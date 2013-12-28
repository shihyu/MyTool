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
#include 'slick.sh'
#include 'tagsdb.sh'
#require "se/lang/api/LanguageSettings.e"
#import "slickc.e"
#import "stdcmds.e"
#endregion

using se.lang.api.LanguageSettings;

#define CH_MODE_NAME    'Ch'
#define CH_LANGUAGE_ID  'ch'

defload()
{
   _str word_chars="A-Za-z0-9_$";
   _str setup_info='MN='CH_MODE_NAME',TABS=+4,MA=1 74 1,':+
                   'KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=':+
                   word_chars',LN=Ch,CF=1,LNL=0,TL=-1';
   _str compile_info='';
   _str syntax_info='4 1 1 0 0 1 0 0';
   _str be_info='';
   
   _CreateLanguage(CH_LANGUAGE_ID, CH_MODE_NAME, 
                   setup_info, compile_info,
                   syntax_info, be_info, "", word_chars);  
   _CreateExtension('ch',  CH_LANGUAGE_ID);
   _CreateExtension('chf', CH_LANGUAGE_ID);
   _CreateExtension('chs', CH_LANGUAGE_ID);

   // The Ch language will inherit callback from C/C++
   LanguageSettings.setLangInheritsFrom(CH_LANGUAGE_ID, 'c');
   LanguageSettings.setReferencedInLanguageIDs(CH_LANGUAGE_ID, "ansic c");
}

