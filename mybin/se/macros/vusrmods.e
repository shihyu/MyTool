////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44088 $
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
#import "doscmds.e"
#import "main.e"
#import "stdprocs.e"
#endregion

/***************************************************************
* By convention, vusrmods is a batch program which loads all   *
* user specific modules and restores the users previous setup. *
* You may modify this file any way you wish. The install       *
* program will not overwrite this file,  if it already exits.  *
***************************************************************/
defmain()
{
   _str vusrmods_name=slick_path_search(USERMODS_FILE:+_macro_ext);
   _str path=substr(vusrmods_name,1,pathlen(vusrmods_name));
   /*********************************************************
   * If you want to write new commands, and/or              *
   * procedures, place them in another module               *
   * such as "user.e". The IF statement below will          *
   * automatically MAKE and LOAD "user.e" if it exists.     *
   *                                                        *
   * To add a macro package some one else has written,      *
   * follow the directions they give for installation.      *
   * Most macro packages require you to insert a makeNload  *
   * statement.                                             *
   *********************************************************/

   _str filename=slick_path_search('user':+_macro_ext);
   if (filename!='') {  /* user.e exist? */
      makeNload(filename);              /* compile and load  */
   }
   filename=slick_path_search(USERMACS_FILE:+_macro_ext);
   if ( filename!='') {  /* usermacs file exist? */
      makeNload(filename);              /* compile and load  */
   }

   /* makeNload(find_it('XXX.e'))      /* install package XXX */  */



   // Note: system modified forms must by loaded manually

   // Load user forms.
   rc='';
   filename=slick_path_search(USEROBJS_FILE:+_macro_ext);
   if ( filename!='') {  /* userobjs.e exist? */
      message(nls('Running %s',filename));
      int status=shell("updateobjs ":+filename);
      rc=xcom(maybe_quote_filename(filename));
      process_make_rc(rc,filename);
   }
   if ( rc=='' || ! rc ) {
      clear_message();
   }

   /*********************************************************
   * You should not have to modify the file USERDEFS_FILE   *
   * since it is automatically created by the LIST-SOURCE   *
   * command which is accessible from the CONFIG menu (F5)  *
   * under "List source for configuration...".              *
   * Before you install a new version of SLICK, invoke the  *
   * LIST-SOURCE command to generate the USERDEFS_FILE batch*
   * program containing your key bindings, and all edit     *
   * options available from the CONFIG menu.                *
   *********************************************************/
   filename=slick_path_search(USERDEFS_FILE:+_macro_ext);
   if ( filename!='') {  /* userdefs.e exist? */
      message(nls('Running %s',filename));
      rc=xcom(maybe_quote_filename(filename));
      /* See slick.sh for constant value of USERDEFS_FILE. */
      process_make_rc(rc,filename);
   }
   // Select emulation so that addition modules are loaded
   if (def_keys!='' && def_keys!='windows-keys' && def_keys!='macosx-keys') {
      _str emulate='';
      parse def_keys with emulate '-keys';
      shell(maybe_quote_filename(path'emulate')' 'emulate);
      clear_message();
      // Set button bar to invalid index
      //_default_option('B',-1);
      // Run this file again since running emulate blasted key bindings and options
      filename=slick_path_search(USERDEFS_FILE:+_macro_ext);
      if ( filename!='') {  /* userdefs.e exist? */
         message(nls('Running %s',filename));
         rc=xcom(maybe_quote_filename(filename));
         /* See slick.sh for constant value of USERDEFS_FILE. */
         process_make_rc(rc,filename);
      }
   }
   if ( rc=='' || ! rc ) {
      clear_message();
   }
   return(0);

}
static _str find_it(_str name)
{
   _str new_name=slick_path_search(name);
   if ( new_name!='' ) {
      return(new_name);
   }
   return(name);
}
