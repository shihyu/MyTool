////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46084 $
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
#include "xml.sh"
#import "codetemplate.e"
#import "complete.e"
#import "ctcategory.e"
#import "ctitem.e"
#import "dirlist.e"
#import "fileman.e"
#import "files.e"
#import "guicd.e"
#import "ini.e"
#import "main.e"
#import "makefile.e"
#import "project.e"
#import "projutil.e"
#import "recmacro.e"
#import "stdprocs.e"
#import "wkspace.e"
#endregion

// Callback used to copy a file with prompt for overwriting destination
static int copyFile(_str src, _str& target);
// Callback used to prompt for undefined and prompt-able paramters in the template
static int promptForParameters(ctTemplateDetails_t& details, ctTemplateContent_t& content);
static void maybePrependJavaKeyword(_str &val, _str keyword);


// Disable "Add to current project" check box
#define CTADDITEMFLAG_DISABLE_ADD_TO_PROJECT 0x1
// Hide "Add to current project" check box
#define CTADDITEMFLAG_HIDE_ADD_TO_PROJECT    0x2

_command int add_item(_str& templatePath="", _str& itemName="", _str& itemLocation="", boolean& addToProject=false, boolean quiet=false, ctTemplateContent_t* resultContent=null, ctOptions_t options=null) name_info(","VSARG2_READ_ONLY)
{
   int was_recording = _macro();
   // Delete recorded call to add_item()
   _macro_delete_line();

   _str cwd = getcwd();

   // Can files be added to this project type?
   boolean canAddFiles = true;


   // Expand out embedded environment variables (e.g. %VSROOT%, etc.)
   templatePath=_replace_envvars(templatePath);
   if( templatePath=="" || itemName=="" ) {
      int flags = 0;
      // RGH - 5/3/2006
      // Eclipse not using the addToProject button right now 
      if (isEclipsePlugin()) {
         addToProject = false;
      } else if( _project_name == "") {
         flags |= CTADDITEMFLAG_DISABLE_ADD_TO_PROJECT;
      } else if( !_CanWriteFileSection(_project_name) ) {
         // We are not able to add files to some associated project types (Visual Studio C#, VB, etc.),
         // so we must turn off and disable the ability to add item to project.
         flags |= CTADDITEMFLAG_DISABLE_ADD_TO_PROJECT;
         canAddFiles=false;
      }
      // Note:
      // (addToProject && _project_name!="") because we still want
      // to macro record what was passed in for addToProject.
      ctTemplateDetails_t details;
      // if templatePath was passed in, then we know what template the user wants to instantiate...
      _str result;
      if (templatePath :!= "") {
         int handle = _ctTemplateOpen(templatePath);
         _ctTemplate_GetTemplateDetails(handle, details);
         // ...so find the name from the template file and pass it to show
         result = show("-modal _ctAddItem_form",
                            flags,itemLocation,(addToProject && _project_name!="" && canAddFiles),'','', details.Name);
      } else {
         result = show("-modal _ctAddItem_form",
                            flags,itemLocation,(addToProject && _project_name!="" && canAddFiles));
      }
      if( result=="" ) {
         // User cancelled
         return COMMAND_CANCELLED_RC;
      }
      _str ht:[] = _param1;
      templatePath = ht:["template"];
      itemName = ht:["name"];
      itemLocation = ht:["location"];
      addToProject = (boolean)( ht:["project"] != 0 );
   }
   if( itemLocation=="" ) {
      itemLocation=getcwd();
   }

   // Fetch global parameters for all templates...if necessary
   if (options == null) {
      int status = initializeCtOptionsTable(options);
      if (status != 0) {
         return(status);
      }
   }

   itemLocation=absolute(itemLocation,cwd);
   ctTemplateContent_t content; content._makeempty();
   _str statusMsg = "";
   int status = _ctInstantiateTemplate(templatePath,itemName,itemLocation,
                                       content,
                                       options.Parameters,
                                       copyFile,promptForParameters,
                                       statusMsg);
   if( resultContent ) {
      resultContent->_makeempty();
      *resultContent=content;
   }

   // Files already open may have been overwritten, so catch it now.
   // By calling _ReloadFileList() we only reload those files that
   // were instantiated with the template.
   _str list[]; list._makeempty();
   int i;
   for( i=0; i<content.Files._length(); ++i ) {
      list[list._length()]=content.Files[i].TargetFilename;
   }
   int orig_actapp = def_actapp;
   def_actapp |= ACTAPP_WARNONLYIFBUFFERMODIFIED;
   // RGH - 5/2/2006
   // For Eclipse we refresh the workspace here so it knows about the files before we open buffers
   if (!isEclipsePlugin()) {
      _ReloadFileList(list);
   } else {
      _eclipse_refresh_workspace();
   }
   def_actapp=orig_actapp;

   if( status!=0 ) {
      if( !quiet && status!=COMMAND_CANCELLED_RC ) {
         if( statusMsg=="" ) {
            statusMsg="Error adding template. ":+get_message(status);
         }
         _message_box(statusMsg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return status;
   }

   // Open file(s) created by template
   if( content.Files._length() > 0 ) {
      _str firstFilename = content.Files[0].TargetFilename;
      _str edit_options = "";
      status=_mdi.p_child.edit(edit_options" "maybe_quote_filename(firstFilename));
      if( status!=0 ) {
         _str msg = "Error opening file:\n\n":+
                    firstFilename:+"\n\n":+
                    get_message(status);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return status;
      }
   }

   if( addToProject && _project_name!="" && canAddFiles ) {
      // Add instantiated template files to project
      _str targetFileList[]; targetFileList._makeempty();
      _str msg = "";
      for( i=0; i<content.Files._length(); ++i ) {
         _str TargetFilename = content.Files[i].TargetFilename;
         status=project_add_file(TargetFilename,true,_project_name,msg);
         // If error and not simply a case of the file already in the project
         if( status!=0 && status!=2 ) {
            if( quiet ) {
               // No way to ask the user if they want to continue, so bail
               break;
            }
            msg="Error adding file to project.\n\n":+
                TargetFilename:+"\n\n":+
                "The status returned was:\n":+
                "\t":+msg:+"\n\n":+
                "Continue?\n\n":+
                "Click Yes to continue.\n":+
                "Click No to abort but leave files already added.\n":+
                "Click Cancel to abort and remove all files already added.";
            int status2 = _message_box(msg,"",MB_YESNOCANCEL|MB_ICONQUESTION);
            if( status2!=IDYES ) {
               if( status2==IDCANCEL ) {
                  // Abort and remove all files added to project so far
                  if( targetFileList._length() > 0 ) {
                     _str del_list = "";
                     int j;
                     for( j=0; j<targetFileList._length(); ++j ) {
                        del_list = del_list" "maybe_quote_filename(targetFileList[j]);
                     }
                     del_list=strip(del_list,'B');
                     status2=project_remove_filelist(_project_name,del_list);
                     if( status2!=0 ) {
                        // Who cares if quiet=true - this is serious
                        msg="Warning: Unable to remove files from project. ":+get_message(status2);
                        _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
                     }
                  }
               }
               break;
            }
         }
         // 1. Do not add file to targetFileList on error.
         // 2. Do not add file to targetFileList if it already exists, since we
         //    would not want to remove it on abort.
         if( status==0 ) {
            targetFileList[targetFileList._length()]=TargetFilename;
         }
         // If we got here, then we are continuing whether there was an error or not
         status=0;
      }
   }

   // Turn macro recording back on and insert custom recorded call
   _macro('m',was_recording);
   if( addToProject ) {
      // Use _RelativeToProject() for item location in recorded macro, since
      // a user recording a macro to add project items would almost always
      // want it recorded so that files are added to the CURRENT project's
      // working directory. If for some reason this is not the case, then
      // they can always edit the recorded macro and change the location.
      // IMPORTANT:
      // Very important that itemLocation have a trailing FILESEP before
      // calling _RelativeToProject(). Otherwise the last name part of the
      // path is picked up as a filename, not a directory.
      _maybe_append_filesep(itemLocation);
      _macro_call("add_item",
                  _encode_vslickconfig(_encode_vsroot(templatePath,true,false),true,false),
                  itemName,
                  _RelativeToProject(itemLocation),
                  addToProject,
                  quiet,
                  0);
   } else {
      // Use relative() for item location in recorded macro, since a
      // user recording a macro to add relative to the current working directory
      // would almost always want it recorded so that files are added to
      // the current working directory. If for some reason this is not the
      // case, then they can always edit the recorded macro and change the
      // location.
      // IMPORTANT:
      // Very important that itemLocation have a trailing FILESEP before
      // calling relative(). Otherwise the last name part of the  path is
      // picked up as a filename, not a directory.
      _maybe_append_filesep(itemLocation);
      _macro_call("add_item",
                  _encode_vslickconfig(_encode_vsroot(templatePath,true,false),true,false),
                  itemName,
                  relative(itemLocation,cwd,false),
                  addToProject,
                  quiet,
                  0);
   }
   return 0;
}


/**
 * Adds a template item (class, interface, enum) to a Java package.  Only
 * callable from the right-click context menu in the Projects tool window
 * with autofolders as package view.
 * 
 * @param item name of the Java item to add
 */
_command void add_java_item(_str item = '') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY) {
   int proj_wid = _find_object('_tbprojects_form._proj_tooltab_tree');
   /**
    * make sure this was called from the project tool window...just in
    * case.  the menu item wouldn't be loaded if this wasn't java and it
    * wasn't the package view, and we're executing FROM_MENU_ONLY so we
    * really don't have to check EVERYTHING...  */
   if (_get_focus() :!= proj_wid) return;
   _str package = proj_wid._TreeGetCaption(proj_wid._TreeCurIndex());
   // open up the project file and find the node for the package
   int handle = _ProjectHandle();
   if (handle <= 0) return; 
   int node=_xmlcfg_find_simple(handle, "/Project/Files/Folder[@Name='"package"'][@Type='Package']");
   if (node <= 0) return; 
   int child = _xmlcfg_get_first_child(handle, node);
   _str itemLocation = '';
   // extract the location of the files in the package from one of the file nodes
   if (child >= 0) {
      _str projpath=_strip_filename(_xmlcfg_get_filename(handle),'N');
      _str relfile=_xmlcfg_get_attribute(handle, child, 'N');
      itemLocation=absolute(_strip_filename(relfile, 'N'), projpath);
   }

   _str templatePath = '';
   if (item :!= '') {
      templatePath = _ctGetSysItemTemplatesDir():+ FILESEP :+ "Java":+FILESEP;
   }
   if (item :== 'Java Class') {
      templatePath = templatePath :+ "Class":+FILESEP :+ "Basic Class" :+ FILESEP :+ "BasicClass.setemplate";
   } else if (item :== 'Java Interface') {
      templatePath = templatePath :+ "Interface":+FILESEP :+ "Interface.setemplate";
   } else if (item :== 'Java Enum') {
      templatePath = templatePath :+ "Enum":+FILESEP :+ "Enum.setemplate";
   }

   ctOptions_t options; 
   int status = initializeCtOptionsTable(options);
   if (status != 0) {
      return;
   }
   // we know what package to add the new file to...so lets fill it in
   if (strip(package) :!= "(default package)") {
      initializeCtParameter(options, "package", package, true);
   }
   _str ItemName = '';
   add_item(templatePath, ItemName, itemLocation, true, false, null, options);
}

/**
 * Used to initialize a template substitution parameter in order to
 * pre-fill the field in the 'prompt for parameters' dialog.
 * 
 * @param options parameter struct (which should be passed to add_item)
 * @param key the name of the parameter
 * @param val the initial value
 * @param prompt should we prompt the user for this value?
 * @param prompt_str string to display at the prompt
 */
static void initializeCtParameter(ctOptions_t &options,_str key, _str val, boolean prompt, _str prompt_str = ''){
   options.Parameters:[key].Value = val;
   options.Parameters:[key].Prompt = prompt;
   options.Parameters:[key].PromptString = prompt_str;
}

/**
 * Initialize a ctOptions struct with the global parameters from the
 * options.xml file.  
 * 
 * @param options struct to be initialized
 * 
 * @return int 0 on success
 */
static int initializeCtOptionsTable(ctOptions_t &options){
   options._makeempty();
   _str options_filename = _ctOptionsGetOptionsFilename();
   if( options_filename!="" ) {
      int status = _ctOptionsGetOptions(options_filename,options);
      if( status!=0 ) {
         // Error
         _str msg = "Error fetching template options from file. "get_message(status):+"\n\n":+
                    options_filename;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return(status);
   }
   return(-1);
}

/**
 * Copy source file to target. If file already exists at destination, then prompt user
 * to overwrite.
 * 
 * @param src    Source filename to copy from.
 * @param target Target filename to copy to.
 * 
 * @return 0 on success, <0 on error. Error is returned when there was an error
 * copying the file, or the user was prompted to overwrite and hit Cancel.
 */
static int copyFile(_str src, _str& target)
{
   if( src==null || src=="" || target==null || target=="" ) {
      return VSRC_INVALID_ARGUMENT;
   }
   if( !file_exists(src) ) {
      _str msg = "Unable to copy file. "get_message(FILE_NOT_FOUND_RC):+"\n\n":+
                 src;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return FILE_NOT_FOUND_RC;
   }
   if( file_exists(target) ) {
      _str msg = "File already exists at destination.\n\n":+
                 target:+"\n\n":+
                 "Overwrite?";
     int status = _message_box(msg,"",MB_YESNOCANCEL|MB_ICONQUESTION,IDNO);
     if( status==IDNO ) {
        // Not an error
        return 0;
     } else if( status==IDCANCEL ) {
        return COMMAND_CANCELLED_RC;
     }
     // Make sure we can overwrite it
#if __UNIX__
     chmod("\"u+w g+w o+w\" " maybe_quote_filename(target));
#else
     chmod("-r " maybe_quote_filename(target));
#endif
   }
   int status = copy_file(src,target);
   if( status!=0 ) {
      _str msg = "Error copying file. "get_message(status):+"\n\n":+
                 "From:\n":+
                 "\t":+src:+"\n\n":+
                 "To:\n":+
                 "\t":+target;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }

   // Make sure we can modify and save it (process substitution parameters)
#if __UNIX__
   chmod("\"u+w g+w o+w\" " maybe_quote_filename(target));
#else
   chmod("-r " maybe_quote_filename(target));
#endif

   return status;
}

/**
 * Kind of a hack...we don't have the ability to eliminate parts of the
 * template if certain values are not specified.  So to allow for generic
 * Java templates, check if a package/interface/superclass was specified,
 * and if so, add the package/implements/extends keywords.
 * 
 * @param val parameter value from user
 * @param keyword keyword associated with val
 */
static void maybePrependJavaKeyword(_str &val, _str keyword){
   if (strip(val) :!= '') {
      if (keyword :== 'implements' || keyword :== 'extends'){
         val = keyword :+ ' ' :+ val;
      } else if (keyword :== 'package') {
         val = keyword :+ ' ' :+ val :+ ';';
      }
   }
}

/**
 * Prompt for any undefined parameters and parameters that are specifically marked as Prompt-able
 * in the template.
 * 
 * @param details ctTemplateDetails_t structure for the template being instantiated.
 * @param content ctTemplateContent_t structure for the template being instantiated.
 *                Complete source, target, and options information is stored here at
 *                the time this function is called.
 * 
 * @return Number of parameters prompted for. <0 on error or command cancelled.
 */
static int promptForParameters(ctTemplateDetails_t& details, ctTemplateContent_t& content)
{
   // Put together a sorted list of undefined parameters
   _str undefIndex[]; undefIndex._makeempty();
   _str parm;
   for( parm._makeempty();; ) {
      content.Parameters._nextel(parm);
      if( parm._isempty() ) {
         break;
      }
      if( content.Parameters:[parm].Prompt ) {
         _str PromptString = content.Parameters:[parm].PromptString;
         if( PromptString!=null && PromptString!="" ) {
            // Sort on prompt string
            undefIndex[undefIndex._length()]=PromptString"\t"parm;
         } else {
            // Sort on parameter name
            undefIndex[undefIndex._length()]=parm"\t"parm;
         }
      }
   }
   if( undefIndex._length() == 0 ) {
      // Nothing to do
      return 0;
   }
   undefIndex._sort();

   // Prompt for undefined parameter values
   int orig_wid;
   get_window_id(orig_wid);
   int input_wid, output_wid;
   if( _create_temp_view(input_wid) == 0 ) {
      // Error
      return ERROR_OPENING_FILE_RC;
   }
   activate_window(input_wid);
   _delete_line();
   int i;
   for( i=0; i<undefIndex._length(); ++i ) {
      _str Name="", PromptString="";
      parse undefIndex[i] with PromptString"\t"Name;
      _str line = PromptString;
      if( ! content.Parameters:[Name].Value._isempty() ) {
         line = line :+ ":":+content.Parameters:[Name].Value;
      }
      insert_line(line);
   }
   activate_window(orig_wid);
   _str result = show("-modal _textbox_form",
                      "Parameter Entry",
                      TB_VIEWID_INPUT|TB_VIEWID_OUTPUT,
                      "",                 // width ('' or 0 uses default)
                      "",                 // Optional help item
                      "",                 // Buttons and captions
                      "",                 // Retrieve name
                      input_wid);
   if( result=="" || !isinteger(result) || (int)result<=0 ) {
      // User cancelled
      return COMMAND_CANCELLED_RC;
   }
   output_wid=(int)result;
   activate_window(output_wid);
   top();up(); i=0;
   while( !down() ) {
      get_line(auto val);
      val=strip(val);
      _str PromptString="", Name="";
      parse undefIndex[i] with PromptString"\t"Name;
      if (details.Name :== 'Java Class' || details.Name :== 'Java Enum' || details.Name :== 'Java Interface') {
         maybePrependJavaKeyword(val, PromptString);
      }
      content.Parameters:[Name].Value=val;
      content.Parameters:[Name].Prompt=false;
      ++i;
   }
   // We do not want to get re-prompted for parameters on the slim chance that
   // we reached the last line of output before we reached the last undefined
   // parameter value, so set the rest to not prompt.
   for( ;i<undefIndex._length(); ++i ) {
      _str PromptString="", Name="";
      parse undefIndex[i] with PromptString"\t"Name;
      content.Parameters:[Name].Prompt=false;
   }
   _delete_temp_view(output_wid);

   return ( undefIndex._length() );
}

#define ENTER_NAME "<Enter name>"
#define NO_DESCRIPTION "<No description>"


//
// Add Item form
//

defeventtab _ctAddItem_form;

void ctl_add.on_create(int flags=0, _str defaultLocation="", boolean addToProject=false,
                       _str sysTemplatesPath="", _str userTemplatesPath="", _str defaultTemplate='')
{
   _SetDialogInfoHt("flags",flags);
   _SetDialogInfoHt("defaultLocation",defaultLocation);
   // RGH - 5/3/2006
   // For Eclipse we load the root dir of the active project into location and
   // disable the addToProject button
   if (isEclipsePlugin()) {
      ctl_add_to_project.p_visible = false;
      _str name = '';
      _eclipse_get_active_project_name(name);
      if (name :!= ''){
         _str loc = '';
         _eclipse_get_project_dir(loc);
         _SetDialogInfoHt("defaultLocation",loc);
      }
   } else {
      ctl_add_to_project.p_value = (int)addToProject;
      if( flags & CTADDITEMFLAG_HIDE_ADD_TO_PROJECT ) {
         ctl_add_to_project.p_visible=false;
      } else if( flags & CTADDITEMFLAG_DISABLE_ADD_TO_PROJECT ) {
         ctl_add_to_project.p_enabled=false;
      }
   }
   ctl_category._ctCategoryInit(sysTemplatesPath,userTemplatesPath);
   // Once to restore the category...
   if (defaultTemplate :== '') {
      restoreRetrieveHistory();
   }
   // Inform the category list that the current category has changed
   ctl_category._ctCategoryOnChangeSelected();
   // ...and again to restore the item now that the item list has been filled in.
   // Note:
   // This is a little inefficient because the category is restored twice.
   if (defaultTemplate :== '') {
      restoreRetrieveHistory();
   } else {
      // if default Template was passed in, we know what template the user wants to instantiate
      // so don't use the history to open up an item, just find what they want.
      _str name = _strip_filename(defaultTemplate, 'P');
      int widCategory = p_active_form._find_control("ctl_category");
      boolean old_inOnChange = widCategory._dlInOnChange(1);
      if( name!="" ) {
         int widItem = p_active_form._find_control("ctl_item");
         if( widItem==0 ) {
            // ??
            return;
         }
         widItem._ctItemListSetCurrentItem(name);
      }
      widCategory._dlInOnChange((int)old_inOnChange);
   }
}

void _ctAddItem_form.on_load()
{
   _control ctl_itemname;
   p_window_id=ctl_itemname;
   _set_sel(1,length(p_text)+1);_set_focus();
}

static boolean onAddItem(_str& templatePath, _str& itemName, _str& itemLocation, boolean& addToProject)
{
   // Verify all form input

   _control ctl_item;
   _control ctl_itemname;
   _control ctl_location;

   // Item
   _str path;
   if( !ctl_item._ctItemListGetCurrentItem(path) ) {
      // Should never get here
      _str msg = "An item must be selected. Please select an item from the Item list.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return false;
   }

   // Name
   _str name = ctl_itemname.p_text;
   if( name=="" || name==ENTER_NAME || pos(CTDEFAULTNAME_INVALID_CHARS,name,1,'er') ) {
      _str msg = "A valid name is required. Please enter a valid name in the Name field.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_itemname;
      _set_sel(1,length(p_text)+1);_set_focus();
      return false;
   }

   // Location
   _str location = ctl_location.p_text;
   location=strip(location,'B','"');
   if( location=="" ) {
      _str msg = "A location is required. Please enter a location in the Location field.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_location;
      _set_sel(1,length(p_text)+1);_set_focus();
      return false;
   }
#if __UNIX__
   location=_unix_expansion(location);
#endif
   if( !isdirectory(location) ) {
      _str msg = "Location does not exist:\n\n":+
                 location:+"\n\n":+
                 "Create?";
      int status = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
      if( status!=IDYES ) {
         p_window_id=ctl_location;
         _set_sel(1,length(p_text)+1);_set_focus();
         return false;
      }
      status=make_path(location);
      if( status!=0 ) {
         msg="Error creating directory \"":+location:+"\".":+get_message(status);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctl_location;
         _set_sel(1,length(p_text)+1);_set_focus();
         return false;
      }
   }

   _control ctl_confirm;
   if( ctl_confirm.p_value != 0 ) {
      // Prompt user to confirm files to be added.
      // This requires us to almost-instantiate a template.
      ctTemplateDetails_t details; details._makeempty();
      ctTemplateContent_t content; content._makeempty();
      int status = _ctTemplateGetTemplate(path,&details,&content);
      if( status!=0 ) {
         _str msg = "Unable to retrieve template information for confirmation. "get_message(status):+"\n\n":+
                    path;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return false;
      }
      _str templateDir = _strip_filename(path,'n');
      ctTemplateContent_File_t files[]; files._makeempty();
      status=_ctCreateTemplateContentFileList(content,name,details.DefaultName,templateDir,location,files);
      if( status!=0 ) {
         _str msg = "Unable to assemble file list for confirmation. "get_message(status);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return false;
      }
      _str text = "The following files will be created:\n\n";
      int i;
      for( i=0; i<files._length(); ++i ) {
         text=text:+files[i].TargetFilename:+"\n";
      }
      status=_message_box(text,"Confirm File Creation",MB_YESNOCANCEL|MB_ICONQUESTION);
      if( status!=IDYES ) {
         return false;
      }
   }

   templatePath=path;
   itemName=name;
   itemLocation=location;
   // It does not matter if ctl_add_to_project is disabled or hidden.
   // We always use the value, since it is always explicitly set when
   // the dialog is launched.
   addToProject = ( ctl_add_to_project.p_value!=0 );

   return true;
}

/**
 * Save category and item history for the active form.
 */
static void saveRetrieveHistory()
{
   int widCategory = p_active_form._find_control("ctl_category");
   if( widCategory==0 ) {
      // ??
      return;
   }
   _str path = widCategory._ctCategoryGetCategoryPath();
   if( path!="" ) {
      _str name = "";
      int widItem = p_active_form._find_control("ctl_item");
      if( widItem>0 ) {
         _str unused;
         widItem._ctItemListGetCurrentItem(unused,name);
      }
      if( _workspace_filename!="" ) {
         // Save/restore last template by workspace history
         _str info = path'|'name;
         int status = _ini_set_value(VSEWorkspaceStateFilename(_workspace_filename),"Global","LastItemTemplate",info);
         if( status!=0 ) {
            _str msg = "Warning: Failed to save last item template in workspace history. ":+get_message(status);
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
      } else {
         // Save/restore last template by global history
         _str info = path'|'name;
         _append_retrieve(0,info,"_ctAddItem_form.LastItemTemplate");
      }
   }
}

/**
 * Restore category and item history. If a workspace is open, then history
 * is retrieved from the workspace. Otherwise it is retrieved from global
 * autorestore info.
 */
static void restoreRetrieveHistory()
{
   _str path="", name="";

   if( _workspace_filename!="" ) {
      // Save/restore last template by workspace history
      _str info = "";
      int status = _ini_get_value(VSEWorkspaceStateFilename(_workspace_filename),"Global","LastItemTemplate",info);
      if( status==0 ) {
         parse info with path'|'name;
      }
   } else {
      // Save/restore last template by global history
      _str info =_retrieve_value("_ctAddItem_form.LastItemTemplate");
      parse info with path'|'name;
   }
   // Restore category
   if( path!="" ) {
      int widCategory = p_active_form._find_control("ctl_category");
      if( widCategory==0 ) {
         // ??
         return;
      }
      boolean old_inOnChange = widCategory._dlInOnChange(1);
      if( widCategory._ctCategorySetCategoryPath(path) ) {
         // Restore item
         if( name!="" ) {
            int widItem = p_active_form._find_control("ctl_item");
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

void ctl_add.lbutton_up()
{
   _str templatePath = "";
   _str itemName = "";
   _str itemLocation = "";
   boolean addToProject = false;
   if( !onAddItem(templatePath,itemName,itemLocation,addToProject) ) {
      // Error
      return;
   }
   _str ht:[]; ht._makeempty();
   ht:["template"]=templatePath;
   ht:["name"]=itemName;
   ht:["location"]=itemLocation;
   ht:["project"]=addToProject;
   _param1=ht;

   // Save/restore
   saveRetrieveHistory();
   p_active_form._delete_window(0);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

void ctl_browse.lbutton_up()
{
   int wid = p_window_id;
   _str result = _ChooseDirDialog("Choose Location", p_prev.p_text, '', CDN_PATH_MUST_EXIST|CDN_ALLOW_CREATE_DIR|CDN_CHANGE_DIRECTORY);
   if( result=="" ) {
      return;
   }
   p_window_id=wid.p_prev;
   p_text=result;
   end_line();
   _set_focus();
}

void _ctAddItem_form.on_resize()
{
   // Take measurements before rearranging
   int edge_x = ctl_category_label.p_x;
   int edge_y = ctl_category_label.p_y;
   int after_category_cx = ctl_item.p_x - (ctl_category.p_x + ctl_category.p_width);
   int after_category_cy = ctl_description.p_y - (ctl_category.p_y + ctl_category.p_height);
   int after_description_cy = ctl_itemname.p_y - (ctl_description.p_y + ctl_description.p_height);
   int after_itemname_cy = ctl_location.p_y - (ctl_itemname.p_y +ctl_itemname.p_height);
   int after_location_cx = ctl_browse.p_x - (ctl_location.p_x + ctl_location.p_width);
   //int after_location_cy = ctl_add.p_y - (ctl_location.p_y + ctl_location.p_height);
   int after_location_cy = ctl_add_to_project.p_y - (ctl_location.p_y + ctl_location.p_height);
   int after_add_to_project_cy = ctl_nav_divider.p_y - (ctl_add_to_project.p_y + ctl_add_to_project.p_height);
   int after_divider_cy = ctl_bottom_panel.p_y - (ctl_nav_divider.p_y + ctl_nav_divider.p_height);

   // Rearrange

   // Client rectangle
   int client_w = _dx2lx(SM_TWIP,p_active_form.p_client_width);
   int client_h = _dy2ly(SM_TWIP,p_active_form.p_client_height);
   // Control bounds rectangle
   int w = client_w - edge_x*2;
   int h = client_h - edge_y*2;
   ctl_category.p_width = (w - after_category_cx) / 2;
   ctl_item_label.p_x = ctl_item.p_x = ctl_category.p_x + ctl_category.p_width + after_category_cx;
   ctl_item.p_width = w - ctl_category.p_width - after_category_cx;
   // Category and Item tree controls y-origin are fixed. Only the height of the trees vary.
   //ctl_category.p_height=ctl_item.p_height= client_h - ctl_category.p_y - after_category_cy - ctl_description.p_height -
   //   after_description_cy - ctl_itemname.p_height - after_itemname_cy - ctl_location.p_height -
   //   after_location_cy - ctl_add.p_height - edge_y;
   ctl_category.p_height=ctl_item.p_height= client_h - ctl_category.p_y - after_category_cy - ctl_description.p_height -
      after_description_cy - ctl_itemname.p_height - after_itemname_cy - ctl_location.p_height -
      after_location_cy - ctl_add_to_project.p_height - after_add_to_project_cy - ctl_nav_divider.p_height -
      after_divider_cy - ctl_bottom_panel.p_height - edge_y;
   ctl_description.p_y = ctl_category.p_y + ctl_category.p_height + after_category_cy;
   ctl_description.p_width = w;
   ctl_itemname.p_y = ctl_description.p_y + ctl_description.p_height + after_description_cy;
   // Name label and textbox x-origin are fixed. Only the width of the textbox varies.
   ctl_itemname.p_width = client_w - ctl_itemname.p_x - edge_x;
   // The "Name:" label does not line up exactly with the textbox (because it is less high),
   // so must be careful to center it vertically on its textbox.
   ctl_itemname_label.p_y = ctl_itemname.p_y + (ctl_itemname.p_height - ctl_itemname_label.p_height)/2;
   ctl_location.p_y = ctl_itemname.p_y + ctl_itemname.p_height + after_itemname_cy;
   // Location label and textbox x-origin are fixed. Only the width of the textbox varies.
   ctl_location.p_width = client_w - ctl_location.p_x - after_location_cx - ctl_browse.p_width - edge_x;
   // The "Location:" label does not line up exactly with the textbox (because it is shorter),
   // so must be careful to center it vertically on its textbox.
   ctl_location_label.p_y = ctl_location.p_y + (ctl_location.p_height - ctl_location_label.p_height)/2;
   ctl_browse.p_x = ctl_location.p_x + ctl_location.p_width + after_location_cx;
   // The Browse button does not line up exactly with the textbox (because it is taller),
   // so must be careful to center it vertically on its textbox.
   ctl_browse.p_y = ctl_location.p_y + (ctl_location.p_height - ctl_browse.p_height)/2;
   // Add to current project
   ctl_add_to_project.p_y = ctl_location.p_y + ctl_location.p_height + after_location_cy;
   // Divider
   ctl_nav_divider.p_y = ctl_add_to_project.p_y + ctl_add_to_project.p_height + after_add_to_project_cy;
   ctl_nav_divider.p_width = w;
   // Bottom panel (Add, Cancel, Help)
   ctl_bottom_panel.p_y = ctl_nav_divider.p_y + ctl_nav_divider.p_height + after_divider_cy;
   ctl_bottom_panel.p_width = w;
}

void ctl_bottom_panel.on_resize()
{
   // Take measurements before rearranging
   int after_add_cx = ctl_cancel.p_x - (ctl_add.p_x + ctl_add.p_width);

   // Rearrange

   // Client rectangle
   int client_w = _dx2lx(SM_TWIP,p_client_width);
   int client_h = _dy2ly(SM_TWIP,p_client_height);
   // Add, Cancel, Help
   // Note:
   // x-spacing between buttons is all the same, so we reuse after_add_cx for all inter-button spacing.
   ctl_help.p_x = client_w - ctl_help.p_width;
   ctl_cancel.p_x = ctl_help.p_x - after_add_cx - ctl_cancel.p_width;
   ctl_add.p_x = ctl_cancel.p_x - after_add_cx - ctl_add.p_width;
}

defeventtab _ctAddItem_CategoryTree_etab _inherit _ctCategoryTree_etab;

// Override _ctCategoryTree_etab.ON_CREATE so we can initialize the form all
// at once in ctl_add.ON_CREATE.
void _ctAddItem_CategoryTree_etab.on_create()
{
}

/**
 * _ul2_dirtree has an lbutton_double_click, but we do not want
 * it to be called in this case
 */
void _ctAddItem_CategoryTree_etab.enter,lbutton_double_click()
{
   call_event(find_index("_ul2_tree",EVENTTAB_TYPE),last_event(),'E');
}

void _ctAddItem_CategoryTree_etab.on_change(int reason, int nodeIndex)
{
   if( _dlInOnChange() ) {
      // Recursion not allowed!
      return;
   }

   boolean old_inOnChange = _dlInOnChange(1);
   switch( reason ) {
   case CHANGE_SELECTED:
      {
         mou_hour_glass(1);
         _str catPath = _dlBuildSelectedPath();
         _str templatePath = _ctCategoryToTemplatePath(catPath);
         if( templatePath!="" ) {
            ctl_item._ctItemListInit(templatePath);
         }
         mou_hour_glass(0);
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


defeventtab _ctAddItem_ItemList_etab _inherit _ctItemList_etab;

// Override _ctItemList_etab.ON_CREATE so we can initialize the form all
// at once in ctl_add.ON_CREATE.
// Note:
// We also have to override the ON_CREATE event so that inherited _ctItemList_etab.ON_CREATE
// does not get called and clear the list (default action) out from under us.
void _ctAddItem_ItemList_etab.on_create()
{
}

/**
 * Populate item information in dialog for selected item.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 */
static void onSelectItem()
{
   // Clear the current item so there is no confusion if there is nothing
   // to select in the item list.
   _str Description = "";
   _str DefaultName = "";
   _str location = "";

   // Note:
   // _ctItemListGetCurrentItem() will fail when the tree is cleared (e.g. each time a new category
   // is chosen). We just blow it off in that case.
   _str templateFilename = "";
   if( _ctItemListGetCurrentItem(templateFilename) ) {

      do {
         ctTemplateDetails_t templateDetails;
         int status = _ctTemplateGetTemplateDetails(templateFilename,templateDetails);
         if( status!=0 ) {
            _str msg = "Error retrieving details for template \"":+templateFilename:+"\". ":+get_message(status);
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            break;
         }

         Description=templateDetails.Description;
         if( Description=="" ) {
            Description=NO_DESCRIPTION;
         }

         DefaultName=templateDetails.DefaultName;
         if( DefaultName=="" ) {
            DefaultName=ENTER_NAME;
         }

         location=_GetDialogInfoHt("defaultLocation");
         if( location=="" ) {
            // Use current working directory
            location=getcwd();
         }

      } while( false );
   }

   _control ctl_description;
   _control ctl_itemname;
   _control ctl_location;
   _control ctl_browse;
   _control ctl_add;
   ctl_description.p_ReadOnly=false;
   ctl_description.p_text=Description;
   ctl_description.p_ReadOnly=true;
   ctl_itemname.p_text=DefaultName;
   ctl_location.p_text=location;
   boolean enabled = _ctItemListGetCurrentItem();
   if( ctl_add.p_enabled!=enabled ) {
      // Assume all controls need p_enabled toggled
      ctl_description.p_enabled=enabled;
      ctl_itemname.p_enabled=enabled;
      ctl_location.p_enabled=enabled;
      ctl_browse.p_enabled=enabled;
      ctl_add.p_enabled=enabled;
   }
}

void _ctAddItem_ItemList_etab.on_change(int reason, int nodeIndex)
{
   if( _ctItemListInOnChange() ) {
      // Recursion not allowed!
      return;
   }
   boolean old_inOnChange = _ctItemListInOnChange(1);
   switch( reason ) {
   case CHANGE_SELECTED:
      onSelectItem();
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
