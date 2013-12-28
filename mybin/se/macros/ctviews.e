////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47140 $
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
#import "codetemplate.e"
#import "controls.e"
#import "fileman.e"
#import "files.e"
#import "guiopen.e"
#import "main.e"
#import "menu.e"
#import "picture.e"
#import "stdcmds.e"
#import "stdprocs.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

/**
 * Common function.
 * <p>
 * Retrieve pointer to ctTemplateDetails_t object. This is the instance data
 * associated with the active form.
 * <p>
 * We store the details object on the active form so that outside forces
 * can update members of the object when needed. This allows all views
 * to share the same data (e.g. Template Manager).
 * 
 * @param templateDetails (optional). Pointer to ctTemplateDetails_t object used to initialize stored data.
 *                        When set to 0, the current instance data is returned.
 *                        Defaults to 0.
 * 
 * @return Copy of ctTemplateDetails_t object which is details instance data
 * for the active form.
 */
ctTemplateDetails_t _ctViewDetails(ctTemplateDetails_t* templateDetails=null)
{
   if( templateDetails ) {
      _SetDialogInfoHt("ctview.details",*templateDetails);
   }
   return ( (ctTemplateDetails_t)_GetDialogInfoHt("ctview.details") );
}

/**
 * Common function.
 * <p>
 * Retrieve copy of ctTemplateContent_t object. This is the instance data
 * associated with the active form.
 * <p>
 * We store the content object on the active form so that outside forces
 * can update members of the object when needed. This allows all views
 * to share the same data (e.g. Template Manager).
 * 
 * @param templateContent (optional). Pointer to ctTemplateContent_t object used to initialize stored data.
 *                        When set to 0, the current instance data is returned.
 *                        Defaults to 0.
 * 
 * @return Copy of ctTemplateContent_t object which is content instance data
 * for the active form.
 */
ctTemplateContent_t _ctViewContent(ctTemplateContent_t* templateContent=null)
{
   if( templateContent ) {
      _SetDialogInfoHt("ctview.content",*templateContent);
   }
   return ( (ctTemplateContent_t)_GetDialogInfoHt("ctview.content") );
}


//
// Template details view. Consists of apis for getting, setting, and verifying
// template details data.
//

defeventtab _ctDetailsView_etab;

#define ENTER_NAME "<Enter name>"
#define NO_DESCRIPTION "<No description>"

// If you override this, then make sure your derived on_create event
// calls this one to ensure proper initialization.
void _ctDetailsView_etab.on_create()
{
}


/**
 * Initialize details view with data.
 * <p>
 * IMPORTANT: <br>
 * Active window must be details view frame.
 * <p>
 * We store the details object on the active form so that outside forces
 * can update members of the object when needed. This allows all views
 * to share the same data (e.g. Template Manager).
 * 
 * @param templateFilename Template filename from which details come.
 * @param templateDetails  ctTemplateDetails_t object.
 */
void _ctDetailsViewInit(_str templateFilename, ctTemplateDetails_t& templateDetails)
{
   // Clear the details so there is no confusion if there is nothing
   // selected.
   _str Name = "";
   _str Description = "";
   _str DefaultName = "";
   _str SortOrder = "";

   // Is the view currently read-only?
   _SetDialogInfoHt("readOnly",false,p_window_id);
   _ctDetailsViewReadOnly(false);

   // All views (details, files, parameters) share this info
   _SetDialogInfoHt("ctview.templateFilename",templateFilename);
   _ctViewDetails(&templateDetails);

   if( templateDetails!=null ) {

      do {

         Name=templateDetails.Name;
         if( Name==null || Name=="" ) {
            Name=ENTER_NAME;
         }

         Description=templateDetails.Description;
         if( Description==null || Description=="" ) {
            Description=NO_DESCRIPTION;
         }

         DefaultName=templateDetails.DefaultName;
         if( DefaultName==null || DefaultName=="" ) {
            DefaultName="";
         }

         SortOrder=(_str)templateDetails.SortOrder;
         if( (int)SortOrder<0 ) {
            SortOrder="0";
         }

      } while( false );
   }

   _control ctl_description;
   _control ctl_name;
   _control ctl_defaultname;
   _control ctl_sortorder;
   ctl_name.p_text=Name;
   ctl_name._set_sel(1);
   ctl_description.p_text=Description;
   ctl_description._set_sel(1);
   ctl_defaultname.p_text=DefaultName;
   ctl_defaultname._set_sel(1);
   ctl_sortorder.p_text=SortOrder;
   ctl_sortorder._set_sel(1);
}

/**
 * Enable/disable input in the details view.
 * <p>
 * IMPORTANT: <br>
 * Active window must be details view frame.
 * 
 * @param enable (optional). Set to false to disable the details view.
 *               Defaults to true.
 */
void _ctDetailsViewEnable(boolean enable=true)
{
   _control ctl_name, ctl_description, ctl_defaultname, ctl_sortorder;
   ctl_name.p_enabled=enable;
   ctl_description.p_enabled=enable;
   ctl_defaultname.p_enabled=enable;
   ctl_sortorder.p_enabled=enable;
   // And the spin control
   ctl_sortorder.p_next.p_enabled=enable;
}

/**
 * Set input in the details view read-only.
 * <p>
 * IMPORTANT: <br>
 * Active window must be details view frame.
 * 
 * @param readOnly (optional). Set to false to unset read-only mode on input in the details view.
 *                 Defaults to true.
 */
void _ctDetailsViewReadOnly(boolean readOnly=true)
{
   _control ctl_name, ctl_description, ctl_defaultname, ctl_sortorder;

   _SetDialogInfoHt("readOnly",readOnly,p_window_id);

   if( ctl_name.p_ReadOnly!=readOnly ) {
      // Assume all controls need p_ReadOnly toggled
      ctl_name.p_ReadOnly=readOnly;
      ctl_description.p_ReadOnly=readOnly;
      ctl_defaultname.p_ReadOnly=readOnly;
      ctl_sortorder.p_ReadOnly=readOnly;
      // And the spin control
      ctl_sortorder.p_next.p_enabled=!readOnly;
   }
}

static boolean verifyName(_str Name)
{
   // Anything goes!
   return true;
}

static boolean verifyDescription(_str Description)
{
   // Anything goes!
   return true;
}

static boolean verifyDefaultName(_str DefaultName)
{
   if( DefaultName==ENTER_NAME || pos(CTDEFAULTNAME_INVALID_CHARS,DefaultName,1,'er') ) {
      // Invalid
      return false;
   }
   // Valid
   return true;
}

static boolean verifySortOrder(_str SortOrder)
{
   if( !isinteger(SortOrder) || (int)SortOrder<0 ) {
      // Invalid
      return false;
   }
   // Valid
   return true;
}

/**
 * Verify details view input.
 * <p>
 * Use _ctViewDetails to retrieve a copy of ctTemplateDetails_t results.
 * <p>
 * IMPORTANT: <br>
 * Active window must be details view frame.
 * 
 * @param quiet (optional). Set to true to not display error messages.
 *              Defaults to false.
 * @param selectError   (optional). Set to false if you do not want the location
 *                      of the error made active.
 *                      Defaults to true.
 * @param statusMessage (optional). Set to description of error (if any).
 * 
 * @return true on success (no errors in input).
 */
boolean _ctDetailsViewVerifyInput(boolean quiet=false, boolean selectError=true, _str& statusMessage=null)
{
   _control ctl_name, ctl_description, ctl_defaultname, ctl_sortorder;
   // Name
   _str Name = strip(ctl_name.p_text);
   if( !verifyName(Name) ) {
      statusMessage = "A valid name is required. Please enter a valid name in the Name field.";
      if( !quiet ) {
         _message_box(statusMessage,"",MB_OK|MB_ICONEXCLAMATION);
      }
      if( selectError ) {
         p_window_id=ctl_name;
         _set_sel(1,length(p_text)+1);_set_focus();
      }
      return false;
   }
   // Description
   _str Description = strip(ctl_description.p_text);
   if( !verifyDescription(Description) ) {
      statusMessage = "Invalid description. Please enter a valid description in the Description field.";
      if( !quiet ) {
         _message_box(statusMessage,"",MB_OK|MB_ICONEXCLAMATION);
      }
      if( selectError ) {
         p_window_id=ctl_description;
         _set_sel(1,length(p_text)+1);_set_focus();
      }
      return false;
   }
   // DefaultName
   _str DefaultName = strip(ctl_defaultname.p_text);
   if( !verifyDefaultName(DefaultName) ) {
      statusMessage = "Invalid default name. Please enter a valid default name using valid filename characters in the Default name field.";
      if( !quiet ) {
         _message_box(statusMessage,"",MB_OK|MB_ICONEXCLAMATION);
      }
      if( selectError ) {
         p_window_id=ctl_defaultname;
         _set_sel(1,length(p_text)+1);_set_focus();
      }
      return false;
   }
   // SortOrder
   _str SortOrderStr = strip(ctl_sortorder.p_text);
   if( !verifySortOrder(SortOrderStr) ) {
      statusMessage = "Invalid sort order. Please enter a valid sort order >=0 in the Sort order field.";
      if( !quiet ) {
         _message_box(statusMessage,"",MB_OK|MB_ICONEXCLAMATION);
      }
      if( selectError ) {
         p_window_id=ctl_sortorder;
         _set_sel(1,length(p_text)+1);_set_focus();
      }
      return false;
   }
   int SortOrder = (int)SortOrderStr;

   // Store verified details
   ctTemplateDetails_t templateDetails;
   templateDetails.Name=Name;
   templateDetails.Description=Description;
   templateDetails.DefaultName=DefaultName;
   templateDetails.SortOrder=SortOrder;
   _ctViewDetails(&templateDetails);

   // All good
   return true;
}

#define CT_SORTORDER_INCREMENT 10

void ctl_sortorder_spin.on_spin_down()
{
   _control ctl_sortorder;
   _str SortOrder = ctl_sortorder.p_text;
   if( !verifySortOrder(SortOrder) || !verifySortOrder((int)SortOrder - CT_SORTORDER_INCREMENT) ) {
      SortOrder="0";
   } else {
      SortOrder=(int)SortOrder - CT_SORTORDER_INCREMENT;
   }
   p_window_id=ctl_sortorder;
   p_text=SortOrder;
   _set_sel(1,length(p_text)+1);_set_focus();
}

void ctl_sortorder_spin.on_spin_up()
{
   _control ctl_sortorder;
   _str SortOrder = ctl_sortorder.p_text;
   if( !verifySortOrder(SortOrder) || !verifySortOrder((int)SortOrder + CT_SORTORDER_INCREMENT) ) {
      SortOrder="0";
   } else {
      SortOrder=(int)SortOrder + CT_SORTORDER_INCREMENT;
   }
   p_window_id=ctl_sortorder;
   p_text=SortOrder;
   _set_sel(1,length(p_text)+1);_set_focus();
}


//
// Template files view. Consists of apis for getting, setting, and verifying
// template files data.
//

defeventtab _ctFilesView_etab;

// If you override this, then make sure your derived on_create event
// calls this one to ensure proper initialization.
void _ctFilesView_etab.on_create()
{
   _ctFilesViewInOnChange((int)false);
}

// If you override this, then you might want your derived on_change event
// to call this one so that unhandled events are handled.
void ctl_files.on_change(int reason, int nodeIndex=0)
{
   if( p_parent._ctFilesViewInOnChange() ) {
      // Recursion not allowed!
      return;
   }

   boolean old_inOnChange = p_parent._ctFilesViewInOnChange(1);
   switch( reason ) {
   case CHANGE_SELECTED:
      {
         _control ctl_file_up, ctl_file_down, ctl_file_remove;
         boolean enabled = ( nodeIndex > 0 );
         if( ctl_file_up.p_enabled!=enabled ) {
            // Assume they all need to be enabled/disabled
            ctl_file_up.p_enabled=enabled;
            ctl_file_down.p_enabled=enabled;
            ctl_file_remove.p_enabled=enabled;
            ctl_file_edit.p_enabled=enabled;
         }
      }
      break;
   }
   p_parent._ctFilesViewInOnChange((int)old_inOnChange);
}

void ctl_files.rbutton_up(int x=-1, int y=-1)
{
   _str menu_name="_ctFilesView_menu";
   int index = find_index(menu_name,oi2type(OI_MENU));
   if( index==0 ) {
      return;
   }
   int handle = p_active_form._menu_load(index,'p');
   if( handle<0) {
      _str msg = "Unable to load menu \"":+menu_name:+"\"";
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
   _menu_show(handle,flags,x,y);
   _menu_destroy(handle);
}

void ctl_files.context()
{
   int x=0, y=0;
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   ctl_files.call_event(x,y,ctl_files,RBUTTON_UP,'w');
}

static int findFilesTree(int wid=0)
{
   if( wid==0 || wid.p_object!=OI_TREE_VIEW ) {
      wid = p_active_form._find_control("ctl_files");
   }
   return wid;
}

static int findFilesTreeOrDie(int wid=0)
{
   wid=findFilesTree(wid);
   if( wid==0 ) {
      _str msg = "Unable to locate Files tree.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }
   return wid;
}

int _OnUpdate_ctFilesViewAddFile(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }

   if( _ctViewAddEnabled( target_wid ) ) {
      return MF_ENABLED;
   }

   return MF_GRAYED;
}

static boolean _ctViewAddEnabled(int treeWid)
{
   if( _GetDialogInfoHt("readOnly",treeWid.p_parent) ) {
      // View is read-only
      return false;
   }
   return true;
}

static boolean _ctViewEditEnabled(int treeWid)
{
   // Note:
   // We do not check for read-only view since we want the user to be able
   // to view the file.
   return (treeWid._TreeCurIndex() > 0);
}

static boolean _ctViewMoveEnabled(int treeWid)
{
   if( _GetDialogInfoHt("readOnly",treeWid.p_parent) ) {
      // View is read-only
      return false;
   }

   if( treeWid._TreeCurIndex() > 0 ) {
      return true;
   }

   return false;
}

_command void ctFilesViewAddFile(int treeWid=0)
{
   treeWid=findFilesTreeOrDie(treeWid);
   if( treeWid==0 ) {
      return;
   }

   _str templateFilename = _GetDialogInfoHt("ctview.templateFilename");
   ctTemplateDetails_t details = _ctViewDetails();
   ctTemplateContent_t content = _ctViewContent();

   ctTemplateContent_File_t File; File._makeempty();
   _str src, target;
   boolean copy, replace;

   boolean done = false;
   prompt:
   do {
      _str result = show("-modal _ctAddFile_form",templateFilename,details.DefaultName,content.Delimiter,File);
      if( result=="" ) {
         // Command cancelled
         return;
      }
      // All error checking is done at this point
      src=_param1;
      copy=_param2;
      target=_param3;
      replace=_param4;

      // Look through all current files and make sure we are not duplicating a target
      int index = treeWid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while( index>0 ) {
         _str line = treeWid._TreeGetCaption(index);
         _str Filename, TargetFilename, ReplaceParameters;
         parse line with Filename"\t"TargetFilename"\t"ReplaceParameters"\t".;
         if( file_eq(target,TargetFilename) ) {
            _str msg = "Duplicate target found. Cannot add file.";
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            treeWid._TreeSetCurIndex(index);
            // Fill in the File so that re-prompting is less painful
            File.Filename=src;
            File.TargetFilename=target;
            File.ReplaceParameters=replace;
            continue prompt;
         }
         index=treeWid._TreeGetNextSiblingIndex(index);
      }
      done=true;

   } while( !done );

   _str templateDir = _GetDialogInfoHt("ctview.templateDir");
   _maybe_append_filesep(templateDir);

   src=absolute(src);
   if( copy ) {
      // Copy source to template directory first
      if( !isdirectory(templateDir) ) {
         int status = make_path(templateDir);
         if( status!=0 ) {
            _str msg = "Error creating directory:\n\n":+
                       templateDir:+"\n\n":+
                       get_message(status):+"\n\n":+
                       "Cannot add file.";
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return;
         }
      }
      _str name = _strip_filename(src,'p');
      _str new_src = templateDir:+name;
      if( !file_eq(src,new_src) ) {
         if( file_exists(new_src) ) {
            _str msg = "File already exists.\n\n":+
                       new_src:+"\n\n":+
                       "Overwrite?";
            int status = _message_box(msg,"",MB_YESNO,IDNO);
            if( status!=IDYES ) {
               return;
            }
         }
         int status = copy_file(src,new_src);
         if( status!=0 ) {
            _str msg = "Error copying file to:\n\n":+
                       new_src:+"\n\n":+
                       get_message(status):+"\n\n":+
                       "Cannot add file.";
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return;
         }
      }
      src=new_src;
   }
   src=relative(src,templateDir);
   _str line = src"\t"target"\t"replace;
   int index = treeWid._TreeAddItem(TREE_ROOT_INDEX,line,TREE_ADD_AS_CHILD,0,0,-1);
   treeWid._TreeSetCurIndex(index);
   // Must call on_change() ourselves for the case of only 1 node in the tree,
   // so might as well call it for all cases.
   treeWid.call_event(CHANGE_SELECTED,index,treeWid,ON_CHANGE,'w');
}

void ctl_file_add.lbutton_up()
{
   _control ctl_files;
   ctFilesViewAddFile(ctl_files);
}

int _OnUpdate_ctFilesViewEditFile(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }

   if( _ctViewEditEnabled(target_wid) ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

_command void ctFilesViewEditFile(int treeWid=0)
{
   treeWid=findFilesTreeOrDie(treeWid);
   if( treeWid==0 ) {
      return;
   }

   int index = treeWid._TreeCurIndex();
   if( index<=0 ) {
      // Nothing to do
      return;
   }

   _str templateDir = _GetDialogInfoHt("ctview.templateDir");
   _maybe_append_filesep(templateDir);

   _str line = treeWid._TreeGetCaption(index);
   _str Filename, TargetFilename, ReplaceParameters;
   parse line with Filename"\t"TargetFilename"\t"ReplaceParameters"\t".;
   ctTemplateContent_File_t File;
   File.Filename=absolute(Filename,templateDir);
   File.TargetFilename=TargetFilename;
   File.ReplaceParameters= ( ReplaceParameters != "0" );

   _str templateFilename = _GetDialogInfoHt("ctview.templateFilename");
   ctTemplateDetails_t details = _ctViewDetails();
   ctTemplateContent_t content = _ctViewContent();

   _str caption = "Edit File";
   boolean readOnly = _GetDialogInfoHt("readOnly",treeWid.p_parent);
   if( readOnly ) {
      caption="View File";
   }
   _str result = show("-modal _ctAddFile_form",templateFilename,details.DefaultName,content.Delimiter,File,caption,false,readOnly);
   if( readOnly || result=="" ) {
      // Read-only or command cancelled
      return;
   }
   // All error checking is done at this point
   _str src = _param1;
   boolean copy = _param2;
   _str target = _param3;
   boolean replace = _param4;

   src=relative(src,templateDir);
   line = src"\t"target"\t"replace;
   treeWid._TreeSetCaption(index,line);
   treeWid._TreeSetCurIndex(index);
}

void ctl_file_edit.lbutton_up()
{
   _control ctl_files;
   ctFilesViewEditFile(ctl_files);
}

void ctl_files.lbutton_double_click()
{
   ctFilesViewEditFile(p_window_id);
}

int _OnUpdate_ctFilesViewOpenFile(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }

   if( _GetDialogInfoHt("readOnly",target_wid.p_parent) ) {
      // View is read-only
      return MF_GRAYED;
   }

   if( target_wid._TreeCurIndex() > 0 ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

_command void ctFilesViewOpenFile(int treeWid=0)
{
   treeWid=findFilesTreeOrDie(treeWid);
   if( treeWid==0 ) {
      return;
   }

   int index = treeWid._TreeCurIndex();
   if( index<=0 ) {
      // Nothing to do
      return;
   }

   _str templateDir = _GetDialogInfoHt("ctview.templateDir");
   _maybe_append_filesep(templateDir);

   _str line = treeWid._TreeGetCaption(index);
   _str Filename, TargetFilename, ReplaceParameters;
   parse line with Filename"\t"TargetFilename"\t"ReplaceParameters"\t".;
   Filename=absolute(Filename,templateDir);
   if( !file_exists(Filename) ) {
      _str msg = "File does not exist on disk.\n\n":+
                 Filename:+"\n\n":+
                 "Create?";
      int status = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
      if( status!=IDYES ) {
         return;
      }
   }
   _mdi.p_child.edit(maybe_quote_filename(Filename));
}

static boolean moveFileUpDown(int treeWid=0, _str direction='')
{
   treeWid=findFilesTreeOrDie(treeWid);
   if( treeWid==0 ) {
      return false;
   }
   int index = treeWid._TreeCurIndex();
   if( index<=0 ) {
      // Nothing selected
      return false;
   }
   int status = 0;
   if( direction=='-' ) {
      status=treeWid._TreeMoveDown(index);
   } else {
      status=treeWid._TreeMoveUp(index);
   }
   return ( status==0 );
}

int _OnUpdate_ctFilesViewMoveFileUp(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }
   if( _ctViewMoveEnabled(target_wid) ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

_command void ctFilesViewMoveFileUp(int treeWid=0)
{
   moveFileUpDown(treeWid);
}

int _OnUpdate_ctFilesViewMoveFileDown(CMDUI &cmdui, int target_wid, _str command)
{
   return ( _OnUpdate_ctFilesViewMoveFileUp(cmdui,target_wid,command) );
}

_command void ctFilesViewMoveFileDown(int treeWid=0)
{
   moveFileUpDown(treeWid,'-');
}

void ctl_file_up.lbutton_up()
{
   _control ctl_files;
   ctFilesViewMoveFileUp(ctl_files);
}

void ctl_file_down.lbutton_up()
{
   _control ctl_files;
   ctFilesViewMoveFileDown(ctl_files);
}

int _OnUpdate_ctFilesViewRemoveFile(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }
   if( _ctViewMoveEnabled(target_wid) ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

_command void ctFilesViewRemoveFile(int treeWid=0)
{
   treeWid=findFilesTreeOrDie(treeWid);
   if( treeWid==0 ) {
      return;
   }
   int index = treeWid._TreeCurIndex();
   if( index>0 ) {
      _str line = treeWid._TreeGetCaption(index);
      _str Filename, TargetFilename, ReplaceParameters;
      parse line with Filename"\t"TargetFilename"\t"ReplaceParameters"\t".;
      _str templateDir = _GetDialogInfoHt("ctview.templateDir");
      Filename=absolute(Filename,templateDir);

      treeWid._TreeDelete(index);

      if( file_exists(Filename) ) {
         _str msg = "Delete file from disk permanently?\n\n":+
                    Filename;
         int status = _message_box(msg,"",MB_YESNOCANCEL|MB_ICONQUESTION,IDNO);
         if( status==IDYES ) {
            status=delete_file(Filename);
            if( status!=0 ) {
               msg="Warning: Could not delete file from disk:\n\n":+
                   Filename:+"\n\n":+
                   get_message(status);
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
         } else if( status==IDCANCEL ) {
            return;
         }
      }
      // Must call on_change() ourselves for the case of only 1 node in the tree,
      // so might as well call it for all cases.
      treeWid.call_event(CHANGE_SELECTED,treeWid._TreeCurIndex(),treeWid,ON_CHANGE,'w');
   }
}

void ctl_file_remove.lbutton_up()
{
   _control ctl_files;
   ctFilesViewRemoveFile(ctl_files);
}

static void setFilesCols()
{
   // Create the grid, setup column labels
   int w1, w2, w3;
   // +200 is a fudge-factor
   w3=_text_width("Replace Parameters") + 200;
   w1=w2=(p_width - w3) / 2;
   _TreeSetColButtonInfo(0,w1,0,-1,"Source");
   _TreeSetColButtonInfo(1,w2,0,-1,"Target");
   _TreeSetColButtonInfo(2,w3,0,-1,"Replace Parameters");
}

/**
 * Indicate whether we are in the middle of an on_change event for the files view.
 * Used to disallow recursion.
 * <p>
 * IMPORTANT: <br>
 * Active window must be files view frame.
 * 
 * @param onoff 0 = Not in an on_change event. <br>
 *              1 = In an on_change event. <br>
 *              -1 = Return current value without setting.
 * 
 * @return Previous value. Current value if -1 specified.
 */
boolean _ctFilesViewInOnChange(int onoff=-1)
{
   boolean old_onoff = _GetDialogInfoHt("inOnChange",p_window_id);
   if( onoff > -1 ) {
      _SetDialogInfoHt("inOnChange",onoff!=0,p_window_id);
   }
   return old_onoff;
}

/**
 * Initialize files view with list of files.
 * <p>
 * IMPORTANT: <br>
 * Active window must be files view frame.
 * <p>
 * We store the content object on the active form so that outside forces
 * can update members of the object when needed. This allows all views
 * to share the same data (e.g. Template Manager).
 * 
 * @param templateFilename The template file from which details and content come.
 * @param details ctTemplateDetails_t object. Required for assembling the example
 *                and preview when adding a file.
 * @param content ctTemplateContent_t object. Contains Files array used to
 *                initialize list.
 */
void _ctFilesViewInit(_str templateFilename,
                      ctTemplateDetails_t& details,
                      ctTemplateContent_t& content)
{
   boolean old_inOnChange = _ctFilesViewInOnChange(1);

   templateFilename=strip(templateFilename,'B','"');
   templateFilename=strip(templateFilename);

   // Is the view currently read-only?
   _SetDialogInfoHt("readOnly",false,p_window_id);
   _ctFilesViewReadOnly(false);

   // All views (details, files, parameters) share this info
   _SetDialogInfoHt("ctview.templateFilename",templateFilename);
   _str templateDir = "";
   if( templateFilename!="" ) {
      templateDir=_strip_filename(templateFilename,'n');
      _maybe_strip_filesep(templateDir);
   }
   _SetDialogInfoHt("ctview.templateDir",templateDir);
   _ctViewDetails(&details);
   _ctViewContent(&content);
   _str DefaultName = details.DefaultName;
   if( DefaultName==null ) {
      details.DefaultName="";
      // Fix it
      _ctViewDetails(&details);
   }
   _str Delimiter = content.Delimiter;
   if( Delimiter==null ) {
      content.Delimiter="";
      // Fix it
      _ctViewContent(&content);
   }

   // Clear the files so there is no confusion if there is nothing
   // selected.
   _control ctl_files;
   ctl_files._TreeDelete(TREE_ROOT_INDEX,'c');

   // Column labels
   ctl_files.setFilesCols();

   // Insert files
   if( content.Files!=null ) {
      int i;
      for( i=0; i<content.Files._length(); ++i ) {
         ctTemplateContent_File_t File = content.Files[i];
         _str line = File.Filename"\t"File.TargetFilename"\t"File.ReplaceParameters;
         ctl_files._TreeAddItem(TREE_ROOT_INDEX,line,TREE_ADD_AS_CHILD,0,0,-1);
      }
   }

   _ctFilesViewInOnChange((int)old_inOnChange);
   ctl_files.call_event(CHANGE_SELECTED,ctl_files._TreeCurIndex(),ctl_files,ON_CHANGE,'w');
}

/**
 * Enable/disable input in the files view.
 * <p>
 * IMPORTANT: <br>
 * Active window must be files view frame.
 * 
 * @param enable (optional). Set to false to disable the files view.
 *               Defaults to true.
 */
void _ctFilesViewEnable(boolean enable=true)
{
   // _OnUpdate mucks with the active window!
   int orig_wid;
   get_window_id(orig_wid);

   _control ctl_files, ctl_file_add, ctl_file_edit, ctl_file_remove;
   ctl_files.p_enabled=enable;
   CMDUI cmdui;
   cmdui.button_wid=0;
   cmdui.inMenuBar=false;
   cmdui.menu_handle=0;
   cmdui.menu_pos=0;
   ctl_file_add.p_enabled=( enable && _ctViewAddEnabled(ctl_files));
   ctl_file_edit.p_enabled=( enable && _ctViewEditEnabled(ctl_files));
   ctl_file_up.p_enabled=ctl_file_down.p_enabled=ctl_file_remove.p_enabled=( enable && _ctViewMoveEnabled(ctl_files));

   activate_window(orig_wid);
}

/**
 * Set input in the files view read-only.
 * <p>
 * IMPORTANT: <br>
 * Active window must be files view frame.
 * 
 * @param readOnly (optional). Set to false to unset read-only mode on input in the files view.
 *                 Defaults to true.
 */
void _ctFilesViewReadOnly(boolean readOnly=true)
{
   _control ctl_files, ctl_file_add, ctl_file_edit, ctl_file_remove;

   _SetDialogInfoHt("readOnly",readOnly,p_window_id);

   CMDUI cmdui;
   cmdui.button_wid=0;
   cmdui.inMenuBar=false;
   cmdui.menu_handle=0;
   cmdui.menu_pos=0;

   ctl_file_add.p_enabled=_ctViewAddEnabled(ctl_files);

   // We want the user to be able to view the file but not edit
   ctl_file_edit.p_enabled=_ctViewEditEnabled(ctl_files);
   ctl_file_up.p_enabled=ctl_file_down.p_enabled=ctl_file_remove.p_enabled=_ctViewMoveEnabled(ctl_files);

}

/**
 * Verify files view input.
 * <p>
 * Use _ctViewContent to retrieve a copy of the ctTemplateContent_t results.
 * <p>
 * IMPORTANT: <br>
 * Active window must be files view frame.
 * 
 * @param quiet (optional). Set to true to not display error messages.
 *              Defaults to false.
 * @param selectError   (optional). Set to false if you do not want the location
 *                      of the error made active.
 *                      Defaults to true.
 * @param statusMessage (optional). Set to description of error (if any).
 * 
 * @return true on success (no errors in input).
 */
boolean _ctFilesViewVerifyInput(boolean quiet=false, boolean selectError=true, _str& statusMessage=null)
{
   ctTemplateContent_t templateContent = _ctViewContent();
   templateContent.Files._makeempty();
   _control ctl_files;
   int index = ctl_files._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while( index>0 ) {
      _str line = ctl_files._TreeGetCaption(index);
      _str Filename, TargetFilename, ReplaceParameters;
      parse line with Filename"\t"TargetFilename"\t"ReplaceParameters"\t".;
      int i = templateContent.Files._length();
      templateContent.Files[i].Filename=Filename;
      templateContent.Files[i].TargetFilename=TargetFilename;
      templateContent.Files[i].ReplaceParameters=( ReplaceParameters != "0" );
      index=ctl_files._TreeGetNextSiblingIndex(index);
   }

   // Store verified content
   _ctViewContent(&templateContent);

   // All good
   return true;
}


//
// Template parameters view. Consists of apis for getting, setting, and verifying
// template parameters data.
//

defeventtab _ctParametersView_etab;

// If you override this, then make sure your derived on_create event
// calls this one to ensure proper initialization.
void _ctParametersView_etab.on_create()
{
   _ctParametersViewInOnChange((int)false);
}

// For those forms that are resizable, we resize what is within the view.
// IMPORTANT:
// Active window must be parameters view frame.
void _ctParametersView_etab.on_resize()
{
   if( p_active_form.p_border_style != BDS_SIZABLE ) {
      // Nothing to do
      return;
   }
   int frameW = _dx2lx(SM_TWIP,p_client_width);
   int frameH = _dy2ly(SM_TWIP,p_client_height);
   _control ctl_params, ctl_param_add, ctl_param_edit, ctl_param_remove;
   _control ctl_delimiter_label, ctl_delimiter, ctl_delimiter_note;
   int after_tree_x = ctl_param_add.p_x - (ctl_params.p_x + ctl_params.p_width);
   int after_tree_y = 0;
   if( ctl_delimiter.p_visible ) {
      // Force the tree to take up entire height of frame if not showing the delimiter
      after_tree_y = ctl_delimiter.p_y - (ctl_params.p_y + ctl_params.p_height);
   }
   // Assumption: ctl_params tree is flush (0,0) with left,top edge of frame
   ctl_params.p_width = frameW - after_tree_x - ctl_param_add.p_width;
   ctl_params.p_height = frameH - after_tree_y - ctl_delimiter.p_height;
   // Buttons align vertically under each other
   ctl_param_add.p_x=ctl_params.p_x + ctl_params.p_width + after_tree_x;
   ctl_param_edit.p_x=ctl_param_add.p_x;
   ctl_param_remove.p_x=ctl_param_add.p_x;
   // Delimiter label, text box, note
   ctl_delimiter.p_y=ctl_params.p_y + ctl_params.p_height + after_tree_y;
   ctl_delimiter_label.p_y=ctl_delimiter.p_y + (ctl_delimiter.p_height - ctl_delimiter_label.p_height) intdiv 2;
   ctl_delimiter_note.p_y=ctl_delimiter_label.p_y;
}

// If you override this, then you might want your derived on_change event
// to call this one so that unhandled events are handled.
void ctl_params.on_change(int reason, int nodeIndex)
{
   if( p_parent._ctParametersViewInOnChange() ) {
      // Recursion not allowed!
      return;
   }

   boolean old_inOnChange = p_parent._ctParametersViewInOnChange(1);
   switch( reason ) {
   case CHANGE_SELECTED:
      {
         // Passing true will get the right things enabled/disabled based
         // on what is in the tree.
         p_parent._ctParametersViewEnable(true);
      }
      break;
   }
   p_parent._ctParametersViewInOnChange((int)old_inOnChange);
}

void ctl_params.rbutton_up(int x=-1, int y=-1)
{
   _str menu_name="_ctParametersView_menu";
   int index = find_index(menu_name,oi2type(OI_MENU));
   if( index==0 ) {
      return;
   }
   int handle = p_active_form._menu_load(index,'p');
   if( handle<0) {
      _str msg = "Unable to load menu \"":+menu_name:+"\"";
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
   _menu_show(handle,flags,x,y);
   _menu_destroy(handle);
}

void ctl_params.context()
{
   int x=0, y=0;
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   ctl_params.call_event(x,y,ctl_params,RBUTTON_UP,'w');
}

static int findParametersTree(int wid=0)
{
   if( wid==0 || wid.p_object!=OI_TREE_VIEW ) {
      wid = p_active_form._find_control("ctl_params");
   }
   return wid;
}

static int findParametersTreeOrDie(int wid=0)
{
   wid=findParametersTree(wid);
   if( wid==0 ) {
      _str msg = "Unable to locate Parameters tree.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }
   return wid;
}

int _OnUpdate_ctParametersViewAddParameter(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }

   if (_ctViewAddEnabled(target_wid)) {
      return MF_ENABLED;
   }

   return MF_GRAYED;
}

_command void ctParametersViewAddParameter(int treeWid=0)
{
   treeWid=findParametersTreeOrDie(treeWid);
   if( treeWid==0 ) {
      return;
   }

   _str Name = "";
   _str Value = "";
   boolean Prompt = false;
   _str PromptString = "";

   boolean done = false;
   prompt:
   do {

      _str result = show("-modal _ctAddParameter_form",Name,Value,Prompt,PromptString);
      if( result=="" ) {
         // Command cancelled
         return;
      }
      // All error checking is done at this point
      Name=_param1;
      Value=_param2;
      Prompt=_param3;
      PromptString=_param4;

      // Make sure we are not re-defining a pre-defined parameter
      if( _ctIsPredefinedParameter(Name) ) {
         _str msg = "'"Name"' is a pre-defined substitution paramter. Please choose another name.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         continue prompt;
      }

      // Look through all current parameters and make sure we are not duplicating a parameter
      int index = treeWid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while( index>0 ) {
         _str line = treeWid._TreeGetCaption(index);
         _str n;
         parse line with n"\t".;
         if( lowcase(n)==lowcase(Name) ) {
            _str msg = "Duplicate parameter found. Cannot add parameter.";
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            treeWid._TreeSetCurIndex(index);
            continue prompt;
         }
         index=treeWid._TreeGetNextSiblingIndex(index);
      }
      done=true;

   } while( !done );

   _str line = Name"\t"Value"\t"Prompt"\t"PromptString;
   int index = treeWid._TreeAddItem(TREE_ROOT_INDEX,line,TREE_ADD_AS_CHILD,0,0,-1);
   treeWid._TreeSetCurIndex(index);
   // Must call on_change() ourselves for the case of only 1 node in the tree,
   // so might as well call it for all cases.
   treeWid.call_event(CHANGE_SELECTED,index,treeWid,ON_CHANGE,'w');
}

void ctl_param_add.lbutton_up()
{
   _control ctl_params;
   ctParametersViewAddParameter(ctl_params);
}

int _OnUpdate_ctParametersViewEditParameter(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }

   if( _ctViewEditEnabled(target_wid) ) {
      return MF_ENABLED;
   }

   return MF_GRAYED;
}

_command void ctParametersViewEditParameter(int treeWid=0)
{
   treeWid=findParametersTreeOrDie(treeWid);
   if( treeWid==0 ) {
      return;
   }

   int index = treeWid._TreeCurIndex();
   if( index<=0 ) {
      return;
   }

   _str line = treeWid._TreeGetCaption(index);
   _str Name, Value, Prompt, PromptString;
   parse line with Name"\t"Value"\t"Prompt"\t"PromptString"\t".;

   _str caption = "Edit Parameter";
   boolean readOnly = _GetDialogInfoHt("readOnly",treeWid.p_parent);
   if( readOnly ) {
      caption="View Parameter";
   }
   _str result = show("-modal _ctAddParameter_form",Name,Value,Prompt!="0",PromptString,caption,readOnly);
   if( readOnly || result=="" ) {
      // Read-only or command cancelled
      return;
   }
   // All error checking is done at this point
   Name=_param1;
   Value=_param2;
   Prompt=_param3;
   PromptString=_param4;

   line=Name"\t"Value"\t"Prompt"\t"PromptString;
   treeWid._TreeSetCaption(index,line);
   treeWid._TreeSetCurIndex(index);
}

void ctl_param_edit.lbutton_up()
{
   _control ctl_params;
   ctParametersViewEditParameter(ctl_params);
}

void ctl_params.lbutton_double_click()
{
   ctParametersViewEditParameter(p_window_id);
}

int _OnUpdate_ctParametersViewRemoveParameter(CMDUI &cmdui, int target_wid, _str command)
{
   // Sanity please
   if( target_wid==0 || target_wid.p_object!=OI_TREE_VIEW ) {
      return MF_GRAYED;
   }

   if( _ctViewMoveEnabled(target_wid) ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

_command void ctParametersViewRemoveParameter(int treeWid=0)
{
   treeWid=findParametersTreeOrDie(treeWid);
   if( treeWid==0 ) {
      return;
   }
   int index = treeWid._TreeCurIndex();
   if( index>0 ) {
      treeWid._TreeDelete(index);
      // Must call on_change() ourselves for the case of only 1 node in the tree,
      // so might as well call it for all cases.
      treeWid.call_event(CHANGE_SELECTED,treeWid._TreeCurIndex(),treeWid,ON_CHANGE,'w');
   }
}

void ctl_param_remove.lbutton_up()
{
   _control ctl_params;
   ctParametersViewRemoveParameter(ctl_params);
}

/**
 * Verify parameters view input.
 * <p>
 * Use _ctViewContent to retrieve a copy of the ctTemplateContent_t results.
 * <p>
 * IMPORTANT: <br>
 * Active window must be parameters view frame.
 * 
 * @param quiet (optional). Set to true to not display error messages.
 *              Defaults to false.
 * @param selectError   (optional). Set to false if you do not want the location
 *                      of the error made active.
 *                      Defaults to true.
 * @param statusMessage (optional). Set to description of error (if any).
 * 
 * @return true on success (no errors in input).
 */
boolean _ctParametersViewVerifyInput(boolean quiet=false, boolean selectError=true, _str& statusMessage=null)
{
   ctTemplateContent_t templateContent = _ctViewContent();
   templateContent.Parameters._makeempty();
   _control ctl_params;
   int index = ctl_params._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while( index>0 ) {
      _str line = ctl_params._TreeGetCaption(index);
      _str Name, Value, Prompt, PromptString;
      parse line with Name"\t"Value"\t"Prompt"\t"PromptString"\t".;
      templateContent.Parameters:[Name].Value=Value;
      templateContent.Parameters:[Name].Prompt=( Prompt != "0" );
      templateContent.Parameters:[Name].PromptString=PromptString;
      index=ctl_params._TreeGetNextSiblingIndex(index);
   }
   _control ctl_delimiter;
   templateContent.Delimiter=ctl_delimiter.p_text;
   if( templateContent.Delimiter=="" ) {
      templateContent.Delimiter=CTPARAMETER_DELIM;
   }

   // Store verified content
   _ctViewContent(&templateContent);

   // All good
   return true;
}

static void setParametersCols()
{
   // Create the grid, setup column labels
   int w1, w2, w3, w4;
   // +200 is a fudge-factor
   w3=_text_width("Prompt") + 200;
   w1=w2=w4=(p_width - w3) / 3;
   _TreeSetColButtonInfo(0,w1,0,-1,"Name");
   _TreeSetColButtonInfo(1,w2,0,-1,"Value");
   _TreeSetColButtonInfo(2,w3,0,-1,"Prompt");
   _TreeSetColButtonInfo(3,w4,0,-1,"Prompt String");
}

/**
 * Indicate whether we are in the middle of an on_change event for the parameters view.
 * Used to disallow recursion.
 * <p>
 * IMPORTANT: <br>
 * Active window must be parameters view frame.
 * 
 * @param onoff 0 = Not in an on_change event. <br>
 *              1 = In an on_change event. <br>
 *              -1 = Return current value without setting.
 * 
 * @return Previous value. Current value if -1 specified.
 */
boolean _ctParametersViewInOnChange(int onoff=-1)
{
   boolean old_onoff = _GetDialogInfoHt("inOnChange",p_window_id);
   if( onoff > -1 ) {
      _SetDialogInfoHt("inOnChange",onoff!=0,p_window_id);
   }
   return old_onoff;
}

/**
 * Initialize parameters view with parameters data.
 * <p>
 * IMPORTANT: <br>
 * Active window must be parameters view frame.
 * <p>
 * We store the content object on the active form so that outside forces
 * can update members of the object when needed. This allows all views
 * to share the same data (e.g. Template Manager).
 * 
 * @param templateFilename The template file from which details and content come.
 * @param details ctTemplateDetails_t object.
 * @param content ctTemplateContent_t object. Contains Parameters hash table
 *                used to initialize list.
 * @param hideDelimiter (optional). Set to true if you want to hide the 
 *                      Delimiter field from view and have the parameters 
 *                      tree take up the entire height of the view.
 *                      Defaults to false.
 */
void _ctParametersViewInit(_str templateFilename,
                           ctTemplateDetails_t& details,
                           ctTemplateContent_t& content,
                           boolean hideDelimiter=false)
{
   boolean old_inOnChange = _ctParametersViewInOnChange(1);

   templateFilename=strip(templateFilename,'B','"');
   templateFilename=strip(templateFilename);

   // Is the view currently read-only?
   _SetDialogInfoHt("readOnly",false,p_window_id);
   _ctParametersViewReadOnly(false);

   // All views (details, files, parameters) share this info
   _SetDialogInfoHt("ctview.templateFilename",templateFilename);
   _str templateDir = "";
   if( templateFilename!="" ) {
      templateDir=_strip_filename(templateFilename,'n');
      _maybe_strip_filesep(templateDir);
   }
   _SetDialogInfoHt("ctview.templateDir",templateDir);
   _ctViewDetails(&details);
   _ctViewContent(&content);

   // Clear the parameters so there is no confusion if there is nothing
   // selected.
   _control ctl_params;
   ctl_params._TreeDelete(TREE_ROOT_INDEX,'c');

   // Column labels
   ctl_params.setParametersCols();

   _str Delimiter = CTPARAMETER_DELIM;
   if( content.Parameters!=null ) {
      if( content.Delimiter!=null ) {
         Delimiter=content.Delimiter;
      }

      // Insert parameters
      _str Name;
      for( Name._makeempty();; ) {
         content.Parameters._nextel(Name);
         if( Name._isempty() ) {
            break;
         }
         ctTemplateContent_ParameterValue_t Param = content.Parameters:[Name];
         _str line = Name"\t"Param.Value"\t"Param.Prompt"\t"Param.PromptString;
         ctl_params._TreeAddItem(TREE_ROOT_INDEX,line,TREE_ADD_AS_CHILD,0,0,-1);
      }
      ctl_params._TreeSortCol(0);
      ctl_params._TreeTop();
   }
   _control ctl_delimiter;
   // Leave blank if using the default delimiter
   ctl_delimiter.p_text = (Delimiter == CTPARAMETER_DELIM) ? "" : Delimiter;
   ctl_delimiter._set_sel(1);
   if( hideDelimiter ) {
      // Force the parameters tree to take up entire height of view
      ctl_params.p_height=ctl_delimiter.p_y + ctl_delimiter.p_height;
      ctl_delimiter_label.p_visible=false;
      ctl_delimiter.p_visible=false;
      ctl_delimiter_note.p_visible=false;
   }

   _ctParametersViewInOnChange((int)old_inOnChange);
   // 9/30/2011 - rb
   // Cannot pass 'ctl_params._TreeCurIndex()' directly. Some kind of interpreter bug I guess.
   int index = ctl_params._TreeCurIndex();
   ctl_params.call_event(CHANGE_SELECTED,index,ctl_params,ON_CHANGE,'w');
}

/**
 * Enable/disable input in the parameters view.
 * <p>
 * IMPORTANT: <br>
 * Active window must be parameters view frame.
 * 
 * @param enable (optional). Set to false to disable the parameters view.
 *               Defaults to true.
 */
void _ctParametersViewEnable(boolean enable=true)
{
   _control ctl_params, ctl_param_add, ctl_param_edit, ctl_param_remove, ctl_delimiter;
   if( ctl_params.p_enabled!=enable ) {
      ctl_params.p_enabled=enable;
   }
   CMDUI cmdui;
   cmdui.button_wid=0;
   cmdui.inMenuBar=false;
   cmdui.menu_handle=0;
   cmdui.menu_pos=0;
   ctl_param_add.p_enabled=( enable && _ctViewAddEnabled(ctl_params));
   ctl_param_edit.p_enabled=( enable && _ctViewEditEnabled(ctl_params));
   ctl_param_remove.p_enabled=( enable && _ctViewMoveEnabled(ctl_params));
   ctl_delimiter.p_enabled=enable;

}

/**
 * Set input in the parameters view read-only.
 * <p>
 * IMPORTANT: <br>
 * Active window must be parameters view frame.
 * 
 * @param readOnly (optional). Set to false to unset read-only mode on input in the parameters view.
 *                 Defaults to true.
 */
void _ctParametersViewReadOnly(boolean readOnly=true)
{
   _control ctl_params, ctl_param_add, ctl_param_edit, ctl_param_remove, ctl_delimiter;

   _SetDialogInfoHt("readOnly",readOnly,p_window_id);

   CMDUI cmdui;
   cmdui.button_wid=0;
   cmdui.inMenuBar=false;
   cmdui.menu_handle=0;
   cmdui.menu_pos=0;
   ctl_param_add.p_enabled=_ctViewAddEnabled(ctl_params);
   // We want the user to be able to view the parameter but not edit
   ctl_param_edit.p_enabled=_ctViewEditEnabled(ctl_params);
   ctl_param_remove.p_enabled=_ctViewMoveEnabled(ctl_params);
   ctl_delimiter.p_ReadOnly=readOnly;
}


//
// _ctAddFile_form
// Used to add files to a template in the Files view.
//

defeventtab _ctAddFile_form;

void ctl_ok.on_create(_str templateFilename="",
                      _str DefaultName="",
                      _str Delimiter=CTPARAMETER_DELIM,
                      ctTemplateContent_File_t& File=null,
                      _str caption="",
                      boolean enableSource=true,
                      boolean readOnly=false)
{
   if( caption!="" ) {
      p_active_form.p_caption=caption;
   }

   _ctAddFile_form_initial_alignment();

   _SetDialogInfoHt("readOnly",readOnly);

   if( templateFilename==null ) {
      templateFilename="";
   }
   templateFilename=strip(templateFilename,'B','"');
   templateFilename=strip(templateFilename);
   _SetDialogInfoHt("templateFilename",templateFilename);

   _str templateDir = "";
   if( templateFilename==null || templateFilename!="" ) {
      templateDir=_strip_filename(templateFilename,'n');
      _maybe_strip_filesep(templateDir);
   }
   _SetDialogInfoHt("templateDir",templateDir);

   if( DefaultName==null || DefaultName=="" ) {
      // No default name to help us form target filename preview, so
      // just stick in a place-holder.
      DefaultName="input-file-name";
   }
   _SetDialogInfoHt("DefaultName",DefaultName);

   if( Delimiter==null || Delimiter=="" ) {
      Delimiter=CTPARAMETER_DELIM;
   }
   _SetDialogInfoHt("Delimiter",Delimiter);

   _control ctl_source, ctl_target, ctl_target_button, ctl_copy_to_template_dir, ctl_replace_params, ctl_browse;
   _str Filename = "";
   _str TargetFilename = "";
   boolean ReplaceParameters = true;
   if( File!=null ) {
      Filename=File.Filename;
      TargetFilename=File.TargetFilename;
      ReplaceParameters=File.ReplaceParameters;
   }
   ctl_source.p_text=Filename;
   if( !enableSource ) {
      // Probably editing a file rather than creating one
      ctl_source.p_enabled=false;
      ctl_copy_to_template_dir.p_enabled=false;
      ctl_browse.p_enabled=false;
   }
   ctl_target.p_text=TargetFilename;
   ctl_replace_params.p_value = (int)ReplaceParameters;
   ctl_source.call_event(CHANGE_OTHER,ctl_source,ON_CHANGE,'w');

   ctl_source.p_enabled= ( ctl_source.p_enabled && !readOnly );
   ctl_copy_to_template_dir.p_enabled= ( ctl_source.p_enabled && !readOnly );
   ctl_browse.p_enabled= ( ctl_source.p_enabled && !readOnly );
   ctl_target.p_enabled=!readOnly;
   ctl_target_button.p_enabled=!readOnly;
   ctl_replace_params.p_enabled=!readOnly;
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _ctAddFile_form_initial_alignment()
{
   rightAlign := ctl_preview_frame.p_x + ctl_preview_frame.p_width;
   sizeBrowseButtonToTextBox(ctl_source.p_window_id, ctl_browse.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctl_target.p_window_id, ctl_target_button.p_window_id, 0, rightAlign);
}

static boolean verifyFileFormInput(_str& src, boolean& copySrcToTemplateDir, _str& target, boolean& replaceParams)
{
   _control ctl_source, ctl_target, ctl_copy_to_template_dir, ctl_replace_params;
   src=ctl_source.p_text;
   src=strip(src,'B','"');
   src=strip(src);
   if( src=="" || !file_exists(src) ) {
      _str msg = "Missing or bad source file name. Please provide a valid source file name.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_source;
      _set_sel(1,length(p_text)+1);_set_focus();
      return false;
   }
   copySrcToTemplateDir = ( ctl_copy_to_template_dir.p_value != 0 );

   target=ctl_target.p_text;
   target=strip(target,'B','"');
   target=strip(target);
   if( target=="" ) {
      _str msg = "Missing or bad target file name. Please provide a valid target file name.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_target;
      _set_sel(1,length(p_text)+1);_set_focus();
      return false;
   }
   replaceParams = ( ctl_replace_params.p_value != 0 );

   // All good
   return true;
}

void ctl_ok.lbutton_up()
{
   if( !_GetDialogInfoHt("readOnly") ) {
      _str src, target;
      boolean copy, replace;
      if( !verifyFileFormInput(src,copy,target,replace) ) {
         // Error
         return;
      }
      _param1=src;
      _param2=copy;
      _param3=target;
      _param4=replace;
   }
   p_active_form._delete_window(0);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

#define TARGET_EXAMPLE_FORMATSPEC "Example: $fileinputname$.%s"
#define PREVIEW_FORMATSPEC "%s\n\nwould be copied to:\n\n%s"

static void updatePreview()
{
   _control ctl_source, ctl_target, ctl_copy_to_template_dir;

   _str src = ctl_source.p_text;
   src=strip(src,'B','"');
   src=strip(src);
   src=translate(src,FILESEP,FILESEP2);
   // Target example label
   _str lang = _get_extension(src);
   if( lang=="" ) {
      lang="cpp";
   }
   _str target_note = nls(TARGET_EXAMPLE_FORMATSPEC,lang);
   ctl_target_note.p_caption=target_note;

   _str target = ctl_target.p_text;
   target=strip(target,'B','"');
   target=strip(target);
   target=translate(target,FILESEP,FILESEP2);

   if( src!="" && ctl_copy_to_template_dir.p_value ) {
      // Should never get here if there is no templateDir since
      // the ctl_copy_to_template_dir checkbox would never have
      // been enabled.
      _str templateDir = _GetDialogInfoHt("templateDir");
      _maybe_append_filesep(templateDir);
      src=_strip_filename(src,'p');
      src=templateDir:+src;
   }

   // Sanity in the Preview frame please
   if( src=="" ) {
      src="[Enter a source file name]";
   }

   _str DefaultName = _GetDialogInfoHt("DefaultName");
   _str Delimiter = _GetDialogInfoHt("Delimiter");
   _str wordChars = "";
   lang = _Filename2LangId(target);
   wordChars = LanguageSettings.getWordChars(lang);
   ctTemplateContent_ParameterValue_t not_used:[];
   target=_ctProcessContentString(target,DefaultName,"location",not_used,null,Delimiter,wordChars);
   if( target=="" ) {
      target="[Enter a target file name]";
   } else {
      // Prepend with ../ if not absolute already
      if( !file_eq(target,absolute(target)) &&
          !isdrive(target) &&
          !( __NT__ && substr(target,1,2)=='\\' && length(target)==2 ) ) {
         target="location":+FILESEP:+target;
      }
   }
   src=ctl_preview_label._ShrinkFilename(src,ctl_preview_label.p_width);
   target=ctl_preview_label._ShrinkFilename(target,ctl_preview_label.p_width);
   _str text = nls(PREVIEW_FORMATSPEC,src,target);
   _control ctl_preview_label;
   ctl_preview_label.p_caption=text;
}

void ctl_source.on_change()
{
   _str src = p_text;
   src=strip(src,'B','"');
   src=strip(src);
   _str templateDir = _GetDialogInfoHt("templateDir");
   _control ctl_copy_to_template_dir;
   int copy = ctl_copy_to_template_dir.p_value;
   boolean enabled = true;
   if( templateDir!="" ) {
      _maybe_append_filesep(templateDir);
      if( file_eq(templateDir,substr(src,1,length(templateDir))) ) {
         copy=1;
         enabled=false;
      }
   } else {
      // No templateDir means it does not make sense to copy a source file
      // to the template directory.
      copy=0;
      enabled=false;
   }
   if( copy != ctl_copy_to_template_dir.p_value ) {
      ctl_copy_to_template_dir.p_value=copy;
   }
   if( enabled != ctl_copy_to_template_dir.p_enabled ) {
      ctl_copy_to_template_dir.p_enabled=enabled;
   }
   updatePreview();
}

void ctl_copy_to_template_dir.lbutton_up()
{
   updatePreview();
}

void ctl_browse.lbutton_up()
{
   _str result=_OpenDialog("-modal",
                           "Choose File", // Title
                           "", // Initial wildcards
                           def_file_types,
                           OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST,
                           "", // Default extension
                           "", // Initial filename
                           "", // Initial directory
                           "",
                           "");
   result=strip(result,'B','"');
   if( result=="" ) {
      return;
   }
   _control ctl_source;
   ctl_source.p_text=result;
}

void ctl_target.on_change()
{
   updatePreview();
}

// Used to change the substitution parameter delimiter when it differs
// from the default ($).
void _on_popup2_ctInsertSubstitution(_str menu_name, int menu_handle)
{
   if( translate(menu_name,'_','-') != "_ctTargetSubsitutions_menu" ) {
      return;
   }
   _str Delimiter = _GetDialogInfoHt("Delimiter");
   if( Delimiter == CTPARAMETER_DELIM ) {
      // Already using the default, so nothing to do
      return;
   }
   int nofitems = _menu_info(menu_handle);
   int i;
   for( i=0; i<nofitems; ++i ) {
      int mf_flags;
      _str caption, command, categories, help_command, help_message;
      _menu_get_state(menu_handle,i,mf_flags,'p',caption,command,categories,help_command,help_message);
      caption=stranslate(caption,Delimiter,CTPARAMETER_DELIM);
      command=stranslate(command,Delimiter,CTPARAMETER_DELIM);
      _menu_set_state(menu_handle,i,mf_flags,'p',caption,command,categories,help_command,help_message);
   }
}

_command void ctInsertSubstitution(_str text="")
{
   ctlinsert(text,_GetDialogInfoHt("Delimiter"));
}


//
// _ctAddParameter_form
// Used to add parameters to a template in the Parameters view.
//

defeventtab _ctAddParameter_form;

void ctl_ok.on_create(_str Name="", _str Value="", boolean Prompt=false, _str PromptString="",
                      _str caption="", boolean readOnly=false)
{
   if( caption!="" ) {
      p_active_form.p_caption=caption;
   }

   _SetDialogInfoHt("readOnly",readOnly);

   _control ctl_name, ctl_value, ctl_prompt, ctl_promptstring;
   ctl_name.p_text=Name;
   ctl_value.p_text=Value;
   ctl_prompt.p_value= (int)Prompt;
   ctl_promptstring.p_text=PromptString;
   ctl_prompt.call_event(ctl_prompt,LBUTTON_UP,'w');

   ctl_name.p_enabled=!readOnly;
   ctl_value.p_enabled=!readOnly;
   ctl_prompt.p_enabled=!readOnly;
   ctl_promptstring.p_enabled=!readOnly;
}

static boolean verifyParameterFormInput(_str& Name, _str& Value, boolean& Prompt, _str& PromptString)
{
   _control ctl_name, ctl_value, ctl_prompt, ctl_promptstring;

   Name=strip(ctl_name.p_text);
   if( Name=="" ) {
      _str msg = "Missing parameter name. Please provide a valid parameter name.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_name;
      _set_sel(1,length(p_text)+1);_set_focus();
      return false;
   }
   // If any part of the name is invalid
   if( 1 != pos('{#0'CTPARAMETER_NAME_RE'}',Name,1,'er') || pos('0') < length(Name) ) {
      _str msg = "Invalid parameter name. Please provide a valid parameter name.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_name;
      _set_sel(1,length(p_text)+1);_set_focus();
      return false;
   }

   Value=strip(ctl_value.p_text);

   Prompt= ( ctl_prompt.p_value != 0 );

   PromptString=strip(ctl_promptstring.p_text);
   PromptString=strip(PromptString,'B','"');
   PromptString=strip(PromptString);

   // All good
   return true;
}

void ctl_ok.lbutton_up()
{
   if( !_GetDialogInfoHt("readOnly") ) {
      _str Name, Value, PromptString;
      boolean Prompt;
      if( !verifyParameterFormInput(Name,Value,Prompt,PromptString) ) {
         // Error
         return;
      }
      _param1=Name;
      _param2=Value;
      _param3=Prompt;
      _param4=PromptString;
   }
   p_active_form._delete_window(0);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

