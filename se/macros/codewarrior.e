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
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#endregion

/*
    Supports Metrowerks CodeWarrior for Gamecube
*/



static _str cwList[];

/**
 * Find the header or source file associated with the current file in the editor
 * 
 * @deprecated  Use {@link edit_associated_file} instead.
 */
_command void cw_find_associated_file()
{
   edit_associated_file();
}

/*
 Function Name:getCodeWarriorRootPath

 Parameters:   None

 Description:  Checks the registry for CodeWarrior

 Returns:      String containing the path to CodeWarrior root

 */
static _str getCodeWarriorRootPath() {

   if (_isUnix()) return("");
   cwPath := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Metrowerks\CodeWarrior for Windows', '', 'PATH');
   _maybe_append_filesep(cwPath);
   return(cwPath);
}

/*
 Function Name:  maybeCreateCWGamecubeTagfile

 Parameters:     None

 Description:    Creates a tag file for CodeWarrior Gamecube

 Returns:        Tagfile name

 */
_str maybeCreateCWGamecubeTagfile()
{
   _str tagFilename = _tagfiles_path() :+ 'cw_ppc_eabi' :+ TAG_FILE_EXT;
   cmdargs := "";

   // maybe create tag file
   if(!file_exists(tagFilename)) {
      //say('Creating ' :+ tagFilename);
      message('Building tag file "' :+ tagFilename :+ '"');

      _str cwPath = getCodeWarriorRootPath();
      if(cwPath == '') return '';

      _str cwTagFilename = tagFilename;
      tagFilename = _maybe_quote_filename(cwTagFilename);

      includePath :=  cwPath :+ 'PowerPC_EABI_Support' :+ FILESEP;
      cmdargs :+= ' "' :+ includePath :+ '*."';
      cmdargs :+= ' "' :+ includePath :+ '*.h"';
      cmdargs :+= ' "' :+ includePath :+ '*.hpp"';
      cmdargs :+= ' "' :+ includePath :+ '*.hxx"';
      cmdargs :+= ' "' :+ includePath :+ '*.inl"';
      cmdargs :+= ' "' :+ includePath :+ '*.c"';
      cmdargs :+= ' "' :+ includePath :+ '*.cpp"';
      cmdargs :+= ' "' :+ includePath :+ '*.cp"';
      cmdargs :+= ' "' :+ includePath :+ '*.cxx"';

      makeTagCmd := '-t -n "CodeWarrior Gamecube" -o ';
      makeTagCmd :+= tagFilename :+ ' ' :+ cmdargs;
      int status = make_tags(makeTagCmd);
      if(!status) {

      }

      clear_message();
   }

   // return the tag filename
   // (which will be added to the list returned by tags_filenamea)
   return(tagFilename);
}

/*
 Function Name:  maybeCreateCWWin32Tagfile

 Parameters:     None

 Description:    Creates a tag file for CodeWarrior Win32

 Returns:        Tagfile name

 */
_str maybeCreateCWWin32Tagfile()
{
   _str tagFilename = _tagfiles_path() :+ 'cw_win32' :+ TAG_FILE_EXT;
   cmdargs := "";

   // maybe create tag file
   if(!file_exists(tagFilename)) {
      //say('Creating ' :+ tagFilename);
      message('Building tag file "' :+ tagFilename :+ '"');

      _str cwPath = getCodeWarriorRootPath();
      if(cwPath == '') return '';

      _str cwTagFilename = tagFilename;
      tagFilename = _maybe_quote_filename(cwTagFilename);

      includePath :=  cwPath :+ 'Win32 Support' :+ FILESEP;
      cmdargs :+= ' "' :+ includePath :+ '*."';
      cmdargs :+= ' "' :+ includePath :+ '*.h"';
      cmdargs :+= ' "' :+ includePath :+ '*.hpp"';
      cmdargs :+= ' "' :+ includePath :+ '*.hxx"';
      cmdargs :+= ' "' :+ includePath :+ '*.inl"';
      cmdargs :+= ' "' :+ includePath :+ '*.c"';
      cmdargs :+= ' "' :+ includePath :+ '*.cpp"';
      cmdargs :+= ' "' :+ includePath :+ '*.cp"';
      cmdargs :+= ' "' :+ includePath :+ '*.cxx"';

      includePath = cwPath :+ 'MSL' :+ FILESEP;
      cmdargs :+= ' "' :+ includePath :+ '*."';
      cmdargs :+= ' "' :+ includePath :+ '*.h"';
      cmdargs :+= ' "' :+ includePath :+ '*.hpp"';
      cmdargs :+= ' "' :+ includePath :+ '*.hxx"';
      cmdargs :+= ' "' :+ includePath :+ '*.inl"';
      cmdargs :+= ' "' :+ includePath :+ '*.c"';
      cmdargs :+= ' "' :+ includePath :+ '*.cpp"';
      cmdargs :+= ' "' :+ includePath :+ '*.cp"';
      cmdargs :+= ' "' :+ includePath :+ '*.cxx"';

      makeTagCmd := '-t -n "CodeWarrior Win32" -o ';
      makeTagCmd :+= tagFilename :+ ' ' :+ cmdargs;
      int status = make_tags(makeTagCmd);
      if(!status) {

      }

      clear_message();
   }

   // return the tag filename
   // (which will be added to the list returned by tags_filenamea)
   return(tagFilename);
}

/*
 Function Name:  maybeCreateCWMacOSTagfile

 Parameters:     None

 Description:    Creates a tag file for CodeWarrior MacOS

 Returns:        Tagfile name

 */
_str maybeCreateCWMacOSTagfile()
{
   _str tagFilename = _tagfiles_path() :+ 'cw_mac' :+ TAG_FILE_EXT;
   cmdargs := "";

   // maybe create tag file
   if(!file_exists(tagFilename)) {
      //say('Creating ' :+ tagFilename);
      message('Building tag file "' :+ tagFilename :+ '"');

      _str cwPath = getCodeWarriorRootPath();
      if(cwPath == '') return '';

      _str cwTagFilename = tagFilename;
      tagFilename = _maybe_quote_filename(cwTagFilename);

      includePath :=  cwPath :+ 'MacOS Support' :+ FILESEP;
      cmdargs :+= ' "' :+ includePath :+ '*."';
      cmdargs :+= ' "' :+ includePath :+ '*.h"';
      cmdargs :+= ' "' :+ includePath :+ '*.hpp"';
      cmdargs :+= ' "' :+ includePath :+ '*.hxx"';
      cmdargs :+= ' "' :+ includePath :+ '*.h++"';
      cmdargs :+= ' "' :+ includePath :+ '*.inl"';
      cmdargs :+= ' "' :+ includePath :+ '*.c"';
      cmdargs :+= ' "' :+ includePath :+ '*.cpp"';
      cmdargs :+= ' "' :+ includePath :+ '*.cp"';
      cmdargs :+= ' "' :+ includePath :+ '*.cxx"';
      cmdargs :+= ' "' :+ includePath :+ '*.c++"';

      includePath = cwPath :+ 'MSL' :+ FILESEP;
      cmdargs :+= ' "' :+ includePath :+ '*."';
      cmdargs :+= ' "' :+ includePath :+ '*.h"';
      cmdargs :+= ' "' :+ includePath :+ '*.hpp"';
      cmdargs :+= ' "' :+ includePath :+ '*.hxx"';
      cmdargs :+= ' "' :+ includePath :+ '*.h++"';
      cmdargs :+= ' "' :+ includePath :+ '*.inl"';
      cmdargs :+= ' "' :+ includePath :+ '*.c"';
      cmdargs :+= ' "' :+ includePath :+ '*.cpp"';
      cmdargs :+= ' "' :+ includePath :+ '*.cp"';
      cmdargs :+= ' "' :+ includePath :+ '*.cxx"';
      cmdargs :+= ' "' :+ includePath :+ '*.c++"';

      makeTagCmd := '-t -n "CodeWarrior MacOS" -o ';
      makeTagCmd :+= tagFilename :+ ' ' :+ cmdargs;
      int status = make_tags(makeTagCmd);
      if(!status) {

      }

      clear_message();
   }

   // return the tag filename
   // (which will be added to the list returned by tags_filenamea)
   return(tagFilename);
}

