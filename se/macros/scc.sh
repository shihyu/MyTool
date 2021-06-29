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
#pragma option(metadata,"vc.e")

extern int _SccListProviders();
extern int _SccGetNumberOf32BitSystems();
extern int _SccInit(_str pszProvider);
extern void _SccUninit();
extern void _SccInitOptions();
extern int _SccGetCommandOptions(int,...);
extern int _SccOpenProject(bool iAllowNewProject,_str pszComment,...);
extern _str _SccGetCurProjectInfo(int iOption);
extern _str _SccGetProviderDllName(_str pszProvider);
extern int _SccCloseProject();
extern int _SccProperties(_str pszFilename);
extern int _SccCheckout(var hrefFileList,_str pszComment);
extern int _SccGet(var hrefFileList);
extern int _SccUncheckout(var hrefFileList);
extern int _SccDiff(_str pszFilename);
extern int _SccCheckin(var hrefFileList,_str pszComment);
extern int _SccAdd(var hrefFileList,_str pszComment);
extern int _SccRemove(var hrefFileList,_str pszComment);
extern int _SccRename(_str pszFileame,_str pszNewFilename);
extern int _SccHistory(var hrefFileList);
extern int _SccRunScc(typeless &);
extern int _SccPopulateList(int iCommand,var hrefFileList,...);
extern void _SccGetVersion(_str &hrefMajor,_str &hrefMinor);
extern int _SccQueryInfo(var hrefFileList,var FileStatus);
extern int _SccQueryInfo2(var hrefFileList,var FileStatus,int iMaxNum);
extern int _SccGetProviderCapabilities();
