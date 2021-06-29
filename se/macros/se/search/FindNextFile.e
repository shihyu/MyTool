////////////////////////////////////////////////////////////////////////////////////
// Copyright 2016 SlickEdit Inc. 
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
#include "slick.sh"
#import "complete.e"
#import "cutil.e"
#import "files.e"
#import "makefile.e"
#import "markfilt.e"
#import "slickc.e"
#import "stdprocs.e"
#import "wkspace.e"
#require "se/search/ISearchFunctor.e"

namespace se.search;

// find next workspace/project file helper 
class FindNextFile {
   private static int s_project_id = -1;
   private static int s_workspace_id = -1;

   private static _str s_project_last_fileaname = "";
   private static _str s_workspace_last_fileaname = "";

   static void reset()
   {
      s_project_id = -1;
      s_workspace_id = -1;
      s_project_last_fileaname = "";
      s_workspace_last_fileaname = "";
   }

   static void init_workspace_list(_str workspace_name='')
   {
      if (s_workspace_id < 0) {
         int status;
         get_window_id(auto orig_view_id);
         if (s_workspace_id < 0 && workspace_name != '') {
            _create_temp_view(auto temp_view_id);

            _str ProjectFiles[];
            status = _GetWorkspaceFiles(workspace_name, ProjectFiles);
            if (status) {
               _delete_temp_view(temp_view_id); activate_window(orig_view_id);
               return;
            }
            int i;
            workpace_path := _strip_filename(workspace_name,'N');
            for (i = 0; i < ProjectFiles._length(); ++i) {
               files_wid := p_window_id;
               GetProjectFiles(absolute(ProjectFiles[i], workpace_path),temp_view_id,'',null,'',false,true,false);
               bottom();
            }
            _remove_duplicates(_fpos_case,0,-1,false);
            if (s_workspace_last_fileaname :!= '') {
               save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
               top();
               status = search('^'_escape_re_chars(s_project_last_fileaname)'$','rh@');
               if (status) {
                  bottom();
               }
               restore_search(s1, s2, s3, s4, s5);
            } else {
               bottom();
            }
            s_workspace_id = temp_view_id;
         }
         activate_window(orig_view_id);
      }
   }

   static void init_project_list(_str projectName='')
   {
      if (s_project_id < 0) {
         get_window_id(auto orig_view_id);
         if (projectName != '') {
            _create_temp_view(auto temp_view_id);
            GetProjectFiles(projectName,temp_view_id,'',null,'',false,true,false);
            if (s_project_last_fileaname :!= '') {
               save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
               top();
               status := search('^'_escape_re_chars(s_project_last_fileaname)'$','rh@');
               if (status) {
                  bottom();
               }
               restore_search(s1, s2, s3, s4, s5);
            } else {
               bottom();
            }
            s_project_id = temp_view_id;
         }
         activate_window(orig_view_id);
      }
   }

   static void close_workspace_filelist()
   {
      if (s_workspace_id > 0) {
         s_workspace_id.get_line(s_workspace_last_fileaname);
         _delete_temp_view(s_workspace_id,true);
         s_workspace_id = -1;
      }
   }

   static void close_project_filelist()
   {
      if (s_project_id > 0) {
         s_project_id.get_line(s_project_last_fileaname);
         _delete_temp_view(s_project_id,true);
         s_project_id = -1;
      }
   }

   private static _str _get_next_file(int buffer_id, _str cur_filename, bool do_prev = false)
   {
      filename := '';
      if (buffer_id > 0) {
         get_window_id(auto orig_view_id);
         activate_window(buffer_id);
         get_line(auto line);
         if (line :!= cur_filename) {
            if (cur_filename != '') {
               save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
               save_pos(auto p); top();
               status := search('^'_escape_re_chars(cur_filename)'$','rh@');
               if (status) {
                  restore_pos(p);
               }
               restore_search(s1, s2, s3, s4, s5);
            }
         }
         if (do_prev) {
            status := up();
            if (status || p_line == 0) {
               bottom();
            }
         } else {
            if (down()) top();
         }
         get_line(filename);
         activate_window(orig_view_id);
      }
      return filename;
   }

   static _str workspace_get_next_file(_str cur_filename, bool do_prev = false)
   {
      return _get_next_file(s_workspace_id, cur_filename, do_prev);
   }

   static int workspace_get_num_files()
   {
      if (s_workspace_id > 0) {
         return s_workspace_id.p_noflines;
      }
      return 0;
   }

   static _str project_get_next_file(_str cur_filename, bool do_prev = false)
   {
      return _get_next_file(s_project_id, cur_filename, do_prev);
   }

   static int project_get_num_files()
   {
      if (s_project_id > 0) {
         return s_project_id.p_noflines;
      }
      return 0;
   }

   static public void forEachFileList(int list_wid, _str search_string, _str search_options, int search_range, ISearchFunctor& func) {
      get_window_id(auto orig_wid);
      status := 0;
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      activate_window(list_wid);
      top();
      bool file_already_loaded;
      int temp_view_id,orig_view_id;
      for (;;) {
         get_line(auto filename);
         filename = strip(filename, 'b', '"');
         status = _open_temp_view(strip(filename), temp_view_id, orig_view_id, '', file_already_loaded, false, true, 0, false, false);
         if (!status) {
            _updateTextChange();
            top(); up();
            status = search(search_string, '@'search_options'+');
            if (!status) {
               save_pos(auto p);
               buf_id := p_buf_id;
               int edit_status = edit('+q +bi 'buf_id);
               if (!edit_status) {
                  restore_pos(p);
                  result := func.exec(search_string, search_options);
                  if (result) {
                     break;
                  }
               }
            }
            _delete_temp_view(temp_view_id);
         }

         activate_window(list_wid);
         if (down()) {
            break;
         }
      }
      activate_window(orig_wid);
   }

   static void doAllBuffers(_str search_string, _str search_options, ISearchFunctor& func) {
      if (_no_child_windows()) {
         return;
      }

      get_window_id(auto orig_wid);
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      orig_buf_id := p_buf_id;
      first_buf_id := _mdi.p_child.p_buf_id;
      p_buf_id = first_buf_id;
      for (;;) {
         top();
         status := search(search_string, '@'search_options'+');
         if (!status) {
            result := func.exec(search_string, search_options);
            if (result) {
               break;
            }
         }
         _next_buffer('NR');
         if (p_buf_id == first_buf_id) {
            status = STRING_NOT_FOUND_RC;
            break;
         }
      }
      p_buf_id = orig_buf_id;
      activate_window(orig_wid);
   }

   static void doProjectFiles(_str search_string, _str search_options, bool search_workspace, ISearchFunctor& func) {
      if (search_workspace && _workspace_filename == '') {
         return;
      } else if (!search_workspace && _project_name == '') {
         return;
      }

      flush_keyboard();
      get_window_id(auto orig_wid);
      status := 0;
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      num_matches := 0;
      buf_id := 0;
      filename := '';
      if (search_workspace) {
         if (_workspace_filename != '') {
            FindNextFile.init_workspace_list(_workspace_filename);
            filename = FindNextFile.workspace_get_next_file('');
         }
      } else {
         if (_project_name != '') {
            FindNextFile.init_project_list(_project_name);
            filename = FindNextFile.project_get_next_file('');
         }
      }
      if (filename :== '') {
         activate_window(orig_wid);
         return;
      }
      first_filename := filename;
      bool file_already_loaded;
      int temp_view_id,orig_view_id;
      for (;;) {
         status = _open_temp_view(strip(filename), temp_view_id, orig_view_id, '', file_already_loaded, false, true, 0, false, false);
         if (!status) {
            _updateTextChange();
            top(); up();
            status = search(search_string, '@'search_options'+');
            if (!status) {
               save_pos(auto p);
               buf_id = p_buf_id;
               int edit_status = edit('+q +bi 'buf_id);
               if (!edit_status) {
                  restore_pos(p);
                  result := func.exec(search_string, search_options);
                  if (result) {
                     break;
                  }
               }
            }
            _delete_temp_view(temp_view_id);
         }
         if (search_workspace) {
            filename = FindNextFile.workspace_get_next_file(filename);
         } else {
            filename = FindNextFile.project_get_next_file(filename);
         }
         if ((filename :== '') || (filename :== first_filename)) {
            status = FILE_NOT_FOUND_RC;
            break;
         }
      }
      activate_window(orig_wid);
   }

   static void doBuffer(_str search_string, _str search_options, ISearchFunctor& func) {
      save_pos(auto p);
      if (pos('p', search_options, 1, 'I')) {
         top(); up();
      }
      status := search(search_string, '@'search_options'+');
      if (!status) {
         restore_pos(p);
         func.exec(search_string, search_options);
      }
      restore_pos(p);
   }

   static void doSelection(_str search_string, _str search_options, ISearchFunctor& func) {
      save_pos(auto p);
      if (select_active2()) {
         mark_id := _duplicate_selection('');
         if (pos('p', search_options, 1, 'I')) {
            _begin_select(mark_id); _begin_line();
         }
         search_options :+= 'm';
      } else {
         top(); up();
      }
      status := search(search_string, '@'search_options'+');
      if (!status) {
         restore_pos(p);
         func.exec(search_string, search_options);
      }
      restore_pos(p);
   }

   static void doCurrentProc(_str search_string, _str search_options, ISearchFunctor& func) {
      if ((p_lexer_name :== '') || !_in_function_scope()) {
         doBuffer(search_string, search_options, func);
         return;
      }
      save_pos(auto p);
      orig_mark := _duplicate_selection('');
      mark_id := _alloc_selection();
      status := select_proc(0, mark_id, 1);
      if (!status) {
         if (_select_type(mark_id, 'S') == 'C') {
            _select_type(mark_id, 'S', 'E');
         }
         _select_type(mark_id, 'U', 'P');
         restore_pos(p);
         search_options :+= 'm';
         _show_selection(mark_id);
      }
      doSelection(search_string, search_options, func);
      _show_selection(orig_mark);
      if (mark_id) {
         _free_selection(mark_id);
      }
      restore_pos(p);
   }

   static public void forEachRange(_str search_string, _str search_options, int search_range, ISearchFunctor& func) {

      switch (search_range) {
      case VSSEARCHRANGE_CURRENT_BUFFER:
         doBuffer(search_string, search_options, func);
         break;

      case VSSEARCHRANGE_CURRENT_SELECTION:
         doSelection(search_string, search_options, func);
         break;

      case VSSEARCHRANGE_CURRENT_PROC:
         doCurrentProc(search_string, search_options, func);
         break;
            
      case VSSEARCHRANGE_ALL_BUFFERS:
         doAllBuffers(search_string, search_options, func);
         break;

      case VSSEARCHRANGE_PROJECT:
      case VSSEARCHRANGE_WORKSPACE:
         doProjectFiles(search_string, search_options, (search_range == VSSEARCHRANGE_WORKSPACE), func);
         break;
      }
   }
};

namespace default;
using namespace se.search.FindNextFile;

definit() 
{
   FindNextFile.reset();
}

void _exit_se_search_FindNextFile()
{
   FindNextFile.reset();
}

void _prjopen__se_search_FindNextFile(bool singleFileProject)
{
   if (singleFileProject) return;
   FindNextFile.close_project_filelist();
}

void _prjupdate_se_search_FindNextFile()
{
   FindNextFile.close_project_filelist();
   FindNextFile.close_workspace_filelist();
}

void _workspace_opened_se_search_FindNextFile()
{
   FindNextFile.close_project_filelist();
   FindNextFile.close_workspace_filelist();
}

void _wkspace_close_se_search_FindNextFile()
{
   FindNextFile.close_project_filelist();
   FindNextFile.close_workspace_filelist();
}

void _workspace_refresh_se_search_FindNextFile()
{
   FindNextFile.close_project_filelist();
   FindNextFile.close_workspace_filelist();
}

_command void reset_findnextproject() name_info(',')
{
   FindNextFile.reset();
}

