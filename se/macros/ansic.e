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
#import "se/lang/api/LanguageSettings.e"
#import "se/lang/api/ExtensionSettings.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;

/* 
 * Language setup to allow users to separate ANSI C options from C++.
 *
 * HOW IT WORKS
 * 
 * When you open a .h or .i file, it will check if there is a matching
 * file in the same directory with one of the "c" or "cpp" style
 * extensions, then it will check what that extension is referred to
 * and use that instead of the default.
 *
 * To avoid file I/O, this check will only be performed if the '.c'
 * extension has been referred to something OTHER than C/C++.
 */

static const ANSIC_LANGUAGE_ID=  "ansic";

/**
 * Space-delimited list of extensions (no dots). 
 * These extensions will be overridden with extension settings
 * and options from the 'ansic' extension. 
 * <br>
 * <b>NOTE:</b> 
 * This setting is no longer supported as of SlickEdit 2008. 
 * You can just refer 'c' to 'ansic'. 
 * 
 * @default ""
 * @categories Configuration_Variables 
 */
_str def_ansic_exts="";


defload()
{
   if (!ExtensionSettings.isExtensionDefined(ANSIC_LANGUAGE_ID)) {
      ExtensionSettings.setLangRefersTo(ANSIC_LANGUAGE_ID,ANSIC_LANGUAGE_ID);
   }

   if( LanguageSettings.getBeginEndPairs(ANSIC_LANGUAGE_ID) == '' ) {
      LanguageSettings.setBeginEndPairs(ANSIC_LANGUAGE_ID, "(#ifdef),(#ifndef),(#if)|(#endif)");
   }

   if ( LanguageSettings.getLangInheritsFrom(ANSIC_LANGUAGE_ID) == '' ) {
      LanguageSettings.setLangInheritsFrom(ANSIC_LANGUAGE_ID, 'c');
   }

   // Migrate def_ansic_exts to point to ANSIC
   foreach ( auto ext in def_ansic_exts ) {
      ExtensionSettings.setLangRefersTo(ext, 'ansic');
   }
}
bool _ansic_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _ansic_supports_insert_begin_end_immediately() {
   return true;
}
