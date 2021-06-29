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
#include "project.sh"
#import "complete.e"
#import "env.e"
#import "files.e"
#import "help.e"
#import "main.e"
#import "pipe.e"
#import "projconv.e"
#import "projutil.e"
#import "seltree.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "util.e"
#import "wkspace.e"
#import "refactor.e"
#import "projconv.e"
#import "makefile.e"
#import "tags.e"
#endregion

int def_use_visual_studio_version = 0;
_str def_auto_visual_studio_select = "project,latest,solution,prompt";

int _VCPPTimerHandle=-1;

struct VSInstall {
   _str name;
   _str version;
   _str productid;
   _str path;
};

static VSInstall vstudio_installs[];

enum_flags VCPPOptions {
   VCPP_CLOSE_ON_EXIT,     // 0x01
   //VCPP_OPEN_ON_START,     // 0x02 no longer supported
   VCPP_ADD_VSE_MENU,      // 0x04
};

#if 0
_command vcppInit()
{
   //VCPPInit(char *pszClassPrefix,char *pszWindowTitlePrefix);
   VCPPInit('Afx:','Microsoft Developer Studio');
}

#endif
#if 0
_command AddVSEToVCPPToolsMenu()
{
   MaybeAddVSEToVCPPRegEntry(editor_name('E'),
                             '"$(FilePath)" -#$(CurLine) "-#gui-goto-col $(CurCol)"',
                             '$(FileDir)');
}
#endif

_str def_vcpp_save='';
int  def_vcpp_version=0;

/**
 * Gets or sets the value for putting the Slickedit short cut on 
 * the Visual C++ menu. 
 * 
 * @param value       value to set (send null to retrieve the current value)
 * 
 * @return bool       true if shortcut is there, false otherwise
 */
bool _vcppsetup_se_shortcut_on_vcpp_menu(bool value = null)
{
   if (value != null) {
      // we kill the timer no matter what
      KillVCPPTimer();

      // or in the value
      if (value) {
         def_vcpp_flags |= VCPP_ADD_VSE_MENU;
         if (_VCPPTimerHandle < 0) {
            PerpetualVCPPMenuItem();
         }
      } else {             // remove the value
         def_vcpp_flags &= ~VCPP_ADD_VSE_MENU;
      }
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // return our current value
   return ((def_vcpp_flags & VCPP_ADD_VSE_MENU) != 0);
}

static _str _vcpp_versionlist_callback(int sl_event,_str &result,_str info)
{
   if (sl_event==SL_ONINIT) {
      _nocheck _control _sellist;
      if (!def_vcpp_version) {
         _sellist.search('?Use Latest Version','@rh');
      }else{
         _sellist.search(def_vcpp_version'.x','@rh');
      }
      _sellist._lbselect_line();
   }
   return('');
}

_command set_vcpp_version() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Visual Studio integration");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   int orig_view_id,temp_view_id;
   orig_view_id=_create_temp_view(temp_view_id);
   VCPPListAvailableVersions();
   p_window_id=orig_view_id;
   typeless result=show('-modal _sellist_form',
               'Select a VCPP Version',
               SL_VIEWID,
               temp_view_id,
               '',//buttons
               '',//help
               '',//font
               _vcpp_versionlist_callback
               );
   if (result!='') {
      if (pos(' 4.x ',' 'result' ')) {
         def_vcpp_version=4;
      }else if (pos(' 5.x ',' 'result' ')) {
         def_vcpp_version=5;
      }else if (pos(' 6.x ',' 'result' ')) {
         def_vcpp_version=6;
      }else if (pos(' 7.x?',' 'result' ',1,'r')) {
         def_vcpp_version=7;
      }else if (result=='Use Latest Version') {
         def_vcpp_version=0;
      }
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

static void EditorOnTop()
{
   _set_foreground_syswindow('vs_mdiframe');
}

definit()
{
   if (machine()!='WINDOWS' || _win32s()==1 || !_haveVersionControl() || DllIsMissing('vchack.dll') ) {
      return;
   }
   if (upcase(arg(1))!='L') {
      _VCPPTimerHandle= (-1);
      /*if (def_vcpp_flags&VCPP_OPEN_ON_START && !VCPPIsUp(def_vcpp_version)) {
         path := "";
         typeless status=GetVCPPBinPath(path,def_vcpp_version,1);
         if (status||path=='') return;

         path=_maybe_quote_filename(path);
         if (_IsVCPPWorkspaceFilename(_workspace_filename)) {
            path :+= ' '_maybe_quote_filename(_workspace_filename);
         }
         shell(path,'A');
         int timeout=VCPP_STARTUP_TIMEOUT;
         if (timeout>60) timeout=59;
         typeless start_ss="";
         parse _time("M") with . ":" . ":" start_ss;
         for (;;) {
            delay(50);
            if (VCPPIsVisible(def_vcpp_version)) break;
            typeless ss="";
            parse _time("M") with . ":" . ":" ss;
            if (ss<start_ss) ss :+= 60;
            if (ss-start_ss>timeout) break;
         }
         EditorOnTop();
      }
      */
      if (def_vcpp_flags&VCPP_ADD_VSE_MENU) {
         PerpetualVCPPMenuItem();
      }
   }
   vstudio_installs._makeempty();
}

/**
 * <p>This command is used to execute a menu item of another application.</p>
 * 
 * <p>This command is only supported under Windows, Windows 95/98, and Windows NT.</p>
 * 
 * <p>cmdline is a  string in the format: [-a] [-c[p] "ClassName"] [-t[p] "WindowTitle"] MenuSpec</p>
 * 
 * <p>Where MenuSpec is a list of menu items separated by a vertical bar
 * character '|' which indicate how to traverse the menu to find the final
 * menu item.  The optional 'p' which follows the -c or -t options indicates
 * that the name specified is a prefix match of the class or window title
 * respectively.  Use the -a option to make the other application active.
 * Sometimes, the other application becomes active anyway (depending on the
 * Version of the OS, whether you are creating a dialog box, and the other
 * application).</p>
 * 
 * @return 0 if succesful
 * @example <p>
 * syntax: appmenu [-a] [-c[p] classname] [-t[p] windowtitle] &lt;menuspec&gt;
 * </p>
 * 
 * <p>If you use the -t option, don't forget to use '"' around titles with spaces</p>
 * <pre>
 * <b>menuspec</b>:
 * Separate with "|".
 *     Will translate the & characters that may be in the menus, not "...".
 *     Ex.:"File|Open..."
 * <b>appmenu -a -cp Afx -tp "Microsoft Developer Studio" File|Open...</b>
 * <b>appmenu -a -t "Borland C++" File|Open...</b>
 * </pre>
 * @categories Miscellaneous_Functions
 */
_command int appmenu(typeless arg1="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_message(get_message(VSRC_FEATURE_REQUIRES_PRO_EDITION));
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   _str classprefix=0;
   _str windowprefix=0;
   classname := "";
   windowtitle := "";
   menuspec := "";
   typeless activateapp=0;
   _str str=arg1;
   for (;;) {
      _str cur=parse_file(str);
      if (cur=='') break;
      if (upcase(substr(cur,1,2))=='-C') {
         classprefix=upcase(substr(cur,3,1))=='P';
         classname=strip(parse_file(str),'b','"');
         continue;
      }
      if (upcase(substr(cur,1,2))=='-T') {
         windowprefix=upcase(substr(cur,3,1))=='P';
         windowtitle=strip(parse_file(str),'b','"');
         continue;
      }
      if (upcase(strip(cur))=='-A') {
         activateapp=1;
         continue;
      }
      menuspec :+= cur;
   }
   if (classname=='') {
      classprefix=1;
   }
   if (menuspec=='') {
      _message_box(nls("You must specify a menu spec ex:File|Open..."));
      return(INVALID_ARGUMENT_RC);
   }
   return AppMenu(classname,windowtitle,menuspec,
                  (int)classprefix,(int)windowprefix,activateapp);
}

static void PerpetualVCPPMenuItem()
{
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_VCPP_SETUP) || !_haveBuild()) {
      return;
   }
   _VCPPTimerHandle=_set_timer(1000,find_index("MaybeAddVSEToVCPPMenu",PROC_TYPE),def_vcpp_version);
   typeless status=MaybeAddVSEToVCPPMenu(def_vcpp_version);
}

static int VCPPMessageBoxTimerHandle=-1;
static void FindVCPPReloadMessageBox2(double OrigBTime)
{
   if (!_haveBuild()) {
      return;
   }
   typeless status=FindVCPPReloadMessageBox();
   SearchIsOver := ((double)_time('b')-OrigBTime)>=5000;//We have been looking for 5 seconds
   if (!status || SearchIsOver) {
      _kill_timer(VCPPMessageBoxTimerHandle);
      VCPPMessageBoxTimerHandle=-1;
   }
}

void HuntForVCPPMessageBox()
{
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_VCPP_SETUP) || !_haveBuild()) {
      return;
   }
   if (VCPPMessageBoxTimerHandle>-1) return;
   VCPPMessageBoxTimerHandle=_set_timer(50,FindVCPPReloadMessageBox2,_time('b'));
}

static void KillVCPPTimer()
{
   if (_VCPPTimerHandle>=0) {
      _kill_timer(_VCPPTimerHandle);
      _VCPPTimerHandle=-1;
   }
}

void _exit_VCPP()
{
   if (!_haveProMacros()) return;
   if (machine()!='WINDOWS' || _win32s()==1) {
      return;
   }
   KillVCPPTimer();
   if (def_vcpp_flags&VCPP_CLOSE_ON_EXIT) {
      //3:24pm 1/13/1998
      //Because of VC++ 5.0, this won't work any more
      //AppMenu(VCPP_CLASSNAME_PREFIX,VCPP_WINDOWTITLE_PREFIX,"File|Exit",1,2,0);
   }
}
/*
6.x vcvars32.bat

@echo off
rem
rem Root of Visual Developer Studio Common files.
set VSCommonDir=G:\vc6\Common

rem
rem Root of Visual Developer Studio installed files.
rem
set MSDevDir=G:\vc6\Common\msdev98

rem
rem Root of Visual C++ installed files.
rem
set MSVCDir=G:\vc6\VC98

rem
rem VcOsDir is used to help create either a Windows 95 or Windows NT specific path.
rem
set VcOsDir=WIN95
if "%OS%" == "Windows_NT" set VcOsDir=WINNT

rem
echo Setting environment for using Microsoft Visual C++ tools.
rem

if "%OS%" == "Windows_NT" set PATH=%MSDevDir%\BIN;%MSVCDir%\BIN;%VSCommonDir%\TOOLS\%VcOsDir%;%VSCommonDir%\TOOLS;%PATH%
if "%OS%" == "" set PATH="%MSDevDir%\BIN";"%MSVCDir%\BIN";"%VSCommonDir%\TOOLS\%VcOsDir%";"%VSCommonDir%\TOOLS";"%windir%\SYSTEM";"%PATH%"
set INCLUDE=%MSVCDir%\ATL\INCLUDE;%MSVCDir%\INCLUDE;%MSVCDir%\MFC\INCLUDE;%INCLUDE%
set LIB=%MSVCDir%\LIB;%MSVCDir%\MFC\LIB;%LIB%

set VcOsDir=
set VSCommonDir=

*/
static int _set_devstudio_environment(bool quiet=false,int major_version=6)
{
   //Root of Visual Developer Studio Common files.
   _str VSCommonDir;  //G:\vc6\Common

   //Root of Visual Developer Studio installed files.
   _str MSDevDir;  // G:\vc6\Common\msdev98

   //Root of Visual C++ installed files.
   _str MSVCDir;  // G:\vc6\VC98

   VcOsDir := "WIN95";
   if (!_win32s()) {
      VcOsDir="WINNT";
   }

   // Determine latest version
   latestVersionString := "";
   if (_ntRegFindLatestVersion(HKEY_LOCAL_MACHINE, 'Software\Microsoft\DevStudio', latestVersionString, major_version)) {
      if (!quiet) {
         _message_box('Version key (e.g 6.0) not found under HKEY_LOCAL_MACHINE\Software\Microsoft\DevStudio');
      }
      return(1);
   }
   _str key;
   key='Software\Microsoft\VisualStudio\':+latestVersionString:+'\Setup\Microsoft Visual C++';
   MSVCDir=_ntRegQueryValue(
      HKEY_LOCAL_MACHINE,
      key,
      "",  // DefaultValue
      "ProductDir");
   if (MSVCDir=="") {
      if (!quiet) {
         _message_box('ProductDir value not found at HKEY_LOCAL_MACHINE\':+key);
      }
      return(1);
   }

   if (major_version!=5) {
      key='Software\Microsoft\VisualStudio\':+latestVersionString:+'\Setup';
      VSCommonDir=_ntRegQueryValue(
         HKEY_LOCAL_MACHINE,
         key,
         "",  // DefaultValue
         "VSCommonDir");
      if (VSCommonDir=="") {
         if (!quiet) {
            _message_box('VSCommonDir value not found at HKEY_LOCAL_MACHINE\':+key);
         }
         return(1);
      }
   }

   // Determine latest version
   if (_ntRegFindLatestVersion(HKEY_CURRENT_USER, 'Software\Microsoft\DevStudio', latestVersionString, major_version)) {
      if (!quiet) {
         _message_box('Version key (e.g 6.0) not found under HKEY_CURRENT_USER\Software\Microsoft\DevStudio');
      }
      return(1);
   }
   key='Software\Microsoft\DevStudio\':+latestVersionString:+'\Directories';
   MSDevDir=_ntRegQueryValue(
      HKEY_CURRENT_USER,
      key,
      "",  // DefaultValue
      "Install Dirs");
   if (MSDevDir=="") {
      if (!quiet) {
         _message_box("'Install Dirs' value not found at HKEY_CURRENT_USER\\":+key);
      }
      return(1);
   }
   _maybe_strip_filesep(MSDevDir);
   MSDevDir=_strip_filename(MSDevDir,'n');
   _maybe_strip_filesep(MSDevDir);

   if (!file_exists(MSDevDir'\bin\msdev.exe')) {
      if (!quiet) {
         _message_box("msdev.exe not found in directory '"MSDevDir"\\bin'");
      }
      return(1);
   }

   set_env('VcOsDir',VcOsDir);
   if (major_version!=5) set_env('VSCommonDir',VSCommonDir);

   set_env('MSDevDir',MSDevDir);
   set_env('MSVCDir',MSVCDir);

   if (major_version==5) {
      set_env('PATH',_replace_envvars('%MSDevDir%\BIN;%MSVCDir%\BIN;%MSVCDir%\BIN\%VcOsDir%;%PATH%'));
      set_env('INCLUDE',_replace_envvars('%MSVCDir%\INCLUDE;%MSVCDir%\MFC\INCLUDE;%MSVCDir%\ATL\INCLUDE;%INCLUDE%'));
   } else {
      set_env('PATH',_replace_envvars('%MSDevDir%\BIN;%MSVCDir%\BIN;%VSCommonDir%\TOOLS\%VcOsDir%;%VSCommonDir%\TOOLS;%PATH%'));
      set_env('INCLUDE',_replace_envvars('%MSVCDir%\ATL\INCLUDE;%MSVCDir%\INCLUDE;%MSVCDir%\MFC\INCLUDE;%INCLUDE%'));
   }
   set_env('LIB',_replace_envvars('%MSVCDir%\LIB;%MSVCDir%\MFC\LIB;%LIB%'));

   set_env('VcOsDir',null);
   set_env('VSCommonDir',null);

   // Now set them in the build window if necessary.
   set('PATH='get_env('PATH'));
   set('MSDevDir='MSDevDir);
   set('MSVCDir='MSVCDir);
   set('LIB='get_env('LIB'));
   set('INCLUDE='get_env('INCLUDE'));
   return(0);

}
/**
 * Sets the environment variables for Visual C++ 5.x
 * or 6.x.  It a version newer than 6.x is found, it
 * will attempt to set the environment like 6.x.
 *
 * <P>
 * If the user configures SlickEdit to use a specific
 * version of Visual C++.  The user will need to exit
 * the editor before the environment can be set up
 * correctly.
 *
 * @param quiet
 * @return
 */
_command int set_devstudio_environment(bool quiet=false)
{
   if (path_search('msdev.exe','','P'):!='') {
      if (!quiet) {
         _message_box('Visual C++ is already setup.  msdev.exe is already in your PATH.');
      }
      _restore_origenv(true,true);
      return(0);
   }
   _restore_origenv(false,true);
   _str latestVersionString=def_vcpp_version;
   if (!def_vcpp_version) {
      // Determine latest version
      if (_ntRegFindLatestVersion(HKEY_LOCAL_MACHINE, 'Software\Microsoft\DevStudio', latestVersionString)) {
         return(1);
      }
   }
   if (latestVersionString<=4) {
      if (!quiet) {
         _message_box("Can't set environment for Visual C++ 4.x");
      }
      return(1);
   }
   if (latestVersionString<=5) {
      return(_set_devstudio_environment(quiet,5));
   }
   typeless major_version="";
   parse latestVersionString with major_version'.';
   return(_set_devstudio_environment(quiet,major_version));
}

/*
rem c:\Program files\Microsoft.NET\Common7\IDE
rem \Program files\Microsoft.NET
rem _str value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\7.0","","InstallDir");
@SET VSINSTALLDIR=C:\PROGRA~1\MICROS~2.NET\Common7\IDE
@SET VCINSTALLDIR=C:\PROGRA~1\MICROS~2.NET
rem HKEY_LOCAL_MACHINE\SOFTWARE\Micrsoft\.NETFramework        ,  installroot
@SET PATH=%PATH%;C:\WINNT\MICROS~1.NET\FRAMEW~1\V10~1.291\;C:\PROGRA~1\MICROS~1.NET\FRAMEW~1\Bin
@SET LIB=%LIB%;C:\WINNT\MICROS~1.NET\FRAMEW~1\V10~1.291
@SET INCLUDE=%INCLUDE%;C:\WINNT\MICROS~1.NET\FRAMEW~1\V10~1.291
@echo off
rem Root of Visual Developer Studio Common files.

if "%VSINSTALLDIR%"=="" goto Usage
if "%VCINSTALLDIR%"=="" set VCINSTALLDIR=%VSINSTALLDIR%

REM set VSCommonDir=%VSINSTALLDIR%\Common7
set VSCommonDir=%VSINSTALLDIR%

rem
rem Root of Visual Studio ide installed files.
rem
REM set DevEnvDir=%VSCommonDir%\ide
set DevEnvDir=%VSCommonDir%

rem
rem Root of Visual C++ installed files.
rem
set MSVCDir=%VCINSTALLDIR%\VC7

rem
rem VcOsDir is used to help create either a Windows 9x or Windows NT specific path.
rem
set VcOsDir=WIN9x
if "%OS%" == "Windows_NT" set VcOsDir=WINNT

rem
echo Setting environment for using Microsoft Visual C++.NET 7.0 tools.
echo (If you also have Visual C++ 6.0 installed and wish to use its tools
echo from the command line, run vcvars32.bat for Visual C++ 6.0.)
rem

REM %VCINSTALLDIR%\Common7\Tools dir is added only for real setup.

if "%OS%" == "Windows_NT" set PATH=%DevEnvDir%;%MSVCDir%\BIN;%VCINSTALLDIR%\Common7\Tools;%VCINSTALLDIR%\Common7\Tools\bin\prerelease;%VCINSTALLDIR%\Common7\Tools\bin;%PATH%;
if "%OS%" == "" set PATH="%DevEnvDir%";"%MSVCDir%\BIN";"%windir%\SYSTEM";"%VCINSTALLDIR%\Common7\Tools";"%VCINSTALLDIR%\Common7\Tools\bin\prerelease";"%VCINSTALLDIR%\Common7\Tools\bin";%PATH%
set INCLUDE=%MSVCDir%\ATLMFC\INCLUDE;%MSVCDir%\INCLUDE;%MSVCDir%\PlatformSDK\include\prerelease;%MSVCDir%\PlatformSDK\include;%INCLUDE%
set LIB=%MSVCDir%\ATLMFC\LIB;%MSVCDir%\LIB;%MSVCDir%\PlatformSDK\lib\prerelease;%MSVCDir%\PlatformSDK\lib;%LIB%

set VcOsDir=
set VSCommonDir=

goto end

:Usage

echo. VSINSTALLDIR variable is not set.
echo.
echo SYNTAX: VCVARS32

goto end

:end
*/
static int _set_visualstudio_environment(bool quiet=false, int major_version=0, _str target_version='')
{
   _restore_origenv(false,true);
   if (major_version>=9) {
      return(_set_visualstudio2008orHigher_environment(quiet,major_version,target_version));
   }
   if (major_version==0 && target_version=='') {
      latestMS:=_getLatestVisualStudioVersion();
      if (latestMS=='') {
         return 1;
      }
      switch (latestMS) {
      case COMPILER_NAME_VS2003:
         return _set_visualstudio_environment(quiet,7);
      case COMPILER_NAME_VS2005:
         return _set_visualstudio_environment(quiet,8);
      case COMPILER_NAME_VS2005_EXPRESS:
         return _set_visualstudio_environment(quiet,8);
      case COMPILER_NAME_VS2008:
         return _set_visualstudio_environment(quiet,9);
      case COMPILER_NAME_VS2008_EXPRESS:
         return _set_visualstudio_environment(quiet,9);
      case COMPILER_NAME_VS2010:
         return _set_visualstudio_environment(quiet,10);
      case COMPILER_NAME_VS2010_EXPRESS:
         return _set_visualstudio_environment(quiet,10);
      case COMPILER_NAME_VS2012:
         return _set_visualstudio_environment(quiet,11);
      case COMPILER_NAME_VS2012_EXPRESS:
         return _set_visualstudio_environment(quiet,11);
      case COMPILER_NAME_VS2013:
         return _set_visualstudio_environment(quiet,12);
      case COMPILER_NAME_VS2013_EXPRESS:
         return _set_visualstudio_environment(quiet,12);
      case COMPILER_NAME_VS2015:
         return _set_visualstudio_environment(quiet,14);
      case COMPILER_NAME_VS2015_EXPRESS:
         return _set_visualstudio_environment(quiet,14);
      case COMPILER_NAME_VS2017:
         return _set_visualstudio_environment(quiet,15);
      case COMPILER_NAME_VS2019:
         return _set_visualstudio_environment(quiet,16);
      }
      if (!quiet) {
         _message_box('Missing support for 'latestMS);
      }
      return 1;
   }

   if (target_version:!='') {
      _str test_key=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\":+target_version,"","InstallDir");
      if (test_key:=='') {
         target_version='';
      }
   }

   if (target_version:=='') {
      if (_ntRegFindLatestVersion(HKEY_LOCAL_MACHINE, 'Software\Microsoft\VisualStudio', target_version, major_version)) {
         return(1);
      }
   }
   _str VSINSTALLDIR=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\":+target_version,"","InstallDir");
   if (VSINSTALLDIR=='') {
      if (!quiet) {
         _message_box(nls("InstallDir key not found under SOFTWARE\\Microsoft\\VisualStudio\\%s",target_version));
      }
      return(1);
   }
   _str NETFrameworkRoot=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\.NETFramework","","InstallRoot");
   if (NETFrameworkRoot=='') {
      if (!quiet) {
         _message_box("InstallRoot key not found under SOFTWARE\\Microsoft\\.NETFramework");
      }
      return(1);
   }
   _str NETFrameworkVersion=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\.NETFramework","","Version");
   // 6:00:08 PM 1/25/2002
   // For the release candidate, there is no version number...
   /*if (NETFrameworkVersion=='') {
      if (!quiet) {
         _message_box("Version key not found under SOFTWARE\\Microsoft\\.NETFramework");
      }
      return(1);
   }*/
   _maybe_strip_filesep(VSINSTALLDIR);
   VCINSTALLDIR := _strip_filename(VSINSTALLDIR,'n');
   VCINSTALLDIR=substr(VCINSTALLDIR,1,length(VCINSTALLDIR)-1);
   VCINSTALLDIR=_strip_filename(VCINSTALLDIR,'n');
   VCINSTALLDIR=substr(VCINSTALLDIR,1,length(VCINSTALLDIR)-1);

   set_env('VSINSTALLDIR',VSINSTALLDIR);
   set_env('VCINSTALLDIR',VCINSTALLDIR);

   //@SET PATH=%PATH%;C:\WINNT\MICROS~1.NET\FRAMEW~1\V10~1.291\;C:\PROGRA~1\MICROS~1.NET\FRAMEW~1\Bin
   set_env('PATH',get_env('PATH')';'NETFrameworkRoot:+NETFrameworkVersion';'NETFrameworkRoot'\Bin');
   //@SET LIB=%LIB%;C:\WINNT\MICROS~1.NET\FRAMEW~1\V10~1.291
   set_env('LIB',get_env('LIB')';'NETFrameworkRoot:+NETFrameworkVersion);
   //@SET INCLUDE=%INCLUDE%;C:\WINNT\MICROS~1.NET\FRAMEW~1\V10~1.291
   set_env('INCLUDE',get_env('INCLUDE')';'NETFrameworkRoot:+NETFrameworkVersion);


   _str VSCommonDir=VSINSTALLDIR;
   set_env('VSCommonDir',VSCommonDir);

   set_env('DevEnvDir',VSCommonDir);

   majorVersion := '7';
   {
      p := pos('.',target_version);
      if (p>1) {
         majorVersion=substr(target_version, 1, p-1);
      }
   }

   if (majorVersion>=8) {
      set_env('MSVCDir',VCINSTALLDIR'\VC');
   } else {
      set_env('MSVCDir',VCINSTALLDIR'\VC':+majorVersion);
   }
   //set_env('MSVCDir',VCINSTALLDIR'\VC7');

   if (get_env('OS') == "Windows_NT") {
      set_env('PATH',_replace_envvars('%DevEnvDir%;%MSVCDir%\BIN;%VCINSTALLDIR%\Common7\Tools;%VCINSTALLDIR%\Common7\Tools\bin\prerelease;%VCINSTALLDIR%\Common7\Tools\bin;%PATH%;'));
   } else {
      // Win9x case
      set_env('PATH',_replace_envvars('"%DevEnvDir%";"%MSVCDir%\BIN";"%windir%\SYSTEM";"%VCINSTALLDIR%\Common7\Tools";"%VCINSTALLDIR%\Common7\Tools\bin\prerelease";"%VCINSTALLDIR%\Common7\Tools\bin";%PATH%'));
   }

   include_path := '%MSVCDir%\ATLMFC\INCLUDE;%MSVCDir%\INCLUDE;%MSVCDir%\PlatformSDK\include\prerelease;%MSVCDir%\PlatformSDK\include;%INCLUDE%';
   // check to see if PlatformSDK\include\prerelease directory exists
   if (file_match('+d +x -p ':+_maybe_quote_filename(_replace_envvars('%MSVCDir%\PlatformSDK\include\prerelease')),1)=="") {
      include_path = '%MSVCDir%\ATLMFC\INCLUDE;%MSVCDir%\INCLUDE;%MSVCDir%\PlatformSDK\include;%INCLUDE%'; 
   }
   set_env('INCLUDE',_replace_envvars(include_path));

   lib_path := '%MSVCDir%\ATLMFC\LIB;%MSVCDir%\LIB;%MSVCDir%\PlatformSDK\lib\prerelease;%MSVCDir%\PlatformSDK\lib;%LIB%';
   // check to see if PlatformSDK\lib\prerelease directory exists
   if (file_match('+d +x -p ':+_maybe_quote_filename(_replace_envvars('%MSVCDir%\PlatformSDK\lib\prerelease')),1)=="") {
      lib_path = '%MSVCDir%\ATLMFC\LIB;%MSVCDir%\LIB;%MSVCDir%\PlatformSDK\lib;%LIB%';
   }
   set_env('LIB',_replace_envvars(lib_path));
   set_env('VSCommonDir',null);

   // Now set them in the build window if necessary.
   set('PATH='get_env('PATH'));
   set('DevEnvDir='get_env('DevEnvDir'));
   set('MSVCDir='get_env('MSVCDir'));
   set('INCLUDE='get_env('INCLUDE'));
   set('LIB='get_env('LIB'));
   set('VSINSTALLDIR='get_env('VSINSTALLDIR'));
   set('VCINSTALLDIR='get_env('VCINSTALLDIR'));
   return(0);

}
/*
Visual Studio 2013 environment changes seen in 2013 command prompt
   CommandPromptType=Native
   ExtensionSdkDir=C:\Program Files (x86)\Microsoft SDKs\Windows\v8.1\ExtensionSDKs

   Framework40Version=v4.0
   FrameworkDir=C:\Windows\Microsoft.NET\Framework64
   FrameworkDIR64=C:\Windows\Microsoft.NET\Framework64
   FrameworkVersion=v4.0.30319
   FrameworkVersion64=v4.0.30319
   FSHARPINSTALLDIR=C:\Program Files (x86)\Microsoft SDKs\F#\3.1\Framework\v4.0\

   INCLUDE=
     C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\INCLUDE
     C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\ATLMFC\INCLUDE
     C:\Program Files (x86)\Windows Kits\8.1\include\shared
     C:\Program Files (x86)\Windows Kits\8.1\include\um
     C:\Program Files (x86)\Windows Kits\8.1\include\winrt

   LIB=
      C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\LIB\amd64
      C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\ATLMFC\LIB\amd64
      C:\Program Files (x86)\Windows Kits\8.1\lib\winv6.3\um\x64

   LIBPATH=
      C:\Windows\Microsoft.NET\Framework64\v4.0.30319
      C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\LIB\amd64
      C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\ATLMFC\LIB\amd64
      C:\Program Files (x86)\Windows Kits\8.1\References\CommonConfiguration\Neutral
      C:\Program Files (x86)\Microsoft SDKs\Windows\v8.1\ExtensionSDKs\Microsoft.VCLibs\12.0\References\CommonConfiguration\neutral


   Add path 
     C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow;
     C:\Program Files (x86)\MSBuild\12.0\bin\amd64;
     C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\BIN\amd64;
     C:\Windows\Microsoft.NET\Framework64\v4.0.30319;
     C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\VCPackages;
     C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE;
     C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\Tools;
     C:\Program Files (x86)\HTML Help Workshop;
     C:\Program Files (x86)\Microsoft Visual Studio 12.0\Team Tools\Performance Tools\x64;
     C:\Program Files (x86)\Microsoft Visual Studio 12.0\Team Tools\Performance Tools;
     C:\Program Files (x86)\Windows Kits\8.1\bin\x64;
     C:\Program Files (x86)\Windows Kits\8.1\bin\x86;
     C:\Program Files (x86)\Microsoft SDKs\Windows\v8.1A\bin\NETFX 4.5.1 Tools\x64\;

     Platform=X64
     VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\
     VisualStudioVersion=12.0

     VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 12.0\
     WindowsSdkDir=C:\Program Files (x86)\Windows Kits\8.1\
     WindowsSDK_ExecutablePath_x64=C:\Program Files (x86)\Microsoft SDKs\Windows\v8.1A\bin\NETFX 4.5.1 Tools\x64\
     WindowsSDK_ExecutablePath_x86=C:\Program Files (x86)\Microsoft SDKs\Windows\v8.1A\bin\NETFX 4.5.1 Tools\
*/
/*

CommandPromptType=Native
ExtensionSdkDir=C:\Program Files (x86)\Microsoft SDKs\Windows Kits\10\ExtensionSDKs
Framework40Version=v4.0
FrameworkDir=C:\Windows\Microsoft.NET\Framework64
FrameworkDIR64=C:\Windows\Microsoft.NET\Framework64
FrameworkVersion=v4.0.30319
FrameworkVersion64=v4.0.30319
INCLUDE=C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\INCLUDE;
    C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\ATLMFC\INCLUDE;
    C:\Program Files (x86)\Windows Kits\10\include\10.0.10240.0\ucrt;
    C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6\include\um;
    C:\Program Files (x86)\Windows Kits\10\include\10.0.10240.0\shared;
    C:\Program Files (x86)\Windows Kits\10\include\10.0.10240.0\um;
    C:\Program Files (x86)\Windows Kits\10\include\10.0.10240.0\winrt;
LIB=C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\LIB\amd64;
    C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\ATLMFC\LIB\amd64;
    C:\Program Files (x86)\Windows Kits\10\lib\10.0.10240.0\ucrt\x64;
    C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6\lib\um\x64;
    C:\Program Files (x86)\Windows Kits\10\lib\10.0.10240.0\um\x64;
LIBPATH=C:\Windows\Microsoft.NET\Framework64\v4.0.30319;
      C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\LIB\amd64;
      C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\ATLMFC\LIB\amd64;
      C:\Program Files (x86)\Windows Kits\10\UnionMetadata;C:\Program Files (x86)\Windows Kits\10\References;
      C:\Program Files (x86)\Windows Kits\10\References\Windows.Foundation.UniversalApiContract\1.0.0.0;
      C:\Program Files (x86)\Windows Kits\10\References\Windows.Foundation.FoundationContract\1.0.0.0;
      C:\Program Files (x86)\Windows Kits\10\References\indows.Networking.Connectivity.WwanContract\1.0.0.0;
      C:\Program Files (x86)\Microsoft SDKs\Windows Kits\10\ExtensionSDKs\Microsoft.VCLibs\14.0\References\CommonConfiguration\neutral;
NETFXSDKDir=C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6\
Path=C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow;
    C:\Program Files (x86)\MSBuild\14.0\bin\amd64;
    C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\BIN\amd64;
    C:\Windows\Microsoft.NET\Framework64\v4.0.30319;
    C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\VCPackages;
    C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE;
    C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools;
    C:\Program Files (x86)\HTML Help Workshop;
    C:\Program Files (x86)\Microsoft Visual Studio 14.0\Team Tools\Performance Tools\x64;
    C:\Program Files (x86)\Microsoft Visual Studio 14.0\Team Tools\Performance Tools;
    C:\Program Files (x86)\Windows Kits\10\bin\x64;
    C:\Program Files (x86)\Windows Kits\10\bin\x86;
    C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6 Tools\x64\;
    above added to front of path
Platform=X64
UCRTVersion=10.0.10240.0
UniversalCRTSdkDir=C:\Program Files (x86)\Windows Kits\10\
VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\
VisualStudioVersion=14.0
VS100COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\Tools\
VS110COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\Tools\
VS120COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\Tools\
VS140COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools\
VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 14.0\
WindowsLibPath=C:\Program Files (x86)\Windows Kits\10\UnionMetadata;
    C:\Program Files (x86)\Windows Kits\10\References;
    C:\Program Files (x86)\Windows Kits\10\References\Windows.Foundation.UniversalApiContract\1.0.0.0;
    C:\Program Files (x86)\Windows Kits\10\References\Windows.Foundation.FoundationContract\1.0.0.0;
    C:\Program Files (x86)\Windows Kits\10\References\indows.Networking.Connectivity.WwanContract\1.0.0.0
WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
WindowsSDKLibVersion=10.0.10240.0\
WindowsSDKVersion=10.0.10240.0\
WindowsSDK_ExecutablePath_x64=C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6 Tools\x64\
WindowsSDK_ExecutablePath_x86=C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6 Tools\

*/


/*
DevEnvDir=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\
ExtensionSdkDir=C:\Program Files (x86)\Microsoft SDKs\Windows Kits\10\ExtensionSDKs
Framework40Version=v4.0
FrameworkDir=C:\Windows\Microsoft.NET\Framework64\
FrameworkDIR64=C:\Windows\Microsoft.NET\Framework64
FrameworkVersion=v4.0.30319
FrameworkVersion64=v4.0.30319
INCLUDE=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\ATLMFC\include;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\include;C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6.1\include\um;C:\Program Files (x86)\Windows Kits\10\include\10.0.14393.0\ucrt;C:\Program Files (x86)\Windows Kits\10\include\10.0.14393.0\shared;C:\Program Files (x86)\Windows Kits\10\include\10.0.14393.0\um;C:\Program Files (x86)\Windows Kits\10\include\10.0.14393.0\winrt;
LIB=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\ATLMFC\lib\x64;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\lib\x64;C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6.1\lib\um\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.14393.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.14393.0\um\x64;
LIBPATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\ATLMFC\lib\x64;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\lib\x64;C:\Program Files (x86)\Windows Kits\10\UnionMetadata;C:\Program Files (x86)\Windows Kits\10\References;C:\Windows\Microsoft.NET\Framework64\v4.0.30319;
NETFXSDKDir=C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6.1\
Path=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\bin\HostX64\x64;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\VC\VCPackages;C:\Program Files (x86)\Microsoft SDKs\TypeScript\2.1;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TestWindow;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\bin\Roslyn;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Team Tools\Performance Tools;C:\Program Files (x86)\Microsoft Visual Studio\Shared\Common\VSPerfCollectionTools\;C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\;C:\Program Files (x86)\Windows Kits\10\bin\x64;C:\Program Files (x86)\Windows Kits\10\bin\10.0.14393.0\x64;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\\MSBuild\15.0\bin;C:\Windows\Microsoft.NET\Framework64\v4.0.30319;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\;C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\Tools\;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v8.0\bin;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v8.0\libnvvp;C:\ProgramData\Oracle\Java\javapath;C:\Program Files (x86)\ActiveState Komodo IDE 9\;C:\Program Files (x86)\PHP\;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;c:\Program Files (x86)\Microsoft SQL Server\90\Tools\binn\;C:\Program Files\nodejs\;C:\Program Files\TortoiseHg\;C:\Go\bin;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Program Files\Perforce;C:\Program Files\SlikSvn\bin;C:\PROGRA~1\CONDUS~1\DISKEE~1\;C:\Program Files\TortoiseSVN\bin;C:\Program Files (x86)\PuTTY\;C:\Program Files (x86)\Windows Kits\8.1\Windows Performance Toolkit\;C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\;C:\Users\lbaldwin\.dnx\bin;C:\Program Files\Microsoft DNX\Dnvm\;C:\Program Files\Microsoft SQL Server\130\Tools\Binn\;C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common;C:\Program Files (x86)\QuickTime\QTSystem\;C:\Program Files\CMake\bin;C:\Program Files\Microsoft Windows Performance Toolkit\;C:\Program Files\Git\cmd;C:\Program Files (x86)\GtkSharp\2.12\bin;C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\TShell\TShell\;C:\Users\lbaldwin\AppData\Roaming\npm
Platform=x64
UCRTVersion=10.0.14393.0
UniversalCRTSdkDir=C:\Program Files (x86)\Windows Kits\10\
VCIDEInstallDir=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\VC\
VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\
VCToolsInstallDir=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\
VCToolsRedistDir=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Redist\MSVC\14.10.25017\
VisualStudioVersion=15.0
VS150COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\Tools\
VSCMD_ARG_app_plat=Desktop
VSCMD_ARG_HOST_ARCH=x64
VSCMD_ARG_TGT_ARCH=x64
VSCMD_VER=15.0.26228.4
VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\
WindowsLibPath=C:\Program Files (x86)\Windows Kits\10\UnionMetadata;C:\Program Files (x86)\Windows Kits\10\References
WindowsSdkBinPath=C:\Program Files (x86)\Windows Kits\10\bin\
WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
WindowsSDKLibVersion=10.0.14393.0\
WindowsSdkVerBinPath=C:\Program Files (x86)\Windows Kits\10\bin\10.0.14393.0\
WindowsSDKVersion=10.0.14393.0\
WindowsSDK_ExecutablePath_x64=C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\x64\
WindowsSDK_ExecutablePath_x86=C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\
*/
#if 0
#endif
/**
 * Set environment vars for Visual Studio 2008, 2010, and higher
 * @return int 0 on success. All other is a failure (probably after a modal 
 *         messgae box)
 * @remarks This code (and its comments) needs to be updated each time a new 
 *          release of Visual Studio makes it into the wild.
 */
static int _set_visualstudio2008orHigher_environment(bool quiet=false, int major_version=0, _str target_version='')
{
   //say('IN major_version='major_version'> target_version='target_version'>');
   // This handles Visual Studio 9.0 (VS 2008) and Visual Studio 10.0 (VS 2010)
   if (major_version >= 15) {
      _set_visualstudio2017_environment(major_version);
      return(0);
   }

   if (target_version:=='') {
      if (major_version == 9) {
         target_version = '9.0';
      } else if (major_version == 10) {
         target_version = '10.0';
      } else if (major_version == 11) {
         target_version = '11.0';
      } else if (major_version == 12) {
         target_version = '12.0';
      } else if (major_version == 14) {
         target_version = '14.0';
      } else if (major_version == 15) {
         target_version = '15.0';
      } else if (major_version == 16) {
         target_version = '16.0';
      }
   }

    platformSDKVersionString := "";
   if (major_version > 16) {
      _message_box('Need new code for determining Visual Studio ' :+ major_version :+ ' location. [vchack.e]');
   } else if (major_version == 16){
      platformSDKVersionString = "v10.0";
   } else if (major_version == 15){
      platformSDKVersionString = "v10.0";
   } else if (major_version == 14){
      platformSDKVersionString = "v8.1";
   } else if (major_version == 12){
      platformSDKVersionString = "v8.1";
   } else if (major_version == 11){
      platformSDKVersionString = "v8.0";
   } else if (major_version == 10){
      platformSDKVersionString = "v7.0A";
   } else if (major_version == 9){
      platformSDKVersionString = "v6.0A";
   }

   
   _str VSINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\":+target_version:+"\\Setup\\VS","","ProductDir");
   if (VSINSTALLDIR == '') {
      // Need this for VC++ 2008 Express but not 2010 Express
      VSINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VCExpress\\":+target_version:+"\\Setup\\VS","","ProductDir");
      if (VSINSTALLDIR == '') {
         // Just need msbuild in path for VB and C# project builds. could do better and put compiler in path
         /*if (!quiet) {
            _message_box(nls("ProductDir key not found under SOFTWARE\\Microsoft\\VisualStudio\\%s\\Setup\\VS",target_version));
         }
         return(1);*/
      }
   }
   _maybe_strip_filesep(VSINSTALLDIR);
   //say('VSINSTALLDIR='VSINSTALLDIR);
   isExpressEdition := false;
   _str DEVENVDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\":+target_version:+"\\Setup\\VS","","EnvironmentDirectory");
   //say('DEVENVDIR='DEVENVDIR);
   if (DEVENVDIR == '') {
      DEVENVDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VCExpress\\":+target_version,"","InstallDir");
      //say('h2 DEVENVDIR='DEVENVDIR);
      if (DEVENVDIR == '') {
         // Just need msbuild in path for VB and C# project builds. could do better and put compiler in path
         // For Visual Studio 2013 Express need WDExpress
         DEVENVDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\WDExpress\\":+target_version,"","InstallDir");
      }
      //say('EXPRESSS!!!!!! DEVENVDIR='DEVENVDIR);
      isExpressEdition=true;
   }
   _maybe_strip_filesep(DEVENVDIR);

   MSBUILDBINDIR := "";
   if (isExpressEdition) {
      MSBUILDBINDIR=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\MSBuild\\ToolsVersion\\":+target_version,"MSBuildToolsPath");
   } else {
      if (major_version >= 14) {
         ntGetSpecialFolderPath(auto ProgramFiles, CSIDL_PROGRAM_FILES);
         bindir:=ProgramFiles:+'MSBuild\14.0\bin\';
         if (machine_bits() == "64") {
            bindir :+= 'amd64\';
         }
         if (file_exists(bindir)) {
            MSBUILDBINDIR=bindir;
         } else {
            ntGetSpecialFolderPath(ProgramFiles, CSIDL_PROGRAM_FILESX86);
            bindir=ProgramFiles:+'MSBuild\14.0\bin\';
            if (machine_bits() == "64") {
               bindir :+= 'amd64\';
            }
            if (file_exists(bindir)) {
               MSBUILDBINDIR=bindir;
            }
         }
      }
   }
   _maybe_strip_filesep(MSBUILDBINDIR);

   _str VCINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\":+target_version:+"\\Setup\\VC","","ProductDir");
   if (VCINSTALLDIR == '') {
      // Need this for VC++ 2008 Express but not 2010 Express
      VCINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VCExpress\\":+target_version:+"\\Setup\\VC","","ProductDir");
      if (VCINSTALLDIR == '') {
         // Just need msbuild in path for VB and C# project builds. could do better and put compiler in path
         /*if (!quiet) {
            _message_box(nls("ProductDir key not found under SOFTWARE\\Microsoft\\VisualStudio\\%s\\Setup\\VC",target_version));
         }
         return(1);*/
      }
   }
   _maybe_strip_filesep(VCINSTALLDIR);

   VSCOMMONTOOLSBINDIR := "";
   if (!isExpressEdition) {
      VSCOMMONTOOLSBINDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\":+target_version:+"\\Setup\\VS","","VS7CommonBinDir");
      //say('h1 VSCOMMONTOOLSBINDIR='VSCOMMONTOOLSBINDIR);
      if (VSCOMMONTOOLSBINDIR == '') {
         // For Visual Studio 2013 and 2015, for some reason the "VS7CommonBinDir" key is present but blank
         if (major_version>=12) {
            // Fetch the VS7CommonDir key and append "bin" to construct the bin dir.
            VSCOMMONTOOLSBINDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\":+target_version:+"\\Setup\\VS","","VS7CommonDir");
            //say('h2 VSCOMMONTOOLSBINDIR='VSCOMMONTOOLSBINDIR);
            if (VSCOMMONTOOLSBINDIR!='') {
               _maybe_append_filesep(VSCOMMONTOOLSBINDIR);
               VSCOMMONTOOLSBINDIR :+= 'bin';
               //say('h3 VSCOMMONTOOLSBINDIR='VSCOMMONTOOLSBINDIR);
            }
         }
         // Just need msbuild in path for VB and C# project builds. could do better and put compiler in path
         /*if (!quiet) {
            _message_box(nls("VS7CommonBinDir key not found under SOFTWARE\\Microsoft\\VisualStudio\\%s\\Setup\\VC",target_version));
         }
         return(1);*/
      }
      _maybe_strip_filesep(VSCOMMONTOOLSBINDIR);
   }

  
   _str SDKINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\":+platformSDKVersionString,"","InstallationFolder");
   //say('sdkinstalldir='SDKINSTALLDIR);
   if (SDKINSTALLDIR == '') {
      // Just need msbuild in path for VB and C# project builds. could do better and put compiler in path
      /*if (!quiet) {
         _message_box("InstallationFolder key not found under SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\":+platformSDKVersionString);
      }
      return(1);*/
   }
   _maybe_strip_filesep(SDKINSTALLDIR);


   UniversalCRTSdkDir := "";
   UCRTVersion := "";
   NETFXSDKDir := "";
   if (major_version >= 14) {
      UniversalCRTSdkDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots", "", "KitsRoot10");
      // iterate over windows kit 10 versions to find the newest one with windows.h
      if (UniversalCRTSdkDir != "") {
         versionDir := dir_match(UniversalCRTSdkDir:+"Include":+FILESEP:+"10.*", true);
         while (versionDir != "") {
            unquotedVersionDir := _maybe_unquote_filename(versionDir);
            unquotedVersionDir = strip(unquotedVersionDir,'T',FILESEP);
            if (file_exists(unquotedVersionDir:+FILESEP:+"um":+FILESEP:+"windows.h")) {
               UCRTVersion = _strip_filename(unquotedVersionDir,'P'):+FILESEP;
            }
            versionDir = dir_match(UniversalCRTSdkDir:+"Include":+FILESEP:+"10.*", false);
         }
         _maybe_strip_filesep(UCRTVersion);
      }

      NETFXSDKDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Microsoft SDKs\\NETFXSDK\\4.6.1", "", "KitsInstallationFolder");
      if (NETFXSDKDir != '') {
         NETFXSDKDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Microsoft SDKs\\NETFXSDK\\4.6", "", "KitsInstallationFolder");
      }
   }


   _str FRAMEWORKINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\.NetFramework","","InstallRoot");
   if (FRAMEWORKINSTALLDIR == '') {
      if (!quiet) {
         _message_box("InstallRoot key not found under SOFTWARE\\Microsoft\\.NetFramework");
      }
      return(1);
   }
   _maybe_strip_filesep(FRAMEWORKINSTALLDIR);

   // .NET frameworks are additive in VS2008 and higher. So 3.5 builds on 2.0.X, etc.
   _str dotNetFrameworkDirs = FRAMEWORKINSTALLDIR'\v3.5;'FRAMEWORKINSTALLDIR'\v2.0.50727;';
   if(major_version >= 10) {
      // .NET paths for VS 2010
      _str frameworkDir, frameworkVer;
      if (machine_bits() :== "64") {
         frameworkDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7","","FrameworkDir64"); 
         frameworkVer = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7","","FrameworkVer64"); 
      } else {
         frameworkDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7","","FrameworkDir32"); 
         frameworkVer = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7","","FrameworkVer32"); 
      }
      if (frameworkDir != '' && frameworkVer != '') {
         dotNetFrameworkDirs = frameworkDir:+frameworkVer';':+dotNetFrameworkDirs;
      } else {
         dotNetFrameworkDirs = FRAMEWORKINSTALLDIR'\v4.0.30319;':+FRAMEWORKINSTALLDIR'\v4.0.30128;':+dotNetFrameworkDirs; //'v4.0.20506'
      }
   }

   //if(major_version >= 11) {
   //   dotNetFrameworkDirs = FRAMEWORKINSTALLDIR'\v5.0???;':+dotNetFrameworkDirs;
   //} 

   set_env('VSINSTALLDIR',VSINSTALLDIR);
   set_env('VCINSTALLDIR',VCINSTALLDIR);

   /* Might need to set LIBPATH too.  Not doing it yet.
      Also, this code only supports configuring for 32-bit compiling. Currently our project 
      supports doesn't need this because it launch devenv or msbuild which handles 32-bit or
      64-bit builds depending on the visual studio project.
   */ 
   // Set up Path
   //_str PATH=DEVENVDIR';'VCINSTALLDIR'\bin;'VSCOMMONTOOLSBINDIR';':+dotNetFrameworkDirs :+ SDKINSTALLDIR'\bin;':+ get_env('PATH');
   _str PATH;
   if (VCINSTALLDIR!='' && DEVENVDIR!='') {
       VCBINDIR := VCINSTALLDIR:+'\bin';
       if (machine_bits() :== "64") {
          VCBINDIR :+= '\amd64';
       }
       PATH=DEVENVDIR';'VCBINDIR';';
       // Express edition does not have VSCOMMONTOOLSBINDIR
       if (VSCOMMONTOOLSBINDIR!='') {
          PATH :+= VSCOMMONTOOLSBINDIR';';
       }
       if (MSBUILDBINDIR!='') {
          PATH :+= MSBUILDBINDIR';';
       }
       PATH :+= dotNetFrameworkDirs :+ SDKINSTALLDIR'\bin;':+ get_env('PATH');
   } else {
       PATH=dotNetFrameworkDirs :+ SDKINSTALLDIR'\bin;':+ get_env('PATH');
   }
    
    INCLUDE := "";
    LIB := "";
    if (VCINSTALLDIR!='' && SDKINSTALLDIR!='') {
       sdkdir:="";
       if (major_version>=14) {
          bits := (machine_bits() == 64) ? 'x64' : 'x86';
          if (UniversalCRTSdkDir != "" && UCRTVersion != '') {
             sdkdir :+= UniversalCRTSdkDir:+'lib\':+UCRTVersion:+'\ucrt\':+bits;
             sdkdir :+= ';';
             sdkdir :+= UniversalCRTSdkDir:+'lib\':+UCRTVersion:+'\um\':+bits;
          }
          if (NETFXSDKDir != '') {
             if (sdkdir != '') {
                sdkdir :+= ';';
             }
             sdkdir :+= NETFXSDKDir:+'lib\um\':+bits;
          }
       } else if (major_version>=11) {
          if (sdkdir != '') {
             sdkdir :+= ';';
          }
          sdkdir=SDKINSTALLDIR'\LIB';
          if (major_version>=12) {
             // Visual Studio 2013 and Visual Studio 2015
             // LIB=C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\LIB;C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\ATLMFC\LIB;C:\Program Files (x86)\Windows Kits\8.1\lib\winv6.3\um\x86
             bits := (machine_bits() == 64) ? 'x64' : 'x86';
             sdkdir :+= '\winv6.3\um\x86';
          } else {
             // Visual Studio 2012
             //LIB=C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\LIB;C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\ATLMFC\LIB;C:\Program Files (x86)\Windows Kits\8.0\lib\win8\um\x86; 
             bits := (machine_bits() == 64) ? 'x64' : 'x86';
             sdkdir :+= '\win8\um\':+bits;
          } 
       }

       if (isExpressEdition) {
          INCLUDE=VCINSTALLDIR'\INCLUDE;':+
          SDKINSTALLDIR'\INCLUDE;':+
          get_env('INCLUDE');
          if (machine_bits() :== "64") {
             LIB=VCINSTALLDIR'\LIB\amd64;':+
                sdkdir;
          } else {
             LIB=VCINSTALLDIR'\LIB;':+
                sdkdir;
          }

       } else {
         INCLUDE=VCINSTALLDIR'\ATLMFC\INCLUDE;':+
         VCINSTALLDIR'\INCLUDE;':+
         SDKINSTALLDIR'\INCLUDE;':+
         get_env('INCLUDE');
         if (machine_bits() :== "64") {
            LIB=VCINSTALLDIR'\ATLMFC\LIB\amd64;':+
               VCINSTALLDIR'\LIB\amd64;':+
               sdkdir;
         } else {
            LIB=VCINSTALLDIR'\ATLMFC\LIB;':+
               VCINSTALLDIR'\LIB;':+
               sdkdir;
         }
       }
    }
    /*
      Check that these LIB directories exist
    */
    lib_path_list:=LIB;
    LIB='';
    for (;;) {
       if ( lib_path_list=='') break;
       parse lib_path_list with auto test_dir ';' lib_path_list;
       if (file_exists(test_dir)) {
          if (LIB!='') {
             LIB:+=';';
          }
          LIB:+=test_dir;
       }
    }
    LIB=LIB:+';':+get_env('LIB');
    if (major_version>=11) {
       // Includes are same for express edititions of these
       if (major_version==11) {
          //INCLUDE=_get_vs_sys_includes(isExpressEdition?COMPILER_NAME_VS2012_EXPRESS:COMPILER_NAME_VS2012);
          INCLUDE=_get_vs_sys_includes(COMPILER_NAME_VS2012);
       } else if (major_version==12) {
          //INCLUDE=_get_vs_sys_includes(isExpressEdition?COMPILER_NAME_VS2013_EXPRESS:COMPILER_NAME_VS2013);
          INCLUDE=_get_vs_sys_includes(COMPILER_NAME_VS2013);
       } else if (major_version==14) {
          //INCLUDE=_get_vs_sys_includes(isExpressEdition?COMPILER_NAME_VS2015_EXPRESS:COMPILER_NAME_VS2015);
          INCLUDE=_get_vs_sys_includes(COMPILER_NAME_VS2015);
       } else if (major_version==15) {
          //INCLUDE=_get_vs_sys_includes(isExpressEdition?COMPILER_NAME_VS2015_EXPRESS:COMPILER_NAME_VS2015);
          INCLUDE=_get_vs_sys_includes(COMPILER_NAME_VS2017);
       } else {
          _message_box('Need new code for determining Visual Studio ' :+ major_version :+ ' location. [vchack.e]');
          //INCLUDE=_get_vs_sys_includes(COMPILER_NAME_VS2014);
       }
    }


   set_env('PATH',PATH);
   set_env('LIB',LIB);
   set_env('INCLUDE',INCLUDE);
   set_env('DevEnvDir',DEVENVDIR);

   set_env('MSVCDir',null);
   set_env('VSCommonDir',null);

   // Now set them in the build window if necessary.
   set('PATH='get_env('PATH'));
   set('DevEnvDir='get_env('DevEnvDir'));
   set('MSVCDir='get_env('MSVCDir'));
   set('INCLUDE='get_env('INCLUDE'));
   set('LIB='get_env('LIB'));
   set('VSINSTALLDIR='get_env('VSINSTALLDIR'));
   set('VCINSTALLDIR='get_env('VCINSTALLDIR'));
   if (major_version >= 10) {
      if (target_version != '') {
         set('VisualStudioVersion='target_version);
      }
   }

   //say('done with env');
   return(0);
}

static int _set_visualstudio2017_environment(int major_version, bool quiet=false) {

   _str target_version='';

   if (major_version > 16) {
      _message_box('Need new code for determining Visual Studio ' :+ major_version :+ ' location. [vchack.e]');
   }
   platformSDKVersionString := "v10.0";

   VSINSTALLDIR := _getVStudioInstallPath2017(major_version,true);
   if (major_version == 16) {
      target_version = '16.0';
   } else if (major_version == 15) {
      target_version = '15.0';
   }
   if (VSINSTALLDIR == '') {
      VSINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7", "", target_version); 
      if (VSINSTALLDIR == '') {
         _message_box('Cannot find Visual Studio install path for version: 'major_version);
         return(1);
      }
   }

   VCINSTALLDIR := VSINSTALLDIR:+'VC':+FILESEP;
   if (!file_exists(VCINSTALLDIR)) {
      return(1);
   }
   DEVENVDIR := VSINSTALLDIR:+'Common7\IDE\';
   VSCOMNTOOLS := VSINSTALLDIR:+'Common7\Tools\';

   KitsRoot := "KitsRoot10";
   UniversalCRTSdkDir := _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots", "", KitsRoot);
   do {
      if (UniversalCRTSdkDir != "") break;
      KitsRoot = "KitsRoot81";
      UniversalCRTSdkDir = _ntRegQueryValue(HKEY_CURRENT_USER, "SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots", "", KitsRoot);
      if (UniversalCRTSdkDir != "") break;
      KitsRoot = "KitsRoot";
      UniversalCRTSdkDir = _ntRegQueryValue(HKEY_CURRENT_USER, "SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots", "", KitsRoot);
   } while (false);


   UCRTVersion := "";
   // iterate over windows kit 10 versions to find the newest one with windows.h
   if (UniversalCRTSdkDir != "" && KitsRoot=="KitsRoot10") {
      versionDir := dir_match(UniversalCRTSdkDir:+"Include":+FILESEP:+"10.*", true);
      while (versionDir != "") {
         unquotedVersionDir := _maybe_unquote_filename(versionDir);
         unquotedVersionDir = strip(unquotedVersionDir,'T',FILESEP);
         if (file_exists(unquotedVersionDir:+FILESEP:+"um":+FILESEP:+"windows.h")) {
            UCRTVersion = _strip_filename(unquotedVersionDir,'P'):+FILESEP;
            break;
         }
         versionDir = dir_match(versionDir, false);
      }
   }

   NETFXSDKDir := '';
   sdkversion := '';
   int status = _ntRegFindFirstSubKey(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\Microsoft SDKs\NETFXSDK\',sdkversion,1);
   while (!status) {
      status = _ntRegFindFirstSubKey(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\Microsoft SDKs\NETFXSDK\',sdkversion,0);
   }
   if (sdkversion != '') {
      NETFXSDKDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Microsoft SDKs\NETFXSDK\':+sdkversion, "", "KitsInstallationFolder");
   }

   __VCVARS_TOOLS_VERSION := _getVCToolsVersion2017(VCINSTALLDIR, major_version);
   VCToolsInstallDir := VCINSTALLDIR:+'Tools\MSVC\':+__VCVARS_TOOLS_VERSION:+'\';
   if (!file_exists(VCToolsInstallDir)) {
      VCToolsInstallDir = '';
   }
   VCToolsRedistDir := VCINSTALLDIR:+'Redist\MSVC\':+__VCVARS_TOOLS_VERSION:+'\';
   if (!file_exists(VCToolsRedistDir)) {
      VCToolsRedistDir = '';
   }

/*
PATH=
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\bin\HostX86\x86;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\VC\VCPackages;
   C:\Program Files (x86)\Microsoft SDKs\TypeScript\2.2;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TestWindow;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\bin\Roslyn;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Team Tools\Performance Tools;
   C:\Program Files (x86)\Microsoft Visual Studio\Shared\Common\VSPerfCollectionTools\;
   C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\;
   C:\Program Files (x86)\Microsoft SDKs\F#\4.1\Framework\v4.0\;
   C:\Program Files (x86)\Windows Kits\10\bin\x86;
   C:\Program Files (x86)\Windows Kits\10\bin\10.0.15063.0\x86;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\\MSBuild\15.0\bin;
   C:\Windows\Microsoft.NET\Framework\v4.0.30319;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\Tools\;


   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\VC\VCPackages;
   C:\Program Files (x86)\\Microsoft SDKs\TypeScript\2.2;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\bin;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\Tools\;

INCLUDE=
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\ATLMFC\include;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\include;
   C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6.1\include\um;
   C:\Program Files (x86)\Windows Kits\10\include\10.0.14393.0\ucrt;
   C:\Program Files (x86)\Windows Kits\10\include\10.0.14393.0\shared;
   C:\Program Files (x86)\Windows Kits\10\include\10.0.14393.0\um;
   C:\Program Files (x86)\Windows Kits\10\include\10.0.14393.0\winrt;

LIB=
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\ATLMFC\lib\x64;
   C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.10.25017\lib\x64;
   C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6.1\lib\um\x64;
   C:\Program Files (x86)\Windows Kits\10\lib\10.0.14393.0\ucrt\x64;
   C:\Program Files (x86)\Windows Kits\10\lib\10.0.14393.0\um\x64;

*/      
   
    
   include_path := "";
   if (major_version==15) {
      include_path=_get_vs_sys_includes(COMPILER_NAME_VS2017);
   } else if (major_version==16) {
      include_path=_get_vs_sys_includes(COMPILER_NAME_VS2019);
   }
   
   lib_path := "";
   bits := (machine_bits() == 64) ? 'x64' : 'x86';
   if (VCToolsInstallDir != '') {
      strappend(lib_path, VCToolsInstallDir:+'ATLMFC\lib':+FILESEP:+bits);
      strappend(lib_path, ';');
      strappend(lib_path, VCToolsInstallDir:+'lib':+FILESEP:+bits);
      strappend(lib_path, ';');
   }
   if (UniversalCRTSdkDir != "" && UCRTVersion != '') {
      strappend(lib_path, UniversalCRTSdkDir:+'lib':+FILESEP:+UCRTVersion:+'ucrt':+FILESEP:+bits);
      strappend(lib_path, ";");
      strappend(lib_path, UniversalCRTSdkDir:+'lib':+FILESEP:+UCRTVersion:+'um':+FILESEP:+bits);
      strappend(lib_path, ";");
   }
   if (NETFXSDKDir != '') {
      strappend(lib_path, NETFXSDKDir:+"lib":+FILESEP:+"um":+FILESEP:+bits);
   }
   /*
     Check that these LIB directories exist
   */
   lib_path_list:=lib_path;
   lib_path='';
   for (;;) {
      if ( lib_path_list=='') break;
      parse lib_path_list with auto test_dir ';' lib_path_list;
      if (file_exists(test_dir)) {
         if (lib_path!='') {
            lib_path:+=';';
         }
         lib_path:+=test_dir;
      }
   }
   

   path := '';
   if (machine_bits() == 64) {
      if (file_exists(VCToolsInstallDir:+'bin\HostX64\x64')) {
         strappend(path, VCToolsInstallDir:+'bin\HostX64\x64');
         strappend(path, ";");
      }
   } else {
      if (file_exists(VCToolsInstallDir:+'bin\HostX86\x86')) {
         strappend(path, VCToolsInstallDir:+'bin\HostX86\x86');
         strappend(path, ";");
      }
   }

   strappend(path, VSINSTALLDIR:+'Common7\IDE\VC\VCPackages');
   strappend(path, ";");

   ntGetSpecialFolderPath(auto ProgramFiles, CSIDL_PROGRAM_FILES);
   if (file_exists(ProgramFiles:+'Microsoft SDKs\TypeScript\2.2')) {
      strappend(path, ProgramFiles:+'Microsoft SDKs\TypeScript\2.2');
      strappend(path, ";");
   } else if (file_exists(ProgramFiles:+'Microsoft SDKs\TypeScript\2.1')) {
      strappend(path, ProgramFiles:+'Microsoft SDKs\TypeScript\2.1');
      strappend(path, ";");
   }

   if (machine_bits() == 64) {
      ntGetSpecialFolderPath(ProgramFiles, CSIDL_PROGRAM_FILESX86);
      if (file_exists(ProgramFiles:+'Microsoft SDKs\TypeScript\2.2')) {
         strappend(path, ProgramFiles:+'Microsoft SDKs\TypeScript\2.2');
         strappend(path, ";");
      } else if (file_exists(ProgramFiles:+'Microsoft SDKs\TypeScript\2.1')) {
         strappend(path, ProgramFiles:+'Microsoft SDKs\TypeScript\2.1');
         strappend(path, ";");
      }
   }


   MSBUILDDIR := VSINSTALLDIR:+'MSBuild\Current\Bin';
   if (file_exists(MSBUILDDIR)) {
      strappend(path, MSBUILDDIR);
      strappend(path, ";");
   } else {
      MSBUILDDIR = VSINSTALLDIR:+'MSBuild\':+target_version:+'\bin';
      if (file_exists(MSBUILDDIR)) {
         strappend(path, MSBUILDDIR);
         strappend(path, ";");
      }
   }

   strappend(path, VSINSTALLDIR:+'Common7\IDE\');
   strappend(path, ";");
   strappend(path, VSINSTALLDIR:+'Common7\Tools\');
   strappend(path, ";");
   strappend(path, get_env('PATH'));

   set_env('VisualStudioVersion', target_version);
   set_env('PATH',path);
   set_env('LIB',lib_path);
   set_env('INCLUDE',include_path);
   set_env('DevEnvDir',DEVENVDIR);
   set_env('VCINSTALLDIR',VCINSTALLDIR);
   set_env('VSINSTALLDIR',VSINSTALLDIR);

   env_commontools := '';
   switch (major_version) {
   case 15:
      env_commontools = 'VS150COMNTOOLS'; 
      break;
   case 16:
      env_commontools = 'VS160COMNTOOLS'; 
      break;
   }
   set_env(env_commontools,VSCOMNTOOLS);

   if (VCToolsInstallDir != '') {
      set_env('VCToolsInstallDir',VCToolsInstallDir);
   }
   if (VCToolsRedistDir != '') {
      set_env('VCToolsRedistDir',VCToolsRedistDir);
   }

   set('VisualStudioVersion='get_env('VisualStudioVersion'));
   set('PATH='get_env('PATH'));
   set('DevEnvDir='get_env('DevEnvDir'));
   set('INCLUDE='get_env('INCLUDE'));
   set('LIB='get_env('LIB'));
   set('VCINSTALLDIR='get_env('VCINSTALLDIR'));
   set('VSINSTALLDIR='get_env('VSINSTALLDIR'));
   set(env_commontools'='get_env(env_commontools));
   if (VCToolsInstallDir != '') {
      set('VCToolsInstallDir='get_env('VCToolsInstallDir'));
   }
   if (VCToolsRedistDir != '') {
      set('VCToolsRedistDir='get_env('VCToolsRedistDir'));
   }
   return 0;
}

/**
 * Sets the environment variables for Visual Studio 2015
 */
_command int set_visualstudio2019_environment()
{
   return(_set_visualstudio_environment(false,16));
}

/**
 * Sets the environment variables for Visual Studio 2015
 */
_command int set_visualstudio2017_environment()
{
   return(_set_visualstudio_environment(false,15));
}


/**
 * Sets the environment variables for Visual Studio 2015
 */
_command int set_visualstudio2015_environment()
{
   return(_set_visualstudio_environment(false,14));
}

/**
 * Sets the environment variables for Visual Studio 2013
 */
_command int set_visualstudio2013_environment()
{
   return(_set_visualstudio_environment(false,12));
}

/**
 * Sets the environment variables for Visual Studio 2012 
 */
_command int set_visualstudio2012_environment()
{
   return(_set_visualstudio_environment(false,11));
}

/**
 * Sets the environment variables for Visual Studio 2010 
 */
_command int set_visualstudio2010_environment()
{
   return(_set_visualstudio_environment(false,10));
}

/**
 * Sets the environment variables for Visual Studio 2008 
 */
_command int set_visualstudio2008_environment()
{
   return(_set_visualstudio_environment(false,9));
}

/**
 * Sets the environment variables for Visual Studio 2005 (Whidbey)
 */
_command int set_visualstudio2005_environment()
{
   return(_set_visualstudio_environment(false,8));
}

/**
 * Sets the environment variables for Visual Studio .NET 2003 (Everett)
 */
_command int set_visualstudio2003_environment()
{
   return(_set_visualstudio_environment(false,7));
}

/**
 * Sets the environment variables for Visual Studio, whatever the latest version is
 *
 * <P>
 * If the user configures SlickEdit to use a specific
 * version of Visual C++.  The user will need to exit
 * the editor before the environment can be set up
 * correctly.
 *
 * @param quiet
 * @return
 */
_command int set_visualstudio_environment(bool quiet=false,_str version='',int major_version=0,bool must_set_environment=false)
{
   /*
      NOTE: In the future, we may want to make sure the correct visual studio
      compiler is being found based on the visual studio project "version" 
      attribute.
   */
   /*
      Here we try reusing the current PATH settings if cl is already in the PATH. This code
      is only expected to be hit for a single file project. If the causes problems, add
      an argument to this function which clearly indicates this is for a single file project.
   */
   //IF we are trying to set up a single file project build/compile
   if (!must_set_environment && version=='' && major_version==0) {
      _str found_path=path_search('cl','','P');
      if (found_path:!='') {
         if (!quiet) {
            _message_box('Visual C++ is already setup.  devenv.exe is already in your PATH.');
         }
         return(0);
      }
   }
   _restore_origenv();
   if (!must_set_environment) {
      _str found_path=_orig_path_search('devenv');
      if (found_path:!='') {
         if (!quiet) {
            _message_box('Visual C++ is already setup.  devenv.exe is already in your PATH.');
         }
         _restore_origenv(true,true);
         return(0);
      }
   }

   if (version!='' && major_version==0) {
      major_version_s := "";
      parse version with major_version_s '.' .;
      if (isnumber(major_version_s)) {
         major_version = (int)major_version_s;
      }
   }
   return(_set_visualstudio_environment(quiet,major_version,version));
}

_str _vstudio_get_version_from_tests(_str solutionVersion='',bool setup_environment=true) {
   _str tests = def_auto_visual_studio_select;
   if (tests == '') {
      tests = "project,latest,solution,prompt"; // defaults
   }

   while (tests != '') {
      parse tests with auto use "," tests;
      switch (use) {
      case 'project':
         platformVersion := vstudio_find_platform_toolset();
         if (platformVersion > 0) {
            if (setup_environment) {
               set_visualstudio_environment(true, '', platformVersion, true);
            }
            return platformVersion;
         }
         break;

      case 'solution':
         if (setup_environment) {
            if (solutionVersion != '') {
               set_visualstudio_environment(true, solutionVersion, 0, true);
               return solutionVersion;
            }
         }
         break;

      case 'latest':
         latestMS := _getLatestVisualStudioVersion();
         latestVersion := 0;
         switch (latestMS) {
         case COMPILER_NAME_VS2003:    
            latestVersion = 7;
            break;
         case COMPILER_NAME_VS2005:
         case COMPILER_NAME_VS2005_EXPRESS:
            latestVersion = 8; 
            break;
         case COMPILER_NAME_VS2008:
         case COMPILER_NAME_VS2008_EXPRESS:
            latestVersion = 9; 
            break;
         case COMPILER_NAME_VS2010:
         case COMPILER_NAME_VS2010_EXPRESS:
            latestVersion = 10; 
            break;
         case COMPILER_NAME_VS2012:
         case COMPILER_NAME_VS2012_EXPRESS:
            latestVersion = 11; 
            break;
         case COMPILER_NAME_VS2013:
         case COMPILER_NAME_VS2013_EXPRESS:
            latestVersion = 12; 
            break;
         case COMPILER_NAME_VS2015:
         case COMPILER_NAME_VS2015_EXPRESS:
            latestVersion = 14; 
            break;
         case COMPILER_NAME_VS2017:
            latestVersion = 15; 
            break;;
         case COMPILER_NAME_VS2019:
            latestVersion = 16; 
            break;
         default:
            break;
         }
         if (latestVersion > 0) {
            if (setup_environment) {
               set_visualstudio_environment(true, '', latestVersion, true);
            }
            return latestVersion;
         }
         break;

      case 'prompt':
         if (setup_environment) {
            version := _vstudio_select_toolset();
            if (version > 0) {
               set_visualstudio_environment(true, '', version, true);
               return version;
            }
         }
         break;

      default:
      }
   }
   return '';
}
void _init_vcpp()
{
   if (_IsWorkspaceAssociated(_workspace_filename) && _project_name!='') {
      int handle = _ProjectHandle(_project_name);
      _str build_command = _ProjectGet_TargetCmdLine(handle,_ProjectGet_TargetNode(handle,'Build'));
      _str filename=parse_file(build_command,false);
      name := _strip_filename(filename,'PE');

      if (_file_eq(name,'msdev') || _file_eq(name,'devenv') || _file_eq(name,'msbuild') ) {
         // Make sure the .NET version of cl is not used (or for that
         // matter, the LIB and INCLUDE environment variables) when
         // switching between VC6 and .NET projects
         _restore_origenv(true,true);

         _str found_file=path_search(filename,"","P");
         if (found_file!="") {
            _str VCPPProjectFilename;
            int status=_GetAssociatedProjectInfo(_project_name, VCPPProjectFilename);
            if (!status) {
               _str ext=_get_extension(VCPPProjectFilename,true);
               if (_file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT)) {
                  filename='msbuild';
                  found_file=path_search(filename,"","P");
               }
            }
         }
         if (found_file=="" ) {
            if (_file_eq(name,'msdev') ) {
               set_devstudio_environment(true);
            } else {
               if (def_use_visual_studio_version > 0) {
                  set_visualstudio_environment(true,'',def_use_visual_studio_version,true);
                  return;
               }

               // check for older solutions
               solutionVersion := "";
               _str sln_file = _AbsoluteToWorkspace(_WorkspaceGet_AssociatedFile(gWorkspaceHandle));
               if (sln_file:!='') {
                  solutionVersion = vstudio_application_version(sln_file);
                  if (solutionVersion != '') {
                     if(isnumber(solutionVersion)) {
                        double ver = (double)solutionVersion;
                        if (ver < 10.0) {
                           set_visualstudio_environment(true, solutionVersion, 0, true);
                           return;
                        }
                     }
                  }
               }
               _vstudio_get_version_from_tests(solutionVersion);
            }
         }
      }
   }
}

int _vstudio_select_toolset()
{
   _str vstudio_versions[];
   _getVisualStudioVersions(vstudio_versions);

   _str result = select_tree(vstudio_versions, null, null, null, null, null, null,
                             "Select Visual Studio Version");
   version := 0;
   switch(result) {
   case COMPILER_NAME_VS2003:
      version = 7;
      break;

   case COMPILER_NAME_VS2005:
   case COMPILER_NAME_VS2005_EXPRESS:
      version = 8;
      break;

   case COMPILER_NAME_VS2008:
   case COMPILER_NAME_VS2008_EXPRESS:
      version = 9;
      break;

   case COMPILER_NAME_VS2010:
   case COMPILER_NAME_VS2010_EXPRESS:
      version = 10;
      break;

   case COMPILER_NAME_VS2012:
   case COMPILER_NAME_VS2012_EXPRESS:
      version = 11;
      break;

   case COMPILER_NAME_VS2013:
   case COMPILER_NAME_VS2013_EXPRESS:
      version = 12;
      break;

   case COMPILER_NAME_VS2015:
   case COMPILER_NAME_VS2015_EXPRESS:
      version = 14;
      break;

   case COMPILER_NAME_VS2017:
      version = 15;
      break;
   case COMPILER_NAME_VS2019:
      version = 16;
      break;
   }
   return version;
}

_command void vstudio_select_environment() name_info(',')
{
   platform_toolset := _vstudio_select_toolset();
   if (platform_toolset > 0) {
      set_visualstudio_environment(true, '', platform_toolset, true);
   }
}
int _vstudio_find_platform_toolset1(_str filename) {
   majorVersion:=0;
   ext := _get_extension(filename, true);
   if (_file_eq(ext, VISUAL_STUDIO_VCX_PROJECT_EXT)) {
       handle := _xmlcfg_open(filename, auto status, VSXMLCFG_OPEN_ADD_PCDATA);
       if (status) return 0;

       val := "";
       // TBD: find all platform toolsets and compare???
       // find any platform toolset
       index := _xmlcfg_find_simple(handle, "/Project/PropertyGroup[@Label='Configuration']/PlatformToolset");
       if (index >= 0) {
          int data = _xmlcfg_get_first_child(handle, index, VSXMLCFG_NODE_PCDATA);
          if (data >= 0) {
             val = _xmlcfg_get_value(handle, data);
         }
       }
       _xmlcfg_close(handle);
       if (val != '') {
          version := 0;
          switch (val) {
          case 'v90':
             version = 9; break;
          case 'v100':   
          case 'v100_xp':   
             version = 10; break;
          case 'v110':      
          case 'v110_xp':
             version = 11; break;
          case 'v120':
          case 'v120_xp':
             version = 12; break;
          case 'v140':
          case 'v140_xp':  
             version = 14; break;
          case 'v141':
             version = 15; break;
          case 'v142':
             version = 16; break;
          default:
             break;
          }
          if (version > majorVersion) {
             majorVersion = version;
          }
       }
   }
   return majorVersion;
}
int _vstudio_find_platform_toolset2(_str filename){
   majorVersion:=0;
   ext := _get_extension(filename, true);
   // .csproj
   //<Project ToolsVersion="15.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
   if (_file_eq(ext, VISUAL_STUDIO_CSHARP_PROJECT_EXT) || _file_eq(ext, VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT)) {
      handle := _xmlcfg_open(filename, auto status, VSXMLCFG_OPEN_ADD_PCDATA);
      if (status) return 0;
      index := _xmlcfg_find_simple(handle, "/Project");
      typeless version;
      parse _xmlcfg_get_attribute(handle,index,'ToolsVersion') with version '.';
      _xmlcfg_close(handle);
      if (version!='') {
         if (version>=9 && version<=16) {
            if (version > majorVersion) {
               majorVersion = version;
            }
         }
      }
   }
   return majorVersion;
}

static int vstudio_find_platform_toolset()
{
   if (!_IsWorkspaceAssociated(_workspace_filename)) {
      return 0;
   }

   workspaceFile := _WorkspaceGet_AssociatedFile(gWorkspaceHandle);
   if (workspaceFile == '') {
      return 0;
   }

   ext := _get_extension(workspaceFile, true);
   if (!_file_eq(ext,VISUAL_STUDIO_SOLUTION_EXT)) {
      return 0;
   }
   majorVersion := 0;
   int i;
   _str projects[] = null;
   int status = _GetWorkspaceFiles(_workspace_filename, projects);
   for (i = 0; i < projects._length(); ++i) {
      filename := "";
      status = _GetAssociatedProjectInfo(_AbsoluteToWorkspace(projects[i], _workspace_filename), filename);
      if (status) continue;
      majorVersion=_vstudio_find_platform_toolset1(filename);
   }
   if (!majorVersion) {
      for (i = 0; i < projects._length(); ++i) {
         filename := "";
         status = _GetAssociatedProjectInfo(_AbsoluteToWorkspace(projects[i], _workspace_filename), filename);
         if (status) continue;

         majorVersion=_vstudio_find_platform_toolset2(filename);
      }
   }
   return majorVersion;
}

/**
 * Calls vstudio_open_file to open the current file in Visual Studio. It will first
 * attempt to connect to a running instance of Visual Studio. 
 *  
 * <p>Does not support versions of Visual Studio older than 2003
 * 
 * @return 1 if successful, 
 *         -2 if the file doesn't exist,
 *         or an error code from vstudio_open_file()
 *  
 * @categories Miscellaneous_Functions
 */
_command int vstudio_edit_file() name_info(','VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Visual Studio integration");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if(file_exists(p_buf_name))
   {
      // DO NOT QUOTE this filename (p_buf_name). The DLL function will handle
      // quoting the path if needed.
      return vstudio_open_file(p_buf_name, p_line, p_col);
   }
   message("File must be saved for this operation");
   return -2;
}

/**
 * Calls vstudio_open_solution to open the current workspace's associated
 * Visual Studio solution (.sln) file in Visual Studio .NET. 
 * 
 * @return  0 if the workspace is not associated with a valid .sln file,
 *          1 if successful, 
 *         -1 indicates Visual Studio could not be started.,
 *         or an error code from vstudio_open_solution()
 *  
 * @categories Miscellaneous_Functions
 */
_command int vstudio_open_solution_file() name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Visual Studio integration");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // Get the associated workspace file (.sln) and read
   // in the file version.
   if (gWorkspaceHandle < 0)
   {
      message("No workspace open");
      return 0;
   }

   // Find the Visual Studio .sln file associate with this workspace
   _str workspaceFile=_WorkspaceGet_AssociatedFile(gWorkspaceHandle);
   if (workspaceFile=='')
   {
      message("Not a Visual Studio 2003 (or later) solution");
      return 0;
   }
   // Get the full (quoted) path to the .sln file and retrieve the file version
   workspaceFile=absolute(workspaceFile,_strip_filename(_xmlcfg_get_filename(gWorkspaceHandle),'N'));
   // Convert file version to Visual Studio version
   _str vstudioVer = vstudio_application_version(workspaceFile);
   if (vstudioVer != '')
   {
      // Invoke builtin for opening the solution file in Visual Studio
      fullSlnPath := _maybe_quote_filename(workspaceFile);
      if(!vstudio_open_solution(fullSlnPath, vstudioVer))
      {
         message("Could not open with Visual Studio version "vstudioVer);
      }
   }
   else
   {
      message("Not a Visual Studio 2003 (or later) solution");
   }
   return 0;
}


_str _getVCToolsVersion2017(_str VCINSTALLDIR, int major_version)
{
   if (VCINSTALLDIR == '') {
      return '';
   }
   toolsVersion := '';
   configFile := 'Microsoft.VCToolsVersion.default.txt';
   if (major_version == 16) {
      configFile = 'Microsoft.VCToolsVersion.v142.default.txt';
   }
   filename := _maybe_quote_filename(VCINSTALLDIR:+'Auxiliary\Build\':+configFile);
   if (!_GetFileContents(filename, toolsVersion)) {
      if (toolsVersion != '') {
         toolsVersion=strip(toolsVersion);
         toolsVersion=strip(toolsVersion,'B',"\n");
         toolsVersion=strip(toolsVersion,'B',"\r");
      }
   }

   if (toolsVersion != '') {
      return toolsVersion;
   }
   toolsVersion = '';
   configFile = 'Microsoft.VCToolsVersion.default.props';
   if (major_version == 16) {
      configFile = 'Microsoft.VCToolsVersion.v142.default.props';
   }
   filename = VCINSTALLDIR:+'Auxiliary\Build\':+configFile;  
   handle := _xmlcfg_open(filename, auto status, VSXMLCFG_OPEN_ADD_PCDATA);
   if (!status) {
      index := _xmlcfg_find_simple(handle, "/Project/PropertyGroup/VCToolsVersion");
      if (index >= 0) {
         data := _xmlcfg_get_first_child(handle, index, VSXMLCFG_NODE_PCDATA);
         if (data >= 0) {
            toolsVersion = _xmlcfg_get_value(handle, data);
        }
      }
      _xmlcfg_close(handle);
   }

   return toolsVersion;
}

// vswhere.exe --
// vswhere is designed to be a redistributable, single-file executable that can be used 
// in build or deployment scripts to find where Visual Studio - or other products in 
// the Visual Studio family - is located. For example, if you know the relative path to 
// MSBuild, you can find the root of the Visual Studio install and combine the paths to 
// find what you need.

static void query_vswhere()
{
   if (!_isWindows() || !vstudio_installs._isempty()) {
      return;
   }

   exePath := path_search('vswhere.exe','','P');
   if (exePath :== '') {
      ntGetSpecialFolderPath(auto ProgramFiles, (ntIs64Bit()) ? CSIDL_PROGRAM_FILESX86 : CSIDL_PROGRAM_FILES);
      exePath = ProgramFiles:+"Microsoft Visual Studio\\Installer\\vswhere.exe";
      if (!file_exists(exePath)) {
         exePath = '';
      }
   }

   if (exePath :== '') {
      // prompt for location?  find default? def-var?
      return;
   }

   cmd := _maybe_quote_filename(exePath):+' -utf8 -all -prerelease -requires Microsoft.Component.MSBuild -format xml';
   result := _PipeShellResult(cmd, auto status, 'CH');
   if (result != '') {
      handle := _xmlcfg_open_from_string(result, status,VSXMLCFG_OPEN_ADD_PCDATA);
      if (handle >= 0) {
         _xmlcfg_find_simple_array(handle, "/instances/instance", auto array);
         foreach (auto i=> auto instance in array) {
            //installationPath
            //installationVersion
            //displayName
            //productId
            _str name, version, path, productId;
            int node, cdata;
            node = _xmlcfg_find_child_with_name(handle, (int)instance, "installationPath", VSXMLCFG_NODE_ELEMENT_START);
            if (node > 0) {
               cdata = _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_CDATA|VSXMLCFG_NODE_PCDATA);
               if (cdata >= 0) {
                  path = _xmlcfg_get_value(handle, cdata);
               }
            }

            node = _xmlcfg_find_child_with_name(handle, (int)instance, "installationVersion", VSXMLCFG_NODE_ELEMENT_START);
            if (node > 0) {
               cdata = _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_CDATA|VSXMLCFG_NODE_PCDATA);
               if (cdata >= 0) {
                  version = _xmlcfg_get_value(handle, cdata);
               }
            }

            node = _xmlcfg_find_child_with_name(handle, (int)instance, "productId", VSXMLCFG_NODE_ELEMENT_START);
            if (node > 0) {
               cdata = _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_CDATA|VSXMLCFG_NODE_PCDATA);
               if (cdata >= 0) {
                  productId = _xmlcfg_get_value(handle, cdata);
               }
            }

            node = _xmlcfg_find_child_with_name(handle, (int)instance, "displayName", VSXMLCFG_NODE_ELEMENT_START);
            if (node > 0) {
               cdata = _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_CDATA|VSXMLCFG_NODE_PCDATA);
               if (cdata >= 0) {
                  name = _xmlcfg_get_value(handle, cdata);
               }
            } else {
               node = _xmlcfg_find_child_with_name(handle, (int)instance, "instanceId", VSXMLCFG_NODE_ELEMENT_START);
               if (node > 0) {
                  cdata = _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_CDATA|VSXMLCFG_NODE_PCDATA);
                  if (cdata >= 0) {
                     name = _xmlcfg_get_value(handle, cdata);
                  }
               }
            }

            VSInstall vs;
            vs.name = name; vs.version = version; vs.path = path; vs.productid = productId;
            vstudio_installs[vstudio_installs._length()] = vs;
         }
         _xmlcfg_close(handle);
      }
   }

   if (vstudio_installs._isempty()) {
      VSInstall vs;
      vs.name = ''; vs.version = ''; vs.path = ''; vs.productid = '';
      vstudio_installs[vstudio_installs._length()] = vs;
   }
}

// in case of multiple installations, sort by product ids
static int VisualStudioProductIds:[] = {
   "Microsoft.VisualStudio.Product.Enterprise"     => 0,
   "Microsoft.VisualStudio.Product.Professional"   => 1,
   "Microsoft.VisualStudio.Product.Community"      => 2,
   "Microsoft.VisualStudio.Product.WDExpress"      => 3,
   "Microsoft.VisualStudio.Product.BuildTools"     => 4,
   ""                                              => 99
};

static int vsinstall_sort_by_productid(VSInstall &vs1, VSInstall &vs2)
{
   p1 := VisualStudioProductIds._indexin(vs1.productid);
   p2 := VisualStudioProductIds._indexin(vs2.productid);
   v1 := (p1 != null) ? *p1 : 99; v2 := (p2 != null) ? *p2 : 99;
   return (v1 - v2);
}
static int vsinstall_sort_by_version_productid(VSInstall &vs1, VSInstall &vs2)
{
   status:=_version_compare(vs1.version,vs2.version);
   if (status) {
      return status;
   }
   return vsinstall_sort_by_productid(vs1,vs2);
}


_str _getVStudioInstallPath2017(int &majorVersion,bool find_ge=false)
{
   if (majorVersion < 15) {
      return "";
   }

   query_vswhere();
   if (vstudio_installs._isempty()) {
      return "";
   }


   VSInstall matches[];
   foreach (auto vs in vstudio_installs) {
      parse vs.version with auto major "." .;
      if (isnumber(major) && (majorVersion == (int)major)) {
         matches[matches._length()] = vs;
      }
   }
   // no matching 
   if (matches._isempty()) {
      if (!find_ge) {
         return '';
      }
      foreach (vs in vstudio_installs) {
         parse vs.version with auto major "." .;
         if (isnumber(major) && ((int)major>=majorVersion)) {
            matches[matches._length()] = vs;
         }
      }
      if (matches._length() < 1) {
         return '';
      }
      // sort by version,productId
      if (matches._length() > 1) {
         matches._sort("", 0, -1, vsinstall_sort_by_version_productid);
      }

      path :=  matches[0].path;
      parse matches[0].version with auto major "." .;
      majorVersion=(int)major;
      if (path != '') {
         _maybe_append(path, FILESEP);
      }
      return path;
   }
   
   // sort by productId
   if (matches._length() > 1) {
      matches._sort("", 0, -1, vsinstall_sort_by_productid);
   }

   path :=  matches[0].path;
   if (path != '') {
      _maybe_append(path, FILESEP);
   }
   return path;
}


 
