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
#include "subversion.sh"
#import "cvsutil.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "subversion.e"
#import "wkspace.e"
#import "sc/lang/String.e"
#endregion

using sc.lang.String;

/**
 * Gets the name of the subversion executable and options
 * @return Subversion executable and options
 */
_str _SVNGetExeAndOptions(bool exeOnly=false)
{
   _str svn_exename=_SVNGetExePath();
   if ( exeOnly ) {
      return svn_exename;
   }
   return(_maybe_quote_filename(svn_exename)' 'def_svn_global_options);
}

/**
 * Aceeses the entries file and gets the URL for <b>filename</b>
 * @param filename file to get URL for
 * @param URL URL that corresponds to <b>filename</b>
 * @return 0 if successful
 */
int _SVNGetFileURL(_str filename,_str &URL)
{
   curdur := getcwd();
   path := _file_path(filename);
   status := chdir(path,1);
   if ( status ) {
      return status;
   }

   rfilename := relative(filename,path);

   URL="";
   status=_SVNGetAttributeFromCommand(rfilename,"URL",URL);
   if (_isMac()) {
      // About 20% of the time on the Mac, this call will fail.
      // It seems to always work with a quick retry. Windows doesn't
      // exhibit this problem.
      // 1/5/2011 - We should not need this anymore... but it won't hurt to leave
      //            it for now
      if( (status == 0) && (URL == '') ) {
         status=_SVNGetAttributeFromCommand(rfilename,"URL",URL);
      }
   }
   URL = stranslate(URL,' ',"%20");

   chdir(curdur,1);
   return status;
}
/**
 * Prior to version Subversion 1.4 _SVNGetEntryAttribute would
 * open the .svn/entries file directly.  In Subversion 1.4 this
 * file is no longer XML but a more proprietary format, so we
 * use the "svn info" command to get these
 * @param filename
 * @param attribute_name name of the attribute to look for must
 *                       be cased the same as in the output from
 *                       "svn info", but not have the trailing
 *                       ':'
 * @param entry_attribute
 *
 * @return int
 */
int _SVNGetAttributeFromCommand(_str filename,_str attribute_name,_str &entry_attribute)
{
   // Keep the original directory
   _str origdir=getcwd();
   entry_attribute="";
   String StdOutData,StdErrData;
   status := 0;
   remote := IsSVNRemoteFile(filename);
   curErrData := StdErrData.get();

   do {
      _str path=_file_path(filename);
      if ( path!="" && !remote ) {
         // Change to the directory that that file is in.
         status = chdir(path,1);
      }
      if ( status ) {
         return status;
      }
      rfilename := "";
      if ( !remote ) {
         rfilename = _strip_filename(filename,'P');
      }else{
         rfilename = filename;
      }

      _str command=_SVNGetExeAndOptions()' info '_maybe_quote_filename(rfilename);

      status=_CVSPipeProcess(command,path,'P'def_cvs_shell_options,StdOutData,StdErrData,
                             false,null,null,null,-1,false,false);
   
      //say('_SVNGetAttributeFromCommand StdErrData='StdErrData);
      //say('p='pos("(is not a working copy)",StdErrData,1,'r'));
      if (status || pos("(Not a versioned resource)",StdOutData.get()) 
          || pos("(is not a working copy)",StdErrData.get(),1,'r') ) {
         if (!status) status=1;
         break;
      }
      if ( pos("svn: This client is too old to work with working copy",StdErrData) ) {
         return(INCORRECT_VERSION_RC);
      }
      _str outdata=StdOutData.get();
   
      nl := "";
      if ( pos("\r\n",outdata) ) {
         nl = "\r\n";
      }else{
         nl = "\n";
      }
   
   //   _str nl="\n";
   //   if (_vsUnix()) {
   //      // Use \r\n on Windows
   //      nl="\r\n";
   //   }
   
      // Check for errors
      curLine := "";
      parse curErrData with curLine (nl) curErrData;
      if (isinteger(curLine)) {
         status=(int)curLine;
         break;
      }
   
      attribute_name_len := length(attribute_name);
      for (;;) {
         parse outdata with curLine (nl) outdata;
         if ( curLine=="" ) break;
         curField := substr(curLine,1,attribute_name_len+1);
         if ( curField==attribute_name:+':' ) {
   
            // Use +2 because we have to strip ':' too
            entry_attribute=substr(curLine,attribute_name_len+2);
   
            // Strip any whitespace
            entry_attribute=strip(entry_attribute);
            break;
         }
      }
   } while (false);
   // Change back to original directory, we had changed to the directory the 
   // file was in
   chdirStatus := chdir(origdir,1);
   if ( chdirStatus ) status = chdirStatus;
   // Use a separate status, we don't want a 0 (good) status from chdir to 
   // supercede an earlier failure.

   return status;
}

/**
 * @param filename Filename that may be a local filename or a 
 *                 subversion filename
 * 
 * @return bool true if this is a remote subversion file 
 *         (note: "file://" is remote)
 */
static bool IsSVNRemoteFile(_str filename)
{
   substr7 := substr(filename,1,7);
   return substr(filename,1,6)=="svn://"|| 
      substr7=="http://"||
      substr7=="file://"||
      substr(filename,1,9)=="svn+ssh://";
}

int _SVNGetBranchForLocalFile(_str filename,_str &branchName,_str &repositoryRoot,_str &subFilename,_str &URL="")
{
   repositoryRoot = subFilename = branchName = "";
   _str remote_filename;
   int status=_SVNGetFileURL(filename,remote_filename);
   if ( status ) {
      return(status);
   }
   String StdOutData,StdErrData;
   status=_CVSPipeProcess(_SVNGetExeAndOptions():+" info --xml ":+_maybe_quote_filename(remote_filename),'','P'def_cvs_shell_options,StdOutData,StdErrData,
                          false,null,null,null,-1,false,false);
   int orig_wid=_create_temp_view(auto temp_wid);
   // Took out insert-text of stderr from here, since it could cause the 
   // parse to fail when subversion gives warnings.
   _insert_text(StdOutData.get());
   p_window_id=orig_wid;

   xmlhandle :=_xmlcfg_open_from_buffer(temp_wid,status,VSXMLCFG_OPEN_ADD_PCDATA);

   //repositoryRoot := "";
   if ( !status ) {
      urlIndex := _xmlcfg_find_simple(xmlhandle,"/info/entry/url");
      if ( urlIndex>-1 ) {
         pcDataIndex := _xmlcfg_get_first_child(xmlhandle,urlIndex,VSXMLCFG_NODE_PCDATA);
         if ( pcDataIndex>-1 ) {
            URL = _xmlcfg_get_value(xmlhandle,pcDataIndex);
         }
      }
      repositoryIndex := _xmlcfg_find_simple(xmlhandle,"/info/entry/repository/root");
      if ( repositoryIndex>-1 ) {
         pcDataIndex := _xmlcfg_get_first_child(xmlhandle,repositoryIndex,VSXMLCFG_NODE_PCDATA);
         if ( pcDataIndex>-1 ) {
            repositoryRoot = _xmlcfg_get_value(xmlhandle,pcDataIndex);
         }
      }
      branchName = URL;
      branchName = _strip_filename(branchName,'N');

      justPath := _file_path(filename);
#if 1
      // Use this code to pare branch name back to just the branch name without
      // the path piece
      _maybe_strip_filesep(justPath);
      _maybe_strip(branchName,'/');
      for ( ;; ) {
         lastdir_justPath   := _GetLastDirName(justPath);
         lastdir_branchName := _GetLastDirName(branchName);
         if ( lastdir_justPath!=lastdir_branchName ) break;

         branchName = _file_path(branchName);
         justPath = _file_path(justPath);

         _maybe_strip(branchName,'/');
         _maybe_strip_filesep(justPath);
      }
      subFilename = substr(remote_filename,length(branchName)+1);
      _maybe_strip(subFilename, '/', stripFromFront:true);
#endif 
   }
   _xmlcfg_close(xmlhandle);
//
////   p_window_id=temp_wid;
////   _save_file('+o c:\temp\out.xml');
//   p_window_id=orig_wid;
//   _delete_temp_view(temp_wid);
   return status;
}
