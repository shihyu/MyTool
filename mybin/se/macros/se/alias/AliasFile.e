////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44847 $
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
#require "se/lang/api/LanguageSettings.e"
#import "main.e"
#import "stdprocs.e"
#import "stdcmds.e"
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

   public void create(_str profileName = '') {
      if (m_handle >= 0) {
         close();
      }
      m_handle = _xmlcfg_create('', VSENCODING_UTF8, VSXMLCFG_CREATE_IF_EXISTS_CREATE);
      if (m_handle < 0) {
         return;
      }
      m_profile = _xmlcfg_add(m_handle, TREE_ROOT_INDEX, 'profile', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      if (m_profile > 0 && profileName != '') {
         _xmlcfg_set_attribute(m_handle, m_profile, 'name', profileName);
      }
   }
   
   public int open(_str filename, _str profileName = '') {
      if (m_handle >= 0) {
         close();
      }
      m_handle = _xmlcfg_open(maybe_quote_filename(filename), auto status, VSXMLCFG_OPEN_ADD_ALL_PCDATA, VSENCODING_UTF8);
      if (m_handle < 0) {
         return status;
      }
      loadProfile(profileName);
      return 0;
   }

   public int save(_str filename) {
      if (m_handle < 0) {
         return 0;
      }
      flags := VSXMLCFG_SAVE_ALL_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_PRESERVE_PCDATA_INDENT;
      status := _xmlcfg_save(m_handle, -1, flags, filename, VSENCODING_UTF8);
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

   private int findAlias(_str name, boolean case_insensitive) {
      if (!case_insensitive) {
         return(m_aliases._indexin(name) ? m_aliases:[name] : 0);
      }
      foreach (auto aliasname => auto node in m_aliases) {
         if (strieq(aliasname, name)) {
            return node;
         }
      }
      return 0;
   }

   public void loadProfile(_str profileName) {
      m_aliases._makeempty();
      m_profile = -1;

      typeless profiles[];
      query := (profileName == '') ? "/profile" : "/profile[@name='"profileName"']";
      status := _xmlcfg_find_simple_array(m_handle, query, profiles, TREE_ROOT_INDEX);
      if (status) {
         // create profile
         m_profile = _xmlcfg_add(m_handle, TREE_ROOT_INDEX, 'profile', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         if (profileName != '') {
            _xmlcfg_set_attribute(m_handle, m_profile, 'name', profileName);
         }

      } else if (profiles._length()) {
         foreach (auto node in profiles) {
            typeless props[];
            status = _xmlcfg_find_simple_array(m_handle, 'p', props, node);
            if (!status) {
               foreach (auto index in props) {
                  name := _xmlcfg_get_attribute(m_handle, index, 'n');
                  m_aliases:[name] = index;
               }
            }
            m_profile = node;
         }
      }
   }

   public void listProfiles(_str (&list)[]) {
      typeless profiles[];
      status := _xmlcfg_find_simple_array(m_handle, "/profile", profiles, TREE_ROOT_INDEX);
      if (!status) {
         int names:[];
         foreach (auto node in profiles) {
            profileName := _xmlcfg_get_attribute(m_handle, node, 'name');
            if (!names._indexin(profileName)) {
               list[list._length()] = profileName;
               names:[profileName] = node;
            }
         }
      }
   }

   public void setProfile(_str profileName) {
      if (m_handle < 0 || m_profile < 0) {
         return;
      }
      _xmlcfg_set_attribute(m_handle, m_profile, 'name', profileName);
   }

   void resetProfile(_str profileName) {
      query := (profileName == '') ? "/profile" : "/profile[@name='"profileName"']";
      typeless profiles[];
      status := _xmlcfg_find_simple_array(m_handle, query, profiles, TREE_ROOT_INDEX);
      if (!status) {
         if (profiles._length()) {
            foreach (auto node in profiles) {
               _xmlcfg_delete(m_handle, node);
            }
         }
      }

      m_aliases._makeempty();
      m_profile = _xmlcfg_add(m_handle, TREE_ROOT_INDEX, 'profile', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      if (m_profile > 0 && profileName != '') {
         _xmlcfg_set_attribute(m_handle, m_profile, 'name', profileName);
      }
   }

   public boolean hasAlias(_str name) {
      node := findAlias(name, (def_alias_case == 'i'));
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

   public void insertAlias(_str name, _str value, AliasParam (*params)[] = null) {
      if (m_handle < 0 || m_profile < 0 && name:!='') {
         return;
      }

      aliasname := name;
      index := findAlias(name, false);
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
            _xmlcfg_add(m_handle, node, value, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);
         }
      }
   }

   public void deleteAlias(_str name) {
      node := findAlias(name, false);
      if (node > 0) {
         _xmlcfg_delete(m_handle, node);
         m_aliases._deleteel(name);
      }
   }

   public void deleteAliasParams(_str name) {
      node := findAlias(name, false);
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

   public _str getAlias(_str name, AliasParam (*params)[] = null) {
      _str value = '';
      if (params != null) {
         (*params)._makeempty();
      }
      node := findAlias(name, (def_alias_case == 'i'));
      if (node > 0) {
         index := _xmlcfg_find_simple(m_handle, 'text', node);
         if (index > 0) {
            n := _xmlcfg_get_first_child(m_handle, index, VSXMLCFG_NODE_CDATA|VSXMLCFG_NODE_PCDATA);
            if (n > 0) {
               value = _xmlcfg_get_value_unindent(m_handle, n);
            }
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

   public void getNames(_str (&list)[], _str matchName = '') {
      namelen := length(matchName);
      namecase := def_alias_case:!='e';
      foreach (auto name => auto node in m_aliases) {
         if (namelen) {
            prefix := substr(name, 1, namelen);
            if ((matchName:!=prefix && !(namecase && strieq(matchName, prefix)))) {
               // no match
               continue;
            }
         }
         list[list._length()] = name;
      }
   }

   public void getAliases(_str (&list):[], _str matchName = '') {
      namelen := length(matchName);
      namecase := def_alias_case:!='e';
      foreach (auto name => auto node in m_aliases) {
         if (namelen) {
            prefix := substr(name, 1, namelen);
            if ((matchName:!=prefix) && !(namecase && strieq(matchName, prefix))) {
               // no match
               continue;
            }
         }

         index := _xmlcfg_find_simple(m_handle, 'text', node);
         if (index > 0) {
            n := _xmlcfg_get_first_child(m_handle, index, VSXMLCFG_NODE_CDATA|VSXMLCFG_NODE_PCDATA);
            if (n > 0) {
               list:[name] = _xmlcfg_get_value_unindent(m_handle, n);
            }
         }
      }
   }
};

namespace default;
using namespace se.lang.api;

#define VSOLDCFGFILE_ALIASES "alias.slk"   // old alias
#define VSALIASXMLVERSION "5"

static boolean gAliasCheck = false;

definit()
{
   gAliasCheck = false;
}

static void _se_convert_v17_alias_file(_str aliasfilename, _str newaliasfilename, _str profileName='')
{ 
   orig_view_id := p_window_id;
   temp_view_id := 0;
   int status = _open_temp_view(maybe_quote_filename(aliasfilename), temp_view_id, orig_view_id);
   if (status) {
      p_window_id = orig_view_id;
      return;
   }

   _str line, name, value;
   get_line(line);
   if (pos('<profile', line, 1) == 1) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      if (file_exists(aliasfilename:+'.bak')) {
         //try backup file
         status = _open_temp_view(maybe_quote_filename(aliasfilename:+'.bak'), temp_view_id, orig_view_id);
         if (status) {
            p_window_id = orig_view_id;
            return;
         }

      } else {
         return;
      }
   }

   se.alias.AliasFile aliasfile;
   aliasfile.create(profileName);

   top(); up();
   while (!search('^[~ \t]','Rh@') && !status) {
      get_line(line);
      int p = pos('( |$|\()', line, 1, 'r');
      name = substr(line, 1, p - 1);
      value = substr(line, p);

      AliasParam params[];
      int start_line = p_line;
      int min_col = p + 1;

      if (substr(value, 1, 1) == '(') {
         // parse parameters
         line = substr(value, 2);
         for (;;) {
            _str varble = '';
            _str prompt_string = '';
            _str init_value = '';
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
      aliasfile.insertAlias(name, value, &params);

      if (status) break;
      _begin_line();
   }
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   aliasfile.save(newaliasfilename);
   aliasfile.close();
}

static void _se_duplicate_alias_file(_str oldAliasfilename, _str newAliasfilename, _str newProfileName)
{
   if (file_exists(newAliasfilename)) {
      return;
   }
   se.alias.AliasFile aliasfile;
   aliasfile.open(oldAliasfilename);
   aliasfile.setProfile(newProfileName);
   aliasfile.save(newAliasfilename);
   aliasfile.close();
}

/**
* Convert v17 style alias files to v18 style
*/
static void updateSlickAlias()
{
   if (gAliasCheck) return;
   gAliasCheck = true;

   filename := get_env(_SLICKALIAS);
   if (filename == '') {
      filename = VSOLDCFGFILE_ALIASES;
   }
   if (!pathlen(filename)) {
      filename = usercfg_path_search(filename);
      if (filename == '') {
         filename = _ConfigPath():+VSOLDCFGFILE_ALIASES;
      }
   } else {
      filename = absolute(filename);
   }

   if (filename != '') {
      // convert alias.slk?
      newfilename := '';
      if (_get_extension(filename):== 'slk') {
         newfilename = _strip_filename(filename, 'E'):+'.als.xml';
      }

      if (newfilename != '' && !file_exists(newfilename)) {
         _se_convert_v17_alias_file(filename, newfilename, '');
      }
   }
}

static _str alias_update_langs[] = {
   "c", "cs", "d", "docbook", "e", "html", "java", "js", "m", "pl", "xml",
   "docbook", "markdown"
};

static void removeOldAliasXML()
{
   src_path := _ConfigPath();
   filepath := maybe_quote_filename(src_path'*.xml');
   filename := file_match(filepath, 1); 
   _str files[];
   for (;;) {
      if (filename == '') break;
      if (endsWith(filename, '.als.xml')) {
         files[files._length()] = filename;
      }
      filename = file_match(filepath, 0);
   }

   foreach (filename in files) {
      delete_file(filename);
   }

   int index;
   foreach (auto lang in alias_update_langs) {
      // check if old alias file exists
      if (!file_exists(src_path:+lang:+'.als')) {
         // need to regenerate default aliases
         index = find_index('def-surround-with-version-':+lang, MISC_TYPE);
         if (index) {
            delete_name(index);
         }
      }
   }
}

void updateAliasFiles()
{
   index := find_index('def-aliasfile-version', MISC_TYPE);
   if (index) {
      if (name_info(index) :== VSALIASXMLVERSION) {
         return;
      }
   }
   removeOldAliasXML();

   src_path := _ConfigPath();
   filepath := maybe_quote_filename(src_path'*.als');
   filename := file_match(filepath, 1);
   for (;;) {
      if (filename == '') break;

      extra := '';
      parse _strip_filename(filename, 'P') with auto lang '.als';
      if (endsWith(lang, '_symboltrans')) {
         lang = substr(lang, 1, length(lang)-length('_symboltrans'));
         extra = '/symboltrans';
      }
      profile := getAliasLangProfileName(lang):+extra;
      oldfilename := filename;
      filename = filename:+'.xml';
      if (!file_exists(filename)) {
         _se_convert_v17_alias_file(oldfilename, filename, profile);
      }
      filename = file_match(filepath, 0);
   }

   // special case for cob, duplicate
   filename = file_match(src_path'cob.als.xml', 1);
   if (filename != '') {
      _se_duplicate_alias_file(src_path'cob.als.xml', src_path'cob74.als.xml', getAliasLangProfileName('cob74'));
      _se_duplicate_alias_file(src_path'cob.als.xml', src_path'cob2000.als.xml', getAliasLangProfileName('cob2000'));
   }

   index = name_match("def-alias-", 1, MISC_TYPE);
   for (;;) {
      if (!index) break;
      filename = name_info(index);
      if (filename != "") {
         if (_get_extension(filename) :== 'als') {
            // append .xml to als
            set_name_info(index, filename:+'.xml');
         }
      }
      index = name_match("def-alias-", 0, MISC_TYPE);
   }
   updateSlickAlias();

   index = find_index('def-aliasfile-version', MISC_TYPE);
   if (!index) {
      insert_name('def-aliasfile-version', MISC_TYPE, VSALIASXMLVERSION);
   } else {
      set_name_info(index, VSALIASXMLVERSION);
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

_str seGetSlickEditAliasFile()
{
   aliasFilename := get_env(_SLICKALIAS);
   if (aliasFilename == '') {
      return VSCFGFILE_ALIASES;
   }
   if (_get_extension(aliasFilename):== 'slk') {
      aliasFilename = _strip_filename(aliasFilename, 'E'):+'.als.xml';
   }
   updateSlickAlias();
   return aliasFilename;
}

_str getAliasLangProfileName(_str langID='')
{
   return (langID:=='') ? '' : '/language/':+langID:+'/aliases';
}

