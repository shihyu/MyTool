////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
_str _SVNGetExeAndOptions(boolean exeOnly=false)
{
   _str svn_exename=def_svn_info.svn_exe_name;
   if ( !file_exists(svn_exename) ) {
      svn_exename=path_search(svn_exename);
   }
   if ( exeOnly ) {
      return svn_exename;
   }
   return(maybe_quote_filename(svn_exename)' 'def_svn_global_options);
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
#if __MACOSX__
   // About 20% of the time on the Mac, this call will fail.
   // It seems to always work with a quick retry. Windows doesn't
   // exhibit this problem.
   // 1/5/2011 - We should not need this anymore... but it won't hurt to leave
   //            it for now
   if( (status == 0) && (URL == '') ) {
      status=_SVNGetAttributeFromCommand(rfilename,"URL",URL);
   }
#endif
   URL = stranslate(URL,' ',"%20");

   chdir(curdur,1);
   return status;
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
   status=_CVSPipeProcess(_SVNGetExeAndOptions():+" info --xml ":+maybe_quote_filename(remote_filename),'','P'def_cvs_shell_options,StdOutData,StdErrData,
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
      if ( first_char(subFilename)=='/' ) subFilename=substr(subFilename,2);
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
