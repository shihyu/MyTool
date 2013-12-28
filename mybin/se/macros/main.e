////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50488 $
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
#include "minihtml.sh"
#require "se/lang/api/LanguageSettings.e"
#import "se/alias/AliasFile.e"
#import "se/color/ColorScheme.e"
#import "se/color/SymbolColorConfig.e"
#import "autosave.e"
#import "autocomplete.e"
#import "codetemplate.e"
#import "bufftabs.e"
#import "context.e"
#import "enterpriseoptions.e"
#import "env.e"
#import "fileman.e"
#import "files.e"
#import "filetypemanager.e"
#import "guifind.e"
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
#import "saveload.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "tbprops.e"
#import "toolbar.e"
#import "vchack.e"
#import "window.e"
#import "wkspace.e"
#import "wman.e"
#import "xml.e"
#import "xmldoc.e"
#endregion

using namespace se.lang.api;

int _use_timers=1;
boolean def_use_timers=true;

VSAUTOLOADEXT gAutoLoadExtHashtab:[]=
{
  // extension => module, mode-name
  'ch'=> {'ch','Ch'},
  'chf'=> {'ch'},
  'chs'=> {'ch'},
  'for'=> {'fortran','Fortran'},
  'f'=>{'fortran',''},
  'f90'=>{'fortran',''},
  'f95'=>{'fortran',''},
  'cob'=>{'cobol','Cobol'},
  'cbl'=>{'cobol',''},
  'mod'=>{'modula','Modula'},
  'bas'=>{'msqbas','Visual Basic'},
  'frm'=>{'msqbas',''},
  'vbs'=>{'vbscript','VBScript'},
  'vb'=>{'msqbas',''},
  'vhd'=>{'vhdl',''},
  'vhdl'=>{'vhdl','VHDL'},
  'v'=>{'verilog','Verilog'},
  'verilog'=>{'verilog','Verilog'},
  'prg'=>{'prg'},
  'ada'=>{'ada','Ada'},
  'adb'=>{'ada',''},
  'ads'=>{'ada',''},
  'perl'=>{'perl','Perl'},
  'py'=>{'python','Python'},
  'python'=>{'python','Python'},
  'pl'=>{'perl','Perl'},
  'pm'=>{'perl',''},
  'awk'=>{'awk','Awk'},
  'tcl'=>{'tcl','Tcl'},
  'tlib'=>{'tcl'},
  'exp'=>{'tcl'},
  'asm'=>{'asm','Intel Assembly'},
  's'=>{'asm',''},
  'inc'=>{'asm','Intel Assembly'},
  'asm390'=>{'asm','IBM HLASM'},
  'rexx'=>{'rexx'},
  'rul'=>{'rul','InstallScript'},
  'pl1'=>{'pl1','PL/I'},
  'cics'=>{'cics','CICS'},
  'rb'=>{'ruby','Ruby'},
  'rby'=>{'ruby','Ruby'},
  'ruby'=>{'ruby','Ruby'},
  'g'=>{'antlr','ANTLR'},
  'l'=>{'antlr','Lex'},
  'y'=>{'antlr','Yacc'},
  'lex'=>{'antlr','Lex'},
  'yacc'=>{'antlr','Yacc'},
  'sas'=>{'sas','SAS'},
  'gl'=>{'4gl','GL'},
  '4gl'=>{'4gl','GL'},
  'p4gl'=>{'4gl','GL'},
  'as'=>{'actionscript','ActionScript'},
  //'seq'=>{'sabl','SABL'},  The company that uses this explicitly loads it.
};

_str _post_install_version = "0";
boolean def_list_binary_files=true;
_str def_mffind_pathsep=';';
int def_maxcombohist=20;  // Default maximum combo box retrieval list
// Used by Help and API index. We need these declared here because they are
// used to transfer configuration data from pre-7.0 versions.
_str def_helpidx_filename;
_str def_helpidx_path;
#if __PCDOS__
_str def_msdn_coll;
#endif 
//_str def_wh;
static _str xfer_helpidx_filename='';
static _str xfer_wh='';
static boolean buildingStateFile=false;
static int gAutoRestoreFinished = 0;

_str  def_encoding='+fautounicode';

/**
 * If enabled, when you click or switch focus to a text box or
 * combo box, automatically select the text in the text box
 * so that it can be typed over.
 *
 * @default true
 * @categories Configuration_Variables
 */
boolean def_focus_select=true;

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
boolean def_cde_workaround=true;
int def_max_makefile_menu=15;
int def_surround_mode_options=0xffff;
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
boolean def_error_check_help_items=true;
_str st_batch_mode=0;    /* Used by ST command to indicate DEFMAIN -p option. */
_str _macro_ext;

/**
 * Key bindings version. We need this to know whether we should
 * automatically update some key bindings when transferring a
 * users keyboard configuration to a new version.
 *
 * @default 0
 * @categories Configuration_Variables
 */
_str def_keys_version=0;

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
int def_ctags_flags=2;
boolean def_switchbuf_cd=false;
VS_TAG_RETURN_TYPE gnull_return_type={null,null,null,0,0,false,{'\1'=>''},0};
int def_fileio_timeout=250;
int def_fileio_continue_to_timeout=2000;
int def_codehelp_flags = VSCODEHELPFLAG_AUTO_FUNCTION_HELP|
                         VSCODEHELPFLAG_AUTO_LIST_MEMBERS|
                         VSCODEHELPFLAG_RESERVED_ON|
                         VSCODEHELPFLAG_INSERT_OPEN_PAREN|
                         VSCODEHELPFLAG_SPACE_INSERTS_SPACE|
                         VSCODEHELPFLAG_DISPLAY_FUNCTION_COMMENTS|
                         VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS|
                         VSCODEHELPFLAG_REPLACE_IDENTIFIER|
                         VSCODEHELPFLAG_PRESERVE_IDENTIFIER|
                         VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION|
                         VSCODEHELPFLAG_NO_SPACE_AFTER_COMMA|
                         VSCODEHELPFLAG_AUTO_LIST_PARAMS|
                         VSCODEHELPFLAG_PARAMETER_TYPE_MATCHING|
                         VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN|
                         VSCODEHELPFLAG_MOUSE_OVER_INFO|
                         VSCODEHELPFLAG_FIND_TAG_PREFERS_ALTERNATE;

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
   ,def_exit_process=''
   ,def_user_args=''
   ,_error_file=''
   ,def_prompt=''
#if __PCDOS__
   ,_fpos_case="I"
#else
   ,_fpos_case=""
#endif
   ,_macro_ext=''
   ,_tag_pass=''
   ,def_file_types=''
   ,def_qmark_complete=''
   ,def_one_file='+w'
   ,def_scroll_speeds='30.0 20.3 10.4 10.6'
   ,def_next_word_style
   ,def_top_bottom_style
   ,def_pmatch_style2=1
   ,def_leave_selected=''
   ,def_gui=''
   ,def_alt_menu=''
   ,def_modal_tab=''
   ,def_wh='vslick.idx'
   ,def_cua_textbox=''
   ,def_mdi_menu=_MDIMENU
   ,_cur_mdi_menu=_MDIMENU
   ,def_keydisp='L'
   ,def_as_timer_amounts='m1 m1 0'
   ,def_as_directory      // Default directory for AutoSave
   ,def_mffind_style=2
#if __UNIX__
   ,COMPILE_ERROR_FILE="vserrors.tmp"
#else
   ,COMPILE_ERROR_FILE="$errors.tmp"
#endif
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
   ,def_max_loadall='1 8000'
   ,def_tprint_pscommand='--media=Letter --no-header --quiet';

#if __UNIX__
   _str def_qt_sellist_font='Default Fixed Font,10';
   _str def_qt_jsellist_font='OEM Fixed Font';
#else
   _str def_qt_sellist_font='Courier,10';
   _str def_qt_jsellist_font='OEM Fixed Font';
#endif
   //_str def_color_scheme="VSE Default";
   _str def_color_scheme="(init)";
   _str def_embedded_color_scheme="(init)";
_str   def_save_on_compile='1 0'; //0=no save, 1=save current file, 2=save all files
_str _compiler_default; // Default compiler package when create new project.
boolean def_close_window_like_1fpw=true;

_str def_keys = '';
boolean def_emulation_was_selected = false;
boolean def_exit_on_autosave = 0;
int def_open_style=OPEN_SMART_OPEN;
boolean def_mac_save_prompt_style=1;
boolean def_delete_uses_recycle_bin=0;
#if __UNIX__
_str def_trash_command='';
#endif
boolean def_prompt_open_style=true;
int def_tagging_cache_size = 0x10000;  // 64 megabytes
int def_tagging_cache_max  = 0x80000;  // 512 megabytes
_str def_tagging_excludes = '';
int def_proc_tree_options=PROC_TREE_AUTO_EXPAND|PROC_TREE_SORT_LINENUMBER|PROC_TREE_NO_BUFFERS;
int def_proc_tree_expand_level = 0;
int def_tag_select_options=PROC_TREE_SORT_FUNCTION;
int def_tagwin_flags= -1;    // Turn on everything just in case we add more flags in the next release
int def_references_flags=-1; // Turn on everything just in case we add more flags in the next release
int def_proctree_flags= -1;  // Turn on everything just in case we add more flags in the next release
int def_tagselect_flags = -1;// Turn on everything just in case we add more flags in the next release
int def_find_symbol_flags = -1;// Turn on everything just in case we add more flags in the next release
int def_class_flags = -1;// Turn on everything just in case we add more flags in the next release
int def_javadoc_filter_flags=(-1&~(VS_TAGFILTER_PACKAGE|VS_TAGFILTER_MISCELLANEOUS|VS_TAGFILTER_INCLUDE|VS_TAGFILTER_LABEL|VS_TAGFILTER_LVAR));
int def_xmldoc_filter_flags=(-1&~(VS_TAGFILTER_PACKAGE|VS_TAGFILTER_MISCELLANEOUS|VS_TAGFILTER_INCLUDE|VS_TAGFILTER_LABEL|VS_TAGFILTER_LVAR));
#if __MACOSX__
int def_autotag_flags2=AUTOTAG_ON_SAVE|AUTOTAG_BUFFERS|AUTOTAG_SYMBOLS|AUTOTAG_FILES_PROJECT_ONLY|AUTOTAG_CURRENT_CONTEXT|AUTOTAG_WORKSPACE_NO_ACTIVATE;
#else
int def_autotag_flags2=AUTOTAG_ON_SAVE|AUTOTAG_BUFFERS|AUTOTAG_SYMBOLS|AUTOTAG_FILES_PROJECT_ONLY|AUTOTAG_CURRENT_CONTEXT;
#endif
int def_pmatch_max_diff = 80000;   // We have a for loop in c_id_case() which needs about 60k for this to work
int def_updown_col=0;
int def_change_dir=OFN_CHANGEDIR;
#if __PCDOS__
int def_use_xp_opendialog = 0;
#endif
boolean def_copy_noselection=true;
boolean def_stop_process_noselection=true;
boolean def_enter_indent=0;
boolean def_auto_landscape=1;
boolean def_cursorwrap=0;
boolean def_hack_tabs=0;
boolean def_restore_cursor=0;
boolean def_pull=1;
boolean def_jmp_on_tab=1;
boolean def_linewrap=0;
boolean def_join_strips_spaces=true;
boolean def_reflow_next=0;
boolean def_pmatch_style=0;
boolean def_stay_on_cmdline=0;
boolean def_start_on_cmdline=0;
boolean def_start_on_first=0;
boolean def_exit_file_list=0;
int def_auto_restore=0;
int def_eclipse_switchbuf=1;
boolean def_eclipse_extensionless=true;
boolean def_eclipse_check_ext_mode=true;
boolean def_deselect_copy=1;
boolean def_deselect_paste=0;
boolean def_deselect_drop=0;
_str def_oemaddons_modules="";
//boolean def_ignore_tcase=1;
boolean def_keep_dir=0;
boolean def_from_cursor=0;   // Set to one in EMACS emul. Effects some word functions.
boolean def_unix_expansion=__UNIX__;  // Expand ~ and $ like UNIX shells.
boolean def_process_tab_output=1;  // Default build window output to tab in output toolbar
int def_help_flags=HF_CLOSE;
int def_mouse_menu_style=2;    // MM_MARK_FIRST
//boolean def_mouse_paste=__UNIX__;  // middle mouse button does paste
boolean def_brief_word=0;
boolean def_vcpp_word=0;
boolean def_subword_nav=0;
int def_cd=CDFLAG_CHANGE_DIR_IN_BUILD_WINDOW|CDFLAG_EXPAND_ALIASES_IN_CD_FORM;
int def_max_filehist=9;
int def_max_windowhist=9;
int def_max_workspacehist=9;
int def_actapp=ACTAPP_AUTORELOADON|ACTAPP_AUTOREADONLY;
int def_vcflags=VCF_SET_READ_ONLY;
int def_as_flags = AS_ASDIR;    // AutoSave flags
int def_restore_flags= RF_CWD|RF_PROJECTFILES|RF_WORKSPACE;
int def_init_delay=50;
int _display_wid=0;

int def_read_ahead_lines= 500;
int def_clipboards= 50;
int def_max_filepos=1000;
int def_compile_flags=COMPILEFLAG_CDB4COMPILE;
int def_max_fhlen=40;      // Maximum length of filenames under menus
int def_err=0;
int _config_modify=0;
int def_mfsearch_init_flags=MFSEARCH_INIT_HISTORY;
int def_exit_flags=EXIT_CONFIG_ALWAYS/*|EXIT_FILES_PROMPT*/;
int def_re_search=UNIXRE_SEARCH;
int _filepos_view_id=0;
#if __UNIX__
   boolean def_autoclipboard=1;
#else
   boolean def_autoclipboard=0;
#endif

boolean _no_mdi_bind_all=0;
boolean def_cfgfiles=1;
boolean def_localsta=1;
int def_max_autosave=500;//Largest file in K to autosave
int def_diff_options=0;  // Passed to DLL. Ignore leading,trailing...
int def_diff_edit_options=DIFFEDIT_AUTO_JUMP|DIFFEDIT_SHOW_GAUGE|DIFFEDIT_START_AT_FIRST_DIFF;
#if 1
int GMFDiffViewOptions=DIFF_VIEW_DIFFERENT_FILES|DIFF_VIEW_VIEWED_FILES|DIFF_VIEW_MISSING_FILES1|DIFF_VIEW_MISSING_FILES2|DIFF_VIEW_DIFFERENT_SYMBOLS|DIFF_VIEW_MISSING_SYMBOLS1|DIFF_VIEW_MISSING_SYMBOLS2;
int def_mfdiff_functions=1;
#else
int GMFDiffViewOptions=DIFF_VIEW_DIFFERENT_FILES|DIFF_VIEW_VIEWED_FILES|DIFF_VIEW_MISSING_FILES1|DIFF_VIEW_MISSING_FILES2;
int def_mfdiff_functions=0;
#endif
int def_smart_diff_limit=1000;
int def_max_fast_diff_size=800;
int def_diff_max_intraline_len=4096;
int def_diff_num_sessions=10;
boolean def_dragdrop=true;
int def_seldisp_flags=SELDISP_SHOWPROCCOMMENTS;
int def_seldisp_maxlevel=6;
int def_vcpp_flags=0; // VCPP_ADD_VSE_MENU;
int def_mfflags=1;
_str def_bgtag_options='30 10 3 600';
int def_buffer_retag=TAG_DEFAULT_BUFFER_RETAG_INTERVAL;
_str def_add_to_prj_dep_ext='.h .hpp .hxx';

_str def_cvs_global_options="";  // These are options passed to all cvs operations
                                 // before the command name
_str def_svn_global_options="";  // These are options passed to all cvs operations
                                 // before the command name
int _CVSDebug=0;

int def_cvs_flags=CVS_RESTORE_COMMENT;

_str def_cvs_shell_options='Q';
boolean def_updown_screen_lines=true;
_str _last_lang='';   // Last state file setting for lang

int def_wpselect_flags = 0;

boolean def_vcpp_bookmark = false;

#if __UNIX__
   boolean def_filelist_show_dotfiles = true;
#else
   boolean def_filelist_show_dotfiles = false;
#endif
boolean def_quick_start_was_shown = false;
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

#if __UNIX__
   #if __MACOSX__
   _str def_clipboard_formats = "H";
   #else
   _str def_clipboard_formats = "";
   #endif
#else
_str def_clipboard_formats = "H";
#endif
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
boolean def_auto_set_buffer_cache= true;

/*
   Turn off color coding if files larger than size below.
*/
long def_auto_set_buffer_cache_ksize= 100000;    // 100 megabytes
/*
   Use fundamental mode for files larger than ksize below.
*/
long def_use_fundamental_mode_ksize= 50000;    // 50 megabytes

/*
   Turn off undo if for files larger than ksize below.
*/
long def_use_undo_ksize= 100000;    // 100 megabytes

/**
 * This setting specifies the default mode name to use
 * when you drag the mouse in the MDI area in order to
 * create new windows.  If set to null or the empty string,
 * it will create a new window viewing the current file,
 * or a fundamental mode if there is no current window.
 *
 * @default null
 * @categories Configuration_Variables
 */
_str def_mouse_create_window_modename = null;

//Comment block autocompletion default
boolean def_auto_complete_block_comment = true;

//Default value for number of line comments needed for line comment wrapping
int def_cw_line_comment_min = 2;

/**
 * Maximum number of lines in a block comment or in a block of consecutive line 
 * comments that will be analyzed when trying to automatically determine the 
 * proper width on the comment. Comment wrapping will look analyze at most 
 * def_cw_analyze_lines_max number of lines above the cursor position and 
 * def_cw_analyze_lines_max number of lines below the cursor postion. 
 */
int def_cw_analyze_lines_max = 100;

//Comment wrap defaults
_str CW_commentWrapDefaultsStr = '0 1 0 1 1 64 0 0 80 0 80 0 80 0 0 1';
_str XW_xmlWrapDefaultsStr = '0 0 'XW_NODEFAULTSCHEME;
_str XW_xmlWrapDefaultsStrDocbook = '1 1 'XW_NODEFAULTSCHEME;
int CW_defaultFixedWidth = 64;
int CW_defaultRightMargin = 80;
int CW_defaultLineCommentMin = 2;
//XML/HTML formatting defaults
int def_xw_pre_tag_search_depth = 10;

/**
 * Default line comment mode. 
 */
COMMENT_LINE_MODE def_comment_line_mode = LEFT_MARGIN;

boolean def_disable_replace_tooltip = false;
boolean def_disable_postbuild_error_markers = false;
boolean def_disable_postbuild_error_scroll_markers = false;
int def_max_mffind_output = 2*1024*1024;
int def_max_search_results_buffers = 32;

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
boolean def_warn_about_vslickconfig=true;

defload()
{
   if ( find_index('st',COMMAND_TYPE) ) return;
   buildingStateFile=true;
   _default_keys=find_index('default-keys',EVENTTAB_TYPE);
   set_eventtab_index(_default_keys,event2index(F3),find_index('quit-view',COMMAND_TYPE));
   def_actapp&=~ACTAPP_AUTOREADONLY;
   execute('addons ',"");    // run the addons module to add all other modules.
   int status=rc;
   def_actapp|=ACTAPP_AUTOREADONLY;
   if ( status && status!=2 ) {
      process_make_rc(status,'addons');
   }
   if ( ! status) {
     clear_message();   // If messages at bottom, erase it.
   }

   // OEM-specific addons
   oemAddons();

#if KEEP
   get_fkeytext(text,option);
   if ( option!='S') {    // Zoom the window
      one_window();
   }
#endif

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
 * If the given path does not already end with a file separator, then we add 
 * one.  Use checkForQuotes = false to do a "dumb" check, where we simply look 
 * at the last character and add a file separator.  Set to true to do a smarter 
 * check that determines if the path is enclosed in double quotes, therefore 
 * checking the last character before the closing quote. 
 *  
 * If double quotes are found in the initial path, they will be in the final 
 * path.  No checking to determine if they are necessary is done.  That's your 
 * own business. 
 * 
 * @param path                      path to possibly add a filesep to
 * @param checkForQuotes            whether to check if the path is in quotes 
 *  
 * @categories File_Functions
 */
void _maybe_append_filesep(_str &path, boolean checkForQuotes = false)
{
   if (path == '') return;
   
   // maybe we have quotes all around us?
   if (checkForQuotes && substr(path, 1, 1) == '"' && substr(path, length(path), 1) == '"') {
      // strip them off
      path = strip(path, 'B', '"');
      if (substr(path, length(path), 1) != FILESEP) {
         path = path :+ FILESEP;
      }

      // add back the quotes
      path = '"'path'"';
   } else {
      if (substr(path, length(path), 1) != FILESEP) {
         path = path :+ FILESEP;
      }
   }

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
   _str result = '';
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
   int result = -1;
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

#define POSTINSTALL_MACRO_NAME    "postinstall.e"
#define OEMPOSTINSTALL_MACRO_NAME "oempostinstall.e"

/**
 * Do the post-install tasks
 */
static void DoPostInstall()
{
   // If we are NOT building the state file.
   if (editor_name('s')!='') {
      // checkout a license and/or display licensing dialog.
      _LicenseInit();
   }
   _str currentVersion;
   parse get_message(SLICK_EDITOR_VERSION_RC) with . . currentVersion . ;
   _str stateName = editor_name('s');
   if (compareVSEVersions(_post_install_version, currentVersion) < 0 && stateName != '') {
      // We may need to do some post-install tasks. If the version we last ran post-install
      // tasks is < the current version, then we need to run a post-install macro to complete
      // installation. This change was made to accommodate unattended installation.
      _str macro=get_env("VSROOT") :+ "macros":+FILESEP:+POSTINSTALL_MACRO_NAME;
      _str oem_postinstall_macro=get_env("VSROOT") :+ "macros":+FILESEP:+OEMPOSTINSTALL_MACRO_NAME;
      if ( file_exists(oem_postinstall_macro) ) {
         macro=oem_postinstall_macro;
      }
      int status=shell(maybe_quote_filename( macro ));
      _config_modify_flags(CFGMODIFY_MUSTSAVESTATE);
      _post_install_version = _version();
      _post_call(save_config);
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
   int cool_index = find_index("cool_features",COMMAND_TYPE);
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
int makeNload(_str module, boolean doLoad=true, boolean quiet=false)
{
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
   _load(filename,'r');
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
         p='r'p_RLine" "p_col " "p_hex_nibble" "p_cursor_y " "p_left_edge' 'p_LastModified' 'point();
      } else {
         p=point('l') " "p_col " "p_hex_nibble" "p_cursor_y " "p_left_edge' 'p_LastModified' 'point();
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
   int old_wid=p_window_id;
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
_command void quit_view() name_info(','VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
  _delete_window();
}

// Save _config_modify flags caused by a transfer configuration
// separate from _config_modify so user is not configused by
// Save Configuration? message_box.
static int gcfgTransferModifyFlags;

/**
 * Get or set the configuration modification flags.
 * The AND mask is applied first, then the OR flags.
 * <ul>
 * <li>CFGMODIFY_ALLCFGFILES -- for backward compatibility.
 *                              New macros should use the constants below.
 * <li>CFGMODIFY_DEFVAR -- set macro variable with prefix "def_"
 * <li>CFGMODIFY_DEFDATA -- set symbol with prefix "def_"
 * <li>CFGMODIFY_OPTION -- color, scroll style, insert state or
 *                         any option which the list_config
 *                         command generates source for.
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
 * saved to "vslick.sta" (UNIX: "vslick.stu") if you loaded new macro modules.
 * When the editor is invoked, the state file is loaded and then the source code
 * representing your configuration changes are applied.</p>
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
_command gui_save_config() name_info(','VSARG2_EDITORCTL)
{
   int status=_promptSaveConfig();
   if (status!=1) {
      return(status);
   }
   return(save_config());
}
int _promptSaveConfig() {
   _str msg = 'Configuration Not Saved';
   // IF no user config mods AND no automatic config mods
   if (!_config_modify && !gcfgTransferModifyFlags) return(0);
   // If running from Eclipse we need more descriptive message because
   // user cannot tell what configuration we are talking about
   if (isEclipsePlugin()) {
      msg = 'SlickEdit Core 'msg;
   }

   // IF user modified the configuration.
   if (_config_modify) {
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
 * Updates source code representing your configuration changes.
 * Source code representing your configuration changes is saved in the
 * files "vusrdefs.e" (UNIX: "vunxdefs.e"), "vusrobjs.e" (UNIX:
 * "vunxobjs.e"), and "vusrs<I>NNN</I>.e" (UNIX:
 * "vunxs<I>NNN</I>.e").  The state file will be saved to "vslick.sta"
 * (UNIX: "vslick.stu") if you loaded new macro modules.  When the
 * editor is invoked, the state file is loaded and then the source code
 * representing your configuration changes are applied.
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
_command int save_config(_str save_immediate='') name_info(','VSARG2_EDITORCTL)
{
   boolean cant_write_config_files=_default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
   if (cant_write_config_files) return(0);
   if (!_config_modify && !gcfgTransferModifyFlags) return(0);

   int old_config_modify=_config_modify;
   _config_modify|=gcfgTransferModifyFlags;
   int status=save_config2(save_immediate!='');
   if (status) {
      _config_modify=old_config_modify;
   } else {
      gcfgTransferModifyFlags=0;
   }
   return(status);
}
static void adjust_colors()
{
   typeless bg,fg,flags;
   parse _default_color(CFG_FUNCTION) with fg bg .;
   if (bg==fg) {
      parse _default_color(CFG_WINDOW_TEXT) with fg bg .;
      _default_color(CFG_FUNCTION,fg,bg);
   }
   parse _default_color(CFG_ATTRIBUTE) with fg bg .;
   if (bg==fg) {
      parse _default_color(CFG_FUNCTION) with fg bg flags;
      _default_color(CFG_ATTRIBUTE,fg,bg,flags);
   }
   parse _default_color(CFG_LINEPREFIXAREA) with fg bg .;
   if (fg==0x0 && bg==0xffffff) {
      // We might need to make this code path smarter in the
      // future
      parse _default_color(CFG_WINDOW_TEXT) with fg bg .;
      _default_color(CFG_LINEPREFIXAREA,fg,bg,0);
   } else if (bg==fg) {
      parse _default_color(CFG_WINDOW_TEXT) with fg bg .;
      _default_color(CFG_LINEPREFIXAREA,fg,bg,0);
   }
   parse _default_color(CFG_UNKNOWNXMLELEMENT) with fg bg .;
   if (bg==fg) {
      parse _default_color(CFG_WINDOW_TEXT) with fg bg .;
      _default_color(CFG_UNKNOWNXMLELEMENT,0x0080ff,bg,F_BOLD);
   }
   parse _default_color(CFG_XHTMLELEMENTINXSL) with fg bg .;
   if (bg==fg) {
      parse _default_color(CFG_PPKEYWORD) with fg bg .;
      _default_color(CFG_XHTMLELEMENTINXSL,0x0080ff,bg,F_BOLD);
   }

#if __UNIX__
   parse _default_color(CFG_STATUS) with fg bg . ;
   if (bg == 0xc0c0c0) {
      _default_color(CFG_STATUS, fg, 0x80000005, 0);
   }
   parse _default_color(CFG_MESSAGE) with fg bg . ;
   if (bg == 0xc0c0c0) {
      _default_color(CFG_MESSAGE, fg, 0x80000005, 0);
   }
#endif

   parse _default_color(CFG_BLOCK_MATCHING) with fg bg flags;
   if (fg == bg) {
      parse _default_color(CFG_WINDOW_TEXT) with fg bg .;
      _default_color(CFG_BLOCK_MATCHING, 0xff0000, bg, F_BOLD);
   }
}

#if !__UNIX__

#define NEW_VERSIONED_CONFIG_DIR_NAME     "My SlickEdit Config"
#define NEW_ECLIPSE_VERSIONED_CONFIG_DIR_NAME     "My SlickEdit Core Config"

#else

#define NEW_VERSIONED_CONFIG_DIR_NAME     ".slickedit"
#define NEW_ECLIPSE_VERSIONED_CONFIG_DIR_NAME     ".secore"

#endif


#if !__UNIX__
static void _PostTransferCfgToAppData()
{
   xfer_helpidx_filename=xfer_helpidx_filename;
   if( xfer_helpidx_filename!='' ) {
      def_helpidx_filename=xfer_helpidx_filename;
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   xfer_wh=xfer_wh;
   if( xfer_wh!='' ) {
      def_wh=xfer_wh;
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
}

static void _TransferCfgToAppDataPath()
{
    _str list[];

   xfer_helpidx_filename='';
   xfer_wh='';

   _str vsroot=get_env('VSROOT');
   _str dest_path=_ConfigPath();

   list._makeempty();
   // These are all relative to VSROOT
   list[list._length()]=VSCFGFILE_USER_BOX;
   list[list._length()]=VSCFGFILE_USER_COLORSCHEMES;
   list[list._length()]=VSCFGFILE_USER_VCS;
   list[list._length()]='usrpacks.slk';
   list[list._length()]=VSCFGFILE_USER_FTP;
#if __UNIX__
   list[list._length()]='uproject.slk';   // Move old 7.0 file
#else
   list[list._length()]='project.slk';    // Move old 7.0 file
#endif
   list[list._length()]=VSCFGFILE_USER_PRINTSCHEMES;
   list[list._length()]=VSCFGFILE_ALIASES;
   list[list._length()]=VSCFGFILE_USER_BEAUTIFIER;
   list[list._length()]='macros':+FILESEP:+USERMACS_FILE:+_macro_ext;
   //list[list._length()]='macros':+FILESEP:+USERMACS_FILE:+_macro_ext'x';
   list[list._length()]='win':+FILESEP:+_WINDOW_CONFIG_FILE;
   list[list._length()]='win':+FILESEP:+_INI_FILE;
   list[list._length()]='macros':+FILESEP:+USERDEFS_FILE:+_macro_ext;
   //list[list._length()]='macros':+FILESEP:+USERDEFS_FILE:+_macro_ext'x';
   list[list._length()]='macros':+FILESEP:+USEROBJS_FILE:+_macro_ext;
   //list[list._length()]='macros':+FILESEP:+USEROBJS_FILE:+_macro_ext'x';
   list[list._length()]='macros':+FILESEP:+_getUserSysFileName():+_macro_ext;
   //list[list._length()]='macros':+FILESEP:+_getUserSysFileName():+_macro_ext'x';
   list[list._length()]=USERCPP_FILE;
   list[list._length()]=USER_LEXER_FILENAME;
   list[list._length()]='diffmap.ini';
   list[list._length()]='filepos.slk';
   _str old_path,filename;
   if( def_helpidx_filename!='' ) {
      // Change def_helpidx_path so moved help index file is found
      old_path=_strip_filename(_replace_envvars(def_helpidx_filename),'N');
      filename=_strip_filename(_replace_envvars(def_helpidx_filename),'P');
      if( file_eq(old_path,vsroot) ) {
         list[list._length()]=filename;
         xfer_helpidx_filename=dest_path:+filename;
         //def_helpidx_filename=dest_path:+filename;
      }
   }
   if( def_wh!='' ) {
      // Any help index files referenced in def_wh that reside in VSROOT
      // will be moved, and the paths stored will be updated.
      _str wh1,wh2,wh3,rest;
      parse def_wh with wh1 ';' wh2 ';' wh3 ';' rest;
      _str new_wh='';
      old_path=_strip_filename(_replace_envvars(wh1),'N');
      filename=_strip_filename(_replace_envvars(wh1),'P');
      if( file_eq(old_path,vsroot) ) {
         list[list._length()]=filename;
         new_wh=new_wh:+dest_path:+filename;
      }
      if( wh2!='' ) {
         old_path=_strip_filename(_replace_envvars(wh2),'N');
         filename=_strip_filename(_replace_envvars(wh2),'P');
         if( file_eq(old_path,vsroot) ) {
            list[list._length()]=filename;
            new_wh=new_wh';'dest_path:+filename;
         }
      }
      if( wh3!='' ) {
         old_path=_strip_filename(_replace_envvars(wh3),'N');
         filename=_strip_filename(_replace_envvars(wh3),'P');
         if( file_eq(old_path,vsroot) ) {
            list[list._length()]=filename;
            new_wh=new_wh';'dest_path:+filename;
         }
      }
      if( rest!='' ) {
         new_wh=new_wh';'rest;
      }
      if( new_wh!='' ) {
         xfer_wh=new_wh;
         //def_wh=new_wh;
      }
   }

   // Copy user config files
   typeless i;
   int status=0;
   _str src,dest;
   for( i=0;i<list._length();++i ) {
      src=vsroot:+list[i];
      dest=dest_path:+_strip_filename(list[i],'P');
      // Ignore status
      //say('copying - src='src'  dest='dest);
      status=copy_file(src,dest);
   }

   // Copy vusrs*.e
   src=file_match(vsroot'macros\vusrs*.e',1);
   for(;;) {
      if( src=='' ) break;
      dest=dest_path:+_strip_filename(src,'P');
      // Ignore status
      //say('copying - src='src'  dest='dest);
      status=copy_file(src,dest);
      src=file_match(vsroot'macros\vusrs*.e',0);
   }

   // Copy *.als
   src=file_match(vsroot'*.als',1);
   for(;;) {
      if( src=='' ) break;
      dest=dest_path:+_strip_filename(src,'P');
      // Ignore status
      //say('copying - src='src'  dest='dest);
      status=copy_file(src,dest);
      src=file_match(vsroot'*.als',0);
   }

}
#endif
#if __UNIX__
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
      };
int _usingXftFonts();
static void _saveDefaultFonts(DEFAULT_FONTS &df,boolean &maybeRestoreFonts)
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
}
static void _maybe_keep_default_font(int cfg, _str old_font)
{
   _str name,rest;
   parse _default_font(cfg) with name',' rest;
   if (strieq(name,"adobe-helvetica") ||
       strieq(name,"adobe-courier")
#if !__UNIX__
       || strieq(name,"Courier New")
#endif
       ) {
      //say('restored 'cfg' to 'old_font);
      _default_font(cfg,old_font);
   }
}
static void _maybeRestoreDefaultFonts(DEFAULT_FONTS &df,boolean maybeRestoreFonts)
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

/**
 * Load the macros the user has specified in def_macfiles. 
 */
static void apply_user_macros(_str user_macfiles) 
{
   // deal with duplicate modules in def_macfiles
   // this should not be possible, but no harm in guarding
   // against it so we do not incorrectly report it as
   // a module name conflict.
   boolean been_there_done_that:[];

   // string containing a list of modules that errored out
   errorFiles := "";

   // for each module
   foreach (auto module in user_macfiles) {

      // no more modules?
      if (module=='') break;
      module = strip(module, "B", "\"");

      // get just the module name, no path
      module_name := _strip_filename(module,'P');

      // already saw this one?
      if (been_there_done_that._indexin(_file_case(module_name))) continue;
      been_there_done_that:[_file_case(module_name)] = true;

      // toss out delphi.ex
      if (file_eq(module_name,'delphi.ex')) {
         continue;
      }

      // check if this module is already loaded, if it is, it means they
      // have a user module whose name conflicts with the name of a module
      // that we ship with SlickEdit.  Do not allow them to load a module
      // with a name conflict.
      int index=find_index(module_name,MODULE_TYPE|DLLMODULE_TYPE);
      if (index) {
         _macfile_delete(module_name,'');
         if (def_oemaddons_modules == "" || pos(module_name,def_oemaddons_modules) == 0) {
            errorFiles = errorFiles :+ "CONFLICT:\t" :+ module :+ "\n";
         }
         continue;
      }

      // get the file extension, should be either .ex, .dll, or .so (Unix) 
      filename := "";
      ext := _get_extension(module_name);

      // If this is a Slick-C macro
      if (file_eq(ext,'ex')) {
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
            if (file_match('-p 'maybe_quote_filename(filename),1)=='') {
               filename=_ConfigPath():+substr(module,1,length(module));
               // look for the macro pcode using the original source directory.
               filename=file_match('-p 'maybe_quote_filename(filename),1);
            }
            if (filename=='') {
               filename=_ConfigPath():+substr(module,1,length(module)-1);
               if (file_match('-p 'maybe_quote_filename(filename),1)=='') {
                  filename=_ConfigPath():+substr(module,1,length(module));
                  filename=file_match('-p 'maybe_quote_filename(filename),1);
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
      }

      // now load the module or DLL
      if (filename!='') {
         // Use suspend/resume so that if a Slick-C stack happens,
         // we can pick up and load as many modules as possible.
         _suspend();
         if (!rc) {
            if (file_eq(ext,'ex')) {
               if (load(filename) != 0) {
                  errorFiles = errorFiles :+ "COMPILE ERROR:\t" :+ filename :+ "\n";
                  _macfile_delete(module_name,'');
               }
            } else {
               dload(filename);
            }
            rc=1;
            _resume();
         } else if (rc!=1) {
            errorFiles = errorFiles :+ "ERROR:\t" :+ filename :+ "\n";
            if (file_eq(ext,'ex')) {
               // unload modules that error, otherwise they will error
               // again in their definit() and the editor will not
               // be able to come up.
               unload(_strip_filename(module_name,'P'));
            }
         }
      } else {
         // if the file is missing, then remove it from def_macfiles
         // and report that it is missing.
         _macfile_delete(module_name,'');
         errorFiles = errorFiles :+ "MISSING:\t" :+ module :+ "\n";
      }
   }

   // report whatever errors occurred loading user macros
   if (errorFiles != "") {
      _message_box("There were errors loading the following user modules (from def_macfiles).\n\n":+errorFiles);
   }
}

void _firstinit()
{
   // This useless looking assignment ensures that this variable does not get removed
   // when writing the state file. p_copy_color_coding_to_clipboard_op references
   // this macro variable.
   def_max_html_clipboard_ksize=def_max_html_clipboard_ksize;
   // This is used by open_temp_view and must be initialized early
   _filepos_view_id=0;
   _per_file_data_init(_ConfigPath(), def_max_filepos);
   _set_ant_options((int)def_antmake_identify, def_max_ant_file_size);
   def_file_name_map_init_c_value = false;

   boolean cant_write_config_files=_default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
   if (!cant_write_config_files) {
      _CheckForObsoleteEnvironment();
   }

   int status=0;
   _str old_default_config = "";
   _str new_default_config = "";

   config_migrated_from_version := "";
   boolean transfered_directory=false;
   if (!cant_write_config_files) {
      transfered_directory = _TransferCfgToNewDirectory(old_default_config, new_default_config);
      if( transfered_directory ) {
         // Also clear out old sample workspaces
         upgrade_workspace_manager();
      }
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
         if (pos("^[0-9]*[.][0-9]*[.][0-9]*$", config_migrated_from_version, 1, 'r') <= 0) {
            config_migrated_from_version = "10.0.0";
         }
      }
   }

   _save_origenv();
   _project_name='';_project_DebugCallbackName='';_project_DebugConfig=false;
   _project_extTagFiles = ''; _project_extExtensions = '';
   _workspace_filename='';
   gActiveConfigName="";
   gActiveTargetDestination="";
   gWorkspaceHandle=-1;
   gProjectHashTab._makeempty();
   gProjectExtHandle= -1;
   gxmlcfg_help_index_handle=0;


#if __OS390__ || __TESTS390__
   parse get_env('DISPLAY') with debugip':';
   set_env('DEBUGIP',debugip);
   if (get_env('PATH') == '') {
      set_env('PATH', '/bin');
   }
#endif
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
   _str path='';
   _str statename=editor_name('s');
   if (statename!='') {
      //statepath=strip_filename(statename,'n');
      path=_ConfigPath();
   } else {
      _mdi._ShowWindow();  // Show window using OS argument
      _cmdline.p_visible=0;
   }

   // We do not want the command line to auto-select if it
   // loses and regains focus, for example when a symbol mouse-over
   // help window pops up even though it's using SW_SHOWNOACTIVATE.
   // To test this issue, go to the command line, type a partial command,
   // then move the mouse to cause a mouse-over help dialog to display.
   // Without this change, the text on the command line would wind up 
   // getting selected.
   _cmdline.p_auto_select=0;

   boolean bool=statename!='' /*&& !file_eq(path,statepath)*/ && def_cfgfiles;

   // IF we are not creating a state file AND user wants cfg files
   //    AND user wants local state file
   if (bool && def_localsta) {
      bool=false;
      // Not sure if we will always want to compare directories.  Its
      // a weird case where user specified state file from command line.
      //
      if (_default_option(VSOPTION_APPLY_LOCAL_STATE_FILE_CHANGES)) {
         //_message_box('VSOPTION_APPLY_LOCAL_STATE_FILE_CHANGES');
         bool=true;
         /*
            (Clark) 
            We have dropped support for CLASSIC CONFIG (windows single user).  
            Configuration changes could be lost.
         */
      }
   }
   if (bool && !cant_write_config_files) {
      _SplashScreenStatus("Migrating configuration settings...");
#if !__UNIX__
      if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ECLIPSE_PLUGIN) {
         get_env(_VSECLIPSECONFIGVERSION);
      } else {
         get_env(_SLICKCONFIG);
      }
      status=rc;
      if (status) {
         path=_macro_path();
      }
#endif

#if __UNIX__
      DEFAULT_FONTS df;
      boolean maybeRestoreFonts;
      _saveDefaultFonts(df,maybeRestoreFonts);
#endif

      // Must run _getUserSysFileName() first so have correct button bar resource.
      // USERDEFS_FILES sets button bar.
      _in_firstinit=1;
      _str filename=maybe_quote_filename(path:+_getUserSysFileName():+_macro_ext);
      boolean usersyso_exists=false;
      if(file_match('-p 'filename,1)!='' ) {
         status=shell(filename);
         //messageNwait('status h2='status);
         usersyso_exists=true;
      }
      _no_mdi_bind_all=1;
      int old_modify=_config_modify;
      filename=maybe_quote_filename(path:+USERDEFS_FILE:+_macro_ext);
      _str vuserdefs_filename='';
      if(file_match('-p 'filename,1)!='' ) {
         vuserdefs_filename=filename;
         status=shell(filename);
         if (!status) {
            def_emulation_was_selected=true;
            if (def_color_scheme_version == COLOR_SCHEME_VERSION_DEFAULT) {
               if (substr(config_migrated_from_version, 1, 2) == "14") {
                  def_color_scheme_version = COLOR_SCHEME_VERSION_CURRENT;
               } else {
                  def_color_scheme_version = COLOR_SCHEME_VERSION_PREHISTORIC;
               }
            }
         }
      }
      _config_modify=old_modify;
      _no_mdi_bind_all=0;
      filename=maybe_quote_filename(path:+USERMACS_FILE:+_macro_ext);

      if(file_match('-p 'filename,1)!='' ) {
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
            status=_load(filename,'r');
         }
      }
      // Load all user add macro files and DLLs
      int index=0;
      _str name;
      parse def_keys with name '-keys';
      if (name=='') {
         name='slick';
      } else if (name=='gnuemacs') {
         name='gnu';
      }
      
      if (
           #if __MACOSX__
           name!='macosx'
           #else
           name!='windows'
           #endif
          ) {
         _str module='emulate.ex';
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
         status=shell(maybe_quote_filename(filename)' 'name);
         //_message_box('status='status);
         if (status) {
            _message_box(nls('unable to switch to %s1 emulation',name));
         } else {
            def_emulation_was_selected=true;
         }
         if(vuserdefs_filename!='') {
            shell(vuserdefs_filename);
         }
      }

      // We must have this for epsilon emulation.
      // Go ahead and do it for any configuration,
      // if several users complain, we can change this.
      int kt_index=find_index('default_keys',EVENTTAB_TYPE);
      set_eventtab_index(kt_index,event2index(name2event('A-.')),find_index('list_symbols',COMMAND_TYPE));
      set_eventtab_index(kt_index,event2index(name2event('A-,')),find_index('function_argument_help',COMMAND_TYPE));
      set_eventtab_index(kt_index,event2index(name2event('M- ')),0);

      // Notify call-list about event table changes
      call_list('_eventtab_modify_',kt_index,'');


      filename=maybe_quote_filename(path:+USEROBJS_FILE:+_macro_ext);
      if(file_match('-p 'filename,1)!='' ) {

         // update icons to match latest version of editor
         shell("updateobjs ":+filename);

         // now run vusrobjs
         status=shell(filename);
         //messageNwait('status h2='status);
      }

      if (isEclipsePlugin()) {
         _str r = get_env("VSROOT");
         if (r != '') {
            _str r_t = _unquote_filename(r);
            _str bmr = r_t :+ "bitmaps";
            if (!(r_t :== r)) {
               bmr = maybe_quote_filename(bmr);
            }
            set_env("VSLICKBITMAPS",bmr);
         }
      }

      // reload tool window bitmaps if the size has changed
      tbReloadBitmaps();

      if (def_localsta) {
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

      _UpgradeLanguageSetup();

      if (config_migrated_from_version != "") {
         // Avoid homogonizing the user's brace settings for anything other 
         // than a version upgrade from a pre-new-beautifier version.
         parse config_migrated_from_version with auto major '.' auto minor '.' auto revision '.' .;

         if ((int)major < 17) {
            _UpgradeBeautifier();
         } else {
            _UpgradeBeautifierSettings();
         }
      } else if (!transfered_directory) {
         _post_call(_SetupBeautifier);
      }

      _UpgradeExtensionSetup();
      _UpgradeColorScheme();
      _UpgradeSymbolColoringScheme();
      _UpgradeAutoCompleteSettings(config_migrated_from_version);
      _post_call(_MigrateV14SymbolColoringOptions,  config_migrated_from_version);

      // existing users do not need to be told about features they already know about
      _UpgradeNotificationLevels(config_migrated_from_version);
      // we split alias expansion from syntax expansion
      _UpgradeLanguageAliasExpansion(config_migrated_from_version);
      // we added extensionless file handling for all languages
      _UpgradeExtensionlessFiles(config_migrated_from_version);
      // added {} option
      _UpgradeAutoBracketSettings(config_migrated_from_version);
      // moved code into C++, changed file format to XML
      _UpgradeFileposData();
      // update toolbars
      _UpdateToolbars();
      // turn off def_vcpp_flags
      _UpgradeVCPPFlags(config_migrated_from_version);
      // convert existing macros
      _UpgradeAliases(config_migrated_from_version);
      // automate url mappings
      _UpdateURLMappings();

      _in_firstinit=0;
      if (old_default_config != '') {
         _cleanup_old_tagfiles(old_default_config);
      }
      //_UpdateKeyBindings();
#if !__UNIX__
      _PostTransferCfgToAppData();
#else
      if (old_default_config!='') {
         _maybeRestoreDefaultFonts(df,maybeRestoreFonts);
      }
#endif

      // we need to do this before calling apply_user_macros - it may get called 
      // again later, but that's no big deal
      if(transfered_directory) {
         change_def_macfiles_location(old_default_config, new_default_config);
      }

      // Delayed gratification teaches patience.  It also saves 
      // us from dying before the editor is ready to run.
      _post_call(apply_user_macros, def_macfiles);
   }

   if( def_focus_select && def_cde_workaround &&
       (machine()=='SPARCSOLARIS' || machine()=='INTELSOLARIS') ) {
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

   // if their old tag file cache size is larger than the new tag file cache maximum
   // make the maximum match their existing setting
   if (def_tagging_cache_max < def_tagging_cache_size) {
      def_tagging_cache_max = def_tagging_cache_size;
   }

   // 6.4.09 - 10770 - sg- we no longer use the New Project Wizard
   def_launch_new_project_wizard = false;

   // 6.16.10 - 10583 - Added option to restore workspace when 
   // we start - defaults to TRUE
   if (config_migrated_from_version != '' && _version_compare(config_migrated_from_version, '15.0.1.0') < 0) {
      def_restore_flags |= RF_WORKSPACE;
   }

   _config_modify=0;
   // IF we have a 2.0 constant value for UNIXRE_SEARCH
   if (def_re_search==0x80) {
      // convert it to the new 3.0 value
      def_re_search=UNIXRE_SEARCH;
   }
   adjust_colors();
   _str filename='';
   _str new_lang=_default_option(VSOPTIONZ_LANG);
   if (_last_lang!=new_lang) {
      path=get_env('VSROOT'):+'macros':+FILESEP;
      if (new_lang=='') {
         filename=path:+SYSOBJS_FILE:+".e";
      } else {
         filename=path:+SYSOBJS_FILE'_'new_lang:+".e";
      }
      if(file_match('-p "'filename'"',1)!='' ) {
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
   _str binPath=get_env('VSLICKBIN1');
   _str dllPath=binPath:+'vsdebug.dll';
   if ( !file_exists(dllPath) ) {
      gMissingDllList=gMissingDllList:+' vsdebug.dll';

      dllPath=binPath:+'vchack.dll';
      if ( !file_exists(dllPath) ) {
         gMissingDllList=gMissingDllList:+' vchack.dll';
      }
   }
   dllPath=binPath:+'vsrefactor.dll';
   if ( !file_exists(dllPath) ) {
      gMissingDllList=gMissingDllList:+' vsrefactor.dll';
   }

   if(transfered_directory) {
      change_ext_tagfiles_location(old_default_config, new_default_config);
      change_def_macfiles_location(old_default_config, new_default_config);
   }

   if (transfered_directory) {
      // ensure that VSLICKBACKUP is reloaded from ini
      if (file_exists(_ConfigPath():+_INI_FILE)) {
         _str value = "";
         status = _ini_get_value(_ConfigPath():+_INI_FILE, "Environment", "VSLICKBACKUP", value);
         if ( !status ) {
            set_env("VSLICKBACKUP", value);
         }
      }
   }

   // start up the pip, and maybe do a send on startup
   if (index_callable(find_index("_pip_startup", PROC_TYPE))) {
      _post_call(_pip_startup);
   }
   if (index_callable(find_index("_hotfix_startup", PROC_TYPE))) {
      _post_call(_hotfix_startup);
   }

   // initialize the file name mapper, if it hasn't been done already
   if (index_callable(find_index("_InitializeFileNameMapping", PROC_TYPE))) {
      remap := (config_migrated_from_version != '' && _version_compare(config_migrated_from_version, '18.0.0.0') < 0);
      _post_call(_InitializeFileNameMapping, remap);
   }
}

definit()
{
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
int _autoRestoreFinished()
{
   return gAutoRestoreFinished;
}

#define DEFMAIN_OPTIONS 'H R P # SUT FN MDIHIDE'
defmain()
{
   boolean cant_write_config_files=_default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
   _setup_jaws_mode();
   _hit_defmain=true;
   gAutoRestoreFinished = 0;
   /*
      Here we call dllinit functions.  These dllinit functions
      must be called before autorestore.
   */
   call_list("dllinit_");

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
  _str macro_program='';
  _str terminal_file_spec='';
  _str restore_options;
  if (def_auto_restore) {
     restore_options="I";
  } else {
     restore_options="IN";
  }
  _str restore_options2 = restore_options;
  boolean mdi_menu_loaded=false;
  _project_name="";_project_DebugCallbackName="";_project_DebugConfig=false;
  _project_extTagFiles = ""; _project_extExtensions = "";
  _workspace_filename="";
  _str ExecList[];
  _str option;
  _str filename,ext;
  boolean mdihide=false;
  boolean no_exit=false;
  boolean do_workspace_opened_calllist=true;
#if __MACOSX__
  // Strip off the -psn_X_YYYYYY process serial # argument
  // We don't want it showing up as an edit command in the 
  // command history
  cmdline = stranslate(cmdline, '', '[^\-]\-psn[0-9_]+', "L");
#endif
  workspaceToOpen := '';
  origRestoreOptions := 0;
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
           if (!mdi_menu_loaded) {
              mdi_menu_loaded=true;
              _load_mdi_menu();
           }
           _str temp=cmdline;
           filename=strip(parse_file(temp),"B",'"');
           ext=_get_extension(filename,true);
           if (file_eq(ext,PRJ_FILE_EXT) ||
               file_eq(ext,WORKSPACE_FILE_EXT) ||
               file_eq(ext,VISUAL_STUDIO_SOLUTION_EXT) ||
               file_eq(ext,VCPP_PROJECT_WORKSPACE_EXT) ||
               file_eq(ext,TORNADO_WORKSPACE_EXT)
               ) {

              // save this to open later - we need to wait until the toolbars are up and running
              workspaceToOpen = filename;
              origRestoreOptions = def_restore_flags;
              def_restore_flags &= ~RF_WORKSPACE;

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
        _str rest=strip(parse_file(cmdline),'B','"');
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
  if (!mdi_menu_loaded && !mdihide) {
     _load_mdi_menu();
  }
#if KEEP
  /* Create the menu bar window. */
  index=find_index('one-window',COMMAND_TYPE);
  if ( index_callable(index) ) {
     call_index(index);
  }
#endif

  // Set Closable MDI document tabs before we autorestore everything
  if ( !mdihide ) {
     _mdi.p_ClosableTabs = def_document_tabs_closable;
  }

  int focus_wid=0;
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
     if (cmdname!='restore') {
        // No files are restore here.
        if (!mdihide) {
           restore(restore_options2);
        }
        if (macro_program=="lmw") {
           if (editor_name('s')!='') {
              // checkout a license and/or display licensing dialog.
              _LicenseInit();
           }
        } else {
           execute(macro_program,"");
        }
     } else {
        if (!mdihide) {
           gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_DISABLE;
           execute(macro_program,"");
           gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_ENABLE;
        }
     }

     // now that we've restored everything else, open the workspace specified
     if (workspaceToOpen != '') {
        workspace_open(workspaceToOpen,"","I");
        def_restore_flags = origRestoreOptions;
        }
        doExecList(ExecList);
     /*if (index_callable(find_index('_restore_all_bookmarks',PROC_TYPE))) {
        _restore_all_bookmarks();
     } */

     st_batch_mode=0;
     if ( rc=='' ) { rc=0; }
     if ( no_exit ) {
        if ( def_start_on_cmdline ) {
           cursor_command();
        }
        DoPostInstall();

        // 1.13.09 - this has been moved into the quick start - sg
        // ShowCoolFeatures();
        _use_timers=1;

        if (_workspace_filename!='' && do_workspace_opened_calllist) {
           focus_wid = _get_focus();
           call_list('_prjopen_');
           if (focus_wid) focus_wid._set_focus();

           call_list('_workspace_opened_');
        }
        gAutoRestoreFinished = 1;
        stop();
     }
     exit(rc);
  }
  /* insert the user's command into the command retrieve file.*/
  restore(restore_options2);
  gAutoRestoreFinished = 1;
  
  append_retrieve_command('e 'strip(cmdline));

  // now that we've restored everything else, open the workspace specified
  if (workspaceToOpen != '') {
     _SplashScreenStatus("Opening workspace: "_strip_filename(workspaceToOpen,'P'));
     workspace_open(workspaceToOpen,"","I");
     def_restore_flags = origRestoreOptions;
  }

  doExecList(ExecList);
#if _MDI_INTERFACE
  if (cmdline!='' ) {
     if (orig_cwd!=getcwd()) {
        _str new_cwd=getcwd();
        chdir(orig_cwd,1);
        edit(cmdline,EDIT_DEFAULT_FLAGS);
        chdir(new_cwd,1);
     } else {
        edit(cmdline,EDIT_DEFAULT_FLAGS);
     }
  }
#else
  empty_file_buf_id=p_buf_id;
  if ( cmdline!='' ) {
     edit(cmdline,EDIT_DEFAULT_FLAGS);
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
  if ( def_start_on_cmdline ) {
     cursor_command();
  }
  if (_workspace_filename!='' && do_workspace_opened_calllist) {
     focus_wid = _get_focus();
     call_list('_prjopen_');
     if (focus_wid) focus_wid._set_focus();

     call_list('_workspace_opened_');
  }

  /* Running SLICK inside build window? */
  //if ( get_env('SLKRUNS')==1 ) {
  //   /* Get out of here. */
  //   exit(1)
  //}
  /*if (index_callable(find_index('_restore_all_bookmarks',PROC_TYPE))) {
     _restore_all_bookmarks();
  } */
  DoPostInstall();
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
void process_make_rc(_str error_code,_str module, boolean quiet = false)
{
  if ( error_code ) {
     /* messageNwait('error_code='error_code' module='module) */
    int index=find_index('st',COMMAND_TYPE);
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
      } else exit(1);
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
   //9:36am 7/2/1998
   //This frees the handle to vsscc.dll that is loaded by vshlp.dll in
   //_InsertProjectFileList.
   //If this doesn't happen, the editor crashes on exit w/o any debug info
   //(Not even a cancel button)
   if (machine()=='WINDOWS' && index_callable(find_index('_FreeSccDll',PROC_TYPE))) {
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
 * files such as "vslick.sta" (UNIX: "vslick.stu") and 
 * "alias.als.xml". 
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
   _str new_name='';
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
   _str new_name='';
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
   if (subdir!='' && last_char(subdir)!=FILESEP) {
      subdir=subdir:+FILESEP;
   }
   _str filename=usercfg_path_search(name,subdir);
   _str new_user_file=_ConfigPath():+subdir:+name;
   if (!file_eq(filename,new_user_file)) {
      // Backup the previous local configuration file.
      copy_file(new_user_file,new_user_file'.bak');
      // Overwrite the local config file with the global user config file
      copy_file(filename,new_user_file);
   }
   return(new_user_file);
}
static int _MigrateChanges(_str name)
{
   switch (_file_case(name)) {
   case VSCFGFILE_USER_EXTPROJECTS:
   case VSCFGFILE_USER_PRJTEMPLATES:
      return(def_migrate_flags&VSMIGFLAG_PACKAGES);
   case VSCFGFILE_USER_BOX:
      return(def_migrate_flags&VSMIGFLAG_COMMENTSTYLE);
   case VSCFGFILE_USER_FTP:
      return(def_migrate_flags&VSMIGFLAG_FTP);
   case VSCFGFILE_USER_COLORSCHEMES:
      return(def_migrate_flags&VSMIGFLAG_COLORSCHEMES);
   case VSCFGFILE_USER_PRINTSCHEMES:
      return(def_migrate_flags&VSMIGFLAG_PRINTSCHEMES);
   case VSCFGFILE_USER_BEAUTIFIER:
      return(def_migrate_flags&VSMIGFLAG_BEAUTIFIER);
   case VSCFGFILE_USER_VCS:
      return(def_migrate_flags&VSMIGFLAG_VCS);
   case VSCFGFILE_ALIASES:
      return(def_migrate_flags&VSMIGFLAG_ALIASES);
   }
   _str ext=_get_extension(name);
   switch (_file_case(ext)) {
   case 'als':
      return(def_migrate_flags&VSMIGFLAG_ALIASES);
   case 'vlx':
      return(def_migrate_flags&VSMIGFLAG_COLORCODING);
   }
   return(0);
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
   if (subdir!='' && last_char(subdir)!=FILESEP) {
      subdir=subdir:+FILESEP;
   }
   typeless global_date=0;
   _str global_filename='';
   _str vslickmisc=strip(get_env('VSLICKMISC'),'B',PATHSEP);
   if (!pos(PATHSEP,vslickmisc)) {
      global_filename=vslickmisc;
      if (last_char(global_filename)!=FILESEP) {
         global_filename=global_filename:+FILESEP;
      }
      global_filename=global_filename:+subdir:+name;
      global_date=_file_date(global_filename,'B');
      if (global_date=='' || global_date==0) {
         global_filename='';
      }
   } else {
      global_filename=path_search(subdir:+name,_SLICKMISC,'s');
   }

   _str local_filename=_ConfigPath():+subdir:+name;
   _str local_date=_file_date(local_filename,'B');

   // IF we are not migrating sysadmin configuration changes to users
   if (!_MigrateChanges(name)) {
      if (file_exists(local_filename)) {
         return(local_filename);
      }
      return(global_filename);
   }

   if (global_filename!='') {
      if (local_date=='' || local_date==0 || file_eq(local_filename,global_filename)) {
         return(global_filename);
      }
      if (global_date=='' || global_date==0) {
         global_date=_file_date(global_filename,'B');
      }
      if (local_date>global_date) {
         return(local_filename);
      }
      return(global_filename);
   }
   if (local_date=='' || local_date==0) {
      return('');
   }
   return(local_filename);
}
_str misc_path_search(_str name, _str options="")
{
   if ( get_env(_SLICKMISC)=='' ) {
      return(slick_path_search1(name,options));
   }
   _str filename=path_search(name,_SLICKMISC,'s'options);
   if (filename=='' && file_eq(_get_extension(name),'hlp')) {
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

/**
 * Updates how language settings are stored.  In case user has any old-style 
 * language settings lying around, we update them to the new style. 
 * 
 * @param moduleLoaded 
 */
void _UpgradeLanguageSetup(_str moduleLoaded="")
{
   // might change a language option, so clear cache
   index := find_index("_ClearDefaultLanguageOptionsCache");
   if (index > 0) {
      call_index(index);
   }
 
   /** 
    * "def-setup-[ext]" is no longer used for extension setup in SE 2008. 
    * Instead we use "def-lang-for-ext-[ext]" and "def-language-[lang]". 
    * The purpose of this code is to migrate those settings appropriately. 
    */
   names := "";
   index = name_match('def-setup-',1,MISC_TYPE);
   while (index > 0) {
      names :+= ("\t" :+ name_name(index) :+ "\n");
      name := substr(name_name(index),11);
      info := name_info(index);
      delete_name(index);
      if (substr(info,1,1)=='@') {
         index = find_index('def-lang-for-ext-'name);
         if (!index) {
            insert_name('def-lang-for-ext-'name,MISC_TYPE,substr(info,2));
         } else {
            set_name_info(index, substr(info,2));
         }

      } else {
         index = find_index('def-language-'name);
         if (!index) {
            insert_name('def-language-'name,MISC_TYPE,info);
         } else {
            set_name_info(index, info);
         }

         index = find_index('def-lang-for-ext-'name);
         if (!index) {
            insert_name('def-lang-for-ext-'name,MISC_TYPE,name);
         } else {
            set_name_info(index, name);
         }
      }
      // next please
      index = name_match('def-setup-',1,MISC_TYPE);
   }

   if (moduleLoaded != "" && names != '') {
      _message_box(nls("The module '%s'\n":+
                       "defines the following variables which are no longer used:\n":+
                       "\n":+
                       "%s\n":+
                       "def-setup-[ext]* has been replaced with def-language-[langid] and\n":+
                       "file extensions are mapped to languages using def-lang-for-ext-[ext]\n":+
                       "\n":+
                       "The settings have been automatically migrated, but we recommend\n":+
                       "revising your code to create the correct settings using\n":+
                       "_CreateLanguage() and _CreateExtension().",
                       moduleLoaded,names));
   }

   // these things used to be in _UpgradeExtensionSetup, but they deal with how values 
   // are stored, rather than what value defaults should be, so I moved them here - sg

   // change storage of word chars in SE 2010 - sg
   // get language specific primary extensions
   wordChars := '';
   typeless start, rest;
   index = name_match('def-language-',1,MISC_TYPE);
   for (;;) {
     if ( ! index ) { break; }
     langID := substr(name_name(index),14);

     info := name_info(index);
     parse info with start 'WC='wordChars',' rest;

     if (wordChars != '' && wordChars != 'N/A') {
        LanguageSettings.setWordChars(langID, wordChars);
        info = start'WC=N/A,'rest;
        set_name_info(index, info);
     }

     index=name_match('def-language-',0,MISC_TYPE);
   }

   // change storage of numbering setting in pl1 in SE 2009
   if (LanguageSettings.isLanguageDefined('pl1')) {
      index = find_index('def-numbering-pl1', MISC_TYPE);
      if (index < 0) {
         // we used to store this value this way...but not anymore
         insert_name('def-numbering-pl1', MISC_TYPE, LanguageSettings.getMainStyle('pl1', 0));
      } 
   }

   // move delphi expansions to a new brace style flag (pascal only)
   if (LanguageSettings.isLanguageDefined('pas')) {
      insertBlankLine := LanguageSettings.getInsertBlankLineBetweenBeginEnd('pas');
      if (insertBlankLine) {
         // turn on delphi expansions
         LanguageSettings.setDelphiExpansions('pas', true);
         // turn off insert blank line - it's not used with this language anyway
         LanguageSettings.setInsertBlankLineBetweenBeginEnd('pas', false);
      }
   }

   if (LanguageSettings.isLanguageDefined('vbs')) {
      autoClose := LanguageSettings.getAutoBracket('vbs');
      if (autoClose & AUTO_BRACKET_SINGLE_QUOTE) {
         autoClose &= ~AUTO_BRACKET_SINGLE_QUOTE;
         LanguageSettings.setAutoBracket('vbs', autoClose);
      }
   }

   if (LanguageSettings.isLanguageDefined('java')) {
      refLangs := LanguageSettings.getReferencedInLanguageIDs('java');
      if (refLangs != '') {
         if (pos('android', refLangs) <= 0) {
            refLangs :+= ' android';
         }
      } else {
         refLangs = 'android';
      }
      LanguageSettings.setReferencedInLanguageIDs('java', refLangs);
   }
}

// Upgrade from pre-17 formatting settings to new beautifier settings.
void _UpgradeBeautifier() {
   index := find_index('beautifier_upgrade_from_settings', PROC_TYPE);
   if (index > 0) {
      call_index(index);
   }
}

// Upgrade settings of new beautifier from one version to another. 
// Not for the case of upgrading from pre v17 versions.
void _UpgradeBeautifierSettings() {
   index := find_index('beautifier_upgrade_existing_settings', PROC_TYPE);
   if (index > 0) {
      call_index(index);
   }
}

// For the case where the user is starting from a clean config.
void _SetupBeautifier() {
   index := find_index('beautifier_initial_setup', PROC_TYPE);
   if (index > 0) {
      call_index(index);
   }
}

/**
 * Updates a keybinding in an event table.
 * 
 * @param eventtab               name of keytable or index of keytable in the 
 *                               names table
 * @param keyName                name of key that we are binding
 * @param oldCmd                 command that is currently bound to key - if 
 *                               this does not match the current binding, this
 *                               function does not create a new binding.  Use an
 *                               empty string to create a new binding
 * @param newCmd                 command that we want to bind to key.  Use an 
 *                               empty string to simply remove old binding.
 */
void updateKeytab(typeless eventtab, _str keyName, _str oldCmd, _str newCmd)
{
   // find our event table
   eventtabIndex := 0;
   if (isinteger(eventtab)) {
      eventtabIndex = eventtab;
   } else {
      eventtabIndex = find_index(eventtab,EVENTTAB_TYPE);
   }

   if (eventtabIndex) {

      // find the binding for this key
      keyIndex := eventtab_index(eventtabIndex, eventtabIndex, event2index(name2event(keyName)));

      // make sure it matches our old command, we don't want to go around unbinding things willy nilly
      if ((keyIndex == 0 && oldCmd == '') || name_name(keyIndex) == oldCmd) {

         // initialize this to 0, if we are not binding the key to a new command, this will 
         // just unbind the key
         newIndex := 0;
         if (newCmd != '') {
            newIndex = find_index(newCmd, COMMAND_TYPE);
         } 

         // set it and forget it
         set_eventtab_index(eventtabIndex, event2index(name2event(keyName)), newIndex);
      }
   }
}

/**
 * Upgrades any language setting defaults that have changed since the previous 
 * version. 
 */
void _UpgradeExtensionSetup()
{
   /**
    * Heads up!  In v15.0.1, we changed how this function works.  If you need to 
    * make an update to a default language setting, do it in a callback for that 
    * language.  The callback will be called _<langId>_update_settings.  It may 
    * already exist, or you may have to create it.  In your callback, do a check 
    * for the UpdateVersion of the language before making any changes.  The 
    * UpdateVersion lets us know when we last updated this language's default 
    * settings, so we can know if the language is already up to date.  That way, we 
    * won't trample settings set by the user. 
    *  
    * Do not worry about setting the new UpdateVersion for the 
    * language in your callback, we take care of it here. 
    */

   // get language specific primary extensions
   index := name_match('def-language-',1,MISC_TYPE);
   for (;;) {
     if ( ! index ) { break; }
     langId := substr(name_name(index),14);
     updateIndex := find_index('_'langId'_update_settings', PROC_TYPE);
     if (updateIndex) {
        call_index(updateIndex);

        // make sure we mark the language as up to date!
        LanguageSettings.setUpdateVersion(langId, _version());
     }                   

     index=name_match('def-language-',0,MISC_TYPE);
   }

   // make sure that max symbols is high enough
   if (def_update_context_max_symbols <= 10000) {
      def_update_context_max_symbols = 0x10000; // 64k
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

/**
 * Callback to update ANSI-C language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _ansic_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   _str UpdateVersion = '15.0.1';
   if (_version_compare(UpdateVersion, LanguageSettings.getUpdateVersion('ansic')) > 0) {
      // "ANSIC" mode name changes to "ANSI-C" in 12.0
      if (_LangId2Modename('ansic') == 'ANSIC') {
         LanguageSettings.setModeName('ansic', 'ANSI-C');
      }
   }
}

/**
 * Callback to update IBM HLASM language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _asm390_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   _str UpdateVersion = '15.0.1';
   if (_version_compare(UpdateVersion, LanguageSettings.getUpdateVersion('asm390')) > 0) {
      // "OS/390" mode name changes to "IBM HLASM" in SE 2008
      if (LanguageSettings.getModeName('asm390') == 'OS/390 Assembler') {
         LanguageSettings.setModeName('asm390', 'IBM HLASM');
      }
   }

}

/**
 * Callback to update Cobol language settings.  See {@link _UpgradeExtensionSetup}. 
 */
void _cob_update_settings()
{
   _str UpdateVersion = '16.0.1';
   if (_version_compare(UpdateVersion, LanguageSettings.getUpdateVersion('cob')) > 0) {
      // "Cobol" mode name changes to "Cobol 85" in 17.0
      if (LanguageSettings.getModeName('cob') == 'Cobol') {
         LanguageSettings.setModeName('cob', 'Cobol 85');
      }
   }
   if (_version_compare('18.0.0', LanguageSettings.getUpdateVersion('cob74')) > 0) {
      LanguageSettings.setAliasFilename('cob74', 'cob74.als.xml');
   }
   if (_version_compare('18.0.0', LanguageSettings.getUpdateVersion('cob2000')) > 0) {
      LanguageSettings.setAliasFilename('cob2000', 'cob2000.als.xml');
   }
}

/**
 * Callback to update C/C++ language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _c_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   _str UpdateVersion = '15.0.1';
   if (_version_compare(UpdateVersion, LanguageSettings.getUpdateVersion('c')) > 0) {
      // "C" mode name changes to "C/C++" in 12.0
      if (LanguageSettings.getModeName('c') == 'C') {
         LanguageSettings.setModeName('c', 'C/C++');
         updateDefFileTypesLabel('C Files', 'C/C++ Files');
      }

      // make sure that '(' is bound to c_paren in "C/C++" mode
      updateKeytab('c_keys', '(', 'auto-functionhelp-key', 'c-paren');
   }

   if (def_c_xmldoc :== '') {
      def_c_xmldoc = false;
   }
}

/**
 * Callback to update DOCBOOK language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _docbook_update_settings()
{
   upgradeOldXMLExtensionToLanguage('docbook', DOCBOOK_SETUP);
}

/**
 * Callback to update DTD language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _dtd_update_settings()
{
   updateXMLLanguages('dtd');
}

/**
 * Callback to update Slick-C language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _e_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   _str UpdateVersion = '15.0.1';
   if (_version_compare(UpdateVersion, LanguageSettings.getUpdateVersion('e')) > 0) {
      // make sure that '(' is bound to slick_paren in "Slick-C" mode
      updateKeytab('slick_keys', '(', 'auto-functionhelp-key', 'slick-paren');
   }
}

/**
 * Callback to update Plain Text language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _fundamental_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   _str UpdateVersion = '15.0.1';
   if (_version_compare(UpdateVersion, LanguageSettings.getUpdateVersion(FUNDAMENTAL_LANG_ID)) > 0) {
      // v13 - "Fundamental" mode name changes to "Plain Text" in SE 2008
      if (LanguageSettings.getModeName(FUNDAMENTAL_LANG_ID) == 'Fundamental') {
         LanguageSettings.setModeName(FUNDAMENTAL_LANG_ID, 'Plain Text');
      }

      // add period and apostrophe to Plain Text word chars in 14.0.2
      wordChars := LanguageSettings.getWordChars(FUNDAMENTAL_LANG_ID);
      if (wordChars == "A-Za-z0-9_'$") {
         LanguageSettings.setWordChars(FUNDAMENTAL_LANG_ID, "A-Za-z0-9_'.$");
      }
   }
}

/**
 * Callback to update HTML language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _html_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   _str UpdateVersion = '15.0.1.2';
   if (_version_compare(UpdateVersion, LanguageSettings.getUpdateVersion('html')) > 0) {
      // html key table fix
      keyTable := LanguageSettings.getKeyTableName('html');
      if (keyTable == 'default-keys' || keyTable == '') {
         LanguageSettings.setKeyTableName('html', 'html_keys');
      }
   
      // fix the bindings for html_enter, html_space, html_lt and html_tab
      index := find_index('html-keys',EVENTTAB_TYPE);
      if (index) {
         updateKeytab(index, 'ENTER', '', 'html-enter');
         updateKeytab(index, '<', '', 'html-lt');
         updateKeytab(index, ' ', '', 'html-space');
         //html-tab is new in v15.0.1.2
         updateKeytab(index, 'TAB', 'html-key', 'html-tab');
      }
   }
}

/**
 * Callback to update Java language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _java_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', LanguageSettings.getUpdateVersion('java')) > 0) {
      // The old java setup up pointed to c-keys. We want to point to
      // java-keys now to get the extra java key bindings.
      keyTable := LanguageSettings.getKeyTableName('java');
      if (keyTable == 'c-keys' || keyTable == 'c_keys') {
         LanguageSettings.setKeyTableName('java', 'java-keys');
      }
   
      // make sure that '(' is bound to c_paren in "Java" mode
      updateKeytab('java_keys', '(', 'auto-functionhelp-key', 'c-paren');
   }
}

/**
 * Callback to update Objective-C language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _m_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', LanguageSettings.getUpdateVersion('m')) > 0) {
      // "OBJC" mode name changes to "Objective-C" in 12.0
      if (LanguageSettings.getModeName('m') == 'OBJC') {
         LanguageSettings.setModeName('m', 'Objective-C');
         updateDefFileTypesLabel('Object-C Files', 'Objective-C Files');
      }
   }
   if (_version_compare('16.1.0', LanguageSettings.getUpdateVersion('m')) > 0) {
      // Objective-C lexer changes to Objective-C in 17.0
      if (LanguageSettings.getLexerName('m') == 'cpp') {
         LanguageSettings.setLexerName('m', 'Objective-C');
      }
   }
}

/**
 * Callback to update Lua language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _lua_update_settings()
{
   if (_version_compare('17.0.0', LanguageSettings.getUpdateVersion('lua')) > 0) {
      // Binding for lua tab key to smarttab.
      updateKeytab('lua_keys', 'TAB', '', 'smarttab');
   }
}

/**
 * Callback to update Pascal language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _pas_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', LanguageSettings.getUpdateVersion('pas')) > 0) {

      // in v15, we changed handling of pascal_begin 
      // undo these, this mechanism is handled in syntax expansion now
      index := find_index("pascal_keys", EVENTTAB_TYPE);
      updateKeytab(index, 'n', 'pascal-n', '');
      updateKeytab(index, 'N', 'pascal-n', '');
      updateKeytab(index, 'd', 'pascal-d', '');
      updateKeytab(index, 'D', 'pascal-d', '');
      updateKeytab(index, 'y', 'pascal-y', '');
      updateKeytab(index, 'Y', 'pascal-y', '');
   }
}

/**
 * Callback to update Python language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _py_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', LanguageSettings.getUpdateVersion('py')) > 0) {
      // Binding for pyton tab key changed from python_tab to smarttab.
      updateKeytab('python_keys', 'tab', 'python-tab', 'smarttab');
   }
}


void _ruby_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', LanguageSettings.getUpdateVersion('ruby')) > 0) {
      // unbind this key
      updateKeytab('ruby_keys', '[', 'ruby-bracket', '');
   }
}

/**
 * Callback to update SqlServer language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _sqlserver_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', LanguageSettings.getUpdateVersion('sqlserver')) > 0) {
   
      wordChars := LanguageSettings.getWordChars('sqlserver');
      if (wordChars == "A-Za-z0-9_$#@") {  // Byte regex search
         // Correct the old code page specific word characters
         wordChars='A-Za-z0-9_$#@\x{a5}\x{a3}';
         LanguageSettings.setWordChars('sqlserver', wordChars);
      }
   }
}

/**
 * Callback to update SlickEdit TagDoc language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _tagdoc_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', LanguageSettings.getUpdateVersion('tagdoc')) > 0) {
      // "VSTagDoc" mode name changes to "SlickEdit Tag Docs" in 12.0
      if (LanguageSettings.getModeName('tagdoc') == 'VSTagDoc') {
         LanguageSettings.setModeName('tagdoc', 'SlickEdit Tag Docs');
      }
   }
}

/**
 * Callback to update VBScript language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _vbs_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', LanguageSettings.getUpdateVersion('vbs')) > 0) {

      // VBScript got its own event table and binding for SPACE, ENTER
      keyTable := LanguageSettings.getKeyTableName('vbs');
      if (keyTable != 'vbscript_keys') {
         LanguageSettings.setKeyTableName('vbs', 'vbscript_keys');
      }
   
      // fix the bindings for SPACE, ENTER
      index := find_index('vbscript-keys',EVENTTAB_TYPE);
      if (!index) {
         // Insert the names table
         index=insert_name('vbscript-keys',EVENTTAB_TYPE);
      }
      if (index) {
         updateKeytab(index, 'ENTER', '', 'vbscript-enter');
         updateKeytab(index, ' ', '', 'vbscript-space');
      }
   }
   if (_version_compare('16.0.0', LanguageSettings.getUpdateVersion('vbs')) > 0) {
      flags := LanguageSettings.getAutoBracket('vbs');
      LanguageSettings.setAutoBracket('vbs', flags & ~AUTO_BRACKET_SINGLE_QUOTE);
   }
}

/**
 * Callback to update VB language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _bas_update_settings()
{
   if (_version_compare('16.0.0', LanguageSettings.getUpdateVersion('bas')) > 0) {
      flags := LanguageSettings.getAutoBracket('bas');
      LanguageSettings.setAutoBracket('bas', flags & ~AUTO_BRACKET_SINGLE_QUOTE);
   }
}

/**
 * Callback to update VPJ language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _vpj_update_settings()
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', LanguageSettings.getUpdateVersion('vpj')) > 0) {
      upgradeOldXMLExtensionToLanguage('vpj', VPJ_SETUP);
   
      _str list[];
      list[list._length()]='vpe';
      list[list._length()]='vpw';
      list[list._length()]='vpt';
      int i;
      for (i=0;i<list._length();++i) {
         index:=find_index('def-language-'list[i],MISC_TYPE);
         if (index) {
            // In 8.0 beta, refered to XML.  Now it refers to vpj
            // In SE 2008, we use def-lang-for-ext- instead of def-language-
            delete_name(index);
   
            refersTo := ExtensionSettings.getLangRefersTo(list[i]);
            if (refersTo == 'xml' || refersTo == null) {
               ExtensionSettings.setLangRefersTo(list[i], 'vpj');
            }
         }
      }
   }
}

/**
 * Callback to update XSD language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _xsd_update_settings()
{
   upgradeOldXMLExtensionToLanguage('xsd', XSD_SETUP);
}


/**
 * Callback to update XHTML language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _xhtml_update_settings()
{
   upgradeOldXMLExtensionToLanguage('xhtml', XHTML_SETUP);
}

/**
 * Callback to update XMLDOC language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _xmldoc_update_settings()
{
   upgradeOldXMLExtensionToLanguage('xmldoc', XMLDOC_SETUP);
}

/**
 * Callback to update XML language settings.  See {@link 
 * _UpgradeExtensionSetup}. 
 */
void _xml_update_settings()
{
   updateXMLLanguages('xml');
}

/**
 * Callback to update CoffeeScript language settings.  See 
 * {@link _UpgradeExtensionSetup}. 
 */
void _coffeescript_update_settings()
{
   // we added CoffeeScript in v18
   // set up def_file_types for upgrading users
   if (_version_compare('18.0.0', LanguageSettings.getUpdateVersion('coffeescript')) > 0) {
      addNewLanguageToDefFileTypes('CoffeeScript Files', '*.coffee');
   }
}

/**
 * Callback to update CoffeeScript language settings.  See 
 * {@link _UpgradeExtensionSetup}. 
 */
void _googlego_update_settings()
{
   // we added CoffeeScript in v18
   // set up def_file_types for upgrading users
   if (_version_compare('18.0.0', LanguageSettings.getUpdateVersion('googlego')) > 0) {
      addNewLanguageToDefFileTypes('Google Go Files', '*.go');
   }
}

/**
 * Callback to update TTCN-3 language settings.  See 
 * {@link _UpgradeExtensionSetup}. 
 */
void _ttcn3_update_settings()
{
   // we added TTCN-3 in v18
   // set up def_file_types for upgrading users
   if (_version_compare('18.0.0', LanguageSettings.getUpdateVersion('ttcn3')) > 0) {
      addNewLanguageToDefFileTypes('TTCN-3 Files', '*.ttcn');
   }
}

static void _UpgradeLanguageAliasExpansion(_str config_migrated_from_version)
{
   // if we did not upgrade from anything, don't worry about it
   if (config_migrated_from_version == '') return;

   // get the major version
   dotPos := pos('.', config_migrated_from_version);
   if (dotPos) {
      prevMajorVersion := (int)substr(config_migrated_from_version, 1, dotPos - 1);
      // we split alias expansion from syntax expansion in v15
      if (prevMajorVersion < 15) {
         index := name_match('def-language-',1,MISC_TYPE);
         for (;;) {
           if ( ! index ) { break; }
           langID := substr(name_name(index),14);

           synExp := LanguageSettings.getSyntaxExpansion(langID);
           LanguageSettings.setExpandAliasOnSpace(langID, synExp);

           index=name_match('def-language-',0,MISC_TYPE);
         }
      }
   }
}

/**
 * Adds a new language to the def_file_types - for upgrading 
 * customers when we add support for a new language. 
 * 
 * @param langLabel        label for language (usually mode 
 *                         name)
 * @param fileTypes        extensions used by language
 */
static void addNewLanguageToDefFileTypes(_str langLabel, _str fileTypes)
{
   // see if it's already there - that would be WEIRD
   if (!pos(langLabel" (", def_file_types)) {
      // just shove it at the end, basically
      if (!endsWith(def_file_types, ',')) {
         def_file_types :+= ',';
      }
      def_file_types :+= langLabel' ('fileTypes')';
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
}

static void updateDefFileTypesLabel(_str oldLabel, _str newLabel)
{
   // we want to update the label of the mode
   _str text1, rest;
   if (pos(oldLabel" (", def_file_types) && !pos(newLabel" (", def_file_types)) {
      parse def_file_types with text1 oldLabel" (" rest;
      def_file_types = text1 :+ newLabel" ("rest;
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
}

/**
 * We upgraded some xml-based languages from extensions that point to XML to 
 * full languages. 
 * 
 * @param langId 
 * @param setupInfo 
 */
static void upgradeOldXMLExtensionToLanguage(_str langId, _str setupInfo)
{
   index := find_index('def-language-'langId, MISC_TYPE);
   if (index) {
      // are we pointing at xml?
      if (substr(name_info(index), 1, 4) == '@xml') {
         set_name_info(index, setupInfo);
      } else {
         updateXMLLanguages(langId);
      }
   }
}

/**
 * Some updates that are common to XML-based languages.
 * 
 * @param langId                 language to update
 */
static void updateXMLLanguages(_str langId)
{
   // We added the UpdateVersion in v15.0.1, so all updates prior to that just check for 15.0.1
   if (_version_compare('15.0.1', LanguageSettings.getUpdateVersion(langId)) > 0) {
      wordChars := LanguageSettings.getWordChars(langId);

      //Check for the case in 13.0.0 - 14.0.1 that had bad default word_chars and fix
      if (wordChars._length() > 3 && substr(wordChars, 1, 3) == 'WC=') {
         wordChars = substr(wordChars, 4);
         LanguageSettings.setWordChars(langId, wordChars);
      }
        
      if (!pos('\p', wordChars)) {
         LanguageSettings.setWordChars(langId, '\p{isXMLNameChar}?!');
      }

      keyTable := LanguageSettings.getKeyTableName(langId);
      if (keyTable == 'html-keys' || keyTable == 'html_keys') {
         LanguageSettings.setKeyTableName(langId, 'xml-keys');

         LanguageSettings.setIndentStyle(langId, INDENT_SMART);
      }
   }

}

static void _UpgradeAutoBracketSettings(_str config_migrated_from_version)
{
   // if we did not upgrade from anything, don't worry about it
   if (config_migrated_from_version == '') return;

   // get the major/minor version
   parse config_migrated_from_version with auto major '.' auto minor '.' auto revision '.' .;

   if (major <= 15 && revision < 1) {
      flags := 0;
      index := name_match('def-language-', 1, MISC_TYPE);
      for (;;) {
        if (!index) { break; }
        langID := substr(name_name(index), 14);
        flags = LanguageSettings.getAutoBracket(langID);
        LanguageSettings.setAutoBracket(langID, flags | AUTO_BRACKET_BRACE);
        index=name_match('def-language-',0,MISC_TYPE);
      }

      flags = LanguageSettings.getAutoBracket('html');
      LanguageSettings.setAutoBracket('html', flags | AUTO_BRACKET_ANGLE_BRACKET);
      flags = LanguageSettings.getAutoBracket('xml');
      LanguageSettings.setAutoBracket('xml', flags | AUTO_BRACKET_ANGLE_BRACKET);
      flags = LanguageSettings.getAutoBracket('cfml');
      LanguageSettings.setAutoBracket('cfml', flags | AUTO_BRACKET_ANGLE_BRACKET);
   }

   if (major < 16) {
      flags := 0;
      flags = LanguageSettings.getAutoBracket('html');
      LanguageSettings.setAutoBracket('html', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('xml');
      LanguageSettings.setAutoBracket('xml', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('cfml');
      LanguageSettings.setAutoBracket('cfml', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('verilog');
      LanguageSettings.setAutoBracket('verilog', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('systemverilog');
      LanguageSettings.setAutoBracket('systemverilog', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('vb');
      LanguageSettings.setAutoBracket('vb', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('bas');
      LanguageSettings.setAutoBracket('bas', flags & ~AUTO_BRACKET_ENABLE);
      flags = LanguageSettings.getAutoBracket('frm');
      LanguageSettings.setAutoBracket('frm', flags & ~AUTO_BRACKET_ENABLE);
   }
}

/**
 * If migrating from a version earlier than 17.0.2, clear out 
 * the visual c++ menu integration, because it can cause delays. 
 */
static void _UpgradeVCPPFlags(_str config_migrated_from_version)
{
   // if we did not upgrade from anything, don't worry about it
   if (config_migrated_from_version == '') return;

   // get the major/minor version
   parse config_migrated_from_version with auto major '.' auto minor '.' auto revision '.' .;

   // do this for 17.0.1 or earlier
   if (major > 17) return;
   if (major == 17 && minor > 0) return;
   if (major == 17 && revision >= 2) return;

   // clear the flag
   if (def_vcpp_flags & VCPP_ADD_VSE_MENU) {
      def_vcpp_flags &= ~(VCPP_ADD_VSE_MENU);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

/**
 * Upgrade aliases 
 *  
 */
static void _UpgradeAliases(_str config_migrated_from_version)
{
   boolean upgradeV17Aliases = false;
   if (config_migrated_from_version != '') {
      // get the major/minor version
      parse config_migrated_from_version with auto major '.' auto minor '.' auto revision '.' .;
      if (major < 18) {
         upgradeV17Aliases = true;
      }
   }

   if (!upgradeV17Aliases) {
      // see if alias info set
      index := find_index('def-aliasfile-version', MISC_TYPE);
      if (!index) {
         upgradeV17Aliases = true;

      } else {
         // check current version info??
         if (name_info(index) :!= VSALIASXMLVERSION) {
            upgradeV17Aliases = true;
         }
      }
   }
   
   if (upgradeV17Aliases) {
      updateAliasFiles();
   }
}

static void _UpdateURLMappings()
{
   _str UpdateVersion = '18.0.1.0';
   _str urlmap_version = getDefVar('def-url-mappings-version', '');
   if (_version_compare(UpdateVersion, urlmap_version) > 0) {
      upgradeURLMappingNames(urlmap_version);
      setDefVar('def-url-mappings-version', _version());
   }
}

_str file_match2(_str filename,int findfirst,_str options)
{
   filename=strip(filename,'B',"'");
   filename=strip(filename,'B','"');
   return(file_match(maybe_quote_filename(filename)' 'options,findfirst));
}
// Now in vsapi.dll
#if 0
boolean file_exists(_str filename)
{
   filename=strip(filename,'B','"');
   return(file_match(maybe_quote_filename(filename)' -p', 1)!='');
}
#endif

boolean file_or_buffer_exists(_str filename)
{
   filename=strip(filename,'B','"');
   return(buf_match(filename,1,'E')!='' || file_exists(filename));
}

static boolean remove_tagfile_from_lang_list(_str &langTagFileList, _str tagFile, _str langId)
{
   // search for this file
   tagFilePos := pos(PATHSEP :+ tagFile :+ PATHSEP, PATHSEP :+ langTagFileList :+ PATHSEP, 1, _fpos_case);
   if (!tagFilePos) {
      // try looking for it with the environment variables encoded
      tagFile = _encode_vsenvvars(tagFile, true);
      tagFilePos = pos(PATHSEP :+ tagFile :+ PATHSEP, PATHSEP :+ langTagFileList :+ PATHSEP, 1, _fpos_case);
   }

   // did we find it?
   if (tagFilePos) {
      // yes!
      --tagFilePos;

      // now remove it
      langTagFileList = substr(langTagFileList, 1, tagFilePos) :+ substr(langTagFileList, tagFilePos + length(tagFile) + 1);
      langTagFileList = stranslate(langTagFileList, '', PATHSEP :+ PATHSEP);
      langTagFileList = strip(langTagFileList, 'B', PATHSEP);

      // and set the new value
      LanguageSettings.setTagFileList(langId, _encode_vsenvvars(langTagFileList, true, false));

      return true;
   }

   // did not have this item
   return false;
}

static void _get_auto_generated_tagfile_names(_str (&list)[])
{
   i:=0;
   list._makeempty();
   list[i=0]='ada.vtg';
   list[i++]='asm390.vtg';
   list[i++]='bas.vtg';
   list[i++]='bbc.vtg';
   list[i++]='cics.vtg';
   list[i++]='cfml.vtg';
   list[i++]='cfscript.vtg';
   list[i++]='cobol.vtg';
   list[i++]='cpp.vtg';
   list[i++]='dotnet.vtg';
   list[i++]='html.vtg';
   list[i++]='idl.vtg';
   list[i++]='java.vtg';
   list[i++]='javascript.vtg';
   list[i++]='js.vtg';
   list[i++]='jsharp.vtg';
   list[i++]='jsp.vtg';
   list[i++]='lua.vtg';
   list[i++]='model204.vtg';
   list[i++]='npasm.vtg';
   list[i++]='omgidl.vtg';
   list[i++]='pascal.vtg';
   list[i++]='perl.vtg';
   list[i++]='php.vtg';
   list[i++]='phpscript.vtg';
   list[i++]='pro.vtg';
   list[i++]='python.vtg';
   list[i++]='rexx.vtg';
   list[i++]='ruby.vtg';
   list[i++]='rultags.vtg';
   list[i++]='sas.vtg';
   list[i++]='seq.vtg';
   list[i++]='slickc.vtg';
   list[i++]='tcl.vtg';
   list[i++]='tld.vtg';
   list[i++]='tornado.vtg';
   list[i++]='uslickc.vtg';
   list[i++]='verilog.vtg';
   list[i++]='vhdl.vtg';
   list[i++]='vbscript.vtg';
   list[i++]='xml.vtg';
   list[i++]='xhmtl.vtg';
   list[i++]='xmldoc.vtg';
   list[i++]='xsd.vtg';
   //list[i++]='pvwave.vtg';
}
static void _cleanup_old_tagfiles(_str old_config_dir)
{
   // list of automatically build tag files
   int i=0;
   _str list[];
   _get_auto_generated_tagfile_names(list);

   // close all the databases
   tag_close_all();

   // get paths to VSROOT, tagfiles directory, and old tagfiles directory
   _str vsroot=get_env('VSROOT');
   _maybe_append_filesep(vsroot);
   _str tagfiles=_tagfiles_path();
   _maybe_append_filesep(tagfiles);
   _str oldfiles=old_config_dir;
   _maybe_append_filesep(oldfiles);
   oldfiles=oldfiles:+"tagfiles":+FILESEP;

   // for each extension we have support loaded for
   _str tagFilesTable:[];
   LanguageSettings.getTagFileListTable(tagFilesTable);
   foreach (auto langId => auto langTagFileList in tagFilesTable) {

      // go through everything in our list
      for (i = 0; i < list._length(); ++i) {

         // check for tag file in VSROOT
         tag_filename := vsroot :+ list[i];
         if (remove_tagfile_from_lang_list(langTagFileList, tag_filename, langId)) {
            // it was in there, so we delete it
            if (file_exists(tag_filename)) delete_file(tag_filename);
         }

         // check in old configuration directory
         tag_filename = oldfiles :+ list[i];
         if (remove_tagfile_from_lang_list(langTagFileList, tag_filename, langId)) {
            // remove the tag file from the *new* configuration directory
            tag_filename = tagfiles :+ list[i];
            if (file_exists(tag_filename)) delete_file(tag_filename);
         }

         // finally, to cover all bases, check in the new configuration directory
         tag_filename = tagfiles :+ list[i];
         if (remove_tagfile_from_lang_list(langTagFileList, tag_filename, langId)) {
            // remove the tag file from the *new* configuration directory
            if (file_exists(tag_filename)) delete_file(tag_filename);
         }
      }
   }

   // remove the tag files from the *new* configuration directory
   for (i=0;i<list._length();++i) {
      tag_filename:=vsroot:+list[i];
      if (file_exists(tag_filename)) {
         delete_file(tag_filename);
      }
      tag_filename=tagfiles:+list[i];
      if (file_exists(tag_filename)) {
         delete_file(tag_filename);
      }
   }
}

boolean isTagFileAutoGenerated(_str tagFilename)
{
   // get paths to VSROOT, tagfiles directory, and old tagfiles directory
   _str vsroot=get_env('VSROOT');
   _maybe_append_filesep(vsroot);
   _str tagfiles=_tagfiles_path();
   _maybe_append_filesep(tagfiles);

   // split the tagfile into parts
   path := _strip_filename(tagFilename, "N");
   _maybe_append_filesep(path);

   // if it's not the right path, then it's definitely not auto-generated
   if (!file_eq(vsroot, path) && !file_eq(tagfiles, path)) return false;

   // now see if the name matches one of our auto-gen files
   name := _strip_filename(tagFilename, 'P');

   _str list[];
   _get_auto_generated_tagfile_names(list);

   for (i := 0; i < list._length(); i++) {
      if (file_eq(list[i], name)) return true;
   }

   return false;
}

static void _UpdateKeys()
{
   if (def_keys_version>=1) return;
   def_keys_version=1;

   // update alt-menu key bindings for A_B
#if USE_B_FOR_BUILD
   if (def_alt_menu) {
      set_eventtab_index(_default_keys,event2index(A_B),0);
   }
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
   case 'vi-keys':
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
static void set2(_str envVarName,_str value, boolean updateProcessBuffer)
{
   if (updateProcessBuffer) {
      set(envVarName:+'='((value==null)?'':value));
   } else {
      set_env(envVarName,value);
   }

}
void _restore_origenv(boolean updateProcessBuffer=false,boolean restoreVCPPEnvVars=false)
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
    _str old_path=get_env('PATH');
    set_env('PATH',_origenv_PATH);
    _str result=path_search(programName,'','P');
    set_env('PATH',old_path);
    return(result);
}
boolean _jaws_mode()
{
   return(_default_option(VSOPTION_JAWS_MODE));
}
static void _setup_jaws_mode()
{
   if (_jaws_mode()) {
      def_codehelp_flags&= ~(VSCODEHELPFLAG_AUTO_FUNCTION_HELP|VSCODEHELPFLAG_AUTO_LIST_MEMBERS|VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION|VSCODEHELPFLAG_AUTO_LIST_PARAMS);
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
   _str result='';
   int i=1;
   int arg_number=1;
   for (;;) {
      int j=pos('%s([123456789]|)',msg,i,'r');
      if ( ! j ) {
        result=result:+substr(msg,i);
        return(result);
      }
      typeless n;
      int len=pos('');
      if (len>=3) {
         n=substr(msg,j+2,1);
      } else {
         n=arg_number;
      }
      if (arg(2)._varformat()==VF_ARRAY) {
         if(arg(2)[n]._varformat()==VF_EMPTY) {
            //say("Error in error message");
            //say(" ...Array not initialized");
            result=result:+substr(msg,i,j-i);
         } else {
            result=result:+substr(msg,i,j-i):+arg(2)[n];
         }
      } else {
         _str argNp1='';
         if (arg()>n && arg(n+1)._varformat()!=VF_EMPTY) {
            argNp1 = arg(n+1);
         }
         result=result:+substr(msg,i,j-i):+argNp1;
      }
      arg_number=arg_number+1;
      i=j+len;
   }

}

/**
 * Used by OEMs to load custom macros and resources without having to
 * modify shipping macro source. Look for and execute oemaddons.e
 */
static void oemAddons()
{
   _str path;
   path=get_env('VSROOT');
   if( last_char(path)!=FILESEP ) path=path:+FILESEP;
   path=path:+FILESEP:+"macros":+FILESEP:+"oemaddons.e";
   if( !file_exists(path) ) {
      // Check for .ex
      path=path'x';
      if( !file_exists(path) ) {
         path="";
      }
   }
   if( path!="" ) {
      def_actapp&=~ACTAPP_AUTOREADONLY;
      // Run the oemaddons module to add custom OEM modules
      execute('oemaddons ',"");
      def_actapp|=ACTAPP_AUTOREADONLY;
      if( rc && rc!=2 ) {
         process_make_rc(rc,'oemaddons');
      }
      if( !rc ) {
         // If messages at bottom, erase it
        clear_message();
      }
   }
}

static boolean _TransferCfgToNewDirectory(_str &old_default_config, _str &new_default_config)
{
   // Prefix is above the directory that is called My Visual SlickEdit config or
   // My SlickEdit config
   int i;
   _str current_config_path = _ConfigPath();
   _str config_path_base = '';

   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ECLIPSE_PLUGIN) {
      config_path_base = get_env(_VSECLIPSECONFIG);
      _find_old_eclipse_default_config(config_path_base, old_default_config, new_default_config);
   } else {
      config_path_base = get_env(_SLICKEDITCONFIG);
      _find_old_default_config(config_path_base, old_default_config, new_default_config);
   }

   if(old_default_config != "") {
      _str msg = "Copying config '" :+ old_default_config:+ "\n to new directory '" :+ new_default_config :+ "...";
      _SplashScreenStatus("Copying configuration directory...");
      show_cancel_form_on_top("SlickEdit", msg, false, false);
      _str arg1 = old_default_config;
      _str arg2 = new_default_config;

      static boolean canceled;
      process_events(canceled);
      int return_value = copyFileTree(old_default_config, new_default_config, '', true);

      // Delete Slick-C tag file in new location to force re-tagging,
      // because the old tag file still points to the *.e files in old
      // installation.  --Kohei - 2006/6/8
      _str slickc_tagfile = 'slickc.vtg';
#if __UNIX__
      slickc_tagfile = 'u' :+ slickc_tagfile;
#endif
      slickc_tagfile = new_default_config :+ 'tagfiles' :+ FILESEP :+ slickc_tagfile;
      if ( file_exists(slickc_tagfile) ) {
         delete_file(slickc_tagfile);
      }

      //Remove the manifest.xml file
      _str manifest_xml_file = 'manifest.xml';
      manifest_xml_file = new_default_config :+ manifest_xml_file;
      if (file_exists(manifest_xml_file)) {
         delete_file(manifest_xml_file);
      }

      //Remove the pipDB.vtg file
      _str pipDB_file = 'pipDB.vtg';
      pipDB_file = new_default_config :+ pipDB_file;
      if (file_exists(pipDB_file)) {
         delete_file(pipDB_file);
      }

      //Remove dump.txt (Eclipse JNI error log) 
      _str dump_file = 'dump.txt';
      dump_file = new_default_config :+ dump_file;
      if (file_exists(dump_file)) {
         delete_file(dump_file);
      }

      // Delete old hot fixes directory, none of them apply to new version
      _str hotfixes_dir = new_default_config :+ "hotfixes" :+ FILESEP;
      _DelTree(hotfixes_dir, true);

      // Remove the logs directory
      _str logsDir = _log_path(new_default_config);
      _DelTree(logsDir, true);

      // Delete samples directory in new location
      //_str sample_projects_dir = _localSampleProjectsPath();
      //_DelTree(sample_projects_dir,true);
      
      close_cancel_form(cancel_form_wid());
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
         restore_filename=restore_filename:+_WINDOW_CONFIG_FILE;
         if( file_exists(restore_filename) ) {
            editor_name('r',restore_filename);
         }
      }
      return true;
   }

   return false;
}

static void upgrade_workspace_manager()
{
   // clear out all our old sample projects (which were in the old version directory)
   clear_old_sample_projects(def_workspace_info);

   // add new ones!
   maybeAddSampleProjectsToTree(def_workspace_info);

   // Clean up old-style Xcode project history
   remove_xcode_pbxproj_extensions(def_workspace_info);
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
           int pbxExt = pos('project.pbxproj', workspaceInfo[i].caption);
           if(pbxExt > 0) {
              _str captionTrimmed = substr(workspaceInfo[i].caption,1,pbxExt-2);
              workspaceInfo[i].caption = captionTrimmed;
           }
        }

        if(!(workspaceInfo[i].filename._isempty()))
        {
            int pbxExt = pos('project.pbxproj', workspaceInfo[i].filename);
            if(pbxExt > 0) {
               _str fileTrimmed = substr(workspaceInfo[i].filename,1,pbxExt-2);
               workspaceInfo[i].filename = fileTrimmed;
            }
        }
    }
}

static void change_ext_tagfiles_location(_str old_default_config, _str new_default_config)
{
   // Take out trailing slash if there is one
   int last_slash = lastpos(FILESEP,new_default_config);
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
         parse langTagFilesList with auto tagFile PATHSEP langTagFilesList;
         tagFile = _replace_envvars(tagFile);

         _str vtg = _strip_filename(tagFile, 'P');
         _str dir = _strip_filename(tagFile, 'N');

         // Does the start of the tagfile path match the old_default_config? If so then
         // the tagfile is underneath the old directory.
         tagfile_config_dir := substr(dir, 1, length(old_default_config));
         rest_of_path := substr(dir, length(tagfile_config_dir) + 1);
         if (file_eq(tagfile_config_dir, old_default_config)) {
            if (last_char(new_default_config) != FILESEP && first_char(rest_of_path) != FILESEP ) {
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

   // Also clear out old sample workspaces
   upgrade_workspace_manager();
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
      if (!file_eq(relativeFile, macroFile)) {
         sourceFile := relativeFile;
         if (_get_extension(relativeFile) == "ex") {
            sourceFile = substr(relativeFile,1,length(relativeFile)-1);
         }
         if (file_exists(new_default_config:+FILESEP:+sourceFile)) {
            macroFile = relativeFile;
         }
      }
      if (new_macfiles != '') new_macfiles :+= ' ';
      new_macfiles :+= maybe_quote_filename(macroFile);
   }

   // change def_macfiles if we moved any macros
   if (new_macfiles != def_macfiles) {
      def_macfiles = new_macfiles;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

/**
 * Check to see if the current platform is Mac OS X
 * 
 * @return Flag: true for active, false not
 */
boolean _isMac()
{
   return(machine()=='MACOSX' || machine()=='MACOSX11');
}
/**
 * Check to see if the Eclipse plug-in is active.
 * 
 * @return Flag: true for active, false not
 */
boolean isEclipsePlugin()
{
   return (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ECLIPSE_PLUGIN);
}
void _bind_command_to_key(_str event,_str command,int et_index=_default_keys)
{
   if (command==null) {
      set_eventtab_index(et_index,event2index(event),0);
   }
   int index=find_index(command,COMMAND_TYPE);
   if (!index) {
      _message_box('_bind_command_to_key: command 'command' not found');
      return;
   }
   set_eventtab_index(et_index,event2index(event),index);
}
_str _default_c_wildcards()
{
#if __UNIX__
   if (_isMac()) {
      return("*.c;*.cxx;*.cpp;*.m;*.mm;*.h;*.hpp;*.hxx");
   }
   return("*.c;*.cxx;*.cpp;*.h;*.hpp;*.hxx");
#else
   return("*.c;*.cxx;*.cpp;*.h;*.hpp;*.hxx;*.inl");
#endif

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
  
      // compare them, I suppose
      compValue := strcmp(preDot1, preDot2);
      if (compValue) return compValue;
   }

   return 0;
}
