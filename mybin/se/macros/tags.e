////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50174 $
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
#import "se/tags/TaggingGuard.e"
#import "varedit.e"
#import "autosave.e"
#import "bind.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "compile.e"
#import "context.e"
#import "c.e"
#import "cjava.e"
#import "cua.e"
#import "cutil.e"
#import "dlgman.e"
#import "eclipse.e"
#import "error.e"
#import "fileman.e"
#import "files.e"
#import "guicd.e"
#import "html.e"
#import "javaopts.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "mfsearch.e"
#import "mouse.e"
#import "mprompt.e"
#import "perl.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "pushtag.e"
#import "quickrefactor.e"
#import "refactor.e"
#import "search.e"
#import "seek.e"
#import "seldisp.e"
#import "seltree.e"
#import "setupext.e"
#import "sftp.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tagrefs.e"
#import "tagwin.e"
#import "tbautohide.e"
#import "toast.e"
#import "toolbar.e"
#import "util.e"
#import "wkspace.e"
#import "cobol.e"
#import "asm.e"
#import "xmlcfg.e"
#import "env.e"
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
                       use existing tag types, see VS_TAGTYPE_* for the
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

#define C_COMPILER_CAPTION       "C/C++ compiler libraries"
#define JAVA_COMPILER_CAPTION    "Java compiler libraries"
#define DOTNET_COMPILER_CAPTION  ".NET Frameworks (C# and VB)"
#define XCODE_COMPILER_CAPTION   "Xcode Frameworks"
// Has
static STRARRAY eclipseExtMap:[];

static _str gEclipseTags;
//int def_include_protos = 0;

static boolean gTagCallList:[];
void _TagDelayCallList()
{
   gNoTagCallList=1;
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
   gNoTagCallList=0;
   _str tag_refresh_i=TagMakeIndex(TAGFILE_REFRESH_CALLBACK_PREFIX);
   boolean DoRefresh=gTagCallList._indexin(tag_refresh_i);
   typeless i;
   for (i._makeempty();;) {
      gTagCallList._nextel(i);
      if (i._isempty()) break;
      if (i==tag_refresh_i) {
         continue;
      }
      _str a1='',a2='',a3='';
      parse i with a1 (_chr(0)) a2 (_chr(0)) a3;
      call_list(a1,a2,a3);
   }
   if (DoRefresh) {
      call_list(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }
}

static boolean _gin_update_tagfile_cache;
void _update_tag_filelists()
{
   if (!gtag_filelist_cache_updated && !_gin_update_tagfile_cache) {
      _gin_update_tagfile_cache=1;
      _update_tag_filelist2();
      _gin_update_tagfile_cache=0;
   }
}
static _str gtag_filelist_last_ext;
void _update_tag_filelist_ext(_str ext)
{
   _update_tag_filelists();

   // if this is the same extension we were looking for 
   // last time, no need to update
   if (gtag_filelist_last_ext==ext) {
      return;
   }

   //gtag_filelist_ext._makeempty();
   // get the tag file list
   _str tag_filelist=tags_filename(ext,true);

   // put these tag files into the global list so we don't 
   // have to look it up again
   gtag_filelist_ext._makeempty();
   for (;;) {
      _str tag_filename=parse_tag_file_name(tag_filelist);
      if (tag_filename=='') {
         break;
      }
       gtag_filelist_ext[gtag_filelist_ext._length()]=tag_filename;
   }

   // save the extension so we know what we have
   gtag_filelist_last_ext=ext;
}
static void _update_tag_filelist2()
{
   gtag_filelist_cache_updated=false;
   gtag_filelist_last_ext="";
   
   gtag_filelist_ext._makeempty();
   gtag_filelist._makeempty();
   _str tag_filelist=tags_filename();
   _str tag_filename='';
   for (;;) {
      tag_filename = parse_tag_file_name(tag_filelist);
      if (tag_filename=='') {
         break;
      }
      gtag_filelist[gtag_filelist._length()]=tag_filename;
   }
   gtag_filelist_project._makeempty();
   tag_filelist=project_tags_filename();
   for (;;) {
      tag_filename = parse_tag_file_name(tag_filelist);
      if (tag_filename=='') {
         break;
      }
      gtag_filelist_project[gtag_filelist_project._length()]=tag_filename;
   }
   gtag_filelist_cache_updated=true;
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
_command int setEclipseTagFiles(_str params="")
{
    _str tag_filename;
    _str tag_filelist;
    _str filelist;
    _str ext;
    _str tf_lang = '';
    gEclipseTags = params;
    parse params with ext ',' filelist;
    eclipseExtMap:[ext]._makeempty();
    for (;;) {
       parse filelist with tag_filename"\n"tag_filelist;
       if (tag_filename=='') {
          break;
       }
       filelist = tag_filelist;
       if(ext == ''){
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
          int status = tag_read_db(maybe_quote_filename(tag_filename));
          if (status >= 0) {
             eclipseExtMap:[ext][eclipseExtMap:[ext]._length()] = tag_filename;
          } else {
             _str config = _ConfigPath();
             _maybe_append_filesep(config);
             _str temp_tag_filename = config :+ "tagfiles" :+ FILESEP :+ tag_filename; 
             status = tag_read_db(maybe_quote_filename(temp_tag_filename));
             if (status >= 0) {
                eclipseExtMap:[ext][eclipseExtMap:[ext]._length()] = temp_tag_filename;
             }
          }
       }
          
    }

    javaTagFiles := _replace_envvars(LanguageSettings.getTagFileList('java'));
    if (javaTagFiles != "") {
       for (;;) {
          parse javaTagFiles with auto temp ";" javaTagFiles;
          if (temp =='') {
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
   _str _ret = '';
   int i;
    for (i = 0; i < eclipseExtMap:[ext]._length(); i++) {
       _ret = _ret:+eclipseExtMap:[ext][i]:+ PATHSEP;
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
_command int removeEclipseTagFile(_str tag_filename = "")
{
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


_command testseteclipse()
{
   setEclipseTagFiles("java,c:\\foo\\b.c.d\\mytag.vtg\nd:\\aew\\yourtag.vtg");
   showtaglistext();
   removeEclipseTagFile("java,c:\\foo\\b.c.d\\mytag.vtg");
   showtaglistext();
}
_command showtaglistext()
{
   int i;
   STRARRAY fa = tags_filenamea(gtag_filelist_last_ext);
   for (i = 0; i < fa._length(); i++)
   {
      say(i+1".>"fa[i]"<");
   }
   say("**********************");
}

_command showtaglist()
{
   int i;
   STRARRAY fa = tags_filenamea();
   for (i = 0; i < fa._length(); i++)
   {
      say(i+1".>"fa[i]"<");
   }
   say("**********************");
}

/**
 * Return the array tag files associated with the given (optional) extension.
 * If the extension given is the empty string, and the current object is an
 * editor control, get the extension from the p_LangId property.
 * If the current object is not an editor control, retrieve all tag files
 * and project tag files, reguarless of extension relationship.
 *
 * @param ext      (optional) file extension (language) to get tags for
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
STRARRAY tags_filenamea(_str ext="")
{
   if (ext=="") {
      _update_tag_filelists();
      return(gtag_filelist);
   }
   _update_tag_filelist_ext(ext);

   return(gtag_filelist_ext);
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
_str tags_filename(_str lang="",boolean includeSlickC=true)
{
   int i=0;
   _str result="";
   _str tag_filename="";
   _str dummy="";
   static int in_tags_filename;
   if (!in_tags_filename) {
      in_tags_filename=1;
      if (lang!="") {
         _update_tag_filelist_ext(lang);
      } else {
         _update_tag_filelists();
      }
      in_tags_filename=0;
      if (gtag_filelist_cache_updated) {
         if (lang!="") {
            result="";
            for (i=0;i<gtag_filelist_ext._length();++i) {
               if (result=="") {
                  result=gtag_filelist_ext[i];
               } else {
                  result=result:+PATHSEP:+gtag_filelist_ext[i];
               }
            }
            return(result);
         } else if (includeSlickC) {
            result="";
            for (i=0;i<gtag_filelist._length();++i) {
               if (result=="") {
                  result=gtag_filelist[i];
               } else {
                  result=result:+PATHSEP:+gtag_filelist[i];
               }
            }
            //say(result);
            //say('optimize all tag files');

            return(result);
         }
      }
   }
   _str project_tagfiles='';

   // 4:25pm 6/18/1999
   // Had to change this piece from project to workspace
   // 4:55pm 6/25/2001
   // We don't need to filter out Slick-C&reg; files from the project list
   if (_workspace_filename!='' && (lang!='e' || includeSlickC)) {
      project_tagfiles=_strip_filename(_workspace_filename,'E'):+TAG_FILE_EXT:+PATHSEP;
   }
   _str filename=get_env(_SLICKTAGS);
   // Only use tag files which have files for the
   // correct extension
   if (lang!='') {
      // IF any global tag files to convert to extension specific
      if (filename!="") {
         if (project_tagfiles!="" && last_char(project_tagfiles)!=PATHSEP) {
            project_tagfiles=project_tagfiles:+PATHSEP;
         }
         project_tagfiles=project_tagfiles:+filename;
         filename="";  // Global tag files processed.
      }
      _str list=project_tagfiles;project_tagfiles="";
      // save the name of the 'original' open tag file
      _str orig_tag_db = tag_current_db();
      for (;;) {
         tag_filename = parse_tag_file_name(list);
         if (tag_filename=="") {
            break;
         }
         tag_filename=absolute(tag_filename);
         int status= tag_read_db(tag_filename);
         if ((status >= 0) && 
             (tag_current_version() <= VS_TAG_LATEST_VERSION) &&
             (tag_find_language(dummy,lang)==0 || 
              (lang=='tagdoc') ||
              (lang=='phpscript' && tag_find_language(dummy,'html')==0) ||
              (lang=='xml' && tag_find_language(dummy,'xsd')==0) ||
              (lang=='xml' && tag_find_language(dummy,'dtd')==0) ||
              (lang=='html' && tag_find_language(dummy,'tld')==0) ||
              (lang=='xmldoc' && tag_find_language(dummy,'xmldoc')==0)
             )) {
            if (project_tagfiles=="") {
               project_tagfiles=tag_filename;
            } else {
               project_tagfiles=project_tagfiles:+PATHSEP:+tag_filename;
            }
         }
         tag_reset_find_language();
      }
      // restore the 'current' tag file open for read
      if (orig_tag_db != '') {
         tag_read_db(orig_tag_db);
      }
   }
   if (project_tagfiles!="" && last_char(project_tagfiles)!=PATHSEP) {
      project_tagfiles=project_tagfiles:+PATHSEP;
   }

   // Are we running from Eclipse?  If so, we need to use the tag files
   // for each project
   //
   if (isEclipsePlugin()) {
      if (lang=='') {
         typeless e;
         for (e._makeempty();;) {
            eclipseExtMap._nextel(e);
            if (e._isempty()) {
               break;
            }
            for (i = 0; i < eclipseExtMap._el(e)._length(); i++) {
               if(filename != '' && last_char(filename) != PATHSEP) {
                  filename = filename :+ PATHSEP :+ eclipseExtMap._el(e)[i];
               } else {
                  filename = eclipseExtMap._el(e)[i];
               }
            }
         }

      } else if (eclipseExtMap._indexin(lang)) {
         for (i = 0; i < eclipseExtMap:[lang]._length(); i++) {
            if(filename != '' && last_char(filename) != PATHSEP) {
               filename = filename :+ PATHSEP :+ eclipseExtMap:[lang][i];
            } else {
               filename = eclipseExtMap:[lang][i];
            }
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
   langTagFileList := LanguageSettings.getTagFileList(lang);

   if (lang!="" && (langTagFileList != '' || _istagging_supported(lang))) {
      // check for project specific tag files
      if(lang == _project_extExtensions && _project_extTagFiles != '') {
         if(filename != '' && last_char(filename) != PATHSEP) {
            filename = filename :+ PATHSEP :+ _project_extTagFiles;
         } else {
            filename = _project_extTagFiles;
         }
      } else {
         if (!isEclipsePlugin() || isEclipsePlugin() && lang != "java") {
            langTagFileList=_replace_envvars(langTagFileList);
            if (langTagFileList!='') {
               if (filename=='') {
                  filename=langTagFileList;
               } else {
                  if (last_char(filename)==PATHSEP) {
                     filename=filename:+langTagFileList;
                  } else {
                     filename=filename:+PATHSEP:+langTagFileList;
                  }
               }
            }
         }
      }
   } else {
      _str langTagFileTable:[];
      LanguageSettings.getTagFileListTable(langTagFileTable);
      foreach (auto thisLangId => langTagFileList in langTagFileTable) {

         if(thisLangId == _project_extExtensions && _project_extTagFiles != '') {
            if(filename != '' && last_char(filename) != PATHSEP) {
               filename = filename :+ PATHSEP :+ _project_extTagFiles;
            } else {
               filename = _project_extTagFiles;
            }
         } else {
            langTagFileList = _replace_envvars(langTagFileList);
            if (langTagFileList!='' && ((includeSlickC && lang=="") || thisLangId != 'e')) {
               if (filename=='') {
                  filename=langTagFileList;
               } else {
                  if (last_char(filename)==PATHSEP) {
                     filename=filename:+langTagFileList;
                  } else {
                     filename=filename:+PATHSEP:+langTagFileList;
                  }
               }
            }
         }
      }
   }

   // if this is C/C++ or a derivative and they have selected a refactoring
   // configuration, also use the tag file associated with the refactoring
   // configuration
   _str compilerTagFile = '';
   _str cppTagFile = '';
   // We want the C++ compiler tag file for "c", but "d" and "googlego" derives from "c"
   // and should not use the C++ compiler tag file.
   // We also want the Java compiler tag file for Java, unless we
   // are in the Eclipse plugin (Core) because that has it's own
   // sort of JDK tagging.
   if ((_LanguageInheritsFrom("c", lang) && !(_LanguageInheritsFrom('d', lang) || _LanguageInheritsFrom('googlego', lang))) ||
       (_LanguageInheritsFrom("java", lang) && !isEclipsePlugin())) {
      compilerTagFile=compiler_tags_filename(lang);
   #if __UNIX__
      cppTagFile=_tagfiles_path():+"ucpp":+TAG_FILE_EXT;
   #else
      cppTagFile=_tagfiles_path():+"cpp":+TAG_FILE_EXT;
   #endif
      if (compilerTagFile != '') {
         if(filename != '' && last_char(filename) != PATHSEP) {
            filename = filename :+ PATHSEP :+ compilerTagFile;
         } else {
            filename = compilerTagFile;
         }
      }
   } else if (lang == "") {
      compilerTagFile=compiler_tags_filename("c");
      _maybe_append(filename,PATHSEP);
      filename = filename :+ compilerTagFile;

      compilerTagFile=compiler_tags_filename("java");
      _maybe_append(filename,PATHSEP);
      filename = filename :+ compilerTagFile;

      compilerTagFile=compiler_tags_filename("cs");
      _maybe_append(filename,PATHSEP);
      filename = filename :+ compilerTagFile;
   }

   /*if ( filename=='' ) {
      filename=SLICK_TAGS_DB;
   } */
   _str duplist=project_tagfiles:+filename;
   // Remove duplicate tag files
   _str list='';
   for (;;) {
      tag_filename = parse_tag_file_name(duplist);
      if (tag_filename=='') {
         break;
      }
      tag_filename=absolute(tag_filename);
      if (pos(PATHSEP:+tag_filename:+PATHSEP,PATHSEP:+list:+PATHSEP,1,_fpos_case)) {
         continue;
      }
      if (compilerTagFile!='' && file_eq(tag_filename,cppTagFile)) {
         continue;
      }
      if (list=='') {
         list=tag_filename;
      } else {
         list=list:+PATHSEP:+tag_filename;
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
   // check for tagfiles in the workspace that are auto updated and append
   // them to the list
   filename := "";
   if(_workspace_filename != "") {
      int autoUpdatedTagfileList[] = null;
      _WorkspaceGet_TagFileNodes(gWorkspaceHandle, autoUpdatedTagfileList);
      for(t := 0; t < autoUpdatedTagfileList._length(); t++) {
         _str autoUpdatedTagfile = _AbsoluteToWorkspace(_xmlcfg_get_attribute(gWorkspaceHandle, autoUpdatedTagfileList[t], "File"));
         if(lang == "") {
            // no extension so add all tagfiles
            if(filename != '' && last_char(filename) != PATHSEP) {
               filename = filename :+ PATHSEP :+ autoUpdatedTagfile;
            } else {
               filename = autoUpdatedTagfile;
            }
         } else {
            // make sure this tagfile contains files of this extension
            int status = tag_read_db(autoUpdatedTagfile);
            if ((status >= 0) && 
                (tag_current_version() <= VS_TAG_LATEST_VERSION) &&
                (tag_find_language(auto dummy,lang)==0 || 
                 (lang=="tagdoc") ||
                 (lang=='phpscript' && tag_find_language(dummy,'html')==0) ||
                 (lang=='xml' && tag_find_language(dummy,'xsd')==0) ||
                 (lang=='xml' && tag_find_language(dummy,'dtd')==0) ||
                 (lang=='html' && tag_find_language(dummy,'tld')==0) ||
                 (lang=='xmldoc' && tag_find_language(dummy,'xmldoc')==0)
                )) {
               if(filename != '' && last_char(filename) != PATHSEP) {
                  filename = filename :+ PATHSEP :+ autoUpdatedTagfile;
               } else {
                  filename = autoUpdatedTagfile;
               }
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
   // get the active compiler configuration from the project
   compiler_name := refactor_get_active_config_name(_ProjectHandle(),lang);
   if (compiler_name == "") {
      return "";
   }

   // put together the tag database file name, the file has to exist
   compilerTagFile := _tagfiles_path():+compiler_name:+TAG_FILE_EXT;
   if (!file_exists(compilerTagFile)) {
      return "";
   }

   // no point in returning a tag file we can't open
   status := tag_read_db(compilerTagFile);
   if (status < 0) {
      return "";
   }

   // this is an empty tag file, well, if that's what they want, fine
   if (tag_find_language(auto found_lang) < 0) {
      tag_reset_find_language();
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
         return "";
      }

      // put together the tag database file name, the file has to exist
      compilerTagFile = _tagfiles_path():+compiler_name:+TAG_FILE_EXT;
      if (!file_exists(compilerTagFile)) {
         return "";
      }

      // no point in returning a tag file we can't open
      status = tag_read_db(compilerTagFile);
      if (status < 0) {
         return "";
      }
   }

   // this compiler tag file is appropriate for this language
   tag_reset_find_language();
   return compilerTagFile;
}
/**
 * This function is obsolete.
 */
_str global_tags_filename(boolean doRelative=false)
{
   _str filename=get_env(_SLICKTAGS);
   /*if ( filename=='' ) {
      filename=SLICK_TAGS_DB;
   }*/
   return(AbsoluteList(filename));
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
int _set_listvar(_str name, _str list, boolean append=false)
{
   int index=find_index(name,MISC_TYPE);
   if (!index) {
      if (list!='') {
         insert_name(name,MISC_TYPE,list);
         return(1);
      }
   } else {
      if (list=='') {
         delete_name(index);
         return(1);
      } else {
         _str old_list=name_info(index);
         if (append) {
            // Append only works if items in same order or only adding one.
            if (!pos(PATHSEP:+list:+PATHSEP,PATHSEP:+old_list:+PATHSEP,1,_fpos_case)) {
               if (last_char(old_list)!=PATHSEP && old_list!='') {
                  old_list=old_list:+PATHSEP;
               }
               old_list=old_list:+list;
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
   boolean found_it=false;
   int index=find_index(name,MISC_TYPE);
   if (!index) {
      return 0;
   }

   _str new_list="";
   _str old_list=name_info(index);
   while (old_list != '') {
      _str file='';
      if (file_eq(xfile,old_list)) {
         file = old_list;
         old_list = "";
      } else if (file_eq(xfile:+PATHSEP, substr(old_list,1,length(xfile)+1))) {
         file = substr(old_list,1,length(xfile));
         old_list = substr(old_list,length(xfile)+2);
      } else {
         parse old_list with file PATHSEP old_list;
      }
      if (file_eq(file, xfile)) {
         found_it = true;
         continue;
      }
      if (new_list!='') strappend(new_list,PATHSEP);
      strappend(new_list, file);
   }

   if (!found_it) {
      return 0;
   }

   if (new_list == '') {
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
_command void set_exttagfiles(_str cmdline='',boolean append=false)
{
   set_lang_tagfiles(cmdline,append);
}
/**
 * Set the list of language specific tag files.
 *
 * @param cmdline   extension and list of tag files
 * @param append    Append the files to list, or start new list? 
 */
_command void set_lang_tagfiles(_str cmdline='',boolean append=false)
{
   _str ext,list;
   parse cmdline with ext list;
   if (ext=='') {
      return;
   }
   list=stranslate(list,'','"');
   if (substr(ext,1,1)=='.') {
      ext=substr(ext,2);
   }
   lang := _Ext2LangId(ext);
   if (lang == '') {
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
_command void remove_exttagfile(_str cmdline='')
{
   remove_lang_tagfile(cmdline);
}
/**
 * Remove a specific tag file from an extension's tag file list.
 *
 * @param cmdline   extension and tag file 
 */
_command void remove_lang_tagfile(_str cmdline='')
{
   _str ext,tagfile,list='';
   parse cmdline with ext tagfile;
   if (ext=='') {
      return;
   }
   tagfile=stranslate(tagfile,'','"');
   if (substr(ext,1,1)=='.') {
      ext=substr(ext,2);
   }
   lang := _Ext2LangId(ext);
   if (lang == '') {
      lang = _Ext2LangId(lowcase(ext));
   }
   tagfile=_encode_vsenvvars(tagfile,true,false);

   if (_remove_listvar('def-tagfiles-'lang, tagfile)) {
      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }
}
/**
 * Set up kill functions for the given file extension.
 * Kill functions are functions not displayed in auto-function-help.
 *
 * @param cmdline   extension and list of functions to add to kill list
 * @param append    Append the functions to list, or start new list? 
 *  
 * @deprecated Use {@link set_lang_kill_functions()} 
 */
_command void set_extkillfcts(_str cmdline='',boolean append=false)
{
   set_lang_kill_functions(cmdline,append);
}
/**
 * Set up kill functions for the given file extension.
 * Kill functions are functions not displayed in auto-function-help.
 *
 * @param cmdline   extension and list of functions to add to kill list
 * @param append    Append the functions to list, or start new list? 
 */
_command void set_lang_kill_functions(_str cmdline='',boolean append=false)
{
   _str ext,list;
   parse cmdline with ext list;
   if (ext=='') {
      return;
   }
   if (substr(ext,1,1)=='.') {
      ext=substr(ext,2);
   }
   lang := _Ext2LangId(ext);
   if (lang == '') {
      lang = _Ext2LangId(lowcase(ext));
   }
   if (_set_listvar('def-killfcts-'lang, list, append)) {
      _config_modify_flags(CFGMODIFY_DEFDATA);
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
_str project_tags_filename(boolean doRelative=false)
{
   if(isEclipsePlugin()){
      _str tagFile = '';
      int status = _eclipse_get_project_tagfile_string(tagFile);
      return tagFile;
      
   }
     //3:54pm 6/18/1999
      //Updating this to do workspace stuff...
      
      if (_workspace_filename=='') {
         return('');
      }
      return(_strip_filename(_workspace_filename,'E'):+TAG_FILE_EXT);
   /*_str project_tagfiles='';
   if (_project_name!='') {
      _ini_get_value(_project_name,"COMPILER","TAGFILES",project_tagfiles);
      project_tagfiles=_parse_project_command(project_tagfiles, '', _project_get_filename(),'');
      if (project_tagfiles=='') {
         project_tagfiles=strip_filename(_project_name,'E'):+TAG_FILE_EXT;
      }
   }
   if (!doRelative) {
      return(AbsoluteList(project_tagfiles));
   }
   return(project_tagfiles);*/
}
/**
 * @return
 * Return the list of include paths for the current project.
 *
 * @param doRelative  Allow relative paths, or convert to absolute?
 */
_str project_include_filepath(boolean doRelative=false)
{
   _str project_include='';
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
_str refs_filename(boolean doRelative=false)
{
   if (machine_bits()=='64') {
      return('');
   }
   _str filename;
   if (_project_name!='') {
      filename=_ProjectGet_RefFile(_ProjectHandle());
      //_ini_get_value(_project_name,"COMPILER."GetCurrentConfigName(),"REFFILE",filename);
      filename=_parse_project_command(filename,'',_project_get_filename(),'');
      if (filename!='') {
         filename=absolute(filename,_strip_filename(_project_name,'N'));
         if (file_eq(_get_extension(filename,1),BSC_FILE_EXT)) {
            if (file_match(filename' -p',1)=='') {
               filename='';
            }
         }
      }
   } else {
      // filename=get_env(_SLICKREFS);
      filename='';
   }
   if (filename=='') {
      return '';
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
   _str list='';
   _str TagFilename='';
   for (;;) {
      TagFilename = parse_tag_file_name(taglist);
      if (TagFilename=='') break;
      TagFilename=absolute(TagFilename);
      if (list=='') {
         list=TagFilename;
      } else {
         list=list:+PATHSEP:+TagFilename;
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
_str RemoveDupsFromPathList(_str taglist,boolean all_dirs=false)
{
   _str first,newlist=';';
   while (taglist != '') {
      parse taglist with first (PATHSEP) taglist;
      stranslate(first,'','"');
      if (last_char(first) != FILESEP && all_dirs) {
         strappend(first,FILESEP);
      }
      //first=maybe_quote_filename(first);
      if (!pos(PATHSEP:+_file_case(first):+PATHSEP,_file_case(newlist),1,'i')) {
         strappend(newlist,first:+PATHSEP);
      }
   }
   if (newlist!='') {
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
   _str next_tag_file_list=get_env(_SLICKTAGS);
   if (next_tag_file_list=="") {
      return;
   }
   /*
       Convert VSE <=2.0 tag file extensions to
       >=3.0 tag file extensions
   */
   _str new_tag_list="";
   _str tag_file='';
   for (;;) {
      tag_file = parse_tag_file_name(next_tag_file_list);
      if (tag_file=="" && next_tag_file_list=="") {
         break;
      }
      if(file_eq(_get_extension(tag_file),'slk')) {
         tag_file=_strip_filename(tag_file,'e')'.vtg';
      }
      if (new_tag_list=="") {
         new_tag_list=tag_file;
      } else {
         new_tag_list=new_tag_list:+PATHSEP:+tag_file;
      }
   }
   /*
       Convert global tag files to extension specific tag
       files.
   */
   _str list=new_tag_list;
   _str tag_filename='';
   for (;;) {
      tag_filename = parse_tag_file_name(list);
      if (tag_filename=="") {
         break;
      }
      tag_filename=absolute(tag_filename);
      int status= tag_read_db(tag_filename);
      if (status >= 0) {
         // get the files from the database
         _str srcfilename='';
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
   // Delete this environment variable from the vslick.ini file
   typeless new_tag_file_list;
   new_tag_file_list._makeempty();
   _ConfigEnvVar(_SLICKTAGS,new_tag_file_list);

   // Delete this environment variable
   set_env(_SLICKTAGS);

   _config_modify_flags(CFGMODIFY_DEFDATA);
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
   _str alias_file='';
   for (;;) {
      parse next_tag_file_list with alias_file (PATHSEP) next_tag_file_list;
      _str first_ch=substr(alias_file,1,1);
      if ( alias_file==''  ) {
         return('');
      }
      if ( first_ch=='+' || first_ch=='-' ) {
         _str second_ch=upcase(substr(alias_file,2,1));
         /* Search recursively up the directory tree for all alias.slk files. */
         if ( second_ch=='R' ) {
            parse alias_file with . alias_file ;
            alias_file=absolute(alias_file);
            _str path=substr(alias_file,1,pathlen(alias_file));
            _str next_file=absolute(path'..'FILESEP:+substr(alias_file,pathlen(alias_file)+1));
            if ( next_file!=alias_file ) {
               next_tag_file_list='+R 'next_file:+PATHSEP:+next_tag_file_list;
            } else {
               continue;
            }
         } else {
            messageNwait(nls('Invalid option in alias file list: %s',alias_file));
            return('');
         }
      }
      if ( file_match('-p 'maybe_quote_filename(alias_file),1)!='' ) {
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
_str next_tag_filea(_str (&list)[],int &i,boolean checkFiles=true,boolean openFileRead=false)
{
   for (;;) {
      if (i>=list._length()) {
         return("");
      }
      _str tag_file=list[i];++i;
      // need to check files?
      if (checkFiles && file_match('-p 'maybe_quote_filename(tag_file),1)=='') {
         // tag file doesn't exist, try .vtg extension instead of .slk
         if(!file_eq(_get_extension(tag_file),'slk')) {
            continue;
         }
         tag_file=_strip_filename(tag_file,'e')'.vtg';
         if ( file_match('-p 'maybe_quote_filename(tag_file),1)=='' ) {
            continue;
         }
      }
      // if requested, open tag file for read access, otherwise just return it
      if (!openFileRead || tag_read_db(tag_file) >= 0) {
         return(tag_file);
      }
   }
}

_str parse_tag_file_name(_str &tag_filelist, _str ext=".vtg")
{
   // parse up to the path seperator.  This should be the file name
   parse tag_filelist with auto tag_file (PATHSEP) tag_filelist;

   // if the file name ends with .vtg, or there is no more to parse, or the file exists
   // then we automatically can assume this is a complete tag file name.
   if (tag_filelist == "" || endsWith(tag_file,ext,false,'i') || file_exists(tag_file)) {
      return tag_file;
   }

   // if the tag file name contains path seperators, then it might get truncated.
   // parse forward to the next path seperator and check for a completion.
   parse tag_filelist with auto tag_file_rest (PATHSEP) auto tag_filelist_rest;
   for (;;) {
      // if what we find ends with .vtg or the file exists on disk, then count it as a tag file.
      // be a bit liberal with case-sensitivity, we are just verifying after all.
      if (endsWith(tag_file_rest,ext,false,'i') || file_exists(tag_file:+PATHSEP:+tag_file_rest)) {
         tag_filelist = tag_filelist_rest;
         return tag_file:+PATHSEP:+tag_file_rest;
      }
      // if we run off the end of the list, stop and give up
      if (tag_filelist_rest == "") {
         break;
      }
      // get the next segment form the tag file name
      parse tag_filelist_rest with auto tag_file_more (PATHSEP) tag_filelist_rest;
      tag_file_rest = tag_file_rest:+PATHSEP:+tag_file_more;
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
_str next_tag_file2(_str &next_tag_file_list,boolean checkFiles=true,boolean openFileRead=false)
{
   for (;;) {
      //say('next_tag_file_list='next_tag_file_list);
      _str tag_file = parse_tag_file_name(next_tag_file_list);
      //say('tag_file='tag_file);
      // end of list?
      if (tag_file=='') {
         return '';
      }
      // need to check files?
      if (checkFiles && file_match('-p 'maybe_quote_filename(tag_file),1)=='') {
         // tag file doesn't exist, try .vtg extension instead of .slk
         if(!file_eq(_get_extension(tag_file),'slk')) {
            continue;
         }
         tag_file=_strip_filename(tag_file,'e')'.vtg';
         if ( file_match('-p 'maybe_quote_filename(tag_file),1)=='' ) {
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
_str next_tag_file(_str tag_file_list,boolean find_first,boolean checkFiles=true,boolean openFileRead=false)
{
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
   if ( tag_files=='' ) {
      messageNwait(nls('No tag files found.  Press any key to continue'));
      return(1);
   }
   _str filename = next_tag_file2(tag_files,true,true);
   if ( filename=='' ) {
      messageNwait(nls('Tag files missing or corrupt: %s.  Press any key to continue',tag_files));
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
void _aremove_duplicates(_str (&list)[],boolean IgnoreCase)
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
static int prompt_user(_str (&taglist)[],_str (&filelist)[],int (&linelist)[],_str &tagname,_str &filename,_str more_caption='')
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
   _aremove_duplicates(list,0);
   //messageNwait("prompt_user: len="taglist._length());
   if (list._length()>=2) {
      _str option='-reinit';
      if (_find_object('_sellist_form')) {
         option='-new';
      }
      tagname=show('_sellist_form -mdi -modal 'option,
                  nls("Select a Tag Name %s",more_caption),
                  SL_SELECTCLINE,
                  list,
                  '',
                  '',  // help item name
                  '',  // font
                  ''   // Call back function
                 );
   } else {
      tagname=list[0];
   }
   if (tagname=="") {
      return(COMMAND_CANCELLED_RC);
   }
   _str proc_name='',dc,dt;int df;
   tag_tree_decompose_tag(tagname,proc_name,dc,dt,df);
   int status=0;
   // Now that the exact tag and tag type has been selected,
   // we can remove other types
   int i,j;
   for (i=0;i<taglist._length();++i) {
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

   // float files from current project to the top of the list
   // don't bother if current buffer isn't in project
   _str tagfilename=project_tags_filename();
   if (tagfilename!='' && tag_read_db(tagfilename)>=0) {
      int found=0;
      for (i=0;i<filelist._length();++i) {
         if (tag_find_file(filename,filelist[i])==0) {
            for (j=i; j>found; --j) {
               filelist[j]=filelist[j-1];
            }
            filelist[found++]=filename;
         }
      }
      tag_reset_find_file();
   }

   // force current buffer to the top of the list
   if (_isEditorCtl()) {
      for (i=0;i<filelist._length();++i) {
         if (file_eq(filelist[i],p_buf_name)) {
            for (j=i; j>0; --j) {
               filelist[j]=filelist[j-1];
            }
            filelist[0]=p_buf_name;
            break;
         }
      }
   }

   if ( filelist._length()>1 ) {
      _str option='-reinit';
      if (_find_object('_sellist_form')) {
         option='-new';
      }
      filename=show('_sellist_form -mdi -modal 'option,
                  nls('Select a File with "%s"',proc_name),
                  SL_SELECTCLINE,
                  filelist,
                  '',
                  '',        // help item name
                  '',                    // font
                  ''   // Call back function
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
static boolean gTagFilesThatCantBeRebuilt:[];

/**
 * Maybe build a tag file for the given file extension.  This takes
 * advantage of the built-in _[ext]_maybeBuildTagFile callbacks, and
 * will automatically build the tag file for that extension if possible.
 * <P>
 * In addition, this function cycles through all the tag files in the
 * current extension and makes sure that they are up-to-date, if they
 * are not, it will automatically rebuild the tag file.
 *
 * @param   lang     Language ID, see {@link p_LangId}
 * 
 * @categories Tagging_Functions
 */
void MaybeBuildTagFile(_str lang='', boolean with_refs=false)
{
   // do not let this happen from a timer
   if (autosave_timer_running() || mousemove_handler_running()) {
      return;
   }
   //messageNwait('p_LangId='p_LangId);
   if (lang=='' && _isEditorCtl()) lang=p_LangId;
   int tfindex=0;
   int index=find_index('_'lang'_MaybeBuildTagFile',PROC_TYPE);
   if (index_callable(index)) {
      if (!isdirectory(_tagfiles_path())) {
         mkdir(_tagfiles_path());
      }
      // verify that we have "maketags" available
      _str slickc_filename=path_search('maketags'_macro_ext,'VSLICKMACROS');
      if (slickc_filename=="") {
         slickc_filename=path_search('maketags'_macro_ext'x','VSLICKMACROS');
      }
      if (slickc_filename!='') {
         call_index(tfindex,with_refs,index);
      }
   }
   typeless tag_files=tags_filenamea(lang);
   int i=0;
   int Noffiles=0;
   _str tag_filename = next_tag_filea(tag_files, i, false, true);
   while (tag_filename != '') {
      if (tag_filename!="") {
         if (tag_current_version() < VS_TAG_LATEST_VERSION &&
             !gTagFilesThatCantBeRebuilt._indexin(_file_case(tag_filename))) {
            // this tag file is out of date and needs to be rebuilt
            tag_get_detail(VS_TAGDETAIL_num_files,Noffiles);
            boolean generate_refs = (tag_get_db_flags() & VS_DBFLAG_occurrences) != 0;
            if (_IsAutoUpdatedTagFile(tag_filename)) {
               message(nls("Auto updated tag file has old version.  Use 'vsmktags' to regenerate '%s'.",tag_filename));
               gTagFilesThatCantBeRebuilt:[_file_case(tag_filename)] = true;
            } else {
               useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
               if (useThread || Noffiles < 4000) {
                  RetagFilesInTagFile(tag_filename,true,generate_refs,true,true,useThread,true);
               }
               if (useThread) delay(250);
               tag_read_db(tag_filename);
               if (tag_current_version() < VS_TAG_LATEST_VERSION) {
                  message(nls("Tag file '%s' has old version and cannot be rebuilt.",tag_filename));
                  gTagFilesThatCantBeRebuilt:[_file_case(tag_filename)] = true;
               }
            }
         }
      }
      tag_filename = next_tag_filea(tag_files, i, false, true);
   }
}
/**
 * @return
 * Return the standard path for storing language specific
 * builtins files.  If no file is found, return '';
 */
_str ext_builtins_path(_str ext, _str basename)
{
   // find the appropriate builtins file
   _str root_dir=get_env('VSROOT');
   // first try 'builtins' directory
   _str extra_file=root_dir'builtins'FILESEP:+basename'.tagdoc';
   if (file_exists(extra_file)) {
      return(extra_file);
   }
   extra_file=root_dir'builtins'FILESEP:+'builtins.'ext;
   if (file_exists(extra_file)) {
      return(extra_file);
   }
   // not there, try in VSROOT
   extra_file=root_dir:+basename:+'.tagdoc';
   if (file_exists(extra_file)) {
      return(extra_file);
   }
   extra_file=root_dir:+'builtins.'ext;
   if (file_exists(extra_file)) {
      return(extra_file);
   }
   return('');
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
   _str f=file_match('"'basepath'" +DP',1);
   while (f!='') {
      if (f>greatest) greatest=f;
      f=file_match('"'basepath': +DP',0);
   }
   if (greatest==basepath) return('');
   if (last_char(greatest)!=FILESEP) {
      greatest=greatest:+FILESEP;
   }
   return greatest;
}
/**
 * Return the standard path for storing tag files.
 */
_str _tagfiles_path()
{
   return _ConfigPath():+'tagfiles':+FILESEP;
}
/**
 * Return the path to the global tag files directory
 */
_str _global_tagfiles_path()
{
   return get_env('VSROOT'):+'tagfiles':+FILESEP;
}
/**
 * Generic function for building tag file when the only thing
 * to tag is one builtin's function.
 *
 * @param tfindex      (reference) index of def_tagfiles_[ext]
 * @param ext          file extension
 * @param basename     base name of extension specific tagfile
 * @param description  tag file description
 *
 * @return 0 on success, <0 on error.
 */
int ext_MaybeBuildTagFile(int &tfindex, _str ext, _str basename, _str description)
{
   // maybe we can recycle tag file
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,basename)) {
      return(0);
   }

   // run maketags and tag just the builtins file.
   _str extra_file=ext_builtins_path(ext, basename);
   if (extra_file=='' || !file_exists(extra_file)) {
      return(1);
   }
   return ext_BuildTagFile(tfindex,tagfilename,ext,description,
                           false,'',extra_file);
}
/**
 * Generic function for recycling an extension specific tag file.
 * If a tag file is found in the global configuration directory,
 * and the expected name matches, it is added to def_tagfiles_[ext]
 * for the given file extension.
 * <P>
 * Whether this function succeeds or not, 'tfindex' and 'tagfilename'
 * will be set appropriately upon return.
 * <P>
 * If this function returns true, then we can assume that the
 * extension specific automatically built tag file for the given
 * extension is already set up, so there is nothing more to do.
 * <P>
 * If this function returns false, the tag file needs to be built
 * (or rebuilt).
 *
 * @param tfindex      (reference) index of def_tagfiles_[ext]
 * @param tagfilename  (reference) path to extension tag file
 * @param ext          file extension
 * @param basename     base name of extension specific tagfile
 *
 * @return true if tag file was already set up or recycled
 *         for this extension, otherwise return false
 */
boolean ext_MaybeRecycleTagFile(int &tfindex, _str &tagfilename,
                                _str ext, _str basename)
{
   // look up tag files for this extension
   _str name_part=basename:+TAG_FILE_EXT;
   tagfilename=absolute(_tagfiles_path():+name_part);

   // just return if the tag file is already set up
   langTagFileList := LanguageSettings.getTagFileList(ext);
   if (pos(name_part,langTagFileList,1,_fpos_case)) {
      // tag file doesn't exist?  then return false
      if (tagfilename=='' || tag_read_db(tagfilename)==FILE_NOT_FOUND_RC) {
         return(false);
      }
      // status==0, or we have unhandled error opening tag file
      return(true);
   }

   // is there a tag file matching the name we are looking for
   // in the user or global configuration directory?
   if (tagfilename=='' || tag_read_db(tagfilename) < 0) {
      // do not go after global tag file if they want local state
      // for performance, or if it is the same directory again
      if (/*def_localsta ||*/ file_eq(_tagfiles_path(),_global_tagfiles_path())) {
         return(false);
      }
      // try to find the global tag file
      tagfilename = absolute(_global_tagfiles_path():+name_part);
      if (tagfilename=='' || tag_read_db(tagfilename) < 0) {
         tagfilename=absolute(_tagfiles_path():+name_part);
         return(false);
      }
   }

   // set up the tag file path
   message("Adding tag file "tagfilename"...");
   LanguageSettings.setTagFileList(ext, tagfilename, true);
   tfindex=find_index('def-tagfiles-'ext,MISC_TYPE);
   message("Added tag file "tagfilename);

   // that's all folks
   return(true);
}
/**
 * Utility function for building a tag file, calls maketags for you and
 * does the other dirty work, such as setting the tag file path, invoking
 * the callbacks, and setting _config_modify.
 *
 * @param tfindex      (reference) index of def_tagfiles_[ext]
 * @param tagfilename  path to extension tag file
 * @param ext          file extension
 * @param tagfiledesc  description of tag file
 * @param recursive    search for matches recursively under path1 and path2?
 * @param path_list    list of file paths or wildcards to pass to maketags
 * @param extra_file   path to 'builtins' file
 *
 * @return 0 on success, nonzero on error
 */
int ext_BuildTagFile(int &tfindex,_str tagfilename,_str ext,_str tagfiledesc,
                     boolean recursive,_str path_list,_str extra_file='')
{
   // close the tagfile before rebuilding it if it is open
   tag_close_db(tagfilename);

   // run maketags
   _str tree_opt = (recursive)? '-t':'';
   int status=shell('maketags 'tree_opt' -c ':+
                    '-n "'tagfiledesc'" -o ' :+
                    maybe_quote_filename(tagfilename)' 'path_list);

   // quote the extra file, and make sure it exists.
   if (!status && extra_file!='') {
      status=shell('maketags -r -o ' :+
                   maybe_quote_filename(tagfilename)' ' :+
                   maybe_quote_filename(extra_file));
   }

   // set def-tagfiles-ext
   LanguageSettings.setTagFileList(ext, tagfilename, true);
   tfindex = find_index('def-tagfiles-'ext, MISC_TYPE);

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
 * <DT>E<DD>Case-sensitive match
 * <DT>I<DD>Case-insensitive match
 * <DT>R<DD>use SlickEdit regular expressions
 * <DT>U<DD>use Unix regular expressions
 * <DT>B<DD>use Brief regular expressions
 * <DT>L<DD>use Perl regular expressions
 * <DT>&<DD>use SlickEdit wildcard (filename) expressions
 * <DT>A<DD>Search all tag files, not just the workspace tag file.
 * <DT>P<DD>Limit search to the current project only
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
_command grep_tag,gt(_str search_str='', _str options="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   int i,n;
   _str lang='';
   _str tag_name='';
   boolean context_found=false;
   tag_push_matches();

   // Default search options for case and re etc. not used when
   // this function is called with two arguments. This is so that
   // user defined keyboard macros work correctly when default
   // search options are changed.
   if ( arg() <= 1 || options=="") {
      if (search_str=='') {
         message(nls('Usage: gt/tag_name_regex/search_options'));
         tag_pop_matches();
         return(1);
      }
      _str delim='';
      orig_search_str := search_str;
      parse search_str with  1 delim +1 search_str (delim) options;
      if (isalnum(delim) || delim=='_') {
         search_str=orig_search_str;
         options='';
      }
   }
   options=upcase(options);
   boolean project_only=(pos('P',options)>0);
   boolean find_all=(pos('A',options)>0);
   if (find_all || project_only) {
      options=stranslate(options,'','A');
      options=stranslate(options,'','P');
   }
   if (!pos('^[eirubyapl&]*$',options,1,'ri')) {
      _message_box(get_message(INVALID_ARGUMENT_RC));
      tag_pop_matches();
      return(INVALID_ARGUMENT_RC);
   }

   int embedded_status=0;
   typeless orig_values;
   mou_hour_glass(1);
   if (_isEditorCtl()) {
      // we are an editor control, so search locals and context
      embedded_status = _EmbeddedStart(orig_values);
      lang=p_LangId;
      MaybeBuildTagFile(lang);
      _UpdateContext(true);
      _UpdateLocals(true);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      sentry.lockMatches(true);

      // get matches from locals
      message("searching context:");
      n=tag_get_num_of_locals();
      for (i=1; i<=n; i++) {
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

   int status=0;
   i=0;
   typeless tag_files;
   if (find_all || lang=='e') {
      tag_files=tags_filenamea(lang);
   } else {
      _str a[];
      a[0]=_GetWorkspaceTagsFilename();
      tag_files=a;
   }
   _str tag_filename = next_tag_filea(tag_files, i, false, true);
   while (tag_filename!='') {
      message("searching "tag_filename":");
      status = tag_find_regex(search_str, options);
      while (!status) {
         boolean foundInProject=true;
         if (project_only) {
            _str file_name='';
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
   mou_hour_glass(0);
   clear_message();

   // save current selection
   typeless mark='';
   if ( _select_type()!='' ) {
      mark=_duplicate_selection();
      if ( mark<0 ) {
         tag_pop_matches();
         return(NOT_ENOUGH_MEMORY_RC);
      }
   }

   // prompt for which tag to go to
   VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   status = tag_select_symbol_match(cm);
   if (status == BT_RECORD_NOT_FOUND_RC) {
      if (_MaybeRetryTaggingWhenFinished()) {
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
   if ( mark!='' ) {
      int old_mark=_duplicate_selection('');
      _show_selection(mark);
      _free_selection(old_mark);
   } else {
      _deselect();
   }

   // that's all folks
   tag_pop_matches();
   return(status);
}
int _resolve_include_file(_str &filename) 
{
   _str match= strip(filename, 'B', '"');
   match = strip(match, 'B', "'");
   filename = match;
   boolean isHTTPFile=false;
   if ( filename!='' && (!iswildcard(filename) || file_exists(filename)) ) {
      //messageNwait('filename='filename);
      isHTTPFile=_isHTTPFile(filename) != 0;
      if (!isHTTPFile && _FileQType(p_buf_name)==VSFILETYPE_URL_FILE &&
          // This is not an absolute path
           !(isdrive(substr(filename,1,2)) ||
            substr(filename,1,1)=='/' || substr(filename,1,1)=='\'
           )
          ) {
         isHTTPFile=true;
         //say('p_DocumentName='p_DocumentName);
         _str path=_strip_filename(translate(p_DocumentName,FILESEP,FILESEP2),'N');
         filename=translate(path,'/','\'):+filename;
      }
      match=filename;
      if (!isHTTPFile) {
         match=file_match2(filename,1,'-pd');
         if ( match=='' ) {
            match=file_match2(_strip_filename(p_buf_name,'N'):+filename,1,'-pd');
            if ( match=='' ) {
               _str ext=_get_extension(p_buf_name);
               if ( file_eq('.'ext,_macro_ext) || file_eq(ext,'cmd') ) {
                  _str info=get_env('VSLICKINCLUDE');
                  if (info!='') {
                     match=include_search(filename,info);
                  }
               }
               if (match=='') {
                  _str info=_ProjectGet_IncludesList(_ProjectHandle(),_project_get_section(gActiveConfigName));
                  info=_absolute_includedirs(info, _project_get_filename());
                  match=include_search(filename,info);
                  // DJB (11-06-2006) -- last ditch effort, check refactoring
                  // compiler configuration for include paths to search
                  if (_LanguageInheritsFrom('c') && match=='') {
                     _str header_file = "";
                     _str compiler_includes    = "";
                     int compiler_status = refactor_get_active_config(header_file, compiler_includes, _ProjectHandle());
                     if (!compiler_status) {
                        match=include_search(filename,compiler_includes);
                     }
                  }
#if __UNIX__
                  if (_LanguageInheritsFrom('c') && match=='') {
                     match=include_search(filename,'/usr/include/');
                  }
#endif
               }
            }
         }
#if 0
         // Clark.  Made these changes to fix something but
         // I don't remember the test case.  Now that I'm looking at this
         // code again, it does not make sense so I have pulled this
         // change for now.
         match=file_match2(absolute(filename,strip_filename(p_buf_name,'N')),1,'-pd');
         if ( match=='' ) {
            lang=get_extension(p_buf_name);
            if ( file_eq('.'lang,_macro_ext) || file_eq(lang,'cmd') ) {
               info=get_env('VSLICKINCLUDE');
               if (info!='') {
                  match=include_search(filename,info);
               }
            }
            if (match=='') {
               info=_ProjectGet_IncludesList(_ProjectHandle(),_project_get_section(gActiveConfigName));
               info=_absolute_includedirs(info, _project_get_filename());
               match=include_search(filename,info);
            }
         }
         if (match=='') {
            match=file_match2(filename,1,'-pd');
         }
#endif
         // if not found, try searching the entire workspace
         if (match=='') {
            match=_ProjectWorkspaceFindFile(filename, false);
         }
         // if still not found, try prompting for path
         if (match=='') {
            static _str last_dir;
            if (last_dir!='' && file_exists(last_dir:+filename)) {
               match=last_dir:+filename;
            } else {
               _str found_dir=_strip_filename(filename,'N');
               _str just_filename = _strip_filename(filename,'P');
               _str found_filename = _ChooseDirDialog("Find File", found_dir, just_filename);
               if (found_filename=='') {
                  return(COMMAND_CANCELLED_RC);
               }
               match=found_filename:+just_filename;
               last_dir=found_filename;
            }
         }
      }
   }
   if ( match!='' ) {
      filename=match;
      return(0);
   }
   _message_box(nls("File '%s' not found",filename));
   return(FILE_NOT_FOUND_RC);
}

int tag_get_current_include_info(VS_TAG_BROWSE_INFO &cm) 
{
   tag_browse_info_init(cm);
   cm.line_no= -1;  // Don't do goto line
   typeless orig_values;
   embedded := _EmbeddedStart(orig_values);
   _str lang=p_LangId;
   int status=0;
   orig_line_no := p_line;
   if (_LanguageInheritsFrom('cob')) {
      // first get the project include file path
      _str cobol_copy_path=get_cobol_copy_path();
      // search for copy book include statements
      typeless p;
      save_pos(p);
      _begin_line();
      status=search('((include|copy|[-]INC|[%]INCLUDE|[+][+]INCLUDE)[ \t]+{"?+"|[~ \t]+}([ \t]|$))|$','@rih');
      if (p_line != orig_line_no) status = STRING_NOT_FOUND_RC;
      int color=_clex_find(0,'g');
      restore_pos(p);
      if (!status && color==CFG_KEYWORD && match_length()) {
         _str word=get_match_text(0);
         if (last_char(word)=='.') {
            word=substr(word,1,length(word)-1);
         }
         _str filename='';
         if (pathlen(p_buf_name)) {
            _str temp=_strip_filename(p_buf_name,"n"):+word;
            filename=path_search(temp,cobol_copy_path,"v",". .cbl .cob .cpy .cobol .if .ocb");
         }
         if (filename=='') {
            filename=path_search(word,cobol_copy_path,"v",". .cbl .cob .cpy .cobol .if .ocb");
         }
         if (filename!='') {
            _str result_dir = _strip_filename(filename,'N');
            if (upcase(result_dir) :== result_dir) {
               _str result_file = _strip_filename(filename,'P');
               split(cobol_copy_path,PATHSEP,auto paths);
               int i = 0;
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
   } else if (_LanguageInheritsFrom('asm390')) {
      // first get the project include file path
      _str cobol_copy_path=get_asm390_macro_path();
      // search for copy book include statements
      typeless p;
      save_pos(p);
      _begin_line();
      status=search('((include|copy)[ \t]+{"?+"|[~ \t]+}([ \t]|$))|$','@rih');
      if (p_line != orig_line_no) status = STRING_NOT_FOUND_RC;
      int color=_clex_find(0,'g');
      restore_pos(p);
      if (!status && color==CFG_KEYWORD && match_length()) {
         _str word=get_match_text(0);
         if (last_char(word)=='.') {
            word=substr(word,1,length(word)-1);
         }
         _str temp;
         _str filename='';
         if (pathlen(p_buf_name)) {
            temp=_strip_filename(p_buf_name,"n"):+word;
            filename=path_search(temp,cobol_copy_path,"v",". .asm390 .asm .s");
         }
         if (filename=='') {
            filename=path_search(temp,cobol_copy_path,"v",". .asm390 .asm .s");
         }
         if (filename!='') {
            cm.file_name=filename;
            if (embedded == 1) {
               _EmbeddedEnd(orig_values);
            }
            return(0);
         }
      }
   } else if (_LanguageInheritsFrom('ant')) {
      // see if the statement under the cursor is a file (wholesaled from cursor_error2) 
      _str http_extra='http\:/|ttp\:/|tp\:/|p\:/|\:/|/|';
      save_pos(auto p);
      search(':q|('http_extra'\:|):p|^','rh-');
      restore_pos(p);
      _str fn=get_match_text();
      fn=strip(fn,'B',"'");
      fn=maybe_quote_filename(fn);
      // if we are on an xml file, jump to it
      _str proc_name = cur_word(auto sc);
      if (fn != "" && _get_extension(fn) == "xml" && !_ant_CursorOnProperty(proc_name, sc)) {
         cm.file_name = fn;
         return(0);
      }
   } else if (_LanguageInheritsFrom('pl1')) {
      // first get the project include file path
      project_include_path := "";
      if (_project_name != '') {
         project_include_path = project_include_filepath();
      }
      // now check the def var
      if (def_pl1_include_path!='') {
         if (project_include_path!='' && last_char(project_include_path)!=PATHSEP) {
            strappend(project_include_path,PATHSEP);
         }
         strappend(project_include_path,def_pl1_include_path);
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
         if (word == '') {
            word = word1;
         }
         word = strip(word);
         if (last_char(word)=='.') {
            word=substr(word,1,length(word)-1);
         }
         filename := "";
         if (pathlen(p_buf_name)) {
            project_include_path = project_include_path :+ PATHSEP :+ _strip_filename(p_buf_name,"n");
         }
         filename=path_search(word,project_include_path,"v",get_file_extensions_sorted_with_dot('pl1'));
         if (filename!='') {
            cm.file_name=filename;
            if (embedded == 1) {
               _EmbeddedEnd(orig_values);
            }
            return(0);
         }
      }
   } else if (_LanguageInheritsFrom('java') && _ProjectGet_AppType(_ProjectHandle()) == 'android') {
      // for symbols from the R class, check if we have only 1 match which is in R.java
      // if that is the case, this symbol might reference a resource file
      // we can then check to see if we have an appropriately named resource file 
      VS_TAG_IDEXP_INFO idexp_info;
      tag_idexp_info_init(idexp_info);
      struct VS_TAG_RETURN_TYPE visited:[];
      status = _Embeddedget_expression_info(false, 'java', idexp_info, visited);
      if (!status) {
         if (pos('R.',idexp_info.prefixexp) == 1) {
            context_found := context_find_tag(idexp_info.lastid);
            if (context_found && tag_get_num_of_matches() == 1) {
               VS_TAG_BROWSE_INFO im;
               tag_get_match_info(1,im);
               if (im.file_name && _strip_filename(im.file_name,'P') == 'R.java') {
                  _str full_file = _ProjectWorkspaceFindFile(idexp_info.lastid'.xml');
                  if (full_file != '') {
                     cm.file_name = full_file;
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
   if (line=='') {
      if (embedded == 1) {
         _EmbeddedEnd(orig_values);
      }
      return(FILE_NOT_FOUND_RC);
   }

   // Get multiple lines of text so multi-line error matches work.
   int index=find_index('def-'lang'-include',MISC_TYPE);
   if (index) {
      _str include_re=name_info(index);
      if (pos(include_re,line,1,'ri')) {
         _str filename=substr(line,pos('S0'),pos('0'));
         if (filename!='') {
            if (file_eq(lang,'pas') && _get_extension(filename)=='') {
               filename=filename'.pas';
            }
            cm.file_name=filename;
            _str file_line=substr(line,pos('S1'),pos('1'));
            if (_LanguageInheritsFrom('c') && isnumber(file_line)) {
               cm.line_no=(int)file_line;
            }
            return(0);
         }
      }
   }
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   MaybeBuildTagFile(p_LangId);
   if (context_id > 0 && _clex_find(0,'g')!=CFG_COMMENT) {
      int include_line=0;
      _str include_path='';
      _str type_name='';
      tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
      tag_get_detail2(VS_TAGDETAIL_context_line,context_id,include_line);
      if (type_name=='include' && p_line==include_line) {
         tag_get_detail2(VS_TAGDETAIL_context_return,context_id,include_path);
         if (include_path != '' && file_match(maybe_quote_filename(include_path),1)!='')  {
            if (embedded == 1) {
               _EmbeddedEnd(orig_values);
            }
               // This should be an absolute path.
            cm.file_name=include_path;
            return(0);
         }
         tag_get_detail2(VS_TAGDETAIL_context_name,context_id,include_path);
         if (include_path != '' && _istagging_supported(p_LangId)) {
            if (embedded == 1) {
               _EmbeddedEnd(orig_values);
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
 * <dt>case</dt>     <dd>Go to the begging of the current switch statement</dd>
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
static int tag_get_continue_or_break_info(int &line_no, long &seek_pos) 
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
      {
         // just go to the end of the current function
         _UpdateContext(true);
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
            _UpdateContext(true,false,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
            int statement_id = tag_current_statement();
            if (statement_id > 0) {
               // first we parse out the target label from the statement information
               tag_get_detail2(VS_TAGDETAIL_context_type, statement_id, auto statement_type);
               tag_get_detail2(VS_TAGDETAIL_context_name, statement_id, auto statement_name);
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, statement_id, auto goto_case_start);
               parse statement_name with "goto" auto goto_case_name;
               goto_case_name = strip(goto_case_name):+":";

               // now we find our enclosing switch statement
               while (statement_id > 0) {
                  tag_get_detail2(VS_TAGDETAIL_context_type, statement_id, statement_type);
                  tag_get_detail2(VS_TAGDETAIL_context_name, statement_id, statement_name);
                  if (statement_type=="if" && substr(statement_name, 1, 6)=="switch") {
                     // now iterate forward until we either pass the switch statement
                     // or we find a matching case statement
                     tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, statement_id, auto switch_end_seekpos);
                     case_id := statement_id+1;
                     loop {
                        // past end of context items?
                        if (case_id > tag_get_num_of_context()) {
                           break;
                        }
                        // past the end of the switch statement, oh brother
                        tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, case_id, auto case_start_seekpos);
                        if (case_start_seekpos > switch_end_seekpos) {
                           break;
                        }
                        // check that this case statement matches the outer switch
                        tag_get_detail2(VS_TAGDETAIL_context_outer, case_id, auto case_outer_id);
                        if (case_outer_id == statement_id) {
                           // check if the case name matches the target 
                           // or if they are just trying to jump to the next case
                           tag_get_detail2(VS_TAGDETAIL_context_name,  case_id, auto case_name);
                           case_name = strip(case_name);
                           if (case_name == goto_case_name ||
                              (goto_case_name=="case:" && case_start_seekpos > goto_case_start)) {
                              tag_get_context_info(case_id, auto cm);
                              line_no  = cm.line_no;
                              seek_pos = cm.seekpos;
                              return 0;
                           }
                        }
                        case_id++;
                     }
                     // we didn't find a matching case, drop back to
                     // just jumping to the top of the switch statement
                     tag_get_context_info(statement_id, auto cm);
                     line_no  = cm.line_no;
                     seek_pos = cm.seekpos;
                     return 0;
                  }
                  tag_get_detail2(VS_TAGDETAIL_context_outer, statement_id, statement_id);
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
         _UpdateContext(true,false,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
         int statement_id = tag_current_statement();
         while (statement_id > 0) {
            tag_get_detail2(VS_TAGDETAIL_context_type, statement_id, auto statement_type);
            tag_get_detail2(VS_TAGDETAIL_context_name, statement_id, auto statement_name);
            if ((statement_type == "loop") || 
                (statement_type=="if" && substr(statement_name, 1, 6)=="switch" && lastid=="break")) {
               tag_get_context_info(statement_id, auto cm);
               if (lastid=='continue' || lastid=='case') {
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
               tag_get_context_info(statement_id-1, auto prev_cm);
               if (prev_cm.type_name=="label" && prev_cm.member_name==label_name) {
                  return 0;
               }
            }
            tag_get_detail2(VS_TAGDETAIL_context_outer, statement_id, statement_id);
         }
      }
      break;

   case "case":
      {
         // Use statement tagging to find the matching block start/end for
         // break and continue.  
         _UpdateContext(true,false,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
         int statement_id = tag_current_statement();
         while (statement_id > 0) {
            tag_get_detail2(VS_TAGDETAIL_context_type, statement_id, auto statement_type);
            tag_get_detail2(VS_TAGDETAIL_context_name, statement_id, auto statement_name);
            if (statement_type=="if" && substr(statement_name, 1, 6)=="switch") {
               tag_get_context_info(statement_id, auto cm);
               line_no  = cm.line_no;
               seek_pos = cm.seekpos;
               return 0;
            }
            tag_get_detail2(VS_TAGDETAIL_context_outer, statement_id, statement_id);
         }
      }
      break;
   }

   return STRING_NOT_FOUND_RC;
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
 * 
 * @return Returns 0 if successful.  Otherwise, a non-zero value is returned.
 *
 * @appliesTo  Edit_Window
 * @see f
 * @see push_tag
 * @see find_proc
 * @see make_tags
 * @see gui_make_tags
 * @see gui_push_tag
 * 
 * @categories Tagging_Functions
 */
_command find_tag(_str params="", boolean quiet=false/*, int &outTempWID=null */) name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   /* Clark: SlickEdit Tools only. When edit is called, a temp view is created
      and the global variable def_msvsp_temp_wid is set.  The caller must
      initialize this Slick-C variable before calling this function.
   */
   // create a new match set
   tag_push_matches();

   int i;
   _str PrefixHashtable:[]=null;
   _str UriHashtable:[]=null;
   boolean context_found=false;
   int     context_id=0;

   // parse command line options
   _str tagfiles_ext='';
   boolean combine_slickc_and_c_tagfiles=false;
   boolean includeSlickC=false;
   boolean findAntTag=false;
   boolean onAntPropertyRef=false;
   boolean use_context_find=false;
   boolean force_case_sensitivity=false;
   _str option='',rest='';;
   for (;;) {
      parse params with option rest;
      if (lowcase(option)=='-e') {
         parse rest with tagfiles_ext params;
      } else if (lowcase(option)=='-sc') {
         combine_slickc_and_c_tagfiles=true;
         params=rest;
      } else if (lowcase(option)=='-is') {
         includeSlickC=true;
         params=rest;
      } else if (lowcase(option)=='-c') {
         use_context_find=true;
         params=rest;
      } else if (lowcase(option)=='-cs') {
         force_case_sensitivity=true;
         params=rest;
      } else {
         break;
      }
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // use Context Tagging(R) to find tag matches in current buffer
   VS_TAG_BROWSE_INFO cm;
   int embedded_status=0;
   typeless orig_values;
   int status=0;
   int view_id=0;
   _str lang='';
   _str proc_name=params;
   if ( params=='' ) {
      if( !_isEditorCtl()) {
         tag_pop_matches();
         return(1);
      }
      // see if the statement under the cursor is a #include or variant
      status=tag_get_current_include_info(cm);
      if (!status) {
         status=_resolve_include_file(cm.file_name);
         if (status) return(status);
         status=tag_edit_symbol(cm);
         return(status);
      }
      // see if the word under the cursor is a keyword that indicates a jump
      status=tag_get_continue_or_break_info(auto target_line=0, auto target_seek=0);
      if (!status) {
         if (target_line > 0) {
            p_RLine = target_line;
            _GoToROffset(target_seek);
         }
         if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
            expand_line_level();
         }
         return 0;
      }
      /* Try to find the procedure at the cursor. */
      _UpdateContext(true);
      context_id = tag_current_context();
      embedded_status = _EmbeddedStart(orig_values);
      MaybeBuildTagFile(p_LangId);

      // check if we are in an include tag and if we can jump
      // straight to it the include file
      context_found=context_find_tag(proc_name);

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
         int start_col=0;
         proc_name=cur_identifier(start_col);
         if (proc_name=='') {
            proc_name=cur_word(start_col);
            start_col=_text_colc(start_col,"I");
         }
         if ( proc_name=='' ) {
            if (embedded_status==1) {
               _EmbeddedEnd(orig_values);
            }
            message(nls('No word at cursor'));
            tag_pop_matches();
            return(2);
         }
         if (p_col < start_col || p_col >= start_col+length(proc_name)) {
            int orig_col=p_col;
            p_col=start_col+length(proc_name);
            proc_name='';
            context_found=context_find_tag(proc_name);
            p_col=orig_col;
            if (!context_found && !is_valid_idexp(proc_name)) {
               proc_name=cur_word(start_col);
               start_col=_text_colc(start_col,"I");
            }
         }
      }
      lang=_get_extension(p_buf_name);

      if(p_LangId == "html") {
         _jsp_GetConfigPrefixToUriHash(PrefixHashtable);
         _jsp_GetConfigUriToFileHash(UriHashtable);
      }

      if (!context_found && p_LangId == 'e' &&
          (file_eq('.'lang,_macro_ext) || file_eq(lang,'sh')) ) {
         if (embedded_status==1) {
            _EmbeddedEnd(orig_values);
         }
         tag_pop_matches();
         return(find_proc(proc_name,force_case_sensitivity));
      }

      if (!context_found && p_LangId == ANT_LANG_ID && _in_string() ) {
         // current word instead of current indentifier is correct here
         proc_name = cur_word(auto sc);
         context_found=context_find_tag(proc_name);
         findAntTag = true;
         onAntPropertyRef = _ant_CursorOnProperty(proc_name, sc);
      }

      if (!context_found && (p_LangId=='docbook') && _in_string() ) {
         // current word instead of current indentifier is correct here
         proc_name = cur_word(auto sc);
         context_found=context_find_tag(proc_name);
      }

      if (!context_found && (p_LangId=='xml') && _in_string() && 
          _ProjectGet_AppType(_ProjectHandle()) == 'android') {
         proc_name = cur_word(auto sc);
         context_found=context_find_tag(proc_name);
      }

   } else if (use_context_find) {

      // look up proc_name using context sensitive tag search
      _UpdateContext(true);
      _UpdateLocals(true);
      if (_isEditorCtl()) {
         if (embedded_status==1) {
            _EmbeddedStart(orig_values);
            embedded_status=0;
         }
         MaybeBuildTagFile(p_LangId);
      }

      // DJB 04-23-2007
      // allow leading digits instead of just a regular identifier,
      // otherwise, lastpos() will come up with the wrong results
      // for symbols that have digits in the middle, like "name2obj".
      _str prefixexp='';
      int p;
      if (_isEditorCtl()) {
         p=lastpos(_clex_identifier_re():+"$",proc_name,1,'r');
      } else {
         p=lastpos("(:i|):v",proc_name,MAXINT,'r');
      }
      if (p>1) {
         prefixexp=substr(proc_name,1,p-1);
         proc_name=substr(proc_name,p,pos(''));
      } else if (p==1) {
         proc_name=substr(proc_name,p,pos(''));
      }
      _str errorArgs[]; errorArgs._makeempty();
      int find_status=_Embeddedfind_context_tags(errorArgs,prefixexp,proc_name,0,0,'');
      if (find_status >= 0 && tag_get_num_of_matches() > 0) {
         context_found=1;
      }
   } else {
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
   _str tag_files='';
   if (combine_slickc_and_c_tagfiles) {
      tag_files=tags_filename('e'):+PATHSEP:+tags_filename('c');
   } else if (params=='' && tagfiles_ext=="" &&
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
      return('');
   }

   // save current selection
   typeless mark='';
   if ( _select_type()!='' ) {
      mark=_duplicate_selection();
      if ( mark<0 ) {
         tag_pop_matches();
         return(NOT_ENOUGH_MEMORY_RC);
      }
   }

   // use default global tag search algorithm
   if (!context_found) {
      status=find_tag_matches(tag_files, proc_name);

      if (status) {

         // decompose the original proc name into tag, class, type
         _str orig_tag_name,orig_class_name,orig_type_name;
         int orig_tag_flags=0;
         tag_tree_decompose_tag(proc_name, orig_tag_name, orig_class_name, orig_type_name, orig_tag_flags);

         // If we haven't found the tag by name maybe the tag is using
         // a JSP prefix. Try sticking the shortname of the TLD taglib
         // at the front of the tag.      
         if(_isEditorCtl() && p_LangId=='tld' && tag_get_num_of_matches() < 1) {
            _str firstPart, secondPart;
            parse orig_tag_name with firstPart ':' secondPart;

            // See if the prefix exists in our list of taglib mappings.
            // Get the corresponding uri and filename
            _str prefix = "", uri = "", tldfile = "";
            if (PrefixHashtable._indexin(firstPart)) {
               prefix = firstPart;
               uri = PrefixHashtable:[prefix];
               tldfile = UriHashtable:[uri];

               // Get the shortname for this tld file
               _str short_name="";
               index := _FindLanguageCallbackIndex('vs%s-get-taglib-shortname',p_LangId);
               if(index) {
                  status = call_index(view_id, '', short_name, index); 
               }

               orig_tag_name = short_name :+ ":" :+ secondPart;
            }

            // Only if this prefix exists in the hashtable and it's tldfile matches
            // the file we are looking at do we search for this tag
            if (prefix != "" && file_eq(p_buf_name,tldfile) && _istagging_supported(lang)) {
               i = tag_find_context_iterator(orig_tag_name, true, p_EmbeddedCaseSensitive);
               while (i > 0) {
                  _str i_file_name;
                  _str i_type_name;
                  _str i_class_name;
                  tag_get_detail2(VS_TAGDETAIL_context_type,i,i_type_name);
                  tag_get_detail2(VS_TAGDETAIL_context_class,i,i_class_name);
                  tag_get_detail2(VS_TAGDETAIL_context_file,i,i_file_name);
                  if ((orig_type_name=='' || i_type_name == orig_type_name) &&
                      (orig_class_name==null || i_class_name == orig_class_name || _LanguageInheritsFrom('cob'))) {
                     tag_insert_match_fast(VS_TAGMATCH_context, i);
                     status=0;
                  }
                  i = tag_next_context_iterator(orig_tag_name, i, true, p_EmbeddedCaseSensitive);
               }
            }
         }
      }
   }

   // warn user if we did not find any matches
   if (!quiet && tag_get_num_of_matches() <= 0) {
      if (_MaybeRetryTaggingWhenFinished()) {
         return find_tag(params, quiet);
      }
      _message_box(nls("Tag '%s' not found.",proc_name));
   }

   // remove duplicate tags
   filterForwardClasses := ((_GetCodehelpFlags() & VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS)==0);
   filterSignatures     := ((_GetCodehelpFlags() & VSCODEHELPFLAG_FILTER_OVERLOADED_FUNCTIONS)!=0);
   if (_FindLanguageCallbackIndex("_%s_analyze_return_type") <= 0) {
      filterSignatures = false;
   }

   // check for strict case-sensitivity
   matchProc := '';
   if (force_case_sensitivity) {
      tag_tree_decompose_tag(proc_name, matchProc, 
                             auto dummy_class, auto dummy_type, auto dummy_flags);
   }
   VS_TAG_RETURN_TYPE visited:[];
   tag_remove_duplicate_symbol_matches(false,false,filterForwardClasses,
                                       false,false,false,matchProc,
                                       filterSignatures,visited);

   // symbol information for tag we will go to
   tag_browse_info_init(cm);

   // maybe remove matches which are not ant target/property tags
   if (findAntTag) {
      tag_filter_ant_matches(onAntPropertyRef);
   } 

   // check if there is a preferred definition or declaration to jump to
   int match_id = tag_check_for_preferred_symbol(_GetCodehelpFlags());
   if (match_id > 0) {

      // record the matches the user chose from
      tag_get_match_info(match_id, cm);
      push_tag_add_match(cm);
      for (i=1; i<=tag_get_num_of_matches(); ++i) {
         if (i==match_id) continue;
         VS_TAG_BROWSE_INFO im;
         tag_get_match_info(i,im);
         push_tag_add_match(im);
      }

   } else {
      // present list of matches and go to the selected match
      status = tag_select_symbol_match(cm,true,_GetCodehelpFlags());
      if (status < 0) {
         tag_pop_matches();
         return status;
      }
   }

   // now go to the selected tag
   status = tag_edit_symbol(cm);
   tag_pop_matches();
   return status;
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
   _str word='';
   int enabled=MF_ENABLED;

   // (DJB 06-10-2003) We can still push-tag if tagging isn't supported in current buffer
   //
   if ( !target_wid || !target_wid._isEditorCtl() /* || !target_wid._istagging_supported() */) {
      enabled=MF_GRAYED;
   } else if (!target_wid.is_valid_idexp(word)) {
      word=target_wid.cur_word(auto junk);
   }

   // 12:14p 5/11/2009 - DWH - Check for p_mdi_child AND p_window_state.
   // Allow action for non-MDI windows, but can only check p_window_state for 
   // MDI child windows
   if (p_mdi_child && p_window_state:=='I') {
      enabled=MF_GRAYED;
   }

   if ((enabled == MF_ENABLED) && target_wid._in_string() && 
       ((target_wid._LanguageInheritsFrom('xml') ||
        target_wid._LanguageInheritsFrom('html')) && !target_wid.p_LangId=='ant')) {
      enabled=MF_GRAYED;
      word='';
   }

   command=translate(command,'-','_');
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
   _str msg='';
   if (command=='cb-find' || command=='cf') {
      if (word=="") {
         msg=nls("Show in Symbol Browser");
      } else {
         msg=nls("Show %s in Symbol Browser",word);
      }
   } else if (command=='push-ref') {
      if (def_references_options & VSREF_DO_NOT_GO_TO_FIRST) {
         if (word=="") {
            msg=nls("Find Reference");
         } else {
            msg=nls("Find References to %s",word);
         }
      } else {
         if (word=="") {
            msg=nls("Go to Reference");
         } else {
            msg=nls("Go to Reference to %s",word);
         }
      }
   } else if (command=='generate-debug') {
      if (word=="") {
         msg=nls("Generate Debug Statement");
      } else {
         msg=nls("Generate Debug Statement for %s",word);
      }
   } else {
      if (word=="") {
         msg=nls("Go to Definition");
      } else {
         msg=nls("Go to Definition of %s",word);
      }
   }
   if (cmdui.menu_handle) {
      if (!_orig_item_text._indexin(command)) {
         _orig_item_text:[command]="";
      }
      _str keys='',text='';
      parse _orig_item_text:[command] with keys ',' text;
      if ( keys!=def_keys || text=='') {
         int flags=0;
         _str new_text;
         typeless junk;
         _menu_get_state(menu_handle,command,flags,'m',new_text,junk,junk,junk,_orig_help_text:[command]);
         if (keys!=def_keys || text=='') {
            text=new_text;
         }
         _orig_item_text:[command]=def_keys','text;
         //message '_orig_item_text='_orig_item_text;delay(300);
      }
      _str key_name='';
      parse _orig_item_text:[command] with \t key_name;
      int status=_menu_set_state(menu_handle,
                                 cmdui.menu_pos,enabled,'p',
                                 msg"\t":+key_name,
                                 command,'','',
                                 _orig_help_text:[command]);
   }
   return(enabled);
}

int _OnUpdate_update_doc_comment(CMDUI &cmdui,int target_wid,_str command)
{
   _str word='';
   int enabled=MF_ENABLED;

   if ( !target_wid || !target_wid._isEditorCtl()  || !target_wid._istagging_supported()) {
      enabled=MF_GRAYED;
   }

   if (p_mdi_child && p_window_state:=='I') {
      enabled=MF_GRAYED;
   }

   command=translate(command,'-','_');
   int menu_handle=cmdui.menu_handle;
   int button_wid=cmdui.button_wid;
   if (button_wid) {
      return enabled;
   }
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      return 0;
   }

   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   _str func_name = '';
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, auto type_name);
      // are we on a function? 
      if (tag_tree_type_is_func(type_name)) {
         tag_get_detail2(VS_TAGDETAIL_context_name, context_id, func_name);
      }
   }
   if (func_name == '') {
      return MF_GRAYED; 
   }
   _str msg='';
   if (command=='update-doc-comment') {
      msg=nls("Update Doc Comment for %s ", func_name);
   } 
   if (cmdui.menu_handle) {
      if (!_orig_item_text._indexin(command)) {
         _orig_item_text:[command]="";
      }
      _str keys='',text='';
      parse _orig_item_text:[command] with keys ',' text;
      if ( keys!=def_keys || text=='') {
         int flags=0;
         _str new_text;
         typeless junk;
         _menu_get_state(menu_handle,command,flags,'m',new_text,junk,junk,junk,_orig_help_text:[command]);
         if (keys!=def_keys || text=='') {
            text=new_text;
         }
         _orig_item_text:[command]=def_keys','text;
         //message '_orig_item_text='_orig_item_text;delay(300);
      }
      _str key_name='';
      parse _orig_item_text:[command] with \t key_name;
      int status=_menu_set_state(menu_handle,
                                 cmdui.menu_pos,enabled,'p',
                                 msg"\t":+key_name,
                                 command,'','',
                                 _orig_help_text:[command]);
   }
   return(enabled);
}
/**
 * Push a bookmark then jump to references to the symbol under the cursor.
 *
 * @return int
 * 
 * @categories Tagging_Functions
 */
_command int push_ref,r(_str params="") name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   if (_no_child_windows()) {
      return(find_refs(params));
   }
   int focus_wid=_get_focus();
   boolean refsFormHidden = (_tbIsAutoHidden('_tbtagrefs_form') > 0);
   int mark=_alloc_selection('b');
   if ( mark<0 ) {
      return(mark);
   }
   _mdi.p_child.mark_already_open_destinations();
   _mdi.p_child._select_char(mark);
   tag_refs_clear_pics();
   int wid = p_window_id;
   int status=find_refs(params);
   if ( status /* or substr(p_buf_name,1,7)="Help on" */ ) {
      _free_selection(mark);
      return(status);
   }
   p_window_id = wid;
   _mdi.p_child.push_destination();
   int ret = push_bookmark(mark);
   if (refsFormHidden) {
      toolShowReferences();
   }
   return ret;
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
_command void mou_push_ref() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   mou_click();
   push_ref();
}
int _OnUpdate_mou_push_ref(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
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
_command find_refs(_str params="", _str preview_option="") name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // create a new match set
   tag_push_matches();

   // parse command line options
   boolean context_found=false;
   _str tagfiles_lang='';
   boolean combine_slickc_and_c_tagfiles=false;
   _str option='',rest='';
   for (;;) {
      parse params with option rest;
      if (lowcase(option)=='-e') {
         parse rest with tagfiles_lang params;
      } else if (lowcase(option)=='-sc') {
         combine_slickc_and_c_tagfiles=true;
         params=rest;
      } else {
         break;
      }
   }

   // attempt to use Context Tagging(R) to find symbol matches
   int embedded_status=0;
   typeless orig_values;
   int status=0;
   _str ext='';
   _str proc_name=params;
   if ( params=='' ) {
      if( !_isEditorCtl()) {
         tag_pop_matches();
         return(1);
      }
      /* Try to find the procedure at the cursor. */
      //say("trying Context Tagging(R), proc_name="proc_name);
      _UpdateContext(true);
      embedded_status = _EmbeddedStart(orig_values);
      MaybeBuildTagFile(p_LangId,true);

      context_found=context_find_tag(proc_name);
      if (!context_found && !is_valid_idexp(proc_name)) {
         //say("Context Tagging(R) failed, reverting to current word only");
         int start_col=0;
         proc_name=cur_identifier(start_col);
         if (proc_name=='') {
            proc_name=cur_word(start_col);
            start_col=_text_colc(start_col,"I");
         }
         if ( proc_name=='' ) {
            if (embedded_status == 1) {
               _EmbeddedEnd(orig_values);
            }
            message(nls('No word at cursor'));
            tag_pop_matches();
            return(2);
         }
         if (p_col!=start_col) {
            int orig_col=p_col;
            p_col=start_col+length(proc_name);
            proc_name='';
            context_found=context_find_tag(proc_name);
            p_col=orig_col;
            if (!context_found && !is_valid_idexp(proc_name)) {
               proc_name=cur_word(start_col);
               start_col=_text_colc(start_col,"I");
            }
         }
      }
      if (!context_found && (p_LangId=='docbook') && _in_string() ) {
         // current word instead of current indentifier is correct here
         proc_name = cur_word(auto sc);
         context_found=context_find_tag(proc_name);
      }
      if (!context_found && (p_LangId=='android') && _in_string()) {
         // current word instead of current indentifier is correct here
         proc_name = cur_word(auto sc);
         context_found=context_find_tag(proc_name);
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
   _str tag_files='';
   _str occ_lang='';
   if (combine_slickc_and_c_tagfiles) {
      tag_files=tags_filename('e'):+PATHSEP:+tags_filename('c');
      // check if the current workspace tag file or extension specific
      // tag file requires occurrences to be tagged.
      if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
         tag_pop_matches();
         return(1);
      }
      occ_lang='c';
   } else if (params=='' && tagfiles_lang=="" &&
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
            //tag_files='';
            occ_lang='';
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
   //   return('');
   //}

   // save current selection
   typeless mark='';
   if ( _select_type()!='' ) {
      mark=_duplicate_selection();
      _select_type(mark, 'S', 'E');
      if ( mark<0 ) {
         tag_pop_matches();
         return(NOT_ENOUGH_MEMORY_RC);
      }
   }

   // if not find with Context Tagging(R), try conventional methods
   faking_it := false;
   if (!context_found) {
      status=find_tag_matches(tag_files,proc_name);
      if (status && params!='') {
         status=find_tag_matches(tags_filename(),proc_name);
      }
      if (status) {
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
            _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_SYMBOL_NOT_FOUND,
                           nls("Symbol '%s' not found.  Searching for word matches.",proc_name),
                           "References", 1);
         }

         // insert fake tag match
         tag_insert_match('',proc_name,'','',0,'',0,'');
         faking_it=true;
      }
   }

   VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   if ( faking_it) {
      // just use the fake symbol as-is
      tag_get_match_info(1,cm);
      if (_isEditorCtl()) {
         cm.language=p_LangId;
      } else {
         cm.language=_Filename2LangId(cm.file_name);
      }

   } else {
      // remove duplicate tags
      tag_remove_duplicate_symbol_matches(true, true, true, true, false, false, '', 
                                          false, null, 0, true, true);

      // avoid prompting for declaration vs. definition of the same symbol
      int match_id = tag_check_for_preferred_symbol(VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION);
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
   int focus_wid=_get_focus();

   // populate the references tool window
   toolShowReferences();
   status=refresh_references_tab(cm,true);
   boolean preview_only = (preview_option!='');

   // advance to the first tag reference
   int next_ref_status=0;
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
      next_ref_status=next_ref(preview_only);
   }

   // set up find-next / find-prev
   if (!preview_only) {
      _mffindNoMore(def_mfflags);
      _mfrefIsActive=true;
      set_find_next_msg("Find reference", _GetReferencesSymbolName());
   }

   // information user how to get next reference
   if (!preview_only && !next_ref_status) {
      _str bindings='';
      _str text = "";
      if (def_mfflags & 1) {
         bindings=_mdi.p_child.where_is("find_next",1);
      } else {
         bindings=_mdi.p_child.where_is("next_error",1);
      }
      parse bindings with 'is bound to 'bindings;
      parse bindings with bindings ',';
      if (bindings!="") {
         text="Press "bindings:+" for next occurrence.";
      }
      sticky_message(text);
   }

   // restore selection
   if ( mark!='' ) {
      int old_mark=_duplicate_selection('');
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
 * Get tag information struct for the symbol under the cursor
 * 
 * @param params           find tag options (-e [ext] or -sc for Slick-C&reg;)
 * @param cm               (output) symbol information
 * @param quiet            if true, just return status, no message boxes
 * @param all_choices      (output) array of choices
 * @param return_choices   return tag choices instead of prompting?
 * 
 * @return 0 on success, <0 on error
 * 
 * @categories Tagging_Functions
 */
int tag_get_browse_info(_str params, 
                        struct VS_TAG_BROWSE_INFO& cm, 
                        boolean quiet=false, 
                        struct VS_TAG_BROWSE_INFO (&all_choices)[]=null,
                        boolean return_choices=false, 
                        boolean filterDuplicates=true,
                        boolean filterPrototypes=true,
                        boolean filterDefinitions=false,
                        boolean force_tag_search=false,
                        boolean filterFunctionSignatures=false,
                        VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // create a new match set
   tag_push_matches();
   tag_browse_info_init(cm);

   // parse command line options
   boolean context_found=false;
   _str tagfiles_ext='';
   boolean combine_slickc_and_c_tagfiles=false;
   _str option='',rest='';
   for (;;) {
      parse params with option rest;
      if (lowcase(option)=='-e') {
         parse rest with tagfiles_ext params;
      } else if (lowcase(option)=='-sc') {
         combine_slickc_and_c_tagfiles=true;
         params=rest;
      } else {
         break;
      }
   }

   // attempt to use Context Tagging(R) to find matches
   int embedded_status=0;
   typeless orig_values;
   int status=0;
   _str proc_name=params;
   if ( params=='' ) {
      if( !_isEditorCtl()) {
         tag_pop_matches();
         return(1);
      }
      /* Try to find the procedure at the cursor. */
      //say("trying Context Tagging(R), proc_name="proc_name);
      _UpdateContext(true);
      embedded_status = _EmbeddedStart(orig_values);
      MaybeBuildTagFile(p_LangId,true);

      context_found=context_find_tag(proc_name);
      if (!context_found && !is_valid_idexp(proc_name)) {
         //say("Context Tagging(R) failed, reverting to current word only");
         int start_col=0;
         proc_name=cur_identifier(start_col);
         if (proc_name=='') {
            proc_name=cur_word(start_col);
            start_col=_text_colc(start_col,"I");
         }
         if ( proc_name=='' ) {
            if (embedded_status==1) {
               _EmbeddedEnd(orig_values);
            }
            if (!quiet) message(nls('No word at cursor'));
            tag_pop_matches();
            return(2);
         }
         if (p_col!=start_col) {
            int orig_col=p_col;
            p_col=start_col+length(proc_name);
            proc_name='';
            context_found=context_find_tag(proc_name);
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
   _str tag_files='';
   _str occ_lang='';
   if (combine_slickc_and_c_tagfiles) {
      tag_files=tags_filename('e'):+PATHSEP:+tags_filename('c');
      occ_lang='c';
   } else if (params=='' && tagfiles_ext=="" &&
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
            tag_files='';
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
   //   return('');
   //}

   // save current selection
   typeless mark='';
   if ( _select_type()!='' ) {
      mark=_duplicate_selection();
      if ( mark<0 ) {
         tag_pop_matches();
         return(NOT_ENOUGH_MEMORY_RC);
      }
   }

   // find matching tags and place them in a match set
   if (!context_found || force_tag_search) {
      status=find_tag_matches(tag_files,proc_name);
   }

   // check if we are sitting on one of our matches
   tag_filter_only_match_under_cursor(p_buf_name, _QROffset());

   // remove duplicate symbols from the match set
   tag_remove_duplicate_symbol_matches(filterPrototypes,
                                       filterDuplicates,
                                       true,true,
                                       filterDefinitions,
                                       false,'',
                                       filterFunctionSignatures,
                                       visited, depth, false);

   if (return_choices) {
      // populate the all_choices array
      int i,n = tag_get_num_of_matches();
      for(i=0; i<n; ++i) {
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
            return tag_get_browse_info(params, cm, quiet, all_choices, return_choices, filterDuplicates, filterPrototypes, filterDefinitions, force_tag_search, filterFunctionSignatures, visited, depth);
         }
         _message_box(nls("Definition of '%s' not found",proc_name)".");
      }
   }

   // restore the original selection
   if ( mark!='' ) {
      int old_mark=_duplicate_selection('');
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
   //-//tag_browse_info_dump(cm, "tag_get_occurrence_file_list");

   // always add the file that contains the tag
   refFileList[refFileList._length()] = cm.file_name;

   // if this is a local variable or a static local function/variable, only need to
   // return the file that contains it
   if (cm.type_name == "lvar") {
      return 0;
   }

   // if this is a private member in Java, then restrict, only need
   // the file that contains it.
   if ((cm.flags & VS_TAGFLAG_access)==VS_TAGFLAG_private && _get_extension(cm.file_name)=="java") {
      return 0;
   }

   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }

   // open the workspace tagfile
   int status = tag_read_db(project_tags_filename());
   if(status < 0) return status;

   // build list of files to check
   _str fileList[] = null;
   _str fileHash:[] = null;

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
   //-//say("tag_get_occurrence_file_list: " fileList._length() " possible files");

   // if the file count is high enough, show progress dialog
   int progressFormID = 0;
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

      int tempViewID = 0;
      int origViewID = 0;
      boolean alreadyExists = false;
      status = _open_temp_view(filename, tempViewID, origViewID, "", alreadyExists, false, true);
      if(status < 0) continue;

      // doing this because it is done in cb_add_file_refs.  it may not be
      // necessary for this case
      _SetAllOldLineNumbers();

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
      int maxRefs = def_cb_max_references / 4; // 10;
     _str errorArgs[]; errorArgs._makeempty();
      int numRefs = 0;
      boolean hasRef = false;

      // Does this file have any references that are instances of any of the classes in the all classes list?
      status = tag_match_multiple_occurrences_in_file(errorArgs, cm.member_name, p_EmbeddedCaseSensitive,
                              all_classes, all_classes._length(), VS_TAGFILTER_ANYTHING,
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
                                 int progressMin = 0, boolean narrowList=true,
                                 int tagFilter=VS_TAGFILTER_ANYTHING,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //-//tag_browse_info_dump(cm, "tag_get_occurrence_file_list");

   // always add the file that contains the tag
   refFileList[refFileList._length()] = cm.file_name;

   // if this is a local variable or a static local function/variable, only need to
   // return the file that contains it
   if(cm.type_name == "lvar") {
      return 0;
   }

   // if this is a private member in Java, then restrict, only need
   // the file that contains it.
   if ((cm.flags & VS_TAGFLAG_access)==VS_TAGFLAG_private && _get_extension(cm.file_name)=="java") {
      return 0;
   }

   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }

   // open the workspace tagfile
   int status = tag_read_db(project_tags_filename());
   if(status < 0) return status;

   // build list of files to check
   _str fileList[] = null;
   _str fileHash:[] = null;
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
   //-//say("tag_get_occurrence_file_list: " fileList._length() " possible files");

   // if the file count is high enough, show progress dialog
   int progressFormID = 0;
   if(progressMin > 0 && fileList._length() > 0 && fileList._length() >= progressMin) {
      progressFormID = show_cancel_form("Finding files that reference '" cm.member_name "'", null, true, true);
   }

   // iterate over the file list, making sure they really refer to the object
   int i, n = fileList._length();
   for(i = 0; i < n; i++) {
      _str filename = fileList[i];

      // if this is the filename that was passed in, it's already in the list
      // so no need to bother with it
      if(file_eq(filename, cm.file_name)) {
         //-//say("tag_get_occurrence_file_list: file=" filename " IN BY DEFAULT");
         continue;
      }

      int tempViewID = 0;
      int origViewID = 0;
      boolean alreadyExists = false;
      status = _open_temp_view(filename, tempViewID, origViewID, "", alreadyExists, false, true);
      if(status < 0) continue;

      // doing this because it is done in cb_add_file_refs.  it may not be
      // necessary for this case
      _SetAllOldLineNumbers();

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
      int maxRefs = def_cb_max_references / 4; // 10;
      _str errorArgs[]; errorArgs._makeempty();
      int numRefs = 0;
      status = tag_match_occurrences_in_file(errorArgs, 0, 0, cm.member_name, p_EmbeddedCaseSensitive,
                                             cm.file_name, cm.line_no, VS_TAGFILTER_ANYTHING, 0, 0,
                                             numRefs, maxRefs, visited, depth+1);
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
   int orig_wid = p_window_id;
   if (!_isEditorCtl()) {
      p_window_id=VSWID_HIDDEN;
   }

   // load the file the tag is located in
   int tempViewID = 0;
   int origViewID = 0;
   boolean buffer_already_exists=false;
   int status = _open_temp_view(cm.file_name, tempViewID, origViewID, '', buffer_already_exists, false, true);
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
         int contextLineNumber = 0;
         _str contextFileName  = '';
         tag_get_detail2(VS_TAGDETAIL_context_line, contextID, contextLineNumber);
         tag_get_detail2(VS_TAGDETAIL_context_file, contextID, contextFileName);

         if (contextLineNumber == cm.line_no && file_eq(contextFileName, cm.file_name)) {
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
int tag_type_to_filter(_str tag_type,int tag_flags)
{
   int filter=0;
   int bit=1;
   int i;
   for (i=1; i<=32; ++i) {
      if (tag_filter_type(0,bit,tag_type,tag_flags)) {
         filter|=bit;
      }
      bit*=2;
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
_command goto_context_tag(_str proc_name='', _str line_no='') name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   if (!_isEditorCtl()) {
      return(1);
   }

   // reparse the context and locals if needed
   _UpdateContext(true);
   _UpdateLocals(true);
   typeless CurrentBufferPos;
   save_pos(CurrentBufferPos);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // Try to find the procedure at the cursor.
   _str errorArgs[]; errorArgs._makeempty();
   if ( proc_name=='' &&
        context_match_tags(errorArgs,proc_name,false,1,true,p_EmbeddedCaseSensitive) <= 0) {

      int start_col=0;
      proc_name=cur_identifier(start_col);
      if (proc_name=='') {
         proc_name=cur_word(start_col);
         start_col=_text_colc(start_col,"I");
      }
      if ( proc_name=='' ) {
         message(nls('No word at cursor'));
         return(2);
      }
   }

   // decompose the original proc name into tag, class, type
   _str orig_signature='';
   _str orig_tag_name='';
   _str orig_class_name='';
   _str orig_type_name='';
   int orig_tag_flags=0;
   tag_tree_decompose_tag(proc_name, orig_tag_name, orig_class_name, orig_type_name, orig_tag_flags, orig_signature);

   // save current selection if there is one
   typeless mark='';
   if ( _select_type()!='' ) {
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
   boolean local_found = false;
   int i = tag_find_local_iterator(orig_tag_name, true, p_EmbeddedCaseSensitive, true, orig_class_name);
   while (i > 0) {
      tag_get_detail2(VS_TAGDETAIL_local_type,i,type_name);
      tag_get_detail2(VS_TAGDETAIL_local_args,i,signature);
      //say("FOUND: tag_name="tag_name" type_name="type_name" orig="orig_type_name);
      if ((orig_type_name=='' || type_name == orig_type_name) &&
          (orig_signature=='' || signature == orig_signature)) {
         proc_name=tag_tree_make_caption_fast(VS_TAGMATCH_local,i,true,true,false);
         tag_get_detail2(VS_TAGDETAIL_local_start_linenum, i, start_linenum);
         tag_get_detail2(VS_TAGDETAIL_local_start_seekpos, i, start_seekpos);
         if (!local_found && line_no!='' && line_no:==start_linenum) {
            tagList._makeempty();
            linenumList._makeempty();
            seekposList._makeempty();
            local_found = true;
         }
         tagList[tagList._length()]=proc_name;
         linenumList[linenumList._length()]=start_linenum;
         seekposList[seekposList._length()]=start_seekpos;
      }
      i = tag_next_local_iterator(orig_tag_name, i, true, p_EmbeddedCaseSensitive, true, orig_class_name);
   }

   // not found in locals, so try out global scope
   boolean context_found = false;
   if (!local_found) {
      i = tag_find_context_iterator(orig_tag_name, true, p_EmbeddedCaseSensitive, true, orig_class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type,i,type_name);
         tag_get_detail2(VS_TAGDETAIL_context_args,i,signature);
         //say("FOUND: tag_name="tag_name" type_name="type_name" orig="orig_type_name);
         if ((orig_type_name=='' || type_name == orig_type_name) &&
             (orig_signature=='' || signature == orig_signature)) {
            proc_name=tag_tree_make_caption_fast(VS_TAGMATCH_context,i,true,true,false);
            tag_get_detail2(VS_TAGDETAIL_context_start_linenum, i, start_linenum);
            tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, i, start_seekpos);
            if (!context_found && line_no!='' && line_no:==start_linenum) {
               tagList._makeempty();
               linenumList._makeempty();
               seekposList._makeempty();
               context_found = true;
            }
            tagList[tagList._length()]=proc_name;
            linenumList[linenumList._length()]=start_linenum;
            seekposList[seekposList._length()]=start_seekpos;
         }
         i = tag_next_context_iterator(orig_tag_name, i, true, p_EmbeddedCaseSensitive, true, orig_class_name);
      }
   }

   // no matches!
   if (tagList._length() < 1) {
      _message_box(nls("%s not found in '%s'",proc_name,p_buf_name));
      return(2);
   }

   // more than one match, then display selection dialog
   typeless old_scroll_style=_scroll_style();
   _scroll_style('c');
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
   if ( mark!='' ) {
      int old_mark=_duplicate_selection('');
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
              boolean find_parents, int max_matches,
              boolean exact_match, boolean case_sensitive,
              int filter_flags=VS_TAGFILTER_ANYTHING,
              int context_flags=VS_TAGCONTEXT_ALLOW_locals,
              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // make sure that the context doesn't get modified by a background thread.
   errorArgs._makeempty();
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // find more details about the current tag
   cur_flags := cur_type_id := cur_scope_seekpos := 0;
   cur_tag_name := cur_type_name := cur_context := cur_class := cur_package := "";
   int context_id=tag_get_current_context(cur_tag_name, cur_flags, cur_type_name, cur_type_id,
                                          cur_context, cur_class, cur_package);
   if (cur_context == "" && (context_flags & VS_TAGCONTEXT_ONLY_inclass)) {
      errorArgs[1]=lastid;
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   //say "_do_default_find_context_tags"
   // try to match the symbol in the current context
   tag_clear_matches();
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_this_file) ||
       (context_flags & VS_TAGCONTEXT_ONLY_locals)) {
      tag_files._makeempty();
   }
   num_matches := 0;
   tag_list_symbols_in_context(lastid, "", 0, 0, tag_files, '',
                               num_matches, max_matches,
                               filter_flags, context_flags,
                               exact_match, case_sensitive,
                               visited, depth);

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
                               boolean find_parents=false,
                               int max_matches=def_tag_max_find_context_tags,
                               boolean exact_match=true, boolean case_sensitive=false,
                               int filter_flags=VS_TAGFILTER_ANYTHING,
                               int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                               VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   int num_matches=0;
   int status=0;
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   errorArgs._makeempty();
   tag_clear_matches();

   // try to match the symbol in the current context
   index := _FindLanguageCallbackIndex("_%s_find_context_tags");
   if (!index && upcase(substr(p_lexer_name,1,3))=='XML') {
      index=find_index('_html_find_context_tags',PROC_TYPE);
   }
   if (index && index_callable(index)) {
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
      typeless tag_files = tags_filenamea(p_LangId);
      int context_list_flags = (find_parents)? VS_TAGCONTEXT_FIND_parents : 0;
      status=tag_list_symbols_in_context(lastid, "", 
                                         0, 0, tag_files, '',
                                         num_matches, max_matches,
                                         filter_flags, 
                                         context_flags | context_list_flags,
                                         exact_match, case_sensitive, 
                                         visited, depth); 
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
                                   boolean find_parents,int max_matches,
                                   boolean exact_match,boolean case_sensitive,
                                   int filter_flags=VS_TAGFILTER_ANYTHING,
                                   int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                                   VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //say("_doc_comment_find_context_tags: prefixexp="prefixexp" lastid="lastid);
   if (!(info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT)) {
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   _str allWords[];
   if (prefixexp == "@") {
      allWords = gDoxygenCommandsAtsign;
   } else if (prefixexp == "\\") {
      allWords = gDoxygenCommandsBackslash;
   } else if (first_char(prefixexp) == "<" || first_char(prefixexp) == "&") {

      return _html_find_context_tags(errorArgs, prefixexp, 
                                     lastid, lastidstart_offset, 
                                     info_flags, otherinfo, 
                                     find_parents, max_matches, 
                                     exact_match, case_sensitive, 
                                     filter_flags, context_flags, 
                                     visited, depth);

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
      VS_TAG_BROWSE_INFO cm;
      tag_get_context_info(context_id, cm);
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
                            VS_TAGFILTER_LVAR, context_flags, 
                            num_params, max_matches, 
                            exact_match, case_sensitive, 
                            "", visited, depth);

      restore_pos(p);
      _UpdateLocals(true);
      return (num_params > 0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;

   } else {
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   num_matches := 0;
   prefix := prefixexp:+lastid;
   word := "";
   foreach (word in allWords) {
      if (_CodeHelpDoesIdMatch(prefix, word, exact_match, case_sensitive)) {
         tag_insert_match("", substr(word, 2), "statement", "", 1, "", 0, "");
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
 *    0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
int _Embeddedparse_return_type(_str (&errorArgs)[], typeless tag_files,
                         _str symbol, _str search_class_name,
                         _str file_name, _str return_type, boolean isjava,
                         struct VS_TAG_RETURN_TYPE &rt,
                         VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   errorArgs._makeempty();

   // look up and call the extension specific callback function
   int status = 0;
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
 * 
 * 
 * @param codehelp_flags
 * 
 * @return int
 */
int tag_check_for_preferred_symbol(int codehelp_flags)
{
   // index of unique tag match
   num_procs    := 0;
   num_protos   := 0;
   num_vardefs  := 0;
   num_vardecls := 0;
   unique_proc  := 0;
   unique_proto := 0;
   unique_other := -1;

   // for keeping track if proc/proto class names match
   unique_class_name := null;
   unique_class := true;

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
   n := tag_get_num_of_matches();
   for (i:=1; i<=n; ++i) {
      tag_get_detail2(VS_TAGDETAIL_match_type, i, tag_type);
      tag_get_detail2(VS_TAGDETAIL_match_flags, i, tag_flags);
      tag_get_detail2(VS_TAGDETAIL_match_file, i, file_name);
      tag_get_detail2(VS_TAGDETAIL_match_class, i, class_name);
      tag_get_detail2(VS_TAGDETAIL_match_line, i, start_line_number);
      tag_get_detail2(VS_TAGDETAIL_match_scope_linenum, i, scope_line_number);
      if (scope_line_number < start_line_number) scope_line_number = start_line_number;
      if (_isEditorCtl()) {
         // are we already on this symbol?
         if (!file_eq(file_name,p_buf_name) || p_RLine < start_line_number || p_RLine > scope_line_number) {
            if (unique_other < 0) {
               unique_other = i;
            } else {
               unique_other = 0;
            }
         }
      }
      // check that the class name matches
      if (unique_class_name == null) {
         unique_class_name = class_name;
      } else if (unique_class_name != class_name) {
         unique_class = false;
      }
      if (tag_type=='var') {
         // declaration
         unique_proto = i;
         num_vardecls++;
      } else if (tag_type == 'proto' || tag_type == 'procproto') {
         // declaration
         unique_proto = i;
         num_protos++;
      } else if (tag_tree_type_is_func(tag_type)) {
         // definition
         unique_proc = i;
         num_procs++;
      } else if (tag_type=='gvar') {
         if (tag_flags & VS_TAGFLAG_extern) {
            // assume this is a declaration
            unique_proto = i;
            num_vardecls++;
         } else {
            // definition
            unique_proc = i;
            num_vardefs++;
         }
      } else if (tag_tree_type_is_class(tag_type)) {
         // classes, looking for a unique, not forward declaration
         if (!(tag_flags & VS_TAGFLAG_forward)) {
            unique_proc = i;
            num_procs++;
         } else {
            num_protos++;
         }
      } else {
         // not a proc or proto, so force choice
         return 0;
      }
   }

   // check that we don't have both vars and functions
   if ((num_procs+num_protos) > 0 && (num_vardecls+num_vardefs) > 0) {
      return 0;
   }

   // should we just jump to the other corresponding tag?
   if (unique_other > 0 && (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_ALTERNATE)) {
      return unique_other;
   }

   // check for unique definition
   if (unique_class && (num_procs+num_vardefs)==1 && (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION)) {
      return unique_proc;
   }

   // check for unique declaration
   if (unique_class && (num_protos+num_vardecls)==1 && (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION)) {
      return unique_proto;
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
void tag_filter_ant_matches(boolean onref=false)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(true);

   int i,n = tag_get_num_of_matches();
   for (i=n; i>=1; --i) {
      tag_get_detail2(VS_TAGDETAIL_match_type, i, auto tag_type);
      tag_get_detail2(VS_TAGDETAIL_match_file, i, auto file_name);
      boolean removed = false;
      if (onref) {
         if (tag_type != 'prop') {
            tag_remove_match(i);
            removed = true;
         }
      } else if (tag_type != 'target' && tag_type != 'prop') {
         tag_remove_match(i);
         removed = true;
      } 
      if (!removed && def_antmake_filter_matches) {
         int handle = _xmlcfg_open_from_buffer(_mdi.p_child, auto status, VSXMLCFG_OPEN_ADD_PCDATA);
         if (!status) {
            if (p_buf_name != file_name) {
               // match is from different file
               boolean keep = false;
               int j = 0;
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
                     _str absName = absolute(importFile,_strip_filename(p_buf_name,'N'));
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
                           _str absName= absolute(entities[j],_strip_filename(p_buf_name,'N'));
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
                  tag_remove_match(i);
               }
            } else {
               // match is from the same file
            }
         }
         _xmlcfg_close(handle);
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
 */
void tag_filter_symbol_matches(int filter_flags, boolean filter_all=false)
{
   // no filtering to do?
   if ((filter_flags & VS_TAGFILTER_ANYTHING) == VS_TAGFILTER_ANYTHING) {
      return;
   }

   // put all the matches in an array
   int i,n = tag_get_num_of_matches();
   int num_matches=0;
   VS_TAG_BROWSE_INFO taglist[];
   taglist._makeempty();
   for (i=0; i<n; ++i) {
      tag_get_match_info(i+1,taglist[i]);
      if (taglist[i].type_name=='proto') taglist[i].flags &= ~VS_TAGFLAG_maybe_var;
      if (tag_filter_type(0, filter_flags, taglist[i].type_name, taglist[i].flags)) {
         num_matches++;
      }
   }

   // no matches?
   if (num_matches==0) {
      if (filter_all) {
         tag_clear_matches();
      }
      return;
   }

   // reconstruct the set of tag matches
   tag_clear_matches();
   n = taglist._length();
   for (i=0; i<n; ++i) {
      if (taglist[i].type_name=='proto') taglist[i].flags &= ~VS_TAGFLAG_maybe_var;
      if (!tag_filter_type(0, filter_flags, taglist[i].type_name, taglist[i].flags)) {
         continue;
      }
      tag_insert_match_info(taglist[i]);
   }
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
 */
void tag_remove_duplicate_symbol_matches(boolean filterDuplicatePrototypes=true,
                                         boolean filterDuplicateGlobalVars=true,
                                         boolean filterDuplicateClasses=true,
                                         boolean filterAllImports=true,
                                         boolean filterDuplicateDefinitions=false,
                                         boolean filterAllTagMatchesInContext=false,
                                         _str matchExact='',
                                         boolean filterFunctionSignatures=false,
                                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                                         boolean filterAnonymousClasses=true,
                                         boolean filterTagUses=false)
{
   // put all the matches in an array
   int i,n = tag_get_num_of_matches();
   if (n<=1) return;
   int numFuncs=0;
   VS_TAG_BROWSE_INFO taglist[];
   taglist._makeempty();
   for (i=0; i<n; ++i) {
      tag_get_match_info(i+1,taglist[i]);
      if (tag_tree_type_is_func(taglist[i].type_name)) ++numFuncs;
   }

   // now create a hash table of all the matches
   // hashing by class name and tag name
   typeless j=0;
   _str hash_key='';
   _str duplicates='';
   _str taghash:[];
   _str taglochash:[];
   for (i=0; i<n; ++i) {
      hash_key = taglist[i].class_name' 'taglist[i].member_name;
      if (taghash._indexin(hash_key)) {
         taghash:[hash_key] :+= ' 'i;
      } else {
         taghash:[hash_key] = i;
      }
      hash_key :+= ' 'taglist[i].line_no' '_file_case(taglist[i].file_name);
      if (taglochash._indexin(hash_key)) {
         taglochash:[hash_key] :+= ' 'i;
      } else {
         taglochash:[hash_key] = i;
      }
   }

   // array of tags that did not match the function signature
   VS_TAG_BROWSE_INFO signatureMismatches[];

   // check if there are duplicate functions in the list
   _str include_name='';
   if (taglist._length()) {
      for (i=n-1; i>=0; i--) {
         VS_TAG_BROWSE_INFO cmi = taglist[i];
         // filter out tag file matches that are from the same file as the current context
         if (filterAllTagMatchesInContext) {
            if (_isEditorCtl() && file_eq(p_buf_name, taglist[i].file_name) && taglist[i].tag_database != '') {
               taglist[i] = null;
            }
         }

         if (matchExact != '') {
            if (cmi.member_name != matchExact) {
               taglist[i] = null;
               continue;
            }
         }

         if (filterDuplicatePrototypes && (cmi.type_name=='proto' || cmi.type_name=='procproto')) {
            // filter out duplicate functions (declarations vs. definitions)
            hash_key = cmi.class_name' 'cmi.member_name;
            if (taghash._indexin(hash_key)) {
               duplicates = taghash:[hash_key];
               while (duplicates != '') {
                  parse duplicates with j duplicates;
                  if (j!=i && taglist[j]!=null) {
                     if (tag_tree_type_is_func(taglist[j].type_name) && 
                         taglist[j].member_name:==cmi.member_name && 
                         taglist[j].class_name:==cmi.class_name) {
                        taglist[i] = null;
                        break;
                     }
                  }
               }
            }

         } else if (filterDuplicateDefinitions && (cmi.type_name=='func' || cmi.type_name=='proc')) {
            // filter out duplicate functions (declarations vs. definitions)
            hash_key = cmi.class_name' 'cmi.member_name;
            if (taghash._indexin(hash_key)) {
               duplicates = taghash:[hash_key];
               while (duplicates != '') {
                  parse duplicates with j duplicates;
                  if (j!=i && taglist[j]!=null) {
                     if (tag_tree_type_is_func(taglist[j].type_name) && 
                         taglist[j].member_name:==cmi.member_name && 
                         taglist[j].class_name:==cmi.class_name) {
                        taglist[i] = null;
                        break;
                     }
                  }
               }
            }
         } else if (filterDuplicateGlobalVars && cmi.type_name=='gvar') {
            // filter out duplicate global variables (declaration vs. definition)
            hash_key = cmi.class_name' 'cmi.member_name;
            if (taghash._indexin(hash_key)) {
               duplicates = taghash:[hash_key];
               while (duplicates != '') {
                  parse duplicates with j duplicates;
                  if (j!=i && taglist[j]!=null) {
                     if (taglist[j].type_name=='var' && 
                         taglist[j].member_name:==cmi.member_name && 
                         taglist[j].class_name:==cmi.class_name) {
                        taglist[i] = null;
                        break;
                     }
                  }
               }
            }
         } else if (filterDuplicateClasses && tag_tree_type_is_class(cmi.type_name) && (cmi.flags & VS_TAGFLAG_forward)) {
            // filter out forward class declarations
            hash_key = cmi.class_name' 'cmi.member_name;
            if (taghash._indexin(hash_key)) {
               duplicates = taghash:[hash_key];
               while (duplicates != '') {
                  parse duplicates with j duplicates;
                  if (j!=i && taglist[j]!=null) {
                     if (tag_tree_type_is_class(taglist[j].type_name) && 
                         taglist[j].member_name:==cmi.member_name && 
                         taglist[j].class_name:==cmi.class_name &&
                        !(taglist[j].flags & VS_TAGFLAG_forward)) {
                        taglist[i] = null;
                        break;
                     }
                  }
               }
            }
         } else if (filterAnonymousClasses && tag_tree_type_is_class(cmi.type_name)) {
            // filter out forward class declarations
            hash_key = cmi.class_name' 'cmi.member_name;
            if (taghash._indexin(hash_key)) {
               duplicates = taghash:[hash_key];
               while (duplicates != '') {
                  parse duplicates with j duplicates;
                  if (j!=i && taglist[j]!=null) {
                     if (taglist[j].type_name == 'typedef' && 
                         taglist[j].member_name:==cmi.member_name && 
                         taglist[j].class_name:==cmi.class_name &&
                         file_eq(taglist[j].file_name, cmi.file_name)) {
                        taglist[i] = null;
                        break;
                     }
                  }
               }
            }
         } else if (filterAllImports && (cmi.type_name=='include' || cmi.type_name=='import')) {
            // filter out duplicate include or import statements
            if (file_eq(include_name, cmi.member_name)) {
               taglist[i] = null;
            } else {
               include_name = cmi.member_name;
            }
         } else if (filterTagUses && cmi.type_name=='taguse') {
            if (n > 1) {
               taglist[i] = null;
            }
         }

         // look for exact matches only
         hash_key = cmi.class_name' 'cmi.member_name' 'cmi.line_no' '_file_case(cmi.file_name);
         if (taglochash._indexin(hash_key)) {
            duplicates = taglochash:[hash_key];
            while (duplicates != '') {
               parse duplicates with j duplicates;
               if (j!=i && taglist[j]!=null) {
                  if (tag_browse_info_equal(cmi,taglist[j])) {
                     taglist[i] = null;
                     break;
                  }
               }
            }
         }

         // filter out symbol matches that are not the right argument list
         if (filterFunctionSignatures && numFuncs > 1 && taglist[i] != null) {
            if (_isEditorCtl() && n>1 && 
                tag_tree_type_is_func(cmi.type_name) && 
                !(cmi.flags & VS_TAGFLAG_maybe_var) &&
                !(cmi.flags & VS_TAGFLAG_operator)) {
               if (tag_check_function_parameter_list(cmi,visited,depth+1) == 0) {
                  signatureMismatches[signatureMismatches._length()] = taglist[i];
                  taglist[i] = null;
                  continue;
               }
            }
         }
      }
   }

   // reconstruct the set of tag matches
   tag_clear_matches();
   n = taglist._length();
   for (i=0; i<n; ++i) {
      if (taglist[i] != null) {
         tag_insert_match_info(taglist[i]);
      }
   }

   // add in signature mismatches if we didn't find any other matches
   if (tag_get_num_of_matches() <= 0) {
      n = signatureMismatches._length();
      for (i=0; i<n; ++i) {
         tag_insert_match_info(signatureMismatches[i]);
      }
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

   int i, n = tag_get_num_of_matches();
   for(i=1; i<=n; ++i) {
      _str match_file_name = '';
      int match_start_seekpos = 0;
      int match_scope_seekpos = 0;
      tag_get_detail2(VS_TAGDETAIL_match_file, i, match_file_name);
      tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, i, match_start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_match_scope_seekpos, i, match_scope_seekpos);
      if (file_eq(match_file_name, fileName) && 
          offset >= match_start_seekpos && offset <= match_scope_seekpos) {
         VS_TAG_BROWSE_INFO cm;
         tag_get_match_info(i, cm);
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
 *
 * @return &lt;0 on error or no matches.  Otherwise, it returns the
 *         number of matches found.
 */
int context_match_tags(_str (&errorArgs)[], _str &tagname,
                       boolean find_parents=false,
                       int max_matches=def_tag_max_find_context_tags,
                       boolean exact_match=true,boolean case_sensitive=false)
{
   // in a comment or string, then no context
   //say("context_match_tags("tagname")");
   int cfg=_clex_find(0,'g');
   if (_in_comment() ||
       (cfg==CFG_STRING && !_LanguageInheritsFrom('cob') &&
        !_LanguageInheritsFrom('html') &&
        upcase(substr(p_lexer_name,1,3))!='XML')) {
      //say("context_match_tags: in string or comment");
      save_pos(auto p);
      left();cfg=_clex_find(0,'g');
      if (_in_comment() || cfg==CFG_STRING) {
         restore_pos(p);
         return 0;
      }
      restore_pos(p);
   }

   // Update the current context and locals
   _UpdateContext(true);
   _UpdateLocals(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   errorArgs._makeempty();
   num_matches := 0;
   tag_clear_matches();
   status := tag_context_match_tags(errorArgs,tagname,exact_match,case_sensitive,find_parents,num_matches,max_matches);
   if (status < 0) {
      return status;
   }
   if (num_matches == 0 && tag_get_num_of_matches() > 0) {
      num_matches = tag_get_num_of_matches();
   }
   // match tags failed
   //say("context_match_tags: status="status" num_matches="num_matches);
   return num_matches;
}

/**
 * Use {@link context_match_tags} to find tags for tag navigation.
 * This is the preferred method for finding matches to tags, although,
 * if it fails, pushtag will revert to a more simplistic method that
 * just searches for a match by tag name.
 *
 * @param proc_name   name of tag to search for
 *
 * @return false on failure, true on success.
 */
static boolean context_find_tag(_str &proc_name, boolean force_case_sensitive=false)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   _str match_tag = '';
   _str errorArgs[]; errorArgs._makeempty();
   tag_clear_matches();
   int i, num_matches=context_match_tags(errorArgs,match_tag,true,
                                         def_tag_max_find_context_tags,
                                         true,p_EmbeddedCaseSensitive || force_case_sensitive);
   if (num_matches <= 0) {
      return false;
   }

   tag_get_detail2(VS_TAGDETAIL_match_name, 1, proc_name);
   return true;
}

/**
 * Returns the number of tags found.
 */
static void find_tag_matches3(_str proc_name)
{
   tag_tree_decompose_tag(proc_name, auto tag_name, auto class_name, auto type_name, auto tag_flags);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   case_sensitive := p_EmbeddedCaseSensitive;
   int i=tag_find_local_iterator(tag_name,true,case_sensitive);
   while (i > 0) {
      tag_get_detail2(VS_TAGDETAIL_local_class, i, auto i_class_name);
      tag_get_detail2(VS_TAGDETAIL_local_type, i, auto i_type_name);
      if ((class_name=='' || i_class_name :== class_name) && 
          (type_name==''  || i_type_name :== type_name)) {
         tag_insert_match_fast(VS_TAGMATCH_local, i);
      }
      i=tag_next_local_iterator(tag_name,i,true,case_sensitive);
   }

   i=tag_find_context_iterator(tag_name,true,case_sensitive);
   while (i > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_class, i, auto i_class_name);
      tag_get_detail2(VS_TAGDETAIL_context_type, i, auto i_type_name);
      if ((class_name=='' || i_class_name :== class_name) && 
          (type_name==''  || i_type_name :== type_name)) {
         tag_insert_match_fast(VS_TAGMATCH_context, i);
      }
      i=tag_next_context_iterator(tag_name,i,true,case_sensitive);
   }
}

/*
    Return
       0   Found one or more tags
       1   No tags found
       2   Bad error. Tag file messed up, Out of memory?, file not found
       COMMAND_CANCELLED_RC   User aborted.
*/
int find_tag_matches(_str tag_filelist, _str proc_name, boolean recursive_call=false)
{
   // translate Slick-C command names with dash
   _str orig_proc_name=proc_name;
   if (!_isEditorCtl() || _LanguageInheritsFrom('e')) {
      proc_name=translate(proc_name,'_','-');
   }

   // handle linkage differences between "C" and assembly
   if (!recursive_call && _isEditorCtl() &&
       (_LanguageInheritsFrom('c') || _LanguageInheritsFrom('for'))) {
      clear_message();
      find_tag_matches(tag_filelist, '_'proc_name,true);
   }

   // try to find tags in locals and current context
   if (_isEditorCtl() && _istagging_supported()) {
      find_tag_matches3(proc_name);
   }

   int status=0;
   _str TagFileList=tag_filelist;
   _str tag_files[]; tag_files._makeempty();
   for (;;) {
      _str CurFilename=next_tag_file2(TagFileList,false/*no check*/,false/*no open*/);
      if (CurFilename=='') break;
      status = tag_read_db(absolute(CurFilename));
      if ( status < 0 ) {
         _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_TAGGING_ERROR, nls("Error opening tag file '%s': %s", CurFilename, get_message(status)));
         continue;
      }
      tag_files[tag_files._length()]=CurFilename;
   }
   status=tag_list_duplicate_matches(proc_name, tag_files);
   //say("find_tag2: status="status" proc_name="proc_name);
   if (status && proc_name != orig_proc_name) {
      status=tag_list_duplicate_matches(orig_proc_name, tag_files);
   }
   if (!status) {
      clear_message();
   }
   return(status);
}

static _str gtkinfo;
static _str gtk;

static _str db2_next_sym(boolean multiline=false)
{
   if (p_col>_text_colc()) {
      if (!multiline) {
         gtk=gtkinfo='';
         return(gtk);
      }
      if(down()) {
         gtk=gtkinfo='';
         return('');
      }
      _begin_line();
   }
   int status=0;
   _str ch=get_text();
   if (ch=='' || ((ch=='/' || ch=='-') && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(db2_next_sym(multiline));
   }
   int start_col=0,start_line=0;
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
      start_col=p_col;
      start_line=p_line;
      status=_clex_find(STRING_CLEXFLAG,'n');
      if (status) {
         _end_line();
      } else if (p_col==1) {
         up();_end_line();
      }
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col+1);
      return(gtk);
   }
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      start_col=p_col;
      if(_clex_find(0,'g')==CFG_NUMBER) {
         for (;;) {
            if (p_col>_text_colc()) break;
            right();
            if(_clex_find(0,'g')!=CFG_NUMBER) {
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(start_col,p_col-start_col+1);
         return(gtk);
      }
      //search('[~'p_word_chars']|$','@r');
      _TruncSearchLine('[~'word_chars']|$','r');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   right();
   gtk=gtkinfo=ch;
   return(gtk);

}
static int db2_get_next_decl(_str &name,_str &type,_str &return_type)
{
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   db2_next_sym();
   if (gtk=='') {
      restore_search(s1,s2,s3,s4,s5);
      return(1);
   }
   if (gtkinfo==',') {
      db2_next_sym(1);
      if (gtk=='') {
         restore_search(s1,s2,s3,s4,s5);
         return(1);
      }
   }
   // If we are NOT sitting on a variable
   if (gtk!=TK_ID) {
      restore_search(s1,s2,s3,s4,s5);
      return(1);
   }
   name=gtkinfo;
   type='var';
   // Skip over variable name
   //search('[~'p_word_chars']|$','ri@');
   word_chars := _clex_identifier_chars();
   _TruncSearchLine('[~'word_chars']|$','ri');
   int start=_nrseek();
   for(;;) {
      db2_next_sym();
      if (gtk=='' || gtk==',') {
         break;
      }
   }
   if (gtk==',') {
      return_type=strip(get_text(_nrseek()-start-1,start));
   } else {
      return_type=strip(get_text(_nrseek()-start,start));
   }
   if (lowcase(return_type)=='cursor') {
      type='cursor';
   }
   return(0);
}

/**
 * Search for tags in DB2 code.
 *
 * @param proc_name    (reference) proc to search for, or set to name of proc found
 * @param find_first   find first proc, or find next?
 *
 * @return 0 on success, nonzero on error or if no more tags.
 */
_str db2_proc_search(_str &proc_name,int find_first)
{
   _str variable_re='',re='';
   int status=0;
   static int state;
   if ( find_first ) {
      state=0;
      word_chars := _clex_identifier_chars();
      variable_re='(['word_chars']#)';
      re='{#1(declare)}[ \t]+\c{#0'variable_re'}';
         //_mdi.p_child.insert_line(re);
      mark_option := (p_EmbeddedLexerName != '')? 'm':'';
      status=search(re,'w:phri'mark_option'@xcs');
   } else {
      if (state) {
         status=0;
      } else {
         status=repeat_search();
      }
   }

   typeless orig_pos;
   save_pos(orig_pos);
   for (;;) {
      if ( status ) {
         restore_pos(orig_pos);
         break;
      }
      _str name='',type='',return_type='';
      if (state) {
         status=db2_get_next_decl(name,type,return_type);
         //messageNwait('n='name' type='type);
         if (status) {
            state=0;
            word_chars := _clex_identifier_chars();
            variable_re='(['word_chars']#)';
            re='{#1(declare)}[ \t]+\c{#0'variable_re'}';
            status=search(re,'w:phri@xcs');
            continue;
         }
      } else {
         name=get_match_text(0);
         _str keyword=get_match_text(1);
         if (lowcase(keyword)=='declare') {
            state=1;
            status=db2_get_next_decl(name,type,return_type);
            //messageNwait('s='status' n='name' t='type);
            if (status) {
               state=0;
               word_chars := _clex_identifier_chars();
               variable_re='(['word_chars']#)';
               re='{#1(declare)}[ \t]+\c{#0'variable_re'}';
               status=search(re,'w:phri@xcs');
               continue;
            }
         } else {
            // make sure the first word on this line is NOT DROP
            _str line;
            _str first_word;
            get_line(line);
            parse line with first_word .;
            if (lowcase(first_word)=='drop') {
               status=repeat_search();
               continue;
            }
            type='func';
            return_type='';
         }
      }
      name=tag_tree_compose_tag(name,'',type,0,'',return_type);
      if (proc_name:=='') {
         proc_name=name;
         return(0);
      }
      if (proc_name==name) {
         return(0);
      }
      if (state) {
         status=0;
      } else {
         status=repeat_search();
      }
   }
   return(status);
}

defeventtab jcl_keys;
def ' '=embedded_key;
def '.'=embedded_key; // auto_codehelp_key
def '('=embedded_key; // auto_functionhelp_key
def ':'=embedded_key;
def '{'=embedded_key;
def '}'=embedded_key;
//def 'c- '=codehelp_complete;
def TAB=embedded_key;
def ENTER=embedded_key;
//def tab=cob_tab;
//def s_tab=cob_backtab;

int jcl_proc_search1(_str &proc_name, int find_first)
{
   _str search_key='';
   int status=0;
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
      _str name=get_match_text(0);
      if (name=='') {
         parse p_buf_name with '('name')';
         if (name=='') {
            status=repeat_search();
            continue;
         }
      }
      _str type='proc';
      //say('name='name' t='type);
      _str temp_proc_name=tag_tree_compose_tag(name,'',type);
      if (proc_name=='') {
         proc_name=temp_proc_name;
         return(0);
      }
      _str find_name,find_type;
      parse proc_name with find_name'('find_type')';
      if ((find_type:==type || find_type=="") && strieq(find_name,name)) {
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
_str mak_proc_search(_str &proc_name,boolean find_first)
{
   if ( proc_name:=='' ) {
      proc_name='(:p)';
   } else {
      _str rest;
      proc_name=_escape_re_chars(proc_name);
      parse proc_name with proc_name '(' rest;
   }
   int status=0;
   _str search_key='^{'proc_name'} *{[:=]}';
   if ( find_first ) {
      status=search(search_key,'@rhiXc');
   } else {
      status=repeat_search();
   }
   for (;;) {
      if (status) {
         return(status);
      }
      _str word=strip(get_text(match_length('0'),match_length('S0')),'T');
      if (!pos('(',word)) {
         _str delim=get_text(match_length('1'),match_length('S1'));
         _str type=(delim=='=')? 'const':'label';
         //if (pos('(',word)) return mak_proc_search(proc_name,0);
         proc_name=word'('type')';
         break;
      }
      //messageNwait('word='word);
      status=repeat_search();
   }
   return(status);
}

/**
 * Search for labels in a DOS batch file.
 *
 * @param proc_name    (reference) proc to search for, or set to name of proc found
 * @param find_first   find first proc, or find next?
 *
 * @return 0 on success, nonzero on error or if no more tags.
 */
_str bat_proc_search(_str &proc_name,boolean find_first)
{
   if ( proc_name:=='' ) {
      word_chars := _clex_identifier_chars();
      // Lexer definition for Batch has a bunch of
      // extra file separator and filename chars
      // in the identifier characters in order to
      // avoid coloring keywords like "if" as
      // keywords when they appear in a path.
      // Since these are NOT real identifier chars,
      // filter them out.
      word_chars = stranslate(word_chars,'','?');
      word_chars = stranslate(word_chars,'','%');
      word_chars = stranslate(word_chars,'','.');
      word_chars = stranslate(word_chars,'','~');
      word_chars = stranslate(word_chars,'','/');
      word_chars = stranslate(word_chars,'','\\');
      proc_name='(['word_chars']#)';
   } else {
      _str rest;
      proc_name=_escape_re_chars(proc_name);
      parse proc_name with proc_name '(' rest;
   }
   int status=0;
   _str search_key='^\:{'proc_name'} *';
   if ( find_first ) {
      status=search(search_key,'@rhiXcs');
   } else {
      status=repeat_search();
   }
   if( !status ) {
      _str word=strip(get_text(match_length('0'),match_length('S0')),'T');
      proc_name=word'(label)';
   }
   return status;
}

/**
 * Search for sections in a Unix Imakefile.
 *
 * @param proc_name    (reference) proc to search for, or set to name of proc found
 * @param find_first   find first proc, or find next?
 *
 * @return 0 on success, nonzero on error or if no more tags.
 */
_str imakefile_proc_search(_str &proc_name,boolean find_first)
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
 * @categories Search_Functions
 *
 * @return 0 on success, nonzero on error.
 */
_command int make_tags(_str params="") name_info(FILE_ARG'*')
{
   int status=shell('maketags 'params);
   return(status);

}

/**
 * This command builds or updates tag files.  The tags files are used by the
 * <b>push_tag</b> and <b>gui_push_tag</b> to go to tag definitions.  The <b>Tag
 * Files dialog box</b> is displayed which lets you choose the files you wish to
 * tag.
 *
 * @return Returns 0 if successful.
 *
 * @see make_tags
 * @see push_tag
 * @see gui_push_tag
 * @see find_tag
 * @see f
 *
 * @categories Search_Functions
 *
 */
_command void gui_make_tags() name_info(FILE_ARG'*')
{
   if (!_no_child_windows() && _mdi.p_child._isEditorCtl()) {
      _mdi.p_child.show('-xy _tag_form');
   } else {
      show('-desktop -xy _tag_form');
   }
}


static typeless reset_subdir_box = 0;

/**
 * Check if the support is loaded for the given extension, and if
 * not attempts to load support for the extension.
 *
 * @param ext                      file extension to load support for
 * @param index                    (reference) set up index for def_setup_ext
 * @param buf_name                 name of buffer in question
 * @param currentObjectIsBuffer    Is the current object the buffer?
 *
 * @return _str
 * Function returns 1 if error, returns 0 Module loaded ok if ok
 * if no there is no support for the  module, returns '' and index = 0
 * def-language-ext's symbol table index is returned in pass by reference
 * variable index
 */
_str check_and_load_support(_str ext,int &index,_str buf_name='',boolean currentObjectIsBuffer=false)
{
   lang := _Filename2LangId(buf_name);
   index = find_index('def-language-'lang, MISC_TYPE);

   if (index) {
#if 0
      parse SUPPORTED_TYPES with extension'='fn . ;
      mindex=find_index(fn:+_macro_ext,MODULE_TYPE)
      if (mindex) {
         return(0);//Module already exists
      }
#endif
      return(0);  // Assume module already exists. */
   }
   VSAUTOLOADEXT *pautoLoadExt;
   pautoLoadExt=gAutoLoadExtHashtab._indexin(_file_case(ext));
   if (pautoLoadExt) {
      _str fn=pautoLoadExt->macroName;
      _str filename = slick_path_search(fn:+_macro_ext'x');
      if (filename=='') {
         filename = slick_path_search(fn:+_macro_ext);
      } else {
         _str path=_strip_filename(filename,'N');
         _str name=file_match('-p 'maybe_quote_filename(path:+fn:+_macro_ext),1);
         if (name!='') {
            //filename=name'x';
            filename=name;
         }
      }
      if (filename == '') {
         _message_box(nls("Can't Find Support Module '%s'.",fn:+_macro_ext));
         return(1);
      }
      filename=maybe_quote_filename(filename);
      _load(filename,'u');     // Unload existing module.
      _macfile_add(filename,_macro_ext'x',0,1);
      message(nls('making:')' 'filename);
      filename=maybe_quote_filename(filename);
      int status=_make(filename);
      if (status) {
         _message_box(nls("Unable to compile macro '%s'",filename));
         return(status);
      }
      clear_message();
      _loadrc=0;
      _load(filename);  // Load module now
      status=_loadrc;
      if (status && status!=MODULE_ALREADY_LOADED_RC) {
         _message_box(nls("Can't Load Support Module '%s'.",fn:+_macro_ext));
         return(1);
      }
      _config_modify_flags(CFGMODIFY_LOADMACRO);
      lang = _Filename2LangId(buf_name);
      index = find_index('def-language-'lang, MISC_TYPE);
      return(0); //Module loaded ok
   }
   return('');
}

/** 
 * If the language ID matches one of the builtin 
 * extensions supported by SlickEdit, this function will 
 * attempt to automaticaly load support for the language 
 * if it is not already loaded. 
 * 
 * @param mode_name     Display name for language type 
 * 
 * @return The language ID for the language 
 *         corresponding to 'mode_name'. 
 *  
 * @see _Modename2LangId 
 * @see _Filename2LangId 
 * @see _Ext2LangId 
 *  
 * @categories Miscellaneous_Functions 
 */
_str check_and_load_mode_support(_str mode_name)
{
   // try to find matching def-language for this mode name
   lang := _Modename2LangId(mode_name);
   if ( lang != "" ) {
      return lang;
   }

   // try to auto-load the modename
   typeless i;
   for (i._makeempty();;) {
      VSAUTOLOADEXT *p;
      p= &gAutoLoadExtHashtab._nextel(i);
      if (i._isempty()) {
         break;
      }
      //say('p='p);
      _str modeName=p->modeName;
      if (!modeName._isempty() && _ModenameEQ(modeName,mode_name)) {
         int index=0;
         check_and_load_support(i,index);
         return _Modename2LangId(mode_name);
      }
   }

   // no match found
   return('');
}

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
_command _str current_proc(boolean dosticky_message=true) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   _str msg = 'function';
   _str proc_name='';
   _str type_name='';
   _str caption='';
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
      caption   = 'undefined.';
      proc_name = '';
   }
   if (dosticky_message) {
      sticky_message('The current 'msg' is 'caption);
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
_command _str current_func_signature(boolean dosticky_message=true) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   _str msg = 'function';
   _str type_name='';
   _str return_type='';
   _str caption='';
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
      if (tag_tree_type_is_func(type_name)) {
         tag_get_detail2(VS_TAGDETAIL_context_return, context_id, return_type);
         tag_get_detail2(VS_TAGDETAIL_context_throws, context_id, auto throws);
         caption = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,false);
         if (return_type != '') {
            caption = return_type :+ ' ' :+ caption;
         }
         if (throws != '') {
            caption = caption :+ ' throws ' :+ throws;
         }
      } else {
         return '';
      }
   } else {
      '';
   }
   if (dosticky_message) {
      sticky_message('The current 'msg' is 'caption);
   }
   return(caption);
}

/**
 * Parse elements from current function or method signature. 
 * 
 * @param hashtab 
 * @param first_line 
 * @param last_line 
 * 
 * @return 0 on success 
 */
int _parseCurrentFuncSignature(_str (&hashtab):[][], int &first_line, int &last_line, int &func_start_line)
{
   hashtab._makeempty();
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   int status = 0;
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, auto type_name);
      // are we on a function? 
      if (tag_tree_type_is_func(type_name)) {
         tag_get_detail2(VS_TAGDETAIL_context_return, context_id, auto return_type);
         // return value
         hashtab:['return'][0]=return_type;
         // throws or exception values
         tag_get_detail2(VS_TAGDETAIL_context_throws, context_id, auto throws);
         split(throws, ',', auto throwVals);
         int i = 0;
         for (i = 0; i < throwVals._length(); i++) {
            hashtab:['throws'][i]=throwVals[i];
         }
         // param values
         tag_get_detail2(VS_TAGDETAIL_context_args, context_id, auto args);
         split(args, ',', auto paramVals);
         int counter = 0;
         for (i = 0; i < paramVals._length(); i++) {
            // skip ellipsis
            if (strip(paramVals[i]) != "...") {
               // handle a default value
               int equalsIndex = pos('=',strip(paramVals[i]));
               if (equalsIndex) {
                  paramVals[i] = stranslate(strip(substr(paramVals[i],1,equalsIndex)),'','=');
               }
               // handle pass by reference
               int ampersandIndex = pos('&',strip(paramVals[i]));
               if (ampersandIndex) {
                  paramVals[i] = stranslate(strip(substr(paramVals[i],ampersandIndex)),'','&');
               }
               // handle pointer
               int starIndex = pos('*',strip(paramVals[i]));
               if (starIndex) {
                  paramVals[i] = stranslate(strip(substr(paramVals[i],starIndex)),'','*');
               }
               // handle const 
               int constIndex = pos('const ',strip(paramVals[i]));
               if (constIndex == 1) {
                  paramVals[i] = strip(substr(paramVals[i],6));
               }
               // strip out possible non-identifier characters 
               paramVals[i] = stranslate(paramVals[i],'','[\[\]\(\)\:]+','R');
               split(strip(paramVals[i])," ", auto temp);
               if (temp._length() == 2) {
                  hashtab:['param'][counter++]=temp[1];
               } else {
                  hashtab:['param'][counter++]=temp[0];
               }
            }
         }
         save_pos(auto p);
         // find the first and last lines of the comment
         tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, auto start);
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
_command _str current_class(boolean dosticky_message=true) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   _UpdateContext(true);
   _str cur_context='',cur_package='',caption='';
   _str dn, dt, cur_class;
   int df, di;
   int context_id = tag_get_current_context(dn,df,dt,di,cur_context,cur_class,cur_package);
   if (dosticky_message) {
      if (context_id > 0 && cur_class != '') {
         caption = cur_class;
      } else {
         caption = 'undefined.';
      }
      sticky_message('The current class is 'caption);
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
_command _str current_tag(boolean dosticky_message=true, boolean include_args=false) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   _str caption='';
   int context_id = tag_current_context();
   if (context_id > 0) {
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,include_args,false);
   }
   if (dosticky_message) {
      if (context_id <= 0) {
         caption = 'undefined.';
      }
      sticky_message('The current tag is 'caption);
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
_command _str current_package(boolean dosticky_message=true) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   _UpdateContext(true);
   _str cur_context='',cur_package='',caption='';
   _str dn,dt,dc;int df,di;
   int context_id = tag_get_current_context(dn,df,dt,di,cur_context,dc,cur_package);
   if (dosticky_message) {
      if (context_id>0 && cur_package!='') {
         caption = cur_package;
      } else {
         caption = 'undefined.';
      }
      sticky_message('The current package is 'caption);
   }
   return(cur_package);
}

/**
 * Moves the cursor to the begining of the enclosing statement or
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
      _message_box('Tagging not supported for files of this extension.  Make sure support module is loaded.');
      return(2);
   }
   // Update the complete context information and find nearest tag
   _UpdateContext(true,false,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int seekpos=(int)_QROffset();
   int context_id = tag_nearest_context(p_RLine);
   int num_tags = tag_get_num_of_context();

   if (!context_id) {
      return (1);
   }

   int parent_context=0;
   tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, parent_context );

   // declarations
   int start_line_no=0, start_seekpos=0;
   int scope_line_no=0, scope_seekpos=0;
   int end_line_no=0, end_seekpos=0, this_parent=0;
   _str type_name='';
   int tag_flags=0;
   _str tag_name='';
   _str proc_name='';
   _str file_name='';
   _str class_name='';
   _str signature='';
   _str return_type='';

   if( parent_context > 0 ) {
      tag_get_context(parent_context, proc_name, type_name, file_name,
                      start_line_no, start_seekpos,
                      scope_line_no, scope_seekpos,
                      end_line_no, end_seekpos,
                      class_name, tag_flags, signature, return_type);
      tag_get_detail2(VS_TAGDETAIL_context_name,parent_context,proc_name);
      tag_get_detail2(VS_TAGDETAIL_context_class,parent_context,class_name);
      tag_get_detail2(VS_TAGDETAIL_context_args,parent_context,signature);
      tag_get_detail2(VS_TAGDETAIL_context_return,parent_context,return_type);

      // go to the symbol location
      p_RLine = scope_line_no;
      _GoToROffset(start_seekpos);

      // make sure the symbols is not on a hidden line
      if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
         expand_line_level();
      }

      _UpdateContext(true);
      _UpdateContextWindow(true);
      _proc_found = tag_tree_compose_tag(proc_name, class_name, type_name, tag_flags, signature, return_type);
      return(0);
   }

   return (1);
}

/**
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 */
static void add_tag( int context_id )
{
   int start_line_no=0, start_seekpos=0;
   int scope_line_no=0, scope_seekpos=0;
   int end_line_no=0, end_seekpos=0, this_parent=0;
   _str type_name='';
   int tag_flags=0;
   _str tag_name='';
   _str proc_name='';
   _str file_name='';
   _str class_name='';
   _str signature='';
   _str return_type='';
   int parent_context=0;
   int num_tags = tag_get_num_of_context();

   tag_get_context(context_id, proc_name, type_name, file_name,
                   start_line_no, start_seekpos,
                   scope_line_no, scope_seekpos,
                   end_line_no, end_seekpos,
                   class_name, tag_flags, signature, return_type);
   tag_get_detail2(VS_TAGDETAIL_context_name,context_id,proc_name);
   tag_get_detail2(VS_TAGDETAIL_context_class,context_id,class_name);
   tag_get_detail2(VS_TAGDETAIL_context_args,context_id,signature);
   tag_get_detail2(VS_TAGDETAIL_context_return,context_id,return_type);

   // go to the symbol location
   p_RLine = scope_line_no;
   _GoToROffset(start_seekpos);

   // make sure the symbols is not on a hidden line
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }

   _UpdateContext(true,false,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
   _UpdateContextWindow(true);
   _proc_found = tag_tree_compose_tag(proc_name, class_name, type_name, tag_flags, signature, return_type);
}

/**
 * For synchronization, threads should perform a 
 * tag_lock_context(false) prior to invoking this function. 
 */
static int find_next_sibling( int direction, int context_id )
{
   int seekpos=(int)_QROffset();
   int start_line_no=0, start_seekpos=0,this_parent=0;
   int scope_line_no=0, scope_seekpos=0;
   _str type_name='';
   int tag_flags=0;
   _str tag_name='';
   int parent_context=0;
   int num_tags = tag_get_num_of_context();

   tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, parent_context );

   // search backward for suitable tag
   while (context_id>0 && context_id<=num_tags) {
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
      tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, tag_flags);
      tag_get_detail2(VS_TAGDETAIL_context_name, context_id, tag_name);

      if ((direction < 0 && start_seekpos < seekpos) ||
          (direction > 0 && start_seekpos > seekpos)) {

          tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, this_parent );

         // Does this tag have the same parent
         // as the initial context
         if ( /*tag_filter_type(0,filter_flags,type_name,tag_flags) &&*/
             //!(tag_flags & VS_TAGFLAG_ignore) &&
             !(tag_flags & VS_TAGFLAG_anonymous) && ( parent_context == this_parent ) ) {
            return context_id;
         }
      }
      context_id+=direction;
   }
   return -1;
}

static int do_next_prev_sibling( int direction, int filter_flags=VS_TAGFILTER_ANYPROC, _str quiet='' )
{
   // No support for this extension?
   if ( ! _istagging_supported() ) {
      if (quiet=='') {
         _message_box('Tagging is not supported for files of this extension.  Make sure support module is loaded.');
      }
      return(2);
   }

   // statements not supported?
   if (!_are_statements_supported()) {
      if (quiet=='') {
         _message_box('Statement tagging is not supported for files of this extension.');
      }
      return STRING_NOT_FOUND_RC;
   }

   // Update the complete context information and find nearest tag
   _UpdateContext(true,false,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int seekpos=(int)_QROffset();
   int context_id = tag_nearest_context(p_RLine);
   int num_tags = tag_get_num_of_context();
   if (!context_id) {
      context_id = (direction>0)? 1:num_tags;
   }

   int starting_context_id = context_id;

//   int parent_context=0;
//   tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, parent_context );

   // declarations
   int start_line_no=0, start_seekpos=0;
   int scope_line_no=0, scope_seekpos=0;
   int end_line_no=0, end_seekpos=0, this_parent=0;
   _str type_name='';
   int tag_flags=0;
   _str tag_name='';

   tag_get_detail2(VS_TAGDETAIL_context_name, context_id, tag_name);

   context_id = find_next_sibling( direction, context_id  );

   if( context_id > 0 ) {
      add_tag( context_id  );
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

// move to the next or previous tag in the current context
//    direction    -- 1=next, -1=previous
//    filter_flags -- VS_TAGFITLER_* (default is for procs only)
//
static int do_next_prev_tag(int direction, int filter_flags=VS_TAGFILTER_ANYPROC )
{
   // No support for this extension?
   if ( ! _istagging_supported() ) {
      _message_box('Tagging not supported for files of this extension.  Make sure support module is loaded.');
      return(2);
   }

   // Update the complete context information and find nearest tag
   _UpdateContext(true,false);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int seekpos=(int)_QROffset();
   int context_id = tag_nearest_context(p_RLine,filter_flags);
   int num_tags = tag_get_num_of_context();
   if (!context_id) {
      context_id = (direction>0)? 1:num_tags;
   }

   // declarations
   int start_line_no=0, start_seekpos=0;
   int scope_line_no=0, scope_seekpos=0;
   int end_line_no=0, end_seekpos=0;
   _str type_name='';
   int tag_flags=0;
   _str tag_name='';
   _str proc_name='';
   _str file_name='';
   _str class_name='';
   _str signature='';
   _str return_type='';

   // search backward for suitable tag
   while (context_id>0 && context_id<=num_tags) {
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
      tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, tag_flags);
      tag_get_detail2(VS_TAGDETAIL_context_name, context_id, tag_name);
      if ((direction < 0 && start_seekpos < seekpos) ||
          (direction > 0 && start_seekpos > seekpos)) {
         if (tag_filter_type(0,filter_flags,type_name,tag_flags) &&
             !(tag_flags & VS_TAGFLAG_ignore) && !(tag_flags & VS_TAGFLAG_anonymous)) {

            tag_get_context(context_id, proc_name, type_name, file_name,
                            start_line_no, start_seekpos,
                            scope_line_no, scope_seekpos,
                            end_line_no, end_seekpos,
                            class_name, tag_flags, signature, return_type);
            tag_get_detail2(VS_TAGDETAIL_context_name,context_id,proc_name);
            tag_get_detail2(VS_TAGDETAIL_context_class,context_id,class_name);
            tag_get_detail2(VS_TAGDETAIL_context_args,context_id,signature);
            tag_get_detail2(VS_TAGDETAIL_context_return,context_id,return_type);

            // Skip tags that are statements
            if( tag_tree_type_is_statement(type_name) ) {
               context_id+=direction;
               continue;
            }

            // go to the tag location
            p_RLine = scope_line_no;
            _GoToROffset(start_seekpos);

            // make sure the symbols is not on a hidden line
            if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
               expand_line_level();
            }

            _UpdateContext(true);
            _UpdateContextWindow(true);
            _proc_found = tag_tree_compose_tag(proc_name, class_name, type_name, tag_flags, signature, return_type);
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
static int do_next_prev_statement(int direction, boolean recursive=true, _str quiet='')
{
   // No support for this extension?
   if ( ! _istagging_supported() ) {
      if (quiet=='') {
         _message_box('Tagging is not supported for files of this extension.  Make sure support module is loaded.');
      }
      return(2);
   }

   // statements not supported?
   if (!_are_statements_supported()) {
      if (quiet=='') {
         _message_box('Statement tagging is not supported for files of this extension.');
      }
      return STRING_NOT_FOUND_RC;
   }

   // Update the complete context information and find nearest tag
   _UpdateContext(true,false,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int seekpos=(int)_QROffset();
   //int statement_id = tag_nearest_context(p_RLine);
   int statement_id = tag_current_statement();
   int num_statements = tag_get_num_of_context();
   if (!statement_id) {
      statement_id = (direction>0)? 1:num_statements;
   }

   // if not looking recursively, set starting point as end of current statement
   if (!recursive) {
      int statement_start_seekpos = 0;
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, statement_id, statement_start_seekpos);
      if (direction < 0 && statement_start_seekpos < seekpos) {
         seekpos = statement_start_seekpos;
      }
      int statement_end_seekpos   = 0;
      tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, statement_id, statement_end_seekpos);
      if (direction > 0 && statement_end_seekpos > seekpos) {
         seekpos = statement_end_seekpos;
      }
   }

   // declarations
   int start_line_no=0, start_seekpos=0;
   int scope_line_no=0, scope_seekpos=0;
   int end_line_no=0, end_seekpos=0;
   _str type_name='';
   int tag_flags=0;
   _str tag_name='';
   _str proc_name='';
   _str file_name='';
   _str class_name='';
   _str signature='';
   _str return_type='';

   // search backward for suitable tag
   while (statement_id>0 && statement_id<=num_statements) {
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, statement_id, start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_type, statement_id, type_name);
      tag_get_detail2(VS_TAGDETAIL_context_flags, statement_id, tag_flags);
      tag_get_detail2(VS_TAGDETAIL_context_name, statement_id, tag_name);
      if ((direction < 0 && start_seekpos < seekpos) ||
          (direction > 0 && start_seekpos > seekpos)) {
            tag_get_context(statement_id, proc_name, type_name, file_name,
                            start_line_no, start_seekpos,
                            scope_line_no, scope_seekpos,
                            end_line_no, end_seekpos,
                            class_name, tag_flags, signature, return_type);
            tag_get_detail2(VS_TAGDETAIL_context_name,statement_id,proc_name);
            tag_get_detail2(VS_TAGDETAIL_context_class,statement_id,class_name);
            tag_get_detail2(VS_TAGDETAIL_context_args,statement_id,signature);
            tag_get_detail2(VS_TAGDETAIL_context_return,statement_id,return_type);

            // Skip tags that are statements
            if( !tag_tree_type_is_statement(type_name) && (type_name != 'lvar') ) {
               statement_id+=direction;
               continue;
            }

            // go to the statement location
            p_RLine = scope_line_no;
            _GoToROffset(start_seekpos);

            // make sure the symbols is not on a hidden line
            if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
               expand_line_level();
            }

            _UpdateContext(true);
            _UpdateContextWindow(true);
            _proc_found = tag_tree_compose_tag(proc_name, class_name, type_name, tag_flags, signature, return_type);
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
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command int next_proc(_str quiet="", _str flags="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int filter_flags = VS_TAGFILTER_ANYPROC;
   if (flags!='') {
      filter_flags = VS_TAGFILTER_ANYTHING;
   }
   int status=do_next_prev_tag(1,filter_flags);
   if (quiet=='' && status) {
      message('No next procedure');
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
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command int prev_proc(_str quiet="", _str flags="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int filter_flags = VS_TAGFILTER_ANYPROC;
   if (flags!='') {
      filter_flags = VS_TAGFILTER_ANYTHING;
   }
   int status=do_next_prev_tag(-1,filter_flags);
   if (quiet=='' && status) {
      message('No previous procedure');
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
_command int begin_proc() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id == 0) {
      save_pos(auto p);
      _clex_skip_blanks();
      context_id = tag_current_context();
      restore_pos(p);
   }
   _str type_name='';
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   }
   if (context_id > 0 && tag_tree_type_is_func(type_name)) {
      // go to the function end locaion
      int start_seekpos=0;
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
      _GoToROffset(start_seekpos);
      // make sure the symbols is not on a hidden line
      if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
         expand_line_level();
      }
   } else {
      _str msg="Not in a function or procedure.";
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
_command int end_proc() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id == 0) {
      save_pos(auto p);
      _clex_skip_blanks();
      context_id = tag_current_context();
      restore_pos(p);
   }
   _str type_name='';
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   }
   if (context_id > 0 && tag_tree_type_is_func(type_name)) {
      // go to the function end locaion
      int end_seekpos=0;
      tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
      _GoToROffset(end_seekpos);
      // make sure the symbols is not on a hidden line
      if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
         expand_line_level();
      }
   } else {
      _str msg="Not in a function or procedure.";
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
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command int next_tag(_str quiet="", _str flags="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int filter_flags = def_proctree_flags;
   if (flags!='') {
      filter_flags = VS_TAGFILTER_ANYTHING;
   }
   int status=do_next_prev_tag(1,filter_flags);
   if (quiet=='' && status) {
      message('No next tag');
   }
   return(status);
}

/**
 * Navigate to the next statement in the current buffer.
 * <p>
 * This function is part of statement tagging and only works well
 * for languages that support statement-level tagging.
 * 
 * @return 0 on success, nonzero on error.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int next_statement(_str quiet='') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int status=do_next_prev_statement(1,true,quiet);
   if (quiet=='' && status) {
      message('No next statement');
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
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int begin_statement(_str quiet='') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   if (!_are_statements_supported()) {
      if (quiet=='') {
         _message_box('Statement tagging is not supported for files of this extension.');
      }
      return STRING_NOT_FOUND_RC;
   }
   // Update the complete context information and find nearest tag
   _UpdateContext(true,false,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int seekpos=(int)_QROffset();
   //int statement_id = tag_nearest_context(p_RLine);
   int statement_id = tag_current_statement();
   int num_statements = tag_get_num_of_context();
   if (!statement_id) {
      statement_id = tag_nearest_context(p_RLine);
   }
   if (!statement_id) {
      statement_id = 1;
   }

   // get the statement start seek position
   int statement_start_seekpos = 0;
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, statement_id, statement_start_seekpos);
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
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int end_statement(_str quiet='') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   if (!_are_statements_supported()) {
      if (quiet=='') {
         _message_box('Statement tagging is not supported for files of this extension.');
      }
      return STRING_NOT_FOUND_RC;
   }
   // Update the complete context information and find nearest tag
   _UpdateContext(true,false,VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int seekpos=(int)_QROffset();
   //int statement_id = tag_nearest_context(p_RLine);
   int statement_id = tag_current_statement();
   int num_statements = tag_get_num_of_context();
   if (!statement_id) {
      statement_id = tag_nearest_context(p_RLine);
   }
   if (!statement_id) {
      statement_id = num_statements;
   }

   // get the statement end seek position
   int statement_end_seekpos = 0;
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, statement_id, statement_end_seekpos);
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
_command int next_sibling(_str quiet='') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int status=do_next_prev_sibling(1,VS_TAGFILTER_ANYPROC,quiet);
   if (quiet=='' && status) {
      message('No next sibling');
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
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command int prev_tag(_str quiet="", _str flags="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int filter_flags = def_proctree_flags;
   if (flags!='') {
      filter_flags = VS_TAGFILTER_ANYTHING;
   }
   int status=do_next_prev_tag(-1,filter_flags);
   if (quiet=='' && status) {
      message('No previous tag');
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
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int prev_statement(_str quiet='') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int status=do_next_prev_statement(-1,true,quiet);
   if (quiet=='' && status) {
      message('No previous statement');
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
_command int prev_sibling(_str quiet='') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   int status=do_next_prev_sibling(-1,VS_TAGFILTER_ANYPROC,quiet);
   if (quiet=='' && status) {
      message('No previous sibling');
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
_command int begin_statement_block(_str quiet='') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
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
_command int end_statement_block(_str quiet='') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
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
 * Navigate to end of current tag.
 * This function uses the same flags as the proc tree on the
 * project toolbar, so you can use that to filter out certain tags.
 *
 * @return 0 on success, nonzero on error.
 * 
 * @see next_tag
 * @see prev_tag
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int end_tag() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id == 0) {
      save_pos(auto p);
      _clex_skip_blanks();
      context_id = tag_current_context();
      restore_pos(p);
   }
   if( context_id<=0 ) {
      _str msg='';
      if( context_id==0 ) {
         msg="No current context.";
      } else {
         msg=get_message(context_id);
      }
      message(msg);
      return(1);
   }

   // get the statement start seek position
   int end_seekpos=0;
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
   _GoToROffset(end_seekpos);

   // make sure the symbols is not on a hidden line
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }
   return(0);
}

/**
 * Navigate to end of current tag.
 * This function uses the same flags as the proc tree on the
 * project toolbar, so you can use that to filter out certain tags.
 *
 * @return 0 on success, nonzero on error.
 * 
 * @see next_tag
 * @see prev_tag
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command int begin_tag() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id == 0) {
      save_pos(auto p);
      _clex_skip_blanks('-');
      context_id = tag_current_context();
      restore_pos(p);
   }
   if( context_id<=0 ) {
      _str msg='';
      if( context_id==0 ) {
         msg="No current context.";
      } else {
         msg=get_message(context_id);
      }
      message(msg);
      return(1);
   }

   // get the statement start seek position
   int start_seekpos=0;
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
   _GoToROffset(start_seekpos);

   // make sure the symbols is not on a hidden line
   if (!p_IsTempEditor && (_lineflags() & HIDDEN_LF)) {
      expand_line_level();
   }
   return(0);
}

/**
 * Hides lines in the current buffer which are not part of the current
 * function.
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
 * @categories Search_Functions, Selective_Display
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

   // is there a tag under the cursor?
   restore_pos(p);
   int this_context_id = tag_current_context();
   int near_context_id = tag_nearest_context(p_RLine);
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
_command tag_close_all() name_info(TAG_ARG',')
{
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
   if (dbfilename==null || dbfilename=='') {
      dbfilename=tag_current_db();
   }
   if (dbfilename=='') {
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
#if !__UNIX__
   if (machine()=='WINDOWS' && _win32s()!=1) {
      _str refs_database = refs_filename();
      if (refs_database != '' && "."lowcase(_get_extension(refs_database)) :== BSC_FILE_EXT) {
         //tag_read_db(refs_database);
         return tag_close_db(absolute(refs_database));
      }
   }
#endif
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
   index := _FindLanguageCallbackIndex('_%s_list_occurrences',lang);
   save_pos(auto p);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   int result=0;
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

//////////////////////////////////////////////////////////////////////////
// Tag Select Form


// Timer for refreshing tagwin when scrolling through diff tree
static int gTagSelectTimerId=-1;

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (before defload).  Used to
// initialize the timer variable and window IDs.
//
definit()
{
   // IF editor is initalizing from invocation
   if (arg(1)!='L') {
      gTagSelectTimerId=-1;
   }
   // Empty Eclipse mode macros
   eclipseExtMap._makeempty();
   gTagFilesThatCantBeRebuilt._makeempty();
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Open the given file in a temporary view, and insert all the tags from
// that file into the tree control, which is the current object.
//
static int BuildTagList(_str filename)
{
   // save the tree wid, and open the file
   int form_wid=p_active_form;
   int tree_wid=p_window_id;
   int temp_view_id, orig_view_id;
   boolean buffer_already_exists=false;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id,'',buffer_already_exists,false,true);
   if (status) {
      return(status);
   }

   // update the current context
   _str orig_context_file='';
   tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_push_context();
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // insert the tags from the current context into the tree, no heirarchy
   // path up the user info with start line and end line
   cb_prepare_expand(form_wid,tree_wid,TREE_ROOT_INDEX);
   tree_wid._TreeDelete(TREE_ROOT_INDEX,'C');
   int i, n=tag_get_num_of_context();
   for (i=1; i<=n; i++) {
      int j=tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      // is this a function, procedure, or prototype?
      _str type_name='';
      int tag_flags=0;
      int startline=0,endline=0;
      tag_get_detail2(VS_TAGDETAIL_context_type,i,type_name);
      tag_get_detail2(VS_TAGDETAIL_context_flags,i,tag_flags);
      if (tag_filter_type(0,def_tagselect_flags,type_name,tag_flags)) {
         tag_get_detail2(VS_TAGDETAIL_context_start_linenum,i,startline);
         tag_get_detail2(VS_TAGDETAIL_context_end_linenum,i,endline);
         tag_get_detail2(VS_TAGDETAIL_context_file,i,filename);
         j=tag_tree_insert_fast(tree_wid,TREE_ROOT_INDEX,VS_TAGMATCH_context,i,1,-1,0,1,1,
                                startline' 'endline' 'type_name);
      }
   }

   // sort the items in the tree alphabetically
   tree_wid._TreeTop();
   if (def_tag_select_options&PROC_TREE_SORT_FUNCTION) {
      tree_wid._TreeSortCaption(TREE_ROOT_INDEX,'i');
   }

   // close the temporary view and restore the context
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_pop_context();
   return(0);
}

// Refresh the list of symbols in case if the filters have changed
void _tagselect_refresh_symbols()
{
   _nocheck _control ctlfilename;
   _TreeBeginUpdate(TREE_ROOT_INDEX,'','T');
   BuildTagList(p_active_form.ctlfilename.p_user);
   _TreeEndUpdate(TREE_ROOT_INDEX);
   p_redraw=1;
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Event table for tag selector form
//
defeventtab _tag_select_form;

#define NO_TAG_ISEARCH ctlname_prefix.p_user
#define NO_FILL_IN_CB  ctl_tag_tree_view.p_user

// handle OK button press (successful finish)
void ctlok.lbutton_up()
{
   int index=ctl_tag_tree_view._TreeCurIndex();
   if (index <= 0) {
      p_active_form._delete_window('');
      return;
   }
   _str FuncName=ctl_tag_tree_view._TreeGetCaption(index);
   _str LineInfo=ctl_tag_tree_view._TreeGetUserInfo(index);

   //Before we save the form response, complete the text in the text box
   //so the retrieval looks nice.
   ctlname_prefix.p_text=FuncName;
   _save_form_response();
   p_active_form._delete_window(FuncName:+_chr(1):+LineInfo);
}

// initialize form when it is created, load tags from file
void ctlok.on_create(_str filename=null,_str caption=null)
{
   if (filename==null) {
      filename=_mdi.p_child.p_buf_name;
   }
   ctlfilename.p_caption=ctlfilename._ShrinkFilename(filename,ctlfilename.p_width);
   ctlfilename.p_user=filename;
   ctlline.p_caption='';

   ctl_tag_tree_view.BuildTagList(filename);
   ctl_tag_tree_view._TreeTop();
   if (caption!='') {
      int index=ctl_tag_tree_view._TreeSearch(TREE_ROOT_INDEX,caption);
      if (index>=0) {
         ctl_tag_tree_view._TreeSetCurIndex(index);
      }
   }
   ctlname_prefix._retrieve_list();
}

// kill the timer
void ctlok.on_destroy()
{
   if (gTagSelectTimerId != -1) {
      _kill_timer(gTagSelectTimerId);
      gTagSelectTimerId=-1;
   }
}

static void SearchTreeForPrefix()
{
   _str text=ctlname_prefix.p_text;
   int wid=p_window_id;
   p_window_id=ctl_tag_tree_view;
   int index=_TreeSearch(TREE_ROOT_INDEX,text,'ip');
   if (index>-1) {
      _TreeSetCurIndex(index);
   }
   p_window_id=wid;
}

void ctlname_prefix.on_change(int reason)
{
   if (NO_TAG_ISEARCH==1) return;
   NO_FILL_IN_CB=1;
   SearchTreeForPrefix();
   NO_FILL_IN_CB=0;
}


/**
 * Retrieve information about the given tag in the given file
 *
 * @param filename       Source code file to search
 * @param tag_name       name of tag to look for
 * @param tag_caption    displayed caption for tag
 * @param StartLine      (reference) start line
 * @param LastLine       (reference) last line
 * @param TagType        (reference) set to unique tag information
 * @param pcm            (pointer) all tag information
 *
 * @return 0 on success, nonzero otherwise
 */
int FindSymbolInfo(_str filename,
                   _str tag_name, _str tag_caption,
                   int &StartLine, int &LastLine,
                   int &CommentLine, _str &TagType,
                   struct VS_TAG_BROWSE_INFO *pcm=null,
                   boolean AlwaysLoadFromDisk=false)
{
   // open the file in a temporary view
   boolean buffer_already_exists=false;
   int temp_view_id, orig_view_id;
   _str LoadOptions='';
   if (AlwaysLoadFromDisk) {
      LoadOptions='+d';
   }
   int status=_open_temp_view(filename,temp_view_id,orig_view_id,LoadOptions,buffer_already_exists,false,true);
   if (status) {
      return(status);
   }

   // update the current context
   _str orig_context_file='';
   tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_push_context();
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // search for the tag within the current context
   _str type_name='';
   int start_line_no=0, start_seekpos=0, end_line_no=0;
   int context_id = tag_find_context_iterator(tag_name,1,1);
   while (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
      if (TagType=='' || type_name==TagType) {
         _str caption=tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,true);
         if (tag_caption=='' || caption==tag_caption) {
            tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, start_line_no);
            tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_end_linenum,   context_id, end_line_no);
            if (StartLine==0) {
               StartLine=(int)start_line_no;
               LastLine=(int)end_line_no;
               TagType=type_name;
               if (pcm!=null) {
                  _GetContextTagInfo(*pcm,'',tag_name, filename, start_line_no);
               }
               break;
            } else if (StartLine==start_line_no && LastLine==end_line_no) {
               if (pcm!=null) {
                  _GetContextTagInfo(*pcm,'',tag_name, filename, start_line_no);
               }
               break;
            }
         }
      }
      context_id = tag_next_context_iterator(tag_name,context_id,1,1);
      // didn't find the tag with matching caption, try just tag name
      if (tag_caption!='' && context_id < 0 && StartLine==0) {
         tag_caption='';
         context_id = tag_find_context_iterator(tag_name,1,1);
      }
   }

   // If we got the tag, find the start line, otherwise, use startline
   CommentLine = StartLine;
   if (context_id>0 && start_seekpos>0) {
      _GoToROffset(start_seekpos);
      typeless unused;
      _do_default_get_tag_header_comments(CommentLine,unused);
      if (!CommentLine) {
         CommentLine=StartLine;
      }
   }

   // close the temp view and clean up
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_pop_context();
   return (context_id > 0)? 0:1;
}

/**
 * Retrieve information about the tag with the given caption.
 * If the caption is initially empty, prompt the user with
 * the list of tags, and let them select one.
 *
 * @param filename       (required) name of file to list tags in
 * @param caption        (reference) If empty, let user select caption,
 *                                   otherwise, caption to search for
 * @param StartLine      (reference) set to first line of tag
 * @param LastLine       (reference) set to last line of tag
 * @param TagType        (reference) set to unique tag information
 * @param pcm            (optional) contains rest of tag info
 *
 * @return 0 on success, nonzero on error.
 */
int GetSymbolInfo(_str filename, _str &caption,
                  int &StartLine,int &LastLine,int &CommentLine,_str &TagType,
                  struct VS_TAG_BROWSE_INFO *pcm=null,
                  boolean AlwaysLoadFromDisk=false)
{
   // initialize the tag browse info if we were given any
   if (pcm!=null) {
      tag_browse_info_init(*pcm);
   }

   // display the form
   int OrigWID=p_window_id;
   _str Info=show('-modal -reinit -xy _tag_select_form',filename,caption);
   if (Info=='') {
      return(COMMAND_CANCELLED_RC);
   }

   // parse up the results and return
   _str sStartLine,sLastLine;
   parse Info with caption (_chr(1)) sStartLine sLastLine TagType . ;
   StartLine=(int)sStartLine;
   LastLine=(int)sLastLine;
   _str tag_name;
   tag_tree_decompose_caption(caption,tag_name);
   p_window_id=OrigWID;
   FindSymbolInfo(filename,tag_name,caption,StartLine,LastLine,CommentLine,TagType,pcm,AlwaysLoadFromDisk);
   return(0);
}

// Bring up filter menu for tag dialog
void ctl_tag_tree_view.rbutton_up()
{
   // Get handle to menu:
   int index=find_index("_tagbookmark_menu",oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'P');

   if (def_tag_select_options&PROC_TREE_SORT_FUNCTION) {
      _menu_set_state(menu_handle,"sortfunc",MF_CHECKED,'C');
   }else if (def_tag_select_options&PROC_TREE_SORT_LINENUMBER) {
      _menu_set_state(menu_handle,"sortlinenum",MF_CHECKED,'C');
   }

   pushTgConfigureMenu(menu_handle, def_tagselect_flags, false, false, true);

   // Show menu:
   int x,y;
   mou_get_xy(x,y);
   _KillToolButtonTimer();
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

// Timer callback, called from the on_change() event of the tree
// control, whenever the selected item in the tree changes.
//
// Used to update the output symbol tab, in order to preview
// tag choices.
//
static void _TagSelectTimerCallback()
{
   // kill the timer
   if (gTagSelectTimerId != -1) {
      _kill_timer(gTagSelectTimerId);
      gTagSelectTimerId=-1;
   }

   // find the tagform
   _nocheck _control ctl_tag_tree_view;
   _nocheck _control ctlfilename;
   int wid=_find_object("_tag_select_form","n");
   if (!wid) return;

   // update the property view, call tree view, and output tab
   int index=wid.ctl_tag_tree_view._TreeCurIndex();
   _str file_name=wid.ctlfilename.p_user;
   _str uinfo=wid.ctl_tag_tree_view._TreeGetUserInfo(index);
   _str line_no='';
   parse uinfo with line_no ' ' . ;
   _str caption=wid.ctl_tag_tree_view._TreeGetCaption(index);
   tag_tree_decompose_caption(caption,caption);

   // find the output tagwin and update it
   VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   cm.file_name = file_name;
   cm.line_no   = (int) line_no;
   cm.member_name = caption;
   cb_refresh_output_tab(cm, true, true);
}

// Handle change selected or selections (double-click/enter)
// in the tree control
void ctl_tag_tree_view.on_change(int reason, int index)
{
   if (reason == CHANGE_SELECTED) {
      _str startline,endline;
      parse _TreeGetUserInfo(index) with startline endline .;
      ctlline.p_caption=nls("Line range: %s - %s",startline,endline);

      if (gTagSelectTimerId != -1) {
         _kill_timer(gTagSelectTimerId);
         gTagSelectTimerId=-1;
      }
      if (_GetTagwinWID(true)) {
         int timer_delay=max(200,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
         gTagSelectTimerId=_set_timer(timer_delay, _TagSelectTimerCallback);
      }

      NO_TAG_ISEARCH=1;

      if (NO_FILL_IN_CB!=1) {
         int wid=p_window_id;
         _str text=_TreeGetCaption(index);
         p_window_id=ctlname_prefix;
         p_text=text;_set_sel(1);_refresh_scroll();
         _set_sel(1,length(p_text)+1);
         p_window_id=wid;
      }

      NO_TAG_ISEARCH=0;

   } else if (reason == CHANGE_LEAF_ENTER) {
      ctlok.call_event(ctlok,LBUTTON_UP);
   }
}

void ctl_tag_tree_view.'a'-'z','_','A'-'Z'()
{
   int wid=p_window_id;
   p_window_id=ctlname_prefix;
   _str ch=last_event();
   _set_focus();
   call_event(p_window_id,ch);
   p_window_id=wid;
}

// handle resizing the dialog
void _tag_select_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int tree_y = ctl_tag_tree_view.p_y;
   int button_width  = ctlok.p_width;
   int button_height = ctlok.p_height;

   // force size of dialog to remain reasonable
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*3, button_height*4);
   }

   // available space and border usage
   int avail_x, avail_y, border_x, border_y;
   avail_x  = p_width;
   avail_y  = p_height;
   border_x = ctlfilename.p_x;
   border_y = ctlfilename.p_y;

   // size the tree controls
   ctl_tag_tree_view.p_width  = avail_x - border_x*2;
   ctl_tag_tree_view.p_height = avail_y - border_y*2 - button_height - tree_y;
   ctlline.p_x= avail_x - border_x - ctlline.p_width;
   ctlfilename.p_width = avail_x - border_x*3 - ctlline.p_width;
   ctlfilename.p_caption = ctlfilename._ShrinkFilename(ctlfilename.p_user,ctlfilename.p_width);

   // move the buttons up/down
   ctlok.p_y     = avail_y - border_y - button_height;
   ctlcancel.p_y = avail_y - border_y - button_height;
   ctlname_prefix.p_width=ctl_tag_tree_view.p_width;
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Event table for generic tagging "Cancel" button.
//

static _str gdisabled_wid_list='';
static boolean gbuild_cancel=false;
defeventtab _buildtag_form;
_buildcancel.lbutton_up()
{
   gbuild_cancel=1;
   _enable_non_modal_forms(1,0,gdisabled_wid_list);
   gdisabled_wid_list='';
   p_active_form._delete_window();
}
void _buildtag_form.on_close()
{
   if (_buildcancel.p_visible) {
      _buildcancel.call_event(_buildcancel,LBUTTON_UP,'W');
   }
}

_buildcancel.on_create(_str title=null,_str LabelText=null,boolean allowCancel=true,boolean showGuage=false)
{
   if (title!=null) {
      p_active_form.p_caption=title;
   }
   if (LabelText!=null) {
      ctllabel1.p_caption=LabelText;
   }
   gbuild_cancel=false;
   if (!allowCancel) {
      _buildcancel.p_visible=false;
   }
   if (!showGuage) {
      ctl_progress.p_visible=false;
   }
   if (allowCancel && !showGuage) {
      _buildcancel.p_x = (p_active_form.p_width-_buildcancel.p_width) / 2;
   }
   if (!allowCancel && showGuage) {
      ctl_progress.p_width += (ctl_progress.p_x - _buildcancel.p_x);
      ctl_progress.p_x = _buildcancel.p_x;
      ctl_progress.p_max=ctl_progress.p_client_width;
   }
   ctllabel2.p_user = 0;
   ctl_progress.p_user = 0;
}
_buildcancel.on_destroy()
{
   gbuild_cancel=1;
   if (gdisabled_wid_list!='') {
      _enable_non_modal_forms(1,0,gdisabled_wid_list);
      gdisabled_wid_list='';
   }
}
boolean cancel_form_cancelled(int checkFrequency=250)
{
   // check when this function was called 
   if (checkFrequency > 0) {
      static typeless last_time;
      typeless this_time = _time('b');
      if ( isnumber(last_time) && this_time-last_time < checkFrequency ) {
         return false;
      }
      last_time = this_time;
   }

   // prepare to safely call process events
   int orig_use_timers=_use_timers;
   int orig_def_actapp=def_actapp;
   def_actapp=0;
   _use_timers=0;
   int orig_view_id=p_window_id;
   activate_window(VSWID_HIDDEN);
   int orig_hidden_buf_id=p_buf_id;
   typeless orig_hidden_pos;
   save_pos(orig_hidden_pos);

   // process mouse clicks, redraws, etc
   process_events(gbuild_cancel);

   // restore everything after calling process events
   activate_window(VSWID_HIDDEN);
   p_buf_id=orig_hidden_buf_id;
   restore_pos(orig_hidden_pos);
   activate_window(orig_view_id);
   _use_timers=orig_use_timers;
   def_actapp=orig_def_actapp;
   return gbuild_cancel;
}
void close_cancel_form(int buildform_wid)
{
   if (!buildform_wid) return;
   if (!gbuild_cancel) {
      _enable_non_modal_forms(1,0,gdisabled_wid_list);
      // workaround for disabled parent window
      int parent_form_wid = cancel_form_get_parent();
      boolean restore_parent_disabled = false;
      if (parent_form_wid && !parent_form_wid.p_enabled) {
         parent_form_wid.p_enabled = true;
         restore_parent_disabled = false;
      }
      buildform_wid._delete_window();
      if (restore_parent_disabled) {
         parent_form_wid.p_enabled = false;
      }
   }
}
struct CANCEL_PARENT_INFO {
   _str name;
   int wid;
}gCancelParent;

/**
 * Set the parent for the cancel_form (see <B>show_cancel_form</B>
 *
 * When done, you can call this function with 0, but it is not necessary because of
 * the validation that is performed.
 *
 * @param ParentWid Window to set as parent
 */
void cancel_form_set_parent(int ParentWid)
{
   if ( _iswindow_valid(ParentWid) ) {
      gCancelParent.name=ParentWid.p_name;
      gCancelParent.wid=ParentWid;
   }else{
      gCancelParent.name='';
      gCancelParent.wid=0;
   }
}
/**
 * @return the current parent for the cancel_form (see <B>show_cancel_form</B>
 * If the last one set is invalid, it returns the current window id
 */
static int cancel_form_get_parent()
{
   // First be sure the window id is still valid
   if ( _iswindow_valid(gCancelParent.wid) ) {
      // Now check to see if it is still the same dialog
      if ( gCancelParent.name==gCancelParent.wid.p_name ) {
         return(gCancelParent.wid);
      }
   }
   // If the parent was invalid, we don't want to use it again
   gCancelParent.wid=0;
   gCancelParent.name='';
   return(p_window_id);
}
int show_cancel_form(_str title,_str LabelText=null,boolean allowCancel=true,boolean showGuage=false)
{
   gbuild_cancel=false;
   int wid = cancel_form_get_parent().show('_buildtag_form',title,LabelText,allowCancel,showGuage);
   gdisabled_wid_list=_enable_non_modal_forms(0,wid);
   return(wid);
}
int show_cancel_form_on_top(_str title,_str LabelText=null,boolean allowCancel=true,boolean showGuage=false)
{
   gbuild_cancel=false;
   int wid = cancel_form_get_parent().show('-mdi _buildtag_form',title,LabelText,allowCancel,showGuage);
   gdisabled_wid_list=_enable_non_modal_forms(0,wid);
   return(wid);
}
void cancel_form_set_labels(int buildform_wid,_str LabelText1='',_str LabelText2='')
{
   if (!buildform_wid) return;
   if (LabelText1 != null) {
      buildform_wid.ctllabel1.p_caption=LabelText1;
   }

   _control ctllabel2;
   if (LabelText2!=null) {
      buildform_wid.ctllabel2.p_caption=LabelText2;
   }
}
boolean cancel_form_progress(int buildform_wid, int n, int total)
{
   if (!buildform_wid) return false;
   _control ctllabel2;
   if (total > 0) {
      int pixel_width=buildform_wid.ctl_progress.p_max;
      if (total > 200000) {
         total /= 1000;
         n /= 1000;
      }
      int new_value=(n*pixel_width intdiv total);
      buildform_wid.ctl_progress.p_user = total;
      buildform_wid.ctllabel2.p_user = n;
      if (buildform_wid.ctl_progress.p_value != new_value) {
         buildform_wid.ctl_progress.p_value = new_value;
         buildform_wid.ctl_progress.refresh('w');
         return true;
      }
      return(false);
   }
   return(false);
}
int cancel_form_max_label2_width(int buildform_wid)
{
   return(_dx2lx(SM_TWIP,buildform_wid.p_client_width)-buildform_wid.ctllabel1.p_x*2);
}
int cancel_form_text_width(int buildform_wid, _str msg)
{
   return(buildform_wid.ctllabel1._text_width(msg));
}
int cancel_form_wid()
{
   static int last_wid;
   int wid=0;
   if (_iswindow_valid(last_wid) &&
       last_wid.p_object==OI_FORM &&
       !last_wid.p_edit &&
       last_wid.p_name=="_buildtag_form"){
      wid=last_wid;
   }else{
      wid=_find_formobj("_buildtag_form",'N');
      last_wid=wid;
   }
   return(wid);
}
/**
 * This function is used to update the progress bar as a
 * single file is parsed.  This is used primarily for large
 * files, such as JAR files or .NET DLL's.
 */
int cancel_form_update_progress2(_str LabelText2, int n, int total)
{
   int buildform_wid=cancel_form_wid();
   if (buildform_wid <= 0) {
      return 0;
   }

   boolean buildform_cancelled = cancel_form_cancelled();
   if (buildform_cancelled) {
      return COMMAND_CANCELLED_RC;
   }

   int width=cancel_form_max_label2_width(buildform_wid);
   LabelText2=buildform_wid._ShrinkFilename(LabelText2,width);
   cancel_form_set_labels(buildform_wid,null,LabelText2);

   _control ctllabel2;
   int base_n=buildform_wid.ctllabel2.p_user;
   int base_total=buildform_wid.ctl_progress.p_user;
   int max_n=buildform_wid.ctl_progress.p_max;
   if (base_n == null || base_total == null || !isuinteger(base_n) || !isuinteger(base_total)) {
      return 1;
   }

   int total_total = total * base_total;
   int total_n     = total * base_n + n;

   if (total_total > 0) {
      buildform_wid.ctl_progress.p_value = (total_n*max_n) intdiv total_total;
   }

   return 1;
}

_str class_match(_str name,boolean find_first)
{
   // used to iterate through match set
   static int match_index;

   // temporaries
   _str cur_tag_name='',cur_class_name='',cur_type_name='';
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
         cur_class_name='';
         tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
      }

      // find classes which match our requirements
      int num_matches=0;
      GCindex := _FindLanguageCallbackIndex('_%s_get_matches');
      if (GCindex) {
         num_matches = call_index(name,cur_class_name,
                                  VS_TAGFILTER_STRUCT|VS_TAGFILTER_UNION|VS_TAGFILTER_INTERFACE,
                                  true, case_sensitive, GCindex);
      } else {
         num_matches = _do_default_get_matches(name,cur_class_name,
                                               VS_TAGFILTER_STRUCT|VS_TAGFILTER_UNION|VS_TAGFILTER_INTERFACE,
                                               true, case_sensitive);
      }

      // did we find anything?
      if (num_matches <= 0) {
         return '';
      }

      // initialize iterator for match set
      match_index=0;
   }

   // loop until we find a class or package
   while (++match_index <= tag_get_num_of_matches()) {
      typeless tag_files = tags_filenamea();
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
   return '';
}

static void _TagSelectTreeTimerCallback()
{
   // kill the timer
   if (gTagSelectTimerId != -1) {
      _kill_timer(gTagSelectTimerId);
      gTagSelectTimerId=-1;
   }

   // find the tagform
   _nocheck _control ctl_tree;
   int wid=_find_object("_select_tree_form","n");
   if (!wid) return;

   // update the property view, call tree view, and output tab
   int index=wid.ctl_tree._TreeCurIndex();
   if (index <= 0) return;
   _str uinfo=wid.ctl_tree._TreeGetUserInfo(index);
   if (isuinteger(uinfo) && uinfo <= tag_get_num_of_matches()) {
      VS_TAG_BROWSE_INFO cm;
      tag_get_match_info((int)uinfo, cm);
      tag_push_matches();
      cb_refresh_output_tab(cm, true, true, true);
      tag_pop_matches();
   }
}

static sortProcsAndProtos(int codehelpFlags)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(false);

   // Copy all the matches from the tree
   boolean isProto[];
   int matchIds[];
   _str captions[];
   int bitmaps[];
   i := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   j := 0;
   while ( i > 0) {
      
      matchId := _TreeGetUserInfo(i);
      isProto[j] = false;
      matchIds[j] = matchId;
      captions[j] = _TreeGetCaption(i);
      _TreeGetInfo(i, auto show_children, bitmaps[j]);
      tag_get_detail2(VS_TAGDETAIL_match_type, matchId, auto typeName); 
      if (typeName == "proto" || typeName == "procproto") {
         isProto[j] = true;
      }
      tag_get_detail2(VS_TAGDETAIL_match_flags, matchId, auto tagFlags); 
      if (tagFlags & VS_TAGFLAG_forward) {
         isProto[j] = true;
      }

      i = _TreeGetNextSiblingIndex(i);
      j++;
   }

   // Do they want procs or prototypes first?
   preferProtos := false;
   if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) {
      preferProtos = true;
   }

   // Insert the preferred stock
   _TreeBeginUpdate(TREE_ROOT_INDEX);
   _TreeDelete(TREE_ROOT_INDEX, "C");
   for (i=0; i<isProto._length(); i++) {
      if (isProto[i] == preferProtos) {
         _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                      TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                      TREE_NODE_LEAF, 0, matchIds[i]);
      }
   }
   // Then insert the other matches
   for (i=0; i<isProto._length(); i++) {
      if (isProto[i] != preferProtos) {
         _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                      TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                      TREE_NODE_LEAF, 0, matchIds[i]);
      }
   }
   _TreeEndUpdate(TREE_ROOT_INDEX);
   _TreeTop();
}

static _str tag_select_callback(int sl_event, typeless user_data, typeless info=null)
{
   switch (sl_event) {
   case SL_ONINITFIRST:
      // move defs or procs up to the top of the list depending on the
      // user's preferences.
      if (!_no_child_windows()) {
         lang := _mdi.p_child.p_LangId;
         codehelpFlags := _GetCodehelpFlags(lang);
         if ((codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) ||
             (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION)) {
            tree_wid := _find_control("ctl_tree");
            if (tree_wid > 0) {
               tree_wid.sortProcsAndProtos(codehelpFlags);
            }
         }
      }
      // Add custom controls to show proc/proto preference options
      // if the options are not already set
      last_command := name_name(last_index());
      if ((last_command == 'push-tag' || 
           last_command == 'find-tag' || 
           last_command == 'f' ||
           last_command == 'mou-push-tag' ||
           last_command == 'gui-push-tag' ||
           last_command == 'goto-tag' ||
           last_command == 'gnu-goto-tag' ||
           last_command == 'vi-split-to-tag' ) &&
          (_no_child_windows() == false) && 
          (_mdi.p_child._GetCodehelpFlags() & VSCODEHELPFLAG_FIND_TAG_HIDE_OPTIONS) == 0)  {
         bottom_wid := _find_control("ctl_bottom_pic");
         label1_wid := _create_window(OI_LABEL, bottom_wid, "Prioritize navigation to:", 0, 30, bottom_wid.p_width, 250, CW_CHILD);
         combo1_wid := _create_window(OI_COMBO_BOX, bottom_wid, "", 0, 300, bottom_wid.p_width, 300, CW_CHILD);
         check3_wid := _create_window(OI_CHECK_BOX, bottom_wid, "Ignore forward class declarations", 0, 570, bottom_wid.p_width, 300, CW_CHILD);
         check4_wid := _create_window(OI_CHECK_BOX, bottom_wid, "Do not show these options again", 0, 840, bottom_wid.p_width, 300, CW_CHILD);
         bottom_wid.p_height = 1200;
         bottom_wid.p_visible = bottom_wid.p_enabled = true;
         label1_wid.p_width = label1_wid._text_width(label1_wid.p_caption)+600;
         check3_wid.p_width = check3_wid._text_width(check3_wid.p_caption)+600;
         check4_wid.p_width = check4_wid._text_width(check4_wid.p_caption)+600;
         combo1_wid.p_name = 'ctlnavigation';
         check3_wid.p_name = "ctlignoreforwardclass";
         check4_wid.p_name = "ctlhideoptions";

         combo1_wid.p_style = PSCBO_NOEDIT;
         combo1_wid._lbadd_item('Prompt');
         combo1_wid._lbadd_item('Symbol definition (proc)');
         combo1_wid._lbadd_item('Symbol declaration (proto)');
         codehelpFlags := LanguageSettings.getCodehelpFlags(_mdi.p_child.p_LangId);
         value := '';
         if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION) {
            value = 'Symbol definition (proc)';
         } else if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) {
            value = 'Symbol declaration (proto)';
         } else {
            value = 'Prompt';
         }
         combo1_wid._lbfind_and_select_item(value);
         combo1_wid.p_width = combo1_wid._text_width('Symbol declaration (proto)')+600;

         combo1_wid.p_eventtab = defeventtab _language_tagging_form.ctlnavigation;
         combo1_wid.p_eventtab2 = defeventtab _ul2_combobx;
         check3_wid.p_value = (codehelpFlags & VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS)? 0:1;
         check4_wid.p_value = 0;
      }
      // bind keys to commands to scroll the preview window
      p_active_form._MakePreviewWindowShortcuts();
      break;
   case SL_ONCLOSE:
      // check custom controls for proc/proto preference options
      if (!_no_child_windows()) {
         lang := _mdi.p_child.p_LangId;
         codehelpFlags := _GetCodehelpFlags(lang);
         wid := p_active_form._find_control('ctlnavigation');
         if (wid) {
            if (wid.p_text == 'Symbol definition (proc)') {
               codehelpFlags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION;
               codehelpFlags &= ~ VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION;
            } else if (wid.p_text == 'Symbol declaration (proto)') {
               codehelpFlags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION;
               codehelpFlags &= ~ VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION;
            } else {
               codehelpFlags &= ~(VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION | VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION);
            }
         }
         wid = p_active_form._find_control('ctlignoreforwardclass');
         if (wid) {
            if (wid.p_value) {
               codehelpFlags  &= ~VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS;
            } else {
               codehelpFlags |= VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS;
            }
         }
         wid = p_active_form._find_control('ctlhideoptions');
         if (wid) {
            if (wid.p_value) {
               codehelpFlags |= VSCODEHELPFLAG_FIND_TAG_HIDE_OPTIONS;
            } else {
               codehelpFlags  &= ~VSCODEHELPFLAG_FIND_TAG_HIDE_OPTIONS;
            }
         }
         if (codehelpFlags != _GetCodehelpFlags(lang)) {
            LanguageSettings.setCodehelpFlags(lang, codehelpFlags);
         }
      }
      // drop through to kill timer
   case SL_ONINIT:
      if (gTagSelectTimerId != -1) {
         _kill_timer(gTagSelectTimerId);
         gTagSelectTimerId=-1;
      }
      break;
   case SL_ONSELECT:
      if (gTagSelectTimerId != -1) {
         _kill_timer(gTagSelectTimerId);
         gTagSelectTimerId=-1;
      }
      if (_GetTagwinWID(false) || _tbIsAuto("_tbtagwin_form",true)) {
         int timer_delay=max(200,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
         gTagSelectTimerId=_set_timer(timer_delay, _TagSelectTreeTimerCallback);
      }
      break;
   }
   return "";
}


/**
 * Display a dialog for selecting a tag match among the tags in
 * the current tag match set.
 * 
 * @return match ID > 0 on success, <0 on error,
 *         COMMAND_CANCELLED_RC on user cancellation.
 */
int tag_select_match(int codehelpFlags=0)
{
   _str captions[];
   _str match_ids[];
   int pictures[];

   boolean been_there_done_that:[];
   typeless match_id=0;
   _str caption='';
   _str key='';
   int leaf_flag=0;
   int pic_member=0;
   int i_access=0;
   int i_type=0;
   int index=0;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(false);

   int i, m=0, n = tag_get_num_of_matches();
   if (n == 0) {
      // error, no matches
      return BT_RECORD_NOT_FOUND_RC;
   }

   cb_prepare_expand(p_active_form,0,TREE_ROOT_INDEX);
   VS_TAG_BROWSE_INFO cm;

   // first get the matches that have seek positions
   for (i=1; i<=n; ++i) {
      tag_browse_info_init(cm);
      tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, i, cm.seekpos);
      tag_get_detail2(VS_TAGDETAIL_match_start_linenum, i, cm.line_no);
      if (cm.seekpos < 0 || (cm.seekpos==0 && cm.line_no>1)) {
         continue;
      }
      tag_get_match_info(i, cm);
      //if (_QLoadTagsSupported(cm.filename)) {
      //   continue;
      //}
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_match, i, true, true, false);
      key = caption:+"\t":+cm.file_name;
      been_there_done_that:[key] = true;
      key = caption:+"\t":+cm.file_name:+"\t":+cm.line_no:+"\t":+cm.seekpos;
      if (been_there_done_that._indexin(key)) {
         continue;
      }

      match_id = i;
      match_ids[m] = i;
      captions[m] = caption:+"\t":+cm.file_name:+"\t":+cm.line_no;
      tag_tree_filter_member2(0,0,cm.type_name,(cm.class_name!='')?1:0,cm.flags,i_access,i_type);
      tag_tree_select_bitmap(i_access,i_type,leaf_flag,pic_member);
      pictures[m] = pic_member;
      been_there_done_that:[key] = true;
      m++;
   }

   for (i=1; i<=n; ++i) {
      tag_browse_info_init(cm);
      tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, i, cm.seekpos);
      tag_get_detail2(VS_TAGDETAIL_match_start_linenum, i, cm.line_no);
      if (cm.seekpos > 0 || (cm.seekpos==0 && cm.line_no==1)) {
         continue;
      }
      tag_get_match_info(i, cm);
      //if (_QLoadTagsSupported(cm.filename)) {
      //   continue;
      //}
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_match, i, true, true, false);
      key = caption:+"\t":+cm.file_name;
      if (been_there_done_that._indexin(key)) {
         continue;
      }
      key = caption:+"\t":+cm.file_name:+"\t":+cm.line_no;
      if (been_there_done_that._indexin(key)) {
         continue;
      }

      match_id = i;
      match_ids[m] = i;
      captions[m] = caption:+"\t":+cm.file_name:+"\t":+cm.line_no;
      tag_tree_filter_member2(0,0,cm.type_name,(cm.class_name!='')?1:0,cm.flags,i_access,i_type);
      tag_tree_select_bitmap(i_access,i_type,leaf_flag,pic_member);
      pictures[m] = pic_member;
      been_there_done_that:[key] = true;
      m++;
   }

   if (match_ids._length() == 0) {
      return BT_RECORD_NOT_FOUND_RC;
   }
   if (match_ids._length() == 1) {
      return 1;  // == match_ids[0]
   }
   if (match_ids._length() > 1) {
      orig_use_timers := _use_timers;
      _use_timers = 0;
      orig_autohide_delay := def_toolbar_autohide_delay;
      def_toolbar_autohide_delay=MAXINT;

      // If we are sorting to prefer definitions or declarations, don't enable
      // sort buttons in the tree
      columnInfo := (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_WRAP)",":+
                    (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_IS_FILENAME)",":+
                    (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_NUMBERS);
      if ( codehelpFlags & (VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION|VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) ) {
         columnInfo= (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP)",":+
                     (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_IS_FILENAME)",":+
                     (TREE_BUTTON_PUSHBUTTON);
      }

      match_id = select_tree(captions, match_ids, pictures, pictures, 
                             null, tag_select_callback, null, 
                             "Select Symbol", 
                             SL_COLWIDTH|SL_SIZABLE|SL_XY_WIDTH_HEIGHT, 
                             "Name,File,Line,", 
                             columnInfo,
                             true, 
                             "Select Symbol dialog", 
                             "find_tag"
                            );
      def_toolbar_autohide_delay=orig_autohide_delay;
      _use_timers = orig_use_timers;
      int tagwin_wid = _tbGetWid("_tbtagwin_form");
      if (tagwin_wid) _tbMaybeAutoHide(tagwin_wid,true);
      if (match_id == '' || match_id == COMMAND_CANCELLED_RC) {
         return COMMAND_CANCELLED_RC;
      }
   }

   return match_id;
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
   cm.exceptions = '';
   cm.template_args = '';
   cm.language = '';

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
         VS_TAG_BROWSE_INFO cx;
         tag_browse_info_init(cx);
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
   int status = tag_insert_match2(cm.tag_database,
                                  cm.member_name, cm.type_name,
                                  cm.file_name,
                                  cm.line_no, cm.seekpos,
                                  cm.scope_line_no, cm.scope_seekpos,
                                  cm.end_line_no, cm.end_seekpos,
                                  cm.class_name, cm.flags,
                                  cm.return_type:+VS_TAGSEPARATOR_args:+cm.arguments);
   return status;
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
                         boolean include_tab=false, 
                         int force_leaf=0, 
                         int tree_flags=TREE_ADD_AS_CHILD,
                         typeless user_info=null)
{
   return tag_tree_insert_tag(tree_wid, tree_index, 
                              (int)include_tab, 
                              force_leaf, tree_flags,
                              cm.member_name, cm.type_name,
                              cm.file_name, cm.line_no,
                              cm.class_name, cm.flags, 
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
 * @see tag_get_match
 *  
 * @categories Tagging_Functions
 *  
 */
int tag_get_match_info(int match_id, VS_TAG_BROWSE_INFO &cm)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(false);

   tag_browse_info_init(cm);
   int status = tag_get_match(match_id, cm.tag_database, cm.member_name,
                              cm.type_name, cm.file_name, cm.line_no,
                              cm.class_name, cm.flags,
                              cm.arguments, cm.return_type);
   tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, match_id, cm.seekpos);
   tag_get_detail2(VS_TAGDETAIL_match_name_linenum, match_id, cm.name_line_no);
   tag_get_detail2(VS_TAGDETAIL_match_name_seekpos, match_id, cm.name_seekpos);
   tag_get_detail2(VS_TAGDETAIL_match_scope_seekpos, match_id, cm.scope_seekpos);
   tag_get_detail2(VS_TAGDETAIL_match_scope_linenum, match_id, cm.scope_line_no);
   tag_get_detail2(VS_TAGDETAIL_match_end_seekpos, match_id, cm.end_seekpos);
   tag_get_detail2(VS_TAGDETAIL_match_end_linenum, match_id, cm.end_line_no);
   tag_get_detail2(VS_TAGDETAIL_match_parents, match_id, cm.class_parents);
   tag_get_detail2(VS_TAGDETAIL_match_throws, match_id, cm.exceptions);
   tag_get_detail2(VS_TAGDETAIL_match_template_args, match_id, cm.template_args);
   cm.language = (_isEditorCtl() && file_eq(cm.file_name,p_buf_name))? p_LangId:"";
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
 * @see tag_get_match
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
 */
int tag_get_local_info(int local_id, VS_TAG_BROWSE_INFO &cm)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   tag_browse_info_init(cm);
   int status = tag_get_local2(local_id, cm.member_name,
                               cm.type_name, cm.file_name, 
                               cm.line_no, cm.seekpos,
                               cm.scope_line_no, cm.scope_seekpos,
                               cm.end_line_no, cm.end_seekpos,
                               cm.class_name, cm.flags,
                               cm.arguments, cm.return_type);
   tag_get_detail2(VS_TAGDETAIL_local_name_linenum, local_id, cm.name_line_no);
   tag_get_detail2(VS_TAGDETAIL_local_name_seekpos, local_id, cm.name_seekpos);
   tag_get_detail2(VS_TAGDETAIL_local_parents, local_id, cm.class_parents);
   tag_get_detail2(VS_TAGDETAIL_local_throws, local_id, cm.exceptions);
   tag_get_detail2(VS_TAGDETAIL_local_template_args, local_id, cm.template_args);
   cm.language = (_isEditorCtl() && file_eq(cm.file_name,p_buf_name))? p_LangId:"";
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
                     boolean(&been_there_done_that):[], 
                     VS_TAG_RETURN_TYPE (&visited):[]=null,
                     int depth=0, int max_depth=1)
{
   if (depth > max_depth) {
      return 0;
   }
   if (been_there_done_that._indexin(class_name)) {
      return 0;
   }
   been_there_done_that:[class_name]=true;

   if (cancel_form_wid()) {
      cancel_form_set_labels(cancel_form_wid(), "Searching: "class_name);
   } else {
      message("Searching: "class_name);
   }

   // what tag file is this class really in?
   _str normalized;
   _str tag_file = find_class_in_tag_file(class_name, class_name, normalized, 1, tag_files);
   if (tag_file == '') {
      tag_file = find_class_in_tag_file(class_name, class_name, normalized, 1, tag_files, true);
   }
   if (tag_file != '') {
      tag_db_name = tag_file;
   }
   int status = tag_read_db(tag_db_name);
   if (status < 0) {
      return 0;
   }

   // need to parse out our outer class name
   _str outername  = '';
   _str membername = '';
   tag_split_class_name(class_name, membername, outername);

   // try to look up file_name and type_name for class
   typeless dm,dc,df,dt;
   _str type_name='';
   _str file_name='';
   int line_no=0;
   int tag_flags=0;
   status=tag_find_tag(membername, "class", outername);
   if (status==0) {
      tag_get_info(dm, type_name, file_name, line_no, dc, tag_flags);
   } else {
      status=tag_find_tag(membername, "struct", outername);
      if (status==0) {
         tag_get_info(dm, type_name, file_name, line_no, dc, tag_flags);
      } else {
         status=tag_find_tag(membername, "interface", outername);
         if (status==0) {
            tag_get_info(dm, type_name, file_name, line_no, dc, tag_flags);
         }
      }
   }
   while (tag_flags & VS_TAGFLAG_forward) {
      status=tag_next_tag(membername,type_name,class_name);
      if (status<0) {
         break;
      }
      tag_get_info(dm, dt, file_name, line_no, dc, tag_flags);
   }
   tag_reset_find_tag();
/*   if (j<0) {
      file_name = child_file_name;
      line_no   = child_line_no;
   }*/

   // OK, we are now ready to insert
   int pic_class, leaf;
   tag_tree_get_bitmap(0,0,type_name,class_name,0,leaf,pic_class);
   if (depth > 0) {
      tag_insert_match(tag_db_name, membername, type_name, file_name, line_no, 
                       outername, tag_flags, '');
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

   if (file_name=='') {
      return(0); //k;
   }

   // stop here if we are at the depth limit
   if (depth >= max_depth) {
      return 0;
   }

   // now insert derived classes
   _str orig_tag_file = tag_current_db();

   // get all the classes that could maybe possibly derive from this class
   _str candidates[];candidates._makeempty();
   _str candidate_class='';
   _str parents='';
   status=tag_find_class(candidate_class);
   while (!status) {
      tag_get_inheritance(candidate_class,parents);
      if (length(parents) > 0 && pos("[;.:/]"membername"(<[^;]*>|);",';'parents';',1,'ir')) {
         candidates[candidates._length()]=candidate_class;
      }
      status=tag_next_class(candidate_class);
   }

   // verify that they derive directly from that class, then insert in tree
   tag_reset_find_class();
   int i;
   if (depth==0 && (max_depth > 1 || candidates._length() > CB_MAX_INHERITANCE_DEPTH)) {
      show_cancel_form("Finding Derived Classes...",null,true,true);
   }
   typeless dummy;
   for (i=0; i<candidates._length(); ++i) {

      if (max_depth > 1 || candidates._length() > CB_MAX_INHERITANCE_DEPTH) {
         if (cancel_form_cancelled()) break;
         if (depth==0) {
            cancel_form_progress(cancel_form_wid(),i+1,candidates._length());
         }
      }

      tag_read_db(orig_tag_file);
      tag_find_class(dummy,candidates[i]);
      if (tag_is_parent_class(class_name,candidates[i],
                              tag_files,true,true,
                              file_name,visited,depth)) {
         tag_find_derived(/*k,*/candidates[i],
                          tag_db_name,tag_files,
                          file_name,line_no,
                          been_there_done_that,
                          visited, depth+1, max_depth);
      }
   }
   if (depth==0) {
      close_cancel_form(cancel_form_wid());
   }

   tag_reset_find_class();
   tag_read_db(orig_tag_file);
   return (0);//k;
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
 */
int tag_get_context_info(int context_id, VS_TAG_BROWSE_INFO &cm)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   tag_browse_info_init(cm);
   int status = tag_get_context(context_id, cm.member_name,
                                cm.type_name, cm.file_name,
                                cm.line_no, cm.seekpos,
                                cm.scope_line_no, cm.scope_seekpos,
                                cm.end_line_no, cm.end_seekpos,
                                cm.class_name, cm.flags,
                                cm.arguments, cm.return_type);
   tag_get_detail2(VS_TAGDETAIL_context_name_linenum, context_id, cm.name_line_no);
   tag_get_detail2(VS_TAGDETAIL_context_name_seekpos, context_id, cm.name_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_parents, context_id, cm.class_parents);
   tag_get_detail2(VS_TAGDETAIL_context_throws, context_id, cm.exceptions);
   tag_get_detail2(VS_TAGDETAIL_context_template_args, context_id, cm.template_args);
   cm.language = (_isEditorCtl() && file_eq(cm.file_name,p_buf_name))? p_LangId:"";
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
 * @see tag_get_match
 *
 * @categories Tagging_Functions
 */
int tag_get_tag_info(VS_TAG_BROWSE_INFO &cm)
{
   tag_browse_info_init(cm);
   tag_get_info(cm.member_name, cm.type_name,
                cm.file_name, cm.line_no,
                cm.class_name, cm.flags);
   tag_get_detail(VS_TAGDETAIL_arguments, cm.arguments);
   tag_get_detail(VS_TAGDETAIL_return, cm.return_type);
   tag_get_detail(VS_TAGDETAIL_class_parents, cm.class_parents);
   tag_get_detail(VS_TAGDETAIL_throws, cm.exceptions);
   tag_get_detail(VS_TAGDETAIL_template_args, cm.template_args);
   tag_get_detail(VS_TAGDETAIL_language_id, cm.language);
   cm.tag_database = tag_current_db();
   return 0;
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
   // make sure that the symbol does not come from a DLL, Jar, or Class file
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      _message_box(nls("Can not go to symbol in a binary file: %s",cm.file_name));
      return COMMAND_CANCELLED_RC;
   }

   // adjust the location of the symbol if necessary
   int status = tag_refine_symbol_match(cm);
   if (status == COMMAND_CANCELLED_RC) {
      return status;
   }

   // first try to open the by matching a current buffer
   int view_id = p_window_id;
   status=edit('+b 'maybe_quote_filename(cm.file_name));
   if ( status ) {
      // now try to open the file normally
      status=edit(maybe_quote_filename(cm.file_name));
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
         _message_box(nls("Could not open %s: %s",cm.file_name,get_message(status)));
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
      if(!isVisualStudioPlugin()) {
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
int tag_list_matches_in_context(VS_TAG_BROWSE_INFO cm)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   _UpdateContext(true,true);
   _UpdateLocals(true);

   int num_matches=0;
   _str no_tag_files[];
   no_tag_files._makeempty();

   tag_clear_matches();
   tag_list_any_symbols(0,0,cm.member_name,no_tag_files,
                        VS_TAGFILTER_ANYTHING,
                        VS_TAGCONTEXT_ANYTHING|VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_ALLOW_private|VS_TAGCONTEXT_ALLOW_protected|VS_TAGCONTEXT_ALLOW_package|VS_TAGCONTEXT_ALLOW_forward,
                        num_matches, def_tag_max_find_context_tags,
                        true, p_EmbeddedCaseSensitive);

   if (tag_get_num_of_matches() == 0) {
      return BT_RECORD_NOT_FOUND_RC;
   }
   return num_matches;
}

int tag_select_symbol_match(VS_TAG_BROWSE_INFO &cm, 
                            boolean addMatches=false,
                            int codehelpFlags=0)
{
   // display dialog to select the appropriate tag match
   int match_id = tag_select_match(codehelpFlags);
   if (match_id == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }
   // check for error
   if (match_id < 0) {
      return match_id;
   }

   // populate a tag info struct with the selected match
   tag_get_match_info(match_id, cm);
   if (cm.file_name == null || cm.file_name == '') {
      // error
      return BT_RECORD_NOT_FOUND_RC;
   }

   // record the matches the user chose from
   int i,n = tag_get_num_of_matches();
   if (addMatches) {
      push_tag_add_match(cm);
      for (i=1; i<=n; ++i) {
         if (i==match_id) continue;
         VS_TAG_BROWSE_INFO im;
         tag_get_match_info(i,im);
         push_tag_add_match(im);
      }
   }

   // that's all folks
   return 0;
}

int tag_refine_symbol_match(VS_TAG_BROWSE_INFO &cm, boolean quietlyChooseFirstMatch=false)
{
   // make sure that the selected symbol does not come
   // from a DLL, Jar, or Class file
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      return 0;
   }

   // go to the file containing the chosen symbol
   boolean buffer_already_exists=false;
   int temp_view_id=0, orig_view_id=0;
   int status = _open_temp_view(cm.file_name, 
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
   status = tag_list_matches_in_context(cm);
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
   int match_id = tag_find_match(cm);
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

   // clean up the temp view and restore the window id
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;
   tag_pop_matches();
   tag_unlock_context();
   return 0;
}

_str tag_tree_compose_tag_info(VS_TAG_BROWSE_INFO cm)
{
   return tag_tree_compose_tag(cm.member_name, cm.class_name, 
                               cm.type_name, cm.flags, cm.arguments, 
                               cm.return_type, cm.template_args);
}

void tag_tree_decompose_tag_info(_str taginfo, VS_TAG_BROWSE_INFO &cm)
{
   tag_browse_info_init(cm);
   tag_tree_decompose_tag(taginfo, 
                          cm.member_name, 
                          cm.class_name, 
                          cm.type_name, 
                          cm.flags,
                          cm.arguments,
                          cm.return_type,
                          cm.template_args);
}

/**
 * Return the documentation for a command.
 * 
 * For best results the documentation should be in javadoc
 * format.
 * 
 * @param tagName
 * 
 * @return _str
 */
_str tag_command_html_documentation (_str tagName)
{
   _str documentation = '';
   if (tagName != '-') {
      tagName = stranslate(tagName, '_', '-');
   }
   //'last_recorded_macro's aren't like other commands. Bail out.
   if (substr(tagName, 1, 19) == 'last_recorded_macro') {
      return "";
   }
   int tagIndex = find_index(tagName, COMMAND_TYPE);

   int tfindex = 0;
   int moduleIndex = 0;
   _str moduleName = '';
   _str extension = '';
   _str fileName = '';

   //Get the file name that the proc is in.
   _e_MaybeBuildTagFile(tfindex,true);
   moduleIndex = index_callable(tagIndex);
   moduleName = name_name(moduleIndex); //The .ex file the _command is in.
   extension = substr(moduleName, lastpos('.', moduleName)+1);
   moduleName = substr(moduleName, 1, length(moduleName)-1);
   fileName = path_search(moduleName, 'VSLICKMACROS');

   //If we couldn't find the file name in the usual way, try another method.
   if ((fileName == '') && !strieq(extension, 'DLL')) {
      _str tagfiles = '';
      int tagsMatching = -1;
      tagfiles = tags_filename('e', false);
      tagsMatching = find_tag_matches(tagfiles, tagName);
      tag_remove_duplicate_symbol_matches(false, false, false, false);
      VS_TAG_BROWSE_INFO cm;
      tag_browse_info_init(cm);
      int i;
      for (i = 0; i <= tag_get_num_of_matches(); ++i) {
         tag_get_match_info(i, cm);
         if (cm.type_name == 'func') {
            fileName = cm.file_name;
            break;
         }
      }
   }

   //Get the line number the proc is on
   int status = 0;
   int tempWID = 0;
   int origWID = 0;
   boolean bufferExists = false;
   status = _open_temp_view(fileName, tempWID, origWID, '', bufferExists, false,
                            true);
   if (status) {
      return "";
   }
   
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int contextID = 0;
   int lineNumber = 0;
   contextID = tag_find_context_iterator(tagName, true, true);
   if (contextID < 0) {
      _delete_temp_view(tempWID);
      activate_window(origWID);
      return '';
   }
   tag_get_detail2(VS_TAGDETAIL_context_line, contextID, lineNumber);
   
   //Use all that information to get comments:
   int commentFlags = 0;
   _str comments = '';
   status = _ExtractTagComments2(commentFlags, comments, 2000, tagName,
                                 fileName, lineNumber);
   _delete_temp_view(tempWID);
   activate_window(origWID);

   if (status) {
      return '';
   }

   _make_html_comments(comments, commentFlags, "", "");

   return comments;
}


defeventtab _tag_progress_form;
boolean cancelTagProgressFormGlobal = false;

void ctlCancel.on_create()
{
   cancelTagProgressFormGlobal = false;
}

void ctlCancel.lbutton_up()
{
   cancelTagProgressFormGlobal = true;
}

boolean getCancelTagProgressFormGlobal() {
   return cancelTagProgressFormGlobal;
}

int tagProgressCallback(int percentage, boolean breakIfEditorVisible = false, typeless userData = "")
{
   // this is only currently used if the mdi window is hidden
   if(breakIfEditorVisible && _mdi.p_visible) {
      return 0;
   }

   int cancelPressed = 0;

   // find the control
   _nocheck _control ctlLogTree;
   _nocheck _control ctlProgress;
   int wid = _find_object("_tag_progress_form", "N");
   if(wid) {
      wid.ctlProgress.p_max = 100;
      wid.ctlProgress.p_value = percentage;
      //wid.ctlProgress.refresh("W");
      wid.refresh("W");

      // handle messages
      int orig_use_timers=_use_timers;
      int orig_def_actapp=def_actapp;
      def_actapp=0;
      _use_timers=0;
      process_events(cancelTagProgressFormGlobal);
      _use_timers=orig_use_timers;
      def_actapp=orig_def_actapp;
      if(cancelTagProgressFormGlobal) {
         cancelPressed = 1;
      }
   }

   return cancelPressed;
}


int adjustTagfilePaths(_str tagfile, _str origPath, _str newPath)
{
   // open the database for business
   int status = tag_open_db(tagfile);
   if (status < 0) {
      return status;
   }

   int tempViewID = 0;
   int origViewID = _create_temp_view(tempViewID);

   // get the files from the database
   int numFiles = 0;
   tag_get_detail(VS_TAGDETAIL_num_files, numFiles);

   _str filename = "";
   _str includename = "";
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
   while(!down()) {
      _str origFilename = "";
      get_line(origFilename);

      // make orig filename relative to remote db and then absolute to local db
      _str newFilename = relative(origFilename, origPath);
      newFilename = absolute(newFilename, newPath);

      // rename the file in the database
      status = tag_rename_file(origFilename, newFilename);
      if(status) break;
   }

   // cleanup the temp view
   p_window_id = origViewID;
   _delete_temp_view(tempViewID);

   return status;
}

/**
 *
 */
_command int check_autoupdated_tagfiles(_str workspaceName = _workspace_filename) name_info(FILE_ARG'*,'VSARG2_EDITORCTL)
{
   int status = 0;

   if(workspaceName == "") {
      return 0;
   }

   int handle = -1;
   if(workspaceName == _workspace_filename) {
      handle = gWorkspaceHandle;
   } else {
      handle = _xmlcfg_open(workspaceName, status);
      if(handle < 0) return status;
   }

   // get list of auto updated tagfiles for this workspace
   int tagfileNodes[] = null;
   _WorkspaceGet_TagFileNodes(handle, tagfileNodes);

   // if this workspace has no auto updated tagfiles then there is nothing to do
   if(tagfileNodes._length() > 0) {
      // check to see if any of the tag files are out dated
      message("Checking auto-updated tag files...");
      mou_hour_glass(1);
      int i;
      int outdatedTagfileNodes[] = null;
      for(i = 0; i < tagfileNodes._length(); i++) {
         int tagfileNode = tagfileNodes[i];

         // get the filename and remote filename
         _str filename = _AbsoluteToWorkspace(_xmlcfg_get_attribute(handle, tagfileNode, "File"), workspaceName);
         _str remoteFilename = _AbsoluteToWorkspace(_xmlcfg_get_attribute(handle, tagfileNode, "AutoUpdateFrom"), workspaceName);

         // check to see if it is out dated
         if (isAutoUpdatedTagfileOutdated(filename, remoteFilename, workspaceName)) {
            outdatedTagfileNodes[outdatedTagfileNodes._length()] = tagfileNode;
         }
      }

      // if there are any outdated files, show the form and update them
      if(outdatedTagfileNodes._length() > 0) {
         message("Updating auto-updated tag files...");

         // show the form
         int wid = show("-xy _tag_progress_form");
         wid.p_caption = "Auto-Update Tag Files";

         _nocheck _control ctlLogTree;
         _nocheck _control ctlProgress;

         // setup columns
         wid.ctlLogTree._TreeSetColButtonInfo(0, 2500, TREE_BUTTON_PUSHBUTTON, 0, "Workspace");
         wid.ctlLogTree._TreeSetColButtonInfo(1, wid.ctlLogTree.p_width - 2500, 0, 0, "Update From");

         // put the list of tag files into the form
         for(i = 0; i < outdatedTagfileNodes._length(); i++) {
            int tagfileNode = outdatedTagfileNodes[i];

            // get the filename and remote filename
            _str filename = _xmlcfg_get_attribute(handle, tagfileNode, "File");
            _str remoteFilename = _AbsoluteToWorkspace(_xmlcfg_get_attribute(handle, tagfileNode, "AutoUpdateFrom"), workspaceName);

            treeIndex := wid.ctlLogTree._TreeAddItem(TREE_ROOT_INDEX, filename "\t" remoteFilename, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
            wid.ctlLogTree._TreeSetCheckable(treeIndex, 1, 0);
            wid.ctlLogTree._TreeSetCheckState(treeIndex, TCB_UNCHECKED);
         }
         wid.refresh("W");
         int node = wid.ctlLogTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);

         // check each workspace
         for(i = 0; i < outdatedTagfileNodes._length(); i++) {
            wid.ctlLogTree._TreeSetCurIndex(node);
            wid.ctlLogTree._TreeRefresh();
            wid.ctlProgress.p_value = 0;

            int tagfileNode = outdatedTagfileNodes[i];

            // get the filename and remote filename
            _str filename = _AbsoluteToWorkspace(_xmlcfg_get_attribute(handle, tagfileNode, "File"), workspaceName);
            _str remoteFilename = _AbsoluteToWorkspace(_xmlcfg_get_attribute(handle, tagfileNode, "AutoUpdateFrom"), workspaceName);

            // call for the update
            status = _updateAutoUpdatedTagfile(filename, remoteFilename, workspaceName);
            if(status) break;

            // show the checkmark and step next
            wid.ctlLogTree._TreeSetCheckState(node, TCB_CHECKED);
            wid.ctlLogTree._TreeRefresh();
            node = wid.ctlLogTree._TreeGetNextSiblingIndex(node);
         }

         // close the form
         wid._delete_window();
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
static boolean isAutoUpdatedTagfileOutdated(_str localFilename, _str remoteFilename, _str workspaceName = _workspace_filename)
{
   int status = 0;

   // make sure both files are absoluted to the workspace
   localFilename = _AbsoluteToWorkspace(localFilename, workspaceName);
   remoteFilename = _AbsoluteToWorkspace(remoteFilename, workspaceName);

   // get the date of the remote file
   _str remoteDate = _file_date(remoteFilename, "B");
   if(remoteDate == "" || remoteDate == 0) {
      // if remote not found then update cannot be performed so return false
      return false;
   }

   // get the date of the local file
   _str localDate = _file_date(localFilename, "B");
   if(localDate <= remoteDate) {
      return true;
   }

   return false;
}

/**
 * Replace the local auto-updated tag file with the one from the remote location
 */
int _updateAutoUpdatedTagfile(_str localFilename, _str remoteFilename, _str workspaceName = _workspace_filename)
{
   int status = 0;

   // make sure both files are absoluted to the workspace
   localFilename = _AbsoluteToWorkspace(localFilename, workspaceName);
   remoteFilename = _AbsoluteToWorkspace(remoteFilename, workspaceName);

   // figure out temp name for copy
   _str tempLocalFilename = localFilename ".tmp";
   if(file_exists(tempLocalFilename)) {
      // delete it to make room
      status = delete_file(tempLocalFilename);
      if(status) {
         _message_box(nls("Failed to auto update tag file '%s1'.  Remove previous temp file failed with error: %s2 (%s3).", localFilename, get_message(status), status));
         return status;
      }
   }

   // get the size of the remote file
   _str line = file_match("-P +V " maybe_quote_filename(remoteFilename), 1);
   int remoteFileSize = 0;
   _str remoteSizeStr = substr(line, DIR_SIZE_COL, DIR_SIZE_WIDTH);
   if(isinteger(remoteSizeStr)) {
      // this should *always* be true
      remoteFileSize = (int)remoteSizeStr;
   }

   // open the remote file
   int remoteHandle = _FileOpen(remoteFilename, 0);
   if(remoteHandle < 0) {
      _message_box(nls("Failed to auto update tag file '%s1'.  Remote file open failed with error: %s2 (%s3).", localFilename, get_message(remoteHandle), remoteHandle));
      return remoteHandle;
   }

   // open the local temp file
   int localHandle = _FileOpen(tempLocalFilename, 1);
   if(localHandle < 0) {
      _message_box(nls("Failed to auto update tag file '%s1'.  Local temp file open failed with error: %s2 (%s3).", localFilename, get_message(localHandle), localHandle));

      // close remote file
      _FileClose(remoteHandle);
      return localHandle;
   }

   // setup buffer
   #define COPYBUFSIZE 64 * 1024 - 1
   int buffer = _BlobAlloc(COPYBUFSIZE); // 64k is largest allowed blob
   if(buffer < 0) {
      _message_box(nls("Failed to auto update tag file '%s1'.  Buffer allocation failed with error: %s2 (%s3).", localFilename, get_message(buffer), buffer));

      // close files
      _FileClose(remoteHandle);
      _FileClose(localHandle);
      return buffer;
   }

   // do the copy
   int totalBytesRead = 0;
   while(totalBytesRead < remoteFileSize) {
      // call the progress callback
      int cancelPressed = tagProgressCallback(totalBytesRead * 100 intdiv remoteFileSize);
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

      // clear the buffer
      _BlobInit(buffer);

      // read the next chunk
      int bytesRead = _BlobReadFromFile(buffer, remoteHandle, COPYBUFSIZE);
      if(bytesRead < 0) {
         // free the buffer
         _BlobFree(buffer);

         // close both files
         _FileClose(remoteHandle);
         _FileClose(localHandle);

         _message_box(nls("Failed to auto update tag file '%s1'.  Read remote file failed with error: %s2 (%s3).", localFilename, get_message(bytesRead), bytesRead));
         return bytesRead;
      }
      totalBytesRead = totalBytesRead + bytesRead;

      // write the next chunk.  this must be done in a loop in case the full
      // amount that was requested was not written
      int totalWritten = 0;
      while(totalWritten < bytesRead) {
         _BlobSetOffset(buffer, totalWritten, 0);
         int bytesWritten = _BlobWriteToFile(buffer, localHandle, bytesRead);
         if(bytesWritten < 0) {
            _message_box(nls("Failed to auto update tag file '%s1'.  Write local temp file failed with error: %s2 (%s3).", localFilename, get_message(bytesWritten), bytesWritten));

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
         _message_box(nls("Failed to auto update tag file '%s1'.  Close local tag file failed with error: %s2 (%s3).", localFilename, get_message(status), status));
         return status;
   }

   // make sure local tagfile is not read only
#if __UNIX__
   chmod("\"u+w g+w o+w\" " maybe_quote_filename(localFilename));
#else
   chmod("-r " maybe_quote_filename(localFilename));
#endif

   // delete the local tagfile
   status = delete_file(localFilename);
   switch(status) {
      case FILE_NOT_FOUND_RC:
      case 0:
         status = 0;
         break;

      default:
         _message_box(nls("Failed to auto update tag file '%s1'.  Delete local tag file failed with error: %s2 (%s3).", localFilename, get_message(status), status));
         return status;
   }

   // rename the temp local file
   status = _file_move(localFilename, tempLocalFilename);
   if(status) {
      _message_box(nls("Failed to auto update tag file '%s1'.  Rename temp tag file failed with error: %s2 (%s3).", localFilename, get_message(status), status));
      return status;
   }

   // adjust the paths
   status = adjustTagfilePaths(localFilename, _strip_filename(localFilename, "N"), _strip_filename(remoteFilename, "N"));
   if(status) {
      _message_box(nls("Failed to auto update tag file '%s1'.  Rename temp tag file failed with error: %s2 (%s3).", localFilename, get_message(status), status));
      return status;
   }

   // make the local file read only
#if __UNIX__
   chmod("\"u+r u-w u-x g+r g-w g-x o+r o-w o-x\" " maybe_quote_filename(localFilename));
#else
   chmod("+r " maybe_quote_filename(localFilename));
#endif

   return status;
}

/** 
 * Find out what tag file and file the given parent class comes from.
 */
int find_location_of_parent_class(_str tag_database, _str class_name, 
                                         _str &file_name, int &line_no, _str &type_name)
{
   // save the original database name
   int status=0;
   _str orig_database = tag_current_db();
   if (tag_database != '' && tag_database != orig_database) {
      status = tag_read_db(tag_database);
      if (status < 0) {
         return status;
      }
   }

   // need to parse out our outer class name
   _str outername  = '';
   _str membername = '';
   tag_split_class_name(class_name, membername, outername);

   // try to look up file_name and type_name for class
   file_name='';
   line_no=0;
   type_name='';
   typeless dm,dc,df,dt;
   int tag_flags=0;
   status=tag_find_tag(membername, "class", outername);
   if (status==0) {
      tag_get_info(dm, type_name, file_name, line_no, dc, tag_flags);
   } else {
      status=tag_find_tag(membername, "struct", outername);
      if (status==0) {
         tag_get_info(dm, type_name, file_name, line_no, dc, tag_flags);
      } else {
         status=tag_find_tag(membername, "interface", outername);
         if (status==0) {
            tag_get_info(dm, type_name, file_name, line_no, dc, tag_flags);
         } else {
            type_name = "class";
            return BT_RECORD_NOT_FOUND_RC;
         }
      }
   }

   // skip forward declarations
   while (!status && (tag_flags & VS_TAGFLAG_forward)) {
      status=tag_next_tag(membername,type_name,class_name);
      if (status<0) {
         break;
      }
      tag_get_info(dm, dt, file_name, line_no, dc, tag_flags);
   }
   tag_reset_find_tag();

   // restore the original database
   if (tag_database != '' && tag_database != orig_database) {
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
 * @param (out)parents_array  parent names will be added to the end of the array passed in.
 */
void tag_info_get_parents_of(VS_TAG_BROWSE_INFO cm, typeless tag_files, _str (&parents_array)[]) 
{
   tag_get_parents_of(cm.member_name, cm.class_parents, cm.tag_database, tag_files, 
                  cm.file_name, cm.line_no, 0, parents_array);
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
 * 
 * @return int
 */
int tag_get_parents_of(_str class_name, _str class_parents,
                          _str tag_db_name, typeless &tag_files,
                          _str child_file_name, int child_line_no, int depth, _str (&parents_array)[])
{
   if (depth >= CB_MAX_INHERITANCE_DEPTH) {
      return 0;
   }

   // what tag file is this class really in?
   _str normalized;
   _str tag_file = find_class_in_tag_file(class_name, class_name, normalized, 1, tag_files);
   if (tag_file == '') {
      tag_file = find_class_in_tag_file(class_name, class_name, normalized, 1, tag_files, true);
   }
   if (tag_file != '') {
      tag_db_name = tag_file;
   }
   int status = tag_read_db(tag_db_name);
   if (status < 0) {
       parents_array[parents_array._length()]=class_name;
      return 0;
   }

   // get are parent classes and the tag files they come from
   int result = 0;
   _str tag_dbs = '';
   _str parents = cb_get_normalized_inheritance(class_name, tag_dbs, tag_files, false, class_parents, child_file_name);

   // make sure the right tag file is still open
   status = tag_read_db(tag_db_name);
   if (status < 0) {
      parents_array[parents_array._length()]=class_name;
      return 0;
   }

   _str file_name='';
   _str type_name='';
   int line_no=0;
   status = find_location_of_parent_class(tag_db_name, class_name, file_name, line_no, type_name);
   if (status < 0) {
      file_name = child_file_name;
      line_no   = child_line_no;
   }

   parents_array[parents_array._length()]=class_name;

   // recursively process parent classes
   _str p1,t1;
   _str orig_tag_file = tag_current_db();
   while (parents != '') {
      parse parents with p1 ';' parents;
      parse tag_dbs with t1 ';' tag_dbs;
      parse p1 with p1 '<' .;
      find_location_of_parent_class(t1,p1,file_name,line_no,type_name);
      result = tag_get_parents_of(p1, '', t1, tag_files, file_name, line_no, depth+1, parents_array);
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
   // tag database is already there, then don't change it
   if (cm.tag_database!=null && cm.tag_database!='') {
      return;
   }

   // found the tag, type, and class name, now find it in a database
   i := 0;
   orig_tagfile := tag_current_db();
   tag_files := tags_filenamea(cm.language);
   tag_filename := next_tag_filea(tag_files,i,false,true);
   while ( tag_filename!='' ) {

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

int _VirtualProcSearch(_str &macro_name, boolean includeFlags = true)
{
   tag_lock_matches(true);
   tag_lock_context(true);
   tag_push_context();
   _UpdateContext(true);
   class_name := "";
   type_name := "";
   tag_flags := 0;
   context_id := 0;
   tag_tree_decompose_tag(macro_name, macro_name, class_name, type_name, tag_flags);
   if (macro_name == "") {
      context_id = (tag_get_num_of_context() > 0)? 1:STRING_NOT_FOUND_RC;
   } else {
      context_id = tag_find_context_iterator(macro_name,true,true,true,class_name);
   }
   if (context_id <= 0) {
      tag_pop_context();
      tag_unlock_context();
      return STRING_NOT_FOUND_RC;
   }
   VS_TAG_BROWSE_INFO cm;
   tag_get_context_info(context_id, cm);
   if (!includeFlags) {
      cm.flags = 0;
   }
   p_RLine = cm.line_no;
   _GoToROffset(cm.seekpos);
   macro_name = tag_tree_compose_tag_info(cm);
   tag_pop_context();
   tag_unlock_context();
   tag_unlock_matches();
   return 0;
}


struct AUTOTAG_BUILD_INFO {
   _str configName;
   _str langId;
   _str tagDatabase;
   _str directoryPath;
   _str wildcardOptions;
};


static void getAllCompilerChoices(available_compilers &compilers,
                                  _str (&cpp_compiler_names)[],
                                  _str (&java_compiler_names)[],
                                  _str (&dotnet_compiler_names)[] /*ignored*/ )
{
   // get the list of C++ compiler configurations from compilers.xml
   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;
   refactor_config_open( filename );
   generate_default_configs();
   refactor_config_open( filename );
   refactor_get_compiler_configurations(cpp_compiler_names, java_compiler_names);
   _evaluate_compilers(compilers,cpp_compiler_names);
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
   _str VisualCppPath='';
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
   if (defaultChoice=='') {
      defaultChoice = compilers.latestMS;
   }
   if (defaultChoice=='') {
      defaultChoice = _GetLatestCompiler();
   }

   // just pick the first one if there is one
   if (defaultChoice=='' && cpp_compiler_names._length() > 0) {
      defaultChoice = cpp_compiler_names[0];
   }

   for (i:=0; i<cpp_compiler_names._length(); ++i) {
      AUTOTAG_BUILD_INFO autotagInfo;
      autotagInfo.configName = cpp_compiler_names[i];
      autotagInfo.langId = 'c';
      autotagInfo.tagDatabase = cpp_compiler_names[i]:+TAG_FILE_EXT;
      autotagInfo.directoryPath = "";
      autotagInfo.wildcardOptions = "";
      choices[choices._length()] = autotagInfo;
   }

   if (choices._length() <= 0) {
      for (i=0; i<cppNamesList._length(); i++) {
         AUTOTAG_BUILD_INFO autotagInfo;
         autotagInfo.configName = cppNamesList[i];
         autotagInfo.langId = 'c';
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
   _str JDKPath='';
   getJavaIncludePath(javaList,JDKPath,javaNamesList);

   langPriority = 20;
   langCaption = JAVA_COMPILER_CAPTION;
   defaultChoice = _GetLatestJDK();
   if (defaultChoice == 'not found') {
      defaultChoice = '';
   }

   for (i:=0; i<java_compiler_names._length(); ++i) {
      AUTOTAG_BUILD_INFO autotagInfo;
      autotagInfo.configName = java_compiler_names[i];
      autotagInfo.langId = 'java';
      autotagInfo.tagDatabase = java_compiler_names[i]:+TAG_FILE_EXT;
      autotagInfo.directoryPath = "";
      autotagInfo.wildcardOptions = "";
      choices[choices._length()] = autotagInfo;
   }

   if (choices._length() <= 0) {
      for (i=0; i<javaNamesList._length(); i++) {
         AUTOTAG_BUILD_INFO autotagInfo;
         autotagInfo.configName = javaNamesList[i];
         autotagInfo.langId = 'java';
         autotagInfo.tagDatabase = "java":+TAG_FILE_EXT;
         autotagInfo.directoryPath = javaList[i];
         autotagInfo.wildcardOptions = "";
         choices[choices._length()] = autotagInfo;
      }
   }
}

int _getAutoTagInfo_unity3d(AUTOTAG_BUILD_INFO &autotagInfo) {
#if __UNIX__
   if (_isMac()) {
      //Applications/Unity/Unity.app/Contents/Frameworks/Managed/UnityEngine.dll
      _str install_path='/Applications/Unity/Unity.app/';
      _str path=install_path:+'Contents/Frameworks/Managed/';
      _str filename=path:+'UnityEngine.dll';
      if (file_exists(filename)) {
         autotagInfo.configName = 'Unity';
         autotagInfo.langId = 'cs';
         autotagInfo.tagDatabase = "unity":+TAG_FILE_EXT;
         autotagInfo.directoryPath = install_path;
         autotagInfo.wildcardOptions = maybe_quote_filename(filename):+
            ' 'maybe_quote_filename(path:+'UnityEditor.dll');
         return 0;
      }
   }
   return 1;
#else
   //HKL\sorware\classes\com.unity3d.kharma\shell\open\command\
   //  "C:\Program Files (x86)\Unity\Editor\Unity.exe" -openurl "%1"
   _str key='SOFTWARE\classes\com.unity3d.kharma\shell\open\command';
   _str value = _ntRegQueryValue(HKEY_LOCAL_MACHINE,key,'',null);
   if (value._varformat()==VF_LSTR) {
      //_message_box('VALUE='value);
      _str unity_exe=parse_file(value,false);
      _str install_path=_strip_filename(unity_exe,'n');
      if (last_char(install_path)==FILESEP) {
         install_path=substr(install_path,1,length(install_path)-1);
         install_path=_strip_filename(install_path,'n');
      }
      _str path=_strip_filename(unity_exe,'n'):+'data\managed\';

      autotagInfo.configName = 'Unity';
      autotagInfo.langId = 'cs';
      autotagInfo.tagDatabase = "unity":+TAG_FILE_EXT;
      autotagInfo.directoryPath = install_path;
      autotagInfo.wildcardOptions = maybe_quote_filename(path:+'UnityEngine.dll'):+
         ' 'maybe_quote_filename(path:+'UnityEditor.dll');
      return 0;
   }
#endif
   return 1;

}

void _cs_getAutoTagChoices(_str &langCaption, int &langPriority,
                           AUTOTAG_BUILD_INFO (&choices)[], _str &defaultChoice)
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

   for (i:=0; i<dotnet_compiler_names._length(); ++i) {
      AUTOTAG_BUILD_INFO autotagInfo;
      autotagInfo.configName = dotnet_compiler_names[i];
      autotagInfo.langId = 'cs';
      autotagInfo.tagDatabase = dotnet_compiler_names[i]:+TAG_FILE_EXT;
      autotagInfo.directoryPath = "";
      autotagInfo.wildcardOptions = "";
      choices[choices._length()] = autotagInfo;
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
         AUTOTAG_BUILD_INFO autotagInfo;
         autotagInfo.configName = p;
         autotagInfo.langId = 'cs';
         autotagInfo.tagDatabase = "dotnet":+TAG_FILE_EXT;
         autotagInfo.directoryPath = dotnetItem.install_dir;
         autotagInfo.wildcardOptions = dotnetItem.maketags_args;
         choices[choices._length()] = autotagInfo;
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
            autotagInfo.langId = 'm';
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
         autotagInfo.langId = 'cob';
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
   int status=0;
   _str perl_binary='';
#if !__UNIX__
   status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                            "SOFTWARE\\ActiveWare\\Perl5",
                            "BIN", perl_binary);
   if (!status) {
      perls[perls._length()] = perl_binary;
   }
#endif

   perl_binary=path_search("perl","","P");
   if (perl_binary != '') {
      perls[perls._length()] = _strip_filename(perl_binary, 'N');
   }

#if !__UNIX__
   perl_binary=_path2cygwin('/bin/perl.exe');
   if (perl_binary != '') {
      perl_binary = _cygwin2dospath(perl_binary);
      if (perl_binary != '') {
         perls[perls._length()] = _strip_filename(perl_binary, 'N');
      }
   }
#endif
   if (def_perl_exe_path != '') {
      perls[perls._length()] = _strip_filename(def_perl_exe_path, 'N');
   }

   foreach (auto p in perls) {
      if (p != '') {
         AUTOTAG_BUILD_INFO autotagInfo;
         if (pos("cygwin", p)) {
            autotagInfo.configName = 'Cygwin Perl';
         } else {
            autotagInfo.configName = p;
         }
         autotagInfo.langId = 'pl';
         autotagInfo.tagDatabase = 'perl':+TAG_FILE_EXT;
         autotagInfo.directoryPath = p;
         autotagInfo.wildcardOptions = "";
         choices[choices._length()] = autotagInfo;
      }
   }
}

/**
 * Load all the auto-tagging choices into the given tree control (which should 
 * be the current window ID when this is called). 
 */
void _loadAutoTagChoices()
{
   // go through all the languages
   _str langId = "";
   _str allLangIds[];
   LanguageSettings.getAllLanguageIds(allLangIds);
   foreach (langId in allLangIds) {
      _loadLangAutoTagChoices(langId);
   }
   _TreeSortUserInfo(TREE_ROOT_INDEX, 'N');
}

int _loadLangAutoTagChoices(_str langId, int langIndex = -1)
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
   call_index(langCaption, langPriority, choices, defaultChoice, callbackIndex);
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
      if (autotagInfo.directoryPath != '' && autotagInfo.directoryPath != autotagInfo.configName) {
         caption :+=  \t :+ autotagInfo.directoryPath;
      }

      compilerIndex := _TreeAddItem(langIndex, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, autotagInfo);
      _TreeSetCheckable(compilerIndex, 1, 0);
      _TreeSetCheckState(compilerIndex, checked);
      choicesFound:[lowcase(autotagInfo.configName)] = true;
   }
   _TreeSortCaption(langIndex, 'D');

   return langIndex;
}

void replace_exttagfiles(_str ext,_str tagfilename)
{
   _str file_name=_strip_filename(tagfilename,'P');
   _str tf1=absolute(_tagfiles_path():+file_name);
   _str tf2=absolute(_global_tagfiles_path():+file_name);
   _str tag_files='';

   fileList := LanguageSettings.getTagFileList(ext);
   while (fileList!='') {
      _str f_env = parse_tag_file_name(fileList);
      curFile := _replace_envvars(f_env);

      // see if the file is already in our list
      if (file_eq(curFile, tagfilename)) {
         // already in the list, so don't mess with it
         return;
      }

      // this file is not the same as our new file, so we will keep it in the list
      if (!file_eq(curFile,tf1) && !file_eq(curFile,tf2)) {
         if (tag_files=='') {
            tag_files=f_env;
         } else {
            strappend(tag_files,PATHSEP:+f_env);
         }
      }
   }

   if (tag_files != '') tag_files :+= PATHSEP;
   tag_files :+= tagfilename;
  
   LanguageSettings.setTagFileList(ext, tag_files);
}

int _do_default_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, boolean backgroundThread = true)
{
   call_list("_LoadBackgroundTaggingSettings");
   tagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   flags := VS_TAG_REBUILD_FROM_SCRATCH;
   if (!backgroundThread) flags |= VS_TAG_REBUILD_SYNCHRONOUS;
   status := tag_build_tag_file_from_wildcards(tagFileName,
                                               flags, 
                                               autotagInfo.directoryPath,
                                               autotagInfo.wildcardOptions);

   if (status == 0) {
      alertId := _GetBuildingTagFileAlertGroupId(tagFileName);
      _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, "Updating: "autotagInfo.tagDatabase, '', 1);
   } else if (status < 0) {
      msg := get_message(status, tagFileName);
      _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_TAGGING_ERROR, msg, "Tagging", 1);
   }

   return status;
}

int _c_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, boolean backgroundThread = true)
{

   // compiler configurations save the directory path for later
   config_name := autotagInfo.configName;
   if (autotagInfo.directoryPath == "") {

      _str config_file = _ConfigPath() :+ COMPILER_CONFIG_FILENAME;
      status := refactor_config_open( config_file );

      if(status==VSRC_VSREFACTOR_CONFIGURATION_NOT_FOUND_1A || refactor_config_count() <= 0 ) {
         generate_default_configs();
         status=0;
      }
      if (status < 0) {
         return status;
      }
      status = refactor_build_compiler_tagfile(config_name, 'cpp', true, backgroundThread);
      refactor_config_close();
      def_refactor_active_config=config_name;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      gtag_filelist_cache_updated=false;
      return status;

   }

   // have to build tag file based on name and directory information
   _str cppPath = autotagInfo.directoryPath;
   _maybe_append_filesep(cppPath);
   autotagInfo.wildcardOptions = create_cpp_autotag_args(cppPath);
   if (autotagInfo.wildcardOptions == '') {
      // check for cygwin
       autotagInfo.wildcardOptions = create_cygwin_autotag_args();
       if (autotagInfo.wildcardOptions == '') {
          return FILE_NOT_FOUND_RC;
       }
   }

   cppTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   cppTagFileName = maybe_quote_filename(cppTagFileName);

   _str make_tag_cmd = backgroundThread ? '-b ' : '';
   make_tag_cmd :+= '-t -c -n "C/C++ Compiler Libraries" -o ':+cppTagFileName:+' ':+autotagInfo.wildcardOptions;
   int status=make_tags(make_tag_cmd);
   if (!status) {
      replace_exttagfiles('c',cppTagFileName);
      _config_modify_flags(CFGMODIFY_DEFDATA);

      list := LanguageSettings.getTagFileList('c');
      if (list != '') {
         list = _replace_envvars(list);
         _str vcpp_TagFileName=_strip_filename(cppTagFileName,'N'):+'visualcpp.vtg';
         list=PATHSEP:+list:+PATHSEP;
         _str b4='',after='';
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

int _java_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, boolean backgroundThread = true)
{
   config_name := autotagInfo.configName;
   javaPath := autotagInfo.directoryPath;
   _maybe_append_filesep(javaPath);

   // compiler configurations save the directory path for later
   if (autotagInfo.directoryPath == "") {
      _str config_file = _ConfigPath() :+ COMPILER_CONFIG_FILENAME;
      status := refactor_config_open( config_file );
      if(status==VSRC_VSREFACTOR_CONFIGURATION_NOT_FOUND_1A || refactor_config_count() <= 0 ) {
         generate_default_configs();
         status=0;
      }
      if (status < 0) {
         return status;
      }
      status = refactor_build_compiler_tagfile(config_name, 'java', true, backgroundThread);
      refactor_config_close();
      def_active_java_config=config_name;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      return status;
   }

   autotagInfo.wildcardOptions = create_java_autotag_args(javaPath/*, true*/);
   _str result; 
   if (autotagInfo.wildcardOptions == '') {
      autotagInfo.wildcardOptions = CheckForUserInstalledJava(javaPath);
      if ( autotagInfo.wildcardOptions=='') {
         return FILE_NOT_FOUND_RC;
      }
   }

   javaTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   javaTagFileName = maybe_quote_filename(javaTagFileName);

   //Check to see if there is a previous copy of VisualCafe.vtg
   _str tree_option='-t ';
#if __UNIX__
   if (!pos('*.java',autotagInfo.wildcardOptions)) {
      // We really need this if we are tagging kaffe because we will be searching
      // everthing under "/usr/share".  This code is also useful when we are just
      // tagging specific jar or zip files.  This code might work well for Windows
      // too.
      tree_option='';
   }
#endif
   _str make_tag_cmd = backgroundThread ? '-b ' : '';
   make_tag_cmd :+= tree_option' -c -n "Java Compiler Libraries" -o ':+javaTagFileName:+' ':+autotagInfo.wildcardOptions;
   int status=make_tags(make_tag_cmd);
   if (!status) {
      replace_exttagfiles('java',javaTagFileName);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   return status;
}

int _cs_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, boolean backgroundThread = true)
{
   config_name := autotagInfo.configName;
   dotnetPath := autotagInfo.directoryPath;
   _maybe_append_filesep(dotnetPath);

   // compiler configurations save the directory path for later
   if (autotagInfo.directoryPath == "") {
      _str config_file = _ConfigPath() :+ COMPILER_CONFIG_FILENAME;
      status := refactor_config_open( config_file );
      if(status==VSRC_VSREFACTOR_CONFIGURATION_NOT_FOUND_1A || refactor_config_count() <= 0 ) {
         generate_default_configs();
         status=0;
      }
      if (status < 0) {
         return status;
      }
      status = refactor_build_compiler_tagfile(config_name, 'dotnet', true, backgroundThread);
      refactor_config_close();
      def_active_java_config=config_name;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      return status;
   }

   dotnetTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   dotnetTagFileName = maybe_quote_filename(dotnetTagFileName);

   _str make_tag_cmd = backgroundThread ? '-b ' : '';
   make_tag_cmd :+= '-t -c -n ".NET Framework" -o ':+dotnetTagFileName:+' ':+autotagInfo.wildcardOptions;
   int status=make_tags(make_tag_cmd);
   if (!status) {
      replace_exttagfiles('cs',dotnetTagFileName);
      replace_exttagfiles('bas',dotnetTagFileName);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   return status;
}

int _cob_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, boolean backgroundThread = true)
{
   config_name := autotagInfo.configName;
   cobolPath := autotagInfo.directoryPath;
   _maybe_append_filesep(cobolPath);
   autotagInfo.wildcardOptions = create_cobol_autotag_args(cobolPath);

   cobolTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   cobolTagFileName = maybe_quote_filename(cobolTagFileName);
   _str make_tag_cmd = backgroundThread ? '-b ' : '';
   make_tag_cmd :+= '-t -c -n "COBOL Compiler Libraries" -o ':+cobolTagFileName:+' ':+autotagInfo.wildcardOptions;
   int status=make_tags(make_tag_cmd);
   if (!status) {
      replace_exttagfiles('cob',cobolTagFileName);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   return status;
}

int _m_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, boolean backgroundThread = true)
{
   config_name := autotagInfo.configName;
   frameworkPath := autotagInfo.directoryPath;
   _maybe_append_filesep(frameworkPath);
   boolean visited:[];
   autotagInfo.wildcardOptions = create_framework_autotag_args(frameworkPath,visited);

   // If we're doing the default /System/Library/Frameworks, then also add
   // the /Library/Frameworks directory
   if (frameworkPath :== '/System/Library/Frameworks/') {
      visited._makeempty();
      strappend(autotagInfo.wildcardOptions, create_framework_autotag_args('/Library/Frameworks/',visited));
   }

   frameworkTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   frameworkTagFileName = maybe_quote_filename(frameworkTagFileName);
   //Check to see if there is a previous version of the tag file
   _str make_tag_cmd = backgroundThread ? '-b ' : '';
   make_tag_cmd :+= '-t -c -n "C/C++/Objective-C Frameworks" -o ':+frameworkTagFileName:+' ':+autotagInfo.wildcardOptions;
   int status=make_tags(make_tag_cmd);
   if (!status) {
      // Link the tag file to both C/C++ and Objective-C
      replace_exttagfiles('c',frameworkTagFileName);
      replace_exttagfiles('m',frameworkTagFileName);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   return status;
}

int _pl_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, boolean backgroundThread = true)
{
   config_name := autotagInfo.configName;
   perlPath := autotagInfo.directoryPath;
   _maybe_append_filesep(perlPath);
   autotagInfo.wildcardOptions = create_perl_autotag_args(perlPath);

   perlTagFileName := _tagfiles_path():+autotagInfo.tagDatabase;
   perlTagFileName = maybe_quote_filename(perlTagFileName);
   _str make_tag_cmd = backgroundThread ? '-b ' : '';
   make_tag_cmd :+= '-t -c -n "Perl Compiler Libraries" -o ':+perlTagFileName:+' ':+autotagInfo.wildcardOptions;
   int status=make_tags(make_tag_cmd);
   if (!status) {
      replace_exttagfiles('pl',perlTagFileName);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   return status;
}

void _buildSelectedAutoTagFiles(AUTOTAG_BUILD_INFO (&choices)[], boolean backgroundThread)
{
   AUTOTAG_BUILD_INFO autotagInfo;
   foreach (autotagInfo in choices) {
      int buildIndex = find_index("_"autotagInfo.langId"_buildAutoTagFile", PROC_TYPE);
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
   if (cobolPath!='') {
      // make sure that cobol support is loaded
      if (!index_callable(find_index('_CobolCopyFilePath',PROC_TYPE))) {
         load(get_env('VSROOT'):+'macros':+FILESEP:+'cobol.e');
      }
      // Sets def_cobol_copy_path and gcobol_copy_path
      _str copy_path = _CobolCopyFilePath(cobolPath);
   }

   _str extra_file=ext_builtins_path('cob','cobol');

   if (cobolPath=='') {
      return(extra_file);
   }

   // we do not pull in these specific copy books, so tag them here
   _str win_cpy_files='';
#if !__UNIX__
   if (file_exists(cobolPath:+"windows.cpy")) {
      win_cpy_files=win_cpy_files:+' "'cobolPath:+'windows.cpy"';
   }
   if (file_exists(cobolPath:+"mq.cpy")) {
      win_cpy_files=win_cpy_files:+' "'cobolPath:+'mq.cpy"';
   }
#endif

   return ( extra_file :+
            ' "'cobolPath:+'*.cob"' :+
            ' "'cobolPath:+'*.cbl"' :+
            ' "'cobolPath:+'*.ocb"' :+
            win_cpy_files );
}

_str create_framework_autotag_args(_str frameworkPath, boolean (&visited):[], int depth=0)
{
   _str ret_value='';
   _str folders[];
   _str names[];
   _str path=file_match('+D +X 'frameworkPath,1);
   while (path:!='') {
      folders[folders._length()]=path;
      path=file_match('+D +X 'frameworkPath,0);
   }

   for (index:=0;index<folders._length();++index) {
      frameworkName := folders[index];
      if (last_char(frameworkName)==FILESEP) {
         frameworkName = substr(frameworkName,1,length(frameworkName)-1);
      }
      frameworkName = _strip_filename(frameworkName,'P');
      names[index] = frameworkName;
      if (visited._indexin(frameworkName)) {
         continue;
      }
      visited:[frameworkName] = false;
      if ('./':!=substr(folders[index],length(folders[index])-1)) {
         strappend(ret_value,folders[index]:+'Headers/*.h ');
      }
   }

   for (index=0;index<folders._length();++index) {
      frameworkName := names[index];
      if (visited._indexin(frameworkName) && visited:[frameworkName]==true) {
         continue;
      }
      visited:[frameworkName] = true;
      if ('./':!=substr(folders[index],length(folders[index])-1)) {
         strappend(ret_value,create_framework_autotag_args(folders[index]:+'Frameworks/',visited, depth+1));
      }
   }

   return ret_value;
}

_str create_cygwin_autotag_args()
{
#if __UNIX__
   return("");
#else
   _str cygwinPath = _cygwin_path();
   if (cygwinPath!="") {
      _str include_path = '';
      if (isdirectory(cygwinPath:+'usr':+FILESEP)) {
         include_path = maybe_quote_filename(cygwinPath:+'usr':+FILESEP:+'*.h');
         include_path = include_path:+' 'maybe_quote_filename(cygwinPath:+'usr':+FILESEP:+'*.c');
      }
      if (isdirectory(cygwinPath:+'lib':+FILESEP)) {
         if (include_path=='') {
            include_path = maybe_quote_filename(cygwinPath:+'lib':+FILESEP:+'*.h');
         } else {
            include_path = include_path:+' 'maybe_quote_filename(cygwinPath:+'lib':+FILESEP:+'*.h');
         }
         include_path = include_path:+' 'maybe_quote_filename(cygwinPath:+'lib':+FILESEP:+'*.c');
      }
      cygwinPath = include_path;
   }
   return(cygwinPath);
#endif
}

_str create_perl_autotag_args(_str perlPath)
{
   extra_file := ext_builtins_path('pl','perl');

   _maybe_append_filesep(perlPath);
   std_libs := get_perl_std_libs(perlPath :+ 'perl.exe');

   return ( extra_file :+ std_libs );
}
static void add_path(_str path)
{
   save_pos(auto p);
   _lbtop();
   typeless status=_lbsearch(path,_fpos_case);
   if (!status) {
      _lbselect_line();
      return;
   }
   restore_pos(p);
   _lbadd_item(path);
}

defeventtab _tagging_excludes_form;

void _tagging_excludes_form_save_settings()
{
   ctlexclude_pathlist.p_user = false;
}

boolean _tagging_excludes_form_is_modified()
{
   return ctlexclude_pathlist.p_user;
}

boolean _tagging_excludes_form_apply()
{
   def_tagging_excludes='';
   int wid=p_window_id;
   p_window_id=ctlexclude_pathlist;
   save_pos(auto p);
   _lbtop();_lbup();
   while (!_lbdown()) {
      _str txt = strip(_lbget_text());
      if (def_tagging_excludes != '') {
         def_tagging_excludes=def_tagging_excludes:+PATHSEP:+txt;
      } else {
         def_tagging_excludes=txt;
      }
   }
   restore_pos(p);
   p_window_id=wid;
   if (isEclipsePlugin()) {
      _eclipse_set_tagging_excludes(def_tagging_excludes);
      if (_message_box("Retag your workspace now?","SlickEdit Core",MB_YESNO|MB_ICONQUESTION) == IDYES) {
         _eclipse_retag();
      }
   }
   return true;
}

void ctlexclude_pathlist.on_create()
{
   _str excludes = def_tagging_excludes;
   for (;;) {
      parse excludes with auto cur PATHSEP excludes;
      if (cur=='') break;
      add_path(cur);
   }

   _tagging_excludes_form_initial_alignment();
}

static void _tagging_excludes_form_initial_alignment()
{
   // make the buttons the same width so they don't look goofy
   ctlexclude_add_path.p_width = ctlexclude_delete.p_width = ctlexclude_up.p_width =
      ctlexclude_down.p_width = ctlexclude_add_component.p_width;
}

void _tagging_excludes_form.on_resize()
{
   padding := ctlexclude_pathlist.p_x;

   widthDiff := p_width - (ctlexclude_add_component.p_x + ctlexclude_add_component.p_width + padding);
   heightDiff := p_height - (ctlexclude_pathlist.p_height + 2 * padding);

   if (widthDiff) {
      ctlexclude_add_component.p_x += widthDiff;
      ctlexclude_add_path.p_x = ctlexclude_delete.p_x = ctlexclude_up.p_x =
         ctlexclude_down.p_x = ctlexclude_add_component.p_x;
      ctlexclude_pathlist.p_width += widthDiff;
   }

   if (heightDiff) {
      ctlexclude_pathlist.p_height += heightDiff;
   }
}

int validateComponent(_str name)
{
#if !__UNIX__
   // '\ / : ? " < > |' are invalid filename characters on windows
   if (pos('[?"<>\|]', name, 1, 'r')) {
      _message_box("Path component name must be a valid filename.");
      return(1);
   } 
   int colIndex = pos(':', name, 1); 
   if (colIndex > 0 && colIndex + 1 < length(name) && pos(':', name, colIndex + 1)) {
      _message_box("Path component name must be a valid filename.");
      return(1);
   }
#endif
   return 0;
}

void ctlexclude_add_path.lbutton_up()
{
   typeless result = _ChooseDirDialog('','','',CDN_PATH_MUST_EXIST);
   if(result=='') {
      return;
   }
   _str path=strip(result,'B','"');
   _maybe_append_filesep(path);
   int wid=p_window_id;
   _control ctlexclude_pathlist;
   p_window_id=ctlexclude_pathlist;
   add_path(path);
   p_window_id=wid;
   ctlexclude_pathlist.p_user=true;
}

void ctlexclude_add_component.lbutton_up()
{
   typeless result=show('-modal _textbox_form',
               'Enter the partial path component',
               0,//Flags,
               '',//Tb width
               '',//help item
               '',//Buttons and captions
               '',//retrieve name
               '-e validateComponent Path Component:');
   if (result != '' && _param1 != null) {
      _str path=strip(_param1,'B','"');
      _maybe_append_filesep(path);
      _maybe_prepend(path,FILESEP);
      path='.*':+path:+'.*';
      int wid=p_window_id;
      _control ctlexclude_pathlist;
      p_window_id=ctlexclude_pathlist;
      add_path(path);
      p_window_id=wid;
      ctlexclude_pathlist.p_user=true;
   }
}

void ctlexclude_delete.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctlexclude_pathlist;
   if (_lbget_seltext() == '') {
      return;
   }
   save_pos(auto p);
   top();up();
   boolean ff;
   for (ff=true;;ff=false) {
      typeless status=_lbfind_selected(ff);
      if (status) break;
      _lbdelete_item();_lbup();
   }
   restore_pos(p);
   _lbselect_line();
   p_window_id=wid;
   ctlexclude_pathlist.p_user=true;
}

void ctlexclude_up.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctlexclude_pathlist;
   _str item=_lbget_seltext();
   if (item == '') {
      return;
   }
   int orig_linenum=p_line;
   _lbdelete_item();
   if (p_line==orig_linenum) {
      _lbup();
   }
   _lbup();
   _lbadd_item(item);
   _lbselect_line();
   p_window_id=wid;
   ctlexclude_pathlist.p_user=true;
}

void ctlexclude_down.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctlexclude_pathlist;
   _str item=_lbget_seltext();
   if (item == '') {
      return;
   }
   _lbdelete_item();
   _lbadd_item(item);
   _lbselect_line();
   p_window_id=wid;
   ctlexclude_pathlist.p_user=true;
}

