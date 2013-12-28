////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48910 $
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
#require "se/lang/api/LanguageSettings.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

using se.lang.api.LanguageSettings;

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

#define ANSIC_LANGUAGE_ID "ansic"

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
   // Setup the placeholder 'ansic' extension setup and options
   if( !find_index('def-language-'ANSIC_LANGUAGE_ID,MISC_TYPE) ) {
      replace_def_data("def-language-"ANSIC_LANGUAGE_ID,'MN=ANSI-C,TABS=+4,MA=1 74 1,KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=ansic,CF=1,LNL=0,TL=-1');
   }
   if( !find_index('def-lang-for-ext-'ANSIC_LANGUAGE_ID,MISC_TYPE) ) {
      replace_def_data("def-lang-for-ext-"ANSIC_LANGUAGE_ID,ANSIC_LANGUAGE_ID);
   }
   if( !find_index('def-options-'ANSIC_LANGUAGE_ID,MISC_TYPE) ) {
      replace_def_data("def-options-"ANSIC_LANGUAGE_ID,"4 1 1 0 4 1 1");
   }

   if( LanguageSettings.getBeginEndPairs(ANSIC_LANGUAGE_ID) == '' ) {
      LanguageSettings.setBeginEndPairs(ANSIC_LANGUAGE_ID, "(#ifdef),(#ifndef),(#if)|(#endif)");
   }

   if ( LanguageSettings.getLangInheritsFrom(ANSIC_LANGUAGE_ID) == '' ) {
      LanguageSettings.setLangInheritsFrom(ANSIC_LANGUAGE_ID, 'c');
   }

   // Migrate def_ansic_exts to use def-lang-for-ext- and point to ANSIC
   foreach ( auto ext in def_ansic_exts ) {
      index := find_index("def-lang-for-ext-"ext,MISC_TYPE);
      if ( index <= 0 ) {
         insert_name("def-lang-for-ext-"ext, MISC_TYPE, "ansic");
      } else {
         set_name_info(index, "ansic");
      }
   }
}
