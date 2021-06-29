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
#include "tagsdb.sh"
#include "project.sh"
#import "stdprocs.e"
#import "stdcmds.e"
#import "wkspace.e"
#import "projconv.e"
#import "picture.e"
#import "treeview.e"
#import "guicd.e"
#import "listbox.e"
#import "ptoolbar.e"
#import "main.e"
#import "project.e"
#import "recmacro.e"
#import "fileproject.e"
#import "tags.e"
#import "vchack.e"
#import "menu.e"
#import "menu.e"
#import "vc.e"
#import "mprompt.e"
#import "projutil.e"
#import "actionscript.e"
#import "ini.e"
#import "cutil.e"
#import "xcode.e"
#import "compile.e"
#import "xmlcfg.e"
#import "diff.e"
#import "complete.e"
#import "dir.e"
#import "files.e"
#import "saveload.e"
#import "setupext.e"
#import "util.e"
#import "packs.e"
#endregion

static int  gUserTemplatesHandle;
static int  gSysTemplatesHandle;
static const OTHER_PROJ_PACK_NAME=   '(Other)';

static _str MRUProjectTypes[];
static _str MRUDocModes[];


static _str LBDIVIDER = "------------------------------------------------------";

struct PROJECT_TEMPLATE_INFO {
    bool m_hasExecutable;
    bool m_AlwaysCreateDirectoryFromProjectName;
    bool m_DisableAddToWorkspace;
};

static void AddMacroRecordingForHashtab(_str HashTab:[],_str varname)
{
   _macro_append('_str 'varname':[];');
   _macro_append(varname'._makeempty();');
   typeless i;
   for (i._makeempty();;) {
      HashTab._nextel(i);
      if (i._isempty()) break;
      if (HashTab._indexin(i)) {
         _macro_append(varname':['_quote(i)']='_quote(HashTab:[i])';');
      } else {
         _macro_append(varname':['_quote(i)"]='';");
      }
   }
}
/**
 * Determines which project types require executable names.  Fills up a table
 * with this information.
 *
 * @param usertemplates_handle      handle to system project templates file
 * @param table                     table to be filled:  if a project type
 *                                  requires an executable name, true will be
 *                                  mapped to the project name.  otherwise, the
 *                                  project type may be missing or mapped to
 *                                  false.
 */
static void _FillProjectTypeExecutableTable(int systemplates_handle, int usertemplates_handle)
{
   PTR_PROJECT_TYPES_EXECUTABLE(null);
   PROJECT_TEMPLATE_INFO table:[];
   table._makeempty();
   GetProjectTypeExecutables(systemplates_handle, table);
   if (usertemplates_handle >= 0) {
      GetProjectTypeExecutables(usertemplates_handle, table);
   }
   PTR_PROJECT_TYPES_EXECUTABLE(table);
}
/**
 * Loads a hashtable with information regarding whether the project types
 * contained in the file specified by the handle require executable names.
 *
 * @param handle                    handle to template file
 * @param table                     table to be filled
 */
static void GetProjectTypeExecutables(int handle, PROJECT_TEMPLATE_INFO (&table):[])
{
   // search for the OutputFile attribute
   int attrNode;
   _str foundNodes[];

   _xmlcfg_find_simple_array(handle, "/Templates/Template", foundNodes);
   foreach (attrNode in foundNodes) {
       projType := _xmlcfg_get_attribute(handle, attrNode, 'Name');
       a:=_xmlcfg_get_attribute(handle,attrNode,'AlwaysCreateDirectoryFromProjectName');
       table:[projType].m_hasExecutable = false;
       table:[projType].m_AlwaysCreateDirectoryFromProjectName = (a:==1);
       a=_xmlcfg_get_attribute(handle,attrNode,'DisableAddToWorkspace');
       table:[projType].m_DisableAddToWorkspace = (a:==1);
   }

   ss := "Templates/Template/Config/@OutputFile";

   _xmlcfg_find_simple_array(handle, ss, foundNodes);
   foreach (attrNode in foundNodes) {
      outputFile := _xmlcfg_get_value(handle, attrNode);
      if (outputFile != '') {
         parent := _xmlcfg_get_parent(handle, attrNode);      // get the Config node
         parent = _xmlcfg_get_parent(handle, parent);    // get the Template node

         projType := _xmlcfg_get_attribute(handle, parent, 'Name');
         a:=_xmlcfg_get_attribute(handle,parent,'DisableExeName');
         if (a:!=1) {
             table:[projType].m_hasExecutable = true;
         }
      }
   }

   //ss = "Templates/Template/Config/Menu/Target/Exec[contains(@CmdLine,'%&lt;e')]";
   ss = "Templates/Template/Config/Menu/Target/Exec[contains(@CmdLine,'%<e')]";
   _xmlcfg_find_simple_array(handle, ss, foundNodes);
   foreach (attrNode in foundNodes) {
       int parent;
       parent = _xmlcfg_get_parent(handle, attrNode);      // get the Target node
       parent = _xmlcfg_get_parent(handle, parent);      // get the Menu node
       parent = _xmlcfg_get_parent(handle, parent);      // get the Config node
       parent = _xmlcfg_get_parent(handle, parent);    // get the Template node

       projType := _xmlcfg_get_attribute(handle, parent, 'Name');
       a:=_xmlcfg_get_attribute(handle,parent,'DisableExeName');
       if (a:!=1) {
           table:[projType].m_hasExecutable = true;
       }
   }

}
static void FillInPrjName(bool HadButtonChange=false)
{
   if (ctladd_to_workspace.p_enabled) {
      if (ctladd_to_workspace.p_value) {
         _str BaseName=_workspace_filename;
         ctlProjectNewDir.p_text=_strip_filename(BaseName,'N');
         PROJECTNEWDIR_MODIFY(0);
      } else {
         _str wroot=GetWorkspaceRoot();
         if (wroot!='') {
            ctlProjectNewDir.p_text=wroot;
            PROJECTNEWDIR_MODIFY(0);
         }
      }
   } else {
      _str currentDir = getcwd();
      _maybe_append_filesep(currentDir);
      ctlProjectNewDir.p_text = currentDir;
      PROJECTNEWDIR_MODIFY(0);
   }
}



defeventtab _workspace_new_form;
static _str DEPLIST_STRIPPED_NAMES(...):[] {
   if (arg()) ctldeplist.p_user=arg(1);
   return ctldeplist.p_user;
}
static _str PROJECT_STRIPPED_NAMES(...):[] {
   if (arg()) ctladd_to_project_name.p_user=arg(1);
   return ctladd_to_project_name.p_user;
}
static _str WORKSPACE_NEW_OPTION(...) {
   if (arg()) p_active_form.p_user=arg(1);
   return p_active_form.p_user;
}
static const NEW_PROJ_WIZARD_TIMER=   'NewProjectWizardTimer';
// Returns pointer to value but takes value (not pointer to value)
typedef PROJECT_TEMPLATE_INFO (*PPROJECT_TEMPLATE_INFO):[];
static PPROJECT_TEMPLATE_INFO PTR_PROJECT_TYPES_EXECUTABLE(...) {
   if (arg()) ctlcustomize.p_user=arg(1);
   return &ctlcustomize.p_user;
}
static int PROJECTNEWDIR_MODIFY(...) {
   if (arg()) ctlProjectNewDir.p_user=arg(1);
   return ctlProjectNewDir.p_user;
}
static bool project_orig_add_to_workspace_enable(...) {
    if (arg()) ctladd_to_workspace.p_user=arg(1);
    return ctladd_to_workspace.p_user;
}
static bool MUST_SAVE_NEW_FILES(...) {
    if (arg()) ctlencoding.p_user=arg(1);
    return ctlencoding.p_user;
}
static int PUSER_IGNORE_DIRECTORY_CHANGE(...) {
   if (arg()) ctldirectory.p_user=arg(1);
   return ctldirectory.p_user;
}
static int PUSER_IGNORE_FILENAME_CHANGE(...) {
   if (arg()) ctlfilename.p_user=arg(1);
   return ctlfilename.p_user;
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _workspace_new_form_initial_alignment()
{
   // file tab
   sizeBrowseButtonToTextBox(ctldirectory.p_window_id, ctlBrowsedir.p_window_id, 0,
                             ctlfilename.p_x_extent);

   // project tab
   sizeBrowseButtonToTextBox(ctlProjectNewDir.p_window_id, ctlBrowseCD.p_window_id, 0,
                             _new_prjname.p_x_extent);
   sizeBrowseButtonToTextBox(ctlinclude_label.p_window_id, ctlinclude_help.p_window_id);
   sizeBrowseButtonToTextBox(ctlexclude_label.p_window_id, ctlexclude_help.p_window_id);

   // workspace tab
   sizeBrowseButtonToTextBox(ctlnew_workspace_dir.p_window_id, ctlcommand1.p_window_id, 0,
                             ctlnew_workspace_name.p_x_extent);

}

ctlProjTree.on_change(int reason)
{
   if (reason == CHANGE_SELECTED) {
      packageName := ctlProjTree._TreeGetCurCaption();
      if (CheckMSProjectType(packageName)){
         // see about possibly disabling the executable name
         hasExecutableName := false;
         if (*PTR_PROJECT_TYPES_EXECUTABLE() != null && PTR_PROJECT_TYPES_EXECUTABLE()->_indexin(packageName)) {
            hasExecutableName = PTR_PROJECT_TYPES_EXECUTABLE()->:[packageName].m_hasExecutable;
         }

         ctlExecutableName.p_enabled = ctlExecutableLabel.p_enabled = hasExecutableName;
         if (hasExecutableName && ctlExecutableName.p_text == '') {
            ctlExecutableName.p_text = _strip_filename(_new_prjname.p_text, 'pe');
         }
      } else {
         ctlExecutableName.p_enabled = ctlExecutableLabel.p_enabled = false;
      }
      UpdateReadOnlyLocation();
   }
}

void ctl_new_proj_wizard.lbutton_up(bool manual = false)
{
   // show the wizard
   result := p_active_form.show('-modal -xy _new_project_wizard_form');

   if (result == IDOK) {
      // select things based on what user said
      // if there is a second param, then we try and find it
      searchItem := _param1;
      index := ctlProjTree._TreeSearch(TREE_ROOT_INDEX, searchItem, 'T');
      if (index > 0) {
         ctlProjTree._TreeSetCurIndex(index);
         ctlProjTree._set_focus();
      } else {
         index = ctlProjTree._TreeSearch(TREE_ROOT_INDEX, OTHER_PROJ_PACK_NAME, 'T');
         ctlProjTree._TreeSetCurIndex(index);
         ctlProjTree._set_focus();
      }

   } else if (result == IDIGNORE || manual) {
      // close this form, too
      p_active_form._delete_window();
   }
}


/**
 * Checks to see if the package name is a type that SlickEdit
 * can create on its own.  Some Microsoft project types cannot
 * be created using SlickEdit.  If the project type is one of
 * these MS types, then the function displays a message to the
 * user.
 *
 * @param packageName
 *               the project type to check
 *
 * @return whether the project type is one SlickEdit can create
 */
bool CheckMSProjectType(_str packageName)
{
   msg := "";
   if ( strieq(packageName,"Microsoft Visual C++ for 32 bit Windows") ) {
      msg="If you are using Visual C++ version 5.0 or newer, create your workspace in Visual C++. Then open your Visual C++ workspace from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
   } else if ( strieq(packageName,"Microsoft Visual C++ for 32 bit Windows >= 6.0") ) {
      msg="If you are using Visual C++ version 6.0 or newer, create your workspace/solution in Visual C++. Then open your Visual C++ workspace from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
   } else if ( strieq(substr(packageName,1,length("Microsoft Visual Studio")),"Microsoft Visual Studio") ) {
         // Being very lazy here by just checking the first part of the package string, but it keeps us from
         // having to check the 6 or more possibilities explicitly.
      msg="If you are using Visual Studio, create your workspace/solution in Visual Studio. Then open your Visual Studio workspace/solution from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
   }
   if ( msg != "" ) {
          // This is not a package we can create on our own, so advise the user
       _message_box(msg, "", MB_OK | MB_ICONINFORMATION);
       return false;
   }
   return true;
}

void ctlcustomize.lbutton_up()
{
   // remember which package was selected before customization
   selectedItem := ctlProjTree._TreeGetCurCaption();

   if (gUserTemplatesHandle>=0) {
      _xmlcfg_close(gUserTemplatesHandle);
   }
   show('-modal _packs_form');

   if(_find_formobj('_workspace_new_form','n')){
      gUserTemplatesHandle=_ProjectOpenUserTemplates();
      _FillInProjectTreeControl(gUserTemplatesHandle,gSysTemplatesHandle,false);
      _FillProjectTypeExecutableTable(gSysTemplatesHandle, gUserTemplatesHandle);


      // change the selection back to the package that was selected before customization
      int status = ctlProjTree._TreeSearch(TREE_ROOT_INDEX, selectedItem, "T");//ctlPkgList._lbsearch(selectedItem);
      if (status >= 0) {
         ctlProjTree._TreeSetCurIndex(status);
      }
   }
}
void ctlcustomize.on_destroy()
{
   if (gUserTemplatesHandle>=0) {
      _xmlcfg_close(gUserTemplatesHandle);
   }
   if (gSysTemplatesHandle>=0) {
      _xmlcfg_close(gSysTemplatesHandle);
   }
}

void ctlnew_workspace_name.on_change()
{
   _str wroot=GetWorkspaceRoot();
   if (wroot!='') {
      ctlnew_workspace_dir.p_text=strip(ctlnew_workspace_dir.p_text,'B','"');
      if (ctlnew_workspace_dir.p_text=="" || _file_eq(_strip_filename(ctlnew_workspace_dir.p_text,'N'),wroot)) {
         ctlnew_workspace_dir.p_text=wroot:+ctlnew_workspace_name.p_text;
      }
   }
}
void ctlBrowseCD.lbutton_up()
{
   _str olddir=getcwd();
   _str path = _ChooseDirDialog("",p_prev.p_text,"",CDN_ALLOW_CREATE_DIR|CDN_PATH_MUST_EXIST);
   chdir(olddir,1);
   if ( path=='' ) {
      return;
   }
   p_prev.p_text=path;
}

ctlProjectNewDir.on_change()
{
   PROJECTNEWDIR_MODIFY(1);

   UpdateReadOnlyLocation();
}

static _str CreateReadOnlyLocation(bool checkAlways=false)
{
    Always := false;
    if (checkAlways) {
        packageName := ctlProjTree._TreeGetCurCaption();

        // see about possibly disabling the executable name
        if (CheckMSProjectType(packageName)) {
            if (*PTR_PROJECT_TYPES_EXECUTABLE() != null && PTR_PROJECT_TYPES_EXECUTABLE()->_indexin(packageName)) {
               Always = PTR_PROJECT_TYPES_EXECUTABLE()->:[packageName].m_AlwaysCreateDirectoryFromProjectName;
            }
        }
    }
   text := strip(ctlProjectNewDir.p_text,'B','"');

   if (ctlCreateProjDir.p_value || Always) {
      _maybe_append_filesep(text);
      text :+= _new_prjname.p_text;
   }
   _maybe_append_filesep(text);

   return text;
}

static void UpdateReadOnlyLocation()
{
   // _chr(13) = newline in label
   ctlROLocation.p_caption = 'Files will be located at:':+ _chr(13) :+
      ctlROLocation._ShrinkFilename(CreateReadOnlyLocation(true), ctlROLocation.p_width);
   disableAddToWorkspace := false;
    packageName := ctlProjTree._TreeGetCurCaption();

    // see about possibly disabling the executable name
    if (CheckMSProjectType(packageName)) {
        if (*PTR_PROJECT_TYPES_EXECUTABLE() != null && PTR_PROJECT_TYPES_EXECUTABLE()->_indexin(packageName)) {
           disableAddToWorkspace = PTR_PROJECT_TYPES_EXECUTABLE()->:[packageName].m_DisableAddToWorkspace;
        }
    }
    if (disableAddToWorkspace) {
        project_orig_add_to_workspace_enable(ctladd_to_workspace.p_enabled);
        ctladd_to_workspace.p_enabled=false;
        if (ctladd_to_workspace.p_value) {
            ctlcreate_new_workspace.p_value=1;
            ctladd_to_workspace.p_value=0;
        }
    } else {
        if (isinteger(project_orig_add_to_workspace_enable())) {
            ctladd_to_workspace.p_enabled=project_orig_add_to_workspace_enable();
        }
    }
}

void ctlDocModes.lbutton_double_click()
{
   _param1 =_param2 = _param3 = _param4 ='';
   _param5=0;
   _param6 = ctlDocModes._lbget_seltext();

   ctlok.call_event(ctlok,LBUTTON_UP);
}


static const NEW_FILE_TAB=      0;
static const NEW_PROJECT_TAB=   1;
static const NEW_WORKSPACE_TAB= 2;
void ctlok.lbutton_up()
{
   _macro('m',_macro('s'));
   creatingFromInvocationDirectory := ctlinclude_filespecs.p_visible;
   wid := 0;
   if (ctl_gn_tab.p_ActiveTab==NEW_FILE_TAB) {
      Filename := strip(strip(ctlfilename.p_text),'B','"');
      ProjectName := "";
      Path := _strip_filename(Filename,'N');
      if (Path=='') {
         Path=ctldirectory.p_text;
      } else {
         Path=absolute(Path);
         Filename=_strip_filename(Filename,'P');
      }
      modeName := "";


      _maybe_append_filesep(Path);
      if (def_unix_expansion) {
         Path = _unix_expansion(Path);
      }

      if (ctlDocModes.p_text != '') {
         modeName=ctlDocModes._lbget_text();
         if (modeName == "Automatic") {
            modeName = HandleAutomaticDocumentMode(Filename);
         }
         if (modeName == "") {
            return;
         }
      } else if ( Filename=='' ) {
         // Here we try to guess that the user wants the same file type
         // as the current buffer.  Since nothing is selected this is a reasonable
         // guess.
         wid=_mdi.p_child;
         if (wid && wid._isEditorCtl(false)) {
            modeName=ctlDocModes._lbget_text();
         }
      }

      // verify extension and doc mode match.
      if (modeName != "Fundamental" && modeName != "Plain Text" && modeName != "Automatic") {
         _str ext = _get_extension(Filename);
         if (ext != "") {
            _str lang = _Ext2LangId(ext);
            if (lang == '') {
               lang = _Ext2LangId(lowcase(ext));
            }
            if (!strieq(_LangGetModeName(lang), modeName)) {
               // warn user about mismatched extensions (provided they have the warning turned on).
               if (def_warn_mismatched_ext) {
                  _str msg = "Filename extension, "ext", does not match selected Document Mode, "modeName".  Continue?";
                  int result = textBoxDialog("Mismatched Extensions",
                       0,                                         // Flags
                       0,                                         // width
                      "",                                         // help item
                      "Yes,No\t-html "msg,                        // buttons and captions
                      "",                                         // Retrieve Name
                      "-CHECKBOX Warn about mismatched extensions.:1" );
                  // check for warning checkbox (0=unchecked, 1=checked)
                  def_warn_mismatched_ext = (_param1 == 1);
                  _config_modify_flags(CFGMODIFY_DEFVAR);
                  if (result != 1/*Yes*/) {   /*button 1, aka Yes*/
                     return;
                  }
               }
            }
         }
      }

      if (Filename=='') {
         _param1='';
      } else {
         _param1=Path:+Filename;
      }

      if (ctladd_to_project.p_enabled && ctladd_to_project.p_value) {
         _str StrippedNames:[];
         StrippedNames=PROJECT_STRIPPED_NAMES();
         ProjectName=_AbsoluteToWorkspace(StrippedNames:[ctladd_to_project_name.p_text]);
      }
      // save the value of the add to project checkbox
      _append_retrieve(ctladd_to_project, ctladd_to_project.p_value, '_workspace_new_form.ctladd_to_project');
      _nocheck _control ctllineformat;
      _append_retrieve(ctllineformat, ctllineformat.p_text, '_workspace_new_form.ctllineformat');

      // Note: when Filename is blank, workspace_new_file displays an error
      // if  we are adding this file to a project
      if (Filename=='') {
         ProjectName='';
      }

      // for macro recording
      _macro_call('workspace_new_file',
                  0,
                  Filename,
                  Path,
                  modeName,
                  ProjectName,
                  _EncodingGetComboSetting(),
                  _NewDialogLineFormat(),
                  MUST_SAVE_NEW_FILES()
                 );
      int result = workspace_new_file(
         true,
         Filename,
         Path,
         modeName,
         ProjectName,
         _EncodingGetComboSetting(),
         _NewDialogLineFormat(),
         MUST_SAVE_NEW_FILES()
         );
      // update most recently used document mode list
      if (!result) {
         UseDocumentMode(modeName);
      }
      // Check and save any modified project packs.
   } else if (ctl_gn_tab.p_ActiveTab==NEW_PROJECT_TAB) {
      _str packageName=OTHER_PROJ_PACK_NAME;
      initMacroBefore := "";


      if (ctlProjTree.p_visible) {
         // any parent items in trees are not valid project types but groups of project types
         if (ctlProjTree._TreeDoesItemHaveChildren(ctlProjTree._TreeCurIndex())) {
            _message_box("You must specify a project type.", "", MB_OK);
            return;
         }
         packageName=ctlProjTree._TreeGetCurCaption();
         if (strieq(packageName, "Root")) {
            _message_box("You must specify a project type.", "", MB_OK);
            return;
         }
         if (!CheckMSProjectType(packageName)) {
            return;
         }

         msg := "";
        if ( strieq(packageName,"Microsoft Visual C++ for 32 bit Windows") ) {
           msg="If you are using Visual C++ version 5.0 or newer, create your workspace in Visual C++. Then open your Visual C++ workspace from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
        } else if ( strieq(packageName,"Microsoft Visual C++ for 32 bit Windows >= 6.0") ) {
           msg="If you are using Visual C++ version 6.0 or newer, create your workspace/solution in Visual C++. Then open your Visual C++ workspace from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
        } else if ( strieq(substr(packageName,1,length("Microsoft Visual Studio")),"Microsoft Visual Studio") ) {
           // Being very lazy here by just checking the first part of the package string, but it keeps us from
           // having to check the 6 or more possibilities explicitly.
           msg="If you are using Visual Studio, create your workspace/solution in Visual Studio. Then open your Visual Studio workspace/solution from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
        }
         if ( msg != "" ) {
            // This is not a package we can create on our own, so advise the user
            _message_box(msg, "", MB_OK | MB_ICONINFORMATION);
            return;
         }
         initMacroBefore=_ProjectTemplateGet_InitMacroBefore(packageName);
      }
      if ( ctlinclude_filespecs.p_visible ) {
         _save_form_response();
      }

      Dependency := "";
      if (ctldependency.p_visible && ctldependency.p_value && ctldependency.p_enabled && ctladd_to_workspace.p_enabled) {
         _str StrippedNames:[];
         StrippedNames=DEPLIST_STRIPPED_NAMES();
         if (StrippedNames._varformat()==VF_HASHTAB) {
            Dependency=StrippedNames:[ctldeplist.p_text];
         }
      }
      if (initMacroBefore!='' && index_callable(find_index(initMacroBefore,PROC_TYPE|COMMAND_TYPE))) {
          _macro('m',_macro('s'));
          _macro_call(initMacroBefore,
                      0,
                      packageName,
                      _new_prjname.p_text,
                      CreateReadOnlyLocation(),
                      ctladd_to_workspace.p_value!=0,
                      ctlExecutableName.p_text,
                      Dependency
                     );
      } else {
          _macro('m',_macro('s'));
          _macro_call('workspace_new_project',
                      0,
                      packageName,
                      _new_prjname.p_text,
                      CreateReadOnlyLocation(),
                      ctladd_to_workspace.p_value!=0,
                      ctlExecutableName.p_text,
                      Dependency
                     );
      }

      projectName := "";
      STRARRAY filespecs;
      STRARRAY excludeFilespecs;
      if ( creatingFromInvocationDirectory ) {
         if (ctlexclude_filespecs.p_visible) {
            if (ctlexclude_filespecs.p_text != '') {
               list := ctlexclude_filespecs.p_text;
               while (list != '') {
                  file:=parse_file_sepchar(list);
                  if (file != '') {
                     ARRAY_APPEND(excludeFilespecs,file);
                  }
               }
            }
         }

         if (ctlinclude_filespecs.p_visible) {
            if (ctlinclude_filespecs.p_text != '') {
               list := ctlinclude_filespecs.p_text;
               while (list != '') {
                  file:=parse_file_sepchar(list);
                  if (file != '') {
                     ARRAY_APPEND(filespecs,file);
                  }
               }
            }
         }
         projectName = ctlProjectNewDir.p_text;
         _maybe_append_filesep(projectName);
         projectName :+= _new_prjname.p_text;
         if ( !_file_eq(PRJ_FILE_EXT,get_extension(projectName,true)) ) {
            projectName :+= PRJ_FILE_EXT;
         }
      }

      projectDir := ctlProjectNewDir.p_text;
      recursive := ctlrecursive.p_value!=0;
      add_as_wildcard:= ctlwildcard.p_value!=0;
      directoryfolder:=ctldirectoryfolder.p_value!=0;
      symlinks := ctlsymlinks.p_value!=0;
      createsubfolders:= ctlcustomfolders.p_value!=0;
      dont_show := ctldontshow.p_value!=0;
      if (creatingFromInvocationDirectory) {
         DIRPROJFLAGS flags=_default_option(VSOPTION_DIR_PROJECT_FLAGS)&~(DIRPROJFLAG_RECURSIVE|DIRPROJFLAG_ADD_AS_WILDCARD|DIRPROJFLAG_DIRECTORY_FOLDER|DIRPROJFLAG_FOLLOW_SYMLINKS|DIRPROJFLAG_DONT_PROMPT|DIRPROJFLAG_CREATE_SUBFOLDERS);
         if (recursive) flags|=DIRPROJFLAG_RECURSIVE;
         if (add_as_wildcard) flags|=DIRPROJFLAG_ADD_AS_WILDCARD;
         if (directoryfolder) flags|=DIRPROJFLAG_DIRECTORY_FOLDER;
         if (symlinks) flags|=DIRPROJFLAG_FOLLOW_SYMLINKS;
         if (dont_show) flags|=DIRPROJFLAG_DONT_PROMPT;
         if (createsubfolders) flags|=DIRPROJFLAG_CREATE_SUBFOLDERS;
         if (flags!=_default_option(VSOPTION_DIR_PROJECT_FLAGS)) {
            _default_option(VSOPTION_DIR_PROJECT_FLAGS,flags);
         }
         if (ctlinclude_filespecs.p_text!=_default_option(VSOPTIONZ_DIR_PROJECT_INCLUDES)) {
            _default_option(VSOPTIONZ_DIR_PROJECT_INCLUDES,ctlinclude_filespecs.p_text);
         }
         if (ctlexclude_filespecs.p_text!=_default_option(VSOPTIONZ_DIR_PROJECT_EXCLUDES)) {
            _default_option(VSOPTIONZ_DIR_PROJECT_EXCLUDES,ctlexclude_filespecs.p_text);
         }
         if (packageName!=_default_option(VSOPTIONZ_DIR_PROJECT_TYPE)) {
            _default_option(VSOPTIONZ_DIR_PROJECT_TYPE,packageName);
         }
      }
      /*vpw_filename:=CreateReadOnlyLocation();
      _maybe_append_filesep(vpw_filename);
      vpw_filename:+=_new_prjname.p_text;*/
      if (initMacroBefore!='' && index_callable(find_index(initMacroBefore,PROC_TYPE|COMMAND_TYPE))) {
          call_index(true,
                     packageName,
                     _new_prjname.p_text,
                     CreateReadOnlyLocation(),
                     ctladd_to_workspace.p_value!=0,
                     ctlExecutableName.p_text,
                     Dependency,
                     !creatingFromInvocationDirectory,
                     !creatingFromInvocationDirectory,
                     find_index(initMacroBefore,PROC_TYPE|COMMAND_TYPE)
                     );
      } else {
          workspace_new_project(true,
                                packageName,
                                _new_prjname.p_text,
                                CreateReadOnlyLocation(),
                                ctladd_to_workspace.p_value!=0,
                                ctlExecutableName.p_text,
                                Dependency,
                                !creatingFromInvocationDirectory,
                                !creatingFromInvocationDirectory
                                );
      }

      /*if ( creatingFromInvocationDirectory ) {
         handle := _ProjectHandle(projectName);
         _addWildcardsToProject(projectDir, filespecs, excludeFilespecs, recursive, symlinks, projectName, handle);
         _ProjectSave(handle);
      }*/
   } else if (ctl_gn_tab.p_ActiveTab==NEW_WORKSPACE_TAB) {
      dir := strip(ctlnew_workspace_dir.p_text,'B','"');
      _macro_call('workspace_new',
                  0,
                  ctlnew_workspace_name.p_text,
                  dir);
      workspace_new(true,ctlnew_workspace_name.p_text,dir);
   }
}


static void initialize_workspace_tab()
{
   ctlworkspace_type_list._lbadd_item("Blank Workspace");
   _str wroot=GetWorkspaceRoot();
   ctlnew_workspace_dir.p_text=wroot;
   if (wroot=="") {
      ctlnew_workspace_dir.p_text=getcwd();
   }
}

void ctlok.on_create(_str option='',_str (&Files)[]=null,_str workspaceFilename="")
{
   option=lowcase(option);
   // The x option is sometimes passed in from the Project tool window
   // Visual Studio needs new files added to the project to be saved.
   if (pos('s',option)) {
      MUST_SAVE_NEW_FILES(true);
      option=stranslate(option,'','s');
   } else {
      MUST_SAVE_NEW_FILES(false);
   }
   _workspace_new_form_initial_alignment();
   PUSER_IGNORE_DIRECTORY_CHANGE(0);
   PUSER_IGNORE_FILENAME_CHANGE(0);
   PROJECTNEWDIR_MODIFY(0);
   initialize_file_tab();
   initialize_project_tab(Files,workspaceFilename!='');
   initialize_workspace_tab();
   WORKSPACE_NEW_OPTION(option);
   if ( workspaceFilename=="" ) {
      ybuffer := ctl_gn_tab.p_y;
      extraControlSpace := (ctlwildcard.p_y_extent+ybuffer) - ctlinclude_label.p_y;
      ctl_gn_tab.p_height -= extraControlSpace;
      ctlok.p_y -= extraControlSpace;
      ctlCancel.p_y -= extraControlSpace;
      ctlCancel.p_next.p_y -= extraControlSpace;
      p_active_form.p_height -= extraControlSpace;
      ctlinclude_label.p_visible = false;
      ctlinclude_help.p_visible = false;
      ctlinclude_filespecs.p_visible = false;
      ctlexclude_label.p_visible = false;
      ctlexclude_help.p_visible = false;
      ctlexclude_filespecs.p_visible = false;
      ctlwildcard.p_visible=false;
      ctldirectoryfolder.p_visible=false;
   } else {
      ctldontshow.p_visible=true;
      ctlCreateProjDir.p_enabled=false;
      ctlCreateProjDir.p_enabled=false;
      _new_prjname.p_enabled=false;
      ctlProjectNewDir.p_enabled=false;
      ctlBrowseCD.p_enabled=false;
      if (!ctlProjTree.p_visible) {
         adjust_y := ctlinclude_label.p_y- ctladd_to_workspace.p_y_extent-200;
         if (adjust_y > 0) {
            ctlinclude_label.p_y     -= adjust_y;
            ctlinclude_help.p_y      -= adjust_y;
            ctlinclude_filespecs.p_y -= adjust_y;
            
            ctlexclude_label.p_y     -= adjust_y;
            ctlexclude_help.p_y      -= adjust_y;
            ctlexclude_filespecs.p_y -= adjust_y;
            
            ctlrecursive.p_y         -= adjust_y;
            ctlsymlinks.p_y          -= adjust_y;
            ctlcustomfolders.p_y     -= adjust_y;
            ctlwildcard.p_y          -= adjust_y;
            ctldirectoryfolder.p_y   -= adjust_y; 
         } 
      }
   }
   if (option=='p') {
      ctl_gn_tab.p_ActiveTab=NEW_PROJECT_TAB;
      if ( workspaceFilename!="" ) {
         /*_maybe_append_filesep(startupPath);
         justFile := _getDirTitledWorkspaceName(startupPath);
         justPath := startupPath;
         workspaceFilename := _getDirTitledWorkspaceFilename(startupPath);*/
         justPath := _strip_filename(workspaceFilename,'N');
         justFile := _strip_filename(workspaceFilename,'PE');

         _new_prjname.p_text = justFile;
         ctlProjectNewDir.p_text = justPath;
         project_type:=_default_option(VSOPTIONZ_DIR_PROJECT_TYPE);
         int index= -1;
         if (project_type!='') {
            index = ctlProjTree._TreeSearch(TREE_ROOT_INDEX,project_type,'T');
            if ( index>=0 ) {
               ctlProjTree._TreeSetCurIndex(index);
            }
         }
         if (index<0) {
            index = ctlProjTree._TreeSearch(TREE_ROOT_INDEX,'(Other)','T');
            if ( index>0 ) {
               ctlProjTree._TreeSetCurIndex(index);
            }
         }
         ctl_gn_tab._setEnabled(NEW_FILE_TAB,0);
         ctl_gn_tab._setEnabled(NEW_WORKSPACE_TAB,0);

         // throw some possible filespecs into the include list
         ctlinclude_filespecs._retrieve_list();
         ctlinclude_filespecs.add_filetypes_to_combo();
         ctlinclude_filespecs.p_text=_default_option(VSOPTIONZ_DIR_PROJECT_INCLUDES);
         ctlexclude_filespecs.p_text=_default_option(VSOPTIONZ_DIR_PROJECT_EXCLUDES);
         DIRPROJFLAGS flags=_default_option(VSOPTION_DIR_PROJECT_FLAGS);
#if 0
         _retrieve_prev_form();
         if ( ctlinclude_filespecs.p_text=="" ) {
            // If we didn't get anything when we called _retrieve_prev_form,
            status := ctlinclude_filespecs._lbsearch('*.c;');
            if ( !status ) {
               ctlinclude_filespecs.p_text = ctlinclude_filespecs._lbget_text();
            }
         }
         ctlrecursive.p_value=1;
#endif
         ctlrecursive.p_value=(flags& DIRPROJFLAG_RECURSIVE)?1:0;;
         ctlwildcard.p_value=(flags& DIRPROJFLAG_ADD_AS_WILDCARD)?1:0;;
         ctldirectoryfolder.p_value=(flags& DIRPROJFLAG_DIRECTORY_FOLDER)?1:0;
         ctlcustomfolders.p_value=(flags& DIRPROJFLAG_CREATE_SUBFOLDERS)?1:0;
         ctlsymlinks.p_value=(flags& DIRPROJFLAG_FOLLOW_SYMLINKS)?1:0;
         if (!_isUnix()) {
            ctlsymlinks.p_visible=false;
         }
         ctlCreateProjDir.p_value=0;
         ctlCreateProjDir.p_enabled=false;
      }
   } else if (option == 'pw') {
      ctl_gn_tab.p_ActiveTab=NEW_PROJECT_TAB;

      _SetDialogInfoHt(NEW_PROJ_WIZARD_TIMER, -1, ctl_new_proj_wizard);

      int * timer = _GetDialogInfoHtPtr(NEW_PROJ_WIZARD_TIMER, ctl_new_proj_wizard);
      if (_timer_is_valid(*timer)) {
         _kill_timer(*timer);
         *timer = -1;
      }

      *timer = _set_timer(200, launchNewProjectWizard);
   } else if (option=='d') {
      //9:34am 7/20/1999
      //This means that we are going to return all of the new project
      //information to the caller.  We limit the user to a new project in the
      //current workspace.
      ctl_gn_tab.p_ActiveTab=NEW_PROJECT_TAB;
      ctl_gn_tab._setEnabled(NEW_FILE_TAB,0);
      ctl_gn_tab._setEnabled(NEW_PROJECT_TAB,1);
      ctl_gn_tab._setEnabled(NEW_WORKSPACE_TAB,0);
      ctlcreate_new_workspace.p_enabled=false;
      ctladd_to_workspace.p_enabled=true;
      ctladd_to_workspace.p_value=1;
   } else if (option=='f2' || option=='f3') {
      /*
         Limit to adding new file to current project.
         Return information to caller.
      */
      ctl_gn_tab.p_ActiveTab=NEW_FILE_TAB;
      ctl_gn_tab._setEnabled(NEW_FILE_TAB,1);
      ctl_gn_tab._setEnabled(NEW_PROJECT_TAB,0);
      ctl_gn_tab._setEnabled(NEW_WORKSPACE_TAB,0);
      if (option=='f3') {
         ctladd_to_project.p_enabled=false;
         ctladd_to_project_name.p_enabled=false;
      } else {
         ctladd_to_project.p_enabled=false;
         ctladd_to_project.p_value=1;
         ctladd_to_project.p_user=1;
         ctladd_to_project_name.p_enabled=false;
      }
   }
}

void ctlrecursive.lbutton_up()
{
   ctlsymlinks.p_enabled=(p_value!=0);
   ctlcustomfolders.p_enabled=((p_value!=0) && !(ctlwildcard.p_visible && ctlwildcard.p_value));
}

void ctlwildcard.lbutton_up()
{
   ctlcustomfolders.p_value=p_value;
   ctldirectoryfolder.p_enabled=(p_value!=0);
}
/**
 * Select which controls should initially have focus for each tab.
 */
void _workspace_new_form.on_load() {
   if (ctl_gn_tab.p_ActiveTab==NEW_FILE_TAB) {
      ctlnew_workspace_name._set_focus();
      _new_prjname._set_focus();
      ctlfilename._set_focus();
   } else if (ctl_gn_tab.p_ActiveTab==NEW_PROJECT_TAB) {
      ctlfilename._set_focus();
      ctlnew_workspace_name._set_focus();
      _new_prjname._set_focus();
   } else if (ctl_gn_tab.p_ActiveTab==NEW_WORKSPACE_TAB) {
      ctlfilename._set_focus();
      ctlnew_workspace_name._set_focus();
      _new_prjname._set_focus();
   }
}

static void launchNewProjectWizard()
{
   button := _find_object('_workspace_new_form.ctl_new_proj_wizard');
   if (button < 0) return;

   int * timer = _GetDialogInfoHtPtr(NEW_PROJ_WIZARD_TIMER, button);
   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }

   // find button and click it!
   button.call_event(button, LBUTTON_UP, 'W');
}

void ctladd_to_project_name.on_change(int reason)
{
   if (!p_visible) {
      return;
   }
   _str StrippedNames:[];
   StrippedNames=PROJECT_STRIPPED_NAMES();
   if (StrippedNames._varformat()!=VF_HASHTAB) return;
   if (!StrippedNames._indexin(p_text)) return;
   dir := _strip_filename(_AbsoluteToWorkspace(StrippedNames:[p_text]),'N');
   ctldirectory.p_text=dir;
}
void ctldirectory.on_change() {
   if (PUSER_IGNORE_DIRECTORY_CHANGE()) return;
   Filename := strip(strip(ctlfilename.p_text),'B','"');
   Path := _strip_filename(Filename,'N');
   if (Path!='') {
      PUSER_IGNORE_FILENAME_CHANGE(1);
      ctlfilename.p_text=_strip_filename(Filename,'P');
      PUSER_IGNORE_FILENAME_CHANGE(0);
   }
}
void ctlfilename.on_change() {
   if (PUSER_IGNORE_FILENAME_CHANGE()) return;
   Filename := strip(strip(ctlfilename.p_text),'B','"');
   Path := _strip_filename(Filename,'N');
   if (Path!="") {
      ctlfilename.p_completion= FILENEW_NOQUOTES_ARG;
      PUSER_IGNORE_DIRECTORY_CHANGE(1);
      ctldirectory.p_text=Path;
      PUSER_IGNORE_DIRECTORY_CHANGE(0);
   }

   if (WORKSPACE_NEW_OPTION()=='f3') {
      return;
   }
   // disable [] Add to project if they do not give a file name
   if (_strip_filename(Filename, 'P') == "" /*|| isdirectory(Filename)*/) {
      if (ctladd_to_project.p_enabled) {
         ctladd_to_project.p_enabled = false;
         ctladd_to_project_name.p_enabled = false;
         ctladd_to_project.p_user = ctladd_to_project.p_value;
      }
   } else {
      if ((_project_name!="") && !ctladd_to_project.p_enabled) {
         ctladd_to_project.p_enabled = true;
         ctladd_to_project_name.p_enabled = true;
         ctladd_to_project.p_value = ctladd_to_project.p_user;
      }
   }
}

void ctlDocModes.on_change(int reason)
{
   if (reason == CHANGE_CLINE) {
      // see if this item is the list divider
      if (strieq(ctlDocModes._lbget_text(), LBDIVIDER)) {
         ctlDocModes._lbdown();
         ctlDocModes._lbselect_line();
         ctlDocModes.p_text = ctlDocModes._lbget_text();
      }
   } else if (reason == CHANGE_OTHER) {  // if user types in name, select it.
      mode := ctlDocModes.p_text;
      _str text = ctlDocModes._lbget_text();
      if (lowcase(mode)!=lowcase(text)) {
         return;
      }
      _lbselect_line();
   }
}
static _str _NewDialogLineFormat() {

   if (pos('(crlf)',ctllineformat.p_text,1,'i')) {
      return "+FND";
   }
   if (pos('(lf)',ctllineformat.p_text,1,'i')) {
      return "+FNU";
   }
   if (pos('(cr)',ctllineformat.p_text,1,'i')) {
      return "+FNM";
   }
   return '';
}
void _FillInProjectNames(_str projectName,_str (&StrippedNames):[]) {
   int wid;
   if (_workspace_filename!='' && _project_name!='') {
      _str ProjectNames[];
      _GetWorkspaceFiles(_workspace_filename,ProjectNames);
      int i;

      for (i=0;;++i) {
         if (i>=ProjectNames._length()) {
            _lbfind_and_select_item(_strip_filename(projectName,'PE'));
            break;
         }
         StrippedCurName := _strip_filename(ProjectNames[i],'PE');
         if (StrippedNames._indexin(StrippedCurName)) {
            _lbclear();
            StrippedNames._makeempty();
            for (i=0;;++i) {
               if (i>=ProjectNames._length()) {
                  _lbfind_and_select_item(_strip_filename(_RelativeToWorkspace(projectName),'E'));
                  break;
               }
               StrippedCurName = _strip_filename(_RelativeToWorkspace(ProjectNames[i]),'E');
               StrippedNames:[StrippedCurName]=ProjectNames[i];
               _lbadd_item(StrippedCurName);
            }
            break;
         }
         StrippedNames:[StrippedCurName]=ProjectNames[i];
         _lbadd_item(StrippedCurName);
      }
   }
}
static void initialize_file_tab()
{
   typeless status=0;
   info := "";
   projectHandle := _ProjectHandle();
   project_dir := "";
   // Have to check for this because of the "invoke with a directory" case, there
   // won't be a project open in that case.
   if (projectHandle >= 0) {
      project_dir =_ProjectGet_WorkingDir(projectHandle);
   }
   project_dir=absolute(project_dir,_file_path(_project_name));
   int handle;
   _str config;
   _ProjectGet_ActiveConfigOrExt(_project_name, handle, config);
   projwid := _tbGetActiveProjectsTreeWid();
   if (_project_name=='') {
      ctldirectory.p_text=getcwd();
   } else if (_ProjectGet_Type(handle, config) :== 'java' &&
              strieq(_ProjectGet_AutoFolders(handle),VPJ_AUTOFOLDERS_PACKAGEVIEW) && _get_focus() == projwid) {
      // special case here for Java package view
      _str caption=projwid._TreeGetCaption(projwid._TreeCurIndex());
      int node=_xmlcfg_find_simple(handle, "/Project/Files/Folder[@Name='"caption"']":+
                                   "[@Type='Package']");
      // try to populate the directory text with the directory from the current package
      if (node >= 0) {
         int child=_xmlcfg_get_first_child(handle, node);
         if (child >= 0) {
            projpath := _strip_filename(_xmlcfg_get_filename(handle),'N');
            _str relfile=_xmlcfg_get_attribute(handle, child, 'N');
            absfile := absolute(relfile, projpath);
            ctldirectory.p_text=_strip_filename(absfile, 'N');
         }
      } else {
         status=_ini_get_value(_project_get_filename(),_project_get_section("GLOBAL"),"WORKINGDIR",info);
         if (!status) {
            info=absolute(info,_strip_filename(_project_name,'N'));
            ctldirectory.p_text=info;
         } else {
            ctldirectory.p_text=getcwd();
         }
      }
   } else {
      status=_ini_get_value(_project_get_filename(),_project_get_section("GLOBAL"),"WORKINGDIR",info);
      if (!status) {
         info=absolute(info,_strip_filename(_project_name,'N'));
         ctldirectory.p_text=info;
      } else {
         ctldirectory.p_text=getcwd();
      }
   }
   if (_UTF8()) {
      _EncodingFillComboList('','Automatic',OEFLAG_REMOVE_FROM_NEW);
   } else {
      ctlencoding.p_visible=ctlencodinglabel.p_visible=false;
   }
   ctllineformat._lbadd_item('Automatic');
   ctllineformat._lbadd_item('Windows/DOS (CRLF)');
   ctllineformat._lbadd_item('Unix/Mac (LF)');
   ctllineformat._lbadd_item('Classic Mac (CR)');
   ctllineformat._retrieve_value();

   FillInDocumentModeList();
   _str StrippedNames:[];
   ctladd_to_project_name._FillInProjectNames(_project_name,StrippedNames);
   PROJECT_STRIPPED_NAMES(StrippedNames);

   ctladd_to_project.p_enabled=(_project_name!="");
   if (_IsWorkspaceAssociated(_workspace_filename)) {
      if (!_IsAddDeleteSupportedWorkspaceFilename(_workspace_filename)) {
         ctladd_to_project.p_enabled=false;
      }
   }

   if (ctladd_to_project.p_enabled) {
      // restore the last value of add to project
      retrieveValue := ctladd_to_project._retrieve_value();
      if (retrieveValue != null && isinteger(retrieveValue)) {
         ctladd_to_project.p_value = retrieveValue;
      } else {
         ctladd_to_project.p_value = 1;
      }
   }
   ctladd_to_project.p_user = ctladd_to_project.p_value;
   ctladd_to_project_name.p_enabled = (ctladd_to_project.p_enabled && ctladd_to_project.p_value != 0);

   ctlfilename.call_event(CHANGE_OTHER,ctlfilename,ON_CHANGE,"W");
}

/*
 * Fills in the Document Mode list on the New File tab.  Moved
 * this to its own function since list has to be refreshed when
 * user changes number of recently used modes to display.
 *
 **/
void FillInDocumentModeList()
{
   int wid=_mdi.p_child;

   // save currently selected item - Automatic mode is default
   current := ctlDocModes.p_text;
   if (current == '') {
      current = "Automatic";
   }

   // clear list
   ctlDocModes._lbclear();

   // we need to use the lower of the two values:  the maximum
   // allowed number of MRUs versus the current length of the
   // array.
   int max = def_max_doc_mode_mru;
   if (def_max_doc_mode_mru > MRUDocModes._length()) {
      max = MRUDocModes._length();
   }

   // Put in placeholders for most recently used types
   // there is no listbox insert method and the _list_modes method
   // sorts its value, so if we want the MRU list at top, we need
   // to add placeholders now.
   j := 0;
   if (max) {
      for (; j < max; j++) {
         ctlDocModes._lbadd_item(j);
      }

      // add extra placeholder for line separator
      ctlDocModes._lbadd_item(j);
   }

   // 6.4.07
   // change the _list_modes calls to include Automatic mode
   if (wid && wid._isEditorCtl(false)) {
      ctlDocModes._list_modes(wid.p_LangId, wid.p_mode_name, true);
   } else {
      ctlDocModes._list_modes('', '', true);
   }

   // insert N most recently used document modes at placeholders
   if (max) {
      ctlDocModes._lbtop();
      ctlDocModes._lbselect_line();
      for (j = 0; j < max; j++) {
         ctlDocModes._lbset_item(MRUDocModes[j]);
         ctlDocModes.down();
      }

      // add line separator
      ctlDocModes._lbset_item(LBDIVIDER);
   }

   // restore previous selection
   found := false;
   ctlDocModes._lbtop();
   while (!ctlDocModes.down()) {
      if (strieq(ctlDocModes._lbget_text(), current)) {
         ctlDocModes.p_text = current;
         ctlDocModes._lbselect_line();
         found = true;
         break;
      }
   }

   // not found, just select what's at the top
   if (!found) {
      ctlDocModes._lbtop();
      ctlDocModes._lbselect_line();
   }

}

static _str GetWorkspaceRoot()
{
   if (_workspace_filename=='') {
      return('');
   }
   _str NewWorkspaceDir=_GetWorkspaceDir();
   //Get rid of the trailing filesep
   NewWorkspaceDir=substr(NewWorkspaceDir,1,length(NewWorkspaceDir)-1);
   //Trim back one path...
   // NOTE: this is done because most projects live in a subdirectory with the same
   //       name.  for example, a project Test1 most likely lives in a folder named
   //       Test1 so the last piece of the path is trimmed based on that assumption
   NewWorkspaceDir=_strip_filename(NewWorkspaceDir,'N');
   return(NewWorkspaceDir);
}

_str _compiler_default;

static void initialize_project_tab(_str Files[]=null,bool forcedDirectoryLocation=false)
{
   PTR_PROJECT_TYPES_EXECUTABLE(null);

   int wid;
   // append a FILESEP if there is not one
   currentDir := getcwd();
   _maybe_append_filesep(currentDir);

   gUserTemplatesHandle = -1;
   gSysTemplatesHandle = -1;
   if (_haveBuild()) {
      createdUserTemplates := false;
      gUserTemplatesHandle=_ProjectOpenUserTemplates(createdUserTemplates);
      gSysTemplatesHandle=_ProjectOpenTemplates();
      if (gSysTemplatesHandle<0 && (gUserTemplatesHandle<0 || createdUserTemplates) ) {
         // No templates are available, so we will remove project and workspace
         // tabs from the dialog
         wid=p_window_id;
         p_window_id=ctl_gn_tab;
         _setEnabled(2,0);
         _setEnabled(1,0);
         p_window_id=wid;
         return;
      }

      _FillInProjectTreeControl(gUserTemplatesHandle,gSysTemplatesHandle,false,forcedDirectoryLocation);
      _FillProjectTypeExecutableTable(gSysTemplatesHandle, gUserTemplatesHandle);

      // If a default compiler package is specified, use it.
      // Otherwise select the last compiler package selected.
      _str _compiler_restore;
      if (_compiler_default == "") {
         _compiler_restore = _retrieve_value("_project_new_form.packageSelected");
      } else {
         _compiler_restore = _compiler_default;
      }
      if (_compiler_restore == "") {
         _compiler_restore = "(None)";
      }
      wid = p_window_id;
      p_window_id = ctlProjTree;
      _compiler_restore = lowcase(_compiler_restore);
      found := 0;
      typeless status = 0;

      // search for compiler package - if not found exactly, do a prefix search
      int index = _TreeSearch(TREE_ROOT_INDEX, _compiler_restore, "IT");
      if (index < 0) {
         index = _TreeSearch(TREE_ROOT_INDEX, _compiler_restore, "IPT");
      }

      // If no compiler package can be matched, use the first package
      if (index < 0) {
         _TreeSetCurIndex(TREE_ROOT_INDEX);
      }

      p_window_id=wid;
   } else {
      // no builds, then no fancy project types
      ctllabel4.p_visible = ctlProjTree.p_visible = ctlcustomize.p_visible = false;
      ctlExecutableLabel.p_visible = ctlExecutableName.p_visible = false;
      ctldependency.p_visible = ctldeplist.p_visible = false;

      xDiff := ctlProjectNewDir.p_x - ctllabel4.p_x;

      label1.p_x = _new_prjname.p_x = ctlCreateProjDir.p_x = ctlLocationLabel.p_x =
         ctlProjectNewDir.p_x = ctlROLocation.p_x = ctlcreate_new_workspace.p_x =
         ctladd_to_workspace.p_x = ctllabel4.p_x;
      ctlBrowseCD.p_x -= xDiff;

      yDiff := ctlcreate_new_workspace.p_y - ctlExecutableLabel.p_y;
      ctlcreate_new_workspace.p_y -= yDiff;
      ctladd_to_workspace.p_y -= yDiff;

      ctlROLocation.p_width += xDiff;
   }

   ctlcreate_new_workspace.p_value=1;

   if (ctlcreate_new_workspace.p_value) {
      ctlProjectNewDir.p_text=GetWorkspaceRoot();
   }

   if (_workspace_filename=='') {
      ctladd_to_workspace.p_enabled=false;
   }

   if (_haveBuild()) {
      _str ProjectNames[];
      _str StrippedNames:[];
      if (_workspace_filename!='') {
         if (Files==null) {
            _GetWorkspaceFiles(_workspace_filename,ProjectNames);
         } else {
            ProjectNames=Files;
         }
         if (ProjectNames._length()) {
            wid=p_window_id;
            p_window_id=ctldeplist;
            int i;
            for (i=0;i<ProjectNames._length();++i) {
               StrippedCurName := _strip_filename(ProjectNames[i],'PE');
               StrippedNames:[StrippedCurName]=ProjectNames[i];
               _lbadd_item(StrippedCurName);
            }
            _lbfind_and_select_item(_strip_filename(_project_name,'PE'));
            p_window_id=wid;
            DEPLIST_STRIPPED_NAMES(StrippedNames);
            ctldependency.p_value=0;
         } else {
            ctldeplist.p_enabled=false;
            ctldependency.p_enabled=false;
            ctldependency.p_value=0;
         }
      } else {
         ctldeplist.p_enabled=ctldependency.p_enabled=false;
      }
   }

   ctlcreate_new_workspace.call_event(ctlcreate_new_workspace,LBUTTON_UP);
   VendorWorkspace := "";
   if (gWorkspaceHandle>=0) {
      _GetAssociatedWorkspaceInfo(gWorkspaceHandle,VendorWorkspace);
   }
   if (ctlProjectNewDir.p_text=="") {
      ctlProjectNewDir.p_text=currentDir;
   }
   PROJECTNEWDIR_MODIFY(0);

   if (_IsWorkspaceAssociated(_workspace_filename)) {
      //Cannot let the user add projects to a VCPP workspace
      ctladd_to_workspace.p_enabled=false;
      ctladd_to_workspace.call_event(ctladd_to_workspace,LBUTTON_UP);
   }
}

// Search thru the specified file for a list of section names and
// append section names into the list. Duplicate copies are removed.
// Retn: 0 OK, !0 can't read file
static int _getProjectTypeNames(int handle, _str (&p)[], int user, bool showAll)
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
      if (!_ignoreProjectPackage(handle, array[i],showAll)) continue;

      // Ignore a global project pack if a version with the same name
      // already exists in the list.
      if (!user) {
         found := 0;
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

      p[p._length()]=sectionName;
   }
   return(0);
}


/**
 * Retrieves the list of available project types and populates the tree view at Project > New.
 *
 * @param usertemplates_handle
 * @param systemplates_handle
 * @param showAll whether all project types should be listed
 */
static void _FillInProjectTreeControl(int usertemplates_handle,
                               int systemplates_handle,
                               bool showAll,bool forcedDirectoryLocation=false)
{
   wid := p_window_id;
   _control ctlProjTree;
   p_window_id = ctlProjTree;

   // Get the list of user-defined project packs first.
   // If a project pack exists as user-defined and globally defined,
   // the user-defined version in the user's project pack file
   // superceeds the global version.
   PROJECTPACKS p:[];
   p._makeempty();

   GetAllProjectPacks(p, usertemplates_handle, systemplates_handle, showAll,forcedDirectoryLocation);

   // Fill the project type tree view.
   fillProjectTree(p);
   _TreeTop();
   p_window_id=wid;
}


/**
 * Fills in the Project Types tree on Project > New.
 *
 * @param p         List of project types with which to populate
 *                  the tree view.
 */
static void fillProjectTree(PROJECTPACKS (&p):[])
{
   int index;

   _TreeDelete(TREE_ROOT_INDEX, "C");
   _TreeBeginUpdate(TREE_ROOT_INDEX);

   // add most recently used project types to tree
   index = AddMRUProjTypesToTree(p);

   PopulateProjectPacksTree(p);

   // update title of most recently used node
   if (index > 0)   {
      _TreeSetCaption(index, "Recently Used");
   }

   _TreeEndUpdate(TREE_ROOT_INDEX);
}

/**
 * Adds the Most Recently Used project types list to the project types tree as a node titled "Recently Used".
 *
 * @return the index of the new "Recently Used" node.  -1 if it
 *         was not added because of a lack of recently used
 *         types
 */
static int AddMRUProjTypesToTree(PROJECTPACKS (&p):[])
{
   if (!MRUProjectTypes._isempty()) {

      lower := MRUProjectTypes._length();
      if (lower > def_max_proj_type_mru) {
         lower = def_max_proj_type_mru;
      }

      if (lower > 0) {
         int index = _TreeAddItem(TREE_ROOT_INDEX, "!Recently Used", TREE_ADD_AS_CHILD);

         added_one := false;
         int i;
         for (i = 0; i < lower; i++) {
            if (p._indexin(MRUProjectTypes[i])) {
               _TreeAddItem(index, MRUProjectTypes[i], TREE_ADD_AS_CHILD, 0, 0, -1);
               added_one=true;
            }
         }
         if (!added_one) {
            _TreeDelete(index);
            index= -1;
         }

         return index;
      }
   }
   return -1;
}

void ctlBrowsedir.lbutton_up()
{
   wid := p_window_id;
   typeless result=_ChooseDirDialog("",p_prev.p_text,"",CDN_PATH_MUST_EXIST|CDN_ALLOW_CREATE_DIR);
   if ( result=='' ) {
      return;
   }

   // we don't need quotes for this
   result = strip(result, 'B', '"');

   p_window_id=wid.p_prev;
   p_text=result;
   end_line();
   _set_focus();
   return;
}
#if 0 //11:03am 6/17/1999
void _gn_filename.on_change()
{
   if (p_text == '') {
      ctladd_to_project.p_enabled = false;
   } else if (_workspace_filename !='' ) {
      ctladd_to_project.p_enabled = true;
   }
}
#endif

void ctladd_to_project.lbutton_up()
{
   ctladd_to_project_name.p_enabled=p_value!=0;
}

void _new_prjname.on_change()
{
   if (ctlExecutableName.p_visible && ctlExecutableName.p_enabled) {
      exename := _strip_filename(p_text,'pe');
      ctlExecutableName.p_text=exename;
   }

   UpdateReadOnlyLocation();
}

void ctlCreateProjDir.lbutton_up()
{
   UpdateReadOnlyLocation();
}

void ctlcreate_new_workspace.lbutton_up()
{
   if (!PROJECTNEWDIR_MODIFY()) {
      FillInPrjName(true);
   }
   int NewWorkspace=(int)(ctladd_to_workspace.p_value==0);
   if (ctldeplist.p_Noflines) {
      ctldependency.p_enabled=!NewWorkspace;
      ctldeplist.p_enabled= ctldependency.p_enabled && (ctldependency.p_value != 0);
   }
}

void ctldependency.lbutton_up()
{
   ctldeplist.p_enabled = ctldependency.p_enabled && (ctldependency.p_value != 0);
}

defeventtab _workspace_dependencies_form;

static _str gFiles(...)[] {
   if (arg()) ctlok.p_user=arg(1);
   return ctlok.p_user;
}
static _str gDependencies(...):[] {
   if (arg()) ctltree1.p_user=arg(1);
   return ctltree1.p_user;
}
static int gNoOnChange(...) {
   if (arg()) ctlProjectList.p_user=arg(1);
   return ctlProjectList.p_user;
}
static _str gLastProject(...) {
   if (arg()) ctllabel1.p_user=arg(1);
   return ctllabel1.p_user;
}
static _str gStrippedNames(...):[] {
   if (arg()) p_active_form.p_user=arg(1);
   return p_active_form.p_user;
}
static _str gOrigDependencies(...):[] {
   if (arg()) ctlhelp.p_user=arg(1);
   return ctlhelp.p_user;
}
static _str RETURN_DEPENDENCIES_IN_HASHTAB(...) {
   if (arg()) ctllabel2.p_user=arg(1);
   return ctllabel2.p_user;
}

static bool FileDependsOn(_str File1,_str File2,_str Dependencies:[])
{
   File2Cased := _file_case(File2);
   if (!Dependencies._indexin(File2Cased)) return(false);
   _str Deps = Dependencies:[File2Cased];
   for (;;) {
      _str cur=parse_file(Deps,false);
      if (cur._varformat()==VF_EMPTY ||cur=='') {
         break;
      }
      if (_file_eq(File1,cur)) {
         return(true);
      }
      if (FileDependsOn(File1,cur,Dependencies)) {
         return(true);
      }
   }
   return(false);
}

static bool FileImmediatelyDependsOn(_str File1,_str File2,
                                        _str Dependencies:[])
{
   File2Cased := _file_case(File2);
   if (!Dependencies._indexin(File2Cased)) return(false);
   _str Deps=Dependencies:[File2Cased];
   for (;;) {
      _str cur=parse_file(Deps,false);
      if (cur._varformat()==VF_EMPTY || cur=='') {
         break;
      }
      if (_file_eq(File1,cur)) {
         return(true);
      }
   }
   return(false);
}


void ctlProjectList.on_change(int reason)
{
   if (gNoOnChange()==1) {
      return;
   }
   wid := p_window_id;
   _nocheck _control ctltree1;
   p_window_id=ctltree1;
   _str Files[],Dependencies:[];
   Files=gFiles();
   Dependencies=gDependencies();
   state := bm1 := bm2NOLONGERUSED := 0;
   Filename := "";

   if (gLastProject()!='') {
      //Set the deps for the last one
      OldDeps := "";
      index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      for (;;) {
         if (index<0) {
            break;
         }
         if (_TreeGetCheckState(index)) {
            cap := _TreeGetCaption(index);
            parse cap with "\t" Filename;
            OldDeps :+= ' 'always_quote_filename(Filename);
         }
         index=_TreeGetNextSiblingIndex(index);
      }
      OldDeps=strip(OldDeps);
      Dependencies:[_file_case(gLastProject())]=OldDeps;
   }
   gDependencies(Dependencies);

   _TreeDelete(TREE_ROOT_INDEX,'C');
   //Fill in new deps
   _str StrippedNames:[];
   StrippedNames=gStrippedNames();
   cbindex := 0;
   int i;
   for (i=0;i<Files._length();++i) {
      if (!_file_eq(Files[i],StrippedNames:[ctlProjectList.p_text]) &&
          !FileDependsOn(StrippedNames:[ctlProjectList.p_text],Files[i],Dependencies)) {
         dispName := GetProjectDisplayName(Files[i]);
         if (def_project_show_relative_paths) {
            dispName = _RelativeToWorkspace(dispName);
         }
         treeIndex := _TreeAddItem(TREE_ROOT_INDEX,
                                   _strip_filename(dispName,'P')"\t"dispName,
                                   TREE_ADD_AS_CHILD,
                                   -1,
                                   -1,
                                   -1);
         _TreeSetCheckable(treeIndex,1,0);
         if (FileImmediatelyDependsOn(GetProjectDisplayName( Files[i]),GetProjectDisplayName( StrippedNames:[ctlProjectList.p_text]),Dependencies)) {
            _TreeSetCheckState(treeIndex,TCB_CHECKED);
         } else {
            _TreeSetCheckState(treeIndex,TCB_UNCHECKED);
         }
      }
   }
   if (Files._length()) {
      _TreeSortCaption(TREE_ROOT_INDEX,'F');
      _TreeTop();
   }
   _TreeRefresh();
   p_window_id=wid;
   gLastProject(StrippedNames:[p_text]);
}

static void projectListTreeCheckToggle(int index)
{
   state := bm1 := bm2NOLONGERUSED := 0;
   if ( !ctlok.p_enabled ) {
      _str ErrorMessage=nls("You cannot change these settings because this is an asssociated workspace.");
      _str workspacetype=_WorkspaceGet_AssociatedFileType(gWorkspaceHandle);
      if (workspacetype == JBUILDER_VENDOR_NAME) {
         // no op
      } else if (workspacetype!='') {
         line2 := "You must change these settings in";
         for (;;) {
            _str cur;
            parse workspacetype with cur workspacetype;
            if (cur=='') {
               break;
            }
            line2 :+= ' '_Capitalize(cur);
         }
         line2 :+= '.';
         ErrorMessage :+= "\n"line2;
      }
      _message_box(ErrorMessage);
   }
}

int ctltree1.on_change(int reason,int index)
{
   switch ( reason ) {
   case CHANGE_CHECK_TOGGLED:
      projectListTreeCheckToggle(index);
      break;
   }
   return 0;
}
void ctltree1.ENTER()
{
   ctlok.call_event(ctlok,LBUTTON_UP);
}


void ctlok.on_create(_str Files[],_str Dependencies:[],_str Project,
                     bool ReturnHashTab=false,bool DisableTree=false)
{
   if (ReturnHashTab) {
      RETURN_DEPENDENCIES_IN_HASHTAB(1);
   }
   wid := p_window_id;
   gNoOnChange(1);
   p_window_id=ctlProjectList;
   _str StrippedNames:[];
   for (i:=0;i<Files._length();++i) {
      CurStrippedName := _strip_filename(GetProjectDisplayName(Files[i]),'P');
      StrippedNames:[CurStrippedName]=Files[i];
      _lbadd_item(CurStrippedName);
   }
   gStrippedNames(StrippedNames);

   _lbsort();
   _lbtop();
   status := _lbfind_and_select_item(GetProjectDisplayName(_strip_filename(Project,'P')),_fpos_case);
   p_window_id=wid;
   gNoOnChange(0);
   gFiles(Files);
   gDependencies(Dependencies);
   gOrigDependencies(Dependencies);

   longestName := 0;
   longestPath := 0;
   for (i=0;i<Files._length();++i) {
      int curwidth=_text_width(_strip_filename(GetProjectDisplayName(Files[i]),'P'));
      if (curwidth>longestName) {
         longestName=curwidth;
      }
      curwidth=_text_width(Files[i]);
      if (curwidth>longestPath) {
         longestPath=curwidth;
      }
   }

   oldwidth := 0;
   ctltree1._TreeColWidth(0,longestName+100);
   if (longestName+longestPath+750>ctltree1.p_width) {

      oldwidth=ctltree1.p_width;

      ctltree1.p_width=longestName+longestPath+750;

      diff := ctltree1.p_width-oldwidth;
      ctlhelp.p_x=ctlok.p_x=ctlok.p_next.p_x=ctlok.p_x+diff;
      ctlProjectList.p_width=ctltree1.p_width;
      p_active_form.p_width+=diff;
   }
   ctlProjectList.call_event(CHANGE_SELECTED,-1,ctlProjectList,ON_CHANGE,'W');
   if (DisableTree) {
      ctlok.p_enabled=false;
   }
}

int ctlok.lbutton_up()
{
   ctlProjectList.call_event(CHANGE_SELECTED,ctlProjectList,ON_CHANGE,'W');
   _str Dependencies:[];
   Dependencies=gDependencies();
   if (RETURN_DEPENDENCIES_IN_HASHTAB()==1) {
      _param1=Dependencies;
      p_active_form._delete_window(0);
      return(0);
   }

   int was_recording=_macro();
   _macro('M',_macro('S'));
   AddMacroRecordingForHashtab(Dependencies,'Dependencies');
   int status=_WriteDependencies(Dependencies,gOrigDependencies());
   _macro_append('_WriteDependencies(Dependencies);');
   _macro('M',was_recording);
   if (status) {
      _message_box(nls('Could not write to workspace file %s.\n\n%s',_workspace_filename,get_message(status)));
   }
   p_active_form._delete_window(0);
   return(0);
}




#if 0
// 4/20/2015 - In case we make a change and allow non-wildcard projects in the
// new project case.
static void addTreeToProjectNoDialog(_str basePath,
                                     _str projectName,
                                     _str (&includeList)[],
                                     _str (&excludeList)[],
                                     bool recursive,
                                     bool followSymlinks)
{
   _str ConfigName=ALL_CONFIGS;

   // Find all files in tree:
   mou_hour_glass(true);
   message('SlickEdit is finding all files in tree');

   recursiveString := recursive ? '+t' : '-t';
   optimizeString := followSymlinks ? '' : '+o';

   formwid := p_active_form;
   filelist_view_id := 0;
   int orig_view_id=_create_temp_view(filelist_view_id);
   p_window_id=filelist_view_id;
   _str orig_cwd=getcwd();
   _str ProjectName=projectName;
   all_files := _maybe_quote_filename(basePath);
   for (i := 0; i < includeList._length(); ++i) {
      strappend(all_files,' -wc '_maybe_quote_filename(includeList[i]));
   }

   for (i = 0; i < excludeList._length(); ++i) {
      strappend(all_files,' -exclude '_maybe_quote_filename(excludeList[i]));
   }

   // +W option supports multiple file specs but must specify switches
   // before files when you use this option.
   status:=insert_file_list(recursiveString' 'optimizeString' +W +L -v +p -d 'all_files);
   if (status==CMRC_OPERATION_CANCELLED) {
      p_window_id=orig_view_id;
      _delete_temp_view(filelist_view_id);
      mou_hour_glass(false);
      clear_message();
      _message_box(get_message(CMRC_OPERATION_CANCELLED));
      return;
   }
   p_line=0;

   int FileToNode:[];
   FilesNode := 0;
   AutoFolders := "";
   int ExtToNodeHashTab:[];
   LastExt := "";
   LastNode := 0;
   _InitAddFileToConfig(FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);
   // Insert tree file list into project source file list:
   top();up();
   while (!down()) {
      get_line(auto filename);
      filename=strip(filename);
      if (filename=='') break;
      if (_DataSetIsFile(filename)) {
         filename=upcase(filename);
      }
      _AddFileToConfig(0,relative(filename,_strip_filename(ProjectName,'N')),ConfigName,FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);
   }
   //Now sort the buffer...
   p_window_id=orig_view_id;
   _delete_temp_view(filelist_view_id);

}
#endif

/**
 * Updates the most recently used document mode list after a user has created a new file.
 *
 * @param modeName
 */
static void UseDocumentMode(_str modeName)
{
   if (strieq(modeName, "Automatic")) return;

   i := 0;
   for (; i < MRUDocModes._length(); i++ ) {
      if (strieq(MRUDocModes[i], modeName)) {
         break;
      }
   }

   // mode name was found - reorganize
   if (i < MRUDocModes._length()) {
      ShiftArrayUp(MRUDocModes, 0, i);
   } else {   // mode name not found, add new one and remove last one
      ShiftArrayUp(MRUDocModes, 0);
   }

   MRUDocModes[0] = modeName;

   // clear any items past maximum
   for (i = def_max_doc_mode_mru; i < MRUDocModes._length(); ++i) {
      MRUDocModes._deleteel(i);
   }

}

/**
 * Updates the most recently used project type list when a new project is created.
 *
 * @param type   the project type that was used
 */
static void UseProjectType(_str type)
{
   i := 0;
   for (; i < MRUProjectTypes._length(); i++ ) {
      if (strieq(MRUProjectTypes[i], type)) {
         break;
      }
   }

   // mode name was found - reorganize
   if (i < MRUProjectTypes._length()) {
      ShiftArrayUp(MRUProjectTypes, 0, i);
   } else {   // mode name not found, add new one and remove last one
      ShiftArrayUp(MRUProjectTypes, 0);
   }

   MRUProjectTypes[0] = type;

   // clear any items past maximum
   for (i = def_max_proj_type_mru; i < MRUProjectTypes._length(); ++i) {
      MRUDocModes._deleteel(i);
   }

}

/**
 * Handles the logic when the user selects the
 * Automatic document mode from the new file dialog.
 *
 * @param filename file to be created
 *
 * @return the new document mode
 */
_str HandleAutomaticDocumentMode(_str filename)
{
   // if no extension, then create as Plain Text (Fundamental)
   // if extension, look up document mode
   modeName := "Plain Text";
   lang := _Filename2LangId(filename);
   if (lang != "") {
      modeName = _LangGetModeName(lang);
   }

   // if no extension, then ask if user wants plain text
   if (modeName == "") {
      // warn user about lack of document mode for specified extension
      if (def_warn_unknown_ext) {
         _str msg = nls("No Document Mode for this specified file: %s.  Create document as Plain Text?", filename);
         int result = textBoxDialog("Unknown Extension",
                                    0,                                          // Flags
                                    0,                                          // width
                                    "",                                         // help item
                                    "Yes,No\t-html "msg,                        // buttons and captions
                                    "",                                         // Retrieve Name
                                    "-CHECKBOX Warn about unknown extensions.:1");
         // check for warning checkbox (0=unchecked, 1=checked)
         def_warn_unknown_ext = (_param1 == 1);
         _config_modify_flags(CFGMODIFY_DEFVAR);
         if (result == 1/*Yes*/) {   /*button 1, aka Yes*/
            modeName = "Plain Text";
         }
      } else {
         modeName = "Plain Text";
      }
   }

   return modeName;
}

