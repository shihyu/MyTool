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
#require "se/files/FileNameMapper.e"
#import "guiopen.e"
#import "main.e"
#import "listbox.e"
#import "optionsxml.e"
#import "picture.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion Imports

using se.files.FileNameMapper;
using se.files.FilePattern;
using namespace se.files;

// whether to prompt to make a mapping when a user does 
// Select Mode on a file
bool def_prompt_extless_select_mode = true;
// whether the file name mapper has been initialized 
// with our default values
bool def_file_name_map_init_defaults = false;

//FileNameMapper def_file_name_mapper;

static const FILENAME_WILDCARD= '*';
static _str DIRECTORY_WILDCARD() {
   return '**'FILESEP;
}


#region Options Dialog Helper Functions

defeventtab _manage_advanced_file_types_form;

static bool ADVANCED_FILE_TYPES_MODIFIED(...) {
   if (arg()) _ctl_patterns_label.p_user=arg(1);
   return _ctl_patterns_label.p_user;
}

void _manage_advanced_file_types_form_save_settings()
{
   ADVANCED_FILE_TYPES_MODIFIED(false);
}

bool _manage_advanced_file_types_form_is_modified()
{
   return ADVANCED_FILE_TYPES_MODIFIED();
}

bool _manage_advanced_file_types_form_apply()
{
   FilePattern patterns[];
   getListsFromTrees(patterns);

   FileNameMapper.setLists(patterns);

   // if there are any extensionless buffers open, we might need to think on their language mode
   _update_extensionless_buffers();

   return true;
}

_str _manage_advanced_file_types_form_export_settings(_str &file)
{
   error := '';
   
   filename := 'fileNameMappings.xml';
   status := FileNameMapper.exportMap(file :+ filename);

   if (!status) {
      file = filename;
   }

   return error;

}

_str _manage_advanced_file_types_form_import_settings(_str &file)
{
   error := '';

   status := FileNameMapper.importMap(file);

   return error;
}

#endregion Options Dialog Helper Functions

void _ctl_patterns_tree.on_create()
{
   // set up the trees!
   colSlice := _ctl_patterns_tree.p_width intdiv 4;

   _ctl_patterns_tree._TreeSetColButtonInfo(0, colSlice * 3, TREE_BUTTON_PUSHBUTTON, -1, 'Pattern');
   _ctl_patterns_tree._TreeSetColButtonInfo(1, colSlice, TREE_BUTTON_PUSHBUTTON, -1, 'Language');

   FilePattern patterns[];
   FileNameMapper.getLists(patterns);
   loadListsIntoTrees(patterns);

   enableDisableButtons();
}

/**
 * Loads the list of mapped files and file patterns into the trees on the GUI 
 * for editing. 
 * 
 * @param files                  table of files mapped to languages
 * @param patterns               FilePattern structs describing patterns and 
 *                               mapped to language.  In array because order
 *                               matters.
 */
static void loadListsIntoTrees(FilePattern (&patterns)[])
{
   // and now the patterns!
   for (i := 0; i < patterns._length(); i++) {
      FilePattern pattern = patterns[i];
      caption := buildTreeCaption(pattern.AntPattern, _LangId2Modename(pattern.Language));
      _ctl_patterns_tree._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, pattern.Type);
   }
}

/**
 * Grabs the list of mapped files and file patterns from the GUI to be saved in 
 * our settings. 
 * 
 * @param files                  table of files mapped to languages
 * @param patterns               FilePatterns describing patterns and mapped to 
 *                               language.  In array because order matters.
 */
static void getListsFromTrees(FilePattern (&patterns)[])
{
   index:=_ctl_patterns_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      FilePattern pattern;
      pattern.Regex = '';
      pattern.AllFiles = false;
      getTreeLineData(_ctl_patterns_tree, index, pattern.Type, pattern.AntPattern, auto language);
      pattern.Language = _Modename2LangId(language);

      patterns[patterns._length()] = pattern;

      index = _ctl_patterns_tree._TreeGetNextSiblingIndex(index);
   }
}

void _manage_advanced_file_types_form.on_resize()
{
   width := _dx2lx(p_active_form.p_xyscale_mode, p_active_form.p_client_width);
   height := _dy2ly(p_active_form.p_xyscale_mode, p_active_form.p_client_height);

   // determine padding
   padding := _ctl_patterns_label.p_x;

   widthDiff := width - (_ctl_edit_pattern_btn.p_x_extent + padding);
   heightDiff := height - (_ctl_patterns_tree.p_y_extent + padding);

   if (widthDiff) {
      // move the pattern tree buttons over
      _ctl_edit_pattern_btn.p_x += widthDiff;
      _ctl_add_name_pattern_btn.p_x += widthDiff;
      _ctl_add_path_with_name_pattern_btn.p_x += widthDiff;
      _ctl_add_path_pattern_btn.p_x += widthDiff;
      _ctl_add_pattern_btn.p_x += widthDiff;
      _ctl_delete_pattern_btn.p_x += widthDiff;
      _ctl_move_up_pattern_btn.p_x += widthDiff;
      _ctl_move_down_pattern_btn.p_x += widthDiff;

      // widen the trees
      _ctl_patterns_tree.p_width += widthDiff;

      resizeTreeColumns();
   }
   _ctl_patterns_tree.p_height += heightDiff;
}

void _ctl_patterns_tree.on_change(int reason)
{
   if (reason == CHANGE_SELECTED) {
      enableDisableButtons();
   }
}

/**
 * Enables and disables the buttons used to modify the trees.  Different buttons 
 * are available depending on which item in the tree is selected. 
 * 
 * @param type             
 */
static void enableDisableButtons()
{
   int selected[];
   _ctl_patterns_tree._TreeGetSelectionIndices(selected);
   numSelected := selected._length();

   if (numSelected == 0) {
      _ctl_edit_pattern_btn.p_enabled = _ctl_delete_pattern_btn.p_enabled = 
         _ctl_move_up_pattern_btn.p_enabled = _ctl_move_down_pattern_btn.p_enabled = false;
   } else if (numSelected == 1) {
      selIndex := selected[0];
      _ctl_edit_pattern_btn.p_enabled = _ctl_delete_pattern_btn.p_enabled = true;

      prev := _ctl_patterns_tree._TreeGetPrevSiblingIndex(selIndex);
      next := _ctl_patterns_tree._TreeGetNextSiblingIndex(selIndex);
   
      _ctl_move_up_pattern_btn.p_enabled = (prev >= 0);
      _ctl_move_down_pattern_btn.p_enabled = (next >= 0);
   } else {
      _ctl_edit_pattern_btn.p_enabled = _ctl_move_up_pattern_btn.p_enabled = _ctl_move_down_pattern_btn.p_enabled = false;
      _ctl_delete_pattern_btn.p_enabled = true;
   }
}

/**
 * Resizes the columns in the trees after a resize of the trees themselves.
 */
static void resizeTreeColumns()
{
   treeWidth := _ctl_patterns_tree.p_width;

   colSlice := _ctl_patterns_tree.p_width intdiv 4;

   _ctl_patterns_tree._TreeSetColButtonInfo(0, colSlice * 3);
   _ctl_patterns_tree._TreeSetColButtonInfo(1, colSlice);
}

/**
 * Retrieves the data about a file type mapping.
 * 
 * @param treeWid                tree we are pulling data from
 * @param index                  index of line we want data from
 * @param type                   the type of mapping (see 
 *                               AdvancedFileTypeMapType)
 * @param fileOrPattern          the file or pattern info
 * @param language               language we are mapping to (mode name)
 */
static void getTreeLineData(int treeWid, int index, int &type, _str &fileOrPattern, _str& language)
{
   // the type is stored in the user info
   type = treeWid._TreeGetUserInfo(index);

   // get the caption, then parse out what is inside
   caption := treeWid._TreeGetCaption(index);
   parseTreeCaption(caption, fileOrPattern, language);
}

/**
 * Parse mapping information from a caption pulled from one of the trees on the 
 * GUI. 
 * 
 * @param caption                caption of line in tree
 * @param fileOrPattern          file or pattern info
 * @param language               language we are mapping to (mode name)
 */
static void parseTreeCaption(_str caption, _str &fileOrPattern, _str &language)
{
   // this is pretty simple, really
   fileOrPattern = language = '';
   parse caption with fileOrPattern \t language;
}

/**
 * Builds a caption for a line in the tree.
 * 
 * @param fileOrPattern          file or pattern info
 * @param language               language we are mapping to (mode name)
 * 
 * @return                       the tree caption
 */
static _str buildTreeCaption(_str fileOrPattern, _str language)
{
   // this is barely worth a function
   caption := fileOrPattern \t language;
   return caption;
}

/**
 * Translates a filename to an ant pattern specifying any file in any directory 
 * with that file name. 
 * 
 * @param filename               filename to translate to an ant pattern.
 * 
 * @return                       ant pattern representing any file in any 
 *                               directory with that file name.
 */
static _str filenameToAntPattern(_str filename)
{
   // we just add the directory wildcard to the beginning
   antPattern := DIRECTORY_WILDCARD() :+ filename;
   return antPattern;
}

/**
 * Translates a path to an ant pattern specifying any file under that directory. 
 * Can specify whether we want to match recursively or not. 
 * 
 * @param path                   path to translate
 * @param recursive              whether we want to match recursively - true if 
 *                               we want to match any file under this path,
 *                               false if we only want to match things directly
 *                               in this directory.
 * 
 * @return                       ant pattern representing path
 */
static _str pathToAntPattern(_str path, bool recursive)
{
   antPattern := path;
   if (recursive) {
      // recursive, so we want the directory wildcard, followed by the file wildcard
      antPattern :+= DIRECTORY_WILDCARD() :+ FILENAME_WILDCARD;
   } else {
      // not recursive, so just add the file wildcard
      antPattern :+= FILENAME_WILDCARD;
   }

   return antPattern;
}

/**
 * Translates an ant pattern to a simple filename.  The pattern must be a 
 * filename match - it must match any file in any directory with a specific 
 * name. 
 * 
 * @param antPattern             ant pattern we wish to translate
 * 
 * @return                       the filename we pulled from the ant pattern, 
 *                               emtpy string if we couldn't figure it out
 */
static _str antPatternToFilename(_str antPattern)
{
   filename := '';
   wildcardLength := length(DIRECTORY_WILDCARD());

   // do a little checking to make sure we have the right thing going on here
   if (substr(antPattern, 1, wildcardLength) == DIRECTORY_WILDCARD()) {
      filename = substr(antPattern, wildcardLength + 1);
   }

   return filename;
}

/**
 * Translates an ant pattern to a directory path.  The pattern must be a path 
 * match - it must match any file under the given directory.  The match may be 
 * recursive. 
 * 
 * @param antPattern             ant pattern we wish to translate
 * @param recursive              whether our path is recursive
 * 
 * @return                       the path we extracted, empty string if we 
 *                               couldn't figure it out
 */
static _str antPatternToPath(_str antPattern, bool &recursive)
{
   path := '';
   recursive = false;

   if (antPattern == '') return path;

   // it better end with a filename wild card
   if (_last_char(antPattern) == FILENAME_WILDCARD) {
      // get rid of that last wildcard
      path = substr(antPattern, 1, length(antPattern) - 1);

      // now check for a directory wildcard - that indicates recursion!
      recursive = endsWith(path, DIRECTORY_WILDCARD());
      if (recursive) {
         path = substr(path, 1, length(path) - length(DIRECTORY_WILDCARD()));
      } 
   }

   return path;
}

/**
 * Handles the possible addition/edit of a tree item.  Determines if the item 
 * conflicts or restates with an existing item.  In case of conflicts, asks the 
 * user to edit the entry or overwrite the existing one. 
 * 
 * @param treeWid                   window id of tree we are working with
 * @param caption                   caption of tree item
 * @param type                      type of mapping (see 
 *                                  AdvancedFileTypeMapType)
 * @param index                     index of tree item.  If the item is new, 
 *                                  then the index is -1.  However, if we are
 *                                  editting an existing item, send the real
 *                                  index here.
 * @param silent                    when set to true, we do not prompt the user 
 *                                  in case of conflict.  We just overwrite the
 *                                  existing line with our new data.
 * 
 * @return                          0 if we added the tree item, ID_CANCEL if 
 *                                  nothing changed.
 */
static int maybeAddToTree(int treeWid, _str caption, int type, int index = -1, bool silent = false)
{
   // get the info out - we don't really care what kind it is
   parseTreeCaption(caption, auto treeInfo, auto language);

   // search for this item in the tree
   matchIndex := treeWid._TreeSearch(TREE_ROOT_INDEX, treeInfo\t, 'P');
   while (matchIndex > 0 && matchIndex != index) {

      // there already is a setting with this pattern/file
      getTreeLineData(treeWid, matchIndex, auto origType, auto origInfo, auto origLanguage);
      if (language != origLanguage) {

         result := IDYES;

         if (!silent) {
            // select the matched line to draw attention to it
            treeWid._TreeSelectLine(matchIndex, true);

            // the language is not the same, so see what user wants to do about that
            result = _message_box('There is already a setting with the pattern "' :+ treeInfo :+ '" mapped to 'origLanguage :+
                                   '.  Would you like to overwrite this setting?', "Overwrite existing setting?", 
                                   MB_YESNOCANCEL | MB_ICONQUESTION);
         }

         if (result == IDNO) {
            // users wants to try and edit this thing again
            parseTreeCaption(caption, auto info, language);
            editResult := show('-modal -xy _edit_file_type_map_form', type, info, language);
            if (editResult == IDOK && _param1._typename() == '_str') {
               // set this to our caption, and do it all over again
               caption = _param1;
               parse caption with treeInfo \t language;
               matchIndex = treeWid._TreeSearch(TREE_ROOT_INDEX, treeInfo\t, 'P');
            } else return IDCANCEL;
         } else if (result == IDCANCEL) {
            // user gave up, too bad
            return IDCANCEL;
         } else {
            // user wants to overwrite, so lets change the existing line to the new language mapping
            treeWid._TreeSetCaption(matchIndex, caption);
            treeWid._TreeSetUserInfo(matchIndex, type);

            // we got here because the user wanted to edit an existing line - since we just overwrote 
            // a completely different line, we need to delete the original one
            if (index > 0) {
               treeWid._TreeDelete(index);
            }

            // select the overwritten line
            treeWid._TreeSelectLine(matchIndex, true);

            return 0;
         }
      } else {
         // since this setting already exists with the exact same language mapping, we just ignore it

         // we got here because the user wanted to edit an existing line - since we just overwrote 
         // a completely different line, we need to delete the original one
         if (index > 0) {
            treeWid._TreeDelete(index);
         }

         // select that line, though
         treeWid._TreeSelectLine(matchIndex, true);

         return IDCANCEL;
      }
   }

   // hey we got through!  just set/add it then
   if (index > 0) {
      // we have an index where we want it - this was an existing setting that was editted
      treeWid._TreeSetCaption(index, caption);
      treeWid._TreeSetUserInfo(index, type);
   } else {
      index = treeWid._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, type);
   }

   // select the line we were playing with
   treeWid._TreeSelectLine(index, true);

   return 0;
}

void _ctl_edit_pattern_btn.lbutton_up()
{
   editExtensionlessFileSetting(AFTMT_PATTERN);
}

void _ctl_add_name_pattern_btn.lbutton_up()
{
   addNewExtensionlessFileSetting(AFTMT_FILENAME_PATTERN);
}

void _ctl_add_path_with_name_pattern_btn.lbutton_up()
{
   addNewExtensionlessFileSetting(AFTMT_FILE);
}

void _ctl_add_path_pattern_btn.lbutton_up()
{
   addNewExtensionlessFileSetting(AFTMT_PATH_PATTERN);
}

void _ctl_add_pattern_btn.lbutton_up()
{
   addNewExtensionlessFileSetting(AFTMT_PATTERN);
}

void _ctl_delete_pattern_btn.lbutton_up()
{
   deleteExtensionlessFileSetting(AFTMT_PATTERN);
}

void _ctl_move_up_pattern_btn.lbutton_up()
{
   moveUpExtensionlessFileSetting(AFTMT_PATTERN);
}

void _ctl_move_down_pattern_btn.lbutton_up()
{
   moveDownExtensionlessFileSetting(AFTMT_PATTERN);
}

/**
 * Retrieves the window id of the tree containing the type of mapping (see 
 * AdvancedFileTypeMapType for types). 
 * 
 * @param type                type of mapping (one of AdvancedFileTypeMapType)
 * 
 * @return                    window id of tree containing that type
 */
static int getTreeWidFromType(int type)
{
   return _ctl_patterns_tree;
}

static void editExtensionlessFileSetting(int type)
{
   // figure out which tree we want
   treeWid := getTreeWidFromType(type);

   // we want to check out the currently selected node - we only allow editing in single select mode
   int selected[];
   treeWid._TreeGetSelectionIndices(selected);
   index := selected[0];

   // parse out the data to be edited
   getTreeLineData(treeWid, index, type, auto info, auto language);

   // show the edit form
   result := show('-modal -xy _edit_file_type_map_form', type, info, language);
   if (result == IDOK && _param1._typename() == '_str') {
      newCaption := _param1;
      if (maybeAddToTree(treeWid, newCaption, type, index) == 0) {
         // ret value = 0 means we modified the tree
         ADVANCED_FILE_TYPES_MODIFIED(true);
         enableDisableButtons();
      }
   }
}

static void addNewExtensionlessFileSetting(int type)
{
   // show the edit form - 
   result := show('-modal -xy _edit_file_type_map_form', type);

   if (result == IDOK && _param1 != null) {

      type=AFTMT_PATTERN;
      // figure out which tree we want
      treeWid := getTreeWidFromType(type);

      // we may have an array since we allow multi-select
      if (_param1._typename() == '[]') {
         _str newCaptions[] = _param1;
         // add each one
         for (i := 0; i < newCaptions._length(); i++) {
            if (maybeAddToTree(treeWid, newCaptions[i], type) == 0) {
               // ret value = 0 means we modified the tree
               ADVANCED_FILE_TYPES_MODIFIED(true);
            }
         }
      } else {
         // just one this time
         _str newCaption = _param1;
         if (maybeAddToTree(treeWid, newCaption, type) == 0) {
            // ret value = 0 means we modified the tree
            ADVANCED_FILE_TYPES_MODIFIED(true);
         }
      }

      enableDisableButtons();
   }
}

static void deleteExtensionlessFileSetting(int type)
{
   // figure out which tree we want
   treeWid := getTreeWidFromType(type);

   // get a whole list of selected stuff
   int selected[];
   treeWid._TreeGetSelectionIndices(selected);

   if (selected._length() == 0) return;

   // figure out what to select after we get rid of stuff
   newSelection := -1;
   if (selected._length() == 1) {
      newSelection = treeWid._TreeGetNextSiblingIndex(selected[0]);
      if (newSelection < 0) {
         newSelection = treeWid._TreeGetPrevSiblingIndex(selected[0]);
      }
   }

   for (i := 0; i < selected._length(); i++) {
      // get the index and rip it out
      treeWid._TreeDelete(selected[i]);
   }

   // if we haven't set up something to select, just pick the top thing
   if (newSelection < 0) {
      newSelection = treeWid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   }

   if (newSelection > 0) {
      treeWid._TreeSelectLine(newSelection);
   } 

   ADVANCED_FILE_TYPES_MODIFIED(true);
   enableDisableButtons();
}

static void moveUpExtensionlessFileSetting(int type)
{
   // figure out which tree we want
   treeWid := getTreeWidFromType(type);

   // we want to check out the currently selected node - we only allow motion in single select mode
   int selected[];
   treeWid._TreeGetSelectionIndices(selected);
   index := selected[0];
   treeWid._TreeMoveUp(index);

   ADVANCED_FILE_TYPES_MODIFIED(true);
   enableDisableButtons();
}

static void moveDownExtensionlessFileSetting(int type)
{
   // figure out which tree we want
   treeWid := getTreeWidFromType(type);

   // we want to check out the currently selected node - we only allow motion in single select mode
   int selected[];
   treeWid._TreeGetSelectionIndices(selected);
   index := selected[0];
   treeWid._TreeMoveDown(index);

   ADVANCED_FILE_TYPES_MODIFIED(true);
   enableDisableButtons();
}

static void _update_extensionless_buffers()
{
   _safe_hidden_window();

   view_id := 0;
   save_view(view_id);

   // go through all our open buffers
   int first_buf_id=p_buf_id;
   for (;;) {

      // we only want the buffers that are extensionless
      if (_get_extension(p_buf_name) == '') {

         // check the _Filename2LangId, now that we have new maps in place
         langId := _Filename2LangId(p_buf_name, F2LI_NO_CHECK_OPEN_BUFFERS | F2LI_NO_CHECK_PERFILE_DATA);

         // is it different?  then set it!
         if (langId != p_LangId) {
            _SetEditorLanguage(langId);
         }
      }

      // next
      _next_buffer('HN');
      if ( p_buf_id==first_buf_id ) {
         break;
      }
   }
   activate_window(view_id);
}

defeventtab _edit_file_type_map_form;

static int CURRENT_TYPE(...) {
   if (arg()) _ctl_ok.p_user=arg(1);
   return _ctl_ok.p_user;
}

void _ctl_ok.on_create(int type, _str fileOrPattern = '', _str language = '')
{
   CURRENT_TYPE(type);

   _edit_file_type_map_form_initial_alignment();

   // this must be a new one
   if (fileOrPattern == '') {
      p_active_form.p_caption = 'Add new';
   } else {
      p_active_form.p_caption = 'Edit';
   }

   // may have to move some things around
   shift := 0;
   if (CURRENT_TYPE() != AFTMT_PATH_PATTERN) {
      _ctl_recursive_check.p_visible = false;
      shift += (_ctl_pattern_frame.p_y - _ctl_recursive_check.p_y);
   }

   if (CURRENT_TYPE() != AFTMT_PATTERN) {
      _ctl_pattern_frame.p_visible = false;
      shift += (_ctl_language_combo.p_y - _ctl_pattern_frame.p_y);
   }

   switch (CURRENT_TYPE()) {
   case AFTMT_FILE:
      _ctl_text_box.p_text = fileOrPattern;
      _ctl_text_box.p_completion = MULTI_FILE_ARG;
      break;
   case AFTMT_PATTERN:
      _ctl_browse_btn.p_visible = false;
      _ctl_text_box.p_width = _ctl_language_combo.p_width;
      _ctl_pattern_frame.p_y -= shift;

      _ctl_label.p_caption = 'Pattern:';

      loadExampleTree();

      _ctl_text_box.p_text = fileOrPattern;
      break;
   case AFTMT_FILENAME_PATTERN:
      _ctl_text_box.p_text = antPatternToFilename(fileOrPattern);
      break;
   case AFTMT_PATH_PATTERN:
      _ctl_label.p_caption = 'Path:';

      _ctl_text_box.p_text = antPatternToPath(fileOrPattern, auto recursive);
      _ctl_recursive_check.p_value = (int)recursive;

      _ctl_text_box.p_completion = DIR_ARG;
      break;
   }

   label := _ctl_label.p_caption;
   p_active_form.p_caption :+= ' 'lowcase(substr(label, 1, length(label) - 1));

   // move stuff up now
   _ctl_language_label.p_y -= shift;
   _ctl_language_combo.p_y -= shift;

   _ctl_ok.p_y -= shift;
   _ctl_cancel.p_y -= shift;
   _ctl_help.p_y -= shift;

   p_active_form.p_height -= shift;

   // load the combo up with the mode names
   _ctl_language_combo._lbclear();
   _ctl_language_combo.get_all_mode_names();
   _ctl_language_combo._lbsort();
   _ctl_language_combo._lbtop();
   _ctl_language_combo.p_text = _ctl_language_combo._lbget_text();

   if (language != '') {
      _ctl_language_combo._lbfind_and_select_item(language, '', true);
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _edit_file_type_map_form_initial_alignment()
{
   rightAlign := _ctl_pattern_frame.p_x_extent;
   sizeBrowseButtonToTextBox(_ctl_text_box.p_window_id, _ctl_browse_btn.p_window_id, 0, rightAlign);
}

static void loadExampleTree()
{
   colSlice := _ctl_example_tree.p_width intdiv 3;

   _ctl_example_tree._TreeSetColButtonInfo(0, colSlice, TREE_BUTTON_PUSHBUTTON, -1, 'Pattern');
   _ctl_example_tree._TreeSetColButtonInfo(1, colSlice * 2, TREE_BUTTON_PUSHBUTTON, -1, 'Matches');

   _ctl_example_tree._TreeAddItem(TREE_ROOT_INDEX, '**'FILESEP'foo'FILESEP'**'FILESEP'*.'\t'files with no extension under a directory named "foo"', TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   _ctl_example_tree._TreeAddItem(TREE_ROOT_INDEX, '**'FILESEP'foo'FILESEP'*'\t'files in a directory named "foo"', TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   _ctl_example_tree._TreeAddItem(TREE_ROOT_INDEX, '**'FILESEP'foo'FILESEP'**'\t'files or directories named "foo"', TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   _ctl_example_tree._TreeAddItem(TREE_ROOT_INDEX, '**'FILESEP'*foo'FILESEP'**'\t'files or directories ending with "foo"', TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   _ctl_example_tree._TreeAddItem(TREE_ROOT_INDEX, '**'FILESEP'foo'FILESEP'**'FILESEP'*'\t'files under a directory named "foo"', TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   _ctl_example_tree._TreeAddItem(TREE_ROOT_INDEX, '**'FILESEP'foo'FILESEP'**'FILESEP'bar'\t'files named "bar" under a directory named "foo"', TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
}

void _ctl_ok.lbutton_up()
{
   if (_ctl_text_box.p_text == '') {
      label := lowcase(_ctl_label.p_caption);
      label = substr(label, 1, length(label) - 1);
      _message_box('Please enter a value for the 'label'.');
      return;
   }

   if (_ctl_language_combo.p_text == '') {
      _message_box('Please select a language.');
      return;
   }

   text := _ctl_text_box.p_text;
   switch (CURRENT_TYPE()) {
   case AFTMT_FILE:
   case AFTMT_FILENAME_PATTERN:
      // we might have several files in this list, separate them
      // if we start off with a double quote, then we know that we have multiple filenames here
      if (substr(text, 1, 1) == '"') {

         _str newCaptions[];
         for ( ;; ) {
            fileOrPattern := parse_file(text, false);
            if (fileOrPattern == '') break;
   
            if (CURRENT_TYPE() == AFTMT_FILENAME_PATTERN) {
               fileOrPattern = filenameToAntPattern(fileOrPattern);
            }

            newCaption := buildTreeCaption(fileOrPattern, _ctl_language_combo.p_text);
            newCaptions[newCaptions._length()] = newCaption;
         }
         _param1 = newCaptions;
      } else {
         if (CURRENT_TYPE() == AFTMT_FILENAME_PATTERN) {
            text = filenameToAntPattern(text);
         }
         _param1 = buildTreeCaption(text, _ctl_language_combo.p_text);
      }
      break;
   case AFTMT_PATH_PATTERN:
      text = strip(text, 'B', '"');
      _maybe_append_filesep(text);

      antPattern := pathToAntPattern(text, (_ctl_recursive_check.p_value != 0));
      _param1 = buildTreeCaption(antPattern, _ctl_language_combo.p_text);
      break;
   case AFTMT_PATTERN:
      _param1 = buildTreeCaption(text, _ctl_language_combo.p_text);
      break;
   }

   p_active_form._delete_window(IDOK);
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(IDCANCEL);
}

void _ctl_browse_btn.lbutton_up()
{
   curText := _ctl_text_box.p_text;
   newText := '';

   switch (CURRENT_TYPE()) {
   case AFTMT_FILE:
   case AFTMT_FILENAME_PATTERN:
      // do we have a current value? - use that as the initial filename
      curFile := '';
      curPath := '';
      if (curText != '') {
         // split into filename and path
         curPath = _strip_filename(curText, 'N');
         curFile = _strip_filename(curText, 'P');
      }
   
      // prompt for stuff
      newText = _OpenDialog('-new -mdi -modal',     // show arguments
                            'Map file',                                    // title
                            '',                                            // initial wildcards
                            '',                                            // file filters
                            OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT,        // flags
                            '',                                            // default extension
                            curFile,                                       // initial filename
                            curPath                                        // initial directory
                            );
   
      if (newText != '') {
         // we only want the file name
         if (CURRENT_TYPE() == AFTMT_FILENAME_PATTERN) {
            // we may be dealing with several filenames at this point, which requires a bit of processing
            
            filenamesOnly := '';
            numFiles := 0;
            for ( ;; ) {
               filename := parse_file(newText, false);
               if (filename == '') break;
               numFiles++;

               filename = _strip_filename(filename, 'P');
               filenamesOnly :+= '"'filename'" ';
            }

            filenamesOnly = strip(filenamesOnly);

            // if we only have one file, then we don't need the quotes
            if (numFiles == 1) {
               filenamesOnly = strip(filenamesOnly, 'B', '"');
            }

            newText = _file_case(filenamesOnly);
         } else {
            // only one file?  strip the quotes
            tempNewText := newText;
            if (parse_file(tempNewText) == newText) {
               newText = strip(newText, 'B', '"');
            }
         }
      }
      break;
   case AFTMT_PATH_PATTERN:
      curText = _replace_envvars(curText);

      newText = show('-modal _cd_form', 'Map files in directory',
                   true,               // expand_alias_invisible,
                   true,               // process_chdir_invisible,
                   true,               // save_settings_invisible,
                   false,              // ShowRecursive,
                   '',                 // find_file,
                   curText,            // find_path,
                   false,              // path_must_exist,
                   true,               // allow_create_directory,
                   false);             // change_directory

      newText = strip(newText, 'B', '"');

      break;
   }

   if (newText != '') {
      _ctl_text_box.p_text = _file_case(newText);
   }
}

defeventtab _map_files_like_this_form;

static _str MAP_FILE(...) {
   if (arg()) _ctl_ok.p_user=arg(1);
   return _ctl_ok.p_user;
}
static _str MAP_LANGID(...) {
   if (arg()) _ctl_options.p_user=arg(1);
   return _ctl_options.p_user;
}

void _ctl_ok.on_create(_str file, _str langId)
{
   MAP_FILE(file);
   MAP_LANGID(langId);

   language := _LangId2Modename(langId);
   filename := _strip_filename(file, 'P');
   dir := _strip_filename(file, 'N');

   _ctl_info_label.p_caption = 'You can map all files like this to a language, so that the correct language will be automatically assigned to a file whenever you open it.';

   _ctl_rb_map_file.p_caption = 'Just map this file to 'language'.';
   _ctl_rb_map_filename.p_caption = 'Map all files named "'filename'" to 'language'.';

   // figure out how much width we have to spare for the directory
   label := 'Map all extensionless files in %s to 'language'.';
   leftoverWidth := _ctl_rb_map_dir.p_width - _text_width(label);
   dir = _ctl_rb_map_dir._ShrinkFilename(dir, leftoverWidth);
   _ctl_rb_map_dir.p_caption = nls(label, dir);

   _ctl_do_not_ask.p_value = (int)(!def_prompt_extless_select_mode);
}

void _ctl_ok.lbutton_up()
{
   if (_ctl_rb_map_file.p_value) {
      // map this exact file to a language
      FileNameMapper.addFileMap(MAP_FILE(), MAP_LANGID());
   } else if (_ctl_rb_map_filename.p_value) {
      FilePattern pattern;
      pattern.Language = MAP_LANGID();
      pattern.Type = AFTMT_FILENAME_PATTERN;
      filename := _strip_filename(MAP_FILE(), 'P');
      pattern.AntPattern = filenameToAntPattern(filename);
      pattern.AllFiles = false;

      FileNameMapper.addPatternMap(pattern);
      _update_extensionless_buffers();
   } else if (_ctl_rb_map_dir.p_value) {
      FilePattern pattern;
      pattern.Language = MAP_LANGID();
      pattern.Type = AFTMT_PATH_PATTERN;
      dir := _strip_filename(MAP_FILE(), 'N');
      pattern.AntPattern = pathToAntPattern(dir, false);
      pattern.AllFiles = false;

      FileNameMapper.addPatternMap(pattern);
      _update_extensionless_buffers();
   }

   def_prompt_extless_select_mode = (_ctl_do_not_ask.p_value == 0);
   _config_modify_flags(CFGMODIFY_DEFVAR);

   p_active_form._delete_window();
}

void _ctl_options.lbutton_up()
{
   p_active_form._delete_window();

   config('_manage_advanced_file_types_form', 'D');
}

