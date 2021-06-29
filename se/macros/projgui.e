////////////////////////////////////////////////////////////////////////////////////
// Copyright 2018 SlickEdit Inc. 
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
#include "project.sh"
#import "bgsearch.e"
#import "fileproject.e"
#import "files.e"
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "project.e"
#import "projconv.e"
#import "projutil.e"
#import "project.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "wizard.e"
#import "wkspace.e"
#endregion



defeventtab _import_list_form;

/**
 * Adds the list of file types found in def_file_types to a list
 * box.
 */
void _init_filters()
{
   _lbclear();
   _retrieve_list();
   _lbbottom();

   name := "";
   list := "";
   _str wildcards=def_file_types;
   for (;;) {
      parse wildcards with name '('list')' ',' wildcards;
      if (name=='') break;
      _lbadd_item(list);
   }
}

ctlok.on_create()
{
   _retrieve_prev_form();
   ctlFileFilter._init_filters();

   ctlFileFilter.p_enabled=ctlFileFilterEnable.p_value!=0;
   _import_list_form_initial_alignment();
}

ctlFileFilterEnable.lbutton_up()
{
   ctlFileFilter.p_enabled=ctlFileFilterEnable.p_value!=0;
}

ctlListFileBrowse.lbutton_up()
{
   working_dir := absolute(_ProjectGet_WorkingDir(ProjectFormProjectHandle()), _strip_filename(ProjectFormProjectName(), 'N'));
   _str result=_OpenDialog("-modal",
                           'Import Files',// title
                           '',// Initial wildcards
                           "Text Files (*.txt),All Files (*.*)",
                           OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT|OFN_SET_LAST_WILDCARDS,
                           "", // Default extension
                           ""/*wildcards*/, // Initial filename
                           working_dir,// Initial directory
                           "",
                           ""
                           );
   if ( result!='' ) {
      ctlListFile.p_text=strip(result,'B','"');
   }
}

/**
 * Reads the specified import file, grabbing each line and 
 * putting it into an array 
 * 
 * @param file_array 
 * @param recursive 
 * 
 * @return int 
 */
static int get_file_array(_str (&file_array)[],bool &recursive)
{
   file_array._makeempty();

   // collapse the list file into a bgm_gen_file_list friendly string
   // open the file specified into a temp view
   int temp_wid;
   int orig_wid;
   int status=_open_temp_view(ctlListFile.p_text,temp_wid,orig_wid);
   if (status) {
      _message_box('Could not open list file');
      return status;
   }

   // make sure we don't get any array size warnings
   if (p_Noflines+10>_default_option(VSOPTION_WARNING_ARRAY_SIZE)) {
      _default_option(VSOPTION_WARNING_ARRAY_SIZE,p_Noflines+10);
   }

   // grab each line in the file
   top();
   up();
   _str cur_line;
   while (!down()) {
      get_line(cur_line);
      cur_line=strip(cur_line);
      if (cur_line:!='') {
         file_array[file_array._length()]=cur_line;
      }
   }

   // clean up after ourselves
   p_window_id=orig_wid;
   _delete_temp_view(temp_wid);

   // do what the checkbox says
   recursive=ctlRecurse.p_value!=0;

   return 0;
}

static int generate_file_list()
{
   // get the files specified in the import list
   _str file_array[];
   bool recursive;
   int status=get_file_array(file_array,recursive);

   // we failed, very sad
   if (status) return 0;

   // figure out which files to keep based on file type
   _str wildcards=ALLFILES_RE;
   if (ctlFileFilterEnable.p_value) {
      wildcards=ctlFileFilter.p_text;
   }

   int temp_wid;
   status=bgm_gen_file_list(temp_wid,'',wildcards,'',true,false,false,true,recursive,file_array);
   if (status) {
      if (status<0) {
         _message_box(get_message(status));
      }
      return(0);
   }

   activate_window(temp_wid);

   bgm_filter_project_files(wildcards);

   return temp_wid;
}

ctlok.lbutton_up()
{
   _save_form_response();
   if (ctlFileFilter.p_text!='') {
      _append_retrieve(ctlFileFilter,ctlFileFilter.p_text);
   }
   temp_wid:=p_window_id.generate_file_list();
   p_active_form._delete_window(temp_wid);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _import_list_form_initial_alignment()
{
   // size the buttons to the textbox
   sizeBrowseButtonToTextBox(ctlListFile.p_window_id, 
                             ctlListFileBrowse.p_window_id, 
                             0,
                             ctlFileFilter.p_x_extent);
}


defeventtab _project_tool_wizard_form;

static _str TEMPLATE_TYPE(...) {
   if (arg()) slide3_add_to_template.p_user=arg(1);
   return slide3_add_to_template.p_user;
}

static const ISEXTPROJECT_KEY= 'langid';
static const PROJECT_HANDLE_KEY='projectHandle';

int _OnUpdate_project_tool_wizard(CMDUI &cmdui,int target_wid,_str command)
{
   // make sure a project is open
   if (_project_name != '') {
      return MF_ENABLED;
   } else if (!_no_child_windows() && _fileProjectHandle()>=0) {
      // or an extension-specific project will work, too
      return MF_ENABLED;
   }

   return MF_GRAYED;
}

_command void project_tool_wizard(int projectHandle = _ProjectHandle(), int isExtProject = 0, bool doMakeCopy = true) name_info(',')
{
   // if this is a language-specific project, then we do not
   // bother with configurations
   if (projectHandle<0) {
      isExtProject=1;
      handle:=_fileProjectSetCurrentOrCreate(auto editorctl_wid,auto config);
      if (handle<0) {
         return;
      }
   } else {
      if (projectHandle==_fileProjectHandle()) {
         isExtProject=1;
      }
   }

   if (doMakeCopy) {
      origProjHandle := projectHandle;
      projectHandle = _xmlcfg_create(_xmlcfg_get_filename(origProjHandle), VSENCODING_UTF8);
      _xmlcfg_copy(projectHandle, TREE_ROOT_INDEX, origProjHandle, TREE_ROOT_INDEX, VSXMLCFG_COPY_CHILDREN);
   }

   typeless callback_table:[];
   setupProjectToolWizardTable(callback_table, projectHandle, isExtProject);

   WIZARD_INFO info;
   info.dialogCaption = 'Add new project tool';
   info.parentFormName = '_project_tool_wizard_form';
   info.callbackTable = callback_table;

   result:=_Wizard(&info);

   if (doMakeCopy) {
      if (result!=COMMAND_CANCELLED_RC) {
         // now save the project file
         if (isExtProject) {
            _fileProjectSaveCurrent(projectHandle);
         } else {
            _ProjectSave(projectHandle);
         }
         projName := _xmlcfg_get_filename(projectHandle);

         // IF we are modifying the active project
         if (!isExtProject && projName == _project_name) {
            _ProjectCache_Update(projName);
            p_window_id._WorkspacePutProjectDate(projName);

            p_window_id.call_list("_prjupdatedirs_");

            // regenerate the makefile
            p_window_id._maybeGenerateMakefile(projName);
            p_window_id.call_list("_prjupdate_");
         } else if (isExtProject) {
            //readAndParseAllExtensionProjects();
            maybeResetLanguageProjectToolList(isExtProject);
         }
      }

      _xmlcfg_close(projectHandle);
   }
}

static void setupProjectToolWizardTable(typeless (&callback_table):[], int projectHandle, int isExtProject)
{
// callback_table:['destroy'] = ptw_destroy;
   callback_table:['finish'] = ptw_finish;

   // slide 0 - basic info
   callback_table:['ctlslide0.create'] = ptw_basic_create;
   callback_table:['ctlslide0.next'] = ptw_basic_next;
   callback_table:['ctlslide0.skip'] = 0;

   // slide 1 - configurations
   callback_table:['ctlslide1.next'] = ptw_configurations_next;
   callback_table:['ctlslide1.finishon'] = 0;
   callback_table:['ctlslide1.skip'] = 0;

   // slide 2 - advanced options
   callback_table:['ctlslide2.create'] = ptw_advanced_create;
   callback_table:['ctlslide2.finishon'] = 0;
   callback_table:['ctlslide2.skip'] = 0;

   // slide 3 - finish up
   callback_table:['ctlslide3.finishon'] = 1;
   callback_table:['ctlslide3.skip'] = 0;

   // some info we just want to send to the wizard
   callback_table:[ISEXTPROJECT_KEY] = isExtProject;
   callback_table:[PROJECT_HANDLE_KEY] = projectHandle;

}

static int ptw_get_isExtProject()
{
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   return pWizardInfo->callbackTable:[ISEXTPROJECT_KEY];
}

static int ptw_get_project_handle()
{
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   return pWizardInfo->callbackTable:[PROJECT_HANDLE_KEY];
}

static int ptw_basic_create()
{
   projectHandle := ptw_get_project_handle();

   // handles all the little gui tweaks for the whole wizard
   panelWidth := ctlslide0.p_width;

   pad_x := slide0_caption.p_x;

   // which of these labels is longest?  align them!
   slide0_name.p_x = ctllabel15.p_x_extent + (pad_x intdiv 2);
   slide0_name.p_width = panelWidth - pad_x - slide0_name.p_x;
   slide0_exe.p_x = slide0_args.p_x = slide0_name.p_x;

   // fill in the combo box full of the existing tools
   slide0_copy_combo.ptw_fill_in_existing_tool_names(projectHandle);
   slide0_copy_combo.p_enabled = false;

   rightAlign := panelWidth - pad_x;
   sizeBrowseButtonToTextBox(slide0_exe, ctlimage1.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(slide0_args, ctlToolCmdLineButton.p_window_id, 0, rightAlign);

   ctlRunFromDir.p_x = ctllabel10.p_x_extent + (pad_x intdiv 2);
   sizeBrowseButtonToTextBox(ctlRunFromDir, ctl_browse_dir.p_window_id, ctlRunFromButton.p_window_id, rightAlign);

   ctlToolSaveCombo.p_x = ctlRunFromDir.p_x;

   // call the creation functions of other slide,
   // so their controls will be ready
   ptw_configurations_init();
   ptw_advanced_init();
   ptw_end_init();

   return 0;
}

static void ptw_fill_in_existing_tool_names(int handle)
{
   _str tools[];
   _str added:[];
   _ProjectGet_Targets(handle, tools, '');
   for (i := 0; i < tools._length(); i++) {
      // this is the index into the project file
      index := (int)tools[i];

      // get the menu caption - we need to make sure this is not a dash (separator)
      caption := _ProjectGet_TargetMenuCaption(handle, index);
      if (caption != '-') {
         // get the name
         name := _ProjectGet_TargetName(handle, index);

         lowcaseItem := lowcase(name);
         if (!added._indexin(lowcaseItem)) {
            _lbadd_item(name);
            added:[lowcaseItem] = 1;
         }
      }
   }

   _lbsort();
   _lbtop();
   _lbselect_line();
}
static _str getToolNameFromMenuCaption(_str caption) {
   return stranslate(caption,'','&');
}

static int ptw_basic_next()
{
   // make sure the necessary fields are filled in
   if (slide0_name.p_text == '') {
      _message_box("Please enter a menu caption for your new project tool.");
      return 1;
   }

   // make sure we don't already have a tool by this name
   if (_ProjectDoes_TargetExist(ptw_get_project_handle(), getToolNameFromMenuCaption(slide0_name.p_text))) {
      _message_box('A project tool with the name "'getToolNameFromMenuCaption(slide0_name.p_text)'" already exists.');
      return 1;
   }

   return 0;
}

static void ptw_configurations_init()
{
   // load the configurations in the project into the tree
   _str configs[];
   _ProjectGet_ConfigNames(ptw_get_project_handle(), configs);
   configs._sort();

   index := 0;
   for (i := 0; i < configs._length(); i++) {
      index = slide1_tree._TreeAddItem(TREE_ROOT_INDEX, configs[i], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);

      // go ahead and just select them all
      slide1_tree._TreeSetCheckState(index, TCB_CHECKED);
   }

   slide1_tree.p_CheckListBox = true;
}

static int ptw_configurations_next()
{
   // they need to pick at least one
   index := slide1_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      if (slide1_tree._TreeGetCheckState(index) == TCB_CHECKED) {
         return 0;
      }
      index = slide1_tree._TreeGetNextSiblingIndex(index);
   }

   // we got to the end, with nothing picked
   _message_box("Please select at least one configuration.");
   return 1;
}

static void ptw_advanced_init()
{
   ProjectFormFillInToolSaveCombo();
}

static int ptw_advanced_create()
{
   // if we are not copying from an existing tool,
   // set a default value for the save option
   if (!slide0_copy_check.p_value) {
      ptw_set_default_save_option();
   }

   return 0;
}

static void ptw_set_default_save_option()
{
   // if the current file option (%f) is specified in the arguments, then
   // we default to save the current file
   defaultOption := VPJ_SAVEOPTION_SAVENONE;
   if (pos('%f', slide0_args.p_text)) {
      defaultOption = VPJ_SAVEOPTION_SAVECURRENT;
   }
}

static void ptw_set_save_option(_str option)
{
   ctlToolSaveCombo._lbdeselect_all();
   ctlToolSaveCombo.p_line=ProjectFormSaveOptionToLine(option);
   ctlToolSaveCombo._lbselect_line();
   ctlToolSaveCombo.p_text=ctlToolSaveCombo._lbget_text();
}

static void ptw_end_init()
{
   // determine if this was made from a template
   projectHandle := ptw_get_project_handle();
   if (_ProjectGet_AssociatedFileType(projectHandle) == '') {
      type := _ProjectGet_ActiveType();

      if (type == '') {
         type = _ProjectGet_TemplateName(projectHandle);
      }

      // if we have a type, then save it
      // For now, don't update type template for single file projects which have 
      // different templates.
      if (type != '' && !ptw_get_isExtProject()) {
         TEMPLATE_TYPE(type);
         slide3_add_to_template.p_visible = true;
      } else {
         slide3_add_to_template.p_visible = false;
      }
   }
}

static int ptw_finish()
{
   // get the list of checked configs
   _str configs[];
   projectHandle := ptw_get_project_handle();
   isExtProject := ptw_get_isExtProject();
   /*if (isExtProject) {
      configName := langId;
      configs[0] = configName;

      // make sure there is a section for this lang in the extension projects file

      if (_ProjectGet_ConfigNode(projectHandle, configName)<0) {
         _ProjectCreateLangSpecificConfig(projectHandle, configName);
      }
   } else */{
      index := slide1_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         if (slide1_tree._TreeGetCheckState(index) == TCB_CHECKED) {
            configs[configs._length()] = slide1_tree._TreeGetCaption(index);
         }
         index = slide1_tree._TreeGetNextSiblingIndex(index);
      }
   }

   saveToolToFile(projectHandle, configs);

   // do we save this to the project template as well?
   if (slide3_add_to_template.p_visible && slide3_add_to_template.p_value) {
      saveToolToTemplate(_ProjectGet_TemplateName(projectHandle), configs);
   }

   return 0;
}

static void saveToolToFile(int handle, _str (&configs)[])
{
   for (i := 0; i < configs._length(); i++) {
      // add the tool
      index := _ProjectAddTool(handle, getToolNameFromMenuCaption(slide0_name.p_text), configs[i],slide0_name.p_text);

      // set the command line
      cmdLine :=strip(_maybe_quote_filename(strip(slide0_exe.p_text))' 'strip(slide0_args.p_text));
      _ProjectSet_TargetCmdLine(handle, index, cmdLine);

      // run from dir?
      _ProjectSet_TargetRunFromDir(handle, index, strip(ctlRunFromDir.p_text,'B','"'));

      // set some sensible defaults for other advanced options
      // capture output = true, output to build window = true
      _ProjectSet_TargetCaptureOutputWith(handle, index, ProjectFormGetCaptureOutputWith());

      // save option
      _ProjectSet_TargetSaveOption(handle, index, ProjectFormGetToolSaveComboValue());
   }
}

static void saveToolToTemplate(_str templateName, _str (&configs)[])
{
   // first, look for the template in the existing user and system templates
   foundInHandle := 0;
   foundAtNode := 0;

   // first check the user templates
   userTemplates :=  _ProjectOpenUserTemplates();
   sysTemplates := _ProjectOpenTemplates();
   foundAtNode = _ProjectTemplatesGet_TemplateNode(userTemplates, templateName, false);
   if (foundAtNode < 0) {
      // not in the user templates, so see if it is in the system templates
      foundAtNode = _ProjectTemplatesGet_TemplateNode(sysTemplates, templateName, false);
      if (foundAtNode > 0) {
         foundInHandle = sysTemplates;
      }
   } else {
      foundInHandle = userTemplates;
   }

   if (foundAtNode <= 0) {
      // we didn't find it, oh well
      _xmlcfg_close(userTemplates);
      _xmlcfg_close(sysTemplates);
      return;
   }

   // create a new file to store this as we work with it
   tempHandle := _xmlcfg_create('',VSENCODING_UTF8);
   node := _xmlcfg_copy(tempHandle, TREE_ROOT_INDEX, foundInHandle, foundAtNode, VSXMLCFG_COPY_AS_CHILD);
   _xmlcfg_set_name(tempHandle, node, VPJTAG_PROJECT);
   _ProjectTemplateExpand(sysTemplates, tempHandle, true);

   // this does the work
   saveToolToFile(tempHandle, configs);

   oldNode := _ProjectTemplatesGet_TemplateNode(userTemplates, templateName, true);
   ProjectNode := _xmlcfg_set_path(tempHandle, "/"VPJTAG_PROJECT);

   int NewNode=_xmlcfg_copy(userTemplates, oldNode, tempHandle, ProjectNode,0);
   _xmlcfg_set_name(userTemplates, NewNode, VPTTAG_TEMPLATE);

   _xmlcfg_delete(userTemplates, oldNode);
   _ProjectTemplatesSave(userTemplates);

   _xmlcfg_close(tempHandle);
   _xmlcfg_close(userTemplates);
   _xmlcfg_close(sysTemplates);
}

void slide0_copy_check.lbutton_up()
{
   slide0_copy_combo.p_enabled = (slide0_copy_check.p_value != 0);
   call_event(slide0_copy_combo, ON_CHANGE);
}

void slide0_copy_combo.on_change()
{
   // make sure this is turned on
   if (slide0_copy_check.p_value) {
      handle := ptw_get_project_handle();

      // now update all the other controls to reflect the values for this tool
      tool := slide0_copy_combo.p_text;
      toolNode := _ProjectGet_TargetNode(handle, tool, '');
      if (toolNode > 0) {
         // executable and arguments
         cmdLine := _ProjectGet_TargetCmdLine(handle, toolNode);
         exec:=parse_file(cmdLine,false);
         args:=strip(cmdLine);
         //parse cmdLine with auto exec auto args;
         slide0_exe.p_text = exec;
         slide0_args.p_text = args;

         // run from dir
         ctlRunFromDir.p_text = _ProjectGet_TargetRunFromDir(handle, toolNode);

         // save option
         saveOption := _ProjectGet_TargetSaveOption(handle, toolNode);
         ptw_set_save_option(saveOption);

         // capture output, output to build window
         output := _ProjectGet_TargetCaptureOutputWith(handle, toolNode);
         if (output == VPJ_CAPTUREOUTPUTWITH_PROCESSBUFFER) {
            ctlToolCaptureOutput.p_value = 1;
            ctlToolOutputToConcur.p_value = 1;
         } else if (output == VPJ_CAPTUREOUTPUTWITH_REDIRECTION) {
            ctlToolCaptureOutput.p_value = 1;
               ctlToolOutputToConcur.p_value = 0;
         } else {
            ctlToolCaptureOutput.p_value = ctlToolOutputToConcur.p_value = 0;
         }
      }
   }
}

void slide1_select_all.lbutton_up()
{
   index := slide1_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      slide1_tree._TreeSetCheckState(index, TCB_CHECKED);

      index = slide1_tree._TreeGetNextSiblingIndex(index);
   }
}

void slide1_clear_all.lbutton_up()
{
   index := slide1_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      slide1_tree._TreeSetCheckState(index, TCB_UNCHECKED);

      index = slide1_tree._TreeGetNextSiblingIndex(index);
   }
}
