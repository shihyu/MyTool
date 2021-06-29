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
#include "treeview.sh"
#import "se/lang/api/LanguageSettings.e"
#import "complete.e"
#import "ini.e"
#import "listbox.e"
#import "main.e"
#import "optionsxml.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#endregion

using se.lang.api.LanguageSettings;
/*
12:54pm 9/3/1998

After some snooping, I found out that these are the items that NT 5.0
adds to the registry when it puts a new type in.  If you don't do all of
these, you don't seem to get the icons for the associated files.

Notes:
@ is the "Default Value" entry for the key

"efile" would really be "SlickEdit", or some other appropriate name

-DWH

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.e]
@="efile"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\efile]
@="SlickEdit"
"EditFlags"=hex:00,00,00,00

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\efile\DefaultIcon]
@="E:\\vslick40\\win\\vs.exe,0"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\efile\Shell]
@=""

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\efile\Shell\open]
"EditFlags"=hex:01,00,00,00

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\efile\Shell\open\command]
@="E:\\vslick40\\win\\vs.exe %1"

*/

//#define VSFILE_TYPES "vpw slk vlx e sh"
//#define COMMON_TYPES "vpw vpj slk vlx for f cob cbl mod bas ada pl awk cmd bat"
static const NOT_ASSOCIABLE= ' exe  bat vbs dll cmd bin cpl com lnk ';

_command void assocft() name_info(',')
{
   if (!isAssociateFileTypesAvailable()) {
      message("This command is not available on this platform");
   } else {
      config('_associate_file_types_form', 'D');
   }
}

bool isAssociateFileTypesAvailable()
{
   if (_isUnix()) {
      return false;
   }

   return true;
}

#region Options Dialog Helper Functions

defeventtab _associate_file_types_form;

// since we don't make the changes until the user hits OK, we save what needs
// to be changed
static const ASSOCIATION_TABLE='assocTable';


// view combo values
static const VIEW_BY_LANG=       "List extensions by language";
static const VIEW_EXT_LIST=      "List extensions only";

void _associate_file_types_form_init_for_options()
{
   _str absExeFilename=editor_name("p"):+_strip_filename(editor_name("E"),'P');
   _registervs(absExeFilename);

   _SetDialogInfoHt(ASSOCIATION_TABLE, null);

   // set up the combo
   _ctl_view_combo._lbadd_item(VIEW_EXT_LIST);
   _ctl_view_combo._lbadd_item(VIEW_BY_LANG);

   // restore the last value
   _ctl_view_combo._retrieve_value();

   // do a little magic on the help blurb to make it look good
   _ctl_current_list._minihtml_UseDialogFont();
   _ctl_current_list.p_backcolor = 0x80000022;

   // fill in our tree!
   _ctl_ext_tree.fillExtensionTree();

   // and our label!
   setCurrentAssociationsList();
}

void _associate_file_types_form_restore_state()
{
   // in case the user wandered off and added some new languages 
   // or extensions, we need to refresh the list
   _ctl_ext_tree.fillExtensionTree();
}

void _associate_file_types_form_save_settings()
{
   _str key;
   int value;

   // go through our table and find all the 'new' values
   _str newKeys[];
   _str (*pAssocTable):[]=_GetDialogInfoHtPtr(ASSOCIATION_TABLE);
   foreach (key => value in *pAssocTable) {
      if (endsWith(key, '.new')) {
         newKeys[newKeys._length()] = key;
         ext := substr(key, 1, length(key) - 4);
         origKey := getOrigKey(ext);
         pAssocTable->:[origKey] = value;
      }
   }
   
   // save the new value as original, delete the new
   for (i := 0; i < newKeys._length(); i++) {
      key = newKeys[i];

      // get the extension
      ext := substr(key, 1, length(key) - 4);

      origKey := getOrigKey(ext);
      pAssocTable->:[origKey] = pAssocTable->:[key];
      pAssocTable->_deleteel(key);
   }
}

bool _associate_file_types_form_apply()
{
   setAssociations();

   return true;
}

bool _associate_file_types_form_is_modified()
{
   _str key;
   int value;
   _str (*pAssocTable):[]=_GetDialogInfoHtPtr(ASSOCIATION_TABLE);
   foreach (key => value in *pAssocTable) {
      if (endsWith(key, '.new')) {
         return true;
      }
   }

   return false;
}

void _associate_file_types_form_cancel()
{
   _SetDialogInfoHt(ASSOCIATION_TABLE, null);
}

_str _associate_file_types_form_export_settings(_str &unusedFileArg, _str &extensions)
{
   error := '';
   ext := '';

   // first look up file extensions defined using def_lang_for_ext_*
   _str extList[];
   _GetAllExtensions(extList);
   for (i := 0; i < extList._length(); i++) {
     ext = extList[i];

     value := _ntRegQueryValue(HKEY_CLASSES_ROOT, '.'ext);
     if (_file_eq(value, 'SlickEdit')) extensions :+= ext' ';
   }

   return error;
}

_str _associate_file_types_form_import_settings(_str &unusedFileArg, _str &extensions)
{
   _str extList[];
   split(extensions, ' ', extList);
   for (i := 0; i < extList._length(); i++) {
      _associatefiletypetovs(strip(extList[i]));
   }

   return '';
}

#endregion Options Dialog Helper Functions

static bool _allowable_for_association(_str fileExt) 
{
   return (pos(' 'fileExt' ', NOT_ASSOCIABLE) == 0);
}

void fillExtensionTree()
{
   // clear out the old stuff first
   _ctl_ext_tree._TreeDelete(TREE_ROOT_INDEX);

   // how should we list this stuff?
   if (_ctl_view_combo.p_text == VIEW_BY_LANG) {

      // categorized by language
      _str langs[];
      _GetAllLangIds(langs);
      langs._sort();

      for (i := 0; i < langs._length(); i++) {

         // get the extensions for this language
         list := _LangGetExtensions(langs[i]);

         if (list != '') {
            _str extensions[];
            split(list, ' ',  extensions);

            name := LanguageSettings.getModeName(langs[i]);
            langNode := _ctl_ext_tree._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_COLLAPSED);

            // start everything off as not checked - this may be changed 
            // if any of the children are checked
            _TreeSetCheckable(langNode, 1, 1, 0);

            // now add the extensions for the language
            extensions._sort();
            addedOne := false;
            for (j := 0; j < extensions._length(); j++) {

               // not all extensions are associable
               if (_allowable_for_association(extensions[j])) {
                  extNode := _ctl_ext_tree._TreeAddItem(langNode, extensions[j], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);

                  checked := isExtensionAssociated(extensions[j]);
                  _TreeSetCheckable(extNode, 1, 0, checked);

                  addedOne = true;
               }
            }

            // we didn't add any extensions, so delete the language
            if (!addedOne) {
               _TreeDelete(langNode);
            }
         }
      }
      // sort the languages
      _TreeSortCaption(TREE_ROOT_INDEX, 'PI');

   } else {
      // just throw all the extensions into the list
      _str extensions[];
      _GetAllExtensions(extensions);
      extensions._sort('I');

      for (i := 0; i < extensions._length(); i++) {

        if (_allowable_for_association(extensions[i])) {
           extNode := _ctl_ext_tree._TreeAddItem(TREE_ROOT_INDEX, extensions[i], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);

           checked := isExtensionAssociated(extensions[i]);
           _TreeSetCheckable(extNode, 1, 0, checked);
        }
      }
   }
}

void _ctl_ext_tree.on_change(int reason, int index)
{
   if (reason == CHANGE_CHECK_TOGGLED) {
      // get the new check state
      newState := _TreeGetCheckState(index);

      // is this a parent node?
      _str extList[];
      child := _TreeGetFirstChildIndex(index);
      if (child > 0) {
         while (child > 0) {
            extList[extList._length()] = _TreeGetCaption(child);
            child = _TreeGetNextSiblingIndex(child);
         }
      } else {
         extList[0] = _TreeGetCaption(index);
      }

      for (i := 0; i < extList._length(); i++) {
         setAssociationValue(extList[i], newState);
      }

      // update the label
      setCurrentAssociationsList();
   }
}

static void setCurrentAssociationsList()
{
   _str extensions[];
   _GetAllExtensions(extensions);
   extensions._sort('I');

   list := '';
   _str assocExts[];
   for (i := 0; i < extensions._length(); i++) {

      // add it to our list - they've already been sorted
      if (_allowable_for_association(extensions[i]) && isExtensionAssociated(extensions[i])) {
         list :+= extensions[i]' ';
      }
   }

   _ctl_current_list.p_text = '<b>Current associations:</b>  'strip(list);
   _ctl_current_list.p_width = _ctl_ext_tree.p_width;
}

void _ctl_view_combo.on_change()
{
   _ctl_ext_tree.fillExtensionTree();
}

void _ctl_view_combo.on_destroy()
{
   _ctl_view_combo._append_retrieve(_ctl_view_combo, _ctl_view_combo.p_text);
}

void _associate_file_types_form.on_resize()
{
   pad := _ctl_ext_tree.p_x;
   heightDiff := p_height - (_ctl_current_list.p_y_extent + pad);
   widthDiff := p_width - (_ctl_ext_tree.p_x_extent + pad);

   if (heightDiff) {
      _ctl_ext_tree.p_height += heightDiff;
      _ctl_current_list.p_y += heightDiff;
   }

   if (widthDiff) {
      _ctl_ext_tree.p_width += widthDiff;
      _ctl_current_list.p_width = _ctl_ext_tree.p_width;
      _ctl_view_combo.p_x += widthDiff;
      _ctl_view_label.p_x += widthDiff;
   }
}

static _str getOrigKey(_str ext)
{
   return ext'.orig';
}

static _str getNewKey(_str ext)
{
   return ext'.new';
}

static void setAssociationValue(_str ext, int value)
{
   // first, see if the new value matches the original
   origKey := getOrigKey(ext);
   newKey := getNewKey(ext);
   _str (*pAssocTable):[]=_GetDialogInfoHtPtr(ASSOCIATION_TABLE);
   if (pAssocTable->:[origKey] == value) {
      pAssocTable->_deleteel(newKey);
   } else {
      pAssocTable->:[newKey] = value;
   }
}

static bool isExtensionAssociated(_str ext)
{
   // first check for a new value
   key := getNewKey(ext);
   _str (*pAssocTable):[]=_GetDialogInfoHtPtr(ASSOCIATION_TABLE);
   if (pAssocTable->_indexin(key)) {
      return (pAssocTable->:[key] != 0);
   }

   // now try for the original value
   key = getOrigKey(ext);
   if (pAssocTable->_indexin(key)) {
      return (pAssocTable->:[key] != 0);
   }

   // nothing, so get and save a new original value
   value := _ntRegQueryValue(HKEY_CLASSES_ROOT, '.'ext);
   pAssocTable->:[key] = (int)(_file_eq(value,'SlickEdit'));

   return (pAssocTable->:[key] != 0);
}

static void setAssociations()
{
   // go through our table and find all the 'new' values
   _str key;
   int value;
   _str (*pAssocTable):[]=_GetDialogInfoHtPtr(ASSOCIATION_TABLE);
   foreach (key => value in *pAssocTable) {
      if (endsWith(key, '.new')) {
         ext := substr(key, 1, length(key) - 4);
         if (value) {
            // associate!
            _associatefiletypetovs(ext);
         } else {
            // disassociate!
            _associatefiletypetovs(ext, ext:+'file');
         }
      }
   }
}

