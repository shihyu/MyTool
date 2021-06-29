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
#include "xml.sh"
#import "listbox.e"
#import "main.e"
#import "search.e"
#import "sellist.e"
#import "seltree.e"

namespace default;

_str def_search_color_presets[] = {
   ",XSC,",
   "CS,,",
   "CC,,"
};

static const COLOR2CHECKBOXTAB= "OKNSCPL1234FAT";
static _str gcolortab[] = {
   "Other",
   "Keyword",
   "Number",
   "String",
   "Comment",
   "Preprocessing",
   "Line Number",
   "Symbol 1",
   "Symbol 2",
   "Symbol 3",
   "Symbol 4",
   "Function",
   "Attribute",
   "Tag",
};

static _str s_cc_opt_to_str:[];

definit()
{
   // The following nationalizes the content of the Elements combo box.
   //  Lookup language-specific values for gcolortab
   gcolortab[0] = get_message(VSRC_FF_OTHER);
   gcolortab[1] = get_message(VSRC_FF_KEYWORD);
   gcolortab[2] = get_message(VSRC_FF_NUMBER);
   gcolortab[3] = get_message(VSRC_FF_STRING);
   gcolortab[4] = get_message(VSRC_FF_COMMENT);
   gcolortab[5] = get_message(VSRC_FF_PREPROCESSING);
   gcolortab[6] = get_message(VSRC_FF_LINE_NUMBER);
   gcolortab[7] = get_message(VSRC_FF_SYMBOL1);
   gcolortab[8] = get_message(VSRC_FF_SYMBOL2);
   gcolortab[9] = get_message(VSRC_FF_SYMBOL3);
   gcolortab[10] = get_message(VSRC_FF_SYMBOL4);
   gcolortab[11] = get_message(VSRC_FF_FUNCTION);
   gcolortab[12] = get_message(VSRC_FF_ATTRIBUTE);
   gcolortab[13] = get_message(VSRC_FF_TAG);

   s_cc_opt_to_str._makeempty();
}

_str _ccsearch_option_to_string(_str search_options)
{
   result := "";
   if (s_cc_opt_to_str._indexin(search_options)) {
      return s_cc_opt_to_str:[search_options];
   }
   int i, j, n;
   len := length(search_options);
   n = pos('C', search_options, 1, 'I');
   if (n > 0) {
      for (i = n + 1; i < len; ++i) {
         j = pos(substr(search_options, i, 1), COLOR2CHECKBOXTAB, 1, 'I');
         if (!j) {
            break;
         }
         if (result == '') {
            result = gcolortab[j-1];
         } else {
            result :+= ', 'gcolortab[j-1];
         }
      }
   }

   n = pos('X', search_options, 1, 'I');
   if (n > 0) {
      for (i = n + 1; i < len; ++i) {
         j = pos(substr(search_options, i, 1), COLOR2CHECKBOXTAB, 1, 'I');
         if (!j) {
            break;
         }
         if (result == '') {
            result = 'Not 'gcolortab[j-1];
         } else {
            result :+= ', Not 'gcolortab[j-1];
         }
      }
   }
   if (result == '') {
      result = 'None';
   }
   s_cc_opt_to_str:[search_options] = result;
   return(result);
}

/* strips color search options from search options */
_str _ccsearch_strip_colors_from_options(_str search_options)
{
   IncludeChars := "";
   ExcludeChars := "";
   int i, j, n;
   len := length(search_options);

   /*
      It might be better if search('',search_options) could be called parse these settings.
      This works for now.
   */
   n = pos('C', search_options, 1, 'I');
   if (n > 0) {
      for (i = n + 1; i < len; ++i) {
         j = pos(substr(search_options, i, 1), COLOR2CHECKBOXTAB, 1, 'I');
         if (!j) {
            break;
         }
         IncludeChars :+= substr(search_options, i, 1);
      }
   }
   n = pos('X', search_options, 1, 'I');
   if (n > 0) {
      for (i = n + 1; i < len; ++i) {
         j = pos(substr(search_options, i, 1), COLOR2CHECKBOXTAB, 1, 'I');
         if (!j) {
            break;
         }
         ExcludeChars :+= substr(search_options, i, 1);
      }
   }

   if (IncludeChars == "" && ExcludeChars == "") {
      return "";
   }
   if (IncludeChars != '') {
      IncludeChars = 'C'IncludeChars;
   }
   if (ExcludeChars != '') {
      ExcludeChars = 'X'ExcludeChars;
   }
   return(IncludeChars',':+ExcludeChars',');
}

defeventtab _ccsearch_form;

static _str _ccsearch_get_option()
{
   int i;
   IncludeChars := "";
   ExcludeChars := "";
   for ( i = 1;i <= gcolortab._length(); ++i) {
      wid := _find_control('check'i);
      if (wid.p_value == 0) {
         ExcludeChars :+= substr(COLOR2CHECKBOXTAB,i,1);
      } else if (wid.p_value == 1) {
         IncludeChars :+= substr(COLOR2CHECKBOXTAB,i,1);
      }
   }

   if (IncludeChars == "" && ExcludeChars == "") {
      return "";
   }
   if (IncludeChars != '') {
      IncludeChars = 'C'IncludeChars;
   }
   if (ExcludeChars != '') {
      ExcludeChars = 'X'ExcludeChars;
   }
   return(IncludeChars',':+ExcludeChars',');
}

void ctlok.lbutton_up()
{
   _param1 = _ccsearch_get_option();
   p_active_form._delete_window(1);
}

void ctlreset.lbutton_up()
{
   int i;
   for (i = 1; i <= gcolortab._length(); ++i) {
      wid := _find_control('check'i);
      wid.p_value = 2;
   }

   if (ctladdpreset.p_visible) {
      ctladdpreset.p_caption = "Add Preset";
      ctladdpreset.p_enabled = false;
   }
}

void ctlok.on_create()
{
   _str IncludeChars, ExcludeChars;
   int i, j;
   parse arg(1) with IncludeChars','ExcludeChars',';
   for (i = 2; i <= length(IncludeChars); ++i) {
      j = pos(substr(IncludeChars, i, 1, 'I'), COLOR2CHECKBOXTAB);
      if (j) {
         wid := _find_control('check'j);
         if (wid) {
            wid.p_value = 1;
         }
      }
   }
   for (i = 2;i <= length(ExcludeChars); ++i) {
      j = pos(substr(ExcludeChars, i, 1, 'I'),COLOR2CHECKBOXTAB);
      if (j) {
         wid := _find_control('check'j);
         if (wid) {
            wid.p_value = 0;
         }
      }
   }

   show_presets := arg(2);
   if (show_presets != '') {
      check1.call_event(_control check1, LBUTTON_UP, "W");

   } else {
      ctladdpreset.p_visible = false;
      ctladdpreset.p_enabled = false;
      ctlpresets.p_visible = false;
      ctlpresets.p_enabled = false;

      p_active_form.p_height = ctladdpreset.p_y;
   }
}

void check1.lbutton_up()
{
   if (!ctladdpreset.p_visible) {
      return;
   }

   option := _ccsearch_get_option();
   if (option :== "") {
      ctladdpreset.p_enabled = false;
      return;
   }

   found := false;
   foreach (auto n in def_search_color_presets) {
      if (n :== option) {
         found = true;
         break;
      }
   }

   if (!found) {
      ctladdpreset.p_caption = "Add Preset";
   } else {
      ctladdpreset.p_caption = "Remove Preset";
   }
   ctladdpreset.p_enabled = true;
}

void ctladdpreset.lbutton_up()
{
   option := _ccsearch_get_option();
   // add or delete?
   index := -1;
   for (i := 0; i < def_search_color_presets._length(); ++i) {
      if (option :== def_search_color_presets[i]) {
         index = i;
         break;
      }
   }

   if (index < 0) {
      def_search_color_presets[def_search_color_presets._length()] = option;

      // toggle caption
      ctladdpreset.p_caption = "Remove Preset";
   } else {
      def_search_color_presets._deleteel(index);

      // toggle caption
      ctladdpreset.p_caption = "Add Preset";
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

void ctlpresets.lbutton_up()
{
   _ccsearch_list_presets();

   // run update
   check1.call_event(_control check1, LBUTTON_UP, "W");
}

defeventtab _ccsearch_presets_callback;
static bool _ccsearch_presets_modified = false;

static void _ccsearch_presets_tree_save()
{
   def_search_color_presets._makeempty();   
   if (ctl_tree._TreeGetNumChildren(TREE_ROOT_INDEX) == 0) {
      return;
   }
   index := ctl_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   n := 0;
   while (index > 0) {
      _str info = ctl_tree._TreeGetUserInfo(index);
      def_search_color_presets[n] = info;
      ++n;
      index = ctl_tree._TreeGetNextSiblingIndex(index);
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

void ctl_delete.lbutton_up()
{
   index := ctl_tree._TreeCurIndex();
   if (index <= TREE_ROOT_INDEX) return;
   ctl_tree._TreeDelete(index);
   if (ctl_tree._TreeGetNumChildren(TREE_ROOT_INDEX) == 0) {
      p_enabled = false;
   }
   _ccsearch_presets_modified = true; 
}

static _str _ccsearch_presets_cb(int reason, typeless user_data, typeless info=null)
{
   switch (reason) {
   case SL_ONDEFAULT:
      break;
   case SL_ONINIT:
      _ccsearch_presets_modified = false;
      break;
   case SL_ONINITFIRST:
      ctl_delete.p_eventtab = defeventtab _ccsearch_presets_callback.ctl_delete;
      break;
   case SL_ONSELECT:
      break;
   case SL_ONCLOSE:
      if (_ccsearch_presets_modified) {
         _ccsearch_presets_tree_save();
      }
      break;
   }
   return '';
}

static void _ccsearch_list_presets()
{
   _str array[];
   _str keys[];
   foreach (auto opt in def_search_color_presets) {
      array[array._length()] = _ccsearch_option_to_string(opt);
      keys[keys._length()] = opt;
   }

   int flags = SL_DESELECTALL |
               SL_ALLOWMULTISELECT |
               SL_SELECTALL |
               SL_DELETEBUTTON;

   _str result = select_tree(array, keys, null, null, null, _ccsearch_presets_cb, null,
                             "Color Coding Search Presets",
                             flags);

   if (result == COMMAND_CANCELLED_RC || result == '') {
      return;
   }
}

_command void search_cc_presets() name_info(',')
{
   _ccsearch_list_presets();
}

