////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50200 $
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
#include "alias.sh"
#require "se/lang/api/LanguageSettings.e"
#require "se/alias/AliasFile.e"
#import "commentformat.e"
#import "files.e"
#import "listbox.e"
#import "main.e"
#import "mprompt.e"
#import "optionsxml.e"
#import "picture.e"
#import "savecfg.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "xmlwrap.e"
#import "xmlwrapgui.e"
#endregion

using se.lang.api.LanguageSettings;
using se.alias.AliasFile;

//DIALOG BOX MAY BE SHOWN MODELESSLY

/*
p_user's:

   ALIAS_TABLE - _ctlae_ok.p_user - is the hash table that holds the aliases.  Every function that
                needs it saves and restores it.

   LAST_EDITED_ALIAS - _ctlae_alias_list.p_user - This is the last alias that was edited.  It is
                              saved so that before we fill in the alias selected
                              in the alias list box, we can save the last one
                              that was edited.

   ALIAS_MODIFIED - _ctlae_edit_window.p_user - Modify flag.
   ALIAS_PARAMS_MODIFIED - _ctlae_param_tree.p_user  - alias parameters modified
   ALIAS_FILE_TYPE - ctlAliasEscapeSeqButton.p_user - alias file type
*/
#define ORIG_FILENAME            _ctlae_param_add.p_user
#define ALIAS_TABLE              _ctlae_ok.p_user
#define ALIAS_MODIFIED           _ctlae_edit_window.p_user
#define LAST_EDITED_ALIAS        _ctlae_alias_list.p_user
#define ALIAS_FILE_TYPE          ctlAliasEscapeSeqButton.p_user
#define ALIAS_LANGUAGE           ctl_escapeSeq_label.p_user
#define ALIAS_PARAMS_MODIFIED    _ctlae_param_tree.p_user

#define ALIAS_PIC_INDEX                   _ctl_filename.p_user
#define SURROUND_WITH_ALIAS_PIC_INDEX     _ctlae_param_labelt.p_user
/*
#define ORIG_EXPAND_VALUE        _ctl_expand_on_space.p_user
*/

#define SURROUND_PREFIX '=surround_with_'
struct ALIAS_TYPE {
   _str value[];
   AliasParam params[];
};

/**
 * Retrieves the filename where language-specific aliases are kept for the given 
 * language.  Does not include the path, as file is assumed to be in the user's 
 * config dir. 
 * 
 * @param langID        language ID of language to fetch alias file name for`
 * @param create        whether to create a new entry if one 
 *                      does not exist
 * 
 * @return              file name
 */
_str getAliasFileNameForLang(_str langID, boolean createEntry = true)
{
   aliasFilename := LanguageSettings.getAliasFilename(langID);
   if (aliasFilename == '' && createEntry && langID!="") {
      aliasFilename = langID'.als.xml';
      LanguageSettings.setAliasFilename(langID, aliasFilename);
   }

   return aliasFilename;
}

defeventtab _alias_editor_form;

#region Options Dialog Helper Functions

void _alias_editor_form_init_for_options(_str options = '')
{  
   _str a[];
   _str langID = '', surround = '', initialAliasName = '';
   split(options, ' ', a);
   switch (a._length()) {
   case 3:
      initialAliasName = a[2];
   case 2:
      surround = a[1];
   case 1:
      langID = a[0];
      break;
   }

   aliasFilename := getAliasFilename(langID);
   _SetDialogInfoHt('aliasFilename', aliasFilename);

   initAliasEditor(aliasFilename, surround, initialAliasName, REGULAR_ALIAS_FILE, langID);
   _ctl_filename.p_visible = true;
   _ctl_filename.p_caption = "Alias file:  "aliasFilename;

   _ctlae_ok.p_visible = false;
   _ctlae_cancel.p_visible = false;
   _ctlae_help.p_visible = false;

   _set_language_form_lang_id(langID);
}

boolean _alias_editor_form_is_modified()
{
   return (ALIAS_MODIFIED != 0 || _ctlae_edit_window.p_modify || ALIAS_PARAMS_MODIFIED);
}

boolean _alias_editor_form_apply()
{
   status := 0;

   if (ALIAS_MODIFIED != 0 || _ctlae_edit_window.p_modify || ALIAS_PARAMS_MODIFIED) {
   
      ALIAS_TYPE alias_table:[];
      status=_ctlae_alias_list.call_event(CHANGE_OTHER,1,_ctlae_alias_list,ON_CHANGE,'');
      if (status) {
         return (status == 0);
      }
   
      ALIAS_MODIFIED=0;
      ALIAS_PARAMS_MODIFIED=0;
      _ctlae_edit_window.p_modify = 0;
   
      alias_table=ALIAS_TABLE;
   
      if ( ALIAS_FILE_TYPE == SYMTRANS_ALIAS_FILE) {
         _str ST_symbols[];
         typeless name;
         for (name._makeempty();;) {
            alias_table._nextel(name);
            if (name._isempty()) break;
            ST_symbols[ST_symbols._length()] = name;
         }
         //save the possible expansions.
         ST_storeSymbols(ALIAS_LANGUAGE, ST_symbols);
      }
   
      _str aliasfilename=ORIG_FILENAME;
      aliasfilename=usercfg_init_write(aliasfilename);

      profileName := getAliasLangProfileName(ALIAS_LANGUAGE);
      if (ALIAS_FILE_TYPE == SYMTRANS_ALIAS_FILE) {
         profileName :+='/symboltrans';
      }
      status=write_alias_file(aliasfilename,alias_table,profileName);
   }

   return (status == 0);
}

_str _alias_editor_form_export_settings(_str &file, _str &importArgs, _str langID = '')
{
   error := '';
   
   // get the alias file for this language and lack thereof
   aliasFile := getAliasFilename(langID, false);

   // is this a whole path or just a file name?
   if (aliasFile != '') {
      if (!pathlen(aliasFile)) {
         // get the file, probably in the config dir
         aliasFile = usercfg_path_search(aliasFile);
      } else {
         // this a path to somewheres
         aliasFile = absolute(aliasFile);
      }
   }

   // make sure we have a path here
   if (aliasFile != '' && (file_exists(aliasFile))) {
      // rip out just the file name
      justFile := _strip_filename(aliasFile, 'P');
      if (copy_file(aliasFile, file :+ justFile)) {
         if (langID != '') {
            error = 'Error copying alias file for '_LangId2Modename(langID)', 'aliasFile'.';
         } else {
            error = 'Error copying global alias file, 'aliasFile'.';
         }
      }
      file = justFile;
   }

   // save some values for our import args
   if (langID != '') {
      importArgs = 'expand='LanguageSettings.getExpandAliasOnSpace(langID);
   } 
   
   return error;
}

_str _alias_editor_form_import_settings(_str file, _str importArgs, _str langID = '')
{
   error := '';
   status := 0;

   if (file != '') {
      // get the filename for this alias
      curFile := getAliasFilename(langID);
   
      // is this a whole path or just a file name?
      if (!pathlen(curFile)) {
         // get the file, probably in the config dir
         curFile = usercfg_init_write(curFile);
      } else {
         // this a path to somewheres
         curFile = absolute(curFile);
      }
      if (curFile == '') curFile = _ConfigPath() :+ getAliasFilename(langID);
   
   
      if (file_exists(curFile)) {
         // we append to the original file, rather than replace it
         status = mergeAliasFiles(curFile, file, langID);
      } else {
         // easy!  we just copy
         status = copy_file(file, curFile);
      }
   }

   if (langID != '') {
      parse importArgs with 'expand=' auto expandValue;
      LanguageSettings.setExpandAliasOnSpace(langID, ((int)expandValue) != 0);
   }

   if (status) {
      if (langID != '') {
         error = 'Error copying aliases from alias file for '_LangId2Modename(langID)', 'file'.';
      } else {
         error = 'Error copying aliases from global alias file, 'file'.';
      }
   }

   return error;
}

static _str getAliasFilename(_str langID, boolean createEntry = true)
{
   // if we have a language, load the alias file for that language
   aliasFilename := '';
   if (langID != '') {
      aliasFilename = getAliasFileNameForLang(langID, createEntry);

   } else {
      // here we use the directory aliases file
      aliasFilename = seGetSlickEditAliasFile();
   }

   return aliasFilename;
}

/**
 * Combines the aliases in two files into one file.  The merged 
 * file is saved in the same path as the first file.  If there 
 * are any aliases which have the same name in both files, 
 * aliases in file2 are given precedence. 
 * 
 * @param file1            first file to merge, path where the 
 *                         merged file is saved
 * @param file2            second file to merge, any aliases 
 *                         named in this file have precedence
 *                         over same named aliases in file1
 */
static int mergeAliasFiles(_str file1, _str file2, _str profileName)
{
   ALIAS_TYPE aliasTable:[];

   status := 0;
   do {

      // read the first file
      status = load_alias_file(file1, profileName, aliasTable);
      if (status) break;
   
      // read the second file - stuff will be overwritten
      status = load_alias_file(file2, profileName, aliasTable, true);
      if (status) break;
   
      // write everything out to the first path
      status = write_alias_file(file1, aliasTable, profileName);

   } while (false);

   return status;
}

/**
 * 
 * Test to see if the symbol translation data for this lang type is 
 * loaded.  If not, cache the data from the symbol translation alias 
 * files to optimize the lookup. 
 */
void _buffer_add_loadSymbolTransData() {
   if (ST_needToLoadSymbols()) {
      _str aliasfilename = getSymbolTransaliasFile(p_LangId);
      if (aliasfilename=='') {
         return;
      }
      profileName := getAliasLangProfileName(p_LangId):+'/symboltrans';
      
      _str ST_symbols[];
      AliasFile aliasFile;
      status := aliasFile.open(aliasfilename, profileName);
      if (status < 0) return;
      aliasFile.getNames(ST_symbols);
      aliasFile.close();
     
      //save the possible expansions.
      ST_storeSymbols(p_LangId, ST_symbols);
   }
   return;
}

#endregion Options Dialog Helper Functions

_command void aliasEscapeSeqInsert(_str seq = '') { 
   _ctlae_edit_window._insert_text(seq);
}
_command void aliasEscapeSeqInsertAndBackspace(_str seq = '') { 
   _ctlae_edit_window._insert_text(seq);
   _ctlae_edit_window.p_col -= 1;
}

static boolean parametersAvailable()
{
   return (ALIAS_FILE_TYPE != SYMTRANS_ALIAS_FILE);
}

/**
 * Determines if "surround-with" aliases are available on the 
 * current alias options form. 
 * 
 * @return boolean
 */
static boolean surroundWithAvailable()
{
   return (ALIAS_FILE_TYPE != DOCCOMMENT_ALIAS_FILE && ALIAS_FILE_TYPE != SYMTRANS_ALIAS_FILE);
}

/**
 * Determines if the currently selected alias is a surround-with 
 * alias. 
 * 
 * @return boolean 
 */
static boolean isCurrentAliasSurroundWith()
{
   _ctlae_alias_list._lbget_item(auto t, auto t2, auto pic);
   return (pic == SURROUND_WITH_ALIAS_PIC_INDEX);
}

/**
 * Returns the appropriate picture index to use with the given 
 * alias. 
 * 
 * @return int 
 */
static void getAliasComboTextAndPicIndex(_str &aliasName, int &picIndex)
{
   // do we allow surround with?
   if (!surroundWithAvailable()) {
      // if not, then we don't need the pictures to differentiate in the list
      picIndex = 0;
   } else {
      // is this a surround with alias?
      prefixLength := length(SURROUND_PREFIX);
      isSurround := (substr(aliasName, 1, prefixLength) == SURROUND_PREFIX);
      if (isSurround) {
         aliasName = substr(aliasName, prefixLength + 1);
         picIndex = SURROUND_WITH_ALIAS_PIC_INDEX;
      } else {
         picIndex = ALIAS_PIC_INDEX;
      }
   }
}

initAliasEditor(_str aliasfilename='', 
                _str editSurroundAliases='', 
                _str initialAliasName='',
                int aliasFileType=REGULAR_ALIAS_FILE,
                _str lang='')
{
   if (lang != '') update_lang_surround_definitions(lang);

   ALIAS_FILE_TYPE = aliasFileType;
   ALIAS_LANGUAGE = lang;
   if (aliasFileType == DOCCOMMENT_ALIAS_FILE) {
      _ctlae_new.p_visible = false;
      _ctlae_delete.p_visible = false;
   } 

   ALIAS_TYPE alias_table:[];

   ALIAS_TYPE junk;junk.value[0]=0;
   alias_table:[0]=junk;alias_table._deleteel(0);

   ORIG_FILENAME=aliasfilename;
   if (aliasfilename=='') {
      aliasfilename=VSCFGFILE_ALIASES;
   }
   if (!pathlen(aliasfilename)) {
      aliasfilename=usercfg_path_search(aliasfilename);
      if (aliasfilename=='') {
         if (file_eq(ORIG_FILENAME,VSCFGFILE_ALIASES)) {
            aliasfilename=_ConfigPath():+VSCFGFILE_ALIASES;
         } else {
            aliasfilename=_ConfigPath():+ORIG_FILENAME;
         }
      }
   } else {
      aliasfilename=absolute(aliasfilename);
   }

   ALIAS_MODIFIED=0;
   ALIAS_PARAMS_MODIFIED=0;
   profileName := (lang == '') ? '' : getAliasLangProfileName(lang);
   if ((ALIAS_FILE_TYPE == SYMTRANS_ALIAS_FILE) && (lang != '')) {
      profileName:+= '/symboltrans';
   }
   load_alias_file(aliasfilename,profileName,alias_table);
   _str fname='';
   typeless fsize='';
   typeless fflags='';
   parse _default_font(CFG_WINDOW_TEXT) with fname','fsize','fflags','. ;
   _ctlae_edit_window.p_font_name=fname;
   _ctlae_edit_window.p_font_size=fsize;
   _ctlae_edit_window.p_font_bold=fflags&F_BOLD;
   _ctlae_edit_window.p_font_italic=fflags&F_ITALIC;
   _ctlae_edit_window.p_font_strike_thru=fflags&F_STRIKE_THRU;
   _ctlae_edit_window.p_font_underline=fflags&F_UNDERLINE;
   _ctlae_edit_window.p_UTF8=true;
   ALIAS_TABLE=alias_table;
   int wid=p_window_id;p_window_id=_control _ctlae_alias_list;
   _update_alias_list();
   _ctlae_alias_list.p_text = initialAliasName;
   _ctlae_alias_list.p_case_sensitive=(lowcase(def_alias_case)=='e');

   colWidth := _ctlae_param_tree.p_width / 4;
   _ctlae_param_tree._TreeSetColButtonInfo(0, colWidth, -1, -1, 'Name');
   _ctlae_param_tree._TreeSetColButtonInfo(1, colWidth * 2, -1, -1, 'Prompt');
   _ctlae_param_tree._TreeSetColButtonInfo(2, colWidth, -1, -1, 'Initial Value');
}

_ctlae_ok.on_create(_str aliasfilename='', 
                    _str editSurroundAliases='', 
                    _str initialAliasName='',
                    int aliasFileType=REGULAR_ALIAS_FILE,
                    _str lang='')
{
   // get all the controls nice and pretty
   _alias_editor_form_initial_alignment();

   // we use these pics in the alias list to differentiate between regular aliases and surround withs
   ALIAS_PIC_INDEX = _find_or_add_picture('_alias.ico');
   SURROUND_WITH_ALIAS_PIC_INDEX = _find_or_add_picture('_surroundwith.ico');
   _ctlae_alias_list.p_picture = 1;

   if (aliasfilename != '') {
      initAliasEditor(aliasfilename, editSurroundAliases, initialAliasName, aliasFileType, lang);
   }
   _SetDialogInfoHt('aliasFilename', aliasfilename);

   if (aliasFileType == DOCCOMMENT_ALIAS_FILE) {
      p_active_form.p_caption='Doc Comment Editor - 'aliasfilename;
      p_active_form.p_help = 'Doc Comment Editor dialog';
      ctlAliasEscapeSeqButton.p_command = '_aliasEscapeSeq_menuDocCommentVersion';
      _ctl_filename.p_visible = false;
   } else if (aliasFileType == SYMTRANS_ALIAS_FILE) {
      p_active_form.p_caption='Symbol Translation Editor - 'aliasfilename;
      p_active_form.p_help = 'Symbol Translation Editor';
      ctlAliasEscapeSeqButton.p_command = '_aliasEscapeSeq_menuDocCommentVersion';
      _ctl_filename.p_visible = false;

      _ctlae_param_labelt.p_visible = _ctlae_param_tree.p_visible = _ctlae_param_add.p_visible = 
         _ctlae_param_edit.p_visible = _ctlae_param_up.p_visible = _ctlae_param_down.p_visible = 
         _ctlae_param_remove.p_visible = false;

      _ctlae_edit_window.p_height = (_ctlae_param_tree.p_y + _ctlae_param_tree.p_height) - _ctlae_edit_window.p_y;
   } else {
      p_active_form.p_caption='Alias Editor - 'aliasfilename;
      ctlAliasEscapeSeqButton.p_command = '_aliasEscapeSeq_menu';
   }
}

void _update_alias_list(int forceUpdate=0)
{
   ALIAS_TYPE alias_table:[];
   alias_table=ALIAS_TABLE;
   
   int wid=p_window_id;p_window_id=_control _ctlae_alias_list;
   _lbclear();

   int picIndex;
   _str aliasName;
   foreach (aliasName => . in alias_table) {
      text := aliasName;
      getAliasComboTextAndPicIndex(text, picIndex);
      _lbadd_item(text, '', picIndex);
   }

   _lbsort();
   _lbtop();
   _lbselect_line();
   p_window_id=wid;
   _ctlae_alias_list.call_event(CHANGE_OTHER,forceUpdate,defeventtab _alias_editor_form._ctlae_alias_list,ON_CHANGE,'E');
}

static _str GetListBoxText()
{
   _str text = _ctlae_alias_list._lbget_text();

   if ((text:!='')&&isCurrentAliasSurroundWith()) {
      text = SURROUND_PREFIX:+text;
   }

   return text;
}

/**
 * Loads the aliases in the given file into the hash table.
 * 
 * @param filename            filename where aliases are located
 * @param lang                language mode
 * @param hashtab             hashtable in which to load aliases
 * @param overwrite           whether to overwrite same named 
 *                            aliases.  If we find an alias with
 *                            the same name as one already in
 *                            the table, do we overwrite the
 *                            first one or ignore the second
 *                            one?
 *  
 * @return                    0 for success, error code 
 *                            otherwise
 */
int load_alias_file(_str filename, _str profileName, ALIAS_TYPE (&hashtab):[], boolean overwrite = false)
{
   mou_hour_glass(1);
   AliasFile aliasFile;
   status := aliasFile.open(filename, profileName);
   if (status < 0) return status;
   _str aliases[];
   aliasFile.getNames(aliases);
   foreach (auto n in aliases) {
      if (overwrite && hashtab._indexin(n)) {
         hashtab._deleteel(name);
      }
      if (!hashtab._indexin(n)) {
         ALIAS_TYPE a;
         AliasParam params[];
         _str ss;
         _str v = aliasFile.getAlias(n, &params);
         a.value = null;
         a.params = params;
         while (v != "") {
            parse v with ss '\n','r' v;
            a.value[a.value._length()] = ss;
         }
         hashtab:[n] = a;
      }
   }
   aliasFile.close();
   mou_hour_glass(0);
   return(0);
}

int _ctlae_alias_list.on_change(int reason)
{
   ALIAS_TYPE alias_table:[];
   alias_table=ALIAS_TABLE;
   _str alias[];
   AliasParam params[];

   typeless p;
   int wid=0;
   int isparameterized=0;
   int offset=0;
   _str varname='';
   _str prompt='';
   _str init='';
   _str line='';
   int status=0;
   int lp=0;
   int i=0;

   switch (reason) {
   case CHANGE_CLINE:
   case CHANGE_OTHER:
   case CHANGE_SELECTED:
      _lbselect_line();
      if (LAST_EDITED_ALIAS==GetListBoxText()
          && arg(2)!=1) {
         return(0);
      }
      wid=p_window_id;p_window_id=_ctlae_edit_window;
      save_pos(p);
      p_line=0;
      if (!search('\t','r@')) {
         _message_box(nls("You cannot put tab characters in an alias.  Use %\\i for indenting - This will cause the alias to expand with tabs for buffers where Indent With Tabs is turned on."));
         _ctlae_alias_list._lbfind_and_select_item(LAST_EDITED_ALIAS,def_alias_case);
         return(1);
      }
      restore_pos(p);
      offset=0;
      // IF there are any aliases
      if (_ctlae_alias_list.p_line) {
         // IF we need to save the previous alias value
         if (LAST_EDITED_ALIAS!='' &&
            (p_modify || ALIAS_PARAMS_MODIFIED)) {
            if (!p_Noflines) {//Dan added to handle the "No Line" case 10:37am 5/22/1996
               insert_line('');
            }

            // mark modified
            ALIAS_MODIFIED=1;

            // get any parameters that are there
            child := _ctlae_param_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
            if (child > 0) {
               ALIAS_PARAMS_MODIFIED=0;
               paramNum := 0;
               while (child > 0) {
                  caption := _ctlae_param_tree._TreeGetCaption(child);
                  parse caption with varname"\t"prompt"\t"init;
                  AliasParam ap;
                  ap.name = varname;
                  ap.initial = init;
                  ap.prompt = prompt;
                  params[params._length()] = ap;

                  child = _ctlae_param_tree._TreeGetNextSiblingIndex(child);
               }
            }

            top();up();
            while (!down()) {
               get_line(line);
               p=pos('\%\(:v\)',line,1,'r');
               while (p) {
                  if (p) {
                     lp=pos(')',line,p);
                     _str varwp=substr(line,p,lp-p+1);
                     _str varwop=substr(varwp,3,length(varwp)-3);

                     index := _ctlae_param_tree._TreeSearch(TREE_ROOT_INDEX, varwop"\t",'ip');
                     if (index < 0 && get_env(varwop)=='') {
                        cont := _message_box(nls("Warning:\n\nThere is no environment variable or parameter for '%s'.  ":+
                                                 "Continue?",varwop), "Alias Parameters", MB_YESNO | MB_ICONEXCLAMATION);
                        if (cont == IDNO) {
                           _ctlae_alias_list._lbfind_and_select_item(LAST_EDITED_ALIAS,def_alias_case);
                           return(1);
                        }
                     }
                  }
                  p=pos('\%\(:v\)',line,lp+1,'r');
               }
               // set a blank line to %\l to preserve the spaces
               if (line=='') line='%\l';
               alias[offset++]=line;
            }
            alias_table:[LAST_EDITED_ALIAS].value = alias;
            alias_table:[LAST_EDITED_ALIAS].params = params;

         } else if (p_modify) {
            ALIAS_MODIFIED=1;
         }

         // Switch to the new alias
         LAST_EDITED_ALIAS=GetListBoxText();
         _lbclear();
         _ctlae_param_tree._TreeDelete(TREE_ROOT_INDEX, 'C');
         fill_in_params(alias_table:[strip(GetListBoxText())].params);
         //lastevent=event2name(test_event());
         alias=alias_table:[strip(GetListBoxText())].value;
         for (i=0;i<alias._length();++i) {
            insert_line(alias[i]);
         }
         refresh();
         top();
         _begin_line();
         if (!p_Noflines) insert_line('');
         
         p_modify=0;
      } else {
         // there are no aliases to display, but we could
         // be switching in or out of  surround mode
         _ctlae_edit_window._lbclear();
         _ctlae_param_tree._TreeDelete(TREE_ROOT_INDEX, 'C');
         p_modify=0;
      }
   }
   typeless enabled='';
   if (!_ctlae_edit_window.p_enabled && _ctlae_alias_list.p_Noflines) {
      enabled=1;
   } else if (_ctlae_edit_window.p_enabled && !_ctlae_alias_list.p_Noflines) {
      enabled=0;
   }
   if (enabled!='') {
      _ctlae_edit_window.p_enabled=enabled;
      _ctlae_delete.p_enabled=enabled;
      _ctlae_param_tree.p_enabled=enabled;
      _ctlae_param_add.p_enabled=enabled;
      _ctlae_param_remove.p_enabled=enabled;
      _ctlae_param_edit.p_enabled=enabled;
      _ctlae_param_up.p_enabled=enabled;
      _ctlae_param_down.p_enabled=enabled;
   }

   enableParamButtons();

   ALIAS_TABLE=alias_table;
   return(0);
}

void _ctlae_param_tree.on_change(int reason)
{
   if (reason == CHANGE_SELECTED) enableParamButtons();
}

static void enableParamButtons()
{
   if (_ctlae_param_tree.p_enabled) {
      curIndex := _ctlae_param_tree._TreeCurIndex();
      if (curIndex > 0) {
         _ctlae_param_remove.p_enabled = _ctlae_param_edit.p_enabled = true;
         _ctlae_param_up.p_enabled = (_ctlae_param_tree._TreeGetPrevSiblingIndex(curIndex) > 0);
         _ctlae_param_down.p_enabled = (_ctlae_param_tree._TreeGetNextSiblingIndex(curIndex) > 0);
      } else {
         _ctlae_param_remove.p_enabled = _ctlae_param_edit.p_enabled =
            _ctlae_param_up.p_enabled = _ctlae_param_down.p_enabled = false;
      }
   }
}

static void fill_in_params(AliasParam (&params)[])
{
   foreach (auto ap in params) {
      caption := ap.name"\t"ap.prompt"\t"ap.initial;
      _ctlae_param_tree._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   }
}

static int write_alias_file(_str filename, ALIAS_TYPE (&alias_table):[], _str profileName)
{
   int status;
   AliasFile aliasFile;
   status = aliasFile.open(filename, profileName);
   if (status) {
      aliasFile.create(profileName);
   }
   aliasFile.clearAliases();

   typeless curalias;
   int size=0;
   int i=0;

   // go through each of the aliases in the table
   typeless name;
   for (name._makeempty();;) {
      // get the name of the next one
      alias_table._nextel(name);
      if (name._isempty()) break;
      
      // get the alias itself
      curalias = alias_table:[name].value;
      if (curalias._isempty()) {
         aliasFile.insertAlias(name, "");
         continue;
      }
      size = curalias._length();

      value := curalias[0];
      for (i = 1; i < size; ++i) {
         // does this end with a space?  preserve it!
         if (curalias[i] == '') {
            curalias[i] = '%\l';
         } else if (last_char(curalias[i]):==' ') {
            curalias[i] = curalias[i]'%\S';
         }
         strappend(value, "\n":+curalias[i]);
      }
      if (value != '') {
         aliasFile.insertAlias(name, value, &alias_table:[name].params);
      }
   }
   aliasFile.save(filename);
   aliasFile.close();
   return(status);
}

static int lastpixel_y(int wid)
{
   return(wid.p_y+wid.p_height);
}

void _ctlae_ok.lbutton_up()
{
   int fid=p_active_form;

   status := false;
   if (_alias_editor_form_is_modified()) {
      status = _alias_editor_form_apply();
   }

   fid._delete_window(status);
}

int _validnewaliasname(_str name,typeless *hashtabptr, boolean isSurround)
{
   _str test_name=strip(name); // first thing done after dialog returns

   if (isSurround) {
      // surround with aliases can contain whitespace since the user
      // won't be typing these in to expand them
      test_name=translate(SURROUND_PREFIX:+test_name,'__'," \t");
   }
   if (pos(" |\t",test_name,1,'r')) {
      _message_box(nls("Alias names may not contain whitespace."));
      return(1);
   }
   if (hashtabptr->_indexin(test_name)) {
      _message_box(nls("An alias %s already exists.",strip(name)));
      return(1);
   }
   return(0);
}

void _ctlae_new.lbutton_up()
{
   ALIAS_TYPE alias_table:[];
   alias_table=ALIAS_TABLE;
   
   surroundPrompt := surroundWithAvailable() ? '-checkbox Surround with' : '';
   _str newaliasname = '';
   boolean isSurround = false;
   while (true) {
      result := textBoxDialog('Enter New Alias Name',                 // form caption
                    0,                                      // flags
                    0,                                      // text box width
                    'Enter New Alias Name dialog',          // help item
                    '',                                     // buttons and captions
                    '',                                     // retrieve name
                    'Alias Name:'newaliasname,
                    surroundPrompt);             // prompt

      if (result == COMMAND_CANCELLED_RC || _param1 == '') return;

      newaliasname = strip(_param1);
      isSurround = surroundPrompt != '' && _param2;

      if (!_validnewaliasname(newaliasname, &alias_table, isSurround)) break;

   }
   
   ALIAS_MODIFIED=1;
   _str newaliastext='';

   // get the full alias name
   _str fullaliasname='';
   int picIndex = 0;
   if (isSurround) {
      newaliasname=translate(newaliasname,'__'," \t");
      fullaliasname=SURROUND_PREFIX:+newaliasname;
      newaliastext="%\\m sur_text -indent%";
      picIndex = SURROUND_WITH_ALIAS_PIC_INDEX;
   } else {
      fullaliasname=newaliasname;
      if (surroundPrompt != '') {
         picIndex = ALIAS_PIC_INDEX;
      }
   }

   alias_table:[fullaliasname].value[0]='';

   // add it to the list
   int wid=p_window_id;
   p_window_id=_ctlae_alias_list;
   _lbdeselect_all();
   _lbadd_item(newaliasname, '', picIndex);
   _lbsort();
   _lbfind_and_select_item(newaliasname,def_alias_case);
   p_window_id=wid;

   typeless x=ALIAS_TABLE;

   _ctlae_alias_list.call_event(CHANGE_OTHER,defeventtab _alias_editor_form._ctlae_alias_list,ON_CHANGE,'E');
   //Dan added this to save blank aliases 10:20am 5/22/1996
   //LAST_EDITED_ALIAS=newaliasname;

   //DJB 11-19-2006 -- insert %\m sur_text -indent% for surround aliases
   _ctlae_edit_window._insert_text(newaliastext);

   //Dan added this to save blank aliases 10:20am 5/22/1996
   _ctlae_edit_window.p_modify=1;

   _ctlae_edit_window._set_focus();
}

void _ctlae_delete.lbutton_up()
{
   ALIAS_TYPE alias_table:[];
   alias_table=ALIAS_TABLE;
   ALIAS_MODIFIED=1;
   int wid=p_window_id;p_window_id=_ctlae_alias_list;
   _str name=GetListBoxText();
   _lbdelete_item();
   alias_table._deleteel(name);
   _lbdeselect_all();
   _ctlae_alias_list.call_event(CHANGE_SELECTED,defeventtab _alias_editor_form._ctlae_alias_list,ON_CHANGE,'E');
   _lbselect_line();
   if (!p_Noflines) {
      _ctlae_edit_window._lbclear();
   }
   p_window_id=wid;
   ALIAS_TABLE=alias_table;
}

void _ctlae_cancel.lbutton_up()
{
   if (ALIAS_MODIFIED || _ctlae_edit_window.p_modify) {
      aliasfilename := _GetDialogInfoHt('aliasFilename');
      if (aliasfilename == '' || aliasfilename == null || !file_exists(aliasfilename)) {
         return;
      }
      aliasfilename = strip(maybe_quote_filename(aliasfilename));
      int result = _message_box(nls("%s has been modified.\n\nExit anyway?", aliasfilename),
                          '',
                          MB_YESNO|MB_ICONQUESTION);
      if (result != IDYES) return;
   }

   // return the value false to state that we did not modify anything
   p_active_form._delete_window(false);
}

int _validnewparamcheck(_str str,_str fieldnum)
{
   int status=0;
   typeless wid=0;
   _str data='';
   parse fieldnum with fieldnum '$' data ;
   switch (fieldnum) {
   case 1://Varname
      wid=data;
      if (!isid_valid(str)) {
         _message_box(nls("%s is not a valid identifier.",str));
         return(1);
      }
      status=wid._TreeSearch(TREE_ROOT_INDEX, str"\t",'ip');
      if (status>0) {
         _message_box(nls("%s already exists.",str));
         return(1);
      }
      return(0);
   case 2://Prompt
      if (str=='') {
         _message_box(nls("You must specify a prompt."));
         return(1);
      }
      if (pos('"',str)) {
         _message_box(nls("Prompt may not contain quotes."));
         return(1);
      }
      return(0);
   case 3://Varname, don't check to see if exists
      if (!isid_valid(str)) {
         _message_box(nls("%s is not a valid identifier.",str));
         return(1);
      }
      return(0);
   }
   return(0);
}

void _ctlae_param_add.lbutton_up()
{
   typeless result=show('-modal _textbox_form',
               'Enter Alias Parameter',
               0,//Flags,
               '',//Tb width
               'Enter Alias Parameter dialog',//help item
               '',//Buttons and captions
               '',//retrieve name
               '-e _validnewparamcheck:1$'_ctlae_param_tree' Parameter Name:',
               '-e _validnewparamcheck:2 Prompt:',
               'Initial Value:');
   if (result=='') return;
   _str varname=_param1;
   _str promptstr=_param2;
   _str initval=_param3;
   int wid=p_window_id;
   caption := varname"\t"promptstr"\t"initval;
   _ctlae_param_tree._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   enableParamButtons();
   ALIAS_PARAMS_MODIFIED=1;
}

void _ctlae_param_edit.lbutton_up()
{
   curIndex := _ctlae_param_tree._TreeCurIndex();
   if (curIndex < 0) return;
   _str varname='';
   _str promptstr='';
   _str initval='';
   caption := _ctlae_param_tree._TreeGetCaption(curIndex);
   parse caption with varname"\t"promptstr"\t"initval;
   typeless result=show('-modal _textbox_form',
               'Edit Alias Parameter',
               0,//Flags,
               '',//Tb width
               'Edit Alias Parameter dialog',//help item
               '',//Buttons and captions
               '',//retrieve name
               '-e _validnewparamcheck:3 Parameter Name:'varname,
               '-e _validnewparamcheck:2 Prompt:'promptstr,
               'Initial Value:'initval);
   if (result=='') return;
   varname=_param1;
   promptstr=_param2;
   initval=_param3;
   _ctlae_param_tree._TreeSetCaption(curIndex, varname"\t"promptstr"\t"initval);
   ALIAS_PARAMS_MODIFIED=1;
}

_ctlae_param_up.lbutton_up()
{
   ALIAS_MODIFIED=1;
   ALIAS_PARAMS_MODIFIED=1;
   index := _ctlae_param_tree._TreeCurIndex();
   _ctlae_param_tree._TreeMoveUp(index);
   enableParamButtons();
}

_ctlae_param_down.lbutton_up()
{
   ALIAS_MODIFIED=1;
   ALIAS_PARAMS_MODIFIED=1;
   index := _ctlae_param_tree._TreeCurIndex();
   _ctlae_param_tree._TreeMoveDown(index);
   enableParamButtons();
}

void _ctlae_param_remove.lbutton_up()
{
   index := _ctlae_param_tree._TreeCurIndex();
   _ctlae_param_tree._TreeDelete(index);
   enableParamButtons();
   ALIAS_MODIFIED=1;
   ALIAS_PARAMS_MODIFIED=1;
}

static void set_vis_all(int parentwid,boolean vis_val)
{
   int first=parentwid.p_child;
   int wid=parentwid.p_child;
   for (;;) {
      wid.p_visible=vis_val;
      wid=wid.p_next;
      if (wid==first) break;
   }
}

static void children_visible(int widlist){set_vis_all(widlist,1);}

static void children_invisible(int widlist){set_vis_all(widlist,0);}

#define gui_small_gap      30
#define gui_medium_gap     90
#define gui_large_gap      180
#define gui_xlarge_gap     315


/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _alias_editor_form_initial_alignment()
{
   ctlAliasEscapeSeqButton.p_x = (_ctlae_edit_window.p_x + _ctlae_edit_window.p_width) - ctlAliasEscapeSeqButton.p_width;
   ctl_escapeSeq_label.p_x = ctlAliasEscapeSeqButton.p_x - (ctl_escapeSeq_label.p_width + 25);

   // set this right on top of the editor control
   if (ctlAliasEscapeSeqButton.p_height > ctl_escapeSeq_label.p_height) {
      ctlAliasEscapeSeqButton.p_y = _ctlae_edit_window.p_y - ctlAliasEscapeSeqButton.p_height;
      _ctlae_def_label.p_y = ctl_escapeSeq_label.p_y = ctlAliasEscapeSeqButton.p_y - ((ctlAliasEscapeSeqButton.p_height - ctl_escapeSeq_label.p_height) intdiv 2);
   } else {
      _ctlae_def_label.p_y = ctl_escapeSeq_label.p_y = _ctlae_edit_window.p_y - ctl_escapeSeq_label.p_height;
      ctlAliasEscapeSeqButton.p_y = ctl_escapeSeq_label.p_y + ((ctl_escapeSeq_label.p_height - ctlAliasEscapeSeqButton.p_height) intdiv 2);
   }

   _ctlae_new.p_y = _ctlae_delete.p_y = _ctlae_alias_list.p_y + _ctlae_alias_list.p_height + PADDING_BETWEEN_LIST_AND_CONTROLS;
   _ctlae_new.p_x = _ctlae_alias_list.p_x;
   _ctlae_delete.p_x = _ctlae_new.p_x + _ctlae_new.p_width + PADDING_BETWEEN_CONTROL_BUTTONS;

   _ctlae_param_edit.p_auto_size = false;
   _ctlae_param_edit.p_width = _ctlae_param_add.p_width;
   _ctlae_param_edit.p_height = _ctlae_param_add.p_height;

   // parameter tree buttons
   alignUpDownListButtons(_ctlae_param_tree, _ctlae_edit_window.p_x + _ctlae_edit_window.p_width,
                          _ctlae_param_add, _ctlae_param_edit, _ctlae_param_up, _ctlae_param_down,
                          _ctlae_param_remove);

   _set_minimum_size(_ctlae_ok.p_width * 6, _ctlae_ok.p_height * 15);
}

static void shift_alias_controls_up()
{
   yDiff := _ctlae_alias_list.p_y - _ctl_filename.p_y;

   _ctlae_def_label.p_y -= yDiff;
   _ctlae_alias_list.p_y -= yDiff;
   _ctlae_alias_list.p_height += yDiff;
   ctl_escapeSeq_label.p_y -= yDiff;
   ctlAliasEscapeSeqButton.p_y -= yDiff;
   _ctlae_edit_window.p_y -= yDiff;
   _ctlae_edit_window.p_height += yDiff;
}

void _alias_editor_form.on_resize()
{
   optionsDialog := !_ctlae_ok.p_visible;

   // the filename label goes away outside the options dialog
   if (p_active_form.p_visible && !optionsDialog && (_ctlae_alias_list.p_y != _ctl_filename.p_y)) {
      shift_alias_controls_up();
   }

   children_invisible(p_active_form);

   // figure out how much the size has changed
   padding := _ctlae_alias_list.p_x;
   widthDiff := p_width - (_ctlae_edit_window.p_x + _ctlae_edit_window.p_width + padding);
   heightDiff := 0;
   if (!optionsDialog) {
      heightDiff = p_height - (_ctlae_ok.p_y + _ctlae_ok.p_height + padding);
   } else {
      heightDiff = p_height - (_ctlae_new.p_y + _ctlae_new.p_height + padding);
   } 

   _ctlae_alias_list.p_height+=heightDiff;
   _ctlae_edit_window.p_height+=heightDiff;
   _ctlae_edit_window.p_width+=widthDiff;

   // row of alias buttons
   _ctlae_help.p_y+=heightDiff;
   _ctlae_ok.p_y=_ctlae_cancel.p_y=_ctlae_help.p_y;

   _ctlae_delete.p_y+=heightDiff;
   _ctlae_new.p_y+=heightDiff;

   // parameter list
   _ctlae_param_labelt.p_y += heightDiff;
   _ctlae_param_labelt.p_width += widthDiff;
   _ctlae_param_tree.p_y+=heightDiff;
   _ctlae_param_tree.p_width+=widthDiff;

   // parameter buttons
   _ctlae_param_down.p_y+=heightDiff;
   _ctlae_param_add.p_y+=heightDiff;
   _ctlae_param_remove.p_y+=heightDiff;
   _ctlae_param_edit.p_y+=heightDiff;
   _ctlae_param_up.p_y+=heightDiff;

   _ctlae_param_add.p_x+=widthDiff;
   _ctlae_param_remove.p_x=_ctlae_param_edit.p_x=_ctlae_param_up.p_x=_ctlae_param_down.p_x=_ctlae_param_add.p_x;

   // insert escape sequence stuff
   ctlAliasEscapeSeqButton.p_x += widthDiff;
   ctl_escapeSeq_label.p_x += widthDiff;

   _ctlae_ok.p_x += widthDiff;
   _ctlae_help.p_x += widthDiff;
   _ctlae_cancel.p_x += widthDiff;

   // show everything again
   children_visible(p_active_form);
   _ctlae_ok.p_visible = _ctlae_cancel.p_visible = _ctlae_help.p_visible = !optionsDialog;
   _ctl_filename.p_visible = optionsDialog;
   _ctlae_new.p_visible = _ctlae_delete.p_visible = (ALIAS_FILE_TYPE != DOCCOMMENT_ALIAS_FILE);

   _ctlae_param_labelt.p_visible = _ctlae_param_tree.p_visible = _ctlae_param_add.p_visible = 
      _ctlae_param_edit.p_visible = _ctlae_param_up.p_visible = _ctlae_param_down.p_visible = 
      _ctlae_param_remove.p_visible = parametersAvailable();
}
_command int edit_extension_alias(_str ext='')
{
   // do they want to edit surround with aliases?
   boolean editSurround=false;
   _str option, rest;
   parse ext with option rest;
   if (option=='-surround') {
      ext = rest;
      editSurround=true;
   }

   // make sure we have the file extension
   lang := ext;
   if ( ext != '' ) {
      lang = _Ext2LangId(ext);
      if (lang == '') {
         // if nothing came up, try the lowcase version
         lang = _Ext2LangId(lowcase(ext));
      }
   }else{
      lang = p_LangId;
   }

   modeName := _LangId2Modename(lang);
   showOptionsForModename(modeName, 'Aliases');
   return(0);
}

_str _lang_doc_comments_expansion_export_settings(_str &path, _str &importArgs, _str langId)
{
   error := '';
   
   // get the expansions file (which is really just some aliases)
   aliasFile := getCWaliasFile(langId, false);

   // make sure we have a path here
   if (aliasFile != '' && (file_exists(aliasFile))) {
      // rip out just the file name
      justFile := _strip_filename(aliasFile, 'P');
      if (copy_file(aliasFile, path :+ justFile)) {
         error = 'Error copying doc comments expansion file for '_LangId2Modename(langId)', 'aliasFile'.';
      }
      path = justFile;
   }

   return error;
}

_str _lang_doc_comments_expansion_import_settings(_str file, _str importArgs, _str langId = '')
{
   error := '';
   status := 0;


   if (file != '') {
      // get the filename for these expansions
      curFile := getCWaliasFile(langId, false);
  
      if (file_exists(curFile)) {
         // we append to the original file, rather than replace it
         status = mergeAliasFiles(curFile, file, langId);
      } else {
         // easy!  we just copy
         status = copy_file(file, curFile);
      }
   }

   if (status) {
      error = 'Error copying aliases from alias file for '_LangId2Modename(langId)', 'file'.';
   }

   return error;
}

