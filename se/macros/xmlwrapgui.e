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
#include "xmlwrap.sh"
#include "tagsdb.sh"
#include "color.sh"
#include "listbox.sh"
#import "guiopen.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "mprompt.e"
#import "optionsxml.e"
#import "sellist.e"
#import "setupext.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "util.e"
#import "xml.e"
#import "xmlwrap.e"
#import "se/alias/AliasFile.e"
#import "cfg.e"
#endregion

//#define  XW_DEFAULTSYMBOLTRANSALIASFILE ('symboltrans':+VSCFGFILEEXT_ALIASES)
//#define  XW_SYMBOLTRANSALIASFILESUFFIX  '_'XW_DEFAULTSYMBOLTRANSALIASFILE

_str getSymbolTransaliasFile(_str lang = p_LangId) {
   return _plugin_append_profile_name(vsCfgPackage_for_Lang(lang),VSCFGPROFILE_SYMBOLTRANS_ALIASES);
}

void autoSymbolTransEditor(_str lang)
{
   _str filename = getSymbolTransaliasFile(lang);

   // now launch the alias dialog
   typeless result=show('-modal -xy -new _alias_editor_form', filename, false, '', SYMTRANS_ALIAS_FILE, lang);
   return;
}
