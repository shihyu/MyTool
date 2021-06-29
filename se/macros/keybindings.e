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
#include "vsevents.sh"
#include "xml.sh"
#import "se/lang/api/LanguageSettings.e"
#import "codehelp.e"
#import "complete.e"
#import "dlgman.e"
#import "fileman.e"
#import "files.e"
#import "guiopen.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "menu.e"
#import "math.e"
#import "optionsxml.e"
#import "picture.e"
#import "seltree.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "util.e"
#import "cfg.e"
#endregion

using se.lang.api.LanguageSettings;

static void _keybindings_form_on_key_change();
static void _bindkey_form_on_key_change();
static void _what_is_form_on_key_change();

/**
 * Show the binding dialog
 */
_command int gui_keybindings,gui_bind_to_key(_str command_name = '') name_info(','EDITORCTL_ARG2)
{
   config('_keybindings_form', 'D', command_name);
   return(0);
}

/**
 * Translate event name to short-form
 *
 * 'Ctrl+S' => 'C-S'
 * 'Alt+Shift+T' => 'A-S-T'
 */
static _str shortEventName(_str eventName)
{
   eventName = stranslate(eventName, 'BACK-BUTTON-DOWN', 'BackButtonDn');
   eventName = stranslate(eventName, 'BACK-BUTTON-UP', 'BackButtonUp');
   eventName = stranslate(eventName, 'BACK-BUTTON-DOUBLE-CLICK', 'BackDoubleClick');
   eventName = stranslate(eventName, 'BACK-BUTTON-TRIPLE-CLICK', 'BackTripleClick');
   eventName = stranslate(eventName, 'FORWARD-BUTTON-DOWN', 'ForwardButtonDn');
   eventName = stranslate(eventName, 'FORWARD-BUTTON-UP', 'ForwardButtonUp');
   eventName = stranslate(eventName, 'FORWARD-BUTTON-DOUBLE-CLICK', 'ForwardDoubleClick');
   eventName = stranslate(eventName, 'FORWARD-BUTTON-TRIPLE-CLICK', 'ForwardTripleClick');
   eventName = stranslate(eventName, 'LBUTTON-DOWN', 'LButtonDn');
   eventName = stranslate(eventName, 'LBUTTON-UP', 'LButtonUp');
   eventName = stranslate(eventName, 'LBUTTON-DOUBLE-CLICK', 'LDoubleClick');
   eventName = stranslate(eventName, 'LBUTTON-TRIPLE-CLICK', 'LTripleClick');
   eventName = stranslate(eventName, 'MBUTTON-DOWN', 'MButtonDn');
   eventName = stranslate(eventName, 'MBUTTON-UP', 'MButtonUp');
   eventName = stranslate(eventName, 'MBUTTON-DOUBLE-CLICK', 'MDoubleClick');
   eventName = stranslate(eventName, 'MBUTTON-TRIPLE-CLICK', 'MTripleClick');
   eventName = stranslate(eventName, 'RBUTTON-DOWN', 'RButtonDn');
   eventName = stranslate(eventName, 'RBUTTON-UP', 'RButtonUp');
   eventName = stranslate(eventName, 'RBUTTON-DOUBLE-CLICK', 'RDoubleClick');
   eventName = stranslate(eventName, 'RBUTTON-TRIPLE-CLICK', 'RTripleClick');
   eventName = stranslate(eventName, 'WHEEL-DOWN', 'WheelDn');
   eventName = stranslate(eventName, 'WHEEL-UP', 'WheelUp');
   eventName = stranslate(eventName, 'WHEEL-LEFT', 'WheelLeft');
   eventName = stranslate(eventName, 'WHEEL-RIGHT', 'WheelRight');
   eventName = stranslate(eventName, 'PAD-SLASH', 'PadSlash');
   eventName = stranslate(eventName, 'PAD-STAR', 'PadStar');
   eventName = stranslate(eventName, 'PAD-MINUS', 'PadMinus');
   eventName = stranslate(eventName, 'PAD-PLUS', 'PadPlus');
   eventName = stranslate(eventName, 'PAD-0', 'Pad0');
   eventName = stranslate(eventName, 'PAD-1', 'Pad1');
   eventName = stranslate(eventName, 'PAD-2', 'Pad2');
   eventName = stranslate(eventName, 'PAD-3', 'Pad3');
   eventName = stranslate(eventName, 'PAD-4', 'Pad4');
   eventName = stranslate(eventName, 'PAD-5', 'Pad5');
   eventName = stranslate(eventName, 'PAD-6', 'Pad6');
   eventName = stranslate(eventName, 'PAD-7', 'Pad7');
   eventName = stranslate(eventName, 'PAD-8', 'Pad8');
   eventName = stranslate(eventName, 'PAD-9', 'Pad9');
   eventName = stranslate(eventName, 'PAD-DOT', 'PadDot');
   eventName = stranslate(eventName, 'PAD-EQUAL', 'PadEqual');
   eventName = stranslate(eventName, 'PAD-ENTER', 'PadEnter');
   eventName = stranslate(eventName, 'C-', 'Ctrl+');
   eventName = stranslate(eventName, 'A-', 'Alt+');
   eventName = stranslate(eventName, 'M-', 'Command+');
   eventName = stranslate(eventName, 'S-', 'Shift+');
   eventName = stranslate(eventName, 'A-', 'Option+');
   return stranslate(eventName, ' ', 'Space');
}

/**
 * Prompt for mouse event
 *
 * @return long event name
 */
static _str getMouseEvent(int prefix)
{
   _str mouse_events[];
   int i;
   for (i = VSEV_FIRST_MOUSE; i <= VSEV_LAST_MOUSE; ++i) {
      if (i != VSEV_MOUSE_MOVE) {
         mouse_events[mouse_events._length()] = strip(event2name(index2event(prefix|i), 'L'));
      }
   }
   return select_tree(mouse_events, null, null, null, null, null, null, 'Select mouse event', 0, null, null, true, 'Select Mouse Event dialog', null);
}

static _str _excludeEventTabs:[] = {
   "root-keys"                => 1,
   "mode-keys"                => 1,
   "argument-completion-keys" => 1,
   "auto-complete-keys"       => 1,
   "codehelp-keys"            => 1,
};

/**
 * create a list of key tables for keybindings dialog
 */
static void enumerateKeyTables(_str (&keyTableNames):[])
{

   // For simplicity, make sure all the mode event tables are created now.
   _plugin_list_profiles(VSCFGPACKAGE_EVENTTAB_PROFILES,auto profileNames);
   for (i:=0;i<profileNames._length();++i) {
      name:=profileNames[i];
      if (beginsWith(name,'emulation-')) {
         continue;
      }
      _eventtab_get_mode_keys(_profile_name_2_eventtab_name(name));
   }

   for (ff := 1;; ff = 0) {
      index := name_match('', ff, EVENTTAB_TYPE);
      if ( !index ) break;
      name := name_name(index);
      if (!(_excludeEventTabs._indexin(name) ||
            pos('[:.]', name_name(index), 1, 'r') ||
            find_index(name_name(index), OBJECT_TYPE) ||
            (pos('[-_]keys$', name, 1, 'r') <= 0))) {

         keyTableNames:[index] = name;
      }
   }
}

/**
 * Get eventtab name from mode name
 */
static _str getKeyTable(_str modeName = '')
{
   if (modeName == '' || modeName == 'default') {
      return 'default-keys';
   }
   if (modeName == 'Vi Command Mode') {
      return 'vi-command-keys';
   } else if (modeName == 'Vi Visual Mode') {
      return 'vi-visual-keys';
   } else if (modeName == 'Diff Mode') {
      return 'diff-keys';
   }

   modeNameKeys :=  modeName:+'-keys';
   index := find_index(modeNameKeys, EVENTTAB_TYPE);
   if (index) {
      return (modeNameKeys);
   }

   return LanguageSettings.getKeyTableName(_Modename2LangId(modeName));
}

static void emptyKeyTable(int keyTableIndex)
{
   if (name_type(keyTableIndex) == EVENTTAB_TYPE) {
      VSEVENT_BINDING list[];
      int NofBindings;
      list_bindings(keyTableIndex, list);
      NofBindings = list._length();

      i := 0;
      for (i; i < NofBindings; ++i) {
         if (!vsIsOnEvent(list[i].iEvent)) {
            index := eventtab_index(keyTableIndex, keyTableIndex, list[i].iEvent);
            if (name_type(index) == EVENTTAB_TYPE) {
               emptyKeyTable(index);
               delete_name(index);
            }
            set_eventtab_index(keyTableIndex, list[i].iEvent, 0, list[i].iEndEvent);
         }
      }
   }
}

static int findKeyBindingIndex(int keyTableIndex, _str keySequence)
{
   _str key, shortKey;
   int keyIndex;
   index := 0;
   if (keyTableIndex == 0) {
      return (index);
   }

   while (true) {
      //Get the first key in the key sequence.
      parse keySequence with key ' ' keySequence;

      //Convert it to short form, so we can find events, etc.
      shortKey = shortEventName(key);
      keyIndex = event2index(name2event(shortKey));

      // get current index for table
      index = eventtab_index(keyTableIndex, keyTableIndex, keyIndex);

      //There are no more keys to come, time to bind.
      if (keySequence == '') {
         break;
      }
      if (index) {
         if (name_type(index) == EVENTTAB_TYPE) {
            //There is a sub-event table.
            keyTableIndex = index;
         } else {
            // keys still left
            if (keySequence != '') {
               index = 0;
            }
            break;
         }
      } else {
         break;
      }
   }
   return (index);
}

/**
 * Bind command to key sequence
 */
static int bind(_str command, _str keyTable, _str keySequence)
{
   _str key;
   _str shortKey;
   commandIndex := find_index(command, COMMAND_TYPE);
   int eventTabIndex;
   int keyIndex;
   int keyEndIndex = VSEV_NULL;
   keyTableIndex := find_index(keyTable, EVENTTAB_TYPE);
   int index;
   int tempKTIndex = keyTableIndex;

   //If the top level key table is new, we need to make one.
   if (!tempKTIndex) {
      tempKTIndex = _eventtab_get_mode_keys(keyTable);
   }

   while (true) {
      //Get the first key in the key sequence.
      parse keySequence with key ' ' keySequence;

      //Convert it to short form, so we can find events, etc.
      shortKey = shortEventName(key);
      keyIndex = event2index(name2event(shortKey));

      // get current index for table
      index = eventtab_index(tempKTIndex, tempKTIndex, keyIndex);

      if (pos("->", keySequence, 1) == 1) {  // handle range
         parse keySequence with "->" key keySequence;
         keyEndIndex = event2index(name2event(shortEventName(key)));
         if (keySequence != '') {
            return(INVALID_ARGUMENT_RC);
         }
      }

      //There are no more keys to come, time to bind.
      if (keySequence == '') {
         if (index && (name_type(index) == EVENTTAB_TYPE)) { // zap this eventtable
            emptyKeyTable(index);
         }

         keyTableIndex = eventtab_index(tempKTIndex, tempKTIndex, keyIndex, 'u');
         set_eventtab_index(keyTableIndex, keyIndex, commandIndex, keyEndIndex);
         _config_modify_flags(CFGMODIFY_KEYS);
         break;
      }

      if (name_type(index) == EVENTTAB_TYPE) {
         //There is a sub-event table.
         keyTable :+= ':'key;
         tempKTIndex = index;
      } else {
         //There isn't a sub-event table. Try to make one.
         keyTable :+= ':'key;
         eventTabIndex = find_index(keyTable, EVENTTAB_TYPE);
         if (!eventTabIndex) {
            eventTabIndex = insert_name(keyTable, EVENTTAB_TYPE);
         }
         if (!eventTabIndex) {
            _message_box('Could not create key table. ':+
                         get_message(eventTabIndex));
            return(1);
         }
         keyTableIndex = eventtab_index(tempKTIndex, tempKTIndex, keyIndex, 'u');
         set_eventtab_index(keyTableIndex, keyIndex, eventTabIndex);
         tempKTIndex = eventTabIndex;
      }
   }

   return (0);
}

/**
 * Unbind key sequence
 */
static int unbind(_str keyTable, _str keySequence)
{
   _str shortKey;
   _str key;
   keyIndex := 0;
   int keyEndIndex = VSEV_NULL;
   keyTableIndex := find_index(keyTable, EVENTTAB_TYPE);

   int keyTableTree[];
   int keyIndexTree[];

   while (keyTableIndex) {
      //Get the first key in the key sequence.
      parse keySequence with key ' ' keySequence;

      //Convert it to short form, so we can find events, etc.
      shortKey = shortEventName(key);
      keyIndex = event2index(name2event(shortKey));

      // save the tree for later
      keyTableTree[keyTableTree._length()] = keyTableIndex;
      keyIndexTree[keyIndexTree._length()] = keyIndex;

      if (pos("->", keySequence, 1) == 1) {  // handle range
         parse keySequence with "->" key keySequence;
         keyEndIndex = event2index(name2event(shortEventName(key)));
         if (keySequence != '') {
            return(INVALID_ARGUMENT_RC);
         }
      }
      //There are no more keys to come, time to unbind.
      if (keySequence == '') {
         break;
      }

      keyTableIndex = eventtab_index(keyTableIndex, keyTableIndex, keyIndex);
      if (name_type(keyTableIndex) != EVENTTAB_TYPE) {
         keyTableIndex = 0;
         break;
      }
   }

   if ((keyTableIndex != 0) && (keyIndex != 0)) {
      set_eventtab_index(keyTableIndex, keyIndex, 0, keyEndIndex);

      // cleanup nested binding tables
      int i = keyTableTree._length() - 1;
      for ( ; i > 0; --i) {
         VSEVENT_BINDING list[];
         list_bindings(keyTableIndex, list);
         if (list._length() > 0) { // tables are not empty
            break;
         }

         int parentKeyTable = keyTableTree[i-1];
         int parentKeyIndex = keyIndexTree[i-1];
         set_eventtab_index(parentKeyTable, parentKeyIndex, 0);
         delete_name(keyTableIndex);
         keyTableIndex = parentKeyTable;
      }
      return (0);
   }
   return (1);
}

#region  Options Dialog Helper Functions

defeventtab _keybindings_form;
static bool RESIZING_KEYBINDINGS(...) {
   if (arg()) ctlbind.p_user=arg(1);
   return ctlbind.p_user;
}
static int SPLITTER_POS(...) {
   if (arg()) ctl_size_y.p_user=arg(1);
   return ctl_size_y.p_user;
}

void _keybindings_form_init_for_options(_str command = '')
{
   _update_profiles_for_modified_eventtabs();
   ctlclose.p_visible = false;
   ctlrun.p_visible = false;
   ctlunbind.p_x = ctlbind.p_x;
   ctlbind.p_x = ctlclose.p_x;

   wid := p_window_id;
   p_window_id = ctlcommandbindings.p_window_id;

   _str keyTableNames:[] = _GetDialogInfoHt("keyTableNames");
   buildKeyBindingTree(keyTableNames);
   filterCommands(ctlcommand_box.p_text, ctlkeysequence_box.p_text);

   p_window_id = wid;

   if (command != '') {
      ctlcommand_box.p_text = command;
      ctlcommandbindings.filterCommands(ctlcommand_box.p_text, ctlkeysequence_box.p_text);
   }
}

void _keybindings_form_restore_state(_str command = '')
{
   if (command != '') {
      // we might need to reload the keytable in case they've 
      // recorded a macro with the dialog open
      _str keyTableNames:[];
      enumerateKeyTables(keyTableNames);
      _SetDialogInfoHt("keyTableNames", keyTableNames);

      wid := p_window_id;
      p_window_id = ctlcommandbindings;

      buildKeyBindingTree(keyTableNames);

      ctlcommand_box.p_text = command;
      ctlcommandbindings.filterCommands(ctlcommand_box.p_text, ctlkeysequence_box.p_text);

      p_window_id = wid;
   }
}

bool _keybindings_form_is_modified()
{
   return false;
}

_str _keybindings_form_export_settings(_str &path) {
   _update_profiles_for_modified_eventtabs();
   return _plugin_export_profiles(path,VSCFGPACKAGE_EVENTTAB_PROFILES);
}
_str _lang_key_table_profile(_str langID, _str value = null)
{
   if (value == null) {
      et_name:=LanguageSettings.getKeyTableName(langID);
      profileName:=_eventtab_name_2_profile_name(et_name);
      handle:=_plugin_get_user_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,profileName,false);
      value='';
      if (handle>=0) {
         _xmlcfg_save_to_string(value,handle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL);
         _xmlcfg_close(handle);
      }
      value=et_name:+"\1":+value;
   } else {
      parse value with auto et_name "\1" value;
      if (value!='') {
         handle:=_xmlcfg_open_from_string(value,auto status);
         if (handle>=0) {
            node:=_xmlcfg_get_document_element(handle);
            if (node>=0) {
               _plugin_set_user_profile(handle);
               _str profileName=_plugin_get_profile_name(_xmlcfg_get_attribute(handle,node,'n'));
               _plugin_set_user_profile(handle);
               _import_eventtab_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,profileName,false,null);
               //say(name_name(find_index(value,EVENTTAB_TYPE)));
            }
         }
      }
      if (et_name!='') {
         LanguageSettings.setKeyTableName(langID, et_name);
      }
      //_eventtab_get_mode_keys(value)
   }

   return value;
}
// Sync this event table with this profile
static void _import_eventtab_profile(_str escapedPackage,_str profileName,bool doDelete,typeless user_info) {
   if (doDelete && !_plugin_has_profile(escapedPackage,profileName)) {
      // This should not happen because we specified not to delete these profiles
      return;
   }
   int kt_index;
   if (beginsWith(profileName,VSCFGPROFILE_EMULATION_PREFIX,false,'i')) {
      // IF this is not the active emulation
      if (!strieq(profileName,_def_keys_2_profile_name())) {
         return;  // nothing more to do.
      }
      // Apply this key bindings
      kt_index=_default_keys;
   } else {
      kt_index=find_index(_profile_name_2_eventtab_name(profileName),EVENTTAB_TYPE);
   }
   if (!kt_index) {
      // Could create this event table.
      // For now, assume this event table isn't needed
      return;
   }
   _plugin_eventtab_apply_bindings(escapedPackage,profileName,kt_index);
   if (_eventtab_get_modify(kt_index)) {
      _eventtab_set_modify(kt_index,false);
      _config_modify_flags(CFGMODIFY_KEYS);
   }
}
static _str _import_key_bindings_from_file(typeless filename,_str (&optionAttrs):[]=null) {
   _update_profiles_for_modified_eventtabs();
   if (filename._varformat()==VF_LSTR && endsWith(filename,VSCFGFILEEXT_CFGXML,false,_fpos_case)) {
        error:=_plugin_import_profiles(filename,VSCFGPACKAGE_EVENTTAB_PROFILES,2,_import_eventtab_profile,null,optionAttrs);
        return error;
   }
   // Importing from the old XML format
   error := '';
   // is this an array of files or just a single file?
   _str emulation;
   if (filename._typename() == '_str') {
      error = importKeybindingFile_Old(filename,_import_eventtab_profile,emulation);
      if (emulation!='') {
         optionAttrs:[VSCFGOPTIONS_ATTR_EMULATION]=emulation;
      }
   } else {
      _str keyFile;
      foreach (keyFile in filename) {
         error :+= importKeybindingFile_Old(keyFile,_import_eventtab_profile,emulation);
      }
   }
   _update_profiles_for_modified_eventtabs();
   return error;
}

_str _keybindings_form_import_settings(typeless &path)
{
   return _import_key_bindings_from_file(path);
}

static _str _property_key_name(int index)
{
   _str key_name=event2name(index2event(index));
   key_name=stranslate(key_name,"''","'");
   return("'"key_name"'");
#if 0
   // IF this is a Unicode character
   if ( pos("'",key_name) || pos('\x{',key_name,1,'i')) {
      return('"'key_name'"');
   }
   if (length(key_name)==1 && _asc(key_name)>127) {
      return('\'_asc(key_name));
   }
   return("'"key_name"'");
#endif
/*
  key_name= translate(event2name(index2event(index)),'_','-')
  if length(key_name)>1 then return(key_name) endif
  if index=_asc("'") then
    return('"''"')
  endif
  return("'"_chr(index)"'")
*/
}

/**
 * Bind command to key sequence
 */
static int bind_old(_str command, _str keyTable, _str keySequence)
{
   _str key;
   _str shortKey;
   commandIndex := find_index(command, COMMAND_TYPE);
   int eventTabIndex;
   int keyIndex;
   int keyEndIndex = VSEV_NULL;
   keyTableIndex := find_index(keyTable, EVENTTAB_TYPE);
   int index;
   int tempKTIndex = keyTableIndex;

   //If the top level key table is new, we need to make one.
   if (!tempKTIndex) {
      tempKTIndex = insert_name(keyTable, EVENTTAB_TYPE);
   }

   while (true) {
      //Get the first key in the key sequence.
      parse keySequence with key ' ' keySequence;

      //Convert it to short form, so we can find events, etc.
      shortKey = shortEventName(key);
      keyIndex = event2index(name2event(shortKey));

      // get current index for table
      index = eventtab_index(tempKTIndex, tempKTIndex, keyIndex);

      if (pos("->", keySequence, 1) == 1) {  // handle range
         parse keySequence with "->" key keySequence;
         keyEndIndex = event2index(name2event(shortEventName(key)));
         if (keySequence != '') {
            return(INVALID_ARGUMENT_RC);
         }
      }

      //There are no more keys to come, time to bind.
      if (keySequence == '') {
         if (index && (name_type(index) == EVENTTAB_TYPE)) { // zap this eventtable
            emptyKeyTable(index);
         }

         keyTableIndex = eventtab_index(tempKTIndex, tempKTIndex, keyIndex, 'u');
         set_eventtab_index(keyTableIndex, keyIndex, commandIndex, keyEndIndex);
         _config_modify_flags(CFGMODIFY_KEYS);
         break;
      }

      if (name_type(index) == EVENTTAB_TYPE) {
         //There is a sub-event table.
         keyTable :+= ':'key;
         tempKTIndex = index;
      } else {
         //There isn't a sub-event table. Try to make one.
         keyTable :+= ':'key;
         eventTabIndex = find_index(keyTable, EVENTTAB_TYPE);
         if (!eventTabIndex) {
            eventTabIndex = insert_name(keyTable, EVENTTAB_TYPE);
         }
         if (!eventTabIndex) {
            _message_box('Could not create key table. ':+
                         get_message(eventTabIndex));
            return(rc);
         }
         keyTableIndex = eventtab_index(tempKTIndex, tempKTIndex, keyIndex, 'u');
         set_eventtab_index(keyTableIndex, keyIndex, eventTabIndex);
         tempKTIndex = eventTabIndex;
      }
   }

   //call_list('_eventtab_modify_', keyTableIndex, key);
   return (0);
}

/**
 * Unbind key sequence
 */
static int unbind_old(_str keyTable, _str keySequence)
{
   _str shortKey;
   _str key;
   keyIndex := 0;
   int keyEndIndex = VSEV_NULL;
   keyTableIndex := find_index(keyTable, EVENTTAB_TYPE);

   int keyTableTree[];
   int keyIndexTree[];

   while (keyTableIndex) {
      //Get the first key in the key sequence.
      parse keySequence with key ' ' keySequence;

      //Convert it to short form, so we can find events, etc.
      shortKey = shortEventName(key);
      keyIndex = event2index(name2event(shortKey));

      // save the tree for later
      keyTableTree[keyTableTree._length()] = keyTableIndex;
      keyIndexTree[keyIndexTree._length()] = keyIndex;

      if (pos("->", keySequence, 1) == 1) {  // handle range
         parse keySequence with "->" key keySequence;
         keyEndIndex = event2index(name2event(shortEventName(key)));
         if (keySequence != '') {
            return(INVALID_ARGUMENT_RC);
         }
      }
      //There are no more keys to come, time to unbind.
      if (keySequence == '') {
         break;
      }

      keyTableIndex = eventtab_index(keyTableIndex, keyTableIndex, keyIndex);
      if (name_type(keyTableIndex) != EVENTTAB_TYPE) {
         keyTableIndex = 0;
         break;
      }
   }

   if ((keyTableIndex != 0) && (keyIndex != 0)) {
      set_eventtab_index(keyTableIndex, keyIndex, 0, keyEndIndex);

      // cleanup nested binding tables
      int i = keyTableTree._length() - 1;
      for ( ; i > 0; --i) {
         VSEVENT_BINDING list[];
         list_bindings(keyTableIndex, list);
         if (list._length() > 0) { // tables are not empty
            break;
         }

         int parentKeyTable = keyTableTree[i-1];
         int parentKeyIndex = keyIndexTree[i-1];
         set_eventtab_index(parentKeyTable, parentKeyIndex, 0);
         delete_name(keyTableIndex);
         keyTableIndex = parentKeyTable;
      }
      _config_modify_flags(CFGMODIFY_KEYS);
      //call_list('_eventtab_modify_', keyTableIndex, key);
      return (0);
   }
   return (1);
}
static int importKeyDefs_Old(int treeHandle, int nodeIndex, _str keyTable,_str emulationKeys)
{
   profileName:=_eventtab_name_2_profile_name(keyTable);
   kt_index:=_eventtab_get_mode_keys(keyTable,1,1 /* apply built-in profile without user mods*/);
   bindingNode := 0;
   bindingNode = _xmlcfg_get_first_child(treeHandle, nodeIndex,
                                         VSXMLCFG_NODE_ELEMENT_START_END);
   status := 0;
   while (bindingNode > 0) {
      command := _xmlcfg_get_attribute(treeHandle, bindingNode, 'Command', '');
      key := _xmlcfg_get_attribute(treeHandle, bindingNode, 'Key', '');
      key = formatImportedKey(key);
      name := _xmlcfg_get_name(treeHandle, bindingNode);

      if (name == 'Assign') {
         status |= bind(command, keyTable, key);
      } else if (name == 'Remove') {
         status |= unbind(keyTable, key);
      }
      bindingNode = _xmlcfg_get_next_sibling(treeHandle, bindingNode,
                                             VSXMLCFG_NODE_ELEMENT_START_END);
   }
   if (kt_index) {
      _update_profile_for_eventtab(kt_index);
      _config_modify_flags(CFGMODIFY_KEYS);
   }

   return status;
}
static _str importKeybindingFile_Old(_str keyFile,void (*callback)(_str epackage,_str profileName,bool doDelete,typeless user_info)=null,_str &emulation=null)
{
   emulation='';
   error:='';
   handle := -1;
   status := 0;
   handle = _xmlcfg_open(keyFile, status, 0, VSENCODING_UTF8);
   if (handle < 0) {
      error=get_message(handle);
      _message_box(get_message(handle));
      return error;
   }

   kbNode := 0;
   kbNode = _xmlcfg_find_child_with_name(handle, TREE_ROOT_INDEX,'KeyBindings', VSXMLCFG_NODE_ELEMENT_START);
   if (kbNode < 0) {
      error=get_message(handle);
      error='Either this old keybord XML file is corrupt or this import file needs to have a .cfg.xml extension on it';
      _message_box(error);
      return error;
   }

   _str orig_def_keys=def_keys;
   restore_default_keys := false;
   emulation = _xmlcfg_get_attribute(handle, kbNode, 'Emulation');
   if (emulation!=_def_keys_2_emulation_profile_suffix()) {
      restore_default_keys=true;
      def_keys=shortEmulationName(emulation)'-keys';
      if (def_keys=='slick-keys') def_keys='';
   }
   modeName := "";
   int modeNode = _xmlcfg_find_child_with_name(handle, kbNode, 'Mode',VSXMLCFG_NODE_ELEMENT_START);
   while (modeNode > 0) {
      modeName = _xmlcfg_get_attribute(handle, modeNode, 'Name', '');

      importKeyDefs_Old(handle, modeNode, modeName:+'-keys',emulation);

      modeNode = _xmlcfg_get_next_sibling(handle, modeNode,VSXMLCFG_NODE_ELEMENT_START);
   }
   _xmlcfg_close(handle);
   if (restore_default_keys) {
      def_keys=orig_def_keys;
      _plugin_eventtab_apply_bindings(VSCFGPACKAGE_EVENTTAB_PROFILES,_def_keys_2_profile_name(),_default_keys);
      if (_eventtab_get_modify(_default_keys)) {
         _eventtab_set_modify(_default_keys,false);
      }
   }
   return error;
}


#endregion Options Dialog Helper Functions

static void getCommandTreeIndices(INTARRAY (&commandTreeIndex):[])
{
   commandTreeIndex = null;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      // get just the file name with path
      nodeText := _TreeGetCaption(index);
      parse nodeText with auto commandName "\t" .;
      commandTreeIndex:[commandName][commandTreeIndex:[commandName]._length()] = index;

      // get next index
      index = _TreeGetNextSiblingIndex(index);
   }
}

static void showhideAllCommands(bool hideAll)
{
   int show_children, bm1, bm2, flags;
   new_flag := (hideAll) ? TREENODE_HIDDEN : 0;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   lastIndex := TREE_ROOT_INDEX;
   while (index > 0) {
      // Get the original tree flags for this node
      _TreeGetInfo(index, show_children, bm1, bm2, flags);
      if ((flags & TREENODE_HIDDEN) != new_flag) {
         _TreeSetInfo(index, show_children, bm1, bm2, (flags & ~TREENODE_HIDDEN) | new_flag, 0);
         lastIndex = index;
      }
      // get next index
      index = _TreeGetNextSiblingIndex(index);
   }
   if (lastIndex > TREE_ROOT_INDEX) {
      _TreeGetInfo(lastIndex, show_children, bm1, bm2, flags);
      _TreeSetInfo(lastIndex, show_children, bm1, bm2, flags, 1);
   }
}

static void showhideTreeIndexArray(bool hideAll, INTARRAY& treeIndex)
{
   int show_children, bm1, bm2, flags, i, index;
   new_flag := (hideAll) ? TREENODE_HIDDEN : 0;
   len := treeIndex._length();
   for (i = 0; i < len; ++i) {
      index = treeIndex[i];
      _TreeGetInfo(index, show_children, bm1, bm2, flags);
      if ((flags & TREENODE_HIDDEN) != new_flag) {
         _TreeSetInfo(index, show_children, bm1, bm2, (flags & ~TREENODE_HIDDEN) | new_flag);
      }
   }
}

static void filterEventTable(int keyTableIndex, INTARRAY (&commandTreeIndex):[])
{
   VSEVENT_BINDING list[];
   int NofBindings;
   list_bindings(keyTableIndex, list);
   NofBindings = list._length();
   i := 0;
   for (i; i < NofBindings; ++i) {
      if (!vsIsOnEvent(list[i].iEvent)) {
         index := eventtab_index(keyTableIndex, keyTableIndex, list[i].iEvent);
         if (name_type(index) == EVENTTAB_TYPE) {
            filterEventTable(index, commandTreeIndex);
         } else {
            commandName := name_name(index);
            showhideTreeIndexArray(false, commandTreeIndex:[commandName]);
         }
      }
   }
}

static void filterKeySequence(_str keySequence)
{
   INTARRAY commandTreeIndex:[] = _GetDialogInfoHt("commandTreeIndex");
   _str keyTableNames:[] = _GetDialogInfoHt("keyTableNames");

   typeless keyTableIndex;
   keyTableIndex._makeempty();
   while (true) {
      keyTableNames._nextel(keyTableIndex);
      if (keyTableIndex._isempty()) {
         break;
      }
      index := findKeyBindingIndex(keyTableIndex, keySequence);
      if (index) {
         if (name_type(index) == EVENTTAB_TYPE) {
            // show nested commands
            filterEventTable(index, commandTreeIndex);
         } else {
            // index is command
            commandName := name_name(index);
            showhideTreeIndexArray(false, commandTreeIndex:[commandName]);
         }
      }
   }
}

static void filterCommandName(_str commandFilterText)
{
   int show_children, bm1, bm2, flags, new_flag;
   _str captionName, commandName;
   commandFilterText = stranslate(commandFilterText, '-', '_');
   commandFilterText = _escape_re_chars(commandFilterText);   // filters are using regular expressions matching
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   lastIndex := TREE_ROOT_INDEX;
   while (index > 0) {
      // get just the file name with path
      captionName = _TreeGetCaption(index);
      parse captionName with commandName "\t" .;

      match_command := (commandFilterText != '' && pos(commandFilterText, commandName, 1, "ir") > 0);
      new_flag = (match_command) ? 0 : TREENODE_HIDDEN;

      // Get the original tree flags for this node
      _TreeGetInfo(index, show_children, bm1, bm2, flags);

      // did the hidden flag change?
      if ((flags & TREENODE_HIDDEN) != new_flag) {
         _TreeSetInfo(index, show_children, bm1, bm2, (flags & ~TREENODE_HIDDEN) | new_flag, 0);
         lastIndex = index;
      }

      // get next index
      index = _TreeGetNextSiblingIndex(index);
   }
   if (lastIndex > TREE_ROOT_INDEX) {
      _TreeGetInfo(lastIndex, show_children, bm1, bm2, flags);
      _TreeSetInfo(lastIndex, show_children, bm1, bm2, flags, 1);
   }
}

static void filterCommands(_str commandFilterText, _str keyFilterText)
{
   curIndex := _TreeCurIndex();
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (commandFilterText :== '' && keyFilterText :== '') {
      showhideAllCommands(false);
   } else {
      showhideAllCommands(true);
      if (commandFilterText :!= '') filterCommandName(commandFilterText);
      if (keyFilterText :!= '') filterKeySequence(keyFilterText);
   }
   newIndex := curIndex;
   _TreeGetInfo(curIndex, auto junk1, auto bm1, auto bm2, auto flags);
   if (curIndex == TREE_ROOT_INDEX || (flags & TREENODE_HIDDEN)) {
      nextIndex := _TreeGetNextIndex(TREE_ROOT_INDEX);
      newIndex = (nextIndex > 0) ? nextIndex : TREE_ROOT_INDEX;
   }
   _TreeSetCurIndex(newIndex);

   if (_TreeCurIndex()==TREE_ROOT_INDEX) {
      index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      _TreeGetInfo(index, auto junk2, junk2, junk2, flags);
      if ((flags & TREENODE_HIDDEN)) {
         if (_TreeGetNextIndex(TREE_ROOT_INDEX)<0) {
            ctlbind.p_enabled = false;
            ctlunbind.p_enabled = false;
            ctlcommand_documentation.p_text = "";
         }
      }
   }
}

#if 0
/**
 * Filter the commands in a tree control.  Tree control must be
 * active.   Nodes that do not match are hidden.
 *
 */
static void filterCommands(_str commandFilterText, _str keyFilterText)
{
   int show_children, bm1, bm2, flags, new_flag;
   _str commandName, keyName, isMacro;
   _str captionName, match_command, match_key;

   commandFilterText = stranslate(commandFilterText, '-', '_');
   commandFilterText = _escape_re_chars(commandFilterText);   // filters are using regular expressions matching
   keyFilterText = _escape_re_chars(keyFilterText);   // filters are using regular expressions matching

   curIndex := _TreeCurIndex();
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   lastIndex := TREE_ROOT_INDEX;
   while (index > 0) {
      // get just the file name with path
      captionName = _TreeGetCaption(index);
      parse captionName with commandName "\t" keyName "\t" . "\t" isMacro;

      match_command = (commandFilterText != '' && pos(commandFilterText, commandName, 1, "ir") > 0);
      match_key = (keyFilterText != '' && keyName != '' && (pos("^":+keyFilterText:+"( |$)", keyName, 1, "ir") > 0));

      new_flag = 0;
      if (commandFilterText != '' && keyFilterText != '') {
         new_flag = (match_command || match_key) ? 0 : TREENODE_HIDDEN;
      } else if (commandFilterText != '') {
         new_flag = (match_command) ? 0 : TREENODE_HIDDEN;
      } else if (keyFilterText != '') {
         new_flag = (match_key) ? 0 : TREENODE_HIDDEN;
      }

      if ((index == curIndex) && new_flag) {
         curIndex = TREE_ROOT_INDEX;
      }

      // Get the original tree flags for this node
      _TreeGetInfo(index, show_children, bm1, bm2, flags);

      // did the hidden flag change?
      if ((flags & TREENODE_HIDDEN) != new_flag) {
         _TreeSetInfo(index, show_children, bm1, bm2, (flags & ~TREENODE_HIDDEN) | new_flag, 0);
         lastIndex = index;
      }

      // get next index
      index = _TreeGetNextSiblingIndex(index);
   }

   if (lastIndex > TREE_ROOT_INDEX) {
      _TreeGetInfo(lastIndex, show_children, bm1, bm2, flags);
      _TreeSetInfo(lastIndex, show_children, bm1, bm2, flags, 1);
   }

   newIndex := _TreeCurIndex();
   if (curIndex == TREE_ROOT_INDEX) {
      nextIndex := _TreeGetNextIndex(TREE_ROOT_INDEX);
      newIndex = (nextIndex > 0) ? nextIndex : TREE_ROOT_INDEX;
   }
   _TreeSetCurIndex(newIndex);
   if (curIndex != newIndex) {
      call_event(CHANGE_SELECTED, newIndex, p_window_id, ON_CHANGE, 'W');
   }
}
#endif

/**
 * Filters items in ctlcommandbindings when keys are typed in ctlcommand_box
 */
void ctlcommand_box.on_change()
{
   if (_GetDialogInfoHt("ctlcommand_box.on_change") == true) {
      return;
   }
   _SetDialogInfoHt("ctlcommand_box.on_change", true);
   ctlcommandbindings.filterCommands(p_text, ctlkeysequence_box.p_text);
   _SetDialogInfoHt("ctlcommand_box.on_change", false);
}

/**
 * Clears the ctlcommand_box textbox
 */
void ctlclear_command.lbutton_up()
{
   ctlcommand_box.p_text = '';
   ctlcommand_box.end_line();
}

/**
 *  Pass some events to the command tree controls
 */
void ctlcommand_box.up,down,pgup,pgdn,"c-i","c-k","c-n","c-p"()
{
   ctlcommandbindings.call_event(ctlcommandbindings.p_eventtab2, last_event(), 'e');
}

/**
 * Insert all commands into the tree.  Tree must be active
 */
static void insertCommandList(INTARRAY (&commandIndexTable):[])
{
   CMDUI cmdui;
   cmdui.menu_handle = 0;
   cmdui.button_wid = 0;
   cmdui.menu_pos = 0;
   cmdui.inMenuBar = false;
   
   for (ff := 1 ;; ff = 0) {
      index := name_match("", ff, COMMAND_TYPE);
      if ( !index ) break;
      if (!index_callable(index)) {
         continue;
      }

      // Add on extra colums
      commandName := name_name(index);
      curName := commandName"\t\t\t";
      if (commandIndexTable._indexin(commandName)) {
         continue;
      }

      parse name_info(index) with ',' auto flags;
      isUserMacro := (flags != '' && isinteger(flags) && ((int)flags & VSARG2_MACRO));

      // Skip commands that can only be ran from Pro version of project
      if (!_isProEdition() && isinteger(flags) && ((int)flags & VSARG2_REQUIRES_PRO_EDITION)) {
         continue;
      }

      // Skip commands that can only be ran from Pro or Standard version of project
      if (!_isProEdition() && !_isStandardEdition() && isinteger(flags) && ((int)flags & VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)) {
         continue;
      }

      // Skip commands that can only be ran from a menu
      if (flags != '' && isinteger(flags) && ((int)flags & VSARG2_EXECUTE_FROM_MENU_ONLY)) {
         continue;
      }

      // Skip commands that start with a leading underscore (not for general use)
      if (_first_char(commandName)=='-' && !isUserMacro) {
         continue;
      }

      // Skip commands that start with "se.debug."
      if (substr(commandName,1,9)=='se.debug.' && !isUserMacro) {
         continue;
      }

      // Skip commands that start with "eclipse-", these are for the eclipse plugin
      if (substr(commandName,1,8)=='eclipse-' && !isUserMacro && !isEclipsePlugin()) {
         if (def_keys!="eclipse-keys") continue;
         switch (commandName) {
         // These exceptions are actually used in Eclipse emulation
         case "eclipse-content-assist":
         case "eclipse-gui-quick-access":
         case "eclipse-build-all":
         case "eclipse-quick-editor-switch":
         case "eclipse-maximize-part":
         case "eclipse-new-wizard":
         case "eclipse-show-outline":
         case "eclipse-next-editor":
         case "eclipse-next-view":
         case "eclipse-next-perspective":
         case "eclipse-run":
         case "eclipse-open-plugin-artifact": 
         case "eclipse-open-resource":
         case "eclipse-prev-editor":
         case "eclipse-prev-view":
         case "eclipse-prev-perspective":
         case "eclipse-show-system-menu":
         case "eclipse-backward-history":
         case "eclipse-forward-history":
         case "eclipse-new-quick-menu":
         case "eclipse-show-view":
         case "eclipse-quick-show-in":
         // These exceptions still work outside of the Eclipse plugin
         case "eclipse-find-in-files":
         case "eclipse-history-diff":
         case "eclipse-maybe-reset-modified-lines":
         case "eclipse-quit":
         case "eclipse-reload-buf":
         case "eclipse-safe-exit":
         case "eclipse-show-outline":
         case "eclipse-set-cd":
            break;
         default:
            continue;
         }
      }

      // Skip commands that start with "ispf-", unless we are in ISPF emulation
      if (substr(commandName,1,5)=='ispf-' && !isUserMacro && def_keys!="ispf-keys") {
         continue;
      }

      // Skip commands that start with "vi-", unless we are in VI emulation
      if (substr(commandName,1,3)=='vi-' && !isUserMacro && def_keys!="vi-keys") {
         continue;
      }

      if (!isUserMacro && !_haveProMacros()) {
         // Note that in order for us to use the _OnUpdate facility to filter out 
         // toolbar buttons: 
         // 1. EVERY _OnUpdate_* call must check for required features (_haveBuild(), etc.)
         //    BEFORE anything else so that MF_REQUIRES_PRO can be returned.
         // 2. EVERY _OnUpdate_* call must deal with target_wid==0 
         //    gracefully (e.g. return MF_GRAYED if appropriate).
         orig_wid := p_window_id;
         mfflags := _OnUpdate(cmdui, 0, commandName);
         p_window_id = orig_wid;
         if ( testFlag(mfflags, MF_REQUIRES_PRO) ) {
            // Feature not present in standard edition
            continue;
         }
      }

      if (isUserMacro) {
         curName :+= "Yes";
      } else {
         curName :+= "No";
      }
      userData := commandName"\t\t\t"index"\t"isUserMacro;
      curIndex := _TreeAddItem(TREE_ROOT_INDEX, curName, TREE_ADD_AS_CHILD, 0, 0, -1, 0, userData);
      commandIndexTable:[commandName][commandIndexTable:[commandName]._length()] = curIndex;
   }
}

/**
 *
 * @param _root_keys
 * @param mode
 * @param prefixKeys
 * @param commandIndexTable will be filled in - the indexes are
 *                          command names, the stored values are
 *                          tree indexes
 */
static void insertKeyDefs(int _root_keys, _str mode, _str prefixKeys,
                           INTARRAY (&commandIndexTable):[])
{
   VSEVENT_BINDING list[];
   list_bindings(_root_keys, list);
   keyTable := "";
   NofBindings := list._length();
   i := 0;
   bindingIndex := 0;
   keyName := "";
   commandName := "";

   //Insert the un-nested key bindings.
   for (i = 0; i < NofBindings; ++i) {
      bindingIndex = list[i].binding;
      //If something is bound to a command ...
      if (bindingIndex && (name_type(bindingIndex) & COMMAND_TYPE)) {
         //... and it's a reasonable event ...
         if (!vsIsOnEvent(list[i].iEvent)) {
            //... and it's not a range, put it in the binding buffer.
            keyName = strip(event2name(index2event(list[i].iEvent), 'L'));
            commandName = strip(name_name(bindingIndex));
            parse name_info(bindingIndex) with ',' auto flags;
            isUserMacro := (flags != '' && ((int)flags & VSARG2_MACRO));
            if (list[i].iEvent != list[i].iEndEvent) {
               keyName :+= " -> " :+ strip(event2name(index2event(list[i].iEndEvent), 'L'));
            }
            curIndex := _TreeAddItem(TREE_ROOT_INDEX,commandName"\t"prefixKeys:+keyName"\t"mode"\t":+(isUserMacro ? "Yes" : "No"),TREE_ADD_AS_CHILD, 0, 0, -1);
            commandIndexTable:[commandName][commandIndexTable:[commandName]._length()] = curIndex;

            userData := commandName"\t"prefixKeys:+keyName"\t"mode"\t"bindingIndex"\t"isUserMacro;
            _TreeSetUserInfo(curIndex, userData);
         }
      }
   }
   //Recurse and insert key bindings nested in a deeper event table.
   for (i = 0; i < NofBindings; ++i) {
      bindingIndex = list[i].binding;
      if (bindingIndex && (name_type(bindingIndex) & EVENTTAB_TYPE) ) {
         insertKeyDefs(bindingIndex, mode, prefixKeys:+
                       event2name(index2event(list[i].iEvent), 'L'):+' ',commandIndexTable);
      }
   }
}

/**
 * Insert all commands that are bound.
 *
 * @param commandIndexTable will be filled in - the indexes are
 *                          command names, the stored values are
 *                          tree indexes
 */
static void insertBindings(_str (&keyTableNames):[], INTARRAY (&commandIndexTable):[])
{
   //Insert all bindings.
   typeless keyTableIndex;
   keyTableIndex._makeempty();
   while (true) {
      keyTableNames._nextel(keyTableIndex);
      if (keyTableIndex._isempty()) {
         break;
      }
      mode := stranslate(keyTableNames:[keyTableIndex], '', '[-_]keys$', 'IR');
      insertKeyDefs(keyTableIndex, mode, '', commandIndexTable);
   }
}

/**
 * Update a new keybinding.  If the current tree index is
 * unbound, then change it's caption to the new binding.
 * Otherwise add a new tree item.
 */
static addKeyBindingToTree(int curIndex, _str commandName, _str keySequence, _str modeName)
{
   commandIndex := find_index(commandName, COMMAND_TYPE);
   if (commandIndex) {
      parse name_info(commandIndex) with ',' auto flags;
      isUserMacro := (flags != '' && ((int)flags & VSARG2_MACRO));

      _str isMacro = isUserMacro ? "Yes" : "No";
      mode := stranslate(modeName, '', '[-_]keys$', 'IR');
      newIndex := _TreeAddItem(TREE_ROOT_INDEX, commandName"\t"keySequence"\t"mode"\t":+isMacro, TREE_ADD_AS_CHILD, 0, 0, -1);
      userData := commandName"\t"keySequence"\t"modeName"\t"commandIndex"\t"isUserMacro;
      _TreeSetUserInfo(newIndex, userData);
      _TreeSetCurIndex(newIndex);
      sortAZ := _GetDialogInfoHt("sortAZ");
      if ( sortAZ ) {
         _TreeSortUserInfo(TREE_ROOT_INDEX, 'NI', 'NID');
      } else {
         _TreeSortUserInfo(TREE_ROOT_INDEX, 'NID', 'NID');
      }
   }
   if (curIndex != TREE_ROOT_INDEX) { // maybe remove old index
      info := _TreeGetUserInfo(curIndex);
      parse info with . "\t" auto curKeySequence "\t" .;
      if (curKeySequence == '') { // previous index was unbound, don't need to display it anymore
         _TreeDelete(curIndex);
      }
   }

   INTARRAY commandTreeIndex:[];
   getCommandTreeIndices(commandTreeIndex);
   _SetDialogInfoHt("commandTreeIndex", commandTreeIndex);
}

/**
 * If this command has other bindings then just remove it from
 * the tree.  Otherwise, leave it in the tree and remove
 * keySequence parameter.
 */
static removeKeyBindingFromTree(int curIndex)
{
   commandName := "";
   modeName := "";
   commandIndex := "";
   isUserMacro := "";
   int treeIndex = TREE_ROOT_INDEX;
   typeless userData = _TreeGetUserInfo(curIndex);
   parse userData with commandName "\t" . "\t" modeName "\t" commandIndex "\t" isUserMacro;

   while (treeIndex >= 0) {
      treeIndex = _TreeSearch(treeIndex, commandName"\t", 'PTSH');
      if (treeIndex >= 0 && (treeIndex != curIndex)) {
         break;
      }
   }
   if (treeIndex >= 0 && treeIndex != curIndex) {
      _TreeDelete(curIndex);
   } else {
      caption :=  commandName"\t\t\t";
      if (isUserMacro == '1') {
         caption :+= "Yes";
      } else {
         caption :+= "No";
      }
      userData = commandName"\t\t\t"commandIndex"\t"isUserMacro;
      _TreeSetCaption(curIndex, caption);
      _TreeSetUserInfo(curIndex, userData);

      filterCommands(ctlcommand_box.p_text, ctlkeysequence_box.p_text);
      sortAZ := _GetDialogInfoHt("sortAZ");
      if ( sortAZ ) {
         _TreeSortUserInfo(TREE_ROOT_INDEX, 'NI', 'NID');
      } else {
         _TreeSortUserInfo(TREE_ROOT_INDEX, 'NID', 'NID');
      }
      call_event(CHANGE_SELECTED, _TreeCurIndex(), p_window_id, ON_CHANGE, 'W');
   }

   INTARRAY commandTreeIndex:[];
   getCommandTreeIndices(commandTreeIndex);
   _SetDialogInfoHt("commandTreeIndex", commandTreeIndex);
}

static void buildKeyBindingTree(_str (&keyTableNames):[], bool includeUnboundCommands=true)
{
   INTARRAY commandIndexTable:[] = null;
   _TreeBeginUpdate(TREE_ROOT_INDEX);
   _TreeDelete(TREE_ROOT_INDEX, 'C');

   insertBindings(keyTableNames, commandIndexTable);
   if (includeUnboundCommands) {
      insertCommandList(commandIndexTable);
   }
   sortAZ := _GetDialogInfoHt("sortAZ");
   if ( sortAZ ) {
      _TreeSortUserInfo(TREE_ROOT_INDEX, 'NI', 'NID');
   } else {
      _TreeSortUserInfo(TREE_ROOT_INDEX, 'NID', 'NID');
   }
   _TreeEndUpdate(TREE_ROOT_INDEX);
   _TreeTop();

   _SetDialogInfoHt("commandTreeIndex", commandIndexTable);
}

void ctlbind.on_create(_str command_name = '')
{
   _keybindings_form_initial_alignment();
   ctlkeysequence_box.p_window_flags|=VSWFLAG_NO_AUTO_MAP_PAD_KEYS;

   _nocheck _control ctlcommandbindings;
   lang := "";
   modename := "";
   int wid = _form_parent();
   if (wid && wid._isEditorCtl()) {
      lang = wid.p_LangId;
      modename = wid.p_mode_name;
   }

   p_active_form.p_caption = 'Key Bindings - 'longEmulationName(def_keys);
   _SetDialogInfoHt("currentExtension", lang);
   _SetDialogInfoHt("currentModeName", modename);
   _SetDialogInfoHt("sortAZ", 1);

   if (command_name != '') {
      typeless prevValue = _GetDialogInfoHt("ctlcommand_box.on_change");
      _SetDialogInfoHt("ctlcommand_box.on_change", true);
      ctlcommand_box.p_text = command_name;
      _SetDialogInfoHt("ctlcommand_box.on_change", false);
   }

   _str keyTableNames:[];
   enumerateKeyTables(keyTableNames);
   _SetDialogInfoHt("keyTableNames", keyTableNames);

   wid = p_window_id;
   p_window_id = ctlcommandbindings;

   colwidth := (p_width intdiv 4) -90;

   _TreeSetColButtonInfo(0,
                         colwidth,
                         TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,
                         0,
                         'Command');
   _TreeSetColButtonInfo(1,
                         colwidth,
                         TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,
                         0,
                         'Key Sequence');
   _TreeSetColButtonInfo(2,colwidth,
                         TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,
                         0,
                         'Mode');
   _TreeSetColButtonInfo(3,colwidth,
                         TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_AL_RIGHT|TREE_BUTTON_AUTOSIZE,
                         0,
                         'Recorded');

   // we only do this if the form is visible - otherwise this step is taken care 
   // of in the init_for_options
   if (p_active_form.p_visible) {
      buildKeyBindingTree(keyTableNames);
      filterCommands(ctlcommand_box.p_text, ctlkeysequence_box.p_text);
   } 

   p_window_id=wid;

   ctlcommand_documentation.p_backcolor = 0x80000022;
   ctlcommand_documentation.p_PaddingY = 0;

   //Restore the position on the divider bar.
   typeless ypos = _moncfg_retrieve_value("_keybindings_form.ctl_size_y.p_y");
   if (isuinteger(ypos)) {
      ctl_size_y.p_y = ypos;
   } 
   SPLITTER_POS(ctl_size_y.p_y);

   RESIZING_KEYBINDINGS(false);
}

void resize_columns()
{
   width := ctlcommandbindings.p_width;

   // columns are 30%/30%/20%/15% - the extra 5% is for the scroll bar
   ctlcommandbindings._TreeSetColButtonInfo(0, (int)(width * 0.3));
   ctlcommandbindings._TreeSetColButtonInfo(1, (int)(width * 0.3));
   ctlcommandbindings._TreeSetColButtonInfo(2, (int)(width * 0.20));
   ctlcommandbindings._TreeSetColButtonInfo(3, (int)(width * 0.15));
}



/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _keybindings_form_initial_alignment()
{
   padding := ctlcommand_box.p_x;
   rightAlign := (p_active_form.p_width - padding*4);
   commandBoxWidth := (p_active_form.p_width - (4 * padding + ctlclear_keysequence.p_width +
                                  ctlclear_command.p_width + ctlmouse_events.p_width +
                                  ctlOR_label.p_width + PADDING_BETWEEN_BUTTONS +
                                  2 * PADDING_BETWEEN_TEXTBOX_AND_BUTTON)) intdiv 2;

   sizeBrowseButtonToTextBox(ctlcommand_box.p_window_id, 
                             ctlclear_command.p_window_id,
                             ctlmouse_events.p_window_id,
                             rightAlign);
   ctlcommand_box.p_width = ctlkeysequence_box.p_width;

   ctlOR_label.p_x = ctlclear_command.p_x_extent + padding;
   ctlOR_label.p_auto_size = false;
   ctlOR_label.p_height = ctlclear_command.p_height;

   ctlkeysequence_label.p_x = ctlkeysequence_box.p_x = ctlOR_label.p_x_extent + padding;

   sizeBrowseButtonToTextBox(ctlkeysequence_box, ctlclear_keysequence,
                             ctlmouse_events, ctlcommandbindings.p_x_extent);
}

void _keybindings_form.on_resize()
{
   if (RESIZING_KEYBINDINGS()) return;
   RESIZING_KEYBINDINGS(true);

   // check for reposition of the splitter - less work!
   if (SPLITTER_POS() != ctl_size_y.p_y) {
      diff := ctlcommandbindings.p_y_extent - ctl_size_y.p_y;

      ctlcommand_documentation.p_y -= diff;
      ctlcommand_documentation.p_height += diff;
      ctlcommandbindings.p_height -= diff;
      SPLITTER_POS(ctl_size_y.p_y);
   } else {
   
      padding := ctlcommandbindings.p_x;
      widthDiff := p_width - (ctlcommandbindings.p_x_extent + padding);
      heightDiff := p_height - (ctlhintbar.p_y_extent + padding);

      // top labels, textboxes, and buttons
      halfDiff := widthDiff intdiv 2;

      ctlcommand_box.p_x = padding;
      sizeBrowseButtonToTextBox(ctlcommand_box.p_window_id,
                                ctlclear_command.p_window_id,
                                0,
                                (p_width intdiv 2) - 2*padding - ctlOR_label.p_width);
      ctlOR_label.p_x = ctlclear_command.p_x_extent + padding;

      ctlkeysequence_label.p_x = ctlkeysequence_box.p_x = (p_width intdiv 2) + padding;
      sizeBrowseButtonToTextBox(ctlkeysequence_box.p_window_id,
                                ctlclear_keysequence.p_window_id,
                                ctlmouse_events.p_window_id,
                                p_width - padding);

      //The bindings.
      ctlcommandbindings.p_width += widthDiff;
   
      resize_columns();
   
      //The buttons.
      ctlimport.p_y += heightDiff;
      ctlexport.p_y = ctlsave_chart.p_y = ctlrun.p_y = ctlbind.p_y = ctlunbind.p_y = ctlimport.p_y;
   
      //Buttons for macro mode.
      ctlbind.p_x += widthDiff;
      ctlunbind.p_x += widthDiff;
   
      ctlhintbar.p_y += heightDiff;
   
      //The size bar.
      ctl_size_y.p_width += widthDiff;

      totalHeight := ctlcommand_documentation.p_height + ctlcommandbindings.p_height;
      ratio := (double)ctlcommandbindings.p_height / (double)totalHeight;
      remainingHeight := totalHeight + heightDiff;
   
      ctlcommandbindings.p_height = (int)(ratio * (double)remainingHeight);
      ctlcommand_documentation.p_height = remainingHeight - ctlcommandbindings.p_height;
      ctl_size_y.p_y = ctlcommandbindings.p_y_extent;
      SPLITTER_POS(ctl_size_y.p_y);
   
      ctlcommand_documentation.p_y = ctl_size_y.p_y_extent;
      ctlcommand_documentation.p_width += widthDiff;
   }

   RESIZING_KEYBINDINGS(false);
}

void _keybindings_form.on_destroy()
{
   _moncfg_append_retrieve(0, ctl_size_y.p_y, "_keybindings_form.ctl_size_y.p_y");
}

ctl_size_y.lbutton_down()
{
   _ul2_image_sizebar_handler(ctlcommandbindings.p_y*2,
                              ctlcommand_documentation.p_y +
                              ctlcommand_documentation.p_height - 240);
}

/**
 * Set a flag when ctlkeysequence_box gets focus
 */
void ctlkeysequence_box.on_got_focus()
{
   // Set boolean that we had an onGotFocus event so we can throw out lbuttondn/lbuttonup
   _SetDialogInfoHt("throwAwayButtonDown", true);
   // For some reason, we get here twice when click
   _MacGiveKeyToSlickEdit(true);
}
void ctlkeysequence_box.on_lost_focus()
{
   // For some reason, on_got_focus gets called too many times
   _MacGiveKeyToSlickEdit(false);
   _MacGiveKeyToSlickEdit(false);
}
void ctlkeysequence_box.on_destroy()
{
   // For some reason, on_got_focus gets called too many times
   _MacGiveKeyToSlickEdit(false);
   _MacGiveKeyToSlickEdit(false);
}

static void maybeClearPastEvents()
{
   typeless prevValue = _GetDialogInfoHt("ctlkeysequence_box.on_change");
   _SetDialogInfoHt("ctlkeysequence_box.on_change", true);
   clearPastEvents := _GetDialogInfoHt("clearPastEvents");
   // Have to check w/ ==true, because it "if (null)" will be a runtime error
   if (clearPastEvents == true) {
      ctlkeysequence_box.p_text = "";
      _SetDialogInfoHt("clearPastEvents", false);
   }
   _SetDialogInfoHt("ctlkeysequence_box.on_change", prevValue);
}

/**
 * Insert name of the mouse event into ctlkeysequence_box
 */
void ctlkeysequence_box.'range-first-mouse-event'-'all-range-last-mouse-event'()
{
   // The ctlkeysequence_box.on_got_focus() event sets the throwAwayButtonDown
   // variable that is stored in the dialog info.  This is so when the user clicks
   // to give focus "LbuttonDn" does not get inserted into the list
   throwAwayButtonDown := _GetDialogInfoHt("throwAwayButtonDown");
   wid := _get_focus();
   if ( wid ) {
      if (_get_focus() == ctlkeysequence_box) {
         event_name := strip(event2name(last_event(), 'L'));
         lowcase_event_name := lowcase(event_name);
         if (throwAwayButtonDown && endsWith(lowcase_event_name,"buttondn",true)) {
            // if we have lbuttondn and onGotFocus, do nothing, wait for lbuttonup
            _SetDialogInfoHt("throwAwayButtonDown", false);
         } else if (endsWith(lowcase_event_name,"buttonup",true)) {
            _SetDialogInfoHt("throwAwayButtonUp", false);
         } else if (event_name!="MouseMove") {
            if (endsWith(event_name,"Click",true)) {
               maybeClearPastEvents();
               p_text = event_name;
               _SetDialogInfoHt("throwAwayButtonUp", true);
            } else {
               maybeClearPastEvents();
               p_text = strip(p_text' 'event_name);
            }
            end_line();
         }
      }
   }
}

/**
 * Insert character for the event into ctlkeysequence_box
 */
void ctlkeysequence_box.'range-first-nonchar-key'-'all-range-last-nonchar-key','range-first-char-key'-'range-last-char-key',ON_SCROLL_LOCK()
{
   event := last_event();
   maybeClearPastEvents();
   p_text = strip(p_text' 'event2name(event, 'L'));
   end_line();
   return;
}

static void _keybindings_form_on_key_change()
{
   ctlcommandbindings.filterCommands(ctlcommand_box.p_text, ctlkeysequence_box.p_text);
}

/**
 * Filter the tree according to what is in ctlkeysequence_box.
 */
void ctlkeysequence_box.on_change()
{
   if (_GetDialogInfoHt("ctlkeysequence_box.on_change") == true) {
      return;
   }
   _SetDialogInfoHt("ctlkeysequence_box.on_change",true);
   maybeClearPastEvents();
   if (p_active_form.p_name == "_keybindings_form") {
      p_active_form._keybindings_form_on_key_change();
   } else if (p_active_form.p_name == "_bind_one_key_form") {
      p_active_form._bindkey_form_on_key_change();
   } else if (p_active_form.p_name == "_what_is_form") {
      p_active_form._what_is_form_on_key_change();
   }
   _SetDialogInfoHt("ctlkeysequence_box.on_change",false);
   return;
}

void ctlclear_keysequence.lbutton_up()
{
   clearKeySequenceBox();
}

/**
 * Clear box
 */
static void clearKeySequenceBox()
{
   ctlkeysequence_box.p_text = "";
   ctlkeysequence_box.end_line();
}

/**
 * @return _str name of command currently selected in ctlcommandbindings
 */
static _str currentCommandName()
{
   caption := "";
   command := "";
   index := 0;
   index = ctlcommandbindings._TreeCurIndex();
   caption = ctlcommandbindings._TreeGetCaption(index);

   parse caption with command "\t" .;

   return strip(command);
}

/**
 * on_change event for the column control with the list of
 * commands
 * @param reason change reason
 * @param index index that change occured to
 *
 * @return int
 */
int ctlcommandbindings.on_change(int reason, int index, int col=-1)
{
   switch (reason) {
   case CHANGE_BUTTON_PRESS:
      sortAZ := _GetDialogInfoHt("sortAZ");
      if (col == 0) {
         if ( sortAZ ) {
            _TreeSortUserInfo(TREE_ROOT_INDEX, 'NI', 'NID');
         } else {
            _TreeSortUserInfo(TREE_ROOT_INDEX, 'NID', 'NID');
         }
         _SetDialogInfoHt("sortAZ",!sortAZ);
      }
      break;
   case CHANGE_SELECTED:
      if (index <= 0) {
         ctlbind.p_enabled = false;
         ctlunbind.p_enabled = false;
         ctlcommand_documentation.p_text = "";
         return 0;
      }

      cmdBinding := "";

      //Disable unbind key if the current row is an unbound entry.
      caption := _TreeGetCaption(index);
      parse caption with . "\t" cmdBinding "\t" .;
      ctlbind.p_enabled = true;
      if (cmdBinding != '') {
         ctlunbind.p_enabled = true;
      } else {
         ctlunbind.p_enabled = false;
      }
      _str htmlDocs = tag_command_html_documentation(currentCommandName());
      ctlcommand_documentation.p_text = htmlDocs;
      break;
   case CHANGE_EDIT_OPEN:
      break;
   case CHANGE_EDIT_CLOSE:
      break;
   case CHANGE_LEAF_ENTER:
      if (index != TREE_ROOT_INDEX) {
         ctlbind.call_event(ctlbind, LBUTTON_UP);
      }
      break;
   case CHANGE_EDIT_QUERY:
      break;
   default:
      break;
   }
   return 0;
}

void ctlcommandbindings.del()
{
   cmdBinding := "";
   _str caption = _TreeGetCaption(_TreeCurIndex());
   parse caption with . "\t" cmdBinding "\t" .;
   if (cmdBinding != '') {
      ctlunbind.call_event(ctlunbind, LBUTTON_UP);
   }
}

void ctlcommandbindings."C-."()
{
   caption := _TreeGetCaption(_TreeCurIndex());
   parse caption with auto commandName "\t" .;
   if (commandName != "") {
      find_proc(commandName);
   }
}

void ctlcommand_documentation.on_change(int reason, _str hrefText)
{
   if (reason == CHANGE_CLICKED_ON_HTML_LINK) {
      if (substr(hrefText,1,7)=="help://") {
         help(substr(hrefText,8));
         return;
      }
      if (substr(hrefText,1,1)!=JAVADOCHREFINDICATOR) {
         tag_goto_url(hrefText);
         return;
      }
      // Don't think we need to be fancier here like in tag_match_href_text()
      _str help_item;
      parse substr(hrefText, 2) with help_item '()';
      help(help_item);
   }
}

void ctlmouse_events.'range-first-mouse-event'-'all-range-last-mouse-event'()
{
   evIndex := event2index(last_event());
   if ((evIndex & ~VSEVFLAG_ALL_SHIFT_FLAGS) == VSEV_LBUTTON_DOWN ||
       (evIndex & ~VSEVFLAG_ALL_SHIFT_FLAGS) == VSEV_RBUTTON_DOWN ||
       (evIndex & ~VSEVFLAG_ALL_SHIFT_FLAGS) == VSEV_MBUTTON_DOWN
      ) {
      new_event := getMouseEvent(evIndex & VSEVFLAG_ALL_SHIFT_FLAGS);
      if (new_event :!= '' && new_event != COMMAND_CANCELLED_RC) {
         ctlkeysequence_box.p_text = strip(ctlkeysequence_box.p_text' 'new_event);
         ctlkeysequence_box._end_line();
      }
   }
}

/******************************************************************************/

void ctlsave_chart.lbutton_up()
{
   fileName := "keychart.html";
   if (!getFileName(fileName, get_env("HOME"), true,'*.html')) {
      return;
   }
   saveKeyChart(fileName);
}

void ctlimport.lbutton_up()
{
   import_key_bindings();

   _str keyTableNames:[] = _GetDialogInfoHt("keyTableNames");
   ctlcommandbindings.buildKeyBindingTree(keyTableNames);
   ctlcommandbindings.filterCommands(ctlcommand_box.p_text, ctlkeysequence_box.p_text);
   p_active_form.p_caption = 'Key Bindings - 'longEmulationName(def_keys);
}

void ctlexport.lbutton_up()
{
   export_key_bindings();
}

/******************************************************************************/

void ctlbind.lbutton_up()
{
   commandName := "";
   keySequence := ctlkeysequence_box.p_text;
   curIndex := ctlcommandbindings._TreeCurIndex();
   caption := ctlcommandbindings._TreeGetCaption(curIndex);
   parse caption with commandName "\t" .;

   _str modeName = _GetDialogInfoHt("currentModeName");
   typeless result = show("-modal _bind_one_key_form", commandName, modeName, keySequence);
   if (!result) {
      //_param1 = keyTable;
      //_param2 = keySequence;
      //_param3 = false;      // key already bound?
      if (_param3) {  // I don't know what bindings got deleted so rebuild tree
         _str keyTableNames:[] = _GetDialogInfoHt("keyTableNames");
         ctlcommandbindings.buildKeyBindingTree(keyTableNames);
         ctlcommandbindings.filterCommands(ctlcommand_box.p_text, ctlkeysequence_box.p_text);
      } else {
         ctlcommandbindings.addKeyBindingToTree(curIndex, commandName, _param2, _param1);
      }
   }
}

void ctlunbind.lbutton_up()
{
   _str commandName;
   _str keySequence;
   _str modeName;
   index := ctlcommandbindings._TreeCurIndex();
   caption := ctlcommandbindings._TreeGetCaption(index);
   parse caption with commandName "\t" keySequence "\t" modeName "\t" .;

   if (pos("->", keySequence, 1) > 0) {
      int buttonResult = _message_box("Unbind '"commandName"' from entire range '"keySequence"'?", '', MB_YESNO);
      if (buttonResult == IDNO) {
         return;
      }
   } else {
      int buttonResult = _message_box("Unbind '"commandName"' from '"keySequence"'?", '', MB_YESNO);
      if (buttonResult == IDNO) {
         return;
      }
   }
   _str keyTable = getKeyTable(modeName);
   int status = unbind(keyTable, keySequence);
   if (!status) {
      ctlcommandbindings.removeKeyBindingFromTree(index);
      if (keyTable=='default-keys') {
         _eventtab_set_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_def_keys_2_profile_name(),_default_keys);
      } else {
         _eventtab_set_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_eventtab_name_2_profile_name(keyTable),_eventtab_get_mode_keys(keyTable));
      }
   }
}

/******************************************************************************/

void ctlrun.lbutton_up()
{
   commandName := ctlcommandbindings.currentCommandName();
   p_active_form._delete_window(commandName);
}

/******************************************************************************/

static int getFileName(_str& suggestedFileName, _str initDir, bool doSave,_str initial_wildcards='*.cfg.xml',_str file_types='XML Config Files (*.cfg.xml);'def_file_types) {
   fileName := "";
   if (suggestedFileName == '') {
      fileName = _def_keys_2_emulation_profile_suffix(def_keys):+VSCFGFILEEXT_CFGXML;
   } else {
      fileName = suggestedFileName;
   }

   unixflags := 0;
   if (_isUnix()) {
      _str attrs = file_list_field(fileName, DIR_ATTR_COL, DIR_ATTR_WIDTH);
      _str w = pos('w', attrs, '', 'i');
      if (!w && (attrs != '')) {
         unixflags = OFN_READONLY;
      }
   }
   initFilename := "";
   if (initDir == '') {
      initDir = _maybe_quote_filename(_ConfigPath());
   }
   title := "";
   flags := 0;
   if (doSave) {
      title = 'Save As';
      flags = OFN_SAVEAS|OFN_KEEPOLDFILE;
      if (_FileQType(fileName) == VSFILETYPE_NORMAL_FILE) {
         initFilename = fileName;
      } else {
         initFilename = _strip_filename(fileName, 'P');
      }
   } else {
      title = 'Open';
      initFilename='';
   }
   _str result = _OpenDialog('-modal',
                             title,
                             initial_wildcards,     // Initial wildcards
                             file_types,  // file types
                             flags|unixflags,
                             def_ext,      // Default extensions
                             initFilename, // Initial filename
                             initDir,      // Initial directory
                             '',      // Reserved
                             title" dialog box"
                            );
   if (result == '') {
      return 0;
   }
   if (doSave) {
      //results = strip_options(result, options, true);
      fileName = stranslate(result, '', '^\+ftext ', 'IR');
   } else {
      fileName = result;
   }
   suggestedFileName = strip(strip(fileName),'B','"');
   if (_file_eq(_strip_filename(suggestedFileName,'P'),VSCFGFILE_USER)) {
      _message_box(nls("For safety, this filename may not be '%s' because it is used for non-key binding related configuration data",VSCFGFILE_USER));
      return 0;
   }
   return 1;
}

/******************************************************************************/

static _str _safehtmlstr(_str s)
{
   s = stranslate(s, "&amp;", "&");
   s = stranslate(s, "&gt;", ">");
   s = stranslate(s, "&lt;", "<");

   return (s);
}

static void printKeyBindingsChart(int _root_keys, _str mode, _str prefixKeys)
{
   VSEVENT_BINDING list[];
   list_bindings(_root_keys, list);
   keyTable := "";
   NofBindings := list._length();
   i := 0;
   bindingIndex := 0;
   keyName := "";
   command := "";

   //Insert key bindings
   for (i = 0; i < NofBindings; ++i) {
      bindingIndex = list[i].binding;
      //If something is bound to a command ...
      if (bindingIndex && (name_type(bindingIndex) & COMMAND_TYPE)) {
         //... and it's a reasonable event ...
         if (!vsIsOnEvent(list[i].iEvent)) {
            keyName = _safehtmlstr(strip(event2name(index2event(list[i].iEvent), 'L')));
            command = strip(name_name(bindingIndex));
            if (list[i].iEvent != list[i].iEndEvent) {
               keyName :+= "&nbsp;-&gt;&nbsp;" :+ _safehtmlstr(strip(event2name(index2event(list[i].iEndEvent), 'L')));
            }
            insert_line("\t\t\t<tr>");
            insert_line("\t\t\t\t<td align=left>"command"</td>");
            insert_line("\t\t\t\t<td align=right>"prefixKeys:+keyName"</td>");
            insert_line("\t\t\t</tr>");
         }
      }
   }

   //Recurse and insert key bindings nested in a deeper event table.
   for (i = 0; i < NofBindings; ++i) {
      bindingIndex = list[i].binding;
      if (bindingIndex && (name_type(bindingIndex) & EVENTTAB_TYPE) ) {
         keyName = event2name(index2event(list[i].iEvent), 'L');
         printKeyBindingsChart(bindingIndex, mode, prefixKeys:+keyName:+'&nbsp;');
      }
   }
}

static void saveKeyChart(_str fileName = '')
{
   htmlViewID := 0;
   originalID := _find_or_create_temp_view(htmlViewID, "", fileName);
   p_window_id = htmlViewID;
   p_buf_name = fileName;

   top();
   insert_line("<html>");
   insert_line("\t<head>");
   insert_line("\t\t<title>"longEmulationName(def_keys)" Emulation</title>");
   insert_line("\t</head>");
   insert_line("\t<body>");
   insert_line("\t<div width=100% style=\"-moz-column-width: 18em;":+
               " -moz-column-rule: solid black 1em;":+
               " -moz-column-gap: 4em\">");


   _str keyTableNames:[];
   enumerateKeyTables(keyTableNames);

   typeless keyTableIndex;
   keyTableIndex._makeempty();
   while (true) {
      keyTableNames._nextel(keyTableIndex);
      if (keyTableIndex._isempty()) {
         break;
      }
      mode := stranslate(keyTableNames:[keyTableIndex], '', '[-_]keys$', 'IR');

      insert_line("\t\t<table width=100% border=1>");
      insert_line("\t\t\t<tr>");
      insert_line("\t\t\t\t<th colspan=\"2\" align=left>Mode: "mode"</th>");
      insert_line("\t\t\t</tr>");
      insert_line("\t\t\t<tr>");
      insert_line("\t\t\t\t<th align=left>Command</th>");
      insert_line("\t\t\t\t<th align=right>Key Sequence</th>");
      insert_line("\t\t\t</tr>");
      printKeyBindingsChart(keyTableIndex, mode, '');
      insert_line("\t\t</table><p>");
   }

   insert_line("\t</div>");
   insert_line("\t</body>");
   insert_line("</html>");
   save_as(_maybe_quote_filename(fileName));

   p_window_id = originalID;
   _delete_temp_view(htmlViewID);
}

/******************************************************************************/

/**
 * Imports the keybindings definitions found in an XML file into the given key 
 * table. 
 * 
 * @param treeHandle 
 * @param nodeIndex 
 * @param keyTable 
 * 
 * @return        0 if all keybindings were imported successfully, non-zero 
 *                otherwise.  Even if one binding fails, then the rest are still
 *                attempted.
 */
static int importKeyDefs(int treeHandle, int nodeIndex, _str keyTable)
{
   bindingNode := 0;
   bindingNode = _xmlcfg_get_first_child(treeHandle, nodeIndex,
                                         VSXMLCFG_NODE_ELEMENT_START_END);
   status := 0;
   while (bindingNode > 0) {
      command := _xmlcfg_get_attribute(treeHandle, bindingNode, 'Command', '');
      key := _xmlcfg_get_attribute(treeHandle, bindingNode, 'Key', '');
      key = formatImportedKey(key);
      name := _xmlcfg_get_name(treeHandle, bindingNode);

      if (name == 'Assign') {
         status |= bind(command, keyTable, key);
      } else if (name == 'Remove') {
         status |= unbind(keyTable, key);
      }
      bindingNode = _xmlcfg_get_next_sibling(treeHandle, bindingNode,
                                             VSXMLCFG_NODE_ELEMENT_START_END);
   }

   return status;
}

/**
 * Resets the keybindings to the base emulation set by first 
 * removing all user keybindings, then importing the emulation's 
 * base set. 
 */
void resetEmulationKeyBindings(_str keys=def_keys)
{
   _plugin_delete_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_def_keys_2_profile_name(keys));
   if (keys=='vi-keys') {
      kt_name:='vi_command_keys';
      _plugin_delete_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_eventtab_name_2_profile_name(kt_name));
      kt_name='vi_visual_keys';
      _plugin_delete_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_eventtab_name_2_profile_name(kt_name));
   }
   if (keys==def_keys) {
      _set_emulation_key_bindings(true);
   }
}

/******************************************************************************/
/**
 * Changes all the 'Option' to 'Alt', so that running this on
 * either platform will end up with same output.
 *
 * @param key
 *
 * @return _str
 */
static _str formatKeyForExport(_str key)
{
   return stranslate(key, 'Alt', 'Option');
}

static _str formatImportedKey(_str key)
{
   if (_isMac()) {
      return stranslate(key, 'Option', 'Alt');
   } else {
      return stranslate(key, 'Alt', 'Option');
   }
}

/******************************************************************************/

static void traverseUserKeyBingings(int _root_keys, _str mode,
                                     _str prefixKeys, _str (&localBindings):[]:[])
{
   VSEVENT_BINDING list[];
   list_bindings(_root_keys, list);

   NofBindings := list._length();
   i := 0;
   bindingIndex := 0;
   keyName := "";
   command := "";
   //Insert the un-nested key bindings.
   for (i = 0; i < NofBindings; ++i) {
      bindingIndex = list[i].binding;
      //If something is bound to a command ...
      if (bindingIndex && (name_type(bindingIndex) & COMMAND_TYPE)) {
         //... and it's a reasonable event ...
         if (!vsIsOnEvent(list[i].iEvent)) {
            keyName = strip(event2name(index2event(list[i].iEvent), 'L'));
            command = strip(name_name(bindingIndex));
            if (list[i].iEvent != list[i].iEndEvent) {
               keyName :+= " -> " :+ strip(event2name(index2event(list[i].iEndEvent), 'L'));
            }
            localBindings:[mode]:[prefixKeys:+keyName] = command;
         }
      }
   }
   //Recurse and insert key bindings nested in a deeper event table.
   for (i = 0; i < NofBindings; ++i) {
      bindingIndex = list[i].binding;
      if (bindingIndex && (name_type(bindingIndex) & EVENTTAB_TYPE) && !vsIsOnEvent(list[i].iEvent)) {
         traverseUserKeyBingings(bindingIndex, mode, prefixKeys:+
                       event2name(index2event(list[i].iEvent), 'L'):+' ',localBindings);
      }
   }
}

static void getUserKeyBindings(_str (&localBindings):[]:[])
{
   _str keyTableNames:[];
   enumerateKeyTables(keyTableNames);

   //Insert all bindings.
   typeless keyTableIndex;
   keyTableIndex._makeempty();
   while (true) {
      keyTableNames._nextel(keyTableIndex);
      if (keyTableIndex._isempty()) {
         break;
      }
      mode := stranslate(keyTableNames:[keyTableIndex], '', '[-_]keys$', 'IR');
      traverseUserKeyBingings(keyTableIndex, mode, '', localBindings);
   }
}

static void traverseBaseKeyBindings(int treeHandle, int node, _str modeName,
                                    _str (&baseBindings):[]:[],
                                    _str prefixKeys = '')
{
   command := "";
   key := "";
   keyTable := "";
   keySequence := "";
   name := "";

   //Record individual key bindings
   bindingNode := 0;
   bindingNode = _xmlcfg_get_first_child(treeHandle, node,
                                         VSXMLCFG_NODE_ELEMENT_START_END);
   while (bindingNode > 0) {
      command = _xmlcfg_get_attribute(treeHandle, bindingNode, 'Command', '');
      key = _xmlcfg_get_attribute(treeHandle, bindingNode, 'Key', '');
      key = formatImportedKey(key);

      //record here:
      baseBindings:[modeName]:[strip(prefixKeys' 'key)] = command;

      bindingNode = _xmlcfg_get_next_sibling(treeHandle, bindingNode,
                                             VSXMLCFG_NODE_ELEMENT_START_END);
   }

   prefixName := "";
   tableNode := 0;
   tableNode = _xmlcfg_find_child_with_name(treeHandle, node,
                                            'Prefix',
                                            VSXMLCFG_NODE_ELEMENT_START);
   while (tableNode > 0) {
      prefixName = _xmlcfg_get_attribute(treeHandle, tableNode, 'Key', '');
      prefixName = formatImportedKey(prefixName);

      traverseBaseKeyBindings(treeHandle, tableNode, modeName, baseBindings, prefixName);

      tableNode = _xmlcfg_get_next_sibling(treeHandle, tableNode,
                                           VSXMLCFG_NODE_ELEMENT_START);
   }
}

static int importBaseKeyBindings (_str base, _str (&baseBindings):[]:[]=null)
{
   fileName := _getSysconfigMaybeFixPath("keybindings" :+ FILESEP :+ longEmulationName(base) :+ ".xml");
   status := 0;
   treeHandle := _xmlcfg_open(fileName, status, 0, VSENCODING_UTF8);
   if (treeHandle < 0) {
      _message_box("Could not open "fileName);
      return -1;
   }

   kbNode := -1;
   kbNode = _xmlcfg_find_child_with_name(treeHandle, TREE_ROOT_INDEX,
                                         'KeyBindings',
                                         VSXMLCFG_NODE_ELEMENT_START);
   if (kbNode < 0) {
      _message_box("Could not find keybindings in "fileName);
      return -1;
   }

   _str emulationKeys = _xmlcfg_get_attribute(treeHandle, kbNode, 'Emulation');
   if (longEmulationName(base) != emulationKeys) {
      _message_box("Could not recognize base emulation in "fileName);
      return -1;
   }

   baseBindings = null;

   modeName := "";
   modeNode := 0;
   modeNode = _xmlcfg_find_child_with_name(treeHandle, kbNode, 'Mode',
                                           VSXMLCFG_NODE_ELEMENT_START);
   i := 1;
   while (modeNode > 0) {
      modeName = _xmlcfg_get_attribute(treeHandle, modeNode, 'Name', '');
      traverseBaseKeyBindings(treeHandle, modeNode, modeName, baseBindings);
      modeNode = _xmlcfg_get_next_sibling(treeHandle, modeNode,
                                          VSXMLCFG_NODE_ELEMENT_START);
   }
   _xmlcfg_close(treeHandle);
   return 0;
}

/**
 * Determines whether the current emulation (def-keys) has any 
 * custom keybindings. 
 * 
 * @return true if custom keybindings exist for current 
 *         emulation
 */
bool isEmulationCustomized(_str keys)
{
   if (_plugin_is_modified_builtin_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_def_keys_2_profile_name(keys))) {
      return true;
   }
   if (keys=='vi-keys') {
      kt_name:='vi_command_keys';
      if (_plugin_is_modified_builtin_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_eventtab_name_2_profile_name(kt_name))) {
         return true;
      }
      kt_name='vi_visual_keys';
      if (_plugin_is_modified_builtin_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_eventtab_name_2_profile_name(kt_name))) {
         return true;
      }
   }
   return false;
}

_command void import_key_bindings(_str fileName = '') name_info(FILE_ARG','VSARG2_CMDLINE)
{
   if (fileName == '') {
      if (!getFileName(fileName, '', false)) {
         return;
      }
   }
   fileName=strip(fileName);
   _str optionAttrs:[];
   _import_key_bindings_from_file(fileName,optionAttrs);
   _str *pstr=optionAttrs._indexin(VSCFGOPTIONS_ATTR_EMULATION);
   if (pstr) {
      if (*pstr!=_def_keys_2_profile_name()) {
         buttonResult := 0;
         emulation:= *pstr;
         buttonResult = _message_box(nls("Do you want to switch to '%s' emulation?",emulation),'', MB_YESNOCANCEL);
         if (buttonResult == IDYES) {
            shell('emulate 'shortEmulationName(emulation));
         } else if (buttonResult == IDCANCEL) {
            return;
         }
      } else {
         _set_emulation_key_bindings();
      }
   }
}

_command void export_key_bindings(_str fileName = '') name_info(FILE_ARG','VSARG2_CMDLINE)
{
   if (fileName == '') {
      if (!getFileName(fileName, '', true)) {
         return;
      }
   }
   fileName=strip(fileName);
   //_keybindings_form_export_settings(fileName);
   _update_profiles_for_modified_eventtabs();
   _str optionAttrs:[];
   optionAttrs:[VSCFGOPTIONS_ATTR_EMULATION]=_def_keys_2_emulation_profile_suffix();
   _plugin_export_profiles(fileName,VSCFGPACKAGE_EVENTTAB_PROFILES,optionAttrs,true);
}

/******************************************************************************/

defeventtab _bind_one_key_form;

void _bind_one_key_form.on_load()
{
   ctlkeysequence_box._set_focus();
}

void ctlok.on_create(_str commandName = "", _str modeName = "", _str keySequence = "")
{
   _bind_one_key_form_initial_alignment();

   _SetDialogInfoHt("clearPastEvents", true);
   ctlcommand.p_caption = commandName;
   ctlmode.insertModeList(modeName);
   ctlmode.p_text = ctlmode._lbget_text();
   ctlmore._dmless();

   if (keySequence != '') {
      _SetDialogInfoHt("clearPastEvents", false);
      typeless prevValue = _GetDialogInfoHt("ctlkeysequence_box.on_change");
      _SetDialogInfoHt("ctlkeysequence_box.on_change", true);
      ctlkeysequence_box.p_text = keySequence;
      labelDuplicateBindings(keySequence, keySequence);     // need to do this manually this time
      _SetDialogInfoHt("ctlkeysequence_box.on_change", prevValue);
   } else {
      _SetDialogInfoHt("clearPastEvents", false);
   }
   ctlok.p_enabled = ctlkeysequence_box.p_text != '';
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _bind_one_key_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(ctlkeysequence_box.p_window_id, 
                             ctlclear_keysequence.p_window_id, 
                             ctlmouse_events.p_window_id, 
                             ctlmore.p_x_extent);
}

void ctlok.lbutton_up()
{
   commandName := ctlcommand.p_caption;
   modeName :=  ctlbindtomode.p_value ? ctlmode.p_text : "";
   if (modeName == '') {
      modeName = 'default';
   }
   keyTable := getKeyTable(modeName);
   keyTableIndex := find_index(keyTable, EVENTTAB_TYPE);
   keySequence := ctlkeysequence_box.p_text;
   _param1 = keyTable;
   _param2 = keySequence;
   _param3 = false;

   // warn about conflicting key bindings
   curIndex := findKeyBindingIndex(keyTableIndex, keySequence);
   if (curIndex) {
      msg := "";
      if (name_type(curIndex) == EVENTTAB_TYPE) {
         eventtabName := name_name(curIndex);
         parse eventtabName with . ":" auto prefixKeyName;
         msg = nls("'%s' is a prefix key.  If you rebind this key, you will lose all of the keys bound to it.\n\nContinue?", prefixKeyName);
      } else {
         msg = nls("'%s' is currently bound to '%s'.\n\nContinue?", keySequence, name_name(curIndex));
      }
      result := _message_box(msg, "", MB_YESNO);
      if (result == IDNO) {
         return;
      }
      _param3 = true;
   }
   _macro('m',_macro('s'));
   bind(commandName, keyTable, keySequence);
   if (keyTable=='default-keys') {
      _eventtab_set_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_def_keys_2_profile_name(),_default_keys);
   } else {
      _eventtab_set_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_eventtab_name_2_profile_name(keyTable),_eventtab_get_mode_keys(keyTable));
   }
   p_active_form._delete_window(0);
}

void ctlmore.lbutton_up()
{
   _dmmoreless();
}

static void insertModeList(_str modeName)
{
   _list_modes("","", false, true);
   _lbtop();
   count := p_Noflines;
   while (count--) {
      _lbget_item(auto temp_modeName,auto indent, auto pic_index);
      keyTable := getKeyTable(temp_modeName);
      if (keyTable=='' || !_eventtab_get_mode_keys(keyTable)) {
         _lbdelete_item();
         --count;
      } else if (_lbdown()) {
         break;
      }
   }

   if (def_keys == 'vi-keys') {
      _lbadd_item("Vi Command Mode");
      _lbadd_item("Vi Visual Mode");
   }
   _lbadd_item("Diff Mode");
   _lbsort();
   _lbtop();
   if (modeName != '' && _lbi_search("", modeName, "i")) {
      _lbtop();
   }
}

void ctlbindtomode.lbutton_up()
{
   ctlmode.p_enabled = (p_value == true);
   ctlkeysequence_box.call_event(CHANGE_OTHER, ctlkeysequence_box, ON_CHANGE, "W");
}

void ctlmode.on_change(int reason)
{
   if (ctlmode.p_enabled) {
      ctlkeysequence_box.call_event(CHANGE_OTHER, ctlkeysequence_box, ON_CHANGE, "W");
   }
}

static void _bindkey_form_on_key_change()
{
   keySequence := ctlkeysequence_box.p_text;
   ctlbind_warning.labelDuplicateBindings(keySequence, keySequence);
   ctlok.p_enabled = keySequence != '';
}

/**
 * Sets and displays a warning in _bind_to_one_key_form that
 * current sequence is in use
 */
static void labelDuplicateBindings(_str keyName, _str keySequence)
{
   modeName :=  ctlbindtomode.p_value ? ctlmode.p_text : "";
   keyTable := getKeyTable(modeName);
   keyTableIndex := find_index(keyTable, EVENTTAB_TYPE);
   curIndex := findKeyBindingIndex(keyTableIndex, keySequence);
   if (curIndex) {
      msg := "";
      if (name_type(curIndex) == EVENTTAB_TYPE) {
         msg = keyName:+' is a prefix key.';
      } else {
         msg = 'Is bound to: ':+name_name(curIndex);
      }
      ctlbind_warning.p_caption = msg;
      ctlbind_warning.p_visible = true;
   } else {
      ctlbind_warning.p_caption = "";
      ctlbind_warning.p_visible = false;
   }
}

/**
 * If you already know the command you want to bind, call
 * directly into the bind to key form
 */
_command int gui_bind_command(_str commandName = '')
{
   typeless result = show("-modal _bind_one_key_form", commandName);
   if (!result) {
      //_param1 = keyTable;
      //_param2 = keySequence;
      //_param3 = false;    // key already bound?
      result = bind(commandName, _param1, _param2);
   }
   return (result);
}

static _str bindings_select_cb(int reason, typeless user_data, typeless info=null)
{
   _nocheck _control ctl_tree;
   switch (reason) {
   case SL_ONDEFAULT:
      select_tree_message("");
      break;
   case SL_ONINITFIRST:
      {
         _str keyTableNames:[];
         enumerateKeyTables(keyTableNames);
         _SetDialogInfoHt("sortAZ",true);
         ctl_tree.buildKeyBindingTree(keyTableNames, false);
      }
      break;
   case SL_ONSELECT:
      caption := ctl_tree._TreeGetCaption(info);
      parse caption with caption "\t" auto binding "\t" .;
      select_tree_message(caption" is bound to "binding);
      break;
   }
   return '';
}
/**
 * Display all your current key bindings
 * (only showing commands that have bindings)
 */
_command void gui_list_keybindings() name_info(','EDITORCTL_ARG2)
{
   select_tree(null, null, null, null, null,
               bindings_select_cb,
               null, "Key Bindings",
               SL_COLWIDTH|SL_SIZABLE|SL_COMBO|SL_XY_WIDTH_HEIGHT|SL_DEFAULTCALLBACK,
               "Command,Key Sequence,Mode,Recorded",
               (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)',' :+
               (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)',' :+
               (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)',' :+
               (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT),
               true,
               null, "gui_list_bindings");
}

/// eclipse show key command form
_form _what_is_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='What is Key';
   p_forecolor=0x80000008;
   p_height=2130;
   p_width=4785;
   p_x=6780;
   p_y=5010;
   p_eventtab=_what_is_form;
   _label  {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='Key Sequence:';
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=1;
      p_width=1080;
      p_word_wrap=false;
      p_x=120;
      p_y=135;
   }
   _text_box ctlkeysequence_box {
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=285;
      p_tab_index=2;
      p_tab_stop=false;
      p_width=3795;
      p_x=120;
      p_y=390;
      p_eventtab=_keybindings_form.ctlkeysequence_box;
      p_eventtab2=_ul2_textbox;
   }
   _image ctlclear_keysequence {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=330;
      p_max_click=MC_SINGLE;
      p_message='Clear';
      p_Nofstates=1;
      p_picture='bbdelete.svg';
      p_stretch=false;
      p_style=PSPIC_BUTTON;
      p_tab_index=3;
      p_tab_stop=false;
      p_value=0;
      p_width=345;
      p_x=3960;
      p_y=390;
      p_eventtab=_keybindings_form.ctlclear_keysequence;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlmouse_events {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=330;
      p_max_click=MC_SINGLE;
      p_message='Add mouse event';
      p_Nofstates=2;
      p_picture='bbmouse.svg';
      p_stretch=false;
      p_style=PSPIC_BUTTON;
      p_tab_index=4;
      p_tab_stop=false;
      p_value=0;
      p_width=345;
      p_x=4260;
      p_y=390;
      p_eventtab=_keybindings_form.ctlmouse_events;
      p_eventtab2=_ul2_imageb;
   }
   _label {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='Command:';
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=5;
      p_width=765;
      p_word_wrap=false;
      p_x=135;
      p_y=795;
   }
   _label ctlcommandname {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_SUNKEN;
      p_caption='';
      p_forecolor=0x80000008;
      p_height=285;
      p_tab_index=6;
      p_width=3795;
      p_word_wrap=false;
      p_x=120;
      p_y=1050;
   }
   _command_button ctlcancel {
      p_auto_size=false;
      p_cancel=true;
      p_caption='Cancel';
      p_default=false;
      p_height=345;
      p_tab_index=7;
      p_tab_stop=true;
      p_width=1425;
      p_x=1612;
      p_y=1622;
   }
}

defeventtab _what_is_form;

void _what_is_form.on_load()
{
   ctlkeysequence_box._set_focus();
}

void _what_is_form.on_create()
{
   alignControlsVertical(ctlkeysequence_box.p_prev.p_x,
                         ctlkeysequence_box.p_prev.p_y,
                         ctlkeysequence_box.p_prev.p_y,
                         ctlkeysequence_box.p_prev,
                         ctlkeysequence_box.p_window_id,
                         ctlcommandname.p_prev,
                         ctlcommandname.p_window_id,
                         ctlcancel.p_window_id);

   sizeBrowseButtonToTextBox(ctlkeysequence_box.p_window_id, 
                             ctlclear_keysequence.p_window_id, 
                             ctlmouse_events.p_window_id, 
                             p_active_form.p_width - ctlkeysequence_box.p_x);
   ctlcommandname.p_width = ctlkeysequence_box.p_width;
}

static void labelBindings(_str keyName, _str keySequence)
{
   modeName := "";
   int wid = _mdi.p_child;
   if (_iswindow_valid(wid) && wid.p_mdi_child) {
      modeName = wid.p_mode_name;
   }

   keyTable := getKeyTable();
   keyTableIndex := find_index(keyTable, EVENTTAB_TYPE);
   curIndex := findKeyBindingIndex(keyTableIndex, keySequence);
   if (curIndex) {
      msg := "";
      if (name_type(curIndex) == EVENTTAB_TYPE) {
         msg = keyName:+' is a prefix key.';
      } else {
         msg = name_name(curIndex);
      }
      ctlcommandname.p_caption = msg;
   } else {
      ctlcommandname.p_caption = "";
   }
}

static void _what_is_form_on_key_change()
{
   keySequence := ctlkeysequence_box.p_text;
   ctlcommandname.labelBindings(keySequence, keySequence);
}

_command void eclipse_what_is_key() name_info(',')
{
   show('-modal _what_is_form');
}
