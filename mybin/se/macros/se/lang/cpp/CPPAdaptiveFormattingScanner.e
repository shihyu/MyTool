////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#import "stdcmds.e"
#import "c.e"
#import "stdprocs.e"
#import "main.e"
#require "se/adapt/GenericAdaptiveFormattingScanner.e"
#endregion Imports

namespace se.lang.cpp;  

/** 
 * This class handles adaptive formatting specifically for
 * CPP files.
 * 
 */
class CPPAdaptiveFormattingScanner : se.adapt.GenericAdaptiveFormattingScanner {

   CPPAdaptiveFormattingScanner(_str extension = '') 
   {
      GenericAdaptiveFormattingScanner( AFF_BEGIN_END_STYLE | AFF_NO_SPACE_BEFORE_PAREN | 
                                                 AFF_PAD_PARENS | AFF_INDENT_CASE, extension);
      setSwitch('switch','case|default');
      setParenStyle('if|while|for|switch');
      setBeginEndStyle('do|try|if|while|for|switch');
   }
}
