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
#include "toolbar.sh"
#include "blob.sh"
#include "xml.sh"
#include "color.sh"
#include "eclipse.sh"
#import "se/lang/api/LanguageSettings.e"
#import "se/alias/AliasFile.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/twautohide.e"
#import "asm.e"
#import "autosave.e"
#import "bind.e"
#import "cbrowser.e"
#import "cobol.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "compile.e"
#import "context.e"
#import "c.e"
#import "cfcthelp.e"
#import "cjava.e"
#import "csymbols.e"
#import "ctags.e"
#import "cua.e"
#import "cutil.e"
#import "docsearch.e"
#import "env.e"
#import "error.e"
#import "fileman.e"
#import "files.e"
#import "guicd.e"
#import "help.e"
#import "html.e"
#import "listproc.e"
#import "main.e"
#import "menu.e"
#import "mfsearch.e"
#import "mouse.e"
#import "mprompt.e"
#import "notifications.e"
#import "perl.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "pushtag.e"
#import "quickrefactor.e"
#import "refactor.e"
#import "search.e"
#import "seldisp.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tagfind.e"
#import "taggui.e"
#import "tagrefs.e"
#import "tbxmloutline.e"
#import "util.e"
#import "wkspace.e"
#import "xmlcfg.e"
#endregion

using namespace se.lang.api;
/*
   This module is a general purpose engine for providing searching and
   completion for tagged function names.  To avoid update problems, do not
   modify this file or "maketags.e" if possible.  Place your tag support
   procedures for other languages in another file. See below.

   To add support for another language define two global (not static)
   procedures with the following name format and function:

   ------------------------------------------------------------------
   int "ext"_proc_search(   _str &proc_name
                            ,int find_first
                            ,_str extension
                          [ ,int StartFromCursor ]
                          [ ,int StartSeekPos ]
                        )

   Purpose

      Search for any tag or a specific tag.  One of the more difficult
      features features of this function is its ability to support
      find_first/find_next.  Performing a find_next when find_first==0
      means you need to preserve some parsing state information about where
      you were last time so you can continue parsing this time.

   Parameters

      proc_name        Call by reference interpreter variable.
                       If this is "", then we are looking for any tag.
                       If not "", then we are looking for a specific tag.
                       The tag type, if specified, follows the tag name
                       in parenthesis.  Examples:

                          "main(proc)"
                          "mymethod(myclass:proc)"
                          "mymethod(myunit/myclass:proc)"

                       The tag type can be anything, but it is best to
                       use existing tag types, see SE_TAG_TYPE_* for the
                       lexicon.  If your language has packages, modules,
                       or some other namespace or unit concept, the
                       package name needs to be separated from the class
                       name using a forward slash / (VS_TAGSEPARATOR_package)

      find_first       If non-zero, return the first tag.
                       Otherwise, continue searching for another occurrence.

   Interpreter Parameters [optional]

      extension        File extension (not used)

      StartFromCursor  Optional.  IF given, specifies to start scan
                       from the current offset in the current buffer.
                       Ignored if find_first==0.

      StopSeekPos      Optional.  If given, specifices the
                       seek position to stop searching at.

                       At the moment, this only given when
                       looking for locals.  Its purpose is
                       to stop searching for locals after
                       the cursor location (which is/was StopSeekPos).
                       This is so that variables declared after the cursor
                       do not appear when listing symbols.

   Returns 0 if a procedure is found, non-zero otherwise.

   Other notes:

       See one of the procedures mod_proc_search, asm_proc_search,
       or tcl_proc_search for an example.  Note that c_proc_search
       has been defined in the cparse.dll.

   ------------------------------------------------------------------
   vs"ext"_list_tags(     int output_view_id
                         ,_str file_name
                         ,_str extension
                         ,int list_tags_flags
                       [ ,int tree_wid ]
                       [ ,int func_bitmap ]
                       [ ,int StartFromCursor ]
                       [ ,int StartSeekPos ]
                     )

   Purpose

      List global or local tags, and insert tags directly into
      tag database or current context.  Note that this function is
      normally implemented in a DLL for performance.

   Parameters

      output_view_id    Unused, obsolete, always zero.

      file_name         If not "" , specifies the name of the file on disk
                        to be tagged.  If zero, tag the current buffer.

   Interpreter Parameters

      extension         Not used.

      list_tags_flags   List tags bit flags. Valid flags are:

         VSLTF_SKIP_OUT_OF_SCOPE      Skip locals that are not in scope
         VSLTF_SET_TAG_CONTEXT        Set tagging context at cursor position
         VSLTF_LIST_OCCURRENCES       Insert references into tags database
         VSLTF_START_LOCALS_IN_CODE   Parse locals without first parsing header
         VSLTF_NO_SAVE_COMMENTS       Do not save documentation comments

      tree_wid          Unused, obsolete, always zero.

      func_bitmap       Unused, obsolete, always zero.

      StartFromCursor   Optional.  IF given, specifies to start scan from
                        the current offset in the current buffer.

      StopSeekPos       Optional.  If given, specifices the seek
                        position to stop searching at.

                        At the moment, this only given when
                        looking for locals.  Its purpose is
                        to stop searching for locals after
                        the cursor location (which is/was StopSeekPos).
                        This is so that variables declared after the cursor
                        do not appear when listing symbols.

   Returns 0 on success, <0 on error.

   Other notes:

      List tags inserts tags directly into the database, or into the
      current context, using the tagging database functions
      tag_insert_tag() or tag_insert_context(), respectively.

   ------------------------------------------------------------------
   While the "ext"_proc_search function can do everything that's required,
   you might find it difficult to restart a recursive descent parser in
   the middle of some calls.  Also, it is possible to pass more information
   to the tagging engine through the tag_insert_tag() and tag_insert_context()
   routines than you can pass back using proc-search.

   You can implement either one or both of "ext"_proc_search and
   vs"ext"_list_tags.  However, if SlickEdit will always prefer
   to use the list tags function if one is available, so it is not
   necessary to implement both functions.

      var          A variable definition
      proc         A function/procedure definition
      proto        A prototype/forward declaration for a
                   function/procedure
      ClassName:proc    A function/procedure definition for class
                        ClassName
      ClassName:proto   A prototype/forward declaration for a
                        function/procedure for class ClassName.

   "ext" is the extension of the file.

   NOTE: Any of the above functions may be defined in a DLL by using
   the vsDllExport DLL Interface function.  See sample.c for an a
   sample dll which interfaces with SlickEdit.  Use VSPSZ
   in place of "_str" argument types except for call by reference
   strings.  For call by reference string arguments use "VSHREFVAR".

   DllExport examples:
      vsDllExport("int c_proc_search(VSHREFVAR proc_name,int find_first,VSHVAR ext)",0,0);
      vsDllExport("int vsc_list_tags(int output_view_id,VSPSZ filename,VSPSZ ext)",0,0);

*/

const C_COMPILER_CAPTION=       "C/C++ compiler libraries";
const JAVA_COMPILER_CAPTION=    "Java compiler libraries";
const DOTNET_COMPILER_CAPTION=  ".NET Frameworks (C#, F# and VB)";
const XCODE_COMPILER_CAPTION=   "Xcode Frameworks";
// Has
static STRARRAY eclipseExtMap:[];

static _str gEclipseTags;
//int def_include_protos = 0;

static bool gTagCallList:[];

struct TAG_FILELIST_PER_LANG_CACHE {
   _str m_languageId;
   _str m_projectTagFiles[];
   _str m_projectTagFilesList;
   _str m_allTagFiles[];
   _str m_allTagFilesList;
   _str m_compilerTagFile;
};
static TAG_FILELIST_PER_LANG_CACHE gTagFileListCache:[];

void _TagDelayCallList()
{
   gNoTagCallList=true;
   gTagCallList._makeempty();
}
static _str TagMakeIndex(_str prefix,_str filename="",_str options="")
{
   return(prefix:+_chr(0):+filename:+_chr(0):+options);
}
/** 
 * Called when files are added to any project by any means 
 * (i.e. even if a project is inserted into a workspace) 
 */
void _prjupdate_tags_filename() {
   gtag_filelist_cache_updated=false;
   gTagFileListCache._makeempty();
}
void _prjopen_tags_filename(bool singleFileProject) {
   if (singleFileProject) return;
   gtag_filelist_cache_updated=false;
   gTagFileListCache._makeempty();
}
void _prjclose_tags_filename(bool singleFileProject) {
   if (singleFileProject) return;
   gtag_filelist_cache_updated=false;
   gTagFileListCache._makeempty();
}

void _TagCallList(_str prefix, _str filename="", _str options="")
{
   if (_in_firstinit) {
      // We are not off the ground yet
      // We get when load macro in first init
      return;
   }
   if (prefix==TAGFILE_ADD_REMOVE_CALLBACK_PREFIX) {
      gtag_filelist_cache_updated=false;
      gTagFileListCache._makeempty();
   }
   if (gNoTagCallList) {
      _str i=TagMakeIndex(prefix,filename,options);
      gTagCallList:[i]=true;
      return;
   }
   call_list(prefix,filename,options);
}

void _TagProcessCallList()
{
   gNoTagCallList=false;
   _str tag_refresh_i=TagMakeIndex(TAGFILE_REFRESH_CALLBACK_PREFIX);
   DoRefresh := gTagCallList._indexin(tag_refresh_i);
   typeless i;
   for (i._makeempty();;) {
      gTagCallList._nextel(i);
      if (i._isempty()) break;
      if (i==tag_refresh_i) {
         continue;
      }
      a1 := a2 := a3 := "";
      parse i with a1 (_chr(0)) a2 (_chr(0)) a3;
      call_list(a1,a2,a3);
   }
   if (DoRefresh) {
      call_list(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }
}

static void _update_tag_filelists()
{
   static bool in_update_tagfile_cache;
   if (!gtag_filelist_cache_updated && !in_update_tagfile_cache) {
      gtag_filelist_cache_updated=false;
      in_update_tagfile_cache=true;
      gTagFileListCache._makeempty();

      _str tagFileArray[];
      tmp_filelist := tag_filelist := tags_filename();
      tag_filename := "";
      for (;;) {
         tag_filename = parse_tag_file_name(tmp_filelist);
         if (tag_filename=="") {
            break;
         }
         tagFileArray :+= tag_filename;
      }
      gTagFileListCache:[""].m_allTagFiles = tagFileArray;
      gTagFileListCache:[""].m_allTagFilesList = tag_filelist;

      tagFileArray._makeempty();
      tmp_filelist = tag_filelist = project_tags_filename();
      for (;;) {
         tag_filename = parse_tag_file_name(tmp_filelist);
         if (tag_filename=="") {
            break;
         }
         tagFileArray :+= tag_filename;
      }
      gTagFileListCache:[""].m_projectTagFiles = tagFileArray;
      gTagFileListCache:[""].m_projectTagFilesList = tag_filelist;
      in_update_tagfile_cache=false;
      gtag_filelist_cache_updated=true;
   }
}

static void _update_tag_filelist_ext(_str lang)
{
   // if this is the same extension we were looking for 
   // last time, no need to update
   if (gtag_filelist_cache_updated && gTagFileListCache._indexin(lang)) {
      tfcache := gTagFileListCache:[lang];
      if (tfcache.m_languageId != null && tfcache.m_allTagFilesList != null) {
         return;
      }
   }

   // update all the tag files
   _update_tag_filelists();

   // get the tag file list
   tmp_filelist := tag_filelist := tags_filename(lang,true);

   // put these tag files into the global list so we don't 
   // have to look it up again
   _str tagFileArray[];
   for (;;) {
      tag_filename := parse_tag_file_name(tmp_filelist);
      if (tag_filename=="") break;
      tagFileArray :+= tag_filename;
   }

   // save the extension so we know what we have
   gTagFileListCache:[lang].m_languageId = lang;
   gTagFileListCache:[lang].m_allTagFiles = tagFileArray;
   gTagFileListCache:[lang].m_allTagFilesList = tag_filelist;

   // narrow down the list of project-specific tag files that match lang
   if (lang!="" && _istagging_supported(lang) && _workspace_filename != "") {
      project_tagfiles_ext := "";
      _str project_tagfiles_array[];
      // save the name of the "original" open tag file
      orig_tag_db := tag_current_db();
      project_tagfiles := gTagFileListCache:[""].m_projectTagFiles;
      foreach (auto tag_filename in project_tagfiles) {
         if (tag_filename=="") {
            break;
         }
         tag_filename=absolute(tag_filename);
         status := tag_read_db(tag_filename);
         if (status >= 0 && tag_current_version() <= VS_TAG_LATEST_VERSION) {
            // from tagdoc file, you can go anywhere
            use_tag_file := (lang=="tagdoc");
            // other languages that have definitions in other langauge modes
            if (!use_tag_file) {
               alt_languages_list := lang" ";
               switch (lang) {
               case "java":     alt_languages_list :+= "class jar"; break;
               case "groovy":   alt_languages_list :+= "class jar"; break;
               case "kotlin":   alt_languages_list :+= "class jar"; break;
               case "kotlins":   alt_languages_list :+= "class jar kotlin"; break;
               case "scala":    alt_languages_list :+= "class jar"; break;
               case "py":       alt_languages_list :+= "class jar"; break;
               case "clojure":  alt_languages_list :+= "class jar"; break;
               case "cs":       alt_languages_list :+= "dll xmldoc"; break;
               case "bas":      alt_languages_list :+= "dll xmldoc"; break;
               case "vb":       alt_languages_list :+= "dll xmldoc"; break;
               case "vbs":      alt_languages_list :+= "dll xmldoc"; break;
               case "fsharp":   alt_languages_list :+= "dll xmldoc"; break;
               case "html":     alt_languages_list :+= "tld"; break;
               case "xmldoc":   alt_languages_list :+= "xmldoc"; break;
               case "xml":      alt_languages_list = "xsd dtd"; break;
               case "xhtml":    alt_languages_list = "xsd dtd"; break;
               case "phpscript":alt_languages_list = "html"; break;
               case "js":       alt_languages_list = "html"; break;
               default: break;
               }
               foreach (auto alt_lang in alt_languages_list) {
                  if (tag_find_language(auto dummy, alt_lang) == 0) {
                     use_tag_file = true;
                     break;
                  }
               }
            }
            // add the tag file to the project tag file list
            if (use_tag_file) {
               project_tagfiles_array :+= tag_filename;
               if (project_tagfiles_ext == "") {
                  project_tagfiles_ext = tag_filename;
               } else {
                  project_tagfiles_ext :+= PATHSEP:+tag_filename;
               }
            }
         }
         tag_reset_find_language();
      }
      // restore the 'current' tag file open for read
      if (orig_tag_db != "") {
         tag_read_db(orig_tag_db);
      }

      gTagFileListCache:[lang].m_projectTagFiles = project_tagfiles_array;
      gTagFileListCache:[lang].m_projectTagFilesList = project_tagfiles_ext;
   }
}


/**
 * Sets eclipse tag files, that is extension specific tag files
 * we should use since we are being used by the editor control inside
 * eclipse.
 *
 * @param ext The extension to add these files to
 * @param filelist A newline delimited list of tag files for this extension
 *
 **/
_command int setEclipseTagFiles(_str params="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
    _str tag_filename;
    _str tag_filelist;
    _str filelist;
    _str ext;
    tf_lang := "";
    gEclipseTags = params;
    parse params with ext "," filelist;
    eclipseExtMap:[ext]._makeempty();
    for (;;) {
       parse filelist with tag_filename"\n"tag_filelist;
       if (tag_filename=="") {
          break;
       }
       filelist = tag_filelist;
       if(ext == ""){
          int status = tag_read_db(tag_filename);
          if (status >= 0) {
             status = tag_find_language(tf_lang);
             while (!status) {
                eclipseExtMap:[tf_lang][eclipseExtMap:[tf_lang]._length()] = tag_filename;
                status = tag_next_language(tf_lang);
             }
             tag_reset_find_language();
          }
       }
       else {
          int status = tag_read_db(_maybe_quote_filename(tag_filename));
          if (status >= 0) {
             eclipseExtMap:[ext][eclipseExtMap:[ext]._length()] = tag_filename;
          } else {
             _str config = _ConfigPath();
             _maybe_append_filesep(config);
             temp_tag_filename :=  config :+ "tagfiles" :+ FILESEP :+ tag_filename; 
             status = tag_read_db(_maybe_quote_filename(temp_tag_filename));
             if (status >= 0) {
                eclipseExtMap:[ext][eclipseExtMap:[ext]._length()] = temp_tag_filename;
             }
          }
       }
          
    }

    javaTagFiles := _replace_envvars(LanguageSettings.getTagFileList("java"));
    if (javaTagFiles != "") {
       for (;;) {
          parse javaTagFiles with auto temp ";" javaTagFiles;
          if (temp =="") {
             break;
          }
          eclipseExtMap:["java"][eclipseExtMap:["java"]._length()] = temp;
       }
    }
    gtag_filelist_cache_updated=false;
    _update_tag_filelist_ext(ext);
    _update_tag_filelists();
    return 0;
}

_str _GetEclipseTagFiles(_str ext)
{
   _ret := "";
   int i;
    for (i = 0; i < eclipseExtMap:[ext]._length(); i++) {
       _ret :+= eclipseExtMap:[ext][i]:+ PATHSEP;
    }
    return _ret;
}

/**
 * Removes a tag file from specified extension specific tag file
 * This operation will also close the tag file
 *
 * @param ext extension
 * @param tagfile full path to tag file
 *
 **/
_command int removeEclipseTagFile(_str tag_filename = "") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   tag_close_db(tag_filename);
   _update_tag_filelists();
/*      filelist = tag_filelist;
      for (i._makeempty();;) {

         STRARRAY tagList = eclipseExtMap._nextel(i);
         if(i._isempty()){
            break;
         }
         for(x = 0; x < tagList._length(); x++)
         {
            if(tagList._el(x) == tag_filename)
            {

               eclipseExtMap._el(i)._deleteel(x);
               gtag_filelist_cache_updated=false;
               
               _update_tag_filelist_ext(eclipseExtMap._el(i));
               
            }
         }
      }
      */
/*      // Remove tag_filename from extension ext
      if (eclipseExtMap._indexin(ext)) {
         //say(ext" was found in map");
         // We need to remove the file
         STRARRAY taglist = eclipseExtMap:[ext];
         int i;
         // Find the tag file and remove it
         for (i = 0; i < taglist._length(); i++) {
            if (taglist._el(i) == tag_filename) {
               //say(tag_filename" was found");
               eclipseExtMap:[ext]._deleteel(i);
               gtag_filelist_cache_updated=false;
               _update_tag_filelist_ext(ext);
               _update_tag_filelists();
               tag_close_db(tag_filename);
            }
         }
      }
      */
   //}
   return 0;
}

/**
 * Return the array tag files associated with the given (optional) extension.
 * If the extension given is the empty string, and the current object is an
 * editor control, get the extension from the p_LangId property.
 * If the current object is not an editor control, retrieve all tag files
 * and project tag files, reguarless of extension relationship.
 *
 * @param lang      (optional) file extension (language) to get tags for
 *
 * @return array of strings containing each tag file path.
 *
 * @example
 * <PRE>
 * typeless tag_files = tags_filenamea();
 * int i=0;
 * for(;;) {
 *    _str tf = next_tag_filea(tag_files,i,false,true);
 *    if (tf=='') break;
 *    messageNwait("tag file: "tf);
 * }
 * </PRE>
 *
 * @see tags_filename
 * @see next_tag_filea
 *
 * @categories Tagging_Functions
 *
 */
STRARRAY tags_filenamea(_str lang="")
{
   if (lang=="") {
      _update_tag_filelists();
   } else {
      _update_tag_filelist_ext(lang);
   }
   return(gTagFileListCache:[lang].m_allTagFiles);
}
/**
 * Return a list of tag files associated with the given (optional) extension.
 * If the extension given is the empty string, and the current object is an
 * editor control, get the extension from the p_LangId property.
 * If the current object is not an editor control, retrieve all tag files
 * and project tag files, reguarless of extension relationship.
 * <p>
 * <B>Note:</B> The new version of this function {@link tags_filenamea} is
 * used more often, and is slightly more efficient because it returns its
 * results as an array.
 *
 * @param ext  If not '', the workspace tag file and all tag
 * files for the extension specified by
 * <i>ext</i>.  If this is '', all extension
 * specific tag files are returned except
 * optionally the tag files for Slick-C&reg;.
 *
 * @param includeSlickC Specifies whether the tag files for Slick-C&reg;
 * should be returned.  This option has no
 * effect if ext!=''.
 *
 *
 * @return string containing FILESEP separted tag file paths.
 *
 * @see tags_filenamea
 * @see next_tag_filea
 *
 * @categories Tagging_Functions
 *
 */
_str tags_filename(_str lang="",bool includeSlickC=true)
{
   if (!_haveContextTagging()) {
      return "";
   }

   static int in_tags_filename;
   if (!in_tags_filename) {
      in_tags_filename=1;
      if (lang!="") {
         _update_tag_filelist_ext(lang);
      } else {
         _update_tag_filelists();
      }
      in_tags_filename=0;
      if (gtag_filelist_cache_updated && gTagFileListCache._indexin(lang)) {
         tfcache := gTagFileListCache:[lang];
         if (tfcache.m_languageId != null) {
            return gTagFileListCache:[lang].m_allTagFilesList;
         }
      }
   }

   // 4:25pm 6/18/1999
   // Had to change this piece from project to workspace
   // 4:55pm 6/25/2001
   // We don't need to filter out Slick-C&reg; files from the project list
   project_tagfiles := "";
   if (_workspace_filename!="" && (lang!="e" || includeSlickC)) {
      project_tagfiles=project_tags_filename();
   }
   filename := get_env(_SLICKTAGS);
   // Only use tag files which have files for the
   // correct extension
   langTagFileList := LanguageSettings.getTagFileList(lang);
   if (lang!="" && (langTagFileList != "" || _istagging_supported(lang))) {
      // IF any global tag files to convert to extension specific
      if (filename!="") {
         _maybe_append(project_tagfiles, PATHSEP);
         project_tagfiles :+= filename;
         filename="";  // Global tag files processed.
      }
      list := project_tagfiles;
      project_tagfiles="";
      // save the name of the "original" open tag file
      orig_tag_db := tag_current_db();
      for (;;) {
         tag_filename := parse_tag_file_name(list);
         if (tag_filename=="") {
            break;
         }
         tag_filename=absolute(tag_filename);
         status := tag_read_db(tag_filename);
         if (status >= 0 && tag_current_version() <= VS_TAG_LATEST_VERSION) {
            // from tagdoc file, you can go anywhere
            use_tag_file := (lang=="tagdoc");
            // other languages that have definitions in other langauge modes
            if (!use_tag_file) {
               alt_languages_list := lang" ";
               switch (lang) {
               case "java":     alt_languages_list :+= "class jar"; break;
               case "groovy":   alt_languages_list :+= "class jar"; break;
               case "kotlin":   alt_languages_list :+= "class jar"; break;
               case "kotlins":   alt_languages_list :+= "class jar kotlin"; break;
               case "scala":    alt_languages_list :+= "class jar"; break;
               case "py":       alt_languages_list :+= "class jar"; break;
               case "clojure":  alt_languages_list :+= "class jar"; break;
               case "cs":       alt_languages_list :+= "dll xmldoc"; break;
               case "bas":      alt_languages_list :+= "dll xmldoc"; break;
               case "vb":       alt_languages_list :+= "dll xmldoc"; break;
               case "vbs":      alt_languages_list :+= "dll xmldoc"; break;
               case "fsharp":   alt_languages_list :+= "dll xmldoc"; break;
               case "html":     alt_languages_list :+= "tld"; break;
               case "xmldoc":   alt_languages_list :+= "xmldoc"; break;
               case "xml":      alt_languages_list = "xsd dtd"; break;
               case "xhtml":    alt_languages_list = "xsd dtd"; break;
               case "phpscript":alt_languages_list = "html"; break;
               case "js":       alt_languages_list = "html"; break;
               default: break;
               }
               foreach (auto alt_lang in alt_languages_list) {
                  if (tag_find_language(auto dummy, alt_lang) == 0) {
                     use_tag_file = true;
                     break;
                  }
               }
            }
            // add the tag file to the project tag file list
            if (use_tag_file) {
               if (project_tagfiles=="") {
                  project_tagfiles=tag_filename;
               } else {
                  project_tagfiles :+= PATHSEP:+tag_filename;
               }
            }
         }
         tag_reset_find_language();
      }
      // restore the 'current' tag file open for read
      if (orig_tag_db != "") {
         tag_read_db(orig_tag_db);
      }
   }
   _maybe_append(project_tagfiles, PATHSEP);

   // Are we running from Eclipse?  If so, we need to use the tag files
   // for each project
   //
   if (isEclipsePlugin()) {
      if (lang=="") {
         typeless e;
         for (e._makeempty();;) {
            eclipseExtMap._nextel(e);
            if (e._isempty()) {
               break;
            }
            for (i := 0; i < eclipseExtMap._el(e)._length(); i++) {
               _maybe_append(filename, PATHSEP);
               filename :+= eclipseExtMap._el(e)[i];
            }
         }

      } else if (eclipseExtMap._indexin(lang)) {
         for (i := 0; i < eclipseExtMap:[lang]._length(); i++) {
            _maybe_append(filename, PATHSEP);
            filename :+= eclipseExtMap:[lang][i];
         }
      }
   }

   // check for tagfiles in the workspace that are auto updated and append
   // them to the list
   if(_workspace_filename != "") {
      autoUpdatedTagFiles := auto_updated_tags_filename(lang);
      if (autoUpdatedTagFiles != "") {
         _maybe_append(filename, PATHSEP);
         filename :+= autoUpdatedTagFiles;
      }
   }

   // add the appropriate extension specific tag files (_project_extTagFiles or global ones)
   // NOTE: this will check to see if there are any project specific tag files as well as if
   //       the project specific extension matches the current file extension.  if either of
   //       these fails, then fall thru and add the global extension specific tag files.
   if (lang!="" && (langTagFileList != "" || _istagging_supported(lang))) {
      // check for project specific tag files
      if(lang == _project_extExtensions && _project_extTagFiles != "") {
         _maybe_append(filename, PATHSEP);
         filename :+= _project_extTagFiles;
      } else {
         if (!isEclipsePlugin() || isEclipsePlugin() && lang != "java") {
            langTagFileList=_replace_envvars(langTagFileList);
            if (langTagFileList!="") {
               if (filename=="") {
                  filename=langTagFileList;
               } else {
                  _maybe_append(filename, PATHSEP);
                  filename :+= langTagFileList;
               }
            }
         }
      }
   } else {
      _str langTagFileTable:[];
      LanguageSettings.getTagFileListTable(langTagFileTable);
      foreach (auto thisLangId => langTagFileList in langTagFileTable) {

         if(thisLangId == _project_extExtensions && _project_extTagFiles != "") {
            _maybe_append(filename, PATHSEP);
            filename :+= _project_extTagFiles;
         } else {
            langTagFileList = _replace_envvars(langTagFileList);
            if (langTagFileList!="" && ((includeSlickC && lang=="") || thisLangId != "e")) {
               _maybe_append(filename, PATHSEP);
               filename :+= langTagFileList;
            }
         }
      }
   }

   // if this is C/C++ or a derivative and they have selected a refactoring
   // configuration, also use the tag file associated with the refactoring
   // configuration
   // 
   // We want the C++ compiler tag file for "c", but "d" and "googlego" derives from "c"
   // and should not use the C++ compiler tag file.
   // We also want the Java compiler tag file for Java, unless we
   // are in the Eclipse plugin (Core) because that has it's own
   // sort of JDK tagging.
   compilerTagFile := "";
   cppTagFile := "";
   langTagFileList = LanguageSettings.getTagFileList(lang);
   if (lang!="" && (langTagFileList != "" || _istagging_supported(lang))) {
      if ((_LanguageInheritsFrom("c", lang) && !(_LanguageInheritsFrom("d", lang) || _LanguageInheritsFrom("googlego", lang))) ||
          (_LanguageInheritsFrom("java", lang) && !isEclipsePlugin())) {
         if (_isUnix()) {
            cppTagFile=_tagfiles_path():+"ucpp":+TAG_FILE_EXT;
         } else {
            cppTagFile=_tagfiles_path():+"cpp":+TAG_FILE_EXT;
         }
         if (!file_exists(cppTagFile)) {
            cppTagFile = "";
         }
         compilerTagFile=compiler_tags_filename(lang);
         if (compilerTagFile != "") {
            _maybe_append(filename, PATHSEP);
            filename :+= _maybe_quote_filename(compilerTagFile);
         }
      }
   } else {
      // Language has no tagging support, so include compiler tag files
      // along with everything else
      compilerTagFile=compiler_tags_filename("c");
      if (compilerTagFile != "") {
         _maybe_append(filename,PATHSEP);
         filename :+= _maybe_quote_filename(compilerTagFile);
      }

      compilerTagFile=compiler_tags_filename("java");
      if (compilerTagFile != "") {
         _maybe_append(filename,PATHSEP);
         filename :+= _maybe_quote_filename(compilerTagFile);
      }

      compilerTagFile=compiler_tags_filename("cs");
      if (compilerTagFile != "") {
         _maybe_append(filename,PATHSEP);
         filename :+= _maybe_quote_filename(compilerTagFile);
      }
   }

   /*if ( filename=="" ) {
      filename=SLICK_TAGS_DB;
   } */
   _str duplist=project_tagfiles;
   if (filename != "") {
      _maybe_append(duplist,PATHSEP);
      duplist :+= filename;
   }
   // Remove duplicate tag files
   list := "";
   for (;;) {
      tag_filename := parse_tag_file_name(duplist);
      if (tag_filename=="") {
         break;
      }
      tag_filename=absolute(tag_filename);
      if (pos(PATHSEP:+tag_filename:+PATHSEP,PATHSEP:+list:+PATHSEP,1,_fpos_case)) {
         continue;
      }
      if (cppTagFile!="" && _file_eq(tag_filename, cppTagFile)) {
         continue;
      }
      if (list=="") {
         list = tag_filename;
      } else {
         list :+= PATHSEP:+tag_filename;
      }
   }

   return(list);
}
/**
 * Return a list of tag files associated with the current 
 * workspace as auto-updated tag files. 
 *
 * @param lang   If not '', the auto-updated tag files are 
 * only included if they contain files of the given language.
 *
 * @return string containing FILESEP separted tag file paths.
 *
 * @see project_tags_filename
 * @see tags_filename
 * @see next_tag_file
 *
 * @categories Tagging_Functions
 */
_str auto_updated_tags_filename(_str lang="")
{
   if (!_haveContextTagging()) {
      return "";
   }

   // check for tagfiles in the workspace that are auto updated and append
   // them to the list
   tagFileDir := VSEWorkspaceTagFileDir();
   filename := "";
   if (_workspace_filename != "") {
      int autoUpdatedTagfileList[] = null;
      _WorkspaceGet_TagFileNodes(gWorkspaceHandle, autoUpdatedTagfileList);
      for (t := 0; t < autoUpdatedTagfileList._length(); t++) {

         // Get the remote tag filename
         fromTagfile := _AbsoluteToWorkspace(_xmlcfg_get_attribute(gWorkspaceHandle, autoUpdatedTagfileList[t], "AutoUpdateFrom"));
         // Get the absolute local tag filename
         autoUpdatedTagfile := _xmlcfg_get_attribute(gWorkspaceHandle, autoUpdatedTagfileList[t], "File");
         if (autoUpdatedTagfile == "") autoUpdatedTagfile = _strip_filename(fromTagfile,'P');
         autoUpdatedTagfile = absolute(autoUpdatedTagfile, tagFileDir);
         if (fromTagfile != "") {
            autoUpdatedTagfile = absolute(autoUpdatedTagfile, tagFileDir);
         } else {
            autoUpdatedTagfile = _AbsoluteToWorkspace(autoUpdatedTagfile);
         }

         if (lang == "") {
            // no extension so add all tagfiles
            _maybe_append(filename, PATHSEP);
            filename :+= autoUpdatedTagfile;
         } else {
            // make sure this tagfile contains files of this extension
            int status = tag_read_db(autoUpdatedTagfile);
            if ((status >= 0) && 
                (tag_current_version() <= VS_TAG_LATEST_VERSION) &&
                (tag_find_language(auto dummy,lang)==0 || 
                 (lang=="tagdoc") ||
                 (lang=="phpscript" && tag_find_language(dummy,"html")==0) ||
                 (lang=="xml" && tag_find_language(dummy,"xsd")==0) ||
                 (lang=="xml" && tag_find_language(dummy,"dtd")==0) ||
                 (lang=="html" && tag_find_language(dummy,"tld")==0) ||
                 (lang=="xmldoc" && tag_find_language(dummy,"xmldoc")==0)
                )) {
               _maybe_append(filename, PATHSEP);
               filename :+= autoUpdatedTagfile;
            }
            tag_reset_find_language();
         }
      }
   }

   return filename;
}

/** 
 * @return 
 * If there is a specific compiler support tag file associated with 
 * the current project, return that tag file.  If there is a compiler 
 * tag file, but it does not match the given language specification, 
 * then do not return the tag file. 
 * <p>
 * Currently, we only support compiler tag files for C/C++ and Java, 
 * however, this function selects the tag file in a completely language 
 * independent manner, so no changes are needed here if we add compiler 
 * tag file support for another langauge. 
 *
 * @param lang   If lang!='', then we return the correct tag file(s) for 
 *               the language specified.
 */
_str compiler_tags_filename(_str lang="")
{
   if (!_haveContextTagging()) {
      return "";
   }

   // if we have the last result cached, use it
   if (gtag_filelist_cache_updated && gTagFileListCache._indexin(lang)) {
      tfcache := gTagFileListCache:[lang];
      if (tfcache.m_compilerTagFile != null) {
         return tfcache.m_compilerTagFile;
      }
   }

   do {
      // get the active compiler configuration from the project
      compiler_name := refactor_get_active_config_name(_ProjectHandle(),lang);
      //say("compiler_tags_filename: compiler_name="compiler_name);
      if (compiler_name == "") {
         break;
      }

      // put together the tag database file name, the file has to exist
      compilerTagFile := _tagfiles_path():+compiler_name:+TAG_FILE_EXT;
      if (!file_exists(compilerTagFile)) {
         break;
      }

      // no point in returning a tag file we can't open
      status := tag_read_db(compilerTagFile);
      if (status < 0) {
         break;
      }

      // this is an empty tag file, well, if that's what they want, fine
      if (tag_find_language(auto found_lang) < 0) {
         tag_reset_find_language();
         gTagFileListCache:[lang].m_compilerTagFile = compilerTagFile;
         return compilerTagFile;
      }

      // verify that this tag file uses the given langauge
      if (lang != "" && tag_find_language(found_lang, lang) < 0) {
         // the project's compiler tag file does not apply to this
         // language, so check if there is a default compiler tag
         // file that does apply.
         tag_reset_find_language();
         compiler_name = refactor_get_active_config_name(-1,lang);
         if (compiler_name == "") {
            break;
         }

         // put together the tag database file name, the file has to exist
         compilerTagFile = _tagfiles_path():+compiler_name:+TAG_FILE_EXT;
         if (!file_exists(compilerTagFile)) {
            break;
         }

         // no point in returning a tag file we can't open
         status = tag_read_db(compilerTagFile);
         if (status < 0) {
            break;
         }
      }

      // this compiler tag file is appropriate for this language
      tag_reset_find_language();
      gTagFileListCache:[lang].m_compilerTagFile = compilerTagFile;
      return compilerTagFile;

   } while (false);

   // did not find a working compiler tag file for this language
   gTagFileListCache:[lang].m_compilerTagFile = "";
   return "";
}

/**
 * This function is obsolete.
 */
_str global_tags_filename(bool doRelative=false)
{
   if (!_haveContextTagging()) {
      return "";
   }

   filename := get_env(_SLICKTAGS);
   /*if ( filename=="" ) {
      filename=SLICK_TAGS_DB;
   }*/
   return(AbsoluteList(filename));
}

/** 
 * @return
 * Utility function for getting the relevant set of tag files to use in 
 * the _[language]_find_context_tags() callbacks.
 * 
 * @param lang            (optional) file extension (language) to get tags for
 * @param context_flags   (optoinal) context flags (can limit to locals, or current file, or workspace)
 *
 * @categories Tagging_Functions
 */
STRARRAY tag_find_context_tags_filenamea(_str langId="", SETagContextFlags context_flags=SE_TAG_CONTEXT_NULL)
{
   // only locals or current file, so not including tag files
   if ((context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) ||
       (context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE)) {
      return null;
   }

   // only workspace and project tag files
   if (context_flags & SE_TAG_CONTEXT_ONLY_WORKSPACE) {
      tag_files := project_tags_filenamea(doRelative:false, langId);

      // if there are no workspace tag files, fall through
      if (tag_files._length() > 0) {
         // do they also want the auto-updated tag files?
         if (context_flags & SE_TAG_CONTEXT_INCLUDE_AUTO_UPDATED) {
            auto_updated := auto_updated_tags_filename(langId);
            tag_filename := next_tag_file(auto_updated, find_first:true);
            while (tag_filename != "") {
               tag_files :+= tag_filename;
               tag_filename = next_tag_file(auto_updated, find_first:false);
            }
         }
         // do the also want the compiler tag file
         if (context_flags & SE_TAG_CONTEXT_INCLUDE_COMPILER) {
            compiler_tag_file := compiler_tags_filename(langId);
            if (compiler_tag_file != "") {
               tag_files :+= compiler_tag_file;
            }
         }
         // and return the project tag files
         return tag_files;
      }
   }

   // get all language-specific tag files
   return tags_filenamea(langId);
}

/**
 * Set the given def-var to the specified list, or append the
 * list to the already existing def-var.
 *
 * @param name     name of def-var to look up and modify
 * @param list     list of items, separated by PATHSEP
 * @param append   append the items to existing list, or replace list
 *
 * @return
 * Returns 1 if the def-var was actually changed, 0 otherwise
 */
int _set_listvar(_str name, _str list, bool append=false)
{
   index := find_index(name,MISC_TYPE);
   if (!index) {
      if (list!="") {
         insert_name(name,MISC_TYPE,list);
         return(1);
      }
   } else {
      if (list=="") {
         delete_name(index);
         return(1);
      } else {
         _str old_list=name_info(index);
         if (append) {
            // Append only works if items in same order or only adding one.
            if (!pos(PATHSEP:+list:+PATHSEP,PATHSEP:+old_list:+PATHSEP,1,_fpos_case)) {
               _maybe_append(old_list, PATHSEP);
               old_list :+= list;
               set_name_info(index,old_list);
               return(1);
            }
         } else {
            if (list != old_list) {
               set_name_info(index,list);
               return(1);
            }
         }
      }
   }
   return(0);
}
/**
 * Remove an entry from a list var.  Removes the def-var if
 * the list becomes empty.
 *
 * @param name     name of def-var to look up and modify
 * @param xfile    entry to remove from list (uses filename comparison)
 *
 * @return
 * Returns 1 if the def-var was actually changed, 0 otherwise
 */
int _remove_listvar(_str name, _str xfile)
{
   found_it := false;
   index := find_index(name,MISC_TYPE);
   if (!index) {
      return 0;
   }

   new_list := "";
   _str old_list=name_info(index);
   while (old_list != "") {
      file := "";
      if (_file_eq(xfile,old_list)) {
         file = old_list;
         old_list = "";
      } else if (_file_eq(xfile:+PATHSEP, substr(old_list,1,length(xfile)+1))) {
         file = substr(old_list,1,length(xfile));
         old_list = substr(old_list,length(xfile)+2);
      } else {
         parse old_list with file (PARSE_PATHSEP_RE),'r' old_list;
      }
      if (_file_eq(file, xfile)) {
         found_it = true;
         continue;
      }
      if (new_list!="") strappend(new_list,PATHSEP);
      strappend(new_list, file);
   }

   if (!found_it) {
      return 0;
   }

   if (new_list == "") {
      delete_name(index);
   } else {
      set_name_info(index,new_list);
   }
   return 1;
}
/**
 * Set the list of extension specific tag files.
 *
 * @param cmdline   extension and list of tag files
 * @param append    Append the files to list, or start new list? 
 *  
 * @deprecated Use {@link set_lang_tagfiles()} 
 */
_command void set_exttagfiles(_str cmdline="",bool append=false) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   set_lang_tagfiles(cmdline,append);
}

/**
 * Set the list of language specific tag files.
 *
 * @param cmdline   extension and list of tag files
 * @param append    Append the files to list, or start new list? 
 */
_command void set_lang_tagfiles(_str cmdline="",bool append=false) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   _str ext,list;
   parse cmdline with ext list;
   if (ext=="") {
      return;
   }
   list=stranslate(list,'','"');
   if (substr(ext,1,1)=='.') {
      ext=substr(ext,2);
   }
   lang := _Ext2LangId(ext);
   if (lang == "") {
      lang = _Ext2LangId(lowcase(ext));
   }

   LanguageSettings.setTagFileList(lang, list, append);
}

/**
 * Remove a specific tag file from an extension's tag file list.
 *
 * @param cmdline   extension and tag file 
 *  
 * @deprecated Use {@link remove_lang_tagfiles()} 
 */
_command void remove_exttagfile(_str cmdline="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   remove_lang_tagfile(cmdline);
}

/**
 * Remove a specific tag file from an extension's tag file list.
 *
 * @param cmdline   extension and tag file 
 */
_command void remove_lang_tagfile(_str cmdline="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   _str ext,tagfile,list="";
   parse cmdline with ext tagfile;
   if (ext=="") {
      return;
   }
   tagfile=stranslate(tagfile,'','"');
   if (substr(ext,1,1)==".") {
      ext=substr(ext,2);
   }
   lang := _Ext2LangId(ext);
   if (lang == "") {
      lang = _Ext2LangId(lowcase(ext));
   }
   tagfile=_encode_vsenvvars(tagfile,true,false);

   if (_remove_listvar("def-tagfiles-"lang, tagfile)) {
      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,"","");
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }
}

/**
 * @return
 * Return the name of the tag file for the current workspace (project).
 *
 * @param doRelative  Allow relative paths, or convert to absolute?
 *
 * @categories Tagging_Functions
 */
_str workspace_tags_filename_only(bool doRelative=false)
{
   if (!_haveContextTagging()) {
      return "";
   }

   // Eclipse is a special case
   if(isEclipsePlugin()){
      tagFile := "";
      int status = _eclipse_get_project_tagfile_string(tagFile);
      return tagFile;
   }

   // We have to have a workspace open.
   if (_workspace_filename=="") {
      return("");
   }

   // return the workspace tag file name
   return VSEWorkspaceTagFilename();
}

/**
 * @return
 * Return the name of the tag file for the current workspace (project).
 *
 * @param doRelative  Allow relative paths, or convert to absolute?
 *
 * @categories Tagging_Functions
 */
_str project_tags_filename_only(_str project_name=_project_name, bool doRelative=false, bool getProjectTagOnly=false)
{
   if (!_haveContextTagging()) {
      return "";
   }

   // Eclipse is a special case
   if (isEclipsePlugin()){
      tagFile := "";
      int status = _eclipse_get_project_tagfile_string(tagFile);
      return tagFile;
   }

   // Check if this project has it's own tag file
   do {
      if (project_name == "") break;
      project_file := _AbsoluteToWorkspace(project_name);
      if (project_file == "") break;
      if (!_ProjectFileExists(project_file)) break;
      project_handle := _ProjectHandle(project_file);
      option := _ProjectGet_TaggingOption(project_handle);
      if (option == VPJ_TAGGINGOPTION_NONE) return "";
      if (option != VPJ_TAGGINGOPTION_PROJECT && option != VPJ_TAGGINGOPTION_PROJECT_NOREFS) break;
      project_tag_file:=_VSEProjectTagFileName(_workspace_filename,project_file,doRelative);
      return project_tag_file;

   } while (false);
   if (getProjectTagOnly) {
      return '';
   }

   // Otherwise return the workspace tag file
   return workspace_tags_filename_only();
}

/**
 * Returns the path to for the project specific tag file for a 
 * project in the current workspace, regardless of whether the 
 * project is set up for it or not. 
 * 
 * @param project_file Path for the project's vpj file.
 * @return _str pathname for the project specific tag file given 
 *         the project file path.
 */
_str project_specific_tagfile(_str project_file)
{
   tagFileDir := VSEWorkspaceTagFileDir(_workspace_filename, _strip_filename(project_file,'N'));
   extra := _file_eq(_strip_filename(project_file,'e'), _strip_filename(_workspace_filename,'e'))? "-project":"";
   return tagFileDir:+_strip_filename(project_file,'PE'):+extra:+TAG_FILE_EXT;
}

/**
 * @return
 * Return the name of the tag file for the current workspace (project). 
 * Also return in the list any project tag files for projects that 
 * have their own tag file.
 *
 * @param doRelative  Allow relative paths, or convert to absolute?
 *
 * @categories Tagging_Functions
 */
_str project_tags_filename(bool doRelative=false)
{
   if (!_haveContextTagging()) {
      return "";
   }

   // Use cached version of project tag files list
   static int in_project_tags_filename;
   if (!in_project_tags_filename) {
      in_project_tags_filename=1;
      _update_tag_filelists();
      in_project_tags_filename=0;
      if (gtag_filelist_cache_updated) {
         return gTagFileListCache:[""].m_projectTagFilesList;
      }
   }

   // Eclipse is a special case
   if(isEclipsePlugin()){
      tagFile := "";
      int status = _eclipse_get_project_tagfile_string(tagFile);
      return tagFile;
   }

   // We have to have a workspace open.
   if (_workspace_filename=="") {
      return("");
   }

   // Always include the workspace tag file name
   tagfiles := VSEWorkspaceTagFilename();

   // Get the list of projects in this workspace
   _str project_names[];
   _str vendor_project_names[];
   status := _GetWorkspaceFiles(_workspace_filename, project_names, vendor_project_names);
   if (status < 0 || project_names._length() <= 0) {
      return tagfiles;
   }

   // Check each project if it has it's own tag file
   for (i:=0; i<project_names._length(); i++) {
      if (project_names[i] == "") continue;
      project_file := _AbsoluteToWorkspace(project_names[i]);
      if (project_file == "") continue;
      if (!_ProjectFileExists(project_file)) continue;
      project_handle := _ProjectHandle(project_file);
      option := _ProjectGet_TaggingOption(project_handle);
      if (option != VPJ_TAGGINGOPTION_PROJECT && option != VPJ_TAGGINGOPTION_PROJECT_NOREFS) continue;
      project_tag_file := project_specific_tagfile(project_file);
      if (doRelative) {
         project_tag_file = _RelativeToWorkspace(project_tag_file);
      }
      // PREPEND the project tag file to the list if it is the current project
      if (_file_eq(project_file, _project_name)) {
         tagfiles = project_tag_file :+ PATHSEP :+ tagfiles;
      } else {
         tagfiles :+= PATHSEP :+ project_tag_file;
      }
   }

   // Return the list of tag files
   return tagfiles;
}

/**
 * @return
 * Return the project file that is associated with the given project 
 * tag file. 
 *
 * @categories Tagging_Functions
 */
_str project_tags_filename_to_project_file(_str tag_filename)
{
   // We have to have a workspace open.
   if (_workspace_filename=="") {
      return("");
   }

   // Is this the workspace tag file
   if (tag_filename == workspace_tags_filename_only()) {
      return _workspace_filename;
   }

   // Get the list of projects in this workspace
   _str project_names[];
   _str vendor_project_names[];
   status := _GetWorkspaceFiles(_workspace_filename, project_names, vendor_project_names);
   if (status < 0 || project_names._length() <= 0) {
      return "";
   }

   // Check each project if it has it's own tag file
   for (i:=0; i<project_names._length(); i++) {
      if (project_names[i] == "") continue;
      project_file := _AbsoluteToWorkspace(project_names[i]);
      if (project_file == "") continue;
      if (!_ProjectFileExists(project_file)) continue;
      project_handle := _ProjectHandle(project_file);
      option := _ProjectGet_TaggingOption(project_handle);
      if (option != VPJ_TAGGINGOPTION_PROJECT && option != VPJ_TAGGINGOPTION_PROJECT_NOREFS) continue;
      tagFileDir := VSEWorkspaceTagFileDir(_workspace_filename, _strip_filename(project_file,'N'));
      extra := _file_eq(_strip_filename(project_file,'e'), _strip_filename(_workspace_filename,'e'))? "-project":"";
      project_tag_file := tagFileDir:+_strip_filename(project_file,'PE'):+extra:+TAG_FILE_EXT;
      if (_file_eq(tag_filename, project_tag_file)) {
         return project_file;
      }
   }

   // Did not find the project
   return "";
}

/**
 * Return an array of tag files associated with the current workspace. 
 * The files are returned as absolute paths unless otherwise specified. 
 *
 * @param doRelative   Return tag file names relative to the workspace file.
 * @param lang         (optional) file extension (language) to get tags for
 *
 * @return array of strings containing each tag file path.
 *
 * @example
 * <PRE>
 * typeless tag_files = project_tags_filenamea();
 * int i=0;
 * for(;;) {
 *    _str tf = next_tag_filea(tag_files,i,false,true);
 *    if (tf=='') break;
 *    messageNwait("tag file: "tf);
 * }
 * </PRE>
 *
 * @see project_tags_filename
 * @see next_tag_filea
 *
 * @categories Tagging_Functions
 */
STRARRAY project_tags_filenamea(bool doRelative=false, _str lang="")
{
   _update_tag_filelists();
   if (lang != "") {
      _update_tag_filelist_ext(lang);
      return(gTagFileListCache:[lang].m_projectTagFiles);
   }
   return(gTagFileListCache:[""].m_projectTagFiles);
}
/**
 * @return
 * Return the list of include paths for the current project.
 *
 * @param doRelative  Allow relative paths, or convert to absolute?
 */
_str project_include_filepath(bool doRelative=false)
{
   if (_project_name == "") {
      return "";
   }
   project_include := "";
   project_include=_ProjectGet_IncludesList(_ProjectHandle(_project_name));
   project_include=_absolute_includedirs(project_include,_project_get_filename());
   if (!doRelative) {
      return(AbsoluteList(project_include));
   }
   return(project_include);
}
/**
 * @return Returns the name of the references (BSC) file
 *         attached to the current project.
 *
 * @param doRelative allow relative path, or convert to absolute?
 */
_str refs_filename(bool doRelative=false)
{
   if (!_haveContextTagging()) {
      return "";
   }

   if (machine_bits()=="64") {
      return("");
   }
   _str filename;
   if (_project_name!="") {
      filename=_ProjectGet_RefFile(_ProjectHandle());
      //_ini_get_value(_project_name,"COMPILER."GetCurrentConfigName(),"REFFILE",filename);
      filename=_parse_project_command(filename,"",_project_get_filename(),"");
      if (filename!="") {
         filename=absolute(filename,_strip_filename(_project_name,'N'));
         if (_file_eq(_get_extension(filename,true),BSC_FILE_EXT)) {
            if (file_match(_maybe_quote_filename(filename)" -p",1)=="") {
               filename="";
            }
         }
      }
   } else {
      // filename=get_env(_SLICKREFS);
      filename="";
   }
   if (filename=="") {
      return "";
   }
   if (!doRelative) {
      filename = absolute(filename);
   }
   return(filename);
}
/**
 * @return
 * Make each entry in the given list of paths absolute.
 * and return new list.
 *
 * @param taglist   original list of paths
 */
_str AbsoluteList(_str taglist)
{
   list := "";
   TagFilename := "";
   for (;;) {
      TagFilename = parse_tag_file_name(taglist);
      if (TagFilename=="") break;
      TagFilename=absolute(TagFilename);
      if (list=="") {
         list=TagFilename;
      } else {
         list :+= PATHSEP:+TagFilename;
      }
   }
   return(list);
}
/**
 * Remove duplicate filename or paths from a path list.
 * Maintains the original order of the list.
 *
 * @param taglist     original list of paths
 * @param all_dirs    should we attempt to add file sep char?
 *
 * @return new list with duplicate entries removed.
 */
_str RemoveDupsFromPathList(_str taglist,bool all_dirs=false)
{
   _str first,newlist=";";
   while (taglist != "") {
      parse taglist with first (PARSE_PATHSEP_RE),'r' taglist;
      stranslate(first,'','"');
      if (_last_char(first) != FILESEP && all_dirs) {
         strappend(first,FILESEP);
      }
      //first=_maybe_quote_filename(first);
      if (!pos(PATHSEP:+_file_case(first):+PATHSEP,_file_case(newlist),1,'i')) {
         strappend(newlist,first:+PATHSEP);
      }
   }
   if (newlist!="") {
      newlist=substr(newlist,2,length(newlist)-2);
   }
   return(newlist);
}

/**
 * Convert an old (version 2.0!) tag file to the modern tag database
 * format (version 3.0 or current).
 */
void _xlat_old_vslicktags()
{
   next_tag_file_list := get_env(_SLICKTAGS);
   if (next_tag_file_list=="") {
      return;
   }
   /*
       Convert VSE <=2.0 tag file extensions to
       >=3.0 tag file extensions
   */
   new_tag_list := "";
   tag_file := "";
   for (;;) {
      tag_file = parse_tag_file_name(next_tag_file_list);
      if (tag_file=="" && next_tag_file_list=="") {
         break;
      }
      if(_file_eq(_get_extension(tag_file),"slk")) {
         tag_file=_strip_filename(tag_file,"e"):+TAG_FILE_EXT;
      }
      if (new_tag_list=="") {
         new_tag_list=tag_file;
      } else {
         new_tag_list :+= PATHSEP:+tag_file;
      }
   }
   /*
       Convert global tag files to extension specific tag
       files.
   */
   _str list=new_tag_list;
   tag_filename := "";
   for (;;) {
      tag_filename = parse_tag_file_name(list);
      if (tag_filename=="") {
         break;
      }
      tag_filename=absolute(tag_filename);
      int status= tag_read_db(tag_filename);
      if (status >= 0) {
         // get the files from the database
         srcfilename := "";
         status=tag_find_file(srcfilename);
         if (!status) {
            _str lang=_Filename2LangId(srcfilename);
            if (lang!="" && lang!="fundamental") {
               LanguageSettings.setTagFileList(lang, tag_filename, true);
            }
         }
         tag_reset_find_file();
      }
   }
   // Delete this environment variable from the user.cfg.xml file
   typeless new_tag_file_list;
   new_tag_file_list._makeempty();
   _ConfigEnvVar(_SLICKTAGS,new_tag_file_list);

   // Delete this environment variable
   set_env(_SLICKTAGS);
}
static _str next_tag_file_list;

/**
 * @return
 * Return the next alias file in the given list
 *
 * @param alias_file_list   list of alias files, separated by PATHSEP
 * @param find_first        find first file or next?
 */
_str next_alias_file(_str alias_file_list,int find_first)
{
   if ( find_first ) {
      next_tag_file_list=alias_file_list;
   }
   alias_file := "";
   for (;;) {
      parse next_tag_file_list with alias_file (PARSE_PATHSEP_RE),'r' next_tag_file_list;
      first_ch := substr(alias_file,1,1);
      if ( alias_file==""  ) {
         return("");
      }
      if ( first_ch=="+" || first_ch=="-" ) {
         second_ch := upcase(substr(alias_file,2,1));
         /* Search recursively up the directory tree for all alias.slk files. */
         if ( second_ch=="R" ) {
            parse alias_file with . alias_file ;
            alias_file=absolute(alias_file);
            path := substr(alias_file,1,pathlen(alias_file));
            next_file := absolute(path".."FILESEP:+substr(alias_file,pathlen(alias_file)+1));
            if ( next_file!=alias_file ) {
               next_tag_file_list="+R "next_file:+PATHSEP:+next_tag_file_list;
            } else {
               continue;
            }
         } else {
            messageNwait(nls("Invalid option in alias file list: %s",alias_file));
            return("");
         }
      }
      if ( _isAliasProfile(alias_file) || file_match("-p "_maybe_quote_filename(alias_file),1)!="" ) {
         return(alias_file);
      }
   }
}
/**
 * @return the next tag file in the given array of tag files.
 *
 * @param list             list (array) of tag files
 * @param i                (reference, initially 0) current array index
 * @param checkFiles       check if tag file is missing or corrupt?
 * @param openFileRead     open tag file for read?
 *
 * @categories  Tagging_Functions
 */
_str next_tag_filea(_str (&list)[],int &i,bool checkFiles=true,bool openFileRead=false)
{
   if (!_haveContextTagging()) {
      return "";
   }

   for (;;) {
      if (i>=list._length()) {
         return("");
      }
      _str tag_file=list[i];++i;
      // need to check files?
      if (checkFiles && file_match("-p "_maybe_quote_filename(tag_file),1)=="") {
         // tag file doesn't exist, try .vtg extension instead of .slk
         if(!_file_eq(_get_extension(tag_file),"slk")) {
            continue;
         }
         tag_file=_strip_filename(tag_file,"e"):+TAG_FILE_EXT;
         if ( file_match("-p "_maybe_quote_filename(tag_file),1)=="" ) {
            continue;
         }
      }
      // if requested, open tag file for read access, otherwise just return it
      if (!openFileRead || tag_read_db(tag_file) >= 0) {
         return(tag_file);
      }
   }
}

_str parse_tag_file_name(_str &tag_filelist, _str ext=TAG_FILE_EXT)
{
   // parse up to the path seperator.  This should be the file name
   parse tag_filelist with auto tag_file (PARSE_PATHSEP_RE),'r' tag_filelist;
   tag_file = _maybe_unquote_filename(tag_file);

   // if the file name ends with .vtg, or there is no more to parse, or the file exists
   // then we automatically can assume this is a complete tag file name.
   if (tag_filelist == "" || endsWith(tag_file,ext,false,'i') || file_exists(tag_file)) {
      return tag_file;
   }

   // if the tag file name contains path seperators, then it might get truncated.
   // parse forward to the next path seperator and check for a completion.
   parse tag_filelist with auto tag_file_rest (PARSE_PATHSEP_RE),'r' auto tag_filelist_rest;
   for (;;) {
      // if what we find ends with .vtg and the file exists on disk, then count it as a tag file.
      // be a bit liberal with case-sensitivity, we are just verifying after all.
      // this exists to handle tag files with an embedded path separator.
      if (endsWith(tag_file_rest,ext,false,'i') && file_exists(tag_file:+PATHSEP:+tag_file_rest)) {
         tag_filelist = tag_filelist_rest;
         return tag_file:+PATHSEP:+tag_file_rest;
      }
      // if what we found ends with .vtg or exists on disk, then count it as a tag file
      if (endsWith(tag_file_rest,ext,false,'i') || file_exists(tag_file_rest)) {
         tag_filelist = tag_filelist_rest;
         return tag_file_rest;
      }
      // if we run off the end of the list, stop and give up
      if (tag_filelist_rest == "") {
         break;
      }
      // get the next segment form the tag file name
      parse tag_filelist_rest with auto tag_file_more (PARSE_PATHSEP_RE),'r' tag_filelist_rest;
      tag_file_rest :+= PATHSEP:+tag_file_more;
   }
   
   // exit with shame, we have not found a good tag file name
   return tag_file;
}

/**
 * @return the next tag file in the given list, destroying the list in the process.
 *
 * @param next_tag_file_list  (reference) list of tag files, seperated by PATHSEP
 * @param checkFiles          check if tag file is missing or corrupt?
 * @param openFileRead        open tag file for read?
 */
_str next_tag_file2(_str &next_tag_file_list,bool checkFiles=true,bool openFileRead=false)
{
   if (!_haveContextTagging()) {
      return "";
   }

   for (;;) {
      //say('next_tag_file_list='next_tag_file_list);
      tag_file := parse_tag_file_name(next_tag_file_list);
      //say('tag_file='tag_file);
      // end of list?
      if (tag_file=="") {
         return "";
      }
      // need to check files?
      if (checkFiles && file_match("-p "_maybe_quote_filename(tag_file),1)=="") {
         // tag file doesn't exist, try .vtg extension instead of .slk
         if(!_file_eq(_get_extension(tag_file),"slk")) {
            continue;
         }
         tag_file=_strip_filename(tag_file,'e'):+TAG_FILE_EXT;
         if ( file_match("-p "_maybe_quote_filename(tag_file),1)=="" ) {
            continue;
         }
      }
      // if requested, open tag file for read access, otherwise just return it
      if (!openFileRead || tag_read_db(tag_file) >= 0) {
         return(tag_file);
      }
   }
}
/**
 * @return the next tag file in the given list of tag files.
 *
 * @param tag_file_list    list of tag files, seperated by PATHSEP
 * @param find_first       find first in list or next in list?
 * @param checkFiles       check if tag file is missing or corrupt?
 * @param openFileRead     open tag file for read?
 *
 * @categories Tagging_Functions
 */
_str next_tag_file(_str tag_file_list,bool find_first,bool checkFiles=true,bool openFileRead=false)
{
   if (!_haveContextTagging()) {
      return "";
   }

   if ( find_first ) {
      next_tag_file_list=tag_file_list;
   }
   return(next_tag_file2(next_tag_file_list,checkFiles,openFileRead));
}
/**
 * Check and emit the standard warning use when there are no
 * tag files for the given extension.
 *
 * @param tag_files    String possibly containing missing or corrupt tag files.
 *
 * @return 0 if no message emitted, 1 otherwise.
 */
int warn_if_no_tag_files(_str tag_files)
{
   // Standard edition does not have tag files
   if (!_haveContextTagging()) {
      return(0);
   }
   // Do not warn if tagging is not supported for this language
   if (!_istagging_supported()) {
      return(0);
   }
   if ( tag_files=="" ) {
      messageNwait(nls("No tag files found.  Press any key to continue"));
      return(1);
   }
   _str filename = next_tag_file2(tag_files,true,true);
   if ( filename=="" ) {
      messageNwait(nls("Tag files missing or corrupt: %s.  Press any key to continue",tag_files));
      return(1);
   }
   return(0);
}
/**
 * Remove duplicates from a sorted list of strings.
 *
 * @param list        list of strings to remove dups from
 * @param IgnoreCase  use case-insensitive comparisons?
 */
void _aremove_duplicates(_str (&list)[],bool IgnoreCase)
{
   if (!list._length()) return;
   _str previous_line=list[0];
   int i;
   for (i=1;i<list._length();++i) {
      if (IgnoreCase) {
         if (strieq(list[i],previous_line)) {
            list._deleteel(i);
            --i;
         } else {
            previous_line=list[i];
         }
      } else {
         if ( list[i]:==previous_line ) {
            list._deleteel(i);
            --i;
         } else {
            previous_line=list[i];
         }
      }
   }
}
/*
     tagname is also input.
*/
static int prompt_user(_str (&taglist)[],_str (&filelist)[],int (&linelist)[],_str &tagname,_str &filename,_str more_caption="")
{
#if 0
   // If user wants strict language case sensitivity
   if (!def_ignore_tcase) {
      // Determine if all tag entries are for case sensitive languages
      old_tag_ext="";
      IgnoreCase=false;
      for (i=0;i<taglist._length();++i) {
         if (tag_case(filelist[i])=="i") {
            IgnoreCase=true;
            break;
         }
      }
      if (!IgnoreCase) {
         for (i=0;i<taglist._length();++i) {
            if (tagname:!=substr(taglist[i],1,length(tagname))) {
               taglist._deleteel(i);
               filelist._deleteel(i);
               --i;
            }
         }
      }
   }
#endif

   // If there is nothing left in the taglist or filelist, return failure:
   if (taglist._length() == 0 || filelist._length() == 0) {
      return(-1);
   }

   _str list[]; list=taglist;    // Copy the list
   list._sort();
   _aremove_duplicates(list,false);
   //messageNwait("prompt_user: len="taglist._length());
   if (list._length()>=2) {
      option := "-reinit";
      if (_find_formobj("_sellist_form")) {
         option="-new";
      }
      tagname=show("_sellist_form -mdi -modal "option,
                  nls("Select a Tag Name %s",more_caption),
                  SL_SELECTCLINE,
                  list,
                  "",
                  "",  // help item name
                  "",  // font
                  ""   // Call back function
                 );
   } else {
      tagname=list[0];
   }
   if (tagname=="") {
      return(COMMAND_CANCELLED_RC);
   }

   tag_decompose_tag_browse_info(tagname, auto cm);
   proc_name := cm.member_name;
   // Now that the exact tag and tag type has been selected,
   // we can remove other types
   for (i:=0;i<taglist._length();++i) {
      if ( taglist[i]!=tagname) {
         taglist._deleteel(i);
         filelist._deleteel(i);
         if (linelist._length()>i) linelist._deleteel(i);
         --i;
      }
   }
   _str flist[];flist=filelist;
   filelist._sort('f');
   _aremove_duplicates(filelist,_fpos_case:=="I");

   // float files from current workspace to the top of the list
   // don't bother if current buffer isn't in project
   if (_haveContextTagging()) {
      tagfilename := "";
      project_tagfiles := project_tags_filenamea();
      foreach (tagfilename in project_tagfiles) {
         if (tagfilename!="" && tag_read_db(tagfilename)>=0) {
            found := 0;
            for (i=0;i<filelist._length();++i) {
               if (tag_find_file(filename,filelist[i])==0) {
                  for (j:=i; j>found; --j) {
                     filelist[j]=filelist[j-1];
                  }
                  filelist[found++]=filename;
               }
            }
            tag_reset_find_file();
         }
      }
   }

   // force current buffer to the top of the list
   if (_isEditorCtl()) {
      for (i=0;i<filelist._length();++i) {
         if (_file_eq(filelist[i],p_buf_name)) {
            for (j:=i; j>0; --j) {
               filelist[j]=filelist[j-1];
            }
            filelist[0]=p_buf_name;
            break;
         }
      }
   }

   if ( filelist._length()>1 ) {
      option := "-reinit";
      if (_find_formobj("_sellist_form")) {
         option="-new";
      }
      filename=show("_sellist_form -mdi -modal "option,
                  nls('Select a File with "%s"',proc_name),
                  SL_SELECTCLINE,
                  filelist,
                  "",
                  "",        // help item name
                  "",                    // font
                  ""   // Call back function
                 );
   } else {
      filename=filelist[0];
   }
   if (filename=="") {
      return(COMMAND_CANCELLED_RC);
   }
   // now that the file has been selected, remove other items from linelist
   if (linelist._length()) {
      for (i=0;i<flist._length();++i) {
         if ( flist[i]!=filename) {
            if (linelist._length()>i) linelist._deleteel(i);
            flist._deleteel(i);
            --i;
         }
      }
      linelist._sort();
   }
   // that's all
   return(0);
}

static _str _taglist_callback(int reason,var result,typeless key)
{
   if (reason==SL_ONDEFAULT) {  // Enter key
      result=_sellist.p_line-1;
      return(1);
   }
   return("");
}

// Hash table of old tag files that attempts to rebuild results in errors.
// This can be because the tag file is read-only, or because the none
// of the source files pointed to the tag file no longer exist on disk.
static bool gTagFilesThatCantBeRebuilt:[];

/**
 * Maybe build a tag file for the given file extension.  This takes
 * advantage of the built-in _[ext]_maybeBuildTagFile callbacks, and
 * will automatically build the tag file for that extension if possible.
 * <P>
 * In addition, this function cycles through all the tag files in the
 * current extension and makes sure that they are up-to-date, if they
 * are not, it will automatically rebuild the tag file.
 *
 * @param lang       Language ID, see {@link p_LangId} 
 * @param withRefs   Build the tag file with support for symbol cross-referencing 
 * @param useThreads Build the tag file in the background if possible 
 * 
 * @categories Tagging_Functions
 */
void MaybeBuildTagFile(_str lang="", bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return;
   }

   // do not let this happen from a timer unless on a thread
   if (!useThread && autosave_timer_running()) {
      return;
   }
   // do not let this happen when someone is just moving the mouse around
   if (mousemove_handler_running()) {
      return;
   }
   if(!forceRebuild && !_default_option(VSOPTION_AUTO_BUILD_TAG_FILES)) {
      return;
   }

   // make sure we do not get in here twice
   static bool inMaybeBuildTagFile;
   if (inMaybeBuildTagFile) {
      return;
   }
   inMaybeBuildTagFile=true;

   //messageNwait('p_LangId='p_LangId);
   if (lang=="" && _isEditorCtl()) lang=p_LangId;
   tfindex := 0;
   index := find_index("_"lang"_MaybeBuildTagFile",PROC_TYPE);
   if (index_callable(index)) {
      if (!isdirectory(_tagfiles_path())) {
         mkdir(_tagfiles_path());
      }
      // verify that we have "maketags" available
      slickc_filename := path_search("maketags"_macro_ext,"VSLICKMACROS");
      if (slickc_filename=="") {
         slickc_filename=path_search("maketags"_macro_ext"x","VSLICKMACROS");
      }
      if (slickc_filename!="") {
         call_index(tfindex, withRefs, useThread, forceRebuild, index);
      }
   }

   // do not let tag file rebuilding triggers happen from a timer
   if (autosave_timer_running()) {
      inMaybeBuildTagFile=false;
      return;
   }

   // check if we have any out-of-date tag files for this lang
   tag_files := tags_filenamea(lang);
   i := 0;
   Noffiles := 0;
   tag_filename := next_tag_filea(tag_files, i, false, true);
   while (tag_filename != "") {
      if (tag_current_version() < VS_TAG_LATEST_VERSION &&
          !gTagFilesThatCantBeRebuilt._indexin(_file_case(tag_filename))) {
         // this tag file is out of date and needs to be rebuilt
         tag_get_detail(VS_TAGDETAIL_num_files,Noffiles);
         generate_refs := (tag_get_db_flags() & VS_DBFLAG_occurrences) != 0;
         if (_IsAutoUpdatedTagFile(tag_filename)) {
            message(nls("Auto updated tag file has old version.  Use 'vsmktags' to regenerate '%s'.",tag_filename));
            gTagFilesThatCantBeRebuilt:[_file_case(tag_filename)] = true;
         } else {
            useThread = useThread || _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
            if (useThread || Noffiles < 4000) {
               RetagFilesInTagFile(tag_filename,true,generate_refs,true,true,useThread,true);
            }
            if (useThread) delay(100);
            tag_read_db(tag_filename);
            if (tag_current_version() < VS_TAG_LATEST_VERSION) {
               message(nls("Tag file '%s' has old version and cannot be rebuilt.",tag_filename));
               gTagFilesThatCantBeRebuilt:[_file_case(tag_filename)] = true;
            }
         }
      }
      tag_filename = next_tag_filea(tag_files, i, false, true);
   }

   // finished success
   inMaybeBuildTagFile=false;
}
/**
 * @return
 * Return the standard path for storing language specific
 * builtins files.  If no file is found, return "";
 */
_str ext_builtins_path(_str lang, _str basename="")
{
   // If they did not specify a basename, use the language ID
   if (basename == "") {
      basename = lang;
   }
   // Look for a tagdoc file in the user's configuration directory
   extra_file := _ConfigPath() :+ basename".tagdoc";
   if (file_exists(extra_file)) {
      return(extra_file);
   }

   // If not there, then look in 'sysconfig/tagging/builtins' directory
   extra_file = _getSysconfigMaybeFixPath("tagging":+FILESEP:+"builtins":+FILESEP:+basename".tagdocdir");
   if (isdirectory(extra_file) && file_exists(extra_file)) {
      return(extra_file:+"/*");
   }

   // If not there, then look in 'sysconfig/tagging/builtins' directory
   extra_file = _getSysconfigMaybeFixPath("tagging":+FILESEP:+"builtins":+FILESEP:+basename".tagdoc", true);
   if (file_exists(extra_file)) {
      return(extra_file);
   }
   extra_file = _getSysconfigMaybeFixPath("tagging":+FILESEP:+"builtins":+FILESEP:+"builtins.":+lang, true);
   if (file_exists(extra_file)) {
      return(extra_file);
   }
   if (_LanguageInheritsFrom("xml", lang)) {
      extra_file = _getSysconfigMaybeFixPath("tagging":+FILESEP:+"builtins":+FILESEP:+basename".dtd", true);
      if (file_exists(extra_file)) {
         return(extra_file);
      }
      extra_file = _getSysconfigMaybeFixPath("tagging":+FILESEP:+"builtins":+FILESEP:+basename".xsd", true);
      if (file_exists(extra_file)) {
         return(extra_file);
      }
   }
   extra_file = _getSysconfigMaybeFixPath("tagging":+FILESEP:+"builtins":+FILESEP:+basename".zip", true);
   if (file_exists(extra_file)) {
      return(extra_file);
   }

   // did not find the file
   return("");
}
/**
 * Find the path name under the given base path with
 * the highest (lexicographically) version number.
 * <P>
 * For example, if there are the following directories under /opt:
 * <PRE>>
 *    /opt/jdk1.0.2
 *    /opt/jdk1.1.7
 *    /opt/jdk1.2.2
 *    /opt/jdk1.3
 * </PRE>
 * This function will return /opt/jdk1.3/, indicating that
 * is is the presumed "latest" version.
 *
 * @param basepath    base path to search, e.g. /opt/jdk
 *
 * @return "latest" version found, "" if there are none.
 */
_str latest_version_path(_str basepath)
{
   _str greatest=basepath;
   f := file_match('"'basepath'" +DP',1);
   while (f!="") {
      if (f>greatest) greatest=f;
      f=file_match('"'basepath': +DP',0);
   }
   if (greatest==basepath) return("");
   _maybe_append_filesep(greatest);
   return greatest;
}
/**
 * Return the standard path for storing tag files.
 */
_str _tagfiles_path()
{
   return _ConfigPath():+"tagfiles":+FILESEP;
}
/**
 * Return the path to the global tag files directory
 */
_str _global_tagfiles_path()
{
   return _getSlickEditInstallPath():+"tagfiles":+FILESEP;
}
/**
 * Generic function for building tag file when the only thing
 * to tag is one file contain declarations of builtin functions. 
 * This function can also be passed a list of paths to tag.
 *
 * @param tfindex       (reference) index of def_tagfiles_[lang]
 * @param lang          language ID
 * @param basename      base name of language specific tagfile
 * @param description   tag file description 
 * @param path_list     list of file paths to build tag file from 
 * @param recursive     search 'path_list' recursively for files to tag 
 * @param withRefs      Build the tag file with support for symbol cross-referencing 
 * @param useThreads    Build the tag file in the background if possible 
 *
 * @return 0 on success, <0 on error.
 */
int ext_MaybeBuildTagFile(int &tfindex, 
                          _str lang,
                          _str basename="", 
                          _str description="", 
                          _str path_list="", 
                          bool recursive=false,
                          bool withRefs=false, 
                          bool useThread=false,
                          bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // If they did not specify a basename, use the language ID
   if (basename == "") {
      basename = lang;
   }

   // maybe we can recycle tag file
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,lang,basename) && !forceRebuild) {
      return(0);
   }

   // If they did not specify a description, create one
   if (description == "") {
      description = _LangGetModeName(lang):+" Builtins";
   }

   // run maketags and tag just the builtins file.
   extra_file := ext_builtins_path(lang, basename);
   if (extra_file=="" || (!iswildcard(extra_file) && !file_exists(extra_file))) {
      return(1);
   }
   return ext_BuildTagFile(tfindex, tagfilename,
                           lang, description,
                           recursive, path_list, extra_file,
                           withRefs, useThread);
}
/**
 * Generic function for recycling a language specific tag file.
 * If a tag file is found in the global configuration directory,
 * and the expected name matches, it is added to def_tagfiles_[lang]
 * for the given file language.
 * <P>
 * Whether this function succeeds or not, 'tfindex' and 'tagfilename'
 * will be set appropriately upon return.
 * <P>
 * If this function returns true, then we can assume that the
 * automatically built language specific tag file for the given
 * language is already set up, so there is nothing more to do.
 * <P>
 * If this function returns false, the tag file needs to be built
 * (or rebuilt).
 *
 * @param tfindex      (reference) index of def_tagfiles_[lang]
 * @param tagfilename  (reference) path to language specific tag file
 * @param lang         language ID
 * @param basename     (optional) base name of language specific tagfile
 *
 * @return true if tag file was already set up or recycled
 *         for this language, otherwise return false
 */
bool ext_MaybeRecycleTagFile(int &tfindex, _str &tagfilename,
                             _str lang, _str basename="")
{
   if (!_haveContextTagging()) {
      return false;
   }
   tfindex=0;

   // If they did not specify a basename, use the language ID
   if (basename == "") {
      basename = lang;
   }

   // look up tag files for this language
   name_part := basename:+TAG_FILE_EXT;
   tagfilename = absolute(_tagfiles_path():+name_part);
   tfindex=find_index("def-tagfiles-"lang,MISC_TYPE);

   // just return if the tag file is already set up
   langTagFileList := LanguageSettings.getTagFileList(lang);
   if (pos(FILESEP:+name_part,langTagFileList,1,_fpos_case) || pos(FILESEP2:+name_part,langTagFileList,1,_fpos_case)) {
      // tag file doesn't exist?  then return false
      if (tagfilename=="" || !file_exists(tagfilename) || tag_read_db(tagfilename)==FILE_NOT_FOUND_RC) {
         return(false);
      }
      // status==0, or we have unhandled error opening tag file
      return(true);
   }

   // is there a tag file matching the name we are looking for
   // in the user or global configuration directory?
   if (tagfilename=="" || !file_exists(tagfilename) || tag_read_db(tagfilename) < 0) {
      // do not go after global tag file if they want local state
      // for performance, or if it is the same directory again
      if (/*def_localsta ||*/ _file_eq(_tagfiles_path(),_global_tagfiles_path())) {
         return(false);
      }
      // try to find the global tag file
      tagfilename = absolute(_global_tagfiles_path():+name_part);
      if (tagfilename=="" || !file_exists(tagfilename) || tag_read_db(tagfilename) < 0) {
         tagfilename=absolute(_tagfiles_path():+name_part);
         return(false);
      }
   }

   // set up the tag file path
   message("Adding tag file "tagfilename"...");
   LanguageSettings.setTagFileList(lang, tagfilename, true);
   message("Added tag file "tagfilename);

   // that's all folks
   return(true);
}
/**
 * Utility function for building a tag file, calls maketags for you and
 * does the other dirty work, such as setting the tag file path, invoking
 * the callbacks, and setting _config_modify.
 *
 * @param tfindex       (reference) index of def_tagfiles_[lang]
 * @param tagfilename   path to language tag file
 * @param lang          language ID
 * @param tagfiledesc   description of tag file
 * @param recursive     search for matches recursively under path1 and path2?
 * @param path_list     list of file paths or wildcards to pass to maketags
 * @param extra_file    path to 'builtins' file
 * @param withRefs      Build the tag file with support for symbol cross-referencing 
 * @param useThreads    Build the tag file in the background if possible 
 *
 * @return 0 on success, nonzero on error
 */
int ext_BuildTagFile(int &tfindex,
                     _str tagfilename,
                     _str lang,
                     _str tagfiledesc,
                     bool recursive,
                     _str path_list,
                     _str extra_file="", 
                     bool withRefs=false, 
                     bool useThread=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // close the tagfile before rebuilding it if it is open
   tag_close_db(tagfilename);

   // run maketags
   status := 0;
   updateOpt     := "";
   treeOpt       := recursive? " -t": "";
   referencesOpt := withRefs?  " -x": "";
   threadOpt     := useThread? " -B": "";
   if (path_list != "") {
      updateOpt      = "-r ";
      status=shell("maketags "treeOpt:+referencesOpt:+threadOpt" -c ":+
                       '-n "'tagfiledesc'" -o ' :+
                       _maybe_quote_filename(tagfilename)" "path_list);
   }

   // quote the extra file, and make sure it exists.
   if (!status && extra_file!="") {
      status=shell("maketags "updateOpt:+referencesOpt:+threadOpt" -o " :+
                   _maybe_quote_filename(tagfilename)" " :+
                   _maybe_quote_filename(extra_file));
   }

   // set def-tagfiles-ext
   LanguageSettings.setTagFileList(lang, tagfilename, true);
   tfindex = 0;

   // that's all folks
   return(status);
}

/**
 * Search for tags matching the given search pattern.
 * Note: 'gt' is shorthand for the grep-tag command.
 * <PRE>
 *   Usage:  gt/tag_name_regex/search_options
 * </PRE>
 *
 * @param search_str   Regex and search options.
 * The following search options are accepted:
 * <DL compact>
 * <DT>E</DT><DD>Case-sensitive match</DD>
 * <DT>I</DT><DD>Case-insensitive match</DD>
 * <DT>R</DT><DD>Interpret string as a SlickEdit regular expression. 
 *               See section <a href="help:SlickEdit regular expressions">SlickEdit Regular Expressions</a>.</DD>
 * <DT>L</DT><DD>Interpret string as a Perl regular expression. 
 *               See section <a href="help:Perl regular expressions">Perl Regular Expressions</a>.</DD>
 * <DT>~</DT><DD>Interpret string as a Vim regular expression. 
 *               See section <a href="help:Vim regular expressions">Vim Regular Expressions</a>.</DD>
 * <DT>U</DT><DD>Interpret string as a Perl regular expression. 
 *               See section <a href="help:Perl regular expressions">Perl Regular Expressions</a>.
 *               Support for Unix syntax regular expressions has been dropped.</DD>
 * <DT>B</DT><DD>Interpret string as a Perl regular expression. 
 *               See section <a href="help:Perl regular expressions">Perl Regular Expressions</a>.
 *               Support for Brief syntax regular expressions has been dropped.</DD>
 * <DT>&</DT><DD>Interpret string as a Wildcard regular expression.</DD>
 * <DT>A</DT><DD>Search all tag files, not just the workspace tag file.</DD>
 * <DT>P</DT><DD>Limit search to the current project only</DD>
 * <DT>S</DT><DD>Limit search to Slick-C tag file(s).</DD>
 * </DL>
 *
 * @return Returns 0 if successful.  Otherwise, a non-zero value is returned.
 *
 * @see f
 * @see push_tag
 * @see find_proc
 * @see find_tag
 * @see gui_push_tag
 * 
 * @categories Tagging_Functions
 */
_command grep_tag,gt(_str search_str="", _str options="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   // Default search options for case and re etc. not used when
   // this function is called with two arguments. This is so that
   // user defined keyboard macros work correctly when default
   // search options are changed.
   if ( arg() <= 1 || options=="") {
      if (search_str=="") {
         message(nls("Usage: gt/tag_name_regex/search_options"));
         return(1);
      }
      delim := "";
      orig_search_str := search_str;
      parse search_str with  1 delim +1 search_str (delim) options;
      if (isalnum(delim) || delim=="_") {
         search_str=orig_search_str;
         options="";
      }
   }
   options=upcase(options);
   project_only := (pos("P",options)>0);
   find_all := (pos("A",options)>0);
   find_slickc := (pos("S",options)>0);
   if (find_all || project_only || find_slickc) {
      options=stranslate(options,"","A");
      options=stranslate(options,"","P");
      options=stranslate(options,"","S");
   }
   if (!pos('^[eirubyapsl&]*$',options,1,'ri')) {
      _message_box(get_message(INVALID_ARGUMENT_RC));
      return(INVALID_ARGUMENT_RC);
   }

   if (!_haveContextTagging()) {
      if (search_str == "") {
         popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Tagging");
         return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG;
      }
      status := grep_ctags(search_str, options, false);
      if (status >= 0 || status == COMMAND_CANCELLED_RC) {
         return status;
      }
      tag_warn_no_symbols(search_str);
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   int i,n;
   lang := "";
   tag_name := "";
   context_found := false;
   tag_push_matches();

   embedded_status := 0;
   typeless orig_values;
   mou_hour_glass(true);
   if (_isEditorCtl()) {
      // we are an editor control, so search locals and context
      embedded_status = _EmbeddedStart(orig_values);
      lang=p_LangId;
      MaybeBuildTagFile(lang);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      sentry.lockMatches(true);
      _UpdateContext(true,true);
      _UpdateLocals(true,true);

      // get matches from locals
      message("searching context:");
      n=tag_get_num_of_locals();
      for (i=1; i<=n; i++) {
         tag_get_detail2(VS_TAGDETAIL_local_flags, i, auto local_flags);
         if (local_flags & SE_TAG_FLAG_IGNORE) continue;
         tag_get_detail2(VS_TAGDETAIL_local_name, i, tag_name);
         if (pos(search_str, tag_name, 1, options) > 0) {
            tag_insert_match_fast(VS_TAGMATCH_local,i);
            context_found=true;
         }
      }

      // get matches from current context
      n=tag_get_num_of_context();
      for (i=1; i<=n; i++) {
         tag_get_detail2(VS_TAGDETAIL_local_name, i, tag_name);
         if (pos(search_str, tag_name, 1, options) > 0) {
            tag_insert_match_fast(VS_TAGMATCH_context,i);
            context_found=true;
         }
      }
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
         embedded_status=0;
      }
   }

   status := 0;
   i=0;
   typeless tag_files;
   if (find_all || lang=="e") {
      tag_files=tags_filenamea(lang);
   } else if (find_slickc) {
      tag_files=tags_filenamea("e");
   } else {
      _str a[];
      a[0]=_GetWorkspaceTagsFilename();
      tag_files=a;
   }
   _str tag_filename = next_tag_filea(tag_files, i, false, true);
   while (tag_filename!="") {
      message("searching "tag_filename":");
      status = tag_find_regex(search_str, options);
      while (!status) {
         foundInProject := true;
         if (project_only) {
            file_name := "";
            tag_get_detail(VS_TAGDETAIL_file_name, file_name);
            _str relativeFilename = _RelativeToProject(file_name);
            if(_projectFindFile(_workspace_filename, _project_name, relativeFilename) == "") {
               foundInProject=false;
            }
         }
         if (foundInProject) {
            tag_insert_match_fast(VS_TAGMATCH_tag,0);
         }
         status = tag_next_regex(search_str, options);
      }
      tag_reset_find_tag();
      tag_filename = next_tag_filea(tag_files, i, false, true);
   }
   mou_hour_glass(false);
   clear_message();

   // save current selection
   typeless mark="";
   if ( _select_type()!="" ) {
      mark=_duplicate_selection();
      if ( mark<0 ) {
         tag_pop_matches();
         return(NOT_ENOUGH_MEMORY_RC);
      }
   }

   // check if the user used regex options but didn't specify regex
   if (!pos("r",options,1,'i') && search_str != _escape_re_chars(search_str) && tag_get_num_of_matches() <= 0) {
      return grep_tag(search_str,"r":+options);
   }

   // prompt for which tag to go to
   tag_init_tag_browse_info(auto cm);
   status = tag_select_symbol_match(cm);
   if (status == BT_RECORD_NOT_FOUND_RC) {
      if (_MaybeRetryTaggingWhenFinished()) {
         tag_pop_matches();
         return grep_tag(search_str, options);
      }
      _message_box(nls("Tag containing "'%s'" not found",search_str));
   }
   if (status < 0) {
      tag_pop_matches();
      return status;
   }

   // now go to the selected match
   status = tag_edit_symbol(cm);
   if (status < 0) {
      tag_pop_matches();
      return status;
   }

   // set a bookmark
   if ( mark!="" ) {
      int old_mark=_duplicate_selection("");
      _show_selection(mark);
      _free_selection(old_mark);
   } else {
      _deselect();
   }

   // that's all folks
   tag_pop_matches();
   return(status);
}
int _OnUpdate_grep_tag(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveContextTagging() && !_haveCtags()) {
      return MF_GRAYED|MF_REQUIRES_PRO_OR_STANDARD;
   }
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}

int _resolve_include_file(_str &filename, bool quiet=false) 
{
   match := strip(filename, 'B', '"');
   match = strip(match, 'B', "'");
   filename = match;
   isHTTPFile := false;
   if ( filename!="" && (!iswildcard(filename) || file_exists(filename)) ) {
      //messageNwait('filename='filename);
      isHTTPFile = _isHTTPFile(filename) != 0;
      if (!isHTTPFile && _FileQType(p_buf_name)==VSFILETYPE_URL_FILE &&
          // This is not an absolute path
           !(isdrive(substr(filename,1,2)) ||
            substr(filename,1,1)=="/" || substr(filename,1,1)=='\'
           )
          ) {
         isHTTPFile=true;
         //say('p_DocumentName='p_DocumentName);
         path := _strip_filename(translate(p_DocumentName,FILESEP,FILESEP2),'N');
         filename=translate(path,'/','\'):+filename;
      }
      match = filename;
      if (!isHTTPFile) {
         match = file_match2(filename,1,"-pd");
         if ( match=="" ) {
            match = file_match2(_strip_filename(p_buf_name,'N'):+filename,1,"-pd");
            if ( match=="" ) {
               ext := _get_extension(p_buf_name);
               if ( _file_eq("."ext,_macro_ext) || _file_eq(ext,"cmd") ) {
                  info := get_env("VSLICKINCLUDE");
                  if (info!="") {
                     match = include_search(filename,info);
                  }
               }
               if (match == "") {
                  info := _ProjectGet_IncludesList(_ProjectHandle(),_project_get_section(gActiveConfigName));
                  info = _absolute_includedirs(info, _project_get_filename());
                  match = include_search(filename,info);
                  // DJB (11-06-2006) -- last ditch effort, check refactoring
                  // compiler configuration for include paths to search
                  if (_LanguageInheritsFrom("c") && match=="" && _haveBuild()) {
                     header_file := "";
                     compiler_includes := "";
                     compiler_status := refactor_get_active_config(header_file, compiler_includes, _ProjectHandle(), quiet);
                     if (!compiler_status) {
                        match = include_search(filename,compiler_includes);
                     }
                  }
                  if (_isUnix()) {
                     if (_LanguageInheritsFrom("c") && match=="") {
                        match = include_search(filename,"/usr/include/");
                     }
                  }
               }
            }
         }
         // if not found, try searching the entire workspace
         if (match=="") {
            match = _ProjectWorkspaceFindFile(filename, true, false, quiet);
            if (match == COMMAND_CANCELLED_RC) {
               return COMMAND_CANCELLED_RC;
            }
         } else if (quiet) {
            match = _maybe_quote_filename(match);
         }
         // if still not found, try prompting for path
         if (match=="") {
            static _str last_dir;
            if (last_dir!="" && file_exists(last_dir:+filename)) {
               match = last_dir:+filename;
            } else if (!quiet) {
               found_dir := _strip_filename(filename,'N');
               just_filename := _strip_filename(filename,'P');
               found_filename := _ChooseDirDialog("Find File", found_dir, just_filename);
               if (found_filename=="") {
                  return(COMMAND_CANCELLED_RC);
               }
               match = found_filename:+just_filename;
               if (quiet) match = _maybe_quote_filename(match);
               last_dir=found_filename;
            }
         }
      }
   }
   if ( match != "" ) {
      filename = match;
      return(0);
   }
   if (!quiet) {
      filename = _ShrinkFilenameToScreenWidth(filename);
      _message_box(nls("File '%s' not found",filename));
   }
   return(FILE_NOT_FOUND_RC);
}

int tag_get_current_include_info(VS_TAG_BROWSE_INFO &cm) 
{
   tag_init_tag_browse_info(cm);
   cm.line_no= -1;  // Don't do goto line
   typeless orig_values;
   embedded := _EmbeddedStart(orig_values);
   lang := p_LangId;
   status := 0;
   orig_line_no := p_line;
   if (_LanguageInheritsFrom("cob")) {
      // first get the project include file path
      cobol_copy_path := get_cobol_copy_path();
      cobol_copy_exts := get_cobol_copy_extensions();
      // search for copy book include statements
      save_pos(auto p);
      _begin_line();
      status=search('((include|copy|[-]INC|[%]INCLUDE|[+][+]INCLUDE)[ \t]+{"?+"|[~ \t]+}([ \t]|$))|$','@rihxcs');
      if (p_line != orig_line_no) status = STRING_NOT_FOUND_RC;
      color:=_clex_find(0,'g');
      restore_pos(p);
      if (!status && (color==CFG_KEYWORD || color==CFG_PPKEYWORD) && match_length()) {
         word := get_match_text(0);
         _maybe_strip(word, ".");
         filename := "";
         if (pathlen(p_buf_name)) {
            temp := _strip_filename(p_buf_name,"n"):+word;
            filename=path_search(temp, cobol_copy_path, "v", cobol_copy_exts);
         }
         if (filename=="") {
            filename=path_search(word, cobol_copy_path, "v", cobol_copy_exts);
         }
         if (filename!="") {
            result_dir := _strip_filename(filename,'N');
            if (upcase(result_dir) :== result_dir) {
               result_file := _strip_filename(filename,'P');
               split(cobol_copy_path,PATHSEP,auto paths);
               i := 0;
               for (i = 0; i < paths._length();i++) {
                  if (upcase(paths[i]) :== result_dir) {
                     filename = paths[i] :+ result_file;
                  }
               }
            }
            cm.file_name=filename;
            if (embedded == 1) {
               _EmbeddedEnd(orig_values);
            }
            return(0);
         }
      }
   } else if (_LanguageInheritsFrom("asm390")) {
      // first get the project include file path
      asm390_copy_path := get_asm390_macro_path();
      asm390_copy_exts := get_asm390_macro_extensions();
      // search for copy book include statements
      save_pos(auto p);
      _begin_line();
      status=search('((include|copy)[ \t]+{"?+"|[~ \t]+}([ \t]|$))|$','@rihxcs');
      if (p_line != orig_line_no) status = STRING_NOT_FOUND_RC;
      color:=_clex_find(0,'g');
      restore_pos(p);
      if (!status && color==CFG_KEYWORD && match_length()) {
         word := get_match_text(0);
         _maybe_strip(word, ".");
         _str temp;
         filename := "";
         if (pathlen(p_buf_name)) {
            temp=_strip_filename(p_buf_name,"n"):+word;
            filename=path_search(temp, asm390_copy_path, "v", asm390_copy_exts);
         }
         if (filename=="") {
            filename=path_search(temp, asm390_copy_path, "v", asm390_copy_exts);
         }
         if (filename!="") {
            cm.file_name=filename;
            if (embedded == 1) {
               _EmbeddedEnd(orig_values);
            }
            return(0);
         }
      }
   } else if (_LanguageInheritsFrom("ant")) {
      // see if the statement under the cursor is a file (wholesaled from cursor_error2) 
      http_extra := 'http\:/|ttp\:/|tp\:/|p\:/|\:/|/|';
      save_pos(auto p);
      search(':q|('http_extra'\:|):p|^','rh-');
      restore_pos(p);
      fn := get_match_text();
      fn=strip(fn,'B',"'");
      fn=_maybe_quote_filename(fn);
      // if we are on an xml file, jump to it
      _str proc_name = cur_word(auto sc);
      if (fn != "" && _get_extension(fn) == "xml" && !_ant_CursorOnProperty(proc_name, sc)) {
         cm.file_name = fn;
         return(0);
      }
   } else if (_LanguageInheritsFrom("pl1")) {
      // first get the project include file path
      project_include_path := "";
      if (_project_name != "") {
         project_include_path = project_include_filepath();
      }
      // now check the def var
      if (def_pl1_include_path!="") {
         _maybe_append(project_include_path, PATHSEP);
         project_include_path :+= def_pl1_include_path;
      }
      // search for copy book include statements
      save_pos(auto p);
      _begin_line();
      status=search('(include[ \t]+?+\({?+}\)([; \t]|$))|(include[ \t]+{#1"?+"|[~ \t;]+}([; \t]|$))|':+
                    '(inc[ \t]+?+\({?+}\)([; \t]|$))|(inc[ \t]+{#1"?+"|[~ \t;]+}([; \t]|$))|':+
                    '(xinclude[ \t]+?+\({?+}\)([; \t]|$))|(xinclude[ \t]+{#1"?+"|[~ \t;]+}([; \t]|$))|':+
                    '(xinscan[ \t]+?+\({?+}\)([; \t]|$))|(xinscan[ \t]+{#1"?+"|[~ \t;]+}([; \t]|$))|':+
                    '(inscan[ \t]+?+\({?+}\)([; \t]|$))|(inscan[ \t]+{#1"?+"|[~ \t;]+}([; \t]|$))|$','@rih');
      if (p_line != orig_line_no) status = STRING_NOT_FOUND_RC;
      color := _clex_find(0,'g');
      restore_pos(p);
      if (!status && (color==CFG_KEYWORD || color==CFG_PPKEYWORD) && match_length()) {
         word := get_match_text(0);
         word1 := get_match_text(1);
         if (word == "") {
            word = word1;
         }
         word = strip(word);
         _maybe_strip(word, ".");
         filename := "";
         if (pathlen(p_buf_name)) {
            project_include_path :+= PATHSEP :+ _strip_filename(p_buf_name,"n");
         }
         filename=path_search(word,project_include_path,"v",get_file_extensions_sorted_with_dot("pl1"));
         if (filename!="") {
            cm.file_name=filename;
            if (embedded == 1) {
               _EmbeddedEnd(orig_values);
            }
            return(0);
         }
      }
   } else if (_LanguageInheritsFrom("java") && _ProjectGet_AppType(_ProjectHandle()) == "android") {
      // for symbols from the R class, check if we have only 1 match which is in R.java
      // if that is the case, this symbol might reference a resource file
      // we can then check to see if we have an appropriately named resource file 
      VS_TAG_IDEXP_INFO idexp_info;
      tag_idexp_info_init(idexp_info);
      struct VS_TAG_RETURN_TYPE visited:[];
      status = _Embeddedget_expression_info(false, "java", idexp_info, visited);
      if (!status) {
         if (pos("R.",idexp_info.prefixexp) == 1) {
            context_found := context_find_tag(idexp_info.lastid);
            if (context_found && tag_get_num_of_matches() == 1) {
               tag_get_match_info(1, auto im);
               if (im.file_name && _strip_filename(im.file_name,"P") == "R.java") {
                  full_file := _ProjectWorkspaceFindFile(idexp_info.lastid".xml", true, false, true);
                  if (full_file != "") {
                     // just take first match
                     cm.file_name = parse_file(full_file, false);
                     tag_pop_matches();
                     return 0;
                  }
               }
            }
            tag_pop_matches();
         }
      }
   }

   _str line;
   get_line(line);
   if (line=="") {
      if (embedded == 1) {
         _EmbeddedEnd(orig_values);
      }
      return(FILE_NOT_FOUND_RC);
   }

   include_re:=_LangGetProperty(lang,VSLANGPROPNAME_INCLUDE_RE);
   if (pos(include_re,line,1,'ri')) {
      filename := substr(line,pos('S0'),pos('0'));
      if (filename!="") {
         if (_file_eq(lang,"pas") && _get_extension(filename)=="") {
            filename :+= ".pas";
         }
         cm.file_name=filename;
         file_line := substr(line,pos('S1'),pos('1'));
         if (_LanguageInheritsFrom("c") && isnumber(file_line)) {
            cm.line_no=(int)file_line;
         }
         return(0);
      }
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true);

   int context_id = tag_current_context();
   //MaybeBuildTagFile(p_LangId);
   if (context_id > 0 && _clex_find(0,'g')!=CFG_COMMENT) {
      include_line := 0;
      include_path := "";
      type_name := "";
      tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
      tag_get_detail2(VS_TAGDETAIL_context_line,context_id,include_line);
      if (type_name=="include" && p_line==include_line) {
         tag_get_detail2(VS_TAGDETAIL_context_return,context_id,include_path);
         if (include_path != "" && file_match(_maybe_quote_filename(include_path),1)!="")  {
            if (embedded == 1) {
               _EmbeddedEnd(orig_values);
            }
            // This should be an absolute path.
            cm.file_name=include_path;
            return(0);
         }
         tag_get_detail2(VS_TAGDETAIL_context_name,context_id,include_path);
         if (include_path != "" && _istagging_supported(p_LangId)) {
            if (embedded == 1) {
               _EmbeddedEnd(orig_values);
            }
            if (pos('^[ \t]*(\"[^\"]+\"|\<[^>]+\>)',include_path,1,'u') > 0) {
               include_path = get_match_substr(include_path, 1);
               include_path = substr(include_path, 2, length(include_path)-2);
            }
            cm.file_name=include_path;
            return(0);
         }
      }
   }
   if (embedded == 1) {
      _EmbeddedEnd(orig_values);
   }
   return(FILE_NOT_FOUND_RC);
}
/**
 * If the cursor is sitting on a keyword which is recognized generally 
 * to cause a local jump in execution, find the location that execution 
 * would continue at.  The following keywords are recognized: 
 *  
 * <dl compact> 
 * <dt>break</dt>    <dd>Go to end of corresponding [labelled] block</dd>
 * <dt>continue</dt> <dd>Go to start of corresponding [labelled] block</dd>
 * <dt>goto</dt>     <dd>Go to corresponding label</dd>
 * <dt>return</dt>   <dd>Go to the end of the current function</dd>
 * <dt>case</dt>     <dd>Go to the beginning of the current switch statement</dd>
 * </dl> 
 *  
 * This function could be extended to handle jumping to constructors 
 * on "new" and jumping to destructors on "delete". 
 * 
 * @param line_no    [output] Set to line number to jump to 
 * @param seek_pos   [output] set to seek position to jump to
 * 
 * @return 0 on success, <0 on error.
 */
int tag_get_continue_or_break_info(int &line_no, long &seek_pos, bool ForceUpdate=false) 
{
   // The cursor must start out sitting on a keyword
   if (_clex_find(0, 'g') != CFG_KEYWORD) {
      return STRING_NOT_FOUND_RC;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // now get the keyword, lowcase it for case-insensitive languages
   auto lastid = cur_identifier(auto start_col);
   if (!p_LangCaseSensitive) {
      lastid = lowcase(lastid);
   }

   // check if there is an optional label for the goto, break, or continue
   auto label_name = "";
   switch (lastid) {
   case "goto":
   case "break":
   case "continue":
      save_pos(auto p);
      save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
      p_col = start_col+length(lastid);
      _clex_skip_blanks();
      if (isalpha(get_text())) {
         label_name = cur_identifier(start_col);
      }
      restore_search(s1, s2, s3, s4, s5);
      restore_pos(p);
   }

   // now do something based on the keyword
   switch (lastid) {
   case "return":
   case "co_return":
   case "co_yield":
      {
         // just go to the end of the current function
         _UpdateContext(true,ForceUpdate);
         int context_id = tag_current_context();
         if (context_id > 0) {
            tag_get_context_info(context_id, auto cm);
            line_no  = cm.end_line_no;
            seek_pos = cm.end_seekpos-1;
            return 0;
         }
      }
      break;

   case "goto":
      {
         // move the cursor to the label, and recursively solve "goto"
         if (label_name=="") {
            return STRING_NOT_FOUND_RC;
         }
         // handle "goto case" as found in D language
         if (label_name=="case" || label_name=="default") {
            _UpdateStatements(true,ForceUpdate);
            int statement_id = tag_current_statement();
            if (statement_id > 0) {
               // first we parse out the target label from the statement information
               tag_get_detail2(VS_TAGDETAIL_statement_type, statement_id, auto statement_type);
               tag_get_detail2(VS_TAGDETAIL_statement_name, statement_id, auto statement_name);
               tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, statement_id, auto goto_case_start);
               parse statement_name with "goto" auto goto_case_name;
               goto_case_name = strip(goto_case_name):+":";

               // now we find our enclosing switch statement
               while (statement_id > 0) {
                  tag_get_detail2(VS_TAGDETAIL_statement_type, statement_id, statement_type);
                  tag_get_detail2(VS_TAGDETAIL_statement_name, statement_id, statement_name);
                  if (statement_type=="switch" || (statement_type=="if" && substr(statement_name, 1, 6)=="switch")) {
                     // now iterate forward until we either pass the switch statement
                     // or we find a matching case statement
                     tag_get_detail2(VS_TAGDETAIL_statement_end_seekpos, statement_id, auto switch_end_seekpos);
                     case_id := statement_id+1;
                     loop {
                        // past end of context items?
                        if (case_id > tag_get_num_of_statements()) {
                           break;
                        }
                        // past the end of the switch statement, oh brother
                        tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, case_id, auto case_start_seekpos);
                        if (case_start_seekpos > switch_end_seekpos) {
                           break;
                        }
                        // check that this case statement matches the outer switch
                        tag_get_detail2(VS_TAGDETAIL_statement_outer, case_id, auto case_outer_id);
                        if (case_outer_id == statement_id) {
                           // check if the case name matches the target 
                           // or if they are just trying to jump to the next case
                           tag_get_detail2(VS_TAGDETAIL_statement_name,  case_id, auto case_name);
                           case_name = strip(case_name);
                           if (case_name == goto_case_name ||
                              (goto_case_name=="case:" && case_start_seekpos > goto_case_start)) {
                              tag_get_statement_browse_info(case_id, auto cm);
                              line_no  = cm.line_no;
                              seek_pos = cm.seekpos;
                              return 0;
                           }
                        }
                        case_id++;
                     }
                     // we didn't find a matching case, drop back to
                     // just jumping to the top of the switch statement
                     tag_get_statement_browse_info(statement_id, auto cm);
                     line_no  = cm.line_no;
                     seek_pos = cm.seekpos;
                     return 0;
                  }
                  tag_get_detail2(VS_TAGDETAIL_statement_outer, statement_id, statement_id);
               }
            }
         }

         // simple case, just jump to the label
         save_pos(auto p);
         p_col = start_col;
         status := find_tag();
         if (!status) {
            line_no  = p_RLine;
            seek_pos = _QROffset();
         }
         restore_pos(p);
         return status;
      }
      break;

   case "continue":
   case "break":
      {
         // Use statement tagging to find the matching block start/end for
         // break and continue.
         _UpdateStatements(true,ForceUpdate);
         int statement_id = tag_current_statement();
         while (statement_id > 0) {
            tag_get_detail2(VS_TAGDETAIL_statement_type, statement_id, auto statement_type);
            tag_get_detail2(VS_TAGDETAIL_statement_name, statement_id, auto statement_name);
            if ((statement_type == "loop") || 
                (statement_type == "switch" && lastid=="break") || 
                (statement_type=="if" && substr(statement_name, 1, 6)=="switch" && lastid=="break")) {
               tag_get_statement_browse_info(statement_id, auto cm);
               if (lastid=="continue" || lastid=="case") {
                  line_no  = cm.line_no;
                  seek_pos = cm.seekpos;
               } else {
                  line_no  = cm.end_line_no;
                  seek_pos = cm.end_seekpos;
               }

               // no label name, so just use first match found
               if (label_name == "") {
                  return 0;
               }

               // check for matching labeled break or continue statements
               tag_get_statement_browse_info(statement_id-1, auto prev_cm);
               if (prev_cm.type_name=="label" && prev_cm.member_name==label_name) {
                  return 0;
               }
            }
            tag_get_detail2(VS_TAGDETAIL_statement_outer, statement_id, statement_id);
         }
      }
      break;

   case "case":
      {
         // Use statement tagging to find the matching block start/end for
         // break and continue.  
         _UpdateStatements(true,ForceUpdate);
         int statement_id = tag_current_statement();
         while (statement_id > 0) {
            tag_get_detail2(VS_TAGDETAIL_statement_type, statement_id, auto statement_type);
            tag_get_detail2(VS_TAGDETAIL_statement_name, statement_id, auto statement_name);
            if (statement_type=="switch" || (statement_type=="if" && substr(statement_name, 1, 6)=="switch")) {
               tag_get_statement_browse_info(statement_id, auto cm);
               line_no  = cm.line_no;
               seek_pos = cm.seekpos;
               return 0;
            }
            tag_get_detail2(VS_TAGDETAIL_statement_outer, statement_id, statement_id);
         }
      }
      break;

   case "yield":
      {
         // Use statement tagging to find the matching block end for yield
         _UpdateStatements(true,ForceUpdate);
         statement_id := tag_current_statement();
         while (statement_id > 0) {
            tag_get_detail2(VS_TAGDETAIL_statement_type, statement_id, auto statement_type);
            tag_get_detail2(VS_TAGDETAIL_statement_name, statement_id, auto statement_name);
            if (statement_type == "loop"   ||
                statement_type == "switch" ||
                (statement_type == "if" && substr(statement_name, 1, 4)!="case") ||
                statement_type == "try"    ||
                tag_tree_type_is_func(statement_type)) {
               tag_get_statement_browse_info(statement_id, auto cm);
               line_no  = cm.end_line_no;
               seek_pos = cm.end_seekpos;
               return 0;
            }
            // look further out
            tag_get_detail2(VS_TAGDETAIL_statement_outer, statement_id, statement_id);
         }
      }
      break;
   }

   return STRING_NOT_FOUND_RC;
}

/**
 * By default, this method will pop up a message box to warn the user that 
 * a symbol was not found.  However if the user has elected to only be 
 * informed with a less intrusive message on the message box, it will only 
 * do that. 
 * 
 * @param tagname    symbol that was being searched for
 */
void tag_warn_no_symbols(_str tagname)
{
   msg := get_message(VSCODEHELPRC_NO_SYMBOLS_FOUND, tagname, tagname);
   if (!_haveContextTagging()) {
      msg :+= "  ";
      if (ctags_filename() == "") {
         msg :+= "No 'tags' file.  ";
      }
      msg :+= get_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging"VSREGISTEREDTM);
   }

   option := (def_codehelp_flags & VSCODEHELPFLAG_FIND_TAG_ERROR_NO_MESSAGE_BOX)? 1:0;
   if (option) {
      message(msg);
      return;
   }

   result := checkBoxDialog("SlickEdit", msg, "Direct all future 'No symbols found' warnings to the message bar.", MB_OKCANCEL, option, "", "Context Tagging");
   if (result != IDCANCEL && _param1 == 1) {
      def_codehelp_flags |= VSCODEHELPFLAG_FIND_TAG_ERROR_NO_MESSAGE_BOX;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

/**
 * This command is the same as the {@link push_tag} command except
 * that no bookmark is pushed.
 *
 * @param params     command line parameters
 *                      -sc = include Slick-C&reg; and C/C++ tag files
 *                      -is = include Slick-C&reg; tag file
 *                      -c  = use context find tag to find proc_name
 *                      -cs = use strict case-sensitivity
 *                      proc_name = name of symbol to find
 * @param quiet      only return status, no message boxes 
 * @param extra_codehelp_flags 
 * 
 * @return Returns 0 if successful.  Otherwise, a non-zero value is returned.
 *
 * @appliesTo  Edit_Window
 * @see f
 * @see push_tag
 * @see push_alttag 
 * @see push_def
 * @see push_decl
 * @see find_proc
 * @see make_tags
 * @see gui_make_tags
 * @see gui_push_tag
 * 
 * @categories Tagging_Functions, Search_Functions
 */
_command find_tag(_str params="", bool quiet=false, VSCodeHelpFlags extra_codehelp_flags=VSCODEHELPFLAG_NULL) name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI)
{
   /* Clark: SlickEdit Tools only. When edit is called, a temp view is created
      and the global variable def_msvsp_temp_wid is set.  The caller must
      initialize this Slick-C variable before calling this function.
   */
   // create a new match set
   _SetTimeout(0);
   tag_push_matches();

   _str PrefixHashtable:[]=null;
   _str UriHashtable:[]=null;
   context_found := false;
   context_id    := 0;
   i := 0;

   // parse command line options
   tagfiles_ext := "";
   combine_slickc_and_c_tagfiles := false;
   includeSlickC := false;
   findAntTag := false;
   onAntPropertyRef := false;
   use_context_find := false;
   force_case_sensitivity := false;
   expected_line := 0;
   option := rest := "";
   for (;;) {
      parse params with option rest;
      if (lowcase(option)=="-e") {
         parse rest with tagfiles_ext params;
      } else if (lowcase(option)=="-sc") {
         combine_slickc_and_c_tagfiles=true;
         params=rest;
      } else if (lowcase(option)=="-is") {
         includeSlickC=true;
         params=rest;
      } else if (lowcase(option)=="-c") {
         use_context_find=true;
         params=rest;
      } else if (lowcase(option)=="-cs") {
         force_case_sensitivity=true;
         params=rest;
      } else if (lowcase(option)=="-line") {
         parse rest with auto line_str params;
         if (isuinteger(line_str)) expected_line = (int)line_str;
      } else {
         break;
      }
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // use Context Tagging(R) to find tag matches in current buffer
   VS_TAG_RETURN_TYPE find_visited:[];
   VS_TAG_BROWSE_INFO cm;
   embedded_status := 0;
   typeless orig_values;
   status := 0;
   view_id := 0;
   lang := "";
   proc_type  := "";
   proc_class := "";
   proc_name  := params;
   if ( params=="" ) {
      if( !_isEditorCtl()) {
         tag_pop_matches();
         if (_chdebug) {
            say("find_tag:  not in an editor control");
         }
         return(1);
      }
      // see if the statement under the cursor is a #include or variant
      status=tag_get_current_include_info(cm);
      if (!status) {
         if (_chdebug) {
            say("find_tag:  include file");
         }
         status=_resolve_include_file(cm.file_name);
         tag_pop_matches();
         if (status) return(status);
         status=tag_edit_symbol(cm);
         return(status);
      }
      // see if the word under the cursor is a keyword that indicates a jump
      status=tag_get_continue_or_break_info(auto target_line=0, auto target_seek=0, true);
      if (!status) {
         if (target_line > 0) {
            p_RLine = target_line;
            _GoToROffset(target_seek);
         }
         if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
            expand_line_level();
         }
         tag_pop_matches();
         if (_chdebug) {
            say("find_tag:  continue or break statement");
         }
         return 0;
      }

      // Try to find the symbol at the cursor.
      _UpdateContextAndTokens(true,true);
      context_id = tag_current_context();
      embedded_status = _EmbeddedStart(orig_values);
      MaybeBuildTagFile(p_LangId);

      // set up flags for context tagging, check if we should search 
      // for overridden virtual methods
      find_context_flags := (SE_TAG_CONTEXT_ANYTHING | SE_TAG_CONTEXT_ALLOW_LOCALS);
      if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_FIND_NO_DERIVED_VIRTUAL_OVERRIDES)) {
         find_context_flags |= (SE_TAG_CONTEXT_FIND_PARENTS);
         find_context_flags |= (SE_TAG_CONTEXT_FIND_DERIVED);
      }

      // check if we are in an include tag and if we can jump
      // straight to it the include file
      context_found=context_find_tag(proc_name,
                                     find_parents:true, 
                                     force_case_sensitive:false,
                                     def_tag_max_find_context_tags,
                                     filter_flags:  SE_TAG_FILTER_ANYTHING,
                                     context_flags: find_context_flags,
                                     visited: find_visited);

#if 0
      // If find-tag doesn't work in this case, try find matching paren / block
      if (!context_found && (!is_valid_idexp(proc_name) || _clex_find(0, 'g')==CFG_KEYWORD)) {
         int block_status = find_matching_paren(true);
         if (!block_status) {
            return(0);
         }
      }
#endif

      if (!context_found && !is_valid_idexp(proc_name)) {
         start_col := 0;
         proc_name=cur_identifier(start_col);
         if (proc_name=="") {
            proc_name=cur_word(start_col);
            start_col=_text_colc(start_col,"I");
         }
         if ( proc_name=="" ) {
            if (embedded_status==1) {
               _EmbeddedEnd(orig_values);
            }
            message(nls("No word at cursor"));
            tag_pop_matches();
            if (_chdebug) {
               say("find_tag:  no word at cursor");
            }
            return(2);
         }
         if (p_col < start_col || p_col >= start_col+length(proc_name)) {
            orig_col := p_col;
            p_col=start_col+length(proc_name);
            proc_name="";
            context_found=context_find_tag(proc_name, 
                                           find_parents:true, 
                                           force_case_sensitive:false, 
                                           def_tag_max_find_context_tags,
                                           visited: find_visited);
            p_col=orig_col;
            if (!context_found && !is_valid_idexp(proc_name)) {
               proc_name=cur_word(start_col);
               start_col=_text_colc(start_col,"I");
            }
         }
      }
      lang=_get_extension(p_buf_name);

      if(p_LangId == "html" && _haveContextTagging()) {
         _jsp_GetConfigPrefixToUriHash(PrefixHashtable);
         _jsp_GetConfigUriToFileHash(UriHashtable);
      }

      if (!context_found && p_LangId == "e" &&
          (_file_eq("."lang,_macro_ext) || _file_eq(lang,"sh")) ) {
         if (embedded_status==1) {
            _EmbeddedEnd(orig_values);
         }
         tag_pop_matches();
         if (_chdebug) {
            say("find_tag:  try slick-c find-proc");
         }
         return(find_proc(proc_name,force_case_sensitivity));
      }

      // special case to try to search ctags-based tag file
      if (!context_found && !_haveContextTagging() && _haveCtags()) {
         status = find_ctags(proc_name, false);
         if (status >= 0 || status == COMMAND_CANCELLED_RC) {
            if (_chdebug) {
               say("find_tag:  try ctags");
            }
            return status;
         }
         tag_warn_no_symbols(proc_name);
         return VSRC_FEATURE_REQUIRES_PRO_EDITION;
      }

      if (!context_found && p_LangId == ANT_LANG_ID && _in_string() ) {
         // current word instead of current indentifier is correct here
         proc_name = cur_word(auto sc);
         context_found=context_find_tag(proc_name, 
                                        find_parents:true, 
                                        force_case_sensitive:false, 
                                        def_tag_max_find_context_tags,
                                        visited: find_visited);
         findAntTag = true;
         onAntPropertyRef = _ant_CursorOnProperty(proc_name, sc);
      }

      if (!context_found && (p_LangId=="docbook") && _in_string() ) {
         // current word instead of current indentifier is correct here
         proc_name = cur_word(auto sc);
         context_found=context_find_tag(proc_name, 
                                        find_parents:true, 
                                        force_case_sensitive:false, 
                                        def_tag_max_find_context_tags,
                                        visited: find_visited);
      }

      if (!context_found && (p_LangId=="xml") && _in_string() && 
          _ProjectGet_AppType(_ProjectHandle()) == "android") {
         proc_name = cur_word(auto sc);
         context_found=context_find_tag(proc_name, 
                                        find_parents:true, 
                                        force_case_sensitive:false, 
                                        def_tag_max_find_context_tags,
                                        visited: find_visited);
      }

   } else if (use_context_find) {

      // look up proc_name using context sensitive tag search
      _UpdateContextAndTokens(true,true);
      _UpdateLocals(true);
      if (_isEditorCtl()) {
         if (embedded_status==1) {
            _EmbeddedStart(orig_values);
            embedded_status=0;
         }
         MaybeBuildTagFile(p_LangId);
      }

      tag_decompose_tag_browse_info(proc_name,auto proc_cm);
      proc_type  = proc_cm.type_name;
      proc_class = proc_cm.class_name;
      //proc_name = proc_cm.member_name;

      // DJB 04-23-2007
      // allow leading digits instead of just a regular identifier,
      // otherwise, lastpos() will come up with the wrong results
      // for symbols that have digits in the middle, like "name2obj".
      prefixexp := "";
      int p;
      if (_isEditorCtl()) {
         p=lastpos(_clex_identifier_re():+"$",proc_name,1,'r');
      } else {
         p=lastpos("(:i|):v",proc_name,MAXINT,'r');
      }
      if (p>1) {
         prefixexp=substr(proc_name,1,p-1);
         proc_name=substr(proc_name,p,pos(""));
      } else if (p==1) {
         proc_name=substr(proc_name,p,pos(""));
      }
      _str errorArgs[];
      find_status := _Embeddedfind_context_tags(errorArgs,prefixexp,proc_name,0,0,"");
      if (find_status >= 0 && tag_get_num_of_matches() > 0) {
         context_found=true;
      }
   } else {

      tag_decompose_tag_browse_info(proc_name,auto proc_cm);
      proc_type = proc_cm.type_name;
      proc_class = proc_cm.class_name;
      //proc_name = proc_cm.member_name;

      if (_isEditorCtl()) {
         if (embedded_status==1) {
            _EmbeddedStart(orig_values);
            embedded_status=0;
         }
         MaybeBuildTagFile(p_LangId);
      }
   }

/*
 * If in html and we can't find a tag in a tld file run through the prefixes for the current jsp file
 * and see if any of those match what he have and then direct the code to the shortname in the tld
 */

   // find the set of tag files to search
   tag_files := "";
   if (combine_slickc_and_c_tagfiles) {
      tag_files=tags_filename("e"):+PATHSEP:+tags_filename("c");
   } else if (params=="" && tagfiles_ext=="" &&
              _isEditorCtl() && _istagging_supported()) {
      tag_files=tags_filename(p_LangId /* context tag files*/, includeSlickC);
   } else if (tagfiles_ext!="") {
      tag_files=tags_filename(tagfiles_ext /* context tag files*/, includeSlickC);
   } else {
      tag_files=tags_filename("",includeSlickC);
   }
   if (_isEditorCtl() && embedded_status==1) {
      _EmbeddedEnd(orig_values);
      embedded_status=0;
   }
   if (!context_found && warn_if_no_tag_files(tag_files)) {
      tag_pop_matches();
      if (_chdebug) {
         say("find_tag:  no tag files");
      }
      return("");
   }

   // save current selection
   typeless mark="";
   if ( _select_type()!="" ) {
      mark=_duplicate_selection();
      if ( mark<0 ) {
         tag_pop_matches();
         return(NOT_ENOUGH_MEMORY_RC);
      }
   }

   // use default global tag search algorithm
   if (!context_found) {
      status=find_tag_matches(tag_files, proc_name);
      if (_chdebug) {
         say("find_tag:  searching for '"proc_name"' in tag files, status="status" num matches="tag_get_num_of_matches());
         _dump_var(tag_files, "find_tag: tag_files");
      }

      if (status) {

         // decompose the original proc name into tag, class, type
         tag_decompose_tag_browse_info(proc_name, auto orig_cm);

         // If we haven't found the tag by name maybe the tag is using
         // a JSP prefix. Try sticking the shortname of the TLD taglib
         // at the front of the tag.      
         if(_isEditorCtl() && p_LangId=="tld" && tag_get_num_of_matches() < 1) {
            _str firstPart, secondPart;
            parse orig_cm.member_name with firstPart ":" secondPart;

            // See if the prefix exists in our list of taglib mappings.
            // Get the corresponding uri and filename
            prefix := uri := tldfile := "";
            if (PrefixHashtable._indexin(firstPart)) {
               prefix = firstPart;
               uri = PrefixHashtable:[prefix];
               tldfile = UriHashtable:[uri];

               // Get the shortname for this tld file
               short_name := "";
               index := _FindLanguageCallbackIndex("vs%s-get-taglib-shortname",p_LangId);
               if(index) {
                  status = call_index(view_id, "", short_name, index); 
               }

               orig_cm.member_name = short_name :+ ":" :+ secondPart;
            }

            // Only if this prefix exists in the hashtable and it's tldfile matches
            // the file we are looking at do we search for this tag
            if (prefix != "" && _file_eq(p_buf_name,tldfile) && _istagging_supported(lang)) {
               i = tag_find_context_iterator(orig_cm.member_name, true, p_EmbeddedCaseSensitive);
               while (i > 0) {
                  _str i_file_name;
                  _str i_type_name;
                  _str i_class_name;
                  tag_get_detail2(VS_TAGDETAIL_context_type,i,i_type_name);
                  tag_get_detail2(VS_TAGDETAIL_context_class,i,i_class_name);
                  tag_get_detail2(VS_TAGDETAIL_context_file,i,i_file_name);
                  if ((orig_cm.type_name=="" || i_type_name == orig_cm.type_name) &&
                      (orig_cm.class_name==null || i_class_name == orig_cm.class_name || _LanguageInheritsFrom("cob"))) {
                     tag_insert_match_fast(VS_TAGMATCH_context, i);
                     status=0;
                  }
                  i = tag_next_context_iterator(orig_cm.member_name, i, true, p_EmbeddedCaseSensitive);
               }
            }
         }
      }
   }

   // warn user if we did not find any matches
   if (!quiet && tag_get_num_of_matches() <= 0) {
      if (proc_name == "" && _isEditorCtl()) {
         proc_name = cur_identifier(auto col);
      }
      if (_MaybeRetryTaggingWhenFinished()) {
         if (_chdebug) {
            say("find_tag:  retry tagging after tag file build finishes");
         }
         tag_pop_matches();
         return find_tag(params, quiet, extra_codehelp_flags);
      }
      tag_warn_no_symbols(proc_name);
      tag_pop_matches();
      if (_chdebug) {
         say("find_tag:  no matches found");
      }
      return BT_RECORD_NOT_FOUND_RC;
   }

   // check find tag options and override defaults if necessary
   codehelp_flags := _GetCodehelpFlags() | extra_codehelp_flags;
   if (extra_codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) {
      codehelp_flags &= ~(VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION);
      codehelp_flags |=  (VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS);
   }
   if (extra_codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION) {
      codehelp_flags &= ~(VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION);
   }
   if (codehelp_flags & (VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION|VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION)) {
      // DJB 04/172015
      //
      // Even though it is an imprecise interpretation of "Go to definition"
      // and "Go to declaration", it still makes sense to jump to the
      // prototype if sitting on the definition and vice-versa.
      //
      //codehelp_flags &= ~(VSCODEHELPFLAG_FIND_TAG_PREFERS_ALTERNATE);
   }
   filterForwardClasses := ((codehelp_flags & VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS)==0);
   filterImports        := filterForwardClasses;
   filterSignatures     := ((codehelp_flags & VSCODEHELPFLAG_FILTER_OVERLOADED_FUNCTIONS)!=0);
   if (_FindLanguageCallbackIndex("_%s_analyze_return_type") <= 0) {
      filterSignatures = false;
   }
   if (!_haveContextTagging()) {
      filterSignatures = false;
   }

   // check for strict case-sensitivity
   matchProc := "";
   if (force_case_sensitivity) {
      tag_decompose_tag_browse_info(proc_name, auto match_cm);
      matchProc = match_cm.member_name;
   }

   // If the parameters passed on the command line included a type name,
   // then filter out items that do not match that type (and class name).
   if (proc_type != "" && tag_get_num_of_matches() > 1) {
      have_proc_type_match := false;
      for (i=1; i<=tag_get_num_of_matches(); ++i) {
         tag_get_match_info(i, auto im);
         if ( im.type_name != proc_type) continue;
         if ( tag_compare_classes(im.class_name, proc_class, force_case_sensitivity) != 0) continue;
         have_proc_type_match = true;
         break;
      }
      if (have_proc_type_match) {
         for (i=tag_get_num_of_matches(); i>=1; --i) {
            tag_get_match_info(i, auto im);
            if ( im.type_name != proc_type || tag_compare_classes(im.class_name, proc_class, force_case_sensitivity) != 0) {
               tag_remove_match(i);
            }
         }
      }
   }

   // remove duplicate tags
   tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:false,
                                       filterDuplicateGlobalVars:false,
                                       filterForwardClasses,
                                       filterImports,
                                       filterDuplicateDefinitions:false,
                                       filterAllTagMatchesInContext:false,
                                       matchProc,
                                       filterSignatures,
                                       find_visited);
   if (_chdebug) {
      tag_dump_matches("find_tag: AFTER REMOVE DUPLCIATES");
   }

   // warn user if we did not find any matches
   if (force_case_sensitivity && !quiet && tag_get_num_of_matches() <= 0) {
      response := _message_box(nls("Tag '%s' not found.\n\nTry case-insensitive search?",proc_name),"Find Tag",MB_YESNO);
      if (response == IDYES) {
         tag_pop_matches();
         return find_tag(proc_name,quiet,extra_codehelp_flags);
      }
   }

   // symbol information for tag we will go to
   tag_init_tag_browse_info(cm);

   // maybe remove matches which are not ant target/property tags
   if (findAntTag) {
      tag_filter_ant_matches(onAntPropertyRef);
   } 

   if (expected_line != 0) {
      tag_filter_matches_on_line(expected_line);
      if (_chdebug) {
         tag_dump_matches("find_tag: AFTER REMOVE EXPECTED LINE="expected_line);
      }
   }

   // check if there is a preferred definition or declaration to jump to
   match_id := tag_check_for_preferred_symbol(codehelp_flags);
   if (match_id > 0) {

      // record the matches the user chose from
      tag_get_match_info(match_id, cm);
      push_tag_add_match(cm);
      for (i=1; i<=tag_get_num_of_matches(); ++i) {
         if (i==match_id) continue;
         tag_get_match_info(i, auto im);
         push_tag_add_match(im);
      }
      if (_chdebug) {
         say("find_tag: preferred symbol="match_id);
         tag_browse_info_dump(cm, "find_tag: preferred symbol");
      }

   } else {
      focus_wid := _get_focus();
      // present list of matches and go to the selected match
      status = tag_select_symbol_match(cm,true,codehelp_flags);
      if (status < 0) {
         tag_pop_matches();
         // Restore focus. We do this for the case of the Preview tool-window being auto-shown,
         // and the user hits ESC to cancel, so that focus goes back to where it came from and
         // not to the now hidden Preview window.
         if ( focus_wid ) {
            focus_wid._set_focus();
         }
         return status;
      }
   }

   // report which symbol was chosen
   if (_chdebug) {
      tag_browse_info_dump(cm, "find_tag: chosen symbol");
   }

   // now go to the selected tag
   status = tag_edit_symbol(cm);
   tag_pop_matches();
   return status;
}
int _OnUpdate_find_tag(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}

static _str _orig_item_text:[];
static _str _orig_help_text:[];

void _UncacheTagKeyInfo()
{
   _orig_item_text=null;
   _orig_help_text=null;
}

int _OnUpdate_push_ref(CMDUI &cmdui,int target_wid,_str command)
{
   word := "";
   int enabled=MF_ENABLED;
   codehelp_flags := VSCODEHELPFLAG_NULL;

   // (DJB 06-10-2003) We can still push-tag if tagging isn't supported in current buffer
   //
   if ( target_wid && target_wid._isEditorCtl() ) {
      codehelp_flags=target_wid._GetCodehelpFlags();
      if (!target_wid.is_valid_idexp(word)) {
         word=target_wid.cur_word(auto junk);
      }
   } else {
      enabled=MF_GRAYED;
      codehelp_flags=_GetCodehelpFlags();
   }

   // 12:14p 5/11/2009 - DWH - Check for p_mdi_child AND p_window_state.
   // Allow action for non-MDI windows, but can only check p_window_state for 
   // MDI child windows
   if (p_mdi_child && p_window_state:=='I') {
      enabled=MF_GRAYED;
   }

   if ((enabled == MF_ENABLED) && target_wid._in_string() && 
       ((target_wid._LanguageInheritsFrom("xml") ||
        target_wid._LanguageInheritsFrom("html")) && !target_wid.p_LangId=="ant")) {
      enabled=MF_GRAYED;
      word="";
   }

   command=translate(command,"-","_");
   int menu_handle=cmdui.menu_handle;
   int button_wid=cmdui.button_wid;
   if (button_wid) {
      /*if (word=="") {
         button_wid.p_message=msg;
      } else {
         button_wid.p_message=msg;
      } */
      return(enabled);
   }
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      return(0);
   }
   msg := "";
   if (command=="cb-find" || command=="cf") {
      if (!_haveContextTagging()) {
         if (cmdui.menu_handle) {
            _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
            _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
            return MF_DELETED|MF_REQUIRES_PRO;
         }
         return MF_GRAYED|MF_REQUIRES_PRO;
      }
      if (word=="") {
         msg = get_message(VSRC_SHOW_SYMBOL_NO_WORD);
      } else {
         msg = nls(get_message(VSRC_SHOW_SYMBOL), word);
      }
   } else if (command=="push-ref" || command=="r" || command=="mou-push-ref" || command=="find-refs") {
      if (!_haveContextTagging()) {
         if (cmdui.menu_handle) {
            _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
            _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
            return MF_DELETED|MF_REQUIRES_PRO;
         }
         return MF_GRAYED|MF_REQUIRES_PRO;
      }
      if (def_references_options & VSREF_DO_NOT_GO_TO_FIRST) {
         if (word=="") {
            msg = get_message(VSRC_FIND_REFS_NO_WORD);
         } else {
            msg = nls(get_message(VSRC_FIND_REFS), word);
         }
      } else {
         if (word=="") {
            msg = get_message(VSRC_GO_TO_REFS_NO_WORD);
         } else {
            msg = nls(get_message(VSRC_GO_TO_REFS), word);
         }
      }
   } else if (command=="generate-debug") {
      if (!_haveContextTagging()) {
         if (cmdui.menu_handle) {
            _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
            _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
            return MF_DELETED|MF_REQUIRES_PRO;
         }
         return MF_GRAYED|MF_REQUIRES_PRO;
      }
      if (word=="") {
         msg = get_message(VSRC_GEN_DEBUG_NO_WORD);
      } else {
         msg = nls(get_message(VSRC_GEN_DEBUG), word);
      }
   } else if (command=="add-cursors-for-symbol") {
      if (!_haveContextTagging()) {
         if (cmdui.menu_handle) {
            _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
            _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
            return MF_DELETED|MF_REQUIRES_PRO;
         }
         return MF_GRAYED|MF_REQUIRES_PRO;
      }
      if (word=="") return MF_GRAYED;
      msg = nls(get_message(VSRC_ADD_CURSORS_FOR_SYMBOL), word);

   } else {

      // check if this is a #include statement
      isPoundInclude := false;
      isSlickC := false;
      if ( target_wid && target_wid._isEditorCtl()) {
         isSlickC = target_wid._LanguageInheritsFrom("e");
         if (target_wid._LanguageInheritsFrom("c") || isSlickC) {
            target_wid.get_line(auto current_line);
            if (pos('^[ \t]*[#][ \t]*(include|import|require)[ \t]*(\"[^\"]+\"|\<[^>]+\>)',current_line,1,'u') > 0) {
               word = get_match_substr(current_line, 2);
               isPoundInclude = true;
            }
         }
      }

      // disable push-tag, etc. for Standard edition
      if (!_haveContextTagging()) {
         if (!(isPoundInclude || isSlickC || 
               command == "find-ctags" || command == "grep-ctags" ||
               command == "push-tag"   || command == "grep-tag")) {
            if (cmdui.menu_handle) {
               _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
               _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
               return MF_DELETED|MF_REQUIRES_PRO;
            }
            return MF_GRAYED|MF_REQUIRES_PRO;
         }
      }

      goto_def := true;
      switch (command) {
      case "push-def":
         goto_def = true;
         break;
      case "push-decl":
         goto_def = false;
         break;
      case "mou-push-tag":
      case "push-tag":
      case 'push-tag-filter-overloads':
         goto_def = ((codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) == 0);
         break;
      case "mou-push-alttag":
      case "push-alttag":
         delete_alttag := false;
         if (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION) {
            goto_def = false;
         } else if (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) {
            goto_def = true;
         } else {
            delete_alttag = true;
         }
         if (delete_alttag || isPoundInclude || !_haveContextTagging()) {
            if (cmdui.menu_handle) {
               _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
               return MF_DELETED|MF_REQUIRES_PRO;
            }
         }
         break;
      }
      // Then set appropriate caption
      if (word=="" && goto_def) {
         msg = get_message(VSRC_GO_TO_DEF_NO_WORD);
      } else if (word=="" && !goto_def) {
         msg = get_message(VSRC_GO_TO_DECL_NO_WORD);
      } else if (isPoundInclude) {
         msg = nls(get_message(VSRC_GO_TO_INCLUDE), word);
      } else if (goto_def) {
         msg = nls(get_message(VSRC_GO_TO_DEF), word);
      } else {
         msg = nls(get_message(VSRC_GO_TO_DECL), word);
      }
   }
   if (cmdui.menu_handle) {
      if (!_orig_item_text._indexin(command)) {
         _orig_item_text:[command]="";
      }
      keys := text := "";
      parse _orig_item_text:[command] with keys "," text;
      if ( keys!=def_keys || text=="") {
         flags := 0;
         _str new_text;
         typeless junk;
         _menu_get_state(menu_handle,command,flags,'m',new_text,junk,junk,junk,_orig_help_text:[command]);
         if (keys!=def_keys || text=="") {
            text=new_text;
         }
         _orig_item_text:[command]=def_keys","text;
         //message '_orig_item_text='_orig_item_text;delay(300);
      }
      key_name := "";
      parse _orig_item_text:[command] with \t key_name;
      int status=_menu_set_state(menu_handle,
                                 cmdui.menu_pos,enabled,'p',
                                 msg"\t":+key_name,
                                 command,"","",
                                 _orig_help_text:[command]);
   }
   return(enabled);
}
int _OnUpdate_r(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_push_ref(cmdui, target_wid, command);
}

/**
 * Push a bookmark then jump to references to the symbol under the cursor.
 *
 * @return int
 * 
 * @categories Tagging_Functions, Search_Functions
 */
_command int push_ref,r(_str params="") name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (_no_child_windows()) {
      return(find_refs(params));
   }
   focus_wid := _get_focus();
   int mark=_alloc_selection('b');
   if ( mark<0 ) {
      return(mark);
   }
   _mdi.p_child.mark_already_open_destinations();
   _mdi.p_child._select_char(mark);
   //tag_refs_clear_pics();
   wid := p_window_id;
   int status=find_refs(params);
   if ( status /* or substr(p_buf_name,1,7)="Help on" */ ) {
      _free_selection(mark);
      return(status);
   }
   if (_iswindow_valid(wid)) {
      p_window_id = wid;
   }
   _mdi.p_child.push_destination();
   ret := _mdi.p_child.push_bookmark(mark, isReferences:true);
   if ( tw_is_auto_lowered_form("_tbtagrefs_form") ) {
      toolShowReferences();
   }
   return ret;
}
_command codehelp_trace_push_ref(_str proc_name="") name_info(TAG_ARG','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   orig_chdebug := _chdebug;
   _chdebug = 1;
   push_ref(proc_name);
   _chdebug = orig_chdebug;
}
int _OnUpdate_codehelp_trace_push_ref(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_push_ref(cmdui,target_wid,"push-ref");
}

/**
 * The <b>mou_push_ref</b> command places the cursor using the 
 * mouse position, pushes a bookmark, and then finds references 
 * to the symbol pointed to by the mouse.
 *
 * @see mou_click
 * @see push_ref 
 * @see mou_push_tag 
 *
 * @appliesTo Edit_Window
 * @categories Search_Functions, Mouse_Functions
 */
_command void mou_push_ref() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION|VSARG2_NOEXIT_SCROLL)
{
   mou_click();
   push_ref();
}
int _OnUpdate_mou_push_ref(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_push_ref(cmdui,target_wid,command);
}

/**
 * Find refernces to the symbol under the cursor.
 *
 * @param params           find tag options (-e [ext] or -sc for Slick-C&reg;)
 * 
 * @return 0 on success, <0 on error
 * 
 * @categories Tagging_Functions
 */
_command find_refs(_str params="", _str preview_option="") name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // create a new match set
   tag_push_matches();

   // parse command line options
   context_found := false;
   tagfiles_lang := "";
   combine_slickc_and_c_tagfiles := false;
   option := rest := "";
   for (;;) {
      parse params with option rest;
      if (lowcase(option)=="-e") {
         parse rest with tagfiles_lang params;
      } else if (lowcase(option)=="-sc") {
         combine_slickc_and_c_tagfiles=true;
         params=rest;
      } else {
         break;
      }
   }

   // attempt to use Context Tagging(R) to find symbol matches
   VS_TAG_RETURN_TYPE find_visited:[];
   focus_wid := _get_focus();
   embedded_status := 0;
   typeless orig_values;
   status := 0;
   ext := "";
   proc_name:=params;
   if ( params=="" ) {
      if( !_isEditorCtl()) {
         tag_pop_matches();
         return(1);
      }
      /* Try to find the procedure at the cursor. */
      //say("trying Context Tagging(R), proc_name="proc_name);
      _UpdateContextAndTokens(true,true);
      embedded_status = _EmbeddedStart(orig_values);
      MaybeBuildTagFile(p_LangId,true);

      context_found=context_find_tag(proc_name, 
                                     find_parents:true, 
                                     force_case_sensitive:false, 
                                     def_tag_max_find_context_tags,
                                     visited: find_visited);
      if (!context_found && !is_valid_idexp(proc_name)) {
         //say("Context Tagging(R) failed, reverting to current word only");
         start_col := 0;
         proc_name=cur_identifier(start_col);
         if (proc_name=="") {
            proc_name=cur_word(start_col);
            start_col=_text_colc(start_col,"I");
         }
         if ( proc_name=="" ) {
            if (embedded_status == 1) {
               _EmbeddedEnd(orig_values);
            }
            message(nls("No word at cursor"));
            tag_pop_matches();
            return(2);
         }
         if (p_col!=start_col) {
            orig_col := p_col;
            p_col=start_col+length(proc_name);
            proc_name="";
            context_found=context_find_tag(proc_name, 
                                           find_parents:true, 
                                           force_case_sensitive:false, 
                                           def_tag_max_find_context_tags,
                                           visited: find_visited);
            p_col=orig_col;
            if (!context_found && !is_valid_idexp(proc_name)) {
               proc_name=cur_word(start_col);
               start_col=_text_colc(start_col,"I");
            }
         }
      }
      if (!context_found && (p_LangId=="docbook") && _in_string() ) {
         // current word instead of current indentifier is correct here
         proc_name = cur_word(auto sc);
         context_found=context_find_tag(proc_name, 
                                        find_parents:true, 
                                        force_case_sensitive:false, 
                                        def_tag_max_find_context_tags,
                                        visited: find_visited);
      }
      if (!context_found && (p_LangId=="android") && _in_string()) {
         // current word instead of current indentifier is correct here
         proc_name = cur_word(auto sc);
         context_found=context_find_tag(proc_name, 
                                        find_parents:true, 
                                        force_case_sensitive:false, 
                                        def_tag_max_find_context_tags,
                                        visited: find_visited);
      }
   } else {
      if (_isEditorCtl()) {
         if (embedded_status==1) {
            _EmbeddedStart(orig_values);
            embedded_status=0;
         }
         MaybeBuildTagFile(p_LangId,true);
      }
   }

   // compute the set of tag files to search
   tag_files := "";
   occ_lang := "";
   if (combine_slickc_and_c_tagfiles) {
      tag_files=tags_filename("e"):+PATHSEP:+tags_filename("c");
      // check if the current workspace tag file or extension specific
      // tag file requires occurrences to be tagged.
      if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
         tag_pop_matches();
         return(1);
      }
      occ_lang="c";
   } else if (params=="" && tagfiles_lang=="" &&
              _isEditorCtl() && _istagging_supported()) {
      tag_files=tags_filename(p_LangId /* context tag files*/);
      occ_lang=p_LangId;
   } else if (tagfiles_lang!="") {
      tag_files=tags_filename(tagfiles_lang /* context tag files*/);
      occ_lang=tagfiles_lang;
   } else {
      tag_files=tags_filename("",false);
      if (_isEditorCtl()) {
         occ_lang=p_LangId;
         if (!_istagging_supported(occ_lang)) {
            //tag_files="";
            occ_lang="";
         }
      }
   }

   // make sure that the tag file was built with references
   if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
      tag_pop_matches();
      return(1);
   }
   if (_isEditorCtl() && embedded_status==1) {
      _EmbeddedEnd(orig_values);
      embedded_status=0;
   }
   //if (!context_found && _istagging_supported(occ_lang) && warn_if_no_tag_files(tag_files)) {
   //   tag_pop_matches();
   //   return("");
   //}

   // save current selection
   typeless mark="";
   if ( _select_type()!="" ) {
      mark=_duplicate_selection();
      _select_type(mark, 'S', 'E');
      if ( mark<0 ) {
         tag_pop_matches();
         return(NOT_ENOUGH_MEMORY_RC);
      }
   }

   // filter out case-insenstive matches if requested.
   case_sensitive_proc_name := "";
   if (_isEditorCtl() && proc_name != "" && (_GetCodehelpFlags() & VSCODEHELPFLAG_GO_TO_DEF_CASE_SENSITIVE)) {
      tag_decompose_tag_browse_info(proc_name, auto proc_cm);
      case_sensitive_proc_name = proc_cm.member_name;
   }

   // remove duplicate tags
   tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:true, 
                                       filterDuplicateGlobalVars:true, 
                                       filterDuplicateClasses:true, 
                                       filterAllImports:true, 
                                       filterDuplicateDefinitions:false, 
                                       filterAllTagMatchesInContext:false, 
                                       case_sensitive_proc_name, 
                                       filterFunctionSignatures:false, 
                                       find_visited, 1, 
                                       filterAnonymousClasses:true, 
                                       filterTagUses:true, 
                                       filterTagAttributes:true);

   // if not find with Context Tagging(R), try conventional methods
   faking_it := false;
   if (!context_found || tag_get_num_of_matches() <= 0) {
      status=find_tag_matches(tag_files,proc_name);
      if (status && params!="") {
         status=find_tag_matches(tags_filename(),proc_name);
         if (!status) occ_lang="";
      }
      tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:true, 
                                          filterDuplicateGlobalVars:true, 
                                          filterDuplicateClasses:true, 
                                          filterAllImports:true, 
                                          filterDuplicateDefinitions:false, 
                                          filterAllTagMatchesInContext:false, 
                                          case_sensitive_proc_name, 
                                          filterFunctionSignatures:false, 
                                          find_visited, 1, 
                                          filterAnonymousClasses:true, 
                                          filterTagUses:true, 
                                          filterTagAttributes:true);
      if (/*status || */tag_get_num_of_matches() <= 0) {
         if (_MaybeRetryTaggingWhenFinished()) {
            return find_refs(params, preview_option);
         }

         // check if we should worn that the symbol was not found
         if (!(def_references_options & VSREF_SEARCH_WORDS_ANYWAY)) {

            msg := nls("Symbol '%s' not found.<p>Do you want to search for word matches?",proc_name);
            result := textBoxDialog("Symbol Not Found",
                 0,                                         // Flags
                 0,                                         // width
                "",                                         // help item
                "Ok,Cancel:_cancel\t-html "msg,                     // buttons and captions
                "",                                         // Retrieve Name
                "-CHECKBOX Always just search for word matches if the symbol was not found.:0" );
            if (result == 1/*Ok*/ && _param1 == 1) {
               def_references_options |= VSREF_SEARCH_WORDS_ANYWAY;
               _config_modify_flags(CFGMODIFY_DEFVAR);
            } else if (result != 1/*Ok*/) {
               tag_pop_matches();
               return COMMAND_CANCELLED_RC;
            }
         } else {
            // just warn them that the symbol was not found with an alert
            msg := nls("Symbol '%s' not found.  Searching for word matches.",proc_name);
            if (_isEditorCtl()) {
               notifyUserOfWarning(ALERT_SYMBOL_NOT_FOUND, msg, p_buf_name, p_RLine);
            } else {
               notifyUserOfWarning(ALERT_SYMBOL_NOT_FOUND, msg, "");
            }
         }

         // insert fake tag match
         tag_init_tag_browse_info(auto fake_cm, proc_name);
         tag_insert_match_browse_info(fake_cm);
         faking_it=true;
      }
   }

   tag_init_tag_browse_info(auto cm);
   if ( faking_it) {
      // just use the fake symbol as-is
      tag_get_match_info(1,cm);
      if (_isEditorCtl()) {
         cm.language=p_LangId;
      } else {
         cm.language=_Filename2LangId(cm.file_name);
      }

   } else {
      // check find tag options and override defaults if necessary
      // avoid prompting for declaration vs. definition of the same symbol
      project_flags := (_GetCodehelpFlags() & VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT);
      if (_GetReferencesLookinOption() == VS_TAG_FIND_TYPE_PROJECT_ONLY) {
         project_flags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT;
      }
      if (_GetReferencesLookinOption() == VS_TAG_FIND_TYPE_SAME_PROJECTS) {
         project_flags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT;
      }
      // determine if we should remove all function overloads
      if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_FILTER_OVERLOADED_FUNCTIONS)) {
         tag_remove_duplicate_symbols_from_matches_ignoring_function_arguments(project_flags);
      }
      match_id := tag_check_for_preferred_symbol(project_flags|VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION);
      if (match_id > 0) {
         // used the selected declaration
         tag_get_match_info(match_id, cm);
      } else {
         // prompt user to select match
         status = tag_select_symbol_match(cm);
         if (status < 0) {
            tag_pop_matches();
            return status;
         }
      }
   }

   // populate the references tool window
   if (_chdebug) {
      tag_browse_info_dump(cm, "find_refs");
   }
   toolShowReferences();
   status=refresh_references_tab(cm,true);
   preview_only := (preview_option!="");

   // advance to the first tag reference
   next_ref_status := 0;
   if (!status && !(def_references_options & VSREF_DO_NOT_GO_TO_FIRST)) {
      if (focus_wid) {
         /*
            When the references tool window is shown and is docked to the main mdi window, 
            the main MDI window becomes active. Here we restore focus to the floating
            MDI window which had focus. I only reproduced this bug when not in one
            file per window. Not sure why I didn't get the same problem in one file
            per window mode.
         */
         focus_wid._set_focus();
      }
      next_ref_status=next_ref(preview_only, false, true);
   }

   // set up find-next / find-prev
   if (!preview_only) {
      _gui_find_dismiss();
      _mffindNoMore(def_mfflags);
      _mfrefIsActive=true;
      set_find_next_msg("Find reference", _GetReferencesSymbolName());
   }

   // information user how to get next reference
   if (!preview_only && !next_ref_status) {
      bindings := "";
      text := "";
      if (def_mfflags & 1) {
         bindings=_mdi.p_child._where_is("find_next");
      } else {
         bindings=_mdi.p_child._where_is("next_error");
      }
      parse bindings with bindings ",";
      if (bindings!="") {
         text="Press "bindings:+" for next occurrence.";
      }
      sticky_message(text);
   }

   // restore selection
   if ( mark!="" ) {
      old_mark := _duplicate_selection("");
      _show_selection(mark);
      _free_selection(old_mark);
   } else {
      _deselect();
   }

   // that's all folks
   tag_pop_matches();
   return(status);
}
int _OnUpdate_find_refs(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_push_ref(cmdui,target_wid,command);
}

/**
 * Get tag information struct for the symbol under the cursor
 * 
 * @param params              find tag options (-e [ext] or -sc for Slick-C&reg;)
 * @param cm                  (output) symbol information
 * @param quiet               if true, just return status, no message boxes
 * @param all_choices         (output) array of choices
 * @param return_choices      return tag choices instead of prompting? 
 * @param filterDuplicates    Remove all duplicate symbol definitions.
 * @param filterPrototypes    Remove forward declarations of functions if the 
 *                            corresponding function definition is also present.
 * @param filterDefinitions   Remove duplicate function definitions
 * @param force_tag_search    Force tag search
 * @param filterFunctionSignatures  attempt to filter out function signatures 
 *                                  that do not match
 * @param visited             cache of previous tagging results
 * @param depth               depth of recursive search 
 * @param max_matches         maximum number of items to find 
 * @param filterTagUses       Filter out symbols of type 'taguse'.
 * @param filterAnnotations   Filter out tags of type 'annotation'.
 * 
 * @return 0 on success, <0 on error
 * 
 * @categories Tagging_Functions
 */
int tag_get_browse_info(_str params, 
                        struct VS_TAG_BROWSE_INFO& cm, 
                        bool quiet=false, 
                        struct VS_TAG_BROWSE_INFO (&all_choices)[]=null,
                        bool return_choices=false, 
                        bool filterDuplicates=true,
                        bool filterPrototypes=true,
                        bool filterDefinitions=false,
                        bool force_tag_search=false,
                        bool filterFunctionSignatures=false,
                        VS_TAG_RETURN_TYPE (&visited):[]=null, 
                        int depth=0,
                        int max_matches=def_tag_max_find_context_tags,
                        bool filterTagUses=true,
                        bool filterAnnotations=false,
                        bool filterImportsAndIncludes=false)
{
   // set up symbol filter and context tagging search flags
   context_flags := SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS;
   if (return_choices && !quiet && force_tag_search) {
      context_flags |= SE_TAG_CONTEXT_FIND_ALL;
      context_flags |= SE_TAG_CONTEXT_FIND_LENIENT;
      context_flags |= SE_TAG_CONTEXT_NO_GLOBALS;
   }
   filter_flags := SE_TAG_FILTER_ANYTHING;
   if (filterAnnotations) {
      filter_flags &= ~SE_TAG_FILTER_ANNOTATION;
   }
   if (filterTagUses) {
      filter_flags &= ~SE_TAG_FILTER_MISCELLANEOUS;
   }
   if (filterImportsAndIncludes) {
      filter_flags &= ~SE_TAG_FILTER_INCLUDE;
   }

#if 1

   // set up remove options
   VSTagRemoveDuplicatesOptionFlags removeDuplicatesOptions = 0;
   if (filterFunctionSignatures) {
      removeDuplicatesOptions |= VS_TAG_REMOVE_DUPLICATE_FUNCTION_SIGNATURES;
   }
   if (filterTagUses) {
      removeDuplicatesOptions |= VS_TAG_REMOVE_DUPLICATE_TAG_USES;
      removeDuplicatesOptions |= VS_TAG_REMOVE_DUPLICATE_TAG_ATTRIBUTES;
   }
   if (def_references_options & VSREF_ALLOW_MIXED_LANGUAGES) {
      removeDuplicatesOptions |= VS_TAG_REMOVE_INVALID_LANG_REFERENCES;
   }
   if (filterAnnotations) {
      removeDuplicatesOptions |= VS_TAG_REMOVE_DUPLICATE_ANNOTATIONS;
   }
   if (filterDuplicates) {
      removeDuplicatesOptions |= VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS;
   }
   if (filterPrototypes) {
      removeDuplicatesOptions |= VS_TAG_REMOVE_DUPLICATE_PROTOTYPES;
   }
   if (filterDefinitions) {
      removeDuplicatesOptions |= VS_TAG_REMOVE_DUPLICATE_SYMBOLS;
   }
   if (filterImportsAndIncludes) {
      removeDuplicatesOptions |= VS_TAG_REMOVE_DUPLICATE_IMPORTS;
   }

   return tag_get_browse_info_remove_duplicates(params, 
                                                cm, 
                                                quiet, 
                                                return_choices, 
                                                all_choices, 
                                                max_matches, 
                                                force_tag_search, 
                                                removeDuplicatesOptions, 
                                                filter_flags, 
                                                context_flags, 
                                                visited, depth);

#else

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // create a new match set
   tag_push_matches();
   tag_init_tag_browse_info(cm);

   // parse command line options
   context_found := false;
   tagfiles_ext := "";
   combine_slickc_and_c_tagfiles := false;
   option := rest := "";
   for (;;) {
      parse params with option rest;
      if (lowcase(option)=="-e") {
         parse rest with tagfiles_ext params;
      } else if (lowcase(option)=="-sc") {
         combine_slickc_and_c_tagfiles=true;
         params=rest;
      } else {
         break;
      }
   }

   // attempt to use Context Tagging(R) to find matches
   embedded_status := 0;
   typeless orig_values;
   status := 0;
   _str proc_name=params;
   if ( params=="" ) {
      if( !_isEditorCtl()) {
         tag_pop_matches();
         return(1);
      }
      /* Try to find the procedure at the cursor. */
      //say("trying Context Tagging(R), proc_name="proc_name);
      _UpdateContext(true,true);
      embedded_status = _EmbeddedStart(orig_values);
      MaybeBuildTagFile(p_LangId,true);

      context_found=context_find_tag(proc_name, false, visited, depth+1, max_matches, filter_flags, context_flags);
      if (!context_found && !is_valid_idexp(proc_name)) {
         //say("Context Tagging(R) failed, reverting to current word only");
         start_col := 0;
         proc_name=cur_identifier(start_col);
         if (proc_name=="") {
            proc_name=cur_word(start_col);
            start_col=_text_colc(start_col,"I");
         }
         if ( proc_name=="" ) {
            if (embedded_status==1) {
               _EmbeddedEnd(orig_values);
            }
            if (!quiet) message(nls("No word at cursor"));
            tag_pop_matches();
            return(2);
         }
         if (p_col!=start_col) {
            orig_col := p_col;
            p_col=start_col+length(proc_name);
            proc_name="";
            context_found=context_find_tag(proc_name, false, visited, depth+1, max_matches, filter_flags, context_flags);
            p_col=orig_col;
            if (!context_found && !is_valid_idexp(proc_name)) {
               proc_name=cur_word(start_col);
               start_col=_text_colc(start_col,"I");
            }
         }
      }
   } else {
      if (_isEditorCtl()) {
         if (embedded_status==1) {
            _EmbeddedStart(orig_values);
            embedded_status=0;
         }
         MaybeBuildTagFile(p_LangId,true);
      }
   }

   // get the set of tag files needed for the search
   tag_files := "";
   occ_lang := "";
   if (combine_slickc_and_c_tagfiles) {
      tag_files=tags_filename("e"):+PATHSEP:+tags_filename("c");
      occ_lang="c";
   } else if (params=="" && tagfiles_ext=="" &&
              _isEditorCtl() && _istagging_supported()) {
      tag_files=tags_filename(p_LangId /* context tag files*/);
      occ_lang=p_LangId;
   } else if (tagfiles_ext!="") {
      tag_files=tags_filename(tagfiles_ext /* context tag files*/);
      occ_lang=tagfiles_ext;
   } else {
      tag_files=tags_filename("",false);
      if (_isEditorCtl()) {
         occ_lang=p_LangId;
         if (!_istagging_supported(occ_lang)) {
            tag_files="";
         }
      }
   }

   // DJB -- we do not need a symbol cross reference here
   //
   //if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
   //   tag_pop_matches();
   //   return(COMMAND_CANCELLED_RC);
   //}
   
   if (_isEditorCtl() && embedded_status==1) {
      _EmbeddedEnd(orig_values);
      embedded_status=0;
   }
   //if (!context_found && _istagging_supported(occ_lang) && warn_if_no_tag_files(tag_files)) {
   //   tag_pop_matches();
   //   return("");
   //}

   // save current selection
   typeless mark="";
   if ( _select_type()!="" ) {
      mark=_duplicate_selection();
      if ( mark<0 ) {
         tag_pop_matches();
         return(NOT_ENOUGH_MEMORY_RC);
      }
   }

   // find matching tags and place them in a match set
   if (!context_found && force_tag_search) {
      status=find_tag_matches(tag_files,proc_name,false,max_matches,filter_flags);
   }

   // check if we are sitting on one of our matches
   tag_filter_only_match_under_cursor(p_buf_name, _QROffset());

   // remove duplicate symbols from the match set
   tag_remove_duplicate_symbol_matches(filterPrototypes,
                                       filterDuplicates,
                                       filterDuplicateClasses:true,
                                       filterImportsAndIncludes,
                                       filterDefinitions,
                                       filterAllTagMatchesInContext:false,
                                       ""/*matchExactTagName*/,
                                       filterFunctionSignatures,
                                       visited, depth+1, 
                                       filterAnonymousClasses:true,
                                       filterTagUses,
                                       filterTagUses,
                                       filterAnnotations);

   if (return_choices) {
      // populate the all_choices array
      n := tag_get_num_of_matches();
      for (i:=0; i<n; ++i) {
         tag_get_match_info(i+1,all_choices[i]);
         status=0;
      }
      if (n > 0) {
         cm = all_choices[0];
      }
   } else if (quiet && tag_get_num_of_matches() > 1) {
      // take the first match
      tag_get_match_info(1,cm);
      status = 0;
   } else {
      // prompt user for the tag of their choosing
      status = tag_select_symbol_match(cm);
      if (!quiet && status == BT_RECORD_NOT_FOUND_RC) {
         if (_MaybeRetryTaggingWhenFinished()) {
            return tag_get_browse_info(params, 
                                       cm, 
                                       quiet, 
                                       all_choices, 
                                       return_choices, 
                                       filterDuplicates, 
                                       filterPrototypes, 
                                       filterDefinitions, 
                                       force_tag_search, 
                                       filterFunctionSignatures, 
                                       visited, 
                                       depth, 
                                       max_matches, 
                                       filterTagUses, 
                                       filterAnnotations);
         }
         _message_box(nls("Definition of '%s' not found",proc_name)".");
      }
   }

   // restore the original selection
   if ( mark!="" ) {
      int old_mark=_duplicate_selection("");
      _show_selection(mark);
      _free_selection(old_mark);
   } else {
      _deselect();
   }

   // that's all folks
   tag_pop_matches();
   return(status);

#endif
}

/**
 * Get tag information struct for the symbol under the cursor
 * 
 * @param params              find tag options (-e [ext] or -sc for Slick-C&reg;)
 * @param cm                  (output) symbol information
 * @param quiet               if true, just return status, no message boxes
 * @param return_choices      return tag choices instead of prompting? 
 * @param all_choices         (output) array of choices
 * @param max_matches         maximum number of items to find 
 * @param force_tag_search    Force tag search
 * @param removeDuplicatesOptions   set of bit flags of options for what kinds of duplicates to remove. 
 *        <ul>
 *        <li>VS_TAG_REMOVE_DUPLICATE_PROTOTYPES -
 *            Remove forward declarations of functions if the corresponding function 
 *            definition is also in the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS -              
 *            Remove forward or extern declarations of global and namespace level 
 *            variables if the actual variable definition is also in the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_CLASSES -              
 *            Remove forward declarations of classes, structs, and 
 *            interfaces if the actual definition is in the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_IMPORTS -
 *            Remove all import statements from the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_SYMBOLS -
 *            Remove all duplicate symbol definitions.
 *        <li>VS_TAG_REMOVE_DUPLICATE_CURRENT_FILE -
 *            Remove tag matches that are found in the current symbol context.
 *        <li>VS_TAG_REMOVE_DUPLICATE_FUNCTION_SIGNATURES -              
 *            [not implemented here] 
 *            Attempt to filter out function signatures that do not match.
 *        <li>VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES -              
 *            Filter out anonymous class names in preference of typedef.
 *            for cases like typedef struct { ... } name_t;
 *        <li>VS_TAG_REMOVE_DUPLICATE_TAG_USES -              
 *            Filter out tags of type 'taguse'.  For cases of mixed language
 *            Android projects, which have duplicate symbol names in the XML and Java.
 *        <li>VS_TAG_REMOVE_DUPLICATE_ANNOTATIONS -              
 *            Filter out tags of type 'annotation' so that annotations
 *            do not conflict with other symbols with the same name.
 *        <li>VS_TAG_REMOVE_BINARY_LOADED_TAGS -
 *            Filter out tags from files which were loaded using a binary
 *            load tags method, such as jar files or .NET dll files.
 *        </ul>
 * @param filter_flags        Tag filter flags, only insert tags passing this 
 *                            filter. See {@link tag_filter_type} for more details.
 * @param context_flags       VS_TAGCONTEXT_*, tag context filter flags
 * @param visited             cache of previous tagging results
 * @param depth               depth of recursive search 
 * 
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Tagging_Functions
 */
int tag_get_browse_info_remove_duplicates(_str params, 
                                          struct VS_TAG_BROWSE_INFO& cm, 
                                          bool quiet=false, 
                                          bool return_choices=false, 
                                          struct VS_TAG_BROWSE_INFO (&all_choices)[]=null,
                                          int max_matches=def_tag_max_find_context_tags,
                                          bool force_tag_search=false,
                                          VSTagRemoveDuplicatesOptionFlags removeDuplicatesOptions=0,
                                          SETagFilterFlags filter_flags = SE_TAG_FILTER_ANYTHING,
                                          SETagContextFlags context_flags = SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS,
                                          VS_TAG_RETURN_TYPE (&visited):[]=null, 
                                          int depth=0)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // create a new match set
   tag_push_matches();
   tag_init_tag_browse_info(cm);

   // parse command line options
   context_found := false;
   tagfiles_ext := "";
   combine_slickc_and_c_tagfiles := false;
   option := rest := "";
   for (;;) {
      parse params with option rest;
      if (lowcase(option)=="-e") {
         parse rest with tagfiles_ext params;
      } else if (lowcase(option)=="-sc") {
         combine_slickc_and_c_tagfiles=true;
         params=rest;
      } else {
         break;
      }
   }

   // set up symbol filter and context tagging search flags
   if (return_choices && !quiet && force_tag_search) {
      context_flags |= SE_TAG_CONTEXT_FIND_ALL;
      context_flags |= SE_TAG_CONTEXT_FIND_LENIENT;
      context_flags |= SE_TAG_CONTEXT_NO_GLOBALS;
   }
   if (removeDuplicatesOptions & VS_TAG_REMOVE_DUPLICATE_ANNOTATIONS) {
      filter_flags &= ~SE_TAG_FILTER_ANNOTATION;
   }
   if (removeDuplicatesOptions & VS_TAG_REMOVE_DUPLICATE_TAG_USES) {
      filter_flags &= ~SE_TAG_FILTER_MISCELLANEOUS;
   }
   if (removeDuplicatesOptions & VS_TAG_REMOVE_DUPLICATE_IMPORTS) {
      filter_flags &= ~SE_TAG_FILTER_INCLUDE;
   }

   // attempt to use Context Tagging(R) to find matches
   embedded_status := 0;
   orig_values := null;
   status := 0;
   proc_name := params;
   if ( params=="" ) {
      if( !_isEditorCtl()) {
         tag_pop_matches();
         return(1);
      }
      /* Try to find the procedure at the cursor. */
      //say("trying Context Tagging(R), proc_name="proc_name);
      _UpdateContextAndTokens(true,true);
      embedded_status = _EmbeddedStart(orig_values);
      MaybeBuildTagFile(p_LangId,true);

      context_found=context_find_tag(proc_name, 
                                     find_parents:false,
                                     force_case_sensitive:false, 
                                     max_matches, 
                                     filter_flags, context_flags,
                                     visited, depth+1);
      if (!context_found && !is_valid_idexp(proc_name)) {
         //say("Context Tagging(R) failed, reverting to current word only");
         start_col := 0;
         proc_name=cur_identifier(start_col);
         if (proc_name=="") {
            proc_name=cur_word(start_col);
            start_col=_text_colc(start_col,"I");
         }
         if ( proc_name=="" ) {
            if (embedded_status==1) {
               _EmbeddedEnd(orig_values);
            }
            if (!quiet) message(nls("No word at cursor"));
            tag_pop_matches();
            return(2);
         }
         if (p_col!=start_col) {
            orig_col := p_col;
            p_col=start_col+length(proc_name);
            proc_name="";
            context_found=context_find_tag(proc_name, 
                                           find_parents:false,
                                           force_case_sensitive:false, 
                                           max_matches, 
                                           filter_flags, context_flags,
                                           visited, depth+1);
            p_col=orig_col;
            if (!context_found && !is_valid_idexp(proc_name)) {
               proc_name=cur_word(start_col);
               start_col=_text_colc(start_col,"I");
            }
         }
      }
   } else {
      if (_isEditorCtl()) {
         if (embedded_status==1) {
            _EmbeddedStart(orig_values);
            embedded_status=0;
         }
         MaybeBuildTagFile(p_LangId,true);
      }
   }

   // get the set of tag files needed for the search
   tag_files := "";
   occ_lang := "";
   if (combine_slickc_and_c_tagfiles) {
      tag_files=tags_filename("e"):+PATHSEP:+tags_filename("c");
      occ_lang="c";
   } else if (params=="" && tagfiles_ext=="" &&
              _isEditorCtl() && _istagging_supported()) {
      tag_files=tags_filename(p_LangId /* context tag files*/);
      occ_lang=p_LangId;
   } else if (tagfiles_ext!="") {
      tag_files=tags_filename(tagfiles_ext /* context tag files*/);
      occ_lang=tagfiles_ext;
   } else {
      tag_files=tags_filename("",false);
      if (_isEditorCtl()) {
         occ_lang=p_LangId;
         if (!_istagging_supported(occ_lang)) {
            tag_files="";
         }
      }
   }

   // DJB -- we do not need a symbol cross reference here
   //
   //if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
   //   tag_pop_matches();
   //   return(COMMAND_CANCELLED_RC);
   //}
   
   if (_isEditorCtl() && embedded_status==1) {
      _EmbeddedEnd(orig_values);
      embedded_status=0;
   }
   //if (!context_found && _istagging_supported(occ_lang) && warn_if_no_tag_files(tag_files)) {
   //   tag_pop_matches();
   //   return("");
   //}

   // save current selection
   typeless mark="";
   if ( _select_type()!="" ) {
      mark=_duplicate_selection();
      if ( mark<0 ) {
         tag_pop_matches();
         return(NOT_ENOUGH_MEMORY_RC);
      }
   }

   // find matching tags and place them in a match set
   if (!context_found && force_tag_search) {
      status=find_tag_matches(tag_files,proc_name,false,max_matches,filter_flags);
   }

   // check if we are sitting on one of our matches
   tag_filter_only_match_under_cursor(p_buf_name, _QROffset());

   // remove duplicate symbols from the match set
   removeDuplicatesOptions |= VS_TAG_REMOVE_DUPLICATE_IMPORTS;
   removeDuplicatesOptions |= VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES;
   if (!force_tag_search) {
      removeDuplicatesOptions |= VS_TAG_REMOVE_BINARY_LOADED_TAGS;
   }
   tag_remove_duplicate_symbols_from_matches_with_function_argument_matching(pszMatchExactSymbolName:"", 
                                                                             pszCurrentFileName:"",
                                                                             occ_lang, 
                                                                             removeDuplicatesOptions, 
                                                                             visited, depth+1);

   n := tag_get_num_of_matches();
   if (return_choices) {
      // populate the all_choices array
      for(i:=0; i<n; ++i) {
         tag_get_match_info(i+1,all_choices[i]);
         status=0;
      }
      if (n > 0) {
         cm = all_choices[0];
      }
   } else if (quiet) {
      if (n >= 1) {
         // take the first match
         tag_get_match_info(1,cm);
         status = 0;
      } else if (status >= 0) {
         status = BT_RECORD_NOT_FOUND_RC;
      }
   } else {
      // prompt user for the tag of their choosing
      status = tag_select_symbol_match(cm);
      if (!quiet && status == BT_RECORD_NOT_FOUND_RC) {
         if (_MaybeRetryTaggingWhenFinished()) {
            return tag_get_browse_info_remove_duplicates(params, 
                                                         cm, 
                                                         quiet, 
                                                         return_choices, 
                                                         all_choices, 
                                                         max_matches,
                                                         force_tag_search, 
                                                         removeDuplicatesOptions, 
                                                         filter_flags, 
                                                         context_flags, 
                                                         visited, depth);
         }
         _message_box(nls("Definition of '%s' not found",proc_name)".");
      }
   }

   // restore the original selection
   if ( mark!="" ) {
      old_mark := _duplicate_selection("");
      _show_selection(mark);
      _free_selection(old_mark);
   } else {
      _deselect();
   }

   // that's all folks
   tag_pop_matches();
   return(status);
}

/**
 * Get list of files that reference the specified tag. Reject any files that do not have
 * any function references whose scope is one of the classes in the list of class names passed in.
 *
 * @param cm     Information about the tag to be checked
 * @param refFileList
 *               (output) Array of files that reference the tag
 * @param classList
 *               List of class names to compare references against.
 * @param progressMin
 *               Minimum number of files in list to warrant a progress dialog
 *
 * @return 0 on succes, <0 on error
 */
int tag_get_occurrence_file_list_restrict_to_classes(struct VS_TAG_BROWSE_INFO cm, 
                                                     _str (&refFileList)[],
                                                     _str all_classes[], 
                                                     _str (&tag_files)[], 
                                                     int progressMin = 0,
                                                     VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //-//tag_browse_info_dump(cm, "tag_get_occurrence_file_list");

   // always add the file that contains the tag
   refFileList[refFileList._length()] = cm.file_name;

   // if this is a local variable or a static local function/variable, only need to
   // return the file that contains it
   if (cm.type_name == "lvar" && !(cm.flags & SE_TAG_FLAG_EXTERN)) {
      return 0;
   }

   // if this is a private member in Java, then restrict, only need
   // the file that contains it.
   if ((cm.flags & SE_TAG_FLAG_ACCESS)==SE_TAG_FLAG_PRIVATE && _get_extension(cm.file_name)=="java") {
      return 0;
   }

   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   status := _MaybeRetagOccurrences();
   if (status < 0) {
      return status;
   }

   // build list of files to check
   _str fileList[] = null;
   _str fileHash:[] = null;

   // get all the project tag files
   tagfiles := project_tags_filenamea();
   tagfilename := "";
   foreach (tagfilename in tagfiles) {

      // open the workspace tagfile
      status = tag_read_db(tagfilename);
      if(status < 0) continue;

      if(!tag_find_occurrence(cm.member_name, true, true)) {
         do {
            _str occurName, occurFilename;
            tag_get_occurrence(occurName, occurFilename);

            if(!fileHash._indexin(occurFilename)) {
               fileList[fileList._length()] = occurFilename;
               fileHash:[occurFilename] = true;
            }

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

//      say("tag_get_occurrence_file_list_restrict_to_classes: "i" filename="filename);

      // if this is the filename that was passed in, it's already in the list
      // so no need to bother with it
//      if(file_eq(filename, cm.file_name)) {
//         //-//say("tag_get_occurrence_file_list: file=" filename " IN BY DEFAULT");
//         continue;
//      }

      tempViewID := 0;
      origViewID := 0;
      alreadyExists := false;
      status = _open_temp_view(filename, tempViewID, origViewID, "", alreadyExists, false, true);
      if(status < 0) continue;

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
      int maxRefs = def_cb_max_references intdiv 4; // 10;
     _str errorArgs[]; errorArgs._makeempty();
      numRefs := 0;
      hasRef := false;

      // Does this file have any references that are instances of any of the classes in the all classes list?
      status = tag_match_multiple_occurrences_in_file(errorArgs, cm.member_name, p_EmbeddedCaseSensitive,
                                                      all_classes, all_classes._length(), SE_TAG_FILTER_ANYTHING,
                                                      hasRef, maxRefs, visited );

      // If this file does have a reference to one of the classes in the all_classes list
      // then we want to consider this file. Otherwise do not process the file because it cannot
      // be related to the symbol we are trying to rename.
      if( hasRef ) {
         refFileList[refFileList._length()] = filename;
      }

      // cleanup
      _delete_temp_view(tempViewID);
      p_window_id = origViewID;

      // if there is a progress form, update it
      if(progressFormID) {
         cancel_form_progress(progressFormID, i, fileList._length());
         if(cancel_form_cancelled()) {
            // empty file list
            refFileList._makeempty();
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
int tag_get_occurrence_file_list(struct VS_TAG_BROWSE_INFO cm, _str (&refFileList)[],
                                 int progressMin = 0, bool narrowList=true,
                                 int tagFilter=SE_TAG_FILTER_ANYTHING,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //-//tag_browse_info_dump(cm, "tag_get_occurrence_file_list");

   // always add the file that contains the tag
   refFileList[refFileList._length()] = cm.file_name;

   // if this is a local variable or a static local function/variable, only need to
   // return the file that contains it
   if (cm.type_name == "lvar" && !(cm.flags & SE_TAG_FLAG_EXTERN)) {
      return 0;
   }

   // if this is a private member in Java, then restrict, only need
   // the file that contains it.
   if ((cm.flags & SE_TAG_FLAG_ACCESS)==SE_TAG_FLAG_PRIVATE && _get_extension(cm.file_name)=="java") {
      return 0;
   }

   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   status := _MaybeRetagOccurrences();
   if (status < 0) {
      return status;
   }

   // build list of files to check
   _str fileList[] = null;
   _str fileHash:[] = null;

   // get all the project tag files
   tagfiles := project_tags_filenamea();
   tagfilename := "";
   foreach (tagfilename in tagfiles) {

      // open the workspace tagfile
      status = tag_read_db(tagfilename);
      if(status < 0) continue;

      if(!tag_find_occurrence(cm.member_name, true, true)) {
         do {
            _str occurName, occurFilename;
            tag_get_occurrence(occurName, occurFilename);

            if(fileHash._indexin(occurFilename) == false) {
               fileList[fileList._length()] = occurFilename;
               fileHash:[occurFilename] = true;
            }

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

      // if this is the filename that was passed in, it's already in the list
      // so no need to bother with it
      if(_file_eq(filename, cm.file_name)) {
         //-//say("tag_get_occurrence_file_list: file=" filename " IN BY DEFAULT");
         continue;
      }

      tempViewID := 0;
      origViewID := 0;
      alreadyExists := false;
      status = _open_temp_view(filename, tempViewID, origViewID, "", alreadyExists, false, true);
      if(status < 0) continue;

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
      int maxRefs = def_cb_max_references intdiv 4; // 10;
      _str errorArgs[]; errorArgs._makeempty();
      numRefs := 0;
      status = tag_match_symbol_occurrences_in_file(errorArgs, 0, 0, 
                                                    cm, p_EmbeddedCaseSensitive,
                                                    SE_TAG_FILTER_ANYTHING,
                                                    SE_TAG_CONTEXT_ANYTHING, 
                                                    0, 0,
                                                    numRefs, maxRefs, 
                                                    visited, depth+1);
      //-//say("tag_get_occurrence_file_list: refs=" numRefs "  status=" status "  file=" filename);

      // cleanup
      _delete_temp_view(tempViewID);
      p_window_id = origViewID;

      // add to list if refs are found
      if( ( narrowList == false ) || ( numRefs > 0 || status == 2 ) ) {
         refFileList[refFileList._length()] = filename;
         status = 0;
      }

      // if there is a progress form, update it
      if(progressFormID) {
         cancel_form_progress(progressFormID, i, fileList._length());
         if(cancel_form_cancelled()) {
            // empty file list
            refFileList._makeempty();
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

/**
 * Find the tag referred to by the browse info and fill in the rest
 * of the struct information for it
 */
int tag_complete_browse_info(struct VS_TAG_BROWSE_INFO& cm)
{
   if(cm.file_name == "") {
      // error
      return -1;
   }

   // save the window ID
   orig_tag_database := cm.tag_database;
   orig_wid := p_window_id;
   if (!_isEditorCtl()) {
      p_window_id=VSWID_HIDDEN;
   }

   // load the file the tag is located in
   tempViewID := 0;
   origViewID := 0;
   buffer_already_exists := false;
   int status = _open_temp_view(cm.file_name, tempViewID, origViewID, "", buffer_already_exists, false, true);
   if(status < 0) {
      p_window_id = orig_wid;
      return status;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // do while false scope used to break out on error and make sure
   // that the temp view is cleaned up
   do {

      status = tag_update_context();
      if(status < 0) break;

      int contextID = tag_find_context_iterator(cm.member_name, true, true);
      if(contextID < 0) break;

      do {
         contextLineNumber := 0;
         contextFileName := "";
         tag_get_detail2(VS_TAGDETAIL_context_line, contextID, contextLineNumber);
         tag_get_detail2(VS_TAGDETAIL_context_file, contextID, contextFileName);

         if (contextLineNumber == cm.line_no && _file_eq(contextFileName, cm.file_name)) {
            // match found so copy all of its data
            tag_get_context_info(contextID, cm);
            cm.tag_database = orig_tag_database;
            break;
         }

         // next please
         contextID = tag_next_context_iterator(cm.member_name, contextID, true, true);

      } while (contextID > 0);

   } while(false);

   // cleanup
   _delete_temp_view(tempViewID);
   p_window_id = origViewID;

   return status;
}

/**
 * Given a tag type and tag flags, compute a (normally minimal)
 * set of filters that will accept the tag.
 *
 * @param tag_type    Tag type to search for
 * @param tag_flags   Tag flags to accept.
 *
 * @return bitset of VS_TAGFILTER_*
 */
SETagFilterFlags tag_type_to_filter(_str tag_type, SETagFlags tag_flags)
{
   filter := SE_TAG_FILTER_NULL;
   bit := (SETagFilterFlags)1;
   for (i:=1; i<=32; ++i) {
      if (tag_filter_type(SE_TAG_TYPE_NULL,bit,tag_type,(int)tag_flags)) {
         filter|=bit;
      }
      bit = (SETagFilterFlags)(2*bit);
   }
   return filter;
}

/**
 * Go to the given proc in the current buffer, expecting it to be
 * near the indicated line number.  Prompt user if there are
 * multiple occurrences of 'proc_name' in the buffer.
 *
 * @param proc_name    proc name to find
 * @param line_no      expected line number
 *
 * @return 0 on success, nonzero on error.
 */
_command goto_context_tag(_str proc_name="", _str line_no="", _str doStatements="") name_info(TAG_ARG','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   if (!_isEditorCtl()) {
      return(1);
   }

   // reparse the context and locals if needed
   typeless CurrentBufferPos;
   save_pos(CurrentBufferPos);
   _end_line();
   seekpos := (int)_QROffset();
   restore_pos(CurrentBufferPos);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContextAndTokens(true,true);
   if (doStatements != "") {
      _UpdateStatements(true,true);
   }
   _UpdateLocals(true,true);

   // Try to find the procedure at the cursor.
   _str errorArgs[]; errorArgs._makeempty();
   if ( proc_name=="" &&
        context_match_tags(errorArgs,proc_name,false,1,true,p_EmbeddedCaseSensitive) <= 0) {

      start_col := 0;
      proc_name=cur_identifier(start_col);
      if (proc_name=="") {
         proc_name=cur_word(start_col);
         start_col=_text_colc(start_col,"I");
      }
      if ( proc_name=="" ) {
         message(nls("No word at cursor"));
         return(2);
      }
   }

   // decompose the original proc name into tag, class, type
   tag_decompose_tag_browse_info(proc_name, auto orig_cm);

   // save current selection if there is one
   typeless mark="";
   if ( _select_type()!="" ) {
      mark=_duplicate_selection();
      if ( mark<0 ) {
         return(NOT_ENOUGH_MEMORY_RC);
      }
   }

   // list of tags matching in current buffer
   _str tagList[];     tagList._makeempty();
   int linenumList[]; linenumList._makeempty();
   int seekposList[]; seekposList._makeempty();

   // see if it is found in locals
   _str type_name;
   _str signature;
   int start_linenum,start_seekpos;
   local_found := false;
   int i = tag_find_local_iterator(orig_cm.member_name, true, p_EmbeddedCaseSensitive, true, orig_cm.class_name);
   while (i > 0) {
      tag_get_detail2(VS_TAGDETAIL_local_type,i,type_name);
      tag_get_detail2(VS_TAGDETAIL_local_args,i,signature);
      //say("FOUND: tag_name="tag_name" type_name="type_name" orig="orig_type_name);
      if (tag_is_local_in_scope(i,seekpos)) {
         if ((orig_cm.type_name=="" || type_name == orig_cm.type_name) &&
             (orig_cm.arguments=="" || signature == orig_cm.arguments)) {
            proc_name=tag_tree_make_caption_fast(VS_TAGMATCH_local,i,true,true,false);
            tag_get_detail2(VS_TAGDETAIL_local_start_linenum, i, start_linenum);
            tag_get_detail2(VS_TAGDETAIL_local_start_seekpos, i, start_seekpos);
            if (!local_found && line_no!="" && line_no:==start_linenum) {
               tagList._makeempty();
               linenumList._makeempty();
               seekposList._makeempty();
               local_found = true;
            }
            tagList[tagList._length()]=proc_name;
            linenumList[linenumList._length()]=start_linenum;
            seekposList[seekposList._length()]=start_seekpos;
            if (local_found) break;
         }
      }
      i = tag_next_local_iterator(orig_cm.member_name, i, true, p_EmbeddedCaseSensitive, true, orig_cm.class_name);
   }

   // not found in locals, so try out global scope
   context_found := false;
   if (!local_found) {
      i = tag_find_context_iterator(orig_cm.member_name, true, p_EmbeddedCaseSensitive, true, orig_cm.class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type,i,type_name);
         tag_get_detail2(VS_TAGDETAIL_context_args,i,signature);
         //say("FOUND: tag_name="tag_name" type_name="type_name" orig="orig_type_name);
         if ((orig_cm.type_name=="" || type_name == orig_cm.type_name) &&
             (orig_cm.arguments=="" || signature == orig_cm.arguments)) {
            proc_name=tag_tree_make_caption_fast(VS_TAGMATCH_context,i,true,true,false);
            tag_get_detail2(VS_TAGDETAIL_context_start_linenum, i, start_linenum);
            tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, i, start_seekpos);
            if (!context_found && line_no!="" && line_no:==start_linenum) {
               tagList._makeempty();
               linenumList._makeempty();
               seekposList._makeempty();
               context_found = true;
            }
            tagList[tagList._length()]=proc_name;
            linenumList[linenumList._length()]=start_linenum;
            seekposList[seekposList._length()]=start_seekpos;
            if (context_found) break;
         }
         i = tag_next_context_iterator(orig_cm.member_name, i, true, p_EmbeddedCaseSensitive, true, orig_cm.class_name);
      }
   }

   // no matches!
   if (tagList._length() < 1) {
      buf_name := _ShrinkFilenameToScreenWidth(p_buf_name);
      _message_box(nls("%s not found in '%s'",proc_name,buf_name));
      return(2);
   }

   // more than one match, then display selection dialog
   typeless old_scroll_style=_scroll_style();
   _scroll_style("c");
   i=0;
   if (tagList._length() > 1) {
      i=show("_sellist_form -mdi -modal -reinit",
                  nls("Multiple Occurrences Found"),
                  SL_DEFAULTCALLBACK|SL_SELECTCLINE,
                  tagList,
                  "",
                  "",  // help item name
                  "",  // font
                  _taglist_callback  // Call back function
                 );
   }

   // cancelled?
   if (i=="") {
      _scroll_style(old_scroll_style);
      return(COMMAND_CANCELLED_RC);
   }

   // position on tag
   _GoToROffset(seekposList[i]);
   p_RLine=linenumList[i];

   // make sure the symbols is not on a hidden line
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }

   // restore scroll style
   _scroll_style(old_scroll_style);

   // restore selections
   if ( mark!="" ) {
      int old_mark=_duplicate_selection("");
      _show_selection(mark);
      _free_selection(old_mark);
   } else {
      _deselect();
   }

   // that's all folks!
   return(0);
}

/**
 * For languages not implementing an extension specific context
 * find tag function (see {@link _c_find_context_tags}), this function
 * serves in its place.  It can resolve tags based on rudimentary
 * information, such as tag name, class scope, but does not attempt
 * to solve other harder language specific scoping issues, such as
 * imports or aliasing, etc.
 *
 * @param errorArgs          List of argument for codehelp error messages
 * @param prefixexp          prefix expression, see {@link _c_get_expression_info}
 * @param lastid             identifier under cursor
 * @param lastidstart_offset start offset of identifier under cursor
 * @param info_flags         bitset of VSAUTOCODEINFO_
 * @param otherinfo          extension specific information
 * @param find_parents       find matches in parent classes
 * @param max_matches        maximum number of matches to find
 * @param exact_match        exact match or prefix match for lastid?
 * @param case_sensitive     case sensitive match?
 * @param filter_flags       bitset of VS_TAGFILTER_
 * @param context_flags      bitset of VS_TAGCONTEXT_
 * @param visited            hash table of prior results
 * @param depth              depth of recursive search
 *
 * @return 0 on sucess, nonzero on error
 */
int _do_default_find_context_tags(
              _str (&errorArgs)[],
              _str prefixexp,_str lastid,
              int lastidstart_offset,int info_flags,
              typeless otherinfo,
              bool find_parents, int max_matches,
              bool exact_match, bool case_sensitive,
              SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
              SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_chdebug) {
      isay(depth, "_do_default_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   }
   // make sure that the context doesn't get modified by a background thread.
   errorArgs._makeempty();
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // find more details about the current tag
   cur_scope_seekpos := 0;
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_flags, 
                                         auto cur_type_name, auto cur_type_id,
                                         auto cur_context, auto cur_class, auto cur_package,
                                         visited, depth+1);
   if (cur_context == "" && (context_flags & SE_TAG_CONTEXT_ONLY_INCLASS)) {
      errorArgs[1]=lastid;
      if (_chdebug) {
         isay(depth, "_do_default_find_context_tags: NO CURRENT CONTEXT");
      }
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // clear the match set
   tag_clear_matches();
   num_matches := 0;

   // get the tag file list
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   // try to match the symbol in the current context
   if (_haveContextTagging()) {
      context_flags |= SE_TAG_CONTEXT_FIND_LENIENT;
   } else {
      tag_files._makeempty();
      context_flags |= SE_TAG_CONTEXT_ONLY_CONTEXT;
   }
   tag_list_symbols_in_context(lastid, "", 0, 0, tag_files, "",
                               num_matches, max_matches,
                               filter_flags, context_flags,
                               exact_match, case_sensitive,
                               visited, depth+1);

   if (_chdebug) {
      isay(depth, "_do_default_find_context_tags: found "num_matches);
      tag_dump_matches("_do_default_find_context_tags: ", depth+1);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1]=lastid;
   int status=(num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   return(status);
}
/**
 * Find tags matching the symbol information returned from a call to
 * _Embedded_get_expression_info, and insert them in to the match set.
 *
 * @param errorArgs          List of argument for codehelp error messages
 * @param prefixexp          prefix expression, see {@link _c_get_expression_info}
 * @param lastid             identifier under cursor
 * @param lastidstart_offset start offset of identifier under cursor
 * @param info_flags         bitset of VSAUTOCODEINFO_
 * @param otherinfo          extension specific information
 * @param find_parents       find matches in parent classes
 * @param max_matches        maximum number of matches to find
 * @param exact_match        exact match or prefix match for lastid?
 * @param case_sensitive     case sensitive match?
 * @param filter_flags       bitset of VS_TAGFILTER_
 * @param context_flags      bitset of VS_TAGCONTEXT_
 * @param visited            hash table of prior results
 * @param depth              depth of recursive search
 *
 * @return 0 on sucess, nonzero on error
 */
int _Embeddedfind_context_tags(_str (&errorArgs)[],
                               _str prefixexp,_str lastid,
                               int lastidstart_offset,int info_flags,
                               typeless otherinfo,
                               bool find_parents=false,
                               int max_matches=def_tag_max_find_context_tags,
                               bool exact_match=true, bool case_sensitive=false,
                               SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                               SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                               VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   num_matches := 0;
   status := 0;
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   errorArgs._makeempty();
   tag_clear_matches();

   // try to match the symbol in the current context
   index := _FindLanguageCallbackIndex("_%s_find_context_tags");
   if (!index && upcase(substr(p_lexer_name,1,3))=="XML") {
      index=find_index("_html_find_context_tags",PROC_TYPE);
   }
   if (index && index_callable(index) && _haveContextTagging()) {
      // call language-specific symbol search function
      status=call_index(errorArgs,
                        prefixexp, lastid, lastidstart_offset,
                        info_flags, otherinfo,
                        find_parents, max_matches,
                        exact_match, case_sensitive,
                        filter_flags, context_flags, 
                        visited, depth,
                        index);
      num_matches=tag_get_num_of_matches();

   } else {
      // get list of tag files and search options
      tag_files := tags_filenamea(p_LangId);
      context_list_flags := (find_parents)? SE_TAG_CONTEXT_FIND_PARENTS : 0;
      if (!_haveContextTagging()) {
         context_list_flags = SE_TAG_CONTEXT_FIND_LENIENT;
      }

      // generic function for searching for symbol matches
      status=tag_list_symbols_in_context(lastid, "", 
                                         0, 0, tag_files, "",
                                         num_matches, max_matches,
                                         filter_flags, 
                                         context_flags | context_list_flags,
                                         exact_match, case_sensitive, 
                                         visited, depth+1);

      // try to use ctags to look up symbol matches
      if (!_haveContextTagging() && _haveCtags() && lastid != "" && !(context_flags & SE_TAG_CONTEXT_RESTRICTIVE_FLAGS)) {
         status = tag_list_symbols_in_ctags_file("", lastid, exact_match, true, true, case_sensitive, "", num_matches, max_matches);
      }
   }

   // Return 0 indicating success if anything was found
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   if (status) {
      return(status);
   }
   errorArgs[1]=lastid;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

/**
 * @author dbrueni (4/4/2012)
 * 
 * @param errorArgs 
 * @param prefixexp 
 * @param lastid 
 * @param lastidstart_offset 
 * @param info_flags 
 * @param otherinfo 
 * @param find_parents 
 * @param max_matches 
 * @param exact_match 
 * @param case_sensitive 
 * @param filter_flags 
 * @param context_flags 
 * @param visited 
 * @param depth 
 * 
 * @return int 
 */
int _doc_comment_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                                   _str lastid,int lastidstart_offset,
                                   int info_flags,typeless otherinfo,
                                   bool find_parents,int max_matches,
                                   bool exact_match,bool case_sensitive,
                                   SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                                   SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_chdebug) {
      isay(depth, "_doc_comment_find_context_tags: lastid="lastid" prefixexp="prefixexp" exact="exact_match" case="case_sensitive);
   }

   if (!(info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT)) {
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   _str allWords[];
   if (prefixexp == "@") {
      allWords = gDoxygenCommandsAtsign;
   } else if (prefixexp == "\\") {
      allWords = gDoxygenCommandsBackslash;
   } else if (_first_char(prefixexp) == "<" || _first_char(prefixexp) == "&") {

      return _html_find_context_tags(errorArgs, prefixexp, 
                                     lastid, lastidstart_offset, 
                                     info_flags, otherinfo, 
                                     find_parents, max_matches, 
                                     exact_match, case_sensitive, 
                                     filter_flags, context_flags, 
                                     visited, depth+1);

   } else if (prefixexp == "@param" || prefixexp == "\\param") {

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // try to locate the current context, maybe skip over
      // comments to start of next tag
      save_pos(auto p);
      _clex_skip_blanks();
      context_id := tag_current_context();
      if (context_id <= 0) {
         restore_pos(p);
         return VSCODEHELPRC_NO_SYMBOLS_FOUND;
      }

      // get the information about the current function
      tag_get_context_info(context_id, auto cm);
      if (!tag_tree_type_is_func(cm.type_name)) {
         restore_pos(p);
         return VSCODEHELPRC_NO_SYMBOLS_FOUND;
      }

      // update the locals, including parameters
      _GoToROffset(cm.scope_seekpos);
      left();
      _UpdateLocals(true);

      // insert the locals that match the ID
      num_params := 0;
      tag_list_class_locals(0, 0, null, lastid, "", 
                            SE_TAG_FILTER_LOCAL_VARIABLE, context_flags, 
                            num_params, max_matches, 
                            exact_match, case_sensitive, 
                            "", visited, depth+1);

      restore_pos(p);
      _UpdateLocals(true);
      return (num_params > 0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;

   } else if (prefixexp == "@see" || prefixexp == "\\see") {
      info_flags &= ~VSAUTOCODEINFO_IN_JAVADOC_COMMENT;
      return _Embeddedfind_context_tags(errorArgs, "", lastid, lastidstart_offset, info_flags, otherinfo, find_parents, max_matches, exact_match, case_sensitive, filter_flags, context_flags, visited, depth);

   } else {
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   tag_init_tag_browse_info(auto word_cm);
   num_matches := 0;
   prefix := prefixexp:+lastid;
   word := "";
   foreach (word in allWords) {
      if (_CodeHelpDoesIdMatch(prefix, word, exact_match, case_sensitive)) {
         word_cm.member_name = substr(word, 2);
         word_cm.type_name = "statement";
         word_cm.line_no = 1;
         tag_insert_match_browse_info(word_cm);
         num_matches++;
      }
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = prefix;
   return (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

/**
 * Utility function for parsing the syntax of a return type
 * pulled from the tag database, tag_get_detail(VS_TAGDETAIL_return, ...)
 * The return type is evaluated relative to the current class context
 * and in the context of the file in which it was seen.  This is
 * necessary in order to resolve imported namespaces, etc.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs          array of strings for error message arguments
 *                           refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files          list of extension specific tag files
 * @param symbol             name of symbol having given return type
 * @param search_class_name  class context to evaluate return type relative to
 * @param file_name          file from which return type string comes
 * @param return_type        return type string to be parsed (e.g. FooBar **)
 * @param isjava             Is this Java, JavaScript, or similar language?
 * @param rt                 (reference) return type information
 * @param visited            (reference) types analyzed thus far
 * @param depth              search depth, to prevent recursion
 *
 * @return
 *    0 on success, &lt;0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
int _Embeddedparse_return_type(_str (&errorArgs)[], 
                               typeless tag_files,
                               _str symbol, 
                               _str search_class_name,
                               _str file_name, 
                               _str return_type, 
                               bool isjava,
                               struct VS_TAG_RETURN_TYPE &rt,
                               VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   errorArgs._makeempty();

   // look up and call the extension specific callback function
   status := 0;
   index := _FindLanguageCallbackIndex("_%s_parse_return_type");
   if (index && index_callable(index)) {
      tag_push_matches();
      status=call_index(errorArgs, tag_files,
                        symbol, search_class_name,
                        file_name, return_type, isjava,
                        rt, visited, depth, index);
      tag_pop_matches();
   } else {
      errorArgs[0] = return_type;
      status = VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   // Return 0 indicating success if anything was found
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   return(status);
}

/**
 * Utility function for parsing an expression and inferring a return type. 
 * This function simply calls langauge-specific callbacks to do the actual 
 * calculations and heavy lifting. 
 * 
 *
 * @param errorArgs          array of strings for error message arguments
 *                           refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files          list of extension specific tag files
 * @param symbol             name of symbol having given return type
 * @param search_class_name  class context to evaluate return type relative to
 * @param file_name          file from which return type string comes
 * @param prefix_flags       bitset of VSCODEHELP_PREFIX_*
 * @param expr               expression to evaluate
 * @param rt                 (reference) return type information
 * @param visited            (reference) types analyzed thus far
 * @param depth              search depth, to prevent recursion
 *
 * @return
 *    0 on success, &lt;0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
int _Embeddedget_type_of_expression(_str (&errorArgs)[], 
                                    typeless tag_files,
                                    _str symbol, 
                                    _str search_class_name,
                                    _str file_name,
                                    CodeHelpExpressionPrefixFlags prefix_flags,
                                    _str expr, 
                                    struct VS_TAG_RETURN_TYPE &rt,
                                    struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (expr == null || expr == "") {
      return INVALID_ARGUMENT_RC;
   }
   embedded_status := _EmbeddedStart(auto orig_values);
   errorArgs._makeempty();

   // look up and call the extension specific callback function
   status := 0;
   index  := _FindLanguageCallbackIndex("_%s_get_type_of_expression");
   if (index && index_callable(index)) {
      tag_push_matches();
      tag_return_type_init(rt);
      status=call_index(errorArgs, tag_files,
                        symbol, search_class_name, file_name,
                        prefix_flags, expr, rt,
                        visited, depth, index);
      tag_pop_matches();
      if (status >= 0) {
         if (embedded_status==1) {
            _EmbeddedEnd(orig_values);
         }
         return status;
      }
   }
/*
   // that didn't work, try to get type of constant
   index  := _FindLanguageCallbackIndex("_%s_get_type_of_constant");
   if (index && index_callable(index)) {
      tag_push_matches();
      tag_return_type_init(rt);
      status=call_index(expr, rt, index);
      tag_pop_matches();
      if (status >= 0) {
         if (embedded_status==1) {
            _EmbeddedEnd(orig_values);
         }
         return status;
      }
   }
*/
   // Return error indicating we could not evaluate this expression
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   errorArgs[0] = expr;
   return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
}

/**
 * Utility function for parsing a prefix expression and inferring a return type. 
 * This function simply calls langauge-specific callbacks to do the actual 
 * calculations and heavy lifting. 
 *
 * @param errorArgs           List of argument for codehelp error messages
 * @param prefixexp           Prefix expression
 * @param rt                  (reference) return type structure
 * @param depth               (optional) depth of recursion 
 * @param prefix_flags        bitset of VSCODEHELP_PREFIX_* 
 * @param search_class_name   current package/class scope 
 *
 * @return
 *    0 on success, &lt;0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
int _Embeddedget_type_of_prefix(_str (&errorArgs)[], 
                                _str prefixexp,
                                struct VS_TAG_RETURN_TYPE &rt, 
                                VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                                CodeHelpExpressionPrefixFlags prefix_flags=VSCODEHELP_PREFIX_NULL, 
                                _str search_class_name="")
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (prefixexp == null || prefixexp == "") {
      return INVALID_ARGUMENT_RC;
   }
   embedded_status := _EmbeddedStart(auto orig_values);
   errorArgs._makeempty();

   // look up and call the extension specific callback function
   status := 0;
   index  := _FindLanguageCallbackIndex("_%s_get_type_of_prefix");
   tag_push_matches();
   tag_return_type_init(rt);
   if (index && index_callable(index)) {
      status=call_index(errorArgs, 
                        prefixexp, rt, 
                        visited, depth, 
                        prefix_flags, 
                        search_class_name, 
                        index);
   } else {
      status = _c_get_type_of_prefix(errorArgs, 
                                     prefixexp, rt, 
                                     visited, depth, 
                                     prefix_flags, 
                                     search_class_name);
   }
   tag_pop_matches();
   if (status >= 0) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      return status;
   }

   // Return error indicating we could not evaluate this expression
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   errorArgs[0] = prefixexp;
   return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
}

/**
 * Utility function for evaluating a symbol's return type, possibly inferring 
 * the return type from an initializer expression. 
 * This function simply calls langauge-specific callbacks to do the actual 
 * calculations and heavy lifting. 
 * 
 *
 * @param errorArgs          array of strings for error message arguments
 *                           refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files          list of extension specific tag files
 * @param cm                 symbol with return type (and possible initializer)
 * @param visited            (reference) types analyzed thus far
 * @param depth              search depth, to prevent recursion
 *
 * @return
 *    Expanded return type on success, "" on error.
 */
_str _Embeddedget_inferred_return_type_string(_str (&errorArgs)[], 
                                              typeless tag_files,
                                              VS_TAG_BROWSE_INFO &cm,
                                              struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (cm == null || cm.return_type == "") {
      return "";
   }
   parse cm.return_type with auto return_type VS_TAGSEPARATOR_equals auto equal_to;
   if (_chdebug) {
      isay(depth, "_Embeddedget_inferred_return_type_string: return_type="return_type);
      isay(depth, "_Embeddedget_inferred_return_type_string: equal_to="equal_to);
   }
   add_return_info := "";
   if (return_type != "") {
      tag_return_type_init(auto rt);
      isjava := _LanguageInheritsFrom("java",  cm.language) ||
                _LanguageInheritsFrom("js",    cm.language) ||
                _LanguageInheritsFrom("cs",    cm.language);
      ar_index := _FindLanguageCallbackIndex("_%s_analyze_return_type");
      rt_status := VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      if (ar_index > 0) {
         rt_status = _Embeddedanalyze_return_type(ar_index, errorArgs, tag_files, cm, return_type, rt, visited);
      }
      if (rt_status < 0 && rt_status != VSCODEHELPRC_BUILTIN_TYPE) {
         rt_status = _Embeddedparse_return_type(errorArgs, tag_files, cm.member_name, cm.class_name, cm.file_name, cm.return_type, isjava, rt, visited);
      }
      if (rt_status == 0 || rt_status == VSCODEHELPRC_BUILTIN_TYPE) {
         add_return_info = tag_return_type_string(rt);
         if (stranslate(add_return_info,""," ") == stranslate(return_type,""," ")) {
            if (_chdebug) {
               isay(depth, "_Embeddedget_inferred_return_type_string: OUT, no change");
            }
            add_return_info="";
            return "";
         }
      }

   }
   if (equal_to != "") {
      tag_return_type_init(auto rt);
      eq_status := _Embeddedget_type_of_expression(errorArgs, tag_files, cm.member_name, cm.class_name, cm.file_name, VSCODEHELP_PREFIX_NULL, equal_to, rt, visited);
      if (eq_status == 0 || eq_status == VSCODEHELPRC_BUILTIN_TYPE) {
         add_return_info = tag_return_type_string(rt);
         if (stranslate(add_return_info,""," ") == stranslate(return_type,""," ")) {
            if (_chdebug) {
               isay(depth, "_Embeddedget_inferred_return_type_string: OUT, no change");
            }
            add_return_info="";
            return "";
         }
      }
   }
   if (add_return_info == "") {
      // Slick-C colon-declared local variable with type of reference parameter
      if ( _LanguageInheritsFrom("e", cm.language) && cm.type_name=="lvar" && cm.return_type=="auto") {
         tag_return_type_init(auto rt);
         param_status := _c_get_type_of_parameter(errorArgs,tag_files,cm,rt,visited,depth+1);
         if (param_status == 0 || param_status == VSCODEHELPRC_BUILTIN_TYPE) {
            add_return_info = tag_return_type_string(rt);
            if (stranslate(add_return_info,""," ") == stranslate(return_type,""," ")) {
               if (_chdebug) {
                  isay(depth, "_Embeddedget_inferred_return_type_string: OUT, no change");
               }
               add_return_info="";
               return "";
            }
         }
      }
   } else {
      if (_LanguageInheritsFrom("e", cm.language)) {
         add_return_info = stranslate(add_return_info, "_str", "_sc_lang_string");
      }
   }
   if (_chdebug) {
      isay(depth, "_Embeddedget_inferred_return_type_string: OUT, add_return_info="add_return_info);
   }
   return add_return_info;
}

/**
 * 
 * 
 * @param codehelp_flags
 * 
 * @return int
 */
int tag_check_for_preferred_symbol(VSCodeHelpFlags codehelp_flags)
{
   // index of unique tag match
   num_procs      := 0;
   num_protos     := 0;
   num_vardefs    := 0;
   num_vardecls   := 0;
   unique_proc    := 0;
   unique_proto   := 0;
   unique_other   := -1;

   // index of unique tag match in current project
   num_in_cur_wkspace := 0;
   num_in_cur_project := 0;
   num_in_rel_project := 0;
   num_prj_procs    := 0;
   num_prj_protos   := 0;
   num_prj_vardefs  := 0;
   num_prj_vardecls := 0;
   unique_wkspace   := 0;
   unique_project   := 0;
   unique_relative  := 0;
   current_wkspace  := _workspace_filename;
   current_project  := _project_name;
   relative_project := "";
   if (_isEditorCtl() && (codehelp_flags & (VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT|VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT))) {
      relative_project = _WorkspaceFindProjectWithFile(p_buf_name, _workspace_filename, true, true);
   }

   // for keeping track if proc/proto class names match
   require_choice    := false;
   unique_class_name := null;
   unique_class      := true;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(false);

   // count the number of procs and protos and the
   // index of the unique item
   tag_type  := "";
   tag_flags := 0;
   file_name := "";
   class_name:= "";
   start_line_number := 0;
   scope_line_number := 0;
   bool matches_in_project[];
   bool matches_in_wkspace[];
   matches_in_project[0] = false;
   matches_in_wkspace[0] = false;
   n := tag_get_num_of_matches();
   for (i:=1; i<=n; ++i) {
      tag_get_detail2(VS_TAGDETAIL_match_type, i, tag_type);
      tag_get_detail2(VS_TAGDETAIL_match_flags, i, tag_flags);
      tag_get_detail2(VS_TAGDETAIL_match_file, i, file_name);
      tag_get_detail2(VS_TAGDETAIL_match_class, i, class_name);
      class_name = stranslate(class_name, VS_TAGSEPARATOR_package, VS_TAGSEPARATOR_class);

      // are we already on this symbol?
      if (_isEditorCtl()) {
         tag_get_detail2(VS_TAGDETAIL_match_line, i, start_line_number);
         tag_get_detail2(VS_TAGDETAIL_match_scope_linenum, i, scope_line_number);
         if (scope_line_number < start_line_number) scope_line_number = start_line_number+1;
         if (!_file_eq(file_name,p_buf_name) || p_RLine < start_line_number || p_RLine > scope_line_number) {
            if (unique_other < 0) {
               unique_other = i;
            } else {
               unique_other = 0;
            }
         }
      }

      // check if the file is in the current project
      matches_in_wkspace[i] = false;
      matches_in_project[i] = false;
      in_current_project := 0;
      if (current_project != "" && (codehelp_flags & (VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT|VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT))) {
         in_current_project = _isFileInProject(_workspace_filename, current_project, file_name);
         if (in_current_project) {
            unique_wkspace = i;
            unique_project = i;
            num_in_cur_wkspace++;
            num_in_cur_project++;
            matches_in_wkspace[i] = true;
            matches_in_project[i] = true;
         } else if (relative_project != "" && !_file_eq(relative_project, current_project)) {
            in_current_project = _isFileInProject(_workspace_filename, relative_project, file_name);
            if (in_current_project) {
               unique_wkspace = i;
               unique_relative = i;
               num_in_cur_wkspace++;
               num_in_rel_project++;
               matches_in_wkspace[i] = true;
               matches_in_project[i] = true;
            }
         }
      }

      // check if the file is in the current workspace
      if (!in_current_project && current_wkspace != "" && (codehelp_flags & (VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT|VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_WORKSPACE))) {
         found_in_workspace := _WorkspaceFindFile(file_name, _workspace_filename, returnAll:true);
         if (found_in_workspace != "") {
            unique_wkspace = i;
            num_in_cur_wkspace++;
            matches_in_wkspace[i] = true;
         }
      }

      // check that the class name matches
      if (unique_class_name == null) {
         unique_class_name = class_name;
      } else if (tag_compare_classes(unique_class_name,class_name) != 0) {
         if (endsWith(unique_class_name,VS_TAGSEPARATOR_package:+class_name,true)) {
            // there must have been a namespace qualification, let it ride
         } else if (endsWith(class_name, VS_TAGSEPARATOR_package:+unique_class_name,true)) {
            // found a longer qualified name
            unique_class_name=class_name;
         } else {
            unique_class = false;
         }
      }

      if (tag_type=="var") {
         // declaration
         num_vardecls++;
         if (in_current_project) {
            unique_proto = i;
            num_prj_vardecls++;
         } else if (!unique_proto) {
            unique_proto = i;
         }
      } else if (tag_type == "proto" || tag_type == "procproto") {
         // declaration
         num_protos++;
         if (in_current_project) {
            unique_proto = i;
            num_prj_protos++;
         } else if (!unique_proto) {
            unique_proto = i;
         }
      } else if (tag_tree_type_is_func(tag_type)) {
         // definition
         num_procs++;
         if (in_current_project) {
            unique_proc = i;
            num_prj_procs++;
         } else if (!unique_proc) {
            unique_proc = i;
         }
      } else if (tag_type=="gvar") {
         if (tag_flags & SE_TAG_FLAG_EXTERN) {
            // assume this is a declaration
            num_vardecls++;
            if (in_current_project) {
               unique_proto = i;
               num_prj_vardecls++;
            } else if (!unique_proto) {
               unique_proto = i;
            }
         } else {
            // definition
            num_vardefs++;
            if (in_current_project) {
               unique_proc = i;
               num_prj_procs++;
            } else if (!unique_proc) {
               unique_proc = i;
            }
         }
      } else if (tag_tree_type_is_class(tag_type)) {
         // classes, looking for a unique, not forward declaration
         if (!(tag_flags & SE_TAG_FLAG_FORWARD)) {
            num_procs++;
            if (in_current_project) {
               unique_proc = i;
               num_prj_procs++;
            } else if (!unique_proc) {
               unique_proc = i;
            }
         } else {
            num_protos++;
         }
      } else {
         // not a proc or proto, so force choice
         require_choice = true;
      }
   }

   // check if we have a unique match in the current project or current workspace
   if (unique_other <= 0 && (unique_relative || unique_project || unique_wkspace) && (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT)) {
      // check for unique definition
      if (unique_class && (num_prj_procs+num_prj_vardefs)==1 && (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION)) {
         return unique_proc;
      }
      // check for unique declaration
      if (unique_class && (num_prj_protos+num_prj_vardecls)==1 && (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION)) {
         return unique_proto;
      }
      // only one symbol in the current project, then just go to it
      if (num_in_cur_project == 1) {
         return unique_project;
      }
      // only one symbol in the relative project, then just go to it
      if (num_in_rel_project == 1) {
         return unique_relative;
      }
      // only one symbol in the current workspace, then just go to it
      if (num_in_cur_wkspace == 1) {
         return unique_wkspace;
      }
   }

   // should we just jump to the other unique corresponding tag?
   if (unique_other > 0 && (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_ALTERNATE)) {
      return unique_other;
   }

   // check that we don't have both vars and functions
   if ((num_procs+num_protos) > 0 && (num_vardecls+num_vardefs) > 0) {
      require_choice = true;
   }

   // check if we are already on a symbol, but there are numerous options
   if (!require_choice && unique_other >= 0 && (unique_proc || unique_proto) ) {
      if (unique_proc  > 0 && (num_protos+num_vardecls) > 1) require_choice = true;
      if (unique_proto > 0 && (num_procs +num_vardefs ) > 1) require_choice = true;
   }

   // check for unique definition
   if (!require_choice && unique_class && (num_procs+num_vardefs)==1 && (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION)) {
      return unique_proc;
   }

   // check for unique declaration
   if (!require_choice && unique_class && (num_protos+num_vardecls)==1 && (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION)) {
      return unique_proto;
   }

   // no unique symbol, but we may need to filter down to project or workspace matches only
   if (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT) {
      // filter matches down to items in current project and relative project only
      if (num_in_cur_project > 0 || num_in_rel_project > 0) {
         if ( _chdebug ) {
            say("tag_check_for_preferred_symbol H"__LINE__": FILTER TO PROJECT ONLY");
         }
         sentry.lockMatches(true);
         tag_get_all_matches(auto matches);
         tag_clear_matches();
         for (i=1; i<=n; i++) {
            if (matches_in_project[i]) {
               tag_insert_match_info(matches[i-1]);
            }
         }
         // now prompt with the restricted list of matches, unless there is only one
         return (tag_get_num_of_matches() == 1)? 1:0;
      }
   }
   if (codehelp_flags & (VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_WORKSPACE|VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT)) {
      if (num_in_cur_wkspace > 0) {
         if ( _chdebug ) {
            say("tag_check_for_preferred_symbol H"__LINE__": FILTER TO WORKSPACE ONLY");
         }
         sentry.lockMatches(true);
         tag_get_all_matches(auto matches);
         tag_clear_matches();
         for (i=1; i<=n; i++) {
            if (matches_in_wkspace[i]) {
               tag_insert_match_info(matches[i-1]);
            }
         }
         // now prompt with the restricted list of matches, unless there is only one
         return (tag_get_num_of_matches() == 1)? 1:0;
      }
   }

   // no unique preferred selection
   return 0;
}

/**
 * Filter any tags from a match set which are not Ant target or 
 * property tags.  Because of the nature of SlickEdit's xml 
 * tagging, we could get extraneous matches based on the names 
 * of attributes or tasks, which we don't want to include in the 
 * results. 
 *  
 * @param onref Whether we are on a property reference, 
 *              indicating that we should restrict results to
 *              properties
 *  
 */
void tag_filter_ant_matches(bool onref=false)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(true);

   VS_TAG_BROWSE_INFO tag_list[];
   tag_get_all_matches(tag_list);
   haveAllMatches := true;

   int i,n = tag_get_num_of_matches();
   for (i=1; i<=n; ++i) {
      tag_get_detail2(VS_TAGDETAIL_match_type, i, auto tag_type);
      tag_get_detail2(VS_TAGDETAIL_match_file, i, auto file_name);
      removed := false;
      if (onref) {
         if (tag_type != "prop") {
            tag_list[i] = null;
            removed = true;
            haveAllMatches = false;
         }
      } else if (tag_type != "target" && tag_type != "prop") {
         tag_list[i] = null;
         removed = true;
         haveAllMatches = false;
      } 
      if (!removed && def_antmake_filter_matches) {
         int handle = _xmlcfg_open_from_buffer(_mdi.p_child, auto status, VSXMLCFG_OPEN_ADD_PCDATA);
         if (!status) {
            if (p_buf_name != file_name) {
               // match is from different file
               keep := false;
               j := 0;
               typeless imports[] = null;
               status = _xmlcfg_find_simple_array(handle, "//import", imports, TREE_ROOT_INDEX);
               if(!status) {
                  for(j = 0; j < imports._length() && !keep; j++) {
                     // get the file name of the import
                     _str importFile = _xmlcfg_get_attribute(handle, imports[j], "file");
                     if (importFile == "") {
                         continue;
                     }
                     // try to resolve the absolute filename
                     absName := absolute(importFile,_strip_filename(p_buf_name,'N'));
                     if (absName == "") {
                         continue;
                     }
                     // if the import is for the file where the match exists, keep the match 
                     if (absName == file_name) {
                        keep = true;
                     }
                  }
               } else {
                  // if we get an error doing an xmlcfg operation, stop trying to filter
                  keep = true;
               }
               if (!keep) {
                  // now check for external xml entities
                  int dtnode = _xmlcfg_get_first_child(handle,TREE_ROOT_INDEX,VSXMLCFG_NODE_DOCTYPE);
                  if(dtnode > 0) {
                     _str ht:[];
                     status = _xmlcfg_get_attribute_ht(handle,dtnode,ht);
                     if(status == 0) {
                        _str attr, val;
                        _str entities[],ids[];
                        foreach( attr => val in ht ) {
                           parseFilesFromEntity(val,entities,ids);
                        }
                        for (j = 0; j < entities._length() && !keep; j++) {
                           absName := absolute(entities[j],_strip_filename(p_buf_name,'N'));
                           // if the entity is for the file where the match exists, keep the match 
                           if (absName == file_name) {
                              keep = true;
                           }
                        }
                     } else {
                        // if we get an error doing an xmlcfg operation, stop trying to filter
                        keep = true;
                     }
                  }
               }
               if (!keep) {
                  tag_list[i] = null;
                  removed = true;
                  haveAllMatches = false;
               }
            } else {
               // match is from the same file
            }
         }
         _xmlcfg_close(handle);
      }
   }

   // reconstruct the set of tag matches
   if (!haveAllMatches) {
      tag_clear_matches();
      n = tag_list._length();
      for (i=0; i<n; ++i) {
         if (tag_list[i] != null) {
            tag_insert_match_info(tag_list[i]);
         }
      }
   }

}

/**
 * Filter symbol matches leaving only matches that start on the given line. 
 * 
 * @param expected_line   Expected symbol start line.
 */
void tag_filter_matches_on_line(int expected_line)
{
   VS_TAG_BROWSE_INFO found_on_line[];
   n := tag_get_num_of_matches();
   for (i:=1; i<=n; ++i) {
      tag_get_match_info(i, auto im);
      if (im != null && im.line_no == expected_line) {
         found_on_line :+= im;
      }
   }
   n = found_on_line._length();
   if (n > 0) {
      tag_clear_matches();
      for (i=0; i<n; ++i) {
         if (found_on_line[i] != null) {
            tag_insert_match_info(found_on_line[i]);
         }
      }
   }
}

/**
 * Filter out the symbols in the current match set that do not
 * match the given set of filters.  If none of the symbols in the
 * match set match the filters, do no filtering.
 * 
 * @param filter_flags  bitset of VS_TAGFILTER_*
 * @param filter_all    if 'true', allow all the matches to be filtered out 
 *  
 * @deprecated Use tag_filter_symbols_from_matches() instead 
 */
void tag_filter_symbol_matches(SETagFilterFlags filter_flags, bool filter_all=false)
{
   tag_filter_symbols_from_matches(filter_flags, filter_all);
}

/**
 * Remove duplicate tag matches from the current match set.
 * 
 * @param filterDuplicatePrototypes
 *        Remove forward declarations of functions if 
 *        the corresponding function definition is 
 *        also in the match set.
 * @param filterDuplicateGlobalVars
 *        Remove forward or extern declarations or global 
 *        and namespace level variables if the actual variable 
 *        definition is also in the match set.
 * @param filterDuplicateClasses
 *        Remove forward declarations of classes, structs, and 
 *        interfaces if the actual definition is in the match set.
 * @param filterAllImports
 *        Remove all import statements from the match set.
 * @param filterDuplicateDefinitions
 *        Remove all duplicate symbol definitions.
 * @param filterAllTagMatchesInContext
 *        Remove tag matches that are found in the 
 *        current symbol context.
 * @param matchExact 
 *        look for exact matches
 * @param filterFunctionSignatures 
 *        attempt to filter out function signatures that do not match
 * @param visited 
 *        cache of previous tagging results
 * @param depth 
 *        depth of recursive search
 * @param filterAnonymousClasses 
 *        Filter out anonymous class names in preference of typedef.
 *        for cases like typedef struct { ... } name_t;
 * @param filterTagUses 
 *        Filter out tags of type 'taguse'.
 *        for cases of mixed language android projects, which
 *        have duplicate symbol names in the XML and Java.
 * @param filterTagAttributes 
 *        Filter out tags of type 'attribute'.
 *        for cases of mixed language android projects, which
 *        have duplicate symbol names in the XML and Java.
 * @param filterAnnotations 
 *        Filter out tags of type 'annotation' so that annotations
 *        do not conflict with other symbols with the same name.
 * @param filterBinaryLoadedTags 
 *        Filter out tags from files which were loaded using a binary load tags 
 *        method, such as jar files or .NET dll files.
 *  
 * @see tag_remove_duplicate_symbols_from_matches_with_function_argument_matching 
 * @see tag_remove_duplicate_symbols_from_matches 
 *  
 * @categories Tagging_Functions
 *
 */
void tag_remove_duplicate_symbol_matches(bool filterDuplicatePrototypes=true,
                                         bool filterDuplicateGlobalVars=true,
                                         bool filterDuplicateClasses=true,
                                         bool filterAllImports=true,
                                         bool filterDuplicateDefinitions=false,
                                         bool filterAllTagMatchesInContext=false,
                                         _str matchExact="",
                                         bool filterFunctionSignatures=false,
                                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                                         bool filterAnonymousClasses=true,
                                         bool filterTagUses=true,
                                         bool filterTagAttributes=false,
                                         bool filterAnnotations=false,
                                         bool filterBinaryLoadedTags=true)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(true);

   // use the fast C++ version to remove duplicates
   tag_remove_duplicate_symbols_from_matches(matchExact, 
                                             _isEditorCtl()? p_buf_name:"",
                                             _isEditorCtl()? p_LangId:"",
                                             ((filterDuplicatePrototypes? VS_TAG_REMOVE_DUPLICATE_PROTOTYPES : 0) |
                                              (filterDuplicateGlobalVars? VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS : 0) |
                                              (filterDuplicateClasses? VS_TAG_REMOVE_DUPLICATE_CLASSES : 0) |
                                              (filterAllImports? VS_TAG_REMOVE_DUPLICATE_IMPORTS : 0) |
                                              (filterDuplicateDefinitions? VS_TAG_REMOVE_DUPLICATE_SYMBOLS : 0) |
                                              (filterAllTagMatchesInContext? VS_TAG_REMOVE_DUPLICATE_CURRENT_FILE : 0) |
                                              (filterFunctionSignatures? VS_TAG_REMOVE_DUPLICATE_FUNCTION_SIGNATURES : 0) |
                                              (filterAnonymousClasses? VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES : 0) |
                                              (filterTagUses? VS_TAG_REMOVE_DUPLICATE_TAG_USES : 0) |
                                              (filterTagUses? VS_TAG_REMOVE_DUPLICATE_TAG_ATTRIBUTES : 0) |
                                              (!(def_references_options & VSREF_ALLOW_MIXED_LANGUAGES)? VS_TAG_REMOVE_INVALID_LANG_REFERENCES : 0) |
                                              (filterAnnotations? VS_TAG_REMOVE_DUPLICATE_ANNOTATIONS : 0) |
                                              (filterBinaryLoadedTags? VS_TAG_REMOVE_BINARY_LOADED_TAGS : 0)
                                             ));

   // still have more work to do if filtering out by function signatures
   n := tag_get_num_of_matches();
   if (filterFunctionSignatures && n > 1 && _isEditorCtl()) {
      tag_filter_matches_by_function_arguments(visited, depth+1);
   }
}

/**
 * Remove duplicate tag matches from the current match set, by looking at the 
 * argument list for the current function call under the cursor and evaluating 
 * the return types of each argument and matching them against each of the 
 * overloaded function signatures in the current match set. 
 * 
 * @param visited            cache of previous tagging results
 * @param depth              depth of recursive search
 *  
 * @see tag_remove_duplicate_symbols_from_matches_with_function_argument_matching 
 * @see tag_remove_duplicate_symbols_from_matches
 */
void tag_filter_matches_by_function_arguments(VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_chdebug) {
      isay(depth, "tag_filter_matches_by_function_arguments: IN");
   }
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(true);

   // still have more work to do if filtering out by function signatures
   n := tag_get_num_of_matches();
   if (n > 1 && _isEditorCtl()) {

      // put all the matches in an array
      numFuncs := 0;
      VS_TAG_BROWSE_INFO definiteTagList[];
      for (i:=0; i<n; ++i) {
         tag_get_match_info(i+1,definiteTagList[i]);
         if (tag_tree_type_is_func(definiteTagList[i].type_name)) ++numFuncs;
      }
      

      // are there multiple functions in the list?
      if (numFuncs <= 1) {
         return;
      }

      // keep track of the argument lists for all the tags we have processed
      VS_TAG_FUNCTION_CALL_ARGUMENT tagListArgs[][];

      // we are going to track two sets of results here, symbols that should
      // definately be deleted, and symbols that can speculatively be deleted
      speculativeTagList := definiteTagList;
      numToDefinatelyDelete := 0;
      numToSpeculativlyDelete := 0;

      // check if there are duplicate functions in the list
      for (i=n-1; i>=0; i--) {
         // filter out symbol matches that are not the right argument list
         VS_TAG_BROWSE_INFO cmi = definiteTagList[i];
         if (_chdebug) {
            tag_browse_info_dump(cmi, "tag_filter_matches_by_function_arguments: ARG MATCHING FOR taglist["i"]", depth+1);
         }
         if (tag_tree_type_is_func(cmi.type_name) && 
             !(cmi.flags & SE_TAG_FLAG_MAYBE_VAR) &&
             !(cmi.flags & SE_TAG_FLAG_OPERATOR)) {
            not_even_close_to_matching := false;
            result := tag_check_function_parameter_list(cmi,not_even_close_to_matching,visited,depth+2,tagListArgs[i]);
            if (result == 0) {
               speculativeTagList[i] = null;
               numToSpeculativlyDelete++;
               if (not_even_close_to_matching) {
                  definiteTagList[i] = null;
                  numToDefinatelyDelete++;
                  if (_chdebug) {
                     isay(depth+1, "tag_filter_matches_by_function_arguments: FUNCTION ARGUMENTS DEFINATELY DO NOT MATCH");
                  }
               } else {
                  if (_chdebug) {
                     isay(depth+1, "tag_filter_matches_by_function_arguments: FUNCTION ARGUMENTS SPECULATIVELY DO NOT MATCH");
                  }
               }
               continue;
            } else if (result > 0) {
               if (_chdebug) {
                  isay(depth+1, "tag_filter_matches_by_function_arguments: FUNCTION ARGUMENTS DO MATCH");
               }
               // check to make sure this is not a prototype with no return type
               if (pos("proto",cmi.type_name) && 
                   !pos("destr",cmi.type_name) && 
                   !pos("constr",cmi.type_name) && 
                   cmi.return_type=="" && 
                   _LanguageInheritsFrom('c',cmi.language)) {
                  speculativeTagList[i] = null;
                  numToSpeculativlyDelete++;
               }
            }
         }
      }

      // see if any of the speculative non-matching items were functions whose
      // argument lists match prototypes which did match.
      // check if there are duplicate functions in the list
      for (i=n-1; i>=0; i--) {
         VS_TAG_BROWSE_INFO cmi = speculativeTagList[i];
         if (cmi != null) continue;
         cmi = definiteTagList[i];
         if (cmi == null) continue;
         if (!tag_tree_type_is_func(cmi.type_name)) continue;
         if (pos("proto", cmi.type_name) > 0) continue;
         if (_chdebug) {
            tag_browse_info_dump(cmi, "tag_filter_matches_by_function_arguments: RECHECKING FUNCTION ARG MATCHING FOR taglist["i"]", depth+1);
         }
         for (j:=i-1; j>=0; j--) {
            VS_TAG_BROWSE_INFO cmj = speculativeTagList[j];
            if (cmj == null) continue;
            if (!tag_tree_type_is_func(cmj.type_name)) continue;
            if (!pos("proto", cmj.type_name) > 0) continue;

            args_i := tagListArgs[i];
            args_j := tagListArgs[j];
            if (args_i._length() != args_j._length()) continue;

            allArgsMatch := true;
            for (k:=0; k<args_i._length(); k++) {
               if (args_i[k].type != null && args_j[k].type != null && !tag_return_type_equal(args_i[k].type, args_j[k].type)) {
                  allArgsMatch = false;
                  break;
               }
            }
            if (allArgsMatch) {
               speculativeTagList[i] = definiteTagList[i];
               if (_chdebug) {
                  isay(depth+1, "tag_filter_matches_by_function_arguments: FOUND PROTOTYPE MATCHING FUNCTION ARG LIST");
               }
               break;
            }
         }
      }

      // Make sure that something was filtered out, but not everything.
      if (numToSpeculativlyDelete > 0 && numToSpeculativlyDelete < n) {
         if (_chdebug) {
            isay(depth, "tag_filter_matches_by_function_arguments: BUILD NEW SET OF MATCHES");
         }
         // reconstruct the set of tag matches
         tag_clear_matches();
         n = speculativeTagList._length();
         for (i=0; i<n; ++i) {
            if (speculativeTagList[i] != null) {
               tag_insert_match_info(speculativeTagList[i]);
            }
         }

      } else if (numToDefinatelyDelete > 0 && numToDefinatelyDelete < n) {
         if (_chdebug) {
            isay(depth, "tag_filter_matches_by_function_arguments: BUILD NEW SET OF MATCHES MORE DEFINATE MATCHES");
         }
         // reconstruct the set of tag matches
         tag_clear_matches();
         n = definiteTagList._length();
         for (i=0; i<n; ++i) {
            if (definiteTagList[i] != null) {
               tag_insert_match_info(definiteTagList[i]);
            }
         }
      }
   }
}

/**
 * If all the items in the current match set belong to the same class and 
 * have the same tag name, and are all functions, filter then down to the 
 * least-specified version of the function signature. 
 *  
 * @param depth              depth of recursive search 
 *  
 * @see tag_remove_duplicate_symbols_from_matches_with_function_argument_matching 
 * @see tag_remove_duplicate_symbols_from_matches
 */
void tag_remove_duplicate_symbols_from_matches_ignoring_function_arguments(VSCodeHelpFlags codehelp_flags, int depth=0)
{
   if (_chdebug) {
      isay(depth, "tag_filter_matches_ignoring_function_arguments: IN");
   }

   // check for project/workspace filtering options
   current_wkspace  := _workspace_filename;
   current_project  := _project_name;
   relative_project := "";
   if (_isEditorCtl() && (codehelp_flags & (VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT|VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT))) {
      relative_project = _WorkspaceFindProjectWithFile(p_buf_name, _workspace_filename, true, true);
   }

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(true);

   // check the number of matches, if there is only one, then get out fast
   n := tag_get_num_of_matches();
   if (n <= 1) return;

   // get initial function information
   function_is_in_project := false;
   function_is_in_wkspace := false;
   tag_get_match_info(1, auto function_cm);

   // filter through the rest of the tags
   for (i:=1; i<=n; ++i) {
      tag_get_match_info(i, auto cm);

      // we found a symbol which was not a function name
      if (!tag_tree_type_is_func(cm.type_name)) return;

      // we found a symbol with a name mismatch
      if (function_cm.member_name != cm.member_name) {
         return;
      }

      // we found a symbol with a class name mismatch
      if (function_cm.class_name != cm.class_name) {
         return;
      }

      // we found a different in static vs. non-static
      if ((function_cm.flags & SE_TAG_FLAG_STATIC) != (cm.flags & SE_TAG_FLAG_STATIC)) {
         return;
      }
      // we found a different in const vs. non-const
      if ((function_cm.flags & SE_TAG_FLAG_CONST) != (cm.flags & SE_TAG_FLAG_CONST)) {
         return;
      }
      // we found a different in volatile vs. non-volatile
      if ((function_cm.flags & SE_TAG_FLAG_VOLATILE) != (cm.flags & SE_TAG_FLAG_VOLATILE)) {
         return;
      }

      // ok, we have a function and no other conflicts, now look for the preferred version

      // first, check if they are filtering by project
      if (codehelp_flags & (VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT|VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT)) {
         if (!function_is_in_project) {
            if (current_project != "" && _isFileInProject(_workspace_filename, current_project, cm.file_name) != 0) {
               function_is_in_project = true;
               function_is_in_wkspace = true;
               function_cm = cm;
               continue;
            }
            if (relative_project != "" && 
                       !_file_eq(relative_project, current_project) &&
                       _isFileInProject(_workspace_filename, relative_project, cm.file_name) != 0) {
               function_is_in_project = true;
               function_is_in_wkspace = true;
               function_cm = cm;
               continue;
            }
         }
      }

      // second, check if they are filtering by workspace
      if (codehelp_flags & (VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT|VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_WORKSPACE|VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT)) {
         if (!function_is_in_project && !function_is_in_wkspace) {
            // check if the file is in the current workspace
            if (current_wkspace != "" && _WorkspaceFindFile(cm.file_name, _workspace_filename) != "") {
               function_is_in_wkspace = true;
               function_cm = cm;
               continue;
            }
         }
      }

      // third, prefer prototypes over to definitions
      if (!pos("proto",function_cm.type_name) && !pos("proto",cm.type_name)) {
         function_cm = cm;
         continue;
      }

      // fourth, prefer prototypes with valid return types to anything with no return type
      if (pos("proto",function_cm.type_name) && 
          !pos("destr",function_cm.type_name) && 
          !pos("constr",function_cm.type_name) && 
          function_cm.return_type == "" && 
          cm.return_type != "" && 
          _LanguageInheritsFrom('c',function_cm.language)) {
         function_cm = cm;
         continue;
      }

      // fifth, prefer a "current context" match to a database match
      if (function_cm.tag_database != null && function_cm.tag_database != "") {
         if (cm.tag_database == null || cm.tag_database == "") {
            function_cm = cm;
            continue;
         }
      }

      // finally, prefer shorter argument lists
      if (length(cm.arguments) < length(function_cm.arguments)) {
         function_cm = cm;
         continue;
      }
   }

   // reconstruct the set of tag matches with our one chosen match
   if (function_cm.member_name != "") {
      tag_clear_matches();
      tag_insert_match_info(function_cm);
   }
}

/**
 * Remove duplicate symbols from the set of tags in a match set.
 * 
 * @param pszMatchExactSymbolName   (optional) look for exact matches to this symbol only 
 * @param pszCurrentFileName        (optional) current file name
 * @param pszCurrentFileName        (optional) current language mode
 * @param removeDuplicatesOptions   set of bit flags of options for what kinds of duplicates to remove. 
 *        <ul>
 *        <li>VS_TAG_REMOVE_DUPLICATE_PROTOTYPES -
 *            Remove forward declarations of functions if the corresponding function 
 *            definition is also in the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS -              
 *            Remove forward or extern declarations of global and namespace level 
 *            variables if the actual variable definition is also in the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_CLASSES -              
 *            Remove forward declarations of classes, structs, and 
 *            interfaces if the actual definition is in the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_IMPORTS -
 *            Remove all import statements from the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_SYMBOLS -
 *            Remove all duplicate symbol definitions.
 *        <li>VS_TAG_REMOVE_DUPLICATE_CURRENT_FILE -
 *            Remove tag matches that are found in the current symbol context.
 *        <li>VS_TAG_REMOVE_DUPLICATE_FUNCTION_SIGNATURES -              
 *            [not implemented here] 
 *            Attempt to filter out function signatures that do not match.
 *        <li>VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES -              
 *            Filter out anonymous class names in preference of typedef.
 *            for cases like typedef struct { ... } name_t;
 *        <li>VS_TAG_REMOVE_DUPLICATE_TAG_USES -              
 *            Filter out tags of type 'taguse'.  For cases of mixed language
 *            Android projects, which have duplicate symbol names in the XML and Java.
 *        <li>VS_TAG_REMOVE_DUPLICATE_ANNOTATIONS -              
 *            Filter out tags of type 'annotation' so that annotations
 *            do not conflict with other symbols with the same name.
 *        <li>VS_TAG_REMOVE_BINARY_LOADED_TAGS -
 *            Filter out tags from files which were loaded using a binary
 *            load tags method, such as jar files or .NET dll files.
 *        </ul>
 * @param visited    cache of previous tagging results
 * @param depth      depth of recursive search
 *  
 * @see tag_list_symbols_in_context 
 * @see tag_list_in_class
 * @see tag_list_in_file
 * @see tag_list_globals_of_type 
 * @see tag_list_context_globals
 * @see tag_list_context_imports
 * @see tag_list_context_packages
 * @see tag_list_duplicate_matches 
 * @see tag_list_duplicate_tags 
 * @see tag_remove_duplicate_symbols_from_matches
 * @see tag_remove_duplicate_symbol_matches 
 *
 * @categories Tagging_Functions
 */
void tag_remove_duplicate_symbols_from_matches_with_function_argument_matching(_str pszMatchExactSymbolName,
                                                                               _str pszCurrentFileName,
                                                                               _str pszCurrentLangId,
                                                                               VSTagRemoveDuplicatesOptionFlags removeDuplicatesOptions,
                                                                               VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(true);

   // use the fast C++ version to remove duplicates
   tag_remove_duplicate_symbols_from_matches(pszMatchExactSymbolName, 
                                             pszCurrentFileName,
                                             pszCurrentLangId,
                                             removeDuplicatesOptions);

   // still have more work to do if filtering out by function signatures
   n := tag_get_num_of_matches();
   if ((removeDuplicatesOptions & VS_TAG_REMOVE_DUPLICATE_FUNCTION_SIGNATURES) && n > 1 && _isEditorCtl()) {
      tag_filter_matches_by_function_arguments(visited, depth+1);
   }
}

/**
 * If the match set contains an item which matches the symbol under
 * the cursor, according to it's start and scope seek positions,
 * select only that match, removing all other matches from the
 * match set.
 * 
 * @param bufName    file name the cursor is in
 * @param offset     real offset within file where the cursor is
 */
void tag_filter_only_match_under_cursor(_str fileName, long offset)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(false);
   _str taglanghash:[];
   _str tagfilehash:[];
   n := tag_get_num_of_matches();
   for(i:=1; i<=n; ++i) {
      match_file_name := "";
      match_file_lang := "";
      match_tag_file  := "";
      tag_get_detail2(VS_TAGDETAIL_match_file, i, match_file_name);
      tag_get_detail2(VS_TAGDETAIL_match_language_id, i, match_file_lang);
      tag_get_detail2(VS_TAGDETAIL_match_tag_file, i, match_tag_file);
      match_file_name = _file_case(match_file_name);
      if (match_file_lang != "") taglanghash:[match_file_name] = match_file_lang;
      if (match_tag_file  != "") tagfilehash:[match_file_name] = match_tag_file;
   }

   for(i=1; i<=n; ++i) {
      match_file_name := "";
      match_start_seekpos := 0;
      match_scope_seekpos := 0;
      tag_get_detail2(VS_TAGDETAIL_match_file, i, match_file_name);
      tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, i, match_start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_match_scope_seekpos, i, match_scope_seekpos);
      if (_file_eq(match_file_name, fileName) && 
          offset >= match_start_seekpos && offset <= match_scope_seekpos) {
         tag_get_match_info(i, auto cm);
         match_file_name = _file_case(match_file_name);
         if ((cm.language == null || cm.language == "") && taglanghash._indexin(match_file_name)) {
            cm.language = taglanghash:[match_file_name]; 
         }
         if ((cm.tag_database == null || cm.tag_database == "") && tagfilehash._indexin(match_file_name)) {
            cm.tag_database = tagfilehash:[match_file_name]; 
         }
         tag_clear_matches();
         tag_insert_match_info(cm);
         break;
      }
   }
}

/**
 * Find tags matching the given tag name, using context information.
 *
 * @param errorArgs        On error set to arguments for error message.
 * @param tagname          (reference) set to name of symbol under cursor
 * @param find_parents     find instances of symbol in parent classes?
 * @param max_matches      maximun number of matches to find
 * @param exact_match      exact match or prefix match?
 * @param case_sensitive   case sensitive or case-insensitive match?
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 * @param filter_flags     Tag filter flags, only insert tags passing this 
 *                         filter. See {@link tag_filter_type} for more details.
 * @param context_flags    VS_TAGCONTEXT_*, tag context filter flags
 *
 * @return &lt;0 on error or no matches.  Otherwise, it returns the
 *         number of matches found.
 */
int context_match_tags(_str (&errorArgs)[], 
                       _str &tagname,
                       bool find_parents=false,
                       int max_matches=def_tag_max_find_context_tags,
                       bool exact_match=true,
                       bool case_sensitive=false,
                       VS_TAG_RETURN_TYPE (&visited):[]=null,
                       int depth=0,
                       SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                       SETagContextFlags context_flags=SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS)
{
   // in a comment or string, then no context
   if (_chdebug) {
      isay(depth, "context_match_tags("tagname")");
   }
   int cfg=_clex_find(0,'g');
   if (_in_comment() ||
       (cfg==CFG_STRING && !_LanguageInheritsFrom("cob") &&
        !_LanguageInheritsFrom("html") &&
        upcase(substr(p_lexer_name,1,3))!="XML")) {
      //say("context_match_tags: in string or comment");
      save_pos(auto p);
      left();cfg=_clex_find(0,'g');
      // Allow searching in strings in all languages (need this for finding
      // references to include files in C/C++).  Let the individual language
      // decide if it can or can not create an ID expression in a string.
      if (_in_comment() /*|| cfg==CFG_STRING*/) {
         restore_pos(p);
         if (_chdebug) {
            isay(depth, "context_match_tags: IN COMMENT");
         }
         return 0;
      }
      restore_pos(p);
   }

   // Update the current context and locals
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);
   _UpdateContextAndTokens(true);
   _UpdateLocals(true);

   // make sure that class names are matched case-sensitive
   if (p_EmbeddedCaseSensitive) {
      filter_flags |= SE_TAG_FILTER_CASE_SENSITIVE;
   }

   errorArgs._makeempty();
   status := ctstatus := num_matches := 0;
   tag_clear_matches();
   if (_haveContextTagging()) {
      if (_chdebug) {
         isay(depth, "context_match_tags: have context tagging");
      }
      status = tag_context_match_tags(errorArgs,
                                      tagname,exact_match,
                                      case_sensitive,find_parents,
                                      num_matches,max_matches,
                                      visited, depth+1,
                                      filter_flags, context_flags);
   } else {
      // try generic function for searching for symbol matches (locals and current file)
      if (tagname == "" && _isEditorCtl()) {
         tagname = cur_identifier(auto col);
      }
      if (_chdebug) {
         isay(depth, "context_match_tags: using generic callback, tagname="tagname);
      }
      status = tag_list_symbols_in_context(tagname, "", 
                                           0, 0, null, "",
                                           num_matches, max_matches,
                                           filter_flags, context_flags|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ONLY_CONTEXT,
                                           exact_match, case_sensitive, 
                                           visited, depth+1);
      // no context tagging, try ctags support
      if (_haveCtags() && (status < 0 || num_matches <= 0) && !(context_flags & SE_TAG_CONTEXT_RESTRICTIVE_FLAGS)) {
         ctstatus = tag_list_symbols_in_ctags_file("", tagname, exact_match, true, true, case_sensitive, "", num_matches, max_matches);
      } else {
         ctstatus = VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
      }
      if (status < 0 && ctstatus >= 0) status = ctstatus;
   }
   if (status < 0) {
      // match tags failed
      if (_chdebug) {
         isay(depth, "context_match_tags: FAIL status="status);
      }
      return status;
   }
   num_matches = tag_get_num_of_matches();
   if (_chdebug) {
      isay(depth, "context_match_tags: status="status" num_matches="num_matches);
   }
   return num_matches;
}

/**
 * Use {@link context_match_tags} to find tags for tag navigation.
 * This is the preferred method for finding matches to tags, although,
 * if it fails, pushtag will revert to a more simplistic method that
 * just searches for a match by tag name.
 *
 * @param proc_name              name of symbol to search for 
 * @param find_parents           find symbol in parent classes also 
 * @param force_case_sensitive   case sensitive or case-insensitive match?
 * @param visited                (optional) hash table of prior results
 * @param depth                  (optional) depth of recursive search
 * @param max_matches            maximun number of matches to find
 * @param filter_flags           Tag filter flags, only insert tags passing this 
 *                               filter. See {@link tag_filter_type} for more details.
 * @param context_flags          VS_TAGCONTEXT_*, tag context filter flags
 *
 * @return false on failure, true on success.
 */
static bool context_find_tag(_str &proc_name,
                             bool find_parents=true,
                             bool force_case_sensitive=false,
                             int max_matches=def_tag_max_find_context_tags,
                             SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                             SETagContextFlags context_flags=SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS,
                             VS_TAG_RETURN_TYPE (&visited):[]=null,
                             int depth=0) 
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   match_tag := "";
   _str errorArgs[]; errorArgs._makeempty();
   tag_clear_matches();
   num_matches := context_match_tags(errorArgs,
                                     match_tag,
                                     find_parents,
                                     max_matches,
                                     true/*exact_match*/,
                                     p_EmbeddedCaseSensitive || force_case_sensitive,
                                     visited, depth,
                                     filter_flags,
                                     context_flags);
   if (num_matches <= 0) {
      return false;
   }

   tag_get_detail2(VS_TAGDETAIL_match_name, 1, proc_name);
   return true;
}

/**
 * Returns the number of tags found.
 */
static void find_tag_matches3(_str proc_name, int max_matches, SETagFilterFlags filter_flags)
{

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   tag_decompose_tag_browse_info(proc_name, auto cm);
   case_sensitive := p_EmbeddedCaseSensitive;
   i := tag_find_local_iterator(cm.member_name,true,case_sensitive);
   n := tag_get_num_of_matches();
   while (i > 0) {
      tag_get_detail2(VS_TAGDETAIL_local_class, i, auto i_class_name);
      tag_get_detail2(VS_TAGDETAIL_local_type, i, auto i_type_name);
      if ((cm.class_name=="" || i_class_name :== cm.class_name) && 
          (cm.type_name==""  || i_type_name :== cm.type_name) &&
          (cm.type_name!=""  || tag_filter_type(SE_TAG_TYPE_NULL,filter_flags,i_type_name))) {
         tag_insert_match_fast(VS_TAGMATCH_local, i);
         if (n++ > max_matches) break;
      }
      i=tag_next_local_iterator(cm.member_name,i,true,case_sensitive);
   }

   i=tag_find_context_iterator(cm.member_name,true,case_sensitive);
   while (i > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_class, i, auto i_class_name);
      tag_get_detail2(VS_TAGDETAIL_context_type, i, auto i_type_name);
      if ((cm.class_name=="" || i_class_name :== cm.class_name) && 
          (cm.type_name==""  || i_type_name :== cm.type_name) &&
          (cm.type_name!=""  || tag_filter_type(SE_TAG_TYPE_NULL,filter_flags,i_type_name))) {
         tag_insert_match_fast(VS_TAGMATCH_context, i);
         if (n++ > max_matches) break;
      }
      i=tag_next_context_iterator(cm.member_name,i,true,case_sensitive);
   }
}

/*
    Return
       0   Found one or more tags
       1   No tags found
       2   Bad error. Tag file messed up, Out of memory?, file not found
       COMMAND_CANCELLED_RC   User aborted.
*/
int find_tag_matches(_str tag_filelist, 
                     _str proc_name, 
                     bool recursive_call=false,
                     int max_matches=def_tag_max_find_context_tags,
                     SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING)
{
   // translate Slick-C command names with dash
   _str orig_proc_name=proc_name;
   if (!_isEditorCtl() || _LanguageInheritsFrom("e")) {
      proc_name=translate(proc_name,"_","-");
   }

   // handle linkage differences between "C" and assembly
   if (!recursive_call && _isEditorCtl() &&
       (_LanguageInheritsFrom("c") || _LanguageInheritsFrom("for"))) {
      clear_message();
      find_tag_matches(tag_filelist, "_"proc_name,true,max_matches,filter_flags);
   }

   // try to find tags in locals and current context
   if (_isEditorCtl() && _istagging_supported()) {
      find_tag_matches3(proc_name, max_matches, filter_flags);
   }

   status := 0;
   _str tag_files[];
   if (_haveContextTagging()) {
      _str TagFileList=tag_filelist;
      for (;;) {
         _str CurFilename=next_tag_file2(TagFileList,false/*no check*/,false/*no open*/);
         if (CurFilename=="") break;
         CurFilename=absolute(CurFilename);
         status = tag_read_db(CurFilename);
         if ( status < 0 ) {
            // don't sweat over tag files that are auto-generated
            if (isTagFileAutoGenerated(CurFilename)) continue;
            msg := nls("Error opening tag file '%s': %s", CurFilename, get_message(status));
            notifyUserOfWarning(ALERT_TAG_FILE_ERROR, msg, CurFilename, 0);
            continue;
         }
         tag_files[tag_files._length()]=CurFilename;
      }
   }

   status=tag_list_duplicate_matches(proc_name, tag_files, max_matches, filter_flags);
   //say("find_tag2: status="status" proc_name="proc_name);
   if (status && proc_name != orig_proc_name) {
      status=tag_list_duplicate_matches(orig_proc_name, tag_files, max_matches, filter_flags);
   }
   if (!status) {
      clear_message();
   }
   return(status);
}

defeventtab jcl_keys;
def " "=embedded_key;
def "."=embedded_key; // auto_codehelp_key
def "("=embedded_key; // auto_functionhelp_key
def ":"=embedded_key;
def "{"=embedded_key;
def "}"=embedded_key;
//def 'c- '=codehelp_complete;
def TAB=embedded_key;
def ENTER=embedded_key;
//def tab=cob_tab;
//def s_tab=cob_backtab;

int jcl_proc_search1(_str &proc_name, int find_first)
{
   search_key := "";
   status := 0;
   if ( find_first ) {
      word_chars := _clex_identifier_chars();
      search_key='^//{#0['word_chars']#|}[ \t]+proc([ \t]|$)';
      status=search(search_key,'@rhixcs');
   } else {
      status=repeat_search();
   }
   for (;;) {
      if ( status ) {
         return(status);
      }
      name := get_match_text(0);
      if (name=="") {
         parse p_buf_name with "("name")";
         if (name=="") {
            status=repeat_search();
            continue;
         }
      }
      tag_init_tag_browse_info(auto cm, name, "", SE_TAG_TYPE_PROC);
      temp_proc_name := tag_compose_tag_browse_info(cm);
      if (proc_name=="") {
         proc_name=temp_proc_name;
         return(0);
      }
      tag_decompose_tag_browse_info(proc_name,auto proc_cm);
      if ((proc_cm.type_name:==cm.type_name || proc_cm.type_name=="") && strieq(proc_cm.member_name,name)) {
         return(0);
      }
      status=repeat_search();
   }
}
/**
 * Search for tags in JCL code, or in code embedded in JCL.
 *
 * @param proc_name    (reference) proc to search for, or set to name of proc found
 * @param find_first   find first proc, or find next?
 *
 * @return 0 on success, nonzero on error or if no more tags.
 */
int jcl_proc_search(_str &proc_name, int find_first, 
                    _str unused_ext="", _str start_seekpos="", _str end_seekpos="")
{
   return(_EmbeddedProcSearch(jcl_proc_search1,proc_name,find_first,
                              unused_ext, start_seekpos, end_seekpos));
}

/**
 * Search for sections in a Unix Makefile.
 *
 * @param proc_name    (reference) proc to search for, or set to name of proc found
 * @param find_first   find first proc, or find next?
 *
 * @return 0 on success, nonzero on error or if no more tags.
 */
int mak_proc_search(_str &proc_name,bool find_first)
{
   static _str re_map:[];
   if (re_map._isempty()) {
      re_map:["TYPE"] = "[:=]";
   }

   static _str kw_map:[];
   if (kw_map._isempty()) {
      kw_map:[":"] = "label";
      kw_map:["="] = "const";
   }

   return _generic_regex_proc_search("^<<<NAME>>> *<<<TYPE>>>", proc_name, find_first!=0, "", re_map, kw_map);
}

/**
 * Search for labels in a DOS batch file.
 *
 * @param proc_name    (reference) proc to search for, or set to name of proc found
 * @param find_first   find first proc, or find next?
 *
 * @return 0 on success, nonzero on error or if no more tags.
 */
int bat_proc_search(_str &proc_name,bool find_first)
{
   // Lexer definition for Batch has a bunch of
   // extra file separator and filename chars
   // in the identifier characters in order to
   // avoid coloring keywords like "if" as
   // keywords when they appear in a path.
   // Since these are NOT real identifier chars,
   // filter them out.
   static _str re_map:[];
   if (re_map._isempty()) {
      word_chars := _clex_identifier_chars();
      word_chars = stranslate(word_chars,'','?');
      word_chars = stranslate(word_chars,'','%');
      word_chars = stranslate(word_chars,'','.');
      word_chars = stranslate(word_chars,'','~');
      word_chars = stranslate(word_chars,'','/');
      word_chars = stranslate(word_chars,'','\\');
      re_map:["NAME"] = "["word_chars"]#";
   }

   return _generic_regex_proc_search('^\:{<<<NAME>>>} *', proc_name, find_first!=0, "label", re_map);
}

/**
 * Search for sections in a Unix Imakefile.
 *
 * @param proc_name    (reference) proc to search for, or set to name of proc found
 * @param find_first   find first proc, or find next?
 *
 * @return 0 on success, nonzero on error or if no more tags.
 */
int imakefile_proc_search(_str &proc_name,bool find_first)
{
   return mak_proc_search(proc_name,find_first);
}

/**
 * This command runs the external macro "maketags.e".
 *
 * The make_tags command builds a file called "tags.vtg" (UNIX:
 * "utags.vtg") which is a binary database file.  This information is used by the <b>push_tag</b> command to
 * quickly find one of your procedures.  Multiple files with wild cards may be
 * specified.
 *
 * See "tags.e" for information on adding support for other
 * languages.
 *
 * @param cmdline a string with the following possible options
 *
 * <dl>
 * <dt>-L</dt><dd>specifies list file</dd>
 * <dt>@ [file]</dt><dd>specifies a file which contains a
 * list of file names.  Use the <b>write_list</b>
 * command to generate a list of file names.</b></dd>
 * <dt>-R</dt><dd>Update tag file (checks dates)</dd>
 * <dt>-D</dt><dd>delete tags</dd>
 * <dt>-C</dt><dd>allow cancellation</dd>
 * <dt>-O [filename]</dt><dd>specifies a output tag file,
 * rather than using the default of tags.vtg (UNIX:
 * utags.vtg)</dd>
 * <dt>-X</dt><dd>build symbol cross-reference</dd>
 * <dt>-N [desc]</dt><dd>Adds a description of the tag file</dd>
 * <dt>-U [filename]</dt><dd>rebuild the specified tag file</dd>
 * <dt>-P</dt><dd>report the time required to tag</dd>
 * <dt>-B</dt><dd>use background thread if possible</dd>
 * <dt>-T</dt><dd>find files recursively in subdirectories</dd>
 * <dt>-Q</dt><dd>quiet</dd>
 * <dt>-E [dir]</dt><dd>exclude files under directory</dd>
 * </dl>
 *
 *
 * @param OutputFile ] [@]<i>file1</i>  [@]<i>file2 ...</i>

 * @example
 * <pre>
 * make-tags   -t *.c *.asm
 * make-tags   @list1 *.pas
 * </pre>
 *
 * @see push_tag
 * @see gui_make_tags
 *
 * @categories Tagging_Functions, Search_Functions
 *
 * @return 0 on success, nonzero on error.
 */
_command int make_tags(_str params="") name_info(FILE_ARG'*'','VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Tagging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // save focus, in case if tagging is cancelled
   focus_wid := _get_focus();

   // launch maketags batch macro
   status := shell("maketags "params);

   // restore focus (if focus window is still valid and does not already have it
   if (focus_wid && _iswindow_valid(focus_wid) && focus_wid!=_get_focus()) {
      focus_wid._set_focus();
   }

   // that's all folks
   return status;
}

/**
 * This command builds or updates tag files.  The tags files are used by the
 * <b>push_tag</b> and <b>gui_push_tag</b> to go to tag definitions.  The <b>Tag
 * Files dialog box</b> is displayed which lets you choose the files you wish to
 * tag.
 *
 * @return Returns 0 if successful.
 *  
 * @see autotag 
 * @see make_tags
 * @see push_tag
 * @see gui_push_tag
 * @see find_tag
 * @see f
 *
 * @categories Tagging_Functions, Forms, Search_Functions
 */
_command void gui_make_tags(_str tagfilename="", _str forLangId="") name_info(FILENOQUOTES_ARG','VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Tagging");
      return;
   }

   if (!_no_child_windows() && _mdi.p_child._isEditorCtl()) {
      _mdi.show("-xy _tag_form", forLangId, tagfilename);
   } else {
      show("-desktop -xy _tag_form", forLangId, tagfilename);
   }
}

int _OnUpdate_gui_make_tags(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveContextTagging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   return MF_ENABLED;
}


static typeless reset_subdir_box = 0;

/**
 * Returns the name of the current procedure.  This function also will
 * return the name of the current class name, type definition, #define,
 * any definition that is tagged.  If <i>display_message</i> is <b>true</b>
 * or not specified, the current function name is displayed on the message line.
 *
 * @param dosticky_message    Display message on message line, remember
 *                            to pass "false" if you are calling this
 *                            just to get the current proc name.
 *
 * @return the name of the current procedure or "" if it can't be found
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command _str current_proc(bool dosticky_message=true) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   int context_id = tag_current_context(allow_outline_only:true);
   msg := "function";
   proc_name := "";
   type_name := "";
   caption := "";
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_name, context_id, proc_name);
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
      if (tag_tree_type_is_func(type_name)) {
         caption = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,false);
      } else {
         msg = type_name;
         caption = proc_name;
      }
   } else {
      caption   = "undefined.";
      proc_name = "";
   }
   if (dosticky_message) {
      sticky_message("The current "msg" is "caption);
   }
   return(proc_name);
}

/**
 * Returns the signature of the current function.  If
 * <i>display_message</i> is <b>true</b> or not specified, 
 * the current function signature is displayed on the 
 * message line. 
 *
 * @param dosticky_message    Display message on message line, remember
 *                            to pass "false" if you are calling this
 *                            just to get the current proc
 *                            signature.
 *
 * @return the signature of the current procedure or "" if it can't
 *         be found
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command _str current_func_signature(bool dosticky_message=true) name_info(","VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   int context_id = tag_current_context();
   msg := "function";
   type_name := "";
   return_type := "";
   caption := "";
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
      if (tag_tree_type_is_func(type_name)) {
         tag_get_detail2(VS_TAGDETAIL_context_return, context_id, return_type);
         tag_get_detail2(VS_TAGDETAIL_context_throws, context_id, auto throws);
         caption = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,false);
         if (return_type != "") {
            caption = return_type :+ " " :+ caption;
         }
         if (throws != "") {
            caption :+= " throws " :+ throws;
         }
      } else {
         return "";
      }
   } else {
      "";
   }
   if (dosticky_message) {
      sticky_message("The current "msg" is "caption);
   }
   return(caption);
}

static void _parseCurrentFunctionArguments(_str (&javaDocHashTab):[][], 
                                           _str (&xmlDocHashTab):[][], 
                                           _str args, bool doTemplateArgs)
{
   //say("_parseCurrentFunctionArguments H"__LINE__": args="args);
   split(args, ",", auto paramVals);

   // if there are mismatched nested items, correct for it here
   // This solution is not great, but it is better than nothing.
   for (i := 0; i < paramVals._length()-1; i++) {
      if ((pos('<', paramVals[i]) > 0 && pos('>', paramVals[i]) <= 0) ||
          (pos('[', paramVals[i]) > 0 && pos(']', paramVals[i]) <= 0) ||
          (pos('(', paramVals[i]) > 0 && pos(')', paramVals[i]) <= 0) ||
          (pos('{', paramVals[i]) > 0 && pos('}', paramVals[i]) <= 0)) {
         paramVals[i] :+= ',';
         paramVals[i] :+= paramVals[i+1];
         paramVals._deleteel(i+1);
      }
   }

   for (i = 0; i < paramVals._length(); i++) {
      // skip ellipsis
      if (strip(paramVals[i]) != "...") {
         // handle a default value
         int equalsIndex = pos("=",strip(paramVals[i]));
         if (equalsIndex) {
            paramVals[i] = stranslate(strip(substr(paramVals[i],1,equalsIndex)),"","=");
         }
         // handle pass by reference
         int ampersandIndex = pos("&",strip(paramVals[i]));
         if (ampersandIndex) {
            paramVals[i] = stranslate(strip(substr(paramVals[i],ampersandIndex)),"","&");
         }
         // handle pointer
         int starIndex = pos("*",strip(paramVals[i]));
         if (starIndex) {
            paramVals[i] = stranslate(strip(substr(paramVals[i],starIndex)),"","*");
         }
         // handle const 
         int constIndex = pos("const ",strip(paramVals[i]));
         if (constIndex == 1) {
            paramVals[i] = strip(substr(paramVals[i],6));
         }
         // strip out possible non-identifier characters 
         paramVals[i] = stranslate(paramVals[i],'','[\[\]\(\)\:]+','R');
         split(strip(paramVals[i])," ", auto temp);
         param_name := temp[0];
         if (temp._length() > 1) {
            param_name = temp[temp._length() - 1];
         }
         xml_param_tag := "param";
         jd_param_name := param_name;
         if (doTemplateArgs) {
            jd_param_name = "<" :+ param_name :+ ">";
            xml_param_tag = "typeparam";
         }
         javaDocHashTab:["param"] :+= jd_param_name;
         xmlDocHashTab:[xml_param_tag] :+= param_name;
      }
   }
}

/**
 * Parse elements from current function or method signature. 
 * 
 * @param javaDocHashTab
 * @param xmlDocHashTab
 * @param first_line 
 * @param last_line 
 * @param func_start_line 
 * 
 * @return 0 on success 
 */
int _parseCurrentFuncSignature(_str (&javaDocHashTab):[][], 
                               _str (&xmlDocHashTab):[][], 
                               int &first_line, int &last_line, 
                               int &func_start_line)
{
   javaDocHashTab._makeempty();
   xmlDocHashTab._makeempty();

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   current_id := tag_current_context();
   nearest_id := tag_nearest_context(p_RLine, SE_TAG_FILTER_ANYTHING, true);
   if (nearest_id > 0 && (current_id != nearest_id) && _in_comment()) {
      current_id = nearest_id;
   }

   status := 0;
   if (current_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, current_id, auto type_name);
      // are we on a function? 
      if (tag_tree_type_is_func(type_name) || tag_tree_type_is_class(type_name) || tag_tree_type_is_data(type_name)) {
         // get return type or variable type
         if (tag_tree_type_is_func(type_name) || tag_tree_type_is_data(type_name)) {
            tag_get_detail2(VS_TAGDETAIL_context_return, current_id, auto return_type);
            // return value
            javaDocHashTab:["return"][0]=return_type;
            xmlDocHashTab:["return"][0]=return_type;
         }
         // throws or exception values
         if (tag_tree_type_is_func(type_name)) {
            tag_get_detail2(VS_TAGDETAIL_context_throws, current_id, auto throws);
            split(throws, ",", auto throwVals);
            for (i := 0; i < throwVals._length(); i++) {
               javaDocHashTab:["throws"][i]=throwVals[i];
               xmlDocHashTab:["throws"][i]=throwVals[i];
            }
         }
         // param values
         tag_get_detail2(VS_TAGDETAIL_context_template_args, current_id, auto template_args);
         if (template_args != "") {
            _parseCurrentFunctionArguments(javaDocHashTab, xmlDocHashTab, template_args, true);
         }
         tag_get_detail2(VS_TAGDETAIL_context_args, current_id, auto function_args);
         if (function_args != "") {
            _parseCurrentFunctionArguments(javaDocHashTab, xmlDocHashTab, function_args, false);
         }

         save_pos(auto p);
         // find the first and last lines of the comment
         tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, current_id, auto start);
         _GoToROffset(start);
         func_start_line = p_line;
         _do_default_get_tag_header_comments(first_line,last_line);
         restore_pos(p);
      } else {
         status = 1; 
      }
   } else {
      status = 1;
   }
   return status;
}
/**
 * @return
 * Returns the name of the current class context.  Note that the string
 * returned is in tagsdb format with class and package separators, you
 * can use this directly with the searching routines in tagsdb, however
 * you may want to convert the separators to your native language before
 * displaying the results to the user.
 *
 * @param dosticky_message    Display message on message line, remember
 *                            to pass "false" if you are calling this
 *                            just to get the current class name.
 */
_command _str current_class(bool dosticky_message=true) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   _UpdateContext(true);
   caption := "";
   context_id := tag_get_current_context(auto dn,auto df,auto dt,auto di,
                                         auto cur_context,auto cur_class,auto cur_package);
   if (dosticky_message) {
      if (context_id > 0 && cur_class != "") {
         caption = cur_class;
      } else {
         caption = "undefined.";
      }
      sticky_message("The current class is "caption);
   }
   return(cur_class);
}
/**
 * @return
 * Returns a caption representing the name of the current tag
 * under the cursor.
 * The string returne
 * class context.  Note that the string
 * returned is in tagsdb format with class and package separators, you
 * can use this directly with the searching routines in tagsdb, however
 * you may want to convert the separators to your native language before
 * displaying the results to the user.
 *
 * @param dosticky_message    Display message on message line, remember
 *                            to pass "false" if you are calling this
 *                            just to get the current class name.
 * 
 * @see tag_tree_make_caption_fast();
 */
_command _str current_tag(bool dosticky_message=true, bool include_args=false) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   caption := "";
   int context_id = tag_current_context(allow_outline_only:true);
   if (context_id > 0) {
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,include_args,false);
   }
   if (dosticky_message) {
      if (context_id <= 0) {
         caption = "undefined.";
      }
      sticky_message("The current tag is "caption);
   }
   return(caption);
}
/**
 * @return
 * Returns the name of the current package name.  This applies to
 * packages, as in Java, programs and libraries as in Pascal and COBOL,
 * and namespaces, as in C.
 *
 * @param dosticky_message    Display message on message line, remember
 *                            to pass "false" if you are calling this
 *                            just to get the current package name.
 */
_command _str current_package(bool dosticky_message=true) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   _UpdateContext(true);
   caption := "";
   context_id := tag_get_current_context(auto dn,auto df,auto dt,auto di,
                                         auto cur_context,auto dc,auto cur_package);
   if (dosticky_message) {
      if (context_id>0 && cur_package!="") {
         caption = cur_package;
      } else {
         caption = "undefined.";
      }
      sticky_message("The current package is "caption);
   }
   return(cur_package);
}

/**
 * Moves the cursor to the beginning of the enclosing statement or
 * symbol scope relative to the current cursor position.
 * <p>
 * This function is part of statement tagging and only works well
 * for languages that support statement-level tagging.
 * 
 * @return 0 on success, nonzero on error.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int goto_parent() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   // No support for this extension?
   if ( ! _istagging_supported() ) {
      _message_box("Tagging not supported for files of this extension.  Make sure support module is loaded.");
      return(2);
   }
   // Update the complete context information and find nearest tag
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   useStatements := true;
   if (_are_statements_supported()) {
      _UpdateStatements(true,true);
   } else {
      _UpdateContext(true,true);
      useStatements = false;
   }

   current_seekpos := _QROffset();
   context_id := 0;
   
   if (useStatements) {
      context_id = tag_current_statement();
   } else {
      context_id = tag_current_context();
   }
   if (!context_id) {
      if (useStatements) {
         context_id = tag_nearest_statement(p_RLine);
      } else {
         context_id = tag_nearest_context(p_RLine);
      }
   }
   if (!context_id) {
      return (1);
   }

   context_linenum := 0;
   context_seekpos := 0;
   parent_context := 0;
   if (useStatements) {
      tag_get_detail2(VS_TAGDETAIL_statement_start_linenum, context_id, context_linenum);
      tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, context_id, context_seekpos);
   } else {
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, context_linenum);
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, context_seekpos);
   }
   if (context_linenum < p_RLine) {
      parent_context = context_id;
   } else if (context_seekpos < current_seekpos) {
      parent_context = context_id;
   } else {
      if (useStatements) {
         tag_get_detail2(VS_TAGDETAIL_statement_outer, context_id, parent_context);
      } else {
         tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, parent_context);
      }
   }

   // declarations
   if( parent_context > 0 ) {
      tag_init_tag_browse_info(auto cm);
      if (useStatements) {
         tag_get_statement_browse_info(parent_context, cm);
      } else {
         tag_get_context_browse_info(parent_context, cm);
      }

      // go to the symbol location
      p_RLine = cm.scope_line_no;
      _GoToROffset(cm.seekpos);

      // make sure the symbols is not on a hidden line
      if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
         expand_line_level();
      }

      _UpdateContextWindow(true);
      _proc_found = tag_compose_tag_browse_info(cm);
      return(0);
   }

   return (1);
}

/**
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 */
static void go_to_context_tag( int context_id, bool doStatements=false )
{
   tag_get_context_browse_info(context_id, auto cm);
   if ( doStatements ) {
      tag_get_statement_browse_info(context_id, cm);
   }

   // go to the symbol location
   p_RLine = cm.scope_line_no;
   _GoToROffset(cm.seekpos);

   // make sure the symbols is not on a hidden line
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }

   _UpdateContextWindow(true);
   _proc_found = tag_compose_tag_browse_info(cm);
}

/**
 * For synchronization, threads should perform a 
 * tag_lock_context(false) prior to invoking this function. 
 */
static int find_next_sibling( int direction, int statement_id )
{
   seekpos := _QROffset();
   start_line_no := start_seekpos := 0;
   scope_line_no := scope_seekpos := 0;
   type_name := "";
   tag_flags := SE_TAG_FLAG_NULL;
   tag_name := "";
   this_parent := 0;
   parent_statement := 0;
   num_tags := tag_get_num_of_statements();

   tag_get_detail2(VS_TAGDETAIL_statement_outer, statement_id, parent_statement );

   // search backward for suitable tag
   while (statement_id>0 && statement_id<=num_tags) {
      tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, statement_id, start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_statement_type, statement_id, type_name);
      tag_get_detail2(VS_TAGDETAIL_statement_flags, statement_id, tag_flags);
      tag_get_detail2(VS_TAGDETAIL_statement_name, statement_id, tag_name);

      if ((direction < 0 && start_seekpos < seekpos) ||
          (direction > 0 && start_seekpos > seekpos)) {

          tag_get_detail2(VS_TAGDETAIL_statement_outer, statement_id, this_parent );

         // Does this tag have the same parent
         // as the initial statement
         if ( /*tag_filter_type(0,filter_flags,type_name,tag_flags) &&*/
             //!(tag_flags & SE_TAG_FLAG_IGNORE) &&
             !(tag_flags & SE_TAG_FLAG_ANONYMOUS) && ( parent_statement == this_parent ) ) {
            return statement_id;
         }
      }
      statement_id += direction;
   }
   return -1;
}

static int do_next_prev_sibling( int direction, SETagFilterFlags filter_flags=SE_TAG_FILTER_ANY_PROCEDURE, _str quiet="" )
{
   // No support for this extension?
   if ( ! _istagging_supported() ) {
      if (quiet=="") {
         _message_box("Tagging is not supported for files of this extension.  Make sure support module is loaded.");
      }
      return(2);
   }

   // statements not supported?
   if (!_are_statements_supported()) {
      if (quiet=="") {
         _message_box("Statement tagging is not supported for files of this extension.");
      }
      return STRING_NOT_FOUND_RC;
   }

   // Update the complete context information and find nearest tag
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateStatements(true,true);

   int seekpos=(int)_QROffset();
   int statement_id = tag_nearest_statement(p_RLine);
   int num_tags = tag_get_num_of_statements();
   if (!statement_id) {
      statement_id = (direction>0)? 1:num_tags;
   }

   int starting_statement_id = statement_id;

//   int parent_statement=0;
//   tag_get_detail2(VS_TAGDETAIL_statement_outer, statement_id, parent_statement );

   // declarations
   start_line_no := start_seekpos := 0;
   scope_line_no := scope_seekpos := 0;
   end_line_no := end_seekpos := this_parent := 0;
   type_name := "";
   tag_flags := 0;
   tag_name := "";

   tag_get_detail2(VS_TAGDETAIL_statement_name, statement_id, tag_name);

   statement_id = find_next_sibling( direction, statement_id  );
   if ( statement_id > 0 ) {
      go_to_context_tag( statement_id  );
      return(0);
   }
/*
   // Could not find next/previous sibling so jump to the parent context
   // if it exists and go to it's first/last child
   tag_get_detail2(VS_TAGDETAIL_context_outer, starting_context_id, this_parent );

   if( this_parent > 0 ) {
      context_id = find_next_sibling( direction, this_parent );

      // If the next sibling context is valid and we are going foward then go to the
      // next context which should be the first child of this context
      if( ( context_id > 0 ) && ( direction > 0 ) && ( context_id+1 <= num_tags ) ) {
         add_tag( context_id+1 );
         return(0);
      }
   }
*/
   // no next/previous proc/tag
   return(1);
}

/**
 * Move to the next or previous tag in the current context
 * 
 * @param direction        1=next, -1=previous
 * @param filter_flags     SE_TAG_FITLER_* (default is for procs only) 
 * @param filter_by_types  use settings in {@link def_cb_filter_by_types}
 * 
 * @return 0 on success
 */
static int do_next_prev_tag(int direction, 
                            SETagFilterFlags filter_flags=SE_TAG_FILTER_ANY_PROCEDURE,
                            bool filter_by_types = false)
{
   // No support for this extension?
   if ( !_istagging_supported() ) {
      _message_box("Tagging not supported for files of this extension.  Make sure support module is loaded.");
      return(2);
   }

   // Update the complete context information and find nearest tag
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true);

   seekpos := _QROffset();
   context_id := tag_nearest_context(p_RLine, filter_flags, (direction < 0), filter_by_types);

   // If we could not find nearest context, try first or last item in context
   num_tags := tag_get_num_of_context();
   if (context_id <= 0) {
      context_id = (direction>0)? 1:num_tags;
   }

   // check if the current buffer is using the outline view
   useOutlineFilter := false;
   if (def_outline_view_enabled) {
      useOutlineFilter = isCurrentBufferSupportedForOutlineView();
   }

   // declarations
   tag_init_tag_browse_info(auto cm);
   start_seekpos := 0L;
   tag_flags := SE_TAG_FLAG_NULL;

   // search forward or backward for suitable tag
   while (context_id>0 && context_id<=num_tags) {

      // Skip tags that are statements
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, auto type_name);
      if( tag_tree_type_is_statement(type_name) ) {
         context_id+=direction;
         continue;
      }

      // check tag filters
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, tag_flags);
      if ((direction < 0 && start_seekpos < seekpos) ||
          (direction > 0 && start_seekpos > seekpos)) {
         if (tag_filter_type(SE_TAG_TYPE_NULL,filter_flags,type_name,(int)tag_flags) &&
             !(tag_flags & SE_TAG_FLAG_IGNORE) && 
             !(tag_flags & SE_TAG_FLAG_OUTLINE_HIDE) && 
             !(tag_flags & SE_TAG_FLAG_ANONYMOUS) &&
              (!useOutlineFilter || tag_tree_filter_outline(context_id))) {

            if (filter_by_types) {
               type_id := tag_get_type_id(type_name);
               if (type_id < def_cb_filter_by_types._length() && !def_cb_filter_by_types[type_id]) {
                  context_id+=direction;
                  continue;
               }
            }

            tag_get_context_browse_info(context_id, cm);

            // go to the tag location
            p_RLine = cm.scope_line_no;
            _GoToROffset(cm.seekpos);

            // make sure the symbols is not on a hidden line
            if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
               expand_line_level();
            }

            _UpdateContextWindow(true);
            _UpdateContext(true);
            _proc_found = tag_compose_tag_browse_info(cm);
            return(0);
         }
      }
      context_id+=direction;
   }

   // no next/previous proc/tag
   return(1);
}

// move to the next or previous statement in the current context
//    direction    -- 1=next, -1=previous
//    recursive    -- if false, gets next statement, skipping inner blocks
//    quiet        -- pass 1 to disable message boxes
//
static int do_next_prev_statement(int direction, bool recursive=true, _str quiet="")
{
   // No support for this extension?
   if ( ! _istagging_supported() ) {
      if (quiet=="") {
         _message_box("Tagging is not supported for files of this extension.  Make sure support module is loaded.");
      }
      return(2);
   }

   // statements not supported?
   if (!_are_statements_supported()) {
      if (quiet=="") {
         _message_box("Statement tagging is not supported for files of this extension.");
      }
      return STRING_NOT_FOUND_RC;
   }

   // Update the complete context information and find nearest tag
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateStatements(true,true);

   seekpos := _QROffset();
   statement_id := tag_nearest_statement(p_RLine, SE_TAG_FILTER_ANYTHING, (direction < 0));

   // If we could not find nearest statement, try first or last item in context
   num_statements := tag_get_num_of_statements();
   if (statement_id <= 0) {
      statement_id = (direction>0)? 1:num_statements;
   }

   // if not looking recursively, set starting point as end of current statement
   if (!recursive) {
      statement_start_seekpos := 0;
      tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, statement_id, statement_start_seekpos);
      if (direction < 0 && statement_start_seekpos < seekpos) {
         seekpos = statement_start_seekpos;
      }
      statement_end_seekpos := 0;
      tag_get_detail2(VS_TAGDETAIL_statement_end_seekpos, statement_id, statement_end_seekpos);
      if (direction > 0 && statement_end_seekpos > seekpos) {
         seekpos = statement_end_seekpos;
      }
   }

   // declarations
   tag_init_tag_browse_info(auto cm);
   start_seekpos := 0L;
   tag_flags := SE_TAG_FLAG_NULL;

   // search backward for suitable tag
   while (statement_id>0 && statement_id<=num_statements) {

      // Skip tags that are not statements
      tag_get_detail2(VS_TAGDETAIL_statement_type, statement_id, auto type_name);
      if( !tag_tree_type_is_statement(type_name) && (type_name != "lvar") ) {
         statement_id+=direction;
         continue;
      }

      // check tag filters
      tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, statement_id, start_seekpos);
      if ((direction < 0 && start_seekpos < seekpos) ||
          (direction > 0 && start_seekpos > seekpos)) {

         // go to the tag location
         tag_get_statement_browse_info(statement_id, cm);
         p_RLine = cm.scope_line_no;
         _GoToROffset(cm.seekpos);

         // make sure the symbols is not on a hidden line
         if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
            expand_line_level();
         }

         _UpdateContextWindow(true);
         _UpdateStatements(true,true);
         _proc_found = tag_compose_tag_browse_info(cm);
         return(0);
      }
      statement_id+=direction;
   }

   // no next/previous proc/tag
   return(1);
}

/**
 * Places cursor on next function heading.  If the <i>quiet</i> argument is
 * given and is not "", no error message is displayed.
 *
 * @return Returns 0 if successful.  Otherwise, a non-zero value is
 * returned.
 *
 * @see next_tag
 * @see prev_proc 
 * @see begin_proc 
 * @see end_proc
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command int next_proc(_str quiet="", _str flags="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   filter_flags := SE_TAG_FILTER_ANY_PROCEDURE;
   if (flags!="") {
      filter_flags = SE_TAG_FILTER_ANYTHING;
   }
   int status=do_next_prev_tag(1,filter_flags);
   if (quiet=="" && status) {
      message("No next procedure");
   }
   return(status);
}
/**
 * Places cursor on previous function heading.  If the <i>quiet</i>
 * argument is given and is not "", no error message is displayed.
 *
 * @return Returns 0 if successful.  Otherwise, a non-zero value is returned.
 *
 * @see prev_tag
 * @see next_proc
 * @see begin_proc 
 * @see end_proc
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command int prev_proc(_str quiet="", _str flags="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   filter_flags := SE_TAG_FILTER_ANY_PROCEDURE;
   if (flags!="") {
      filter_flags = SE_TAG_FILTER_ANYTHING;
   }
   int status=do_next_prev_tag(-1,filter_flags);
   if (quiet=="" && status) {
      message("No previous procedure");
   }
   return(status);
}
/**
 * Navigate to the beginning of the current procedure.
 *
 * @return 0 on success, nonzero on error.
 * 
 * @see next_proc
 * @see prev_proc
 * @see end_proc
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int begin_proc() name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true);

   context_id := tag_current_context();
   if (context_id == 0) {
      save_pos(auto p);
      _clex_skip_blanks();
      context_id = tag_current_context();
      restore_pos(p);
   }
   type_name := "";
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   }
   if (context_id > 0 && tag_tree_type_is_func(type_name)) {
      // go to the function end locaion
      start_seekpos := 0;
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
      _GoToROffset(start_seekpos);
      // make sure the symbols is not on a hidden line
      if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
         expand_line_level();
      }
   } else {
      msg := "Not in a function or procedure.";
      message(msg);
      return(1);
   }
   return(0);
}
/**
 * Navigate to end of current procedure.
 *
 * @return 0 on success, nonzero on error.
 * 
 * @see next_proc
 * @see prev_proc 
 * @see begin_proc 
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int end_proc() name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true);

   context_id := tag_current_context();
   if (context_id == 0) {
      save_pos(auto p);
      _clex_skip_blanks();
      context_id = tag_current_context();
      restore_pos(p);
   }
   type_name := "";
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   }
   if (context_id > 0 && tag_tree_type_is_func(type_name)) {
      // go to the function end locaion
      end_seekpos := 0;
      tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
      _GoToROffset(end_seekpos);
      // make sure the symbols is not on a hidden line
      if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
         expand_line_level();
      }
   } else {
      msg := "Not in a function or procedure.";
      message(msg);
      return(1);
   }
   return(0);
}

/**
 * Places cursor on next tag definition, skipping any tags filtered out by
 * the Defs tool window.  If the <i>quiet</i> argument is given an is not "", no error
 * message is displayed.
 *
 * @return Returns 0 if successful.  Otherwise, a non-zero value is
 * returned.
 *
 * @see next_proc
 * @see prev_proc
 * @see prev_tag 
 * @see begin_tag 
 * @see end_tag 
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command int next_tag(_str quiet="", _str flags="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   SETagFilterFlags filter_flags = def_proctree_flags;
   if (flags!="") {
      filter_flags = SE_TAG_FILTER_ANYTHING;
   }
   int status=do_next_prev_tag(1,filter_flags,filter_by_types:true);
   if (quiet=="" && status) {
      message("No next tag");
   }
   return(status);
}

/**
 * Navigate to the next statement in the current buffer.
 * <p>
 * This function is part of statement tagging and only works well
 * for languages that support statement-level tagging.
 * 
 * @see prev_statement 
 * @see begin_statement
 * @see end_statement
 * @see begin_statement_block 
 * @see end_statement_block
 * 
 * @return 0 on success, nonzero on error.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int next_statement(_str quiet="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int status=do_next_prev_statement(1,true,quiet);
   if (quiet=="" && status) {
      message("No next statement");
   }
   return(status);
}

/**
 * Navigate to the beginning of the current statement under the cursor.
 * <p>
 * This function is part of statement tagging and only works well
 * for languages that support statement-level tagging.
 * 
 * @return 0 on success, nonzero on error.
 * 
 * @see next_statement 
 * @see prev_statement
 * @see end_statement
 * @see begin_statement_block 
 * @see end_statement_block
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int begin_statement(_str quiet="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   if (!_are_statements_supported()) {
      if (quiet=="") {
         _message_box("Statement tagging is not supported for files of this extension.");
      }
      return STRING_NOT_FOUND_RC;
   }
   // Update the complete context information and find nearest tag
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateStatements(true,true);

   int seekpos=(int)_QROffset();
   //int statement_id = tag_nearest_context(p_RLine);
   int statement_id = tag_current_statement();
   int num_statements = tag_get_num_of_statements();
   if (!statement_id) {
      statement_id = tag_nearest_statement(p_RLine);
   }
   if (!statement_id) {
      statement_id = 1;
   }

   // get the statement start seek position
   statement_start_seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, statement_id, statement_start_seekpos);
   _GoToROffset(statement_start_seekpos);

   // make sure the symbols is not on a hidden line
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }

   return 0;
}

/**
 * Navigate to the end of the current statement under the cursor.
 * <p>
 * This function is part of statement tagging and only works well
 * for languages that support statement-level tagging.
 * 
 * @return 0 on success, nonzero on error.
 * 
 * @see next_statement 
 * @see prev_statement
 * @see begin_statement
 * @see begin_statement_block 
 * @see end_statement_block
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int end_statement(_str quiet="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   if (!_are_statements_supported()) {
      if (quiet=="") {
         _message_box("Statement tagging is not supported for files of this extension.");
      }
      return STRING_NOT_FOUND_RC;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // Update the complete context information and find nearest tag
   _UpdateStatements(true,true);

   int seekpos=(int)_QROffset();
   //int statement_id = tag_nearest_context(p_RLine);
   int statement_id = tag_current_statement();
   int num_statements = tag_get_num_of_statements();
   if (!statement_id) {
      statement_id = tag_nearest_statement(p_RLine);
   }
   if (!statement_id) {
      statement_id = num_statements;
   }

   // get the statement end seek position
   statement_end_seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_statement_end_seekpos, statement_id, statement_end_seekpos);
   _GoToROffset(statement_end_seekpos);

   // make sure the symbols is not on a hidden line
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }

   return 0;
}

/**
 * Navigate to the next sibling in the current buffer.
 * <p>
 * This function is part of statement tagging and only works well
 * for languages that support statement-level tagging.
 * 
 * @return 0 on success, nonzero on error.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int next_sibling(_str quiet="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int status=do_next_prev_sibling(1,SE_TAG_FILTER_ANY_PROCEDURE,quiet);
   if (quiet=="" && status) {
      message("No next sibling");
   }
   return(status);
}

/**
 * Places cursor on previous tag definition, skipping any tags filtered 
 * out by the Defs tool window.  If the <i>quiet</i> argument is 
 * given an is not "", no error message is displayed.
 *
 * @return 0 on success, nonzero on error.
 *
 * @see next_tag 
 * @see next_proc
 * @see prev_proc
 * @see begin_tag 
 * @see end_tag 
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 */
_command int prev_tag(_str quiet="", _str flags="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   SETagFilterFlags filter_flags = def_proctree_flags;
   if (flags!="") {
      filter_flags = SE_TAG_FILTER_ANYTHING;
   }
   int status=do_next_prev_tag(-1,filter_flags,filter_by_types:true);
   if (quiet=="" && status) {
      message("No previous tag");
   }
   return(status);
}

/**
 * Navigate to the previous statement in the current buffer.
 * <p>
 * This function is part of statement tagging and only works well
 * for languages that support statement-level tagging.
 * 
 * @return 0 on success, nonzero on error.
 *
 * @see next_statement 
 * @see begin_statement
 * @see end_statement
 * @see begin_statement_block 
 * @see end_statement_block
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int prev_statement(_str quiet="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int status=do_next_prev_statement(-1,true,quiet);
   if (quiet=="" && status) {
      message("No previous statement");
   }
   return(status);
}

/**
 * Navigate to the previous sibling in the current buffer.
 * <p>
 * This function is part of statement tagging and only works well
 * for languages that support statement-level tagging.
 * 
 * @return 0 on success, nonzero on error.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int prev_sibling(_str quiet="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int status=do_next_prev_sibling(-1,SE_TAG_FILTER_ANY_PROCEDURE,quiet);
   if (quiet=="" && status) {
      message("No previous sibling");
   }
   return(status);
}

/**
 * Navigate to the beginning of the current statement block.
 * <p>
 * This function is part of statement tagging and only works well
 * for languages that support statement-level tagging.
 * 
 * @return 0 on success, nonzero on error.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int begin_statement_block(_str quiet="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   status := goto_parent();
   if (status) {
      status = begin_statement(quiet);
   }
   if (status) {
      if (!quiet) {
         message("Not in a valid statement context");
      }
      return status;
   }

   return next_statement(quiet);
}

/**
 * Navigate to the end of the current statement block.
 * <p>
 * This function is part of statement tagging and only works well
 * for languages that support statement-level tagging.
 * 
 * @return 0 on success, nonzero on error.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int end_statement_block(_str quiet="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   status := goto_parent();
   if (status) {
      status = begin_statement(quiet);
   }
   if (status) {
      if (!quiet) {
         message("Not in a valid statement context");
      }
      return status;
   }

   status = next_statement(quiet);
   if (status) return status;

   while (next_sibling(quiet)==0);

   return end_statement(quiet);
}

/**
 * Navigate to end of current symbol.
 *
 * @return 0 on success, nonzero on error.
 *  
 * @see begin_tag
 * @see next_tag
 * @see prev_tag
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int end_tag() name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true);

   context_id := tag_current_context();
   if (context_id == 0) {
      save_pos(auto p);
      _clex_skip_blanks();
      context_id = tag_current_context();
      restore_pos(p);
   }
   if( context_id<=0 ) {
      msg := "";
      if( context_id==0 ) {
         msg="No current context.";
      } else {
         msg=get_message(context_id);
      }
      message(msg);
      return(1);
   }

   // get the statement start seek position
   end_seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
   _GoToROffset(end_seekpos);

   // make sure the symbols is not on a hidden line
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }
   return(0);
}

/**
 * Navigate to beginning of current symbol.
 *
 * @return 0 on success, nonzero on error.
 *  
 * @see end_tag 
 * @see next_tag
 * @see prev_tag
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int begin_tag() name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true);

   context_id := tag_current_context();
   if (context_id == 0) {
      save_pos(auto p);
      _clex_skip_blanks('-');
      context_id = tag_current_context();
      restore_pos(p);
   }
   if( context_id<=0 ) {
      msg := "";
      if( context_id==0 ) {
         msg="No current context.";
      } else {
         msg=get_message(context_id);
      }
      message(msg);
      return(1);
   }

   // get the statement start seek position
   start_seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
   _GoToROffset(start_seekpos);

   // make sure the symbols is not on a hidden line
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }
   return(0);
}

/**
 * Hides lines in the current buffer which are not part of the current function.
 * 
 * @see all
 * @see hide_code_block
 * @see hide_all_comments
 * @see preprocess
 * @see hide_selection
 * @see allnot
 * @see show_col1
 * @see show_all
 * @see _lineflags
 * @see selective_display
 * @see show_braces
 * @see show_indent
 * @see show_paragraphs
 * @see show_procs
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions, Selective_Display_Category
 * 
 */ 
_command void show_current_proc() name_info(',')
{
   // save current position
   save_pos(auto p);

   // turn off previous selective display
   show_all();

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true);

   // is there a tag under the cursor?
   restore_pos(p);
   this_context_id := tag_current_context(allow_outline_only:true);
   near_context_id := tag_nearest_context(p_RLine);
   if (this_context_id == near_context_id) {
      prev_tag();
      up(); _end_line();
      _clex_skip_blanks('-');
   } else {
      _clex_skip_blanks('-');
   }

   // hide all the lines between here and top of file
   if (p_line > 1) {
      select_line();
      top();
      down();
      hide_selection();
   }

   // now find end of function and hide all lines from
   // there to the bottom of the function
   restore_pos(p);
   end_tag();
   down();
   select_line();
   bottom();
   hide_selection();

   // restore cursor and we are done
   restore_pos(p);
}

/**
 * Close all currently open tag databases.
 *
 * @return 0 on success, <0 on error.
 *
 * @see tag_close_db
 * @see tag_create_db
 * @see tag_current_db
 * @see tag_current_version
 * @see tag_flush_db
 * @see tag_open_db
 * @see tag_read_db
 *
 * @categories Tagging_Functions
 */
_command tag_close_all() name_info(TAG_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   tag_close_all_db();
}

/**
 * Close the given tag database (or the current one).  This does not
 * technically <i>close</i> the database, it only switches it to being
 * open for read-only.  This is useful to clean up after writing to
 * a database.  Use {@link tag_close_db} to permanently close a database. 
 * <p>
 * Higher level than {@link tag_close_db}.  Closes the database for
 * write options, leaving it open for read options, caching
 * anything that was buffered.
 *
 * @param dbfilename   (optional) name of tag database, default is current
 *
 * @return 0 on success, <0 on error.
 *
 * @see tag_close_db()
 * @since 3.0
 * @deprecated Use {@link tag_close_db()} instead with caching options.
 *
 * @categories Tagging_Functions
 */
int tag_close_db2(_str dbfilename=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (dbfilename==null || dbfilename=="") {
      dbfilename=tag_current_db();
   }
   if (dbfilename=="") {
      return(0);
   }
   // Reopen this file for read access
   return(tag_read_db(dbfilename));
}
/**
 * Close the BSC database (references database) if it is currently open
 *
 * @return 0 on success, <0 on error.
 */
int tag_close_bsc()
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_isWindows()) {
      if (_win32s()!=1) {
         _str refs_database = refs_filename();
         if (refs_database != "" && "."lowcase(_get_extension(refs_database)) :== BSC_FILE_EXT) {
            //tag_read_db(refs_database);
            return tag_close_db(absolute(refs_database));
         }
      }
   }
   return 0;
}

/**
 * If this is a project tag file or Slick-C&reg; tags file, attempt to
 * retag occurrences found within the source file.  If this is not
 * the project tag file or if the source file is binary, then do nothing.
 *
 * @param ext   (optional) File extension to retag occurrences for.
 *
 * @return 0 on success, <0 on error
 */
int _retagOccurrences(_str lang=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // do we need to tag occurrences?
   if (!(tag_get_db_flags() & VS_DBFLAG_occurrences)) {
      return(0);
   }

   // binary file, then do not tag occurrences
   if (lang==null) {
      if (!_isEditorCtl() && p_window_id!=VSWID_HIDDEN) {
         return(0);
      }
      lang=p_LangId;
   }
   if (_QBinaryLoadTagsSupported(p_buf_name)) {
      return(0);
   }

   // prepare for update for current buffer
   int status = tag_occurrences_start(p_buf_name);
   if (status) {
      return status;
   }

   // save, search and file position, then call the retag function
   // find the extension specific or default list occurrences callback
   index := _FindLanguageCallbackIndex("_%s_list_occurrences",lang);
   save_pos(auto p);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   result := 0;
   if (index) {
      result = call_index(p_buf_name,0,0,index);
   } else {
      result = tag_list_occurrences(p_buf_name,null,true,0,0);
   }
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);

   // complete updating current buffer
   status = tag_occurrences_end(p_buf_name);
   if (status) {
      return status;
   }
   return result;
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (before defload).  Used to
// initialize the timer variable and window IDs.
//
definit()
{
   // IF editor is initializing from invocation
   if (arg(1)!='L') {
   }
   // Empty Eclipse mode macros
   eclipseExtMap._makeempty();
   gTagFilesThatCantBeRebuilt._makeempty();
   gTagCallList._makeempty();
   gtag_filelist_cache_updated=false;
   gTagFileListCache._makeempty();
}

_str class_match(_str name,bool find_first)
{
   // used to iterate through match set
   static int match_index;

   // temporaries
   cur_tag_name := cur_class_name := cur_type_name := "";
   case_sensitive := p_EmbeddedCaseSensitive;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // first time searching?
   if (find_first) {

      // find our current class context
      _UpdateContext(true);
      int context_id = tag_current_context();
      while (context_id > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_name, context_id, cur_tag_name);
         tag_get_detail2(VS_TAGDETAIL_context_class, context_id, cur_class_name);
         tag_get_detail2(VS_TAGDETAIL_context_type, context_id, cur_type_name);

         if (tag_tree_type_is_class(cur_type_name) || tag_tree_type_is_package(cur_type_name)) {
            cur_class_name = tag_join_class_name(cur_tag_name, cur_class_name,
                                                 null, case_sensitive);
            break;
         }
         cur_class_name="";
         tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
      }

      // find classes which match our requirements
      num_matches := 0;
      GCindex := _FindLanguageCallbackIndex("_%s_get_matches");
      if (GCindex) {
         num_matches = call_index(name,cur_class_name,
                                  SE_TAG_FILTER_STRUCT|SE_TAG_FILTER_UNION|SE_TAG_FILTER_INTERFACE,
                                  true, case_sensitive, GCindex);
      } else {
         num_matches = _do_default_get_matches(name,cur_class_name,
                                               SE_TAG_FILTER_STRUCT|SE_TAG_FILTER_UNION|SE_TAG_FILTER_INTERFACE,
                                               true, case_sensitive);
      }

      // did we find anything?
      if (num_matches <= 0) {
         return "";
      }

      // initialize iterator for match set
      match_index=0;
   }

   // loop until we find a class or package
   typeless tag_files = tags_filenamea(p_LangId);
   while (++match_index <= tag_get_num_of_matches()) {
      tag_get_detail2(VS_TAGDETAIL_match_name, match_index, cur_tag_name);
      tag_get_detail2(VS_TAGDETAIL_match_class, match_index, cur_class_name);
      tag_get_detail2(VS_TAGDETAIL_match_type, match_index, cur_type_name);
      if (tag_tree_type_is_class(cur_type_name) || tag_tree_type_is_package(cur_type_name)) {
         cur_class_name = tag_join_class_name(cur_tag_name, cur_class_name,
                                              tag_files, case_sensitive);
         return cur_class_name;
      }
   }

   // no more matches
   return "";
}

/**
 * Look in the current match set for for an exact match to
 * the symbol specified by 'cm'.
 * 
 * @param cm   symbol to search for
 * 
 * @return match ID > 0 on success, BT_RECORD_NOT_FOUND if not found.
 */
int tag_find_match(VS_TAG_BROWSE_INFO cm)
{
   // narrow the requirements in 'cm' down to core information
   cm.scope_line_no = 0;
   cm.scope_seekpos = 0;
   cm.name_line_no = 0;
   cm.name_seekpos = 0;
   cm.end_line_no = 0;
   cm.end_seekpos = 0;
   cm.exceptions = "";
   cm.template_args = "";
   cm.language = "";

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(false);
   
   // keep track if we found a math on this specific line number
   haveLineNumberMatch := false;
   indexOfLineNumberMatch :=0;

   for (;;) {

      // loop through all matches looking for an exact fit
      int i, n = tag_get_num_of_matches();
      for (i=1; i<=n; ++i) {
         tag_init_tag_browse_info(auto cx);
         tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, i, cx.seekpos);
         if (cm.seekpos > 0 && cx.seekpos != cm.seekpos) {
            continue;
         }
         tag_get_detail2(VS_TAGDETAIL_match_start_linenum, i, cx.line_no);
         if (cm.line_no > 0) {
            if (cx.line_no != cm.line_no) {
               continue;
            }
            if (!haveLineNumberMatch) {
               indexOfLineNumberMatch = i;
               haveLineNumberMatch = true;
            } else {
               indexOfLineNumberMatch = BT_RECORD_NOT_FOUND_RC;
            }
         }
         tag_get_match_info(i, cx);
         if (tag_browse_info_equal(cm,cx,p_EmbeddedCaseSensitive)) {
            return i;
         }
      }

      // no match, and no seekpos, give up
      if (cm.seekpos == 0 && cm.line_no == 0) {
         break;
      }

      // don't look for specific seek positions
      if (cm.seekpos > 0) {
         cm.seekpos = 0;
         continue;
      }

      // really desparate, don't look for specific line numbers
      if (cm.line_no > 0) {
         cm.line_no = 0;
      }
   }

   // did we find this tag on the specified line number?
   if (haveLineNumberMatch) {
      return indexOfLineNumberMatch;
   }

   // otherwise we don't know for sure which one to go to
   return BT_RECORD_NOT_FOUND_RC;
}

/**
 * Insert the tag match corresponding to the givem symbol
 * information structure into the current match set.
 * 
 * @param cm   (input) symbol information
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see tag_get_match_info
 * @see tag_insert_match
 */
int tag_insert_match_info(VS_TAG_BROWSE_INFO &cm)
{
   return tag_insert_match_browse_info(cm);
}

/**
 * Insert the tag match corresponding to the givem symbol
 * information structure into the current context.
 * 
 * @param cm   (input) symbol information
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see tag_get_match_info
 * @see tag_insert_match
 */
int tag_insert_context_info(VS_TAG_BROWSE_INFO &cm)
{
   return tag_insert_context_browse_info(0, cm);
}

/**
 * API function for inserting a tag entry with supporting info into
 * the given tree control.
 *
 * @param tree_wid      window ID of the tree control to insert into.
 * @param tree_index    parent tree node index to insert item under.
 * @param cm   (input)  symbol information
 * @param include_tab   append class name after signature if 1,
 *                      prepend class name with :: if 0.
 *                      See {@link tag_tree_make_caption} for further explanation.
 * @param force_leaf    if < 0, force leaf node, otherwise choose by type.
 *                      Normally "container" tag types, such as classes or structs 
 *                      are automatically inserted as non-leaf nodes.
 * @param tree_flags    flags passed to {@link _TreeAddItem}.
 * @param user_info     per-node user data for tree control 
 *
 * @return tree index of new item on success, <0 on error.
 * @see tag_tree_insert_tag
 * @see tag_get_match_info
 * 
 * @categories Tagging_Functions
 */
int tag_tree_insert_info(int tree_wid, int tree_index, 
                         VS_TAG_BROWSE_INFO &cm,
                         bool include_tab=false, 
                         int force_leaf=0, 
                         int tree_flags=TREE_ADD_AS_CHILD,
                         typeless user_info=null)
{
   return tag_tree_insert_tag(tree_wid, tree_index, 
                              (int)include_tab, 
                              force_leaf, tree_flags,
                              cm.member_name, cm.type_name,
                              cm.file_name, cm.line_no,
                              cm.class_name, (int)cm.flags, 
                              cm.arguments, user_info);
}

/**
 * Populate the given symbol struct with all the known information
 * corresponding to the given match ID in the current match set.
 * <p> 
 * For synchronization, macros should perform a 
 * tag_lock_matches(true) prior to invoking this function. 
 * 
 * @param match_id   match ID
 * @param cm         (output) symbol information
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see tag_get_match_browse_info
 *  
 * @categories Tagging_Functions
 *  
 */
int tag_get_match_info(int match_id, VS_TAG_BROWSE_INFO &cm)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(false);

   status := tag_get_match_browse_info(match_id, cm);
   if (cm.language == "" && _isEditorCtl() && _file_eq(cm.file_name,p_buf_name)) { 
      cm.language = p_LangId;
   }

   return status;
}

/**
 * Transfer all the symbol matches in the current match set to 
 * the given array. 
 *  
 * @param matches    (output) Array of symbol information 
 *  
 * @return 0 on success, <0 on error.
 * 
 * @see tag_get_match_browse_info
 * @see tag_get_match_info
 *  
 * @categories Tagging_Functions
 */
int tag_get_all_matches(VS_TAG_BROWSE_INFO (&matches)[])
{
   m := matches._length();
   n := tag_get_num_of_matches();
   for (i:=1; i<=n; i++) {
      status := tag_get_match_info(i, matches[m++]);
      if (status < 0) return status;
   }
   return 0;
}

/**
 * Populate the given symbol struct with all the known information
 * corresponding to the given local ID in the current locals set.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(false)
 * prior to invoking this function.
 * 
 * @param match_id   match ID
 * @param cm         (output) symbol information
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see tag_get_local
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 */
int tag_get_local_info(int local_id, VS_TAG_BROWSE_INFO &cm)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   status := tag_get_local_browse_info(local_id, cm);
   if (cm.language == "" && _isEditorCtl() && _file_eq(cm.file_name,p_buf_name)) { 
      cm.language = p_LangId;
   }

   return status;
}

/**
 * Find the derived (child) classes of a class_name.  
 * 
 * @param j 
 * @param class_name name of class (with package/namespace if it exists)
 * @param tag_db_name tag database containing the class
 * @param tag_files array of tag files
 * @param child_file_name 
 * @param child_line_no
 * @param been_there_done_that keep track of classes that have been
 *                             visited
 * @param visited         hash table of prior Context Tagging&reg; results
 * @param depth           current depth of inheritance
 * @param max_depth       max depth of inheritance to look through
 * 
 * @return int
 */
int tag_find_derived(/*int j, */_str class_name, 
                     _str tag_db_name, typeless& tag_files, 
                     _str child_file_name, int child_line_no, 
                     bool(&been_there_done_that):[], 
                     VS_TAG_RETURN_TYPE (&visited):[]=null,
                     int depth=0, int max_depth=1, int orig_depth=0)
{
   if (_chdebug) {
      isay(depth, "tag_find_derived: class_name="class_name);
      isay(depth, "tag_find_derived: orig_depth="orig_depth);
      isay(depth, "tag_find_derived: depth="depth);
      isay(depth, "tag_find_derived: max_depth="max_depth);
   }
   if (!_haveContextTagging()) {
      if (_chdebug) {
         isay(depth, "tag_find_derived: NO CONTEXT TAGGING");
      }
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (depth > max_depth) {
      if (_chdebug) {
         isay(depth, "tag_find_derived: PAST MAX DEPTH");
      }
      return 0;
   }
   if (been_there_done_that._indexin(class_name)) {
      if (_chdebug) {
         isay(depth, "tag_find_derived: BEEN THERE");
      }
      return 0;
   }
   been_there_done_that:[class_name]=true;

   if (cancel_form_wid()) {
      cancel_form_set_labels(cancel_form_wid(), "Searching: "class_name);
   } else {
      message("Searching: "class_name);
   }

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
      if (_chdebug) {
         isay(depth, "tag_find_derived: error opening tag database: "status);
      }
      return 0;
   }

   // need to parse out our outer class name
   outername := "";
   membername := "";
   tag_split_class_name(class_name, membername, outername);

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
         } else {
            status=tag_find_tag(membername, "union", outername);
            if (status==0) {
               tag_get_tag_browse_info(cm);
            }
         }
      }
   }
   type_name := cm.type_name;
   while (cm.flags & SE_TAG_FLAG_FORWARD) {
      status=tag_next_tag(membername,type_name,class_name);
      if (status<0) {
         break;
      }
      tag_get_tag_browse_info(cm);
   }
   tag_reset_find_tag();
/*   if (j<0) {
      file_name = child_file_name;
      line_no   = child_line_no;
   }*/

   // OK, we are now ready to insert
   pic_class := tag_get_bitmap_for_type(cm.type_id);
   if (depth > orig_depth && cm.member_name != "") {
      cm.tag_database = tag_db_name;
      cm.member_name = membername;
      cm.class_name  = outername;
      tag_insert_match_browse_info(cm);
   }
/*   int k;
   if (j < 0) {
      k = TREE_ROOT_INDEX;
      _TreeSetCaption(TREE_ROOT_INDEX, class_name);
      _TreeSetInfo(TREE_ROOT_INDEX, 1, pic_class, pic_class);
   } else {
      if (depth <= 0) {
         k = j;
      } else {
         int show_children = (depth < max_depth)? 1:0;
         k = _TreeAddItem(j, class_name, TREE_ADD_AS_CHILD, pic_class, pic_class, show_children);

      }
   }
   _str ucm = tag_db_name ';' class_name ';' type_name ';' file_name ';' line_no;
   _TreeSetUserInfo(k, ucm);*/

   if (cm.file_name=="") {
      if (_chdebug) {
         isay(depth, "tag_find_derived: NO FILE NAME");
      }
      return 0;
   }

   // stop here if we are at the depth limit
   if (depth > max_depth) {
      if (_chdebug) {
         isay(depth, "tag_find_derived: DEPTH EXCEEDED");
      }
      return 0;
   }

   // now insert derived classes
   orig_tag_file := tag_current_db();

   // get all the classes that could maybe possibly derive from this class
   _str candidates[];
   candidate_class := "";
   parents := "";
   status=tag_find_class(candidate_class);
   while (!status) {
      tag_get_inheritance(candidate_class,parents);
      if (length(parents) > 0 && pos("[;.:/]"membername"(<[^;]*>|);",';'parents';',1,'ir')) {
         candidates :+= candidate_class;
      }
      status=tag_next_class(candidate_class);
   }

   // show the cancel form
   cancel_wid := 0;
   if (depth==orig_depth && (max_depth > depth+1 || candidates._length() > CB_MAX_REFERENCES)) {
      cancel_wid = show_cancel_form("Finding Derived Classes...",null,true,true);
   }

   // verify that they derive directly from that class, then insert in tree
   tag_reset_find_class();
   foreach (auto i => candidate_class in candidates) {

      if (max_depth > depth+1 || candidates._length() > CB_MAX_INHERITANCE_DEPTH) {
         if (cancel_form_cancelled()) break;
         if (depth==orig_depth) {
            cancel_form_progress(cancel_form_wid(),i+1,candidates._length());
         }
      }

      tag_read_db(orig_tag_file);
      tag_find_class(auto dummy, candidate_class);
      if (_chdebug) {
         isay(depth, "tag_find_derived: candidate["i"]="candidate_class" class_name="class_name);
      }

      is_parent := tag_is_parent_class(class_name,
                                       candidate_class,
                                       tag_files,
                                       true,true,
                                       cm.file_name,
                                       visited,depth+1);
      if (!is_parent) {
         tag_get_inheritance(candidate_class, auto candidate_parents);
         tag_get_parents_of(candidate_class, candidate_parents, orig_tag_file, tag_files, cm.file_name, cm.line_no, depth+1, auto parents_array, visited, depth+2);
         class_name_no_colons := stranslate(class_name, VS_TAGSEPARATOR_package, VS_TAGSEPARATOR_class);
         is_parent = (_inarray(class_name, parents_array) || _inarray(class_name_no_colons, parents_array))? 1:0;
      }

      if (is_parent > 0) {
         tag_find_derived(candidate_class,
                          tag_db_name,tag_files,
                          cm.file_name,cm.line_no,
                          been_there_done_that,
                          visited, depth+1, max_depth, orig_depth);
      } else if (_chdebug) {
         isay(depth, "tag_find_derived: '"class_name"' is not a parent of '"candidate_class"'");
      }

   }
   if (depth==orig_depth && cancel_wid != 0) {
      close_cancel_form(cancel_form_wid());
   }

   tag_reset_find_class();
   tag_read_db(orig_tag_file);
   return 0;
}

/**
 * Populate the given symbol struct with all the known information
 * corresponding to the given context ID in the current context set.
 * <p> 
 * For synchronization, threads should perform a 
 * tag_lock_context(false) prior to invoking this function. 
 * 
 * @param context_id   context ID
 * @param cm           (output) symbol information
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see tag_get_context
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 */
int tag_get_context_info(int context_id, VS_TAG_BROWSE_INFO &cm)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   status := tag_get_context_browse_info(context_id, cm);
   if (cm.language == "" && _isEditorCtl() && _file_eq(cm.file_name,p_buf_name)) { 
      cm.language = p_LangId;
   }

   return status;
}

/**
 * Populate the given symbol struct with all the known information
 * corresponding to the given match ID in the current match set.
 * 
 * @param match_id   match ID
 * @param cm         (output) symbol information
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see tag_get_tag_browse_info
 *
 * @categories Tagging_Functions
 */
int tag_get_tag_info(VS_TAG_BROWSE_INFO &cm)
{
   return tag_get_tag_browse_info(cm);
}

/**
 * Shrink the given file name down to an abbreviated size small enough to 
 * fit on the current screen in a message box.   
 * 
 * @param file_name    File path/name to shrink
 * 
 * @return Elided file name 
 *  
 * @see _ShrinkFilename()
 */
_str _ShrinkFilenameToScreenWidth(_str file_name)
{
   x := y := 0; 
   _map_xy(p_window_id, 0, x, y);
   _GetVisibleScreenFromPoint(x,y,auto vx,auto vy,auto vwidth,auto vheight);
   return _ShrinkFilename(file_name, max(vwidth intdiv 4, min(800,vwidth)));
}

/**
 * Assuming the current control is an editor control, open the file
 * corresponding to the given symbol's file and go to it's believed
 * line number and seek position.
 * 
 * @param cm   symbol information
 * 
 * @return 0 on success, <0 on error
 */
int tag_edit_symbol(VS_TAG_BROWSE_INFO &cm)
{
   // just get the important part of the file name
   cm_file_name := cm.file_name;
   if (/*!file_exists(cm_file_name) &&*/ pos("\1", cm.file_name)) {
      parse cm.file_name with cm_file_name "\1" .;
   }

   // make sure that the symbol does not come from a DLL, Jar, or Class file
   if (_QBinaryLoadTagsSupported(cm_file_name)) {
      cm_file_name = _ShrinkFilenameToScreenWidth(cm_file_name);
      _message_box(nls("Can not go to symbol in a binary file: %s",cm_file_name));
      return COMMAND_CANCELLED_RC;
   }

   // make sure that the symbol has a file name
   if (cm_file_name == "") {
      _message_box(nls("Can not go to symbol '%s' with unspecified file",cm.member_name));
      return COMMAND_CANCELLED_RC;
   }

   // adjust the location of the symbol if necessary
   int status = tag_refine_symbol_match(cm);
   if (status == COMMAND_CANCELLED_RC) {
      return status;
   }

   // first try to open the by matching a current buffer
   view_id := p_window_id;
   status=edit('+b '_maybe_quote_filename(cm_file_name));
   if ( status ) {
      // now try to open the file normally
      status=edit(_maybe_quote_filename(cm_file_name));
      if ( status ) {
         if ( status==NEW_FILE_RC ) {
            quit();
            activate_window(view_id);
            status = FILE_NOT_FOUND_RC;
         }
      }
      clear_message();

      // Cancelled?
      if (status == COMMAND_CANCELLED_RC) {
         return status;
      }

      // handle error cases, except for NEW_FILE_RC and COMMAND_CANCELLED_RC, 
      // which are already handled
      if (status) {
         cm_file_name = _ShrinkFilenameToScreenWidth(cm_file_name);
         _message_box(nls("Could not open %s: %s",cm_file_name,get_message(status)));
         return status;
      }
   }
   // TBF:  Need to take this out for floating editor windows, but we will
   // problably need it on Unix to make sure the new editor window gets focus
   // after focus shifts to the tag_select_dialog().  We need to have a way
   // to restore focus back to the original tab group that had focus.
   //_mdi._set_foreground_window();

   // go to the specified seek position
   maybe_deselect(true);
   if (cm.line_no>=0) {
      p_RLine=cm.line_no;
      if (!isVisualStudioPlugin()) {
         //center_line();
         
         // calculate the number of lines in the function's header comment 
         int first_line=p_line, last_line=p_line;
         if (_do_default_get_tag_header_comments(first_line, last_line)) first_line=p_line;
         if (first_line > p_line) first_line = p_line;
   
         // now center the screen on the entire symbol
         if (cm.end_line_no > last_line) last_line = cm.end_line_no;
         center_region(first_line, last_line);
      }
      if (cm.seekpos > 0) {
         _GoToROffset(cm.seekpos);
      } else if (cm.seekpos == 0 && cm.line_no==1) {
         _GoToROffset(cm.seekpos);
      }
   }

   // make sure the symbols is not on a hidden line
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }

   // that's all folks
   return 0;
}

/**
 * Find tags in the current file which match the given symbol
 * 
 * @param cm   symbol information
 * 
 * @return number of matches found on success, <0 on error
 */
int tag_list_matches_in_context(VS_TAG_BROWSE_INFO cm,
                                VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   _UpdateContext(true);
   _UpdateLocals(true);

   num_matches := 0;
   _str no_tag_files[];
   no_tag_files._makeempty();

   tag_clear_matches();
   tag_list_any_symbols(0,0,cm.member_name,no_tag_files,
                        SE_TAG_FILTER_ANYTHING,
                        SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ALLOW_PRIVATE|SE_TAG_CONTEXT_ALLOW_PROTECTED|SE_TAG_CONTEXT_ALLOW_PACKAGE|SE_TAG_CONTEXT_ALLOW_FORWARD,
                        num_matches, def_tag_max_find_context_tags,
                        true, p_EmbeddedCaseSensitive,
                        visited, depth+1);

   if (tag_get_num_of_matches() == 0) {
      return BT_RECORD_NOT_FOUND_RC;
   }
   return num_matches;
}

int tag_select_symbol_match(VS_TAG_BROWSE_INFO &cm, 
                            bool addMatches=false,
                            VSCodeHelpFlags codehelpFlags=VSCODEHELPFLAG_NULL)
{
   // display dialog to select the appropriate tag match
   if ( _chdebug ) {
      tag_dump_matches("tag_select_symbol_match: IN");
   }
   match_id := tag_select_match(codehelpFlags);
   if (match_id == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }
   if (match_id == BT_RECORD_NOT_FOUND_RC) {
      return BT_RECORD_NOT_FOUND_RC;
   }
   // check for other error
   if (match_id < 0) {
      _message_box(get_message(match_id,""));
      return match_id;
   }

   // populate a tag info struct with the selected match
   tag_get_match_info(match_id, cm);
   if (cm.file_name == null || cm.file_name == "") {
      // error
      _message_box(nls("Can not jump to symbol '%s': No file name!",cm.member_name));
      return BT_RECORD_NOT_FOUND_RC;
   }

   // record the matches the user chose from
   if (addMatches) {
      push_tag_add_match(cm);
      n := tag_get_num_of_matches();
      for (i:=1; i<=n; ++i) {
         if (i==match_id) continue;
         tag_get_match_info(i, auto im);
         push_tag_add_match(im);
      }
   }

   // that's all folks
   return 0;
}

int tag_refine_symbol_match(VS_TAG_BROWSE_INFO &cm, 
                            bool quietlyChooseFirstMatch=false,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // make sure that the selected symbol does not come
   // from a DLL, Jar, or Class file
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      return 0;
   }

   // go to the file containing the chosen symbol
   orig_tag_database := cm.tag_database;
   buffer_already_exists := false;
   temp_view_id := orig_view_id := 0;
   status := _open_temp_view(cm.file_name, 
                             temp_view_id, orig_view_id, 
                             "", buffer_already_exists,
                             false, true /* select mode */);
   if (status) { // error
      return status;
   }

   // go to the expected line number
   p_RLine=cm.line_no;
   if (cm.seekpos > 0) {
      _GoToROffset(cm.seekpos);
   }

   tag_lock_context();
   tag_push_matches();
   status = tag_list_matches_in_context(cm, visited, depth+1);
   if (status < 0) {
      // error
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      tag_pop_matches();
      tag_unlock_context();
      return status;
   }

   // try to find an exact match to their selected tag (cm)
   // if not found, display dialog to choose among the available symbols
   match_id := tag_find_match(cm);
   if (match_id <= 0) {
      // do not prompt if there are multiple matches
      if (quietlyChooseFirstMatch && tag_get_num_of_matches() > 1) {
         match_id = 1;
      } else {
         match_id = tag_select_match();
      }
      if (match_id == COMMAND_CANCELLED_RC) {
         _delete_temp_view(temp_view_id);
         p_window_id=orig_view_id;
         tag_pop_matches();
         tag_unlock_context();
         return COMMAND_CANCELLED_RC;
      }
      if (match_id < 0) {
         _delete_temp_view(temp_view_id);
         p_window_id=orig_view_id;
         tag_pop_matches();
         tag_unlock_context();
         return BT_RECORD_NOT_FOUND_RC;
      }
   }

   // get the critical information about the selected match
   // and move the cursor to that location
   tag_get_match_info(match_id, cm);
   if (cm.tag_database == "") {
      cm.tag_database = orig_tag_database;
   }

   // clean up the temp view and restore the window id
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;
   tag_pop_matches();
   tag_unlock_context();
   return 0;
}

/**
 * Find the given symbol in the tag file and extract the line number as 
 * recorded in the tag database, which may be slightly different if the 
 * tag database is out-of-date.  If the symbol is found, the 
 * 'tagged_line_no' and 'tag_database' are set here. 
 * 
 * 
 * @param tag_files     list of tag files to search
 * @param cm            (reference) symbol information
 * 
 * @return 0 on success.
 */
int tag_find_tag_line_in_tag_files(_str (&tag_files)[], VS_TAG_BROWSE_INFO &cm)
{
   // do we already have a tagged_line_no
   if (cm.tagged_line_no > 0) {
      return 0;
   }

   // determine the line number of the symbol according to the tag database
   i := 0;
   tag_database := cm.tag_database;
   if (tag_database == null || tag_database == "") {
      if (tag_files == null) {
         tag_files = tags_filenamea(cm.language);
      }
      tag_database = next_tag_filea(tag_files,i,false,true);
   } else {
      status := tag_read_db(tag_database);
      if (status < 0) return status;
   }

   while (tag_database != "") {
      // search for exact match
      status := tag_find_tag(cm.member_name, 
                             cm.type_name, 
                             cm.class_name, 
                             cm.arguments, 
                             cm.file_name);
      while (status == 0) {
         tag_get_tag_browse_info(auto tag_cm);
         if (cm.arguments     == tag_cm.arguments &&
             cm.template_args == tag_cm.template_args) {
            cm.tag_database   = tag_database;
            cm.tagged_line_no = tag_cm.line_no;
            tag_reset_find_tag();
            return 0;
         }
         status = tag_next_tag(cm.member_name, 
                               cm.type_name, 
                               cm.class_name, 
                               cm.arguments, 
                               cm.file_name);
      }
      tag_reset_find_tag();

      // if we already knew which tag database to look at, we are done
      if (tag_database != null && tag_database != "") {
         break;
      }

      // try the next tag file
      tag_database = next_tag_filea(tag_files,i,false,true);
   }

   return VSCODEHELPRC_NO_SYMBOLS_FOUND;
}

/**
 * @deprecated Use {@link tag_compose_tag_brose_info()} instead.
 */
_str tag_tree_compose_tag_info(VS_TAG_BROWSE_INFO cm)
{
   return tag_compose_tag_browse_info(cm);
}
/**
 * @deprecated Use {@link tag_decompose_tag_brose_info()} instead.
 */
void tag_tree_decompose_tag_info(_str taginfo, VS_TAG_BROWSE_INFO &cm)
{
   tag_decompose_tag_browse_info(taginfo, cm);
}

/**
 * @return
 * Return the documentation for a command.
 * 
 * For best results the documentation should be in javadoc format.
 * 
 * @param tagName   Name of Slick-C comamnd to extract comments for.
 */
_str tag_command_html_documentation (_str tagName)
{
   documentation := "";
   if (tagName != '-') {
      tagName = stranslate(tagName, "_", "-");
   }
   //'last_recorded_macro's aren't like other commands. Bail out.
   if (substr(tagName, 1, 19) == "last_recorded_macro") {
      return "";
   }
   tagIndex := find_index(tagName, COMMAND_TYPE);

   tfindex := 0;
   moduleIndex := 0;
   moduleName := "";
   extension := "";
   fileName := "";

   //Get the file name that the proc is in.
   _e_MaybeBuildTagFile(tfindex,true,true);
   moduleIndex = index_callable(tagIndex);
   moduleName = name_name(moduleIndex); //The .ex file the _command is in.
   extension = substr(moduleName, lastpos(".", moduleName)+1);
   moduleName = substr(moduleName, 1, length(moduleName)-1);
   fileName = path_search(moduleName, "VSLICKMACROS");

   //If we couldn't find the file name in the usual way, try another method.
   if ((fileName == "") && !strieq(extension, "DLL")) {
      tagfiles := "";
      tagsMatching := -1;
      tagfiles = tags_filename("e", false);
      tagsMatching = find_tag_matches(tagfiles, tagName, false, def_tag_max_function_help_protos);
      tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:false, 
                                          filterDuplicateGlobalVars:false, 
                                          filterDuplicateClasses:false, 
                                          filterAllImports:false);
      tag_init_tag_browse_info(auto cm);
      int i;
      for (i = 0; i <= tag_get_num_of_matches(); ++i) {
         tag_get_match_info(i, cm);
         if (cm.type_name == "func") {
            fileName = cm.file_name;
            break;
         }
      }
   }

   //Get the line number the proc is on
   status := 0;
   tempWID := 0;
   origWID := 0;
   bufferExists := false;
   status = _open_temp_view(fileName, tempWID, origWID, "", bufferExists, false,
                            true);
   if (status) {
      return "";
   }
   langId := p_LangId;
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   lineNumber := 0;
   contextID := tag_find_context_iterator(tagName, true, true);
   if (contextID < 0) {
      _delete_temp_view(tempWID);
      activate_window(origWID);
      return "";
   }
   tag_get_detail2(VS_TAGDETAIL_context_line, contextID, lineNumber);
   
   //Use all that information to get comments:
   status = _ExtractTagComments2(auto commentFlags, auto comments, 2000, tagName, fileName, lineNumber);
   _delete_temp_view(tempWID);
   activate_window(origWID);

   if (status) {
      return "";
   }

   _make_html_comments(comments, commentFlags, "", "", true, langId);

   return comments;
}


int adjustTagfilePaths(_str tagfile, 
                       _str origPath, 
                       _str newPath,
                       int slickcProgressCallback=0,
                       int startPercent=0,
                       int finalPercent=100)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // open the database for business
   status := tag_open_db(tagfile);
   if (status < 0) {
      return status;
   }

   tempViewID := 0;
   origViewID := _create_temp_view(tempViewID);

   // get the files from the database
   numFiles := 0;
   tag_get_detail(VS_TAGDETAIL_num_files, numFiles);
   if (numFiles==0) numFiles=1;

   filename := "";
   includename := "";
   status = tag_find_file(filename);
   while (!status) {
      insert_line(filename);
      status = tag_find_include_file(filename, includename);
      while (!status) {
         insert_line(includename);
         status = tag_next_include_file(filename, includename);
      }
      status = tag_next_file(filename);
   }
   tag_reset_find_file();

   // reset status after the BT_RECORD_NOT_FOUND_RC that
   // ended the previous loop
   status = 0;

   // adjust all the paths
   top(); up();
   while (!down()) {
      origFilename := "";
      get_line(origFilename);

      // make orig filename relative to remote db and then absolute to local db
      newFilename := relative(origFilename, origPath);
      relFilename := newFilename;
      newFilename = absolute(newFilename, newPath);

      // rename the file in the database
      tag_rename_file(origFilename, newFilename);

      //static int countFiles;
      //if (++countFiles < 10) {
      //   say("adjustTagfilePaths H"__LINE__": origFilename="origFilename);
      //   say("adjustTagfilePaths H"__LINE__": relFilename="relFilename);
      //   say("adjustTagfilePaths H"__LINE__": newFilename="newFilename);
      //}

      // update progress
      if (slickcProgressCallback && (p_line % 100) == 0) {
         call_index(startPercent + (p_line*100 intdiv numFiles)*(finalPercent-startPercent) intdiv 100, slickcProgressCallback);
         p_window_id=tempViewID;
      }
   }

   // cleanup the temp view
   p_window_id = origViewID;
   _delete_temp_view(tempViewID);

   return status;
}

/**
 * @deprecated 
 * This command is no longer supported.  Use tag_dump_context() instead. 
 */
_command void dump_tag_debug_info() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   _UpdateStatements(true, true);
   tag_dump_context();
}

/**
 *
 */
_command int check_autoupdated_tagfiles(_str workspaceName = _workspace_filename) name_info(FILE_ARG'*,'VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   status := 0;

   if(workspaceName == "") {
      return 0;
   }

   handle := -1;
   if(workspaceName == _workspace_filename) {
      handle = gWorkspaceHandle;
   } else {
      handle = _xmlcfg_open(workspaceName, status);
      if(handle < 0) return status;
   }

   // Make sure the workspace tag file directory exists
   tagFileDir := VSEWorkspaceTagFileDir(workspaceName);
   if (!isdirectory(tagFileDir)) {
      mkdir(tagFileDir);
   }

   // get list of auto updated tagfiles for this workspace
   int tagfileNodes[] = null;
   _WorkspaceGet_TagFileNodes(handle, tagfileNodes);

   // if this workspace has no auto updated tagfiles then there is nothing to do
   if(tagfileNodes._length() > 0) {
      // check to see if any of the tag files are out dated
      message("Checking auto-updated tag files...");
      mou_hour_glass(true);
      int i;
      int outdatedTagfileNodes[] = null;
      for(i = 0; i < tagfileNodes._length(); i++) {
         int tagfileNode = tagfileNodes[i];

         // get the filename and remote filename
         remoteFilename := _AbsoluteToWorkspace(_xmlcfg_get_attribute(handle, tagfileNode, "AutoUpdateFrom"), workspaceName);
         filename := _xmlcfg_get_attribute(handle, tagfileNode, "File");
         if (filename == "") filename = _strip_filename(remoteFilename,'P');
         if (remoteFilename != "") {
            filename = absolute(filename, tagFileDir);
         } else {
            filename = _AbsoluteToWorkspace(filename);
         }

         // check to see if it is out dated
         if (isAutoUpdatedTagfileOutdated(filename, remoteFilename, workspaceName)) {
            outdatedTagfileNodes[outdatedTagfileNodes._length()] = tagfileNode;
         }
      }

      // if there are any outdated files, show the form and update them
      if(outdatedTagfileNodes._length() > 0) {
         message("Updating auto-updated tag files...");

         // show the form
         created_my_own_form := false;
         wid := _find_formobj("_tag_progress_form", "N");
         if (wid <= 0) {
            created_my_own_form = true;
            wid = show("-xy _tag_progress_form");
         }

         _nocheck _control ctlLogTree;
         _nocheck _control ctlProgress;

         // setup columns
         tree_index := TREE_ROOT_INDEX;
         if (created_my_own_form) {
            wid.p_caption = "Auto-Update Tag Files";
            wid.ctlLogTree._TreeSetColButtonInfo(0, 2500, TREE_BUTTON_PUSHBUTTON, 0, "Workspace");
            wid.ctlLogTree._TreeSetColButtonInfo(1, wid.ctlLogTree.p_width - 2500, 0, 0, "Update From");
         } else {
            tree_index = wid.ctlLogTree._TreeCurIndex();
         }

         // put the list of tag files into the form
         for(i = 0; i < outdatedTagfileNodes._length(); i++) {
            int tagfileNode = outdatedTagfileNodes[i];

            // get the filename and remote filename
            remoteFilename := _AbsoluteToWorkspace(_xmlcfg_get_attribute(handle, tagfileNode, "AutoUpdateFrom"), workspaceName);
            filename := _xmlcfg_get_attribute(handle, tagfileNode, "File");
            if (filename == "") filename = _strip_filename(remoteFilename,'P');
            if (remoteFilename != "") {
               filename = absolute(filename, tagFileDir);
            } else {
               filename = _AbsoluteToWorkspace(filename);
            }

            tagFileIndex := wid.ctlLogTree._TreeAddItem(tree_index, filename "\t" remoteFilename, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
            wid.ctlLogTree._TreeSetCheckable(tagFileIndex, 1, 0);
            wid.ctlLogTree._TreeSetCheckState(tagFileIndex, TCB_UNCHECKED);
         }
         wid.refresh("W");
         node := wid.ctlLogTree._TreeGetFirstChildIndex(tree_index);

         // check each workspace
         for(i = 0; i < outdatedTagfileNodes._length(); i++) {
            wid.ctlLogTree._TreeSetCurIndex(node);
            wid.ctlLogTree._TreeRefresh();
            wid.ctlProgress.p_value = 0;

            int tagfileNode = outdatedTagfileNodes[i];

            // get the filename and remote filename
            remoteFilename := _AbsoluteToWorkspace(_xmlcfg_get_attribute(handle, tagfileNode, "AutoUpdateFrom"), workspaceName);
            filename := _xmlcfg_get_attribute(handle, tagfileNode, "File");
            if (filename == "") filename = _strip_filename(remoteFilename,'P');
            if (remoteFilename != "") {
               filename = absolute(filename, tagFileDir);
            } else {
               filename = _AbsoluteToWorkspace(filename);
            }

            // call for the update
            status = _updateAutoUpdatedTagfile(filename, remoteFilename, workspaceName, wid);
            //if(status) break;

            // show the checkmark and step next
            wid.ctlLogTree._TreeSetCheckState(node, TCB_CHECKED);
            wid.ctlLogTree._TreeRefresh();
            node = wid.ctlLogTree._TreeGetNextSiblingIndex(node);
         }

         // close the form
         if (created_my_own_form) {
            wid._delete_window();
         }
      }

      if(cancelTagProgressFormGlobal) {
         message("Tag file update cancelled");
      } else {
         message("All auto-updated tag files up-to-date");
      }
      mou_set_pointer(0);
   }

   // close the workspace if it was opened in this function
   if(workspaceName != _workspace_filename) {
      _xmlcfg_close(handle);
   }

   return status;
}


/**
 * Check to see if an auto-updated tag file is out of date
 */
static bool isAutoUpdatedTagfileOutdated(_str localFilename, _str remoteFilename, _str workspaceName = _workspace_filename)
{
   status := 0;

   // make sure both files are absoluted to the workspace
   localFilename = _AbsoluteToWorkspace(localFilename, workspaceName);
   remoteFilename = _AbsoluteToWorkspace(remoteFilename, workspaceName);

   // get the date of the remote file
   remoteDate := _file_date(remoteFilename, "B");
   if (remoteDate == "" || remoteDate == 0) {
      // if remote not found then update cannot be performed so return false
      return false;
   }

   // get the date of the local file
   localDate := _file_date(localFilename, "B");
   if (localDate == "" || localDate <= remoteDate) {
      return true;
   }

   return false;
}

static const COPYBUFSIZE= 64 * 1024 - 1;
/**
 * Replace the local auto-updated tag file with the one from the remote location
 */
int _updateAutoUpdatedTagfile(_str localFilename, _str remoteFilename, _str workspaceName=_workspace_filename, int progress_form_wid=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // make sure both files are absoluted to the workspace
   status := 0;
   localFilename = _AbsoluteToWorkspace(localFilename, workspaceName);
   remoteFilename = _AbsoluteToWorkspace(remoteFilename, workspaceName);
   shrunkLocalFilename  := _ShrinkFilenameToScreenWidth(localFilename);
   shrunkRemoteFilename := _AbsoluteToWorkspace(remoteFilename, workspaceName);

   // figure out temp name for copy
   tempLocalFilename :=  localFilename :+ ".tmp";
   if(file_exists(tempLocalFilename)) {
      // delete it to make room
      status = delete_file(tempLocalFilename);
      if (status) {
         _message_box(nls("Failed to auto update tag file '%s1'.  Remove previous temp file failed with error: %s2 (%s3).", shrunkLocalFilename, get_message(status), status));
         return status;
      }
   }

   // get the size of the remote file
   line := file_match("-P +V " _maybe_quote_filename(remoteFilename), 1);
   remoteFileSize := 0;
   remoteSizeStr := substr(line, DIR_SIZE_COL, DIR_SIZE_WIDTH);
   if(isinteger(remoteSizeStr)) {
      // this should *always* be true
      remoteFileSize = (int)remoteSizeStr;
   }

   // open the remote file
   remoteHandle := _FileOpen(remoteFilename, 0);
   if (remoteHandle < 0) {
      _message_box(nls("Failed to auto update tag file '%s1'.  Remote file open failed with error: %s2 (%s3).", shrunkLocalFilename, get_message(remoteHandle), remoteHandle));
      return remoteHandle;
   }

   // open the local temp file
   localHandle := _FileOpen(tempLocalFilename, 1);
   if (localHandle < 0) {
      _message_box(nls("Failed to auto update tag file '%s1'.  Local temp file open failed with error: %s2 (%s3).", shrunkLocalFilename, get_message(localHandle), localHandle));

      // close remote file
      _FileClose(remoteHandle);
      return localHandle;
   }

   // setup buffer
   buffer := _BlobAlloc(COPYBUFSIZE); // 64k is largest allowed blob
   if (buffer < 0) {
      _message_box(nls("Failed to auto update tag file '%s1'.  Buffer allocation failed with error: %s2 (%s3).", shrunkLocalFilename, get_message(buffer), buffer));
      // close files
      _FileClose(remoteHandle);
      _FileClose(localHandle);
      return buffer;
   }

   // do the copy
   iterations := 0;
   totalBytesRead := 0;
   cancel_form_set_labels(progress_form_wid, null, "Copying tag file contents");
   while(totalBytesRead < remoteFileSize) {
      // call the progress callback
      if ((iterations++ % 50) == 0) {
         int cancelPressed = tagProgressCallback(totalBytesRead * 50 intdiv remoteFileSize);
         if(cancelPressed) {
            // user requested the loop be broken so clean everything up

            // free the buffer
            _BlobFree(buffer);

            // close both files
            _FileClose(remoteHandle);
            _FileClose(localHandle);

            // delete the temp tagfile
            delete_file(tempLocalFilename);
            return status;
         }
      }

      // clear the buffer
      _BlobInit(buffer);

      // read the next chunk
      int bytesRead = _BlobReadFromFile(buffer, remoteHandle, COPYBUFSIZE);
      if (bytesRead < 0) {
         // free the buffer
         _BlobFree(buffer);

         // close both files
         _FileClose(remoteHandle);
         _FileClose(localHandle);

         _message_box(nls("Failed to auto update tag file '%s1'.  Read remote file failed with error: %s2 (%s3).", shrunkLocalFilename, get_message(bytesRead), bytesRead));
         return bytesRead;
      }
      totalBytesRead = totalBytesRead + bytesRead;

      // write the next chunk.  this must be done in a loop in case the full
      // amount that was requested was not written
      totalWritten := 0;
      while (totalWritten < bytesRead) {
         _BlobSetOffset(buffer, totalWritten, 0);
         int bytesWritten = _BlobWriteToFile(buffer, localHandle, bytesRead);
         if (bytesWritten < 0) {
            _message_box(nls("Failed to auto update tag file '%s1'.  Write local temp file failed with error: %s2 (%s3).", shrunkLocalFilename, get_message(bytesWritten), bytesWritten));

            // free the buffer
            _BlobFree(buffer);

            // close both files
            _FileClose(remoteHandle);
            _FileClose(localHandle);

            return bytesWritten;
         } else {
            totalWritten = totalWritten + bytesWritten;
         }
      }
   }

   // free the buffer
   _BlobFree(buffer);

   // close both files
   _FileClose(remoteHandle);
   _FileClose(localHandle);

   // close the local tagfile
   status = tag_close_db(localFilename);
   switch(status) {
      case BT_SESSION_NOT_FOUND_RC:
      case 0:
         status = 0;
         break;

      default:
         _message_box(nls("Failed to auto update tag file '%s1'.  Close local tag file failed with error: %s2 (%s3).", shrunkLocalFilename, get_message(status), status));
         return status;
   }

   // make sure local tagfile is not read only
   if (_isUnix()) {
      chmod("\"u+w g+w o+w\" " _maybe_quote_filename(localFilename));
   } else {
      chmod("-r " _maybe_quote_filename(localFilename));
   }

   // delete the local tagfile
   status = delete_file(localFilename);
   switch(status) {
      case FILE_NOT_FOUND_RC:
      case 0:
         status = 0;
         break;

      default:
         _message_box(nls("Failed to auto update tag file '%s1'.  Delete local tag file failed with error: %s2 (%s3).", shrunkLocalFilename, get_message(status), status));
         return status;
   }

   // rename the temp local file
   status = _file_move(localFilename, tempLocalFilename);
   if (status) {
      _message_box(nls("Failed to auto update tag file '%s1'.  Rename temp tag file failed with error: %s2 (%s3).", shrunkLocalFilename, get_message(status), status));
      return status;
   }

   // adjust the paths
   progress_index := find_index("tagProgressCallback", PROC_TYPE);
   //say("_updateAutoUpdatedTagfile H"__LINE__": localFilename="localFilename);
   //say("_updateAutoUpdatedTagfile H"__LINE__": remoteFilename="remoteFilename);
   //say("_updateAutoUpdatedTagfile H"__LINE__": tempLocalFilename="tempLocalFilename);
   cancel_form_set_labels(progress_form_wid, null, "Adjusting source file paths");
   status = adjustTagfilePaths(localFilename, 
                               _strip_filename(localFilename, "N"), 
                               _strip_filename(remoteFilename, "N"),
                               progress_index, 50, 100);
   if (status == BT_CANNOT_WRITE_OBSOLETE_VERSION_RC) {
      cancel_form_set_labels(progress_form_wid, null, "The source tag file was built with earlier version, updating database format.\nThe source tag file should be rebuilt with vsmktags.");
      status = tag_update_tag_file_to_latest_version(remoteFilename, localFilename, progress_index, 50, 100);
   } else {
      cancel_form_set_labels(progress_form_wid, null, "");
   }
   if (status) {
      _message_box(nls("Failed to auto update tag file '%s1'.  Rename temp tag file failed with error: %s2 (%s3).", shrunkLocalFilename, get_message(status), status));
      return status;
   }

   // make the local file read only
   if (_isUnix()) {
      chmod("\"u+r u-w u-x g+r g-w g-x o+r o-w o-x\" " _maybe_quote_filename(localFilename));
   } else {
      chmod("+r " _maybe_quote_filename(localFilename));
   }

   return status;
}

/** 
 * Find out what tag file and file the given parent class comes from.
 */
int find_location_of_parent_class(_str tag_database, _str class_name, 
                                  _str &file_name, int &line_no, _str &type_name)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // save the original database name
   status := 0;
   orig_database := tag_current_db();
   if (tag_database != "" && tag_database != orig_database) {
      status = tag_read_db(tag_database);
      if (status < 0) {
         return status;
      }
   }

   // need to parse out our outer class name
   tag_init_tag_browse_info(auto cm);
   tag_split_class_name(class_name, cm.member_name, cm.class_name);

   // try to look up file_name and type_name for class
   tag_init_tag_browse_info(auto found_cm);
   status=tag_find_tag(cm.member_name, "class", cm.class_name);
   if (status==0) {
      tag_get_tag_browse_info(found_cm);
   } else {
      status=tag_find_tag(cm.member_name, "struct", cm.class_name);
      if (status==0) {
         tag_get_tag_browse_info(found_cm);
      } else {
         status=tag_find_tag(cm.member_name, "interface", cm.class_name);
         if (status==0) {
            tag_get_tag_browse_info(found_cm);
         }
      }
   }
   file_name = found_cm.file_name;
   line_no   = found_cm.line_no;
   type_name = found_cm.type_name;

   // broaden scope of search for class name
   if (status != 0 && _isEditorCtl()) {
      VS_TAG_RETURN_TYPE rt;
      tag_return_type_init(rt);
      VS_TAG_RETURN_TYPE visited:[];
      _str errorArgs[];
      lang := _isEditorCtl()? p_LangId : "";
      tag_files := tags_filenamea();
      status = _Embeddedparse_return_type(errorArgs, tag_files, cm.member_name, cm.class_name, file_name, class_name, _LanguageInheritsFrom("java") || _LanguageInheritsFrom("cs"), rt, visited);
      if (status == 0) {
         file_name = rt.filename;
         line_no   = rt.line_number;
         if (rt.taginfo != null || rt.taginfo != "") {
            tag_decompose_tag_browse_info(rt.taginfo, cm);
            type_name = cm.type_name;
         }
      } else {
         type_name = "class";
         return BT_RECORD_NOT_FOUND_RC;
      }
   }

   // skip forward declarations
   while (!status && (found_cm.flags & SE_TAG_FLAG_FORWARD)) {
      status=tag_next_tag(cm.member_name, type_name, cm.class_name);
      if (status<0) {
         break;
      }
      tag_get_tag_browse_info(found_cm);
      file_name = found_cm.file_name;
      line_no   = found_cm.line_no;
   }
   tag_reset_find_tag();

   // restore the original database
   if (tag_database != "" && tag_database != orig_database) {
      tag_read_db(orig_database);
   }
   return status;
}

/**
 * Given a browse info describing a class find all the the parents all the way up the inheritance chain and fill
 * in an array with the names of all the parent classes. The context info parents field only contains the immediate parents so that is why this method
 * is needed.
 * 
 * @param cm                  class/interface/struct to get parent information about.
 * @param tag_files           tag_files to use in building the list
 * @param parents_array       [output]parent names will be added to the end of the array passed in.
 * @param visited             (in/out)keeps track of context tagging calculates that have already been done. 
 * @param depth               Used to keep track off the recursive search depth for this call. Set to 0 on initial call.
 * @param max_depth           stop search when 'depth' reaches this level 
 */
int tag_info_get_parents_of(VS_TAG_BROWSE_INFO cm, 
                            typeless tag_files, 
                            _str (&parents_array)[],
                            VS_TAG_RETURN_TYPE (&visited):[]=null, 
                            int depth=0, int max_depth=CB_MAX_INHERITANCE_DEPTH)
{
   return tag_get_parents_of(cm.member_name, cm.class_parents, 
                             cm.tag_database, tag_files, 
                             cm.file_name, cm.line_no, 
                             depth, parents_array, 
                             visited, max_depth);
}

/**
 * 
 * Take information about a class and fill in an array with the names of all the parent classes all the way up the
 * inheritance chain. The context info parents field only contains the immediate parents so that is why this method
 * is needed.
 * 
 * @param class_name          class/interface/struct name to get parent information about
 * @param class_parents       the immediate parents of the class we are trying to get full information about.
 * @param tag_db_name         name of the tagdatabse that this class belongs to.
 * @param tag_files           list of tag_files that should be searched when looking for parents of this class
 * @param child_file_name     The file that contains the definition for the class/interface/struct we are trying 
 *                            to get the parents of. 
 * @param child_line_no       The line number in the file that the definition for the class/interface/struct we are
 *                            trying to get the parents of.
 * @param depth               Used to keep track off the recursive search depth for this call. Set to 0 on initial call.
 * @param parents_array       (out)List of names of all the parents of this class not just immediate. 
 * @param visited             (in/out)keeps track of context tagging calculates that have already been done. 
 * @param max_depth           stop search when 'depth' reaches this level 
 * 
 * @return 0 on success, &lt;0 on error.
 */
int tag_get_parents_of(_str class_name, _str class_parents,
                       _str tag_db_name, typeless &tag_files,
                       _str child_file_name, int child_line_no, 
                       int depth, _str (&parents_array)[],
                       VS_TAG_RETURN_TYPE (&visited):[]=null,
                       int max_depth=CB_MAX_INHERITANCE_DEPTH)
{
   if (_chdebug) {
      isay(depth, "tag_get_parents_of(class_name="class_name", parents="class_parents")");
   }
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (depth > max_depth) {
      return 0;
   }

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
      return 0;
   }

   // get are parent classes and the tag files they come from
   result := 0;
   tag_dbs := "";
   parents := cb_get_normalized_inheritance(class_name, 
                                            tag_dbs, tag_files, 
                                            false, class_parents, 
                                            child_file_name, 
                                            auto ptypes,
                                            includeTemplateParameters:false,
                                            visited, depth+1);

   // make sure the right tag file is still open
   status = tag_read_db(tag_db_name);
   if (status < 0) {
      return 0;
   }

   file_name := "";
   type_name := "";
   line_no := 0;
   status = find_location_of_parent_class(tag_db_name, class_name, file_name, line_no, type_name);
   if (status < 0) {
      file_name = child_file_name;
      line_no   = child_line_no;
   }

   // recursively process parent classes
   orig_tag_file := tag_current_db();
   while (parents != "") {
      parse parents with auto p1 ";" parents;
      parse tag_dbs with auto t1 ";" tag_dbs;
      parse ptypes  with auto tn ";" ptypes;
      parse p1 with p1 "<" .;
      find_location_of_parent_class(t1,p1,file_name,line_no,tn);
      parents_array :+= p1;
      if (depth+1 < max_depth) {
         result = tag_get_parents_of(p1, "", t1, tag_files, file_name, line_no, depth+1, parents_array, visited, max_depth);
      }
   }

   tag_read_db(orig_tag_file);
   return 0;
}

/**
 * Make sure that "tag_database" is filled in for the given symbol
 * information structure.  Has side-effect of changing the active 
 * tag file to the first database that the symbols is found in.
 * 
 * @param cm   (reference) symbol information structure
 */
void tag_get_tagfile_browse_info(struct VS_TAG_BROWSE_INFO &cm) 
{
   if (!_haveContextTagging()) {
      return;
   }
   // tag database is already there, then don't change it
   if (cm.tag_database!=null && cm.tag_database!="") {
      return;
   }

   // found the tag, type, and class name, now find it in a database
   i := 0;
   orig_tagfile := tag_current_db();
   tag_files := tags_filenamea(cm.language);
   tag_filename := next_tag_filea(tag_files,i,false,true);
   while ( tag_filename!="" ) {

      // Find tag match for proc_name.
      int status = tag_find_tag(cm.member_name,cm.type_name,cm.class_name);
      while (status==0) {
         _str tag;
         tag_get_detail(VS_TAGDETAIL_name, tag);
         if (cm.member_name :== tag) {
            cm.tag_database= tag_filename;
            return;
         }
         status = tag_next_tag(cm.member_name,cm.type_name,cm.class_name);
      }
      tag_reset_find_tag();

      // didn't find it, try the next file
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   // jump back to original tag database
   tag_read_db(orig_tagfile);
}

int _VirtualProcSearch(_str &macro_name, bool includeFlags = true)
{
   tag_lock_matches(true);
   tag_lock_context(true);
   tag_push_context();
   _UpdateContext(true);
   VS_TAG_BROWSE_INFO cm;
   context_id := 0;
   if (macro_name == "") {
      context_id = (tag_get_num_of_context() > 0)? 1:STRING_NOT_FOUND_RC;
   } else {
      tag_decompose_tag_browse_info(macro_name, cm);
      context_id = tag_find_context_iterator(cm.member_name,true,true,true,cm.class_name);
   }
   if (context_id <= 0) {
      tag_pop_context();
      tag_unlock_context();
      return STRING_NOT_FOUND_RC;
   }
   tag_get_context_info(context_id, cm);
   if (!includeFlags) {
      cm.flags = SE_TAG_FLAG_NULL;
   }
   p_RLine = cm.line_no;
   _GoToROffset(cm.seekpos);
   macro_name = tag_compose_tag_browse_info(cm);
   tag_pop_context();
   tag_unlock_context();
   tag_unlock_matches();
   return 0;
}


static void getAllCompilerChoices(available_compilers &compilers,
                                  _str (&cpp_compiler_names)[],
                                  _str (&java_compiler_names)[],
                                  _str (&dotnet_compiler_names)[] /*ignored*/ )
{
   if (!_haveBuild()) {
      return;
   }

   // get the list of C++ compiler configurations from compilers.xml
   filename := _ConfigPath():+COMPILER_CONFIG_FILENAME;
   refactor_config_open( filename );
   generate_default_configs();
   refactor_config_open( filename );
   refactor_get_compiler_configurations(cpp_compiler_names, java_compiler_names);
   _evaluate_compilers(compilers,cpp_compiler_names);
   refactor_config_close();
}

_str _getLatestVisualStudioVersion() 
{
   if (!_haveBuild()) {
      return "";
   }

   available_compilers compilers;
   _str cpp_compiler_names[];
   _str java_compiler_names[];
   _str dotnet_compiler_names[];
   // get the list of C++ compiler configurations from compilers.xml
   filename := _ConfigPath():+COMPILER_CONFIG_FILENAME;
   refactor_config_open( filename );
   generate_default_configs();
   refactor_config_open( filename );
   refactor_get_compiler_configurations(cpp_compiler_names, java_compiler_names);
   _evaluate_compilers(compilers,cpp_compiler_names);
   refactor_config_close();
   return compilers.latestMS;
}

void _getVisualStudioVersions(_str (&vstudio_versions)[]) 
{
   if (!_haveBuild()) {
      return;
   }

   available_compilers compilers;
   _str cpp_compiler_names[];
   _str java_compiler_names[];
   _str dotnet_compiler_names[];
   // get the list of C++ compiler configurations from compilers.xml
   filename := _ConfigPath():+COMPILER_CONFIG_FILENAME;
   refactor_config_open( filename );
   generate_default_configs();
   refactor_config_open( filename );
   refactor_get_compiler_configurations(cpp_compiler_names, java_compiler_names);
   int index;
   for (index=0;index<cpp_compiler_names._length();++index) {
      switch(cpp_compiler_names[index]) {
      case COMPILER_NAME_VS2003:
      case COMPILER_NAME_VS2005:
      case COMPILER_NAME_VS2005_EXPRESS:
      case COMPILER_NAME_VS2008:
      case COMPILER_NAME_VS2008_EXPRESS:
      case COMPILER_NAME_VS2010:
      case COMPILER_NAME_VS2010_EXPRESS:
      case COMPILER_NAME_VS2012:
      case COMPILER_NAME_VS2012_EXPRESS:
      case COMPILER_NAME_VS2013:
      case COMPILER_NAME_VS2013_EXPRESS:
      case COMPILER_NAME_VS2015:
      case COMPILER_NAME_VS2015_EXPRESS:
      case COMPILER_NAME_VS2017:
      case COMPILER_NAME_VS2019:
         vstudio_versions[vstudio_versions._length()] = cpp_compiler_names[index];
         break;
      }
   }
   refactor_config_close();
}

void _c_getAutoTagChoices(_str &langCaption, int &langPriority, 
                          AUTOTAG_BUILD_INFO (&choices)[], _str &defaultChoice)
{
   available_compilers compilers;
   _str cpp_compiler_names[];
   _str java_compiler_names[];
   _str dotnet_compiler_names[];
   getAllCompilerChoices(compilers, cpp_compiler_names, java_compiler_names, dotnet_compiler_names);

   _str cppList[];
   VisualCppPath := "";
   _str cppNamesList[];
   getCppIncludePath(cppList, VisualCppPath, cppNamesList);

   // If default config exists then set the combo box to that one
   langPriority = 10;
   langCaption = C_COMPILER_CAPTION;
   defaultChoice = def_refactor_active_config;
   if ( def_refactor_active_config == null || def_refactor_active_config == "" ) {
      defaultChoice = compilers.latestCygwin;
   }

   // keep checking if default_compiler_name is empty because
   // latestCygwin, latestMS, and even _GetLatestCompiler
   // can be empty strings based on the compilers installed
   if (defaultChoice=="") {
      defaultChoice = compilers.latestMS;
   }
   if (defaultChoice=="") {
      defaultChoice = _GetLatestCompiler();
   }

   // just pick the first one if there is one
   if (defaultChoice=="" && cpp_compiler_names._length() > 0) {
      defaultChoice = cpp_compiler_names[0];
   }

   for (i:=0; i<cpp_compiler_names._length(); ++i) {
      AUTOTAG_BUILD_INFO autotagInfo;
      autotagInfo.configName = cpp_compiler_names[i];
      autotagInfo.langId = "c";
      autotagInfo.tagDatabase = cpp_compiler_names[i]:+TAG_FILE_EXT;
      autotagInfo.directoryPath = "";
      autotagInfo.wildcardOptions = "";
      choices[choices._length()] = autotagInfo;
   }

   if (choices._length() <= 0) {
      for (i=0; i<cppNamesList._length(); i++) {
         AUTOTAG_BUILD_INFO autotagInfo;
         autotagInfo.configName = cppNamesList[i];
         autotagInfo.langId = "c";
         autotagInfo.tagDatabase = "cpp":+TAG_FILE_EXT;
         autotagInfo.directoryPath = cppList[i];
         autotagInfo.wildcardOptions = "";
         choices[choices._length()] = autotagInfo;
      }
   }
}

void _java_getAutoTagChoices(_str &langCaption, int &langPriority,
                             AUTOTAG_BUILD_INFO (&choices)[], _str &defaultChoice)
{
   available_compilers compilers;
   _str cpp_compiler_names[];
   _str java_compiler_names[];
   _str dotnet_compiler_names[];
   getAllCompilerChoices(compilers, cpp_compiler_names, java_compiler_names, dotnet_compiler_names);

   _str javaList[];
   _str javaNamesList[];
   JDKPath := "";
   getJavaIncludePath(javaList,JDKPath,javaNamesList);

   langPriority = 20;
   langCaption = JAVA_COMPILER_CAPTION;
   defaultChoice = _GetLatestJDK();
   if (defaultChoice == "not found") {
      defaultChoice = "";
   }

   for (i:=0; i<java_compiler_names._length(); ++i) {
      AUTOTAG_BUILD_INFO autotagInfo;
      autotagInfo.configName = java_compiler_names[i];
      autotagInfo.langId = "java";
      autotagInfo.tagDatabase = java_compiler_names[i]:+TAG_FILE_EXT;
      autotagInfo.directoryPath = "";
      autotagInfo.wildcardOptions = "";
      choices[choices._length()] = autotagInfo;
   }

   if (choices._length() <= 0) {
      for (i=0; i<javaNamesList._length(); i++) {
         AUTOTAG_BUILD_INFO autotagInfo;
         autotagInfo.configName = javaNamesList[i];
         autotagInfo.langId = "java";
         autotagInfo.tagDatabase = "java":+TAG_FILE_EXT;
         autotagInfo.directoryPath = javaList[i];
         autotagInfo.wildcardOptions = "";
         choices[choices._length()] = autotagInfo;
      }
   }
}

int _getAutoTagInfo_unity3d(AUTOTAG_BUILD_INFO &autotagInfo) {
   if (_isUnix()) {
      if (_isMac()) {
         install_path:='/Applications/Unity/Hub/Editor';
         if (file_exists(install_path)) {
            name:=file_match(_maybe_quote_filename(install_path:+'/*'),1);
            _str directory_name='';
            for (;;) {
               if (last_char(name)=='/') {
                  name=substr(name,1,length(name)-1);
                  directory_name=_strip_filename(name,'p');
                  if (substr(directory_name,1,1)!='.') {
                     directory_name=name;
                     break;
                  }
               }
               name=file_match(_maybe_quote_filename(install_path:+'/*'),0);
            }
            //say('directory_name='directory_name);
            install_path=directory_name:+'/Unity.app/Contents';
            path := install_path:+"/Managed/";

            if (!file_exists(path:+"UnityEngine.dll")) {
               return 1;
            }
            autotagInfo.configName = "Unity";
            autotagInfo.langId = "cs";
            autotagInfo.tagDatabase = "unity":+TAG_FILE_EXT;
            autotagInfo.directoryPath = install_path;
            mono_runtimes:=path:+'../MonoBleedingEdge/lib/mono/4.7.1-api';
            if (!file_exists(mono_runtimes)) {
               mono_runtimes=path:+'../Mono';
            }
            autotagInfo.wildcardOptions = _maybe_quote_filename(path:+'UnityEngine.dll'):+
               ' '_maybe_quote_filename(path:+'UnityEditor.dll'):+
               ' '_maybe_quote_filename(path:+'Unity.Locator.dll'):+
               ' '_maybe_quote_filename(path:+'../../../PlaybackEngines/WebGLSupport/UnityEditor.WebGL.Extensions.dll'):+
               ' '_maybe_quote_filename(path:+'../PlaybackEngines/MacStandaloneSupport/UnityEditor.OSXStandalone.Extensions.dll'):+
               //' +t "'path:+'../Mono/*.dll"':+
               ' +t '_maybe_quote_filename(path:+'../NetStandard/*.dll'):+
               ' +t '_maybe_quote_filename(mono_runtimes:+'/*.dll'):+
               ' '_maybe_quote_filename(path:+'../MonoBleedingEdge/lib/mono/unity/UnityScript.dll'):+
               ' '_maybe_quote_filename(path:+'../MonoBleedingEdge/lib/mono/unity/UnityScript.Lang.dll'):+
               ' '_maybe_quote_filename(path:+'../MonoBleedingEdge/lib/mono/unity/Boo.Lang.dll'):+
               ' +t '_maybe_quote_filename(path:+'UnityEngine/*.dll'):+
               ' +t '_maybe_quote_filename(path:+'../UnityExtensions/Unity/*.dll');
            return 0;
         }
         //Applications/Unity/Unity.app/Contents/Frameworks/Managed/UnityEngine.dll
         install_path = "/Applications/Unity/Unity.app/";
         path := install_path:+"Contents/Frameworks/Managed/";
         filename := path:+"UnityEngine.dll";
         if (file_exists(filename)) {
            autotagInfo.configName = "Unity";
            autotagInfo.langId = "cs";
            autotagInfo.tagDatabase = "unity":+TAG_FILE_EXT;
            autotagInfo.directoryPath = install_path;
            autotagInfo.wildcardOptions = _maybe_quote_filename(filename):+
               " "_maybe_quote_filename(path:+"UnityEditor.dll"):+
               " +t /Applications/Unity/Unity.app/Contents/UnityExtensions/Unity/GUISystem/*.dll":+
               " +t /Applications/Unity/Unity.app/Contents/Frameworks/Mono/*.dll";
            return 0;
         }
      }
      return 1;
   }
   //HKL\sorware\classes\com.unity3d.kharma\shell\open\command\
   //  "C:\Program Files (x86)\Unity\Editor\Unity.exe" -openurl "%1"
   key := 'SOFTWARE\classes\com.unity3d.kharma\shell\open\command';
   _str value = _ntRegQueryValue(HKEY_LOCAL_MACHINE,key,"",null);
   if (value._varformat()==VF_LSTR) {
      //_message_box('VALUE='value);
      _str unity_exe=parse_file(value,false);
      install_path := _strip_filename(unity_exe,'n');
      if (_last_char(install_path)==FILESEP) {
         install_path=substr(install_path,1,length(install_path)-1);
         install_path=_strip_filename(install_path,'n');
      }
      path := _strip_filename(unity_exe,'n'):+'data\managed\';

      autotagInfo.configName = "Unity";
      autotagInfo.langId = "cs";
      autotagInfo.tagDatabase = "unity":+TAG_FILE_EXT;
      autotagInfo.directoryPath = install_path;
      mono_runtimes:=path:+'../MonoBleedingEdge/lib/mono/4.7.1-api';
      if (!file_exists(mono_runtimes)) {
         mono_runtimes=path:+'../Mono';
      }
      autotagInfo.wildcardOptions = _maybe_quote_filename(path:+'UnityEngine.dll'):+
         ' '_maybe_quote_filename(path:+'UnityEditor.dll'):+
         ' '_maybe_quote_filename(path:+'Unity.Locator.dll'):+
         ' '_maybe_quote_filename(path:+'../PlaybackEngines/WebGLSupport/UnityEditor.WebGL.Extensions.dll'):+
         ' '_maybe_quote_filename(path:+'../PlaybackEngines/windowsstandalonesupport/UnityEditor.WindowsStandalone.Extensions.dll'):+
         //' +t "'path:+'../Mono/*.dll"':+
         ' +t '_maybe_quote_filename(path:+'../NetStandard/*.dll'):+
         ' +t '_maybe_quote_filename(mono_runtimes:+'/*.dll'):+
         ' '_maybe_quote_filename(path:+'../MonoBleedingEdge/lib/mono/unityscript/UnityScript.dll'):+
         ' '_maybe_quote_filename(path:+'../MonoBleedingEdge/lib/mono/unityscript/UnityScript.Lang.dll'):+
         ' '_maybe_quote_filename(path:+'../MonoBleedingEdge/lib/mono/unityscript/Boo.Lang.dll'):+
         ' +t '_maybe_quote_filename(path:+'UnityEngine/*.dll'):+
         ' +t '_maybe_quote_filename(path:+'../UnityExtensions/Unity/*.dll');
      return 0;
   }
   return 1;

}

void _cs_getAutoTagChoices(_str &langCaption, int &langPriority,
                           AUTOTAG_BUILD_INFO (&choices)[], 
                           _str &defaultChoice,
                           _str langId="cs")
{
   DotNetFrameworkInfo dotnetFrameworks[];
   getDotNetFrameworkPaths(dotnetFrameworks);

   available_compilers compilers;
   _str cpp_compiler_names[];
   _str java_compiler_names[];
   _str dotnet_compiler_names[];
   getAllCompilerChoices(compilers, cpp_compiler_names, java_compiler_names, dotnet_compiler_names);

   langPriority = 30;
   langCaption = DOTNET_COMPILER_CAPTION;
   defaultChoice = "";
   if (langId == "") langId = "cs";

   for (i:=0; i<dotnet_compiler_names._length(); ++i) {
      AUTOTAG_BUILD_INFO autotagInfo;
      autotagInfo.configName = dotnet_compiler_names[i];
      autotagInfo.langId = langId;
      autotagInfo.tagDatabase = dotnet_compiler_names[i]:+TAG_FILE_EXT;
      autotagInfo.directoryPath = "";
      autotagInfo.wildcardOptions = "";
      choices :+= autotagInfo;
   }

   if (choices._length() <= 0) {
      for (i=0; i<dotnetFrameworks._length(); i++) {
         dotnetItem := dotnetFrameworks[i];
         p := dotnetItem.display_name;
         if (p._length() == 0) p = dotnetItem.version;
         if (p._length() == 0) p = dotnetItem.name;
         if (i+1 == dotnetFrameworks._length() && !_isMac()) {
            defaultChoice = p;
         }
         dotnet_version := dotnetItem.version;
         if (dotnet_version == null) dotnet_version = "";
         if (dotnet_version != "" ) dotnet_version = "-":+dotnet_version;
         dotnet_version = "";
         AUTOTAG_BUILD_INFO autotagInfo;
         autotagInfo.configName = p;
         autotagInfo.langId = langId;
         autotagInfo.tagDatabase = "dotnet":+dotnet_version:+TAG_FILE_EXT;
         autotagInfo.directoryPath = dotnetItem.install_dir;
         autotagInfo.wildcardOptions = dotnetItem.maketags_args;
         choices :+= autotagInfo;
      }
   }
#if 0
   AUTOTAG_BUILD_INFO autotagInfo;
   int status=_getAutoTagInfo_unity3d(autotagInfo);
   if (!status) {
      choices[choices._length()] = autotagInfo;
      defaultChoice=autotagInfo.configName;
   }
#endif
}

void _fsharp_getAutoTagChoices(_str &langCaption, int &langPriority,
                               AUTOTAG_BUILD_INFO (&choices)[], 
                               _str &defaultChoice,
                               _str origLangId=null)
{
   if ( origLangId != null && origLangId == "fsharp" ) {
      _cs_getAutoTagChoices(langCaption,langPriority,choices,defaultChoice,"fsharp");
   }
}
void _bas_getAutoTagChoices(_str &langCaption, int &langPriority,
                            AUTOTAG_BUILD_INFO (&choices)[], 
                            _str &defaultChoice,
                            _str origLangId=null)
{
   if ( origLangId != null && origLangId == "bas" ) {
      _cs_getAutoTagChoices(langCaption,langPriority,choices,defaultChoice,"bas");
   }
}

void _m_getAutoTagChoices(_str &langCaption, int &langPriority, 
                          AUTOTAG_BUILD_INFO (&choices)[], _str &defaultChoice)
{
   if(_isMac()) {
      XcodeSDKInfo macFrameworks[];
      getXcodeSDKs(macFrameworks);
   
      langPriority = 40;   
      langCaption = XCODE_COMPILER_CAPTION;
      defaultChoice = "";
   
      if (macFrameworks._length() > 0) {
         for (i:=0; i<macFrameworks._length(); i++) {
            defaultChoice = macFrameworks[0].name;
            AUTOTAG_BUILD_INFO autotagInfo;
            frmInfo := macFrameworks[i];
            autotagInfo.configName = frmInfo.name;
            autotagInfo.langId = "m";
            autotagInfo.tagDatabase = "ufrmwk":+TAG_FILE_EXT;
            autotagInfo.directoryPath = frmInfo.framework_root;
            autotagInfo.wildcardOptions = "";
            choices[choices._length()] = autotagInfo;
         }
      }
   }
}

void _cob_getAutoTagChoices(_str &langCaption, int &langPriority,
                            AUTOTAG_BUILD_INFO (&choices)[], _str &defaultChoice)
{
   // get the cobol compiler options
   _str cobolList[];
   _CobolInstallPaths(cobolList);

   langPriority = 50;
   langCaption = "Cobol Libraries";
   defaultChoice = "";

   if (cobolList._length() > 0) {
      p := "";
      foreach (p in cobolList) {
         AUTOTAG_BUILD_INFO autotagInfo;
         autotagInfo.configName = p;
         autotagInfo.langId = "cob";
         autotagInfo.tagDatabase = "cobol":+TAG_FILE_EXT;
         autotagInfo.directoryPath = p;
         autotagInfo.wildcardOptions = "";
         choices[choices._length()] = autotagInfo;
      }
   }
}

void _pl_getAutoTagChoices(_str &langCaption, int &langPriority, 
                          AUTOTAG_BUILD_INFO (&choices)[], _str &defaultChoice)
{
   langPriority = 45;
   langCaption = "Perl libraries";
   defaultChoice = "";

   _str perls[];
   // first, we try and find some perl
   status := 0;
   perl_binary := "";
   if (_isWindows()) {
      status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                               "SOFTWARE\\ActiveWare\\Perl5",
                               "BIN", perl_binary);
      if (!status) {
         perls[perls._length()] = perl_binary;
      }
   }

   perl_binary=path_search("perl","","P");
   if (perl_binary != "") {
      perls[perls._length()] = _strip_filename(perl_binary, 'N');
   }

   if (_isWindows()) {
      perl_binary=_path2cygwin("/bin/perl.exe");
      if (perl_binary != "") {
         perl_binary = _cygwin2dospath(perl_binary);
         if (perl_binary != "") {
            perls[perls._length()] = _strip_filename(perl_binary, 'N');
         }
      }
   }
   if (def_perl_exe_path != "") {
      perls[perls._length()] = _strip_filename(def_perl_exe_path, 'N');
   }

   foreach (auto p in perls) {
      if (p != "") {
         AUTOTAG_BUILD_INFO autotagInfo;
         if (pos("cygwin", p)) {
            autotagInfo.configName = "Cygwin Perl";
         } else {
            autotagInfo.configName = p;
         }
         autotagInfo.langId = "pl";
         autotagInfo.tagDatabase = "perl":+TAG_FILE_EXT;
         autotagInfo.directoryPath = p;
         autotagInfo.wildcardOptions = "";
         choices[choices._length()] = autotagInfo;
      }
   }
}

/**
 * Load all the auto-tagging choices into the given tree control (which should 
 * be the current window ID when this is called). 
 *  
 * @param langId     Load the choices specifically for the given language 
 */
void _loadAutoTagChoices(_str langId="")
{
   // go through all the languages
   _str allLangIds[];
   if (langId == null || langId == "") {
      LanguageSettings.getAllLanguageIds(allLangIds);
   } else {
      allLangIds :+= langId;
   }
   foreach (auto thisLangId in allLangIds) {
      _loadLangAutoTagChoices(thisLangId, -1, langId);
   }
   _TreeSortUserInfo(TREE_ROOT_INDEX, 'N');
}

static bool FudgeJavaCaptions(int langIndex,bool checkOnly=false) {
   child:=_TreeGetFirstChildIndex(langIndex);
   while (child>=0) {
      caption:=_TreeGetCaption(child);
      digits_string:=caption;
      if (pos('JDK',digits_string)>0) {
         parse digits_string with 'JDK' digits_string "\t";
      }
      digits_string=strip(digits_string);
      if (!(
          isnumber(substr(digits_string,1,3)) 
          ||(isinteger(substr(digits_string,1,2)) /*two digit major case*/ && substr(digits_string,3,1)=='.')
          )
          ) {
         if (checkOnly) {
            return true;
         }
      }
      parse digits_string with auto digits1 '.' auto digits2 '.';
      _str prefix='';
      if (digits1==1) {
         if (length(digits2)==1) {
            prefix='0'digits2;
         } else if(length(digits2)==0) {
            if (checkOnly) {
               return true;
            }
         } else {
            if (checkOnly) {
               return true;
            }
         }
      } else {
         if (length(digits1)==1) {
            prefix='0'digits1;
         } else {
            // Should be two digits here or we are lost
            prefix=digits1;
         }
      }
      //say('prefix='prefix' cap='caption);
      if (!checkOnly) {
         _TreeSetCaption(child,prefix:+_chr(1):+caption);
      }
      child=_TreeGetNextSiblingIndex(child);
   }
   return false;
}
static void SortJDKCaptions(int langIndex) {
   // Try to fix sort order. 9.x.x will be sorted before 10.x

   // Check if we recognize the captions
   if(FudgeJavaCaptions(langIndex,true)) {
      // We're lost.
      return;
   }
   FudgeJavaCaptions(langIndex,false);
   _TreeSortCaption(langIndex, 'D');
   // Restore the captions
   child:=_TreeGetFirstChildIndex(langIndex);
   while (child>=0) {
      caption:=_TreeGetCaption(child);
      parse caption with (_chr(1)) caption;
      _TreeSetCaption(child,caption);
      child=_TreeGetNextSiblingIndex(child);
   }

}

int _loadLangAutoTagChoices(_str langId, int langIndex = -1, _str origLangId=null)
{
   // check if there is a callback for this language
   callbackIndex := find_index("_"langId"_getAutoTagChoices", PROC_TYPE);
   if (!index_callable(callbackIndex)) {
      return -1;
   }

   // call the callback to get the auto tag file build choices
   AUTOTAG_BUILD_INFO autotagInfo;
   AUTOTAG_BUILD_INFO choices[];
   defaultChoice := "";
   langCaption := ""; 
   langPriority := 0;
   call_index(langCaption, langPriority, choices, defaultChoice, origLangId, callbackIndex);
   if (choices._length() <= 0) {
      // we have an empty section, let us delete it
      if (langIndex > 0) {
         _TreeDelete(langIndex);
      }
      return -1;
   }

   // add this category to the tree
   if (langIndex < 0) {
      langIndex = _TreeAddItem(TREE_ROOT_INDEX, langCaption, TREE_ADD_AS_CHILD, _pic_fldclos, _pic_fldopen, TREE_NODE_EXPANDED, 0, langPriority);
   } else {
      // remove all existing children, please
      _TreeDelete(langIndex, 'C');
   }

   // go through all the items and add them to the tree
   _str choicesFound:[];
   foreach (autotagInfo in choices) {
      if (choicesFound._indexin(lowcase(autotagInfo.configName))) {
         continue;
      }
      checked := TCB_UNCHECKED;
      if (autotagInfo.configName == defaultChoice) {
         checked = TCB_CHECKED;
      }
      caption := autotagInfo.configName;
      if (autotagInfo.directoryPath != null && 
          autotagInfo.directoryPath != "" && 
          autotagInfo.directoryPath != autotagInfo.configName) {
         caption :+=  \t :+ autotagInfo.directoryPath;
      }

      compilerIndex := _TreeAddItem(langIndex, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, autotagInfo);
      _TreeSetCheckable(compilerIndex, 1, 0);
      _TreeSetCheckState(compilerIndex, checked);
      choicesFound:[lowcase(autotagInfo.configName)] = true;
   }
   if (langId=='java') {
      SortJDKCaptions(langIndex);
   } else {
      _TreeSortCaption(langIndex, 'D');
   }

   return langIndex;
}

void replace_exttagfiles(_str ext,_str tagfilename)
{
   file_name := _strip_filename(tagfilename,'P');
   tf1 := absolute(_tagfiles_path():+file_name);
   tf2 := absolute(_global_tagfiles_path():+file_name);
   tag_files := "";

   fileList := LanguageSettings.getTagFileList(ext);
   while (fileList!="") {
      f_env := parse_tag_file_name(fileList);
      curFile := _replace_envvars(f_env);

      // see if the file is already in our list
      if (_file_eq(curFile, tagfilename)) {
         // already in the list, so don't mess with it
         return;
      }

      // this file is not the same as our new file, so we will keep it in the list
      if (!_file_eq(curFile,tf1) && !_file_eq(curFile,tf2)) {
         if (tag_files=="") {
            tag_files=f_env;
         } else {
            strappend(tag_files,PATHSEP:+f_env);
         }
      }
   }

   if (tag_files != "") tag_files :+= PATHSEP;
   tag_files :+= tagfilename;
  
   LanguageSettings.setTagFileList(ext, tag_files);
}

int _do_default_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, bool backgroundThread = true)
{
   call_list("_LoadBackgroundTaggingSettings");
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   tagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   flags := VS_TAG_REBUILD_FROM_SCRATCH;
   if (!backgroundThread) flags |= VS_TAG_REBUILD_SYNCHRONOUS;
   status := tag_build_tag_file_from_wildcards(tagFileName,
                                               flags, 
                                               autotagInfo.directoryPath,
                                               autotagInfo.wildcardOptions);

   if (status == 0) {
      alertId := _GetBuildingTagFileAlertGroupId(tagFileName);
      _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, "Updating: "autotagInfo.tagDatabase, "", 1);
   } else if (status < 0) {
      msg := get_message(status, tagFileName);
      notifyUserOfWarning(ALERT_TAGGING_ERROR, msg, tagFileName, 0);
   }

   return status;
}

int _c_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, bool backgroundThread = true)
{
   // compiler configurations save the directory path for later
   config_name := autotagInfo.configName;
   if (autotagInfo.directoryPath == "" && _haveBuild()) {

      config_file := _ConfigPath() :+ COMPILER_CONFIG_FILENAME;
      status := refactor_config_open( config_file );

      if(status==VSRC_VSREFACTOR_CONFIGURATION_NOT_FOUND_1A || refactor_config_count() <= 0 ) {
         generate_default_configs();
         status=0;
      }
      if (status < 0) {
         return status;
      }
      status = refactor_build_compiler_tagfile(config_name, "cpp", true, backgroundThread);
      refactor_config_close();
      def_refactor_active_config=config_name;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      gtag_filelist_cache_updated=false;
      gTagFileListCache._makeempty();
      return status;

   }

   // have to build tag file based on name and directory information
   cppPath := autotagInfo.directoryPath;
   _maybe_append_filesep(cppPath);
   autotagInfo.wildcardOptions = create_cpp_autotag_args(cppPath);
   if (autotagInfo.wildcardOptions == "") {
      // check for cygwin
       autotagInfo.wildcardOptions = create_cygwin_autotag_args();
       if (autotagInfo.wildcardOptions == "") {
          return FILE_NOT_FOUND_RC;
       }
   }

   cppTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   cppTagFileName = _maybe_quote_filename(cppTagFileName);

   make_tag_cmd := backgroundThread ? "-b " : "";
   make_tag_cmd :+= '-t -c -n "C/C++ Compiler Libraries" -o ':+cppTagFileName:+" ":+autotagInfo.wildcardOptions;
   status := make_tags(make_tag_cmd);
   if (!status) {
      replace_exttagfiles("c",cppTagFileName);

      list := LanguageSettings.getTagFileList("c");
      if (list != "") {
         list = _replace_envvars(list);
         vcpp_TagFileName := _strip_filename(cppTagFileName,'N'):+"visualcpp":+TAG_FILE_EXT;
         list=PATHSEP:+list:+PATHSEP;
         b4 := after := "";
         parse list with  b4 (PATHSEP:+vcpp_TagFileName:+PATHSEP),_fpos_case after;
         if (b4!=list) {
            list=strip(b4:+PATHSEP:+after,'B',PATHSEP);
            list=stranslate(list,PATHSEP,PATHSEP:+PATHSEP);
            LanguageSettings.setTagFileList('c', list);
         }
      }
   }
   return status;
}

int _java_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, bool backgroundThread = true)
{
   config_name := autotagInfo.configName;
   javaPath := autotagInfo.directoryPath;
   _maybe_append_filesep(javaPath);

   // compiler configurations save the directory path for later
   if (autotagInfo.directoryPath == "" && _haveContextTagging()) {
      config_file := _ConfigPath() :+ COMPILER_CONFIG_FILENAME;
      status := refactor_config_open( config_file );
      if(status==VSRC_VSREFACTOR_CONFIGURATION_NOT_FOUND_1A || refactor_config_count() <= 0 ) {
         generate_default_configs();
         status=0;
      }
      if (status < 0) {
         return status;
      }
      status = refactor_build_compiler_tagfile(config_name, "java", true, backgroundThread);
      refactor_config_close();
      def_active_java_config=config_name;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      return status;
   }

   autotagInfo.wildcardOptions = create_java_autotag_args(javaPath/*, true*/);
   if (autotagInfo.wildcardOptions == "") {
      autotagInfo.wildcardOptions = CheckForUserInstalledJava(javaPath);
      if ( autotagInfo.wildcardOptions=="") {
         return FILE_NOT_FOUND_RC;
      }
   }

   javaTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   javaTagFileName = _maybe_quote_filename(javaTagFileName);

   //Check to see if there is a previous copy of VisualCafe.vtg
   tree_option := "-t ";
   if (_isUnix()) {
      if (!pos("*.java",autotagInfo.wildcardOptions)) {
         // We really need this if we are tagging kaffe because we will be searching
         // everthing under "/usr/share".  This code is also useful when we are just
         // tagging specific jar or zip files.  This code might work well for Windows
         // too.
         tree_option="";
      }
   }
   make_tag_cmd := backgroundThread ? "-b " : "";
   make_tag_cmd :+= tree_option' -c -n "Java Compiler Libraries" -o ':+javaTagFileName:+" ":+autotagInfo.wildcardOptions;
   status := make_tags(make_tag_cmd);
   if (!status) {
      replace_exttagfiles("java",javaTagFileName);
   }
   return status;
}

int _cs_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, bool backgroundThread = true)
{
   config_name := autotagInfo.configName;
   dotnetPath := autotagInfo.directoryPath;
   _maybe_append_filesep(dotnetPath);

   // compiler configurations save the directory path for later
   if (autotagInfo.directoryPath == "" && _haveBuild()) {
      config_file := _ConfigPath() :+ COMPILER_CONFIG_FILENAME;
      status := refactor_config_open( config_file );
      if (status==VSRC_VSREFACTOR_CONFIGURATION_NOT_FOUND_1A || refactor_config_count() <= 0 ) {
         generate_default_configs();
         status=0;
      }
      if (status < 0) {
         return status;
      }
      status = refactor_build_compiler_tagfile(config_name, "dotnet", true, backgroundThread);
      refactor_config_close();
      def_active_java_config=config_name;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      return status;
   }

   dotnet_version := autotagInfo.configName;
   if (dotnet_version == null) dotnet_version = "";
   dotnetTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   dotnetTagFileName = _maybe_quote_filename(dotnetTagFileName);

   make_tag_cmd := backgroundThread ? "-b " : "";
   make_tag_cmd :+= '-t -c -n ".NET Framework ':+dotnet_version:+'" -o ':+dotnetTagFileName:+" ":+autotagInfo.wildcardOptions;
   status := make_tags(make_tag_cmd);
   if (!status) {
      replace_exttagfiles("cs",dotnetTagFileName);
      replace_exttagfiles("bas",dotnetTagFileName);
   }
   return status;
}

int _fsharp_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, bool backgroundThread = true)
{
   return _cs_buildAutoTagFile(autotagInfo, backgroundThread);
}
int _bas_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, bool backgroundThread = true)
{
   return _cs_buildAutoTagFile(autotagInfo, backgroundThread);
}

int _cob_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, bool backgroundThread = true)
{
   config_name := autotagInfo.configName;
   cobolPath := autotagInfo.directoryPath;
   _maybe_append_filesep(cobolPath);
   autotagInfo.wildcardOptions = create_cobol_autotag_args(cobolPath);

   cobolTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   cobolTagFileName = _maybe_quote_filename(cobolTagFileName);
   make_tag_cmd := backgroundThread ? "-b " : "";
   make_tag_cmd :+= '-t -c -n "COBOL Compiler Libraries" -o ':+cobolTagFileName:+" ":+autotagInfo.wildcardOptions;
   status := make_tags(make_tag_cmd);
   if (!status) {
      replace_exttagfiles("cob",cobolTagFileName);
   }
   return status;
}

int _m_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, bool backgroundThread = true)
{
   config_name := autotagInfo.configName;
   frameworkPath := autotagInfo.directoryPath;
   _maybe_append_filesep(frameworkPath);
   bool visited:[];
   autotagInfo.wildcardOptions = create_framework_autotag_args(frameworkPath,visited);

   // If we're doing the default /System/Library/Frameworks, then also add
   // the /Library/Frameworks directory
   if (frameworkPath :== "/System/Library/Frameworks/") {
      visited._makeempty();
      strappend(autotagInfo.wildcardOptions, create_framework_autotag_args("/Library/Frameworks/",visited));
   }

   frameworkTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   frameworkTagFileName = _maybe_quote_filename(frameworkTagFileName);
   //Check to see if there is a previous version of the tag file
   make_tag_cmd := backgroundThread ? "-b " : "";
   make_tag_cmd :+= '-t -c -n "C/C++/Objective-C Frameworks" -o ':+frameworkTagFileName:+" ":+autotagInfo.wildcardOptions;
   status := make_tags(make_tag_cmd);
   if (!status) {
      // Link the tag file to both C/C++ and Objective-C and Swift
      replace_exttagfiles("c",frameworkTagFileName);
      replace_exttagfiles("m",frameworkTagFileName);
      replace_exttagfiles("swift",frameworkTagFileName);
   }
   return status;
}

int _pl_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, bool backgroundThread = true)
{
   config_name := autotagInfo.configName;
   perlPath := autotagInfo.directoryPath;
   _maybe_append_filesep(perlPath);
   autotagInfo.wildcardOptions = create_perl_autotag_args(perlPath);

   perlTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   perlTagFileName = _maybe_quote_filename(perlTagFileName);
   make_tag_cmd := backgroundThread ? "-b " : "";
   make_tag_cmd :+= '-t -c -n "Perl Compiler Libraries" -o ':+perlTagFileName:+" ":+autotagInfo.wildcardOptions;
   status := make_tags(make_tag_cmd);
   if (!status) {
      replace_exttagfiles("pl",perlTagFileName);
   }
   return status;
}

void _buildSelectedAutoTagFiles(AUTOTAG_BUILD_INFO (&choices)[], bool backgroundThread)
{
   AUTOTAG_BUILD_INFO autotagInfo;
   foreach (autotagInfo in choices) {
      buildIndex := find_index("_"autotagInfo.langId"_buildAutoTagFile", PROC_TYPE);
      if (buildIndex <= 0) {
         buildIndex = find_index("_do_default_buildAutoTagFile", PROC_TYPE);
      }
      if (index_callable(buildIndex)) {
         call_index(autotagInfo, backgroundThread, buildIndex);
      }
   }
}

_str _getSelectedAutoTagFiles(AUTOTAG_BUILD_INFO (&choices)[])
{
   allChoices := "";
   choices._makeempty();
   langIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (langIndex > TREE_ROOT_INDEX) {
      compilerIndex := _TreeGetFirstChildIndex(langIndex);
      while (compilerIndex > TREE_ROOT_INDEX) {

         configName := _TreeGetCaption(compilerIndex);
         checked := _TreeGetCheckState(compilerIndex, 0);
         if (checked == TCB_CHECKED) {
            AUTOTAG_BUILD_INFO autotagInfo = _TreeGetUserInfo(compilerIndex);
            if (autotagInfo.configName==null || autotagInfo.configName=="") {
               autotagInfo.configName = configName;
            }
            if (autotagInfo != null && configName != "") {
               _maybe_append(allChoices, "\t");
               allChoices :+= configName;
               choices[choices._length()] = autotagInfo;
            }
         }
         compilerIndex = _TreeGetNextSiblingIndex(compilerIndex);
      }
      langIndex = _TreeGetNextSiblingIndex(langIndex);
   }
   return allChoices;
}

void _checkSelectedAutoTagFiles(_str selectedItems)
{
   // first time here, just take all the defaults
   if (selectedItems == null || selectedItems == "") {
      return;
   }
   langIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (langIndex > TREE_ROOT_INDEX) {
      compilerIndex := _TreeGetFirstChildIndex(langIndex);
      while (compilerIndex > TREE_ROOT_INDEX) {
         // get the original checkbox picture index
         orig_checked := checked := _TreeGetCheckState(compilerIndex, 0);
         // should this item be checked or not?
         configName := _TreeGetCaption(compilerIndex);
         if (pos("\t"configName"\t", "\t"selectedItems"\t") > 0) {
            checked = TCB_CHECKED;
         } else {
            checked = TCB_UNCHECKED;
         }
         // did it change?
         if (checked != orig_checked) {
            _TreeSetCheckState(compilerIndex, checked);
         }
         // next please
         compilerIndex = _TreeGetNextSiblingIndex(compilerIndex);
      }
      langIndex = _TreeGetNextSiblingIndex(langIndex);
   }
}

_str create_cobol_autotag_args(_str cobolPath)
{
   // has a nice side-effect...
   if (cobolPath!="") {
      // make sure that cobol support is loaded
      if (!index_callable(find_index("_CobolCopyFilePath",PROC_TYPE))) {
         load(_getSlickEditInstallPath():+"macros":+FILESEP:+"cobol.e");
      }
      // Sets def_cobol_copy_path and gcobol_copy_path
      _str copy_path = _CobolCopyFilePath(cobolPath);
   }

   _str extra_file=ext_builtins_path("cob","cobol");

   if (cobolPath=="") {
      return(extra_file);
   }

   // we do not pull in these specific copy books, so tag them here
   win_cpy_files := "";
   if (_isWindows()) {
      if (file_exists(cobolPath:+"windows.cpy")) {
         win_cpy_files :+= ' "'cobolPath:+'windows.cpy"';
      }
      if (file_exists(cobolPath:+"mq.cpy")) {
         win_cpy_files :+= ' "'cobolPath:+'mq.cpy"';
      }
   }

   return ( extra_file :+
            ' "'cobolPath:+'*.cob"' :+
            ' "'cobolPath:+'*.cbl"' :+
            ' "'cobolPath:+'*.ocb"' :+
            win_cpy_files );
}

_str create_framework_autotag_args(_str frameworkPath, bool (&visited):[], int depth=0)
{
   ret_value := "";
   _str folders[];
   _str names[];
   path := file_match("+D +X "frameworkPath,1);
   while (path:!="") {
      folders[folders._length()]=path;
      path=file_match("+D +X "frameworkPath,0);
   }

   for (index:=0;index<folders._length();++index) {
      frameworkName := folders[index];
      _maybe_strip_filesep(frameworkName);
      frameworkName = _strip_filename(frameworkName,'P');
      names[index] = frameworkName;
      if (visited._indexin(frameworkName)) {
         continue;
      }
      visited:[frameworkName] = false;
      if ("./":!=substr(folders[index],length(folders[index])-1)) {
         strappend(ret_value,folders[index]:+"Headers/*.h ");
      }
   }

   for (index=0;index<folders._length();++index) {
      frameworkName := names[index];
      if (visited._indexin(frameworkName) && visited:[frameworkName]==true) {
         continue;
      }
      visited:[frameworkName] = true;
      if ("./":!=substr(folders[index],length(folders[index])-1)) {
         strappend(ret_value,create_framework_autotag_args(folders[index]:+"Frameworks/",visited, depth+1));
      }
   }

   return ret_value;
}

_str create_cygwin_autotag_args()
{
   if (_isUnix()) {
      return("");
   }
   _str cygwinPath = _cygwin_path();
   if (cygwinPath!="") {
      include_path := "";
      if (isdirectory(cygwinPath:+"usr":+FILESEP)) {
         include_path = _maybe_quote_filename(cygwinPath:+"usr":+FILESEP:+"*.h");
         include_path :+= " "_maybe_quote_filename(cygwinPath:+"usr":+FILESEP:+"*.c");
      }
      if (isdirectory(cygwinPath:+"lib":+FILESEP)) {
         if (include_path=="") {
            include_path = _maybe_quote_filename(cygwinPath:+"lib":+FILESEP:+"*.h");
         } else {
            include_path :+= " "_maybe_quote_filename(cygwinPath:+"lib":+FILESEP:+"*.h");
         }
         include_path :+= " "_maybe_quote_filename(cygwinPath:+"lib":+FILESEP:+"*.c");
      }
      cygwinPath = include_path;
   }
   return(cygwinPath);
}

_str create_perl_autotag_args(_str perlPath)
{
   extra_file := ext_builtins_path("pl","perl");

   _maybe_append_filesep(perlPath);
   std_libs := get_perl_std_libs(perlPath :+ "perl.exe");

   return ( extra_file :+ std_libs );
}

/**
 * Generic proc_search that uses a regular expression search.
 *  
 * @param regex        expression to search for. 
 *                     This must contain the string "<<<NAME>>>"
 *                     to indicate the position of the tag name.
 *                     It can also optionally contain the following:
 *                     <ul>
 *                     <li>"<<<NAME2>>>" -- alternate name regular expression
 *                     <li>"<<<CLASS>>>" -- indicates position of class name regex
 *                     <li>"<<<RETURN>>>" -- indicates position of return type regex
 *                     <li>"<<<ARGS>>>" -- indicates position of argument list regex
 *                     <li>"<<<TYPE>>>" -- indicates position of type regex
 *                     <li>"<<<FLAGS>>>" -- indicates position of keyword(s) that maps to tag flags
 *                     </ul>
 * @param proc_name    (reference) proc to search for, or set to name of proc found
 * @param find_first   find first proc, or find next? 
 * @param type_name    tag type to use for matches found 
 * @param re_map       map regular expression compontes, 
 *                     allowed keys include NAME, NAME2, CLASS, RETURN, TYPE, ARGS
 *                     (passed by reference, but never modified) 
 * @param kw_map       map keywords to tag type names or tag flag values
 *                     (passed by reference, but never modified) 
 *
 * @return 0 on success, nonzero on error or if no more tags.
 *  
 * @categories Tagging_Functions
 */
int _generic_regex_proc_search(_str regex, _str &proc_name, bool find_first, _str type_name="", _str (&re_map):[]=null, _str (&kw_map):[]=null)
{
   tag_init_tag_browse_info(auto cm);
   status := 0;

   if (find_first) {
      // construct regular expression for the proc name
      new_re_map := re_map;
      if ( proc_name == "" ) {
         proc_name = _clex_identifier_re();
         if (!re_map._indexin("NAME"))  new_re_map:["NAME"]  = proc_name;
         if (!re_map._indexin("NAME2")) new_re_map:["NAME2"] = proc_name;
         if (!re_map._indexin("CLASS")) new_re_map:["CLASS"] = proc_name;
      } else {
         tag_decompose_tag_browse_info(proc_name, cm);
         proc_name = _escape_re_chars(cm.member_name);
         new_re_map:["NAME"]  = proc_name;
         new_re_map:["NAME2"] = proc_name;
         new_re_map:["CLASS"] = _escape_re_chars(cm.class_name);
      }

      // generic regular expression for arguments
      if (pos("<<<ARGS>>>", regex) && !new_re_map._indexin("ARGS")) {
         new_re_map:["ARGS"] = "[ \\t,*&=":+_clex_identifier_chars():+"]@";
      }

      // substitute user-specified regular expressions
      new_regex := regex;
      foreach (auto item in "NAME NAME2 CLASS ARGS RETURN TYPE FLAGS") {
         marker := "<<<":+item:+">>>";
         marker_re := (new_re_map._indexin(item)? new_re_map:[item] : _clex_identifier_re());
         new_regex = stranslate(new_regex, "(#<":+item:+">":+marker_re:+")", marker);
      }

      // search for a match
      case_opts := (p_LangCaseSensitive? '':'i');
      status=search(new_regex,'@rh'case_opts'Xcs');
      proc_name = "";

   } else {
      // search again
      status=repeat_search();
   }

   // set 'proc_name" to the match if we found something
   while ( !status ) {
      // make sure we got a good match (with a tag name)
      tag_init_tag_browse_info(cm);
      cm.member_name = strip(get_match_text("NAME"));
      if (cm.member_name == "" && pos("<<<NAME2>>>", regex)) cm.member_name = strip(get_match_text("NAME2"));
      if (cm.member_name == "") {
         status = repeat_search();
         continue;
      }

      // get labeled components of regular expression match
      if (pos("<<<CLASS>>>",  regex))  cm.class_name  = strip(get_match_text("CLASS"));
      if (pos("<<<RETURN>>>", regex))  cm.return_type = strip(get_match_text("RETURN"));
      if (pos("<<<ARGS>>>",   regex))  cm.arguments   = strip(get_match_text("ARGS"));

      // get the keyword associated with the tag, then map to a tag type
      if (pos("<<<TYPE>>>", regex)) {
         kw := strip(get_match_text("TYPE"));
         if (kw_map._indexin(kw)) {
            type_name = kw_map:[kw];
         } else if (kw_map._indexin(lowcase(kw))) {
            type_name = kw_map:[lowcase(kw)];
         } else if (kw_map._indexin(upcase(kw))) {
            type_name = kw_map:[upcase(kw)];
         }
      }
      cm.type_name=type_name;

      // get the tag flags associated with the tag, then map to tag flags
      cm.flags = SE_TAG_FLAG_NULL;
      if (pos("<<<FLAGS>>>", regex)) {
         list := strip(get_match_text("FLAGS"));
         while (list != "") {
            val := "";
            parse list with auto kw list;
            if (kw_map._indexin(kw)) {
               val = kw_map:[kw];
            } else if (kw_map._indexin(lowcase(kw))) {
               val = kw_map:[lowcase(kw)];
            } else if (kw_map._indexin(upcase(kw))) {
               val = kw_map:[upcase(kw)];
            }
            if (val != "" && isinteger(val)) {
               cm.flags |= (SETagFlags)((int)val);
            }
         }
      }

      // we have a valid tag
      proc_name = tag_compose_tag_browse_info(cm);
      return 0;
   }

   // we did not find a tag
   return status;
}

