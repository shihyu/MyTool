////////////////////////////////////////////////////////////////////////////////////
// Copyright 2013 SlickEdit Inc.
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
#pragma option(pedantic, on)
#region Imports
#include "slick.sh"
#include "xml.sh"
#include "alias.sh"
#import "se/lang/api/LanguageSettings.e"
#import "main.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "cfg.e"
#import "xmldoc.e"
#endregion

namespace se.alias;

class AliasFile {
   private int m_handle = -1;
   private int m_profile = -1;
   private int m_aliases:[];

   AliasFile() {
   }

   ~AliasFile() {
      close();
   }

   public void create(_str profilePath) {
      if (m_handle >= 0) {
         close();
      }
      filename := "";
      if (!_isAliasProfile(profilePath)) {
         filename=absolute(profilePath);
      }
      m_handle = _xmlcfg_create(filename, VSENCODING_UTF8);
      if (m_handle < 0) {
         return;
      }
      m_profile=initXml(m_handle,profilePath);
   }
   public static int initXml(int handle,_str profilePath,_str version=VSCFGPROFILE_ALIASES_VERSION) {
      int node=_xmlcfg_set_path(handle,"/profile");
      _xmlcfg_delete_attribute(handle,node,'name');
      _xmlcfg_set_attribute(handle,node,VSXMLCFG_PROFILE_NAME,profilePath);
      _xmlcfg_set_attribute(handle,node,VSXMLCFG_PROFILE_VERSION,version);
      return node;
   }
   
   public int open(_str filename) {
      if (m_handle >= 0) {
         close();
      }
      if (_isAliasProfile(filename)) {
         _str package=_plugin_get_profile_package(filename);
         profile := _plugin_get_profile_name(filename);
         m_handle=_plugin_get_profile(package,profile);
      } else {
         m_handle = _xmlcfg_open(_maybe_quote_filename(filename), auto status, VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA, VSENCODING_UTF8);
      }
      if (m_handle < 0) {
         return m_handle;
      }
      loadProfile();
      return 0;
   }

   public int save(_str profilePath) {
      if (m_handle < 0) {
         return 0;
      }
      if (_isAliasProfile(profilePath)) {
         _plugin_set_profile(m_handle);
         return 0;
      }
      flags := VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL;
      status := _xmlcfg_save(m_handle, -1, flags, profilePath, VSENCODING_UTF8);
      return status;
   }

   public void close() {
      if (m_handle >= 0) {
         _xmlcfg_close(m_handle);
         m_handle = -1;
         m_profile = -1;
         m_aliases._makeempty();
      }
   }

   private int findAlias(_str name, bool case_sensitive=def_alias_case:=='e') {
      //return node=_xmlcfg_find_property(m_handle,m_profile,name);
      if (case_sensitive) {
         return(m_aliases._indexin(name) ? m_aliases:[name] : 0);
      }
      matchNode := -1;
      foreach (auto aliasname => auto node in m_aliases) {
         if (aliasname==name) {
            return node;
         }
         if (strieq(aliasname, name)) {
            matchNode=node;
         }
      }
      if (matchNode>=0) {
         return matchNode;
      }
      return 0;
   }

   public void loadProfile() {
      m_aliases._makeempty();
      m_profile = -1;

      typeless profiles[];
      //m_profile := _xmlcfg_set_path(handle,"/profile");
       
      node := _xmlcfg_set_path(m_handle,"/profile");

      typeless props[];
      status := _xmlcfg_find_simple_array(m_handle, 'p', props, node);
      if (!status) {
         foreach (auto index in props) {
            name := _xmlcfg_get_attribute(m_handle, index, 'n');
            m_aliases:[name] = index;
         }
      }
      m_profile = node;
   }

   public int getProfileNode() {
      node := _xmlcfg_find_simple(m_handle, "/profile");
      return node;
   }

   public bool hasAlias(_str name) {
      node := findAlias(name);
      return(node > 0);
   }

   private void addParameter(int node, _str name, _str initial, _str prompt) {
      if (name != '') {
         index := _xmlcfg_add(m_handle, node, 'param', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         if (index > 0) {
            _xmlcfg_set_attribute(m_handle, index, 'n', name);
            _xmlcfg_set_attribute(m_handle, index, 'default', initial);
            _xmlcfg_set_attribute(m_handle, index, 'prompt', prompt);
         }
      }
   }

   public void insertAlias(_str name, _str value, AliasParam (*params)[] = null, bool case_sensitive=def_alias_case:=='e') {
      if (m_handle < 0 || m_profile < 0 && name:!='') {
         return;
      }

      aliasname := name;
      index := findAlias(name,case_sensitive);
      if (index > 0) {
         _xmlcfg_delete(m_handle, index, true);

      } else {
         index = _xmlcfg_add(m_handle, m_profile, 'p', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(m_handle, index, 'n', aliasname);
         m_aliases:[name] = index;
      }

      if (index > 0) {
         if (params != null && (*params)._length()) {
            node := _xmlcfg_add(m_handle, index, 'params', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
            if (node > 0) {
               foreach (auto ap in (*params)) {
                  addParameter(node, ap.name, ap.initial, ap.prompt);
               }
            }
         }

         node := _xmlcfg_add(m_handle, index, 'text', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         if (node > 0) {
            /*
            //IF this is a multi-line alias
            if (pos("\n",value)) {
               value="\n":+value:+"\n";
            } */
            _xmlcfg_add_child_text(m_handle, node, value);
         }
      }
   }

   public void deleteAlias(_str name,bool case_sensitive=def_alias_case:=='e') {
      node := findAlias(name,case_sensitive);
      if (node > 0) {
         _xmlcfg_delete(m_handle, node);
         m_aliases._deleteel(name);
      }
   }

   public void deleteAliasParams(_str name, bool case_sensitive=def_alias_case:=='e') {
      node := findAlias(name,case_sensitive);
      if (node > 0) {
         index := _xmlcfg_find_simple(m_handle, 'params', node);
         if (index > 0) {
            _xmlcfg_delete(m_handle, index);
         }
      }
   }

   public void clearAliases() {
      if (m_handle < 0 || m_profile < 0) {
         return;
      }

      m_aliases._makeempty();
      _xmlcfg_delete(m_handle, m_profile, true);
   }

   public _str getAlias(_str name, AliasParam (*params)[] = null,bool case_sensitive=def_alias_case:=='e') {
      value := "";
      if (params != null) {
         (*params)._makeempty();
      }
      node := findAlias(name,case_sensitive);
      if (node > 0) {
         index := _xmlcfg_find_simple(m_handle, 'text', node);
         if (index > 0) {
            value=_xmlcfg_get_text(m_handle,index);
         }

         if (params != null) {
            index = _xmlcfg_find_simple(m_handle, 'params', node);
            if (index > 0) {
               typeless nodes[];
               status := _xmlcfg_find_simple_array(m_handle, 'param', nodes, index);
               if (!status && nodes._length()) {
                  foreach (auto n in nodes) {
                     AliasParam ap;
                     ap.name = _xmlcfg_get_attribute(m_handle, n, 'n');
                     ap.initial = _xmlcfg_get_attribute(m_handle, n, 'default');
                     ap.prompt = _xmlcfg_get_attribute(m_handle, n, 'prompt');
                     if (ap.name != '') {
                        (*params)[(*params)._length()] = ap;
                     }
                  }
               }
            }
         }
      }
      return value;
   }

   public void getNames(_str (&list)[], _str matchName = '', bool case_sensitive=def_alias_case:=='e') {
      namelen := length(matchName);
      foreach (auto name => auto node in m_aliases) {
         if (namelen) {
            prefix := substr(name, 1, namelen);
            if (matchName:!=prefix && (case_sensitive || !strieq(matchName, prefix))) {
               // no match
               continue;
            }
         }
         list[list._length()] = name;
      }
   }

   public void getAliases(_str (&list):[], _str matchName = '',bool case_sensitive=def_alias_case:=='e') {
      namelen := length(matchName);
      foreach (auto name => auto node in m_aliases) {
         if (namelen) {
            prefix := substr(name, 1, namelen);
            if (matchName:!=prefix && (case_sensitive || !strieq(matchName, prefix))) {
               // no match
               continue;
            }
         }

         index := _xmlcfg_find_simple(m_handle, 'text', node);
         if (index > 0) {
            list:[name]=_xmlcfg_get_text(m_handle,index);
         }
      }
   }
};

namespace default;

static bool gAliasCheck = false;

definit()
{
   gAliasCheck = false;
}

bool _isAliasProfile(_str name) {
   if (endsWith(name, VSCFGFILEEXT_ALIASES) ||
       endsWith(name, '.slk')
       ) {
      return false;
   }
   return true;
}

_str getAliasLangProfileName(_str langID='')
{
   return (langID:=='') ? '' : _plugin_append_profile_name(vsCfgPackage_for_Lang(langID),VSCFGPROFILE_ALIASES);
}

_str alias_path_search(_str name)
{
   if (_isAliasProfile(name)) {
      _str package=_plugin_get_profile_package(name);
      profile := _plugin_get_profile_name(name);
      
      if (_plugin_has_profile(package,profile)) {
         return name;
      }
      return '';
   }
   if (name=='') return('');
   if (pathlen(name)) {
      return(absolute(name));
   }
   local_filename := _ConfigPath():+name;
   if (file_exists(local_filename)) return(local_filename);
   return '';
}
static void old_addParameter(int handle,int node, _str name, _str initial, _str prompt) {
   if (name != '') {
      index := _xmlcfg_add(handle, node, 'param', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      if (index > 0) {
         _xmlcfg_set_attribute(handle, index, 'n', name);
         _xmlcfg_set_attribute(handle, index, 'default', initial);
         _xmlcfg_set_attribute(handle, index, 'prompt', prompt);
      }
   }
}

static void old_insertAlias(int handle,_str name, _str value, AliasParam (*params)[] = null) {
   if (handle < 0 && name:!='') {
      return;
   }
   profile := _xmlcfg_set_path(handle,"/profile");

   aliasname := name;
   index := _xmlcfg_add(handle, profile, 'p', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(handle, index, 'n', aliasname);

   if (index > 0) {
      if (params != null && (*params)._length()) {
         node := _xmlcfg_add(handle, index, 'params', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         if (node > 0) {
            foreach (auto ap in (*params)) {
               old_addParameter(handle,node, ap.name, ap.initial, ap.prompt);
            }
         }
      }

      node := _xmlcfg_add(handle, index, 'text', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      if (node > 0) {
         _xmlcfg_add_child_text(handle, node, value);
      }
   }
}

void _se_convert_v17_als_to_als_xml_file(_str aliasfilename, _str newaliasfilename, _str profileName='')
{ 
   orig_view_id := p_window_id;
   temp_view_id := 0;
   int status = _open_temp_view(aliasfilename, temp_view_id, orig_view_id);
   if (status) {
      p_window_id = orig_view_id;
      return;
   }

   _str line, name, value;
   get_line(line);
   if (pos('<profile', line, 1) == 1) {
      // Don't know what's going on here
      return;
   }

   handle := _xmlcfg_create(newaliasfilename, VSENCODING_UTF8);
   int node=_xmlcfg_set_path(handle,"/profile");

   top(); up();
   while (!search('^[~ \t]','Rh@') && !status) {
      get_line(line);
      int p = pos('( |$|\()', line, 1, 'r');
      name = substr(line, 1, p - 1);
      value = substr(line, p);

      AliasParam params[];
      start_line := p_line;
      int min_col = p + 1;

      if (substr(value, 1, 1) == '(') {
         // parse parameters
         line = substr(value, 2);
         for (;;) {
            varble := "";
            prompt_string := "";
            init_value := "";
            strip(line, 'L');
            parse line with varble '"' prompt_string '"' +0 init_value;

            init_value = substr(init_value,3);      /* init_value starts out with
                                                     * the last " from the prompt-
                                                     * string in position 1
                                                     * This is done to preserve leading
                                                     * spaces after the first space
                                                     */
            if (varble == ')') {
               break;
            }

            AliasParam ap;
            ap.name = strip(varble);
            ap.initial = strip(init_value);
            ap.prompt = strip(prompt_string);
            params[params._length()] = ap;

            if (down()) break;
            get_line(line);
         }

         if (!down()) {
            get_line(line);
            value = line;
         } else {
            value = '';
         }
         start_line = p_line;
         min_col = _first_non_blank_col();
      }

      if (value == '') {
         if (down()) break;
         continue;
      }
      for (;;) {
         status = down();
         if (status) break;
         get_line(line);
         if (substr(line, 1, 1) != ' ') break;
         col := _first_non_blank_col(min_col);
         if (col < min_col) min_col = col;
      }
      p_line = start_line;
      if (min_col == MAXINT) {
         min_col = 2;
      }
      for (;;) {
         status = down();
         if (status) break;
         get_line(line);
         if (substr(line, 1, 1) != ' ') break;

         strappend(value, "\n":+substr(line, _text_colc(min_col,'p')));
      }
      old_insertAlias(handle,name, value, &params);

      if (status) break;
      _begin_line();
   }
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   //aliasfile.save(newaliasfilename);
   flags := VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_REINDENT_PCDATA_RELATIVE;
   _xmlcfg_save(handle, -1, flags, newaliasfilename, VSENCODING_UTF8);

   
   _xmlcfg_close(handle);
}
void _convert_alias_text_to_v21_text(int handle) {
   typeless array[];
   _xmlcfg_find_simple_array(handle,"/profile/p/text",array);
   for (i:=0;i<array._length();++i) {
      node:=array[i];
      node = _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_CDATA|VSXMLCFG_NODE_PCDATA);
      if (node > 0) {
         value := _xmlcfg_get_value_unindent(handle, node);
         node=array[i];
         _xmlcfg_delete(handle,node,true);
         _xmlcfg_add_child_text(handle,node,value);
      }
   }
}
