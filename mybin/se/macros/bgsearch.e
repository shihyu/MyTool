////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49771 $
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
#include "pipe.sh"
#import "autosave.e"
#import "files.e"
#import "main.e"
#import "makefile.e"
#import "mfsearch.e"
#import "search.e"
#import "sellist.e"
#import "stdprocs.e"
#import "tbautohide.e"
#import "tbsearch.e"
#import "tbfind.e"
#import "toast.e"
#import "toolbar.e"
#import "wkspace.e"
#require "se/search/SearchResults.e"
#endregion

using se.search.SearchResults;

// set to 1 while debugging
#define ALLOW_TIMEOUT            (0)

#define MAX_RESULT_BLOCK_SIZE    (50000)
#define MAX_RESULT_BLOCK_NUM     (50)
#define SEND_CUR_FILE            (50)
#define START_SEQUENCE           "***"

// used by both bgm_ and bgs_ functions
static _str bg_get_send_str(_str string)
{
   return(length(string)"\n"string"\n");
}

/****************************************
functions that monitor and control search
prefix: bgm_ background monitor
****************************************/
static boolean bgm_received_start_sequence;
static int     bgm_hin;
static int     bgm_hout;
static int     bgm_herr;
static int     bgm_proc_handle;
static int     bgm_mfflags;
static boolean bgm_displayed_file=false;
static _str    bgm_cur_file='';
static int     bgm_NofMatches;
static int     bgm_NofFileMatches;
static int     bgm_NofFiles;
static boolean bgm_search_stopped;
static boolean bgm_ignoring_file;
static _str    bgm_search_string;
static _str    bgm_options;
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

int bgm_gen_file_list(int &temp_view_id,_str files,_str &wildcards,_str file_exclude,boolean files_delimited_with_pathsep,
                      boolean searchProjectFiles,boolean searchWorkspaceFiles,boolean expandWildcards=false,
                      boolean recursive=false,_str (&file_array)[]=null)
{
   int orig_view_id;
   get_window_id(orig_view_id);
   if (wildcards=='') wildcards=ALLFILES_RE;
   _create_temp_view(temp_view_id);
   _str split_char=' ';
   if (files_delimited_with_pathsep) {
      split_char=def_mffind_pathsep;
   }
   _str tree_option='';
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
   for (;;) {
      if (files_delimited_with_pathsep) {
         parse files with filename (def_mffind_pathsep) files;
         if (filename=='') break;
      } else {
         filename= parse_file(files,false);
         if (filename=='') break;
      }
      file_array[file_array._length()]=filename;
   }

   _str exclude_list='';
   if (file_exclude != '') {
      _str list = file_exclude;
      while (list != '') {
         parse list with file_exclude ";" list;
         if (file_exclude != '') {
            file_exclude = strip(file_exclude, 'B');
            if (exclude_list == '') {
               exclude_list = ' -exclude ':+maybe_quote_filename(file_exclude);
            } else {
               strappend(exclude_list, ' 'maybe_quote_filename(file_exclude));
            }
         }
      }
   }

   boolean addedWorkspaceFiles=(_workspace_filename=='');  // if there is no workspace, say it has been added
                                                           // so that it won't be added if it is in the file list
   boolean addedProjectFiles=(_project_name=='');          // ditto
   boolean addedBuffers=false;
   boolean addedCurrent=false;
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
               int files_wid = p_window_id;
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
            int files_wid=p_window_id;
            GetProjectFiles(_project_name,files_wid,'',null,'',false,true,true);
            bottom();insert_line('-stop');
         }

      } else if (pos("<Project: ", filename)) {
         _str project_file='';
         _str workpace_path=_strip_filename(_workspace_filename,'N');
         parse filename with "<Project: " project_file ">";
         insert_line('-start');
         int files_wid=p_window_id;
         GetProjectFiles(absolute(project_file,workpace_path),files_wid,'',null,'',false,true,true);
         bottom();insert_line('-stop');
      } else if (strieq(filename,MFFIND_BUFFERS)) {
         if (!addedBuffers) {
            addedBuffers=true;
            _str name=buf_match('',1,'b');
            while (!rc) {
               if (name != '' && name != '.process' && !_isGrepBuffer(name)) {
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
               if (name != '' && name != '.process' && !_isGrepBuffer(name)) {
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
               if (name != '' && name != '.process' && !_isGrepBuffer(name)) {
                  filename = _strip_filename(name, 'N'); 
               }
            }
            if (strieq(filename, MFFIND_BUFFER_DIR)) {
               continue;
            }
         }
         filename=absolute(filename);
         boolean isDirectory=(!iswildcard(filename) || file_exists(filename)) && (isdirectory(filename) || last_char(filename)==FILESEP);
         if (isDirectory) {
            _maybe_append_filesep(filename);
            if (expandWildcards) {
               _str list=wildcards;
               _str file_list='';
               _str wildcard;
               while (list!='') {
                  parse list with wildcard '[;:]','r' list;
                  if (wildcard!='') {
                     _str filename2=filename:+strip(wildcard, 'B');
                     if (file_list=='') {
                        file_list=maybe_quote_filename(filename2);
                     } else {
                        strappend(file_list,' 'maybe_quote_filename(filename2));
                     }
                  }
               }
               _str insert_list = '+w -v +p ':+options:+tree_option' ':+file_list;
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
               insert_line('+d ':+options:+tree_option' ':+filename);
            }
         } else if (iswildcard(filename) && !file_exists(filename)) {
            if (expandWildcards) {
               _str insert_list = '+w -v +p ':+options:+tree_option' ':+maybe_quote_filename(filename);
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
   _str wildcard_re=bgm_make_re(wildcards);
   _str path_re = '';
   _str exclude_re = bgm_make_exclude_re(file_exclude, path_re);
   boolean is_filtering=false;
   _str fname, pname;
   _str pos_options = 'R':+_fpos_case;

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
         } else if (!pos(wildcard_re,fname,1,pos_options)) {
            if (_delete_line()) break;
            up();
         } else if ((exclude_re != '') && pos(exclude_re,fname,1,pos_options)) {
            if (_delete_line()) break;
            up();      
         } else if ((path_re != '') && pos(path_re,pname,1,pos_options)) {
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

static boolean bgm_send_file_list(_str files,int mfflags,_str wildcards,_str file_exclude,boolean files_delimited_with_pathsep,
                                  boolean searchProjectFiles,boolean searchWorkspaceFiles)
{
   int temp_view_id;
   int orig_view_id;
   get_window_id(orig_view_id);
   if (bgm_gen_file_list(temp_view_id,files,wildcards,file_exclude,files_delimited_with_pathsep,searchProjectFiles,searchWorkspaceFiles)) {
      return true;
   }

   activate_window(temp_view_id);

   bgm_send_raw(bgm_hout,wildcards);
   bgm_send_raw(bgm_hout,file_exclude);
   bgm_filter_project_files(wildcards, file_exclude);
   int num_files=p_Noflines;
   bgm_send_int(bgm_hout,num_files);

   top();up();
   while (!down()) {
      get_line(auto fname);
      bgm_send_str(bgm_hout,fname);
   }
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   return false;
}

static void bgm_send_buffer_list()
{
   _str buffers[];
   buffers._makeempty();

   _str name=buf_match('',1);
   while (!rc) {
      if ((name != '') && (name != '.process') && !_isGrepBuffer(name)) {
         buffers[buffers._length()]=name;
      }
      name=buf_match('',0);
   }

   bgm_send_int(bgm_hout,buffers._length());

   typeless index;
   for (index._makeempty();;) {
      buffers._nextel(index);
      if (index._isempty()) break;
      bgm_send_str(bgm_hout,buffers[index]);
   }
}

static _str bgm_read_buffer;

static boolean bgm_test(int pipe)
{
   if (length(bgm_read_buffer)>0) {
      return(true);
   }
   _str test;
   _PipeRead(pipe,test,1,1);
   return(length(test)>0);
}

static void bgm_read_line(int pipe,_str &buffer)
{
   if (length(bgm_read_buffer)) {
      int i=pos("\n",bgm_read_buffer);
      if (i) {
         buffer=substr(bgm_read_buffer,1,i-1);
         bgm_read_buffer=substr(bgm_read_buffer,i+1);
         return;
      }
   }
   int max_tries=100;
   _str test;
   _str new_buffer;
   while(max_tries>0) {
      _PipeRead(pipe,test,1,1);
      if (!length(test)) {
#if ALLOW_TIMEOUT
         --max_tries;
#endif
         delay(1);
         continue;
      }
      _PipeRead(pipe,new_buffer,MAX_RESULT_BLOCK_SIZE,0);
      strappend(bgm_read_buffer,new_buffer);
      int i=pos("\n",bgm_read_buffer);
      if (i) {
         buffer=substr(bgm_read_buffer,1,i-1);
         bgm_read_buffer=substr(bgm_read_buffer,i+1);
         return;
      }
   }
#if ALLOW_TIMEOUT
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
   int max_tries=100;
   _str test;
   _str new_buffer;
   while(max_tries>0) {
      _PipeRead(pipe,test,1,1);
      if (!length(test)) {
#if ALLOW_TIMEOUT
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
#if ALLOW_TIMEOUT
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
   _str text='';
   if (size>0) {
      text=bgm_recv_line(pipe);
   }

   return text;
}
// takes the wildcards string and generates a SlickEdit regular expression
_str bgm_make_re(_str wildcards)
{
   _str re='';
   _str filter;
   _str ch;
   wildcards=strip(wildcards);

   while (wildcards != '') {
      parse wildcards with filter '[;:]','r' wildcards;
      if (filter != '') {
         filter = strip(filter, 'B');
         if (last_char(re) == ')') {
            strappend(re, '|(');
         } else {
            strappend(re, '(');
         }
         if (filter == '*.*') {
            filter = '*';
         }
         if (first_char(filter) != '*') {
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
   _str re='';
   _str filter;
   _str ch;
   wildcards = strip(wildcards);
   path_re = '';

   while (wildcards != '') {
      parse wildcards with filter '[;:]','r' wildcards;
      if (filter != '') {
         filter = strip(filter, 'B');
         _str* dest_re = &re;
         if (last_char(filter) == FILESEP) {
            dest_re = &path_re;
         }
         if (last_char(*dest_re) == ')') {
            strappend(*dest_re, '|(');
         } else {
            strappend(*dest_re, '(');
         }
         if (filter == '*.*') {
            filter = '*';
         }
         if (first_char(filter) != '*') {
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

static void bgm_terminate_search(boolean quiet=false)
{
   gbgm_search_state=0;
   _tbFindUpdateBGSearchStatus();
   _PipeTerminateProcess(bgm_proc_handle);
   _PipeCloseProcess(bgm_proc_handle);
   _PipeEndProcess(bgm_proc_handle);
   _autosave_set_timer_alternate();
   if (quiet) return;

   _str text='';
   if (bgm_NofFiles>0) {
      // .NET does not do this, it uses the full result string even with "Display file names only"
      // .NET also does not have a separate message for no matches found if it search files
      //    i.e.  it can display  "Total found: 0 Matching files: 0 Total files searched: 22"
      if (bgm_mfflags&MFFIND_FILESONLY) {
         text='Matching files: 'bgm_NofFileMatches'     Total files searched: 'bgm_NofFiles;
      } else {
         text='Total found: 'bgm_NofMatches'     Matching files: 'bgm_NofFileMatches'     Total files searched: 'bgm_NofFiles;
      }
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

static boolean bgm_process_file(boolean doDeleteBuffer=false)
{
   boolean added_results=false;
   _str search_options = '@H'bgm_options;
   _SetAllOldLineNumbers();
   save_search(auto p1, auto p2, auto p3, auto p4, auto p5);
   top();
   int status = search(bgm_search_string, search_options);
   if (!status) {
      added_results = true;
      buf_name := _build_buf_name();
      bgm_results.insertFileLine(buf_name);
      ++bgm_NofFileMatches;
      if (!(bgm_mfflags&MFFIND_FILESONLY)) {
         while (!status) {
            ++bgm_NofMatches;
            bgm_results.insertCurrentMatch();
            status = repeat_search();
         }
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

void bgm_update_search()
{
   if (gbgm_search_state != BG_SEARCH_ACTIVE) {
      return;
   }

   _str orig_strlen_warn=_default_option(VSOPTION_WARNING_STRING_LENGTH);
   if (orig_strlen_warn < MAX_RESULT_BLOCK_SIZE*2) {
      _default_option(VSOPTION_WARNING_STRING_LENGTH,MAX_RESULT_BLOCK_SIZE*2);
   }

   gbgm_search_state |= BG_SEARCH_UPDATE;

   boolean continue_search=true;
   boolean added_results=false;
   boolean cancel=false;
   long next_idle_time=_idle_time_elapsed();
   long last_idle_time=next_idle_time-1;
   _str cmd;

   while (last_idle_time<=next_idle_time && continue_search &&  bgm_test(bgm_herr) ) {
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
            if ((!bgm_ignoring_file)&&(!bgm_displayed_file)) {
               bgm_results.insertFileLine(bgm_cur_file);
               bgm_displayed_file=true;
               ++bgm_NofFileMatches;
            }
            if (bgm_mfflags&MFFIND_FILESONLY) {
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
                     _str line;
                     parse all_results with pcol FoundLen LineLen truncate linenum col':'all_results;
                     line=substr(all_results,1,LineLen);
                     all_results=substr(all_results,LineLen+1);
                     bgm_results.insertLine(pcol, FoundLen, linenum, col, line, truncate);
                     ++bgm_NofMatches;
                  }
               }
            }
            break;
         case 'cur_file':
            bgm_NofFiles=bgm_recv_int(bgm_herr);
            bgm_cur_file=strip(bgm_recv_raw(bgm_herr));
            sticky_message(bgm_cur_file);
            bgm_displayed_file=false;
            bgm_ignoring_file=false;
            break;
         case 'buf_full':
            // with the main editor searching open files, it could have already done this
            if (!(bgm_mfflags&MFFIND_FILESONLY)) {
               if (def_max_mffind_output>=(2*1024*1024)) {
                  bgm_results.insertMessage('Output larger than '(int)(def_max_mffind_output/(1024*1024)):+'MB. Switching to files only mode.');
               } else {
                   bgm_results.insertMessage('Output larger than '(int)(def_max_mffind_output/1024):+'KB. Switching to files only mode.');
               }
               bgm_mfflags|=MFFIND_FILESONLY;
               bgm_results.setMFFlags(MFFIND_FILESONLY, 0);
            }
            break;
         case 'query':
            boolean buffer_already_exists;
            int temp_view_id;
            int orig_view_id;
            int status=_open_temp_view(bgm_cur_file,temp_view_id,orig_view_id,'',buffer_already_exists,false,true);
            bgm_ignoring_file=buffer_already_exists;
            if (status) {
               bgm_results.insertMessage('Failed to open: 'bgm_cur_file);
               added_results=true;
            } else {
               if (bgm_process_file(!buffer_already_exists)) {
                  added_results=true;
               }
            }
            break;
         case 'error':
            if (!bgm_ignoring_file) {
               bgm_results.insertMessage('Failed to open: 'bgm_cur_file);
               added_results=true;
            }
            break;
         case 'focus':
   #if !__UNIX__
            // spawning the second editor causes the focus to shift to it
            // need to get focus back to the main editor
            if (!_AppHasFocus()) {
               //_mdi._set_foreground_window();
               if (_find_object("_tbfind_form",'') && !_tbIsAutoHidden("_tbfind_form")) {
                  activate_toolbar("_tbfind_form", "_findstring");
               } else {
                  //toolShowSearch(bgm_grep_id);
                  _mdi._set_foreground_window();
               }
            }
   #endif
            break;
         case 'done':
            bgm_NofFiles=bgm_recv_int(bgm_herr);
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

void start_bgsearch(_str search_string,_str options,_str files,int mfflags,boolean searchProjectFiles,boolean searchWorkspaceFiles,_str wildcards,_str file_exclude,boolean files_delimited_with_pathsep,int grep_id)
{
   if (gbgm_search_state) {
      message('There is a background search running.');
      return;
   }
   bgm_read_buffer='';
   bgm_search_string=search_string;
   bgm_options=options;
   bgm_mfflags=mfflags;

   topline := se.search.generate_search_summary(search_string,options,files,mfflags,wildcards,file_exclude);
   set_find_next_msg(topline);
   bgm_results.initialize(topline, search_string, mfflags, grep_id);
   bgm_results.showResults();
   toolSearchScroll();

   bgm_NofMatches=0;
   bgm_NofFileMatches=0;
   bgm_NofFiles=0;
   bgm_search_stopped=false;
   bgm_ignoring_file=false;

   // 1-AD56U (DJB):
   // always invoke background editor using 
   // -sul to disable locking on Unix
#if __UNIX__
   lock_option := " -sul";
#else
   lock_option := "";
#endif

   bgm_proc_handle=_PipeProcess(maybe_quote_filename(editor_name("E")):+' +new':+lock_option:+' -q -st 0 -mdihide -r bgsearch',bgm_hin,bgm_hout,bgm_herr,'');

   if (bgm_proc_handle<0) {
      message('There was an error starting the search process');
      return;
   }

   gbgm_search_state=BG_SEARCH_ACTIVE;
   bgm_received_start_sequence=false;
   _autosave_set_timer_alternate();

   bgm_send_int(bgm_hout,0);
   bgm_send_int(bgm_hout,def_max_mffind_output);
   bgm_send_raw(bgm_hout,search_string);
   bgm_send_int(bgm_hout,bgm_mfflags);
   bgm_send_raw(bgm_hout,options);

   bgm_send_buffer_list();

   if (bgm_send_file_list(files,mfflags,wildcards,file_exclude,files_delimited_with_pathsep,searchProjectFiles,searchWorkspaceFiles)) {
      stop_search('quiet');
      message('There was an error starting the search process');
      return;
   }

   _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_BACKGROUND_SEARCH, 'Find in Files started', '', 0);
}

/************************************
functions that perform actual search
prefix: bgs_ background search
************************************/
static struct bgs_state {
   boolean  searched_files:[];
   int      num_searched_files;
   _str     search_string;
   _str     options;
   int      mfflags;
   boolean  filesonly;
   _str     wildcards;
   _str     file_exclude;
   boolean  buffers:[];
   int      disp_buf_size;       // estimate of the size of the display buffer in the main editor
   int      disp_buf_max;        // the maximum to put in the buffer
   int      send_cur_file_count;
   _str     recv_line_remainder;
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

static void bgs_send_cur_file(bgs_state& search_state,_str &cur_file)
{
   _file_write(2,bg_get_send_str('cur_file'):+
                 bgs_get_send_int(search_state.num_searched_files):+
                 bgs_get_send_raw(cur_file));
}

static void bgs_send_cur_file_query(bgs_state& search_state,_str &cur_file)
{
   _file_write(2,bg_get_send_str('cur_file'):+
               bgs_get_send_int(search_state.num_searched_files):+
               bgs_get_send_raw(cur_file):+
               bg_get_send_str("query"));
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

   int end_pos=pos("\n",ret_value);
   _str data;

   int max_tries=100;
   while ((end_pos<=0) && (max_tries>0)) {
      _file_read(0,data,100);
      if (length(data)>0) {
         ret_value=ret_value:+data;
         end_pos=pos("\n",ret_value);
      } else {
#if ALLOW_TIMEOUT
         --max_tries;
#endif
         delay(1);
      }
   }

#if ALLOW_TIMEOUT
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
   _str text='';
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
   _str ret_value='';
   _str cur_block;
   int cur_size;
   int max_tries=100;
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
#if ALLOW_TIMEOUT
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

static boolean bgs_prepare_view(_str cur_file,int &temp_view_id,int &orig_view_id,boolean &file_already_loaded)
{
   int status=_open_temp_view(cur_file,temp_view_id,orig_view_id,'',file_already_loaded,false,true,0,true);
   if (status) {
      return false;
   }
   //_SetEditorLanguage();
   return true;
}

static void bgs_process_file(bgs_state& search_state,_str cur_file)
{
   boolean sent_cur_file=true;
   cur_file=strip(cur_file);
   _str text;
   _str result_block='';
   _str cur_result='';
   int local_results=0;

   if (search_state.searched_files._indexin(_file_case(cur_file))) {
      return;
   } else {
      search_state.searched_files:[_file_case(cur_file)]=true;
      ++search_state.num_searched_files;
   }

   if (search_state.buffers._indexin(_file_case(cur_file))) {
      bgs_send_cur_file_query(search_state,cur_file);
      return;
   } else if (search_state.send_cur_file_count <= 0) {
      bgs_send_cur_file(search_state,cur_file);
      search_state.send_cur_file_count=SEND_CUR_FILE;
   } else {
      --search_state.send_cur_file_count;
      sent_cur_file=false;
   }

   int temp_view_id;
   int prev_view_id;
   int found_one_status;
   int linenum;
   int col;
   int pcol;
   int FoundLen;
   _str line;
   _str disp_prefix;
   _str prefix;
   int truncate;
   boolean file_already_loaded;
   if (bgs_prepare_view(cur_file,temp_view_id,prev_view_id,file_already_loaded)) {
      top();
      found_one_status=search(search_state.search_string,'@'search_state.options);
      if (!found_one_status) {
         if (!sent_cur_file) {
            bgs_send_cur_file(search_state,cur_file);
         }
         bgs_update_buf_size(search_state,length(cur_file)+6);// 12345          6
                                                              // File (cur_file)\n
         do {
            linenum=p_line;col=p_col;
            FoundLen=match_length();
            truncate=SearchResults.getSearchResultLine(line, pcol, FoundLen, search_state.mfflags);
            disp_prefix=linenum' 'col':';
            prefix=pcol' 'FoundLen' 'length(line)' 'truncate' 'disp_prefix;
            cur_result=prefix:+line;
            bgs_update_buf_size(search_state,length(line)+length(disp_prefix)+3); // two leading spaces and newline

            if ((local_results>=MAX_RESULT_BLOCK_NUM)||((length(result_block)+length(cur_result))>MAX_RESULT_BLOCK_SIZE)) {
               bgs_send(bg_get_send_str('result'):+bgs_get_send_raw(result_block));
               result_block='';
               local_results=0;
            }

            ++local_results;
            strappend(result_block,cur_result);
         } while ((!search_state.filesonly)&&(!repeat_search()));
         if (local_results>0) {
            bgs_send(bg_get_send_str('result'):+bgs_get_send_raw(result_block));
         }
      }
      activate_window(prev_view_id);
      _delete_temp_view(temp_view_id);
   } else {
      if (!sent_cur_file) {
         bgs_send_cur_file(search_state,cur_file);
      }
      // failed to load (or receive) the file
      bgs_send_str('error');
   }
}

static void bgs_process_directory(bgs_state& search_state,_str dirname,boolean recurse,boolean append_wildcards,_str attr_flags)
{
   _str file_list='';
   _str exclude_list='';
   _str filter='';

   if (append_wildcards) {
      _str list=search_state.wildcards;
      _str wildcard;
      _str filename2;
      while (list!='') {
         parse list with wildcard '[;:]','r' list;
         if (wildcard!='') {
            filename2=dirname:+strip(wildcard, 'B');
            if (file_list=='') {
               file_list=maybe_quote_filename(filename2);
            } else {
               strappend(file_list,' 'maybe_quote_filename(filename2));
            }
         }
      }
   } else {
      filter=_strip_filename(dirname,'P');
      file_list=maybe_quote_filename(dirname);
   }

   if (search_state.file_exclude != '') {
      _str file_exclude = search_state.file_exclude;
      _str list = file_exclude;
      while (list != '') {
         parse list with file_exclude ";" list;
         if (file_exclude != '') {
            file_exclude = strip(file_exclude, 'B');
            if (exclude_list == '') {
               exclude_list = ' -exclude ':+maybe_quote_filename(file_exclude);
            } else {
               strappend(exclude_list, ' 'maybe_quote_filename(file_exclude));
            }
         }
      }
   }

   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
#if __UNIX__
   _str tree_option='';
   if (recurse) {
      tree_option='+t';
   }
   _str insert_list = '+w -v +p 'tree_option' ':+file_list;
   if (exclude_list) {
      strappend(insert_list, exclude_list);
   }
   insert_file_list(insert_list);
   top();up();
   _str line;
   while (!down()) {
      get_line(line);
      bgs_process_file(search_state,line);
   }
#else
   _str tree_option='';
   if (recurse) {
      tree_option = '+f +d';
   }
   _str insert_list = '+w -v +p 'tree_option' 'attr_flags' ':+file_list;
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
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
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
   int count_file=0;
   int count_buffer=0;
   boolean quit=false;
   boolean load_file=false;

   bgs_send_line(START_SEQUENCE);
   bgs_send_str('focus');
   search_state.disp_buf_size=bgs_recv_int(search_state);
   search_state.disp_buf_max=bgs_recv_int(search_state);
   search_state.search_string=bgs_recv_raw(search_state);
   search_state.mfflags=bgs_recv_int(search_state);
   search_state.filesonly=(search_state.mfflags&MFFIND_FILESONLY)!=0;
   search_state.options=bgs_recv_raw(search_state);
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

   top();up();
   while (!down()) {
      _str options = '';
      get_line(fname);
      fname = strip_options(fname, options, true);
      _str first_flag = substr(options, 1, 2);
      options = substr(options, 4);
      if ((first_flag:=='+d') || (first_flag:=='+f')) {
         // append wildcards and search for files
         boolean recurse = false;
         if (pos('+t', options)) {
            recurse = true;
            options = substr(options, 4);
         }
         bgs_process_directory(search_state, fname, recurse, first_flag:=='+d', options);
      } else {
         bgs_process_file(search_state, fname);
      }

      activate_window(file_list_view_id);
   }
   activate_window(orig_view_id);
   _delete_temp_view(file_list_view_id);
   bgs_stop_and_exit(search_state);
}

