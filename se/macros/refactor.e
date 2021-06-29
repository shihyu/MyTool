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
#include "eclipse.sh"
#include "markers.sh"
#include "refactor.sh"
#include "tagsdb.sh"
#include "cbrowser.sh"
#include "diff.sh"
#include "mfundo.sh"
#include "xml.sh"
#include "scc.sh"
#include "color.sh"
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "cbrowser.e"
#import "cidexpr.e"
#import "cjava.e"
#import "codehelp.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "csymbols.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "guireplace.e"
#import "help.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "menu.e"
#import "projconv.e"
#import "projutil.e"
#import "project.e"
#import "refactorgui.e"
#import "quickrefactor.e"
#import "saveload.e"
#import "sellist.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "taggui.e"
#import "tagrefs.e"
#import "tags.e"
#import "util.e"
#import "vc.e"
#import "vchack.e"
#import "wkspace.e"
#endregion

using se.lang.api.LanguageSettings;

/**
 * This module implements our support for refactoring.
 *
 * @since  9.0
 */

/**
 * If 'true', the menu items for C++ refactoring will be removed. 
 *  
 * @default true
 * @categories Configuration_Variables
 */
bool def_disable_cpp_refactoring=true;


definit()
{
   if (arg(1):!='L') {
      update_compilers_xml();
   }
}

static bool update_system_headers(CompilerConfiguration (&configurations)[])
{
   modified := false;
   int compiler_index;
   _str system_header;

   for (compiler_index=0;compiler_index<configurations._length();++compiler_index) {
      system_header=configurations[compiler_index].systemHeader;
      system_header=_replace_envvars(system_header);
      sysconfig_pos := pos(FILESEP:+"sysconfig":+FILESEP,system_header,1,_fpos_case);
      if (sysconfig_pos) {
         // DJB 08-05-2005 -- system headers are now stored relative to VSROOT
         system_header=/*get_env("VSROOT"):+*/substr(system_header,sysconfig_pos+1);
         modified=true;
      }
      system_header = _encode_vslickconfig(system_header,true,false);
      configurations[compiler_index].systemHeader=system_header;
   }

   return modified;
}

static void write_compilers_xml(int handle, CompilerConfiguration (&configurations)[])
{
   int compiler_index;
   int include_index;

   int compiler_node;
   int includes_node;
   int cur_include_node;

   //empty the file and re-create it using the new format
   _xmlcfg_delete(handle,TREE_ROOT_INDEX,true);

   // add the root compilers node
   int compilers_root_node=_xmlcfg_add(handle,TREE_ROOT_INDEX,"Compilers",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(handle,compilers_root_node,"Version",COMPILERS_XML_VERSION);

   // add the DOCTYPE
   int doctypeNode = _xmlcfg_add(handle, compilers_root_node, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_BEFORE);
   _xmlcfg_set_attribute(handle, doctypeNode, "root", "Compilers");
   _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", COMPLIERS_XML_DTD_PATH);

   for (compiler_index=0;compiler_index<configurations._length();++compiler_index) {
      compiler_node=_xmlcfg_add(handle,compilers_root_node,"C_Configuration",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(handle,compiler_node,"Name",configurations[compiler_index].configuarationName);
      _xmlcfg_set_attribute(handle,compiler_node,"Header",configurations[compiler_index].systemHeader);

      includes_node=_xmlcfg_add(handle,compiler_node,"Includes",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);

      for (include_index=0;include_index<configurations[compiler_index].systemIncludes._length();++include_index) {
         cur_include_node=_xmlcfg_add(handle,includes_node,"Include",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(handle,cur_include_node,"Dir",configurations[compiler_index].systemIncludes[include_index]);
      }
   }

   _xmlcfg_save(handle,-1,VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR);
}

static void update_compilers_xml()
{
   needs_update := false;

   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;

   int status;
   int handle=_xmlcfg_open(filename,status);

   if (status) {
      return;
   }

   // read the exisiting data
   CompilerConfiguration configurations[];
   int compiler_index;
   typeless compiler_nodes[];
   int include_index;
   typeless include_nodes[];

   do {

      // check for version 9 file
      status=_xmlcfg_find_simple_array(handle,"VSRefactor/Configuration",compiler_nodes);

      if ((status==0) && (compiler_nodes._length()>0)) {
         needs_update=true;
         for (compiler_index=0;compiler_index<compiler_nodes._length();++compiler_index) {
            configurations[compiler_index].configuarationName=_xmlcfg_get_attribute(handle,
                                                                                    compiler_nodes[compiler_index],
                                                                                    "Name");
            configurations[compiler_index].systemHeader=_xmlcfg_get_attribute(handle,
                                                                              compiler_nodes[compiler_index],
                                                                              "Filename");
            status=_xmlcfg_find_simple_array(handle,"Includes/Include",include_nodes,compiler_nodes[compiler_index]);

            for (include_index=0;include_index<include_nodes._length();++include_index) {
               configurations[compiler_index].systemIncludes[include_index]=
                     _xmlcfg_get_attribute(handle,include_nodes[include_index],"Dir");
            }
         }
         update_system_headers(configurations);
         break;
      }

      // check for version 10 or later
      status=_xmlcfg_find_simple_array(handle,"Compilers/C_Configuration",compiler_nodes);

      if ((status==0) && (compiler_nodes._length()>0)) {
         for (compiler_index=0;compiler_index<compiler_nodes._length();++compiler_index) {
            configurations[compiler_index].configuarationName=_xmlcfg_get_attribute(handle,
                                                                                    compiler_nodes[compiler_index],
                                                                                    "Name");
            configurations[compiler_index].systemHeader=_xmlcfg_get_attribute(handle,
                                                                              compiler_nodes[compiler_index],
                                                                              "Header");
            status=_xmlcfg_find_simple_array(handle,"Includes/Include",include_nodes,compiler_nodes[compiler_index]);

            for (include_index=0;include_index<include_nodes._length();++include_index) {
               configurations[compiler_index].systemIncludes[include_index]=
                     _xmlcfg_get_attribute(handle,include_nodes[include_index],"Dir");
            }
         }

         if (update_system_headers(configurations)) {
            needs_update=true;
         }

         break;
      }

   } while ( false );

   if (needs_update) {
      write_compilers_xml(handle, configurations);
   }

   _xmlcfg_close(handle);
}

/**
 * Get list of files that reference the specified tag
 *
 * @param cm     Information about the tag to be checked
 * @param refFileList
 *               (output) Array of files that reference the tag
 * @param progressMin
 *               Minimum number of files in list to warrant a progress dialog
 *
 * @return 0 on succes, <0 on error
 */
static int refactor_get_occurrences_in_classes(struct VS_TAG_BROWSE_INFO& cm,
                                               _str classList[], 
                                               int (&refersToClass)[], 
                                               int progressMin = 0, 
                                               bool &cannotBeMoved=false, 
                                               bool (&occurrFiles):[]=null,
                                               VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveRefactoring()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   cannotBeMoved = false;

//   say("tag_get_occurrences_in_classes");

   //-//printBrowseInfo(cm, "tag_get_occurrence_file_list");

   // if this is a local variable or a static local function/variable, only need to
   // return the file that contains it
   if(cm.type_name == "lvar") {
      return 0;
   }

   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   status := _MaybeRetagOccurrences();
   if (status < 0) {
      return status;
   }

   // get all the project tag files
   _str fileList[] = null;
   tag_files := project_tags_filenamea();
   tag_filename := "";
   foreach (tag_filename in tag_files) {
      // open the workspace tagfile
      status = tag_read_db(tag_filename);
      if (status < 0) continue;

      // build list of files to check
      if(!tag_find_occurrence(cm.member_name, true, true)) {
         do {
            _str occurName, occurFilename;
            tag_get_occurrence(occurName, occurFilename);

            fileList[fileList._length()] = occurFilename;

         } while(!tag_next_occurrence(cm.member_name, true, true));
      }
      tag_reset_find_occurrence();
   }
   //-//say("tag_get_occurrence_file_list: " fileList._length() " possible files");

   // if the file count is high enough, show progress dialog
   progressFormID := 0;
   if(progressMin > 0 && fileList._length() > 0 && fileList._length() >= progressMin) {
      progressFormID = show_cancel_form("Finding files that reference '" cm.member_name "'", null, true, true);
   }

   // iterate over the file list, making sure they really refer to the object
   int i, n = fileList._length();
   for(i = 0; i < n; i++) {
      _str filename = fileList[i];
//     say("filename = "filename);

      tempViewID := 0;
      origViewID := 0;
      alreadyExists := false;
      status = _open_temp_view(filename, tempViewID, origViewID, "", alreadyExists, false, true);
      if(status < 0) continue;

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // doing this because it is done in cb_add_file_refs.  it may not be
      // necessary for this case
      if (p_buf_size<def_use_old_line_numbers_ksize*1024) {
         _SetAllOldLineNumbers();
      }

      // this function will return 0 on success, 2 if it has more refs
      // than the max allowed, or 2 if it has not found a ref within
      // 32*maxRefs attempts that it makes.  therefore, we should
      // return this file as a possibile match if numRefs > 0 or
      // status == 2.  a pretty good tradeoff seems to be setting
      // maxRefs to 10 which yields a maximum of 10 matches, but
      // limits the time wasted in the file with no matches by only
      // making 320 attempts
      //
      // NOTE: this did not work reliably at 10 so it is going to
      //       be set to def_cb_max_references for now to match how
      //       ctlreferences.on_change() works
      int nSeek, nClass, maxRefs = def_cb_max_references intdiv 4; // 10;
      _str errorArgs[]; errorArgs._makeempty();
      numRefs := 0;
      long seekPositions[]; seekPositions._makeempty();

      status = tag_match_symbol_occurrences_in_file_get_positions(errorArgs, seekPositions, 
                                                                  cm, p_EmbeddedCaseSensitive,
                                                                  SE_TAG_FILTER_ANYTHING,
                                                                  SE_TAG_CONTEXT_ANYTHING, 
                                                                  0, 0,
                                                                  numRefs, maxRefs, visited, depth+1);

      if(status != 0) {
//         say("status = "status);
      }

      // Go through seek positions.
      for(nSeek = 0; nSeek < seekPositions._length(); nSeek++) {

         // go to seek position of occurrence so we can get info about the prefix expression if any.
         _GoToROffset(seekPositions[nSeek]);

         instance_class := "";
         class_name := "";
         context_id := tag_get_current_context(auto tag_name, auto cur_flags, 
                                               auto cur_type_name, auto cur_type_id, 
                                               auto cur_context, instance_class, auto cur_package,
                                               visited, depth+1);

         parent_context := 0;
         tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, parent_context);

         tag_init_tag_browse_info(auto parent_cm);
         if(parent_context > 0) {
            tag_get_context_browse_info(parent_context, parent_cm);
         }

         // get the prefix expression.
         VS_TAG_IDEXP_INFO idexp_info;
         tag_idexp_info_init(idexp_info);
         if(_c_get_expression_info(false, idexp_info, visited, depth+1) != 0) {
            continue;
         }

         // If tag has a prefix find the class of the prefix.
         VS_TAG_RETURN_TYPE rt;tag_return_type_init(rt);
         if(idexp_info.prefixexp != "" && _Embeddedget_type_of_prefix(idexp_info.errorArgs, 
                                                                      idexp_info.prefixexp, rt, 
                                                                      visited, depth+1) == 0) {
            instance_class = rt.return_type;
         }

         status = _Embeddedfind_context_tags(idexp_info.errorArgs, 
                                             idexp_info.prefixexp, idexp_info.lastid, 
                                             idexp_info.lastidstart_col,
                                             idexp_info.info_flags, 
                                             idexp_info.otherinfo, 
                                             true, maxRefs, true, true,
                                             SE_TAG_FILTER_ANYTHING, 
                                             SE_TAG_CONTEXT_ALLOW_LOCALS,
                                             visited, depth+1);

         if (status >= 0) {

            occurrFiles:[filename] = true;

            int nMatch;
            for(nMatch=1; nMatch <= tag_get_num_of_matches(); ++nMatch) {
               int match_flags, start_seekpos, match_line;
               _str match_class_name, match_tag_name, match_parents, match_type;
               tag_get_detail2(VS_TAGDETAIL_match_class, nMatch, match_class_name);
               tag_get_detail2(VS_TAGDETAIL_match_name, nMatch, match_tag_name);
               tag_get_detail2(VS_TAGDETAIL_match_parents, nMatch, match_parents);
               tag_get_detail2(VS_TAGDETAIL_match_line, nMatch, match_line);
               tag_get_detail2(VS_TAGDETAIL_match_type, nMatch, match_type);
               tag_get_detail2(VS_TAGDETAIL_match_flags, nMatch, match_flags);
               tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, nMatch, start_seekpos);

//               say("     reference "cm.member_name" at seekPosition "seekPositions[nSeek]" in file "filename);
//               say("           match_class_name="match_class_name);
//               say("           match_tag_name="match_tag_name);
//               say("           match_tag_type="match_type);
//               say("           cm.class_name="cm.class_name);
//               say("           cur_context="cur_context);
//               say("           instance_class="instance_class);
//               say("           cur_flags="cur_flags);
//               say("           match_flags="match_flags);
//               say("           start_seekpos="start_seekpos);
//               say("           pa_proc_name="pa_proc_name);
//               say("           pa_start_seekpos="pa_start_seekpos);

               /*
               References in superclass functions to superclass members (cur_context == super_class)
                  -any static references can be moved.
                  -other references are ok to be moved since they will be accessible to the superclass function
                   after it moves to the subclasses.
               */

               // references to private members should stop the functions from being moved
               // if they are accessed outside the class. This should only happen if friend is used.
               // Friend references are found by tagging so this code will not work until friends are handled correctly if ever.

               if(cur_context != cm.class_name && (match_flags & SE_TAG_FLAG_PRIVATE) && !(match_flags & SE_TAG_FLAG_STATIC)) {
                  cannotBeMoved = true;
               }

               // Skip the definition match.
//               if((match_line != cm.line_no) || (filename != cm.file_name)) {
                  // any reference that is an explicit instance(or cast) of the superclass cannot be moved.
                  if(cur_context != cm.class_name && (instance_class == cm.class_name) && !(match_flags & SE_TAG_FLAG_STATIC)) {
                     cannotBeMoved = true;
//                     say("     cannot be moved");
//                     say("     reference "cm.member_name" at seekPosition "seekPositions[nSeek]" in file "filename);
//                     say("           match_class_name="match_class_name);
//                     say("           match_tag_name="match_tag_name);
//                     say("           match_tag_type="match_type);
//                     say("           cm.class_name="cm.class_name);
//                     say("           cur_context="cur_context);
//                     say("           instance_class="instance_class);
//                     say("           cur_flags="cur_flags);
//                     say("           match_flags="match_flags);
//                     say("           match_parents="match_parents);
//                     say("           start_seekpos="start_seekpos);
//                     say("           match lineno="match_line);
//                     say("           pa_proc_name="pa_proc_name);
//                     say("           pa_start_seekpos="pa_start_seekpos);
//                     say("           cm.lineno="cm.line_no);
//                     say("           cm.file_name="cm.file_name);
                  }
 //              }

               /*
               References in subclass functions to superclass members (cur_context == one of the subclasses)
                  -any reference without a prefix is ok and that subclass
                   needs to be marked as referring to that particular superclass member.
                  -any reference that is an explicit instance(or cast) of the superclass cannot be moved.
                  -any static reference can be moved but must have it's scope renamed to the subclass.
                  -any reference that is an explicitinstance(or cast) of the subclass is ok and that subclass
                   needs to be marked as referring to that particular superclass member.
               */
               for(nClass = 0; nClass < classList._length(); nClass++) {
               
                  // Mark the class that is referring to this member. This should either be the original
                  // class or a class that inherits the member of the original class. 
                  if(idexp_info.prefixexp == "" && cur_context == classList[nClass]) {
                     refersToClass[nClass]=1;
                  }

                  // any reference that is an explicitinstance(or cast) of the subclass is ok and that subclass
                  // needs to be marked as referring to that particular superclass member.
                  if(idexp_info.prefixexp != "" && instance_class == classList[nClass]) {
                     refersToClass[nClass]=1;
                  }
               }     
            }
         }

         // Make this a hash table
         // See what class in our list the class this occurrence belongs to 
         for(nClass = 0; nClass < classList._length(); nClass++) {

            // Mark the class that is referring to this member. This should either be the original
            // class or a class that inherits the member of the original class. 
            if(class_name == classList[nClass]) {
               refersToClass[nClass]++;
               break;
            }
         }
      }

      // cleanup
      _delete_temp_view(tempViewID);
      p_window_id = origViewID;

      // if there is a progress form, update it
      if(progressFormID) {
         cancel_form_progress(progressFormID, i, fileList._length());
         if(cancel_form_cancelled()) {
            // empty file list
            status = COMMAND_CANCELLED_RC;

            break;
         }
      }
   }

   // kill progress form
   if(progressFormID) {
      close_cancel_form(progressFormID);
   }

   return status;
}

int get_syntax_indent( _str extension )
{
   // Get syntax indent
   syntax_indent:=LanguageSettings.getSyntaxIndent(extension);
   if (isinteger(syntax_indent)) {
      return(int)syntax_indent;
   }
   return 3;
}

/**
 * @return Returns a bitset of VSREFACTOR_FORMAT_* flags indicating a 
 *         variety of formatting options needed by certain refactoring
 *         operations. 
 * 
 * @param lang    Language ID (see {@link p_LangId} 
 */
static int get_formatting_flags( _str lang )
{
   // flags
   flags := 0;

   braceStyle := LanguageSettings.getBeginEndStyle(lang);
   if (braceStyle == BES_BEGIN_END_STYLE_2) {
      flags |= VSREFACTOR_FORMAT_ALIGNED_STYLE_BRACES;
   }
   if (braceStyle == BES_BEGIN_END_STYLE_3) {
      flags |= VSREFACTOR_FORMAT_INDENTED_STYLE_BRACES;
   }
   if (!flags) {
      flags |= VSREFACTOR_FORMAT_K_AND_R_STYLE_BRACES;
   }
   if ((int)LanguageSettings.getFunctionBeginOnNewLine(lang)) {
      flags |= VSREFACTOR_FORMAT_FUNCTION_BRACES_ON_NEW_LINE;
   }
   if (LanguageSettings.getIndentFirstLevel(lang)) {
      flags |= VSREFACTOR_FORMAT_INDENT_FIRST_LEVEL_OF_CODE;
   }
   if (LanguageSettings.getUseContinuationIndentOnFunctionParameters(lang)) {
      flags |= VSREFACTOR_FORMAT_USE_CONTINUATION_INDENT;
   }
   if (LanguageSettings.getIndentWithTabs(lang)) {
      flags |= VSREFACTOR_FORMAT_INDENT_WITH_TABS;
   }
   if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN)) {
      flags |= VSREFACTOR_FORMAT_PAD_PARENS;
   }
   if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_NO_SPACE_AFTER_COMMA)) {
      flags |= VSREFACTOR_FORMAT_INSERT_SPACE_AFTER_COMMA;
   }

   return flags;
}

// Find a file that contains non-inline function definitions for the given class. 
_str find_class_definition_file( int editorctl_wid, _str class_name, _str langId)
{
   tag_files := editorctl_wid.tags_filenamea(langId);
   file_name := "";
   tag_file_name := "";

   // Look through all the references in this class and find the references
   // that are functions. Look for a function reference that is not inline
   // and if it is found use the file that it is in as the file to move the definition to.
   // Otherwise use the file_name where the definition was found.
   num_matches := 0;
   max_matches := def_tag_max_find_context_tags;

   editorctl_wid.tag_push_matches();

   VS_TAG_RETURN_TYPE visited:[];
   status := editorctl_wid.tag_list_in_class("",class_name,0,0,tag_files,
                                             num_matches,max_matches,
                                             SE_TAG_FILTER_ANYTHING,
                                             SE_TAG_CONTEXT_ONLY_THIS_CLASS|SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE,
                                             false, true, null, null, visited, 1);

   if (status == 1) {
      // Are any of these matches functions that are not inline?
      for (i := 1; i <= num_matches; i++) {
         tag_get_match_browse_info(i, auto cm);
         tag_file_name = cm.file_name;

         if (cm.class_name == class_name) {
            if (editorctl_wid.tag_tree_type_is_func(cm.type_name)) {
               if ((cm.flags & (SE_TAG_FLAG_INLINE|SE_TAG_FLAG_INCLASS)) == 0) {
                  file_name=cm.file_name;
                  break;
               }
            }
         }
      }
   }

   // Could not find a file with a function in it. Go with one of the files we found.
   if(file_name == "") {
      file_name = tag_file_name;
   }

   editorctl_wid.tag_pop_matches();
   return file_name;
}
/**
 * Find the project the file belongs to. Get the project information,
 * then add the file to the refactoring transaction.
 * <p>
 * If the given file is not C or C++, the file is not added to the transaction.
 *
 * @param nTransactionHandle     Refactoring transaction handle
 * @param filename               name of file to add to transaction
 *
 * @return 0 on success, <0 on error, COMMAND_CANCELLED_RC on cancelation
 */
int refactor_add_project_file(int nTransactionHandle, _str filename, bool warnProject=true)
{
   if (!_haveRefactoring()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // verify that the file is a C/C++ source file
   _str lang = _Filename2LangId( filename );
   if ( !_LanguageInheritsFrom("c", lang) ) {
      _SccDisplayOutput("Skipping:  \""filename"\" (not C/C++ source)", false);
      return 0;
   }

   // attempt to find the file in the current project
   projectName := "";
   if ( _projectFindFile(_workspace_filename, _project_name, _RelativeToProject(filename)) != "" ) {
      projectName = _project_name;
   } else {
      projectName = _WorkspaceFindProjectWithFile(filename, _workspace_filename, true, true);
   }

   // project file not found, nag them about it
   if (projectName == "") {
      currentProjectMessage := "";
      int currentProjectQuestion = MB_OKCANCEL;
      if (_project_name != "") {
         currentProjectQuestion = MB_YESNOCANCEL;
         currentProjectMessage = "\n\nUse settings from the current project (":+_strip_filename(_project_name,'P'):+") ?";
      }
      if (warnProject) {
         if (!isEclipsePlugin()) {
            int response = _message_box("Warning:\n\nThe file '" filename "' is not in a project in this workspace." :+ currentProjectMessage, "SlickEdit", currentProjectQuestion);
            if (response == IDCANCEL) {
               return COMMAND_CANCELLED_RC;
            } else if (response == IDYES || response==IDOK) {
               projectName = _project_name;
            }
         }
      } else {
         projectName = _project_name;
      }
   }

   // append the includes list for this file
   _str includes = getDelimitedIncludePath(PATHSEP, filename, projectName);

   // get the #defines and #undefs for this file
   cdefs := "";
   if (isEclipsePlugin()) {
      _eclipse_get_project_defines_string(cdefs);
   } else {
      cdefs = _ProjectGet_AllDefines(filename, _ProjectHandle(projectName), GetCurrentConfigName());
   }
   // get the compiler configuration header file and includes
   header_file := "";
   sys_includes := "";
   refactor_get_active_config(header_file, sys_includes, _ProjectHandle(projectName));

   // If they want to refactor or fully parse system includes,
   // then merge all the system includes with the user includes
   if (def_refactor_option_flags & REFACTOR_SYSTEM_INCLUDES) {
      _maybe_append(includes, PATHSEP);
      includes :+= sys_includes;
      sys_includes="";
   }

   // now add the file to the transaction
   int status = refactor_add_file( nTransactionHandle, filename, includes, sys_includes, cdefs, header_file );
   if (status < 0) {
      _message_box("Failed adding file to transaction:  ":+get_message(status));
   }
   return status;
}

static int get_all_classes_with_function(struct VS_TAG_BROWSE_INFO function_cm, _str lang, 
                                         struct VS_TAG_BROWSE_INFO (&all_classes_with_function)[],
                                         _str (&all_classes)[], 
                                         typeless &visited=null, int depth=0)
{
   int i;
   typeless tag_files = tags_filenamea(lang);
   gcanceled_finding_children = false;

   struct VS_TAG_BROWSE_INFO mother_of_all_classes=null;
   if( function_cm.class_name != "" ) {

      int wid = show("_refactor_finding_children_form");

      // Assumes that parent_classes comes back in order from highest level class to lowest level
      // say A derives from B and B derives from C the order would be:
      // A,B,C
      struct VS_TAG_BROWSE_INFO parent_classes[]=null;
      get_parents( function_cm.class_name, function_cm.tag_database, tag_files, function_cm.file_name, 
                   parent_classes );

      // Go from back to front looking for first instance of symbol name in the parent classes.
      for( i=parent_classes._length()-1; i >= 0; i-- ) {
         if (parent_classes[i].tag_database != "") {
            tag_read_db(parent_classes[i].tag_database);
         } else if (function_cm.tag_database != "") {
            tag_read_db(function_cm.tag_database);
         }
         this_class_name := tag_join_class_name(parent_classes[i].member_name, parent_classes[i].class_name, tag_files, true, false, false, visited, depth+1);
         if( ( tag_find_tag(function_cm.member_name, "proto", this_class_name ) == 0 ) ||
             ( tag_find_tag(function_cm.member_name, "func", this_class_name ) == 0 ) ||
             ( tag_find_tag(function_cm.member_name, "proc", this_class_name ) == 0 ) ||
             ( tag_find_tag(function_cm.member_name, "procproto", this_class_name ) == 0 ) || 
             ( tag_find_tag(function_cm.member_name, "constr", this_class_name ) == 0 ) ||
             ( tag_find_tag(function_cm.member_name, "destr", this_class_name ) == 0 ) ) {
            mother_of_all_classes=parent_classes[i];
            break;
         }
      }
      tag_reset_find_tag();

      // Should not happen since this means none of the parents or the class itself contains
      // the symbol name.
      if( mother_of_all_classes == null ) {
         _message_box("Could not find function definition in any classes");
         if (_iswindow_valid(wid)) wid._delete_window();
         return -1;
      } else {
         get_children_of( mother_of_all_classes.member_name, mother_of_all_classes.tag_database,
                          tag_files, mother_of_all_classes.file_name, all_classes_with_function,
                          all_classes, function_cm.member_name,
                          inheritance_depth:1000, visited, depth+1);
      }

      if (_iswindow_valid(wid)) {
         wid._delete_window();
      }
      if( gcanceled_finding_children == true ) {
         return COMMAND_CANCELLED_RC;
      }
   }

   return 0;
}
/**
 * Post a progress message while parsing or doing a refactoring operation.
 *
 * @param message    Message to display.
 */
int refactor_file_message(_str filename, int i=1, int n=1)
{
   _str completeFilename = filename;
   wid := cancel_form_wid();
   if (wid) {
      file_msg := "";
      if (n > 1) {
         file_msg = get_message(VSRC_VSREFACTOR_FILE_3A, "", i, n);
      } else {
         file_msg = get_message(VSRC_VSREFACTOR_FILE_1A, "");
      }
      int max_width=cancel_form_max_label2_width(wid) - cancel_form_text_width(wid,file_msg);
      filename=wid._ShrinkFilename(filename,max_width);
      if (n > 1) {
         cancel_form_set_labels(wid, get_message(VSRC_VSREFACTOR_FILE_3A, filename, i, n));
      } else {
         cancel_form_set_labels(wid, get_message(VSRC_VSREFACTOR_FILE_1A, filename));
      }
      // Line below causes lockup in eclipse. 
      if (!isEclipsePlugin()) {
         if (cancel_form_cancelled()) return COMMAND_CANCELLED_RC;
      }
   }

   _SccDisplayOutput("Parsing:  \""completeFilename"\"", false);
   return 0;
}

/**
 * Post a progress message while parsing or doing a refactoring operation.
 *
 * @param message    Message to display.
 */
int refactor_message(_str msg, bool isFileName=false)
{
   wid := cancel_form_wid();
   if (wid) {
      if (isFileName) {
         int max_width=cancel_form_max_label2_width(wid);
         msg=wid._ShrinkFilename(msg,max_width);
      }
      cancel_form_set_labels(wid, null, msg);
      if (cancel_form_cancelled()) return COMMAND_CANCELLED_RC;
   }
   return 0;
}

/**
 * Update the caller on our progress when doing a refactoring operation.
 * If the progress callback returns < 0, it must indicate a cancellation.
 *
 * @param progress   Progress factor between 0 .. maximum
 * @param maximum    Number that progress is computed relative to
 *
 * @return 0 on success, <0 on cancellation.
 */
int refactor_progress(int progress, int maximum)
{
   wid := cancel_form_wid();
   if (wid) {
      cancel_form_progress(wid, progress, maximum);
      if (cancel_form_cancelled()) return COMMAND_CANCELLED_RC;
   }
   return 0;
}

/**
 * Prompt user to locate a missing header file and add the include directory
 * to the end of the project's user include path.
 *
 * @param handle        Handle to transaction
 * @param filename      File being parsed
 * @param headerPath    Path as seen in #include directive
 * @param foundFile     [reference] set to path found
 *
 * @return 0 on success, <0 on error.
 */
int refactor_locate_file(int handle, _str filename, _str headerPath, _str &foundFile)
{
   // attempt to find matching file in project, this is to seed directory search
   baseHeaderName := _strip_filename(headerPath, 'P');

   // attempt to find the file in the current project or workspace
   projectName := "";
   projectDir := "";
   if ( _projectFindFile(_workspace_filename, _project_name, _RelativeToProject(baseHeaderName)) != "" ) {
      projectName = _project_name;
   } else {
      projectName = _WorkspaceFindProjectWithFile(baseHeaderName, _workspace_filename, true, true);
   }
   projectDir = _strip_filename(projectName, 'N');

   // prompt them for the location of the header file
   foundFile = _ChooseDirDialog('Find include file: "'headerPath'"',
                                projectDir, baseHeaderName);
   if (foundFile=="") {
      return(COMMAND_CANCELLED_RC);
   }
   _maybe_append_filesep(foundFile);
   foundFile :+= baseHeaderName;

   // resolve the file that was located to an include directory
   userIncludePath := foundFile;
   while (headerPath != "") {
      headerPath = _strip_filename(headerPath, 'N');
      userIncludePath = _strip_filename(userIncludePath, 'N');
      _maybe_strip_filesep(headerPath);
      _maybe_strip_filesep(userIncludePath);
   }
   _maybe_append_filesep(userIncludePath);

   // find the project that the file being parsed belongs to
   if ( _projectFindFile(_workspace_filename, _project_name, _RelativeToProject(filename)) != "" ) {
      projectName = _project_name;
   } else {
      projectName = _WorkspaceFindProjectWithFile(filename, _workspace_filename, true, true);
   }
   projectDir = _strip_filename(projectName, 'N');

   // check if this project is an associated project or a SlickEdit project
   int projectHandle = _ProjectHandle(projectName);
   if (project_is_associated_file(projectName)) {
      projectHandle = -1;
      _message_box("The include directory can not be added to an associated workspace.");
   }

   // prompt them to add that directory to their include directory list
   addIncludeDir := false;
   if (projectHandle >= 0) {
      int response = _message_box('Do you want to add "'userIncludePath'" to the end of your project include directory list?',"SlickEdit", MB_YESNO);
      if (response == IDYES) {
         addIncludeDir = true;
      }
   }

   // add the file to their project include dir list
   if (addIncludeDir) {
      // resolve the user include path relative to the project directory
      relativeIncludePath := relative(userIncludePath, projectDir);

      _str configList[];
      _ProjectGet_ConfigNames(projectHandle,configList);
      int i,n = configList._length();
      for (i=0; i<n; ++i) {
         _str includeDirs = _ProjectGet_IncludesList(projectHandle, configList[i]);
         if (!pos(PATHSEP:+relativeIncludePath:+PATHSEP, PATHSEP:+includeDirs:+PATHSEP)) {
            _ProjectSet_IncludesList(projectHandle, includeDirs:+PATHSEP:+relativeIncludePath, configList[i]);
         }
      }
   }

   // add the include path to the transaction's include paths
   if (_haveRefactoring()) {
      refactor_add_user_include_directory(handle, filename, userIncludePath);
   }

   // success
   return 0;
}

/**
 * Prompt user if they want to continue or not after a parsing failure.
 *
 * @param filename   Name of file which errors were found in
 * @param status     pass-thru status (if callback not found)
 *
 * @return <ul>
 *         <li>COMMAND_CANCELLED_RC if they say 'no'
 *         <li>0 if 'yes'
 *         <li>1 if 'yestoall'
 *         </ul>
 */
int refactor_prompt_to_skip(_str filename)
{
   msg :=  "Errors were found parsing:\n\n\"":+filename:+"\"\n\nSkip this file?";
   _str answer = show("-modal _yesToAll_form", msg, "Refactoring", false);
   if (answer == "YESTOALL") {
      return 1;
   } else if (answer == "YES") {
      return 0;
   } else {
      return COMMAND_CANCELLED_RC;
   }
}

/**
 * Show the errors in the specified refactoring transaction
 * in the output toolbar
 *
 * @param handle     Refactoring transaction handle
 * @param filename   show refactoring errors for the given file
 *
 * @return the number of errors reported
 */
int refactor_show_errors(int handle, _str filename)
{
   //say("Error(" status "): Refactoring failed with (" numErrors ") errors");

   // get the errors
   allErrorStrings := "*** Errors\n";
   numErrors := refactor_count_errors(handle, filename);
   for (i := 0; i < numErrors; i++) {
      errorString := "";
      refactor_get_error(handle, filename, i, errorString);
      allErrorStrings :+= errorString "\n";
   }

   _SccDisplayOutput(allErrorStrings);
   return numErrors;
}

//   _reload_vc_buffers( fileList );

// Save the list if files that were modified
void build_modified_file_list( int handle, _str (&fileList)[] )
{

   // build list of files that changed
   fileList = null;
   numMods := refactor_count_modified_files(handle);
   for (i := 0; i < numMods; i++) {
      filename := "";
      refactor_get_modified_file_name(handle, i, filename);
      if (filename != "") {
         fileList[fileList._length()] = filename;
      }
   }
}

/**
 * Save the files modified by this transaction and set up a
 * multi-file undo step to correspond.
 * <p>
 * The current object must be an editor control.
 *
 * @param handle     refactoring transaction handle
 * @param stepTitle  title to display for this undo step
 *
 * @return 0 on success, <0 on error
 */
int refactor_save_transaction( int handle, _str stepTitle )
{
   // start a new undo set
   error_filenames := "";
   status := result := 0;
   bool already_open;
   doMFUndo := (stepTitle != "");

   if (doMFUndo) {
      _MFUndoBegin(stepTitle);
   }
   _project_disable_auto_build(true);

   // for each file that was modified
   n := refactor_count_modified_files(handle);
   for (i := 0; i < n; i++) {
      // get the file's name
      filename := "";
      refactor_get_modified_file_name(handle, i, filename);
      if (filename == "") continue;

      // open the file in a temp view
      temp_view_id := orig_view_id := 0;
      status = _open_temp_view(filename,temp_view_id,orig_view_id,"",already_open);
      if (status) {
         strappend(error_filenames,filename:+"\n");
         result = status;
         continue;
      }

      // make the temp view current
      p_window_id=temp_view_id;

      // save bookmark, breakpoint, and annotation information
      _SaveMarkersInFile(auto markerSaves);

      // create a view containing the information needed to
      // update the window positions for this buffer.
      window_pos_view_id := _list_bwindow_pos(p_buf_id);

      // this won't work too good if we are in read-only mode
      if (_QReadOnly()) {
         status = _prompt_readonly_file(true);
         if (status == COMMAND_CANCELLED_RC) {
            return (status);
         } else if (status == -1) {
            continue;
         }
         //status = _readonly_error(0, true);
         if (!_QReadOnly()) status=0;
      }

      if (doMFUndo) {
         // log the undo step
         _MFUndoBeginStep(filename);
      }

      // out with the old, in with the new
      if (!status) {
         if (already_open) {
            p_modify = true; _undo('S'); // start a new undo step in modified state
         }

         refactor_file_wid := 0;
         original_file_wid := _create_temp_view(refactor_file_wid);
         refactor_file_wid.p_UTF8 = original_file_wid.p_UTF8;
         refactor_file_wid.p_newline = original_file_wid.p_newline;
         refactor_file_wid.p_encoding = original_file_wid.p_encoding;
         status = refactor_get_modified_file_contents(refactor_file_wid, handle, filename);
         if (status && status!=FILE_NOT_FOUND_RC) {
            strappend(error_filenames,filename:+"\n");
            result = status;
         }

         // copy lines over from refactored file to original file
         // compare them one-by-one to avoid creating too many change bars
         original_line := "";
         refactor_line := "";
         original_file_wid.top();
         original_file_wid._begin_line();
         refactor_file_wid.top();
         refactor_file_wid._begin_line();
         loop {
            // Get both lines
            original_file_wid.get_line(original_line);
            refactor_file_wid.get_line(refactor_line);
            // Replace the line if they differ
            if (original_line :!= refactor_line) {
               original_file_wid.replace_line(refactor_line);
            }

            // Drop down to the next line of the refactored version
            if (refactor_file_wid.down()) {
               if (original_file_wid.down()) break;
               while (!original_file_wid._delete_line());
               break;
            }
            // Drop down to the next line of the original version.
            // Copy the rest of the lines from the refactored source if
            // we hit the end of the original source file.
            if (original_file_wid.down()) {
               loop {
                  refactor_file_wid.get_line(refactor_line);
                  original_file_wid.insert_line(refactor_line);
                  if (refactor_file_wid.down()) break;
               }
               break;
            }

            // Try to re-align to a matching line
            if (original_line :!= refactor_line) {
               original_file_wid.save_pos(auto original_file_pos);
               refactor_file_wid.save_pos(auto refactor_file_pos);
               // Scan forward in the refactored file for a line that
               // matches the next line in the original file.
               found_matching_line := false;
               if (!found_matching_line) {
                  original_file_wid.get_line(original_line);
                  for (j:=0; j<20; j++) {
                     refactor_file_wid.get_line(refactor_line); 
                     if (original_line :== refactor_line) { 
                        refactor_file_wid.restore_pos(refactor_file_pos);
                        original_file_wid.up();
                        for (k:=0; k<j; k++) {
                           refactor_file_wid.get_line(refactor_line);
                           original_file_wid.insert_line(refactor_line);
                           refactor_file_wid.down();
                        }
                        original_file_wid.down();
                        found_matching_line = true;
                        break;
                     }
                     if (refactor_file_wid.down()) break;
                  }
               }
               // Scan forward in the original file for a line that
               // matches the next line in the refactored file.
               if (!found_matching_line) {
                  refactor_file_wid.restore_pos(refactor_file_pos);
                  refactor_file_wid.get_line(refactor_line);
                  for (j:=0; j<20; j++) {
                     original_file_wid.get_line(original_line);
                     if (original_line :== refactor_line) {
                        // delete the lines from the original that don't match
                        found_matching_line = true;
                        original_file_wid.restore_pos(original_file_pos);
                        for (k:=0; k<j; k++) {
                           original_file_wid._delete_line();
                        }
                        break;
                     }
                     if (original_file_wid.down()) break;
                  }
               }
               // Did not find a match
               if (!found_matching_line) {
                  refactor_file_wid.restore_pos(refactor_file_pos);
                  original_file_wid.restore_pos(original_file_pos);
               }
            }
         }

         // Delete the temp view containing the refactored code
         _delete_temp_view(refactor_file_wid);
         activate_window(original_file_wid);
      }

      // make sure the extension gets set or else tagging will not
      // be able to update for this file
      p_window_id._SetEditorLanguage();

      // and now we save the file
      if (!status) {
         status=save(_maybe_quote_filename(filename), SV_NOADDFILEHIST);
      }
      if (status) {
         strappend(error_filenames,filename:+"\n");
         result = status;
      }

      // restore bookmarks, breakpoints, and annotation locations
      _RestoreMmrkersInFile(markerSaves);

      // restore the window positions and clean up
      if (window_pos_view_id) {
         _set_bwindow_pos(window_pos_view_id);
         _delete_temp_view(window_pos_view_id);
      }

      // clean up the temp view
      _delete_temp_view(temp_view_id);
      orig_view_id=p_window_id;

      if (doMFUndo) {
         // complete the undo step
         _MFUndoEndStep(filename);
      }

      // save status is cancellation
      if (status == COMMAND_CANCELLED_RC) {
         break;
      }
   }

   _project_disable_auto_build(false);

   if (doMFUndo && status == COMMAND_CANCELLED_RC) {
      _MFUndoCancel();
      return status;
   }

   if (doMFUndo) {
      // indicate that the current undo set is complete
      _MFUndoEnd();
   }

   // If errors occurred, report them all right here, right now
   if (error_filenames != "") {
      _message_box(nls("Could not save files.\n%s\n\n%s",get_message(status),error_filenames));
   }
   return result;
}

/**
 * Review the refactoring transaction.
 * <p>
 * This method will do the following:
 * <ul>
 * <li>If status is COMMAND_CANCELLED_RC, cancel the transaction quietly
 * <li>Update the errors and display an error message if status < 0 otherwise
 * <li>Display the results dialog for reviewing changes
 * <li>save the modified files
 * </ul>
 *
 * @param handle                 refactoring transaction handle
 * @param status                 status returned by refactoring
 * @param error_message          message to display if status < 0
 * @param undo_message           message to display if status < 0
 * @param file_name              name of file to report errors happening in
 * @param quiet                  no output messages 
 * @param place_modified_on_left Reverse position of files so the modified file is on the left
 *
 * @return status on success, COMMAND_CANCELLED_RC if they cancel.
 */
int refactor_review_and_commit_transaction(int handle, 
                                           int status, 
                                           _str error_message, 
                                           _str undo_message, 
                                           _str file_name="", 
                                           _str results_name="Refactoring results", 
                                           bool quiet = false,
                                           bool place_modified_on_left=false )
{
   // does the user prefer refactoring to show the modified file on the left
   if (def_refactor_option_flags & REFACTOR_PREVIEW_REVERSED) {
      if (results_name == "Refactoring results") {
         place_modified_on_left = true;
      }
   }

   // if the transaction was cancelled, then exit quietly
   if (status == COMMAND_CANCELLED_RC) {
      refactor_cancel_transaction(handle);
      if (!quiet) {
         _SccDisplayOutput("Cancelled.");
      }
      clear_message();
      return status;
   }

   // If there were errors, show them and cancel the transaction
   if (status < 0) {
      numErrors := refactor_count_errors(handle, "");
      refactor_cancel_transaction(handle);
      clear_message();
      if (error_message != "") {
         // check to see if the first error is in the parsing error
         // range or the refactoring error range
         if (status == VSRC_VSREFACTOR_PARSING_FAILURE_1A ||
             (status >= VSRC_VSPARSER_ERROR_PREFIX && status <= VSRC_VSPARSER_END_ERRORS)) {
            _message_box(error_message:+"\n\n":+get_message(VSRC_VSREFACTOR_PARSING_FAILURE_1A,numErrors));
         } else {
            _message_box(error_message);
         }
      }
      return status;
   }

   // successful refactoring
   clear_message();

   // Show what changed for user confirmation.
   // "" indicates that the user hit 'Cancel'
   if (showRefactoringModifications(handle, results_name, place_modified_on_left) == "") {
      refactor_cancel_transaction(handle);
      if (!quiet) {
         _SccDisplayOutput("Cancelled.");
      }
      clear_message();
      return 0;
   }

   // Save list of files before commit since after commit
   // there will be no more modified files
   //_str fileList[] = null;
   //build_modified_file_list( handle, fileList );

   // commit the transaction
   //status = refactor_commit_transaction(handle);
   status = refactor_save_transaction(handle, undo_message);
   if (status < 0) {
      refactor_cancel_transaction(handle);
      if (!quiet) {
         if (status == COMMAND_CANCELLED_RC) {
            _SccDisplayOutput("Cancelled.");
         } else {
            _SccDisplayOutput("Failed.");
         }
      }
      _message_box("Failed to save files:  ":+get_message(status));
      return status;
   }

   // Make sure all of the open buffers matched the commited files
   //_reload_vc_buffers( fileList );
   if (!quiet) {
      _SccDisplayOutput("Done.");
   }
   refactor_cancel_transaction(handle);
   return 0;
}
_str refactor_get_active_config_name(int project_handle=-1,_str lang="")
{
   // first check project with current active config
   if (project_handle >= 0) {
      compiler_name := _ProjectGet_ActualCompilerConfigName( project_handle, GetCurrentConfigName(), lang);
      if (compiler_name != "") {
         if (compiler_name == COMPILER_NAME_NONE) return "";
         return compiler_name;
      }
   }
   if (lang != "") {
      if (_LanguageInheritsFrom("c",lang)) {
         return def_refactor_active_config;
      } else if (_LanguageInheritsFrom("java",lang)) {
         return def_active_java_config;
      } else {
         return "";
      }
   }
   /*
      Could do a little better here to support no project open and still get
      the default Java or C++ tag file.
   */
   // fall back to global default
   return def_refactor_active_config;
}
static int refactor_check_config(bool quiet=false)
{
   if (!_haveBuild()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   _str filename = _ConfigPath() :+ COMPILER_CONFIG_FILENAME;

   refactor_config_open( filename );

   int status = refactor_maybe_select_active_configuration(-1, quiet);

//   if( find_config( def_rf_active_config ) < 0 ) {
//      return show("-modal _refactor_c_compiler_properties_form");
//   }

   refactor_config_close();
   return status;
}

int refactor_get_active_config( _str &header_file, _str &includes, int project_handle=-1, bool quiet=false)
{
   if ( !_haveBuild() ) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // Cancelled if return value is an empty string
   if ( refactor_check_config(quiet) == COMMAND_CANCELLED_RC ) return COMMAND_CANCELLED_RC;

   // open the configuration file
   status := refactor_config_open( _ConfigPath() :+ COMPILER_CONFIG_FILENAME );
   if (status < 0) {
      return status;
   }

   // get the current compiler config name
   compiler_name := refactor_get_active_config_name( project_handle );

   // get the header file
   includes=header_file= "";
   refactor_config_get_header( compiler_name, header_file );

   // build delimited include path
   int i,n = refactor_config_count_includes( compiler_name );

   // make sure the config was found
   if (n < 0) {
      // fall back on the default config
      compiler_name = def_refactor_active_config;
      refactor_config_get_header(compiler_name, header_file);
      n = refactor_config_count_includes( compiler_name );
   }
   for ( i = 0 ; i < n; i++ ) {
      if ( i > 0 ) {
         strappend(includes, PATHSEP );
      }
      include_string := "";
      refactor_config_get_include( compiler_name, i, include_string );
      strappend( includes, include_string );
   }

   // finally, close the compiler configuration file
   return refactor_config_close();
}

/*
   get parent class. go through filenames for all instances of that tag
   if any of the filenames contain the child class then
*/
_str tagGetClassFilename( typeless &tag_files, _str class_name, _str &inner_class, _str fileLangId )
{
   valid_filename := "";
   if (!_haveContextTagging()) {
      return "";
   }

   // iterate through each tag file
   i := 0;
   tag_filename := next_tag_filea(tag_files,i,false,true);
   while ( tag_filename != "" ) {
      // Find prefix tag match for proc_name.
      tag_split_class_name(class_name, auto inner_name, auto outer_name);
 
      status := tag_find_equal(inner_name, true);
      while ( !status ) {
         inner_class = inner_name;
         tag_get_tag_browse_info(auto cm);
         if ( cm.language == fileLangId ) {
            valid_filename = cm.file_name;
            break;
         }
         status = tag_next_equal( true );
      }

      tag_reset_find_tag();
      tag_filename = next_tag_filea( tag_files, i, false, true );
   }

   return valid_filename;
}

// Find literal at cursor and return start seek position and end seek position of symbol
_str findLiteralAtCursor( long &startSeekPos, long &endSeekPos )
{
   literalName := "";
   literalType := 0;
   typeless cursorSeekPos;

   startSeekPos = 0;
   endSeekPos = 0;

   if (!_isEditorCtl()) {
      return "";
   }

   // Save current cursor position
   save_pos(cursorSeekPos);

   // Must be a literal.
   if ( _clex_find( NUMBER_CLEXFLAG, "T" ) != 0 ) {
      literalType = NUMBER_CLEXFLAG;
   } else if ( _clex_find( STRING_CLEXFLAG, "T" ) != 0 ) {
      literalType = STRING_CLEXFLAG;
   }

   // Test if we are immediately to the right of a literal.
   if (literalType == 0) {
      left();
      if ( _clex_find( NUMBER_CLEXFLAG, "T" ) != 0 ) {
         literalType = NUMBER_CLEXFLAG;
      } else if ( _clex_find( STRING_CLEXFLAG, "T" ) != 0 ) {
         literalType = STRING_CLEXFLAG;
      }
   }

   // Test if we are immediately to the left of a literal.
   if (literalType == 0) {
      restore_pos(cursorSeekPos);
      right();
      if ( _clex_find( NUMBER_CLEXFLAG, "T" ) != 0 ) {
         literalType = NUMBER_CLEXFLAG;
      } else if ( _clex_find( STRING_CLEXFLAG, "T" ) != 0 ) {
         literalType = STRING_CLEXFLAG;
      }
   }

   // Not a literal.
   if ( literalType == 0 ) {
      restore_pos(cursorSeekPos);
      return "";
   }

   // Move cursor to beginning of literal.
   if ( _clex_find( literalType, "-N" ) != 0 ) {
      // Could not find beginning of literal from some strange reason
      restore_pos(cursorSeekPos);
      return "";
   }

   // Beginning of literal.
   startSeekPos = _QROffset();

   // If leading character is L or S immediately before the " then grab the
   // leading character as well. Also grab leading char if it is a . This gets
   // missed for some reason.
   first_chars := get_text(2);
   if(first_chars == "L\'" || first_chars == 'L"' || first_chars == 'S"' || get_text(1) == ".") {
      startSeekPos--;
   }

   // Move cursor back to original position so that this find starts on the right literal type
   restore_pos(cursorSeekPos);

   // Find end of literal and then convert whole literal to a string
   if ( _clex_find( literalType, "N" ) == 0 ) {
      if (p_col==1) {
         up();
         _end_line();
      }
      endSeekPos = _QROffset();
      literalName = get_text( ( int )( endSeekPos - ( startSeekPos + 1 ) ), ( int )startSeekPos+1 );
   } else {
      // Hit bottom of file
      _end_line();
      endSeekPos = _QROffset();
      literalName = get_text( ( int )( endSeekPos - ( startSeekPos + 1 ) ), ( int )startSeekPos+1 );
   }

   // Restore original cursor position
   restore_pos(cursorSeekPos);

   // Make seek positions inclusive
   startSeekPos += 1;
   endSeekPos   -= 1;

   return literalName;
}

///////////////////////////////////////////////////////////////////////////////

static int find_class_struct(_str class_name) 
{
   inner_class_name := "";
   outer_class_name := "";
   tag_split_class_name(class_name, inner_class_name, outer_class_name);
   //-//say("-- find_class_struct(class="class_name" inner="inner_class_name" outer="outer_class_name"); --");

   int nStatus = tag_find_equal(inner_class_name);
   while ( nStatus >= 0 ) {
      _str str=""/*, str_cpp=""*/;
      nType := 0;
      tag_get_detail(VS_TAGDETAIL_class_name, str);
      tag_get_detail(VS_TAGDETAIL_type_id, nType);

      //str_cpp = tag_name_to_cpp_name(str);
      if ( (nType == SE_TAG_TYPE_CLASS || nType == SE_TAG_TYPE_STRUCT) && outer_class_name :== str ) {
         tag_reset_find_tag();
         return 0;
      }
      //-//say("find_class_struct(class="class_name"type="nType", outer_class_name="outer_class_name", str="str")");
      nStatus = tag_next_equal();
   }

   tag_reset_find_tag();
   return nStatus;
}

int tag_get_class_detail(_str class_name, int tag_detail, var result) 
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   nPos := pos("@", class_name);
   if ( nPos ) {
      //say("get_class_detail("class_name") pos("@")="nPos);
      return -1;
   }

   nStatus := 0;
   tag_filename := "";
   tag_files := project_tags_filenamea();
   foreach(tag_filename in tag_files) {

      nStatus = tag_read_db(tag_filename);
      if ( nStatus < 0) continue;

      nStatus = find_class_struct(class_name);
      if ( nStatus < 0 ) continue;

      tag_get_detail(tag_detail, result);
      return 0;
   }

   //-//say("tag_find_tag("class_name"): ------FAILED [nStatus="nStatus"] = " :+get_message(nStatus) " FAILED -----------");
   return nStatus;
}

static int get_member_detail(_str class_name, _str member_name, int tag_detail, var result) 
{
   nStatus := 0;
   tag_filename := "";
   tag_files := project_tags_filenamea();
   foreach(tag_filename in tag_files) {

      nStatus = tag_read_db(tag_filename);
      if ( nStatus < 0) continue;

      nStatus = tag_find_equal(member_name, false, class_name);
      if ( nStatus < 0 ) {
         tag_reset_find_tag();
         continue;
      }

      tag_get_detail(tag_detail, result);
      tag_reset_find_tag();
      return 0;
   }

   return nStatus;
}

_str get_assoc_class_file_name(_str class_filename, _str class_name, typeless& tag_files)
{
   _str normalized;
   tag_db_name := "";
   orig_tag_file := tag_current_db();
   _str tag_file = find_class_in_tag_file(class_name, class_name, normalized, true, tag_files);

   if (tag_file == "") {
      tag_file = find_class_in_tag_file(class_name, class_name, normalized, true, tag_files, true);
   }
   if (tag_file != "") {
      tag_db_name = tag_file;
   }

   int status = tag_read_db(tag_db_name);
   if (status < 0) {
      tag_read_db(orig_tag_file);
      return "";
   }

   int nStatus = find_class_struct(class_name);
   if ( nStatus < 0 ) {
      tag_read_db(orig_tag_file);
      return "";
   }
   nStatus = tag_find_in_class(class_name);
   while ( nStatus >= 0 ) {
      type_name := tag_name := file_name := "";

      tag_get_detail(VS_TAGDETAIL_type, type_name);
      tag_get_detail(VS_TAGDETAIL_name, tag_name);
      tag_get_detail(VS_TAGDETAIL_file_name, file_name);

      //-//say("tag="tag_name" type_name="type_name" file_name="file_name);
      if ( class_filename != file_name ) {
         tag_reset_find_in_class();
         tag_read_db(orig_tag_file);
         return file_name;
      }
      nStatus = tag_next_in_class();
   }
   tag_reset_find_in_class();
   tag_read_db(orig_tag_file);
   return class_filename;
}

static void swap_array_elements( typeless (&array)[], int a, int b )
{
   if ( a < 0 || a >= array._length() || b < 0 || b >= array._length() ) {
      return;
   }

   typeless vA = array[a];
   array[a] = array[b];
   array[b] = vA;
}

_str tag_name_to_cpp_name(_str tag_name)
{
   _str _tag_name=tag_name;
   cpp_name := "";

   for (;;) {
      part := "";
      parse tag_name with part '/|:+','U' tag_name;
      if ( part == "" ) {
         break;
      }
      if ( cpp_name :== "" ) {
         cpp_name = part;
      } else {
         cpp_name :+= "::" :+ part;
      }
   }
   //-//say("tag_name_to_cpp_name: tag_name=\""_tag_name"\"cpp_name=\""cpp_name"\"");
   return cpp_name;
}

/**
 * Do everything needed to be ready to start refactoring
 *
 * F if cancelled, T to continue
 */
bool refactor_init(bool requireWorkspace = true, bool requireConfig = true, _str msg = "Refactoring...")
{
   if (!_haveRefactoring()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return false;
   }

   if (!isEclipsePlugin()) {
      // make sure there is an open workspace
      if (requireWorkspace && _workspace_filename == "") {
         _message_box("Refactoring requires a workspace and project.");
         return false;
      }
   }

   // Check refactoring config.  Canceled if return value is an empty string
   if (requireConfig) {
      if ( refactor_check_config() == COMMAND_CANCELLED_RC ) return false;
   }

   // prompt to save modified files
   if (!saveFilesBeforeRefactoring()) return false;

   // Force the current context to be up-to-date, even for large files
   _UpdateContextAndTokens(true,true);

   if (msg != "") { // Clear the output toolbar
      _SccDisplayOutput(msg, true);
   }
   return true;
}

///////////////////////////////////////////////////////////////////////////////

/**
 * Warn them if C/C++ refactoring is disabled. 
 *  
 * @return 'true' if refactoring is disabled. 
 */
static bool refactor_warn_if_disabled()
{
   if (!_haveRefactoring()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return true;
   }
   if (def_disable_cpp_refactoring) {
      _message_box("C/C++ Refactoring is disabled by default.\n":+
                   "\n":+
                   "To enable it, go to Macro > Set Macro Variable and set ":+
                   "'def_disable_cpp_refactoring' to '0'.");
   }
   return def_disable_cpp_refactoring;
}

/**
 * Parse the current file
 */
_command int refactor_parse(_str quiet="") name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if (!refactor_init(false)) return COMMAND_CANCELLED_RC;

   // add the files
   _str filename = p_buf_name;

   // display the refactoring configuration test form
   response := "";
   if (quiet == "") {
      response = show("-modal -xy _refactor_test_parser_form", filename );
      if (response != "ok" && response != "pp") {
         return COMMAND_CANCELLED_RC;
      }
   }

   // begin the refactoring transaction
   handle := refactor_begin_transaction(/*"refactor_parse"*/);
   if (handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle));
      return handle;
   }

   // add the single file to the project
   int status = refactor_add_project_file(handle, filename, false);
   if (status < 0) {
      refactor_cancel_transaction(handle);
      return status;
   }

   // parse the files
   show_cancel_form("Refactoring", "", true, true);
   if (response == "pp") {
      new_file("C");
      name_file(_strip_filename(filename, "e"):+".i");
      status = refactor_c_preprocess(handle, p_window_id, true);
   } else {
      status = refactor_c_parse(handle, 0);
   }
   close_cancel_form(cancel_form_wid());

   // cancel the transaction
   numErrors := refactor_count_errors(handle, "");
   refactor_cancel_transaction(handle);
   clear_message();
   if (status == COMMAND_CANCELLED_RC) {
      _SccDisplayOutput("Cancelled.");
      return status;
   }
   if (status < 0) {
      _message_box(get_message(VSRC_VSREFACTOR_PARSING_FAILURE_1A,numErrors));
      return status;
   }

   // cancel the transaction
   _SccDisplayOutput("Done.");
   return status;
}

/**
 * Run refactor-parse on all source files in a project
 * <p>
 * Syntax: refactor-parse-all &lt;project.vpj&gt; [config] [offset]
 */
_command int refactor_parse_project(_str options = "") name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if(strieq(options, "help")) {
      message("refactor-parse-all <project.vpj> [config] [starting-offset]");
      return 0;
   }

   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if(!refactor_init()) return 0;

   // record starting time
   _str startTime = _time('B');

   // get list of files in the project
   _str workspaceName = _workspace_filename;
   _str projectName = _project_name;
   config := GetCurrentConfigName(projectName);
   startOffset := 0;

   for(;;) {
      opt := "";
      parse options with opt options;
      if(opt == "") break;

      if(_file_eq(_get_extension(opt, true), PRJ_FILE_EXT)) {
         projectName = opt;
      } else if(isnumber(opt)) {
         startOffset = (int)opt;
      } else {
         config = opt;
      }
   }

   // find the project in the workspace
   if(!file_exists(_AbsoluteToWorkspace(projectName, workspaceName))) {
      justProjectName := _strip_filename(projectName, "P");
      _str projectFileList[] = null;
      _WorkspaceGet_ProjectFiles(gWorkspaceHandle, projectFileList/*, GetCurrentConfigName(projectName)*/);
      int j, o = projectFileList._length();
      for(j = 0; j < o; j++) {
         _str curProject = projectFileList[j];
         if(curProject == "") continue;

         if(_file_eq(_strip_filename(curProject, "P"), justProjectName)) {
            projectName = _AbsoluteToWorkspace(curProject, workspaceName);
            break;
         }
      }
   }

   // make sure project was found
   if(!file_exists(projectName)) {
      message("Unable to find project");
      return -1;
   }

   // open the project
   int projectHandle = _ProjectHandle(projectName);
   if(projectHandle < 0) return projectHandle;

   // Get the current configuration name for this project
   configName := GetCurrentConfigName(projectName);

   // get list of files
   _str fileList[] = null;
   _getProjectFiles(workspaceName, projectName, fileList, 1);

   // begin the refactoring transaction
   handle := refactor_begin_transaction(/*"refactor_parse"*/);
   if(handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle));
      return handle;
   }

   status := 0;
   int i, n = fileList._length();
   for(i = 0; i < n; i++) {
      // throw it out if it is not a cpp file
      _str filename = fileList[i];
      if(filename == "") continue;
      filename = _parse_project_command(filename, "", projectName, "");
      if (!file_exists(filename)) {
         _SccDisplayOutput("NotFound: \"" filename "\"");
         continue;
      }

      // see if it is in the requested config
      int node = _ProjectGet_FileNode(projectHandle, _RelativeToProject(filename, projectName));
      if(node >= 0) {
         _str configList = _xmlcfg_get_attribute(projectHandle, node, "C");
         if(configList != "" && pos("\"" config "\"", configList, 1, "I") == 0) {
            _SccDisplayOutput("NotInCfg: \"" filename "\"");
            continue;
         }
      }

      if(i < startOffset) {
         _SccDisplayOutput("Skipping: \"" filename "\"");
         continue;
      }

      // only deal with c files
      _str ext = _get_extension(filename);
      if(_first_char(ext) != "c") {
         continue;
      }

      // add the file to the transaction
      status = refactor_add_project_file(handle, filename, false);
      if (status < 0) {
         refactor_cancel_transaction(handle);
         return status;
      }
   }

   // parse the files
   show_cancel_form("Refactoring", "", true, true);
   status = refactor_c_parse(handle, 0);
   close_cancel_form(cancel_form_wid());

   // simply cancel out the transaction
   numErrors := refactor_count_errors(handle, "");
   refactor_cancel_transaction(handle);
   clear_message();
   if (status == COMMAND_CANCELLED_RC) {
      _SccDisplayOutput("Cancelled.");
      return status;
   }

   // calculate elapsed time
   _str endTime = _time('B');
   int milliseconds = (int)endTime - (int)startTime;
   int seconds = milliseconds intdiv 1000;
   int minutes = seconds intdiv 60;
   seconds = seconds % 60;

   _str minutesStr = minutes;
   if(length(minutesStr) < 2) {
      minutesStr = "0" minutesStr;
   }
   _str secondsStr = seconds;
   if(length(secondsStr) < 2) {
      secondsStr = "0" secondsStr;
   }

   _SccDisplayOutput("Time: " minutesStr ":" secondsStr);

   if(status < 0) {
      _message_box(get_message(VSRC_VSREFACTOR_PARSING_FAILURE_1A,numErrors));
      return status;
   }
   _SccDisplayOutput("Done.");
   return status;
}

/**
 * Rename a symbol and adjust all references.
 * <p>
 *
 * @categories Refactoring_Functions
 */
_command int refactor_rename() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   // get browse information for the tag under the symbol
   status := tag_get_browse_info("", auto cm);
   if (status == COMMAND_CANCELLED_RC) return status;
   if (status < 0) {
      //_message_box("Rename failed: ":+get_message(status), "Rename Refactoring");
      return status;
   }

   // tag_get_browse_info() returns information about where the
   // symbol is defined, not necessarily the location where the cursor
   // is now.  therefore, the current file and seek position should
   // also be passed to refactor_rename_symbol()
   symbolName := "";
   i := seekPosition := 0;
   if (!getSymbolInfoAtCursor(symbolName, seekPosition)) {
//      cm.member_name = symbolName;
//      cm.file_name = p_buf_name;
//      cm.seekpos = seekPosition;
//      cm.line_no = p_RLine;
   }

   // call common rename function
   return refactor_rename_symbol(cm, "", p_buf_name, seekPosition);
}


int _OnUpdate_refactor_rename(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   int clex_color = _clex_find(0,'g');
   if (clex_color!=CFG_WINDOW_TEXT && clex_color!=CFG_LIBRARY_SYMBOL && clex_color!=CFG_USER_DEFINED && clex_color!=CFG_FUNCTION) {
     return(MF_GRAYED);
   }

   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

//////////////////////////////////////////////////////////////////////////////
// Add the children (classes that derive from 'class_name') to the
// inheritance tree browser).  tag databases and file names are resolved
// allowing us to display parents that are in other tag files.
// This function is recursive, but limited to CB_MAX_INHERITANCE_DEPTH levels.
// p_window_id must be the inheritance tree control (left tree of window).
//
// Depth of 2 means only get direct descendents which will include the current class and it's direct children.
static void get_children_of( _str class_name, 
                             _str tag_db_name, 
                             typeless &tag_files, 
                             _str child_file_name,
                             struct VS_TAG_BROWSE_INFO (&children)[],
                             _str (&all_children)[],
                             _str function_name,
                             int inheritance_depth=1000,
                             typeless &visited=null, int depth=0)
{
   static bool canceled;
   process_events( canceled );

   if ( gcanceled_finding_children == true )
      return;

   // what tag file is this class really in?
   normalized := "";
   tag_file := find_class_in_tag_file(class_name, class_name, normalized, true, tag_files);
   if (tag_file == "") {
      tag_file = find_class_in_tag_file(class_name, class_name, normalized, true, tag_files, true);
   }
   if (tag_file != "") {
      tag_db_name = tag_file;
   }
   status := tag_read_db(tag_db_name);
   if (status < 0) {
      return;
   }

   // need to parse out our outer class name
   outername  := "";
   membername := class_name;
   if (pos('(.*):(.*)', class_name, 1, 'U')) {
      outername  = substr(class_name, pos('S0'), pos('0'));
      membername = substr(class_name, pos('S1'), pos('1'));
   } else if (pos(VS_TAGSEPARATOR_package, class_name)) {
      parse class_name with outername (VS_TAGSEPARATOR_package) membername;
   }

   // See if we start with a typedef
   status=tag_find_tag(membername, "typedef", outername);

   // Keep going until non-typedef is found
   while ( status == 0 ) {
      tag_get_detail(VS_TAGDETAIL_return_only, membername);
      class_name = membername;
      status=tag_find_tag(membername, "typedef", outername);
   }
   tag_reset_find_tag();

   // try to look up file_name and type_name for class
   tag_init_tag_browse_info(auto cm);
   status=tag_find_tag(membername, "class", outername);
   if (status==0) {
      tag_get_tag_browse_info(cm);
   } else {
      status=tag_find_tag(membername, "struct", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
      } else {
         status=tag_find_tag(membername, "interface", outername);
         if (status==0) {
            tag_get_tag_browse_info(cm);
         }
      }
   }
   tag_reset_find_tag();

   cm.seekpos = 0;
   cm.member_name  = class_name;
   cm.class_name   = class_name;
   cm.tag_database = tag_db_name;
   tag_complete_browse_info( cm );

   // Only add children that have the function symbol we are renaming
   // as a member unless function_name is blank in which we add all.
   if((function_name == "") || (tag_find_tag(function_name,"proto",membername) == 0) ||
         (tag_find_tag(function_name,"proc",membername) == 0) ||
         (tag_find_tag(function_name,"func",membername) == 0)) {
      children :+= cm;
   }
   tag_reset_find_tag();

   all_children :+= class_name;

   // Process the symbol in relation to each class

   // now insert derived classes
   orig_tag_file := tag_current_db();

   // get all the classes that could maybe possibly derive from this class
   _str candidates[];
   candidate_class := "";
   parents := "";
   status=tag_find_class(candidate_class);
   while (!status) {
      tag_get_inheritance(candidate_class,parents);
      if (pos("[;.:/]"membername"(<[^;]@>|);",';'parents';',1,'ir')) {
         candidates :+= candidate_class;
      }
      status=tag_next_class(candidate_class);
   }
   tag_reset_find_class();

   // verify that they derive directly from that class.
   inheritance_depth--;
   if (inheritance_depth <= 0) {
      return;
   }

   for (i:=0; i<candidates._length(); ++i) {
      tag_read_db(orig_tag_file);
      tag_find_class(auto dummy,candidates[i]);

      if (tag_is_parent_class(class_name,candidates[i],tag_files,true,true,null,visited,depth+1)) {
         get_children_of(candidates[i], tag_db_name, tag_files, cm.file_name, children, all_children, function_name, inheritance_depth, visited, depth+1);
      }
   }

   tag_reset_find_class();
   tag_read_db(orig_tag_file);
}

// Get all of the parents of this class. include the class itself
void get_parents( _str class_name, _str tag_db_name, typeless &tag_files, _str parent_file_name,
                  struct VS_TAG_BROWSE_INFO (&parents)[] )
{
   // what tag file is this class really in?
   if (tag_db_name != "") tag_read_db(tag_db_name);
   normalized := "";
   tag_file := find_class_in_tag_file(class_name, class_name, normalized, true, tag_files);
   if (tag_file == "") {
      tag_file = find_class_in_tag_file(class_name, class_name, normalized, true, tag_files, true);
   }
   if (tag_file != "") {
      tag_db_name = tag_file;
   }
   status := tag_read_db(tag_db_name);
   if (status < 0) {
      return;
   }

   // need to parse out our outer class name
   outername  := "";
   membername := class_name;
   if (pos('(.*):(.*)', class_name, 1, 'U')) {
      outername  = substr(class_name, pos('S0'), pos('0'));
      membername = substr(class_name, pos('S1'), pos('1'));
   } else if (pos(VS_TAGSEPARATOR_package, class_name)) {
      parse class_name with outername VS_TAGSEPARATOR_package membername;
   }

   // try to look up file_name and type_name for class
   tag_init_tag_browse_info(auto cm);

   // See if we start with a typedef
   status=tag_find_tag(membername, "typedef", outername);

   // Keep going until non-typedef is found
   while ( status == 0 ) {
      tag_get_detail(VS_TAGDETAIL_return_only, membername);
      class_name = membername;
      status=tag_find_tag(membername, "typedef", outername);
   }
   tag_reset_find_tag();

   status=tag_find_tag(membername, "class", outername);
   if (status==0) {
      tag_get_tag_browse_info(cm);
   } else {
      status=tag_find_tag(membername, "struct", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
      } else {
         status=tag_find_tag(membername, "interface", outername);
         if (status==0) {
            tag_get_tag_browse_info(cm);
         }
      }
   }
   tag_reset_find_tag();

   cm.member_name   = class_name;
   cm.class_name    = class_name;
   cm.tag_database  = tag_db_name;

   tag_complete_browse_info(cm);
   cm.tag_database  = tag_db_name;
   tag_get_tagfile_browse_info(cm);

   parents :+= cm;

   if (cm.class_parents == "") {
      tag_get_inheritance( class_name, cm.class_parents );
   }
   class_parents := cm.class_parents;
   while (class_parents != "") {
      parse class_parents with auto parent_class_name VS_TAGSEPARATOR_parents class_parents;
      parse parent_class_name with parent_class_name "<" .;

      if ( parent_class_name != "" ) {
         get_parents(parent_class_name, tag_db_name, tag_files, cm.file_name, parents);
      }
   }
}

int correct_class_seek_pos( _str file_name, _str class_name, int lineno )
{
   seekpos := 0;
   int temp_view_id,orig_view_id;
   int status = _open_temp_view(file_name,temp_view_id,orig_view_id);

   if (status) {
      return seekpos;
   }

   _GoToROffset(seekpos);
   p_line = lineno;

   start_col := 0;

   // Make sure to check multiple lines

   _str curword = cur_word(start_col, "", false, true );
   while ((curword!="")&&(curword!=class_name)) {
      c_next_sym();
      curword = c_get_syminfo();
   }

   if ( curword == class_name ) {
      seekpos = (int)_QROffset()-length(class_name);
   }
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   return seekpos;
}

int refactor_rename_symbol(struct VS_TAG_BROWSE_INFO cm, _str newName = "", _str filename = "",
                           long beginSeekPos = 0, long endSeekPos = 0,
                           VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   i := j := k := flags := 0;

   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if (!refactor_init()) {
      return COMMAND_CANCELLED_RC;
   }
   // for classes, constructors, and destructors, the entire class should be
   // renamed as well as all constructors and the destructor.  therefore, go
   // ahead and drop the leading ~ if present
   _maybe_strip(cm.member_name, '~', stripFromFront:true);

   // filename and the seek positions are the location that the refactoring
   // was triggered from if started from the editor control.  this information
   // will be passed to the refactoring engine to make sure the exact symbol is
   // found.  if these values are not set, use the information that was passed
   // in the tag browse info
   if (filename == "") {
      filename = cm.file_name;
      beginSeekPos = cm.seekpos;
      endSeekPos = cm.scope_seekpos;
   }

   tag_update_context();

   // get list of files that reference the symbol
   _str fileList[] = null;
   int status = tag_get_occurrence_file_list(cm, fileList, 10, true, SE_TAG_FILTER_ANYTHING, visited);
   if (status == COMMAND_CANCELLED_RC) {
      return status;
   } else if(status < 0){
      _message_box("Rename failed. error=":+get_message(status), "Rename Refactoring");
      return status;
   }

   // Get the tag file for the current project or current workspace
   project_tagfile := project_tags_filename_only();
   if (project_tagfile == "") {
      project_tagfile = workspace_tags_filename_only();
   }

   int nStatus = tag_read_db(project_tagfile);
   if ( nStatus < 0) {
      _message_box("tag_read_db("project_tagfile") failed. error=":+get_message(nStatus));
      return nStatus;
   }

   int isFunction,isClassFunction;
   if(tag_tree_type_is_func(cm.type_name)) {
      isFunction = 1;
      if ( cm.class_name != "" ) {
         isClassFunction = 1;
      } else {
         isClassFunction = 0;
      }
   } else {
      isFunction = 0;
      isClassFunction = 0;
   }

//   say("isClassFunction = "isClassFunction);

   // Get all parents and children of original symbol. Remove duplicates
   // Go through all symbols that have been found and see if any of their parents
   //    are any of the original list of classes.

   // rename the symbol
   show_cancel_form("Refactoring", "Searching for files that contain the symbol to rename", false, false);

   _str lang = _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);

   typeless tag_files = tags_filenamea(lang);
   _str all_classes[]=null;
   struct VS_TAG_BROWSE_INFO all_classes_with_function[]=null;
   struct VS_TAG_BROWSE_INFO mother_of_all_classes=null;
   if ( isFunction && cm.class_name != "" ) {

      int wid = show("_refactor_finding_children_form");

      // Assumes that parent_classes comes back in order from highest level class to lowest level
      // say A derives from B and B derives from C the order would be:
      // A,B,C
      struct VS_TAG_BROWSE_INFO parent_classes[]=null;
      get_parents( cm.class_name, cm.tag_database, tag_files, cm.file_name, parent_classes );

      // Make sure the project's tag database is open. get_parents may have left
      // some other tagdatabase open.
      nStatus = tag_read_db(project_tagfile);
      if ( nStatus < 0) {
         _message_box("tag_read_db("project_tagfile") failed. error=":+get_message(nStatus), "Rename Refactoring");
         return nStatus;
      }

      // Go from back to front looking for first instance of symbol name in the parent classes.
      for ( i=parent_classes._length()-1; i >= 0; i-- ) {

         if ( ( tag_find_tag(cm.member_name, "proto", parent_classes[i].member_name ) == 0 ) ||
              ( tag_find_tag(cm.member_name, "func", parent_classes[i].member_name ) == 0 ) ||
              ( tag_find_tag(cm.member_name, "procproto", parent_classes[i].member_name ) == 0 ) ||
              ( tag_find_tag(cm.member_name, "constr", parent_classes[i].member_name ) == 0 ) ||
              ( tag_find_tag(cm.member_name, "destr", parent_classes[i].member_name ) == 0 ) ||
              ( tag_find_tag(cm.member_name, "proc", parent_classes[i].member_name ) == 0 ) ) {
            mother_of_all_classes=parent_classes[i];
            break;
         }
      }
      tag_reset_find_tag();

      // Should not happen since this means none of the parents or the class itself contains
      // the symbol name.
      if ( mother_of_all_classes == null ) {
         _message_box("Rename failed: Could not find function definition in any classes", "Rename Refactoring");
         close_cancel_form(cancel_form_wid());
         wid._delete_window();
         return -1;
      } else {
         get_children_of( mother_of_all_classes.member_name, mother_of_all_classes.tag_database,
                          tag_files, mother_of_all_classes.file_name, all_classes_with_function,
                          all_classes, cm.member_name,
                          inheritance_depth:1000, visited, 1);
      }

      if ( gcanceled_finding_children == true ) {
         return COMMAND_CANCELLED_RC;
      }
      wid._delete_window();
   }

   // begin the refactoring transaction
   handle := refactor_begin_transaction();
   if (handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle), "Rename Refactoring");
      return handle;
   }

   // build flags
   if(cm.type_name == "define") {
      flags |= VSREFACTOR_RENAME_DEFINE;
   }

   if ( isClassFunction ) {
      // get list of files that reference the symbol
      fileList = null;
      status = tag_get_occurrence_file_list_restrict_to_classes(cm, fileList, all_classes,
                                                                tag_files, 10, visited );

      if (status == COMMAND_CANCELLED_RC) {
         refactor_cancel_transaction(handle);
         return status;
      } else if (status < 0) {
         // error
         _message_box("Failed getting occurrence file list:  ":+get_message(status), "Rename Refactoring");
         refactor_cancel_transaction(handle);
         return status;
      }
   }

   close_cancel_form(cancel_form_wid());

   // if no files in list, this is a local variable so just add the current buffer
   if (!_inarray(filename, fileList)) {
      fileList[fileList._length()] = filename;
   }

   // add the files
//   say("Files found = "fileList._length());
   n := fileList._length();
   for (i = 0; i < n; i++) {
//      say(i" "fileList[i]);
      status = refactor_add_project_file(handle, fileList[i]);
      if (status < 0) {
         _message_box("Failed adding project file '" :+ fileList[i] :+ "':  ":+get_message(status), "Rename Refactoring");
         refactor_cancel_transaction(handle);
         return status;
      }
   }

   _str results = show("-modal _refactor_rename_form", cm, cm.member_name, beginSeekPos, endSeekPos, filename,
                       isFunction, isClassFunction );

   // Canceled rename
   if ( results == "" ) {
      refactor_cancel_transaction(handle);
      return 0;
   }

   _str sFlags;
   parse results with newName (PATHSEP) sFlags;

   flags |= (int)sFlags;

   // rename the symbol
   show_cancel_form("Refactoring", "", true, true);


   if( isClassFunction && ( ( flags & VSREFACTOR_RENAME_VIRTUAL_METHOD_IN_BASE_CLASSES ) || 
                            ( flags & VSREFACTOR_RENAME_OVERLOADED_METHODS ) ) ){
      // When the last two parameters are valid then rename will lookup the class
      // defined by those two values and then lookup the symbol name in that class and do the rename.
      for ( i = 0 ; i < all_classes_with_function._length( ) ; i++ ) {
         // Adjust seekpos so that it is on the class name rather than the keyword class or struct.
         all_classes_with_function[i].seekpos = correct_class_seek_pos( all_classes_with_function[i].file_name,
                                                                        all_classes_with_function[i].member_name,
                                                                        all_classes_with_function[i].line_no );

         refactor_c_add_class_info( handle,  all_classes_with_function[i].member_name,
                                    all_classes_with_function[i].file_name,
                                    (int)all_classes_with_function[i].seekpos,
                                    (int)all_classes_with_function[i].end_seekpos );
      }
   }

   // Rename the symbol under the cursor specified by cm.member_name, filename and beginSeekPos,endSeekPos
   status = refactor_c_rename(handle, filename, cm.member_name, (int)beginSeekPos, (int)endSeekPos, newName, flags );

   if (status < 0) {
      if(status != COMMAND_CANCELLED_RC) {
         _message_box("Failed renaming symbol '" :+ cm.member_name :+ "':  ":+get_message(status, newName), "Rename Refactoring");
      }
      close_cancel_form(cancel_form_wid());
      refactor_cancel_transaction(handle);
      return status;
   }

   close_cancel_form(cancel_form_wid());

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, status, "Failed to rename symbol.", "Rename "cm.member_name" => "newName, filename);

   return 0;
}

/**
 * Replace a literal constant with a constant.
 * <p>
 */
int refactor_replace_literal_symbol( _str filename, _str literalName, _str constantName, int flags )
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   // begin the refactoring transaction
   handle := refactor_begin_transaction(/*"Replace Literal"*/);
   if (handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle));
      return handle;
   }

   // figure out which project includes this file
   int status = refactor_add_project_file(handle, filename);
   if (status < 0) {
      refactor_cancel_transaction(handle);
      return status;
   }

   // extract the method
   show_cancel_form("Refactoring", "", true, true);
   status = refactor_c_replace_literal(handle, filename, literalName, constantName, flags);
   close_cancel_form(cancel_form_wid());

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, status, "Failed to replace literal.", "Replace Literal", filename);
   return status;
}

/**
 * Replace a literal (string or number) constant with a constant.
 * <p>
 *
 * @categories Refactoring_Functions
 */
_command int refactor_replace_literal() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   _str newName;
   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   long startSeekPos,endSeekPos;

   _str literalName = findLiteralAtCursor( startSeekPos, endSeekPos );

   if ( literalName == "" ) {
      _message_box("Replace Literal requires a string or number literal.");
      return COMMAND_CANCELLED_RC;
   }

   _str result = show("-modal _refactor_replace_literal_form", p_buf_name, literalName );

   // Canceled rename
   if ( result == "" ) {
      return 0;
   }

   _str sFlags;
   int flags;
   parse result with newName (PATHSEP) sFlags;

   flags = (int)sFlags;

   return refactor_replace_literal_symbol( p_buf_name, literalName, newName, flags );
}

int _OnUpdate_refactor_replace_literal(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   int startSeek,endSeek;
   _str literal = target_wid.findLiteralAtCursor(startSeek,endSeek);

   if (target_wid._clex_find(0,'g')!=CFG_NUMBER && target_wid._clex_find(0,'g')!=CFG_STRING) {
      return MF_GRAYED;
   }

   return _OnUpdateRefactoringCommand(cmdui, target_wid, command, true);
}

// simplified version of select_text from surround_with
void get_limited_selection(int &start_pos,int &end_pos)
{
   typeless cursor_pos;
   save_pos(cursor_pos);

   lock_selection();
   begin_select();
   if (_select_type():=="LINE") {
      begin_line();
   }

   first_column := p_col;
   _first_non_blank();

   // if the selection does not start at the beginning of a line
   if (p_col < first_column) {
      // use the start of the selection
      begin_select();
   }

   start_pos=(int)_QROffset();

   // find the end position
   end_select();  // go to the last line of the selection

   _first_non_blank();
   first_column = p_col;
   end_select();
   if (_select_type():=="LINE") {
      end_line();
   }

   while (first_column >= p_col) {
      // there is nothing selected on this line but whitespace
      //   keep looking for end of selected text
      up();
      _first_non_blank();
      first_column = p_col;
      end_line();
   }

   end_pos=(int)_QROffset();

   restore_pos(cursor_pos);
}

/**
 * Extract a complete method from a fragment of code.
 * Grabs the current selection.
 * <p>
 *
 * @categories Refactoring_Functions
 */
_command refactor_extract_method() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   // This method requires a selection, but not a block selection
   if ( ! select_active() ) {
      _message_box("Extract Method requires a selection.");
      return COMMAND_CANCELLED_RC;
   }

   int start_pos;
   int end_pos;
   get_limited_selection(start_pos,end_pos);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // get browse information for the tag under the symbol
   _UpdateContextAndTokens(true);

   context_name := "";
   context_type := 0;
   int context_id = tag_current_context();
   while (context_id > 0) {
      // get information about this context item, is it the proc?
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, context_type);
      tag_get_detail2(VS_TAGDETAIL_context_name, context_id, context_name);
      if (tag_tree_type_is_func(context_type) && context_type!="proto" && context_type!="procproto") {
         break;
      }
      // go up one level
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
   }
   if (context_name == "") {
      _message_box("Selection is not within a function body.");
      return COMMAND_CANCELLED_RC;
   }

   // begin the refactoring transaction
   handle := refactor_begin_transaction(/*"Extract Method"*/);
   if (handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle));
      return handle;
   }

   // add the files
   _str filename = p_buf_name;

   // try adding the file (and parsing it)
   int status = refactor_add_project_file(handle, filename);
   if (status < 0) {
      refactor_cancel_transaction(handle);
      return status;
   }

   int flags = get_formatting_flags( _Filename2LangId( filename ) );

   // extract the method
   paramInfo := "";
   returnType := "";
   typeless createMethodCall=0;
   show_cancel_form("Refactoring", "", true, true);
   status = refactor_c_extract_method(handle, p_buf_name, context_name, createMethodCall,
                                      start_pos, end_pos, returnType, paramInfo, flags, p_SyntaxIndent);
   close_cancel_form(cancel_form_wid());
   if (status == COMMAND_CANCELLED_RC) {
      refactor_cancel_transaction(handle);
      clear_message();
      return status;
   }
   if (status < 0) {
      refactor_cancel_transaction(handle);
      if (status == VSRC_VSREFACTOR_PARSING_FAILURE_1A) {
         numErrors := refactor_count_errors(handle, "");
         _message_box("Failed to extract method:\n\n":+get_message(status,numErrors));
      } else {
         _message_box("Failed to extract method:\n\n":+get_message(status));
      }
      return status;
   }

   // prompt them so they can rename, reorder, etc
   paramInfo = show("-modal -xy _refactor_extract_method_form", context_name"_extracted", returnType, paramInfo, createMethodCall);
   if (paramInfo == "") {
      refactor_cancel_transaction(handle);
      return COMMAND_CANCELLED_RC;
   }

   _str beautify_new_function="0", create_javadoc="0";
   parse paramInfo with context_name "\n" createMethodCall "\n" beautify_new_function "\n" create_javadoc "\n" paramInfo;

   // ok, now rename the objects and modify the parse tree appropriately
   mou_hour_glass(true);
   status = refactor_c_extract_method_finish(handle, p_buf_name, context_name, createMethodCall, paramInfo, "", flags, p_SyntaxIndent);
   mou_hour_glass(false);

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, status, "Failed to extract method.", "Extract Method ":+context_name, p_buf_name);
   return status;
}


int _OnUpdateRefactoringCommand(CMDUI &cmdui,int target_wid,_str command,bool allowString=false,bool allowNonCpp=false)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   lang := target_wid.p_LangId;
   if (!_LanguageInheritsFrom('c',lang) && !allowNonCpp) {
      return MF_GRAYED;
   }
   if (!target_wid._istagging_supported(lang)) {
      return MF_GRAYED;
   }
   if (_clex_find(0,'g')==CFG_COMMENT) {
      return(MF_GRAYED);
   }
   if (!allowString && _clex_find(0,'g')==CFG_STRING) {
      return(MF_GRAYED);
   }
   return MF_ENABLED;
}
int _OnUpdate_refactor_extract_method(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   lang := target_wid.p_LangId;
   if (!_LanguageInheritsFrom("c",lang)) {
      return MF_GRAYED;
   }
   if ( ! select_active() || _select_type()=="BLOCK" ) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}

/**
 * Modify the parameter list of a function and update all references.
 * <p>
 *
 */

int _OnUpdate_refactor_modify_params(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   int clex_color = _clex_find(0,'g');
   if (clex_color!=CFG_FUNCTION && clex_color!=CFG_IDENTIFIER) {
     return(MF_GRAYED);
   }

   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

/**
 * Modify the parameter list of a function and update all references.
 * <p>
 *
 * @categories Refactoring_Functions
 */
_command int refactor_modify_params() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

/*
   Need to pass the location of the function definition(function body) into 
   refactor_c_modify_params_get_info so that parameters can be correctly checked for
   references in the function body.
*/
   status := tag_get_browse_info("", auto cm);
   if (status == COMMAND_CANCELLED_RC) return status;
   if(status < 0) {
      //_message_box( "Modify parameters failed: " :+ get_message(VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A,cm.member_name));
      return VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A;
   }

   tag_complete_browse_info(cm);
   tag_get_tagfile_browse_info(cm);

   if(tag_tree_type_is_func(cm.type_name) == 0) {
      _message_box( "Modify parameters failed: " :+ get_message(VSRC_VSREFACTOR_SYMBOL_IS_NOT_A_FUNCTION_1A,cm.member_name));
      return VSRC_VSREFACTOR_SYMBOL_IS_NOT_A_FUNCTION_1A;
   }

   status = refactor_start_modify_params(cm, (int)cm.seekpos);
   if(status < 0 && status != COMMAND_CANCELLED_RC) {
      _message_box("Modify parameters failed:\n\n":+get_message(status, cm.member_name), "Modify Parameters");
   }
   return status;
}

int refactor_start_modify_params(struct VS_TAG_BROWSE_INFO cm, int beginSeekPos = 0, int endSeekPos = 0)
{
   // If this symbol is not a function that bail.
   if(!tag_tree_type_is_func(cm.type_name) || (cm.type_name == "")) {
      return 0;
   }

   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   int i, status;
   // init refactoring operations
   if(!refactor_init()) return COMMAND_CANCELLED_RC;

   // begin the refactoring transaction
   handle := refactor_begin_transaction(/*"Create Standard Methods"*/);
   if(handle < 0) {
      return handle;
   }

   _str fileList[];

   // get list of files that reference the symbol
   VS_TAG_RETURN_TYPE visited:[];
   status = tag_get_occurrence_file_list(cm, fileList, 10, false, SE_TAG_FILTER_ANYTHING, visited);
   if(status == COMMAND_CANCELLED_RC) {
      return 0;
   }

   if(fileList._length()==0) {
      fileList[fileList._length()] = cm.file_name;
   }

   isClassFunction := false;
   if(cm.class_name != "") {
      isClassFunction = true;
   } 

   if( isClassFunction ) {
      _str lang = _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);
      typeless tag_files = tags_filenamea(lang);
      struct VS_TAG_BROWSE_INFO all_classes_with_function[]=null;
      _str all_classes[]=null;
      int result = get_all_classes_with_function(cm, lang, all_classes_with_function, all_classes, visited);

      if(result==-1) {
         return VSRC_VSREFACTOR_INTERNAL_ERROR;
      }
      // get list of files that reference the symbol
      fileList = null;
      status = tag_get_occurrence_file_list_restrict_to_classes(cm, fileList, all_classes,
                                                            tag_files, 10, visited );
      if(status == COMMAND_CANCELLED_RC) {
         refactor_cancel_transaction(handle);
         return status;
      } else if(status < 0) {
         // error
         refactor_cancel_transaction(handle);
         return status;
      }

      // When the last two parameters are valid then rename will lookup the class
      // defined by those two values and then lookup the symbol name in that class and do the rename.
      for( i = 0 ; i < all_classes_with_function._length( ) ; i++ ) {
         // Adjust seekpos so that it is on the class name rather than the keyword class or struct.
         all_classes_with_function[i].seekpos = correct_class_seek_pos( all_classes_with_function[i].file_name,
                                                                        all_classes_with_function[i].member_name,
                                                                        all_classes_with_function[i].line_no );
   
         refactor_c_add_class_info( handle,  all_classes_with_function[i].member_name,
                                             all_classes_with_function[i].file_name,
                                             (int)all_classes_with_function[i].seekpos,
                                             (int)all_classes_with_function[i].end_seekpos );
      }      
   }   

   // add the files
   n := fileList._length();
   for(i = 0; i < n; i++) {
      status = refactor_add_project_file(handle, fileList[i]);
      if(status < 0) {
         refactor_cancel_transaction(handle);
         return status;
      }
   }

   _str paramInfo,newParamInfo;
   numParameters := 0;
   status = refactor_c_modify_params_get_info(handle, cm.member_name, cm.file_name, (int)cm.seekpos, (int)cm.end_seekpos,       
                              paramInfo);

   if(status < 0) {
      refactor_cancel_transaction(handle);
      return status;
   }

   // prompt them so they can rename, reorder, etc
   newParamInfo = show("-modal -xy _refactor_modify_params_form", cm.member_name, paramInfo);

   if (newParamInfo == "") {
      refactor_cancel_transaction(handle);
      return COMMAND_CANCELLED_RC;
   }

   show_cancel_form("Refactoring", "", true, true);

   /*
   isClassFunction := false;
   if(tag_tree_type_is_func(cm.type_name) && (cm.class_name != "")) {
      isClassFunction = true;
   } 

   if( isClassFunction ) {
      _str lang = _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);
      typeless tag_files = tags_filenamea(lang);
      struct VS_TAG_BROWSE_INFO all_classes_with_function[]=null;
      _str all_classes[]=null;
      int result = get_all_classes_with_function(cm, ext, all_classes_with_function, all_classes);

      // get list of files that reference the symbol
      fileList = null;
      status = tag_get_occurrence_file_list_restrict_to_classes(cm, fileList, all_classes,
                                                            tag_files, 10 );
      if(status == COMMAND_CANCELLED_RC) {
         refactor_cancel_transaction(handle);
         return status;
      } else if(status < 0) {
         // error
         refactor_cancel_transaction(handle);
         return status;
      }

      // When the last two parameters are valid then rename will lookup the class
      // defined by those two values and then lookup the symbol name in that class and do the rename.
      for( i = 0 ; i < all_classes_with_function._length( ) ; i++ ) {
         // Adjust seekpos so that it is on the class name rather than the keyword class or struct.
         all_classes_with_function[i].seekpos = correct_class_seek_pos( all_classes_with_function[i].file_name,
                                                                        all_classes_with_function[i].member_name,
                                                                        all_classes_with_function[i].line_no );
   
         refactor_c_add_class_info( handle,  all_classes_with_function[i].member_name,
                                             all_classes_with_function[i].file_name,
                                             all_classes_with_function[i].seekpos,
                                             all_classes_with_function[i].end_seekpos );
      }      
   }   
*/   

   status = refactor_c_modify_params(handle, cm.member_name, cm.file_name, (int)cm.seekpos, (int)cm.end_seekpos, paramInfo, newParamInfo);

   close_cancel_form(cancel_form_wid());
   if (status == COMMAND_CANCELLED_RC) {
      refactor_cancel_transaction(handle);
      clear_message();
      return status;
   }

   if(status < 0) {
      refactor_cancel_transaction(handle);
      return status;
   }

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, status, "Modify parameters failed:", "Modify Parameters", cm.file_name);

   return 0;
}

_command int refactor_parameterize_method() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   _message_box(get_message(VSRC_COMMAND_NOT_IMPLEMENTED));
   return 0;
}
int _OnUpdate_refactor_parameterize_method(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   //return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
   return MF_ENABLED;
}

/**
 * Create standard methods for a class or struct.
 * <p>
 *
 */

int refactor_standard_methods_symbol(struct VS_TAG_BROWSE_INFO cm, _str symbolName, _str &className, int &existingStandardMethods, int &transactionHandle )
{
   transactionHandle = 0;

   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   // get list of files that reference the symbol
   _str fileList[] = null;
   status := 0;
   fileList[fileList._length()] = cm.file_name;

   // begin the refactoring transaction
   handle := refactor_begin_transaction(/*"Create Standard Methods"*/);
   if (handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle));
      return handle;
   }

   transactionHandle = handle;

   // add the files
   int i, n = fileList._length();
   for (i = 0; i < n; i++) {
      status = refactor_add_project_file(handle, fileList[i]);
      if (status < 0) {
         refactor_cancel_transaction(handle);
         return status;
      }
   }

   // encapsulate this symbol with getters and setters
   className="";
   existingStandardMethods=0;

   show_cancel_form("Refactoring", "", true, true);
   // Validate the symbol, find the class it's in, and determine which standard methods already exist in the class
   status = refactor_c_standard_methods( handle, cm.file_name, symbolName, (int)cm.seekpos, (int)cm.scope_seekpos, className, existingStandardMethods );

   close_cancel_form(cancel_form_wid());
   if (status == COMMAND_CANCELLED_RC) {
      refactor_cancel_transaction(handle);
      clear_message();
      return status;
   }

   if (status < 0) {
      refactor_cancel_transaction(handle);

      if ( status == VSRC_VSREFACTOR_SYMBOL_IS_NOT_A_CLASS ) {
         _message_box("The symbol '" symbolName "' is not valid, It must be a class declaration or a class reference." );
      } else if ( status == VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A ) {
         _message_box("The symbol '" symbolName "' was not found." );
      } else {
         _message_box("Standard methods refactoring failed.\n\n":+get_message(status));
      }

      return status;
   }

   return status;
}

int refactor_start_standard_methods( struct VS_TAG_BROWSE_INFO cm )
{
   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   className := "";
   existingStandardMethods := transactionHandle := 0;
   int result = refactor_standard_methods_symbol( cm, cm.member_name, className, existingStandardMethods, transactionHandle );

   if ( result == 0 ) {
      _str results = show("-modal _refactor_standard_methods_form", cm.member_name, cm.seekpos, cm.scope_seekpos, className,
                          existingStandardMethods );

      // Canceled
      if ( results == "" ) {
         return 0;
      }

      int methodsFlags = (int)results;
      _str lang = _Filename2LangId(cm.file_name);
      result = refactor_c_standard_methods_finish( transactionHandle,
                                                   cm.file_name,
                                                   cm.member_name,
                                                   (int)cm.seekpos,
                                                   (int)cm.scope_seekpos,
                                                   methodsFlags,
                                                   get_formatting_flags(lang),
                                                   get_syntax_indent(lang) );
      // review the changes and save the transaction
      refactor_review_and_commit_transaction(transactionHandle, result, "Failed to create standard methods.", "Create Standard Methods");

   } else {
      return result;
   }

   return result;
}

static bool goto_class_name()
{
   limit := 32;
   nextsym := get_text(-1);
   while ((limit>0)&&(nextsym!="{")&&(nextsym!=":")) {
      nextsym=c_next_sym();
      --limit;
   }

   c_prev_sym();
   _clex_skip_blanks('-hc');

   return(limit>0);
}

static void find_class_scope()
{
   tag_update_context();

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   save_pos(auto cursor_pos);
   context_id :=tag_current_context();
   tag_init_tag_browse_info(auto cm);

   found   := false;
   gave_up := false;
   iteration := 1;

   while ((!found)&&(context_id>0)&&(!gave_up)&&(iteration<32)) {
      tag_get_context_browse_info(context_id, cm);
      ++iteration;

      if (_QROffset()==cm.end_seekpos) {
         gave_up=true;
      } else {
         _GoToROffset(cm.end_seekpos);
         if (cm.type_name:=="class" || cm.type_name:=="struct") {
            found=true;
         } else {
            context_id=tag_current_context();
         }
      }
   }

   if (found) {
      _GoToROffset(cm.seekpos);
      if (!goto_class_name()) {
         restore_pos(cursor_pos);
      }
   } else {
      restore_pos(cursor_pos);
   }
}

/**
 * Create standard methods for a class under the cursor or a class that the cursor is
 * inside. The standards methods include a constructor, copy constructor, destructor,
 * and assignment operator.
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_standard_methods() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   find_class_scope();

   // get browse information for the tag under the symbol
   status := tag_get_browse_info("", auto cm);
   if (status < 0) return status;

   // tag_get_browse_info() does not set the seek position, so we need
   // to figure it out.  the easiest thing is to just override the
   // filename and seekpos with the current symbol info.  then the
   // symbol will be resolved to its definition during the rename
   symbolName := "";
   seekPosition := 0;
   if (!getSymbolInfoAtCursor(symbolName, seekPosition)) {
      cm.file_name = p_buf_name;
      cm.seekpos = seekPosition;
      cm.line_no = p_RLine;
   }

   return refactor_start_standard_methods( cm );
}

int _OnUpdate_refactor_standard_methods(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

/**
 * Encapsulate a field with getter's and setter's.
 * <p>
 *
 */

int refactor_start_encapsulate(struct VS_TAG_BROWSE_INFO cm)
{
   if (!_haveRefactoring()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _str lang = _Filename2LangId(cm.file_name);
   int i, status,formattingFlags = get_formatting_flags(lang);

   // Start the transaction and get the handle for the transaction
   _str fileList[];
   int handle = refactor_start_refactoring_transaction(cm, fileList);

   show_cancel_form("Refactoring", "", true, true);
   status = refactor_c_find_class_methods( handle, cm.file_name, cm.member_name, (int)cm.seekpos, (int)cm.end_seekpos );
   if (status == COMMAND_CANCELLED_RC) {
      refactor_cancel_transaction(handle);
      close_cancel_form(cancel_form_wid());
      return status;
   } else if (status < 0) {
      refactor_cancel_transaction(handle);
      _message_box("Encapsulate field refactoring failed.\n\n":+get_message(status, cm.member_name));
      close_cancel_form(cancel_form_wid());
      return status;
   }

   _str class_methods[];
   for( i = 0 ; i < refactor_c_get_num_class_methods(handle) ; i++ ) {
      name := "";
      refactor_c_get_class_method(handle, i, name);
      class_methods[class_methods._length()] = name;
   }

   _str result = show("-modal _refactor_encapsulate_field_form", handle, cm.member_name, class_methods);

   // Canceled refactoring
   if ( result == "" ) {
      close_cancel_form(cancel_form_wid());
      return 0;
   }

   _str getterName, setterName, methodName;

   parse result with getterName (PATHSEP) setterName (PATHSEP) methodName;

   status = refactor_encapsulate_symbol( handle, cm, cm.member_name,
                                         getterName, setterName, methodName,
                                         formattingFlags, get_syntax_indent(lang) );

   if (status == COMMAND_CANCELLED_RC) {
      refactor_cancel_transaction(handle);
   } else if (status < 0) {
      _message_box("Encapsulate field refactoring failed.\n\n":+get_message(status, cm.member_name));
      refactor_cancel_transaction(handle);
   }

   return status;
}

/**
 * Encapsulate a class field that is under the cursor. This will create getter and setter functions
 * for the field, move the field to be private, and change all references to the field to use the 
 * getter and setter functions.
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_encapsulate() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   // get browse information for the tag under the symbol
   status := tag_get_browse_info("", auto cm);
   if (status < 0) return status;

   // tag_get_browse_info() does not set the seek position, so we need
   // to figure it out.  the easiest thing is to just override the
   // filename and seekpos with the current symbol info.  then the
   // symbol will be resolved to its definition during the rename
   symbolName := "";
   seekPosition := 0;
   if (!getSymbolInfoAtCursor(symbolName, seekPosition)) {
      cm.member_name = symbolName;
      cm.file_name = p_buf_name;
      cm.seekpos = seekPosition;
      cm.line_no = p_RLine;
   }

   return refactor_start_encapsulate( cm );
}

int _OnUpdate_refactor_encapsulate(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   int clex_color = _clex_find(0,'g');

   if (clex_color!=CFG_WINDOW_TEXT && clex_color!=CFG_LIBRARY_SYMBOL && clex_color!=CFG_USER_DEFINED) {
      return(MF_GRAYED);
   }

   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

// Return transaction handle or error
int refactor_start_refactoring_transaction(struct VS_TAG_BROWSE_INFO cm, _str (&fileList)[])
{
   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   //say("======================================================");
   //say("refactor_encapsulate_symbol: cm.member_name=" cm.member_name " seekpos=" cm.seekpos);

   // get list of files that reference the symbol

   fileList = null;
   _str class_list[];

   class_list[class_list._length()] = cm.class_name;
   VS_TAG_RETURN_TYPE visited:[];

   _str lang = _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);
   typeless tag_files = tags_filenamea( lang );
   int status = tag_get_occurrence_file_list(cm, fileList, 0, false, SE_TAG_FILTER_MEMBER_VARIABLE, visited);
   if (status < 0) {
      return status; 
   }

   // if no files in list, this is a local variable so just add the current buffer
   if (fileList._length() == 0 && cm.file_name!="") {
      fileList[fileList._length()] = cm.file_name;
   }

   // begin the refactoring transaction
   handle := refactor_begin_transaction(/*"Encapsulate Field"*/);
   if (handle < 0) {
      return handle;
   }

   // add the files
   int i, n = fileList._length();
   for (i = 0; i < n; i++) {
      status = refactor_add_project_file(handle, fileList[i]);
      if (status < 0) {
         refactor_cancel_transaction(handle);
         return status;
      }
   }

   return handle;
}

int refactor_encapsulate_symbol(int handle, struct VS_TAG_BROWSE_INFO cm, _str symbolName,
                                _str& getterName, _str& setterName, _str &methodName, int formattingFlags, int syntaxIndent )
{
   if (!_haveRefactoring()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // encapsulate this symbol with getters and setters
//   show_cancel_form("Refactoring", "", true, true);
   int status = refactor_c_encapsulate(handle, cm.file_name, cm.member_name, getterName, setterName, methodName,
                                       (int)cm.seekpos, (int)cm.scope_seekpos,
                                       formattingFlags, syntaxIndent );
   close_cancel_form(cancel_form_wid());
   if (status < 0 && status!=COMMAND_CANCELLED_RC) {
      if ( status == VSRC_VSREFACTOR_INVALID_SYMBOL_1A ) {
         _message_box("The symbol '" symbolName "' is not a valid field for encapsulation. Must be a class field." );
      } else if ( status == VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A ) {
         _message_box("The symbol '" symbolName "' was not found." );
      } else {
         _message_box("Failed to encapsulate field:  ":+get_message(status));
      }
   }

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, status, "", "Encapsulate Field");
   return status;
}

/**
 * Convert a local variable to a class field.
 * <p>
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_local_to_field() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

//   if( list_modified("", false, true) < 0 )
//      return 0

   //say("======================================================");
   //say("refactor_local_to_field:");

   // get browse information for the tag under the symbol
   nStatus := tag_get_browse_info("", auto cm);
   if ( nStatus < 0 ) {
      return nStatus;
   }

   //say("refactor_local_to_field: cm.class_name="cm.class_name"cm.member_name="cm.member_name"cm.file_name="cm.file_name"cm.type_name="cm.type_name);
   if ( cm.class_name != "" || cm.member_name == "" || cm.file_name == "" || cm.type_name != "lvar" ) {
      return 0;
   }

   // tag_get_browse_info() does not set the seek position, so we need
   // to figure it out.  the easiest thing is to just override the
   // filename and seekpos with the current symbol info.  then the
   // symbol will be resolved to its definition during the rename
   symbolName := "";
   seekPosition := 0;
   if ( !getSymbolInfoAtCursor(symbolName, seekPosition) ) {
      cm.file_name = p_buf_name;
      cm.seekpos   = seekPosition;
   }

   refactor_local_to_field_symbol(cm);
   return 0;
}
int _OnUpdate_refactor_local_to_field(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

int refactor_local_to_field_symbol( struct VS_TAG_BROWSE_INFO cm )
{
   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   _str result = show("-modal _refactor_local_to_field_form", cm.member_name,
                      get_formatting_flags( _Filename2LangId( cm.file_name ) ));
   if ( result == COMMAND_CANCELLED_RC ) {
      return 0;
   }
   _str strNewFieldName = _param1;
   int  nFlags = _param2;

   if ( strNewFieldName == "" ) {
      return -1;
   }

   // begin the refactoring transaction
   nHandle := refactor_begin_transaction(/*"Local to Field"*/);
   if ( nHandle < 0 ) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(nHandle));
      return nHandle;
   }

   int nStatus = refactor_add_project_file(nHandle, cm.file_name);
   if ( nStatus < 0 ) {
      refactor_cancel_transaction(nHandle);
      return nStatus;
   }

   // convert local to field
   show_cancel_form("Refactoring", "", true, true);
   nStatus = refactor_c_local_to_field(nHandle, cm.file_name, cm.member_name, (int)cm.seekpos, (int)cm.scope_seekpos, strNewFieldName, nFlags);
   close_cancel_form(cancel_form_wid());

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(nHandle, nStatus, "Failed to convert local to field.", "Convert Local to Field", cm.file_name);
   return nStatus;
}

/**
 * Convert a global variable to a static class field.
 * <p>
 *
 * @categories Refactoring_Functions
 */
_command int refactor_global_to_field() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   //say("refactor_global_to_field:");

//   if( list_modified("", false, true) < 0 )
//      return 0;

   // get browse information for the tag under the symbol
   nStatus := tag_get_browse_info("", auto cm);
   if ( nStatus < 0 ) {
      return nStatus;
   }

   //say("refactor_global_to_field: className=" cm.class_name " memberName=" cm.member_name " typeName=" cm.type_name);
   if ( cm.member_name == "" || cm.file_name == "" || cm.type_name != "gvar" ) {
      return -1;
   }

   // tag_get_browse_info() does not set the seek position, so we need
   // to figure it out.  the easiest thing is to just override the
   // filename and seekpos with the current symbol info.  then the
   // symbol will be resolved to its definition during the rename
   symbolName := "";
   seekPosition := 0;
   if ( !getSymbolInfoAtCursor(symbolName, seekPosition) ) {
      //cm.file_name = p_buf_name;
      //cm.seekpos   = seekPosition;
   }

   //say("refactor_global_to_field_symbol:");
   return refactor_global_to_field_symbol(cm, p_buf_name, seekPosition);
}
int _OnUpdate_refactor_global_to_field(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

int refactor_global_to_field_symbol( struct VS_TAG_BROWSE_INFO cm, _str filename = "", long nBeginSeekPos=0, long nEndSeekPos=0 )
{
   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   //say("======================================================");
   //say("refactor_global_to_field_symbol:");

   // Get the tag file for the current project or current workspace
   project_tagfile := project_tags_filename_only();
   if (project_tagfile == "") {
      project_tagfile = workspace_tags_filename_only();
   }

   // open the workspace tagfile
   int nStatus = tag_read_db(project_tagfile);
   if ( nStatus < 0 ) {
      _message_box("tag_read_db("project_tagfile") failed. error=":+get_message(nStatus));
      return nStatus;
   }

   _str result = show("-modal _refactor_global_to_field_form", cm.member_name,
                      get_formatting_flags( _Filename2LangId( cm.file_name ) ) );
   if ( result == COMMAND_CANCELLED_RC ) {
      return 0;
   }

   _str strNewFieldName = _param1;
   int  nFlags          = _param2;
   _str sClassCpp       = _param3;
   _str sClass          = _param4;
   //int  nClassId        = _param4;

   if ( strNewFieldName == "" || sClass == "" || sClassCpp == "" ) {
      _message_box("Null parameter from _refactor_global_to_field_form.");
      return -1;
   }

   // filename and the seek positions are the location that the refactoring
   // was triggered from if started from the editor control.  this information
   // will be passed to the refactoring engine to make sure the exact symbol is
   // found.  if these values are not set, use the information that was passed
   // in the tag browse info
   if ( filename == "" ) {
      filename      = cm.file_name;
      nBeginSeekPos = cm.seekpos;
      nEndSeekPos   = cm.scope_seekpos;
   }

   //_str sClass="";
   //nStatus = tag_get_class(nClassId, sClass);
   //if( nStatus < 0 ) {
   //   _message_box("tag_get_class(id="nClassId") failed. project_tagfile="project_tagfile);
   //   return nStatus;
   //}

   sClassFileName := "";
   nStatus = tag_get_class_detail(sClass, VS_TAGDETAIL_file_name, sClassFileName);
   if( nStatus < 0 ) {
      _message_box("get_class_detail("sClass") failed.");
      return nStatus;
   }

   // get list of files that reference the symbol
   VS_TAG_RETURN_TYPE visited:[];
   _str fileList[] = null;
   nStatus = tag_get_occurrence_file_list(cm, fileList, 10, true, SE_TAG_FILTER_ANYTHING, visited);
   if ( nStatus == COMMAND_CANCELLED_RC ) {
      return 0;
   } else if (nStatus < 0) {
      // error
      _message_box("tag_get_occurrence_file_list() failed.");
      return nStatus;
   }

   i := exists := 0;
   for ( ; i < fileList._length(); ++i ) {
      if ( fileList[i] :== sClassFileName ) {
         exists = 1;
         if ( i != 0 ) {
            swap_array_elements(fileList, 0, i);
         }
         break;
      }
   }
   if ( !exists ) {
      //say("Class filename not in fileList");
      // insert the file containing the class symbol to which we will add the field
      fileList[fileList._length()] = sClassFileName;
      swap_array_elements(fileList, 0, fileList._length()-1);
   }

   // if not files in list, this is a local variable so just add the current buffer
   if ( fileList._length() == 0 ) {
      fileList[fileList._length()] = filename;
   }

   // begin the refactoring transaction
   nHandle := refactor_begin_transaction(/*"Global to Field"*/);
   if ( nHandle < 0 ) {
      _message_box("Failed creating refactoring transaction: ":+get_message(nHandle));
      return nHandle;
   }

   // add the files
   int /*i,*/ n = fileList._length();
   for ( i = 0; i < n; i++ ) {
      //say("REFFILE: "refFile);
      nStatus = refactor_add_project_file(nHandle, fileList[i]);
      if ( nStatus < 0 ) {
         refactor_cancel_transaction(nHandle);
         return nStatus;
      }
   }

   // convert global variable to static field
   show_cancel_form("Refactoring", "", true, true);
   nStatus = refactor_c_global_to_field(nHandle, filename, cm.member_name, (int)nBeginSeekPos, (int)nEndSeekPos, sClassFileName, sClassCpp, strNewFieldName, nFlags);
   close_cancel_form(cancel_form_wid());

   // review the changes and save the transaction
   nStatus = refactor_review_and_commit_transaction(nHandle, nStatus, "Failed to convert global to field.", "Convert Global to Field", filename);
   return nStatus;
}

/**
 * Convert an instance variable to a static variable.
 * <p>
 *
 * @categories Refactoring_Functions
 */
_command int refactor_instance_to_static() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   _message_box(get_message(VSRC_COMMAND_NOT_IMPLEMENTED));
   return 0;
}
int _OnUpdate_refactor_instance_to_static(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   //return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
   return MF_GRAYED;
}

/**
 * Convert a static method to an instance method.
 * <p>
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_static_to_instance_method() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   // get browse information for the tag under the symbol
   nStatus := tag_get_browse_info("", auto cm);
   if ( nStatus < 0 ) {
      return nStatus;
   }

   // tag_get_browse_info() does not set the seek position, so we need
   // to figure it out.  the easiest thing is to just override the
   // filename and seekpos with the current symbol info.  then the
   // symbol will be resolved to its definition during the rename
   strSymbolName := "";
   nSeekPosition := 0;
   if ( !getSymbolInfoAtCursor(strSymbolName, nSeekPosition) ) {
      // errror?
   }

   //say("refactor_static_to_instance_method:");
   refactor_static_to_instance_method_symbol(cm, p_buf_name, nSeekPosition);

   return nStatus;
}

int _OnUpdate_refactor_static_to_instance_method(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

/**
 * Convert a static method to an instance method.
 * <p>
 *
 */
int refactor_static_to_instance_method_symbol(struct VS_TAG_BROWSE_INFO cm, _str strFileName="", int nSeekPosition=0)
{
   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   //say("======================================================");
   //say("refactor_static_to_instance_method_symbol:");

   // Get the tag file for the current project or current workspace
   project_tagfile := project_tags_filename_only();
   if (project_tagfile == "") {
      project_tagfile = workspace_tags_filename_only();
   }

   // open the workspace tagfile
   int nStatus = tag_read_db(project_tagfile);
   if ( nStatus < 0 ) {
      _message_box("tag_read_db("project_tagfile") failed. error["nStatus"]" );
      return nStatus;
   }

   nStatus = get_member_detail(cm.class_name, cm.member_name, VS_TAGDETAIL_flags, cm.flags);
   if ( nStatus ) {
      _message_box("ERROR: get_member_detail("cm.class_name", "cm.member_name", "cm.flags") msg=":+get_message(nStatus));
      return nStatus;
   }

   //say("refactor_static_to_instance_method: className=" cm.class_name " memberName=" cm.member_name " typeName=" cm.type_name " flags="dec2hex(cm.flags, 16));
   //say("refactor_static_to_instance_method: fileName=" cm.file_name);
   if ( cm.member_name == "" || cm.file_name == "" || (cm.type_name != "func" && cm.type_name != "proto") ) {
      return -1;
   }

   // Make sure this is a static method
   if ( !(cm.flags & SE_TAG_FLAG_STATIC) ) {
      _message_box("This is not a static method.");
      //say("This is not a static method!");
      return -1;
   }

   // get list of files that reference the symbol
   VS_TAG_RETURN_TYPE visited:[];
   _str fileList[] = null;
   nStatus = tag_get_occurrence_file_list(cm, fileList, 10, true, SE_TAG_FILTER_ANYTHING, visited);
   if ( nStatus == COMMAND_CANCELLED_RC ) {
      return 0;
   } else if (nStatus < 0) {
      // error
      return nStatus;
   }

   // if no files in list, then we must fail
   if ( fileList._length() == 0 ) {
      return -1;
   }

   // begin the refactoring transaction
   nHandle := refactor_begin_transaction(/*"Static to Instance Method"*/);
   if ( nHandle < 0 ) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(nHandle));
      return nHandle;
   }

   // add the files
   int i, n = fileList._length();
   for ( i = 0; i < n; i++ ) {
      nStatus = refactor_add_project_file(nHandle, fileList[i]);
      if ( nStatus < 0 ) {
         refactor_cancel_transaction(nHandle);
         return nStatus;
      }
   }

   class_name := tag_name_to_cpp_name(cm.class_name);
   // convert static method to instance method
   show_cancel_form("Refactoring", "", true, true);
   nStatus = refactor_c_static_to_instance_method(nHandle, cm.member_name, class_name, cm.file_name, (int)cm.scope_seekpos, 0);
   close_cancel_form(cancel_form_wid());

   // review the changes and save the transaction
   nStatus = refactor_review_and_commit_transaction(nHandle, nStatus, "Failed to convert static method to instance method.", "Convert Static to Instance Method", cm.file_name);
   return nStatus;
}

int _OnUpdate_refactor_static_to_instance(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   //return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
   return MF_GRAYED;
}

/**
 * Replace a constant temporary variable with an expression.
 * <p>
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_temp_to_query() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   _message_box(get_message(VSRC_COMMAND_NOT_IMPLEMENTED));
   return 0;
}
int _OnUpdate_refactor_temp_to_query(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   //return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
   return MF_GRAYED;
}

/**
 * Replace a repeated expression with a temporary variable.
 * <p>
 *
 */
_command int refactor_query_to_temp() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   _message_box(get_message(VSRC_COMMAND_NOT_IMPLEMENTED));
   return 0;
}
int _OnUpdate_refactor_query_to_temp(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   //return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
   return MF_GRAYED;
}

/**
 * Pull the designated symbol up to a super class. Also allows pulling 
 * up of dependent members.
 * <p>
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_pull_up() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   status := tag_get_browse_info("", auto cm);
   if (status == COMMAND_CANCELLED_RC) return status;
   if (status < 0) {
     _message_box( "Pull up failed: " :+ get_message(VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A,cm.member_name));
      return VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A;
   }

   tag_complete_browse_info(cm);

   return refactor_pull_up_symbol(cm);
}

bool in_file_list(_str filename, _str fileList[])
{
   int i;
   for(i = 0; i < fileList._length(); i++) {
      if(filename == fileList[i]) {
         return true;
      }
   }
   return false;
}

int refactor_pull_up_symbol(struct VS_TAG_BROWSE_INFO cm)
{
   int i, status;
   // init refactoring operations
   if (!refactor_init()) return COMMAND_CANCELLED_RC;

   // Get the tag file for the current project or current workspace
   project_tagfile := project_tags_filename_only();
   if (project_tagfile == "") {
      project_tagfile = workspace_tags_filename_only();
   }

   // open the workspace tagfile
   status = tag_read_db(project_tagfile);
   if( status < 0 ) {
      _message_box("tag_read_db("project_tagfile") failed: ":+get_message(status));
      return status;
   }

   tag_complete_browse_info(cm);

   // Name of field that user has selected. 
   _str member_name = cm.member_name;

   // Line number of field that user has selected.
   int member_line_no = cm.line_no;

   // Now find the class that this member belongs in 
   // and have the browse info point to the class's browse 
   // info.
   find_class_scope();

   status = tag_get_browse_info("", cm);
   if(status < 0) return status;
   tag_complete_browse_info(cm);

   if(cm.type_name != "class") {
      _message_box("Pull up failed: Must start the pull up refactoring inside a class definition");
      return -1;   
   }

   // begin the refactoring transaction
   handle := refactor_begin_transaction(/*"Pull Up"*/);
   if(handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle));
      return handle;
   }

   tag_update_context();

   // get list of files that reference the symbol
   VS_TAG_RETURN_TYPE visited:[];
   _str fileList[] = null;
   status = tag_get_occurrence_file_list(cm, fileList, 10, true, SE_TAG_FILTER_ANYTHING, visited);
   if(status == COMMAND_CANCELLED_RC) {
      return 0;
   } else if(status < 0) {
      _message_box("Failed to get list of files that contain symbol:  ":+get_message(status));
      return status;
   }

   // if no files in list then return.
   if(fileList._length() == 0) {
      _message_box("Failed to get list of files that contain symbol:  ":+
                   get_message(VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A), cm.member_name);
   }

   // add the files to the transaction
   n := fileList._length();
   for(i = 0; i < n; i++ ) {
      status = refactor_add_project_file(handle, fileList[i]);
      if(status < 0) {
         _message_box("Failed to add project file:  ":+get_message(status));
         refactor_cancel_transaction(handle);
         return status;
      }
   }

   show_cancel_form("Refactoring", "", true, true);

   _str superClassInfo;
   status = refactor_c_get_super_classes(handle, cm.member_name, 
                              cm.file_name, (int)cm.seekpos, (int)cm.end_seekpos, superClassInfo);

   close_cancel_form(cancel_form_wid());

   if(status < 0) {
      _message_box("Failed to get super classes:  ":+get_message(status));
      refactor_cancel_transaction(handle);
      return status;
   }

   // Find all files that the super class references.
   _str selected_super_class, super_class_def_file_name, super_class_file_name, super_class;
   _str selected_super_class_file_name="", sNumSuperClasses = "0";
   parse superClassInfo with sNumSuperClasses "@" .;
   if(sNumSuperClasses == "0") {
      _message_box("There are no super classes to move this member to. Cannot Pull Up.", "Pull Up");
      return COMMAND_CANCELLED_RC;
   }

   _str super_class_info = show("-modal _refactor_pull_up_form", superClassInfo, cm);
  
   // Refactoring canceled
   if( super_class_info == "" ) {
      refactor_cancel_transaction(handle);
      return COMMAND_CANCELLED_RC;
   }

   parse super_class_info with selected_super_class "@" super_class_def_file_name;

   // Find super class declaration file name
   parse superClassInfo with sNumSuperClasses "@" superClassInfo;
   for(i = 0; i < (int)sNumSuperClasses; i++) {
      parse superClassInfo with super_class "@" super_class_file_name "@" superClassInfo;

      if(!in_file_list(selected_super_class, fileList) && (super_class == selected_super_class)) {

         status = refactor_add_project_file(handle, super_class_file_name);
         if(status < 0) {
            _message_box("Failed to add project file:  ":+get_message(status));
            refactor_cancel_transaction(handle);
            return status;
         }
         break;
      }
   }

   // Add super class definition file to transaction.
   if(!in_file_list(super_class_def_file_name, fileList) && (super_class_def_file_name != super_class_file_name)) {
      status = refactor_add_project_file(handle, super_class_def_file_name);
      if(status < 0) {
         _message_box("Failed to add project file:  ":+get_message(status));
         refactor_cancel_transaction(handle);
         return status;
      }
   }

   // Find all files that contain function bodies for members that could potentially
   // be moved so that dependencies can be correctly found.
   num_matches := 0;
   max_matches := def_tag_max_find_context_tags;
   lang := _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);
   tag_files := tags_filenamea( lang );

   tag_push_matches();

   status = tag_list_in_class("",cm.member_name,0,0,tag_files,
                     num_matches,max_matches,
                     SE_TAG_FILTER_ANYTHING,
                     SE_TAG_CONTEXT_ONLY_THIS_CLASS|SE_TAG_CONTEXT_ALLOW_PRIVATE|SE_TAG_CONTEXT_ALLOW_PROTECTED,
                     false,true, null, null, visited, 1);

   _str function_body_files[] = null; 
   bool function_body_hash:[] = null;
   if (status == 1) {
      for ( i = 1 ; i <= num_matches; i++ ) {
         tag_get_match_browse_info(i, auto info);
         if (function_body_hash._indexin(_file_case(info.file_name)) == true) {
            continue;
         }
         function_body_hash:[_file_case(info.file_name)] = true;
         function_body_files[function_body_files._length()] = info.file_name;
      }
   }
   tag_pop_matches();

   // Build dependency string to send to find_members
   dependencyFiles := function_body_files._length() :+ "@";
   for (i = 0; i < function_body_files._length(); i++) {
      dependencyFiles :+= function_body_files[i] :+ "@";
   }

   // Now find all members of the class that can be moved and their dependencies.
   membersInfo := "";
   status = refactor_c_pull_up_find_members(handle, cm.member_name, cm.file_name, 
                                            (int)cm.seekpos, (int)cm.end_seekpos, 
                                            super_class, membersInfo, dependencyFiles);

   struct MemberInfo memberInfoList[] = null;
   parse_members_info(membersInfo, memberInfoList);

   _str members_to_move = show("-modal _refactor_pull_up_form2", member_name, member_line_no, cm.member_name, super_class, membersInfo, memberInfoList);

   // Refactoring canceled
   if (members_to_move == "") {
      refactor_cancel_transaction(handle);
      return COMMAND_CANCELLED_RC;
   }

   mou_hour_glass(true);

   show_cancel_form("Refactoring", "", true, true);

   // Sets the member that was being moved when the error occurred so it can be displayed in the
   // error message.
   _str member_working_on;
   status = refactor_c_pull_up(handle, cm.file_name, cm.member_name, 
                               (int)cm.seekpos, (int)cm.end_seekpos, 
                               super_class, members_to_move, member_working_on, super_class_def_file_name);
   mou_hour_glass(false);

   if(status < 0) {
      _message_box("Failed to Pull Up:  ":+get_message(status, member_working_on), "Pull Up");
      return status;
   }

   close_cancel_form(cancel_form_wid());

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, status, "Failed to Pull Up.", "Pull Up ":+super_class, cm.file_name);
   return status;
}

int _OnUpdate_refactor_pull_up(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

/**
 * Push the designated symbol down from the parent
 * class into this class.
 * <p>
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_push_down() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // get browse information for the tag under the symbol
   status := tag_get_browse_info("", auto cm);
   if (status == COMMAND_CANCELLED_RC) return status;
   if (status < 0) {
     _message_box( "Pull down failed: " :+ get_message(VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A,cm.member_name));
      return VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A;
   }

   tag_complete_browse_info(cm);

   return refactor_push_down_symbol(cm);
}

void parse_members_info( _str members_info, MemberInfo (&memberInfoList)[])
{
   typeless num_members;
   _str temp_members_info;

   parse members_info with num_members "@" temp_members_info;

//   say("members_info="members_info);

//   say("-----------------------------");
//   say("Parse members Info");
//   say("-----------------------------");

   int i, nMember, dependency_tree_id, member_tree_id, n = (int)num_members;
   for(nMember = 0; nMember < n; nMember++) {
      _str sIndex, sDescrip, sMemberType, sName, sTypeName, sFile, sLineNo, sHidden;
      parse temp_members_info with sIndex "@" temp_members_info;
      parse temp_members_info with sDescrip "@" temp_members_info;
      parse temp_members_info with sMemberType "@" temp_members_info;
      parse temp_members_info with sName "@" temp_members_info;
      parse temp_members_info with sTypeName "@" temp_members_info;
      parse temp_members_info with sFile "@" temp_members_info;
      parse temp_members_info with sLineNo "@" temp_members_info;
      parse temp_members_info with sHidden "@" temp_members_info;
      //      TODO:
      //     this line number may not be the same as the line numberneeded for tagging so
      //     try to find closest tagging match and correct the line number.

//      say("member "nMember);
//      say("------------------");

      memberInfoList[nMember].memberName = sName;
      memberInfoList[nMember].typeName = sTypeName;
      memberInfoList[nMember].fileName = sFile;
      memberInfoList[nMember].lineNo = (int)sLineNo;
      memberInfoList[nMember].memberType = sMemberType;
      memberInfoList[nMember].description = sDescrip;
      memberInfoList[nMember].memberIndex = (int)sIndex;
      memberInfoList[nMember].treeIndex = 0; // Fill in later

      if(sHidden == "hidden") {
         memberInfoList[nMember].hidden = true;
      } else {
         memberInfoList[nMember].hidden = false;
      }

//      say("   memberName = "memberInfoList[nMember].memberName);
//      say("   typeName   = "memberInfoList[nMember].typeName);
//      say("   fileName   = "memberInfoList[nMember].fileName);
//      say("   lineNo     = "memberInfoList[nMember].lineNo);
//      say("   memberType = "memberInfoList[nMember].memberType);
//      say("   description= "memberInfoList[nMember].description);
//      say("   memberIndex= "memberInfoList[nMember].memberIndex);
//      say("   treeIndex  = "memberInfoList[nMember].treeIndex);

      // Add dependencies
      _str s_num_dependencies, s_is_a_dependency, s_is_a_global, s_cross_dependency_index, dependencyDefFilename,
            sDependencyDefSeekPosition, dependencySymbolName;
      int num_dependencies, cross_dependency_index;
      parse temp_members_info with s_num_dependencies "@" temp_members_info;

      num_dependencies = (int)s_num_dependencies;

//      say("   numDependencies= "num_dependencies);
//      say("temp_members_info="temp_members_info);

//      memberInfoList[nMember].dependencies = null;
      nShownDependencies := 0;
      for(i = 0; i < num_dependencies; i++) {
         parse temp_members_info with dependencySymbolName "@" dependencyDefFilename "@" sDependencyDefSeekPosition "@" temp_members_info;
         parse temp_members_info with sIndex "@" temp_members_info;
         parse temp_members_info with s_is_a_dependency "@" s_is_a_global "@" s_cross_dependency_index "@" temp_members_info;
         parse temp_members_info with sDescrip "@" temp_members_info;

 //        say("      dependency = "i);
 //        say("         dependencySymbolName = "dependencySymbolName);
 //        say("         dependencyDefFilename = "dependencyDefFilename);
 //        say("         sDependencyDefSeekPosition = "sDependencyDefSeekPosition);
 //        say("         index = "sIndex);
 //        say("         s_is_a_dependency = "s_is_a_dependency);
 //        say("         s_is_a_global = "s_is_a_global);
 //        say("         s_cross_dependency_index = "s_cross_dependency_index);
 //        say("         description = "sDescrip);

         int index = (int)sIndex;
         cross_dependency_index = (int)s_cross_dependency_index;

         if(s_is_a_dependency == "false") {
            continue;
         }

         memberInfoList[nMember].dependencies[nShownDependencies].description = sDescrip;
         memberInfoList[nMember].dependencies[nShownDependencies].memberIndex = index;
         if(s_is_a_global == "true") {
            memberInfoList[nMember].dependencies[nShownDependencies].isAGlobal = true;
         } else {
            memberInfoList[nMember].dependencies[nShownDependencies].isAGlobal = false;
         }
//         say("nShownDependencies="nShownDependencies);

         memberInfoList[nMember].dependencies[nShownDependencies].symbolName        = dependencySymbolName;
         memberInfoList[nMember].dependencies[nShownDependencies].defFilename       = dependencyDefFilename;
         memberInfoList[nMember].dependencies[nShownDependencies].defSeekPosition   = (int)sDependencyDefSeekPosition;
         memberInfoList[nMember].dependencies[nShownDependencies].crossDependencyMemberIndex = cross_dependency_index;
         nShownDependencies++;
      }

//      say("      numDependencies after parse="memberInfoList[nMember].dependencies._length());
   }

   for(nMember = 0; nMember < n; nMember++) {
//      say("member: "nMember" "memberInfoList[nMember].description);

      int nDependencies = memberInfoList[nMember].dependencies._length();
//      say("   numDependencies="nDependencies);
      for(i = 0; i < nDependencies; i++) {
         int crossDependencyMemberIndex = memberInfoList[nMember].dependencies[i].crossDependencyMemberIndex;

//         say("      dependency="memberInfoList[nMember].dependencies[i].description" "crossDependencyMemberIndex);

         if(crossDependencyMemberIndex != -1) {
//            say("crossDependencyMemberIndex: "memberInfoList[nMember].description" = "crossDependencyMemberIndex);

            int newDependencyIndex = memberInfoList[crossDependencyMemberIndex].dependencies._length(); 

//            say("         cross member = "memberInfoList[crossDependencyMemberIndex].description);
            memberInfoList[crossDependencyMemberIndex].dependencies[newDependencyIndex].description = 
                  memberInfoList[nMember].description;
            memberInfoList[crossDependencyMemberIndex].dependencies[newDependencyIndex].memberIndex = 
                  memberInfoList[nMember].memberIndex;
            memberInfoList[crossDependencyMemberIndex].dependencies[newDependencyIndex].isAGlobal = false;
            memberInfoList[crossDependencyMemberIndex].dependencies[newDependencyIndex].crossDependencyMemberIndex = -1;
//            memberInfoList[nMember].dependencies[i].crossDependencyMemberIndex = -1;

            memberInfoList[crossDependencyMemberIndex].dependencies[newDependencyIndex].symbolName = 
                  memberInfoList[nMember].dependencies[i].symbolName;
            memberInfoList[crossDependencyMemberIndex].dependencies[newDependencyIndex].defFilename = 
                  memberInfoList[nMember].dependencies[i].defFilename;
            memberInfoList[crossDependencyMemberIndex].dependencies[newDependencyIndex].defSeekPosition = 
                  memberInfoList[nMember].dependencies[i].defSeekPosition;

         }
      }
   }

//   for(nMember = 0; nMember < n; nMember++) {
//      int nDependencies = memberInfoList[nMember].dependencies._length();
//      say("*member = "memberInfoList[nMember].description);
//      for(i = 0; i < nDependencies; i++) {
//         say("     *dependency = "memberInfoList[nMember].dependencies[i].description);
//      }
//   }
}

//defeventtab _refactor_finding_children_form;
int refactor_push_down_symbol(struct VS_TAG_BROWSE_INFO cm)
{
//   say("===================================================");
   // init refactoring operations
   if(!refactor_init()) return COMMAND_CANCELLED_RC;

   // Get the tag file for the current project or current workspace
   project_tagfile := project_tags_filename_only();
   if (project_tagfile == "") {
      project_tagfile = workspace_tags_filename_only();
   }

   // open the workspace tagfile
   status := tag_read_db(project_tagfile);
   if( status < 0 ) {
      _message_box("tag_read_db("project_tagfile") failed: ":+get_message(status));
      return status;
   }

   tag_complete_browse_info(cm);

   // Name of field that user has selected. 
   _str member_name = cm.member_name;

   // Line number of field that user has selected.
   int member_line_no = cm.line_no;

   // Now find the class that this member belongs in 
   // and have the browse info point to the class's browse 
   // info.
   find_class_scope();

   status = tag_get_browse_info("", cm);
   if(status < 0) return status;
   tag_complete_browse_info(cm);

   if(cm.type_name != "class") {
      _message_box("Push down failed: Must start the push down refactoring inside a class definition");
      return -1;   
   }

   // begin the refactoring transaction
   handle := refactor_begin_transaction(/*"Pull Up"*/);
   if(handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle));
      return handle;
   }

   tag_update_context();

   // get list of files that reference the symbol
   VS_TAG_RETURN_TYPE visited:[];
   _str fileList[] = null;
   status = tag_get_occurrence_file_list(cm, fileList, 10, true, SE_TAG_FILTER_ANYTHING, visited);
   if(status == COMMAND_CANCELLED_RC) {
      return 0;
   } else if(status < 0) {
      _message_box("Failed to get list of files that contain symbol:  ":+get_message(status));
      return status;
   }

   // if no files in list then return.
   if(fileList._length() == 0) {
      _message_box("Failed to get list of files that contain symbol:  ":+
                   get_message(VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A), cm.member_name);
   }

   // add the files to the transaction
   n := fileList._length();
   for (i := 0; i < n; i++ ) {
      status = refactor_add_project_file(handle, fileList[i]);
//      say("adding file "fileList[i]);
      if(status < 0) {
         _message_box("Failed to add project file:  ":+get_message(status));
         refactor_cancel_transaction(handle);
         return status;
      }
   }

   show_cancel_form("Push down refactoring", "Searching for derived classes", false, false);

   num_matches := 0;
   max_matches := def_tag_max_find_context_tags;
   lang := _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);
   tag_files := tags_filenamea( lang );
   derivedClassInfo := "";
   struct VS_TAG_BROWSE_INFO all_derived_classes_cm[], directly_derived_classes_cm[];
   _str all_derived_classes[], directly_derived_classes[];

   // Only get directly derived classes( depth of 2) This list also includes the class itself however.
   get_children_of(cm.member_name, cm.tag_database,
                   tag_files, cm.file_name, directly_derived_classes_cm,
                   directly_derived_classes, "", 2,
                   visited, 1);

   // Get all derived classes for dependency checking.
   get_children_of(cm.member_name, cm.tag_database,
                   tag_files, cm.file_name, all_derived_classes_cm,
                   all_derived_classes, "",
                   inheritance_depth:1000, visited, 1);

   // Only keep directly derived classes
   struct VS_TAG_BROWSE_INFO direct_children_cm[];
   for(i = 0; i < directly_derived_classes_cm._length(); i++) {
      if(directly_derived_classes_cm[i].member_name != cm.member_name) {
         direct_children_cm[direct_children_cm._length()] = directly_derived_classes_cm[i]; 
      }
   }

   close_cancel_form(cancel_form_wid());

   _str selected_derived_class, derived_class_def_file_name, derived_class_file_name, derived_class="";
   _str selected_derived_class_file_name="", sNumDerivedClasses = "0";

   // Nothing to push down to.
   if(direct_children_cm._length() == 0) {
      _message_box("There are no derived classes to move this member to. Cannot Push down.", "Push Down");
      refactor_cancel_transaction(handle);
      return COMMAND_CANCELLED_RC;
   }

   _str derived_class_info = show("-modal _refactor_push_down_form", direct_children_cm, cm);
  
   // Refactoring canceled
   if( derived_class_info == "" ) {
      refactor_cancel_transaction(handle);
      return COMMAND_CANCELLED_RC;
   }

   parse derived_class_info with selected_derived_class "@" derived_class_def_file_name;

   // Find derived class declaration file name
   for(i = 0; i < direct_children_cm._length(); i++) {
      if(!in_file_list(derived_class_def_file_name, fileList) && (direct_children_cm[i].member_name == selected_derived_class)) {
         derived_class = selected_derived_class;
         derived_class_file_name = direct_children_cm[i].file_name;
         status = refactor_add_project_file(handle, derived_class_file_name);
//         say("adding file 1"derived_class_file_name);
         if(status < 0) {
            _message_box("Failed to add project file:  ":+get_message(status));
            refactor_cancel_transaction(handle);
            return status;
         }
         break;
      }
   }

   // Find all files that contain function bodies for members that could potentially
   // be moved so that dependencies can be correctly found.
   tag_push_matches();

   status = tag_list_in_class("",cm.member_name,0,0,tag_files,
                     num_matches,max_matches,
                     SE_TAG_FILTER_ANYTHING,
                     SE_TAG_CONTEXT_ONLY_THIS_CLASS|SE_TAG_CONTEXT_ALLOW_PRIVATE|SE_TAG_CONTEXT_ALLOW_PROTECTED,
                     false, true, null, null, visited, 1);

   _str function_body_files[] = null; 
   bool function_body_hash:[] = null;
   if (status == 1) {
      for ( i = 1 ; i <= num_matches; i++ ) {
         tag_get_match_browse_info(i, auto info);

         if(function_body_hash._indexin(_file_case(info.file_name)) == true) {
            continue;
         }

         function_body_hash:[_file_case(info.file_name)] = true;
         function_body_files[function_body_files._length()] = info.file_name;

         if (!in_file_list(info.file_name, fileList) && 
                     (info.file_name != derived_class_file_name) && 
                     (info.file_name != derived_class_def_file_name)) {
            status = refactor_add_project_file(handle, info.file_name);
            fileList :+= info.file_name;
//            say("adding file 2"tag_file_name);
            if (status < 0) {
               _message_box("Failed to add project file:  ":+get_message(status));
               refactor_cancel_transaction(handle);
               return status;
            }
         }
      }
   }
   tag_pop_matches();

//   for (i = 0; i < fileList._length(); i++) {
//      say("adding file 3"fileList[i]);
//   }

   // Build dependency string to send to find_members
   dependencyFiles := function_body_files._length() :+ "@";
   for (i = 0; i < function_body_files._length(); i++) {
      dependencyFiles :+= function_body_files[i] :+ "@";
   }

   show_cancel_form("Refactoring", "", true, true);

   // Now find all members of the class that can be moved and their dependencies.
   membersInfo := "";
   status = refactor_c_push_down_find_members(handle, cm.member_name, cm.file_name, 
                                              (int)cm.seekpos, (int)cm.end_seekpos, 
                                              derived_class, membersInfo, dependencyFiles);

   close_cancel_form(cancel_form_wid());

   if(status < 0) {
      _message_box("Push down failed:  ":+get_message(status));
      refactor_cancel_transaction(handle);
      return status;
   }

   struct MemberInfo memberInfoList[] = null;
   parse_members_info(membersInfo, memberInfoList);

//   int wid = show("_refactor_finding_children_form");
   show_cancel_form("Refactoring", "", true, true);

//   say("Searching for member occurrences in derived classes");
//   say("===================================================");


   _str derived_class_list[];
   int nClass;
   for(i = 0; i < memberInfoList._length(); i++) {

      msg := "Searching for member occurrences in derived classes (" :+ i :+ "/" :+
             memberInfoList._length() :+ ")";

      static bool canceled;
      process_events( canceled );

      if ( gcanceled_finding_children == true ) {
         refactor_cancel_transaction(handle);
         close_cancel_form(cancel_form_wid());
         return COMMAND_CANCELLED_RC;
      }

      cancel_form_set_labels(cancel_form_wid(), msg);
      cancel_form_progress(cancel_form_wid(), i, memberInfoList._length()-1);

      tag_init_tag_browse_info(auto member_cm);
      member_cm.class_name = cm.member_name;
      member_cm.member_name = memberInfoList[i].memberName;
      member_cm.file_name = memberInfoList[i].fileName;
      member_cm.line_no = memberInfoList[i].lineNo;
      member_cm.type_name = memberInfoList[i].memberType;

      // Initialize boolean array for which classes this member is referred to by.
      for(nClass = 0; nClass < all_derived_classes._length(); nClass++) {
         memberInfoList[i].referred_to_in_class[nClass] = 0;
      }

      memberInfoList[i].files = null;
      memberInfoList[i].explicitRefOutsideClass = false;
      status = refactor_get_occurrences_in_classes(member_cm, 
                                                   all_derived_classes, 
                                                   memberInfoList[i].referred_to_in_class, 
                                                   0,
                                                   memberInfoList[i].explicitRefOutsideClass, 
                                                   memberInfoList[i].files);
   }

   close_cancel_form(cancel_form_wid());
//   wid._delete_window();


   // Need to get cm for each member of the class
   _str result = show("-modal _refactor_push_down_form2", member_name, member_line_no, handle, cm.member_name, 
                               derived_class, memberInfoList, all_derived_classes, lang, cm.file_name);

   if(result == "") {
      refactor_cancel_transaction(handle);
      return COMMAND_CANCELLED_RC;
   }

   // TODO Need to grab list of filenames to move definitions to.
   // Add super class definition file to transaction.
   _str members_to_move, class_def_info_list;

   parse result with members_to_move "$" class_def_info_list;

   // Go through class def file list and add any files that are not already
   // in the file list.
   _str class_defs, num_class_defs;
   _str new_files[] = null;
   parse class_def_info_list with num_class_defs "@" class_defs;
   for(i = 0; i < (int)num_class_defs; i++) {
      _str class_filename;
      parse class_defs with auto class_name "@" class_filename "@" class_defs;
      if(!in_file_list(class_filename, fileList) && !in_file_list(class_filename, new_files)) {
         new_files[new_files._length()] = class_filename;
      }
   }

//   say("members_to_move="members_to_move);


   bool membersToMove:[] = null;
   // Make a hash table of the memberIndices of all members that are going to be moved.
   _str temp_members_to_move, sNumMembersToMove, sMemberIndex;
   parse members_to_move with sNumMembersToMove "@" temp_members_to_move;
   for(i = 0; i < (int)sNumMembersToMove; i++) {
      parse temp_members_to_move with sMemberIndex "@" temp_members_to_move;
      membersToMove:[(int)sMemberIndex] = true;
//      say("memberIndex to move="sMemberIndex);
   }
   // Extract files from hash table
   for(i = 0; i < memberInfoList._length(); i++) {
      // Is this one of the members that should be extracted?
      // If not then continue else add it's files to the filesList

//      say("memberInfoList = "memberInfoList[i].memberIndex);

      if(membersToMove._indexin(memberInfoList[i].memberIndex) == false) {
         continue;
      }

//      say("member = "memberInfoList[i].memberName);
      typeless element;
      for (element._makeempty();;) {
         memberInfoList[i].files._nextel(element);
         if(element._isempty()) break;

         if(!in_file_list(element, fileList) && !in_file_list(element, new_files)) {
            new_files[new_files._length()] = element;
//            say("     filename = "element);
         }
      }
   }


   // add files to project
   for(i = 0; i < new_files._length(); i++) {
      status = refactor_add_project_file(handle, new_files[i]);
//      say("adding new file"new_files[i]);

      if(status < 0) {
         _message_box("Failed to add project file:  ":+get_message(status));
         refactor_cancel_transaction(handle);
         return status;
      }
   }

   // Refactoring canceled
   if( members_to_move == "") {
      refactor_cancel_transaction(handle);
      return COMMAND_CANCELLED_RC;
   }

   mou_hour_glass(true);

   show_cancel_form("Refactoring", "", true, true);

   // Make string of all files that contain function body's or static initializers.
   // Push down will go through these files to gather function body's and static initializers to move.
   _str orig_class_def_files = function_body_files._length() :+ "@";
   for(i = 0; i < function_body_files._length(); i++) {
      orig_class_def_files :+= function_body_files[i] :+ "@";
   }

//   say("orig_class_def_files =" orig_class_def_files);

   // Sets the member that was being moved when the error occurred so it can be displayed in the
   // error message.
   _str member_working_on;

   // Go through the members to move and add dependency information.
   parse members_to_move with sNumMembersToMove "@" temp_members_to_move;

   members_to_move_with_dependencies :=  sNumMembersToMove :+ "@";

//   say("Members to move");
//   say("---------------");
   for(i = 0; i < (int)sNumMembersToMove; i++) {
      parse temp_members_to_move with sMemberIndex "@" temp_members_to_move;

      members_to_move_with_dependencies :+= sMemberIndex :+ "@";

      struct MemberInfo pMemberInfo = memberInfoList[(int)sMemberIndex];

//      say("   memberInfo="pMemberInfo.description);

      members_to_move_with_dependencies :+= pMemberInfo.dependencies._length() :+ "@";
//      say("   numDependencies="pMemberInfo.dependencies._length());
      for(j := 0; j < pMemberInfo.dependencies._length(); j++) {
//         say("      defFilename="pMemberInfo.dependencies[j].defFilename);
//         say("      symbolName="pMemberInfo.dependencies[j].symbolName);
//         say("      defSeekPosition="pMemberInfo.dependencies[j].defSeekPosition);
         members_to_move_with_dependencies :+= pMemberInfo.dependencies[j].symbolName :+ "@";
         members_to_move_with_dependencies :+= pMemberInfo.dependencies[j].defFilename :+ "@";
         members_to_move_with_dependencies :+= pMemberInfo.dependencies[j].defSeekPosition :+ "@";
      }
   }

//   say("s="members_to_move_with_dependencies);

   status = refactor_c_push_down(handle, cm.file_name, cm.member_name, 
                                 (int)cm.seekpos, (int)cm.end_seekpos, 
                                 derived_class, members_to_move_with_dependencies, 
                                 member_working_on, class_def_info_list, 
                                 orig_class_def_files);
   mou_hour_glass(false);

   if(status < 0) {
      close_cancel_form(cancel_form_wid());
      _message_box("Failed to Push Down:  ":+get_message(status, member_working_on), "Push Down");
      refactor_cancel_transaction(handle);
      return status;
   }

   close_cancel_form(cancel_form_wid());

   // review the changes and save the transaction
   refactor_review_and_commit_transaction(handle, status, "Failed to Push Down.", "Push Down" :+derived_class, cm.file_name);
   return status;
}


int _OnUpdate_refactor_push_down(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

/**
 * Extract a set of methods and fields, etc into a new class.
 * <p>
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_extract_class() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // get browse information for the tag under the symbol
   nStatus := tag_get_browse_info("", auto cm);
   if ( nStatus < 0 ) {
      return nStatus;
   }

   return refactor_extract_class_symbol(cm, false);
}

/**
 * Extract a set of methods and fields, etc into a new superclass.
 * 
 * Create standard methods for a class under the cursor or a class that the cursor is
 * inside. The standards methods include a constructor, copy constructor, destructor,
 * and assignment operator.
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_extract_super_class() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // get browse information for the tag under the symbol
   nStatus := tag_get_browse_info("", auto cm);
   if( nStatus < 0 ) {
      return nStatus;
   }

   return refactor_extract_class_symbol(cm, true);
}

int refactor_extract_class_symbol(struct VS_TAG_BROWSE_INFO cm=null, bool bExtractSuper=false)
{
   //tag_browse_info_dump(cm,"refactor_extract_class_symbol");
   // init refactoring operations
   if( !refactor_init() ) {
      return COMMAND_CANCELLED_RC;
   }

   tag_complete_browse_info(cm);

   // begin the refactoring transaction
   nHandle := refactor_begin_transaction(/*"Extract Class"*/);
   if( nHandle < 0 ) {
   _message_box(get_message(VSRC_COMMAND_NOT_IMPLEMENTED));
      return nHandle;
   }
   if( !tag_tree_type_is_class(cm.type_name) ) {
      _message_box("Error "cm.member_name" is not a class. Type is '"cm.type_name"'");
      return -1;
   }

   // Find all files that contain function bodies for members that could potentially
   // be moved so that dependencies can be correctly found.
   num_matches := 0;
   max_matches := def_tag_max_find_context_tags;
   lang := _isEditorCtl() ? p_LangId : _Filename2LangId(cm.file_name);
   tag_files := tags_filenamea( lang );
   class_name := "";

   tag_push_matches();

   VS_TAG_RETURN_TYPE visited:[];
   nStatus := tag_list_in_class("",
                                cm.member_name,
                                0,
                                0,
                                tag_files,
                                num_matches,
                                max_matches,
                                SE_TAG_FILTER_ANYTHING,
                                SE_TAG_CONTEXT_ONLY_THIS_CLASS|SE_TAG_CONTEXT_ALLOW_PRIVATE|SE_TAG_CONTEXT_ALLOW_PROTECTED,
                                false,
                                true,
                                null, null, visited, 1);

   _str function_body_files[] = null; 
   bool function_body_hash:[] = null;
   if (nStatus == 1) {
      for ( i := 1 ; i <= num_matches; i++ ) {
         tag_get_match_browse_info(i, auto info);
         class_name = info.class_name;

         if (function_body_hash._indexin(_file_case(info.file_name)) == true) {
            continue;
         }

         function_body_hash:[_file_case(info.file_name)] = true;
         function_body_files[function_body_files._length()] = info.file_name;
      }
   }
   bool file_name_hash:[] = null;
   for( i := 0; i < function_body_files._length(); ++i ) {
      if( file_name_hash._indexin(function_body_files[i]) == true ) {
         continue;
      }
      nStatus = refactor_add_project_file(nHandle, function_body_files[i]);
      //-//say("refactor_extract_class_symbol: add_project_file -> "function_body_files[i]);
      if( nStatus < 0 ) {
         refactor_cancel_transaction(nHandle);
         return nStatus;
      }
      file_name_hash:[function_body_files[i]] = true;
   }

   tag_pop_matches();

   _str result = show("-modal _refactor_extract_class_file", bExtractSuper);
   if( result :!= "" ) {
      refactor_cancel_transaction(nHandle);
      return nStatus;
   }

   // do some return value checking to make sure we have
   // new files for extract class, and that the user didn't
   // set the header and source to the same location
   if( _param2 == "" || _param3 == "" || _param2 == _param3 ) {
      return VSRC_VSREFACTOR_INTERNAL_ERROR;
   }

   bAdded_S := false;
   bAdded_H := false;
   // If this file doesn't already exist in the current project,
   // query to determine if it should be added
   if( !_FileExistsInCurrentProject(absolute(_param2), _project_name) ) {
      int nResult=_message_box(_param2" is not included in the project.  Would you like to add it?","",MB_YESNOCANCEL|MB_ICONEXCLAMATION);
      if( nResult==IDYES ) {
         bAdded_S = (project_add_file(_param2) == 0);
      }
   }

   // If this file doesn't already exist in the current project,
   // query to determine if it should be added
   if( !_FileExistsInCurrentProject(absolute(_param3), _project_name) ) {
      int nResult=_message_box(_param3" is not included in the project.  Would you like to add it?","",MB_YESNOCANCEL|MB_ICONEXCLAMATION);
      if( nResult==IDYES ) {
         bAdded_H = (project_add_file(_param3) == 0);
      }
   }

   if( cm.class_name :== "" ) {
      cm.class_name = class_name;
   }

   if( file_name_hash:[_param2] != true ) {
      //-//say("refactor_extract_class_symbol: add_project_file -> "_param2);
      nStatus = refactor_add_project_file(nHandle, _param2);
      if( nStatus < 0 ) {
         refactor_cancel_transaction(nHandle);
         return nStatus;
      }
   }
   file_name_hash:[_param2] = true;

   if( file_name_hash:[_param3] != true ) {
      //-//say("refactor_extract_class_symbol: add_project_file -> "_param3);
      nStatus = refactor_add_project_file(nHandle, _param3, false);
      if( nStatus < 0 ) {
         refactor_cancel_transaction(nHandle);
         return nStatus;
      }
   }
   file_name_hash:[_param3] = true;

   _str file_name = cm.file_name;
   if( pos('h',_get_extension(file_name)) ) {
      //-//say("refactor_extract_class_symbol: pos('h') file_name="file_name" class_name="cm.class_name);
      c_file := get_assoc_class_file_name(file_name, cm.class_name, tag_files);
      //-//say("refactor_extract_class_symbol: c_file="c_file);
      if( c_file :!= "" ) {
         file_name = c_file;
      } 
   }

   mou_hour_glass(true);
   show_cancel_form("Refactoring", "", true, true);

   nStatus = refactor_c_extract_class_generate_member_list(nHandle, 
                                                           cm.member_name, 
                                                           file_name, 
                                                           (int)cm.seekpos, 
                                                           (int)cm.end_seekpos,
                                                           function_body_files); 
   close_cancel_form(cancel_form_wid());
   if( nStatus < 0 ) {
      refactor_cancel_transaction(nHandle);
      _message_box("Refactoring failed:  ":+get_message(nStatus));
      return nStatus;
   }

   struct ExtractClassMI memberInfo[];
   nStatus = show("-modal _refactor_extract_class_form", nHandle, cm, function_body_files, memberInfo, bExtractSuper );
   if( nStatus < 0 ) {
      refactor_cancel_transaction(nHandle);
      _message_box("Refactoring failed:  ":+get_message(nStatus));
      return nStatus;
   } else if( nStatus == 1 ) {
      // refactoring was cancelled
      refactor_cancel_transaction(nHandle);
      return 0;
   }

   // review the changes and save the transaction
   return refactor_review_and_commit_transaction(nHandle, nStatus, "", bExtractSuper ? "Extract Super Class" : "Extract Class");
}

int _OnUpdate_refactor_extract_class(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

int _OnUpdate_refactor_extract_super_class(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

/**
 * Move the designated field to a different location.
 * <p>
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_move_field() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   // init refactoring operations
   if(!refactor_init()) return COMMAND_CANCELLED_RC;

   // get browse information for the tag under the symbol
   status := tag_get_browse_info("", auto cm);
   if (status < 0) return status;

   // tag_get_browse_info() does not set the seek position, so we need
   // to figure it out.  the easiest thing is to just override the
   // filename and seekpos with the current symbol info.  then the
   // symbol will be resolved to its definition during the rename
   symbolName := "";
   seekPosition := 0;
   if (!getSymbolInfoAtCursor(symbolName, seekPosition)) {
      cm.member_name = symbolName;
      cm.file_name = p_buf_name;
      cm.seekpos = seekPosition;
      cm.line_no = p_RLine;
   }

   return refactor_start_move_field( cm );
}

_command int refactor_start_move_field( struct VS_TAG_BROWSE_INFO cm=null ) name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   tag_complete_browse_info(cm);
   if(!(cm.flags & SE_TAG_FLAG_STATIC)) {
      _message_box("The symbol '" cm.member_name "' is not a valid field for moving. Must be a static class field." );
      return 0;
   }
   // init refactoring operations
   if(!refactor_init()) return COMMAND_CANCELLED_RC;

   _str result = show("-modal _refactor_move_field_form", cm.member_name, cm );

   // Refactoring canceled
   if( result == "" ) {
      return 0;
   }

   _str className, classFileName, classDefFileName;
   parse result with className (PATHSEP) classFileName (PATHSEP) classDefFileName;

   return refactor_move_symbol( cm, cm.member_name, className, classFileName, classDefFileName );
}
int _OnUpdate_refactor_start_move_field(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}
int _OnUpdate_refactor_move_field(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}

int refactor_move_symbol(struct VS_TAG_BROWSE_INFO cm, _str symbolName, _str className, _str classFileName, _str classDefFileName )
{
   int i;
   // init refactoring operations
   if(!refactor_init()) return COMMAND_CANCELLED_RC;

//   say("======================================================");
//   say("refactor_move_symbol: cm.member_name=" cm.member_name " seekpos=" cm.seekpos);
//   say("refactor_move_symbol: symbolName=" symbolName " className=" className );

   // get list of files that reference the symbol
   _str fileList[] = null;

   // Make sure class file is always the first one in the list of files. Very important
   fileList[fileList._length()] = classFileName;


   _str class_list[];

   class_list[ class_list._length() ] = cm.class_name;
   _str lang = _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);
   typeless tag_files = tags_filenamea( lang );
   struct VS_TAG_RETURN_TYPE visited:[];
   int status = tag_get_occurrence_file_list_restrict_to_classes(cm, fileList, class_list, tag_files, 10, visited);
//   int status = tag_get_occurrence_file_list(cm, fileList, 10);
   if(status == COMMAND_CANCELLED_RC) {
      return 0;
   } else if(status < 0) {
      // error
      return status;
   }

   // if no files in list, this is a local variable so just add the current buffer
   if(fileList._length() == 1) {
      fileList[fileList._length()] = cm.file_name;
   }

   // Is the classDefFile already in the list? Add it to the list if
   // it is not already in the file list.
   alreadyInList := false;
   for(i = 0; i < fileList._length(); i++) {
      if( fileList[i] == classDefFileName ) {
         alreadyInList = true;
         break;
      }
   }

   if( !alreadyInList ) {
      fileList[fileList._length()] = classDefFileName;
   }

   // begin the refactoring transaction
   handle := refactor_begin_transaction(/*"Move Field"*/);
   if(handle < 0) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(handle));
      return handle;
   }

   _str origFilename = cm.file_name;

   // add the files
   n := fileList._length();
   for(i = 0; i < n; i++) {
      status = refactor_add_project_file(handle, fileList[i]);
      if(status < 0) {
         refactor_cancel_transaction(handle);
         return status;
      }
   }


   show_cancel_form("Refactoring", "", true, true);
   status = refactor_c_move_field(handle, origFilename, symbolName, className, classFileName, classDefFileName, (int)cm.seekpos, (int)cm.end_seekpos);
   close_cancel_form(cancel_form_wid());

   if(status < 0 && status != COMMAND_CANCELLED_RC) {
      if( status == VSRC_VSREFACTOR_INVALID_SYMBOL_1A ) {
         _message_box("The symbol '" symbolName "' is not a valid field for moving. Must be a static class field." );
      } else if( status == VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A ) {
         _message_box("The symbol '" symbolName "' was not found." );
      } else {
         _message_box("Failed to move field:  ":+get_message(status));
      }
      refactor_cancel_transaction(handle);
      return status;
   }

   // review the changes and save the transaction
   status = refactor_review_and_commit_transaction(handle, status, "", "Move Field");
   return status;
}


/**
 * Move the designated method to a different location.
 * <p>
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_move_method() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

  // init refactoring operations
   if( !refactor_init() ) return COMMAND_CANCELLED_RC;

   // get browse information for the tag under the symbol
   status := tag_get_browse_info("", auto cm);
   if ( status < 0 ) {
      return status;
   }

   //-//tag_browse_info_dump(cm, "refactor_move_method");

   // tag_get_browse_info() does not set the seek position, so we need
   // to figure it out.  the easiest thing is to just override the
   // filename and seekpos with the current symbol info.  then the
   // symbol will be resolved to its definition during the rename
   symbolName := "";
   seekPosition := 0;
   if( !getSymbolInfoAtCursor(symbolName, seekPosition) ) {
      //cm.file_name = p_buf_name;
      //cm.seekpos   = seekPosition;
   }

   //say("refactor_global_to_field_symbol:");
   return refactor_move_method_symbol(cm, p_buf_name, seekPosition);
}
int _OnUpdate_refactor_move_method(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
}
int refactor_move_method_symbol(struct VS_TAG_BROWSE_INFO cm, _str filename = "", long nBeginSeekPos=0)
{
   // init refactoring operations
   if( !refactor_init() ) return COMMAND_CANCELLED_RC;

   // filename and the seek positions are the location that the refactoring
   // was triggered from if started from the editor control.  this information
   // will be passed to the refactoring engine to make sure the exact symbol is
   // found.  if these values are not set, use the information that was passed
   // in the tag browse info
   if( filename == "" ) {
      filename      = cm.file_name;
      nBeginSeekPos = cm.seekpos;
   }

   if( filename == "" ) {
      _message_box("The file containing the symbol "cm.member_name" could not be found.");
      return -1;
   }

   if( cm.type_name != "func" && cm.type_name != "proto" ) {
      _message_box("The symbol "cm.member_name" is not a method.");
      return -1;
   }

   // Get the tagDB flags for this method
   int nStatus = get_member_detail(cm.class_name, cm.member_name, VS_TAGDETAIL_flags, cm.flags);
   if( nStatus ) {
      _message_box("ERROR: get_member_detail("cm.class_name", "cm.member_name", "cm.flags") msg=":+get_message(nStatus));
      return nStatus;
   }

   if( cm.class_name == "" ) {
      //_message_box("Move-method on global functions is currently not supported.");
      //return 0;
      cm.flags |= SE_TAG_FLAG_STATIC;
   }

   result := "";
   _str fileList[]=null;
   VS_TAG_RETURN_TYPE visited:[];
   // If this is a static method then we don't need to worry about delegates
   // so we use a different form
   if( cm.flags & SE_TAG_FLAG_STATIC ) {
      result = show("-modal _refactor_move_static_method_form", cm.member_name, cm.flags, get_formatting_flags(_Filename2LangId(cm.file_name)) | VSREFACTOR_METHOD_STATIC);
      if( result != COMMAND_CANCELLED_RC ) {
         _param5 = refactor_begin_transaction(/*"Move Method"*/);
         if( _param5 < 0 ) {
            _message_box("Failed creating refactoring transaction: error=":+get_message(nStatus));
            return _param5;
         }
      } else {
         return 0;
      }

      nStatus = tag_get_occurrence_file_list(cm, fileList, 10, true, SE_TAG_FILTER_ANYTHING, visited);
      if( nStatus == COMMAND_CANCELLED_RC) {
         return 0;
      } else if( nStatus < 0 ) {
         // error
         return nStatus;
      }
      //_message_box("Move-method on static-methods is currently not supported.");
      //return 0;
   } else {
      result = show("-modal _refactor_move_method_form", cm, cm.member_name, get_formatting_flags(_Filename2LangId(cm.file_name)));
   }

   if( result == COMMAND_CANCELLED_RC ) {
      //say("refactor_global_to_field_symbol: Canceled");
      return 0;
   }

   _str lang = _isEditorCtl()? p_LangId : _Filename2LangId(cm.file_name);
   typeless tag_files[] = tags_filenamea( lang );

   // get list of files that reference the symbol
   _str sSrcMethodName   = cm.member_name;
   _str sSrcClass        = cm.class_name;
   _str sDstMethodName   = _param1;
   int  nFlags           = _param2;
   int  nReceiver        = _param3;
   nSrcIdx := 0;
   nDstIdx := 0;

   if( sDstMethodName == "" ) {
      _message_box("The new method name is NULL.");
      return -1;
   }
   sAssocSrcClassFileName := "";
   sSrcClassFileName := "";

   if( sSrcClass != "" ) {
      nStatus = tag_get_class_detail(sSrcClass, VS_TAGDETAIL_file_name, sSrcClassFileName);
      if( nStatus < 0 ) {
         _message_box("get_class_detail("sSrcClass") failed.");
         return nStatus;
      }
      sAssocSrcClassFileName = get_assoc_class_file_name(sSrcClassFileName, sSrcClass, tag_files);
      //-//say("---get_assoc_class_file_name(Src:"sSrcClassFileName")="sAssocSrcClassFileName);
   } else {
      sSrcClassFileName = cm.file_name;
   }

   _str sDstClass=_param4;
   sDstClassFileName := "";
   nStatus = tag_get_class_detail(sDstClass, VS_TAGDETAIL_file_name, sDstClassFileName);
   if( nStatus < 0 ) {
      _message_box("get_class_detail("sDstClass") failed.");
      return nStatus;
   }

   nSrcIdx = fileList._length();
   if( sAssocSrcClassFileName == "" ) {
      fileList[nSrcIdx] = sSrcClassFileName;
   } else {
      fileList[nSrcIdx] = sAssocSrcClassFileName;
   }

   sAssocDstClassFileName := get_assoc_class_file_name(sDstClassFileName, sDstClass, tag_files);
   //-//say("---get_assoc_class_file_name(Dst:"sDstClassFileName")="sAssocDstClassFileName);

   nDstIdx = fileList._length();
   if( sAssocDstClassFileName == "" ) {
      if( sDstClassFileName != fileList[fileList._length()-1] ) {
         fileList[nDstIdx] = sDstClassFileName;
      } else {
         nDstIdx -= 1;
      }
   } else {
      if( sDstClassFileName != fileList[fileList._length()-1] ) {
         fileList[nDstIdx] = sAssocDstClassFileName;
      } else {
         nDstIdx -= 1;
      }
   }

   // begin the refactoring transaction
   int nHandle = _param5;//refactor_begin_transaction();
   if( nHandle < 0 ) {
      _message_box("Failed creating refactoring transaction:  ":+get_message(nHandle));
      return nHandle;
   }

   // add the files
   int n = fileList._length(), i=0;
   for( i = 0; i < n; i++ ) {
      _str refFile = fileList[i];
      bAddFile := 0;

      //-//say("REFFILE["i"]: "refFile);

      if( cm.flags & SE_TAG_FLAG_STATIC ) {
         bAddFile = 1;
      } else {
         if( refFile != cm.file_name ) {
            bAddFile = 1;
         }
      }

      if( bAddFile ) {
         // figure out which project includes this file and add the file to the transaction if
         // this file exists in the project
         nStatus = refactor_add_project_file(nHandle, refFile);
         if( nStatus < 0 ) {
            refactor_cancel_transaction(nHandle);
            return nStatus;
         }
      }
   }

   cppSrcClassName := "";
   if( sSrcClass != "" ) {
      cppSrcClassName = tag_name_to_cpp_name(sSrcClass);
   }

   cppDstClassName := "";
   if( sDstClass != "" ) {
      cppDstClassName = tag_name_to_cpp_name(sDstClass);
   }

   //-//say("refactor_c_move_method: src="cppSrcClassName"::"sSrcMethodName" dst="cppDstClassName"::"sDstMethodName);
   // convert global variable to static field
   show_cancel_form("Refactoring", "", true, true);
   //-//say("refactor_c_move_method("fileList[nSrcIdx]", "fileList[nDstIdx]") srcIdx="nSrcIdx" dstIdx="nDstIdx);
   nStatus = refactor_c_move_method(nHandle,
                                    sSrcMethodName,
                                    cppSrcClassName,
                                    sDstMethodName,
                                    cppDstClassName,
                                    nSrcIdx,
                                    nDstIdx,
                                    fileList,
                                    nReceiver,
                                    nFlags);
   close_cancel_form(cancel_form_wid());

   // review the changes and save the transaction
   nStatus = refactor_review_and_commit_transaction(nHandle, nStatus, "Failed to move method.", "Move Method ":+sSrcMethodName);
   return nStatus;
}

/**
 * Create a template class from a non-template class.
 * <p>
 *
 */
_command int refactor_parameterize_class() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   _message_box(get_message(VSRC_COMMAND_NOT_IMPLEMENTED));
   return 0;
}
int _OnUpdate_refactor_parameterize_class(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveRefactoring()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   //return _OnUpdateRefactoringCommand(cmdui, target_wid, command);
   return MF_GRAYED;
}

/*
   Find index of configuration with the given name in the list of configureations.

   @param config_name      Name of configuration to search for.

   @return index on success otherwise returns -1
*/
static int refactor_find_config( _str config_name )
{
   if (!_haveBuild()) {
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }

   compiler_name := "";
   int i,n = refactor_config_count();
   for (i=0; i<n; ++i) {
      refactor_config_get_name(i, compiler_name);
      if( config_name == compiler_name ) {
         return i;
      }
   }

   return -1;
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Move the designated symbol to a different location.
 * <p>
 * Returns 1 if the current configuration is valid, otherwise
 * Returns 0 on success or <0 on error.
 */

static int refactor_maybe_select_active_configuration( int project_handle=-1, bool quiet=false)
{
   if (!_haveBuild()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   status := 0;
   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;
   refactor_config_open( filename );

   if( refactor_config_count() <= 0 ) {
      generate_default_configs();
   }

   compiler_name := refactor_get_active_config_name( project_handle );
   if( refactor_find_config( compiler_name ) < 0 ) {
      int i;
      _str configs[];

      // Build list of config names
      for( i = 0 ; i < refactor_config_count() ; i++ ) {
         _str configName;
         refactor_config_get_name( i, configName );
         configs[ configs._length() ] = configName;
      }

      if (quiet) {
         return COMMAND_CANCELLED_RC;
      }

      if( refactor_config_count( ) > 0 ) {
         _str selection = show("_sellist_form -mdi -modal -reinit",
                               nls("Choose a default configuration"),
                               SL_DEFAULTCALLBACK|SL_SELECTCLINE,
                               configs,
                               "",
                               "",  // help item name
                               "",  // font
                               ""  // Call back function
                              );

         if( selection != "" ) {
            def_refactor_active_config = selection;
            _config_modify_flags(CFGMODIFY_DEFVAR);
            gtag_filelist_cache_updated=false;
         } else {
            return(COMMAND_CANCELLED_RC);
         }
      }

      _str default_config = show("-modal -xy _refactor_c_compiler_properties_form");
      if (default_config == "") {
         return(COMMAND_CANCELLED_RC);
      }

   } else {
      // Return 1 if the configuration is OK.
      return 1;
   }

   return status;
}

/**
 * Brings up the refactoring options dialog
 * <p>
 * 
 * @categories Refactoring_Functions
 */
_command int refactor_options() name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   // warn them that C++ refactoring is disabled
   if (refactor_warn_if_disabled()) return 0;

   orig_wid := p_window_id;

   int status = refactor_maybe_select_active_configuration( );
   if (status <= 0) {
      p_window_id = orig_wid;
      return status;
   }

   _str default_config = show("-modal -xy _refactor_c_compiler_properties_form");
   p_window_id = orig_wid;
   return (default_config == "")? COMMAND_CANCELLED_RC:0;
}

//////////////////////////////////////////////////////////////////////////////
// If 'cm' is a prototype, attempt to locate it's corresponding definition
//
bool refactor_convert_proto_to_proc(VS_TAG_BROWSE_INFO &cm)
{
   // Get the tag file for the current project or current workspace
   nStatus := 0;
   found := false;
   tag_files := project_tags_filename();
   foreach (auto project_tagfile in tag_files) {

      // open the workspace tagfile
      nStatus = tag_read_db(project_tagfile);
      if( nStatus < 0 ) continue;

      const_flag := (cm.flags & SE_TAG_FLAG_CONST);
      if ((cm.type_name:=="proto" || cm.type_name:=="procproto") &&
          !(cm.flags & (SE_TAG_FLAG_NATIVE|SE_TAG_FLAG_ABSTRACT))) {
         search_arguments :=  VS_TAGSEPARATOR_args:+cm.arguments;
         if (tag_find_tag(cm.member_name, "proc", cm.class_name, search_arguments)==0 ||
             tag_find_tag(cm.member_name, "func", cm.class_name, search_arguments)==0 ||
             tag_find_tag(cm.member_name, "constr", cm.class_name, search_arguments)==0 ||
             tag_find_tag(cm.member_name, "destr", cm.class_name, search_arguments)==0) {
            tag_get_tag_browse_info(cm);
            tag_complete_browse_info(cm);
            tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
            found=true;
         } else if (pos(VS_TAGSEPARATOR_package,cm.class_name)) {
            _str search_class=substr(cm.class_name,1,pos('S')-1):+
                          VS_TAGSEPARATOR_class:+
                          substr(cm.class_name,pos('S')+1);
            if (tag_find_tag(cm.member_name, "proc", search_class, search_arguments)==0 ||
                tag_find_tag(cm.member_name, "func", search_class, search_arguments)==0 ||
                tag_find_tag(cm.member_name, "constr", search_class, search_arguments)==0 ||
                tag_find_tag(cm.member_name, "destr", search_class, search_arguments)==0) {
               tag_get_tag_browse_info(cm);
               tag_complete_browse_info(cm);
               tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
               found=true;
            }
         }
         // find alternate matches until we locate proc with correct constness
         while (found && (cm.flags & SE_TAG_FLAG_CONST) != const_flag &&
                !tag_next_tag(cm.member_name, cm.type_name, cm.class_name, search_arguments)) {
            tag_get_tag_browse_info(cm);
            tag_complete_browse_info(cm);
            tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
         }
      }

      tag_reset_find_tag();
      if (found) {
         return true;
      }
   }

   if (nStatus < 0) {
      _message_box("tag_read_db("project_tagfile") failed. error["nStatus"]" );
   }
   return false;
}

/**
 * Get info for the symbol at the cursor
 *
 * @param symbolName       (output) Name of symbol at cursor
 * @param seekPosition     (output) Seek position of symbol at cursor 
 * @param visited          (optional) hash table of prior results
 * @param depth            (op\tional) depth of recursive search
 *
 * @return 0 on success, <0 on error
 */
int getSymbolInfoAtCursor(_str& symbolName, int& seekPosition,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // build path to the current symbol
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   int status = _c_get_expression_info(false, idexp_info, visited, depth);

   // return the info
   symbolName   = idexp_info.lastid;
   seekPosition = idexp_info.lastidstart_offset;
   return status;
}

static int getBrowseInfoAtCursor( struct VS_TAG_BROWSE_INFO &cm,
                                  VS_TAG_RETURN_TYPE (&visited):[], int depth=0 )
{
   // get browse information for the tag under the symbol
   status := tag_get_browse_info("", 
                                 cm, 
                                 quiet:false, 
                                 all_choices:null, 
                                 return_choices:false, 
                                 filterDuplicates:true, 
                                 filterPrototypes:true, 
                                 filterDefinitions:false, 
                                 force_tag_search:false, 
                                 filterFunctionSignatures:false, 
                                 visited, depth+1);
   if(status < 0) return status;

   // tag_get_browse_info() returns information about where the
   // symbol is defined, not necessarily the location where the cursor
   // is now.  therefore, the current file and seek position should
   // also be passed to refactor_rename_symbol()
   symbolName := "";
   i := seekPosition := 0;
   if(!getSymbolInfoAtCursor(symbolName, seekPosition)) {
      cm.member_name = symbolName;
      cm.file_name = p_buf_name;
      cm.seekpos = seekPosition;
      cm.line_no = p_RLine;
   }

   return status;
}

/**
 * Get the list of includes for this project
 * config, separated by the specified delimiter
 */
_str getDelimitedIncludePath(_str delimiter, _str fileName, _str projectName = _project_name, _str config = "")
{
   if (isEclipsePlugin()) {
      _includes := "";
      _eclipse_get_project_includes_string(_includes);

      return _includes;
   }
   if(config == "") {
      config = GetCurrentConfigName(projectName);
   }

   _str includesList = _ProjectGet_IncludesForFile(_ProjectHandle(projectName), fileName, true, config);
   includesList = _parse_project_command(includesList, "", projectName, "");

   // run thru the includes and make sure they are all absolute
   includePath := "";
   int i;
   for(i = 0; ; i++) {
      inc := "";
      parse includesList with inc (PARSE_PATHSEP_RE),'r' includesList;
      if(includesList == "" && inc == "") break;

      // make it absolute
      inc = stranslate(inc, FILESEP, FILESEP :+ FILESEP);
      // don't call absolute if the path starts with a variable
      if ((substr(inc,1,2):!='"$')&&(substr(inc,1,1):!='$')) {
         inc = _AbsoluteToProject(inc, projectName);
      }

      if(i == 0) {
         includePath = inc;
      } else {
         includePath :+= delimiter :+ inc;
      }
   }

   return includePath;
}

/**
 * Prompt the user to save modified files before refactoring
 *
 * @return F if cancelled, T to continue
 */
static bool saveFilesBeforeRefactoring()
{
   if (_no_child_windows()) return true;
   _project_disable_auto_build(true);
   int status = _mdi.p_child.list_modified("Files must be saved before refactoring",true);
   _project_disable_auto_build(false);
   if(!status) return true;
   return false;
}

/**
 * If not in a C/C++ source file, remove the refactoring menu
 * from the popup menu when you have a selection.
 */
void _on_popup2_refactor(_str menu_name,int menu_handle)
{
   // Remove both versions of extract method if we are not an editor control.
   if (!_isEditorCtl(false)) {
      int output_menu_handle,output_menu_pos;
      int status=_menu_find(menu_handle,"refactor_extract_method",output_menu_handle,output_menu_pos,'M');
      if (!status) {
         _menu_delete(output_menu_handle,output_menu_pos);
      }
      status=_menu_find(menu_handle,"refactor_quick_extract_method",output_menu_handle,output_menu_pos,'M');
      if (!status) {
         _menu_delete(output_menu_handle,output_menu_pos);
      }
      status=_menu_find(menu_handle,"refactorbar",output_menu_handle,output_menu_pos,'C');
      if (!status) {
         _menu_delete(output_menu_handle,output_menu_pos);
      }
   }

   // Remove C Extract method refactoring if this is not an editor control or we are not in C mode.
   if (!_LanguageInheritsFrom("c") || def_disable_cpp_refactoring || !_haveRefactoring()) {
      int output_menu_handle,output_menu_pos;
      int status=_menu_find(menu_handle,"refactor_extract_method",output_menu_handle,output_menu_pos,'M');
      if (!status) {
         _menu_delete(output_menu_handle,output_menu_pos);
      }
   }
}
/**
 * Look up the given item in the refactoring menu and enable/disable it.
 * Copy it from the refactoring menu template if necessary.
 */
void addSpecificRefactoringMenuItem(int refactoringMenuHandle,
                                    int refactoringTemplateHandle,
                                    _str category_name, _str cmdPrefix, _str cmd, 
                                    int insertIndex, bool enable)
{
   submenuHandle := 0;
   itemIndex := 0;
   int enable_flag = enable? MF_ENABLED : MF_GRAYED;
   if(_menu_find(refactoringMenuHandle, category_name, submenuHandle, itemIndex, 'C')) {
      // not found so  load from template and then modify the command if necessary
      mfflags := 0;
      mi_caption := "";
      mi_command := "";
      mi_category := "";
      helpCommand := "";
      helpMessage := "";
      if(!_menu_get_state(refactoringTemplateHandle, category_name, mfflags, 'C', mi_caption, mi_command, mi_category, helpCommand, helpMessage)) {
         // insert this in our menu
         _menu_insert(refactoringMenuHandle, insertIndex, enable_flag, mi_caption, (cmdPrefix == "") ? mi_command : cmdPrefix :+ cmd :+ mi_category, mi_category, helpCommand, helpMessage);
      }

      // find the item that was just inserted
      if(_menu_find(refactoringMenuHandle, category_name, submenuHandle, itemIndex, 'C')) {
         return;
      }
   }
   _menu_set_state(refactoringMenuHandle, itemIndex, enable_flag, 'P');
}

/**
 * Add refactoring menu items to the specified menu
 *
 * @param menuHandle Handle of parent menu
 * @param cmdPrefix  Prefix of command.  Empty for MDI menu or editor control right click menu
 * @param cm         Information about the tag that is currently selected
 * @param removeIfDisabled
 *                   Remove the refactoring submenu if disabled and this is true
 */
void addQuickRefactoringMenuItems(int menuHandle, _str cmdPrefix, 
                                  struct VS_TAG_BROWSE_INFO cm = null,
                                  bool removeIfDisabled = true)
{
   // find refactoring menu placeholder
   int refactoringMenuHandle;
   int refactoringMenuIndex = _menu_find_loaded_menu_category(menuHandle, "quick_refactoring", refactoringMenuHandle);
   if(refactoringMenuIndex < 0) {
      return;
   }

   // load refactoring menu template
   int index = find_index("_quick_refactoring_menu", oi2type(OI_MENU));
   if(!index) {
      return;
   }

   int refactoringTemplateHandle = _menu_load(index, 'P');
   if(refactoringTemplateHandle < 0) {
      return;
   }

   // figure out the extension
   lang := "";
   if (cm != null) {
      lang = cm.language;
      if (lang==null || lang=="") {
         lang = _Filename2LangId(cm.file_name);
      }
   }

   // if cm is null or this is not a 'c' extension, remove the refactoring
   // if requested
   if (removeIfDisabled && 
       (cm == null || 
        _LanguageInheritsFrom("m", lang) ||
        (!_LanguageInheritsFrom("c",    lang) &&
         !_LanguageInheritsFrom("java", lang) && 
         !_LanguageInheritsFrom("cs",   lang) && 
         !_LanguageInheritsFrom("e",    lang)) )) {
      hasSeparatorBefore := false;
      hasSeparatorAfter := false;
      sepCaption := "";
      mfflags := 0;

      // check for separator before
      if (refactoringMenuIndex > 0) {
         if (!_menu_get_state(menuHandle, refactoringMenuIndex - 1, mfflags, 'P', sepCaption)) {
            if (sepCaption == "-") {
               hasSeparatorBefore = true;
            }
         }
      }

      // check for separator after
      if(!_menu_get_state(menuHandle, refactoringMenuIndex + 1, mfflags, 'P', sepCaption)) {
         if(sepCaption == "-") {
            hasSeparatorAfter = true;
         }
      }

      // remove refactoring submenu
      _menu_delete(menuHandle, refactoringMenuIndex);

      if (cm == null || _istagging_supported(_Filename2LangId(cm.file_name))) {
         // add override method 
         if (cm == null && _FindLanguageCallbackIndex("_%s_generate_function",lang) > 0) {
            if(_menu_find(refactoringMenuHandle, "override_method", auto outMenuHandle, auto outItemIndex, 'C') && 
               _menu_find(refactoringMenuHandle, cmdPrefix"_override_method", outMenuHandle, outItemIndex, 'M')) {
               _menu_insert(menuHandle, refactoringMenuIndex, 0, "Override Method...", "override_method", "override_method");
            }
         }
         // add quick rename
         if (cm == null) {
            _str quick_rename_command = (cmdPrefix == "")? "refactor_quick_rename" : cmdPrefix:+"_refactor ":+"quick_rename";
            _menu_insert(menuHandle, refactoringMenuIndex, 0, "Rename symbol", quick_rename_command);
         }

         // TBF: disable this feature for 11.0
         /*
         _str quick_encapsulate_field_command = (cmdPrefix == "")? "refactor_quick_encapsulate_field" : cmdPrefix:+"_refactor ":+"quick_encapsulate_field";
         //_menu_insert(menuHandle, refactoringMenuIndex, 0, "Encapsulate field", quick_encapsulate_field_command);
         _menu_insert(menuHandle, refactoringMenuIndex, MF_GRAYED, "Encapsulate field", quick_encapsulate_field_command);
         */

         if (!removeIfDisabled) {
            _str quick_modify_parameter_command = (cmdPrefix == "")? "refactor_quick_modify_params" : cmdPrefix:+"_refactor ":+"quick_modify_params";
            _menu_insert(menuHandle, refactoringMenuIndex, 0, "Modify Parameters", quick_modify_parameter_command);

            _str quick_replace_literal_command = (cmdPrefix == "")? "refactor_quick_replace_literal" : cmdPrefix:+"_refactor ":+"quick_replace_literal";
            if(cmdPrefix != "cb" && cmdPrefix != "proctree") {
               _menu_insert(menuHandle, refactoringMenuIndex, 0, "Replace Literal", quick_replace_literal_command);
            }
         }

         hasSeparatorAfter = false;
      }

      // remove trailing separator if there is also one before
      if(hasSeparatorAfter) {
         if(refactoringMenuIndex == 0 || hasSeparatorBefore) {
            _menu_delete(menuHandle, refactoringMenuIndex);
         }
      }
      // cleanup refactoring menu template
      _menu_destroy(refactoringTemplateHandle);
      return;
   }

   // determine which refactorings should be enabled
   enableQuickRename              := true;
   enableQuickEncapsulate         := true;
   enableQuickModifyParams        := true;
   enableQuickReplaceLiteral      := true;
   enableQuickExtractMethod       := false;

   if(cm != null) {
      if(cm.type_name != "func" && cm.type_name != "proc" && cm.type_name != "proto") {
         enableQuickModifyParams = false;
      }
      if(!(cm.class_name != "" && cm.type_name == "var")) {
         enableQuickEncapsulate = false;
      }
   }

   if (_isEditorCtl()) {
      // enable extract method only if there is a selection
      // This method requires a selection, but not a block selection
      if ( select_active() && _select_type()!="BLOCK" ) {
         enableQuickExtractMethod = true;
      } 
   }


   // the format of the command depends on where the refactoring menu is being
   // shown from.  if cmdPrefix is empty, this is the main mdi menu or the
   // right click menu in an editor control.  for these, just use the normal
   // 'refactor_NAME' syntax.  if there is a command prefix, this is coming
   // from the proctree or symbol browser, so use the format 'PREFIX_refactor NAME'.
   //
   // each refactoring should use its category as its command suffix.  for
   // example:
   //
   //   refactoring   category   command           prefixed-command
   //   ------------------------------------------------------------------------------
   //   rename        rename     refactor_rename   prefix_refactor rename
   //

   // add override method 
   if (_FindLanguageCallbackIndex("_%s_generate_function",lang) > 0) {
      // make sure this isn't already there...
      if(_menu_find(refactoringMenuHandle, "override_method", auto outMenuHandle, auto outItemIndex, 'C') && 
         _menu_find(refactoringMenuHandle, cmdPrefix"_override_method", outMenuHandle, outItemIndex, 'M')) {
         status := _menu_insert(refactoringMenuHandle, -1, 0, "Override Method...", "override_method", "override_method");
      }
   }

   cmd := "_quick_refactor ";

   // Quick Replace literal
   if(cmdPrefix != "cb" && cmdPrefix != "proctree" && cmdPrefix != "tbclass") {
      addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "quick_replace_literal", cmdPrefix, cmd, 0, enableQuickReplaceLiteral);
   }

   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "quick_encapsulate_field", cmdPrefix, cmd, 0, enableQuickEncapsulate);

   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "quick_modify_params", cmdPrefix, cmd, 0, enableQuickModifyParams);

   if (cm == null) {
      // Extract method
      addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "quick_extract_method", cmdPrefix, cmd, 0, enableQuickExtractMethod);
   }

   // quick rename
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "quick_rename", cmdPrefix, cmd, 0, enableQuickRename);

   // cleanup refactoring menu template
   _menu_destroy(refactoringTemplateHandle);
}

static void addAutoImportMenuItems(int menuHandle, _str cmdPrefix, 
                                   struct VS_TAG_BROWSE_INFO cm = null,
                                   bool removeIfDisabled = true)
{
   // find imports menu placeholder
   importsMenuIndex := _menu_find_loaded_menu_category(menuHandle, "imports", auto importsMenuHandle);
   if(importsMenuIndex < 0) {
      return;
   }

   // figure out the extension
   lang := "";
   if (cm != null) {
      lang = cm.language;
      if (lang==null || lang=="") {
         lang = _Filename2LangId(cm.file_name);
      }
   }

   // if cm is null or this is not a 'c' extension, remove the refactoring
   // if requested
   if (!_haveRefactoring() && removeIfDisabled) {
      // remove imports submenu
      _menu_delete(menuHandle, importsMenuIndex);
      _menuRemoveExtraSeparators(menuHandle, importsMenuIndex);
      return;
   }
   // Can't remove the Imports submenu unless add code to readd it after it's been removed.
#if 0
   // if cm is null or this is not a 'c' extension, remove the refactoring
   // if requested
   if (removeIfDisabled && (cm == null || !_haveRefactoring() ||
                            (!_LanguageInheritsFrom("c", lang) &&
                             !_LanguageInheritsFrom("java", lang) && 
                             !_LanguageInheritsFrom("e", lang)))) {
      // remove imports submenu
      _menu_delete(menuHandle, importsMenuIndex);
      _menuRemoveExtraSeparators(menuHandle, importsMenuIndex);
      return;
   }
#endif
}

/**
 * Add refactoring menu items to the specified menu
 *
 * @param menuHandle Handle of parent menu
 * @param cmdPrefix  Prefix of command.  Empty for MDI menu or editor control right click menu
 * @param cm         Information about the tag that is currently selected
 * @param removeIfDisabled
 *                   Remove the refactoring submenu if disabled and this is true
 */
void addCPPRefactoringMenuItems(int menuHandle, _str cmdPrefix, 
                                      struct VS_TAG_BROWSE_INFO cm = null,
                                      bool removeIfDisabled = true)
{
   // hide C/C++ refactoring if it is disabled
   if (def_disable_cpp_refactoring || !_haveRefactoring()) {
      if (!_menu_find(menuHandle,"cpp_refactoring",auto mh,auto mpos,'C')) {
         _menu_delete(mh,mpos);
      }
      return;
   }

   // find refactoring menu placeholder
   int refactoringMenuHandle;
   int refactoringMenuIndex = _menu_find_loaded_menu_category(menuHandle, "cpp_refactoring", refactoringMenuHandle);
   if(refactoringMenuIndex < 0) {
      return;
   }

   // load refactoring menu template
   int index = find_index("_refactoring_menu", oi2type(OI_MENU));
   if(!index) {
      return;
   }

   int refactoringTemplateHandle = _menu_load(index, 'P');
   if(refactoringTemplateHandle < 0) {
      return;
   }

   // figure out the extension
   lang := "";
   if (cm != null) {
      lang = cm.language;
      if (lang==null || lang=="") {
         lang = _Filename2LangId(cm.file_name);
      }
   }

   // if cm is null or this is not a 'c' extension,
   // remove or disable the C++ refactoring menu
   _menu_set_state(menuHandle, "cpp_refactoring", MF_ENABLED);
   if (cm == null || !_LanguageInheritsFrom("c", lang)) {

      hasSeparatorBefore := false;
      hasSeparatorAfter := false;

      _str sepCaption;
      int mfflags;

      // check for separator before
      if(refactoringMenuIndex > 0) {
         if(!_menu_get_state(menuHandle, refactoringMenuIndex - 1, mfflags, 'P', sepCaption)) {
            if(sepCaption == "-") {
               hasSeparatorBefore = true;
            }
         }
      }

      // check for separator after
      if(!_menu_get_state(menuHandle, refactoringMenuIndex + 1, mfflags, 'P', sepCaption)) {
         if(sepCaption == "-") {
            hasSeparatorAfter = true;
         }
      }

      if (removeIfDisabled) {
         // remove refactoring submenu
         _menu_delete(menuHandle, refactoringMenuIndex);

         // remove trailing separator if there is also one before
         if(hasSeparatorAfter) {
            if(refactoringMenuIndex == 0 || hasSeparatorBefore) {
               _menu_delete(menuHandle, refactoringMenuIndex);
            }
         }
      } else {
         // just disable the whole submenu
         _menu_set_state(menuHandle, "cpp_refactoring", MF_GRAYED);
      }

      return;
   }

   // determine which refactorings should be enabled
   enableRename                   := false;
   enableMoveField                := false;
   enableMoveMethod               := false;
   enableEncapsulate              := false;
   enableReplaceLiteral           := false;
   enableLocalToField             := false;
   enableGlobalToField            := false;
   enableStaticToInstanceMethod   := false;
   enableExtractMethod            := false;
   enableStandardMethods          := false;
   enableModifyParams             := false;
   enablePullUp                   := false;
   enablePushDown                 := false;
   enableExtractClass             := false;
 
   if(cm != null) {
      if (_LanguageInheritsFrom("c", lang)) {
         //-//tag_browse_info_dump(cm, "addRefactoringMenuItems");

         // only currently supported for c/c++
         // this is where we check to see if each refactoring should be enabled or not

         // default rename to enabled for any symbols
         enableRename = true;

         // default move field to enabled for any symbols
         enableMoveField = true;

         // default move method to enabled for any symbols
         enableMoveMethod = true;

         // default encapsulate field to enabled for any symbols
         enableEncapsulate = true;

         // default replace literal to enabled for any symbols
         enableReplaceLiteral = true;

         enableLocalToField = true;
         enableGlobalToField = true;
         enableStaticToInstanceMethod = true;
         enableStandardMethods = true;
         enablePullUp = true;
         enablePushDown = true;

         if(tag_tree_type_is_func( cm.type_name ) == 1) {
            enableModifyParams = true;
         }

         if(tag_tree_type_is_class(cm.type_name) == 1) {
            enableExtractClass = true;
         }
      } 
   } else if (_isEditorCtl()) {
      // enable extract method only if there is a selection
      // This method requires a selection, but not a block selection
      if ( select_active() && _select_type()!="BLOCK" ) {
         enableExtractMethod = true;
      } 
   }
   if(cm != null) {
      if(cm.type_name != "func" && cm.type_name != "proc" && cm.type_name != "proto") {
         enableModifyParams = false;
      }
      if(!(cm.class_name != "" && cm.type_name == "var")) {
         enableEncapsulate = false;
      }
   }
   // the format of the command depends on where the refactoring menu is being
   // shown from.  if cmdPrefix is empty, this is the main mdi menu or the
   // right click menu in an editor control.  for these, just use the normal
   // 'refactor_NAME' syntax.  if there is a command prefix, this is coming
   // from the proctree or symbol browser, so use the format 'PREFIX_refactor NAME'.
   //
   // each refactoring should use its category as its command suffix.  for
   // example:
   //
   //   refactoring   category   command           prefixed-command
   //   ------------------------------------------------------------------------------
   //   rename        rename     refactor_rename   prefix_refactor rename
   //

   cmd := "_refactor ";

   // standard methods
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "standard_methods", cmdPrefix, cmd, 0, enableStandardMethods );

   // Replace literal
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "replace_literal", cmdPrefix,  cmd, 0, enableReplaceLiteral);
//   _menu_set_state(refactoringMenuHandle, itemIndex, enableReplaceLiteral ? MF_ENABLED : MF_GRAYED, 'P');


   // Local variables aren't available from the symbol browser or the proctree
   if( cmdPrefix == "" ) {
      // local_to_field
      addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "local_to_field", cmdPrefix,cmd, 0, enableLocalToField);
   }

   // global_to_field
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "global_to_field", cmdPrefix, cmd, 0, enableGlobalToField);
//   _menu_set_state(refactoringMenuHandle, itemIndex, enableGlobalToField ? MF_ENABLED : MF_GRAYED, 'P');

   // static_to_instance_method
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "static_to_instance_method", cmdPrefix, cmd, 0, enableStaticToInstanceMethod);
//   _menu_set_state(refactoringMenuHandle, itemIndex, enableStaticToInstanceMethod ? MF_ENABLED : MF_GRAYED, 'P');

   // move field
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "move_field", cmdPrefix, cmd, 0, enableMoveField );
//   _menu_set_state(refactoringMenuHandle, itemIndex, enableMoveField ? MF_ENABLED : MF_GRAYED, 'P');

   // move field
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "move_method", cmdPrefix, cmd, 0, enableMoveMethod);

   // extract_super_class
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "extract_super_class", cmdPrefix, cmd, 0, enableExtractClass);

   // extract_class
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "extract_class", cmdPrefix, cmd, 0, enableExtractClass);

   // encapsulate field
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "encapsulate", cmdPrefix, cmd, 0, enableEncapsulate);
//   _menu_set_state(refactoringMenuHandle, itemIndex, enableEncapsulate ? MF_ENABLED : MF_GRAYED, 'P');

   // pull_up
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "pull_up", cmdPrefix, cmd, 0, enablePullUp);

   // push_down
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "push_down", cmdPrefix, cmd, 0, enablePullUp);

   // modify function parameters
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "modify_params", cmdPrefix, cmd, 0, false);

   if (cm == null) {
      // Extract method
      addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "extract_method", cmdPrefix, cmd, 0, enableExtractMethod);
   }

   // rename
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "rename", cmdPrefix, cmd, 0, enableRename);

   // bar
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "bar", cmdPrefix, cmd, -1, true);

   // Options
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "parse", cmdPrefix, cmd, -1, true);

   // Options
   addSpecificRefactoringMenuItem(refactoringMenuHandle, refactoringTemplateHandle, "options", cmdPrefix, cmd, -1, true);

   // cleanup refactoring menu template
   _menu_destroy(refactoringTemplateHandle);
}

/**
 * Add refactoring menu items to the specified menu for the current symbol at the cursor
 *
 * @param menuHandle Handle of parent menu
 * @param removeIfDisabled
 *                   Remove the refactoring submenu if disabled and this is true
 */
void addRefactoringMenuItemsForCurrentSymbol(int menuHandle, bool removeIfDisabled=true)
{
   if (!_haveRefactoring()) {
      addCPPRefactoringMenuItems(menuHandle, "", null, true);
      addQuickRefactoringMenuItems(menuHandle, "", null, true);
      addAutoImportMenuItems(menuHandle, "", null, true);
      return;
   }

   // get browse information for the tag under the symbol.
   // for supported languages to be as fast as possible
   if (_isEditorCtl(false) && 
       (!_LanguageInheritsFrom("m")) &&
       (_LanguageInheritsFrom("c")    || 
        _LanguageInheritsFrom("cs")   || 
        _LanguageInheritsFrom("java") || 
        _LanguageInheritsFrom("e")    )) {
      tag_init_tag_browse_info(auto cm);
      cm.file_name = p_buf_name;
      cm.language = p_LangId;

      lang := p_LangId;
      VS_TAG_IDEXP_INFO idexp_info;
      struct VS_TAG_RETURN_TYPE visited:[];
      if (!_Embeddedget_expression_info(false, lang, idexp_info, visited)) {

         // fill in just enough information for use in enable/disabling the menu items
         if(idexp_info.lastid != "") {
            cm.member_name = idexp_info.lastid;
            cm.seekpos = idexp_info.lastidstart_offset;
         }
         addCPPRefactoringMenuItems(menuHandle, "", cm, removeIfDisabled);
         addQuickRefactoringMenuItems(menuHandle, "", cm, removeIfDisabled);
         addAutoImportMenuItems(menuHandle, "", cm, removeIfDisabled);
      } else {
         // Find out if there is a literal under the cursor since _Embeddedget_expression_info
         // does not find literals.
         int startSeekPos,endSeekPos;

         _str literal = findLiteralAtCursor( startSeekPos, endSeekPos );
         if( literal != "" ) {
            cm.member_name = literal;
            cm.seekpos = startSeekPos;
            cm.end_seekpos = endSeekPos;
            addCPPRefactoringMenuItems(menuHandle, "", cm, removeIfDisabled);
            addQuickRefactoringMenuItems(menuHandle, "", cm, removeIfDisabled);
            addAutoImportMenuItems(menuHandle, "", cm, removeIfDisabled);
         } else {
            addCPPRefactoringMenuItems(menuHandle, "", cm, removeIfDisabled);
            addQuickRefactoringMenuItems(menuHandle, "", cm, removeIfDisabled);
            addAutoImportMenuItems(menuHandle, "", cm, removeIfDisabled);
         }
      }
   } else {
      addCPPRefactoringMenuItems(menuHandle, "", null, removeIfDisabled);
      addQuickRefactoringMenuItems(menuHandle, "", null, removeIfDisabled);
      addAutoImportMenuItems(menuHandle, "", null, true);
   }
}

/**
 * init-menu callback for the Tools->Refactoring menu
 */
void _init_menu_refactoring(int menuHandle, int noChildWindows)
{
   // find the tools menu
   int toolsMenuHandle;
   if(_menu_find_loaded_menu_caption(menuHandle, "Tools", toolsMenuHandle) < 0) {
      return;
   }

   // populate refactoring submenu
   addRefactoringMenuItemsForCurrentSymbol(toolsMenuHandle, false);
}

/**
 * Show the errors in the specified refactoring transaction
 * in the output toolbar
 * <p>
 * NOTE: This function is no longer called because the errors are
 *       accumulated and displayed immediately after parsing using
 *       a macro callback from the DLL.
 *
 * @param handle Refactoring transaction handle
 *
 * @return the number of errors reported
 */
int showRefactoringErrors(int handle)
{
   if (!_haveRefactoring()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // get the errors
   allErrorStrings := "";
   numErrors := refactor_count_error_files(handle);
   for (i := 0; i < numErrors; i++) {
      filename := "";
      refactor_get_error_file_name(handle,i,filename);
      if (filename=="") continue;
      refactor_show_errors(handle,filename);
   }

   _SccDisplayOutput(allErrorStrings);
   return numErrors;
}

/**
 * Show the modified files in the specified refactoring transaction
 * in the output toolbar
 *
 * @param handle                  Refactoring transaction handle 
 * @param result_name             Form caption to use 
 * @param place_modified_on_left  Reverse position of files so the modified file is on the left
 *
 * @return 0 on success, <0 on error
 */
int showRefactoringModifications(int handle, _str results_name, bool place_modified_on_left=false)
{
   int numMods = refactor_count_modified_files(handle);
   if(numMods <= 0) {
      _message_box("No files were changed.");
      return 0;
   }

   // build list of files that changed
   _str fileList[] = null;
   int i;
   for(i = 0; i < numMods; i++) {
      filename := "";
      refactor_get_modified_file_name(handle, i, filename);
      if(filename != "") {
         fileList[fileList._length()] = filename;
      }
   }

   // show the refactoring results form
   return show("-modal -xy _refactor_results_form", "", "", "refactor", handle, fileList, results_name, place_modified_on_left);
}

/**
 * Get the names of all the compiler configurations in compilers.xml
 */
void refactor_get_compiler_configurations(_str (&c_list)[], _str(&java_list)[], bool generate=false)
{
   if (!_haveBuild()) {
      return;
   }

   // get a list of all compiler configurations
   opened_config_file := false;
   filename := _ConfigPath():+COMPILER_CONFIG_FILENAME;
   if(!refactor_config_is_open(filename)) {
      opened_config_file=true;
      refactor_config_open( filename );
   }

   // generate compilers.xml if it doesn't already exist
   if(generate && refactor_config_count() <= 0 ) {
      generate_default_configs();
   }

   // get each configuration
   compiler_name := "";
   compiler_type := "";
   bool c_compilerHash:[] = null;
   bool java_compilerHash:[] = null;
   int i,n = refactor_config_count();
   for (i=0; i<n; ++i) {
      refactor_config_get_type(i, compiler_type);
      refactor_config_get_name(i, compiler_name);

      // check to see if this name already exists in the hash table
      if (compiler_type :== "cpp") {
         if(c_compilerHash._indexin(compiler_name) == true) {
            continue;
         }
         c_compilerHash:[compiler_name] = true;
         c_list :+= compiler_name;
      } else if (compiler_type :== "java"){
         if(java_compilerHash._indexin(compiler_name) == true) {
            continue;
         }
         java_compilerHash:[compiler_name] = true;
         java_list :+= compiler_name;
      }
   }

   // there is a chance that the *active* config is not in compilers.xml
   if (def_refactor_active_config != "" && !c_compilerHash._indexin(def_refactor_active_config)) {
      c_compilerHash:[def_refactor_active_config] = true;
      c_list :+= def_refactor_active_config;
   }
   if (def_active_java_config != "" && !java_compilerHash._indexin(def_active_java_config)) {
      java_compilerHash:[def_active_java_config] = true;
      java_list :+= def_active_java_config;
   }

   // close the configuration file
   if (!opened_config_file) {
      refactor_config_close();
   }
}

int refactor_build_compiler_tagfile(_str config_name, _str config_type, 
                                    bool quiet=false, bool useThread=false)
{
   if (!_haveBuild()) {
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }

   // construct the path name for the tag file
   filename := _tagfiles_path():+config_name:+TAG_FILE_EXT;
   if (file_exists(filename) && !quiet) {
      int response = _message_box("Warning:\n\nThe file '" filename "' already exists.  Overwrite?", "Visual SlickEdit", MB_OKCANCEL);
      if (response != IDOK) {
         return COMMAND_CANCELLED_RC;
      }
   }

   // open the configuration file
   opened_config_file := false;
   config_file := _ConfigPath():+COMPILER_CONFIG_FILENAME;
   if(!refactor_config_is_open(config_file)) {
      opened_config_file=true;
      int status = refactor_config_open( config_file );
      if (status < 0) {
         return status;
      }
   }

   make_tag_args := "";
   if (config_type == "cpp") {
      wildcards := "";
      i := pos("C/C++ Files",def_file_types);
      if (i) {
         // Set wildcards to this one.
         parse substr(def_file_types,i) with "("wildcards")";
      } else {
         wildcards="*.h;*.cc;*.tcc;*.hpp;*.hxx;*.h++;*.inl;*.cpp";
      }

      // search for STL files
      // this should be strappend(wildcards,";*."), but to avoid some
      // other problems we are doing this
      _str noext_files=_get_langext_files();
      for (;;) {
         _str curfile=parse_file(noext_files);
         if (curfile=="") break;
         strappend(wildcards,";"curfile);
      }

      // get the include directories for this configuration
      maybeExcludeVersions := "";
      includePathArgs := "";
      n := refactor_config_count_includes( config_name );
      for (i=0; i<n; ++i) {
         includePath := "";
         refactor_config_get_include( config_name, i, includePath );
         _maybe_append_filesep(includePath);

         // don't search for Frameworks when tagging a compiler as there is a separate
         // section of the autotag dialog to handle frameworks
         if (includePath:!="/System/Library/Frameworks/") {
            _str temp_wildcards=wildcards;
            _str cur_wildcard;

            while (temp_wildcards:!="") {
               parse temp_wildcards with cur_wildcard ";" temp_wildcards;
               strappend(includePathArgs, ' "':+includePath:+cur_wildcard:+'"');
            }
         }
         // Exclude "Versions" subdirectory when parsing frameworks dirs
         if (pos("/Frameworks/", includePath) > 0 && pos("/Library/", includePath) > 0) {
            maybeExcludeVersions :+= " -E Versions/";
            maybeExcludeVersions :+= " -E " _maybe_quote_filename("Headers 1/");
         }
      }
      make_tag_args = "+t -C -o ":+_maybe_quote_filename(filename):+" ":+includePathArgs:+maybeExcludeVersions;
   } else if (config_type == "java") {
   
      src_root := "";
      refactor_config_get_java_source(config_name, src_root);
   
      tree_option := "-t ";
      _str cmd_args = create_java_autotag_args(src_root);
      if (_isUnix()) {
         if (!pos("*.java", cmd_args)) {
            // We really need this if we are tagging kaffe because we will be searching
            // everthing under "/usr/share".  This code is also useful when we are just
            // tagging specific jar or zip files.  This code might work well for Windows
            // too.
            tree_option="";
         }
      }
      make_tag_args = tree_option" -C -o ":+_maybe_quote_filename(filename):+" ":+cmd_args;
   }
   

   // finally, close the compiler configuration file
   if (opened_config_file) {
      refactor_config_close();
   }

   if (make_tag_args == "") {
      return (COMMAND_CANCELLED_RC);
   }

   if (useThread) {
      make_tag_args = "-b ":+make_tag_args;
   }

   int status = make_tags(make_tag_args);
   if (!status) {
      // invoke the tagfiles change callbacks
      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,"","");
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }
   return status;
}

void generate_default_configs()
{
   if (!_haveBuild()) {
      return;
   }

   int i;
   _str config_names[],config_includes[],header_names[];
   _str java_config_names[], java_config_sources[]/*, java_config_bins[]*/;
   _str filename = _ConfigPath():+COMPILER_CONFIG_FILENAME;

   config_names._makeempty();
   config_includes._makeempty();
   header_names._makeempty();
   java_config_names._makeempty();
   java_config_sources._makeempty();
//   java_config_bins._makeempty();

   getCppIncludeDirectories( config_names, config_includes, header_names );

//   say("num includes = " config_names._length() );
   for( i = 0 ; i < config_names._length() ; i++ ) {
//      say("config = " i " name = " config_names[i] " header = " header_names[i] " includes = " config_includes[i] );
      refactor_config_add( config_names[i], header_names[i], config_includes[i] );
   }

   jdkPath := "";
   getJavaIncludePath(java_config_sources, jdkPath, java_config_names);

   for (i = 0; i < java_config_names._length(); i++) {
      _str jars = java_get_jdk_jars(java_config_sources[i]);
      refactor_config_add_java(java_config_names[i], java_config_sources[i], jars);
   }

   refactor_config_save( filename );
   _GetLatestCompiler(true, false);

//   if( def_rf_active_config == "" ) {
//      _config_modify_flags(CFGMODIFY_DEFVAR);
//      refactor_config_get_name(0, def_rf_active_config );
//   }
}


void get_cpp_compiler_configs(CompilerConfiguration (&configs)[])
{
   if (!_haveBuild()) {
      return;
   }

   filename := _ConfigPath():+COMPILER_CONFIG_FILENAME;
   config_is_open := refactor_config_is_open( filename )!=0;
   refactor_config_open( filename );

   if( refactor_config_count() <= 0 ) {
      generate_default_configs();
   }

   compiler_name := "";
   compiler_type := "";

   int num_configs = refactor_config_count();
   int num_includes;

   int config_index;
   int include_index;
   num_c_configs := 0;

   for (config_index=0; config_index<num_configs; ++config_index) {
      refactor_config_get_type(config_index,compiler_type); 
      if (compiler_type :== "cpp") {
         refactor_config_get_name(config_index, compiler_name);
   
         configs[num_c_configs].configuarationName=compiler_name;
         refactor_config_get_header(compiler_name,configs[num_c_configs].systemHeader);
         // workaround for bug in refactor_config_get_header() when header is encoded with environment variable
         if (pos("%", configs[num_c_configs].systemHeader)) {
            env_pos := pos("%SLICKEDITCONFIGVERSION%", configs[num_c_configs].systemHeader);
            if (env_pos > 0) {
               configs[num_c_configs].systemHeader = substr(configs[num_c_configs].systemHeader, env_pos);
            }
            env_pos = pos("%SLICKEDITCONFIG%", configs[num_c_configs].systemHeader);
            if (env_pos > 0) {
               configs[num_c_configs].systemHeader = substr(configs[num_c_configs].systemHeader, env_pos);
            }
            env_pos = pos("%VSLICKCONFIG%", configs[num_c_configs].systemHeader);
            if (env_pos > 0) {
               configs[num_c_configs].systemHeader = substr(configs[num_c_configs].systemHeader, env_pos);
            }
            env_pos = pos("%VSROOT%", configs[num_c_configs].systemHeader);
            if (env_pos > 0) {
               configs[num_c_configs].systemHeader = substr(configs[num_c_configs].systemHeader, env_pos);
            }
         }
         configs[num_c_configs].systemHeader = _replace_envvars(configs[num_c_configs].systemHeader);

         num_includes=refactor_config_count_includes(compiler_name);
         for (include_index=0; include_index<num_includes; ++include_index) {
            refactor_config_get_include(compiler_name,include_index,configs[num_c_configs].systemIncludes[include_index]);
         }
         num_c_configs++;
      }
   }

   if (!config_is_open) {
      refactor_config_close();
   }
}

void write_cpp_compiler_configs(CompilerConfiguration (&configs)[])
{
   if (!_haveBuild()) {
      return;
   }

   filename := _ConfigPath():+COMPILER_CONFIG_FILENAME;
   config_is_open := refactor_config_is_open( filename )!=0;
   refactor_config_open( filename );

   refactor_config_delete_all_type("cpp");

   for (config_index:=0;config_index<configs._length();++config_index) {
      all_includes := "";
      int inc_index;
      for (inc_index=0;inc_index<configs[config_index].systemIncludes._length();++inc_index) {
         if (inc_index==0) {
            all_includes=configs[config_index].systemIncludes[inc_index];
         } else {
            strappend(all_includes,PATHSEP:+configs[config_index].systemIncludes[inc_index]);
         }
      }
      system_header := _encode_vslickconfig(configs[config_index].systemHeader, true, false);
      refactor_config_add(configs[config_index].configuarationName, system_header, all_includes);
   }

   refactor_config_save(filename);

   if (!config_is_open) {
      refactor_config_close();
   }
}

static bool isNotDot(_str dirName)
{
   dirLength := length(dirName);

   lastChars := substr(dirName,dirLength - 2);

   if (lastChars:==(FILESEP"."FILESEP)) {
      return false;
   }

   lastChars = substr(dirName,dirLength - 3);

   if (lastChars:==(FILESEP".."FILESEP)) {
      return false;
   }

   return true;
}

static _str findDDKIncludes(_str version)
{
   _str instDir =_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\WINDDK\'version,"","LFNDirectory");
   if (instDir == "") {
      return "";
   }
   _maybe_append_filesep(instDir);

   // file_match can not be used in recursive functions
   _str incDirs[];
   checked := 0;

   baseInc :=  instDir:+"inc":+FILESEP;
   incDirs[incDirs._length()] = baseInc;

   while (checked < incDirs._length()) {
      incDir := file_match(incDirs[checked]" +D +X", 1);

      while (incDir != "") {
         if (isNotDot(incDir)) {
            incDirs[incDirs._length()] = incDir;
         }
         incDir = file_match(incDirs[checked]" +D +X", 0);
      }
      ++checked;
   }

   incDirs._sort("DF");

   checked = incDirs._length() - 1;

   while (checked >= 0) {
      strappend(instDir, PATHSEP);
      strappend(instDir, incDirs[checked]);
      --checked;
   }

   return instDir;
}

_str _get_vs_sys_includes(_str config_name)
{
   include_path := "";
   has_macros := false;
   do_default := true;


   if (_isWindows()) {
      do_default=false;
      switch (config_name) {
      case COMPILER_NAME_VS6:
         include_path = _ntRegQueryValue(HKEY_CURRENT_USER,
                                         'Software\Microsoft\DevStudio\6.0\Build System\Components\Platforms\Win32 (x86)\Directories',
                                         "","Include Dirs");
         break;
      case COMPILER_NAME_VSDOTNET:
         include_path = _ntRegQueryValue(HKEY_LOCAL_MACHINE,
                                         'SOFTWARE\Microsoft\VisualStudio\7.0\VC\VC_OBJECTS_PLATFORM_INFO\Win32\Directories',
                                         "","Include Dirs");
         has_macros=true;
         break;
      case COMPILER_NAME_VS2003:
         include_path = _ntRegQueryValue(HKEY_LOCAL_MACHINE,
                                         'SOFTWARE\Microsoft\VisualStudio\7.1\VC\VC_OBJECTS_PLATFORM_INFO\Win32\Directories',
                                         "","Include Dirs");
         has_macros=true;
         break;
      case COMPILER_NAME_VS2005_EXPRESS:
         {
            _str myDocumentsPath;
            ntGetSpecialFolderPath(myDocumentsPath,CSIDL_PERSONAL);
            _maybe_append_filesep(myDocumentsPath);
            //_message_box("myDocumentsPath="myDocumentsPath);
            // Try to open the user settings
            vcSettingsFilename := myDocumentsPath:+'\Visual Studio 2005\Settings\C++ Express\CurrentSettings.vssettings';
            int status;
            int handle=_xmlcfg_open(vcSettingsFilename,status,VSXMLCFG_OPEN_ADD_PCDATA);
            //_message_box("handle="handle" vcSettingsFilename="vcSettingsFilename);
            if (handle<0) {
               // Now try to open the global settings file for VC
               //'c:\Program Files\Microsoft Visual Studio 8\VC\Profile\VCExpress.vssettings'
               vcSettingsFilename=_ntRegQueryValue(HKEY_LOCAL_MACHINE,
                                                   'SOFTWARE\Microsoft\VCExpress\8.0\Setup\VC',
                                                   "", "ProductDir");
               _maybe_append_filesep(vcSettingsFilename);
               vcSettingsFilename :+= 'Profile\VCExpress.vssettings';
               handle=_xmlcfg_open(vcSettingsFilename,status,VSXMLCFG_OPEN_ADD_PCDATA);
               //_message_box("handle="handle" vcSettingsFilename="vcSettingsFilename);
            }
            if (handle<0) {
            } else {
               int node=_xmlcfg_find_simple(handle,"/UserSettings/ToolsOptions/ToolsOptionsCategory[@name='Projects']/ToolsOptionsSubCategory[@name='VCDirectories']/PropertyValue[@name='IncludeDirectories']");
               //int node=_xmlcfg_find_simple(handle,"//PropertyValue[@name='IncludeDirectories']");
               if (node>=0) {
                  node=_xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_PCDATA);
                  if (node>=0) {
                     parse _xmlcfg_get_value(handle,node) with "Win32" "|" include_path "|";
                     //_message_box("h2 value="_xmlcfg_get_value(handle,node));
                     //_message_box("include_path="include_path);
                     has_macros=true;
                  }
               }
               _xmlcfg_close(handle);
            }

            break;
         }
      case COMPILER_NAME_VS2005:  // Tested with Standard Edition
         {
            _str myDocumentsPath;
            ntGetSpecialFolderPath(myDocumentsPath,CSIDL_PERSONAL);
            _maybe_append_filesep(myDocumentsPath);
            // Try to open the user settings
            vcSettingsFilename := myDocumentsPath:+'\Visual Studio 2005\Settings\CurrentSettings.vssettings';
            int status;
            int handle=_xmlcfg_open(vcSettingsFilename,status,VSXMLCFG_OPEN_ADD_PCDATA);
            if (handle<0) {
               // Now try to open the global settings file for VC
               //'c:\Program Files\Microsoft Visual Studio 8\Common7\IDE\Profiles\VC.vssettings'
               vcSettingsFilename=_ntRegQueryValue(HKEY_LOCAL_MACHINE,
                                                   'SOFTWARE\Microsoft\VisualStudio\8.0\Setup\VS',
                                                   "","EnvironmentDirectory");
               _maybe_append_filesep(vcSettingsFilename);
               vcSettingsFilename :+= 'Profiles\VC.vssettings';
               handle=_xmlcfg_open(vcSettingsFilename,status,VSXMLCFG_OPEN_ADD_PCDATA);
            }
            if (handle<0) {
            } else {
               int node=_xmlcfg_find_simple(handle,"/UserSettings/ToolsOptions/ToolsOptionsCategory[@name='Projects']/ToolsOptionsSubCategory[@name='VCDirectories']/PropertyValue[@name='IncludeDirectories']");
               //int node=_xmlcfg_find_simple(handle,"//PropertyValue[@name='IncludeDirectories']");
               if (node>=0) {
                  node=_xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_PCDATA);
                  if (node>=0) {
                     parse _xmlcfg_get_value(handle,node) with "Win32" "|" include_path "|";
                     //_message_box("h2 value="_xmlcfg_get_value(handle,node));
                     //_message_box("2005 includ_path="include_path);
                     has_macros=true;
                  }
               }
               _xmlcfg_close(handle);
            }
      #if 0
            _str LocalAppDataDir = _ntGetRegistryValue(HKEY_CURRENT_USER,
                                                       'Software\Microsoft\Windows\CurrentVersion\Explorer',
                                                       "Shell Folders","Local AppData",false);
            _str abs_vccomponents = LocalAppDataDir;
            _maybe_append_filesep(abs_vccomponents);
            strappend(abs_vccomponents,"Microsoft":+FILESEP:+"VisualStudio":+FILESEP:+"8.0":+FILESEP:+"VCComponents.dat");
            //_message_box(abs_vccomponents);
            _ini_get_value(abs_vccomponents,
                           'VC\VC_OBJECTS_PLATFORM_INFO\Win32\Directories',
                           "Include Dirs",
                           include_path);
            _message_box("include_path="include_path);
      #endif
            break;
         }
      case COMPILER_NAME_VS2008_EXPRESS:
         {
            _str myDocumentsPath;
            ntGetSpecialFolderPath(myDocumentsPath,CSIDL_PERSONAL);
            _maybe_append_filesep(myDocumentsPath);
            //_message_box("myDocumentsPath="myDocumentsPath);
            // Try to open the user settings
            vcSettingsFilename := myDocumentsPath:+'\Visual Studio 2008\Settings\C++ Express\CurrentSettings.vssettings';
            int status;
            int handle=_xmlcfg_open(vcSettingsFilename,status,VSXMLCFG_OPEN_ADD_PCDATA);
            //_message_box("handle="handle" vcSettingsFilename="vcSettingsFilename);
            if (handle<0) {
               // Now try to open the global settings file for VC
               //'c:\Program Files\Microsoft Visual Studio 8\VC\Profile\VCExpress.vssettings'
               vcSettingsFilename=_ntRegQueryValue(HKEY_LOCAL_MACHINE,
                                                   'SOFTWARE\Microsoft\VCExpress\9.0\Setup\VC',
                                                   "", "ProductDir");
               _maybe_append_filesep(vcSettingsFilename);
               vcSettingsFilename :+= 'Profile\VCExpress.vssettings';
               handle=_xmlcfg_open(vcSettingsFilename,status,VSXMLCFG_OPEN_ADD_PCDATA);
               //_message_box("handle="handle" vcSettingsFilename="vcSettingsFilename);
            }
            if (handle<0) {
            } else {
               int node=_xmlcfg_find_simple(handle,"/UserSettings/ToolsOptions/ToolsOptionsCategory[@name='Projects']/ToolsOptionsSubCategory[@name='VCDirectories']/PropertyValue[@name='IncludeDirectories']");
               //int node=_xmlcfg_find_simple(handle,"//PropertyValue[@name='IncludeDirectories']");
               if (node>=0) {
                  node=_xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_PCDATA);
                  if (node>=0) {
                     parse _xmlcfg_get_value(handle,node) with "Win32" "|" include_path "|";
                     //_message_box("h2 value="_xmlcfg_get_value(handle,node));
                     //_message_box("include_path="include_path);
                     has_macros=true;
                  }
               }
               _xmlcfg_close(handle);
            }

            break;
         }
      case COMPILER_NAME_VS2008:  // Tested with Standard Edition
         {
            _str myDocumentsPath;
            ntGetSpecialFolderPath(myDocumentsPath,CSIDL_PERSONAL);
            _maybe_append_filesep(myDocumentsPath);
            // Try to open the user settings
            vcSettingsFilename := myDocumentsPath:+'\Visual Studio 2008\Settings\CurrentSettings.vssettings';
            int status;
            int handle=_xmlcfg_open(vcSettingsFilename,status,VSXMLCFG_OPEN_ADD_PCDATA);
            if (handle<0) {
               // Now try to open the global settings file for VC
               //'c:\Program Files\Microsoft Visual Studio 8\Common7\IDE\Profiles\VC.vssettings'
               vcSettingsFilename=_ntRegQueryValue(HKEY_LOCAL_MACHINE,
                                                   'SOFTWARE\Microsoft\VisualStudio\9.0\Setup\VS',
                                                   "","EnvironmentDirectory");
               _maybe_append_filesep(vcSettingsFilename);
               vcSettingsFilename :+= 'Profiles\VC.vssettings';
               handle=_xmlcfg_open(vcSettingsFilename,status,VSXMLCFG_OPEN_ADD_PCDATA);
            }
            if (handle<0) {
            } else {
               int node=_xmlcfg_find_simple(handle,"/UserSettings/ToolsOptions/ToolsOptionsCategory[@name='Projects']/ToolsOptionsSubCategory[@name='VCDirectories']/PropertyValue[@name='IncludeDirectories']");
               //int node=_xmlcfg_find_simple(handle,"//PropertyValue[@name='IncludeDirectories']");
               if (node>=0) {
                  node=_xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_PCDATA);
                  if (node>=0) {
                     parse _xmlcfg_get_value(handle,node) with "Win32" "|" include_path "|";
                     //_message_box("h2 value="_xmlcfg_get_value(handle,node));
                     //_message_box("include_path="include_path);
                     has_macros=true;
                  }
               }
               _xmlcfg_close(handle);
            }
      #if 0
            _str LocalAppDataDir = _ntGetRegistryValue(HKEY_CURRENT_USER,
                                                       'Software\Microsoft\Windows\CurrentVersion\Explorer',
                                                       "Shell Folders","Local AppData",false);
            _str abs_vccomponents = LocalAppDataDir;
            _maybe_append_filesep(abs_vccomponents);
            strappend(abs_vccomponents,"Microsoft":+FILESEP:+"VisualStudio":+FILESEP:+"9.0":+FILESEP:+"VCComponents.dat");
            //_message_box(abs_vccomponents);
            _ini_get_value(abs_vccomponents,
                           'VC\VC_OBJECTS_PLATFORM_INFO\Win32\Directories',
                           "Include Dirs",
                           include_path);
            _message_box("include_path="include_path);
      #endif
            break;
         }

      case COMPILER_NAME_VS2010:  
      case COMPILER_NAME_VS2010_EXPRESS:
         {
            _str VCINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7", "", "10.0");
            do {
               if (VCINSTALLDIR != "") break;
               VCINSTALLDIR = _ntRegQueryValue(HKEY_CURRENT_USER, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7", "", "10.0");
               if (VCINSTALLDIR != "") break;
               VCINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VC7", "", "10.0");
               if (VCINSTALLDIR != "") break;
               VCINSTALLDIR = _ntRegQueryValue(HKEY_CURRENT_USER, "SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VC7", "", "10.0");
            } while (false);

            _str SDKINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v7.0A", "", "InstallationFolder");
            do {
               if (SDKINSTALLDIR != "") break;
               SDKINSTALLDIR = _ntRegQueryValue(HKEY_CURRENT_USER, "SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v7.0A", "", "InstallationFolder");
               if (SDKINSTALLDIR != "") break;
               if (VCINSTALLDIR != "") {
                  SDKINSTALLDIR = VCINSTALLDIR:+'\PlatformSDK\';
               }
            } while (false);

            if (VCINSTALLDIR != "") {
               strappend(include_path, VCINSTALLDIR:+"INCLUDE":+FILESEP);
               strappend(include_path, ";");
               strappend(include_path, VCINSTALLDIR:+'ATLMFC\INCLUDE':+FILESEP);
            }
            if (SDKINSTALLDIR != "") {
               if (include_path != "") {
                  strappend(include_path, ";");
               }
               strappend(include_path, SDKINSTALLDIR:+"include":+FILESEP);
            }
            break;
         }

      case COMPILER_NAME_VS2012:  
      case COMPILER_NAME_VS2012_EXPRESS:  
      case COMPILER_NAME_VS2013:  
      case COMPILER_NAME_VS2013_EXPRESS:  
      case COMPILER_NAME_VS2015:  
      case COMPILER_NAME_VS2015_EXPRESS:  
         {
            target_version := "11.0";
            if (config_name==COMPILER_NAME_VS2015 || config_name==COMPILER_NAME_VS2015_EXPRESS) {
               target_version="14.0";
            } else if (config_name==COMPILER_NAME_VS2013 || config_name==COMPILER_NAME_VS2013_EXPRESS) {
               target_version="12.0";
            }
            _str VCINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7", "", target_version);
            do {
               if (VCINSTALLDIR != "") break;
               VCINSTALLDIR = _ntRegQueryValue(HKEY_CURRENT_USER, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7", "", target_version);
               if (VCINSTALLDIR != "") break;
               VCINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VC7", "", target_version);
               if (VCINSTALLDIR != "") break;
               VCINSTALLDIR = _ntRegQueryValue(HKEY_CURRENT_USER, "SOFTWARE\\Wow6432Node\\Microsoft\\VisualStudio\\SxS\\VC7", "", target_version);
            } while (false);

            if (VCINSTALLDIR != "") {
               strappend(include_path, VCINSTALLDIR:+"INCLUDE":+FILESEP);
               strappend(include_path, ";");
               strappend(include_path, VCINSTALLDIR:+'ATLMFC\INCLUDE':+FILESEP);
            }

            // HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Kits\Installed Roots .. KitsRoot
            // 2012 = KitsRoot
            // 2013 = KitsRoot81
            extradir := "";
            KitsRoot := "KitsRoot";
            if (config_name==COMPILER_NAME_VS2013 || config_name==COMPILER_NAME_VS2013_EXPRESS) {
               KitsRoot="KitsRoot81";
            } else if (config_name==COMPILER_NAME_VS2015 || config_name==COMPILER_NAME_VS2015_EXPRESS) {
               extradir="10.0.10240.0":+FILESEP;
               KitsRoot="KitsRoot10";
            }

            SDKINSTALLDIR := _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots", "", KitsRoot);
            do {
               if (SDKINSTALLDIR != "") break;
               SDKINSTALLDIR = _ntRegQueryValue(HKEY_CURRENT_USER, "SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots", "", KitsRoot);
            } while (false);


            // iterate over windows kit 10 versions to find the newest one with windows.h
            if (SDKINSTALLDIR != "" && KitsRoot=="KitsRoot10") {
               versionDir := dir_match(SDKINSTALLDIR:+"Include":+FILESEP:+"10.*", true);
               while (versionDir != "") {
                  unquotedVersionDir := _maybe_unquote_filename(versionDir);
                  unquotedVersionDir = strip(unquotedVersionDir,'T',FILESEP);
                  if (file_exists(unquotedVersionDir:+FILESEP:+"um":+FILESEP:+"windows.h")) {
                     extradir = _strip_filename(unquotedVersionDir,'P'):+FILESEP;
                  }
                  versionDir = dir_match(SDKINSTALLDIR:+"Include":+FILESEP:+"10.*", false);
               }
            }

            NETFXSDKDir := _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Microsoft SDKs\\NETFXSDK\\4.6.1", "", "KitsInstallationFolder");
            if (NETFXSDKDir != '') {
               NETFXSDKDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Microsoft SDKs\\NETFXSDK\\4.6", "", "KitsInstallationFolder");
            }

            if (SDKINSTALLDIR != "") {
                if (config_name==COMPILER_NAME_VS2015 || config_name==COMPILER_NAME_VS2015_EXPRESS) {
                  // Files like stdio.h are here
                   if (include_path != "") {
                      strappend(include_path, ";");
                   }
                  strappend(include_path, SDKINSTALLDIR:+"Include":+FILESEP:+extradir:+"ucrt":+FILESEP);
               }
               if (include_path != "") {
                  strappend(include_path, ";");
               }
               strappend(include_path, SDKINSTALLDIR:+"include":+FILESEP:+extradir:+"shared":+FILESEP);
               strappend(include_path, ";");
               strappend(include_path, SDKINSTALLDIR:+"include":+FILESEP:+extradir:+"um":+FILESEP);
               strappend(include_path, ";");
               strappend(include_path, SDKINSTALLDIR:+"include":+FILESEP:+extradir:+"winrt":+FILESEP);
            }
            if (NETFXSDKDir != '') {
               if (include_path != "") {
                  strappend(include_path, ";");
               }
               strappend(include_path, NETFXSDKDir:+"include":+FILESEP:+"um":+FILESEP);
            }
   #if 0
            if (config_name==COMPILER_NAME_VS2012_EXPRESS 
                || config_name==COMPILER_NAME_VS2013_EXPRESS) {
               SDKINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v7.1A", "", "InstallationFolder");
               do {
                  if (SDKINSTALLDIR != "") break;
                  SDKINSTALLDIR = _ntRegQueryValue(HKEY_CURRENT_USER, "SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v7.1A", "", "InstallationFolder");
               } while (false);

               if (SDKINSTALLDIR != "") {
                  if (include_path != "") {
                     strappend(include_path, ";");
                  }
                  strappend(include_path, SDKINSTALLDIR:+"include":+FILESEP);
               }
            }
   #endif
            break;
         }

      case COMPILER_NAME_VS2017:
      case COMPILER_NAME_VS2019:
         major_version := 15;
         target_version := "15.0";
         if (config_name == COMPILER_NAME_VS2019) {
            major_version = 16;
            target_version = "16.0";
         }
         VSINSTALLDIR := _getVStudioInstallPath2017(major_version);
         if (VSINSTALLDIR == '') {
            VSINSTALLDIR = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7", "", target_version); 
         }
         if (VSINSTALLDIR != '') {
            VCINSTALLDIR :=  VSINSTALLDIR:+'VC':+FILESEP;
            _str __VCVARS_TOOLS_VERSION = _getVCToolsVersion2017(VCINSTALLDIR, major_version);
            if (__VCVARS_TOOLS_VERSION != '') {
               VCToolsInstallDir := VCINSTALLDIR:+'Tools\MSVC\':+__VCVARS_TOOLS_VERSION:+FILESEP;
               strappend(include_path, VCToolsInstallDir:+'include':+FILESEP);
               strappend(include_path, ';');
               strappend(include_path, VCToolsInstallDir:+'ATLMFC\include':+FILESEP);
            }
         }

         extradir := "";
         KitsRoot := "KitsRoot10";
         SDKINSTALLDIR := _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows Kits\Installed Roots', '', KitsRoot);
         do {
            if (SDKINSTALLDIR != "") break;
            SDKINSTALLDIR = _ntRegQueryValue(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\Windows Kits\Installed Roots', '', KitsRoot);
         } while (false);

         // iterate over windows kit 10 versions to find the newest one with windows.h
         if (SDKINSTALLDIR != "" && KitsRoot=="KitsRoot10") {
            versionDir := dir_match(SDKINSTALLDIR:+"Include":+FILESEP:+"10.*", true);
            while (versionDir != "") {
               unquotedVersionDir := _maybe_unquote_filename(versionDir);
               unquotedVersionDir = strip(unquotedVersionDir,'T',FILESEP);
               if (file_exists(unquotedVersionDir:+FILESEP:+"um":+FILESEP:+"windows.h")) {
                  extradir = _strip_filename(unquotedVersionDir,'P'):+FILESEP;
               }
               versionDir = dir_match(SDKINSTALLDIR:+"Include":+FILESEP:+"10.*", false);
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

         if (SDKINSTALLDIR != "") {
            if (include_path != "") {
               strappend(include_path, ";");
            }
            strappend(include_path, SDKINSTALLDIR:+"include":+FILESEP:+extradir:+"shared":+FILESEP);
            strappend(include_path, ";");
            strappend(include_path, SDKINSTALLDIR:+"include":+FILESEP:+extradir:+"um":+FILESEP);
            strappend(include_path, ";");
            strappend(include_path, SDKINSTALLDIR:+"include":+FILESEP:+extradir:+"winrt":+FILESEP);
            strappend(include_path, ";");
            strappend(include_path, SDKINSTALLDIR:+"include":+FILESEP:+extradir:+"ucrt":+FILESEP);
         }
         if (NETFXSDKDir != '') {
            if (include_path != "") {
               strappend(include_path, ";");
            }
            strappend(include_path, NETFXSDKDir:+"include":+FILESEP:+"um":+FILESEP);
         }
         break;

      case COMPILER_NAME_VCPP_TOOLKIT2003:
         include_path=getVcppToolkitPath2003();
         _maybe_append_filesep(include_path);
         strappend( include_path, "include":+FILESEP);
         break;
      case COMPILER_NAME_PLATFORM_SDK2003:
         include_path=getVcppPlatformSDKPath2003();
         _maybe_append_filesep(include_path);
         strappend( include_path, "include":+FILESEP);
         if (file_exists(include_path:+"crt":+FILESEP:+"stdio.h")) {
            strappend(include_path,";");
            strappend(include_path,getVcppPlatformSDKPath2003());
            _maybe_append_filesep(include_path);
            strappend( include_path, "include":+FILESEP:+"crt":+FILESEP);
         } else {
            _str toolkitPath = getVcppToolkitPath2003();
            if (toolkitPath != "") {
               strappend(include_path,";");
               strappend(include_path,toolkitPath);
               _maybe_append_filesep(include_path);
               strappend( include_path, "include":+FILESEP);
            }
         }
         break;
      default:
         do_default=true;
      }
   }
   if (do_default) {
      version := "";
      parse config_name with (COMPILER_NAME_DDK:+" - ") version;
      if (version!="") {
         include_path = findDDKIncludes(version);
      }
   }

   if (include_path!="") {
      if (has_macros) {
         include_path = _expand_all_vs_macros(config_name,include_path,-1,-1);
         if (substr(include_path,1,2)!='\\' && !pos(';\\'include_path)) {
            // This works as long as there are no unc names as include directories
            include_path=stranslate(include_path,'\','\\');
         }
      }
   }
   /*
      Visual Studio 2008 has duplicates of
         C:\Program Files\Microsoft SDKs\Windows\v6.0A\include
   */
   // Remove duplicates
   bool hash:[];
   result := "";
   for (;;) {
      _str path;
      parse include_path with path ";" include_path;
      if (path!="") {
      } else if (include_path=="") {
         break;
      }
      if (!hash._indexin(_file_case(path))) {
         hash:[_file_case(path)]=true;
         if (result=="") {
            result=path;
         } else {
            result :+= ";"path;
         }
      }
   }

   return result;
}

