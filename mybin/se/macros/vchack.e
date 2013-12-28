////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47113 $
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
#import "env.e"
#import "files.e"
#import "main.e"
#import "projconv.e"
#import "projutil.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "util.e"
#import "wkspace.e"
#endregion

int _VCPPTimerHandle=-1;

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
 * @param boolean value       value to set (send null to 
 *                            retrieve the current value)
 * 
 * @return boolean            true if shortcut is there, false 
 *                            otherwise
 */
boolean _vcppsetup_se_shortcut_on_vcpp_menu(boolean value = null)
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

_command set_vcpp_version()
{
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
   }
}

static void EditorOnTop()
{
   _set_foreground_syswindow('vs_mdiframe');
}

definit()
{
   if (machine()!='WINDOWS' || _win32s()==1 || DllIsMissing('vchack.dll') ) {
      return;
   }
   if (upcase(arg(1))!='L') {
      _VCPPTimerHandle= (-1);
      /*if (def_vcpp_flags&VCPP_OPEN_ON_START && !VCPPIsUp(def_vcpp_version)) {
         _str path='';
         typeless status=GetVCPPBinPath(path,def_vcpp_version,1);
         if (status||path=='') return;

         path=maybe_quote_filename(path);
         if (_IsVCPPWorkspaceFilename(_workspace_filename)) {
            path=path' 'maybe_quote_filename(_workspace_filename);
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
            if (ss<start_ss) ss=ss:+60;
            if (ss-start_ss>timeout) break;
         }
         EditorOnTop();
      }
      */
      if (def_vcpp_flags&VCPP_ADD_VSE_MENU) {
         PerpetualVCPPMenuItem();
      }
   }
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
_command int appmenu(typeless arg1="")
{
   _str classprefix=0;
   _str windowprefix=0;
   _str classname='';
   _str windowtitle='';
   _str menuspec='';
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
      menuspec=menuspec:+cur;
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
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_VCPP_SETUP)) {
      return;
   }
   _VCPPTimerHandle=_set_timer(1000,find_index("MaybeAddVSEToVCPPMenu",PROC_TYPE),def_vcpp_version);
   typeless status=MaybeAddVSEToVCPPMenu(def_vcpp_version);
}

static int VCPPMessageBoxTimerHandle=-1;
static void FindVCPPReloadMessageBox2(double OrigBTime)
{
   typeless status=FindVCPPReloadMessageBox();
   boolean SearchIsOver=((double)_time('b')-OrigBTime)>=5000;//We have been looking for 5 seconds
   if (!status || SearchIsOver) {
      _kill_timer(VCPPMessageBoxTimerHandle);
      VCPPMessageBoxTimerHandle=-1;
   }
}

void HuntForVCPPMessageBox()
{
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_VCPP_SETUP)) {
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
static int _set_devstudio_environment(boolean quiet=false,int major_version=6)
{
   //Root of Visual Developer Studio Common files.
   _str VSCommonDir;  //G:\vc6\Common

   //Root of Visual Developer Studio installed files.
   _str MSDevDir;  // G:\vc6\Common\msdev98

   //Root of Visual C++ installed files.
   _str MSVCDir;  // G:\vc6\VC98

   _str VcOsDir="WIN95";
   if (!_win32s()) {
      VcOsDir="WINNT";
   }

   // Determine latest version
   _str latestVersionString="";
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
   if (last_char(MSDevDir)==FILESEP) MSDevDir=substr(MSDevDir,1,length(MSDevDir)-1);
   MSDevDir=_strip_filename(MSDevDir,'n');
   if (last_char(MSDevDir)==FILESEP) MSDevDir=substr(MSDevDir,1,length(MSDevDir)-1);

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
_command int set_devstudio_environment(boolean quiet=false)
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
static int _set_visualstudio_environment(boolean quiet=false, int major_version=0, _str target_version='')
{
   _restore_origenv(false,true);
   if (major_version>=9) {
      return(_set_visualstudio2008orHigher_environment(quiet,major_version,target_version));
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
   if (last_char(VSINSTALLDIR)==FILESEP) {
      VSINSTALLDIR=substr(VSINSTALLDIR,1,length(VSINSTALLDIR)-1);
   }
   _str VCINSTALLDIR=_strip_filename(VSINSTALLDIR,'n');
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

   _str majorVersion='7';
   {
      int p=pos('.',target_version);
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

   _str include_path = '%MSVCDir%\ATLMFC\INCLUDE;%MSVCDir%\INCLUDE;%MSVCDir%\PlatformSDK\include\prerelease;%MSVCDir%\PlatformSDK\include;%INCLUDE%';
   // check to see if PlatformSDK\include\prerelease directory exists
   if (file_match('+d +x -p ':+maybe_quote_filename(_replace_envvars('%MSVCDir%\PlatformSDK\include\prerelease')),1)=="") {
      include_path = '%MSVCDir%\ATLMFC\INCLUDE;%MSVCDir%\INCLUDE;%MSVCDir%\PlatformSDK\include;%INCLUDE%'; 
   }
   set_env('INCLUDE',_replace_envvars(include_path));

   _str lib_path = '%MSVCDir%\ATLMFC\LIB;%MSVCDir%\LIB;%MSVCDir%\PlatformSDK\lib\prerelease;%MSVCDir%\PlatformSDK\lib;%LIB%';
   // check to see if PlatformSDK\lib\prerelease directory exists
   if (file_match('+d +x -p ':+maybe_quote_filename(_replace_envvars('%MSVCDir%\PlatformSDK\lib\prerelease')),1)=="") {
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

/**
 * Set environment vars for Visual Studio 2008, 2010, and higher
 * @return int 0 on success. All other is a failure (probably after a modal 
 *         messgae box)
 * @remarks This code (and its comments) needs to be updated each time a new 
 *          release of Visual Studio makes it into the wild.
 */
static int _set_visualstudio2008orHigher_environment(boolean quiet=false, int major_version=0, _str target_version='')
{
   // This handles Visual Studio 9.0 (VS 2008) and Visual Studio 10.0 (VS 2010)
   if (target_version:=='') {
      if (major_version == 9) {
         target_version = '9.0';
      } else if (major_version == 10) {
         target_version = '10.0';
      } else if (major_version == 11) {
         target_version = '11.0';
      } 
   }

    _str platformSDKVersionString = '';
   if (major_version > 11) {
      _message_box('Need new code for determining Visual Studio ' :+ major_version :+ ' location. [vchack.e]');
   } else if (major_version == 11){
      platformSDKVersionString = "v8.0A";
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
   boolean isExpressEdition = false;
   _str DEVENVDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\":+target_version:+"\\Setup\\VS","","EnvironmentDirectory");
   //say('DEVENVDIR='DEVENVDIR);
   if (DEVENVDIR == '') {
      DEVENVDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VCExpress\\":+target_version,"","InstallDir");
      //say('h2 DEVENVDIR='DEVENVDIR);
      if (DEVENVDIR == '') {
         // Just need msbuild in path for VB and C# project builds. could do better and put compiler in path
         /*if (!quiet) {
            _message_box(nls("EnvironmentDirectory key not found under SOFTWARE\\Microsoft\\VisualStudio\\%s\\Setup\\VS",target_version));
         }
         return(1);*/
      }
      isExpressEdition=true;
   }
   _maybe_strip_filesep(DEVENVDIR);

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

   _str VSCOMMONTOOLSDIR = '';
   if (!isExpressEdition) {
      VSCOMMONTOOLSDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\":+target_version:+"\\Setup\\VS","","VS7CommonBinDir");
      if (VSCOMMONTOOLSDIR == '') {
         // Just need msbuild in path for VB and C# project builds. could do better and put compiler in path
         /*if (!quiet) {
            _message_box(nls("VS7CommonBinDir key not found under SOFTWARE\\Microsoft\\VisualStudio\\%s\\Setup\\VC",target_version));
         }
         return(1);*/
      }
      _maybe_strip_filesep(VSCOMMONTOOLSDIR);
   }

  
   _str SDKINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\":+platformSDKVersionString,"","InstallationFolder");
   if (SDKINSTALLDIR == '') {
      // Just need msbuild in path for VB and C# project builds. could do better and put compiler in path
      /*if (!quiet) {
         _message_box("InstallationFolder key not found under SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\":+platformSDKVersionString);
      }
      return(1);*/
   }
   _maybe_strip_filesep(SDKINSTALLDIR);


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
      _str frameworkDir32 = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7","","FrameworkDir32");
      _str frameworkVer32 = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7","","FrameworkVer32");
      if (frameworkDir32 != '' && frameworkVer32 != '') {
         dotNetFrameworkDirs = frameworkDir32:+frameworkVer32';':+dotNetFrameworkDirs;
      } else {
         dotNetFrameworkDirs = FRAMEWORKINSTALLDIR'\v4.0.30319;':+FRAMEWORKINSTALLDIR'\v4.0.30128;':+dotNetFrameworkDirs; //'v4.0.20506'
      }
   }

   //if(major_version >= 11) {
   //   dotNetFrameworkDirs = FRAMEWORKINSTALLDIR'\v5.0???;':+dotNetFrameworkDirs;
   //} 

   set_env('VSINSTALLDIR',VSINSTALLDIR);
   set_env('VCINSTALLDIR',VCINSTALLDIR);

   // Might need to set LIBPATH too.  Not doing it yet.
#if 1 
   // Set up Path
   //_str PATH=DEVENVDIR';'VCINSTALLDIR'\bin;'VSCOMMONTOOLSDIR';':+dotNetFrameworkDirs :+ SDKINSTALLDIR'\bin;':+ get_env('PATH');
   _str PATH;
   if (VCINSTALLDIR!='' && DEVENVDIR!='') {
       PATH=DEVENVDIR';'VCINSTALLDIR'\bin;';
       // Express edition does not have VSCOMMONTOOLSDIR
       if (VSCOMMONTOOLSDIR!='') {
          PATH=PATH:+VSCOMMONTOOLSDIR';';
       }
       PATH=PATH:+dotNetFrameworkDirs :+ SDKINSTALLDIR'\bin;':+ get_env('PATH');
   } else {
       PATH=dotNetFrameworkDirs :+ SDKINSTALLDIR'\bin;':+ get_env('PATH');
   }
#endif
    
    _str INCLUDE='';
    _str LIB='';
    if (VCINSTALLDIR!='' && SDKINSTALLDIR!='') {
       if (isExpressEdition) {
          INCLUDE=VCINSTALLDIR'\INCLUDE;':+
          SDKINSTALLDIR'\INCLUDE;':+
          get_env('INCLUDE');
          LIB=VCINSTALLDIR'\LIB;':+
             SDKINSTALLDIR'\LIB;':+get_env('LIB');
       } else {
         INCLUDE=VCINSTALLDIR'\ATLMFC\INCLUDE;':+
         VCINSTALLDIR'\INCLUDE;':+
         SDKINSTALLDIR'\INCLUDE;':+
         get_env('INCLUDE');
         LIB=VCINSTALLDIR'\ATLMFC\LIB;':+
            VCINSTALLDIR'\LIB;':+
            SDKINSTALLDIR'\LIB;':+get_env('LIB');
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
   return(0);

}

/**
 * Sets the environment variables for Visual Studio 2012 
 */
_command int set_visualstudio11_environment()
{
   return(_set_visualstudio_environment(false,11));
}

/**
 * Sets the environment variables for Visual Studio 2010 
 */
_command int set_visualstudio10_environment()
{
   return(_set_visualstudio_environment(false,10));
}

/**
 * Sets the environment variables for Visual Studio 2008 
 */
_command int set_visualstudio9_environment()
{
   return(_set_visualstudio_environment(false,9));
}

/**
 * Sets the environment variables for Visual Studio 2005 (Whidbey)
 */
_command int set_visualstudio8_environment()
{
   return(_set_visualstudio_environment(false,8));
}

/**
 * Sets the environment variables for Visual Studio .NET 2003 (Everett)
 */
_command int set_visualstudio7_environment()
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
_command int set_visualstudio_environment(boolean quiet=false,_str version='')
{
   /*
      NOTE: In the future, we may want to make sure the correct visual studio
      compiler is being found based on the visual studio project "version" 
      attribute.
   */
   _restore_origenv();
   _str found_path=path_search('devenv','','P');
   if (found_path:!='') {
      if (!quiet) {
         _message_box('Visual C++ is already setup.  devenv.exe is already in your PATH.');
      }
      _restore_origenv(true,true);
      return(0);
   }

   int major_version=0;
   if (version!='') {
      _str major_version_s='';
      parse version with major_version_s '.' .;
      if (isnumber(major_version_s)) {
         major_version = (int)major_version_s;
      }
   }
   return(_set_visualstudio_environment(quiet,major_version,version));
}
void _init_vcpp()
{
   if (_IsWorkspaceAssociated(_workspace_filename) && _project_name!='') {
      int handle = _ProjectHandle(_project_name);
      _str build_command = _ProjectGet_TargetCmdLine(handle,_ProjectGet_TargetNode(handle,'Build'));
      _str filename=parse_file(build_command,false);
      _str name=_strip_filename(filename,'PE');

      if (file_eq(name,'msdev') || file_eq(name,'devenv') || file_eq(name,'msbuild') ) {
         // Make sure the .NET version of cl is not used (or for that
         // matter, the LIB and INCLUDE environment variables) when
         // switching between VC6 and .NET projects
         _restore_origenv(true,true);

         _str found_file=path_search(filename,"","P");
         if (found_file=="" ) {
            if (file_eq(name,'msdev') ) {
               set_devstudio_environment(true);
            } else {
               //determine which version of Visaul Studio to use
               _str version='';
               _str sln_file=_AbsoluteToWorkspace(_WorkspaceGet_AssociatedFile(gWorkspaceHandle));
               if (sln_file:!='') {
                  version = vstudio_application_version(sln_file);
               }
               set_visualstudio_environment(true,version);
            }
         }
      }
   }
}

/**
 * Calls vstudio_open_file to open the current file in Visual Studio. It will first
 * attempt to connect to a running instance of Visual Studio 2003 or 2005.
 * 
 * @return 1 if successful, 
 *         -2 if the file doesn't exist,
 *         or an error code from vstudio_open_file()
 */
_command int vstudio_edit_file() name_info(','VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY)
{
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
 */
_command int vstudio_open_solution_file() name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT|VSARG2_REQUIRES_MDI)
{
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
      _str fullSlnPath = maybe_quote_filename(workspaceFile);
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

