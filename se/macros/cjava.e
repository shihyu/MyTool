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
#import "cfcthelp.e"
#import "cidexpr.e"
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
#import "rte.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "util.e"
#import "vchack.e"
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


defeventtab csharp_keys;
def  ' '= csharp_space;
def  '#'= c_pound;
def  '('= c_paren;
def  '*'= c_asterisk;
def  '.'= auto_codehelp_key;
def  '/'= c_slash;
def  ':'= c_colon;
def  ';'= c_semicolon;
def  '<'= auto_functionhelp_key;
def  '='= auto_codehelp_key;
def  '"'= c_dquote;
def  '>'= auto_codehelp_key;
def  '@'= c_atsign;
def  '\'= c_backslash;
def  '%'= c_percent;
def  '{'= csharp_begin;
def  '}'= c_endbrace;
def  ','= csharp_comma;
def  '['= csharp_startbracket;
def  'ENTER'= c_enter;
def  'TAB'= smarttab;


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
   _SetEditorLanguage("java");
}
_command void csharp_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage("cs");
}


_command void csharp_startbracket() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   l_event := last_event();
   if(!command_state() && def_csharp_refactor_auto_import==1) {
      refactor_add_import(true);
   }
   keyin(l_event);
}

_command void csharp_comma() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   l_event := last_event();
   if(!command_state() && def_csharp_refactor_auto_import==1) {
      refactor_add_import(true);
   }
   keyin(l_event);
}

_command void csharp_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if(!command_state() && def_csharp_refactor_auto_import==1) {
      refactor_add_import(true);
   }
   c_space();
}

_command void csharp_begin() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if(!command_state() && def_csharp_refactor_auto_import==1) {
      refactor_add_import(true);
   }
   c_begin();
}


/**
 * @see _c_generate_function
 */
int _java_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                                   _str (&header_list)[], _str function_body,
                                   int indent_col, int begin_col,
                                   bool make_proto=false)
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
                                 bool make_proto=false)
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
                                 bool make_proto=false)
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
                                  bool make_proto=false)
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
                                 bool make_proto=false)
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
                                bool make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}

/**
 * @see _c_generate_function
 */
int _googlego_generate_function(VS_TAG_BROWSE_INFO cm, int &c_access_flags,
                                _str (&header_list)[],_str function_body,
                                int indent_col, int begin_col,
                                bool make_proto=false)
{
   return _c_generate_function(cm,c_access_flags,header_list,function_body,
                                      indent_col,begin_col,make_proto);
}

/**
 * @see _c_get_expression_pos
 */
int _e_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count,int depth=0)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count,depth);
}


/**
 * @see _c_get_expression_pos
 */
int _cs_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count,int depth=0)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count,depth);
}

/**
 * @see _c_get_expression_pos
 */
int _java_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count,int depth=0)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count,depth);
}

/**
 * @see _c_get_expression_pos
 */
int _rul_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count,int depth=0)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count,depth);
}

/**
 * @see _c_get_expression_pos
 */
int _phpscript_get_expression_pos(int &lhs_start_offset,_str &expression_op,int &pointer_count,int depth=0)
{
   return _c_get_expression_pos(lhs_start_offset,expression_op,pointer_count,depth);
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

int _e_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
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
int _java_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
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
int _cs_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   int status=_c_get_expression_info(PossibleOperator, info, visited, depth);

   // compensate for @ keywords
   if (substr(info.lastid,1,1)=="@") {
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
int _cfscript_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
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
int _phpscript_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
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
int _idl_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

//////////////////////////////////////////////////////////////////////////
static _str gCancelledCompiler="";
void _prjopen_java_util()
{
   gCancelledCompiler="";
}

_str java_get_active_compile_tag_file()
{
   if (!_haveBuild()) {
      return "";
   }
   javaCompiler := refactor_get_active_config_name(_ProjectHandle(), 'java');
   if (javaCompiler == '') {
      refactor_get_compiler_configurations(auto cl, auto jl, true);
      javaCompiler = _GetLatestJDK(true);
      if (javaCompiler != '') {
         def_active_java_config = javaCompiler;
      }
   }
   //say("javaCompiler="javaCompiler);
   if (javaCompiler != '') {
      javaCompiler = _tagfiles_path():+javaCompiler:+TAG_FILE_EXT;
   }
   return javaCompiler;
}

/**
 * @see ext_MaybeRecycleTagFIle
 */
int _java_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // Find the active "Java" compiler tag file
   compiler_name := refactor_get_active_config_name(_ProjectHandle(), "java");
   //say("_java_MaybeBuildTagFile: name="compiler_name);
   if (compiler_name != "" && compiler_name != gCancelledCompiler) {
      // put together the file name
      _str compilerTagFile=_tagfiles_path():+compiler_name:+TAG_FILE_EXT;
      if (!file_exists(compilerTagFile)) {
         int status = refactor_build_compiler_tagfile(compiler_name, "java", false, useThread);
         if (status == COMMAND_CANCELLED_RC) {
            message("You pressed cancel.  You will have to build the tag file manually.");
            gCancelledCompiler = compiler_name;
         } else if (status == 0) {
            gCancelledCompiler = "";
         }
      }
   }

   tagfilename := "";
   if (p_embedded) {

      // maybe we can recycle JSP tag file
      if (!ext_MaybeRecycleTagFile(tfindex,tagfilename,"java","jsp") || forceRebuild) {
         // Attempt to find the Java Servlet jar and tag it
         path_list := "";
         if (_isMac()) {
            XcodeSDKInfo allSdkInfo[];
            getXcodeSDKs(allSdkInfo);
            XcodeSDKInfo i;
            foreach (i in allSdkInfo) {
               xcode_path := i.sdk_root;
               p := pos(FILESEP:+"Contents":+FILESEP,xcode_path);
               if (p <= 0) continue;
               xcode_path = substr(xcode_path, 1, p+9);
               _maybe_append_filesep(xcode_path);
               path_list = xcode_path :+ "Applications/Application Loader.app/Contents/MacOS/itms/share/iTMSTransporter.woa/Contents/OSGi-Bundles/com.springsource.javax.servlet-2.5.0.jar";
               if (file_exists(path_list)) break;
               path_list = "";
            }
         }

         ext_MaybeBuildTagFile(tfindex, "java", "jsp",
                               "JSP Implicit Objects",
                               _maybe_quote_filename(path_list), 
                               false, withRefs, useThread, forceRebuild);
      }
   }

   // maybe we can recycle tag file(s)
   if (_isUnix()) {
      if (ext_MaybeRecycleTagFile(tfindex,tagfilename,"java","ujava") && !forceRebuild) {
         return(0);
      }
   } else {
      if (ext_MaybeRecycleTagFile(tfindex,tagfilename,"java","java") && !forceRebuild) {
         return(0);
      }
   }
   // recycling didn't work, might have to build tag files
   tfindex=0;
   return(0);
}

/**
 * @see ext_MaybeBuildTagFIle
 */
int _cfscript_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex, "cfscript", "", "", "", false, withRefs, useThread, forceRebuild);
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
   _str settingsPlistPath = concat_path_and_file(SDKRoot, "SDKSettings.plist");
   propertyValue := "";
   saveWindowId := p_window_id;
   plist_view_id := 0;
   view_id := 0;
   int status=_open_temp_view(settingsPlistPath,plist_view_id,view_id);
   if (!status) {
      searchRegex :=  "<key>"_escape_re_chars(propertyName)'</key>\n:b<string>{?+}</string>';
      if (plist_view_id.search( searchRegex, "+r@") == 0) {
         propertyValue = plist_view_id.get_text(match_length('0'), match_length('S0'));
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
 * @return _str SDK display name, e.g. 'macOS 10.6' or 'iOS 5.0'
 */
static _str _xcode_GetSDKDisplayName(_str SDKRoot){

   _str sdkName = _xcode_GetSDKPropertyListString("DisplayName",SDKRoot);
   if(sdkName == "") {
       // Just use the SDK directory name (without the .sdk extension)
       // as a fallback name in case the .plist file can't be read
       sdkDir := strip(SDKRoot, 'T', FILESEP);
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
    _str canonName = _xcode_GetSDKPropertyListString("CanonicalName",SDKRoot);
    return canonName;
}

/**
 * Returns the current Developer directory used by the Xcode 
 * command line tools. Most of the time this is /Developer.
 */
static _str _xcode_GetDeveloperRoot() {
    xcodeDevRoot := "";
    settingsFile := "/usr/share/xcode-select/xcode_dir_path";
    saveWindowId := p_window_id;
    settings_view_id := 0;
    orig_view_id := 0;
    int status = _open_temp_view(settingsFile, settings_view_id, orig_view_id);
    if(!status) {
        settings_view_id.get_line(xcodeDevRoot);
        _delete_temp_view(settings_view_id);
    }
    if(xcodeDevRoot == "") {
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
   _str wildcardSpec = concat_path_and_file(developerDir, "SDKs/*.sdk");
   wildcardSearch :=  "+D +X "wildcardSpec;
   path := file_match(wildcardSearch,1);
   while (path:!="") {
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
   wildcardSearch :=  "+D +X "wildcardSpec;
   path := file_match(wildcardSearch,1);
   while (path:!="") {
      platforms[platforms._length()]=path;
      path=file_match(wildcardSearch,0);
   }
}

static const MAC_FRAMEWORKS_SUBDIR= "System/Library/Frameworks/";

/**
 * Gets all of the SDK root directories on macOS 
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
   SDKRoot := "/";
   XcodeSDKInfo defaultInfo;
   defaultInfo.name = "Default (/System/Library/Frameworks)";
   defaultInfo.canonicalName = "";
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

static int getDotNetFrameworkPathForVersion(_str csharp_version, DotNetFrameworkInfo &info)
{
   if (_isUnix()) return 0;

   // initialize info structure
   info.name = ".NET Framework";
   if (csharp_version != "") strappend(info.name," "csharp_version);
   info.version = "";
   info.maketags_args = "";
   info.install_dir = "";
   info.sdk_dir = "";
   info.display_name = "";

   // v3.0 and v3.5 are registered differently (and easier)
   if (csharp_version == "v3.0" || csharp_version == "v3.5") {
       threedot_key := "SOFTWARE\\Microsoft\\.NETFramework\\AssemblyFolders\\":+csharp_version;
       _str veethreedir;
       int status = _ntRegFindValue(HKEY_LOCAL_MACHINE, threedot_key, "All Assemblies In", veethreedir);
       if (status) {
          // If no registry key, use %PROGRAMFILES%\Reference Assemblies\Microsoft\Framework
          ntGetSpecialFolderPath(veethreedir, CSIDL_PROGRAM_FILES);
          _maybe_append_filesep(veethreedir);
          veethreedir :+= "Reference Assemblies\\Microsoft\\Framework\\" :+ csharp_version;
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
      key := "SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full";
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
      veefourdir :+= "Reference Assemblies\\Microsoft\\Framework\\.NETFramework\\" :+ csharp_version;
      info.version = "v4.0.30319";
      info.install_dir = veefourdir;
   }

   if (csharp_version == "v4.5") {
      // The .NET Framework 4.5 RC installer writes registry keys when installation is successful.
      // You can test whether the .NET Framework 4.5 RC is installed by checking the 
      // HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full folder in the registry
      // for a DWORD value named Release. The existence of this key indicates that the .NET Framework 4.5 RC
      // has been installed on that computer.
      key := "SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full";
      _str install;
      int status = _ntRegFindValue(HKEY_LOCAL_MACHINE, key, "Release", install);
      if (status) {
         return STRING_NOT_FOUND_RC;
      }

      _str veefourdir;
      ntGetSpecialFolderPath(veefourdir, CSIDL_PROGRAM_FILES);
      _maybe_append_filesep(veefourdir);
      veefourdir :+= "Reference Assemblies\\Microsoft\\Framework\\.NETFramework\\" :+ csharp_version;
      info.version = "v4.5";
      info.install_dir = veefourdir;

      // 4.5 installs on top of v4.0, impersonate 4.0 from here out
      csharp_version = "v4.0";
   }

   // get the Frameworks SDK directory from registry
   // This is optional
   csharp_key := "SOFTWARE\\Microsoft\\.NETFramework";
   int status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                                csharp_key, "sdkInstallRoot":+csharp_version, info.sdk_dir);

   // get basic frameworks directory from registry
   csharp_dir := "";
   status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                            csharp_key, "InstallRoot", csharp_dir);
   if (status) {
      // If no registry key, use %WINDIR%\Microsoft.NET\Framework
      ntGetSpecialFolderPath(csharp_dir, CSIDL_WINDOWS);
      _maybe_append_filesep(csharp_dir);
      csharp_dir :+= "Microsoft.NET\\Framework\\";
   }

   // make sure the directory ends in a FILESEP
   _maybe_append_filesep(csharp_dir);

   // expecting a particular version number
   if (csharp_version != "") {
      // search for the build number
      csharp_build_number := "";
      csharp_build_range := "";
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
   if (csharp_version == "") {
      csharp_version = _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\NET Framework Setup\\Product", "", "Version");
      if (csharp_version != "") {
         info.version = csharp_version;
         info.install_dir = csharp_dir:+csharp_version;
         return 0;
      }
   }

   // desparate, just try hard-coded values
   if (csharp_version=="v1.0" && file_exists(csharp_dir:+"v1.0.3705":+FILESEP:+"mscorlib.dll")) {
      info.version = "v1.0.3705";
      info.install_dir = csharp_dir:+"v1.0.3705";
      return 0;
   }
   if (csharp_version=="v1.1" && file_exists(csharp_dir:+"v1.1.4322":+FILESEP:+"mscorlib.dll")) {
      info.version = "v1.1.4322";
      info.install_dir = csharp_dir:+"v1.1.4322";
      return 0;
   }
   if (csharp_version=="v2.0" && file_exists(csharp_dir:+"v2.0.50727":+FILESEP:+"mscorlib.dll")) {
      info.version = "v2.0.50727";
      info.install_dir = csharp_dir:+"v2.0.50727";
      return 0;
   }
   if (csharp_version=="v2.0" && file_exists(csharp_dir:+"v2.0.50215":+FILESEP:+"mscorlib.dll")) {
      info.version = "v2.0.50215";
      info.install_dir = csharp_dir:+"v2.0.50215";
      return 0;
   }

   // no luck
   return STRING_NOT_FOUND_RC;
}

_str getDotNetFrameworkAutotagPaths(DotNetFrameworkInfo &info)
{
   // already have maketag args set?
   if (info.maketags_args != "") {
      return info.maketags_args;
   }

   // .NET framework 1.1 and 2.0 use pretty standard tagging where
   // we look for System*.dll and System*.xml

   // .NET 3.0 and 3.5 are a bit strange. They both are built
   // on top of 2.0, and they are a little lax in the DLL naming, so
   // be basically have to include *.dll

   // check that mscorlib.dll exists, if it is not there, we have a problem
   csharp_path := "";
   frameworkDir := strip(info.install_dir, "T", FILESEP);
   corlib_path := frameworkDir:+FILESEP:+"mscorlib.dll";
   if (file_exists(corlib_path)) {
      csharp_path=_maybe_quote_filename(corlib_path);
   }

   // The released .NET framework also has mscorcfg.dll which may be tagged
   cfg_path := frameworkDir:+FILESEP:+"mscorcfg.dll";
   if (file_exists(cfg_path)) {
      csharp_path :+= " "_maybe_quote_filename(cfg_path);
   }

   // The released .NET framework also has mscorwks.dll which may be tagged
   wks_path := frameworkDir:+FILESEP:+"mscorwks.dll";
   if (file_exists(wks_path)) {
      csharp_path :+= " "_maybe_quote_filename(wks_path);
   }

   // The released .NET framework also has System.*.dll which needs to be tagged
   if (file_exists(frameworkDir:+FILESEP:+"System.dll")) {
      system_path := frameworkDir:+FILESEP:+"System.*.dll";
      system_path2 := frameworkDir:+FILESEP:+"System.dll";
      csharp_path :+= " "_maybe_quote_filename(system_path)" "_maybe_quote_filename(system_path2);
   }

   // Need to also tag any Microsoft.*.dlls
   msftPath :=  frameworkDir:+FILESEP:+"Microsoft.*.dll";
   csharp_path :+= " "_maybe_quote_filename(msftPath);

   // The released .NET framework SDK also has mscorcfg.dll which may be tagged
   if (info.sdk_dir != "") {
      sdkDir := strip(info.sdk_dir, "T", FILESEP);
      cfg_path = sdkDir:+FILESEP:+"bin":+FILESEP:+"mscorcfg.dll";
      if (file_exists(cfg_path)) {
         csharp_path :+= " "_maybe_quote_filename(cfg_path);
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
   xml_path :=  frameworkDir:+FILESEP:+"mscorlib.xml";
   csharp_path :+= " "_maybe_quote_filename(xml_path);
   xml_path=frameworkDir:+FILESEP:+"Microsoft.*.xml";
   csharp_path :+= " "_maybe_quote_filename(xml_path);
   xml_path=frameworkDir:+FILESEP:+"System.*.xml";
   csharp_path :+= " "_maybe_quote_filename(xml_path);
   xml_path=frameworkDir:+FILESEP:+"System.xml";
   csharp_path :+= " "_maybe_quote_filename(xml_path);

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
   return "-E "_maybe_quote_filename(exclude_path)" "_maybe_quote_filename(system_path_dll)" "_maybe_quote_filename(system_path_xml);
}

static _str getAspDotNetNuGetFallbackXml()
{
   // Look up the ASP.NET Core installation dir
   aspnet_core_version := _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\ASP.NET Core\\Runtime Package Store", "", "InstallDir");
   if ( aspnet_core_version == "" ) {
      return "";
   }

   // Find the NuGetFallbackFolder, which has nice little XMLDoc files hidden in there
   csharp_path := "";
   nuget_xml_path := aspnet_core_version;
   _maybe_append_filesep(nuget_xml_path);
   nuget_xml_path :+= "sdk":+FILESEP;
   nuget_xml_path :+= "NuGetFallbackFolder":+FILESEP;

   // check the current language, but exclude other languages, except en
   active_lang := _locale_language_name();
   active_lang = stranslate(active_lang, '-', '_');
   parse active_lang with active_lang '-' auto active_region '-' .;
   foreach (auto current_lang in "ar de en es fi fr he hu in it ja ka ko sl sw sv ru uk zh-hans zh-hant") {
      if (strieq(current_lang,active_lang)) continue;
      if (strieq(current_lang,active_lang'-'active_region)) continue;
      csharp_path :+= " -E "_maybe_quote_filename(current_lang:+FILESEP);
   }

   // there are some XML config files under there we do not want
   csharp_path :+= " -E "_maybe_quote_filename("build":+FILESEP);
   csharp_path :+= " -E "_maybe_quote_filename("src":+FILESEP);
   csharp_path :+= " -E "_maybe_quote_filename("clientexclusionlist.xml");

   // get the other XML files, and return
   csharp_path :+= " "_maybe_quote_filename(nuget_xml_path:+"*.xml");
   return csharp_path;
}

class Sortable_DotNetFrameworkInfo: sc.lang.IComparable {
   _str m_version;
   DotNetFrameworkInfo m_info;
   Sortable_DotNetFrameworkInfo(_str version="",DotNetFrameworkInfo &info=null) {
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

   if (_isUnix()) {
      csharp_dir := "";
      if (_isMac()) {
         unity_mono_path := "/Applications/Unity/MonoDevelop.app/Contents/Frameworks/Mono.framework/Libraries/mono";
         csharp_dir="/Library/Frameworks/Mono.framework/Libraries/mono";
         if (file_exists(unity_mono_path)) {
            csharp_dir=unity_mono_path;
         }
      } else {
         // Tested on ubuntu after installing monodevelop
         csharp_dir="/usr/lib/mono";
      }

      // Also look for .NET Core versions
      dotnet_dir := path_search("dotnet","PATH","P");
      if (dotnet_dir=="") {
         dotnet_dir = "/usr/local/share/dotnet/dotnet";
      }
      if (file_exists(dotnet_dir)) {
         dotnet_dir = _strip_filename(dotnet_dir, "N");
      }

      if (file_exists(csharp_dir) || file_exists(dotnet_dir)) {
         // Unity has it's own install of Mono.
         NewViewId := 0;
         orig_view_id := _create_temp_view(NewViewId);
         if (file_exists(dotnet_dir:+"/sdk")) {
            insert_file_list(dotnet_dir:+'/sdk/*.* +D -V +P -S');
         }
         if (file_exists(dotnet_dir:+"/shared")) {
            insert_file_list(dotnet_dir:+'/shared/*/*.* +D -V +P -S');
         }
         if (file_exists(csharp_dir)) {
            insert_file_list(csharp_dir:+'/*.* +D -V +P -S');
            insert_file_list(csharp_dir:+'/xbuild-frameworks/.NETPortable/*.* +D -V +P -S');
         }
         Sortable_DotNetFrameworkInfo list[];

         fsort('n');
         top();up();
         for (;;) {
            if (down()) break;
            get_line(auto versionDir);
            versionDir = strip(versionDir);
            _maybe_strip(versionDir, FILESEP);
            lastVersionDir := _strip_filename(versionDir, 'P');
            if (_first_char(lastVersionDir) == '.') continue;

            csharp_path_chk := versionDir:+FILESEP:+"mscorlib.dll";
            if (file_exists(csharp_path_chk)) {
               system_path  :=  versionDir:+FILESEP:+"System.dll";
               system_path2 :=  versionDir:+FILESEP:+"System.*.dll";
               system_path3 :=  versionDir:+FILESEP:+"Microsoft.*.dll";
               csharp_path  :=  _maybe_quote_filename(csharp_path_chk):+" ":+_maybe_quote_filename(system_path):+" ":+_maybe_quote_filename(system_path2):+" ":+_maybe_quote_filename(system_path3);
               xml_path     :=  _maybe_quote_filename(versionDir:+FILESEP:+"**":+FILESEP:+"*.xml");

               if (pos("/mono", versionDir, 1, 'i') > 0) {
                  info.display_name = "Mono.framework "lastVersionDir;
                  info.version = "Mono ":+lastVersionDir;
               } else {
                  info.display_name = ".NET Framework "lastVersionDir;
                  info.version = ".NET Core ":+lastVersionDir;
               }
               info.name = info.display_name;
               info.install_dir = versionDir;
               info.sdk_dir = "";
               info.maketags_args = csharp_path:+" ":+xml_path;
               Sortable_DotNetFrameworkInfo item(lastVersionDir,info);
               list :+= item;
            }
         }
         list._sort();
         //debugvar(list);
         for (i:=0;i<list._length();++i) {
            frameworks :+= list[i].m_info;
         }

         p_window_id=orig_view_id;

      }

   #if 0
       else {
         // For now, just look in "/usr/local/lib/" for corlib.dll
         // check that mscorlib.dll exists, if it is not there, we have a problem
         csharp_dir := "/usr/local/lib";
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
      return 0;
   } 
   
   // locate the C# runtime libraries
   int status;
   sdk_dir := "";
   csharp_dir := "";
   csharp_version := "";
   csharp_key := "SOFTWARE\\Microsoft\\.NETFramework";

   // try for .NET Framework SDK
   if (getDotNetFrameworkPathForVersion("", info) == 0) {
      frameworks :+= info;
   }

   // try for .NET Framework 1.0 (I don't think this ever existed)
   if (getDotNetFrameworkPathForVersion("v1.0", info) == 0) {
      frameworks :+= info;
   }

   // try for .NET Framework 1.1
   if (getDotNetFrameworkPathForVersion("v1.1", info) == 0) {
      frameworks :+= info;
   }

   // try for .NET Framework 2.0
   dotNetTwoIndex := -1;
   _str dotNetTwoFullVersion;
   if (getDotNetFrameworkPathForVersion("v2.0", info) == 0) {
      dotNetTwoIndex = frameworks._length();
      frameworks[dotNetTwoIndex] = info;
      dotNetTwoFullVersion = info.version;
   }

   // If we have v2.0, we may also have 3.0 and 3.5
   if(dotNetTwoIndex > -1) {
      dotNetThreeZeroIndex := -1;
      dotNetThreeFiveIndex := -1;
      dotNetFourZeroIndex := -1;

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
         autotagArgsForTwo := getDotNetFrameworkAutotagPaths(frameworks[dotNetTwoIndex]);
         autotagArgsForNugetXml := getAspDotNetNuGetFallbackXml();
         frameworks[dotNetTwoIndex].maketags_args = autotagArgsForTwo" "autotagArgsForNugetXml;
         exclude_xml  := "-EFrameworkList.xml -EWinFXList.xml -EVSList.xml -EGroupedProviders.xml -ENetFx*.xml";

         // Append the v3.0-specific wildcards to the v2.0 args
         autotagArgsForThreeZero := "";
         if(dotNetThreeZeroIndex > 0) {
            dotNetThreeDir := strip(frameworks[dotNetThreeZeroIndex].install_dir, "T", FILESEP);
            autotagArgsForThreeZero = getDotNetAutotagsArgsForThreeOrFour(dotNetThreeDir);
            frameworks[dotNetThreeZeroIndex].maketags_args = exclude_xml" "autotagArgsForTwo" "autotagArgsForThreeZero" "autotagArgsForNugetXml;
         }

         // Append the v3.5-specific wildcards to the v3.0 args
         // (or the v2.0 args if somehow 3.0 is not installed)
         autotagArgsForThreeFive := "";
         if(dotNetThreeFiveIndex > 0) {
            dotNetThreeFiveDir := strip(frameworks[dotNetThreeFiveIndex].install_dir, "T", FILESEP);
            autotagArgsForThreeFive = getDotNetAutotagsArgsForThreeOrFour(dotNetThreeFiveDir);
            frameworks[dotNetThreeFiveIndex].maketags_args = exclude_xml" "autotagArgsForTwo" "autotagArgsForThreeZero" "autotagArgsForThreeFive" "autotagArgsForNugetXml;
         }

         // Append the v4.0-specific wildcards to the v3.0 args
         // (or the v2.0 args if somehow 3.0 is not installed)
         // We do *not* add the v3.5 paths, as v4.0 *replaces* v3.5,
         // but like v3.5, it includes 3.0 and 2.x
         autotagArgsForFourZero := "";
         if(dotNetFourZeroIndex > 0) {
            dotNetFourZeroDir := strip(frameworks[dotNetFourZeroIndex].install_dir, "T", FILESEP);
            autotagArgsForFourZero = getDotNetAutotagsArgsForThreeOrFour(dotNetFourZeroDir);
            frameworks[dotNetFourZeroIndex].maketags_args = exclude_xml" "autotagArgsForThreeZero" "autotagArgsForFourZero" "autotagArgsForNugetXml;
         }
      }
   }

   // try for .NET Framework versions 4.5.1 and newer
   _ntRegListKeys(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\.NET Framework Platform\Setup\Multi-Targeting Pack', auto dotnet_keys);
   if (dotnet_keys._length() > 0) {
      ntGetSpecialFolderPath(auto dotnet_dir, CSIDL_PROGRAM_FILESX86);
      _maybe_append_filesep(dotnet_dir);
      dotnet_dir :+= 'Reference Assemblies\Microsoft\Framework\.NETFramework\';
      foreach ( auto dotnet_version in dotnet_keys ) {
         info.name = "Microsoft .NET Framework ":+dotnet_version;
         info.version = dotnet_version;
         info.install_dir = dotnet_dir:+dotnet_version;
         info.sdk_dir = "";
         info.maketags_args = "";
         info.maketags_args = getDotNetFrameworkAutotagPaths(info);
         frameworks :+= info;
      }
   }

   // try the oldest of old .NET Beta version
   csharp_key="SOFTWARE\\Microsoft\\ComPlus";
   status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                            csharp_key,"InstallRoot", csharp_dir);
   if (!status) {
      _maybe_append_filesep(csharp_dir);
      status=_ntRegFindValue(HKEY_LOCAL_MACHINE,
                             csharp_key,"Version", csharp_version);
      if (status) csharp_version = "v1.0.3705";
      info.name = ".NET Framework 1.0 Beta";
      info.version = csharp_version;
      info.install_dir = csharp_dir:+csharp_version;
      info.sdk_dir = "";
      info.maketags_args = "";
      info.maketags_args = getDotNetFrameworkAutotagPaths(info);
      frameworks :+= info;
   }

   // make sure all paths have maketags args
   n := frameworks._length();
   for (i:=0; i<n; ++i) {

      // already have a path set up?
      if (frameworks[i].maketags_args != "") {
         continue;
      }

      csharp_path := getDotNetFrameworkAutotagPaths(frameworks[i]);
      if (csharp_path == "") {
         frameworks._deleteel(i);
         --i; --n;
         continue;
      }

      // now save the wild cards for this framework version
      frameworks[i].maketags_args = csharp_path;
   }

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
int _cs_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   status := _MaybeBuildTagFile_dotnet(tfindex, withRefs, useThread, forceRebuild);

   tfindex2 := 0;
   status2 := _MaybeBuildTagFile_unity3d(tfindex2, withRefs, useThread, forceRebuild);
   //say("status="status" tf="tfindex" 2="status2" tf2="tfindex2);

   if (!status) return status;

   tfindex=tfindex2;
   return status2;

}
static int _MaybeBuildTagFile_dotnet(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false) 
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // if they have an old csharp.vtg, remove it
   ext := "cs";
   tagfilename := absolute(_tagfiles_path():+"csharp":+TAG_FILE_EXT);
   remove_lang_tagfile("cs ":+_maybe_quote_filename(tagfilename));

   // maybe we can recycle tag file(s)
   tagfilename="";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"dotnet") && !forceRebuild) {
      return(0);
   }

   DotNetFrameworkInfo frameworks[];
   getDotNetFrameworkPaths(frameworks);

   if (frameworks._length() == 0) {
      return PATH_NOT_FOUND_RC;
   }

   i := latest_index := 0;
   for (i=1; i<frameworks._length(); ++i) {
      if (frameworks[i].version > frameworks[latest_index].version) {
         latest_index = i;
      }
   }

   dotnet_version := frameworks[latest_index].version;
   if (dotnet_version == null) dotnet_version = "";
   dotnet_path := frameworks[latest_index].maketags_args;
   if (dotnet_path=="") {
      return PATH_NOT_FOUND_RC;
   }

   // The user does not have an extension specific tag file for C#
   extra_file := ext_builtins_path(ext,"dotnet");
   return ext_BuildTagFile(tfindex,tagfilename,ext,".NET Framework ":+dotnet_version,
                           false,dotnet_path,extra_file, withRefs, useThread);
}
static int _MaybeBuildTagFile_unity3d(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false) 
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   ext := "cs";
   tagfilename := absolute(_tagfiles_path():+"unity":+TAG_FILE_EXT);

   // maybe we can recycle tag file(s)
   tagfilename="";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"unity") && !forceRebuild) {
      return(0);
   }

   AUTOTAG_BUILD_INFO autotagInfo;
   int status=_getAutoTagInfo_unity3d(autotagInfo);

   if (status) {
      return PATH_NOT_FOUND_RC;
   }

   _str dotnet_path=autotagInfo.wildcardOptions;
   if (dotnet_path=="") {
      return PATH_NOT_FOUND_RC;
   }

   // The user does not have an extension specific tag file for C#
   _str extra_file=ext_builtins_path(ext,"unity");
   return ext_BuildTagFile(tfindex,tagfilename,ext,"Unity",
                           false,dotnet_path,extra_file, withRefs, useThread);
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
int _jsl_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // if they have an old jsharp.vtg, remove it
   ext := "jsl";

   DotNetFrameworkInfo frameworks[];
   getDotNetFrameworkPaths(frameworks);
   if (frameworks._length() == 0) {
      return PATH_NOT_FOUND_RC;
   }

   i := latest_index := 0;
   for (i=1; i<frameworks._length(); ++i) {
      if (frameworks[i].version > frameworks[latest_index].version) {
         latest_index = i;
      }
   }

   dotnet_version := frameworks[latest_index].version;
   if (dotnet_version == null) dotnet_version = "";
   dotnet_path := frameworks[latest_index].maketags_args;
   if (dotnet_path=="") {
      return PATH_NOT_FOUND_RC;
   }

   // first try to recycle or build the DOTNET tag file
   status := result := 0;
   tagfilename := "";
   if (!ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"dotnet") || forceRebuild) {
      // The user does not have an extension specific tag file for C#
      extra_file := ext_builtins_path(ext,"dotnet");
      status = ext_BuildTagFile(tfindex,tagfilename,ext,".NET Framework ":+dotnet_version,
                                false,dotnet_path,extra_file, withRefs, useThread);
      if (status < 0) {
         result = status;
      }
   }

   // second try to recycle or build the JSHARP tag file
   if (!ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"jsharp") || forceRebuild) {
      jsharp_path := _maybe_quote_filename(frameworks[latest_index].install_dir:+FILESEP:+"vjs*.dll");
      status = ext_BuildTagFile(tfindex,tagfilename,ext,"J# Compiler Libraries",false,jsharp_path,"", withRefs, useThread);
      if (status < 0) {
         result = status;
      }
   }

   return result;

}

/**
 * @see ext_MaybeBuildTagFIle
 */
int _phpscript_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file
   tagfilename := "";
   lang := "phpscript";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,lang) && !forceRebuild) {
      return(0);
   }
 
   // run maketags and tag just the builtins file, and other builtins files
   return ext_BuildTagFile(tfindex,tagfilename,lang,"PHP Libraries",
                           false,"",
                           ext_builtins_path(lang,"phpscript"), withRefs, useThread);
}

/**
 * @see ext_MaybeBuildTagFIle
 */
int _idl_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex,"idl","omgidl","OMG IDL Builtins", "", false, withRefs, useThread, forceRebuild);
}

/**
 * @see _c_find_context_tags
 */
int _phpscript_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                                 _str lastid,int lastidstart_offset,
                                 int info_flags,typeless otherinfo,
                                 bool find_parents,int max_matches,
                                 bool exact_match,bool case_sensitive,
                                 SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                                 SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                                 VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (_chdebug) {
      isay(depth, "_phpscript_find_context_tags: lastid="lastid" prefix="prefixexp);
   }
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= SE_TAG_CONTEXT_ONLY_FUNCS;
   }
   status := _c_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,false,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth+1,prefix_rt);

   // maybe we have to search for symbols with a leading dollar sign
   if (status < 0 && lastid != "" && _first_char(lastid) != "$") {
      if (_chdebug) {
         isay(depth, "_phpscript_find_context_tags: retrying with leading $");
      }
      status = _c_find_context_tags(errorArgs,prefixexp,"$"lastid,lastidstart_offset,
                                    info_flags,otherinfo,false,max_matches,
                                    exact_match,case_sensitive,
                                    filter_flags,context_flags,
                                    visited,depth+1,prefix_rt);
   }

   // patch up class members with a dollar sign by taking it away.
   if (prefixexp != "" && _last_char(prefixexp)==">" && tag_get_num_of_matches() > 0) {
      VS_TAG_BROWSE_INFO matches[];
      tag_get_all_matches(matches);
      tag_clear_matches();
      for (i:=0; i<matches._length(); i++) {
         _maybe_strip(matches[i].member_name, "$");
         tag_insert_match_info(matches[i]);
      }
   }

   return status;
}

/**
 * @see _do_default_find_context_tags
 */
int _idl_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           bool find_parents,int max_matches,
                           bool exact_match, bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("_idl_find_context_tags("prefixexp","lastid","lastid_prefix")");
   tag_return_type_init(prefix_rt);

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
      prefixChar := get_text(1, lastidstart_offset-1);
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
      context_flags |= SE_TAG_CONTEXT_ONLY_FUNCS;
   }

   // this instance is not a function, so mask it out of filter flags
   if (info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
      filter_flags &= ~(SE_TAG_FILTER_PROCEDURE|SE_TAG_FILTER_PROTOTYPE);
   }

   // get the tag file list
   errorArgs._makeempty();
   num_matches := 0;
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   // deal with default case where we have no prefix expression
   if (prefixexp == "") {
      return _do_default_find_context_tags( errorArgs, 
                                            prefixexp, 
                                            lastid, lastidstart_offset, 
                                            info_flags, otherinfo, 
                                            find_parents, max_matches, 
                                            exact_match, case_sensitive, 
                                            filter_flags, context_flags, 
                                            visited, depth+1);
   }

   // attempt to evaluate the prefix expression
   status := 0;
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   if (prefixexp!="") {
      status = _c_get_type_of_prefix(errorArgs, prefixexp, rt, visited, depth+1);
      prefix_rt = rt;
   }

   // try to match the symbol in the current context
   if (!status) {
      if (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY) {
         context_flags |= SE_TAG_CONTEXT_ONLY_CONST;
      }
      if (rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) {
         context_flags |= SE_TAG_CONTEXT_ONLY_STATIC;
      }
      tag_list_in_class(lastid, rt.return_type,
                        0, 0, tag_files,
                        num_matches, max_matches,
                        filter_flags,
                        context_flags | SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE | ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS),
                        exact_match, case_sensitive, 
                        null, null, visited, depth+1);

      if (num_matches == 0) {
         context_list_flags := SE_TAG_CONTEXT_ANYTHING;
         if ( find_parents && !(rt.return_flags & (VSCODEHELP_RETURN_TYPE_STATIC_ONLY|VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY)) ) {
            context_list_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
         }
         tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, tag_files, "",
                                     num_matches, max_matches,
                                     filter_flags,
                                     context_flags | context_list_flags | SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE | ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS),
                                     exact_match, case_sensitive, visited, depth+1);
      }
   }

   // really getting very desperate for a match here
   // stop here if we are only searching context
   if (num_matches==0 && exact_match && prefixexp!="" &&
       !(context_flags & SE_TAG_CONTEXT_ONLY_CONTEXT)) {
      tag_list_context_globals(0,0,lastid,true,tag_files,
                               SE_TAG_FILTER_ANY_PROCEDURE,context_flags,
                               num_matches, max_matches,
                               exact_match, case_sensitive, 
                               visited, depth+1);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=="")? rt.return_type:lastid;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

// Insert imported packages, current object is editor control
static void java_insert_imports(int tree_wid, int tree_root, var tag_files,
                                _str cur_package_name, _str cur_class_name,
                                _str lastid, _str lastid_prefix,
                                SETagFilterFlags filter_flags, SETagContextFlags context_flags,
                                bool exact_match, bool case_sensitive,
                                int &num_matches,int max_matches,
                                VS_TAG_RETURN_TYPE (&visited):[]=null,
                                int depth=0)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // look for other imports and global classes in this file
   i := tag_flags := 0;
   class_name := "";
   type_name := "";
   proc_name := "";
   num_matches = tag_get_num_of_context();
   for (i=1; i<=num_matches; i++) {
      if (num_matches > max_matches) break;
      tag_get_detail2(VS_TAGDETAIL_context_flags, i, tag_flags);
      if (tag_flags & SE_TAG_FLAG_ANONYMOUS) {
         continue;
      }
      tag_get_detail2(VS_TAGDETAIL_context_class, i, class_name);
      if (class_name == "" || class_name :== cur_package_name || class_name:==cur_class_name) {
         tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
         if ((type_name :== "class"     && (filter_flags & SE_TAG_FILTER_STRUCT)) ||
             (type_name :== "interface" && (filter_flags & SE_TAG_FILTER_INTERFACE)) ||
             (type_name :== "annotype"  && (filter_flags & SE_TAG_FILTER_ANNOTATION))) {
            tag_tree_insert_fast(tree_wid, tree_root,
                                 VS_TAGMATCH_context, i, 0, 1, 0, 0, 0);
         } else if (type_name:=="package") {
            tag_get_detail2(VS_TAGDETAIL_context_name, i, proc_name);
            tag_list_in_class(lastid_prefix,proc_name,
                              tree_wid,tree_root,tag_files,
                              num_matches,max_matches,
                              filter_flags,
                              context_flags|SE_TAG_CONTEXT_ACCESS_PACKAGE,
                              exact_match,case_sensitive, 
                              null, null, visited, depth+1);
         }
      }
   }

   // list specifically imported classes
   if (num_matches < max_matches) {
      tag_list_context_imports(tree_wid,tree_root,lastid_prefix,tag_files,
                               filter_flags,context_flags,
                               num_matches,max_matches,
                               exact_match,case_sensitive,
                               visited, depth+1);
   }

   // java.lang is always imported
   if (num_matches < max_matches && _LanguageInheritsFrom("java")) {
      tag_list_in_class(lastid_prefix,"java.lang",
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags, 
                        exact_match, case_sensitive,
                        null, null, visited, depth+1);
      tag_list_in_class(lastid_prefix,"java/lang",
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags, 
                        exact_match, case_sensitive,
                        null, null, visited, depth+1);
   }

   // these functions are always imported for JSP pages
   if (num_matches < max_matches && _file_eq(_get_extension(p_buf_name),"jsp")) {
      tag_list_in_class(lastid_prefix,"javax.servlet",
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited, depth+1);
      tag_list_in_class(lastid_prefix,"javax/servlet",
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited, depth+1);
      tag_list_in_class(lastid_prefix,"javax.servlet.jsp",
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited, depth+1);
      tag_list_in_class(lastid_prefix,"javax/servlet/jsp",
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited, depth+1);
      tag_list_in_class(lastid_prefix,"javax.servlet.http",
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited, depth+1);
      tag_list_in_class(lastid_prefix,"javax/servlet/http",
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited, depth+1);
      tag_list_in_class(lastid_prefix,"javax.servlet.jsp.tagext",
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited, depth+1);
      tag_list_in_class(lastid_prefix,"javax/servlet/jsp/tagext",
                        tree_wid,tree_root,tag_files,
                        num_matches,max_matches,
                        filter_flags,context_flags,
                        exact_match,case_sensitive,
                        null, null, visited, depth+1);
   }

   // last ditch attempt, list global classes and interfaces
   if (num_matches < max_matches) {
      tag_list_context_globals(tree_wid, tree_root, lastid,
                               true, tag_files,
                               filter_flags, context_flags,
                               num_matches,max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);
   }
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
   switch (_first_char(word.insertWord)) {
   case "$":
   case "%":
   case "@":
      // For plain old variable references, we want to keep the $.  For
      // references inside of a class (ie: foo->$bar), we want to remove the $.
     if (p_col > 1 && idexp_info.prefixexp != "") {
         word.insertWord = substr(word.insertWord, 2);
      }
   }
}

static int _find_control_name(int wid,_str eventtab,_str lastid,bool exact_match,int eventtab_line)
{
   if (wid.p_object != OI_SSTAB_CONTAINER && wid.p_name!="" &&
       pos(lastid,wid.p_name)==1 &&
       (!exact_match || length(lastid)==length(wid.p_name))) {
      return_type := "";
      switch (wid.p_object) {
      case OI_MDI_FORM:          return_type = "_sc_lang_mdi_form"; break;
      case OI_FORM:              return_type = "_sc_lang_form"; break;
      case OI_TEXT_BOX:          return_type = "_sc_lang_text_box"; break;
      case OI_CHECK_BOX:         return_type = "_sc_lang_check_box"; break;
      case OI_COMMAND_BUTTON:    return_type = "_sc_lang_command_button"; break;
      case OI_RADIO_BUTTON:      return_type = "_sc_lang_radio_button"; break;
      case OI_FRAME:             return_type = "_sc_lang_frame"; break;
      case OI_LABEL:             return_type = "_sc_lang_label"; break;
      case OI_LIST_BOX:          return_type = "_sc_lang_list_box"; break;
      case OI_HSCROLL_BAR:       return_type = "_sc_lang_hscroll_bar"; break;
      case OI_VSCROLL_BAR:       return_type = "_sc_lang_vscroll_bar"; break;
      case OI_COMBO_BOX:         return_type = "_sc_lang_combo_box"; break;
      case OI_HTHELP:            return_type = "_sc_lang_hthelp"; break;
      case OI_PICTURE_BOX:       return_type = "_sc_lang_picture_box"; break;
      case OI_IMAGE:             return_type = "_sc_lang_image"; break;
      case OI_GAUGE:             return_type = "_sc_lang_gauge"; break;
      case OI_SPIN:              return_type = "_sc_lang_spin"; break;
      case OI_MENU:              return_type = "_sc_lang_menu"; break;
      case OI_MENU_ITEM:         return_type = "_sc_lang_menu_item"; break;
      case OI_TREE_VIEW:         return_type = "_sc_lang_tree_view"; break;
      case OI_SSTAB:             return_type = "_sc_lang_sstab"; break;
      case OI_DESKTOP:           return_type = "_sc_lang_desktop"; break;
      case OI_SSTAB_CONTAINER:   return_type = "_sc_lang_sstab_container"; break;
      case OI_EDITOR:            return_type = "_sc_lang_editor"; break;
      case OI_MINIHTML:          return_type = "_sc_lang_minihtml"; break;
      case OI_SWITCH:            return_type = "_sc_lang_switch"; break;
      case OI_TEXTBROWSER:       return_type = "_sc_lang_textbrowser"; break;
      }
      tag_init_tag_browse_info(auto cm, wid.p_name, "", SE_TAG_TYPE_CONTROL, SE_TAG_FLAG_NULL, p_buf_name, eventtab_line);
      cm.return_type = return_type;
      tag_insert_match_browse_info(cm,true);
   }
   return 0;
}

int _e_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         bool find_parents,int max_matches,
                         bool exact_match,bool case_sensitive,
                         SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                         SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                         VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (_chdebug) {
      isay(depth, "_e_find_context_tags: lastid="lastid" prefixexp="prefixexp" exact="exact_match" case="case_sensitive);
      isay(depth, "_e_find_context_tags H"__LINE__": p_buf_name="p_buf_name);
   }

   // hook for javadoc tags, adapted to find-context tags.
   tag_return_type_init(prefix_rt);
   if (info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) {
      return _doc_comment_find_context_tags(errorArgs, prefixexp, 
                                            lastid, lastidstart_offset, 
                                            info_flags, otherinfo, 
                                            find_parents, max_matches, 
                                            exact_match, case_sensitive, 
                                            filter_flags, context_flags, 
                                            visited, depth+1);
   }

   // context is a goto statement?
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: GOTO STATEMENT");
      }
      label_count := 0;
      if (context_flags & SE_TAG_CONTEXT_ALLOW_LOCALS) {
         _CodeHelpListLabels(0, 0, lastid, "",
                             label_count, max_matches,
                             exact_match, case_sensitive, 
                             visited, depth+1);
      }
      return (label_count>0)? 0 : VSCODEHELPRC_NO_LABELS_DEFINED;
   }

   // special case for #import or #require "string.e"
   if ((prefixexp == "#import" || prefixexp=="#require" || prefixexp=="#include") &&
       (info_flags & VSAUTOCODEINFO_IN_PREPROCESSING)) {
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: PREPROCESSING INCLUDE");
      }

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
      prefixChar := get_text(1, lastidstart_offset-1);
      num_headers := insert_files_of_extension( 0, 0, 
                                                p_buf_name,
                                                header_ext, 
                                                false, extraDir, 
                                                true, lastid,
                                                exact_match );

      macros_dir := _getSlickEditInstallPath():+"macros":+FILESEP;
      if (!_file_eq(_strip_filename(p_buf_name,'n'),macros_dir)) {
         num_headers += insert_files_of_extension( 0, 0,
                                                   macros_dir:+FILESEP:+"slick.sh",
                                                   header_ext, 
                                                   false, extraDir, 
                                                   true, lastid,
                                                   exact_match);
      }
      return (num_headers==0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   }

   // is the cursor on #import or #include?
   if (prefixexp == "#" && (info_flags & VSAUTOCODEINFO_IN_PREPROCESSING)) {
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: OTHER PREPROCESSING");
      }
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // get the tag file list
   errorArgs._makeempty();
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   // attempt to evaluate the prefix expression
   status := 0;
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   maybe_control_name := (prefixexp == "");
   if (prefixexp != "") {
      status = _c_get_type_of_prefix(errorArgs, prefixexp, rt, visited, depth+1);
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: prefixexp evalutes to "rt.return_type" status="status);
      }
      prefix_rt = rt;
      if (status == 0 && rt.return_type != "") {
         context_flags |= SE_TAG_CONTEXT_NO_GLOBALS;
         if (pos("_sc_lang_", rt.return_type)==1 && 
             rt.return_type != "_sc_lang_array" &&
             rt.return_type != "_sc_lang_hashtable" &&
             rt.return_type != "_sc_lang_typeless" &&
             rt.return_type != "_sc_lang_string") {
            maybe_control_name = true;
         }
      }
   }

   // attempt to determine what event tab we are in
   eventtab_name := "";
   eventtab_line := 0;
   wid := 0;
   save_pos(auto p);
   typeless p1,p2,p3,p4;
   save_search(p1,p2,p3,p4);
   if ( substr(lastid, 1, 2) != "p_" && 
        (prefixexp=="" || maybe_control_name) &&
        !(info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) &&
        !(info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET)) {
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: NOT PROPERTY, check for control name and event tab");
      }
      // Allocate a selection for searching up 200k backwards.
      orig_mark_id := _duplicate_selection("");
      mark_id := _alloc_selection();
      _select_line(mark_id);
      orig_offset := _QROffset();
      if (orig_offset > 500000) {
         _GoToROffset(orig_offset-500000);
      } else {
         _GoToROffset(0);
      }
      _select_line(mark_id);
      _show_selection(mark_id);
      _end_select(mark_id);

      // search for the event table statement
      searchStatus := search("^ *defeventtab +{:v}","@m-rh");
      if (searchStatus == 0) {
         eventtab_name = get_match_text(0);
         eventtab_line = p_RLine;
         dash_eventtab_name := stranslate(eventtab_name,"-","_");
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

   // look for a control
   num_matches := 0;
   tag_clear_matches();
   if (wid && eventtab_name!="" && maybe_control_name) {
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: eventtab="eventtab_name);
      }
      tag_list_in_class(lastid, eventtab_name, 
                        0, 0, tag_files,
                        num_matches, max_matches,
                        filter_flags, context_flags,
                        exact_match, case_sensitive,
                        null, "", 
                        visited,depth+1);
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: NUM CONTROLS FOUND="num_matches);
      }
   }
   if (wid && eventtab_name!="" && tag_get_num_of_matches() <= 0) {
      _for_each_control(wid,_find_control_name,'H',eventtab_name,lastid,exact_match,eventtab_line);
      num_matches = tag_get_num_of_matches();
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: wid="wid" NUM CONTROLS FOUND="num_matches);
      }
   }

   // id followed by paren, then limit search to functions
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= SE_TAG_CONTEXT_ONLY_FUNCS;
   }

   // this instance is not a function, so mask it out of filter flags
   if (info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
      filter_flags &= ~(SE_TAG_FILTER_PROCEDURE|SE_TAG_FILTER_PROTOTYPE);
   }

   // try to match the symbol in the current context
   if (!status) {
      context_list_flags := SE_TAG_CONTEXT_ANYTHING;
      if ( find_parents && !(rt.return_flags & (VSCODEHELP_RETURN_TYPE_STATIC_ONLY|VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY)) ) {
         context_list_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
      }
      tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, tag_files, "",
                                  num_matches, max_matches,
                                  filter_flags,
                                  context_flags | context_list_flags | SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE | ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS),
                                  exact_match, case_sensitive, visited, depth+1);
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: FIRST SEARCH, num_matches="num_matches);
      }
      if (num_matches == 0 && !exact_match && !(context_list_flags & SE_TAG_CONTEXT_FIND_LENIENT)) {
         context_list_flags |= SE_TAG_CONTEXT_FIND_LENIENT;
         tag_list_symbols_in_context(lastid, rt.return_type, 0, 0, tag_files, "",
                                     num_matches, max_matches,
                                     filter_flags,
                                     context_flags | context_list_flags | SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE | ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? SE_TAG_CONTEXT_ANYTHING:SE_TAG_CONTEXT_ALLOW_LOCALS),
                                     exact_match, case_sensitive, visited, depth+1);
         if (_chdebug) {
            isay(depth, "_e_find_context_tags: LENIENT SEARCH, num_matches="num_matches);
         }
      }
      if (num_matches == 0 && maybe_control_name && (filter_flags & (SE_TAG_FILTER_PROCEDURE|SE_TAG_FILTER_PROTOTYPE))) {
         tag_list_symbols_in_context(lastid, "", 0, 0, tag_files, p_buf_name,
                                     num_matches, max_matches,
                                     filter_flags,
                                     context_flags | context_list_flags | SE_TAG_CONTEXT_ONLY_STATIC,
                                     exact_match, case_sensitive, visited, depth+1);
         if (_chdebug) {
            isay(depth, "_e_find_context_tags: STATIC CLASS MEMBER FOR CONTROL, num_matches="num_matches);
         }
      }
   }

   // insert the 'this' symbol
   if (prefixexp == "" && _CodeHelpMaybeInsertThis( lastid, "this", 
                                                    tag_files, 
                                                    filter_flags, context_flags, 
                                                    exact_match, case_sensitive,
                                                    false, "", visited, depth+1)) {
      num_matches++;
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: ADDING 'this'");
      }
   }

   // find procs that belong to control names
   if (prefixexp != "" && (status < 0 || (rt.return_flags & VSCODEHELP_RETURN_TYPE_BUILTIN))) {
      int i=tag_find_context_iterator(prefixexp, false, true);
      while (i > 0) {
         type_name := "";
         tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
         if (tag_tree_type_is_func(type_name)) {
            tag_init_tag_browse_info(auto cm);
            tag_get_context_info(i, cm);
            tag_names := substr(cm.member_name, length(prefixexp)+1);
            while (tag_names != "") {
               parse tag_names with auto tag_name "," tag_names;
               if (tag_name != "" &&
                   (lastid=="" || pos(lastid,tag_name)==1) &&
                   (!exact_match || length(lastid)==length(tag_name))) {
                  cm.member_name = tag_name;
                  tag_tree_insert_info(0, 0, cm, false,1,0);
                  num_matches++;
                  if (_chdebug) {
                     isay(depth, "_e_find_context_tags: found proc: "tag_name);
                  }
               }
            }
         }
         i=tag_next_context_iterator(prefixexp, i, false, true);
      }
   }

   // find control names that belong to procs
   if (prefixexp == "") {
      int i=tag_find_context_iterator(prefixexp, false, true);
      while (i > 0) {
         type_name := "";
         tag_name  := "";
         tag_flags := SE_TAG_FLAG_NULL;
         tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
         tag_get_detail2(VS_TAGDETAIL_context_name, i, tag_name);
         if (tag_tree_type_is_func(type_name) && pos(".", tag_name)) {
            tag_get_detail2(VS_TAGDETAIL_context_flags, i, tag_flags);
            parse tag_name with tag_name "." .;
            if (tag_name != "" &&
                pos(lastid,tag_name)==1 &&
                (!exact_match || length(lastid)==length(tag_name))) {
               tag_tree_insert_tag(0, 0, 0,1,0,tag_name,"control","",0,"",(int)tag_flags,"");
               num_matches++;
               if (_chdebug) {
                  isay(depth, "_e_find_context_tags: found control: "tag_name);
               }
            }
         }
         i=tag_next_context_iterator(prefixexp, i, false, true);
      }
   }

   // look for slick-c builtins
   if ((num_matches == 0 || maybe_control_name) && lastid != "") {
      // Slick-C builtins, just dump them in 'globals'
      tag_list_in_file(0, 0, lastid, tag_files,
                       "builtins.e", SE_TAG_FILTER_PROTOTYPE|SE_TAG_FILTER_PROPERTY,
                       context_flags | SE_TAG_CONTEXT_ONLY_NON_STATIC,
                       num_matches, max_matches,
                       true, true, visited, depth+1);
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: BUILTINS, num_matches="num_matches);
      }
   }

   // really getting very desperate for a match here
   // stop here if we are only searching context
   if ((num_matches==0 || maybe_control_name) && lastid != "" && prefixexp!="" &&
       !(context_flags & SE_TAG_CONTEXT_ONLY_CONTEXT)) {
      context_flags &= ~ SE_TAG_CONTEXT_NO_GLOBALS;
      if (_chdebug) {
         tag_dump_context_flags(context_flags, "_e_find_context_tags: GLOBALS", depth);
      }
      tag_list_context_globals(0,0,lastid,true,tag_files,
                               SE_TAG_FILTER_ANY_PROCEDURE,context_flags,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);
      if (_chdebug) {
         isay(depth, "_e_find_context_tags: GLOBALS, num_matches="num_matches);
      }
   }

   if (_chdebug) {
      isay(depth, "_e_find_context_tags: RETURNING num_matches="num_matches" actual number="tag_get_num_of_matches());
      tag_dump_matches("_e_find_context_tags", depth+1);
   }

   // be forgiving even if we had a bad return type status
   if (status && prefixexp!="") {
      return (num_matches == 0)? status:0;
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=="")? rt.return_type:lastid;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}
/**
 * @see _java_find_context_tags
 */
int _cs_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                          _str lastid,int lastidstart_offset,
                          int info_flags,typeless otherinfo,
                          bool find_parents,int max_matches,
                          bool exact_match, bool case_sensitive,
                          SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                          SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                          VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,find_parents,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth,prefix_rt);
}
/**
 * Find the superclass of 'cur_class_name' and place it in 'lastid'
 * Otherwise, do not modify 'lastid'
 *
 * @param lastid           (reference) on success, set to name of superclass
 * @param cur_class_name   current class context
 * @param tag_files        list of tag files to check
 */
void _java_find_super(_str &superclass, _str cur_class_name, typeless tag_files, 
                      bool qualify_classname=true,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // is this a reference to the constructor of the parent class in Java?
   // make sure that the context doesn't get modified by a background thread.
   superclass="";
   tag_lock_context();
   tag_dbs := "";
   parents := cb_get_normalized_inheritance(cur_class_name, tag_dbs, tag_files, true, "", p_buf_name, "", true, visited, depth+1);
   if ( _chdebug ) {
      isay(depth, "_java_find_super: cur_class_name="cur_class_name" parents="parents);
   }
   while (parents != "") {
      _str p1,t1;
      parse parents with p1 ";" parents;
      parse tag_dbs with t1 ";" tag_dbs;
      if (t1!="" && tag_read_db(t1)<0) {
         continue;
      }
      // add transitively inherited class members
      if (qualify_classname) {
         superclass = p1;
         break;
      }
      inner_class := outer_class := "";
      parse p1 with p1 "<" .;
      tag_split_class_name(p1, inner_class, outer_class);
      if ((t1!="" && tag_find_tag(inner_class, "class", outer_class)==0) ||
          tag_find_context_iterator(inner_class,true,true,false,outer_class) > 0) {
         superclass=inner_class;
         break;
      }
   }
   tag_reset_find_tag();
   tag_unlock_context();
}
/**
 * @see _do_default_find_context_tags
 */
int _java_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                            _str lastid,int lastidstart_offset,
                            int info_flags,typeless otherinfo,
                            bool find_parents,int max_matches,
                            bool exact_match, bool case_sensitive,
                            SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                            SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                            VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "_java_find_context_tags: ------------------------------------------------------");
      isay(depth, "_java_find_context_tags: lastid="lastid" prefixexp="prefixexp" exact="exact_match" case_sensitive="case_sensitive);
      tag_dump_filter_flags(filter_flags,   "_java_find_context_tags: FILTER FLAGS", depth);
      tag_dump_context_flags(context_flags, "_java_find_context_tags: CONTEXT FLAGS", depth);
   }
   // hook for javadoc tags, adapted to find-context tags.
   tag_return_type_init(prefix_rt);
   if (info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) {
      return _doc_comment_find_context_tags(errorArgs, prefixexp, 
                                            lastid, lastidstart_offset, 
                                            info_flags, otherinfo, 
                                            find_parents, max_matches, 
                                            exact_match, case_sensitive, 
                                            filter_flags, context_flags, 
                                            visited, depth+1);
   }

   // context is a goto statement?
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      label_count := 0;
      if (context_flags & SE_TAG_CONTEXT_ALLOW_LOCALS) {
         _CodeHelpListLabels(0, 0, lastid, "",
                             label_count, max_matches,
                             exact_match, case_sensitive, 
                             visited, depth+1);
      }
      return (label_count>0)? 0 : VSCODEHELPRC_NO_LABELS_DEFINED;
   }

   //say("_e_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   errorArgs._makeempty();
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);
   if (p_LangId == "js") {
      tag_files = tag_find_context_tags_filenamea("java", context_flags);
   }
   if (p_LangId == "scala" || _LanguageInheritsFrom('kotlin')) {
      jtf := java_get_active_compile_tag_file();
      if (jtf != '') {
         tag_files :+= jtf;
      }
   }
   if ((context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) ||
       (context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE)) {
      tag_files._makeempty();
   }

   // context is in using or import statement?
   num_matches := 0;
   if (prefixexp == "" && (info_flags & VSAUTOCODEINFO_IN_IMPORT_STATEMENT)) {
      tag_list_context_globals(0, 0, lastid,
                               true, tag_files,
                               SE_TAG_FILTER_PACKAGE, SE_TAG_CONTEXT_ANYTHING,
                               num_matches,max_matches,
                               exact_match, case_sensitive,
                               visited, depth+1);
      if (_chdebug) {
         isay(depth, "_java_find_context_tags: FIND GLOBALS FOR IMPORT STATEMENT");
      }
      return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // get the current class and current package from the context
   tag_init_tag_browse_info(auto cm);
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_tag_flags,
                                         auto cur_type_name, auto cur_type_id,
                                         auto cur_class_name, auto cur_class_only,
                                         auto cur_package_name,
                                         visited, depth+1);

   // id followed by paren, then limit search to functions
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= SE_TAG_CONTEXT_ONLY_FUNCS;
   }


   // if this is a static function, only list static methods and fields
   if (context_id>0 && cur_type_id==SE_TAG_TYPE_FUNCTION && cur_class_name!="" && prefixexp=="") {
      if (cur_tag_flags & SE_TAG_FLAG_STATIC) {
         context_flags |= SE_TAG_CONTEXT_ONLY_STATIC;
      } else if (p_LangId == 'scala') {
         // For scala, don't suggest static methods when in a regular method.
         context_flags |= SE_TAG_CONTEXT_ONLY_NON_STATIC;
      }

   }

   // looking specifically for annotation types here
   if (substr(prefixexp,1, 1)=="@" && (_LanguageInheritsFrom("java") || p_LangId == "groovy" || p_LangId == "scala"
                                       || _LanguageInheritsFrom('kotlin'))) {
      prefixexp = substr(prefixexp,2);
      filter_flags = SE_TAG_FILTER_ANNOTATION;
      if (prefixexp == "") {
         // update the classes, make sure that case-sensitive matches get preference
         // first try case-sensitive matches
         java_insert_imports(0, 0, tag_files,
                             cur_package_name, cur_class_name,
                             lastid, lastid,
                             SE_TAG_FILTER_ANNOTATION,
                             SE_TAG_CONTEXT_ACCESS_PUBLIC,
                             exact_match, case_sensitive,
                             num_matches, max_matches, visited);
         return (num_matches > 0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
      }

   // no prefix expression, update globals and members from current context
   } else if (prefixexp == "" || prefixexp == "new") {

      // narrow down filters if this is a "new" expression
      if (prefixexp == "new") {
         if (_chdebug) {
            isay(depth, "_java_find_context_tags H"__LINE__": HAVE NEW");
         }
         filter_flags &= ~SE_TAG_FILTER_ANY_DATA;
         //filter_flags &= ~SE_TAG_FILTER_ANY_PROCEDURE;
         filter_flags &= ~SE_TAG_FILTER_DEFINE;
         filter_flags &= ~SE_TAG_FILTER_LABEL;
      }

      // insert the 'this' symbol
      if (prefixexp == "new" && _CodeHelpMaybeInsertThis( lastid, "this", 
                                                          tag_files, 
                                                          filter_flags, context_flags, 
                                                          exact_match, case_sensitive,
                                                          false, "", visited, depth+1)) {
         num_matches++;
      }

      // insert the 'super' symbol
      
      // replace 'super' with the name of the superclass
      super_id   := (_LanguageInheritsFrom("cs")? "base" : "super");
      if (prefixexp != "new" && _CodeHelpDoesIdMatch(lastid, super_id, exact_match, case_sensitive)) {
         _java_find_super(auto superclass,cur_class_name,tag_files,true,visited,depth+1);
         if (superclass != "" && _CodeHelpMaybeInsertThis(lastid, super_id, tag_files, 
                                                          filter_flags, context_flags, 
                                                          exact_match, case_sensitive, 
                                                          true, superclass,
                                                          visited, depth+1)) {
            num_matches++;
         }
      }

      // insert the 'value' parameter if we are in a C# property getter or setter
      if (prefixexp != "new" && _LanguageInheritsFrom("cs") && 
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

         // if we are in the setting, well, it usually has a return type of 'void'
         if (cur_return_type == "" || cur_return_type == "void") {
            outer_id := 0;
            tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, outer_id);
            if ( outer_id > 0) {
               outer_type := "";
               tag_get_detail2(VS_TAGDETAIL_context_type, outer_id, outer_type);
               if (outer_type == "prop") {
                  tag_get_detail2(VS_TAGDETAIL_context_return, outer_id, cur_return_type);
               }
            }
         }

         tag_init_tag_browse_info(cm, "value", "", SE_TAG_TYPE_PARAMETER, SE_TAG_FLAG_NULL, p_buf_name, cur_line_no);
         cm.return_type = cur_return_type;
         tag_insert_match_browse_info(cm,true);
         num_matches++;
      }

      // Find jsp.vtg instead of passing in all tag_files
      if (_file_eq(_get_extension(p_buf_name), "jsp")) {
         if (!(context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE) &&
             !(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) &&
             !(context_flags & SE_TAG_CONTEXT_NO_GLOBALS)) {
            _str jsp_tag_files[];
            jsp_tag_files[0] = _tagfiles_path() :+ "jsp" :+ TAG_FILE_EXT;
            tag_list_context_globals(0, 0, lastid,
                                     true, jsp_tag_files,
                                     filter_flags, context_flags,
                                     num_matches, max_matches, 
                                     exact_match, case_sensitive, 
                                     visited, depth+1);
         }
      }

      // list explicitely imported packages from current context
      if (!(context_flags & SE_TAG_CONTEXT_ONLY_INCLASS) &&
          !(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS)) {

         // java.lang is always imported
         if (_LanguageInheritsFrom("java") && _CodeHelpDoesIdMatch(lastid, "java", exact_match, case_sensitive)) {
            tag_init_tag_browse_info(cm, "java", "", SE_TAG_TYPE_PACKAGE);
            tag_insert_match_browse_info(cm,true);
            num_matches++;
            if (!exact_match) {
               cm.member_name="java.lang";
               tag_insert_match_browse_info(cm,true);
               num_matches++;
            }
         }

         // javax.servlet is always imported into JSP
         if (_file_eq(_get_extension(p_buf_name), "jsp")) {
            if (_CodeHelpDoesIdMatch(lastid, "javax", exact_match, case_sensitive)) {
               tag_init_tag_browse_info(cm, "javax", "", SE_TAG_TYPE_PACKAGE);
               tag_insert_match_browse_info(cm,true);
               num_matches++;
               if (!exact_match) {
                  cm.member_name="javax.servlet";
                  tag_insert_match_browse_info(cm,true);
                  cm.member_name="javax.servlet.http";
                  tag_insert_match_browse_info(cm,true);
                  cm.member_name="javax.servlet.jsp";
                  tag_insert_match_browse_info(cm,true);
                  cm.member_name="javax.servlet.jsp.tagext";
                  tag_insert_match_browse_info(cm,true);
                  num_matches+=4;
               }
            }
         }

         n := tag_get_num_of_context();
         for (i:=1; i<=n; i++) {
            type_name := proc_name := package_name := first_name := "";
            package_line := 0;
            package_seekpos := 0;
            tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
            tag_get_detail2(VS_TAGDETAIL_context_line, i, package_line);
            tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, i, package_seekpos);
            if (type_name :== "package") {
               tag_get_detail2(VS_TAGDETAIL_context_name, i, proc_name);
               tag_get_detail2(VS_TAGDETAIL_context_class, i, package_name);
               package_name = stranslate(package_name, ".", VS_TAGSEPARATOR_class);
               package_name = stranslate(package_name, ".", VS_TAGSEPARATOR_package);
               if (package_name == "") package_name = proc_name;
               else package_name = package_name "." proc_name;

            } else if (type_name :== "import") {
               tag_get_detail2(VS_TAGDETAIL_context_name, i, proc_name);
               proc_name = stranslate(proc_name, ".", VS_TAGSEPARATOR_class);
               proc_name = stranslate(proc_name, ".", VS_TAGSEPARATOR_package);
               if (pos(".*", proc_name) > 0) {
                  package_name = substr(proc_name, 1, pos('S')-1);
               } else if (pos("._", proc_name) > 0) {
                  package_name = substr(proc_name, 1, pos('S')-1);
                  proc_name = substr(proc_name, 1, pos('S')):+'*';
               } else if (lastpos(".", proc_name) > 0) {
                  package_name = substr(proc_name, 1, pos('S')-1);
                  proc_name = substr(proc_name, pos('S')+1);
                  if (_CodeHelpDoesIdMatch(lastid, proc_name, exact_match, case_sensitive)) {
                     cm.type_name = "import";
                     cm.member_name = proc_name;
                     cm.class_name = package_name;
                     cm.file_name = p_buf_name;
                     cm.line_no = package_line;
                     cm.seekpos = package_seekpos;
                     tag_insert_match_browse_info(cm,true);
                     num_matches++;
                  }
               }
            }
            if (package_name != "") {
               parse package_name with first_name "." package_name;
               if (_CodeHelpDoesIdMatch(lastid, first_name, exact_match, case_sensitive)) {
                  cm.type_name = "package";
                  cm.member_name = first_name;
                  cm.class_name = "";
                  cm.file_name = p_buf_name;
                  cm.line_no = package_line;
                  cm.seekpos = package_seekpos;
                  tag_insert_match_browse_info(cm,true);
                  num_matches++;
                  if (!exact_match) {
                     proc_name = first_name;
                     while (package_name != "") {
                        parse package_name with first_name "." package_name;
                        proc_name :+= "." first_name;
                        cm.type_name = "package";
                        cm.member_name = proc_name;
                        cm.class_name = "";
                        cm.file_name = p_buf_name;
                        cm.line_no = package_line;
                        cm.seekpos = package_seekpos;
                        tag_insert_match_browse_info(cm,true);
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
                                     SE_TAG_TYPE_PACKAGE, 0, 0,
                                     num_matches, max_matches,
                                     visited, depth+1);
            if (_chdebug) {
               isay(depth, "_java_find_context_tags H"__LINE__": after tag_list_globals_of_type, num_matches="num_matches);
            }
         } else {
            tag_list_context_packages(0, 0, lastid, tag_files, 
                                      num_matches, max_matches, 
                                      exact_match, case_sensitive,
                                      visited, depth+1);
            if (_chdebug) {
               isay(depth, "_java_find_context_tags H"__LINE__": after tag_list_context_packages, num_matches="num_matches);
            }
         }
      }

      // check for matches
      orig_num_matches := num_matches;
      context_list_flags := (find_parents)? SE_TAG_CONTEXT_FIND_PARENTS : 0;
      noimport_filter_flags := (filter_flags & ~(SE_TAG_FILTER_INCLUDE));
      //if (!case_sensitive) {
      //   tag_list_symbols_in_context(lastid, "", 
      //                               0, 0, tag_files, "",
      //                               num_matches, max_matches,
      //                               noimport_filter_flags,
      //                               context_flags|context_list_flags,
      //                               exact_match, true,//case_sensitive,
      //                               visited, depth+1);
      //   if (_chdebug) {
      //      isay(depth, "_java_find_context_tags: IN CONTEXT, CASE SENSITIVE, matches="num_matches);
      //   }
      //}
      if (_chdebug) {
         tag_dump_filter_flags(filter_flags,   "_java_find_context_tags: BEFORE tag_list_symbols_in_context: FILTER FLAGS", depth);
         tag_dump_context_flags(context_flags, "_java_find_context_tags: BEFORE tag_list_symbols_in_context: CONTEXT FLAGS", depth);
      }
      tag_list_symbols_in_context(lastid, "", 
                                  0, 0, tag_files, "",
                                  num_matches, max_matches,
                                  noimport_filter_flags, 
                                  context_flags|context_list_flags,
                                  exact_match, case_sensitive,
                                  visited, depth+1);
      if (_chdebug) {
         isay(depth, "_java_find_context_tags: IN CONTEXT, matches="num_matches);
      }

      // remove ONLY static flag if search yielded no results
      if (exact_match && num_matches == orig_num_matches && 
          (context_flags & (SE_TAG_CONTEXT_ONLY_STATIC|SE_TAG_CONTEXT_ONLY_NON_STATIC))) {
         if (_chdebug) {
            isay(depth, "_java_find_context_tags: RETRY IGNORING STATIC");
         }
         context_flags_no_static := context_flags & ~(SE_TAG_CONTEXT_ONLY_STATIC|SE_TAG_CONTEXT_ONLY_NON_STATIC);
         tag_list_symbols_in_context(lastid, "", 
                                     0, 0, tag_files, "",
                                     num_matches, max_matches,
                                     noimport_filter_flags, 
                                     context_flags_no_static|context_list_flags,
                                     exact_match, case_sensitive,
                                     visited, depth+1);
         if (_chdebug) {
            isay(depth,"_c_find_context_tags: IN CONTEXT FIND IGNORE STATIC lastid="lastid" num_matches="num_matches);
         }
      }

      // if the identifier was followed by a paren, and the search come up with nothing,
      // we could have a variable with a pointer to function type
      if (num_matches == 0 && (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) && (context_flags & SE_TAG_CONTEXT_ONLY_FUNCS)) {
         tag_list_symbols_in_context(lastid, "", 
                                     0, 0, tag_files, "",
                                     num_matches, max_matches,
                                     noimport_filter_flags, 
                                     (context_flags|context_list_flags) & ~SE_TAG_CONTEXT_ONLY_FUNCS,
                                     exact_match, case_sensitive,
                                     visited, depth+1);
      }

      // no early return if we are looking for a constructor
      if (prefixexp != "new") {
         if (num_matches > 0) {
            if (_chdebug) {
               tag_dump_matches("_java_find_context_tags: IN CONTEXT MATCHES", depth+1);
            }
            return 0;
         }
         status := _do_default_find_context_tags(errorArgs, "",
                                                 lastid, lastidstart_offset,
                                                 info_flags, otherinfo, 
                                                 find_parents, max_matches, 
                                                 exact_match, case_sensitive,
                                                 filter_flags, context_flags,
                                                 visited, depth+1);
         if (_chdebug) {
            isay(depth, "_java_find_context_tags: DEFAULT FIND CONTEXT, matches="num_matches" status="status);
         }
         if (_chdebug) {
            tag_dump_matches("_java_find_context_tags: DEFAULT FIND CONTEXT MATCHEDS", depth+1);
         }
         return status;
      }
   }

   // maybe prefix expression is a package name or prefix of package name
   is_package := _CodeHelpListPackages(0, 0,
                                       p_window_id, tag_files,
                                       prefixexp, lastid,
                                       num_matches, max_matches,
                                       exact_match, case_sensitive,
                                       visited, depth+1);

   // evaluate the prefix expression
   status := 0;
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   if (prefixexp != "") {
      status = _java_get_type_of_prefix(errorArgs, prefixexp, rt, visited, depth+1);
      prefix_rt = rt;
      if (_chdebug) {
         isay(depth, "_java_find_context_tags: prefix status="status);
         tag_return_type_dump(rt, "_java_find_context_tags: prefix rt", depth);
      }
      if (endsWith(prefixexp, "->") && status == VSCODEHELPRC_CONTEXT_NOT_VALID) {
         // try again, this -> prefix expression never should have happened.
         return _java_find_context_tags(errorArgs, "", 
                                        lastid, lastidstart_offset, 
                                        info_flags, otherinfo, 
                                        find_parents, max_matches, 
                                        exact_match, case_sensitive, 
                                        filter_flags, context_flags, 
                                        visited, depth);
      }
      if (status && num_matches==0) {
         return status;
      }
   } else {
      status = 0;
   }

   if (!status) {
      if (p_LangId == 'scala' && prefixexp != '') {
         if (isupper(substr(prefixexp, 1, 1))) {
            // It's a type, or an object, we want to see static methods.
            context_flags |= SE_TAG_CONTEXT_ONLY_STATIC;
         } else {
            context_flags |= SE_TAG_CONTEXT_ONLY_NON_STATIC;
         }
      }

      // pick up other context flags depending on class scope      
      if ((pos(cur_package_name"/",rt.return_type)==1) ||
          (!pos(VS_TAGSEPARATOR_package,rt.return_type) &&
           !pos(VS_TAGSEPARATOR_package,cur_class_name))) {
         if ( _chdebug ) {
            isay(depth, "_java_find_context_tags H"__LINE__": H1, rt.return_type="rt.return_type" cur_class_name="cur_class_name" cur_package_name="cur_package_name);
         }
         context_flags |= SE_TAG_CONTEXT_ALLOW_PACKAGE;
         if ( !_LanguageInheritsFrom("cs") ) {
            context_flags |= SE_TAG_CONTEXT_ALLOW_PROTECTED;
         }
      }
      if (tag_is_parent_class(rt.return_type,cur_class_name,tag_files,false,false,null,visited,depth+1)) {
         if ( _chdebug ) {
            isay(depth, "_java_find_context_tags H"__LINE__": H2, rt.return_type="rt.return_type" cur_class_name="cur_class_name);
         }
         context_flags |= SE_TAG_CONTEXT_ACCESS_PACKAGE;
         if ( !_LanguageInheritsFrom("cs") ) {
            context_flags |= SE_TAG_CONTEXT_ACCESS_PROTECTED;
         }
      }
      if (tag_check_for_package(rt.return_type, tag_files, true, true, null, visited, depth+1)) {
         context_flags |= SE_TAG_CONTEXT_ALLOW_PACKAGE;
      }
      if (pos(rt.return_type:+VS_TAGSEPARATOR_class, cur_class_name)==1) {
         context_flags |= SE_TAG_CONTEXT_ALLOW_PRIVATE;
      }

      context_flags |= _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags, context_flags);

      // add the builtin new method
      tag_init_tag_browse_info(cm);
      if (prefixexp != "new" &&
          !(rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) && 
          _LanguageInheritsFrom("java") && 
          _CodeHelpDoesIdMatch(lastid, "new", exact_match, case_sensitive)) {
         cm.type_name = "constr";
         cm.member_name = "new";
         cm.line_no = 1;
         tag_insert_match_browse_info(cm,true);
         num_matches++;
      }
         
      // add the builtin length attribute
      if (prefixexp != "new" &&
          (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY) && 
          _LanguageInheritsFrom("java") &&
          _CodeHelpDoesIdMatch(lastid, "length", exact_match, case_sensitive)) {
         cm.type_name = "prop";
         cm.member_name = "length";
         cm.return_type = "int";
         cm.line_no = 1;
         tag_insert_match_browse_info(cm,true);
         num_matches++;
      }

      // add the builtin clone method
      if (prefixexp != "new" &&
          (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY) && 
          _LanguageInheritsFrom("java") &&
          _CodeHelpDoesIdMatch(lastid, "clone", exact_match, case_sensitive)) {
         cm.type_name = "func";
         cm.member_name = "clone";
         cm.line_no = 1;
         cm.return_type = "";
         tag_insert_match_browse_info(cm,true);
         num_matches++;
      }

      if (prefixexp != "new" && _LanguageInheritsFrom("d")) {
         tag_get_info_from_return_type(rt, auto rt_cm);
         if (tag_tree_type_is_class(rt_cm.type_name) || tag_tree_type_is_data(rt_cm.type_name)) {
            // The .tupleof property returns an ExpressionTuple of all the 
            // fields in the class,\nexcluding the hidden fields and the 
            // fields in the base class"));
            tag_init_tag_browse_info(cm);
            if (_CodeHelpDoesIdMatch(lastid, "tupleof", exact_match, case_sensitive)) {
               cm.type_name = "prop";
               cm.member_name = "tupleof";
               cm.line_no = 1;
               cm.return_type = "ExpressionTuple";
               tag_insert_match_browse_info(cm,true);
               num_matches++;
            }
            // Size in bytes of struct
            if (_CodeHelpDoesIdMatch(lastid, "sizeof", exact_match, case_sensitive)) {
               cm.type_name = "prop";
               cm.member_name = "sizeof";
               cm.line_no = 1;
               cm.return_type = "int";
               tag_insert_match_browse_info(cm,true);
               num_matches++;
            }
            // Size boundary struct needs to be aligned on
            if (_CodeHelpDoesIdMatch(lastid, "alignof", exact_match, case_sensitive)) {
               cm.type_name = "prop";
               cm.member_name = "alignof";
               cm.line_no = 1;
               cm.return_type = "int";
               tag_insert_match_browse_info(cm,true);
               num_matches++;
            }
            // Provides access to the encosing (outer) class
            if (pos(VS_TAGSEPARATOR_class, rt.return_type) > 0 &&
                _CodeHelpDoesIdMatch(lastid, "outer", exact_match, case_sensitive)) {
               tag_split_class_name(rt.return_type, auto inner_name, auto outer_name);
               cm.type_name = "prop";
               cm.member_name = "outer";
               cm.line_no = 1;
               cm.return_type = outer_name;
               tag_insert_match_browse_info(cm,true);
               num_matches++;
            }
            // Allocate an instance of a subclass
            if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) && 
                !(rt_cm.flags & SE_TAG_FLAG_TEMPLATE) &&
                _CodeHelpDoesIdMatch(lastid, "new", exact_match, case_sensitive)) {
               cm.type_name = "constr";
               cm.member_name = "new";
               cm.line_no = 1;
               tag_insert_match_browse_info(cm,true);
               num_matches++;
            }
         }

         if (rt_cm.type_name=="enum") {
            // Smallest value of enum
            tag_init_tag_browse_info(cm);
            if (_CodeHelpDoesIdMatch(lastid, "min", exact_match, case_sensitive)) {
               cm.type_name = "prop";
               cm.member_name = "min";
               cm.line_no = 1;
               cm.return_type = "int";
               tag_insert_match_browse_info(cm,true);
               num_matches++;
            }
            // Largest value of enum
            if (_CodeHelpDoesIdMatch(lastid, "max", exact_match, case_sensitive)) {
               cm.type_name = "prop";
               cm.member_name = "max";
               cm.line_no = 1;
               cm.return_type = "int";
               tag_insert_match_browse_info(cm,true);
               num_matches++;
            }
            // First enum member value
            if (_CodeHelpDoesIdMatch(lastid, "init", exact_match, case_sensitive)) {
               cm.type_name = "prop";
               cm.member_name = "init";
               cm.line_no = 1;
               cm.return_type = "int";
               tag_insert_match_browse_info(cm,true);
               num_matches++;
            }
            // Size of storage for an enumerated value
            if (_CodeHelpDoesIdMatch(lastid, "sizeof", exact_match, case_sensitive)) {
               cm.type_name = "prop";
               cm.member_name = "sizeof";
               cm.line_no = 1;
               cm.return_type = "int";
               tag_insert_match_browse_info(cm,true);
               num_matches++;
            }
         }

         if (rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) {
            if (rt_cm.flags & SE_TAG_FLAG_TEMPLATE) {
               rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_STATIC_ONLY);
               context_flags &= ~(SE_TAG_CONTEXT_ONLY_STATIC);
               context_flags |= SE_TAG_CONTEXT_ONLY_THIS_CLASS;
            }
         }
      }
      if (is_package) {
         context_flags|=SE_TAG_CONTEXT_ONLY_THIS_CLASS;
      }

      constructor_class := rt.return_type;
      is_new_expr := pos("new ",prefixexp" ")==1;
      // this only works for really simple class names
      outer_class := is_new_expr ? substr(prefixexp, 5) : rt.return_type;
      if (is_new_expr) parse prefixexp with prefixexp '(' .;

      if (status && is_new_expr) {
         // Type name isn't complete, so return possible type names.
         status = tag_list_symbols_in_context(outer_class, null, 0, 0, tag_files, "", num_matches, 10,
                                              SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_ANY_SYMBOL,
                                              SE_TAG_CONTEXT_ONLY_CLASSES, exact_match, case_sensitive, visited, depth+1);
         if (_chdebug) {
            isay(depth, "_java_find_context_tags: NEW expr status="status" num_matches="num_matches" status="status);
         }
      }

      if (status < 0) {
         return status;
      }

      // handle 'new' expressions as a special case
      if (is_new_expr && 
          ((info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) ||
           (prefixexp == "new" && !(info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL)) )) {
         _maybe_strip(outer_class, '::');
         _maybe_strip(outer_class, '.');
         outer_class = stranslate(outer_class, ":", "::");
         if (outer_class=="" && exact_match) {
            tag_qualify_symbol_name(constructor_class,lastid,cur_class_name,p_buf_name,tag_files,true, visited, depth+1);
         } else if (outer_class=="") {
            tag_qualify_symbol_name(constructor_class,lastid,"",p_buf_name,tag_files,true, visited, depth+1);
         } else {
            constructor_class = tag_join_class_name(lastid, outer_class, tag_files, true, false, false, visited, depth+1);
         }
         if (constructor_class == "") {
            if (_chdebug) {
               isay(depth, "_java_find_context_tags: is_new_expr reset constructor_class");
            }
            constructor_class = rt.return_type;
         }
         if (constructor_class == "" && exact_match) {
            if (_chdebug) {
               isay(depth, "_java_find_context_tags: is_new_expr reset constructor_class to lastid");
            }
            constructor_class = lastid;
         }
         if (_chdebug) {
            isay(depth, "_java_find_context_tags: is_new_expr AFTER: constructor_class="constructor_class" outer_class="outer_class);
         }
      }

      if (find_parents && !(rt.return_flags & (VSCODEHELP_RETURN_TYPE_STATIC_ONLY|VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY))) {
         context_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
      }

      if (_chdebug) {
         tag_dump_filter_flags(filter_flags, "_java_find_context_tags: FINAL FILTER FLAGS", depth);
         tag_dump_context_flags(context_flags, "_java_find_context_tags: FINAL CONTEXT FLAGS", depth);
         isay(depth, "_java_find_context_tags: constructor_class="constructor_class);
      }

      if (constructor_class != "") {
         handle := _ProjectHandle();
         if (prefixexp != "" && pos("R.",prefixexp) == 1 && _ProjectGet_AppType(handle) == "android") {
            context_flags = SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE;
            wkspace_tagfiles := project_tags_filenamea();
            tag_list_any_symbols(0,0,lastid,
                                 wkspace_tagfiles,
                                 filter_flags,context_flags,
                                 num_matches,max_matches,
                                 exact_match,case_sensitive,
                                 visited, depth+1);
            if (_chdebug) {
               isay(depth, "_java_find_context_tags H"__LINE__": after tag_list_any_symbols, WORKSPACE num_matches="num_matches);
            }
            if (num_matches == 0) {
               tag_list_any_symbols(0,0,lastid,tag_files,filter_flags,context_flags,num_matches,max_matches,
                                    exact_match,case_sensitive);
               if (_chdebug) {
                  isay(depth, "_java_find_context_tags H"__LINE__": after tag_list_any_symbols, ALL num_matches="num_matches);
               }
            }
         } else {
            tag_list_in_class(lastid, constructor_class,
                              0, 0, tag_files,
                              num_matches, max_matches,
                              filter_flags, context_flags,
                              exact_match, case_sensitive,
                              null, null, visited, depth+1);
            if (is_new_expr && num_matches == 0 && length(constructor_class) > length(rt.return_type)) {
               tag_list_in_class(lastid, rt.return_type,
                                 0, 0, tag_files,
                                 num_matches, max_matches,
                                 filter_flags, context_flags,
                                 exact_match, case_sensitive,
                                 null, null, visited, depth+1);
            }
            if (_chdebug) {
               isay(depth, "_java_find_context_tags: LIST IN CLASS lastid="lastid" constructor_class="constructor_class" num_matches="num_matches);
            }
            // remove ONLY static flag if search yielded no results
            if (exact_match && num_matches == 0 && 
                (context_flags & (SE_TAG_CONTEXT_ONLY_STATIC|SE_TAG_CONTEXT_ONLY_NON_STATIC))) {
               if (_chdebug) {
                  isay(depth, "_java_find_context_tags: RETRY IGNORING STATIC");
               }
               context_flags_no_static := context_flags & ~(SE_TAG_CONTEXT_ONLY_STATIC|SE_TAG_CONTEXT_ONLY_NON_STATIC);
               tag_list_in_class(lastid, rt.return_type,
                                 0, 0, tag_files,
                                 num_matches, max_matches,
                                 filter_flags, context_flags_no_static,
                                 exact_match, case_sensitive,
                                 null, null, visited, depth+1);
               if (_chdebug) {
                  isay(depth,"_c_find_context_tags: IN CONTEXT FIND IGNORE STATIC lastid="lastid" num_matches="num_matches);
               }
            }
         }
      }
   }

   if (_chdebug) {
      tag_dump_matches("_java_find_context_tags: MATCHES", depth);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=="")? rt.return_type:lastid;
   //say("_java_find_context_tags: num_matches="num_matches);
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

/**
 * Evaluate the type of a Java prefix expression.
 * <P>
 * This function is technically private, use the public
 * function {@link _c_analyze_return_type()} instead.
 *
 * @param errorArgs      List of argument for codehelp error messages
 * @param prefixexp      Prefix expression
 * @param rt             (reference) return type structure
 * @param depth          (optional) depth of recursion
 *
 * @return 0 on success, non-zero on error
 */
int _java_get_type_of_prefix(_str (&errorArgs)[], _str prefixexp,
                             struct VS_TAG_RETURN_TYPE &rt, 
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                             CodeHelpExpressionPrefixFlags prefix_flags=VSCODEHELP_PREFIX_NULL)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   typeless tag_files = tags_filenamea(p_LangId);
   if (p_LangId == "js") tag_files = tags_filenamea("java");
   tag_push_matches();
   status := _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited, depth, prefix_flags);
   tag_pop_matches();
   return status;
}


/**
 * @see _java_find_context_tags
 */
int _cfscript_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                                _str lastid,int lastidstart_offset,
                                int info_flags,typeless otherinfo,
                                bool find_parents,int max_matches,
                                bool exact_match,bool case_sensitive,
                                SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                                SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                                VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                                VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return(_java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,false,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth,prefix_rt));
}

/**
 * @see _c_parse_return_type
 */
int _java_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                            _str symbol, _str search_class_name,
                            _str file_name, _str return_type, bool isjava,
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
                          _str file_name, _str return_type, bool isjava,
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
                           _str type_name, SETagFlags tag_flags,
                           _str file_name, _str return_type,
                           struct VS_TAG_RETURN_TYPE &rt,
                           struct VS_TAG_RETURN_TYPE (&visited):[],
                           int depth=0)
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,
                                 rt,visited,depth);
}
/**
 * @see _c_analyze_return_type
 */
int _cs_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                            _str tag_name, _str class_name,
                            _str type_name, SETagFlags tag_flags,
                            _str file_name, _str return_type,
                            struct VS_TAG_RETURN_TYPE &rt,
                            struct VS_TAG_RETURN_TYPE (&visited):[],
                            int depth=0)
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,
                                 rt,visited,depth);
}

/**
 * @see _c_analyze_return_type
 */
int _java_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                              _str tag_name, _str class_name,
                              _str type_name, SETagFlags tag_flags,
                              _str file_name, _str return_type,
                              struct VS_TAG_RETURN_TYPE &rt,
                              struct VS_TAG_RETURN_TYPE (&visited):[],
                              int depth=0)
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,
                                 rt,visited,depth);
}
/**
 * @see _c_analyze_return_type
 */
int _phpscript_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                                   _str tag_name, _str class_name,
                                   _str type_name, SETagFlags tag_flags,
                                   _str file_name, _str return_type,
                                   struct VS_TAG_RETURN_TYPE &rt,
                                   struct VS_TAG_RETURN_TYPE (&visited):[],
                                   int depth=0)
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,
                                 rt,visited,depth);
}
/**
 * @see _c_analyze_return_type
 */
int _rul_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                             _str tag_name, _str class_name,
                             _str type_name, SETagFlags tag_flags,
                             _str file_name, _str return_type,
                             struct VS_TAG_RETURN_TYPE &rt,
                             struct VS_TAG_RETURN_TYPE (&visited):[],
                             int depth=0)
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,
                                 rt,visited,depth+1);
}


/**
 * @see _c_get_type_of_expression
 */
int _cs_get_type_of_expression(_str (&errorArgs)[], 
                               typeless tag_files,
                               _str symbol, 
                               _str search_class_name,
                               _str file_name,
                               CodeHelpExpressionPrefixFlags prefix_flags,
                               _str expr, 
                               struct VS_TAG_RETURN_TYPE &rt,
                               struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_get_type_of_expression(errorArgs, tag_files, 
                                    symbol, search_class_name, file_name, 
                                    prefix_flags, expr, 
                                    rt, visited, depth);
}
/**
 * @see _c_get_type_of_expression
 */
int _java_get_type_of_expression(_str (&errorArgs)[], 
                                 typeless tag_files,
                                 _str symbol, 
                                 _str search_class_name,
                                 _str file_name,
                                 CodeHelpExpressionPrefixFlags prefix_flags,
                                 _str expr, 
                                 struct VS_TAG_RETURN_TYPE &rt,
                                 struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_get_type_of_expression(errorArgs, tag_files, 
                                    symbol, search_class_name, file_name, 
                                    prefix_flags, expr, 
                                    rt, visited, depth);
}
/**
 * @see _c_get_type_of_expression
 */
int _js_get_type_of_expression(_str (&errorArgs)[], 
                               typeless tag_files,
                               _str symbol, 
                               _str search_class_name,
                               _str file_name,
                               CodeHelpExpressionPrefixFlags prefix_flags,
                               _str expr, 
                               struct VS_TAG_RETURN_TYPE &rt,
                               struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_get_type_of_expression(errorArgs, tag_files, 
                                    symbol, search_class_name, file_name, 
                                    prefix_flags, expr, 
                                    rt, visited, depth);
}
/**
 * @see _c_get_type_of_expression
 */
int _groovy_get_type_of_expression(_str (&errorArgs)[], 
                                   typeless tag_files,
                                   _str symbol, 
                                   _str search_class_name,
                                   _str file_name,
                                   CodeHelpExpressionPrefixFlags prefix_flags,
                                   _str expr, 
                                   struct VS_TAG_RETURN_TYPE &rt,
                                   struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_get_type_of_expression(errorArgs, tag_files, 
                                    symbol, search_class_name, file_name, 
                                    prefix_flags, expr, 
                                    rt, visited, depth);
}
/**
 * @see _c_get_type_of_expression
 */
int _e_get_type_of_expression(_str (&errorArgs)[], 
                              typeless tag_files,
                              _str symbol, 
                              _str search_class_name,
                              _str file_name,
                              CodeHelpExpressionPrefixFlags prefix_flags,
                              _str expr, 
                              struct VS_TAG_RETURN_TYPE &rt,
                              struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_get_type_of_expression(errorArgs, tag_files, 
                                    symbol, search_class_name, file_name, 
                                    prefix_flags, expr, 
                                    rt, visited, depth);
}

/**
 * @see _c_parse_return_type
 */
int _e_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                            _str symbol, _str search_class_name,
                            _str file_name, _str return_type, bool isjava,
                            struct VS_TAG_RETURN_TYPE &rt,
                            VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_parse_return_type(errorArgs,tag_files,
                               symbol,search_class_name,
                               file_name,return_type,
                               true,rt,visited,depth);
}


static _str _make_import_wildcard_pattern(_str (&existing_imports)[])
{
   _str choices[];
   int  i;

   // Implicit wildcard in all compilation units.
   choices[0] = "java.lang";

   for (i = 0; i < existing_imports._length(); i++) {
      spos := pos(".*", existing_imports[i]);
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
 * @param param_name     (unused)named argument expected for this position 
 * @param visited        hash table of context tagging results 
 * @param depth          recursive search depth
 *
 * @return number of items inserted
 */
int _java_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                   int tree_wid, int tree_index,
                                   _str lastid_prefix="", 
                                   bool exact_match=false, bool case_sensitive=true,
                                   _str param_name="", _str param_default="",
                                   struct VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // number of matches inserted
   k := match_count := 0;

   // could insert NULL, but screw them...
   if (rt_expected.pointer_count>0) {
      return (match_count);
   }

   // Insert boolean
   if (rt_expected.return_type=="boolean") {
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
   if (rt_expected.return_type=="java.lang/String" || rt_expected.return_type=="java/lang/String") {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "\"", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,'""',"const","",0,"",0,"");
         match_count++;
      }
   }

   // Insert null for non-builtin types (these must be classes)
   if (!_c_is_builtin_type(rt_expected.return_type)) {
      // insert null reference
      if (_CodeHelpDoesIdMatch(lastid_prefix, "null", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"null","const","",0,"",0,"");
         match_count++;
      }
      // maybe insert 'this'
      if (rt_expected.pointer_count==0) {
         this_class_name := _MatchThisOrSelf(visited, depth+1);
         if (this_class_name!="") {
            tag_files := tags_filenamea(p_LangId);
            if (this_class_name == rt_expected.return_type ||
                tag_is_parent_class(rt_expected.return_type,this_class_name,tag_files,true,true,null,visited,depth+1)) {
               if (_CodeHelpDoesIdMatch(lastid_prefix, "this", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"this","const","",0,"",0,"");
                  match_count++;
               }
            }
         }

         // Try inserting new 'class' (Java specific)
         if (_LanguageInheritsFrom("java")) {
            // If it was specified as a generic, include the set parameters in the suggestion
            generic_args := "";
            blank_args := "";
            if (rt_expected.istemplate && rt_expected.template_names._length() > 0) {
               _str existing_imports[];
               VS_JAVA_IMPORT_INFO imports:[];

               // Take a look at the existing imports so we can un-qualify
               // generic argument types as needed.
               tag_files := tags_filenamea(_isEditorCtl()? p_LangId:"");
               java_get_existing_imports(existing_imports, imports, auto min_seek, auto max_seek, tag_files, visited, depth+1);

               _str names[];
               wildcards := _make_import_wildcard_pattern(existing_imports);
               for (ai := 0; ai < rt_expected.template_names._length(); ai++) {
                  ty := "";
                  if (rt_expected.template_args._indexin(rt_expected.template_names[ai])) {
                     ty = rt_expected.template_args:[rt_expected.template_names[ai]];
                  }
                  if (imports._indexin(ty) && imports:[ty] != null || (wildcards && pos(wildcards, ty, 1, 'U'))) {
                     dotp := lastpos(".", ty);
                     ty = substr(ty, dotp+1);
                  }
                  names[ai] = ty;
               }
               generic_args="<"(join(names, ","))">";
               blank_args="<>";
            }

            // check the current package name
            cur_tag_name := cur_type_name := cur_context := cur_class := cur_package := "";
            typeless cur_flags=0, cur_type_id=0;
            tag_get_current_context(cur_tag_name, cur_flags, 
                                    cur_type_name, cur_type_id, 
                                    cur_context, cur_class, cur_package,
                                    visited, depth+1);

            // insert qualified class name (except for java.lang and current package)
            class_name := stranslate(rt_expected.return_type,".",VS_TAGSEPARATOR_class);
            class_name=stranslate(class_name,".",VS_TAGSEPARATOR_package);
            if (pos("java.lang.", class_name) != 1 && 
                pos("java/lang/", class_name) != 1 && 
                pos(cur_package, class_name) != 1) {
               if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
               }
            }

            // insert unqualified class name
            p := lastpos(".", class_name);
            if (p > 0) {
               class_name = substr(class_name, p+1);
               if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
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
 * @param param_name     (unused)named argument expected for this position 
 * @param visited        hash table of context tagging results 
 * @param depth          recursive search depth
 *
 * @return number of items inserted
 */
int _cs_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                 int tree_wid, int tree_index,
                                 _str lastid_prefix="", 
                                 bool exact_match=false, bool case_sensitive=true,
                                 _str param_name="", _str param_default="",
                                 struct VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // number of matches inserted
   k := match_count := 0;

   // could insert NULL, but screw them...
   if (rt_expected.pointer_count>0) {
      return (match_count);
   }

   // special case for C# named parameters
   include_named_param := false;
   if (param_name != null && param_name != "" && rt_expected.return_type != "") {
      // check if we should offer to insert named function argument
      if (codehelp_at_start_of_parameter() || _CodeHelpDoesIdMatch(lastid_prefix, param_name, exact_match, case_sensitive)) {
         if (_e_parse_for_slickc_named_argument(true,depth+1) == "") {
            tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name":","param","",0,"",0,rt_expected.return_type);
            match_count++;
            include_named_param = true;
         }
      }
   }

   // special case for C# out parameters with declarations
   if (param_name != null && param_name != "" && rt_expected.return_type != "") {
      if (lastid_prefix == "" && (rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_OUT)) {
         if (tag_find_local_iterator(param_name, true, true) <= 0) {
            include_auto_param := false;
            opt_out_keyword := "out ";
            save_pos(auto before_ref_keyword_check);
            left();
            start_col := p_col;
            prev_id := cur_identifier(start_col);
            restore_pos(before_ref_keyword_check);
            if (prev_id == "ref" || prev_id == "out" || prev_id == "in") {
               if (p_col > start_col+length(prev_id)) {
                  p_col = start_col;
                  include_auto_param = codehelp_at_start_of_parameter();
                  if (prev_id == "out") {
                     opt_out_keyword = "";
                  }
               }
            }
            restore_pos(before_ref_keyword_check);

            // double check that we do not already have "ref", "out" or "in"
            if (include_auto_param || codehelp_at_start_of_parameter()) {
               tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,opt_out_keyword:+rt_expected.return_type:+" ":+param_name,"param","",0,"",0,rt_expected.return_type);
               match_count++;
               tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,opt_out_keyword:+"var ":+param_name,"param","",0,"",0,rt_expected.return_type);
               match_count++;
            }
         }
      }
   }

   // Insert boolean
   if (rt_expected.return_type=="bool") {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "true", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"true","const","",0,"",0,"");
         match_count++;
      }
      if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":true", exact_match, case_sensitive)) {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":true","const","",0,"",0,"");
         match_count++;
      }
      if (_CodeHelpDoesIdMatch(lastid_prefix, "false", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"false","const","",0,"",0,"");
         match_count++;
      }
      if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":false", exact_match, case_sensitive)) {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":false","const","",0,"",0,"");
         match_count++;
      }
   }

   // Insert empty string
   if (rt_expected.return_type=="java.lang/String" || rt_expected.return_type=="java/lang/String") {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "\"", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,'""',"const","",0,"",0,"");
         match_count++;
      }
      if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":\"", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+':""',"const","",0,"",0,"");
         match_count++;
      }
   }

   // Insert null for non-builtin types (these must be classes)
   if (!_c_is_builtin_type(rt_expected.return_type)) {
      // insert null reference
      if (_CodeHelpDoesIdMatch(lastid_prefix, "null", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"null","const","",0,"",0,"");
         match_count++;
      }
      if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":null", exact_match, case_sensitive)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":null","const","",0,"",0,"");
         match_count++;
      }
      // maybe insert 'this'
      if (rt_expected.pointer_count==0) {
         this_class_name := _MatchThisOrSelf(visited, depth+1);
         if (this_class_name!="") {
            tag_files := tags_filenamea(p_LangId);
            if (this_class_name == rt_expected.return_type ||
                tag_is_parent_class(rt_expected.return_type,this_class_name,tag_files,true,true,null,visited,depth+1)) {
               if (_CodeHelpDoesIdMatch(lastid_prefix, "this", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"this","const","",0,"",0,"");
                  match_count++;
               }
               if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":this", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":this","const","",0,"",0,"");
                  match_count++;
               }
            }
         }

         // Try inserting new 'class' (C# specific)
         if (_LanguageInheritsFrom("cs")) {
            // If it was specified as a generic, include the set parameters in the suggestion
            generic_args := "";
            blank_args := "";
            if (rt_expected.istemplate && rt_expected.template_names._length() > 0) {
               _str names[];
               for (ai := 0; ai < rt_expected.template_names._length(); ai++) {
                  ty := "";
                  if (rt_expected.template_args._indexin(rt_expected.template_names[ai])) {
                     ty = rt_expected.template_args:[rt_expected.template_names[ai]];
                  }
                  names[ai] = ty;
               }
               generic_args="<"(join(names, ","))">";
               blank_args="<>";
            }

            // check the current package name
            cur_tag_name := cur_type_name := cur_context := cur_class := cur_package := "";
            typeless cur_flags=0, cur_type_id=0;
            tag_get_current_context(cur_tag_name, cur_flags, 
                                    cur_type_name, cur_type_id, 
                                    cur_context, cur_class, cur_package,
                                    visited, depth+1);

            // insert qualified class name (except for java.lang and current package)
            class_name := stranslate(rt_expected.return_type,".",VS_TAGSEPARATOR_class);
            class_name=stranslate(class_name,".",VS_TAGSEPARATOR_package);
            if (pos("System.", class_name) != 1 && 
                pos("System/", class_name) != 1 && 
                pos(cur_package, class_name) != 1) {
               if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
               }
               if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":new", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":new "(class_name :+ blank_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":new "(class_name :+ generic_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
               }
            }

            // insert unqualified class name
            p := lastpos(".", class_name);
            if (p > 0) {
               class_name = substr(class_name, p+1);
               if (_CodeHelpDoesIdMatch(lastid_prefix, "new", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ blank_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"new "(class_name :+ generic_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
               }
               if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":new", exact_match, case_sensitive)) {
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":new "(class_name :+ blank_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
                  match_count++;
                  k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":new "(class_name :+ generic_args),"func","",0,"",(int)SE_TAG_FLAG_CONSTRUCTOR,"");
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
 * @param param_name     (unused)named argument expected for this position 
 * @param visited        hash table of context tagging results 
 * @param depth          recursive search depth
 *
 * @return number of items inserted
 */
int _rul_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                  int tree_wid, int tree_index,
                                  _str lastid_prefix="", 
                                  bool exact_match=false, bool case_sensitive=true,
                                  _str param_name="", _str param_default="",
                                  struct VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // number of matches inserted
   k := match_count := 0;

   // could insert NULL, but screw them...
   if (rt_expected.pointer_count>0) {
      return (match_count);
   }

   // Insert boolean
   if (rt_expected.return_type=="BOOL") {
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
 * @param param_name     named argument expected for this position 
 * @param visited        hash table of context tagging results 
 * @param depth          recursive search depth
 *
 * @return number of items inserted
 */
int _e_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                int tree_wid, int tree_index,
                                _str lastid_prefix="",
                                bool exact_match=false, bool case_sensitive=true,
                                _str param_name="", _str param_default="",
                                struct VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // make sure we have a vald return type
   if (rt_expected == null) {
      return INVALID_ARGUMENT_RC;
   }

   // number of matches inserted
   match_count := 0;
   include_named_param := false;

   // special case for Slick-C named parameters
   // this should have been a callback, but this was quicker & simpler
   if (param_name != null && param_name != "") {
      // check if we should offer to insert named function argument
      if (rt_expected.return_type != "") {
         if (codehelp_at_start_of_parameter() || _CodeHelpDoesIdMatch(lastid_prefix, param_name, exact_match, case_sensitive)) {
            if (_e_parse_for_slickc_named_argument(true,depth+1) == "") {
               tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name":","param","",0,"",0,rt_expected.return_type);
               match_count++;
               include_named_param = true;
            }
         }
      }

      // blow out of here if return flags indicate that this is a reference
      if (rt_expected != null && rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_REF) {
         // special case for Slick-C pass by reference paramters
         // this should have been a callback, but this was quicker & simpler
         if (param_name != null && param_name != "") {
            // this does not need a synchronization guard since the call to
            // tag_find_local_iterator() stands alone.
            _UpdateLocals(true);
            if (tag_find_local_iterator(param_name, true, true) <= 0) {
               tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"auto ":+param_name,"param","",0,"",0,rt_expected.return_type);
               match_count++;
               return match_count;
            }
         }
         return(0);
      }
   }

   // was there a default parameter value supplied?
   if (param_name != null && param_name != "" && param_default != null && param_default != "") {
      if (_CodeHelpDoesIdMatch(lastid_prefix, param_default, exact_match, case_sensitive)) {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_default,"const","",0,"",0,"");
         match_count++;
         if (include_named_param) {
            tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":":+param_default,"const","",0,"",0,"");
            match_count++;
         }
      }
   }

   // could insert NULL, but screw them...
   if (rt_expected.pointer_count>0) {
      if (!(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
         if (_CodeHelpDoesIdMatch(lastid_prefix, "null", exact_match, case_sensitive)) {
            tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"null","const","",0,"",0,"");
            match_count++;
         }
         if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":null", exact_match, case_sensitive)) {
            tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":null","const","",0,"",0,"");
            match_count++;
         }
      }
      return (match_count);
   }

   // Insert boolean
   if (rt_expected.return_type=="boolean" || rt_expected.return_type=="bool") {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "true", exact_match, case_sensitive)) {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"true","const","",0,"",0,"");
         match_count++;
         if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":true", exact_match, case_sensitive)) {
            tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":true","const","",0,"",0,"");
            match_count++;
         }
      }
      if (_CodeHelpDoesIdMatch(lastid_prefix, "false", exact_match, case_sensitive)) {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"false","const","",0,"",0,"");
         match_count++;
      }
      if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":false", exact_match, case_sensitive)) {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":false","const","",0,"",0,"");
         match_count++;
      }
   }

   // Insert empty string
   if (rt_expected.return_type=="_str") {
      if (_CodeHelpDoesIdMatch(lastid_prefix, "\"", exact_match, case_sensitive)) {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,'""',"const","",0,"",0,"");
         match_count++;
      }
      if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+':""', exact_match, case_sensitive)) {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+':""',"const","",0,"",0,"");
         match_count++;
      }
   }

   // Insert 0 constant for integer types
   if (rt_expected.return_type=="int") {
      if (lastid_prefix == "") {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"0","const","",0,"",0,"");
         match_count++;
      }
      if (include_named_param && _CodeHelpDoesIdMatch(lastid_prefix, param_name:+":0", exact_match, case_sensitive)) {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,param_name:+":0","const","",0,"",0,"");
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
                         _str tag_name,_str type_name,
                         SETagFlags tag_flags,
                         _str file_name, int line_no,
                         _str prefixexp,typeless tag_files,
                         int tree_wid, int tree_index,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,
                               tree_wid,tree_index,
                               visited,depth);
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
                            _str tag_name,_str type_name, 
                            SETagFlags tag_flags,
                            _str file_name, int line_no,
                            _str prefixexp,typeless tag_files,
                            int tree_wid, int tree_index,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,
                               tree_wid,tree_index,
                               visited,depth);
}
/**
 * @see _c_match_return_type
 */
int _cs_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                          struct VS_TAG_RETURN_TYPE &rt_candidate,
                          _str tag_name,_str type_name,
                          SETagFlags tag_flags,
                          _str file_name, int line_no,
                          _str prefixexp,typeless tag_files,
                          int tree_wid, int tree_index,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,
                               tree_wid,tree_index,
                               visited,depth);

}
/**
 * @see _c_match_return_type
 */
int _phpscript_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                 struct VS_TAG_RETURN_TYPE &rt_candidate,
                                 _str tag_name,_str type_name, 
                                 SETagFlags tag_flags,
                                 _str file_name, int line_no,
                                 _str prefixexp,typeless tag_files,
                                 int tree_wid, int tree_index,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,
                               tree_wid,tree_index,
                               visited,depth);
}
/**
 * @see _c_match_return_type
 */
int _rul_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                           struct VS_TAG_RETURN_TYPE &rt_candidate,
                           _str tag_name,_str type_name, 
                           SETagFlags tag_flags,
                           _str file_name, int line_no,
                           _str prefixexp,typeless tag_files,
                           int tree_wid, int tree_index,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,
                               tree_wid,tree_index,
                               visited,depth);
}
/**
 * @see _c_find_members_of
 * 
 * @deprecated  This feature is no longer used in 11.0
 */
int _e_find_members_of(struct VS_TAG_RETURN_TYPE &rt,
                       _str tag_name,_str type_name, 
                       SETagFlags tag_flags,
                       _str file_name, int line_no,
                       _str &prefixexp, typeless tag_files, SETagFilterFlags filter_flags,
                       VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_find_members_of(rt,tag_name,type_name,tag_flags,
                             file_name,line_no,prefixexp,
                             tag_files,filter_flags,visited,depth);
}
/**
 * @see _c_find_members_of
 * 
 * @deprecated  This feature is no longer used in 11.0
 */
int _java_find_members_of(struct VS_TAG_RETURN_TYPE &rt,
                          _str tag_name,_str type_name, 
                          SETagFlags tag_flags,
                          _str file_name, int line_no,
                          _str &prefixexp, typeless tag_files, SETagFilterFlags filter_flags,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_find_members_of(rt,tag_name,type_name,tag_flags,
                             file_name,line_no,prefixexp,
                             tag_files,filter_flags,visited,depth);
}
/**
 * @see _c_find_members_of
 * 
 * @deprecated  This feature is no longer used in 11.0
 */
int _rul_find_members_of(struct VS_TAG_RETURN_TYPE &rt,
                         _str tag_name,_str type_name,
                         SETagFlags tag_flags,
                         _str file_name, int line_no,
                         _str &prefixexp, typeless tag_files, SETagFilterFlags filter_flags,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_find_members_of(rt,tag_name,type_name,tag_flags,
                             file_name,line_no,prefixexp,
                             tag_files,filter_flags,visited,depth);
}

/**
 * @see _c_fcthelp_get_start
 */
int _e_fcthelp_get_start(_str (&errorArgs)[],
                         bool OperatorTyped,
                         bool cursorInsideArgumentList,
                         int &FunctionNameOffset,
                         int &ArgumentStartOffset,
                         int &flags,
                         int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}
/**
 * @see _c_fcthelp_get_start
 */
int _java_fcthelp_get_start(_str (&errorArgs)[],
                            bool OperatorTyped,
                            bool cursorInsideArgumentList,
                            int &FunctionNameOffset,
                            int &ArgumentStartOffset,
                            int &flags,
                            int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}
/**
 * @see _c_fcthelp_get_start
 */
int _cs_fcthelp_get_start(_str (&errorArgs)[],
                          bool OperatorTyped,
                          bool cursorInsideArgumentList,
                          int &FunctionNameOffset,
                          int &ArgumentStartOffset,
                          int &flags,
                          int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}
/**
 * @see _c_fcthelp_get_start
 */
int _cfscript_fcthelp_get_start(_str (&errorArgs)[],
                                bool OperatorTyped,
                                bool cursorInsideArgumentList,
                                int &FunctionNameOffset,
                                int &ArgumentStartOffset,
                                int &flags,
                                int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}
/**
 * @see _c_fcthelp_get_start
 */
int _phpscript_fcthelp_get_start(_str (&errorArgs)[],
                                 bool OperatorTyped,
                                 bool cursorInsideArgumentList,
                                 int &FunctionNameOffset,
                                 int &ArgumentStartOffset,
                                 int &flags,
                                 int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}

/**
 * @see _c_fcthelp_get
 */
int _e_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      bool &FunctionHelp_list_changed,
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
                      bool &FunctionHelp_list_changed,
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
                      bool &FunctionHelp_list_changed,
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
                          bool &FunctionHelp_list_changed,
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
                      bool &FunctionHelp_list_changed,
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
bool _cs_is_continued_statement()
{
   return _c_is_continued_statement();
}
bool _js_is_continued_statement()
{
   return _c_is_continued_statement();
}
bool _cfscript_is_continued_statement()
{
   return _c_is_continued_statement();
}
bool _phpscript_is_continued_statement()
{
   return _c_is_continued_statement();
}
bool _java_is_continued_statement()
{
   return _c_is_continued_statement();
}


_str java_get_jdk_jars(_str root = "") {

   if (root :== "") return root;
   jdk_jar_list := "";

   _maybe_append_filesep(root);
   jre_lib_jars := _maybe_quote_filename(root:+"jre":+FILESEP:+"lib":+FILESEP:+"*.jar"); 
   cur_jar := file_match(jre_lib_jars"  -p +t", 1);
   if (cur_jar == "") {
      jre_lib_jars = _maybe_quote_filename(root:+"lib":+FILESEP:+"*.jar"); 
      cur_jar = file_match(jre_lib_jars"  -p +t", 1);
   }
   for (;;) {
      if(cur_jar :== "") break;
      jdk_jar_list :+= cur_jar :+ PATHSEP;
      cur_jar = file_match(cur_jar, 0);
   }
   return(jdk_jar_list);
}


// Automatically activate live errors if we can detect a valid JDK 6 (or later)
void java_maybe_activate_live_errors(){
   if (!_haveBuild()) {
      return;
   }
   javahome := "";
   if (_isUnix()) {
      _str javaList[];
      _str javaNamesList[];
      if (_isMac()) {
         javahome=get_all_specific_JDK_paths_mac(javaList,javaNamesList);
      } else {
         javahome=get_all_specific_JDK_paths("/usr:/opt:/app:/usr/lib/jvm","1.6:1.7:1.8:9.0.0:9.0.1:9.0.2:9.1.0:9:10",javaList,javaNamesList);
      }
      if (javahome != "") {
         int jdk_check = _check_java_installdir(javahome, true);
         if (jdk_check != 0) {
            return;
         }
      }
   } else {
      _str latest_subkey, major, minor, rest;
      regkeypath := 'SOFTWARE\JavaSoft\JDK';
      result := _ntRegFindLatestVersion(HKEY_LOCAL_MACHINE,regkeypath,latest_subkey,0);
      if ( result < 0 ) {
         regkeypath = 'SOFTWARE\JavaSoft\Java Development Kit';
         result = _ntRegFindLatestVersion(HKEY_LOCAL_MACHINE,regkeypath,latest_subkey,0);
      }
      if (result == 0) {
         parse latest_subkey with major "." minor "." rest;
         if (major>=9) {
            minor=major;
         }
         if (isinteger(minor)) {
            int min = (int)minor;
            if (min >= 6) {
              javahome=_ntRegQueryValue(HKEY_LOCAL_MACHINE,regkeypath'\'latest_subkey,"","JavaHome");
              if (javahome != "") {
                 int jdk_check = _check_java_installdir(javahome, true);
                 if (jdk_check != 0) {
                    return;
                 }
              }
            }
         }
      }
   }
   _maybe_append_filesep(javahome);
   _str java_name;
#if 0
   if (_isMac()) {
      java_name = javahome :+ "/Home/bin" :+ FILESEP :+ "java";
   } else {
      java_name = javahome :+ "bin" :+ FILESEP :+ "java";
   }
#endif
   java_name = javahome :+ "bin" :+ FILESEP :+ "java";
   if (_isWindows()) {
      java_name :+= ".exe";
   }
   _str version = get_jdk_version_from_exe(_maybe_quote_filename(java_name));
   if (version == "") {
      return;
   }
   res := check_for_jdk_6(version);
   if (!res) {
      return;
   }
   def_java_live_errors_jdk_6_dir = javahome; 
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

_str java_get_jdk_classpath()
{
   if(def_java_live_errors_jdk_6_dir != "") {
      return(def_java_live_errors_jdk_6_dir);
   }
   jdk_jar_class_path := "";
   _str jdk_path;
   _str java_list[];

   getJavaIncludePath(java_list, jdk_path);
   if (jdk_path=="") {
      return(def_java_live_errors_jdk_6_dir);
   }

//   say("jdk_path="jdk_path);

   jdk_jar_class_path="";

   // look for the standard rt.jar

   // Avoid doing a tree list if possible.
   match := file_match("-p "_maybe_quote_filename(jdk_path:+"jre":+FILESEP:+"lib":+FILESEP:+"rt.jar"),1);
   if (match=="") {
      match=file_match("-p +t "_maybe_quote_filename(jdk_path:+"rt.jar"),1);
      if (match!="") {
         jdk_jar_class_path = match;
      } else {
         // Look for the MAC version of rt.jar
         match=file_match("-p +t "_maybe_quote_filename(jdk_path:+"classes.jar"),1);
         if (match!="") {
           dir := _strip_filename(match,'N');
   
            jdk_jar_class_path :+= dir :+ "charsets.jar" :+ PATHSEP;
            jdk_jar_class_path :+= dir :+ "classes.jar" :+ PATHSEP;
            jdk_jar_class_path :+= dir :+ "dt.jar" :+ PATHSEP;
            jdk_jar_class_path :+= dir :+ "jce.jar" :+ PATHSEP;
            jdk_jar_class_path :+= dir :+ "jsse.jar" :+ PATHSEP;
            jdk_jar_class_path :+= dir :+ "laf.jar" :+ PATHSEP;
            jdk_jar_class_path :+= dir :+ "sunrasign.jar" :+ PATHSEP;
            jdk_jar_class_path :+= dir :+ "ui.jar";
         } else {
            // Look for the IBM core.jar and add all of the separate jar files
            // that make up what should have been rt.jar and put them in the class path.
            match=file_match("-p +t "_maybe_quote_filename(jdk_path:+"core.jar"),1);
            if (match!="") {
               dir := _strip_filename(match,'N');
   
               jdk_jar_class_path :+= dir :+ "charsets.jar" :+ PATHSEP;
               jdk_jar_class_path :+= dir :+ "core.jar" :+ PATHSEP;
               jdk_jar_class_path :+= dir :+ "graphics.jar" :+ PATHSEP;
               jdk_jar_class_path :+= dir :+ "ibmjssefips.jar" :+ PATHSEP;
               jdk_jar_class_path :+= dir :+ "javaplugin.jar" :+ PATHSEP;
               jdk_jar_class_path :+= dir :+ "security.jar" :+ PATHSEP;
               jdk_jar_class_path :+= dir :+ "server.jar" :+ PATHSEP;
               jdk_jar_class_path :+= dir :+ "xml.jar";
            } else {
               // Try the jre installed with slickedit.
            }
         }
      }
   }

   // DJB 03/08/2006 -- only set config_modify if absolutely necessary
   if (def_java_live_errors_enabled && _java_live_errors_supported() &&
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
   JDKPath = "";
   javaPath := "";
   javaPath=get_Navigator_path();
   if (javaPath !="") {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_NETSCAPE;
      JDKPath=javaPath;
   }
   javaPath=get_jbuilder_path();
   if (javaPath !="") {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_JBUILDER;
      JDKPath=javaPath;
   }
   javaPath=get_vcafe_path();
   if (javaPath !="") {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_VISUALCAFE;
      JDKPath=javaPath;
   }
   javaPath=get_jpp_path();
   if (javaPath !="") {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_JPP;
      JDKPath=javaPath;
   }
   javaPath=get_Supercede_path();
   if (javaPath !="") {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_SUPERCEDE;
      JDKPath=javaPath;
   }
   javaPath=get_IBM_JDK_path();
   if (javaPath !="") {
      javaList[javaList._length()]=javaPath;
      javaNamesList[javaNamesList._length()]=COMPILER_NAME_IBM;
      JDKPath=javaPath;
   }
   found_a_jdk := false;
   if (isEclipsePlugin()) {
      javaPath = get_all_eclipse_jdk_paths(javaList, javaNamesList);
   }

   if (_isMac()) {
      javaPath=get_all_specific_JDK_paths("/System/Library/Frameworks/JavaVM.framework/Versions:/Library/Java/JavaVirtualMachines/","1.0:1.1:1.2:1.3:1.4:1.5:1.6:1.7:1.8:9.0.0:9.0.1:9.0.2:9.1.0:2.0:2.1",javaList,javaNamesList);
      javaPath2:=get_all_specific_JDK_paths_mac(javaList,javaNamesList);
      if (javaPath2!='') {
         javaPath=javaPath2;
      }
   } else if(_isUnix()) {
      javaPath=get_all_specific_JDK_paths("/usr:/opt:/app:/usr/lib/jvm","1.0:1.1:1.2:1.3:1.4:1.5:1.6:1.7:1.8:9.0.0:9.0.1:9.0.2:9.1.0:9:10:2.0:2.1",javaList,
                                          javaNamesList);
   } else {
      _str jdk_keys[];
      _ntRegListKeys(HKEY_LOCAL_MACHINE,'SOFTWARE\JavaSoft\JDK',jdk_keys);
      _str version_str_list="1.0:1.1:1.2:1.3:1.4:1.5:1.6:1.7:1.8:2.0:2.1";
      for (i:=0;i<jdk_keys._length();++i) {
         strappend(version_str_list,':':+jdk_keys[i]);
      }
      javaPath=get_all_specific_JDK_paths("unused",version_str_list,javaList,javaNamesList);
   }
   //   say("javaPath1="javaPath);
   if (javaPath !="") {
      JDKPath=javaPath;
      found_a_jdk=true;
   }
   if (!found_a_jdk) {
      javaPath=get_JDK_path();
//      say("javaPath2="javaPath);
      if (javaPath !="") {
         java_exe :=  javaPath :+ "bin" :+ FILESEP "java";
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
   //say("JDKPath3="JDKPath);

   // try using their configured JDK directory
   get_javac_from_defvar(javaList,JDKPath,javaNamesList);
   //say("JDKPath4="JDKPath);
}

static _str get_Navigator_path()
{
   if (_isUnix()) {
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
   }

   _str javaPath=_ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Netscape\Netscape Navigator',"Main","Java Directory");
   //HKEY_LOCAL_MACHINE\SOFTWARE\Netscape\Netscape Navigator\4.04 (en)\Main

   _maybe_append_filesep(javaPath);
   if (javaPath !="" && create_java_autotag_args(javaPath) == "") {
      javaPath = "";
   }
   return(javaPath);
}

static _str get_IBM_JDK_path()
{
   if (_isUnix()) {
      return("");
   }

   _str javaPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\IBM\IBM Developer Kit, Java(TM) Tech. Edition\1.1.7',"","JavaHome");

   _maybe_append_filesep(javaPath);
   if (javaPath !="" && create_java_autotag_args(javaPath) == "") {
      javaPath = "";
   }
   return(javaPath);

}

static _str get_Supercede_path()
{
   if (_isUnix()) {
      return("");
   }

   _str javaPath=_ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\SuperCede\SuperCede',"","Install Path");

   _maybe_append_filesep(javaPath);
   if (javaPath !="" && create_java_autotag_args(javaPath) == "") {
      javaPath = "";
   }
   return(javaPath);

}
static _str get_JDK_path(){
   if (_isUnix()) {
      javaPath := "/usr/java/";
      if (isdirectory(javaPath"/bin/")) {
         return(javaPath);
      }
      javaPath="/usr/local/java/";
      if (isdirectory(javaPath"/bin/")) {
         return(javaPath);
      }
      javaPath="/usr/jdk_base/";  // IBM 4.3.x
      if (isdirectory(javaPath"/bin/")) {
         return(javaPath);
      }
      javaPath="/opt/java/";
      if (isdirectory(javaPath"/bin/")) {
         return(javaPath);
      }
      javaPath="/app/java/";
      if (isdirectory(javaPath"/bin/")) {
         return(javaPath);
      }
      return("");
   }
   javaPath := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\JavaSoft\JDK',"","JavaHome");
   if ( javaPath == "" ) {
      javaPath = _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\JavaSoft\Java Development Kit',"","JavaHome");
   }

   _maybe_append_filesep(javaPath);
   if (javaPath !="" && create_java_autotag_args(javaPath) == "") {
      javaPath = "";
   }
   return(javaPath);
}

static _str get_all_eclipse_jdk_paths(_str (&javaList)[], _str (&javaNamesList)[]){
   eclipse_jdks := "";
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
   found_path := "";
   _str orig_base_dirs=base_dirs;

   // loop through the JDK versions
   while (jdk_versions != "") {
      jdk_version := "";
      parse jdk_versions with jdk_version ":" jdk_versions;
      // try each base directory scheme
      while (base_dirs != "") {
         base_dir := "";
         parse base_dirs with base_dir (PARSE_PATHSEP_RE),"r" base_dirs;
         // try the version-specific lookup
         //say("get_all_specific_JDK_paths: jdk_version="jdk_version);
         _str javaPath=get_specific_JDK_path(base_dir,jdk_version);
         while (javaPath != "") {
            path := "";
            //say("get_specific_JDK_path: javaPath="javaPath);
            parse javaPath with path (PARSE_PATHSEP_RE),'r' javaPath;
            if( path != "" ) {
               //say("get_specific_JDK_path: path="path);
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
   if (_isMac() && (found_path == "")) {
      found_path = get_all_specific_JDK_paths_mac(javaList, javaNamesList);
   }

   return(found_path);
}

// http://developer.apple.com/library/mac/#releasenotes/Java/JavaSnowLeopardUpdate3LeopardUpdate8RN/NewandNoteworthy/NewandNoteworthy.html
static _str get_all_specific_JDK_paths_mac(_str (&javaList)[], _str (&javaNamesList)[])
{
   // we have to run "/usr/libexec/java_home --xml" to get the list of available JVMs
   pid := 0;
   status := 0;

   // create a temp file to capture the output
   _str outputFilename = mktemp();
   // set up the command to output the result
   //_str commandWithOutput = "/usr/libexec/java_home --xml > "_maybe_quote_filename(outputFilename)" 2>&1"; 
   commandWithOutput :=  "/usr/libexec/java_home --xml > "_maybe_quote_filename(outputFilename); 
   // shell the command
   shellProc := "/bin/sh";
   if (file_match("-p "shellProc, 1) == "") {
      shellProc = path_search("sh");
      if (shellProc=="") {
         return "";
      }
   }
   status = shell(commandWithOutput, "QP", shellProc, pid);
   // now load that XML output
   int xmlHandle = _xmlcfg_open(outputFilename, status, VSXMLCFG_OPEN_ADD_PCDATA);
   if (xmlHandle<0) {
      delete_file(outputFilename);
      return "";
   }
   _str jvmNodes[];
   // use a hashtable to store these so we don't store duplicate paths to the same JVM
   _str jvmCollection:[];
   jvm_version := "";
   jvm_home := "";
   // find all of the nodes that define a JVM
   _xmlcfg_find_simple_array(xmlHandle, "/plist/array/dict", jvmNodes);
   i := 0;
   for (i = 0; i < jvmNodes._length(); i++) {
      j := 0;
      _str keyNodes[];
      int jvmNode = (int)jvmNodes[i];
      jvm_version = "";
      jvm_home = "";
      // get all of the key nodes under the current JVM node
      _xmlcfg_find_simple_array(xmlHandle, "key", keyNodes, jvmNode);
      for (j = 0; j < keyNodes._length(); j++) {
         int keyNode = (int)keyNodes[j];
         valueNode := -1;
         keyName := "";
         int tempPCDataNode = _xmlcfg_get_first_child(xmlHandle, keyNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
         if (tempPCDataNode >= 0) {
            keyName = _xmlcfg_get_value(xmlHandle, tempPCDataNode);
         }
         if (strieq(keyName, "JVMVersion") == true) {
            // get the version of the JVM
            valueNode = _xmlcfg_get_next_sibling(xmlHandle, keyNode);
            tempPCDataNode = _xmlcfg_get_first_child(xmlHandle, valueNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
            if (tempPCDataNode >= 0) {
               jvm_version = _xmlcfg_get_value(xmlHandle, tempPCDataNode);
            }
         } else if (strieq(keyName, "JVMHomePath") == true) {
            // get the name of the JVM
            valueNode = _xmlcfg_get_next_sibling(xmlHandle, keyNode);
            tempPCDataNode = _xmlcfg_get_first_child(xmlHandle, valueNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
            if (tempPCDataNode >= 0) {
               _str tempPath = _xmlcfg_get_value(xmlHandle, tempPCDataNode);
               // strip the /home from the end of the path (we assume the parent directory)
                  if (strieq(_strip_filename(tempPath, 'p'), "home") == true) {
                     tempPath = _strip_filename(tempPath, 'n');
               }
               _maybe_append_filesep(tempPath);
               // see if src.jar or classes.jar actually exists in this path
               _str tempSrcFilename = tempPath;
               tempSrcFilename :+= ("Home" :+ FILESEP :+ "src.jar");
               if (file_exists(tempSrcFilename) == true) {
                  jvm_home = tempPath;
               } else {
                  tempSrcFilename=tempPath:+("Home" :+ FILESEP :+ "src.zip");
                  tempSrcFilename2:=tempPath:+("Home/lib" :+ FILESEP :+ "src.zip");
                  if (file_exists(tempSrcFilename) == true || file_exists(tempSrcFilename2)) {
                     jvm_home = tempPath;
                  } else {
                      _str tempClassesFilename = tempPath;
                      tempClassesFilename :+= ("Classes" :+ FILESEP :+ "classes.jar");
                      if (file_exists(tempClassesFilename) == true) {
                          jvm_home = tempPath;
                      }
                  }
               }
            }
         } 
      }
      // see if we have a name and a value
      if ((jvm_version != "") && (jvm_home != "")) {
         if (isdigit(substr(jvm_version,1,1))) {
            jvm_version='JDK 'jvm_version;
         }
         jvmCollection:[jvm_version] = jvm_home;
      }
   }
   // clean up after ourselves
   _xmlcfg_close(xmlHandle);
   delete_file(outputFilename);

   // if we find anything, store it here
   foundPath := "";
   // now just store the names and homes of the JVMs to be returned
   foreach (jvm_version => jvm_home in jvmCollection) {
      javaNamesList[javaNamesList._length()] = jvm_version;
      javaList[javaList._length()] = jvm_home;
      foundPath  = jvm_home;
   } 

   return foundPath;
}
static bool jar_or_zip_file_exists(_str filename_noext) {
   if (file_exists(filename_noext".jar")) {
      return true;
   }
   return  file_exists(filename_noext".zip");
}

static _str get_specific_JDK_path(_str base_dir, _str jdk_version)
{
   if (_isUnix()) {
      javaPath := base_dir:+"/java":+jdk_version:+FILESEP;
      if (isdirectory(javaPath)) {
         return(javaPath);
      }
      if (_isMac()) {
         // The macintosh has things installed under the base dir:  /System/Library/Frameworks/JavaVM.framework/Versions
         // For example: /System/Library/Frameworks/JavaVM.framework/Versions/1.4.2/
         javaPath="";
         searchStr := base_dir:+FILESEP:+jdk_version:+"*";
         //say("get_specific_JDK_path: searchStr="searchStr);
         filename := file_match("+D +X -P ":+searchStr,1);
         if (filename=="") {
            searchStr = base_dir:+FILESEP:+"jdk":+jdk_version:+"*";
            //say("get_specific_JDK_path: searchStr="searchStr);
            filename = file_match("+D +X -P ":+searchStr,1);
         }
         if (filename=="") {
            searchStr = base_dir:+FILESEP:+"jdk-":+jdk_version:+"*";
            //say("get_specific_JDK_path: searchStr="searchStr);
            filename = file_match("+D +X -P ":+searchStr,1);
         }
         //say("get_specific_JDK_path: findFirst="filename);
         for (;;) {
            if (filename=="=" || filename=="" )  break;
            if (filename!="" && _last_char(filename)==FILESEP && jar_or_zip_file_exists(filename:+"Home":+FILESEP:+"src")) {
               if (length(javaPath) > 0) javaPath :+= ":";
               javaPath :+= filename:+FILESEP:+"Home":+FILESEP;
            }
            if (filename!="" && _last_char(filename)==FILESEP && jar_or_zip_file_exists(filename:+"Contents":+FILESEP:+"Home":+FILESEP:+"src")) {
               if (length(javaPath) > 0) javaPath :+= ":";
               javaPath :+= filename:+FILESEP:+"Contents":+FILESEP:+"Home":+FILESEP;
            }
            if (filename!="" && _last_char(filename)==FILESEP && jar_or_zip_file_exists(filename:+"Contents":+FILESEP:+"Home":+FILESEP:+"lib":+FILESEP:+"src")) {
               if (length(javaPath) > 0) javaPath :+= ":";
               javaPath :+= filename:+FILESEP:+"Contents":+FILESEP:+"Home":+FILESEP:+"lib":+FILESEP;
            }
            // Be sure to pass filename with correct path.
            // Result filename is built with path of given file name.
            filename=file_match(filename,0);       // find next.
            // say("get_specific_JDK_path: findNext="filename);
         }
         return(javaPath);
      }
      // Sometimes the JDK is installed under /usr/lib/jvm/
      // For example: /usr/lib/jvm/java-1.7.0-openjdk-amd64
      javaPath=base_dir:+"/java-"jdk_version:+"*";
      javaPath=file_match("+D +X +P ":+javaPath,1);
      if (javaPath!="" && isdirectory(javaPath)) {
         return(javaPath);
      }
      // Sometimes the JDK is installed under /usr/java/
      // For example: /usr/java/jdk1.3.0_02/
      javaPath=base_dir:+"/java":+FILESEP:+"jdk":+jdk_version:+"*";
      javaPath=file_match("+D +X +P ":+javaPath,1);
      if (javaPath!="" && isdirectory(javaPath)) {
         return(javaPath);
      }
      // Sometimes the JDK is installed under /usr/java/jdk-VERSION
      // For example: /usr/java/jdk-9.0.1/
      javaPath=base_dir:+"/java":+FILESEP:+"jdk-":+jdk_version:+"*";
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
   }

   javaPath := "";
   parse jdk_version with auto major "." . ;
   if ( isinteger(major) && (int)major >= 9 ) {
      javaPath = _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\JavaSoft\JDK\'jdk_version,"","JavaHome");
   }
   if (javaPath=="") {
      javaPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\JavaSoft\Java Development Kit\'jdk_version,"","JavaHome");
   }
   if (javaPath=="") {
      return("");
   }
   _maybe_append_filesep(javaPath);
   if (!file_exists(javaPath"bin":+FILESEP:+"javac.exe")) {
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
      if (!file_exists(javaPath"javac.exe")) {
         return("");
      }
      // Strip the 'bin' directory
      javaPath=substr(javaPath,1,length(javaPath)-1);
      javaPath=_strip_filename(javaPath,'N');
   }
   if (javaPath !="" && create_java_autotag_args(javaPath) == "") {
      javaPath = "";
   }
   return(javaPath);
}

_str get_jdk_version_from_exe(_str exe = ""){
   _str temp = mktemp();
   int status = shell(exe:+" -version 2> ":+_maybe_quote_filename(temp), 'Q');
   if (status == 0) {
      int temp_wid, orig_wid;
      _open_temp_view(_maybe_quote_filename(temp), temp_wid, orig_wid);
      _str line, ver;
      get_line(line);
      parse line with 'java version "'ver'"';
      if (ver == "") {
         parse line with 'openjdk version "'ver'"';
      }
      _delete_temp_view(temp_wid);
      p_window_id = orig_wid;
      return(ver);
   }
   return("");
}
_str get_jdk_name_from_path(_str path, _str jdk_version){
   start := pos(_escape_re_chars(jdk_version):+"?*", path, 1, 'R');
   if (!start) {
      return ("");
   }
   temp_str := substr(path, start);
   int len = pos(FILESEP,temp_str) - 1;
   path = substr(path,start,len);
   if (get_extension(path,true) == ".jdk") {
      path = substr(path,1,length(path)-4);
   }
   return(COMPILER_NAME_SUN :+ " " :+ path);
}

_str get_jdk_from_root(_str root_dir = ""){
   name := "";
   java_exe :=  root_dir:+ "bin" :+ FILESEP :+ "java"; 

   if (_isWindows()) {
      java_exe :+= ".exe";
   }

   if (file_exists(java_exe)) {
      _str ver = get_jdk_version_from_exe(_maybe_quote_filename(java_exe)); 
      name = COMPILER_NAME_SUN :+ " " :+ ver;
   }
   return (name);
}

void get_javac_from_path( _str (& javaList)[], _str &JDKPath, _str (&javaNamesList)[])
{
   javaPath := "";
   if (_isUnix()) {
      /*   javaPath = path_search("javac");
         if (javaPath == "") return;
         //javaPath = absolute(javaPath);  // resolve symbollic links
         javaPath = strip_filename(javaPath, "N");
         if (javaPath=="/usr/bin/") {*/
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
      /*      if (file_exists("/usr/share/libgcj.jar")) {
               javaList[javaList._length()]= "/usr/share/";
               return;
            }
            return;
         }
         javaPath = substr(javaPath,1,length(javaPath)-1);
         javaPath = strip_filename(javaPath, "N");
         if (javaPath == "") return;
         javaList[javaList._length()]= javaPath;
         JDKPath=javaPath;*/
   } else {
      javaPath=path_search("javac.exe","PATH","P");
      if (javaPath!="") {
         dir := _strip_filename(javaPath, "N");
         java_exe := _maybe_quote_filename(dir :+ "java.exe");
         ver := "";
         if (file_exists(java_exe)) {
            ver = get_jdk_version_from_exe(java_exe);
         } 
         javaPath2 := substr(javaPath,1,(pathlen(javaPath)-1));
         subdirname := _strip_filename(javaPath2,"PDE");
         if (_file_eq(subdirname,"bin")) {
            javaPath=_strip_filename(javaPath2,'N');
            javaPath=_strip_filename(javaPath, 'NE');
            if (ver :!= "") {
               name :=  COMPILER_NAME_SUN :+ " " :+ ver;
               javaNamesList[javaNamesList._length()] = name;
               javaList[javaList._length()]= javaPath;
               JDKPath=javaPath;
            }
   /*         javaList[javaList._length()]= javaPath;
            JDKPath=javaPath;*/
         }
      }
   }
}

_str get_java_from_settings_or_java_home()
{
   java_name := "java":+EXTENSION_EXE;
   java_path := def_jdk_install_dir;
   if (java_path != "") {
      _maybe_append_filesep(java_path);
      java_path :+= "bin" :+ FILESEP :+ java_name;
      if (file_exists(java_path)) {
         return _maybe_quote_filename(java_path);
      }
   }
   java_path = get_env("JAVA_HOME");
   if (java_path != "") {
      _maybe_append_filesep(java_path);
      java_path :+= "bin" :+ FILESEP :+ java_name;
      if (file_exists(java_path)) {
         return _maybe_quote_filename(java_path);
      }
   }
   return java_name;
}

void get_javac_from_defvar( _str (& javaList)[], _str &JDKPath, _str (&javaNamesList)[])
{
   _str javaPath=def_jdk_install_dir;
   if (javaPath!="") {
      _maybe_append_filesep(javaPath);
      javaPath2 :=  javaPath:+"bin";
      java_name :=  "java":+EXTENSION_EXE;
      java_exe := _maybe_quote_filename(javaPath2 :+ FILESEP :+ java_name);
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
   if ( javaPath != "" ) {
      javaPath=strip(javaPath,'B','"');
      //strip off the javac.exe "%1" arguments
      javaPath=_strip_filename(javaPath,'N');

      //If the last subdirectory in the path is bin, strip it off
      if (_last_char(javaPath) == FILESEP && javaPath !="") {
         javaPath2 := substr(javaPath,1,(pathlen(javaPath)-1));
         subdirname := _strip_filename(javaPath2,"PDE");
         if (_file_eq(subdirname,"bin")) {
            javaPath=_strip_filename(javaPath2,"N");
         } else {
            javaPath="";
         }
      }
      if (javaPath!="") {
         if (!isdirectory(javaPath)) {
            javaPath="";
         }
      }
   }
   return(javaPath);

}

static _str get_vcafe_path()
{
   if (_isUnix()) {
      return("");
   }
   //Check for Visual Cafe
   _str javaPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Classes\VisualCafeProject.Document\shell\open\command',"");
   if (javaPath != "") {
      javaPath=clean_javaPath(javaPath);

   }
   if (javaPath !="" && create_java_autotag_args(javaPath) == "") {
      javaPath = "";
   }
   return(javaPath);
}

static _str get_jbuilder_path()
{
   if (_isUnix()) {
      return("");
   }
   //Check for JBuilder 3
   _str javaPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Classes\JBuilder.Project\Shell\Open\Command',"");
   //Check for JBuilder
   if (javaPath=="") {
      javaPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Classes\JBuilder.ProjectFile\Shell\Open\Command',"");
   }
   if (javaPath !="") {
      javaPath=clean_javaPath(javaPath);
   }
   if (javaPath !="" && create_java_autotag_args(javaPath) == "") {
      javaPath = "";
   }
   return(javaPath);
}

static _str get_jpp_path()
{
   if (_isUnix()) {
      return("");
   }
   //Check for J++ 6.0
   _str javaPath,javaPath2="";
   status := _ntRegFindValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\Java VM',"LibsDirectory",javaPath);
   _maybe_strip_filesep(javaPath);
   if (javaPath!="") {
      javaPath=_replace_envvars(javaPath);
      javaPath=_strip_filename(javaPath,'N');
   }
   if (javaPath != "") {
      javaPath2= javaPath:+"Packages";
      if (isdirectory(javaPath2)) {
         javaPath2 :+= FILESEP:+"*.zip";
         if ((file_match(_maybe_quote_filename(javaPath2):+"  -p",1)) !="") {
            if (javaPath !="" && create_java_autotag_args(javaPath) == "") {
               javaPath = "";
            }
            return(javaPath);
         }
      }
   }
   //Check for J++ 1.0
   if (javaPath != "") {
      //javaPath=javaPath:+"Java":+FILESEP;
      if (isdirectory(javaPath)) {
         javaPath2 :+= "classes":+FILESEP:+"classes.zip";
         if ((file_match(_maybe_quote_filename(javaPath2)"  -p",1))== "") {
            javaPath="";
         }
      } else {
         javaPath="";
      }
   }
   if (create_java_autotag_args(javaPath) == "") {
      javaPath = "";
   }

   return(javaPath);
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
   // It may seem strange using absolute_file_exists() on files that were already, 
   // found by file_match(), but we need to do that to avoid problems with some 
   // java packages on linux that have src.zip as a broken symbolic link to another 
   // directory. Doing the extra test filters out these broken links. 
   match := file_match("-p +t "_maybe_quote_filename(javaPath:+"String.java"),1);
   if (match!="") {
      return(javaPath:+"*.java");
   }else{
      match=file_match("-p +t "_maybe_quote_filename(javaPath:+"lib":+FILESEP"src.zip"),1);
      if (match!="" && absolute_file_exists(match)) {
         return(match);
      }
      match=file_match("-p +t "_maybe_quote_filename(javaPath:+"src.zip"),1);
      if (match!="" && absolute_file_exists(match)) {
         return(match);
      }
      match=file_match("-p +t "_maybe_quote_filename(javaPath:+"src.jar"),1);
      if (match!="" && absolute_file_exists(match)) {
         return(match);
      }
      match=file_match("-p +t "_maybe_quote_filename(javaPath:+"rt.jar"),1);
      if (match!="" && absolute_file_exists(match)) {
         return(match);
      }
      match=file_match("-p +t "_maybe_quote_filename(javaPath:+"classes.zip"),1);
      if (match!="" && absolute_file_exists(match)) {
         return(match);
      }
   }
   return("");
}

static bool absolute_file_exists(_str filename)
{
   if (_isUnix()) {
      // Resolve symlinks, so we test for the existence of the target of
      // the symlink, not the symlink itself.
      return file_exists(absolute(filename, null, true));
   } else {
      return file_exists(filename);
   }
}

/*
 Function Name:create_java_autotag_args

 Parameters:  javaPath

 Description: determines what argument paths should be set for make_tags

 Returns:     the command argument for make_tags

 */
_str create_java_autotag_args(_str javaPath/*,bool find_jdk=false*/)
{
   include_path := "";
   cmdargs := "";
   JppFlag := false;
   LibsFound := false;
   _maybe_append_filesep(javaPath);

   if (_isUnix()) {
      if (_isMac()) {
         include_path=javaPath;
         if( isdirectory(include_path:+"Home":+FILESEP) && file_exists(include_path:+"Home":+FILESEP:+"src.jar") ) {
            // Tiger, Leopard, and early Snow Leopard installations
            cmdargs :+= " "_maybe_quote_filename(include_path):+"Home":+FILESEP:+"src.jar";
         } else if( isdirectory(include_path:+"Home":+FILESEP) && file_exists(include_path:+"Home":+FILESEP:+"src.zip") ) {
            // Yosemite
            cmdargs :+= " "_maybe_quote_filename(include_path):+"Home":+FILESEP:+"src.zip";
         } else if( isdirectory(include_path:+"Home":+FILESEP) && file_exists(include_path:+"Home/lib/":+FILESEP:+"src.zip") ) {
            // Java 10.x
            cmdargs :+= " "_maybe_quote_filename(include_path):+"Home/lib":+FILESEP:+"src.zip";
         } else if( isdirectory(include_path:+"Home":+FILESEP) && file_exists(include_path:+"Classes":+FILESEP:+"classes.jar") ) {
            // Later Snow Leopard and Lion installations
            cmdargs :+= " "_maybe_quote_filename(include_path):+"Classes":+FILESEP:+"classes.jar";
         }
         if (cmdargs != "") {
            return cmdargs;
         }
      }

      //Get the .java files from the src subdirectory
      include_path=javaPath:+"src":+FILESEP;
      //SrcFound=0;
      if ( isdirectory(include_path) ) {
         cmdargs :+= ' ""include_path:+"*.java"';
         //SrcFound=1;
      } else if (isdirectory(javaPath"java") &&
                 isdirectory(javaPath"javax") &&
                 isdirectory(javaPath"com")) {
         include_path=javaPath;
         //cmdargs=cmdargs:+' ""include_path:+"*.java"';
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
         include_path :+= "lib":+FILESEP:+"src.zip";
         if (!absolute_file_exists(include_path)) {
            include_path=javaPath:+"src.zip";
         }
         if (absolute_file_exists(include_path)) {
            cmdargs :+= " "_maybe_quote_filename(include_path);
            //SrcFound=1;
         } else {
            include_path=javaPath;
            include_path :+= "src.jar";
            if (absolute_file_exists(include_path)) {
               cmdargs :+= " "_maybe_quote_filename(include_path);
               //SrcFound=1;
            } else {
               _str last_effort = CheckForUserInstalledJava(javaPath);
              if (last_effort != "" && last_effort != " ") {
                 cmdargs :+= " "_maybe_quote_filename(last_effort);
              }
            }
         }
      }
      if (cmdargs=="") {
         //say("h1 javaPath="javaPath);
         if(file_exists(javaPath:+"libgcj.jar") && isdirectory(javaPath:+"kaffe")) {
            //say("h2");
            //Could add usr/share/pgsql/jdbc7.0-1.1.jar  OR usr/share/pgsql/jdbc7.1-1.2.jar
            cmdargs=cmdargs:+" "_maybe_quote_filename(javaPath:+"libgcj.jar"):+" ":+
               _maybe_quote_filename(javaPath:+"kaffe":+FILESEP:+"*.jar");
            //say(cmdargs);
         } else {
            // There's no source that we found, next best thing is to tag the jre
            // jar files. 
            if (isdirectory(javaPath"jre/lib")) {
               cmdargs :+= " "_maybe_quote_filename(javaPath"jre/lib/*.jar");
            }
         }
      }
      return(cmdargs);
   }

   test_javaPath := "";
   int status=_ntRegFindValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\Java VM',"LibsDirectory",test_javaPath);
   if (test_javaPath!="") {
      _maybe_strip_filesep(test_javaPath);
      test_javaPath=_replace_envvars(test_javaPath);
      test_javaPath=_strip_filename(test_javaPath,'N');
      _maybe_append_filesep(test_javaPath);
      JppFlag=_file_eq(test_javaPath,javaPath);
   }
   if (JppFlag) {
      include_path = javaPath:+"Packages":+FILESEP;
      if (isdirectory(include_path)) {
         cmdargs :+= ' "':+include_path:+'*.zip"';
         if ((file_match(_maybe_quote_filename(include_path:+"*.zip"):+" -p",1))!="") {
            //messageNwait("cmdargs "cmdargs);
            return(cmdargs);
         }
      }
      include_path = javaPath:+"Classes":+FILESEP;
      if (isdirectory(include_path)) {
         cmdargs :+= ' "':+include_path:+'classes.zip"';
         if ((file_match(_maybe_quote_filename(include_path:+"classes.zip"):+" -p",1))!="") {
            //messageNwait("cmdargs2 "cmdargs);
            return(cmdargs);
         }
      }
   }
   //Vcafe, Jbuilder, and J++ you have to add the java subdirectory
   // if we retrieved the value from the registry.
   if (_last_char(javaPath) == FILESEP) {
      javaPath2 := substr(javaPath,1,(pathlen(javaPath)-1));
      subdirname := _strip_filename(javaPath2,'P');
      if (!_file_eq(subdirname,"java")) {
         javaPath2=javaPath:+"java":+FILESEP;
         // added for the case where the JDK 1.4 has no src subdir in it
         // such that there is a java sun and com directory under the jdk dir
         if (isdirectory(javaPath2) && !isdirectory(javaPath:+"com":+FILESEP)) {
            javaPath=javaPath2;
         }
      }
   }
   //It's not Supercede, so its JDK, VCafe, or Jbuilder

   //Get the .java files from the src subdirectory
   include_path=javaPath:+"src":+FILESEP;
   if ( isdirectory(include_path) ) {
      cmdargs :+= ' "'include_path:+'*.java"';
      LibsFound=true;
   } else if (isdirectory(javaPath"java") &&
              isdirectory(javaPath"javax") &&
              isdirectory(javaPath"com")) {
      // what should i do for this case?
      include_path=javaPath;
      //cmdargs=cmdargs:+' "'include_path:+'*.java"';
      // this line was necessary to exclude adding the demo directory to the java tag file
      cmdargs=cmdargs:+' "'include_path:+'sunw':+FILESEP:+'*.java"':+
                       ' "'include_path:+'javax':+FILESEP:+'*.java"':+
                       ' "'include_path:+'org':+FILESEP:+'*.java"':+
                       ' "'include_path:+'java':+FILESEP:+'*.java"':+
                       ' "'include_path:+'com':+FILESEP:+'*.java"';
      LibsFound=true;
   } else {
      //If there is no src subdirectory, get the src.jar file
      include_path=javaPath;
      include_path :+= "lib":+FILESEP:+"src.zip";
      if (!absolute_file_exists(include_path)) {
         include_path=javaPath:+"src.zip";
      }
      if (absolute_file_exists(include_path)) {
         cmdargs :+= " "_maybe_quote_filename(include_path);
         LibsFound=true;
      } else {
         include_path=javaPath;
         include_path :+= "src.jar";

         if (absolute_file_exists(include_path)) {
            cmdargs :+= " "_maybe_quote_filename(include_path);
            LibsFound=true;
         }
      }
   }
   if (!LibsFound) {
      //Get the classes.zip file from the lib subdirectory
      include_path=javaPath:+"lib":+FILESEP;
      if ( isdirectory(include_path)) {
         // JDK 1.1, 1.2, JBuilder
         if (file_match(_maybe_quote_filename(include_path:+"classes.zip")" -p",1)!= "") {
            cmdargs :+= ' "'include_path:+'classes.zip"';
            LibsFound=true;
         }
         if (file_match(_maybe_quote_filename(include_path:+"*.jar"),1)!= "") {
            cmdargs :+= ' "'include_path:+'*.jar"';
            LibsFound=true;
         }
         include_path=javaPath:+"jre":+FILESEP:+"lib":+FILESEP;
         if ( isdirectory(include_path)) {
            if (file_match(_maybe_quote_filename(include_path:+"*.jar"),1)!= "") {
               cmdargs :+= ' "'include_path:+'*.jar"';
               LibsFound=true;
            }
         }
         include_path=javaPath:+"jre":+FILESEP:+"lib":+FILESEP:+"ext":+FILESEP;
         if ( isdirectory(include_path)) {
            if (file_match(_maybe_quote_filename(include_path:+"*.jar"),1)!= "") {
               cmdargs :+= ' "'include_path:+'*.jar"';
               LibsFound=true;
            }
         }
      }
      if (!LibsFound) {
         // Visual Cafe
         include_path=javaPath:+"classes":+FILESEP;
         if ( isdirectory(include_path)) {
            LibsFound=true;
            cmdargs :+= ' "'include_path:+'*.jar"';
         }
      }
   }
   if (!LibsFound) {
      //Check for SuperCede
      include_path=javaPath:+"jre":+FILESEP;
      if (isdirectory(include_path)) {
         //We are dealing with Supercede, so we need the .jar files
         cmdargs :+= ' "'include_path:+'*.jar"';
      }
   }

   return(cmdargs);
}


_str create_cpp_autotag_args(_str cppPath)
{
   //Gather the arguments for make_tags
   cmdargs := "";
   vcppFlag := 0;
   include_path := "";
   _maybe_append_filesep(cppPath);

   if (_isUnix()) {
      include_path=cppPath;
      cmdargs :+= ' "'include_path:+'*.h"';
      cmdargs :+= ' "'include_path:+'*.cc"';
      cmdargs :+= ' "'include_path:+'*.tcc"';
      _str noext_files=_get_langext_files();
      for (;;) {
         _str curfile=parse_file(noext_files);
         if (curfile=="") break;
         cmdargs :+= " "_maybe_quote_filename(include_path:+curfile);
      }
      return(cmdargs);
   }
   if ( _file_eq(cppPath,getVcppIncludePath7()) ) {

      _str vcppPathInfo =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.0\VC\VC_OBJECTS_PLATFORM_INFO\Win32\Directories',"","Include Dirs");
      _str installDir =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.0\Setup\VC',"","ProductDir");
      _str frameworkDir =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\.NETFramework',"", "sdkInstallRoot");
      _maybe_append_filesep(frameworkDir);

      vcppPathInfo=stranslate(vcppPathInfo,installDir,"$(VCInstallDir)");
      vcppPathInfo=stranslate(vcppPathInfo,frameworkDir,"$(FrameworkSDKDir)");
      for (;;) {
         parse vcppPathInfo with include_path (PARSE_PATHSEP_RE),'r' vcppPathInfo;
         if (include_path=="") break;
         if ( isdirectory(include_path) ) {
            _maybe_append_filesep(include_path);
            //add the relevant files from the Visual C++ include directory
            cmdargs :+= ' "'include_path:+'*."';
            cmdargs :+= ' "'include_path:+'*.h"';
            cmdargs :+= ' "'include_path:+'*.hpp"';
            cmdargs :+= ' "'include_path:+'*.hxx"';
            cmdargs :+= ' "'include_path:+'*.h++"';
            cmdargs :+= ' "'include_path:+'*.inl"';
         }
      }
      return(cmdargs);
   } else if ( _file_eq(cppPath,getVcppIncludePath2003()) ) {

      _str vcppPathInfo =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.1\VC\VC_OBJECTS_PLATFORM_INFO\Win32\Directories',"","Include Dirs");
      _str installDir =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.1\Setup\VC',"","ProductDir");
      _str frameworkDir =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\.NETFramework',"","sdkInstallRoot");
      _maybe_append_filesep(frameworkDir);

      vcppPathInfo=stranslate(vcppPathInfo,installDir,"$(VCInstallDir)");
      vcppPathInfo=stranslate(vcppPathInfo,frameworkDir,"$(FrameworkSDKDir)");
      for (;;) {
         parse vcppPathInfo with include_path (PARSE_PATHSEP_RE),'r' vcppPathInfo;
         if (include_path=="") break;
         if ( isdirectory(include_path) ) {
            _maybe_append_filesep(include_path);
            //add the relevant files from the Visual C++ include directory
            cmdargs :+= ' "'include_path:+'*."';
            cmdargs :+= ' "'include_path:+'*.h"';
            cmdargs :+= ' "'include_path:+'*.hpp"';
            cmdargs :+= ' "'include_path:+'*.hxx"';
            cmdargs :+= ' "'include_path:+'*.h++"';
            cmdargs :+= ' "'include_path:+'*.inl"';
         }
      }
      return(cmdargs);
   }
   // IF NOT borland C++
   if (!isdirectory(cppPath:+"VCL")) {
      //We are tagging Visual C++
      vcppFlag=1;
   }
   include_path=cppPath:+"include" FILESEP;
   if ( isdirectory(include_path) ) {
      //add the relevant files from the Visual C++ include directory
      cmdargs :+= ' "'include_path:+'*."';
      cmdargs :+= ' "'include_path:+'*.h"';
      cmdargs :+= ' "'include_path:+'*.hpp"';
      cmdargs :+= ' "'include_path:+'*.hxx"';
      cmdargs :+= ' "'include_path:+'*.h++"';
      cmdargs :+= ' "'include_path:+'*.inl"';

   }
   include_path=cppPath:+"usr":+FILESEP:+"include":+FILESEP;
   if ( isdirectory(include_path) ) {
      //add the relevant files from the Gnu Cygwin directory
      cmdargs :+= ' "'include_path:+'*."';
      cmdargs :+= ' "'include_path:+'*.h"';
      cmdargs :+= ' "'include_path:+'*.hpp"';
      cmdargs :+= ' "'include_path:+'*.h++"';
      cmdargs :+= ' "'include_path:+'*.cc"';
      cmdargs :+= ' "'include_path:+'*.tcc"';

   }
   if (vcppFlag) {
      include_path=cppPath:+"mfc" FILESEP;
      if ( isdirectory(include_path) ) {
         //Add the relevant files from the MFC directory
         cmdargs :+= ' "'include_path:+'*.h"';
         cmdargs :+= ' "'include_path:+'*.cpp"';
      }

      include_path=cppPath:+"atl" FILESEP;
      if ( isdirectory(include_path) ) {
         //Add the relevant files from the ATL directory
         cmdargs :+= ' "'include_path:+'*.h"';
         cmdargs :+= ' "'include_path:+'*.cpp"';
      }
      include_path=cppPath:+"crt" FILESEP;
      if ( isdirectory(include_path) ) {
         //Add the relevant files from the ATL directory
         cmdargs :+= ' "'include_path:+'*."';
         cmdargs :+= ' "'include_path:+'*.h"';
         cmdargs :+= ' "'include_path:+'*.c"';
         cmdargs :+= ' "'include_path:+'*.cpp"';
      }
   }
   return(cmdargs);
}

/**
 * @return Returns the path to Borland C++ Builder (6.0) using
 *         the registry, and failing that, by finding bcb.exe
 *         using the PATH environment variable.
 */
static _str get_BCB_path()
{
   if (_isUnix()) {
      return("");
   }
   //Check to see if it is in the registry
   //HKEY_LOCAL_MACHINE\SOFTWARE\Borland\C++Builder
   _str BCBPath=_ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Borland\C++Builder',"","RootDir");
   if (BCBPath!="") {
      _maybe_append_filesep(BCBPath);
      if (create_cpp_autotag_args(BCBPath) == "") {
         return("");
      }
   }

   //Check and see if the executable is in the path
   if (BCBPath=="") {
      BCBPath=path_search("bcb.exe","Path","P");
      if (BCBPath!="") {
         //If found, strip  "bin" off the path.
         BCBPath2 := substr(BCBPath,1,(pathlen(BCBPath)-1));
         subdirname := _strip_filename(BCBPath2,"PDE");
         if (_file_eq(subdirname,"bin")) {
            BCBPath=_strip_filename(BCBPath2,'N');
            BCBPath=_strip_filename(BCBPath, 'NE');
            return(BCBPath);
         }
      }
   }

   return(BCBPath);
}

/**
 * @return Returns the path to Borland C++ BuilderX (1.0) using
 *         the registry, and failing that, by finding bcb.exe
 *         using the PATH environment variable.
 */
static _str get_BCBX_path()
{
   if (_isUnix()) {
      return("");
   }
   //Check to see if it is in the registry
   //HKEY_LOCAL_MACHINE\SOFTWARE\Borland\C++BuilderX\
   _str BCBPath=_ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Borland\C++BuilderX',"","PathName");
   if (BCBPath!="") {
      _maybe_append_filesep(BCBPath);
      if (create_cpp_autotag_args(BCBPath) == "") {
         return("");
      }
   }

   //Check and see if the executable is in the path
   if (BCBPath=="") {
      BCBPath=path_search("CBuilderW.exe","Path","P");
      if (BCBPath!="") {
         //If found, strip  'bin' off the path.
         BCBPath2 := substr(BCBPath,1,(pathlen(BCBPath)-1));
         subdirname := _strip_filename(BCBPath2,"PDE");
         if (_file_eq(subdirname,"bin")) {
            BCBPath=_strip_filename(BCBPath2,'N');
            BCBPath=_strip_filename(BCBPath, 'NE');
            return(BCBPath);
         }
      }
   }

   return(BCBPath);
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
   if (CCPath!="") {
      //If found, strip  'bin' off the path.
      CCPath2 := substr(CCPath,1,(pathlen(CCPath)-1));
      subdirname := _strip_filename(CCPath2,"PDE");
      if (_file_eq(subdirname,"bin")) {  
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
   if (_isUnix()) {
      return("");
   }
   _str cygwinPath = _cygwin_path();
   if (cygwinPath!="") {
      if (create_cpp_autotag_args(cygwinPath) == "") {
         if (!(isdirectory(cygwinPath:+"usr":+FILESEP) || isdirectory(cygwinPath:+"lib":+FILESEP))) {
            cygwinPath = "";
         }
      }
   }
   return(cygwinPath);
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
   if (_isUnix()) {
      return("");
   }
   lccPath := _ntRegQueryValue(HKEY_CURRENT_USER, 'Software\lcc\Compiler', "", "includepath");

   if (lccPath == "") {
      // that key is not there, probably
      return("");
   }

   if (lccPath!="") {
      _maybe_strip_filesep(lccPath);
      lccPath=_strip_filename(lccPath,'N');
   }
   if (lccPath!="") {
      if (create_cpp_autotag_args(lccPath) == "") {
         lccPath = "";
      }
      return(lccPath);
   }
   return(lccPath);
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
   if (_isUnix()) {
      return("");
   }
   _str vcppPath2,subdirname;
   vcppPath := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\DevStudio','Products\Microsoft Visual C++',"ProductDir");
   _maybe_append_filesep(vcppPath);
   if (vcppPath!="") {
      vcppPath=_replace_envvars(vcppPath);
      if (create_cpp_autotag_args(vcppPath) == "") {
         vcppPath = "";
      }
      return(vcppPath);
   }
   //Check the registry for msdev's location
   vcppPath=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Classes\mdpfile\shell\open\command',"");
   //If there are any quotes on, we want to strip them off
   vcppPath=strip(vcppPath,'B','"');
   if ( vcppPath != "" ) {
      //strip off the msdev.exe "%1" arguments
      vcppPath=_replace_envvars(vcppPath);
      vcppPath=_strip_filename(vcppPath,'N');

      //If the last subdirectory in the path is bin, strip it off
      if (_last_char(vcppPath) == FILESEP) {
         vcppPath2= substr(vcppPath,1,(pathlen(vcppPath)-1));
         subdirname=_strip_filename(vcppPath2,"PDE");
         if (_file_eq(subdirname,"bin")) {
            vcppPath=_strip_filename(vcppPath2,"N");
         } else {
            vcppPath="";
         }
      }

      if (vcppPath!="") {
         //If the last subdirectory in the path is SharedIDE, strip it off
         if (_last_char(vcppPath) == FILESEP) {
            vcppPath2= substr(vcppPath,1,(pathlen(vcppPath)-1));
            subdirname=_strip_filename(vcppPath2,"PDE");
            if (_file_eq(subdirname,"SharedIDE")) {
               //We have version 5.0 or greater
               vcppPath=_strip_filename(vcppPath2,"N");
               //Add The default pathname for Visual C++
               vcppPath :+= "vc" FILESEP;
            }
         }

         if (isdirectory(vcppPath) && create_cpp_autotag_args(vcppPath) != "") {
            return(vcppPath);
         } else {
            vcppPath="";
         }
      }

   }
   vcppPath=path_search("tracer.exe","PATH","P");
   if (vcppPath!="") {
      //If found, strip  'bin' off the path.
      vcppPath2= substr(vcppPath,1,(pathlen(vcppPath)-1));
      subdirname=_strip_filename(vcppPath2,"PDE");
      if (_file_eq(subdirname,"bin")) {
         vcppPath=_strip_filename(vcppPath2,'N');
         vcppPath=_strip_filename(vcppPath, 'NE');
         if (create_cpp_autotag_args(vcppPath) == "") {
            vcppPath = "";
         }
         return(vcppPath);
      }
   }
   if (create_cpp_autotag_args(vcppPath) == "") {
      vcppPath = "";
   }

   return(vcppPath);
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
   if (_isUnix()) {
      return("");
   }
   vcppPath :=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SYSTEM\ControlSet001\Control\Session Manager\Environment',"","Mstools");
   _maybe_append_filesep(vcppPath);
   if (vcppPath!="") {
      vcppPath=_replace_envvars(vcppPath);
      if (create_cpp_autotag_args(vcppPath) == "") {
         vcppPath = "";
      }
      return(vcppPath);
   }

   return(vcppPath);
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
   if (_isUnix()) {
      return("");
   }
   vcppPath := _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\Developer\Directories',"","ProductDir");
   _maybe_append_filesep(vcppPath);
   if (vcppPath!="") {
      vcppPath=_replace_envvars(vcppPath);
      if (create_cpp_autotag_args(vcppPath) == "") {
         vcppPath = "";
      }
      return(vcppPath);
   }

   return(vcppPath);
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

   if (_isUnix()) {
      return("");
   }
   vcppPath :=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\DevStudio\5.0\Products\Microsoft Visual C++',"","ProductDir");
   if (vcppPath=="") {
      vcppPath =_ntRegQueryValue(HKEY_CURRENT_USER,'SOFTWARE\Microsoft\DevStudio\5.0\Products\Microsoft Visual C++',"","ProductDir");
   }
   _maybe_append_filesep(vcppPath);
   if (vcppPath!="") {
      vcppPath=_replace_envvars(vcppPath);
      if (create_cpp_autotag_args(vcppPath) == "") {
         vcppPath = "";
      }
      return(vcppPath);
   }

   return(vcppPath);
}

_str getVcppIncludePath7()
{
   if (_isUnix()) {
      return("");
   }
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.0\Setup\VC',"","ProductDir");
}

_str getVcppIncludePath2003()
{
   if (_isUnix()) {
      return("");
   }
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\7.1\Setup\VC',"","ProductDir");
}

_str getVcppIncludePath2005()
{
   if (_isUnix()) {
      return("");
   }
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\8.0\Setup\VC',"","ProductDir");
}
_str getVcppIncludePath2005Express()
{
   if (_isUnix()) {
      return("");
   }
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VCExpress\8.0\Setup\VC',"","ProductDir");
}
_str getVcppIncludePath2008()
{
   if (_isUnix()) {
      return("");
   }
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\9.0\Setup\VC',"","ProductDir");
}
_str getVcppIncludePath2008Express()
{
   if (_isUnix()) {
      return("");
   }
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VCExpress\9.0\Setup\VC',"","ProductDir");
}
_str getVcppIncludePath2010()
{
   if (_isUnix()) {
      return("");
   }
   _str result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\10.0\Setup\VC',"","ProductDir");
   if (result!="") {
      // Now check if devenv is really here. This could be the 2010 express edition
      _str DEVENVDIR=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\10.0\Setup\VS',"","EnvironmentDirectory");
      if (DEVENVDIR=="") {
         // This is the 2010 Express edition
         return "";
      }
   }
   return result;
}
_str getVcppIncludePath2012()
{
   if (_isUnix()) {
      return("");
   }
   _str result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\11.0\Setup\VC',"","ProductDir");
   return result;
}
_str getVcppIncludePath2013()
{
   if (_isUnix()) {
      return("");
   }
   _str result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\12.0\Setup\VC',"","ProductDir");
   return result;
}
_str getVcppIncludePath2015()
{
   if (_isUnix()) {
      return("");
   }
   _str result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VisualStudio\14.0\Setup\VC',"","ProductDir");
   return result;
}
_str getVcppIncludePath2017()
{
   if (_isUnix()) {
      return("");
   }
   _str result = _getVStudioInstallPath2017(15);
   return result;
}
_str getVcppIncludePath2019()
{
   if (_isUnix()) {
      return("");
   }
   _str result = _getVStudioInstallPath2017(16);
   return result;
}

_str getVcppIncludePath2010Express()
{
   if (_isUnix()) {
      return("");
   }
   return _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\VCExpress\10.0\Setup\VC',"","ProductDir");
}
_str getVcppToolkitPath2003()
{
   if (_isUnix()) {
      return("");
   }
   return _ntRegQueryValue(HKEY_CURRENT_USER,"Environment","","VCToolkitInstallDir");
}

_str getVcppPlatformSDKPath2003()
{
   if (_isUnix()) {
      return("");
   }
   guidName := "";
   int status = _ntRegFindFirstSubKey(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\MicrosoftSDK\InstalledSDKs', guidName, 1);
   if (!status && guidName!="") {
      return _ntRegQueryValue(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\MicrosoftSDK\InstalledSDKs\'guidName, "", "Install Dir");
   }
   return "";
}

_str getDDKIncludePath()
{
   if (_isUnix()) {
      return("");
   }

   ddkPath := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\WINDDK', "", "LFNDirectory");
   _maybe_append_filesep(ddkPath);
   return(ddkPath);
}

_str getGNUCppIncludePath(_str cppPath)
{
   _str include_path = cppPath;
   if( file_exists( include_path :+ "limits.h" ) ) {
   } else if ( file_exists( include_path :+ "include" :+ FILESEP :+ "limits.h") ) {
      include_path :+= "include" :+ FILESEP;
   } else if ( file_exists( include_path :+ "usr" :+ FILESEP :+ "include" :+ FILESEP :+ "limits.h") ) {
      include_path :+= "usr" :+ FILESEP :+ "include" :+ FILESEP;
   } else {
      if (_isUnix()) {
         include_path = "/usr/include/";
      }
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
   case "LINUXRPI4":
      return "g++-linux-rpi4.h";
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
      return "g++-macos.h";      // macOS native
   case "MACOSX11":
      return "g++-macx11.h";     // macOS under X11
   default:
      return "";
   }
}

void getCppIncludeDirectories( _str (&config_names)[], _str (&config_includes)[], _str (&header_names)[] )
{
   // list of include directories per configuration delimited by path separators
   _str cppList[],names[];
   visualCppPath := "";
   cppList._makeempty();
   names._makeempty();
   config_includes._makeempty();
   getCppIncludePath( cppList, visualCppPath, names);

   bool includeHash:[] = null;

   output_configs := 0;
   for( i := 0 ; i < cppList._length() ; i++ ) {
      _str include_path = cppList[i];
      config_includes[ output_configs ] = "";
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

         header_names[output_configs]  = _getSysconfigMaybeFixPath("vsparser":+FILESEP:+"vscpp.h");
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
                 (names[i] == COMPILER_NAME_VS2012_EXPRESS) ||
                 (names[i] == COMPILER_NAME_VS2013) ||
                 (names[i] == COMPILER_NAME_VS2013_EXPRESS) ||
                 (names[i] == COMPILER_NAME_VS2015) ||
                 (names[i] == COMPILER_NAME_VS2015_EXPRESS) ||
                 (names[i] == COMPILER_NAME_VS2017) ||
                 (names[i] == COMPILER_NAME_VS2019) ||
                 (names[i] == COMPILER_NAME_VCPP_TOOLKIT2003) ||
                 (names[i] == COMPILER_NAME_PLATFORM_SDK2003) ) {
         strappend( config_includes[output_configs], _get_vs_sys_includes(names[i]) );

         header_names[output_configs]  = _getSysconfigMaybeFixPath("vsparser":+FILESEP:+"vscpp.h");
         config_names[output_configs]  = names[i];
         output_configs++;
      } else if ( names[i] == COMPILER_NAME_DDK ) {
         // look for any/all versions of the DDK
         _str version;
         int status=_ntRegFindFirstSubKey(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\WINDDK',version,1);

         while (!status) {
            header_names[output_configs]  = _getSysconfigMaybeFixPath("vsparser":+FILESEP:+"vscpp.h");
            config_names[output_configs]  = names[i]" - "version;
            config_includes[output_configs] = _get_vs_sys_includes(config_names[output_configs]);
            output_configs++;

            status=_ntRegFindFirstSubKey(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\WINDDK',version,0);
         }
      } else if ( names[i] == COMPILER_NAME_SUNCC ) {

         header_names[output_configs] = _getSysconfigMaybeFixPath("vsparser":+FILESEP:+getGNUCppConfigHeader());
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

      } else if (_isMac() && names[i] == COMPILER_NAME_CLANG && (beginsWith(include_path, "/Applications/Xcode") || beginsWith(include_path, "/Developer/SDKs/"))) {

         xcode_app := "";
         if (beginsWith(include_path, "/Applications/Xcode")) {
            parse include_path with "/Applications/" xcode_app ".app/Contents/Developer/" . "/" auto platformname ".platform/Developer/SDKs/" auto sdk_version ".sdk/" .;
            config_names[ output_configs ] = COMPILER_NAME_CLANG"-"xcode_app"-"sdk_version;
         } else {
            parse include_path with "/Developer/SDKs/" auto sdk_version ".sdk/" .;
            config_names[ output_configs ] = COMPILER_NAME_CLANG"-"sdk_version;
         }
   
         config_includes[ output_configs ] = include_path :+ "usr" :+ FILESEP :+ "include" :+ FILESEP;
         if (file_exists(include_path:+"usr/include/c++/4.2.1")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"usr/include/c++/4.2.1/");
         } else if (file_exists(include_path:+"usr/include/c++/4.0.0")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"usr/include/c++/4.0.0/");
         }

         if (file_exists(include_path:+"usr/include/c++/4.2.1/i686-apple-darwin10/x86_64")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"usr/include/c++/4.2.1/i686-apple-darwin10/x86_64/");
         } else if (file_exists(include_path:+"usr/include/c++/4.2.1/i686-apple-darwin10")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"usr/include/c++/4.2.1/i686-apple-darwin10/");
         } else if (file_exists(include_path:+"usr/include/c++/4.0.0/i686-apple-darwin10/x86_64")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"usr/include/c++/4.0.0/i686-apple-darwin10/x86_64/");
         } else if (file_exists(include_path:+"usr/include/c++/4.0.0/i686-apple-darwin10")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"usr/include/c++/4.0.0/i686-apple-darwin10/");
         } else if (file_exists(include_path:+"usr/include/c++/4.0.0/powerpc-apple-darwin10")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"usr/include/c++/4.2.1/powerpc-apple-darwin10/");
         } else if (file_exists(include_path:+"usr/include/c++/4.2.1/i686-apple-darwin10/")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"usr/include/c++/4.0.0/powerpc-apple-darwin10/");
         }

         if (file_exists(include_path:+"Developer/usr/llvm-gcc-4.2/include/gcc/darwin")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"usr/llvm-gcc-4.2/include/gcc/darwin/");
         }
         if (file_exists(include_path:+"Developer/Headers")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"Developer/Headers/");
         }
         if (file_exists(include_path:+"Library/Frameworks")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"Library/Frameworks/");
         }
         if (file_exists(include_path:+"System/Library/Frameworks")) {
            strappend(config_includes[output_configs], PATHSEP:+include_path:+"System/Library/Frameworks/");
         }
         if (xcode_app != "" && file_exists("/Applications/" :+ xcode_app :+ ".app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include")) {
            strappend(config_includes[output_configs], PATHSEP:+"/Applications/" :+ xcode_app :+ ".app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/");
         }
         header_names[output_configs] = _getSysconfigMaybeFixPath("vsparser":+FILESEP:+"clang-macos.h");
         output_configs++;

      } else if( ( names[i] == COMPILER_NAME_CYGWIN ) || 
                 ( names[i] == COMPILER_NAME_GCC ) ||
                 ( names[i] == COMPILER_NAME_CLANG ) ||
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
            header_names[ output_configs ] = _getSysconfigMaybeFixPath("vsparser":+FILESEP:+getGNUCppConfigHeader());
            output_configs++;
         } else if ( file_exists( include_path :+ "include" :+ FILESEP :+ "limits.h") ) {
            include_path :+= "include" :+ FILESEP;
         } else if ( file_exists( include_path :+ "usr" :+ FILESEP :+ "include" :+ FILESEP :+ "limits.h") ) {
            include_path :+= "usr" :+ FILESEP :+ "include" :+ FILESEP;
         } else {
            if (_isUnix()) {
               include_path = "/usr/include/";
            }
         }

         // Check for file /usr/include/g++-3 for unix and linux.
         gcpp3_includes :=  include_path :+ "g++-3" :+ FILESEP;
         if ( !file_exists( gcpp3_includes :+ "vector" ) ) {
            gcpp3_includes = "";
         }

         // Check for file /usr/include/mingw for cygwin
         mingw_includes :=  include_path :+ "mingw" :+ FILESEP;
         if ( !file_exists( mingw_includes :+ "ctype.h" ) ) {
            mingw_includes = "";
         }

         // Check for file /usr/include/cygwin for cygwin
         cygwin_includes :=  include_path :+ "cygwin" :+ FILESEP;
         if ( !file_exists( cygwin_includes :+ "types.h" ) ) {
            cygwin_includes = "";
         }

         // Check for file /usr/include/mingw/g++-3 for cygwin
         mingw_gcpp3_includes :=  include_path :+ "mingw" :+ FILESEP :+ "g++-3" :+ FILESEP;
         if ( !file_exists( mingw_gcpp3_includes :+ "vector" ) ) {
            mingw_gcpp3_includes = "";
         }

         // Check for file /usr/include/w32api for cygwin
         w32api_includes :=  include_path :+ "w32api" :+ FILESEP;
         if ( !file_exists( w32api_includes :+ "windows.h" ) ) {
            w32api_includes = "";
         }

         // strip the include directories off of the path
         // look under lib/gcc-lib/* for limits.h
         _str slash_path = cppList[i];
         _maybe_append_filesep(slash_path);
         _str gcclib_path[];
         if ( names[i] == COMPILER_NAME_CLANG ) {
            gcclib_path[0] = slash_path:+"lib":+FILESEP:+"clang":+FILESEP;
         } else {
            gcclib_path[0] = slash_path:+"lib":+FILESEP:+"gcc-lib":+FILESEP;
            gcclib_path[1] = slash_path:+"lib":+FILESEP:+"gcc":+FILESEP;   // changed in gcc3.4
            gcclib_path[2] = slash_path:+"include":+FILESEP:+"gcc":+FILESEP;  // Mac location
         }
         for (gcclib_path_index:=0;gcclib_path_index<gcclib_path._length();++gcclib_path_index) {
            // Add multiple configs based on different compiler versions
            match := file_match("+T "_maybe_quote_filename( gcclib_path[gcclib_path_index] :+ "varargs.h"),1);
            while (match!="") {

               // parse the gcc version and target version out of the list
               gcc_version := "";
               target_version := "";
               parse match with . (gcclib_path[gcclib_path_index]) target_version (FILESEP) gcc_version (FILESEP) "include" (FILESEP) "limits.h";

               _str full_name = names[i];
               if ( names[i] != COMPILER_NAME_CLANG && gcc_version!="") {
                  strappend(full_name,"-"gcc_version);
               }
               if (target_version!="") {
                  strappend(full_name,"-"target_version);
               }

               already_added := false;
               int search_index;
               for (search_index=0;search_index<output_configs;++search_index) {
                  if (config_names[search_index]:==full_name) {
                     already_added=true;
                  }
               }

               if ((gcc_version!="" || target_version!="") && gcc_version!="install-tools" && !already_added) {
                  config_includes[ output_configs ] = "";

                  // check for include/c++/version/.
                  cpp_version_include :=  slash_path:+"include":+FILESEP:+"c++":+FILESEP:+gcc_version:+FILESEP;
                  if (file_exists(cpp_version_include:+"vector")) {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cpp_version_include );
                  } else {
                     cpp_version_include = slash_path:+"usr":+FILESEP:+"include":+FILESEP:+"c++":+FILESEP:+gcc_version:+FILESEP;
                     if (file_exists(cpp_version_include:+"vector")) {
                        _maybe_append( config_includes[output_configs], PATHSEP );
                        strappend( config_includes[output_configs], cpp_version_include );
                     }
                  }
                  // check for include/c++/version/target/
                  cpp_version_include = slash_path:+"include":+FILESEP:+"c++":+FILESEP:+gcc_version:+FILESEP:+target_version:+FILESEP;
                  if (file_exists(cpp_version_include:+"bits":+FILESEP:+"c++config.h")) {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cpp_version_include );
                  } else {
                     cpp_version_include = slash_path:+"usr":+FILESEP:+"include":+FILESEP:+"c++":+FILESEP:+gcc_version:+FILESEP:+target_version:+FILESEP;
                     if (file_exists(cpp_version_include:+"bits":+FILESEP:+"c++config.h")) {
                        _maybe_append( config_includes[output_configs], PATHSEP );
                        strappend( config_includes[output_configs], cpp_version_include );
                     }
                  }
                  // check for include/c++/version/backward/
                  cpp_version_include = slash_path:+"include":+FILESEP:+"c++":+FILESEP:+gcc_version:+FILESEP:+"backward":+FILESEP;
                  if (file_exists(cpp_version_include:+"new.h")) {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cpp_version_include );
                  } else {
                     cpp_version_include = slash_path:+"usr":+FILESEP:+"include":+FILESEP:+"c++":+FILESEP:+gcc_version:+FILESEP:+"backward":+FILESEP;
                     if (file_exists(cpp_version_include:+"new.h")) {
                        _maybe_append( config_includes[output_configs], PATHSEP );
                        strappend( config_includes[output_configs], cpp_version_include );
                     }
                  }

                  // check for include/g++
                  cpp_version_include = slash_path:+"include":+FILESEP:+"g++":+FILESEP;
                  if (file_exists(cpp_version_include:+"vector")) {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cpp_version_include );
                  } else {
                     cpp_version_include = slash_path:+"usr":+FILESEP:+"include":+FILESEP:+"g++":+FILESEP;
                     if (file_exists(cpp_version_include:+"vector")) {
                        _maybe_append( config_includes[output_configs], PATHSEP );
                        strappend( config_includes[output_configs], cpp_version_include );
                     }
                  }

                  // check for include/g++/target/
                  cpp_version_include = slash_path:+"include":+FILESEP:+"g++":+FILESEP:+target_version:+FILESEP;
                  if (file_exists(cpp_version_include:+"bits":+FILESEP:+"c++config.h")) {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cpp_version_include );
                  } else {
                     cpp_version_include = slash_path:+"usr":+FILESEP:+"include":+FILESEP:+"g++":+FILESEP:+target_version:+FILESEP;
                     if (file_exists(cpp_version_include:+"bits":+FILESEP:+"c++config.h")) {
                        _maybe_append( config_includes[output_configs], PATHSEP );
                        strappend( config_includes[output_configs], cpp_version_include );
                     }
                  }

                  // now try gcc-lib/platform/version/target/include
                  _maybe_append( config_includes[output_configs], PATHSEP );
                  strappend( config_includes[output_configs], _strip_filename(match,'n') );
                  if (substr(gcc_version,1,1) == 3 && gcpp3_includes != "") {
                     _maybe_append( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], gcpp3_includes );
                  }

                  // add the basic include path
                  _maybe_append( config_includes[output_configs], PATHSEP );
                  strappend( config_includes[output_configs], include_path );

                  // add the win32api path
                  if (w32api_includes != "") {
                     strappend( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], w32api_includes );
                  }

                  // add the cygwin and mingw extensions
                  if (pos("cygwin",target_version) && cygwin_includes != "") {
                     strappend( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], cygwin_includes );
                  }
                  if (mingw_includes != "") {
                     strappend( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], mingw_includes );
                  }
                  if (substr(gcc_version,1,1) == 3 && mingw_gcpp3_includes != "") {
                     strappend( config_includes[output_configs], PATHSEP );
                     strappend( config_includes[output_configs], mingw_gcpp3_includes );
                  }
                  header_names[output_configs] = _getSysconfigMaybeFixPath("vsparser":+FILESEP:+getGNUCppConfigHeader());
                  config_names[output_configs] = full_name;

                  // Make name unique if there is more than one config of this type
                  output_configs++;
               }

               match = file_match("-p +t "_maybe_quote_filename( gcclib_path[gcclib_path_index] :+ "limits.h"),0);
            }
         }
      } else if (names[i] == COMPILER_NAME_BORLAND  || 
                 names[i] == COMPILER_NAME_BORLAND6 || 
                 names[i] == COMPILER_NAME_BORLANDX) {
         // Borland C++ Builder and C++ BuilderX
         strappend( config_includes[output_configs], include_path :+ 'include\' :+ PATHSEP );
         header_names[output_configs]  = _getSysconfigMaybeFixPath("vsparser":+FILESEP:+"borland.h");
         config_names[output_configs]  = names[i];
         output_configs++;
      } else {
         // Others are not supported
      }
   }
}

void getCppIncludePath(_str (&cppList)[], _str &VisualCppPath, _str (&names)[], bool appendIncludeDirectory=false )
{
   VisualCppPath="";
   cppPath := "";
   cppPath=getVcppIncludePath2();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath4();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS4;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath5();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS5;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath6();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS6;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath7();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VSDOTNET;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2003();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2003;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2005();
   if (cppPath !="") {
      names[names._length()]=COMPILER_NAME_VS2005;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2005Express();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2005_EXPRESS;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2008Express();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2008_EXPRESS;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2008();
   if (cppPath !="") {
      names[names._length()]=COMPILER_NAME_VS2008;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2010Express();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2010_EXPRESS;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2010();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2010;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2012();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2012;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   /* 
    Since express editiong has same includes,
    dont' need autotag dialog to add this.
    
   cppPath=getVcppIncludePath2012();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2012_EXPRESS;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   } */
   cppPath=getVcppIncludePath2013();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2013;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2015();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2015;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2017();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2017;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppIncludePath2019();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2019;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   /* 
    Since express editiong has same includes,
    dont' need autotag dialog to add this.
    
   cppPath=getVcppIncludePath2013();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VS2013_EXPRESS;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }*/
   cppPath=getVcppPlatformSDKPath2003();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_PLATFORM_SDK2003;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getVcppToolkitPath2003();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_VCPP_TOOLKIT2003;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   }
   cppPath=getDDKIncludePath();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_DDK;
      if ( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=="") {
         VisualCppPath=cppPath;
      }
   }
   cppPath=get_BCBX_path();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_BORLANDX;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=="") {
         VisualCppPath=cppPath;
      }
   }
   cppPath=get_BCB_path();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_BORLAND6;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=="") {
         VisualCppPath=cppPath;
      }
   }
   cppPath=get_Cygwin_path();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_CYGWIN;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "usr":+FILESEP:+"include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=="") {
         VisualCppPath=cppPath;
      }
   }
   cppPath=get_lcc_path();
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_LCC;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=="") {
         VisualCppPath=cppPath;
      }
   }
   _str gccPath=get_cc_path("gcc");
   if (gccPath=="") gccPath=get_cc_path("gcc-4");
   if (gccPath=="") gccPath=get_cc_path("gcc-3");
   if (gccPath !="") {
      names[names._length()] = COMPILER_NAME_GCC;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=gccPath;
      if (VisualCppPath=="") {
         VisualCppPath=gccPath;
      }
   }
   if (_isUnix()) {
      if (gccPath != FILESEP:+"usr" && gccPath != FILESEP:+"usr":+FILESEP && file_exists(FILESEP:+"usr":+FILESEP:+"bin":+FILESEP:+"gcc")) {
         names[names._length()] = COMPILER_NAME_GCC;
         if( appendIncludeDirectory == true ) {
            strappend( cppPath, "include":+FILESEP );
         }
         cppList[cppList._length()]=FILESEP:+"usr";
      }
   }
   cppPath=get_cc_path("cc");
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_CC;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      if (VisualCppPath=="") {
         VisualCppPath=cppPath;
      }
   }
   cppPath=get_cc_path("cl");
   if (cppPath !="") {
      names[names._length()] = COMPILER_NAME_CL;
      if( appendIncludeDirectory == true ) {
         strappend( cppPath, "include":+FILESEP );
      }
      cppList[cppList._length()]=cppPath;
      VisualCppPath=cppPath;
   } else if (gccPath!=null) {
      VisualCppPath=gccPath;
   }
   if (_isUnix()) {
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
      // check for /usr/*/bin/gcc on Unix
      list_wid := 0;
      orig_wid := _create_temp_view(list_wid);
      if (list_wid >= 0) {
         list_wid.insert_file_list("+P -V /usr/*/bin/gcc");
         list_wid.insert_file_list("+P -V /opt/*/bin/gcc");
         list_wid.top();
         loop {
            starPath := "";
            list_wid.get_line(starPath);
            starPath = strip(starPath);
            if (file_exists(starPath)) {
               names[names._length()] = COMPILER_NAME_GCC;
               cppPath = _strip_filename(starPath,'n');
               cppPath = strip(cppPath, 'T', FILESEP);
               cppPath = _strip_filename(cppPath,'n');
               if( appendIncludeDirectory == true ) {
                  strappend( cppPath, "include":+FILESEP );
               }
               cppList[cppList._length()]=cppPath;
            }
            if (list_wid.down()) break;
         }
         _delete_temp_view(list_wid);
         activate_window(orig_wid);
      }
      // check for /usr/*/bin/clang on Unix
      list_wid = 0;
      orig_wid = _create_temp_view(list_wid);
      if (list_wid >= 0) {
         list_wid.insert_file_list("+P -V /usr/bin/clang");
         list_wid.insert_file_list("+P -V /usr/*/bin/clang");
         list_wid.insert_file_list("+P -V /opt/*/bin/clang");
         if (_isMac()) {
            list_wid.insert_file_list("+P -V /Developer/SDKs/*/usr/bin/python-config");
            list_wid.insert_file_list("+D +P -V /Applications/Xcode*.app/Contents/Developer/Platforms/*.platform/Developer/SDKs/*/usr/include/limits.h");
         }
         list_wid.top();
         loop {
            starPath := "";
            list_wid.get_line(starPath);
            starPath = strip(starPath);
            if (file_exists(starPath)) {
               names[names._length()] = COMPILER_NAME_CLANG;
               cppPath = _strip_filename(starPath,'n');
               cppPath = strip(cppPath, 'T', FILESEP);
               cppPath = _strip_filename(cppPath,'n');
               cppPath = strip(cppPath, 'T', FILESEP);
               cppPath = _strip_filename(cppPath,'n');
               if( appendIncludeDirectory == true ) {
                  strappend( cppPath, "usr/include":+FILESEP );
               }
               cppList[cppList._length()]=cppPath;
            }
            if (list_wid.down()) break;
         }
         _delete_temp_view(list_wid);
         activate_window(orig_wid);
      }
   }
}

