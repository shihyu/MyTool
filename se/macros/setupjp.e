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
#pragma option(pedantic,on);
#region Imports
#include "slick.sh"
#import "main.e"
#import "stdprocs.e"
#endregion

// Set up the font association for Japanese fonts.
// Font association is required before SlickEdit can display
// DBCS characters.
//
// When editing DBCS characters, a singlebyte font and multibyte font
// are used together. Here are the criteria for these fonts:
//    1. Both fonts must have fixed character widths.
//    2. The width of characters in the multibyte font must be exactly
//       twice the width of the characters in the singlebyte font.

static _str parseErrorMsg(int status,_str sbfont,_str mbfont)
{
   msg := "Unable to associate font. ";
   switch (status) {
   case 1:
      msg :+= "Font association is not supported under current locale";
      break;
   case 2:
      msg :+= "Unable to parse font ":+sbfont;
      break;
   case 3:
      msg :+= "Unable to load font ":+sbfont;
      break;
   case 4:
      msg :+= "Unable to parse font ":+mbfont;
      break;
   case 5:
      msg :+= "Unable to load font ":+mbfont;
      break;
   }
   return(msg);
}

static int associateFont(_str sbf, _str mbf)
{
   int status;
   status = _dbcsAssociateFont(sbf,mbf);
   if (status) {
      _str msg = parseErrorMsg(status,sbf,mbf);
      _message_box(msg);
      return(1);
   }
   status = _dbcsAssociateFont(sbf:+",1",mbf);
   if (status) {
      _str msg = parseErrorMsg(status,sbf,mbf);
      _message_box(msg);
      return(1);
   }
   status = _dbcsAssociateFont(sbf:+",2",mbf);
   if (status) {
      _str msg = parseErrorMsg(status,sbf,mbf);
      _message_box(msg);
      return(1);
   }
   return(0);
}

static void printMsg(bool verbose, _str msg)
{
   if (!verbose) return;
   _message_box(msg, "Setup Japanese Fonts");
}

static int mapfont(bool verbose=true)
{
   // Identify the locale.
   val := _locale_language_name();
   if (val == "") {
      printMsg(verbose, nls("Unable to identify the locale."));
      return(1);
   }

   // Check to make sure the locale is JA_JP.
   _str location,encoding;
   parse val with location'.'encoding;
   ulocation := upcase(location);
   if (ulocation != "JA_JP" && ulocation != "JAPANESE") {
      printMsg(verbose, nls("Country/location %s is not supported.",location));
      return(1);
   }

   // Check encoding.
   uencoding := upcase(encoding);
   if (substr(uencoding,1,3) != "EUC" && uencoding != "SJIS" && uencoding != "UJIS") {
      printMsg(verbose, nls("Encoding %s is not supported.",encoding));
      return(1);
   }

   // Get the current window text font.
   // Make sure it is "adobe-courier".
   _str cFont, fname, theRest;
   _str ptsize, fflags;
   cFont = _default_font(CFG_WINDOW_TEXT);
   parse cFont with fname','ptsize','fflags','theRest;
   if (fname != "adobe-courier") {
      printMsg(verbose, nls("Please select 'adobe-courier' as your window text font.\nSelect Tools->Configuration->Font."));
      return(1);
   }
   if (ptsize != 10 && ptsize != 12 && ptsize != 14) {
      printMsg(verbose, nls("Please select 10pt, 12pt, or 14pt for your window text font.\nSelect Tools->Configuration->Font."));
      return(1);
   }

   // Associate a font for the appropriate encoding.
   // When editing DBCS characters, a singlebyte font and multibyte font
   // are used together. Here are the criteria for these fonts:
   //    1. Both fonts must have fixed character widths.
   //    2. The width of characters in the multibyte font must be exactly
   //       twice the width of the characters in the singlebyte font.
   mbfont10 := "-misc-fixed-medium-r-normal--13-120-75-75-c-120-jisx0208.1983-0";
   mbfont12 := "-misc-fixed-medium-r-normal--14-130-75-75-c-140-jisx0208.1983-0";
   mbfont14 := "-misc-fixed-medium-r-normal--19-180-75-75-c-180-jisx0208.1983-0";
   sbfont10 := "adobe-courier,10";
   sbfont12 := "adobe-courier,12";
   sbfont14 := "adobe-courier,14";
   if (associateFont(sbfont10,mbfont10)) return(1);
   if (associateFont(sbfont12,mbfont12)) return(1);
   if (associateFont(sbfont14,mbfont14)) return(1);

   // Associate the multibyte font to the normal text version, the italicized
   // text version, and the bold text version.
   if (verbose) {
      printMsg(verbose, nls("Associated multibyte fonts %s\n%s\n%s\n\nto text fonts\n%s\n%s\n%s\n\nSet up completed."
                            ,mbfont10,mbfont12,mbfont14,sbfont10,sbfont12,sbfont14)
               );
   }
   return(0);
}

definit()
{
   // definit() is called whenever the editor initializes this module.
   // This happens at start up and when the module is loaded. We want to
   // suppress any message box.
   mapfont(false);
}

defload()
{
   mapfont();
}
