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
#include "xml.sh"
#import "complete.e"
#import "diff.e"
#import "files.e"
#import "ini.e"
#import "listbox.e"
#import "main.e"
#import "projconv.e"
#import "project.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion

#define DEFAULTPROJECTPACK "(None)"
#define PACKAGE_TABLE ctledit.p_user
#define PACKAGE_DELETED ctldelete.p_user

static int gUserTemplatesHandle;
static int gSysTemplatesHandle;

/**
 * Imports a file full of project templates.  Copies these into
 * the user templates file.  If there are templates in the
 * existing user templates file with the same template name,
 * they will be overwritten.
 *
 * @param importFile
 *
 * @return int
 */
int importProjectPacks(_str importFile)
{
   // open up the user templates file
   userHandle := _ProjectOpenUserTemplates();

   // open the import file
   importHandle := _xmlcfg_open(importFile, auto status);
   if (importHandle < 0) {
      return status;
   }

   // get the list of templates in this file
   int array[];
   _ProjectTemplatesGet_TemplateNodes(importHandle, array);

   // now go through each one and import it, please
   for (i := 0; i < array._length();++i) {

      templateName := _xmlcfg_get_attribute(importHandle, array[i], 'Name');

      // do we already have a template by this name?
      userTemplateIndex := _ProjectTemplatesGet_TemplateNode(userHandle, templateName, true);

      // now copy in the new stuff
      _xmlcfg_copy(userHandle, userTemplateIndex, importHandle, array[i], VSXMLCFG_COPY_BEFORE);

      // now delete the old one
      if (userTemplateIndex) {
         _xmlcfg_delete(userHandle, userTemplateIndex);
      }
   }

   _ProjectTemplatesSave(userHandle, '', true);
   _xmlcfg_close(userHandle);
   _xmlcfg_close(importHandle);

   return 0;
}

defeventtab _packs_form;

void _FillInPackageListControl(int usertemplates_handle,
                               int systemplates_handle,
                               boolean showAll)
{
   int wid=p_window_id;
   _control ctlProjPackTree;
   p_window_id = ctlProjPackTree;

   // Get the list of user-defined project packs first.
   // If a project pack exists as user-defined and globally defined,
   // the user-defined version in the user's project pack file
   // superceeds the global version.
   PROJECTPACKS p:[];
   p_user = p;
   GetAllProjectPacks(p, usertemplates_handle, systemplates_handle, showAll);
   p_user = p;

   fillProjectPackTree(p);

   // Fill the project package list box.
   p_window_id = wid;
}

void fillProjectPackTree(PROJECTPACKS (&p):[],)
{
   ctlProjPackTree._TreeDelete(TREE_ROOT_INDEX, "C");
   ctlProjPackTree._TreeBeginUpdate(TREE_ROOT_INDEX);
   PopulateProjectPacksTree(p);
   ctlProjPackTree._TreeEndUpdate(TREE_ROOT_INDEX);
   ctlProjPackTree._TreeTop();
}

void GetAllProjectPacks(PROJECTPACKS (&p):[], int usertemplates_handle, 
                        int systemplates_handle, boolean showAll)
{
   // Get the list of user-defined project packs first.
   // If a project pack exists as user-defined and globally defined,
   // the user-defined version in the user's project pack file
   // superceeds the global version.
   p._makeempty();
   if (usertemplates_handle>=0) {
      // 1.25.11 - sg
      // Bug 4627
      // we always want to show all the user project types
      _getProjectPackages(usertemplates_handle, p, 1, true);
   }

   // Get the list of global project packs.
   //_str filename = slick_path_search(VSCFGFILE_PRJTEMPLATES);
   if (systemplates_handle>=0) {
      _getProjectPackages(systemplates_handle, p, 0, showAll);
   }
}

/**
 * Fills in the tree with the list of project packs.  NOTE: 
 * this method does not clear or prepare the tree in any way for 
 * adding packs.  Since this method is used by different forms 
 * (For different purposes), then it is up to the caller to 
 * prepare the tree. 
 * 
 * @param p      Hashtable of project packs.
 */
void PopulateProjectPacksTree(PROJECTPACKS (&p):[])
{
   typeless i;
   int callbackIndex = find_index("_oem_new_project_group_callback",PROC_TYPE);
   for (i._makeempty();;) {
      p._nextel(i);
      if (i._isempty()) break;

      _str packName = i;

      status := 0;
      // First check to see if an OEM has a callback to group these together
      // _oem_new_project_group_callback has to return 1 true if it
      // processed the package name, 0 if this function should process
      // it.
      if ( callbackIndex && index_callable(callbackIndex) ) {
         status = call_index(packName,callbackIndex);
      }
      // 
      // special cases for java, c/c++, microsoft, and python
      if (!status) {
         if (pos("Microsoft", packName)) {
            // we add this as a node itself and also as a choice for C++
            _TreeAddItem(TREE_ROOT_INDEX, packName, TREE_ADD_AS_CHILD | TREE_ADD_SORTED_CI, 0, 0, -1);
            addToGroupedNode("C/C++", packName);
         } else if (pos("Java", packName)) {
            addToGroupedNode("Java", packName);
         } else if (pos("C++", packName)) {
            addToGroupedNode("C/C++", packName);
         } else if (pos("Python", packName)) {
            addToGroupedNode("Python", packName);
         } else if (packName :== "QTMakefile") {
#if __UNIX__
            //_TreeAddItem(TREE_ROOT_INDEX, packName, TREE_ADD_AS_CHILD | TREE_ADD_SORTED_CI, 0, 0, -1);
#endif
         } else {
            _TreeAddItem(TREE_ROOT_INDEX, packName, TREE_ADD_AS_CHILD | TREE_ADD_SORTED_CI, 0, 0, -1);
         }
      }
   }
}

/**
 * Creates a parent node in the tree with the given caption name 
 * (if one does not exist).  Adds a new node (item) as child of 
 * parent (caption). 
 * 
 * @param caption Caption of parent item
 * @param item    Caption of new child to be added to parent
 */
void addToGroupedNode(_str caption, _str item)
{
   int index = _TreeSearch(TREE_ROOT_INDEX, caption);
   if (index < 0) {  // add group parent node
      index = _TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD | TREE_ADD_SORTED_CI, 0, 0, 0);
   }
   _TreeAddItem(index, item, TREE_ADD_AS_CHILD | TREE_ADD_SORTED_CI, 0, 0, -1);
}

void ctlok.on_create()
{
   PACKAGE_DELETED=0;
   gUserTemplatesHandle=_ProjectOpenUserTemplates();
   gSysTemplatesHandle=_ProjectOpenTemplates();
   _FillInPackageListControl(gUserTemplatesHandle,gSysTemplatesHandle,true);
   // Update the pack delete button state.
   updatePackDeleteButtonState();
   updatePackEditButtonState();
}

void ctlok.lbutton_up()
{
   if (checkForModifiedOnClose(0)) {
      return;
   }
   p_active_form._delete_window(0);
}

void ctlPkgList.lbutton_double_click()
{
   ctledit.call_event(ctledit,LBUTTON_UP);
}

int ctlnew.lbutton_up()
{
   // Prompt for a new project pack name.
   _str defaultSavePackName = "";
   PROJECTPACKS p:[];
   p = ctlProjPackTree.p_user;

   typeless result=show('-modal _new_package_form',p);
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _str newname=_param1;
   if (!ctlProjPackTree._TreeSearch(TREE_ROOT_INDEX, newname, 'IT')) {
      _message_box("This package name already exists");
      return(1);
   }

   // Save the current selected pack.
   _str oldSelectedPack = ctlProjPackTree._TreeGetCurCaption();
   if (oldSelectedPack == "") {
      oldSelectedPack = DEFAULTPROJECTPACK;
   }
   if (gUserTemplatesHandle<0) {
      gUserTemplatesHandle=_ProjectCreateUserTemplates(_ConfigPath():+VSCFGFILE_USER_PRJTEMPLATES);
   }

   int Node=_xmlcfg_set_path(gUserTemplatesHandle,VPTX_TEMPLATES);
   int NewNode=_xmlcfg_copy(gUserTemplatesHandle,Node,(p:[_param2].User)?gUserTemplatesHandle:gSysTemplatesHandle,p:[_param2].Node,VSXMLCFG_COPY_AS_CHILD);
   if (!p:[_param2].User) {
      _ProjectTemplateExpand(gSysTemplatesHandle,gUserTemplatesHandle,true);
   }

   _xmlcfg_set_attribute(gUserTemplatesHandle,NewNode,'Name',newname);

   // Create a new empty pack in hash.
   p:[newname].Modified= 1;
   p:[newname].User= 1;
   p:[newname].Node=NewNode;
   ctlProjPackTree.p_user = p;

   // Reinit the pack list.
   ctlProjPackTree.fillProjectPackTree(p);

   // Select current pack.
   selectCurrentPack(newname);
   // Start the project pack edit dialog.
   // If the user cancelled the project pack edit dialog, remove the
   // the newly created project pack from the hash.
   int status = call_event(_control ctledit, LBUTTON_UP);
   if (status == 1) { // user-cancelled
      p._deleteel(newname);
      ctlProjPackTree.p_user = p;
      ctlProjPackTree.fillProjectPackTree(p);
      selectCurrentPack(oldSelectedPack);
      return(0);
   }
   return(0);
}
static int countModifiedPackages()
{
   int modcount = 0;
   PROJECTPACKS p:[];
   p = ctlProjPackTree.p_user;
   typeless ii;
   for (ii._makeempty();;) {
      p._nextel(ii);
      if (ii._isempty()) break;
      if (!p:[ii].User) continue;
      if (!p:[ii].Modified) continue;
      ++modcount;
   }
   return(modcount);
}
// Check the list of project packs for modification.
// Retn: 0 for nothing modified
//       1 for user-cancelled
//       3 can't update user project pack file
static int checkForModifiedOnClose(boolean doCancel)
{
   // If there is any user-defined project pack modified, prompt the user.

   // Prompt the user.
   int status=0;
   if (countModifiedPackages() || PACKAGE_DELETED) {
      if (doCancel) {
         status = prompt_for_save(nls("You have modified the project packages.\n\nSave changes?"));
         if (status== IDNO) {
            p_active_form._delete_window();
            return(1);
         }
         if (status != IDYES) {
            return(1); // user cancelled
         }
      }
      // Always write to the user project pack file.
      status = _ProjectTemplatesSave(gUserTemplatesHandle);
      if (status) {
         return(3);
      }
   }
   return(0);
}
int ctlcancel.lbutton_up()
{
   // Check for modified project packs.
   if (checkForModifiedOnClose(1)) {
      return(0);
   }

   // Quit form.
   p_active_form._delete_window(0);
   return(0);
}
static void updatePackDeleteButtonState()
{
   // first make sure this node has no children
   if (ctlProjPackTree._TreeDoesItemHaveChildren(ctlProjPackTree._TreeCurIndex())) {
      ctldelete.p_enabled = false;
      return;
   }

   // Get the selected item in the package list.
   _str packName = ctlProjPackTree._TreeGetCurCaption();
   parse packName with packName ' (Modified)';
   if (packName == "") return; // nothing selected

   // If project pack is not user-defined, disable Delete.
   PROJECTPACKS p:[];
   p = ctlProjPackTree.p_user;
   if (VendorPack(packName)) {
      if (ctldelete.p_enabled == true) ctldelete.p_enabled = false;
   } else {
      if (ctldelete.p_enabled == false) ctldelete.p_enabled = true;
   }
}

static void updatePackEditButtonState()
{
   // first make sure this node has no children
   if (ctlProjPackTree._TreeDoesItemHaveChildren(ctlProjPackTree._TreeCurIndex())) {
      ctledit.p_enabled = false;
   } else {
      ctledit.p_enabled = true;
   }
}

static int VendorPack(_str packName)
{
   PROJECTPACKS packTable:[];
   packTable = ctlProjPackTree.p_user;
   typeless i;
   for (i._makeempty();;) {
      packTable._nextel(i);
      if (i._isempty()) break;
      if (i==packName) {
         return((int)!packTable:[i].User);
      }
   }
   return(0);
}

void ctlProjPackTree.on_change(int reason)
{
   updatePackDeleteButtonState();
   updatePackEditButtonState();
}

// Allow the user to edit a project pack.
// Retn: 0 OK and proceed as normal
//       1 user-cancelled
int ctledit.lbutton_up()
{
   // Get the selected item in the package list.
   _str packName = ctlProjPackTree._TreeGetCurCaption();
   if (packName == "") return(0); // nothing selected

   // Show the project pack information.
   PROJECTPACKS p:[];
   p = ctlProjPackTree.p_user;

   int handle=_xmlcfg_create('',VSENCODING_UTF8);
   int Node=_xmlcfg_copy(handle,TREE_ROOT_INDEX,(p:[packName].User)?gUserTemplatesHandle:gSysTemplatesHandle,p:[packName].Node,VSXMLCFG_COPY_AS_CHILD);
   _xmlcfg_set_name(handle,Node,VPJTAG_PROJECT);
   _ProjectTemplateExpand(gSysTemplatesHandle,handle,true);
   typeless result=show('-mdi -modal -xy _project_form',packName,handle,'',false,false,true);
   if (result=='') {
      _xmlcfg_close(handle);
      return(1); // user-cancelled
   }
   int oldNode=_ProjectTemplatesGet_TemplateNode(gUserTemplatesHandle,packName,true);
   int ProjectNode=_xmlcfg_set_path(handle,"/"VPJTAG_PROJECT);

   int NewNode=_xmlcfg_copy(gUserTemplatesHandle,oldNode,handle,ProjectNode,0);
   _xmlcfg_set_name(gUserTemplatesHandle,NewNode,VPTTAG_TEMPLATE);

   _xmlcfg_delete(gUserTemplatesHandle,oldNode);

   _xmlcfg_close(handle);

   p:[packName].User = 1;
   p:[packName].Modified = 1;
   p:[packName].Node=NewNode;
   ctlProjPackTree.p_user = p;
   return(0);
}

// Add the project pack names in the hash to the pack list box.
static void fillProjectPackList(PROJECTPACKS (&p):[])
{
   _lbclear();
   typeless i;
   for (i._makeempty();;) {
      p._nextel(i);
      if (i._isempty()) break;
      _lbadd_item(i);
   }
   _lbsort("AI");
   _lbremove_duplicates('i');
}

// Select the current pack in the project pack list.
static void selectCurrentPack(_str packName)
{
   // Select the specified pack name. If match is not found, select
   // the first pack name.
   _str nameOnly;
   parse packName with nameOnly ' (Modified)';
   int found = 0;

   int index = ctlProjPackTree._TreeSearch(TREE_ROOT_INDEX, nameOnly, "IPT");

   // we found it!
   if (!index) {
      ctlProjPackTree._TreeTop();
   }  
   ctlProjPackTree._TreeSetCurIndex(index);
   updatePackDeleteButtonState();
}
int ctldelete.lbutton_up()
{
   // Can only delete user-defined project packs.
   _str currentPack = ctlProjPackTree._TreeGetCurCaption();
   parse currentPack with currentPack ' (Modified)';
   PROJECTPACKS p:[];
   p = ctlProjPackTree.p_user;
   if (!p:[currentPack].User) {
      _message_box(nls("Only user-defined project packs can be deleted."));
      return(0);
   }
   PACKAGE_DELETED=1;

   int Node=_ProjectTemplatesGet_TemplateNode(gUserTemplatesHandle,currentPack);
   if (Node>=0) {
      _xmlcfg_delete(gUserTemplatesHandle,Node);
   }

   ctlProjPackTree._TreeDelete(ctlProjPackTree._TreeCurIndex());
   _str nextPack = ctlProjPackTree._TreeGetCurCaption();
   if (nextPack == "") nextPack = DEFAULTPROJECTPACK;

   // Remove pack from hash.
   p._deleteel(currentPack);

   // Reinit the pack list.
   ctlProjPackTree.p_user = p;
   ctlProjPackTree.fillProjectPackTree(p);

   // Select current pack.
   selectCurrentPack(nextPack);
   return(0);
}

/**
 * Should this package (template) be included in the list
 */
boolean _ignoreProjectPackage(int handle, int templateNode,boolean showAll)
{
   if(handle < 0) return false;

   // see if this template should be allowed on this platform
   _str platforms = _xmlcfg_get_attribute(handle, templateNode, "Platforms");
   platforms = strip(platforms);

   // if platforms is blank, it is used for all
   if(platforms != "") {
      if(__UNIX__) {
         // check for "Unix" in platform list
         if(!pos("\"Unix\"", platforms)) return false;
      } else {
         // check for "Windows" in platform list
         if(!pos("\"Windows\"", platforms)) return false;
      }
   }

   // see if this template should be hidden
   if (!showAll) {
      _str showOnMenu = _xmlcfg_get_attribute(handle, templateNode, "ShowOnMenu");
      if (showOnMenu == "0") return false;
   }

#if !__OS390__
   // remove OS/390 templates
   _str name = _xmlcfg_get_attribute(handle, templateNode, "Name");
   if (!_DataSetSupport()) {
      if (pos("OS/390", name)) return false;
   }
#endif

   return true;
}

// Search thru the specified file for a list of section names and
// append section names into the list. Duplicate copies are removed.
// Retn: 0 OK, !0 can't read file
static int _getProjectPackages(int handle, PROJECTPACKS (&p):[], int user, boolean showAll)
{
   // Loop thru the entire ini file and get all sections.
   // Append new sections to the end of the list.
   _str line, sectionName;
   int i,array[];
   _ProjectTemplatesGet_TemplateNodes(handle,array);
   for (i=0;i<array._length();++i) {
      // Find the start of a section. [sectionName]
      sectionName=_xmlcfg_get_attribute(handle,array[i],'Name');

      // see if this template should be shown
      if(!_ignoreProjectPackage(handle, array[i],showAll)) continue;

      // Ignore a global project pack if a version with the same name
      // already exists in the list.
      if (!user) {
         int found = 0;
         typeless ii;
         for (ii._makeempty();;) {
            p._nextel(ii);
            if (ii._isempty()) break;
            if (lowcase(ii) == lowcase(sectionName)) {
               found = 1;
               break;
            }
         }
         if (found) continue;
      }

      p:[sectionName].Node= array[i];
      p:[sectionName].User = user; // flag a user-defined scheme
      p:[sectionName].Modified = 0; // initially unmodified
   }
   return(0);
}
void _project_expand_copy_from_array(_str (&list)[])
{
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   int i;
   for (i=0;i<list._length();++i) {
      insert_line(list[i]);
   }
   _project_expand_copy_from_view(temp_view_id);

   _str line='';
   top();up();
   for (i=0;;++i) {
      if (down()) {
         break;
      }
      get_line(line);
      list[i]=line;
   }
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
}
void _project_expand_copy_from_view(int view_id)
{
   int temp_view_id=0;
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(view_id);
   save_pos(auto p);

   typeless status=0;
   _str name="";
   _str line="";
   _str value="";
   top();up();
   for (;;) {
      if (down()) {
         break;
      }
      get_line(line);
      parse line with name'='value;
      if (strieq(name,'copy_from')) {
         if (!_delete_line()) {
            up();
         }
         status=_ini_get_section(get_env("VSROOT"):+VSCFGFILE_PRJPACKS,value,temp_view_id);
         if (status) {
            // if not found, check for usrpacks
            _str usrfilename = usercfg_path_search('usrpacks.slk');
            if(usrfilename != "") {
               status = _ini_get_section(usrfilename,value,temp_view_id);
            }

            // if still not found, report the error
            if(status) {
               _message_box(nls("copy_from package '%s' does not exists",value));
               return;
            }
         }
         activate_window(temp_view_id);
         int Noflines=p_Noflines;
         int buf_id=p_buf_id;
         activate_window(view_id);
         int orig_line=p_line;
         _buf_transfer(buf_id,1,Noflines);
         p_line=orig_line;
         _delete_temp_view(temp_view_id);activate_window(view_id);
      } else {
         int linenum=p_line;
         up();_end_line();
         status=search('^'_escape_re_chars(name)'=','@rhi-');
         if (!status) {
            replace_line(line);
            p_line=linenum;
            if (_delete_line()) break;
            up();
         } else {
            p_line=linenum;
         }
      }
   }
   restore_pos(p);
   activate_window(orig_view_id);
}

defeventtab _new_package_form;
void ctlok.lbutton_up()
{
   _param2=ctlcopy_settings_from.p_text;
   _param1=ctlnew_package_name.p_text;
   if (substr(_param1,1,1)=='.') {
      ctlnew_package_name._text_box_error("Package name may not start with a period character");
      return;
   }
   if (pos('[\[\];]',_param1,1,'r')) {
      ctlnew_package_name._text_box_error("Package name may not contain the characters [, ], or ;");
      return;
   }
   if (_param1=='') {
      ctlnew_package_name._text_box_error("Invalid package name");
      return;
   }
   p_active_form._delete_window(1);
}
void ctlok.on_create(PROJECTPACKS p:[])
{
   ctlcopy_settings_from.fillProjectPackList(p);
   ctlcopy_settings_from._lbtop();
   ctlcopy_settings_from.p_text=ctlcopy_settings_from._lbget_text();
}
