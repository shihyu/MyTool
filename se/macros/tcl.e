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
#import "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "context.e"
#import "cutil.e"
#import "math.e"
#import "notifications.e"
#import "pmatch.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  Don't modify this code unless defining extension specific
  aliases do not suit your needs.   For example, if you
  want your brace style to be:

       if [] {
          }

  Use the Language Options dialog 
  ("Document", "[Language] Options...]", "Aliases"). 
  and press the the "Alias" button to create a new alias.
  Type "if" for the name of the alias and press Enter.
  Enter the following text into the upper right editor control:

       if [%\c] {
       %\i}

  The  %\c indicates where the cursor will be placed after the
  "if" alias is expanded.  The %\i specifies to indent by the
  Extension Specific "Syntax Indent" amount define in the
  "Extension Options" dialog box.  Check the "Indent With Tabs"
  check box on the Extension Options dialog box if you want
  the %\i option to indent using tab characters.

*/
/*
  Options for TCL syntax expansion/indenting may be accessed from the
  Language Options ("Document", "[Language] Options...]", "Editing").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2             reserved.
       3             begin/end style.  Begin/end style may be 0,1, or 2
                     as show below.  Add 4 to the begin end style if you
                     want braces inserted when syntax expansion occurs
                     (main and do insert braces anyway).  Typing a begin
                     brace, '{', inserts an end brace when appropriate
                     (unless you unbind the key).  If you want a blank
                     line inserted in between, add 8 to the begin end
                     style.  Default is 4.

                      Style 0
                          if [] {
                             ++i;
                          }

                      Style 1
                          if []
                          {
                             ++i;
                          }

                      Style 2
                          if []
                            {
                            ++i;
                            }


       4             Indent first level of code.  Default is 1.
                     Specify 0 if you want first level statements to
                     start in column 1.
*/

static const TCL_LANGUAGE_ID= "tcl";

defeventtab tcl_keys;
def " "= tcl_space;
def "{"= tcl_begin;
def "}"= tcl_endbrace;
def "ENTER"= tcl_enter;
def "TAB"= smarttab;

_command void tcl_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(TCL_LANGUAGE_ID);
}
_command void tcl_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_tcl_expand_enter, true);
}
bool _tcl_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _tcl_supports_insert_begin_end_immediately() {
   return true;
}
_command void tcl_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
         tcl_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=="") {
      _undo('S');
   }
}
_command void tcl_begin() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   if ( command_state() || _in_comment() || tcl_expand_begin() ) {
      call_root_key("{");
   } else if (_argument=="") {
      _undo('S');
   }

}
_command void tcl_endbrace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   keyin("}");

   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      _in_comment() ) {
   } else if (_argument=="") {
      line := "";
      get_line(line);
      if (line=="}") {
         typeless col=tcl_endbrace_col();
         if (col) {
            replace_line(indent_string(col-1):+"}");
            p_col=col+1;
         }
      }
      _undo('S');
   }
}

/* Returns column where end brace should go.
   Returns 0 if this function does not know the column where the
   end brace should go.
 */
int tcl_endbrace_col()
{
   if (p_lexer_name=="") {
      return(0);
   }
   save_pos(auto p);
   --p_col;
   // Find matching begin brace
   typeless status=_find_matching_paren(def_pmatch_max_diff_ksize);
   if (status) {
      restore_pos(p);
      return(0);
   }
   // Assume end brace is at level 0
   if (p_col==1) {
      restore_pos(p);
      return(1);
   }
   begin_brace_col := p_col;
   // Check if the first char before open brace is close paren
   int col= find_block_col();
   if (!col) {
      restore_pos(p);
      return(0);
   }
   updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE);
   if (p_begin_end_style == BES_BEGIN_END_STYLE_2 || p_begin_end_style == BES_BEGIN_END_STYLE_3) {
      restore_pos(p);
      return(begin_brace_col);
   }
   restore_pos(p);
   return(col);
}

// check for line-continuations
static int _tcl_line_continuation_col()
{
   for (;;) {
      if (up()) break;
      _end_line(); left();
      if (get_text() != '\') {
         down();
         break;
      }
   }
   _first_non_blank();
   return(p_col);
}


static const BLOCK_WORDS= " for foreach if elseif method proc switch while ";
static int find_block_col()
{
   --p_col;
   if (_clex_skip_blanks('-')) return(0);
   /*
       Take advange of the fact that code is written like

          foreach -option {
          }
          foreach -option \
          {
          }

       and not like
          foreach -option
                {
          }

       This function does not find always find the beginning
       of a block in BLOCK_WORDS, but it helps in implementing
       the tcl_endbrace_col function.

   */
   for (;;) {
      while (get_text() == "}" || get_text() == "]") {
         if (_find_matching_paren(def_pmatch_max_diff_ksize)) return(0);
         if (p_col == 1) return(1);
         --p_col;
         if (_clex_skip_blanks("-")) return(0);
      }

      _tcl_line_continuation_col();
      if (get_text() != "}") {
         break;
      }
   }
   return(p_col);
}

/*
   TCL built-ins

AddErrInfo
after
Alloc
AllowExc
append
AppInit
array
AssocData
Async
BackgdErr
Backslash
bgerror
binary
BoolObj
break
CallDel
case
catch
cd
clock
close
CmdCmplt
Concat
concat
continue
CrtChannel
CrtChnlHdlr
CrtCloseHdlr
CrtCommand
CrtFileHdlr
CrtInterp
CrtMathFnc
CrtObjCmd
CrtSlave
CrtTimerHdlr
CrtTrace
DetachPids
DoOneEvent
DoubleObj
DoWhenIdle
DString
eof
error
Eval
eval
EvalObj
exec
Exit
exit
expr
ExprLong
ExprLongObj
fblocked
fconfigure
fcopy
file
fileevent
filename
FindExec
flush
for
foreach
format
GetIndex
GetInt
GetOpnFl
gets
GetStdChan
glob
global
Hash
history
http
if
incr
info
Interp
interp
IntObj
join
lappend
library
license.ter
lindex
LinkVar
linsert
list
ListObj
llength
load
lrange
lreplace
lsearch
lsort
man.macr
namespace
Notifier
Object
ObjectType
ObjSetVar
open
OpenFileChnl
OpenTcp
package
pid
pkgMkIndex
PkgRequire
Preserve
PrintDbl
proc
puts
pwd
read
RecEvalObj
RecordEval
RegExp
regexp
registry
regsub
rename
resource
return
safe
scan
seek
set
SetErrno
SetRecLmt
SetResult
SetVar
Sleep
socket
source
split
SplitList
SplitPath
StaticPkg
string
StringObj
StrMatch
subst
switch
Tcl
Tcl_Main
tclsh
tclvars
tell
time
trace
TraceVar
Translate
unknown
unset
update
uplevel
UpVar
upvar
variable
vwait
while
WrongNumAr
*/

static const TCL_EXPAND_WORDS= " catch for foreach if elseif proc switch while ";

static SYNTAX_EXPANSION_INFO tcl_space_words:[] = {
   "after"              => { "after" },
   "append"             => { "append" },
   "array"              => { "array" },
   "array anymore"      => { "array anymore" },
   "array donesearch"   => { "array donesearch" },
   "array exists"       => { "array exists" },
   "array get"          => { "array get" },
   "array names"        => { "array names" },
   "array nextelement"  => { "array nextelement" },
   "array set"          => { "array set" },
   "array size"         => { "array size" },
   "array startsearch"  => { "array startsearch" },
   "array statistics"   => { "array statistics" },
   "array unset"        => { "array unset" },
   "bgerror"            => { "bgerror" },
   "binary"             => { "binary" },
   "break"              => { "break" },
   "case"               => { "case" },
   "catch"              => { "catch { ... }" },
   "cd"                 => { "cd" },
   "clock"              => { "clock" },
   "clock add"          => { "clock add" },
   "clock clicks"       => { "clock clicks" },
   "clock format"       => { "clock format" },
   "clock microseconds" => { "clock microseconds" },
   "clock milliseconds" => { "clock milliseconds" },
   "clock scan"         => { "clock scan" },
   "clock seconds"      => { "clock seconds" },
   "concat"             => { "concat" },
   "continue"           => { "continue" },
   "dict"               => { "dict" },
   "dict append"        => { "dict append" },
   "dict create"        => { "dict create" },
   "dict exists"        => { "dict exists" },
   "dict filter"        => { "dict filter" },
   "dict for"           => { "dict for" },
   "dict get"           => { "dict get" },
   "dict incr"          => { "dict incr" },
   "dict info"          => { "dict info" },
   "dict keys"          => { "dict keys" },
   "dict lappend"       => { "dict lappend" },
   "dict merge"         => { "dict merge" },
   "dict remove"        => { "dict remove" },
   "dict replace"       => { "dict replace" },
   "dict set"           => { "dict set" },
   "dict size"          => { "dict size" },
   "dict unset"         => { "dict unset" },
   "dict update"        => { "dict update" },
   "dict values"        => { "dict values" },
   "dict with"          => { "dict with" },
   "default"            => { "default" },
   "else"               => { "else { ... }" },
   "elseif"             => { "elseif { ... } { ... }" },
   "eof"                => { "eof" },
   "error"              => { "error" },
   "exec"               => { "exec" },
   "exit"               => { "exit" },
   "expr"               => { "expr" },
   "fconfigure"         => { "fconfigure" },
   "fcopy"              => { "fcopy" },
   "file"               => { "file" },
   "file atime"         => { "file atime" },
   "file attributes"    => { "file attributes" },
   "file channels"      => { "file channels" },
   "file copy"          => { "file copy" },
   "file delete"        => { "file delete" },
   "file delete"        => { "file delete" },
   "file dirname"       => { "file dirname" },
   "file executable"    => { "file executable" },
   "file exists"        => { "file exists" },
   "file extension"     => { "file extension" },
   "file isdirectory"   => { "file isdirectory" },
   "file isfile"        => { "file isfile" },
   "file join"          => { "file join" },
   "file link"          => { "file link" },
   "file link"          => { "file link" },
   "file lstat"         => { "file lstat" },
   "file mkdir"         => { "file mkdir" },
   "file mtime"         => { "file mtime" },
   "file nativename"    => { "file nativename" },
   "file normalize"     => { "file normalize" },
   "file owned"         => { "file owned" },
   "file pathtype"      => { "file pathtype" },
   "file readable"      => { "file readable" },
   "file readlink"      => { "file readlink" },
   "file rename"        => { "file rename" },
   "file rootname"      => { "file rootname" },
   "file separator"     => { "file separator" },
   "file size"          => { "file size" },
   "file split"         => { "file split" },
   "file stat"          => { "file stat" },
   "file system"        => { "file system" },
   "file tail"          => { "file tail" },
   "file tempfile"      => { "file tempfile" },
   "file type"          => { "file type" },
   "file volumes"       => { "file volumes" },
   "file writable"      => { "file writable" },
   "fileevent"          => { "fileevent" },
   "filename"           => { "filename" },
   "flbocked"           => { "flbocked" },
   "flush"              => { "flush" },
   "for"                => { "for { ... } { ... } { ... } { ... }" },
   "foreach"            => { "foreach ... { ... }" },
   "format"             => { "format" },
   "gets"               => { "gets" },
   "glob"               => { "glob" },
   "global"             => { "global" },
   "history"            => { "history" },
   "history keep"       => { "history keep" },
   "history nextid"     => { "history nextid" },
   "history redo"       => { "history redo" },
   "history substitute" => { "history substitute" },
   "http"               => { "http" },
   "if"                 => { "if { ... } { ... }" },
   "incr"               => { "incr" },
   "info"               => { "info" },
   "info args"          => { "info args" },
   "info body"          => { "info body" },
   "info class"         => { "info class" },
   "info cmdcount"      => { "info cmdcount" },
   "info commands"      => { "info commands" },
   "info complete"      => { "info complete" },
   "info coroutine"     => { "info coroutine" },
   "info default"       => { "info default" },
   "info errorstack"    => { "info errorstack" },
   "info exists"        => { "info exists" },
   "info frame"         => { "info frame" },
   "info functions"     => { "info functions" },
   "info globals"       => { "info globals" },
   "info hostname"      => { "info hostname" },
   "info level"         => { "info level" },
   "info library"       => { "info library" },
   "info loaded"        => { "info loaded" },
   "info locals"        => { "info locals" },
   "info object"        => { "info object" },
   "info procs"         => { "info procs" },
   "info script"        => { "info script" },
   "info tclversion"    => { "info tclversion" },
   "info vars"          => { "info vars" },
   "join"               => { "join" },
   "lappend"            => { "lappend" },
   "library"            => { "library" },
   "lindex"             => { "lindex" },
   "linsert"            => { "linsert" },
   "list"               => { "list" },
   "llength"            => { "llength" },
   "load"               => { "load" },
   "lrange"             => { "lrange" },
   "lreplace"           => { "lreplace" },
   "lsearch"            => { "lsearch" },
   "lsort"              => { "lsort" },
   "namespace"          => { "namespace" },
   "namespace children" => { "namespace children" },
   "namespace code"     => { "namespace code" },
   "namespace current"  => { "namespace current" },
   "namespace delete"   => { "namespace delete" },
   "namespace ensemble" => { "namespace ensemble" },
   "namespace exists"   => { "namespace exists" },
   "namespace export"   => { "namespace export" },
   "namespace eval"     => { "namespace eval ... { ... } " },
   "namespace forget"   => { "namespace forget" },
   "namespace inscope"  => { "namespace inscope" },
   "namespace origin"   => { "namespace origin" },
   "namespace parent"   => { "namespace parent" },
   "namespace path"     => { "namespace path" },
   "namespace qualifiers" => { "namespace qualifiers" },
   "namespace tail"     => { "namespace tail" },
   "namespace upvar"    => { "namespace upvar" },
   "namespace unknown"  => { "namespace unknown" },
   "namespace which"    => { "namespace which" },
   "method"             => { "method ... { ... } { ... }" },
   "open"               => { "open" },
   "package"            => { "package" },
   "package forget"     => { "package forget" },
   "package ifneeded"   => { "package ifneeded" },
   "package names"      => { "package names" },
   "package present"    => { "package present" },
   "package provide"    => { "package provide" },
   "package require"    => { "package require" },
   "package unknown"    => { "package unknown" },
   "package vcompare"   => { "package vcompare" },
   "package versions"   => { "package versions" },
   "package vsatisfies" => { "package vsatisfies" },
   "package prefer"     => { "package prefer" },
   "pid"                => { "pid" },
   "proc"               => { "proc ... { ... } { ... }" },
   "puts"               => { "puts" },
   "pwd"                => { "pwd" },
   "read"               => { "read" },
   "regexp"             => { "regexp" },
   "registry"           => { "registry" },
   "regsub"             => { "regsub" },
   "rename"             => { "rename" },
   "resource"           => { "resource" },
   "return"             => { "return" },
   "safe"               => { "safe" },
   "scan"               => { "scan" },
   "seek"               => { "seek" },
   "set"                => { "set" },
   "socket"             => { "socket" },
   "source"             => { "source" },
   "split"              => { "split" },
   "string"             => { "string" },
   "string bytelength"  => { "string bytelength" },
   "string compare"     => { "string compare" },
   "string equal"       => { "string equal" },
   "string first"       => { "string first" },
   "string index"       => { "string index" },
   "string is"          => { "string is" },
   "string last"        => { "string last" },
   "string length"      => { "string length" },
   "string map"         => { "string map" },
   "string match"       => { "string match" },
   "string range"       => { "string range" },
   "string repeat"      => { "string repeat" },
   "string replace"     => { "string replace" },
   "string reverse"     => { "string reverse" },
   "string tolower"     => { "string tolower" },
   "string totitle"     => { "string totitle" },
   "string toupper"     => { "string toupper" },
   "string trim"        => { "string trim" },
   "string trimleft"    => { "string trimleft" },
   "string trimright"   => { "string trimright" },
   "string wordend"     => { "string wordend" },
   "string wordstart"   => { "string wordstart" },
   "subst"              => { "subst" },
   "switch"             => { "switch ... { ... }" },
   "tclsh"              => { "tclsh" },
   "tclvars"            => { "tclvars" },
   "tell"               => { "tell" },
   "then"               => { "then" },
   "time"               => { "time" },
   "trace"              => { "trace" },
   "trace add"          => { "trace add" },
   "trace remove"       => { "trace remove" },
   "trace info"         => { "trace info" },
   "trace variable"     => { "trace variable" },
   "trace vdelete"      => { "trace vdelete" },
   "trace vinfo"        => { "trace vinfo" },
   "unknown"            => { "unknown" },
   "unset"              => { "unset" },
   "update"             => { "update" },
   "uplevel"            => { "uplevel" },
   "variable"           => { "variable" },
   "vwait"              => { "vwait" },
   "while"              => { "while { ... } { ... }" },
};

static int _tcl_indent_col(int syntax_indent)
{
   col := 0;
   save_pos(auto p);
   left(); _clex_skip_blanks('-');
   status := search('^|[{}\\]', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(0);
      }
      if (p_col == 1) {
         // check for line-continuation
         col = _tcl_line_continuation_col();
         restore_pos(p);
         return(col);
      }
      ch := get_text();
      switch (ch) {
      case '\':
         // line-continuation, find start of command
         col = _tcl_line_continuation_col();
         restore_pos(p);
         return(col + syntax_indent);

      case "{":
         col = find_block_col();
         restore_pos(p);
         return(col + syntax_indent);

      case "}":
         if (_find_matching_paren(def_pmatch_max_diff_ksize)) return(0);
         break;
      }
      if (!status) {
         status = repeat_search();
      }
   }
   restore_pos(p);
   return(0);
}

static bool _tcl_split_brace_block(int syntax_indent)
{
   if (p_col > _text_colc(0,'E')) {
      return(false);
   }
   save_pos(auto p);
   search('[~ \t]|$','@rh');
   cfg := _clex_find(0, 'g');
   if (cfg != CFG_COMMENT && cfg != CFG_STRING) {
      ch := get_text();
      if (ch == "}") {
         right();
         col := _tcl_indent_col(syntax_indent);
         restore_pos(p);
         if (col) {
            indent_on_enter(0, col);
            get_line(auto line);
            replace_line(indent_string(col-1):+strip(line));
            return(true);
         }
      }
   }
   restore_pos(p);
   return(false);
}

bool _tcl_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;
   line_splits := _will_split_insert_line();
   if (line_splits && _tcl_split_brace_block(syntax_indent)) {
      return(false);
   }
   if (name_on_key(ENTER):=="nosplit-insert-line") {
      _end_line();
   }
   col := _tcl_indent_col(syntax_indent);
   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

/**
 * Tcl <b>SmartPaste&reg;</b>
 *
 * @return destination column
 */
int tcl_smartpaste(bool char_cbtype, int first_col)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   typeless status = _clex_skip_blanks('m');
   if (!status) {
      word := cur_word(auto junk);
      if (get_text() == "}") {
         ++p_col;
      } else {
         _begin_select(); up(); _end_line();
      }
   }
   col := _tcl_indent_col(syntax_indent);
   return col;
}

static typeless tcl_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;

   typeless status=0;
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');
   orig_word := strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   if_special_case := 0;
   first_word := second_word := rest := "";
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,tcl_space_words,"",aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   if ( word=="") {
      // Check for } else
      parse orig_line with first_word second_word rest;
      if (first_word=="}" && second_word!="" && rest=="" && second_word:==substr("els",1,length(second_word))) {
         keyin(substr("else ",length(second_word)+1));
         return(0);
      }
      // Check for else if or } else if
      if (first_word=="elseif" && orig_word==substr("elseif",1,length(orig_word))) {
         word="elseif";
         if_special_case=1;
      } else if (second_word=="elseif" && rest=="" && orig_word==substr("} elseif",1,length(orig_word))) {
         word="} elseif";
         if_special_case=1;
      } else if (first_word=="}elseif" && second_word=="" && orig_word==substr("}elseif",1,length(orig_word))) {
         word="}elseif";
         if_special_case=1;
      } else {
         return(1);
      }
   }
   if ( word=="") return(1);

   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN | AFF_BEGIN_END_STYLE);
   _str maybespace=p_no_space_before_paren?"":" ";
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   e1 := " {";
   if ( be_style == BES_BEGIN_END_STYLE_2 || be_style == BES_BEGIN_END_STYLE_3 ) {
      e1=' \';
   }
   if ( !LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) e1="";
   
   doNotify := true;
   set_surround_mode_start_line();
   if ( word=="if" || word=="elseif" || if_special_case) {
      replace_line(line:+maybespace:+"{}"e1);
      maybe_insert_braces(syntax_indent,be_style,width,word);
   } else if ( pos("else",word) ) {
      newLine := line:+e1;
      replace_line(newLine);
      maybe_insert_braces(syntax_indent,be_style,width,word);
      doNotify = (newLine != orig_line);
   } else if ( word=="for" ) {
      replace_line(line:+maybespace"{}"maybespace"{}"maybespace"{}"e1);
      maybe_insert_braces(syntax_indent,be_style,width,word);
   } else if ( word=="foreach" || word=="switch") {
      newLine := line" "e1;
      replace_line(newLine);
      maybe_insert_braces(syntax_indent,be_style,width,word);
      doNotify = (newLine != orig_line);
   } else if ( word=="return" ) {
      if (orig_word=="return") {
         keyin(" ");
         doNotify = false;
      } else {
         newLine := indent_string(width)"return ";
         replace_line(newLine);
         _end_line();
         doNotify = (newLine != orig_line);
      }
   } else if ( word=="proc" || word=="method" ) {
      tcl_insert_proc(word);
      doNotify = LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   } else if ( word=="while" ) {
      replace_line(line:+maybespace"{}"e1);
      maybe_insert_braces(syntax_indent,be_style,width,word);
   } else if ( word=="catch" ) {
      replace_line(line:+maybespace"{}");
      _end_line();left();
   } else if ( pos(" "word" ",TCL_EXPAND_WORDS) ) {
      newLine := indent_string(width)word" ";
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if ( word=="continue" || word=="break" ) {
      replace_line(indent_string(width)word);
      _end_line();
   } else if (word=="namespace eval") {
      replace_line(line:+maybespace:+e1);
      maybe_insert_braces(syntax_indent,be_style,width,word);
   } else if (word != orig_word) {
      replace_line(indent_string(width)word" ");
      _end_line();
   } else {
      status=1;
      doNotify = false;
   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return(status);
}
int _tcl_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, tcl_space_words, prefix, min_abbrev);
}
static tcl_expand_begin()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;
   expand := LanguageSettings.getAutoBracketEnabled(p_LangId, AUTO_BRACKET_BRACE);


   typeless brace_indent=0;
   keyin("{");
   line := "";
   get_line_raw(line);
   col := 0;
   int pcol=text_col(line,p_col,"P");
   last_word := "";
   if ( pcol-2>0 ) {
      i := lastpos('[~ ]',line,pcol-2,p_rawpos'r');
      if ( i && substr(line,i,1)=="}" ) {
         parse substr(line,pcol-1) with  last_word '/\*|//',(p_rawpos'r');
      }
   }
   
   if ( line!="{" ) {
      if ( last_word!="{" ) {
         first_word := second_word := "";
         parse line with first_word second_word;
         word := "";
         parse line with "}" word "{",p_rawpos +0 last_word "#",p_rawpos;
         if ( (last_word!="{" || word!="else") ) {
            return(0);
         }
      }
      if ( be_style == BES_BEGIN_END_STYLE_3 ) {
         brace_indent=syntax_indent;
         be_style= 0;
      }
   } else if ( be_style != BES_BEGIN_END_STYLE_3 ) {
      if ( ! prev_stat_has_semi() ) {
         old_col := p_col;
         up();
         if ( ! rc ) {
            _first_non_blank();p_col=p_col+syntax_indent+1;
            down();
         }
         col=p_col-syntax_indent-1;
         if ( col<1 ) {
            col=1;
         }
         if ( col<old_col ) {
            replace_line(indent_string(col-1)"{");
         }
      }
   }
   _first_non_blank();
   if ( expand ) {
      col=p_col-1;
      indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);
      if ( (col && (be_style == BES_BEGIN_END_STYLE_3)) || (! (indent_fl+col)) ) {
         syntax_indent=0;
      }
      insert_line(indent_string(col+brace_indent));
      tcl_endbrace();
      up();_end_line();
      if (LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId) ) {
         tcl_enter();
      }

      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   } else {
      _end_line();
   }
   return(0);

}
static typeless prev_stat_has_semi()
{
   col := 0;
   line := "";
   typeless status=1;
   up();
   if ( ! rc ) {
      col=p_col;_end_line();get_line_raw(line);
      parse line with line '\#',(p_rawpos'r');
      /* parse line with line '{' +0 last_word ; */
      /* parse line with first_word rest ; */
      /* status=stat_has_semi() or line='}' or line="" or last_word='{' */
      line=strip(line,'T');
      if (raw_last_char(line)==")") {
         save_pos(auto p);
         p_col=text_col(line);
         status=_find_matching_paren(def_pmatch_max_diff_ksize);
         if (!status) {
            status=search('[~( \t]','@-rh');
            if (!status) {
               if (!_clex_find(0,'g')==CFG_KEYWORD) {
                  status=1;
               } else {
                  junk := 0;
                  _str kwd=cur_word(junk);
                  status=!pos(" "kwd" ",BLOCK_WORDS);
               }
            }
         }
         restore_pos(p);
      } else {
         status=raw_last_char(line)!=")" && ! pos('(\}|)else$',line,1,p_rawpos'r');
      }
      down();
      p_col=col;
   }
   return(status);
}
static typeless stat_has_semi(...)
{
   line := "";
   get_line_raw(line);
   parse line with line "#",p_rawpos;
   line=strip(line,"T");
   return((raw_last_char(line):==";" || raw_last_char(line):=="}") &&
            (
               ! (( _will_split_insert_line()
                    ) && (p_col<=text_col(line) && arg(1)=="")
                   )
            )
         );

}
static void maybe_insert_braces(int syntax_indent,int be_style,int width,_str word)
{
   int col = width + length(word);
   get_line(auto line);
   if( substr(line,col+2,1) == "{" ) {
      // Position inside {}.
      // Used by control-structures like if, for, while, etc. where
      // syntax expansion automatically inserts a '{condition}' after
      // the keyword.
      col += 3;
   } else {
      // Position 1 space past the word.
      // Used by control-structures like foreach where placing a
      // brace-ified list after the keyword is optional and therefore
      // omitted by syntax expansion.
      col += 2;
   }
   if ( be_style == BES_BEGIN_END_STYLE_3 ) {
      width += syntax_indent;
   }
   if (p_no_space_before_paren) --col;
   if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
      up_count := 1;
      if ( be_style == BES_BEGIN_END_STYLE_2 || be_style == BES_BEGIN_END_STYLE_3 ) {
         up_count++;
         insert_line (indent_string(width)"{");
      }
      if ( LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId)) {
         up_count++;
         insert_line(indent_string(width+syntax_indent));
      }
      insert_line(indent_string(width)"}");
      set_surround_mode_end_line();
      up(up_count);
   }
   p_col=col;
   if ( ! _insert_state() ) { _insert_toggle(); }
}
/*
   It is no longer necessary to modify this function to
   create your own sub style.  Just define an extension
   specific alias.  See comment at the top of this file.
*/
static typeless tcl_insert_proc(_str proctype)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN);
   syntax_indent := p_SyntaxIndent;
   if(!LanguageSettings.getInsertBeginEndImmediately(p_LangId) || p_begin_end_style != BES_BEGIN_END_STYLE_3) {
      syntax_indent=0;
   }

   save_pos(auto p);
   _first_non_blank();
   width := p_col - 1;
   restore_pos(p);

   up_count := 0;
   if( LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
      up_count=1;
      _str maybespace=(p_no_space_before_paren)? "":" ";
      if( (p_begin_end_style == BES_BEGIN_END_STYLE_2) || (p_begin_end_style == BES_BEGIN_END_STYLE_3) ) {
         replace_line(indent_string(width):+proctype:+"  {}");
         insert_line(indent_string(width):+"{");
         ++up_count;
      } else {
         replace_line(indent_string(width):+proctype:+" "maybespace"{} {");
      }
      if( LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId)) {
         ++up_count;
         insert_line("");
      }
      insert_line(indent_string(width):+"}");
   } else {
      replace_line(proctype:+" ");
      _end_line();
   }

   up(up_count);
   p_col=width+length(proctype)+2;   // Put cursor after 'proc ' so user can keyin the name
   return(0);
}

#if 0
/* =========== TCL Tagging Support ================== */
typeless def_tcl_proto;

#define TCL_MODIFIER "public|private|protected|static"
#define TCL_MODIFIER2 "export|eval"
#define TCL_TAGTYPE  "body|configbody|global|variable|set|proc|method|constructor|destructor|class|namespace"

int tcl_proc_search(var proc_name,bool find_first)
{
   static _str cur_class_name;
   class_name := "";
   name := "";
   kind := "";
   if ( find_first ) {
      cur_class_name="";
      word_chars := _clex_identifier_chars();
      variable_re := '([/'word_chars']#)';
      if ( proc_name:=="" ) {
         // not searching for a specific tag
         name=variable_re;
      } else {
         // searching for a specific tag
         df := 0;
         tag_tree_decompose_tag(proc_name, name, class_name, kind, df);
         name=stranslate(name,'\:',':');
      }
      // groups:     #0 (modifier)                     #1 (proc_type)        #2 (modifier2)           #3 :: #4 (class_name)       #5 (proc_name)             #6 arguments
      search('^[ \t]@{'TCL_MODIFIER'|}[ \t]@(itcl\:\:|){'TCL_TAGTYPE'}[ \t]#({'TCL_MODIFIER2'}[ \t]#|){[:]@}{('variable_re'\:\:)@}{'variable_re'@}\c[ \t]@(\{{[ \t'word_chars']@}\}|)','@erh');
   } else {
      // next please
      repeat_search();
   }
   if ( rc ) {
      return rc;
   }
   tag_flags := 0;
   modifier := get_match_text(0);
   proc_type := get_match_text(1);
   modifier2 := get_match_text(2);
   typeless is_global=get_match_text(3);
   class_name=get_match_text(4);
   if (class_name!="") {
      class_name=substr(class_name,1,length(class_name)-2);
      class_name=stranslate(class_name,':','::');
   }
   proc_name=get_match_text(5);
   proc_args := get_match_text(6);
   if (is_global!="") cur_class_name="";
   switch (proc_type) {
   case 'namespace':
      proc_type="package";
      if (modifier2=='export') {
         return tcl_proc_search(proc_name,false);
      }
      proc_args="";
      cur_class_name=proc_name;
      if (class_name!="") {
         cur_class_name=class_name':'proc_name;
         proc_name=cur_class_name;
         class_name="";
      }
      break;
   case 'configbody':
      proc_type="prop";
      break;
   case 'body':
      proc_type="func";
      break;
   case 'proc':
      if (cur_class_name!="") {
         class_name=cur_class_name;
      }
      if (class_name!="") {
         tag_flags|=SE_TAG_FLAG_INCLASS;
      }
      proc_type="func";
      break;
   case 'method':
      class_name=cur_class_name;
      tag_flags|=SE_TAG_FLAG_INCLASS;
      proc_type="proto";
      break;
   case 'constructor':
   case 'destructor':
      if (cur_class_name!="" && class_name=="") {
         class_name=cur_class_name;
         tag_flags|=SE_TAG_FLAG_INCLASS;
      }
      if (proc_type=='constructor') {
         tag_flags=SE_TAG_FLAG_CONSTRUCTOR;
      } else {
         tag_flags=SE_TAG_FLAG_DESTRUCTOR;
      }
      tag_flags|=SE_TAG_FLAG_INCLASS;
      if (proc_name=="") {
         proc_name=proc_type;
         if (pos('::',cur_class_name)) {
            proc_name=substr(cur_class_name,lastpos('::',cur_class_name)+2);
         }
      }
      proc_type="proto";
      break;
   case 'class':
      proc_args="";
      cur_class_name=proc_name;
      if (class_name!="") {
         cur_class_name=class_name':'proc_name;
         proc_name=cur_class_name;
         class_name="";
      }
      break;
   case 'variable':
   case 'global':
   case 'set':
      proc_args="";
      proc_type='var';
      class_name=cur_class_name;
      tag_flags|=SE_TAG_FLAG_INCLASS;
      break;
   }
   switch (modifier) {
   case 'static':
      tag_flags|=SE_TAG_FLAG_STATIC;
      break;
   case 'public':
      tag_flags|=SE_TAG_FLAG_PUBLIC;
      break;
   case 'protected':
      tag_flags|=SE_TAG_FLAG_PROTECTED;
      break;
   case 'private':
      tag_flags|=SE_TAG_FLAG_PRIVATE;
      break;
   }
   if (proc_name=='constructor') {
      tag_flags|=SE_TAG_FLAG_CONSTRUCTOR;
   } else if (proc_name=='destructor') {
      tag_flags|=SE_TAG_FLAG_DESTRUCTOR;
   }
   if (proc_name=="") {
      return tcl_proc_search(proc_name,0);
   }
   proc_name=tag_tree_compose_tag(proc_name,class_name,proc_type,tag_flags,proc_args);
   return(0);
}
#endif

int _tcl_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   ext := "tcl";
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext) && !forceRebuild) {
      return(0);
   }

   // The user does not have an extension specific tag file for TCL
   status := 0;
   tcl_binary := "";
   if (_isWindows()) {
      status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                               "SOFTWARE\\Scriptics\\TclPro\\1.2",
                               "PkgPath", tcl_binary);
      if (status || tcl_binary=="") {
         status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                                  "SOFTWARE\\Scriptics\\TclPro\\1.1",
                                  "PkgPath", tcl_binary);
      }
      if (!status) {
         tcl_binary :+= "\\win32-ix86\\bin\\procomp.exe";
      }
      if (status || tcl_binary=="") {
         status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                                  "SOFTWARE\\Scriptics\\Tcl\\8.0",
                                  "", tcl_binary);
         if (tcl_binary!="") {
            tcl_binary :+= "\\bin";
         }
      }
   }
   if (tcl_binary=="") {
      tcl_binary=path_search("procomp","","P");
   }
   if (_isWindows()) {
      if (tcl_binary=="") {
         tcl_binary=_ntRegGetPythonPath();
         if (tcl_binary!="") {
            _maybe_append_filesep(tcl_binary);
            tcl_binary :+= "tcl":+FILESEP:+"tcl8.3";
         }
      }
   } else {
      if (tcl_binary=="" || tcl_binary=="/" || tcl_binary=="/usr/") {
         tcl_binary=latest_version_path("/usr/lib/tcl");
         if (tcl_binary=="") {
            tcl_binary=latest_version_path("/opt/tcl");
         }
         if (tcl_binary!="") {
            tcl_binary :+= "bin/tcl";
         }
      }
   }
   std_libs := "";
   if (tcl_binary!="") {
      path := _strip_filename(tcl_binary,"n");
      _maybe_strip_filesep(path);
      name := _strip_filename(path,"p");
      if (_file_eq(name,"bin")) {
         path=_strip_filename(path,"n");
         _maybe_strip_filesep(path);
      }
      name=_strip_filename(path,"p");
      if (_file_eq(name,"win32-ix86")) {
         path=_strip_filename(path,"n");
      }
      _maybe_append_filesep(path);
      source_path := file_match(_maybe_quote_filename(path:+"lib"), 1);
      if (source_path!="") {
         path :+= "lib":+FILESEP;
      }
      std_libs=_maybe_quote_filename(path:+"*.tcl"):+" ":+_maybe_quote_filename(path:+"*.itk");
      //say("_tcl_MaybeBuildTagFile: path="path" std_libs="std_libs);
   }

   return ext_BuildTagFile(tfindex,tagfilename,ext,"TCL Libraries",
                           true,std_libs,ext_builtins_path(ext), 
                           withRefs, useThread);
}

/**
 * Checks to see if the first thing on the current line is an 
 * open brace.  Used by comment_erase (for reindentation). 
 * 
 * @return Whether the current line begins with an open brace.
 */
bool tcl_is_start_block()
{
   return c_is_start_block();
}

static int tcl_before_id(VS_TAG_IDEXP_INFO &idexp_info)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (idexp_info.otherinfo == "$") {
      return 0;
   }

   word_chars := _clex_identifier_chars();
   status := 0;
   prefixexp := "";
   prefixexp_offset := 0;
   while (p_col > 1) {
      done := true;
      ch := get_text_safe();
      if (ch == ":") {
         if (p_col > 1) {
            left();
            ch = get_text_safe();
            if (ch == ":" && p_col > 1) {
               left(); done = false;
            }
         }
      }
      if (done) {
         break;
      }

      if (pos('['word_chars']',get_text(),1,'r')) {
         end_col := p_col + 1;
         search('[~'word_chars']\c|^\c','-rh@');
         ch = get_text_safe();
         if (ch != "$") {
            idname := _expand_tabsc(p_col,end_col-p_col);
            if (prefixexp != "") {
               prefixexp = idname:+VS_TAGSEPARATOR_package:+prefixexp;
            } else {
               prefixexp = idname;
            }
            prefixexp_offset = (int)point('s');
            left();
         }
      }
   }
   if (prefixexp != "") {
      idexp_info.prefixexp = prefixexp;
      idexp_info.prefixexpstart_offset = prefixexp_offset;
   }
   return status;
}
/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _tcl_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   done := false;
   status := 1;
   idexp_info.info_flags = VSAUTOCODEINFO_DO_LIST_MEMBERS;
   idexp_info.otherinfo = "";
   typeless orig_pos;
   save_pos(orig_pos);
   word_chars := _clex_identifier_chars();
   if (PossibleOperator) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);

   } else {
      // check color coding to see that we are not in a comment
      int cfg = _clex_find(0,'g');
      if (cfg == CFG_COMMENT) {
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      // IF we are not on an id character.
      if (pos('[~'word_chars']',get_text(),1,'r')) {
         first_col := 1;
         if (p_col > 1) {
            first_col = 0;
            left();
         }
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            right();
            idexp_info.lastid = "";
            idexp_info.lastidstart_col = p_col-first_col;
            idexp_info.lastidstart_offset = (int)point('s');
            done = true;
         }
      } 

      if (!done) {
         int old_TruncateLength = p_TruncateLength; p_TruncateLength = 0;
         _TruncSearchLine('[~'word_chars']|$','r');
         end_col := p_col;
         _TruncSearchLine('[~ \t]|$','r');
         p_col = end_col;
         left();
         search('[~'word_chars']\c|^\c','-rh@');
         lastid := _expand_tabsc(p_col,end_col-p_col);
         if (substr(lastid, 1, 1) == "$") {
            p_col++;
            idexp_info.otherinfo = "$";
         }
         idexp_info.lastid = _expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col = p_col;
         idexp_info.lastidstart_offset = (int)point('s');
         p_TruncateLength = old_TruncateLength;
         if (p_col > 1) {
            left();
         }
         status = 0;
      }

      if (status) {
         idexp_info.info_flags = 0;
         idexp_info.lastid = "";
      }

      if (!status) {
         status = tcl_before_id(idexp_info);
      }   
   }
   restore_pos(orig_pos);
   return(status);
}

int _tcl_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           bool find_parents,int max_matches,
                           bool exact_match,bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   tag_return_type_init(prefix_rt);
   tag_clear_matches();
   errorArgs._makeempty();
   if (_chdebug) {
      isay(depth,"_tcl_find_context_tags: lastid="lastid" prefixexp="prefixexp" otherinfo="otherinfo);
   }

   // get the tag file list
   num_matches := 0;
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   // get the current class from the context
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_flags,
                                         auto cur_type_name, auto cur_type_id,
                                         auto cur_context, auto cur_class,
                                         auto cur_package,
                                         visited, depth+1);


   if (otherinfo == "$") {
     if (cur_context != "" && cur_type_id == SE_TAG_TYPE_FUNCTION) {
         filter_flags = SE_TAG_FILTER_LOCAL_VARIABLE|SE_TAG_FILTER_MEMBER_VARIABLE;

      } else {
         filter_flags = SE_TAG_FILTER_GLOBAL_VARIABLE|SE_TAG_FILTER_MEMBER_VARIABLE;
      }
   }

   // no prefix expression, update globals and symbols from current context
   if (prefixexp == "") {
      if (context_flags & SE_TAG_CONTEXT_ALLOW_LOCALS) {
         tag_list_class_locals(0, 0, tag_files, lastid, "",
                               filter_flags, context_flags,
                               num_matches,max_matches,
                               exact_match, case_sensitive,
                               null, visited, depth+1);
      }

      // now update the globals in the current buffer
      if ((context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE) &&
          !(context_flags & SE_TAG_CONTEXT_NO_GLOBALS) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_THIS_CLASS)) {
         tag_list_context_globals(0, 0, lastid,
                                  true, tag_files,
                                  filter_flags, context_flags,
                                  num_matches, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth+1);
      }

      // now update the external globals
      if (!(context_flags & SE_TAG_CONTEXT_NO_GLOBALS) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_THIS_CLASS)) {
         tag_list_context_globals(0, 0, lastid,
                                  true, tag_files,
                                  filter_flags, context_flags,
                                  num_matches, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth+1);
      }

      // all done
      errorArgs[1] = lastid;
      return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   } else {
      if (find_parents) context_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
      _str template_args:[];

      context_flags |= SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE|SE_TAG_CONTEXT_NO_GLOBALS|SE_TAG_CONTEXT_ALLOW_PACKAGE;
      tag_list_symbols_in_context(lastid, prefixexp, 0, 0, 
                                  tag_files, "",
                                  num_matches, max_matches,
                                  filter_flags, context_flags,
                                  exact_match, case_sensitive, 
                                  visited, depth+1, template_args);
      if (_chdebug) {
         isay(depth,"_tcl_find_context_tags: tag_list_symbols_in_context num_matches="num_matches);
      }
   }

   if (_chdebug) {
      isay(depth,"_tcl_find_context_tags: num_matches="num_matches);
      n := tag_get_num_of_matches();
      for (i:=1; i<=n; ++i) {
         tag_get_match_info(i, auto cm);
         tag_browse_info_dump(cm, "_tcl_find_context_tags", 1);
      }
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=="")? "":lastid;
   return (num_matches <= 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

bool _tcl_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                        VS_TAG_IDEXP_INFO &idexp_info, 
                                        _str terminationKey="")
{
   return false;
}
