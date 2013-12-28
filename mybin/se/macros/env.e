////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46085 $
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
#import "eclipse.e"
#import "files.e"
#import "main.e"
#import "os2cmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#import "stdcmds.e"
#endregion
/**
 * If no arguments are given, a new buffer is created and the current 
 * environment is inserted.  The current value of a single environment 
 * variable may be retrieved by specifying name of the environment 
 * variable without the '=' or value parameter.  To remove an environment 
 * variable, specify the name of the environment variable followed by '=' 
 * and omit the <i>value</i> parameter.  To replace or insert a value for 
 * an environment variable specify all parameters.  'set ?' will list the 
 * names of the environment variables.
 * 
 * @param cmdline is a string in the format: <i>env_var </i>[=] 
 * <i>value</i>
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command int set(_str cndline='', boolean doExpand=true) name_info(ENV_ARG',')
{
   if (isEclipsePlugin()) {
      eclipse_show_disabled_msg('set');
      return(0);
   }
   if ( arg(1)=='' ) {
      if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
         return(0);
      }
      /* list the environment variables. */
      int status=edit('+futf8 +t');
      if ( status ) { return(status); }
      _str name=env_match('',1);
      boolean first_time=true;
      boolean lines_truncated=false;
      for (;;) {
         if ( rc ) { break; }
         _str text=name'='get_env(name);
         if ( length(text)>MAX_LINE ) {
            text=substr(text,1,MAX_LINE);
            lines_truncated=true;
         }
         if ( first_time ) {
            first_time=false;
            replace_line(text);
         } else {
            insert_line(text);
         }
         name=env_match('',0);
      }
      p_modify=0;top();
      if ( lines_truncated ) {
         message(get_message(LINES_TRUNCATED_RC)'.  'nls('Yes, we plan to support long lines.'));
      }
      return(0);
   }
   int i=pos('=',arg(1));
   if ( ! i ) {
      _macro_delete_line();
      /* just look up the variable */
      _str param=env_case(arg(1));
      _str content=get_env(param);
      if ( rc ) {
         message(get_message(rc));
         return(rc);
      }
      _str line='set 'param' ='content;
      command_put(line);
      return(0);
   }
   _str content=substr(arg(1),i+1);
   _str EnvVarName=strip(env_case(substr(arg(1),1,i-1)));
   _str new_value=content;
   if (new_value:!='' && doExpand) {
      new_value=_xlat_env(content);
   }
/*

tcsh, csh
  setenv  envname  "sdff"

sh, bash, ksh, bsh(tested on LINUX), ash(tested on LINUX)
NAME="this is a test";export NAME
*/
#if __UNIX__
   boolean is_csh=pos('csh',_get_process_shell(true))!=0;
#endif
   boolean doUpdateTags=(EnvVarName:==_SLICKTAGS && get_env(_SLICKTAGS)!=new_value);
   if ( content:=='' ) {
      /* remove the variable from the environment */
      set_env(EnvVarName);
      if ( _process_info()) {
#if __UNIX__
         if (is_csh) {
            concur_command('unsetenv 'EnvVarName,false,true,false);
         } else {
            concur_command('unset 'EnvVarName,false,true,false);
         }
#else
         concur_command('set 'EnvVarName'=',false,true,false);
#endif
      }
   } else {
      // only xlate the value if requested
      if(doExpand) {
         content = _xlat_env(content);
      }
      set_env(EnvVarName,content);
      if ( _process_info()) {
#if __UNIX__
         if (is_csh) {
            concur_command('setenv 'EnvVarName' "'content'"',false,true,false);
         } else {
            concur_command(EnvVarName'="'content'";export 'EnvVarName,false,true,false);
         }
#else
         concur_command('set 'EnvVarName'='content,false,true,false);
#endif
      }
      //set_env strip(env_case(substr(arg(1),1,i-1))),content
   }
   if (doUpdateTags) {
      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }
   return(0);

}

// Translate embedded environment variables and expand them into 'str'
//12:01pm 7/9/1999
//Made global for _VslickErrorInfo
_str _xlat_env(_str str)
{
#if __UNIX__
   _str re='{#0\$[a-zA-Z0-9_]#}';
   _str begin_delim='$';
   _str end_delim='';
#else
   _str re='{#0%[a-zA-Z0-9_]@%}';
   _str begin_delim='%';
   _str end_delim='%';
#endif
   int i=1;
   for(;;) {
      i=pos(re,str,i,'er');
      if( !i ) break;
      _str before=substr(str,1,i-1);
      _str after=substr(str,pos('S0')+pos('0'));
      _str temp=substr(str,pos('S0'),pos('0'));
      parse temp with (begin_delim) temp (end_delim);

      // check for escaped percent sign (%%)
      if(!__UNIX__ && temp == "") {
         temp = begin_delim;
      } else {
         temp=get_env(temp);
      }
      str=before:+temp:+after;
      i+=length(temp);
   }

   return(str);
}

/**
 * @return Returns the installation directory for Cygwin.
 */
_str _cygwin_path()
{
#if __UNIX__
   return("");
#else
   cygwinPath := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Cygnus Solutions\GNUPro\i586-cygwin32\i586-cygwin32','','Install Path');
   if (cygwinPath=='') {
      cygwinPath = _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Cygnus Solutions\GNUPro\i586-cygwin32','','Install Path');
      if (cygwinPath=='') {
         cygwinPath = _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Cygnus Solutions\Cygwin\mounts v2\/','','native');
         if (cygwinPath=='') {
            // look for cygstart
            cygwinPath = path_search("cygstart.exe");
            // go back up one if we are in the bin dir
            if (endsWith(cygwinPath, '\bin\cygstart.exe', false, 'I')) {
               cygwinPath = substr(cygwinPath, 1, length(cygwinPath) - 16);
            }
         }
      }
   }
   _maybe_append_filesep(cygwinPath);
   return(cygwinPath);
#endif
}

/**
 * @return Returns the path prefix generated by cygwin to
 *         map UNIX-style paths to DOS style paths.
 */
static _str _cygdrive_prefix()
{
#if __UNIX__
   return("");
#else
   _str cygdrive_prefix="";
   int status=_ntRegFindValue(HKEY_CURRENT_USER,'SOFTWARE\Cygnus Solutions\Cygwin\mounts v2','cygdrive prefix',cygdrive_prefix);
   if( status || cygdrive_prefix=="" ) {
      // Try HKEY_LOCAL_MACHINE
      status=_ntRegFindValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Cygnus Solutions\Cygwin\mounts v2','cygdrive prefix',cygdrive_prefix);
   }

   if( status || cygdrive_prefix=="" ) {
      cygdrive_prefix="/cygdrive/";
   }

   _maybe_append(cygdrive_prefix,'/');
   return(cygdrive_prefix);
#endif
}

/**
 * Convert DOS-style path to a Cygwin UNIX-style path.
 *
 * @param path DOS-style path to convert.
 *
 * @example
 * c:\cygwin\bin\ becomes /cygdrive/c/cygwin/bin/
 *
 * @return Cygwin equivalent UNIX-style path.
 */
_str _path2cygwin(_str path)
{
#if __UNIX__
   return("");
#else
   if( path=="" ) {
      return("");
   }
   _str cygpath=path;
   _str ext=_get_extension(cygpath);
   if( ext=='exe' ) {
      // Strip off the extension
      cygpath=_strip_filename(cygpath,'E');
   }
   cygpath=translate(cygpath,'/',FILESEP);
   if( !isalpha(substr(cygpath,1,1)) || substr(cygpath,2,1)!=':' ) {
      // Probably a UNC path, so no need to convert drive letter
      return(cygpath);
   }
   cygpath=stranslate(cygpath,'',':');
   cygpath=_cygdrive_prefix():+cygpath;

   return(cygpath);
#endif
}

/**
 * Convert absolute Cygwin UNIX-style path to a DOS-style path.
 *
 * @param path Cygwin UNIX-style path to convert.
 *
 * @example
 * /bin/perl.exe becomes c:\cygwin\bin\perl.exe
 *
 * @return equivalent DOS-style path.
 */
_str _cygwin2dospath(_str path)
{
#if __UNIX__
   return(path);
#else
   if( path=="" ) {
      return("");
   }

   // not an absolute path, then just translate fileseps
   if (substr(path,1,1)!='/') {
      path=stranslate(path,FILESEP,'/');
      return(path);
   }

   // Cygwin version of a UNC path?
   if (substr(path,1,2)=='//') {
      path=stranslate(path,FILESEP,'/');
      return(path);
   }

   // Does the path look like /cygdrive/[drive letter]/...?
   _str cygdrive_prefix=_cygdrive_prefix();
   if (file_eq(substr(path,1,length(cygdrive_prefix)),cygdrive_prefix) &&
       isalpha(substr(path,length(cygdrive_prefix)+1,1)) &&
       substr(path,length(cygdrive_prefix)+2,1)=='/') {
      path=stranslate(path,FILESEP,'/');
      return substr(path,11,1):+':':+substr(path,12);
   }

   // OK, then this path must be relative to the cygwin install dir
   _str cygwin_dir=_cygwin_path();
   if (cygwin_dir=='') {
      return '';
   }
   path=substr(path,2);
   path=stranslate(path,FILESEP,'/');

   // compute the new path, and check for .exe
   path=cygwin_dir:+path;
   if (_get_extension(path)=='' && !file_exists(path) && file_exists(path:+'.exe')) {
      path=path:+'.exe';
   }

   return(path);
#endif
}
