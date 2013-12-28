////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50472 $
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
   all support the regular expressions defined in the users ErrorRE.xml
   file.
 
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
     new-line, use the regular expression (\n|\r\n|\r) to match
     any kind of new-line sequence. If you still can't get the
     compiler error message to work, you'll need to write a
     macro. Add a regular expression which matches part of your
     compilers error output (usually the first line). Then set
     the Macro attribute (edit ErrorRE.xml an add/set it) for your
     regular expression and write a macro function which takes
     arguments like the following:
 
  boolean parseErrorOutput_<MyCompiler>(
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
     which specifies the filename. Set the Macro attribute (edit
     ErrorRE.xml an add/set it) for your regular expression and
     write a macro function which takes
 
  boolean parseErrorOutput_<MyCompiler>(
         _str &filename,_str &linenum, _str &col, _str &err_msg
         )
     Return true if a valid match is found.
 
     DO NOT name your function _get_error_info_<microfocus>
     since these callbacks are intended to solve a different
     problem.


*/
///////////////////////////////////////////////////////////////////////////////
// $Revision: 50472 $
///////////////////////////////////////////////////////////////////////////////
#pragma option(pedantic,on)
#region Imports
#include "eclipse.sh"
#include "refactor.sh"
#include "slick.sh"
#include "xml.sh"
#include "color.sh"
#include "markers.sh"
#import "files.e"
#import "guicd.e"
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
#require "se/messages/Message.e"
#import "se/messages/MessageCollection.e"
#import "se/search/SearchResults.e"
#import "tbcmds.e"
#endregion

 _str process_mark;        /* This variable is initialized by "stdcmds" */
 _str _error_mark;
 _str compile_rc;         /* Used for DOS to keep $errors.tmp file loaded. */
 _str _no_filename_index;
 _str _error_found;      /* Set by next when error message found. */

 _str _error_search;      /* Index to search for error function.  Set by init_error() */
 _str _error_parse;       /* Index to parse error function.  Set by init_error() */
 boolean _error_init_done;     /* Set to 1 to indicate that init_error() has been called at least once */
 _str _error_filename;    // Error filename set by init_error(). New in V13
#if __UNIX__
                     /* NOT SET by init_error() function. */
                     /* Used by RS6000 version only. */
   static _str _error_re3='^{#0 *}{#1:i}({#2 *}\||.{#2:i}){#3?*$}';

//   5  IGYPS2072-S   "DISSPLAY" was invalid.  Skipped to the next verb, period
//                    or procedure-name definition.
//   7  IGYPS2072-S   "JUNKLAY" was invalid.  Skipped to the next verb, period
//                    or procedure-name definition.
   static _str _error_re_cob_390='^ *{#1:i}  :c:c:c:c:c:d:d:d:d-:c   {#0}{#2}{#3?*$}';
//ISN     4:200       READZ (1,250,END=500) (INOUT(I),I=1,20)                       00021006
//(E) THE STATEMENT NUMBER HAS BEEN PREVIOUSLY DEFINED. THIS OCCURRENCE OF THE STATEMENT NUMBER HAS BEEN IGNORED. SPECIFY A
//UNIQUE STATEMENT NUMBER TO AVOID ERROR MESSAGE.
//ISN     7:          ERRORERE.                                                     00041005
//(S) THE STATEMENT CONTAINS A SEQUENCE OF CHARACTERS WHICH CANNOT BE RECOGNIZED AS A SYNTACTIC ELEMENT.
   static _str _error_re_for_390='^ISN +{#1:i}\:{#0}{#2}{#3}';
//IEL0304I S   3       INVALID SYNTAX IN ASSIGNMENT STATEMENT AFTER 'ERRORHERE'.    'ERRORHERE' IGNORED.
   static _str _error_re_pl1_390='^:c:c:c:d:d:d:d:c :c   {#1:i}{#0}{#2} +{#3?*$}';
   static _str _error_re_s_390='^?*\*\* Record {#1:i} in {#0[~ ]+}{#2} +{#3?*$}';
   static _str _error_re_cc_390='^(error|warning) [~ \t]+ {#0:p}\:{#1:i}:b{#2}{#3?*$}';
   static _str _error_re_cpp_390='^{#0:q}, line {#1:i}.{#2:i}\:{#3?*$}';

#else
   // PV-Wave
   static _str _error_re3='^  At\: {#0:p}, Line {#1:i}$';
   // Microfocus cobol
   static _str _microfocus_re='^\*[ \t]+{#1:i}-[a-z]\*\*{#0}';
   /*
   CSharp output 7.0 (.net)

   C:\Visual Studio Projects\WindowsApplication1\Form1.cs(73,21): error CS1002: ; expected

   C++ output VC++ 6.0 and 7.0 (.net)

   c:\Visual Studio Projects\testprj\testprj.cpp(29) : error C2078: too many initializers

   Visual Basic Output 7.0 (.net)

   C:\Visual Studio Projects\WindowsApplication2\Form1.vb(13) : error BC30203: Expected an identifier.

   Visual C++ DDK Compiler

   1>h\\skisr.h(47) : error C2143: syntax error : missing \')\' before \'}\'
   1>h\\skisr.h(47) : error C2143: syntax error : missing \'{\' b...
   */

   static _str _error_visual_cpp='^(:i>|[ \t]@){#0?*}\({#1:i}(,{#2:i}|{#2})\) *\: {#3?*$}';
#endif
static _str _error_re4='^({#3?@} at ){#0:p} line {#1:i}?*$';
static _str _error_javacNjikes='^{#0?*}\:{#1:i}\:({#2:i}\:{#3?*$}|{#2}{#3?*$})';
//at com.slickedit.guibuilder.GUICmdSequencer.setProperty(GUICmdSequencer.java:286)
static _str _error_javaException='^\tat [~ \t]#((.[~ \t]#)*)\({#0?#}\:{#1:i}\)';
// Note: Parsing Issue: Filename is NOT on the same line as the error.
//
//     VHDL Compiler, Release 5.200
//     Copyright (c) 1994, Vantage Analysis Systems, Inc.
//     Compiler invocation:   analyze -src dec_conc.vhd -dbg 2 -libfile vsslib.ini
//     Working library MYLIB "/home/projects/test/user.lib".
//     --
//     Compiling "dec_conc.vhd" line 1...
//     Compiled entity MYLIB.ISA_DEC
//     --
//     Compiling "dec_conc.vhd" line 18...
// **Error: LINE 23 *** The type required in this context does not match that of this expression.   (compiler/analyzer/3)
//
// **Error: LINE 23 *** No legal integer type for integer literal >>0<<.   (compiler/analyzer/3)
//
// **Error: LINE 27 *** No legal integer type for integer literal >>4<<.   (compiler/analyzer/3)
//
//     --
//     1/2 design unit(s) compiled successfully.
//     Syntax summary: 10 error(s), 0 warning(s) found.
//
static _str _error_vantage_re='^\*\*Error\: LINE {#1:i}{#0} \*\*\* {#3?*}$';
   // Could do better for turbo pascal $i+ $i-
   // ifdef fndef  fopt
   //,def_include_re = '^[ \t]*( (\#include|include)[ \t]#(<{#0:p}>|{#0:q})|\{\$i|\(\*\$i)([\t ]#){#0:p})';

// JBuilder 8 SE
// Copyright (c) 1996-2002 Borland Software Corporation.  All rights reserved.
//
//
// Disabling offscreen DirectDraw acceleration
// Building...
// Checking Java dependencies...
// Checking borlandproject1...
// "Frame1.java": Error #: 202 : 'class' or 'interface' expected at line 8, column 1
// "Frame1.java": Error #: 209 : 'try' without 'catch' or 'finally' at line 25, column 5
// "Frame1.java": Error #: 207 : not an expression statement at line 28, column 5
// "Frame1.java": Error #: 200 : ';' expected at line 28, column 8
// Compiling Application1.java...
// "Application1.java": Error #: 300 : class Frame1 not found in class borlandproject1.Application1 at line 21, column 5
// "Application1.java": Error #: 300 : class Frame1 not found in class borlandproject1.Application1 at line 21, column 24
// Build complete.
static _str _error_jbuilder = '^[ \t]@\"{#0:p}\"\: {#3Error \#\: :i \: ?*} at line {#1:i}, column {#2:i}$';

// **Error** C:\Projects\ActionScript\Hello World\Application.as: Line 14: Syntax error.
//       functon foo(title:String):Void {
//
// **Error** C:\Projects\ActionScript\Hello World\Application.as: Line 15: ActionScript 2.0 class scripts may only define class or interface constructs.
//          v +++;
//
// **Error** C:\Projects\ActionScript\Hello World\Application.as: Line 16: Unexpected '}' encountered
//       }
//
// Total ActionScript Errors: 3   Reported Errors: 3
//
static _str _error_actionscript = '^\*\*Error\*\* {#0:p}\: Line {#1:i}\: {#2}{#3?*$}';

int _pic_error_marker = 0;
static int gpictype_error = 0;
static int gerror_scroll_mark_type = 0;


#define C_INCLUDE '^[ \t]*(\#include|include|\#line)[ \t]#({#1:i}[ \t]#|)(<{#0[~>]#}>|"{#0[~"]#}")'
#define M_INCLUDE '^[ \t]*(\#include|\#import|include|\#line)[ \t]#({#1:i}[ \t]#|)(<{#0[~>]#}>|"{#0[~"]#}")'
#define E_INCLUDE '^[ \t]*(\#include|\#import|\#require|include)[ \t]#(''{#0[~'']#}''|"{#0[~"]#}")'
#define PAS_INCLUDE '^[ \t]*\{(\$i|\(\*\$i)[ \t]#{#0[~} \t]#}'

#define BUILD_MESSAGE_TYPE 'Build Error'

////////////////////////////////////////////////////////////////////////////////
// New code for error parsing regular expressions. Now they are
// loaded from a configuration file
////////////////////////////////////////////////////////////////////////////////
//
#define ERROR_RE_CONFIG_FILENAME 'ErrorRE.xml'
struct COLLECTION_ITEM {
   _str regex;
   _str macro;
};
static COLLECTION_ITEM allExpressions[];   // holds all the "global" error parsing expressions
static COLLECTION_ITEM extExpressions[];   // holds the extension-specific parsing expressions
static COLLECTION_ITEM exclusionExpressions[]; // holds expressions that are "false positive", meaning
                                     // that we don't actually want these guys to match an
                                     // error line.
static _str lastExtension = '';

int def_max_error_markers = 1000;

/** 
 * If a build error message matches this regular expression, 
 * it will be categorized as an "Error" in the message list. 
 *  
 * @default "error"
 * @categories Configuration_Variables
 */ 
_str def_build_errors_re='error';

/**
 * If a build error message matches this regular expression, 
 * it will be categorized as a "Warning" in the message list.
 *  
 * @default "warning"
 * @categories Configuration_Variables
 */
_str def_build_warnings_re='warning';

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
#if __UNIX__
   _str userName;
   _userName(userName);
   COMPILE_ERROR_FILE=_temp_path():+'vserr.':+userName;
#else
   COMPILE_ERROR_FILE=_temp_path():+'vserr.':+getpid();
#endif
   return(COMPILE_ERROR_FILE);
}
void _exit_errfile()
{
   if (file_eq(COMPILE_ERROR_FILE,_temp_path():+'vserr.':+getpid())) {
      delete_file(COMPILE_ERROR_FILE);
   }
   allExpressions._makeempty();
   extExpressions._makeempty();
   exclusionExpressions._makeempty();
}

defload()
{
   allExpressions._makeempty();
   extExpressions._makeempty();
   exclusionExpressions._makeempty();

   // load the margin bitmap for errors
   _pic_error_marker = _update_picture(0, "_errmark.ico");

   load_include_re(C_INCLUDE,'c');
   load_include_re(C_INCLUDE,'ansic');
   load_include_re(C_INCLUDE,'java');
   load_include_re(C_INCLUDE,'rul');
   load_include_re(C_INCLUDE,'vera');
   load_include_re(C_INCLUDE,'ch');
   load_include_re(C_INCLUDE,'as');
   load_include_re(C_INCLUDE,'idl');
   load_include_re(C_INCLUDE,'asm');
   load_include_re(C_INCLUDE,'s');
   load_include_re(C_INCLUDE,'imakefile');
   load_include_re(C_INCLUDE,'rc');
   load_include_re(C_INCLUDE,'lex');
   load_include_re(C_INCLUDE,'yacc');
   load_include_re(C_INCLUDE,'antlr');
   load_include_re(M_INCLUDE,'m');
   load_include_re(PAS_INCLUDE,'pas');
   load_include_re(E_INCLUDE,'e');
   init_error();
   rc=0;
}
static void load_include_re(_str value, _str ext)
{
   _str name='def-'ext'-include';
   int index=find_index(name,MISC_TYPE);
   if (!index) {
      insert_name(name,MISC_TYPE,value);
   }
#if 1   // You will want to remove this when users have dlgbox to modify this stuff
   else {
      set_name_info(index,value);
   }
#endif
}
static _str activate_error_file(var mark,int &temp_view_id)
{
   if ( _error_file=='' ) {
      _error_file=absolute(COMPILE_ERROR_FILE);
      //_error_file=absolute(GetErrorFilename())
   }
   int status=0;
   _str filename='';
   int orig_view_id=0;
   int load_rc=_open_temp_view(_error_file,temp_view_id,orig_view_id,'+b');
   if ( load_rc ) {
      if (def_err) {
         // Check if an error file exists with .err extension.
         filename=_strip_filename(p_buf_name,'E')'.err';
         load_rc=_open_temp_view(filename,temp_view_id,orig_view_id,'+l');
         if (_error_mark!='') {
            _deselect(_error_mark);
         }
      }
      if (!load_rc) {
         _error_file=filename;
         mark=_error_mark;
      } else {
         // insert a view of the .process file.
         status=_open_temp_view('.process',temp_view_id,orig_view_id,'+b');
         if ( status ) {
            if ( status==FILE_NOT_FOUND_RC ) {
               //message nls("No error message files")
               status=STRING_NOT_FOUND_RC;
            } else {
               message(get_message(status));
            }
            return(status);
         }
         mark=process_mark;
         if (_top_process_mark=='') {
            _top_process_mark=_alloc_selection('B');
            if ( _top_process_mark<0 ) {
               message(get_message((int)_top_process_mark));
               return(1);
            }
            top();
            _select_char(_top_process_mark);
         }
      }
   } else {
      mark=_error_mark;
   }
   if ( mark=='' ) {
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
      }
   } else {
      if ( _select_type(mark)=='' ) {     /* mark deleted? */
         top();  /* Assume previous process was exited. */
                 /* Start from beginning of buffer */
         if (load_rc) {
            _SetNextErrorMark(mark);
         } else {
            _select_char(mark);
         }
      }
      _begin_select(mark);
   }
   if ( load_rc ) {
      process_mark=mark;
   } else {
      _error_mark=mark;
   }
   return(0);

}

static _str GetVslickErrorPath()
{
   _str VSErrorPath='';
   typeless filepos;
   save_pos(filepos);
   int status=0;
   for (;;) {
      #if __UNIX__
      status=search('VSLICKERRORPATH=','@r<-');
      #else
      status=search('VSLICKERRORPATH="?@"','@r<-');
      #endif
      if (status) {
         break;
      }
      _str MaybeEcho='';
      typeless seekpos=_QROffset();
      if (seekpos-5>=0) {
         MaybeEcho=get_text(5,seekpos-5);
      }
      if (MaybeEcho!='echo ') {
         break;
      }
      left();
   }
   //Found the real thing
   if (!status) {
      get_line(auto line);
      #if __UNIX__
      int p=pos('{VSLICKERRORPATH=?@}',line,1,'r');
      #else
      int p=pos('{VSLICKERRORPATH="?@"}',line,1,'r');
      #endif
      if (p) {
         #if __UNIX__
         p=pos('=',line);
         if (p) {
            VSErrorPath=substr(line,p+1);
         }
         #else
         line=substr(line,pos('S0'),pos('0'));
         p=pos('"',line);
         int lp=lastpos('"',line);
         if (p && lp && lp>p) {
            VSErrorPath=substr(line,p,lp-p+1);
            VSErrorPath=strip(VSErrorPath,'B','"');
         }
         #endif
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
   allExpressions._makeempty();
   extExpressions._makeempty();
   exclusionExpressions._makeempty();
}

static int _error_marker_get_picture()
{
   if (!_pic_error_marker) {
      _pic_error_marker = _update_picture(-1, "_errmark.ico");
   }
   return _pic_error_marker;
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

#define TEST_ESC_COUNT 10

_command void set_error_markers(_str options="")
{
   boolean setErrorMarkers = false;
   boolean setErrorScrollMarkers = false;

   if ( options=="" ) {
      // Support calling the "old way"
      setErrorMarkers = true;
   } else {
      for ( ;; ) {
         cur := lowcase(parse_file(options));
         if ( cur=="" ) break;
         if ( cur=='-m' ) {
            setErrorMarkers = true;
         } else if ( cur=='-s' ) {
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
   typeless mark='';
   int temp_view_id=0;
   typeless status = activate_error_file(mark, temp_view_id);
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
   int messageCount = 0;
   typeless p; save_pos(p); //save pos in error file

   _str filenameMap:[];
   _str add_include_path = '';
   if (_ini_get_value(_project_name, 'COMPILER.'GetCurrentConfigName(), 'includedirs', add_include_path) != 0){
      add_include_path = '';
   }

   _str msgType = '';
   int markerHandle = -1;
   mCollection->startBatch();

   int line=0;
   int col=0;
   _str err_msg='';
   _str filename='';
   _str last_filename = '';
   _str found_filename='';
   int source_view_id = 0;
   boolean file_already_loaded = false;
   int check_esc_count = TEST_ESC_COUNT;
   int err_count=0;
   int buildLine;
   for (;;) {
      if (--check_esc_count < 0) {
         if( _IsKeyPending(false)) {
            break;
#if 0 //9:42am 11/17/2010
            int orig_def_actapp=def_actapp;
            def_actapp=0;
            int result1=_message_box('Would you like to cancel setting error markers?','',MB_YESNOCANCEL);
            def_actapp=orig_def_actapp;
            if (result1!=IDNO) {
               break;
            }
#endif
         }
         check_esc_count = TEST_ESC_COUNT;
      }
      activate_window(temp_view_id);
      int rc = call_index('', _error_search);
      if (rc) {
         break;
      }
      _end_line();
      buildLine = p_line;
      matchText := get_match_text();
      call_index(filename, line, col, err_msg, _error_parse);
      if ( filename != '' ) {

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
         _str absoluteFilename = absolute(filename, VslickErrorPath);

         _str hashtableKey = filename"\1"VslickErrorPath;
         if (filenameMap._indexin(hashtableKey)) {
            // have we already seen a file with this filename?
            if (filenameMap:[hashtableKey] == FILE_NOT_FOUND_RC) {
               status = FILE_NOT_FOUND_RC;
            } else {
               filename = filenameMap:[hashtableKey];
            }
         } else if(file_exists(absoluteFilename)) {
            // file found so use this filename for the rest of the function
            filename = absoluteFilename;
            filenameMap:[hashtableKey] = filename;
         } else {
            // file not found so search for it
            boolean found_it=false;
            if (VslickErrorPath!="") {
               found_filename=include_search(filename, VslickErrorPath, add_include_path);
               if (found_filename!='') {
                  filename=found_filename;
                  found_it=true;
               }
            }

            // if not found, search for file in the current project and workspace
            if (!found_it) {
               found_filename=_ProjectWorkspaceFindFile(filename);
               if (found_filename!='') {
                  filename=found_filename;
                  found_it=true;
               }
            }
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
               status = _open_temp_view(maybe_quote_filename(filename), source_view_id, junk,'', file_already_loaded);
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
            if ( line!='' ) {
               GoToErrorLine(line);
            }
            // drop pic here
            if ( setErrorMarkers ) {
               markerHandle = _LineMarkerAdd(p_window_id, p_line, 0, 0, error_bmp,
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
               tmpMsg.m_date = '';
               if ( setErrorMarkers ) {
                  tmpMsg.m_markerPic = error_bmp;
               }
               tmpMsg.m_lmarkerID = markerHandle;
               tmpMsg.m_attributes:['build window line'] = buildLine;

               se.messages.MenuItem tmpMenuItem;
               tmpMenuItem.m_menuText = 'Go to Build Output';
               tmpMenuItem.m_callback = 'goToBuildOutput';
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
_command int next_error(_str resetMessages='',
                        _str unusedArg2='',
                        _str displayMessages='',
                        _str lookingBackwards='') name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI)
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

   // mark which buffers were open before we navigate to the next error
   _mdi.p_child.mark_already_open_destinations();
   if (!_no_child_windows()) { 
      _mdi.p_child.pop_destination(false,true);
   }

/*#if __UNIX__
   if (resetMessages=='' && _sbhas_errors()) {
      return(sbnext_error());
   }
#endif*/
   p_window_id=_mdi.p_child;
   _str old_buffer_name='';
   typeless swold_pos;
   int swold_buf_id=0;
   set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
   /* Preserve column position for the case where the error message */
   /* does not display a column and the active buffer contains the error. */
   int old_col=p_col;
   int old_buf_id=p_buf_id;

   int orig_view_id=0;
   get_window_id(orig_view_id);  /* HERE - Need this for WorkFrame support so we can
                               *        get back to the original view after
                               *        "No more errors".
                               */

   /* is there a errors temp file? */
   typeless mark;
   int temp_view_id=0;
   status=activate_error_file(mark,temp_view_id);
   if ( status ) {
      if (upcase(resetMessages)!='R') {
         // no message files
         if (status==STRING_NOT_FOUND_RC) {
            _message_box(nls("No error message files"));
         }
      }
      status=1;
      return(status);
   }
   boolean looking_backwards = lookingBackwards!='';
   //if arg(4) is non-null, we are looking backwards.  arg(2) is unused,
   //but I was worried that it might be reserved.
   if ( upcase(resetMessages)=='R' ) {  /* reset messages? */
      goto_read_point();
      _deselect(_top_process_mark);clear_message();_select_char(_top_process_mark);
      rc=1;
      clear_all_error_markers();
   } else {
      message(nls('Searching...'));
      if (looking_backwards) {
         _begin_line();
         //Since the mark is always at the end of the line, If we are looking
         //backwards we always go to the beginning of the line first so that
         //we don't find the line that we are on.
      }
      rc=call_index(lookingBackwards,_error_search);
   }
   _str filename='';
   _str found_filename='';
   int line=0;
   int col=0;
   _str err_msg='';
   if ( ! rc ) {
      compile_rc=0;
      _end_line();
      if (mark==process_mark) {
         _SetNextErrorMark(process_mark);
      } else {
         //_SetNextErrorMark(_error_mark);
         _deselect(mark);_select_char(mark); //Always put mark at end of the line.
      }
      call_index(filename,line,col,err_msg,_error_parse);
      if ( filename!='' ) {
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
         _str absoluteFilename = absolute(filename, VslickErrorPath);

         if(file_exists(absoluteFilename)) {
            // file found so use this filename for the rest of the function
            filename = absoluteFilename;
         } else {
            // file not found so search for it
            boolean found_it=false;
            if (VslickErrorPath!="") {
               found_filename=include_search(filename,VslickErrorPath);
               if (found_filename!='') {
                  filename=found_filename;
                  found_it=true;
               }
            }

            // if not found, search for file in the current project and workspace
            if (!found_it) {
               found_filename=_ProjectWorkspaceFindFile(filename);
               if (found_filename!='') {
                  filename=found_filename;
                  found_it=true;
               }
            }

            // if still not found, try prompting for path
            if (!found_it) {
               static _str last_dir;
               if (last_dir!='' && file_exists(last_dir:+filename)) {
                  filename=last_dir:+filename;
               } else {
                  _str found_dir = _strip_filename(filename,"N");
                  _str just_filename = _strip_filename(filename,"P");
                  found_filename = _ChooseDirDialog("Find File",found_dir,just_filename);
                  if (found_filename!='') {
                     filename=found_filename:+just_filename;
                     last_dir=found_filename;
                  }
               }
            }
         }
         activate_window(orig_view_id);
         if (iswildcard(filename) && !file_exists(filename)) {
            status=FILE_NOT_FOUND_RC;
         } else if(file_exists(filename)){
            status=edit(maybe_quote_filename(filename));
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
            switch_buffer(old_buffer_name,'',swold_pos,swold_buf_id);
         }
         if ( status ) {
            if ( status==NEW_FILE_RC ) {
               err_msg=nls("File '%s' not found",filename);
            } else {
               err_msg=nls("Error loading file '%s'",filename)'.  'get_message(status);
            }
            if ( status ) {
               if (upcase(resetMessages)!='R') {
                  _message_box(err_msg);
               }
               _delete_temp_view(temp_view_id,false);
               activate_window(orig_view_id);

               return(1);
            }
         }
      }
      int source_view_id=0;
      get_window_id(source_view_id);
      _delete_temp_view(temp_view_id,false);
      if (source_view_id!=temp_view_id) {
         activate_window(source_view_id);
      }

      typeless old_scroll_style=_scroll_style();
      _scroll_style('c');
      _error_found=1;
      if ( line!='' ) {
         GoToErrorLine(line);
      }
      _scroll_style(old_scroll_style);
      if ( col!='' ) {
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
      /* sticky_message 'filename='filename' line='line' col='col */
   } else {
      status=STRING_NOT_FOUND_RC;
      _str message_text=nls('No more errors');
      if ( file_eq(p_buf_name,_error_file) ) {
         status=2;  // Indicate that there were no more errors in error file
         p_modify=0;
         if ( compile_rc ) {
            activate_window(orig_view_id);
            typeless result=edit(maybe_quote_filename(_error_file));
            if (!result) {
               bottom();
            }
         } else if( def_quit_error_file ) {
            _str buf_name=p_buf_name;
            int buf_id=p_buf_id;
            _delete_temp_view(temp_view_id);
            activate_window(orig_view_id);
            if (def_one_file!='') {
               // Delete all mdi windows which are displaying this buffer.
               int count=0;
               int wid=window_match(buf_name,1,'xn');
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
                           wid.close_window('',false);
                        } else {
                           // Delete the window and not the buffer.
                           wid._delete_window();
                        }
                     }
                     wid=window_match(buf_name,0,'xn');
                  }
               } else {
                  status=edit(' +bp +bi 'buf_id);
                  quit();
               }
            } else {
               status=edit(' +bp +bi 'buf_id);
               quit();
               /*orig_wid=p_window_id;
               close_buffer(false);
               if (orig_wid==p_window_id) {
                  _delete_view();
               } */
            }
            if (_error_file=='') {
               //_error_file=COMPILE_ERROR_FILE;
               _error_file=GetErrorFilename();//GetErrorFilename sets COMPILE_ERROR_FILE
            }
            message_text=message_text:+'. 'nls('%s file quit',_error_file);
            if ( displayMessages ) { /* Display message? */
               if (_no_child_windows() && upcase(resetMessages)!='R') {
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
            if( lookingBackwards=='' ) {  /* Just did a next_error()? */
               bottom();
            } else {   /* Just did a prev_error()? */
               top();
            }
            if (mark==process_mark) {
               _SetNextErrorMark(process_mark);
            } else {
               _deselect(mark);_select_char(mark);
            }
            _delete_temp_view(temp_view_id,false);
            activate_window(orig_view_id); /* HERE - Need this for WorkFrame support
                                          *        so we can get back to the original
                                          *        view when "No more errors".
                                          */
            if ( displayMessages ) { /* Display message? */
               if (_no_child_windows() && upcase(resetMessages)!='R') {
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
      if (resetMessages=='R'||!looking_backwards) {
         goto_read_point();// Only go to bottom if Reseting errors
      }
      if (!looking_backwards) {
         p_col=1;//Go beginning of line in case the process is halfway through
                 //writing a line
      }
      if (mark==process_mark) {
         _SetNextErrorMark(process_mark);
      } else {
         _deselect(mark);_select_char(mark);
      }
      _delete_temp_view(temp_view_id,false);
      activate_window(orig_view_id);
      if ( displayMessages ) {
         if (_no_child_windows() && upcase(resetMessages)!='R') {
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
      _mdi.p_child.push_destination();
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
_command int prev_error() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI)
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
   return(next_error('','','','-'));
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

#define DELIMS '"|<|>|\}':+"|'";

static boolean _is_grep_goto()
{
   if (p_LangId == 'grep' || p_name == "ctloutput") {
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
static boolean _is_cursor_error()
{
   return( p_mdi_child ||
           (_process_info('B') || file_eq(_strip_filename(p_buf_name,'P'),COMPILE_ERROR_FILE)) ||
           p_active_form.p_name == "_tbshell_form" ||
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
         return('');
      }
   }

   int status=0;
   _str filename='';
   _str found_filename='';
   _str err_msg='';

   // Try custom goto include code
   VS_TAG_BROWSE_INFO cm;
   status=tag_get_current_include_info(cm);
   if (!status) {
      status=_resolve_include_file(cm.file_name);
      if (status) return(status);
      boolean push = !((p_buf_flags & VSBUFFLAG_HIDDEN) || p_buf_name == ".process");
      if (push && def_search_result_push_bookmark) {
         push_bookmark();
      }
      status=tag_edit_symbol(cm);
      if (!status && push) {
         push_destination();
      }
      return(status);
   }
   _str text='';
   save_pos(auto p2);
   begin_line();
   text=get_text(4096);
   restore_pos(p2);

   _str info='';
   int orig_view_id=0;
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
      status=call_index(_error_search);
      restore_pos(p3);
   }
   if (status) {
      clear_message();
         //We might need to add support file:// here too.
      _str http_extra='http\:/|ttp\:/|tp\:/|p\:/|\:/|/|';
      search(':q|('http_extra'\:|):p|^','rh-');   /* Search for Filename */
      filename=get_match_text();
         //messageNwait('filename='filename);
      filename=strip(filename,'B',"'");    /* Strip quotes if any */
      filename=maybe_quote_filename(filename);
      activate_window(orig_view_id);
      status=0;
      if (filename!='') {
         status=_resolve_include_file(filename);
         if (!status) {
            tag_browse_info_init(cm);
            cm.file_name=filename;
            cm.line_no= -1;
            boolean push = !((p_buf_flags & VSBUFFLAG_HIDDEN) || p_buf_name == ".process");
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
   _str line='';
   int col=0;
   call_index(filename,line,col,err_msg,_error_parse);
   status=0;
   if ( filename!='' ) {
      filename=strip(filename,'B','"');
      activate_window(orig_view_id);
      set_next_error(true,true);
      status=FILE_NOT_FOUND_RC;
      if (file_exists(filename)) {
         status=edit(maybe_quote_filename(filename));
      } else {
         boolean found_it=false;
         _str VslickErrorPath=GetVslickErrorPath();
         if (VslickErrorPath!="") {
            found_filename=include_search(filename,VslickErrorPath);
            if (found_filename!='') {
               filename=found_filename;
               found_it=true;
            }
         }

         // if not found, search for file in the current project
         if (!found_it) {
            found_filename=_ProjectWorkspaceFindFile(filename);
            if (found_filename!='') {
               filename=found_filename;
               found_it=true;
            }
         }

         // if still not found, try prompting for path
         if (!found_it) {
            static _str last_dir;
            if (last_dir!='' && file_exists(last_dir:+filename)) {
               filename=last_dir:+filename;
            } else {
               _str found_dir     = _strip_filename(filename,"N");
               _str just_filename = _strip_filename(filename,"P");
               found_filename = _ChooseDirDialog("Find File",found_dir,just_filename);
               if (found_filename=='') {
                  return(COMMAND_CANCELLED_RC);
               }
               filename=found_filename:+just_filename;
               last_dir=found_filename;
            }
         }
         // give up and curl up in the corner and cry
         if (!found_it) {
            sticky_message(nls("File '%s' not found",filename));
         } else {
            status=edit(maybe_quote_filename(filename));
         }
      }
      if ( ! status ) {
         #if 1   /* HERE - 5/30/1995 - uniconize the file if necessary */
         if(upcase(p_window_state)=='I' ) {
            p_window_state='N';
         }
         #endif
         typeless old_scroll_style=_scroll_style();
         _scroll_style('c');
         if ( line!='' ) {
            GoToErrorLine((typeless)line);
         }
         if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
            expand_line_level();
         }
         _scroll_style(old_scroll_style);
         if ( col!='' ) {
            p_col=_text_colc(col,'I');
         }
      }
   }
   if ( ! status ) {
      sticky_message(err_msg);
   }
   if (!status) {
      _mdi._set_foreground_window();
   }
   return(status);

}
void GoToErrorLine(int LineNumber)
{
   if (!gerror_info._indexin(p_buf_name)) {
      if (p_buf_size<VSMAX_SETOLDLINENUMS_BUF_SIZE) {
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
_command void find_error() name_info(','VSARG2_REQUIRES_MDI)
{
   typeless pcode_offset='';
   _str filename='';
   parse error_pos() with pcode_offset filename;
   filename=_strip_filename(filename,'E');
   _str sourcefilename= slick_path_search(filename:+_macro_ext);
#if __PCDOS__
   if ( sourcefilename=='' ) {  /* Might be .cmd file. */
      sourcefilename= slick_path_search(filename'.cmd');
   }
#endif
   if ( sourcefilename=='' ) {
      message(nls("Can't find error"));
      return;
   }
   st('-f 'pcode_offset " "maybe_quote_filename(sourcefilename));
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
_command int set_next_error(_str beQuiet='', _str gotoEndOfLine='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   boolean doEndLine=gotoEndOfLine!="" && gotoEndOfLine;
   boolean quiet=beQuiet!='';
   typeless mark;
   if ( p_buf_name=='.process' ) {
      mark=process_mark;
   } else if ( file_eq(p_buf_name,_error_file) ) {
      mark=_error_mark;
   } else if ( file_eq(_strip_filename(p_buf_name,'P'),COMPILE_ERROR_FILE) &&
      (_error_mark=='' || _select_type(_error_mark)=='') ) {
      _error_file=p_buf_name;
      mark=_error_mark;
   } else {
      if (quiet) {
         return(1);
      }
      _message_box(nls('Build tab or %s must be active',COMPILE_ERROR_FILE));
      return(1);
   }
   if ( mark == '' ) {
      mark = _alloc_selection('b');
      if ( p_buf_name=='.process' ) {
         process_mark=mark;
      } else {
         _error_mark=mark;
      }
   }
   typeless p;
   if (doEndLine) {
      save_pos(p);
      _end_line();
   }
   if (mark==process_mark) {
      _SetNextErrorMark(process_mark);
   } else {
      _deselect(_error_mark);
      _select_char(_error_mark);
   }
   if (doEndLine) {
      restore_pos(p);
   }
   //_deselect(mark);_select_char(mark);
   if (past_top_error()) {
      _deselect(_top_process_mark);clear_message();_select_char(_top_process_mark);
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
_command void reset_next_error(_str unused1='', _str unused2='', _str displayMessages='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   tag_close_bsc();
   _mffindNoMore(2);
   _mfrefNoMore(2);
   init_error();
   gerror_info._makeempty();
/*#if __UNIX__
   _sbreset_next_error();
#endif*/
   next_error('R','',displayMessages);
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
_str include_search(_str filename, _str multi_path='',_str multi_path2='')
{
   if ( multi_path=='' ) {
      multi_path='INCLUDE=';
   }
   if ( pos('=',multi_path) ) {
      multi_path=get_env(stranslate(multi_path,'','='));
   }
   _str path='';
   _str match='';
   for (;;) {
      if ( multi_path=='' ) {
         //return('');
         break;
      }
      parse multi_path with path (PATHSEP) multi_path;
      if ( last_char(path):!=FILESEP && last_char(path):!=FILESEP2 ) {
         path=path:+FILESEP;
      }
      match=file_match2(path:+filename,1,'-p');
      if ( match!='' ) {
         return(match);
      }
   }

   if (multi_path2=='') {
      int status=_ini_get_value(_project_name,'COMPILER.'GetCurrentConfigName(),'includedirs',multi_path2);
   }
   for (;;) {
      if ( multi_path2=='' ) {
         return('');
      }
      parse multi_path2 with path (PATHSEP) multi_path2;
      if ( last_char(path):!=FILESEP && last_char(path):!=FILESEP2 ) {
         path=path:+FILESEP;
      }
      match=file_match2(path:+filename,1,'-p');
      if ( match!='' ) {
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
   if ( error_re=='' ) {
      return;
   }
   _str regexWithoutStart = strip(error_re,'L','^');
   if (pattern=='') {
      pattern= '('regexWithoutStart')';
      return;
   }
   pattern= pattern'|('regexWithoutStart')';
}

boolean _get_error_info_pvwave_pro(_str &filename,_str &linenum, _str &col, _str &err_msg )
{
   _str line='';
   get_line(line);
   if (filename=="" || linenum=="" ||
       substr(line,1,6):!='  At: ') {
      return(false);
   }
   up();
   get_line(err_msg);
   down();
   return(true);
}
#if !__UNIX__
boolean _get_error_info_microfocus(_str &filename,_str &linenum, _str &col, _str &err_msg )
{
   _str line='';
   get_line(line);
   if (/*filename!="*" || */linenum=="" ||
       !pos(_microfocus_re,line,1,'ri')) {
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
   int status=search('[~a-z]cobol[ \t]*{:p}','@rih-');
   if (status) {
      return(false);
   }
   filename=get_match_text(0);
   restore_pos(p);
   return(true);
}
#endif
/*
   filename must be initialized and may be ''
   linenum must be initialized and may be ''
   col must be initialized and may be ''
   err_msg must be initialized and may be ''
*/
void call_list_get_error_info(_str view_id,_str &filename,_str &line, _str &col, _str &err_msg,_str matched_string)
{
   _str prefix_name='_get_error_info_';
   int orig_view_id=0;
   get_window_id(orig_view_id);
   _str idx_list='';
   typeless index=name_match(prefix_name,1,PROC_TYPE);
   for (;;) {
      if ( ! index ) { break; }
      if ( index_callable(index) ) {
         idx_list=idx_list:+' ':+index;
         //call_index(arg(2),arg(3),arg(4),arg(5),index)
      }
      index=name_match(prefix_name,0,PROC_TYPE);
   }
   if (view_id!='') {
      activate_window((int)view_id);
   }
   typeless p;
   while( idx_list!='' ) {
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
static boolean past_top_error()
{
   if (!_process_info('b') || _top_process_mark=='' || _select_type(_top_process_mark)=="") {
      return(0);
   }
   int linenum=p_line;
   int buf_id=p_buf_id;
   save_pos(auto p);
   _begin_select(_top_process_mark);
   int linenum2=p_line;
   p_buf_id=buf_id;restore_pos(p);
   return(linenum<linenum2);
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
   _error_search= find_index('search-for-error',PROC_TYPE);
   _error_parse= find_index('parse-error',PROC_TYPE);
   _error_re=def_error_re;
   _error_re2=def_error_re2;
   if (_isEditorCtl()){
      lang=p_LangId;
   } else {
      lang='fundamental';
   }
   index=find_index(lang'-init-error',PROC_TYPE|COMMAND_TYPE);
   if ( index ) {
      call_index(index);
      return;
   }
   // ~Original code
*/
}
#if __UNIX__ && !__OS390__
   /* as assembler error message support */
   /* Assembler: xxx.s  */
   /* aline 12 : message */
boolean _get_error_info_as(_str &filename,_str &line,_str &col, _str &err_msg)
{
   if ( filename!='aline' && filename!=(_chr(13)'line') ) {
      return(false);
   }
   typeless p=point();
   typeless ln=point('L');
   typeless cl=p_col;
   int left_edge=p_left_edge;
   int cursor_y=p_cursor_y;
   search('^Assembler\: ','@rih-');
   if ( rc ) {
      filename='';
   } else {
      get_line(auto cur_line);
      parse cur_line with . filename;
      goto_point(p,ln);p_col=cl;set_scroll_pos(left_edge,cursor_y);
   }
   return(filename!='');
}

boolean _get_error_info_cc_rs6000(_str &filename,_str &line,_str &col, _str &err_msg)
{
   /* RS6000 cc compiler does not provide source filename. */
   /* search backwards for cc line to get filename. */
   if ( filename!='' || line=='' ) {
      return(false);
   }
   typeless p=point();
   typeless ln=point('L');
   int cl=p_col;
   int left_edge=p_left_edge;
   int cursor_y=p_cursor_y;
   int status=search('^?*[ \t]+{(cc|xlf)[ \t]?*$}','@rih-');
   if (status ) {
      filename='';
   } else {
      get_line(auto cur_line);
      cur_line=get_match_text(0);
      parse cur_line with . cur_line;
      for (;;) {
         parse cur_line with filename cur_line;
         if ( substr(filename,1,1)!='-' ) {
            break;
         }
         if ( filename=='' ) {
            break;
         }
      }
      goto_point(p,ln);p_col=cl;set_scroll_pos(left_edge,cursor_y);
   }
   return(filename!='');
}
#endif

#if __OS390__ || __TESTS390__
boolean _get_error_info_DataSetComp_os390(_str &filename,_str &linenum,_str &col, _str &err_msg,_str matched_string)
{
   //say('start f='filename);
   if ((filename!='' && filename!='ISN') || linenum=='' ) return(false);

   // This assembler output has no column information.
   // Default it to the first column.
   col = "1";

   // Save the current position for a restart.
   save_pos(p);

   // Search backward for the compile command which has the
   // filename
   _str cc_re= 'vscomp.rexx[ \t]+[~ \t]+[ \t]+{:q}';
   status=search(cc_re,'w:p@rih-');
   //say('status='status);
   if (status ) {
      filename='';
      return(false);
   }
   filename=get_match_text(0)
   //say('filename='filename);
   parse filename with '"'dataset'('member')';
   if (member!='') {
      filename=DATASET_ROOT:+dataset:+FILESEP:+member;
   } else {
      parse dataset with dataset'"';
      filename=DATASET_ROOT:+dataset;
   }
   //say('h2 filename='filename);
   restore_pos(p);

   if (pos(_error_re_cob_390,matched_string,'','ri')) {
      //say('cobol case');
      msg_start_col=23;
      //get_line(line);
      //err_msg=substr(line,msg_start_col);
      for (;;) {
         if(down()) break;
         get_line(line);
         //say('l='line);
         if (substr(line,1,msg_start_col-1)!='') {
            break;
         }
         err_msg=strip(err_msg)' 'substr(line,msg_start_col);
      }
      restore_pos(p);
      return(true);
   }
   if (pos(_error_re_for_390,matched_string,'','ri')) {
      err_msg='';
      if(!down()) {
         get_line(line);
         parse line with ') 'err_msg;
         for (;;) {
            if(down()) break;
            get_line(line);
            if (line=='') break;
            if (substr(line,1,1)=='(' && substr(line,3,1)==')') {
               break;
            }
            if (substr(line,4)=='ISN ' || substr(line,1,2)=='**') {
               break;
            }
            err_msg=strip(err_msg)' 'line;
         }
      }
      //err_msg=lowcase(err_msg);
      restore_pos(p);
      return(true);
   }
   if (pos(_error_re_pl1_390,matched_string,'','ri')) {
      err_msg=strip(err_msg);
      return(true);
   }

   restore_pos(p);
   return(false);
}
boolean _get_error_info_s_os390(_str &filename,_str &line,_str &col, _str &err_msg,_str matched_string)
{
   //say('start f='filename);
   if (!pos(_error_re_s_390,matched_string,'','ri') || file_match(filename,1)!='' || line=='' ) return(false);

   // This assembler output has no column information.
   // Default it to the first column.
   col = "1";

   // Save the current position for a restart.
   save_pos(p);

   _str cc_re = '(c89|cc|c\+\+|cxx)[ \t]+?*[ \t]*{([a-zA-Z0-9_]+.s|:q)}[ \t]*?*$';
   status=search(cc_re,'w:p@rih-');
   //say('status='status);
   if (status ) {
      filename='';
   } else {
      get_line(auto cur_line);
      pos(cc_re,cur_line,'','ri');
      parse substr(cur_line,pos('S'),pos('')) with . cmdlineargs;
      //say('cmdlineargs='cmdlineargs);

      for (;;) {
         filename=parse_file(cmdlineargs);
         if (filename=='') { // Can happen if "-o filename" is the only filename
            break;
         }
         if (substr(filename,1,1)=='-') {
            if (filename=='-o') {
               // Skip next file argument
               filename=parse_file(cmdlineargs);
            }
         } else {
            break;
         }
      }
      //filename=substr(cur_line,pos('S0'),pos('0'));

      //say('s1 filename='filename);
      if (substr(filename,1,4)=='"//''') {
         //say('s2 filename='filename);
         parse filename with "'"dataset'('member')';
         if (member!='') {
            filename='//'dataset'/'member;
         } else {
            parse dataset with dataset "'";
            filename='//'dataset;
         }
      }
      //say('s2 filename='filename);
      restore_pos(p);
   }
   // From the error line, search backward for the error messages.
   // The error messages are flagged with " ERROR " and they can be
   // on more than one line. Loop back a line at a time and concat
   // the error messages.
   err_msg = "";
   while (p_line > 1) {
      p_line = p_line - 1;
      get_line(cur_line);
      //say(cur_line);
      if (pos(_error_re_s_390,cur_line,1,"ri") ||
          !pos('^?*\*\* (ERROR|WARNING) \*\*(\* | ){?*$}', cur_line, 1, "ri")
          ) {
         //say('bool1='(!pos('^?*\*\* (ERROR|WARNING) \*\*(\* | ){?*$}', cur_line, 1, "ri")));
         //say('bool2='pos(_error_re_s_390,cur_line,1,"ri"));
         break;
      }
      _str sep = "";
      if (err_msg != "") sep = ". "
      err_msg = substr(cur_line,pos('S0'),pos('0')) :+ sep :+ err_msg;
   }
   restore_pos(p);
   return(filename!='');
}
#endif

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
   if(retval == 'modified') {
      allExpressions._makeempty();
      extExpressions._makeempty();
      exclusionExpressions._makeempty();
   }
}
/**
 * Initializes error parsing regular expressions, loaded from the
 * ErrorRE.xml configuration file
 */
void init_error_re()
{
   _error_filename='';
   if (_isEditorCtl()) {
      _error_filename=p_buf_name;
   }
   _error_search= find_index('search_for_error_re',PROC_TYPE);
   _error_parse= find_index('parse_error_re',PROC_TYPE);
   _error_init_done=true;

   // Reload the hashtable by reading the configuration file
   if (allExpressions._isempty()) {
      // Read (or create and read) the XML configuration file
      int xHandle = loadErrorConfigFile();
      if (xHandle >= 0) {
         loadDefaultErrorExpressions(xHandle);
         _xmlcfg_close(xHandle);
      }
   }

   // Load the array of expressions used to filter
   // out unwanted matches.
   if(exclusionExpressions._isempty()) {
      int xHandle = loadErrorConfigFile();
      if(xHandle >= 0) {
         loadExclusionExpressions(xHandle);
         _xmlcfg_close(xHandle);
      }
   }

   _str lang = 'fundamental';
   if (_isEditorCtl()) {
      lang = p_LangId;
   }
   if (lastExtension != lang) {
      // Set up expressions per extension
      lastExtension = lang;
      extExpressions._makeempty();
      int xHandle = loadErrorConfigFile();
      if (xHandle >= 0)
      {
         loadLanguageSpecificErrorExpressions(xHandle, lang);
         _xmlcfg_close(xHandle);
      }

      // Also see if there is a custom initialization
      // method for this extension
      int extensionIndex = find_index(lang'-init-error',PROC_TYPE|COMMAND_TYPE);
      if ( extensionIndex ) {
         call_index(extensionIndex);
      }
   }
}

/**
 * Search for error lines using regular expressions read from the ErrorRE.xml
 * configuration file
 *
 * @return The same status code as calling search()
 * @see search
 */
int search_for_error_re(_str direction='')
{
   _str directionops = (direction=='')? '>' : '<-';

   if (pos('-',directionops)) {
      up();_end_line();
   }

   save_pos(auto p);

   _str pattern='';
   typeless hashIndex;
   hashIndex._makeempty();

   // Walk the list of extension-specific expressions, if set,
   // and or them together
   for (hashIndex._makeempty(); ;) {
      extExpressions._nextel(hashIndex);
      if (hashIndex._isempty()) {
         break;
      }
      or_re(pattern, extExpressions[hashIndex].regex);
   }

   // Walk the global expressions, and or them together
   for (hashIndex._makeempty(); ;) {
      allExpressions._nextel(hashIndex);
      if (hashIndex._isempty()) {
         break;
      }
      //_message_box('re='allExpressions[hashIndex].regex);
      or_re(pattern, allExpressions[hashIndex].regex);
   }

   if (pattern:== '') {
      return (STRING_NOT_FOUND_RC);
   }

   /* I tweeked this stuff a little.  Basically, if you're looking for the
      previous error, you want to search backwards, and use the < option rather
      than the > option */
   _str searchOpts = directionops :+ '@rih';
   int status = search('^('pattern')', searchOpts);
   boolean keepLooking = true;
   while((!status) && (keepLooking)) {
      keepLooking = false;
      if (past_top_error()) {
         /* If we went above the top, return string not found, because we found
            an old error */
         status=STRING_NOT_FOUND_RC;
         restore_pos(p);
      } else {
         // We matched an expression. But now we want to make sure it's not
         // one of our false-positives
         int matchStart = match_length('S');
         int matchLen = match_length('');
         _str matchedLine = get_text(matchLen, matchStart);
         for (hashIndex._makeempty(); ;) {
            exclusionExpressions._nextel(hashIndex);
            if (hashIndex._isempty()) {
               break;
            } else {
               // See if the line matches this false-positive expression
               if (pos(exclusionExpressions[hashIndex].regex, matchedLine, 1, 'ri') > 0) {
                  status=repeat_search(searchOpts);
                  keepLooking = true;
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

/**
 * Parse error lines using regular expressions read from the ErrorRE.xml
 * configuration file
 *
 * @param filename Output parameter for the file containing the error
 * @param line Output parameter for the line number in filename
 * @param col Output parameter for the column position on line in filename
 * @param err_msg Output parameter for the error message 
 *  
 * @categories Miscellaneous_Functions
 */
void parse_error_re(_str &filename,_str &line,_str &col,_str &err_msg,
                    typeless view_id='', _str alt_word='')
{   
   /* arg(6) HERE - 5/18/95 - added for IBM WorkFrame support */
   _str temp = '';
   if ( alt_word!='' ) {
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
   _str expressionThatMatched = '';
   _str macroToCall = '';
   hashIndex._makeempty();
   int status = 0;

   // Walk the list of extension-specific expressions, if set
   for (hashIndex._makeempty(); status < 1;) {
      extExpressions._nextel(hashIndex);
      if (hashIndex._isempty()) {
         break;
      }
      status = pos(extExpressions[hashIndex].regex, temp, 1, 'ri');
      if (status) {
         expressionThatMatched = extExpressions[hashIndex].regex;
         macroToCall= extExpressions[hashIndex].macro;
      }
   }

   // Walk the global expressions
   if (expressionThatMatched == '' && status < 1) {
      for (hashIndex._makeempty();;) {
         allExpressions._nextel(hashIndex);
         if (hashIndex._isempty()) {
            break;
         }
         status = pos(allExpressions[hashIndex].regex, temp, 1, 'ri');
         if (status) {
            expressionThatMatched = allExpressions[hashIndex].regex;
            macroToCall = allExpressions[hashIndex].macro;
            break;
         }
      }
   }

   filename=substr(temp,pos('S0'),pos('0'));
   //say('b4 filename='filename);
   line=substr(temp,pos('S1'),pos('1'));
   col=substr(temp,pos('S2'),pos('2'));
   err_msg=substr(temp,pos('S3'),pos('3'));
   int default_start1=pos('s1');
   int default_start2=pos('s2');
#define IN_FILE_FROM 'In file included from '
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
      err_msg='In file including from 'filename;
   } else if (strieq(substr(strip(filename),1,length('from ')),'from ') ) {
      filename=substr(strip(filename),length('from ')+1);
      err_msg='In file including from 'filename;
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
   if (col=='') {
      typeless before_carot_search;
      save_pos(before_carot_search);
      int i;
      for (i=0; i<5; ++i) {
         if (down()) break;
         _str carot_line='';
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
   //say('line='line' col='col);

   if (_DataSetSupport()) {
      _str dataset = '';
      _str member = '';
      if (substr(filename,1,4)=='"//''') {
         parse filename with "'"dataset'('member')';
         if (member!='') {
            filename=DATASET_ROOT:+dataset:+FILESEP:+member;
         } else {
            parse dataset with dataset "'";
            filename='//'dataset;
         }
      }
      else if (pos('(',filename)) {
         filename=strip(filename,'B','"');
         filename=strip(filename,'B',"'");
         parse filename with dataset'('member')';
         filename=DATASET_ROOT:+dataset:+FILESEP:+member;
      }
   }

   // check for ant syntax
   //    [compiler] Compiling 1 source file to OUTDIRPATH
   //    [compiler] ABSFILENAME
   //
   // NOTE: for now, assume that a filename starting with '[' is
   //       ant syntax.  our project dont currently support filenames
   //       that start with '[' anyway
   filename = strip(filename);
   if (first_char(filename) == '[') {
      // trim off the '[compiler]' part
      int closeBracket = pos(']', filename);
      if (closeBracket > 0) {
         filename = substr(filename, closeBracket + 1);
         filename = strip(filename);
      }
   }


   //say('filename='filename);
   /* Clipper compiler error message support */
   /* compiling ...prg  */
   /* line 12: message */
   /* 123 error */
   if ( filename=='line' || filename==(_chr(13)'line') ) {
      if ( _no_filename_index != 0 ) {
         call_index(filename,view_id,_no_filename_index);
      }
      if ( filename=='' ) {
         line='';
         col='';
         err_msg=nls('Could not find name of buffer that was compiled');
      }
   }
   boolean regexSpecificMacroWorked=false;
   if (macroToCall!='') {
      int index=find_index(macroToCall,PROC_TYPE);
      if (index_callable(index)) {
         regexSpecificMacroWorked=call_index(filename,line,col,err_msg,temp,index);
      }
   }
   if (!regexSpecificMacroWorked) {
      call_list_get_error_info(view_id,filename,line,col,err_msg,temp);
   }
   //say('h2 line='line' col='col);

   if ( err_msg=='' && line!='' ) {
      int start=default_start1;
      if ( pos('2') ) {
         start=default_start2;
      }
      parse substr(temp,start) with ':' err_msg;
   } else if ( substr(err_msg,1,1)==':' ) {
      err_msg=substr(err_msg,2);
   }
   if (substr(filename,1,1)!='"') {
      filename=maybe_quote_filename(filename);
   }
}

/////////////////////////////////////////////////////////////
// New XML configuration file methods
/////////////////////////////////////////////////////////////

/**
 * Opens the ErrorRE.xml configuration file, or creates it if missing
 *
 * @return Handle to the XML configuration DOM
 */
int loadErrorConfigFile()
{
   int openStatus = 0;
   _str config_file = _ConfigPath() :+ ERROR_RE_CONFIG_FILENAME;
   int xml_handle = _xmlcfg_open(config_file, openStatus, VSXMLCFG_OPEN_REFCOUNT /*| VSXMLCFG_OPEN_ADD_ALL_PCDATA*/);
   if (xml_handle < 0 || openStatus < 0) {
      xml_handle = createErrorConfigFile();
   }
   return xml_handle;
}

int resetErrorConfigFile()
{
   return createErrorConfigFile();
}

/**
 * Load the expressions specific to the current file extension (if any).
 * Do not call this method directly from client code. Use loadExtensionErrorExpressions
 *
 * @param xml_handle    Handle to the XML configuration DOM
 * @param lang          Languageto find an expression set for
 *
 * @return Node index for the regular expression category for the extension,
 *         or -1 if no special category is defined
 * @see loadExtensionErrorExpressions
 */
static int findLanguageSpecificSet(int xml_handle, _str lang)
{
   // Loop through all the top-level Tools, looking for "Extension ext"
   // as the Tool name
   //
   // We also want to be smart about the name of the extension set, so
   // find all the possible identical extensions. For example, if we have defined
   // an "Extension PL" for perl, we'll also want to use it for all other extensions
   // that have the same lexer (plx, pm, etc)
   //
   _str extensionSetRE = "^Extension " :+ lang :+ "$";
   typeless indexes[]=null;
   _xmlcfg_find_simple_array(xml_handle,'//ErrorExpressions/Tool',indexes);
   int len=indexes._length();
   int foundNode = -1;
   int i;
   for ( i=0;i<len;++i ) {
      // Get the names of the Tools and add them to the drop-down combo box control
      _str toolName =_xmlcfg_get_attribute(xml_handle,indexes[i],"Name",0);
      if (pos(extensionSetRE, toolName, 1, "IU")) {
         foundNode = indexes[i];
         break;
      }
   }

   return foundNode;
}


/**
 * Looks for and loads extension-specific error parsing expressions
 *
 * @param xml_handle    Handle to the XML configuration DOM
 * @param lang          Language to find an expression set for
 *
 * @see findExtensionSpecificSet
 */
static void loadLanguageSpecificErrorExpressions(int xml_handle, _str lang)
{
   // See if there is a section in the error configuration file
   // for this file extension (or it's refer-to extension)
   int extensionNode = findLanguageSpecificSet(xml_handle, lang);
   if(extensionNode > 0) {
      readExpressionsByPriority(xml_handle, extensionNode, extExpressions);
   }
}

/**
 * Loads the default (global) error-parsing regular expressions
 * from the ErrorRE.xml configuration file. These are expressions
 * for all extensions.
 *
 * @param xml_handle Handle to the XML configuration DOM
 *
 */
static void loadDefaultErrorExpressions(int xml_handle)
{
   // Get the top-level items
   int priority = 0;
   _str toolXpath = '//Tool[@Priority="' :+ (priority) :+ '"]';
   int toolIdx = _xmlcfg_find_simple(xml_handle, toolXpath, TREE_ROOT_INDEX);
   while (toolIdx > -1) {
      // Skip this node if the name attribute starts with "Extension"
      // or "Exclu" (for Exclude, Exclusions)
      _str toolName =_xmlcfg_get_attribute(xml_handle, toolIdx, "Name", 0);
      if (pos("^Extension", toolName, 1, "IU") == 0 && pos("^Exclu", toolName, 1, "IU") == 0) {
         // If this node has the Enabled="0" attribute, then skip it
         _str enabled =_xmlcfg_get_attribute(xml_handle, toolIdx, "Enabled", "1");
         if (enabled :== "1") {
            readExpressionsByPriority(xml_handle, toolIdx, allExpressions);
         }
      }

      // Find the tool with the next priority value
      toolXpath = '//Tool[@Priority="' :+ (++priority) :+ '"]';
      toolIdx = _xmlcfg_find_simple(xml_handle, toolXpath, TREE_ROOT_INDEX);
   }
}

/**
 * Loads the "false positive" error-parsing regular expressions
 * from the ErrorRE.xml configuration file. These are expressions
 * that we don't want to be read as real error line.
 *
 * @param xml_handle Handle to the XML configuration DOM
 *
 */
static void loadExclusionExpressions(int xml_handle)
{
   // Get the top-level items
   int priority = 0;
   _str toolXpath = '//Tool[@Priority="' :+ (priority) :+ '"]';
   int toolIdx = _xmlcfg_find_simple(xml_handle, toolXpath, TREE_ROOT_INDEX);
   while (toolIdx > -1) {
      // Skip this node if the name attribute starts with "Extension"
      // or "Exclu" (for Exclude, Exclusions)
      _str toolName =_xmlcfg_get_attribute(xml_handle, toolIdx, "Name", 0);
      if (pos("^Exclu", toolName, 1, "IU")) {
         // If this node has the Enabled="0" attribute, then skip it
         _str enabled =_xmlcfg_get_attribute(xml_handle, toolIdx, "Enabled", "1");
         if (enabled :== "1") {
            readExpressionsByPriority(xml_handle, toolIdx, exclusionExpressions);
         }
      }

      // Find the tool with the next priority value
      toolXpath = '//Tool[@Priority="' :+ (++priority) :+ '"]';
      toolIdx = _xmlcfg_find_simple(xml_handle, toolXpath, TREE_ROOT_INDEX);
   }
}

/**
 * Read all the error parsing expressions in this category
 *
 * @param xml_handle Handle to the error config XML DOM
 * @param nodeIndex  Node index of the category (Tool node)
 */
static void readExpressionsByPriority(int xml_handle, int nodeIndex, COLLECTION_ITEM (&collection)[])
{
   // Read the expressions for this tool/category
   int priority = 0;
   _str expXpath = 'Expression[@Priority="' :+ (priority) :+ '"]';
   int expIdx = _xmlcfg_find_simple(xml_handle, expXpath, nodeIndex);
   while (expIdx > -1) {
      cacheExpressionDetails(xml_handle, expIdx, collection);

      expXpath = 'Expression[@Priority="' :+ (++priority) :+ '"]';
      expIdx = _xmlcfg_find_simple(xml_handle, expXpath, nodeIndex);
   }
}

/**
 * Read all the error parsing expressions in this category
 *
 * @param xml_handle Handle to the error config XML DOM
 * @param nodeIndex  Node index of the category (Tool node)
 */
static void readDefaultExpressionsByPriority(int xml_handle, int nodeIndex)
{
   // Read the expressions for this tool/category
   int priority = 0;
   _str expXpath = 'Expression[@Priority="' :+ (priority) :+ '"]';
   int expIdx = _xmlcfg_find_simple(xml_handle, expXpath, nodeIndex);
   while (expIdx > -1) {
      cacheDefaultExpressionDetails(xml_handle, expIdx);

      expXpath = 'Expression[@Priority="' :+ (++priority) :+ '"]';
      expIdx = _xmlcfg_find_simple(xml_handle, expXpath, nodeIndex);
   }
}

/**
 * Read all the error parsing expressions in this extension-specific category
 *
 * @param xml_handle Handle to the error config XML DOM
 * @param nodeIndex  Node index of the extension category (Tool node)
 */
static void readExtExpressionsByPriority(int xml_handle, int nodeIndex)
{
   // Read the expressions for this tool/category
   int priority = 0;
   _str expXpath = 'Expression[@Priority="' :+ (priority) :+ '"]';
   int expIdx = _xmlcfg_find_simple(xml_handle, expXpath, nodeIndex);
   while (expIdx > -1) {
      cacheExtExpressionDetails(xml_handle, expIdx);

      expXpath = 'Expression[@Priority="' :+ (++priority) :+ '"]';
      expIdx = _xmlcfg_find_simple(xml_handle, expXpath, nodeIndex);
   }
}

/**
 * Read all the error parsing expressions in an "exclusion"
 * (false positive) category
 *
 * @param xml_handle Handle to the error config XML DOM
 * @param nodeIndex  Node index of the category (Tool node)
 */
static void readExclusionExpressionsByPriority(int xml_handle, int nodeIndex)
{
   // Read the expressions for this tool/category
   int priority = 0;
   _str expXpath = 'Expression[@Priority="' :+ (priority) :+ '"]';
   int expIdx = _xmlcfg_find_simple(xml_handle, expXpath, nodeIndex);
   while (expIdx > -1) {
      cacheExclusionExpressionDetails(xml_handle, expIdx);

      expXpath = 'Expression[@Priority="' :+ (++priority) :+ '"]';
      expIdx = _xmlcfg_find_simple(xml_handle, expXpath, nodeIndex);
   }
}

static void cacheExpressionDetails(int xml_handle, int nodeIndex, COLLECTION_ITEM (&collection)[])
{
   // TODO: Instead of display, just populate the global array?
   _str reName =_xmlcfg_get_attribute(xml_handle,nodeIndex,"Name",0);
   _str enabled =_xmlcfg_get_attribute(xml_handle, nodeIndex, "Enabled", "1");
   //say('Found expression 'reName' . Enabled == 'enabled);

   // If this node has the Enabled="0" attribute, then skip it
   if (enabled :== "1") {
      // Underneath the Expression node is the <RE> node, with a CDATA element
      // The CDATA element contains the text of the regular expression
      _str regexString = '';
      int reNodeIdx = _xmlcfg_find_child_with_name(xml_handle, nodeIndex, "RE");
      if (reNodeIdx > -1) {
         int cdataIdx = _xmlcfg_get_first_child(xml_handle, reNodeIdx, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
         if (cdataIdx > -1) {
            regexString = _xmlcfg_get_value(xml_handle, cdataIdx);

            //say("\t" :+ reName :+ "\t" :+ regexString);
         }
      }

      // The "Macro" attribute defines the macro that will be used
      // for parsing the expression output. The macro node is defined
      // in the XML schema, but it's just not being used right now
      _str macro = _xmlcfg_get_attribute(xml_handle, nodeIndex, 'Macro', '');

      // Add the expression and the macro to the target hashtable
      //collection:[regexString] = macro;
      collection[collection._length()].regex = regexString;
      collection[collection._length()-1].macro = macro;
   }
}

static void cacheDefaultExpressionDetails(int xml_handle, int nodeIndex)
{
   // TODO: Instead of display, just populate the global array?
   _str reName =_xmlcfg_get_attribute(xml_handle,nodeIndex,"Name",0);
   _str enabled =_xmlcfg_get_attribute(xml_handle, nodeIndex, "Enabled", "1");
   //say('Found expression 'reName' . Enabled == 'enabled);

   // If this node has the Enabled="0" attribute, then skip it
   if (enabled :== "1") {
      // Underneath the Expression node is the <RE> node, with a CDATA element
      // The CDATA element contains the text of the regular expression
      _str regexString = '';
      int reNodeIdx = _xmlcfg_find_child_with_name(xml_handle, nodeIndex, "RE");
      if (reNodeIdx > -1) {
         int cdataIdx = _xmlcfg_get_first_child(xml_handle, reNodeIdx, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
         if (cdataIdx > -1) {
            regexString = _xmlcfg_get_value(xml_handle, cdataIdx);

            //say("\t" :+ reName :+ "\t" :+ regexString);
         }
      }

      // The "Macro" attribute defines the macro that will be used
      // for parsing the expression output. The macro node is defined
      // in the XML schema, but it's just not being used right now
      _str macro = _xmlcfg_get_attribute(xml_handle, nodeIndex, 'Macro', '');

      // Add the expression and the macro to the target hashtable
      allExpressions[allExpressions._length()].regex=regexString;
      allExpressions[allExpressions._length()-1].macro=macro;
   }
}

static void cacheExtExpressionDetails(int xml_handle, int nodeIndex)
{
   // TODO: Instead of display, just populate the global array?
   _str reName =_xmlcfg_get_attribute(xml_handle,nodeIndex,"Name",0);
   _str enabled =_xmlcfg_get_attribute(xml_handle, nodeIndex, "Enabled", "1");
   // If this node has the Enabled="0" attribute, then skip it
   //say('Found expression 'reName' . Enabled == 'enabled);
   if (enabled :== "1") {
      // Underneath the Expression node is the <RE> node, with a CDATA element
      // The CDATA element contains the text of the regular expression
      _str regexString = '';
      int reNodeIdx = _xmlcfg_find_child_with_name(xml_handle, nodeIndex, "RE");
      if (reNodeIdx > -1) {
         int cdataIdx = _xmlcfg_get_first_child(xml_handle, reNodeIdx, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
         if (cdataIdx > -1) {
            regexString = _xmlcfg_get_value(xml_handle, cdataIdx);

            //say("\t" :+ reName :+ "\t" :+ regexString);
         }
      }

      // The "Macro" attribute defines the macro that will be used
      // for parsing the expression output
      _str macro = _xmlcfg_get_attribute(xml_handle, nodeIndex, 'Macro', '');

      // Add the expression and the macro to the target hashtable
      extExpressions[extExpressions._length()].regex=regexString;
      extExpressions[extExpressions._length()-1].macro = macro;
   }
}

static void cacheExclusionExpressionDetails(int xml_handle, int nodeIndex)
{
   // TODO: Instead of display, just populate the global array?
   _str reName =_xmlcfg_get_attribute(xml_handle,nodeIndex,"Name",0);
   _str enabled =_xmlcfg_get_attribute(xml_handle, nodeIndex, "Enabled", "1");
   // If this node has the Enabled="0" attribute, then skip it
   //say('Found expression 'reName' . Enabled == 'enabled);
   if (enabled :== "1") {
      // Underneath the Expression node is the <RE> node, with a CDATA element
      // The CDATA element contains the text of the regular expression
      _str regexString = '';
      int reNodeIdx = _xmlcfg_find_child_with_name(xml_handle, nodeIndex, "RE");
      if (reNodeIdx > -1) {
         int cdataIdx = _xmlcfg_get_first_child(xml_handle, reNodeIdx, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
         if (cdataIdx > -1) {
            regexString = _xmlcfg_get_value(xml_handle, cdataIdx);

            //say("\t" :+ reName :+ "\t" :+ regexString);
         }
      }

      // The "Macro" attribute defines the macro that will be used
      // for parsing the expression output
      _str macro = _xmlcfg_get_attribute(xml_handle, nodeIndex, 'Macro', '');

      // Add the expression and the macro to the target hashtable
      exclusionExpressions[exclusionExpressions._length()].regex=regexString;
      exclusionExpressions[exclusionExpressions._length()-1].macro=macro;
   }
}

/**
 * This method creates the ErrorRE.xml configuration file from scratch
 *
 * @return Handle to the newly created XML DOM
 * @example This method creates the ErrorRE.xml configuration file from scratch. It replaces
 * all of the static and global declarations that used to be found hardcoded in Error.e
 * The configuration file is read when init_error() is called. If the file isn't there,
 * this method will fill it out with the "factory defaults". Once the ErrorRe.xml file
 * is in the user's config directory, the user can use the new GUI dialog to modify this file.
 */
static int createErrorConfigFile()
{
   // Create the file from scratch. Write it into the configuration directory
   int openStatus = 0;
   _str config_file = _ConfigPath() :+ ERROR_RE_CONFIG_FILENAME;
   int xml_handle = _xmlcfg_create(config_file, VSENCODING_UTF8, VSXMLCFG_CREATE_IF_EXISTS_CLEAR);
   if (xml_handle >= 0) {
#if __UNIX__
      int unixEnabled = 1;
      int windowsEnabled = 0;
#else
      int unixEnabled = 0;
      int windowsEnabled = 1;
#endif
      int toolPriority = 0;

      // These expressions (and the rules for the platforms) are taken
      // from the global initializers in error.e
      int docRoot = createDocumentRoot(xml_handle);

      // Create the "default" Tool expressions. These expressions are used
      // for parsing errors on all platforms
      int defNode = createToolNode(xml_handle,docRoot,"default", toolPriority, 1);
      if (defNode > 0) {
         toolPriority++;
         int expressionPriority = 0;

         createExpressionNode(xml_handle, defNode, "def1", "def_error_re", expressionPriority++, 1,
                              '^\*@(cfe\: (Error|Warning)\:|error(~:f|[*:])|warning(~:f|[:*])|\(|<|)\*@ *{:q|(.\\|):p}( +| *\(|\:|, line ){:d#}(,|\:|)( *{:d#}|> :i|)(\)|) @(error|){(\:|Error[~s]|Fatal|Warning)?*$}', "");

         createExpressionNode(xml_handle, defNode, "def2", "def_error_re2", expressionPriority++, 1,
                              '^link *\:?*\:{}{}{}{?*}$', "");

         createExpressionNode(xml_handle, defNode, "def4", "_error_re4", expressionPriority++, 1,
                              '^({#3?@} at ){#0:p} line {#1:i}?*$', "");
         createExpressionNode(xml_handle, defNode, "Python", "", expressionPriority++, 1,
                              '^  File \"{#0[^"]+}\", line {#1:i}?*(\n|\r\n|\r)?*(\n|\r\n|\r)( *?\^(\n|\r\n|\r)|){#3[^ ]+\: ?*}$', "  File \"junk5.py\", line 1\n    x=import\n          ^\nSyntaxError: invalid syntax\n\n  File \"test.py\", line 21, in <module>\n    foo.bar()\nAttributeError: Foo instance has no attribute 'bar'\n");
      }

      // Separate node for Java, enabled by default
      int javaNode = createToolNode(xml_handle,docRoot,"Java", toolPriority, 1);
      if (javaNode > 0) {
         toolPriority++;
         int expressionPriority = 0;

         createExpressionNode(xml_handle, javaNode, "NJikes", "_error_javacNjikes", expressionPriority++, 1,
                              '^{#0?*}\:{#1:i}\:({#2:i}\:{#3?*$}|{#2}{#3?*$})', "");

         createExpressionNode(xml_handle, javaNode, "JBuilder", "_error_jbuilder", expressionPriority++, 1,
                              '^[ \t]@\"{#0:p}\"\: {#3Error \#\: :i \: ?*} at line {#1:i}, column {#2:i}$', "\"Frame1.java\": Error #: 202 : 'class' or 'interface' expected at line 8, column 1");

         createExpressionNode(xml_handle, javaNode, "Exception", "_error_javaException", expressionPriority++, 1,
                              '^\tat [~ \t]#((.[~ \t]#)*)\({#0?#}\:{#1:i}\)', "at com.slickedit.guibuilder.GUICmdSequencer.setProperty(GUICmdSequencer.java:286)");

         createExpressionNode(xml_handle, javaNode, "Maven", "none", expressionPriority++, 1,
                              '^\[ERROR\]:b{#0:p}\:\[{#1:n}\,{#2:n}\]:b{#3?#}$', '[ERROR] App.java:[11,18] cannot find symbol');

         createExpressionNode(xml_handle, javaNode, "Exception2", "_error_javaException2", expressionPriority++, 0,
                              '^\tat:b#{#0[~\(]#}\({#1[~\)\:]#}\)', '');

         createExpressionNode(xml_handle, javaNode, "Exception3", "_error_javaException3", expressionPriority++, 0,
                              '^\tat:b#{#0[~\(]#}\({#1?#}\:{#2:i}\)', '');

         createExpressionNode(xml_handle, javaNode, "JUnit", "_error_junitExceptionHeader", expressionPriority++, 0,
                              '^:i\):b#{#0[~\(]#}\({#1[~\)]#}\)', '');
      }

      // Create an area for "false-positive" exclusion expressions
      int exclusionNode = createToolNode(xml_handle,docRoot,'Exclusions', toolPriority, 1);
      if(exclusionNode > 0) {
         toolPriority++;
         int expressionPriority = 0;
         createExpressionNode(xml_handle, exclusionNode, "Total Time", "", expressionPriority++, 1,
                              '^\-+:btotal:btime\::b:i\::i\::i$', '---------- Total Time: 0:00:22');
         createExpressionNode(xml_handle, exclusionNode, "In file included from", "", expressionPriority++, 1,
                              'in file included from :p\::d', 'In file included from file.cpp:13');

      }

      // Create the tool node for error parsing expressions on Unix platforms
      int unixNode = createToolNode(xml_handle,docRoot,"Unix Defaults", toolPriority, unixEnabled);
      if (unixNode > 0) {
         toolPriority++;
         int expressionPriority = 0;
         createExpressionNode(xml_handle, unixNode, "COB-390", "_error_re_cob_390", expressionPriority++, 1,
                              '^ *{#1:i}  :c:c:c:c:c:d:d:d:d-:c   {#0}{#2}{#3?*$}', "5  IGYPS2072-S   \"DISSPLAY\" was invalid.  Skipped to the next verb, period");

         createExpressionNode(xml_handle, unixNode, "FOR-390", "_error_re_for_390", expressionPriority++, 1,
                              '^ISN +{#1:i}\:{#0}{#2}{#3}', "ISN     4:200       READZ (1,250,END=500) (INOUT(I),I=1,20)                       00021006");

         createExpressionNode(xml_handle, unixNode, "PL1-390", "_error_re_pl1_390", expressionPriority++, 1,
                              '^:c:c:c:d:d:d:d:c :c   {#1:i}{#0}{#2} +{#3?*$}', "IEL0304I S   3       INVALID SYNTAX IN ASSIGNMENT STATEMENT AFTER 'ERRORHERE'.    'ERRORHERE' IGNORED.");

         createExpressionNode(xml_handle, unixNode, "S-390", "_error_re_s_390", expressionPriority++, 1,
                              '^?*\*\* Record {#1:i} in {#0[~ ]+}{#2} +{#3?*$}', "");

         createExpressionNode(xml_handle, unixNode, "CC-390", "_error_re_cc_390", expressionPriority++, 1,
                              '^(error|warning) [~ \t]+ {#0:p}\:{#1:i}:b{#2}{#3?*$}', "");

         createExpressionNode(xml_handle, unixNode, "CPP-390", "_error_re_cpp_390", expressionPriority++, 1,
                              '^{#0:q}, line {#1:i}.{#2:i}\:{#3?*$}', "");
      }

      // Create the tool node for error parsing expressions on Windows platforms
      int winNode = createToolNode(xml_handle,docRoot,"Windows Defaults", toolPriority, windowsEnabled);
      if (winNode > 0) {
         toolPriority++;
         int expressionPriority = 0;
         createExpressionNode(xml_handle, winNode, "Visual Studio", "_error_visual_cpp", expressionPriority++, 1,
                              '^(:i>|[ \t]@){#0?*}\({#1:i}(,{#2:i}|{#2})\) *\: {#3?*$}', 'c:\Visual Studio Projects\testprj\testprj.cpp(29) : error C2078: too many initializers');
      }

      // These are for rarely used tools. By default, they will be disabled
      int miscNode = createToolNode(xml_handle,docRoot,"Other", toolPriority, 0);
      if (miscNode > 0) {
         toolPriority++;
         int expressionPriority = 0;
         createExpressionNode(xml_handle, miscNode, "Vantage", "_error_vantage_re", expressionPriority++, 0,
                              '^\*\*Error\: LINE {#1:i}{#0} \*\*\* {#3?*}$', '**Error: LINE 23 *** No legal integer type for integer literal >>0<<.');

         createExpressionNode(xml_handle, miscNode, "PV-Wave", "_error_re3", expressionPriority++, 0,
                              '^  At\: {#0:p}, Line {#1:i}$', "");

         createExpressionNode(xml_handle, miscNode, "Microfocus", "_microfocus_re", expressionPriority++, 0,
                              '^\*[ \t]+{#1:i}-[a-z]\*\*{#0}', "");
         if (windowsEnabled) {
            createExpressionNode(xml_handle, miscNode, "ActionScript (Macromedia Flash)", "_error_actionscript", expressionPriority++, 0,
                               '^\*\*Error\*\* {#0:p}\: Line {#1:i}\: {#2}{#3?*$}', "");
         }

         createExpressionNode(xml_handle, miscNode, "Lua (luac)", "", expressionPriority++, 0,
                              '^:p\: {#0:p}\:{#1:i}\: {#3?*$}', "");

      }

      // This is an empty area for further extension by the user
      int userNode = createToolNode(xml_handle,docRoot,"User", toolPriority, 0);
      if (userNode > 0) {
         toolPriority++;
      }

      _xmlcfg_save(xml_handle, -1, 0/*, null, VSENCODING_UTF8*/);
   }
   //_xmlcfg_close(xml_handle);
   return xml_handle;
}

// Set up the XML document root node for the error expressions XML config file
// Refer to the ErrorRE.xsd schema
static int createDocumentRoot(int xHandle)
{
   int docRoot = _xmlcfg_add(xHandle, TREE_ROOT_INDEX, 'ErrorExpressions', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   if (docRoot >= 0) {
      _xmlcfg_add_attribute(xHandle, docRoot, "xmlns", 'http://www.slickedit.com/schema/11.0/ErrorRE.xsd');
   }
   return docRoot;
}

// Create a "Tool" node in the error expressions XML config file
// Refer to the ErrorRE.xsd schema
static int createToolNode(int xHandle, int docRoot, _str toolName, int toolPriority, int enabled)
{
   int toolNode = _xmlcfg_add(xHandle, docRoot, 'Tool', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   if (toolNode > 0) {
      _xmlcfg_add_attribute(xHandle, toolNode, 'Name', toolName);
      _xmlcfg_add_attribute(xHandle, toolNode, 'Priority', toolPriority);
      _xmlcfg_add_attribute(xHandle, toolNode, 'Enabled', enabled);
   }
   return toolNode;
}

// Create an "Expression" node as a child of a "Tool" node in the error expression XML config file
// The Expression node contains the regex definition as well as optional test cases (sample matches)
// Refer to the ErrorRE.xsd schema
static int createExpressionNode(int xHandle, int toolRoot, _str expName, _str expOldName, int expPriority, int enabled, _str expression, _str matches)
{
   int expNode = _xmlcfg_add(xHandle, toolRoot, 'Expression', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   if (expNode > 0) {
      _xmlcfg_add_attribute(xHandle, expNode, 'Name', expName);
      _xmlcfg_add_attribute(xHandle, expNode, 'OldName', expOldName);
      _xmlcfg_add_attribute(xHandle, expNode, 'Priority', expPriority);
      _xmlcfg_add_attribute(xHandle, expNode, 'Enabled', enabled);
      int expText = _xmlcfg_add(xHandle, expNode, 'RE', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      if (expText > 0) {
         int expTextCDATA = _xmlcfg_add(xHandle, expText, '', VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
         if (expTextCDATA > 0) {
            _xmlcfg_set_value(xHandle, expTextCDATA, expression);
         }
      }

      if (matches != null && length(matches) > 0) {
         int matchText = _xmlcfg_add(xHandle, expNode, 'Matches', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         if (matchText > 0) {
            int matchTextCDATA = _xmlcfg_add(xHandle, matchText, '', VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            if (matchTextCDATA > 0) {
               _xmlcfg_set_value(xHandle, matchTextCDATA, matches);
            }
         }
      }
   }
   return expNode;
}

void _wkspace_close_clear_errors()
{
   clear_all_error_markers();
}

_command void goToBuildOutput (se.messages.Message* inMsg=null)
{
   if (inMsg == null) {
      return;
   }

   int orig_view_id;
   int temp_view_id;
   typeless status;
   typeless mark = '';

   status = activate_error_file(mark, temp_view_id);

   p_line = inMsg->m_attributes:['build window line'];
   _SetNextErrorMark(process_mark);

   activate_build();
}

static _str getMessageType(_str errMsg, _str matchText)
{
   // first, we check the error message
   if (pos(def_build_errors_re, errMsg, 1, 'IR') > 0) {
      return 'Error';
   }
   if (pos(def_build_warnings_re, errMsg, 1, 'IR') > 0) {
      return 'Warning';
   }

   // no?  well, check the entire match then
   if (pos(def_build_errors_re, matchText, 1, 'IR') > 0) {
      return 'Error';
   }
   if (pos(def_build_warnings_re, matchText, 1, 'IR') > 0) {
      return 'Warning';
   }

   // nothing
   return '(Info)';
}
