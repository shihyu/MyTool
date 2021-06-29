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
#include "mfsearch.sh"
#include "pipe.sh"
#include "plugin.sh"
#import "autosave.e"
#import "complete.e"
#import "context.e"
#import "files.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "mfsearch.e"
#import "search.e"
#import "sellist.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbsearch.e"
#import "tbfind.e"
#import "toast.e"
#import "toolbar.e"
#import "util.e"
#import "wkspace.e"
#import "se/datetime/DateTime.e"
#require "se/search/SearchResults.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twautohide.e"
#import "math.e"
#endregion

using namespace se.datetime;
using se.search.SearchResults;
int def_search_threads=8;

// set to 1 while debugging
#define BGSEARCH_ALLOW_TIMEOUT            (0)

static const MAX_RESULT_BLOCK_SIZE=    (50000);
static const MAX_RESULT_BLOCK_NUM=     (50);
static const SEND_CUR_FILE=            (50);
static const START_SEQUENCE=           "***";

// used by both bgm_ and bgs_ functions
static _str bg_get_send_str(_str string)
{
   return(length(string)"\n"string"\n");
}

/****************************************
functions that monitor and control search
prefix: bgm_ background monitor
****************************************/
static bool    bgm_received_start_sequence;
static int     bgm_hin;
static int     bgm_hout;
static int     bgm_herr;
static int     bgm_proc_handle;
static int     bgm_mfflags;
static int     bgm_NofMatches;
static int     bgm_NofFileMatches;
static int     bgm_NofFiles;
static int     bgm_NofSkippedBinaryFiles;
static int     bgm_contextLevel;
static bool    bgm_search_stopped;
static bool    bgm_ignoring_file;
static _str    bgm_search_string;
static _str    bgm_options;
static typeless bgm_start_time;
static SearchResults bgm_results;

static void bgm_send_line(int pipe, _str text)
{
   _PipeWrite(pipe, text"\n");
}

static void bgm_send_int(int pipe, int num)
{
   bgm_send_line(pipe, num);
}

static void bgm_send_str(int pipe, _str string)
{
   _PipeWrite(pipe,bg_get_send_str(string));
}

static void bgm_send_raw(int pipe, _str text)
{
   _PipeWrite(pipe,length(text)"\n"text);
}

static void _bgm_copy_fileview(int listview_id, int temp_view_id) 
{
   get_window_id(auto orig_view_id);
   activate_window(temp_view_id);
   // validate or assume user knows what they are doing?
   markid := _alloc_selection();
   top(); _select_line(markid);
   bottom();
   // ignore blank lines at bottom
   for (;;) {
      if (_first_non_blank_col(0)) break;
      if (up()) break;
   }
   _select_line(markid);
   activate_window(listview_id);
   _copy_to_cursor(markid);
   _free_selection(markid);
   bottom();
   activate_window(orig_view_id);
}

static void _bgm_copy_filelist(_str filename, int listview_id) 
{
   status := _open_temp_view(filename, auto temp_view_id, auto orig_view_id, '+futf8');
   if (status) {
      return;
   }
   _bgm_copy_fileview(listview_id, temp_view_id);
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);
}

static void _bgm_copy_searchresults(int grep_id, int listview_id) 
{
   if (!_grep_buffer_exists(grep_id)) {
      return;
   }
   orig_view_id :=_create_temp_view(auto temp_view_id);
   p_UTF8 = true;
   _grep_make_filelist(grep_id, temp_view_id);
   _bgm_copy_fileview(listview_id, temp_view_id);
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);
}

static bool bgm_is_zip_file(_str ext) 
{
   return (_file_eq(ext, ".zip") || _file_eq(ext, ".jar")  || _file_eq(ext, ".xlsx") || _file_eq(ext, ".docx") || _file_eq(ext, ".jmod") ||
           _file_eq(ext, ".tar") || _file_eq(ext, ".cpio")  || _file_eq(ext, ".gz") || _file_eq(ext, ".Z") || _file_eq(ext, ".xz") || _file_eq(ext, ".bz2"));
}

static _str bgm_get_binary_files(int exclude_zipfiles)
{
   result := "";
   exts := _LangGetExtensions('binary'); 
   while (exts != '') {
      parse exts with auto ext exts;
      ext = '.':+ext;
      if (exclude_zipfiles && bgm_is_zip_file(ext)) {
         continue;
      }
      _maybe_append(result, ';');
      result = result:+'*':+ext;
   }
   return result;
}

static _str bgm_get_default_excludes(int look_in_zipfiles)
{
   result := "";
   files := _default_option(VSOPTIONZ_DEFAULT_EXCLUDES);
   while (files != '') {
      filename := parse_file_sepchar(files);
      if (filename :== MFFIND_BINARY_FILES) {
         filename = bgm_get_binary_files(look_in_zipfiles);

      } else if (look_in_zipfiles) {
         name := _strip_filename(filename, "PE");
         ext := get_extension(filename, true);
         if ((name == "*") && bgm_is_zip_file(ext)) {
             continue;
         }
      }
      _maybe_append(result, ';');
      result = result:+filename;
   }
   return result;
}

static void bgm_get_includes_excludes(_str& wildcards, _str& file_exclude, int look_in_zipfiles)
{
   if (wildcards != '') {
      result := "";
      files := wildcards;
      while (files != '') {
         filename := parse_file_sepchar(files);
         if (filename :== MFFIND_BINARY_FILES) {
            filename = bgm_get_binary_files(look_in_zipfiles);
         }
         _maybe_append(result, ';');
         result = result:+filename;
      }
      wildcards = result;
   }

   if (file_exclude != '') {
      result := "";
      files := file_exclude;
      while (files != '') {
         filename := parse_file_sepchar(files);
         if (filename :== MFFIND_DEFAULT_EXCLUDES) {
            filename = bgm_get_default_excludes(look_in_zipfiles);

         } else if (filename :== MFFIND_BINARY_FILES) {
            filename = bgm_get_binary_files(look_in_zipfiles);
         }
         _maybe_append(result, ';');
         result = result:+filename;
      }
      file_exclude = result;
   }
}

int bgm_gen_file_list(int &temp_view_id,_str files,_str &wildcards,_str& file_exclude,bool files_delimited_with_semicolon,
                      bool searchProjectFiles,bool searchWorkspaceFiles,bool expandWildcards=false,
                      bool recursive=false,_str (&file_array)[]=null,int look_in_zipfiles=0)
{
   int orig_view_id;
   get_window_id(orig_view_id);
   if (wildcards=='') wildcards=ALLFILES_RE;
   _create_temp_view(temp_view_id);
   split_char := ' ';
   if (files_delimited_with_semicolon) {
      split_char=';';
   }
   tree_option := "";
   _str options;
   files=strip_options(files,options,true);
   if (recursive && !pos('+t',options)) {
      tree_option='+t';
   }
   if (searchWorkspaceFiles && _workspace_filename!='') {
      files=MFFIND_WORKSPACE_FILES:+split_char:+files;
   } else if (searchProjectFiles && _project_name!='') {
      files=MFFIND_PROJECT_FILES:+split_char:+files;
   }

   // Add files to file_array
   _str filename;
   while (files!='') {
      if (files_delimited_with_semicolon) {
         filename=parse_file_sepchar(files);
      } else {
         filename= parse_file(files,false);
      }
      if (filename!='') {
         file_array[file_array._length()]=filename;
      }
   }

   bgm_get_includes_excludes(wildcards, file_exclude, look_in_zipfiles);

   exclude_list := "";
   if (file_exclude != '') {
      _str list = file_exclude;
      while (list != '') {
         filename=parse_file_sepchar(list);
         if (filename != '') {
            strappend(exclude_list, ' -exclude '_maybe_quote_filename(filename));
         }
      }
   }

   addedWorkspaceFiles := (_workspace_filename=='');  // if there is no workspace, say it has been added
                                                           // so that it won't be added if it is in the file list
   addedProjectFiles := (_project_name=='');          // ditto
   addedBuffers := false;
   addedCurrent := false;
   int status;

   bottom();
   int j;
   for (j=0;j<file_array._length();++j) {
      filename=file_array[j];
      filename=strip(filename);
      if (strieq(filename,MFFIND_WORKSPACE_FILES)) {
         if (!addedWorkspaceFiles) {
            addedWorkspaceFiles=true;
            _str ProjectFiles[];
            _str workpace_path;
            int i;
            status=_GetWorkspaceFiles(_workspace_filename,ProjectFiles);
            if (status) {
               _delete_temp_view(temp_view_id);activate_window(orig_view_id);
               _message_box(nls("Unable to open workspace '%s'",_workspace_filename));
               return(1);
            }
            insert_line('-start');
            workpace_path=_strip_filename(_workspace_filename,'N');
            for (i=0;i<ProjectFiles._length();++i) {
               files_wid := p_window_id;
               GetProjectFiles(absolute(ProjectFiles[i],workpace_path)
                               ,files_wid,'',null,'',false,true,true);
               bottom();
            }
            insert_line('-stop');
         }
      } else if (strieq(filename,MFFIND_PROJECT_FILES)) {
         if (!addedProjectFiles) {
            addedProjectFiles=true;
            insert_line('-start');
            files_wid := p_window_id;
            GetProjectFiles(_project_name,files_wid,'',null,'',false,true,true);
            bottom();insert_line('-stop');
         }

      } else if (pos("<Project: ", filename)) {
         if (!addedWorkspaceFiles) {
            project_file := "";
            workpace_path := _strip_filename(_workspace_filename,'N');
            parse filename with "<Project: " project_file ">";
            if (project_file != '') {
               insert_line('-start');
               files_wid := p_window_id;
               GetProjectFiles(absolute(project_file,workpace_path),files_wid,'',null,'',false,true,true);
               bottom();insert_line('-stop');
            }
         }

      } else if (pos("<Filelist: ", filename)) {
         parse filename with "<Filelist: " auto listfile ">";
         if (listfile != '') {
            insert_line('-start');
            files_wid := p_window_id;
            _bgm_copy_filelist(_maybe_quote_filename(listfile), files_wid);
            bottom();insert_line('-stop');
         }

      } else if (pos("<SearchResults: ", filename)) {
         parse filename with "<SearchResults: " auto grep_id ">";
         if (grep_id != '' && isnumber(grep_id)) {
            insert_line('-start');
            files_wid := p_window_id;
            _bgm_copy_searchresults((int)grep_id, files_wid);
            bottom(); insert_line('-stop');
         }

      } else if (strieq(filename,MFFIND_BUFFERS)) {
         if (!addedBuffers) {
            addedBuffers=true;
            _str name=buf_match('',1,'b');
            while (!rc) {
               if (name != '' && !beginsWith(name,'.process') && !_isGrepBuffer(name)) {
                  insert_line(' 'name);
               }
               name=buf_match('',0,'b');
            }
         }
      } else if (strieq(filename,MFFIND_BUFFER)) {
         if (!addedCurrent&&!addedBuffers) {
            addedCurrent=true;
            if (!_no_child_windows()) {
               _str name=_mdi.p_child.p_buf_name;
               if (name != '' && !beginsWith(name,'.process') && !_isGrepBuffer(name)) {
                  insert_line(' 'name);
               }
            }
         }
      } else if (buf_match(filename,1,'x')!='') {
         insert_line(' 'filename);
      } else {
         if (strieq(filename, MFFIND_BUFFER_DIR)) {
            if (!_no_child_windows()) {
               _str name = _mdi.p_child.p_buf_name;
               if (name != '' && !beginsWith(name,'.process') && !_isGrepBuffer(name)) {
                  filename = _strip_filename(name, 'N'); 
               }
            }
            if (strieq(filename, MFFIND_BUFFER_DIR)) {
               continue;
            }
         }
         filename=absolute(filename);
         isDirectory := (!iswildcard(filename) || file_exists(filename)) && (isdirectory(filename) || _last_char(filename)==FILESEP);
         if (isDirectory) {
            _maybe_append_filesep(filename);
            if (expandWildcards) {
               _str list=wildcards;
               file_list := _maybe_quote_filename(filename);
               wildcard_list := "";
               _str wildcard;
               while (list!='') {
                  wildcard=parse_file_sepchar(list);
                  if (wildcard!='') {
                     strappend(wildcard_list,' -wc '_maybe_quote_filename(wildcard));
                  }
               }
               if (wildcard_list!='') {
                  strappend(file_list,wildcard_list);
               }
               insert_list :=  '+w -v +p ':+options:+tree_option' ':+file_list;
               if (look_in_zipfiles) {
                  insert_list='+z 'insert_list;
               }
               if (exclude_list!='') {
                  strappend(insert_list, exclude_list);
               }
               status=insert_file_list(insert_list);
               if (status && status != FILE_NOT_FOUND_RC) {
                  _delete_temp_view(temp_view_id);
                  activate_window(orig_view_id);
                  return(status);
               }
            } else {
               insert_line('+d ':+options:+tree_option' ':+filename);
            }
         } else if (iswildcard(filename) && !file_exists(filename)) {
            if (expandWildcards) {
               insert_list :=  '+w -v +p ':+options:+tree_option' ':+_maybe_quote_filename(filename);
               if (look_in_zipfiles) {
                  insert_list='+z 'insert_list;
               }
               if (exclude_list) {
                  strappend(insert_list, exclude_list);
               }
               status=insert_file_list(insert_list);
               if (status && status != FILE_NOT_FOUND_RC) {
                  _delete_temp_view(temp_view_id);
                  activate_window(orig_view_id);
                  return(status);
               }
            } else {
               insert_line('+f ':+options:+tree_option' ':+filename);
            }
         } else {
            insert_line(' 'filename);
         }
      }
   }
   activate_window(orig_view_id);
   return(0);
}

/**
 * remove all files that were added as part of a project that do not match
 * the wildcards
 */
void bgm_filter_project_files(_str wildcards, _str file_exclude = '')
{
   //_str wildcard_re=bgm_make_re(wildcards);
   //_str path_re = '';
   //_str exclude_re = bgm_make_exclude_re(file_exclude, path_re);
   is_filtering := false;
   _str fname, pname;
   //_str pos_options = 'R':+_fpos_case;

   top(); up();
   while (!down()) {
      get_line(fname);
      fname=strip(fname);
      pname=_strip_filename(fname, 'N');
      if (is_filtering) {
         if (fname:=='-stop') {
            is_filtering=false;
            if (_delete_line()) break;
            up();
         } else if (fname :== '') {
            if (_delete_line()) break;
            up();
         } else if (!_FileRegexMatchPath(wildcards,fname)) {
            if (_delete_line()) break;
            up();
         } else if ((file_exclude != '') && _FileRegexMatchExcludePath(file_exclude,fname)) {
            if (_delete_line()) break;
            up();      
         }
      } else if (fname:=='-start') { // not filtering
         is_filtering=true;
         if (_delete_line()) break;
         up();
      }
   }
}

static bool bgm_send_file_list(_str files,int mfflags,_str wildcards,_str file_exclude,bool files_delimited_with_semicolon,
                                  bool searchProjectFiles,bool searchWorkspaceFiles)
{
   int temp_view_id;
   int orig_view_id;
   get_window_id(orig_view_id);
   if (bgm_gen_file_list(temp_view_id,files,wildcards,file_exclude,files_delimited_with_semicolon,searchProjectFiles,searchWorkspaceFiles,false,false,null,mfflags & MFFIND_LOOKINZIPFILES)) {
      return true;
   }

   activate_window(temp_view_id);

   bgm_send_raw(bgm_hout,wildcards);
   mfdebug_say('wildcards:'wildcards);
   bgm_send_raw(bgm_hout,file_exclude);
   mfdebug_say('excludes:'file_exclude);
   bgm_filter_project_files(wildcards, file_exclude);
   num_files := p_Noflines;
   bgm_send_int(bgm_hout,num_files);
   mfdebug_say('Noffiles:'num_files);

   top();up();
   while (!down()) {
      get_line(auto fname);
      mfdebug_say('fname:'fname);
      bgm_send_str(bgm_hout,fname);
   }
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   return false;
}
int def_background_mfsearch_ksize=1024*20;  // 20 megabytes
static void bgm_send_buffer_list()
{
   _str buffers[];
   buffers._makeempty();

#if 1
   get_window_id(auto orig_wid);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();

   // for each buffer
   first_buf_id := p_buf_id;
   for (;;) {
      if (!(p_buf_flags & VSBUFFLAG_HIDDEN) && (p_modify || p_buf_size<def_background_mfsearch_ksize*1024)) {
         name:=p_buf_name;
         if ((name != '') && !beginsWith(name,'.process') && !_isGrepBuffer(name)) {
            buffers[buffers._length()]=name;
            if (p_buf_name!=p_buf_name_no_symlinks) {
               buffers[buffers._length()]=p_buf_name_no_symlinks;
            }
         }
      }

      _next_buffer('HN');
      if ( p_buf_id==first_buf_id ) {
         break;
      }
   }

   // restore original window id
   activate_window(orig_wid);
#else
   _str name=buf_match('',1);
   while (!rc) {
      if ((name != '') && (name != '.process') && !_isGrepBuffer(name)) {
         buffers[buffers._length()]=name;
      }
      name=buf_match('',0);
   }
#endif
   bgm_send_int(bgm_hout,buffers._length());

   typeless index;
   for (index._makeempty();;) {
      buffers._nextel(index);
      if (index._isempty()) break;
      bgm_send_str(bgm_hout,buffers[index]);
   }
}

static _str bgm_read_buffer;

static int bgm_test(int pipe)
{
   if (length(bgm_read_buffer)>0) {
      return(1);
   }
   _str test;
   status:=_PipeRead(pipe,test,1,1);
   if (status<0) {
      return status;
   }
   return(length(test));
}

static void bgm_read_line(int pipe,_str &buffer)
{
   if (length(bgm_read_buffer)) {
      i := pos("\n",bgm_read_buffer);
      if (i) {
         buffer=substr(bgm_read_buffer,1,i-1);
         bgm_read_buffer=substr(bgm_read_buffer,i+1);
         return;
      }
   }
   max_tries := 100;
   _str test;
   _str new_buffer;
   while(max_tries>0) {
      _PipeRead(pipe,test,1,1);
      if (!length(test)) {
#if BGSEARCH_ALLOW_TIMEOUT
         --max_tries;
#endif
         delay(1);
         continue;
      }
      _PipeRead(pipe,new_buffer,MAX_RESULT_BLOCK_SIZE,0);
      strappend(bgm_read_buffer,new_buffer);
      i := pos("\n",bgm_read_buffer);
      if (i) {
         buffer=substr(bgm_read_buffer,1,i-1);
         bgm_read_buffer=substr(bgm_read_buffer,i+1);
         return;
      }
   }
#if BGSEARCH_ALLOW_TIMEOUT
   if (max_tries==0) {
      _message_box('bgm_recv_line timed out');
   }
#endif
   buffer='';
}

static void bgm_read_size(int pipe,_str &buffer,int size)
{
   if (size<0) {
      buffer='';
      return;
   }
   if (length(bgm_read_buffer)>=size) {
      buffer=substr(bgm_read_buffer,1,size);
      bgm_read_buffer=substr(bgm_read_buffer,size+1);
      return;
   }
   max_tries := 100;
   _str test;
   _str new_buffer;
   while(max_tries>0) {
      _PipeRead(pipe,test,1,1);
      if (!length(test)) {
#if BGSEARCH_ALLOW_TIMEOUT
         --max_tries;
#endif
         delay(1);
         continue;
      }
      _PipeRead(pipe,new_buffer,MAX_RESULT_BLOCK_SIZE,0);
      strappend(bgm_read_buffer,new_buffer);
      if (length(bgm_read_buffer)>=size) {
         buffer=substr(bgm_read_buffer,1,size);
         bgm_read_buffer=substr(bgm_read_buffer,size+1);
         return;
      }
   }
#if BGSEARCH_ALLOW_TIMEOUT
   if (max_tries==0) {
      _message_box('bgm_recv_line timed out');
   }
#endif
   buffer='';
}

static _str bgm_recv_line(int pipe)
{
   _str buffer;
   bgm_read_line(pipe,buffer);
   return(buffer);
}

static _str bgm_recv_raw(int pipe)
{
   int size=bgm_recv_int(pipe);

   _str buffer;
   bgm_read_size(pipe,buffer,size);
   return(buffer);
}

static int bgm_recv_int(int pipe)
{
   _str temp = bgm_recv_line(pipe);
   if (isinteger(temp)) {
      return(int)temp;
   }

   return 0;
}

static _str bgm_recv_str(int pipe)
{
   int size=bgm_recv_int(pipe);
   text := "";
   if (size>0) {
      text=bgm_recv_line(pipe);
   }

   return text;
}
// takes the wildcards string and generates a SlickEdit regular expression
_str bgm_make_re(_str wildcards)
{
   re := "";
   _str filter;
   _str ch;
   wildcards=strip(wildcards);

   while (wildcards != '') {
      parse wildcards with filter '[;:]','r' wildcards;
      if (filter != '') {
         filter = strip(filter, 'B');
         if (_last_char(re) == ')') {
            strappend(re, '|(');
         } else {
            strappend(re, '(');
         }
         if (filter == '*.*') {
            filter = '*';
         }
         if (_first_char(filter) != '*') {
            strappend(re, _escape_re_chars(FILESEP, 'r'));
         }
         while (filter != '') {
            ch = substr(filter, 1, 1);
            filter = substr(filter, 2);
            if (ch == '*') {
               strappend(re, '?*');
            } else {
               strappend(re, ch);
            }
         }
         strappend(re, '$)');
      }
   }
   return re;
}

_str bgm_make_exclude_re(_str wildcards, _str &path_re)
{
   re := "";
   _str filter;
   _str ch;
   wildcards = strip(wildcards);
   path_re = '';

   while (wildcards != '') {
      parse wildcards with filter '[;:]','r' wildcards;
      if (filter != '') {
         filter = strip(filter, 'B');
         _str* dest_re = &re;
         if (_last_char(filter) == FILESEP) {
            dest_re = &path_re;
         }
         if (_last_char(*dest_re) == ')') {
            strappend(*dest_re, '|(');
         } else {
            strappend(*dest_re, '(');
         }
         if (filter == '*.*') {
            filter = '*';
         }
         if (_first_char(filter) != '*') {
            strappend(*dest_re, _escape_re_chars(FILESEP, 'r'));
         }
         while (filter != '') {
            ch = substr(filter, 1, 1);
            filter = substr(filter, 2);
            if (ch=='*') {
               strappend(*dest_re, '?*');
            } else {
               ch = _escape_re_chars(ch, 'r');
               strappend(*dest_re, ch);
            }
         }
         if (dest_re == &path_re) {
            strappend(*dest_re, ')');
         } else {
            strappend(*dest_re, '$)');
         }
      }
   }
   return re;
}

int _OnUpdate_stop_search(CMDUI &cmdui,int target_wid,_str command)
{
   if (gbgm_search_state & BG_SEARCH_UPDATE) {
      return MF_GRAYED;
   } else if (gbgm_search_state & BG_SEARCH_ACTIVE) {
      return MF_ENABLED;
   }
   return(MF_GRAYED);
}
_command void stop_search(_str quiet='')
{
   if (gbgm_search_state & BG_SEARCH_UPDATE) {
      gbgm_search_state |= BG_SEARCH_TERMINATING;
   } else if (gbgm_search_state & BG_SEARCH_ACTIVE) {
      bgm_search_stopped=true;

      bgm_terminate_search((quiet!=''));
   } else if (quiet=='') {
      message('There is no background search running.');
   }
}

static void bgm_terminate_search(bool quiet=false)
{
   gbgm_search_state=0;
   _tbFindUpdateBGSearchStatus();
   _PipeTerminateProcess(bgm_proc_handle);
   _PipeCloseProcess(bgm_proc_handle);
   _PipeEndProcess(bgm_proc_handle);
   _autosave_set_timer_alternate();
   if (quiet) return;

   text := "";
   if (bgm_NofFiles>0) {
      // .NET does not do this, it uses the full result string even with "Display file names only"
      // .NET also does not have a separate message for no matches found if it search files
      //    i.e.  it can display  "Total found: 0 Matching files: 0 Total files searched: 22"
      if (bgm_mfflags & MFFIND_FILESONLY) {
         if (bgm_mfflags&MFFIND_FIND_FILES) {
            text='Total files found: 'bgm_NofFiles;
         } else {
            text='Matching files: 'bgm_NofFileMatches'     Total files searched: 'bgm_NofFiles;
         }
      } else {
         text='Total found: 'bgm_NofMatches'     Matching files: 'bgm_NofFileMatches'     Total files searched: 'bgm_NofFiles;
      }

#if 0
      typeless end_time = _time('b');
      typeless elapsed_time = (end_time - bgm_start_time)/1000;
      text :+= "  ("elapsed_time" seconds)";
#endif

   } else {
      text='No files were found to look in.';
   }
   if (bgm_search_stopped) {
      bgm_results.insertMessage('Search terminated');
   }
   bgm_results.done(text);
   refresh();

   message(text);
   _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_BACKGROUND_SEARCH, 'Find in Files completed', '', 1);
}

static bool bgm_process_file(bool doDeleteBuffer=false)
{
   added_results := false;
   search_options :=  '@H'bgm_options;
   if (p_buf_size<def_use_old_line_numbers_ksize*1024) {
      _SetAllOldLineNumbers();
   }
   save_search(auto p1, auto p2, auto p3, auto p4, auto p5);
   top();
   status := search(bgm_search_string, search_options);
   if (!status) {
      added_results = true;
      ++bgm_NofFileMatches;
      if (bgm_mfflags & MFFIND_FILESONLY) {
         cur_file := _build_buf_name();
         bgm_results.insertFileLine(cur_file, false);

      } else {
         while (!status) {
            ++bgm_NofMatches;
            bgm_results.insertCurrentMatch();
            if (!def_search_result_list_nested_re_matches) {
               match_len := match_length('');
               if (match_len > 0) {
                  goto_point(match_length('s') + match_len - 1);
               }
            }
            status = repeat_search();
         }
         bgm_results.endCurrentFile();
         bgm_mfflags = bgm_results.getMFFlags();
      }
   }
   restore_search(p1,p2,p3,p4,p5);
   if (doDeleteBuffer) {
      _delete_buffer();
   }
   _delete_temp_view(p_window_id,false);
   return added_results;
}

void bgm_update_search(bool AlwaysUpdate=false)
{
   if (gbgm_search_state != BG_SEARCH_ACTIVE) {
      return;
   }

   _str orig_strlen_warn=_default_option(VSOPTION_WARNING_STRING_LENGTH);
   if (orig_strlen_warn < MAX_RESULT_BLOCK_SIZE*2) {
      _default_option(VSOPTION_WARNING_STRING_LENGTH,MAX_RESULT_BLOCK_SIZE*2);
   }

   gbgm_search_state |= BG_SEARCH_UPDATE;

   continue_search := true;
   added_results := false;
   cancel := false;
   next_idle_time := _idle_time_elapsed();
   last_idle_time := next_idle_time-1;
   _str cmd;

   while (last_idle_time<=next_idle_time && continue_search) {
      status2:=bgm_test(bgm_herr);
      if (status2>0) {
      } else if (status2<=0) {
         if (_PipeIsProcessExited(bgm_proc_handle)) {
            stop_search();
         }
         break;
      }
      last_idle_time=next_idle_time;
      if (!bgm_received_start_sequence) {
         _str line=bgm_recv_line(bgm_herr);
         if (line==START_SEQUENCE) {
            bgm_received_start_sequence=true;
         }
      } else {
         cmd = bgm_recv_str(bgm_herr);
         switch (cmd) {
         case 'result':
            added_results=true;
            if (bgm_mfflags & MFFIND_FILESONLY) {
               // read the result, but do nothing with it
               bgm_recv_raw(bgm_herr);
            } else {
               _str all_results=bgm_recv_raw(bgm_herr);
               if (!bgm_ignoring_file) {
                  while (all_results!='') {
                     typeless pcol;
                     typeless FoundLen;
                     typeless LineLen;
                     typeless truncate;
                     typeless linenum;
                     typeless col;
                     typeless line_type;
                     _str line;
                     parse all_results with linenum col pcol FoundLen LineLen line_type truncate ':' all_results;
                     line=substr(all_results,1,LineLen);
                     all_results=substr(all_results,LineLen+1);
                     if (line_type == se.search.SEARCH_RESULT_PREFIX) {
                        bgm_results.setMatchLinenum(linenum, col);
                     } else {
                        bgm_results.insertLine(linenum, pcol, FoundLen, line, line_type, (int)truncate, false);
                     }
                     if (line_type == se.search.SEARCH_RESULT_LINE_MATCH) {
                        ++bgm_NofMatches;
                     }
                  }
               }
            }
            break;
         case 'file_status':
            {
               bgm_NofFiles = bgm_recv_int(bgm_herr);
               cur_file := strip(bgm_recv_raw(bgm_herr));
               sticky_message(cur_file);
            }
            break;
         case 'cur_file':
            {
               bgm_NofFiles = bgm_recv_int(bgm_herr);
               cur_file := strip(bgm_recv_raw(bgm_herr));
               sticky_message(cur_file);
               bgm_results.insertFileLine(cur_file, false);
               ++bgm_NofFileMatches;
            }
            break;
         case 'cur_context':
            {
               context_id := bgm_recv_int(bgm_herr);
               context_type := bgm_recv_int(bgm_herr);
               context_linenum := bgm_recv_int(bgm_herr);
               context_level := bgm_recv_int(bgm_herr);
               context_name := strip(bgm_recv_raw(bgm_herr));
               if (context_id < 0) {
                  bgm_results.setContext(-1, 0);
               } else {
                  bgm_results.insertContextLine(0, context_name, context_type, context_linenum, context_level);
                  new_level := NEXTLEVEL_LF + NEXTLEVEL_LF + (NEXTLEVEL_LF * (context_level+1));
                  bgm_results.setContext(context_id, new_level);
               }
            }
            break;
         case 'filelist':
            {
               bgm_NofFiles=bgm_recv_int(bgm_herr);
               cur_file := strip(bgm_recv_raw(bgm_herr));
               bgm_results.insertMessage('File 'strip(cur_file));
            }
            break;
         case 'buf_full':
            // with the main editor searching open files, it could have already done this
            if (!(bgm_mfflags & MFFIND_FILESONLY)) {
               if (def_max_mffind_output_ksize>=(2*1024)) {
                  bgm_results.insertMessage('Output larger than '(def_max_mffind_output_ksize intdiv 1024):+'MB. Switching to files only mode.');
               } else {
                   bgm_results.insertMessage('Output larger than '(def_max_mffind_output_ksize):+'KB. Switching to files only mode.');
               }
               bgm_mfflags|=MFFIND_FILESONLY;
               bgm_results.setMFFlags(MFFIND_FILESONLY, 0);
            }
            break;
         case 'query':
            {
               cur_file := strip(bgm_recv_raw(bgm_herr));
               status := _open_temp_view(cur_file, auto temp_view_id, auto orig_view_id,'', auto buffer_already_exists, false, true);

               skipBinaryFile:=false;
               if (bgm_mfflags & MFFIND_INTERNAL_EXCLUDE_BINARY_FILES) {
                  //skipBinaryFile=_mffind_is_binary_file();
                  skipBinaryFile=(p_LangId=='binary');
                  if (skipBinaryFile) {
                     ++bgm_NofSkippedBinaryFiles;
                  }
               }
               if (!skipBinaryFile) {
                  if (status) {
                     bgm_results.insertMessage('Failed to open: 'cur_file);
                     added_results=true;
                  } else {
                     if (bgm_process_file(!buffer_already_exists)) {
                        added_results=true;
                     }
                  }
               }
            }
            break;
         case 'error':
            if (!bgm_ignoring_file) {
               cur_file := strip(bgm_recv_raw(bgm_herr));
               bgm_results.insertMessage('Failed to open: 'cur_file);
               added_results=true;
            }
            break;
         case 'focus':
            if (_isWindows()) {
               // spawning the second editor causes the focus to shift to it
               // need to get focus back to the main editor
               if ( !_AppHasFocus() ) {
                  //_mdi._set_foreground_window();
                  wid := _tbGetActiveFindAndReplaceForm();
                  if ( wid > 0 && !tw_is_auto_lowered(wid) ) {
                     activate_tool_window('_tbfind_form', true, '_findstring');
                  } else {
                     //toolShowSearch(bgm_grep_id);
                     _mdi._set_foreground_window();
                  }
               }
            }
            break;
         case 'done':
            bgm_NofFiles=bgm_recv_int(bgm_herr);
            bgm_NofFiles-=bgm_NofSkippedBinaryFiles;
            continue_search=false;
            break;
         default:
            continue_search=false;
            _message_box('unrecognized command "'cmd'"('length(cmd)')');
            break;
         }
      }
      process_events(cancel);
      if (gbgm_search_state & BG_SEARCH_TERMINATING) {
         continue_search=false;
      }

      next_idle_time=_idle_time_elapsed();
   }
   if (added_results) {
      // force the search results window to redraw
      refresh();
   }

   gbgm_search_state &= ~BG_SEARCH_UPDATE;

   if (gbgm_search_state & BG_SEARCH_TERMINATING) {
      stop_search();
   } else if (!continue_search) {
      bgm_terminate_search();
   }
   _default_option(VSOPTION_WARNING_STRING_LENGTH,orig_strlen_warn);
}

static _str find_files_summary_line(_str files, _str wildcards, _str file_exclude, _str file_stats)
{
   _str subdir_opts;
   _str disp_files = strip_options(files,subdir_opts,true);
   summary := "Find files ";
   if (disp_files :!= '') {
      strappend(summary,'"'disp_files'", ');
      if (wildcards == '') {
         strappend(summary, '"*"');
      } else {
         strappend(summary, '"'wildcards'"');
      }
      if (file_exclude != '') {
         strappend(summary,', Exclude: "'file_exclude'"');
      }
      if (file_stats != '') {
         se.search.generate_mffile_file_stats_summary(summary, file_stats);
      }
   }
   return summary;
}
bool def_mfdebug=false;
static void mfdebug_say(_str msg) {
   if (def_mfdebug) {
      dsay(msg);
   }
}
void start_bgsearch(_str search_string,_str options,_str files,int mfflags,bool searchProjectFiles,bool searchWorkspaceFiles,_str wildcards,_str file_exclude,bool files_delimited_with_semicolon,int grep_id,int before_lines=0,int after_lines=0,_str file_stats='')
{
   if (gbgm_search_state) {
      message('There is a background search running.');
      return;
   }
   if (_mffind_excludes_binary_files(file_exclude)) {
      mfflags|= MFFIND_INTERNAL_EXCLUDE_BINARY_FILES;
   }
   bgm_read_buffer='';
   bgm_search_string=search_string;
   bgm_options=options;

   topline := "";
   if (mfflags & MFFIND_FIND_FILES) {
      topline = find_files_summary_line(files, wildcards, file_exclude, file_stats);

      // zero out flags that don't apply
      mfflags &= ~(MFFIND_FILESONLY|MFFIND_MATCHONLY|MFFIND_LIST_CURRENT_CONTEXT);

   } else {
      topline = se.search.generate_search_summary(search_string,options,files,mfflags,wildcards,file_exclude,'','', file_stats);
   }
   set_find_next_msg(topline);

   bgm_mfflags=mfflags;
   bgm_NofMatches=0;
   bgm_NofFileMatches=0;
   bgm_NofFiles=0;
   bgm_NofSkippedBinaryFiles=0;
   bgm_contextLevel=-1;
   bgm_search_stopped=false;
   bgm_ignoring_file=false;

   // 1-AD56U (DJB):
   // always invoke background editor using 
   // -sul to disable locking on Unix
   _str lock_option;
   if (!(_default_option(VSOPTION_ALLOW_FILE_LOCKING))) {
      lock_option = " -sul";
   } else {
      lock_option = "";
   }
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   VSWID_HIDDEN.search('',options);
   save_search(auto junk1,auto junk2, auto junk3, auto junk4, auto color_flags);
   restore_search(s1, s2, s3, s4, s5);
   symlink_option := "";
   if (_default_option(VSOPTION_WIN_RESOLVE_SYMLINKS)==1) {
      symlink_option=" +ssymlink ";
   } else if (_default_option(VSOPTION_WIN_RESOLVE_SYMLINKS)==2) {
      symlink_option=" +ssymlinkdirs ";
   }
   list_context := mfflags & MFFIND_LIST_CURRENT_CONTEXT;
   if ((color_flags && false) || list_context) {
      // -slocalsta   -- Use global state file and don't write a local state file
      // -sloadplugins -- disable loading of plugins, user macros, and user forms at startup
      // -sautobuildtagfiles -- disable automatically creating tag files (typing, non-explicit etc.)
      bgm_proc_handle=_PipeProcess(_maybe_quote_filename(editor_name("E")):+' +newi ':+lock_option:+symlink_option' -sc '_maybe_quote_filename(get_env('SLICKEDITCONFIG'))' -q -st 0 -mdihide -slocalsta -sloadplugins -sautobuildtagfiles -nogui -r bgsearch',bgm_hin,bgm_hout,bgm_herr,'');
   } else {
      if (_config_modify_flags()) {
         save_config(1);
      }
      _str exe_path=editor_name('P'):+"sgrep":+EXTENSION_EXE;
      if (!file_exists(exe_path)) {
         exe_path=editor_name('P'):+"cmgrep":+EXTENSION_EXE;
      }
      bgm_proc_handle=_PipeProcess(_maybe_quote_filename(exe_path):+symlink_option' --threads 'def_search_threads' --bgsearch',bgm_hin,bgm_hout,bgm_herr,'');
   }

   if (bgm_proc_handle<0) {
      message('There was an error starting the search process');
      return;
   }

   gbgm_search_state=BG_SEARCH_ACTIVE;
   bgm_received_start_sequence=false;
   bgm_start_time = _time('b');
   _autosave_set_timer_alternate();

   mfdebug_say('--------------------------------------------------');
   bgm_send_raw(bgm_hout,_spill_file_path());
   mfdebug_say('spill_file_path:'_spill_file_path());
   bgm_send_raw(bgm_hout,_getSlickEditInstallPath());
   mfdebug_say('install_path:'_getSlickEditInstallPath());
   bgm_send_raw(bgm_hout,_plugin_get_user_plugins_path());
   mfdebug_say('user_plugins_path:'_plugin_get_user_plugins_path());
   bgm_send_raw(bgm_hout,_ConfigPath());
   mfdebug_say('config_path:'_ConfigPath());
   bgm_send_int(bgm_hout,0);
   mfdebug_say('def_max_mffind_output_ksize:'def_max_mffind_output_ksize);
   bgm_send_int(bgm_hout,def_max_mffind_output_ksize*1024);
   mfdebug_say('search_string:'search_string);
   bgm_send_raw(bgm_hout,search_string);
   mfdebug_say('bgm_mfflags:'dec2hex(bgm_mfflags));
   bgm_send_int(bgm_hout,bgm_mfflags);
   mfdebug_say('def_search_result_multiline_matches:'def_search_result_multiline_matches);
   bgm_send_int(bgm_hout,def_search_result_multiline_matches);
   mfdebug_say('before_lines:'before_lines);
   bgm_send_int(bgm_hout,before_lines);
   mfdebug_say('after_lines:'after_lines);
   bgm_send_int(bgm_hout,after_lines);
   mfdebug_say('search_options:'options);
   bgm_send_raw(bgm_hout,options);
   mfdebug_say('def_find_file_attr_options:'def_find_file_attr_options);
   bgm_send_raw(bgm_hout,def_find_file_attr_options);
   mfdebug_say('def_search_result_sorted_filenames:'def_search_result_sorted_filenames);
   bgm_send_int(bgm_hout,def_search_result_sorted_filenames);
   mfdebug_say('file_stats:'file_stats);
   bgm_send_raw(bgm_hout,file_stats);
   bgm_send_buffer_list();

   if (bgm_send_file_list(files,mfflags,wildcards,file_exclude,files_delimited_with_semicolon,searchProjectFiles,searchWorkspaceFiles)) {
      stop_search('quiet');
      message('There was an error starting the search process');
      return;
   }

   bgm_results.initialize(topline, search_string, mfflags, grep_id, before_lines, after_lines);
   bgm_results.showResults();
   toolSearchScroll();
   _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_BACKGROUND_SEARCH, 'Find in Files started', '', 0);
}

/************************************
functions that perform actual search
prefix: bgs_ background search
************************************/
struct bgs_state {
   bool     searched_files:[];
   int      num_searched_files;
   _str     search_string;
   _str     options;
   _str     attr_flags;
   int      mfflags;
   int      multiline;
   int      before_lines;
   int      after_lines;
   bool     filesonly;
   _str     wildcards;
   _str     file_exclude;
   bool     buffers:[];
   int      disp_buf_size;       // estimate of the size of the display buffer in the main editor
   int      disp_buf_max;        // the maximum to put in the buffer
   int      send_cur_file_count;
   _str     recv_line_remainder;
   int      sort_filenames;
   int      sortfile_view_id;

   // file stats
   MFFIND_FILE_STATS file_stats;

};

static void bgs_send_line(_str text)
{
   _file_write(2,text"\n");
}

static void bgs_send(_str buffer)
{
   _file_write(2,buffer);
}

static _str bgs_get_send_int(int num)
{
   return(num"\n");
}

static void bgs_send_int(int num)
{
   _file_write(2,bgs_get_send_int(num));
}

static void bgs_send_str(_str string)
{
   _file_write(2,bg_get_send_str(string));
}

static _str bgs_get_send_raw(_str string)
{
   return(length(string)"\n"string);
}

static void bgs_send_raw(_str text)
{
   _file_write(2,bgs_get_send_raw(text));
}

static void bgs_send_file_status(bgs_state& search_state,_str &cur_file)
{
   _file_write(2,bg_get_send_str('file_status'):+
                 bgs_get_send_int(search_state.num_searched_files):+
                 bgs_get_send_raw(cur_file));
}

static void bgs_send_cur_file(bgs_state& search_state,_str &cur_file)
{
   _file_write(2,bg_get_send_str('cur_file'):+
               bgs_get_send_int(search_state.num_searched_files):+
               bgs_get_send_raw(cur_file));
}

static void bgs_send_cur_file_query(bgs_state& search_state,_str &cur_file)
{
   _file_write(2,bg_get_send_str("query"):+
               bgs_get_send_raw(cur_file));
}

static void bgs_send_cur_context(int context_id, int context_type, int context_linenum, int context_level, _str &cur_context)
{
   _file_write(2,bg_get_send_str('cur_context'):+
               bgs_get_send_int(context_id):+
               bgs_get_send_int(context_type):+
               bgs_get_send_int(context_linenum):+
               bgs_get_send_int(context_level):+
               bgs_get_send_raw(cur_context));
}

static void bgs_send_list_file(bgs_state& search_state,_str &cur_file)
{
   _file_write(2,bg_get_send_str('filelist'):+
                 bgs_get_send_int(search_state.num_searched_files):+
                 bgs_get_send_raw(cur_file));
}

static void bgs_send_file_error(bgs_state& search_state,_str &cur_file)
{
   _file_write(2,bg_get_send_str("error"):+
               bgs_get_send_raw(cur_file));
}



static void bgs_stop_and_exit(bgs_state& search_state)
{
   // tell the main editor that search is ending (either because
   // it ran to completion or encountered an error)
   //_message_box('pause');
   bgs_send_str('done');
   bgs_send_int(search_state.num_searched_files);
   exit();
}

/**
 * Synchronously read a line from stdin
 */
static _str bgs_recv_line(bgs_state& search_state)
{
   _str ret_value=search_state.recv_line_remainder;
   search_state.recv_line_remainder='';

   end_pos := pos("\n",ret_value);
   _str data;

   max_tries := 100;
   while ((end_pos<=0) && (max_tries>0)) {
      _file_read(0,data,100);
      if (length(data)>0) {
         ret_value :+= data;
         end_pos=pos("\n",ret_value);
      } else {
#if BGSEARCH_ALLOW_TIMEOUT
         --max_tries;
#endif
         delay(1);
      }
   }

#if BGSEARCH_ALLOW_TIMEOUT
   if (max_tries==0) {
      bgs_stop_and_exit(search_state);
   }
#endif

   search_state.recv_line_remainder=substr(ret_value,end_pos+1);
   ret_value=substr(ret_value,1,end_pos-1);

   return ret_value;
}

static int bgs_recv_int(bgs_state& search_state)
{
   _str temp = bgs_recv_line(search_state);
   if (isinteger(temp)) {
      return(int)temp;
   }
   return 0;
}

static _str bgs_recv_str(bgs_state& search_state)
{
   int size=bgs_recv_int(search_state);
   text := "";
   if (size>0) {
      text=bgs_recv_line(search_state);
   }

   if (length(text)!=size) {
      bgs_stop_and_exit(search_state);
   }

   return text;
}

static _str bgs_recv_raw(bgs_state& search_state)
{
   int size=bgs_recv_int(search_state);
   ret_value := "";
   _str cur_block;
   int cur_size;
   max_tries := 100;
   _str data;

   if (size>0) {
      cur_block=search_state.recv_line_remainder;
      search_state.recv_line_remainder='';
      cur_size=length(cur_block);
      while (cur_size<size) {
         _file_read(0,data,size-cur_size);
         if (length(data)>0) {
            strappend(cur_block,data);
            cur_size=length(cur_block);
         } else {
#if BGSEARCH_ALLOW_TIMEOUT
            --max_tries;
            if (max_tries<=0) {
               _message_box('quitting from recv_raw');
               bgs_stop_and_exit(search_state);
            }
#endif
            delay(1);
         }
      }
      search_state.recv_line_remainder=substr(cur_block,size+1);
      strappend(ret_value,substr(cur_block,1,size));
   }

   return ret_value;
}

static void bgs_update_buf_size(bgs_state& search_state,int change)
{
   if (!search_state.filesonly) {
      search_state.disp_buf_size+=change;
      if (search_state.disp_buf_size>search_state.disp_buf_max) {
         search_state.filesonly=true;
         bgs_send_str('buf_full');
      }
   }
}

static bool bgs_prepare_view(_str cur_file,int &temp_view_id,int &orig_view_id,bool &file_already_loaded)
{
   int status=_open_temp_view(cur_file,temp_view_id,orig_view_id,'-e',file_already_loaded,false,true,0,true);
   if (status) {
      return false;
   }
   if (p_file_size==0) {
      insert_line('');
      _delete_text(-2);
   }
   //_SetEditorLanguage();
   _updateTextChange();
   return true;
}

//
static void bgs_update_context(int context_id, int (&context_stack)[])
{
   buf_id := p_buf_id;

   int scope_ids[];
   if (context_id >= 0) {
      tag_search_result_context_get_contexts(buf_id, context_id, scope_ids);
   }

   i := 0;
   idx := -1;
   for (i = 0; (i < context_stack._length()) && (i < scope_ids._length()); ++i, ++idx) {
      if (context_stack[i] != scope_ids[i]) {
         break;
      }
   }

   // remove old elements
   for (i = idx + 1; i < context_stack._length(); ++i) {
      context_stack._deleteel(i);
   }

   // add new elements
   for (i = idx + 1; i < scope_ids._length(); ++i) {
      status := tag_search_result_context_get_info(buf_id, scope_ids[i], auto context_type, auto context_linenum, auto context_name);
      if (!status) {
         bgs_send_cur_context(scope_ids[i], context_type, context_linenum, i, context_name);
      }
      context_stack[i] = scope_ids[i];
   }

   if (context_id < 0) {
      bgs_send_cur_context(-1, 0, 0, 0, '');
   }
}

// 
static void bgs_add_search_result(bgs_state& search_state, _str& result_block, int &local_results,
                           int linenum, int col, int pcol, int matchlen, int line_type, int truncate, _str line)
{
   disp_prefix := linenum' 'col ':';
   bgs_update_buf_size(search_state,length(line)+length(disp_prefix)+3); // two leading spaces and newline

   prefix := linenum' 'col' 'pcol' 'matchlen' 'length(line)' 'line_type' 'truncate':';
   cur_result := prefix:+line;
   if ((local_results>=MAX_RESULT_BLOCK_NUM)||((length(result_block)+length(cur_result))>MAX_RESULT_BLOCK_SIZE)) {
      bgs_send(bg_get_send_str('result'):+bgs_get_send_raw(result_block));
      result_block='';
      local_results=0;
   }
   ++local_results;
   strappend(result_block, cur_result);
}

//
static void bgs_add_after_lines(bgs_state& search_state, _str& result_block, int &local_results,
                                    _str (&lines)[], int match_linenum, int& last_line)
{
   if (!lines._isempty()) {
      foreach(auto l in lines) {
         parse l with auto lnum ":" auto trunc ":" auto line;
         linenum := (int)lnum;
         if ((match_linenum > 0) && (linenum >= match_linenum)) break;

         bgs_add_search_result(search_state, result_block, local_results, linenum, 1, -1, -1, se.search.SEARCH_RESULT_LINE_POST_MATCH, (int)trunc, line);
         last_line = linenum;
      }
      lines._makeempty();
   }
}

static void bgs_process_file(bgs_state& search_state,_str cur_file)
{
   sent_cur_file := true;
   cur_file=strip(cur_file);
   _str text;
   result_block := "";
   cur_result := "";
   local_results := 0;

   if (search_state.searched_files._indexin(_file_case(cur_file))) {
      return;
   } else {
      if (!_mffind_file_stats_test(cur_file, search_state.file_stats)) {
         return;
      }
      search_state.searched_files:[_file_case(cur_file)]=true;
      ++search_state.num_searched_files;
   }
   if (search_state.mfflags & MFFIND_FIND_FILES) {
      bgs_send_list_file(search_state,cur_file);
      return;
   }
   if (search_state.buffers._indexin(_file_case(cur_file))) {
      bgs_send_cur_file_query(search_state,cur_file);
      return;
   }

   int temp_view_id;
   int prev_view_id;
   int found_one_status;
   int linenum;
   int col;
   int pcol;
   int FoundLen;
   int line_type;
   _str line;
   _str disp_prefix;
   _str prefix;
   int truncate;
   _str after_lines[];
   int context_stack[];
   bool file_already_loaded;
   if (bgs_prepare_view(cur_file,temp_view_id,prev_view_id,file_already_loaded)) {
      buf_id := p_buf_id;
      context_id := -1;
      context_start := -1;
      update_context := false;
      top();
      skipBinaryFile:=false;
      if (search_state.mfflags & MFFIND_INTERNAL_EXCLUDE_BINARY_FILES) {
         //skipBinaryFile=_mffind_is_binary_file();
         skipBinaryFile=(p_LangId=='binary');
         if (skipBinaryFile) {
            --search_state.num_searched_files;
         }
      }
      if (!skipBinaryFile) {
         if (search_state.send_cur_file_count <= 0) {
            bgs_send_file_status(search_state,cur_file);
            search_state.send_cur_file_count=SEND_CUR_FILE;
         } else {
            --search_state.send_cur_file_count;
            sent_cur_file=false;
         }
         found_one_status=search(search_state.search_string,'@':+_mffind_vlx_check(search_state.options));
         if (!found_one_status) {
            bgs_send_cur_file(search_state,cur_file);
            if (search_state.filesonly) {
               activate_window(prev_view_id);
               _delete_temp_view(temp_view_id);
               return;
            }
            bgs_update_buf_size(search_state,length(cur_file)+6);
            if ((search_state.mfflags & MFFIND_LIST_CURRENT_CONTEXT) && _istagging_supported(p_LangId) && (!_FindLanguageCallbackIndex("%s_proc_search"))) {
               update_context = true;
               se.tags.TaggingGuard sentry;
               sentry.lockContext(false);
               _UpdateContext(true, true);
               tag_search_result_context_start(buf_id);
            }
            last_line := -1;
            do {
               match_linenum := p_RLine; 
               match_col := _text_colc(p_col, 'P');
               match_offset := match_length('S');
               match_len := match_length();

               insert_ab_sep := false;

               if (update_context) {
                  last_context_id := context_id;
                  context_id = tag_search_result_context_find(buf_id, match_linenum, match_offset);
                  if (last_context_id != context_id) {
                     bgs_add_after_lines(search_state, result_block, local_results, after_lines, -1, -1);

                     // send new context
                     if ((context_id < 0) && (last_context_id >= 0)) {
                        bgs_add_search_result(search_state, result_block, local_results, -1, -1, -1, -1, se.search.SEARCH_RESULT_LINE_SEPARATOR, 0, '');
                     }

                     // send current results
                     if (local_results > 0) {
                        bgs_send(bg_get_send_str('result'):+bgs_get_send_raw(result_block));
                        result_block='';
                        local_results=0;
                     }

                     bgs_update_context(context_id, context_stack);
                     last_line = -1;
                  }
               }

               bgs_add_search_result(search_state, result_block, local_results, match_linenum, match_col, -1, -1, se.search.SEARCH_RESULT_PREFIX, 0, '');

               if (search_state.mfflags & MFFIND_MATCHONLY) {
                  utf8 := p_UTF8;
                  end_offset := (match_len > 0) ? (match_offset + match_len - 1) : match_offset;
                  goto_point(match_offset);
                  offset := (int)point('S');
                  line_type = se.search.SEARCH_RESULT_LINE_MATCH;
                  mlen := match_len;
                  linenum = match_linenum;
                  col = match_col; 
                  do {
                     last_offset := offset;
                     linenum = p_line; pcol = _text_colc(p_col, 'P'); len := mlen; truncate = 0;
                     line_len := (_line_length() - pcol) + 1;
                     if (line_len > len) {
                        line_len = len;
                     }
                     if ((def_search_result_max_line_size > 0) && (line_len > def_search_result_max_line_size)) {
                        line_len = def_search_result_max_line_size;
                        truncate |= se.search.SEARCH_RESULT_TRUNCATE_TRAILING_FLAG;
                     }
                     //truncate = SearchResults.getSearchResultLine(line, pcol, len);
                     line = get_text_raw(line_len); pcol = 1;
                     if (!utf8) {
                        line = SearchResults.convertToUTF8(line, pcol, line_len);
                     }
                     if (len < 0) len = 0;
                     bgs_add_search_result(search_state, result_block, local_results, linenum, col, pcol, line_len, line_type, truncate, line);
                     if (!search_state.multiline) break;
                     if (down()) break;
                     _begin_line(); offset = (int)point('S');
                     mlen -= (offset - last_offset);
                     linenum = p_line;  col = 1;
                     line_type = se.search.SEARCH_RESULT_LINE_CONTINUATION;
                  } while ((offset < end_offset) && (match_len > 0));

               } else {
                  save_pos(auto p);

                  before_match_lines := search_state.before_lines;
                  after_match_lines := search_state.after_lines;

                  if (before_match_lines > 0 || after_match_lines > 0) {
                     if (last_line > 0) {
                        insert_ab_sep = true;
                     }
                     if (after_match_lines > 0) {
                        bgs_add_after_lines(search_state, result_block, local_results, after_lines, match_linenum, last_line);
                     }
                     if (before_match_lines > 0) {
                        // check prematch lines
                        if (match_linenum < before_match_lines + 1) {
                           before_match_lines = match_linenum - 1;
                        }
                        if (last_line > 0) {
                           if (match_linenum <= (last_line + before_match_lines)) {
                              before_match_lines = match_linenum - (last_line + before_match_lines);
                              insert_ab_sep = false;
                           }

                           // don't add seperator for consecutive lines
                           if ((match_linenum - before_match_lines) <= (last_line + 1)) {
                              insert_ab_sep = false;
                           }
                        }
                     } else {
                        if (last_line > 0) {
                           // don't add seperator for consecutive lines
                           if (match_linenum <= (last_line + 1)) {
                              insert_ab_sep = false;
                           }
                        }
                     }
                  }
                  after_lines._makeempty();

                  if (insert_ab_sep) {
                     //insertLine(-1, -1, -1, "", SEARCH_RESULT_LINE_SEPARATOR, 0); //send sep
                     bgs_add_search_result(search_state, result_block, local_results, -1, -1, -1, -1, se.search.SEARCH_RESULT_LINE_SEPARATOR, 0, '');
                  }

                  // insert pre-lines
                  if (before_match_lines > 0) {
                     up(before_match_lines);
                     linenum = match_linenum - before_match_lines;
                     for (i := 0; i < before_match_lines; ++i, ++linenum) {
                        _begin_line();  len := _line_length();
                        truncate = SearchResults.getSearchResultLine(line, 1, len);
                        //insertLine(linenum, 1, -1, line, SEARCH_RESULT_LINE_PRE_MATCH, truncated);
                        bgs_add_search_result(search_state, result_block, local_results, linenum, 1, -1, -1, se.search.SEARCH_RESULT_LINE_PRE_MATCH, truncate, line);
                        last_line = linenum;
                        if (down()) break;
                     }
                     restore_pos(p);
                  }

                  end_offset := (match_len > 0) ? (match_offset + match_len - 1) : match_offset;
                  goto_point(match_offset);
                  offset := (int)point('S');
                  line_type = se.search.SEARCH_RESULT_LINE_MATCH;
                  mlen := match_len;
                  linenum = match_linenum;
                  col = match_col; 
                  do {
                     last_offset := offset;
                     pcol = _text_colc(p_col, 'P'); len := mlen;
                     truncate = SearchResults.getSearchResultLine(line, pcol, len);
                     last_line = linenum;
                     bgs_add_search_result(search_state, result_block, local_results, linenum, col, pcol, len, line_type, truncate, line);
                     if (!search_state.multiline) break;
                     if (down()) break;
                     _begin_line(); offset = (int)point('S');
                     mlen -= (offset - last_offset);
                     ++linenum;  col = 1;
                     line_type = se.search.SEARCH_RESULT_LINE_CONTINUATION;
                  } while ((offset < end_offset) && (match_len > 0));


                  // insert post-lines
                  if (after_match_lines > 0) {
                     goto_point(match_offset+match_len);
                     linenum = p_RLine;
                     for (i := 0; i < after_match_lines; ++i) {
                        if (down()) break;
                        _begin_line(); len := _line_length(); ++linenum;
                        truncated := SearchResults.getSearchResultLine(line, 1, len);
                        after_lines[after_lines._length()] = linenum':'truncated':'line;
                     }
                  }
                  restore_pos(p);
               }

            } while (!repeat_search());

            bgs_add_after_lines(search_state, result_block, local_results, after_lines, -1, last_line);
            if (local_results > 0) {
               bgs_send(bg_get_send_str('result'):+bgs_get_send_raw(result_block));
            }
         }
      }
      activate_window(prev_view_id);
      _delete_temp_view(temp_view_id);
      if (update_context) {
         tag_search_result_context_end(buf_id);
      }

   } else {
      // failed to load (or receive) the file
      if (search_state.send_cur_file_count <= 0) {
         bgs_send_file_status(search_state,cur_file);
         search_state.send_cur_file_count=SEND_CUR_FILE;
      } else {
         --search_state.send_cur_file_count;
         sent_cur_file=false;
      }
      
      bgs_send_file_error(search_state,cur_file);
   }
}

static void bgs_process_directory(bgs_state& search_state,_str dirname,bool recurse,bool append_wildcards,_str attr_flags,int look_in_zipfiles)
{
   file_list := "";
   exclude_list := "";
   filter := "";

   if (append_wildcards) {
      _str list=search_state.wildcards;
      wildcard_list := "";
      _str wildcard;
      while (list!='') {
         wildcard=parse_file_sepchar(list);
         if (wildcard!='') {
            strappend(wildcard_list,' '_maybe_quote_filename(wildcard));
         }
      }
      file_list=_maybe_quote_filename(dirname);
      if (wildcard_list!='') {
         strappend(file_list,' -wc':+wildcard_list);
      }
   } else {
      filter=_strip_filename(dirname,'P');
      file_list=_maybe_quote_filename(dirname);
   }

   if (search_state.file_exclude != '') {
      _str file_exclude = search_state.file_exclude;
      _str list = file_exclude;
      while (list != '') {
         file_exclude=parse_file_sepchar(list);
         if (file_exclude != '') {
            strappend(exclude_list,' -exclude '_maybe_quote_filename(file_exclude));
         }
      }
   }

#if 1  /*__UNIX__ */
   //Always do this so don't have to worry about symbolic links.
   //Also, the +F option isn't implemented in the new findfirst/findnext code.
   // The purpose of the other code was to allow for some searching to be performed 
   // BEFORE the all files were listed to show the user output.
   // A better way to do this would be to all an
   // insert_file_list callback for each file output.
   _str tree_option=_isUnix()?'':search_state.attr_flags;
   if (recurse) {
      tree_option = '+t ' :+ tree_option;
   }
   insert_list :=  '+w -v +p 'tree_option' ':+file_list;
   if (look_in_zipfiles) {
      insert_list='+z 'insert_list;
   }
   if (exclude_list) {
      strappend(insert_list, exclude_list);
   }

   if (search_state.sort_filenames) {
      get_window_id(auto orig_view_id);
      activate_window(search_state.sortfile_view_id);
      insert_file_list(insert_list);
      activate_window(orig_view_id);

   } else {
      int temp_view_id;
      int orig_view_id=_create_temp_view(temp_view_id);

      insert_file_list(insert_list);
      top();up();
      _str line;
      while (!down()) {
         get_line(line);
         bgs_process_file(search_state,line);
      }

      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }

#else
   tree_option := "";
   if (recurse) {
      tree_option = '+f +d';
   }
   insert_list :=  '+w -v +p 'tree_option' 'attr_flags' ':+file_list;
   if (exclude_list) {
      strappend(insert_list, exclude_list);
   }
   insert_file_list(insert_list);

   _str filename;
   _str name;
   top();up();
   while (!down()) {
      get_line(filename);
      filename=strip(filename);
      if (last_char(filename)==FILESEP) {
         name=substr(filename,1,length(filename)-1);
         name=_strip_filename(name,'P');
         if (name!='.' && name!='..') {
            bgs_process_directory(search_state,filename:+filter,recurse,append_wildcards,attr_flags);
         }
      } else {
         bgs_process_file(search_state,filename);
      }
   }
#endif
}

// _editor_cmdline contains all arguments passed to VSE and is set in main.e
_str _editor_cmdline;

_command void bgsearch()
{
   // check if this is being run directly (bad) or by launching a background search (good)
   if (!pos('bgsearch',_editor_cmdline)) {
      message('bgsearch can only be used for background searches');
      return;
   }
   _default_option(VSOPTION_FORCE_WRAP_LINE_LEN,(MAXINT intdiv 2)-1000);

   bgs_state search_state;

   search_state.searched_files._makeempty();
   search_state.num_searched_files=0;
   search_state.buffers._makeempty();
   search_state.send_cur_file_count=0;
   search_state.recv_line_remainder='';

   // do not return from this function anywhere past here
   // returning will cause the editor to exit normally and save
   // the user configuration/display settings which is probably
   // not what they want.  instead of returning, call stop_and_exit()
   // note: if there is a pipe error, stop_and_exit will also be called then
   count_file := 0;
   count_buffer := 0;
   quit := false;
   load_file := false;

   bgs_send_line(START_SEQUENCE);
   bgs_send_str('focus');
   bgs_recv_raw(search_state); // skip spill file path
   bgs_recv_raw(search_state); // skip vsroot
   bgs_recv_raw(search_state); // skip plugin path
   bgs_recv_raw(search_state);  // skip config path
   search_state.disp_buf_size=bgs_recv_int(search_state);
   search_state.disp_buf_max=bgs_recv_int(search_state);
   if (search_state.disp_buf_max <= 0) {
      search_state.disp_buf_max = MAXINT;
   }
   search_state.search_string=bgs_recv_raw(search_state);
   search_state.mfflags=bgs_recv_int(search_state);
   search_state.multiline=bgs_recv_int(search_state);
   search_state.before_lines=bgs_recv_int(search_state);
   search_state.after_lines=bgs_recv_int(search_state);
   search_state.filesonly=(search_state.mfflags & MFFIND_FILESONLY)!=0;
   search_state.options=bgs_recv_raw(search_state);
   search_state.attr_flags=bgs_recv_raw(search_state);
   search_state.sort_filenames=bgs_recv_int(search_state);

   // file stats
   file_stats := bgs_recv_raw(search_state);
   _mffind_file_stats_init(file_stats, search_state.file_stats);

   int num_buffers=bgs_recv_int(search_state);

   for (;count_buffer<num_buffers;++count_buffer) {
      _str bname=bgs_recv_str(search_state);
      search_state.buffers:[_file_case(bname)]=true;
   }

   search_state.wildcards=bgs_recv_raw(search_state);
   search_state.file_exclude=bgs_recv_raw(search_state);
   int num_files=bgs_recv_int(search_state);

   int file_list_view_id;
   int orig_view_id=_create_temp_view(file_list_view_id);
   p_buf_name='mylist';

   if ((orig_view_id:=='') || (file_list_view_id:=='')) {
      bgs_stop_and_exit(search_state);
   }

   _str fname;
   // get all search paths/files/buffers/whatever out of the pipe
   // before searching anything
   for (;count_file<num_files;++count_file) {
      fname=bgs_recv_str(search_state);
      bottom();insert_line(fname);
   }

   search_state.sortfile_view_id = 0;
   if (search_state.sort_filenames != 0) {
      _create_temp_view(search_state.sortfile_view_id);
      activate_window(file_list_view_id);
   }

   top();up();
   while (!down()) {
      options := "";
      get_line(fname);
      fname = strip_options(fname, options, true);
      first_flag := substr(options, 1, 2);
      options = substr(options, 4);
      if ((first_flag:=='+d') || (first_flag:=='+f')) {
         // append wildcards and search for files
         recurse := false;
         if (pos('+t', options)) {
            recurse = true;
            options = substr(options, 4);
         }
         bgs_process_directory(search_state, fname, recurse, first_flag:=='+d', options,search_state.mfflags & MFFIND_LOOKINZIPFILES);
      } else {
         if (search_state.sort_filenames) {
            activate_window(search_state.sortfile_view_id);
            insert_line(fname);
         } else {
            bgs_process_file(search_state, fname);
         }
      }

      activate_window(file_list_view_id);
   }

   if (search_state.sort_filenames != 0) {
      activate_window(search_state.sortfile_view_id);
      sort_buffer(_fpos_case);
      _remove_duplicates(_fpos_case);

      top();up();
      while (!down()) {
         get_line(fname);
         bgs_process_file(search_state, fname);
         activate_window(search_state.sortfile_view_id);
      }
      activate_window(orig_view_id);
   }

   activate_window(orig_view_id);
   _delete_temp_view(file_list_view_id);
   if (search_state.sortfile_view_id != 0) {
      _delete_temp_view(search_state.sortfile_view_id);
   }
   bgs_stop_and_exit(search_state);
}

