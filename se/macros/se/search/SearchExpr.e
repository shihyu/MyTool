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
#include "treeview.sh"
#include "xml.sh"
#import "listbox.e"
#import "main.e"
#import "search.e"
#import "sellist.e"
#import "seltree.e"
#import "cfg.e"

namespace se.search;

namespace default;

static int s_saved_searches_handle;

struct SearchExprOptions {
   _str     m_search_string;
   _str     m_replace_string;
   bool     m_replace_mode;
   int      m_search_flags;
   _str     m_colors;
   _str     m_misc_options;
   bool     m_multifile;
   _str     m_files;
   _str     m_file_types;
   _str     m_file_excludes;
   int      m_sub_folders;
   int      m_file_stats_enabled;
   _str     m_file_stats;

   int      m_grep_id;
   int      m_mfflags;
};

definit()
{
   s_saved_searches_handle = -1;
}
static void _read_hash_position_info(int (&hash_position):[],int &largest_position=0, int (&hash_name2node):[]=null) {

   hash_name2node._makeempty();
   handle:=s_saved_searches_handle;
   hash_position._makeempty();
   int profile_node=_xmlcfg_get_document_element(handle);

   largest_position=0;
   property_node:=_xmlcfg_get_first_child(handle,profile_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   while (property_node>=0) {
      if (_xmlcfg_get_name(handle,property_node)!=VSXMLCFG_PROPERTY) {
         property_node=_xmlcfg_get_next_sibling(handle,property_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         continue;
      }
      _str name=_xmlcfg_get_attribute(handle,property_node, VSXMLCFG_PROPERTY_NAME);
      position:= _xmlcfg_get_attribute(handle, property_node, "position");
      if (isinteger(position)) {
         if (position>largest_position) {
            largest_position=position;
         }
         hash_position:[name]=position;
      }

      hash_name2node:[name]=property_node;
      property_node=_xmlcfg_get_next_sibling(handle,property_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }
}

static int _open_saved_search_index()
{
   if (s_saved_searches_handle < 0) {
      int handle=_plugin_get_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_SEARCHES);
      int profile_node;
      if (handle<0) {
         handle=_xmlcfg_create_profile(profile_node,VSCFGPACKAGE_MISC,VSCFGPROFILE_SEARCHES,VSCFGPROFILE_SEARCHES_VERSION);
      }
      profile_node=_xmlcfg_get_document_element(handle);
      if (profile_node<0) {
         _xmlcfg_close(handle);
         handle=_xmlcfg_create_profile(profile_node,VSCFGPACKAGE_MISC,VSCFGPROFILE_SEARCHES,VSCFGPROFILE_SEARCHES_VERSION);
      }
      // Check if the first property defines a position attribute
      s_saved_searches_handle = handle;
      first:=_xmlcfg_find_simple(handle, '/profile/p');
      if (first>=0) {
         _xmlcfg_get_attribute(handle,first,'position');
         int hash_position:[];
         _read_hash_position_info(hash_position);
         // The converted searches.xml doesn't have the position attribute.
         // Add the position attribute now.
         if (hash_position._isempty()) {
            int array[];
            _xmlcfg_list_properties(array,handle,profile_node);
            for (i:=0;i<array._length();++i) {
               _xmlcfg_set_attribute(handle,array[i],'position',i+1);
            }
         }
      }


      _xmlcfg_sort_on_attribute(handle,profile_node,"position",'n');

      _xmlcfg_set_modify(handle,0);
   }
   return (s_saved_searches_handle);
}

static void _close_saved_search_index(bool save_modified=true)
{
   if (s_saved_searches_handle < 0) {
      return;
   }
   if (save_modified &&_xmlcfg_get_modify(s_saved_searches_handle)) {
      _plugin_set_profile(s_saved_searches_handle);
   }
   _xmlcfg_close(s_saved_searches_handle);
   s_saved_searches_handle = -1;
}

static int _find_saved_search(_str name)
{
   handle := _open_saved_search_index();
   if (handle < 0) {
      return (-1);
   }
   return _xmlcfg_find_simple(handle, '/profile/p[@n="' :+ (name) :+ '"]', TREE_ROOT_INDEX);
}

void _write_saved_search(_str name, SearchExprOptions& expr)
{
   handle := _open_saved_search_index();
   if (handle < 0) {
      return;
   }
   int hash_position:[];
   int largest_position;
   _read_hash_position_info(hash_position,largest_position);
   int parent_node = _xmlcfg_find_simple(handle, '/profile', TREE_ROOT_INDEX);
   int node = _xmlcfg_add(handle, parent_node, VSXMLCFG_PROPERTY, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   if (node > 0) {
      _xmlcfg_add_attribute(handle, node, VSXMLCFG_PROPERTY_NAME, name);
      _xmlcfg_add_attribute(handle, node, "Search", expr.m_search_string);
      if (expr.m_replace_mode || expr.m_replace_string != '') {
         _xmlcfg_add_attribute(handle, node, "Replace", expr.m_replace_string);
      }
      _xmlcfg_add_attribute(handle, node, "ReplaceMode", expr.m_replace_mode);
      _xmlcfg_add_attribute(handle, node, "Flags", expr.m_search_flags);
      if (expr.m_colors != '') {
         _xmlcfg_add_attribute(handle, node, "Colors", expr.m_colors);
      }
      if (expr.m_misc_options != '') {
         _xmlcfg_add_attribute(handle, node, "OtherOpts", expr.m_misc_options);
      }
      if (expr.m_multifile) {
         int file_node = _xmlcfg_add(handle, node, "Files", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
         if (file_node > 0) {
            _xmlcfg_add_attribute(handle, file_node, "Path", expr.m_files);
            _xmlcfg_add_attribute(handle, file_node, "Types", expr.m_file_types);
            if (expr.m_file_excludes != '') {
               _xmlcfg_add_attribute(handle, file_node, "Excludes", expr.m_file_excludes);
            }
            _xmlcfg_add_attribute(handle, file_node, "SubFolders", expr.m_sub_folders);
            _xmlcfg_add_attribute(handle, file_node, "FileStatsEnabled", expr.m_file_stats_enabled);
            if (expr.m_file_stats != '') {
               _xmlcfg_add_attribute(handle, file_node, "FileStats", expr.m_file_stats);
            }
         }
      } else {
         _xmlcfg_add_attribute(handle, node, "Buffers", expr.m_files);
      }
      _xmlcfg_add_attribute(handle, node, "GrepID", expr.m_grep_id);
      _xmlcfg_add_attribute(handle, node, "MFFlags", expr.m_mfflags);

      _xmlcfg_add_attribute(handle,node,"position",largest_position+1);
   }
   _close_saved_search_index();
}

void _read_saved_search(int node, _str& name, SearchExprOptions& expr)
{
   handle := _open_saved_search_index();
   if (handle < 0) {
      return;
   }
   name = _xmlcfg_get_attribute(handle, node, VSXMLCFG_PROPERTY_NAME, 0);
   expr.m_search_string = _xmlcfg_get_attribute(handle, node, "Search", '');
   expr.m_replace_string = _xmlcfg_get_attribute(handle, node, "Replace", '');
   expr.m_replace_mode = _xmlcfg_get_attribute(handle, node, "ReplaceMode", 0);
   expr.m_search_flags = _xmlcfg_get_attribute(handle, node, "Flags", 0);
   expr.m_colors = _xmlcfg_get_attribute(handle, node, "Colors", '');
   expr.m_misc_options = _xmlcfg_get_attribute(handle, node, "OtherOpts", '');
   int file_node = _xmlcfg_find_child_with_name(handle, node, "Files");
   if (file_node < 0) {
      expr.m_multifile = false;
      expr.m_files = _xmlcfg_get_attribute(handle, node, "Buffers");
      expr.m_file_types = "";
      expr.m_file_excludes = "";
      expr.m_sub_folders = 0;
      expr.m_file_stats_enabled = 0;
      expr.m_file_stats = "";
   } else {
      expr.m_multifile = true;
      expr.m_files = _xmlcfg_get_attribute(handle, file_node, "Path");
      expr.m_file_types = _xmlcfg_get_attribute(handle, file_node, "Types");
      expr.m_file_excludes = _xmlcfg_get_attribute(handle, file_node, "Excludes");
      expr.m_sub_folders = _xmlcfg_get_attribute(handle, file_node, "SubFolders");
      expr.m_file_stats_enabled = _xmlcfg_get_attribute(handle, file_node, "FileStatsEnabled");
      expr.m_file_stats = _xmlcfg_get_attribute(handle, file_node, "FileStats");
   }

   expr.m_grep_id = _xmlcfg_get_attribute(handle, node, "GrepID", -1);
   expr.m_mfflags = _xmlcfg_get_attribute(handle, node, "MFFlags", 0);
}

void _update_saved_search_names(_str (&array)[])
{
   handle := _open_saved_search_index();
   if (handle < 0) {
      return;
   }
   int hash_name2node:[];
   int hash_position:[];
   _read_hash_position_info(hash_position,auto largest_position,hash_name2node);

   //int handle=_xmlcfg_create_profile(auto profile_node,VSCFGPACKAGE_MISC,VSCFGPROFILE_SEARCHES,VSCFGPROFILE_SEARCHES_VERSION);
   last_position := 0;

   for (i:=0;i<array._length();++i) {
      _str name=array[i];
      int *pnode=hash_name2node._indexin(name);
      if (hash_name2node._indexin(name)) {
         int node=*pnode;
         _plugin_next_position(name,last_position,hash_position);
         _xmlcfg_set_attribute(handle,node,'position',last_position);
         hash_name2node._deleteel(name);
      }
   }
   foreach (auto name=>auto node in hash_name2node) {
      _xmlcfg_delete(handle,node);
   }
   int profile_node=_xmlcfg_get_document_element(handle);
   _xmlcfg_sort_on_attribute(handle,profile_node,"position",'n');

   _plugin_set_profile(handle);
   //_xmlcfg_close(handle);
}
int _retrieve_saved_search(_str name, SearchExprOptions& expr)
{
   handle := _open_saved_search_index();
   if (handle < 0) {
      return FILE_NOT_FOUND_RC;
   }
   int node = _find_saved_search(name);
   if (node < 0) {
      return FILE_NOT_FOUND_RC;
   }

   expr.m_search_string = _xmlcfg_get_attribute(handle, node, "Search", '');
   expr.m_replace_string = _xmlcfg_get_attribute(handle, node, "Replace", '');
   expr.m_replace_mode = _xmlcfg_get_attribute(handle, node, "ReplaceMode", 0);
   expr.m_search_flags = _xmlcfg_get_attribute(handle, node, "Flags", 0);
   expr.m_colors = _xmlcfg_get_attribute(handle, node, "Colors");
   expr.m_misc_options = _xmlcfg_get_attribute(handle, node, "OtherOpts", '');
   int file_node = _xmlcfg_find_child_with_name(handle, node, "Files");
   if (file_node < 0) {
      expr.m_multifile = false;
      expr.m_files = _xmlcfg_get_attribute(handle, node, "Buffers");
      expr.m_file_types = "";
      expr.m_file_excludes = "";
      expr.m_sub_folders = 0;
      expr.m_file_stats_enabled = 0;
      expr.m_file_stats = "";
   } else {
      expr.m_multifile = true;
      expr.m_files = _xmlcfg_get_attribute(handle, file_node, "Path");
      expr.m_file_types = _xmlcfg_get_attribute(handle, file_node, "Types");
      expr.m_file_excludes = _xmlcfg_get_attribute(handle, file_node, "Excludes");
      expr.m_sub_folders = _xmlcfg_get_attribute(handle, file_node, "SubFolders", -1);
      expr.m_file_stats_enabled = _xmlcfg_get_attribute(handle, file_node, "FileStatsEnabled", -1);
      expr.m_file_stats = _xmlcfg_get_attribute(handle, file_node, "FileStats");
   }

   expr.m_grep_id = _xmlcfg_get_attribute(handle, node, "GrepID", -1);
   expr.m_mfflags = _xmlcfg_get_attribute(handle, node, "MFFlags", 0);
   return 0;
}


void _delete_saved_search(_str name)
{
   handle := _open_saved_search_index();
   if (handle < 0) {
      return;
   }
   int node = _find_saved_search(name);
   if (node > 0) {
      _xmlcfg_delete(handle, node);
   }
}

void _get_saved_search_names(_str (&array)[], bool needs_replace = false, bool needs_files = false)
{
   handle := _open_saved_search_index();
   if (handle < 0) {
      return;
   }
   int i;
   typeless nodes[];
   _xmlcfg_find_simple_array(handle, '/profile/p', nodes);
   for (i = 0; i < nodes._length(); ++i) {
      int node = nodes[i];
      if (needs_replace && (_xmlcfg_get_attribute(handle, node, "Replace", 0) :== "")) {
         continue;
      }
      if (needs_files && (_xmlcfg_find_child_with_name(handle, node, "Files") < 0)) {
         continue;
      }
      name:=_xmlcfg_get_attribute(handle, node, VSXMLCFG_PROPERTY_NAME);
      if (name!='') {
         array[array._length()] = _xmlcfg_get_attribute(handle, node, VSXMLCFG_PROPERTY_NAME, 0);
      }
   }
}

int _get_saved_search_count()
{
   handle := _open_saved_search_index();
   if (handle < 0) {
      return (0);
   }
   typeless nodes[];
   _xmlcfg_find_simple_array(handle, '/profile/p', nodes);
   return (nodes._length());
}

defeventtab search_remove_expression_callback;

void ctl_delete.lbutton_up()
{
   int del_indexes[]=null;
   int index, info;
   for (ff:=1;;ff=0) {
      index = ctl_tree._TreeGetNextSelectedIndex(ff, info);
      if (index < 0){
         break;
      }
      caption := ctl_tree._TreeGetCaption(index);
      _delete_saved_search(caption);
      del_indexes[del_indexes._length()]=index;
   }

   len := del_indexes._length();
   int i;
   for (i = 0; i < len; ++i) {
      ctl_tree._TreeDelete(del_indexes[i]);
   }
}

static _str _remove_saved_search_cb(int reason, typeless user_data, typeless info=null)
{
   switch (reason) {
   case SL_ONDEFAULT:
      break;
   case SL_ONINIT:
      break;
   case SL_ONINITFIRST:
      ctl_delete.p_eventtab = defeventtab search_remove_expression_callback.ctl_delete;
      break;
   case SL_ONRESIZE:
      break;
   case SL_ONSELECT:
      break;
   case SL_ONCLOSE:
      break;
   }
   return '';
}

void _remove_saved_search()
{
   _str array[];
   _get_saved_search_names(array);

   int flags = SL_DESELECTALL |
               SL_SELECTALL |
               SL_ALLOWMULTISELECT |
               SL_DELETEBUTTON;

   _str result = select_tree(array, null, null, null, null, _remove_saved_search_cb, null,
                             "Remove Search Expression",
                             flags);
   save_modified := (result != COMMAND_CANCELLED_RC);
   _close_saved_search_index(save_modified);
}

void _save_search_expression(SearchExprOptions expr)
{
   typeless result = show('-modal _textbox_form',
                          "New Saved Search Expression Name",   // Form caption
                          0,  //flags
                          "", //use default textbox width
                          "", //Help item.
                          "", //Buttons and captions
                          "", //Retrieve Name
                          'New Saved Search Expression Name:'expr.m_search_string);
   if (result == "") {
      return;
   }

   _str array[];
   _get_saved_search_names(array);
   len := array._length();
   int n;
   for (n = 0; n < len; ++n) {
      if (_param1 == array[n]) {
         break;
      }
   }
   if (n < len) {
      result = _message_box(nls("Saved Search name already exists.  Would you like to replace it?"), '', MB_YESNO|MB_ICONQUESTION);
      if (result == IDNO) {
         return;
      }
      if (result == IDYES) {
         _delete_saved_search(_param1);
      }
   }
   _write_saved_search(_param1, expr);
}

static _str _list_saved_searches_callback(int reason, var result, typeless key)
{
   _nocheck _control _sellist;
   if (reason == SL_ONDEFAULT) {
      result = _sellist.p_line - 1; // just want the line/index number
      return (1);
   }
   return ('');
}

static _str _list_saved_searches(bool needs_replace, bool needs_files)
{
   _str array[];
   _get_saved_search_names(array, needs_replace, needs_files);
   if (array._length() == 0) {
      return ('');
   }

   int flags = SL_SELECTCLINE;
   _str result = select_tree(array, null, null, null, null, null, null,
                             "Saved Search Expressions",
                             SL_SELECTCLINE);
   if (result == COMMAND_CANCELLED_RC || result == '') {
      return ('');
   }
   return (result);
}

/**
 * Search for text in buffer using search string and search
 * options stored from an entry in the saved search expressions
 * list.
 *
 * @param name Saved search expression name.  If no name is
 *             passed in, a selection list is displayed to pick
 *             from the list of saved expressions.
 * @see find
 * @appliesTo Edit_Window, Editor_Control @categories
 * Search_Functions
 */
_command void find_search_expression(_str name = '') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (_get_saved_search_count() == 0) {
      message("No saved searches.");
      return;
   }
   int node;
   if (name :== "") {
      name = _list_saved_searches(false, false);
      if (name :== "") {
         return;
      }
   }
   SearchExprOptions expr;
   status := _retrieve_saved_search(name, expr);
   if (status) {
      message("Search expression '":+name:+" not found");
      return;
   }
   find(expr.m_search_string, make_search_options(expr.m_search_flags):+expr.m_colors);
}

/**
 * Replace text in buffer using search string, replace string,
 * and search options stored from an entry in the saved search
 * expressions list.
 *
 * @param name Saved search expression name.  If no name is
 *             passed in, a selection list is displayed to pick
 *             from the list of saved expressions.
 * @param go   Replace all without prompt.
 * @see find
 * @appliesTo Edit_Window, Editor_Control @categories
 * Search_Functions
 */
_command void replace_search_expression(_str name = '', bool go = false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (_get_saved_search_count() == 0) {
      message("No saved searches.");
      return;
   }
   int node;
   if (name :== "") {
      name = _list_saved_searches(true, false);
      if (name :== "") {
         return;
      }
   } 

   SearchExprOptions expr;
   status := _retrieve_saved_search(name, expr);
   if (status) {
      message("Search expression '":+name:+" not found");
      return;
   }
   replace(expr.m_search_string, expr.m_replace_string, make_search_options(expr.m_search_flags):+expr.m_colors);
}

_command void replace_all_search_expression(_str name = '') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   replace_search_expression(name, true);
}
