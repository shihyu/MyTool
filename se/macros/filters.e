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
#import "main.e"
#import "recmacro.e"
#endregion


_control _filters
_control _ok


defeventtab _filters_form;

_str def_file_types;

_ok.on_create()
{
   _filters.p_text = def_file_types;
   _macro('m',_macro('s'));
   _macro_delete_line();
}

_ok.lbutton_up()
{
   def_file_types = _filters.p_text;
   _macro('m',_macro('s'));
   _macro_append("def_file_types=" _quote(def_file_types)";");
   _config_modify_flags(CFGMODIFY_DEFVAR);
   p_active_form._delete_window(0);
}
