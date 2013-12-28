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
#import "error.e"
#import "diff.e"
#import "help.e"
#import "listbox.e"
#import "picture.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion

#define ERROR_RE_CONFIG_FILENAME 'ErrorRE.xml'

static int cached_xml_handle = -1;
static int current_editing_node = -1;
static int current_editing_parent = -1;
static boolean suppressPicClickExp = false;
static boolean suppressPicClickCat = false;
static boolean configurationModified = false;

definit()
{
   cached_xml_handle = -1;
   current_editing_node = -1;
   current_editing_parent = -1;
   suppressPicClickExp = false;
   suppressPicClickCat = false;
   configurationModified = false;
}

/**
 * Returns the handle to the error configuration xml file,
 * optionally loading the file if it's not already been loaded.
 * 
 * @param create     true to load the xml file if it's not
 *                   loaded already
 * 
 * @return           xml config handle
 */
static int getConfigHandle(boolean load = true)
{
   // only create a new handle if the parameter says so
   if(cached_xml_handle < 0 && load)
   {
      // Call loadErrorConfigFile located in error.e
      // This will load the existing file or create it
      int loadIDX = find_index("loadErrorConfigFile", PROC_TYPE);
      if(loadIDX > 0)
      {
         int handle = (int)call_index(loadIDX);
         if(handle >= 0)
            cached_xml_handle = handle;
      }
   }
   return cached_xml_handle;
}

static void saveConfiguration()
{
   if(cached_xml_handle > -1)
   {
      //say("Saving configuration");
      if(_xmlcfg_save(cached_xml_handle, -1, 0) == 0)
      {
         configurationModified = true;
      }
   }
}


// Releases the reference to the error configuration xml file
static void releaseConfigHandle()
{
   if(cached_xml_handle > -1)
   {
      //_xmlcfg_save(cached_xml_handle, -1, 0);
      _xmlcfg_close(cached_xml_handle);
      cached_xml_handle = -1;
   }
}

defeventtab _error_re_form;

#region Options Dialog Helper Functions

void _error_re_form_init_for_options()
{
   ctlbtn_ok.p_visible = false;
   ctlbtn_cxl.p_visible = false;
   ctlbtn_help.p_visible = false;
}

void _error_re_form_save_settings()
{
   handle := getConfigHandle(false);
   if(handle > 0)
   {    
      _xmlcfg_set_modify(handle, 0);
   }
}

boolean _error_re_form_is_modified()
{
   // we use the modify setting of the xml file...we are trusting.
   handle := getConfigHandle(false);
   if(handle > 0) 
   {
      return (_xmlcfg_get_modify(handle) != 0);
   }

   // we shouldn't get here, but we'll do this because we are confused
   return false;
}

boolean _error_re_form_apply()
{
   // Save changes to the XML configuration
   saveConfiguration();

   return true;
}

_str _error_re_form_export_settings(_str &file)
{
   error := '';
   config_file := _ConfigPath() :+ ERROR_RE_CONFIG_FILENAME;
   if(file_exists(config_file)) 
   {
      if (copy_file(config_file, file :+ ERROR_RE_CONFIG_FILENAME)) error = 'Error exporting Configure Error Parsing options.';
      file = ERROR_RE_CONFIG_FILENAME;
   }

   return error;
}

_str _error_re_form_import_settings(_str file)
{
   error := '';
   config_file := _ConfigPath() :+ ERROR_RE_CONFIG_FILENAME;
   if (copy_file(file, config_file)) error = 'Error importing Configure Error Parsing options.';

   return error;
}

#endregion Options Dialog Helper Functions

void ctlbtn_reset.lbutton_up()
{
   // delete the existing xml file
   if(cached_xml_handle > -1)
   {
      releaseConfigHandle();
   }

   // clear out the trees
   ctltree_categories._TreeDelete(TREE_ROOT_INDEX, 'C');
   ctltree_categories._TreeRefresh();
   ctltree_expressions._TreeDelete(TREE_ROOT_INDEX, 'C');
   ctltree_expressions._TreeRefresh();

   handle := resetErrorConfigFile();
   if (handle >= 0)
   {   
      cached_xml_handle = handle;
   }

   // recreate it again
   loadToolTree();
   OnCategoryChange();
}

void ctlimagebtn_addexpression.lbutton_up()
{
   // Bring up the "edit expression" dialog so the user
   // can define and test a new error expression
   _str sampleTestCase = 'Error in /usr/proj/tmp/file.x, line 23, column 13: Fatal error' :+ "\r\n" :+
                         '         -group #0-           -group #1- -group #2- -group #3-\r\n' :+ "\r\n" :+
                         'error in C:\MyProjects\file.c, line 44, column 44: stdio.h not found';
   _str sampleExpression = '^Error in:b{#0:p},:bline:b{#1:i},:bcolumn:b{#2:i}\::b{#3?+}$';

   int selectedCategory = ctltree_categories._TreeCurIndex();
   int categoryNode = ctltree_categories._TreeGetUserInfo(selectedCategory);
   _str retVal = show('-modal -xy _error_re_edit_form', "<name>", sampleExpression, sampleTestCase, -1, categoryNode);
   if(retVal != null && retVal != '')
   {
      OnCategoryChange();
      //_str retVal = expName'###'expVal'###'macroName'###'testCases;
   }
}

void ctlimagebtn_delexpression.lbutton_up()
{
   // Delete the selected expression
   int selected = ctltree_expressions._TreeCurIndex();
   if(selected > 0)
   {
      int expNode = ctltree_expressions._TreeGetUserInfo(selected);
      if(expNode > 0)
      {
         deleteAndReprioritize(expNode);

         // Now refresh the tree. Just fake a change in
         // selection of the category list
         OnCategoryChange();
      }
   }
}

void ctlimagebtn_editexpression.lbutton_up()
{
   // Bring up the "edit expression" dialog so the user
   // can modify and test the expression
   // Show the edit form to modify this expression
   int selIdx = ctltree_expressions._TreeCurIndex();
   if(selIdx > 0)
   {
      int nodeIdx = (int)ctltree_expressions._TreeGetUserInfo(selIdx);
      if(nodeIdx > 0)
      {
         int selectedCategory = ctltree_categories._TreeCurIndex();
         int categoryNode = ctltree_categories._TreeGetUserInfo(selectedCategory);
         _str retVal = show('-modal -xy _error_re_edit_form', "", "", "", nodeIdx, categoryNode);
         if(retVal != null && retVal != '')
         {
            OnCategoryChange();
            //_str retVal = expName'###'expVal'###'macroName'###'testCases;
         }
      }
   }
}

// Button to delete a category/tool
void ctlimagebtn_delcat.lbutton_up()
{
   // TODO: Display prompt for removing this category
   // or simply disabling it.
   int selCategory = ctltree_categories._TreeCurIndex();
   if(selCategory > 0)
   {
      int categoryNode = ctltree_categories._TreeGetUserInfo(selCategory);
      if(categoryNode > 0)
      {
         deleteAndReprioritize(categoryNode);

         // Now reload the category tree
         loadToolTree();
         //ctltree_categories._TreeSetCurIndex(selCategory - 1);
         updateCategoryControls();

      }
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
   addNewCategory(newName);
   // Refresh/reload the list of expression categories
   loadToolTree();

   // Reset the selection index to select the newly created node
   int newPlace = ctltree_categories._TreeSearch(TREE_ROOT_INDEX, newName);
   ctltree_categories._TreeSetCurIndex(newPlace);

   // Make sure the expressions for this category are updated
   // TODO: This may be redundant, and possibly removed
   OnCategoryChange();
}

_str _check_new_category()
{
   _str toValidate = arg(1) ;
   if(toValidate == null || toValidate == '')
      return(1);

   //say('Validating: 'toValidate);
   // Now make sure the category doesn't already exist
   if(categoryAlreadyExists(toValidate))
   {
      //say('Category already exists');
      //text1.p_text = toValidate :+ ' already exists.';
      _nocheck _control text1;
      text1._text_box_error('Category 'toValidate' already exists');
      // use _textbox_error
      return(1);
   }
   return(0); // for ok , 1 for error
}

// Button to move a category/tool down in priority
void ctlimagebtn_catdown.lbutton_up()
{
   // Move category/tool priority down
   // Get the selected index
   int selected = ctltree_categories._TreeCurIndex();
   // Get the next item in the tree
   int next = ctltree_categories._TreeGetNextSiblingIndex(selected);

   // If we have 2 valid tree nodes, get the xml indices
   // and swap the priority attribute values
   if(selected > 0 && next > 0)
   {
      _str caption = ctltree_categories._TreeGetCaption(selected);

      int selectedNode = ctltree_categories._TreeGetUserInfo(selected);
      int nextNode = ctltree_categories._TreeGetUserInfo(next);
      swapNodePriority(selectedNode, nextNode);

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
   int selected = ctltree_categories._TreeCurIndex();
   // Get the previous item in the tree
   int prev = ctltree_categories._TreeGetPrevSiblingIndex(selected);

   // If we have 2 valid tree nodes, get the xml indices
   // and swap the priority attribute values
   if(selected > 0 && prev > 0)
   {
      _str caption = ctltree_categories._TreeGetCaption(selected);

      int selectedNode = ctltree_categories._TreeGetUserInfo(selected);
      int prevNode = ctltree_categories._TreeGetUserInfo(prev);
      swapNodePriority(selectedNode, prevNode);

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
   int selected = ctltree_expressions._TreeCurIndex();
   // Get the next item in the tree
   int next = ctltree_expressions._TreeGetNextSiblingIndex(selected);

   // If we have 2 valid tree nodes, get the xml indices
   // and swap the priority attribute values
   if(selected > 0 && next > 0)
   {
      _str caption = ctltree_expressions._TreeGetCaption(selected);

      int selectedNode = ctltree_expressions._TreeGetUserInfo(selected);
      int nextNode = ctltree_expressions._TreeGetUserInfo(next);
      swapNodePriority(selectedNode, nextNode);

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
   int selected = ctltree_expressions._TreeCurIndex();
  
   // Get the previous item in the tree
   int prev = ctltree_expressions._TreeGetPrevSiblingIndex(selected);
   // If we have 2 valid tree nodes, get the xml indices
   // and swap the priority attribute values
   if(selected > 0 && prev > 0)
   {
      _str caption = ctltree_expressions._TreeGetCaption(selected);

      int selectedNode = ctltree_expressions._TreeGetUserInfo(selected);
      int prevNode = ctltree_expressions._TreeGetUserInfo(prev);
      swapNodePriority(selectedNode, prevNode);

      // Reload the expression tree to reflect the changes
      loadExpressionTree();

      int newPlace = ctltree_expressions._TreeSearch(TREE_ROOT_INDEX, caption);
      ctltree_expressions._TreeSetCurIndex(newPlace);
   }
   updateExpressionControls();
}

// Swaps the "Priority" attribute value of two Expression
// or two Tool nodes that are siblings
static void swapNodePriority(int original, int sibiling)
{
   int xhandle = getConfigHandle();
   // Get the priority value of the current selected item
   _str origPriority = _xmlcfg_get_attribute(xhandle, original, "Priority");

   // Get the priority value of the sibling item to swap with
   _str siblingPriority = _xmlcfg_get_attribute(xhandle, sibiling, "Priority");

   _xmlcfg_set_attribute(xhandle, original, "Priority", siblingPriority);
   _xmlcfg_set_attribute(xhandle, sibiling, "Priority", origPriority);
}

static void deleteAndReprioritize(int nodeToDelete)
{
   // First get the priority value of the node we're going to delete
   int xhandle = getConfigHandle();
   _str origPriority = _xmlcfg_get_attribute(xhandle, nodeToDelete, "Priority");
   int nOrigPriority = (int)origPriority;
   int startNode = nodeToDelete;
   int prevNode = _xmlcfg_get_prev_sibling(xhandle, startNode);
   while(prevNode > 0)
   {
      // Decrement the priority attibute if it is greater than the 
      // one we are deleting
      _str sibPriority = _xmlcfg_get_attribute(xhandle, prevNode, "Priority");
      int nsibPriority = (int)sibPriority;
      if(nsibPriority > nOrigPriority)
      {
         _str newPriority = (_str)(nsibPriority - 1);
         _xmlcfg_set_attribute(xhandle, prevNode, "Priority", newPriority);
      }
      startNode = prevNode;
      prevNode = _xmlcfg_get_prev_sibling(xhandle, startNode);
   }

   startNode = nodeToDelete;
   int nextNode = _xmlcfg_get_next_sibling(xhandle, startNode);
   while(nextNode > 0)
   {
      // TODO: Decrement the priority attibute if it is greater than the 
      // one we are deleting
      _str sibPriority = _xmlcfg_get_attribute(xhandle, nextNode, "Priority");
      int nsibPriority = (int)sibPriority;
      if(nsibPriority > nOrigPriority)
      {
         _str newPriority = (_str)(nsibPriority - 1);
         _xmlcfg_set_attribute(xhandle, nextNode, "Priority", newPriority);
      }
      startNode = nextNode;
      nextNode = _xmlcfg_get_next_sibling(xhandle, startNode);
   }

   _xmlcfg_delete(xhandle, nodeToDelete);

}

void _error_re_form.on_destroy()
{
   releaseConfigHandle();
}

void _error_re_form.on_create()
{
   _error_re_form_initial_alignment();

   ctltree_expressions._TreeSetColButtonInfo(0, 2000, TREE_BUTTON_AUTOSIZE, -1, "Name");
   ctltree_expressions._TreeSetColButtonInfo(1, 3000, TREE_BUTTON_AUTOSIZE , -1, "Expression");
   ctltree_expressions._TreeSetColEditStyle(1,TREE_EDIT_TEXTBOX);
   ctltree_categories._TreeSetColButtonInfo(0, 2000, TREE_BUTTON_AUTOSIZE, -1, "Expression Category");
   loadToolTree();
   ctlimagebtn_catdown.p_enabled = false;
   ctlimagebtn_catup.p_enabled = false;
   ctlimagebtn_delcat.p_enabled = false;

   int firstChild = ctltree_categories._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if(firstChild >= 0)
   {
      ctltree_categories._TreeSetCurIndex(firstChild);
      OnCategoryChange();
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _error_re_form_initial_alignment()
{
   ctlimagebtn_editexpression.p_auto_size = false;
   ctlimagebtn_editexpression.p_width = ctlimagebtn_addexpression.p_width;
   ctlimagebtn_editexpression.p_height = ctlimagebtn_addexpression.p_height;

   alignUpDownListButtons(ctltree_categories, 0, ctlimagebtn_addcat.p_window_id,
                          ctlimagebtn_delcat.p_window_id, ctlimagebtn_catup.p_window_id, ctlimagebtn_catdown.p_window_id);

   rightAlign := p_active_form.p_width - ctltree_expressions.p_x;
   alignUpDownListButtons(ctltree_expressions, rightAlign, ctlimagebtn_editexpression.p_window_id,
                          ctlimagebtn_addexpression.p_window_id, ctlimagebtn_delexpression.p_window_id,
                          ctlimagebtn_expressionup.p_window_id, ctlimagebtn_expressiondown.p_window_id);
}

void _error_re_form.on_resize()
{
   int clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   int padding = ctltree_categories.p_x;

   // if we are not embedded in the options, we have a min size
   // have we set the min size yet?  if not, min width will be 0
   if (ctlbtn_ok.p_visible && !_minimum_width()) {
      minH := ctlbtn_reset.p_height * 13 + padding;
      minW := ctlbtn_reset.p_width * 5 + padding;

      _set_minimum_size(minW, minH);
   }
   
   // We won't resize the "categories" area, but will stretch the expressions area
   // Determine where to place the image buttons for the expression area
   widthDiff := clientW - (ctlimagebtn_expressiondown.p_x + ctlimagebtn_expressiondown.p_width + padding);
   if(widthDiff)
   {
      // move our buttons over
      ctlimagebtn_delexpression.p_x += widthDiff;
      ctlimagebtn_expressiondown.p_x += widthDiff;
      ctlimagebtn_expressionup.p_x += widthDiff;
      ctlimagebtn_editexpression.p_x += widthDiff;
      ctlimagebtn_addexpression.p_x += widthDiff;

      // Resize the expression area to fit between the left and the image buttons
      ctltree_expressions.p_width +=  widthDiff;

      // move the buttons, too - will only show up if not embedded in options
      ctlbtn_help.p_x += widthDiff;
      ctlbtn_cxl.p_x += widthDiff;
      ctlbtn_ok.p_x += widthDiff;
   }

   heightDiff := 0;
   heightDiff = clientH - (ctlbtn_reset.p_y + ctlbtn_reset.p_height + padding);

   if(heightDiff)
   {
      // Resize the expression area
      ctltree_expressions.p_height += heightDiff;

      ctlbtn_reset.p_y += heightDiff;
      ctlbtn_help.p_y += heightDiff;
      ctlbtn_cxl.p_y += heightDiff;
      ctlbtn_ok.p_y += heightDiff;
   }

   ctltree_expressions.refresh();
}

void _error_re_form.f1()
{
   help(p_active_form.p_help);
}

void ctlbtn_cxl.lbutton_up()
{
   // Close the form without saving the XML configuration
   //say("Form cancelled");
   p_active_form._delete_window();

}

void ctlbtn_ok.lbutton_up()
{
   _error_re_form_apply();
   _str retVal = configurationModified ? 'modified' : '';
   p_active_form._delete_window(retVal);
}

// Fired when the selected tool changes
void ctltree_categories.on_change(int reason,int index)
{
   if( reason == CHANGE_SELECTED ){
      suppressPicClickCat = true;
      OnCategoryChange();
   } else if ( reason==CHANGE_CHECK_TOGGLED ) {
      categoryTreeCheckToggle(index);
   }
}

static int categoryTreeCheckToggle(int index)
{
   if((index > 0) /*&& (suppressPicClickCat == false)*/ ) {
      // get the bitmap information in the tree

      int nodeIdx = (int)_TreeGetUserInfo(index);

      // toggle the picture, but only if it's not grayed out

      // Change the value of the Enabled attribute to correspond
      // to the new picture
      if( !_TreeGetCheckState(index) ) {
         _xmlcfg_set_attribute(getConfigHandle(), nodeIdx, "Enabled", "0");
      } else {
         _xmlcfg_set_attribute(getConfigHandle(), nodeIdx, "Enabled", "1");
      }

   }
   //say("Lbutton up on "index);
   suppressPicClickCat = false;
   return 0;
}

static void updateCategoryControls()
{
   int curSel = ctltree_categories._TreeCurIndex();
   int prevSib = ctltree_categories._TreeGetPrevSiblingIndex(curSel);
   int nextSib = ctltree_categories._TreeGetNextSiblingIndex(curSel);
   // Disable UP button if no previous category
   ctlimagebtn_catup.p_enabled = (prevSib > 0);
   // Disable DOWN button if no previous category
   ctlimagebtn_catdown.p_enabled = (nextSib > 0);

   _str cap = ctltree_categories._TreeGetCaption(curSel);
   // Disable deleting the default category
   if(cap == null)
   {
      ctlimagebtn_delcat.p_enabled = false;
   }
   else
   {
      ctlimagebtn_delcat.p_enabled = true;
   }
}

static void loadToolTree()
{
   // Clear any existing contents
   ctltree_categories._TreeDelete(0, "C");
   ctltree_categories._TreeBeginUpdate(TREE_ROOT_INDEX);
   // Populate the tree list of tools/categories, sorted by priority
   int priority = 0;
   _str toolXpath = '//Tool[@Priority="' :+ (priority) :+ '"]';
   int xhandle = getConfigHandle();
   int toolIdx = _xmlcfg_find_simple(xhandle, toolXpath, TREE_ROOT_INDEX);
   while(toolIdx > -1) {
      _str toolName =_xmlcfg_get_attribute(xhandle, toolIdx, "Name", 0);
      // If this node has the Enabled="0" attribute
      _str enabledAttr =_xmlcfg_get_attribute(xhandle, toolIdx, "Enabled", "1");

      // Add the item to the category tree
      int addedItem = ctltree_categories._TreeAddListItem(toolName,0,TREE_ROOT_INDEX,-1,toolIdx);

      if(enabledAttr == "1") {
         ctltree_categories._TreeSetCheckState(addedItem, TCB_CHECKED);
      } else {
         ctltree_categories._TreeSetCheckState(addedItem, TCB_UNCHECKED);
      }
     
      toolXpath = '//Tool[@Priority="' :+ (++priority) :+ '"]';
      toolIdx = _xmlcfg_find_simple(xhandle, toolXpath, TREE_ROOT_INDEX);
   }
   ctltree_categories._TreeEndUpdate(TREE_ROOT_INDEX);
}

static void OnCategoryChange()
{
   updateCategoryControls();

   loadExpressionTree();

   int firstChild = ctltree_expressions._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (firstChild >= 0)
      ctltree_expressions._TreeSetCurIndex(firstChild);

   updateExpressionControls();
}

// Populate the tree list of regular expressions based on the 
// selected category/tool
static void loadExpressionTree()
{
   // Clear out the current expression list contents
   ctltree_expressions._TreeDelete(0, "C");
   ctltree_expressions._TreeBeginUpdate(TREE_ROOT_INDEX);

   // Get the selected item from the category/tool listing
   int selCategory = ctltree_categories._TreeCurIndex();
   _str selectedText = ctltree_categories._TreeGetCaption(selCategory);
  
   // Use XPath to look for the <Tool> node that has the Name attribute
   // matching the newly-selected list text
   int xml_handle = getConfigHandle();
   if(xml_handle > -1)
   {
      //XPath search for //Tool[@Name='selectedText']
      _str toolXpath = '//Tool[@Name="' :+ selectedText :+ '"]';
      int toolIdx = _xmlcfg_find_simple(xml_handle, toolXpath, TREE_ROOT_INDEX);
      if(toolIdx > -1)
      {
         // Get the list of all <Expression> nodes under the selected Tool
         // Get them in order of priority
         int priority = 0;
         _str expXpath = 'Expression[@Priority="' :+ (priority) :+ '"]';
         int expIdx = _xmlcfg_find_simple(xml_handle, expXpath, toolIdx);
         while(expIdx > -1)
         {
            
            // Get the names of the <Expression>s and add them to the list
            _str reName =_xmlcfg_get_attribute(xml_handle,expIdx,"Name",0);
            _str enabledAttr = _xmlcfg_get_attribute(xml_handle, expIdx, "Enabled", '1');

            // Underneath the Expression node is the <RE> node, with a CDATA element
            // The CDATA element contains the text of the regular expression
            int reNodeIdx = _xmlcfg_find_child_with_name(xml_handle, expIdx, "RE");
            if(reNodeIdx > -1)
            {
              
              int cdataIdx = _xmlcfg_get_first_child(xml_handle, reNodeIdx, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
              if(cdataIdx > -1)
              {
                  _str reCDATAValue = _xmlcfg_get_value(xml_handle, cdataIdx);
                  int addedItem = ctltree_expressions._TreeAddListItem(reName :+ "\t" :+ reCDATAValue, 0, TREE_ROOT_INDEX, -1, expIdx);

                  // TODO: If the parent (list box) category is disabled, then add the child items
                  // as greyed.
                  if(enabledAttr == "1") {
                     ctltree_expressions._TreeSetCheckState(addedItem, TCB_CHECKED);
                  } else {
                     ctltree_expressions._TreeSetCheckState(addedItem, TCB_UNCHECKED);
                  }
              }
            }

            expXpath = 'Expression[@Priority="' :+ (++priority) :+ '"]';
            expIdx = _xmlcfg_find_simple(xml_handle, expXpath, toolIdx);
         }
      }
   }
   ctltree_expressions._TreeEndUpdate(TREE_ROOT_INDEX);
}


void ctltree_expressions.on_change(int reason,int index)
{
   if(reason == CHANGE_LEAF_ENTER) /* Double click or enter */ {
      // Show the edit form to modify this expression
      int nodeIdx = (int)_TreeGetUserInfo(index);
      int selectedCategory = ctltree_categories._TreeCurIndex();
      int categoryNode = ctltree_categories._TreeGetUserInfo(selectedCategory);
      _str retVal = show('-modal -xy _error_re_edit_form', "", "", "", nodeIdx, categoryNode);
      if(retVal != null && retVal != '')
      {
         OnCategoryChange();
         //_str retVal = expName'###'expVal'###'macroName'###'testCases;
      }
   } else if (reason == CHANGE_SELECTED) {
      // TODO: Suppress lbutton_up event for toggling the expression
      //say("Changed to "index);
      updateExpressionControls();
      suppressPicClickExp = true;
   } else if ( reason==CHANGE_CHECK_TOGGLED ) {
      expressionsTreeCheckToggle(index);
   }
}

static void updateExpressionControls()
{
   int curSel = ctltree_expressions._TreeCurIndex();
   int prev = ctltree_expressions._TreeGetPrevSiblingIndex(curSel);
   int next = ctltree_expressions._TreeGetNextSiblingIndex(curSel);
   ctlimagebtn_delexpression.p_enabled = (curSel > 0);
   ctlimagebtn_editexpression.p_enabled = (curSel > 0);
   ctlimagebtn_expressiondown.p_enabled = (next > 0);
   ctlimagebtn_expressionup.p_enabled = (prev > 0);
}

static int expressionsTreeCheckToggle(int index)
{
   if((index > 0) /*&& (suppressPicClickExp == false)*/ ) {
      // get the bitmap information in the tree

      int nodeIdx = (int)_TreeGetUserInfo(index);

      // toggle the picture, but only if it's not grayed out

      // Change the value of the Enabled attribute to correspond
      // to the new picture
      if( !_TreeGetCheckState(index) ) {
         _xmlcfg_set_attribute(getConfigHandle(), nodeIdx, "Enabled", "0");
      } else {
         _xmlcfg_set_attribute(getConfigHandle(), nodeIdx, "Enabled", "1");
      }
   }
   //say("Lbutton up on "index);
   suppressPicClickExp = false;
   return 0;
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
   int nodeIndex = arg(4);
   int parentIndex = arg(5);
   _str macroName = '';

   if(nodeIndex > 0)
   {
      // We've been passed a node index for an existing element

      // Get the information directly out of the xml document, instead
      // of from the parameters
      // Get the names of the <Expression>s and add them to the list
      int xml_handle = getConfigHandle();
      expressionName = _xmlcfg_get_attribute(xml_handle,nodeIndex,"Name",0);
      macroName = _xmlcfg_get_attribute(xml_handle,nodeIndex,"Macro");

      // Underneath the Expression node is the <RE> node, with a CDATA element
      // The CDATA element contains the text of the regular expression
      int reNodeIdx = _xmlcfg_find_child_with_name(xml_handle, nodeIndex, "RE");
      if(reNodeIdx > -1)
      {
        int cdataIdx = _xmlcfg_get_first_child(xml_handle, reNodeIdx, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
        if(cdataIdx > -1)
        {
            expressionText = _xmlcfg_get_value(xml_handle, cdataIdx);
        }
      }

      // Also unde the Expression node is a Matches node that contains an optional test
      // case of line(s) that should be matched by the regular expression
      int testCaseIdx = _xmlcfg_find_child_with_name(xml_handle, nodeIndex, "Matches");
      if(testCaseIdx > -1)
      {
        int cdataIdx = _xmlcfg_get_first_child(xml_handle, testCaseIdx, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
        if(cdataIdx > -1)
        {
            testCases = _xmlcfg_get_value(xml_handle, cdataIdx);
        }
      }

      //p_caption = "Edit Expression";
      current_editing_node = nodeIndex;
      current_editing_parent = parentIndex;
   }
   else
   {
      // No node element has been passed, so we're
      // creating a new expression
      //p_caption = "New Expression";
      current_editing_node = -1;
      current_editing_parent = parentIndex;
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
   int numLines = ctledit_testcase.p_Noflines;
   int lineIndex = 1;
   _str expressionToTest = _findstring.p_text;
   _str lineText = null;
   _str searchOpts = "@IR";
   _findstring.p_forecolor = 0x80000008;
   _str errMsg = "No matches found";
   typeless p;
   int lastSeekPos = -1;

   ctledit_testcase.save_pos(p);
   ctledit_testcase.top();
   // Iterate over all the lines in the editor control
   // and evaluate the expression.
   for(;;) {

      int found=ctledit_testcase.search(expressionToTest,searchOpts);
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
         _str outputMessage="Matched expression on line #":+ctledit_testcase.p_line;
         nextSeekPos=match_length('S')+match_length('');
         // make sure we haven't found the same seek pos
         if (nextSeekPos <= lastSeekPos) {
            break;
         }
         lastSeekPos = nextSeekPos;
         int groupIdx = 0;
         for(;groupIdx <= 3; ++groupIdx) {
            //int groupStart = pos("S" :+ groupIdx);
            //int groupLen = pos(groupIdx);
            //if(groupStart > 0 && groupLen > 0)
            {
               _str groupText= ctledit_testcase.get_match_text(groupIdx);
               //_str thisGroup = ;
               outputMessage = outputMessage :+ "\n"groupNames[groupIdx]": "groupText;
            }
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

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _error_re_edit_form_initial_alignment()
{
   rightAlign := ctledit_testcase.p_x + ctledit_testcase.p_width;
   sizeBrowseButtonToTextBox(_findstring.p_window_id, _re_button.p_window_id, 0, rightAlign);
}

void _error_re_edit_form.on_resize()
{
   int padding = _findstring.p_x;

   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      int minW = ctltext_macroname.p_x + ctltext_macroname.p_width + padding;
      int minH = (ctledit_testcase.p_y * 2) + padding;
      _set_minimum_size(minW, minH);
   }

   // For horizontal resizing, just stretch the expression entry and the editor control
   widthDiff := p_width - (ctledit_testcase.p_x + ctledit_testcase.p_width + padding);
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
   heightDiff := p_height - (ctlbtn_ok.p_y + ctlbtn_ok.p_height + padding);
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
   _str retVal = '';
   _str macroName = ctltext_macroname.p_text;
   _str testCases = ctledit_testcase.get_text(ctledit_testcase.p_buf_size,0);
   _str expName = ctltext_expressionname.p_text;
   _str expVal = _findstring.p_text;

   if(current_editing_node >= 0)
   {
      if(saveEditedNode(current_editing_node, expName, expVal, macroName, testCases) > 0)
         retVal = 'edit';
   }
   else
   {
      // The dialog is creating a brand-new node
      if(saveNewNode(current_editing_parent, expName, expVal,macroName,testCases) > 0)
          retVal = 'new';
   }
   
   p_active_form._delete_window(retVal);
}

static int saveEditedNode(int nodeIndex, _str expressionName, _str expression, _str macroName, _str testCases)
{
   int xHandle = getConfigHandle();
   if(xHandle < 0)
      return -1;

   // Update the XML node for this expression
   _xmlcfg_set_attribute(xHandle, nodeIndex, 'Name', expressionName);
   _xmlcfg_set_attribute(xHandle, nodeIndex, 'Macro', macroName);

   // Underneath the Expression node is the <RE> node, with a CDATA element
   // The CDATA element contains the text of the regular expression
   int reNodeIdx = _xmlcfg_find_child_with_name(xHandle, nodeIndex, "RE");
   if(reNodeIdx > -1)
   {
     int cdataIdx = _xmlcfg_get_first_child(xHandle, reNodeIdx, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
     if(cdataIdx > -1)
     {
        _xmlcfg_set_value(xHandle, cdataIdx, expression);
     }
   }

   // Also unde the Expression node is a Matches node that contains an optional test
   // case of line(s) that should be matched by the regular expression
   int testCaseIdx = _xmlcfg_find_child_with_name(xHandle, nodeIndex, "Matches");
   if(testCaseIdx < 0)
   {
      // The Matches node may not be there in the default file. So create it.
      testCaseIdx = _xmlcfg_add(xHandle, nodeIndex, 'Matches', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      if (testCaseIdx > 0)
      {
         int matchTextCDATA = _xmlcfg_add(xHandle, testCaseIdx, '', VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
      }
   }
   if(testCaseIdx > 0)
   {
      // Set the value of the child CDATA node
     int cdataIdx = _xmlcfg_get_first_child(xHandle, testCaseIdx, VSXMLCFG_NODE_CDATA | VSXMLCFG_NODE_PCDATA);
     if(cdataIdx > -1)
     {
        _xmlcfg_set_value(xHandle, cdataIdx, testCases);
     }
   }
   return 1;
}

static int saveNewNode(int parentNode, _str expressionName, _str expression, _str macroName, _str testCases)
{
   // We  need to find the current highest priority value for all the existing child nodes
   
   int xHandle = getConfigHandle();
   if(xHandle < 0)
      return -1;
   int nextPriority = getNextExpressionPriorityValue(parentNode);

   // Create a new XML node under the parent node for the expression
   int expNode = _xmlcfg_add(xHandle, parentNode, 'Expression', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   if (expNode > 0)
   {
      _xmlcfg_add_attribute(xHandle, expNode, 'Name', expressionName);
      _xmlcfg_add_attribute(xHandle, expNode, 'OldName', '');
      _xmlcfg_add_attribute(xHandle, expNode, 'Priority', nextPriority);
      _xmlcfg_add_attribute(xHandle, expNode, 'Enabled', '1');
      int expText = _xmlcfg_add(xHandle, expNode, 'RE', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      if (expText > 0)
      {
         int expTextCDATA = _xmlcfg_add(xHandle, expText, '', VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
         if (expTextCDATA > 0)
         {
            _xmlcfg_set_value(xHandle, expTextCDATA, expression);
         }
      }

      if (testCases != null && length(testCases) > 0)
      {
         int matchText = _xmlcfg_add(xHandle, expNode, 'Matches', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         if (matchText > 0)
         {
            int matchTextCDATA = _xmlcfg_add(xHandle, matchText, '', VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            if (matchTextCDATA > 0)
            {
               _xmlcfg_set_value(xHandle, matchTextCDATA, testCases);
            }
         }
      }
   }
   return expNode;
}

static int getNextExpressionPriorityValue(int categoryNode)
{
   // Walk the list of child nodes (Expressions) underneath
   // a particular category (tool). We're looking for the highest
   // Priority attribute value so we know what the next usable value is
   // when inserting a new Expression node
   int priority = 0;
   int xml_handle = getConfigHandle();
   if(xml_handle < 0)
      return -1;

   _str expXpath = 'Expression[@Priority="' :+ (priority) :+ '"]';
   int expIdx = _xmlcfg_find_simple(xml_handle, expXpath, categoryNode);
   while (expIdx > -1)
   {
      expXpath = 'Expression[@Priority="' :+ (++priority) :+ '"]';
      expIdx = _xmlcfg_find_simple(xml_handle, expXpath, categoryNode);
   }
   return priority;
}

static int getNextCategoryPriorityValue()
{
   // Walk the list of categories (Tools). We're looking for the highest
   // Priority attribute value so we know what the next usable value is
   // when inserting a new Tool/Category node
   int priority = 0;
   int xml_handle = getConfigHandle();
   if(xml_handle < 0)
      return -1;

   _str expXpath = '//Tool[@Priority="' :+ (priority) :+ '"]';
   int expIdx = _xmlcfg_find_simple(xml_handle, expXpath);
   while (expIdx > -1)
   {
      expXpath = '//Tool[@Priority="' :+ (++priority) :+ '"]';
      expIdx = _xmlcfg_find_simple(xml_handle, expXpath);
   }
   return priority;
}

// Just determines if the category already exists. This way we don't create
// duplicates
static boolean categoryAlreadyExists(_str categoryName)
{
   int xml_handle = getConfigHandle();
   if(xml_handle < 0)
      return true;

   _str expXpath = '//Tool[@Name="' :+ (categoryName) :+ '"]';
   //say('Looking for: 'expXpath);
   int expIdx = _xmlcfg_find_simple(xml_handle, expXpath);
   if(expIdx > 0)
      return true;
   return false;
}

static void addNewCategory(_str categoryName)
{
   // Get a new priority value for this category
   int newCatPriority = getNextCategoryPriorityValue();
   // Now we can create it
   // And add the new category to the XML configuration
   int xml_handle = getConfigHandle();
   int docRootNode = _xmlcfg_get_first_child(xml_handle, 0);
   int newCategoryNode = _xmlcfg_add(xml_handle, docRootNode, "Tool", VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(xml_handle, newCategoryNode, "Name", categoryName);
   _xmlcfg_add_attribute(xml_handle, newCategoryNode, "Priority", newCatPriority);
}


// The big TODO: Listing
// * User Interface
// 2 - use the PIC API for displaying the "found" groups? when the user
//    selects the "validate" button
// 
/// 
// * Search_Error
// 1 - Implement a new method, and assign it (for testing only) in init_error (_error_search)
// 2 - Have this method return the index of the expression that was found? Easier to pass to parse_error
// * Parse_error
// 1 - Pretty much works as before, but doesn't rely on 
// 

// Behavior
// Look at clark's modifications to error.e (creating the array/list of expressions)
// If there's a project, look in the project's definitions
// A project will use the defined categories/tool names
// If no project, use the "extension-specific" groups, if any
// Otherwise, use the default array/list
// Make this an array of structures
