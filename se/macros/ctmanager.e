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
#include "codetemplate.sh"
#include "dirlist.sh"
#import "ctcategory.e"
#import "ctitem.e"
#import "ctmanager.e"
#import "ctviews.e"
#import "codetemplate.e"
#import "dirlist.e"
#import "fileman.e"
#import "main.e"
#import "picture.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "sc/util/Rect.e"
#import "help.e"
#endregion


_command void template_manager() name_info(","VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveCodeTemplates()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Merge");
      return;
   }
   show("-mdi _ctTemplateManager_form");
}

static void _ctTemplateManagerContextMenu(_str menuNameOrIndex, int x=-1, int y=-1)
{
   index := 0;
   if( isinteger(menuNameOrIndex) ) {
      index=(int)menuNameOrIndex;
   } else {
      index=find_index(menuNameOrIndex,oi2type(OI_MENU));
   }
   if( index==0 ) {
      return;
   }
   int handle = p_active_form._menu_load(index,'p');
   if( handle<0) {
      msg :=  "Unable to load menu \"":+menuNameOrIndex:+"\"";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   if( x==y && x==-1 ) {
      x=VSDEFAULT_INITIAL_MENU_OFFSET_X; y=VSDEFAULT_INITIAL_MENU_OFFSET_Y;
      x=mou_last_x('m')-x; y=mou_last_y('m')-y;
      _lxy2dxy(p_scale_mode,x,y);
      _map_xy(p_window_id,0,x,y,SM_PIXEL);
   }
   // Show the menu
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status=_menu_show(handle,flags,x,y);
   _menu_destroy(handle);
}

static const CTM_DETAILS_TAB= 0;
static const CTM_FILES_TAB=   1;
static const CTM_CUSTOM_PARAMETERS_TAB= 2;

defeventtab _ctTemplateManager_form;

static int findCategoryTree(int wid=0)
{
   if( wid==0 || wid.p_object!=OI_TREE_VIEW ) {
      int formWid = _find_formobj("_ctTemplateManager_form",'n');
      if( formWid!=0 ) {
         wid = formWid._find_control("ctl_category");
      }
   }
   return wid;
}

static int findCategoryTreeOrDie(int wid=0)
{
   wid=findCategoryTree(wid);
   if( wid==0 ) {
      msg := "Unable to locate Categories tree.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }
   return wid;
}

static int findItemList(int wid=0)
{
   if( wid==0 || wid.p_object!=OI_TREE_VIEW ) {
      int formWid = _find_formobj("_ctTemplateManager_form",'n');
      if( formWid!=0 ) {
         wid = formWid._find_control("ctl_item");
      }
   }
   return wid;
}

static int findItemListOrDie(int wid=0)
{
   wid=findItemList(wid);
   if( wid==0 ) {
      msg := "Unable to locate Templates list.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }
   return wid;
}

/**
 * Verify and retrieve user input on dialog.
 * 
 * @param templateFilename (output). Template filename of current template item.
 * @param templateDetails  (output). ctTemplateDetails_t object. Details tab.
 * @param templateContent  (output). ctTemplateContent_t object. Files, Custom Parameters tabs.
 * @param quiet (optional). Set to true to not display error messages.
 *              Defaults to false.
 * @param selectError   (optional). Set to false if you do not want the location
 *                      of the error made active.
 *                      Defaults to true.
 * @param statusMessage (optional). Set to description of error (if any).
 * 
 * @return true if all user input verified successfully.
 */
static bool verifyFormInput(_str& templateFilename,
                               ctTemplateDetails_t& templateDetails,
                               ctTemplateContent_t& templateContent,
                               bool quiet=false, bool selectError=true,
                               _str& statusMessage=null)
{
   _control ctl_template_sstab;
   _control ctl_details_view, ctl_files_view, ctl_params_view;

   // Details
   if( !ctl_details_view._ctDetailsViewVerifyInput(quiet,selectError,statusMessage) ) {
      if( selectError ) {
         ctl_template_sstab.p_ActiveTab=CTM_DETAILS_TAB;
      }
      return false;
   }

   // Files
   if( !ctl_files_view._ctFilesViewVerifyInput() ) {
      if( selectError ) {
         ctl_template_sstab.p_ActiveTab=CTM_FILES_TAB;
      }
      return false;
   }

   // Parameters
   if( !ctl_params_view._ctParametersViewVerifyInput() ) {
      if( selectError ) {
         ctl_template_sstab.p_ActiveTab=CTM_CUSTOM_PARAMETERS_TAB;
      }
      return false;
   }

   ctTemplateDetails_t details = _ctViewDetails();
   ctTemplateContent_t content = _ctViewContent();

   // last.template is the template filename that Details, Files, Parameters
   // is currently populated from. We cannot retrieve the template filename
   // from ctl_item tree since the user might be in the middle of switching
   // items, in which case the template filename would be for the wrong
   // template.
   templateFilename=_GetDialogInfoHt("last.template");
   templateDetails=details;
   templateContent=content;

   // All good
   return true;
}

/**
 * Save category and item history for the active form.
 */
static void saveRetrieveHistory()
{
   widCategory := p_active_form._find_control("ctl_category");
   if( widCategory==0 ) {
      // ??
      return;
   }
   _str path = widCategory._ctCategoryGetCategoryPath();
   if( path!="" ) {
      name := "";
      widItem := p_active_form._find_control("ctl_item");
      if( widItem>0 ) {
         _str unused;
         widItem._ctItemListGetCurrentItem(unused,name);
      }
      // Save/restore last template by global history
      info :=  path'|'name;
      _append_retrieve(0,info,"_ctTemplateManager_form.LastItemTemplate");
   }
}

/**
 * Restore category and item history.
 */
static void restoreRetrieveHistory()
{
   path := name := "";

   // Save/restore last template by global history
   _str info =_retrieve_value("_ctTemplateManager_form.LastItemTemplate");
   parse info with path'|'name;
   // Restore category
   if( path!="" ) {
      widCategory := p_active_form._find_control("ctl_category");
      if( widCategory==0 ) {
         // ??
         return;
      }
      old_inOnChange := widCategory._dlInOnChange(1);
      if( widCategory._ctCategorySetCategoryPath(path) ) {
         // Restore item
         if( name!="" ) {
            widItem := p_active_form._find_control("ctl_item");
            if( widItem==0 ) {
               // ??
               return;
            }
            widItem._ctItemListSetCurrentItem(name);
         }
      }
      widCategory._dlInOnChange((int)old_inOnChange);
   }
}

/**
 * Set template filename textbox.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tab control.
 * 
 * @param templateFilename Absolute filename of template selected.
 */
static void setTemplateFilename(_str templateFilename)
{
   was_ReadOnly := p_ReadOnly;
   p_ReadOnly=false;
   // Shrink to fit into width of textbox
   p_text=_ShrinkFilename(templateFilename,p_width);
   p_ReadOnly=was_ReadOnly;
}

/**
 * Compare details1 and details2 ctTemplateDetails_t objects.
 * Whitespace is not significant when performing equality
 * tests (e.g. "" == "   ").
 * 
 * @param details1
 * @param details2
 * 
 * @return true if members of details1 are (effectively) equal to members of details2.
 */
static bool detailsEqual(ctTemplateDetails_t& details1, ctTemplateDetails_t& details2)
{
   if( details1.Name != details2.Name ) {
      return false;
   }
   if( details1.Description != details2.Description ) {
      return false;
   }
   if( details1.SortOrder!= details2.SortOrder) {
      return false;
   }
   if( details1.DefaultName != details2.DefaultName ) {
      return false;
   }
   // All members are equal
   return true;
}

/**
 * Compare content1 and content2 ctTemplateContent_t objects.
 * Whitespace is not significant when performing equality
 * tests (e.g. "" == "   ").
 * 
 * @param content1
 * @param content2
 * 
 * @return true if members of content1 are (effectively) equal to members of content2.
 */
static bool contentEqual(ctTemplateContent_t& content1, ctTemplateContent_t& content2)
{
   Delimiter1 := strip(content1.Delimiter);
   Delimiter2 := strip(content2.Delimiter);
   Delimiter1 = Delimiter1=="" ? CTPARAMETER_DELIM : Delimiter1;
   Delimiter2 = Delimiter2=="" ? CTPARAMETER_DELIM : Delimiter2;
   if( Delimiter1 != Delimiter2 ) {
      return false;
   }
   if( content1.Files != content2.Files ) {
      return false;
   }
   // Note that hash table equality tests are pretty smart
   if( content1.Parameters != content2.Parameters ) {
      return false;
   }
   // All members are equal
   return true;
}

/**
 * Check to see if data for last template has changed or is invalid.
 * <p>
 * Operates on the active form.
 * 
 * @param needToSave (output). Set to true when there are no errors
 *                   and template data has changed which requires it
 *                   to be saved to its template file.
 * @param templateFilename (optional). Pointer to string to receive template
 *                         filename from form.
 * @param templateDetails  (optional). Pointer to ctTemplateDetails_t object to
 *                         receive template details from form input.
 * @param templateContent  (optional). Pointer to ctTemplateContent_t object to
 *                         receive template content from form input.
 * 
 * @return true if no errors.
 */
static bool checkForUnsavedFormInput(bool& needToSave,
                                        _str* templateFilename=null,
                                        ctTemplateDetails_t* templateDetails=null,
                                        ctTemplateContent_t* templateContent=null,
                                        bool quiet=false, bool selectError=true,
                                        _str& statusMessage=null)
{
   needToSave=false;

   sstabWid := p_active_form._find_control("ctl_template_sstab");
   categoryWid := p_active_form._find_control("ctl_category");
   itemWid := p_active_form._find_control("ctl_item");

   if( !itemWid._ctItemListGetCurrentItem() ) {
      // There is no current item (probably initializing or no items in current category)
      return true;
   }

   // Last template selected
   _str origTemplateFilename = _GetDialogInfoHt("last.template");
   if( origTemplateFilename==null || origTemplateFilename=="" ) {
      // Initializing
      // or switching from an empty category (no template)
      // or do not want to check for unsaved input (e.g. just deleted the last template).
      return true;
   }

   // Validate user input
   lastTemplateFilename := "";
   ctTemplateDetails_t lastDetails;
   ctTemplateContent_t lastContent;
   if( !p_active_form.verifyFormInput(lastTemplateFilename,lastDetails,lastContent,quiet,selectError,statusMessage) ) {
      // Input validation error
      return false;
   }

   // Do not bother checking if anything changed if the current item is
   // a system template (which the user cannot edit).
   if( !_ctIsSysItemTemplatePath(origTemplateFilename) ) {

      // Check if anything changed
      ctTemplateDetails_t origDetails = (ctTemplateDetails_t)_GetDialogInfoHt("last.details");
      ctTemplateContent_t origContent = (ctTemplateContent_t)_GetDialogInfoHt("last.content");
      if( !detailsEqual(lastDetails,origDetails) || !contentEqual(lastContent,origContent) ) {
         needToSave=true;
      }
   }

   if( templateFilename ) {
      *templateFilename = lastTemplateFilename;
   }
   if( templateDetails ) {
      *templateDetails = lastDetails;
   }
   if( templateContent ) {
      *templateContent = lastContent;
   }

   // All good
   return true;
}

static bool saveTemplate(_str templateFilename,
                            ctTemplateDetails_t& details, ctTemplateContent_t& content,
                            bool quiet=false, _str& msg=null)
{
   int status = _ctTemplatePutTemplate(templateFilename,details,content);
   if( status!=0 ) {
      // Error
      if( !quiet ) {
         msg="Unable to save template item. ":+get_message(status):+"\n\n":+
             _GetDialogInfoHt("last.item");
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return false;
   }

   // Inform dialog that data has been saved
   _SetDialogInfoHt("last.details",details);
   _SetDialogInfoHt("last.content",content);

   // All good
   return true;
}

/**
 * Save data for last template if modified.
 *
 * @param quiet Set to true if you want form input saved only if there are no errors.
 *              Errors will not be reported to the user.
 *              Defaults to false.
 * 
 * @return true if no errors.
 */
static bool maybeSaveFormInput(bool quiet=false)
{
   needToSave := false;
   templateFilename := "";
   ctTemplateDetails_t details; details._makeempty();
   ctTemplateContent_t content; content._makeempty();
   if( !checkForUnsavedFormInput(needToSave,&templateFilename,&details,&content,quiet,!quiet) ) {
      // Error
      return false;
   }
   if( needToSave ) {
      return ( saveTemplate(templateFilename,details,content) );
   }
   // All good
   return true;
}

static void maybeReloadCurrentItem(bool postCall=false)
{
   // Check to make sure the current template was not modified outside
   // of the Template Manager dialog (e.g. user edited .setemplate file
   // in editor.
   _str templateFilename = _GetDialogInfoHt("last.template");
   if( templateFilename!=null && templateFilename!="" ) {
      _str curFileDate = _file_date(templateFilename,'b');
      _str lastFileDate = _GetDialogInfoHt("last.template_file_date");
      if( lastFileDate!=null && curFileDate!=null && lastFileDate < curFileDate ) {
         // Clear last.template so that current template item is not saved
         // and will get reloaded from disk.
         _SetDialogInfoHt("last.template",null);
         if( postCall ) {
            _post_call(find_index("ctTemplateManagerItemListRefresh",COMMAND_TYPE|PROC_TYPE));
         } else {
            ctTemplateManagerItemListRefresh();
         }
      }
   }
}

void _ctTemplateManager_form.on_got_focus()
{
   // Only interested when the form gets focus. Controls get on_got_focus
   // events after the form.
   if( p_window_id == p_active_form ) {
      maybeReloadCurrentItem(true);
   }
   // Call the root event handler in case there is some default handling that
   // needs to happen (e.g. select text in a text box).
   call_event(defeventtab _ainh_dlg_manager,ON_GOT_FOCUS,'e');
}

// This will catch all on_lost_focus events for the form, even
// those fired when switching from one control to another.
void _ctTemplateManager_form.on_lost_focus()
{
   ctTemplateDetails_t old_details = _ctViewDetails();
   ctTemplateContent_t old_content = _ctViewContent();
   if( maybeSaveFormInput(true) ) {
      // Refresh the template list if the name or sortorder changed.
      // Pass true to post the call to refresh, since we really do not want to be messing
      // around with the active window inside an on_lost_focus event.
      maybeRefreshItemList(old_details,old_content,true);
   }
   // Call the root event handler in case there is some default handling that
   // needs to happen (e.g. deselect text in a text box).
   call_event(defeventtab _ainh_dlg_manager,ON_LOST_FOCUS,'e');
}

void ctl_close.on_create(_str sysTemplatesPath="", _str userTemplatesPath="")
{
   _ctTemplateManager_form_initial_alignment();

   // Use dialog info to know when a template has changed and needs to
   // be verified and saved.

   // Last selected template filename
   _SetDialogInfoHt("last.template",null);
   // Last selected template file date
   _SetDialogInfoHt("last.template_file_date",null);
   // Last selected category
   _SetDialogInfoHt("last.category",null);
   // Last selected item
   _SetDialogInfoHt("last.item",null);
   // Last selected template details data
   _SetDialogInfoHt("last.details",null);
   // Last selected template content data
   _SetDialogInfoHt("last.content",null);

   _SetDialogInfoHt("inOnLostFocus",false);

   ctl_category._ctCategoryInit(sysTemplatesPath,userTemplatesPath);
   // Once to restore the category...
   restoreRetrieveHistory();
   // Inform the category list that the current category has changed
   ctl_category._ctCategoryOnChangeSelected();
   // ...and again to restore the item now that the item list has been filled in.
   // Note:
   // This is a little inefficient because the category is restored twice.
   restoreRetrieveHistory();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _ctTemplateManager_form_initial_alignment()
{
   ctl_file_edit.p_auto_size = false;
   ctl_file_edit.p_width = ctl_file_add.p_width;
   ctl_file_edit.p_height = ctl_file_add.p_height;

   ctl_param_edit.p_auto_size = false;
   ctl_param_edit.p_width = ctl_param_add.p_width;
   ctl_param_edit.p_height = ctl_param_add.p_height;

   //rightAlign := ctl_template_sstab.p_child.p_width - (int)(ctl_details_view.p_y * 1.5);
   rightAlign := ctl_template_sstab.p_child.p_width - (ctl_details_view.p_y + ctl_details_view.p_y intdiv 2);
   alignUpDownListButtons(ctl_files.p_window_id, 
                          rightAlign, 
                          ctl_file_add.p_window_id,
                          ctl_file_edit.p_window_id, 
                          ctl_file_up.p_window_id,
                          ctl_file_down.p_window_id, 
                          ctl_file_remove.p_window_id);

   ctl_param_add.resizeToolButton(ctl_files.p_height intdiv 5);
   ctl_param_edit.resizeToolButton(ctl_files.p_height intdiv 5);
   ctl_param_remove.resizeToolButton(ctl_files.p_height intdiv 5);
   alignUpDownListButtons(ctl_params.p_window_id, 
                          rightAlign, 
                          ctl_param_add.p_window_id,
                          ctl_param_edit.p_window_id, 
                          ctl_param_remove.p_window_id);
}

void ctl_close.lbutton_up()
{
   needToSave := false;
   templateFilename := "";
   ctTemplateDetails_t details; details._makeempty();
   ctTemplateContent_t content; content._makeempty();
   msg := "";
   if( !checkForUnsavedFormInput(needToSave,&templateFilename,&details,&content,true,true,msg) ) {
      msg=msg:+"\n\n":+
          "Close anyway (changes will not be saved)?";
      int status = _message_box(msg,"",MB_YESNO|MB_ICONEXCLAMATION,IDNO);
      if( status!=IDYES ) {
         return;
      }
      needToSave=false;
   }
   //say('ctl_close.lbutton_up: needToSave='needToSave);
   status := 0;
   if( needToSave ) {
      if( !saveTemplate(templateFilename,details,content,true,msg) ) {
         msg=msg:+"\n\n":+
         "Close anyway?";
         int status2 = _message_box(msg,"",MB_YESNO|MB_ICONEXCLAMATION,IDNO);
         if( status2!=IDYES ) {
            return;
         }
         status=ERROR_WRITING_FILE_RC;
      }
   }

   // Save/restore
   saveRetrieveHistory();
   p_active_form._delete_window(status);
}

void ctl_options.lbutton_up()
{
   show("-modal _ctTemplateOptions_form");
}

void ctl_template_sstab.on_create()
{
   _SetDialogInfoHt("inOnChange",false,p_window_id);
}

void ctl_template_sstab.on_change(int reason, int activeTab)
{
   if( _GetDialogInfoHt("inOnChange",p_window_id) ) {
      // No recursion!
      return;
   }
   _SetDialogInfoHt("inOnChange",true,p_window_id);

   switch( reason ) {
   case CHANGE_TABACTIVATED:
      // Any errors will be handled by the call
      maybeSaveFormInput();
      break;
   }

   _SetDialogInfoHt("inOnChange",false,p_window_id);
}


defeventtab _ctTemplateManager_CategoryTree_etab _inherit _ctCategoryTree_etab;

// Override _ctCategoryTree_etab.ON_CREATE so we can initialize the form all
// at once in ctl_close.ON_CREATE.
void _ctTemplateManager_CategoryTree_etab.on_create()
{
}

void _ctTemplateManager_CategoryTree_etab.on_change(int reason, int nodeIndex)
{
   if( _dlInOnChange() ) {
      // Recursion not allowed!
      return;
   }

   old_inOnChange := _dlInOnChange(1);
   switch( reason ) {
   case CHANGE_SELECTED:
      {
         // checkForUnsavedFormInput() might change the active window on us if it
         // found an error (bad user input), so save it now.
         int thisWid;
         get_window_id(thisWid);
         needToSave := false;
         templateFilename := "";
         ctTemplateDetails_t details; details._makeempty();
         ctTemplateContent_t content; content._makeempty();
         if( !checkForUnsavedFormInput(needToSave,&templateFilename,&details,&content) ) {
            // Note:
            // The item list has not been filled in yet, so we can leave
            // it as is, including the currently selected item that has
            // something wrong with it.
            _str lastCategoryPath = _GetDialogInfoHt("last.category");
            thisWid._ctCategorySetCategoryPath(lastCategoryPath);
            break;
         }
         if( needToSave ) {
            if( !saveTemplate(templateFilename,details,content) ) {
               // Note:
               // The item list has not been filled in yet, so we can leave
               // it as is, including the currently selected item that has
               // something wrong with it.
               _str lastCategoryPath = _GetDialogInfoHt("last.category");
               thisWid._ctCategorySetCategoryPath(lastCategoryPath);
               break;
            }
         }
         mou_hour_glass(true);
         _str catPath = _dlBuildSelectedPath();
         _str templatePath = _ctCategoryToTemplatePath(catPath);
         if( templatePath!="" ) {
            // Save and restore the currently selected template (if any)
            templateName := "";
            ctl_item._ctItemListGetCurrentItem(null,templateName);
            ctl_item._ctItemListInit(templatePath);
            ctl_item._ctItemListSetCurrentItem(templateName);
         }
         mou_hour_glass(false);
      }
      break;
   case CHANGE_COLLAPSED:
      call_event(reason,nodeIndex,true,defeventtab _ctCategoryTree_etab,ON_CHANGE,'e');
      break;
   default:
      // Note:
      // last_index('','k') is NOT reliable, so you cannot walk the inheritance
      // chain with eventtab_inherit() to find out the next eventtable in the
      // chain of inheritance.
      call_event(reason,nodeIndex,true,defeventtab _ctCategoryTree_etab,ON_CHANGE,'e');
   }
   _dlInOnChange((int)old_inOnChange);
}

int _OnUpdate_ctTemplateManagerCategoryTreeNewTemplate(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }
   _str templateDir = target_wid._ctCategoryToTemplatePath();
   if( _ctIsSysItemTemplatePath(templateDir) ) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}

_command void ctTemplateManagerCategoryTreeNewTemplate(int categoryWid=0) name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   ctTemplateManagerItemListNew(categoryWid);
}

int _OnUpdate_ctTemplateManagerCategoryTreeNew(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }
   _str templateDir = target_wid._ctCategoryToTemplatePath();
   if( _ctIsSysItemTemplatePath(templateDir) ) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}

_command void ctTemplateManagerCategoryTreeNew(int categoryWid=0) name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   categoryWid=findCategoryTreeOrDie(categoryWid);
   if( categoryWid==0 ) {
      return;
   }
   _str templateDir = categoryWid._ctCategoryToTemplatePath();
   _maybe_append_filesep(templateDir);
   if( _ctIsSysItemTemplatePath(templateDir) ) {
      msg := "Cannot create new categories under installed templates category. Create new categories under user templates category instead.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   if( !maybeSaveFormInput() ) {
      // Error saving current template
      return;
   }

   // Name/path of category.
   // Note:
   // User can provide multiple nested categories (e.g. category1/category2/...)
   // and they will all be created.
   path := "";
   do {

      _str result = show("-modal _textbox_form",
                         "New Category", // Title
                         0,              // Flags
                         "",             // Width
                         "",             // Help
                         "",             // Buttons and captions
                         "",             // Retrieve name
                         "Category name:"path);
      if( result=="" ) {
         // User cancelled
         return;
      }
      result=strip(_param1);
      result=strip(result,'B','"');

      path=result;
      path=translate(path,FILESEP,FILESEP2);

      _maybe_strip_filesep(path);
      // Make sure the user entered a path that is relative to the
      // current category.
      if( path!="" && !_file_eq( substr(absolute(path,templateDir),1,length(templateDir)) , templateDir ) ) {
         _str msg = "Invalid category path. Please provide a relative category path or just a category name.\n\n":+
                    path;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         continue;
      }
      path=relative(path,templateDir,false);
      // Check to see if this category path already exists
      if( isdirectory(templateDir:+path) ) {
         _str msg = "Category directory already exists. Please choose a different name.\n\n":+
                    templateDir:+path;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         continue;
      }

   } while( false );

   int status = make_path(templateDir:+path);
   if( status!=0 ) {
      _str msg = "Error creating category directory. "get_message(status):+"\n\n":+
                 templateDir:+path;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   // Refresh category tree and item list to reflect new template.
   // Note:
   // Refreshing the category tree will result in the item list being refreshed.
   ctTemplateManagerCategoryTreeRefresh(categoryWid,path);
}

int _OnUpdate_ctTemplateManagerCategoryTreeDelete(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }
   _str templateDir = target_wid._ctCategoryToTemplatePath();
   if( !_ctIsSysItemTemplatePath(templateDir) ) {

      return MF_ENABLED;
   }
   return MF_GRAYED;
}

_command void ctTemplateManagerCategoryTreeDelete(int categoryWid=0) name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   categoryWid=findCategoryTreeOrDie(categoryWid);
   if( categoryWid==0 ) {
      return;
   }

   _str catPath = categoryWid._ctCategoryGetCategoryPath();
   if( catPath=="" ) {
      // ???
      return;
   }
   _str templateDir = categoryWid._ctCategoryToTemplatePath(catPath);
   if( _ctIsSysItemTemplatePath(templateDir) ) {
      msg := "Deleting installed categories not allowed.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   folder := substr(catPath,lastpos('/',catPath)+1);
   _str msg = nls("Are you sure you want to permanently remove the folder %s and all of its contents?",folder);
   int status = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
   if( status!=IDYES ) {
      return;
   }

   _maybe_append_filesep(templateDir);
   // Sanity
   if( isdrive(substr(templateDir,1,length(templateDir)-1)) ) {
      msg=nls("The folder %s evaluates to the root of drive %s. ",folder,substr(templateDir,1,2)):+
              "Recursive delete on a drive not allowed.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   _str cwd = getcwd(); _maybe_append_filesep(cwd);
   if( _file_eq(substr(cwd,1,length(templateDir)),templateDir) ) {
      // Cannot delete the directory if we are in it
      new_cwd := strip(templateDir,'T',FILESEP);
      new_cwd=substr(new_cwd,1,pathlen(new_cwd)-1);
      chdir(new_cwd,1);
   }

   // Make sure the user does not delete the templates/ItemTemplates directory itself
   _str userItemTemplatesRoot = _ctGetUserItemTemplatesDir();
   _maybe_append_filesep(userItemTemplatesRoot);
   isRootDir := _file_eq(templateDir,userItemTemplatesRoot);
   status=_DelTree(templateDir,!isRootDir);
   if( status!=0 ) {
      msg="Could not completely remove folder. "get_message(status):+"\n\n":+
          templateDir;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }

   _str lastTemplateFilename = _GetDialogInfoHt("last.template");
   if( lastTemplateFilename!="" && _file_eq(substr(lastTemplateFilename,1,length(templateDir)),templateDir) ) {
      // Clear last item so that we do not try to save the template we just deleted
      _SetDialogInfoHt("last.template",null);
   }

   // Refresh category tree and item list to reflect new template.
   // Note:
   // Refreshing the category tree will result in the item list being refreshed.
   _str path = (status!=0 || isRootDir) ? "" : "..";
   ctTemplateManagerCategoryTreeRefresh(categoryWid,path,isRootDir);
}

/**
 * Refresh the current category and its children (if node is expanded).
 * 
 * @param categoryWid (optional). Window id of category tree.
 *                    If set to 0, then we look up the category tree wid.
 *                    Defaults to 0.
 * @param subPath (optional). Relative category path under the current node to
 *                set as current after the refresh.
 *                Defaults to "".
 */
_command void ctTemplateManagerCategoryTreeRefresh(int categoryWid=0, _str subPath="", ...) name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   categoryWid=findCategoryTreeOrDie(categoryWid);
   if( categoryWid==0 ) {
      return;
   }
   _str categoryPath = categoryWid._ctCategoryToTemplatePath();
   if( categoryPath!="" ) {
      old_inOnChange := categoryWid._dlInOnChange(1);
      categoryWid._ctCategorySetCategoryPath(categoryPath);
      categoryWid._dlInOnChange((int)old_inOnChange);
      index := categoryWid._TreeCurIndex();
      if( index>0 ) {
         _str path = translate(subPath,FILESEP,FILESEP2);
         while( path!="" && index>0 ) {
            _str cat;
            parse path with cat (FILESEP) path;
            categoryWid._TreeSetInfo(index,1);
            categoryWid.call_event(CHANGE_EXPANDED,index,categoryWid,ON_CHANGE,'w');
            int found_index;
            if( cat=="." ) {
               // Nothing to do
               found_index=index;
            } else if( cat==".." ) {
               // Parent
               found_index=categoryWid._TreeGetParentIndex(index);
            } else {
               found_index=categoryWid._TreeSearch(index,cat);
            }
            if( found_index<=0 ) {
               break;
            }
            index=found_index;
            categoryWid._TreeSetCurIndex(index);
         }
         int ShowChildren;
         categoryWid._TreeGetInfo(index,ShowChildren);
         if( ShowChildren==-1 && categoryWid._TreeGetParentIndex(index) == 0 ) {
            // Special case of top-level node being refreshed. We always
            // want to try to expand it if it is a leaf. Otherwise it will
            // never be able to be expanded (e.g. user deletes everything
            // under root "User Templates" category, then copy stuff back
            // in and hit refresh).
            ShowChildren=1;
         }
         if( ShowChildren==1 ) {
            // Node was expanded, so we must refresh in case sub-categories were added
            categoryWid.call_event(CHANGE_EXPANDED,index,categoryWid,ON_CHANGE,'w');
         }
         // Informing the category tree of a change will also refresh the item list
         categoryWid.call_event(CHANGE_SELECTED,index,categoryWid,ON_CHANGE,'w');
      }
   }
}

void _ctTemplateManager_CategoryTree_etab.'DEL'()
{
   _control ctl_category;
   ctTemplateManagerCategoryTreeDelete(ctl_category);
}

void _ctTemplateManager_CategoryTree_etab.rbutton_up(int x=-1, int y=-1)
{
   _ctTemplateManagerContextMenu("_ctTemplateManager_CategoryTree_menu",x,y);
}

void _ctTemplateManager_CategoryTree_etab.context()
{
   x := y := 0;
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _ctTemplateManager_CategoryTree_etab.call_event(x,y,defeventtab _ctTemplateManager_CategoryTree_etab,RBUTTON_UP,'e');
}


//
// _ctTemplateManager_ItemList_etab
//

defeventtab _ctTemplateManager_ItemList_etab _inherit _ctItemList_etab;

// Override _ctItemList_etab.ON_CREATE so we can initialize the form all
// at once in ctl_add.ON_CREATE.
// Note:
// We also have to override the ON_CREATE event so that inherited _ctItemList_etab.ON_CREATE
// does not get called and clear the list (default action) out from under us.
void _ctTemplateManager_ItemList_etab.on_create()
{
}

/**
 * Populate item information in dialog for selected item.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 * <p>
 * IMPORTANT: <br>
 * This function will throw away any current view data and replace it with
 * view data for the selected item. Call checkForUnsavedFormInput to determine
 * if current view data needs to be saved.
 * 
 * @see checkForUnsavedFormInput
 */
static void onSelectItem()
{
   ctTemplateDetails_t details = null;
   ctTemplateContent_t content = null;
   // Note:
   // _ctItemListGetCurrentItem() will fail when the tree is cleared (e.g. each time a new category
   // is chosen). We just blow it off in that case.
   templateFilename := "";
   itemName := "";
   if( _ctItemListGetCurrentItem(templateFilename,itemName) ) {

      do {

         int status = _ctTemplateGetTemplate(templateFilename,&details,&content);
         if( status!=0 ) {
            msg :=  "Error retrieving template data for \"":+templateFilename:+"\". ":+get_message(status);
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            break;
         }

      } while( false );
   }

   templateFilenameWid := p_active_form._find_control("ctl_template_filename");
   sstabWid := p_active_form._find_control("ctl_template_sstab");
   detailsViewWid := p_active_form._find_control("ctl_details_view");
   filesViewWid := p_active_form._find_control("ctl_files_view");
   paramsViewWid := p_active_form._find_control("ctl_params_view");
   categoryWid := p_active_form._find_control("ctl_category");
   itemWid := p_window_id;

   _SetDialogInfoHt("last.template",templateFilename);
   _SetDialogInfoHt("last.template_file_date",_file_date(templateFilename,'b'));
   _str categoryPath = categoryWid._ctCategoryGetCategoryPath();
   _SetDialogInfoHt("last.category",categoryPath);
   _SetDialogInfoHt("last.item",itemName);
   _SetDialogInfoHt("last.details",details);
   _SetDialogInfoHt("last.content",content);

   templateFilenameWid.setTemplateFilename(templateFilename);
   detailsViewWid._ctDetailsViewInit(templateFilename,details);
   filesViewWid._ctFilesViewInit(templateFilename,details,content);
   paramsViewWid._ctParametersViewInit(templateFilename,details,content);

   // Enable/disable views based on whether there is a current item
   enable := ( templateFilename != "" );
   detailsViewWid._ctDetailsViewEnable(enable);
   filesViewWid._ctFilesViewEnable(enable);
   paramsViewWid._ctParametersViewEnable(enable);

   // Do not bother making controls read-only if they are already disabled
   if( enable ) {
      // Set/unset views read-only based on whether the current item is a system template
      readOnly := _ctIsSysItemTemplatePath(templateFilename);
      detailsViewWid._ctDetailsViewReadOnly(readOnly);
      filesViewWid._ctFilesViewReadOnly(readOnly);
      paramsViewWid._ctParametersViewReadOnly(readOnly);
   }
}

void _ctTemplateManager_ItemList_etab.on_change(int reason, int nodeIndex)
{
   if( _ctItemListInOnChange() ) {
      // Recursion not allowed!
      return;
   }
   old_inOnChange := _ctItemListInOnChange(1);
   switch( reason ) {
   case CHANGE_SELECTED:
      {
         // checkForUnsavedFormInput() might change the active window on us if it
         // found an error (bad user input), so save it now.
         int thisWid;
         get_window_id(thisWid);
         needToSave := false;
         templateFilename := "";
         ctTemplateDetails_t details; details._makeempty();
         ctTemplateContent_t content; content._makeempty();
         if( !checkForUnsavedFormInput(needToSave,&templateFilename,&details,&content) ) {
            // Note:
            // The ON_CHANGE for the category tree does its own call to checkForUnsavedFormInput(),
            // so we do not have to worry about restoring the category tree ourselves.
            _str lastItem = _GetDialogInfoHt("last.item");
            thisWid._ctItemListSetCurrentItem(lastItem);
            break;
         }
         //say('_ctTemplateManager_ItemList_etab.on_change: needToSave='needToSave);
         if( needToSave ) {
            if( !saveTemplate(templateFilename,details,content) ) {
               // Note:
               // The ON_CHANGE for the category tree does its own call to checkForUnsavedFormInput(),
               // so we do not have to worry about restoring the category tree ourselves.
               _str lastItem = _GetDialogInfoHt("last.item");
               thisWid._ctItemListSetCurrentItem(lastItem);
               break;
            }
         }
         thisWid.onSelectItem();
      }
      break;
   case CHANGE_COLLAPSED:
      break;
   case CHANGE_EXPANDED:
      break;
   case CHANGE_LEAF_ENTER:
      break;
   }
   _ctItemListInOnChange((int)old_inOnChange);
}

/**
 * Return category path pointed to by (mx,my) coordinates.
 * 
 * @param categoryWid  Window id of category tree.
 * @param mx           Mouse x coordinate.
 * @param my           Mouse y coordinate.
 * @param categoryPath (output). Category tree path pointed to.
 * @param fsPath       (output). File-system path that maps to category tree path.
 * @param refreshList  Set to true to call category tree's ON_CHANGE with
 *                     CHANGE_SELECTED reason.
 * 
 * @return true if successful and categoryPath is set to category
 * tree path, fsPath is set to file-system path that maps to category path.
 */
static bool pointToCategory(int categoryWid, int mx, int my, _str& categoryPath, _str& fsPath, bool refreshList)
{
   catPath := "";
   int index = categoryWid._TreeGetIndexFromPoint(mx,my,'p');
   if (index>=0) {
      // Do not allow selecting a category to refresh the Templates list
      // until we are done.
      old_inOnChange := categoryWid._dlInOnChange(1);
      categoryWid._TreeSetCurIndex(index);
      categoryPath=categoryWid._dlBuildSelectedPath();
      categoryWid._dlInOnChange((int)old_inOnChange);
      fsPath=categoryWid._ctCategoryToTemplatePath(categoryPath);
      if( refreshList ) {
         categoryWid.call_event(CHANGE_SELECTED,index,categoryWid,ON_CHANGE,'w');
      }
      return true;
   }
   return false;
}

static void dragdropFromItemListContextMenu(_str categoryDir, _str srcTemplateFilename, int x=-1, int y=-1)
{
   // Create a temporary menu resource and build the menu items on-the-fly
   menuName := "_temp_TemplateManagerDragDrop_menu";
   int index = find_index(menuName,oi2type(OI_MENU));
   if( index ) {
      delete_name(index);
   }
   index=insert_name(menuName,oi2type(OI_MENU));
   _menu_insert(index,-1,0,"Copy Here","ctTemplateManagerItemListCopy ":+categoryDir);
   _menu_insert(index,-1,0,"Move Here","ctTemplateManagerItemListMove ":+categoryDir);
   _menu_insert(index,-1,0,"-");
   _menu_insert(index,-1,0,"Cancel","nothing");

   // Show the menu
   _ctTemplateManagerContextMenu(index);

   // Delete temporary menu resource
   delete_name(index);

   // The menu returns immediately before executing the menu item command, so do not refresh
   // until after the menu item command has had a chance to execute.
   _post_call(ctTemplateManagerItemListRefresh);
}

static int MIN_CX() {
   return  ( 40 intdiv _twips_per_pixel_x() );
}
static int MIN_CY() {
   return ( 40 intdiv _twips_per_pixel_y() );
}
void _ctTemplateManager_ItemList_etab.lbutton_down(bool rbuttonDown=false)
{
   // Call _ctItemList_etab.LBUTTON_DOWN in order to get tree node selected
   call_event(defeventtab _ctItemList_etab,LBUTTON_DOWN,'e');

   srcTemplateFilename := "";
   if( !_ctItemListGetCurrentItem(srcTemplateFilename) ) {
      // ???
      return;
   }
   //if( !rbuttonDown && _ctIsSysItemTemplatePath(srcTemplateFilename) ) {
   //   // Moving system templates not allowed
   //   return;
   //}

   int itemWid;
   get_window_id(itemWid);

   // Original category so we can restore it after done with drag-drop operation
   _control ctl_category;
   _str origCategoryPath = ctl_category._ctCategoryGetCategoryPath();

   // Rectangle for Categories window in pixels, relative to desktop
   sc.util.Rect r = sc.util.Rect.mapFromWid(ctl_category);

   mou_mode(1);
   mou_capture();
   _KillToolButtonTimer();
   int old_mouse_pointer=p_mouse_pointer;
   done := false;
   event := "";
   notEnoughDrag := true;
   // Original lbutton_down mouse coordinates relative to screen in pixels
   int orig_x, orig_y;
   mou_get_xy(orig_x,orig_y);
   // Mouse coordinates relative to Categories window in pixels
   int mx = ctl_category.mou_last_x();
   int my = ctl_category.mou_last_y();
   while( !done ) {
      event=get_event();
      switch( event ) {
      case MOUSE_MOVE:
         {
            int mp = MP_NODROP;
            int x, y;
            mou_get_xy(x,y);
            if( notEnoughDrag ) {
               if( (x-orig_x) > MIN_CX() ) {
                  notEnoughDrag=false;
               }
               if( (y-orig_y) > MIN_CY() ) {
                  notEnoughDrag=false;
               }
            }
            if( notEnoughDrag ) {
               // The mouse has not moved enough to justify starting a drag-drop operation
               break;
            }
            inside := r.contains(x, y);
            if( inside ) {
               mx=ctl_category.mou_last_x();
               my=ctl_category.mou_last_y();
               catPath := templatePath := "";
               if( pointToCategory(ctl_category,mx,my,catPath,templatePath,false) &&
                   templatePath!="" ) {

                  if( _ctIsUserItemTemplatePath(templatePath) ) {
                     mp=MP_ALLOWDROP;
                  }
               }
            }
            if( p_mouse_pointer != mp ) {
               p_mouse_pointer=mp;
            }
         }
         break;
      case RBUTTON_UP:
      case LBUTTON_UP:
      case ESC:
         done=true;
         break;
      }
   }
   mou_mode(0);
   mou_release();
   p_mouse_pointer=old_mouse_pointer;

   if( event==ESC ) {
      // User cancelled
      return;
   }
   if( notEnoughDrag ) {
      // User did not move the mouse enough to start a drag-drop operation,
      // so just do whatever the last event would have done by passing it
      // down the inheritance chain.
      if( rbuttonDown && event==RBUTTON_UP ) {
         activate_window(itemWid);
         itemWid.call_event(itemWid,RBUTTON_UP,'w');
      } else if( event==LBUTTON_UP ) {
         activate_window(itemWid);
         itemWid.call_event(itemWid,LBUTTON_UP,'w');
      }
      return;
   }
   catPath := dstPath := "";
   bstatus := pointToCategory(ctl_category,mx,my,catPath,dstPath,false);

   // Restore originally selected category
   ctl_category._ctCategorySetCategoryPath(origCategoryPath,false);

   if( !bstatus || dstPath=="" ) {
      // User did not point to a category
      return;
   }

   if( _ctIsSysItemTemplatePath(dstPath) ) {
      // Not allowed to copy/move items to a system templates folder
      return;
   }
   if( rbuttonDown ) {
      dragdropFromItemListContextMenu(dstPath,srcTemplateFilename,mx,my);
   } else {
      if( _ctIsSysItemTemplatePath(srcTemplateFilename) ) {
         // Prompt user to copy instead of move
         msg := "You cannot move a template from a system category folder.";
         if( _isMac() ) {
            msg :+= "\n\nYou can copy a template by right-clicking (or Ctrl+clicking) and dragging.";
         } else {
            msg :+= "\n\nYou can copy a template by right-clicking and dragging.";
         }
         msg :+= "\n\nWould you like to copy this template?";
         int status = _message_box(msg,"",MB_YESNOCANCEL|MB_ICONQUESTION);
         if( status!=IDYES ) {
            return;
         }
         ctTemplateManagerItemListCopy(dstPath);
         ctTemplateManagerItemListRefresh(itemWid,ctl_category);
      }
      return;
      ctTemplateManagerItemListMove(dstPath);
      ctTemplateManagerItemListRefresh(itemWid,ctl_category);
   }
}

void _ctTemplateManager_ItemList_etab.rbutton_down()
{
   call_event(true,defeventtab _ctTemplateManager_ItemList_etab,LBUTTON_DOWN,'e');
}

int _OnUpdate_ctTemplateManagerItemListNew(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }
   int categoryWid = target_wid.p_active_form.findCategoryTreeOrDie();
   _str templateDir = categoryWid._ctCategoryToTemplatePath();
   if( _ctIsSysItemTemplatePath(templateDir) ) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}

_command void ctTemplateManagerItemListNew(int categoryWid=0, int itemWid=0) name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   categoryWid=findCategoryTreeOrDie(categoryWid);
   if( categoryWid==0 ) {
      return;
   }
   itemWid=findItemListOrDie(itemWid);
   if( itemWid==0 ) {
      return;
   }
   _str templateDir = categoryWid._ctCategoryToTemplatePath();
   _maybe_append_filesep(templateDir);
   if( _ctIsSysItemTemplatePath(templateDir) ) {
      msg := "Cannot create new templates under installed templates category. Create new templates under user templates category instead.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   if( !maybeSaveFormInput() ) {
      // Error saving current template
      return;
   }

   // Name (no subdir, no extension) of template file
   name := "";
   // Relative subdirectory of new template file. If the user provides a subdirectory,
   // the result is a new category (or categories) for the template created under
   // the current category.
   subdir := "";
   // The absolute filename of the template file we are trying to create
   templateFilename := "";
   do {

      _str result = show("-modal _textbox_form",
                         "New Template", // Title
                         0,              // Flags
                         "",             // Width
                         "",             // Help
                         "",             // Buttons and captions
                         "",             // Retrieve name
                         "Template name:"name);
      if( result=="" ) {
         // User cancelled
         return;
      }
      result=strip(_param1);
      result=strip(result,'B','"');

      name=_strip_filename(result,'p');
      subdir=_strip_filename(result,'n');
      subdir=translate(subdir,FILESEP,FILESEP2);

      _maybe_strip_filesep(subdir);
      // Make sure the user entered a subdirectory that is relative to the
      // current category.
      if( subdir!="" && !_file_eq( substr(absolute(subdir,templateDir),1,length(templateDir)) , templateDir ) ) {
         _str msg = "Invalid sub-category for template name. Please provide a relative sub-category or no sub-category.\n\n":+
                    subdir;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         continue;
      }
      subdir=relative(subdir,templateDir,false);
      // If the user put the .setemplate extension on the name, then remove it
      if( _get_extension(name,true) == CT_EXT ) {
         name=_strip_filename(name,'e');
      }
      // Check to see if this template already exists
      templateFilename=name;
      templateFilename=strip(templateFilename,'T','.');
      templateFilename :+= CT_EXT;
      if( subdir != "" ) {
         templateFilename=templateDir:+subdir:+FILESEP:+name:+FILESEP:+templateFilename;
      } else {
         templateFilename=templateDir:+name:+FILESEP:+templateFilename;
      }
      if( file_exists(templateFilename) ) {
         _str msg = "Template already exists. Please choose a different name.\n\n":+
                    templateFilename;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         continue;
      }

   } while( false );

   // Note:
   // We use a template to create an item template. This template-template is located under sysconfig/templates.
   _str itemTemplateTemplateFilename = _ctGetSysTemplatesDir():+FILESEP:+CT_ITEM_TEMPLATE_TEMPLATE;
   _str location = templateDir;
   // Explanation by example:
   // If the user enters a name of 'Foo' then the template file created is 'Foo/Foo.setemplate'.
   // If the user enters a name of 'subdir/Foo' then the template file created is 'subdir/Foo/Foo.setemplate'.
   if( subdir!="" ) {
      location :+= subdir:+FILESEP:+name;
   } else {
      location :+= name;
   }
   ctTemplateContent_t resultContent;
   statusMessage := "";
   int status = _ctInstantiateTemplate(itemTemplateTemplateFilename,name,location,resultContent,null,null,null,statusMessage);
   if( status!=0 ) {
      // Error
      _str msg = "Error creating template.\n\n":+
                 templateFilename:+"\n\n":+
                 statusMessage;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   // Refresh category tree and item list to reflect new template.
   // Note:
   // Refreshing the category tree will result in the item list being refreshed.
   ctTemplateManagerCategoryTreeRefresh(categoryWid);
   // Select the template we just created in the item list
   itemWid._ctItemListSetCurrentItem(name);
}

int _OnUpdate_ctTemplateManagerItemListDelete(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }
   templateFilename := "";
   if( target_wid._ctItemListGetCurrentItem(templateFilename) &&
       !_ctIsSysItemTemplatePath(templateFilename) ) {

      return MF_ENABLED;
   }
   return MF_GRAYED;
}

/**
 * Delete a template, all its files, and the directory it is
 * under (if that directory is empty after deleting files).
 * 
 * @param templateFilename
 * @param prompt           Set to false if you do not want user
 *                         prompted for confirmation of delete.
 *                         Defaults to true.
 * 
 * @return int
 */
static int deleteTemplate(_str templateFilename, bool prompt=true)
{
   templateDir := _strip_filename(templateFilename,'n');
   _maybe_append_filesep(templateDir);

   ctTemplateDetails_t details; details._makeempty();
   ctTemplateContent_t content; content._makeempty();
   int status = _ctTemplateGetTemplate(templateFilename,&details,&content);
   if( status!=0 ) {
      _str msg = "Error retrieving template information. ":+get_message(status):+"\n\n":+
                 templateFilename;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return status;
   }

   // Put together a list of files to delete, and a list of files NOT to delete.
   // IMPORTANT:
   // We ONLY delete files that are directly under the template directory.
   _str delete_list[]; delete_list._makeempty();
   _str nodelete_list[]; nodelete_list._makeempty();
   if( content.Files != null && content.Files._length() > 0 ) {
      int i;
      for( i=0; i<content.Files._length(); ++i ) {
         _str Filename = content.Files[i].Filename;
         Filename=absolute(Filename,templateDir);
         // Only delete files that are directly under the template directory
         if( _file_eq(substr(Filename,1,length(templateDir)),templateDir) ) {
            delete_list[delete_list._length()]=Filename;
         } else {
            nodelete_list[nodelete_list._length()]=Filename;
         }
      }
   }

   if( prompt ) {
      // Make sure the user is very comfortable with what is about to be deleted
      _str msg = nls("Are you sure you want to permanently remove the template %s?",details.Name);
      if( delete_list._length() >0 ) {
         msg=msg:+"\n\n":+
             "The following files will be deleted:";
         int i;
         for( i=0; i<delete_list._length(); ++i ) {
            msg :+= "\n\t":+relative(delete_list[i],templateDir,false);
         }
      }
      if( nodelete_list._length() > 0 ) {
         msg=msg:+"\n\n":+
             "The following files will be preserved:";
         int i;
         for( i=0; i<nodelete_list._length(); ++i ) {
            msg :+= "\n\t":+relative(nodelete_list[i],templateDir,false);
         }
      }
      status=_message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
      if( status!=IDYES ) {
         return COMMAND_CANCELLED_RC;
      }
      status=0;
   }

   // Delete template content files
   int i;
   for( i=0; i<delete_list._length(); ++i ) {
      status=delete_file(delete_list[i]);
      if( status!=0 ) {
         _str msg = "Warning: Could not delete file. ":+get_message(status):+"\n\n":+
                    delete_list[i]:+"\n\n":+
                    "Continue?";
         int status2 = _message_box(msg,"",MB_YESNO|MB_ICONEXCLAMATION,IDNO);
         if( status2!=IDYES ) {
            break;
         }
         status=0;
      }
   }

   // Delete the .setemplate file
   if( 0==status ) {
      status=delete_file(templateFilename);
      if( status!=0 ) {
         _str msg = "Warning: Could not delete template file. ":+get_message(status):+"\n\n":+
                    templateFilename;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
   }

   // Delete template folder if it is empty (empty directories do not count)
   if( 0==status ) {
      if( isDirectoryEmpty(templateDir,true,true) ) {
         _str cwd = getcwd(); _maybe_append_filesep(cwd);
         if( _file_eq(substr(cwd,1,length(templateDir)),templateDir) ) {
            // Cannot delete the directory if we are in it
            new_cwd := strip(templateDir,'T',FILESEP);
            new_cwd=substr(new_cwd,1,pathlen(new_cwd)-1);
            chdir(new_cwd,1);
         }
         //status=rmdir(templateDir);
         status=_DelTree(templateDir,true);
         if( status!=0 ) {
            _str msg = "Warning: Could not delete template directory. ":+get_message(status):+"\n\n":+
                       templateDir;
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
      }
   }
   return status;
}

_command void ctTemplateManagerItemListDelete(int itemWid=0) name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   itemWid=findItemListOrDie(itemWid);
   if( itemWid==0 ) {
      return;
   }
   templateFilename := itemName := "";
   if( !itemWid._ctItemListGetCurrentItem(templateFilename,itemName) ) {
      return;
   }

   deleteTemplate(templateFilename);

   // Clear last item so that we do not try to save the template we just deleted
   _SetDialogInfoHt("last.template",null);

   // Refresh item list
   ctTemplateManagerItemListRefresh(itemWid);
}

int _OnUpdate_ctTemplateManagerItemListCopy(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }
   templateFilename := "";
   if( target_wid._ctItemListGetCurrentItem(templateFilename) ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

/**
 * Copy current template item to a category directory.
 * 
 * @param dstCategoryDir (input, output). Destination category
 *                       directory to copy template item to.
 * @param itemWid        Window id of template items list.
 * @param categoryWid    Window id of category tree.
 * @param refreshList    Set to false if you do not want category and
 *                       template lists refreshed after the copy.
 *                       Defaults to true.
 * 
 * @return 0 on success, <0 on error or COMMAND_CANCELLED_RC if 
 *         command was cancelled for any reason.
 */
_command int ctTemplateManagerItemListCopy(_str& dstCategoryDir="",
                                           int itemWid=0, int categoryWid=0,
                                           bool refreshList=true) name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   // Destination category directory
   if( dstCategoryDir=="" ) {
      // TODO: prompt user to choose category
      return COMMAND_CANCELLED_RC;
   }
   if( !_ctIsUserItemTemplatePath(dstCategoryDir) ) {
      msg := "You cannot copy/move a template into a system category folder. Please choose a user category folder destination.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return COMMAND_CANCELLED_RC;
   }
   _maybe_append_filesep(dstCategoryDir);

   // Source template
   itemWid=findItemListOrDie(itemWid);
   if( itemWid==0 ) {
      return COMMAND_CANCELLED_RC;
   }
   srcTemplateFilename := srcItemName := "";
   if( !itemWid._ctItemListGetCurrentItem(srcTemplateFilename,srcItemName) ) {
      return COMMAND_CANCELLED_RC;
   }
   srcTemplateDir := _strip_filename(srcTemplateFilename,'n');
   _maybe_append_filesep(srcTemplateDir);
   ctTemplateContent_t content;
   int status = _ctTemplateGetTemplateContent(srcTemplateFilename,content);
   if( status!=0 ) {
      _str msg = nls("Error retrieving template information for %s. ",srcItemName):+get_message(status):+"\n\n":+
                 srcTemplateFilename;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return status;
   }

   // Source template category (the template lives under this directory either by itself or in a subdirectory).
   // We need this to build our destination paths correctly when copying files.
   _str srcCategoryDir = srcTemplateDir;
   // Do not look any further up in the tree for a category directory than the root user templates directory
   _str userItemTemplatesDir = _ctGetUserItemTemplatesDir();
   _maybe_append_filesep(userItemTemplatesDir);
   if( !_file_eq(srcTemplateDir,userItemTemplatesDir) ) {
      srcCategoryDir=absolute(srcTemplateDir:+"..":+FILESEP);
      if( srcCategoryDir=="" ) {
         // ???
         srcCategoryDir=srcTemplateDir;
      }
      _maybe_append_filesep(srcCategoryDir);
   }

   // Destination template and template directory
   dstTemplateFilename := absolute( relative(srcTemplateFilename,srcCategoryDir) , dstCategoryDir );
   dstTemplateDir := _strip_filename(dstTemplateFilename,'n');
   _maybe_append_filesep(dstTemplateDir);

   // Verify we are not copying source over itself
   if( _file_eq(srcTemplateFilename,dstTemplateFilename) ) {
      // No harm, no foul. Just bail quietly.
      return COMMAND_CANCELLED_RC;
   }

   // Overwriting existing template?
   if( file_exists(dstTemplateFilename) ) {
      _str msg = "Template with same name already exists at destination:\n\n":+
                 strip(dstTemplateDir,'T','\'):+"\n\n":+
                 "Overwrite?";
      status=_message_box(msg,"",MB_YESNOCANCEL|MB_ICONQUESTION,IDNO);
      if( status!=IDYES ) {
         return COMMAND_CANCELLED_RC;
      }
   }

   // Copy template and files to destination
   status=0;
   if( !isdirectory(dstTemplateDir) ) {
      status=make_path(dstTemplateDir);
      if( status!=0 ) {
         _str msg = "Error creating directory:\n\n":+
                    dstTemplateDir:+"\n\n":+
                    get_message(status);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return status;
      }
   }
   _str srcFilenames[]; srcFilenames._makeempty();
   _str dstFilenames[]; dstFilenames._makeempty();
   do {

      status=copy_file(srcTemplateFilename,dstTemplateFilename);
      if( status!=0 ) {
         _str msg = "Error copying to file:\n\n":+
                    dstTemplateFilename:+"\n\n":+
                    get_message(status);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         break;
      }
      int i;
      for( i=0; i<content.Files._length(); ++i ) {

         srcFilename := absolute(content.Files[i].Filename,srcTemplateDir);
         dstFilename := absolute(content.Files[i].Filename,dstTemplateDir);
         if( _file_eq(srcFilename,dstFilename) ) {
            // This happens when a template's file is stored outside the template's directory.
            // Nothing to do in this case.
            continue;
         }

         // Make sure destination directory exists
         dstDir := _strip_filename(dstFilename,'n');
         if( !isdirectory(dstDir) ) {
            status=make_path(dstDir);
            if( status!=0 ) {
               _str msg = "Error creating directory:\n\n":+
                          dstDir:+"\n\n":+
                          get_message(status);
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
               break;
            }
         }
         status=copy_file(srcFilename,dstFilename);
         if( status!=0 ) {
            _str msg = "Error copying to file:\n\n":+
                       dstFilename:+"\n\n":+
                       get_message(status);
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            break;
         }
         srcFilenames[srcFilenames._length()]=srcFilename;
         dstFilenames[dstFilenames._length()]=dstFilename;
      }

   } while( false );

   if( status!=0 ) {
      // Error, so clean up
      delete_file(dstTemplateFilename);
      int i;
      for( i=0; i<dstFilenames._length(); ++i ) {
         delete_file(dstFilenames[i]);
      }
      if( isDirectoryEmpty(dstTemplateDir,false,true) ) {
         int status2 = _DelTree(dstTemplateDir,true);
         _str msg = "Warning: Could not delete directory. "get_message(status2):+"\n\n":+
                    dstTemplateDir;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
   }

   // Refresh category tree?
   if( refreshList ) {
      categoryWid=findCategoryTreeOrDie(categoryWid);
      if( categoryWid==0 ) {
         return status != 0 ? status : COMMAND_CANCELLED_RC;
      }
      _str categoryDir = categoryWid._ctCategoryToTemplatePath();
      _maybe_append_filesep(categoryDir);
      if( _file_eq(categoryDir,dstCategoryDir) ) {
         // We just copied a template to the currently selected category,
         // so refresh the category (which will also refresh the template
         // items list).
         ctTemplateManagerCategoryTreeRefresh(categoryWid);
      }
   }
   return status;
}

int _OnUpdate_ctTemplateManagerItemListMove(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }
   templateFilename := "";
   if( target_wid._ctItemListGetCurrentItem(templateFilename) &&
       !_ctIsSysItemTemplatePath(templateFilename) ) {

      return MF_ENABLED;
   }
   return MF_GRAYED;
}

/**
 * Move current template item to a category directory. A move is
 * really 2 operations: copy, delete.
 * 
 * @param dstCategoryDir (input, output). Destination category
 *                       directory to move template item to.
 * @param itemWid        Window id of template items list.
 * @param categoryWid    Window id of category tree.
 * @param refreshList    Set to false if you do not want category and
 *                       template lists refreshed after the move.
 *                       Defaults to true.
 * 
 * @return 0 on success, <0 on error or COMMAND_CANCELLED_RC if 
 *         command was cancelled for any reason.
 */
_command int ctTemplateManagerItemListMove(_str& dstCategoryDir="",
                                           int itemWid=0, int categoryWid=0,
                                           bool refreshList=true) name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   itemWid=findItemListOrDie(itemWid);
   if( itemWid==0 ) {
      return COMMAND_CANCELLED_RC;
   }
   categoryWid=findCategoryTreeOrDie(categoryWid);
   if( categoryWid==0 ) {
      return COMMAND_CANCELLED_RC;
   }

   srcTemplateFilename := srcItemName := "";
   if( !itemWid._ctItemListGetCurrentItem(srcTemplateFilename,srcItemName) ) {
      return COMMAND_CANCELLED_RC;
   }
   if( !_ctIsUserItemTemplatePath(srcTemplateFilename) ) {
      msg := "You cannot move a template from a system category folder. Consider copying the template instead.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return COMMAND_CANCELLED_RC;
   }
   int status = ctTemplateManagerItemListCopy(dstCategoryDir,itemWid,categoryWid,false);
   if( status == 0 ) {
      // Now delete the source template
      status=deleteTemplate(srcTemplateFilename,false);
   }
   _str categoryDir = categoryWid._ctCategoryToTemplatePath();
   _maybe_append_filesep(categoryDir);
   _maybe_append_filesep(dstCategoryDir);
   if( refreshList && _file_eq(categoryDir,dstCategoryDir) ) {
      // We just moved a template to the currently selected category,
      // so refresh the category (which will also refresh the template
      // items list).
      ctTemplateManagerCategoryTreeRefresh(categoryWid);
   }
   return status;
}

_command void ctTemplateManagerItemListRefresh(int itemWid=0, int categoryWid=0) name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!isinteger(itemWid)) itemWid=0;
   itemWid=findItemListOrDie(itemWid);
   if( itemWid==0 ) {
      return;
   }
   categoryWid=findCategoryTreeOrDie(categoryWid);
   if( categoryWid==0 ) {
      return;
   }

   if( !itemWid.p_active_form.maybeSaveFormInput() ) {
      // Error
      return;
   }

   itemName := "";
   itemWid._ctItemListGetCurrentItem(null,itemName);
   _str templateDir = categoryWid._ctCategoryToTemplatePath();
   if( templateDir!="" ) {
      old_inOnChange := itemWid._ctItemListInOnChange(1);
      itemWid._ctItemListInit(templateDir);
      itemWid._ctItemListSetCurrentItem(itemName);
      itemWid._ctItemListInOnChange((int)old_inOnChange);
      itemWid.call_event(CHANGE_SELECTED,itemWid._TreeCurIndex(),itemWid,ON_CHANGE,'w');
   }
}

/**
 * Determine if template item list needs to be refreshed based on previous
 * details and content compared to current details and content.
 *
 * @param prev_details ctTemplateDetails_t object representing previous template details.
 * @param prev_content ctTemplateContent_t object representing previous template content.
 * @param postCall     Set to true if you want the refresh run after all other
 *                     processing. Useful when being called from an on_got_focus
 *                     or on_lost_focus event.
 */
static void maybeRefreshItemList(ctTemplateDetails_t& prev_details,
                                 ctTemplateContent_t& prev_content,
                                 bool postCall=false)
{
   ctTemplateDetails_t details = _ctViewDetails();
   if( prev_details==null ||
       details.Name != prev_details.Name ||
       details.SortOrder != prev_details.SortOrder ) {

      if( postCall ) {
         _post_call(ctTemplateManagerItemListRefresh);
      } else {
         ctTemplateManagerItemListRefresh();
      }
   }
}

void _ctTemplateManager_ItemList_etab.'DEL'()
{
   _control ctl_item;
   ctTemplateManagerItemListDelete(ctl_item);
}

void _ctTemplateManager_ItemList_etab.rbutton_up(int x=-1, int y=-1)
{
   _ctTemplateManagerContextMenu("_ctTemplateManager_ItemList_menu",x,y);
}

void _ctTemplateManager_ItemList_etab.context()
{
   x := y := 0;
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _ctTemplateManager_ItemList_etab.call_event(x,y,defeventtab _ctTemplateManager_ItemList_etab,RBUTTON_UP,'e');
}
