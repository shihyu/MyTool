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
#include "debug.sh"
#include "slick.sh"
#include "toolbar.sh"
#include "dockchannel.sh"
#include "listbox.sh"
#import "listbox.e"
#import "qtoolbar.e"
#import "stdprocs.e"
#import "toolbar.e"
#import "options.e"
#import "sc/controls/customizations/ToolbarControl.e"
#import "se/ui/toolwindow.e"
#import "main.e"
#import "menu.e"
#import "stdcmds.e"
#endregion

_TOOLBAR def_toolbartab[];

// button bar picture size
_str def_toolbar_pic_size="24";
_str g_toolbar_pic_size="24";
int def_toolbar_tab_pic_size=20;
int g_toolbar_tab_pic_size=20;
int def_toolbar_tree_pic_size=14;
int g_toolbar_tree_pic_size=14;
int def_toolbar_pic_depth=32;
int g_toolbar_pic_depth=32;
bool def_toolbar_pic_auto=true;
bool def_toolbar_tree_pic_auto=true;
bool def_toolbar_tab_pic_auto=true;

// Hue, Saturation, and Brightness bias.
// Use this to calibrate button bar and tool window icon loading to 
// your tastes with respect to color saturation and brightness.
//
// This is a triplet of "h s v", wher:
//    h -- is the hue adjustment, the number of degrees to rotate on the 
//         HSV color wheel (ranging between -359 ... 359)
//    s -- saturation adjustment (ranging between -255 ... 255)
//    v -- brightness value adjustment (ranging between -255 ... 255)
//
_str def_toolbar_pic_hsv_bias="";
_str g_toolbar_pic_hsv_bias="";

// button bar toolbar button style
_str def_toolbar_pic_style="";
_str g_toolbar_pic_style="";

// button bar toolbar button theme (for background)
_str g_toolbar_pic_theme = '';

// button bar toolbar spacing
int def_toolbar_pic_hspace = 4;
int def_toolbar_pic_vspace = 0;


/* 
  tbReloadBitmaps 
     theme def_toolbar_pic_size def_toolbar_pic_style def_toolbar_pic_hsv_bias g_toolbar_pic_depth
  tbReloadTreeBitmaps
     theme  def_toolbar_tree_pic_auto def_toolbar_tree_pic_size def_toolbar_pic_hsv_bias  g_toolbar_pic_depth def_toolbar_pic_style?
  tbReloadTabBitmaps
     theme def_toolbar_tab_pic_size  def_toolbar_pic_hsv_bias def_toolbar_tab_pic_size g_toolbar_pic_depth def_toolbar_pic_style?
 
*/

void _before_write_state_toolbar_options() {
   g_toolbar_pic_style=def_toolbar_pic_style;
   g_toolbar_pic_hsv_bias= def_toolbar_pic_hsv_bias;
   g_toolbar_pic_depth=def_toolbar_pic_depth;
   g_toolbar_tree_pic_size= def_toolbar_tree_pic_size;
   g_toolbar_tab_pic_size=def_toolbar_tab_pic_size;
   g_toolbar_pic_size=def_toolbar_pic_size;
}


static const BB_XSPACE= 90;

struct SPECIALCONTROL {

   int object;

   // Width in twips.  Can be zero.
   int width;

   // Height in twips. Can be zero.
   int height;

   _str name;

   _str eventtab_name;

   _str eventtab2_name;

   // Help description for what control does
   _str description;

   // some controls are not allowed in certain editions of SlickEdit.
   ToolbarRequireFlag edition_flags;
};

static const CUSTOMIZE_HELP_STRING= "On a toolbar, right-click and select \"Properties...\" to customize.";

static SPECIALCONTROL gtwSpecialControlTab:[] = {
   '_tbsearch_hist_etab'    => {OI_COMBO_BOX,2500,     0,    "_tbsearch_hist_etab",    "_tbsearch_hist_etab",    "_ul2_combobx", "Search History",        TB_REQUIRE_NONE            },
   '_tbcontext_combo_etab'  => {OI_COMBO_BOX,4200,     0,    "_tbcontext_combo_etab",  "_tbcontext_combo_etab",  "_ul2_combobx", "Current Context",       TB_REQUIRE_CURRENT_CONTEXT },
   '_tbproject_list_etab'   => {OI_COMBO_BOX,3200,     0,    "_tbproject_list_etab",   "_tbproject_list_etab",   "_ul2_combobx", "Current Project",       TB_REQUIRE_NONE            },
   '_tbproject_config_etab' => {OI_COMBO_BOX,3200,     0,    "_tbproject_config_etab", "_tbproject_config_etab", "_ul2_combobx", "Current Configuration", TB_REQUIRE_BUILD           },
   'button'                 => {OI_IMAGE,    0,        0,    "",                       "",                       "",             CUSTOMIZE_HELP_STRING,   TB_REQUIRE_NONE            },
   //'button'               => {OI_BUTTON,   380,      1220, "",                       "",                       "",             "",                      TB_REQUIRE_NONE            },
   'space1'                 => {OI_IMAGE,    BB_XSPACE,0,    "",                       "_ul2_picture",           "",             "",                      TB_REQUIRE_NONE            },
};

struct TBCONTROL {

   // Name of bitmap. If starts with tab character,
   // one of the following special names
   //    button
   //    _tbsearch_hist_etab
   //    space1
   _str name;     

   // Command to execute, can be ""
   _str command;

   // tool tip message, can be ""
   _str msg;
};

static const CUSTOMIZE_HELP_STRING= "On a toolbar, right-click and select \"Properties...\" to customize.";

struct TBCATLIST {

   // Category name
   _str name;

   // Bitset of ToolbarRequireFlag
   int rflags;

   // Bitmap info
   TBCONTROL CtrlList[];
};

// Some of these entries are replicated throughout the array.
static TBCATLIST gToolbarCatTab[] = {

   { "Custom Button",
      0,
      {
         { "\tbutton",'','' },
      }
   },
   { "User Definable Tools",
      0,
      {
        { 'bbtool01','',CUSTOMIZE_HELP_STRING },
        { 'bbtool02','',CUSTOMIZE_HELP_STRING },
        { 'bbtool03','',CUSTOMIZE_HELP_STRING },
        { 'bbtool04','',CUSTOMIZE_HELP_STRING },
        { 'bbtool05','',CUSTOMIZE_HELP_STRING },
        { 'bbtool06','',CUSTOMIZE_HELP_STRING },
        { 'bbtool07','',CUSTOMIZE_HELP_STRING },
        { 'bbtool08','',CUSTOMIZE_HELP_STRING },
        { 'bbtool09','',CUSTOMIZE_HELP_STRING },
        { 'bbtool10','',CUSTOMIZE_HELP_STRING },
        { 'bbtool11','',CUSTOMIZE_HELP_STRING },
        { 'bbtool12','',CUSTOMIZE_HELP_STRING },
        { 'bbtool13','',CUSTOMIZE_HELP_STRING },
        { 'bbtool14','',CUSTOMIZE_HELP_STRING },
        { 'bbtool15','',CUSTOMIZE_HELP_STRING },
        { 'bbtool16','',CUSTOMIZE_HELP_STRING },
        { 'bbtool17','',CUSTOMIZE_HELP_STRING },
        { 'bbtool18','',CUSTOMIZE_HELP_STRING },
        { 'bbtool19','',CUSTOMIZE_HELP_STRING },
        { 'bbtool20','',CUSTOMIZE_HELP_STRING },
        { 'bbtool21','',CUSTOMIZE_HELP_STRING },
        { 'bbtool22','',CUSTOMIZE_HELP_STRING },
        { 'bbtool23','',CUSTOMIZE_HELP_STRING },
        { 'bbtool24','',CUSTOMIZE_HELP_STRING },
        { 'bbtool25','',CUSTOMIZE_HELP_STRING },
        { 'bbtool26','',CUSTOMIZE_HELP_STRING },
        { 'bbtool27','',CUSTOMIZE_HELP_STRING },
        { 'bbtool28','',CUSTOMIZE_HELP_STRING },
        { 'bbtool29','',CUSTOMIZE_HELP_STRING },
        { 'bbtool30','',CUSTOMIZE_HELP_STRING },
        { 'bbtool31','',CUSTOMIZE_HELP_STRING },
        { 'bbtool32','',CUSTOMIZE_HELP_STRING },
        { 'bbtool33','',CUSTOMIZE_HELP_STRING },
        { 'bbtool34','',CUSTOMIZE_HELP_STRING },
        { 'bbtool35','',CUSTOMIZE_HELP_STRING },
        { 'bbtool36','',CUSTOMIZE_HELP_STRING },
        { 'bbtool37','',CUSTOMIZE_HELP_STRING },
        { 'bbtool38','',CUSTOMIZE_HELP_STRING },
        { 'bbtool39','',CUSTOMIZE_HELP_STRING },
        { 'bbtool40','',CUSTOMIZE_HELP_STRING },
        { 'bbtool41','',CUSTOMIZE_HELP_STRING },
        { 'bbtool42','',CUSTOMIZE_HELP_STRING },
        { 'bbtool43','',CUSTOMIZE_HELP_STRING },
        { 'bbtool44','',CUSTOMIZE_HELP_STRING },
        { 'bbsupport2','',CUSTOMIZE_HELP_STRING },
        { 'bbrefresh','',CUSTOMIZE_HELP_STRING },
        { 'bbswap','',CUSTOMIZE_HELP_STRING },
      }
   },
   { "Edits and Selections",
      0,
      {
         { 'bbcut',                 'cut',                     'Delete Selected Text and Copy to the Clipboard' },
         { 'bbcopy',                'copy-to-clipboard',       'Copy Selected Text to the Clipboard' },
         { 'bbpaste',               'paste',                   'Paste Clipboard into Current File' },
         { 'bbundo',                'undo',                    'Undo the Last Edit Operation' },
         { 'bbredo',                'redo',                    'Undo the Last Undo Operation' },
         { 'bbclipboards',          'list-clipboards',         'Insert a Clipboard Selected from a List of your Recently Created Clipboards' },
         { 'bbselect_code_block',   'select-code-block',       'Select Lines in the Current Code Block' },
         { 'bbfind_matching_paren', 'find-matching-paren',     'Find the Matching Parenthesis or Begin/End Structure Pairs' },
         { 'bbunindent_selection',  'unindent-selection',      'Unindent Selected Text' },
         { 'bbindent_selection',    'indent-selection',        'Indent Selected Text' },
         { 'bbsurround_with',       'surround_with',           'Surrounds the Selected Block of Text with a Control Structure or Tag' },
         { 'bbunsurround',          'unsurround',              'Un-surrounds the block under the cursor' },
         { 'bblowcase',             'maybe-lowcase-selection', 'Translate Characters in Current Word or Selection to Lower Case' },
         { 'bbupcase',              'maybe-upcase-selection',  'Translate Characters in Current Word or Selection to Upper Case' },
         { 'bbreflow',              'reflow-selection',        'Word Wrap Current Paragraph or Selection' },
         { 'bbspell',               'spell-check M',           'Spell Check from Cursor or Selected Text' },
         { 'bbshift_left',          'shift-selection-left',    'Left Shift Selection' },
         { 'bbshift_right',         'shift-selection-right',   'Right Shift Selection' },
         { 'bbtabs_to_spaces',      'convert_tabs2spaces',     'Convert Tabs to Spaces' },
         { 'bbspaces_to_tabs',      'convert_spaces2tabs',     'Convert Indentation Spaces to Tabs' },
         { 'bbbeautify',            'beautify_selection',      'Beautify Selection or Entire Buffer' },
         { 'bbdelete',              'delete_char',             'Deletes character at the cursor.' },
      }
   },
   { "Navigation",
      0,
      {
         { 'bbtop',                 'top-of-buffer',           'Moves Cursor to the Top of the Current File' },
         { 'bbbottom',              'bottom-of-buffer',        'Moves Cursor to the Bottom of the Current File' },
         { 'bbup',                  'page-up',                 'Moves Cursor Up one Page Within the Current File' },
         { 'bbdown',                'page-down',               'Moves Cursor Down one Page Within the Current File' },
         { 'bbleft',                'begin-line-text-toggle',  'Moves Cursor to the Beginning of the Current Line' },
         { 'bbright',               'end-line-text-toggle',    'Moves Cursor to the Eeginning of the Current Line' },
         { 'bbback',                'back',                    'Navigate Backward' },
         { 'bbforward',             'forward',                 'Navigate Forward' },
      }
   },
   { "Files and Buffers",
      0,
      {
         { 'bbnew',              'new',                 'Create an Empty File to Edit' },
         { 'bbopen',             'gui-open',            'Open a File for Editing' },
         { 'bbproject_add_item', 'project-add-item',    'Create Files from Template and Add to Project' },
         { 'bbtemplate_manager', 'template_manager',    'Create, Edit, and Delete your Templates' },
         { 'bbsave',             'save',                'Save Current File' },
         { 'bbsave_as',          'gui-save-as',         'Save the Current File Under a Different Name' },
         { 'bbsave_all',         'save-all',            'Save All Modified Files' },
         { 'bbsave_history',     'activate-deltasave',  'List Backup History for Current File' },
         { 'bbrevert',           'revert',              'Revert Current File to Version on Disk' },
         { 'bbclose',            'quit',                'Close Current File' },
         { 'bbclose_all',        'close-all',           'Close All Open Files' },
         { 'bbclose_others',     'close-others',        'Close All Open Files except Current File' },
         { 'bbnext_buffer',      'next-doc',            'Switch to Next File' },
         { 'bbprev_buffer',      'prev-doc',            'Switch to Previous File' },
         { 'bblist_buffers',     'list-buffers',        'List All Open Files' },
         { 'bbreload',           'auto-reload',         'Reload Files That Have Changed on Disk' },
         { 'bbdiff',             'diff',                'Bring Up DIFFzilla'VSREGISTEREDTM'' },
         { 'bbmerge',            'merge',               'Merge Two Sets of Changes Made to a File' },
         { 'bbnext_window',      'next-window',         'Switch to Next Edit Window' },
         { 'bbprev_window',      'prev-window',         'Switch to Previous Edit Window' },
         { 'bbprint',            'gui-print',           'Print Current File' },
         { 'bbprint_preview',    'print-preview',       'Print Preview For Current File' },
         { 'bbhtml_preview',     'html-preview',        'Bring up Web Browser or Display HTML File in Web Browser' },
         { 'bbfind_file',        'find-file',           'Search for File' },
         { 'bbtabs_to_spaces',   'convert_tabs2spaces', 'Convert Tabs to Spaces' },
         { 'bbspaces_to_tabs',   'convert_spaces2tabs', 'Convert Indentation Spaces to Tabs' },
         { 'bbnew_file',         'new_file',            'Create an Empty Unnamed Text File to Edit (No Prompting)' },
         { 'bbnew_file_ansic',   'new_file ANSI-C',     'Create an Empty Unnamed ANSI-C File to Edit (No Prompting)' },
         { 'bbnew_file_cpp',     'new_file C/C++',      'Create an Empty Unnamed C++ File to Edit (No Prompting)' },
         { 'bbnew_file_cs',      'new_file C#',         'Create an Empty Unnamed C# File to Edit (No Prompting)' },
         { 'bbnew_file_java',    'new_file Java',       'Create an Empty Unnamed Java File to Edit (No Prompting)' },
         { 'bbnew_file_js',      'new_file JavaScript', 'Create an Empty Unnamed JavaScript File to Edit (No Prompting)' },
         { 'bbnew_file_php',     'new_file PHP',        'Create an Empty Unnamed PHP File to Edit (No Prompting)' },
         { 'bbnew_file_ruby',    'new_file Ruby',       'Create an Empty Unnamed Ruby File to Edit (No Prompting)' },
         { 'bbnew_file_vb',      'new_file Visual Basic','Create an Empty Unnamed Visual Basic File to Edit (No Prompting)' },
         { 'bbnew_file_xml',     'new_file XML',        'Create an Empty Unnamed XML File to Edit (No Prompting)' },
         { 'bbmakedir',          'make_path',           'Create an New Directory' },
         { 'bbfolder',           'gui_cd',              'Change Directory' },
      }
   },
   { "Searching",
      0,
      {
         { 'bbfind',                'gui-find',            'Search for a String You Specify' },
         { 'bbfind_next',           'find-next',           'Search for the Next Occurrence of the String You Last Searched' },
         { 'bbfind_prev',           'find-prev',           'Search for the Previous Occurence of the String You Last Searched' },
         { 'bbfind_word',           'quick-search',        'Search for Word at Cursor' },
         { 'bbreplace',             'gui-replace',         'Search for a String and Replace it with Another String' },
         { 'bbfind_in_files',       'find-in-files',       'Search for String in Files' },
         { 'bbreplace_in_files',    'replace-in-files',    'Search and Replace for String in Files' },
         { 'bbfind_file',           'find-file',           'Search for File' },
         { 'bbnext_error',          'next-error',          'Process the Next Compiler Error Message' },
         { 'bbprev_error',          'prev-error',          'Process the Previous Compiler Error Message' },
         { 'bbstop_search',         'stop-search',         'Stops the Current Background Search' },
         { 'bbfind_matching_paren', 'find-matching-paren', 'Find the Matching Parenthesis or Begin/End Structure Pairs' },
         { "\t_tbsearch_hist_etab",     '',                    '' },
      }
   },
   { "Tagging",
      TB_REQUIRE_CONTEXT_TAGGING,
      {
         { 'bbfind_refs',          'push-ref',                        'Go to Reference' },
         { 'bbnext_tag',           'next-tag',                        'Place Cursor on Next Symbol Definition' },
         { 'bbprev_tag',           'prev-tag',                        'Place Cursor on Previous Symbol Definition' },
         { 'bbfind_symbol',        'gui-push-tag',                    'Activate the Find Symbol Tool Window to Locate Tags' },
         { 'bbpush_tag',           'push-tag',                        'Go to Definition' },
         { 'bbpush_decl',          'push-alttag',                     'Go to Declaration' },
         { 'bbpop_tag',            'pop-bookmark',                    'Pop the Last Bookmark' },
         { 'bbend_tag',            'end-tag',                         'Place Cursor at the End of the Current Symbol Definition' },
         { 'bbfunction_help',      'function-argument-help',          'Display Prototype(s) and Highlight Current Argument' },
         { 'bblist_symbols',       'list-symbols',                    'List Valid Symbols for Current Context' },
         { 'bbrefactor_rename',    'refactor_quick_rename precise',   'Rename Symbol under Cursor' },
         { 'bbclass_browser_find', 'cb-find',                         'Find the Symbol under the Cursor and Display in Symbol Browser' },
         { 'bbtag_props',          'activate_tag_properties_toolbar', 'Display the Properties for the Current Symbol in the Symbol Browser' },
         { 'bbmake_tags',          'gui-make-tags',                   'Build Tag Files for Use by the Symbol Browser and Other Context Tagging'VSREGISTEREDTM' Features' },
         { 'bbnext_statement',     'next-statement',                  'Place Cursor on Next Statement Within a Function' },
         { 'bbprev_statement',     'prev-statement',                  'Place Cursor on Previous Statement Within a Function' },
         { "\t_tbcontext_combo_etab",  '',                                '' },
      }
   },
   {
     "Completion",
      0,
      {
         { 'bbcomplete_next', 'complete-next',     'Retrieve Next Word or Variable Which is a Prefix Match of the Word at the Cursor' },
         { 'bbcomplete_prev', 'complete-prev',     'Retrieve Previous Word or Variable Which is a Prefix Match of the Word at the Cursor' },
         { 'bbcomplete_list', 'complete-list',     'Display a List of Words or Variables Which are a Prefix Match of the Word at the Cursor' },
         { 'bbcomplete_more', 'complete-more',     'Inserts the Text Up to and Including the Next Word Which Follows the Last Match Found by the Last Completion Command' },
         { 'bbcomplete_auto', 'autocomplete',      'Display Completion Options for the Word at the Cursor' },
         { 'bbexpand_alias',  'expand-alias',      'Expands the Alias Name for the Word at the Cursor' },
         { 'bbcomplete_tag',  'codehelp_complete', 'Use Tagging to Complete the Word at the Cursor' },
         { 'bblist_aliases',  'alias',             'Displays, Creates, or Modifies Aliases' },
         { 'bbnew_alias',     'new-alias',         'Create a New Alias from the Current Text Selection' },
      }
   },
   { "Windowing",
      0,
      {
         { 'bbfullscreen',      'fullscreen',      'Toggle Full Screen Editing Mode' },
         { 'bbtile_horizontal', 'tile-windows',    'Tile Edit Windows' },
         { 'bbstack_horizontal','tile-windows h',  'Horizontally Tile Edit Windows' },
         { 'bbstack_vertical',  'tile-windows v',  'Vertically Tile Edit Windows' },
         { 'bbmaximize_window', 'maximize-window', 'Maximize Current Edit Window' },
         { 'bbiconize_all',     'iconize-all',     'Minimize All Edit Windows' },
         { 'bbzoomin',          'wfont_zoom_in',   'Increase the Font Size for the Current Editor Window' },
         { 'bbzoomout',         'wfont_zoom_out',  'Decrease the Font Size for the Current Editor Window' },
         { 'bbunzoom',          'wfont_unzoom',    'Reset the Font Size for the Current Editor Window' },
         { 'bbhsplit_window',   'hsplit_window',   'Splits the Current Window Horizontally in Half' },
         { 'bbvsplit_window',   'vsplit_window',   'Splits the Current Window Vertically in Half' },
         { 'bbone_window',      'untile_windows',  'Creates one document tab group with all windows' },
      }
   },
   { "Project",
      TB_REQUIRE_BUILD,
      {
         { 'bbworkspace_new',          'workspace-new',           'Create a Workspace and/or Project' },
         { 'bbworkspace_insert',       'workspace-insert',        'Add an Existing Project to the Current Workspace' },
         { 'bbproject_properties',     'project-edit',            'Edit Settings for the Current Project' },
         { 'bbproject_dependencies',   'workspace_dependencies',  'Edit Build Dependencies for the Current Project' },
         { 'bbmake',                   'project-build',           'Run the Build Command for the Current Project' },
         { 'bbexecute',                'project-execute',         'Run the Execute Command in the Current Project' },
         { 'bbcompile',                'project-compile',         'Run the Compile Command for the Current Project' },
         { 'bbnext_error',             'next-error',              'Process the Next Compiler Error Message' },
         { 'bbprev_error',             'prev-error',              'Process the Previous Compiler Error Message' },
         { 'bbdebug',                  'project-debug',           'Run the Debug Command for the Current Project' },
         { 'bbcheckin',                'checkin',                 'Check in Current File into Version Control System' },
         { 'bbcheckout',               'checkout',                'Check out or Update Current File from Version Control System' },
         { 'bbproject_add_item',       'project-add-item',        'Create Files from Template and Add to Project' },
         { "\t_tbproject_list_etab",   '',                 '' },
         { "\t_tbproject_config_etab", '',                 '' },
      }
   },
   { "Debug",
      TB_REQUIRE_DEBUGGING,
      {
         { 'bbdebug',                         'project-debug',                   'Run the Debug Command for the Current Project' },
         { 'bbdebug_remote',                  'debug_remote',                    'Attach Debugger to a Remote Application' },
         { 'bbdebug_attach',                  'debug_attach',                    'Attach Debugger to a Running Application' },
         { 'bbdebug_detach',                  'debug_detach',                    'Detach Debugger from a Running Application' },
         { 'bbdebug_restart',                 'debug_restart',                   'Restart Execution' },
         { 'bbdebug_args',                    'debug_run_with_arguments',        'Start Debugging with Arguments' },
         { 'bbdebug_continue',                'project_debug',                   'Continue Execution' },
         { 'bbdebug_suspend',                 'debug_suspend',                   'Suspend Execution' },
         { 'bbdebug_stop',                    'debug_stop',                      'Stop Debugging' },
         { 'bbdebug_show_next_statement',     'debug_show_next_statement',       'Display the Source Line for the Instruction Pointer' },
         { 'bbdebug_up',                      'debug_up',                        'Go One Level Up Stack' },
         { 'bbdebug_down',                    'debug_down',                      'Go One Level Down Stack' },
         { 'bbdebug_top',                     'debug_top',                       'Go to Top of Stack' },
         { 'bbdebug_step_into',               'debug_step_into',                 'Step Into a Function' },
         { 'bbdebug_step_instruction',        'debug_step_instr',                'Step by One Instruction' },
         { 'bbdebug_step_deep',               'debug_step_deep',                 'Step Into Next Statement (Will Step into Runtimes)' },
         { 'bbdebug_step_over',               'debug_step_over',                 'Step Over the Next Statement' },
         { 'bbdebug_step_out',                'debug_step_out',                  'Step out of the Current Function' },
         { 'bbdebug_run_to_cursor',           'debug_run_to_cursor',             'Continue until Line Cursor is on' },
         { 'bbdebug_add_breakpoint',          'debug_add_breakpoint',            'Create a New Breakpoint or Watchpoint' },
         { 'bbdebug_toggle_breakpoint',       'debug_toggle_breakpoint',         'Toggle Breakpoint' },
         { 'bbdebug_toggle_enabled',          'debug_toggle_breakpoint_enabled', 'Toggle Breakpoint between Enabled and Disabled' },
         { 'bbdebug_toggle_breakpoint3',      'debug_toggle_breakpoint3',        'Toggle Breakpoint between Enabled, Disabled, and Removed' },
         { 'bbdebug_disable_breakpoints',     'debug_disable_all_breakpoints',   'Disable All Breakpoints' },
         { 'bbdebug_clear_breakpoints',       'debug_clear_all_breakpoints',     'Delete All Breakpoints' },
         { 'bbdebug_breakpoints',             'debug_breakpoints',               'View or Modify Breakpoints' },
         { 'bbdebug_add_exception',           'debug_add_exception',             'Add a New Exception Breakpoint' },
         { 'bbdebug_disable_exceptions',      'debug_disable_all_exceptions',    'Disable All Exceptions' },
         { 'bbdebug_clear_exceptions',        'debug_clear_all_exceptions',      'Delete All Exception Breakpoints' },
         { 'bbdebug_exceptions',              'debug_exceptions',                'View or Modify Exception Breakpoints' },
         { 'bbdebug_add_watch',               'debug_add_watch',                 'Add a Watch on the Current Variable' },
         { 'bbdebug_add_watchpoint',          'debug_add_watchpoint',            'Add a Watchpoint on the Variable under the Cursor' },
         { 'bbdebug_toggle_hex',              'debug_toggle_hex',                'Toggle Between Default and Hexadecimal Variable Display' },
         { 'bbdebug_toggle_disassembly',      'debug_toggle_disassembly',        'Toggle Display of Disassembly' },
         { 'bbdebug_set_instruction_pointer', 'debug_set_instruction_pointer',   'Set the Instruction Pointer to the Current Line' },
      }
   },
   { "Selective Display",
      0,
      {
         { 'bbselective_display', 'selective-display', 'Display Selective Display Dialog Box' },
         { 'bbshow_procs',        'show-procs',        'Outline Current File with Function Headings' },
         { 'bbhide_code_block',   'hide-code-block',   'Hide Lines inside Current Code Block' },
         { 'bbhide_selection',    'hide-selection',    'Hide Selected Lines' },
         { 'bbplusminus',         'plusminus',         'Toggles between hiding and showing the code block under the cursor' },
         { 'bbshow_all',          'show-all',          'End Selective Display. All Lines Are Displayed and Outline Bitmaps Are Removed.' },
      }
   },
   { "Bookmarks",
      0,
      {
         { 'bbset_bookmark',    'set-bookmark',    'Set a Persistent Bookmark on the Current Line' },
         { 'bbnext_bookmark',   'next-bookmark',   'Go to Next Bookmark' },
         { 'bbprev_bookmark',   'prev-bookmark',   'Go to Previous Bookmark' },
         { 'bbbookmarks',       'goto-bookmark',   'Displays Go to Bookmark Dialog Box' },
         { 'bbclear_bookmarks', 'clear-bookmarks', 'Clear All Bookmarks' },
         { 'bbdelete_bookmark', 'delete-bookmark', 'Delete the Bookmark on the Current Line' },
         { 'bbtoggle_bookmark', 'toggle-bookmark', 'Toggle Setting a Bookmark on the Current Line' },
         { 'bbpush_bookmark',   'push-bookmark',   'Push a Bookmark onto the Bookmark Stack' },
         { 'bbpop_bookmark',    'pop-bookmark',    'Jump to the Last Bookmark Pushed on the Bookmark Stack' },
      }
   },
   { "Macros",
      0,
      {
         { 'bbmacro_record',  'record-macro-toggle',      'Starts macro recording' },
         //{ 'bbmacro_stop',    'end-recording',            'Stops Macro Recording' },
         { 'bbmacro_execute', 'record-macro-end-execute', 'Runs the Last Recorded Macro' },
      }
   },
   { "Tools",
      0,
      {
         { 'bbconfig',      'config',        'Display Configuration Options Dialog' },
         { 'bbcalculator',  'calculator',    'Display Calculator Dialog Box' },
         { 'bbspell',       'spell-check M', 'Spell Check from Cursor or Selected Text' },
         { 'bbhex',         'hex',           'Toggle Hex Editing' },
         { 'bbruler',       'ruler',         'Insert Ruler Line' },
         { 'bbmenu_editor', 'open-menu',     'Edit Menus' },
         { 'bbform_editor', 'open-form',     'Edit Forms' },
         { 'bbtoolbars',    'toolbars',      'Edits Toolbars' },
         { 'bbbeautify',    'gui_beautify',  'Displays Language Specific Beautifier Dialog Box' },
         { 'bbftp',         'toggle-ftp',    'Toggles FTP Client Toolbar On/Off' }
      }
   },
   { "Version Control",
      TB_REQUIRE_VERSION_CONTROL,
      {
         { 'bbvc_diff','svc-diff-with-tip','Diff current file with the most recent version' },
         { 'bbvc_diff_symbol','svc-diff-current-symbol-with-tip','Diff the current symbol with the most recent version' },
         { 'bbvc_diff_tags','svc-diff-symbols-with-tip','Diff all symbols in the current file with the most recent version' },
         { 'bbvc_history','svc-history','Show Version Control history for the current file' },
         { 'bbcheckin','svc-commit','Checks in current file' },
         { 'bbcheckout','svc-checkout','Checks out source code from Version Control' },
         { 'bbvc_lock','vclock','Locks the current file without checking out the file' },
         { 'bbvc_unlock','vcunlock','Unlocks the current file without checking in the file' },
         { 'bbvc_update','svc-update','Get most recent version of current file from version control' },
         { 'bbvc_dir_update','svc-gui-mfupdate','Compare Directory with Version Control' },
         { 'bbvc_project_update','svc-gui-mfupdate-project','Compare current Project with Version Control' },
         { 'bbvc_project_dependencies','svc-gui-mfupdate-project-dependencies','Compare current Project and Dependencies with Version Control' },
         { 'bbvc_workspace_update','svc-gui-mfupdate-workspace','Compare Workspace with Version Control' },
         { 'bbvc_add','svc-add','Add Current file to version control' },
         { 'bbvc_pull','svc-pull-from-repository','Pull recent commits from version control repository' },
         { 'bbvc_push','svc-push-to-repository','Push recent commits to version control repository' },
         { 'bbvc_shelves','svc-list-shelves','List shelves created from version control or multi-file diff' },
         { 'bbvc_browse','svc-gui-browse-repository','Browse version control repository' },
         { 'bbvc_setup','vcsetup','Allows you to choose and configure a Version Control interface' },
      }
   },
   { "HTML",
      0,
      {
         { 'bbhtml_body',          'insert_html_body',          'Insert or Adjust Body Tag in Current HTML File' },
         { 'bbhtml_style',         'insert_html_styles',        'Insert Style Tag into Current HTML File' },
         { 'bbhtml_image',         'insert_html_image',         'Insert Image into Current HTML File' },
         { 'bbhtml_link',          'insert_html_link',          'Insert Link into Current HTML File' },
         { 'bbhtml_anchor',        'insert_html_anchor',        'Insert Target into Current HTML File' },
         { 'bbhtml_applet',        'insert_html_applet',        'Insert Java Applet into Current HTML File' },
         { 'bbhtml_script',        'insert_html_script',        'Insert Script or Script Tag into Current HTML File' },
         { 'bbhtml_hline',         'insert_html_hline',         'Insert Horizontal Line into Current HTML File' },
         { 'bbhtml_rgb_color',     'insert_rgb_value',          'Insert RGB Value into Current HTML File' },
         { 'bbhtml_head',          'insert_html_heading',       'Insert Heading Tag into Current HTML File' },
         { 'bbhtml_paragraph',     'insert_html_paragraph',     'Insert Paragraph Tag into Current HTML File' },
         { 'bbhtml_bold',          'insert_html_bold',          'Insert Bold Tag into Current HTML File' },
         { 'bbhtml_italic',        'insert_html_italic',        'Insert Italic Tag into Current HTML File' },
         { 'bbhtml_underline',     'insert_html_uline',         'Insert Underline Tag into Current HTML File' },
         { 'bbhtml_code',          'insert_html_code',          'Insert Code Tag into Current HTML File' },
         { 'bbhtml_font',          'insert_html_font',          'Insert Font Tag into Current HTML File' },
         { 'bbhtml_center',        'insert_html_center',        'Insert Align Center Tag into Current HTML File' },
         { 'bbhtml_list',          'insert_html_list',          'Insert Ordered/Unordered Tag into Current HTML File' },
         { 'bbhtml_right',         'insert_html_right',         'Insert Align Right Tag into Current HTML File' },
         { 'bbhtml_table',         'insert_html_table',         'Insert Table Tag into Current HTML File' },
         { 'bbhtml_table_row',     'insert-html-table-row',     'Insert Table Row Tag into Current HTML File' },
         { 'bbhtml_table_cell',    'insert_html_table_col',     'Insert Table Cell Tag into Current HTML File' },
         { 'bbhtml_table_header',  'insert_html_table_header',  'Insert Table Header Tag into Current HTML File' },
         { 'bbhtml_table_caption', 'insert_html_table_caption', 'Insert Table Caption Tag into Current HTML File' },
         { 'bbhtml_preview',       'html-preview',              'Bring up Web Browser or Display HTML File in Web Browser' },
         { 'bbspell',              'spell-check M',             'Spell Check from Cursor or Selected Text' },
         { 'bbftp',                'toggle-ftp',                'Toggles FTP Client Toolbar On/Off' }
      }
   },
   { "XML",
      0,
      {
        { 'bbbeautify',           'beautify_selection', 'Beautify Selection or Entire Buffer' },
        { 'bbxml_validate',       'xml-validate',       'Validate XML Document' },
        { 'bbxml_wellformedness', 'xml-wellformedness', 'Check for Well-Formedness' },
      }
   },
   { "Android",
      0,
      {
         { 'bbandroid_avd',   'android-avd-manager',  'Launch Android Virtual Device Manager' },
         { 'bbandroid_sdk',   'android-sdk-manager',  'Launch Android SDK Manager' },
         { 'bbandroid_ddms',  'android-ddms',         'Launch DDMS (Dalvik Debug Monitor)' },
      }
   },
   { "Miscellaneous",
      0,
      {
         { 'bbvsehelp',   'help -contents',  'SlickEdit Help' },
         { 'bbsdkhelp',   'wh',              'Displays SDK Help for the Word at the Cursor' },
         { 'bbsupport',   'do-webmail-support', 'Contact SlickEdit Support' },
         { 'bbapi_index', 'api-index',       'API Apprentice Help on Current Word' },
         { 'bbshell',     'dos',             'Run the Operating System Command Shell' },
         { 'bbcolor',     'color',           'Displays Color Settings Dialog Box' },
         { 'bbfont',      'config Fonts',    'Displays Font Settings Dialog Box' },
         { 'bbkeys',      'gui-bind-to-key', 'Allows you to Change Your Key Bindings' },
         { 'bbexit',      'safe-exit',       'Prompts to Save Files if Necessary and Exits the Editor' },
      }
   },
   { "Space",
      0,
      {
         { "\tspace1", '', '' },
      }
   },
};

void _tbPropsInitCategories()
{
   ToolbarFeatures features;

   // Fill the category list and select the first category:
   int i;
   for ( i = 0; i < gToolbarCatTab._length(); i++ ) {
      if ( !isinteger(gToolbarCatTab[i].rflags) ) {
         gToolbarCatTab[i].rflags = 0;
      }
      if ( features.testFlags(gToolbarCatTab[i].rflags) ) {
         ctlcatlist._lbadd_item( gToolbarCatTab[i].name );
      }
   }
   ctlcatlist._lbtop();
   ctlcatlist._lbselect_line();
   _tbPropsShowControlsForCategory( ctlcatlist._lbget_text() );
}

void _tbPropsToolbarEdit(int wid, int state)
{
   if (!wid) return;

   int child = wid.p_active_form.p_child;
   int first_child = child;
   if (child) {
      for (;;) {
         if (child.p_object == OI_COMBO_BOX) {
            _ComboBoxSetDragDrop(child, state);

         } else if (child.p_object == OI_IMAGE) {
            if (state) {
               child.p_enabled = true;
            }

         }
         child = child.p_next;
         if (child == first_child) {
            break;
         }
      }
   }
}

void _tbPropsSetupToolbars(int state)
{
   int i, n = def_toolbartab._length();
   for (i = 0; i < n; ++i) {
      if (def_toolbartab[i].tbflags & TBFLAG_SIZEBARS) {
         continue;
      }

      //int wid = _tbIsVisible(def_toolbartab[i].FormName);
      wid := _tbGetWid(def_toolbartab[i].FormName);
      if (wid != 0) {
         _tbPropsToolbarEdit(wid, state);
      }
   }

   if (!state) {
      _tbOnUpdate(true);
   }
}

int _tbLastUnifiedToolbarState(int value = null)
{
   return 0;
}
static int _tbGetBitmapIndex(_str picname)
{
   // first try to find a SVG image
   svg_picname := _strip_filename(picname, 'p');
   if (!endsWith(svg_picname,".svg",true,'i')) {
      svg_picname = picname :+ ".svg";
   }
   picIndex := _find_or_add_picture(svg_picname, true);
   if ( picIndex > 0 ) return picIndex;

   // then look for an ICO
   ico_picname := _strip_filename(picname, 'p');
   if (!endsWith(ico_picname,".ico",true,'i')) {
      ico_picname = picname :+ ".ico";
   }
   picIndex = _find_or_add_picture(ico_picname);
   return picIndex;
}
static void _tbPropsShowControls(int cIndex)
{
   //ctldescription.p_caption = '';
   int firstChild = ctlpicture.p_child;
   prevchild := 0;
   int child = firstChild;
   if ( child ) {
      for ( ;; ) {
         //messageNwait( "child="child" name="child.p_name );
         prevchild = child;
         child = child.p_next;
         if ( child.p_next == child ) {
            prevchild._delete_window();
            break;
         }
         prevchild._delete_window();
      }
   }

   ToolbarFeatures features;

   _str cName = gToolbarCatTab[cIndex].name;
   int NofControls = gToolbarCatTab[cIndex].CtrlList._length();
   ctlcontrols.p_caption = cName' Controls';
   int frame_wid = _control ctlpicture;

   first_x := 0;
   x := 0;
   y := 0;
   _lxy2lxy(SM_TWIP, SM_TWIP, x, y);

   int width, height;
   picname := "";
   wid := 0;
   rflags := 0;
   int client_width = _dx2lx(SM_TWIP, frame_wid.p_client_width);
   line_height := 0;
   int i;
   for ( i = 0; i < NofControls; ++i ) {

      #if 1
      // Note that in order for us to use the _OnUpdate facility to filter out 
      // toolbar buttons: 
      // 1. EVERY _OnUpdate_* call must check for required features (_haveBuild(), etc.)
      //    BEFORE anything else so that MF_REQUIRES_PRO can be returned.
      // 2. EVERY _OnUpdate_* call must deal with target_wid==0 
      //    gracefully (e.g. return MF_GRAYED if appropriate).
      CMDUI cmdui;
      cmdui.menu_handle = 0;
      cmdui.button_wid = 0;
      _OnUpdateInit(cmdui, 0);
      int mfflags = _OnUpdate(cmdui, 0, gToolbarCatTab[cIndex].CtrlList[i].command);
      if ( testFlag(mfflags, MF_REQUIRES_PRO) ) {
         // Missing required feature
         continue;
      }
      #else
      if ( !features.testFlags(gToolbarCatTab[cIndex].CtrlList[i].rflags) ) {
         // Missing required feature
         continue;
      }
      #endif

      picname = gToolbarCatTab[cIndex].CtrlList[i].name;

      if ( substr(picname, 1, 1) :== "\t" ) {
         picname = substr(picname, 2);
         SPECIALCONTROL* psc = &gtwSpecialControlTab:[picname];

         // check if this control is supported in this edition
         if ( !features.testFlags(psc->edition_flags) ) {
            continue;
         }

         wid = _create_window(psc->object, frame_wid, '', 0, 0, 0, 0, CW_CHILD);
         wid.p_tab_index = i + 1;
         if ( psc->eventtab_name != '' ) {
            wid.p_eventtab = frame_wid.p_eventtab;
         }
         switch ( psc->object ) {
         case OI_IMAGE:
            wid.p_picture = _tbGetBitmapIndex("bbfind");
            wid.p_eventtab = defeventtab _toolbar_customization_form.ctlpicture;
            wid.p_eventtab2 = defeventtab _ul2_picture;
            if ( picname == 'button' ) {
               // Note:
               // In 10.0 we support an Image control with both a caption AND a picture. This
               // means that the "Sample Button" on Toolbar Customization dialog must now have
               // its p_picture property =0. Now we must check in gtwSpecialControlTab for a
               // special control (e.g. space1..spaceX) and skip this loop when p_picture=0
               // and the image is not a special control.
               wid.p_picture = 0;
               wid.p_message = psc->description;
               //wid.p_style = PSPIC_FLAT_BUTTON;
               wid.p_style = PSPIC_HIGHLIGHTED_BUTTON;
               wid.p_caption = 'Sample Button';
               width = wid.p_width;
               height = wid.p_height;
            } else if ( picname == 'space1' ) {
               height = wid.p_height;
               width = psc->width;
               wid.p_picture = 0;
               wid.p_message = picname;
               wid.p_style = PSPIC_TOOLBAR_DIVIDER_VERT;

            } else {
               height = wid.p_height;
               width = psc->width;
               wid.p_picture = 0;
               wid.p_message = picname;
               wid.p_border_style = BDS_FIXED_SINGLE;
            }
            break;
         case OI_COMBO_BOX:
            wid.p_name = picname;
            wid.p_width = psc->width;
            wid.p_eventtab = defeventtab _toolbar_customization_form.ctlpicture;
            wid.p_eventtab2 = defeventtab _ul2_picture;
            wid.p_message = psc->description;
            _ComboBoxSetPlaceHolderText(wid, psc->description);
            //wid.p_eventtab = find_index(psc->eventtab,EVENTTAB_TYPE);
            //wid.p_eventtab2 = defeventtab _ul2_combobx;
            width = wid.p_width;
            height = wid.p_height;
            _ComboBoxSetDragDrop(wid, 1);
            break;
         default:
            _message_box("Internal bug. Control not supported");
            width = 0;
            height = 0;
            break;
         }

      } else {

         wid = _create_window(OI_IMAGE, frame_wid, '', 0, 0, 0, 0, CW_HIDDEN | CW_CHILD);
         wid.p_tab_index = i + 1;
         picindex := _tbGetBitmapIndex(picname);
         if ( !picindex ) {
            continue;
         }
         wid.p_picture = picindex;
         wid.p_command = gToolbarCatTab[cIndex].CtrlList[i].command;
         wid.p_message = gToolbarCatTab[cIndex].CtrlList[i].msg;
         //wid.p_style = PSPIC_FLAT_BUTTON;
         wid.p_style = PSPIC_HIGHLIGHTED_BUTTON;
         wid.p_eventtab = defeventtab _toolbar_customization_form.ctlpicture;
         wid.p_eventtab2 = defeventtab _ul2_picture;
         width = wid.p_width;
         height = wid.p_height;
      }

      if ( (x + width) > client_width ) {
         x = first_x;
         y += line_height;
      }
      wid._move_window(x, y, width, height);
      wid.p_visible = true;
      //messageNwait("w="client_width" width="width" height="height" line_height="line_height);
      if ( height > line_height ) {
         line_height = height;
      }
      x += width;
   }
}

void _tbPropsShowControlsForCategory(_str category)
{
   // A dumb linear search through the array is okay
   // since this is driven by the user selecting from a
   // list that has not more than a dozen or less items.
   n := gToolbarCatTab._length();
   for ( i := 0; i < n; i++ ) {
      if ( gToolbarCatTab[i].name == category ) {
         _tbPropsShowControls(i);
         break;
      }
   }
}

bool _tbIsSpecialControl(_str name)
{
   return (gtwSpecialControlTab._indexin(name) != 0);
}

void _tbGetSpecialControl(_str specialControlKey, SPECIALCONTROL &psc)
{
   if (specialControlKey != '' && gtwSpecialControlTab._indexin(specialControlKey)) {
      psc = gtwSpecialControlTab:[specialControlKey];
   }
}

void _tbSetSpecialControl(int wid, _str specialControlKey)
{
   SPECIALCONTROL *psc;
   psc=gtwSpecialControlTab._indexin(specialControlKey);
   if (psc) {
      wid.p_eventtab=find_index(psc->eventtab_name,EVENTTAB_TYPE);
      wid.p_eventtab2=find_index(psc->eventtab2_name,EVENTTAB_TYPE);
   }
}

int _tbGetToolbarControlType(TBCONTROL tbc)
{
   int type;
   name := tbc.name;
   if (substr(name, 1, 1) :== "\t") {
      name = substr(name, 2);
      SPECIALCONTROL *psc = &gtwSpecialControlTab:[name];

      if (psc -> object == OI_IMAGE) {
         if (name == 'button') type = sc.controls.customizations.TBCT_USER_BUTTON;
         else type = sc.controls.customizations.TBCT_SEPARATOR;
      } else if (psc -> object == OI_COMBO_BOX) type = sc.controls.customizations.TBCT_COMBO;
   } else type = sc.controls.customizations.TBCT_PIC_BUTTON;

   return type;
}

static int BBFIRST_XINDENT() {
   return (_twips_per_pixel_x()*GetSystemMetrics(VSM_TOOLBAR_HANDLE_EXTENT));
}
static const BBFIRST_YINDENT= 40;

void _tbResizeButtonBar2(int& new_width, int& new_height)
{
   int child, first_child;
   first_child = child = p_child;
   if (child == 0) {
      return;
   }
   int h_space = def_toolbar_pic_hspace * _twips_per_pixel_x();
   int v_space = def_toolbar_pic_vspace * _twips_per_pixel_y();
   int h_space2 = h_space intdiv 2;
   int x = BBFIRST_XINDENT() + h_space;
   int y = BBFIRST_YINDENT + def_toolbar_pic_vspace * _twips_per_pixel_y();
   line_height := 0;
   for (;;) {
      int child_x,child_y,child_width,child_height;
      if (child.p_object==OI_IMAGE && child.p_picture==0 && 
          _tbIsSpecialControl(lowcase(child.p_message))) {
         child_width = BB_XSPACE;
      } else {
         child._get_window(child_x, child_y, child_width, child_height);
      }

      child_x = x;
      child_y = y;
      child._move_window(child_x + h_space2, child_y, child_width, child_height);
      _lxy2lxy(p_xyscale_mode, p_scale_mode, child_width, child_height);
      if (!child.p_visible) {
         child.p_visible=true;
      }

      if (child_height > line_height) {
         line_height = child_height;
      }

      x += child_width + h_space;
      child = child.p_next;
      if (child == first_child) {
         break;
      }
   }

   new_width = x;
   new_height = y + line_height + v_space;
}

void _tbResizeButtonBar(DockingArea area)
{
   typeless junk1,junk2;
   if( area==0 ) {
      _tbResizeButtonBar2(junk1,junk2);
      return;
   }
   if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
      _tbResizeButtonBar2(junk1,junk2);
      return;
   }
   _tbResizeButtonBar2(junk1,junk2);
}

void _tbApplyControlList(_str FormName, TBCONTROL (&list)[])
{
   orig_form_wid := p_active_form;
   orig_wid := p_window_id;
   int old_form_index=find_index(FormName,oi2type(OI_FORM));
   if (!old_form_index) return;
   //int VisibleWid=_tbIsVisible(FormName);
   VisibleWid := _tbGetWid(FormName);
   int form_wid=_create_window(OI_FORM,_desktop,"",0,0,2000,900,CW_PARENT|CW_HIDDEN,BDS_SIZABLE);
   form_wid.p_name=FormName;
   form_wid.p_caption=old_form_index.p_caption;
   form_wid.p_tool_window=true;
   form_wid.p_CaptionClick=true;
   form_wid.p_eventtab2=find_index("_qtoolbar_etab2",EVENTTAB_TYPE);

   int i,count;
   count = list._length();
   for ( i = 0; i < count; ++i) {
      _str picname = list[i].name;
      if ( substr(picname,1,1):=="\t") {
         SPECIALCONTROL *psc;
         picname=substr(picname,2);
         psc=&gtwSpecialControlTab:[picname];
         int wid = _create_window(psc->object,form_wid,"",0,0,0,0,CW_CHILD);
         wid.p_tab_index=i+1;
         if (psc->eventtab_name!="") {
            wid.p_eventtab=find_index(psc->eventtab_name,EVENTTAB_TYPE);
         }
         if (psc->eventtab2_name!="") {
            wid.p_eventtab2=find_index(psc->eventtab2_name,EVENTTAB_TYPE);
         }
         switch (psc->object) {
         case OI_IMAGE:
            //wid.p_eventtab=defeventtab _toolbar_customization_form.ctlpicture;
            //wid.p_eventtab2=defeventtab _ul2_picture;
            if (picname=='button') {
               //wid.p_picture=find_index('bbfind.svg',PICTURE_TYPE);
               // Note:
               // In 10.0 we support an Image control with both a caption AND a picture. This
               // means that the "Sample Button" on Toolbar Customization dialog must now have
               // its p_picture property =0.
               wid.p_auto_size=true;
               wid.p_picture=0;
               wid.p_message=psc->description;
               //wid.p_style=PSPIC_FLAT_BUTTON;
               wid.p_style=PSPIC_HIGHLIGHTED_BUTTON;
               wid.p_caption='Sample Button';
               //width=wid.p_width;
               //height=wid.p_height;

            } else if (picname=='space1') {
               wid.p_auto_size=true;
               wid.p_picture=0;
               wid.p_message=picname;
               wid.p_style = PSPIC_TOOLBAR_DIVIDER_VERT;

            } else {
               //height=wid.p_height;
               //width=psc->width;
               wid.p_picture=0;
               wid.p_message=picname;
               //wid.p_border_style=BDS_FIXED_SINGLE;
            }
            break;
         case OI_COMBO_BOX:
            wid.p_auto_size=true;
            wid.p_name=picname;
            wid.p_width=psc->width;
            wid.p_message=psc->description;
            //wid.p_eventtab=find_index(psc->eventtab,EVENTTAB_TYPE);
            //wid.p_eventtab2=defeventtab _ul2_combobx;
            //width=wid.p_width;
            //height=wid.p_height;
            break;
         default:
            _message_box("Internal bug.  Control not supported");
            //width=0;
            //height=0;
         }
      } else {
         int wid = _create_window(OI_IMAGE,form_wid,"",0,0,0,0,CW_CHILD);
         wid.p_tab_index=i+1;
         wid.p_auto_size=true;
         picindex := _tbGetBitmapIndex(picname);
         if ( !picindex ) continue;
         wid.p_picture=picindex;
         wid.p_command = list[i].command;
         wid.p_message=list[i].msg;
         wid.p_style=PSPIC_HIGHLIGHTED_BUTTON;
         wid.p_eventtab2=defeventtab _ul2_picture;
      }
   }
   delete_name(old_form_index);

   typeless junk1,junk2;
   form_wid._tbResizeButtonBar2(junk1,junk2);
   int status=form_wid._update_template();
   set_name_info(status,FF_SYSTEM);
   _set_object_modify(status);
   form_wid._delete_window();
   if (VisibleWid) {
      _tbRedisplay(VisibleWid);
   }
   p_window_id=orig_wid;
}

_str _tbGetUpdatedIconName(_str old_icon_name)
{
   // updateobjs.e will support an "updateIcon" command argument after 22.0.1 
   // that will be faster than generating a temp-file.
   if (_version_compare(_version(), "22.0.0.9") > 0)  {
      _param1 = "";
      status := shell("updateobjs updateIcon ":+_maybe_quote_filename(old_icon_name));
      if (!status && _param1 != "") {
         return _param1;
      }
      return old_icon_name;
   }

   // generate a temporary file name
   temp_file := mktemp(Extension:"");
   if (temp_file == "") {
      return "";
   }

   // create a temp view in order to insert a fake form with this picture property
   temp_file :+= ".e";
   status := _open_temp_view(temp_file, auto temp_view_id, auto orig_view_id);
   if (status) {
      return "";
   }
   insert_line("_form update_icon_form {");
   insert_line("   p_picture=\"" :+ old_icon_name :+ "\";");
   insert_line("}");

   // save the form to disk
   _save_file('+o '_maybe_quote_filename(temp_file));
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   // now update the form with picture property in tow
   shell("updateobjs ":+temp_file);

   // now we open the temp view again
   status = _open_temp_view(temp_file, temp_view_id, orig_view_id);
   if (status) {
      delete_file(temp_file);
      return "";
   }

   // look for p_picture (will always succeed)
   search("p_picture", '@ehw');

   // parse out the bitmap value
   get_line(auto line);
   parse line with auto leading "p_picture" "=" auto bitmap ";";

   // strip quotes
   if (_first_char(bitmap) == "'") {
      bitmap = strip(bitmap, 'B', "'");
   } else if (_first_char(bitmap) == '"') {
      bitmap = strip(bitmap, 'B', '"');
   }

   // delete the temp file, we are done with it
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   delete_file(temp_file);

   // final step, return the update bitmap 
   return bitmap;
}

defload()
{
   foreach (auto cat in gToolbarCatTab) {
      foreach (auto control in cat.CtrlList) {
         if (beginsWith(control.name, "bb")) {
            _tbGetBitmapIndex(control.name);
         }
      }
   }
}

