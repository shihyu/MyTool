////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50652 $
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
#import "options.e"
#import "setupext.e"
#endregion

#define DEFAULTS_FILE 'defaults'
#define SLICKDEF_FILE 'slickdef'
#define WINDEFS_FILE 'windefs'
#define MACOSXDEFS_FILE 'macosxdefs'
#define COMMONDEFS_FILE 'commondefs'

static _str gMissingFileList[]=null;
defmain()
{
   gMissingFileList=null;
   int orig_def_actapp=def_actapp;
   def_actapp=0;
   _use_timers=0;
#if __UNIX__
   _str dllpath=editor_name('P');
   _str filename='';
#else
   _str dllpath=editor_name('P');
   _str filename=dllpath:+'cparse':+DLLEXT;
   _str qfilename=filename;
   if ( pos(' ',filename) ) {
      qfilename='"'qfilename'"';
   }
   if (file_match(' -p 'qfilename,1)=='') {
      filename=get_env('VSLICKBIN1'):+('cparse':+DLLEXT);
      dllpath=substr(filename,1,pathlen(filename));
   }
#endif
#if 0
  if ( _menu_file_spec=='' && _help_file_spec=='' ) {
     options=lowcase(get_env('VSLICK'));
     parse options with '-m' _menu_file_spec .;
     parse options with '-h' _help_file_spec .;
  }
#endif
  /* find main and assume rest of macro source files there.*/
  _str path='';
  _str name='';
  _str new_name='';
  if ( arg(1)!='' ) {
     path=arg(1);
  } else {
     /* Duplicating code here for SLICK_PATH_SEARCH() function */
     /* so that this code does not have to be in main.e */
     name='main'_macro_ext;
     new_name= path_search(name,_SLICKPATH);
     if ( new_name=='' ) {
        new_name= path_search(name);
     }
     path= substr(new_name,1,pathlen(new_name));
  }

#if !__UNIX__
  // Required early on for user config path information
  _dllexport("void winutils:ntGetSpecialFolderPath(VSHREFVAR hvarAppDataPath,int csidl_special_folder)",0,0);
#endif

  // Slick-C language intrinsics
  makeNload(path'sc'FILESEP'lang'FILESEP'DelayTimer');
  makeNload(path'sc'FILESEP'lang'FILESEP'IIterable');
  makeNload(path'sc'FILESEP'lang'FILESEP'IAssignTo');
  makeNload(path'sc'FILESEP'lang'FILESEP'IEquals');
  makeNload(path'sc'FILESEP'lang'FILESEP'IComparable');
  makeNload(path'sc'FILESEP'lang'FILESEP'IControlID');
  makeNload(path'sc'FILESEP'lang'FILESEP'IHashable');
  makeNload(path'sc'FILESEP'lang'FILESEP'IIndexable');
  makeNload(path'sc'FILESEP'lang'FILESEP'IArray');
  makeNload(path'sc'FILESEP'lang'FILESEP'IHashIndexable');
  makeNload(path'sc'FILESEP'lang'FILESEP'IHashTable');
  makeNload(path'sc'FILESEP'lang'FILESEP'IToString');
  makeNload(path'sc'FILESEP'lang'FILESEP'Range');
  makeNload(path'sc'FILESEP'lang'FILESEP'String');
  makeNload(path'sc'FILESEP'lang'FILESEP'Timer');

  // Slick-C collection classes
  makeNload(path'sc'FILESEP'collections'FILESEP'Stack');
  makeNload(path'sc'FILESEP'collections'FILESEP'IList.e');
  makeNload(path'sc'FILESEP'collections'FILESEP'IMultiMap.e');
  makeNload(path'sc'FILESEP'collections'FILESEP'List.e');
  makeNload(path'sc'FILESEP'collections'FILESEP'Map.e');
  makeNload(path'sc'FILESEP'collections'FILESEP'MapItemCompare.e');
  makeNload(path'sc'FILESEP'collections'FILESEP'MultiMap.e');

  // Slick-C controls classes
  makeNload(path'sc'FILESEP'controls'FILESEP'Table');

  // Slick-C editor utility classes
  makeNload(path'sc'FILESEP'editor'FILESEP'SavePosition');
  makeNload(path'sc'FILESEP'editor'FILESEP'SaveSearch');
  makeNload(path'sc'FILESEP'editor'FILESEP'TempEditor');
  makeNload(path'sc'FILESEP'editor'FILESEP'LockSelection');

  // Slick-C net classes and interfaces
  makeNload(path'sc'FILESEP'net'FILESEP'ISocketCommon');
  makeNload(path'sc'FILESEP'net'FILESEP'IServerSocket');
  makeNload(path'sc'FILESEP'net'FILESEP'IClientSocket');
  makeNload(path'sc'FILESEP'net'FILESEP'Socket');
  makeNload(path'sc'FILESEP'net'FILESEP'ServerSocket');
  makeNload(path'sc'FILESEP'net'FILESEP'ClientSocket');

  // Slick-C util classes and interfaces
  makeNload(path'sc'FILESEP'util'FILESEP'Rect');
  makeNload(path'sc'FILESEP'util'FILESEP'Point');

  // Filter functor interface
  makeNload(path'se'FILESEP'util'FILESEP'IFilter');

  // Observer functor interface
  makeNload(path'se'FILESEP'util'FILESEP'IObserver');

  // PathMapper class
  makeNload(path'se'FILESEP'util'FILESEP'IPathMapper');
  makeNload(path'se'FILESEP'util'FILESEP'PathMapper');

  // LanguageSettings api
  makeNload(path'se'FILESEP'lang'FILESEP'api'FILESEP'LanguageSettings');
  makeNload(path'se'FILESEP'lang'FILESEP'api'FILESEP'ExtensionSettings');

  // Advanced file type mapping
  makeNload(path'se'FILESEP'files'FILESEP'FileNameMapper');
  makeNload(path'filetypemanager');

  // Slick-C file utility classes
  makeNload(path'se'FILESEP'files'FILESEP'FileWatcherManager');

  // Other stuff
  makeNload(path'saveload');
  makeNload(path'files');
  makeNload(path'filewatch');
  makeNload(path'stdprocs');
  makeNload(path'stdcmds');
  makeNload(path'url');
  makeNload(path'xmlcfg');
  makeNload(path'xml');
  makeNload(path'tbsearch');
  makeNload(path'tbshell');
  makeNload(path'output');
  makeNload(path'mouse');  // Need mou_hour_glass
  makeNload(path'cua');
  makeNload(path'error');
  makeNload(path'reflow');
  makeNload(path'options');
  makeNload(path'bind');
  makeNload(path'recmacro');
  makeNload(path'sellist');
  makeNload(path'listedit');
  makeNload(path'eclipse');
  makeNload(path'put');
  makeNload(path'complete');
  makeNload(path'window');
  makeNload(path'moveedge');
  makeNload(path'markfilt');
  makeNload(path'search');
  makeNload(path'clipbd');
  makeNload(path'quickstart');
  message(nls('making %s',path:+DEFAULTS_FILE));
  int status=shell('"'path:+DEFAULTS_FILE'"');
  process_make_rc(status,DEFAULTS_FILE);
  message(nls('making %s',path:+COMMONDEFS_FILE));
  status=shell('"'path:+COMMONDEFS_FILE'"');
  process_make_rc(status,COMMONDEFS_FILE);
  message(nls('making %s',path:+WINDEFS_FILE));
  status=shell('"'path:+WINDEFS_FILE'"');
  process_make_rc(status,WINDEFS_FILE);
  #if __MACOSX__
  message(nls('making %s',path:+MACOSXDEFS_FILE));
  status=shell('"'path:+MACOSXDEFS_FILE'"');
  process_make_rc(status,MACOSXDEFS_FILE);
  #endif
  // DJB 08-07-2013
  // Reloading error.e has not been necessary for years.
  //makeNload(path'error');   // After setting def_error_re, init again
  makeNload(path'forall');
  makeNload(path'math');
  makeNload(path'dir');
  makeNload(path'fileman');
  makeNload(path'compile');
  makeNload(path'last');
  makeNload(path'get');
  makeNload(path'restore');
  makeNload(path'c');
  makeNload(path'csymbols');
  makeNload(path'ccontext');
  makeNload(path'cjava');
  makeNload(path'cutil');
  makeNload(path'smartp');
  makeNload(path'pascal');
  makeNload(path'slickc');
  makeNload(path'codehelp');
  makeNload(path'codehelputil');

  // DJB (07/03/2006)
  // always load language support, even on Windows
  makeNload(path'4gl');
  makeNload(path'actionscript');
  makeNload(path'ada');
  makeNload(path'ansic');
  makeNload(path'antlr');
  makeNload(path'asm');
  makeNload(path'awk');
  makeNload(path'ch');
  makeNload(path'cics');
  makeNload(path'cobol');
  makeNload(path'd');
  makeNload(path'fortran');
  makeNload(path'model204');
  makeNload(path'modula');
  makeNload(path'msqbas');
  makeNload(path'objc');
  makeNload(path'perl');
  makeNload(path'pl1');
  makeNload(path'plsql');
  makeNload(path'prg');
  makeNload(path'properties');
  makeNload(path'python');
  makeNload(path'ruby');
  makeNload(path'rul');
  makeNload(path'sas');
  makeNload(path'sqlservr');
  makeNload(path'tcl');
  makeNload(path'vbscript');
  makeNload(path'verilog');
  makeNload(path'vhdl');
  makeNload(path'lua');
  makeNload(path'css');
  makeNload(path'systemverilog');
  makeNload(path'vera');
  makeNload(path'ps1');
  makeNload(path'javascript');
  makeNload(path'erlang');
  makeNload(path'haskell');
  makeNload(path'fsharp');
  makeNload(path'markdown');
  makeNload(path'coffeescript');
  makeNload(path'googlego');
  makeNload(path'ttcn');
  makeNload(path'cg');
  makeNload(path'matlab');
  makeNload(path'scala');

  makeNload(path'pmatch');
  makeNload(path'doscmds');
  makeNload(path'os2cmds');
  makeNload(path'extern');
  makeNload(path'env');
  makeNload(path'util');
  makeNload(path'selcob');
  //makeNload(path'index')
  // Load system forms.
  rc='';
  //filename=get_env('VSROOT')'macros':+FILESEP:+(SYSOBJS_FILE:+_macro_ext);
  filename = path:+(SYSOBJS_FILE:+_macro_ext);
  if ( filename!='') {
     message(nls('Running %s',filename));
     rc=xcom('"'filename'"');
     process_make_rc(rc,filename);
  }
  menu_mdi_bind_all();
  if ( rc=='' || ! rc ) {
     clear_message();
  }
  // load _open_temp_view,_delete_temp_view,_create_temp_view ...
  makeNload(path'sellist2');
  makeNload(path'seltree');
  makeNload(path'ini');
  makeNload(path'menu');
  makeNload(path'tags');
  //makeNload(path'ctags')  We use cparse.dll instead
  makeNload(path'compare');
  makeNload(path'alias');
  makeNload(path'bookmark');
  makeNload(path'pushtag');
  makeNload(path'dlgeditv');
  makeNload(path'deupdate');
  makeNload(path'dlgman');
  makeNload(path'tbfilelist');
  makeNload(path'controls');
  makeNload(path'spin');
  makeNload(path'listbox');
  makeNload(path'treeview');
  makeNload(path'sstab');
  makeNload(path'combobox');
  makeNload(path'dirlist');
  makeNload(path'dirlistbox');
  makeNload(path'dirtree');
  makeNload(path'drvlist');
  makeNload(path'filelist');
  makeNload(path'frmopen');
  makeNload(path'guiopen');
  makeNload(path'listproc');
  makeNload(path'color');
  makeNload(path'guicd');
  makeNload(path'picture');
  makeNload(path'inslit');
  makeNload(path'filters');
  makeNload(path'font');
  makeNload(path'wfont');
  makeNload(path'fsort');
  makeNload(path'listproc');
  makeNload(path'spell');
  makeNload(path'mprompt');
  makeNload(path'seek');
  makeNload(path'projconv');
  makeNload(path'projutil');
  makeNload(path'project');
  makeNload(path'ptoolbar');
  makeNload(path'tbopen');
  makeNload(path'vstudiosln');
  makeNload(path'wkspace');
  makeNload(path'projmake');
  makeNload(path'wman');
  makeNload(path'packs');
  makeNload(path'rte');
  makeNload(path'tbfind');

  makeNload(path'guifind');
  makeNload(path'guireplace');

  dllloadNcheck(dllpath:+'vsockapi');

  makeNload(path'ftpq');
  makeNload(path'ftp');
  makeNload(path'ftpclien');
  makeNload(path'ftpopen');
  makeNload(path'ftpparse');
  makeNload(path'sftp');
  makeNload(path'sftpclien');
  makeNload(path'sftpopen');
  makeNload(path'sftpparse');
  makeNload(path'sftpq');
  makeNload(path'makefile');
  makeNload(path'context');
  makeNload(path'cbrowser');
  makeNload(path'autocomplete');
  // Be sure that proctree stays under cbrowser because cbrowser loads the bitmaps
  makeNload(path'proctree');
  makeNload(path'tbclass');
  makeNload(path'caddmem');
  makeNload(path'printcommon');
#if __UNIX__
  makeNload(path'winman');
#endif
  makeNload(path'print');
  makeNload(path'poperror');
  makeNload(path'b2k');
  makeNload(path'keybindings');
  makeNload(path'event');
  makeNload(path'mfsearch');
  makeNload(path'bgsearch');
  makeNload(path'dockchannel');
  makeNload(path'toolbar');
  makeNload(path'qtoolbar');
  makeNload(path'tbview');
  makeNload(path'tbpanel');
  makeNload(path'tbtabgroup');
  makeNload(path'tbdockchannel');
  makeNload(path'tbautohide');
  makeNload(path'tbgrabbar');
  makeNload(path'tbcontrols');
  makeNload(path'tbprops');
  makeNload(path'tbcmds');
  makeNload(path'tbdeltasave');
  //tbResetAll(); // Setup initial toolbars
  makeNload(path'searchcb');
  makeNload(path'config');
  makeNload(path'pconfig');
  makeNload(path'filecfg');
  makeNload(path'fontcfg');
  makeNload(path'setupext');

  // VersionControlSettings api
  makeNload(path'se'FILESEP'vc'FILESEP'VersionControlSettings');

  makeNload(path'calc');
  makeNload(path'hex');
  //makeNload(path'readonly')
  makeNload(path'findfile');
  makeNload(path'menuedit');
  makeNload(path'tagwin');
  makeNload(path'tagrefs');
  makeNload(path'tagfind');
  makeNload(path'backtag');
  makeNload(path'tagform');
  makeNload(path'debug');
  makeNload(path'debuggui');
  makeNload(path'debugpkg');
  makeNload(path'deltasave');
  makeNload(path'coolfeatures');
  makeNload(path'tbregex');
  makeNload(path'errorcfgdlg');
  makeNload(path'hotspots');
  makeNload(path'tbprojectcb');
  makeNload(path'guidgen');
  makeNload(path'annotations');
  makeNload(path'licensemgr');
  makeNload(path'moveline');
  makeNload(path'taghilite');
  makeNload(path'tbclipbd');
  makeNload(path'docbook');
  makeNload(path'rexx');
  makeNload(path'tbxmloutline');

  // All Languages
  makeNload(path'se'FILESEP'options'FILESEP'AllLanguagesTable');
  makeNload(path'alllanguages');

#if !__UNIX__
  _dllexport("int vsscc:_SccListProviders()",0,0);
  _dllexport("int vsscc:_SccGetNumberOf32BitSystems()",0,0);
  _dllexport("int vsscc:_SccInit(VSPSZ)",0,0);
  _dllexport("void vsscc:_SccUninit()",0,0);
  _dllexport("void vsscc:_SccInitOptions()",0,0);
  _dllexport("int vsscc:_SccGetCommandOptions(int)",0,0);
  _dllexport("int vsscc:_SccOpenProject(int,VSPSZ)",0,0);
  _dllexport("VSPSZ vsscc:_SccGetCurProjectInfo(int)",0,0);
  _dllexport("VSPSZ vsscc:_SccGetProviderDllName(VSPSZ)",0,0);
  _dllexport("int vsscc:_SccCloseProject()",0,0);
  _dllexport("int vsscc:_SccProperties(VSPSZ)",0,0);
  _dllexport("int vsscc:_SccCheckout(VSHREFVAR,VSPSZ)",0,0);
  _dllexport("int vsscc:_SccGet(VSHREFVAR)",0,0);
  _dllexport("int vsscc:_SccUncheckout(VSHREFVAR)",0,0);
  _dllexport("int vsscc:_SccDiff(VSPSZ)",0,0);
  _dllexport("int vsscc:_SccCheckin(VSHREFVAR,VSPSZ)",0,0);
  _dllexport("int vsscc:_SccAdd(VSHREFVAR,VSPSZ)",0,0);
  _dllexport("int vsscc:_SccRemove(VSHREFVAR,VSPSZ)",0,0);
  _dllexport("int vsscc:_SccRename(VSPSZ,VSPSZ)",0,0);
  _dllexport("int vsscc:_SccHistory(VSHREFVAR)",0,0);
  _dllexport("int vsscc:_SccRunScc(VSHREFVAR)",0,0);
  _dllexport("int vsscc:_SccPopulateList(int,VSHREFVAR)",0,0);
  _dllexport("void vsscc:_SccGetVersion(VSHREFVAR,VSHREFVAR)",0,0);
  _dllexport("int vsscc:_SccQueryInfo(VSHREFVAR,VSHREFVAR)",0,0);
  _dllexport("int vsscc:_SccQueryInfo2(VSHREFVAR,VSHREFVAR,int)",0,0);
  _dllexport("int vsscc:_SccGetProviderCapabilities()",0,0);

#endif
  makeNload(path'vc');

  makeNload(path'varedit');
  makeNload(path'aliasedt');
  makeNload(path'pipe');
  makeNload(path'argument');

  dllloadNcheck(dllpath:+'tagsdb');
  dllloadNcheck(dllpath:+'cparse');
  dllloadNcheck(dllpath:+'vsdebug');
  dllloadNcheck(dllpath:+'vsrefactor');
  dllloadNcheck(dllpath:+'vsRTE');
#if __PCDOS__
  dllloadNcheck(dllpath:+'vccache');
#endif
  refresh();
  makeNload(path'help');   /* help must be loaded last. */
  makeNload(path'vlstobjs');
  makeNload(path'savecfg');
  makeNload(path'ccode');
  makeNload(path'selcode');
  makeNload(path'seldisp');
  makeNload(path's390');
  makeNload(path'dsutil');
#if __OS390__ || __TESTS390__
  makeNload(path'changeman');
#endif
  makeNload(path'jobutil');
  makeNload(path'calib');

#if __UNIX__
  dllloadNcheck(dllpath:+'vshlp');
#else
  //vsDllExport("int   _hi_save_idx_file(VSPSZ pszFilename)",0,0);
  //vsDllExport("void  _hi_init_hash_table()",0,0);
  //vsDllExport("void  _hi_free_hash_heap()",0,0);
  //vsDllExport("VSPSZ _hi_helpfile_description(VSPSZ pszFilename)",0,0);
  _dllexport("int vshlp:_SaveSelDisp(VSPSZ pszFilename,VSPSZ pszFileDate)");
  _dllexport("int vshlp:_RestoreSelDisp(VSPSZ pszFilename,VSPSZ pszFileDate)");

  _dllexport("int vshlp:_winhelpfind(VSPSZ pszFilename,VSPSZ pszKeyword,int HelpType,int ListBoxFormat)",0,0);
  _dllexport("VSPSZ vshlp:_winhelptitle(VSPSZ pszFilename)",0,0);
  _dllexport("int vshlp:_hi_add_files(VSPSZ,int,int,int)",0,0);
  _dllexport("int vshlp:_hi_hit_list(VSPSZ pszHelpPrefix,VSPSZ pszFilename, int InitTable, int LBWid, int CompleteMatch)",0,0);
  _dllexport("_command void vshlp:vshlp_version()",0,0);
  _dllexport("int vshlp:_hi_insert_helpfile_list(VSPSZ)",0,0);
  _dllexport("int vshlp:_hi_new_idx_file(VSPSZ)",0,0);
  _dllexport("int vshlp:_JavaGetClassRefList(VSPSZ pszClassFilename,VSHREFVAR hvarArray)",0,0);
  _dllexport("int vshlp:_InsertProjectFileList(VSHREFVAR,VSHREFVAR,,VSHREFVAR,int,int,int)",0,0);
  _dllexport("int vshlp:_InsertProjectFileListXML(int,VSHREFVAR,int,int,int,int,int,VSHREFVAR,int)",0,0);
  _dllexport("void vshlp:_InsertProjectFileListXML_WithoutFolders(int treeParentIndex,int workspaceHandle,VSHREFVAR hvarProjectHandleList,VSPSZ pszFilter,int pic_file)",0,0);
  _dllexport("void vshlp:_FreeSccDll()",0,0);
  _dllexport("int vshlp:_IsFileMatchedExtension(VSPSZ pszFilename,VSPSZ pszPattern)",0,0);
  _dllexport("int vshlp:_GetDiskSpace(VSPSZ pszPath,VSHREFVAR hvarTotalSpace,VSHREFVAR hvarFreeSpace)",0,0);
  _dllexport("int vshlp:_FilterTreeControl(VSPSZ pszFilter,int iPrefixFilter)",0,0);
  _dllexport("int vshlp:_FileTreeRemoveFileOriginFromFile(int iIndex, VSPSZ pszOriginsToRemove, VSPSZ pszFilter, VSHREFVAR htPicIndices)",0,0);
  _dllexport("int vshlp:_FileTreeRemoveFileOrigin(VSPSZ pszOriginsToRemove, VSHREFVAR deletedCaptions, VSPSZ pszFilter, VSHREFVAR htPicIndices)",0,0);
  _dllexport("void vshlp:_FileTreeAddFileOrigin(int index, VSPSZ pszAddedOrigins, int iBufId, VSPSZ pszFilter, VSHREFVAR htPicIndices)",0,0);
  _dllexport("int vshlp:_FileTreeAddFile(VSPSZ pszFile, VSPSZ pszOrigins, int iBufId, VSPSZ pszFilter, VSHREFVAR htPicIndices)",0,0);
  _dllexport("int vshlp:_findFirstTimeOut(VSPSZ pszFilename, int milliTimeout,int milliContinueToFail)",0,0);
  _dllexport("int vshlp:_fileIOTimeOut(VSPSZ pszFilename, int milliTimeout)",0,0);
  _dllexport("int vshlp:_FileListAddFile(int iTreeIndex,VSPSZ pszFile,VSPSZ pszFilter,int iBufId,int iPicFile,int iTreeNodeFlags)",0,0);
  _dllexport("int vshlp:_FileListAddFilesInProject(VSPSZ pszWorkspaceFile,VSPSZ pszProjectFile,int iTreeIndex,int iPicIndex)",0,0);

  // winutils exports
  // A lot of this was originally in vshlp. But now the Windows-only code resides in winutils.dll
  _dllexport("int winutils:ntSupportOpenDialog()",0,0);
  _dllexport("VSPSZ winutils:ntOpenDialog(int TemplateId,int owner_wid,VSPSZ pszTitle,VSPSZ pszInitialWildCards,VSPSZ pszFileFilters,int NTOFNFlags,int VSOFNFlags,VSPSZ pszDefaultExt,VSPSZ pszInitialFilename,VSPSZ pszInitialDirectory,VSPSZ pszRetrieveName,VSPSZ pszHelpItem)",0,0);
  _dllexport("int winutils:NTShellExecute(VSPSZ pszOperation,VSPSZ pszFilename,VSPSZ pszParams,VSPSZ pszDir)");
  _dllexport("int winutils:NTShellExecuteEx(VSPSZ pszOperation, VSPSZ pszFilename, VSPSZ pszParams, VSPSZ pszDir, VSHREFVAR exitCode)");
  _dllexport("VSPSZ winutils:NTNetGetConnection(VSPSZ DriveString)");
  _dllexport("int winutils:NTNetGetDomainComputers(int wid)",0,0);
  _dllexport("int winutils:NTNetGetComputerShares(int wid, VSPSZ pszComputerName)",0,0);
  _dllexport("int winutils:ntGetExplorerShowHiddenFlags()",0,0);
  _dllexport("void winutils:ntGetSpecialFolderPath(VSHREFVAR hvarAppDataPath,int csidl_special_folder)",0,0);
  _dllexport("int winutils:ntGetVolumeInformation(VSPSZ pszPath,VSHREFVAR hvarFSName,VSHREFVAR hvarFSFlags)",0,0);
  _dllexport("int winutils:ntGetVolumeSN(VSPSZ pszPath,VSHREFVAR hvarVSN)",0,0);
  _dllexport("int winutils:ntIISGetVirtualDirectoryPath(VSPSZ vdirname, VSHREFVAR path)",0,0);
//_dllexport("VSPSZ winutils:_ntRegQueryValue(int ConstantHkey,VSPSZ pszPath,VSPSZ pszDefault)");
  _dllexport("int winutils:_ntRegFindFirstValue(int iRootKey,VSPSZ vspszSubKeyName,VSHREFVAR hvarVarName,VSHREFVAR hvarValVal,int FindFirst)");
  _dllexport("int winutils:_ntRegFindFirstSubKey(int iRootKey,VSPSZ vspszSubKeyPath,VSHREFVAR hvarVarName,int FindFirst)");
  _dllexport("int winutils:_associatefiletypetovs(VSPSZ pszExtnodot)");
  _dllexport("int winutils:_registervs(VSPSZ pszExeFilename)");
  _dllexport("VSPSZ winutils:_ntgetdefaultprintinfo()",0,0);
  _dllexport("void winutils:ntGetVersionEx(VSHREFVAR hvarMajorVersion,VSHREFVAR hvarMinorVersion,VSHREFVAR hvarBuildNumber,VSHREFVAR hvarPlatformId,VSHREFVAR hvarCSDVersion)",0,0);
  _dllexport("int winutils:ntIs64Bit()",0,0);
  _dllexport("void winutils:ntGlobalMemoryStatus(VSHREFVAR hvarMemoryLoad,VSHREFVAR hvarTotalPhys,VSHREFVAR hvarAvailPhys,VSHREFVAR hvarTotalPageFile,VSHREFVAR hvarAvailPageFile,VSHREFVAR hvarTotalVirtual,VSHREFVAR hvarAvailVirtual)",0,0);
  _dllexport("void winutils:ntGetMaxCommandLength()",0,0);
  _dllexport("int winutils:NTAddAceToObjectsSecurityDescriptor(VSPSZ pszObjName,int ObjectType,VSPSZ pszTrustee,int dwAccessRights,int AccessMode,int dwInheritance)");
  _dllexport("void winutils:ntGetGUID(VSHREFVAR hvarguid)",0,0);

  // winutils registry stuff
  _dllexport("int winutils:_ntRegFindLatestVersion(int root, VSPSZ subkey, VSHREFVAR version, int requiredMajor)");
  _dllexport("VSPSZ winutils:_ntRegQueryValue(int root, VSPSZ subkey, VSPSZ defaultValue, VSPSZ valueName)");
  _dllexport("VSPSZ winutils:_ntRegGetLatestVersionValue(int root, VSPSZ prefixPath, VSPSZ suffixPath, VSPSZ valueName)");

  // vchack exports
  _dllexport("int vchack:AppMenu(VSPSZ,VSPSZ,VSPSZ,int,int,int)");
  _dllexport("int vchack:MaybeAddVSEToVCPPRegEntry(VSPSZ,VSPSZ,VSPSZ)");
  _dllexport("int vchack:MaybeAddVSEToVCPPMenu()");
  _dllexport("int vchack:GetVCPPBinPath(VSHREFVAR,int)");
  _dllexport("int vchack:VCPPIsUp(int)");
  _dllexport("int vchack:VCPPIsVisible(int)");
  _dllexport("void vchack:VCPPInit(VSPSZ,VSPSZ)");
  _dllexport("int vchack:VCPPIsVSEOnMenu(int)");
  _dllexport("void vchack:VCPPSaveFiles(VSPSZ)");
  _dllexport("int vchack:FindVCPPReloadMessageBox()");
  _dllexport("void vchack:VCPP5Help(VSPSZ,int)");
  _dllexport("int vchack:TornadoIsUp()",0,0);
  _dllexport("int vchack:TornadoIsVisible()",0,0);
  _dllexport("int vchack:VCPPListAvailableVersions()",0,0);
  _dllexport("int vchack:HTMLHelpAvailable()",0,0);
  _dllexport("int vchack:msdn_num_collections()");
  _dllexport("int vchack:msdn_collection_info(int,VSHREFVAR,VSHREFVAR)");
  _dllexport("int vchack:msdn_keyword_help(VSPSZ,VSPSZ,VSPSZ)");
  _dllexport("int vchack:vstudio_open_file(VSPSZ,int,int)");
  _dllexport("int vchack:vstudio_open_solution(VSPSZ,VSPSZ)");

  _dllexport("int filewatcher:filewatcherAddPath(VSPSZ,int,int)");
  _dllexport("void filewatcher:filewatcherRemovePath(VSPSZ,int)");
  _dllexport("void filewatcher:filewatcherRemoveType(int)");
  _dllexport("void filewatcher:filewatcherInitType(int)");
  _dllexport("void filewatcher:filewatcherStop(int)");
  _dllexport("int filewatcher:_GetFastReloadInfoTable(VSHREFVAR,int,int,VSHREFVAR,int)");
  _dllexport("int filewatcher:_GetSlowReloadFiles(VSHREFVAR)");
  makeNload(path'vchack');
#endif

  dllloadNcheck(dllpath:+'vsvcs');
  // want hour glass code soon.
  makeNload(path'se'FILESEP'util'FILESEP'MousePointerGuard');
  makeNload(path'diff');
  makeNload(path'diffprog');
  makeNload(path'diffedit');
  makeNload(path'diffmf');
  makeNload(path'diffencode');
  makeNload(path'diffinsertsym');
  makeNload(path'difftags');
  makeNload(path'se/diff/DiffSession');
  makeNload(path'diffsetup');
  makeNload(path'merge');
  makeNload(path'history');
  makeNload(path'compword');
  makeNload(path'cformat');
  makeNload(path'csbeaut');
  makeNload(path'beautifier');
  dllloadNcheck(dllpath:+'cformat');
  dllloadNcheck(dllpath:+'filewatcher');
  makeNload(path'hformat');
  makeNload(path'adaformat');
  makeNload(path'refactor');
  makeNload(path'refactorgui');
  makeNload(path'javacompilergui');
  makeNload(path'jrefactor');
  makeNload(path'quickrefactor');
  makeNload(path'java');

  // DJB (07/03/2006)
  // always load these, even on Windows
  makeNload(path'argument');
  makeNload(path'briefsch');
  makeNload(path'briefutl');
  makeNload(path'poperror');

  makeNload(path'prefix');
  makeNload(path'emacs');
  makeNload(path'gemacs');

  makeNload(path'ex');
  makeNload(path'vi');
  makeNload(path'vicmode');
  makeNload(path'viimode');
  makeNload(path'vivmode');
  makeNload(path'ispf');
  makeNload(path'ispflc');
  makeNload(path'ispfsrch');

  makeNload(path'html');
  makeNload(path'htmltool');
  makeNload(path'bufftabs');
  makeNload(path'enum');
  makeNload(path'helpidx');
  makeNload(path'box');
  makeNload(path'commentformat');
  makeNload(path'xmlwrap');
  makeNload(path'xmlwrapgui');
  makeNload(path'ppedit');
  makeNload(path'autosave');
  makeNload(path'xmldoc');
  makeNload(path'javadoc');
  makeNload(path'javaopts');
  makeNload(path'applet');
  makeNload(path'gwt');
  makeNload(path'ejb');
  makeNload(path'wizard');
  makeNload(path'gnucopts');
  makeNload(path'vcppopts');
  makeNload(path'phpopts');
  makeNload(path'pythonopts');
  makeNload(path'perlopts');
  makeNload(path'rubyopts');
  makeNload(path'cvs');
  makeNload(path'commitset');
  makeNload(path'svc');
  makeNload(path'svchistory');
  makeNload(path'svcupdate');
  makeNload(path'svcrepobrowser');
  makeNload(path'cvsutil');
  makeNload(path'cvsquery');
  makeNload(path'git');
  makeNload(path'mercurial');

  makeNload(path'se'FILESEP'vc'FILESEP'IVersionControl.e');
  makeNload(path'se'FILESEP'vc'FILESEP'IVersionedFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'BackupHistoryVersionedFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'GitVersionedFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'HgVersionedFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'PerforceVersionedFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'SVNVersionedFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'CVSClass.e');
  makeNload(path'se'FILESEP'vc'FILESEP'GitClass.e');
  makeNload(path'se'FILESEP'vc'FILESEP'Hg.e');
  makeNload(path'se'FILESEP'vc'FILESEP'Perforce.e');
  makeNload(path'se'FILESEP'vc'FILESEP'SVN.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCCacheManager.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCRepositoryCache.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCBaseRevisionItem.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCBranch.e');
  makeNload(path'se'FILESEP'vc'FILESEP'IBuildFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'CVSBuildFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'GitBuildFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'HgBuildFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'NormalBuildFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'SubversionBuildFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCCacheExterns.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCExclusion.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCFile.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCFileType.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCInfo.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCLabel.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCRepository.e');
  makeNload(path'se'FILESEP'vc'FILESEP'VCRevision.e');
  makeNload(path'se'FILESEP'vc'FILESEP'SVNCache.e');
  makeNload(path'se'FILESEP'vc'FILESEP'QueuedVCCommand.e');
  makeNload(path'se'FILESEP'vc'FILESEP'QueuedVCCommandManager.e');

  makeNload(path'subversion');
  makeNload(path'subversionbrowser');
  makeNload(path'subversionutil');
  makeNload(path'historydiff');
  makeNload(path'surround');
  makeNload(path'j2me');
  makeNload(path'upcheck');
  makeNload(path'hotfix');
  makeNload(path'contact_support');
  makeNload(path'junit');
  makeNload(path'unittest');
  makeNload(path'xcode');
  makeNload(path'maven');
  makeNload(path'codetemplate');
  makeNload(path'ctcategory');
  makeNload(path'ctitem');
  makeNload(path'ctadditem');
  makeNload(path'ctviews');
  makeNload(path'ctmanager');
  makeNload(path'ctoptions');
  // moved this from a batch macro - sg - 12.11.07
  makeNload(path'assocft');
  makeNload(path'android');
#if __UNIX__
  //makeNload(path'tornadou');
#else
  makeNload(path'tornado');
#endif

  // adaptive formatting - sg - 9.18.07
  makeNload(path'sc'FILESEP'collections'FILESEP'Stack');
  makeNload(path'se'FILESEP'adapt'FILESEP'AdaptiveFormattingScannerBase');
  makeNload(path'se'FILESEP'adapt'FILESEP'GenericAdaptiveFormattingScanner');
  makeNload(path'se'FILESEP'lang'FILESEP'cpp'FILESEP'CPPAdaptiveFormattingScanner');
  makeNload(path'se'FILESEP'lang'FILESEP'pas'FILESEP'PascalAdaptiveFormattingScanner');
  makeNload(path'se'FILESEP'lang'FILESEP'dbase'FILESEP'DBaseAdaptiveFormattingScanner');
  makeNload(path'se'FILESEP'lang'FILESEP'tcl'FILESEP'TCLAdaptiveFormattingScanner');
  makeNload(path'se'FILESEP'lang'FILESEP'html'FILESEP'HTMLAdaptiveFormattingScanner');
  makeNload(path'adaptiveformatting');

  // new options dialog - sg - 9.11.07
  makeNload(path'se'FILESEP'options'FILESEP'IPropertyDependency');
  makeNload(path'se'FILESEP'options'FILESEP'PropertyDependencySet');
  makeNload(path'se'FILESEP'options'FILESEP'CategoryHelpPanel');
  makeNload(path'se'FILESEP'options'FILESEP'Condition');
  makeNload(path'se'FILESEP'options'FILESEP'IPropertyTreeMember');
  makeNload(path'se'FILESEP'options'FILESEP'Property');
  makeNload(path'se'FILESEP'options'FILESEP'PropertyGroup');
  makeNload(path'se'FILESEP'options'FILESEP'BooleanProperty');
  makeNload(path'se'FILESEP'options'FILESEP'ColorProperty');
  makeNload(path'se'FILESEP'options'FILESEP'DependencyTree');
  makeNload(path'se'FILESEP'options'FILESEP'NumericProperty');
  makeNload(path'se'FILESEP'options'FILESEP'Path');
  makeNload(path'se'FILESEP'options'FILESEP'PropertyGetterSetter');
  makeNload(path'se'FILESEP'options'FILESEP'RelationTable');
  makeNload(path'se'FILESEP'options'FILESEP'Select');
  makeNload(path'se'FILESEP'options'FILESEP'SelectChoice');
  makeNload(path'se'FILESEP'options'FILESEP'TextProperty');
  makeNload(path'se'FILESEP'options'FILESEP'OptionsPanelInfo');
  makeNload(path'se'FILESEP'options'FILESEP'DialogTransformer');
  makeNload(path'se'FILESEP'options'FILESEP'DialogEmbedder');
  makeNload(path'se'FILESEP'options'FILESEP'DialogExporter');
  makeNload(path'se'FILESEP'options'FILESEP'DialogTagger');
  makeNload(path'se'FILESEP'options'FILESEP'PropertySheet');
  makeNload(path'se'FILESEP'options'FILESEP'PropertySheetEmbedder');
  makeNload(path'se'FILESEP'options'FILESEP'OptionsXMLParser');
  makeNload(path'se'FILESEP'options'FILESEP'OptionsData');
  makeNload(path'se'FILESEP'options'FILESEP'OptionsHistoryNavigator');
  makeNload(path'se'FILESEP'options'FILESEP'OptionsTree');
  makeNload(path'se'FILESEP'options'FILESEP'OptionsConfigTree');
  makeNload(path'se'FILESEP'options'FILESEP'OptionsExportTree');
  makeNload(path'se'FILESEP'options'FILESEP'OptionsImportTree');
  makeNload(path'se'FILESEP'options'FILESEP'ExportImportGroup');
  makeNload(path'se'FILESEP'options'FILESEP'ExportImportGroupManager');
  makeNload(path'se'FILESEP'options'FILESEP'OptionsConfigurationXMLParser');
  makeNload(path'optionsxml');
  makeNload(path'propertysheetform.e');

  makeNload(path'sc'FILESEP'controls'FILESEP'CheckboxTree.e');
  makeNload(path'se'FILESEP'options'FILESEP'OptionsCheckBoxTree.e');
  makeNload(path'sc'FILESEP'controls'FILESEP'RubberBand.e');

  // WWTS
  //makeNload(path'WWTS');
  //makeNload(path'se'FILESEP'vc'FILESEP'IWWTSInterface');
  //makeNload(path'se'FILESEP'vc'FILESEP'VCInfo');
  //makeNload(path'se'FILESEP'vc'FILESEP'WWTSFile');
  //makeNload(path'se'FILESEP'vc'FILESEP'WWTSLine');
  //makeNload(path'se'FILESEP'vc'FILESEP'IWWTSIdentifier');
  //makeNload(path'se'FILESEP'vc'FILESEP'WWTSModel');
  //makeNload(path'se'FILESEP'vc'FILESEP'WWTSCVS');
  //makeNload(path'se'FILESEP'vc'FILESEP'VCSFactory');
  //makeNload(path'se'FILESEP'vc'FILESEP'VCFileType');
  //makeNload(path'se'FILESEP'vc'FILESEP'WWTSDisplay');
  //makeNload(path'se'FILESEP'vc'FILESEP'WWTSDisplayQueue');
  //makeNload(path'se'FILESEP'vc'FILESEP'WWTSProcessManager');
  //makeNload(path'se'FILESEP'vc'FILESEP'WWTSUserIdentifier');
  //makeNload(path'se'FILESEP'vc'FILESEP'WWTSCVSTagIdentifier');
  //makeNload(path'se'FILESEP'vc'FILESEP'WWTSRelativeAgeIdentifier');
  //makeNload(path'se'FILESEP'vc'FILESEP'VCInfo');
  //makeNload(path'se'FILESEP'vc'FILESEP'ILabelFetcher');
  //makeNload(path'se'FILESEP'vc'FILESEP'CVSLabelFetcher');

  // Message Lists
  makeNload(path'se'FILESEP'util'FILESEP'Observer');
  makeNload(path'se'FILESEP'util'FILESEP'Subject');
  makeNload(path'se'FILESEP'lineinfo'FILESEP'FieldInfo');
  makeNload(path'se'FILESEP'lineinfo'FILESEP'LineInfo');
  makeNload(path'se'FILESEP'lineinfo'FILESEP'LineInfoCollection');
  makeNload(path'se'FILESEP'lineinfo'FILESEP'LineInfoBrowser');
  makeNload(path'se'FILESEP'lineinfo'FILESEP'LineInfoDefinitions');
  makeNload(path'se'FILESEP'lineinfo'FILESEP'LineInfoFiles');
  makeNload(path'se'FILESEP'lineinfo'FILESEP'RelocatableMarker');
  makeNload(path'se'FILESEP'lineinfo'FILESEP'TypeInfo');
  makeNload(path'se'FILESEP'messages'FILESEP'Message');
  makeNload(path'se'FILESEP'messages'FILESEP'MessageCollection');
  makeNload(path'se'FILESEP'messages'FILESEP'MessageBrowser');

  // DateTime
  makeNload(path'se'FILESEP'datetime'FILESEP'DateTime');
  makeNload(path'se'FILESEP'datetime'FILESEP'DateTimeDuration');
  makeNload(path'se'FILESEP'datetime'FILESEP'DateTimeInterval');
  makeNload(path'se'FILESEP'datetime'FILESEP'DateTimeFilters');
  makeNload(path'calendar');

  // Tagging and Symbol Coloring
  makeNload(path'se'FILESEP'tags'FILESEP'SymbolInfo');
  makeNload(path'se'FILESEP'tags'FILESEP'SymbolTable');
  makeNload(path'se'FILESEP'tags'FILESEP'TaggingGuard');
  makeNload(path'se'FILESEP'color'FILESEP'ColorInfo');
  makeNload(path'se'FILESEP'color'FILESEP'ColorScheme');
  makeNload(path'se'FILESEP'color'FILESEP'DefaultColorsConfig');
  makeNload(path'se'FILESEP'color'FILESEP'IColorCollection');
  makeNload(path'se'FILESEP'color'FILESEP'LineNumberRanges');
  makeNload(path'se'FILESEP'color'FILESEP'SymbolColorRule');
  makeNload(path'se'FILESEP'color'FILESEP'SymbolColorRuleBase');
  makeNload(path'se'FILESEP'color'FILESEP'SymbolColorRuleIndex');
  makeNload(path'se'FILESEP'color'FILESEP'SymbolColorAnalyzer');
  makeNload(path'se'FILESEP'color'FILESEP'SymbolColorConfig');
  makeNload(path'se'FILESEP'color'FILESEP'SymbolColorDoubleBuffer');

  // Net
  makeNload(path'se'FILESEP'net'FILESEP'IOnCancelHandler');
  makeNload(path'se'FILESEP'net'FILESEP'IServerConnection');
  makeNload(path'se'FILESEP'net'FILESEP'IServerConnectionObserver');
  makeNload(path'se'FILESEP'net'FILESEP'ServerConnection');
  makeNload(path'se'FILESEP'net'FILESEP'ServerConnectionObserver');
  makeNload(path'se'FILESEP'net'FILESEP'ServerConnectionObserverDialog');
  makeNload(path'se'FILESEP'net'FILESEP'ServerConnectionObserverMessage');
  makeNload(path'se'FILESEP'net'FILESEP'ServerConnectionObserverFormInstance');
  makeNload(path'se'FILESEP'net'FILESEP'ServerConnectionPool');

  // Search
  makeNload(path'se'FILESEP'search'FILESEP'SearchResults');

  // compile all the other macro files
  makeNload(path'addons',false);
  makeNload(path'altsetup',false);
  makeNload(path'bbedit',false);
  makeNload(path'bbeditdef',false);
  makeNload(path'briefdef',false);
  makeNload(path'cleanup',false);
  makeNload(path'cmmode',false);
  makeNload(path'codewarrior',false);
  makeNload(path'codewarriordef',false);
  makeNload(path'codewrightdef',false);
  makeNload(path'cwprojconv',false);
  makeNload(path'draw',false);
  makeNload(path'eclipsedef',false);
  //makeNload(path'editflst',false);
  makeNload(path'emacsdef',false);
  makeNload(path'emulate',false);
  makeNload(path'fill',false);
  makeNload(path'gendtd',false);
  makeNload(path'gnudef',false);
  makeNload(path'guisetup',false);
  makeNload(path'ispfdef',false);
  makeNload(path'maketags',false);
  makeNload(path'postinstall',false);
  makeNload(path'pro',false);
  makeNload(path'sabl',false);
  makeNload(path'slickdef',false);
  makeNload(path'updateobjs',false);
  makeNload(path'vcpp',false);
  makeNload(path'vcppdef',false);
  makeNload(path'videf',false);
  makeNload(path'vlstcfg',false);
  makeNload(path'vlstkeys',false);
  makeNload(path'vsnet',false);
  makeNload(path'vsnetdef',false);
  makeNload(path'vusrmods',false);
  makeNload(path'xcodedef',false);

  // DBGp
  makeNload(path'se'FILESEP'debug'FILESEP'dbgp'FILESEP'dbgp');
  makeNload(path'se'FILESEP'debug'FILESEP'dbgp'FILESEP'dbgputil');
  makeNload(path'se'FILESEP'debug'FILESEP'dbgp'FILESEP'DBGpOptions');

  // Xdebug
  makeNload(path'se'FILESEP'debug'FILESEP'xdebug'FILESEP'xdebug');
  makeNload(path'se'FILESEP'debug'FILESEP'xdebug'FILESEP'xdebugattach');
  makeNload(path'se'FILESEP'debug'FILESEP'xdebug'FILESEP'xdebugutil');
  makeNload(path'se'FILESEP'debug'FILESEP'xdebug'FILESEP'xdebugprojutil');
  makeNload(path'se'FILESEP'debug'FILESEP'xdebug'FILESEP'XdebugConnectionMonitor');
  makeNload(path'se'FILESEP'debug'FILESEP'xdebug'FILESEP'XdebugConnectionProgressDialog');
  makeNload(path'se'FILESEP'debug'FILESEP'xdebug'FILESEP'XdebugOptions');

  // pydbgp
  makeNload(path'se'FILESEP'debug'FILESEP'pydbgp'FILESEP'pydbgp');
  makeNload(path'se'FILESEP'debug'FILESEP'pydbgp'FILESEP'pydbgpattach');
  makeNload(path'se'FILESEP'debug'FILESEP'pydbgp'FILESEP'pydbgputil');
  makeNload(path'se'FILESEP'debug'FILESEP'pydbgp'FILESEP'PydbgpConnectionMonitor');
  makeNload(path'se'FILESEP'debug'FILESEP'pydbgp'FILESEP'PydbgpConnectionProgressDialog');
  makeNload(path'se'FILESEP'debug'FILESEP'pydbgp'FILESEP'PydbgpOptions');

  // menu and toolbar customizations
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'UserControl');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'MenuControl');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'ToolbarControl');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'UserModification');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'MenuModification');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'ToolbarModification');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'Separator');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'MenuSeparator');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'ToolbarSeparator');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'CustomizationHandler');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'MenuCustomizationHandler');
  makeNload(path'sc'FILESEP'controls'FILESEP'customizations'FILESEP'ToolbarCustomizationHandler');

  // perl5db
  makeNload(path'se'FILESEP'debug'FILESEP'perl5db'FILESEP'perl5db.e');
  makeNload(path'se'FILESEP'debug'FILESEP'perl5db'FILESEP'perl5dbattach.e');
  makeNload(path'se'FILESEP'debug'FILESEP'perl5db'FILESEP'Perl5dbConnectionMonitor.e');
  makeNload(path'se'FILESEP'debug'FILESEP'perl5db'FILESEP'Perl5dbConnectionProgressDialog.e');
  makeNload(path'se'FILESEP'debug'FILESEP'perl5db'FILESEP'Perl5dbOptions.e');
  makeNload(path'se'FILESEP'debug'FILESEP'perl5db'FILESEP'perl5dbutil.e');

  // rdbgp
  makeNload(path'se'FILESEP'debug'FILESEP'rdbgp'FILESEP'rdbgp.e');
  makeNload(path'se'FILESEP'debug'FILESEP'rdbgp'FILESEP'rdbgpattach.e');
  makeNload(path'se'FILESEP'debug'FILESEP'rdbgp'FILESEP'RdbgpConnectionMonitor.e');
  makeNload(path'se'FILESEP'debug'FILESEP'rdbgp'FILESEP'RdbgpConnectionProgressDialog.e');
  makeNload(path'se'FILESEP'debug'FILESEP'rdbgp'FILESEP'RdbgpOptions.e');
  makeNload(path'se'FILESEP'debug'FILESEP'rdbgp'FILESEP'rdbgputil.e');

  // product improvement program
  makeNload(path'pip');
  makeNload(path'enterpriseoptions');

  // notifications
  makeNload(path'notifications.e');
  makeNload(path'tbnotification.e');

  makeNload(path'se'FILESEP'ui'FILESEP'IHotspotMarker');
  makeNload(path'se'FILESEP'ui'FILESEP'IKeyEventCallback');
  makeNload(path'se'FILESEP'ui'FILESEP'ITextChangeListener');
  makeNload(path'se'FILESEP'ui'FILESEP'IOvertypeListener');
  makeNload(path'se'FILESEP'ui'FILESEP'TextChange');
  makeNload(path'se'FILESEP'ui'FILESEP'EventUI');
  makeNload(path'se'FILESEP'ui'FILESEP'NavMarker');
  makeNload(path'se'FILESEP'ui'FILESEP'OvertypeMarker');
  makeNload(path'se'FILESEP'ui'FILESEP'StreamMarkerGroup');
  makeNload(path'se'FILESEP'ui'FILESEP'HotspotMarkers');

  // auto bracket
  makeNload(path'se'FILESEP'autobracket'FILESEP'IAutoBracket');
  makeNload(path'se'FILESEP'autobracket'FILESEP'DefaultAutoBracket');
  makeNload(path'se'FILESEP'autobracket'FILESEP'AutoBracketListener');
  makeNload(path'se'FILESEP'lang'FILESEP'generic'FILESEP'GenericAutoBracket');
  makeNload(path'se'FILESEP'lang'FILESEP'cpp'FILESEP'CPPAutoBracket');
  makeNload(path'se'FILESEP'lang'FILESEP'objectivec'FILESEP'ObjectiveCAutoBracket');
  makeNload(path'se'FILESEP'lang'FILESEP'markdown'FILESEP'MarkdownAutoBracket');
  makeNload(path'se'FILESEP'lang'FILESEP'matlab'FILESEP'MatlabAutoBracket');
  makeNload(path'se'FILESEP'lang'FILESEP'xml'FILESEP'XMLAutoBracket');
  makeNload(path'se'FILESEP'ui'FILESEP'AutoBracketMarker');
  makeNload(path'autobracket');

  // toast notification messages
  makeNload(path'toast.e');

  // windbg
  makeNload(path'se'FILESEP'debug'FILESEP'windbg'FILESEP'windbg.e');

  makeNload(path'se'FILESEP'alias'FILESEP'AliasFile');

  // Mark system forms
  int index=name_match('',1,OBJECT_TYPE);
  for (;;) {
     if (!index) break;
     if (substr(name_name(index),1,1)!='-') {
        if (name_info(index)!='') set_name_info(index,'');
     } else {
        set_name_info(index,FF_SYSTEM);
     }
     index=name_match('',0,OBJECT_TYPE);
  }

  // restore app activation flags and timers
  def_actapp=orig_def_actapp;
  _use_timers=1;

  // Mark system languages
  _EnumerateInstalledLanguages();

  /* By convention, vusrmods is a batch program which loads all */
  /* user specific modules and restores the users previous setup. */
  _str vusrmods_name=slick_path_search(USERMODS_FILE:+_macro_ext);
  if ( vusrmods_name!='' ) {
     message(nls('Running %s',vusrmods_name));
     status=shell('"'vusrmods_name'"');
     if ( status ) {
        rc=status;
        return(status);
     }
  }

  // Migrate the def-setup-* to def-language-*
  // and also update certain language settings.
  _UpgradeLanguageSetup();

  // Let the user know about any files that were not restored
  showMissingFileList(gMissingFileList);
  rc=0;
  return(0);
}
static void dllloadNcheck(_str filename)
{
   int status=_dllload(filename);
   if (status==FILE_NOT_FOUND_RC) {
      static int numWarnings;
      gMissingFileList[gMissingFileList._length()]=filename'.dll';
      if (!numWarnings) {
         int result=_message_box(nls("DLL File %s not found\nThis maybe normal if you are building a small state file for an OEM installation, and you will not be warned about other missing DLLs\n\nContinue?",filename),'',MB_YESNO);
         if (result==IDNO) {
            stop();
         }
      }
      ++numWarnings;
   }
}

static void showMissingFileList(_str (&fileList)[])
{
   if (fileList!=null) {
      show('-modal _sellist_form','The following files were missing',0,fileList);
   }
}

