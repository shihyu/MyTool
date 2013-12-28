////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47587 $
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
#import "bookmark.e"
#import "cformat.e"
#import "cutil.e"
#import "debug.e" 
#import "files.e"
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
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

#define AFDEBUG_WINDOW   0
#define AFDEBUG_FILE     0

#define AFDEBUGFLAG_WINDOW 0x1
#define AFDEBUGFLAG_FILE   0x2
#define AFDEBUGFLAG_ALL    0x3

#define AF_NONE_SCHEME_NAME "(None)"


typedef struct {

/** @return int */
#define AFTYPE_INT 0

/** @return boolean */
#define AFTYPE_BOOLEAN 1

/** @return _str */
#define AFTYPE_STR 2

   int type;

/**
 * Check for type correctness.
 * @example
 * <pre>
 * Type        Value          Valid?
 * ---------------------------------
 * int        | -3           | yes
 * int        | 0            | yes
 * int        | 3            | yes
 * int        | true         | yes
 * int        | false        | yes
 * int        | apples       | no
 * boolean    | true         | yes
 * boolean    | false        | yes
 * boolean    | 0            | yes
 * boolean    | 1            | yes
 * boolean    | 3            | no
 * _str       | *            | yes
 * </pre>
 */
#define AFCONSTRAINT_SIMPLE 0

/**
 * Range test expression.
 * @example less-than 3: <3
 * @example greater-than-or-equal-to 0: >=0
 * @example greater-than-or-equal-to 0 and less-than-or-equal-to 3: >=0 && <=3
 * @example less-than 0 or greater-than 3: <0 || >3
 */
#define AFCONSTRAINT_RANGE 1

/**
 * List test expression.
 * @example 1,3,5,7,11,13,17
 */
#define AFCONSTRAINT_LIST 2

   int constraint_type;

   typeless constraint;
   typeless default_val;

} adaOption_t;

static adaOption_t gAdaOptionTab:[] = {

/** IndentWithTabs off. */
#define OPT_IWT_OFF     (0)
/** IndentWithTabs on. Leading indent will use tabs. */
#define OPT_IWT_ON      (1)
/** IndentWithTabs strict. Leading indent AND intraline indent will use tabs. */
#define OPT_IWT_STRICT  (2)
   "IndentWithTabs"         => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_IWT_OFF" && <="OPT_IWT_STRICT, OPT_IWT_OFF },

   "OneStatementPerLine"    => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },
   "OneDeclPerLine"         => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },
   "OneEnumPerLine"         => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },
   "OneParameterPerLine"    => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },

/** Operator at end of same line when breaking line on operator boundary. */
#define OPT_OPBIAS_SAME_LINE 0
/** Operator at beginning of next line when breaking line on operator boundary. */
#define OPT_OPBIAS_NEXT_LINE 1
   "OperatorBias" => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_OPBIAS_SAME_LINE" && <="OPT_OPBIAS_NEXT_LINE, OPT_OPBIAS_SAME_LINE },

#define OPT_PAD_PRESERVE (-1)
#define OPT_PAD_OFF      (0)
#define OPT_PAD_ON       (1)
   "PadBeforeBinaryOps"     => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PAD_PRESERVE" && <="OPT_PAD_ON, OPT_PAD_PRESERVE },
   "PadAfterBinaryOps"      => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PAD_PRESERVE" && <="OPT_PAD_ON, OPT_PAD_PRESERVE },

   "PadBeforeSemicolon"     => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PAD_PRESERVE" && <="OPT_PAD_ON, OPT_PAD_PRESERVE },
   "PadAfterSemicolon"      => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PAD_PRESERVE" && <="OPT_PAD_ON, OPT_PAD_PRESERVE },

   "PadBeforeComma"         => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PAD_PRESERVE" && <="OPT_PAD_ON, OPT_PAD_PRESERVE },
   "PadAfterComma"          => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PAD_PRESERVE" && <="OPT_PAD_ON, OPT_PAD_PRESERVE },

   "PadBeforeLeftParen"     => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PAD_PRESERVE" && <="OPT_PAD_ON, OPT_PAD_PRESERVE },
   "PadAfterLeftParen"      => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PAD_PRESERVE" && <="OPT_PAD_ON, OPT_PAD_PRESERVE },

   "PadBeforeRightParen"    => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PAD_PRESERVE" && <="OPT_PAD_ON, OPT_PAD_PRESERVE },
   "PadAfterRightParen"     => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PAD_PRESERVE" && <="OPT_PAD_ON, OPT_PAD_PRESERVE },

   "VAlignDeclColon"        => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },
   "VAlignDeclInOut"        => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },

   "VAlignSelector"         => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },
   "VAlignParens"           => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },
   "VAlignAssignment"       => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },
   "VAlignAdjacentComments" => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },

   "MaxLineLength"          => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">=0 && <=1024", 0 },
   "IndentPerLevel"         => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">=0 && <=20", 3 },
   "ContinuationIndent"     => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">=0 && <=20", 3 },
   "TabSize"                => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">=0 && <=20", 3 },
   "OrigTabSize"            => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">=0 && <=20", 3 },

#define OPT_WORDCASE_PRESERVE     (-1)
#define OPT_WORDCASE_LOWER        (0)
#define OPT_WORDCASE_UPPER        (1)
#define OPT_WORDCASE_CAPITALIZE   (2)
   "ReservedWordCase" => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_WORDCASE_PRESERVE" && <="OPT_WORDCASE_CAPITALIZE, OPT_WORDCASE_PRESERVE },

#define OPT_PRESERVE_BLANK_LINES (-1)
   "BLBeforeSubprogramDecl"        => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAfterSubprogramDecl"         => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAdjacentSubprogramDecl"      => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },

   "BLBeforeSubprogramBody"        => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAfterSubprogramBody"         => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAdjacentSubprogramBody"      => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },

   "BLBeforeTypeDecl"              => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAfterTypeDecl"               => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAdjacentTypeDecl"            => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },

   "BLBeforeAspectClause"       => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAfterAspectClause"        => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAdjacentAspectClause"     => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },

   "BLBeforeSubunitHeader"         => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAfterSubunitHeader"          => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },

   "BLBeforeBegin"                 => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAfterBegin"                  => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },

   "BLBeforeIf"                    => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAfterIf"                     => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },

   "BLBeforeReturn"                => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAfterReturn"                 => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },

   "BLBeforeLoop"                  => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAfterLoop"                   => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },

   "BLBeforeNestedParenListItem"   => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },
   "BLAfterNestedParenListItem"    => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_PRESERVE_BLANK_LINES" && <=20", OPT_PRESERVE_BLANK_LINES },

   "CommentAfterTypeDeclIndent"        => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">=0 && <=20", 0 },

#define OPT_TCOMMENT_COL           (0)
#define OPT_TCOMMENT_INDENT        (1)
#define OPT_TCOMMENT_ORIGRELINDENT (2)
   "TrailingComment"        => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">="OPT_TCOMMENT_COL" && <="OPT_TCOMMENT_ORIGRELINDENT, OPT_TCOMMENT_ORIGRELINDENT },
   "TrailingCommentCol"     => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">=0 && <=120", 80 },
   "TrailingCommentIndent"  => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">=0 && <=20", 3 },

   "NoTrailingTypeDeclComments" => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },

   "IfBreakOnLogicalOps"                       => { AFTYPE_BOOLEAN, AFCONSTRAINT_SIMPLE, null, false },
   "IfLogicalOpAddContinuationIndent"          => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">=0 && <=20", 0 },
   "IfLogicalOpLogicalOpAddContinuationIndent" => { AFTYPE_INT, AFCONSTRAINT_RANGE, ">=0 && <=20", 0 },

};

static typeless gAdminOptions:[];

struct adaScheme_t {

   // All formatting options for this scheme
   typeless options:[];

};

static boolean isValidOption(_str optionName, typeless val)
{
   adaOption_t* option = gAdaOptionTab._indexin(optionName);
   if( !option ) {
      // It is no option that we know about, so assume it is okay
      return true;
   }

   // Disallow null option values
   if( val==null ) return false;

   // Simple type tests
   if( option->constraint_type==AFCONSTRAINT_SIMPLE ) {
      if( option->type==AFTYPE_INT && isinteger(val) ) {
         return true;
      }
      if( option->type==AFTYPE_STR ) {
         return true;
      }
      if( option->type==AFTYPE_BOOLEAN && (val==true || val==false) ) {
         return true;
      }
   }

   // Complex type tests
   _str c='';
   if( option->constraint_type==AFCONSTRAINT_LIST ) {
      if( option->type==AFTYPE_INT ) {
         if( !isinteger(val) ) {
            return false;
         }
         _str constraint = option->constraint;
         if( constraint=="" ) {
            // It passes automatically if there is no constraint
            return true;
         }
         while( constraint!="" ) {
            parse constraint with c ',' constraint;
            if( !isinteger(c) ) {
               // Bad constraint. What to do, what to do?
               _message_box("Bad constraint for option: "optionName);
               return false;
            }
            if( (int)val==(int)c ) {
               return true;
            }
         }
         // If we got here, then no constraint matched
         return false;
      }
      if( option->type==AFTYPE_STR ) {
         _str constraint = option->constraint;
         if( constraint=="" ) {
            // It passes automatically if there is no constraint
            return true;
         }
         while( constraint!="" ) {
            parse constraint with c ',' constraint;
            if( strip(val):==strip(c) ) {
               return true;
            }
         }
         // If we got here, then no constraint matched
         return false;
      }
   }
   if( option->constraint_type==AFCONSTRAINT_RANGE ) {
      if( !isinteger(val) ) {
         return false;
      }
      _str constraint = option->constraint;
      if( constraint=="" ) {
         // It passes automatically if there is no constraint
         return true;
      }
      _str expr = "";
      while( constraint!="" ) {
         _str op='';
         parse constraint with c op constraint;
         expr=expr' 'val:+c' 'op;
      }
      typeless result;
      if( expr=="" || eval_exp(result,expr,10) ) {
         // Bad constraint. What to do, what to do?
         _message_box("Bad constraint for option: "optionName);
         return false;
      }
      return result;
   }

   // If we got here, then no types matched
   return false;
}

static typeless getDefaultOption(_str optionName)
{
   adaOption_t* option = gAdaOptionTab._indexin(optionName);
   if( !option ) {
      return null;
   }
   return option->default_val;
}

static void initOptions(typeless (&options):[])
{
   typeless optionName;
   for( optionName._makeempty();; ) {
      gAdaOptionTab._nextel(optionName);
      if( optionName._isempty() ) break;
      options:[optionName] = gAdaOptionTab:[optionName].default_val;
   }
}

static void enforceValidOptions(typeless (&options):[])
{
   typeless key;
   for( key._makeempty();; ) {
      options._nextel(key);
      if( key._isempty() ) break;
      if( !isValidOption(key,options:[key]) ) {
         options:[key] = getDefaultOption(key);
      }
   }
}

static int getScheme(adaScheme_t (&s):[], _str name, _str lang, boolean sync_lang_options)
{
   int temp_view_id=0;
   int orig_view_id=0;
   if( FormatSystemIniFilename()=='' ||
       _open_temp_view(FormatSystemIniFilename(),temp_view_id,orig_view_id) ) {
      return 1;
   }

   _str prefix=lang:+'-scheme-';
   getScheme2(s,prefix,name,sync_lang_options);

   // Delete the temp view
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   return 0;
}

static int getUserScheme(adaScheme_t (&s):[], _str name, _str lang, boolean sync_lang_options)
{
   int temp_view_id=0;
   int orig_view_id=0;
   if( FormatUserIniFilename()=='' ||
       _open_temp_view(FormatUserIniFilename(),temp_view_id,orig_view_id) ) {
      return 1;
   }

   _str prefix=lang:+'-scheme-';
   int status=getScheme2(s,prefix,name,sync_lang_options);

   // Delete the temp view
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   return status;
}

static int getAdminOptions(typeless (&options):[], _str lang)
{
   int temp_view_id=0;
   int orig_view_id=0;
   if( FormatAdminIniFilename()=='' ||
       _open_temp_view(FormatAdminIniFilename(),temp_view_id,orig_view_id) ) {
      return 1;
   }

   _str prefix=lang:+'-scheme-';
   // getScheme2() handles retrieving system and user schemes too, so it takes
   // a hash table of schemes.
   adaScheme_t s:[];
   s._makeempty();
   int status = getScheme2(s,prefix,'admin',false,false);
   // Delete the temp view
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   if( !status ) {
      typeless i;
      for( i._makeempty();; ) {
         s:['admin'].options._nextel(i);
         if( i._isempty() ) break;
         options:[i]=s:['admin'].options:[i];
      }
   }

   return status;
}

// Must call getAdminOptions() before calling mergeAdminOptions()
static void mergeAdminOptions(typeless (&options):[], _str lang)
{
   typeless i;
   for( i._makeempty();; ) {
      options._nextel(i);
      if( i._isempty() ) break;
      if( gAdminOptions._indexin(i) ) {
         options:[i] = gAdminOptions:[i];
      }
   }
}

/**
 * This function assumes we are in an ini view
 * Options have the format: name=val
 */
static int getScheme2(adaScheme_t (&s):[], _str prefix, _str name, 
                      boolean sync_lang_options, boolean init_options=true)
{
   _str ss="";
   if( name!="" ) {
      ss=prefix:+name;
   }

   parse prefix with auto lang '-' .;
   _str line='';
   _str section_name='';
   _str scheme_name='';
   _str varname='', val='';
   int sl=0, el=0;

   top();
   boolean found_one=false;
   do {
      if( _ini_find_section(ss) ) {
         break;
      }
      get_line(line);
      parse line with '[' section_name ']';
      parse section_name with (prefix) scheme_name;
      if( scheme_name=="" ) {
         // Not a valid scheme
         if( down() ) break;   // Bottom of file, so done!
         continue;
      }
      found_one=true;
      // Move off the section line
      if( down() ) break;
      sl=p_line;
      // Now find the next section so we can bracket this section
      if( _ini_find_section('') ) {
         bottom();
      } else {
         up();   // Move off the the next section name
      }
      el=p_line;

      // Get the options
      if( init_options ) {
         // Load default options for this scheme
         initOptions(s:[scheme_name].options);
      }
      p_line=sl;
      while( p_line<=el ) {
         get_line(line);
         line=strip(line,'L');
         if( line=="" || substr(line,1,1)==';' ) {
            // Blank line OR comment line
            if( down() ) break;  // Done!
            continue;
         }
         parse line with line ';' .;   // Get rid of a trailing comment (not sure if we need this)
         parse line with varname '=' val;
         if( val=="" ) {
            if( down() ) break;   // Done!
            continue;   // Not a valid value
         }
         if( isValidOption(varname,val) ) {
            s:[scheme_name].options:[varname]=val;
         }
         if( down() ) break;   // Done!
      }
   } while( name=="" );

   if( name=="" ) return  found_one?0:1 ;   // Done

   scheme_name=name;
   if( sync_lang_options ) {

      IndentPerLevel := LanguageSettings.getSyntaxIndent(lang);
      if( isValidOption("IndentPerLevel",IndentPerLevel) ) {
         s:[scheme_name].options:["IndentPerLevel"]=IndentPerLevel;
      }
      // If ReservedWordCase is set to OPT_WORDCASE_PRESERVE
      // then we do not want to sync the options because the user would
      // never be able to keep the setting.
      ReservedWordCase := LanguageSettings.getKeywordCase(lang);
      if( isValidOption("ReservedWordCase",ReservedWordCase) ) {
         if( s:[scheme_name].options:["ReservedWordCase"]!=OPT_WORDCASE_PRESERVE ) {
            s:[scheme_name].options:["ReservedWordCase"]=ReservedWordCase;
         }
      }

      s:[scheme_name].options:["IndentWithTabs"] = LanguageSettings.getIndentWithTabs(lang);
   }

   // Make sure all values are legal
   enforceValidOptions(s:[scheme_name].options);

   return  found_one?0:1 ;
}

static int saveScheme(adaScheme_t *s_p,_str section_name,boolean sync_lang_options)
{
   int status=0;

   parse section_name with auto lang '-scheme-' auto scheme_name;

   _str msg='';
   _str info='';
   if( sync_lang_options ) {
      LanguageSettings.setSyntaxIndent(lang, s_p->options:["IndentPerLevel"]);
      updateList := SYNTAX_INDENT_UPDATE_KEY'='s_p->options:["IndentPerLevel"]',';

      // If ReservedWordCase is set to OPT_WORDCASE_PRESERVE
      // then we do not want to sync the options because they would
      // make no sense to the Ada language setup analogs.
      if( s_p->options:["ReservedWordCase"]!=OPT_WORDCASE_PRESERVE ) {
         LanguageSettings.setKeywordCase(lang, s_p->options:["ReservedWordCase"]);
         updateList :+= KEYWORD_CASING_UPDATE_KEY'='s_p->options:["ReservedWordCase"]',';
      }

      LanguageSettings.setIndentWithTabs(lang, s_p->options:["IndentWithTabs"] != 0);
      updateList :+= INDENT_WITH_TABS_UPDATE_KEY'='s_p->options:["IndentWithTabs"]',';

      _update_buffers(lang, updateList);

   }

   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if( orig_view_id=='' ) {
      _message_box('Error creating temp view');
      return 1;
   }
   _delete_line();

   // Options
   typeless options:[];
   typeless optionName;
   options=s_p->options;
   for( optionName._makeempty();; ) {
      options._nextel(optionName);
      if( optionName._isempty() ) break;
      //say('saveScheme: insert_line('optionName:+'=':+options:[optionName]:+')');
      insert_line(optionName:+'=':+options:[optionName]);
   }
   // Sort
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      msg=get_message(mark);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return 1;
   }
   _select_line(mark);
   top();
   _select_line(mark);
   _sort_selection('i',mark);
   _delete_selection(mark);
   bottom();

   p_window_id=orig_view_id;

   // Whatever calls this function is responsible for calling
   // MaybeCreateFormatUserIniFile() first.

   // Do not need to use _delete_temp_view() because _ini_put_section() will get rid of it for us
   // Do not need to worry if the file does not exist, _ini_put_section() will create it
   status=_ini_put_section(FormatUserIniFilename(),section_name,temp_view_id);
   if( status ) {
      msg=nls('Unable to update file "%s".',FormatUserIniFilename()):+"  ":+get_message(status);
      _message_box(msg,"Error",MB_OK|MB_ICONEXCLAMATION);
      return status;
   }
   // call_list for _adaformatSaveScheme_
   call_list('_adaformatSaveScheme_',lang,scheme_name);

   return 0;
}

/**
 * Make sure a default Ada Beautifier scheme exists in "uformat.ini".
 */
int AdaFormatMaybeCreateDefaultScheme()
{
   adaScheme_t scheme;

   MaybeCreateFormatUserIniFile();

   // Sync with language options?
   typeless sync_lang_options='';
   int status=_ini_get_value(FormatUserIniFilename(),"common","sync_ext_options",sync_lang_options,"1");
   if( status ) sync_lang_options=true;

   initOptions(scheme.options);
   // Guarantee that these atleast get set to the same value as "IndentPerLevel"
   scheme.options:["TabSize"]= -1;
   scheme.options:["OrigTabSize"]= -1;
   // Get [[lang]-scheme-Default] section and put into scheme
   adaScheme_t temp:[];
   temp._makeempty();
   temp:[ADAF_DEFAULT_SCHEME_NAME]=scheme;
   int writedefaultoptions=getUserScheme(temp,ADAF_DEFAULT_SCHEME_NAME,'ada',sync_lang_options);
   scheme=temp:[ADAF_DEFAULT_SCHEME_NAME];
   //say('AdaFormatMaybeCreateDefaultScheme: writedefaultoptions='writedefaultoptions);
   if( writedefaultoptions ) {
      // If we are here, then (for some reason) there were no default options
      // in the user scheme file, so write the default options.
      status=saveScheme(&scheme,'ada':+'-scheme-':+ADAF_DEFAULT_SCHEME_NAME,sync_lang_options);
      if( status ) {
         _str msg='Failed to write default options to "':+FormatUserIniFilename():+'"';
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return 1;
      }
   }

   return 0;
}

static int format(adaScheme_t *pscheme,
                  _str lang,
                  _str orig_encoding,
                  _str infilename,
                  _str inview_id,
                  _str outfilename,
                  int  start_indent,
                  int  start_linenum)
{
   int vse_flags=0;
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
                       (int)inview_id,
                       outfilename,
                       start_indent,
                       start_linenum,
                       pscheme->options,
                       vse_flags);

   return 0;
}

static int myCheckTabs(int editorctl_wid, adaScheme_t *s_p, boolean quiet=false)
{
   // Check to see if the current buffer's tab settings differ from the (syntax_indent && indent_with_tabs)
   if( s_p->options:["IndentWithTabs"] && editorctl_wid ) {
      typeless t1=0, t2=0;
      if( editorctl_wid.p_tabs!="" ) {
         parse editorctl_wid.p_tabs with t1 t2 .;
      }
      int interval=t2-t1;
      if( interval!=s_p->options:["TabSize"] ) {
         int status = IDOK;
         if( !quiet ) {
            _str msg="Your current buffer's tab settings do not match your chosen tab size.\n\n":+
                "OK will change your current buffer's tab settings to match those you have chosen";
            status=_message_box(msg,
                                "",
                                MB_OKCANCEL);
         }
         if( status==IDOK ) {
            editorctl_wid.p_tabs='+':+s_p->options:["TabSize"];
         } else {
            return 1;
         }
      }
   }

   return 0;
}

int _OnUpdate_ada_beautify(CMDUI cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return MF_GRAYED;
   }

   _str lang=target_wid.p_LangId;
   return ( _LanguageInheritsFrom('ada',lang)?MF_ENABLED:MF_GRAYED );
}

/**
 * Return value=2 means there was an error beautifying and calling function should
 * get the error message with vsadaformat_iserror()
 * 
 * @param quiet  (optional). Set to true if you do not want to see status messages or be
 *               prompted for options (e.g. tab mismatch). More serious errors (e.g. failed to save
 *               default options, etc.) will still be displayed loudly.
 *               Defaults to false.
 */
_command int ada_format,ada_beautify(int in_wid=0,
                                     int start_indent=0,
                                     _str lang='', 
                                     adaScheme_t* pscheme=null,
                                     boolean quiet=false
                                    ) name_info(','VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if( start_indent<0 ) {
      start_indent=0;
   }

   adaScheme_t scheme;
   scheme._makeempty();
   if( pscheme ) {
      scheme= *(pscheme);
   }

   if( p_Nofhidden ) {
      show_all();
   }

   // Save in the case of doing the entire buffer so we can set it back when we "undo"
   boolean old_modify=p_modify;
   int old_left_edge=p_left_edge;
   int old_cursor_y=p_cursor_y;
   save_pos(auto p);

   _str infilename="";
   _str outfilename="";
   int editorctl_wid=p_window_id;
   if( !_isEditorCtl() ) {
      editorctl_wid=0;
   }

   _str msg='';
   _str orig_lang='';
   int status=0;
   typeless sync_lang_options='';

   // Do the current buffer
   if( scheme._isempty() ) {
      if( !_isEditorCtl() ) {
         msg="No buffer!";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return 1;
      }
      if( lang=="" ) {
         lang=p_LangId;
      }
      orig_lang=lang;
      if( BeautifyCheckSupport(lang) ) {
         if( !quiet ) {
            msg='Beautifying not supported for language "':+_LangId2Modename(lang):+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
         return 1;
      }
      lang=orig_lang;

      // Sync with language options?
      status=_ini_get_value(FormatUserIniFilename(),"common","sync_ext_options",sync_lang_options,"1");
      if( status ) sync_lang_options=true;

      initOptions(scheme.options);
      // Guarantee that these at least get set to the same value as "indentPerLevel"
      scheme.options:["TabSize"]= -1;
      scheme.options:["OrigTabSize"]= -1;
      // Get [[lang]-scheme-Default] section and put into scheme
      adaScheme_t temp:[];
      temp._makeempty();
      temp:[ADAF_DEFAULT_SCHEME_NAME]=scheme;
      int writedefaultoptions=getUserScheme(temp,ADAF_DEFAULT_SCHEME_NAME,lang,sync_lang_options);
      scheme=temp:[ADAF_DEFAULT_SCHEME_NAME];
      if( writedefaultoptions ) {
         // If we are here, then (for some reason) there were no default options
         // in the user scheme file, so write the default options.
         AdaFormatMaybeCreateDefaultScheme();
         status=saveScheme(&scheme,lang:+'-scheme-':+ADAF_DEFAULT_SCHEME_NAME,sync_lang_options);
         if( status ) {
            msg='Failed to write default options to "':+FormatUserIniFilename():+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return 1;
         }
         getUserScheme(temp,ADAF_DEFAULT_SCHEME_NAME,lang,sync_lang_options);
         scheme=temp:[ADAF_DEFAULT_SCHEME_NAME];
      }
   } else {
      if( lang=="" ) {
         msg="No source language!";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return 1;
      }
   }

   if( myCheckTabs(editorctl_wid,&scheme,quiet) ) {
      return 1;
   }

   boolean orig_utf8=p_UTF8;
   int orig_encoding=p_encoding;
   // This is the +fxxx flag that p_encoding is equivalent to.
   // This is very important when creating the temp view to output
   // to, and when saving the temp file for the beautifier to process.
   _str encoding_loadsave_flag=_EncodingToOption(orig_encoding);


   // Switch to temp view
   int orig_view_id=p_window_id;
   if( in_wid ) {
      p_window_id=in_wid;
   }

   // Make a temp file to use as the input source file
   infilename=mktemp();
   if( infilename=="" ) {
      msg="Error creating temp file";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return 1;
   }
   //_save_file(encoding_loadsave_flag' +o junk');
   status=_save_file(encoding_loadsave_flag' +o ':+maybe_quote_filename(infilename));   // This is the source file
   if( status ) {
      msg='Error creating temp file "':+infilename:+'".  ':+get_message(status);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return 1;
   }
   int start_linenum=p_line;
   bottom();
   boolean last_line_was_bare=(_line_length()==_line_length(1));

   // Create a temporary view for beautifier output *with* p_undo_steps=0
   _str arg2="+td";   // DOS \r\n linebreak
   if( length(p_newline)==1 ) {
      if( substr(p_newline,1,1)=='\r' ) {
         arg2="+tm";   // Macintosh \r linebreak
      } else {
         arg2="+tu";   // UNIX \n linebreak
      }
   }
   arg2=encoding_loadsave_flag' 'arg2;
   //say('arg2='arg2);
   int output_view_id=0;
   status=_create_temp_view(output_view_id,arg2);
   if( status=="" ) {
      msg="Error creating temp view";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return 1;
   }
   // _create_temp_view() _always_ sets p_UTF8=1, so must override
   p_UTF8=orig_utf8;
   _delete_line();

   mou_hour_glass(1);
   status=format(&scheme,
                 lang,
                 orig_encoding,
                 infilename,
                 0,   // Input view id
                 outfilename,
                 start_indent,
                 start_linenum);
   mou_hour_glass(0);

   // Cleanup temp files that were created
   delete_file(infilename);   // Delete the temp file
   if( !_line_length(true) ) {
      // Get rid of the zero-length line at the bottom
      _delete_line();
   }

   _str rest='';
   msg=vsadaformat_iserror();
   if( msg!="" ) {
      _delete_temp_view(output_view_id);
      if( in_wid ) {
         // Do this instead of orig_view_id so we can set the error line number correctly
         p_window_id=in_wid;
      } else {
         p_window_id=orig_view_id;
      }

      // Show the message and position at the error
      if( isinteger(msg) ) {
         // Got one of the *_RC constants in rc.sh
         msg=get_message((int)msg);
      } else {
         _str efilename='';
         typeless eline='';
         typeless ecol='';
         _str emsg='';
         parse msg with efilename'('eline','ecol'): 'emsg;
         if( isinteger(eline) ) {   // Just in case
            p_line=eline;
            if( isinteger(ecol) ) {
               p_col=ecol;
            }
         }
         // Reformat the message to remove the temp filename and replace with
         // the current buffer name (no path)
         parse msg with efilename '(' +0 rest;
         msg=_strip_filename(p_buf_name,'P'):+rest;
      }
      if( in_wid ) {
         // Do not show the error yet.  Let ada_beautify_selection() do that, otherwise
         // the linenumber it displays will be completely wrong.
         p_window_id=in_wid;
         return 2;
      } else {
         if( !quiet ) {
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
      }
      return 2;
   } else {
      // Everything is good, so clear the temp view and put the beautiful stuff in
      typeless mark=_alloc_selection();
      if( mark<0 ) {
         msg=get_message(mark);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         _delete_temp_view(output_view_id);
         p_window_id=orig_view_id;
         return 1;
      }
      if( in_wid ) {
         p_window_id=in_wid;
      } else {
         p_window_id=orig_view_id;
      }
      // _lbclear() does a _delete_selection(), so do not have to worry about a lot of undo steps
      _lbclear();
      p_window_id=output_view_id;
      //_save_file('+o out');
      top();
      _select_line(mark);
      bottom();
      _select_line(mark);
      if( in_wid ) {
         p_window_id=in_wid;
      } else {
         p_window_id=orig_view_id;
      }
      _copy_to_cursor(mark);
      _free_selection(mark);
      bottom();
      if( last_line_was_bare ) {
         // The last line of the file had no newline at the end, so fix it
         _end_line();
         _delete_text(-2);
      }
      int adjusted_linenum=vsadaformat_adjusted_linenum();
      p_line= (adjusted_linenum)?(adjusted_linenum):(1);   // Don't allow line 0
      _begin_line();
      _delete_temp_view(output_view_id);

      set_scroll_pos(old_left_edge,old_cursor_y);
   }

   return 0;
}

static int findBeginContext(int mark, int &sl, int &el, boolean quiet=false)
{
   int old_sl=sl;
   int old_el=el;
   _str msg='';

   _begin_select(mark);

   while( p_line>1 ) {
      // Goto to beginning of line so not fooled by start of comment
      _begin_line();
      if( _in_comment(1) ) {
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

static int findEndContext(int mark, int &sl, int &el, boolean quiet=false)
{
   int old_sl=sl;
   int old_el=el;
   _str msg='';

   _end_select(mark);
   // Goto end of line so not fooled by start of comment
   _end_line();

   while( p_line<p_Noflines ) {
      if( _in_comment(1) ) {
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
                             boolean &last_line_was_bare,
                             boolean quiet=false)
{
   last_line_was_bare=false;
   save_pos(auto p);
   int old_linenum=p_line;
   typeless orig_mark=_duplicate_selection("");
   context_mark=_duplicate_selection();
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      _free_selection(context_mark);
      return mark;
   }
   int start_col=0;
   int end_col=0;
   int dummy=0;
   int startmark_linenum=0;
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
   int sl=p_line;   // start line
   _end_select(context_mark);
   int el=p_line;   // end line
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
   int tl=p_line;   // Top line
   soc_linenum=sl;
   int diff=old_linenum-tl;
   _select_line(mark);
   _begin_select(context_mark);
   first_non_blank();
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
   last_line_was_bare= (_line_length()==_line_length(1));

   // Create a temporary view to hold the code selection and move it there
   _str arg2="+td";   // DOS \r\n linebreak
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
   p_line=p_line+diff+2;
   p_window_id=orig_view_id;

   return 0;
}

static void deleteContextSelection(int context_mark)
{
   // If we were on the last line, then beautified text will get inserted too
   // early in the buffer
   _end_select();
   int last_line_was_empty=0;
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

_command int ada_format_selection,ada_beautify_selection(_str lang='',
                                                         adaScheme_t *pscheme=null,
                                                         boolean quiet=false
             ) name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{

   if( !select_active() ) {
      return (ada_format(0,0,lang,pscheme,quiet));
   }

   adaScheme_t scheme;
   scheme._makeempty();
   if( pscheme ) {
      scheme= *(pscheme);
   }

   if( p_Nofhidden ) {
      show_all();
   }

   int editorctl_wid=p_window_id;
   if( !_isEditorCtl() ) {
      editorctl_wid=0;
   }

   // Do the current buffer
   _str msg='';
   _str orig_lang='';
   int status=0;
   typeless sync_lang_options='';
   if( scheme._isempty() ) {
      if( !_isEditorCtl() ) {
         msg="No buffer!";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return 1;
      }
      if( lang=="" ) {
         lang=p_LangId;
      }
      orig_lang=lang;
      if( BeautifyCheckSupport(lang) ) {
         if( !quiet ) {
            msg='Beautifying not supported for "':+_LangId2Modename(lang):+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
         return 1;
      }
      lang=orig_lang;

      // Sync with language options?
      status=_ini_get_value(FormatUserIniFilename(),"common","sync_ext_options",sync_lang_options,"1");
      if( status ) sync_lang_options=true;

      // Get [[lang]-scheme-Default] section and put into scheme
      initOptions(scheme.options);
      // Guarantee that these atleast get set to the same value as "indent_amount"
      scheme.options:["TabSize"]= -1;
      scheme.options:["OrigTabSize"]= -1;
      adaScheme_t temp:[];
      temp._makeempty();
      temp:[ADAF_DEFAULT_SCHEME_NAME]=scheme;
      int writedefaultoptions=getUserScheme(temp,ADAF_DEFAULT_SCHEME_NAME,lang,sync_lang_options);
      scheme=temp:[ADAF_DEFAULT_SCHEME_NAME];
      if( writedefaultoptions ) {
         // If we are here, then (for some reason) there were no default options
         // in the user scheme file, so write the default options
         status=saveScheme(&scheme,lang:+'-scheme-':+ADAF_DEFAULT_SCHEME_NAME,sync_lang_options);
         if( status ) {
            msg='Failed to write default options to "':+FormatUserIniFilename():+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return 1;
         }
      }
   } else {
      if( lang=="" ) {
         msg="No language specified!";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return 1;
      }
   }

   // Ada only has line comments, so fake this up
   _str mlc_startstr="--";
   _str mlc_endstr="";

   save_pos(auto p);
   int orig_view_id=p_window_id;
   int old_left_edge=p_left_edge;
   int old_cursor_y=p_cursor_y;

   _begin_select();
   int tom_linenum=p_line;
   restore_pos(p);

   // Find the context
   int temp_view_id=0;
   int context_mark=0;
   int soc_linenum=0;
   boolean last_line_was_bare=false; 
   if( createContextView(mlc_startstr,mlc_endstr,temp_view_id,context_mark,soc_linenum,last_line_was_bare,quiet) ) {
      if( !quiet ) {
         _message_box('Failed to derive context for selection');
      }
      return 1;
   }

   typeless old_mark=0, mark=0;
   int start_indent=0;
   int new_linenum=0;
   int error_linenum=0;

   // Do this before calling ada_format() so do not end up somewhere funky
   restore_pos(p);
   status=ada_format(temp_view_id,start_indent,lang,&scheme,quiet);
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
      new_linenum=new_linenum+soc_linenum-1;
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
         error_linenum=error_linenum+soc_linenum-1-2;
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


///////////////////////////////////////////////////////////////////////////////
// _ada_beautify_form
///////////////////////////////////////////////////////////////////////////////
static adaScheme_t gSchemes:[];
static adaScheme_t gUserSchemes:[];

static boolean gChangeScheme = true;
static adaScheme_t gOrigScheme;
static _str gOrigSchemeName = "";

static boolean gChangeBL = true;

static _str gLangId = "";

#define AF_INDENTTAB     (0)
#define AF_STATEMENTSTAB (1)
#define AF_HSPACINGTAB   (2)
#define AF_VALIGNTAB     (3)
#define AF_COMMENTSTAB   (4)
#define AF_SCHEMESTAB    (5)

defeventtab _ada_beautify_form;

static void enableChildren(int parent,boolean enable)
{
   int firstwid,wid;

   if( !parent ) return;

   firstwid=parent.p_child;
   if( !firstwid ) return;
   wid=firstwid;
   for(;;) {
      if( wid.p_enabled!=enable ) wid.p_enabled=enable;
      wid=wid.p_next;
      if( wid==firstwid ) break;
   }

   return;
}

/**
 * This function assumes that the control to admin enable/disable is
 * the active object.
 */
static void adminEnable(_str name="")
{
   if( name=="" ) {
      // Get it from the active object
      parse p_name with 'ctl_'name;
   }
   boolean enable = (0==gAdminOptions._indexin(name));
   switch( p_object ) {
   case OI_TEXT_BOX:
      // Disable the textbox
      p_enabled=enable;
      break;
   case OI_CHECK_BOX:
      p_enabled=enable;
      break;
   case OI_RADIO_BUTTON:
      if( p_parent.p_object==OI_FRAME || p_parent.p_object==OI_PICTURE_BOX ) {
         enableChildren(p_parent,enable);
      } else {
         // No frame around radio buttons, so find adjacent siblings
         // and enable/disable them.
         //
         // Forward siblings
         int wid = p_window_id;
         do {
            wid.p_enabled=enable;
            wid=wid.p_next;
         } while( wid!=p_window_id && wid.p_object==OI_RADIO_BUTTON );
         // Previous siblings
         wid = p_window_id.p_prev;
         while( wid!=p_window_id && wid.p_object==OI_RADIO_BUTTON ) {
            wid.p_enabled=enable;
            wid=wid.p_prev;
         }
      }
      break;
   default:
      // Should never get here
      _str msg="adaformat: Unrecognized control type for '"p_name"'";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
}

static void oncreateIndent(adaScheme_t *s_p)
{
   typeless IndentPerLevel=s_p->options:["IndentPerLevel"];
   if( !isValidOption("IndentPerLevel",IndentPerLevel) ) {
      IndentPerLevel=gAdaOptionTab:["IndentPerLevel"].default_val;
   }
   typeless TabSize=s_p->options:["TabSize"];
   if( !isValidOption("TabSize",TabSize) ) {
      TabSize=IndentPerLevel;
   }
   typeless OrigTabSize=s_p->options:["OrigTabSize"];
   if( !isValidOption("OrigTabSize",OrigTabSize) ) {
      OrigTabSize=IndentPerLevel;
   }
   typeless IndentWithTabs= (s_p->options:["IndentWithTabs"]!=0);
   typeless MaxLineLength= (s_p->options:["MaxLineLength"]);
   if( !isValidOption("MaxLineLength",MaxLineLength) ) {
      MaxLineLength=gAdaOptionTab:["MaxLineLength"].default_val;
   }
   typeless ContinuationIndent=s_p->options:["ContinuationIndent"];
   if( !isValidOption("ContinuationIndent",ContinuationIndent) ) {
      ContinuationIndent=IndentPerLevel;
   }
   typeless OperatorBias=s_p->options:["OperatorBias"];
   if( !isValidOption("OperatorBias",OperatorBias) ) {
      OperatorBias=gAdaOptionTab:["OperatorBias"].default_val;
   }

   // Now set the controls
   ctl_IndentPerLevel.p_text=IndentPerLevel;
   ctl_IndentPerLevel.adminEnable();

   ctl_TabSize.p_text=TabSize;
   ctl_TabSize.adminEnable();

   ctl_OrigTabSize.p_text=OrigTabSize;
   ctl_OrigTabSize.adminEnable();

   ctl_IndentWithTabs.p_value=IndentWithTabs;
   ctl_IndentWithTabs.adminEnable();

   ctl_MaxLineLength.p_text=MaxLineLength;
   ctl_MaxLineLength.adminEnable();

   ctl_ContinuationIndent.p_text=ContinuationIndent;
   ctl_ContinuationIndent.adminEnable();

   ctl_OperatorBias_SameLine.p_value=0;
   ctl_OperatorBias_NextLine.p_value=0;
   switch( OperatorBias ) {
   case OPT_OPBIAS_SAME_LINE:
      ctl_OperatorBias_SameLine.p_value=1;
      break;
   case OPT_OPBIAS_NEXT_LINE:
      ctl_OperatorBias_NextLine.p_value=1;
      break;
   }
   ctl_OperatorBias_SameLine.adminEnable("OperatorBias");
   // Remember these so clicking on a radio button that is already checked
   // does not modify a scheme.
   ctl_OperatorBias_SameLine.p_user=ctl_OperatorBias_SameLine.p_value;
   ctl_OperatorBias_NextLine.p_user=ctl_OperatorBias_NextLine.p_value;
}

static void oncreateStatements(adaScheme_t *s_p)
{
   typeless ReservedWordCase=s_p->options:["ReservedWordCase"];
   if( !isValidOption("ReservedWordCase",ReservedWordCase) ) {
      ReservedWordCase=gAdaOptionTab:["ReservedWordCase"].default_val;
   }
   typeless OneStatementPerLine=s_p->options:["OneStatementPerLine"];
   if( !isValidOption("OneStatementPerLine",OneStatementPerLine) ) {
      OneStatementPerLine=gAdaOptionTab:["OneStatementPerLine"].default_val;
   }
   typeless OneDeclPerLine=s_p->options:["OneDeclPerLine"];
   if( !isValidOption("OneDeclPerLine",OneDeclPerLine) ) {
      OneDeclPerLine=gAdaOptionTab:["OneDeclPerLine"].default_val;
   }
   typeless OneParameterPerLine=s_p->options:["OneParameterPerLine"];
   if( !isValidOption("OneParameterPerLine",OneParameterPerLine) ) {
      OneParameterPerLine=gAdaOptionTab:["OneParameterPerLine"].default_val;
   }
   typeless OneEnumPerLine=s_p->options:["OneEnumPerLine"];
   if( !isValidOption("OneEnumPerLine",OneEnumPerLine) ) {
      OneEnumPerLine=gAdaOptionTab:["OneEnumPerLine"].default_val;
   }

   // Now set the controls
   ctl_ReservedWordCase_upper.p_value=ctl_ReservedWordCase_lower.p_value=0;
   ctl_ReservedWordCase_capitalize.p_value=ctl_ReservedWordCase_preserve.p_value=0;
   switch( ReservedWordCase ) {
   case OPT_WORDCASE_UPPER:
      ctl_ReservedWordCase_upper.p_value=1;
      break;
   case OPT_WORDCASE_LOWER:
      ctl_ReservedWordCase_lower.p_value=1;
      break;
   case OPT_WORDCASE_CAPITALIZE:
      ctl_ReservedWordCase_capitalize.p_value=1;
      break;
   case OPT_WORDCASE_PRESERVE:
      ctl_ReservedWordCase_preserve.p_value=1;
      break;
   }
   ctl_ReservedWordCase_upper.adminEnable("ReservedWordCase");

   ctl_OneStatementPerLine.p_value = OneStatementPerLine;
   ctl_OneStatementPerLine.adminEnable();

   ctl_OneDeclPerLine.p_value = OneDeclPerLine;
   ctl_OneDeclPerLine.adminEnable();

   ctl_OneParameterPerLine.p_value = OneParameterPerLine;
   ctl_OneParameterPerLine.adminEnable();

   ctl_OneEnumPerLine.p_value = OneEnumPerLine;
   ctl_OneEnumPerLine.adminEnable();
}

static void oncreateHorizontalSpacing(adaScheme_t *s_p)
{
   typeless PadBeforeBinaryOps=s_p->options:["PadBeforeBinaryOps"];
   if( !isValidOption("PadBeforeBinaryOps",PadBeforeBinaryOps) ) {
      PadBeforeBinaryOps=gAdaOptionTab:["PadBeforeBinaryOps"].default_val;
   }
   typeless PadAfterBinaryOps=s_p->options:["PadAfterBinaryOps"];
   if( !isValidOption("PadAfterBinaryOps",PadAfterBinaryOps) ) {
      PadAfterBinaryOps=gAdaOptionTab:["PadAfterBinaryOps"].default_val;
   }
   typeless PadBinaryOps_preserve = (PadBeforeBinaryOps==OPT_PAD_PRESERVE || PadAfterBinaryOps==OPT_PAD_PRESERVE);

   typeless PadBeforeSemicolon=s_p->options:["PadBeforeSemicolon"];
   if( !isValidOption("PadBeforeSemicolon",PadBeforeSemicolon) ) {
      PadBeforeSemicolon=gAdaOptionTab:["PadBeforeSemicolon"].default_val;
   }
   typeless PadAfterSemicolon=s_p->options:["PadAfterSemicolon"];
   if( !isValidOption("PadAfterSemicolon",PadAfterSemicolon) ) {
      PadAfterSemicolon=gAdaOptionTab:["PadAfterSemicolon"].default_val;
   }
   typeless PadSemicolon_preserve = (PadBeforeSemicolon==OPT_PAD_PRESERVE || PadAfterSemicolon==OPT_PAD_PRESERVE);

   typeless PadBeforeComma=s_p->options:["PadBeforeComma"];
   if( !isValidOption("PadBeforeComma",PadBeforeComma) ) {
      PadBeforeComma=gAdaOptionTab:["PadBeforeComma"].default_val;
   }
   typeless PadAfterComma=s_p->options:["PadAfterComma"];
   if( !isValidOption("PadAfterComma",PadAfterComma) ) {
      PadAfterComma=gAdaOptionTab:["PadAfterComma"].default_val;
   }
   typeless PadComma_preserve = (PadBeforeComma==OPT_PAD_PRESERVE || PadAfterComma==OPT_PAD_PRESERVE);

   typeless PadBeforeLeftParen=s_p->options:["PadBeforeLeftParen"];
   if( !isValidOption("PadBeforeLeftParen",PadBeforeLeftParen) ) {
      PadBeforeLeftParen=gAdaOptionTab:["PadBeforeLeftParen"].default_val;
   }
   typeless PadAfterLeftParen=s_p->options:["PadAfterLeftParen"];
   if( !isValidOption("PadAfterLeftParen",PadAfterLeftParen) ) {
      PadAfterLeftParen=gAdaOptionTab:["PadAfterLeftParen"].default_val;
   }
   typeless PadLeftParen_preserve = (PadBeforeLeftParen==OPT_PAD_PRESERVE || PadAfterLeftParen==OPT_PAD_PRESERVE);

   typeless PadBeforeRightParen=s_p->options:["PadBeforeRightParen"];
   if( !isValidOption("PadBeforeRightParen",PadBeforeRightParen) ) {
      PadBeforeRightParen=gAdaOptionTab:["PadBeforeRightParen"].default_val;
   }
   typeless PadAfterRightParen=s_p->options:["PadAfterRightParen"];
   if( !isValidOption("PadAfterRightParen",PadAfterRightParen) ) {
      PadAfterRightParen=gAdaOptionTab:["PadAfterRightParen"].default_val;
   }
   typeless PadRightParen_preserve = (PadBeforeRightParen==OPT_PAD_PRESERVE || PadAfterRightParen==OPT_PAD_PRESERVE);

   // Now set the controls
   ctl_PadBeforeBinaryOps.p_value=PadBeforeBinaryOps;
   ctl_PadAfterBinaryOps.p_value=PadAfterBinaryOps;
   ctl_PadBinaryOps_preserve.p_value= (int)PadBinaryOps_preserve;
   ctl_PadBinaryOps_preserve.call_event(ctl_PadBinaryOps_preserve,LBUTTON_UP);
   ctl_PadBeforeBinaryOps.adminEnable();
   ctl_PadAfterBinaryOps.adminEnable();
   if( gAdminOptions._indexin("PadBeforeBinaryOps") || gAdminOptions._indexin("PadAfterBinaryOps") ) {
      ctl_PadBinaryOps_preserve.p_enabled=false;
   }

   ctl_PadBeforeSemicolon.p_value=PadBeforeSemicolon;
   ctl_PadAfterSemicolon.p_value=PadAfterSemicolon;
   ctl_PadSemicolon_preserve.p_value= (int)PadSemicolon_preserve;
   ctl_PadSemicolon_preserve.call_event(ctl_PadBinaryOps_preserve,LBUTTON_UP);
   ctl_PadBeforeSemicolon.adminEnable();
   ctl_PadAfterSemicolon.adminEnable();
   if( gAdminOptions._indexin("PadBeforeSemicolon") || gAdminOptions._indexin("PadAfterSemicolon") ) {
      ctl_PadSemicolon_preserve.p_enabled=false;
   }

   ctl_PadBeforeComma.p_value=PadBeforeComma;
   ctl_PadAfterComma.p_value=PadAfterComma;
   ctl_PadComma_preserve.p_value= (int)PadComma_preserve;
   ctl_PadComma_preserve.call_event(ctl_PadBinaryOps_preserve,LBUTTON_UP);
   ctl_PadBeforeComma.adminEnable();
   ctl_PadAfterComma.adminEnable();
   if( gAdminOptions._indexin("PadBeforeComma") || gAdminOptions._indexin("PadAfterComma") ) {
      ctl_PadComma_preserve.p_enabled=false;
   }

   ctl_PadBeforeLeftParen.p_value=PadBeforeLeftParen;
   ctl_PadAfterLeftParen.p_value=PadAfterLeftParen;
   ctl_PadLeftParen_preserve.p_value= (int)PadLeftParen_preserve;
   ctl_PadLeftParen_preserve.call_event(ctl_PadBinaryOps_preserve,LBUTTON_UP);
   ctl_PadBeforeLeftParen.adminEnable();
   ctl_PadAfterLeftParen.adminEnable();
   if( gAdminOptions._indexin("PadBeforeLeftParen") || gAdminOptions._indexin("PadAfterLeftParen") ) {
      ctl_PadLeftParen_preserve.p_enabled=false;
   }

   ctl_PadBeforeRightParen.p_value=PadBeforeRightParen;
   ctl_PadAfterRightParen.p_value=PadAfterRightParen;
   ctl_PadRightParen_preserve.p_value= (int)PadRightParen_preserve;
   ctl_PadRightParen_preserve.call_event(ctl_PadBinaryOps_preserve,LBUTTON_UP);
   ctl_PadBeforeRightParen.adminEnable();
   ctl_PadAfterRightParen.adminEnable();
   if( gAdminOptions._indexin("PadBeforeRightParen") || gAdminOptions._indexin("PadAfterRightParen") ) {
      ctl_PadRightParen_preserve.p_enabled=false;
   }
}

static void oncreateVerticalAlignment(adaScheme_t *s_p)
{
   typeless VAlignDeclColon=s_p->options:["VAlignDeclColon"];
   if( !isValidOption("VAlignDeclColon",VAlignDeclColon) ) {
      VAlignDeclColon=gAdaOptionTab:["VAlignDeclColon"].default_val;
   }
   typeless VAlignDeclInOut=s_p->options:["VAlignDeclInOut"];
   if( !isValidOption("VAlignDeclInOut",VAlignDeclInOut) ) {
      VAlignDeclInOut=gAdaOptionTab:["VAlignDeclInOut"].default_val;
   }
   typeless VAlignSelector=s_p->options:["VAlignSelector"];
   if( !isValidOption("VAlignSelector",VAlignSelector) ) {
      VAlignSelector=gAdaOptionTab:["VAlignSelector"].default_val;
   }
   typeless VAlignAssignment=s_p->options:["VAlignAssignment"];
   if( !isValidOption("VAlignAssignment",VAlignAssignment) ) {
      VAlignAssignment=gAdaOptionTab:["VAlignAssignment"].default_val;
   }
   typeless VAlignParens=s_p->options:["VAlignParens"];
   if( !isValidOption("VAlignParens",VAlignParens) ) {
      VAlignParens=gAdaOptionTab:["VAlignParens"].default_val;
   }
   typeless VAlignAdjacentComments=s_p->options:["VAlignAdjacentComments"];
   if( !isValidOption("VAlignAdjacentComments",VAlignAdjacentComments) ) {
      VAlignAdjacentComments=gAdaOptionTab:["VAlignAdjacentComments"].default_val;
   }

   // Now set the controls
   ctl_VAlignDeclColon.p_value = (int)VAlignDeclColon;
   ctl_VAlignDeclColon.adminEnable();

   ctl_VAlignDeclInOut.p_value = (int)VAlignDeclInOut;
   ctl_VAlignDeclInOut.adminEnable();

   ctl_VAlignSelector.p_value = (int)VAlignSelector;
   ctl_VAlignSelector.adminEnable();

   ctl_VAlignAssignment.p_value = (int)VAlignAssignment;
   ctl_VAlignAssignment.adminEnable();

   ctl_VAlignParens.p_value = (int)VAlignParens;
   ctl_VAlignParens.adminEnable();

   ctl_VAlignAdjacentComments.p_value = (int)VAlignAdjacentComments;
   ctl_VAlignAdjacentComments.adminEnable();
}

static _str blOption2Label(_str option)
{
   _str label = "";

   switch( option ) {
   case "BLSubprogramDecl":
      label = "Subprogram declaration";
      break;
   case "BLSubprogramBody":
      label = "Subprogram body";
      break;
   case "BLTypeDecl":
      label = "Type declaration";
      break;
   case "BLAspectClause":
      label = "for...use";
      break;
   case "BLSubunitHeader":
      label = "Subunit comment header";
      break;
   case "BLBegin":
      label = "begin/end";
      break;
   case "BLIf":
      label = "if/elsif/else";
      break;
   case "BLReturn":
      label = "return";
      break;
   case "BLLoop":
      label = "Loops";
      break;
   case "BLNestedParenListItem":
      label = "Nested paren list item";
      break;
   }

   return label;
}

static _str blLabel2Option(_str label)
{
   _str option = "";

   switch( label ) {
   case "Subprogram declaration":
      option = "BLSubprogramDecl";
      break;
   case "Subprogram body":
      option = "BLSubprogramBody";
      break;
   case "Type declaration":
      option = "BLTypeDecl";
      break;
   case "for...use":
      option = "BLAspectClause";
      break;
   case "Subunit comment header":
      option = "BLSubunitHeader";
      break;
   case "begin/end":
      option = "BLBegin";
      break;
   case "if/elsif/else":
      option = "BLIf";
      break;
   case "return":
      option = "BLReturn";
      break;
   case "Loops":
      option = "BLLoop";
      break;
   case "Nested paren list item":
      option = "BLNestedParenListItem";
      break;
   }

   return option;
}

#define BL_UNUSED_VALUE "x"
static _str blOption2TreeCaption(_str option, adaScheme_t *s_p)
{
   _str caption = "";
   _str label;

   label = blOption2Label(option);

   switch( option ) {
   case "BLSubprogramDecl":
      caption = label :+
                "\t" :+
                s_p->options:["BLBeforeSubprogramDecl"] :+
                "\t" :+
                s_p->options:["BLAfterSubprogramDecl"] :+
                "\t" :+
                s_p->options:["BLAdjacentSubprogramDecl"];
      break;
   case "BLSubprogramBody":
      caption = label :+
                "\t" :+
                s_p->options:["BLBeforeSubprogramBody"] :+
                "\t" :+
                s_p->options:["BLAfterSubprogramBody"] :+
                "\t" :+
                s_p->options:["BLAdjacentSubprogramBody"];
      break;
   case "BLTypeDecl":
      caption = label :+
                "\t" :+
                s_p->options:["BLBeforeTypeDecl"] :+
                "\t" :+
                s_p->options:["BLAfterTypeDecl"] :+
                "\t" :+
                s_p->options:["BLAdjacentTypeDecl"];
      break;
   case "BLAspectClause":
      caption = label :+
                "\t" :+
                s_p->options:["BLBeforeAspectClause"] :+
                "\t" :+
                s_p->options:["BLAfterAspectClause"] :+
                "\t" :+
                s_p->options:["BLAdjacentAspectClause"];
      break;
   case "BLSubunitHeader":
      caption = label :+
                "\t" :+
                s_p->options:["BLBeforeSubunitHeader"] :+
                "\t" :+
                s_p->options:["BLAfterSubunitHeader"] :+
                "\t" :+
                BL_UNUSED_VALUE;/* No adjacent setting */
      break;
   case "BLBegin":
      caption = label :+
                "\t" :+
                s_p->options:["BLBeforeBegin"] :+
                "\t" :+
                s_p->options:["BLAfterBegin"] :+
                "\t" :+
                BL_UNUSED_VALUE;/* No adjacent setting */
      break;
   case "BLIf":
      caption = label :+
                "\t" :+
                s_p->options:["BLBeforeIf"] :+
                "\t" :+
                s_p->options:["BLAfterIf"] :+
                "\t" :+
                BL_UNUSED_VALUE;/* No adjacent setting */
      break;
   case "BLReturn":
      caption = label :+
                "\t" :+
                s_p->options:["BLBeforeReturn"] :+
                "\t" :+
                s_p->options:["BLAfterReturn"] :+
                "\t" :+
                BL_UNUSED_VALUE;/* No adjacent setting */
      break;
   case "BLLoop":
      caption = label :+
                "\t" :+
                s_p->options:["BLBeforeLoop"] :+
                "\t" :+
                s_p->options:["BLAfterLoop"] :+
                "\t" :+
                BL_UNUSED_VALUE;/* No adjacent setting */
      break;
   case "BLNestedParenListItem":
      caption = label :+
                "\t" :+
                s_p->options:["BLBeforeNestedParenListItem"] :+
                "\t" :+
                s_p->options:["BLAfterNestedParenListItem"] :+
                "\t" :+
                BL_UNUSED_VALUE;/* No adjacent setting */
      break;
   }
   if( caption=="" ) {
      // Should never get here
      _str msg = 'Unknown blank line option "'option'"';
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }

   return caption;
}

static void oncreateBlankLines(adaScheme_t *s_p)
{
   gChangeBL=false;

   ctl_BLTree._TreeDelete(TREE_ROOT_INDEX,'C');

   // Create the grid
   int wid=p_window_id;
   p_window_id=ctl_BLTree;
   _TreeSetColButtonInfo(0,2500,0,-1,"Item");
   _TreeSetColButtonInfo(1,1500,0,-1,"Before");
   _TreeSetColButtonInfo(2,1500,0,-1,"After");
   _TreeSetColButtonInfo(3,1500,0,-1,"Between");
   _TreeSetColEditStyle(0,TREE_EDIT_TEXTBOX);
   _TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   _TreeSetColEditStyle(2,TREE_EDIT_TEXTBOX);
   _TreeSetColEditStyle(3,TREE_EDIT_TEXTBOX);
   p_window_id=wid;


   // Insert items into grid
   _str caption;
   caption=blOption2TreeCaption("BLSubprogramDecl",s_p);
   ctl_BLTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF,TREENODE_BOLD);
   caption=blOption2TreeCaption("BLSubprogramBody",s_p);
   ctl_BLTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF,TREENODE_BOLD);
   caption=blOption2TreeCaption("BLTypeDecl",s_p);
   ctl_BLTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF,TREENODE_BOLD);
   caption=blOption2TreeCaption("BLAspectClause",s_p);
   ctl_BLTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF,TREENODE_BOLD);
   caption=blOption2TreeCaption("BLSubunitHeader",s_p);
   ctl_BLTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF,TREENODE_BOLD);
   caption=blOption2TreeCaption("BLBegin",s_p);
   ctl_BLTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF,TREENODE_BOLD);
   caption=blOption2TreeCaption("BLIf",s_p);
   ctl_BLTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF,TREENODE_BOLD);
   caption=blOption2TreeCaption("BLReturn",s_p);
   ctl_BLTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF,TREENODE_BOLD);
   caption=blOption2TreeCaption("BLLoop",s_p);
   ctl_BLTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF,TREENODE_BOLD);
   caption=blOption2TreeCaption("BLNestedParenListItem",s_p);
   ctl_BLTree._TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF,TREENODE_BOLD);

   gChangeBL=true;
}

static void oncreateComments(adaScheme_t *s_p)
{
   typeless CommentAfterTypeDeclIndent=s_p->options:["CommentAfterTypeDeclIndent"];
   if( !isValidOption("CommentAfterTypeDeclIndent",CommentAfterTypeDeclIndent) ) {
      CommentAfterTypeDeclIndent=gAdaOptionTab:["CommentAfterTypeDeclIndent"].default_val;
   }
   typeless TrailingComment=s_p->options:["TrailingComment"];
   if( !isValidOption("TrailingComment",TrailingComment) ) {
      TrailingComment=gAdaOptionTab:["TrailingComment"].default_val;
   }
   typeless TrailingCommentCol=s_p->options:["TrailingCommentCol"];
   if( !isValidOption("TrailingCommentCol",TrailingCommentCol) ) {
      TrailingCommentCol=gAdaOptionTab:["TrailingCommentCol"].default_val;
   }
   typeless TrailingCommentIndent=s_p->options:["TrailingCommentIndent"];
   if( !isValidOption("TrailingCommentIndent",TrailingCommentIndent) ) {
      TrailingCommentIndent=gAdaOptionTab:["TrailingCommentIndent"].default_val;
   }
   typeless NoTrailingTypeDeclComments=s_p->options:["NoTrailingTypeDeclComments"];
   if( !isValidOption("NoTrailingTypeDeclComments",NoTrailingTypeDeclComments) ) {
      NoTrailingTypeDeclComments=gAdaOptionTab:["NoTrailingTypeDeclComments"].default_val;
   }

   // Now set the controls
   ctl_CommentAfterTypeDeclIndent.p_text=CommentAfterTypeDeclIndent;
   ctl_CommentAfterTypeDeclIndent.adminEnable();

   ctl_TrailingCommentCol.p_text=TrailingCommentCol;
   ctl_TrailingCommentIndent.p_text=TrailingCommentIndent;

   ctl_TrailingCommentCol_enable.p_value=0;
   ctl_TrailingCommentIndent_enable.p_value=0;
   ctl_TrailingComment_OrigRelIndent.p_value=0;
   switch( TrailingComment ) {
   case OPT_TCOMMENT_COL:
      ctl_TrailingCommentCol_enable.p_value=1;
      break;
   case OPT_TCOMMENT_INDENT:
      ctl_TrailingCommentIndent_enable.p_value=1;
      break;
   case OPT_TCOMMENT_ORIGRELINDENT:
      ctl_TrailingComment_OrigRelIndent.p_value=1;
      break;
   }
   ctl_TrailingCommentCol_enable.call_event(ctl_TrailingCommentCol,LBUTTON_UP);
   ctl_TrailingCommentCol_enable.adminEnable("TrailingComment");
   // CommentCol and CommentIndent can be admin controlled while
   // still allowing the user to pick the individual setting for
   // a trailing comment.
   ctl_TrailingCommentCol.adminEnable();
   ctl_TrailingCommentIndent.adminEnable();

   ctl_NoTrailingTypeDeclComments.p_value = (int)NoTrailingTypeDeclComments;
   ctl_NoTrailingTypeDeclComments.adminEnable();

   // Remember these so clicking on a radio button that is already checked
   // does not modify a scheme.
   ctl_TrailingCommentCol_enable.p_user=ctl_TrailingCommentCol_enable.p_value;
   ctl_TrailingCommentIndent_enable.p_user=ctl_TrailingCommentIndent_enable.p_value;
   ctl_TrailingComment_OrigRelIndent.p_user=ctl_TrailingComment_OrigRelIndent.p_value;
}

static void oncreateAdvanced(adaScheme_t *s_p)
{
   typeless IfBreakOnLogicalOps=s_p->options:["IfBreakOnLogicalOps"];
   if( !isValidOption("IfBreakOnLogicalOps",IfBreakOnLogicalOps) ) {
      IfBreakOnLogicalOps=gAdaOptionTab:["IfBreakOnLogicalOps"].default_val;
   }
   typeless IfLogicalOpAddContinuationIndent=s_p->options:["IfLogicalOpAddContinuationIndent"];
   if( !isValidOption("IfLogicalOpAddContinuationIndent",IfLogicalOpAddContinuationIndent) ) {
      IfLogicalOpAddContinuationIndent=gAdaOptionTab:["IfLogicalOpAddContinuationIndent"].default_val;
   }
   typeless IfLogicalOpLogicalOpAddContinuationIndent=s_p->options:["IfLogicalOpLogicalOpAddContinuationIndent"];
   if( !isValidOption("IfLogicalOpLogicalOpAddContinuationIndent",IfLogicalOpLogicalOpAddContinuationIndent) ) {
      IfLogicalOpLogicalOpAddContinuationIndent=
         gAdaOptionTab:["IfLogicalOpLogicalOpAddContinuationIndent"].default_val;
   }

   // Now set the controls
   ctl_IfBreakOnLogicalOps.p_value = (int)IfBreakOnLogicalOps;
   ctl_IfBreakOnLogicalOps.adminEnable();

   ctl_IfLogicalOpAddContinuationIndent.p_text = IfLogicalOpAddContinuationIndent;
   ctl_IfLogicalOpAddContinuationIndent.adminEnable();

   ctl_IfLogicalOpLogicalOpAddContinuationIndent.p_text = IfLogicalOpLogicalOpAddContinuationIndent;
   ctl_IfLogicalOpLogicalOpAddContinuationIndent.adminEnable();
}

static void oncreateSchemes(adaScheme_t *s_p)
{
   // Schemes
   gOrigScheme._makeempty();
   gOrigSchemeName="";
   gSchemes._makeempty();
   gUserSchemes._makeempty();

   // Get the last scheme used
   _str last_scheme='';
   if( _ini_get_value(FormatUserIniFilename(),gLangId:+"-scheme-":+ADAF_DEFAULT_SCHEME_NAME,"last_scheme",last_scheme) ) {
      last_scheme=AF_NONE_SCHEME_NAME;
   }
   // Save this for the Reset button
   gOrigScheme= *s_p;
   gOrigSchemeName=last_scheme;

   typeless i;
   boolean old_change_scheme=gChangeScheme;
   gChangeScheme=false;
   if( !getScheme(gSchemes,"",gLangId,false) ) {
      for( i._makeempty();; ) {
         gSchemes._nextel(i);
         if( i._isempty() ) break;
         ctl_SchemesList._lbadd_item(i);
      }
   }
   if( !getUserScheme(gUserSchemes,"",gLangId,false) ) {
      for( i._makeempty();; ) {
         gUserSchemes._nextel(i);
         if( i._isempty() ) break;
         // We do not want to blast the default scheme because it is already set
         if( i!=ADAF_DEFAULT_SCHEME_NAME ) {
            ctl_SchemesList._lbadd_item(i);
         }
      }
   }
   ctl_SchemesList._lbsort();
   ctl_SchemesList.p_text=last_scheme;
   ctl_SchemesList.p_user=last_scheme;
   gChangeScheme=old_change_scheme;

   return;
}

// arg(1) is historically the extension used to find the beautifier
// form (e.g. CFML uses the HTML form, so arg(1)='html'.
// arg(2) is the canonical language ID of the file being beautified.
typeless ctl_Go.on_create(typeless ext='',
                          _str lang='',
                          typeless a3='',
                          _str caption='')
{
   adaScheme_t scheme;
   adaScheme_t s:[];

   if( caption!="" ) {
      p_active_form.p_caption=caption;
   }


   gChangeScheme=true;

   gOrigScheme._makeempty();
   gOrigSchemeName="";
   s._makeempty();

   int editorctl_wid=_form_parent();
   if ((editorctl_wid && !editorctl_wid._isEditorCtl()) ||
       (editorctl_wid._QReadOnly())) {
      editorctl_wid=0;
   }

   if( lang=="" ) {
      lang=_mdi.p_child.p_LangId;
   }
   if( lang=="" ) {
      _str msg="No buffer, read only buffer or unrecognized language.  Cannot continue.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_active_form._delete_window();
      return "";
   }
   gLangId = lang;
   if( !editorctl_wid ) ctl_Go.p_enabled=false;

   // Sync with language options?
   typeless sync_lang_options;
   int status=_ini_get_value(FormatUserIniFilename(),"common","sync_ext_options",sync_lang_options,true);
   if( status ) sync_lang_options=true;
   ctl_SyncExtensionOptions.p_value=sync_lang_options;

   scheme._makeempty();
   initOptions(scheme.options);
   // Guarantee that these atleast get set to the same value as "IndentPerLevel"
   scheme.options:["TabSize"]= -1;
   scheme.options:["OrigTabSize"]= -1;
   s:[ADAF_DEFAULT_SCHEME_NAME]=scheme;
   getUserScheme(s,ADAF_DEFAULT_SCHEME_NAME,lang,sync_lang_options);
   scheme=s:[ADAF_DEFAULT_SCHEME_NAME];
#if 0
   say('ctl_Go.on_create: ***************************************');
   typeless i;
   for( i._makeempty();; ) {
      scheme.options._nextel(i);
      if( i._isempty() ) break;
      say('ctl_Go.on_create: scheme.options:['i']='scheme.options:[i]);
   }
#endif

   // Admin options (if any) override default options
   getAdminOptions(gAdminOptions,gLangId);
   mergeAdminOptions(scheme.options,gLangId);
   if( !gAdminOptions._isempty() ) {
      // We have admin controlled settings, so make the notice visible
      ctl_admin_image.p_visible=true;
      ctl_admin_caption.p_visible=true;
   }

   // Set the help by language
   if( _LanguageInheritsFrom('ada',lang) ) {
      ctl_Help.p_help="Ada Beautifier dialog box";
   }

   gChangeScheme=false;
   oncreateIndent(&scheme);
   oncreateStatements(&scheme);
   oncreateHorizontalSpacing(&scheme);
   oncreateVerticalAlignment(&scheme);
   oncreateBlankLines(&scheme);
   oncreateComments(&scheme);
   oncreateAdvanced(&scheme);
   oncreateSchemes(&scheme);
   gChangeScheme=true;

   // Remember the active tab
   ctl_sstab._retrieve_value();
   //ctl_sstab.p_ActiveTab=INDENTTAB;

   // Selection
   if( _mdi.p_child.select_active() ) {
      ctl_SelectionOnly.p_enabled=true;
      ctl_SelectionOnly.p_value=1;
   } else {
      ctl_SelectionOnly.p_enabled=false;
   }

   return 0;
}

void ctl_Go.lbutton_up()
{
   // Save the user default and dialog settings
   int status=ctl_Save.call_event(ctl_Save,LBUTTON_UP);
   if( status ) {
      return;
   }

   // Check to see if the current buffer's tab settings matches the tab size chosen
   if( myCheckTabs(_form_parent(),&gUserSchemes:[ADAF_DEFAULT_SCHEME_NAME]) ) {
      return;
   }

   boolean selection= (ctl_SelectionOnly.p_enabled && ctl_SelectionOnly.p_value!=0);

   int editorctl_wid=_form_parent();
   p_active_form._delete_window();
   p_window_id=editorctl_wid;

   // save bookmark, breakpoint, and annotation information
   editorctl_wid._SaveBookmarksInFile(auto bmSaves);
   editorctl_wid._SaveBreakpointsInFile(auto bpSaves);
   editorctl_wid._SaveAnnotationsInFile(auto annoSaves);

   if( selection ) {
      ada_beautify_selection(gLangId,&gUserSchemes:[ADAF_DEFAULT_SCHEME_NAME]);
   } else {
      ada_beautify(0,0,gLangId,&gUserSchemes:[ADAF_DEFAULT_SCHEME_NAME]);
   }

   // restore bookmarks, breakpoints, and annotation locations
   editorctl_wid._RestoreBookmarksInFile(bmSaves);
   editorctl_wid._RestoreBreakpointsInFile(bpSaves);
   editorctl_wid._RestoreAnnotationsInFile(annoSaves);
   return;
}

void ctl_Go.on_destroy()
{
   // Remember the active tab
   ctl_sstab._append_retrieve(ctl_sstab,ctl_sstab.p_ActiveTab);

   // Cleanup
   gSchemes._makeempty();
   gUserSchemes._makeempty();
   gAdminOptions._makeempty();

   return;
}

void ctl_Cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

int ctl_Save.lbutton_up()
{
   adaScheme_t scheme;

   boolean sync_lang_options= (ctl_SyncExtensionOptions.p_value!=0);

   MaybeCreateFormatUserIniFile();

   // Save the settings to [<gLangId>-scheme-Default] section of user schemes
   scheme._makeempty();
   _str scheme_name='';
   if( onokScheme(&scheme,scheme_name) || saveScheme(&scheme,gLangId:+'-scheme-':+ADAF_DEFAULT_SCHEME_NAME,sync_lang_options) ) {
      return 1;
   }
   gUserSchemes:[ADAF_DEFAULT_SCHEME_NAME]=scheme;

   // Save the last scheme name used
   _ini_set_value(FormatUserIniFilename(),gLangId:+'-scheme-':+ADAF_DEFAULT_SCHEME_NAME,'last_scheme',scheme_name);

   // Now write common options.  We do this after the call to saveScheme()
   // because saveScheme() gaurantees that the file will exist.
   _ini_set_value(FormatUserIniFilename(),"common","sync_ext_options",sync_lang_options);

   // Configuration was saved, so change the "Cancel" caption to "Close"
   ctl_Cancel.p_caption='Cl&ose';

   return 0;
}

void ctl_Reset.lbutton_up()
{
   // Remember the current tab
   int old_tabinfo=ctl_sstab.p_ActiveTab;

   gChangeScheme=false;
   ctl_SchemesList.p_text=gOrigSchemeName;
   // Set this so ctl_SchemesList.on_change does not try to save old scheme
   ctl_SchemesList.p_user="";
   oncreateIndent(&gOrigScheme);
   oncreateStatements(&gOrigScheme);
   oncreateHorizontalSpacing(&gOrigScheme);
   oncreateVerticalAlignment(&gOrigScheme);
   oncreateBlankLines(&gOrigScheme);
   oncreateComments(&gOrigScheme);
   gChangeScheme=true;

   // Restore the current tab
   typeless activetab='', rest='';
   parse old_tabinfo with activetab rest;
   ctl_sstab.p_ActiveTab=activetab;

   return;
}

static int onokIndent(adaScheme_t *s_p)
{
   _str msg='';
   typeless IndentPerLevel=ctl_IndentPerLevel.p_text;
   if( !isinteger(IndentPerLevel) || IndentPerLevel<0 ) {
      msg="Invalid indent amount";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_IndentPerLevel;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   }
   typeless TabSize=ctl_TabSize.p_text;
   if( !isinteger(TabSize) || TabSize<0 ) {
      msg="Invalid tab size";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_TabSize;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   }
   typeless OrigTabSize=ctl_OrigTabSize.p_text;
   if( !isinteger(OrigTabSize) || OrigTabSize<0 ) {
      msg="Invalid original tab size";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_OrigTabSize;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   }
   typeless IndentWithTabs= (ctl_IndentWithTabs.p_value!=0);
   typeless MaxLineLength= (ctl_MaxLineLength.p_text);
   if( !isinteger(MaxLineLength) || MaxLineLength<0 ) {
      msg="Invalid maximum line length";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_MaxLineLength;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   }
   typeless ContinuationIndent=ctl_ContinuationIndent.p_text;
   if( !isinteger(ContinuationIndent) || ContinuationIndent<0 ) {
      msg="Invalid continuation indent";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_ContinuationIndent;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   }
   typeless OperatorBias=OPT_OPBIAS_SAME_LINE;
   if( ctl_OperatorBias_SameLine.p_value ) {
      OperatorBias=OPT_OPBIAS_SAME_LINE;
   } else if( ctl_OperatorBias_NextLine.p_value ) {
      OperatorBias=OPT_OPBIAS_NEXT_LINE;
   }

   s_p->options:["IndentPerLevel"]=IndentPerLevel;
   s_p->options:["TabSize"]=TabSize;
   s_p->options:["OrigTabSize"]=OrigTabSize;
   s_p->options:["IndentWithTabs"]=IndentWithTabs;
   s_p->options:["MaxLineLength"]=MaxLineLength;
   s_p->options:["ContinuationIndent"]=ContinuationIndent;
   s_p->options:["OperatorBias"]=OperatorBias;

   return 0;
}

static int onokStatements(adaScheme_t *s_p)
{
   int ReservedWordCase=0;
   if( ctl_ReservedWordCase_upper.p_value ) {
      ReservedWordCase=OPT_WORDCASE_UPPER;
   } else if( ctl_ReservedWordCase_lower.p_value ) {
      ReservedWordCase=OPT_WORDCASE_LOWER;
   } else if( ctl_ReservedWordCase_capitalize.p_value ) {
      ReservedWordCase=OPT_WORDCASE_CAPITALIZE;
   } else if( ctl_ReservedWordCase_preserve.p_value ) {
      ReservedWordCase=OPT_WORDCASE_PRESERVE;
   } else {
      _str msg="Must choose reserved word case";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_ReservedWordCase_upper;
      _set_focus();
      return 1;
   }
   typeless OneStatementPerLine = (0!=ctl_OneStatementPerLine.p_value);
   typeless OneDeclPerLine = (0!=ctl_OneDeclPerLine.p_value);
   typeless OneParameterPerLine = (0!=ctl_OneParameterPerLine.p_value);
   typeless OneEnumPerLine = (0!=ctl_OneEnumPerLine.p_value);

   s_p->options:["ReservedWordCase"] = ReservedWordCase;
   s_p->options:["OneStatementPerLine"] = OneStatementPerLine;
   s_p->options:["OneDeclPerLine"] = OneDeclPerLine;
   s_p->options:["OneParameterPerLine"] = OneParameterPerLine;
   s_p->options:["OneEnumPerLine"] = OneEnumPerLine;

   return 0;
}

static int onokHorizontalSpacing(adaScheme_t *s_p)
{
   int PadBeforeBinaryOps = OPT_PAD_PRESERVE;
   int PadAfterBinaryOps  = OPT_PAD_PRESERVE;
   if( !ctl_PadBinaryOps_preserve.p_value ) {
      PadBeforeBinaryOps = ctl_PadBeforeBinaryOps.p_value?OPT_PAD_ON:OPT_PAD_OFF;
      PadAfterBinaryOps = ctl_PadAfterBinaryOps.p_value?OPT_PAD_ON:OPT_PAD_OFF;
   }

   int PadBeforeSemicolon = OPT_PAD_PRESERVE;
   int PadAfterSemicolon  = OPT_PAD_PRESERVE;
   if( !ctl_PadSemicolon_preserve.p_value ) {
      PadBeforeSemicolon = ctl_PadBeforeSemicolon.p_value?OPT_PAD_ON:OPT_PAD_OFF;
      PadAfterSemicolon = ctl_PadAfterSemicolon.p_value?OPT_PAD_ON:OPT_PAD_OFF;
   }

   int PadBeforeComma = OPT_PAD_PRESERVE;
   int PadAfterComma  = OPT_PAD_PRESERVE;
   if( !ctl_PadComma_preserve.p_value ) {
      PadBeforeComma = ctl_PadBeforeComma.p_value?OPT_PAD_ON:OPT_PAD_OFF;
      PadAfterComma = ctl_PadAfterComma.p_value?OPT_PAD_ON:OPT_PAD_OFF;
   }

   int PadBeforeLeftParen = OPT_PAD_PRESERVE;
   int PadAfterLeftParen  = OPT_PAD_PRESERVE;
   if( !ctl_PadLeftParen_preserve.p_value ) {
      PadBeforeLeftParen = ctl_PadBeforeLeftParen.p_value?OPT_PAD_ON:OPT_PAD_OFF;
      PadAfterLeftParen = ctl_PadAfterLeftParen.p_value?OPT_PAD_ON:OPT_PAD_OFF;
   }

   int PadBeforeRightParen = OPT_PAD_PRESERVE;
   int PadAfterRightParen  = OPT_PAD_PRESERVE;
   if( !ctl_PadRightParen_preserve.p_value ) {
      PadBeforeRightParen = ctl_PadBeforeRightParen.p_value?OPT_PAD_ON:OPT_PAD_OFF;
      PadAfterRightParen = ctl_PadAfterRightParen.p_value?OPT_PAD_ON:OPT_PAD_OFF;
   }

   s_p->options:["PadBeforeBinaryOps"] = PadBeforeBinaryOps;
   s_p->options:["PadAfterBinaryOps"] = PadAfterBinaryOps;

   s_p->options:["PadBeforeSemicolon"] = PadBeforeSemicolon;
   s_p->options:["PadAfterSemicolon"] = PadAfterSemicolon;

   s_p->options:["PadBeforeComma"] = PadBeforeComma;
   s_p->options:["PadAfterComma"] = PadAfterComma;

   s_p->options:["PadBeforeLeftParen"] = PadBeforeLeftParen;
   s_p->options:["PadAfterLeftParen"] = PadAfterLeftParen;

   s_p->options:["PadBeforeRightParen"] = PadBeforeRightParen;
   s_p->options:["PadAfterRightParen"] = PadAfterRightParen;

   return 0;
}

static int onokVerticalAlignment(adaScheme_t *s_p)
{
   boolean VAlignDeclColon        = (0!=ctl_VAlignDeclColon.p_value);
   boolean VAlignDeclInOut        = (0!=ctl_VAlignDeclInOut.p_value);
   boolean VAlignSelector         = (0!=ctl_VAlignSelector.p_value);
   boolean VAlignAssignment       = (0!=ctl_VAlignAssignment.p_value);
   boolean VAlignParens           = (0!=ctl_VAlignParens.p_value);
   boolean VAlignAdjacentComments = (0!=ctl_VAlignAdjacentComments.p_value);

   s_p->options:["VAlignDeclColon"] = VAlignDeclColon;
   s_p->options:["VAlignDeclInOut"] = VAlignDeclInOut;
   s_p->options:["VAlignSelector"] = VAlignSelector;
   s_p->options:["VAlignAssignment"] = VAlignAssignment;
   s_p->options:["VAlignParens"] = VAlignParens;
   s_p->options:["VAlignAdjacentComments"] = VAlignAdjacentComments;

   return 0;
}

static int onokBlankLines(adaScheme_t *s_p)
{
   int index;

   index=ctl_BLTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while( index>=0 ) {
      _str caption;
      _str label;
      _str option;
      _str before, after, adjacent;
      caption=ctl_BLTree._TreeGetCaption(index);
      parse caption with label "\t" before "\t" after "\t" adjacent;
      option=blLabel2Option(label);
      if( !blIsValidOption(option,before,after,adjacent,s_p) ) {
         _str msg='Invalid blank line setting for "'label'"';
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         //_str new_caption = option"\t"before"\t"after"\t"adjacent;
         //_TreeSetCaption(index,new_caption);
         return -1;
      }
      index=ctl_BLTree._TreeGetNextSiblingIndex(index);
   }

   return 0;
}

static int onokComments(adaScheme_t *s_p)
{
   _str msg='';
   _str CommentAfterTypeDeclIndent=ctl_CommentAfterTypeDeclIndent.p_text;
   if( !isValidOption("CommentAfterTypeDeclIndent",CommentAfterTypeDeclIndent) ) {
      msg="Invalid indent value";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_CommentAfterTypeDeclIndent;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   }

   int TrailingComment= -1;
   typeless TrailingCommentCol=ctl_TrailingCommentCol.p_text;
   typeless TrailingCommentIndent=ctl_TrailingCommentIndent.p_text;
   if( ctl_TrailingCommentCol_enable.p_value ) {
      TrailingComment=OPT_TCOMMENT_COL;
      // Error check column value
      if( !isValidOption("TrailingCommentCol",TrailingCommentCol) ) {
         msg="Invalid trailing comment column";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctl_TrailingCommentCol;
         _set_sel(1,length(p_text)+1);
         _set_focus();
         return 1;
      }
   } else if( ctl_TrailingCommentIndent_enable.p_value ) {
      TrailingComment=OPT_TCOMMENT_INDENT;
      // Error check indent value
      if( !isValidOption("TrailingCommentIndent",TrailingCommentIndent) ) {
         msg="Invalid trailing comment indent";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctl_TrailingCommentIndent;
         _set_sel(1,length(p_text)+1);
         _set_focus();
         return 1;
      }
   } else if( ctl_TrailingComment_OrigRelIndent.p_value ) {
      TrailingComment=OPT_TCOMMENT_ORIGRELINDENT;
   } else {
      msg="Must choose trailing comment setting";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_TrailingCommentCol_enable;
      _set_focus();
      return 1;
   }
   // Error checking has already been performed for the chosen option.
   // We need to save these options, even when they were not selected,
   // so quietly error check them now.
   if( TrailingComment!=OPT_TCOMMENT_COL &&
       !isValidOption("TrailingCommentCol",TrailingCommentCol) ) {
      TrailingCommentCol=gAdaOptionTab:["TrailingCommentCol"].default_val;
   }
   if( TrailingComment!=OPT_TCOMMENT_INDENT &&
       !isValidOption("TrailingCommentIndent",TrailingCommentIndent) ) {
      TrailingCommentIndent=gAdaOptionTab:["TrailingCommentIndent"].default_val;
   }

   boolean NoTrailingTypeDeclComments = (0!=ctl_NoTrailingTypeDeclComments.p_value);

   s_p->options:["CommentAfterTypeDeclIndent"] = CommentAfterTypeDeclIndent;

   s_p->options:["TrailingComment"] = TrailingComment;
   s_p->options:["TrailingCommentCol"] = TrailingCommentCol;
   s_p->options:["TrailingCommentIndent"] = TrailingCommentIndent;

   s_p->options:["NoTrailingTypeDeclComments"] = NoTrailingTypeDeclComments;

   return 0;
}

static int onokAdvanced(adaScheme_t* s_p)
{
   _str msg='';
   typeless IfBreakOnLogicalOps = (0!=ctl_IfBreakOnLogicalOps.p_value);
   typeless IfLogicalOpAddContinuationIndent=ctl_IfLogicalOpAddContinuationIndent.p_text;
   if( !isValidOption("IfLogicalOpAddContinuationIndent",IfLogicalOpAddContinuationIndent) ) {
      msg="Invalid logical operator indent";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_IfLogicalOpAddContinuationIndent;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return 1;
   }
   typeless IfLogicalOpLogicalOpAddContinuationIndent=ctl_IfLogicalOpLogicalOpAddContinuationIndent.p_text;
   if( !isValidOption("IfLogicalOpLogicalOpAddContinuationIndent",IfLogicalOpLogicalOpAddContinuationIndent) ) {
      if( !isValidOption("IfLogicalOpLogicalOpAddContinuationIndent",IfLogicalOpLogicalOpAddContinuationIndent) ) {
         msg="Invalid logical operator indent";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctl_IfLogicalOpLogicalOpAddContinuationIndent;
         _set_sel(1,length(p_text)+1);
         _set_focus();
         return 1;
      }
   }

   s_p->options:["IfBreakOnLogicalOps"] = IfBreakOnLogicalOps;
   s_p->options:["IfLogicalOpAddContinuationIndent"] = IfLogicalOpAddContinuationIndent;
   s_p->options:["IfLogicalOpLogicalOpAddContinuationIndent"] = IfLogicalOpLogicalOpAddContinuationIndent;

   return 0;
}

static int onokScheme(adaScheme_t* s_p,_str &scheme_name)
{
   int status=onokIndent(s_p);
   if( status ) return status;
   status=onokStatements(s_p);
   if( status ) return status;
   status=onokHorizontalSpacing(s_p);
   if( status ) return status;
   status=onokVerticalAlignment(s_p);
   if( status ) return status;
   status=onokBlankLines(s_p);
   if( status ) return status;
   status=onokComments(s_p);
   if( status ) return status;
   status=onokAdvanced(s_p);
   if( status ) return status;
   scheme_name=ctl_SchemesList.p_text;

   return 0;
}

int ctl_SaveScheme.lbutton_up(_str doRename='')
{
   adaScheme_t scheme;

   _str old_name=ctl_SchemesList.p_text;
   if( old_name==AF_NONE_SCHEME_NAME ) {
      old_name="";
   } else if( pos("(Modified)",old_name,1,'i') ) {
      parse old_name with old_name '(Modified)';
   }

   boolean do_rename= (doRename != "");

   if( do_rename && !gUserSchemes._indexin(old_name) ) {
      _message_box(nls('Cannot find user scheme "%s".  System schemes cannot be renamed',old_name));
      return 1;
   }

   // Prompt user for name of scheme
   _str system_schemes=' "'ADAF_DEFAULT_SCHEME_NAME'" ';
   typeless i;
   for( i._makeempty();; ) {
      gSchemes._nextel(i);
      if( i._isempty() ) break;
      system_schemes=system_schemes:+' "'i'" ';
   }
   _str user_schemes='';
   for( i._makeempty();; ) {
      gUserSchemes._nextel(i);
      if( i._isempty() ) break;
      if( i==ADAF_DEFAULT_SCHEME_NAME ) continue;
      user_schemes=user_schemes:+' "'i'" ';
   }
   _str name=show("-modal _beautify_save_scheme_form",old_name,do_rename,system_schemes,user_schemes);
   if( name=="" ) {
      // User cancelled
      return 0;
   }

   MaybeCreateFormatUserIniFile();

   if( do_rename ) {
      // Delete the existing scheme
      gUserSchemes._deleteel(old_name);
      _ini_delete_section(FormatUserIniFilename(),gLangId:+'-scheme-':+old_name);
      ctl_SchemesList._lbfind_and_delete_item(old_name, 'i');
      ctl_SchemesList._lbtop();
   }

   // Save the user settings to [[lang]-scheme-<scheme name>] section of user schemes
   scheme._makeempty();
   typeless dummy;
   if( onokScheme(&scheme,dummy) || saveScheme(&scheme,gLangId:+'-scheme-'name,false) ) {
      _message_box('Failed to write scheme to "':+FormatUserIniFilename():+'"');
      return 1;
   }
   boolean old_gchange_scheme=gChangeScheme;
   gChangeScheme=false;
   // add it to the list
   ctl_SchemesList._lbadd_item_no_dupe(name, '', LBADD_SORT, true);
   // Set this so ctl_SchemesList.on_change does not try to save old scheme
   ctl_SchemesList.p_user="";
   gChangeScheme=old_gchange_scheme;
   gUserSchemes:[name]=scheme;

   return 0;
}

void ctl_DeleteScheme.lbutton_up()
{
   _str msg='';
   _str old_name=ctl_SchemesList.p_text;
   if( old_name==AF_NONE_SCHEME_NAME ) {
      msg="Cannot remote empty scheme";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   } else if( !gUserSchemes._indexin(old_name) ) {
      msg=nls('Cannot find user scheme "%s".  System schemes cannot be removed',old_name);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   MaybeCreateFormatUserIniFile();

   // Delete the existing scheme
   gUserSchemes._deleteel(old_name);
   _ini_delete_section(FormatUserIniFilename(),gLangId:+'-scheme-':+old_name);
   gChangeScheme=false;
   ctl_SchemesList._lbfind_and_delete_item(old_name, 'i');
   ctl_SchemesList._lbtop();
   ctl_SchemesList.p_text=AF_NONE_SCHEME_NAME;
   // Set this so ctl_SchemesList.on_change doesn't try to save old scheme
   ctl_SchemesList.p_user="";
   gChangeScheme=true;

   return;
}

void ctl_RenameScheme.lbutton_up()
{
   call_event(1,ctl_SaveScheme,LBUTTON_UP,'W');

   return;
}

void ctl_SchemesList.on_change(int reason)
{
   adaScheme_t *scheme_p;
   if( !gChangeScheme ) return;

   // Yes, changing things in an on_change() can cause more on_change events
   gChangeScheme=false;

   _str name='';
   _str old_name='';
   _str msg='';

   // Use this loop for easy error handling (like a goto)
   for(;;) {
      name=p_text;
      //old_name=gOrigSchemeName;
      old_name=p_user;
      // IF name has not changed OR no scheme chosen
      if( name==old_name || name==AF_NONE_SCHEME_NAME ) {
         break;
      }
      if( !gSchemes._indexin(name) && !gUserSchemes._indexin(name) ) {
         msg='The scheme "':+name:+'" is empty';
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_text=old_name;
         break;
      } else {
         if( pos("(Modified)",old_name,1,'i') ) {
            msg="You have a modified scheme.\n":+
                "Do you wish to save it?";
            typeless status=_message_box(msg,"",MB_YESNOCANCEL|MB_ICONQUESTION);
            if( status==IDCANCEL ) {
               p_text=old_name;
               break;
            } else if( status==IDYES ) {
               // Put the old name in so we know which scheme to save
               p_text=old_name;
               status=call_event(ctl_SaveScheme,LBUTTON_UP);
               if( status ) {
                  // There was a problem, so do not put the new name back in its place
                  break;
               }
               ctl_SchemesList.p_text=name;   // Put it back
            }

         }

         scheme_p=gSchemes._indexin(name);
         if( !scheme_p ) {
            scheme_p=gUserSchemes._indexin(name);
         }

         // Admin options (if any) override default options
         mergeAdminOptions(scheme_p->options,gLangId);

         oncreateIndent(scheme_p);
         oncreateStatements(scheme_p);
         oncreateHorizontalSpacing(scheme_p);
         oncreateVerticalAlignment(scheme_p);
         oncreateBlankLines(scheme_p);
         oncreateComments(scheme_p);
      }
      break;
   }
   p_user=name;
   gChangeScheme=true;

   return;
}

static void modifyScheme()
{
   if( !gChangeScheme ) return;

   gChangeScheme=false;
   _str name=ctl_SchemesList.p_text;
   if( !pos("(Modified)",name,1,'i') && name!=AF_NONE_SCHEME_NAME ) {
      name=strip(name,'B'):+' (Modified)';
      ctl_SchemesList.p_text=name;
      ctl_SchemesList.p_user=name;
   }
   gChangeScheme=true;
}

void ctl_IndentPerLevel.on_change()
{
   modifyScheme();
}
void ctl_IndentWithTabs.lbutton_up()
{
   modifyScheme();
}
void ctl_OperatorBias_SameLine.lbutton_up()
{
   // Did the user just click on something that was already checked?
   if( p_value!=p_user ) {
      modifyScheme();
      // Remember these so clicking on a radio button that is already checked
      // does not modify a scheme.
      ctl_OperatorBias_SameLine.p_user=ctl_OperatorBias_SameLine.p_value;
      ctl_OperatorBias_NextLine.p_user=ctl_OperatorBias_NextLine.p_value;
   }
}

void ctl_ReservedWordCase_upper.lbutton_up()
{
   modifyScheme();
}
void ctl_OneStatementPerLine.lbutton_up()
{
   modifyScheme();
}

// Used by all the Pad checkboxes
void ctl_PadBinaryOps_preserve.lbutton_up()
{
   int before_wid = p_prev.p_prev;
   int after_wid = p_prev;

   if( p_value ) {
      // Preserve
      before_wid.p_value=0;
      after_wid.p_value=0;
   }
   before_wid.p_enabled = (p_value==0);
   after_wid.p_enabled = (p_value==0);
}

void ctl_VAlignDeclColon.lbutton_up()
{
   modifyScheme();
}

static boolean blIsValidOption(_str option,
                               typeless& before, typeless& after, typeless& adjacent,
                               adaScheme_t* s_p=null)
{
   _str beforeOptionName, afterOptionName, adjacentOptionName;

   beforeOptionName=afterOptionName=adjacentOptionName="";
   switch( option ) {
   case "BLSubprogramDecl":
      beforeOptionName="BLBeforeSubprogramDecl";
      afterOptionName="BLAfterSubprogramDecl";
      adjacentOptionName="BLAdjacentSubprogramDecl";
      break;
   case "BLSubprogramBody":
      beforeOptionName="BLBeforeSubprogramBody";
      afterOptionName="BLAfterSubprogramBody";
      adjacentOptionName="BLAdjacentSubprogramBody";
      break;
   case "BLTypeDecl":
      beforeOptionName="BLBeforeTypeDecl";
      afterOptionName="BLAfterTypeDecl";
      adjacentOptionName="BLAdjacentTypeDecl";
      break;
   case "BLAspectClause":
      beforeOptionName="BLBeforeAspectClause";
      afterOptionName="BLAfterAspectClause";
      adjacentOptionName="BLAdjacentAspectClause";
      break;
   case "BLSubunitHeader":
      beforeOptionName="BLBeforeSubunitHeader";
      afterOptionName="BLAfterSubunitHeader";
      adjacentOptionName="BLAdjacentSubunitHeader";
      break;
   case "BLBegin":
      beforeOptionName="BLBeforeBegin";
      afterOptionName="BLAfterBegin";
      adjacentOptionName="BLAdjacentBegin";
      break;
   case "BLIf":
      beforeOptionName="BLBeforeIf";
      afterOptionName="BLAfterIf";
      adjacentOptionName="BLAdjacentIf";
      break;
   case "BLReturn":
      beforeOptionName="BLBeforeReturn";
      afterOptionName="BLAfterReturn";
      adjacentOptionName="BLAdjacentReturn";
      break;
   case "BLLoop":
      beforeOptionName="BLBeforeLoop";
      afterOptionName="BLAfterLoop";
      adjacentOptionName="BLAdjacentLoop";
      break;
   case "BLNestedParenListItem":
      beforeOptionName="BLBeforeNestedParenListItem";
      afterOptionName="BLAfterNestedParenListItem";
      adjacentOptionName="BLAdjacentNestedParenListItem";
      break;
   }
   boolean valid = true;
   if( !isValidOption(beforeOptionName,before) ) {
      before=gAdaOptionTab:[beforeOptionName].default_val;
      valid=false;
   }
   if( !isValidOption(afterOptionName,after) ) {
      after=gAdaOptionTab:[afterOptionName].default_val;
      valid=false;
   }
   if( !isValidOption(adjacentOptionName,adjacent) ) {
      adjacent=gAdaOptionTab:[adjacentOptionName].default_val;
      valid=false;
   }
   // Force unused values to be set to unused
   switch( option ) {
   case "BLSubunitHeader":
   case "BLBegin":
   case "BLIf":
   case "BLReturn":
   case "BLLoop":
   case "BLNestedParenListItem":
      if( adjacent!=BL_UNUSED_VALUE ) {
         adjacent=BL_UNUSED_VALUE;
         valid=false;
      }
      // Clear adjacentOptionName so it cannot be set in the scheme passed in
      adjacentOptionName="";
      break;
   }

   if( valid && s_p ) {
      // Set the scheme options
      if( beforeOptionName!="" ) {
         s_p->options:[beforeOptionName]=before;
      }
      if( afterOptionName!="" ) {
         s_p->options:[afterOptionName]=after;
      }
      if( adjacentOptionName!="" ) {
         s_p->options:[adjacentOptionName]=adjacent;
      }
   }

   return valid;
}

int ctl_BLTree.on_change(int reason, int index, int col=0, _str value='')
{
   if( !gChangeBL ) return 0;

   _str before='';
   _str after='';
   _str adjacent='';
   _str suffix='';

   if( reason==CHANGE_EDIT_OPEN ) {
      _str caption = _TreeGetCaption(index);
      _str label;
      _str option;
      parse caption with label "\t" before "\t" after "\t" adjacent;
      option=blLabel2Option(label);
      if( col==3 ) {
         // Disallow edits for unused values
         switch( option ) {
         case "BLSubunitHeader":
         case "BLBegin":
         case "BLIf":
         case "BLReturn":
         case "BLLoop":
         case "BLNestedParenListItem":
            if( adjacent!=BL_UNUSED_VALUE ) {
               // Do not know how it got this way, but fix it
               _TreeSetCaption(index,option"\t"before"\t"after"\t"adjacent);
            }
            return -1;
         }
      }
      // Check for values that are admin controlled
      parse option with 'BL'suffix;
      switch( col ) {
      case 1:
         option='BLBefore'suffix;
         break;
      case 2:
         option='BLAfter'suffix;
         break;
      case 3:
         option='BLAdjacent'suffix;
         break;
      }
      if( gAdminOptions._indexin(option) ) {
         // Admin controlled option, so do not let user change it
         return -1;
      }
   } else if( reason==CHANGE_EDIT_CLOSE ) {
      _str caption = _TreeGetCaption(index);
      _str label;
      _str option;
      parse caption with label "\t" before "\t" after "\t" adjacent;
      // Replace value we are editing with value set by user
      switch( col ) {
      case 1:
         before=value;
         break;
      case 2:
         after=value;
         break;
      case 3:
         adjacent=value;
         break;
      }
      option=blLabel2Option(label);
      if( !blIsValidOption(option,before,after,adjacent) ) {
         _str msg='Invalid blank line setting for "'label'"';
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         //_str new_caption = option"\t"before"\t"after"\t"adjacent;
         //_TreeSetCaption(index,new_caption);
         return -1;
      }
      modifyScheme();
   }

   return 0;
}

void ctl_CommentAfterTypeDeclIndent.on_change()
{
   modifyScheme();
}
void ctl_NoTrailingTypeDeclComments.lbutton_up()
{
   modifyScheme();
}
// Used by all the Trailing comment radio buttons
void ctl_TrailingCommentCol_enable.lbutton_up()
{
   // Did the user just click on something that was already checked?
   if( p_value!=p_user ) {
      modifyScheme();
      if( ctl_TrailingCommentCol_enable.p_value ) {
         ctl_TrailingCommentCol.p_enabled=true;
         ctl_TrailingCommentCol.adminEnable();   // Disable if admin controlled
         ctl_TrailingCommentIndent.p_enabled=false;
      } else if( ctl_TrailingCommentIndent_enable.p_value ) {
         ctl_TrailingCommentCol.p_enabled=false;
         ctl_TrailingCommentIndent.p_enabled=true;
         ctl_TrailingCommentIndent.adminEnable();   // Disable if admin controlled
      } else if( ctl_TrailingComment_OrigRelIndent.p_value ) {
         ctl_TrailingCommentCol.p_enabled=false;
         ctl_TrailingCommentIndent.p_enabled=false;
      }
      // Remember these so clicking on a radio button that is already checked
      // does not modify a scheme.
      ctl_TrailingCommentCol_enable.p_user=ctl_TrailingCommentCol_enable.p_value;
      ctl_TrailingCommentIndent_enable.p_user=ctl_TrailingCommentIndent_enable.p_value;
      ctl_TrailingComment_OrigRelIndent.p_user=ctl_TrailingComment_OrigRelIndent.p_value;
   }
}
void ctl_TrailingCommentCol.on_change()
{
   modifyScheme();
}

void ctl_IfBreakOnLogicalOps.lbutton_up()
{
   modifyScheme();
}
void ctl_IfLogicalOpAddContinuationIndent.on_change()
{
   modifyScheme();
}


#if 0

///////////////////////////////////////////////////////////////////////////////
// Tests
///////////////////////////////////////////////////////////////////////////////

_command aftest1()
{
   _str optionName;
   typeless val;

   say('*******************************************');
   optionName="IndentWithTabs";
   val=0;
   say('isValidOption('optionName','val') = 'isValidOption(optionName,val));

   optionName="VAlignAssignment";
   val=true;
   say('isValidOption('optionName','val') = 'isValidOption(optionName,val));

   optionName="IndentPerLevel";
   val=3;
   say('isValidOption('optionName','val') = 'isValidOption(optionName,val));
}

_command aftest2()
{
   adaScheme_t schemes:[];
   schemes._makeempty();
   getScheme(schemes,"",'ada',true);
   typeless schemeName;
   for( schemeName._makeempty();; ) {
      schemes._nextel(schemeName);
      if( schemeName._isempty() ) break;
      say(schemeName);
      typeless optionName;
      for( optionName._makeempty();; ) {
         schemes:[schemeName].options._nextel(optionName);
         if( optionName._isempty() ) break;
         say('   'optionName' => 'schemes:[schemeName].options:[optionName]);
      }
   }
}

_command aftest3()
{
   AdaFormatMaybeCreateDefaultScheme();
}

_command aftest4()
{
   adaScheme_t schemes:[];
   schemes._makeempty();
   getScheme(schemes,"",'ada',true);
   format(&schemes:["SlickEdit"],'ada',p_encoding,'d:\unittest\cformat\ada\junk1.ada',0,'',0,0);
}

_command aftest5()
{
   typeless options:[];
   options._makeempty();
   int status = getAdminOptions(options,'ada');
   say('aftest5: status='status);
   typeless i;
   for( i._makeempty();; ) {
      options._nextel(i);
      if( i._isempty() ) break;
      say('aftest5: options:['i']='options:[i]);
   }
}
#endif
