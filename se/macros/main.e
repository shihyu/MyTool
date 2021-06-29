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
#include "listbox.sh"
#include "tagsdb.sh"
#include "csv.sh"
#include "minihtml.sh"
#import "se/lang/api/LanguageSettings.e"
#import "se/alias/AliasFile.e"
#import "se/color/ColorScheme.e"
#import "autosave.e"
#import "autocomplete.e"
#import "codetemplate.e"
#import "bhrepobrowser.e"
#import "bufftabs.e"
#import "context.e"
#import "dir.e"
#import "enterpriseoptions.e"
#import "env.e"
#import "fileman.e"
#import "files.e"
#import "filetypemanager.e"
#import "help.e"
#import "hotfix.e"
#import "ini.e"
#import "listbox.e"
#import "menu.e"
#import "notifications.e"
#import "options.e"
#import "pip.e"
#import "recmacro.e"
#import "restore.e"
#import "savecfg.e"
#import "cfg.e"
#import "saveload.e"
#import "seldisp.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "taggui.e"
#import "tags.e"
#import "tbcontrols.e"
#import "tbfind.e"
#import "tbopen.e"
#import "tbprops.e"
#import "toolbar.e"
#import "qtoolbar.e"
#import "dockchannel.e"
#import "se/ui/toolwindow.e"
#import "vchack.e"
#import "window.e"
#import "wkspace.e"
#import "wman.e"
#import "xml.e"
#import "xmldoc.e"
#import "search.e"
#import "fileproject.e"
#import "bind.e"
#import "project.e"
#import "tbcmds.e"
#import "quickstart.e"
#endregion

using namespace se.lang.api;
using namespace se.ui;

static bool gConfigMigrated = false;

// Save _config_modify flags caused by a transfer configuration
// separate from _config_modify so user is not confused by
// Save Configuration? message_box.
static int gcfgTransferModifyFlags;

int gin_restore;
bool gdelayed_activateOutputWindow;
int _use_timers=1;
bool def_use_timers=true;
bool def_hex_view_copy=true;
bool def_hex_binary_copy=true;
bool def_select_all_line=true;
/*
   On some remote networks, findfirst/findnext is very slow.
   _IsKeyPending might be a reasonable solution but it just
   doesn't work on Unix and macOS (not sure about Windows).
   Here we create a scheme to have auto complete in the
   list_matches() function timeout (def_fileio_timeout) and 
   continue to quickly timeout for up to 2 seconds (def_fileio_continue_to_timeout).
*/
typeless gautocomplete_ContinueToFail;
typeless gautocomplete_MatchFunIndex;
typeless gautocomplete_StartTime;

_str _FILESEP; // Don't initialize this here.
_str _FILESEP2   = '\';
_str _PATHSEP    = ':';
_str _COMMANDSEP = ';';

typeless _config_file_dates:[];
bool def_prompt_unnamed_save_all;
//bool def_prompt_unnamed_save_all_workspace;
int def_inclusive_block_sel=1;
_str _post_install_version = "0";
bool def_list_binary_files=true;
int def_maxcombohist=20;  // Default maximum combo box retrieval list
// Used by Help and API index. We need these declared here because they are
// used to transfer configuration data from pre-7.0 versions.
static bool buildingStateFile=false;
static bool gAutoRestoreFinished=true;
static _str _selection_list_font;

/**
 * Message logging support.  If enabled, all messages sent to the 
 * SlickEdit status line will be logged to the messsage log file. 
 * (message.log in the logs subdir of the user configuration directory). 
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_message_logging = false;

/* 
   Have the default encoding automatically detect Utf-8, Utf-16,
   and Utf-32 files without a leading signature. Utf-8 files
   with no signature are becoming more common. The Binary
   language setup ensures that some obvious extensions are
   loaded in binary and start in hex mode.
*/
_str  def_encoding='+fautounicode2';

/**
 * If enabled, when you click or switch focus to a text box or
 * combo box, automatically select the text in the text box
 * so that it can be typed over.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_focus_select=true;

/**
 * Problem on Solaris running CDE causes some keys (Left arrow)
 * not to work when this option is on. If this is set to true (default)
 * then _firstinit() will set def_focus_select=false. This allows the
 * user to override it if they want.
 *
 * @default true
 * @categories Configuration_Variables
 *
 * @see def_focus_select
 */
bool def_cde_workaround=true;
int def_max_makefile_menu=15;
//Currently only DRAW_BOX flag used
int def_surround_mode_flags=0xffff;
int def_vc_advanced_options=VC_ADVANCED_PROJECT|VC_ADVANCED_BUFFERS;
int def_optimize_sccprjfiles=4000;
_str _workspace_filename='';
_str def_page='p';  // p- full page (default), c-cursor
int def_javadoc_format_flags=VSJAVADOCFLAG_BEAUTIFY|VSJAVADOCFLAG_ALIGN_PARAMETERS|VSJAVADOCFLAG_ALIGN_EXCEPTIONS|VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION|VSJAVADOCFLAG_ALIGN_RETURN|VSJAVADOCFLAG_ALIGN_DEPRECATED|VSJAVADOCFLAG_DEFAULT_ON;
int def_javadoc_parammin=6;
int def_javadoc_parammax=10;
int def_javadoc_exceptionmin=6;
int def_javadoc_exceptionmax=10;
int gxmlcfg_help_index_handle;
bool def_error_check_help_items=true;
_str st_batch_mode=0;    /* Used by ST command to indicate DEFMAIN -p option. */
_str _macro_ext;

/**
 * If this configuration was upgraded from a previous one, this
 * value holds the previous configuration directory.
 */
_str def_config_transfered_from_dir='';

int def_record_dataset_mode=1;
_str   def_alias_case='i';
_str def_long_weekday_names  = "Sunday Monday Tuesday Wednesday Thursday Friday Saturday";
_str def_short_weekday_names = "Sun. Mon. Tues. Wed. Thur. Fri. Sat.";
_str def_long_month_names  = "January February March April May June July August September October November December";
_str def_short_month_mames = "Jan. Feb. Mar. Apr. May June July Aug. Sept. Oct. Nov. Dec.";
static _str gconfig_path;
_str _editor_cmdline="";
int def_vcpp_version=0;
typeless _argument='';
typeless _arg_complete='';
int def_ctags_flags=CTAGS_FLAGS_TAG_PROTOTYPES;
bool def_switchbuf_cd=false;
VS_TAG_RETURN_TYPE gnull_return_type={null,null,null,0,0,false,{'\1'=>''},0};
int def_fileio_timeout=250;
int def_fileio_continue_to_timeout=2000;
VSCodeHelpFlags def_codehelp_flags = VSCODEHELPFLAG_DEFAULT_FLAGS;

int def_codehelp_idle=0;  // Our stuff seems pretty fast now
                           // Try this for a while and maybe
                           // back off to 50 milliseconds if
                           // we think its necessary.

/**
 * Constants for maximum limits of items inserted by context
 * tagging, specifically, auto-list members.
 */
int def_tag_max_function_help_protos   = VSCODEHELP_MAXFUNCTIONHELPPROTOS;
int def_tag_max_list_members_symbols   = VSCODEHELP_MAXLISTMEMBERSSYMBOLS;
int def_tag_max_list_members_time      = VSCODEHELP_MAXLISTMEMBERSTIME;
int def_tag_max_list_matches_symbols   = VSCODEHELP_MAXLISTMATCHESSYMBOLS;
int def_tag_max_list_matches_time      = VSCODEHELP_MAXLISTMATCHESTIME;
int def_tag_max_find_context_tags      = VSCODEHELP_MAXFINDCONTEXTTAGS;

WORKSPACE_LIST def_workspace_info[]=null;
AUTORESTORE_MONITOR_CONFIG gautorestore_monitor_configs:[]=null;
// flag indicating whether or not push and pull should be interactive
bool def_git_pushpull_interactive = true;
//
//  Set initial values for global variables defined in slick.sh
//
_str _help_file_spec=''
   ,def_load_options="-L"
   ,def_save_options="-O"
   ,def_preload_ext=""
   ,def_select_style="E"
   ,def_persistent_select='Y'
   ,def_advanced_select=''
   ,def_scursor_style=''
   ,def_line_insert="A"
   ,def_exit_process='1'
   ,_error_file=''
   ,def_prompt=''
   ,_macro_ext=''
   ,_tag_pass=''
   ,def_file_types=''
   ,def_qmark_complete=''
   ,def_one_file='+w'
   ,def_scroll_speeds='30.0 20.3 10.4 10.6'
   ,def_next_word_style
   ,def_top_bottom_style
   ,def_leave_selected=''
   ,def_gui=''
   ,def_alt_menu=''
   ,def_modal_tab=''
   ,def_cua_textbox='1'
   ,def_mdi_menu=_MDIMENU
   ,_cur_mdi_menu=_MDIMENU
   ,def_keydisp='L'
   ,def_as_timer_amounts='m1 m1 0'
   ,def_as_directory      // Default directory for AutoSave
   ,def_mffind_style=2
   ,def_tprint_cheader="%f"
   ,def_tprint_cfooter="%p"
   /*
   options -->   print_flags,blank_lines_after_header,
                 blank_lines_before_footer,lines_per_page,
                 columns_per_line,linenums_every,
   */
   ,def_tprint_options=(TPRINT_FORM_FEED_AFTER_LAST_PAGE):+
                       ",2,2,60,80,0"
   ,def_tprint_lheader,def_tprint_lfooter
   ,def_tprint_rheader,def_tprint_rfooter
   ,def_tprint_command="lp -c -o nobanner %f"   // Optional command which prints file
   ,def_tprint_filter    // Optional filter to filter buffer text
                         // before printing.
   ,def_tprint_device="/dev/lp0"
   //,def_mdibb='_mdibutton_bar_form'    // Name of default button bar
   ,def_tprint_pscommand='--media=Letter --no-header --quiet';

//_str def_color_scheme="VSE Default";
_str def_color_scheme="Default";
_str def_embedded_color_scheme="(init)";

bool def_load_partial=true;
int def_load_partial_ksize=8000;
_str   def_save_on_compile='1 0'; //0=no save, 1=save current file, 2=save all files
_str _compiler_default; // Default compiler package when create new project.
bool def_close_window_like_1fpw=true;

_str def_keys = '';
bool def_exit_on_autosave = false;
int def_open_style=OPEN_SMART_OPEN;
bool def_mac_save_prompt_style=true;
/* Note that this def var is intentionally ignored by some features.
   The Update Directory dialog ignores this setting and always tries
   to recyle files that are deleted.
*/
bool def_delete_uses_recycle_bin=false;

_str def_trash_command='';

bool def_prompt_open_style=true;
int def_tagging_cache_ksize = 0x10000;  // 64 megabytes
int def_tagging_cache_max_ksize  = 0x80000;  // 512 megabytes
bool def_tagging_use_memory_mapped_files=true;  // use memory mapped files for tag databases
bool def_tagging_use_independent_file_caches=true;  // use independent file caches for each database
int def_context_tagging_max_cache=250;  // number of current context sets to cache
_str def_tagging_excludes = '';
int def_background_tagging_timeout=250;
int def_background_tagging_idle=500;
int def_background_tagging_threads=4;
int def_background_reader_threads=2;
int def_background_database_threads=1;
int def_background_tagging_maximum_jobs=1000;
int def_background_tagging_max_ksize=32000;
bool def_background_tagging_minimize_write_locking=true;
DefsToolWindowOptions def_proc_tree_options=PROC_TREE_AUTO_EXPAND|PROC_TREE_SORT_LINENUMBER;
int def_proc_tree_expand_level = 0;
int def_tag_select_options=PROC_TREE_SORT_FUNCTION;
SETagFilterFlags def_tagwin_flags = SE_TAG_FILTER_ANYTHING;    // Turn on everything just in case we add more flags in the next release
SETagFilterFlags def_references_flags = SE_TAG_FILTER_ANYTHING; // Turn on everything just in case we add more flags in the next release
SETagFilterFlags def_proctree_flags= SE_TAG_FILTER_ANYTHING;  // Turn on everything just in case we add more flags in the next release
SETagFilterFlags def_tagselect_flags = SE_TAG_FILTER_ANYTHING;// Turn on everything just in case we add more flags in the next release
SETagFilterFlags def_find_symbol_flags = SE_TAG_FILTER_ANYTHING;// Turn on everything just in case we add more flags in the next release
// If SE_TAG_FILTER_ANYTHING changes, we need to rename this variable or convert the old default
// value to the new default value.
SETagFilterFlags def_class_flags = SE_TAG_FILTER_ANYTHING;
SETagFilterFlags def_javadoc_filter_flags=(SE_TAG_FILTER_ANYTHING & ~(SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_MISCELLANEOUS|SE_TAG_FILTER_INCLUDE|SE_TAG_FILTER_LABEL|SE_TAG_FILTER_LOCAL_VARIABLE));
SETagFilterFlags def_xmldoc_filter_flags =(SE_TAG_FILTER_ANYTHING & ~(SE_TAG_FILTER_PACKAGE|SE_TAG_FILTER_MISCELLANEOUS|SE_TAG_FILTER_INCLUDE|SE_TAG_FILTER_LABEL|SE_TAG_FILTER_LOCAL_VARIABLE));

bool def_pmatch_style=false;
_str def_pmatch_style2=1;
int def_pmatch_max_diff_ksize = 100;   // Maximum distance to search forward/backward to find matching paren
int def_pmatch_max_level = 500;        // Maximum number of nesting levels to search for matching paren
int def_pmatch_max_ksize = 1024;       // Turn off paren matching if the buffer is larger than 1 megabyte

int def_updown_col=0;
int def_change_dir=1;

int def_use_xp_opendialog = 0;

bool def_copy_noselection=true;
bool def_stop_process_noselection=true;
bool def_enter_indent=false;
bool def_auto_landscape=true;
bool def_cursorwrap=false;
bool def_hack_tabs=false;
bool def_restore_cursor=false;
bool def_pull=true;
bool def_jmp_on_tab=true;
bool def_linewrap=false;
bool def_join_strips_spaces=true;
bool def_reflow_next=false;
bool def_stay_on_cmdline=false;
bool def_start_on_cmdline=false;
bool def_start_on_first=false;
bool def_exit_file_list=false;
int def_auto_restore=0;
int def_eclipse_switchbuf=1;
bool def_eclipse_extensionless=true;
bool def_eclipse_check_ext_mode=true;
bool def_deselect_copy=true;
bool def_deselect_paste=false;
bool def_deselect_drop=false;
_str def_oemaddons_modules="";
//bool def_ignore_tcase=true;
bool def_keep_dir=false;
bool def_from_cursor=false;   // Set to one in EMACS emul. Effects some word functions.
bool def_process_tab_output=true;  // Default build window output to tab in output toolbar
bool def_terminal_tab_output=true;
bool def_interactive_tab_output=true;
int def_mouse_menu_style=2;    // MM_MARK_FIRST
//bool def_mouse_paste=__UNIX__;  // middle mouse button does paste
bool def_brief_word=false;
bool def_vcpp_word=false;
bool def_subword_nav=false;
int def_cd=CDFLAG_CHANGE_DIR_IN_BUILD_WINDOW|CDFLAG_CHANGE_DIR_IN_TERMINAL_WINDOWS|CDFLAG_EXPAND_ALIASES_IN_CD_FORM;
bool def_sync_envvars_to_terminals=true;
int def_max_filehist=9;
int def_max_allfileshist=64;
int def_max_windowhist=9;
int def_max_workspacehist=9;
bool def_filehist_verbose=false;
int def_actapp=ACTAPP_AUTORELOADON|ACTAPP_AUTOREADONLY;
int def_vcflags=VCF_SET_READ_ONLY;
int def_as_flags = AS_ASDIR;    // AutoSave flags
int def_restore_flags = RF_CWD | RF_PROJECTFILES | RF_WORKSPACE | RF_PROJECTS_TREE | RF_PROJECT_LAYOUT;
int def_init_delay=50;
int _display_wid=0;

int def_read_ahead_lines= 500;
int def_clipboards= 50;
int def_max_filepos=1000;
int def_compile_flags=COMPILEFLAG_CDB4COMPILE;
int def_max_fhlen=40;      // Maximum length of filenames under menus
bool def_display_buffer_id=false;
int def_err=0;
int _config_modify=0;
int def_mfsearch_init_flags=MFSEARCH_INIT_HISTORY|MFSEARCH_INIT_AUTO_ESCAPE_REGEX;
int def_exit_flags=EXIT_CONFIG_ALWAYS/*|EXIT_FILES_PROMPT*/;
int def_re_search_flags=VSSEARCHFLAG_PERLRE;
int _filepos_view_id=0;
bool def_autoclipboard; //0 1

bool _no_mdi_bind_all=false;
bool def_cfgfiles=true;
int def_max_autosave_ksize=500;//Largest file in K to autosave
int def_diff_flags=0;  // Passed to DLL. Ignore leading,trailing...
int def_diff_edit_flags=DIFFEDIT_AUTO_JUMP|DIFFEDIT_SHOW_GAUGE|DIFFEDIT_START_AT_FIRST_DIFF;
#if 1
int GMFDiffViewOptions=DIFF_VIEW_DIFFERENT_FILES|DIFF_VIEW_VIEWED_FILES|DIFF_VIEW_MISSING_FILES1|DIFF_VIEW_MISSING_FILES2|DIFF_VIEW_DIFFERENT_SYMBOLS|DIFF_VIEW_MISSING_SYMBOLS1|DIFF_VIEW_MISSING_SYMBOLS2;
int def_mfdiff_functions=1;
#else
int GMFDiffViewOptions=DIFF_VIEW_DIFFERENT_FILES|DIFF_VIEW_VIEWED_FILES|DIFF_VIEW_MISSING_FILES1|DIFF_VIEW_MISSING_FILES2;
int def_mfdiff_functions=0;
#endif
int def_smart_diff_limit=1000;
int def_smart_diff_iterations=5000;
int def_max_diff_markup=5000;
int def_max_fast_diff_size=800;
int def_diff_max_intraline_len=4096;
int def_diff_num_sessions=10;
bool def_dragdrop=true;
int def_seldisp_flags=SELDISP_SHOWPROCCOMMENTS;
int def_seldisp_maxlevel=25;
int def_seldisp_minlevel=20;
bool def_seldisp_single=false;
int def_vcpp_flags=0; // VCPP_ADD_VSE_MENU;
int def_mfflags=1;
_str def_bgtag_options='30 10 3 600';
_str def_add_to_prj_dep_ext='.h .hpp .hxx .h++';

_str def_cvs_global_options="";  // These are options passed to all cvs operations
                                 // before the command name
_str def_svn_global_options="";  // These are options passed to all cvs operations
                                 // before the command name
int _CVSDebug=0;

int def_cvs_flags=CVS_RESTORE_COMMENT;

_str def_cvs_shell_options='Q';
bool def_updown_screen_lines=true;
_str _last_lang='';   // Last state file setting for lang

int def_wpselect_flags = 0;

bool def_vcpp_bookmark = false;

bool def_filelist_show_dotfiles; //false true;
/**
 * Optional string to place before backup files' names and extensions:
 * &lt;prefix&gt;&lt;file&gt;.&lt;ext&gt;
 *
 * @default ""
 * @categories Configuration_Variables
 *
 * @see def_backupinfix
 * @see def_backuppostfix
 */
_str def_backupprefix;

/**
 * Optional string to place between backup files' names and extensions:
 * &lt;file&gt;&lt;infix&gt;.&lt;ext&gt;
 *
 * @default ""
 * @categories Configuration_Variables
 *
 * @see def_backupprefix
 * @see def_backuppostfix
 */
_str def_backupinfix;

/**
 * Optional string to place after backup files' names and extensions:
 * &lt;file&gt;.&lt;ext&gt;&lt;postfix&gt;
 *
 * @default ""
 * @categories Configuration_Variables
 *
 * @see def_backupprefix
 * @see def_backupinfix
 */
_str def_backuppostfix = '.BAK';

#if 0
/** 
 * Optional encoding override for faster multi-file 
 * search/replace 
 *  
 * <p>Set to +fautounicode for almost the best speed while still
 * get very good encoding determination. +fautotext is fastest 
 * because it simple chooses chooses the default text encoding 
 * which can be Utf-8 or the active code page. 
 */
//_str def_mffind_encoding; * 
#endif


// symbol browser limits
int def_cbrowser_low_refresh    = CB_LOW_WATER_MARK;
int def_cbrowser_high_refresh   = CB_HIGH_WATER_MARK;
int def_cbrowser_flood_refresh  = CB_FLOOD_WATER_MARK;

// obsolete (pre-11.0.2) versions of symbol browser limits
int def_cb_low_refresh    = CB_LOW_WATER_MARK;
int def_cb_high_refresh   = CB_HIGH_WATER_MARK;
int def_cb_flood_refresh  = CB_FLOOD_WATER_MARK;

// references tool window limits
int def_cb_max_references = CB_MAX_REFERENCES;

// refactoring default configuration name
_str def_refactor_active_config = "";

   /*
      It is pretty easy to run out of memory when when converting
      code to HTML.
      For example, 100Meg of color coded XML converts to 500Meg of Utf8 HTML.
      The 500Meg of Utf8 needs to be converted to Utf16 which requires an additional
      ~2000Meg. You need 2.5 gig!!! 
    
      Also, users most likely only expect to convert small source snippets to HTML. Converted
      large amounts of color coded text to HTML is a waste of time.
   */
long def_max_html_clipboard_ksize = 1000;  // 1 megabyte

/*
  When true and _SetEditorLanguage is called, the buffer cache size
  is automatically set based on the file size.
*/
bool def_auto_set_buffer_cache= true;

/*
   Turn off color coding if files larger than size below.
*/
long def_auto_set_buffer_cache_ksize= 100000;    // 100 megabytes
/*
   Use fundamental mode for files larger than ksize below.
*/
long def_use_fundamental_mode_ksize= 50000;    // 50 megabytes

long def_use_old_line_numbers_ksize= 10000;    // 10 megabytes

/*
   Turn off undo if for files larger than ksize below.
*/
long def_use_undo_ksize= 100000;    // 100 megabytes

/*
   Turn off soft wrap if for files larger than ksize below.
*/
long def_use_softwrap_ksize= 100000;    // 100 megabytes

/*
   Turn off view line numbers for files larger than ksize below.
*/
long def_use_view_line_numbers_ksize= 100000; // 100 megabytes

long def_use_minimap_ksize=1000000; // 100 megabytes

//Comment block autocompletion default
bool def_auto_complete_block_comment = true;

//Default value for number of line comments needed for line comment wrapping
int def_cw_line_comment_min = 2;

// Only show workspace files in version control GUI update
int def_svc_update_only_shows_wkspace_files = 0;

// Only show controlled files (no '?' files) in version control GUI update
int def_svc_update_only_shows_controlled_files = 0;

/**
 * Maximum number of lines in a block comment or in a block of consecutive line 
 * comments that will be analyzed when trying to automatically determine the 
 * proper width on the comment. Comment wrapping will look analyze at most 
 * def_cw_analyze_lines_max number of lines above the cursor position and 
 * def_cw_analyze_lines_max number of lines below the cursor postion. 
 */
int def_cw_analyze_lines_max = 100;

//Comment wrap defaults
int CW_defaultFixedWidth = 64;
int CW_defaultRightMargin = 80;
int CW_defaultLineCommentMin = 2;
//XML/HTML formatting defaults
int def_xw_pre_tag_search_depth = 10;

/**
 * Default line comment mode. 
 */
COMMENT_LINE_MODE def_comment_line_mode = LEFT_MARGIN;

/**
 * Disable replace tooltip helper used for search and replace.
 *
 * @categories Configuration_Variables
 */
bool def_show_plusminus_tooltip=true;
bool def_disable_replace_tooltip = false;
bool def_disable_postbuild_error_markers = false;
bool def_disable_postbuild_error_scroll_markers = false;
int def_max_mffind_output_ksize = 2*1024;
int def_initial_search_results_buffers = 2;

_str def_import_file_types = "Text Files (*.txt)";

int def_clipboards_max_preview = 32768;

/** 
 * Set this to 0 if you do not want to be warned about 
 * having a VSLICKCONFIG or VSLICKCLASSICCONFIG environment 
 * variable, which as of SlickEdit 2008, are no longer 
 * supported. 
 * 
 * VSLICKCONFIG has been replaced with SLICKEDITCONFIG 
 * which specifies a versioned subdirectory.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_warn_about_vslickconfig=true;

defload()
{
   if ( find_index('st',COMMAND_TYPE) ) return;
   buildingStateFile=true;
   _default_keys=find_index('default-keys',EVENTTAB_TYPE);
   //set_eventtab_index(_default_keys,event2index(F3),find_index('quit-view',COMMAND_TYPE));
   orig_bit:=(def_actapp& ACTAPP_AUTOREADONLY);
   def_actapp&=~ACTAPP_AUTOREADONLY;
   execute('addons ',"");    // run the addons module to add all other modules.
   int status=rc;
   def_actapp|=orig_bit;
   if ( status && status!=2 ) {
      process_make_rc(status,'addons');
   }
   if ( ! status) {
     clear_message();   // If messages at bottom, erase it.
   }

   // OEM-specific addons
   oemAddons();

}

/**
 * Normalize a VSE product version, so if it's 10 we will return 10.0.0, and
 * if it's 9.1 it will return 9.1.0.
 *
 * @param version  Arbitrary version string, like 10.2.4
 * @param major    (out) Major version
 * @param minor    (out) Minor version
 * @param revision (out) Revision number
 * @param build    (out) Build number
 */
void normalizeVSEVersion(_str version, _str& major, _str& minor, _str& revision, _str& build)
{
   parse version with major'.'minor'.'revision'.'build;
   major = isnumber(major) ? major : 0;
   minor = isnumber(minor) ? minor : 0;
   revision = isnumber(revision) ? revision : 0;
   build = isnumber(build) ? build : 0;
}

/**
 * Split a delimited string and insert it into an array.
 *
 * @categories String_Functions
 *
 * @param delimited_string Delimited string to turn into an array
 * @param delimiter        Delimiter that separates string parts
 * @param string_array     Array to recieve string parts minus delimiters
 *
 * @see join
 * @see split2array
 */
void split(_str delimited_string, _str delimiter, _str (&string_array)[])
{
   _str ss;
   string_array = null;
   while(delimited_string != "") {
      parse delimited_string with ss (delimiter) delimited_string;
      string_array[string_array._length()] = ss;
   }
}

/**
 * Split a delimited string and return it as an array.
 *
 * @categories String_Functions
 *
 * @param delimited_string Delimited string to turn into an array
 * @param delimiter        Delimiter that separates string parts
 *
 * @see join
 * @see split
 */
STRARRAY split2array(_str delimited_string, _str delimiter)
{
   _str ss;
   _str string_array[];
   while(delimited_string != "") {
      parse delimited_string with ss (delimiter) delimited_string;
      string_array[string_array._length()] = ss;
   }
   return string_array;
}


/**
 * Join the contents of an array of strings into a delimited string.
 *
 * @categories String_Functions
 *
 * @param string_array     Array of strings to join
 * @param delimeter        delimeter to use when joining
 *
 * @return Delimited string
 *
 * @see split
 */
_str join(_str (&string_array)[], _str delimiter)
{
   result := "";
   int i,n = string_array._length();
   if (n > 0) {
      result = string_array[0];
   }
   for (i=1; i<n; ++i) {
      strappend(result, delimiter);
      strappend(result, string_array[i]);
   }
   return result;
}
/**
 * Join the contents of dictionary values or keys into a
 * delimited string.
 *
 * @categories String_Functions
 *
 * @param container        dictionary of strings to join
 * @param delimeter        delimeter to use when joining
 *
 * @return Delimited string
 *
 * @see split
 */
_str joinDict(typeless &dict, _str delimiter,bool join_values=false)
{
   result := "";
   first_iter := true;
   foreach (auto k=>auto v in dict) {
      if (!first_iter) {
         strappend(result, delimiter);
      }
      if (join_values) {
         strappend(result, v);
      } else {
         strappend(result, k);
      }
      first_iter=false;
   }
   return result;
}

/**
 * If a version component is a wildcard '*', set it to -1
 *
 * @param number The input version component
 *
 * @return The input version component if it's actually a #, otherwise -1
 */
_str makeWildcardNegative(_str number)
{
   _str result;
   result = number == '*' ? -1 : number;
   return result;
}

/**
 * Compare two VSE product versions, like 10.0 and 9.0.4.
 *
 * @param version1
 * @param version2
 *
 * @return 1 if version1 > version2, 0 if version1 == version2, -1 if version1 < version2
 */
int compareVSEVersions(_str version1, _str version2)
{
   _str major1, minor1, revision1, build1;
   normalizeVSEVersion(version1,major1,minor1,revision1,build1);
   _str major2, minor2, revision2, build2;
   normalizeVSEVersion(version2,major2,minor2,revision2,build2);
   major1 = makeWildcardNegative(major1);
   major2 = makeWildcardNegative(major2);
   minor1 = makeWildcardNegative(minor1);
   minor2 = makeWildcardNegative(minor2);
   revision1 = makeWildcardNegative(revision1);
   revision2 = makeWildcardNegative(revision2);
   build1 = makeWildcardNegative(build1);
   build2 = makeWildcardNegative(build2);
   result := -1;
   if( major1 > major2 ) {
      result = 1;
   } else if( major1 == major2 ) {
      if( minor1 > minor2 ) {
         result = 1;
      } else if( minor1 == minor2 ) {
         if( revision1 > revision2 ) {
            result = 1;
         } else if( revision1 == revision2 ) {
            if( build1 > build2 ) {
               result = 1;
            } else if( build1 == build2 ) {
               result = 0;
            }
         }
      }
   }
   return result;
}

static const POSTINSTALL_MACRO_NAME=    "postinstall.e";
static const OEMPOSTINSTALL_MACRO_NAME= "oempostinstall.e";

static void _maybe_load_user_macros(_str orig_def_macfiles) {
   // IF we are building the state file, don't need to worry about config
   if (editor_name('s')=='') {
      return;
   }
   if (!gConfigMigrated && !_default_option(VSOPTION_LOCALSTA)) {
      orig_config_modify:=_config_modify;
      apply_user_macros(orig_def_macfiles,auto need_new_config_modification);
      if (!need_new_config_modification) {
         _config_modify=orig_config_modify;
      }
      return;
   }
   if (gcfgTransferModifyFlags) {
      apply_user_macros(orig_def_macfiles);
   }
}

/**
 * Do the post-install tasks
 */
static void DoPostInstall(_str orig_def_macfiles,bool do_save_config_immediate=false)
{
   // IF we are building the state file, don't need to worry about config
   if (editor_name('s')=='') {
      return;
   }
   if (!gConfigMigrated && !_default_option(VSOPTION_LOCALSTA)) {
#if 0
      orig_config_modify:=_config_modify;
      apply_user_macros(orig_def_macfiles);
      _config_modify=orig_config_modify;
#endif
      //_message_box('new code DoPostInstall immed='do_save_config_immediate' st='editor_name('s'));
      if (do_save_config_immediate) {
         return;
      }
      cant_write_config_files := _default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
      if ( _allow_quick_start_wizard && !cant_write_config_files) {
         quick_start();
      }
      return;
   }
   /*
      When an old config is transfered, want the buffers to start
      out with the beautifier settings. 

      The only bad thing with doing this is that the user may 
      have a modified "indent_with_tabs" and/or "tabs" for one buffer. 
      It would take a lot of work to fix this and it's not worth
      the effort. Just give the user the setings from their profile.
   */
   if (gcfgTransferModifyFlags) {
#if 0
      apply_user_macros(orig_def_macfiles);
#endif
      // Unable to import beautifier.e for some reason
      //_beautifier_cache_clear('');
      int index;
      index=find_index("_beautifier_cache_clear",PROC_TYPE);
      if (index_callable(index)) call_index('',index);
      index=find_index("_beautifier_profile_changed",PROC_TYPE);
      if (index_callable(index)) call_index('','',index);
   }
   _str currentVersion;
   parse get_message(SLICK_EDITOR_VERSION_RC) with . 'Version' currentVersion . ;
   //_message_box('_post_install_version='_post_install_version' cur='currentVersion);
   if (compareVSEVersions(_post_install_version, currentVersion) < 0) {
      if (do_save_config_immediate) {
         /* When a macro is run with -p (i.e vsdiff or install program running license manager)
            only save the configuration if settings were migrated. That way,
            there is no access denied problem saving the state file if an instance
            of SlickEdit is running.
         */ 
         if (gcfgTransferModifyFlags) {
            save_config('',true);
         }
      } else {
         // We may need to do some post-install tasks. If the version we last ran post-install
         // tasks is < the current version, then we need to run a post-install macro to complete
         // installation. This change was made to accommodate unattended installation.
         _str macro=_getSlickEditInstallPath() :+ "macros":+FILESEP:+POSTINSTALL_MACRO_NAME;
         _str oem_postinstall_macro=_getSlickEditInstallPath() :+ "macros":+FILESEP:+OEMPOSTINSTALL_MACRO_NAME;
         if ( file_exists(oem_postinstall_macro) ) {
            macro=oem_postinstall_macro;
         }
         int status=shell(_maybe_quote_filename( macro ));
         _config_modify_flags(CFGMODIFY_MUSTSAVESTATE);
         //_message_box('gcfgModifyFlags='gcfgTransferModifyFlags' cm='_config_modify' postv='_post_install_version' cv='currentVersion);
         _post_install_version = _version();
         _post_call(save_config);
      }
   }

}

/**
 * Bring up the tips and tricks dialog.
 */
static void ShowCoolFeatures()
{
   // start the cool features dialog (have to do it this way
   // to avoid problems building state file when coolfeatures.e
   // isn't loaded yet.
   if (buildingStateFile) return;
   cool_index := find_index("cool_features",COMMAND_TYPE);
   if (cool_index && index_callable(cool_index)) {
      call_index("startup",cool_index);
   }
}

/**
 * Compiles (if necessary) and loads the Slick-C&reg; <i>module_name</i> given.
 *  
 * @param module     Slick-C&reg; module to build and load 
 * @param doLoad     (default true) load module into interpreter?
 *  
 * @return Returns 0 if successful.
 *
 * @appliesTo Edit_Window
 *
 * @categories File_Functions
 *
 */
int makeNload(_str module, bool doLoad=true, bool quiet=false)
{
   //say(_strip_filename(module,'P'));
   //say(nls('making:')' 'module);
   message(nls('making:')' 'module);
   if ( pos(' ',module) ) module='"'module'"';
   _make(module);
   process_make_rc(rc,module,quiet);

   // if we are in quiet mode, then things won't be stopped, so we 
   // need to check for that ourselves
   if (quiet && rc) return rc;

   if (!doLoad) return(0);
   _str filename=module;
   // Load needed a global variable since, defload and definit are executed
   // after the _load opcode completes.  We could change this if defload
   // and definit executed immediately.
   _loadrc= 0;
   _load(filename,'r');_config_modify_flags(CFGMODIFY_LOADMACRO);
   int status=_loadrc;
   if ( status ) {
      if ( substr(status,1,1)!='-' ) {
         status=1;
      }
     if (quiet) return status;

     _message_box(nls("Error loading module:")" ":+module:+".  "get_message(status));
     if ( find_index('st',COMMAND_TYPE) ) {
        status=1;
        stop();
     } else {
        _message_box("makeNload: module="module);
        exit(1);
     }
   }
   return(status);
}
/**
 * Used for saving and restoring location within a buffer.  DO NOT use
 * this function if you plan to modify the buffer before calling the
 * <b>restore_pos</b> function.  Use the <b>_save_pos2</b> function
 * instead.  Saves buffer location information into <i>p</i>.  Use the
 * <b>restore_pos</b> procedure to restore the location within a buffer.
 *
 * @see restore_pos
 * @see _save_pos2
 * @see _restore_pos2
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void save_pos(typeless &p, typeless useRealLineNumbers="")
{
   if (p_HasBuffer) {
      /*
         WARNING: DO NOT APPEND ANYTHING AFTER THE POINT() FUNCTION CALL.  The point() function
         sometimes returns two values and not one.
      */
      if (useRealLineNumbers != "") {
         p='r'p_RLine" "p_col " "p_hex_nibble" "p_cursor_y " "_WinGetLeftEdge(0,false)' 'p_LastModified' 'point();
      } else {
         p=point('l') " "p_col " "p_hex_nibble" "p_cursor_y " "_WinGetLeftEdge(0,false)' 'p_LastModified' 'point();
      }
      return;
   }
   _lbsave_pos(p);
}
/**
 * Restores buffer position saved by <b>save_pos</b> procedure.
 *
 * @see _restore_pos2
 * @see save_pos
 * @see _save_pos2
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void restore_pos(typeless p)
{
   if (p_HasBuffer) {
      typeless linenum,col,hex_nibble,cursor_y,left_edge,last_modify;
      parse p with linenum col hex_nibble cursor_y left_edge last_modify p;
      if ( substr(linenum,1,1)=='r' ) {  /* Use real line number? */
         p_RLine=(int)substr(linenum,2);
      } else {
         if ( p_LastModified != last_modify ) {
            goto_point(p,-1);
         } else {
            goto_point(p,linenum);
         }
      }
      p_col=col;p_hex_nibble=hex_nibble;
      set_scroll_pos(left_edge,cursor_y);
      return;
   }
   _lbrestore_pos(p);
}
/**
 * Displays string <i>msg</i> and waits for a key press.  Used when debugging
 * macros.  Press Ctrl+Break to halt a macro during a <b>messageNwait</b> or
 * <b>get_event</b> call.
 *
 * @categories Keyboard_Functions
 *
 */
void messageNwait(_str msg="")
{
   // since the refresh below may make the command line window active */
   // if the current window is the hidden window, save and restore the window. */
   old_wid := p_window_id;
   // IF this is an editor control
   _str k,event=last_event();
   if (p_HasBuffer) {
      // Doing refresh can change the current line if
      // we are in selective display
      save_pos(auto p);
      if (p_object!=OI_DESKTOP && p_active_form.p_enabled && p_active_form.p_visible) {
         refresh();
      }
      message(msg);
      k=get_event();
      restore_pos(p);
   } else {
      if (p_object!=OI_DESKTOP && p_active_form.p_enabled && p_active_form.p_visible) {
         refresh();
      }
      message(msg);
      k=get_event();
   }
   last_event(event);
   clear_message();
   p_window_id=old_wid;
   if (event2name(k)=='C-Break') {
      _message_box('Macro halted');
      stop();
   }
}
/**
 * Deletes the current window without prompting.  The buffer
 * attatched to the window is not deleted.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Window_Functions
 *
 */
_command void quit_view() name_info(','VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY)
{
  _delete_window();
}

/**
 * Get or set the configuration modification flags.
 * The AND mask is applied first, then the OR flags.
 * <ul>
 * <li>CFGMODIFY_ALLCFGFILES -- for backward compatibility.
 *                              New macros should use the constants below.
 * <li>CFGMODIFY_DEFVAR -- set macro variable with prefix "def_"
 * <li>CFGMODIFY_DEFDATA -- Not needed since v21
 * <li>CFGMODIFY_OPTION -- Not needed since v21
 * <li>CFGMODIFY_RESOURCE -- user FORM, BITMAP, MENU, BUTTON BAR, TOOL BAR
 * <li>CFGMODIFY_SYSRESOURCE -- system FORM, BITMAP, MENU, BUTTON BAR, TOOL BAR
 * <li>CFGMODIFY_LOADMACRO -- loaded a macro (except vusermacs.e)
 * <li>CFGMODIFY_LOADDLL -- loaded a DLL.
 * <li>CFGMODIFY_KEYS -- Modify keys
 * <li>CFGMODIFY_USERMACS -- vusrmacs was loaded.
 * <li>CFGMODIFY_MUSTSAVESTATE -- (CFGMODIFY_LOADMACRO|CFGMODIFY_LOADDLL)
 * <li>CFGMODIFY_DELRESOURCE -- resource is deleted.
 *                              This should be used with
 *                              CFGMODIFY_RESOURCE or CFGMODIFY_SYSRESOURCE.
 * </ul>
 *
 * @param or_flags      OR in these flags
 * @param and_mask      AND with this mask
 *
 * @return The new configuration modification flag set.
 *
 * @see list_config
 * @see save_config
 * @see gui_save_config
 */
int _config_modify_flags(int or_flags=0, int and_mask=0xffffffff)
{
   int orig_modify = _config_modify;
   _config_modify &= and_mask;
   _config_modify |= or_flags;

   //if (_config_modify != orig_modify) {
   //   say("_config_modify_flags: CONFIGURATION MODIFICATION FLAGS CHANGED!");
   //   _StackDump();
   //}

   return _config_modify;
}

/**
 * <p>You are prompted whether you wish to save the configuration changes.
 * Source code representing your configuration changes is saved in the files
 * "vusrdefs.e" (UNIX: "vunxdefs.e"), "vusrobjs.e" (UNIX: "vunxobjs.e"), and
 * "vusrs<i>NNN</i>.e" (UNIX: "vusrs<i>NNN</i>.e") where <i>NNN</i> is unique
 * characters for this version of SlickEdit.  The state file will be
 * saved to "vslick.sta" if you loaded new macro modules. When
 * the editor is invoked, the state file is loaded and then the
 * source code representing your configuration changes are
 * applied.</p>
 *
 * <p>The state file contains macro module(s), name table, dialog box
 * templates, bitmaps, event table(s), global/static variable value(s), and
 * editor options.  When the editor is invoked, it searches for the state file.
 * First the directory from which the editor was loaded is searched and then the
 * path directories are searched.  The editor will not search for a state file
 * if the editor is invoked with the '-x' option in the command line.</p>
 *
 * @return Returns 0 if successful.  Common return codes are:
 * <ul>
 * <li>COMMAND_CANCELLED_RC</li>
 * <li>ACCESS_DENIED_RC</li>
 * <li>ERROR_OPENING_FILE_RC</li>
 * <li>INSUFFICIENT_DISK_SPACE_RC</li>
 * <li>ERROR_READING_FILE_RC</li>
 * <li>ERROR_WRITING_FILE_RC</li>
 * <li>DRIVE_NOT_READY_RC</li>
 * <li>PATH_NOT_FOUND_RC</li>
 * </ul>
 *
 * <p>On error, message box displayed.</p>
 *
 * @see write_state
 * @see save_config
 *
 * @categories Miscellaneous_Functions
 *
 */
_command gui_save_config(_str save_immediate='') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   int status=_promptSaveConfig();
   if (status!=1) {
      return(status);
   }
   return(save_config(save_immediate));
}
int _promptSaveConfig() {
   msg := "Configuration Not Saved";
   // IF no user config mods AND no automatic config mods
   if (!_config_modify && !gcfgTransferModifyFlags && !_plugin_get_user_options_modify()) return(0);
   // If running from Eclipse we need more descriptive message because
   // user cannot tell what configuration we are talking about
   if (isEclipsePlugin()) {
      msg = 'SlickEdit Core 'msg;
   }

   // IF user modified the configuration.
   if (_config_modify || _plugin_get_user_options_modify()) {
      int result=prompt_for_save('Save configuration?',msg);
      if (result==IDCANCEL) {
         return(COMMAND_CANCELLED_RC);
      }
      if (result==IDNO) {
         return(0);
      }
   }
   return(1);
}

/**
 * Save config if necessary.
 *  
 * Do not check _plugin_get_user_options_modify(). That's because there are a 
 * number of places where the configuration is temporarily modified 
 * (force_wrap_line_len,display_flags). Best to rely on _config_modify_flags().
 */
void _maybe_save_config(bool AlwaysUpdate=false) 
{
   // Save config?
   if((def_exit_flags & (SAVE_CONFIG_IMMEDIATELY|SAVE_CONFIG_IMMEDIATELY_SHARE_CONFIG)) && 
      (_config_modify_flags() /*|| _plugin_get_user_options_modify()*/)) {
      /*if((def_exit_flags & (SAVE_CONFIG_IMMEDIATELY|SAVE_CONFIG_IMMEDIATELY_SHARE_CONFIG)) && !_config_modify_flags()) {
         say(_date()' '_time()' extra save');
      } */
      //say('saving config');
      save_config(1,false,true);
   }
}

/**
 * Updates source code representing your configuration changes.
 * Source code representing your configuration changes is saved in the
 * files "vusrdefs.e" (UNIX: "vunxdefs.e"), "vusrobjs.e" (UNIX:
 * "vunxobjs.e"), and "vusrs<I>NNN</I>.e" (UNIX:
 * "vunxs<I>NNN</I>.e").  The state file will be saved to "vslick.sta"
 * if you loaded new macro modules.  When the editor is invoked,
 * the state file is loaded and then the source code
 * representing your configuration changes are applied.
 *
 * @param save_immediate   0 if we are saving on exit, 1 if
 *                         we are just saving for funsies
 *
 * @return Returns 0 if successful.  Common return codes are:
 * COMMAND_CANCELLED_RC, ACCESS_DENIED_RC,
 * ERROR_OPENING_FILE_RC, INSUFFICIENT_DISK_SPACE_RC,
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC,
 * DRIVE_NOT_READY_RC, and PATH_NOT_FOUND_RC.  On
 * error, message box displayed.
 *
 * @see write_state
 * @see gui_save_config
 *
 * @categories Miscellaneous_Functions
 *
 */
_command int save_config(_str save_immediate='',bool ignore_errors=false,bool quiet=false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   cant_write_config_files := _default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
   if (cant_write_config_files) return(0);
   _update_profiles_for_modified_eventtabs();
   if (!_config_modify && !gcfgTransferModifyFlags && !_plugin_get_user_options_modify()) return(0);

   int old_config_modify=_config_modify;
   _config_modify|=gcfgTransferModifyFlags;
   int status=save_config2((save_immediate=='') ? true : (save_immediate == '1'),ignore_errors,quiet);
   if (status) {
      _config_modify=old_config_modify;
   } else {
      gcfgTransferModifyFlags=0;
   }
   return(status);
}

#if 1 /*__UNIX__*/
      struct DEFAULT_FONTS {
         _str sbcs_dbcs_source_window_font;
         _str hex_source_window_font;
         _str unicode_source_window_font;
         _str message_font;
         _str status_font;
         _str menu_font;
         _str dialog_font;
         _str mdichildicon_font;
         _str mdichildtitle_font;
         _str function_help_font;
         _str function_help_fixed_font;
         _str file_manager_window_font;
         _str diff_editor_window_font;
         _str minihtml_proportional_font;
         _str minihtml_fixed_font;
         _str unicode_diff_editor_window_font;
      };
int _usingXftFonts();
static void _saveDefaultFonts(DEFAULT_FONTS &df,bool &maybeRestoreFonts)
{
   maybeRestoreFonts=false;
   /*
            We are transfering the configuration
   */
   // If we are using XFT
   if (!_usingXftFonts()) return;
   maybeRestoreFonts=true;

   df.sbcs_dbcs_source_window_font=_default_font(CFG_SBCS_DBCS_SOURCE_WINDOW);
   df.hex_source_window_font=_default_font(CFG_HEX_SOURCE_WINDOW);
   df.unicode_source_window_font=_default_font(CFG_UNICODE_SOURCE_WINDOW);
   df.message_font=_default_font(CFG_MESSAGE);
   df.status_font=_default_font(CFG_STATUS);
   df.menu_font=_default_font(CFG_MENU);
   df.dialog_font=_default_font(CFG_DIALOG);
   df.mdichildicon_font=_default_font(CFG_MDICHILDICON);
   df.mdichildtitle_font=_default_font(CFG_MDICHILDTITLE);
   df.function_help_font=_default_font(CFG_FUNCTION_HELP);
   df.function_help_fixed_font=_default_font(CFG_FUNCTION_HELP_FIXED);
   df.file_manager_window_font=_default_font(CFG_FILE_MANAGER_WINDOW);
   df.diff_editor_window_font=_default_font(CFG_DIFF_EDITOR_WINDOW);
   df.minihtml_proportional_font=_default_font(CFG_MINIHTML_PROPORTIONAL);
   df.minihtml_fixed_font=_default_font(CFG_MINIHTML_FIXED);
   df.unicode_diff_editor_window_font=_default_font(CFG_UNICODE_DIFF_EDITOR_WINDOW);
}
static void _maybe_keep_default_font(int cfg, _str old_font)
{
   _str name,rest;
   parse _default_font(cfg) with name',' rest;
   if (strieq(name,"adobe-helvetica") ||
       strieq(name,"adobe-courier")
       || (!_isUnix() && strieq(name,"Courier New"))
       ) {
      //say('restored 'cfg' to 'old_font);
      _default_font(cfg,old_font);
   }
}
static void _maybeRestoreDefaultFonts(DEFAULT_FONTS &df,bool maybeRestoreFonts)
{
   if (!maybeRestoreFonts) {
      return;
   }

   _maybe_keep_default_font(CFG_SBCS_DBCS_SOURCE_WINDOW,df.sbcs_dbcs_source_window_font);
   _maybe_keep_default_font(CFG_HEX_SOURCE_WINDOW,df.hex_source_window_font);
   _maybe_keep_default_font(CFG_UNICODE_SOURCE_WINDOW,df.unicode_source_window_font);
   _maybe_keep_default_font(CFG_MESSAGE,df.message_font);
   _maybe_keep_default_font(CFG_STATUS,df.status_font);
   _maybe_keep_default_font(CFG_MENU,df.menu_font);
   _maybe_keep_default_font(CFG_DIALOG,df.dialog_font);
   _maybe_keep_default_font(CFG_MDICHILDICON,df.mdichildicon_font);
   _maybe_keep_default_font(CFG_MDICHILDTITLE,df.mdichildtitle_font);
   _maybe_keep_default_font(CFG_FUNCTION_HELP,df.function_help_font);
   _maybe_keep_default_font(CFG_FUNCTION_HELP_FIXED,df.function_help_fixed_font);
   _maybe_keep_default_font(CFG_FILE_MANAGER_WINDOW,df.file_manager_window_font);
   _maybe_keep_default_font(CFG_DIFF_EDITOR_WINDOW,df.diff_editor_window_font);
   _maybe_keep_default_font(CFG_MINIHTML_PROPORTIONAL,df.minihtml_proportional_font);
   _maybe_keep_default_font(CFG_MINIHTML_FIXED,df.minihtml_fixed_font);
   _maybe_keep_default_font(CFG_UNICODE_DIFF_EDITOR_WINDOW,df.unicode_diff_editor_window_font);
}
#endif

static void _CheckForObsoleteEnvironment()
{
   // back door for stubborn users
   if (!def_warn_about_vslickconfig) {
      return;
   }

   // check for VSLICKCLASSICCONFIG
   env_name := "VSLICKCLASSICCONFIG";
   config_dir := get_env(env_name);
   if (rc || config_dir == '') {
      env_name = '';
   }

   // check for VSLICKCONFIG
   if (env_name == '') {
      env_name = "VSLICKCONFIG";
      config_dir = get_env(env_name);
      if (rc || config_dir == '') {
         env_name = '';
      }
   }

   // no problems with environment
   if (env_name == '') {
      return;
   }

   // warn them about the obsolescense of their environment
   answer := _message_box("The "env_name" environment variable is no longer supported.":+
                          "\n\n":+
                          "If you wish to specify your configuration directory using an\n":+
                          "environment variable, please exit now and use SLICKEDITCONFIG.":+
                          "\n\n":+
                          "Otherwise, SlickEdit will use the following configuration directory:":+
                          "\n\n":+
                          _ConfigPath():+
                          "\n\n":+
                          "Continue anyway?",
                          "SlickEdit",
                          MB_YESNO|MB_ICONEXCLAMATION);

   // this is safe because we were in _firstinit()
   if (answer == IDNO) {
      fexit();
   }
}
static bool _macroLoadPermitted(_str filename) {
   if (_haveProMacros()) {
      return true;
   }
   name:=_strip_filename(filename,'P');
   if (substr(name,1,4):=='vunx' || 
       substr(name,1,4):=='vusr'
       ) {
      return true;
   }
   return false;
}

/**
 * Load the macros the user has specified in def_macfiles. 
 */
static void apply_user_macros(_str user_macfiles,bool &need_new_config_modification=false) 
{
   need_new_config_modification=false;
   if(!_default_option(VSOPTION_LOAD_PLUGINS)) {
      return;
   }
   if (!_haveProMacros()) {
      return;
   }
   // deal with duplicate modules in def_macfiles
   // this should not be possible, but no harm in guarding
   // against it so we do not incorrectly report it as
   // a module name conflict.
   bool been_there_done_that:[];

   // string containing a list of modules that errored out
   errorFiles := "";

   // for each module
   foreach (auto module in user_macfiles) {

      // no more modules?
      if (module=='') break;
      module = strip(module, "B", "\"");

      // get just the module name, no path
      module_name := _strip_filename(module,'P');

      if (!_macroLoadPermitted(module)) {
         continue;
      }

      // already saw this one?
      if (been_there_done_that._indexin(_file_case(module_name))) continue;
      been_there_done_that:[_file_case(module_name)] = true;

      // toss out delphi.ex
      if (_file_eq(module_name,'delphi.ex')) {
         continue;
      }
      // vcpp.e isn't needed any more.
      if (_file_eq(module_name,'vcpp.ex')) {
         continue;
      }

      // check if this module is already loaded, if it is, it means they
      // have a user module whose name conflicts with the name of a module
      // that we ship with SlickEdit. Do not allow them to load a module
      // with a name conflict.
      index := find_index(module_name,MODULE_TYPE|DLLMODULE_TYPE);
      if (index) {
         _macfile_delete(module_name,'');need_new_config_modification=true;
         /* Not sure how vusrmacs.ex is getting in def_macfiles but
            it is happenning. Note that vusrmacs<event> can also store
            recorded macros.
         */
         if (!beginsWith(module_name,USERMACS_FILE,false,_fpos_case) &&
             (def_oemaddons_modules == "" || pos(module_name,def_oemaddons_modules) == 0)) {
            errorFiles :+= "CONFLICT:\t" :+ module :+ "\n";
         }
         continue;
      }

      // get the file extension, should be either .ex, .dll, or .so (Unix) 
      filename := "";
      ext := _get_extension(module_name);

      // If this is a Slick-C macro
      if (_file_eq(ext,'ex')) {
         // look for the macro in paths defined in VSLICKMACROS first
         // NOTE: this is done to fix a problem when installing two versions of
         //       the editor in different places (conserving config during install).
         //       absolute paths in def_macfiles led to emulation and language macros
         //       from the previous install being loaded into the newer install.  by
         //       searching first for the macro in VSLICKMACROS, any newer macros
         //       will be found first and override the absolute path to the old install
         filename = _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
         if(filename == "") {
            // look for the macro source using the original source directory.
            filename=substr(module,1,length(module)-1);
            if (_isRelative(filename) || file_match('-p '_maybe_quote_filename(filename),1)=='') {
               filename=_ConfigPath():+substr(module,1,length(module));
               // look for the macro pcode using the original source directory.
               filename=file_match('-p '_maybe_quote_filename(filename),1);
            }
            if (filename=='') {
               filename=_ConfigPath():+substr(module,1,length(module)-1);
               if (file_match('-p '_maybe_quote_filename(filename),1)=='') {
                  filename=_ConfigPath():+substr(module,1,length(module));
                  filename=file_match('-p '_maybe_quote_filename(filename),1);
               }
               if (filename=='') {
                  filename=_macro_path_search(substr(module,1,length(module)-1));
                  if (filename=='') {
                     filename=_macro_path_search(substr(module,1,length(module)));
                  }
               }
            }
         }
      } else {
         // otherwise, assume it is a DLL
         filename = slick_path_search1(module);
         if (!_haveProMacros()) {
            // Standard version doesn't support custom DLLs
            continue;
         }
      }

      // now load the module or DLL
      if (filename!='') {
         // Use suspend/resume so that if a Slick-C stack happens,
         // we can pick up and load as many modules as possible.
         _suspend();
         if (!rc) {
            if (_file_eq(ext,'ex')) {
               // load the slick-c file, not the pcode
               if (_file_eq(get_extension(filename), 'ex')) {
                  filename = substr(filename,1,length(filename)-1);
               }

               if (load(filename) != 0) {
                  errorFiles :+= "COMPILE ERROR:\t" :+ filename :+ "\n";
                  _macfile_delete(module_name,'');need_new_config_modification=true;
               }
            } else {
               dload(filename);
            }
            rc=1;
            _resume();
         } else if (rc!=1) {
            errorFiles :+= "ERROR:\t" :+ filename :+ "\n";
            if (_file_eq(ext,'ex')) {
               // unload modules that error, otherwise they will error
               // again in their definit() and the editor will not
               // be able to come up.
               unload(_strip_filename(module_name,'P'), true);
            }
         }
      } else {
         // if the file is missing, then remove it from def_macfiles
         // and report that it is missing.
         _macfile_delete(module_name,'');need_new_config_modification=true;
         errorFiles :+= "MISSING:\t" :+ module :+ "\n";
      }
   }

   // report whatever errors occurred loading user macros
   if (errorFiles != "") {
      _message_box("There were errors loading the following user modules (from def_macfiles).\n\n":+errorFiles);
   }
}
void _convert_new_beautifier_profiles(_str vusr_filename='',_str langId='',_str profileName='') {
   do_recycle := false;
   if (vusr_filename=='') {
      vusr_filename=usercfg_path_search('vusr_beautifier.xml');
      do_recycle=true;
   }
   if (!file_exists(vusr_filename)) {
      return;
   }
   // Convert to the new .cfg.xml languages settings
   module := "convert_vusr_beautifier_xml.ex";
   filename := _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
   //_message_box('filename='filename);
   if (filename=='') {
      module='convert_vusr_beautifier_xml.e';
      filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
      //_message_box('h2 filename='filename);
      if (filename=='') {
         filename='convert_vusr_beautifier_xml';
      }
   }
   more_args := "";
   if (langId!='') {
      more_args=' 'langId;
      if (profileName!='') {
         more_args :+= ' ':+profileName;
      }
   }
   shell(_maybe_quote_filename(filename)' '_maybe_quote_filename(vusr_filename):+more_args);
   if (do_recycle) {
      recycle_file(_ConfigPath():+'vusr_beautifier.xml');
   }
}
static void add_ext_items(_str (&array)[],_str prefix,_str new_prefix,_str sortdata) {
   index:=name_match(prefix,1,MISC_TYPE);
   while (index) {
      parse name_name(index) with (prefix) auto ext;
      array[array._length()]=ext:+sortdata:+"\t":+new_prefix:+'-':+ext:+"\t":+name_info(index);

      //convertLangToXml(langId,index);
      index=name_match(prefix,0,MISC_TYPE);
   }
}
void _convert_names_table_ext_data_to_cfgxml() {
   _str array[];
   add_ext_items(array,'def-lang-for-ext-','langid','a');
   add_ext_items(array,'def-encoding-','encoding','b');
   add_ext_items(array,'def-association-','association','c');
   add_ext_items(array,'def-default-dtd-','default-dtd','d');
   if (array._length()) {
      array._sort();
      for (i:=0;i<array._length();++i) {
         parse array[i] with auto ext "\t" auto key "\t" auto value;
         if (substr(key,1,12)=='association-' && value=='0 ') {
            continue;
         }
         //say('key='key' value='value);
         _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_FILE_EXTENSIONS,VSCFGPROFILE_FILE_EXTENSIONS_VERSION,key,value);
      }
   }
}
void _MaybeUpgradeLanguageSetup(_str moduleLoaded="") {
  if (name_match('def-setup-',1,MISC_TYPE)>0 || name_match('def-language-',1,MISC_TYPE)>0) {
     module := "lang2cfgxml.ex";
     filename:= _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
     //_message_box('filename='filename);
     if (filename=='') {
        module='lang2cfgxml.e';
        filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
        //_message_box('h2 filename='filename);
        if (filename=='') {
           filename='lang2cfgxml';
        }
     }
     shell(_maybe_quote_filename(filename));
     // _convert_names_table_ext_data_to_cfgxml this gets done by lang2cfgxml.e
  } else {
     _convert_names_table_ext_data_to_cfgxml();
  }
}
static void _init_platform_vars() {
   initialize_def_vars := false;
   // IF we are building the state file
   if (_FILESEP=='') {
      initialize_def_vars=true;
   }
   if (_isWindows() || _isMac()) {
      _fpos_case="I";
      if (initialize_def_vars) {
         def_clipboard_formats="H";
      }
   } else {
      _fpos_case="";
      if (initialize_def_vars) {
         def_clipboard_formats="H";
      }
   }
   if (_isUnix()) {

      _FILESEP="/";
      _FILESEP2="\\";
      _PATHSEP=":";
      _COMMANDSEP=";";

      ALLFILES_RE='*';
      WILDCARD_CHARS='*?[]^\';

      DIR_ATTR_WIDTH=10;
      DIR_FILE_COL=(45+2*_dbcs());

      COMPILE_ERROR_FILE= "vserrors.tmp";

      if (initialize_def_vars) {
         def_autoclipboard=true;
         def_filelist_show_dotfiles=true;
         def_buffer_retag=2000;

         def_codehelp_key_idle=200;
         def_memberhelp_idle=400;
         def_update_tagging_idle=1000;
         def_update_tagging_extra_idle=500;
         def_no_error_info_commands2='vsbuild java ls echo cp mv rm mkdir rmdir cd diff find more sed set export setenv';
         def_error_info_commands='cc CC gcc g++ gcc-3 gcc-4 g++-3 g++-4 vst javc sgrep c89 c++ vscomp.rexx';
         def_resolve_dependency_symlinks=1;
         def_url_proxy="";
         def_url_proxy_bypass="";
         def_vim_change_cursor=false;
         def_use_word_help_url=false;
         def_unix_expansion=true;  // Expand ~ and $ like UNIX shells.
         def_debug_exe_extensions = EXE_FILE_RE;

      }

   } else {

      _FILESEP="\\";
      _FILESEP2="/";
      _PATHSEP=";";
      _COMMANDSEP="&";

      ALLFILES_RE='*.*';
      WILDCARD_CHARS='*?';

      DIR_ATTR_WIDTH=5;//    10
      DIR_FILE_COL=(40+2*_dbcs()); //  (45+2*_dbcs())

      COMPILE_ERROR_FILE="$errors.tmp";// "vserrors.tmp"

      if (initialize_def_vars) {
         def_autoclipboard=false;
         def_filelist_show_dotfiles=false;
         def_buffer_retag=2000;
         def_codehelp_key_idle=50;
         def_memberhelp_idle=50;
         def_update_tagging_idle=500;
         def_update_tagging_extra_idle=250;
         def_no_error_info_commands2='vsbuild java pkzip pkunzip unzip';
         def_error_info_commands='cl javac sj grep sgrep vst msdev';
         def_resolve_dependency_symlinks=0;
         def_url_proxy="IE;";
         def_url_proxy_bypass="";
         def_vim_change_cursor=true;
         def_use_word_help_url=true;
         def_unix_expansion=false;  // Expand ~ and $ like UNIX shells.
         def_debug_exe_extensions = EXE_FILE_RE;
      }

   }

   if (_isMac()) {
      if (initialize_def_vars) {
         def_autotag_flags2=AUTOTAG_ON_SAVE|AUTOTAG_BUFFERS|AUTOTAG_SYMBOLS|AUTOTAG_FILES_PROJECT_ONLY|AUTOTAG_CURRENT_CONTEXT|AUTOTAG_WORKSPACE_NO_ACTIVATE|AUTOTAG_ON_SWITCHBUF;
      }
   } else {
      if (initialize_def_vars) {
         def_autotag_flags2=AUTOTAG_ON_SAVE|AUTOTAG_BUFFERS|AUTOTAG_SYMBOLS|AUTOTAG_FILES_PROJECT_ONLY|AUTOTAG_CURRENT_CONTEXT|AUTOTAG_ON_SWITCHBUF;
      }
   }

}


/**
 * Did we migrate the configuration in _firstinit()?
 * Note that this will only be true for the session of the 
 * application that actually performed the migration. 
 *
 * @return true if config was migrated in this session.
 *
 * @see def_config_transfered_from_dir
 */
bool _configMigrated()
{
   return gConfigMigrated;
}

/**
 * Application theme (e.g. colors). To set a new theme, 
 * set <code>new_app_theme</code> to a valid theme name, or '' 
 * for the system theme. Otherwise leave it null (the default) 
 * to simply retrieve the current app theme. Set 
 * <code>force=true</code> to force theme change regardless 
 * whether current theme is already set to same. 
 * 
 * @param new_app_theme 
 * @param force 
 * 
 * @return Current app theme.
 *  
 * @deprecated use _app_theme_auto. This function is used for 
 *             importing configs prior to 2020 (v25).
 */
_str _app_theme(_str new_app_theme=null, bool force=false)
{
   _str app_theme = _default_option(VSOPTIONZ_APP_THEME);
   if ( new_app_theme != null 
        && (force || new_app_theme != app_theme || new_app_theme != g_toolbar_pic_theme) ) {
      //say('changing theme');
      // have to reset toolbar pic theme so that icons reload
      g_toolbar_pic_theme = "reset";
      _config_modify_flags(CFGMODIFY_DEFVAR);
      app_theme = _default_option(VSOPTIONZ_APP_THEME, new_app_theme);
   }
   return app_theme;
}

static bool _app_theme_changed(_str new_app_theme,bool &need_to_change_themes=false) {
   _str app_theme = _default_option(VSOPTIONZ_APP_THEME_AUTO);
   _str cmp_app_theme=_default_option(VSOPTIONZ_APP_THEME);
   _str cmp_new_app_theme=new_app_theme;
   if (strieq(cmp_new_app_theme,'automatic')) {
      cmp_new_app_theme=_GetAppThemeForOS();
   }
   need_to_change_themes=!strieq(cmp_new_app_theme, cmp_app_theme);
   return !strieq(new_app_theme,app_theme);
}
/**
 * Application theme (e.g. colors). To set a new theme, 
 * set <code>new_app_theme</code> to a valid theme name, or '' 
 * for the system theme. Otherwise leave it null (the default) 
 * to simply retrieve the current app theme. Set 
 * <code>force=true</code> to force theme change regardless 
 * whether current theme is already set to same. 
 * 
 * @param new_app_theme 
 * @param force 
 * 
 * @return Current app theme. 
 */
_str _app_theme_auto(_str new_app_theme=null,bool force=false) {
   _str app_theme = _default_option(VSOPTIONZ_APP_THEME_AUTO);
   bool need_to_change_themes;
   if ( new_app_theme != null && (force ||_app_theme_changed(new_app_theme,need_to_change_themes))) {
      if (force || need_to_change_themes) {
         //say('changing theme');
         // have to reset toolbar pic theme so that icons reload
         g_toolbar_pic_theme = "reset";
      }
      _config_modify_flags(CFGMODIFY_OPTION);
      app_theme = _default_option(VSOPTIONZ_APP_THEME_AUTO, new_app_theme);
   }
   return app_theme;
}
void _config_reload_app_theme() {
   //say('_config_reload_app_theme');
   // If current setting doesn't match what's in the state file.
   if (_default_option(VSOPTIONZ_APP_THEME)!=g_toolbar_pic_theme) {
      //say('theme changed');
      _app_theme_auto(_app_theme_auto(),true);
      if (index_callable(find_index('_before_write_state_toolbar_options',COMMAND_TYPE|PROC_TYPE))) {
         _before_write_state_toolbar_options();
      }
   } else if (def_toolbar_pic_style    != g_toolbar_pic_style     || 
              def_toolbar_pic_hsv_bias != g_toolbar_pic_hsv_bias  || 
              def_toolbar_pic_depth    != g_toolbar_pic_depth     || 
              def_toolbar_tree_pic_size!= g_toolbar_tree_pic_size || 
              def_toolbar_tab_pic_size != g_toolbar_tab_pic_size  || 
              def_toolbar_pic_size     != g_toolbar_pic_size) {
      // reload tool window bitmaps if the size has changed
      if (index_callable(find_index("tbReloadBitmaps", COMMAND_TYPE|PROC_TYPE))) {
         //say("_config_reload_app_theme: bitmap option changed");
         tbReloadBitmaps("","",reloadSVGFromDisk:false);
         tbReloadTabBitmaps("","",reloadSVGFromDisk:false);
         tbReloadTreeBitmaps("","",reloadSVGFromDisk:false);
         if (index_callable(find_index('_before_write_state_toolbar_options',COMMAND_TYPE|PROC_TYPE))) {
            _before_write_state_toolbar_options();
         }
      }
   } else {
      if (index_callable(find_index("tbReloadBitmaps", COMMAND_TYPE|PROC_TYPE))) {
         if (def_toolbar_pic_auto) tbReloadBitmaps("auto","",reloadSVGFromDisk:false);
      }
      if (index_callable(find_index("tbReloadTreeBitmaps", COMMAND_TYPE|PROC_TYPE))) {
         if (def_toolbar_tree_pic_auto) tbReloadTreeBitmaps("auto", "", reloadSVGFromDisk:false);
      }
      if (index_callable(find_index("tbReloadTabBitmaps", COMMAND_TYPE|PROC_TYPE))) {
         if (def_toolbar_tab_pic_auto) tbReloadTabBitmaps("auto", "", reloadSVGFromDisk:false);
      }
   }
}

void _firstinit()
{
   _config_file_dates._makeempty();
   gautocomplete_ContinueToFail=0;
   // Force access so this doesn't get deleted.
   def_git_pushpull_interactive=def_git_pushpull_interactive;
   // Must turn on pip later depending on def_pip_on
   _pip_on=false;
   gautorestore_monitor_configs=null;
   // Don't want this deleted when the statte file is written.
   //def_mffind_encoding=def_mffind_encoding;
   _allow_quick_start_wizard=true;
   _init_platform_vars();
   _selection_list_font='';
   // safe_exit sets _use_timers to 0 and if the state file is saved
   // we need to set it back to 1 here.
   _use_timers=1; 
   gin_restore=0;
   // Unfortunately, if transfer configuration in _firstinit(), _fileProjectSetCurrent may 
   // get called so we need to make sure that module is initialized here before it's called.
   if (index_callable(find_index('_fileProjectInit',PROC_TYPE))) {
      _fileProjectInit();
   }
   // This useless looking assignment ensures that this variable does not get removed
   // when writing the state file. p_copy_color_coding_to_clipboard_op references
   // this macro variable.
   def_max_html_clipboard_ksize=def_max_html_clipboard_ksize;
   // This is used by open_temp_view and must be initialized early
   _filepos_view_id=0;
   _per_file_data_init(_ConfigPath(), def_max_filepos);
   _SlickEditUtil_UpdateOptions();

   cant_write_config_files := _default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
   if (!cant_write_config_files) {
      _CheckForObsoleteEnvironment();
   }

   status := 0;
   old_default_config := "";
   new_default_config := "";

   gConfigMigrated = false;
   config_migrated_from_version := "";
   transfered_directory_major_ver := '0';
   if ( !cant_write_config_files ) {
      gConfigMigrated = _TransferCfgToNewDirectory(old_default_config, new_default_config);
      // attempt to compute the approximate release which the configuration
      // directory was migrated from.  For configuration directories lacking
      // a trailing version number, just assume 10.0.0, even though this could
      // be inaccurate for some very rare cases, such as someone who used
      // "-sc" with versions before 13.0.0.
      if (old_default_config != "") {
         last_filesep_pos := lastpos(FILESEP, old_default_config, length(old_default_config)-1);
         if (last_filesep_pos > 0) {
            config_migrated_from_version = substr(old_default_config, last_filesep_pos+1, length(old_default_config)-last_filesep_pos-1);
         }
         // If this is a standard config directory, remove the trailing -s
         if (length(config_migrated_from_version)>=2 && substr(config_migrated_from_version,length(config_migrated_from_version)-1,2)=="-s") {
            config_migrated_from_version=substr(config_migrated_from_version,1,length(config_migrated_from_version)-2);
         }
         if (pos("^[0-9]*[.][0-9]*[.][0-9]*$", config_migrated_from_version, 1, 'r') <= 0) {
            config_migrated_from_version = "10.0.0";
         }
      }
      if (gConfigMigrated && config_migrated_from_version!='') {
         _allow_quick_start_wizard=false;
         parse config_migrated_from_version with transfered_directory_major_ver '.';
      }
      if( gConfigMigrated ) {
         // Reload the user.cfg.xml that may have been transfered. This reloads all the local and system plugin .cfg.xml files
         if (gConfigMigrated && transfered_directory_major_ver<21 ) {
            // v20 already had a user.cfg.xml. If the file exists, do some translations on it here.
            update_v20_user_cfg_xml(transfered_directory_major_ver);
         }
         plugin_reload_user_config();
      }
   }
   if (_allow_quick_start_wizard 
       // Returns true if user.cfg.xml exists
       && _plugin_have_user_options()
       ) {
      _allow_quick_start_wizard=false;
   }
   _save_origenv();
   _project_name='';_project_DebugCallbackName='';_project_DebugConfig=false;
   _project_extTagFiles = ''; _project_extExtensions = '';
   _workspace_filename='';
   gActiveConfigName="";
   gActiveTargetDestination="";
   gWorkspaceHandle=-1;
   gProjectHashTab._makeempty();
   gxmlcfg_help_index_handle=0;


   _hit_defmain=false;
   gtag_filelist_cache_updated=false;
   // Force a reference to some variables so they get created
   // and are not removed.
   if (0) {  // YES WE WANT 0 HERE.
      // DONT EXECUTE ANYTHING HERE
      _compiler_default='';
   }
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_ONE_FILE_PER_WINDOW)) {
      def_one_file='+w';
   }
   gconfig_path="";
   _config_modify=0;gcfgTransferModifyFlags=0;
   path := "";
   statename := editor_name('s');
   if (statename!='') {
      //statepath=strip_filename(statename,'n');
      path=_ConfigPath();
   } else {
      _mdi._ShowWindow();  // Show window using OS argument
      _cmdline.p_visible=false;
   }

   // We do not want the command line to auto-select if it
   // loses and regains focus, for example when a symbol mouse-over
   // help window pops up even though it's using SW_SHOWNOACTIVATE.
   // To test this issue, go to the command line, type a partial command,
   // then move the mouse to cause a mouse-over help dialog to display.
   // Without this change, the text on the command line would wind up 
   // getting selected.
   _cmdline.p_auto_select=false;
   creating_state_file := statename=='';
   filename:='';

   filename_no_quotes:=_ConfigPath():+VSCFGFILE_USER;
   // IF file doesn't exist, _file_date returns 0 which has the same effect as null
   _config_file_dates:[_file_case(filename_no_quotes)]=_file_date(filename_no_quotes,'B');
   apply_local_state_file_changes2:=!creating_state_file && (!_default_option(VSOPTION_LOCALSTA) || 
          // Local state file is older than global state file
         (_default_option(VSOPTION_LOCALSTA) && _default_option(VSOPTION_APPLY_LOCAL_STATE_FILE_CHANGES))
       ) && !cant_write_config_files;

   // IF we are not creating a state file AND user wants cfg files
   //    AND need to apply local changes to state file
   if (apply_local_state_file_changes2 && def_cfgfiles) {
      _SplashScreenStatus("Migrating configuration settings...");

      if (!_isUnix()) {
         if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ECLIPSE_PLUGIN) {
            get_env(_VSECLIPSECONFIGVERSION);
         } else {
            get_env(_SLICKCONFIG);
         }
         status=rc;
         if (status) {
            path=_macro_path();
         }
      }


      DEFAULT_FONTS df;
      bool maybeRestoreFonts;
      if (_isUnix()) {
         _saveDefaultFonts(df,maybeRestoreFonts);
      }

      // Must run _getUserSysFileName() first so have correct button bar resource.
      // USERDEFS_FILES sets button bar.
      _in_firstinit=1;
      filename_no_quotes = path:+_getUserSysFileName():+_macro_ext;
      filename = _maybe_quote_filename(filename_no_quotes);
      usersyso_exists := false;
      if(file_exists(filename_no_quotes)) {
         _config_file_dates:[_file_case(filename_no_quotes)]=_file_date(filename_no_quotes,'B');
         status=shell(filename);
         //messageNwait('status h2='status);
         usersyso_exists=true;
      } else { 
         _config_file_dates:[_file_case(filename_no_quotes)]=null;
      }
      _no_mdi_bind_all=true;
      int old_modify=_config_modify;
      if (gConfigMigrated && transfered_directory_major_ver<21 ) {
         /* 
             It's best to switch to the users emulation before applying their
             changes. We also need the alt_menu_setting to correctly set
             up the key bindings before applying the users changes.

             These changes were really to fix key bindings and nothing else:

             MAC
                 Initial emulation is macOS which has a binding for Command+F

             Users configuration is say:  CUA with Alt menu hot keys turned on.
             This means that he has a binding for Command + F which needs to be 
             removed because userdefs and userkeys DON'T REMOVE KEYS!.

             Here we take care of that.
         */
         _str alt_menu_setting;
         get_users_emulation_and_switch_to_it(path,alt_menu_setting);

         if(alt_menu_setting!=null) {
            def_alt_menu= alt_menu_setting;
            macro:='altsetup';
            filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext'x');
            if (filename=='') {
               filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext);
            }
            if (filename=='') {
               _message_box("File '%s' not found",macro:+_macro_ext'x');
            } else {
               status=shell(macro' 'number2yesno(def_alt_menu));
               if (status) {
                  _message_box(nls("Unable to set alt menu hotkeys.\n\nError probably caused by missing macro compiler or incorrect macro compiler version."));
               }
            }
         }

         filename=_maybe_quote_filename(path:+USERDEFS_FILE:+_macro_ext);
         if(file_match('-p 'filename,1)!='' ) {

            dataFilename := _maybe_quote_filename(path:+USERDATA_FILE:+_macro_ext);
            if (file_match('-p 'dataFilename,1) == '') {
               // If the user does not have a vusrdata file, split vusrdefs up
               // into a vusrdefs and vusrdata file.
               splitDataFile(filename,dataFilename);
            }

            _str vuserdefs_filename=filename;
            status=shell(filename);
            if (!status) {
               index:=find_index('def_color_scheme_version',VAR_TYPE);
               if (index>0) {
                  color_scheme_version:=_get_var(index);
                  if (isinteger(color_scheme_version)) {
                     if (color_scheme_version == COLOR_SCHEME_VERSION_DEFAULT) {
                        if (substr(config_migrated_from_version, 1, 2) == "14") {
                           _set_var(index, COLOR_SCHEME_VERSION_CURRENT);
                        } else {
                           _set_var(index, COLOR_SCHEME_VERSION_PREHISTORIC);
                        }
                     }
                  }
               }
            }
            vuserdefs_filename=strip(vuserdefs_filename,'B','"');
            recycle_file(vuserdefs_filename);
            recycle_file(vuserdefs_filename'x');
         }

         vusrdata_filename := "";
         filename=_maybe_quote_filename(path:+USERDATA_FILE:+_macro_ext);
         if (file_match('-p 'filename,1) != '') {
            vusrdata_filename=filename;
            shell(vusrdata_filename);
            vusrdata_filename=strip(vusrdata_filename,'B','"');
            recycle_file(vusrdata_filename);
            recycle_file(vusrdata_filename'x');
         }
         if (gConfigMigrated) {
            vusrkeys_filename := "";
            filename=_maybe_quote_filename(path:+USERKEYS_FILE:+_macro_ext);
            if (file_match('-p 'filename,1) != '' ) {
               vusrkeys_filename=filename;
               shell(vusrkeys_filename);
               vusrkeys_filename=strip(vusrkeys_filename,'B','"');
               recycle_file(vusrkeys_filename);
               recycle_file(vusrkeys_filename'x');
            }
         }
         _update_profiles_for_modified_eventtabs();
      }

      // make sure we know to write a new config after exiting this time
      gcfgTransferModifyFlags |= CFGMODIFY_DEFVAR|CFGMODIFY_KEYS;

      _config_modify = old_modify;
      _no_mdi_bind_all=false;
      filename_no_quotes = path:+USERMACS_FILE:+_macro_ext;
      filename = _maybe_quote_filename(filename_no_quotes);

      if(file_exists(filename_no_quotes)) {
         _config_file_dates:[_file_case(filename_no_quotes)]=_file_date(filename_no_quotes,'B');
         _reload_usermacs(filename_no_quotes);
      } else { 
         _config_file_dates:[_file_case(filename_no_quotes)]=null;
      }
      // Load all user add macro files and DLLs
      kt_index := find_index('default_keys',EVENTTAB_TYPE);

      // Notify call-list about event table changes
      call_list('_eventtab_modify_',kt_index,'');

      filename_no_quotes=path:+USEROBJS_FILE:+_macro_ext;
      filename=_maybe_quote_filename(filename_no_quotes);
      if(file_exists(filename_no_quotes)) {
         _config_file_dates:[_file_case(filename_no_quotes)]=_file_date(filename_no_quotes,'B');
         if(_default_option(VSOPTION_LOAD_PLUGINS)) {
            // update icons to match latest version of editor
            shell("updateobjs ":+filename);

            // now run vusrobjs
            status=shell(filename);
         }
         //messageNwait('status h2='status);
      } else { 
         _config_file_dates:[_file_case(filename_no_quotes)]=null;
      }

      if (isEclipsePlugin()) {
         _str r = _getSlickEditInstallPath();
         if (r != '') {
            _str r_t = _maybe_unquote_filename(r);
            bmr :=  r_t :+ VSE_BITMAPS_DIR;
            if (!(r_t :== r)) {
               bmr = _maybe_quote_filename(bmr);
            }
            set_env("VSLICKBITMAPS",bmr);
         }
      }

      if (_default_option(VSOPTION_LOCALSTA)) {
         // We are transfer configuration from a previous version.
         menu_mdi_bind_all();
         _CfgTransferDone();
         gcfgTransferModifyFlags|=CFGMODIFY_SYSRESOURCE|CFGMODIFY_MUSTSAVESTATE;
      } else if (!usersyso_exists){
         // We must transfer menu bindings to this new version of
         // the editor.  This will cause a _getUserSysFileName() to be
         // generated with the _mdi_menu resource.
         menu_mdi_bind_all();
         gcfgTransferModifyFlags|=CFGMODIFY_SYSRESOURCE;
      }

      _in_firstinit=0;
      //_UpdateKeyBindings();
      if (_isUnix()) {
         if (old_default_config!='') {
            _maybeRestoreDefaultFonts(df,maybeRestoreFonts);
         }
      }
#if 0
      // reload tool window bitmaps if the size has changed
      if (index_callable(find_index("tbReloadBitmaps", COMMAND_TYPE|PROC_TYPE))) {
         tbReloadBitmaps();
         tbReloadTabBitmaps();
         tbReloadTreeBitmaps();
      }
#endif

      // we need to do this before calling apply_user_macros - it may get called 
      // again later, but that's no big deal
      if(gConfigMigrated) {
         change_def_macfiles_location(old_default_config, new_default_config);
      }

      // new state file means it is also time to update, that is, rebuild, slickc.vtg
      slickc_tagfile := _tagfiles_path();
      _maybe_append_filesep(slickc_tagfile);
      slickc_tagfile :+= TAG_BASENAME;
      if (file_exists(slickc_tagfile)) {
         delete_file(slickc_tagfile);
      }

      /* 
         _post_call seem kind of wierd. If a message box occurs AFTER
         calling _post_call here, then the post call in DoPostInstall()
         gets executed first. When the state file is saved before
         user macros are loaded, all key bindings are lost.

         The fix is to load the macros in DoPostIntall() instead.
      */ 
      //_post_call(apply_user_macros, def_macfiles);
      if (!gConfigMigrated && !_default_option(VSOPTION_LOCALSTA)) {
         _config_modify=0;gcfgTransferModifyFlags=0;
      }
   } else {
      filename_no_quotes=path:+USEROBJS_FILE:+_macro_ext;
      _config_file_dates:[_file_case(filename_no_quotes)]=_file_date(filename_no_quotes,'B');

      filename_no_quotes = path:+USERMACS_FILE:+_macro_ext;
      if (!def_cfgfiles && apply_local_state_file_changes2) {
         if (_config_file_changed(filename_no_quotes)) {
            //say('apply 'filename_no_quotes);
            _reload_usermacs(filename_no_quotes);
         }
      } else {
         _config_file_dates:[_file_case(filename_no_quotes)]=_file_date(filename_no_quotes,'B');
      }

      if (index_callable(find_index('_getUserSysFileName',PROC_TYPE))) {
         filename_no_quotes = path:+_getUserSysFileName():+_macro_ext;
         _config_file_dates:[_file_case(filename_no_quotes)]=_file_date(filename_no_quotes,'B');
      }
   }
   if (gConfigMigrated) {
      // Move old lastmac*.e files into vusrmacs.e
      _in_firstinit=1;
      filePattern := _ConfigPath() :+ "lastmac*.e";
      filePath:=file_match('-p '_maybe_quote_filename(filePattern),1);
      while (filePath!='') {
         _importUserMacroFile(filePath);
         recycle_file(filePath);
         filePath = file_match("-p "_maybe_quote_filename(filePattern), 0);
      }
      _in_firstinit=0;
   }
   // Apply the event table profiles if we are not building the state file or transfering
   // an old config
   if (editor_name('s')!='' && (!gConfigMigrated || transfered_directory_major_ver>=21 )) {
      _plugin_eventtab_apply_all_bindings();
   }

   if( def_focus_select && def_cde_workaround && _isSolaris() ) {
      // Problem on Solaris running CDE causes some keys (Left arrow)
      // not to work when this option is on.
      def_focus_select=false;
   }

   // if their old symbol browser maximums were adjusted higher
   // than the new, higher defaults, then use their size
   if (def_cb_low_refresh > def_cbrowser_low_refresh) {
      def_cbrowser_low_refresh = def_cb_low_refresh;
   }
   if (def_cb_high_refresh > def_cbrowser_high_refresh) {
      def_cbrowser_high_refresh = def_cb_high_refresh;
   }
   if (def_cb_flood_refresh > def_cbrowser_flood_refresh) {
      def_cbrowser_flood_refresh = def_cb_flood_refresh;
   }

   // do not let the tagging cache be set to anything less than 8M
   if (def_tagging_cache_ksize < 8000) {
      def_tagging_cache_ksize = 8000;
   }

   // if their old tag file cache size is larger than the new tag file cache maximum
   // make the maximum match their existing setting
   if (def_tagging_cache_max_ksize < def_tagging_cache_ksize) {
      def_tagging_cache_max_ksize = def_tagging_cache_ksize;
   }

   // turn on memory mapped files
   if (gConfigMigrated && transfered_directory_major_ver<21 ) {
      def_tagging_use_memory_mapped_files = true;
   }

   // turn off background tagging if they set the number of threads to 0
   if (def_background_tagging_threads == 0) {
      def_autotag_flags2 |= AUTOTAG_DISABLE_ALL_THREADS;
   }

   // increase default for selective display max level
   if (def_seldisp_maxlevel <= 6) {
      def_seldisp_maxlevel = 25;
   }

   // 6.4.09 - 10770 - sg- we no longer use the New Project Wizard
   def_launch_new_project_wizard = false;

   // We set this to zero because store transfer config flags in gcfgTransferModifyFlags
   // Added option to automatically escape regex tokens for search text with init current word, selection options
   if ( config_migrated_from_version != '' && _version_compare(config_migrated_from_version, '20.0.1.0') <= 0 ) {
      def_mfsearch_init_flags |= MFSEARCH_INIT_AUTO_ESCAPE_REGEX;
   }

   // Make def_toolbar_pic_size a simple integer instead of Width x Height
   parse def_toolbar_pic_size with def_toolbar_pic_size 'x' .;
   if (def_toolbar_pic_size == "") def_toolbar_pic_size=24;

   // Can remove this when can safely switch app_theme while SlickEdit is running.
   if (_isMac()) {
      _in_firstinit=1;
      _config_reload_app_theme();
      _in_firstinit=0;
   } else {
      _config_reload_app_theme();
   }

   _config_modify=0;
   filename = "";
   _str new_lang=_default_option(VSOPTIONZ_LANG);
   if (_last_lang!=new_lang) {
      path=_getSlickEditInstallPath():+'macros':+FILESEP;
      if (new_lang=='') {
         filename=path:+SYSOBJS_FILE:+".e";
      } else {
         filename=path:+SYSOBJS_FILE'_'new_lang:+".e";
      }
      if(file_exists(filename)) {
         status=shell('"'filename'"');
         if (status) {
            _message_box(nls("Failed to execute '%s'.\n\n",filename):+get_message(status));
         }
      } else {
         _message_box(nls("File '%s' not found",filename));
      }
      _last_lang=new_lang;
      _config_modify_flags(CFGMODIFY_MUSTSAVESTATE);
   }
   gMissingDllList='';
   binPath := get_env('VSLICKBIN1');
   dllPath := binPath:+'vsdebug.dll';
   if ( !file_exists(dllPath) ) {
      gMissingDllList :+= ' vsdebug.dll';

      dllPath=binPath:+'vchack.dll';
      if ( !file_exists(dllPath) ) {
         gMissingDllList :+= ' vchack.dll';
      }
   }
   dllPath=binPath:+'vsrefactor.dll';
   if ( !file_exists(dllPath) ) {
      gMissingDllList :+= ' vsrefactor.dll';
   }

   if ( gConfigMigrated ) {
      change_ext_tagfiles_location(old_default_config, new_default_config);
      change_def_macfiles_location(old_default_config, new_default_config);

      // save the old config dir - do it here so the def-var is not overwritten by vusrdefs.
      def_config_transfered_from_dir = old_default_config;

      // IF we have a state file
      if (statename!='') {
         // We've already run vusrdefs which may have def_notification_actions
         module := "convert2cfgxml.ex";
         filename = _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
         //_message_box('filename='filename);
         if (filename=='') {
            module='convert2cfgxml.e';
            filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
            //_message_box('h2 filename='filename);
            if (filename=='') {
               filename='convert2cfgxml';
            }
         }
         status=shell(_maybe_quote_filename(filename)' 'config_migrated_from_version);
      }
      // clear out old sample workspaces and add absolute project
      upgrade_workspace_manager(transfered_directory_major_ver);
      _convert_names_table_ext_data_to_cfgxml();
   }

   // start up the pip, and maybe do a send on startup
   if (index_callable(find_index("_hotfix_startup", PROC_TYPE))) {
      _post_call(_hotfix_startup);
   }

   //Remove any unprocessed shutdown.xml file
   shutdownFile := _ConfigPath():+"shutdown.xml";
   if (file_exists(shutdownFile)) {
      delete_file(shutdownFile);
   }

   // up-front work is done, idle time counter starts now
   _reset_idle();

}

static void get_users_emulation_and_switch_to_it(_str path,_str &alt_menu_setting) {
   called_emulate_macro := false;
   alt_menu_setting=null;
   filename := _maybe_quote_filename(path:+USERDEFS_FILE:+_macro_ext);
   //say(filename);
   int status=_open_temp_view(filename,auto temp_wid,auto orig_wid);
   if (!status) {
      status=search('^defmain\(\)','@r');
      //say('h1 status='status);
      if (!status) {
         status=search('^[ \t]*def_keys[ \t]*=','@r');
         //say('h2 status='status);
         if (!status) {
            get_line(auto line);
            //say('h3 status='status);
            //parse line with line '[''"]','r';
            has_dash_keys := pos('-keys',line)!=0;
            parse line with '[''"]','r' auto name '-keys';
            //say('name='name);
            if (name=='' || !has_dash_keys) {
               name='slick';
            } else if (name=='gnuemacs') {
               name='gnu';
            }
            if (name!=(_isMac()?'macosx':'windows') ) {
               module := "emulate.ex";
               filename = _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
               //_message_box('filename='filename);
               if (filename=='') {
                  module='emulate.e';
                  filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
                  //_message_box('h2 filename='filename);
                  if (filename=='') {
                     filename='emulate';
                  }
               }
               status=shell(_maybe_quote_filename(filename)' 'name);
               //_message_box('status='status);
               if (status) {
                  _message_box(nls('unable to switch to %s1 emulation',name));
               } else {
                  called_emulate_macro=true;
               }
            }
         }
      }
      top();
      status=search('^defmain\(\)','@r');
      //say('h1 status='status);
      if (!status) {
         status=search('^[ \t]*def_alt_menu[ \t]*=','@r');
         if (!status) {
            get_line(auto line);
            parse line with '=' alt_menu_setting ';';
            alt_menu_setting=strip(alt_menu_setting);
            alt_menu_setting=strip(alt_menu_setting,'B','"');
            alt_menu_setting=strip(alt_menu_setting,'B',"'");
         }
      }

      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
   }
   if (!called_emulate_macro) {
      _set_emulation_key_bindings();
   }
}
static void splitDataFile(_str vusrdefsFilename,_str vusrdataFilename)
{
   // Copy vusrdefs to vusrdata
   status := copy_file(vusrdefsFilename,vusrdataFilename);
   if ( !status ) {
      status = _open_temp_view(vusrdataFilename,auto tempWID,auto origWID,"",true,false,true);
      if ( !status ) {
         // Select from the top to the marker and delete it.
         markid := _alloc_selection();
         top();_select_line(markid);
         status = search('^//MARKER','@r');
         if ( !status ) {
            _select_line(markid);
            _delete_selection(markid);
         } else {
            _deselect(markid);
         }
         status = search('^  replace_def_data\(','@rxcs');
         if ( !status ) {
            // Select from the first replace_def_data to the line before the
            // close brace at the bottom and delete it.
            _select_line(markid);
            status = search('^\}','@r');
            up();
            _select_line(markid);
            _delete_selection(markid);
         }
         status = _save_file('+o '_maybe_quote_filename(vusrdataFilename));
         _delete_temp_view(tempWID);
         _free_selection(markid);
      }
      status = _open_temp_view(vusrdefsFilename,tempWID,origWID,"",true,false,true);
      if ( !status ) {
         markid := _alloc_selection();
         status = search('^defmain()','@rxcs');
         if ( !status ) {
            // Select from defmain to the first replace_def_data and delete it.
            down(); // Skip {
            down();
            _select_line(markid);
            status = search('^  replace_def_data\(','@rxcs');
            if ( !status ) {
               up();
               _select_line(markid);
               _delete_selection(markid);
            }
         }
         status = _save_file('+o '_maybe_quote_filename(vusrdefsFilename));
         _delete_temp_view(tempWID);
         _free_selection(markid);
      }
   }
}

definit()
{
   gAutoRestoreFinished=true;
   buildingStateFile=(arg(1)=='L');
   gconfig_path="";
   _macro_ext=get_env("VSLICKEXT");
   if (_macro_ext=="") {
      _macro_ext=".e";
   }
}
static _str option_present(var option,_str cmdline,_str word_options)
{
   for (;;) {
      parse word_options with option word_options ;
      if ( option=='' ) {
         return(0);
      }
      int len;
      if (isalpha(substr(cmdline,1,1))) {
         len=pos(' ',cmdline)-1;
      } else {
         len=1;
      }
      if (len<0) len=length(cmdline);
      if ( strieq(option,substr(cmdline,1,len)) ) {
         return(1);
      }
   }

}
int _DefaultUndoSteps()
{
   if ( pos('\+u(\:{:i}|)',def_load_options,'','ri') ) {
      /* Set default undo steps for temp buffer. */
      typeless undo_steps=substr(def_load_options,pos('s0'),pos('0'));
      if ( undo_steps=='' ) {
         undo_steps=300;
      }
      return(undo_steps);
   }
   return(0);
}
static void doExecList(_str (&ExecList)[])
{
   int i;
   for (i=0;i<ExecList._length();++i) {
      execute(ExecList[i],"");
   }
}

void maybe_warn_oem()
{
   _str matches[];
   regex := '^(suffix-?@|-?@-bufname2ext|-?@-Filename2LangId)$';

   index := name_match('', 1, PROC_TYPE);
   while (index > 0) {
      // get the name
      name := name_name(index);

      // does it match our pattern?
      if (pos(regex, name, 1, 'R') == 1) {
         matches[matches._length()] = name;
      }

      // get the next one
      index = name_match('', 0, PROC_TYPE);
   }

}

/**
 * @return int return non-zero if auto-restore has completed
 */
bool _autoRestoreFinished()
{
   return gAutoRestoreFinished;
}

/** 
 * Called by defmain when we want to activate the open projects 
 * window because the user specified a directory and created a 
 * new workspace. Have to use _post_call to get focus set 
 * correctly. 
 */
static void activateTBProjects()
{
   formWID := tw_find_form('_tbprojects_form');
   if ( formWID ) {
      fid := activate_tool_window('_tbprojects_form',true,'_proj_tooltab_tree');
      if (fid) {
         origWID := p_window_id;
         _nocheck _control _proj_tooltab_tree;
         p_window_id = fid._proj_tooltab_tree;

         workspaceIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         // Get index for workspace
         if ( workspaceIndex>=0 ) {
            // Get index for project
            projectIndex := _TreeGetFirstChildIndex(workspaceIndex);
            if ( projectIndex>=0 ) {
               // Expand project index, have to call event manually
               _TreeGetInfo(projectIndex,auto state);
               _TreeSetInfo(projectIndex,1);
               call_event(CHANGE_EXPANDED,projectIndex,_proj_tooltab_tree,ON_CHANGE, 'W');

               // Get source folder index
               sourceIndex := _TreeGetFirstChildIndex(projectIndex);
               if ( sourceIndex>=0 ) {
                  // Expand source index, have to call event manually
                  _TreeGetInfo(sourceIndex, state);
                  _TreeSetInfo(sourceIndex,1);
                  call_event(CHANGE_EXPANDED,sourceIndex,_proj_tooltab_tree,ON_CHANGE, 'W');

                  // Find first file index, set focus to it
                  firstFileIndex := _TreeGetFirstChildIndex(sourceIndex);
                  if ( firstFileIndex>=0 ) {
                     _TreeSetCurIndex(firstFileIndex);
                  }
               }
            }
         }

         p_window_id = origWID;
      }
   }
}

bool _is_workspace_filename(_str filename) {
   workspace_file_ext:=_get_extension(filename,true);
   return _file_eq(workspace_file_ext,PRJ_FILE_EXT) ||
       _file_eq(workspace_file_ext,WORKSPACE_FILE_EXT) ||
       _file_eq(workspace_file_ext,'.xcodeproj') || _file_eq(workspace_file_ext,'.xcode') || 
       _file_eq(_strip_filename(filename,'P'),'Cargo.toml') || 
       _file_eq(workspace_file_ext, VCPP_PROJECT_WORKSPACE_EXT) ||
      _file_eq(workspace_file_ext, TORNADO_WORKSPACE_EXT) ||
      _file_eq(workspace_file_ext, VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT) ||
      _file_eq(workspace_file_ext, XCODE_PROJECT_EXT) ||
      _file_eq(workspace_file_ext, XCODE_PROJECT_LONG_BUNDLE_EXT) ||
      _file_eq(workspace_file_ext, XCODE_PROJECT_SHORT_BUNDLE_EXT) ||
      _file_eq(workspace_file_ext, XCODE_WKSPACE_BUNDLE_EXT) ||
      _file_eq(workspace_file_ext, VISUAL_STUDIO_SOLUTION_EXT) ||
      _file_eq(workspace_file_ext, JBUILDER_PROJECT_EXT) ||
      _file_eq(workspace_file_ext, MACROMEDIA_FLASH_PROJECT_EXT);
}
extern bool _lazy_workspace_spec(_str &filename);
static const DEFMAIN_OPTIONS= 'H R P # SUT FN MDIHIDE';
defmain()
{
   _str orig_def_macfiles=def_macfiles;
   cant_write_config_files := _default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
   _setup_jaws_mode();
   _hit_defmain=true;
   gAutoRestoreFinished = false;
   /*
      Here we call dllinit functions.  These dllinit functions
      must be called before autorestore.
   */
   call_list("dllinit_");
   if(_default_option(VSOPTION_LOAD_PLUGINS)) {
      _plugin_load_all();
   }

   if (!cant_write_config_files) {
      /* make sure the local configuration directory is created. */
      _str local_dir=_tagfiles_path();
      if ( ! isdirectory(local_dir) ) {
         int status=make_path(local_dir,'0');  /* Give no shell messages options. */
         if ( status ) {  /* Error trying to create path. */
            popup_message(nls('Unable to create configuration directory "%s"',local_dir)'.  'get_message(status));
         }
      }
   
      // Create the user templates directory since the documentation discusses it
      local_dir=_ctGetUserItemTemplatesDir();
      if( ! isdirectory(local_dir) ) {
         // '0'=No shell messages options
         int status = make_path(local_dir,'0');
         if( status!=0 ) {
            // Error creating directory
            popup_message(nls('Unable to create configuration directory "%s"',local_dir)'.  'get_message(status));
         }
      }
   }

   _in_firstinit=0;
   _str orig_cwd=getcwd();
   p_window_id=_edit_window();
#if !_MDI_INTERFACE
   if ( p_buf_name=='' && def_keys=='emacs-keys' ) {
      p_buf_name='.main';
   }
   p_undo_steps=_DefaultUndoSteps();
#endif
  _str cmdline=arg(1);

  // Save a copy in global variable.
  // This is used by:
  // * Trial macro (vstrial.e) to determine if we are in the middle of post-install.
  _editor_cmdline=cmdline;

  st_batch_mode=0;
  macro_program := "";
  terminal_file_spec := "";
  bool dont_restore_workspace=false;
  _str restore_options;
  if (_default_option(VSOPTION_NEW_OPTION)==2) {
     dont_restore_workspace=true;
     restore_options="IN";
  } else {
     if (def_auto_restore) {
        restore_options="I";
     } else {
        restore_options="IN";
     }
  }
  _str restore_options2 = restore_options;
  mdi_menu_loaded := false;
  _project_name="";_project_DebugCallbackName="";_project_DebugConfig=false;
  _project_extTagFiles = ""; _project_extExtensions = "";
  _workspace_filename="";
  _str ExecList[];
  _str option;
  _str filename;
  mdihide := false;
  no_exit := false;
  do_workspace_opened_calllist := true;
  if (_isMac()) {
     // Strip off the -psn_X_YYYYYY process serial # argument
     // We don't want it showing up as an edit command in the 
     // command history
     cmdline = stranslate(cmdline, '', '[^\-]\-psn[0-9_]+', "L");
  }
  workspaceToOpen := '';
  for (;;) {
     cmdline=strip(cmdline,'L');
     if ( substr(cmdline,1,1)=='"' && substr(cmdline,2,1)=='-' &&
        option_present(option,substr(cmdline,3),DEFMAIN_OPTIONS)
        ) {
        cmdline=substr(cmdline,2,length(option)+1):+'"'strip(substr(cmdline,length(option)+3),'L');
     }
     if ( substr(cmdline,1,1)!='-' ) {
        if ( cmdline=='' && macro_program=='') {
           cmdline='-r restore ':+restore_options;
        } else {
           /*if (!mdi_menu_loaded) {
              mdi_menu_loaded=true;
              _load_mdi_menu();
           } */
           _str temp=cmdline;
           filename=strip(parse_file(temp),"B",'"');
           if (_is_workspace_filename(filename) || _lazy_workspace_spec(filename)) {
              workspaceToOpen = filename;
              // save this to open later - we need to wait until the toolbars are up and running
              dont_restore_workspace=true;

              // workspace_open does the "_workspace_opened_" call list
              // so we don't need to do it again below.
              do_workspace_opened_calllist=false;
              //workspace_open(filename,"","I");
              // IF we are restoring files in project
              if (def_restore_flags & RF_PROJECTFILES) {
                 // Don't restore files or project name
                 restore_options2=restore_options="IGN";
              } else {
                 // Unfortunately, since the editor used the wrong
                 // MDI frame size, we don't restore files/windows here.
                 // We can probably correct this in version 3.0
                 // Don't restore files or project name.
                 restore_options2=restore_options="IGN";
              }
              cmdline=temp;
              continue;
           }
           break;
        }
     }
     /* Not an invocation option? */
     if ( substr(cmdline,1,1)!='-' ||
        ! option_present(option,substr(cmdline,2),DEFMAIN_OPTIONS) ) {
        break;
     }
     cmdline=substr(cmdline,length(option)+2);
     if ( option=='H') {
        _help_file_spec=parse_file(cmdline);
     } else if ( option=='R' ) {
        no_exit=true;
        macro_program=cmdline;
        break;
     } else if ( option=='P' ) {
        no_exit=false;
        macro_program=cmdline;
        break;
     } else if ( option=='#' ) {
        rest := strip(parse_file(cmdline),'B','"');
        ExecList[ExecList._length()]=rest;
     } else if (option=='FN') {
        break;
     } else if (option=='MDIHIDE') {
        //4:48pm 4/20/1998
        //Dan Added for hidden mdi startup support.
        //Do not show mdi
        mdihide=true;
        _default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS,SW_HIDE);
     }
  }
  if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_MENUS)) {
     _cur_mdi_menu="";
  }
  // If we are NOT building the state file.
  if (editor_name('s')!='') {
     // checkout a license and/or display licensing dialog.
     _LicenseInit();
  }
  if (!mdi_menu_loaded && !mdihide) {
     _load_mdi_menu();
  }

  // Set Closable MDI document tabs before we autorestore everything
  if ( !mdihide ) {
     _mdi.p_ClosableTabs = def_document_tabs_closable;
  }
  /* Load user macros BEFORE doing auto-restore. That way,
     we can auto-restore a custom tool window (todo.e).
  */
  _maybe_load_user_macros(orig_def_macfiles);
  focus_wid := 0;
  if ( macro_program!='' ) {
     /* Running SLICK inside build window? */
     //if ( no_exit && get_env('SLKRUNS')==1 ) {
     //   /* Get out of here. */
     //   exit(1)
     //}
     if ( ! no_exit ) {
        st_batch_mode=1;
     }
     _str cmdname;
     parse macro_program with cmdname .;
     typeless execute_status=0;
     if (cmdname!='restore') {
        // No files are restore here.
        if (!mdihide) {
           if (dont_restore_workspace) {
              orig:=def_restore_flags;
              def_restore_flags &= ~RF_WORKSPACE;
              restore(restore_options2);
              def_restore_flags=orig;
           } else {
              restore(restore_options2);
           }
        }
        if (macro_program=="lmw") {
           /*if (editor_name('s')!='') {
              // checkout a license and/or display licensing dialog.
              _LicenseInit();
              say('af3');
           } */
        } else {
           execute(macro_program,"");
           execute_status=rc;
        }
     } else {
        if (!mdihide) {
           gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_DISABLE;
           if (dont_restore_workspace) {
              orig:=def_restore_flags;
              def_restore_flags &= ~RF_WORKSPACE;
              execute(macro_program,"");
              def_restore_flags=orig;
           } else {
              execute(macro_program,"");
           }
           execute_status=rc;
           gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_ENABLE;
        }
     }

     // now that we've restored everything else, open the workspace specified
     if (workspaceToOpen != '') {
        workspace_open(_maybe_quote_filename(workspaceToOpen),"","I");
     }
     doExecList(ExecList);
     /*if (index_callable(find_index('_restore_all_bookmarks',PROC_TYPE))) {
        _restore_all_bookmarks();
     } */

     st_batch_mode=0;
     if ( !isinteger(execute_status) ) { execute_status=0; }
     if ( no_exit ) {
        if ( def_start_on_cmdline ) {
           cursor_command();
        }
        DoPostInstall(orig_def_macfiles,mdihide);

        if (_workspace_filename!='' && do_workspace_opened_calllist) {
           focus_wid = _get_focus();
           call_list('_prjopen_',false);
           if (focus_wid) focus_wid._set_focus();

           call_list('_workspace_opened_');
        }
        gAutoRestoreFinished = true;
        if (mdihide) {
           exit(execute_status);
        }
        // Do this AFTER auto-restore so gPipLastSendDate is initialized
        if (index_callable(find_index("_pip_startup", PROC_TYPE))) {
           _post_call(_pip_startup);
        }
        stop();
     }
     DoPostInstall(orig_def_macfiles,true);
     exit(execute_status);
  }
  _str dirList[];
  _getDirectoryListFromCmdline(cmdline,dirList);
  _str invocationDirectory='';
  bool directoryWasLast=false;
  if (dirList._length()) {
     invocationDirectory=dirList[0];
     //directoryWasLast=true;
  }
  /* insert the user's command into the command retrieve file.*/
  if ( dirList._length()) {

     origDefRestoreFlags := def_restore_flags;
     def_restore_flags &= ~RF_WORKSPACE;
     restore(restore_options2,0,null,RH_NO_RESTORE_FILES);
     def_restore_flags = origDefRestoreFlags;

     new_cwd:=getcwd();
     chdir(orig_cwd,1);
     orig_wkspace:=_workspace_filename;
     project_add_directory_folder(dirList);
     if (orig_wkspace!=_workspace_filename) {
        new_cwd=getcwd();
     } else {
        chdir(new_cwd,1);
     }

     if (cmdline!='' ) {
        chdir(orig_cwd,1);
        edit(cmdline,EDIT_DEFAULT_FLAGS);
        chdir(new_cwd,1);
     }
     
     gAutoRestoreFinished = true;
  } else {
     if (dont_restore_workspace) {
        orig:=def_restore_flags;
        def_restore_flags &= ~RF_WORKSPACE;
        restore(restore_options2);
        def_restore_flags=orig;
     } else {
        restore(restore_options2);
     }
     gAutoRestoreFinished = true;

     append_retrieve_command('e 'strip(cmdline));

     // now that we've restored everything else, open the workspace specified
     if (workspaceToOpen != '') {
        _SplashScreenStatus("Opening workspace: "_strip_filename(workspaceToOpen,'P'));
        workspace_open(_maybe_quote_filename(workspaceToOpen),"","I");
     }

     doExecList(ExecList);
#if _MDI_INTERFACE
     if (cmdline!='' ) {
        new_cwd := getcwd();
        chdir(orig_cwd,1);
        edit(cmdline,EDIT_DEFAULT_FLAGS);
        chdir(new_cwd,1);
     }
#else
     empty_file_buf_id=p_buf_id;
     if (cmdline!='' ) {
        new_cwd := getcwd();
        chdir(orig_cwd,1);
        edit(cmdline,EDIT_DEFAULT_FLAGS);
        chdir(new_cwd,1);
     }
     /* Get fileid of empty file in the top ring already create by E */
     /* if user has selected file(s) to edit get rid of the empty file. */
     if ( empty_file_buf_id!=p_buf_id ) {   /* Any files loaded? */
        /* quit empty file */
        buf_id=p_buf_id;
        load_files '+bi 'empty_file_buf_id;
        quit();
        /* activate the last loaded file. */
        load_files '+bi 'buf_id;
     } else {
        _SetEditorLanguage();
     }
#endif
  }
  if ( def_start_on_cmdline ) {
     cursor_command();
  }
  if (_workspace_filename!='' && do_workspace_opened_calllist) {
     focus_wid = _get_focus();
     call_list('_prjopen_',false);
     if (focus_wid) focus_wid._set_focus();

     call_list('_workspace_opened_');
  }
  gAutoRestoreFinished = true;

  /* Running SLICK inside build window? */
  //if ( get_env('SLKRUNS')==1 ) {
  //   /* Get out of here. */
  //   exit(1)
  //}
  /*if (index_callable(find_index('_restore_all_bookmarks',PROC_TYPE))) {
     _restore_all_bookmarks();
  } */

  DoPostInstall(orig_def_macfiles);
  // Do this AFTER auto-restore so gPipLastSendDate is initialized
  if (index_callable(find_index("_pip_startup", PROC_TYPE))) {
     _post_call(_pip_startup);
  }
}
void _project_directory_post_options() {
   flags:=_default_option(VSOPTION_DIR_PROJECT_FLAGS);
   if ( flags & DIRPROJFLAG_OPTION_ACTIVE_OPEN_TOOL_WINDOW) {
      _post_call(activate_open);
   } else if ( flags & DIRPROJFLAG_OPTION_ACTIVE_PROJECTS_TOOL_WINDOW) {
      _post_call(activateTBProjects);
   }
}

/**
 * Get an invocation directory from the command line, if one 
 * exists. 
 * 
 * @param cmdline list of files and directories(real options 
 *                parsed off).  Directories are removed from the
 *                list.
 * @param directoryWasLast set to true if a directory was the 
 *                         last thing in <B>cmdline</B>
 * 
 * @return _str last directory specified in <B>cmdline</B>
 */
void _getDirectoryListFromCmdline(_str &cmdline,_str (&dirList)[])
{
   dirList._makeempty();
   justFilesCmdline := "";
   for (;;) {
      curDir := parse_file(cmdline,false);
      if ( curDir=="" ) break;
      //if ( lastDir!="" ) directoryWasLast = false;
      if ( substr(curDir,1,2):!='-#' && (isdirectory(curDir,"",false) || _last_char(curDir)==FILESEP) ) {
         _maybe_append_filesep(curDir);
         dirList:+=curDir;
      } else {
         justFilesCmdline :+= ' '_maybe_quote_filename(curDir);
      }
   }
   cmdline = justFilesCmdline;
   //_maybe_append_filesep(lastDir);
}

/**
 * <p>Processes error codes during rebuild of the state file.
 * <i>error_code</i> is either a negative number corresponding to one of
 * the error constants in "rc.sh" or 1 which indicates error is from the
 * Slick-C&reg; translator trying to compile the file <i>module_name</i>.
 * <i>module_name</i> is the name of the file during which the error
 * occurred.</p>
 *
 * <p>When a compilation error occurs and the st command has not been
 * loaded, a message is displayed and the editor is exited.  Otherwise, a
 * message is displayed and the editor remains resident.</p>
 *
 * @categories Miscellaneous_Functions
 *
 */
void process_make_rc(_str error_code,_str module, bool quiet = false)
{
  if ( error_code ) {
     /* messageNwait('error_code='error_code' module='module) */
    index := find_index('st',COMMAND_TYPE);
    if ( error_code==FILE_NOT_FOUND_RC ) {
       if ( !quiet ) _message_box(nls("Can't find module:")" ":+module);
       rc=2;
       if ( !quiet ) stop(); 
    } else {
      if ( error_code==1  ) {  /* rc from Slick Translator? */
         if ( ! index && !quiet ) {  /* message already displayed by st command? */
            _message_box(nls("Error compiling or loading:")" ":+module:+".  Compilation failure.");
         }
      } else {
        if ( index ) {
           refresh();
        }
        if ( !quiet ) _message_box(nls("Error compiling or loading:")" ":+module:+".  "get_message((int)error_code));
      }
      if ( index ) { 
         rc=2;
         if (!quiet) stop(); 
      } else {
         exit(1);
      }
    }
  }
}
//def a_5=fexit


/**
 * Exits the editor without saving files or doing anything.  This command is
 * mainly useful to a macro hacker and the developers of SlickEdit.  You
 * might want to use this function to test our AutoSave feature.
 *
 * @see safe_exit
 * @categories Miscellaneous_Functions
 */
_command void fexit()
{
   // If were started as part of the eclipse plug-in then
   // we do not want to allow fexit
   //
   if (index_callable(find_index("isEclipsePlugin"))) {
      if (isEclipsePlugin()) {
         message("fexit not allowed from WebSphere Studio or Eclipse");
         return;
      }
   }

   if ( index_callable(find_index("delphiIsRunning",PROC_TYPE)) ) {
      if ( delphiIsRunning() ) {
         delphi_stop(1);
      }
   }
   // Kill process buffer and child processes
   _process_info('Q');
   //9:36am 7/2/1998
   //This frees the handle to vsscc.dll that is loaded by vshlp.dll in
   //_InsertProjectFileList.
   //If this doesn't happen, the editor crashes on exit w/o any debug info
   //(Not even a cancel button)
   if (_haveVersionControl() && machine()=='WINDOWS' && index_callable(find_index('_FreeSccDll',PROC_TYPE))) {
      _FreeSccDll();
   }
   exit(1);

   // This is a strange place to put this, but we need these assignments so
   // write_state doesn't delete them. (def_backup*fix are used in C code only,
   // but users should be able to set them -- strange case!)
   def_backupprefix = def_backupprefix;
   def_backupinfix = def_backupinfix;
   def_backuppostfix = def_backuppostfix;
}

/**
 * @return  Returns the directory used to store miscellaneous configuration
 * files such as "vslick.sta" and "user.cfg.xml".
 * 
 * @param options   (optional, UNIX only) set to 'n' 
 *                  pre-6.0 style config dir.  This option
 *                  is essentially obsolete at this point.
 *
 * @see restore_path
 * @see _create_config_path
 * @see _macro_path
 *
 * @categories File_Functions 
 * @deprecated Use {@link _ConfigPath()}. 
 */
_str _config_path(_str options="")
{
   if (options=="") {
      if (gconfig_path!="") {
         return(gconfig_path);
      }
      gconfig_path=_ConfigPath();
      return(gconfig_path);
   }
   return(_ConfigPath());
}
static void _CfgTransferDone()
{
   _default_option(VSOPTION_MACRO_SOURCE_LEVEL,1);
}
/**
 * <p>Used for searching for SlickEdit executables, Slick-C&reg; macros,
 * help files, and miscellaneous SlickEdit files.  The second and
 * optional parameter specifies a program and batch macro search.
 * Search order is as follows:</p>
 *
 * <p>  Try path given with <i>filename</i><br>
 * Non-UNIX platforms:  Try current directory.<br>
 * Try paths specified in VSLICKPATH environment
 * variable.<br>
 * Try paths specified in PATH environment variable.</p>
 *
 * @return If successful, a complete file specification for filename is returned.
 * Otherwise '' is returned.
 *
 * @see path_search
 * @see include_search
 *
 * @categories File_Functions
 *
 */
_str slick_path_search(_str name, _str options="")
{
   new_name := "";
   if ( get_env(_SLICKPATH)!='' ) {
      new_name=path_search(name,_SLICKPATH,options);
   }
   if ( new_name=='' ) {
      new_name=path_search(name,'PATH',options);
   }
   return(new_name);
}
_str slick_path_search1(_str name, _str options="")
{
   new_name := "";
   if ( get_env(_SLICKPATH)!='' ) {
      new_name=path_search(name,_SLICKPATH,options);
   }
   return(new_name);
}
_str usercfg_init_write(_str name,_str subdir='')
{
   if (pathlen(name)) {
      return(absolute(name));
   }
   _maybe_append_filesep(subdir);
   filename := usercfg_path_search(name,subdir);
   new_user_file := _ConfigPath():+subdir:+name;
   if (!_file_eq(filename,new_user_file)) {
      // Backup the previous local configuration file.
      copy_file(new_user_file,new_user_file'.bak');
      // Overwrite the local config file with the global user config file
      copy_file(filename,new_user_file);
   }
   return(new_user_file);
}
/*
  None of our customers are making use of migrating system configuration
  changes to users.  Eventually we should put all our system configuration
  data in "sysconfig" and allow this directory to be overridden or to have
  a second directory to look in.
*/
_str usercfg_path_search(_str name,_str subdir='')
{
   if (name=='') return('');
   if (pathlen(name)) {
      return(absolute(name));
   }
   _maybe_append_filesep(subdir);
   typeless global_date=0;
   global_filename := "";
   vslickmisc := strip(get_env('VSLICKMISC'),'B',PATHSEP);
   if (!pos(PATHSEP,vslickmisc)) {
      global_filename=vslickmisc;
      _maybe_append_filesep(global_filename);
      global_filename :+= subdir:+name;
      global_date=_file_date(global_filename,'B');
      if (global_date=='' || global_date==0) {
         global_filename='';
      }
   } else {
      global_filename=path_search(subdir:+name,_SLICKMISC,'s');
   }

   _str local_filename=_ConfigPath():+subdir:+name;
   _str local_date=_file_date(local_filename,'B');

   if (file_exists(local_filename)) {
      return(local_filename);
   }
   return(global_filename);
}
_str misc_path_search(_str name, _str options="")
{
   if ( get_env(_SLICKMISC)=='' ) {
      return(slick_path_search1(name,options));
   }
   _str filename=path_search(name,_SLICKMISC,'s'options);
   if (filename=='' && _file_eq(_get_extension(name),'hlp')) {
      filename=slick_path_search1(name,options);
   }
   return(filename);
}
_str bitmap_path_search(_str name, _str options="")
{
   if ( get_env("VSLICKBITMAPS")=='' ) {
      return(slick_path_search1(name,options));
   }
   _str filename=path_search(name,"VSLICKBITMAPS",'s'options);
   return(filename);
}

/**
 * Attempts to find a file in the macros directory structure.
 * 
 * @param name 
 * @param options 
 * 
 * @return _str 
 *  
 * @categories File_Functions 
 *  
 * @deprecated Use {@link _macro_path_search()}
 */
_str macro_path_search(_str name, _str options="")
{
   return _macro_path_search(name, options);
}

_str file_match2(_str filename,int findfirst,_str options)
{
   filename=strip(filename,'B',"'");
   filename=strip(filename,'B','"');
   return(file_match(_maybe_quote_filename(filename)' 'options,findfirst));
}
// Now in vsapi.dll
#if 0
bool file_exists(_str filename)
{
   filename=strip(filename,'B','"');
   return(file_match(_maybe_quote_filename(filename)' -p', 1)!='');
}
#endif

bool file_or_buffer_exists(_str filename)
{
   filename=strip(filename,'B','"');
   return(buf_match(filename,1,'E')!='' || file_exists(filename));
}

void _get_auto_generated_tagfile_names(_str (&list)[])
{
   list._makeempty();
   list :+= "ada":+TAG_FILE_EXT;
   list :+= "ansisql":+TAG_FILE_EXT;
   list :+= "asm390":+TAG_FILE_EXT;
   list :+= "bas":+TAG_FILE_EXT;
   list :+= "bbc":+TAG_FILE_EXT;
   list :+= "cics":+TAG_FILE_EXT;
   list :+= "cfml":+TAG_FILE_EXT;
   list :+= "cfscript":+TAG_FILE_EXT;
   list :+= "cobol":+TAG_FILE_EXT;
   list :+= "cpp":+TAG_FILE_EXT;
   list :+= "csproj":+TAG_FILE_EXT;
   list :+= "css":+TAG_FILE_EXT;
   list :+= "d":+TAG_FILE_EXT;
   list :+= "db2":+TAG_FILE_EXT;
   list :+= "docbook":+TAG_FILE_EXT;
   list :+= "dotnet":+TAG_FILE_EXT;
   list :+= "googlego":+TAG_FILE_EXT;
   list :+= "groovy":+TAG_FILE_EXT;
   list :+= "haskell":+TAG_FILE_EXT;
   list :+= "html":+TAG_FILE_EXT;
   list :+= "idl":+TAG_FILE_EXT;
   list :+= "java":+TAG_FILE_EXT;
   list :+= "javascript":+TAG_FILE_EXT;
   list :+= "js":+TAG_FILE_EXT;
   list :+= "jsharp":+TAG_FILE_EXT;
   list :+= "jsp":+TAG_FILE_EXT;
   list :+= "lua":+TAG_FILE_EXT;
   list :+= "matlab":+TAG_FILE_EXT;
   list :+= "m4":+TAG_FILE_EXT;
   list :+= "model204":+TAG_FILE_EXT;
   list :+= "npasm":+TAG_FILE_EXT;
   list :+= "omgidl":+TAG_FILE_EXT;
   list :+= "pascal":+TAG_FILE_EXT;
   list :+= "perl":+TAG_FILE_EXT;
   list :+= "php":+TAG_FILE_EXT;
   list :+= "phpscript":+TAG_FILE_EXT;
   list :+= "plsql":+TAG_FILE_EXT;
   list :+= "powershell":+TAG_FILE_EXT;
   list :+= "pro":+TAG_FILE_EXT;
   list :+= "python":+TAG_FILE_EXT;
   list :+= "qml":+TAG_FILE_EXT;
   list :+= "rexx":+TAG_FILE_EXT;
   list :+= "ruby":+TAG_FILE_EXT;
   list :+= "rultags":+TAG_FILE_EXT;
   list :+= "rust":+TAG_FILE_EXT;
   list :+= "sabl":+TAG_FILE_EXT;
   list :+= "sas":+TAG_FILE_EXT;
   list :+= "scala":+TAG_FILE_EXT;
   list :+= "seq":+TAG_FILE_EXT;
   list :+= "slickc":+TAG_FILE_EXT;
   list :+= "sqlserver":+TAG_FILE_EXT;
   list :+= "swift":+TAG_FILE_EXT;
   list :+= "systemverilog":+TAG_FILE_EXT;
   list :+= "tcl":+TAG_FILE_EXT;
   list :+= "tld":+TAG_FILE_EXT;
   list :+= "tornado":+TAG_FILE_EXT;
   list :+= "ttcn3":+TAG_FILE_EXT;
   list :+= "ufrmwk":+TAG_FILE_EXT;
   list :+= "uslickc":+TAG_FILE_EXT;
   list :+= "unity":+TAG_FILE_EXT;
   list :+= "vera":+TAG_FILE_EXT;
   list :+= "verilog":+TAG_FILE_EXT;
   list :+= "vhdl":+TAG_FILE_EXT;
   list :+= "vbscript":+TAG_FILE_EXT;
   list :+= "vcproj":+TAG_FILE_EXT;
   list :+= "xml":+TAG_FILE_EXT;
   list :+= "xhmtl":+TAG_FILE_EXT;
   list :+= "xmldoc":+TAG_FILE_EXT;
   list :+= "xsd":+TAG_FILE_EXT;
   list :+= "xsl":+TAG_FILE_EXT;
}
bool isTagFileAutoGenerated(_str tagFilename)
{
   // get paths to VSROOT, tagfiles directory, and old tagfiles directory
   vsroot := _getSlickEditInstallPath();
   _maybe_append_filesep(vsroot);
   tagfiles := _tagfiles_path();
   _maybe_append_filesep(tagfiles);

   // split the tagfile into parts
   path := _strip_filename(tagFilename, "N");
   _maybe_append_filesep(path);

   // if it's not the right path, then it's definitely not auto-generated
   if (!_file_eq(vsroot, path) && !_file_eq(tagfiles, path)) return false;

   // now see if the name matches one of our auto-gen files
   name := _strip_filename(tagFilename, 'P');

   _str list[];
   _get_auto_generated_tagfile_names(list);

   for (i := 0; i < list._length(); i++) {
      if (_file_eq(list[i], name)) return true;
   }

   return false;
}

static void fixupMacBindings()
{
   // Mac Shift+Cmd+W must call 'quit' rather than 'close_buffer'.
   // Note that if key is currently bound to something other than
   // 'close_buffer', or is unbound, then leave it alone because
   // the user intentionally bound/unbound it.
   kt_index := find_index('default_keys', EVENTTAB_TYPE);
   int old_cmd = eventtab_index(kt_index, kt_index, event2index(name2event('S-M-W')));
   if( old_cmd != 0 && name_name(old_cmd) == 'close_buffer' ) {
      set_eventtab_index(kt_index, event2index(name2event('S-M-W')), find_index('quit', COMMAND_TYPE));
   }
}
static void fixupContextTaggingBindings()
{
   /* Mac keyboard generates special characters with option keys. Someone did complain
      about A-digit keys not working. Best not to take these over either. We can change
      this if we get complaints on Mac in macOS emulation.
   */ 
   // We must have this for epsilon emulation.
   // Go ahead and do it for any configuration,
   // if several users complain, we can change this.
   if (machine()!='MACOSX') {
      kt_index := find_index("default_keys",EVENTTAB_TYPE);
      set_eventtab_index(kt_index,event2index(name2event('A-.')),find_index('list_symbols',COMMAND_TYPE));
      set_eventtab_index(kt_index,event2index(name2event('A-,')),find_index('function_argument_help',COMMAND_TYPE));
   }

   set_eventtab_index(_default_keys,event2index(name2event('M- ')),0);
}

void fixupVimBindings()
{
   // Adding 12.0.2 Vim visual key bindings for users upgrading
   vis_index := find_index("vi_visual_keys",EVENTTAB_TYPE);
   if (vis_index) {
      set_eventtab_index(vis_index,event2index(name2event('^')),find_index('vi_visual_begin_line',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('(')),find_index('vi_visual_prev_sentence',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event(')')),find_index('vi_visual_next_sentence',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('{')),find_index('vi_visual_prev_paragraph',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('}')),find_index('vi_visual_next_paragraph',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('[')),find_index('vi_open_bracket_cmd',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event(']')),find_index('vi_closed_bracket_cmd',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('%')),find_index('vi_find_matching_paren',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('<')),find_index('vi_visual_shift_left',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('>')),find_index('vi_visual_shift_right',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event(':')),find_index('vi_visual_ex_mode',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('*')),find_index('vi_quick_search',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('#')),find_index('vi_quick_reverse_search',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('=')),find_index('beautify_selection',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('b')),find_index('vi_visual_prev_word',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('B')),find_index('vi_visual_prev_word2',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('e')),find_index('vi_visual_end_word',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('E')),find_index('vi_visual_end_word2',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('g')),find_index('vi_maybe_text_motion',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('G')),find_index('vi_goto_line',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('i')),find_index('vi_visual_i_cmd',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('n')),find_index('ex_repeat_search',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('N')),find_index('ex_reverse_repeat_search',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('w')),find_index('vi_visual_next_word',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('W')),find_index('vi_visual_next_word2',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('HOME')),find_index('vi_visual_begin_line',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('C-R')),find_index('vi_visual_maybe_command',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('"')),find_index('vi_cb_name',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('a')),find_index('vi_visual_a_cmd',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('I')),find_index('vi_visual_insert_mode',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('q')),find_index('vi_record_kbdmacro',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('@')),find_index('vi_execute_kbdmacro',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('C-R')),find_index('vi_redo',COMMAND_TYPE));
   }

   // Adding 12.0.2 Vim command key bindings for users upgrading
   com_index := find_index("vi_command_keys",EVENTTAB_TYPE);
   if (com_index) {
      set_eventtab_index(com_index,event2index(name2event('*')),find_index('vi_quick_search',COMMAND_TYPE));
      set_eventtab_index(com_index,event2index(name2event('#')),find_index('vi_quick_reverse_search',COMMAND_TYPE));
      set_eventtab_index(com_index,event2index(name2event('=')),find_index('vi_format',COMMAND_TYPE));
      set_eventtab_index(com_index,event2index(name2event('q')),find_index('vi_record_kbdmacro',COMMAND_TYPE));
      set_eventtab_index(com_index,event2index(name2event('@')),find_index('vi_execute_kbdmacro',COMMAND_TYPE));
      set_eventtab_index(com_index,event2index(name2event('C-R')),find_index('vi_redo',COMMAND_TYPE));
   }

   if (def_keys == 'vi-keys') {
      //set_eventtab_index(_default_keys,event2index(name2event('F5')),
      //                   find_index('project_debug',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F5')),
                         find_index('debug_stop',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F5')),
                         find_index('debug_restart',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('F9')),
      //                   find_index('debug_toggle_breakpoint',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('C-F9')),
      //                   find_index('debug_toggle_breakpoint_enabled',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F9')),
                         find_index('debug_clear_all_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('A-F9')),
                         find_index('debug_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F10')),
                         find_index('debug_step_over',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F10')),
                         find_index('debug_run_to_cursor',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F11')),
                         find_index('debug_step_into',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F11')),
                         find_index('debug_step_out',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F8')),
                         find_index('next_doc',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F8')),
                         find_index('prev_doc',COMMAND_TYPE));
      def_one_file='+w';
      _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
      _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_EVENLY);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}
static void fixupEclipseBindings()
{
   if (!isEclipsePlugin()) {
      return;
   }
   // Use this spot for setting Eclipse specific key bindings
   index := find_index("default_keys",EVENTTAB_TYPE);
   set_eventtab_index(index,event2index(name2event('C-PGUP')),0);
   set_eventtab_index(index,event2index(name2event('C-PGDN')),0);
}

static void _UpdateKeys()
{
   /*
      As of v21, the def_keys_version variable has been removed. 
      The version of the profile should be used instead. If
      we are migrating an old config, def_keys_version
      will exist and we can use for this upgrade.
   */
   index:=find_index('def_keys_version',VAR_TYPE);
   if (!index) return;
   version:=_get_var(index);
   if (version>=3) return;
   _config_modify_flags(CFGMODIFY_KEYS);
   _config_modify_flags(CFGMODIFY_DEFVAR);
   if (version>=2) {
      vis_index := find_index("vi_visual_keys",EVENTTAB_TYPE);
      if (vis_index) {
         set_eventtab_index(vis_index,event2index(name2event('!')),find_index('vi_visual_filter',COMMAND_TYPE));
      }

      // Notify call-list about event table changes
      call_list('_eventtab_modify_',_default_keys,'');
      _set_var(index,3);
      return;
   }
   _set_var(index,3);

#if 0
   // Removed due to concern about the assumptions here.
   // update alt-menu key bindings for A_B
#if USE_B_FOR_BUILD
   if (def_alt_menu) {
      set_eventtab_index(_default_keys,event2index(A_B),0);
   }
#endif
#endif

   // update debugger key bindings
   switch (def_keys) {
   case 'windows-keys':
      set_eventtab_index(_default_keys,event2index(name2event('F5')),
                         find_index('project_debug',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F5')),
                         find_index('debug_stop',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F5')),
                         find_index('debug_restart',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F9')),
                         find_index('debug_toggle_breakpoint',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F9')),
                         find_index('debug_toggle_breakpoint_enabled',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F9')),
                         find_index('debug_clear_all_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('A-F9')),
                         find_index('debug_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F10')),
                         find_index('debug_step_over',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F10')),
                         find_index('debug_run_to_cursor',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F11')),
                         find_index('debug_step_into',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F11')),
                         find_index('debug_step_out',COMMAND_TYPE));
      break;
   case '':
      //set_eventtab_index(_default_keys,event2index(name2event('F5')),
      //                   find_index('project_debug',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F5')),
                         find_index('debug_stop',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F5')),
                         find_index('debug_restart',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('F9')),
      //                   find_index('debug_toggle_breakpoint',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('C-F9')),
      //                   find_index('debug_toggle_breakpoint_enabled',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F9')),
                         find_index('debug_clear_all_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('A-F9')),
                         find_index('debug_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F10')),
                         find_index('debug_step_over',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F10')),
                         find_index('debug_run_to_cursor',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F11')),
                         find_index('debug_step_into',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F11')),
                         find_index('debug_step_out',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F8')),
                         find_index('next_doc',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F8')),
                         find_index('prev_doc',COMMAND_TYPE));
      break;
   case 'brief-keys':
      //set_eventtab_index(_default_keys,event2index(name2event('F5')),
      //                   find_index('project_debug',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('S-F5')),
      //                   find_index('debug_stop',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('C-S-F5')),
      //                   find_index('debug_restart',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('F9')),
      //                   find_index('debug_toggle_breakpoint',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F9')),
                         find_index('debug_toggle_breakpoint_enabled',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F9')),
                         find_index('debug_clear_all_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('A-F9')),
                         find_index('debug_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F10')),
                         find_index('debug_step_over',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F10')),
                         find_index('debug_run_to_cursor',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F11')),
                         find_index('debug_step_into',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F11')),
                         find_index('debug_step_out',COMMAND_TYPE));
      break;
   case 'emacs-keys':
      set_eventtab_index(_default_keys,event2index(name2event('F5')),
                         find_index('project_debug',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F5')),
                         find_index('debug_stop',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F5')),
                         find_index('debug_restart',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F9')),
                         find_index('debug_toggle_breakpoint',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F9')),
                         find_index('debug_toggle_breakpoint_enabled',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F9')),
                         find_index('debug_clear_all_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('A-F9')),
                         find_index('debug_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F10')),
                         find_index('debug_step_over',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F10')),
                         find_index('debug_run_to_cursor',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F11')),
                         find_index('debug_step_into',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F11')),
                         find_index('debug_step_out',COMMAND_TYPE));
      break;
   case 'gnuemacs-keys':
      set_eventtab_index(_default_keys,event2index(name2event('F5')),
                         find_index('project_debug',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F5')),
                         find_index('debug_stop',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F5')),
                         find_index('debug_restart',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F9')),
                         find_index('debug_toggle_breakpoint',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F9')),
                         find_index('debug_toggle_breakpoint_enabled',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F9')),
                         find_index('debug_clear_all_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('A-F9')),
                         find_index('debug_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F10')),
                         find_index('debug_step_over',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F10')),
                         find_index('debug_run_to_cursor',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('F11')),
                         find_index('debug_step_into',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F11')),
                         find_index('debug_step_out',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-LBUTTON-DOWN')),find_index('mou_click_copy',COMMAND_TYPE));
      break;
   case 'ispf-keys':
      //set_eventtab_index(_default_keys,event2index(name2event('F5')),
      //                   find_index('project_debug',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F5')),
                         find_index('debug_stop',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F5')),
                         find_index('debug_restart',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('F9')),
      //                   find_index('debug_toggle_breakpoint',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('C-F9')),
      //                   find_index('debug_toggle_breakpoint_enabled',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-S-F9')),
                         find_index('debug_clear_all_breakpoints',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('A-F9')),
                         find_index('debug_breakpoints',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('F10')),
      //                   find_index('debug_step_over',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('C-F10')),
                         find_index('debug_run_to_cursor',COMMAND_TYPE));
      //set_eventtab_index(_default_keys,event2index(name2event('F11')),
      //                   find_index('debug_step_into',COMMAND_TYPE));
      set_eventtab_index(_default_keys,event2index(name2event('S-F11')),
                         find_index('debug_step_out',COMMAND_TYPE));
      break;
   }
   fixupVimBindings();
   fixupMacBindings();
   fixupContextTaggingBindings();
   fixupEclipseBindings();

   // Notify call-list about event table changes
   call_list('_eventtab_modify_',_default_keys,'');

   // IF we are not building the state file
   _DebugUpdateMenu();
}
_command void update_keys()
{
   // Update keys to this version of the editor.
   _UpdateKeys();
}
static _str _origenv_PATH;
static _str _origenv_INCLUDE;
static _str _origenv_LIB;
static _str _origenv_MSVCDir;

void _save_origenv()
{
   _origenv_PATH=get_env('PATH');
   _origenv_INCLUDE=get_env('INCLUDE');
   _origenv_LIB=get_env('LIB');
   _origenv_MSVCDir=get_env('MSVCDir');
}
static void set2(_str envVarName,_str value, bool updateProcessBuffer)
{
   if (updateProcessBuffer) {
      set(envVarName:+'='((value==null)?'':value));
   } else {
      set_env(envVarName,value);
   }

}
void _restore_origenv(bool updateProcessBuffer=false,bool restoreVCPPEnvVars=false)
{
   if (get_env('PATH')!=_origenv_PATH) {
      set2('PATH',_origenv_PATH,updateProcessBuffer);
   }
   if (!restoreVCPPEnvVars) return;

   if (get_env('INCLUDE')!=_origenv_INCLUDE) {
      set2('INCLUDE',_origenv_INCLUDE,updateProcessBuffer);
   }
   if (get_env('LIB')!=_origenv_LIB) {
      set2('LIB',_origenv_LIB,updateProcessBuffer);
   }
   if (get_env('MSVCDir')!=_origenv_MSVCDir) {
      set2('MSVCDir',_origenv_MSVCDir,updateProcessBuffer);
   }
}
_str _orig_path_search(_str programName)
{
    old_path := get_env('PATH');
    set_env('PATH',_origenv_PATH);
    _str result=path_search(programName,'','P');
    set_env('PATH',old_path);
    return(result);
}
bool _jaws_mode()
{
   return(_default_option(VSOPTION_JAWS_MODE));
}
static void _setup_jaws_mode()
{
   if (_jaws_mode()) {
      def_codehelp_flags&= ~(VSCODEHELPFLAG_AUTO_FUNCTION_HELP|VSCODEHELPFLAG_AUTO_LIST_MEMBERS|VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION|VSCODEHELPFLAG_AUTO_LIST_PARAMS);
      _config_modify_flags(CFGMODIFY_DEFVAR);
#if 0
      def_codehelp_flags=VSCODEHELPFLAG_RESERVED_ON|
                       VSCODEHELPFLAG_INSERT_OPEN_PAREN|VSCODEHELPFLAG_SPACE_INSERTS_SPACE|
                       VSCODEHELPFLAG_DISPLAY_FUNCTION_COMMENTS|VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS|
                       VSCODEHELPFLAG_REPLACE_IDENTIFIER|VSCODEHELPFLAG_PRESERVE_IDENTIFIER|
                       VSCODEHELPFLAG_NO_SPACE_AFTER_COMMA|
                       VSCODEHELPFLAG_PARAMETER_TYPE_MATCHING|
                       VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN;
#endif

   }
}
/**
 * @return Returns <i>string</i> with '%s' values replaced with arg1, arg2,
 * etc.  The first parameter must be a string constant.
 *
 * <p>Note that the Slick-C Translator optimizes the case where the
 * <b>nls</b> procedure is called with a simple string constant.  In this case,
 * the code generation is equivalent to just specifying the string constant
 * (i.e. the <b>nls</b> procedure is not called.).</p>
 *
 * @categories Miscellaneous_Functions
 *
 */
_str nls(_str msg,...)
{
   result := "";
   i := 1;
   arg_number := 1;
   for (;;) {
      int j=pos('%s([123456789]|)',msg,i,'r');
      if ( ! j ) {
        result :+= substr(msg,i);
        return(result);
      }
      typeless n;
      len := pos('');
      if (len>=3) {
         n=substr(msg,j+2,1);
      } else {
         n=arg_number;
      }
      if (arg(2)._varformat()==VF_ARRAY) {
         if(arg(2)[n]._varformat()==VF_EMPTY) {
            //say("Error in error message");
            //say(" ...Array not initialized");
            result :+= substr(msg,i,j-i);
         } else {
            result :+= substr(msg,i,j-i):+arg(2)[n];
         }
      } else {
         argNp1 := "";
         if (arg()>n && arg(n+1)._varformat()!=VF_EMPTY) {
            argNp1 = arg(n+1);
         }
         result :+= substr(msg,i,j-i):+argNp1;
      }
      arg_number++;
      i=j+len;
   }

}

/**
 * Used by OEMs to load custom macros and resources without having to
 * modify shipping macro source. Look for and execute oemaddons.e
 */
static void oemAddons()
{
   path := _getSlickEditInstallPath();
   _maybe_append_filesep(path);
   path :+= FILESEP:+"macros":+FILESEP:+"oemaddons.e";
   if( !file_exists(path) ) {
      // Check for .ex
      path :+= 'x';
      if( !file_exists(path) ) {
         path="";
      }
   }
   if( path!="" ) {
      orig_bit:=(def_actapp& ACTAPP_AUTOREADONLY);
      def_actapp&=~ACTAPP_AUTOREADONLY;
      // Run the oemaddons module to add custom OEM modules
      execute('oemaddons ',"");
      def_actapp|=orig_bit;
      if( rc && rc!=2 ) {
         process_make_rc(rc,'oemaddons');
      }
      if( !rc ) {
         // If messages at bottom, erase it
        clear_message();
      }
   }
}

static bool needToUpgradeArchiveFiles()
{
   deltaArchivePath := _getBackupHistoryPath();
   needToUpgrade := !path_exists(deltaArchivePath);
   return needToUpgrade;
}

static bool _TransferCfgToNewDirectory(_str &old_default_config, _str &new_default_config)
{
   // Prefix is above the directory that is called My Visual SlickEdit config or
   // My SlickEdit config
   i := 0;
   _str current_config_path = _ConfigPath();
   config_path_base := "";

   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ECLIPSE_PLUGIN) {
      config_path_base = get_env(_VSECLIPSECONFIG);
      _find_old_eclipse_default_config(config_path_base, old_default_config, new_default_config);
   } else {
      config_path_base = get_env(_SLICKEDITCONFIG);
      _find_old_default_config(config_path_base, old_default_config, new_default_config);
   }

   if(old_default_config != "") {
      msg :=  "Copying config '" :+ old_default_config:+ "\n to new directory '" :+ new_default_config :+ "...";
      _SplashScreenStatus("Copying configuration directory...");
      show_cancel_form_on_top("SlickEdit", msg, false, false);
      _str arg1 = old_default_config;
      _str arg2 = new_default_config;


      // skip copying certain files and directories
      bool skipFilesOrDirs:[];
      skipFilesOrDirs:[_file_case(STATE_FILENAME)] = true;
      skipFilesOrDirs:[_file_case("pipDB":+TAG_FILE_EXT)] = true;
      skipFilesOrDirs:[_file_case("dump.txt")] = true;
      skipFilesOrDirs:[_file_case("shutdown.xml")] = true;
      skipFilesOrDirs:[_file_case("vusrdata.ex")] = true;
      skipFilesOrDirs:[_file_case("vusrdefs.ex")] = true;
      skipFilesOrDirs:[_file_case("vusrkeys.ex")] = true;
      skipFilesOrDirs:[_file_case("vusrobjs.ex")] = true;
      _str tag_list[];
      _get_auto_generated_tagfile_names(tag_list);
      for (i=0; i<tag_list._length(); i++) {
         skipFilesOrDirs:[_file_case("tagfiles":+FILESEP:+tag_list[i])] = true;
      }
      skipFilesOrDirs:[_file_case("logs":+FILESEP)] = true;
      skipFilesOrDirs:[_file_case("hotfixes":+FILESEP)] = true;
      skipFilesOrDirs:[_file_case("java_rte_classes":+FILESEP)] = true;
      skipFilesOrDirs:[_file_case("mfundo":+FILESEP)] = true;
      skipFilesOrDirs:[_file_case("SampleProjects":+FILESEP)] = true;
      skipFilesOrDirs:[_file_case("SCDebug":+FILESEP)] = true;
      skipFilesOrDirs:[_file_case("vsdelta":+FILESEP)] = true;
      skipFilesOrDirs:[_file_case("autosave":+FILESEP)] = true;
      skipFilesOrDirs:[_file_case("tagfiles":+FILESEP:+XML_TAGFILE_CACHE_DIR:+FILESEP)] = true;
      if (!_haveContextTagging()) skipFilesOrDirs:[_file_case("tagfiles":+FILESEP)] = true;
      if (!_haveVersionControl()) skipFilesOrDirs:[_file_case("versioncache":+FILESEP)] = true;

      // remove hot-fix related items from previous version
      hotfix_statefile := file_match(_maybe_quote_filename(old_default_config:+FILESEP:+"vslick.ver.*.sta"):+ " -P", 1);
      while (hotfix_statefile != "") {
         skipFilesOrDirs:[_file_case(relative(hotfix_statefile, old_default_config))] = true;
         hotfix_statefile = file_match(hotfix_statefile, 0);
      }
      hotfix_plugin := file_match(_maybe_quote_filename(old_default_config:+FILESEP:+"plugins":+FILESEP:+"com_slickedit.base.ver.*.zip"):+" -P", 1);
      while (hotfix_plugin != "") {
         skipFilesOrDirs:[_file_case(relative(hotfix_plugin, old_default_config))] = true;
         hotfix_plugin = file_match(hotfix_plugin, 0);
      }

      // Now copy the configuration directory
      static bool canceled;
      process_events(canceled);
      int return_value = copyFileTree(old_default_config, new_default_config, '', true, null, skipFilesOrDirs);

      // Delete Slick-C tag file in new location to force re-tagging,
      // because the old tag file still points to the *.e files in old
      // installation.  --Kohei - 2006/6/8
      slickc_tagfile :=  'slickc':+TAG_FILE_EXT;
      if (_isUnix()) {
         slickc_tagfile = 'u' :+ slickc_tagfile;
      }
      slickc_tagfile = new_default_config :+ 'tagfiles' :+ FILESEP :+ slickc_tagfile;
      if ( file_exists(slickc_tagfile) ) {
         delete_file(slickc_tagfile);
      }

      //Remove the manifest.xml file
      manifest_xml_file := "manifest.xml";
      manifest_xml_file = new_default_config :+ manifest_xml_file;
      if (file_exists(manifest_xml_file)) {
         delete_file(manifest_xml_file);
      }

      //Remove the pipDB.vtg file
      pipDB_file :=  'pipDB':+TAG_FILE_EXT;
      pipDB_file = new_default_config :+ pipDB_file;
      if (file_exists(pipDB_file)) {
         delete_file(pipDB_file);
      }

      //Remove dump.txt (Eclipse JNI error log) 
      dump_file := "dump.txt";
      dump_file = new_default_config :+ dump_file;
      if (file_exists(dump_file)) {
         delete_file(dump_file);
      }

      // Delete old hot fixes directory, none of them apply to new version
      hotfixes_dir :=  new_default_config :+ "hotfixes" :+ FILESEP;
      _DelTree(hotfixes_dir, true);

      // Remove the logs directory
      _str logsDir = _log_path(new_default_config);
      _DelTree(logsDir, true);

      // Delete samples directory in new location
      //_str sample_projects_dir = _localSampleProjectsPath();
      //_DelTree(sample_projects_dir,true);
      
      if( return_value==0 ) {
         // Success
         // If there exists a vrestore.slk that was copied over from the
         // old config, then inform the application of the new restore
         // filename path. This is absolutely necessary since the user's
         // toolbars would be reset otherwise in the case of running the
         // product just after a patch, where the application does not
         // yet know about the vrestore.slk because it has not been copied
         // yet.
         _str restore_filename = new_default_config;
         _maybe_append_filesep(restore_filename);
         restore_filename :+= _WINDOW_CONFIG_FILE;
         if( file_exists(restore_filename) ) {
            editor_name('r',restore_filename);
         }
      }

      needToUpgradeArchives := needToUpgradeArchiveFiles();
      if ( needToUpgradeArchives ) {
         upgradeBackupHistoryFiles(old_default_config,config_path_base,cancel_form_wid());
      }
      close_cancel_form(cancel_form_wid());

      setSaveLogRebuild();
      return true;
   }

   return false;
}

/** 
 * This only upgrades backup history archives in global 
 * configurations.  If you have a VSLICKBACKUP set (this is what 
 * gets set in the configuration dialog), these will be upgraded 
 * on the fly as you access them. 
 *  
 * @param old_default_config old config path with version
 * @param config_path_base new config path, without version
 * @param cancel_form_wid window ID for cancel form so we can 
 *                        put gauge up
 */
static void upgradeBackupHistoryFiles(_str old_default_config,_str config_path_base,int cancel_form_wid)
{
   STRARRAY couldNotUpgradeList;
   DSUpgradeArchiveTree(old_default_config,config_path_base,couldNotUpgradeList,cancel_form_wid);
   len := couldNotUpgradeList._length();

   if ( len>0 ) {
      caption := nls("Could not upgrade the following backup history archive files:\n\n");
      for (i:=0; i<len; ++i) {
         caption :+= nls(couldNotUpgradeList[i]"\n\n");
      }
      _message_box(caption);
   }
}

static void setSaveLogRebuild()
{
   basePath := _getBackupHistoryPath();
   _maybe_append_filesep(basePath);
   dirName := basePath :+ '.';
   if ( file_exists(dirName) ) {
      saveLogFilename := basePath:+SAVELOG_FILE;
      if ( file_exists(saveLogFilename) ) {
         // If there is already a savelog.xml, we assume we're up to date.
         return;
      }
      xmlhandle := _xmlcfg_create(saveLogFilename,VSENCODING_UTF8);
      if ( xmlhandle>-1 ) {
         saveLogIndex := _xmlcfg_find_simple(xmlhandle,"/SaveLog");
         if ( saveLogIndex<0 ) {
            saveLogIndex = _xmlcfg_add(xmlhandle,TREE_ROOT_INDEX,"SaveLog",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
         }
         _xmlcfg_set_attribute(xmlhandle,saveLogIndex,"Rebuild",1);
         _xmlcfg_save(xmlhandle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
         _xmlcfg_close(xmlhandle);
      }
   }
}

static void upgrade_workspace_manager(_str transfered_directory_major_ver) {
   // clear out all our old sample projects (which were in the old version directory)
   clear_old_sample_projects(def_workspace_info);

   // add new ones!
   maybeAddSampleProjectsToTree(def_workspace_info);

   // Clean up old-style Xcode project history
   remove_xcode_pbxproj_extensions(def_workspace_info);

   // try to remove duplicate entries
   _upgrade_workspace_manager_remove_duplicates(def_workspace_info);

   // try to add current project to older entries that just have workspace name
   if (transfered_directory_major_ver<21) {
      _upgrade_workspace_manager_active_projects(def_workspace_info);
   }
}

void clear_old_sample_projects(WORKSPACE_LIST (&workspaceInfo)[])
{
   // go through the list and find the sample folder
   for (i := 0; i < workspaceInfo._length(); i++) {
      // is this a folder?
      if (workspaceInfo[i].isFolder) {
         if (workspaceInfo[i].caption == WORKSPACE_FOLDER_SAMPLES) {
            // hey, we found it!
            workspaceInfo._deleteel(i);
            return;
         } else {
            // we might need to recurse here
            clear_old_sample_projects(workspaceInfo[i].u.list);
         }
      } // not a folder, so just leave it alone
   }
}

void remove_xcode_pbxproj_extensions(WORKSPACE_LIST (&workspaceInfo)[])
{
    // Find any captions or filenames that end in /project.pbxproj. Trim this portion
    // off so that only ProjectName.xcodeproj or ProjectName.xcode remains. 
    for (i := 0; i < workspaceInfo._length(); i++) {
        if(!(workspaceInfo[i].caption._isempty())) {
           pbxExt := pos('project.pbxproj', workspaceInfo[i].caption);
           if(pbxExt > 0) {
              captionTrimmed := substr(workspaceInfo[i].caption,1,pbxExt-2);
              workspaceInfo[i].caption = captionTrimmed;
           }
        }

        if(!(workspaceInfo[i].filename._isempty()))
        {
            pbxExt := pos('project.pbxproj', workspaceInfo[i].filename);
            if(pbxExt > 0) {
               fileTrimmed := substr(workspaceInfo[i].filename,1,pbxExt-2);
               workspaceInfo[i].filename = fileTrimmed;
            }
        }
    }
}

static void change_ext_tagfiles_location(_str old_default_config, _str new_default_config)
{
   // Take out trailing slash if there is one
   last_slash := lastpos(FILESEP,new_default_config);
   if(last_slash == length(new_default_config)) {
      new_default_config = substr(new_default_config, 1, last_slash-1);
   }

   // go through each language tag file list
   _str langTagFileTable:[];
   LanguageSettings.getTagFileListTable(langTagFileTable);
   foreach (auto langId => auto langTagFilesList in langTagFileTable) {

      oldTagFilesList := langTagFilesList;
      newTagFilesList := '';
      while (langTagFilesList != '') {
         // go through each tag file in the list and update the path
         parse langTagFilesList with auto tagFile (PARSE_PATHSEP_RE),'r' langTagFilesList;
         tagFile = _replace_envvars(tagFile);

         vtg := _strip_filename(tagFile, 'P');
         dir := _strip_filename(tagFile, 'N');

         // Does the start of the tagfile path match the old_default_config? If so then
         // the tagfile is underneath the old directory.
         tagfile_config_dir := substr(dir, 1, length(old_default_config));
         rest_of_path := substr(dir, length(tagfile_config_dir) + 1);
         if (_file_eq(tagfile_config_dir, old_default_config)) {
            if (_last_char(new_default_config) != FILESEP && _first_char(rest_of_path) != FILESEP ) {
               rest_of_path = FILESEP :+ rest_of_path;
            }

            tagFile = new_default_config :+ rest_of_path :+ vtg;
         }

         // add this tag file to our list
         if (newTagFilesList != '') {
            newTagFilesList :+= PATHSEP;
         }
         newTagFilesList :+= tagFile;
      }

      // we might need to update our list
      if (newTagFilesList != oldTagFilesList) {
         LanguageSettings.setTagFileList(langId, newTagFilesList);
      }
   }
}

/**
 * This function is not really necessary any more because now we 
 * will store loaded macro paths relative to the configuration 
 * directory so that they are more portable.  But we can still 
 * use this function to migrate and old configuration which has 
 * absolute paths to the configuration directory to the new way 
 * of storing macro paths. 
 */
static void change_def_macfiles_location(_str old_default_config, _str new_default_config)
{
   // Take out trailing slash if there is one
   new_default_config = strip(new_default_config, 'T', FILESEP);

   // Loop through all the files in def_macfiles
   new_macfiles := "";
   foreach (auto macroFile in def_macfiles) {
      // Does the start of the macro path match the old_default_config? 
      // If so then the macro is underneath the old directory.
      macroFile = strip(macroFile, "B", '"');
      relativeFile := relative(macroFile, old_default_config, false);
      if (!_file_eq(relativeFile, macroFile)) {
         sourceFile := relativeFile;
         if (_get_extension(relativeFile) == "ex") {
            sourceFile = substr(relativeFile,1,length(relativeFile)-1);
         }
         if (file_exists(new_default_config:+FILESEP:+sourceFile)) {
            macroFile = relativeFile;
         }
      }
      if (new_macfiles != '') new_macfiles :+= ' ';
      new_macfiles :+= _maybe_quote_filename(macroFile);
   }

   // change def_macfiles if we moved any macros
   if (new_macfiles != def_macfiles) {
      def_macfiles = new_macfiles;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

#if 0
/**
 * Check to see if the current platform is macOS
 * 
 * @return Flag: true for active, false not
 */
bool _isMac()
{
   return(machine()=='MACOSX' || machine()=='MACOSX11');
}
#endif
  
/**
 * Check to see if the Eclipse plug-in is active.
 * 
 * @return Flag: true for active, false not
 */
bool isEclipsePlugin()
{
   return (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ECLIPSE_PLUGIN);
}
void _bind_command_to_key(_str event,_str command,int et_index=_default_keys)
{
   if (command==null) {
      set_eventtab_index(et_index,event2index(event),0);
   }
   index := find_index(command,COMMAND_TYPE);
   if (!index) {
      _message_box('_bind_command_to_key: command 'command' not found');
      return;
   }
   set_eventtab_index(et_index,event2index(event),index);
}
_str _default_c_wildcards()
{
   if (_isUnix()) {
      if (_isMac()) {
         return("*.c;*.cxx;*.cpp;*.cppm;*.c++;*.m;*.mm;*.h;*.hpp;*.hxx;*.h++;*.inl;*.ixx");
      }
      return("*.c;*.cxx;*.cpp;*.cppm;*.c++;*.h;*.hpp;*.hxx;*.h++;*.inl;*.ixx");
   }
   return("*.c;*.cxx;*.cpp;*.cppm;*.c++;*.h;*.hpp;*.hxx;*.h++;*.inl;*.ixx");
}

/**
 * Compares two version numbers in the form of x.x.x.x(...) to see which is 
 * greater. 
 * 
 * @param ver1             
 * @param ver2 
 * @param resolution       how far in the comparison to go, use -1 to compare 
 *                         the whole numbers.  See example.
 *  
 * 
 * @return int             0 indicates versions are equal, int > 0 means ver1 is 
 *                         greater, int < 0 means ver2 is greater
 *  
 * @example
 * <pre>
 * _version_compare('15.0.0.5', '15.0.0.6');          // returns -1
 * _version_compare('15.0.0.5', '15.0.0.5');          // returns 0
 * _version_compare('15.0.0.7', '15.0.0.6');          // returns 1
 * _version_compare('15.0.0.7', '15.0.0.6', 3);       // returns 0, as the first three sections of each are equal
 * </pre>
 * 
 * @categories Miscellaneous_Functions
 */
int _version_compare(_str ver1, _str ver2, int resolution = -1)
{
   count := 0;

   while (resolution < 0 || count < resolution) {
      count++;

      // find the dot!
      dotPos1 := pos('.', ver1);
      dotPos2 := pos('.', ver2);

      if (!dotPos1 && !dotPos2) {
         // we are out of dots, so just compare these
         return strcmp(ver1, ver2);
      } 

      // init these to 0, in case there are no more dots
      preDot1 := '0';
      preDot2 := '0';
      if (dotPos1) {
         // strip out what's before the dot
         preDot1 = substr(ver1, 1, dotPos1 - 1);
         ver1 = substr(ver1, dotPos1 + 1);
      } else {
         preDot1 = ver1;
         ver1 = '0';
      }

      if (dotPos2) {
         // strip out what's before the dot
         preDot2 = substr(ver2, 1, dotPos2 - 1);
         ver2 = substr(ver2, dotPos2 + 1);
      } else {
         preDot2 = ver2;
         ver2 = '0';
      }
  
      // When compare numeric version strings
      // 2.0 is less than 10.0 AND
      // 16.4 is less than 16.10.
      // This is not like a floating pointer compare.
      if (isinteger(preDot1) && isinteger(preDot2)) {
         diff:=(int)preDot1-(int)preDot2;
         if (diff) {
            return diff;
         }
      } else {
         compValue := strcmp(preDot1, preDot2);
         if (compValue) return compValue;
      }
   }

   return 0;
}

_command void reset_window_layout,tbResetAll(bool resetToolbars=true)
{
   //_StackDump();
   // Toolbars
   if ( resetToolbars ) {
      // Remove system toolbars from def_toolbartab
      int i;
      for ( i=0; i < def_toolbartab._length(); ++i ) {
         index:= find_index(def_toolbartab[i].FormName, oi2type(OI_FORM));
         if ( index == 0 ) {
            continue;
         }
         typeless ff=name_info(index);
         if( !isinteger(ff) ) {
            ff=0;
         }
         if (ff & FF_SYSTEM) {
            def_toolbartab._deleteel(i);
            --i;
         }
      }

      _tbNewVersion();
      _tbDeleteAllQToolbars();
      _tbResetDefaultQToolbars();
   } else {
      // Sanitize def_toolbartab, but do not delete any user toolbars
      _tbNewVersion();
   }

   // Dock channel
   dc_reset_all();

   // Tool windows
   tw_reset_all();
   if ( !def_tbreset_with_file_tabs || !_haveFileTabsWindow() ) {
      wid := tw_is_visible('_tbbufftabs_form');
      if ( wid ) {
         /*
            Hide File Tabs tool window for the "Main" window layout only.
         */
         // IF tool window is floating OR docked to main MDI window
         if (!tw_is_docked_window(wid) || _MDIFromChild(wid)==_mdi) {
            hide_tool_window(wid);
         }
      }
   }

   _config_modify_flags(CFGMODIFY_DEFVAR);
}

_command void prompt_reset_window_layout()
{
   if( IDYES == _message_box(get_message(VSRC_CFG_RESET_WINDOW_LAYOUT), '', (MB_ICONQUESTION | MB_YESNO)) ) {
      reset_window_layout();
   }
}
/**
 * 
 * @param kt_name
 * @param apply_profile_option
 * @param optionLevel  Specify 0, to get the current event table
 *                     if it exists, or a newly created event
 *                     table with profile settings (very useful
 *                     for mode event tables). Specify 1, to get
 *                     an event table set to profile settings.
 *                     Specify 2, to get the current event table 
 *                     or a new event table.
 * 
 * @return Returns index of event table.
 */
int _eventtab_get_mode_keys(_str kt_name,int apply_profile_option=0,int optionLevel=0) {
   if (kt_name=='') {
      return 0;
   }
   apply_profile := apply_profile_option==1;
   kt_index:=find_index(kt_name,EVENTTAB_TYPE);
   if (!kt_index) {
      if (apply_profile_option==0) {
         apply_profile=true;
      }
      kt_index=insert_name(kt_name,EVENTTAB_TYPE);
      // If not resetting this event table, we can recreate this when needed.
      if (apply_profile_option==1) {
         _config_modify_flags(CFGMODIFY_KEYS);
      }
   }
   if (!apply_profile) {
      return kt_index;
   }
   profileName:=_eventtab_name_2_profile_name(kt_name);
   
   if (profileName!='') {
      _plugin_eventtab_apply_bindings(VSCFGPACKAGE_EVENTTAB_PROFILES,profileName,kt_index,optionLevel);
      if (_eventtab_get_modify(kt_index)) {
         if (!optionLevel) {
            _eventtab_set_modify(kt_index,false);
         }
         // If not resetting this event table, we can recreate this when needed.
         if (apply_profile_option==1) {
            _config_modify_flags(CFGMODIFY_KEYS);
         }
      }
   }
   return kt_index;
}

_str _def_keys_2_emulation_profile_suffix(_str name=def_keys) {
   switch (name) {
   case '':
   case 'slick-keys':
      return 'SlickEdit';
      return 'SlickEdit';
   case 'bbedit-keys':
      return 'BBEdit';
   case 'brief-keys':
      return 'Brief';
   case 'codewarrior-keys':
      return 'CodeWarrior';
   case 'codewright-keys':
      return 'CodeWright';
   case 'emacs-keys':
      return 'Epsilon';
   case 'gnuemacs-keys':
      return 'GNU Emacs';
   case 'ispf-keys':
      return 'ISPF';
   case 'vcpp-keys':
      return 'Visual C++ 6';
   case 'vi-keys':
      return 'Vim';
   case 'vsnet-keys':
      return 'Visual Studio';
   case 'cua-keys':
       return 'CUA';
   case 'windows-keys':
      return 'CUA';
   case 'macosx-keys':
      return 'macOS';
   case 'xcode-keys':
      return 'Xcode';
   case 'eclipse-keys':
      return 'Eclipse';
   }
   return '';
}
_str _def_keys_2_profile_name(_str name=def_keys) {
   return 'emulation-'_def_keys_2_emulation_profile_suffix(name);
}
/**
 * Convert a profile name to the event table name.
 *  
 * NOTE: Uou can't call this function for "emulation-" profile 
 * names. 
 *  
 * @param profileName
 * 
 * @return 
 */
_str _profile_name_2_eventtab_name(_str profileName) {
   return profileName'_keys';
}
/**
 * Convert a profile name to the event table name.
 *  
 * NOTE: Uou can't call this function for "emulation-" profile 
 * names. 
 *  
 * @param profileName
 * 
 * @return 
 */
_str _eventtab_name_2_profile_name(_str eventtabName) {
   eventtabName=translate(eventtabName,'_','-');
   if (eventtabName=='default_keys') {
      return _def_keys_2_profile_name();
   }
   if (endsWith(eventtabName,"_keys",false)) {
      return substr(eventtabName,1,length(eventtabName)-5);
   }
   // Error
   return '';
}
void _plugin_eventtab_apply_all_bindings() {
   // def_keys has been set by misc.def_vars profile.
   // Switch to that emulation here.
   _set_emulation_key_bindings(false);

   /*
      Apply all non-emulation keyboard profiles

      For speed, fetch user options xml which only contains
      user profiles that have beeen modified. Using _plugin_list_profiles
      would require fetching all profiles which is more expensive. The
      user options xml is already loaded so it's quick to fetch a copy of it.
   */
   handle:=_plugin_get_user_options();
   re:='^'VSCFGPACKAGE_EVENTTAB_PROFILES'.';
   _str array[];
   _xmlcfg_find_simple_array(handle,"/options/profile[contains(@n,'"re"','r')]",array);
   len := array._length();
   for (i:=0;i<len;++i) {
      typeless node=array[i];
      profile_name:=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROFILE_NAME);
      if (beginsWith(profile_name,'emulation-',false,'i')) {
         continue;
      }
      // Change emulation already applied these profiles.
      if (profile_name=='vi_command' || profile_name=='vi_visual') {
         continue;
      }
      profile_name=_plugin_get_profile_name(profile_name);
      etab_name:=_profile_name_2_eventtab_name(profile_name);
      index:=find_index(etab_name,EVENTTAB_TYPE);
      // If this event table is not already defined, can
      // defer loading until _SetEditorLanguage switches
      // to that language
      if (index) {
         _eventtab_get_mode_keys(etab_name,1);
      }
   }
   _xmlcfg_close(handle);
}
void _set_emulation_key_bindings(bool just_set_keybindings=false,int optionLevel=0) {
   _plugin_eventtab_apply_bindings(VSCFGPACKAGE_EVENTTAB_PROFILES,_def_keys_2_profile_name(),_default_keys,optionLevel);
   if (_eventtab_get_modify(_default_keys)) {
      if (!optionLevel) {
         _eventtab_set_modify(_default_keys,false);
      }
      _config_modify_flags(CFGMODIFY_KEYS);
   }
   if (def_keys=='vi-keys') {
      _eventtab_get_mode_keys('vi-command-keys',1,optionLevel);
      _eventtab_get_mode_keys('vi-visual-keys',1,optionLevel);
   }
   if (just_set_keybindings) return;
   // Notify call-list about event table changes
   call_list('_eventtab_modify_',defeventtab default_keys,'');
   // Update the menus with key binding information if known
   _update_sysmenu_bindings();
   // Determines the key bindings for all menu items on the SlickEdit menu bar.
   menu_mdi_bind_all();
}
_command void update_emulation_profiles() name_info(',')
{
   _eventtab_set_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_def_keys_2_profile_name(),_default_keys);_eventtab_set_modify(_default_keys,false);
   if (def_keys=='vi-keys') {
      kt_name:='vi-command-keys';
      kt_index:=_eventtab_get_mode_keys(kt_name);
      _eventtab_set_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_eventtab_name_2_profile_name(kt_name),kt_index);_eventtab_set_modify(kt_index,false);
      kt_name='vi-visual-keys';
      kt_index=_eventtab_get_mode_keys(kt_name);
      _eventtab_set_profile(VSCFGPACKAGE_EVENTTAB_PROFILES,_eventtab_name_2_profile_name(kt_name),kt_index);_eventtab_set_modify(kt_index,false);
   }
}
static _str _excludeEventTabs:[] = {
   "root-keys"                => 1,
   "mode-keys"                => 1,
   "argument-completion-keys" => 1,
   "auto-complete-keys"       => 1,
   "codehelp-keys"            => 1,
};
static bool _allow_eventtab(int et_index) {
   if (_excludeEventTabs._indexin(name_name(et_index))) {
      return false;
   }
   return true;
}
void _update_profiles_for_modified_eventtabs() {
   int index=name_match('',1,EVENTTAB_TYPE);
   while (index) {
      _update_profile_for_eventtab(index);
      index=name_match('',0,EVENTTAB_TYPE);
   }
}
void _update_profile_for_eventtab(int index) {
   name := name_name(index);
   if ( ! (name=='root-keys' || name=='mode-keys' ||
           pos('[:.]',name_name(index),1,'r') || find_index(name_name(index),OBJECT_TYPE) ||
           substr(name,1,4)=='-ul2' ||  substr(name,1,4)=='-ul1' ||substr(name,1,5)=='-ainh') ) {

      if (pos('-keys',name) && _allow_eventtab(index) && _eventtab_get_modify(index)) {
         _eventtab_set_profile(VSCFGPACKAGE_EVENTTAB_PROFILES, _eventtab_name_2_profile_name(name),index);
         //say('updated eventtab='name_name(index));
         _eventtab_set_modify(index,false);
      }
   }
}
void _setSelectionListFont(_str fontinfo) {
   _selection_list_font=fontinfo;
}
_str _getSelectionListFont() {
   // Set to '' in _firstinit()
   if (_selection_list_font!='') {
      return _selection_list_font;
   }
   handle:=_plugin_get_property_xml(VSCFGPACKAGE_MISC,VSCFGPROFILE_FONTS,'selection_list');
   if (handle<0) {
      return VSDEFAULT_FIXED_FONT_NAME',10';
   }
   property_node:=_xmlcfg_get_first_child(handle,0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   if (property_node<0) {
      _xmlcfg_close(handle);
      return VSDEFAULT_FIXED_FONT_NAME',10';
   }
   attrs_node:=property_node;
   font_name:=_xmlcfg_get_attribute(handle,attrs_node,'font_name');
   sizex10:=_xmlcfg_get_attribute(handle,attrs_node,'sizex10');
   flags:=_xmlcfg_get_attribute(handle,attrs_node,'flags');
   _xmlcfg_close(handle);
   if (font_name!='' && isinteger(sizex10) && upcase(substr(flags,1,2))=='0X') {
      flags=_hex2dec(flags);
      _selection_list_font=font_name','(sizex10 intdiv 10)','flags;
      return _selection_list_font;
   }
   return VSDEFAULT_FIXED_FONT_NAME',10';
}
static void update_v20_user_cfg_xml(_str transfered_directory_major_ver) {
   filename:=_ConfigPath():+VSCFGFILE_USER;
   if (file_exists(filename)) {
      handle:=_xmlcfg_open(filename,auto status);
      if (handle<0) return;
      match := "application.notifications";
      if (transfered_directory_major_ver>=21) {
         match='application.notification_profiles';
      }
      re:='^'match'.';
      _str array[];
      _xmlcfg_find_simple_array(handle,"/options/*[contains(@n,'"re"','r')]",array);
      doSave:=false;
      for (i:=0;i<array._length();++i) {
         typeless node=array[i];
         profile_name:=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROFILE_NAME);
         profile_name=stranslate(profile_name,VSCFGPACKAGE_NOTIFICATION_PROFILES,match);
         _xmlcfg_set_name(handle,node,VSXMLCFG_PROFILE);
         _xmlcfg_set_attribute(handle,node,VSXMLCFG_PROFILE_NAME,profile_name);
         doSave=true;
      }
      if (doSave) {
         _xmlcfg_save(handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
      }
      _xmlcfg_close(handle);
      if (doSave) {
         // Reload the user.cfg.xml that may have been transfered. This reloads all the local and system plugin .cfg.xml files
         plugin_reload_user_config();
      }
   }
}
_str _get_monitor_config()  {
   _ScreenInfo list[];
   _GetAllScreens(list);
   configs:='';
   int i;
   for (i=0;i<list._length();++i) {
      if (configs:!='') {
         strappend(configs,',');
      }
      strappend(configs,list[i].x' 'list[i].y' 'list[i].width' 'list[i].height);
   }
   return configs;
}
bool _config_file_changed(_str filename) {
   dt:=_file_date(filename,'B');
   if (!dt || dt=='') {
      // File doesn't exist
      // If users deletes vusrmacs, config not updated.
      return false;
   }
   dt2:=_config_file_dates:[_file_case(filename)];
   if (dt2==null || dt2!=dt) {
      _config_file_dates:[_file_case(filename)]=dt;
      return true;
   }
   return false;
}
void _reload_usermacs(_str filename_no_quotes) {
   if(!_default_option(VSOPTION_LOAD_PLUGINS)) {
      return;
   }
   filename:=_maybe_quote_filename(filename_no_quotes);
   int make_rc=_make(filename);
   if ( make_rc ) {
     if ( make_rc==FILE_NOT_FOUND_RC ) {
       popup_message(nls("File '%s' not found",filename));
     } else {
       if ( make_rc==1  ) {  /* rc from Slick Translator? */
          //ST already processed message.
       } else {
         popup_message(nls("Unable to make '%s'",filename)".  "get_message(make_rc));
       }
     }
   } else {
      name := _strip_filename(filename_no_quotes,'P');
      int status;
      if (_file_eq(USERMACS_FILE:+_macro_ext,name)) {
         status=_load(filename,'r');_config_modify_flags(CFGMODIFY_USERMACS);
      } else {
         status=_load(filename,'r');_config_modify_flags(CFGMODIFY_LOADMACRO);
      }
      if (status==VSRC_PRO_VERSION_VERSION_REQUIRED_TO_LOAD_THIS_MACRO && !_haveProMacros()) {
         // There are likely pro features being used in the user recorded macro file.
         // Delete the file so macro recording at least works in the standard edition.
         delete_file(strip(filename,'B','"'));
         delete_file(strip(filename,'B','"')'x');
      }
   }
}
_str _importUserMacroFile(_str path) {
   status:=_open_temp_view(path,auto temp_wid,auto orig_wid);
   if (status) {
      return "Error opening macro file "path"." :+ OPTIONS_ERROR_DELIMITER;
   }
   status=search("_command last_recorded_macro","@>");
   if (status) {
      _delete_temp_view(temp_wid);
      return "Can't find start of recorded command in "path"." :+ OPTIONS_ERROR_DELIMITER;
   }
   get_line(auto line);
   parse line with '_command ' auto macro_name '(';
   parse line with "name_info(','" auto flags ")";
   status=save_macro(macro_name' 'flags,true,'',temp_wid);
   _delete_temp_view(temp_wid);
   if (status) {
      return "Error replacing lastmac macro from "path"." :+ OPTIONS_ERROR_DELIMITER;
   }
   return '';
}

