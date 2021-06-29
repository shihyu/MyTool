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
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "autocomplete.e"
#import "c.e"
#import "cbrowser.e"
#import "cidexpr.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "commentformat.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "files.e"
#import "groovy.e"
#import "listproc.e"
#import "main.e"
#import "notifications.e"
#import "pmatch.e"
#import "ppedit.e"
#import "pushtag.e"
#import "refactor.e"
#import "setupext.e"
#import "slickc.e"
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
   "c" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "bool"                   => ":bool:int:long:",
      "byte"                   => ":byte:signed byte:",
      "char"                   => ":char:signed char:",
      "signed char"            => ":char:signed char:",
      "unsigned char"          => ":char:unsigned char:char8_t:",
      "char8_t"                => ":char:unsigned char:char8_t:",
      "char16_t"               => ":char16_t:char8_t:unsigned short:unsigned short int:",
      "char32_t"               => ":char32_t:char16_t:char8_t:char:wchar_t:unsigned:unsigned int:",
      "wchar_t"                => ":char32_t:char16_t:char8_t:char:wchar_t:unsigned:unsigned int:",
      "float"                  => ":float:",
      "double"                 => ":double:float:",
      "long double"            => ":double:float:long double:",
      "short"                  => ":short:signed short:short int:signed short int:",
      "short int"              => ":short:signed short:short int:signed short int:",
      "signed short"           => ":short:signed short:short int:signed short int:",
      "signed short int"       => ":short:signed short:short int:signed short int:",
      "unsigned short"         => ":unsigned short:unsigned short int:",
      "unsigned short int"     => ":unsigned short:unsigned short int:",
      "int"                    => ":bool:enum:short:int:signed int:signed:intptr_t:ssize_t:",
      "signed"                 => ":int:signed int:signed:intptr_t:ssize_t:",
      "signed int"             => ":int:signed:signed int:intptr_t:ssize_t:",
      "unsigned"               => ":unsigned int:unsigned short:unsigned:size_t:",
      "unsigned int"           => ":unsigned int:unsigned short:unsigned:size_t:",
      "long"                   => ":long:signed long:long int:signed long int:ssize_t:",
      "long int"               => ":long:signed long:long int:signed long int:ssize_t:",
      "signed long"            => ":long:signed long:long int:signed long int:ssize_t:",
      "signed long int"        => ":long:signed long:long int:signed long int:ssize_t:",
      "unsigned long"          => ":unsigned long:unsigned int:unsigned long int:size_t:",
      "unsigned long int"      => ":unsigned long:unsigned int:unsigned long int:size_t:",
      "long long"              => ":long:long int:signed long int:long long:long long int:signed long long:signed long long int:ssize_t:",
      "long long int"          => ":long:long int:signed long int:long long:long long int:signed long long:signed long long int:ssize_t:",
      "signed long long"       => ":long:long int:signed long int:long long:long long int:signed long long:signed long long int:ssize_t:",
      "signed long long int"   => ":long:long int:signed long int:long long:long long int:signed long long:signed long long int:ssize_t:",
      "unsigned long long"     => ":unsigned long:unsigned long int:unsigned long long:unsigned long long int:size_t:",
      "unsigned long long int" => ":unsigned long:unsigned long int:unsigned long long:unsigned long long int:size_t:",
      "size_t"                 => ":unsigned:unsigned int:unsigned long:unsigned long int:unsigned long long:unsigned long long int:size_t:ssize_t:intptr_t:",
      "ssize_t"                => ":int:signed:signed int:long:long int:signed long:signed long int:long long:long long int:signed long long:signed long long int:ssize_t:size_t:intptr_t:",
      "intptr_t"               => ":int:signed:signed int:long:long int:signed long:signed long int:long long:long long int:signed long long:signed long long int:ssize_t:size_t:intptr_t:",
   },

   // D language builtin types
   "d" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "bool"               => ":bool:",
      "byte"               => ":byte:",
      "ubyte"              => ":ubyte:",
      "short"              => ":short:byte:int:",
      "ushort"             => ":ushort:ubyte:int:",
      "int"                => ":bool:byte:ubyte:short:int:ushort:char:wchar:dchar:",
      "uint"               => ":ubyte:ushort:uint:char:wchar:dchar",
      "long"               => ":long:short:byte:int:",
      "ulong"              => ":ulong:ushort:ubyte:uint:",
      "char"               => ":char:int:",
      "wchar"              => ":wchar:int:",
      "dchar"              => ":dchar:int:",
      "float"              => ":float:",
      "double"             => ":double:float:",
      "real"               => ":real:",
      "ifloat"             => ":ifloat:",
      "idouble"            => ":idouble:ifloat:",
      "ireal"              => ":ireal:",
      "cfloat"             => ":cfloat:idouble:double:",
      "cdouble"            => ":cdouble:cfloat:idouble:double:",
      "creal"              => ":creal:ireal:real:",
      "void"               => ":void:",
   },

   // Slick-C builtin types
   "e" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "_str"               => "*:_str:",
      "bigfloat"           => ":float:bigfloat:",
      "bigint"             => ":int:bigint:",
      "bigstring"          => ":_str:bigstring:",
      "boolean"            => ":bool:boolean:",
      "bool"               => ":bool:boolean:",
      "double"             => ":double:float:",
      "float"              => ":float:",
      "int"                => ":int:short:",
      "long"               => ":int:long:short:",
      "short"              => ":short:",
      "typeless"           => "*:_str:bigfloat:bigint:bigstring:bool:boolean:double:float:int:long:short:typeless:unsigned:unsigned short:unsigned int:unsigned long:",
      "unsigned short"     => ":unsigned short:",
      "unsigned int"       => ":unsigned int:unsigned short:",
      "unsigned long"      => ":unsigned long:unsigned int:",
      "unsigned"           => ":unsigned:",
   },

   // Java builtin types
   "java" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "boolean"            => ":boolean:",
      "byte"               => ":byte:",
      "char"               => ":char:",
      "double"             => ":double:float:",    // integer types are allowed
      "float"              => ":float:",           // integer types are allowed
      "int"                => ":int:short:",       // byte, char are allowed
      "long"               => ":long:int:short:",  // byte, char are allowed
      "short"              => ":short:byte:",      // char is allowed
   },

   // Kotlin builtin types
   "kotlin" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "boolean"            => ":boolean:",
      "byte"               => ":byte:",
      "char"               => ":char:",
      "double"             => ":double:float:",    // integer types are allowed
      "float"              => ":float:",           // integer types are allowed
      "int"                => ":int:short:",       // byte, char are allowed
      "long"               => ":long:int:short:",  // byte, char are allowed
      "short"              => ":short:byte:",      // char is allowed
   },
   // Kotlin builtin types
   "kotlins" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "boolean"            => ":boolean:",
      "byte"               => ":byte:",
      "char"               => ":char:",
      "double"             => ":double:float:",    // integer types are allowed
      "float"              => ":float:",           // integer types are allowed
      "int"                => ":int:short:",       // byte, char are allowed
      "long"               => ":long:int:short:",  // byte, char are allowed
      "short"              => ":short:byte:",      // char is allowed
   },
   // JavaScript builtin types
   "js" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "boolean"            => ":boolean:",
      "byte"               => ":byte:",
      "char"               => ":char:",
      "double"             => ":double:float:",    // integer types are allowed
      "float"              => ":float:",           // integer types are allowed
      "int"                => ":int:short:",       // byte, char are allowed
      "long"               => ":long:int:short:",  // byte, char are allowed
      "short"              => ":short:byte:",      // char is allowed
   },

   // C# builtin types
   "cs" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "sbyte"              => ":dynamic:char:sbyte:",
      "byte"               => ":dynamic:char:byte:",
      "ubyte"              => ":dynamic:char:ubyte:",
      "short"              => ":dynamic:char:sbyte:byte:short:",
      "ushort"             => ":dynamic:char:ubyte:byte:ushort:",
      "int"                => ":dynamic:char:sbyte:byte:short:ushort:int:",
      "uint"               => ":dynamic:char:ubyte:byte:ushort:uint:",
      "long"               => ":dynamic:char:sbyte:byte:short:ushort:int:uint:long:",
      "ulong"              => ":dynamic:char:ubyte:byte:ushort:uint:ulong:",
      "char"               => ":dynamic:char:",
      "float"              => ":dynamic:char:sbyte:byte:ubyte:short:ushort:int:uint:long:ulong:float:",
      "double"             => ":dynamic:char:sbyte:byte:ubyte:short:ushort:int:uint:long:ulong:float:double:",
      "decimal"            => ":dynamic:char:sbyte:byte:ubyte:short:ushort:int:uint:long:ulong:",
      "object"             => ":dynamic:char:sbyte:byte:ubyte:short:ushort:int:uint:long:ulong:float:double:object:",
      "dynamic"            => ":dynamic:object:string:",
      "string"             => ":dynamic:string:",
   },

   // InstallScript builtin types
   "rul" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "BOOL"               => ":BOOL:",
      "BYREF"              => ":BYREF:",
      "CHAR"               => ":CHAR:",
      "HWND"               => ":HWND:",
      "INT"                => ":INT:SHORT:",
      "LIST"               => ":LIST:",
      "LONG"               => ":LONG:INT:SHORT:",
      "LPSTR"              => ":LPSTR:",
      "NUMBER"             => ":NUMBER:",
      "POINTER"            => ":POINTER:",
      "SHORT"              => ":SHORT:",
      "STRING"             => ":STRING:LPSTR:",
   },

   // Python builtin types
   "py" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "complex"            => "*:complex:float:",
      "float"              => ":float:",
      "long"               => ":long:int:",
      "int"                => ":int:",
      "string"             => "*:string:",
   },

   // this is kind of hokey, PHP is a typeless language, so you
   // really don't have these types to work with at all.
   "phpscript" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "array"              => ":array:",
      "double"             => ":double:real:float:",
      "float"              => ":float:",
      "int"                => ":int:integer:",
      "integer"            => ":int:integer:",
      "object"             => ":object:",
      "real"               => ":double:real:float:",
      "string"             => ":string:",
   },

   // ColdFusion Scripts (CFScript)
   "cfscript" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "cfscript:"  "float"         => ":float:",
      "cfscript:"  "int"           => ":int:",
      "cfscript:"  "Object"        => ":Object:String:",
      "cfscript:"  "String"        => ":String:",
      "cfscript:"  "boolean"       => ":boolean:",
      "cfscript:"  "number"        => ":number:int:",
      "cfscript:"  "datetime"      => ":datetime:",
   },

   // SystemVerilog (sv)
   "systemverilog" => {
      "byte"               => ":byte:shortint:int:longint:integer:time:",
      "shortint"           => ":byte:shortint:int:longint:integer:time:",
      "int"                => ":byte:shortint:int:longint:integer:time:",
      "longint"            => ":byte:shortint:int:longint:integer:time:",
      "integer"            => ":byte:shortint:int:longint:integer:time:",
      "time"               => ":byte:shortint:int:longint:integer:time:",
      "bit"                => ":bit:logic:reg:",
      "logic"              => ":bit:logic:reg:",
      "reg"                => ":bit:logic:reg:",
      "real"               => ":real:shortreal:realtime:",
      "shortreal"          => ":real:shortreal:realtime:",
      "realtime"           => ":real:shortreal:realtime:",
      "supply0"            => ":supply0:",
      "supply1"            => ":supply1:",
      "tri"                => ":tri1:",
      "triand"             => ":triand:",
      "trior"              => ":trior:",
      "tri0"               => ":tri0:",
      "tri1"               => ":tri1:",
      "wire"               => ":wire:",
      "wand"               => ":wand:",
      "wor"                => ":wor:",
      "trireg"             => ":trireg:",
      "string"             => ":string:",
      "event"              => ":event:",
   },

   // Rust (rs)
   "rs" => {
      "bool"               => ":bool:",
      "char"               => ":char:",
      "i8"                 => ":i8:i16:i32:int:i64:isize:i128:u16:u32:uint:u64:usize:u128:",
      "i16"                => ":i16:i32:int:i64:isize:i128:u32:uint:u64:usize:u128:",
      "i32"                => ":i32:int:i64:isize:i128:u64:usize:u128:",
      "int"                => ":i32:int:i64:isize:i128:u64:usize:u128:",
      "i64"                => ":i64:isize:i128:",
      "isize"              => ":i64:isize:i128:",
      "i128"               => ":i128:",
      "u8"                 => ":i16:i32:int:i64:isize:i128:u8:u16:u32:uint:u64:usize:u128:",
      "u16"                => ":i32:int:i64:isize:i128:u16:u32:uint:u64:usize:u128:",
      "u32"                => ":i64:isize:i128:u32:uint:u64:usize:u128:",
      "uint"               => ":i64:isize:i128:u32:uint:u64:usize:u128:",
      "u64"                => ":i128:u64:usize:u128:",
      "usize"              => ":i128:u64:usize:u128:",
      "u128"               => ":u128:",
      "f32"                => ":f32:f64:",
      "f64"                => ":f64:",
      "str"                => ":str:",
   },
};

/**
 * If set to true, when the user selects an operator from
 * list-members, Context Tagging&reg; will attempt to replace
 * the verbose "operator" syntax with the actual operator.
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_c_replace_operators = false;

/**
 * If set to 'true', support automatically transforming "." to "->" for pointer types in C++ and Slick-C.
 * <p>
 * To modify this setting, go to "Document" > "C/C++ Options..." > "C/C++ Parsing Options"
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_c_auto_dot_to_dash_gt = false;

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
bool def_allow_blank_lines_before_decl = false;

bool do_default_is_builtin_type(_str return_type, bool no_class_types=false)
{
   is_builtin := false;
   index := _FindLanguageCallbackIndex("_%s_is_builtin_type");
   if (index) {
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
bool _c_is_builtin_type(_str return_type, bool no_class_types=false)
{
   // void is a special case, can't assign to this
   if (return_type=="void") {
      return(true);
   }

   lang := _c_get_type_conversion_lang(p_LangId);
   // Do we have this extension on our table (above)?
   if (!_c_type_conversions._indexin(lang)) {
      return(false);
   }
   // Is the return type in the table?
   if (_c_type_conversions:[lang]._indexin(return_type)) {
      // is it a class type?
      if (no_class_types && substr(_c_type_conversions:[lang]:[return_type],1,1)=="*") {
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
bool _c_builtin_assignment_compatible(_str expected_type,
                                         _str candidate_type,
                                         bool candidate_is_pointer)
{
   // if the types match exactly, then always return true,
   // no matter what language, except for 'enum' and 'void'
   if (!candidate_is_pointer && expected_type:==candidate_type &&
       expected_type:!="enum" && expected_type!="void") {
      return(true);
   }

   // special case for 'c', pointers are assignment compatible with bool
   if (_LanguageInheritsFrom("c") && candidate_is_pointer) {
      return(expected_type=="bool");
   }

   // void is a special case, can't assign to this
   if (expected_type=="void" && !candidate_is_pointer) {
      return(false);
   }

   // otherwise, the answer is in the mighty table
   extension := _c_get_type_conversion_lang(p_LangId);
   if (_c_type_conversions._indexin(extension) &&
       _c_type_conversions:[extension]._indexin(expected_type)) {
      allowed_list := _c_type_conversions:[extension]:[expected_type];
      return (pos(":"candidate_type":",allowed_list))? true:false;
   }

   // didn't find a match, assume that it doesn't match
   return(false);
}

/**
 * Looks through the _c_type_conversions table and uses language
 * inherit_from to find the "real" langId for a type 
 */
static _str _c_get_type_conversion_lang(_str lang=p_LangId)
{
   // Do we have this extension on our table (above)?
   // Loop through and anything that if we do not have this extension in the
   // table, get the extension that we inherit from and see if that extension
   // is in the table
   cur_lang := lang;
   for (;;) {
      if (_c_type_conversions._indexin(cur_lang)) {
         break;
      }

      inheritsFrom := LanguageSettings.getLangInheritsFrom(cur_lang);
      if (inheritsFrom == "") {
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
   "java" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "boolean"            => ":java/lang/Boolean:",
      "byte"               => ":java/lang/Byte:",
      "char"               => ":java/lang/Character:",
      "double"             => ":java/lang/Double:",
      "float"              => ":java/lang/Float:",
      "int"                => ":java/lang/Integer:",
      "long"               => ":java/lang/Long:",
      "short"              => ":java/lang/Short:",
   },

   // Kotlin builtin types.
   "kotlin" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "boolean"            => ":kotlin/Boolean:",
      "byte"               => ":kotlin/Byte:",
      "char"               => ":kotlin/Char:",
      "double"             => ":kotlin/Double:",
      "float"              => ":kotlin/Float:",
      "int"                => ":kotlin/Int:",
      "long"               => ":kotlin/Long:",
      "short"              => ":kotlin/Short:",
   },

   "kotlins" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "boolean"            => ":kotlin/Boolean:",
      "byte"               => ":kotlin/Byte:",
      "char"               => ":kotlin/Char:",
      "double"             => ":kotlin/Double:",
      "float"              => ":kotlin/Float:",
      "int"                => ":kotlin/Int:",
      "long"               => ":kotlin/Long:",
      "short"              => ":kotlin/Short:",
   },
   // C# builtin types
   "cs" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "bool"               => ":System/Boolean:",
      "boolean"            => ":System/Boolean:",
      "byte"               => ":System/Byte:",
      "char"               => ":System/Char:",
      "decimal"            => ":System/Decimal:",
      "double"             => ":System/Double:",
      "float"              => ":System/Single:",
      "single"             => ":System/Single:",
      "int"                => ":System/Int32:",
      "integer"            => ":System/Int32:",
      "long"               => ":System/Int64:",
      "short"              => ":System/Int16:",
      "string"             => ":System/String:",
      "ubyte"              => ":System/UInt8:",
      "object"             => ":System/Object:",
      "delegate"           => ":System/Delegate:",
   },

   // D builtin types
   "d" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "bool"               => ":__INTEGRAL_TYPE:",
      "byte"               => ":__INTEGRAL_TYPE:",
      "ubyte"              => ":__INTEGRAL_TYPE:",
      "short"              => ":__INTEGRAL_TYPE:",
      "ushort"             => ":__INTEGRAL_TYPE:",
      "int"                => ":__INTEGRAL_TYPE:",
      "uint"               => ":__INTEGRAL_TYPE:",
      "long"               => ":__INTEGRAL_TYPE:",
      "ulong"              => ":__INTEGRAL_TYPE:",
      "char"               => ":__INTEGRAL_TYPE:",
      "wchar"              => ":__INTEGRAL_TYPE:",
      "dchar"              => ":__INTEGRAL_TYPE:",
      "float"              => ":__FLOATING_POINT_TYPE:",
      "double"             => ":__FLOATING_POINT_TYPE:",
      "real"               => ":__FLOATING_POINT_TYPE:",
      "ifloat"             => ":__IMAGINARY_TYPE:",
      "idouble"            => ":__IMAGINARY_TYPE:",
      "ireal"              => ":__IMAGINARY_TYPE:",
      "cfloat"             => ":__IMAGINARY_TYPE:",
      "cdouble"            => ":__IMAGINARY_TYPE:",
      "creal"              => ":__IMAGINARY_TYPE:",
      "void"               => ":__ANY_TYPE:",
      "enum"               => ":__ENUMERATED_TYPE:",
   },

   // Slick-C builtin types
   "e" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "_str"               => ":_sc_lang_string:",
      "typeless"           => ":_sc_lang_typeless:",
      "_control"           => ":_sc_lang_control:",
      "_form"              => ":_sc_lang_form:",
      "_editor"            => ":_sc_lang_editor:",
      "_text_box"          => ":_sc_lang_text_box:",
      "_check_box"         => ":_sc_lang_check_box:",
      "_command_button"    => ":_sc_lang_command_button:",
      "_radio_button"      => ":_sc_lang_radio_button:",
      "_frame"             => ":_sc_lang_frame:",
      "_label"             => ":_sc_lang_label:",
      "_list_box"          => ":_sc_lang_list_box:",
      "_vscroll_bar"       => ":_sc_lang_vscroll_bar",
      "_hscroll_bar"       => ":_sc_lang_hscroll_bar",
      "_combo_box"         => ":_sc_lang_combo_box",
      "_picture_box"       => ":_sc_lang_picture_box",
      "_image"             => ":_sc_lang_image",
      "_gauge"             => ":_sc_lang_gauge",
      "_spin"              => ":_sc_lang_spin",
      "_sstab"             => ":_sc_lang_sstab",
      "_minihtml"          => ":_sc_lang_minihtml",
      "_tree_view"         => ":_sc_lang_tree_view",
      "_switch"            => ":_sc_lang_switch",
      "_textbrowser"       => ":_sc_lang_textbrowser",
   },

   // Rust builtin types
   "rs" => {
      // EXPECTED TYPE     => CANDIDATE TYPE
      // --------------------------------------------------------------------
      "str"                => ":alloc/str/str:",
      "i8"                 => ":core/num/i8:",
      "i16"                => ":core/num/i16:",
      "i32"                => ":core/num/i32:",
      "i64"                => ":core/num/i64:",
      "i128"               => ":core/num/i128:",
      "u8"                 => ":core/num/u8:",
      "u16"                => ":core/num/u16:",
      "u32"                => ":core/num/u32:",
      "u64"                => ":core/num/u64:",
      "u128"               => ":core/num/u128:",
      "f32"                => ":core/num/f32:",
      "f64"                => ":core/num/f64:",
      "int"                => ":core/num/i32:",
      "bool"               => ":core/bool/bool:",
      "char"               => ":core/char/char:",
      "usize"              => ":core/num/usize:",
      "isize"              => ":core/num/isize:",
   },
};

static _str _e_int_control_names:[] = {
   // forms and tool windows
   "f"                     => "_sc_lang_form",
   "fw"                    => "_sc_lang_form",
   "form"                  => "_sc_lang_form",
   "formwid"               => "_sc_lang_form",
   "form_wid"              => "_sc_lang_form",
   "tw"                    => "_sc_lang_form",
   // window ids
   "w"                     => "_sc_lang_window",
   "wid"                   => "_sc_lang_window",
   // editor window ids
   "e"                     => "_sc_lang_editor",
   "edit"                  => "_sc_lang_editor",
   "edit1"                 => "_sc_lang_editor",
   "editorctlwid"          => "_sc_lang_editor",
   "editorctl_wid"         => "_sc_lang_editor",
   // menus and menu items
   "m"                     => "_sc_lang_menu_item",
   "mi"                    => "_sc_lang_menu_item",
   "menu"                  => "_sc_lang_menu_item",
   "menuitem"              => "_sc_lang_menu_item",
   "menu_item"             => "_sc_lang_menu_item",
   // list box
   "l"                     => "_sc_lang_text_or_list_box",
   "lb"                    => "_sc_lang_text_or_list_box",
   "list"                  => "_sc_lang_text_or_list_box",
   "list1"                 => "_sc_lang_text_or_list_box",
   "listbox"               => "_sc_lang_text_or_list_box",
   "list_box"              => "_sc_lang_text_or_list_box",
   "listwid"               => "_sc_lang_text_or_list_box",
   "list_wid"              => "_sc_lang_text_or_list_box",
   // label
   "label"                 => "_sc_lang_label",
   "label1"                => "_sc_lang_label",
   "labelwid"              => "_sc_lang_label",
   "label_wid"             => "_sc_lang_label",
   // button
   "b"                     => "_sc_lang_command_button",
   "bt"                    => "_sc_lang_command_button",
   "button"                => "_sc_lang_command_button",
   "button_wid"            => "_sc_lang_command_button",
   // generic control
   "c"                     => "_sc_lang_control",
   "i"                     => "_sc_lang_control",
   // check box
   "check"                 => "_sc_lang_check_box",
   "check1"                => "_sc_lang_check_box",
   "checkbox"              => "_sc_lang_check_box",
   "check_wid"             => "_sc_lang_check_box",
   // combo box
   "cb"                    => "_sc_lang_combo_box",
   "combo"                 => "_sc_lang_combo_box",
   "combo1"                => "_sc_lang_combo_box",
   "combobox"              => "_sc_lang_combo_box",
   "combo_box"             => "_sc_lang_combo_box",
   "cbwid"                 => "_sc_lang_combo_box",
   "cb_wid"                => "_sc_lang_combo_box",
   // tab control
   "sst"                   => "_sc_lang_sstab",
   "sstab"                 => "_sc_lang_sstab",
   "sstab1"                => "_sc_lang_sstab",
   "sstabwid"              => "_sc_lang_sstab",
   "sstab_wid"             => "_sc_lang_sstab",
   // tree control
   "t"                     => "_sc_lang_tree_view",
   "tw"                    => "_sc_lang_tree_view",
   "tree"                  => "_sc_lang_tree_view",
   "tree1"                 => "_sc_lang_tree_view",
   "treewid"               => "_sc_lang_tree_view",
   "tree_wid"              => "_sc_lang_tree_view",
};


/**
 * Is the given symbol of integer type and has a name that matches a 
 * common name used for variables that represent Slick-C controls? 
 *
 * @param builtin_type         Expected to be 'int'
 * @param symbol               Name of symbol being testsed
 *
 * @return Slick-C internal type name for context tagging to use for this symbol.
 */
_str _e_get_control_name_type(_str builtin_type, _str symbol)
{
   // check list of common variable names for controls
   if (builtin_type=="int" && _e_int_control_names._indexin(symbol)) {
      return _e_int_control_names:[symbol];
   }
   // didn't find a match, assume that it is not a control
   return "";
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
bool _c_boxing_conversion_allowed(_str expected_type, _str candidate_type, _str langId=null)
{
   // otherwise, the answer is in the mighty table
   if (langId == null) langId = p_LangId;
   if (_c_boxing_conversions._indexin(langId) &&
       _c_boxing_conversions:[langId]._indexin(expected_type)) {
      allowed_list := _c_boxing_conversions:[langId]:[expected_type];
      return (pos(":"candidate_type":",allowed_list))? true:false;
   }

   // check if we are in a language that inherits 
   // from a language with boxing conversions
   foreach ( auto boxingLangId => . in _c_boxing_conversions ) {
      if ( boxingLangId != langId && _LanguageInheritsFrom(boxingLangId, langId) ) {
         return _c_boxing_conversion_allowed(expected_type,candidate_type,boxingLangId);
      }
   }

   // didn't find a match, assume that it doesn't match
   return(false);
}

/**
 * Is there an autoboxing conversion to convert from the candidate
 *
 * @param builtin_type     Built-in type to look for boxing conversion for
 *
 * @return true if assignment compatible, false otherwise
 */
_str _c_get_boxing_conversion(_str builtin_type, _str langId=null)
{
   // otherwise, the answer is in the mighty table
   if (langId == null) langId = p_LangId;
   if (_c_boxing_conversions._indexin(langId) &&
       _c_boxing_conversions:[langId]._indexin(builtin_type)) {
      allowed_list := _c_boxing_conversions:[langId]:[builtin_type];
      parse allowed_list with ":" allowed_list ":";
      return allowed_list;
   }

   // check if we are in a language that inherits 
   // from a language with boxing conversions
   foreach ( auto boxingLangId => . in _c_boxing_conversions ) {
      if ( boxingLangId != langId && _LanguageInheritsFrom(boxingLangId, langId) ) {
         return _c_get_boxing_conversion(builtin_type,boxingLangId);
      }
   }

   // didn't find a match, assume that it doesn't match
   return "";
}

/** 
 * @return 
 * Return 'true' if there is an autoboxing conversion for this language.
 *
 * @param langId      language to check
 */
bool _c_has_boxing_conversion(_str langId)
{
   // otherwise, the answer is in the mighty table
   if (_c_boxing_conversions._indexin(langId)) {
      return true;
   }

   // check if we are in a language that inherits 
   // from a language with boxing conversions
   foreach ( auto boxingLangId => . in _c_boxing_conversions ) {
      if ( boxingLangId != langId && _LanguageInheritsFrom(boxingLangId, langId) ) {
         return true;
      }
   }

   // didn't find a match, assume that it doesn't match
   return false;
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
                         _str tag_name,_str type_name, 
                         SETagFlags tag_flags,
                         _str file_name, int line_no,
                         _str prefixexp,typeless tag_files,
                         int tree_wid, int tree_index,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_c_match_return_type: expected ="rt_expected.return_type " pointer="rt_expected.pointer_count " flags="rt_expected.return_flags " template="rt_expected.istemplate);
      isay(depth, "_c_match_return_type: name="tag_name" candidate="rt_candidate.return_type" pointer="rt_candidate.pointer_count" flags="rt_candidate.return_flags" template="rt_candidate.istemplate);
   }
   // number of matches found
   array_operator := "[]";
   array_object_compatible := false;
   dereference_compatible := true;
   reference_compatible := false;
   insert_tags := false;
   match_count := 0;

   // is this a builtin type?
   expected_is_builtin := false;
   candidate_is_builtin := false;
   if (!rt_expected.istemplate && _c_is_builtin_type(rt_expected.return_type)) {
      expected_is_builtin=true;
      if (_chdebug) {
         isay(depth, "_c_match_return_type: EXPECTED is builtin");
      }
   }
   if (!rt_expected.istemplate && _c_is_builtin_type(rt_candidate.return_type)) {
      candidate_is_builtin=true;
      if (_chdebug) {
         isay(depth, "_c_match_return_type: CANDIDATE is builtin");
      }
   }

   // if one is a template, the other must also be a template class
   if (rt_candidate.istemplate != rt_expected.istemplate) {
      if (rt_expected.istemplate) {
         // expecting an instance of a template class, but got null instead
         if (_LanguageInheritsFrom("java") && rt_candidate.return_type :== "java/lang/Object" && rt_candidate.pointer_count==0 && rt_expected.pointer_count==0 && tag_name:=="anonymous") {
            // can assign null to any template object
         } else if (_LanguageInheritsFrom("cs") && rt_candidate.return_type :== "System/Object" && rt_candidate.pointer_count==0 && rt_expected.pointer_count==0 && tag_name:=="anonymous") {
            // can assign null to any template object
         } else {
            if (_chdebug) {
               isay(depth, "_c_match_return_type: EXPECTING TEMPLATE, MISMATCH");
            }
         }
      } else {
         if (_chdebug) {
            isay(depth, "_c_match_return_type: NOT EXPECTING TEMPLATE, MISMATCH");
         }
         return(0);
      }
   }
   // if these are templates, expect the arguments to match *exactly*
   if (rt_candidate.istemplate==true) {
      typeless i;
      n_expected := n_candidate := 0;
      for (i._makeempty();;) {
         rt_expected.template_args._nextel(i);
         if (i._isempty()) break;
         ++n_expected;
      }
      for (i._makeempty();;) {
         rt_candidate.template_args._nextel(i);
         if (i._isempty()) break;
         if (!rt_expected.template_args._indexin(i)) {
            if (_chdebug) {
               isay(depth, "_c_match_return_type: MISSING TEMPLATE ARG");
            }
            return(0);
         }
         if (rt_candidate.template_args:[i]!=rt_expected.template_args:[i]) {
            if (_chdebug) {
               isay(depth, "_c_match_return_type: MISMATCHED TEMPLATE ARG");
            }
            return(0);
         }
         ++n_candidate;
      }
      if (n_expected!=n_candidate) {
         if (_chdebug) {
            isay(depth, "_c_match_return_type: DIFFERENT NUMBER OF TEMPLATE ARGS");
         }
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
         if (_chdebug) {
            isay(depth, "_c_match_return_type: CAN NOT ASSIGN AN ARRAY TO A HASH TABLE");
         }
         return(0);  // can not assign an array to a hash table
      }
   }
   if ((rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY) &&
       (!(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY))) {
      if (_chdebug) {
         //isay(depth, "_c_match_return_type: CONST");
      }
      //return(0);  // will not try to violate const members
   }
   if ((rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY) &&
       (!(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY))) {
      if (_chdebug) {
         isay(depth, "_c_match_return_type: VOLATILE");
      }
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
   tag_get_info_from_return_type(rt_expected, auto expected_cm);
   tag_get_info_from_return_type(rt_candidate, auto candidate_cm);

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
         if (_chdebug) {
            isay(depth, "_c_match_return_type: BUILTIN TYPES, NOT COMPATIBLE");
         }
         return(0);
      }
   }

   // check if expected type is enumerated type
   if (!expected_is_builtin && expected_cm.type_name=="enumc" && candidate_is_builtin) {
      if (candidate_is_builtin && rt_candidate.pointer_count==0 &&
          _c_builtin_assignment_compatible("enum",
                                           rt_candidate.return_type,
                                           rt_candidate.pointer_count>0)
         ) {
         insert_tags=true;
         reference_compatible=false;
      } else {
         if (_chdebug) {
            isay(depth, "_c_match_return_type: ENUMERATED TYPE");
         }
         return(0);
      }
   }

   // check if candidate type is enumerated type
   if (!candidate_is_builtin && candidate_cm.type_name=="enumc" && expected_is_builtin) {
      if (expected_is_builtin && rt_expected.pointer_count==0 &&
          _c_builtin_assignment_compatible(rt_expected.return_type,"enum",false)
         ) {
         insert_tags=true;
         reference_compatible=false;
      } else {
         if (_chdebug) {
            isay(depth, "_c_match_return_type: CANDIDATE IS ENUMERATED TYPE");
         }
         return(0);
      }
   }

   // list any pointer if assigning to a void * parameter
   if (rt_candidate.pointer_count >= 1 &&
       rt_expected.pointer_count==1 && rt_expected.return_type=="void") {
      insert_tags=true;
   }

   // check if a Java or C# array can be assigned to object
   if (!expected_is_builtin && rt_expected.pointer_count==0 &&
       (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
      if (_LanguageInheritsFrom("java") && rt_expected.return_type:=="java.lang/Object") {
         insert_tags=true;
         array_object_compatible=true;
      } else if (_LanguageInheritsFrom("java") && rt_expected.return_type:=="java/lang/Object") {
         insert_tags=true;
         array_object_compatible=true;
      }
      if (_LanguageInheritsFrom("cs") &&
          (rt_expected.return_type:=="System/Array" ||
           tag_is_parent_class(rt_expected.return_type,"System/Array",
                               tag_files,true,true,
                               null,visited,depth+1))) {
         insert_tags=true;
         array_object_compatible=true;
      }
   }

   // check if a Java or C# being assigned to NULL object
   if (!expected_is_builtin && rt_expected.pointer_count==0 && rt_candidate.pointer_count==0 && tag_name :== "anonymous") {
      if (_LanguageInheritsFrom("java") && rt_candidate.return_type:=="java/lang/Object") {
         insert_tags=true;
      } else if (_LanguageInheritsFrom("cs") && rt_candidate.return_type:=="System/Object") {
         insert_tags=true;
      } else if (_LanguageInheritsFrom("m") && rt_candidate.return_type:=="Object") {
         insert_tags=true;
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
                                     tag_files,true,true,
                                     null,visited,depth+1)) {
         insert_tags=true;
      } else {
         // more to do here, check for type conversion operator
         if (_chdebug) {
            isay(depth, "_c_match_return_type: NO TYPE CONVERSION");
         }
         return(0);
      }
   }

   // if one is a builtin, but the other isn't, give up
   if (!insert_tags && expected_is_builtin != candidate_is_builtin) {
      // more to do here, need to support "void*" and classes
      // type conversion operators defined.
      if (_chdebug) {
         isay(depth, "_c_match_return_type: BUILTIN VS NOT-BUILTIN TYPE");
      }
      return(0);
   }

   // Can only dereference variables
   if (type_name!="var" && type_name!="gvar" && type_name!="param" && type_name!="lvar") {
      dereference_compatible=false;
      reference_compatible=false;
      array_operator="";
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
   scope_info := "";
   if (prefixexp == "" && candidate_cm.type_name=="enumc") {
      context_id := tag_get_current_context(auto cur_tag_name, auto cur_tag_flags,
                                            auto cur_type_name, auto cur_type_id,
                                            auto cur_context, auto cur_class, auto cur_package,
                                            visited, depth+1);
      if (context_id <= 0) {
         cur_context = "";
      }
      outer_name := "";
      inner_name := "";
      tag_split_class_name(candidate_cm.class_name, inner_name, outer_name);
      if (outer_name!="" && pos(outer_name, cur_context) != 1) {
         class_sep := (_LanguageInheritsFrom("java") || _LanguageInheritsFrom("cs") || _LanguageInheritsFrom("d"))? "." : "::";
         outer_name = stranslate(outer_name,class_sep,":");
         outer_name = stranslate(outer_name,class_sep,"/");
         scope_info = outer_name:+class_sep;
      }
   }

   // OK, the types seem to match,
   // compute pointer_prefix and pointer_postfix operators to
   // handle pointer indirection mismatches
   if (insert_tags) {
      if (prefixexp!="") {
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
      opt_ref_keyword := "";
      if ( _LanguageInheritsFrom("cs") ) {
         if (rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_REF) {
            opt_ref_keyword = "ref ";
         } else if (rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_OUT) {
            opt_ref_keyword = "out ";
         } else if (rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_IN) {
            opt_ref_keyword = "in ";
         }

         // double check that we do not already have "ref", "out" or "in"
         save_pos(auto before_ref_keyword_check);
         start_col := p_col;
         prev_id := cur_identifier(start_col);
         if (prev_id == "ref" || prev_id == "out" || prev_id == "in") {
            if (p_col > start_col+length(prev_id)) {
               opt_ref_keyword = "";
            }
         } else {
            if (start_col <= 0) start_col = p_col;
            if (start_col > 1) {
               p_col = start_col-2;
               prev_id = cur_identifier(start_col);
               if (prev_id == "ref" || prev_id == "out" || prev_id == "in") {
                  opt_ref_keyword = "";
               }
            }
         }
         restore_pos(before_ref_keyword_check);
      }
      k := 0;
      if (array_object_compatible && rt_expected.pointer_count!=rt_candidate.pointer_count) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,opt_ref_keyword:+tag_name,type_name,file_name,line_no,"",(int)tag_flags,"",file_name":"line_no);
         match_count++;
      }
      switch (rt_expected.pointer_count-rt_candidate.pointer_count) {
      case -2:
         if (!_LanguageInheritsFrom("java") && !_LanguageInheritsFrom("js") && dereference_compatible) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"**":+tag_name,type_name,file_name,line_no,"",(int)tag_flags,"",file_name":"line_no);
            match_count++;
            if (array_operator!="" && (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"*"tag_name:+array_operator,type_name,file_name,line_no,"",(int)tag_flags,"",file_name":"line_no);
               match_count++;
            }
         }
         break;
      case -1:
         if (!_LanguageInheritsFrom("java") && !_LanguageInheritsFrom("js") && dereference_compatible) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"*":+tag_name,type_name,file_name,line_no,"",(int)tag_flags,"",file_name":"line_no);
            match_count++;
         }
         if (array_operator!="" && (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,opt_ref_keyword:+tag_name:+array_operator,type_name,file_name,line_no,"",(int)tag_flags,"",file_name":"line_no);
            match_count++;
         }
         break;
      case 0:
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,opt_ref_keyword:+scope_info:+tag_name,type_name,file_name,line_no,"",(int)tag_flags,"",file_name":"line_no);
         match_count++;
         if (rt_candidate.pointer_count==1 && reference_compatible && array_operator!="" &&
             (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) &&
             !(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) &&
             !_LanguageInheritsFrom("java") && !_LanguageInheritsFrom("js")) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"&":+tag_name:+array_operator,type_name,file_name,line_no,"",(int)tag_flags,"",file_name":"line_no);
            match_count++;
         }
         break;
      case 1:
         if (!_LanguageInheritsFrom("java") && !_LanguageInheritsFrom("js") && reference_compatible &&
             !(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"&":+tag_name,type_name,file_name,line_no,"",(int)tag_flags,"",file_name":"line_no);
            match_count++;
         }
         break;
      }
   }

   // that's all folks
   if (_chdebug) {
      isay(depth, "_c_match_return_type: tree_wid="tree_wid" tree_index="tree_index);
      isay(depth, "_c_match_return_type: MATCH_COUNT="match_count" matches="tag_get_num_of_matches());
   }
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
                       _str tag_name,_str type_name, 
                       SETagFlags tag_flags,
                       _str file_name, int line_no,
                       _str &prefixexp, typeless tag_files, SETagFilterFlags filter_flags,
                       VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // no return type, forget this
   if (rt.return_type=="") {
      return(0);
   }

   // is this a builtin type?
   if (_c_is_builtin_type(rt.return_type)) {
      return(0);
   }

   // we are willing to handle one level of pointers
   switch (rt.pointer_count) {
   case 1:
      if (_LanguageInheritsFrom("java") || _LanguageInheritsFrom("js") ||
          (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)) {
         prefixexp :+= tag_name:+"[].";
      } else if (_LanguageInheritsFrom("e") &&
                 (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE)) {
         prefixexp :+= tag_name:+":[].";
      } else {
         prefixexp :+= tag_name:+"->";
      }
      break;
   case 0:
      prefixexp :+= tag_name:+".";
      break;
   default:
      return(0);
   }

   // the type seems OK, let's try listing members here
   num_matches := 0;
   tag_list_in_class("",rt.return_type,0,0,tag_files,
                     num_matches,def_tag_max_list_members_symbols,
                     filter_flags,SE_TAG_CONTEXT_ANYTHING,
                     false, true, null, null, visited, depth+1);
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
 * @param type_name      type name of tag (see SE_TAG_TYPE_*)
 * @param tag_flags      tag flags (bitset of SE_TAG_FLAG_*)
 * @param file_name      file that the tag is found in
 * @param return_type    return type to analyze (VS_TAGDETAIL_return_only)
 * @param rt             (reference) returned return type information
 * @param visited        (reference) hash table of previous results
 *
 * @return 0 on success, nonzero otherwise.
 */
int _c_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                           _str tag_name, _str class_name,
                           _str type_name, SETagFlags tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[],
                           int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   errorArgs._makeempty();
   // check for #define'd constants
   if (type_name=="define") {
      rt.istemplate=false;
      tag_init_tag_browse_info(auto cm, tag_name, class_name, type_name, tag_flags);
      cm.return_type = return_type;
      rt.taginfo=tag_compose_tag_browse_info(cm);
      if (pos("^:i$",return_type,1,"r")) {
         if (_LanguageInheritsFrom("rul")) {
            rt.return_type="INT";
         } else {
            rt.return_type="int";
         }
      } else if (pos("^:n$",return_type,1,"r")) {
         if (_LanguageInheritsFrom("rul")) {
            rt.return_type="NUMBER";
         } else {
            rt.return_type="float";
         }
      } else if (_LanguageInheritsFrom("e") && pos("^[']?*[']$",return_type,1,"r")) {
         rt.return_type="_sc_lang_string";
      } else if (pos("^['](\\\\?|?)[']$",return_type,1,"r")) {
         if (_LanguageInheritsFrom("rul")) {
            rt.return_type="CHAR";
         } else {
            rt.return_type="char";
         }
      } else if (pos("^:q$",return_type,1,"r")) {
         if (_LanguageInheritsFrom("e")) {
            rt.return_type="_sc_lang_string";
         } else if (_LanguageInheritsFrom("cs")) {
            rt.return_type="string";
         } else if (_LanguageInheritsFrom("rul")) {
            rt.return_type="STRING";
         } else if (_LanguageInheritsFrom("java")) {
            rt.return_type="java/lang/String";
         } else if (_LanguageInheritsFrom("c")) {
            rt.return_type="char";
            rt.pointer_count=1;
         }
      } else if (_LanguageInheritsFrom("m") && pos("^[@]:q$",return_type,1,"r")) {
         rt.return_type="NSString";
         rt.pointer_count=1;
      } else if (_LanguageInheritsFrom("m") && substr(return_type, 1, 2) == "@[" && _last_char(return_type) == "]") {
         rt.return_type="NSArray";
         rt.pointer_count=1;
      } else if (_LanguageInheritsFrom("m") && substr(return_type, 1, 2) == "@{" && _last_char(return_type) == "}") {
         rt.return_type="NSDictionary";
         rt.pointer_count=1;
      } else if (return_type=="false" || return_type=="true") {
         if (_LanguageInheritsFrom("js") || _LanguageInheritsFrom("java")) {
            rt.return_type="boolean";
         } else if (_LanguageInheritsFrom("e") || _LanguageInheritsFrom("c") || _LanguageInheritsFrom("cs")) {
            rt.return_type="bool";
         }
      } else if (_LanguageInheritsFrom("rul") && (return_type=="FALSE" || return_type=="TRUE")) {
         rt.return_type="BOOL";
      }
      if (rt.return_type=="") {
         rt.taginfo="";
         errorArgs[1]=tag_name;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      }
      return(0);
   } else if (type_name=="enumc") {
      tag_init_tag_browse_info(auto cm,tag_name,class_name,type_name,tag_flags);
      rt.taginfo=tag_compose_tag_browse_info(cm);
      rt.istemplate=false;
      rt.return_type=class_name;
      rt.pointer_count=0;
      return(0);
   } else if (type_name=="enum") {
      rt.taginfo="";
      errorArgs[1]=tag_name;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   } else if (return_type=="void") {
      rt.taginfo="";
      errorArgs[1]=tag_name;
      return VSCODEHELPRC_RETURN_TYPE_IS_VOID;
   }
   // delegate to the return type analysis functions
   status := _c_parse_return_type(errorArgs,tag_files,
                                  tag_name,class_name,file_name,
                                  return_type,
                                  _LanguageInheritsFrom("java") || _LanguageInheritsFrom("d"),
                                  rt, visited, depth+1);
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
 * @param param_name     (unused)named argument expected for this position 
 * @param visited        hash table of context tagging results 
 * @param depth          recursive search depth
 *
 * @return number of items inserted
 */
int _c_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                int tree_wid, int tree_index,
                                _str lastid_prefix="",
                                bool exact_match=false, bool case_sensitive=true,
                                _str param_name="", _str param_default="",
                                struct VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // number of matches inserted
   match_count := 0;
   k := 0;

   // check if we should offer to insert named function argument
   include_named_param := false;
   if (param_name != null && param_name != "" && rt_expected.return_type != "") {
      if (codehelp_at_start_of_parameter() || _CodeHelpDoesIdMatch(lastid_prefix, param_name, exact_match, case_sensitive)) {
         if (!_in_comment() && !codehelp_at_end_of_comment(lastid_prefix)) {
            include_named_param = true;
         }
      }
   }

   // calculate a prefix to insert for the named parameter, normally just a comment
   param_name_prefix := "";
   if (param_name != null && param_name != "") {
      if (_LanguageInheritsFrom("m")) {
         param_name_prefix = param_name:+":";
      } else {
         param_name_prefix = "/*":+param_name:+"*/";
      }
   }

   // was there a default parameter value supplied?
   if (param_name != null && param_name != "" && param_default != null && param_default != "") {
      if (_CodeHelpDoesIdMatch(lastid_prefix, param_default, exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_default,"const","",0,"",0,"");
         match_count++;
         if (include_named_param) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+param_default,"const","",0,"",0,"");
            match_count++;
         }
      }
   }

   // maybe they just want to add in the parameter name to the expression they already have
   if (include_named_param && (exact_match || lastid_prefix=="")) {
      k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+lastid_prefix,"const","",0,"",0,"");
      match_count++;
   }

   // insert NULL, if it isn't #defined, screw them
   if (rt_expected.pointer_count > 0) {
      if (!(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
         if (_CodeHelpDoesIdMatch(lastid_prefix, "NULL", exact_match, case_sensitive)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"NULL","const","",0,"",0,"");
            match_count++;
            if (include_named_param) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"NULL","const","",0,"",0,"");
               match_count++;
            }
         }
         if (_LanguageInheritsFrom("c") && !_LanguageInheritsFrom("ansic")) {
            if (_CodeHelpDoesIdMatch(lastid_prefix, "nullptr", exact_match, case_sensitive)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"nullptr","const","",0,"",0,"");
               match_count++;
               if (include_named_param) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"nullptr","const","",0,"",0,"");
                  match_count++;
               }
            }
         }
      }
      // maybe insert 'this'
      if (rt_expected.pointer_count==1) {
         this_class_name := _MatchThisOrSelf(visited, depth+1);
         if (this_class_name!="" && !_LanguageInheritsFrom("ansic")) {
            lang := _isEditorCtl()? p_LangId : "";
            tag_files := tags_filenamea(lang);
            if (this_class_name == rt_expected.return_type ||
                tag_is_parent_class(rt_expected.return_type,this_class_name,tag_files,true,true,null,visited,depth+1)) {
               if (_CodeHelpDoesIdMatch(lastid_prefix, "this", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"this","const","",0,"",0,"");
                  match_count++;
                  if (include_named_param) {
                     k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"this","const","",0,"",0,"");
                     match_count++;
                  }
               }
            }
         }

         // Objective-C NULL object constants
         if (_LanguageInheritsFrom("m")) {
            tag_files := tags_filenamea(p_LangId);
            if (_CodeHelpDoesIdMatch(lastid_prefix, "Nil", exact_match, case_sensitive)) {
               if (rt_expected.return_type :== "objc_class" || tag_is_parent_class("objc_class",rt_expected.return_type,tag_files,true,true,null,visited,depth+1)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"Nil","const","",0,"",0,"");
                  match_count++;
                  if (include_named_param) {
                     k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"Nil","const","",0,"",0,"");
                     match_count++;
                  }
               }
            }
            if (_CodeHelpDoesIdMatch(lastid_prefix, "nil", exact_match, case_sensitive)) {
               if (rt_expected.return_type :== "objc_object" || tag_is_parent_class("objc_object",rt_expected.return_type,tag_files,true,true,null,visited,depth+1)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"nil","const","",0,"",0,"");
                  match_count++;
                  if (include_named_param) {
                     k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"nil","const","",0,"",0,"");
                     match_count++;
                  }
               }
            }
            if (rt_expected.return_type == "NSString" && rt_expected.pointer_count == 1) {
               if (_CodeHelpDoesIdMatch(lastid_prefix, "@\"", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"@\"\"@","const","",0,"",0,"");
                  match_count++;
                  if (include_named_param) {
                     k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name": @\"\"@","const","",0,"",0,"");
                     match_count++;
                  }
               }
            }
         }

      }
      // insert constant string
      if (_LanguageInheritsFrom("c") && rt_expected.pointer_count==1 && rt_expected.return_type=="char") {
         if (_CodeHelpDoesIdMatch(lastid_prefix, "\"", exact_match, case_sensitive)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"\"\"","const","",0,"",0,"");
            match_count++;
            if (include_named_param) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"\"\"","const","",0,"",0,"");
               match_count++;
            }
         }
      }

      // Try inserting new 'class'
      if (!_c_is_builtin_type(rt_expected.return_type) && _LanguageInheritsFrom("c") && !_LanguageInheritsFrom("ansic")) {

         // If it was specified as a generic, include the set parameters in the suggestion
         generic_args := "";
         blank_args := "";
         if (rt_expected.istemplate && rt_expected.template_names._length() > 0) {
            _str names[];
            for (ai := 0; ai < rt_expected.template_names._length(); ai++) {
               ty := "";
               if (rt_expected.template_args._indexin(rt_expected.template_names[ai])) {
                  ty = rt_expected.template_args:[rt_expected.template_names[ai]];
               }
               names[ai] = ty;
            }
            generic_args="<"(join(names, ","))">";
            blank_args="<>";
         }

         // check the current package name
         tag_get_current_context(auto cur_tag_name, auto cur_flags, 
                                 auto cur_type_name, auto cur_type_id, 
                                 auto cur_context, auto cur_class, auto cur_package,
                                 visited, depth+1);

         // clean up class name for code
         class_name := rt_expected.return_type;
         class_name = stranslate(class_name,VS_TAGSEPARATOR_class,"::");
         if (_LanguageInheritsFrom("java") || _LanguageInheritsFrom("cs" || _LanguageInheritsFrom("rs"))) {
            class_name = stranslate(class_name,".",VS_TAGSEPARATOR_class);
            class_name = stranslate(class_name,".",VS_TAGSEPARATOR_package);
            cur_package = stranslate(cur_package,".",VS_TAGSEPARATOR_class);
            cur_package = stranslate(cur_package,".",VS_TAGSEPARATOR_package);
         } else if (_LanguageInheritsFrom("c") || _LanguageInheritsFrom("m")) {
            class_name = stranslate(class_name,"::",VS_TAGSEPARATOR_class);
            class_name = stranslate(class_name,"::",VS_TAGSEPARATOR_package);
            cur_package = stranslate(cur_package,"::",VS_TAGSEPARATOR_class);
            cur_package = stranslate(cur_package,"::",VS_TAGSEPARATOR_package);
         } else {
            class_name = stranslate(class_name,".",VS_TAGSEPARATOR_class);
            class_name = stranslate(class_name,".",VS_TAGSEPARATOR_package);
            cur_package = stranslate(cur_package,".",VS_TAGSEPARATOR_class);
            cur_package = stranslate(cur_package,".",VS_TAGSEPARATOR_package);
         }

         // Objective-C object default initialization
         objective_c_no_new_case := false;
         if (_LanguageInheritsFrom('m') && rt_expected.pointer_count==1 && !pos("::", class_name)) {
            tag_files := tags_filenamea(p_LangId);
            if (rt_expected.return_type :== "Object" || 
                rt_expected.return_type :== "NSObject" || 
                rt_expected.return_type :== "objc_object" ||
                rt_expected.return_type :== "objc_class" ||
                tag_is_parent_class("NSObject",rt_expected.return_type,tag_files,true,true,null,visited,depth+1) ||
                tag_is_parent_class("Object",rt_expected.return_type,tag_files,true,true,null,visited,depth+1) ||
                tag_is_parent_class("objc_object",rt_expected.return_type,tag_files,true,true,null,visited,depth+1)) {
               if (class_name == "objc_object") class_name = "Object";
               if (class_name == "objc_class")  class_name = "Class";
               objective_c_no_new_case = true;
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"[["class_name" alloc] init]","const","",0,"",0,"");
               match_count++;
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"["class_name" new]","const","",0,"",0,"");
               match_count++;
            }
         }

         // insert qualified class name (except for std:: and current package)
         if (!objective_c_no_new_case &&
             pos("std::", class_name) != 1 &&
             pos("std/", class_name) != 1 &&
             pos(cur_package, class_name) != 1) {
            if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
               match_count++;
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
               match_count++;
            }
         }

         // insert unqualified class name
         p := lastpos(":", class_name);
         if (p <= 0) p = lastpos(".", class_name);
         if (p > 0 && !objective_c_no_new_case) {
            class_name = substr(class_name, p+1);
            if (_LanguageInheritsFrom("c") && class_name :== "basic_string" && beginsWith(generic_args,"<char,")) {
               class_name = "string";
               generic_args = "";
               blank_args   = "";
            }
            if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
               match_count++;
               if (generic_args != blank_args) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
               }
            }
         }
      }

      // that's all
      return 0;
   }

   if (rt_expected.pointer_count==0) {
      // Objective-C NULL object constants
      if (_LanguageInheritsFrom("m")) {
         tag_files := tags_filenamea(p_LangId);
         if (_CodeHelpDoesIdMatch(lastid_prefix, "NSNull", exact_match, case_sensitive)) {
            if (rt_expected.return_type :== "NSObject" || tag_is_parent_class("NSObject",rt_expected.return_type,tag_files,true,true,null,visited,depth+1)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"NSNull","const","",0,"",0,"");
               match_count++;
               if (include_named_param) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"NSNull","const","",0,"",0,"");
                  match_count++;
               }
            }
         }
         if (_CodeHelpDoesIdMatch(lastid_prefix, "Nil", exact_match, case_sensitive)) {
            if (rt_expected.return_type :== "Class" || tag_is_parent_class("Class",rt_expected.return_type,tag_files,true,true,null,visited,depth+1)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"Nil","const","",0,"",0,"");
               match_count++;
               if (include_named_param) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"Nil","const","",0,"",0,"");
                  match_count++;
               }
            }
         }
         if (_CodeHelpDoesIdMatch(lastid_prefix, "nil", exact_match, case_sensitive)) {
            if (rt_expected.return_type :== "Object" || tag_is_parent_class("Object",rt_expected.return_type,tag_files,true,true,null,visited,depth+1)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"nil","const","",0,"",0,"");
               match_count++;
               if (include_named_param) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"nil","const","",0,"",0,"");
                  match_count++;
               }
            }
         }
      }
   }

   // insert character constant
   if (_LanguageInheritsFrom("c") && rt_expected.pointer_count==0 && rt_expected.return_type=="char") {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "\'", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"''","const","",0,"",0,"");
         match_count++;
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"'\\0'","const","",0,"",0,"");
         match_count++;
         if (include_named_param) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"''","const","",0,"",0,"");
            match_count++;
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"'\\0'","const","",0,"",0,"");
            match_count++;
         }
      }
   }

   // Insert boolean
   if (rt_expected.return_type=="bool") {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "true", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"true","const","",0,"",0,"");
         match_count++;
         if (include_named_param) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"true","const","",0,"",0,"");
            match_count++;
         }
      }
      if (_CodeHelpDoesIdMatch(lastid_prefix, "false", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"false","const","",0,"",0,"");
         match_count++;
         if (include_named_param) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"false","const","",0,"",0,"");
            match_count++;
         }
      }
   }


   // Insert sizeof function and numeric constants
   if (_LanguageInheritsFrom("c") && !_LanguageInheritsFrom("d")) {
      if (rt_expected.return_type=="int" ||
          rt_expected.return_type=="long" ||
          rt_expected.return_type=="long int" ||
          rt_expected.return_type=="short" ||
          rt_expected.return_type=="short int" ||
          rt_expected.return_type=="long long" ||
          rt_expected.return_type=="long long int" ||
          rt_expected.return_type=="unsigned char" ||
          rt_expected.return_type=="unsigned int" ||
          rt_expected.return_type=="unsigned long" ||
          rt_expected.return_type=="unsigned long int" ||
          rt_expected.return_type=="unsigned long long" ||
          rt_expected.return_type=="unsigned long long int" ||
          rt_expected.return_type=="unsigned short" ||
          rt_expected.return_type=="unsigned short int" ||
          rt_expected.return_type=="intptr_t" ||
          rt_expected.return_type=="ssize_t" ||
          rt_expected.return_type=="size_t" ) {
         if (_CodeHelpDoesIdMatch(lastid_prefix, "sizeof", exact_match, case_sensitive)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"sizeof","proto","",0,"",0,"");
            match_count++;
            if (include_named_param) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"sizeof","const","",0,"",0,"");
               match_count++;
            }
         }
         if (_CodeHelpDoesIdMatch(lastid_prefix, "alignof", exact_match, case_sensitive)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"alignof","proto","",0,"",0,"");
            match_count++;
            if (include_named_param) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"alignof","const","",0,"",0,"");
               match_count++;
            }
         }
         if (_CodeHelpDoesIdMatch(lastid_prefix, "0", exact_match, case_sensitive)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"0","const","",0,"",0,"");
            match_count++;
            if (include_named_param) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"0","const","",0,"",0,"");
               match_count++;
            }
         }
         if (_CodeHelpDoesIdMatch(lastid_prefix, "1", exact_match, case_sensitive)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"1","const","",0,"",0,"");
            match_count++;
            if (include_named_param) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name_prefix:+"1","const","",0,"",0,"");
               match_count++;
            }
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
 * @param options         Space delimited ptions for the style
 *                        of the generated code.
 *                        <UL><LI>override-kw - Use override
 *                        keyword for virtual function
 *                        signatures.</LI>
 *                        </UL>
 *
 * @return string holding formatted declaration.
 */
_str _c_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                 _str decl_indent_string="",
                 _str access_indent_string="", _str (&header_list)[] = null, 
                 _str options = "")
{
   //say("_c_get_decl H"__LINE__": IN");
   //tag_browse_info_dump(info, "_c_get_decl");
   tag_flags  := info.flags;
   tag_name   := info.member_name;
   class_name := info.class_name;
   type_name  := info.type_name;
   is_java := (_LanguageInheritsFrom("java") || _LanguageInheritsFrom("cs"));
   in_class_def := (flags&VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF);
   verbose      := (flags&VSCODEHELPDCLFLAG_VERBOSE);
   show_class   := (flags&VSCODEHELPDCLFLAG_SHOW_CLASS);
   show_access  := (flags&VSCODEHELPDCLFLAG_SHOW_ACCESS);
   show_inline  := (flags&VSCODEHELPDCLFLAG_SHOW_INLINE);
   show_static  := (flags&VSCODEHELPDCLFLAG_SHOW_STATIC);
   arguments := (info.arguments!="")? "("info.arguments")":"";
   class_sep := (is_java || lang=="e" || lang=="d")? ".":"::";
   return_type := "";
   result := "";
   initial_value := "";
   before_return := "";
   return_start  := "";
   array_arguments := "";
   proto := "";
   use_override_kw := (pos("override-kw", options) != 0);

   //say("_c_get_decl: type_name="type_name);
   switch (type_name) {
   case "proc":         // procedure or command
   case "proto":        // function prototype
   case "constr":       // class constructor
   case "destr":        // class destructor
   case "func":         // function
   case "procproto":    // Prototype for procedure
   case "subfunc":      // Nested function or cobol paragraph
   case "subproc":      // Nested procedure or cobol paragraph
   case "selector":
   case "staticselector":
      before_return=decl_indent_string;
      if (lang=="phpscript" || lang=="rul") {
         strappend(before_return,"function ");
      }
      if (show_access) {
         if (is_java) {
            switch (tag_flags & SE_TAG_FLAG_INTERNAL_ACCESS) {
            case SE_TAG_FLAG_PUBLIC:
               strappend(before_return,"public ");
               break;
            case SE_TAG_FLAG_PACKAGE:
               //strappend(before_return,'package ');
               // package is default scope for Java
               break;
            case SE_TAG_FLAG_PROTECTED:
               strappend(before_return,"protected ");
               break;
            case SE_TAG_FLAG_PRIVATE:
               // yes, this can not happen
               strappend(before_return,"private ");
               break;
            case SE_TAG_FLAG_INTERNAL:
               // internal is only found in C#
               strappend(before_return,"internal ");
               break;
            case SE_TAG_FLAG_PROTECTED|SE_TAG_FLAG_INTERNAL:
               strappend(before_return,"protected internal ");
               break;
            }
         } else if (lang=="c" && in_class_def) {
            c_access_flags := (tag_flags & SE_TAG_FLAG_ACCESS);
            switch (c_access_flags) {
            case SE_TAG_FLAG_PUBLIC:
            case SE_TAG_FLAG_PACKAGE:
               before_return="";
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
            case SE_TAG_FLAG_PROTECTED:
               before_return="";
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
            case SE_TAG_FLAG_PRIVATE:
               before_return="";
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
         if (in_class_def && (tag_flags & SE_TAG_FLAG_STATIC)) {
            strappend(before_return,"static ");
         }
         if (!in_class_def && show_inline) {
            strappend(before_return,"inline ");
         }
         if (tag_flags & SE_TAG_FLAG_NATIVE) {
            strappend(before_return,"native ");
         }
         if (lang=="cs" && (tag_flags & SE_TAG_FLAG_VIRTUAL)) {
            strappend(before_return,"override ");
         } else if ((tag_flags & SE_TAG_FLAG_VIRTUAL) && !is_java && in_class_def) {
            if (!use_override_kw) {
               strappend(before_return,"virtual ");
            }
         }
         if (tag_flags & SE_TAG_FLAG_FINAL) {
            strappend(before_return,"final ");
         }
         if (tag_flags & SE_TAG_FLAG_SYNCHRONIZED) {
            strappend(before_return,"synchronized ");
         }
         if (tag_flags & SE_TAG_FLAG_TRANSIENT) {
            strappend(before_return,"transient ");
         }
      } else if (show_static) {
         if (tag_flags & SE_TAG_FLAG_STATIC) {
            strappend(before_return,"static ");
         }
      }

      // prepend qualified class name for C++
      if (tag_flags & SE_TAG_FLAG_OPERATOR) {
         tag_name = "operator "tag_name;
      }
      if (!in_class_def && show_class && class_name!="") {
         class_name = stranslate(class_name,class_sep,":");
         class_name = stranslate(class_name,class_sep,"/");
         tag_name   = class_name:+class_sep:+tag_name;
      }

      // compute keywords falling in after the signature
      after_sig := "";
      if (tag_flags & SE_TAG_FLAG_CONST && !is_java) {
         strappend(after_sig, " const");
      }
      if (tag_flags & SE_TAG_FLAG_VOLATILE && !is_java) {
         strappend(after_sig," volatile");
      }
      if (use_override_kw && (tag_flags & SE_TAG_FLAG_VIRTUAL) && !is_java && in_class_def) {
         strappend(after_sig, " override");
      }
      if (verbose) {
         if (tag_flags & SE_TAG_FLAG_MUTABLE && !is_java) {
            strappend(before_return," mutable");
         }
         // do something with 'throw'
         if (info.exceptions != "") {
            if (lang=="idl") {
               strappend(after_sig," raises("info.exceptions")");
            } else if (lang=="java") {
               strappend(after_sig," throws "info.exceptions);
            } else if (lang=="c") {
               strappend(after_sig," throw("info.exceptions")");
            }
         }
      }
      // finally, insert the line
      return_type = info.return_type;
      lastch := _last_char(return_type);
      if (lastch!="*" && lastch!="&" && lastch!=" ") {
         return_type = (return_type=="" && (lang=="c" || lang=="e"))? "int ":return_type:+" ";
      }
      if (info.flags&SE_TAG_FLAG_CONST_DESTR) {
         return_type="";
      }
      _maybe_append(return_type, ' ');
      if (type_name=="selector" || type_name=="staticselector") {
         result=before_return:+return_type:+tag_name:+info.arguments:+after_sig;
      } else {
         result=before_return:+return_type:+tag_name:+"("info.arguments")":+after_sig;
      }
      return(result);

   case "define":       // preprocessor macro definition
      return(decl_indent_string"#define ":+tag_name:+arguments:+" "info.return_type);

   case "typedef":      // type definition
      return(decl_indent_string"typedef "info.return_type:+arguments" "tag_name);

   case "gvar":         // global variable declaration
   case "var":          // member of a class / struct / package
   case "lvar":         // local variable declaration
   case "prop":         // property
   case "param":        // function or procedure parameter
   case "group":        // Container variable
   case "mixin":        // D language mixin construct
   case "const":        // pascal constant
      is_ref := false;
      rt := info.return_type;
      end_rt := "";
      if (type_name == "param" && pos("&", rt) != 0) {
         is_ref = true;
         parse rt with rt '&' end_rt;
      }

      if (type_name == "mixin") {
         strappend(before_return,"mixin ");
      }

      if (is_java && type_name == "var") {
         switch (tag_flags & SE_TAG_FLAG_ACCESS) {
         case SE_TAG_FLAG_PUBLIC:
            strappend(before_return,"public ");
            break;
         case SE_TAG_FLAG_PACKAGE:
            //strappend(before_return,'package ');
            // package is default scope for Java
            break;
         case SE_TAG_FLAG_PROTECTED:
            strappend(before_return,"protected ");
            break;
         case SE_TAG_FLAG_PRIVATE:
            // yes, this can not happen
            strappend(before_return,"private ");
            break;
         }
      }

      // get the set of characters that do not match identifiers
      not_id_chars := "[^a-zA-Z0-9_$]";
      if (_isEditorCtl()) {
         not_id_chars = _clex_identifier_notre();
      }

      if (show_static && (tag_flags & SE_TAG_FLAG_STATIC)) {
         strappend(before_return,"static ");
      }
      if ((tag_flags & SE_TAG_FLAG_CONSTEXPR) && !pos('(^|'not_id_chars')constexpr($|':+not_id_chars')',  rt, 1, 're')) {
         strappend(before_return,"constexpr ");
      } else if ((tag_flags & SE_TAG_FLAG_CONSTEVAL) && !pos('(^|'not_id_chars')consteval($|':+not_id_chars')',  rt, 1, 're')) {
         strappend(before_return,"consteval ");
      } else if ((tag_flags & SE_TAG_FLAG_CONSTINIT) && !pos('(^|'not_id_chars')constinit($|':+not_id_chars')',  rt, 1, 're')) {
         strappend(before_return,"constinit ");
      } else if ((tag_flags & SE_TAG_FLAG_CONST) && !pos('(^|'not_id_chars')const($|':+not_id_chars')',  rt, 1, 're')) {
         strappend(before_return,"const ");
      }
      if ((tag_flags & SE_TAG_FLAG_VOLATILE) && !pos('(^|'not_id_chars')volatile($|':+not_id_chars')',  rt, 1, 're')) {
         strappend(before_return,"volatile ");
      }
      if (tag_flags & SE_TAG_FLAG_FINAL) {
         strappend(before_return,"final ");
      }

      parse info.return_type with rt "=" initial_value;
      parse rt with return_start "[" array_arguments;
      if (array_arguments!="") {
         array_arguments="["array_arguments;
      }
      if (initial_value!="") {
         if ((_LanguageInheritsFrom("e",lang) || _LanguageInheritsFrom("java",lang)) && rt == "") {
            initial_value=" := "initial_value;
         } else {
            initial_value=" = "initial_value;
         }
      }

      if (!in_class_def && show_class && class_name!="") {
         class_name = stranslate(class_name,class_sep,":");
         class_name = stranslate(class_name,class_sep,"/");
         tag_name   = class_name:+class_sep:+tag_name;
      }

      // ref param
      if (type_name == "param" && is_ref) {
         if (_LanguageInheritsFrom("e",lang) && array_arguments != "") {
            return(decl_indent_string:+before_return:+return_start" (&" :+ tag_name :+ ")":+ array_arguments);
         } else if (_LanguageInheritsFrom("cs",lang)) {
            return("ref "decl_indent_string:+before_return:+rt" "tag_name:+initial_value);
         } else {
            return(decl_indent_string:+before_return:+return_start"&"end_rt" ":+tag_name:+array_arguments:+initial_value);
         }
      }

      if (_LanguageInheritsFrom("cs",lang)) {
         return(decl_indent_string:+before_return:+rt:+" "tag_name:+initial_value);
      } else {
         return(decl_indent_string:+before_return:+rt:+" ":+tag_name:+array_arguments:+initial_value);
      }

   case "struct":       // structure definition
   case "enum":         // enumerated type
   case "class":        // class definition
   case "union":        // structure / union definition
   case "interface":    // interface, eg, for Java
   case "package":      // package / module / namespace
   case "prog":         // pascal program
   case "lib":          // pascal library
      if (!in_class_def && show_class && class_name!="") {
         class_name = stranslate(class_name,class_sep,":");
         class_name = stranslate(class_name,class_sep,"/");
         tag_name   = class_name:+class_sep:+tag_name;
      }
      arguments = "";
      if (info.template_args!="") {
         arguments = "<"info.template_args">";
      } else if (info.arguments!="") {
         arguments = "<"info.arguments">";
      }
      if (type_name:=="package" && lang=="c") {
         type_name="namespace";
      }
      return(decl_indent_string:+type_name" "tag_name:+arguments);

   case "label":        // label
      return(decl_indent_string:+tag_name":");

   case "import":       // package import or using
      return(decl_indent_string:+"import "tag_name);

   case "friend":       // C++ friend relationship
      return(decl_indent_string:+"friend "tag_name:+arguments);

   case "include":      // C++ include or Ada with (dependency)
      return(decl_indent_string:+"#include "tag_name);

   case "form":         // GUI Form or window
      return(decl_indent_string:+"_form "tag_name);
   case "menu":         // GUI Menu
      return(decl_indent_string:+"_menu "tag_name);
   case "control":      // GUI Control or Widget
      return(decl_indent_string:+"_control "tag_name);
   case "eventtab":     // GUI Event table
      return(decl_indent_string:+"defeventtab "tag_name);

   case "enumc":        // enumeration value
      proto=decl_indent_string;
      if (!in_class_def && show_class && class_name!="") {
         class_name= stranslate(class_name,class_sep,":");
         class_name= stranslate(class_name,class_sep,"/");
         strappend(proto,class_name:+class_sep);
      }
      strappend(proto,info.member_name);
      if (info.return_type!="") {
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
      return(decl_indent_string:+type_name" "tag_name);

   case "tag":          // HTML / XML / SGML tag
   case "taguse":       // HTML / XML / SGML tag
      return(decl_indent_string:+"<"info.member_name">");

   default:
      proto=decl_indent_string;
      if (info.return_type!="") {
         strappend(proto,info.return_type" ");
      }
      if (!in_class_def && show_class && class_name!="") {
         class_name= stranslate(class_name,class_sep,":");
         class_name= stranslate(class_name,class_sep,"/");
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
      if (terminationKey:==FILESEP || terminationKey==FILESEP2) {
         // if we have a directory name and they typed a file separator, remove it
         lc := _last_char(word.insertWord);
         if (lc == FILESEP || lc == FILESEP2) {
            word.insertWord = substr(word.insertWord, 1, length(word.insertWord)-1);
         }
         return;
      }
      return;
   }

   // special handling for user-define string literal operator
   if (idexp_info != null && word.symbol != null &&
       (word.symbol.flags & SE_TAG_FLAG_OPERATOR) &&
       substr(word.symbol.member_name, 1,2) == '""') {
      word.insertWord = substr(word.symbol.member_name,3);
      word.symbol.type_name = "statement";
   }

   // special handling for overloaded operators
   if (idexp_info != null && word.symbol != null &&
       (word.symbol.flags & SE_TAG_FLAG_OPERATOR) &&
       def_c_replace_operators &&
       _last_char(idexp_info.prefixexp) == ".") {
      word.insertWord = word.symbol.member_name;
      word.symbol.type_name = "statement";
   }
}

bool _c_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                   VS_TAG_IDEXP_INFO &idexp_info,
                                   _str terminationKey="")
{
   // special handling for overloaded operators
   if (idexp_info != null && word.symbol != null &&
       (word.symbol.flags & SE_TAG_FLAG_OPERATOR) &&
       def_c_replace_operators &&
       _last_char(idexp_info.prefixexp) == ".") {
      // delete the '.' charactor
      if (!_clex_is_identifier_char(_first_char(word.insertWord))) {
         p_col -= length(word.insertWord)+1;
         _delete_char();
         if (terminationKey == " ") {
            _insert_text(" ");
         }
         p_col += length(word.insertWord);
      }
      // do not double-insert the operator
      if (terminationKey == _first_char(word.insertWord)) {
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
       (word.symbol.flags & SE_TAG_FLAG_TEMPLATE) &&
       word.symbol.template_args != null &&
       word.symbol.template_args != "" &&
       tag_tree_type_is_class(word.symbol.type_name) &&
       (_GetCodehelpFlags() & VSCODEHELPFLAG_INSERT_OPEN_PAREN) &&
       (terminationKey=="" || terminationKey==ENTER) &&
       !(idexp_info.info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) &&
       !(idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) ) {

      last_event("<");
      auto_functionhelp_key();
      return false;
   }

   return true;
}

bool c_maybe_list_javadoc(bool OperatorTyped=false)
{
   // check if we are in a docummentation comment
   if (last_event()==" " && _haveContextTagging() &&
       (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) &&
       _clex_find(0, "g") == CFG_COMMENT && _inDocComment()) {
      VS_TAG_IDEXP_INFO idexp_info;
      tag_idexp_info_init(idexp_info);
      visited := null;
      status := _doc_comment_get_expression_info(false, idexp_info, visited);
      if (status < 0) {
         return false;
      }
      if (!(idexp_info.info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT)) {
         return false;
      }
      if (idexp_info.prefixexp == "@param"   ||
          idexp_info.prefixexp == "@see"     ||
          idexp_info.prefixexp == "@throw"   ||
          idexp_info.prefixexp == "\\param"  ||
          idexp_info.prefixexp == "\\see"    ||
          idexp_info.prefixexp == "\\throw"  ) {
         _do_list_members(OperatorTyped:false, DisplayImmediate:true);
         return true;
      }
      // maybe listing attributes of an HTML tag
      if (_first_char(idexp_info.prefixexp) == "<" && length(idexp_info.prefixexp) > 1) {
         _do_list_members(OperatorTyped:false, DisplayImmediate:true);
         return true;
      }
   }

   // not what we were looking for
   return false;
}

enum CFGColorConstants _in_comment_common(CFGColorConstants in_color=CFG_COMMENT) {
   color := (CFGColorConstants)_clex_find(0,"g");
   if (color==in_color) {
      // This code does not work when cursor is inbetween start chars
      // chars of mlcomment. i.e. "/<cursor>*" cursor is inbetween / and *.
      save_pos(auto p);

      // Special case:  cursor on first char of the comment is
      // not 'in' the comment.
      if (prev_char() == 0) {
         ncol := _clex_find(0, "g");
         restore_pos(p);

         if (ncol != in_color) {
            return CFG_NULL;
         }
      } else {
         // At beginning of buffer then.  Not in a comment.
         return CFG_NULL;
      }

      orig_lastModified := p_LastModified;
      orig_modifyflags  := p_ModifyFlags;
      orig_modify       := p_modify;
      orig_line_modify := _lineflags();
      get_line_raw(auto line);
      orig_col := p_col;
      old_TruncateLength := p_TruncateLength;
      p_TruncateLength=0;
      // We have to suspend text callbacks for this buffer. There are cases
      // (DIFFzilla) where these callbacks will cause trouble because they are
      // called and then we will restore the buffer back to its original state.
      _CallbackBufSuspendAll(p_buf_id,1);
      orig_undo_steps := _SuspendUndo(p_window_id);
#if 1
      /* This new code DOES NOT special case '\' at the end of the line
         like the old code. I don't think it's necessary. We really just want
         to know if after splitting at the cursor, the text at the beginning of the next
         line will be in a comment or not.
      */
      _split_line();
      down();p_col=1;_insert_text(' ');p_col=1;
      color = (CFGColorConstants)_clex_find(0,"g");
      _delete_text(1);up();_join_line();
#else
      //Add an extra space to next line's replace_line_raw() call to cover
      //the case of '\' right before the cursor.
      replace_line_raw(expand_tabs(line,1,orig_col-1,'s')' ');
      insert_line_raw(' 'expand_tabs(line,orig_col,-1,'s'));
      p_col=1;
      color=_clex_find(0,'g');
      say('color is comment='(color==CFG_COMMENT));
      if (!_delete_line()) {
         up();
      }
      replace_line_raw(line);
#endif

      p_TruncateLength = old_TruncateLength;
      p_col            = orig_col;
      p_ModifyFlags    = orig_modifyflags;
      p_LastModified   = orig_lastModified;
      //Need to restore start position to preserve scroll position (DOB: 03/07/2006)
      restore_pos(p);

      if (isEclipsePlugin()) {
         _eclipse_set_dirty(p_window_id, orig_modify);
      }
      _lineflags(orig_line_modify,MODIFY_LF);

      // Turn the text callbacks back on
      _updateTextChange();
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
 *                        the line at the cursor) the cursor
 *                        will still be inside a comment.
 *
 * @return Returns <b>true</b> if cursor is within a comment and
 * <b>p_lexer_name</b> is not "".
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
bool _in_comment(bool in_ml_comment=false)
{
   if (p_lexer_name=="") {
      return(false);
   }
   color := 0;
   if (in_ml_comment) {
      color=_in_comment_common();
   } else {
      color=_clex_find(0,"g");
   }
   return(color==CFG_COMMENT);
}
bool _in_mlstring()
{
   if (p_lexer_name=="") {
      return(false);
   }
   color:=_in_comment_common(CFG_STRING);
   return(color==CFG_STRING);
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
bool _in_string()
{
   if (p_lexer_name=="") {
      return false;
   }
   color := _clex_find(0,'g');
   return(color==CFG_STRING);
}

// Does current lang allow class vars to be declared in a function?
static bool lang_allows_vars_declarations_in_functions()
{
   return p_LangId == 'py';
}

/**
 * Determines if the cursor is in a function body or statement scope.
 */
bool _in_function_scope()
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // update the context and find the element under the cursor
   _UpdateContext(true);
   context_id := tag_current_context();
   if (context_id <= 0) {
      return false;
   }

   // check for function or statement
   tag_type := "";
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,tag_type);

   if (lang_allows_vars_declarations_in_functions() && tag_type == 'var') {
      // Look at the containing context instead to see if this decl is in a function or statement.
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, auto outer);
      if (outer > 0) {
         context_id = outer;
         tag_get_detail2(VS_TAGDETAIL_context_type, context_id, tag_type);
      }
   }

   if (!tag_tree_type_is_func(tag_type) && !tag_tree_type_is_statement(tag_type)) {
      return false;
   }

   // check for before scope seek position
   start_seekpos := 0;
   scope_seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,context_id,start_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos,context_id,scope_seekpos);
   if (scope_seekpos > start_seekpos && _QROffset() < scope_seekpos) {
      return false;
   }

   // not in a function body or statement
   return true;
}

/**
 * Determines if the cursor is in a function body or statement scope.
 */
bool _is_return_type_local(VS_TAG_RETURN_TYPE &rt)
{
   // make sure 'rt' is valid
   if (rt == null || rt.line_number == 0 || rt.return_type == "") {
      return false;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // update the context and find the element under the cursor
   _UpdateContext(true);
   context_id := tag_current_context();
   if (context_id <= 0) {
      return false;
   }

   // check for function or statement
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,auto tag_type);
   if (!tag_tree_type_is_func(tag_type) && 
       !tag_tree_type_is_class(tag_type) && 
       !tag_tree_type_is_statement(tag_type)) {
      return false;
   }

   // check for before scope seek position
   tag_get_detail2(VS_TAGDETAIL_context_start_linenum,context_id,auto start_linenum);
   tag_get_detail2(VS_TAGDETAIL_context_end_linenum,  context_id,auto end_linenum);
   if (rt.line_number < start_linenum || rt.line_number > end_linenum) {
      return false;
   }

   // this might be a local class
   return true;
}

/**
 * Use this to determine if the cursor is within the scope of a
 * class. For example:
 * <pre>
 * class Person {
 * }
 * </pre>
 *
 * The method will return false if the cursor is between the 'c'
 * and the '{'.  If the cursor is between the braces, then the
 * function will return true.
 */
bool _in_class_scope()
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // update the context and find the element under the cursor
   _UpdateContext(true);
   context_id := tag_current_context();
   if (context_id <= 0) {
      return false;
   }

   // check for class
   tag_type := "";
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,tag_type);
   if (!tag_tree_type_is_class(tag_type)) {
      return false;
   }

   // check for before scope seek position
   start_seekpos := 0;
   scope_seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,context_id,start_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos,context_id,scope_seekpos);
   if (scope_seekpos > start_seekpos && _QROffset() > scope_seekpos) {
      return true;
   }

   // not in a function body or statement
   return false;
}

definit()
{
   if (gDoxygenCommandsAtsign._length() != gDoxygenCommandsBackslash._length()) {
      gDoxygenCommandsBackslash = null;
      foreach (auto cmd in gDoxygenCommandsAtsign) {
         gDoxygenCommandsBackslash :+= "\\" :+ substr(cmd,2);
      }
   }
}

//////////////////////////////////////////////////////////////////////////
_str gDoxygenCommandsBackslash[]= null;
_str gDoxygenCommandsAtsign[]= {
   "@a", "@addindex", "@addtogroup", "@anchor", "@arg",  "@attention", "@author",
   "@b", "@brief", "@bug", "@c", "@callgraph", "@callergraph", "@category", "@class",
   "@code", "@cond", "@copydoc", "@date", "@def", "@defgroup", "@deprecated", "@details",
   "@dir", "@dontinclude", "@dot", "@dotfile", "@e", "@else", "@elseif", "@em",
   "@endcode", "@endcond", "@enddot", "@endhtmlonly", "@endif", "@endlatexonly",
   "@endlink", "@endmanonly", "@endmsc", "@endverbatim", "@endxmlonly", "@enum",
   "@example", "@exception", "@f$", "@f[", "@f]", "@file", "@fn", "@hideinitializer",
   "@htmlinclude", "@htmlonly", "@if", "@ifnot", "@image", "@include", "@includelineno",
   "@ingroup", "@internal", "@invariant", "@interface",
   "@latexonly", "@li", "@line", "@link", "@literal",
   "@mainpage", "@manonly", "@msc", "@n", "@name", "@namespace", "@nosubgrouping",
   "@note", "@overload", "@p", "@package", "@page", "@par", "@paragraph", "@param",
   "@post", "@pre", "@private", "@privatesection", "@property", "@protected",
   "@protectedsection", "@protocol", "@public", "@publicsection", "@ref", "@relates",
   "@relatesalso", "@remarks", "@return", "@retval", "@sa", "@section", "@see",
   "@showinitializer", "@since", "@skip", "@skipline", "@struct", "@subpage", "@subsection",
   "@subsubsection", "@test", "@throw", "@todo", "@typedef", "@union", "@until",
   "@var", "@verbatim", "@verbinclude", "@version", "@warning", "@weakgroup", 
   "@xmlonly", "@xrefitem", 
   "@$", "@@", "@@", "@&", "@~", "@<", "@>", "@#", "@%"
};
_str gJavadocTagList[]= {
   "@author",
   "@version",
   "@param",
   "@return",
   "@example",
   "@exception",
   "@see",
   "@since",
   "@deprecated",
   "@serial",
   "@serialField",
   "@serialData",
   "@throws"
};
_command void c_atsign() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()) {
      call_root_key(last_event());
      return;
   }
   if (_MultiCursorAlreadyLooping()) {
      keyin("@");
      return;
   }
   if ( !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) || !_haveContextTagging()) {
      keyin("@");
      return;
   }
   _str line;
   //if (_in_comment() && _inJavadoc()) {
   if (_inDocComment()) {
      get_line(line);
      //if (line=='*' && p_col==_text_colc()+1 ) {
      if (onDocCommentBlankLine(line)) {
         keyin(last_event());
         _do_list_members(OperatorTyped:true, 
                          DisplayImmediate:true,
                          gDoxygenCommandsAtsign);
         return;
      }
   } else if (_LanguageInheritsFrom("java") || _LanguageInheritsFrom("m") || _LanguageInheritsFrom("c")) {
      get_line(line);
      if (line=="" && p_col==_text_colc()+1 ) {
         keyin(last_event());
         _do_list_members(OperatorTyped:true, DisplayImmediate:true);
         return;
      }
   }
   call_root_key(last_event());
}

_command void c_backslash() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()) {
      call_root_key(last_event());
      return;
   }
   if (_MultiCursorAlreadyLooping()) {
      keyin('\');
      return;
   }
   if ( !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) || !_haveContextTagging()) {
      keyin('\');
      return;
   }
   if (_inDocComment()) {
      get_line(auto line);
      //if (line=='*' && p_col==_text_colc()+1 ) {
      if (onDocCommentBlankLine(line)) {
         keyin(last_event());
         _do_list_members(OperatorTyped:true, 
                          DisplayImmediate:true,
                          gDoxygenCommandsBackslash);
         return;
      }
   }
   if (_clex_find(0,'g') == CFG_STRING) {
      if (p_col > 1 && get_text_left() == '\' && get_text_left(2) != '\\') {
         keyin(last_event());
         AutoCompleteTerminate();
         //keyin('\');
         return;
      }
      keyin(last_event());
      _do_list_members(OperatorTyped:true, DisplayImmediate:true);
      return;
   }
   call_root_key(last_event());
}

_command void c_percent() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()) {
      call_root_key(last_event());
      return;
   }
   if (_MultiCursorAlreadyLooping()) {
      keyin('%');
      return;
   }
   if ( !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) || !_haveContextTagging()) {
      keyin('%');
      return;
   }
   if (_clex_find(0,'g') == CFG_STRING) {
      if (p_col > 1 && get_text_left() == '%') {
         AutoCompleteTerminate();
         keyin(last_event());
         return;
      }
      keyin(last_event());
      _do_list_members(OperatorTyped:true, DisplayImmediate:true);
      return;
   }
   call_root_key(last_event());
}

static bool lang_supports_nested_fns()
{
   return (p_LangId == 'js');
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
bool _is_line_before_decl()
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // update the current context
   _UpdateContext(true);

   // what is under the cursor?
   type_name := "";
   context_id := tag_current_context();
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
      if ((!lang_supports_nested_fns() && tag_tree_type_is_func(type_name)) ||
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
      context_id = tag_nearest_context(p_RLine,SE_TAG_FILTER_ANYTHING,true);
   }
   if (context_id <= 0) {
      return false;
   }

   // the next item must be a function, class, namespace, or variable
   tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   if (!tag_tree_type_is_func(type_name) &&
       !tag_tree_type_is_class(type_name) &&
       !tag_tree_type_is_package(type_name) &&
       !tag_tree_type_is_data(type_name) &&
       type_name != "typedef") {
      return false;
   }

   // finally, the next item must start on the next line
   context_line := 0;
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
            if (line != "") {
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
bool _c_is_continued_statement()
{
   get_line(auto line);
   if ( pos('^[ \t]#([}]|)[ \t]*(else|catch)([ \t{(]|$)', line, 1, 'r')) {
      return true;
   }

   if ( line == "}" ) {
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
static _str gCancelledCompiler="";
void _prjopen_c_util()
{
   gCancelledCompiler="";
}

/**
 * If we do not already have a 'C' language tag file, create one
 * under certain circumstances.
 */
int _c_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // Find the active "C" compiler tag file
   compiler_name := refactor_get_active_config_name(_ProjectHandle());
   //say("_c_MaybeBuildTagFile: name="compiler_name);
   if (compiler_name != "" && compiler_name != gCancelledCompiler) {
      // put together the file name
      compilerTagFile := _tagfiles_path():+compiler_name:+TAG_FILE_EXT;
      if (!file_exists(compilerTagFile)) {
         status := refactor_build_compiler_tagfile(compiler_name, "cpp", false, useThread);
         if (status == COMMAND_CANCELLED_RC) {
            message("You pressed cancel.  You will have to build the tag file manually.");
            gCancelledCompiler = compiler_name;
         } else if (status == 0) {
            gCancelledCompiler = "";
         }
      }
   }

   // maybe we can recycle tag file(s)
   tagfilename := "";
   if (_isUnix()) {
      if (ext_MaybeRecycleTagFile(tfindex,tagfilename,"c","ucpp") && !forceRebuild) {
         return(0);
      }
   } else {
      if (!forceRebuild) {
         if (ext_MaybeRecycleTagFile(tfindex,tagfilename,"c","cpp") &&
             ext_MaybeRecycleTagFile(tfindex,tagfilename,"c","tornado":+def_tornado_version) &&
             ext_MaybeRecycleTagFile(tfindex,tagfilename,"c","prismp")) {
            return(0);
         }
      }
      AddTornadoTagFile();
      AddPrismPlusTagFile();
   }
   // recycling didn't work, might have to build tag files
   tfindex=0;
   return(0);
}
#if 1 /*!__UNIX__*/
int def_vtg_tornado=1;
int def_vtg_prismplus=1;
static int AddPrismPlusTagFile()
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (machine()!="WINDOWS"|| !def_vtg_prismplus) {
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
   _maybe_append_filesep(path);
   if (file_match(path"+d +x",1) == "") {
      return(1);
   }


   ext := "c";
   cTagFile := LanguageSettings.getTagFileList("c");
   // IF the user does not have an extension specific tag file for Slick-C
   status := 0;
   name_part := "prismp" :+ TAG_FILE_EXT;
   tagfilename := absolute(_tagfiles_path():+name_part);
   //say('name_info='name_info(tfindex));
   if ( !pos(name_part,cTagFile,1,_fpos_case) ||
       tag_read_db(tagfilename)==FILE_NOT_FOUND_RC) {
      tag_close_db(tagfilename);
      //status=shell('maketags -n "Tornado Libraries" -t -o '_maybe_quote_filename(tagfilename)' '_maybe_quote_filename(path:+'*.c')' '_maybe_quote_filename(path:+'*.h'));
      useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
      bg_opt := (useThread)? "-b":"";
      status=shell('maketags 'bg_opt' -n "pRISM+ Libraries" -t -o '_maybe_quote_filename(tagfilename)' '_maybe_quote_filename(path:+"*.h"));
      LanguageSettings.setTagFileList("c", tagfilename, true);
   }
   return(status);
}
static int AddTornadoTagFile()
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (machine()!="WINDOWS" || !def_vtg_tornado) {
      return(1);
   }
   command := _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\TornadoWorkspaceType\\shell\\open\\command","");
   if (command=="" || def_tornado_version==2) {
      command=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\TornadoSourceType\\shell\\open\\command","");
   }
   if (command=="") {
      return(1);
   }
   // command has --> H:\Tornado\host\X86-WI~1\bin\tornado.exe "%1"
   command=parse_file(command);
   path := strip_names(command,4);
   if (file_match(_maybe_quote_filename(path)" +d +x",1) == "") {
      return(1);
   }

   cTagFiles := LanguageSettings.getTagFileList("c");
   // IF the user does not have an extension specific tag file for Slick-C
   status := 0;
   name_part := "tornado":+def_tornado_version:+TAG_FILE_EXT;
   tagfilename := absolute(_tagfiles_path():+name_part);
   //say('name_info='name_info(tfindex));
   if (!pos(name_part,cTagFiles,1,_fpos_case) ||
       tag_read_db(tagfilename)==FILE_NOT_FOUND_RC) {
      tag_close_db(tagfilename);
      useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
      bg_opt := (useThread)? "-b":"";
      status=shell('maketags 'bg_opt' -n "Tornado Libraries" -t -o '_maybe_quote_filename(tagfilename)" "_maybe_quote_filename(path:+"*.h"));
      LanguageSettings.setTagFileList("c", tagfilename, true);
   }
   return(status);
}
int AddDotNetTagFile()
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (machine()!="WINDOWS") {
      return(1);
   }
   ext := "c";
   cTagFile := LanguageSettings.getTagFileList("c");
   // IF the user does not have an extension specific tag file for Slick-C
   status := 0;
   name_part := "dotnet" :+ TAG_FILE_EXT;
   tagfilename := absolute(_tagfiles_path():+name_part);
   if (pos(name_part,cTagFile,1,_fpos_case) == 0) {
      status = tag_read_db(tagfilename);
      if (status == FILE_NOT_FOUND_RC) {
         // show a toast message that the dot net tag files haven't been tagged
         msg := 'The .NET libraries have not been tagged yet.<br>To do that now, click <a href="<<cmd gui-make-tags">here</a>.';
         notifyUserOfWarning(ALERT_TAG_FILE_ERROR, msg, tagfilename, 0);
      } else {
         // close the database
         tag_close_db(tagfilename,true);
         // add the vtg file to the language
         LanguageSettings.setTagFileList("c", tagfilename, true);
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
   sys_cpp_file := _c_sys_ppedit_path();
   usr_cpp_file := _c_user_ppedit_path();
   if (_file_eq(sys_cpp_file,p_buf_name) || _file_eq(usr_cpp_file,p_buf_name)) {
      _actapp_cparse();
   }
}
void _actapp_cparse(_str gettingFocus="")
{
   index := find_index("cpp_reset",COMMAND_TYPE|PROC_TYPE);
   if (gettingFocus && index_callable(index)) {
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
 * @return bool
 */
bool _c_find_surround_lines(int &first_line, int &last_line,
                            int &num_first_lines, int &num_last_lines,
                            bool &indent_change,
                            bool ignoreContinuedStatements=false)
{
   //say("_c_find_surround_lines["__LINE__"]: IN");
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
      _first_non_blank();
      if (!_find_matching_paren(MAXINT, true)) {
         get_line(line);
         // make sure it's not an else statement or something silly
         if (pos('^( |\t)*\#(endif|endregion)', line, 1, 'R')) {
            last_line = p_RLine;

            // check the tagging to figure out num_first_lines
            startLine := scope := 0;

            // make sure that the context doesn't get modified by a background thread.
            se.tags.TaggingGuard sentry;
            sentry.lockContext(false);
            _UpdateStatements(true, false);

            tag := tag_current_statement();
            tag_get_detail2(VS_TAGDETAIL_statement_start_linenum, tag, startLine);
            tag_get_detail2(VS_TAGDETAIL_statement_scope_linenum, tag, scope);
            num_first_lines = scope - startLine + 1;

            // indent doesn't change based on preprocessing
            indent_change = false;

            // return true - we found it!
            return true;
         }
      }
      // something went wrong here, so just return false
      //say("_c_find_surround_lines["__LINE__"]: REGION FAIL");
      return false;
   }
   if ( line == "{" ) {

      // this could be the first line of the block
      first_line = p_RLine;
      num_first_lines = 1;

      // check if they have type 2 or type 3 braces
      if (first_line > 1) {
         _first_non_blank();
         up(); _end_line();
         tk := c_prev_sym();
         _first_non_blank();
         if (tk == ")" && _clex_find(0, 'g') == CFG_KEYWORD &&
             !ignoreContinuedStatements &&
             _c_find_surround_lines(first_line, last_line,
                                    num_first_lines, num_last_lines,
                                    indent_change, false)) {
            return true;
         }
         p_RLine = first_line;
      }

      // find the end of the brace block
      _first_non_blank();
      status = find_matching_paren(true,true);
      if (status) {
         //say("_c_find_surround_lines["__LINE__"]: PAREN FAIL");
         return false;
      }

      // see if we just have brace sitting alone on the end line,
      // or a brace with a superfluous semicolon
      get_line(line);
      braceFollowedByLineComment := pos('[ \t]*}[ \t]*//', line, 1, 'L') > 0;

      if (braceFollowedByLineComment || line == "}" || line == "};") {
         // calculate the number of trailing lines
         last_line = p_RLine;
         num_last_lines = 1;
         return true;
      }

      //say("_c_find_surround_lines["__LINE__"]: BRACE FAIL");
      return false;
   }

   // make sure that the line starts with a statement keyword
   _first_non_blank();
   have_leading_close_brace := false;
   if (get_text() == '}') {
      right();
      right();
      have_leading_close_brace = true;
   }  
   if (_clex_find(0, 'g') != CFG_KEYWORD) {
      //say("_c_find_surround_lines["__LINE__"]: NO KEYWORD");
      return false;
   }

   // see if we recognize the statement they are trying to unsurround
   have_expr := false;
   start_col := 0;
   word := cur_identifier(start_col);
   if (have_leading_close_brace) {
      switch (word) {
      case "else":
      case "catch":
      case "finally":
         break;
      default:
         //say("_c_find_surround_lines["__LINE__"]: KEYWORD AFTER BRACE FAIL");
         return false;
      }
   }
   switch (word) {
   case "if":
   case "while":
   case "for":
   case "using":
   case "switch":
   case "foreach":
   case "foreach_reverse":
      have_expr = true;
      break;
   case "do":
   case "loop":
   case "try":
   case "else":
      have_expr = false;
      break;
   default:
      //say("_c_find_surround_lines["__LINE__"]: KEYWORD FAIL");
      return false;
   }

   // this is good, we have the first line of a statement
   first_line = p_RLine;
   p_col+=length(word);

   // check for "else if" expression
   tk := "";
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
      if (p_LangId=="tcl") {
         if (tk != "{") {
            //say("_c_find_surround_lines["__LINE__"]: NO BRACE");
            return false;
         }
      } else {
         if (tk != "(") {
            //say("_c_find_surround_lines["__LINE__"]: NO PAREN");
            return false;
         }
      }

      // find the end of the conditional expression
      // move left one column to get on the outer paren
      p_col--;
      status = find_matching_paren(true,true);
      if (status) {
         //say("_c_find_surround_lines["__LINE__"]: MATCH PAREN FAIL");
         return false;
      }

      // skip the close paren (brace for Tcl)
      p_col++;
   }

   // the next token better be an open brace
   tk = c_next_sym();
   if (tk != "{") {
      //say("_c_find_surround_lines["__LINE__"]: BRACE FAIL");
      return false;
   }

   // check that we are at the end of the line (not counting comments)
   orig_line := p_RLine;
   save_pos(auto p);
   _clex_skip_blanks("h");
   if (p_RLine==orig_line && !at_end_of_line()) {
      //say("_c_find_surround_lines["__LINE__"]: NOT AND END OF LINE");
      return false;
   }

   // ok, now we know how many lines the statement starts with
   restore_pos(p);
   num_first_lines = p_RLine - first_line + 1;

   // find the matching close brace
   status = find_matching_paren(true,true);
   if (status) {
      //say("_c_find_surround_lines["__LINE__"]: PAREN FAIL");
      return false;
   }

   // the close brace is our initial guess at the last line
   last_line = p_RLine;

   // get the next token
   p_col++;
   save_pos(p);
   tk = c_next_sym();

   // special case for do { ... } while (condition);
   if (word == "do") {

      // check that we have the 'while' keyword next
      if (tk != 1 || c_sym_gtkinfo()!="while") {
         //say("_c_find_surround_lines["__LINE__"]: DO WHILE FAIL");
         return false;
      }

      // next we should find the open paren
      tk = c_next_sym();
      if (tk != "(") {
         //say("_c_find_surround_lines["__LINE__"]: DO WHILE PAREN FAIL");
         return false;
      }

      // find the end of the conditional expression
      status = find_matching_paren(true,true);
      if (status) {
         //say("_c_find_surround_lines["__LINE__"]: DO WHILE MATCH PAREN FAIL");
         return false;
      }

      // the next token should be the semicolon
      p_col++;
      tk = c_next_sym();
      if (tk != ";") {
         //say("_c_find_surround_lines["__LINE__"]: DO WHILE SEMI FAIL");
         return false;
      }

   } else {

      // can't unsurround a try with catches
      while (c_sym_gtkinfo()=="catch") {

         // next token must be an open paren
         tk = c_next_sym();
         if (tk != "(") {
            //say("_c_find_surround_lines["__LINE__"]: CATCH FAIL");
            return false;
         }

         // find the end of the catch expression
         left();
         status = find_matching_paren(true,true);
         if (status) {
            //say("_c_find_surround_lines["__LINE__"]: CATCH PAREN FAIL");
            return false;
         }

         // next token must be an open brace
         p_col++;
         tk = c_next_sym();
         if (tk != "{") {
            //say("_c_find_surround_lines["__LINE__"]: CATCH BRACE FAIL");
            return false;
         }

         // and the immediate next token must be a close brace
         tk = c_next_sym();
         if (tk != "}") {
            //say("_c_find_surround_lines["__LINE__"]: CATCH CLOSE BRACE FAIL");
            return false;
         }

         // the close brace is our initial guess at the last line
         save_pos(p);

         // check for 'finally'
         tk = c_next_sym();
      }

      // only can handle and else or finally if it's statement block is empty
      if (!ignoreContinuedStatements && (c_sym_gtkinfo()=="else" || c_sym_gtkinfo()=="finally")) {

         // next token must be an open brace
         tk = c_next_sym();
         if (tk != "{") {
            //say("_c_find_surround_lines["__LINE__"]: ELSE BRACE FAIL");
            return false;
         }

         // and the immediate next token must be a close brace
         tk = c_next_sym();
         if (tk != "}") {
            //say("_c_find_surround_lines["__LINE__"]: ELSE CLOSE BRACE FAIL");
            return false;
         }
      } else {

         // didn't find an else or finally, so go back to close brace
         restore_pos(p);
      }
   }

   // calculate the number of trailing lines
   num_last_lines = p_RLine - last_line + 1;
   //last_line = p_RLine;

   // check that we are at the end of the line, excluding comments
   save_pos(p);
   _clex_skip_blanks('h');
   if (p_RLine==last_line && !at_end_of_line()) {
      //say("_c_find_surround_lines["__LINE__"]: LAST LINE FAIL");
      return false;
   }

   // that's all folks
   return true;
}

bool _e_find_surround_lines(int &first_line, int &last_line,
                               int &num_first_lines, int &num_last_lines,
                               bool &indent_change,
                               bool ignoreContinuedStatements=false)
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
bool _cs_find_surround_lines(int &first_line, int &last_line,
                                int &num_first_lines, int &num_last_lines,
                                bool &indent_change,
                                bool ignoreContinuedStatements=false)
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
bool _java_find_surround_lines(int &first_line, int &last_line,
                                  int &num_first_lines, int &num_last_lines,
                                  bool &indent_change,
                                  bool ignoreContinuedStatements=false)
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
bool _awk_find_surround_lines(int &first_line, int &last_line,
                                 int &num_first_lines, int &num_last_lines,
                                 bool &indent_change,
                                 bool ignoreContinuedStatements=false)
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
bool _tcl_find_surround_lines(int &first_line, int &last_line,
                                 int &num_first_lines, int &num_last_lines,
                                 bool &indent_change,
                                 bool ignoreContinuedStatements=false)
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
bool _pl_find_surround_lines(int &first_line, int &last_line,
                                int &num_first_lines, int &num_last_lines,
                                bool &indent_change,
                                bool ignoreContinuedStatements=false)
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
bool _as_find_surround_lines(int &first_line, int &last_line,
                                int &num_first_lines, int &num_last_lines,
                                bool &indent_change,
                                bool ignoreContinuedStatements=false)
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change);
}
bool _cfscript_find_surround_lines(int &first_line, int &last_line,
                                      int &num_first_lines, int &num_last_lines,
                                      bool &indent_change,
                                      bool ignoreContinuedStatements=false)
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}
bool _phpscript_find_surround_lines(int &first_line, int &last_line,
                                       int &num_first_lines, int &num_last_lines,
                                       bool &indent_change,
                                       bool ignoreContinuedStatements=false)
{
   return _c_find_surround_lines(first_line, last_line, num_first_lines, num_last_lines, indent_change, ignoreContinuedStatements);
}


/**
 * This function gets additional function line comments for C/C++ languages.
 * This is allowed when there is a simple line comment following the opening
 * brace of a function definition.
 * <pre>
 *   int foobar()
 *   { // this is the comment
 *      return 0;
 *   }
 * </pre>
 *
 * @param first_line  (output) set to first line of comment
 * @param last_line   (output) set to last line of comment
 * @param start_col   (output) set to start column of comment
 *
 * @return 0 on success, <0 if comment is not found
 */
int _c_get_tag_additional_comments(int &first_line,int &last_line,int &start_col)
{
   // make sure we have an item under the current context
   _UpdateContext(true);
   context_id := tag_current_context();
   if (context_id <= 0) return STRING_NOT_FOUND_RC;
   tag_get_context_info(context_id, auto cm);

   // make sure it has an open brace starting it's scope
   save_pos(auto p);
   _GoToROffset(cm.scope_seekpos-1);
   if (get_text() != "{") {
      restore_pos(p);
      return STRING_NOT_FOUND_RC;
   }

   // check for a line comment immediately following the open brace
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   right();
   status := search("[^ \\t]", 'r');
   if (status < 0 || get_text(3) != "// ") {
      restore_search(s1,s2,s3,s4,s5);
      restore_pos(p);
      return STRING_NOT_FOUND_RC;
   }

   // scan down for continuation lines
   start_col = p_col;
   first_line = p_RLine;
   last_line = p_RLine;
   while (down()) {
      _first_non_blank();
      if (p_col != start_col) break;
      if (get_text(3) != "// ") break;
      last_line = p_RLine;
      if (last_line-first_line > def_codehelp_max_comments) break;
   }

   // that's all folks
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
   return 0;
}


/** 
 * If the user just typed '.', and the symbol to the left of the cursor evaluates 
 * to a pointer type, then automatically translate the '.' to a '->' symbol.
 * 
 * @note This function is designed to be called from {@link auto_codehelp_key()}, 
 *       or another callback designed to respond immediately to the '.' key.
 */
void c_auto_dot_to_dashgt()
{
   // return if not in an editor control
   if (!_isEditorCtl()) return;

   // verify language mode carefully, some languages derive from C++ but do not handle pointers or -> the same.
   langId := p_LangId;
   if (langId != "c" && langId != "m" && langId!="ansic" && langId!="e" && langId!="cpp" && langId!="ansicpp" && langId!="ch") return;

   // get the information about the expression under the cursor, bail on any sign of failure
   VS_TAG_IDEXP_INFO idexp_info;
   id_status := _Embeddedget_expression_info(true, langId, idexp_info);
   if (id_status < 0) return;

   // if prefix expression is valid and ends with a '.', as expected, keep going
   if (idexp_info.prefixexp == "" || _last_char(idexp_info.prefixexp) != ".") return;

   // evaluate the prefix expression immediately
   tag_files := tags_filenamea(langId);
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   prefix_status := _c_get_type_of_prefix(auto errorArgs, idexp_info.prefixexp, rt);

   // we are explicitely expecting this error code, success, or any other error code does not good.
   if (prefix_status != VSCODEHELPRC_DOT_FOR_POINTER) return;

   // we must have a valid return type otherwise, and a pointer count of 1.
   if (rt.return_type == "" && rt.pointer_count!=1) return;

   // all is good, create an undo step and do the substitution.
   if (!_macro('S')) _undo('S');
   left();
   _delete_text(1);
   _insert_text("->");

   // notify the user about the feature usage
   notifyUserOfFeatureUse(NF_AUTO_DOT_FOR_DASHGT);
}

static _str gOperatorNameMap:[]:[] = {
   "e" => {
      "="   => "copy",
      "<"   => "compare",
      "<="  => "compare",
      ">"   => "compare",
      ">="  => "compare",
      "=="  => "equals",
      "!="  => "equals",
      ":[]" => "_hash_el",
      "[]"  => "_array_el",
   },
   "d" => {
      "++"  => "opPostInc",
      "--"  => "opPostDec",
      "+"   => "opAdd",
      "-"   => "opSub",
      "*"   => "opMul",
      "/"   => "opDiv",
      "%"   => "opMod",
      "&"   => "opAnd",
      "|"   => "opOr",
      "^"   => "opXor",
      "<<"  => "opShl",
      ">>"  => "opShr",
      ">>>" => "opUShr",
      "~"   => "opCat",
      "=="  => "opEquals",
      "!="  => "opEquals",
      "< "  => "opCmp",
      "<="  => "opCmp",
      "> "  => "opCmp",
      ">="  => "opCmp",
      "= "  => "opAssign",
      "+="  => "opAddAssign",
      "-="  => "opSubAssign",
      "*="  => "opMulAssign",
      "/="  => "opDivAssign",
      "%="  => "opModAssign",
      "&="  => "opAndAssign",
      "|="  => "opOrAssign",
      "^="  => "opXorAssign",
      "<<=" => "opShlAssign",
      ">>=" => "opShrAssign",
      ">>>="=> "opUShrAssign",
      "~="  => "opCatAssign",
      "in"  => "opIn",
      "()"  => "opCall",
      "[]"  => "opIndex",
   }
};

/** 
 * @return 
 * Check the lookup table for an operator name for the given operator. 
 * Return the name if found, otherwise return <i>c_operator</i> as is.
 * 
 * @param c_operator     math or logic operator
 */
_str _c_get_operator_name(_str c_operator) {
   if ( gOperatorNameMap._indexin(p_LangId) && gOperatorNameMap:[p_LangId]._indexin(c_operator) ) {
      return gOperatorNameMap:[p_LangId]:[c_operator];
   }
   return "operator " :+ c_operator;
}

/**
 * Is the given search class part of the STL or boost or something related.
 */
bool _c_is_stl_class(_str search_class_name)
{
   if (search_class_name == "std"   ||
       search_class_name == "boost" ||
       pos("std/",search_class_name) == 1 || 
       pos("std:",search_class_name) == 1 || 
       pos("boost/",search_class_name) == 1 || 
       pos("boost:",search_class_name) == 1 || 
       pos("__gnu_debug/",search_class_name) == 1 ||
       pos("__gnu_cxx/",search_class_name) == 1) {
      return true;
   }
   return false;
}


/**
 * Call with the buffer position on the ']' of 
 * an array index operator.  (ie, somarr[x+1]) 
 * 
 * @param status 0 on success, otherwise returns a 
 *               VSCODEHELPRC_* error.
 * 
 * @return _str Returns the expression inside of the [], minus 
 *         any comments.
 */
_str _c_get_index_expression(int& status) 
{
   right_idx := _QROffset();

   right();

   rc := find_matching_paren(true);
   if (rc) {
      status = VSCODEHELPRC_CONTEXT_NOT_VALID;
      return "";
   }

   left_idx := _QROffset();

   rv := get_text_safe((int)(right_idx - left_idx), (int)left_idx+1);

   rv=stranslate(rv,'','\/\/?*[\n\r]','r');
   rv=stranslate(rv,'','[ \t\n\r]#','r');
   rv=stranslate(rv,'','\/\*?*\*\/','r');

   if (rv == "") {
      status = VSCODEHELPRC_CONTEXT_NOT_VALID;
      return rv;
   }

   status = 0;
   return rv;
}


// Unix regular expression matching java unicode literal. This is 
// a single quoted \u followed by a hexadecimal number.
// For example '\uABCD'
static const RE_MATCH_UNICODE_LITERAL=                      "(?:'[^']\\[ux][0-9A-F]+'|[L]'\\[0-9A-F]+')";

// Unix regular expression matching a double quoted string
// For example  "howdy"
static const RE_MATCH_C_DOUBLE_QUOTED_STRING_LITERAL=       "(?:\"[^\"]*\")";

// Unix regular expression matching a single quoted string
// For example  '\0' or '\233'
static const RE_MATCH_C_SINGLE_QUOTED_CHAR_LITERAL=         "(?:'[^']*')";

// Unix regular expression matching a hexadecimal literal appened with L or l to cast
// it to a long. Example 0xBADF00DL
static const RE_MATCH_C_HEXADECIMAL_LONG_LITERAL=           "(?:0x[0-9A-F]+L)";

// Unix regular expression matching a hexadecimal unsigned literal appened with u or U andL or l to cast
// it to an unsigned long. Example 0xBADF00DL
static const RE_MATCH_C_HEXADECIMAL_UNSIGNED_LONG_LITERAL=  "(?:0x[0-9A-F]+(UL|LU))";

// Unix regular expression matching a hexadecimal literal
// it to a long. Example 0xCAFEF00D. Note match Long literal before this.
static const RE_MATCH_C_HEXADECIMAL_INT_LITERAL=            "(?:0x[0-9A-F]+)";

// Unix regular expression matching a hexadecimal literal
// it to a long. Example 0xCAFEF00D. Note match Long literal before this.
static const RE_MATCH_C_HEXADECIMAL_UNSIGNED_INT_LITERAL=   "(?:0x[0-9A-F]+U)";

// Unix regular expression matching a decimal literal appended with L or l to cast
// it to a long. Example 550L
static const RE_MATCH_C_LONG_LITERAL=                       "(?:[0-9]+L)";

// Unix regular expression matching an unsigned decimal literal appended with L or l to cast
// it to a long. Example 550ul
static const RE_MATCH_C_UNSIGNED_LONG_LITERAL=              "(?:[0-9]+(UL|LU))";

// Unix regular expression matching a decimal literal Example 550
static const RE_MATCH_C_INT_LITERAL=                        "(?:[0-9]+)";

// Unix regular expression matching a decimal literal appended with U or Lto cast
// it to an unsigned Example 55U
static const RE_MATCH_C_UNSIGNED_INT_LITERAL=               "(?:[0-9]+U)";

// Unix regular expression matching a floating point literal appended with f or F to
// make it floating point precision.
static const RE_MATCH_C_FLOATING_POINT_LITERAL=             "(?:(?:[0-9]+(?:\\.[0-9]+|)|\\.[0-9]+)(?:[E](?:\\+|-|)[0-9]+|)[F])";

// Unix regular expression matching a floating point literal that is double precision. (no trailing f or F)
static const RE_MATCH_C_DOUBLE_PRECISION_LITERAL=           "(?:(?:[0-9]+(?:\\.[0-9]+|)|\\.[0-9]+)(?:[E](?:\\+|-|)[0-9]+|))";

// Unix regular expression matching a wide character string literal.
// For instance L"A string". This maps to a wchar_t *
static const RE_MATCH_C_WIDE_CHARACTER_LITERAL=             "(?:L\"[^\"]*\")";

// Unix regular expression matching a windows managed string literal
// For instance L"A string". This maps to a wchar_t *
static const RE_MATCH_C_MANAGED_STRING_LITERAL=             "(?:S\"[^\"]*\")";

// Unix regular expression matching an Objective-C string literal
// For instance @"A string". This maps to a NSString *
static const RE_MATCH_OBJC_STRING_LITERAL=                  "(?:[@]\"[^\"]*\")";


/**
 * Get the return type information for a string suspected of being a constant or literal
 * 
 * @param ch      String containing constant or literal to get type information about
 * @param rt      (out)Filled with the type information for the string passed in.
 * 
 * @return int returns 0 if the string type is successfully interpreted.
 * VSCODEHELPRC_RETURN_TYPE_NOT_FOUND otherwise
 */
int _c_get_type_of_constant(_str ch, struct VS_TAG_RETURN_TYPE &rt, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (_chdebug) {
      isay(depth, "_c_get_type_of_constant: CH="ch);
   }

   // Note: order matters in these checks.
   // Want to check the most specific to most general check.
   // For instance check for 57L (long integer) before you
   // check for integer because the integer check will pick 
   // out 57 as an integer.
   // Check for 5.1f (floating point check for trailing f) 
   // before checking for double. etc.
   VS_TAG_RETURN_TYPE orig_rt = rt;
   rt.filename = p_buf_name;
   rt.line_number = p_line;
   rt.template_args._makeempty();
   rt.template_names._makeempty();
   rt.template_types._makeempty();
   rt.return_flags = VSCODEHELP_RETURN_TYPE_CONST_ONLY; // ? 
   rt.pointer_count = 0;
   rt.istemplate = false;
   rt.taginfo = ""; // Not sure what to put in here

   // Do not limit methods to "const" in C#
   if ( _LanguageInheritsFrom("cs") ) rt.return_flags = 0;

   // Check to see if this literal is a string or character constant
   if (_LanguageInheritsFrom("e")) {
      // In Slick-C there are only string literals and then can have either single or double quotes
      if (pos(":q", ch, 1, "r") == 1) {
         rt.return_type = "_sc_lang_string";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Slick-C quotes string, rt="rt.return_type);
         }
         return 0;
      }   
   } else {
      // wide character string literal L"Blah"
      if (pos(RE_MATCH_C_WIDE_CHARACTER_LITERAL, ch, 1, "U") == 1 && _last_char(ch)=='"') {
         rt.return_type = "const wchar_t*";
         rt.pointer_count = 1;
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: wide character literal, rt="rt.return_type);
         }
         return 0;
      }

      // .NET managed string literal S"Blah"
      if (pos(RE_MATCH_C_MANAGED_STRING_LITERAL, ch, 1, "U") == 1 && _last_char(ch)=='"') {
         rt.return_type = "System/String";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: .NET / C# string, rt="rt.return_type);
         }
         return 0;
      }

      if (_first_char(ch) == '@' && _LanguageInheritsFrom("m")) {
         // Objective-C managed string literal S"Blah"
         if (pos(RE_MATCH_OBJC_STRING_LITERAL, ch, 1, "U") == 1 && _last_char(ch)=='"') {
            rt.return_type = "NSString";
            rt.pointer_count = 1;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: Objective-C string, rt="rt.return_type);
            }
            return 0;
         }
         // Objective-C array
         if (substr(ch, 1, 2) == "@[" && _last_char(ch)==']') {
            rt.return_type = "NSArray";
            rt.pointer_count = 1;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: Objective-C array, rt="rt.return_type);
            }
            return 0;
         }
         // Objective-C dictionary
         if (substr(ch, 1, 2) == "@{" && _last_char(ch)=='}') {
            rt.return_type = "NSDictionary";
            rt.pointer_count = 1;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: Objective-C dictionary, rt="rt.return_type);
            }
            return 0;
         }
      }


      // Is this a string literal? "Blah"
      if (pos(RE_MATCH_C_DOUBLE_QUOTED_STRING_LITERAL, ch, 1, "UI") == 1 && _last_char(ch)=='"') {
         if (_LanguageInheritsFrom("d")) {
            rt.return_type = "char";
            rt.pointer_count = 1;
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: D array of chars, rt="rt.return_type);
            }
         } else if (_LanguageInheritsFrom("c")) {
            rt.return_type = "const char*";
            rt.pointer_count = 1;
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: C char string, rt="rt.return_type);
            }
         } else if (_LanguageInheritsFrom("cs")) {
            rt.return_type = "System/String";
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: .NET / C# string, rt="rt.return_type);
            }
         } else if (_LanguageInheritsFrom("java") || _LanguageInheritsFrom("groovy")) {
            rt.return_type = "java/lang/String";
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: Java string, rt="rt.return_type);
            }
         } else if (_LanguageInheritsFrom("rs")) {
            rt.return_type = "alloc/str/str";
            rt.return_flags = 0; // no const
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: Rust string, rt="rt.return_type);
            }
         }
         return 0;
      }

      // Unix regular expression matching java unicode literal. This is 
      // a single quoted \u followed by a hexadecimal number.
      // For example '\uABCD'
      if (pos(RE_MATCH_UNICODE_LITERAL, ch, 1, "UI") == 1) {
         if (_LanguageInheritsFrom("d")) {
            rt.return_type = "wchar";
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: D wide character literal, rt="rt.return_type);
            }
         } else if (_LanguageInheritsFrom("c")) {
            rt.return_type = "wchar_t";
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: wide character literal, rt="rt.return_type);
            }
         } else {
            rt.return_type = "char";
            if (_chdebug) {
               isay(depth, "_c_get_type_of_constant: character literal, rt="rt.return_type);
            }
         }
         return 0;
      }

      // Is this a character literal?
      // Match any number of characters in the single quoted string to
      // catch '\0' and typos. 
      if (pos(RE_MATCH_C_SINGLE_QUOTED_CHAR_LITERAL, ch, 1, "UI") == 1) {
         rt.return_type = "char";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: single quoted character literal, rt="rt.return_type);
         }
         return 0;
      }
   }

   if (p_LangId == "groovy") {
      status := _groovy_get_type_of_number(ch, rt);
      if (status == 0) {
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Groovy numeric literal, rt="rt.return_type);
         }
         return 0;
      }

   } else if (_LanguageInheritsFrom("rs")) {
      // Floating point literal check 5.1f. Make sure there is a dot somewhere before deciding it is float.
      if (pos(RE_MATCH_C_FLOATING_POINT_LITERAL, ch, 1, "UI") == 1 && pos(".", ch, 1) != 0) {
         rt.return_type = "f32";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Rust 32-bit float, rt="rt.return_type);
         }
         return 0;
      }

      // Double 5.1. Make sure there is a dot somewhere before deciding it is float.
      if (pos(RE_MATCH_C_DOUBLE_PRECISION_LITERAL, ch, 1, "UI") == 1 && pos(".", ch, 1) != 0) {
         rt.return_type = "f64";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Rust 64-bit float, rt="rt.return_type);
         }
         return 0;
      }

      // Hexadecimal unsigned long 0xBADF00DLU or decimal unsigned long 550ul
      if (pos(RE_MATCH_C_HEXADECIMAL_UNSIGNED_LONG_LITERAL, ch, 1, "UI") == 1 ||
         pos(RE_MATCH_C_UNSIGNED_LONG_LITERAL, ch, 1, "UI") == 1) {
         rt.return_type = "u64";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Rust 64-bit unsigned int, rt="rt.return_type);
         }
         return 0;
      }

      // Hexadecimal long 0xBADF00DL or decimal long 550l
      if (pos(RE_MATCH_C_HEXADECIMAL_LONG_LITERAL, ch, 1, "UI") == 1 ||
         pos(RE_MATCH_C_LONG_LITERAL, ch, 1, "UI") == 1) {
         rt.return_type = "i64";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Rust 64-bit signed int, rt="rt.return_type);
         }
         return 0;
      }

      // Hexadecimal unsigned int 0xBadF00dU or decimal unsigned int 550U
      if (pos(RE_MATCH_C_HEXADECIMAL_UNSIGNED_INT_LITERAL, ch, 1, "UI") == 1 ||
         pos(RE_MATCH_C_UNSIGNED_INT_LITERAL, ch, 1, "UI") == 1) {
         rt.return_type = "u32";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Rust 32-bit unsigned int, rt="rt.return_type);
         }
         return 0;
      }

      // Hexadecimal int 0xBadF00d or decimal int 550
      if (pos(RE_MATCH_C_HEXADECIMAL_INT_LITERAL, ch, 1, "UI") == 1 ||
         pos(RE_MATCH_C_INT_LITERAL, ch, 1, "UI") == 1) {
         rt.return_type = "i32";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Rust 32-bit signed int, rt="rt.return_type);
         }
         return 0;
      }

   } else {
      // Floating point literal check 5.1f. Make sure there is a dot somewhere before deciding it is float.
      if (pos(RE_MATCH_C_FLOATING_POINT_LITERAL, ch, 1, "UI") == 1 && pos(".", ch, 1) != 0) {
         rt.return_type = "float";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: single precision float, rt="rt.return_type);
         }
         return 0;
      }

      // Double 5.1. Make sure there is a dot somewhere before deciding it is float.
      if (pos(RE_MATCH_C_DOUBLE_PRECISION_LITERAL, ch, 1, "UI") == 1 && pos(".", ch, 1) != 0) {
         rt.return_type = "double";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: double precision float, rt="rt.return_type);
         }
         return 0;
      }

      // Hexadecimal unsigned long 0xBADF00DLU or decimal unsigned long 550ul
      if (pos(RE_MATCH_C_HEXADECIMAL_UNSIGNED_LONG_LITERAL, ch, 1, "UI") == 1 ||
         pos(RE_MATCH_C_UNSIGNED_LONG_LITERAL, ch, 1, "UI") == 1) {
         rt.return_type = "unsigned long";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: unsigned long int, rt="rt.return_type);
         }
         return 0;
      }

      // Hexadecimal long 0xBADF00DL or decimal long 550l
      if (pos(RE_MATCH_C_HEXADECIMAL_LONG_LITERAL, ch, 1, "UI") == 1 ||
         pos(RE_MATCH_C_LONG_LITERAL, ch, 1, "UI") == 1) {
         rt.return_type = "long";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: long int, rt="rt.return_type);
         }
         return 0;
      }

      // Hexadecimal unsigned int 0xBadF00dU or decimal unsigned int 550U
      if (pos(RE_MATCH_C_HEXADECIMAL_UNSIGNED_INT_LITERAL, ch, 1, "UI") == 1 ||
         pos(RE_MATCH_C_UNSIGNED_INT_LITERAL, ch, 1, "UI") == 1) {
         rt.return_type = "unsigned int";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: unsigned int, rt="rt.return_type);
         }
         return 0;
      }

      // Hexadecimal int 0xBadF00d or decimal int 550
      if (pos(RE_MATCH_C_HEXADECIMAL_INT_LITERAL, ch, 1, "UI") == 1 ||
         pos(RE_MATCH_C_INT_LITERAL, ch, 1, "UI") == 1) {
         rt.return_type = "int";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: int, rt="rt.return_type);
         }
         return 0;
      }
   }

   // Boolean constant
   if (ch:=="true" || ch:=="false") {
      rt.return_type = "bool";
      if (_chdebug) {
         isay(depth, "_c_get_type_of_constant: true or false, rt="rt.return_type);
      }
      return 0;
   }

   // Null object constant (java and C# and groovy)
   if (ch:=="null") {
      if (_LanguageInheritsFrom("java")) {
         rt.return_type = "java/lang/Object";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Java null, rt="rt.return_type);
         }
         return 0;
      } else if (_LanguageInheritsFrom("cs")) {
         rt.return_type = "System/Object";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: C# null, rt="rt.return_type);
         }
         return 0;
      } else if (_LanguageInheritsFrom("e")) {
         rt.return_type = "typeless";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Slick-C null, rt="rt.return_type);
         }
         return 0;
      }
   }

   // Objective-C null objects
   if (_LanguageInheritsFrom("m")) {
      if (ch :== "NULL" || ch :== "nullptr") {
         rt.return_type = "void";
         rt.pointer_count = 1;
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Objective C NULL or nullptr, rt="rt.return_type);
         }
         return 0;
      } else if (ch :== "nil") {
         rt.return_type = "Object";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Objective C nil, rt="rt.return_type);
         }
         return 0;
      } else if (ch :== "Nil") {
         rt.return_type = "Class";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Objective C Nil, rt="rt.return_type);
         }
         return 0;
      } else if (ch :== "NSNull") {
         rt.return_type = "NSNull";
         if (_chdebug) {
            isay(depth, "_c_get_type_of_constant: Objective C NSNull, rt="rt.return_type);
         }
         return 0;
      }
   }

   // Pointer constant
   if (ch:=="null" || ch:=="NULL" || ch:=="nullptr") {
      rt.return_type = "void";
      rt.pointer_count = 1;
      if (_chdebug) {
         isay(depth, "_c_get_type_of_constant: other ponter constant, rt="rt.return_type);
      }
      return 0;
   }

   // might not be a constant
   rt = orig_rt;
   return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
}

// check if this return type uses "auto" for type inference
// 
//    a := 4;     // Java, Slick-C
//    auto b = 3; // C++, Slick-C
//    var c = 2;  // C#
// 
bool _c_is_type_inferred(_str return_type, bool &add_const=true)
{
   // language independent initializer based type inference 
   if (substr(return_type, 1, 1) == "=") {
      return true;
   }

   // type inference only supported for C++, Slick-C, C#, Java, Groovy, and Rust.
   if (!_LanguageInheritsFrom("c") && 
       !_LanguageInheritsFrom("e") && 
       !_LanguageInheritsFrom("cs") &&
       !_LanguageInheritsFrom("java") &&
       !_LanguageInheritsFrom("groovy") &&
       !_LanguageInheritsFrom("kotlin") &&
       !_LanguageInheritsFrom("rs")) {
      return false;
   }

   // Slick-C auto type inferred declarations
   // Get the type from the RHS of the expression.
   found_auto := false;
   while (return_type != "") {

      // strip leading spaces
      if (substr(return_type, 1, 1) :== " ") {
         return_type = strip(return_type);
         continue;
      }

      // strip leading 'const' keyword
      if (length(return_type)>=6 && 
          substr(return_type, 1, 5)=="const" && 
          !isid_valid(substr(return_type, 6, 1))) {
         add_const=true;
         return_type = substr(return_type, 6);
         continue;
      }

      // strip leading 'class' keyword
      if (length(return_type)>=6 && 
          substr(return_type, 1, 5)=="class" && 
          !isid_valid(substr(return_type, 6, 1))) {
         found_auto = true;
         return_type = substr(return_type, 6);
         continue;
      }

      // strip * or & (pointer or reference)
      first_ch := substr(return_type,1,1);
      if (first_ch=="*" || first_ch=="&" || first_ch=="^" || first_ch=="%") {
         return_type = substr(return_type, 2);
         continue;
      }

      // strip [] (array args)
      if (substr(return_type, 1, 1)=="[") {
         num_args := 0;
         if (!match_brackets(return_type, num_args)) return false;
         continue;
      }

      // check for auto keyword
      if (length(return_type)>=5 && 
          substr(return_type, 1, 4)=="auto" && 
          !isid_valid(substr(return_type, 5, 1))) {
         found_auto=true;
         return_type = substr(return_type, 5);
         continue;
      }

      // check for decltype(auto)
      if (length(return_type)>=15 && 
          substr(return_type, 1, 14)=="decltype(auto)" && 
          !isid_valid(substr(return_type, 15, 1))) {
         found_auto=true;
         return_type = substr(return_type, 15);
         continue;
      }

      // check for C# or Java var keyword
      if ((_LanguageInheritsFrom("cs") || _LanguageInheritsFrom("java")) &&
          length(return_type)>=4 && 
          substr(return_type, 1, 3)=="var" && 
          !isid_valid(substr(return_type, 4, 1))) {
         found_auto=true;
         return_type = substr(return_type, 4);
         continue;
      }


      if (p_LangId == "groovy" && length(return_type) >= 4 &&
          substr(return_type, 1, 4) == "def ") {
         found_auto=true;
         return_type = strip(substr(return_type, 4), "L");
         continue;
      }

      // check for initializer expression
      if (substr(return_type, 1, 1)=="=" || substr(return_type,1,2)==":=") {
         return found_auto;
      }

      // if we see anything else, we are out of here
      return false;
   }

   // May have found "auto", but did not find initializer
   return false;
}


/**
 * Substitute actual template parameters for the template parameters
 * found in the template class's template signature.
 * 
 * @param search_class_name     class we are searching from matches within
 * @param file_name             file containing matches
 * @param isjava                is this Java or Java-like source?
 * @param template_parms        List of actual template arguments (may be empty)
 * @param template_sig          Template signature from template class
 * @param template_args         [output] hash table of template arguments
 * @param template_names        [output] ordered array of template argument names 
 * @param is_variadic_template  [output] set to true if this is a variadic template 
 * @param template_class_name   [input] name of template class 
 * @param template_file         [input] name of file template class comes from
 * @param tag_files             array of tag files
 * @param visited               [reference] problems already solved
 * @param depth                 depth of recursive search
 */
int _c_substitute_template_args( _str search_class_name, 
                                 _str file_name, bool isjava,
                                 _str (&template_parms)[], 
                                 _str template_sig,
                                 _str (&template_args):[], 
                                 _str (&template_names)[],
                                 VS_TAG_RETURN_TYPE (&template_types):[],
                                 bool &is_variadic_template,
                                 _str template_class_name, 
                                 _str template_file,
                                 typeless tag_files, 
                                 VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (_chdebug) {
      isay(depth,"_c_substutite_template_args: ===================================================");
      isay(depth,"_c_substitute_template_args: template_class="template_class_name" search_class="search_class_name);
      isay(depth,"_c_substitute_template_args: template_sig="template_sig" num_param="template_parms._length());
      for (i:=0; i<template_parms._length(); i++) {
         isay(depth+1, "_c_substitute_template_args: template_parms["i"]="template_parms[i]);
      }
      tag_return_type_init(auto tmp_rt);
      tmp_rt.istemplate = true;
      tmp_rt.template_args  = template_args;
      tmp_rt.template_names = template_names;
      tmp_rt.template_types = template_types;
      tag_return_type_dump(tmp_rt, "_c_substitute_template_args", depth);
   }

   // save the original template arguments (from the context of the template ID)
   num_template_parms  := template_parms._length();
   orig_template_args  := template_args;
   orig_template_names := template_names;
   orig_template_types := template_types;

   // initialize the "output" template argument lists we are building
   template_args._makeempty();
   template_names._makeempty();
   template_types._makeempty();

   variadic_id := null;
   id := "";
   i := arg_pos := 0;
   argument := "";
   tag_get_next_argument(template_sig, arg_pos, argument);
   while (argument != "") {
      // just keep the last word of the argument string (kludge)
      if (_chdebug) {
         isay(depth,"_c_substitute_template_args: cb_next_arg returns "argument" arg_pos="arg_pos" sig="template_sig);
         if (i < template_parms._length()) {
            isay(depth, "_c_substitute_template_args: template_parms["i"]="template_parms[i]);
         }
      }

      last_argument := argument;
      variadic_template_argument := false;
      missing_template_argument  := false;
      for (;;) {
         p := pos('^ @{:v|'_clex_identifier_re()'|?}', argument, 1, 'r');
         n := pos('0');
         if (argument=="" || !p) {
            if (i >= template_parms._length()) {
               template_parms[i]=id;
               missing_template_argument = true;
               if (_chdebug) {
                  isay(depth, "_c_substitute_template_args: MISSING TEMPLATE ARG, using "id);
               }
            }
            break;
         }
         p = pos('S0');
         id = substr(argument, p, n);
         argument = substr(argument, p+n);
         if (_chdebug) {
            isay(depth, "_c_substitute_template_args: ID="id" ARG="argument);
         }
         if (pos(' *=',argument,1,'r')==1) {
            //isay(depth, "_c_substitute_template_args: argument="substr(argument, pos('')+1)" len="template_parms._length()" i="i);
            if (i >= template_parms._length()) {
               template_parms[i] = substr(argument, pos('')+1);
            }
            argument="";
         } else if (pos(' *extends ',argument,1,'r')==1) {
            //isay(depth, "_c_substitute_template_args: argument=" substr(argument, pos('')+1)" len="template_parms._length()" i="i);
            if (i >= template_parms._length()) {
               template_parms[i] = substr(argument, pos('')+1);
            }
            argument="";
         } else if (pos(' *\.\.\.',argument,1,'r')==1) {
            // variadic arguments?
            argument = substr(argument, pos('')+1);
            variadic_template_argument = true;
            is_variadic_template = true;
         } else if (i >= template_parms._length() && _LanguageInheritsFrom('java')) {
            template_parms[i]="java.lang.Object";
         }
      }
      if (variadic_id != null && variadic_id != "") {
         id = variadic_id;
      }

      //isay(depth,"_c_substitute_template_args: argument="argument);
      if (i < template_parms._length() && template_parms[i] != "") {
         if (_chdebug) {
            isay(depth, "_c_substitute_template_args["i"]: TEMPLATE ARG: "id"-->"template_parms[i]);
         }
         template_search_class_name := "";
         template_file_name := "";
         tag_return_type_init(auto rt_arg);
         if (i < num_template_parms) {
            rt_arg.template_args=orig_template_args;
            rt_arg.template_names=orig_template_names;
            rt_arg.template_types=orig_template_types;
            template_search_class_name=search_class_name;
            template_file_name=file_name;
         } else {
            rt_arg.template_args=template_args;
            rt_arg.template_names=template_names;
            rt_arg.template_types=template_types;
            template_search_class_name = template_class_name;
            template_file_name = template_file;
         }
         rt_arg.istemplate=true;

         status := 0;
         _str errorArgs[];

         //isay(depth, "_c_substitute_template_args: search_class="search_class_name" file="file_name);
         if (_LanguageInheritsFrom("java")) {
            template_parms[i] = strip(template_parms[i]);
            if (template_parms[i]=="?") {
               template_parms[i]="java.lang.Object";
            }
            if (substr(template_parms[i],1,1)=="?") {
               extends_kw := "";
               rest := "";
               parse template_parms[i] with "?" extends_kw rest;
               if (extends_kw=="extends") {
                  template_parms[i] = strip(rest);
               }
            }
         }

         if (template_parms[i] != "") {

            tag_push_matches();
            status = _c_parse_return_type(errorArgs, tag_files,
                                          "", template_search_class_name,
                                          template_file_name, template_parms[i],
                                          isjava, rt_arg,
                                          visited, depth+1);
            //if (status < 0) {
            //   if (_chdebug) {
            //      isay(depth, "_c_substitute_template_args: NOT A TYPE, try expression");
            //   }
            //   status = _c_get_type_of_expression(errorArgs, tag_files,
            //                                      template_parms[i],
            //                                      rt_arg, visited,depth, 0,
            //                                      "", template_search_class_name);
            //}
            if (status < 0 && missing_template_argument) {
               if (id :== "_IsSmall") {
                  tag_return_type_init(rt_arg);
                  rt_arg.return_type = "false";
                  status = 0;
               }
            }

            if (_chdebug) {
               rt_arg_string := rt_arg.return_type;
               if (rt_arg.istemplate) {
                  strappend(rt_arg_string,"<");
                  j := 0;
                  for (j=0; j<rt_arg.template_names._length(); ++j) {
                     el := rt_arg.template_names[j];
                     if (j > 0) strappend(rt_arg_string,",");
                     if (rt_arg.template_args._indexin(el)) {
                        strappend(rt_arg_string,rt_arg.template_args:[el]);
                     } else if (template_args._indexin(el)) {
                        strappend(rt_arg_string,template_args:[el]);
                     } else {
                        strappend(rt_arg_string, el);
                     }
                  }
                  strappend(rt_arg_string,">");
               }
               isay(depth,"_c_substitute_template_args: rt_string="rt_arg_string);
               tag_return_type_dump(rt_arg,"_c_substitute_template_args(AFTER)",depth);
            }

            tag_pop_matches();
         }

         if (!template_args._indexin(id)) {
            template_names :+= id;
         }
         if (status==VSCODEHELPRC_BUILTIN_TYPE) status=0;
         if (!status && rt_arg != null && rt_arg.return_type != null && rt_arg.return_type!="") {
            arg_return_type := tag_return_type_string(rt_arg, printArgNames:false);
            if (isjava) {
               arg_return_type = stranslate(arg_return_type,".",":");
               arg_return_type = stranslate(arg_return_type,".","/");
            } else {
               arg_return_type = stranslate(arg_return_type,"::",":") :+ substr("",1,rt_arg.pointer_count,"*");
            }
            template_args:[id] = arg_return_type;
            template_types:[id] = rt_arg;
            if (_chdebug) {
               isay(depth,"_c_substitute_template_args: parsed return type, id="id" rt_arg="arg_return_type);
            }

         } else if (template_parms[i] != "") {
            if (_chdebug) {
               isay(depth,"_c_substitute_template_args: status="status" return_type="rt_arg.return_type);
            }
            template_args:[id] = template_parms[i];
         }
         if (status == TAGGING_TIMEOUT_RC) {
            return status;
         }
      } else {
         // re-construct original template arguments if we did not have a
         // parameter type or default value for this one.
         orig_id := orig_template_names[i];
         if (orig_id != "") {
            template_names[i] = orig_id;
            if (orig_template_args._indexin(orig_id)) {
               template_args:[orig_id] = orig_template_args:[orig_id];
            }
            if (orig_template_types._indexin(orig_id)) {
               template_types:[orig_id] = orig_template_types:[orig_id];
            }
         }
         if (id != orig_id) {
            if (orig_id == "") {
               template_names[i] = id;
            }
            if (orig_template_args._indexin(id)) {
               template_args:[id] = orig_template_args:[id];
            }
            if (orig_template_types._indexin(id)) {
               template_types:[id] = orig_template_types:[id];
            }
         }
      }
      tag_get_next_argument(template_sig, arg_pos, argument);
      ++i;

      // last argument of variadic template argument list?
      if (variadic_template_argument && argument == "" && i < num_template_parms) {
         argument = last_argument;
         if (variadic_id == null) {
            variadic_id = id:+"+0";
            template_args:[variadic_id]  = template_args:[id];
            template_types:[variadic_id] = template_types:[id];
            variadic_id = id:+"+1";
         } else {
            underscore_pos := lastpos('+', variadic_id);
            arg_number := (int)(substr(variadic_id, underscore_pos+1));
            variadic_id = substr(variadic_id, 1, underscore_pos) :+ (arg_number+1);
         }
      }
   }

   // that's all folks
   return 0;
}

/**
 * Look for inherited template arguments.  See example.
 * <pre>
 *    class A {
 *       int x,y,z;
 *    };
 *    template&lt;typename T&gt; class B {
 *    public:
 *       T* create();
 *    };
 *    class C: public B&lt;A&gt; {
 *    };
 *    void foobar(C* x) {
 *       x->create()->z;
 *    }
 * </pre>
 * 
 * @param errorArgs          array of strings for error message arguments
 *                           refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files          list of extension specific tag files
 * @param tag_class_name     class that the the tag was found in
 * @param search_class_name  derived class
 * @param file_name          where is the tag's class defined
 * @param rt                 return_type to add template argumetns to
 * @param visited            (reference) types analyzed thus far
 * @param depth              search depth, to prevent recursion
 * 
 * @return 0
 */
int _c_get_inherited_template_args(_str (&errorArgs)[], 
                                   typeless tag_files,
                                   _str tag_class_name, 
                                   _str search_class_name, 
                                   _str file_name,
                                   struct VS_TAG_RETURN_TYPE &rt,
                                   VS_TAG_RETURN_TYPE (&visited):[], 
                                   int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_c_get_inherited_template_args: tag_class="tag_class_name" search_class="search_class_name);
      tag_return_type_dump(rt, "_c_get_inherited_template_args", depth);
   }

   // stop if this has gone too far
   if (depth > VSCODEHELP_MAXRECURSIVETYPESEARCH) {
      if (_chdebug) {
         isay(depth, "_c_get_inherited_template_args: recursion too deep");
      }
      return 1;
   }

   // make sure that there is a derivation relationship
   if (tag_class_name == search_class_name) {
      if (_chdebug) {
         isay(depth, "_c_get_inherited_template_args: SAME CLASS");
      }
      return 1;
   }
   if (tag_class_name == "" || search_class_name=="") {
      if (_chdebug) {
         isay(depth, "_c_get_inherited_template_args: MISSING CLASS NAME ARGUMENTS");
      }
      return 1;
   }
   if (!tag_is_parent_class(tag_class_name, search_class_name,
                            tag_files, true, true, 
                            file_name, visited, depth+1)) {
      if (_chdebug) {
         isay(depth, "_c_get_inherited_template_args: "search_class_name" does not derive from "tag_class_name);
      }
      return 1;
   }

   // get this classes's parents
   in_tag_files := "";
   parents := cb_get_normalized_inheritance(search_class_name, in_tag_files, tag_files, true, "", file_name, "", true, visited, depth+1);
   if (parents == "") {
      parents = cb_get_normalized_inheritance(search_class_name, in_tag_files, tag_files, true, "", "", "", true, visited, depth+1);
   }
   if (_chdebug) {
      isay(depth, "_c_get_inherited_template_args: parents="parents);
   }

   // for each parent
   while (parents != "") {

      // get the parent class, this may include template arguments
      parent_class := "";
      parse parents with parent_class VS_TAGSEPARATOR_parents parents;

      // strip off the template arguments
      parent_no_templates := parent_class;
      if (_LanguageInheritsFrom("d")) {
         parse parent_no_templates with parent_no_templates "!(";
      } else {
         parse parent_no_templates with parent_no_templates "<";
      }

      // split the class name
      template_inner := template_outer := "";
      tag_split_class_name(parent_no_templates, template_inner, template_outer);

      // parse the parent class as a return type to evaluate everything
      VS_TAG_RETURN_TYPE parent_rt;
      tag_return_type_init(parent_rt);
      parent_rt.template_args  = rt.template_args;
      parent_rt.template_names = rt.template_names;
      parent_rt.template_types = rt.template_types;
      status := _c_parse_return_type(errorArgs, tag_files, 
                                     template_inner, search_class_name,
                                     file_name, parent_class, 
                                     false, parent_rt, 
                                     visited, depth+1);
      if (_chdebug) {
         isay(depth, "_c_get_inherited_template_args: status="status);
         tag_return_type_dump(parent_rt, "_c_get_inherited_template_args", depth);
      }

      // if successful, transfer the template arguments and quit
      if (status == TAGGING_TIMEOUT_RC) {
         if (_chdebug) {
            isay(depth, "_c_get_inherited_template_args: TIMEOUT");
         }
         return status;
      }
      if (!status && tag_compare_classes(parent_rt.return_type, tag_class_name)==0) {
         if (parent_rt.istemplate) {
            rt.template_args  = parent_rt.template_args;
            rt.template_names = parent_rt.template_names;
            rt.template_types = parent_rt.template_types;
            rt.istemplate = true;
         }
         return 0;
      }

      // recursively attempt to get the parents of this parent
      status = _c_get_inherited_template_args(errorArgs, tag_files,
                                              tag_class_name, parent_no_templates, file_name,
                                              parent_rt, visited, depth+1);
      if (status == TAGGING_TIMEOUT_RC) {
         if (_chdebug) {
            isay(depth, "_c_get_inherited_template_args: TIMEOUT (INHERITED)");
         }
         return status;
      }
      if (!status) {
         rt = parent_rt;
         return 0;
      }
   }

   // no luck
   if (_chdebug) {
      isay(depth, "_c_get_inherited_template_args: NO TEMPLATE ARGS FOUND");
   }
   return 1;
}


/**
 * Evaluate the return type of the i'th non-stack member variable in the 
 * given struct (rt).
 * 
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_
 * @param tag_files           list of extension specific tag files
 * @param rt                  (reference) set to return type result
 * @param array_i             index of struct item to extract
 * @param visited             (reference) prevent recursion, cache results
 * @param depth               depth of recursion (for handling typedefs)
 * 
 * @return 0 on success, &lt;0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
int _c_get_return_type_of_structured_binding(_str (&errorArgs)[], typeless tag_files,
                                             struct VS_TAG_RETURN_TYPE &rt, int array_i,
                                             struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if ( _chdebug ) {
      isay(depth, "_c_get_return_type_of_structured_binding: rt.return_type="rt.return_type" i="array_i);
      tag_return_type_dump(rt, "_c_get_return_type_of_structured_binding:", depth+1);
   }

   // push the match set, just in case if we need to
   tag_push_matches();
   num_matches := 0;
   orig_rt := rt;
   status := 0;

   // is this std::tuple, std::pair, or std::variadic
   if (_c_is_stl_class(rt.return_type)) {
      if (_chdebug) {
         isay(depth, "_c_get_return_type_of_structured_binding: STL");
      }
      return_type := stranslate(rt.return_type, VS_TAGSEPARATOR_package, "::");
      return_type  = stranslate(return_type, VS_TAGSEPARATOR_package, ":");
      if (return_type == "std/tuple"   || 
          return_type == "std/variant" || 
          return_type == "std/pair"    || 
          return_type == "std/triple"  ||
          return_type == "std/array"   ||
          return_type == "std/vector"  ) {
         if (_chdebug) {
            isay(depth, "_c_get_return_type_of_structured_binding: STL TUPLE CASE");
         }
         if (return_type == "std/array" || return_type == "std/vector") {
            array_i = 0;
         }
         if (rt.istemplate && array_i < rt.template_names._length()) {
            template_param_name := rt.template_names[array_i];
            if (rt.template_types._indexin(template_param_name)) {
               template_rt := rt.template_types:[template_param_name];
               if (template_rt != null) {
                  if ( _chdebug ) {
                     isay(depth, "_c_get_return_type_of_structured_binding: EASY TUPLE status="status" rt.return_type="rt.return_type);
                     tag_return_type_dump(template_rt, "_c_get_return_type_of_structured_binding", depth);
                  }
                  tag_pop_matches();
                  rt = template_rt;
                  return 0;
               }
            }
            if (rt.template_args._indexin(template_param_name)) {
               return_type = rt.template_args:[template_param_name];
               if (return_type != null && return_type != "") {
                  status = _c_parse_return_type(errorArgs, tag_files, 
                                                template_param_name, rt.return_type, 
                                                rt.filename, return_type, 
                                                false, rt, 
                                                visited, depth+1);
                  if ( _chdebug ) {
                     isay(depth, "_c_get_return_type_of_structured_binding: TUPLE status="status" rt.return_type="rt.return_type);
                     tag_return_type_dump(rt, "_c_get_return_type_of_structured_binding", depth);
                  }
                  if ( status >= 0 ) {
                     tag_pop_matches();
                     return status;
                  }
               }
            }
         }

         // just give up
         tag_pop_matches();
         rt = orig_rt;
         return VSCODEHELPRC_SUBSCRIPT_BUT_NOT_ARRAY_TYPE;
      }
   }

   status = tag_list_in_class("", rt.return_type, 
                              0, 0, tag_files, 
                              num_matches, def_tag_max_list_matches_symbols, 
                              SE_TAG_FILTER_MEMBER_VARIABLE|SE_TAG_FILTER_PROPERTY, 
                              SE_TAG_CONTEXT_ONLY_NON_STATIC, 
                              false, p_LangCaseSensitive, 
                              rt.template_args, null, 
                              visited, depth+1);
   if ( _chdebug ) {
      isay(depth, "_c_get_return_type_of_structured_binding: status="status" num_matches="num_matches);
   }
   if (status >= 0 && num_matches > 0 && array_i < num_matches) {
      tag_get_all_matches(auto vars);
      vars._sort("",0,-1,tag_browse_info_compare_locations);
      if ( _chdebug ) {
         isay(depth, "_c_get_return_type_of_structured_binding: member["array_i"]="vars[array_i].member_name);
      }
      status = _c_get_return_type_of(errorArgs,
                                     tag_files,
                                     vars[array_i].member_name, 
                                     rt.return_type, 0,
                                     isjava:false, 
                                     SE_TAG_FILTER_MEMBER_VARIABLE|SE_TAG_FILTER_PROPERTY,
                                     maybe_class_name:false, 
                                     filterFunctionSignatures:false, 
                                     rt, 
                                     visited, 
                                     depth+1, 
                                     SE_TAG_CONTEXT_ONLY_NON_STATIC, 
                                     substituteTemplateArguments:true);
      if ( _chdebug ) {
         isay(depth, "_c_get_return_type_of_structured_binding: status="status" rt.return_type="rt.return_type);
         tag_return_type_dump(rt, "_c_get_return_type_of_structured_binding", depth);
      }
      if ( status >= 0 ) {
         tag_pop_matches();
         return status;
      }
   }
   tag_pop_matches();
   rt = orig_rt;
   return VSCODEHELPRC_SUBSCRIPT_BUT_NOT_ARRAY_TYPE;
}

/**
 * Obfuscate a group of files. 
 * All the files will be obuscated and then left open in the editor.
 *  
 * @param file_names    list of files to obfuscate (may include wildcards)
 *  
 * @categories Refactoring_Functions
 */
_command void obfuscate_files(_str file_names="") name_info(FILE_ARG'*,')
{
   if (file_names == "") {
      file_names = prompt();
   }

   orig_wid := _create_temp_view(auto temp_wid);
   status := insert_file_list("-v -d +p " :+ file_names);
   if (status < 0) {
      _delete_temp_view(temp_wid);
      _message_box(get_message(status, file_names));
      return;
   }

   _str file_list[];
   fail := false;
   count := 0;
   top();
   do {
      get_line(auto f);
      f = strip(f);
      if (f == "") break;
      if (isdirectory(f)) {
         _message_box("Can not obfuscate directory: ":+f);
         fail = true;
         break;
      } else if (!file_exists(f)) {
         _message_box("File does not exist: ":+f);
         fail = true;
         break;
      } else {
         file_list :+= f;
      }

   } while (!down());

   _delete_temp_view(temp_wid);
   activate_window(orig_wid);

   // any problems listing files?
   if (fail) {
      return;
   }

   foreach (auto f in file_list) {
      status = edit(_maybe_quote_filename(f));
      if (status < 0) {
         _message_box("Unable to open: ":+f:+" ":+get_message(status));
         return;
      }
   }

   _str idHash:[];
   _MFUndoBegin("Obfuscate files");

   foreach (f in file_list) {
      message("Obfuscating: ":+f);
      _MFUndoBeginStep(f);
      status = edit(_maybe_quote_filename(f));
      obfuscate_current_file(idHash);
      _MFUndoEndStep(f);
   }

   _MFUndoEnd();
   message("Obfuscation done.");
}

/**
 * Replace all the identifiers in the given file with randomly generated 
 * identifiers to hide the meaning of code. 
 *  
 * @categories Refactoring_Functions
 */
_command void obfuscate_current_file(_str (&idHash):[]=null) name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

   n := 0;
   letter := 'A';
   digits := 0;

   top();
   _begin_line();
   identifier_re := _clex_identifier_re();
    
   status := search(identifier_re:+'|:i|:q|:b', '@rm');
   while (!status) {
      len := match_length();
      rep := "";
      cfg := _clex_find(0,'g');
      if (cfg == CFG_KEYWORD || cfg == CFG_PPKEYWORD || cfg == CFG_OPERATOR || cfg == CFG_PUNCTUATION) {
         // do not replace keywords
      } else if (cfg == CFG_NUMBER) {
         rep = n;
         n++;
         if (n > 9) n=0;
      } else if (cfg == CFG_STRING) {
         if (get_text() == '"') {
            rep = '""';
         } else if (get_text() == "'") {
            rep = "''";
         } else {
            rep = 'S';
            digits++;
            if (digits > 0xFFFF) digits=0;
         }
      } else if (cfg == CFG_COMMENT) {
         _replace_text(len, "");
      } else if (get_text() == ' ') {
         rep = ' ';
      } else {
         ident := get_text(len);
         if (idHash._indexin(ident)) {
            rep = idHash:[ident];
         } else {
            rep = letter:+_dec2hex(digits);
            idHash:[ident] = rep;
            digits++;
            ascii_digit := _asc(letter)+1;
            letter = _chr(ascii_digit);
            if (ascii_digit > _asc('Z')) {
               letter = 'A';
            }
            if (digits > 0xFFFF) {
               digits=0;
            }
         }
      }

      if (rep :!= "") {
         _replace_text(len, rep);
         p_col += length(rep);
      }

      status = repeat_search();
   }

   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
}

