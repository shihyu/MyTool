////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48455 $
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
#include "autocomplete.sh"
#import "varedit.e"
#import "c.e"
#import "cbrowser.e"
#import "caddmem.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "ccontext.e"
#import "csymbols.e"
#import "cutil.e"
#import "dlgman.e"
#import "env.e"
#import "fsort.e"
#import "javaopts.e"
#import "jrefactor.e"
#import "listproc.e"
#import "main.e"
#import "projconv.e"
#import "refactor.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "util.e"
#import "wkspace.e"
#import "se/tags/TaggingGuard.e"
#require "sc/lang/IComparable.e"
#endregion

/*
This module contains all the wrapper functions and Context Tagging(R)
API functions for languages that are like C/C++ syntaticly, including:

      Java
      IDL
      JavaScript
      CFScript
      C# (C-Sharp)
      PHP
      Slick-C

Also, all hook functions for Perl and Python that use the C/C++ context
tagging code are found in perl.e and python.e, respectively.
*/

/**
 * This def-var contains a list of preprocessing option flags for 
 * C# code.  These should correspond to the flags that you pass to 
 * your C# compiler using -D. 
 *  
 * @default "NET_2_0=1" 
 *  
 * @category Configuration_Variables 
 */
_str def_cs_preprocessing_options="NET_2_0=1";

/**
 * Activates Java file editing mode.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void java_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('java');
}
_command void csharp_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('cs');
}

/**
 * @see _c_generate_function
 */
int _java_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                                   _str (&header_list)[], _str function_body,
                                   int indent_col, int begin_col,
                                   boolean make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list, function_body,
                                      indent_col,begin_col,make_proto);
}
/**
 * @see _c_generate_function
 */
int _cs_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                                 _str (&header_list)[],_str function_body,
                                 int indent_col, int begin_col,
                                 boolean make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}
/**
 * @see _c_generate_function
 */
int _js_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                                 _str (&header_list)[],_str function_body,
                                 int indent_col, int begin_col,
                                 boolean make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}
/**
 * @see _c_generate_function
 */
int _phpscript_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                                  _str (&header_list)[],_str function_body,
                                  int indent_col, int begin_col,
                                  boolean make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}
/**
 * @see _c_generate_function
 */
int _idl_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                                 _str (&header_list)[],_str function_body,
                                 int indent_col, int begin_col,
                                 boolean make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}
/**
 * @see _c_generate_function
 */
int _e_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                                _str (&header_list)[],_str function_body,
                                int indent_col, int begin_col,
                                boolean make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}


/**
 * @see _c_get_expression_pos
 */
int _e_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count);
}

/**
 * @see _c_get_expression_pos
 */
int _cs_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count);
}

/**
 * @see _c_get_expression_pos
 */
int _java_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count);
}

/**
 * @see _c_get_expression_pos
 */
int _rul_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count);
}

/**
 * @see _c_get_expression_pos
 */
int _phpscript_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count);
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */

int _e_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _java_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _cs_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   int status=_c_get_expression_info(PossibleOperator, info, visited, depth);

   // compensate for @ keywords
   if (substr(info.lastid,1,1)=='@') {
      info.lastid=substr(info.lastid,2);
      info.lastidstart_col++;
      info.lastidstart_offset++;
   }
   return(status);
}


/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _cfscript_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                                  VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _phpscript_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _idl_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

//////////////////////////////////////////////////////////////////////////
static _str gCancelledCompiler='';
void _prjopen_java_util()
{
   gCancelledCompiler='';
}

/**
 * @see ext_MaybeRecycleTagFIle
 */
int _java_MaybeBuildTagFile(int &tfindex)
{
   // Find the active "Java" compiler tag file
   _str compiler_name = refactor_get_active_config_name(_ProjectHandle());
   //say("_c_MaybeBuildTagFile: name="compiler_name);
   if (compiler_name != '' && compiler_name != gCancelledCompiler) {
      // put together the file name
      _str compilerTagFile=_tagfiles_path():+compiler_name:+TAG_FILE_EXT;
      if (!file_exists(compilerTagFile)) {
         useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
         int status = refactor_build_compiler_tagfile(compiler_name, 'java', false, useThread);
         if (status == COMMAND_CANCELLED_RC) {
            message("You pressed cancel.  You will have to build the tag file manually.");
            gCancelledCompiler = compiler_name;
         } else if (status == 0) {
            gCancelledCompiler = '';
         }
      }
   }

   // maybe we can recycle tag file(s)
   _str tagfilename='';
   if (p_embedded) {
      ext_MaybeBuildTagFile(tfindex,"java","jsp","JSP Implicit Objects");
   }

#if __UNIX__
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,"java","ujava")) {
      return(0);
   }
#else
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,"java","java")) {
      return(0);
   }
#endif
   // recycling didn't work, might have to build tag files
   tfindex=0;
   return(0);
}

/**
 * @see ext_MaybeBuildTagFIle
 */
int _cfscript_MaybeBuildTagFile(int &tfindex)
{
   return ext_MaybeBuildTagFile(tfindex,'cfscript','cfscript','CFScript Builtins');
}

/**
 * Helper method for reading property values from an Xcode SDK 
 * SDKSettings.plist file 
 * @param propertyName Property name to search for, e.g. 
 *                     "DisplayName"
 * @param SDKRoot The SDK base directory, e.g. 
 *                /Developer/SDKs/MacOSX10.6.sdk
 * 
 * @return _str The value associated with propertyName
 */
static _str _xcode_GetSDKPropertyListString(_str propertyName, _str SDKRoot)
{
   _str settingsPlistPath = concat_path_and_file(SDKRoot, 'SDKSettings.plist');
   _str propertyValue = '';
   int saveWindowId = p_window_id;
   int plist_view_id=0;
   int view_id=0;
   int status=_open_temp_view(settingsPlistPath,plist_view_id,view_id);
   if (!status) {
      // Regular Expression (unix): <key>PropertyName</key>\n\:b<string>(.+)</string>
      // SDK Name in match group #1
      _str searchRegex = '<key>'propertyName'</key>\n\:b<string>(.+)</string>';
      if (plist_view_id.search( searchRegex, "+u@") == 0) {
         propertyValue = plist_view_id.get_text(match_length('1'), match_length('S1'));
      }
      _delete_temp_view(plist_view_id);
   }
   p_window_id = saveWindowId;
   return propertyValue;
}


/**
 * Helper method for getXcodeSDKs, to get the friendly name for 
 * an installed Mac SDK.
 * @remarks This method looks for an SDKSettings.plist file 
 *          under SDKRoot, and attempts to determine the value
 *          of the DisplayName key.
 * @param SDKRoot Full path to SDK directory, e.g. 
 *                /Developer/SDKs/MacOSX10.5.sdk/
 * @return _str SDK display name, e.g. 'Mac OS X 10.6' or 'iOS 
 *         5.0'
 */
static _str _xcode_GetSDKDisplayName(_str SDKRoot){

   _str sdkName = _xcode_GetSDKPropertyListString('DisplayName',SDKRoot);
   if(sdkName == '') {
       // Just use the SDK directory name (without the .sdk extension)
       // as a fallback name in case the .plist file can't be read
       _str sdkDir = strip(SDKRoot, 'T', FILESEP);
       sdkName = _strip_filename(sdkDir,'PE');
   }
   return sdkName;
}

/**
 * Helper method for getXcodeSDKs, to get the Canonical name for
 * an installed Mac SDK. This canonical name is what is passed 
 * as the -sdk argument to xcodebuild. 
 * @remarks This method looks for an SDKSettings.plist file 
 *          under SDKRoot, and attempts to determine the value
 *          of the CanonicalName key.
 * @param SDKRoot Full path to SDK directory, e.g. 
 *                /Developer/SDKs/MacOSX10.6.sdk/
 * @return _str SDK canonical name, e.g. 'iphonesimulator3.2' or 
 *         'macosx10.6'
 */
static _str _xcode_GetSDKCanonicalName(_str SDKRoot) {
    _str canonName = _xcode_GetSDKPropertyListString('CanonicalName',SDKRoot);
    return canonName;
}

/**
 * Returns the current Developer directory used by the Xcode 
 * command line tools. Most of the time this is /Developer.
 */
static _str _xcode_GetDeveloperRoot() {
    _str xcodeDevRoot = '';
    _str settingsFile = "/usr/share/xcode-select/xcode_dir_path";
    int saveWindowId = p_window_id;
    int settings_view_id = 0;
    int orig_view_id = 0;
    int status = _open_temp_view(settingsFile, settings_view_id, orig_view_id);
    if(!status) {
        settings_view_id.get_line(xcodeDevRoot);
        _delete_temp_view(settings_view_id);
    }
    if(xcodeDevRoot == '') {
        xcodeDevRoot = "/Developer";
    }
    p_window_id = saveWindowId;
    return xcodeDevRoot;
}


/**
 * Helper method for getXcodeSDKs. 
 * @remarks Looks under baseDir (e.g. /Developer) for 
 *          ./SDKs/?.sdk child directories
 * @param developerDir Base path to search under. Usually 
 *                     /Developer.
 * @param sdkPaths Output array 
 */
static void _xcode_FindSDKsUnderPath(_str developerDir, _str (&sdkPaths)[]){
   _str wildcardSpec = concat_path_and_file(developerDir, 'SDKs/*.sdk');
   _str wildcardSearch = '+D +X 'wildcardSpec;
   _str path=file_match(wildcardSearch,1);
   while (path:!='') {
      sdkPaths[sdkPaths._length()]=path;
      path=file_match(wildcardSearch,0);
   }
}
        
/**
 * Helper method for getXcodeSDKs
 * @remarks Finds all of the .platform directories under 
 *          <DeveloperDir>/Platforms. These contain device
 *          platforms, most notably for the iPhone and iPhone
 *          Simulator.
 * @param developerDir Base path to search under. Usually 
 *                     /Developer.
 * @param platforms Output array
 */
static void _xcode_GetPlatforms(_str developerDir, _str (&platforms)[]){
   _str wildcardSpec = concat_path_and_file(developerDir,"Platforms/*.platform");
   _str wildcardSearch = '+D +X 'wildcardSpec;
   _str path=file_match(wildcardSearch,1);
   while (path:!='') {
      platforms[platforms._length()]=path;
      path=file_match(wildcardSearch,0);
   }
}

#define MAC_FRAMEWORKS_SUBDIR "System/Library/Frameworks/"

/**
 * Gets all of the SDK root directories on Mac OS X 
 * @remarks SDKs are found in the following locations: <br>
 *          /System/Library/Frameworks <br>
 *          <DeveloperDir>/SDKs/??.sdk/System/Library/Frameworks
 *          <br> 
 *          <DeveloperDir>/Platforms/??.platform/Developer/SDKs/??.sdk/System/Library/Frameworks
 *          <br>The <DeveloperDir> is usually /Developer, and is
 *          set up by the xcode-select tool.
 * @param allSdkInfo Output array
 */
void getXcodeSDKs(XcodeSDKInfo (&allSdkInfo)[]){
   // Default "Pseudo-SDK" for the always-present in the
   // /System/Library/Frameworks directory
   _str SDKRoot = '/';
   XcodeSDKInfo defaultInfo;
   defaultInfo.name = "Default (/System/Library/Frameworks)";
   defaultInfo.canonicalName = '';
   defaultInfo.sdk_root = SDKRoot;
   defaultInfo.framework_root = defaultInfo.sdk_root :+ MAC_FRAMEWORKS_SUBDIR;
   allSdkInfo[allSdkInfo._length()] = defaultInfo;

   // Find all default SDKs under /Developer/SDKs (or whatever xcode-select has set up
   // the /Developer directory to be)
   // For example, in Xcode 3.2 on Mac 10.6, there is an SDK for Leopard 10.5 and 
   // an SDK for Snow Leopard 10.6
   _str DefaultSDKs[];
   _str xcodeDevRoot = _xcode_GetDeveloperRoot();
   _xcode_FindSDKsUnderPath(xcodeDevRoot, DefaultSDKs);

   // Walk all the default SDKs and get their proper names. Add them
   // to the aggregate listing   
   int _defSdk_index;
   for(_defSdk_index=0; _defSdk_index < DefaultSDKs._length(); _defSdk_index++) {
      XcodeSDKInfo info;
      info.sdk_root = DefaultSDKs[_defSdk_index];
      info.name = _xcode_GetSDKDisplayName(info.sdk_root);
      info.canonicalName = _xcode_GetSDKCanonicalName(info.sdk_root);
      info.framework_root = info.sdk_root :+ MAC_FRAMEWORKS_SUBDIR;
      allSdkInfo[allSdkInfo._length()] = info;
   }

   // Get list of platform directories. These are most likely iPhone platforms
   _str platforms[];
   _xcode_GetPlatforms(xcodeDevRoot,platforms);
   int _platform_index;
   for(_platform_index=0; _platform_index < platforms._length(); _platform_index++) {
      // Get the SDKs under each platform
      _str platformSDKs[];
      _str platformDeveloperDir = concat_path_and_file(platforms[_platform_index],"Developer");
      _xcode_FindSDKsUnderPath(platformDeveloperDir, platformSDKs);

      // Get the frameworks under each platform SDK
      int _psdk_index;
      for(_psdk_index = 0; _psdk_index < platformSDKs._length(); _psdk_index++) {
         XcodeSDKInfo psdkinfo;
         psdkinfo.sdk_root =platformSDKs[_psdk_index];
         psdkinfo.name = _xcode_GetSDKDisplayName(psdkinfo.sdk_root);
         psdkinfo.canonicalName = _xcode_GetSDKCanonicalName(psdkinfo.sdk_root);
         psdkinfo.framework_root = psdkinfo.sdk_root :+ MAC_FRAMEWORKS_SUBDIR;
         allSdkInfo[allSdkInfo._length()] = psdkinfo;
      }
   }

}

#if !__UNIX__
static int getDotNetFrameworkPathForVersion(_str csharp_version, DotNetFrameworkInfo &info)
{
   // initialize info structure
   info.name = ".NET Framework";
   if (csharp_version != '') strappend(info.name,' 'csharp_version);
   info.version = "";
   info.maketags_args = "";
   info.install_dir = "";
   info.sdk_dir = "";
   info.display_name = "";

   // v3.0 and v3.5 are registered differently (and easier)
   if (csharp_version == "v3.0" || csharp_version == "v3.5") {
       _str threedot_key="SOFTWARE\\Microsoft\\.NETFramework\\AssemblyFolders\\":+csharp_version;
       _str veethreedir;
       int status = _ntRegFindValue(HKEY_LOCAL_MACHINE, threedot_key, "All Assemblies In", veethreedir);
       if (status) {
          // If no registry key, use %PROGRAMFILES%\Reference Assemblies\Microsoft\Framework
          ntGetSpecialFolderPath(veethreedir, CSIDL_PROGRAM_FILES);
          _maybe_append_filesep(veethreedir);
          veethreedir = veethreedir :+ "Reference Assemblies\\Microsoft\\Framework\\" :+ csharp_version;
       }

       if (path_exists(veethreedir) == false)
       {
          return STRING_NOT_FOUND_RC;
       }

       info.version = csharp_version;
       info.install_dir = veethreedir;
       return 0;
   }

   if (csharp_version == "v4.0") {
      // The .NET Framework 4 installer writes registry keys when installation is successful. You can 
      // test whether the .NET Framework 4 is installed by checking the registry keys listed in the following table.
      // Full     HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full      Name: Install  Type: DWORD Data: 1
      // Client   HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client    Name: Install  Type: DWORD Data: 1
      _str key = "SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full";
      _str install;
      int status = _ntRegFindValue(HKEY_LOCAL_MACHINE, key, "Install", install);
      if (status) {
         key = "SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Client";
         status = _ntRegFindValue(HKEY_LOCAL_MACHINE, key, "Install", install);
      }
      if (status) {
         return STRING_NOT_FOUND_RC;
      }
      _str veefourdir;
      ntGetSpecialFolderPath(veefourdir, CSIDL_PROGRAM_FILES);
      _maybe_append_filesep(veefourdir);
      veefourdir = veefourdir :+ "Reference Assemblies\\Microsoft\\Framework\\.NETFramework\\" :+ csharp_version;
      info.version = 'v4.0.30319';
      info.install_dir = veefourdir;
   }

   if (csharp_version == "v4.5") {
      // The .NET Framework 4.5 RC installer writes registry keys when installation is successful.
      // You can test whether the .NET Framework 4.5 RC is installed by checking the 
      // HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full folder in the registry
      // for a DWORD value named Release. The existence of this key indicates that the .NET Framework 4.5 RC
      // has been installed on that computer.
      _str key = "SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full";
      _str install;
      int status = _ntRegFindValue(HKEY_LOCAL_MACHINE, key, "Release", install);
      if (status) {
         return STRING_NOT_FOUND_RC;
      }

      _str veefourdir;
      ntGetSpecialFolderPath(veefourdir, CSIDL_PROGRAM_FILES);
      _maybe_append_filesep(veefourdir);
      veefourdir = veefourdir :+ "Reference Assemblies\\Microsoft\\Framework\\.NETFramework\\" :+ csharp_version;
      info.version = 'v4.5';
      info.install_dir = veefourdir;

      // 4.5 installs on top of v4.0, impersonate 4.0 from here out
      csharp_version = 'v4.0';
   }

   // get the Frameworks SDK directory from registry
   // This is optional
   _str csharp_key = "SOFTWARE\\Microsoft\\.NETFramework";
   int status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                                csharp_key, "sdkInstallRoot":+csharp_version, info.sdk_dir);

   // get basic frameworks directory from registry
   _str csharp_dir="";
   status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                            csharp_key, "InstallRoot", csharp_dir);
   if (status) {
      // If no registry key, use %WINDIR%\Microsoft.NET\Framework
      ntGetSpecialFolderPath(csharp_dir, CSIDL_WINDOWS);
      _maybe_append_filesep(csharp_dir);
      csharp_dir = csharp_dir :+ "Microsoft.NET\\Framework\\";
   }

   // make sure the directory ends in a FILESEP
   if (last_char(csharp_dir)!=FILESEP) {
      csharp_dir=csharp_dir:+FILESEP;
   }

   // expecting a particular version number
   if (csharp_version != "") {
      // search for the build number
      _str csharp_build_number='';
      _str csharp_build_range='';
      csharp_key="SOFTWARE\\Microsoft\\.NETFramework\\policy\\":+csharp_version;
      status=_ntRegFindFirstValue(HKEY_LOCAL_MACHINE,
                                  csharp_key,csharp_build_number,csharp_build_range,1);
      while (!status && !isnumber(csharp_build_number)) {
         status=_ntRegFindFirstValue(HKEY_LOCAL_MACHINE,
                                     csharp_key,csharp_build_number,csharp_build_range,0);
      }

      // now return the version directory
      if (!status) {
         info.version = csharp_version:+".":+csharp_build_number;
         info.install_dir = csharp_dir:+csharp_version:+".":+csharp_build_number;
         return 0;
      }
   }

   // looking for non-specific installed version
   if (csharp_version == '') {
      csharp_version = _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\NET Framework Setup\\Product", "", "Version");
      if (csharp_version != '') {
         info.version = csharp_version;
         info.install_dir = csharp_dir:+csharp_version;
         return 0;
      }
   }

   // desparate, just try hard-coded values
   if (csharp_version=='v1.0' && file_exists(csharp_dir:+"v1.0.3705":+FILESEP:+"mscorlib.dll")) {
      info.version = "v1.0.3705";
      info.install_dir = csharp_dir:+"v1.0.3705";
      return 0;
   }
   if (csharp_version=='v1.1' && file_exists(csharp_dir:+"v1.1.4322":+FILESEP:+"mscorlib.dll")) {
      info.version = "v1.1.4322";
      info.install_dir = csharp_dir:+"v1.1.4322";
      return 0;
   }
   if (csharp_version=='v2.0' && file_exists(csharp_dir:+"v2.0.50727":+FILESEP:+"mscorlib.dll")) {
      info.version = "v2.0.50727";
      info.install_dir = csharp_dir:+"v2.0.50727";
      return 0;
   }
   if (csharp_version=='v2.0' && file_exists(csharp_dir:+"v2.0.50215":+FILESEP:+"mscorlib.dll")) {
      info.version = "v2.0.50215";
      info.install_dir = csharp_dir:+"v2.0.50215";
      return 0;
   }

   // no luck
   return STRING_NOT_FOUND_RC;
}

#endif

_str getDotNetFrameworkAutotagPaths(DotNetFrameworkInfo &info)
{
   // already have maketag args set?
   if (info.maketags_args != '') {
      return info.maketags_args;
   }

   // .NET framework 1.1 and 2.0 use pretty standard tagging where
   // we look for System*.dll and System*.xml

   // .NET 3.0 and 3.5 are a bit strange. They both are built
   // on top of 2.0, and they are a little lax in the DLL naming, so
   // be basically have to include *.dll

   // check that mscorlib.dll exists, if it is not there, we have a problem
   _str csharp_path="";
   _str frameworkDir = strip(info.install_dir, "T", FILESEP);
   _str corlib_path=frameworkDir:+FILESEP:+"mscorlib.dll";
   if (file_exists(corlib_path)) {
      csharp_path=maybe_quote_filename(corlib_path);
   }

   // The released .NET framework also has mscorcfg.dll which may be tagged
   _str cfg_path=frameworkDir:+FILESEP:+"mscorcfg.dll";
   if (file_exists(cfg_path)) {
      csharp_path=csharp_path" "maybe_quote_filename(cfg_path);
   }

   // The released .NET framework also has mscorwks.dll which may be tagged
   _str wks_path=frameworkDir:+FILESEP:+"mscorwks.dll";
   if (file_exists(wks_path)) {
      csharp_path=csharp_path" "maybe_quote_filename(wks_path);
   }

   // The released .NET framework also has System.*.dll which needs to be tagged
   if (file_exists(frameworkDir:+FILESEP:+"System.dll")) {
      _str system_path=frameworkDir:+FILESEP:+"System.*.dll";
      _str system_path2=frameworkDir:+FILESEP:+"System.dll";
      csharp_path = csharp_path" "maybe_quote_filename(system_path)" "maybe_quote_filename(system_path2);
   }

   // Need to also tag any Microsoft.*.dlls
   _str msftPath = frameworkDir:+FILESEP:+"Microsoft.*.dll";
   csharp_path = csharp_path" "maybe_quote_filename(msftPath);

   // The released .NET framework SDK also has mscorcfg.dll which may be tagged
   if (info.sdk_dir != '') {
      _str sdkDir = strip(info.sdk_dir, "T", FILESEP);
      cfg_path = sdkDir:+FILESEP:+"bin":+FILESEP:+"mscorcfg.dll";
      if (file_exists(cfg_path)) {
         csharp_path=csharp_path" "maybe_quote_filename(cfg_path);
      }
   }

   // None of the key components, then skip this one
   if (csharp_path == "") {
      return "";
   }

   // get XML files from 32-bit directories if they are not located
   // in this directory
   if (!file_exists(frameworkDir:+FILESEP:+"mscorlib.xml")) {
      frameworkDir = stranslate(frameworkDir, "Framework", "Framework64", "i");
   }

   // Also attempt to tag any XML files in the info.install_dir
   _str xml_path = frameworkDir:+FILESEP:+"mscorlib.xml";
   csharp_path=csharp_path" "maybe_quote_filename(xml_path);
   xml_path=frameworkDir:+FILESEP:+"Microsoft.*.xml";
   csharp_path=csharp_path" "maybe_quote_filename(xml_path);
   xml_path=frameworkDir:+FILESEP:+"System.*.xml";
   csharp_path=csharp_path" "maybe_quote_filename(xml_path);
   xml_path=frameworkDir:+FILESEP:+"System.xml";
   csharp_path=csharp_path" "maybe_quote_filename(xml_path);

   // now save the wild cards for this framework version
   return csharp_path;
}

static _str getDotNetAutotagsArgsForThreeOrFour(_str dotnetFrameworkDir)
{
   system_path_dll := dotnetFrameworkDir:+FILESEP:+"*.dll";
   system_path_xml := dotnetFrameworkDir:+FILESEP:+"*.xml";
   if (!file_exists(dotnetFrameworkDir:+FILESEP:+"mscorlib.xml")) {
      system_path_xml = stranslate(system_path_xml, "Framework", "Framework64", "i");
   }
   exclude_path := dotnetFrameworkDir:+FILESEP:+"SetupCache":+FILESEP;
   return "-E "maybe_quote_filename(exclude_path)" "maybe_quote_filename(system_path_dll)" "maybe_quote_filename(system_path_xml);
}
class Sortable_DotNetFrameworkInfo: sc.lang.IComparable {
   _str m_version;
   DotNetFrameworkInfo m_info;
   Sortable_DotNetFrameworkInfo(_str version='',DotNetFrameworkInfo &info=null) {
      m_version=version;
      m_info=info;
   }
   int compare(sc.lang.IComparable &rhs) {
      if (m_version>((Sortable_DotNetFrameworkInfo)rhs).m_version) {
         return 1;
      }
      if (m_version==((Sortable_DotNetFrameworkInfo)rhs).m_version) {
         return 0;
      }
      return -1;

   }

};
/**
 * Scans the registry [or install dirs on Unix] for version of
 * the .NET Framework, or Mono.   Returns results in three parallel
 * arrays (name, path, version).
 * 
 * @param framework_name   Name of this framework version
 * @param framework_path   Path containing mscorlib.dll
 * @parma framework_wild   Wildcard paths to tag all framework files
 * 
 * @return 0 on success, <0 if no frameworks are found
 */
int getDotNetFrameworkPaths(DotNetFrameworkInfo (&frameworks)[])
{
   DotNetFrameworkInfo info;

#if __UNIX__
   _str csharp_dir;
   if (_isMac()) {
      _str unity_mono_path='/Applications/Unity/MonoDevelop.app/Contents/Frameworks/Mono.framework/Libraries/mono';
      csharp_dir='/Library/Frameworks/Mono.framework/Libraries/mono';

      if (file_exists(unity_mono_path)) {
         csharp_dir=unity_mono_path;
      }
   } else {
      // Tested on ubuntu after installing monodevelop
      csharp_dir='/usr/lib/mono';
   }
   {
      // Unity has it's own install of Mono.


      int NewViewId=0;
      int orig_view_id=_create_temp_view(NewViewId);
      
      insert_file_list(csharp_dir:+ '\*.* +D -V');
      Sortable_DotNetFrameworkInfo list[];
      
      fsort('n');
      top();up();
      for (;;) {
         if (down()) break;
         get_line(auto versionDir);
         versionDir = strip(versionDir);
         // ignore hidden files and directories
         if( pos('^[^.].*\/$', versionDir, 1, 'U') != 0 ) {
            // strip trailing /
            if( pos(FILESEP:+'$',versionDir,1,'U') ) {
               versionDir = substr(versionDir, 1, length(versionDir)-1);
            }

            _str csharp_path_chk=csharp_dir:+FILESEP:+versionDir:+FILESEP:+"mscorlib.dll";
            if( file_exists(csharp_path_chk) ) {
               _str system_path  = csharp_dir:+FILESEP:+versionDir:+FILESEP:+"System.*.dll";
               _str system_path2 = csharp_dir:+FILESEP:+versionDir:+FILESEP:+"System.dll";
               _str csharp_path = csharp_path_chk:+" ":+maybe_quote_filename(system_path):+" ":+maybe_quote_filename(system_path2);

               info.name = "Mono.framework "versionDir;
               info.version = versionDir;
               info.install_dir = csharp_dir:+FILESEP:+versionDir;
               info.sdk_dir = "";
               info.maketags_args = csharp_path;

               Sortable_DotNetFrameworkInfo item(versionDir,info);
               
               list[list._length()]=item;

            }
         }
      }
      list._sort();
      //debugvar(list);
      int i;
      for (i=0;i<list._length();++i) {
         frameworks[frameworks._length()] = list[i].m_info;
      }
      
      p_window_id=orig_view_id;

   }
#if 0
    else {
      // For now, just look in "/usr/local/lib/" for corlib.dll
      // check that mscorlib.dll exists, if it is not there, we have a problem
      _str csharp_dir="/usr/local/lib";
      csharp_path=csharp_dir:+FILESEP:+"corlib.dll";
      if (!file_exists(csharp_path)) {
         return(1);
      }
      csharp_path=csharp_dir:+FILESEP:+"*.dll";

      info.name = "Mono";
      info.version = "";
      info.install_dir = csharp_dir;
      info.sdk_dir = "";
      info.maketags_args = csharp_path;
      frameworks[frameworks._length()] = info;
   }
#endif

#else

   // locate the C# runtime libraries
   int status;
   _str sdk_dir='';
   _str csharp_dir='';
   _str csharp_version='';
   _str csharp_key="SOFTWARE\\Microsoft\\.NETFramework";

   // try for .NET Framework SDK
   if (getDotNetFrameworkPathForVersion("", info) == 0) {
      frameworks[frameworks._length()] = info;
   }

   // try for .NET Framework 1.0 (I don't think this ever existed)
   if (getDotNetFrameworkPathForVersion("v1.0", info) == 0) {
      frameworks[frameworks._length()] = info;
   }

   // try for .NET Framework 1.1
   if (getDotNetFrameworkPathForVersion("v1.1", info) == 0) {
      frameworks[frameworks._length()] = info;
   }

   // try for .NET Framework 2.0
   int dotNetTwoIndex = -1;
   _str dotNetTwoFullVersion;
   if (getDotNetFrameworkPathForVersion("v2.0", info) == 0) {
      dotNetTwoIndex = frameworks._length();
      frameworks[frameworks._length()] = info;
      dotNetTwoFullVersion = info.version;
   }

   // If we have v2.0, we may also have 3.0 and 3.5
   if(dotNetTwoIndex > -1) {
      int dotNetThreeZeroIndex = -1;
      int dotNetThreeFiveIndex = -1;
      int dotNetFourZeroIndex = -1;

      if(getDotNetFrameworkPathForVersion("v3.0", info) == 0) {
         dotNetThreeZeroIndex = frameworks._length();
         frameworks[dotNetThreeZeroIndex] = info;
         frameworks[dotNetThreeZeroIndex].display_name = "v3.0 (includes ":+dotNetTwoFullVersion:+")";
      }

      if(getDotNetFrameworkPathForVersion("v3.5", info) == 0) {
         dotNetThreeFiveIndex = frameworks._length();
         frameworks[dotNetThreeFiveIndex] = info;
         frameworks[dotNetThreeFiveIndex].display_name = "v3.5 (includes v3.0 and ":+dotNetTwoFullVersion:+")";
      }

      if(getDotNetFrameworkPathForVersion("v4.5", info) == 0) {
         dotNetFourZeroIndex = frameworks._length();
         frameworks[dotNetFourZeroIndex] = info;
         if (dotNetThreeZeroIndex > 0) {
            frameworks[dotNetFourZeroIndex].display_name = "v4.5 (includes v3.0)";
         } else {
            frameworks[dotNetFourZeroIndex].display_name = "v4.5 (includes ":+dotNetTwoFullVersion:+")";
         }
      } else if(getDotNetFrameworkPathForVersion("v4.0", info) == 0) {
         dotNetFourZeroIndex = frameworks._length();
         frameworks[dotNetFourZeroIndex] = info;
         if (dotNetThreeZeroIndex > 0) {
            frameworks[dotNetFourZeroIndex].display_name = "v4.0 (includes v3.0)";
         } else {
            frameworks[dotNetFourZeroIndex].display_name = "v4.0 (includes ":+dotNetTwoFullVersion:+")";
         }
      }

      // If we've got a v3.0, v3.5, or v4.0 then build up the "maketags" arguments right now
      // for version v2.0, and then append the 3.0/3.5/4.0 directories to it.
      if(dotNetThreeFiveIndex > 0 || dotNetThreeZeroIndex > 0 || dotNetFourZeroIndex > 0) {

         // Build the autotag args for .NET 2.0
         _str autotagArgsForTwo = getDotNetFrameworkAutotagPaths(frameworks[dotNetTwoIndex]);
         frameworks[dotNetTwoIndex].maketags_args = autotagArgsForTwo;
         exclude_xml  := "-EFrameworkList.xml -EWinFXList.xml -EVSList.xml -EGroupedProviders.xml -ENetFx*.xml";

         // Append the v3.0-specific wildcards to the v2.0 args
         _str autotagArgsForThreeZero = "";
         if(dotNetThreeZeroIndex > 0) {
            dotNetThreeDir := strip(frameworks[dotNetThreeZeroIndex].install_dir, "T", FILESEP);
            autotagArgsForThreeZero = getDotNetAutotagsArgsForThreeOrFour(dotNetThreeDir);
            frameworks[dotNetThreeZeroIndex].maketags_args = exclude_xml" "autotagArgsForTwo" "autotagArgsForThreeZero;
         }

         // Append the v3.5-specific wildcards to the v3.0 args
         // (or the v2.0 args if somehow 3.0 is not installed)
         _str autotagArgsForThreeFive = "";
         if(dotNetThreeFiveIndex > 0) {
            dotNetThreeFiveDir := strip(frameworks[dotNetThreeFiveIndex].install_dir, "T", FILESEP);
            autotagArgsForThreeFive = getDotNetAutotagsArgsForThreeOrFour(dotNetThreeFiveDir);
            frameworks[dotNetThreeFiveIndex].maketags_args = exclude_xml" "autotagArgsForTwo" "autotagArgsForThreeZero" "autotagArgsForThreeFive;
         }

         // Append the v4.0-specific wildcards to the v3.0 args
         // (or the v2.0 args if somehow 3.0 is not installed)
         // We do *not* add the v3.5 paths, as v4.0 *replaces* v3.5,
         // but like v3.5, it includes 3.0 and 2.x
         _str autotagArgsForFourZero = "";
         if(dotNetFourZeroIndex > 0) {
            dotNetFourZeroDir := strip(frameworks[dotNetFourZeroIndex].install_dir, "T", FILESEP);
            autotagArgsForFourZero = getDotNetAutotagsArgsForThreeOrFour(dotNetFourZeroDir);
            frameworks[dotNetFourZeroIndex].maketags_args = exclude_xml" "autotagArgsForThreeZero" "autotagArgsForFourZero;
         }
      }
      
   }

   // try the oldest of old .NET Beta version
   csharp_key="SOFTWARE\\Microsoft\\ComPlus";
   status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                            csharp_key,"InstallRoot", csharp_dir);
   if (!status) {
      if (last_char(csharp_dir)!=FILESEP) {
         csharp_dir=csharp_dir:+FILESEP;
      }
      status=_ntRegFindValue(HKEY_LOCAL_MACHINE,
                             csharp_key,"Version", csharp_version);
      if (status) csharp_version = "v1.0.3705";
      info.name = ".NET Framework 1.0 Beta";
      info.version = csharp_version;
      info.install_dir = csharp_dir:+csharp_version;
      info.sdk_dir = "";
      info.maketags_args = getDotNetFrameworkAutotagPaths(info);
      frameworks[frameworks._length()] = info;
   }

   // make sure all paths have maketags args
   int i,n = frameworks._length();
   for (i=0; i<n; ++i) {

      // already have a path set up?
      if (frameworks[i].maketags_args != "") {
         continue;
      }

      _str csharp_path = getDotNetFrameworkAutotagPaths(frameworks[i]);
      if (csharp_path == "") {
         frameworks._deleteel(i);
         --i; --n;
         continue;
      }

      // now save the wild cards for this framework version
      frameworks[i].maketags_args = csharp_path;
   }

#endif

   return 0;
}

/**
 * Build a tag file for C#.  Looks in the
 * registry on Windows to find the installation
 * path for the NGWSSDK distribution of the C# / .NET
 * libarary.
 *
 * @param tfindex Set to the index of the extension specific
 *                tag file for C#.
 * @return 0 on success, nonzero on error
 */
int _cs_MaybeBuildTagFile(int &tfindex)
{
   int status=_MaybeBuildTagFile_dotnet(tfindex);

   int tfindex2;
   int status2=_MaybeBuildTagFile_unity3d(tfindex2);
   //say('status='status' tf='tfindex' 2='status2' tf2='tfindex2);

   if (!status) return status;

   tfindex=tfindex2;
   return status2;

}
static int _MaybeBuildTagFile_dotnet(int &tfindex) {
   // if they have an old csharp.vtg, remove it
   _str ext='cs';
   _str tagfilename = absolute(_tagfiles_path():+"csharp":+TAG_FILE_EXT);
   remove_lang_tagfile("cs ":+maybe_quote_filename(tagfilename));

   // maybe we can recycle tag file(s)
   tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"dotnet")) {
      return(0);
   }

   DotNetFrameworkInfo frameworks[];
   getDotNetFrameworkPaths(frameworks);

   if (frameworks._length() == 0) {
      return PATH_NOT_FOUND_RC;
   }

   _str dotnet_path=frameworks[frameworks._length()-1].maketags_args;
   if (dotnet_path=='') {
      return PATH_NOT_FOUND_RC;
   }

   // The user does not have an extension specific tag file for C#
   _str extra_file=ext_builtins_path(ext,'dotnet');
   return ext_BuildTagFile(tfindex,tagfilename,ext,".NET Framework",
                           false,dotnet_path,extra_file);
}
static int _MaybeBuildTagFile_unity3d(int &tfindex) 
{
   _str ext='cs';
   _str tagfilename = absolute(_tagfiles_path():+"unity":+TAG_FILE_EXT);

   // maybe we can recycle tag file(s)
   tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"unity")) {
      return(0);
   }

   AUTOTAG_BUILD_INFO autotagInfo;
   int status=_getAutoTagInfo_unity3d(autotagInfo);

   if (status) {
      return PATH_NOT_FOUND_RC;
   }

   _str dotnet_path=autotagInfo.wildcardOptions;
   if (dotnet_path=='') {
      return PATH_NOT_FOUND_RC;
   }

   // The user does not have an extension specific tag file for C#
   _str extra_file=ext_builtins_path(ext,'unity');
   return ext_BuildTagFile(tfindex,tagfilename,ext,"Unity",
                           false,dotnet_path,extra_file);
}
/**
 * Build a tag file for J#.  Looks in the
 * registry on Windows to find the installation
 * path for the NGWSSDK distribution of the J# / .NET libarary.
 *
 * @param tfindex Set to the index of the extension specific
 *                tag file for J#.
 * @return 0 on success, nonzero on error
 */
int _jsl_MaybeBuildTagFile(int &tfindex)
{
   // if they have an old jsharp.vtg, remove it
   _str ext='jsl';

   DotNetFrameworkInfo frameworks[];
   getDotNetFrameworkPaths(frameworks);
   if (frameworks._length() == 0) {
      return PATH_NOT_FOUND_RC;
   }

   int i,latest_index = 0;
   for (i=1; i<frameworks._length(); ++i) {
      if (frameworks[i].version > frameworks[latest_index].version) {
         latest_index = i;
      }
   }

   _str dotnet_path=frameworks[latest_index].maketags_args;
   if (dotnet_path=='') {
      return PATH_NOT_FOUND_RC;
   }

   // first try to recycle or build the DOTNET tag file
   int status=0,result=0;
   _str tagfilename='';
   if (!ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"dotnet")) {
      // The user does not have an extension specific tag file for C#
      _str extra_file=ext_builtins_path(ext,'dotnet');
      status = ext_BuildTagFile(tfindex,tagfilename,ext,".NET Framework",
                                false,dotnet_path,extra_file);
      if (status < 0) {
         result = status;
      }
   }

   // second try to recycle or build the JSHARP tag file
   if (!ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,'jsharp')) {

      _str jsharp_path = maybe_quote_filename(frameworks[latest_index].install_dir:+FILESEP:+"vjs*.dll");
      status = ext_BuildTagFile(tfindex,tagfilename,ext,"J# Compiler Libraries",false,jsharp_path);
      if (status < 0) {
         result = status;
      }
   }

   return result;

}

/**
 * @see ext_MaybeBuildTagFIle
 */
int _phpscript_MaybeBuildTagFile(int &tfindex)
{
   // maybe we can recycle tag file
   _str tagfilename='';
   _str ext="phpscript";
   _str basename=ext;
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,basename)) {
      return(0);
   }

   // find phpscript.tagdoc
   _str extra_file=ext_builtins_path(ext, basename);
   if (extra_file=='' || !file_exists(extra_file)) {
      return(1);
   }

   // phpscript.tagdoc got to be very large as a stand-alone source
   // file, so we have split it into a series of files.
   _str other_files=_strip_filename(extra_file, "N");
   _maybe_append_filesep(other_files);
   other_files :+= "phpscript??.tagdoc";
   other_files = maybe_quote_filename(other_files);

   // run maketags and tag just the builtins file, and other builtins files
   return ext_BuildTagFile(tfindex,tagfilename,ext,"PHP Libraries",
                           false,other_files,extra_file);
}
/**
 * @see ext_MaybeBuildTagFIle
 */
int _idl_MaybeBuildTagFile(int &tfindex)
{
   return ext_MaybeBuildTagFile(tfindex,'idl','omgidl','OMG IDL Builtins');
}

/**
 * @see _c_find_context_tags
 */
int _phpscript_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           boolean find_parents,int max_matches,
                           boolean exact_match,boolean case_sensitive,
                           int filter_flags=VS_TAGFILTER_ANYTHING,
                           int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= VS_TAGCONTEXT_ONLY_funcs;
   }
   return(_c_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                               info_flags,otherinfo,false,max_matches,
                               exact_match,case_sensitive,
                               filter_flags,context_flags,visited,depth));
}

/**
 * @see _do_default_find_context_tags
 */
int _idl_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                            _str lastid,int lastidstart_offset,
                            int info_flags,typeless otherinfo,
                            boolean find_parents,int max_matches,
                            boolean exact_match, boolean case_sensitive,
                            int filter_flags=VS_TAGFILTER_ANYTHING,
                            int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //say("_idl_find_context_tags("prefixexp","lastid","lastid_prefix")");

   // special case for #include
   if (prefixexp=="#include" && (info_flags & VSAUTOCODEINFO_IN_PREPROCESSING)) {
      extraDir := "";
      lastid = strip(lastid, "B", "\"");
      last_slash := lastpos("/", lastid);
      if (last_slash==0) {
         last_slash = lastpos("\\", lastid);
      }
      if (last_slash) {
         extraDir = substr(lastid,1,last_slash);
         lastid = substr(lastid,last_slash+1);
      }

      _str header_ext=(prefixexp=="#include")? ";h;idl;ih;" : ";idl;midl;";
      _str prefixChar = get_text(1, lastidstart_offset-1);
      num_headers := insert_files_of_extension( 0, 0, 
                                                p_buf_name,
                                                header_ext, 
                                                false, extraDir, 
                                                true, lastid,
                                                exact_match );
      return (num_headers==0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   }

   // id followed by paren, then limit search to functions
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= VS_TAGCONTEXT_ONLY_funcs;
   }

   // this instance is not a function, so mask it out of filter flags
   if (info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
      filter_flags &= ~(VS_TAGFILTER_PROC|VS_TAGFILTER_PROTO);
   }

   errorArgs._makeempty();
   num_matches := 0;
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_locals) ||
       (context_flags & VS_TAGCONTEXT_ONLY_this_file)) {
      tag_files._makeempty();
   }

   // deal with default case where we have no prefix expression
   if (prefixexp == '') {
      return _do_default_find_context_tags( errorArgs, 
                                            prefixexp, 
                                            lastid, lastidstart_offset, 
                                            info_flags, otherinfo, 
                                            find_parents, max_matches, 
                                            exact_match, case_sensitive, 
                                            filter_flags, context_flags, 
                                            visited, depth);
   }

   // attempt to evaluate the prefix expression
   int status=0;
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   if (prefixexp!='') {
      status = _c_get_type_of_prefix(errorArgs, prefixexp, rt, visited);
   }

   // try to match the symbol in the current context
   if (!status) {
      if (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY) {
         context_flags |= VS_TAGCONTEXT_ONLY_const;
      }
      if (rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) {
         context_flags |= VS_TAGCONTEXT_ONLY_static;
      }
      tag_list_in_class(lastid, rt.return_type,
                        0, 0, tag_files,
                        num_matches, max_matches,
                        filter_flags,
                        context_flags | VS_TAGCONTEXT_ALLOW_any_tag_type | ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? 0:VS_TAGCONTEXT_ALLOW_locals),
                        exact_match, case_sensitive, 
                        null, null, visited, depth);

      if (num_matches == 0) {
         int context_list_flags = (find_parents)? VS_TAGCONTEXT_FIND_parents : 0;
         tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, tag_files, '',
                                     num_matches, max_matches,
                                     filter_flags,
                                     context_flags | context_list_flags | VS_TAGCONTEXT_ALLOW_any_tag_type | ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? 0:VS_TAGCONTEXT_ALLOW_locals),
                                     exact_match, case_sensitive, visited, depth);
      }
   }

   // really getting very desperate for a match here
   // stop here if we are only searching context
   if (num_matches==0 && exact_match && prefixexp!='' &&
       !(context_flags & VS_TAGCONTEXT_ONLY_context)) {
      tag_list_context_globals(0,0,lastid,true,tag_files,
                               VS_TAGFILTER_ANYPROC,context_flags,
                               num_matches, max_matches,
                               exact_match, case_sensitive, 
                               visited, depth);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=='')? rt.return_type:lastid;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

// Insert imported packages, current object is editor control
static void java_insert_imports(int tree_wid, int tree_root, var tag_files,
                                _str cur_package_name, _str cur_class_name,
                                _str lastid, _str lastid_prefix,
                                int filter_flags, int context_flags,
                                boolean exact_match, boolean case_sensitive,
                                int &num_matches,int max_matches,
                                VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // look for other imports and global classes in this file
   int i, tag_flags=0;
   _str class_name='';
   _str type_name='';
   _str proc_name='';
   num_matches = tag_get_num_of_context();
   for (i=1; i<=num_matches; i++) {
      if (num_matches > max_matches) break;
      tag_get_detail2(VS_TAGDETAIL_context_flags, i, tag_flags);
      if (tag_flags & VS_TAGFLAG_anonymous) {
         continue;
      }
      tag_get_detail2(VS_TAGDETAIL_context_class, i, class_name);
      if (class_name == '' || class_name :== cur_package_name || class_name:==cur_class_name) {
         tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
         if ((type_name :== 'class'     && (filter_flags & VS_TAGFILTER_STRUCT)) ||
             (type_name :== 'interface' && (filter_flags & VS_TAGFILTER_INTERFACE)) ||
             (type_name :== 'annotype'  && (filter_flags & VS_TAGFILTER_ANNOTATION))) {
            tag_tree_insert_fast(tree_wid, tree_root,
                                 VS_TAGMATCH_context, i, 0, 1, 0, 0, 0);
         } else if (type_name:=='package') {
            tag_get_detail2(VS_TAGDETAIL_context_name, i, proc_name);
            tag_list_in_class(lastid_prefix,proc_name,
                              tree_wid,tree_root,tag_files,
                              num_matches,max_matches,
                              filter_flags,
                              context_flags|VS_TAGCONTEXT_ACCESS_package,
                              exact_match,case_sensitive, 
                              null, null, visited);
         }
      }
   }

   // list specifically imported classes
   if (num_matches < max_matches) {
      tag_list_context_imports(tree_wid,tree_root,lastid_prefix,tag_files,
                               filter_flags,context_flags,
                               num_matches,max_matches,
                               exact_match,case_sensitive);
   }

   // java.lang is always imported
   if (num_matches < max_matches && _LanguageInheritsFrom('java')) {
      tag_list_in_class(lastid_prefix,'java.lang',
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags, 
                        exact_match, case_sensitive,
                        null, null, visited);
      tag_list_in_class(lastid_prefix,'java/lang',
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags, 
                        exact_match, case_sensitive,
                        null, null, visited);
   }

   // these functions are always imported for JSP pages
   if (num_matches < max_matches && file_eq(_get_extension(p_buf_name),"jsp")) {
      tag_list_in_class(lastid_prefix,'javax.servlet',
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited);
      tag_list_in_class(lastid_prefix,'javax/servlet',
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited);
      tag_list_in_class(lastid_prefix,'javax.servlet.jsp',
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited);
      tag_list_in_class(lastid_prefix,'javax/servlet/jsp',
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited);
      tag_list_in_class(lastid_prefix,'javax.servlet.http',
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited);
      tag_list_in_class(lastid_prefix,'javax/servlet/http',
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited);
      tag_list_in_class(lastid_prefix,'javax.servlet.jsp.tagext',
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited);
      tag_list_in_class(lastid_prefix,'javax/servlet/jsp/tagext',
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited);
   }

   // last ditch attempt, list global classes and interfaces
   if (num_matches < max_matches) {
      tag_list_context_globals(tree_wid, tree_root, lastid,
                               true, tag_files,
                               filter_flags, context_flags,
                               num_matches,max_matches,
                               exact_match, case_sensitive,
                               visited);
   }
}

void _m_autocomplete_before_replace(AUTO_COMPLETE_INFO &word,
                                   VS_TAG_IDEXP_INFO &idexp_info, 
                                   _str terminationKey="")
{
   _c_autocomplete_before_replace(word, idexp_info, terminationKey);
}
void _e_autocomplete_before_replace(AUTO_COMPLETE_INFO &word,
                                   VS_TAG_IDEXP_INFO &idexp_info, 
                                   _str terminationKey="")
{
   _c_autocomplete_before_replace(word, idexp_info, terminationKey);
}

void _phpscript_autocomplete_before_replace(AUTO_COMPLETE_INFO &word,
                                            VS_TAG_IDEXP_INFO &idexp_info, 
                                            _str terminationKey="")
{
   // watch for $id,%id,@id when it should just be inserted as 'id'
   switch (first_char(word.insertWord)) {
   case '$':
   case '%':
   case '@':
      if (p_col > 1) {
         word.insertWord = substr(word.insertWord, 2);
      }
   }
}

static int _find_control_name(int wid,_str eventtab,_str lastid,boolean exact_match,int eventtab_line)
{
   if (wid.p_object != OI_SSTAB_CONTAINER && wid.p_name!='' &&
       pos(lastid,wid.p_name)==1 &&
       (!exact_match || length(lastid)==length(wid.p_name))) {
      tag_insert_match('',wid.p_name,"control",p_buf_name,eventtab_line,eventtab,0,'');
   }
   return 0;
}

int _e_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         boolean find_parents,int max_matches,
                         boolean exact_match,boolean case_sensitive,
                         int filter_flags=VS_TAGFILTER_ANYTHING,
                         int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // hook for javadoc tags, adapted to find-context tags.
   if (info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) {
      return _doc_comment_find_context_tags(errorArgs, prefixexp, 
                                            lastid, lastidstart_offset, 
                                            info_flags, otherinfo, 
                                            find_parents, max_matches, 
                                            exact_match, case_sensitive, 
                                            filter_flags, context_flags, 
                                            visited, depth);
   }

   // context is a goto statement?
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      label_count := 0;
      if (context_flags & VS_TAGCONTEXT_ALLOW_locals) {
         _CodeHelpListLabels(0, 0, lastid, '',
                             label_count, max_matches,
                             exact_match, case_sensitive, 
                             visited, depth);
      }
      return (label_count>0)? 0 : VSCODEHELPRC_NO_LABELS_DEFINED;
   }

   // special case for #import or #require "string.e"
   if ((prefixexp == '#import' || prefixexp=="#require" || prefixexp=="#include") &&
       (info_flags & VSAUTOCODEINFO_IN_PREPROCESSING)) {

      extraDir := "";
      lastid = strip(lastid, "B", "\"");
      last_slash := lastpos("/", lastid);
      if (last_slash==0) {
         last_slash = lastpos("\\", lastid);
      }
      if (last_slash) {
         extraDir = substr(lastid,1,last_slash);
         lastid = substr(lastid,last_slash+1);
      }

      _str header_ext=(prefixexp=="#include")? ";sh;" : ";e;";
      _str prefixChar = get_text(1, lastidstart_offset-1);
      num_headers := insert_files_of_extension( 0, 0, 
                                                p_buf_name,
                                                header_ext, 
                                                false, extraDir, 
                                                true, lastid,
                                                exact_match );

      macros_dir := get_env('vsroot'):+'macros':+FILESEP;
      if (!file_eq(_strip_filename(p_buf_name,'n'),macros_dir)) {
         num_headers += insert_files_of_extension( 0, 0,
                                                   macros_dir:+FILESEP:+"slick.sh",
                                                   header_ext, 
                                                   false, extraDir, 
                                                   true, lastid,
                                                   exact_match);
      }
      return (num_headers==0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   }

   //say("_e_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   errorArgs._makeempty();
   num_matches := 0;
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_locals) ||
       (context_flags & VS_TAGCONTEXT_ONLY_this_file)) {
      tag_files._makeempty();
   }

   // attempt to determine what event tab we are in
   eventtab_name := "";
   eventtab_line := 0;
   int wid=0;
   save_pos(auto p);
   typeless p1,p2,p3,p4;
   save_search(p1,p2,p3,p4);
   if ( substr(lastid, 1, 2) != "p_" && 
        !(info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) &&
        !(info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET)) {

      // Allocate a selection for searching up 100k backwards.
      orig_mark_id := _duplicate_selection('');
      mark_id := _alloc_selection();
      _select_line(mark_id);
      long orig_offset = _QROffset();
      if (orig_offset > 100000) {
         _GoToROffset(orig_offset - 100000);
      } else {
         _GoToROffset(0);
      }
      _select_line(mark_id);
      _show_selection(mark_id);
      _end_select(mark_id);

      // search for the event table statement
      searchStatus := search('^ *defeventtab +{:v}','@m-rh');
      if (searchStatus == 0) {
         eventtab_name = get_match_text(0);
         eventtab_line = p_RLine;
         _str dash_eventtab_name=stranslate(eventtab_name,'-','_');
         wid=_find_formobj(dash_eventtab_name,'E');
         if (!wid) {
            wid = find_index(dash_eventtab_name,oi2type(OI_FORM));
         }
      }

      // The selection can be freed because it is not the active selection.
      _show_selection(orig_mark_id);
      _free_selection(mark_id);
   }
   restore_search(p1,p2,p3,p4);
   restore_pos(p);

   // attempt to evaluate the prefix expression
   int status=0;
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   if (prefixexp!='') {
      status = _c_get_type_of_prefix(errorArgs, prefixexp, rt, visited);
      if (status == 0 && rt.return_type != "") {
         context_flags |= VS_TAGCONTEXT_NO_globals;
      }
   }

   // look for a control
   tag_clear_matches();
   if (wid && eventtab_name!='') {
      _for_each_control(wid,_find_control_name,'H',eventtab_name,lastid,exact_match,eventtab_line);
      num_matches = tag_get_num_of_matches();
   }

   // id followed by paren, then limit search to functions
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= VS_TAGCONTEXT_ONLY_funcs;
   }

   // this instance is not a function, so mask it out of filter flags
   if (info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
      filter_flags &= ~(VS_TAGFILTER_PROC|VS_TAGFILTER_PROTO);
   }

   // try to match the symbol in the current context
   if (!status) {
      int context_list_flags = (find_parents)? VS_TAGCONTEXT_FIND_parents : 0;
      tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, tag_files, '',
                                  num_matches, max_matches,
                                  filter_flags,
                                  context_flags | context_list_flags | VS_TAGCONTEXT_ALLOW_any_tag_type | ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? 0:VS_TAGCONTEXT_ALLOW_locals),
                                  exact_match, case_sensitive, visited, depth);
      if (num_matches == 0 && !exact_match && !(context_list_flags & VS_TAGCONTEXT_FIND_lenient)) {
         context_list_flags |= VS_TAGCONTEXT_FIND_lenient;
         tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, tag_files, '',
                                     num_matches, max_matches,
                                     filter_flags,
                                     context_flags | context_list_flags | VS_TAGCONTEXT_ALLOW_any_tag_type | ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? 0:VS_TAGCONTEXT_ALLOW_locals),
                                     exact_match, case_sensitive, visited, depth);
      }
   }

   // insert the 'this' symbol
   if (prefixexp == "" && _CodeHelpMaybeInsertThis( lastid, "this", 
                                                    tag_files, 
                                                    filter_flags, context_flags, 
                                                    exact_match, case_sensitive)) {
      num_matches++;
   }

   // find procs that belong to control names
   if (prefixexp != "" && (status < 0 || (rt.return_flags & VSCODEHELP_RETURN_TYPE_BUILTIN))) {
      int i=tag_find_context_iterator(prefixexp, false, true);
      while (i > 0) {
         _str type_name='';
         _str tag_names='';
         _str signature='';
         int tag_flags=0;
         tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
         if (tag_tree_type_is_func(type_name)) {
            tag_get_detail2(VS_TAGDETAIL_context_name, i, tag_names);
            tag_get_detail2(VS_TAGDETAIL_context_args, i, signature);
            tag_get_detail2(VS_TAGDETAIL_context_flags, i, tag_flags);
            tag_names = substr(tag_names, length(prefixexp)+1);
            while (tag_names != '') {
               _str tag_name='';
               parse tag_names with tag_name ',' tag_names;
               if (tag_name != '' &&
                   pos(lastid,tag_name)==1 &&
                   (!exact_match || length(lastid)==length(tag_name))) {
                  tag_tree_insert_tag(0, 0, 0,1,0,tag_name,type_name,'',0,'',tag_flags,signature);
                  num_matches++;
               }
            }
         }
         i=tag_next_context_iterator(prefixexp, i, false, true);
      }
   }

   // look for slick-c builtins
   if (num_matches == 0 && exact_match) {
      // Slick-C builtins, just dump them in 'globals'
      tag_list_in_file(0, 0, lastid, tag_files,
                       "builtins.e", VS_TAGFILTER_PROTO|VS_TAGFILTER_PROPERTY,
                       context_flags | VS_TAGCONTEXT_ONLY_non_static,
                       num_matches, max_matches,
                       true, true);
   }

   // really getting very desperate for a match here
   // stop here if we are only searching context
   if (num_matches==0 && exact_match && prefixexp!='' &&
       !(context_flags & VS_TAGCONTEXT_ONLY_context)) {
      tag_list_context_globals(0,0,lastid,true,tag_files,
                               VS_TAGFILTER_ANYPROC,context_flags,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth);
   }

   // be forgiving even if we had a bad return type status
   if (status && prefixexp!='') {
      return (num_matches == 0)? status:0;
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=='')? rt.return_type:lastid;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}
/**
 * @see _java_find_context_tags
 */
int _cs_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                          _str lastid,int lastidstart_offset,
                          int info_flags,typeless otherinfo,
                          boolean find_parents,int max_matches,
                          boolean exact_match, boolean case_sensitive,
                          int filter_flags=VS_TAGFILTER_ANYTHING,
                          int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,find_parents,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,visited,depth);
}
/**
 * Find the superclass of 'cur_class_name' and place it in 'lastid'
 * Otherwise, do not modify 'lastid'
 *
 * @param lastid           (reference) on success, set to name of superclass
 * @param cur_class_name   current class context
 * @param tag_files        list of tag files to check
 */
void _java_find_super(_str &lastid, _str cur_class_name, typeless tag_files)
{
   // is this a reference to the constructor of the parent class in Java?
   if (lastid=="super") {
      // make sure that the context doesn't get modified by a background thread.
      tag_lock_context();
      _str tag_dbs = '';
      _str parents = cb_get_normalized_inheritance(cur_class_name, tag_dbs, tag_files, true);
      while (parents != '') {
         _str p1,t1;
         parse parents with p1 ';' parents;
         parse tag_dbs with t1 ';' tag_dbs;
         if (t1!='' && tag_read_db(t1)<0) {
            continue;
         }
         // add transitively inherited class members
         _str inner_class='',outer_class='';
         parse p1 with p1 '<' .;
         tag_split_class_name(p1, inner_class, outer_class);
         if ((t1!='' && tag_find_tag(inner_class, 'class', outer_class)==0) ||
             tag_find_context_iterator(inner_class,true,true,false,outer_class) > 0) {
            lastid=inner_class;
            break;
         }
      }
      tag_reset_find_tag();
      tag_unlock_context();
   }
}
/**
 * @see _do_default_find_context_tags
 */
int _java_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                            _str lastid,int lastidstart_offset,
                            int info_flags,typeless otherinfo,
                            boolean find_parents,int max_matches,
                            boolean exact_match, boolean case_sensitive,
                            int filter_flags=VS_TAGFILTER_ANYTHING,
                            int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //say("_java_find_context_tags: lastid="lastid" prefixexp="prefixexp" exact_match="exact_match" case="case_sensitive);
   // hook for javadoc tags, adapted to find-context tags.
   if (info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) {
      return _doc_comment_find_context_tags(errorArgs, prefixexp, 
                                            lastid, lastidstart_offset, 
                                            info_flags, otherinfo, 
                                            find_parents, max_matches, 
                                            exact_match, case_sensitive, 
                                            filter_flags, context_flags, 
                                            visited, depth);
   }

   // context is a goto statement?
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      label_count := 0;
      if (context_flags & VS_TAGCONTEXT_ALLOW_locals) {
         _CodeHelpListLabels(0, 0, lastid, '',
                             label_count, max_matches,
                             exact_match, case_sensitive, 
                             visited, depth);
      }
      return (label_count>0)? 0 : VSCODEHELPRC_NO_LABELS_DEFINED;
   }

   //say("_e_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   errorArgs._makeempty();
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_locals) ||
       (context_flags & VS_TAGCONTEXT_ONLY_this_file)) {
      tag_files._makeempty();
   }

   // context is in using or import statement?
   num_matches := 0;
   if (prefixexp == '' && (info_flags & VSAUTOCODEINFO_IN_IMPORT_STATEMENT)) {
      tag_list_context_globals(0, 0, lastid,
                               true, tag_files,
                               VS_TAGFILTER_PACKAGE, VS_TAGCONTEXT_ANYTHING,
                               num_matches,max_matches,
                               exact_match, case_sensitive,
                               visited, depth);
      return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // get the current class and current package from the context
   cur_tag_name := cur_type_name := cur_class_name := "";
   cur_class_only := cur_package_name := "";
   cur_tag_flags := cur_type_id := 0;
   context_id := tag_get_current_context(cur_tag_name, cur_tag_flags,
                                         cur_type_name, cur_type_id,
                                         cur_class_name, cur_class_only,
                                         cur_package_name);

   // id followed by paren, then limit search to functions
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= VS_TAGCONTEXT_ONLY_funcs;
   }


   // if this is a static function, only list static methods and fields
   if (context_id>0 && cur_type_id==VS_TAGTYPE_function && cur_class_name!='' && prefixexp=='') {
      if (cur_tag_flags & VS_TAGFLAG_static) {
         context_flags |= VS_TAGCONTEXT_ONLY_static;
      }
   }

   // looking specifically for annotation types here
   if (substr(prefixexp,1, 1)=='@' && _LanguageInheritsFrom('java')) {
      prefixexp = substr(prefixexp,2);
      filter_flags = VS_TAGFILTER_ANNOTATION;
      if (prefixexp == '') {
         // update the classes, make sure that case-sensitive matches get preference
         // first try case-sensitive matches
         java_insert_imports(0, 0, tag_files,
                             cur_package_name, cur_class_name,
                             lastid, lastid,
                             VS_TAGFILTER_ANNOTATION,
                             VS_TAGCONTEXT_ACCESS_public,
                             exact_match, case_sensitive,
                             num_matches, max_matches, visited);
         return (num_matches > 0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
      }

   // no prefix expression, update globals and members from current context
   } else if (prefixexp == "" || prefixexp == "new") {

      // narrow down filters if this is a "new" expression
      if (prefixexp == "new") {
         filter_flags &= ~VS_TAGFILTER_ANYDATA;
         filter_flags &= ~VS_TAGFILTER_ANYPROC;
         filter_flags &= ~VS_TAGFILTER_DEFINE;
         filter_flags &= ~VS_TAGFILTER_LABEL;
      }

      // insert the 'this' symbol
      if (_CodeHelpMaybeInsertThis( lastid, "this", 
                                    tag_files, 
                                    filter_flags, context_flags, 
                                    exact_match, case_sensitive)) {
         num_matches++;
      }

      // insert the 'super' symbol
      if (_CodeHelpMaybeInsertThis( lastid, "super", 
                                    tag_files, 
                                    filter_flags, context_flags, 
                                    exact_match, case_sensitive, true)) {
         num_matches++;
      }

      // insert the 'value' parameter if we are in a C# property getter or setter
      if (_LanguageInheritsFrom('cs') && 
          _CodeHelpDoesIdMatch(lastid, "value", exact_match, case_sensitive) &&
          context_id > 0 && tag_tree_type_is_func(cur_type_name) &&
          (substr(cur_tag_name,1,4)=="set_" ||
           substr(cur_tag_name,1,4)=="add_" || 
           substr(cur_tag_name,1,7)=="remove_")) {

         // get the current tag type
         cur_return_type := "";
         cur_line_no := 0;
         tag_get_detail2(VS_TAGDETAIL_context_line, context_id, cur_line_no);
         tag_get_detail2(VS_TAGDETAIL_context_return, context_id, cur_return_type);
         tag_insert_match("", "value", "param", p_buf_name, cur_line_no, 
                          "", 0, cur_return_type);
         num_matches++;
      }

      // Find jsp.vtg instead of passing in all tag_files
      if (!(context_flags & VS_TAGCONTEXT_ONLY_this_file) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_locals) &&
          !(context_flags & VS_TAGCONTEXT_NO_globals)) {
         _str jsp_tag_files[];
         jsp_tag_files[0] = _tagfiles_path() :+ "jsp.vtg";
         tag_list_context_globals(0, 0, lastid,
                                  true, jsp_tag_files,
                                  filter_flags, context_flags,
                                  num_matches, max_matches, 
                                  exact_match, case_sensitive, 
                                  visited, depth);
      }

      // list explicitely imported packages from current context
      if (!(context_flags & VS_TAGCONTEXT_ONLY_inclass) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_locals)) {

         // java.lang is always imported
         if (_LanguageInheritsFrom('java') && _CodeHelpDoesIdMatch(lastid, "java", exact_match, case_sensitive)) {
            tag_insert_match("", "java", "package", "", 1, "", 0, "");
            num_matches++;
            if (!exact_match) {
               tag_insert_match("", "java.lang", "package", "", 1, "", 0, "");
               num_matches++;
            }
         }

         // javax.servlet is always imported into JSP
         if (file_eq(_get_extension(p_buf_name), "jsp")) {
            if (_CodeHelpDoesIdMatch(lastid, "javax", exact_match, case_sensitive)) {
               tag_insert_match("", "javax", "package", "", 1, "", 0, "");
               num_matches++;
               if (!exact_match) {
                  tag_insert_match("", "javax.servlet", "package", "", 1, "", 0, "");
                  tag_insert_match("", "javax.servlet.http", "package", "", 1, "", 0, "");
                  tag_insert_match("", "javax.servlet.jsp", "package", "", 1, "", 0, "");
                  tag_insert_match("", "javax.servlet.jsp.tagext", "package", "", 1, "", 0, "");
                  num_matches+=4;
               }
            }
         }

         n := tag_get_num_of_context();
         for (i:=1; i<=n; i++) {
            type_name := proc_name := package_name := first_name := "";
            package_line := 0;
            tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
            tag_get_detail2(VS_TAGDETAIL_context_line, i, package_line);
            if (type_name :== 'package') {
               tag_get_detail2(VS_TAGDETAIL_context_name, i, proc_name);
               tag_get_detail2(VS_TAGDETAIL_context_class, i, package_name);
               package_name = stranslate(package_name, ".", VS_TAGSEPARATOR_class);
               package_name = stranslate(package_name, ".", VS_TAGSEPARATOR_package);
               if (package_name == "") package_name = proc_name;
               else package_name = package_name "." proc_name;

            } else if (type_name :== 'import') {
               tag_get_detail2(VS_TAGDETAIL_context_name, i, proc_name);
               proc_name = stranslate(proc_name, ".", VS_TAGSEPARATOR_class);
               proc_name = stranslate(proc_name, ".", VS_TAGSEPARATOR_package);
               if (pos(".*", proc_name) > 0) {
                  package_name = substr(proc_name, 1, pos('S')-1);
               } else if (lastpos(".", proc_name) > 0) {
                  package_name = substr(proc_name, 1, pos('S')-1);
                  proc_name = substr(proc_name, pos('S')+1);
                  if (_CodeHelpDoesIdMatch(lastid, proc_name, exact_match, case_sensitive)) {
                     tag_insert_match("", proc_name, VS_TAGTYPE_package, p_buf_name, package_line, "", 0, "");
                     num_matches++;
                  }
               }
            }
            if (package_name != "") {
               parse package_name with first_name "." package_name;
               if (_CodeHelpDoesIdMatch(lastid, first_name, exact_match, case_sensitive)) {
                  tag_insert_match("", first_name, VS_TAGTYPE_package, p_buf_name, package_line, "", 0, "");
                  num_matches++;
                  if (!exact_match) {
                     proc_name = first_name;
                     while (package_name != "") {
                        parse package_name with first_name "." package_name;
                        proc_name = proc_name "." first_name;
                        tag_insert_match("", proc_name, VS_TAGTYPE_package, p_buf_name, package_line, "", 0, "");
                        num_matches++;
                     }
                  }
               }
               proc_name = package_name"."proc_name;
            }
         }

         // list other available classes matching prefix
         if ( lastid == "") {
            tag_list_globals_of_type(0, 0, tag_files, 
                                     VS_TAGTYPE_package, 0, 0,
                                     num_matches, max_matches);
         } else {
            tag_list_context_packages(0, 0, lastid, tag_files, 
                                      num_matches, max_matches, 
                                      exact_match, case_sensitive);
         }
      }

      // check for matches
      if (!case_sensitive) {
         tag_list_symbols_in_context(lastid, "", 
                                     0, 0, tag_files, "",
                                     num_matches, max_matches,
                                     filter_flags, context_flags,
                                     exact_match, true,//case_sensitive,
                                     visited, depth);
      }
      tag_list_symbols_in_context(lastid, "", 
                                  0, 0, tag_files, "",
                                  num_matches, max_matches,
                                  filter_flags, context_flags,
                                  exact_match, case_sensitive,
                                  visited, depth);
      if (num_matches > 0) return num_matches;

      return _do_default_find_context_tags(errorArgs, "",
                                           lastid, lastidstart_offset,
                                           info_flags, otherinfo, 
                                           find_parents, max_matches, 
                                           exact_match, case_sensitive,
                                           filter_flags, context_flags,
                                           visited, depth);
   }

   // maybe prefix expression is a package name or prefix of package name
   is_package := _CodeHelpListPackages(0, 0,
                                       p_window_id, tag_files,
                                       prefixexp, lastid,
                                       num_matches, max_matches,
                                       exact_match, case_sensitive);

   // evaluate the prefix expression
   status := 0;
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   if (prefixexp != '') {
      status = _c_get_type_of_prefix(errorArgs, prefixexp, rt, visited);
      //say("match_class="rt.return_type" status="status);
      if (status && num_matches==0) {
         return status;
      }
   } else {
      status = 0;
   }

   if (!status) {
      
      // pick up other context flags depending on class scope      
      if ((pos(cur_package_name'/',rt.return_type)==1) ||
          (!pos(VS_TAGSEPARATOR_package,rt.return_type) &&
           !pos(VS_TAGSEPARATOR_package,cur_class_name))) {
         context_flags |= VS_TAGCONTEXT_ALLOW_package;
         context_flags |= VS_TAGCONTEXT_ALLOW_protected;
      }
      if (tag_is_parent_class(rt.return_type,cur_class_name,tag_files,false,false)) {
         context_flags |= VS_TAGCONTEXT_ACCESS_package;
         context_flags |= VS_TAGCONTEXT_ACCESS_protected;
      }
      if (tag_check_for_package(rt.return_type, tag_files, true, true)) {
         context_flags |= VS_TAGCONTEXT_ALLOW_package;
      }
      if (pos(rt.return_type:+VS_TAGSEPARATOR_class, cur_class_name)==1) {
         context_flags |= VS_TAGCONTEXT_ALLOW_private;
      }

      context_flags |= _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags, context_flags);

      // add the builtin new method
      if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) && 
          _LanguageInheritsFrom('java') && 
          _CodeHelpDoesIdMatch(lastid, "new", exact_match, case_sensitive)) {
         tag_insert_match("", "new", "constr", "", 1, "", 0, "");
         num_matches++;
      }
         
      // add the builtin length attribute
      if ((rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY) && 
          _LanguageInheritsFrom('java') &&
          _CodeHelpDoesIdMatch(lastid, "length", exact_match, case_sensitive)) {
         tag_insert_match("", "length", "prop", "", 1, "", 0, "");
         num_matches++;
      }

      // add the builtin clone method
      if ((rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY) && 
          _LanguageInheritsFrom('java') &&
          _CodeHelpDoesIdMatch(lastid, "clone", exact_match, case_sensitive)) {
         tag_insert_match("", "clone", "func", "", 1, "", 0, "");
         num_matches++;
      }

      if (_LanguageInheritsFrom('d')) {
         tag_tree_decompose_tag(rt.taginfo, auto unused_tag_name, auto unused_class_name, auto type_name, auto rt_tag_flags);
         if (tag_tree_type_is_class(type_name) || tag_tree_type_is_data(type_name)) {
            // The .tupleof property returns an ExpressionTuple of all the 
            // fields in the class,\nexcluding the hidden fields and the 
            // fields in the base class"));
            if (_CodeHelpDoesIdMatch(lastid, "tupleof", exact_match, case_sensitive)) {
               tag_insert_match("", "tupleof", "prop", "", 1, "", 0, "ExpressionTuple");
               num_matches++;
            }
            // Size in bytes of struct
            if (_CodeHelpDoesIdMatch(lastid, "sizeof", exact_match, case_sensitive)) {
               tag_insert_match("", "sizeof", "prop", "", 1, "", 0, "int");
               num_matches++;
            }
            // Size boundary struct needs to be aligned on
            if (_CodeHelpDoesIdMatch(lastid, "alignof", exact_match, case_sensitive)) {
               tag_insert_match("", "alignof", "prop", "", 1, "", 0, "int");
               num_matches++;
            }
            // Provides access to the encosing (outer) class
            if (pos(VS_TAGSEPARATOR_class, rt.return_type) > 0 &&
                _CodeHelpDoesIdMatch(lastid, "outer", exact_match, case_sensitive)) {
               tag_split_class_name(rt.return_type, auto inner_name, auto outer_name);
               tag_insert_match("", "outer", "prop", "", 1, "", 0, outer_name);
               num_matches++;
            }
            // Allocate an instance of a subclass
            if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) && 
                !(rt_tag_flags & VS_TAGFLAG_template) &&
                _CodeHelpDoesIdMatch(lastid, "new", exact_match, case_sensitive)) {
               tag_insert_match("", "new", "constr", "", 1, "", 0, "");
               num_matches++;
            }
         }

         if (type_name=="enum") {
            // Smallest value of enum
            if (_CodeHelpDoesIdMatch(lastid, "min", exact_match, case_sensitive)) {
               tag_insert_match("", "min", "prop", "", 1, "", 0, "int");
               num_matches++;
            }
            // Largest value of enum
            if (_CodeHelpDoesIdMatch(lastid, "max", exact_match, case_sensitive)) {
               tag_insert_match("", "max", "prop", "", 1, "", 0, "int");
               num_matches++;
            }
            // First enum member value
            if (_CodeHelpDoesIdMatch(lastid, "init", exact_match, case_sensitive)) {
               tag_insert_match("", "init", "prop", "", 1, "", 0, "int");
               num_matches++;
            }
            // Size of storage for an enumerated value
            if (_CodeHelpDoesIdMatch(lastid, "sizeof", exact_match, case_sensitive)) {
               tag_insert_match("", "sizeof", "prop", "", 1, "", 0, "int");
               num_matches++;
            }
         }

         if ((rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) && 
             (rt_tag_flags & VS_TAGFLAG_template)) {
            rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_STATIC_ONLY);
            context_flags &= ~(VS_TAGCONTEXT_ONLY_static);
            context_flags |= VS_TAGCONTEXT_ONLY_this_class;
         }
      }
      if (is_package) {
         context_flags|=VS_TAGCONTEXT_ONLY_this_class;
      }

      constructor_class := rt.return_type;
      is_new_expr := pos('new ',prefixexp' ')==1;
      outer_class := is_new_expr ? substr(prefixexp, 5) : prefixexp;

      if (status && is_new_expr) {
         // Type name isn't complete, so return possible type names.
         status = tag_list_symbols_in_context(outer_class, null, 0, 0, tag_files, '', num_matches, 10,
                                              VS_TAGFILTER_ANYSTRUCT|VS_TAGFILTER_ANYSYMBOL,
                                              VS_TAGCONTEXT_ONLY_classes, exact_match, case_sensitive, visited, depth);
      }

      if (status) {
         return status;
      }

      // handle 'new' expressions as a special case
      if (is_new_expr && (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN)) {
         if (last_char(outer_class)==':') {
            outer_class = substr(outer_class, 1, length(outer_class)-2);
         }
         if (last_char(outer_class)=='.') {
            outer_class = substr(outer_class, 1, length(outer_class)-1);
         }
         outer_class = stranslate(outer_class, ':', '::');
         if (outer_class=='') {
            tag_qualify_symbol_name(constructor_class,lastid,'',p_buf_name,tag_files,true);
         } else {
            constructor_class = tag_join_class_name(lastid, outer_class, tag_files, true);
         }
      }

      if (constructor_class != "") {
         int handle = _ProjectHandle();
         if (prefixexp != '' && pos('R.',prefixexp) == 1 && _ProjectGet_AppType(handle) == 'android') {
            context_flags = VS_TAGCONTEXT_ALLOW_any_tag_type;
            _str wspace_tagfile[];
            wspace_tagfile[0] = _GetWorkspaceTagsFilename();
            tag_list_any_symbols(0,0,lastid,wspace_tagfile,filter_flags,context_flags,num_matches,max_matches,
                                 exact_match,case_sensitive);
            if (num_matches == 0) {
               tag_list_any_symbols(0,0,lastid,tag_files,filter_flags,context_flags,num_matches,max_matches,
                                    exact_match,case_sensitive);
            }
         } else {
            tag_list_in_class(lastid, constructor_class,
                              0, 0, tag_files,
                              num_matches, max_matches,
                              filter_flags, context_flags,
                              exact_match, case_sensitive,
                              null, null, visited, depth+1);
         }
      }
   }


   // replace 'super' with the name of the superclass
   if (lastid=="super" && _LanguageInheritsFrom("java")) {
      _java_find_super(lastid,cur_class_name,tag_files);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=='')? rt.return_type:lastid;
   //say("_java_find_context_tags: num_matches="num_matches);
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}
/**
 * @see _java_find_context_tags
 */
int _cfscript_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                                _str lastid,int lastidstart_offset,
                                int info_flags,typeless otherinfo,
                                boolean find_parents,int max_matches,
                                boolean exact_match,boolean case_sensitive,
                                int filter_flags=VS_TAGFILTER_ANYTHING,
                                int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                                VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,false,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,visited,depth));
}

/**
 * @see _c_parse_return_type
 */
int _java_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                            _str symbol, _str search_class_name,
                            _str file_name, _str return_type, boolean isjava,
                            struct VS_TAG_RETURN_TYPE &rt,
                            VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_parse_return_type(errorArgs,tag_files,
                               symbol,search_class_name,
                               file_name,return_type,
                               true,rt,visited,depth);
}
/**
 * @see _c_parse_return_type
 */
int _cs_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                          _str symbol, _str search_class_name,
                          _str file_name, _str return_type, boolean isjava,
                          struct VS_TAG_RETURN_TYPE &rt,
                          VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_parse_return_type(errorArgs,tag_files,
                               symbol,search_class_name,
                               file_name,return_type,
                               true,rt,visited,depth);
}


/**
 * @see _c_analyze_return_type
 */
int _e_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                           _str tag_name, _str class_name,
                           _str type_name, int tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[])
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,rt,visited);
}
/**
 * @see _c_analyze_return_type
 */
/*
int _cs_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                           _str tag_name, _str class_name,
                           _str type_name, int tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[])
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,rt,visited);
}
*/

/**
 * @see _c_analyze_return_type
 */
int _java_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                           _str tag_name, _str class_name,
                           _str type_name, int tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[])
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,rt,visited);
}
/**
 * @see _c_analyze_return_type
 */
int _phpscript_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                           _str tag_name, _str class_name,
                           _str type_name, int tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[])
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,rt,visited);
}
/**
 * @see _c_analyze_return_type
 */
int _rul_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                           _str tag_name, _str class_name,
                           _str type_name, int tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[])
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,rt,visited);
}



static _str _make_import_wildcard_pattern(_str (&existing_imports)[])
{
   _str choices[];
   int  i;

   // Implicit wildcard in all compilation units.
   choices[0] = 'java.lang';

   for (i = 0; i < existing_imports._length(); i++) {
      int spos = pos('.*', existing_imports[i]);
      if (spos) {
         choices[choices._length()] = substr(existing_imports[i], 1, spos-1);
      }
   }

   return "^("join(choices, '|')')\.[A-Za-z0-9$_]+$';;
}

/**
 * Insert the language-specific constants matching the expected type.
 *
 * @param rt_expected    expected return type
 * @param tag_files      array of tag files
 * @param tree_wid       window ID for tree to insert into
 * @param tree_index     tree index to insert at
 * @param lastid_prefix  word prefix to search for 
 * @param exact_match    search for an exact match or a prefix 
 * @param case_sensitive case-sensitive identifier match?
 *
 * @return number of items inserted
 */
int _java_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                   int tree_wid, int tree_index,
                                   _str lastid_prefix="", 
                                   boolean exact_match=false, boolean case_sensitive=true)
{
   // number of matches inserted
   int k=0, match_count=0;

   // could insert NULL, but screw them...
   if (rt_expected.pointer_count>0) {
      return (match_count);
   }

   // Insert boolean
   if (rt_expected.return_type=='boolean') {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "true", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"true","const","",0,"",0,"");
         match_count++;
      }
      if (_CodeHelpDoesIdMatch(lastid_prefix, "false", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"false","const","",0,"",0,"");
         match_count++;
      }
   }

   // Insert empty string
   if (rt_expected.return_type=='java.lang/String' || rt_expected.return_type=='java/lang/String') {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "\"", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,'""',"const","",0,"",0,"");
         match_count++;
      }
   }

   // Insert null for non-builtin types (these must be classes)
   if (!_c_is_builtin_type(rt_expected.return_type)) {
      // insert null reference
      if (_CodeHelpDoesIdMatch(lastid_prefix, "null", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,'null',"const","",0,"",0,"");
         match_count++;
      }
      // maybe insert 'this'
      if (rt_expected.pointer_count==0) {
         _str this_class_name = _MatchThisOrSelf();
         if (this_class_name!='') {
            typeless tag_files=tags_filenamea(p_LangId);
            if (this_class_name == rt_expected.return_type ||
                tag_is_parent_class(rt_expected.return_type,this_class_name,tag_files,true,true)) {
               if (_CodeHelpDoesIdMatch(lastid_prefix, "this", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"this","const","",0,"",0,"");
                  match_count++;
               }
            }
         }

         // Try inserting new 'class' (Java specific)
         if (_LanguageInheritsFrom("java")) {
            // If it was specified as a generic, include the set parameters in the suggestion
            _str generic_args = '';
            _str blank_args = '';
            if (rt_expected.istemplate && rt_expected.template_names._length() > 0) {
               _str existing_imports[];
               VS_JAVA_IMPORT_INFO imports:[];

               // Take a look at the existing imports so we can un-qualify
               // generic argument types as needed.
               java_get_existing_imports(existing_imports, imports, auto min_seek, auto max_seek);

               _str names[];  names._makeempty();
               _str wildcards = _make_import_wildcard_pattern(existing_imports);
               int ai;

               for (ai = 0; ai < rt_expected.template_names._length(); ai++) {
                  _str ty = rt_expected.template_args:[rt_expected.template_names[ai]];

                  if (imports:[ty] != null || (wildcards && pos(wildcards, ty, 1, 'U'))) {
                     int dotp = lastpos('.', ty);
                     ty = substr(ty, dotp+1);
                  }
                  names[ai] = ty;
               }
               generic_args="<"(join(names, ','))">";
               blank_args="<>";
            }

            // check the current package name
            _str cur_tag_name="", cur_type_name="", cur_context="", cur_class="", cur_package="";
            typeless cur_flags=0, cur_type_id=0;
            tag_get_current_context(cur_tag_name, cur_flags, cur_type_name, cur_type_id, cur_context, cur_class, cur_package);

            // insert qualified class name (except for java.lang and current package)
            _str class_name=stranslate(rt_expected.return_type,'.',VS_TAGSEPARATOR_class);
            class_name=stranslate(class_name,'.',VS_TAGSEPARATOR_package);
            if (pos("java.lang.", class_name) != 1 && 
                pos("java/lang/", class_name) != 1 && 
                pos(cur_package, class_name) != 1) {
               if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",VS_TAGFLAG_constructor,"");
                  match_count++;
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",VS_TAGFLAG_constructor,"");
                  match_count++;
               }
            }

            // insert unqualified class name
            int p = lastpos('.', class_name);
            if (p > 0) {
               class_name = substr(class_name, p+1);
               if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",VS_TAGFLAG_constructor,"");
                  match_count++;
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",VS_TAGFLAG_constructor,"");
                  match_count++;
               }
            }
         }

         // Try inserting new 'class' (C# specific)
         if (_LanguageInheritsFrom("cs")) {
            // If it was specified as a generic, include the set parameters in the suggestion
            _str generic_args = '';
            _str blank_args = '';
            if (rt_expected.istemplate && rt_expected.template_names._length() > 0) {
               _str names[];
               for (ai := 0; ai < rt_expected.template_names._length(); ai++) {
                  _str ty = rt_expected.template_args:[rt_expected.template_names[ai]];
                  names[ai] = ty;
               }
               generic_args="<"(join(names, ','))">";
               blank_args="<>";
            }

            // check the current package name
            _str cur_tag_name="", cur_type_name="", cur_context="", cur_class="", cur_package="";
            typeless cur_flags=0, cur_type_id=0;
            tag_get_current_context(cur_tag_name, cur_flags, cur_type_name, cur_type_id, cur_context, cur_class, cur_package);

            // insert qualified class name (except for java.lang and current package)
            _str class_name=stranslate(rt_expected.return_type,'.',VS_TAGSEPARATOR_class);
            class_name=stranslate(class_name,'.',VS_TAGSEPARATOR_package);
            if (pos("System.", class_name) != 1 && 
                pos("System/", class_name) != 1 && 
                pos(cur_package, class_name) != 1) {
               if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",VS_TAGFLAG_constructor,"");
                  match_count++;
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",VS_TAGFLAG_constructor,"");
                  match_count++;
               }
            }

            // insert unqualified class name
            int p = lastpos('.', class_name);
            if (p > 0) {
               class_name = substr(class_name, p+1);
               if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",VS_TAGFLAG_constructor,"");
                  match_count++;
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",VS_TAGFLAG_constructor,"");
                  match_count++;
               }
            }
         }
      }
   }

   // that's all folks
   return(match_count);
}
/**
 * Insert the language-specific constants matching the expected type.
 *
 * @param rt_expected    expected return type
 * @param tag_files      array of tag files
 * @param tree_wid       window ID for tree to insert into
 * @param tree_index     tree index to insert at
 * @param lastid_prefix  word prefix to search for 
 * @param exact_match    search for an exact match or a prefix 
 * @param case_sensitive case-sensitive identifier match?
 *
 * @return number of items inserted
 */
int _rul_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                  int tree_wid, int tree_index,
                                  _str lastid_prefix="", 
                                  boolean exact_match=false, boolean case_sensitive=true)
{
   // number of matches inserted
   int k=0, match_count=0;

   // could insert NULL, but screw them...
   if (rt_expected.pointer_count>0) {
      return (match_count);
   }

   // Insert boolean
   if (rt_expected.return_type=='BOOL') {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "TRUE", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"TRUE","const","",0,"",0,"");
         match_count++;
      }
      if (_CodeHelpDoesIdMatch(lastid_prefix, "FALSE", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"FALSE","const","",0,"",0,"");
         match_count++;
      }
   }

   // that's all folks
   return(match_count);
}
/**
 * Insert the language-specific constants matching the expected type.
 *
 * @param rt_expected    expected return type
 * @param tag_files      array of tag files
 * @param tree_wid       window ID for tree to insert into
 * @param tree_index     tree index to insert at
 * @param lastid_prefix  word prefix to search for 
 * @param exact_match    search for an exact match or a prefix 
 * @param case_sensitive case-sensitive identifier match?
 *
 * @return number of items inserted
 */
int _cs_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                 int tree_wid, int tree_index,
                                 _str lastid_prefix="", 
                                 boolean exact_match=false, boolean case_sensitive=true)
{
   return _java_insert_constants_of_type(rt_expected,
                                         tree_wid,tree_index,
                                         lastid_prefix,
                                         exact_match,case_sensitive);
}

/**
 * Insert the language-specific constants matching the expected type.
 *
 * @param rt_expected    expected return type
 * @param tag_files      array of tag files
 * @param tree_wid       window ID for tree to insert into
 * @param tree_index     tree index to insert at
 * @param lastid_prefix  word prefix to search for 
 * @param exact_match    search for an exact match or a prefix 
 * @param case_sensitive case-sensitive identifier match?
 *
 * @return number of items inserted
 */
int _e_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                int tree_wid, int tree_index,
                                _str lastid_prefix="",
                                boolean exact_match=false, boolean case_sensitive=true)
{
   // number of matches inserted
   int k=0, match_count=0;

   // could insert NULL, but screw them...
   if (rt_expected.pointer_count>0) {
      if (!(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
         if (_CodeHelpDoesIdMatch(lastid_prefix, "null", exact_match, case_sensitive)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"null","const","",0,"",0,"");
            match_count++;
         }
      }
      return (match_count);
   }

   // Insert boolean
   if (rt_expected.return_type=='boolean') {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "true", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"true","const","",0,"",0,"");
         match_count++;
      }
      if (_CodeHelpDoesIdMatch(lastid_prefix, "false", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"false","const","",0,"",0,"");
         match_count++;
      }
   }

   // Insert empty string
   if (rt_expected.return_type=='_str') {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "\"", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,'""',"const","",0,"",0,"");
         match_count++;
      }
   }

   // that's all folks
   return(match_count);
}

/**
 * @see _c_match_return_type
 */
int _e_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                  struct VS_TAG_RETURN_TYPE &rt_candidate,
                                  _str tag_name,_str type_name, int tag_flags,
                                  _str file_name, int line_no,
                                  _str prefixexp,typeless tag_files,
                                  int tree_wid, int tree_index)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,tree_wid,tree_index);

}
/**
 * @see _c_match_return_type
 */
/*
int _cs_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                  struct VS_TAG_RETURN_TYPE &rt_candidate,
                                  _str tag_name,_str type_name, int tag_flags,
                                  _str file_name, int line_no,
                                  _str prefixexp,typeless tag_files,
                                  int tree_wid, int tree_index)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,tree_wid,tree_index);

}
*/
/**
 * @see _c_match_return_type
 */
int _java_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                  struct VS_TAG_RETURN_TYPE &rt_candidate,
                                  _str tag_name,_str type_name, int tag_flags,
                                  _str file_name, int line_no,
                                  _str prefixexp,typeless tag_files,
                                  int tree_wid, int tree_index)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,tree_wid,tree_index);

}
/**
 * @see _c_match_return_type
 */
int _phpscript_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                  struct VS_TAG_RETURN_TYPE &rt_candidate,
                                  _str tag_name,_str type_name, int tag_flags,
                                  _str file_name, int line_no,
                                  _str prefixexp,typeless tag_files,
                                  int tree_wid, int tree_index)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,tree_wid,tree_index);

}
/**
 * @see _c_match_return_type
 */
int _rul_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                  struct VS_TAG_RETURN_TYPE &rt_candidate,
                                  _str tag_name,_str type_name, int tag_flags,
                                  _str file_name, int line_no,
                                  _str prefixexp,typeless tag_files,
                                  int tree_wid, int tree_index)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,tree_wid,tree_index);

}
/**
 * @see _c_find_members_of
 * 
 * @deprecated  This feature is no longer used in 11.0
 */
int _e_find_members_of(struct VS_TAG_RETURN_TYPE &rt,
                       _str tag_name,_str type_name, int tag_flags,
                       _str file_name, int line_no,
                       _str &prefixexp, typeless tag_files, int filter_flags,
                       VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   return _c_find_members_of(rt,tag_name,type_name,tag_flags,
                             file_name,line_no,prefixexp,
                             tag_files,filter_flags,visited);
}
/**
 * @see _c_find_members_of
 * 
 * @deprecated  This feature is no longer used in 11.0
 */
int _java_find_members_of(struct VS_TAG_RETURN_TYPE &rt,
                          _str tag_name,_str type_name, int tag_flags,
                          _str file_name, int line_no,
                          _str &prefixexp, typeless tag_files, int filter_flags,
                          VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   return _c_find_members_of(rt,tag_name,type_name,tag_flags,
                             file_name,line_no,prefixexp,
                             tag_files,filter_flags,visited);
}
/**
 * @see _c_find_members_of
 * 
 * @deprecated  This feature is no longer used in 11.0
 */
int _rul_find_members_of(struct VS_TAG_RETURN_TYPE &rt,
                       _str tag_name,_str type_name, int tag_flags,
                       _str file_name, int line_no,
                       _str &prefixexp, typeless tag_files, int filter_flags,
                         VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   return _c_find_members_of(rt,tag_name,type_name,tag_flags,
                             file_name,line_no,prefixexp,
                             tag_files,filter_flags,visited);
}

/**
 * @see _c_fcthelp_get_start
 */
int _e_fcthelp_get_start(_str (&errorArgs)[],
                         boolean OperatorTyped,
                         boolean cursorInsideArgumentList,
                         int &FunctionNameOffset,
                         int &ArgumentStartOffset,
                         int &flags
                         )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags));
}
/**
 * @see _c_fcthelp_get_start
 */
int _java_fcthelp_get_start(_str (&errorArgs)[],
                            boolean OperatorTyped,
                            boolean cursorInsideArgumentList,
                            int &FunctionNameOffset,
                            int &ArgumentStartOffset,
                            int &flags
                           )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags));
}
/**
 * @see _c_fcthelp_get_start
 */
int _cs_fcthelp_get_start(_str (&errorArgs)[],
                          boolean OperatorTyped,
                          boolean cursorInsideArgumentList,
                          int &FunctionNameOffset,
                          int &ArgumentStartOffset,
                          int &flags
                         )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags));
}
/**
 * @see _c_fcthelp_get_start
 */
int _cfscript_fcthelp_get_start(_str (&errorArgs)[],
                                boolean OperatorTyped,
                                boolean cursorInsideArgumentList,
                                int &FunctionNameOffset,
                                int &ArgumentStartOffset,
                                int &flags
                               )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags));
}
/**
 * @see _c_fcthelp_get_start
 */
int _phpscript_fcthelp_get_start(_str (&errorArgs)[],
                           boolean OperatorTyped,
                           boolean cursorInsideArgumentList,
                           int &FunctionNameOffset,
                           int &ArgumentStartOffset,
                           int &flags
                          )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags));
}

/**
 * @see _c_fcthelp_get
 */
int _e_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth));
}
/**
 * @see _c_fcthelp_get
 */
int _java_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   int status=_c_fcthelp_get(errorArgs,
                             FunctionHelp_list,FunctionHelp_list_changed,
                             FunctionHelp_cursor_x,
                             FunctionHelp_HelpWord,
                             FunctionNameStartOffset,
                             flags, symbol_info,
                             visited, depth);
   return(status);
}
/**
 * @see _c_fcthelp_get
 */
int _cs_fcthelp_get(  _str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth));
}
/**
 * @see _c_fcthelp_get
 */
int _cfscript_fcthelp_get( _str (&errorArgs)[],
                          VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                          boolean &FunctionHelp_list_changed,
                          int &FunctionHelp_cursor_x,
                          _str &FunctionHelp_HelpWord,
                          int FunctionNameStartOffset,
                          int flags,
                          VS_TAG_BROWSE_INFO symbol_info=null,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth));
}
/**
 * @see _c_fcthelp_get
 */
int _phpscript_fcthelp_get(  _str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth));
}

/*
// Cold Fusion has no tags, except the ones we create in builtins.cfscript
int cfscript_proc_search(_str &proc_name,int find_first)
{
   int StartFromCursor=0;
   int StopSeekPos=0;
   if (arg() > 3 && isinteger(arg(4))) StartFromCursor=(int)arg(4);
   if (arg() > 4 && isinteger(arg(5))) StopSeekPos=(int)arg(5);
   return js_proc_search(proc_name,find_first,p_LangId,StartFromCursor,StopSeekPos);
}
*/
extern int vsjs_list_tags(int output_view_id,
                          _str filename_p,
                          _str extension_p,
                          int ltf_flags=VSLTF_SET_TAG_CONTEXT,
                          int tree_wid=0, int bm_index=0,
                          int startFromCursor=0,
                          int stopSeekPosition=0);
int vscfscript_list_tags(int output_view_id,
                         _str filename_p,
                         _str extension_p,
                         int ltf_flags=VSLTF_SET_TAG_CONTEXT,
                         int tree_wid=0, int bm_index=0,
                         int startFromCursor=0,
                         int stopSeekPosition=0)
{
   return vsjs_list_tags(output_view_id, filename_p, extension_p, 
                         ltf_flags, 0, 0, startFromCursor, stopSeekPosition);
}

/**
 * @see _c_get_decl
 */
_str _rul_get_decl(_str lang, VS_TAG_BROWSE_INFO &info,int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}
/**
 * @see _c_get_decl
 */
_str _idl_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                   _str decl_indent_string="",
                   _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}
/**
 * @see _c_get_decl
 */
_str _phpscript_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                         _str decl_indent_string="",
                         _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}
/**
 * @see _c_get_decl
 */
_str _e_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                 _str decl_indent_string="",
                 _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}
/**
 * @see _c_get_decl
 */
_str _pl_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                  _str decl_indent_string="",
                  _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}
/**
 * @see _c_get_decl
 */
_str _java_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}
/**
 * @see _c_get_decl
 */
_str _cs_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                  _str decl_indent_string="",
                  _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}

///////////////////////////////////////////////////////////////////////////////
/**
 * @see _c_get_syntax_completions
 */
int _java_get_syntax_completions(var words)
{
   return _c_get_syntax_completions(words); 
}
int _cs_get_syntax_completions(var words)
{
   return _c_get_syntax_completions(words); 
}
int _cfscript_get_syntax_completions(var words)
{
   return _c_get_syntax_completions(words); 
}
int _phpscript_get_syntax_completions(var words)
{
   return _c_get_syntax_completions(words); 
}
int _idl_get_syntax_completions(var words)
{
   return _c_get_syntax_completions(words); 
}


///////////////////////////////////////////////////////////////////////////////
// Callbacks used by dynamic surround
//
/**
 * @see _c_is_continued_statement()
 */
boolean _cs_is_continued_statement()
{
   return _c_is_continued_statement();
}
boolean _js_is_continued_statement()
{
   return _c_is_continued_statement();
}
boolean _cfscript_is_continued_statement()
{
   return _c_is_continued_statement();
}
boolean _phpscript_is_continued_statement()
{
   return _c_is_continued_statement();
}
boolean _java_is_continued_statement()
{
   return _c_is_continued_statement();
}


_str java_get_jdk_jars(_str root = '') {

   if (root :== '') return root;
   _str jdk_jar_list = "";

   _maybe_append_filesep(root);
   _str jre_lib_jars = maybe_quote_filename(root:+"jre":+FILESEP:+"lib":+FILESEP:+"*.jar"); 
   _str cur_jar = file_match(jre_lib_jars'  -p +t', 1);
   for (;;) {
      if(cur_jar :== '') break;
      jdk_jar_list = jdk_jar_list :+ cur_jar :+ PATHSEP;
      cur_jar = file_match(cur_jar, 0);
   }
   return(jdk_jar_list);
}


// Automatically activate live errors if we can detect a valid JDK 6 (or later)
void java_maybe_activate_live_errors(){
   _str javahome = '';
#if __UNIX__
   _str javaList[];
   _str javaNamesList[];
   javahome=get_all_specific_JDK_paths("/usr:/opt:/app","1.6",javaList,javaNamesList);
   if (javahome != "") {
      int jdk_check = _check_java_installdir(javahome, true);
      if (jdk_check != 0) {
         return;
      }
   }
#else
   _str latest_subkey, major, minor, rest;
   _str regkeypath = 'SOFTWARE\JavaSoft\Java Development Kit';
   int result = _ntRegFindLatestVersion(HKEY_LOCAL_MACHINE,regkeypath,latest_subkey,1);
   if (result == 0) {
      parse latest_subkey with major '.' minor '.' rest;
      if (isinteger(minor)) {
         int min = (int)minor;
         if (min >= 6) {
           javahome=_ntRegQueryValue(HKEY_LOCAL_MACHINE,regkeypath'\'latest_subkey,'','JavaHome');
           if (javahome != "") {
              int jdk_check = _check_java_installdir(javahome, true);
              if (jdk_check != 0) {
                 return;
              }
           }
         }
      }
   }
#endif
   _maybe_append_filesep(javahome);
   _str java_name = javahome :+ 'bin' :+ FILESEP :+ 'java';
#if !__UNIX__
   java_name = java_name :+ '.exe';
#endif
   _str version = get_jdk_version_from_exe(maybe_quote_filename(java_name));
   if (version == "") {
      return;
   }
   boolean res = check_for_jdk_6(version);
   if (!res) {
      return;
   }
   def_java_live_errors_enabled = 1; 
   def_java_live_errors_jdk_6_dir = javahome; 
//   rteSetEnableJavaLiveErrors(def_java_live_errors_enabled);
}

_str java_get_jdk_classpath()
{
   if(def_java_live_errors_jdk_6_dir != "") {
      return(def_java_live_errors_jdk_6_dir);
   }
   _str jdk_jar_class_path = "";
   _str jdk_path;
   _str java_list[];

   getJavaIncludePath(java_list, jdk_path);
   if (jdk_path=='') {
      return(def_java_live_errors_jdk_6_dir);
   }

//   say("jdk_path="jdk_path);

   jdk_jar_class_path="";

   // look for the standard rt.jar

   // Avoid doing a tree list if possible.
   _str match=file_match('-p 'maybe_quote_filename(jdk_path:+"jre":+FILESEP:+"lib":+FILESEP:+"rt.jar"),1);
   if (match=='') {
      match=file_match('-p +t 'maybe_quote_filename(jdk_path:+"rt.jar"),1);
      if (match!='') {
         jdk_jar_class_path = match;
      } else {
         // Look for the MAC version of rt.jar
         match=file_match('-p +t 'maybe_quote_filename(jdk_path:+"classes.jar"),1);
         if (match!='') {
           _str dir = _strip_filename(match,'N');
   
            jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "charsets.jar" :+ PATHSEP;
            jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "classes.jar" :+ PATHSEP;
            jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "dt.jar" :+ PATHSEP;
            jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "jce.jar" :+ PATHSEP;
            jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "jsse.jar" :+ PATHSEP;
            jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "laf.jar" :+ PATHSEP;
            jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "sunrasign.jar" :+ PATHSEP;
            jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "ui.jar";
         } else {
            // Look for the IBM core.jar and add all of the separate jar files
            // that make up what should have been rt.jar and put them in the class path.
            match=file_match('-p +t 'maybe_quote_filename(jdk_path:+"core.jar"),1);
            if (match!='') {
               _str dir = _strip_filename(match,'N');
   
               jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "charsets.jar" :+ PATHSEP;
               jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "core.jar" :+ PATHSEP;
               jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "graphics.jar" :+ PATHSEP;
               jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "ibmjssefips.jar" :+ PATHSEP;
               jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "javaplugin.jar" :+ PATHSEP;
               jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "security.jar" :+ PATHSEP;
               jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "server.jar" :+ PATHSEP;
               jdk_jar_class_path = jdk_jar_class_path :+ dir :+ "xml.jar";
            } else {
               // Try the jre installed with slickedit.
            }
         }
      }
   }

   // DJB 03/08/2006 -- only set config_modify if absolutely necessary
   if (def_java_live_errors_enabled &&
       def_java_live_errors_jdk_6_dir != jdk_jar_class_path) {
      def_java_live_errors_jdk_6_dir = jdk_jar_class_path;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   return jdk_jar_class_path;
}

// Following are some functions to retrieve paths relevant to Java. Moved these from autotag.e
// so that they are generally accessible. -Parag Chandra 11/23/2004
/*
 Function Name:getJavaIncludePath

 Parameters:   None

 Author:       Chris Cunning

 Description:  Scans for the javac.exe in the path flag environment
               variable.  If located, it removes the bin and exits.  If
               not located, checks the registry for Specific Values

 Returns:      String containing the path to Visual Cafe's include files.

 */
void getJavaIncludePath(_str (&javaList)[],_str &JDKPath, _str (&javaNamesList)[] = null)
{
   JDKPath = '';
   _str javaPath ='';
   javaPath=get_Navigator_path();
   if (javaPath !='') {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_NETSCAPE;
      JDKPath=javaPath;
   }
   javaPath=get_jbuilder_path();
   if (javaPath !='') {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_JBUILDER;
      JDKPath=javaPath;
   }
   javaPath=get_vcafe_path();
   if (javaPath !='') {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_VISUALCAFE;
      JDKPath=javaPath;
   }
   javaPath=get_jpp_path();
   if (javaPath !='') {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_JPP;
      JDKPath=javaPath;
   }
   javaPath=get_Supercede_path();
   if (javaPath !='') {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_SUPERCEDE;
      JDKPath=javaPath;
   }
   javaPath=get_IBM_JDK_path();
   if (javaPath !='') {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_IBM;
      JDKPath=javaPath;
   }
   boolean found_a_jdk=false;
   if (isEclipsePlugin()) {
      javaPath = get_all_eclipse_jdk_paths(javaList, javaNamesList);
   }
#if __UNIX__
   if (_isMac()) {
      javaPath=get_all_specific_JDK_paths("/System/Library/Frameworks/JavaVM.framework/Versions","1.0:1.1:1.2:1.3:1.4:1.5:1.6:1.7:2.0:2.1",javaList,javaNamesList);
   } else {
      javaPath=get_all_specific_JDK_paths("/usr:/opt:/app","1.0:1.1:1.2:1.3:1.4:1.5:1.6:1.7:2.0:2.1",javaList,
                                          javaNamesList);
   }
#else
   javaPath=get_all_specific_JDK_paths("unused","1.0:1.1:1.2:1.3:1.4:1.5:1.6:1.7:2.0:2.1",javaList,javaNamesList);
//   say('javaPath1='javaPath);
#endif
   if (javaPath !='') {
      JDKPath=javaPath;
      found_a_jdk=true;
   }
   if (!found_a_jdk) {
      javaPath=get_JDK_path();
//      say('javaPath2='javaPath);
      if (javaPath !='') {
         _str java_exe = javaPath :+ "bin" :+ FILESEP "java";
         if (file_exists(java_exe)) {
            _str ver = get_jdk_version_from_exe(java_exe);
            javaNamesList[javaNamesList._length()] = COMPILER_NAME_SUN :+ " " :+ ver;
            javaList[javaList._length()]=javaPath;
            JDKPath=javaPath;
         }
      }
   }

   // try using the current path to find javac
   get_javac_from_path(javaList,JDKPath,javaNamesList);
//   say('JDKPath3='JDKPath);

   // try using their configured JDK directory
   get_javac_from_defvar(javaList,JDKPath,javaNamesList);
//   say('JDKPath4='JDKPath);
}

static _str get_Navigator_path()
{
#if __UNIX__
   /*
      We could add support for netscape java.
      Linux 7.2 install netscape with the following java files:

  284054   6-25-2001   6:32a -rw-r--r--  /usr/lib/netscape/java/classes/jae40.jar
  468592   6-25-2001   6:27a -rw-r--r--  /usr/lib/netscape/java/classes/ifc11.jar
  232092   6-25-2001   6:30a -rw-r--r--  /usr/lib/netscape/java/classes/iiop10.jar
 2249255   6-25-2001   6:46a -rw-r--r--  /usr/lib/netscape/java/classes/joptio40.jar
 1891638   6-25-2001   6:41a -rw-r--r--  /usr/lib/netscape/java/classes/java40.jar
  706114   6-25-2001   6:43a -rw-r--r--  /usr/lib/netscape/java/classes/jio40.jar
    6746   6-25-2001   5:53a -rw-r--r--  /usr/lib/netscape/java/classes/resource.jar
   18112   6-25-2001   6:47a -rw-r--r--  /usr/lib/netscape/java/classes/jsd10.jar
  252802   6-25-2001   6:49a -rw-r--r--  /usr/lib/netscape/java/classes/ldap40.jar
  239907   6-25-2001   6:50a -rw-r--r--  /usr/lib/netscape/java/classes/scd10.jar
    3415   7-02-1998   8:33p -rw-r--r--  /usr/lib/netscape/nethelp/picsfail.jar
   57089   6-25-2001   9:33a -r-xr-xr-x  /usr/lib/netscape/plugins/cpPack1.jar
   */
   return("");
#else
   _str javaPath=_ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Netscape\Netscape Navigator','Main','Java Directory');
   //HKEY_LOCAL_MACHINE\SOFTWARE\Netscape\Netscape Navigator\4.04 (en)\Main

   if (last_char(javaPath) != FILESEP && javaPath !='') {
      javaPath =javaPath:+FILESEP;
   }
   if (javaPath !='' && create_java_autotag_args(javaPath) == '') {
      javaPath = '';
   }
   return(javaPath);
#endif
}

static _str get_IBM_JDK_path()
{
#if __UNIX__
   return("");
#else
   _str javaPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\IBM\IBM Developer Kit, Java(TM) Tech. Edition\1.1.7','','JavaHome');

   if (last_char(javaPath) != FILESEP && javaPath !='') {
      javaPath =javaPath:+FILESEP;
   }
   if (javaPath !='' && create_java_autotag_args(javaPath) == '') {
      javaPath = '';
   }
   return(javaPath);
#endif
}

static _str get_Supercede_path()
{
#if __UNIX__
   return("");
#else
   _str javaPath=_ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\SuperCede\SuperCede','','Install Path');

   if (last_char(javaPath) != FILESEP && javaPath !='') {
      javaPath =javaPath:+FILESEP;
   }
   if (javaPath !='' && create_java_autotag_args(javaPath) == '') {
      javaPath = '';
   }
   return(javaPath);
#endif
}
static _str get_JDK_path(){
#if __UNIX__
   _str javaPath="/usr/java/";
   if (isdirectory(javaPath'/bin/')) {
      return(javaPath);
   }
   javaPath="/usr/local/java/";
   if (isdirectory(javaPath'/bin/')) {
      return(javaPath);
   }
   javaPath="/usr/jdk_base/";  // IBM 4.3.x
   if (isdirectory(javaPath'/bin/')) {
      return(javaPath);
   }
   javaPath="/opt/java/";
   if (isdirectory(javaPath'/bin/')) {
      return(javaPath);
   }
   javaPath="/app/java/";
   if (isdirectory(javaPath'/bin/')) {
      return(javaPath);
   }
   return("");
#else
   _str javaPath=_ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\JavaSoft\Java Development Kit','','JavaHome');

   if (last_char(javaPath) != FILESEP && javaPath !='') {
      javaPath =javaPath:+FILESEP;
   }
   if (javaPath !='' && create_java_autotag_args(javaPath) == '') {
      javaPath = '';
   }
   return(javaPath);
#endif
}

static _str get_all_eclipse_jdk_paths(_str (&javaList)[], _str (&javaNamesList)[]){
   _str eclipse_jdks = "";
   int ret_val = _eclipse_get_all_jdks(eclipse_jdks);
   _str cur_jdk;
   if (ret_val == 0) {
      while (eclipse_jdks != "") {
         if (pos(";", eclipse_jdks) >= 1) {
            parse eclipse_jdks with cur_jdk ";";
            eclipse_jdks = substr(eclipse_jdks,pos(";",eclipse_jdks)+1);
            _str name = get_jdk_from_root(cur_jdk);
            if (name != "") {
               javaList[javaList._length()] = cur_jdk; 
               javaNamesList[javaNamesList._length()] = name; 
            }
         }
      }
   }
   return("");
}

static _str get_all_specific_JDK_paths(_str base_dirs, _str jdk_versions, _str (&javaList)[], _str (&javaNamesList)[])
{
   // if we find anything, store it here
   _str found_path='';
   _str orig_base_dirs=base_dirs;

   // loop through the JDK versions
   while (jdk_versions != '') {
      _str jdk_version='';
      parse jdk_versions with jdk_version ':' jdk_versions;
      // try each base directory scheme
      while (base_dirs != '') {
         _str base_dir='';
         parse base_dirs with base_dir PATHSEP base_dirs;
         // try the version-specific lookup
         //say('get_all_specific_JDK_paths: jdk_version='jdk_version);
         _str javaPath=get_specific_JDK_path(base_dir,jdk_version);
         while (javaPath != '') {
            _str path='';
            //say('get_specific_JDK_path: javaPath='javaPath);
            parse javaPath with path PATHSEP javaPath;
            if( path != '' ) {
               //say('get_specific_JDK_path: path='path);
               _str name = get_jdk_name_from_path(path, jdk_version);
               javaNamesList[javaNamesList._length()] = name;
               javaList[javaList._length()]=path;
               found_path=path;
            }
         }
      }
      base_dirs=orig_base_dirs;
   }

   // if we got here and this is the mac, then we need to load this info in a special way
   if (_isMac() && (found_path == '')) {
      found_path = get_all_specific_JDK_paths_mac(javaList, javaNamesList);
   }

   return(found_path);
}

// http://developer.apple.com/library/mac/#releasenotes/Java/JavaSnowLeopardUpdate3LeopardUpdate8RN/NewandNoteworthy/NewandNoteworthy.html
static _str get_all_specific_JDK_paths_mac(_str (&javaList)[], _str (&javaNamesList)[])
{
   // we have to run "/usr/libexec/java_home --xml" to get the list of available JVMs
   int pid = 0;
   int status = 0;

   // create a temp file to capture the output
   _str outputFilename = mktemp();
   // set up the command to output the result
   //_str commandWithOutput = '/usr/libexec/java_home --xml > 'maybe_quote_filename(outputFilename)' 2>&1'; 
   _str commandWithOutput = '/usr/libexec/java_home --xml > 'maybe_quote_filename(outputFilename); 
   // shell the command
   _str shellProc = '/bin/sh';
   if (file_match('-p 'shellProc, 1) == '') {
      shellProc = path_search('sh');
      if (shellProc=='') {
         return '';
      }
   }
   status = shell(commandWithOutput, 'QP', shellProc, pid);
   // now load that XML output
   int xmlHandle = _xmlcfg_open(outputFilename, status, VSXMLCFG_OPEN_ADD_PCDATA);
   if (xmlHandle<0) {
      delete_file(outputFilename);
      return '';
   }
   _str jvmNodes[];
   // use a hashtable to store these so we don't store duplicate paths to the same JVM
   _str jvmCollection:[];
   _str jvm_version = '';
   _str jvm_home = '';
   // find all of the nodes that define a JVM
   _xmlcfg_find_simple_array(xmlHandle, '/plist/array/dict', jvmNodes);
   int i = 0;
   for (i = 0; i < jvmNodes._length(); i++) {
      int j = 0;
      _str keyNodes[];
      int jvmNode = (int)jvmNodes[i];
      jvm_version = '';
      jvm_home = '';
      // get all of the key nodes under the current JVM node
      _xmlcfg_find_simple_array(xmlHandle, 'key', keyNodes, jvmNode);
      for (j = 0; j < keyNodes._length(); j++) {
         int keyNode = (int)keyNodes[j];
         int valueNode = -1;
         _str keyName = '';
         int tempPCDataNode = _xmlcfg_get_first_child(xmlHandle, keyNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
         if (tempPCDataNode >= 0) {
            keyName = _xmlcfg_get_value(xmlHandle, tempPCDataNode);
         }
         if (strieq(keyName, 'JVMVersion') == true) {
            // get the version of the JVM
            valueNode = _xmlcfg_get_next_sibling(xmlHandle, keyNode);
            tempPCDataNode = _xmlcfg_get_first_child(xmlHandle, valueNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
            if (tempPCDataNode >= 0) {
               jvm_version = _xmlcfg_get_value(xmlHandle, tempPCDataNode);
            }
         } else if (strieq(keyName, 'JVMHomePath') == true) {
            // get the name of the JVM
            valueNode = _xmlcfg_get_next_sibling(xmlHandle, keyNode);
            tempPCDataNode = _xmlcfg_get_first_child(xmlHandle, valueNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
            if (tempPCDataNode >= 0) {
               _str tempPath = _xmlcfg_get_value(xmlHandle, tempPCDataNode);
               // strip the /home from the end of the path (we assume the parent directory)
                  if (strieq(_strip_filename(tempPath, 'p'), 'home') == true) {
                     tempPath = _strip_filename(tempPath, 'n');
               }
               _maybe_append_filesep(tempPath);
               // see if src.jar or classes.jar actually exists in this path
               _str tempSrcFilename = tempPath;
               tempSrcFilename :+= ('Home' :+ FILESEP :+ 'src.jar');
               if (file_exists(tempSrcFilename) == true) {
                  jvm_home = tempPath;
                  } else {
                   _str tempClassesFilename = tempPath;
                   tempClassesFilename :+= ('Classes' :+ FILESEP :+ 'classes.jar');
                   if (file_exists(tempClassesFilename) == true) {
                       jvm_home = tempPath;
                   }
               }
            }
         } 
      }
      // see if we have a name and a value
      if ((jvm_version != '') && (jvm_home != '')) {
         jvmCollection:[jvm_version] = jvm_home;
      }
   }
   // clean up after ourselves
   _xmlcfg_close(xmlHandle);
   delete_file(outputFilename);

   // if we find anything, store it here
   _str foundPath = '';
   // now just store the names and homes of the JVMs to be returned
   foreach (jvm_version => jvm_home in jvmCollection) {
      javaNamesList[javaNamesList._length()] = jvm_version;
      javaList[javaList._length()] = jvm_home;
      foundPath  = jvm_home;
   } 

   return foundPath;
}

static _str get_specific_JDK_path(_str base_dir, _str jdk_version)
{
#if __UNIX__
   _str javaPath=base_dir:+"/java":+jdk_version:+FILESEP;
   if (isdirectory(javaPath)) {
      return(javaPath);
   }
   if (_isMac()) {
      // The macintosh has things installed under the base dir:  /System/Library/Frameworks/JavaVM.framework/Versions
      // For example: /System/Library/Frameworks/JavaVM.framework/Versions/1.4.2/
      javaPath='';
      _str searchStr=base_dir:+FILESEP:+jdk_version:+"*";
      // say('get_specific_JDK_path: searchStr='searchStr);
      _str filename=file_match("+D +X -P ":+searchStr,1);
      // say('get_specific_JDK_path: findFirst='filename);
      for (;;) {
         if (filename=='=' || filename=='' )  break;
         if (filename!="" && last_char(filename)==FILESEP && file_exists(filename:+'Home':+FILESEP:+'src.jar')) {
            javaPath=javaPath:+':':+filename;
         }
         // Be sure to pass filename with correct path.
         // Result filename is built with path of given file name.
         filename=file_match(filename,0);       // find next.
         // say('get_specific_JDK_path: findNext='filename);
      }
      return(javaPath);
   }
   // Sometimes the JDK is installed under /usr/java/
   // For example: /usr/java/jdk1.3.0_02/
   javaPath=base_dir:+"/java":+FILESEP:+"jdk":+jdk_version:+"*";
   javaPath=file_match("+D +X +P ":+javaPath,1);
   if (javaPath!="" && isdirectory(javaPath)) {
      return(javaPath);
   }
   // When the linux 1.4 beta 3 installed, it used j2sdk and not jdk as the directory prefix
   // Linux 1.3 install used jdk as the directory prefix
   javaPath=base_dir:+"/java":+FILESEP:+"j2sdk":+jdk_version:+"*";
   javaPath=file_match("+D +X +P ":+javaPath,1);
   if (javaPath!="" && isdirectory(javaPath)) {
      return(javaPath);
   }
   // Solaris 2.8 puts things in /opt/j2sdk1.4.0
   javaPath=base_dir:+FILESEP:+"j2sdk":+jdk_version:+"*";
   javaPath=file_match("+D +X +P ":+javaPath,1);
   if (javaPath!="" && isdirectory(javaPath)) {
      return(javaPath);
   }
   // Java 1.5 jdk wants to go in /opt/jdk1.5.0
   javaPath=base_dir:+FILESEP:+"jdk":+jdk_version:+"*";
   javaPath=file_match("+D +X +P ":+javaPath,1);
   if (javaPath!="" && isdirectory(javaPath)) {
      return(javaPath);
   }

   return("");
#else
   _str javaPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\JavaSoft\Java Development Kit\'jdk_version,'','JavaHome');
   if (javaPath=='') {
      return('');
   }
   _maybe_append_filesep(javaPath);
   if (!file_exists(javaPath'bin':+FILESEP:+'javac.exe')) {
      // JavaHome is broken in the JDK 1.4 beta 2
      // Instead it points to the JRE which does not have the javac compiler.
      // Try java.exe even though we could get the wrong thing.
      _str javaexe=_ntRegQueryValue(
         HKEY_LOCAL_MACHINE,
         'Software\Microsoft\Windows\CurrentVersion\App Paths\java.exe',
         ""  // DefaultValue
         );
      if (javaexe=="") {
         return("");
      }
      javaPath=_strip_filename(javaexe,'N');
      if (!file_exists(javaPath'javac.exe')) {
         return("");
      }
      // Strip the 'bin' directory
      javaPath=substr(javaPath,1,length(javaPath)-1);
      javaPath=_strip_filename(javaPath,'N');
   }
   if (javaPath !='' && create_java_autotag_args(javaPath) == '') {
      javaPath = '';
   }
   return(javaPath);
#endif
}

_str get_jdk_version_from_exe(_str exe = ''){
   _str temp = mktemp();
   int status = shell(exe:+' -version 2> ':+maybe_quote_filename(temp), 'Q');
   if (status == 0) {
      int temp_wid, orig_wid;
      _open_temp_view(maybe_quote_filename(temp), temp_wid, orig_wid);
      _str line, ver;
      get_line(line);
      parse line with 'java version "'ver'"';
      _delete_temp_view(temp_wid);
      p_window_id = orig_wid;
      return(ver);
   }
   return("");
}
_str get_jdk_name_from_path(_str path, _str jdk_version){
   int start = pos(jdk_version:+"*", path, 1, 'R');
   if (!start) {
      return ('');
   }
   _str temp_str = substr(path, start);
   int len = pos(FILESEP,temp_str) - 1;
   return(COMPILER_NAME_SUN :+ " " :+ substr(path,start,len));
}

_str get_jdk_from_root(_str root_dir = ''){
   _str name= '';
   _str java_exe = root_dir:+ "bin" :+ FILESEP :+ "java.exe"; 
   if (file_exists(java_exe)) {
      _str ver = get_jdk_version_from_exe(maybe_quote_filename(java_exe)); 
      name = COMPILER_NAME_SUN :+ " " :+ ver;
   }
   return (name);
}

void get_javac_from_path( _str (& javaList)[], _str &JDKPath, _str (&javaNamesList)[])
{
   _str javaPath='';
#if __UNIX__
/*   javaPath = path_search("javac");
   if (javaPath == "") return;
   //javaPath = absolute(javaPath);  // resolve symbollic links
   javaPath = strip_filename(javaPath, "N");
   if (javaPath=='/usr/bin/') {*/
      /*
         Linux 7.2 install javac in /usr/bin/.  This is not a
         standard Java installation.

         /usr/bin/javac actually runs   "/usr/lib/kaffe/Kaffe"

         /usr/bin/java actually runs   "/usr/lib/kaffe/Kaffe"

         which requires the libraries in

           /usr/share/libgcj.jar  -- Most run-times
           ???/usr/share/libgcj.zip  -- We think this is an old version of the class files
           /usr/share/kaffe/<*>.jar  -- more run-times
           /usr/share/pgsql/jdbc7.0-1.1.jar
           /usr/share/pgsql/jdbc7.1-1.2.jar
      */
/*      if (file_exists('/usr/share/libgcj.jar')) {
         javaList[javaList._length()]= '/usr/share/';
         return;
      }
      return;
   }
   javaPath = substr(javaPath,1,length(javaPath)-1);
   javaPath = strip_filename(javaPath, "N");
   if (javaPath == "") return;
   javaList[javaList._length()]= javaPath;
   JDKPath=javaPath;*/
#else
   javaPath=path_search("javac.exe","PATH","P");
   if (javaPath!='') {
      _str dir = _strip_filename(javaPath, "N");
      _str java_exe = maybe_quote_filename(dir :+ "java.exe");
      _str ver = '';
      if (file_exists(java_exe)) {
         ver = get_jdk_version_from_exe(java_exe);
      } 
      _str javaPath2= substr(javaPath,1,(pathlen(javaPath)-1));
      _str subdirname=_strip_filename(javaPath2,'PDE');
      if (file_eq(subdirname,'bin')) {
         javaPath=_strip_filename(javaPath2,'N');
         javaPath=_strip_filename(javaPath, 'NE');
         if (ver :!= '') {
            _str name = COMPILER_NAME_SUN :+ " " :+ ver;
            javaNamesList[javaNamesList._length()] = name;
            javaList[javaList._length()]= javaPath;
            JDKPath=javaPath;
         }
/*         javaList[javaList._length()]= javaPath;
         JDKPath=javaPath;*/
      }
   }
#endif
}

void get_javac_from_defvar( _str (& javaList)[], _str &JDKPath, _str (&javaNamesList)[])
{
   _str javaPath=def_jdk_install_dir;
   if (javaPath!='') {
      _maybe_append_filesep(javaPath);
      _str javaPath2= javaPath:+"bin";
#if __UNIX__
     _str java_name = "java";
#else
      _str java_name = "java.exe";
#endif
      _str java_exe= maybe_quote_filename(javaPath2 :+ FILESEP :+ java_name);
      if (file_exists(java_exe)) {
         _str ver = get_jdk_version_from_exe(java_exe);
         if (ver != "") {
            javaNamesList[javaNamesList._length()] = COMPILER_NAME_SUN :+ " " :+ ver;
            javaList[javaList._length()]=javaPath;
            JDKPath=javaPath;
         }
      }
   }
}

static _str clean_javaPath( _str javaPath)
{
   if ( javaPath != '' ) {
      javaPath=strip(javaPath,'B','"');
      //strip off the javac.exe "%1" arguments
      javaPath=_strip_filename(javaPath,'N');

      //If the last subdirectory in the path is bin, strip it off
      if (last_char(javaPath) == FILESEP && javaPath !='') {
         _str javaPath2= substr(javaPath,1,(pathlen(javaPath)-1));
         _str subdirname=_strip_filename(javaPath2,'PDE');
         if (file_eq(subdirname,'bin')) {
            javaPath=_strip_filename(javaPath2,'N');
         } else {
            javaPath='';
         }
      }
      if (javaPath!='') {
         if (!isdirectory(javaPath)) {
            javaPath='';
         }
      }
   }
   return(javaPath);

}

static _str get_vcafe_path()
{
#if __UNIX__
   return("");
#else
   //Check for Visual Cafe
   _str javaPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Classes\VisualCafeProject.Document\shell\open\command','');
   if (javaPath != '') {
      javaPath=clean_javaPath(javaPath);

   }
   if (javaPath !='' && create_java_autotag_args(javaPath) == '') {
      javaPath = '';
   }
   return(javaPath);
#endif
}

static _str get_jbuilder_path()
{
#if __UNIX__
   return("");
#else
   //Check for JBuilder 3
   _str javaPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Classes\JBuilder.Project\Shell\Open\Command','');
   //Check for JBuilder
   if (javaPath=='') {
      javaPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Classes\JBuilder.ProjectFile\Shell\Open\Command','');
   }
   if (javaPath !='') {
      javaPath=clean_javaPath(javaPath);
   }
   if (javaPath !='' && create_java_autotag_args(javaPath) == '') {
      javaPath = '';
   }
   return(javaPath);
#endif
}

static _str get_jpp_path()
{
#if __UNIX__
   return("");
#else
   //Check for J++ 6.0
   _str javaPath,javaPath2='';
   int status=_ntRegFindValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\Java VM','LibsDirectory',javaPath);
   if (javaPath!="" && last_char(javaPath)==FILESEP) {
      javaPath=substr(javaPath,1,length(javaPath)-1);
   }
   if (javaPath!="") {
      javaPath=_replace_envvars(javaPath);
      javaPath=_strip_filename(javaPath,'N');
   }
   if (javaPath != '') {
      javaPath2= javaPath:+'Packages';
      if (isdirectory(javaPath2)) {
         javaPath2= javaPath2:+FILESEP:+'*.zip';
         if ((file_match(maybe_quote_filename(javaPath2):+'  -p',1)) !='') {
            if (javaPath !='' && create_java_autotag_args(javaPath) == '') {
               javaPath = '';
            }
            return(javaPath);
         }
      }
   }
   //Check for J++ 1.0
   if (javaPath != '') {
      //javaPath=javaPath:+'Java':+FILESEP;
      if (isdirectory(javaPath)) {
         javaPath2=javaPath2:+'classes':+FILESEP:+'classes.zip';
         if ((file_match(maybe_quote_filename(javaPath2)'  -p',1))== '') {
            javaPath='';
         }
      } else {
         javaPath="";
      }
   }
   if (create_java_autotag_args(javaPath) == '') {
      javaPath = '';
   }

   return(javaPath);
#endif
}

/** 
 * 
 * 
 * @param javaPath
 * 
 * @return _str
 */
_str CheckForUserInstalledJava(_str javaPath)
{
   _str match=file_match('-p +t 'maybe_quote_filename(javaPath:+"String.java"),1);
   if (match!="") {
      return(javaPath:+'*.java');
   }else{
      match=file_match('-p +t 'maybe_quote_filename(javaPath:+"src.zip"),1);
      if (match!='') {
         return(match);
      }else{
         match=file_match('-p +t 'maybe_quote_filename(javaPath:+"src.jar"),1);
         if (match!='') {
            return(match);
         }else{
            match=file_match('-p +t 'maybe_quote_filename(javaPath:+"rt.jar"),1);
            if (match!='') {
               return(match);
            }else{
               match=file_match('-p +t 'maybe_quote_filename(javaPath:+"classes.zip"),1);
               if (match!='') {
                  return(match);
               }
            }
         }
      }
   }
   return('');
}

/*
 Function Name:create_java_autotag_args

 Parameters:  javaPath

 Description: determines what argument paths should be set for make_tags

 Returns:     the command argument for make_tags

 */
_str create_java_autotag_args(_str javaPath/*,boolean find_jdk=false*/)
{
   _str include_path='';
   _str cmdargs='';
   boolean JppFlag=0;
   boolean LibsFound=0;
   _maybe_append_filesep(javaPath);

#if __UNIX__
   if (_isMac()) {
      include_path=javaPath;
      if( isdirectory(include_path:+'Home':+FILESEP) && file_exists(include_path:+'Home':+FILESEP:+'src.jar') ) {
         // Tiger, Leopard, and early Snow Leopard installations
         cmdargs=cmdargs:+' 'maybe_quote_filename(include_path):+'Home':+FILESEP:+'src.jar';
      } else if( isdirectory(include_path:+'Home':+FILESEP) && file_exists(include_path:+'Classes':+FILESEP:+'classes.jar') ) {
         // Later Snow Leopard and Lion installations
         cmdargs=cmdargs:+' 'maybe_quote_filename(include_path):+'Classes':+FILESEP:+'classes.jar';
      }
      return cmdargs;
   } else {
      //Get the .java files from the src subdirectory
      include_path=javaPath:+'src':+FILESEP;
      //SrcFound=0;
      if ( isdirectory(include_path) ) {
         cmdargs=cmdargs:+' "'include_path:+'*.java"';
         //SrcFound=1;
      } else if (isdirectory(javaPath'java') &&
                 isdirectory(javaPath'javax') &&
                 isdirectory(javaPath'com')) {
         include_path=javaPath;
         //cmdargs=cmdargs:+' "'include_path:+'*.java"';
         // this line was necessary to exclude adding the demo directory to the java tag file
         cmdargs=cmdargs:+' "'include_path:+'sunw':+FILESEP:+'*.java"':+
                          ' "'include_path:+'javax':+FILESEP:+'*.java"':+
                          ' "'include_path:+'org':+FILESEP:+'*.java"':+
                          ' "'include_path:+'java':+FILESEP:+'*.java"':+
                          ' "'include_path:+'com':+FILESEP:+'*.java"';
         //SrcFound=1;
      } else {
         //If there is no src subdirectory, get the src.jar file
         include_path=javaPath;
         include_path=include_path:+'src.zip';
         if (file_exists(include_path)) {
            cmdargs=cmdargs:+' 'maybe_quote_filename(include_path);
            //SrcFound=1;
         } else {
            include_path=javaPath;
            include_path=include_path:+'src.jar';
            if (file_exists(include_path)) {
               cmdargs=cmdargs:+' 'maybe_quote_filename(include_path);
               //SrcFound=1;
            } else {
               _str last_effort = CheckForUserInstalledJava(javaPath);
              if (last_effort != '' && last_effort != ' ') {
                 cmdargs = cmdargs :+ ' 'maybe_quote_filename(last_effort);
              }
            }
         }
      }
      if (cmdargs=='') {
         //say('h1 javaPath='javaPath);
         if(file_exists(javaPath:+'libgcj.jar') && isdirectory(javaPath:+'kaffe')) {
            //say('h2');
            //Could add usr/share/pgsql/jdbc7.0-1.1.jar  OR usr/share/pgsql/jdbc7.1-1.2.jar
            cmdargs=cmdargs:+' 'maybe_quote_filename(javaPath:+'libgcj.jar'):+' ':+
               maybe_quote_filename(javaPath:+'kaffe':+FILESEP:+'*.jar');
            //say(cmdargs);
         }
      }
      return(cmdargs);
   }
#else
   _str test_javaPath='';
   int status=_ntRegFindValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\Java VM','LibsDirectory',test_javaPath);
   if (test_javaPath!='') {
      if (test_javaPath!="" && last_char(test_javaPath)==FILESEP) {
         test_javaPath=substr(test_javaPath,1,length(javaPath)-1);
      }
      test_javaPath=_replace_envvars(test_javaPath);
      test_javaPath=_strip_filename(test_javaPath,'N');

      if (last_char(test_javaPath)!=FILESEP) {
         test_javaPath=test_javaPath:+FILESEP;
      }
      JppFlag=file_eq(test_javaPath,javaPath);
   }
   if (JppFlag) {
      include_path = javaPath:+'Packages':+FILESEP;
      if (isdirectory(include_path)) {
         cmdargs=cmdargs:+' "':+include_path:+'*.zip"';
         if ((file_match(maybe_quote_filename(include_path:+'*.zip'):+' -p',1))!='') {
            //messageNwait('cmdargs 'cmdargs);
            return(cmdargs);
         }
      }
      include_path = javaPath:+'Classes':+FILESEP;
      if (isdirectory(include_path)) {
         cmdargs=cmdargs:+' "':+include_path:+'classes.zip"';
         if ((file_match(maybe_quote_filename(include_path:+'classes.zip'):+' -p',1))!='') {
            //messageNwait('cmdargs2 'cmdargs);
            return(cmdargs);
         }
      }
   }
   //Vcafe, Jbuilder, and J++ you have to add the java subdirectory
   // if we retrieved the value from the registry.
   if (last_char(javaPath) == FILESEP) {
      _str javaPath2= substr(javaPath,1,(pathlen(javaPath)-1));
      _str subdirname=_strip_filename(javaPath2,'P');
      if (!file_eq(subdirname,'java')) {
         javaPath2=javaPath:+'java':+FILESEP;
         // added for the case where the JDK 1.4 has no src subdir in it
         // such that there is a java sun and com directory under the jdk dir
         if (isdirectory(javaPath2) && !isdirectory(javaPath:+'com':+FILESEP)) {
            javaPath=javaPath2;
         }
      }
   }
   //It's not Supercede, so its JDK, VCafe, or Jbuilder

   //Get the .java files from the src subdirectory
   include_path=javaPath:+'src':+FILESEP;
   if ( isdirectory(include_path) ) {
      cmdargs=cmdargs:+' "'include_path:+'*.java"';
      LibsFound=1;
   } else if (isdirectory(javaPath'java') &&
              isdirectory(javaPath'javax') &&
              isdirectory(javaPath'com')) {
      // what should i do for this case?
      include_path=javaPath;
      //cmdargs=cmdargs:+' "'include_path:+'*.java"';
      // this line was necessary to exclude adding the demo directory to the java tag file
      cmdargs=cmdargs:+' "'include_path:+'sunw':+FILESEP:+'*.java"':+
                       ' "'include_path:+'javax':+FILESEP:+'*.java"':+
                       ' "'include_path:+'org':+FILESEP:+'*.java"':+
                       ' "'include_path:+'java':+FILESEP:+'*.java"':+
                       ' "'include_path:+'com':+FILESEP:+'*.java"';
      LibsFound=1;
   } else {
      //If there is no src subdirectory, get the src.jar file
      include_path=javaPath;
      include_path=include_path:+'src.zip';
      if (file_exists(include_path)) {
         cmdargs=cmdargs:+' 'maybe_quote_filename(include_path);
         LibsFound=1;
      } else {
         include_path=javaPath;
         include_path=include_path:+'src.jar';
         if (file_exists(include_path)) {
            cmdargs=cmdargs:+' 'maybe_quote_filename(include_path);
            LibsFound=1;
         }
      }
   }
   if (!LibsFound) {
      //Get the classes.zip file from the lib subdirectory
      include_path=javaPath:+'lib':+FILESEP;
      if ( isdirectory(include_path)) {
         // JDK 1.1, 1.2, JBuilder
         if (file_match(maybe_quote_filename(include_path:+'classes.zip')' -p',1)!= '') {
            cmdargs=cmdargs:+' "'include_path:+'classes.zip"';
            LibsFound=true;
         }
         if (file_match(maybe_quote_filename(include_path:+'*.jar'),1)!= '') {
            cmdargs=cmdargs:+' "'include_path:+'*.jar"';
            LibsFound=true;
         }
         include_path=javaPath:+'jre':+FILESEP:+'lib':+FILESEP;
         if ( isdirectory(include_path)) {
            if (file_match(maybe_quote_filename(include_path:+'*.jar'),1)!= '') {
               cmdargs=cmdargs:+' "'include_path:+'*.jar"';
               LibsFound=true;
            }
         }
         include_path=javaPath:+'jre':+FILESEP:+'lib':+FILESEP:+'ext':+FILESEP;
         if ( isdirectory(include_path)) {
            if (file_match(maybe_quote_filename(include_path:+'*.jar'),1)!= '') {
               cmdargs=cmdargs:+' "'include_path:+'*.jar"';
               LibsFound=true;
            }
         }
      }
      if (!LibsFound) {
         // Visual Cafe
         include_path=javaPath:+'classes':+FILESEP;
         if ( isdirectory(include_path)) {
            LibsFound=true;
            cmdargs=cmdargs:+' "'include_path:+'*.jar"';
         }
      }
   }
   if (!LibsFound) {
      //Check for SuperCede
      include_path=javaPath:+'jre':+FILESEP;
      if (isdirectory(include_path)) {
         //We are dealing with Supercede, so we need the .jar files
         cmdargs=cmdargs:+' "'include_path:+'*.jar"';
      }
   }
   return(cmdargs);
#endif
}


_str create_cpp_autotag_args(_str cppPath)
{
   //Gather the arguments for make_tags
   _str cmdargs='';
   int vcppFlag=0;
   _str include_path='';
   _maybe_append_filesep(cppPath);

#if __UNIX__
   include_path=cppPath;
   cmdargs=cmdargs:+' "'include_path:+'*.h"';
   cmdargs=cmdargs:+' "'include_path:+'*.cc"';
   cmdargs=cmdargs:+' "'include_path:+'*.tcc"';
   _str noext_files=_get_langext_files();
   for (;;) {
      _str curfile=parse_file(noext_files);
      if (curfile=='') break;
      cmdargs=cmdargs' 'maybe_quote_filename(include_path:+curfile);
   }
   return(cmdargs);
#else
   if ( file_eq(cppPath,getVcppIncludePath7()) ) {

      _str vcppPathInfo =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.0\VC\VC_OBJECTS_PLATFORM_INFO\Win32\Directories','','Include Dirs');
      _str installDir =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.0\Setup\VC','','ProductDir');
      _str frameworkDir =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\.NETFramework','', 'sdkInstallRoot');
      _maybe_append_filesep(frameworkDir);

      vcppPathInfo=stranslate(vcppPathInfo,installDir,'$(VCInstallDir)');
      vcppPathInfo=stranslate(vcppPathInfo,frameworkDir,'$(FrameworkSDKDir)');
      for (;;) {
         parse vcppPathInfo with include_path (PATHSEP) vcppPathInfo;
         if (include_path=='') break;
         if ( isdirectory(include_path) ) {
            _maybe_append_filesep(include_path);
            //add the relevant files from the Visual C++ include directory
            cmdargs=cmdargs:+' "'include_path:+'*."';
            cmdargs=cmdargs:+' "'include_path:+'*.h"';
            cmdargs=cmdargs:+' "'include_path:+'*.hpp"';
            cmdargs=cmdargs:+' "'include_path:+'*.hxx"';
            cmdargs=cmdargs:+' "'include_path:+'*.inl"';
         }
      }
      return(cmdargs);
   } else if ( file_eq(cppPath,getVcppIncludePath2003()) ) {

      _str vcppPathInfo =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.1\VC\VC_OBJECTS_PLATFORM_INFO\Win32\Directories','','Include Dirs');
      _str installDir =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.1\Setup\VC','','ProductDir');
      _str frameworkDir =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\.NETFramework','','sdkInstallRoot');
      _maybe_append_filesep(frameworkDir);

      vcppPathInfo=stranslate(vcppPathInfo,installDir,'$(VCInstallDir)');
      vcppPathInfo=stranslate(vcppPathInfo,frameworkDir,'$(FrameworkSDKDir)');
      for (;;) {
         parse vcppPathInfo with include_path (PATHSEP) vcppPathInfo;
         if (include_path=='') break;
         if ( isdirectory(include_path) ) {
            _maybe_append_filesep(include_path);
            //add the relevant files from the Visual C++ include directory
            cmdargs=cmdargs:+' "'include_path:+'*."';
            cmdargs=cmdargs:+' "'include_path:+'*.h"';
            cmdargs=cmdargs:+' "'include_path:+'*.hpp"';
            cmdargs=cmdargs:+' "'include_path:+'*.hxx"';
            cmdargs=cmdargs:+' "'include_path:+'*.inl"';
         }
      }
      return(cmdargs);
   }
   // IF NOT borland C++
   if (!isdirectory(cppPath:+'VCL')) {
      //We are tagging Visual C++
      vcppFlag=1;
   }
   include_path=cppPath:+'include' FILESEP;
   if ( isdirectory(include_path) ) {
      //add the relevant files from the Visual C++ include directory
      cmdargs=cmdargs:+' "'include_path:+'*."';
      cmdargs=cmdargs:+' "'include_path:+'*.h"';
      cmdargs=cmdargs:+' "'include_path:+'*.hpp"';
      cmdargs=cmdargs:+' "'include_path:+'*.hxx"';
      cmdargs=cmdargs:+' "'include_path:+'*.inl"';

   }
   include_path=cppPath:+'usr':+FILESEP:+'include':+FILESEP;
   if ( isdirectory(include_path) ) {
      //add the relevant files from the Gnu Cygwin directory
      cmdargs=cmdargs:+' "'include_path:+'*."';
      cmdargs=cmdargs:+' "'include_path:+'*.h"';
      cmdargs=cmdargs:+' "'include_path:+'*.cc"';
      cmdargs=cmdargs:+' "'include_path:+'*.tcc"';

   }
   if (vcppFlag) {
      include_path=cppPath:+'mfc' FILESEP;
      if ( isdirectory(include_path) ) {
         //Add the relevant files from the MFC directory
         cmdargs=cmdargs:+' "'include_path:+'*.h"';
         cmdargs=cmdargs:+' "'include_path:+'*.cpp"';
      }

      include_path=cppPath:+'atl' FILESEP;
      if ( isdirectory(include_path) ) {
         //Add the relevant files from the ATL directory
         cmdargs=cmdargs:+' "'include_path:+'*.h"';
         cmdargs=cmdargs:+' "'include_path:+'*.cpp"';
      }
      include_path=cppPath:+'crt' FILESEP;
      if ( isdirectory(include_path) ) {
         //Add the relevant files from the ATL directory
         cmdargs=cmdargs:+' "'include_path:+'*."';
         cmdargs=cmdargs:+' "'include_path:+'*.h"';
         cmdargs=cmdargs:+' "'include_path:+'*.c"';
         cmdargs=cmdargs:+' "'include_path:+'*.cpp"';
      }
   }
   return(cmdargs);
#endif
}

/**
 * @return Returns the path to Borland C++ Builder (6.0) using
 *         the registry, and failing that, by finding bcb.exe
 *         using the PATH environment variable.
 */
static _str get_BCB_path()
{
#if __UNIX__
   return("");
#else
   //Check to see if it is in the registry
   //HKEY_LOCAL_MACHINE\SOFTWARE\Borland\C++Builder
   _str BCBPath=_ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Borland\C++Builder','','RootDir');
   if (BCBPath!="") {
      if (last_char(BCBPath) != FILESEP) {
         BCBPath =BCBPath:+FILESEP;
      }
      if (create_cpp_autotag_args(BCBPath) == '') {
         return('');
      }
   }

   //Check and see if the executable is in the path
   if (BCBPath=='') {
      BCBPath=path_search("bcb.exe","Path","P");
      if (BCBPath!='') {
         //If found, strip  'bin' off the path.
         _str BCBPath2= substr(BCBPath,1,(pathlen(BCBPath)-1));
         _str subdirname=_strip_filename(BCBPath2,'PDE');
         if (file_eq(subdirname,'bin')) {
            BCBPath=_strip_filename(BCBPath2,'N');
            BCBPath=_strip_filename(BCBPath, 'NE');
            return(BCBPath);
         }
      }
   }

   return(BCBPath);
#endif
}

/**
 * @return Returns the path to Borland C++ BuilderX (1.0) using
 *         the registry, and failing that, by finding bcb.exe
 *         using the PATH environment variable.
 */
static _str get_BCBX_path()
{
#if __UNIX__
   return("");
#else

   //Check to see if it is in the registry
   //HKEY_LOCAL_MACHINE\SOFTWARE\Borland\C++BuilderX\
   _str BCBPath=_ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Borland\C++BuilderX','','PathName');
   if (BCBPath!="") {
      if (last_char(BCBPath) != FILESEP) {
         BCBPath =BCBPath:+FILESEP;
      }
      if (create_cpp_autotag_args(BCBPath) == '') {
         return('');
      }
   }

   //Check and see if the executable is in the path
   if (BCBPath=='') {
      BCBPath=path_search("CBuilderW.exe","Path","P");
      if (BCBPath!='') {
         //If found, strip  'bin' off the path.
         _str BCBPath2= substr(BCBPath,1,(pathlen(BCBPath)-1));
         _str subdirname=_strip_filename(BCBPath2,'PDE');
         if (file_eq(subdirname,'bin')) {
            BCBPath=_strip_filename(BCBPath2,'N');
            BCBPath=_strip_filename(BCBPath, 'NE');
            return(BCBPath);
         }
      }
   }

   return(BCBPath);
#endif
}

/*
 Function Name:get_cc_path

 Parameters:  None

 Description: Gets the path to the given executable from the PATH
              environment variable.

 Returns:     path to given compiler name
*/
static _str get_cc_path(_str exe_name)
{
   //Check and see if the executable is in the path
   _str CCPath=path_search(exe_name,"PATH","P");
   if (CCPath!='') {
      //If found, strip  'bin' off the path.
      _str CCPath2= substr(CCPath,1,(pathlen(CCPath)-1));
      _str subdirname=_strip_filename(CCPath2,'PDE');
      if (file_eq(subdirname,'bin')) {  
         CCPath=_strip_filename(CCPath2,'N');
         CCPath=_strip_filename(CCPath, 'NE');
      }
   }
   return(CCPath);
}

/*
 Function Name:get_Cygwin_path

 Parameters:   None

 Author:       Chris Cunning

 Description:  Checks the registry for Cygnus Cygwin C++
               by checking in the registry.

 Returns:      String containing the path to Cygwin's C++'s include files.

 */
static _str get_Cygwin_path ()
{
#if __UNIX__
   return("");
#else
   _str cygwinPath = _cygwin_path();
   if (cygwinPath!="") {
      if (create_cpp_autotag_args(cygwinPath) == '') {
         if (!(isdirectory(cygwinPath:+'usr':+FILESEP) || isdirectory(cygwinPath:+'lib':+FILESEP))) {
            cygwinPath = '';
         }
      }
   }
   return(cygwinPath);
#endif
}

/*
 Function Name:get_LCC_path

 Parameters:   None

 Author:       Chris Cunning

 Description:  Checks the registry for LCC ANSI C Compiler
               by checking in the registry.

 Returns:      String containing the path to LCC's include files.

 */
static _str get_lcc_path ()
{
#if __UNIX__
   return("");
#else
   lccPath := _ntRegQueryValue(HKEY_CURRENT_USER, 'Software\lcc\Compiler', '', 'includepath');

   if (lccPath == '') {
      // that key is not there, probably
      return("");
   }

   if (lccPath!='') {
      if (last_char(lccPath)==FILESEP) {
         lccPath = substr(lccPath,1,length(lccPath)-1);
      }
      lccPath=_strip_filename(lccPath,'N');
   }
   if (lccPath!="") {
      if (create_cpp_autotag_args(lccPath) == '') {
         lccPath = '';
      }
      return(lccPath);
   }
   return(lccPath);
#endif
}

/*
 Function Name:getCppIncludePath

 Parameters:  cppList:  The list of Cpp paths

 Description: Gathers the list of C++ IDE paths

 Returns:     None

 */

/*
 Function Name:getVcppIncludePath

 Parameters:   None

 Author:       Chris Cunning

 Description:  Scans for the spyxx.exe in the path flag environment
               variable.  If located, it removes the bin and exits.  If
               not located, checks the registry for MSDEV.EXE.  If it
               fails to located the directory in the default listing,
               it will search for stdio.h, assuming that it will find
               it in the Visual C++ include directory

 Returns:      String containing the path to Visual C++'s include files.

 */
_str getVcppIncludePath6()
{
#if __UNIX__
   return("");
#else
   _str vcppPath2,subdirname;
   _str vcppPath =_ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\DevStudio','Products\Microsoft Visual C++','ProductDir');
   if (last_char(vcppPath) != FILESEP && vcppPath !='') {
      vcppPath =vcppPath:+FILESEP;
   }
   if (vcppPath!="") {
      vcppPath=_replace_envvars(vcppPath);
      if (create_cpp_autotag_args(vcppPath) == '') {
         vcppPath = '';
      }
      return(vcppPath);
   }
   //Check the registry for msdev's location
   vcppPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Classes\mdpfile\shell\open\command','');
   //If there are any quotes on, we want to strip them off
   vcppPath=strip(vcppPath,'B','"');
   if ( vcppPath != '' ) {
      //strip off the msdev.exe "%1" arguments
      vcppPath=_replace_envvars(vcppPath);
      vcppPath=_strip_filename(vcppPath,'N');

      //If the last subdirectory in the path is bin, strip it off
      if (last_char(vcppPath) == FILESEP) {
         vcppPath2= substr(vcppPath,1,(pathlen(vcppPath)-1));
         subdirname=_strip_filename(vcppPath2,'PDE');
         if (file_eq(subdirname,'bin')) {
            vcppPath=_strip_filename(vcppPath2,'N');
         } else {
            vcppPath='';
         }
      }

      if (vcppPath!='') {
         //If the last subdirectory in the path is SharedIDE, strip it off
         if (last_char(vcppPath) == FILESEP) {
            vcppPath2= substr(vcppPath,1,(pathlen(vcppPath)-1));
            subdirname=_strip_filename(vcppPath2,'PDE');
            if (file_eq(subdirname,'SharedIDE')) {
               //We have version 5.0 or greater
               vcppPath=_strip_filename(vcppPath2,'N');
               //Add The default pathname for Visual C++
               vcppPath= vcppPath:+'vc' FILESEP;
            }
         }

         if (isdirectory(vcppPath) && create_cpp_autotag_args(vcppPath) != '') {
            return(vcppPath);
         } else {
            vcppPath='';
         }
      }

   }
   vcppPath=path_search("tracer.exe","PATH","P");
   if (vcppPath!='') {
      //If found, strip  'bin' off the path.
      vcppPath2= substr(vcppPath,1,(pathlen(vcppPath)-1));
      subdirname=_strip_filename(vcppPath2,'PDE');
      if (file_eq(subdirname,'bin')) {
         vcppPath=_strip_filename(vcppPath2,'N');
         vcppPath=_strip_filename(vcppPath, 'NE');
         if (create_cpp_autotag_args(vcppPath) == '') {
            vcppPath = '';
         }
         return(vcppPath);
      }
   }
   if (create_cpp_autotag_args(vcppPath) == '') {
      vcppPath = '';
   }

   return(vcppPath);
#endif
}

/*
 Function Name:getVcppIncludePath

 Parameters:   None

 Author:       Chris Cunning

 Description:  Checks the registry for Visual C++ 2.0
               by checking in the registry.

 Returns:      String containing the path to Visual C++'s include files.

 */
_str getVcppIncludePath2 ()
{
#if __UNIX__
   return("");
#else
   _str vcppPath =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SYSTEM\ControlSet001\Control\Session Manager\Environment','','Mstools');
   if (last_char(vcppPath) != FILESEP && vcppPath !='') {
      vcppPath =vcppPath:+FILESEP;
   }
   if (vcppPath!="") {
      vcppPath=_replace_envvars(vcppPath);
      if (create_cpp_autotag_args(vcppPath) == '') {
         vcppPath = '';
      }
      return(vcppPath);
   }

   return(vcppPath);
#endif
}

/*
 Function Name:getVcppIncludePath

 Parameters:   None

 Author:       Chris Cunning

 Description:  Checks the registry for Visual Developer Studio 4.0
               by checking in the registry.

 Returns:      String containing the path to Visual C++'s include files.

 */
_str getVcppIncludePath4 ()
{
#if __UNIX__
   return("");
#else
   _str vcppPath =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\Developer\Directories','','ProductDir');
   if (last_char(vcppPath) != FILESEP && vcppPath !='') {
      vcppPath =vcppPath:+FILESEP;
   }
   if (vcppPath!="") {
      vcppPath=_replace_envvars(vcppPath);
      if (create_cpp_autotag_args(vcppPath) == '') {
         vcppPath = '';
      }
      return(vcppPath);
   }

   return(vcppPath);
#endif
}

/*
 Function Name:getVcppIncludePath5

 Parameters:   None

 Description:  Checks the registry for Visual Developer Studio 5.0
               by checking in the registry.

 Returns:      String containing the path to Visual C++'s include files.

 */
_str getVcppIncludePath5 ()
{

#if __UNIX__
   return("");
#else
   _str vcppPath =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\DevStudio\5.0\Products\Microsoft Visual C++','','ProductDir');
   if (vcppPath=='') {
      vcppPath =_ntRegQueryValue(HKEY_CURRENT_USER,'SOFTWARE\Microsoft\DevStudio\5.0\Products\Microsoft Visual C++','','ProductDir');
   }
   if (last_char(vcppPath) != FILESEP && vcppPath !='') {
      vcppPath =vcppPath:+FILESEP;
   }
   if (vcppPath!="") {
      vcppPath=_replace_envvars(vcppPath);
      if (create_cpp_autotag_args(vcppPath) == '') {
         vcppPath = '';
      }
      return(vcppPath);
   }

   return(vcppPath);
#endif
}

_str getVcppIncludePath7()
{
#if __UNIX__
   return("");
#else
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.0\Setup\VC','','ProductDir');
#endif
}

_str getVcppIncludePath2003()
{
#if __UNIX__
   return("");
#else
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.1\Setup\VC','','ProductDir');
#endif
}

_str getVcppIncludePath2005()
{
#if __UNIX__
   return("");
#else
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\8.0\Setup\VC','','ProductDir');
#endif
}
_str getVcppIncludePath2005Express()
{
#if __UNIX__
   return("");
#else
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VCExpress\8.0\Setup\VC','','ProductDir');
#endif
}
_str getVcppIncludePath2008()
{
#if __UNIX__
   return("");
#else
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\9.0\Setup\VC','','ProductDir');
#endif
}
_str getVcppIncludePath2008Express()
{
#if __UNIX__
   return("");
#else
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VCExpress\9.0\Setup\VC','','ProductDir');
#endif
}
_str getVcppIncludePath2010()
{
#if __UNIX__
   return("");
#else
   _str result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\10.0\Setup\VC','','ProductDir');
   if (result!='') {
      // Now check if devenv is really here. This could be the 2010 express edition
      _str DEVENVDIR=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\10.0\Setup\VS','','EnvironmentDirectory');
      if (DEVENVDIR=='') {
         // This is the 2010 Express edition
         return '';
      }
   }
   return result;
#endif
}
_str getVcppIncludePath2012()
{
#if __UNIX__
   return("");
#else
   _str result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\11.0\Setup\VC','','ProductDir');
   return result;
#endif
}
_str getVcppIncludePath2010Express()
{
#if __UNIX__
   return("");
#else
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VCExpress\10.0\Setup\VC','','ProductDir');
#endif
}
_str getVcppToolkitPath2003()
{
#if __UNIX__
   return("");
#else
   return _ntRegQueryValue(HKEY_CURRENT_USER,'Environment','','VCToolkitInstallDir');
#endif
}

_str getVcppPlatformSDKPath2003()
{
#if __UNIX__
   return("");
#else
   _str guidName = "";
   int status = _ntRegFindFirstSubKey(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\MicrosoftSDK\InstalledSDKs', guidName, 1);
   if (!status && guidName!='') {
      return _ntRegQueryValue(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\MicrosoftSDK\InstalledSDKs\'guidName, '', 'Install Dir');
   }
   return "";
#endif
}

_str getDDKIncludePath()
{
#if __UNIX__
   return("");
#else

   ddkPath := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\WINDDK', '', 'LFNDirectory');
   _maybe_append_filesep(ddkPath);
   return(ddkPath);
#endif
}

_str getGNUCppIncludePath(_str cppPath)
{
   _str include_path = cppPath;
   if( file_exists( include_path :+ "limits.h" ) ) {
   } else if ( file_exists( include_path :+ 'include' :+ FILESEP :+ 'limits.h') ) {
      include_path = include_path :+ 'include' :+ FILESEP;
   } else if ( file_exists( include_path :+ 'usr' :+ FILESEP :+ 'include' :+ FILESEP :+ 'limits.h') ) {
      include_path = include_path :+ 'usr' :+ FILESEP :+ 'include' :+ FILESEP;
   } else {
#if __UNIX__
      include_path = "/usr/include/";
#endif
   }
   return include_path;
}

_str getGNUCppConfigHeader()
{
   switch( machine() ) {
   case "WINDOWS":               // Windows NT on 386 compatible machine.
      return "g++-win.h";
   case "LINUX":                 // LINUX on Intel machine.
      return "g++-linux.h";
   case "SPARCSOLARIS":          // Sun Solaris on Sun SPARC station.
   case "SPARC":                 // SUN SPARC station.
      return "g++-solsp.h";
   case "RS6000":                // AIX RS600.
      return "g++-aix.h";
   case "HP9000":                // UNIX/HPUX on HP9000.
      return "g++-hpux.h";
   case "SGMIPS":                // UNIX/Irix on Silicon Graphics machine.
      return "g++-sgi.h";
   case "INTELSOLARIS":          // Sun Solaris on Intel compatible machine.
      return "g++-solx86.h";
   case "MACOSX":
      return "g++-macx11.h";     // Mac OS X Native
   case "MACOSX11":
      return "g++-macx11.h";     // Mac OS X under X11
   default:
      return '';
   }
}

void getCppIncludeDirectories( _str (&config_names)[], _str (&config_includes)[], _str (&header_names)[] )
{
   int i;
   _str cppList[],names[];
   _str visualCppPath='';

   cppList._makeempty();
   names._makeempty();
   // list of include directories per configuration delimited by path separators
   config_includes._makeempty();

   getCppIncludePath( cppList, visualCppPath, names );

   boolean includeHash:[] = null;

   int output_configs = 0;
   for( i = 0 ; i < cppList._length() ; i++ ) {
      _str include_path = cppList[i];
      config_includes[ output_configs ] = '';
      _maybe_append_filesep(include_path);

      // is this in the include hash already
      /* 
      Visual Studio 2010 Express  and Visual Studio 2010 have the same include directories
      if(includeHash:[strip(include_path, "T", FILESEP)] == true) {
         continue;
      } 
      */ 
      includeHash:[strip(include_path, "T", FILESEP)] = true;

      // ignore COMPILER_NAME_CL
      if( ( names[i] == COMPILER_NAME_VS2 ) || ( names[i] == COMPILER_NAME_VS4 ) ||
          ( names[i] == COMPILER_NAME_VS5 ) || ( names[i] == COMPILER_NAME_VS6 ) ) {

         if ( names[i] == COMPILER_NAME_VS6 ) {
            strappend( config_includes[output_configs], _get_vs_sys_includes(COMPILER_NAME_VS6) );
         } else {
            strappend( config_includes[output_configs], include_path :+ 'INCLUDE\' :+ PATHSEP );
            strappend( config_includes[output_configs], include_path :+ 'MFC\INCLUDE\' :+ PATHSEP );
            strappend( config_includes[output_configs], include_path :+ 'ATL\INCLUDE\' ) ;
         }

         header_names[output_configs]  = get_env("VSROOT") :+ "sysconfig" FILESEP "vsparser" FILESEP "vscpp.h";
         config_names[output_configs]  = names[i];
         output_configs++;
      } else if( (names[i] == COMPILER_NAME_VSDOTNET) ||
                 (names[i] == COMPILER_NAME_VS2003) ||
                 (names[i] == COMPILER_NAME_VS2005) ||
                 (names[i] == COMPILER_NAME_VS2005_EXPRESS) ||
                 (names[i] == COMPILER_NAME_VS2008) ||
                 (names[i] == COMPILER_NAME_VS2008_EXPRESS) ||
                 (names[i] == COMPILER_NAME_VS2010) ||
                 (names[i] == COMPILER_NAME_VS2010_EXPRESS) ||
                 (names[i] == COMPILER_NAME_VS2012) ||
                 (names[i] == COMPILER_NAME_VCPP_TOOLKIT2003) ||
                 (names[i] == COMPILER_NAME_PLATFORM_SDK2003) ) {
         strappend( config_includes[output_configs], _get_vs_sys_includes(names[i]) );

         header_names[output_configs]  = get_env("VSROOT") :+ "sysconfig" FILESEP "vsparser" FILESEP "vscpp.h";
         config_names[output_configs]  = names[i];
         output_configs++;
      } else if ( names[i] == COMPILER_NAME_DDK ) {
         // look for any/all versions of the DDK
         _str version;
         int status=_ntRegFindFirstSubKey(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\WINDDK',version,1);

         while (!status) {
            header_names[output_configs]  = get_env("VSROOT") :+ "sysconfig" FILESEP "vsparser" FILESEP "vscpp.h";
            config_names[output_configs]  = names[i]' - 'version;
            config_includes[output_configs] = _get_vs_sys_includes(config_names[output_configs]);
            output_configs++;

            status=_ntRegFindFirstSubKey(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\WINDDK',version,0);
         }
      } else if ( names[i] == COMPILER_NAME_SUNCC ) {

         header_names[output_configs] = get_env("VSROOT") :+ "sysconfig" FILESEP "vsparser" :+ FILESEP :+ getGNUCppConfigHeader();
         config_names[output_configs]  = names[i];
         if (file_exists(include_path :+ "include" :+ FILESEP)) {
            config_includes[output_configs] = include_path :+ "include" :+ FILESEP;
         }
         if (file_exists(include_path :+ "prod" :+ FILESEP :+ "include" :+ FILESEP)) {
            _maybe_append(config_includes[output_configs], PATHSEP);
            config_includes[output_configs] :+= include_path :+ "prod" :+ FILESEP :+ "include" :+ FILESEP;
         }
         if (file_exists(FILESEP :+ "usr" :+ FILESEP :+ "include" :+ FILESEP)) {
            _maybe_append(config_includes[output_configs], PATHSEP);
            config_includes[output_configs] :+= FILESEP :+ "usr" :+ FILESEP :+ "include" :+ FILESEP;
         }
         output_configs++;

      } else if( ( names[i] == COMPILER_NAME_CYGWIN ) || 
                 ( names[i] == COMPILER_NAME_GCC ) ||
                 ( names[i] == COMPILER_NAME_USR_INCLUDES ) ||
                 ( names[i] == COMPILER_NAME_CC ) || 
                 ( names[i] == COMPILER_NAME_LCC )) {

         // The list of system include directories searched by gcc by default can be
         // determined by running gcc -v hello.c.  The 'verbose' option will display
         // the header file search path, as well as specific macro definitions passed
         // to the C++ preprocessor and compiler stages.
         //
         // Check for file /usr/include for unix and linux.
         _maybe_append_filesep(include_path);
         if( file_exists( include_path :+ "limits.h" ) ) {
            config_includes[ output_configs ] = include_path;
            config_names[ output_configs ] = names[i];
            header_names[ output_configs ] = get_env("VSROOT") :+ "sysconfig" FILESEP "vsparser" FILESEP :+ getGNUCppConfigHeader();
            output_configs++;
         } else if ( file_exists( include_path :+ 'include' :+ FILESEP :+ 'limits.h') ) {
            include_path = include_path :+ 'include' :+ FILESEP;
         } else if ( file_exists( include_path :+ 'usr' :+ FILESEP :+ 'include' :+ FILESEP :+ 'limits.h') ) {
            include_path = include_path :+ 'usr' :+ FILESEP :+ 'include' :+ FILESEP;
         } else {
#if __UNIX__
            include_path = "/usr/include/";
#endif
         }

         // Check for file /usr/include/g++-3 for unix and linux.
         _str gcpp3_includes = include_path :+ 'g++-3' :+ FILESEP;
         if ( !file_exists( gcpp3_includes :+ "vector" ) ) {
            gcpp3_includes = '';
         }

         // Check for file /usr/include/mingw for cygwin
         _str mingw_includes = include_path :+ 'mingw' :+ FILESEP;
         if ( !file_exists( mingw_includes :+ "ctype.h" ) ) {
            mingw_includes = '';
         }

         // Check for file /usr/include/cygwin for cygwin
         _str cygwin_includes = include_path :+ 'cygwin' :+ FILESEP;
         if ( !file_exists( cygwin_includes :+ "types.h" ) ) {
            cygwin_includes = '';
         }

         // Check for file /usr/include/mingw/g++-3 for cygwin
         _str mingw_gcpp3_includes = include_path :+ 'mingw' :+ FILESEP :+ 'g++-3' :+ FILESEP;
         if ( !file_exists( mingw_gcpp3_includes :+ "vector" ) ) {
            mingw_gcpp3_includes = '';
         }

         // Check for file /usr/include/w32api for cygwin
         _str w32api_includes = include_path :+ 'w32api' :+ FILESEP;
         if ( !file_exists( w32api_includes :+ "windows.h" ) ) {
            w32api_includes = '';
         }

         // strip the include directories off of the path
         // look under lib/gcc-lib/* for limits.h
         _str slash_path = cppList[i];
         _maybe_append_filesep(slash_path);
         _str gcclib_path[];
         gcclib_path[0] = slash_path:+"lib":+FILESEP:+"gcc-lib":+FILESEP;
         gcclib_path[1] = slash_path:+"lib":+FILESEP:+"gcc":+FILESEP;   // changed in gcc3.4
         gcclib_path[2] = slash_path:+'include':+FILESEP:+'gcc':+FILESEP;  // Mac location
         int gcclib_path_index;

         for (gcclib_path_index=0;gcclib_path_index<gcclib_path._length();++gcclib_path_index) {
            // Add multiple configs based on different compiler versions
            _str match = file_match('-p +t 'maybe_quote_filename( gcclib_path[gcclib_path_index] :+ "varargs.h"),1);
            while (match!="") {

               // parse the gcc version and target version out of the list
               _str gcc_version='';
               _str target_version='';
               parse match with . (gcclib_path[gcclib_path_index]) target_version FILESEP gcc_version FILESEP "include" FILESEP "limits.h";

               _str full_name = names[i];
               if (gcc_version!='')    strappend(full_name,"-"gcc_version);
               if (target_version!='') strappend(full_name,"-"target_version);

               boolean already_added=false;
               int search_index;
               for (search_index=0;search_index<output_configs;++search_index) {
                  if (config_names[search_index]:==full_name) {
                     already_added=true;
                  }
               }

               if ((gcc_version!='' || target_version!='') && gcc_version!="install-tools" && !already_added) {
                  config_includes[ output_configs ] = '';

                  // check for include/c++/version/.
                  _str cpp_version_include = slash_path:+'include':+FILESEP:+'c++':+FILESEP:+gcc_version:+FILESEP;
                  if (file_exists(cpp_version_include:+"vector")) {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cpp_version_include );
                  } else {
                     cpp_version_include = slash_path:+'usr':+FILESEP:+'include':+FILESEP:+'c++':+FILESEP:+gcc_version:+FILESEP;
                     if (file_exists(cpp_version_include:+"vector")) {
                        _maybe_append( config_includes[output_configs], PATHSEP );
                        strappend( config_includes[output_configs], cpp_version_include );
                     }
                  }
                  // check for include/c++/version/target/
                  cpp_version_include = slash_path:+'include':+FILESEP:+'c++':+FILESEP:+gcc_version:+FILESEP:+target_version:+FILESEP;
                  if (file_exists(cpp_version_include:+'bits':+FILESEP:+"c++config.h")) {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cpp_version_include );
                  } else {
                     cpp_version_include = slash_path:+'usr':+FILESEP:+'include':+FILESEP:+'c++':+FILESEP:+gcc_version:+FILESEP:+target_version:+FILESEP;
                     if (file_exists(cpp_version_include:+'bits':+FILESEP:+"c++config.h")) {
                        _maybe_append( config_includes[output_configs], PATHSEP );
                        strappend( config_includes[output_configs], cpp_version_include );
                     }
                  }
                  // check for include/c++/version/backward/
                  cpp_version_include = slash_path:+'include':+FILESEP:+'c++':+FILESEP:+gcc_version:+FILESEP:+'backward':+FILESEP;
                  if (file_exists(cpp_version_include:+'new.h')) {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cpp_version_include );
                  } else {
                     cpp_version_include = slash_path:+'usr':+FILESEP:+'include':+FILESEP:+'c++':+FILESEP:+gcc_version:+FILESEP:+'backward':+FILESEP;
                     if (file_exists(cpp_version_include:+'new.h')) {
                        _maybe_append( config_includes[output_configs], PATHSEP );
                        strappend( config_includes[output_configs], cpp_version_include );
                     }
                  }

                  // check for include/g++
                  cpp_version_include = slash_path:+'include':+FILESEP:+'g++':+FILESEP;
                  if (file_exists(cpp_version_include:+"vector")) {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cpp_version_include );
                  } else {
                     cpp_version_include = slash_path:+'usr':+FILESEP:+'include':+FILESEP:+'g++':+FILESEP;
                     if (file_exists(cpp_version_include:+"vector")) {
                        _maybe_append( config_includes[output_configs], PATHSEP );
                        strappend( config_includes[output_configs], cpp_version_include );
                     }
                  }

                  // check for include/g++/target/
                  cpp_version_include = slash_path:+'include':+FILESEP:+'g++':+FILESEP:+target_version:+FILESEP;
                  if (file_exists(cpp_version_include:+'bits':+FILESEP:+"c++config.h")) {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cpp_version_include );
                  } else {
                     cpp_version_include = slash_path:+'usr':+FILESEP:+'include':+FILESEP:+'g++':+FILESEP:+target_version:+FILESEP;
                     if (file_exists(cpp_version_include:+'bits':+FILESEP:+"c++config.h")) {
                        _maybe_append( config_includes[output_configs], PATHSEP );
                        strappend( config_includes[output_configs], cpp_version_include );
                     }
                  }

                  // now try gcc-lib/platform/version/target/include
                  _maybe_append( config_includes[output_configs], PATHSEP );
                  strappend( config_includes[output_configs], _strip_filename(match,'n') );
                  if (substr(gcc_version,1,1) == 3 && gcpp3_includes != '') {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], gcpp3_includes );
                  }

                  // add the basic include path
                  _maybe_append( config_includes[output_configs], PATHSEP );
                  strappend( config_includes[output_configs], include_path );

                  // add the win32api path
                  if (w32api_includes != '') {
                     strappend( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], w32api_includes );
                  }

                  // add the cygwin and mingw extensions
                  if (pos('cygwin',target_version) && cygwin_includes != '') {
                     strappend( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cygwin_includes );
                  }
                  if (mingw_includes != '') {
                     strappend( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], mingw_includes );
                  }
                  if (substr(gcc_version,1,1) == 3 && mingw_gcpp3_includes != '') {
                     strappend( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], mingw_gcpp3_includes );
                  }
                  header_names[output_configs] = get_env("VSROOT") :+ "sysconfig" FILESEP "vsparser" FILESEP :+ getGNUCppConfigHeader();
                  config_names[output_configs] = full_name;

                  // Make name unique if there is more than one config of this type
                  output_configs++;
               }

               match = file_match('-p +t 'maybe_quote_filename( gcclib_path[gcclib_path_index] :+ "limits.h"),0);
            }
         }
      } else if (names[i] == COMPILER_NAME_BORLAND  || 
                 names[i] == COMPILER_NAME_BORLAND6 || 
                 names[i] == COMPILER_NAME_BORLANDX) {
         // Borland C++ Builder and C++ BuilderX
         strappend( config_includes[output_configs], include_path :+ 'include\' :+ PATHSEP );
         header_names[output_configs]  = get_env("VSROOT") :+ "sysconfig" FILESEP "vsparser" FILESEP "borland.h";
         config_names[output_configs]  = names[i];
         output_configs++;
      } else {
         // Others are not supported
      }
   }
}

void getCppIncludePath(_str (&cppList)[], _str &VisualCppPath, _str (&names)[], boolean appendIncludeDirectory=false )
{
   VisualCppPath="";
   _str cppPath ='';
   cppPath=getVcppIncludePath2();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VS2;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath4();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VS4;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath5();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VS5;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath6();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VS6;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath7();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VSDOTNET;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2003();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VS2003;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2005();
   if (cppPath !='') {
      names[names._length()]=COMPILER_NAME_VS2005;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2005Express();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VS2005_EXPRESS;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2008Express();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VS2008_EXPRESS;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2008();
   if (cppPath !='') {
      names[names._length()]=COMPILER_NAME_VS2008;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2010Express();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VS2010_EXPRESS;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2010();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VS2010;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2012();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VS2012;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppPlatformSDKPath2003();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_PLATFORM_SDK2003;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppToolkitPath2003();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_VCPP_TOOLKIT2003;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getDDKIncludePath();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_DDK;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=='') {
         VisualCppPath=cppPath;
      }
   }
   cppPath=get_BCBX_path();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_BORLANDX;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=='') {
         VisualCppPath=cppPath;
      }
   }
   cppPath=get_BCB_path();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_BORLAND6;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=='') {
         VisualCppPath=cppPath;
      }
   }
   cppPath=get_Cygwin_path();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_CYGWIN;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "usr":+FILESEP:+"include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=='') {
         VisualCppPath=cppPath;
      }
   }
   cppPath=get_lcc_path();
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_LCC;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=='') {
         VisualCppPath=cppPath;
      }
   }
   _str gccPath=get_cc_path("gcc");
   if (gccPath=="") gccPath=get_cc_path("gcc-4");
   if (gccPath=="") gccPath=get_cc_path("gcc-3");
   if (gccPath !='') {
      names[names._length()] = COMPILER_NAME_GCC;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=gccPath;
      if (VisualCppPath=='') {
         VisualCppPath=gccPath;
      }
   }
#if __UNIX__
   if (gccPath != FILESEP:+"usr" && gccPath != FILESEP:+"usr":+FILESEP && file_exists(FILESEP:+"usr":+FILESEP:+"bin":+FILESEP:+"gcc")) {
      names[names._length()] = COMPILER_NAME_GCC;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=FILESEP:+"usr";
   }
#endif
   cppPath=get_cc_path("cc");
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_CC;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=='') {
         VisualCppPath=cppPath;
      }
   }
   cppPath=get_cc_path("cl");
   if (cppPath !='') {
      names[names._length()] = COMPILER_NAME_CL;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   } else if (gccPath!=null) {
      VisualCppPath=gccPath;
   }
#if __UNIX__
   // check for /usr/include on Unix
   cppPath = FILESEP:+"usr":+FILESEP:+"include";
   if (file_exists(cppPath)) {
      cppList[cppList._length()] = cppPath;
      names[names._length()] = COMPILER_NAME_USR_INCLUDES;
   }
   // check for SunCC compiler on Solaris
   cppPath = FILESEP:+"opt":+FILESEP:+"SUNWspro":+FILESEP:+"bin":+FILESEP:+"CC";
   if (file_exists(cppPath)) {
      cppPath = FILESEP:+"opt":+FILESEP:+"SUNWspro":+FILESEP;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()] = cppPath;
      names[names._length()] = COMPILER_NAME_SUNCC;
   }

   // check for freeware GCC on Solaris
   cppPath = FILESEP:+"usr":+FILESEP:+"sfw":+FILESEP:+"bin":+FILESEP:+"gcc";
   if (file_exists(cppPath)) {
      cppPath = FILESEP:+"usr":+FILESEP:+"sfw":+FILESEP;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()] = cppPath;
      names[names._length()] = COMPILER_NAME_GCC;
   }
   // check for freeware GCC on AIX
   cppPath = FILESEP:+"opt":+FILESEP:+"freeware":+FILESEP:+"bin":+FILESEP:+"gcc";
   if (file_exists(cppPath)) {
      cppPath = FILESEP:+"opt":+FILESEP:+"freeware":+FILESEP;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()] = cppPath;
      names[names._length()] = COMPILER_NAME_GCC;
   }
   // check for freeware GCC on AIX
   cppPath = FILESEP:+"opt":+FILESEP:+"ansic":+FILESEP:+"bin":+FILESEP:+"cc";
   if (file_exists(cppPath)) {
      cppPath = FILESEP:+"opt":+FILESEP:+"ansic":+FILESEP;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()] = cppPath;
      names[names._length()] = COMPILER_NAME_CC;
   }
   // check /usr/local/bin on Unix
   cppPath = FILESEP:+"usr":+FILESEP:+"local":+FILESEP:+"bin":+FILESEP:+"gcc";
   if (file_exists(cppPath)) {
      cppPath = FILESEP:+"usr":+FILESEP:+"sfw":+FILESEP;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()] = cppPath;
      names[names._length()] = COMPILER_NAME_GCC;
   }
#endif
}

