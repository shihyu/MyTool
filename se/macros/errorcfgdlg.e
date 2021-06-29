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
// 
// errorcfgdlg.e
// Form event handlers for the error regular expressions
// configuration and editing dialogs. 
// Buddy files is error.e
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "xml.sh"
#include "search.sh"
#include "plugin.sh"
#include "errorre.sh"
#import "main.e"
#import "error.e"
#import "diff.e"
#import "help.e"
#import "listbox.e"
#import "picture.e"
#import "stdprocs.e"
#import "tbcontrols.e"
#import "treeview.e"
#import "cfg.e"
#import "files.e"
#endregion

static ERRORRE_FOLDER_INFO gerrorre_folder_array[];
static bool gerrorre_folder_array_modified;

static int gcurrent_editing_re_row = -1;
static int gcurrent_editing_folder_row = -1;

definit()
{
   if (arg()!='L') {
      gerrorre_folder_array._makeempty();
      gerrorre_folder_array_modified=false;
   }
   gcurrent_editing_re_row = -1;
   gcurrent_editing_folder_row = -1;
}


#region Options Dialog Helper Functions

defeventtab _error_re_form;

static void set_modify() {
   gerrorre_folder_array_modified=true;
   ctlbtn_reset.p_enabled=true;
}

void _error_re_form_init_for_options()
{
   ctlbtn_ok.p_visible = false;
   ctlbtn_cxl.p_visible = false;
   ctlbtn_help.p_visible = false;
   ctlbtn_reset.p_enabled=(_plugin_is_modified_builtin_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_ERRORPARSING))?true:false;
   gerrorre_folder_array_modified=false;
}

//void _error_re_form_save_settings() {
//}

bool _error_re_form_is_modified()
{
   return gerrorre_folder_array_modified;
}

bool _error_re_form_apply()
{
   _errorre_save_error_parsing_table(gerrorre_folder_array);
   gerrorre_folder_array_modified=false;
   ctlbtn_reset.p_enabled=(_plugin_is_modified_builtin_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_ERRORPARSING))?true:false;
   return true;
}

_str _error_re_form_export_settings(_str &file)
{
   return _plugin_export_profile(file, VSCFGPACKAGE_MISC,VSCFGPROFILE_ERRORPARSING);
}

_str _error_re_form_import_settings(_str file)
{
   error := '';
   if (endsWith(file,VSCFGFILEEXT_CFGXML,false,_fpos_case)) {
      error=_plugin_import_profile(file,VSCFGPACKAGE_MISC,VSCFGPROFILE_ERRORPARSING);
   } else {
      _convert_errorre_xml(file);
   }
   _errorre_config_changed();

   return error;
}

#endregion Options Dialog Helper Functions

void ctlbtn_reset.lbutton_up() {
   // verify user wants to do this
   result := _message_box('Are you sure you wish to reset the regular expressions, deleting any changes you have made?', "Reset", MB_OKCANCEL | MB_ICONQUESTION);
   if (result == IDCANCEL) return;


   // clear out the trees
   ctltree_categories._TreeDelete(TREE_ROOT_INDEX, 'C');
   ctltree_categories._TreeRefresh();
   ctltree_expressions._TreeDelete(TREE_ROOT_INDEX, 'C');
   ctltree_expressions._TreeRefresh();

   _plugin_delete_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_ERRORPARSING);
   _errorre_load_error_parsing_table(gerrorre_folder_array);
   ctlbtn_reset.p_enabled=false;
   gerrorre_folder_array_modified=true;

   // recreate it again
   loadToolTree();
   OnCategoryChange();
}

void ctlimagebtn_addexpression.lbutton_up()
{
   folder_selected := ctltree_categories._TreeCurIndex();
   if (folder_selected<=0) return;
   int folder_row=ctltree_categories._TreeGetChildRow(folder_selected);
   // Bring up the "edit expression" dialog so the user
   // can define and test a new error expression
   _str sampleTestCase = 'Error in /usr/proj/tmp/file.x, line 23, column 13: Fatal error' :+ "\r\n" :+
                         '         -group #0-           -group #1- -group #2- -group #3-\r\n' :+ "\r\n" :+
                         'error in C:\MyProjects\file.c, line 44, column 44: stdio.h not found';
   sampleExpression := '^Error in:b{#0:p},:bline:b{#1:i},:bcolumn:b{#2:i}\::b{#3?+}$';

   selectedCategory := ctltree_categories._TreeCurIndex();
   _str retVal = show('-modal -xy _error_re_edit_form', "<name>", sampleExpression, sampleTestCase, folder_row,-1);
   if(retVal != null && retVal != '') {
      set_modify();
      OnCategoryChange();
      //_str retVal = expName'###'expVal'###'macroName'###'testCases;
   }
}
int _TreeGetChildRow(int child) {
   count:=0;
   for (;;) {
      child=_TreeGetPrevSiblingIndex(child);
      if (child<0) break;
      ++count;
   }
   return count;
}

void ctlimagebtn_delexpression.lbutton_up()
{
   // Delete the selected expression
   selected := ctltree_expressions._TreeCurIndex();
   if(selected > 0) {
      folder_selected := ctltree_categories._TreeCurIndex();
      if (folder_selected<=0) return;
      int folder_row=ctltree_categories._TreeGetChildRow(folder_selected);
      int re_row=ctltree_expressions._TreeGetChildRow(selected);
      gerrorre_folder_array[folder_row].m_errorre_array._deleteel(re_row);
      set_modify();

      // Now refresh the tree. Just fake a change in
      // selection of the category list
      OnCategoryChange();
   }
}

void ctlimagebtn_editexpression.lbutton_up()
{
   folder_selected := ctltree_categories._TreeCurIndex();
   if (folder_selected<=0) return;
   int folder_row=ctltree_categories._TreeGetChildRow(folder_selected);
   // Bring up the "edit expression" dialog so the user
   // can modify and test the expression
   // Show the edit form to modify this expression
   selIdx := ctltree_expressions._TreeCurIndex();
   if(selIdx > 0) {
      int re_row=ctltree_expressions._TreeGetChildRow(selIdx);
      _str retVal = show('-modal -xy _error_re_edit_form', "", "", "", folder_row,re_row);
      if(retVal != null && retVal != '') {
         set_modify();
         OnCategoryChange();
         //_str retVal = expName'###'expVal'###'macroName'###'testCases;
      }
   }
}

// Button to delete a category/tool
void ctlimagebtn_delcat.lbutton_up()
{
   // TODO: Display prompt for removing this category
   // or simply disabling it.
   selCategory := ctltree_categories._TreeCurIndex();
   if(selCategory > 0) {
      int folder_row=ctltree_categories._TreeGetChildRow(selCategory);
      gerrorre_folder_array._deleteel(folder_row);
      set_modify();

      // Now reload the category tree
      loadToolTree();
      //ctltree_categories._TreeSetCurIndex(selCategory - 1);
      updateCategoryControls();
   }
}

// Button to add a category/tool
void ctlimagebtn_addcat.lbutton_up()
{
   // TODO: Show dialog for creating a new category
   _str result = show('-modal _textbox_form',
                 'New Expression Category',      // Form caption
                 0,              //flags
                 '',             //use default textbox width
                 'Error Parsing Expressions',  //Help item.
                 '',             //Buttons and captions
                 '',             //Retieve Name
                 '-e _check_new_category Category Name:MyNewCategory');
   if (result=='') {
      return;
   }
   // Create the new category
   _str newName = _param1;
   ERRORRE_FOLDER_INFO info;
   info.m_name=newName;
   info.m_enabled=true;
   info.m_errorre_array._makeempty();
   gerrorre_folder_array[gerrorre_folder_array._length()]=info;
   set_modify();


   // Refresh/reload the list of expression categories
   loadToolTree();

   // Reset the selection index to select the newly created node
   int newPlace = ctltree_categories._TreeSearch(TREE_ROOT_INDEX, newName);
   ctltree_categories._TreeSetCurIndex(newPlace);

   // Make sure the expressions for this category are updated
   // TODO: This may be redundant, and possibly removed
   OnCategoryChange();
}

// Button to move a category/tool down in priority
void ctlimagebtn_catdown.lbutton_up()
{
   // Move category/tool priority down
   // Get the selected index
   selected := ctltree_categories._TreeCurIndex();
   // Get the next item in the tree
   next := ctltree_categories._TreeGetNextSiblingIndex(selected);

   // If we have 2 valid tree nodes, get the xml indices
   // and swap the priority attribute values
   if(selected > 0 && next > 0) {
      caption := ctltree_categories._TreeGetCaption(selected);

      int folder_row=ctltree_categories._TreeGetChildRow(selected);
      swapFolders(folder_row);

      // Reload the category tree to reflect the changes
      loadToolTree();

      // Reset the selection index
      int newPlace = ctltree_categories._TreeSearch(TREE_ROOT_INDEX, caption);
      ctltree_categories._TreeSetCurIndex(newPlace);

      // Make sure the expressions for this category are updated
      // TODO: This may be redundant, and possibly removed
      OnCategoryChange();
   }
}

// Button to move a category/tool up in priority
void ctlimagebtn_catup.lbutton_up()
{
   // Move category/tool priority up
   // Get the selected index
   selected := ctltree_categories._TreeCurIndex();
   // Get the previous item in the tree
   prev := ctltree_categories._TreeGetPrevSiblingIndex(selected);

   // If we have 2 valid tree nodes, get the xml indices
   // and swap the priority attribute values
   if(selected > 0 && prev > 0) {
      caption := ctltree_categories._TreeGetCaption(selected);

      int folder_row=ctltree_categories._TreeGetChildRow(prev);
      swapFolders(folder_row);

      // Reload the category tree to reflect the changes
      loadToolTree();

      // Reset the selection index
      int newPlace = ctltree_categories._TreeSearch(TREE_ROOT_INDEX, caption);
      ctltree_categories._TreeSetCurIndex(newPlace);
   }
}

// Button to move an expression down in priority
void ctlimagebtn_expressiondown.lbutton_up()
{
   // Move expression priority down
   // Get the selected index
   selected := ctltree_expressions._TreeCurIndex();
   // Get the next item in the tree
   next := ctltree_expressions._TreeGetNextSiblingIndex(selected);

   // If we have 2 valid tree nodes, get the xml indices
   // and swap the priority attribute values
   if(selected > 0 && next > 0) {
      caption := ctltree_expressions._TreeGetCaption(selected);

      swapRE(selected, next);

      // Reload the expression tree to reflect the changes
      loadExpressionTree();

      int newPlace = ctltree_expressions._TreeSearch(TREE_ROOT_INDEX, caption);
      ctltree_expressions._TreeSetCurIndex(newPlace);
   }
   updateExpressionControls();
}

// Button to move an expression up in priority
void ctlimagebtn_expressionup.lbutton_up()
{
   // Move expression priority up
   // Get the selected index
   selected := ctltree_expressions._TreeCurIndex();
  
   // Get the previous item in the tree
   prev := ctltree_expressions._TreeGetPrevSiblingIndex(selected);
   // If we have 2 valid tree nodes, get the xml indices
   // and swap the priority attribute values
   if(selected > 0 && prev > 0) {
      caption := ctltree_expressions._TreeGetCaption(selected);
      swapRE(prev,selected);

      // Reload the expression tree to reflect the changes
      loadExpressionTree();

      int newPlace = ctltree_expressions._TreeSearch(TREE_ROOT_INDEX, caption);
      ctltree_expressions._TreeSetCurIndex(newPlace);
   }
   updateExpressionControls();
}


static void swapRE(int selected, int next) {
   folder_selected := ctltree_categories._TreeCurIndex();
   if (folder_selected<=0) return;
   int folder_row=ctltree_categories._TreeGetChildRow(folder_selected);
   int re_row=ctltree_expressions._TreeGetChildRow(selected);

   ERRORRE_INFO info;
   info=gerrorre_folder_array[folder_row].m_errorre_array[re_row];
   gerrorre_folder_array[folder_row].m_errorre_array[re_row]=gerrorre_folder_array[folder_row].m_errorre_array[re_row+1];
   gerrorre_folder_array[folder_row].m_errorre_array[re_row+1]=info;
   set_modify();
}
// Swaps the "Priority" attribute value of two Expression
// or two Tool nodes that are siblings
static void swapFolders(int folder_row) {
   ERRORRE_FOLDER_INFO info;
   info=gerrorre_folder_array[folder_row];
   gerrorre_folder_array[folder_row]=gerrorre_folder_array[folder_row+1];
   gerrorre_folder_array[folder_row+1]=info;
   set_modify();
}


void _error_re_form.on_destroy()
{
   gerrorre_folder_array._makeempty();
}

void _error_re_form.on_create()
{
   ctlbtn_reset.p_enabled=(_plugin_is_modified_builtin_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_ERRORPARSING))?true:false;
   _errorre_load_error_parsing_table(gerrorre_folder_array);

   ctltree_expressions._TreeSetColButtonInfo(0, 2000, TREE_BUTTON_AUTOSIZE, -1, "Name");
   ctltree_expressions._TreeSetColButtonInfo(1, 100, TREE_BUTTON_AUTOSIZE, -1, "Classification");
   ctltree_expressions._TreeSetColButtonInfo(2, 3000, TREE_BUTTON_AUTOSIZE , -1, "Expression");
   ctltree_expressions._TreeSetColEditStyle(2,TREE_EDIT_TEXTBOX);
   ctltree_categories._TreeSetColButtonInfo(0, 2000, TREE_BUTTON_AUTOSIZE, -1, "Expression Category");
   loadToolTree();
   ctlimagebtn_catdown.p_enabled = false;
   ctlimagebtn_catup.p_enabled = false;
   ctlimagebtn_delcat.p_enabled = false;

   firstChild := ctltree_categories._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if(firstChild >= 0) {
      ctltree_categories._TreeSetCurIndex(firstChild);
      OnCategoryChange();
   }
}

void _error_re_form.on_resize()
{
   int clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   int padding = ctltree_categories.p_x;

   // if we are not embedded in the options, we have a min size
   // have we set the min size yet?  if not, min width will be 0
   if (ctlbtn_ok.p_visible && !_minimum_width()) {
      minH := ctlbtn_reset.p_height * 10 + padding;
      minW := ctlbtn_reset.p_width * 5 + padding;
      _set_minimum_size(minW, minH);
   }
   
   heightDiff := clientH - (ctlbtn_reset.p_y_extent + padding);

   if(heightDiff)
   {
      // Resize the expression area
      ctltree_categories.p_height  += (heightDiff intdiv 4);
      ctltree_expressions.p_height += (heightDiff - (heightDiff intdiv 4));
   }

   alignControlsVertical(ctllabel1.p_x, ctllabel1.p_y,
                         _dy2ly(SM_TWIP, 4),
                         ctllabel1.p_window_id,
                         ctltree_categories.p_window_id,
                         ctllabel2.p_window_id,
                         ctltree_expressions.p_window_id,
                         ctlbtn_ok.p_window_id);

   alignControlsHorizontal(ctlbtn_ok.p_x, ctlbtn_ok.p_y,
                           padding,
                           ctlbtn_ok.p_window_id,
                           ctlbtn_cxl.p_window_id,
                           ctlbtn_help.p_window_id,
                           ctlbtn_reset.p_window_id);
   if (!ctlbtn_ok.p_visible) {
      ctlbtn_reset.p_x = ctlbtn_ok.p_x;
   }

   rightAlign := p_active_form.p_width - ctltree_expressions.p_x;
   max_button_height := min(ctltree_categories.p_height, ctltree_expressions.p_height) intdiv 5;
   ctlimagebtn_addcat.resizeToolButton(max_button_height);
   ctlimagebtn_delcat.resizeToolButton(max_button_height);
   ctlimagebtn_catup.resizeToolButton(max_button_height);
   ctlimagebtn_catdown.resizeToolButton(max_button_height);
   ctltree_categories.p_x_extent = rightAlign - ctlimagebtn_addcat.p_width;
   alignControlsVertical(rightAlign - ctlimagebtn_addcat.p_width,
                         ctltree_categories.p_y,
                         _dy2ly(SM_TWIP, def_toolbar_pic_vspace),
                         ctlimagebtn_addcat.p_window_id,
                         ctlimagebtn_catup.p_window_id, 
                         ctlimagebtn_catdown.p_window_id,
                         ctlimagebtn_delcat.p_window_id);

   ctlimagebtn_editexpression.resizeToolButton(max_button_height);
   ctlimagebtn_addexpression.resizeToolButton(max_button_height);
   ctlimagebtn_expressionup.resizeToolButton(max_button_height);
   ctlimagebtn_expressiondown.resizeToolButton(max_button_height);
   ctlimagebtn_delexpression.resizeToolButton(max_button_height);
   ctltree_expressions.p_width = ctltree_categories.p_width;
   alignControlsVertical(rightAlign - ctlimagebtn_addcat.p_width,
                         ctltree_expressions.p_y,
                         _dy2ly(SM_TWIP, def_toolbar_pic_vspace),
                         ctlimagebtn_editexpression.p_window_id,
                         ctlimagebtn_addexpression.p_window_id, 
                         ctlimagebtn_expressionup.p_window_id, 
                         ctlimagebtn_expressiondown.p_window_id,
                         ctlimagebtn_delexpression.p_window_id);

   ctltree_expressions.refresh();
}

void _error_re_form.f1()
{
   help(p_active_form.p_help);
}

void ctlbtn_cxl.lbutton_up()
{
   if (ctlbtn_cxl.p_visible) {
      if (_error_re_form_is_modified()) {
         status := _message_box("Changes have been made but not applied.","", MB_APPLYDISCARDCANCEL, IDAPPLY);
         switch(status) {
         case IDAPPLY:
            _error_re_form_apply();
             break;
         case IDDISCARD:
             break;
         case IDCANCEL:
             return;
         default:
             break;
        }
      }
   }
   // Close the form without saving the XML configuration
   //say("Form cancelled");
   p_active_form._delete_window();

}

void ctlbtn_ok.lbutton_up()
{
   _error_re_form_apply();
   p_active_form._delete_window();
}

// Fired when the selected tool changes
void ctltree_categories.on_change(int reason,int index)
{
   if( reason == CHANGE_SELECTED ){
      OnCategoryChange();
   } else if ( reason==CHANGE_CHECK_TOGGLED ) {
      categoryTreeCheckToggle(index);
   }
}

static int categoryTreeCheckToggle(int index) {
   if((index > 0)) {
      int folder_row=ctltree_categories._TreeGetChildRow(index);
      // Change the value of the Enabled attribute to correspond
      // to the new picture
      if( !_TreeGetCheckState(index) ) {
         gerrorre_folder_array[folder_row].m_enabled=false;
      } else {
         gerrorre_folder_array[folder_row].m_enabled=true;
      }
      set_modify();

   }
   //say("Lbutton up on "index);
   return 0;
}

static void updateCategoryControls()
{
   curSel := ctltree_categories._TreeCurIndex();
   prevSib := ctltree_categories._TreeGetPrevSiblingIndex(curSel);
   nextSib := ctltree_categories._TreeGetNextSiblingIndex(curSel);
   // Disable UP button if no previous category
   ctlimagebtn_catup.p_enabled = (prevSib > 0);
   // Disable DOWN button if no previous category
   ctlimagebtn_catdown.p_enabled = (nextSib > 0);

   cap := ctltree_categories._TreeGetCaption(curSel);
   // Disable deleting the default category
   if(cap == null) {
      ctlimagebtn_delcat.p_enabled = false;
   } else {
      ctlimagebtn_delcat.p_enabled = true;
   }
}

static void loadToolTree() {
   // Clear any existing contents
   ctltree_categories._TreeDelete(0, "C");
   ctltree_categories._TreeBeginUpdate(TREE_ROOT_INDEX);

   for (i:=0;i<gerrorre_folder_array._length();++i) {
      _str folder_name =gerrorre_folder_array[i].m_name;
      int addedItem = ctltree_categories._TreeAddListItem(folder_name,0,TREE_ROOT_INDEX,-1);
      if(gerrorre_folder_array[i].m_enabled) {
         ctltree_categories._TreeSetCheckState(addedItem, TCB_CHECKED);
      } else {
         ctltree_categories._TreeSetCheckState(addedItem, TCB_UNCHECKED);
      }
   }
   ctltree_categories._TreeEndUpdate(TREE_ROOT_INDEX);
}

static void OnCategoryChange()
{
   updateCategoryControls();

   loadExpressionTree();

   firstChild := ctltree_expressions._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (firstChild >= 0) {
      ctltree_expressions._TreeSetCurIndex(firstChild);
   }

   updateExpressionControls();
}

// Populate the tree list of regular expressions based on the 
// selected category/tool
static void loadExpressionTree()
{
   selCategory := ctltree_categories._TreeCurIndex();
   if(selCategory<=0) {
      selCategory = ctltree_categories._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      ctltree_categories._TreeSetCurIndex(selCategory);
   }
   // Clear out the current expression list contents
   ctltree_expressions._TreeDelete(0, "C");
   ctltree_expressions._TreeBeginUpdate(TREE_ROOT_INDEX);

   // Get the selected item from the category/tool listing
   /*int selCategory = ctltree_categories._TreeCurIndex();
   if(selCategory<=0) {
      selCategory = ctltree_categories._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      //ctltree_categories._TreeSetCurIndex(selCategory);
   } */
   selectedText := ctltree_categories._TreeGetCaption(selCategory);
  
   for (i:=0;i<gerrorre_folder_array._length();++i) {
      _str folder_name =gerrorre_folder_array[i].m_name;
      if (strieq(folder_name,selectedText)) {
         int len=gerrorre_folder_array[i].m_errorre_array._length();

         for(j:=0;j<len;++j) {
            _str reCDATAValue = gerrorre_folder_array[i].m_errorre_array[j].m_re;
            _str reName=gerrorre_folder_array[i].m_errorre_array[j].m_name;
            klass := gerrorre_folder_array[i].m_errorre_array[j].m_severity;
            int addedItem = ctltree_expressions._TreeAddListItem(reName :+ "\t" :+ 
                                                                 klass :+ "\t" :+
                                                                 reCDATAValue, 0, TREE_ROOT_INDEX, -1);

            if(gerrorre_folder_array[i].m_errorre_array[j].m_enabled) {
               ctltree_expressions._TreeSetCheckState(addedItem, TCB_CHECKED);
            } else {
               ctltree_expressions._TreeSetCheckState(addedItem, TCB_UNCHECKED);
            }
         }
      }
   }
   ctltree_expressions._TreeEndUpdate(TREE_ROOT_INDEX);
}


void ctltree_expressions.on_change(int reason,int index)
{
   if(reason == CHANGE_LEAF_ENTER) /* Double click or enter */ {
      ctlimagebtn_editexpression.call_event(ctlimagebtn_editexpression,LBUTTON_UP);
   } else if (reason == CHANGE_SELECTED) {
      // TODO: Suppress lbutton_up event for toggling the expression
      //say("Changed to "index);
      updateExpressionControls();
   } else if ( reason==CHANGE_CHECK_TOGGLED ) {
      expressionsTreeCheckToggle(index);
   }
}

static void updateExpressionControls()
{
   curSel := ctltree_expressions._TreeCurIndex();
   prev := ctltree_expressions._TreeGetPrevSiblingIndex(curSel);
   next := ctltree_expressions._TreeGetNextSiblingIndex(curSel);
   ctlimagebtn_delexpression.p_enabled = (curSel > 0);
   ctlimagebtn_editexpression.p_enabled = (curSel > 0);
   ctlimagebtn_expressiondown.p_enabled = (next > 0);
   ctlimagebtn_expressionup.p_enabled = (prev > 0);
}

static void expressionsTreeCheckToggle(int index)
{
   folder_selected := ctltree_categories._TreeCurIndex();
   if (folder_selected<=0) return;
   int folder_row=ctltree_categories._TreeGetChildRow(folder_selected);
   if((index > 0)) {
      int re_row=ctltree_expressions._TreeGetChildRow(index);

      // Change the value of the Enabled attribute to correspond
      // to the new picture
      if( !_TreeGetCheckState(index) ) {
         gerrorre_folder_array[folder_row].m_errorre_array[re_row].m_enabled=false;
      } else {
         gerrorre_folder_array[folder_row].m_errorre_array[re_row].m_enabled=true;
      }
      set_modify();
   }
   //say("Lbutton up on "index);
}

////////////////////////////////////////////////////////
// _error_re_edit_form handlers and utility methods
////////////////////////////////////////////////////////
defeventtab _error_re_edit_form;

void _error_re_edit_form.on_create()
{
   _str expressionName = arg(1);
   _str expressionText = arg(2);
   _str testCases = arg(3);
   int folder_row = arg(4);
   int re_row = arg(5);
   macroName := "";

   _ctl_classification._lbadd_item(ERRORRE_SEVERITY_AUTO);
   _ctl_classification._lbadd_item("Error");
   _ctl_classification._lbadd_item("Warning");
   _ctl_classification._lbadd_item("Info");
   _ctl_classification.p_text = ERRORRE_SEVERITY_AUTO;


   if(re_row >=0) {
      // We've been passed a node index for an existing element
      expressionName = gerrorre_folder_array[folder_row].m_errorre_array[re_row].m_name;
      macroName = gerrorre_folder_array[folder_row].m_errorre_array[re_row].m_macro;

      expressionText = gerrorre_folder_array[folder_row].m_errorre_array[re_row].m_re;

      testCases = gerrorre_folder_array[folder_row].m_errorre_array[re_row].m_test_case;

      //p_caption = "Edit Expression";
      gcurrent_editing_re_row = re_row;
      gcurrent_editing_folder_row = folder_row;
      _ctl_classification.p_text = gerrorre_folder_array[folder_row].m_errorre_array[re_row].m_severity;
   } else {
      // No node element has been passed, so we're
      // creating a new expression
      //p_caption = "New Expression";
      gcurrent_editing_re_row = -1;
      gcurrent_editing_folder_row = folder_row;
   }

   // Populate the text box controls with the name, optional macro name,
   // and the expression itself
   ctltext_expressionname.p_text = expressionName;
   ctltext_macroname.p_text = macroName;
   _findstring.p_text = expressionText;

   // Right now, we're not implementing the macro funtionality,
   // so we'll hide those controls until we do
   ctltext_macroname.p_visible = false;
   ctllabel_macro.p_visible = false;
   ctledit_testcase.p_newline="\n";
   ctledit_testcase.top();ctledit_testcase.search("\r\n","@","\n");
   testCases=stranslate(testCases,"\n","\r\n");
   
   // Insert the test case text into the editor control
   ctledit_testcase._insert_text(testCases);
   ctledit_testcase.top();
   ctledit_testcase.up();
}

void _findre_type.on_create()
{
   _error_re_edit_form_initial_alignment();
   // Regular expression searches for error parsing are
   // always SlickEdit syntax
   _lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   p_text = RE_TYPE_SLICKEDIT_STRING;
}

void _findstring.f1()
{
   help('Sample error parsing expression');
}

static _str groupNames[] = {'Filename', 'Line #', 'Column', 'Message'};
// Validation button on the edit form. Run the regular expression
// against the test cases in the editor control
void ctlbtn_validate.lbutton_up()
{
   numLines := ctledit_testcase.p_Noflines;
   lineIndex := 1;
   expressionToTest := _findstring.p_text;
   _str lineText = null;
   searchOpts := "@IR";
   _findstring.p_forecolor = 0x80000008;
   errMsg := "No matches found";
   typeless p;
   lastSeekPos := -1;

   ctledit_testcase.save_pos(p);
   ctledit_testcase.top();
   // Iterate over all the lines in the editor control
   // and evaluate the expression.
   for(;;) {

      found := ctledit_testcase.search(expressionToTest,searchOpts);
      int nextSeekPos;
      if(found < 0 && found!=STRING_NOT_FOUND_RC) {
         // Set the expression color to red
         _findstring.p_forecolor = 0x000000FF;
         errMsg = "Invalid expression syntax";
         break;
      } else if(!found || match_length('')==0) {
         // We'll extract out the pieces that were matched
         // An error regular expression will have up to 4 tagged expressions
         // 0 = Filename where the error occurred
         // 1 = line number
         // 2 = column
         // 3 = error message
         errMsg = null;
         outputMessage := "Matched expression on line #":+ctledit_testcase.p_line;
         nextSeekPos=match_length('S')+match_length('');
         // make sure we haven't found the same seek pos
         if (nextSeekPos <= lastSeekPos) {
            break;
         }
         lastSeekPos = nextSeekPos;
         groupIdx := 0;
         for(;groupIdx <= 3; ++groupIdx) {
            //int groupStart = pos("S" :+ groupIdx);
            //int groupLen = pos(groupIdx);
            //if(groupStart > 0 && groupLen > 0)
            {
               groupText := ctledit_testcase.get_match_text(groupIdx);
               //_str thisGroup = ;
               outputMessage :+= "\n"groupNames[groupIdx]": "groupText;
            }
         }
         _str extra_message='';
         form_parent:=p_active_form.p_parent;
         bool preceding_match=false;
         _str matched_name='';
         _str matched_folder_name='';

         if (form_parent>0) {
            _nocheck _control ctltree_categories;
            folder_selected := form_parent.ctltree_categories._TreeCurIndex();
            if (folder_selected>0) {
               folder_caption:=form_parent.ctltree_categories._TreeGetCaption(folder_selected);
               ctledit_testcase.get_line(auto line);

               preceding_match=check_for_preceding_regex_match(extra_message,line,expressionToTest,folder_caption,matched_name,matched_folder_name);
            }
         }
         if (preceding_match) {
            outputMessage="Warning: An earlier error regex matches your sample ("matched_folder_name' - 'matched_name"). You might want to move the position of your regex up so it gets processed earlier.\n\n":+outputMessage;
         }
         _message_box(outputMessage, "Matched Error Expression", MB_OK | MB_ICONINFORMATION);
      } else {
         break;
      }
      ctledit_testcase.goto_point(nextSeekPos);
      //ctledit_testcase.down();ctledit_testcase.begin_line();
   }
   ctledit_testcase.restore_pos(p);
   if (errMsg != null) {
      message(errMsg);
   }
}
static bool check_for_preceding_regex_match(_str &extra_message,_str line, _str test_regex,_str folder_name, _str &matched_name, _str &matched_folder_name) {
   extra_message='';
   if (pos("^(Extension|langid)", folder_name, 1, "ir") != 0 || pos("^Exclu", folder_name, 1, "ir") != 0) {
      return false;
   }


   done:=false;
   for (i:=0;i<gerrorre_folder_array._length();++i) {
      _str temp_folder_name=gerrorre_folder_array[i].m_name;
      if (pos("^(Extension|langid)", temp_folder_name, 1, "ir") != 0 || pos("^Exclu", temp_folder_name, 1, "ir") != 0) {
         continue;
      }
      int len=gerrorre_folder_array[i].m_errorre_array._length();
      for (j:=0;j<len;++j) {
         if (gerrorre_folder_array[i].m_errorre_array[j].m_enabled) {
            if (gerrorre_folder_array[i].m_errorre_array[j].m_re==test_regex) {
               done=true;
               break;
            }
            status := pos(gerrorre_folder_array[i].m_errorre_array[j].m_re, line, 1, 'ri');
            if (status) {
               matched_folder_name=temp_folder_name;
               matched_name=gerrorre_folder_array[i].m_errorre_array[j].m_name;
               //expressionThatMatched = gAllExpressions[hashIndex].regex;
               return true;
            }
         }
      }
      if (done) {
         break;
      }

   }
   return false;
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _error_re_edit_form_initial_alignment()
{
   rightAlign := ctledit_testcase.p_x_extent;
   sizeBrowseButtonToTextBox(_findstring.p_window_id, _re_button.p_window_id, 0, rightAlign);
}

void _error_re_edit_form.on_resize()
{
   int padding = _findstring.p_x;

   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      int minW = ctltext_macroname.p_x_extent + padding;
      int minH = (ctledit_testcase.p_y * 2) + padding;
      _set_minimum_size(minW, minH);
   }

   // For horizontal resizing, just stretch the expression entry and the editor control
   widthDiff := p_width - (ctledit_testcase.p_x_extent + padding);
   if (widthDiff) {
      // Resize the expression entry and the test case editor
      _findstring.p_width += widthDiff;
      ctledit_testcase.p_width += widthDiff;

      // Re-align the pop-up menu button to the right of the expression entry
      _re_button.p_x += widthDiff;

      // Re-align the OK, Cancel, and help buttons
      ctlbtn_help.p_x += widthDiff;
      ctlbtn_cxl.p_x += widthDiff;
      ctlbtn_ok.p_x += widthDiff;
   }

   // For vertical resizing, just expand the editor control
   heightDiff := p_height - (ctlbtn_ok.p_y_extent + padding);
   if (heightDiff) {
      // First, bottom align the buttons
      ctlbtn_ok.p_y += heightDiff;
      ctlbtn_cxl.p_y = ctlbtn_validate.p_y = ctlbtn_help.p_y = ctlbtn_ok.p_y;

      // Now resize the editor control to fit
      ctledit_testcase.p_height += heightDiff;
   }
}

void ctlbtn_cxl.lbutton_up()
{
   // Close the form without saving the XML configuration
   //say("Edit form cancelled");
   p_active_form._delete_window();

}
void ctlbtn_ok.lbutton_up()
{
   // Get all the text values out of the controls
   retVal := "";
   macroName := ctltext_macroname.p_text;
   testCases := ctledit_testcase.get_text(ctledit_testcase.p_buf_size,0);
   expName := ctltext_expressionname.p_text;
   expVal := _findstring.p_text;
   classification := _ctl_classification.p_text;

   retVal = 'edit';
   if(gcurrent_editing_re_row<0) {
      gcurrent_editing_re_row=gerrorre_folder_array[gcurrent_editing_folder_row].m_errorre_array._length();
      retVal = 'new';
      // Check if the name specified already exists
      int len=gerrorre_folder_array[gcurrent_editing_folder_row].m_errorre_array._length();
      for (i:=0;i<len;++i) {
         if (strieq(expName,gerrorre_folder_array[gcurrent_editing_folder_row].m_errorre_array[i].m_name)) {
            _message_box(nls("Name '%s' already exists",expName));
            return;
         }
      }
   }

   saveEditedNode(gerrorre_folder_array[gcurrent_editing_folder_row].m_errorre_array[gcurrent_editing_re_row], 
                  expName, expVal, macroName, testCases, classification);
   
   p_active_form._delete_window(retVal);
}

static void saveEditedNode(ERRORRE_INFO &info, _str expressionName, 
                           _str expression, _str macroName, _str testCases, 
                           _str classification) {
   info.m_name=expressionName;
   info.m_enabled=true;
   info.m_re=expression;
   info.m_macro=macroName;
   info.m_test_case=testCases;
   info.m_severity = classification;
}



// Just determines if the category already exists. This way we don't create
// duplicates
static bool categoryAlreadyExists(_str categoryName)
{
   for (i:=0;i<gerrorre_folder_array._length();++i) {
      folder_name:=gerrorre_folder_array[i].m_name;
      if (strieq(folder_name,categoryName)) {
         return true;
      }
   }
   return false;
}
_str _check_new_category() {
   _str toValidate = arg(1) ;
   if(toValidate == null || toValidate == '') {
      return(1);
   }
   if(categoryAlreadyExists(toValidate)) {
      _nocheck _control text1;
      text1._text_box_error(nls("Category '%s' already exists",toValidate));
      // use _textbox_error
      return(1);
   }
   return(0); // for ok , 1 for error
}

