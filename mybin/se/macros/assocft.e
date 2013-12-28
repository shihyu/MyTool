////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50535 $
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
#import "complete.e"
#import "ini.e"
#import "listbox.e"
#import "optionsxml.e"
#import "stdprocs.e"
#import "util.e"
#endregion

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

#define VSFILE_TYPES "vpw slk vlx e sh"
#define COMMON_TYPES "vpw vpj slk vlx for f cob cbl mod bas ada pl awk cmd bat"

_command void assocft() name_info(',')
{
   if (!isAssociateFileTypesAvailable()) {
      message("This command is not available on this platform");
   } else {
      config('_associate_file_types_form', 'D');
   }
}

boolean isAssociateFileTypesAvailable()
{
   if (__UNIX__) {
      return false;
   }

   return true;
}

defeventtab _associate_file_types_form;

// since we don't make the changes until the user hits OK, we save what needs
// to be changed

#define TYPES_TO_ASSOCIATE ctlassociate.p_user
#define TYPES_TO_DISASSOCIATE ctldisassociate.p_user

#region Options Dialog Helper Functions

static boolean _allowable_for_association(_str fileExt) {
    if(fileExt :== 'exe' || fileExt :== 'bat' || fileExt :== 'vbs' || fileExt :== 'dll') {
        return false;
    }
    return true;
}

void _associate_file_types_form_init_for_options()
{
   _str name='';
   _str absExeFilename=editor_name("p"):+_strip_filename(editor_name("E"),'P');
   _registervs(absExeFilename);
   p_window_id=_control ctllist;

   // first look up file extensions defined using def_lang_for_ext_*
   int index=name_match('def-lang-for-ext-',1,MISC_TYPE);
   while ( index > 0 ) {
     name=substr(name_name(index),18);
     if(_allowable_for_association(name)) {
         add_extension_or_association(name);
     }
     index=name_match('def-lang-for-ext-',0,MISC_TYPE);
   }

   // try hard-coded list of common file extensions
   foreach (name in COMMON_TYPES) {
       if(_allowable_for_association(name)) {
           add_extension_or_association(name);
       }
   }

   p_window_id=_control ctl_asoc_list;
   _lbsort();
   _lbremove_duplicates();
   p_line=1;
   p_window_id=_control ctllist;
   _lbsort();
   _lbremove_duplicates();
   p_line=1;

   // get the options purpose to determine whether to show our button
   form := getOptionsFormFromEmbeddedDialog();
   purpose := _GetDialogInfoHt(PURPOSE, form);
   _ctl_customize_file_types_link.p_visible = (purpose == OP_QUICK_START);
   _ctl_customize_file_types_link.p_mouse_pointer = MP_HAND;
}

void _associate_file_types_form_restore_state()
{
   // this is really only for quick start
   form := getOptionsFormFromEmbeddedDialog();
   purpose := _GetDialogInfoHt(PURPOSE, form);
   if (purpose == OP_QUICK_START) {
      // just reinitialize this stuff in case anything changed
      _associate_file_types_form_init_for_options();
      _associate_file_types_form_save_settings();
   }
}

void _associate_file_types_form_save_settings()
{
   TYPES_TO_ASSOCIATE = null;
   TYPES_TO_DISASSOCIATE = null;
}

boolean _associate_file_types_form_apply()
{
   _disassociate_filetypes_list(TYPES_TO_DISASSOCIATE);
   _associate_filetypes_list(TYPES_TO_ASSOCIATE);

   return true;
}

boolean _associate_file_types_form_is_modified()
{
   if (TYPES_TO_ASSOCIATE == null && TYPES_TO_DISASSOCIATE == null) return false;

   // see if the lists contain only blanks...
   int i;
   for (i = 0; i < TYPES_TO_DISASSOCIATE._length(); i++) {
      // if we find it, check if it's blank
      if (TYPES_TO_DISASSOCIATE[i] != '') return true;
   }

   for (i = 0; i < TYPES_TO_ASSOCIATE._length(); i++) {
      // if we find it, check if it's blank
      if (TYPES_TO_ASSOCIATE[i] != '') return true;
   }

   return false;

}

void _associate_file_types_form_cancel()
{
   TYPES_TO_ASSOCIATE = null;
   TYPES_TO_DISASSOCIATE = null;
}

_str _associate_file_types_form_export_settings(_str &unusedFileArg, _str &extensions)
{
   error := '';

   // first look up file extensions defined using def_lang_for_ext_*
   _str ext;
   index := name_match('def-lang-for-ext-', 1, MISC_TYPE);
   while ( index > 0 ) {
     ext = substr(name_name(index), 18);

     value := _ntRegQueryValue(HKEY_CLASSES_ROOT, '.'ext);
     if (file_eq(value, 'SlickEdit')) extensions :+= ext' ';

     index = name_match('def-lang-for-ext-', 0, MISC_TYPE);
   }

   // try hard-coded list of common file extensions
   foreach (ext in COMMON_TYPES) {
      value := _ntRegQueryValue(HKEY_CLASSES_ROOT, '.'ext);
      if (file_eq(value, 'SlickEdit')) extensions :+= ext' ';
   }
   

   return error;
}

_str _associate_file_types_form_import_settings(_str &unusedFileArg, _str &extensions)
{
   _str extList[];
   split(extensions, ' ', extList);
   _associate_filetypes_list(extList);

   return '';
}

#endregion Options Dialog Helper Functions

void _ctl_customize_file_types_link.lbutton_up()
{
   origWid := p_window_id;

   boolean nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   optionsWid := config('_associate_file_types_form', 'D');
   _modal_wait(optionsWid);

   p_window_id = origWid;

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);

   // we need to reload our options in case anything changed
   _associate_file_types_form_restore_state();
}

void _associate_file_types_form.on_resize()
{
   if (!_ctl_customize_file_types_link.p_visible) {
      // regular options
      ctllist.p_height = p_height - (ctllist.p_y + 120);
      ctl_asoc_list.p_height = ctllist.p_height;
   } else {
      // quick start
      _ctl_customize_file_types_link.p_y = p_height - ( _ctl_customize_file_types_link.p_height + 120);
      ctllist.p_height = _ctl_customize_file_types_link.p_y - (ctllist.p_y + 120);
      ctl_asoc_list.p_height = ctllist.p_height;
   }

}

void switch_type_to_list(_str type, _str (&newList)[], _str (&oldList)[])
{
   // check if this type is in the old list
   int i;
   for (i = 0; i < oldList._length(); i++) {
      // if we find it, set it to blank
      if (oldList[i] == type) {
         oldList[i] = '';
         return;
      }
   }

   // we didn't find it, so we may as well put it into the other list
   newList[newList._length()] = type;
}

static void add_extension_or_association(_str name) 
{
   value := _ntRegQueryValue(HKEY_CLASSES_ROOT, '.'name);
   if (file_eq(value,'SlickEdit')) {
      p_window_id=_control ctl_asoc_list;
      _lbadd_item(name);
      p_window_id= _control ctllist;
   } else{
      _lbadd_item(name);
   }
}

ctlassociate.lbutton_up()
{
   _switch_type_to_associated_list();
}

ctllist.lbutton_double_click()
{
   _switch_type_to_associated_list();
}

ctldisassociate.lbutton_up()
{
   _switch_type_to_disassociated_list();
}

ctl_asoc_list.lbutton_double_click()
{
   _switch_type_to_disassociated_list();
}

_switch_type_to_disassociated_list()
{
   p_window_id = _control ctl_asoc_list;
   status := _lbfind_selected(true);
   for (;;) {
      if (status) break;
      _str ext = _lbget_text();

      switch_type_to_list(ext, TYPES_TO_DISASSOCIATE, TYPES_TO_ASSOCIATE);

      p_window_id = _control ctllist;
      _lbadd_item(ext);
      _lbsort();
      p_line = 1;

      p_window_id = _control ctl_asoc_list;
      _lbdelete_item();
      _lbup();
      status = _lbfind_selected(false);
   }
}

_switch_type_to_associated_list()
{
   p_window_id = _control ctllist;
   status := _lbfind_selected(true);
   for (;;) {
      if (status) break;
      _str ext = _lbget_text();

      switch_type_to_list(ext, TYPES_TO_ASSOCIATE, TYPES_TO_DISASSOCIATE);

      p_window_id = _control ctl_asoc_list;
      _lbadd_item(ext);
      _lbsort();
      p_line = 1;

      p_window_id = _control ctllist;
      _lbdelete_item();
      _lbup();
      status = _lbfind_selected(false);
   }
}

static void _associate_filetypes_list(_str list[])
{
   filename := '';
   if (_win32s()==1) {
      filename=_get_windows_directory()"win.ini";
   }

   int i;
   for (i = 0; i < list._length(); i++) {
      ext := strip(list[i]);
      if (ext != '') {
         if (_win32s() == 1) {
            new_value := editor_name("E")" ^."ext;
            _ini_set_value(filename, "Extensions", ext, new_value);
         } else {
            _associatefiletypetovs(ext);
         }
      }
   }
}

static void _disassociate_filetypes_list(_str list[])
{
   filename := '';
   if (_win32s()==1) {
      filename=_get_windows_directory()"win.ini";
   }

   int i;
   for (i = 0; i < list._length(); i++) {
      ext := strip(list[i]);
      if (ext != '') {
         if (_win32s() == 1) {
            new_value := ext:+'file'" ^."ext;
            _ini_set_value(filename, "Extensions", ext, new_value);
         } else {
            _associatefiletypetovs(ext, ext:+'file');
         }
      }
   }
}

static void _associate_filetypes(){
   _str filename='';
   if (_win32s()==1) {
      filename=_get_windows_directory()"win.ini";
   }
   p_window_id=_control ctllist;
   typeless status=_lbfind_selected(true);
   for (;;) {
      if (status) break;
      _str ext=_lbget_text();
      if (_win32s()==1) {
         _str new_value=editor_name("E")" ^."ext;
         _ini_set_value(filename,"Extensions",ext,new_value);
      } else {
         _associatefiletypetovs(ext);
      }
      p_window_id=_control ctl_asoc_list;
      _lbadd_item(ext);
      _lbsort();
      p_line=1;
      p_window_id=_control ctllist;
      _lbdelete_item();_lbup();
      status=_lbfind_selected(false);
   }
}

static void _disassociate_filetypes(){
   _str filename='';
   if (_win32s()==1) {
      filename=_get_windows_directory()"win.ini";
   }
   p_window_id=_control ctl_asoc_list;
   typeless status=_lbfind_selected(true);
   for (;;) {
      if (status) break;
      _str ext=_lbget_text();
      say(ext);
      if (_win32s()==1) {
         _str new_value= ext:+'file'" ^."ext;
         _ini_set_value(filename,"Extensions",ext,new_value);
      } else {
         _associatefiletypetovs(ext,ext:+'file');
      }
      p_window_id=_control ctllist;
      _lbadd_item(ext);
      _lbsort();
      p_line=1;
      p_window_id=_control ctl_asoc_list;
      _lbdelete_item();_lbup();
      status=_lbfind_selected(false);
   }
}
