////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified o/r unmodified) 
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
#include "cvs.sh"
#include "subversion.sh"
#include "perforce.sh"
#include "mercurial.sh"
#include "git.sh"
#import "se/lang/api/LanguageSettings.e"
#import "se/lang/api/ExtensionSettings.e"
#import "se/color/ColorScheme.e"
#import "se/color/DefaultColorsConfig.e"
#import "se/color/SymbolColorAnalyzer.e"
#import "se/color/SymbolColorConfig.e"
#import "se/datetime/DateTimeFilters.e"
#import "se/alias/AliasFile.e"
#import "se/ui/toolwindow.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "bgsearch.e"
#import "box.e"
#import "cfg.e"
#import "clipbd.e"
#import "compword.e"
#import "context.e"
#import "error.e"
#import "files.e"
#import "filetypemanager.e"
#import "fontcfg.e"
#import "ini.e"
#import "main.e"
#import "notifications.e"
#import "search.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbfilelist.e"
#import "tbfind.e"
#import "tbopen.e"
#import "toolbar.e"
#import "vchack.e"
#import "xml.e"
#import "xmldoc.e"
#endregion

using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;
using se.color.ColorScheme;
using se.color.DefaultColorsConfig;
using se.alias.AliasFile;

static _str gold_intfeature_to_strfeature[]= {
   "close file",
   "", //goto definition
   "adaptive formatting",
   "", //delete code block
   "", //unsurround
   "", //source diff
   "", //reload files
   "", //debugger - enabled, showpopups,method and log options aren't used.
   "", //macro errors
   "alias expansion",
   "symbol translation",
   "comment wrap",
   "doc comment expansion",
   "dynamic surround",
   "xmlhtml formatting",
   "insert right bracket",
   "insert matching parameters",
   "smartpaste",
   "syntax expansion",
   "close completion",
   "case keywords",
   "list members",
   "display parameter information",
   "list compatible parameters",
   "list compatible values",
   "" //"large file editing" - enabled, showpopups,method and log options aren't used.
};


static _str gold_notificationaction_to_strfeature[]= {
   "adaptive formatting",
   "alias expansion",
   "symbol translation",
   "comment wrap",
   "doc comment expansion",
   "dynamic surround",
   "xmlhtml formatting",
   "insert right bracket",
   "insert matching parameters",
   "smartpaste",
   "syntax expansion",
   "close file",
   "case keywords",
   "close completion",
   "list members",
   "display parameter information",
   "list compatible parameters",
   "list compatible values",
   "large file editing",
};

/* 
    Convert old alert_config.xml options and def_notification_actions to properties
 
   struct NOTIFICATION_ACTION {
      NotificationMethod Method;
      bool Log;
   };
   NOTIFICATION_ACTION def_notification_actions[];
*/
static void convert_old_alert_config() {
   _str old_alert_filename=_ConfigPath():+'alert_config.xml';
   handle:=_xmlcfg_open(old_alert_filename,auto status);
   //say('handle='handle);
   if (handle<0) return;

   typeless group_node_array[];
   _xmlcfg_find_simple_array(handle,'//alertgroup',group_node_array);
   for (i:=0;i<group_node_array._length();++i) {
      int group=group_node_array[i];
      groupid:=_xmlcfg_get_attribute(handle,group,'id');
      enabled:=_xmlcfg_get_attribute(handle,group,'enabled');
      showpopups:=_xmlcfg_get_attribute(handle,group,'showpopups');
      //say('groupid='groupid);
      if (groupid=='') {
         continue;
      }
      // Feature notifications or Background Processes
      new_group_id := "";
      switch (groupid) {
      case 0:
         new_group_id=ALERT_GRP_EDITING_ALERTS;
         break;
      case 1:
         new_group_id=ALERT_GRP_BACKGROUND_ALERTS;
         break;
      case 2:
         new_group_id=ALERT_GRP_DEBUG_LISTENER_ALERTS;
         break;
      case 3:
         new_group_id=ALERT_GRP_WARNING_ALERTS;
         break;
      case 4:
         new_group_id=ALERT_GRP_UPDATE_ALERTS;
         break;
      }
      //say('new_group_id='new_group_id);
      if (new_group_id!='') {
         int group_profile=_plugin_get_profile(VSCFGPACKAGE_NOTIFICATION_PROFILES,new_group_id);
         //say('group_profile='group_profile);
         if (group_profile>=0) {
            int doc_node=_xmlcfg_get_first_child(group_profile,0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
            if (enabled!='') _xmlcfg_set_property(group_profile,doc_node,'enabled',enabled);
            if (showpopups!='') _xmlcfg_set_property(group_profile,doc_node,'show_popups',showpopups);
            _plugin_set_profile(group_profile);
            _xmlcfg_close(group_profile);
         }
      }


      if (groupid==0) {
         typeless alert_node_array[];
         _xmlcfg_find_simple_array(handle,'//alert',alert_node_array,group);
         for (j:=0;j<alert_node_array._length();++j) {
            int alert=alert_node_array[j];
            alertid:=_xmlcfg_get_attribute(handle,alert,'id');
            enabled=_xmlcfg_get_attribute(handle,alert,'enabled');
            showpopups=_xmlcfg_get_attribute(handle,alert,'showpopups');

            //method:=_xmlcfg_get_attribute(handle,alert,'method');
            //log:=_xmlcfg_get_attribute(handle,alert,'log');

            //say('a0 alertid='alertid);
            _str feature=gold_intfeature_to_strfeature[alertid];
            if (feature!='') {
               int alert_profile=_plugin_get_profile(vsCfgPackage_for_NotificationGroup(new_group_id),feature);
               //say('alert_profile='alert_profile' feature='gold_intfeature_to_strfeature[alertid]);
               if (alert_profile>=0) {
                  int doc_node=_xmlcfg_get_first_child(alert_profile,0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
                  if (enabled!='') _xmlcfg_set_property(alert_profile,doc_node,'enabled',enabled);
                  if (showpopups!='') _xmlcfg_set_property(alert_profile,doc_node,'show_popups',showpopups);
                  //if (log!='') _xmlcfg_set_property(alert_profile,doc_node,'log',log);
                  //if (method!='') _xmlcfg_set_property(alert_profile,doc_node,'method',method);
                  _plugin_set_profile(alert_profile);
                  _xmlcfg_close(alert_profile);
               }
            }
         }
      }

   }
   _xmlcfg_close(handle);
   delete_file(old_alert_filename);
   index:=find_index('def_notification_actions',VAR_TYPE);
   //say('index='index);
   if (index>0) {
      //say('index='index);
      NOTIFICATION_ACTION notification_array[];
      notification_array= _get_var(index);
      for (k:=0;k<notification_array._length();++k) {
         _str feature=gold_notificationaction_to_strfeature[k];
         int alert_profile=_plugin_get_profile(vsCfgPackage_for_NotificationGroup('feature'),feature);
         if (alert_profile>=0) {
            //say('feature='feature' log='notification_array[k].Log' method='notification_array[k].Method);
            int doc_node=_xmlcfg_get_first_child(alert_profile,0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
            //say('doc_node name='_xmlcfg_get_name(alert_profile,doc_node));
            _xmlcfg_set_property(alert_profile,doc_node,'log',notification_array[k].Log);
            _xmlcfg_set_property(alert_profile,doc_node,'method',(int)notification_array[k].Method);
            _plugin_set_profile(alert_profile);
            //_showxml(handle);
            _xmlcfg_close(alert_profile);
         }
      }
   }

}

/*
 
<!DOCTYPE Project SYSTEM "http://www.slickedit.com/dtd/vse/10.0/vpe.dtd">
<Project
    Version="10.0"
    VendorName="SlickEdit"
    SysVPEVersion="20.0.0.1">
    <Config Name=".coffeescript">
        <Menu>
            <Target
                Name="Compile"
                MenuCaption="&amp;Compile"
                CaptureOutputWith="ProcessBuffer"
                SaveOption="SaveCurrent"
                RunFromDir="%rw">
                <Exec CmdLine="coffee -c %f"/>
            </Target>
            <Target
                Name="Build"
                MenuCaption="&amp;Build"
                CaptureOutputWith="ProcessBuffer"
                SaveOption="SaveWorkspaceFiles"
                RunFromDir="%rw">
                <Exec/>
            </Target>
            <Target
                Name="Rebuild"
                MenuCaption="&amp;Rebuild"
                CaptureOutputWith="ProcessBuffer"
                SaveOption="SaveWorkspaceFiles"
                RunFromDir="%rw">
                <Exec/>
            </Target>
            <Target
                Name="Debug"
                MenuCaption="&amp;Debug"
                SaveOption="SaveNone"
                RunFromDir="%rw">
                <Exec/>
            </Target>
            <Target
                Name="Execute"
                MenuCaption="E&amp;xecute"
                SaveOption="SaveNone"
                RunFromDir="%rw">
                <Exec/>
            </Target>
        </Menu>
    </Config>
</Project>
 
*/
static _str VSCFGFILE_USER_EXTPROJECTS(){
    return (_isUnix()? "uproject.vpe" : "project.vpe" );
}

static void convert_old_LanguageSpecificProjects() {
   /*
     Note that this function does not support converting the old project.slk files (Version <=7.0 I think).
   */
   old_user_extprojects:=_ConfigPath():+VSCFGFILE_USER_EXTPROJECTS();
   if ( editor_name('s')=='' || // if state file exists (not building state file)
        !file_exists(old_user_extprojects)
       ) {
      return;
   }
   status := 0;
   handle:=_xmlcfg_open(old_user_extprojects,status);
   if (handle<0) {
      // Nothing to convert
      return;
   }
   typeless array[];
   _xmlcfg_find_simple_array(handle,'/Project/Config',array);
   for (i:=0;i<array._length();++i) {
      langid := substr(_xmlcfg_get_attribute(handle,array[i],'Name'),2);
      _xmlcfg_set_attribute(handle,array[i],'Name','Release');
      dest_handle:=_xmlcfg_create('',VSENCODING_UTF8);
      dest_profile_node:=_xmlcfg_set_path(dest_handle,'/p/Project');
      _xmlcfg_copy(dest_handle,dest_profile_node,handle,array[i],VSXMLCFG_COPY_AS_CHILD);
      profileName := "User";
      _plugin_set_property(VSCFGPACKAGE_LANGUAGE,langid,VSCFGPROFILE_LANGUAGE_VERSION,'fileproject_default_profile',profileName);
      _plugin_set_property_xml(vsCfgPackage_for_LangFileProjectProfiles(langid),profileName,VSCFGPROFILE_FILEPROJECTS_VERSION,'content',dest_handle);
      _xmlcfg_close(dest_handle);
   }
   _xmlcfg_close(handle);
   delete_file(old_user_extprojects);
}
using se.files.FileNameMapper;
using se.files.FilePattern;
static _str DIRECTORY_WILDCARD() {
   return '**'FILESEP;
}
using namespace se.files;
void _UpgradeExtensionlessFiles(_str config_migrated_from_version) {
   index:=find_index('def_file_name_mapper',VAR_TYPE);
   if (index) {
      typeless value=_get_var(index);
      // table mapping absolute file names to languages
      _str files:[];
      if (value._length()>=1) {
         //say('found files');
         files=value[0];
      }
      // array of FilePatterns in order of precedence
      FilePattern patterns[];
      if (value._length()>=2) {
         //say('found patterns');
         patterns=value[1];
      }
      for (i:=0;i<patterns._length();++i) {
         antPattern:=patterns[i].AntPattern;

         if (endsWith(antPattern,'**')) {
            antPattern:+=FILESEP:+"*.";
         }
         if (endsWith(antPattern,'*')) {
            antPattern:+=".";
         }
         patterns[i].AntPattern=antPattern;
      }
      FileNameMapper.convertFromOldMapVariables(files,patterns);
   }


   if (config_migrated_from_version=='') {
      return;
   }
   // get the major version
   dotPos := pos('.', config_migrated_from_version);
   if (!dotPos) return;

   // we only have to do this coming from version previous to 15
   prevMajorVersion := (int)substr(config_migrated_from_version, 1, dotPos - 1);
   if (prevMajorVersion >= 15) return;

   // have we already set up our defaults?
   if (def_file_name_map_init_defaults) return;
   def_file_name_map_init_defaults = true;

   FilePattern pattern;
   pattern.Type = AFTMT_FILENAME_PATTERN;
   pattern.AllFiles = false;

   // we used to hard code this stuff, but this is better, no?
   pattern.AntPattern = '**'FILESEP'makefile';
   pattern.Language = 'mak';
   FileNameMapper.addPatternMap(pattern);

   if (_isUnix()) {
      // We need to add both because UNIX users type makefile and Makefile
      pattern.AntPattern = '**'FILESEP'Makefile';
      FileNameMapper.addPatternMap(pattern);
   }

   pattern.AntPattern = '**'FILESEP'Imakefile';
   pattern.Language = 'imakefile';
   FileNameMapper.addPatternMap(pattern);

   // if we did not upgrade from anything, don't worry about it
   if (config_migrated_from_version == '') return;

   // are either of these blank?  because then we have nothing to do!
   if (def_cpp_include_path_re != '' && def_user_langext_files != '') {

      dirs := def_cpp_include_path_re;

      // un-escape all the regex chars (remove the lonely slashes)
      // we do it this way rather than use stranslate because we don't want to remove any double slashes
      startPos := 1;
      slashPos := pos('\', dirs, startPos);
      while (slashPos) {
         // remove the slash!
         before := substr(dirs, 1, slashPos - 1);
         after := substr(dirs, slashPos + 1);

         dirs = before :+ after;

         startPos = slashPos;
         if (substr(after, 1, 1) == '\') startPos++;

         slashPos = pos('\', dirs, startPos);
      }

      // now split up the directories by looking for the |
      _str dirArray[];
      split(dirs, '|', dirArray);

      // also split the files into an array
      _str fileArray[];
      split(def_user_langext_files, ' ', fileArray);

      // now we have to combine each and every one by making a pattern
      pattern.Type = AFTMT_PATTERN;
      pattern.AllFiles = false;
      pattern.Language = 'c';

      for (i := 0; i < dirArray._length(); i++) {

         dirPart := dirArray[i];
         // special case for the g++
         if (dirPart == 'g++-[234]') {
            dirArray[i] = dirPart = 'g++';
         }
         dirPart = '*'dirPart'*' :+ FILESEP;

         for (j := 0; j < fileArray._length(); j++) {
            filePart := fileArray[j];

            pattern.AntPattern = DIRECTORY_WILDCARD() :+ dirPart :+ DIRECTORY_WILDCARD() :+ filePart;
            FileNameMapper.addPatternMap(pattern);
         }
      }
   }
}

/**
 * Updates how language settings are stored.  In case user has any old-style 
 * language settings lying around, we update them to the new style. 
 * 
 * @param moduleLoaded 
 */
static void _UpgradeLanguageSetup()
{
#if 0
   Lets just forget about this. v20 will have a setting for this.
    
   // change storage of numbering setting in pl1 in SE 2009
   if (LanguageSettings.isLanguageDefined('pl1')) {
      index = find_index('def-numbering-pl1', MISC_TYPE);
      if (index < 0) {
         // we used to store this value this way...but not anymore
         insert_name('def-numbering-pl1', MISC_TYPE, LanguageSettings.getMainStyle('pl1', 0));
      } 
   }
#endif

   // move delphi expansions to a new brace style flag (pascal only)
   if (LanguageSettings.isLanguageDefined('pas')) {
      insertBlankLine := LanguageSettings.getInsertBlankLineBetweenBeginEnd('pas');
      if (insertBlankLine) {
         // turn on delphi expansions
         LanguageSettings.setDelphiExpansions('pas', true);
         // turn off insert blank line - it's not used with this language anyway
         LanguageSettings.setInsertBlankLineBetweenBeginEnd('pas', false);
      }
   }

   if (LanguageSettings.isLanguageDefined('vbs')) {
      autoClose := LanguageSettings.getAutoBracket('vbs');
      if (autoClose & AUTO_BRACKET_SINGLE_QUOTE) {
         autoClose &= ~AUTO_BRACKET_SINGLE_QUOTE;
         LanguageSettings.setAutoBracket('vbs', autoClose);
      }
   }

   if (LanguageSettings.isLanguageDefined('java')) {
      refLangs := LanguageSettings.getReferencedInLanguageIDs('java');
      if (refLangs != '') {
         if (pos('android', refLangs) <= 0) {
            refLangs :+= ' android';
         }
      } else {
         refLangs = 'android';
      }
      LanguageSettings.setReferencedInLanguageIDs('java', refLangs);
   }
}

/**
 * Upgrades any language setting defaults that have changed since the previous 
 * version. 
 */
void _UpgradeExtensionSetup()
{
   /**
    * Heads up!  In v15.0.1, we changed how this function works.  If you need to 
    * make an update to a default language setting, do it in a callback for that 
    * language.  The callback will be called _<langId>_update_settings.  It may 
    * already exist, or you may have to create it.  In your callback, do a check 
    * for the UpdateVersion of the language before making any changes.  The 
    * UpdateVersion lets us know when we last updated this language's default 
    * settings, so we can know if the language is already up to date.  That way, we 
    * won't trample settings set by the user. 
    *  
    * Do not worry about setting the new UpdateVersion for the 
    * language in your callback, we take care of it here. 
    */
   _ansic_update_settings();
   _asm390_update_settings();
   _cob_update_settings();
   _c_update_settings();
   _docbook_update_settings();
   _dtd_update_settings();
   _e_update_settings();
   _fundamental_update_settings();
   _html_update_settings();
   _java_update_settings();
   _m_update_settings();
   _lua_update_settings();
   _pas_update_settings();
   _py_update_settings();
   _ruby_update_settings();
   _sqlserver_update_settings();
   _tagdoc_update_settings();
   _vbs_update_settings();
   _bas_update_settings();
   _vpj_update_settings();
   _xsd_update_settings();
   _xhtml_update_settings();
   _xmldoc_update_settings();
   _xml_update_settings();
   _coffeescript_update_settings();
   _googlego_update_settings();
   _ttcn3_update_settings();

   index:=name_match('def-'UPDATE_VERSION_DEF_VAR_KEY'-',1,MISC_TYPE);
   int array[];
   while (index) {
      array[array._length()]=index;
      index=name_match('def-'UPDATE_VERSION_DEF_VAR_KEY'-',0,MISC_TYPE);
   }

   for (i:=0;i<array._length();++i) {
      delete_name(array[i]);
   }

}
/**
 * Adds a new language to the def_file_types - for upgrading 
 * customers when we add support for a new language. 
 * 
 * @param langLabel        label for language (usually mode 
 *                         name)
 * @param fileTypes        extensions used by language
 */
static void addNewLanguageToDefFileTypes(_str langLabel, _str fileTypes)
{
   // see if it's already there - that would be WEIRD
   if (!pos(langLabel" (", def_file_types)) {
      // just shove it at the end, basically
      if (!endsWith(def_file_types, ',')) {
         def_file_types :+= ',';
      }
      def_file_types :+= langLabel' ('fileTypes')';
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

static void updateDefFileTypesLabel(_str oldLabel, _str newLabel)
{
   // we want to update the label of the mode
   _str text1, rest;
   if (pos(oldLabel" (", def_file_types) && !pos(newLabel" (", def_file_types)) {
      parse def_file_types with text1 oldLabel" (" rest;
      def_file_types = text1 :+ newLabel" ("rest;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}


static const ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY=         'adaptive-flags';
static const ALIAS_EXPAND_ON_SPACE_DEF_VAR_KEY=             'alias-expand';
static const AUTOBRACKET_VAR_KEY=                           'autobracket';
static const AUTOSURROUND_VAR_KEY=                          'autosurround';
static const AUTOCOMPLETE_MIN_LENGTH_DEF_VAR_KEY=           'autocompletemin';
static const AUTOCOMPLETE_OPTIONS_DEF_VAR_KEY=              'autocomplete';
static const AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY=        'expand-include';
static const AUTO_CASE_KEYWORDS_DEF_VAR_KEY=                'autocase';
static const REFERENCED_IN_LANGUAGES_DEF_VAR_KEY=           'referenced-in';
static const CODEHELP_FLAGS_DEF_VAR_KEY=                    'codehelp';
static const COMMENT_EDITING_FLAGS_DEF_VAR_KEY=             'commentediting';
static const COMMENT_WRAP_OPTIONS_DEF_VAR_KEY=              'comment-wrap';
static const DOC_COMMENT_FLAGS_DEF_VAR_KEY=                 'doccomment';
static const INDENT_OPTIONS_DEF_VAR_KEY=                    'indent';
static const LOAD_FILE_OPTIONS_DEF_VAR_KEY=                 'load';
static const MENU_OPTIONS_DEF_VAR_KEY=                      'menu';
static const NUMBERING_STYLE_DEF_VAR_KEY=                   'numbering';
static const REAL_INDENT_DEF_VAR_KEY=                       'real-indent';
static const SAVE_FILE_OPTIONS_DEF_VAR_KEY=                 'save';
static const SELECTIVE_DISPLAY_OPTIONS_DEF_VAR_KEY=         'selective-display';
static const SMART_PASTE_DEF_VAR_KEY=                       'smartpaste';
static const SMART_TAB_DEF_VAR_KEY=                         'smarttab';
static const SURROUND_OPTIONS_DEF_VAR_KEY=                  'surround';
static const SURROUND_WITH_VERSION_DEF_VAR_KEY=             'surround-with-version';
static const SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY=           'symbolcoloring';
static const TAG_FILE_LIST_DEF_VAR_KEY=                     'tagfiles';
static const UPDATE_VERSION_DEF_VAR_KEY=                    'update-version';
static const USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY=           'adaptive-formatting';
static const XML_WRAP_OPTIONS_DEF_VAR_KEY=                  'xml-wrap';
static const BEAUTIFIER_PROFILE_DEF_VAR_KEY=                'beautifier-profile';
static const BEAUTIFIER_EXPANSIONS_DEF_VAR_KEY=             'beautifier-expansions';
static const LANGUAGE_TAB_CYCLES_INDENTS=                   'tab-cycles-indents';
static const ONE_LINE_AUTOBRACES_DEF_VAR_KEY=               'one-line-brackets';
static const CODE_MARGINS_DEF_VAR_KEY=                      'code-margins';
static const DIFF_COLUMNS_DEF_VAR_KEY=                      'diff-columns';


static typeless getDefaultDefVarValue(_str defVarKey, _str langID)
{
   typeless defaultValue;

   switch (defVarKey) {
   case ADAPTIVE_FORMATTING_FLAGS_DEF_VAR_KEY:
      defaultValue = def_adaptive_formatting_flags;
      break;
   case LOAD_FILE_OPTIONS_DEF_VAR_KEY:
   case MENU_OPTIONS_DEF_VAR_KEY:
   case SAVE_FILE_OPTIONS_DEF_VAR_KEY:
   case TAG_FILE_LIST_DEF_VAR_KEY:
   default:
      defaultValue = '';
      break;
   case ALIAS_EXPAND_ON_SPACE_DEF_VAR_KEY:
   case SMART_PASTE_DEF_VAR_KEY:
      defaultValue = true;
      break;
   case AUTOCOMPLETE_MIN_LENGTH_DEF_VAR_KEY:
      defaultValue = def_auto_complete_minimum_length;
      break;
   case AUTOCOMPLETE_OPTIONS_DEF_VAR_KEY:
      defaultValue = def_auto_complete_options;
      break;
   case CODEHELP_FLAGS_DEF_VAR_KEY:
      extra_codehelp_flag := VSCODEHELPFLAG_FIND_TAG_PREFERS_ALTERNATE;
      if (_FindLanguageCallbackIndex("_%s_analyze_return_type", langID) &&
          _FindLanguageCallbackIndex("_%s_get_expression_pos", langID)) {
         extra_codehelp_flag = VSCODEHELPFLAG_AUTO_LIST_VALUES;
      }
      defaultValue = def_codehelp_flags | extra_codehelp_flag;

      // do not insert parens for cobol
      if (langID == 'cob' || langID == 'cob74' || langID == 'cob2000') {
         defaultValue &= ~VSCODEHELPFLAG_INSERT_OPEN_PAREN;
      }
      break;
   case COMMENT_EDITING_FLAGS_DEF_VAR_KEY:
      defaultValue = VS_COMMENT_EDITING_FLAG_DEFAULT;
      if (!def_auto_javadoc_comment) {
         defaultValue &= ~VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_COMMENT;
         defaultValue &= ~VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT;
      }
      if (!def_auto_javadoc) {
         defaultValue &= ~VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK;
      }
      if (!def_auto_xmldoc_comment) {
         defaultValue &= ~VS_COMMENT_EDITING_FLAG_AUTO_XMLDOC_COMMENT;
      }
      if (!def_extend_linecomment) {
         defaultValue &= ~VS_COMMENT_EDITING_FLAG_EXTEND_LINE_COMMENTS;
      }
      if (!def_auto_linecomment) {
         defaultValue &= ~VS_COMMENT_EDITING_FLAG_SPLIT_LINE_COMMENTS;
      }
      if (!def_join_comments) {
         defaultValue &= ~VS_COMMENT_EDITING_FLAG_JOIN_COMMENTS;
      }
      if (!def_auto_string) {
         defaultValue &= ~VS_COMMENT_EDITING_FLAG_SPLIT_STRINGS;
      }
      break;
   case COMMENT_WRAP_OPTIONS_DEF_VAR_KEY:
      defaultValue = '0 1 0 1 1 64 0 0 80 0 80 0 80 0 0 1';
      break;
   case DOC_COMMENT_FLAGS_DEF_VAR_KEY:
      defaultValue = '';
      break;
   case AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY:
      defaultValue = AC_POUND_INCLUDE_NONE;
      break;
   case INDENT_OPTIONS_DEF_VAR_KEY:
      defaultValue = false;
      if (_LanguageInheritsFrom('py', langID)) {
         defaultValue = true;
      }
      break;
   case AUTO_CASE_KEYWORDS_DEF_VAR_KEY:
      if (_LanguageInheritsFrom('plsql', langID) || _LanguageInheritsFrom('pl1', langID)) {
         defaultValue = 1;
      } else {
         defaultValue = 0;
      }
      break;
   case NUMBERING_STYLE_DEF_VAR_KEY:
      defaultValue = 0;
      break;
   case REAL_INDENT_DEF_VAR_KEY:
      defaultValue = (def_enter_indent != 0);
      break;
   case SMART_TAB_DEF_VAR_KEY:
      {
         index:=find_index('def_smarttab',VAR_TYPE);
         if (!index) {
            defaultValue=2;
         } else {
            defaultValue = _get_var(index);
            if (!isinteger(defaultValue)) {
               defaultValue=2;
            }
         }
      }
      break;
   case SURROUND_OPTIONS_DEF_VAR_KEY:
      {
         index:=find_index('def_surround_mode_options',VAR_TYPE);
         if (!index) {
            defaultValue=0xFFFF;
         } else {
            defaultValue = _get_var(index);
            if (!isinteger(defaultValue)) {
               defaultValue=0xFFFF;
            }
         }
      }
      break;
   case SYMBOL_COLORING_OPTIONS_DEF_VAR_KEY:
      defaultValue = SYMBOL_COLOR_BOLD_DEFINITIONS |
                     SYMBOL_COLOR_SHOW_NO_ERRORS   |
                     SYMBOL_COLOR_DISABLED;
      break;
   case USE_ADAPTIVE_FORMATTING_DEF_VAR_KEY:
      defaultValue = def_adaptive_formatting_on;
      break;
   case XML_WRAP_OPTIONS_DEF_VAR_KEY:
      if (langID == 'docbook') {
         defaultValue = '1 1 'XW_NODEFAULTSCHEME;
      } else {
         defaultValue = '0 0 'XW_NODEFAULTSCHEME;;
      }
      break;

   case AUTOBRACKET_VAR_KEY:
      {
         switch (langID) {
         case 'fundamental':
         case 'binary':
         case 'process':
            defaultValue = AUTO_BRACKET_DEFAULT_OFF;
            break;
         case 'vbs':
            // disable single quote for vbscript
            defaultValue = AUTO_BRACKET_DEFAULT & ~AUTO_BRACKET_SINGLE_QUOTE;
            break;
         case 'c':
         case 'ansic':
            defaultValue = AUTO_BRACKET_DEFAULT_C_STYLE;
            break;
         case 'html':
         case 'cfml':
         case 'xml':
         case 'markdown':
            defaultValue = AUTO_BRACKET_DEFAULT_HTML_STYLE;
            break;
         case 'd':
         case 'lua':
         case 'phpscript':
         case 'pl':
         case 'as':
         case 'awk':
         case 'ch':
         case 'cs':
         case 'e':
         case 'java':
         case 'js':
         case 'jsl':
         case 'm':
         case 'py':
         case 'powershell':
            defaultValue = AUTO_BRACKET_DEFAULT_ON;
            break;
         default:
            defaultValue = AUTO_BRACKET_DEFAULT;
            break;
         }
      }
      break;

   case AUTOSURROUND_VAR_KEY:
      {
         switch (langID) {
         case 'vbs':
            // disable single quote for vbscript
            defaultValue = AUTO_BRACKET_DEFAULT & ~AUTO_BRACKET_SINGLE_QUOTE;
            break;
         case 'c':
         case 'ansic':
            defaultValue = AUTO_BRACKET_DEFAULT_C_STYLE;
            break;
         case 'html':
         case 'cfml':
         case 'xml':
         case 'markdown':
            defaultValue = AUTO_BRACKET_ENABLE|AUTO_BRACKET_DEFAULT_HTML_STYLE;
            break;
         default:
            defaultValue = AUTO_BRACKET_ENABLE|AUTO_BRACKET_DEFAULT;
            break;
         }
      }
      break;


   case DIFF_COLUMNS_DEF_VAR_KEY:
   case SELECTIVE_DISPLAY_OPTIONS_DEF_VAR_KEY:
      defaultValue = '0';
      break;
   case UPDATE_VERSION_DEF_VAR_KEY:
      defaultValue = '21.0.0';
      break;
   case CODE_MARGINS_DEF_VAR_KEY:
      if (_LanguageInheritsFrom('pl1', langID)) {
         defaultValue = '2 72';
      } else {
         defaultValue = '';
      }
   case SURROUND_WITH_VERSION_DEF_VAR_KEY:
      // see if we can find the old def-var that we used before this was lang-specific
      index := find_index('def-surround-version', MISC_TYPE);
      if (!index) {
         // it was never created, so just use 0
         defaultValue = 0;
      } else {
         // has been updated at least once before, find out what version
         value := name_info(index);
         if (isnumber(value)) {
            defaultValue = (int)value;
         } else {
            // no idea what happened here
            defaultValue = 0;
         }
      }
      break;
   }

   return defaultValue;
}
static _str getDefVarName(_str id, _str defVarKey) {
   switch (defVarKey) {
   //case AUTO_CASE_KEYWORDS_DEF_VAR_KEY:
   //case AUTOCOMPLETE_POUND_INCLUDE_DEF_VAR_KEY:
      // why is this one different?  one of life's great mysteries
   //   return('def-'id'-'defVarKey);
   //   break;
   default:
      // yup, it really is that simple
      return('def-'defVarKey'-'id);
      break;
   }

}
static typeless getDefVar(_str defVar, typeless defaultValue = null)
{
   // find our guy in the names table
   index := find_index(defVar, MISC_TYPE);

   if (index) {
      // it's there, so just return it
      return name_info(index);
   } else {
      // it is not there, so return a default value
      return defaultValue;
   }
}
static typeless getLanguageDefVar(_str langID, _str defVarKey, _str defaultValue = null)
{
   defVarName := getDefVarName(langID, defVarKey);
   typeless result = getDefVar(defVarName, defaultValue);
   if (result._isempty()) {
      return getDefaultDefVarValue(defVarKey, langID);
   }
   return result;
}
static _str old_getUpdateVersion(_str langId)
{
   return getLanguageDefVar(langId, UPDATE_VERSION_DEF_VAR_KEY);
}

static void _ansic_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   UpdateVersion := "15.0.1";
   if (_version_compare(UpdateVersion, old_getUpdateVersion('ansic')) > 0) {
      // "ANSIC" mode name changes to "ANSI-C" in 12.0
      if (_LangGetModeName('ansic') == 'ANSIC') {
         LanguageSettings.setModeName('ansic', 'ANSI-C');
      }
   }
}

static void _asm390_update_settings() {
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   UpdateVersion := "15.0.1";
   if (_version_compare(UpdateVersion, old_getUpdateVersion('asm390')) > 0) {
      // "OS/390" mode name changes to "IBM HLASM" in SE 2008
      if (LanguageSettings.getModeName('asm390') == 'OS/390 Assembler') {
         LanguageSettings.setModeName('asm390', 'IBM HLASM');
      }
   }

}

static void _cob_update_settings() {
   UpdateVersion := "16.0.1";
   if (_version_compare(UpdateVersion, old_getUpdateVersion('cob')) > 0) {
      // "Cobol" mode name changes to "Cobol 85" in 17.0
      if (LanguageSettings.getModeName('cob') == 'Cobol') {
         LanguageSettings.setModeName('cob', 'Cobol 85');
      }
   }
   /*if (_version_compare('18.0.0', old_getUpdateVersion('cob74')) > 0) {
      LanguageSettings.setAliasFilename('cob74', 'cob74.als.xml');
   }
   if (_version_compare('18.0.0', old_getUpdateVersion('cob2000')) > 0) {
      LanguageSettings.setAliasFilename('cob2000', 'cob2000.als.xml');
   } */
   if (_version_compare('19.0.0', old_getUpdateVersion('cob74')) > 0) {
      LanguageSettings.setLexerName('cob74', 'Cobol74');
   }
}
/**
 * Updates a keybinding in an event table.
 * 
 * @param eventtab               name of keytable or index of keytable in the 
 *                               names table
 * @param keyName                name of key that we are binding
 * @param oldCmd                 command that is currently bound to key - if 
 *                               this does not match the current binding, this
 *                               function does not create a new binding.  Use an
 *                               empty string to create a new binding
 * @param newCmd                 command that we want to bind to key.  Use an 
 *                               empty string to simply remove old binding.
 */
static void updateKeytab(typeless eventtab, _str keyName, _str oldCmd, _str newCmd)
{
   // find our event table
   eventtabIndex := 0;
   if (isinteger(eventtab)) {
      eventtabIndex = eventtab;
   } else {
      eventtabIndex = _eventtab_get_mode_keys(eventtab);
   }

   if (eventtabIndex) {

      // find the binding for this key
      keyIndex := eventtab_index(eventtabIndex, eventtabIndex, event2index(name2event(keyName)));

      // make sure it matches our old command, we don't want to go around unbinding things willy nilly
      if ((keyIndex == 0 && oldCmd == '') || name_name(keyIndex) == oldCmd) {

         // initialize this to 0, if we are not binding the key to a new command, this will 
         // just unbind the key
         newIndex := 0;
         if (newCmd != '') {
            newIndex = find_index(newCmd, COMMAND_TYPE);
         } 

         // set it and forget it
         set_eventtab_index(eventtabIndex, event2index(name2event(keyName)), newIndex);
      }
   }
}

static void _c_update_settings() {
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   UpdateVersion := "15.0.1";
   if (_version_compare(UpdateVersion, old_getUpdateVersion('c')) > 0) {
      // "C" mode name changes to "C/C++" in 12.0
      if (LanguageSettings.getModeName('c') == 'C') {
         LanguageSettings.setModeName('c', 'C/C++');
         updateDefFileTypesLabel('C Files', 'C/C++ Files');
      }

      // make sure that '(' is bound to c_paren in "C/C++" mode
      updateKeytab('c_keys', '(', 'auto-functionhelp-key', 'c-paren');
   }

   UpdateVersion = '20.0.1';
   if (_version_compare(UpdateVersion, old_getUpdateVersion('c')) > 0) {
      // update typo in def_file_types/def_find_file_types
      _str lt, rt;
      if (pos("C/C++ Files (*.c;*.cc;*.cpp;*.cp;*.cxx;*.c++;*.h;*.hh;*.hpp;*.hxx;h++;*.inl;*.xpm)", def_file_types)) {
         parse def_file_types with lt "C/C++ Files (*.c;*.cc;*.cpp;*.cppm;*.cp;*.cxx;*.c++;*.h;*.hh;*.hpp;*.hxx;h++;*.inl;*.ixx;*.xpm)" rt;
         def_file_types = lt :+ "C/C++ Files (*.c;*.cc;*.cpp;*.cppm;*.cp;*.cxx;*.c++;*.h;*.hh;*.hpp;*.hxx;*.h++;*.inl;*.ixx;*.xpm)" :+ rt;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      if (pos("C/C++ Files (*.c;*.cc;*.cpp;*.cp;*.cxx;*.c++;*.h;*.hh;*.hpp;*.hxx;h++;*.inl;*.xpm)", def_find_file_types)) {
         parse def_find_file_types with lt "C/C++ Files (*.c;*.cc;*.cpp;*.cppm;*.cp;*.cxx;*.c++;*.h;*.hh;*.hpp;*.hxx;h++;*.inl;*.ixx;*.xpm)" rt;
         def_find_file_types = lt :+ "C/C++ Files (*.c;*.cc;*.cpp;*.cppm;*.cp;*.cxx;*.c++;*.h;*.hh;*.hpp;*.hxx;*.h++;*.inl;*.ixx;*.xpm)" :+ rt;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
   }

   if (def_c_xmldoc :== '') {
      def_c_xmldoc = false;
   }
}

static void _docbook_update_settings() {
   updateXMLLanguages('docbook');
}

static void _dtd_update_settings() {
   updateXMLLanguages('dtd');
}

/**
 * Some updates that are common to XML-based languages.
 * 
 * @param langId                 language to update
 */
static void updateXMLLanguages(_str langId)
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', old_getUpdateVersion(langId)) > 0) {
      wordChars := LanguageSettings.getWordChars(langId);

      //Check for the case in 13.0.0 - 14.0.1 that had bad default word_chars and fix
      if (wordChars._length() > 3 && substr(wordChars, 1, 3) == 'WC=') {
         wordChars = substr(wordChars, 4);
         LanguageSettings.setWordChars(langId, wordChars);
      }
        
      if (!pos('\p', wordChars)) {
         LanguageSettings.setWordChars(langId, '\p{isXMLNameChar}?!');
      }

      keyTable := LanguageSettings.getKeyTableName(langId);
      if (keyTable == 'html-keys' || keyTable == 'html_keys') {
         LanguageSettings.setKeyTableName(langId, 'xml-keys');

         LanguageSettings.setIndentStyle(langId, INDENT_SMART);
      }
   }

}

static void _e_update_settings() {
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   UpdateVersion := "15.0.1";
   if (_version_compare(UpdateVersion, old_getUpdateVersion('e')) > 0) {
      // make sure that '(' is bound to slick_paren in "Slick-C" mode
      updateKeytab('slick_keys', '(', 'auto-functionhelp-key', 'slick-paren');
   }
}

static void _fundamental_update_settings() {
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   UpdateVersion := "15.0.1";
   if (_version_compare(UpdateVersion, old_getUpdateVersion(FUNDAMENTAL_LANG_ID)) > 0) {
      // v13 - "Fundamental" mode name changes to "Plain Text" in SE 2008
      if (LanguageSettings.getModeName(FUNDAMENTAL_LANG_ID) == 'Fundamental') {
         LanguageSettings.setModeName(FUNDAMENTAL_LANG_ID, 'Plain Text');
      }

      // add period and apostrophe to Plain Text word chars in 14.0.2
      wordChars := LanguageSettings.getWordChars(FUNDAMENTAL_LANG_ID);
      if (wordChars == "A-Za-z0-9_'$") {
         LanguageSettings.setWordChars(FUNDAMENTAL_LANG_ID, "A-Za-z0-9_'.$");
      }
   }
}

static void _html_update_settings() {
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   UpdateVersion := "15.0.1.2";
   if (_version_compare(UpdateVersion, old_getUpdateVersion('html')) > 0) {
      // html key table fix
      keyTable := LanguageSettings.getKeyTableName('html');
      if (keyTable == 'default-keys' || keyTable == '') {
         LanguageSettings.setKeyTableName('html', 'html_keys');
      }
   
      // fix the bindings for html_enter, html_space, html_lt and html_tab
      index := _eventtab_get_mode_keys('html-keys');
      if (index) {
         updateKeytab(index, 'ENTER', '', 'html-enter');
         updateKeytab(index, '<', '', 'html-lt');
         updateKeytab(index, ' ', '', 'html-space');
         //html-tab is new in v15.0.1.2
         updateKeytab(index, 'TAB', 'html-key', 'html-tab');
      }
   }
}

static void _java_update_settings() {
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', old_getUpdateVersion('java')) > 0) {
      // The old java setup up pointed to c-keys. We want to point to
      // java-keys now to get the extra java key bindings.
      keyTable := LanguageSettings.getKeyTableName('java');
      if (keyTable == 'c-keys' || keyTable == 'c_keys') {
         LanguageSettings.setKeyTableName('java', 'java-keys');
      }
   
      // make sure that '(' is bound to c_paren in "Java" mode
      updateKeytab('java_keys', '(', 'auto-functionhelp-key', 'c-paren');
   }
}

static void _m_update_settings() {
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', old_getUpdateVersion('m')) > 0) {
      // "OBJC" mode name changes to "Objective-C" in 12.0
      if (LanguageSettings.getModeName('m') == 'OBJC') {
         LanguageSettings.setModeName('m', 'Objective-C');
         updateDefFileTypesLabel('Object-C Files', 'Objective-C Files');
      }
   }
   if (_version_compare('16.1.0', old_getUpdateVersion('m')) > 0) {
      // Objective-C lexer changes to Objective-C in 17.0
      if (LanguageSettings.getLexerName('m') == 'cpp') {
         LanguageSettings.setLexerName('m', 'Objective-C');
      }
   }
}

static void _lua_update_settings() {
   if (_version_compare('17.0.0', old_getUpdateVersion('lua')) > 0) {
      // Binding for lua tab key to smarttab.
      updateKeytab('lua_keys', 'TAB', '', 'smarttab');
   }
}

static void _pas_update_settings(){
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', old_getUpdateVersion('pas')) > 0) {

      // in v15, we changed handling of pascal_begin 
      // undo these, this mechanism is handled in syntax expansion now
      index := _eventtab_get_mode_keys("pascal_keys");
      updateKeytab(index, 'n', 'pascal-n', '');
      updateKeytab(index, 'N', 'pascal-n', '');
      updateKeytab(index, 'd', 'pascal-d', '');
      updateKeytab(index, 'D', 'pascal-d', '');
      updateKeytab(index, 'y', 'pascal-y', '');
      updateKeytab(index, 'Y', 'pascal-y', '');
   }
}

static void _py_update_settings() {
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   // Binding for pyton tab key changed from python_tab to smarttab.  And then changed back again
   // in v19.
   pyVer := old_getUpdateVersion('py');
   if (_version_compare('20.1.0', pyVer) > 0) {
      updateKeytab(_eventtab_get_mode_keys('python-keys'), 'tab', 'smarttab', 'python-tab');
   }
}


static void _ruby_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', old_getUpdateVersion('ruby')) > 0) {
      // unbind this key
      updateKeytab('ruby_keys', '[', 'ruby-bracket', '');
   }
}

static void _sqlserver_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', old_getUpdateVersion('sqlserver')) > 0) {
   
      wordChars := LanguageSettings.getWordChars('sqlserver');
      if (wordChars == "A-Za-z0-9_$#@") {  // Byte regex search
         // Correct the old code page specific word characters
         wordChars='A-Za-z0-9_$#@\x{a5}\x{a3}';
         LanguageSettings.setWordChars('sqlserver', wordChars);
      }
   }
}

static void _tagdoc_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', old_getUpdateVersion('tagdoc')) > 0) {
      // "VSTagDoc" mode name changes to "SlickEdit Tag Docs" in 12.0
      if (LanguageSettings.getModeName('tagdoc') == 'VSTagDoc') {
         LanguageSettings.setModeName('tagdoc', 'SlickEdit Tag Docs');
      }
   }
}

static void _vbs_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', old_getUpdateVersion('vbs')) > 0) {

      // VBScript got its own event table and binding for SPACE, ENTER
      keyTable := LanguageSettings.getKeyTableName('vbs');
      if (keyTable != 'vbscript_keys') {
         LanguageSettings.setKeyTableName('vbs', 'vbscript-keys');
      }
   
      // fix the bindings for SPACE, ENTER
      index := _eventtab_get_mode_keys('vbscript-keys');
      if (index) {
         updateKeytab(index, 'ENTER', '', 'vbscript-enter');
         updateKeytab(index, ' ', '', 'vbscript-space');
      }
   }
   if (_version_compare('16.0.0', old_getUpdateVersion('vbs')) > 0) {
      flags := LanguageSettings.getAutoBracket('vbs');
      LanguageSettings.setAutoBracket('vbs', flags & ~AUTO_BRACKET_SINGLE_QUOTE);
   }
}

static void _bas_update_settings()
{
   if (_version_compare('16.0.0', old_getUpdateVersion('bas')) > 0) {
      flags := LanguageSettings.getAutoBracket('bas');
      LanguageSettings.setAutoBracket('bas', flags & ~AUTO_BRACKET_SINGLE_QUOTE);
   }
}

static void _vpj_update_settings() {
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', old_getUpdateVersion('vpj')) > 0) {
      updateXMLLanguages('vpj');
   
      _str list[];
      list[list._length()]='vpe';
      list[list._length()]='vpw';
      list[list._length()]='vpt';
      int i;
      for (i=0;i<list._length();++i) {
         if (!LanguageSettings.isLanguageDefined(list[i])) {
            _DeleteLanguageOptions(list[i]);
   
            refersTo := ExtensionSettings.getLangRefersTo(list[i]);
            if (refersTo == 'xml' || refersTo == null) {
               ExtensionSettings.setLangRefersTo(list[i], 'vpj');
            }
         }
      }
   }
}

static void _xsd_update_settings()
{
   updateXMLLanguages('xsd');
}


static void _xhtml_update_settings()
{
   updateXMLLanguages('xhtml');
}

static void _xmldoc_update_settings()
{
   updateXMLLanguages('xmldoc');
}

static void _xml_update_settings()
{
   updateXMLLanguages('xml');
}

static void _coffeescript_update_settings()
{
   // we added CoffeeScript in v18
   // set up def_file_types for upgrading users
   if (_version_compare('18.0.0', old_getUpdateVersion('coffeescript')) > 0) {
      addNewLanguageToDefFileTypes('CoffeeScript Files', '*.coffee');
   }
}

static void _googlego_update_settings()
{
   // we added CoffeeScript in v18
   // set up def_file_types for upgrading users
   if (_version_compare('18.0.0', old_getUpdateVersion('googlego')) > 0) {
      addNewLanguageToDefFileTypes('Google Go Files', '*.go');
   }
}

static void _ttcn3_update_settings()
{
   // we added TTCN-3 in v18
   // set up def_file_types for upgrading users
   if (_version_compare('18.0.0', old_getUpdateVersion('ttcn3')) > 0) {
      addNewLanguageToDefFileTypes('TTCN-3 Files', '*.ttcn');
   }
}
static void _UpgradeLanguageAliasExpansion(_str config_migrated_from_version)
{
   // if we did not upgrade from anything, don't worry about it
   if (config_migrated_from_version == '') return;

   // get the major version
   dotPos := pos('.', config_migrated_from_version);
   if (dotPos) {
      prevMajorVersion := (int)substr(config_migrated_from_version, 1, dotPos - 1);
      // we split alias expansion from syntax expansion in v15
      if (prevMajorVersion < 15) {
         _str langs[];
         LanguageSettings.getAllLanguageIds(langs);
         for (i := 0; i < langs._length(); i++) {
           langID := langs[i];
           synExp := LanguageSettings.getSyntaxExpansion(langID);
           LanguageSettings.setExpandAliasOnSpace(langID, synExp);
         }
      }
   }
}

static void _UpgradeAutoBracketSettings(_str config_migrated_from_version)
{
   // if we did not upgrade from anything, don't worry about it
   if (config_migrated_from_version == '') return;

   // get the major/minor version
   parse config_migrated_from_version with auto major '.' auto minor '.' auto revision '.' .;

   if (major <= 15 && revision < 1) {
      flags := 0;
      _str langs[];
      LanguageSettings.getAllLanguageIds(langs);
      for (i := 0; i < langs._length(); i++) {
        langID := langs[i];
        flags = LanguageSettings.getAutoBracket(langID);
        LanguageSettings.setAutoBracket(langID, flags | AUTO_BRACKET_BRACE);
      }

      flags = LanguageSettings.getAutoBracket('html');
      LanguageSettings.setAutoBracket('html', flags | AUTO_BRACKET_ANGLE_BRACKET);
      flags = LanguageSettings.getAutoBracket('xml');
      LanguageSettings.setAutoBracket('xml', flags | AUTO_BRACKET_ANGLE_BRACKET);
      flags = LanguageSettings.getAutoBracket('cfml');
      LanguageSettings.setAutoBracket('cfml', flags | AUTO_BRACKET_ANGLE_BRACKET);
   }

   if (major < 16) {
      flags := 0;
      flags = LanguageSettings.getAutoBracket('html');
      LanguageSettings.setAutoBracket('html', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('xml');
      LanguageSettings.setAutoBracket('xml', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('cfml');
      LanguageSettings.setAutoBracket('cfml', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('verilog');
      LanguageSettings.setAutoBracket('verilog', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('systemverilog');
      LanguageSettings.setAutoBracket('systemverilog', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('bas');
      LanguageSettings.setAutoBracket('bas', flags & ~AUTO_BRACKET_ENABLE);
   }
}
/**
 * If migrating from a version earlier than 17.0.2, clear out 
 * the visual c++ menu integration, because it can cause delays. 
 */
static void _UpgradeVCPPFlags(_str config_migrated_from_version)
{
   // if we did not upgrade from anything, don't worry about it
   if (config_migrated_from_version == '') return;

   // get the major/minor version
   parse config_migrated_from_version with auto major '.' auto minor '.' auto revision '.' .;

   // do this for 22.0.2 or earlier.  This flag used to be a reverse flag
   // (CTAGS_FLAGS_NO_LOCAL_DEFINES), as such, the option was turned on by
   // default.  The feature is helpful for a few users, and a problem for
   // several users, it is better for it to be off by default.  By reversing
   // the interpretation of the flag, it gets turned off for everyone who left
   // the setting alone, and this code makes sure the setting stays off for
   // the users who turned it off explicitly.
   if (major <= 22 && (def_ctags_flags & CTAGS_FLAGS_CPP_LOCAL_DEFINES)) {
      def_ctags_flags &= ~CTAGS_FLAGS_CPP_LOCAL_DEFINES;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // do this for 17.0.1 or earlier
   if (major > 17) return;
   if (major == 17 && minor > 0) return;
   if (major == 17 && revision >= 2) return;

   // clear the flag
   if (def_vcpp_flags & VCPP_ADD_VSE_MENU) {
      def_vcpp_flags &= ~(VCPP_ADD_VSE_MENU);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

#if 0
static _str alias_update_langs[] = {
   "c", "cs", "d", "docbook", "e", "html", "java", "js", "m", "pl", "xml",
   "docbook", "markdown"
};

static void removeOldAliasXML()
{
   src_path := _ConfigPath();
   filepath := _maybe_quote_filename(src_path'*.xml');
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
#endif

static int old_createAlias(_str profileName = '') {
   int handle = _xmlcfg_create('', VSENCODING_UTF8, VSXMLCFG_CREATE_IF_EXISTS_CREATE);
   if (handle < 0) {
      return handle;
   }
   profile := _xmlcfg_set_path(handle,"/profile");
   if (profile>=0 && profileName != '') {
      _xmlcfg_set_attribute(handle, profile, 'name', profileName);
   }
   return handle;
}
static _str old_getAliasLangProfileName(_str langID='')
{
   return (langID:=='') ? '' : '/language/':+langID:+'/aliases';
}

static void _se_duplicate_alias_file(_str oldAliasfilename, _str newAliasfilename, _str newProfileName)
{
   if (file_exists(newAliasfilename)) {
      return;
   }
   handle:= _xmlcfg_open(_maybe_quote_filename(oldAliasfilename), auto status, VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA, VSENCODING_UTF8);
   if (handle<0) return;
   //profile:=_xmlcfg_set_path(handle,'/profile');_xmlcfg_set_attribute(handle, profile, 'name', profileName);

   flags := VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL/*|VSXMLCFG_SAVE_REINDENT_PCDATA_RELATIVE*/;
   _xmlcfg_save(handle, -1, flags, newAliasfilename, VSENCODING_UTF8);

   _xmlcfg_close(handle);
}

static int _convert_alias_file_to_v21_profile(_str alias_filename,_str escapedPackage, _str profile) {
   handle:=_xmlcfg_open(alias_filename,auto status,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA, VSENCODING_UTF8);
   if (handle<0) {
      return handle;
   }
   AliasFile.initXml(handle,_plugin_append_profile_name(escapedPackage,profile),1);
   _convert_alias_text_to_v21_text(handle);
   _plugin_set_user_profile(handle);
   _xmlcfg_close(handle);
   return 0;
}

static _str alias_path_search(_str name)
{
   if (name=='') return('');
   if (pathlen(name)) {
      return(absolute(name));
   }
   local_filename := _ConfigPath():+name;
   if (file_exists(local_filename)) return(local_filename);
   return '';
}
static void updateSlickAlias()
{
   filename := get_env("VSLICKALIAS");
   if (filename == '') {
      filename = "alias.slk";
   }
   if (!pathlen(filename)) {
      filename = alias_path_search(filename);
      if (filename == '') {
         filename = _ConfigPath():+"alias.slk";
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
      if (newfilename != '') {
         if (!file_exists(newfilename) && file_exists(filename)) {
            _se_convert_v17_als_to_als_xml_file(filename, newfilename, '');
         }
         filename=newfilename;
      }
      _convert_alias_file_to_v21_profile(filename,VSCFGPACKAGE_MISC,VSCFGPROFILE_ALIASES);
   }
}
static void _UpgradeAliases(_str config_migrated_from_version)
{
   updateSlickAlias();

   // Convert all v17 files to the newer .als.xml format
   src_path := _ConfigPath();

   _str files[];
   filepath := _maybe_quote_filename(src_path'*.als');
   filename := file_match(filepath, 1);
   for (;;) {
      if (filename == '') break;
      files[files._length()] = filename;
      filename = file_match(filepath, 0);
   }
   for (i:=0;i<files._length();++i) {
      filename=files[i];
      extra := '';
      parse _strip_filename(filename, 'P') with auto lang '.als';
      if (endsWith(lang, '_symboltrans')) {
         lang = substr(lang, 1, length(lang)-length('_symboltrans'));
         extra = '/symboltrans';
      } else if (endsWith(lang, '_doccomment')) {
         // This name doesn't really matter. 
         // Only use filname suffux anyway.
         lang = substr(lang, 1, length(lang)-length('_doccomment'));
         extra = '/doccomment';
      }
      profile := old_getAliasLangProfileName(lang):+extra;
      oldfilename := filename;
      filename :+= '.xml';
      if (!file_exists(filename)) {
         _se_convert_v17_als_to_als_xml_file(oldfilename, filename, profile);
      }
      recycle_file(oldfilename);
   }

   // special case for cob, duplicate
   filename = file_match(src_path'cob.als.xml', 1);
   if (filename != '') {
      _se_duplicate_alias_file(src_path'cob.als.xml', src_path'cob74.als.xml', getAliasLangProfileName('cob74'));
      _se_duplicate_alias_file(src_path'cob.als.xml', src_path'cob2000.als.xml', getAliasLangProfileName('cob2000'));
   }
   // Now convert all the .als.xml files to v21 profiles

   files._makeempty();
   filepath = _maybe_quote_filename(src_path'*.als.xml');
   filename = file_match(filepath, 1);
   for (;;) {
      if (filename == '') break;
      files[files._length()] = filename;
      filename = file_match(filepath, 0);
   }
   for (i=0;i<files._length();++i) {
      filename=files[i];
      name:=_strip_filename(filename,'P');
      if (_file_eq(name,'alias.als.xml')) {
         recycle_file(filename);
         continue;
      }
      extra := '';
      parse _strip_filename(filename, 'P') with auto lang '.als.xml';
      _str profileName=VSCFGPROFILE_ALIASES;
      if (endsWith(lang, '_symboltrans')) {
         profileName=VSCFGPROFILE_SYMBOLTRANS_ALIASES;
         lang=substr(lang,1,length(lang)-12);
      } else if (endsWith(lang, '_doccomment')) {
         profileName=VSCFGPROFILE_DOC_ALIASES;
         lang=substr(lang,1,length(lang)-11);
      }
      // For now, assume that if this lang doesn't exist, 
      // it will exist after all the language info is converted.
      _str escapedPackage=vsCfgPackage_for_Lang(lang);
      _convert_alias_file_to_v21_profile(filename,escapedPackage,profileName);
      recycle_file(filename);
   }
}

// UPDATE AUTOMATICALLY INSERTED URL MAPPINGS
static void insertURLMapping(int handle, _str from, _str to)
{
   if (handle < 0) {
      return;
   }
   urlmappings_index := _xmlcfg_find_simple(handle,"/Options/URLMappings");
   if (urlmappings_index < 0) {
      urlmappings_index = _xmlcfg_set_path(handle,"/Options/URLMappings");
   }
   if (urlmappings_index < 0) {
      return;
   }

   // check for duplicates...
   xml_index := _xmlcfg_find_simple(handle, "//MapURL[@From='"from"']", urlmappings_index);
   if (xml_index < 0) {
      // no duplicate, so just add a new one
      xml_index = _xmlcfg_add(handle, urlmappings_index, "MapURL", VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(handle, xml_index, "From", from);
   }
   if (xml_index > 0) {
      _xmlcfg_set_attribute(handle, xml_index, "To", to);
   }
}
#if 0
static void upgradeURLMappingNames(_str version) {

   filename:= _ConfigPath():+"options.xml";

   if (!file_exists(filename)) return;

   int handle = _xmlcfg_open(filename, auto status);
   if (handle < 0) {
      return;
   }
   int list:[];
   typeless array[];
   _xmlcfg_find_simple_array(handle, "/Options/URLMappings/MapURL", array);
   foreach (auto node in array) {
      from := _xmlcfg_get_attribute(handle, node, 'From');
      if (from != '') {
         list:[from] = node;
      }
   }

   /* Automatically adding URL mappings causes extra configuration in user.cfg.xml.
      It's not worth it because these mappings look too old.
    */
   status = 0;
   UpdateVersion := "18.0.1.0"; 

   if (_isWindows()) {
      // searching for Microsoft.Build.xsd schema file
      if (_version_compare(UpdateVersion, version) > 0) {
         msbuildSchema := "http://schemas.microsoft.com/developer/msbuild/2003";
         if (!list._indexin(msbuildSchema)) {
            _str schemaFile;
            _str installDir;

            installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VS7', '', '12.0');
            if (installDir == '') {
               installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VS7', '', '11.0');
               if (installDir == '') {
                  installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VS7', '', '10.0');
                  if (installDir == '') {
                     installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VS7', '', '9.0');
                  }
               }
            }

            // check Express installs?


            if (installDir != '') {
               _maybe_append(installDir, FILESEP);
               schemaFile = installDir:+'Xml\Schemas\1033\Microsoft.Build.xsd';
               if (!file_exists(schemaFile)) {
                  schemaFile = '';
               }
            }

            if (schemaFile == '') {
               // try framework dir
               installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VC7', '', 'FrameworkDir64');
               if (installDir != '') {
                  frameworkVer := _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VC7', '', 'FrameworkVer64');
                  if (frameworkVer != '') {
                     _maybe_append(installDir, FILESEP);
                     installDir :+= frameworkVer; _maybe_append(installDir, FILESEP);
                     schemaFile = installDir:+'Microsoft.Build.xsd';
                     if (!file_exists(schemaFile)) {
                        schemaFile = '';
                     }
                  }
               }

               if (schemaFile == '') {
                  installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VC7', '', 'FrameworkDir32');
                  if (installDir != '') {
                     frameworkVer := _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VC7', '', 'FrameworkVer32');
                     if (frameworkVer != '') {
                        _maybe_append(installDir, FILESEP);
                        installDir :+= frameworkVer; _maybe_append(installDir, FILESEP);
                        schemaFile = installDir:+'Microsoft.Build.xsd';
                        if (!file_exists(schemaFile)) {
                           schemaFile = '';
                        }
                     }
                  }
               }
            }

            if (schemaFile != '') {
               insertURLMapping(handle, msbuildSchema, schemaFile);
               status = 1;
            }
         }
      }
   }

   if (status) {
      _xmlcfg_save(status,-1,0);
   }
   _xmlcfg_close(handle);
}
#endif

static void convert_options_xml_url_mappings() {
   filename:= _ConfigPath():+"options.xml";
   if (!file_exists(filename)) return;
   handle:=_xmlcfg_open(filename,auto status);
   if (handle<0) return;
   typeless array;
   _xmlcfg_find_simple_array(handle,"//MapURL",array);
   for (i:=0;i<array._length();++i) {
      int node=array[i];
      from:=_xmlcfg_get_attribute(handle,node,'From');
      to:=_xmlcfg_get_attribute(handle,node,'To');
      _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_URL_MAPPINGS,VSCFGPROFILE_URL_MAPPINGS_VERSION,from,to);
   }
   _xmlcfg_close(handle);
   recycle_file(filename);
}
static void _UpdateURLMappings()
{
#if 0
   UpdateVersion := "18.0.1.0";
   _str urlmap_version = getDefVar('def-url-mappings-version', '');
   if (_version_compare(UpdateVersion, urlmap_version) > 0) {
      upgradeURLMappingNames(urlmap_version);
      //setDefVar('def-url-mappings-version', _version());
   }
#endif
   index:=find_index('def-url-mappings-version',MISC_TYPE);
   if (index) {
      delete_name(index);
   }
   convert_options_xml_url_mappings();
}

static bool remove_tagfile_from_lang_list(_str &langTagFileList, _str tagFile, _str langId)
{
   // search for this file
   origTagFile := tagFile;
   tagFilePos := pos(PATHSEP :+ tagFile :+ PATHSEP, PATHSEP :+ langTagFileList :+ PATHSEP, 1, _fpos_case);
   if (!tagFilePos) {
      // try looking for it with the environment variables encoded
      tagFile = _encode_vsenvvars(origTagFile, true);
      tagFilePos = pos(PATHSEP :+ tagFile :+ PATHSEP, PATHSEP :+ langTagFileList :+ PATHSEP, 1, _fpos_case);
   }
   if (!tagFilePos) {
      // try looking for it with the environment variables encoded
      tagFile = _encode_vslickconfig(origTagFile, true, false, false);
      tagFilePos = pos(PATHSEP :+ tagFile :+ PATHSEP, PATHSEP :+ langTagFileList :+ PATHSEP, 1, _fpos_case);
   }

   // did we find it?
   if (tagFilePos) {
      // yes!
      --tagFilePos;

      // now remove it
      langTagFileList = substr(langTagFileList, 1, tagFilePos) :+ substr(langTagFileList, tagFilePos + length(tagFile) + 1);
      langTagFileList = stranslate(langTagFileList, '', PATHSEP :+ PATHSEP);
      langTagFileList = strip(langTagFileList, 'B', PATHSEP);

      // and set the new value
      LanguageSettings.setTagFileList(langId, _encode_vsenvvars(langTagFileList, true, false));

      return true;
   }

   // did not have this item
   return false;
}
static void _cleanup_old_tagfiles(_str old_config_dir)
{
   // list of automatically build tag files
   _str list[];
   bool tag_hash:[];
   _get_auto_generated_tagfile_names(list);
   for (i:=0; i < list._length(); i++) {
      tag_hash:[_file_case(list[i])] = true;
   }

   // close all the databases
   tag_close_all();

   // get paths to VSROOT, tagfiles directory, and old tagfiles directory
   _str vsroot=_getSlickEditInstallPath();
   _maybe_append_filesep(vsroot);
   _str tagfiles=_tagfiles_path();
   _maybe_append_filesep(tagfiles);
   _str oldfiles=old_config_dir;
   _maybe_append_filesep(oldfiles);
   oldfiles :+= "tagfiles":+FILESEP;

   // for each extension we have support loaded for
   _str tagFilesTable:[];
   LanguageSettings.getTagFileListTable(tagFilesTable);
   foreach (auto langId => auto langTagFileList in tagFilesTable) {

      // don't bother if there is nothing to remove
      if (langTagFileList._length() == 0) {
         continue;
      }

      // check each tag file if it is an auto-generated tag file
      tag_filename := next_tag_file(langTagFileList, true, false, false);
      while (tag_filename != "") {
         tag_basename := _strip_filename(tag_filename, 'P');
         if (tag_hash._indexin(_file_case(tag_basename))) {
            // check for tag file in VSROOT
            tag_filename = vsroot :+ tag_basename;
            if (remove_tagfile_from_lang_list(langTagFileList, tag_filename, langId)) {
               // it was in there, so we delete it
               if (file_exists(tag_filename)) delete_file(tag_filename);
            }

            // check for tag file in VSROOT/tagfiles, remove it if file doesn't exist
            tag_filename = vsroot :+ "tagfiles" :+ FILESEP :+ tag_basename;
            if (!file_exists(tag_filename)) {
               remove_tagfile_from_lang_list(langTagFileList, tag_filename, langId);
            }

            // check in old configuration directory
            tag_filename = oldfiles :+ tag_basename;
            if (remove_tagfile_from_lang_list(langTagFileList, tag_filename, langId)) {
               // remove the tag file from the *new* configuration directory
               tag_filename = tagfiles :+ list[i];
               if (file_exists(tag_filename)) delete_file(tag_filename);
            }

            // finally, to cover all bases, check in the new configuration directory
            tag_filename = tagfiles :+ tag_basename;
            if (remove_tagfile_from_lang_list(langTagFileList, tag_filename, langId)) {
               // remove the tag file from the *new* configuration directory
               if (file_exists(tag_filename)) delete_file(tag_filename);
            }
         }

         // next please
         tag_filename = next_tag_file(langTagFileList, false, false, false);
      }
   }

   // remove the tag files from the *new* configuration directory
   for (i=0;i<list._length();++i) {
      tag_filename := tagfiles:+list[i];
      if (file_exists(tag_filename)) {
         delete_file(tag_filename);
      }
   }
}
/*
<outlineviewdata>
  <scheme name="DocBook Sections Only">
    <rule nodetype="sect1" autoexpand="0">
      <![CDATA[Sect 1: (%xreflabel)]]>
    </rule>
    <rule nodetype="sect2" autoexpand="0">
      <![CDATA[Sect 2: (%xreflabel)]]>
    </rule>
  </scheme>
</outlineviewdata>

<options>
  <profile n="language.xml.outlineview_profiles.DocBook Sections Only" version="1">
     <p n="sect1" v="0;Sect 1: (%xreflabel)">
     <p n="sect1" v="0;Sect 1: (%xreflabel)">
  </profile>
</options>
*/
static void convert_xml_outline_schemes(_str filename) {
   handle:=_xmlcfg_open(filename,auto status);
   if (handle<0) {
      return;
   }
   typeless schemes[];
   _xmlcfg_find_simple_array(handle,"/outlineviewdata/scheme",schemes);
   for (i:=0;i<schemes._length();++i) {
      int node=schemes[i];
      _str profileName=_xmlcfg_get_attribute(handle,node,'name');
      if (profileName!='') {
         typeless rules[];
         _xmlcfg_find_simple_array(handle,"rule",rules,node);
         for (j:=0;j<rules._length();++j) {
            node= rules[j];
            _str name=_xmlcfg_get_attribute(handle,node,'nodetype');
            if (name!='') {
               _str autoexpand=_xmlcfg_get_attribute(handle,node,'autoexpand');
               if (autoexpand=='') autoexpand=0;
               node=_xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_CDATA);
               value:=_xmlcfg_get_value(handle,node);
               //say('p='profileName' n='name' v='value);
               _plugin_set_property(VSCFGPACKAGE_XMLOUTLINEVIEW_PROFILES, profileName,VSCFGPROFILE_XMLOUTLINEVIEW_VERSION,name,autoexpand:+';':+value);
            }
         }
      }

   }
   _xmlcfg_close(handle);
}
/*
<outlineviewschememap>
  <filemap>
  </filemap>
  <extensionmap>
    <schememapentry>
      <criteria>
        <![CDATA[docbook]]>
      </criteria>
      <schemename>
        <![CDATA[DocBook]]>
      </schemename>
    </schememapentry>
  </extensionmap>
  <filemap>
    <schememapentry>
      <criteria>
        <![CDATA[%VSROOT%sysconfig/options/options.xml]]>
      </criteria>
      <schemename>
        <![CDATA[SlickOptions]]>
      </schemename>
    </schememapentry>
  </filemap>
</outlineviewschememap>
 
<options>
    <profile "xmloutlineview.extensionmap" version="1">
       <p n="xml" v="profile"/>
    </profile>
    <profile "xmloutlineview_filemap" version="1">
        <p n="filename" v="profile_name/>
    </profile>
</options>
*/
static _str get_outlineview_cdata(int handle,int node,_str element) {
   node=_xmlcfg_find_child_with_name(handle,node,element);
   if (node<0) {
      return '';
   }
   node=_xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_CDATA);
   if (node<0) {
      return '';
   }
   return _xmlcfg_get_value(handle,node);
}
static void convert_xml_outline_scheme_map(_str filename) {
   handle:=_xmlcfg_open(filename,auto status);
   if (handle<0) {
      return;
   }
   typeless extmaps[];
   _xmlcfg_find_simple_array(handle,"/outlineviewschememap/extensionmap/schememapentry",extmaps);
   for (i:=0;i<extmaps._length();++i) {
      int node=extmaps[i];
      _str name=get_outlineview_cdata(handle,node,'criteria');
      _str value=get_outlineview_cdata(handle,node,'schemename');
      //say('n='name' v='value);
      _plugin_set_property(VSCFGPACKAGE_XMLOUTLINEVIEW, VSCFGPROFILE_XMLOUTLINEVIEW_EXTENSIONMAP,VSCFGPROFILE_XMLOUTLINEVIEW_VERSION,name,value);
   }

   _xmlcfg_find_simple_array(handle,"/outlineviewschememap/filemap/schememapentry",extmaps);
   for (i=0;i<extmaps._length();++i) {
      int node=extmaps[i];
      _str name=get_outlineview_cdata(handle,node,'criteria');
      _str value=get_outlineview_cdata(handle,node,'schemename');
      //say('n='name' v='value);
      _plugin_set_property(VSCFGPACKAGE_XMLOUTLINEVIEW, VSCFGPROFILE_XMLOUTLINEVIEW_FILEMAP,VSCFGPROFILE_XMLOUTLINEVIEW_VERSION,name,value);
   }

   _xmlcfg_close(handle);
}

static void convert_old_xmloutlineview_data() {

   _str path=_ConfigPath():+'formatschemes/outlineschemes/';
   _str filename;

   filename=path:+"outlineviewschemes.xml";
   if (file_exists(filename)) {
      convert_xml_outline_schemes(filename);
      recycle_file(filename);
   }
   filename=path:+"outlineviewschememap.xml";
   if (file_exists(filename)) {
      convert_xml_outline_scheme_map(filename);
      recycle_file(filename);
   }
   // Delete some unused config files. No need to convert these.
   path=_ConfigPath():+"formatschemes/xwschemes/";
   recycle_file(path:+"docbook.xml");
   recycle_file(path:+"html.xml");
   recycle_file(path:+"xhtml.xml");
   recycle_file(path:+"xml.xml");
   // Make sure no global find first handle is open. This may not be needed any more.
   file_match(_maybe_quote_filename(_ConfigPath()),1);
   rmdir(_ConfigPath():+'formatschemes/outlineschemes');
   rmdir(_ConfigPath():+'formatschemes/xwschemes');
   rmdir(_ConfigPath():+'formatschemes');
}
static void convert_old_beautifier_profiles() {
   ini_filename:=usercfg_path_search('uformat.ini');
   if (!file_exists(ini_filename)) {
      return;
   }
   // Convert to the new .cfg.xml languages settings
   module := "convert_uformat_ini.ex";
   filename := _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
   //_message_box('filename='filename);
   if (filename=='') {
      module='convert_uformat_ini.e';
      filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
      //_message_box('h2 filename='filename);
      if (filename=='') {
         filename='convert_uformat_ini';
      }
   }
   shell(_maybe_quote_filename(filename)' '_maybe_quote_filename(ini_filename));
   recycle_file(_ConfigPath():+'uformat.ini');
}
static void convert_ftp_ini() {
   _str name=(_isUnix()? "uftp.ini": "ftp.ini");
   ini_filename:=usercfg_path_search(name);
   if (!file_exists(ini_filename)) {
      return;
   }
   // Convert to the new .cfg.xml languages settings
   module := "convert_ftp_ini.ex";
   filename := _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
   //_message_box('filename='filename);
   if (filename=='') {
      module='convert_ftp_ini.e';
      filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
      //_message_box('h2 filename='filename);
      if (filename=='') {
         filename='convert_ftp_ini';
      }
   }
   shell(_maybe_quote_filename(filename)' '_maybe_quote_filename(ini_filename));
   recycle_file(_ConfigPath():+name);
}
static void convert_ubox_ini() {
   ini_filename:=usercfg_path_search('ubox.ini');
   if (!file_exists(ini_filename)) {
      return;
   }
   // Convert to the new .cfg.xml languages settings
   module := "convert_box_ini.ex";
   filename := _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
   //_message_box('filename='filename);
   if (filename=='') {
      module='convert_box_ini.e';
      filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
      //_message_box('h2 filename='filename);
      if (filename=='') {
         filename='convert_box_ini';
      }
   }
   shell(_maybe_quote_filename(filename)' '_maybe_quote_filename(ini_filename));
   recycle_file(_ConfigPath():+'ubox.ini');
}
static void convert_uprint_ini() {
   ini_filename:=usercfg_path_search('uprint.ini');
   if (!file_exists(ini_filename)) {
      return;
   }
   // Convert to the new .cfg.xml languages settings
   module := "convert_uprint_ini.ex";
   filename := _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
   //_message_box('filename='filename);
   if (filename=='') {
      module='convert_uprint_ini.e';
      filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
      //_message_box('h2 filename='filename);
      if (filename=='') {
         filename='convert_uprint_ini';
      }
   }
   shell(_maybe_quote_filename(filename)' '_maybe_quote_filename(ini_filename));
   recycle_file(_ConfigPath():+'uprint.ini');
}
static void convert_def_vc_providers() {
   // Convert to the new .cfg.xml languages settings
   module := "convert_def_vc_providers.ex";
   filename := _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
   //_message_box('filename='filename);
   if (filename=='') {
      module='convert_def_vc_providers.e';
      filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
      //_message_box('h2 filename='filename);
      if (filename=='') {
         filename='convert_def_vc_providers';
      }
   }
   shell(_maybe_quote_filename(filename));
   recycle_file(_ConfigPath():+'uservc.slk');
}
static void convert_user_vlx() {
   ini_filename:=usercfg_path_search('user.vlx');
   if (!file_exists(ini_filename)) {
      return;
   }
   cload(ini_filename);
   recycle_file(_ConfigPath():+'user.vlx');
}
static void misc_config_updates(_str config_migrated_from_version) {
   // 6.16.10 - 10583 - Added option to restore workspace when 
   // we start - defaults to TRUE
   if (config_migrated_from_version != '' && _version_compare(config_migrated_from_version, '15.0.1.0') < 0) {
      def_restore_flags |= RF_WORKSPACE;
   }
   // Added option to restore project tool window folders when we start - defaults to TRUE
   if (config_migrated_from_version != '' && _version_compare(config_migrated_from_version, '19.0.0.8') <= 0) {
      def_restore_flags |= RF_PROJECTS_TREE;
   }
   // Added option to restore tool-window layout when opening workspace - defaults to TRUE
   if ( config_migrated_from_version != '' && _version_compare(config_migrated_from_version, '19.0.0.9') <= 0 ) {
      def_restore_flags |= RF_PROJECT_LAYOUT;
   }

   // Made this option accessible by GUI, so include restrictions in the def-var so that it is settable
   if ( config_migrated_from_version != '' && _version_compare(config_migrated_from_version, '20.0.0.0') <= 0 ) {
      def_xml_no_schema_list :+= ' .xsd .xmldoc .xsl .xslt';
   }

   // Added option to automatically escape regex tokens for search text with init current word, selection options
   if ( config_migrated_from_version != '' && _version_compare(config_migrated_from_version, '20.0.1.0') <= 0 ) {
      def_mfsearch_init_flags |= MFSEARCH_INIT_AUTO_ESCAPE_REGEX;
   }
}
static void remove_old_eventtabs() {
   kt_name:='codehelp-keys';
   kt_index:=find_index(kt_name,EVENTTAB_TYPE);
   if (kt_index) delete_name(kt_index);
   kt_name='auto-complete-keys';
   kt_index=find_index(kt_name,EVENTTAB_TYPE);
   if (kt_index) delete_name(kt_index);
   kt_name='argument-completion-keys';
   kt_index=find_index(kt_name,EVENTTAB_TYPE);
   if (kt_index) delete_name(kt_index);
}
/**
 * Update the user's color scheme if it is out of date.
 */
static void _UpgradeColorScheme()
{
   // convert the uscheme.ini file to profiles if there is one.
   _convert_uscheme_ini();
   convert_current := false;
   index:=find_index('def_color_scheme_version',VAR_TYPE);
   if (index>0) {
      color_scheme_version:=_get_var(index);
      if (isinteger(color_scheme_version)) {
         if (color_scheme_version != COLOR_SCHEME_VERSION_DEFAULT &&
             color_scheme_version < COLOR_SCHEME_VERSION_CURRENT) {
            convert_current=true;
         }
      }
   }

   // remove the (modified) if it's there
   defaultProfile:=ColorScheme.getDefaultProfile();
   if (!_plugin_has_profile(VSCFGPACKAGE_COLOR_PROFILES,ColorScheme.realProfileName(defaultProfile))) {
      def_color_scheme='Default';// We are lost
   }
   if (convert_current) {
      // Convert from the default colors
      _convert_uscheme_ini('""');
   }
   // Create a profile for this colors
   DefaultColorsConfig dcc;
   dcc.loadFromDefaultColors();
   scm:=dcc.getCurrentProfile();
   if (dcc.isModifiedBuiltinProfile() && !_plugin_has_user_profile(VSCFGPACKAGE_COLOR_PROFILES,scm->m_name)) {
      // Since the user modified this built-in profile, create a profile for this
      scm->saveProfile();
   }
}

static void convert_etfaves_xml() {
   filename:=_ConfigPath():+'etfaves.xml';
   if (!file_exists(filename)) {
      return;
   }
   handle:=_xmlcfg_open(filename,auto status);
   if (handle>=0) {
      favorites_node:=_xmlcfg_get_first_child(handle,0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      _xmlcfg_set_name(handle,favorites_node,VSXMLCFG_PROPERTY);
      _xmlcfg_set_attribute(handle,favorites_node,VSXMLCFG_PROPERTY_NAME,'content');
      _plugin_set_property_xml(VSCFGPACKAGE_MISC, VSCFGPROFILE_EXPLORER_FAVORITES,VSCFGPROFILE_EXPLORER_FAVORITES_VERSION,'contents',handle);
      _xmlcfg_close(handle);
   }
   // Convert to the new .cfg.xml languages settings
   recycle_file(_ConfigPath():+'etfaves.xml');
}
static void convert_DateTimeFilters_xml() {
   filename:=_ConfigPath():+'DateTimeFilters.xml';
   if (!file_exists(filename)) {
      return;
   }
   _importDateTimeFilters(filename);
   // Convert to the new .cfg.xml languages settings
   recycle_file(_ConfigPath():+'DateTimeFilters.xml');
}
static void convert_def_register() {
    index:=find_index('def_register',MISC_TYPE);
    if (index) {
       _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_OPTIONS,VSCFGPROFILE_OPTIONS_VERSION,'registration_info',name_info(index));
       delete_name(index);
    }
}

static void convert_svcurl()
{
   def_svc_browser_url_list = null;
   filename:=_ConfigPath():+'svcURL.xml';
   if (!file_exists(filename)) {
      return;
   }
   xmlhandle := _xmlcfg_open(filename,auto status);
   if ( status ) return;
   
   // Find all top level tree nodes
   _xmlcfg_find_simple_array(xmlhandle,"/Tree/TreeNode",auto nodeList);
   len := nodeList._length();
   for (i:=0;i<len;++i) {
      // Collect all top level tree nodes in def_svc_browser_url_list
      curAttr := _xmlcfg_get_attribute(xmlhandle,(int)nodeList[i],"Cap");
      def_svc_browser_url_list :+= curAttr;
   }
   _xmlcfg_close(xmlhandle);
   //Don't recycle svcURL.xml since we still use it for auto-restore information.
   //recycle_file(_ConfigPath():+'svcURL.xml');
}

static void _maybe_append_path_to_envvar_value(_str &envvar_value,_str path) {
   if (path=='') return;
   int i;
   i=pos(path,PATHSEP:+envvar_value:+PATHSEP,1,_fpos_case);
   if (i>=1) {
      return;
   }
   if (_last_char(path)==FILESEP) {
      path=substr(path,1,length(path)-1);
   } else {
      path:+=FILESEP;
   }
   if (length(path)) {
      i=pos(path,PATHSEP:+envvar_value:+PATHSEP,1,_fpos_case);
      if (i>=1) {
         return;
      }
   }
   _maybe_append(envvar_value, PATHSEP);
   envvar_value:+=path;
}
static void _maybe_append_paths_to_envvar_value(_str &envvar_value,_str paths) {
   _str temp=paths;
   for (;;) {
      if (temp=='') return;
      parse temp with auto path (PATHSEP) temp;
      _maybe_append_path_to_envvar_value(envvar_value,path);

   }
}
static void convert_vslick_ini() {
   filename:=_ConfigPath():+'vslick.ini';
   if (!file_exists(filename)) {
      return;
   }
   status:=_ini_get_section(filename,"Environment",auto ini_wid);
   if (status) {
      return;
   }
   ini_wid.top();ini_wid.up();
   for (;;) {
      if (ini_wid.down()) {
         break;
      }
      ini_wid.get_line(auto line);
      line=strip(line,'L');
      if (line=='' || substr(line,1,1)==';') {
         continue;
      }
      parse line with auto name '=' auto value;
      value=_replace_envvars(value);
      if (env_eq(name,'VSLICKBIN')) {
         if (get_env('VSLICKBIN')!=value && pos(PATHSEP,value)) {
            envvar_value:=get_env('VSLICKBIN');
            _maybe_append_paths_to_envvar_value(envvar_value,value);
            value=envvar_value;
         } else {
            // This environment variable has not been modified.
            continue;
         }
      } else if (env_eq(name,'VSLICKPATH')) {
         if (get_env('VSLICKPATH')!=value) {
            envvar_value:=get_env('VSLICKPATH');
            _maybe_append_paths_to_envvar_value(envvar_value,value);
            value=envvar_value;
         }
      }
      _ConfigEnvVar(name,value,_encode_vsenvvars(value,false,false));
   }
   _delete_temp_view(ini_wid);
   recycle_file(filename);
}
static void apply_environment_profile() {
   handle:=_plugin_get_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_ENVIRONMENT);
   if (handle<0) return;
   profile_node:=_xmlcfg_get_first_child_element(handle);
   if (profile_node>=0) {
      property_node:=_xmlcfg_get_first_child_element(handle,profile_node);
      while (property_node>=0) {
         name:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME);
         value:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_VALUE);
         set_env(name,value);
         property_node=_xmlcfg_get_next_sibling_element(handle,property_node);
      }
   }
}
static void convert_def_loadall() { 
   index:=find_index('def_max_loadall',VAR_TYPE);
   if (!index) return;
   typeless t=_get_var(index);
   if (t._varformat()!=VF_LSTR) {
      return;
   }
   parse t with auto on auto ksize;
   if (isinteger(on) && isinteger(ksize)) {
      def_load_partial= on!=0;
      def_load_partial_ksize=(int)ksize;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_one_ksize_def_var(_str name,int &new_var,int divide_by=1,int multiple_by=1,int option=0) { 
   index:=find_index(name,VAR_TYPE);
   if (!index) return;
   typeless t=_get_var(index);
   if (!isinteger(t)) {
      if (option==1) {
         new_var=0;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      return;
   }
   if (t > 0 && t < divide_by) t=divide_by;
   new_var=(t intdiv divide_by)*multiple_by;
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_to_ksize_options() {
   convert_one_ksize_def_var('def_tagging_cache_size',def_tagging_cache_ksize);
   convert_one_ksize_def_var('def_tagging_cache_max',def_tagging_cache_max_ksize);
   convert_one_ksize_def_var('def_background_tagging_maximum_kbytes',def_background_tagging_max_ksize);
   convert_one_ksize_def_var('def_update_context_max_file_size',def_update_context_max_ksize,1024 /* previously in bytes */);
   convert_one_ksize_def_var('def_update_statements_max_file_size',def_update_statements_max_ksize,1024 /* previously in bytes */);
   convert_one_ksize_def_var('def_update_tokenlist_max_file_size',def_update_tokenlist_max_ksize,1024 /* previously in bytes */);
   convert_one_ksize_def_var('def_max_autosave',def_max_autosave_ksize);
   convert_one_ksize_def_var('def_max_mffind_output',def_max_mffind_output_ksize,1024 /* previously in bytes */);
   convert_one_ksize_def_var('def_maxbackup',def_maxbackup_ksize,1024 /* previously in bytes */, 1, 1 /* set to 0 if invalid setting */);
   convert_one_ksize_def_var('def_autoreload_compare_contents_max_size',def_autoreload_compare_contents_max_ksize,1024 /* previously in bytes */);
   convert_one_ksize_def_var('def_background_mfsearch_kbufsize',def_background_mfsearch_ksize);
   convert_one_ksize_def_var('def_copy_to_clipboard_warn_mbsize',def_copy_to_clipboard_warn_ksize,1,1024 /* previously in megabytes */);
   convert_one_ksize_def_var('def_word_completion_kmax',def_word_completion_max_ksize);
   convert_one_ksize_def_var('def_pmatch_max_kfile_size',def_pmatch_max_ksize);
   convert_one_ksize_def_var('def_pmatch_max_diff',def_pmatch_max_diff_ksize,1024 /* previously in bytes */);
   convert_one_ksize_def_var('def_xml_max_smart_editing',def_xml_max_smart_editing_ksize,1024 /* previously in bytes */);
}
static void convert_searches_xml(_str xml_file='') {
   do_recycle := false;
   if (xml_file=='') {
      xml_file = _ConfigPath() :+ "searches.xml";
      do_recycle=true;
   }
   if (!file_exists(xml_file)) {
      return;
   }
   // Convert to the new .cfg.xml languages settings
   module := "convert_searches_xml.ex";
   filename := _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
   //_message_box('filename='filename);
   if (filename=='') {
      module='convert_searches_xml.e';
      filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
      //_message_box('h2 filename='filename);
      if (filename=='') {
         filename='convert_searches_xml';
      }
   }
   shell(_maybe_quote_filename(filename)' '_maybe_quote_filename(xml_file));
   if (do_recycle) {
      recycle_file(_ConfigPath():+'searches.xml');
   }
}
static void convert_def_cvs_info() {
   index:=find_index('def_cvs_info',VAR_TYPE);
   if (!index) return;
   typeless t=_get_var(index);
   if (t==null || (t._varformat()!=VF_OBJECT && t._varformat()!=VF_ARRAY) || t._length()<1 || t[0]._varformat()!=VF_LSTR) {
      return;
   }
   def_cvs_exe_path=t[0];  // Get the exe name field
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_def_svn_info() {
   index:=find_index('def_svn_info',VAR_TYPE);
   if (!index) return;
   typeless t=_get_var(index);
   if (t==null || (t._varformat()!=VF_OBJECT && t._varformat()!=VF_ARRAY) || t._length()<1 || t[0]._varformat()!=VF_LSTR) {
      return;
   }
   def_svn_exe_path=t[0];  // Get the exe name field
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_def_perforce_info() {
   index:=find_index('def_perforce_info',VAR_TYPE);
   if (!index) return;
   typeless t=_get_var(index);
   if (t==null || (t._varformat()!=VF_OBJECT && t._varformat()!=VF_ARRAY) || t._length()<1 || t[0]._varformat()!=VF_LSTR) {
      return;
   }
   def_perforce_exe_path=t[0];  // Get the exe name field
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_def_git_info() {
   index:=find_index('def_git_info',VAR_TYPE);
   if (!index) return;
   typeless t=_get_var(index);
   if (t==null || (t._varformat()!=VF_OBJECT && t._varformat()!=VF_ARRAY) || t._length()<1 || t[0]._varformat()!=VF_LSTR) {
      return;
   }
   def_git_exe_path=t[0];  // Get the exe name field
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_def_hg_info() {
   index:=find_index('def_hg_info',VAR_TYPE);
   if (!index) return;
   typeless t=_get_var(index);
   if (t==null || (t._varformat()!=VF_OBJECT && t._varformat()!=VF_ARRAY) || t._length()<1 || t[0]._varformat()!=VF_LSTR) {
      return;
   }
   def_hg_exe_path=t[0];  // Get the exe name field
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_def_workspace_options() {
   index:=find_index('def_workspace_options',VAR_TYPE);
   if (!index) return;
   def_workspace_flags = (WorkspaceHistoryOptions) _get_var(index);
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_def_diff_options() {
   index:=find_index('def_diff_options',VAR_TYPE);
   if (!index) return;
   def_diff_flags=_get_var(index);
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_def_diff_edit_options() {
   index:=find_index('def_diff_edit_options',VAR_TYPE);
   if (!index) return;
   def_diff_edit_flags=_get_var(index);
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_def_re_search() {
   index:=find_index('def_re_search',VAR_TYPE);
   if (!index) return;
   def_re_search_flags=_get_var(index);
   // IF we have a 2.0 constant value for UNIXRE_SEARCH
   if (def_re_search_flags & 0x80) {
      // convert it to the new 3.0 value
      def_re_search_flags=PERLRE_SEARCH;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
static void convert_def_find_file_attr_flags() {
   index:=find_index('def_find_file_attr_flags',VAR_TYPE);
   if (!index) return;
   def_find_file_attr_options=_get_var(index);
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

static void convert_def_opentb_views() {
   index:=find_index('def_opentb_views',VAR_TYPE);
   if (!index) return;
   def_opentb_view_flags=_get_var(index);
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

static void convert_def_opentb_options() {
   index:=find_index('def_opentb_options',VAR_TYPE);
   if (!index) return;
   def_opentb_flags=_get_var(index);
   if ( def_opentb_flags&OPENTB_PREFIX_MATCH ) {
      def_opentb_non_wc_match_style = OPENTB_WC_RECURSIVE_PREFIX_MATCHING;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

static void convert_def_vi_show_msg() {
   if (def_keys=='vi-keys') return;
   index:=find_index('def_vi_show_msg',VAR_TYPE);
   if (!index) return;
   value:=_get_var(index);
   if (value==0) {
      _set_var(index,1);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}
// Want def_cua_textbox = 0 or 1
static void convert_def_cua_textbox() {
   index:=find_index('def_cua_textbox',VAR_TYPE);
   if (!index) return;
   value:=_get_var(index);
   if (!isinteger(value)) {
      _set_var(index,1);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}
// Want def_change_dir = 0 or 1 (not 4==OFN_CHANGEDIR)
static void convert_def_change_dir() {
   index:=find_index('def_change_dir',VAR_TYPE);
   if (!index) return;
   value:=_get_var(index);
   if (value) {
      _set_var(index,1);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

// Want def_exit_process = 0 or 1
static void convert_def_exit_process() {
   index:=find_index('def_exit_process',VAR_TYPE);
   if (!index) return;
   value:=_get_var(index);
   if (value) {
      _set_var(index,1);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

static _str diffSessionDefaults:[] = {
   "ReadOnly1"=>"0",
   "ReadOnly2"=>"0",
   "Quiet"=>"0",
   "Interleaved"=>"0",
   "Modal"=>"0",
   "File1IsBuffer"=>"0",
   "File2IsBuffer"=>"0",
   "File1IsDisk"=>"0",
   "File2IsDisk"=>"0",
   "File1UseDisk"=>"0",
   "File2UseDisk"=>"0",
   "NoMap"=>"0",
   "Preserve1"=>"0",
   "Preserve2"=>"0",
   "BufferIndex1"=>"-1",
   "BufferIndex2"=>"-1",
   "ViewId1"=>"0",
   "ViewId2"=>"0",
   "ViewOnly"=>"0",
   "Comment"=>"",
   "CommentButtonCaption"=>"",
   "File1Title"=>"",
   "File2Title"=>"",
   "DialogTitle"=>"DIFFzilla® Pro",
   "File1Name"=>"",
   "File2Name"=>"",
   "FileSpec"=>"",
   "ExcludeFileSpec"=>"",
   "Recursive"=>0,
   "ImaginaryLineCaption"=>"Imaginary Buffer Line",
   "AutoClose"=>"0",
   "File1FirstLine"=>"0",
   "File1LastLine"=>"0",
   "File2FirstLine"=>"0",
   "File2LastLine"=>"0",
   "RecordFileWidth"=>"0",
   "ShowAlways"=>"0",
   "ParentWIDToRegister"=>"0",
   "OkPtr"=>"",
   "DiffTags"=>"0",
   "FileListInfo"=>"",
   "DiffStateFile"=>"",
   "CompareOnly"=>"0",
   "SaveButton1Caption"=>"",
   "SaveButton2Caption"=>"",
   "Symbol1Name"=>"",
   "Symbol2Name"=>"",
   "SetOptionsOnly"=>"0",
   "sessionName"=>"[unnamed]",
   "sessionDate"=>"",
   "compareOptions"=>"0",
   "fileListFile"=>"",
};

static void renameAttribute(int diffSessionHandle,int index,_str oldName,_str newName,_str &value="")
{
   value = _xmlcfg_get_attribute(diffSessionHandle,index,oldName);
   _xmlcfg_set_attribute(diffSessionHandle,index,newName,value);
   _xmlcfg_delete_attribute(diffSessionHandle,index,oldName);
}

static void convertProperties(int diffSessionHandle,int curIndex,INTARRAY &delArray)
{
   childIndex := _xmlcfg_get_first_child(diffSessionHandle,curIndex);
   for ( ;childIndex>=0; ) {
      _xmlcfg_set_name(diffSessionHandle,childIndex,"p");
      // Change from "Name=" to "n=" and "Value=" to "v=".
      // We have to get the name and value before we decide if we delete it 
      // anyway, so just go ahead and rename the name and value attributes
      renameAttribute(diffSessionHandle,childIndex,"Name","n",auto propName);
      renameAttribute(diffSessionHandle,childIndex,"Value","v",auto value);
      if ( diffSessionDefaults:[propName]==value ) {
         // Check to see if this value is a default value and we can delete it
         ARRAY_APPEND(delArray,childIndex);
      }
      childIndex = _xmlcfg_get_next_sibling(diffSessionHandle,childIndex);
   }
}

/** 
 * For v21 we made changes to the diff sessions to put them in the user.cfg.xml 
 * file.  We decided against putting the sessions in the configuration, but 
 * kept the upgrades to the session file. 
 */
static void upgrade_diff_sessions() {
   diffSessionFilename:=_ConfigPath():+'diffsession.xml';
   diffSessionHandle := _xmlcfg_open(diffSessionFilename,auto status);
   if ( status<0 ) {
      return;
   }
   sessionsIndex := _xmlcfg_get_first_child(diffSessionHandle,TREE_ROOT_INDEX);
   if ( sessionsIndex<0 ) return;
   version := _xmlcfg_get_attribute(diffSessionHandle,sessionsIndex,"version");
   if ( version==1 ) return;
   status = _xmlcfg_find_simple_array(diffSessionHandle,"/Sessions/OneSession",auto indexArray);
   if ( !status ) {
      len := indexArray._length();
      INTARRAY delArray;
      // Change from "Name=" to "n="
      for (i:=0;i<len;++i) {
         curIndex := (int)indexArray[i];
         deleteThisProperty := false;
         renameAttribute(diffSessionHandle,curIndex,"Name","n");

         // Convert all of the properties under this session
         convertProperties(diffSessionHandle,curIndex,delArray);
      }

      // Delete any properties that were actually default values
      len = delArray._length();
      for (i=len-1;i>=0;--i) {
         _xmlcfg_delete(diffSessionHandle,delArray[i]);
      }
   }
   // Set a version number for the file format
   _xmlcfg_set_attribute(diffSessionHandle,sessionsIndex,"version",1);
   status = _xmlcfg_save(diffSessionHandle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
   _xmlcfg_close(diffSessionHandle);
}

#if 0
// 9/6/2016 - We have made the decision not to move named sessions into
//            user.cfg.xml.  Saving this code for now in case it ever
//            becomes practical in the future.
static void convert_diff_sessions() {
   diffSessionFilename:=_ConfigPath():+'diffsession.xml';
   diffSessionHandle := _xmlcfg_open(diffSessionFilename,auto status);
   if ( status<0 ) {
      return;
   }
   status = _xmlcfg_find_simple_array(diffSessionHandle,"/Sessions/OneSession",auto indexArray);
   if ( !status ) {
      len := indexArray._length();
      diffProfileHandle := _xmlcfg_create_profile(auto diffProfileIndex,VSCFGPACKAGE_MISC,'diff_sessions',1);
      // Define a specialized profile element. Better for validation.
      _xmlcfg_set_name(diffProfileHandle,diffProfileIndex,'misc.diff_sessions');
      _xmlcfg_set_attribute(diffProfileHandle,diffProfileIndex,'version',1);
      propertyIndex :=_xmlcfg_add(diffProfileHandle,diffProfileIndex,'contents',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      for (i:=0;i<len;++i) {
         name := _xmlcfg_get_attribute(diffSessionHandle,(int)indexArray[i],"Name");
         sessionID := _xmlcfg_get_attribute(diffSessionHandle,(int)indexArray[i],"sessionId");
         if (name != "[unnamed]" ) {
            sessionIndex := _xmlcfg_add(diffProfileHandle,propertyIndex,"OneSession",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
            _xmlcfg_set_attribute(diffProfileHandle,sessionIndex,"n",name);
            _xmlcfg_set_attribute(diffProfileHandle,sessionIndex,"sessionId",sessionID);
            addContent(diffSessionHandle,(int)indexArray[i],diffProfileHandle,sessionIndex,name);
         }
      }
      _plugin_set_profile(diffProfileHandle);
      _xmlcfg_close(diffProfileHandle);
   }
   convertDiffSessions(diffSessionHandle,indexArray);
   _xmlcfg_save(diffSessionHandle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
   _xmlcfg_close(diffSessionHandle);
}

static void addContent(int diffSessionHandle,int sessionIndex,
                       int diffProfileHandle,int contentIndex,_str name) {
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"ReadOnly1","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"ReadOnly2","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"Quiet","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"Interleaved","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"Modal","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File1IsBuffer","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File2IsBuffer","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File1IsDisk","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File2IsDisk","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File1UseDisk","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File2UseDisk","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"NoMap","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"Preserve1","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"Preserve2","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"BufferIndex1","-1");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"BufferIndex2","-1");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"ViewId1","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"ViewId2","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"ViewOnly","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"Comment","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"CommentButtonCaption","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File1Title","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File2Title","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"DialogTitle","DIFFzilla® Pro");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File1Name","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File2Name","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"FileSpec","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"ExcludeFileSpec","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"Recursive",0);
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"ImaginaryLineCaption","Imaginary Buffer Line");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"AutoClose","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File1FirstLine","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File1LastLine","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File2FirstLine","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"File2LastLine","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"RecordFileWidth","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"ShowAlways","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"ParentWIDToRegister","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"OkPtr","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"DiffTags","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"FileListInfo","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"DiffStateFile","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"CompareOnly","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"SaveButton1Caption","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"SaveButton2Caption","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"Symbol1Name","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"Symbol2Name","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"SetOptionsOnly","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"sessionName","[unnamed]");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"sessionDate","");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"compareOptions","0");
   transferDiffSessionProperty(diffSessionHandle,sessionIndex,diffProfileHandle,contentIndex,"fileListFile","");
}

static void transferDiffSessionProperty(int diffSessionHandle,
                                        int sessionIndex,
                                        int diffProfileHandle,
                                        int contentIndex,
                                        _str propertyName,
                                        _str defaultValue) {
   propertyIndex := _xmlcfg_find_simple(diffSessionHandle,"Property[@Name='"propertyName"']",sessionIndex);
   if ( propertyIndex>-1 ) {
      propertyValue := _xmlcfg_get_attribute(diffSessionHandle,propertyIndex,"Value");
      if ( propertyValue!=defaultValue ) {
         nodeIndex := _xmlcfg_add(diffProfileHandle,contentIndex,'p',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(diffProfileHandle,nodeIndex,'n',propertyName);
         _xmlcfg_set_attribute(diffProfileHandle,nodeIndex,'v',propertyValue);
      }    
   }
}

static void convertDiffSessions(int diffSessionHandle,STRARRAY &indexArray) {
   len := indexArray._length();
   for (i:=0;i<len;++i) {
      name := _xmlcfg_get_attribute(diffSessionHandle,(int)indexArray[i],"Name");
      if (name != "[unnamed]" ) {
         _xmlcfg_delete(diffSessionHandle,(int)indexArray[i]);
      } else {
         _xmlcfg_delete_attribute(diffSessionHandle,(int)indexArray[i],"Name");
         _xmlcfg_set_attribute(diffSessionHandle,(int)indexArray[i],"n",name);
         resetProperty(diffSessionHandle,(int)indexArray[i],"ReadOnly1","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"ReadOnly2","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"Quiet","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"Interleaved","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"Modal","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File1IsBuffer","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File2IsBuffer","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File1IsDisk","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File2IsDisk","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File1UseDisk","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File2UseDisk","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"NoMap","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"Preserve1","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"Preserve2","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"BufferIndex1","-1");
         resetProperty(diffSessionHandle,(int)indexArray[i],"BufferIndex2","-1");
         resetProperty(diffSessionHandle,(int)indexArray[i],"ViewId1","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"ViewId2","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"ViewOnly","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"Comment","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"CommentButtonCaption","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File1Title","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File2Title","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"DialogTitle","DIFFzilla® Pro");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File1Name","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File2Name","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"FileSpec","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"ExcludeFileSpec","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"Recursive",0);
         resetProperty(diffSessionHandle,(int)indexArray[i],"ImaginaryLineCaption","Imaginary Buffer Line");
         resetProperty(diffSessionHandle,(int)indexArray[i],"AutoClose","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File1FirstLine","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File1LastLine","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File2FirstLine","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"File2LastLine","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"RecordFileWidth","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"RecordWidth","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"ShowAlways","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"ParentWIDToRegister","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"OkPtr","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"DiffTags","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"FileListInfo","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"DiffStateFile","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"CompareOnly","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"SaveButton1Caption","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"SaveButton2Caption","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"Symbol1Name","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"Symbol2Name","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"SetOptionsOnly","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"sessionName","[unnamed]");
         resetProperty(diffSessionHandle,(int)indexArray[i],"sessionDate","");
         resetProperty(diffSessionHandle,(int)indexArray[i],"compareOptions","0");
         resetProperty(diffSessionHandle,(int)indexArray[i],"fileListFile","");
      }
   }
}

static void resetProperty(int diffSessionHandle,
                          int sessionIndex,
                          _str propertyName,
                          _str defaultValue) {
   propertyIndex := _xmlcfg_find_simple(diffSessionHandle,"Property[@Name='"propertyName"']",sessionIndex);
   if ( propertyIndex>-1 ) {
      propertyValue := _xmlcfg_get_attribute(diffSessionHandle,propertyIndex,"Value");
      if ( propertyValue!=defaultValue ) {
         nodeIndex := _xmlcfg_add(diffSessionHandle,sessionIndex,'p',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(diffSessionHandle,nodeIndex,'n',propertyName);
         _xmlcfg_set_attribute(diffSessionHandle,nodeIndex,'v',propertyValue);
      }    
      _xmlcfg_delete(diffSessionHandle,propertyIndex);
   }
}
#endif 

static void convert_filelist_options()
{
   index:=find_index('def_filelist_options',VAR_TYPE);
   if (!index) return;
   def_filelist_flags = _get_var(index);
   if ( def_filelist_flags&FILELIST_PREFIX_MATCH ) {
      def_filelist_non_wc_match_style = OPENTB_WC_RECURSIVE_PREFIX_MATCHING;
   }
}

static void _xlat_config_paths_in_compilers_xml(_str config_migrated_from_version) {

   status:=_open_temp_view(_ConfigPath():+COMPILER_CONFIG_FILENAME,auto temp_wid,auto orig_wid);
   if (status) {
      return;
   }
   _str path=_ConfigPath();
   if (_last_char(path):==FILESEP) {
      path=substr(path,1,length(path)-1);
      path=_strip_filename(path,'N');
   }
   search_for:=path:+config_migrated_from_version:+FILESEP;
   replace_with:=_ConfigPath();
   status=search(search_for,_fpos_case,replace_with);
   if (!status) {
      status=_save_file('+o '_maybe_quote_filename(p_buf_name));

   }
   _delete_temp_view(temp_wid);
   p_window_id=orig_wid;
}

defmain()
{
   config_migrated_from_version:=arg(1);
   _str major;
   if (config_migrated_from_version != "") {
      // Avoid homogonizing the user's brace settings for anything other 
      // than a version upgrade from a pre-new-beautifier version.
      parse config_migrated_from_version with major '.' auto minor '.' auto revision '.' .;
   }


   remove_old_eventtabs();
   _update_profiles_for_modified_eventtabs();
   if (config_migrated_from_version!='') {
      if (major<21) {
         _config_modify_flags(CFGMODIFY_DEFVAR);
         convert_searches_xml();
         convert_to_ksize_options();
         convert_def_vi_show_msg();
         convert_def_cua_textbox();
         convert_def_change_dir();
         convert_def_exit_process();
         convert_def_find_file_attr_flags();
         convert_def_opentb_views();
         convert_def_opentb_options();
         convert_def_re_search();
         convert_def_vc_providers();
         recycle_file(_ConfigPath():+'notifications.xml');
         convert_def_diff_options();
         convert_def_diff_edit_options();
         convert_def_workspace_options();
         convert_def_cvs_info();
         convert_def_svn_info();
         convert_def_perforce_info();
         convert_def_git_info();
         convert_def_hg_info();
         convert_vslick_ini();
         convert_svcurl();
         misc_config_updates(config_migrated_from_version);
         _UpgradeAliases(config_migrated_from_version);
         convert_old_xmloutlineview_data();
         convert_ftp_ini();
         _convert_errorre_xml();
         _convert_symbolcoloring_xml();
         convert_user_vlx();
         convert_ubox_ini();
         convert_uprint_ini();
         convert_etfaves_xml();
         convert_DateTimeFilters_xml();
         convert_old_alert_config();
         convert_old_LanguageSpecificProjects();
         // Convert from various old extensionless file handling to new xmlcfg format
         _UpgradeExtensionlessFiles(config_migrated_from_version);
#if 0 
         // 9/6/2016 - We have made the decision not to move named sessions into
         //            user.cfg.xml.  Saving this code for now in case it ever
         //            becomes practical in the future.
         convert_diff_sessions();
#endif
         upgrade_diff_sessions();
         convert_filelist_options();
      }
      if (major<23 && def_keys=='vi-keys') {
         if (!(_default_option('s')&VSSEARCHFLAG_ISRE)) {
            int so = _default_option('S');
            so |= def_re_search_flags;
            _default_option('S', so);
         }
      }
   }

   // Convert to the new .cfg.xml languages settings
   module := "lang2cfgxml.ex";
   filename := _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
   //_message_box('filename='filename);
   if (filename=='') {
      module='lang2cfgxml.e';
      filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
      //_message_box('h2 filename='filename);
      if (filename=='') {
         filename='lang2cfgxml';
      }
   }
   shell(_maybe_quote_filename(filename));


   if (config_migrated_from_version!='') {
      if (major<21) {
         // Since lang2cfgxml can modify profiles
         // overright the settings above with the users
         // profile settings
         convert_old_beautifier_profiles();
         _convert_new_beautifier_profiles();
      }
   }



   if (config_migrated_from_version != "") {
      // Avoid homogonizing the user's brace settings for anything other 
      // than a version upgrade from a pre-new-beautifier version.
      if (major<21) {
         remove_old_eventtabs();
      }

      /*
         It looks like all the calls below don't need to occur if major>=20 except for
         a small part of _UpgradeExtensionSetup() (_c_update_settings) which could be
         moved. Since this code only gets execute when tranfering the config from
         a prior version, go ahead do all this when upgrading from version 20 too but
         not 21.
      */
      if (major<21) {
         convert_def_register();
         _UpgradeLanguageSetup();
         _UpgradeExtensionSetup();
         _convert_default_fonts_to_profile();
         _UpgradeColorScheme();
         _UpgradeSymbolColoringScheme();
         _UpgradeAutoCompleteSettings(config_migrated_from_version);
         _post_call(_MigrateV14SymbolColoringOptions,  config_migrated_from_version);

         // existing users do not need to be told about features they already know about
         _UpgradeNotificationLevels(config_migrated_from_version);
         // we split alias expansion from syntax expansion
         _UpgradeLanguageAliasExpansion(config_migrated_from_version);
         // added {} option
         _UpgradeAutoBracketSettings(config_migrated_from_version);
         // moved code into C++, changed file format to XML
         _UpgradeFileposData();
         // update smart open options
         _UpgradeSmartOpen(config_migrated_from_version);
         // update toolbars
         _UpdateToolbars();
         // Update tool-windows
         _UpdateToolWindows();
         // turn off def_vcpp_flags
         _UpgradeVCPPFlags(config_migrated_from_version);
         // automate url mappings
         _UpdateURLMappings();
         // update lexers with new styles. v22 changes color lexers. Don't need to update these
         //_UpdateCCStyles(config_migrated_from_version);


         if (def_config_transfered_from_dir != '') {
            _cleanup_old_tagfiles(def_config_transfered_from_dir);
         }


         // added separate def-var for file types on the Find/Replace form
         _post_call(_UpgradeFindFileTypes, config_migrated_from_version);
      } else {
         if (!_plugin_has_profile(VSCFGPACKAGE_COLOR_PROFILES,def_color_scheme)) {
            def_color_scheme='Default';// Make sure the color profile exists
         }
      }
   }

   _beautifier_cache_clear('');
   _beautifier_profile_changed('','');
   _xlat_config_paths_in_compilers_xml(config_migrated_from_version);

   rc=0;
   return 0;
}
