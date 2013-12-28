////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#import "listbox.e"
#import "menu.e"
#import "stdprocs.e"
#import "wkspace.e"
#endregion

#define VSHISTKIND_MENUHIST  1
#define VSHISTKIND_DIALOGBOX 2

   struct VSHISTORYTAB {
      _str history_type;
      int kind;
      _str menu_category;
   };
   static VSHISTORYTAB _historytab[]= {
      {"File Menu", VSHISTKIND_MENUHIST,FILEHIST_CATEGORY},
      {"Project Menu", VSHISTKIND_MENUHIST,WKSPHIST_CATEGORY},
   };

static int MaxMRU = 20;

defeventtab _history_form;

#define CUR_FILE_HISTORY_SIZE          ctllabel8.p_user
#define CUR_WKSP_HISTORY_SIZE          ctlHistorySize.p_user

#region Options Dialog Helper Functions

boolean _history_form_is_modified(_str settings:[])
{
   return (def_max_filehist != (int)CUR_FILE_HISTORY_SIZE ||
           def_max_workspacehist != (int)CUR_WKSP_HISTORY_SIZE ||
           def_max_doc_mode_mru != (int)ctlNumMRUDocModes.p_text ||
           def_max_proj_type_mru != (int)ctlNumMRUProjTypes.p_text);
}

boolean _history_form_apply()
{
   def_max_filehist = (int)CUR_FILE_HISTORY_SIZE;
   def_max_workspacehist = (int)CUR_WKSP_HISTORY_SIZE;
   def_max_doc_mode_mru = (int)ctlNumMRUDocModes.p_text;
   def_max_proj_type_mru = (int)ctlNumMRUProjTypes.p_text;

   return true;
}

#endregion Options Dialog Helper Functions

void _history_form.on_resize()
{
   // current dimensions
   width  := _dx2lx(p_xyscale_mode,p_active_form.p_client_width);
   height := _dy2ly(p_xyscale_mode,p_active_form.p_client_height);

   padding := ctlhisttype.p_x;

   // figure out the width change
   widthDiff := width - (ctlhisttype.p_width + 2 * padding);
   if (widthDiff) {
      ctlhisttype.p_width += widthDiff;
      ctlitems.p_width += widthDiff;
      ctlDivider.p_width += widthDiff;
   }

   // figure out the height change
   heightDiff := height - (ctllabel7.p_y + ctllabel7.p_height + padding);
   if (heightDiff) {
      ctldelete.p_y += heightDiff;
      ctlitems.p_height += heightDiff;

      ctllabel8.p_y += heightDiff;
      ctlHistorySize.p_y += heightDiff;
      ctlHistorySpinner.p_y += heightDiff;

      ctlDivider.p_y += heightDiff;

      ctllabel6.p_y += heightDiff;
      ctlNumMRUDocModes.p_y += heightDiff;
      ctlDocModeSpinner.p_y += heightDiff;

      ctllabel7.p_y += heightDiff;
      ctlNumMRUProjTypes.p_y += heightDiff;
      ctlProjTypeSpinner.p_y += heightDiff;
   }
}

ctlhisttype.on_create()
{
   CUR_FILE_HISTORY_SIZE = def_max_filehist;
   CUR_WKSP_HISTORY_SIZE = def_max_workspacehist;

   int i;
   for (i=0;i<_historytab._length();++i) {
      if (_historytab[i].kind==VSHISTKIND_MENUHIST) {
         if (_mdi.p_menu_handle) {
            ctlhisttype._lbadd_item(_historytab[i].history_type);
         }
      }
   }
   ctlhisttype._lbtop();
   ctlhisttype._lbselect_line();
   ctlhisttype.call_event(CHANGE_SELECTED,ctlhisttype,on_change,"");
   ctldelete.p_enabled=0;

   // load max number the MRU num can be
   ctlProjTypeSpinner.p_max = ctlDocModeSpinner.p_max = MaxMRU;

   ctlNumMRUDocModes.p_text = def_max_doc_mode_mru;
   ctlNumMRUProjTypes.p_text = def_max_proj_type_mru;

   // make sure these textboxes aren't covering up the labels
   widest := (ctllabel6.p_width > ctllabel7.p_width) ? ctllabel6.p_width : ctllabel7.p_width;

   ctlNumMRUDocModes.p_x = ctlNumMRUProjTypes.p_x = ctlHistorySize.p_x = ctllabel6.p_x + widest + 60;
   ctlDocModeSpinner.p_x = ctlProjTypeSpinner.p_x = ctlHistorySpinner.p_x = ctlNumMRUDocModes.p_x + ctlNumMRUDocModes.p_width;

   ctllabel8.p_x = ctlHistorySize.p_x - 60 - ctllabel8.p_width;
}

void ctlHistorySize.on_change()
{
   menuCat := _historytab[ctlhisttype.p_line-1].menu_category;
   defaultValue := 0;
   switch (menuCat) {
   case FILEHIST_CATEGORY:
      defaultValue = CUR_FILE_HISTORY_SIZE;
      break;
   case WKSPHIST_CATEGORY:
      defaultValue = CUR_WKSP_HISTORY_SIZE;
      break;
   }

   validateNumber(ctlHistorySize, defaultValue);

   switch (menuCat) {
   case FILEHIST_CATEGORY:
      CUR_FILE_HISTORY_SIZE = ctlHistorySize.p_text;
      break;
   case WKSPHIST_CATEGORY:
      CUR_WKSP_HISTORY_SIZE = ctlHistorySize.p_text;
      break;
   }
}

void ctlNumMRUDocModes.on_change()
{
   validateNumber(ctlNumMRUDocModes, def_max_doc_mode_mru, MaxMRU);
}

void ctlNumMRUProjTypes.on_change()
{
   validateNumber(ctlNumMRUProjTypes, def_max_proj_type_mru, MaxMRU);
}

static void validateNumber(int textBoxWid, int defaultValue = 0, int maxValue = 0)
{
   // check that string is an integer
   if (isinteger(textBoxWid.p_text)) {
      int value = (int)textBoxWid.p_text;

      // make sure value is within range
      if (maxValue && value > maxValue) {
         textBoxWid.p_text = maxValue;
      } else if (value < 0) {
         textBoxWid.p_text = 0;
      }
   } else {
      msg := '';
      if (maxValue) {
         msg = "Please enter an integer between 0 and "maxValue".";
      } else {
         msg = "Please enter a positive integer.";
      }
      _message_box(msg);

      if (defaultValue) {
         textBoxWid.p_text = defaultValue;
      }
   }
}

static void ListItems()
{
   int i=ctlhisttype.p_line-1;
   if (_historytab[i].kind==VSHISTKIND_MENUHIST) {
      int dash_mh=0;
      int dash_pos=0;
      int status=_menu_find(_mdi.p_menu_handle,_historytab[i].menu_category,dash_mh,dash_pos,'C');
      if (!status) {
         int Nofitems=_menu_info(dash_mh,'c');
         for (i=dash_pos+1; i<Nofitems ;++i) {
            int flags=0;
            _str caption='';
            _menu_get_state(dash_mh,i,flags,'p',caption, auto command);
            if ((flags&MF_SUBMENU) && caption=='&All Workspaces') {
               continue;
            }

            parse command with . command;
            parse caption with . caption .;
            _lbadd_item(caption' - 'strip(command, 'B', '"'));
         }
      }
      return;
   }
}
void ctlhisttype.on_change(int reason)
{
   switch (reason) {
   case CHANGE_SELECTED:
      ctlitems._lbclear();
      if (_lbisline_selected()) {
         ctlitems.ListItems();
      }
      if (ctldelete.p_enabled) ctldelete.p_enabled=0;

      int i=ctlhisttype.p_line-1;
      switch (_historytab[i].menu_category) {
      case FILEHIST_CATEGORY:
         ctllabel8.p_visible = ctlHistorySize.p_visible = ctlHistorySpinner.p_visible = true;
         ctlHistorySize.p_text = CUR_FILE_HISTORY_SIZE;
         break;
      case WKSPHIST_CATEGORY:
         ctllabel8.p_visible = ctlHistorySize.p_visible = ctlHistorySpinner.p_visible = true;
         ctlHistorySize.p_text = CUR_WKSP_HISTORY_SIZE;
         break;
      default:
         ctllabel8.p_visible = ctlHistorySize.p_visible = ctlHistorySpinner.p_visible = false;
         break;
      }
   }
}

void ctlitems.on_change(int reason)
{
   switch (reason) {
   case CHANGE_SELECTED:
      if (p_Nofselected) {

         // don't allow them to remove the current project
         i := ctlhisttype.p_line-1;
         if (_historytab[i].menu_category == WKSPHIST_CATEGORY && getFilePath() == _workspace_filename) {
            ctldelete.p_enabled = 0;
         } else ctldelete.p_enabled=1;
      } else {
         ctldelete.p_enabled=0;
      }
   }
}

static _str getFilePath()
{
   caption := ctlitems._lbget_text();
   parse caption with . ' - ' caption;

   return caption;
}

void ctldelete.lbutton_up()
{
   int Nofitems=0;
   int flags=0;
   _str caption='';
   _str selnumber='';
   int i=ctlhisttype.p_line-1;
   _str menu_category=_historytab[i].menu_category;
   if (_historytab[i].kind==VSHISTKIND_MENUHIST) {

      int dash_mh=0;
      int dash_pos=0;
      int status=_menu_find(_mdi.p_menu_handle,menu_category,dash_mh,dash_pos,'C');
      if (status) return;

      // go through each item and delete it individually
      for (;;) {
         status=ctlitems._lbfind_selected(1);
         if (status) break;

         item_caption := getFilePath();


         if (menu_category == FILEHIST_CATEGORY) {
            _menu_remove_filehist(item_caption);
         } else {
            _menu_remove_workspace_hist(item_caption, false);
         }

         ctlitems._lbdelete_item();
      }

      ctlitems._lbtop();
      ctldelete.p_enabled=0;
      return;
   }
}
