////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50365 $
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
#include "autocomplete.sh"
#include "color.sh"
#include "eclipse.sh"
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "c.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "commentformat.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "listproc.e"
#import "main.e"
#import "pmatch.e"
#import "ppedit.e"
#import "refactor.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tagform.e"
#import "tags.e"
#import "toast.e"
#import "util.e"
#import "wkspace.e"
#endregion

using se.lang.api.LanguageSettings;

/*
This module contains all the wrapper functions and Context Tagging&reg;
API functions for C/C++ and related languages.
*/


// Table of type conversions for each language's builtin types.
// If the first char of the list of candidate types is '*', the
// type is a builtin type, but has intrinsic methods, so should not
// be treated as a builtin type in all cases.
//
static _str _c_type_conversions:[]:[] = {

   // C++ builtin types
   'c' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'bool'               => ':bool:int:long:',
      'char'               => ':char:signed char:',
      'double'             => ':double:float:',
      'float'              => ':float:',
      'int'                => ':bool:enum:int:short:signed int:signed:',
      'long double'        => ':double:float:long double:',
      'long int'           => ':enum:long:signed long:long int:',
      'long long'          => ':long long:long:',
      'long'               => ':enum:long:signed long:long int:',
      'short int'          => ':sort:signed short:short int:',
      'short'              => ':sort:signed short:short int:',
      'signed char'        => ':char:signed char:',
      'signed int'         => ':int:signed:signed int:',
      'signed long'        => ':int:long:signed long:',
      'signed short'       => ':short:signed short:',
      'signed'             => ':int:signed int:signed:',
      'unsigned char'      => ':char:unsigned char:',
      'unsigned int'       => ':unsigned int:unsigned short:unsigned:size_t:',
      'size_t'             => ':unsigned int:unsigned short:unsigned:size_t:',
      'unsigned long int'  => ':unsigned long:unsigned int:unsigned long int:',
      'unsigned long long' => ':unsigned long long:',
      'unsigned long'      => ':unsigned long:unsigned int:unsigned long int:',
      'unsigned short int' => ':unsigned short:unsigned short int:',
      'unsigned short'     => ':unsigned short:unsigned short int:',
      'unsigned'           => ':unsigned int:unsigned short:unsigned:size_t:',
   },

   // D language builtin types
   'd' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'bool'               => ':bool:',
      'byte'               => ':byte:',
      'ubyte'              => ':ubyte:',
      'short'              => ':short:byte:int:',
      'ushort'             => ':ushort:ubyte:int:',
      'int'                => ':bool:byte:ubyte:short:int:ushort:char:wchar:dchar:',
      'uint'               => ':ubyte:ushort:uint:char:wchar:dchar',
      'long'               => ':long:short:byte:int:',
      'ulong'              => ':ulong:ushort:ubyte:uint:',
      'char'               => ':char:int:',
      'wchar'              => ':wchar:int:',
      'dchar'              => ':dchar:int:',
      'float'              => ':float:',
      'double'             => ':double:float:',
      'real'               => ':real:',
      'ifloat'             => ':ifloat:',
      'idouble'            => ':idouble:ifloat:',
      'ireal'              => ':ireal:',
      'cfloat'             => ':cfloat:idouble:double:',
      'cdouble'            => ':cdouble:cfloat:idouble:double:',
      'creal'              => ':creal:ireal:real:',
      'void'               => ':void:',
   },

   // Slick-C builtin types
   'e' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      '_str'               => '*:_str:',
      'bigfloat'           => ':float:bigfloat:',
      'bigint'             => ':int:bigint:',
      'bigstring'          => ':_str:bigstring:',
      'boolean'            => ':boolean:',
      'double'             => ':double:float:',
      'float'              => ':float:',
      'int'                => ':int:short:',
      'long'               => ':int:long:short:',
      'short'              => ':short:',
      'typeless'           => '*:_str:bigfloat:bigint:bigstring:boolean:double:float:int:long:short:typeless:unsigned:unsigned short:unsigned int:unsigned long:',
      'unsigned short'     => ':unsigned short:',
      'unsigned int'       => ':unsigned int:unsigned short:',
      'unsigned long'      => ':unsigned long:unsigned int:',
      'unsigned'           => ':unsigned:',
   },

   // Java builtin types
   'java' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'boolean'            => ':boolean:',
      'byte'               => ':byte:',
      'char'               => ':char:',
      'double'             => ':double:float:',    // integer types are allowed
      'float'              => ':float:',           // integer types are allowed
      'int'                => ':int:short:',       // byte, char are allowed
      'long'               => ':long:int:short:',  // byte, char are allowed
      'short'              => ':short:byte:',      // char is allowed
   },

   // JavaScript builtin types
   'js' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'boolean'            => ':boolean:',
      'byte'               => ':byte:',
      'char'               => ':char:',
      'double'             => ':double:float:',    // integer types are allowed
      'float'              => ':float:',           // integer types are allowed
      'int'                => ':int:short:',       // byte, char are allowed
      'long'               => ':long:int:short:',  // byte, char are allowed
      'short'              => ':short:byte:',      // char is allowed
   },

   // C# builtin types
   'cs' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'bool'               => ':bool:',
      'byte'               => ':byte:',
      'char'               => ':char:',
      'decimal'            => ':decimal:',       // integer types are allowed
      'double'             => ':double:float:',  // integer types are allowed
      'float'              => ':float:',         // integer types are allowed
      'int'                => ':int:short:',     // byte
      'long'               => ':int:long:',      // short, byte
      'short'              => ':short:byte:',
      'string'             => '*:string:',
      'ubyte'              => ':ubyte:',
   },

   // InstallScript builtin types
   'rul' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'BOOL'               => ':BOOL:',
      'BYREF'              => ':BYREF:',
      'CHAR'               => ':CHAR:',
      'HWND'               => ':HWND:',
      'INT'                => ':INT:SHORT:',
      'LIST'               => ':LIST:',
      'LONG'               => ':LONG:INT:SHORT:',
      'LPSTR'              => ':LPSTR:',
      'NUMBER'             => ':NUMBER:',
      'POINTER'            => ':POINTER:',
      'SHORT'              => ':SHORT:',
      'STRING'             => ':STRING:LPSTR:',
   },

   // Python builtin types
   'py' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'complex'            => '*:complex:float:',
      'float'              => ':float:',
      'long'               => ':long:int:',
      'int'                => ':int:',
      'string'             => '*:string:',
   },

   // this is kind of hokey, PHP is a typeless language, so you
   // really don't have these types to work with at all.
   'phpscript' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'array'              => ':array:',
      'double'             => ':double:real:float:',
      'float'              => ':float:',
      'int'                => ':int:integer:',
      'integer'            => ':int:integer:',
      'object'             => ':object:',
      'real'               => ':double:real:float:',
      'string'             => ':string:',
   },

   // ColdFusion Scripts (CFScript)
   'cfscript' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'cfscript:'  'float'         => ':float:',
      'cfscript:'  'int'           => ':int:',
      'cfscript:'  'Object'        => ':Object:String:',
      'cfscript:'  'String'        => ':String:',
      'cfscript:'  'boolean'       => ':boolean:',
      'cfscript:'  'number'        => ':number:int:',
      'cfscript:'  'datetime'      => ':datetime:',
   },

   'systemverilog' => {
      'byte'               => ':byte:shortint:int:longint:integer:time:',
      'shortint'           => ':byte:shortint:int:longint:integer:time:',
      'int'                => ':byte:shortint:int:longint:integer:time:',
      'longint'            => ':byte:shortint:int:longint:integer:time:',
      'integer'            => ':byte:shortint:int:longint:integer:time:',
      'time'               => ':byte:shortint:int:longint:integer:time:',
      'bit'                => ':bit:logic:reg:',
      'logic'              => ':bit:logic:reg:',
      'reg'                => ':bit:logic:reg:',
      'real'               => ':real:shortreal:realtime:',
      'shortreal'          => ':real:shortreal:realtime:',
      'realtime'           => ':real:shortreal:realtime:',
      'supply0'            => ':supply0:',
      'supply1'            => ':supply1:',
      'tri'                => ':tri1:',
      'triand'             => ':triand:',
      'trior'              => ':trior:',
      'tri0'               => ':tri0:',
      'tri1'               => ':tri1:',
      'wire'               => ':wire:',
      'wand'               => ':wand:',
      'wor'                => ':wor:',
      'trireg'             => ':trireg:',
      'string'             => ':string:',
      'event'              => ':event:',
   }
};

/**
 * If set to true, when the user selects an operator from
 * list-members, Context Tagging&reg; will attempt to replace
 * the verbose "operator" syntax with the actual operator.
 *
 * @default false
 * @categories Configuration_Variables
 */
boolean def_c_replace_operators = false;

/**
 * Defines whether to skip blank lines when attempting to expand
 * doc comments above a declaration.  If set to false, then
 * expanding a doc comment will look for a declaraction on the
 * very next line ONLY.  If set to false, will look for a
 * declaraction by skipping any blank lines.
 *
 * @default false
 * @categories Configuration_Variables
 */
boolean def_allow_blank_lines_before_decl = false;

boolean do_default_is_builtin_type(_str return_type, boolean no_class_types=false)
{
   boolean is_builtin = false;
   index := _FindLanguageCallbackIndex('_%s_is_builtin_type');
   if(index) {
       is_builtin = call_index(return_type, no_class_types, index);
   } 
   return is_builtin;
}

/**
 * Is the given return type a builtin type?
 *
 * @param return_type    Return type to check if it is builtin
 * @param no_class_types Do not include objects, such as _str in Slick-C
 *
 * @return true if it is builtin, false otherwise
 */
boolean _c_is_builtin_type(_str return_type, boolean no_class_types=false)
{
   // void is a special case, can't assign to this
   if (return_type=='void') {
      return(true);
   }

   _str lang=_c_get_type_conversion_lang(p_LangId);
   // Do we have this extension on our table (above)?
   if (!_c_type_conversions._indexin(lang)) {
      return(false);
   }
   // Is the return type in the table?
   if (_c_type_conversions:[lang]._indexin(return_type)) {
      // is it a class type?
      if (no_class_types && substr(_c_type_conversions:[lang]:[return_type],1,1)=='*') {
         return(false);
      }
      // this is a built-in
      return(true);
   }
   // this is not a built-in type
   return(false);
}

/**
 * Can a variable of the 'candidate_type' be assigned to a variable
 * of the 'expected_type', where both types are builtin types?
 *
 * @param expected_type        Expected type to assign to
 * @param candidate_type       Candidate type to check compability of
 * @param candidate_is_pointer Is the candidate type a pointer?
 *
 * @return true if assignment compatible, false otherwise
 */
boolean _c_builtin_assignment_compatible(_str expected_type,
                                         _str candidate_type,
                                         boolean candidate_is_pointer)
{
   // if the types match exactly, then always return true,
   // no matter what language, except for 'enum' and 'void'
   if (!candidate_is_pointer && expected_type:==candidate_type &&
       expected_type:!='enum' && expected_type!='void') {
      return(true);
   }

   // special case for 'c', pointers are assignment compatible with bool
   if (_LanguageInheritsFrom('c') && candidate_is_pointer) {
      return(expected_type=='bool');
   }

   // void is a special case, can't assign to this
   if (expected_type=='void' && !candidate_is_pointer) {
      return(false);
   }

   // otherwise, the answer is in the mighty table
   _str extension=_c_get_type_conversion_lang(p_LangId);
   if (_c_type_conversions._indexin(extension) &&
       _c_type_conversions:[extension]._indexin(expected_type)) {
      _str allowed_list = _c_type_conversions:[extension]:[expected_type];
      return (pos(":"candidate_type":",allowed_list))? true:false;
   }

   // didn't find a match, assume that it doesn't match
   return(false);
}

/**
 * Looks through the _c_type_conversions table and uses def-inherit-(ext) to 
 * find the "real" extension for a type
 */
static _str _c_get_type_conversion_lang(_str lang=p_LangId)
{
   _str cur_lang=lang;
   // Do we have this extension on our table (above)?
   // Loop through and anything that if we do not have this extension in the 
   // table, get the extension that we inherit from and see if that extension
   // is in the table
   for (;;) {
      if (_c_type_conversions._indexin(cur_lang)) {
         break;
      }

      inheritsFrom := LanguageSettings.getLangInheritsFrom(cur_lang);
      if (inheritsFrom == '') {
         // If we never found anything, use the ext that was passed in
         return lang;
      }

      cur_lang = inheritsFrom;
   }
   return(cur_lang);
}

//=========================================================================
// Table of type conversions for each language's autoboxing conversions.
//
static _str _c_boxing_conversions:[]:[] = {

   // Java builtin types
   'java' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'boolean'            => ':java/lang/Boolean:',
      'byte'               => ':java/lang/Byte:',
      'char'               => ':java/lang/Character:',
      'double'             => ':java/lang/Double:',
      'float'              => ':java/lang/Float:',
      'int'                => ':java/lang/Integer:',
      'long'               => ':java/lang/Long:',
      'short'              => ':java/lang/Short:',
   },

   // C# builtin types
   'cs' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'bool'               => ':System/Boolean:',
      'boolean'            => ':System/Boolean:',
      'byte'               => ':System/Byte:',
      'char'               => ':System/Char:',
      'decimal'            => ':System/Decimal:',
      'double'             => ':System/Double:',
      'float'              => ':System/Single:',
      'single'             => ':System/Single:',
      'int'                => ':System/Int32:',
      'integer'            => ':System/Int32:',
      'long'               => ':System/Int64:',
      'short'              => ':System/Int16:',
      'string'             => ':System/String:',
      'ubyte'              => ':System/UInt8:',
      'object'             => ':System/Object:',
      'delegate'           => ':System/Delegate:',
   },

   // D builtin types
   'd' => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      'bool'               => ':__INTEGRAL_TYPE:',
      'byte'               => ':__INTEGRAL_TYPE:',
      'ubyte'              => ':__INTEGRAL_TYPE:',
      'short'              => ':__INTEGRAL_TYPE:',
      'ushort'             => ':__INTEGRAL_TYPE:',
      'int'                => ':__INTEGRAL_TYPE:',
      'uint'               => ':__INTEGRAL_TYPE:',
      'long'               => ':__INTEGRAL_TYPE:',
      'ulong'              => ':__INTEGRAL_TYPE:',
      'char'               => ':__INTEGRAL_TYPE:',
      'wchar'              => ':__INTEGRAL_TYPE:',
      'dchar'              => ':__INTEGRAL_TYPE:',
      'float'              => ':__FLOATING_POINT_TYPE:',
      'double'             => ':__FLOATING_POINT_TYPE:',
      'real'               => ':__FLOATING_POINT_TYPE:',
      'ifloat'             => ':__IMAGINARY_TYPE:',
      'idouble'            => ':__IMAGINARY_TYPE:',
      'ireal'              => ':__IMAGINARY_TYPE:',
      'cfloat'             => ':__IMAGINARY_TYPE:',
      'cdouble'            => ':__IMAGINARY_TYPE:',
      'creal'              => ':__IMAGINARY_TYPE:',
      'void'               => ':__ANY_TYPE:',
      'enum'               => ':__ENUMERATED_TYPE:',
   },
};


/**
 * Is there an autoboxing conversion to convert from the
 * candidate
 *
 * @param expected_type        Expected type to assign to
 * @param candidate_type       Candidate type to check compability of
 *
 * @return true if assignment compatible, false otherwise
 */
boolean _c_boxing_conversion_allowed(_str expected_type, _str candidate_type)
{
   // otherwise, the answer is in the mighty table
   if (_c_boxing_conversions._indexin(p_LangId) &&
       _c_boxing_conversions:[p_LangId]._indexin(expected_type)) {
      _str allowed_list = _c_boxing_conversions:[p_LangId]:[expected_type];
      return (pos(":"candidate_type":",allowed_list))? true:false;
   }

   // didn't find a match, assume that it doesn't match
   return(false);
}

/**
 * Is there an autoboxing conversion to convert from the
 * candidate
 *
 * @param expected_type        Expected type to assign to
 * @param candidate_type       Candidate type to check compability of
 *
 * @return true if assignment compatible, false otherwise
 */
_str _c_get_boxing_conversion(_str builtin_type)
{
   // otherwise, the answer is in the mighty table
   if (_c_boxing_conversions._indexin(p_LangId) &&
       _c_boxing_conversions:[p_LangId]._indexin(builtin_type)) {
      _str allowed_list = _c_boxing_conversions:[p_LangId]:[builtin_type];
      parse allowed_list with ':' allowed_list ':';
      return allowed_list;
   }

   // didn't find a match, assume that it doesn't match
   return '';
}

/**
 * This is the default function for matching return types.
 * It simply compares types for an exact match and inserts the
 * candidate tag if they match.
 *
 * The extension specific hook function _[ext]_match_return_type()
 * is normally used to perform type matching, and account for
 * language specific features, such as pointer dereferencing,
 * class construction, function call, array access, etc.
 *
 * @param rt_expected    expected return type for this context
 * @param rt_candidate   candidate return type
 * @param tag_name       candidate tag name
 * @param type_name      candidate tag type
 * @param tag_flags      candidate tag flags
 * @param file_name      candidate tag file location
 * @param line_no        candidate tag line number
 * @param prefixexp      prefix to prepend to tag name when inserting ('')
 * @param tag_files      tag files to search (not used)
 * @param tree_wid       tree to insert directly into (gListHelp_tree_wid)
 * @param tree_index     index of tree to insert items at (TREE_ROOT_INDEX)
 *
 * @return number of items inserted into the tree
 */
int _c_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                         struct VS_TAG_RETURN_TYPE &rt_candidate,
                         _str tag_name,_str type_name, int tag_flags,
                         _str file_name, int line_no,
                         _str prefixexp,typeless tag_files,
                         int tree_wid, int tree_index)
{
   //say("_c_match_return_type: expected ="rt_expected.return_type " pointer="rt_expected.pointer_count " flags="rt_expected.return_flags " template="rt_expected.istemplate);
   //say("_c_match_return_type: name="tag_name" candidate="rt_candidate.return_type" pointer="rt_candidate.pointer_count" flags="rt_candidate.return_flags" template="rt_candidate.istemplate);
   // number of matches found
   _str array_operator="[]";
   boolean array_object_compatible=false;
   boolean dereference_compatible=true;
   boolean reference_compatible=false;
   boolean insert_tags=false;
   int match_count=0;

   // is this a builtin type?
   boolean expected_is_builtin=false;
   boolean candidate_is_builtin=false;
   if (!rt_expected.istemplate && _c_is_builtin_type(rt_expected.return_type)) {
      expected_is_builtin=true;
   }
   if (!rt_expected.istemplate && _c_is_builtin_type(rt_candidate.return_type)) {
      candidate_is_builtin=true;
   }

   // if one is a template, the other must also be a template class
   if (rt_candidate.istemplate!=rt_expected.istemplate) {
      //say("_c_match_return_type: TEMPLATE MISMATCH");
      return(0);
   }
   // if these are templates, expect the arguments to match *exactly*
   if (rt_candidate.istemplate==true) {
      typeless i;
      int n_expected=0, n_candidate=0;
      for (i._makeempty();;) {
         rt_expected.template_args._nextel(i);
         if (i._isempty()) break;
         ++n_expected;
      }
      for (i._makeempty();;) {
         rt_candidate.template_args._nextel(i);
         if (i._isempty()) break;
         if (!rt_expected.template_args._indexin(i)) {
            //say("_c_match_return_type: MISSING TEMPLATE ARG");
            return(0);
         }
         if (rt_candidate.template_args:[i]!=rt_expected.template_args:[i]) {
            //say("_c_match_return_type: MISMATCHED TEMPLATE ARG");
            return(0);
         }
         ++n_candidate;
      }
      if (n_expected!=n_candidate) {
         //say("_c_match_return_type: DIFFERENT NUMBER OF TEMPLATE ARGS");
         return(0);
      }
   }

   // check the return flags for assignment compatibility
   if (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) {
      dereference_compatible=false;
      if (!(rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
         array_operator=":[]"; // this is a hash table or array of hash tables
      }

      if ((rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) &&
          (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) !=
          (rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
         //say("_c_match_return_type: CAN NOT ASSIGN AN ARRAY TO A HASH TABLE");
         return(0);  // can not assign an array to a hash table
      }
   }
   if ((rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY) &&
       (!(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY))) {
      //return(0);  // will not try to violate const members
   }
   if ((rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY) &&
       (!(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY))) {
      //say("_c_match_return_type: VOLATILE");
      return(0);  // will not try to violate volatile members
   }
   if (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
      // what do we do here?
   }
   if (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS) {
      // what do I do here?
   }
   if (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) {
      // what do I do here?
   }

   // decompose the match tag in order to determine the tag type
   _str expected_tag_type='';
   _str expected_tag_name='';
   _str expected_class='';
   int expected_tag_flags=0;
   if (rt_expected.taginfo!='') {
      tag_tree_decompose_tag(rt_expected.taginfo,expected_tag_name,
                             expected_class,expected_tag_type,expected_tag_flags);
   }
   _str candidate_tag_type='';
   _str candidate_tag_name='';
   _str candidate_class='';
   int candidate_tag_flags=0;
   if (rt_candidate.taginfo!='') {
      tag_tree_decompose_tag(rt_candidate.taginfo,candidate_tag_name,
                             candidate_class,candidate_tag_type,candidate_tag_flags);
   }

   // check if both are builtin types and if they are assignment compatible
   if (expected_is_builtin && candidate_is_builtin) {
      if (rt_candidate.return_type:==rt_expected.return_type) {
         insert_tags=true;
         reference_compatible=true;
      } else if (rt_expected.pointer_count==0 &&
                 _c_builtin_assignment_compatible(rt_expected.return_type,
                                                  rt_candidate.return_type,
                                                  rt_candidate.pointer_count>0)
                ) {
         insert_tags=true;
         reference_compatible=true;
      } else {
         //say("_c_match_return_type: BUILTIN TYPES, NOT COMPATIBLE");
         return(0);
      }
   }

   // check if expected type is enumerated type
   if (!expected_is_builtin && expected_tag_type=='enumc' && candidate_is_builtin) {
      if (candidate_is_builtin && rt_candidate.pointer_count==0 &&
          _c_builtin_assignment_compatible("enum",
                                           rt_candidate.return_type,
                                           rt_candidate.pointer_count>0)
         ) {
         insert_tags=true;
         reference_compatible=false;
      } else {
         //say("_c_match_return_type: ENUMERATED TYPE");
         return(0);
      }
   }

   // check if candidate type is enumerated type
   if (!candidate_is_builtin && candidate_tag_type=='enumc' && expected_is_builtin) {
      if (expected_is_builtin && rt_expected.pointer_count==0 &&
          _c_builtin_assignment_compatible(rt_expected.return_type,"enum",false)
         ) {
         insert_tags=true;
         reference_compatible=false;
      } else {
         //say("_c_match_return_type: CANDIDATE IS ENUMERATED TYPE");
         return(0);
      }
   }

   // list any pointer if assigning to a void * parameter
   if (rt_candidate.pointer_count >= 1 &&
       rt_expected.pointer_count==1 && rt_expected.return_type=='void') {
      insert_tags=true;
   }

   // check if a Java or C# array can be assigned to object
   if (!expected_is_builtin && rt_expected.pointer_count==0 &&
       (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
      if (_LanguageInheritsFrom('java') && rt_expected.return_type:=='java.lang/Object') {
         insert_tags=true;
         array_object_compatible=true;
      } else if (_LanguageInheritsFrom('java') && rt_expected.return_type:=='java/lang/Object') {
         insert_tags=true;
         array_object_compatible=true;
      }
      if (_LanguageInheritsFrom('cs') &&
          (rt_expected.return_type:=='System/Array' ||
           tag_is_parent_class(rt_expected.return_type,'System/Array',
                               tag_files,true,true))) {
         insert_tags=true;
         array_object_compatible=true;
      }
   }

   // check if we are attempting to assign a Slick-C array to a typeless
   if (expected_is_builtin && rt_expected.pointer_count==0 &&
      (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY) &&
       _LanguageInheritsFrom("e") &&
       (rt_expected.return_type=="var" || rt_expected.return_type=="typeless")) {
      array_object_compatible=true;
   }

   // handle autoboxing
   if (candidate_is_builtin && !expected_is_builtin &&
       rt_candidate.pointer_count == 0 && rt_expected.pointer_count == 0 &&
       _c_boxing_conversion_allowed(rt_candidate.return_type,
                                    rt_expected.return_type)) {
      insert_tags = true;
   }

   // handle auto-unboxing
   if (!candidate_is_builtin && expected_is_builtin &&
       rt_candidate.pointer_count == 0 && rt_expected.pointer_count == 0 &&
       _c_boxing_conversion_allowed(rt_expected.return_type,
                                    rt_candidate.return_type)) {
      insert_tags = true;
   }

   // check if both are not builtin and match in type heirarchy
   if (!expected_is_builtin && !candidate_is_builtin && !insert_tags) {
      if (rt_candidate.return_type:==rt_expected.return_type) {
         insert_tags=true;
         reference_compatible=true;
      } else if (tag_is_parent_class(rt_expected.return_type,
                                     rt_candidate.return_type,
                                     tag_files,true,true)) {
         insert_tags=true;
      } else {
         // more to do here, check for type conversion operator
         //say("_c_match_return_type: NO TYPE CONVERSION");
         return(0);
      }
   }

   // if one is a builtin, but the other isn't, give up
   if (!insert_tags && expected_is_builtin != candidate_is_builtin) {
      // more to do here, need to support "void*" and classes
      // type conversion operators defined.
      //say("_c_match_return_type: BUILTIN VS NOT-BUILTIN TYPE");
      return(0);
   }

   // Can only dereference variables
   if (type_name!='var' && type_name!='gvar' && type_name!='param' && type_name!='lvar') {
      dereference_compatible=false;
      reference_compatible=false;
      array_operator='';
      // technically, references are OK here, but I don't like the idea, so there!
   }

   /*
   // type must match exactly
   // return flags must match exactly
   // don't even try to handle templates
   if (rt1.istemplate || rt2.istemplate) {
      return(false);
   }
   // count this as a match
   */

   if (tag_return_type_equal(rt_expected,rt_candidate,p_EmbeddedCaseSensitive)) {
      insert_tags=true;
   }

   // If this is an enumerated type which is
   // outside of our current scope,
   // then attempt to qualify the symbol name
   _str scope_info='';
   if (prefixexp == '') {
      _str cur_tag_name='';
      int cur_tag_flags=0;
      _str cur_type_name='';
      int cur_type_id=0;
      _str cur_context='';
      _str cur_class='';
      _str cur_package='';
      int context_id = tag_get_current_context(cur_tag_name, cur_tag_flags,
                                               cur_type_name, cur_type_id,
                                               cur_context, cur_class, cur_package);
      if (context_id <= 0) {
         cur_context = '';
      }
      _str outer_name='';
      _str inner_name='';
      tag_split_class_name(candidate_class, inner_name, outer_name);
      if (outer_name!='' && pos(outer_name, cur_context) != 1) {
         _str class_sep = (p_LangId=='java' || p_LangId=='cs' || p_LangId=='d')? '.':'::';
         outer_name = stranslate(outer_name,class_sep,':');
         outer_name = stranslate(outer_name,class_sep,'/');
         scope_info = outer_name:+class_sep;
      }
   }

   // OK, the types seem to match,
   // compute pointer_prefix and pointer_postfix operators to
   // handle pointer indirection mismatches
   if (insert_tags) {
      if (prefixexp!='') {
         dereference_compatible=false;
         reference_compatible=false;
         //if (rt_expected.pointer_count==rt_candidate.pointer_count) {
         //   return(1);
         //}
         //if (rt_expected.pointer_count-rt_candidate.pointer_count==-1 &&
         //    (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
         //   return(1);
         //}
      }
      int k=0;
      if (array_object_compatible && rt_expected.pointer_count!=rt_candidate.pointer_count) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,tag_name,type_name,file_name,line_no,"",tag_flags,"",file_name":"line_no);
         match_count++;
      }
      switch (rt_expected.pointer_count-rt_candidate.pointer_count) {
      case -2:
         if (!_LanguageInheritsFrom('java') && !_LanguageInheritsFrom('js') && dereference_compatible) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"**":+tag_name,type_name,file_name,line_no,"",tag_flags,"",file_name":"line_no);
            match_count++;
            if (array_operator!="" && (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"*"tag_name:+array_operator,type_name,file_name,line_no,"",tag_flags,"",file_name":"line_no);
               match_count++;
            }
         }
         break;
      case -1:
         if (!_LanguageInheritsFrom('java') && !_LanguageInheritsFrom('js') && dereference_compatible) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"*":+tag_name,type_name,file_name,line_no,"",tag_flags,"",file_name":"line_no);
            match_count++;
         }
         if (array_operator!='' && (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,tag_name:+array_operator,type_name,file_name,line_no,"",tag_flags,"",file_name":"line_no);
            match_count++;
         }
         break;
      case 0:
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,scope_info:+tag_name,type_name,file_name,line_no,"",tag_flags,"",file_name":"line_no);
         match_count++;
         if (rt_candidate.pointer_count==1 && reference_compatible && array_operator!='' &&
             (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) &&
             !(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) &&
             !_LanguageInheritsFrom('java') && !_LanguageInheritsFrom('js')) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,'&':+tag_name:+array_operator,type_name,file_name,line_no,"",tag_flags,"",file_name":"line_no);
            match_count++;
         }
         break;
      case 1:
         if (!_LanguageInheritsFrom('java') && !_LanguageInheritsFrom('js') && reference_compatible &&
             !(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"&":+tag_name,type_name,file_name,line_no,"",tag_flags,"",file_name":"line_no);
            match_count++;
         }
         break;
      }
   }

   // that's all folks
   //say("_c_match_return_type: tree_wid="tree_wid" tree_index="tree_index);
   //say("_c_match_return_type: MATCH_COUNT="match_count" matches="tag_get_num_of_matches());
   return(match_count);
}
/**
 * This is the default function for matching return types.
 * It simply compares types for an exact match and inserts the
 * candidate tag if they match.
 *
 * The extension specific hook function _[ext]_match_return_type()
 * is normally used to perform type matching, and account for
 * language specific features, such as pointer dereferencing,
 * class construction, function call, array access, etc. 
 *  
 * NOTE: This feature is no longer used in 11.0 
 *
 * @param rt             return type
 * @param tag_name       tag name
 * @param type_name      tag type
 * @param tag_flags      tag flags
 * @param file_name      tag file location
 * @param line_no        tag line number
 * @param prefixexp      set to prefix expression for accessing this member
 * @param tag_files      tag files to search (not used)
 * @param filter_flags   tag filters (VS_TAGFILTER_*)
 *
 * @return number of items inserted into the tree 
 */
int _c_find_members_of(struct VS_TAG_RETURN_TYPE &rt,
                       _str tag_name,_str type_name, int tag_flags,
                       _str file_name, int line_no,
                       _str &prefixexp, typeless tag_files, int filter_flags,
                       VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   // no return type, forget this
   if (rt.return_type=='') {
      return(0);
   }

   // is this a builtin type?
   if (_c_is_builtin_type(rt.return_type)) {
      return(0);
   }

   // we are willing to handle one level of pointers
   switch (rt.pointer_count) {
   case 1:
      if (_LanguageInheritsFrom('java') || _LanguageInheritsFrom('js') ||
          (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
         prefixexp=prefixexp:+tag_name:+'[].';
      } else if (_LanguageInheritsFrom('e') &&
                 (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE)) {
         prefixexp=prefixexp:+tag_name:+':[].';
      } else {
         prefixexp=prefixexp:+tag_name:+'->';
      }
      break;
   case 0:
      prefixexp=prefixexp:+tag_name:+'.';
      break;
   default:
      return(0);
   }

   // the type seems OK, let's try listing members here
   int num_matches=0;
   tag_list_in_class("",rt.return_type,0,0,tag_files,
                     num_matches,def_tag_max_list_members_symbols,
                     filter_flags,VS_TAGCONTEXT_ANYTHING,
                     false, true, null, null, visited);
   //say("_c_find_members_of: match_type="rt.match_type" num_matches="tag_get_num_of_matches());

   // that's all folks
   return(0);
}

/**
 * Hook function for analyzing variable or function return types.
 * This is used by function argument type matching to determine the
 * precise type of the argument required, and the types of all the
 * candidate variables.
 *
 * @param errorArgs      List of argument for codehelp error messages
 * @param tag_files      list of tag files
 * @param tag_name       name of tag to analyze return type of
 * @param class_name     name of class that the tag belongs to
 * @param type_name      type name of tag (see VS_TAGTYPE_*)
 * @param tag_flags      tag flags (bitset of VS_TAGFLAG_*)
 * @param file_name      file that the tag is found in
 * @param return_type    return type to analyze (VS_TAGDETAIL_return_only)
 * @param rt             (reference) returned return type information
 * @param visited        (reference) hash table of previous results
 *
 * @return 0 on success, nonzero otherwise.
 */
int _c_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                           _str tag_name, _str class_name,
                           _str type_name, int tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[])
{
   errorArgs._makeempty();
   // check for #define'd constants
   if (type_name=='define') {
      rt.istemplate=false;
      rt.taginfo=tag_tree_compose_tag(tag_name,class_name,type_name,tag_flags,"",return_type);
      if (pos("^:i$",return_type,1,'r')) {
         if (_LanguageInheritsFrom('rul')) {
            rt.return_type='INT';
         } else {
            rt.return_type='int';
         }
      } else if (pos("^:n$",return_type,1,'r')) {
         if (_LanguageInheritsFrom('rul')) {
            rt.return_type='NUMBER';
         } else {
            rt.return_type='float';
         }
      } else if (_LanguageInheritsFrom('e') && pos("^[']?*[']$",return_type,1,'r')) {
         rt.return_type='_str';
      } else if (pos("^['](\\\\?|?)[']$",return_type,1,'r')) {
         if (_LanguageInheritsFrom('rul')) {
            rt.return_type='CHAR';
         } else {
            rt.return_type='char';
         }
      } else if (pos("^:q$",return_type,1,'r')) {
         if (_LanguageInheritsFrom('e')) {
            rt.return_type='_str';
         } else if (_LanguageInheritsFrom('cs')) {
            rt.return_type='string';
         } else if (_LanguageInheritsFrom('rul')) {
            rt.return_type='STRING';
         } else if (_LanguageInheritsFrom('java')) {
            rt.return_type='java/lang/String';
         } else if (_LanguageInheritsFrom('c')) {
            rt.return_type='char';
            rt.pointer_count=1;
         }
      } else if (return_type=='false' || return_type=='true') {
         if (_LanguageInheritsFrom('e') || _LanguageInheritsFrom('js') || _LanguageInheritsFrom('java')) {
            rt.return_type='boolean';
         } else if (_LanguageInheritsFrom('c') || _LanguageInheritsFrom('cs')) {
            rt.return_type='bool';
         }
      } else if (_LanguageInheritsFrom('rul') && (return_type=='FALSE' || return_type=='TRUE')) {
         rt.return_type='BOOL';
      }
      if (rt.return_type=='') {
         rt.taginfo="";
         errorArgs[1]=tag_name;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      }
      return(0);
   } else if (type_name=='enumc') {
      rt.istemplate=false;
      rt.taginfo=tag_tree_compose_tag(tag_name,class_name,type_name,tag_flags);
      rt.return_type=class_name;
      rt.pointer_count=0;
      return(0);
   } else if (type_name=='enum') {
      rt.taginfo="";
      errorArgs[1]=tag_name;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   } else if (return_type=='void') {
      rt.taginfo="";
      errorArgs[1]=tag_name;
      return VSCODEHELPRC_RETURN_TYPE_IS_VOID;
   }
   // delegate to the return type analysis functions
   int status = _c_parse_return_type(errorArgs,tag_files,
                                     tag_name,class_name,file_name,
                                     return_type,
                                     _LanguageInheritsFrom('java') || _LanguageInheritsFrom('d'),
                                     rt,visited);
   //say("_c_analyze_return_type: status="status" type="rt.return_type);

   // that's all, return result, allow builtin types
   if ((status && status!=VSCODEHELPRC_BUILTIN_TYPE)) {
      return(status);
   }
   return(0);
}

/**
 * Insert the language-specific constants matching the expected type.
 *
 * @param rt_expected    expected return type
 * @param tree_wid       window ID for tree to insert into
 * @param tree_index     tree index to insert at
 * @param lastid_prefix  word prefix to search for 
 * @param exact_match    search for an exact match or a prefix 
 * @param case_sensitive case-sensitive identifier match?
 *
 * @return number of items inserted
 */
int _c_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                int tree_wid, int tree_index,
                                _str lastid_prefix="",
                                boolean exact_match=false, boolean case_sensitive=true)
{
   // number of matches inserted
   int match_count=0;
   int k=0;

   // insert NULL, if it isn't #defined, screw them
   if (rt_expected.pointer_count>0) {
      if (!(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
         if (_CodeHelpDoesIdMatch(lastid_prefix, "NULL", exact_match, case_sensitive)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"NULL","const","",0,"",0,"");
            match_count++;
         }
      }
      // maybe insert 'this'
      if (rt_expected.pointer_count==1) {
         _str this_class_name = _MatchThisOrSelf();
         if (this_class_name!='') {
            typeless tag_files=tags_filenamea();
            if (this_class_name == rt_expected.return_type ||
                tag_is_parent_class(rt_expected.return_type,this_class_name,tag_files,true,true)) {
               if (_CodeHelpDoesIdMatch(lastid_prefix, "this", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"this","const","",0,"",0,"");
                  match_count++;
               }
            }
         }
      }
      // insert constant string
      if (_LanguageInheritsFrom('c') && rt_expected.pointer_count==1 && rt_expected.return_type=='char') {
         if (_CodeHelpDoesIdMatch(lastid_prefix, "\"", exact_match, case_sensitive)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"\"\"","const","",0,"",0,"");
            match_count++;
         }
      }

      // Try inserting new 'class'
      if (!_c_is_builtin_type(rt_expected.return_type) && _LanguageInheritsFrom("c")) {

         // If it was specified as a generic, include the set parameters in the suggestion
         _str generic_args = '';
         _str blank_args = '';
         if (rt_expected.istemplate && rt_expected.template_names._length() > 0) {
            _str names[];
            for (ai := 0; ai < rt_expected.template_names._length(); ai++) {
               _str ty = rt_expected.template_args:[rt_expected.template_names[ai]];
               names[ai] = ty;
            }
            generic_args="<"(join(names, ','))">";
            blank_args="<>";
         }

         // check the current package name
         _str cur_tag_name="", cur_type_name="", cur_context="", cur_class="", cur_package="";
         typeless cur_flags=0, cur_type_id=0;
         tag_get_current_context(cur_tag_name, cur_flags, cur_type_name, cur_type_id, cur_context, cur_class, cur_package);

         // insert qualified class name (except for java.lang and current package)
         _str class_name=stranslate(rt_expected.return_type,'.',VS_TAGSEPARATOR_class);
         class_name=stranslate(class_name,'.',VS_TAGSEPARATOR_package);
         if (pos("std::", class_name) != 1 && 
             pos("std/", class_name) != 1 && 
             pos(cur_package, class_name) != 1) {
            if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",VS_TAGFLAG_constructor,"");
               match_count++;
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",VS_TAGFLAG_constructor,"");
               match_count++;
            }
         }

         // insert unqualified class name
         int p = lastpos('.', class_name);
         if (p > 0) {
            class_name = substr(class_name, p+1);
            if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",VS_TAGFLAG_constructor,"");
               match_count++;
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",VS_TAGFLAG_constructor,"");
               match_count++;
            }
         }
      }

      // that's all
      return 0;
   }

   // insert character constant
   if (_LanguageInheritsFrom('c') && rt_expected.pointer_count==0 && rt_expected.return_type=='char') {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "\'", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"''","const","",0,"",0,"");
         match_count++;
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"'\\0'","const","",0,"",0,"");
         match_count++;
      }
   }

   // Insert boolean
   if (rt_expected.return_type=='bool') {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "true", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"true","const","",0,"",0,"");
         match_count++;
      }
      if (_CodeHelpDoesIdMatch(lastid_prefix, "false", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"false","const","",0,"",0,"");
         match_count++;
      }
   }


   // Insert sizeof function
   if (_LanguageInheritsFrom('c') && !_LanguageInheritsFrom('d')) {
      if (rt_expected.return_type=='int' || 
          rt_expected.return_type=='long' ||
          rt_expected.return_type=='long int' ||
          rt_expected.return_type=='short' ||
          rt_expected.return_type=='short int' ||
          rt_expected.return_type=='long long' ||
          rt_expected.return_type=='long long int' ||
          rt_expected.return_type=='unsigned char' ||
          rt_expected.return_type=='unsigned int' ||
          rt_expected.return_type=='unsigned long' ||
          rt_expected.return_type=='unsigned long int' ||
          rt_expected.return_type=='unsigned long long' ||
          rt_expected.return_type=='unsigned long long int' ||
          rt_expected.return_type=='unsigned short' || 
          rt_expected.return_type=='unsigned short int' || 
          rt_expected.return_type=='intptr_t' || 
          rt_expected.return_type=='ssize_t' || 
          rt_expected.return_type=='size_t' ) {
         if (_CodeHelpDoesIdMatch(lastid_prefix, "sizeof", exact_match, case_sensitive)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"sizeof","proto","",0,"",0,"");
            match_count++;
         }
      }
   }

   // that's all folks
   return(match_count);
}

/**
 * Format the given tag for display as the variable definition part
 * in list-members or function help.  This function is also used
 * for generating code (override method, add class member, etc.).
 * The current object must be an editor control.
 *
 * @param lang           Current language ID {@see p_LangId} 
 * @param info           tag information
 *                       <UL>
 *                       <LI>info.class_name
 *                       <LI>info.member_name
 *                       <LI>info.type_name;
 *                       <LI>info.flags;
 *                       <LI>info.return_type;
 *                       <LI>info.arguments
 *                       <LI>info.exceptions
 *                       </UL>
 * @param flags          bitset of VSCODEHELPDCLFLAG_*
 * @param decl_indent_string    string to indent declaration with.
 * @param access_indent_string  string to indent public: with. 
 * @param header_list           array of strings that is a comment to insert 
 *                              between the access modifier and the declaration.
 *
 * @return string holding formatted declaration.
 */
_str _c_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0, 
                 _str decl_indent_string="",
                 _str access_indent_string="", _str (&header_list)[] = null)
{
   int tag_flags=info.flags;
   _str tag_name=info.member_name;
   _str class_name=info.class_name;
   _str type_name=info.type_name;
   boolean is_java=(lang=='java' || lang=='cs');
   int in_class_def=(flags&VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF);
   int verbose=(flags&VSCODEHELPDCLFLAG_VERBOSE);
   int show_class=(flags&VSCODEHELPDCLFLAG_SHOW_CLASS);
   int show_access=(flags&VSCODEHELPDCLFLAG_SHOW_ACCESS);
   int show_inline=(flags&VSCODEHELPDCLFLAG_SHOW_INLINE);
   int show_static=(flags&VSCODEHELPDCLFLAG_SHOW_STATIC);
   _str arguments = (info.arguments!='')? '('info.arguments')':'';
   _str class_sep = (lang=='java' || lang=='cs' || lang=='e' || lang=='d')? '.':'::';
   _str return_type = '';
   _str result = '';
   _str initial_value='';
   _str before_return='';
   _str return_start='';
   _str array_arguments='';
   _str proto='';

   //say("_c_get_decl: type_name="type_name);
   switch (type_name) {
   case 'proc':         // procedure or command
   case 'proto':        // function prototype
   case 'constr':       // class constructor
   case 'destr':        // class destructor
   case 'func':         // function
   case 'procproto':    // Prototype for procedure
   case 'subfunc':      // Nested function or cobol paragraph
   case 'subproc':      // Nested procedure or cobol paragraph
   case 'selector':
      before_return=decl_indent_string;
      if (lang=="phpscript" || lang=="rul") {
         strappend(before_return,"function ");
      }
      if (show_access) {
         if (is_java) {
            switch (tag_flags & VS_TAGFLAG_access) {
            case VS_TAGFLAG_public:
               strappend(before_return,'public ');
               break;
            case VS_TAGFLAG_package:
               //strappend(before_return,'package ');
               // package is default scope for Java
               break;
            case VS_TAGFLAG_protected:
               strappend(before_return,'protected ');
               break;
            case VS_TAGFLAG_private:
               // yes, this can not happen
               strappend(before_return,'private ');
               break;
            }
         } else if (lang=='c' && in_class_def) {
            int c_access_flags = (tag_flags & VS_TAGFLAG_access);
            switch (c_access_flags) {
            case VS_TAGFLAG_public:
            case VS_TAGFLAG_package:
               before_return='';
               strappend(before_return,access_indent_string:+"public:\n");
               if (header_list != null) {
                  // generate comment block
                  int i;
                  for (i=0;i<header_list._length();++i) {
                     strappend(before_return,header_list[i]:+"\n");
                  }
               }
               strappend(before_return,decl_indent_string);
               break;
            case VS_TAGFLAG_protected:
               before_return='';
               strappend(before_return,access_indent_string:+"protected:\n");
               if (header_list != null) {
                  // generate comment block
                  int i;
                  for (i=0;i<header_list._length();++i) {
                     strappend(before_return,header_list[i]:+"\n");
                  }
               }
               strappend(before_return,decl_indent_string);
               break;
            case VS_TAGFLAG_private:
               before_return='';
               // yes, this can not happen
               strappend(before_return,access_indent_string:+"private:\n");
               if (header_list != null) {
                  // generate comment block
                  int i;
                  for (i=0;i<header_list._length();++i) {
                     strappend(before_return,header_list[i]:+"\n");
                  }
               }
               strappend(before_return,decl_indent_string);
               break;
            }
         }
      }
      // other keywords before return type
      if (verbose) {
         if (!in_class_def && show_inline) {
            strappend(before_return,'inline ');
         }
         if (in_class_def && (tag_flags & VS_TAGFLAG_static)) {
            strappend(before_return,'static ');
         }
         if (tag_flags & VS_TAGFLAG_native) {
            strappend(before_return,'native ');
         }
         if (lang=='cs' && (tag_flags & VS_TAGFLAG_virtual)) {
            strappend(before_return,'override ');
         } else if ((tag_flags & VS_TAGFLAG_virtual) && !is_java && in_class_def) {
            strappend(before_return,'virtual ');
         }
         if (tag_flags & VS_TAGFLAG_final) {
            strappend(before_return,'final ');
         }
         if (tag_flags & VS_TAGFLAG_synchronized) {
            strappend(before_return,'synchronized ');
         }
         if (tag_flags & VS_TAGFLAG_transient) {
            strappend(before_return,'transient ');
         }
      } else if (show_static) {
         if (tag_flags & VS_TAGFLAG_static) {
            strappend(before_return,'static ');
         }
      }

      // prepend qualified class name for C++
      if (tag_flags & VS_TAGFLAG_operator) {
         tag_name = 'operator 'tag_name;
      }
      if (!in_class_def && show_class && class_name!='') {
         class_name = stranslate(class_name,class_sep,':');
         class_name = stranslate(class_name,class_sep,'/');
         tag_name   = class_name:+class_sep:+tag_name;
      }

      // compute keywords falling in after the signature
      _str after_sig='';
      if (tag_flags & VS_TAGFLAG_const && !is_java) {
         strappend(after_sig, ' const');
      }
      if (tag_flags & VS_TAGFLAG_volatile && !is_java) {
         strappend(after_sig,' volatile');
      }
      if (verbose) {
         if (tag_flags & VS_TAGFLAG_mutable && !is_java) {
            strappend(before_return,' mutable');
         }
         // do something with 'throw'
         if (info.exceptions != '') {
            if (lang=='idl') {
               strappend(after_sig,' raises('info.exceptions')');
            } else if (lang=='java') {
               strappend(after_sig,' throws 'info.exceptions);
            } else if (lang=='c') {
               strappend(after_sig,' throw('info.exceptions')');
            }
         }
      }
      // finally, insert the line
      return_type = info.return_type;
      _str lastch = last_char(return_type);
      if (lastch!='*' && lastch!='&' && lastch!=' ') {
         return_type = (return_type=='' && (lang=='c' || lang=='e'))? 'int ':return_type:+' ';
      }
      if (info.flags&VS_TAGFLAG_const_destr) {
         return_type='';
      }
      if (last_char(return_type):!=' ') {
         return_type = return_type:+' ';
      }
      if (type_name=='selector') {
         result=before_return:+return_type:+tag_name:+info.arguments:+after_sig;
      } else {
         result=before_return:+return_type:+tag_name:+'('info.arguments')':+after_sig;
      }
      return(result);

   case 'define':       // preprocessor macro definition
      return(decl_indent_string'#define ':+tag_name:+arguments:+' 'info.return_type);

   case 'typedef':      // type definition
      return(decl_indent_string'typedef 'info.return_type:+arguments' 'tag_name);

   case 'gvar':         // global variable declaration
   case 'var':          // member of a class / struct / package
   case 'lvar':         // local variable declaration
   case 'prop':         // property
   case "param":        // function or procedure parameter
   case 'group':        // Container variable
   case 'mixin':        // D language mixin construct
      boolean is_ref=false;
      _str rt = info.return_type;
      if(pos("&",info.return_type) != 0) {
         is_ref = true;
         rt = substr(info.return_type, 1, pos("&",info.return_type)-1);
      }

      if (type_name == "mixin") {
         strappend(before_return,'mixin ');
      }

      if (is_java && type_name == 'var') {
         switch (tag_flags & VS_TAGFLAG_access) {
         case VS_TAGFLAG_public:
            strappend(before_return,'public ');
            break;
         case VS_TAGFLAG_package:
            //strappend(before_return,'package ');
            // package is default scope for Java
            break;
         case VS_TAGFLAG_protected:
            strappend(before_return,'protected ');
            break;
         case VS_TAGFLAG_private:
            // yes, this can not happen
            strappend(before_return,'private ');
            break;
         }
      } 

      not_id_chars := _clex_identifier_notre();
      if ((tag_flags & VS_TAGFLAG_const) && !pos('(^|'not_id_chars')const($|':+not_id_chars')',  rt, 1, 're')) {
         strappend(before_return,'const ');
      }
      if ((tag_flags & VS_TAGFLAG_volatile) && !pos('(^|'not_id_chars')volatile($|':+not_id_chars')',  rt, 1, 're')) {
         strappend(before_return,'volatile ');
      }
      if(tag_flags & VS_TAGFLAG_final) {
         strappend(before_return,'final ');
      }
      if (show_static && (tag_flags & VS_TAGFLAG_static)) {
         strappend(before_return,'static ');
      }

      parse rt with rt '=' initial_value;
      parse rt with return_start '[' array_arguments;
      if (array_arguments!='') {
         array_arguments='['array_arguments;
      }
      if (initial_value!='') {
         initial_value=' = 'initial_value;
      }

      if (!in_class_def && show_class && class_name!='') {
         class_name = stranslate(class_name,class_sep,':');
         class_name = stranslate(class_name,class_sep,'/');
         tag_name   = class_name:+class_sep:+tag_name;
      }

      // ref param
      if(type_name == 'param' && is_ref) {
         if(_LanguageInheritsFrom('e') && array_arguments != "") {
            return(decl_indent_string:+before_return:+return_start' (&' :+ tag_name :+ ')':+ array_arguments);
         } else if(_LanguageInheritsFrom('cs')) {
            return("ref "decl_indent_string:+before_return:+rt' 'tag_name:+initial_value);
         } else {
            return(decl_indent_string:+before_return:+return_start'&'tag_name:+array_arguments:+initial_value);
         }
      }

      if (_LanguageInheritsFrom('cs')) {
         return(decl_indent_string:+before_return:+rt' 'tag_name:+initial_value);
      } else {
         return(decl_indent_string:+before_return:+return_start' 'tag_name:+array_arguments:+initial_value);
      }

   case 'struct':       // structure definition
   case 'enum':         // enumerated type
   case 'class':        // class definition
   case 'union':        // structure / union definition
   case 'interface':    // interface, eg, for Java
   case 'package':      // package / module / namespace
   case 'prog':         // pascal program
   case 'lib':          // pascal library
      if (!in_class_def && show_class && class_name!='') {
         class_name = stranslate(class_name,class_sep,':');
         class_name = stranslate(class_name,class_sep,'/');
         tag_name   = class_name:+class_sep:+tag_name;
      }
      arguments = '';
      if (info.template_args!='') {
         arguments = '<'info.template_args'>';
      } else if (info.arguments!='') {
         arguments = '<'info.arguments'>';
      }
      if (type_name:=='package' && lang=='c') {
         type_name='namespace';
      }
      return(decl_indent_string:+type_name' 'tag_name:+arguments);

   case 'label':        // label
      return(decl_indent_string:+tag_name':');

   case 'import':       // package import or using
      return(decl_indent_string:+'import 'tag_name);

   case 'friend':       // C++ friend relationship
      return(decl_indent_string:+'friend 'tag_name:+arguments);

   case 'include':      // C++ include or Ada with (dependency)
      return(decl_indent_string:+'#include 'tag_name);

   case 'form':         // GUI Form or window
      return(decl_indent_string:+'_form 'tag_name);
   case 'menu':         // GUI Menu
      return(decl_indent_string:+'_menu 'tag_name);
   case 'control':      // GUI Control or Widget
      return(decl_indent_string:+'_control 'tag_name);
   case 'eventtab':     // GUI Event table
      return(decl_indent_string:+'defeventtab 'tag_name);

   case 'const':        // pascal constant
   case "enumc":        // enumeration value
      proto=decl_indent_string;
      if (!in_class_def && show_class && class_name!='') {
         class_name= stranslate(class_name,class_sep,':');
         class_name= stranslate(class_name,class_sep,'/');
         strappend(proto,class_name:+class_sep);
      }
      strappend(proto,info.member_name);
      if (info.return_type!='') {
         strappend(proto," = "info.return_type);
      }
      return(proto);


   case "database":     // SQL/OO Database
   case "table":        // Database Table
   case "column":       // Database Column
   case "index":        // Database index
   case "view":         // Database view
   case "trigger":      // Database trigger
   case "task":         // Ada task
   case "file":         // COBOL file descriptor
   case "cursor":       // Database result set cursor
      return(decl_indent_string:+type_name' 'tag_name);

   case "tag":          // HTML / XML / SGML tag
      return(decl_indent_string:+'&lt;'info.member_name'&lt;');

   default:
      proto=decl_indent_string;
      if (info.return_type!='') {
         strappend(proto,info.return_type' ');
      }
      if (!in_class_def && show_class && class_name!='') {
         class_name= stranslate(class_name,class_sep,':');
         class_name= stranslate(class_name,class_sep,'/');
         strappend(proto,class_name:+class_sep);
      }
      strappend(proto,info.member_name);
      return(proto);
   }
}

void _c_autocomplete_before_replace(AUTO_COMPLETE_INFO &word,
                                    VS_TAG_IDEXP_INFO &idexp_info, 
                                    _str terminationKey="")
{
   // special handling for directory names with trailing file separators
   // in #include statements.
   if ((idexp_info != null) &&
       (idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) &&
       (idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS)) {
      switch (terminationKey) {
      case FILESEP:
      case FILESEP2:
         // if we have a directory name and they typed a file separator, remove it
         lc := last_char(word.insertWord);
         if (lc == FILESEP || lc == FILESEP2) {
            word.insertWord = substr(word.insertWord, 1, length(word.insertWord)-1);
         }
         return;
      default:
         return;
      }
   }

   // special handling for overloaded operators
   if (idexp_info != null && word.symbol != null &&
       (word.symbol.flags & VS_TAGFLAG_operator) &&
       def_c_replace_operators &&
       last_char(idexp_info.prefixexp) == ".") {
      word.insertWord = word.symbol.member_name;
      word.symbol.type_name = "statement";
   }
}

boolean _c_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                      VS_TAG_IDEXP_INFO &idexp_info, 
                                      _str terminationKey="")
{
   // special handling for overloaded operators
   if (idexp_info != null && word.symbol != null &&
       (word.symbol.flags & VS_TAGFLAG_operator) &&
       def_c_replace_operators &&
       last_char(idexp_info.prefixexp) == ".") {
      // delete the '.' charactor
      if (!_clex_is_identifier_char(first_char(word.insertWord))) {
         p_col -= length(word.insertWord)+1;
         _delete_char();
         if (terminationKey == " ") {
            _insert_text(" ");
         }
         p_col += length(word.insertWord);
      }
      // do not double-insert the operator
      if (terminationKey == first_char(word.insertWord)) {
         if (length(word.insertWord) == 1) {
            p_col--;
            _delete_char();
         } else {
            last_event("");
         }
      }
      return true;
   }

   // maybe jump into argument help for a template
   // if option to insert an open paren for functions is enabled
   // and the termination key is space or tab or enter
   // and we aren't in some crazy special case
   if (idexp_info != null && word.symbol != null &&
       (word.symbol.flags & VS_TAGFLAG_template) &&
       word.symbol.template_args != null &&
       word.symbol.template_args != "" &&
       tag_tree_type_is_class(word.symbol.type_name) &&
       (_GetCodehelpFlags() & VSCODEHELPFLAG_INSERT_OPEN_PAREN) &&
       (terminationKey=="" || terminationKey==ENTER) &&
       !(idexp_info.info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) &&
       !(idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) ) {
       
      last_event('<');
      auto_functionhelp_key();
      return false;
   }

   return true;
}

_command int c_identifier_key() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   // send command state straight through
   _str l_event = last_event();
   if (command_state()) {
      keyin(l_event);
      return 0;
   }

   // check that cursor is in symbol/identifier color
   switch (_clex_find(0,'g')) {
   case CFG_WINDOW_TEXT:
   case CFG_PUNCTUATION:
   case CFG_LIBRARY_SYMBOL:
   case CFG_OPERATOR:
   case CFG_USER_DEFINED:
      break;
   default:
      keyin(l_event);
      return 0;
   }

   // check that cursor is in an identifier
   int start_col=0;
   _str word = cur_identifier(start_col);
   if (p_col > 0 && p_col < start_col) {
      left();
      word = cur_identifier(start_col);
      right();
   }
   if (word=='' || p_col < start_col || p_col > start_col+length(word)) {
      keyin(l_event);
      return 0;
   }

   _str newName = '';
   if (l_event == backspace) {
      newName = substr(word, 1, p_col-start_col-1) :+ substr(word, p_col-start_col+1);
   } else if (l_event == del) {
      newName = substr(word, 1, p_col-start_col) :+ substr(word, p_col-start_col+1+1);
   } else {
      newName = substr(word, 1, p_col-start_col) :+ l_event :+ substr(word, p_col-start_col+1);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // are we in a function?
   _str tag_type = '';
   int context_id = tag_current_context();
   while (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, tag_type);
      if (tag_tree_type_is_func(tag_type)) {
         break;
      }
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
   }

   // not a function
   if (context_id <= 0) {
      keyin(l_event);
      return 0;
   }

   // get the start and end of this function
   int function_start_seekpos = 0;
   int function_end_seekpos = 0;
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, function_start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, function_end_seekpos);
   }

   // see if the symbol is a local variable
   _str errorArgs[];
   _str tagname=word;
   int num_matches = context_match_tags(errorArgs, tagname, false, 2, true, true);
   if (num_matches != 1) {
      keyin(l_event);
      return 0;
   }

   tag_get_detail2(VS_TAGDETAIL_match_type, 1, tag_type);
   if (tag_type != 'lvar' && tag_type != 'param') {
      keyin(l_event);
      return 0;
   }

   // get browse information for the tag under the symbol
   struct VS_TAG_BROWSE_INFO cm;
   int status = tag_get_browse_info("", cm);
   if (status < 0) {
      keyin(l_event);
      return 0;
   }

   // find all the references to this tag
   VS_TAG_RETURN_TYPE visited:[];
   int seekPositions[]; seekPositions._makeempty();
   int maxReferences = def_cb_max_references;
   int numReferences = 0;
   tag_match_occurrences_in_file_get_positions(errorArgs, seekPositions,
                                               cm.member_name, p_EmbeddedCaseSensitive,
                                               cm.file_name, cm.line_no,
                                               VS_TAGFILTER_ANYTHING, 
                                               function_start_seekpos, function_end_seekpos,
                                               numReferences, maxReferences, visited);

   if (seekPositions._length() <= 0) {
      keyin(l_event);
      return 0;
   }

   // go through the file backwards
   long orig_pos = _QROffset();
   int j,m = seekPositions._length();
   for (j=m-1; j>=0; --j) {

      // go to the seek position
      status = _GoToROffset(seekPositions[j]);
      if (status < 0) continue;

      _delete_text(length(cm.member_name));
      _insert_text(newName);

      if (seekPositions[j] < orig_pos) {
         orig_pos += (length(newName) - length(word));
      }
   }

   if (l_event == del) {
      ++orig_pos;
   }

   // success
   _GoToROffset(orig_pos);
   return 0;
}

int _in_comment_common() {
   int color=_clex_find(0,'g');
   if (color==CFG_COMMENT) {
      // This code does not work when cursor is inbetween start chars
      // chars of mlcomment. i.e. "/<cursor>*" cursor is inbetween / and *.
      typeless p; save_pos(p);
      int orig_modifyflags=p_ModifyFlags;
      boolean orig_modify=p_modify;
      int orig_line_modify=_lineflags();
      _str line;
      get_line_raw(line);
      int orig_col=p_col;
      int old_TruncateLength=p_TruncateLength;
      p_TruncateLength=0;
      //Add an extra space to next line's replace_line_raw() call to cover 
      //the case of '\' right before the cursor.

      // We have to suspend text callbacks for this buffer. There are cases
      // (DIFFzilla) where these callbacks will cause trouble because they are
      // called and then we will restore the buffer back to its original state.
      _CallbackBufSuspendAll(p_buf_id,1);
      int orig_undo_steps=_SuspendUndo(p_window_id);

      replace_line_raw(expand_tabs(line,1,orig_col-1,'s')' ');
      insert_line_raw(' 'expand_tabs(line,orig_col,-1,'s'));
      p_col=1;
      color=_clex_find(0,'g');
      if (!_delete_line()) {
         up();
      }
      replace_line_raw(line);
      p_TruncateLength=old_TruncateLength;
      p_col=orig_col;
      p_ModifyFlags=orig_modifyflags;
      //Need to restore start position to preserve scroll position (DOB: 03/07/2006)
      restore_pos(p);

      if (isEclipsePlugin()) {
         _eclipse_set_dirty(p_window_id, orig_modify); 
      }
      _lineflags(orig_line_modify,MODIFY_LF);

      // Turn the text callbacks back on
      _CallbackBufSuspendAll(p_buf_id,0);
      _ResumeUndo(p_window_id,orig_undo_steps);
   }
   return color;
}
/**
 * Determines if the cursor is in a comment
 *
 * @param in_ml_comment   If in_ml_comment is true, true is return only if
 *                        the cursor is inside a multi-line comment.  This is
 *                        useful determining if after pressing ENTER (splitting
 *                        the line at the cursor) the cursor will be inside
 *                        a multi-line comment.
 *
 * @return Returns <b>true</b> if cursor is within a comment and
 * <b>p_lexer_name</b> is not "".
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
boolean _in_comment(boolean in_ml_comment=false)
{
   if (p_lexer_name=='') {
      return(0);
   }
   int color=0;
   if (in_ml_comment) {
      color=_in_comment_common();
   } else {
      color=_clex_find(0,'g');
   }
   return(color==CFG_COMMENT);
}

/**
 * Determines if the cursor is in a string
 *
 * @return Returns <b>true</b> if cursor is within a string and
 * <b>p_lexer_name</b> is not "".
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
boolean _in_string()
{
   if (p_lexer_name=='') {
      return false;
   }
   int color = _clex_find(0,'g');
   return(color==CFG_STRING);
}

/**
 * Determines if the cursor is in a function body
 * or statement scope.
 */
boolean _in_function_scope()
{
   // update the context and find the element under the cursor
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id=tag_current_context();
   if (context_id <= 0) {
      return false;
   }

   // check for function or statement
   _str tag_type='';
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,tag_type);
   if (!tag_tree_type_is_func(tag_type) && !tag_tree_type_is_statement(tag_type)) {
      return false;
   }

   // check for before scope seek position
   int start_seekpos=0;
   int scope_seekpos=0;
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,context_id,start_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos,context_id,scope_seekpos);
   if (scope_seekpos > start_seekpos && _QROffset() < scope_seekpos) {
      return false;
   }

   // not in a function body or statement
   return true;
}

/** 
 * Use this to determine if the cursor is within the scope of a 
 * class. For example, with 
 *  
 * class Person { 
 * } 
 *  
 * the method will return false if the cursor is between the 'c'
 * and the '{'.  If the cursor is between the braces, then the 
 * function will return true. 
 */
boolean _in_class_scope()
{
   // update the context and find the element under the cursor
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id=tag_current_context();
   if (context_id <= 0) {
      return false;
   }

   // check for class
   _str tag_type='';
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,tag_type);
   if (!tag_tree_type_is_class(tag_type)) {
      return false;
   }

   // check for before scope seek position
   int start_seekpos=0;
   int scope_seekpos=0;
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,context_id,start_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos,context_id,scope_seekpos);
   if (scope_seekpos > start_seekpos && _QROffset() > scope_seekpos) {
      return true;
   }

   // not in a function body or statement
   return false;
}

//////////////////////////////////////////////////////////////////////////
_str gDoxygenCommandsAtsign[]= {
   '@a', '@addindex', '@addtogroup', '@anchor', '@arg',  '@attention', '@author',
   '@b', '@brief', '@bug', '@c', '@callgraph', '@callergraph', '@category', '@class',
   '@code', '@cond', '@copydoc', '@date', '@def', '@defgroup', '@deprecated', '@details',
   '@dir', '@dontinclude', '@dot', '@dotfile', '@e', '@else', '@elseif', '@em',
   '@endcode', '@endcond', '@enddot', '@endhtmlonly', '@endif', '@endlatexonly',
   '@endlink', '@endmanonly', '@endmsc', '@endverbatim', '@endxmlonly', '@enum',
   '@example', '@exception', '@f$', '@f[', '@f]', '@file', '@fn', '@hideinitializer',
   '@htmlinclude', '@htmlonly', '@if', '@ifnot', '@image', '@include', '@includelineno',
   '@ingroup', '@internal', '@invariant', '@interface', '@latexonly', '@li', '@line',
   '@link', '@mainpage', '@manonly', '@msc', '@n', '@name', '@namespace', '@nosubgrouping',
   '@note', '@overload', '@p', '@package', '@page', '@par', '@paragraph', '@param',
   '@post', '@pre', '@private', '@privatesection', '@property', '@protected',
   '@protectedsection', '@protocol', '@public', '@publicsection', '@ref', '@relates',
   '@relatesalso', '@remarks', '@return', '@retval', '@sa', '@section', '@see',
   '@showinitializer', '@since', '@skip', '@skipline', '@struct', '@subpage', '@subsection',
   '@subsubsection', '@test', '@throw', '@todo', '@typedef', '@union', '@until',
   '@var', '@verbatim', '@verbinclude', '@version', '@warning', '@weakgroup', '@xmlonly',
   '@xrefitem', '@$', '@@', '@@', '@&', '@~', '@<', '@>', '@#', '@%'
};
_str gJavadocTagList[]= {
   '@author',
   '@version',
   '@param',
   '@return',
   '@example',
   '@exception',
   '@see',
   '@since',
   '@deprecated',
   '@serial',
   '@serialField',
   '@serialData',
   '@throws'
};
_command void c_atsign() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()) {
      call_root_key(last_event());
      return;
   }
   if ( !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS)) {
      keyin('@');
      return;
   }
   _str line;
   //if (_in_comment() && _inJavadoc()) {
   if (_inDocComment()) {
      get_line(line);
      //if (line=='*' && p_col==_text_colc()+1 ) {
      if (onDocCommentBlankLine(line)) {
         keyin(last_event());
         _do_list_members(true,true,gDoxygenCommandsAtsign);
         return;
      }
   } else if (_LanguageInheritsFrom('java') || _LanguageInheritsFrom("m") || _LanguageInheritsFrom("c")) {
      get_line(line);
      if (line=='' && p_col==_text_colc()+1 ) {
         keyin(last_event());
         _do_list_members(true,true);
         return;
      }
   }
   call_root_key(last_event());
}
_str gDoxygenCommandsBackslash[]= {
   '\a', '\addindex', '\addtogroup', '\anchor', '\arg',  '\attention', '\author',
   '\b', '\brief', '\bug', '\c', '\callgraph', '\callergraph', '\category', '\class',
   '\code', '\cond', '\copydoc', '\date', '\def', '\defgroup', '\deprecated', '\details',
   '\dir', '\dontinclude', '\dot', '\dotfile', '\e', '\else', '\elseif', '\em',
   '\endcode', '\endcond', '\enddot', '\endhtmlonly', '\endif', '\endlatexonly',
   '\endlink', '\endmanonly', '\endmsc', '\endverbatim', '\endxmlonly', '\enum',
   '\example', '\exception', '\f$', '\f[', '\f]', '\file', '\fn', '\hideinitializer',
   '\htmlinclude', '\htmlonly', '\if', '\ifnot', '\image', '\include', '\includelineno',
   '\ingroup', '\internal', '\invariant', '\interface', '\latexonly', '\li', '\line',
   '\link', '\mainpage', '\manonly', '\msc', '\n', '\name', '\namespace', '\nosubgrouping',
   '\note', '\overload', '\p', '\package', '\page', '\par', '\paragraph', '\param',
   '\post', '\pre', '\private', '\privatesection', '\property', '\protected',
   '\protectedsection', '\protocol', '\public', '\publicsection', '\ref', '\relates',
   '\relatesalso', '\remarks', '\return', '\retval', '\sa', '\section', '\see',
   '\showinitializer', '\since', '\skip', '\skipline', '\struct', '\subpage', '\subsection',
   '\subsubsection', '\test', '\throw', '\todo', '\typedef', '\union', '\until',
   '\var', '\verbatim', '\verbinclude', '\version', '\warning', '\weakgroup', '\xmlonly',
   '\xrefitem', '\$', '\@', '\\', '\&', '\~', '\<', '\>', '\#', '\%'
};

_command void c_backslash() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()) {
      call_root_key(last_event());
      return;
   }
   if ( !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS)) {
      keyin('\');
      return;
   }
   _str line;
   if (_inDocComment()) {
      get_line(line);
      //if (line=='*' && p_col==_text_colc()+1 ) {
      if (onDocCommentBlankLine(line)) {
         keyin(last_event());
         _do_list_members(true,true,gDoxygenCommandsBackslash);
         return;
      }
   }
   call_root_key(last_event());
}

//////////////////////////////////////////////////////////////////////////
/** 
 * This function is NOT complete.  It needs to support ANY 
 * tag type and support locals. That way the %\N alias escape 
 * sequence can work better. 
 *  
 * Is the location under the cursor a reasonable place for an
 * javaDoc or xmlDoc style comment?
 */
boolean _is_line_before_decl()
{
   // update the current context
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // what is under the cursor?
   type_name := '';
   context_id := tag_current_context();
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
      if (tag_tree_type_is_func(type_name) || 
          tag_tree_type_is_statement(type_name)) {
         return false;
      }
   }

   // search for next non-blank then look up current context
   save_pos(auto p);
   _clex_skip_blanks("h");
   context_id = tag_current_context();
   restore_pos(p);

   // if simple lookup failed, then find the next context item?
   if (context_id <= 0) {
      context_id = tag_nearest_context(p_RLine,VS_TAGFILTER_ANYTHING,true);
   }
   if (context_id <= 0) {
      return false;
   }

   // the next item must be a function, class, namespace, or variable
   tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   if (!tag_tree_type_is_func(type_name) && 
       !tag_tree_type_is_class(type_name) && 
       !tag_tree_type_is_package(type_name) &&
       !tag_tree_type_is_data(type_name)) {
      return false;
   }

   // finally, the next item must start on the next line
   int context_line=0;
   tag_get_detail2(VS_TAGDETAIL_context_line, context_id, context_line);
   if (context_line != p_RLine+1) {
      if (!def_allow_blank_lines_before_decl) {
         return false;
      } else {
         // we are going to allow some blank lines
         save_pos(p);
         p_RLine++;

         foundNonBlank := false;
         while (p_RLine < context_line) {
            // get the next line
            get_line(auto line);

            // is it blank?
            if (line != '') {
               foundNonBlank = true;
               break;
            }
            if (down()) break;
         }
         restore_pos(p);

         // one of those lines was not blank...
         if (foundNonBlank) {
            return false;
         }
      }
   }

   // the next line is a func, class, namespace, or variable
   return true;
}

//////////////////////////////////////////////////////////////////////////

/**
 * Check if we are sitting on an else or catch statement.
 * This is used by dynamic surround (see surround.e).
 */
boolean _c_is_continued_statement()
{
   get_line(auto line);
   if ( pos('^[ \t]#[}]?[ \t]*(else|catch)([ \t{(]|$)', line, 1, 'r')) {
      return true;
   }

   if ( line == '}' ) {
      save_pos(auto p);
      down();
      get_line(line);
      if ( pos('^[ \t]#(else|catch)([ \t{(]|$)', line, 1, 'r')) {
         restore_pos(p);
         return true;
      }
      restore_pos(p);
   }

   return false;
}

//////////////////////////////////////////////////////////////////////////
static _str gCancelledCompiler='';
void _prjopen_c_util()
{
   gCancelledCompiler='';
}

/**
 * If we do not already have a 'C' language tag file, create one
 * under certain circumstances.
 */
int _c_MaybeBuildTagFile(int &tfindex)
{
   // Find the active "C" compiler tag file
   _str compiler_name = refactor_get_active_config_name(_ProjectHandle());
   //say("_c_MaybeBuildTagFile: name="compiler_name);
   if (compiler_name != '' && compiler_name != gCancelledCompiler) {
      // put together the file name
      _str compilerTagFile=_tagfiles_path():+compiler_name:+TAG_FILE_EXT;
      if (!file_exists(compilerTagFile)) {
         useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
         int status = refactor_build_compiler_tagfile(compiler_name, 'cpp', false, useThread);
         if (status == COMMAND_CANCELLED_RC) {
            message("You pressed cancel.  You will have to build the tag file manually.");
            gCancelledCompiler = compiler_name;
         } else if (status == 0) {
            gCancelledCompiler = '';
         }
      }
   }
   
   // maybe we can recycle tag file(s)
   _str tagfilename='';
#if __UNIX__
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,"c","ucpp")) {
      return(0);
   }
#else
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,"c","cpp") &&
       ext_MaybeRecycleTagFile(tfindex,tagfilename,"c","tornado":+def_tornado_version) &&
       ext_MaybeRecycleTagFile(tfindex,tagfilename,"c","prismp")) {
      return(0);
   }
   AddTornadoTagFile();
   AddPrismPlusTagFile();
#endif
   // recycling didn't work, might have to build tag files
   tfindex=0;
   return(0);
}
#if !__UNIX__
int def_vtg_tornado=1;
int def_vtg_prismplus=1;
static int AddPrismPlusTagFile()
{
   if (machine()!='WINDOWS'|| !def_vtg_prismplus) {
      return(1);
   }
   path := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Integrated Systems, Inc.\\pRISM+","PPC","ISI_PRISM_DIR");
   if (path=="") {
      path = _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Integrated Systems, Inc.\\pRISM+","MIPS","ISI_PRISM_DIR");
      if (path=="") {
         path = _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Integrated Systems, Inc.\\pRISM+","x86","ISI_PRISM_DIR");
      }
   }
   if (path=="") {
      return(1);
   }
   if (last_char(path)!=FILESEP) {
      path=path:+FILESEP;
   }
   if (file_match(path'+d +x',1) == '') {
      return(1);
   }


   _str ext='c';
   cTagFile := LanguageSettings.getTagFileList('c');
   // IF the user does not have an extension specific tag file for Slick-C
   int status=0;
   _str name_part='prismp.vtg';
   _str tagfilename=absolute(_tagfiles_path():+name_part);
   //say('name_info='name_info(tfindex));
   if ( !pos(name_part,cTagFile,1,_fpos_case) ||
       tag_read_db(tagfilename)==FILE_NOT_FOUND_RC) {
      tag_close_db(tagfilename);
      //status=shell('maketags -n "Tornado Libraries" -t -o 'maybe_quote_filename(tagfilename)' 'maybe_quote_filename(path:+'*.c')' 'maybe_quote_filename(path:+'*.h'));
      useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
      _str bg_opt = (useThread)? '-b':'';
      status=shell('maketags 'bg_opt' -n "pRISM+ Libraries" -t -o 'maybe_quote_filename(tagfilename)' 'maybe_quote_filename(path:+'*.h'));
      LanguageSettings.setTagFileList('c', tagfilename, true);
   }
   return(status);
}
static int AddTornadoTagFile()
{
   if (machine()!='WINDOWS' || !def_vtg_tornado) {
      return(1);
   }
   _str command=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\TornadoWorkspaceType\\shell\\open\\command","");
   if (command=='' || def_tornado_version==2) {
      command=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\TornadoSourceType\\shell\\open\\command","");
   }
   if (command=="") {
      return(1);
   }
   // command has --> H:\Tornado\host\X86-WI~1\bin\tornado.exe "%1"
   command=parse_file(command);
   _str path=strip_names(command,4);
   if (file_match(maybe_quote_filename(path)' +d +x',1) == '') {
      return(1);
   }

   cTagFiles := LanguageSettings.getTagFileList('c');
   // IF the user does not have an extension specific tag file for Slick-C
   int status=0;
   _str name_part='tornado':+def_tornado_version:+'.vtg';
   _str tagfilename=absolute(_tagfiles_path():+name_part);
   //say('name_info='name_info(tfindex));
   if (!pos(name_part,cTagFiles,1,_fpos_case) ||
       tag_read_db(tagfilename)==FILE_NOT_FOUND_RC) {
      tag_close_db(tagfilename);
      useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
      _str bg_opt = (useThread)? '-b':'';
      status=shell('maketags 'bg_opt' -n "Tornado Libraries" -t -o 'maybe_quote_filename(tagfilename)' 'maybe_quote_filename(path:+'*.h'));
      LanguageSettings.setTagFileList('c', tagfilename, true);
   }
   return(status);
}
int AddDotNetTagFile()
{
   if (machine()!='WINDOWS') {
      return(1);
   }
   _str ext='c';
   cTagFile := LanguageSettings.getTagFileList('c');
   // IF the user does not have an extension specific tag file for Slick-C
   int status=0;
   _str name_part='dotnet.vtg';
   _str tagfilename=absolute(_tagfiles_path():+name_part);
   if (pos(name_part,cTagFile,1,_fpos_case) == 0) {
      status = tag_read_db(tagfilename);
      if (status == FILE_NOT_FOUND_RC) {
         // show a toast message that the dot net tag files haven't been tagged
         _str msg = 'The .NET libraries have not been tagged yet.<br>To do that now, click <a href="<<cmd gui-make-tags">here</a>.';
         _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_SYMBOL_NOT_FOUND, msg, "Tagging", 1);
      } else {
         // close the database
         tag_close_db(tagfilename,true);
         // add the vtg file to the language
         LanguageSettings.setTagFileList('c', tagfilename, true);
      }
   }
   return(status);
}
#endif

/**
 * Check if the system or user C++ preprocessing header files
 * were just saved, if so, force the tagging engine to reload them
 */
void _cbsave_cparse(...)
{
   _str sys_cpp_file = _c_sys_ppedit_path();
   _str usr_cpp_file = _c_user_ppedit_path();
   if (file_eq(sys_cpp_file,p_buf_name) || file_eq(usr_cpp_file,p_buf_name)) {
      _actapp_cparse();
   }
}
void _actapp_cparse(_str arg1="")
{
   int index=find_index('cpp_reset',COMMAND_TYPE|PROC_TYPE);
   if (index_callable(index)) {
      call_index(index);
   }
}


/**
 * Callback for determining if the current line is the first line
 * of a block statement.
 * <p>
 * Note, this same callback is also called for
 * C#, Java, JavaScript, Awk, Tcl, Slick-C&reg;, ActionScript, PHP, and CFScript.
 * </p>
 * 
 * @param first_line
 * @param last_line
 * @param num_first_lines
 * @param num_last_lines
 * 
 * @return boolean
 */
boolean _c_find_surround_lines(int &first_line, int &last_line, 
                               int &num_first_lines, int &num_last_lines,
                               boolean &indent_change, 
                               boolean ignoreContinuedStatements=false) 
{
   indent_change = true;

   // see if this is a block statement
   status := 0;
   line := "";
   get_line(line);
   if (pos('^( |\t)*\#(if|ifdef|region|ifndef)', line, 1, 'R')) {
      // these two are easy
      first_line = p_RLine;
      num_last_lines = 1;

      // look for the matching # statement
      first_non_blank();
      if(!_find_matching_paren(MAXINT, true)) {
         get_line(line);
         // make sure it's not an else statement or something silly
         if (pos('^( |\t)*\#(endif|endregion)', line, 1, 'R')) {
            last_line = p_RLine;

            // check the tagging to figure out num_first_lines
            int startLine = 0, scope = 0;
            _UpdateContext(true, false, VS_UPDATEFLAG_context|VS_UPDATEFLAG_statement);

            // make sure that the context doesn't get modified by a background thread.
            se.tags.TaggingGuard sentry;
            sentry.lockContext(false);

            tag := tag_current_statement();
            tag_get_detail2(VS_TAGDETAIL_context_start_linenum, tag, startLine);
            tag_get_detail2(VS_TAGDETAIL_context_scope_linenum, tag, scope);
            num_first_lines = scope - startLine + 1;

            // indent doesn't change based on preprocessing
            indent_change = false;

            // return true - we found it!
            return true;
         }
      }
      // something went wrong here, so just return false
      return false;
   }
   if ( line == "{" ) {

      // this could be the first line of the block
      first_line = p_RLine;
      num_first_lines = 1;

      // check if they have type 2 or type 3 braces
      if (first_line > 1) {
         first_non_blank(); 
         up(); _end_line();
         tk := c_prev_sym();
         first_non_blank(); 
         if (tk == ')' && _clex_find(0, 'g') == CFG_KEYWORD && 
             !ignoreContinuedStatements &&
             _c_find_surround_lines(first_line, last_line, 
                                    num_first_lines, num_last_lines, 
                                    indent_change, false)) {
            return true;
         }
         p_RLine = first_line;
      }

      // find the end of the brace block
      first_non_blank();
      status = find_matching_paren(true);
      if (status) {
         return false;
      }

      // see if we just have brace sitting alone on the end line,
      // or a brace with a superfluous semicolon
      get_line(line);
      if (line == "}" || line == "};") {
         // calculate the number of trailing lines
         last_line = p_RLine;
         num_last_lines = 1;
         return true;
      }

      return false;
   }

   // make sure that the line starts with a statement keyword 
   first_non_blank();
   if (_clex_find(0, 'g') != CFG_KEYWORD) {
      return false;
   }

   // see if we recognize the statement they are trying to unsurround
   have_expr := false;
   start_col := 0;
   word := cur_identifier(start_col);
   switch (word) {
   case 'if':
   case 'while':
   case 'for':
   case 'using':
   case 'switch':
   case 'foreach':
   case 'foreach_reverse':
      have_expr = true;
      break;
   case 'do':
   case 'loop':
   case 'try':
   case 'else':
      have_expr = false;
      break;
   default:
      return false;
   }

   // this is good, we have the first line of a statement
   first_line = p_RLine;
   p_col+=length(word);

   // check for "else if" expression
   tk := '';
   if (word == "else") {
      tk = c_next_sym();
      if (tk == "{") {
         tk = c_prev_sym();
      } else if (tk==TK_ID && c_sym_gtkinfo() == "if") {
         have_expr = true;
      }
   }

   // if this statement is followed by a conditional expression
   if (have_expr) {

      // get the next token from this position, it better be a paren
      // Tcl is a special case, it uses braces for conditions
      tk = c_next_sym();
      if (p_LangId=='tcl') {
         if (tk != '{') {
            return false;
         }
      } else {
         if (tk != '(') {
            return false;
         }
      }

      // find the end of the conditional expression
      // move left one column to get on the outer paren
      p_col--;
      status = find_matching_paren(true);
      if (status) {
         return false;
      }

      // skip the close paren (brace for Tcl)
      p_col++;
   }

   // the next token better be an open brace
   tk = c_next_sym();
   if (tk != '{') {
      return false;
   }

   // check that we are at the end of the line (not counting comments)
   orig_line := p_RLine;
   save_pos(auto p);
   _clex_skip_blanks('h');
   if (p_RLine==orig_line && !at_end_of_line()) {
      return false;
   }

   // ok, now we know how many lines the statement starts with
   restore_pos(p);
   num_first_lines = p_RLine - first_line + 1;

   // find the matching close brace
   status = find_matching_paren(true);
   if (status) {
      return false;
   }

   // the close brace is our initial guess at the last line
   last_line = p_RLine;

   // get the next token
   p_col++;
   save_pos(p);
   tk = c_next_sym();

   // special case for do { ... } while (condition);
   if (word == 'do') {

      // check that we have the 'while' keyword next
      if (tk != 1 || c_sym_gtkinfo()!='while') {
         return false;
      }

      // next we should find the open paren
      tk = c_next_sym();
      if (tk != '(') {
         return false;
      }

      // find the end of the conditional expression
      status = find_matching_paren(true);
      if (status) {
         return false;
      }

      // the next token should be the semicolon
      p_col++;
      tk = c_next_sym();
      if (tk != ';') {
         return false;
      }

   } else {

      // can't unsurround a try with catches
      while (c_sym_gtkinfo()=='catch') {

         // next token must be an open paren
         tk = c_next_sym();
         if (tk != '(') {
            return false;
         }

         // find the end of the catch expression
         status = find_matching_paren(true);
         if (status) {
            return false;
         }

         // next token must be an open brace
         p_col++;
         tk = c_next_sym();
         if (tk != '{') {
            return false;
         }

         // and the immediate next token must be a close brace
         tk = c_next_sym();
         if (tk != '}') {
            return false;
         }

         // the close brace is our initial guess at the last line
         save_pos(p);

         // check for 'finally'
         tk = c_next_sym();
      }

      // only can handle and else or finally if it's statement block is empty
      if (!ignoreContinuedStatements && (c_sym_gtkinfo()=='else' || c_sym_gtkinfo()=='finally')) {

         // next token must be an open brace
         tk = c_next_sym();
         if (tk != '{') {
            return false;
         }

         // and the immediate next token must be a close brace
         tk = c_next_sym();
         if (tk != '}') {
            return false;
         }
      } else {

         // didn't find an else or finally, so go back to close brace
         restore_pos(p);
      }
   }

   // calculate the number of trailing lines
   num_last_lines = p_RLine - last_line + 1;
   last_line = p_RLine;

   // check that we are at the end of the line, excluding comments
   save_pos(p);
   _clex_skip_blanks('h');
   if (p_RLine==last_line && !at_end_of_line()) {
      return false;
   }

   // that's all folks
   return true;
}

boolean _e_find_surround_lines(int &first_line, int &last_line, 
                               int &num_first_lines, int &num_last_lines, 
                               boolean &indent_change, 
                               boolean ignoreContinuedStatements=false) 
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
boolean _cs_find_surround_lines(int &first_line, int &last_line, 
                                int &num_first_lines, int &num_last_lines, 
                                boolean &indent_change, 
                                boolean ignoreContinuedStatements=false) 
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
boolean _java_find_surround_lines(int &first_line, int &last_line, 
                                  int &num_first_lines, int &num_last_lines, 
                                  boolean &indent_change, 
                                  boolean ignoreContinuedStatements=false) 
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
boolean _awk_find_surround_lines(int &first_line, int &last_line, 
                                 int &num_first_lines, int &num_last_lines, 
                                 boolean &indent_change, 
                                 boolean ignoreContinuedStatements=false) 
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
boolean _tcl_find_surround_lines(int &first_line, int &last_line, 
                                 int &num_first_lines, int &num_last_lines, 
                                 boolean &indent_change, 
                                 boolean ignoreContinuedStatements=false) 
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
boolean _pl_find_surround_lines(int &first_line, int &last_line, 
                                int &num_first_lines, int &num_last_lines, 
                                boolean &indent_change, 
                                boolean ignoreContinuedStatements=false) 
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
boolean _as_find_surround_lines(int &first_line, int &last_line, 
                                int &num_first_lines, int &num_last_lines, 
                                boolean &indent_change, 
                                boolean ignoreContinuedStatements=false) 
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change);
}
boolean _cfscript_find_surround_lines(int &first_line, int &last_line, 
                                      int &num_first_lines, int &num_last_lines, 
                                      boolean &indent_change, 
                                      boolean ignoreContinuedStatements=false) 
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
boolean _phpscript_find_surround_lines(int &first_line, int &last_line, 
                                       int &num_first_lines, int &num_last_lines, 
                                       boolean &indent_change, 
                                       boolean ignoreContinuedStatements=false) 
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}

