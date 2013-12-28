////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47587 $
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
#include "project.sh"
#include "treeview.sh"
#import "alias.e"
#import "dir.e"
#import "dirlist.e"
#import "dirtree.e"
#import "drvlist.e"
#import "frmopen.e"
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "mprompt.e"
#import "picture.e"
#import "projutil.e"
#import "recmacro.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbopen.e"
#endregion



/**
 * Changes the current directory.  The <b>Change Directory dialog box</b> is 
 * displayed to prompt you for the directory to change to.  This command 
 * supports directory aliases and may change the current directory in the 
 * build window.
 * 
 * @return Returns 0 if successful.
 * 
 * @see cd
 * @see cdd
 * @see alias_cd
 *
 * @categories File_Functions
 * 
 */
_command gui_cd() name_info(FILE_ARG " "MORE_ARG','VSARG2_EDITORCTL)
{
   _macro_delete_line();
#if __UNIX__
   _str reinit='-hideondel';
#endif
   typeless result=show('_cd_form -modal -reinit -xy');
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _macro('m',_macro('s'));
   _macro_call('cd',result);
   typeless status=cd(result);
   if (status) {
      _message_box(nls("Unable to change directory to '%s'\n",result):+
                   get_message(status));
   }
   return(status);
}

#if __MACOSX__
_str macChooseDirDialog(_str dlgTitle, _str initialDirectory);
#endif

#define DIR_MUST_EXIST_INDEX 0

/**
 * Display a modal dialog for choosing a directory.
 * <p>
 * On Windows, this function will display the Windows 
 * "Browse for Folder" directory chooser form, unless
 * <code>file_file</code> is specified, or the <code>flags</code> 
 * are not <code>CDN_PATH_MUST_EXIST</code>.  Any other options
 * specified require it to use _cd_form() to get the additional
 * functionality.
 * 
 * 
 * @param title         title to display dialog using (default "Choose Directory")
 *                      You can also use "" to get the default title.
 * @param find_path     path to initialize dialog to
 * @param find_file     name of specific file to find
 * @param flags         dialog options 
 *                      <ul> 
 *                      <li>CDN_SHOW_EXPAND_ALIAS  -- show "Expand Alias" checkbox
 *                      <li>CDN_SHOW_PROCESS_CHDIR -- show "Process chdir" checkbox
 *                      <li>CDN_SHOW_SAVE_SETTINGS -- show "Save Settings" button
 *                      <li>CDN_SHOW_RECURSIVE     -- show "Recursive" checkbox
 *                      <li>CDN_PATH_MUST_EXIST    -- Selected path must exist
 *                      <li>CDN_ALLOW_CREATE_DIR   -- Allow them to create a new directory
 *                      <li>CDN_CHANGE_DIRECTORY   -- Change dir to 'find_path' on open
 *                      <li>CDN_NO_SYS_DIR_CHOOSER -- Force us to use _cd_form
 *                      </ul>
 * 
 * @return Returns the selected directory.  Return '' on cancel or error. 
 *         <p> 
 *         If the "Process chdir", "Expand alias", or "Recursive" check boxes
 *         are displayed, the selected options are prepended to the 
 *         returned path as follows and the path is quoted if it contains spaces:
 *         <ul>
 *         <li>+p -- "Process chdir" was checked
 *         <li>-p -- "Process chdir" was not checked
 *         <li>+a -- "Expand alias" was checked
 *         <li>-a -- "Expand alias" was not checked
 *         <li>+r -- "Recursive" was checked.
 *         </ul 
 *  
 * @see _OpenDialog 
 * @see def_cd 
 *  
 * @categories Forms
 */
_str _ChooseDirDialog(_str title="Choose Directory",
                      _str find_path="", _str find_file="",
                      int flags=CDN_PATH_MUST_EXIST)
{
   // negative options
   boolean expand_alias_invisible   = (flags & CDN_SHOW_EXPAND_ALIAS)?  false:true;
   boolean process_chdir_invisible  = (flags & CDN_SHOW_PROCESS_CHDIR)? false:true;
   boolean save_settings_invisible  = (flags & CDN_SHOW_SAVE_SETTINGS)? false:true;
   // positive options
   boolean ShowRecursive            = (flags & CDN_SHOW_RECURSIVE)?     true:false;
   boolean path_must_exist          = (flags & CDN_PATH_MUST_EXIST)?    true:false;
   boolean allow_create_directory   = (flags & CDN_ALLOW_CREATE_DIR)?   true:false;
   boolean change_directory         = (flags & CDN_CHANGE_DIRECTORY)?   true:false;
   boolean use_slickc_cd_form       = (flags & CDN_NO_SYS_DIR_CHOOSER)? true:false; 
   
#if __PCDOS__
   if (!(def_cd & CDFLAG_NO_SYS_DIR_CHOOSER) && find_file=="" && !use_slickc_cd_form) {
      bifFlags := (allow_create_directory? 1:0) | (path_must_exist? 2:0);
      _str result = _ntBrowseForFolder(find_path,title,bifFlags);
      if (result=='') return result;
      _maybe_append_filesep(result);
      return result;
   }
#endif

#if __MACOSX__
   if (!(def_cd & CDFLAG_NO_SYS_DIR_CHOOSER) && find_file=="") {
      _str result = macChooseDirDialog(title, find_path);
      if (result=='') return result;
      _maybe_append_filesep(result, true);
      return result;
   }
#endif

   // normalize the message to whatever they 
   // have configured in the message file
   if (title=='' || title=="Choose Directory") {
      title = get_message(VSRC_FF_CHOOSE_DIRECTORY);
   }

   _str result = show('-modal _cd_form',
                        title,
                        expand_alias_invisible,
                        process_chdir_invisible,
                        save_settings_invisible,
                        ShowRecursive,
                        find_file, find_path,
                        path_must_exist,
                        allow_create_directory,
                        change_directory);

   // special case, if we are return file name with no options,
   // there is no need to quote the result.
   if (expand_alias_invisible && process_chdir_invisible && save_settings_invisible) {
      result = strip(result, 'B', '"');
      _maybe_append_filesep(result);
   }
   return result;
}

int def_symlinks=1;


defeventtab _edit_paths_form;

#define DELIMITER       _ctl_ok.p_user
#define ISDIR           _ctl_browse.p_user
#define CAPTION         _ctl_cancel.p_user
#define INITIALVALUE    _ctl_up.p_user

void _ctl_ok.on_create(_str caption, _str curValue, _str delimiter, boolean isDir)
{
   _edit_paths_form_initial_alignment();

   // get our current list of paths
   _str paths[];
   split(curValue, delimiter, paths);

   // now add them to our list box in that order
   foreach (auto path in paths) {
      _ctl_path_list._lbadd_item(path);
   }

   p_active_form.p_caption = 'Set 'caption;

   DELIMITER = delimiter;
   ISDIR = isDir;
   CAPTION = caption;
   INITIALVALUE = curValue;
}


/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _edit_paths_form_initial_alignment()
{
   alignUpDownListButtons(_ctl_path_list.p_window_id, p_active_form.p_width - _ctl_path_list.p_x,
                          _ctl_browse.p_window_id, _ctl_up.p_window_id, _ctl_down.p_window_id, _ctl_delete.p_window_id);
}

void _ctl_browse.lbutton_up()
{
   newPath := browseForNewPath(ISDIR, CAPTION, '');

   if (newPath != '') {
      _ctl_path_list._lbbottom();
      _ctl_path_list._lbadd_item(newPath);
      _ctl_path_list._lbselect_line();
   }
}

_str browseForNewPath(boolean isDir, _str caption, _str initialPath)
{
   newPath := '';
   if (isDir) {
      newPath = _ChooseDirDialog('Choose directory for 'caption,           // title of dialog
                                 initialPath,                              // initial path
                                 '',                                       // initial file
                                 CDN_ALLOW_CREATE_DIR                      // allow user to create a new directory
                                 );
   } else {
      // do we have a current value? - use that as the initial path/filename
      curPath := '';
      curFile := initialPath;
      if (curFile != '') {
         // split into filename and path
         curPath = _strip_filename(curFile, 'N');
         curFile = _strip_filename(curFile, 'P');
      }
      
      // prompt for stuff
      newPath = _OpenDialog('-new -mdi -modal',     // show arguments
                            caption,                                       // title
                            '',                                            // initial wildcards
                            '',                                            // file filters
                            OFN_FILEMUSTEXIST,                             // flags
                            '',                                            // default extension
                            curFile,                                       // initial filename
                            curPath                                        // initial directory
                            );
   }

   return newPath;
}


void _ctl_ok.lbutton_up()
{
   paths := '';

   // put our list back together so we can send it back
   _ctl_path_list._lbtop();

   do {
      // get this item and add it to the list
      paths :+= strip(_ctl_path_list._lbget_text()) :+ DELIMITER;
   } while (!_ctl_path_list._lbdown());

   // trim the last delimiter?
   paths = strip(paths, 'T', DELIMITER);

   p_active_form._delete_window(paths);
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(INITIALVALUE);
}

static void move_path_up()
{
   curIndex := _ctl_path_list.p_line;

   if (curIndex > 1) {
      _ctl_path_list._lbup();
      item := _ctl_path_list._lbget_text();
      _ctl_path_list._lbdelete_item();
      _ctl_path_list._lbadd_item(item);
      _ctl_path_list._lbup();
      _ctl_path_list._lbselect_line();
   }
}

static void move_path_down()
{
   curIndex := _ctl_path_list.p_line;

   if (curIndex < _ctl_path_list.p_Noflines) {
      item := _ctl_path_list._lbget_text();
      _ctl_path_list._lbdelete_item();
      _ctl_path_list._lbadd_item(item);
      _ctl_path_list._lbselect_line();
   }
}

static void delete_path()
{
   _ctl_path_list._lbdelete_item();
   _ctl_path_list._lbselect_line();
}

void _ctl_up.lbutton_up()
{
   move_path_up();
}

void _ctl_down.lbutton_up()
{
   move_path_down();
}

void _ctl_delete.lbutton_up()
{
   delete_path();
}

void _edit_path_form.up, 'C-UP'()
{
   move_path_up();
}

void _edit_path_form.down, 'C-DOWN'()
{
   move_path_down();
}

void _edit_path_form.'DEL'()
{
   delete_path();
}

defeventtab _project_add_tree_or_wildcard_form;

#define     ADD_TREE_FORM_DO_NOT_UPDATE_PATH    ctlpath_textbox.p_user
#define     PROJECT_FILENAME                    ctlpath_label.p_user

static _str filespecHash:[];

// _param1 - trees to add (array of paths)
// _param2 - recursive?
// _param3 - follow symlinks?
// _param4 - exclude filespecs (array of filespecs)
// _param5 - add as wildcard
ctlok.on_create(_str title                   = "",
                _str filespec                = "",
                boolean attempt_retrieval    = false,
                boolean use_exclude_filespec = false,
                _str projectFileName         = '',
                boolean show_wildcard_option = false
                      )
{
   PROJECT_FILENAME = projectFileName;
   if( title!='' ) p_active_form.p_caption=title;

   // maybe retrieve previous info
   if (attempt_retrieval) {
      _retrieve_prev_form();
   }

   // attempt to get an initial value for the include filespecs
   if (PROJECT_FILENAME != null && PROJECT_FILENAME != '' && filespecHash._indexin(PROJECT_FILENAME) && filespecHash:[PROJECT_FILENAME] != null && filespecHash:[PROJECT_FILENAME] != '') {
      ctlinclude_filespecs.p_text = filespecHash:[PROJECT_FILENAME];
   } else {
      if (PROJECT_FILENAME != null && PROJECT_FILENAME != '' && filespecHash._indexin(PROJECT_FILENAME) && (filespecHash:[PROJECT_FILENAME] == null || filespecHash:[PROJECT_FILENAME] == '')) {
         filespecHash._deleteel(PROJECT_FILENAME);
      }
      ctlinclude_filespecs.p_text = filespec;
   }

   if (ctlinclude_filespecs.p_text == '') {
      ctlinclude_filespecs.p_text = '*.*';
   }

   // throw some possible filespecs into the include list
   ctlinclude_filespecs._retrieve_list();
   ctlinclude_filespecs.add_filetypes_to_combo();

   ctlrecursive.p_value=1;
#if __UNIX__
   // Use retrieval value
   ctlsymlinks.p_value=def_symlinks;
#else
   ctlsymlinks.p_visible=false;
#endif

   if (!use_exclude_filespec) {
      ctlexclude_label.p_visible = ctlexclude_filespecs.p_visible = false;
      yDiff := (ctlexclude_filespecs.p_y + ctlexclude_filespecs.p_height) - (ctlinclude_filespecs.p_y + ctlinclude_filespecs.p_height);

      ctlwildcard.p_y -= yDiff;
      ctlwildcard_help.p_y -= yDiff;
      ctlok.p_y -= yDiff;
      ctlcancel.p_y = ctlhelp.p_y = ctlok.p_y;
      p_active_form.p_height -= yDiff;
   } else {
      ctlexclude_filespecs._retrieve_list();
      ctlexclude_filespecs.p_text = _retrieve_value("_project_add_tree_or_wildcard_form.ctlexclude_filespecs.p_text");
   }

   if (!show_wildcard_option) {
      ctlwildcard.p_visible = false;
      ctlwildcard_help.p_visible = false;

      yDiff := ctlwildcard.p_y - ctlexclude_filespecs.p_y;
      ctlok.p_y -= yDiff;
      ctlcancel.p_y = ctlhelp.p_y = ctlok.p_y;
      p_active_form.p_height -= yDiff;
   }


   if (attempt_retrieval) {
      // retrieve the last directory
      title = stranslate(p_active_form.p_caption, '_', ' |.', 'R');
      title = "_project_add_tree_or_wildcard_form_"title".ctlpath_textbox";
      ctlpath_textbox._retrieve_value(title);
   }

   if (ctlpath_textbox.p_text != '') {
      ADD_TREE_FORM_DO_NOT_UPDATE_PATH = false;
      ctlpath_textbox.call_event(ctlpath_textbox, ON_CHANGE);
   } else {
      ctlpath_textbox.p_text = ctldir_tree._get_current_path();
      ADD_TREE_FORM_DO_NOT_UPDATE_PATH = false;
   }

}

void add_filetypes_to_combo(_str filetypes = def_file_types)
{
   while (true) {
      line := _parse_line(filetypes, ',');
      if (line == '') break;

      // do a little special handling for slick-c
      if (pos('(*.e;',line)) {
         line=stranslate(line,'(*'_macro_ext';','(*.e;');
      }

      // add the item if it is not already there
      parse line with '('line')';
      if (line != ALLFILES_RE) {
         _lbadd_item_no_dupe(line, _fpos_case, LBADD_BOTTOM);
      }
   }

	_lbtop();
}

void ctlok.lbutton_up()
{
   if (ctlwildcard.p_visible && ctlwildcard.p_value) {
      if (!iswildcard(ctlinclude_filespecs.p_text)) {
         _message_box('There are no wildcard character in this filespec');
         return;
      }
   }

   _param1._makeempty();         // trees to add
   _param2 = 0;                  // recursive?
   _param3 = 0;                  // follow symlinks?
   _param4._makeempty();         // exclude filespecs
   _param5 = 0;                  // add as wildcard

   cwd := ctldir_tree._etBuildSelectedPath();
   error := compile_include_paths(_param1, cwd, ctlinclude_filespecs.p_text);
   if (error != '') {
      _message_box(error, p_active_form.p_caption);
      _str text=ctlinclude_filespecs.p_text;
      ctlinclude_filespecs.set_command(text,1,length(text)+1);
      ctlinclude_filespecs._set_focus();
      return;
   }

   if (ctlinclude_filespecs.p_text != '' && PROJECT_FILENAME != '' && PROJECT_FILENAME != null) {
      filespecHash:[PROJECT_FILENAME] = ctlinclude_filespecs.p_text;
   }

   _param2=ctlrecursive.p_value;
   _param3=ctlsymlinks.p_value;

   if (ctlexclude_filespecs.p_visible && ctlexclude_filespecs.p_text != '') {
      _str list = ctlexclude_filespecs.p_text;
      _str file_exclude;
      while (list != '') {
         parse list with file_exclude ";" list;
         if (file_exclude != '') {
            _param4[_param4._length()]=file_exclude;
         }
      }

		_append_retrieve(ctlexclude_filespecs, ctlexclude_filespecs.p_text);
		_append_retrieve(0, ctlexclude_filespecs.p_text, "_project_add_tree_or_wildcard_form.ctlexclude_filespecs.p_text");
   }

   if (ctlwildcard.p_visible) {
      _param5 = ctlwildcard.p_value;
   }

   _save_form_response();

   // save the directory
   title := stranslate(p_active_form.p_caption, '_', ' |.', 'R');
   title = "_project_add_tree_or_wildcard_form_"title".ctlpath_textbox";
   ctlpath_textbox._append_retrieve(ctlpath_textbox, cwd, title);

   p_active_form._delete_window(0);
}

/**
 * Compiles an array of paths by combining the base directory
 * with a series of semicolon-delimited include specs.
 *
 * @param paths
 * @param baseDir
 * @param includeSpecs
 *
 * @return _str
 */
_str compile_include_paths(_str (&paths)[], _str baseDir, _str includeSpecs)
{
   paths._makeempty();
   for (;;) {
      _str filenames="";
      parse includeSpecs with filenames ';' includeSpecs ;
      if (filenames == '') break;

      while (true) {
         bfilename := parse_file(filenames);
         if (bfilename == '') break;

         _str filename = _absolute2(bfilename, baseDir);

         // Check if this is a directory specification.
         paths[paths._length()]=filename;
         filename = strip(filename, 'B', '"');
         new_path := _strip_filename(filename,'N');
         name_part := _strip_filename(filename,'P');

         // Check if path exists
         if (new_path!=''){
            _str path=new_path;
            if(!isdirectory(new_path)) {
               error := new_path"\n"nls("Path does not exist.")"\n":+
                            nls("Please verify that the correct path was given.");
               return error;
            }
         }
      }
   }

   return '';
}

void _project_add_tree_or_wildcard_form.on_resize()
{
   padding := ctlpath_textbox.p_x;

   xDiff := p_width - (ctlpath_textbox.p_width + 2 * padding);
   yDiff := p_height - (ctlhelp.p_y + ctlhelp.p_height + padding);

   ctlpath_textbox.p_width += xDiff;
   ctldir_tree.p_width = ctlinclude_filespecs.p_width = ctlexclude_filespecs.p_width = ctlpath_textbox.p_width;
   ctlok.p_x += xDiff;
   ctlcancel.p_x += xDiff;
   ctlhelp.p_x += xDiff;

   ctldir_tree.p_height += yDiff;
   ctlrecursive.p_y += yDiff;
   ctlsymlinks.p_y = ctlrecursive.p_y;
   ctlinclude_label.p_y += yDiff;
   ctlinclude_filespecs.p_y += yDiff;
   ctlexclude_label.p_y += yDiff;
   ctlexclude_filespecs.p_y += yDiff;
   ctlwildcard.p_y += yDiff;
   ctlwildcard_help.p_y += yDiff;
   ctlok.p_y += yDiff;
   ctlcancel.p_y = ctlhelp.p_y = ctlok.p_y;
}

void ctlpath_textbox.on_change()
{
   // see if this is a complete path
   text := ctlpath_textbox.p_text;
   text = strip(text, 'B', '"');
   if (file_exists(text) && !ADD_TREE_FORM_DO_NOT_UPDATE_PATH) {
      ADD_TREE_FORM_DO_NOT_UPDATE_PATH = true;

      // set the directory box to that path, too
      mou_hour_glass(1);
      ctldir_tree._select_path(text);
      mou_hour_glass(0);

      ADD_TREE_FORM_DO_NOT_UPDATE_PATH = false;
   }
}

void ctldir_tree.on_change(int reason,int index)
{
   if (reason == CHANGE_SELECTED) {
      // we want single-click to change the current path
      if (!ADD_TREE_FORM_DO_NOT_UPDATE_PATH) {
         ADD_TREE_FORM_DO_NOT_UPDATE_PATH = true;
         ctlpath_textbox.p_text = _etBuildSelectedPath();
         ADD_TREE_FORM_DO_NOT_UPDATE_PATH = false;
      }
   }

   // we do a lot of selecting nodes to get stuff done here, but we
   // don't want to get into any path changing shenanigans
   if (reason == CHANGE_EXPANDED) {
      ADD_TREE_FORM_DO_NOT_UPDATE_PATH = true;
   }

   call_event(reason,index,find_index('_ul2_explorertree',EVENTTAB_TYPE),ON_CHANGE,'E');

   if (reason == CHANGE_EXPANDED) {
      ADD_TREE_FORM_DO_NOT_UPDATE_PATH = false;
   }
}

void ctlrecursive.lbutton_up()
{
   ctlsymlinks.p_enabled=(p_value!=0);
}

_str modify_wildcard_properties(_str filename, WILDCARD_FILE_ATTRIBUTES &f)
{
   // switch to the directory specified
   curDir := getcwd();
   path := _strip_filename(filename, 'EN');
   if (path != '') {
      pwd(path);
   }

   wildcards := _strip_filename(filename, 'P');

   // show the dialog non-modally
   wid := show('-xy _project_add_tree_or_wildcard_form',
               'Add Tree',
               wildcards,
               false,
               true,
               '',
               false);

   // set the excludes
   ctrl := wid._find_control('ctlexclude_filespecs');
   if (ctrl) {
      ctrl.p_text = f.Excludes;
   }

   // set recursive
   ctrl = wid._find_control('ctlrecursive');
   if (ctrl) {
      ctrl.p_value = (int)f.Recurse;
   }

   // disable the dir tree and include items - user cannot change them at this time
   ctrl = wid._find_control('ctlinclude_filespecs');
   if (ctrl) {
      ctrl.p_enabled = false;
   }

   ctrl = wid._find_control('ctldir_tree');
   if (ctrl) {
      ctrl.p_enabled = false;
   }

   ctrl = wid._find_control('ctlpath_textbox');
   if (ctrl) {
      ctrl.p_enabled = false;
   }

   // now wait for the dialog to finish up
   result := _modal_wait(wid);

   if (!result) {
      f.Recurse = _param2;

      excludes := '';
      for (i := 0; i < _param4._length(); ++i) {
         excludes :+= _param4[i]';';
      }
      f.Excludes = strip(excludes, 't', ';');
   }

   // switch back to our previous current dir
   pwd(curDir);

   return result;
}

defeventtab _cd_form;

#define FINDFILE_NAME                  _ctl_dir_label.p_user
#define CD_FORM_DO_NOT_UPDATE_PATH     _ctl_dir.p_user

void _cd_form.on_create()
{
   _OpenTBDisableRefreshCallback(true);
}

void _cd_form.on_destroy()
{
   _OpenTBDisableRefreshCallback(false);
}

_cd_form.on_resize()
{
   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      _set_minimum_size(_ctl_ok.p_width * 4, _ctl_ok.p_height * 13);
   }

   padding := _ctl_dir_label.p_x;

   // figure out how much the size changed
   motion_y := p_height - (padding + _ctl_help.p_y + _ctl_help.p_height);
   motion_x := p_width - (padding + _ctl_help.p_x + _ctl_help.p_width);

   _ctl_dir.p_width      += motion_x;
   _ctl_explorer_tree.p_width += motion_x;
   _ctl_settings_frame.p_width += motion_x;

   _ctl_explorer_tree.p_height += motion_y;

   _ctl_new_dir.p_x            += motion_x;
   _ctl_ok.p_x            += motion_x;
   _ctl_cancel.p_x        += motion_x;
   _ctl_help.p_x          += motion_x;

   _ctl_save_settings.p_x += motion_x;

   _ctl_settings_frame.p_y += motion_y;
   _ctl_ok.p_y += motion_y;
   _ctl_cancel.p_y += motion_y;
   _ctl_help.p_y += motion_y;
}

_ctl_ok.on_create(_str title="",
                  boolean expand_alias_invisible=false,
                  boolean process_chdir_invisible=false,
                  boolean save_settings_invisible=false,
                  boolean ShowRecursive=false,
                  _str find_file="", _str find_path="",
                  boolean path_must_exist=true,
                  boolean allow_create_directory=false,
                  boolean change_directory=true)
{
   _ctl_cd_build_window.p_value = (def_cd & CDFLAG_CHANGE_DIR_IN_BUILD_WINDOW);

   // This fixes bug with saving savetings.  Need p_value to be 1 and not 2
   if (def_cd & CDFLAG_EXPAND_ALIASES_IN_CD_FORM) {
      _ctl_expand_alias.p_value = 1;
   }

   _ctl_dir._retrieve_list();

   // now handle all these things that got passed in 
   if (title != '') {
      p_active_form.p_caption = title;
   }
   if (find_file!='') {
      _ctl_dir_label.p_caption = nls("Enter path for:  %s", find_file);
      _ctl_dir.p_completion = FILE_ARG;
   }

   // show/hide things
   _ctl_expand_alias.p_visible = !expand_alias_invisible;
   _ctl_recursive.p_visible = ShowRecursive;
   _ctl_cd_build_window.p_visible = !process_chdir_invisible;
   _ctl_save_settings.p_visible = !save_settings_invisible;
   _ctl_new_dir.p_visible = allow_create_directory;
   _cd_form_initial_alignment();

   _SetDialogInfo(DIR_MUST_EXIST_INDEX, path_must_exist);
   FINDFILE_NAME = find_file;

   // set the starting path in the combo box - we will update the tree in the on_load
   text := getcwd();
   if (find_path!='') {
      text = find_path;
   } 
   _ctl_dir.set_command(text, 1, length(text) + 1);
   CD_FORM_DO_NOT_UPDATE_PATH = false;
}

/**
 * Shifts controls around after some have been made invisible.
 */
static void _cd_form_initial_alignment()
{
   if (!_ctl_expand_alias.p_visible && !_ctl_cd_build_window.p_visible && 
       !_ctl_recursive.p_visible) {
      _ctl_settings_frame.p_visible = false;

      _ctl_cancel.p_y = _ctl_help.p_y = _ctl_ok.p_y = _ctl_settings_frame.p_y;
   } else {
      shift := 0;
      padding := _ctl_recursive.p_y - (_ctl_expand_alias.p_y + _ctl_expand_alias.p_height);
      if (!_ctl_expand_alias.p_visible) {
         shift += _ctl_expand_alias.p_height + padding;
      } 

      if (!_ctl_recursive.p_visible) {
         shift += _ctl_recursive.p_height + padding;
      } else {
         _ctl_recursive.p_y -= shift;
      }

      if (!_ctl_cd_build_window.p_visible) {
         shift += _ctl_cd_build_window.p_height + padding;
      } else {
         _ctl_cd_build_window.p_y -= shift;
      }

      if (_ctl_save_settings.p_visible) {
         minHeight := _ctl_save_settings.p_height + 2 * _ctl_save_settings.p_y;
         if (_ctl_settings_frame.p_height - shift < minHeight) {
            shift = _ctl_settings_frame.p_height - minHeight;
         }
      }

      _ctl_settings_frame.p_height -= shift;
      _ctl_ok.p_y -= shift;
      _ctl_cancel.p_y = _ctl_help.p_y = _ctl_ok.p_y;
   }

   if (_ctl_new_dir.p_visible) {
      rightAlign := _ctl_explorer_tree.p_x + _ctl_explorer_tree.p_width;
      sizeBrowseButtonToTextBox(_ctl_dir.p_window_id, _ctl_new_dir.p_window_id, 0, rightAlign);
   } else {
      _ctl_dir.p_width = _ctl_explorer_tree.p_width;
   }
}

_cd_form.on_load()
{
   // wait until the on_load to call the on_change event - we have to wait 
   // until after the _ul2_explorer_tree.on_create2 is called (which calls
   // the tree init stuff)
   _ctl_dir.call_event(CHANGE_OTHER, _ctl_dir, ON_CHANGE, 'W');
}

_ctl_save_settings.lbutton_up()
{
   // zero out the value, start from scratch!
   def_cd = 0;

   // add in the checkbox values
   def_cd |= (_ctl_cd_build_window.p_value)? CDFLAG_CHANGE_DIR_IN_BUILD_WINDOW:0;
   def_cd |= (_ctl_expand_alias.p_value)?  CDFLAG_EXPAND_ALIASES_IN_CD_FORM:0;

   // make sure everything gets saved
   _config_modify_flags(CFGMODIFY_DEFVAR);
   save_config();
   _macro('m',_macro('s'));
   _macro_append('_config_modify_flags(CFGMODIFY_DEFVAR);');
   _macro_append('def_cd='def_cd";");
}

_ctl_ok.lbutton_up()
{
   path := _ctl_dir.p_text;
   if (path == '') return '';

   // maybe expand alias?
   if (_ctl_expand_alias.p_visible && _ctl_expand_alias.p_value) {

      // we need to figure out if this alias is acceptable, i.e. not multi-line
      // retrieve the alias with this key
      path = get_alias(path, auto multi_line_info, '', '', true);

      // parse out the good stuff
      typeless multi_line_flag, file_already_loaded, old_view_id, alias_view_id;
      parse multi_line_info with multi_line_flag file_already_loaded old_view_id alias_view_id .;
      if (multi_line_flag) {
         // multi-line!  no good.
         _message_box('Multi-line alias not allowed.');
         p_window_id=_ctl_dir;
         _set_sel(1,length(p_text)+1);_set_focus();
         return 1;
      }
   }

   if (FINDFILE_NAME != '') {
      filename := concat_path_and_file(path, FINDFILE_NAME);
      if (!file_exists(filename)) {
         _message_box(nls("The file '%s' does not exist.", filename));
         p_window_id = _ctl_dir;
         _set_sel(1, length(p_text) + 1);
         _set_focus();
         return('');
      }
   } else if ( _GetDialogInfo(DIR_MUST_EXIST_INDEX) == true &&
               !isdirectory(path)) {
      _message_box(nls("The directory '%s' does not exist.", path));
      p_window_id=_ctl_dir;
      _set_sel(1, length(p_text) + 1);
      _set_focus();
      return('');
   }

   // now, we build our string that we will send to cd
   typeless result='';
   if (_ctl_cd_build_window.p_visible) {
      // change directory in build window?
      result :+= _ctl_cd_build_window.p_value? '+p ' : '-p ';
   }

   // expand the alias?
   if (_ctl_expand_alias.p_visible) {
      result :+= _ctl_expand_alias.p_value ? '+a ' : '-a ';
   }

   // recursive?
   if (_ctl_recursive.p_visible && _ctl_recursive.p_value) {
      result :+= '+r ';
   }

   // finally, add the file name
   result :+= maybe_quote_filename(_ctl_dir.p_text);

   // save this value for the next time
   if (_ctl_dir.p_text != '') {
      _append_retrieve(_ctl_dir, _ctl_dir.p_text);
   }

   // all done!
   p_active_form._delete_window(strip(result));
}

void _ctl_new_dir.lbutton_up()
{
   // get the path that's in the textbox - that will be our base
   _str path = _ctl_dir.p_text;
   _maybe_append_filesep(path);

   // retrieve new directory name
   int result=textBoxDialog('Enter New Directory Name',
                            0,      // flags,
                            0,      // textbox width
                            '',     // help item
                            "OK,Cancel:_cancel\t-html New directory will be created in "path,//Buttons and captions
                            '',     // retrieve name
                            '-e validNewDirectoryName: New Directory Name:');  // prompt

   // guess they changed their mind
   if (result==COMMAND_CANCELLED_RC) return;

   // create new directory
   path = concat_path_and_file(_ctl_dir.p_text, _param1);

   // make sure we're not just creating something that already exists
   if (!isdirectory(path)) {

      // make us a shiny new directory
      result = mkdir(path);

      // sometimes, we fail
      if (result == ACCESS_DENIED_RC) {
         _message_box("Access to create new directory denied.");
      } else if (result == INSUFFICIENT_DISK_SPACE_RC) {
         _message_box("Insufficient disk space to create new directory.");
      } else if (result != 0) {
         _message_box("Error creating new directory.");
      }
   }

   // switch to viewing new directory
   if (isdirectory(path)) {
      _ctl_explorer_tree._set_current_path(path, 0, def_filelist_show_dotfiles);
   }
}

_ctl_explorer_tree.on_change(int reason, int index)
{
   // set the path on single click
   if (reason == CHANGE_SELECTED && !CD_FORM_DO_NOT_UPDATE_PATH) {
      CD_FORM_DO_NOT_UPDATE_PATH = true;

      text := _etBuildSelectedPath();
      if (text != _ctl_dir.p_text) {
         _ctl_dir.set_command(text, 1);
      }
      CD_FORM_DO_NOT_UPDATE_PATH = false;
   }

   // we do a lot of selecting nodes to get stuff done here, but we
   // don't want to get into any path changing shenanigans
   if (reason == CHANGE_EXPANDED) {
      CD_FORM_DO_NOT_UPDATE_PATH = true;
   }

   call_event(reason, index, find_index('_ul2_explorertree', EVENTTAB_TYPE), ON_CHANGE, 'E');

   if (reason == CHANGE_EXPANDED) {
      CD_FORM_DO_NOT_UPDATE_PATH = false;
   }
}

void _ctl_dir.on_change(int reason)
{
   dirname := p_text;
   if (isdirectory(dirname) && !CD_FORM_DO_NOT_UPDATE_PATH) {
      // did we have a trailing filesep?
      had_filesep := (last_char(dirname)==FILESEP);

      // update the directory list
      _get_sel(auto start_pos);
      CD_FORM_DO_NOT_UPDATE_PATH = true;
      _ctl_explorer_tree._select_path(dirname);
      CD_FORM_DO_NOT_UPDATE_PATH = false;

      _set_sel(start_pos);
      if (last_char(p_text)==FILESEP && !had_filesep) {
         p_text = substr(p_text, 1, length(p_text) - 1);
         // Select everything from startpos to the end of the new text,
         // so it is easy for the user to blast it by typing over the
         // selection.
         _set_sel(start_pos, length(p_text) + 1);
      }
   }

   // enable/disable the OK button
   filename := FINDFILE_NAME;
   if (filename != '') {
      _maybe_append_filesep(dirname);
      _ctl_ok.p_enabled = file_exists(dirname :+ filename);
   }
}

int validNewDirectoryName(_str name)
{
   name = strip(name); // first thing done after dialog returns
   name=translate(name,'a',' ');
#if __UNIX__
   name=translate(name,'aaaaa',':<>"''');  // In case we change :f for convenience, need to allow these characters
#endif

   if (!pos('^:f$', name, 1, 'r')) {
      _message_box("Invalid characters in directory name.");
      return(1);
   }

   return 0;
}
