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
#include "diff.sh"
#include "vsevents.sh"
#include "tagsdb.sh"
#include "eclipse.sh"
#include "xml.sh"
#include "color.sh"
#include "pipe.sh"
#include "minihtml.sh"
#include "license.sh"
#import "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "autobracket.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "box.e"
#import "c.e"
#import "clipbd.e"
#import "main.e"
#import "cobol.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "commentformat.e"
#import "complete.e"
#import "config.e"
#import "context.e"
#import "cutil.e"
#import "cua.e"
#import "debug.e"
#import "dir.e"
#import "dlgman.e"
#import "error.e"
#import "eclipse.e"
#import "ex.e"
#import "fileman.e"
#import "files.e"
#import "filetypemanager.e"
#import "ftpopen.e"
#import "guiopen.e"
#import "help.e"
#import "hex.e"
#import "hotfix.e"
#import "html.e"
#import "htmltool.e"
#import "ini.e"
#import "ispf.e"
#import "ispflc.e"
#import "javadoc.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "mouse.e"
#import "mprompt.e"
#import "os2cmds.e"
#import "pip.e"
#import "pipe.e"
#import "pmatch.e"
#import "projconv.e"
#import "project.e"
#import "pushtag.e"
#import "quickstart.e"
#import "recmacro.e"
#import "rul.e"
#import "selcode.e"
#import "seldisp.e"
#import "sellist.e"
#import "seltree.e"
#import "setupext.e"
#import "slickc.e"
#import "smartp.e"
#import "stdprocs.e"
#import "surround.e"
#import "tagform.e"
#import "tags.e"
#import "tbsearch.e"
#import "toast.e"
#import "toolbar.e"
#import "util.e"
#import "vc.e"
#import "vi.e"
#import "vicmode.e"
#import "wkspace.e"
#import "xml.e"
#import "xmldoc.e"
#import "xmlwrap.e"
#import "se/ui/EventUI.e"
#import "se/ui/OvertypeMarker.e"
#import "se/ui/toolwindow.e"
#import "fileproject.e"
#import "cfg.e"
#import "tbterminal.e"
#import "se/ui/twevent.e"
#endregion

using se.lang.api.LanguageSettings;

static const DIALOG_HISTORY_VIEW_ID = "DIALOG_HISTORY_VIEW_ID";
static const MONCFG_DIALOG_HISTORY_VIEW_ID = "MONCFG_DIALOG_HISTORY_VIEW_ID";
const OPTIONS_XML_HANDLE     = "OPTIONS_XML_HANDLE";
static const SELECT_MODE_VIEW_ID    = "SELECT_/dMODE_VIEW_ID";

static const MIN_PROG_INFO_WIDTH=8000;
static const MIN_PROG_INFO_HEIGHT=7000;

static const JAVADOC_TAGS_FROM_SIG= "param,return,exception,throws";

_str _process_mark:[];
_str _process_error_file_stack[];
_str _error_mark;
_str _top_process_mark:[];//All you need from here are this and the initialization in
//definit.  Any other differences are unintentional.
_str compile_rc;
//static int gsmartnextwindow_state;
/**
 * If enabled and softwrap is on, various home/end commands will move within the current partial line.
 *
 * @default 1
 * @categories Configuration_Variables
 */
bool def_softwrap_home_end=true;
/**
 * When the Tab key indent with spaces with the ptab() function
 * and the syntax indent is used, the indent can be based on
 * syntax indent tab stops (def_syntax_indent_tab_stops=true) or
 * + or syntax indent (def_syntax_indent_tab_stops=false).
 *
 * @default 0
 * @categories Configuration_Variables
 */
bool def_syntax_indent_tab_stops=false;
/**
 * If enabled, cancel current selection after copy to cursor
 * or move to cursor operation.
 *
 * @default 0
 * @categories Configuration_Variables
 */
bool def_deselect_copyto=false;

/**
 * If enabled, attempt to automatically quit the build
 * window when the command shell exits.
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_close_build_window_on_exit=false;

/**
 * If enabled, push a bookmark before jumping to the top or
 * bottom of the current buffer.  This allows you to use
 * pop-bookmark to jump back to the previous location.
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_top_bottom_push_bookmark=false;

/**
 * If enabled, {@link end_line} and {@link end_line_text_toggle} will stop at
 * the vertical line columns before stopping at the end of the line.
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_end_line_stop_at_vertical_line=false;
/**
 * If enabled, {@link end_line}, {@link end_line_text_toggle}, and
 * {@link end_line_ignore_trailing_blanks}, when invoked with multiple
 * cursors, will toggle between the actual line ends and aligning the
 * cursors at the end of the longest line.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_end_line_align_multiple_cursors=true;

/**
 * If enabled, use S/390 display translations.
 *
 * @see p_display_xlat
 * @default false
 * @categories Configuration_Variables
 */
int def_use_390_display_translations=0;

static _str g390DisplayTranslationTable="";

/**
 * If one of these directory names are found along a path
 * to an extensionless file, consider the file as C++
 *
 * @default "inc|include|c++|g++-2|g++-3|g++-4";
 * @categories Configuration_Variables
 */
_str def_cpp_include_path_re = "inc|include|c\\+\\+|g\\+\\+-[234]";

bool def_word_continue=false;

/**
 * When enabled, if you undo all the changes up to the last save,
 * you will be prompted whether you want to continue undoing changes.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_undo_past_save_prompt=true;

/**
 * When enabled, {@link nosplit_insert_line} (Ctrl+Enter) must insert a blank line.
 * <p>
 * Otherwise, it is allowed in certain cases for it to be used to move the
 * cursor to the next virtual stop, for example, in a C/C++ for loop, it
 * can be used to advance the cursor from the initialization statement to
 * the condition, and then to the increment statement.
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_strict_nosplit_insert_line=false;

/**
 * When enabled, split_insert_line() will be called to split
 * command lines in a interactive terminal window.
 *
 * <p>Has no effect unless at or past process read point and
 * "Send input on Enter" is set to "ON".
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_interactive_split_enter=false;
#if 0
/**
 * When enabled, command line(s) are sent when Enter is pressed.
 * Otherwise, commands are sent as soon as a line is
 * available.
 *
 * <p>When on, performance will be noticibly better when sending
 * many lines of source code. When on, you can paste multiple
 * lines and make edits before sending the source lines with by
 * Enter. Editing multiple lines works better when Interactive
 * "Split on Enter" is ON (def_interactive_split_enter=true).
 * </p>
 *
 * @see def_interactive_split_enter
 * @default false
 * @categories Configuration_Variables
 */
bool def_interactive_send_input_on_enter=true;
#endif
no_code_swapping;   /* Just in case there is an I/O error reading */
/* the slick.sta file, this will ensure user */
/* safe exit and save of files.  Common cursor */
/* movement commands will not cause module swapping. */
static bool undo_past_save;
static _str _command_mark,_orig_mark;
static _str _command_op_list;

static int gInSelEditModeCallback=0;

static _str _os_version_name = "";

static const VSBPFLAGC_NOFBITMAPS= (0x0f+1);

int _DebugPictureTab[];   // Global debug picture indexes for faster initialization

static _str gX11WindowManager = "";

definit()
{
   gX11WindowManager = "";
   _str initArg=arg(1);
   if (_UTF8()) {
      _extra_word_chars='\p{L}';
   } else if (_dbcs()) {
      _extra_word_chars="";
   } else {
      _extra_word_chars='\128-\255';
   }
   //gorig_wid=0;gsmartnextwindow_state=0;
   gNoTagCallList=false;

   rc=0;
   _last_have_dll := "";
   _get_string="";
   _get_string2="";

   gvsPrintOptions.print_header="%f";
   if (_isUnix()) {
      gvsPrintOptions.print_footer="%p";
   } else {
      gvsPrintOptions.print_footer="%p of %n";
   }
   gvsPrintOptions.print_font="Courier,10,0";
   // The left,right, and center flags are for 1.0 and 1.5 support
   gvsPrintOptions.print_options="720,720,720,720,720,"(PRINT_CENTER_HEADER|PRINT_CENTER_FOOTER)",0";
   gvsPrintOptions.print_cheader="";
   gvsPrintOptions.print_cfooter="";
   gvsPrintOptions.print_rheader="";
   gvsPrintOptions.print_rfooter="";

   _format_user_ini_filename=null;

   if ( initArg :!= 'L' ) {
      /* Editor initialization case. */
      gbgm_search_state=0;
      _trialMessageDisplayedFlags1=0;

      _html_tempfile="";
      //This is used for VC++ options when someone compiles a single file.
      // I suppose we could just user _html_tempfile, but there is a possiblitly
      // that someone could launch an applet, then run a compile before it closed.
      _vcpp_compiler_option_tempfile="";
      _clear_dir_stack();
      old_search_bounds=null;
      _error_file=GetErrorFilename();//GetErrorFilename sets COMPILE_ERROR_FILE
      _last_open_path="";_last_open_cwd="";
      // Position where last compile was started
      // Don't go past here when searching for the previous error.
      _top_process_mark._makeempty();
      _process_mark._makeempty(); /* Position of last error found by NEXT-ERROR in .process or .process-XXX. */
      _process_error_file_stack._makeempty();
      _error_mark="";  /* Position of last error found by NEXT-ERROR in $errors.tmp*/
      gerror_info._makeempty();
      _error_file="";
      _grep_buffer="";
      compile_rc=0;
      _cua_select=0;
      _command_op_list="";
      _command_mark="";
      _orig_mark="";
      _os_version_name="";
      if (index_callable(find_index("_prjupdate_cobol",PROC_TYPE))) {
         // Make sure current object is not an editor control
         // so that there is no file I/O
         _cmdline._prjupdate_cobol();
      }


      //_cua_textbox(def_cua_textbox)
   } else {
      bitmapsDialogsDir := _getSlickEditInstallPath():+VSE_BITMAPS_DIR:+FILESEP:+"dialogs":+FILESEP;
      _pic_xclose_mono=load_picture(-1,bitmapsDialogsDir:+"_xclose_mono.bmp");
      _pic_pinin_mono=load_picture(-1,bitmapsDialogsDir:+"_pinin_mono.bmp");
      _pic_pinout_mono=load_picture(-1,bitmapsDialogsDir:+"_pinout_mono.bmp");

      _pic_file=load_picture(-1,"_f_doc.svg");
      _pic_file_d=load_picture(-1,"_f_doc_disabled.svg");
      _pic_file12=_pic_file;
      _pic_file_d12=_pic_file_d;

      _pic_drcdrom=load_picture(-1,"_f_drive_cd.svg");
      _pic_drremov=load_picture(-1,"_f_drive_floppy.svg");
      _pic_drfixed=load_picture(-1,"_f_drive.svg");
      _pic_drremote=load_picture(-1,"_f_drive_network.svg");

      _pic_cbarrow=load_picture(-1,"bbmenudown.svg");
      _pic_cbdots=load_picture(-1,"bbbrowse.svg");
      _pic_cbdis=load_picture(-1,"bbmenudown.svg");

      load_picture(-1,"_f_folder.svg");
      load_picture(-1,"_f_folder_active.svg");

      _pic_fldtags=_pic_fldctags=load_picture(-1,"_f_folder_tags.svg");
      _pic_tt=load_picture(-1,"_f_font.svg");
      _pic_printer=load_picture(-1,"_f_printer.svg");
      _pic_search12=load_picture(-1, "_f_search.svg");
      _pic_build12=load_picture(-1, "_f_build.svg");
      if ( _pic_fldtags>=0 ) {
         set_name_info(_pic_fldtags,"Tag File");
      }

      _pic_xml_tag = _update_picture(-1, "_sym_tag.svg");
      _pic_xml_taguse = _update_picture(-1, "_sym_taguse.svg");
      _pic_xml_attr = _update_picture(-1, "_sym_var.svg");
      _pic_xml_target = _update_picture(-1, "_sym_label.svg");
      _pic_symbol_public=load_picture(-1,"_sym_overlay_public.svg");
      if (_pic_symbol_assign>0) set_name_info(_pic_symbol_public, "Public");
      _pic_symbol_assign=load_picture(-1,"_sym_overlay_assign.svg");
      if (_pic_symbol_assign>0) set_name_info(_pic_symbol_assign, "Assignment");
      _pic_symbol_const=load_picture(-1,"_sym_overlay_const.svg");
      if (_pic_symbol_assign>0) set_name_info(_pic_symbol_const, "Const scope");
      _pic_symbol_nonconst=load_picture(-1,"_sym_overlay_nonconst.svg");
      if (_pic_symbol_assign>0) set_name_info(_pic_symbol_nonconst, "Non-const scope");
      _pic_symbol_unknown=load_picture(-1,"_sym_overlay_unknown.svg");
      if (_pic_symbol_assign>0) set_name_info(_pic_symbol_unknown, "Unknown");

      load_picture(-1,"_ed_softwrap.svg");
      load_picture(-1,"_ed_plus.svg");
      load_picture(-1,"_ed_minus.svg");
      load_picture(-1,"_ed_bookmark.svg");
      load_picture(-1,"_ed_bookmark_pushed.svg");
      load_picture(-1,"_ed_annotation.svg");
      load_picture(-1,"_ed_annotation_disabled.svg");

      // preload all sizes and shades of editor margin bitmaps
      bitmapName := "";
      foreach (bitmapName in "_ed_softwrap.svg " :+
                             "_ed_plus.svg " :+
                             "_ed_minus.svg " :+
                             "_ed_bookmark.svg " :+
                             "_ed_bookmark_pushed.svg " :+
                             "_ed_annotation.svg " :+
                             "_ed_annotation_disabled.svg " :+
                             "" ) {
         load_picture(-1, bitmapName);
         //foreach (auto bg in "l d null") {
         //   if (bg=="null") bg="";
         //   foreach (auto bitmapSize in "1 2 3 4 5 6 8 10 12 14 16 20 24 28 32 36 40 44 48 52 56 60 64 72 80 88 96 104 112 120 128") {
         //      load_picture(-1,bitmapName:+"@":+bg:+bitmapSize);
         //   }
         //}
      }

      // preload a few sizes for status alert bitamps
      foreach (bitmapName in "_alert_background_active.svg " :+
                             "_alert_background_inactive.svg " :+
                             "_alert_background_toast.svg " :+
                             "_alert_debug_listener_active.svg " :+
                             "_alert_debug_listener_inactive.svg " :+
                             "_alert_debug_listener_toast.svg " :+
                             "_alert_editing_active.svg " :+
                             "_alert_editing_inactive.svg " :+
                             "_alert_editing_toast.svg " :+
                             "_alert_invisible.svg " :+
                             "_alert_updates_active.svg " :+
                             "_alert_updates_inactive.svg " :+
                             "_alert_updates_toast.svg " :+
                             "_alert_warning_active.svg " :+
                             "_alert_warning_inactive.svg " :+
                             "_alert_warning_toast.svg " :+
                             "" ) {
         load_picture(-1, bitmapName);
         //foreach (auto bg in "l d null") {
         //   if (bg=="null") bg="";
         //   foreach (auto bitmapSize in "4 5 6 7 8 9 10 11 12 14 16 18 20 24") {
         //      load_picture(-1,bitmapName:+"@":+bg:+bitmapSize);
         //   }
         //}
      }

      // preload a few sizes for codehelp HTML comments bitmaps
      foreach (bitmapName in "_f_arrow_into.svg " :+
                             "_f_arrow_lt.svg " :+
                             "_f_arrow_gt.svg " :+
                             "_f_arrow_left.svg " :+
                             "_f_arrow_right.svg " :+
                             "_f_pushtag.svg " :+
                             "_f_symbol_add.svg " :+
                             "_f_symbol_delete.svg " :+
                             "_f_symbol_modified.svg " :+
                             "_f_symbol_moved.svg " :+
                             "_f_run.svg " :+
                             "_f_bug.svg " :+
                             "_f_error.svg " :+
                             "_f_ok.svg " :+
                             "_f_warning.svg " :+
                             "_f_info.svg " :+
                             "bbpaste.svg " :+
                             "bbcopy.svg " :+
                             "bbcut.svg " :+
                             "" ) {
         load_picture(-1, bitmapName);
            foreach (auto bitmapSize in "4 5 6 7 8 9 10 11 12 14 16 18 20 24") {
               load_picture(-1,bitmapName:+"@":+bitmapSize);
         }
      }

      // preload all common dynamicaly sized button bar bitmaps
      foreach (bitmapName in "bbback.svg ":+
                             "bbforward.svg ":+
                             "bbpush_tag.svg ":+
                             "bbfind_refs.svg ":+
                             "bbclass_browser_find.svg ":+
                             "bbmake_tags.svg ":+
                             "bbone_window.svg ":+
                             "bbvsplit_window.svg ":+
                             "bbannotations_prefs.svg ":+
                             "bbannotations_definitions.svg ":+
                             "bbannotations_goto.svg ":+
                             "bbannotations_copy.svg ":+
                             "bbannotations_editor.svg ":+
                             "bbdelete_annotation.svg ":+
                             "bbnew_annotation.svg ":+
                             "bbfilter.svg ":+
                             "bbsave.svg ":+
                             "bbclose.svg ":+
                             "bbdiff.svg ":+
                             "bbmenu.svg ":+
                             "bbmenu.svg ":+
                             "bbdelete.svg ":+
                             "bbnew.svg ":+
                             "bbopen.svg ":+
                             "bbmenudown.svg ":+
                             "bbbrowse.svg ":+
                             "bbmenudown.svg ":+
                             "bbback.svg ":+
                             "bbup.svg ":+
                             "bbdown.svg ":+
                             "bbhsplit_window.svg ":+
                             "bbback.svg ":+
                             "bbup.svg ":+
                             "bbdown.svg ":+
                             "bbhsplit_window.svg ":+
                             "bbone_window.svg ":+
                             "bbopen.svg ":+
                             "bbcalendar.svg ":+
                             "bbcalculator.svg ":+
                             "") {
         //foreach (auto bitmapSize in "16 20 24 32 48") {
         //   load_picture(-1, bitmapName:+"@":+bitmapSize);
         //}
      }

      // preload all sizes and styles for tool window customization bitmaps
      foreach (bitmapName in "tbfind.svg " :+
                             "tbopen.svg " :+
                             "bbcalculator.svg " :+
                             "bbcalendar.svg " :+
                             "bbopen.svg " :+
                             "" ) {
         load_picture(-1, bitmapName);
         foreach (auto bg in "flat 3d grey green blue orange") {
            foreach (auto bitmapSize in "12 14 16 20 24 32 48 64 96 128") {
            load_picture(-1, bitmapName:+"@":+bg:+bitmapSize);
            }
         }
      }

      {
         bitmapsDir := _getSlickEditInstallPath():+VSE_BITMAPS_DIR:+FILESEP;
         _find_or_add_picture(bitmapsDir:+"dialogs":+FILESEP:+"_cbarrow_mono.ico");
         _find_or_add_picture(bitmapsDir:+"dialogs":+FILESEP:+"_xclose_mono.bmp");
      }

      _pic_lbplus=load_picture(-1,"_f_plus.svg");
      _pic_lbminus=load_picture(-1,"_f_minus.svg");

      if (isEclipsePlugin()) {
         _pic_lbvs=load_picture(-1,"_f_vs_plugin.svg");
      } else if (_isStandardEdition()) {
         _pic_lbvs=load_picture(-1,"_f_vs_standard.svg");
      } else if (_isCommunityEdition()) {
         _pic_lbvs=load_picture(-1,"_f_vs_community.svg");
      } else {
         _pic_lbvs=load_picture(-1,"_f_vs_pro.svg");
      }

      _pic_func=load_picture(-1,"_sym_func.svg");
      _pic_sm_file=load_picture(-1,"_f_doc.svg");
      _pic_sm_file_d=load_picture(-1,"_f_doc_disabled.svg");
      _pic_sm_func=load_picture(-1,"_sym_func.svg");

      //1:13pm 6/22/1998
      //Dan added these bitmaps for the new project toolbar stuff....
      _pic_vc_co_user_w=load_picture(-1,"_f_doc_checked.svg");
      set_name_info(_pic_vc_co_user_w,"You have this file checked out");
      _pic_vc_co_user_r=load_picture(-1,"_f_doc_checked_readonly.svg");
      set_name_info(_pic_vc_co_user_r,"You have this read only file checked out");
      _pic_vc_co_other_m_w=load_picture(-1,"_f_doc_vc_user.svg");
      set_name_info(_pic_vc_co_other_m_w,"Another user has this file checked out");
      _pic_vc_co_other_m_r=load_picture(-1,"_f_doc_vc_user_readonly.svg");
      set_name_info(_pic_vc_co_other_m_r,"Another user has this read only file checked out");
      _pic_vc_co_other_x_w=load_picture(-1,"_f_doc_locked.svg");
      set_name_info(_pic_vc_co_other_x_w,"Another user has this file checked out exclusively");
      _pic_vc_co_other_x_r=load_picture(-1,"_f_doc_readonly_locked.svg");
      set_name_info(_pic_vc_co_other_x_r,"Another user has this read only file checked out exclusively");
      _pic_vc_available_w=load_picture(-1,"_f_doc_vc.svg");
      set_name_info(_pic_vc_available_w,"This file is available for check out");
      _pic_vc_available_r=load_picture(-1,"_f_doc_vc_readonly.svg");
      set_name_info(_pic_vc_available_r,"This read only file is available for check out");
      _pic_doc_w=load_picture(-1,"_f_doc.svg");
      _pic_doc_d=load_picture(-1,"_f_doc_disabled.svg");
      _pic_doc_r=load_picture(-1,"_f_doc_readonly.svg");
      _pic_doc_ant=load_picture(-1,"_f_target.svg");
      set_name_info(_pic_doc_ant,"This is a build file");

      _pic_tfldopen=_pic_tfldclos=load_picture(-1,"_f_folder.svg");
      _pic_tfldopendisabled=_pic_tfldclosdisabled=load_picture(-1,"_f_folder_disabled.svg");
      _pic_tproject=load_picture(-1,"_f_workspace.svg");
      _pic_tpkgclos=load_picture(-1,"_f_package.svg");

      // Bitmaps for dynamic surround and auto complete
      _pic_surround = load_picture(-1,"_ed_up_and_down.svg");
      _pic_light_bulb = load_picture(-1, "_ed_lightbulb.svg");
      _pic_editor_reference = load_picture(-1, "_ed_reference.svg");
      _pic_editor_ref_assign = load_picture(-1, "_ed_ref_assign.svg");
      _pic_editor_ref_const = load_picture(-1, "_ed_ref_const.svg");
      _pic_editor_ref_nonconst = load_picture(-1, "_ed_ref_nonconst.svg");
      _pic_editor_ref_unknown = load_picture(-1, "_ed_ref_unknown.svg");
      _pic_keyword = load_picture(-1,"_f_key.svg");
      if (_pic_keyword >= 0) {
         set_name_info(_pic_keyword, "Keyword");
      }
      _pic_syntax = load_picture(-1,"_f_code.svg");
      if (_pic_syntax >= 0) {
         set_name_info(_pic_syntax, "Syntax expansion");
      }
      _pic_complete_prev = load_picture(-1,"_f_complete_prev.svg");
      if (_pic_complete_prev >= 0) {
         set_name_info(_pic_complete_prev, "Word completion on earlier line in file");
      }
      _pic_complete_next = load_picture(-1,"_f_complete_next.svg");
      if (_pic_complete_next >= 0) {
         set_name_info(_pic_complete_next, "Word completion on subsequent line in file");
      }
      _pic_alias = load_picture(-1,"_f_alias.svg");
      if (_pic_alias >= 0) {
         set_name_info(_pic_alias, "Alias or code template");
      }
      _pic_surround_alias = load_picture(-1,"_f_surround.svg");
      if (_pic_alias >= 0) {
         set_name_info(_pic_surround_alias, "Surround code alias or template");
      }

      // Bitmaps for diff buttons
      _pic_merge_left = load_picture(-1,"_ed_diff_merge_left.svg");
      if (_pic_merge_left >= 0) {
         set_name_info(_pic_merge_left, "Merge text left");
      }

      _pic_merge_right = load_picture(-1,"_ed_diff_merge_right.svg");
      if (_pic_merge_right >= 0) {
         set_name_info(_pic_merge_right, "Merge text right");
      }

      // Bitmaps for the debugger
      int breakpt_index=load_picture(-1,"_ed_breakpoint.svg");
      int execbrk_index=load_picture(-1,"_ed_exec_breakpoint.svg");
      int execpt_index=load_picture(-1,"_ed_exec.svg");
      int stackbrk_index=load_picture(-1,"_ed_stack_breakpoint.svg");
      int stackexc_index=load_picture(-1,"_ed_stack.svg");
      int watchpt_index=load_picture(-1,"_ed_watchpoint.svg");
      int watchpn_index=load_picture(-1,"_ed_watchpoint_disabled.svg");

      int breakpn_index=load_picture(-1,"_ed_breakpoint_disabled.svg");
      int execbn_index=load_picture(-1,"_ed_exec_breakpoint_disabled.svg");
      int stackbn_index=load_picture(-1,"_ed_stack_breakpoint_disabled.svg");

      _pic_project=load_picture(-1,"_f_project.svg");
      _pic_project_dependency=load_picture(-1,"_f_project_dependency.svg");
      _pic_workspace=load_picture(-1,"_f_workspace.svg");
      _pic_treecb_blank=load_picture(-1,"_f_blank.svg");

      if ( _pic_workspace>=0 ) {
         set_name_info(_pic_workspace,"Workspace");
      }
      if ( _pic_project>=0 ) {
         set_name_info(_pic_project,"Project");
      }
      if ( _pic_project_dependency>=0 ) {
         set_name_info(_pic_project_dependency,"Project Dependency");
      }

      _pic_job=load_picture(-1,"_ed_annotation.svg");
      _pic_jobdd=load_picture(-1,"_ed_annotation_disabled.svg");
      // Load all of the picures that we need, and set up their help bubbles
      _pic_branch=load_picture(-1,"_f_branch.svg");
      if ( _pic_branch>=0 ) {
         set_name_info(_pic_branch,"This is a branch tag");
      }
      _pic_cvs_file=load_picture(-1,"_f_doc.svg@xA");
      if ( _pic_cvs_file_qm>=0 ) {
         set_name_info(_pic_cvs_file_qm,"This file is in the repository and up-to-date");
      }
      _pic_cvs_file_qm=load_picture(-1,"_f_doc_unknown.svg@xA");
      if ( _pic_cvs_file_qm>=0 ) {
         set_name_info(_pic_cvs_file_qm,"This file does not exist in the repository");
      }
      _pic_file_old=load_picture(-1,"_f_doc_updateable.svg");
      if ( _pic_file_old>=0 ) {
         set_name_info(_pic_file_old,"This file is older than the version in the repository");
      }
      _pic_file_mod=load_picture(-1,"_f_doc_modified.svg");
      if ( _pic_file_mod>=0 ) {
         set_name_info(_pic_file_mod,"This file is modified locally");
      }
      _pic_file_mod_prop=load_picture(-1,"_f_doc_properties_modified.svg");
      if ( _pic_file_mod_prop>=0 ) {
         set_name_info(_pic_file_mod_prop,"This file's properties are modified locally");
      }
      _pic_file_mod2 = load_picture(-1, "_f_doc_new.svg");
      if (_pic_file_mod2 >= 0) {
         set_name_info(_pic_file_mod2, "Another application has modified the file");
      }
      _pic_file_del = load_picture(-1, "_f_doc_delete.svg");
      if (_pic_file_del >= 0) {
         set_name_info(_pic_file_del, "Another application has deleted the file");
      }
      _pic_file_lock = load_picture(-1, "_f_doc_locked.svg");
      if (_pic_file_lock >= 0) {
         set_name_info(_pic_file_lock, "This file is locked");
      }
      _pic_file_old_mod=load_picture(-1,"_f_doc_modified_updateable.svg");
      if ( _pic_file_old_mod>=0 ) {
         set_name_info(_pic_file_old_mod,"This file is older than the version in the repository, and modified locally");
      }
      _pic_cvs_file_obsolete=load_picture(-1,"_f_doc_obsolete.svg@xA");
      if ( _pic_cvs_file_obsolete>=0 ) {
         set_name_info(_pic_cvs_file_obsolete,"This file exists locally, but no longer exists in the repository");
      }
      _pic_cvs_file_new=load_picture(-1,"_f_doc_add_updateable.svg@xA");
      if ( _pic_cvs_file_new>=0 ) {
         set_name_info(_pic_cvs_file_new,"This file is in the repository, but does not exist locally");
      }
      // Use 0 here, we have 2 copies of the same bitmap so that we can have
      // separate messages
      _pic_cvs_filem=load_picture(0,"_f_doc_delete.svg@xA");
      if ( _pic_cvs_filem>=0 ) {
         set_name_info(_pic_cvs_filem,"This file exists locally, but no longer exists in the repository");
      }
      _pic_cvs_filem_mod=load_picture(-1,"_f_doc_modified_delete.svg@xA");
      if ( _pic_cvs_filem_mod>=0 ) {
         set_name_info(_pic_cvs_filem_mod,"This file has been removed but not commited");
      }
      _pic_cvs_filep=load_picture(-1,"_f_doc_add.svg@xA");
      if ( _pic_cvs_filep>=0 ) {
         set_name_info(_pic_cvs_filep,"This file has been added but not commited");
      }
      _pic_cvs_fld_m=load_picture(-1,"_f_folder_delete.svg@xA");
      if ( _pic_cvs_fld_m>=0 ) {
         set_name_info(_pic_cvs_fld_m,"This directory exists locally, but no longer exists in the repository");
      }
      _pic_cvs_fld_date=load_picture(-1,"_f_folder_updateable.svg@xA");
      if ( _pic_cvs_fld_date>=0 ) {
         set_name_info(_pic_cvs_fld_date,"This directory is older than the version in the repository");
      }
      _pic_cvs_fld_mod=load_picture(-1,"_f_folder_modified.svg@xA");
      if ( _pic_cvs_fld_mod>=0 ) {
         set_name_info(_pic_cvs_fld_mod,"This directory is modified but not commited (it has probably been merged from another branch)");
      }
      _pic_cvs_fld_mod_date=load_picture(-1,"_f_folder_modified_updateable.svg@xA");
      if ( _pic_cvs_fld_mod_date>=0 ) {
         set_name_info(_pic_cvs_fld_mod_date,"This directory is modified and older than the version in the repository (it probably needs to be merged)");
      }
      _pic_cvs_fld_p=load_picture(-1,"_f_folder_add.svg@xA");
      if ( _pic_cvs_fld_p>=0 ) {
         set_name_info(_pic_cvs_fld_p,"This directory is in the repository does not exist locally");
      }
      _pic_cvs_fld_qm=load_picture(-1,"_f_folder_unknown.svg@xA");
      if ( _pic_cvs_fld_qm>=0 ) {
         set_name_info(_pic_cvs_fld_qm,"This directory does not exist in the repository");
      }
      _pic_cvs_file_error=load_picture(-1,"_f_doc_error.svg@xA");
      if ( _pic_cvs_file_error>=0 ) {
         set_name_info(_pic_cvs_file_error,"There is a problem with this file.  It probably exists locally, but is not in the CVS Entries file");
      }
      _pic_cvs_fld_error=load_picture(-1,"_f_folder_error.svg@xA");
      if ( _pic_cvs_fld_error>=0 ) {
         set_name_info(_pic_cvs_fld_error,"There is a problem with this directory.  It probably exists locally, but is not in the CVS Entries file");
      }
      _pic_cvs_file_conflict=load_picture(-1,"_f_doc_conflict_updateable.svg@xA");
      if ( _pic_cvs_file_conflict>=0 ) {
         set_name_info(_pic_cvs_file_conflict,"There is a conflict in this file");
      }
      _pic_cvs_file_conflict_updated=load_picture(-1,"_f_doc_conflict_updated.svg@xA");
      if ( _pic_cvs_file_conflict_updated>=0 ) {
         set_name_info(_pic_cvs_file_conflict_updated,"There was a conflict in this file and it cannot be commited until it is modified");
      }
      _pic_cvs_file_conflict_local_added=load_picture(-1,"_f_doc_conflict_add.svg@xA");
      if ( _pic_cvs_file_conflict_local_added>=0 ) {
         set_name_info(_pic_cvs_file_conflict_local_added,"There was a conflict: local add, incoming add upon merge.");
      }
      _pic_cvs_file_conflict_local_deleted=load_picture(-1,"_f_doc_conflict_delete.svg@xA");
      if ( _pic_cvs_file_conflict_local_deleted>=0 ) {
         set_name_info(_pic_cvs_file_conflict_local_deleted,"There was a conflict: local delete, incoming delete upon merge.");
      }
      _pic_cvs_file_copied=load_picture(-1,"_f_doc_copied.svg@xA");
      if ( _pic_cvs_file_copied>=0 ) {
         set_name_info(_pic_cvs_file_copied,"This file is copied in the index.");
      }
      _pic_cvs_file_not_merged=load_picture(-1,"_f_doc_warning.svg@xA");
      if ( _pic_cvs_file_not_merged>=0 ) {
         set_name_info(_pic_cvs_file_not_merged,"This file has been updated but not merged.");
      }
      _pic_cvs_module=load_picture(-1,"_f_folder_checked.svg@xA");

      _pic_vc_user_bitmap  = load_picture(-1, "_f_user.svg");
      _pic_vc_label_bitmap  = load_picture(-1, "_f_label.svg");
      _pic_vc_floatingdate_bitmap  = load_picture(-1, "_f_calendar.svg");
      _pic_linked_bitmap  = load_picture(-1, "bbhtml_link.svg");
      _pic_del_linked_bitmap  = load_picture(-1, "bbhtml_unlink.svg");
      _pic_diff_code_bitmap  = load_picture(-1, "bbcode_colored.svg");
      _pic_del_diff_code_bitmap  = load_picture(-1, "bbtext.svg");
      _pic_diff_doc_bitmap = load_picture(-1,"bbdiff.svg");
      _pic_del_diff_doc_bitmap = load_picture(-1,"bbdiff_names.svg");
      _pic_diff_path_up  = load_picture(-1, "bbup.svg");
      _pic_diff_path_down  = load_picture(-1, "bbdown.svg");

      _pic_file_reload_overlay  = load_picture(-1, "_f_overlay_new.svg");
      if ( _pic_file_reload_overlay>=0 ) {
         set_name_info(_pic_file_reload_overlay,"There is a newer version of this file on disk");
      }
      _pic_file_date_overlay  = load_picture(-1, "_f_overlay_updateable.svg");
      if ( _pic_file_date_overlay>=0 ) {
         set_name_info(_pic_file_date_overlay,"This file is older than the version in the repository");
      }
      _pic_file_mod_overlay  = load_picture(-1, "_f_overlay_modified.svg");
      if ( _pic_file_mod_overlay>=0 ) {
         set_name_info(_pic_file_mod_overlay,"This file is modified locally");
      }
      _pic_file_checkout_overlay  = load_picture(-1, "_f_overlay_checked.svg");
      if ( _pic_file_checkout_overlay>=0 ) {
         set_name_info(_pic_file_checkout_overlay,"This file is checked out");
      }
      _pic_file_deleted_overlay  = load_picture(-1, "_f_overlay_delete.svg");
      if ( _pic_file_deleted_overlay>=0 ) {
         set_name_info(_pic_file_deleted_overlay,"This file has been removed");
      }
      _pic_file_unkown_overlay  = load_picture(-1, "_f_overlay_unknown.svg");
      if ( _pic_file_unkown_overlay>=0 ) {
         set_name_info(_pic_file_unkown_overlay,"This file is unkown");
      }
      _pic_file_add_overlay  = load_picture(-1, "_f_overlay_add.svg");
      if ( _pic_file_add_overlay>=0 ) {
         set_name_info(_pic_file_add_overlay,"This file has been added but not committed");
      }
      _pic_file_conflict_overlay  = load_picture(-1, "_f_overlay_conflict.svg");
      if ( _pic_file_add_overlay>=_pic_file_conflict_overlay ) {
         set_name_info(_pic_file_conflict_overlay,"This file has a conflict");
      }
      _pic_file_copied_overlay  = load_picture(-1, "_f_overlay_copied.svg");
      if ( _pic_file_copied_overlay>=_pic_file_conflict_overlay ) {
         set_name_info(_pic_file_copied_overlay,"This file is copied in the index");
      }
      // 3/9/2020 used same bitmap for these before.  Load second copy so we
      // have a separate message
      _pic_file_not_merged_overlay=load_picture(-1,"_f_overlay_conflict.svg@xA");
      if ( _pic_file_not_merged_overlay>=0 ) {
         set_name_info(_pic_file_not_merged_overlay,"This file has been updated but not merged.");
      }
      _pic_file_locked_overlay=load_picture(-1,"_f_overlay_locked.svg@xA");
      if ( _pic_file_locked_overlay>=0 ) {
         set_name_info(_pic_file_locked_overlay,"Another user has this file checked out exclusively.");
      }

      _pic_diff_all_symbols = load_picture(-1,"_f_diff_all_symbols.svg");
      _pic_diff_one_symbol = load_picture(-1,"_f_diff_one_symbol.svg");

      // Sandra added these for the enhanced open toolbar
      _pic_otb_file_proj = load_picture(-1, "_f_doc_in_project.svg");
      if ( _pic_otb_file_proj ) {
         set_name_info(_pic_otb_file_proj,"This file is in the current project");
      }
      _pic_otb_file_wksp = load_picture(-1, "_f_doc_in_workspace.svg");
      if ( _pic_otb_file_wksp ) {
         set_name_info(_pic_otb_file_wksp,"This file is in the current workspace");
      }
      _pic_otb_overlay_open = load_picture(-1, "_f_overlay_open.svg");
      if ( _pic_otb_overlay_open ) {
         set_name_info(_pic_otb_overlay_open,"This file is currently open");
      }
      _pic_otb_network = load_picture(-1, "_f_network.svg");
      _pic_otb_favorites = load_picture(-1, "_f_favorite.svg");
      _pic_otb_server = load_picture(-1, "_f_server.svg");
      _pic_otb_share = load_picture(-1, "_f_folder_network.svg");
      _pic_otb_cdrom = load_picture(-1, "_f_drive_cd.svg");
      _pic_otb_remote = load_picture(-1, "_f_drive_network.svg");
      _pic_otb_floppy = load_picture(-1, "_f_drive_floppy.svg");

      _pic_disk_file    = load_picture(-1, "_f_doc.svg");
      _pic_hist_file    = load_picture(-1, "_f_doc_history.svg");
      _pic_wksp_file    = load_picture(-1, "_f_doc_in_workspace.svg");
      _pic_proj_file    = load_picture(-1, "_f_doc_in_project.svg");

      load_picture(-1, "_f_folder_up.svg");
      load_picture(-1, "_f_computer.svg");
      load_picture(-1, "_f_drive.svg");
      load_picture(-1, "_f_lock.svg");

      load_picture(-1, bitmapsDialogsDir:+"_blgrip.ico");
      load_picture(-1, bitmapsDialogsDir:+"_tdown.ico");
      load_picture(-1, bitmapsDialogsDir:+"_tup.ico");
      load_picture(-1, bitmapsDialogsDir:+"_tdown2.ico");
      load_picture(-1, bitmapsDialogsDir:+"_tup2.ico");

      load_picture(-1, "_f_arrow_left.svg");
      load_picture(-1, "_f_arrow_right.svg");

      int i;

#if USE_CVS_ANIMATION_PICS
      for (i=0;i<=20;++i) {
         int index=isinteger(_cvs_animation_pics[i])?_cvs_animation_pics[i]:-1;
         suffix := "";
         if (length(i)<2) {
            suffix="0";
         }
         suffix :+= i;
         if (index<=0) {
            _cvs_animation_pics[i]=load_picture(-1,CVS_STALL_PICTURE_PREFIX:+suffix".ico");
         }
      }
#endif

      for (i=0;i<VSBPFLAGC_NOFBITMAPS;++i) {
         _DebugPictureTab[i]=0;
      }

      _DebugPictureTab[VSBPFLAG_BREAKPOINT]=breakpt_index;  // Break point
      _DebugPictureTab[VSBPFLAG_EXEC]=execpt_index;   // Execution point
      _DebugPictureTab[VSBPFLAG_BREAKPOINT|VSBPFLAG_EXEC]=execbrk_index;   // execution point with break point
      _DebugPictureTab[VSBPFLAG_STACKEXEC]=stackexc_index;  // Stack execution
      _DebugPictureTab[VSBPFLAG_STACKEXEC|VSBPFLAG_BREAKPOINT]=stackbrk_index;
      _DebugPictureTab[VSBPFLAG_STACKEXEC|VSBPFLAG_EXEC]=execpt_index;  // Execution point
      _DebugPictureTab[VSBPFLAG_STACKEXEC|VSBPFLAG_BREAKPOINT|VSBPFLAG_EXEC]=execbrk_index;   // execution point with break point

      _DebugPictureTab[VSBPFLAG_BREAKPOINTDISABLED]=breakpn_index;  // Break point disabled

      _DebugPictureTab[VSBPFLAG_BREAKPOINTDISABLED|VSBPFLAG_BREAKPOINT]=breakpt_index;  // Break point
      _DebugPictureTab[VSBPFLAG_BREAKPOINTDISABLED|VSBPFLAG_EXEC]=execbn_index;   // Executing point with break point disabled
      _DebugPictureTab[VSBPFLAG_BREAKPOINTDISABLED|VSBPFLAG_BREAKPOINT|VSBPFLAG_EXEC]=execbrk_index;   // execution point with break point
      _DebugPictureTab[VSBPFLAG_BREAKPOINTDISABLED|VSBPFLAG_STACKEXEC]=stackbn_index;  // Stack execution with break point disabled
      _DebugPictureTab[VSBPFLAG_BREAKPOINTDISABLED|VSBPFLAG_STACKEXEC|VSBPFLAG_BREAKPOINT]=stackbrk_index;
      _DebugPictureTab[VSBPFLAG_BREAKPOINTDISABLED|VSBPFLAG_STACKEXEC|VSBPFLAG_EXEC]=execbn_index;   // Executing point with break point disabled
      _DebugPictureTab[VSBPFLAG_BREAKPOINTDISABLED|VSBPFLAG_STACKEXEC|VSBPFLAG_BREAKPOINT|VSBPFLAG_EXEC]=execbrk_index;   // execution point with break point
   }

   _pic_otb_cd_up = _find_or_add_picture("_f_folder_up.svg");
   _pic_otb_computer = _find_or_add_picture("_f_computer.svg");
   _pic_otb_fixed = _find_or_add_picture("_f_drive.svg");

   _pic_fldaop=_find_or_add_picture("_f_folder_active.svg");
   _pic_folder=_find_or_add_picture("_f_folder.svg");
   _pic_fldclos=_find_or_add_picture("_f_folder.svg");
   _pic_fldopen=_find_or_add_picture("_f_folder.svg");
   _pic_fldclos12=_find_or_add_picture("_f_folder.svg");
   _pic_fldopen12=_find_or_add_picture("_f_folder.svg");

   // Editor initialization case or building state file.
   _in_quit=false;
   _in_exit_list=false;
   _in_help=false;
   undo_past_save=false;
   if (name_on_key(name2event("a-f4"))!= "safe-exit") {
      _mdi._sysmenu_bind(SC_CLOSE,"&Close");
   }
   {
      breakpt_index := find_index("_ed_breakpoint.svg");
      execbrk_index := find_index("_ed_exec_breakpoint.svg",PICTURE_TYPE);
      execpt_index := find_index("_ed_exec.svg",PICTURE_TYPE);
      stackbrk_index := find_index("_ed_stack_breakpoint.svg",PICTURE_TYPE);
      stackexc_index := find_index("_ed_stack.svg",PICTURE_TYPE);
      watchpt_index := find_index("_ed_watchpoint.svg");
      watchpn_index := find_index("_ed_watchpoint_disabled.svg");

      breakpn_index := find_index("_ed_breakpoint_disabled.svg",PICTURE_TYPE);
      execbn_index := find_index("_ed_exec_breakpoint_disabled.svg",PICTURE_TYPE);
      stackbn_index := find_index("_ed_stack_breakpoint_disabled.svg",PICTURE_TYPE);
      execgo_index := find_index("_ed_exec_go.svg",PICTURE_TYPE);
      stackgo_index := find_index("_ed_stack_go.svg",PICTURE_TYPE);

      annotation_index := find_index("_ed_annotation.svg",PICTURE_TYPE);
      annotationgray_index := find_index("_ed_annotation_disabled.svg",PICTURE_TYPE);
      bookmark_index := find_index("_ed_bookmark.svg",PICTURE_TYPE);
      pushbm_index := find_index("_ed_bookmark_pushed.svg",PICTURE_TYPE);

      edplus_index := find_index("_ed_plus.svg",PICTURE_TYPE);
      edminus_index := find_index("_ed_minus.svg",PICTURE_TYPE);

      _PicSetOrder(breakpt_index,VSPIC_ORDER_BPM,0);
      _PicSetOrder(execbrk_index,VSPIC_ORDER_BPM,0);
      _PicSetOrder(stackbrk_index,VSPIC_ORDER_BPM,0);
      _PicSetOrder(watchpt_index,VSPIC_ORDER_BPM,0);
      _PicSetOrder(watchpn_index,VSPIC_ORDER_BPM,0);

      _PicSetOrder(breakpn_index,VSPIC_ORDER_BPM,0);
      _PicSetOrder(execbn_index,VSPIC_ORDER_BPM,0);
      _PicSetOrder(stackbn_index,VSPIC_ORDER_BPM,0);

      _PicSetOrder(execpt_index,VSPIC_ORDER_DEBUGGER,0);
      _PicSetOrder(stackexc_index,VSPIC_ORDER_DEBUGGER,0);
      _PicSetOrder(execgo_index,VSPIC_ORDER_DEBUGGER,0);
      _PicSetOrder(stackgo_index,VSPIC_ORDER_DEBUGGER,0);

      _PicSetOrder(annotation_index,VSPIC_ORDER_ANNOTATION,0);
      _PicSetOrder(annotationgray_index,VSPIC_ORDER_ANNOTATION_GRAY,0);
      _PicSetOrder(bookmark_index,VSPIC_ORDER_SET_BOOKMARK,0);
      _PicSetOrder(pushbm_index,VSPIC_ORDER_PUSHED_BOOKMARK,0);

      _PicSetOrder(edplus_index,VSPIC_ORDER_PLUS,0);
      _PicSetOrder(edminus_index,VSPIC_ORDER_MINUS,0);
   }
}

int _GetDialogHistoryViewId()
{
   int *view_id = _GetDialogInfoHtPtr(DIALOG_HISTORY_VIEW_ID, _mdi);
   if (view_id!=null && _iswindow_valid(*view_id)) {
      return *view_id;
   }

   dialogs_view_id := 0;
   int orig_view_id=_find_or_create_temp_view(dialogs_view_id,"+futf8 +70 +t",".dialogs",false,VSBUFFLAG_THROW_AWAY_CHANGES,true);
   activate_window(orig_view_id);
   _SetDialogInfoHt(DIALOG_HISTORY_VIEW_ID, dialogs_view_id, _mdi);
   return dialogs_view_id;
}
int _GetMonCfgDialogHistoryViewId()
{
   int *view_id = _GetDialogInfoHtPtr(MONCFG_DIALOG_HISTORY_VIEW_ID, _mdi);
   if (view_id!=null && _iswindow_valid(*view_id)) {
      return *view_id;
   }

   dialogs_view_id := 0;
   int orig_view_id=_find_or_create_temp_view(dialogs_view_id,"+futf8 +70 +t",".moncfg_dialogs",false,VSBUFFLAG_THROW_AWAY_CHANGES,true);
   activate_window(orig_view_id);
   _SetDialogInfoHt(MONCFG_DIALOG_HISTORY_VIEW_ID, dialogs_view_id, _mdi);
   return dialogs_view_id;
}

_str _log_path(_str configPath = "")
{
   if (configPath == "") {
      configPath = _ConfigPath();
   }

   return configPath :+ "logs" :+ FILESEP;
}

_str _temp_path()
{
   _str path=_spill_file_path();
   if (path=="") {
      if (_isWindows()) {
         path=get_env("TEMP");
      }
      if (path=="") {
         path=get_env("TMP");
      }
   }
   if (path=="") {
      if (_isUnix()) {
         path="/tmp/";
      } else {
         path='c:\temp\';
      }
   }
   _maybe_append_filesep(path);
   return(path);
}
/**
 * @return Returns a filename which does not yet exist for storing temporary
 * data on disk.  The name returned is based on the process id, the current
 * buffer id, and a count (1-99).  The path on the temp name is the same as your
 * spill file path (CONFIG, "Spill file path...").  <i>start_number</i> is an
 * optional number to start the count.  If you write a macro which needs more
 * than one temp file at a time, increment the <i>start_number</i> to enhance
 * the speed of this procedure.
 *
 * <p>If a unique name can not be created after 99 tries, "" is returned.</p>
 *
 * @categories Miscellaneous_Functions
 *
 */
_str mktemp(int start=1,_str Extension="")
{
   _str path=_temp_path();
   int i,pid=getpid();
   int buf_id;
   for (i=start; i<=99 ; ++i) {
      buf_id=0;
      if (p_HasBuffer) {
         buf_id=p_buf_id;
      }
      name := path:+substr(pid,1,6,"0"):+"-"i"b"buf_id:+Extension;
      if ( file_match("-p "_maybe_quote_filename(name),1)=="" ) {
         return(name);
      }
   }
   return("");
}
_str mktempdir(int start=1,_str dir_prefix="slkdir",bool deltree_first=false) {
   _str path=_temp_path();
   int i,pid=getpid();
   int buf_id;
   for (i=start; i<=99 ; ++i) {
      name := path:+dir_prefix:+substr(pid,1,6,"0"):+"-"i;
      if ( file_match("-p "_maybe_quote_filename(name),1)=="" ) {
         return(name:+FILESEP);
      }
      if (deltree_first) {
         _DelTree(name,true);
         if ( file_match("-p "_maybe_quote_filename(name),1)=="" ) {
            return(name:+FILESEP);
         }
      }
   }
   return("");
}

void _on_keystatechange(int shiftnum = -1,bool IsKeydownEvent = false)
{
   if (shiftnum < 0) {
      return; //inadvertant call
   }
   //say("_on_keystatechange k="event2name(last_event())" shiftnum="shiftnum);
   // IF this was a keydown event and the Right Control key was down
   if (IsKeydownEvent && shiftnum==1 && def_keys=="ispf-keys") {
      if (def_ispf_flags & VSISPF_RIGHT_CONTROL_IS_ENTER) {
         if (_isEditorCtl()) {
            if (!_isdiffed(p_buf_id)) {
               ispf_do_lc();
               refresh();
            }
         } else if (p_window_id==_cmdline) {
            command_execute();
            refresh();
         }
      }
      //say("IsKeydownEvent="IsKeydownEvent);
      //say("shiftnum="shiftnum);
   }
   if (_IsKeyDown(CTRL)) {
      _UpdateURLsMousePointer(true);
   } else {
      _UpdateURLsMousePointer(false);
   }
#if 0
   if (_IsKeyDown(CTRL)) {
      //say("_on_keystatechange: CTRL DOWN");
      if (!gsmartnextwindow_state) {
         gsmartnextwindow_state=1;
         gorig_wid=_mdi.p_child;
         if (gorig_wid.p_window_flags & HIDE_WINDOW_OVERLAP) {
            gorig_wid=0;
         }
      }
      //say("down N="gorig_wid.p_buf_name);
   } else {
      //say("_on_keystatechange: CTRL UP");
      gsmartnextwindow_state=0;
      //say("up N="gorig_wid);
      int final_wid=_mdi.p_child;
      if (!(final_wid.p_window_flags & HIDE_WINDOW_OVERLAP) &&
           (_iswindow_valid(gorig_wid) && gorig_wid.p_mdi_child) &&
          final_wid!=gorig_wid) {
         if (_default_option(VSOPTION_NEXTWINDOWSTYLE)==1) {
            // Put final before original
            //say("_on_keystatechange: reorder N="gorig_wid.p_buf_name" f="final_wid.p_buf_name);
            gorig_wid._MDIReorder(final_wid);
         }
      }
      gorig_wid=0;
   }
#endif
}
/**
 * Determines if there is another window viewing a buffer.  This function also
 * searchings windows created by _create_temp_view() and _open_temp_view() functions.
 *
 * <xmp>
 *
 * Some case analysis
 *   assertion:  IF an mdi child is viewing a buffer, p_buf_flags
 *               must not have the VSBUFFLAG_HIDDEN flag!
 *   assertion:  no views of a buffer created by _open_temp_view can
 *               hang around such the user has time to do delete the buffer.
 * </xmp>
 *
 * @param buf_id    Buffer id
 * @param skip_wid  Window to ignore
 *
 * @return Returns true if there is a window other than <i>skip_wid</i> displaying this buffer.
 */
bool _DialogViewingBuffer(int buf_id,int skip_wid=0)
{
   int i;
   for (i=1;i<=_last_window_id();++i) {
      if (i!=skip_wid && _iswindow_valid(i) && !i.p_mdi_child &&
          i.p_HasBuffer && !i.p_IsMinimap && i.p_buf_id==buf_id && i!=VSWID_HIDDEN
          ) {
         return(true);
      }
   }
   return(false);
}
/**
 * Tests whether it is safe to delete a buffer currently being
 * viewed by a dialog or a view created by
 * _create_temp_view() or _open_temp_view().
 *
 * <P>
 * Note that this function does not check if an MDI
 * window is viewing this buffer or if a buffer is
 * part of the MDI buffer ring !(p_buf_flags & VSBUFFLAG_HIDDEN).
 * This is why the _window_quit() function does not call this function.
 *
 * @param buf_id    Buffer id.  p_buf_id.
 * @param skip_dialog_wid
 *                  Window ID (p_window_id) of the dialog window viewing
 *                  this buffer.  This should be 0 when calling to delete
 *                  a buffer viewed by _create_temp_view() or _open_temp_view().
 * @param buf_flags Buffer flags (p_buf_flags) of the buffer you might delete.
 * @return Returns true if it is safe to delete the buffer.
 */
bool _SafeToDeleteBuffer(int buf_id,int skip_dialog_wid=0,int buf_flags=0)
{
   return(!(buf_flags & VSBUFFLAG_KEEP_ON_QUIT) &&
          !_DialogViewingBuffer(buf_id,skip_dialog_wid));
}

int load_picture(int option,_str filename)
{
   int result=_update_picture(option,filename);
   if (result<0) {
      if (result==FILE_NOT_FOUND_RC) {
         _message_box(nls('File "%s" not found',filename));
      } else {
         _message_box(nls('Unable to load picture "%s"',filename)". "get_message(result));
      }
      rc=result;
   }
   return(result);
}

/**
 * Clears the message on the message line.
 *
 * @categories Miscellaneous_Functions
 */
_command void cmdclear_message()
{
   clear_message();
}
void _on_command_not_allowed()
{
   //message(nls("Command not allowed"));
   //_message_box(nls("Command not allowed"));
}
/**
 * The editor invokes this command when the user presses a key that has no
 * definition, or a mouse event occurs that has no binding.
 *
 * @categories Keyboard_Functions
 *
 */
_command void key_not_defined() name_info(','VSARG2_LASTKEY|VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   switch (last_event()) {
   case ON_NUM_LOCK:
      return;
   }
   int index=event2index(last_event());
   if ( !vsIsMouseEvent(index)) {
      message(nls("Key not defined"));
   }
}
/**
 * @return Returns a string message indicating what was changed by an undo or
 * redo operation.  The input <i>status</i> parameter must be a positive
 * return value from the <b>undo</b> built-in.  If the <b>undo</b>
 * built-in returns a negative return code, do not call this procedure with
 * that value.
 *
 * @categories Miscellaneous_Functions
 *
 */
_str undo_msg(int status)
{
   msg := "";
   if ( status&LINE_INSERTS_UNDONE ) {
      msg=nls("Line insert(s),");
   }
   if ( status&LINE_DELETES_UNDONE ) {
      msg :+= nls("Line delete(s),");
   }
   if ( status&MARK_CHANGE_UNDONE ) {
      msg :+= nls("Mark change,");
   }
   if ( status&TEXT_CHANGE_UNDONE ) {
      msg :+= nls("Text change,");
   }
   if ( status&CURSOR_MOVEMENT_UNDONE ) {
      msg :+= nls("Cursor movement,");
   }
   if (status & LINE_FLAGS_UNDONE) {
      msg :+= nls("Line flags,");
   }
   if (status & FILE_FORMAT_CHANGE_UNDONE) {
      msg :+= nls("File Format Change,");
   }
   if (status & COLOR_CHANGE_UNDONE) {
      msg :+= nls("Color Change,");
   }
   if (status & MARKUP_CHANGE_UNDONE) {
      msg :+= nls("Markup Change,");
   }
   msg=strip(msg,'T',','):+' 'nls("undone");
   if ( p_undo_steps==0 ) {
      msg=nls("Undo not on");
   }
   return(msg);

}

static _str past_save(...)
{
   bool b;
   if ( undo_past_save && def_undo_past_save_prompt) {
      _str name= name_name(prev_index('','C'));
      if ( arg(1)!="" ) {
         b = (name=="redo");
      } else {
         b = (name=="undo" || name=="undo-line" || name=="undo-cursor");
      }
      if ( b && _need_to_save2()) {
         flush_keyboard();
         int result=_message_box(nls("You are about to undo past previous save.\nContinue?"),"",MB_ICONQUESTION|MB_YESNOCANCEL);
         if ( result!=IDYES) {
            return(1);
         }
      }
      undo_past_save=false;
   }
   return(0);

}

int _OnUpdate_undo(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid ) {
      return(MF_GRAYED);
   }
   if ( target_wid.p_object==OI_TEXT_BOX || target_wid.p_object==OI_COMBO_BOX) {
      if (target_wid._undo_status():==NOTHING_TO_UNDO_RC) {
         return(MF_GRAYED);
      }
      return(MF_ENABLED);
   }
   if ( !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (_isdiffed(target_wid.p_buf_id) && target_wid.p_mdi_child) {
      return(MF_GRAYED);
   }
   if (target_wid._undo_status():==NOTHING_TO_UNDO_RC) {
      // Return BOTH GRAYED and ENABLED.  This is because the command
      // should remain enabled so that it can be ran from a keystroke
      // or the command line, but it should appear grayed on the menu
      // and button bars.  This allows undo to report that there is
      // nothing more to undo.
      return MF_GRAYED|MF_ENABLED;
   }
   return MF_ENABLED;
}

/**
 * If this is set to true, undo will undo each individual cursor movement.
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_undo_with_cursor=false;

/**
 * <p>If the current buffer allows more than 0 undoable steps, the last
 * operation is undone.  Cursor movement, scrolling, editing, and
 * selection changes are undoable.  Undo does not affect disk files.  To
 * set the maximum number of undoable steps for the current buffer, use
 * the <b>undo_steps</b> command.  To set the maximum number of
 * undoable steps for files not yet loaded, use the <b>File
 * Options</b>.</p>
 *
 * <p>If the current buffer has 0 undoable steps, the current line is restored to
 * its original value before the cursor moved onto it.</p>
 *
 * <p>If {@link def_undo_with_cursor} is false, this behaves the
 * same as undo_cursor.  This is because most emulations actually need
 * undo_cursor, but we want the older funcitonality to be available.</p>
 *
 * @see redo
 * @see undo_steps
 * @see undo_cursor
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command undo() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX/*|VSARG2_NOEXIT_SCROLL*/)
{
   if (command_state()) {
      _undo();
      return 0;
   }
   if ( past_save() ) {
      return(1);
   }
   undo_opt := def_undo_with_cursor?"":"C";
   if (def_keys=="vi-keys" && vi_get_vi_mode()=="C") {
      undo_opt="V";
   }
   int status=_undo(undo_opt);
   if ( status>=0 && !_IsKeyPending(true,true) ) {
      message(undo_msg(status));
   } else {
      message(get_message(status));
   }
   undo_past_save=(status>=0 && (status&MODIFY_FLAG_UNDONE));
   return(status);
}
int _OnUpdate_undo_cursor(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_undo(cmdui,target_wid,command));
}
/**
 * This command is identical to the <b>undo</b> command except that
 * consecutive steps that are just cursor motion are undone in one step.
 * Use this command instead of the <b>undo</b> command when you
 * are only interested in seeing text changes undone.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command undo_cursor() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX/*|VSARG2_NOEXIT_SCROLL*/)
{
   if (command_state()) {
      _undo();
      return 0;
   }
   if ( past_save() ) {
      return(1);
   }
   int status=_undo('C');
   if ( status>=0 && !_IsKeyPending(true,true) ) {
      message(undo_msg(status));
   } else {
      message(get_message(status));
   }
   undo_past_save=(status>=0 && (status&MODIFY_FLAG_UNDONE));
   return(status);
}
int _OnUpdate_redo(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid ) {
      return(MF_GRAYED);
   }
   if ( target_wid.p_object==OI_TEXT_BOX || target_wid.p_object==OI_COMBO_BOX) {
      if (target_wid._undo_status('r'):==NOTHING_TO_REDO_RC) {
         return(MF_GRAYED);
      }
      return(MF_ENABLED);
   }
   if ( !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (_isdiffed(target_wid.p_buf_id) && target_wid.p_mdi_child) {
      return(MF_GRAYED);
   }
   if (target_wid._undo_status('r'):==NOTHING_TO_REDO_RC) {
      // Return BOTH GRAYED and ENABLED.  This is because the command
      // should remain enabled so that it can be ran from a keystroke
      // or the command line, but it should appear grayed on the menu
      // and button bars.  This allows redo to report that there is
      // nothing more to redo.
      return MF_GRAYED|MF_ENABLED;
   }
   return MF_ENABLED;
}
/**
 * <p>If the current buffer allows more than 0 undoable steps, the last undo
 * operation is redone.  Use the <b>undo</b> command to undo
 * mistakes made while using redo.</p>
 *
 * <p>If the current buffer has 0 undoable steps, the current line is restored to
 * its original value before the cursor moved onto it.</p>
 *
 * @return On successful completion, a descriptive message of what was redone
 * is displayed and a number greater than or equal to zero is returned.
 * Common negative error codes are NOTHING_TO_UNDO_RC, and
 * NOTHING_TO_REDO_RC.  On error, message is displayed.
 *
 * @see undo
 * @see undo_steps
 * @see undo_cursor
 *
 * @categories Miscellaneous_Functions
 *
 */
_command redo() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   if (command_state()) {
      _undo('r');
      return 0;
   }
   if ( past_save('r') ) {
      return(1);
   }
   int status=_undo('r');
   if ( status>=0 && !_IsKeyPending(true,true) ) {
      message(undo_msg(status));
   } else {
      message(get_message(status));
   }
   undo_past_save=(status>=0 && (status&MODIFY_FLAG_UNDONE));
   return(status);

}
// Convert an ISPF picture string to/from a SlickEdit
// regular expression and back.
_str ispf_convert_re(_str searchString,bool reverse=false)
{
   result := "";
   int i,n=length(searchString);
   for (i=1;i<=n;++i) {
      ch := substr(searchString,i,1);
      add := "";
      //say("ispf_convert_re: ch='"ch"'");
      if (reverse==true) {
         if (ch=="[") {
            p := pos("]",searchString,i);
            if (p) {
               ch=substr(searchString,i,p-i+1);
               i=p;
            }
         }
         switch (ch) {
         case "?":
            add="=";
            break;
         case '[~ \t]':
         case '[^ \t]':
            add="^";
            break;
         case '[~\x20-\x7e]':
         case '[^\x20-\x7e]':
            add=".";
            break;
         case "[0-9]":
            add="#";
            break;
         case "[~0-9]":
         case "[^0-9]":
            add="-";
            break;
         case "[a-zA-Z]":
            add="@";
            break;
         case "[a-z]":
            add="<";
            break;
         case "[A-Z]":
            add=">";
            break;
         case '[~ \ta-zA-Z0-9]':
         case '[^ \ta-zA-Z0-9]':
            add="$";
            break;
         default:
            if (substr(ch,1,1)=="[" &&
                isalpha(substr(ch,2,1)) &&
                substr(ch,3,1)==upcase(substr(ch,2,1)) &&
                substr(ch,4,1)=="]") {
               add=substr(ch,2,1);
            } else if (ch=='\') {
               ++i;
               add=substr(searchString,i,1);
            } else {
               add=ch;
            }
         }
      } else {
         switch (ch) {
         case "=":
            add="?";
            break;
         case "^":
            add='[~ \t]';
            break;
         case ".":
            add='[~\x20-\x7e]';
            break;
         case "#":
            add="[0-9]";
            break;
         case "-":
            add="[~0-9]";
            break;
         case "@":
            add="[a-zA-Z]";
            break;
         case "<":
            add="[a-z]";
            break;
         case ">":
            add="[A-Z]";
            break;
         case "$":
            add='[~ \ta-zA-Z0-9]';
            break;
         default:
            if (isalpha(ch)) {
               add="["lowcase(ch):+upcase(ch)"]";
            } else {
               add=_escape_re_chars(ch);
            }
         }
      }
      strappend(result,add);
   }
   return(result);
}
/**
 * Handle the ENTER key or right-control key in ISPF emulation.  On the
 * command line, this behaves like a normal enter key.  Otherwise,
 * this moves the cursor down and to the beginning of the next line.
 * If the line is a newly inserted line, it places the cursor in column
 * one, otherwise, it places the cursor in the prefix area allowing you
 * to enter line commands.  In addition, this command will cause the
 * line commands to be executed.
 *
 * @return True if in ISPF mode and the event was processed, otherwise, returns false.
 *
 * @see help:ISPF Line Commands
 *
 * @categories ISPF_Emulation_Commands
 *
 */
_command bool ispf_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (def_keys=="ispf-keys") {
      if (command_state()) {
         command_execute();
         return(true);
      }
      if (_isEditorCtl()) {
         if (!_isdiffed(p_buf_id)) {

            // guard against infinite recursion
            static bool inHandler;
            if (inHandler) return false;
            inHandler = true;

            // Trying to detect a null line has been entered.
            // This will end certain commands like I with no number
            // which will continually insert lines until a null line is
            // entered.

            processed := false;
            get_line(auto line);
            if(p_LCHasCursor == false && line == "") {
               processed = ispf_process_return(true);
            } else if(p_col >= 2) {
               processed = ispf_process_return(false);
            }

            if(processed) {
               inHandler = false;
               return true;
            }

            orig_col := p_col;
            cursor_down();
            p_col=1;
            if ((p_LCBufFlags & VSLCBUFFLAG_READWRITE) &&
                (def_ispf_flags & VSISPF_CURSOR_TO_LC_ON_ENTER)) {
               // Place cursor in prefix area
               p_LCHasCursor=true;
               p_LCCol=1;
            }
            if (!(def_ispf_flags & VSISPF_RIGHT_CONTROL_IS_ENTER)) {
               ispf_do_lc(orig_col);
            }
            inHandler = false;
            return(true);
         }
      }
      //say("IsKeydownEvent="IsKeydownEvent);
      //say("shiftnum="shiftnum);
   }
   return(false);
}

// split/insert line set cursor position, to smart indent
// on exit, the cursor is in the smart indent column on the new line
void ispf_split_line(_str split_line_func="split-insert-line")
{
   // find what command ENTER is bound
   int default_index=eventtab_index(_default_keys,_default_keys,event2index(ENTER));
   int mode_index=default_index;
   if (p_mode_eventtab) {
      mode_index=eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(ENTER));
   }
   split_index := find_index(split_line_func,PROC_TYPE|COMMAND_TYPE);
   if (!split_index || !index_callable(split_index)) {
      return;
   }
   if (mode_index && default_index!=mode_index) {
      // if ENTER has been rebound, then execute that enter,
      // it will do the smart indenting
      old_keys := def_keys;
      def_keys="windows-keys";
      int root_binding_index=eventtab_index(_default_keys,_default_keys,event2index(ENTER));
      orig_modify:=_eventtab_get_modify(_default_keys);
      set_eventtab_index(_default_keys,event2index(ENTER),split_index);
      last_event(ENTER);
      _argument=1;
      call_index(mode_index);
      _argument="";
      set_eventtab_index(_default_keys,event2index(ENTER),root_binding_index);
      _eventtab_set_modify(_default_keys,orig_modify);
      def_keys=old_keys;
   } else {
      // ENTER is not rebound, so just split/insert line
      old_keys := def_keys;
      def_keys="windows-keys";
      call_index(split_index);
      def_keys=old_keys;
   }
}

// insert a blank line below the cursor
_command void insert_blankline_below() name_info(','VSARG2_MULTI_CURSOR|VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   orig_strict_nosplit_insert_line := def_strict_nosplit_insert_line;
   def_strict_nosplit_insert_line = true;
   nosplit_insert_line();
   def_strict_nosplit_insert_line = orig_strict_nosplit_insert_line;
}
// insert a blank line above the cursor
_command void insert_blankline_above()  name_info(','VSARG2_MULTI_CURSOR|VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   orig_strict_nosplit_insert_line := def_strict_nosplit_insert_line;
   def_strict_nosplit_insert_line = true;
   nosplit_insert_line_above();
   def_strict_nosplit_insert_line = orig_strict_nosplit_insert_line;
}

// insert line (maybe split it) set cursor position, to smart indent
// on exit, the cursor is in the smart indent column on the new line
_command void ispf_split_insert_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   ispf_split_line("split-insert-line");
}

// insert line (maybe split it) set cursor position, to smart indent
// on exit, the cursor is in the smart indent column on the new line
_command void ispf_nosplit_insert_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   ispf_split_line("nosplit-insert-line");
}

// insert line (maybe split it) set cursor position, to smart indent
// on exit, the cursor is in the smart indent column on the new line
_command void ispf_maybe_split_insert_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   ispf_split_line("maybe-split-insert-line");
}

_str def_auto_reset;        /* If non-zero, reset-next-error is called. */
                       /* before a compile or make commands is executed. */

void _smart_enter_with_fall_thru(int smart_enter_index, _str enter_command) {
   int index=eventtab_index(_default_keys,_default_keys,event2index(ENTER));
   orig_modify:=_eventtab_get_modify(_default_keys);
   set_eventtab_index(_default_keys,event2index(ENTER),
                      find_index(enter_command,COMMAND_TYPE));
   call_index(smart_enter_index);
   set_eventtab_index(_default_keys,event2index(ENTER),index);
   _eventtab_set_modify(_default_keys,orig_modify);
}
/**
 * If the visible cursor is on the command line, the command is executed.
 * Otherwise a blank line is inserted after the current line and the cursor is
 * aligned with the first non blank character of the current line.  The current
 * line will not be split.  See <b>split_insert_line</b>.
 *
 * @appliesTo Edit_Window, Editor_Control, Command_Line
 *
 * @categories Command_Line_Methods, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void nosplit_insert_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( command_state() ) {
      command_execute();
      return;
   }

   // process ISPF line commands
   if (name_name(last_index()) != "ispf-nosplit-insert-line") {
      if (ispf_enter_key_handler("nosplit-insert-line")) return;
   }

   if ( p_window_state:=="I" ) {
      p_window_state="N";
      return;
   }
   if (_QReadOnly()) {
      _readonly_error(0);
      return;
   }
   // For better BRIEF emulation, ctrl+enter is set to nosplit_insert_line
   // nosplit_insert_line command should still perform smart indenting.
   // If last event
   if (last_event():!=ENTER && last_event():!=" " &&
       ((!_process_info('b') && name_on_key(last_event())!='keyin-enter') ||
         (_process_is_interactive_idname(_ConcurProcessName()) && _process_within_submission())
       )
      ) {
      if (_interactive_smart_enter('nosplit_insert_line')) {
         return;
      } else if (_process_info('b')) {
      } else {
         last_event(ENTER);
         int enter_index=eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(ENTER));
         if (enter_index && p_mode_eventtab!=_default_keys) {
            _smart_enter_with_fall_thru(enter_index,"nosplit_insert_line");
            return;
         }
      }
   }
   if (p_hex_mode==HM_HEX_LINE) {
      p_hex_nibble=false;
      p_hex_field=false;
   }
   typeless p;
   if (_on_line0()) {
      insert_line('');
      return;
   }

   save_pos(p);
   _begin_line();
   search('[~ \t]|$','@rh');
   restore_pos(p);
   col := 0;
   // If not on blank line
   if ( match_length() ) {
      _begin_line();
      _refresh_scroll();
      _first_non_blank();
      col=p_col;
   } else {
      col=enter_on_bl();
   }
   _end_line();

   _split_line();down();_begin_line();

   if ( p_indent_style!=INDENT_NONE) {
      if ( LanguageSettings.getInsertRealIndent(p_LangId) ) {
         _insert_text(indent_string(col-1));
         //insert_line(indent_string(col-1));
      } else {
         _insert_text("");
      }
      p_col=col;
   } else {
      _insert_text("");
   }
}

/**
 * If the visible cursor is on the command line, the command is executed.
 * Otherwise a blank line is inserted before the current line and the cursor is
 * aligned with the first non blank character of the current line.  The current
 * line will not be split.  See <b>split_insert_line</b>.
 *
 * @appliesTo Edit_Window, Editor_Control, Command_Line
 *
 * @categories Command_Line_Methods, Edit_Window_Methods, Editor_Control_Methods
 */
_command nosplit_insert_line_above() name_info(','VSARG2_MULTI_CURSOR|VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if(_isEditorCtl()) {
      up();
   }
   orig_strict_nosplit_insert_line := def_strict_nosplit_insert_line;
   def_strict_nosplit_insert_line = true;
   nosplit_insert_line();
   def_strict_nosplit_insert_line = orig_strict_nosplit_insert_line;
}

/**
 * Typically used by a command which is bound to the ENTER key.  Called when
 * ENTER key is pressed on a blank line.
 *
 * @return  Returns the column position where the cursor should be placed on
 * a new line that is inserted by an ENTER key command.  You may want to write a
 * replacement for this procedure.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
int enter_on_bl() {
   /*  leave the cursor position alone. */
   return p_col;
}

/**
 * Executes the command on the command line and moves the cursor back
 * to the text area if the variable <b>def_stay_on_cmdline</b> is 0.
 * This function is useful for ENTER key commands.
 *
 * @categories Command_Line_Functions
 */
void command_execute()
{
   orig_wid := p_window_id;

   int child_wid=_MDICurrentChild(0);
   ncw := child_wid==0;
   if (ncw) {
      if (!def_stay_on_cmdline) {
         VSWID_STATUS._set_focus();
      }
   } else {
      cursor_data();
      old_wid := p_window_id;
      refresh();
      p_window_id=old_wid;
   }
   if (substr(_cmdline.p_text,1,1)=="@") {
      _cmdline.set_command("",1);
      message(get_message(COMMAND_NOT_FOUND_RC));
      return;
   }
   //say("_mac="_macro());
   _str command;
   if ( _macro() ) {
      _cmdline.get_command(command);
      _macro_call("execute",command,"a");
   }
   _macro('m',_macro());
   //say("h2 _mac="_macro());
   last_index(prev_index());

   override_stay_on_cmdline := false;
   orig_cmdline := _cmdline.p_text;
   cmdline := _cmdline.p_text;
   _str cmdname;
   if (def_keys=="ispf-keys") {
      ispf_do_lc();
      cmdline=strip(cmdline,'L');
      parse cmdline with cmdname .;
      cmdname=lowcase(cmdname);
      switch (cmdname) {
      case "c":
      case "chg":
      case "change":
      case "find":
      case "f":
      case "rfind":
      case "rchange":
         override_stay_on_cmdline=true;
         break;
      }
      //say("**cmdname="cmdname);
      if (find_index("ispf-"cmdname,COMMAND_TYPE|IGNORECASE_TYPE)) {
         cmdline="ispf-"substr(lowcase(cmdname),1,length(cmdname)):+substr(cmdline,length(cmdname)+1);
      }
   }
   //say("override"override_stay_on_cmdline);
   //say("cmdline="cmdline);
   append_retrieve_command(orig_cmdline);
   _str text;
   int status;
   if (def_unix_expansion) {
      /* Execute result of function call. */
      text=cmdline;
      _cmdline.set_command("",1);
      status=execute(_maybe_unix_expansion(text),'a');
   } else {
      _cmdline.set_command("",1);
      status=execute(cmdline,'a');
   }

   // log this guy in the pip
   if (_pip_on) {
      _pip_log_command_event(cmdline, PCLM_COMMAND_LINE);
   }

   if (_no_child_windows()) {
      if (status==UNKNOWN_COMMAND_RC) {
         _beep();
      } else if (isinteger(status) && status<0 &&
                 status!=COMMAND_CANCELLED_RC) {
         _message_box(get_message(status));
      }
   }

   if (def_stay_on_cmdline /*&& def_keys=='ispf-keys'*/ && !override_stay_on_cmdline &&
       orig_wid==_cmdline && (p_mdi_child || _no_child_windows())) {
      _str ssmessage=get_message();
      if (ssmessage!="") {
         clear_message();
         refresh();
         _message_box(ssmessage,"",MB_OK|MB_ICONINFORMATION);
      }
      _cmdline._set_focus();
   }
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_ONE_FILE_PER_WINDOW)) {
      def_one_file="+w";
   }
}
bool _insertion_valid(bool quiet=false)
{
   if (p_TruncateLength && p_col>_TruncateLengthC()+1) {
      if (!quiet) {
         message(get_message(VSRC_THIS_OPERATION_IS_NOT_ALLOWED_AFTER_TRUNCATION_LENGTH));
         _beep();
      }
      return(false);
   }
   return(true);
}

/**
 * Handle processing ISPF line commands if we are in a mode which does not have a specific
 * event handler for Enter (and thus is not instrumented with a call to ispf_common_enter).
 */
static bool ispf_enter_key_handler(_str commandName)
{
   // do nothing if on the command line or not an editor control
   if (command_state() || !_isEditorCtl()) return false;

   // check if there is something for handling Enter in this language mode
   // make sure that the mode's event table doesn't just point to the same command
   modeIndex := 0;
   if (p_mode_eventtab) {
      modeIndex = eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(ENTER));
      if (modeIndex > 0) {
         commandIndex := find_index(commandName, COMMAND_TYPE);
         if (modeIndex != commandIndex) return false;
      }
   }

   // finally, delegate to calling ISPF enter
   return ispf_enter();
}

/**
 * If the visible cursor is on the command line, the command is executed.
 * Otherwise the current line is split at the cursor.  Enough blanks are
 * appended to the beginning of the new line to align it with the first non
 * blank character of the original line.
 *
 * @appliesTo Edit_Window, Editor_Control, Command_Line
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void split_insert_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   // execute this as a command
   if ( command_state() ) {
      command_execute();
      return;
   }

   // process ISPF line commands
   if (name_name(last_index()) != "ispf-split-insert-line") {
      if (ispf_enter_key_handler("split-insert-line")) return;
   }

   // we're just selecting an iconized window to make big
   if ( p_window_state:=='I' ) {
      p_window_state='N';
      return;
   }
   if (last_event():!=ENTER && last_event():!=" " &&
       ((!_process_info('b') && name_on_key(last_event())!='keyin-enter') ||
         (_process_is_interactive_idname(_ConcurProcessName()) && _process_within_submission())
       )
      ) {
      if (_interactive_smart_enter('split_insert_line')) {
         return;
      } else if (_process_info('b')) {
      } else {
         last_event(ENTER);
         int enter_index=eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(ENTER));
         if (enter_index && p_mode_eventtab!=_default_keys) {
            _smart_enter_with_fall_thru(enter_index,"split_insert_line");
            return;
         }
      }
   }

   // this file's readonly, you can't do that!
   if (_QReadOnly()) {
      _readonly_error(0);
      return;
   }

   // some checks for hex mode
   if (p_hex_mode==HM_HEX_LINE) {
      p_hex_nibble=false;
      p_hex_field=false;
   }

   // if we're on the top line of the file, just insert a blank line and be done with it
   if (_on_line0()) {
      insert_line("");
      //p_col=orig_col;
      return;
   }

   orig_col := p_col;        // save our original column
   indent_col := 0;
   if ( p_indent_style!=INDENT_NONE ) {
      // we're using something complicated to indent, either auto or smart
      _begin_line();
      _refresh_scroll();

      if (_expand_tabsc()!="") _first_non_blank();
      // check to see if our cursor is at or past the end of the line
      if (p_col>_text_colc(0,'E')) {
         p_col=orig_col;
         indent_col=enter_on_bl();        // use this to figure indent
         p_col=orig_col;
      } else {
         // otherwise, we're splitting the line
         indent_col=p_col;
         if (p_col<orig_col) {
            p_col=orig_col;
         }
      }
   } else {
      // this indent style is easy - just go to column 1
      indent_col=1;
      p_col=orig_col;
   }

   int flags=_lineflags();       // get the current line status
   RestoreLineModifyFlags := false;        // we might set this to true
   // are we past/at the end of the line?
   if (p_col>_text_colc()) {
      if (p_buf_width) {
         // Record files have no NLChars.  _split_line
         // won't insert any either.
         RestoreLineModifyFlags=true;
      } else {
         // we're going to add some newline characters
         p_col=_text_colc()+1;
         _str NLChars=get_text(_line_length(true)-_line_length());
         if (NLChars:==p_newline) {
            RestoreLineModifyFlags=true;
         }
      }
   }
   if( _on_line0() || indent_col!=p_col || _expand_tabsc(1,p_col-1)!="" ) {
      // determine if the line after the cursor is blank
      restOfLineBlank := _expand_tabsc(p_col):=="";
      _split_line();
      if (RestoreLineModifyFlags) {       // set this modified line flags here
         _lineflags(flags,MODIFY_LF|INSERTED_LINE_LF);
      }
      down();

      // Insert real indent if option on or when pushing text to right
      if (LanguageSettings.getInsertRealIndent(p_LangId) || !restOfLineBlank) {
         _begin_line();
         _str result=indent_string(indent_col-1);
         _insert_text(result);
      } else {
         p_col=indent_col;
      }
   } else {

      // Do not split the line, but rather insert a new line above, which
      // "pushes" the current line down. We do this to preserve breakpoints
      // and PIC data on the current line.
      // insert a blank line
      line := "";
      // unless there are spaces/tabs on this line, then we insert that
      int curline_flags=_lineflags();
      get_line(auto curline);
      if (_expand_tabsc(p_col)=="") {
         get_line_raw(line);
      }
      up();

      insert_line(line);
      // (clark) I think this is always true
      if (line=="") {
         /*
            Make this look like _split_line was called.
            This is a little smarter than _split_line. _split_line always sets the current
            line of the split as modified. Here we make this emulate press enter in the middle
            versus the end of line.
         */
         if (curline=="") {
            // <enter>
            _lineflags(curline_flags&(MODIFY_LF|INSERTED_LINE_LF), MODIFY_LF|INSERTED_LINE_LF);
         } else {
            // <whitespace><enter> more text here
            _lineflags(MODIFY_LF|(curline_flags&INSERTED_LINE_LF), MODIFY_LF|INSERTED_LINE_LF);
         }
         down();
         _lineflags(INSERTED_LINE_LF,INSERTED_LINE_LF);
      } else {
         down();
      }
      // Other funcitons (e.g. c_enter) end up calling split_insert_line,
      // so we must position the caret at the correct column so smart language
      // indenting does not mistakenly put in extra indent.
      p_col=indent_col;
   }
}
/**
 * <p>If the cursor is on the command line, the command is executed.</p>
 *
 * <p>Otherwise if insert state is on, the current line is split at the
 * cursor.  Enough blanks are appended to the beginning of the new line to align
 * it with the first non blank character of the original line.</p>
 *
 * <p>If the insert state is off, the cursor is moved to column one of the
 * next line.</p>
 *
 * @appliesTo Edit_Window, Editor_Control, Command_Line
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void maybe_split_insert_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   // process ISPF line commands
   if (name_name(last_index()) != "ispf-maybe-split-insert-line") {
      if (ispf_enter_key_handler("maybe-split-insert-line")) return;
   }

   if ( command_state() || _insert_state()) {
      _macro('m', _macro('s'));
      if (last_event()==ENTER && _maybeSplitLineComment()) {
         return;
      }
      split_insert_line();
      return;
   }
   if ( p_window_state:=='I' ) {
      p_window_state='N';
      return;
   }
   if (_QReadOnly()) {
      _readonly_error(0);
      return;
   }
   if ( down() ) {
      if (p_hex_mode==HM_HEX_LINE) {
         p_hex_nibble=false;
         p_hex_field=false;
      }
      insert_line("");
   }
   _begin_line();

}
/**
 * @return Returns true if ENTER is bound to {@link split_insert_line}
 * or if we are in insert mode and ENTER is bound to {@link maybe_split_insert_line}
 */
bool _will_split_insert_line()
{
   _str enter_cmd = name_on_key(ENTER);
   _str ctrl_enter_key = name2event("C_ENTER");
   if (last_event()==ctrl_enter_key) enter_cmd=name_on_key(ctrl_enter_key);
   if (enter_cmd:=="split-insert-line") return true;
   if (enter_cmd:=="maybe-split-insert-line" && _insert_state()) return true;
   return false;
}
// Returns 0 if tabs not in fixed increment.  Otherwise increment
// is returned.  Returns 0 if first tab stop not 1.
int _tabs_in_fixed_increments()
{
   _str tabs=p_tabs;
   typeless first,next,prev,rest;
   parse tabs with first rest;
   if (first!=true || rest=="") {
      return(0);
   }
   parse rest with prev rest;
   typeless inc=prev-first;
   for (;;) {
      if (rest=="") {
         return(inc);
      }
      parse rest with next rest;
      if (next-prev!=inc) {
         return(0);
      }
   }
}
/**
 * If Indent With Tabs ("Document", "Indent With Tabs") is on and the cursor is
 * on or before the first non-blank character, one more syntax indent level is
 * added to the line.
 * <p>
 * If indent with tabs is on and the cursor is after the first non-blank
 * character, a tab character is inserted.
 * <p>
 * If indent with tabs is off, the cursor is moved to the next indent level.
 *
 * @see indent_with_tabs
 * @see tabs
 * @see gui_tabs
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void ctab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_LINEHEX)
{
   if ( command_state() ) {
      maybe_list_matches("","",true);
      return;
   }
   if (!command_state() && def_modal_tab && select_active() && _within_char_selection()) {
      if (_isnull_selection()) {
         _deselect();
      } else {
         if (_QReadOnly()) {
            _readonly_error(0);
            return;
         }
         indent_selection();
         return;
      }
   }
   if (!command_state() && p_indent_with_tabs ) {
      if (_QReadOnly()) {
         _readonly_error(0);
         return;
      }
      if (!command_state() && _within_char_selection()) maybe_delete_selection();
      if (!_tabs_in_fixed_increments()) {
         keyin("\t");
         return;
      }
      if ( command_state() || _expand_tabsc(1,p_col-1)!="") {
         int state=_insert_state();
         if ( ! _insert_state() ) {
            _insert_toggle();
         }
         keyin("\t");
         if ( state!=_insert_state() ) {
            _insert_toggle();
         }
         return;
      }
      // Don't worry about long line here.  This is for C source.
      get_line(auto line);
      old_col := p_col;
      ptab();
      int syntax_indent=p_col-old_col;
      replace_line(reindent_line(line,syntax_indent));
      return;
   }
   init_command_op();
   ptab();
   retrieve_command_results();
}
bool _in_leading_indent() {
   save_pos(auto p);
   _first_non_blank();
   first_non_blank_col:=p_col;
   restore_pos(p);
   return p_col<=first_non_blank_col;
}
void ptab(...)
{
   int tab_style=_LangGetPropertyInt32(p_LangId,VSLANGPROPNAME_TAB_STYLE);
   if ( tab_style!= VSTABSTYLE_USE_TAB_STOPS &&
        _is_syntax_indent_tab_style_supported(p_LangId) /* && p_indent_style!=INDENT_NONE*/ && p_SyntaxIndent>0 ) {
      if (tab_style==VSTABSTYLE_SYNTAX_INDENT && _in_leading_indent()) {
         //VSTABSTYLE_SYNTAX_INDENT
         col:=p_col;
         col+=(int)(arg(1)p_SyntaxIndent);
         p_col=col;
      } else {
         //VSTABSTYLE_USE_SYNTAX_INDENT_AS_TAB_STOPS
         if (p_fixed_font || !p_width_of_space) {
            if ( arg(1)=="" ) {
               p_col=((p_col-1) intdiv p_SyntaxIndent)*p_SyntaxIndent+1;
            } else {
               p_col=((p_col-2) intdiv p_SyntaxIndent)*p_SyntaxIndent+1+p_SyntaxIndent;
            }
            p_col += (int)(arg(1)p_SyntaxIndent);
         } else {
            orig_col := p_col;
            int textwidth=_TextWidthFromCol(p_col);
            int col;
            if (arg(1)=="") {
               int divs=(textwidth intdiv (p_width_of_space*p_SyntaxIndent));
               int remainder=(textwidth % (p_width_of_space*p_SyntaxIndent));
               Nofspaces:=p_SyntaxIndent-(remainder intdiv p_width_of_space);
               if (Nofspaces<=0) {
                  Nofspaces=p_SyntaxIndent;
               }
               col=orig_col+Nofspaces;
               /*int divs=(textwidth intdiv (p_width_of_space*p_SyntaxIndent));
               col=_ColFromTextWidth((divs+1)*p_width_of_space*p_SyntaxIndent);
               if (col<=orig_col) {
                  col=_ColFromTextWidth((divs+2)*p_width_of_space*p_SyntaxIndent);
               } */
            } else {
               int divs=(textwidth intdiv (p_width_of_space*p_SyntaxIndent));
               col=_ColFromTextWidth((divs)*p_width_of_space*p_SyntaxIndent);
               if (col>=orig_col) {
                  col=_ColFromTextWidth((divs-1)*p_width_of_space*p_SyntaxIndent);
               }
            }
            p_col=col;
         }
      }
   } else {
      if ( arg(1)=="-" ) {
         backtab();
      } else {
         tab();
      }
   }

}
/**
 *
 * Moves the cursor to the previous indent level or tab stop.  To set the tab stops see help on <b>gui_tabs</b> or <b>tabs</b> command.
 *
 * @appliesTo     Text_Box, Combo_Box, Edit_Window, Editor_Control
 *
 * @see ctab
 * @see move_text_tab
 * @see move_text_backtab
 *
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void cbacktab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!command_state() && def_modal_tab && select_active() && _within_char_selection()) {
      if (_isnull_selection()) {
         _deselect();
      } else {
         if (_QReadOnly()) {
            _readonly_error(0);
            return;
         }
         unindent_selection();
         return;
      }
   }
   if (!command_state() && _LCIsReadWrite() && (p_LCHasCursor || p_col==1)) {
      p_LCCol=1;
      p_LCHasCursor=true;
      p_hex_nibble=false;
      p_hex_field=false;
      return;
   }
   init_command_op();
   ptab("-");
   retrieve_command_results();

}
/**
 * <p>If Indent With Tabs is on and the cursor is on or before the first non-
 * blank character, one more indent level is added to the line.</p>
 *
 * <p>If indent with tabs is on and the cursor is after the first non-blank
 * character, a tab character is inserted.</p>
 *
 * <p>If indent with tabs is off, enough spaces are inserted to move the
 * text, from the cursor to the end of the line, to the next indent level.</p>
 *
 * <p>The Indent with Tabs option ("Document", "Indent with Tabs") toggles
 * indenting with tabs for the current buffer.</p>
 *
 * @see indent_with_tabs
 * @see tabs
 * @see gui_tabs
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command void move_text_tab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if ( command_state() ) {
      maybe_list_matches("","",true);
      return;
   }
   if (!command_state() && def_modal_tab && select_active() && _within_char_selection()) {
      if (_isnull_selection()) {
         _deselect();
      } else {
         indent_selection();
         return;
      }
   }
   if ( !command_state() && p_indent_with_tabs ) {
      ctab();
      return;
   }
   if (!command_state() && _within_char_selection()) maybe_delete_selection();
   init_command_op();
   old_col := p_col;
   ptab();
   int new_len = length(_expand_tabsc(1,old_col-1,'S'):+
                substr("",1,p_col-old_col):+
                _expand_tabsc(old_col,-2,'S'));
   if (p_TruncateLength > 0 && new_len > _TruncateLengthC()) {
      message(get_message(VSRC_THIS_OPERATION_WOULD_CREATE_LINE_TOO_LONG));
      p_col = old_col;
   } else {
      replace_line(_expand_tabsc(1,old_col-1,"S"):+
                   substr("",1,p_col-old_col):+
                   _expand_tabsc(old_col,-2,"S"));
   }
   retrieve_command_results();
}
/**
 * Moves text, from cursor to end of line, to previous indent level or tab
 * stop.  To set the tab stops see <b>gui_tabs</b> or <b>tabs</b> command.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command void move_text_backtab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!command_state() && def_modal_tab && select_active() && _within_char_selection()) {
      if (_isnull_selection()) {
         _deselect();
      } else {
         unindent_selection();
         return;
      }
   }
   init_command_op();
   old_col := p_col;
   ptab("-");
   if ( _expand_tabsc(1,old_col)=="" ) {
      int syntax_indent=old_col-p_col;
      _reindent_linec(-syntax_indent);
      return;
   }
   subtext := strip(_expand_tabsc(p_col,old_col-p_col),"T");
   replace_line(_expand_tabsc(1,p_col-1,"S"):+subtext:+_expand_tabsc(old_col,-2,"S"));
   p_col += _rawLength(subtext);
   retrieve_command_results();

}
/**
 * Places cursor at column 1 of current line.  For an edit window or editor control, this
 * command attempts to reset the left edge scroll position to 0.
 *
 * @see end_line
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void begin_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   if ( command_state() ) {
      _begin_line();
      return;
   }
   if (p_hex_mode==HM_HEX_ON) {
      _hex_begin_line();
      return;
   }
   save_pos(auto p);
   _begin_line();

   if (def_softwrap_home_end && p_SoftWrap && !p_IsTempEditor) {
      softwrap_begin_line(1, p);
   }

   if ( p_left_edge && p_col<p_char_width-2 ) {
      set_scroll_pos(0,p_cursor_y);
   }

}

static bool softwrap_begin_line(int fnb_col, typeless orig_p)
{
   // if not doing cursor wrap or no softwrap, do nothing
   if (!def_softwrap_home_end || !p_SoftWrap || p_IsTempEditor) {
      return false;
   }

   // save the position that was calculated before
   save_pos(auto new_p);
   do {
      restore_pos(orig_p);
      orig_col:=p_col;
      p_col=0;
      p_cursor_x=p_width;
      first_softwrapp_line_max_col:=p_col;
      restore_pos(new_p);

      // remember the new column
      // and calculate p_cursor_x for column 1
      new_col := p_col;
      p_col=fnb_col;
      softwrap_line_cursor_x := p_cursor_x;
      // If we not on the first soft wrappd line
      if (orig_col>first_softwrapp_line_max_col) {
         p_cursor_x=0;
         softwrap_line_cursor_x = p_cursor_x;
      }

      // go to the original cursor position
      restore_pos(orig_p);

      // was it before the first non-blank position, then do nothing
      if (p_col <= fnb_col) break;

      // if they are at the beginning of the softwrap line, take
      // them to the real beginning of the line
      if (p_cursor_x <= softwrap_line_cursor_x) break;

      // move to the beginning of the softwrap line
      p_cursor_x=softwrap_line_cursor_x;
      return true;

   } while (false);

   // not the softwrap case, so just return
   restore_pos(new_p);
   return false;
}

/**
 * For a text box, the cursor is moved to column one.  For an
 * edit window or editor control, if the cursor is not in column
 * one, the cursor is placed on the first non blank character of
 * the current line.  If the cursor is in a documentation
 * comment or line comment, it is moved to the first non-blank
 * character within the comment on the current line.  If the
 * cursor is before the first non-blank character, it is moved
 * to the right of the comment delimeter.  If the cursor is on
 * the comment delimeter, it is moved to the left of the comment
 * delimeter.  Otherwise the cursor is moved to column one.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void begin_line_text_toggle() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   if ( command_state() ) {
      _begin_line();
      return;
   }
   if (p_hex_mode==HM_HEX_ON) {
      _hex_begin_line();
      return;
   }
   if (p_LCHasCursor && _LCIsReadWrite()) {
      _begin_line();
      p_LCHasCursor=false;
      return;
   }

   save_pos(auto p);
   if (!commentwrap_Home()) {
      restore_pos(p);

      /* make this a toggle from column 1 to first non blank. */
      orig_col := p_col;
      _first_non_blank();
      fnb_col := p_col;
      /* not already on first non blank? */
      if ( p_col!=orig_col) {
         //first_non_blank();
      } else {
         _begin_line();
      }

      if (def_softwrap_home_end && p_SoftWrap && !p_IsTempEditor) {
         softwrap_begin_line(fnb_col, p);
      }
   }
   if ( p_left_edge && p_col<p_char_width-2 ) {
      set_scroll_pos(0,p_cursor_y);
   }

}

/**
 * @return
 * Returns the first non-blank column for the current line.
 *
 * @param return_if_all_blanks   Value to return if the entire line is blank
 *
 * @note
 * This function <b>does not</b> move the cursor position.
 *
 * @see _first_non_blank()
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
typeless _first_non_blank_col(_str return_if_all_blanks="")
{
   typeless sv_search_string,sv_flags,sv_word_re,sv_more;
   save_search(sv_search_string,sv_flags,sv_word_re,sv_more);
   save_pos(auto p);
   _begin_line();
   search('[~ \t]|$','@rh');
   col := p_col;
   restore_pos(p);
   if (!match_length() && return_if_all_blanks!="") {
      restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
      return(return_if_all_blanks);
   }
   restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
   return(col);
}

/**
 * Moves the cursor to the first non space or tab character of the current line.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
int _first_non_blank(_str extra_search_option="")
{
   if (_on_line0()) {
      p_col=1;
      return 1;
   }
   save_search(auto sv_search_string, auto sv_flags, auto sv_word_re, auto sv_more);
   _begin_line();
   p1 := point();
   ln := point('L'); // Search for $ does not work if p_TruncateLength!=0
   search('[~ \t]|$','@rh':+extra_search_option);
   if (p_TruncateLength && (match_length()==0 || p1!=point())) {
      if (p1!=point()) {
         goto_point(p1,(int)ln);
      }
      _begin_line();
      _refresh_scroll();
   }
   restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
   return p_col;
}

/**
 * Moves the cursor to the first non space or tab character of the current line.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void first_non_blank(_str extra_search_option="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _first_non_blank(extra_search_option);
}
/**
 * Moves the cursor to the last non space or tab character of the current line.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
int _last_non_blank(_str extra_search_option="")
{
   if (_on_line0()) {
      p_col=1;
      return 1;
   }
   save_search(auto sv_search_string, auto sv_flags, auto sv_word_re, auto sv_more);
   _end_line();
   p1 := point();
   ln := point('L'); // Search for $ does not work if p_TruncateLength!=0
   search('^|[~ \t]','@-rh':+extra_search_option);
   if (p_TruncateLength && (match_length()==0 || p1!=point())) {
      if (p1!=point()) {
         goto_point(p1,(int)ln);
      }
      _end_line();
      _refresh_scroll();
   }
   restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
   return p_col;
}
/**
 * Moves the cursor to the last non space or tab character of the current line.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void last_non_blank(_str extra_search_option="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _last_non_blank(extra_search_option);
}

int _TruncSearchLine(_str searchString,_str posOptions="")
{
   _str line;
   get_line_raw(line);
   if (p_TruncateLength > 0) {
      line=substr(line,1,_TruncateLengthC());
   }
   int p = pos(searchString,line,_text_colc(p_col,'P'),p_rawpos:+posOptions);
   if (p > 0) {
      p_col = _text_colc(p,'I');
      return 0;
   }
   return STRING_NOT_FOUND_RC;
}
void _TruncEndLine()
{
   _end_line();
   if (p_TruncateLength || p_MaxLineLength) {
      search('([~ ]|^)\c','@rh-');
   }
}

static bool softwrap_end_line(int lnb_col, typeless orig_p)
{
   // if not doing cursor wrap or no softwrap, do nothing
   if (!def_softwrap_home_end || !p_SoftWrap || p_IsTempEditor) {
      return false;
   }

   // save the position that was calculated before
   new_col := p_col;
   save_pos(auto new_p);
   do {

      // go to the original cursor position
      restore_pos(orig_p);

      // was it before the first non-blank position, then do nothing
      if (p_col >= lnb_col) break;

      // remember the new column
      // and calculate p_cursor_x for column 1
      orig_col := p_col;
      p_cursor_x = p_width;

      // do not move cursor further right than we would have otherwise
      if (p_col >= new_col) break;

      // the cursor must be travelling to the right
      if (p_col <= orig_col) break;

      // success!
      return true;

   } while (false);

   // not the softwrap case, so just return
   restore_pos(new_p);
   return false;
}

static void end_line_for_each_multicursor(bool include_non_blank,
                                          bool stop_at_vertical_lines,
                                          bool ignore_trailing_blanks,
                                          bool align_multiple_cursors)
{
   // start from beginning of line
   //
   // for each line:
   //
   // 1) jump to last non-blank *or* or first vertical line column, whichever is less
   // 2) jump to last non-blnak *or* second vertical line column, whicheven is less
   // 3) repeat for all vertical line columns
   // 4) jump to largest non-blank among all lines
   // 5) jump to longest of all lines
   // 6) return to step 1
   //

   orig_left_most_column  := p_col;
   orig_right_most_column := p_col;
   right_most_non_blank_column := 0;
   right_most_column := 0;
   orig_at_non_blank_column := true;
   orig_at_right_most_column := true;

   already_looping := _MultiCursorAlreadyLooping();
   multicursor     := !already_looping && _MultiCursor();

   for (ff:=true; ; ff=false) {
      if (multicursor) {
         if (!_MultiCursorNext(ff)) {
            break;
         }
      }

      if (p_col < orig_left_most_column) {
         orig_left_most_column = p_col;
      }
      if (p_col > orig_right_most_column) {
         orig_right_most_column = p_col;
      }

      // hex mode
      if (p_hex_mode==HM_HEX_ON) {
         _hex_end_line();

      } else {

         get_line(auto line);
         //say("end_line_for_each_multicursor H"__LINE__": line="line);

         // save the original column and jump to the end of the line
         save_pos(auto orig_p);
         orig_col := p_col;

         // force deselect for multi-cursor case
         if (multicursor) {
            _deselect();
         }

         // find the actual end of the line
         _begin_line();
         _TruncEndLine();
         last_col := p_col;
         //say("     end_line_for_each_multicursor H"__LINE__": last_col="last_col);

         // find the last nonblank column (if we need it)
         nonblank_col:=last_col;
         if (ignore_trailing_blanks || include_non_blank) {
            _last_non_blank();
            if (p_col < last_col) right();
            if (p_col > last_col) p_col=last_col;
            nonblank_col=p_col;
            _TruncEndLine();
            //say("     end_line_for_each_multicursor H"__LINE__": nonblank_col="nonblank_col);
         }

         if (ignore_trailing_blanks) {
            p_col = nonblank_col;
            last_col = nonblank_col;
            //say("    end_line_for_each_multicursor H"__LINE__": USING NON BLANK COL");
         } else if (!include_non_blank) {
            nonblank_col = last_col;
            //say("    end_line_for_each_multicursor H"__LINE__": INCLUDE NON BLANK");
         }

         // check if we can use the last non-blank column
         if (nonblank_col > orig_col && nonblank_col < last_col) {
            p_col = nonblank_col;
            //say("    end_line_for_each_multicursor H"__LINE__": USING NON BLANK COL");
         }

         // if this line extends beyond the vertical line column,
         // then toggle first to the vertical line column, then to
         // the end of the line.
         if (stop_at_vertical_lines) {
            vline_col := _default_option('R');
            foreach (auto vcol in vline_col) {
               if (!isuinteger(vcol)) continue;
               if (vcol <= 0) continue;
               // line goes past vertical line column?
               if ((orig_col <= (int)vcol && p_col > (int)vcol)) {
                  p_col = (int)vcol+1;
                  //say("    end_line_for_each_multicursor H"__LINE__": USING VERTICAL COL="vcol);
               }
            }
         }

         // already was at end column then toggle back to nearest column
         if (orig_col >= last_col) {
            if (nonblank_col < p_col) {
               p_col = nonblank_col;
               //say("    end_line_for_each_multicursor H"__LINE__": BACK TO FIRST NON BLANK COL");
            }
         }

         if (def_softwrap_home_end && p_SoftWrap && !p_IsTempEditor) {
            softwrap_end_line(nonblank_col, orig_p);
            //say("    end_line_for_each_multicursor H"__LINE__": p_col="p_col);
         }

         // are we ignoring trailing whitespace?
         //say("    end_line_for_each_multicursor H"__LINE__": last_col="last_col" nonblank_col="nonblank_col);

         if (ignore_trailing_blanks) {
            last_col = nonblank_col;
            //say("    end_line_for_each_multicursor H"__LINE__": IGNORE TRAILING BLANKS");
         } else if (!include_non_blank) {
            nonblank_col = last_col;
            //say("    end_line_for_each_multicursor H"__LINE__": INCLUDE NON BLANK");
         }

         if (orig_col != nonblank_col) {
            orig_at_non_blank_column = false;
         }
         if (orig_col != last_col) {
            orig_at_right_most_column = false;
         }

         if (nonblank_col > right_most_non_blank_column) {
            right_most_non_blank_column = nonblank_col;
         }
         if (last_col > right_most_column) {
            right_most_column = last_col;
         }
      }

      if (!multicursor) {
         if (!already_looping) _MultiCursorLoopDone();
         break;
      }
   }

   if (p_hex_mode==HM_HEX_ON) {
      return;
   }

   align_to_column := 0;
   if (orig_at_non_blank_column && ignore_trailing_blanks && align_multiple_cursors) {
      align_to_column = right_most_non_blank_column;
   } else if (orig_at_right_most_column && !ignore_trailing_blanks && orig_left_most_column < right_most_non_blank_column && align_multiple_cursors) {
      align_to_column = right_most_non_blank_column;
   } else if (orig_left_most_column == orig_right_most_column &&
              orig_left_most_column == right_most_non_blank_column &&
              right_most_non_blank_column < right_most_column &&
              !ignore_trailing_blanks &&
              align_multiple_cursors) {
      align_to_column = right_most_column;
   } else if (include_non_blank && orig_left_most_column < right_most_non_blank_column && !orig_at_non_blank_column) {
      align_to_column = -1;
   }

   //say("end_line_text_toggle_for_each_multicursor H"__LINE__": smallest_column="orig_left_most_column);
   //say("end_line_text_toggle_for_each_multicursor H"__LINE__": largest_column="orig_right_most_column);
   //say("end_line_for_each_multicursor H"__LINE__": orig_at_non_blank_column="orig_at_non_blank_column);
   //say("end_line_for_each_multicursor H"__LINE__": orig_at_right_most_column="orig_at_right_most_column);
   //say("end_line_for_each_multicursor H"__LINE__": right_most_non_blank_column="right_most_non_blank_column);
   //say("end_line_for_each_multicursor H"__LINE__": right_most_column="right_most_column);
   //say("end_line_text_toggle_for_each_multicursor H"__LINE__": align_to_column="align_to_column);

   if (align_to_column != 0) {
      for (ff=true; ; ff=false) {
         if (multicursor) {
            if (!_MultiCursorNext(ff)) {
               break;
            }
         }

         if (align_to_column > 0) {

            // align all cursors on a common column
            p_col = align_to_column;

         } else if (align_to_column < 0) {

            // align all cursors on the last nonblank column
            orig_col := p_col;
            _begin_line();
            _TruncEndLine();
            last_col := p_col;
            //say("    end_line_for_each_multicursor H"__LINE__": last_col="last_col);
            _last_non_blank();
            if (p_col < last_col) right();
            if (p_col > last_col) p_col=last_col;
            nonblank_col := p_col;
            //say("end_line_for_each_multicursor H"__LINE__": nonblank_col="nonblank_col);

            // find the actual end of the line
            if (orig_col < nonblank_col) {
               p_col = orig_col;
            }
         }

         if (!multicursor) {
            if (!already_looping) _MultiCursorLoopDone();
            break;
         }
      }
   }

   if (!already_looping) {
      _MultiCursorLoopDone();
   }
}


/**
 * Places cursor after end of current line.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void end_line() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   if ( command_state() ) {
      _end_line();
      return;
   }
   // There is some code that calls end_line() indiscriminately, including
   // recorded user macros, so just in case if that code is hit while we
   // are already processing multiple cursors, use the simplest implementation
   // of end_line().
   if (_MultiCursorAlreadyLooping()) {
      save_pos(auto orig_p);
      if (p_hex_mode==HM_HEX_ON) {
         _hex_end_line();
         return;
      }
      _TruncEndLine();
      if (def_softwrap_home_end && p_SoftWrap && !p_IsTempEditor) {
         softwrap_end_line(MAXINT, orig_p);
      }
      return;
   }
   end_line_for_each_multicursor(include_non_blank:false,
                                 def_end_line_stop_at_vertical_line,
                                 ignore_trailing_blanks:false,
                                 def_end_line_align_multiple_cursors);
}

/**
 * Places cursor after end of current line, ignoring trailing whitespace.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void end_line_ignore_trailing_blanks() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   if ( command_state() ) {
      _end_line();
      return;
   }
   end_line_for_each_multicursor(include_non_blank:false,
                                 def_end_line_stop_at_vertical_line,
                                 ignore_trailing_blanks:true,
                                 def_end_line_align_multiple_cursors);
}

/**
 * For a text box, the cursor is moved to the last column.
 * For an edit window or editor control, if the cursor is not on
 * the last column the cursor is placed on the last non blank
 * character of the current line.
 * <p>
 * If {@link def_end_line_stop_at_vertical_line} is set to 'true'
 * and the user has a vertical line column configured,
 * then the cursor will also stop at the
 * vertical line column if the line extends beyond it.
 * Otherwise the cursor is moved to the last column.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void end_line_text_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   // not an editor control?
   if ( command_state() ) {
      _end_line();
      return;
   }

   end_line_for_each_multicursor(include_non_blank:true,
                                 def_end_line_stop_at_vertical_line,
                                 ignore_trailing_blanks:false,
                                 def_end_line_align_multiple_cursors);
}


/*
Make these arrays for multi-cursor cursor-up and cursor-down. This could
be done better if this fix used built-in properties
in our internal cursor structure. If users complain, we will
need to change this.
*/
static int gupdown_multicursor_index;
static int gupdown_col[];
static int gupdown_cursor_x[];
static int gupdown_left_edge[];

/**
 * For an edit window or editor control, the cursor moves one line up.
 * For the command line, the previous command
 * in the retrieve buffer ".command" is placed on the command line.
 *
 * @appliesTo  Edit_Window, Editor_Control, Command_Line
 * @categories Command_Line_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int cursor_up(_str count="",_str doScreenLines="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   /*if (!command_state()) {
      return(up());
   } */
   return(_cursor_updown(count,"",1,(doScreenLines=="")?(_str)def_updown_screen_lines:doScreenLines));
}
int _cursor_updown(_str count="",_str dodown="",_str generate_macro_source="",
                   _str doScreenLinesStr="")
{
   if (count=="") count=1;
   dodown=dodown!="";
   generate_macro_source=generate_macro_source!="";
   doScreenLines := doScreenLinesStr:!="" && doScreenLinesStr:!="0";
   int i;
   _str line;
   if (command_state()) {
      int orig_value=def_argument_completion_options;
      def_argument_completion_options = 0;
      for (i=1;i<=count;++i) {
         retrieve_skip((dodown)?"N":"");
         get_command(line);
         command_put(line);
      }
      def_argument_completion_options = orig_value;
      return(0);
   }
   _str key=last_event();
   //read_behind_flush_repeats(key,def_flush_repeats)
   _str prev_cmd=name_name(prev_index('','C'));
   if (prev_cmd == 'cua-select') {
      prev_cmd = get_last_cua_key();
   }
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      gupdown_multicursor_index=0;
   } else if (_MultiCursorAlreadyLooping()) {
      ++gupdown_multicursor_index;
   }
   //say("gupdown_cursor_x="gupdown_cursor_x);
   if (prev_cmd!="cursor-up" && prev_cmd!="cursor-down") {
      gupdown_col[gupdown_multicursor_index]=p_col;
      gupdown_cursor_x[gupdown_multicursor_index]=p_cursor_x;
      gupdown_left_edge[gupdown_multicursor_index]=p_left_edge;
      //say("change x="gupdown_cursor_x);
   }
   if (generate_macro_source) {
      _macro_repeat();
   }
   doHexUpDown := ((!select_active() && p_hex_mode==HM_HEX_LINE) || p_hex_mode==HM_HEX_ON);
   typeless downp;
   save_pos(downp);
   _str orig_point=(doHexUpDown)?point('s'):point();
   int status;
   for (i=1;i<=count;++i) {
      if (doHexUpDown) {
         if ( dodown) {
            status=_hex_down(doScreenLines);
         } else {
            status=_hex_up(doScreenLines);
         }
      } else {
         if ( dodown) {
            status=down(1,doScreenLines);
         } else {
            status=up(1,doScreenLines);
         }
         if (status) {
            if (dodown && (_lineflags()&HIDDEN_LF)) {
               restore_pos(downp);
            }
            break;
         }

         if (_lineflags()&HIDDEN_LF) {
            --i;
         } else if (dodown) {
            save_pos(downp);
         }
      }
   }
   if (!doHexUpDown && (orig_point!=point() || p_SoftWrap)) {
      if (def_updown_col || !p_fixed_font) {
         stay_on_text(gupdown_col[gupdown_multicursor_index],gupdown_cursor_x[gupdown_multicursor_index],gupdown_left_edge[gupdown_multicursor_index]);
      }
      if ((p_col>1)&&def_emulate_leading_tabs) {
         int pcol=_text_colc(p_col,'P');
         _str text='';
         typeless force_wrap_line_len=_default_option(VSOPTION_FORCE_WRAP_LINE_LEN);
         if (pcol<force_wrap_line_len) {
            text=_expand_tabsc(1,p_col);
         }
         if (pcol<force_wrap_line_len && (pcol<_line_length())&&("":==strip(_expand_tabsc(1,pcol)))) {
            ptab("-");
            ptab();
         }
      }
   }
   if (doHexUpDown && orig_point!=point('s')) {
      if (def_updown_col || !p_fixed_font || p_UTF8) {
         stay_on_text(gupdown_col[gupdown_multicursor_index],gupdown_cursor_x[gupdown_multicursor_index],gupdown_left_edge[gupdown_multicursor_index]);
      }
   }
   if (!dodown && _on_line0() && !_default_option('T')) {
      p_line=1;
      blockSelectionActive := (select_active() && _select_type():=="BLOCK");
      if (!blockSelectionActive) {
         p_col=1;
      }
   }

   //read_behind_flush_repeats(key,def_flush_repeats);
   return(status);
}
static void stay_on_text(int updown_col,int updown_cursor_x,int left_edge)
{
   blockSelectionActive := (select_active() && _select_type():=="BLOCK");
   if ( updown_col) {
      if (!p_fixed_font || (p_hex_mode==HM_HEX_ON/* && p_UTF8*/)|| (p_SoftWrap && p_hex_mode!=HM_HEX_ON)) {
         //say("h2 x="updown_cursor_x);
         set_scroll_pos(left_edge,p_cursor_y);
         p_cursor_x=updown_cursor_x;
         //say("col="p_col);
         if (def_updown_col && !blockSelectionActive && p_hex_mode!=HM_HEX_ON/* && !p_SoftWrap*/) {
            if ( _text_colc(0,'E')<p_col ) {
               p_col=_text_colc(0,'E')+1;
            } else if ( _text_colc(p_col,'T')<0 ) {
               p_col=_text_colc(1-_text_colc(p_col,'T'),'i');
            }
         }
      } else if(!blockSelectionActive){
         if ( _text_colc(0,'E')<updown_col ) {
            p_col=_text_colc(0,'E')+1;
         } else if ( _text_colc(updown_col,'T')<0 ) {
            p_col=_text_colc(1-_text_colc(updown_col,'T'),'i');
         } else {
            p_col=updown_col;
         }
      }
   }
}
/**
 * For an edit window or editor control, the cursor is moved one line down.
 * For the command line, the next command in
 * the retrieve buffer ".command" is placed on the command line.
 *
 * @appliesTo  Edit_Window, Editor_Control, Command_Line
 * @categories Command_Line_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int cursor_down(_str count="",_str doScreenLines="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   /*if (!command_state()) {
      return(down());
   } */
   return(_cursor_updown(count,"n",1,(doScreenLines=="")?(_str)def_updown_screen_lines:doScreenLines));
}
/**
 * Places cursor at first line and first column of buffer.  If the "Preserve
 * Column on Top/Bottom" option is on, the cursor is placed at
 * the top of the buffer and the column positon is unchanged.
 *
 * @see bottom_of_buffer
 * @see def_top_bottom_push_bookmark
 * @see def_top_bottom_style
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void top_of_buffer() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_hex_mode==HM_HEX_ON) {
      set_scroll_pos(0,p_cursor_y);
      top();
      return;
   }
   /*if (_MultiCursor()) {
      _MultiCursorClearAll();
      return;
   } */
   int old_col;
   int old_left_edge;
   _str old_point;
   if ( def_top_bottom_style ) {
      old_col=p_col;
      old_left_edge=p_left_edge;
      old_point=point();
      set_scroll_pos(old_left_edge,p_cursor_y);
   }
   if (!(p_buf_flags&(VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN)) && def_top_bottom_push_bookmark && p_LangId!="process" && (_MultiCursorActiveLoopIteration() || !_MultiCursor())) {
      push_bookmark();
   }
   top();
   if ( def_top_bottom_style && old_point!=point() ) {
      p_col=old_col;
   }
   block_was_read(1);
   read_ahead();
}
/**
 *
 * Places text cursor at end of last line of buffer.  If the
 * "Preserve Column on Top/Bottom..." option is on, the cursor
 * is placed on the last line of the buffer and the column
 * position is unchanged.  Executing this command when the
 * cursor is already on the last line of the buffer will move
 * the cursor to the end of the last line.
 *
 * @see top_of_buffer
 * @see def_top_bottom_push_bookmark
 * @see def_top_bottom_style
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void bottom_of_buffer() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_hex_mode==HM_HEX_ON) {
      hex_bottom();
      return;
   }
   /*if (_MultiCursor()) {
      _MultiCursorClearAll();
      return;
   } */
   int old_col;
   int old_left_edge;
   _str old_point;
   if ( def_top_bottom_style ) {
      old_col=p_col;
      old_left_edge=p_left_edge;
      old_point=point();
   }
   if (!(p_buf_flags&(VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN)) && def_top_bottom_push_bookmark && p_LangId!="process" && (_MultiCursorActiveLoopIteration() || !_MultiCursor())) {
      push_bookmark();
   }
   bottom(true);_TruncEndLine();
   if ( def_top_bottom_style && old_point!=point() ) {
      p_col=old_col;
      set_scroll_pos(old_left_edge,p_cursor_y);
   }
   block_was_read(1);
   read_behind();

}
/**
 * Moves cursor to previous page of text.
 *
 * @see page_down
 * @see page_left
 * @see page_right
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void page_up() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   page_up_down();

}
/**
 * Moves cursor to next page of text.
 *
 * @see page_up
 * @see page_left
 * @see page_right
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void page_down() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   page_up_down("d");

}
static void page_up_down(...)
{
   if (p_hex_mode==HM_HEX_ON) {
      if ( arg(1)!="" ) {
         _hex_pagedown();
      } else {
         _hex_pageup();
      }
      return;
   }
   _str key=last_event();
   read_behind(/*key*/);
   _str prev_cmd=name_name(prev_index());
   if (prev_cmd == "cua-select") {
      prev_cmd = get_last_cua_key();
   }
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      gupdown_multicursor_index=0;
   } else if (_MultiCursorAlreadyLooping()) {
      ++gupdown_multicursor_index;
   }
   if (prev_cmd!="page-up" && prev_cmd!="page-down" ) {
      gupdown_col[gupdown_multicursor_index]=p_col;
      gupdown_cursor_x[gupdown_multicursor_index]=p_cursor_x;
      gupdown_left_edge[gupdown_multicursor_index]=p_left_edge;
   }
   if (def_keys=="ispf-keys" && _cmdline.p_text!="" && lowcase(_cmdline.p_text)==substr("maximum",1,length(_cmdline.p_text))) {
      if ( arg(1)!="" ) {
         bottom_of_buffer();
      } else {
         top_of_buffer();
      }
      _cmdline.set_command("",1);
   } else if (lowcase(def_page)=="c") {
      if ( arg(1)!="" ) {
         if (p_cursor_y==0) {
            _page_down();
         } else {
            line_to_top();
         }
      } else {
         //say("p_char_height="p_char_height);
         //say("y="p_cursor_y);
         //say("div="p_cursor_y intdiv p_font_height);
         if (p_char_height<=(p_cursor_y intdiv p_font_height)+1) {
            _page_up();
         } else {
            line_to_bottom();
         }
      }
   } else {
      if ( arg(1)!="" ) {
         _page_down();
      } else {
         _page_up();
      }
   }
   if (def_updown_col || !p_fixed_font || p_SoftWrap) {
      stay_on_text(gupdown_col[gupdown_multicursor_index],gupdown_cursor_x[gupdown_multicursor_index],gupdown_left_edge[gupdown_multicursor_index]);
      if ((p_col>1)&&def_emulate_leading_tabs) {
         int pcol=_text_colc(p_col,'P');
         _str text='';
         typeless force_wrap_line_len=_default_option(VSOPTION_FORCE_WRAP_LINE_LEN);
         if (pcol<force_wrap_line_len) {
            text=_expand_tabsc(1,p_col);
         }
         if (pcol<force_wrap_line_len && (pcol<_line_length())&&("":==strip(_expand_tabsc(1,pcol)))) {
            ptab("-");
            ptab();
         }
      }
   } else {
      p_col=gupdown_col[gupdown_multicursor_index];
   }
   read_behind();
}

void _goto_right_edge_col()
{
   orig_left_edge := p_left_edge;
   p_cursor_x=p_client_width-1;
   //say(p_left_edge" "orig_left_edge);
   if (p_left_edge!=orig_left_edge) {
      --p_col;
      set_scroll_pos(orig_left_edge,p_cursor_y);
      if (p_left_edge!=orig_left_edge) {
         --p_col;
         set_scroll_pos(orig_left_edge,p_cursor_y);
      }
   }
}
void _LCLeft()
{
   if (p_LCCol<=1) {
      if (def_cursorwrap) {
         if(up()) {
            return;
         }
         _goto_right_edge_col();
         p_LCHasCursor=false;
      }
      return;
   }
   --p_LCCol;
}
void _LCRight()
{
   if (p_LCCol>=p_line_numbers_len) {
      _begin_line();
      p_LCHasCursor=false;
      return;
   }
   ++p_LCCol;
}
void _LCEnd()
{
   _end_line();
   p_LCHasCursor=false;
}
bool _doCmdLineCursorBeginEndSelect(_str key)
{
   int start_pos,end_pos;
   _cmdline._get_sel(start_pos,end_pos);
   if (start_pos==end_pos) {
      return(false);
   }
   if (start_pos>=end_pos) {
      int temp=start_pos;
      start_pos=end_pos;
      end_pos=temp;
   }
   _str line;
   int col;
   if (def_cursor_beginend_select) {
      get_command(line,col);
      switch (key) {
      case LEFT:
         set_command(line,start_pos);
         return(true);
      case RIGHT:
         set_command(line,end_pos);
         return(true);
      }
   }
   return(false);
}
/**
 * Moves the cursor one character to the left.  For a edit window or text box
 * control, if word wrap is on, the cursor will wrap to the end of the previous
 * line when the left margin is hit.
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void cursor_left(...) name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   int i,count=1;
   if (arg(1)!="") {
      count=arg(1);
   }
   int col;
   _str line;
   if (command_state()) {
      if (_doCmdLineCursorBeginEndSelect(last_event())) {
         return;
      }
      for (i=1;i<=count;++i) {
         left();
      }
      return;
   }
   _macro_repeat();
   for (i=1;i<=count;++i) {
      if (p_hex_mode==HM_HEX_ON) {
         _hex_left();
      } else {
         if (p_LCHasCursor && _LCIsReadWrite()) {
            _LCLeft();
         } else if (p_col==1 && _LCIsReadWrite()) {
            p_LCCol=p_line_numbers_len;
            p_LCHasCursor=true;
            p_hex_nibble=false;
            p_hex_field=false;
         } else {
            wordwrap_left(def_cursorwrap);
         }
      }
   }
}

/**
 * Wraps the cursor to the end of the previous line after a
 * cursor movement to left which hits the left margin.
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
void wordwrap_left(...)
{
   typeless leftmargin, rightmargin;
   parse p_margins with leftmargin rightmargin .;
   col := p_col;
   typeless force_wrap_line_len=_default_option(VSOPTION_FORCE_WRAP_LINE_LEN);
   if (def_emulate_leading_tabs) {
      int pcol=_text_colc(p_col-1,'P');
      _str text='';
      if (pcol<force_wrap_line_len) {
         text=_expand_tabsc(1,p_col);
      }
      if (pcol<force_wrap_line_len && "":==strip(text)) {
         ptab("-");
      } else if ( def_jmp_on_tab) {
         left();
      } else {
         p_col--;
         _begin_char(); // Make sure we are on at the beginning of the DBCS or UTF-8 chacter
      }
   } else if ( def_jmp_on_tab) {
         left();
   } else {
      p_col--;
      _begin_char(); // Make sure we are on at the beginning of the DBCS or UTF-8 chacter
   }

   if ( (p_word_wrap_style&WORD_WRAP_WWS) ||
        arg(1):=="1" ) {
      if ( def_linewrap || !(p_word_wrap_style&WORD_WRAP_WWS)) {
         leftmargin=1;
      }
      if ( col<=leftmargin) {
         if (p_col<force_wrap_line_len) {
            int pcol=_text_colc(col-1,'P');
            _str text=_expand_tabsc(1,pcol);
            if (strip(text,'B'):=="" ) {
               up(1,true);
               if ( ! rc ) {
                  _end_line();
               }
            }
         }
      }
   }

}
/**
 * Moves the cursor one character to the right.  For an edit window or
 * editor control, if word wrap is on, the cursor will wrap to the next
 * line when the right margin is hit.
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void cursor_right(...) name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   int i,count=1;
   if (arg(1)!="") {
      count=arg(1);
   }
   if (command_state()) {
      if (_doCmdLineCursorBeginEndSelect(last_event())) {
         return;
      }
      for (i=1;i<=count;++i) {
         right();
      }
      return;
   }
   _macro_repeat();
   for (i=1;i<=count;++i) {
      if (p_hex_mode==HM_HEX_ON) {
         _hex_right();
      } else {
         if (p_LCHasCursor && _LCIsReadWrite()) {
            _LCRight();
         } else {
            wordwrap_right(def_cursorwrap);
         }
      }
   }
}

/**
 * Wraps the cursor to the beginning of the next line after
 * a cursor movement to right which hits the right margin.
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
void wordwrap_right(...)
{
   typeless leftmargin, rightmargin;
   parse p_margins with leftmargin rightmargin .;
   if ( (p_word_wrap_style&WORD_WRAP_WWS) ||
        arg(1):=="1" ) {
      if ( ( (p_col>rightmargin && !p_FixedWidthRightMargin) || arg(1):=="1") &&
           p_col>_text_colc() &&
           (def_keys!="ispf-keys" || p_col>p_TruncateLength) &&
           (! select_active() || _select_type():!="BLOCK") ) {
         down();
         if ( ! rc ) {
            if ( def_linewrap || !(p_word_wrap_style&WORD_WRAP_WWS)) {
               p_col=1;
            } else {
               p_col=leftmargin;
            }
         }
         return;
      }
   }

   if (def_emulate_leading_tabs) {

      int pcol=_text_colc(p_col,'P');
      _str text='';
      typeless force_wrap_line_len=_default_option(VSOPTION_FORCE_WRAP_LINE_LEN);
      if (pcol<force_wrap_line_len) {
         text=_expand_tabsc(1,p_col);
      }
      if (pcol<force_wrap_line_len && "":==strip(text)) {
         ptab();
         try_col := p_col;
         _first_non_blank();
         if (p_col>try_col) {
            p_col=try_col;
         }
      } else if ( def_jmp_on_tab ) {
         right();
      } else if(get_text()=="\t") {
         p_col++;
      } else {
         right();
      }
   } else if ( def_jmp_on_tab ) {
      right();
   } else if(get_text()=="\t") {
      p_col++;
   } else {
      right();
   }
}

/**
 * Move the cursor right one character.  If the cursor is at
 * the end of the line, move down to the beginning of the next line.
 *
 * @return 0 on success, <0 if at then end of the file.
 *
 * @see right
 * @see down
 * @see prev_char
 * @see traverse_char
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int next_char() name_info(","VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   // check if we are at or beyond the end of the line
   orig_col := p_col;
   _end_line();
   end_col := p_col;
   p_col = orig_col;
   if ( orig_col >= end_col ) {
      // yes, so go to beginning of next line
      status := down();
      if ( status ) return status;
      _begin_line();
   } else {
      // otherwise just move one char right
      right();
   }
   return 0;
}
/**
 * Move the cursor left one character.  If the cursor is at the
 * beginning of the line, move down to the end of the previous line.
 *
 * @return 0 on success, <0 if at then beginning of the file.
 *
 * @see left
 * @see up
 * @see next_char
 * @see traverse_char
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int prev_char() name_info(","VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   if ( p_col > 1 ) {
      left();
   } else {
      status := up();
      if ( status ) return status;
      _end_line();
   }
   return 0;
}

/**
 * Move the cursor to the next or previous character, wrapping to
 * the next or previous line as necessary.
 *
 * @return 0 on success, <0 if at then beginning of the file.
 *
 * @see next_char
 * @see prev_char
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
int traverse_char(_str direction)
{
   if ( direction=="-" ) {
      return prev_char();
   } else {
      return next_char();
   }
}

/**
 * Call extension specific function to handle deleting the
 * current character under the cursor.
 *
 * @returns 'true' if the delete char was handled by the
 * extension specific callback, 'false' otherwise.
 *
 * @param force_wrap   force line wrap if at end of line?
 */
bool ext_delete_char(_str force_wrap="")
{
   index := _FindLanguageCallbackIndex("_%s_delete_char");
   if (index <= 0) return false;

   save_pos(auto p);
   save_search(auto search_string, auto flags, auto word_re, auto reserved, auto flags2);
   status := call_index(force_wrap, index);
   if (status==0) {
      return true;
   }

   restore_pos(p);
   restore_search(search_string, flags, word_re, reserved, flags2);
   return false;
}

/**
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command void delete_char(_str force_wrap="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   if (ext_delete_char(force_wrap)) {
      return;
   }
   if ( command_state() || (_lineflags()&NOSAVE_LF)) {
      _delete_char();
   } else {
      wordwrap_delete_char(force_wrap);
   }

}
/**
 * Deletes character at the cursor.  If the cursor is in an edit window or
 * editor control, and the rest of the line is null, the next line is joined to
 * the current line.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command void linewrap_delete_char() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   _macro('m',_macro());
   delete_char(1);
}
/**
 * Either calls _delete_char or deletes one tab character worth of space depending
 * on the cursor location and the value of def_emulate_leading_tabs
 */
void maybe_delete_tab(int wrapFlags=0)
{
   if (def_emulate_leading_tabs) {
      get_line(auto line);
      int pcol=text_col(line,p_col,'P');
      if ((pcol<length(line))&&("":==strip(substr(line,1,pcol)))) {
         // may have spaces, may have tabs, let cursor_right figure that out
         int sel_id=_alloc_selection();
         start_col := p_col;
         _select_char(sel_id);
         cursor_right();
         _select_char(sel_id);
         _delete_selection(sel_id);
         _free_selection(sel_id);
         p_col=start_col;
         return;
      }
   }
   _delete_char(wrapFlags);
}
/**
 * Deletes the character under the cursor.  If the cursor is past the end of
 * the current line and word wrap is on or <i>force_wrap </i>!= '', the
 * next line is joined with the current line.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void wordwrap_delete_char(...)
{
   // Special case:
   // If the text caret is at column 1, and the line is empty (not including
   // newline chars), then the current line is deleted so that the next line
   // is "pulled" up. If there is a breakpoint (or PIC) on the next line,
   // then it is preserved.

   //Try handle with comment wrap.  Returns true if handled
   if (commentwrap_Delete()) return;
   if (p_TruncateLength && p_col>p_TruncateLength) {
      message(get_message(VSRC_CURSOR_POSITION_PAST_TRUNCATION_LENGTH));
      return;
   }
   if ( (p_word_wrap_style&WORD_WRAP_WWS)  ||
        arg(1)!="" ) {
      if ( _on_line0() ) {
         return;
      }
      int LineLen=_text_colc(0,'E');
      if ( p_col>LineLen) {
         save_pos(auto p);
         if (down()) {
            message(get_message(BOTTOM_OF_FILE_RC));
         } else {
            restore_pos(p);
            if( p_col==1 && LineLen==0 ) {
               // Empty line, so do not join the line but rather
               // delete the current line, which will "pull" the line
               // below up. We do this to preserve breakpoints and
               // PIC data on the next line.
               _delete_line();
            } else {
               join_line(def_join_strips_spaces);
            }
         }
      } else {
         if ((p_word_wrap_style&WORD_WRAP_WWS) && !(p_word_wrap_style&PARTIAL_WWS)) {
            maybe_delete_tab(VSWRAPFLAG_WORDWRAP);
         } else {
            maybe_delete_tab();
         }
      }
   } else {
      maybe_delete_tab();
   }
}

/**
 * Call extension specific function to handle deleting the
 * current character under the cursor.
 *
 * @returns 'true' if the delete char was handled by the
 * extension specific callback, 'false' otherwise.
 *
 * @param force_wrap   force line wrap if at end of line?
 */
bool ext_rubout_char(_str force_wrap="")
{
   if (command_state()) {
      return false;
   }

   embedded_status := _EmbeddedStart(auto orig_values);
   index := _FindLanguageCallbackIndex("_%s_rubout_char");
   if (index <= 0) {
      if (embedded_status == 1) {
         _EmbeddedEnd(orig_values);
      }
      return false;
   }

   save_pos(auto p);
   save_search(auto search_string, auto flags, auto word_re, auto reserved, auto flags2);
   status := call_index(force_wrap, index);
   if (embedded_status == 1) {
      _EmbeddedEnd(orig_values);
   }

   if (status==0) {
      return true;
   }

   restore_pos(p);
   restore_search(search_string, flags, word_re, reserved, flags2);
   return false;
}

/**
 * Deletes the character to left of cursor.  If the visible cursor is in the
 * text area and word wrap is on or <i>force_wrap </i>!= '', the cursor
 * will wrap to the previous line when the left margin is hit.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void rubout(_str force_wrap="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   if (ext_rubout_char(force_wrap)) {
      return;
   }
   if ( command_state() || (_lineflags()&NOSAVE_LF)) {
      _rubout();
   } else {
      wordwrap_rubout(force_wrap);
   }
}
/**
 * Deletes character to left of cursor.  For an edit window or editor
 * control, the cursor will wrap to the end of the previous line when the left
 * margin is hit.  If you want line wrapping to occur when column one is
 * reached, turn on the Line Wrap on Text option.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command void linewrap_rubout() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   _macro('m',_macro());
   rubout(1);
}
static void _wordwrap_rubout() {
   /*if (def_linewrap) {
      _rubout(VSWRAPFLAG_LINEWRAP|VSWRAPFLAG_WORDWRAP);
   } else {*/
      _rubout(VSWRAPFLAG_WORDWRAP);
   //}
}
/**
 * Deletes character to left of cursor.  For an edit window or editor
 * control, the cursor will wrap to the end of the previous line when the left
 * margin is hit.  If you want line wrapping to occur when column one is
 * reached, turn on the Line Wrap on Text option.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void wordwrap_rubout(...)
{
   if (commentwrap_Backspace()) {
      return;
   }
   check_wordwrap := (p_word_wrap_style&WORD_WRAP_WWS)!=0 && _insert_state() && !_on_line0();
   non_blank_col := 0;
   int leftmargin,rightmargin;
   if (check_wordwrap) {
      // Check if entire line is blank, don't do wordwrap
      save_pos(auto p);
      _first_non_blank();
      non_blank_col=p_col;
      if (_expand_tabsc(p_col,1)=="") {
         // No word wrap on blank lines
         check_wordwrap=false;
      }
      restore_pos(p);
      if(_getAutoMargins(leftmargin,rightmargin)) {
         check_wordwrap=false;
      }
      if (p_col<=non_blank_col && _prevLineInDifferentParagraph(non_blank_col)) {
         check_wordwrap=false;
      }
   }
   if (!check_wordwrap) {
      parse p_margins with auto sleftmargin .;
      leftmargin=(int)sleftmargin;
   }
   if (p_word_wrap_style & PARTIAL_WWS) {
      check_wordwrap=false;
   }

   col := p_col;
   line_len := 0;
   count := 0;
   _str temp;
   int temp_len;
   if ( def_pull || _insert_state() ) {
      if ( def_hack_tabs && p_col!=1 ) {
         // Don't do hacktabs backspace when before left margin
         if (check_wordwrap && p_col<=leftmargin && p_col<=non_blank_col) {
            _wordwrap_rubout();
            return;
         }
         left();
         if (get_text()=="\t") {
            p_col=col;p_col=p_col-1;_delete_char();
         } else {
            if (check_wordwrap) {
               right();
               _wordwrap_rubout();
               return;
            }
            _delete_char();
         }
         //_delete_text();
      } else {
         if (/*def_keys=="brief-keys" && */p_SyntaxIndent && p_indent_style==INDENT_SMART &&
                                           p_indent_with_tabs && p_show_tabs!=1 && p_buf_width==0) {
            /*
               When past end of line, unindent by the SyntaxIndent if possible
            */
            line_len=_text_colc(0,'E');
            if (p_col>line_len+1) {
               count=p_SyntaxIndent;
               if (count>0) {
                  count=((p_col-1)%count);
                  if (!count) count=p_SyntaxIndent;
               }
               if (count<=0) {
                  count=1;
               }
               if (p_col-1<count) {
                  count=p_col-1;
               }
               if (p_col-count>line_len) {
                  p_col-=count;
               } else {
                  temp=_expand_tabsc(p_col-count,count,'S');
                  temp_len=p_col-count-1+length(strip(temp,'T'));
                  p_col=temp_len+1;
                  _delete_end_line();
#if 0
                  temp=_expand_tabsc(p_col-count,count,'S');
                  temp_len=p_col-count-1+length(strip(temp,'T'));
                  replace_line expand_tabs(line,1,temp_len,'S');
                  _end_line();
#endif
               }
            } else {
               if (check_wordwrap) {
                  _wordwrap_rubout();
                  return;
               }
               _rubout();
            }
        } else {
            if (check_wordwrap) {
               _wordwrap_rubout();
               return;
            }
            backspace_unindent := false;
            handled_rubout := false;
            if (p_col>1) {
               get_line(auto line);
               int pcol=text_col(line,p_col-1,'P');
               if ((pcol<length(line))&&("":==strip(substr(line,1,pcol)))) {

                  if (def_emulate_leading_tabs) {

                     // may have spaces, may have tabs, let cursor_left figure that out
                     int sel_id=_alloc_selection();
                     _select_char(sel_id);
                     cursor_left();
                     _select_char(sel_id);
                     _delete_selection(sel_id);
                     _free_selection(sel_id);
                     handled_rubout=true;

                  } else if (/*!commentwrap_Backspace() && */LanguageSettings.getBackspaceUnindents(p_LangId)) {

                     backspace_unindent = true;
                  }
               } else if (line == "" /*&& !commentwrap_Backspace()*/ && LanguageSettings.getBackspaceUnindents(p_LangId)) {
                  backspace_unindent = true;
               }
            }
            // Check for p_SyntaxIndent == 0...if we can't use that, check for tab settings
            if (backspace_unindent && (p_SyntaxIndent || (p_indent_with_tabs && p_tabs != "") ||
                                       (p_SyntaxIndent == 0 && p_tabs != ""))) {

               // determine the number of whitespace chars to delete
               targetCol := p_col;

               if (p_SyntaxIndent <= 0) {
                  if (p_col > 1) {
                     curcol := p_col;
                     backtab();
                     targetCol = p_col;
                     p_col = curcol;
                  }
               } else {
                  nc := max(1, p_col - p_SyntaxIndent);
                  nm := (nc - 1) % p_SyntaxIndent;
                  if (nm == 0) {
                     targetCol = nc;
                  } else {
                     targetCol = p_col - nm;
                  }
               }

               // Don't un-indent if we don't have valid p_SyntaxIndent or valid p_tabs
               while (p_col > targetCol) {
                  _rubout();
                  handled_rubout = true;
               }
               // insert whitespace(s) in case we've deleted more than desired due to
               // mix up of whitespace and tab characters.
               while (p_col < targetCol) {
                  _insert_text(" ");
               }
            }

            if (!handled_rubout) {
               _rubout();
            }
         }
      }
   } else {
      // Brief and Emacs use this code path def_pull==0 && !insert_state()
      if ( col!=1 ) {
         // Changed this to support DBCS
         left();
         if (get_text()=="") {
            p_col=col;
            p_col--;
         } else if (p_col<=col-2) {
            // This actually isn't possible to implement for Unicode so
            // here we just try 2 spaces for Unicode or DBCS
            _insert_text(" ");keyin(" ");
            left();left();
         } else {
            keyin(" ");
            left();
         }
      }
   }
   int status;

   if ( arg(1)!="" ) {
      if ( _on_line0() ) {
         return;
      }
      if ( def_linewrap || !(p_word_wrap_style&WORD_WRAP_WWS)) {
         leftmargin=1;
      }
      //get_line(line);
      if ( (col<=leftmargin || col:==1) &&  p_col<=_first_non_blank_col()
           /*strip(substr(line,1,text_col(line,p_col-1,'P')),'B',' ')==''*/ ) {
         up();
         if ( ! _on_line0()  ) {  /* hit top of file? */
            /* did not hit top of file. */
            if ( def_pull || _insert_state() ) {
               down();
               // Might split tab character. Deleting previous character
               // will not cause a problem.
               _rubout();
               col=p_col;
               int physical_col=_text_colc(p_col,'P');
               _begin_line();
               _delete_text(physical_col-1);
               up();
               _TruncEndLine();

               int LineLen = _text_colc(0,'E');
               if( LineLen==0 ) {
                  // Empty line, so do not join the line, but rather
                  // delete the current line, which will "pull" the line
                  // below up. We do this to preserve breakpoints and
                  // PIC data on the current line.
                  _delete_line();
               } else {
                  status=_join_line();
                  if (status) {
                     down();
                     p_col=col;
                  }
               }

            } else {
               _end_line();
            }
         } else {
            down();
         }
      }
   }

//    if (doCommentFormat) {
//       CW_rubout();
//    }

}
/**
 * Places cursor at top of window.
 *
 * @see bottom_of_window
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void top_of_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   p_cursor_y=0;
}
/**
 * Places cursor at bottom of window.
 *
 * @see top_of_window
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void bottom_of_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   p_cursor_y=(p_client_height-1);

}
/**
 * Places cursor at top left of window.
 *
 * @see bottom_of_window
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void top_left_of_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   p_cursor_y=0;
   p_cursor_x=0;
}
/**
 * Places cursor at bottom left of window.
 *
 * @see top_of_window
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void bottom_left_of_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   p_cursor_y=(p_client_height-1);
   p_cursor_x=0;
}
/**
 * Splits the current line at the cursor position.  Enough spaces are
 * appended to the beginning of the new line to align it with the first non
 * blank character of the current line.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void split_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL)
{
   int first_non_blank;

   orig_col := p_col;
   ifirst_non_blank := _first_non_blank_col(0);

   flags := _lineflags();
   RestoreLineModifyFlags := false;
   if (p_col>_text_colc()) {

      if (p_buf_width) {
         // Record files have no NLChars.  _split_line
         // won't insert any either.
         RestoreLineModifyFlags=true;
      } else {
         p_col=_text_colc()+1;
         _str NLChars=get_text(_line_length(true)-_line_length());
         if (NLChars:==p_newline) {
            RestoreLineModifyFlags=true;
         }
      }
   }
   _split_line();
   if (RestoreLineModifyFlags) {
      _lineflags(flags,MODIFY_LF|INSERTED_LINE_LF);
   }
   down();
   _begin_line();
   search('[ \t]@','rh@');
   if (match_length()) {
      _delete_text(match_length());
   }
   if (ifirst_non_blank) {
      _insert_text(indent_string(ifirst_non_blank-1));
   }
   up();
   p_col=orig_col;
}

/**
 * Split the current line at the specified column boundaries.
 * @param column   column number to split the line at
 */
_command void split_line_at_column(typeless column="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   // prompt for a column number
   static int last_split_column;
   if (!last_split_column) last_split_column=80;
   column=prompt(column,"Split at column:",last_split_column);
   if (column=="") return;
   if (!isnumber(column)) {
      message(get_message(INVALID_ARGUMENT_RC));
      return;
   }
   last_split_column=column;

   // now split up the line
   for (;;) {
      _end_line();
      if (p_col <= column) break;
      _begin_line();
      p_col = column;
      _split_line();
      if (down()) break;
   }
}

/**
 * Split the current line at the specified delimeter.
 * The delimeter will NOT be deleted.
 * @param delim    delimeter string to split line at
 */
_command void split_line_at_delimeter(_str delim="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   // prompt for a column number
   static _str last_delimeter;
   delim=prompt(delim,"Split at delimeter:",last_delimeter);
   if (delim=="") return;
   last_delimeter=delim;

   // now split up the line
   for (;;) {
      save_pos(auto p);
      orig_line := p_line;
      _begin_line();
      cursor_right(length(delim));
      status := search(delim,'@he');
      if (status < 0) break;
      if (p_line != orig_line) {
         restore_pos(p);
         break;
      }
      _split_line();
      if (down()) break;
   }
}

void strip_trailing_spaces()
{
   save_pos(auto p);
   // Must start from beginning of line to ensure that we find
   // something on this line.
   _begin_line();
   status := search('[ \t]@$','rh@');
   if (!status && match_length()) {
      //search_replace("");
      _delete_text(match_length());
   }
   restore_pos(p);
}
void strip_leading_spaces(_str &deletedText="")
{
   save_pos(auto p);
   _begin_line();
   status := search('^[ \t]@','rh@');
   deletedText="";
   if (!status && match_length()) {
      deletedText=get_match_text();
      strip_count := match_length();
      //search_replace('');
      _delete_text(match_length());
   }
   restore_pos(p);
}
/**
 * Joins the next line to the current line at the cursor
 * position.  Works on selections.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void join_lines() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (select_active()) {
      int i;
      _str num_lines = count_lines_in_selection();
      if (!isinteger(num_lines)) {
         // ?
         message("Bad selection.");
         return;
      }
      int nl = (int)num_lines;
      begin_select();
      typeless p;
      _save_pos2(p);
      for (i = 0; i < nl - 1; i++) {
         end_line();
         _insert_text(" ");
         join_line();
      }
      _restore_pos2(p);
   } else {
      join_line();
   }
}
/**
 * Joins the next line to the current line at the cursor position.  Leading
 * blanks on the next line are removed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command int join_line(_str stripLeadingSpaces="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL)
{
   /* join next line to current line at cursor position. */
   /* if cursor position is less than length of line then */
   /* join next line to end of current line. */
   /* leading spaces and tabs of next line are stripped before join. */

   // are we about to try joining line comments or javadoc comments?
   joinComments := _GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_JOIN_COMMENTS) != 0;
   joiningLineComment := joinComments;
   joiningJavaComment := joinComments;

   // is the current a line comment or Java doc comment?
   delims := "";
   typeless p;
   if (joinComments) {
      save_pos(p);
      _end_line();
      joiningLineComment = joiningLineComment && (_inExtendableLineComment(delims) > 0);
      joiningJavaComment = joiningJavaComment && (_inJavadoc() > 0);
      restore_pos(p);
   }

   // Trailing spaces of current line are stripped.
   strip_trailing_spaces();

   // now check out the next line
   int status=down();
   if ( status ) {
      message(get_message(rc));
      return(rc);
   }

   // is the next line a line comment or java doc comment?
   if (joinComments) {
      save_pos(p);
      _first_non_blank();
      joiningLineComment = joiningLineComment && (_inExtendableLineComment(delims) > 0);
      joiningJavaComment = joiningJavaComment && (_inJavadoc() > 0);
      restore_pos(p);
   }

   // if we are joining two comment lines, turn on strip leading spaces
   if (joiningLineComment || joiningJavaComment) {
      stripLeadingSpaces = true;
   }

   up();
   if ( stripLeadingSpaces!="" && !stripLeadingSpaces) { /* Do not strip spaces? */
      status=_JoinLineToCursor();
   } else {
      down();
      _str deletedText;
      strip_leading_spaces(deletedText);
      up();
      status=_JoinLineToCursor();
      if (status && p_TruncateLength) {
         save_pos(p);
         down();
         if (length(deletedText)>_TruncateLengthC()) {
            deletedText=substr(deletedText,1,_TruncateLengthC());
         }
         _begin_line();_insert_text(deletedText);
         restore_pos(p);
      }
      //current_line= current_line:+strip(line,"L")

      // strip the leading comment
      // designator
      if (joiningLineComment) {
         if (get_text(3)=="///") {
            // XML Doc
            _delete_char();
            _delete_char();
            _delete_char();
         } else if (get_text(2)=="//") {
            // C++ comment
            _delete_char();
            _delete_char();
         } else if (get_text(length(delims))==lowcase(delims)) {
            int i;
            for (i=0; i<length(delims); ++i) {
               _delete_char();
            }
         } else if (get_text(1)=="#") {
            // Shell comment
            _delete_char();
         } else if (get_text(1)=="*") {
            // Assembly, COBOL comment
            _delete_char();
         } else if (get_text(1)=="'") {
            // Basic comment
            _delete_char();
         } else if (get_text(1)=="!") {
            // Assembler, Basic comment
            _delete_char();
         } else if (get_text(1)==";") {
            // Assembler, Basic comment
            _delete_char();
         } else if (get_text(2)=="--") {
            // Ada, Pascal, VHDL comment
            _delete_char();
            _delete_char();
         } else if (lowcase(get_text(4)):=="rem ") {
            // Basic comment
            _delete_char();
            _delete_char();
            _delete_char();
         }
      } else if (joiningJavaComment) {
         // Java doc leading star
         if (get_text(1)=="*" && get_text(2)!="*/") {
            _delete_char();
         }
      }
   }
   return(status);

}
/**
 * Places cursor on first character of selection specified.  <i>mark_id</i> is a handle to a
 * selection or bookmark returned by one of the built-ins <b>_alloc_selection</b> or <b>_duplicate_selection</b>.
 * A <i>mark_id</i> of "" or no <i>mark_id</i> parameter identifies the active selection.  If the selection type is LINE,
 * the cursor is moved to the first line of the selection and the column position is unchanged.
 *
 * @param markid a handle to a selection or bookmark returned by one of the built-ins <b>_alloc_selection</b> or
 * <b>_duplicate_selection</b> * @param LockSelection
 * @param RestoreScrollPos
 *
 * @return 0 if successful.  Possible return values are TEXT_NOT_SELECTED_RC or
 * INVALID_SELECTION_HANDLE_RC.  On error, message is displayed.
 * @categories Edit_Window_Methods, Selection_Functions
 */
_command int begin_select(_str markid="",bool LockSelection=true,bool RestoreScrollPos=false) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   temp_view_id := 0;
   orig_view_id := 0;
   if (!_isEditorCtl()) {
      orig_view_id=_create_temp_view(temp_view_id);
   }
   int orig_buf_id=p_buf_id;
   int status=_begin_select(arg(1),LockSelection,RestoreScrollPos);
   if (status) {
      return(status);
   }
   // Here we exit scroll for convenience.
   // Caller might have already done this
   _ExitScroll();
   if (def_one_file!="" || !p_mdi_child || _no_child_windows() ||
       !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)
      ) {
      if (!_correct_window(orig_buf_id)) {
         _begin_select(arg(1),true,false);
      }
   }
   if (_select_type(arg(1))!="BLOCK") {
      // IF this is not a bookmark
      if (!_select_type(arg(1),'B')) {
          // Need this for multiple cursor support
         // make the pivot point the beginning of the selection
         _select_type(arg(1),'P','EE');
      }
   }
   if (temp_view_id != 0) {
      _delete_temp_view(temp_view_id);
   }
   return(0);
}
int _correct_window(int orig_buf_id)
{
   _str buf_name=p_buf_name;
   int buf_id=p_buf_id;
   // If the original buffer is the same as the new buffer
   if (orig_buf_id==buf_id) {
      return(0);
   }
   // Restore original buffer displayed in this window
   p_buf_id=orig_buf_id;
   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW) {
      // -bp so next_buffer/prev_buffer don't modified the buffer list in one file per window mode.
      edit("-bp +bi "buf_id);
      return 0;
   }

   // Find a window to display this window
   i := wid := 0;
   for (i=1;i<=_last_window_id();++i) {
      if (_iswindow_valid(i) && i._isEditorCtl(false) && !i.p_IsMinimap && i.p_buf_id==buf_id &&
          !i.p_DockingArea &&
          (i.p_mdi_child ||
           !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW))
         ) {
         wid=i;
         break;
      }
   }
   /*wid=window_match(buf_name,1,'xn');
   for (;;) {
      if (!wid) break;
      if (wid.p_buf_id==buf_id) break;
      wid=window_match(buf_name,0,'xn');
   }
   */
   if (wid) {
      p_window_id=wid;
      _set_focus();
   } else {
      if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
         return(1);
      }
      // -bp so next_buffer/prev_buffer don't modified the buffer list in one file per window mode.
      edit("-bp +bi "buf_id);
   }
   return(0);
}

/**
 * Create a character selection on the specified range
 * given by a start and end seekpos.  If there is an
 * existing selection, save it before calling this function.
 *
 * @param start_seekpos  start seekpos (real offset)
 * @param end_seekpos    end seekpos for selection (real offset)
 * @return Returns the mark ID of the newly allocated selection.
 *         Returns negative number or zero if no selection is made.
 */
int select_range(long start_seekpos, long end_seekpos)
{
   // create mark so we don't search past end of embedded context
   int mark_id=TEXT_NOT_SELECTED_RC;
   if (start_seekpos > 0 && end_seekpos > 0) {
      mark_id=_alloc_selection();
      if (mark_id >= 0) {
         _show_selection(mark_id);
         save_pos(auto p);
         _GoToROffset(start_seekpos);
         _select_char();   // mark beginning of selection
         _GoToROffset(end_seekpos);
         _select_char();   // mark end of selection
         restore_pos(p);
      }
   }
   return mark_id;
}
/**
 * Places cursor on last character of selection.  If the current selection
 * type is LINE, the cursor is moved to the last line of the selection and
 * the column position is unchanged.
 *
 * @return  Returns 0 if successful.  Otherwise TEXT_NOT_SELECTED_RC is
 * returned.  On error, message is displayed.
 *
 * @appliesTo  Edit_Window
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command end_select(_str markid="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int orig_buf_id=p_buf_id;
   int status=_end_select(arg(1),true,false);
   if (status) {
      return(status);
   }
   if (def_one_file!="" || !p_mdi_child || _no_child_windows() ||
       !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)
      ) {
      if (!_correct_window(orig_buf_id)) {
         _end_select(arg(1),true,false);
      }
   }
   if (_select_type(arg(1))!="BLOCK") {
      // IF this is not a bookmark
      if (!_select_type(arg(1),'B')) {
          // Need this for multiple cursor support
          // make the pivot point the beginning of the selection
         _select_type(arg(1),'P','BB');
      }
   }
}
/**
 * Starts, extends, or locks a line selection.  Used for processing complete
 * lines of text.  The first <b>select_line</b> becomes the pivot point.
 * Most select styles allow the selection to be extended as the cursor
 * moves.  For these styles, you can invoke this command again to lock
 * the selection so that is does not extend as the cursor moves.  In Visual
 * SlickEdit emulation, the selection does not extend as the cursor moves.
 * For this selection style, subsequent calls to this command will select
 * the text between the pivot point and the cursor.
 *
 * @see select_block
 * @see select_char
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_command void select_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _cua_select=0;
   if ( lock_selection() ) return;
   flag := _select_type("")!="" && _select_type('','S')!='C';
   status := _select_line('',def_select_style:+def_advanced_select);
   if ( status==TEXT_ALREADY_SELECTED_RC ||
        (pos('C',def_select_style,1,'i') && flag) ) {
      _deselect();clear_message();select_line();
   }
}
_command void select_matching_paren() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   _select_matching_paren();
}
void _select_matching_paren() {
   if (command_state()) {
      return;
   }
   text := get_text(1);
   if (_asc(text)==13 || _asc(text)==10) {
      left();
      text=get_text(1);
      if (!(pos(text,"([{") || pos(text,")]}"))) {
         right();
         return;
      }
   }
   _deselect();
   vi_correct_visual_mode();
   sel_forward  := (pos(text,"([{") != 0);
   if (!sel_forward) {
      right();
   }
   _cua_select_char();
   save_pos(auto p);
   int status=find_matching_paren(true);
   if (status) {
      restore_pos(p);
      _deselect();
      vi_correct_visual_mode();
      return;
   }
   if (sel_forward) {
      right();
   }
   _cua_select_char();
   vi_correct_visual_mode();
}
/**
 * Starts, extends, or locks a block selection.  Used for processing
 * columns of text.  The first <b>select_block</b> becomes the pivot
 * point.  Most select styles allow the selection to be extended as the
 * cursor moves.  For these styles, you can invoke this command again to
 * lock the selection so that is does not extend as the cursor moves.  In
 * SlickEdit emulation, the selection does not extend as the cursor
 * moves.  For this selection style, subsequent calls to this command will
 * select the text between the pivot point and the cursor.
 *
 * @see select_char
 * @see select_line
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_command void select_block() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
#if !MULTI_CURSOR_SUPPORTS_BLOCK_MARK
   if (_MultiCursor()) {
      _MultiCursorClearAll();
      _deselect();
   }
#endif
   // If they hit Ctrl+I and we are in HTML, check if it
   // is safe to surround the selection with <i> and </i>
   if (last_event()==C_B &&
       select_active() && _select_type()!="BLOCK" &&
       checkHTMLContext() && !_QReadOnly() ) {
      insert_html_bold();
      return;
   }

   _cua_select=0;
   if ( lock_selection() ) return;
   flag := _select_type('')!='' && _select_type('','S')!='C';
   int status=_select_block('',def_select_style:+def_advanced_select);
   if (!def_inclusive_block_sel) {
      _select_type('','I',0);
   }
   if ( status==TEXT_ALREADY_SELECTED_RC ||
        (pos('C',def_select_style,1,'i') && flag)
      ) {
      _deselect();clear_message();select_block();
   }

}

/**
 * Converts selection into multiple character selections, one
 * per line.
 *
 * @see select_char
 * @see select_line
 * @see select_block
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_command void convert_to_multiple_cursors() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (_MultiCursor()) {
      _MultiCursorClearAll();
   }
   _MultiCursorAddFromActiveSelection();
}

void _cua_select_char(_str markid="")
{
   inclusive := "";
   if ( _select_type(markid)!='' && _select_type(markid,'I') ) {
      inclusive='I';
   }
   mstyle := "";
   if ( def_persistent_select=='Y' ) {
      mstyle='EP':+inclusive;
   } else {
      mstyle='E':+inclusive;
   }
   int status=_select_char(markid,mstyle);
   if (status) {
      message(get_message(status));
      return;
   }
   _cua_select=1;
}
/**
 * Starts, extends, or locks a character selection.  Used for processing
 * sentences of text.  The first <b>select_char</b> becomes the pivot
 * point.  Most select styles allow the selection to be extended as the
 * cursor moves.  For these styles, you can invoke this command again to
 * lock the selection so that is does not extend as the cursor moves.  In
 * SlickEdit emulation, the selection does not extend as the cursor
 * moves.  For this selection style, subsequent calls to this command will
 * select the text between the pivot point and the cursor.
 *
 * @see select_block
 * @see select_line
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_command void select_char() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _cua_select=0;
   if ( lock_selection() ) {
      return;
   }
   flag := _select_type('')!='' && _select_type('','S')!='C';
   int status=_select_char('',def_select_style:+def_advanced_select);
   if ( status==TEXT_ALREADY_SELECTED_RC || (pos('C',def_select_style,1,'i') && flag) ) {
      _deselect();clear_message();select_char();
   }
}
/**
 * Clears the selection.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_command void deselect() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL/*|VSARG2_REQUIRES_AB_SELECTION*/)
{
   // check if there is a selection in the mouse-over tooltip to deselect first
   if (_ECCommandCallback("deselect")) return;

   _deselect();
}
int _OnUpdate_deselect(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid.select_active() && !target_wid._ECCommandCallback("isselected")) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}

/**
 * Copies selection to the cursor.  Character or block selections are inserted
 * before the character at the cursor.  For line selection, lines are inserted
 * before or after current line depending on the <b>Line insert style</b>.  By
 * default line marks are inserted after the current line.  Resulting selection
 * is always on destination text.
 *
 * @return  Returns 0 if successful.  Common return codes are TEXT_NOT_SELECTED_RC
 * and SOURCE_DEST_CONFLICT_RC.  On error, message is displayed.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command int copy_to_cursor(...) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_SELECTION)
{
   return(_copy_or_move(arg(1),'C'));

}
/**
 * Moves selection specified to the cursor.  For block and character
 * selections, the text is inserted at the cursor position.  In the case of a
 * line selection, the lines are inserted after the current line.  Resulting
 * selection is placed on the inserted text.
 *
 * @return Returns 0 if successful.  Common return codes are
 * TEXT_NOT_SELECTED_RC, and SOURCE_DEST_CONFLICT_RC.  On error, message is
 * displayed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_command int move_to_cursor(...) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_SELECTION)
{
   return(_copy_or_move(arg(1),'M'));

}
int _copy_or_move(_str markid="",_str copymove_option="",bool do_smartpaste=true,bool support_deselect=true,int MarkFlags=-1)
{
   status := 0;
   //typeless markid=arg(1);
   //typeless copymove_option=arg(2);
   //typeless do_smartpaste=arg(3);
   //typeless support_deselect=arg(4);

   srcbuf_eq_destbuf := false;
   paste_src := 0L;
   sel_type := _select_type(markid);

   if (_select_type(markid)=="") {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   // Lock the selection
   if (markid=="") markid=_duplicate_selection("");
   _select_type(markid,'S','E');
   _get_selinfo(auto start_col, auto end_col, auto srcbuf_id, markid, auto j4, auto j5, auto j6, auto num_sellines);
   srcbuf_eq_destbuf = srcbuf_id == p_buf_id;

   if (srcbuf_eq_destbuf) {
      // Lookup location of selection in the document, in case we need
      // to feed it to the beautifier.
      save_pos(auto p1);
      _begin_select(markid);
      if (sel_type == "LINE") {
         p_col=1;
      }
      paste_src = _QROffset();
      restore_pos(p1);
   }

   if (do_smartpaste) {
      // Here we are assuming we were called from clipbd.e on a
      // paste operation.
      _extend_outline_selection(markid);
   }
   /* lock_selection(1)  /* No message */ */
   special_case := _select_type(markid)=="LINE" && def_line_insert=="B";
   int cursor_y;
   if ( special_case ) {
      cursor_y=p_cursor_y;
      up();
   }

   _str select_style=_select_type('','S');
   _str persistent_mark=_select_type('','U');
   userLockedSelection := select_style=='E' && persistent_mark=='P';

   adjust_outline_destination(markid);
   if (sel_type=="CHAR" && _on_line0()) {
      insert_line("");
   }

   beautify_destination := beautify_paste_expansion(p_LangId) && sel_type != "BLOCK";

   if (do_smartpaste && !beautify_destination) {
      status=smart_paste(markid,copymove_option,"",true,"",0,MarkFlags);
   } else {
      orig_newline:=p_newline;
      if (MarkFlags!=-1 && (MarkFlags & VSMARKFLAG_KEEP_SRC_NLCHARS)) {
         p_newline=_BufGetNewline(srcbuf_id);
      }
      if ( upcase(copymove_option)=='M' ) {
         status=_move_to_cursor(markid,MarkFlags);
      } else {
         status=_copy_to_cursor(markid,MarkFlags);
      }
      if (MarkFlags!=-1 && (MarkFlags & VSMARKFLAG_KEEP_SRC_NLCHARS)) {
         p_newline=orig_newline;
      }
   }
   if ( special_case && (!status || status==SOURCE_DEST_CONFLICT_RC) ) {
      down();
      set_scroll_pos(p_left_edge,cursor_y);
   }

   if (!userLockedSelection || upcase(def_persistent_select)!="Y") {
      // Turn off persistance so that selection goes away when the
      // cursor moves
      if(_select_type(markid)!="") _select_type(markid,'U','');
   }
   //_free_selection(markid);

   start_offset := _QROffset();

   if (beautify_destination) {
      save_pos(auto p1);
      if(sel_type != "") {
         _begin_select(markid);
         p_col=1;
      }
      start_offset = _QROffset();
      restore_pos(p1);
   }

   if (support_deselect && def_deselect_copyto) {
      _deselect(markid);
   }

   if (status == 0 && beautify_destination) {
      if (sel_type == "LINE") {
         if (def_line_insert == "A") {
            // Arrange to have cursor on last line of the selection.
            p_line += num_sellines;
         }
      } else if (sel_type == "CHAR") {
         // start_offset is correct.  We need to get the cursor to the end of
         // pasted selection.
         int calc_col;

         if (num_sellines > 1) {
            calc_col = max(1, p_col + (end_col - p_col));
            p_line += num_sellines-1;
         } else {
            calc_col = p_col + (end_col - start_col);
         }
         p_col = calc_col;
      } else {
         return status;
      }

      if (srcbuf_eq_destbuf) {
         beautify_moved_selection(sel_type, paste_src, start_offset, num_sellines);

         // The beautifier fiddled the selection, so enforce the persistence settings.
         if (!userLockedSelection || upcase(def_persistent_select)!="Y") {
            // Turn off persistance so that selection goes away when the
            // cursor moves
            _select_type(markid,'U','');
         }
      } else {
         beautify_pasted_code(sel_type, start_offset, num_sellines);
      }
   }

   return(status);
}

static void adjust_outline_destination(typeless markid)
{
   if (_select_type(markid)=="LINE") {
      //count=count_lines_in_selection(markid);
      //messageNwait("adjust_outline_destination: count="count);
      //bottom();
      //return;
      int pm= _lineflags()&(PLUSBITMAP_LF|MINUSBITMAP_LF);
      // IF there is a plus bitmap displayed on this line.
      if (pm==PLUSBITMAP_LF) {
         for (;;) {
            if (down()) {
               break;
            }
            if (!(_lineflags()&HIDDEN_LF)) {
               up();
               break;
            }
         }
      }
   }
}

/**
 * Stops the selection area from being extended as the cursor moves.  Used
 * for any selection style which extends the selection area as the cursor moves.
 * The <b>adjust_block_selection</b> command is only useful when the selection
 * is locked so a destination can be indicated with the cursor.
 *
 * @return Returns 0 if no mark active in current buffer.  Otherwise 1 is
 * returned.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_str lock_selection(_str quiet="")
{
   if ( _select_type('','S')=='C' && def_advanced_select!="" ) {
      int first_col,last_col,buf_id;
      _get_selinfo(first_col,last_col,buf_id);
      if ( p_buf_id==buf_id ) {
         select_it(_select_type(),"",_select_type('','I'):+def_advanced_select);
         if ( quiet=="" ) {
            message("Selection locked.");
         }
         return(1);
      }
   }
   return(0);

}
/**
 * Deletes the selection.  No clipboard is created.  This function performs
 * a "binary" delete when in hex mode (<b>p_hex_mode</b>==<b>true</b>).  A
 * binary delete allows bisecting of end of line pairs like CR,LF.
 *
 * @return  On error, displays message.  Possible message is "Text not selected".
 *
 * @see     cut
 * @categories Selection_Functions
 */
_command void delete_selection() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   int was_command_state=command_state();
   if (was_command_state) {
      int start_pos,end_pos;
      _get_sel(start_pos,end_pos);
      if (start_pos==end_pos) {
         set_command("",1);
         return;
      }
      init_command_op();
      if (_select_type()=="") {
         retrieve_command_results();
         return;
      }

   }
   typeless markid=arg(1);
   int selType = _select_type(markid, 'T');
   _extend_outline_selection(markid);
   _begin_select(markid);
   commentwrap_DeleteSelection(markid);
   if (was_command_state) retrieve_command_results();
   else {
      if ((selType :=="CHAR") || (selType :=="LINE")) {
         //say("CF delete selection here we go.");
      }
   }
}
/**
 * Deletes current line or lines in selection
 *
 * <p>If a non-empty selection is active in the current buffer,
 * the delete lines in the selection. Otherwise, the current
 * line is deleted.
 *
 * @return  On error, displays message.  Possible message is "Text not selected".
 *
 * @see     delete_selection
 * @categories Selection_Functions
 */
_command void delete_lines() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL) {

   if (command_state()) {
      delete_line();
      return;
   }
   if (select_active2()) {
      if (_select_type()!="LINE") {
         _select_type("","T","LINE");
      }
      delete_selection();
      return;
   }
   delete_line();
}
/**
 * Fill the selection with a character you choose.  The <b>Fill Selection
 * dialog box</b> is displayed to prompt you for the character to press.
 *
 * @see fill_selection
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 */
_command void gui_fill_selection() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   _macro('m',_macro());
   fill_selection("gui");
}
/**
 *    Fills selection with key you type.  If the <i>gui</i> option is given
 * and not "", a message box is displayed to prompt the user to press a key to
 * fill the selection.  Otherwise, message is displayed on the message line to
 * prompt the user to press a key.
 *
 * @return  Returns 0 if successful.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_command fill_selection(...) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   typeless gui=arg(1);
   if (!p_mdi_child && _executed_from_key_or_cmdline("fill_selection")) {
      gui=1;
   }
   if ( _select_type()=="" ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   _macro_delete_line();
   static _str key;
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      if (gui!="") {
         orig_wid := p_window_id;
         int wid=show("_fill_form");
         key=get_event('F');
         wid._delete_window();
         if ( iscancel(key) ) {
            return(1);
         }
         p_window_id=orig_wid;
         _macro('m',_macro('s'));
      } else {
         message(nls("Type a key to fill mark with"));key=get_event();
         if ( iscancel(key) ) {
            cancel();
            return(1);
         }
      }
   }
   _str param=key2ascii(key);
   _macro_call("_fill_selection",param);
   clear_message();
   _fill_selection(param);
   return(0);
}
/**
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command adjust_block_selection() name_info(','/*VSARG2_MARK|*/VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_BLOCK_SELECTION)
{
   _adjust_block_selection();
}
/**
 * Overwrites block selection at cursor position.  No clipboard is created.
 * Resulting selection is placed on inserted text.  A block of text may be
 * selected with the <b>select_block</b> command (Ctrl+B).  You need
 * to lock the selection for this command to be useful.  Invoke the
 * <b>select_block</b> command again to lock a selection.
 *
 * @appliesTo Editor_Control, Edit_Window
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_command void overlay_block_selection() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_BLOCK_SELECTION)
{
   _overlay_block_selection();
}
/**
 * Shifts selection left the number of character specified.  Character
 * selections are treated the same as line selections.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 */
_command void shift_selection_left(...) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   typeless numshifts=arg(1);
   if (numshifts=="") {
      numshifts=1;
   }
   int i;
   for (i=1;i<=numshifts;++i) {
      _shift_selection_left();
   }
}
/**
 * Shifts selection right the number of characters specified.  Character
 * selections are treated the same as line selections.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 */
_command void shift_selection_right(...) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   typeless numshifts=arg(1);
   if (numshifts=="") {
      numshifts=1;
   }
   int i;
   for (i=1;i<=numshifts;++i) {
      _shift_selection_right();
   }
}
/**
 * Shifts selection right the number of characters specified.  Character selections are treated the
 * same as line selections.  If the 'L' option is given the selection is shifted left.  If the count
 * is not specified, you a prompted to enter a shift count.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_command void arg_shift_selection() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   _macro_delete_line();
   _str LeftOrRight;
   _str count;
   result := 0;
   LeftOrRight=upcase(arg(1));
   doLeft := (LeftOrRight=="L");
   count=arg(2);
   if (count=="") {
      result=show("-modal _textbox_form",
                  (doLeft)?"Shift Selection Left":"Shift Selection Right", // Form caption
                  0, //flags
                  "",   //use default textbox width
                  "",   //Help item.
                  "",   //Buttons and captions
                  "arg_shift_selection",  //Retrieve Name
                  "-i 1,99999 Count:"1
                 );
      if (result=="") {
         return;
      }
      count=_param1;
   }
   if (doLeft) {
      shift_selection_left(count);
      _macro_call("shift_selection_left",count);
   } else {
      shift_selection_right(count);
      _macro_call("shift_selection_right",count);
   }
}
/**
 * Quotes the next character typed.  If a non-ASCII key is typed, a Visual
 * SlickEdit binary key string is inserted.  Useful for entering printer
 * codes into a file such as Ctrl+L into a file.
 *
 * @categories Keyboard_Functions
 *
 */
_command void quote_key() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   message(nls("Type a key"));
   _str key=get_event();
   clear_message();
   key=key2ascii(key);
   _str param;
   if ( length(key)>1 ) {
      param=last_event();
   } else {
      param=key;
   }
   _macro_call("keyin",param);
   keyin(param);
}
/**
 * Toggles insert mode on/off.  The cursor shape is a full character when in
 * over-write mode.  When in insert mode, characters are inserted at the cursor
 * position.  When in over-write mode, the characters at the cursor position are
 * replaced.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command void insert_toggle() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX|VSARG2_READ_ONLY|VSARG2_MARK)
{
   _macro_delete_line();
   _insert_toggle();
   if (_insert_state()) {
      _macro_call("_insert_state",1);
   } else {
      _macro_call("_insert_state",0);
   }
}
bool def_esc_deselects;
/**
 * If the visible cursor is on the command line, the cursor is
 * moved to the current edit window.  Otherwise the visible cursor
 * is moved from the current edit window to the command line.
 *
 * @appliesTo  Edit_Window, Command_Line
 *
 * @categories Command_Line_Functions
 */
_command void cmdline_toggle() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON)
{
   mdi_with_cmdline := false;
   if ( p_active_form.p_isToolWindow ) {
      mdi_with_cmdline = _MDIWindowHasMDIArea(p_active_form);
   }
   if ( ((!p_mdi_child && !p_active_form.p_isToolWindow)
         || (!p_mdi_child && !mdi_with_cmdline))
        && p_object == OI_EDITOR && p_active_form.p_object == OI_FORM ) {

      ToolWindowInfo* twinfo = tw_find_info(p_active_form.p_name);
      if (last_event() :== ESC && twinfo && (twinfo->flags & TWF_DISMISS_LIKE_DIALOG) ) {
         tw_dismiss(p_active_form);
      } else {
         if ( last_event() :== ESC || last_event() :== A_F4 ) {
            call_event(defeventtab _ainh_dlg_manager, last_event(), 'e');
         }
      }
      return;
   }
   if ( p_active_form == tw_is_current_form("_tbshell_form") ||
        p_active_form == tw_is_current_form("_tbterminal_form") ||
        p_active_form == tw_is_current_form("_tbinteractive_form") ) {
      // Note: tw_auto_lower() is a no-op if p_active_form is not an auto-hide window
      tw_auto_lower(p_active_form);
      int child_wid = _MDICurrentChild(0);
      if ( !child_wid ) {
         p_window_id = _cmdline;
      } else {
         p_window_id = child_wid;
      }
      _set_focus();
      return;
   }
   if (last_event():==ESC) {
      if (_MultiCursor()) {
         _MultiCursorClearAll();
         _deselect();
         return;
      }
   }
   if (def_esc_deselects && _isEditorCtl(false) && select_active2()) {
      deselect();
      return;
   }
   result := 0;
   if ((p_window_id!=_cmdline &&
        !_default_option(VSOPTION_HAVECMDLINE))) {
      if (isEclipsePlugin()) {
         result = show("-modal -xy _textbox_form",
                       "SlickEdit Command", // Form caption
                       TB_RETRIEVE, //flags
                       "", //use default textbox width
                       "", //Help item.
                       "", //Buttons and captions
                       "command",   //Retrieve Name
                       "-c "COMMAND_ARG:+_chr(0)"Command:");
      } else {
         result = show("-modal _textbox_form",
                       "", // Form caption
                       TB_RETRIEVE, //flags
                       "", //use default textbox width
                       "", //Help item.
                       "", //Buttons and captions
                       "command",   //Retrieve Name
                       "-c "COMMAND_ARG:+_chr(0)"Command:");
      }
      if (result=="") {
         return;
      }
      _str text=_param1;
      if (def_keys=="ispf-keys") {
         ispf_do_lc();
         _str cmdname;
         cmdline := strip(text,'L');
         parse cmdline with cmdname .;
         cmdname=lowcase(cmdname);
         if (find_index("ispf-"cmdname,COMMAND_TYPE|IGNORECASE_TYPE)) {
            text="ispf-"substr(lowcase(cmdname),1,length(cmdname)):+substr(cmdline,length(cmdname)+1);
         }
      }
      if ( _macro() ) {
         _cmdline.get_command(text);
         _macro_call("execute",text,'a');
      }
      _macro('m',_macro());
      last_index(prev_index());

      if (def_unix_expansion) {
         /* Execute result of function call. */
         //_cmdline.set_command("",1);
         execute(_maybe_unix_expansion(text),'a');
         //append_retrieve_command(text);
      } else {
         execute(text,'ar');
      }
      if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_ONE_FILE_PER_WINDOW)) {
         def_one_file="+w";
      }
      return;
   }

   if (!command_state()) {
      // Assume that retrieve_prev_form/next_form called
      int view_id;
      get_window_id(view_id);
      activate_window(VSWID_RETRIEVE);
      bottom();
      activate_window(view_id);
      _macro_delete_line();
   }
   /* call last_index(prev_index()) */
   int child_wid=_MDICurrentChild(0);
   if (!child_wid) {
      activate_window(_cmdline);
      _cmdline._set_focus();
   } else {
      command_toggle();
   }
}
/**
 * Inserts or overwrites the last key pressed depending upon the insert
 * state.
 *
 * @categories Keyboard_Functions
 *
 */
_command void normal_character() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   maybe_delete_selection();
   keyin(key2ascii(last_event()));
}
/**
 * Inserts or overwrites the MDI edit window buffer name depending on the
 * insert state.
 *
 * @appliesTo Edit_Window, Editor_Control Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command void keyin_buf_name() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX)
{
   maybe_delete_selection();
   _str buf_name= _mdi._edit_window().p_buf_name;
   keyin(_maybe_quote_filename(buf_name));
}
/**
 * Affects nothing.
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void nothing() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
}
/**
 * Moves the line position of the retrieve buffer ".command", one line up
 * and places the contents of the line on the command line.  If the current
 * line is the first line of the buffer, the cursor is placed on the last line
 * and the contents of the last line are placed on the command line.
 * When a command is executed, the current line of the retrieve buffer
 * becomes the last line.  However, the first execution of
 * <b>retrieve_prev</b> after the command is executed will place the
 * contents of the last line on the command line and not move the line
 * position.
 *
 * @see retrieve_next
 *
 * @categories Retrieve_Functions
 *
 */
_command void retrieve_prev() name_info(','VSARG2_CMDLINE)
{
   _str line;
   _cmdline.retrieve_skip();_cmdline.get_command(line);command_put(line);
}
/**
 * Moves the line position of the retrieve buffer ".command", one line
 * down and places the contents of the line on the command line.  If the
 * current line is the last line of the buffer, the cursor is placed on the
 * first line and the contents of the first line are placed on the command
 * line.  When a command is executed, the current line of the retrieve
 * buffer becomes the last line.
 *
 * @see retrieve_prev
 *
 * @categories Retrieve_Functions
 *
 */
_command void retrieve_next() name_info(','VSARG2_CMDLINE)
{
   _str line;
   _cmdline.retrieve_skip('n');_cmdline.get_command(line);command_put(line);
}

void _minihtml_UseDialogFont()
{
   typeless font_name, font_size, flags, charset;
   parse _default_font(CFG_DIALOG) with font_name","font_size","flags","charset;
   if( !isinteger(charset) ) charset=-1;
   if( !isinteger(font_size) ) font_size=8;

   if( font_name!="" ) {
      _minihtml_SetProportionalFont(font_name,charset);
   }
   if( isinteger(font_size) ) {
      _minihtml_SetProportionalFontSize(-1,font_size*10);
      _minihtml_SetFixedFontSize(-1,font_size*10);
   }
}

static const MINIHTML_INDENT_X= 100;

defeventtab _program_info_form;

void _program_info_form.on_resize() {
   // make sure the dialog doesn't get too scrunched
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(MIN_PROG_INFO_WIDTH, MIN_PROG_INFO_HEIGHT);
   }
   // resize the width of the tabs and html controls
   ctlsstab1.p_x_extent = p_width;
   minihtml_width := ctlsstab1.p_width - _dx2lx(SM_TWIP,4)- 2*MINIHTML_INDENT_X;
   ctlminihtml_about.p_width      = minihtml_width;
   ctlminihtml_notes.p_width      = minihtml_width;
   ctlminihtml_copyrights.p_width = minihtml_width;
   ctlminihtml_license.p_width    = minihtml_width;
   ctlminihtml_contact.p_width    = minihtml_width;

   if( ctlbob_banner.p_picture!=0 ) {
      // set the width of the picture box to the width of the dialog
      ctl_banner_box.p_width=p_width;
   } else {
      // No picture, so size down to 0x0 to force the html control to the
      // top of the dialog.
      ctlbob_banner.p_width=0;
      ctlbob_banner.p_height=0;
      ctl_banner_box.p_width=0;
      ctl_banner_box.p_height=0;
   }

   // place the buttons and size the tabs/html controls appropriately
   ctlok.p_y=ctlcopy.p_y=p_height-ctlok.p_height-p_active_form._top_height()-p_active_form._bottom_height()-100;
   ctlsstab1.p_height=ctlok.p_y-ctl_banner_box.p_height-100;

   SSTABCONTAINERINFO info;
   ctlsstab1._getTabInfo(0, info);
   minihtml_height := ctlsstab1.p_height - _dy2ly(SM_TWIP,info.by-info.ty+1);
   ctlminihtml_about.p_height      = minihtml_height;
   ctlminihtml_notes.p_height      = minihtml_height;
   ctlminihtml_copyrights.p_height = minihtml_height;
   ctlminihtml_license.p_height    = minihtml_height;
   ctlminihtml_contact.p_height    = minihtml_height;
}

void ctlcopy.lbutton_up()
{
   switch (ctlsstab1.p_ActiveTab) {
   case 0:
      ctlminihtml_about._minihtml_command("copy");
      break;
   case 1:
      ctlminihtml_notes._minihtml_command("copy");
      break;
   case 2:
      ctlminihtml_copyrights._minihtml_command("copy");
      break;
   case 3:
      ctlminihtml_license._minihtml_command("copy");
      break;
   case 4:
      ctlminihtml_contact._minihtml_command("copy");
      break;
   }
}

void ctlminihtml_about.on_change(int reason,_str hrefText)
{
   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
       // is this a command or function we should run?
       if (substr(hrefText,1,6)=="<<cmd") {
           cmdStr := substr(hrefText,7);
           cmd := "";
           params := "";
           parse cmdStr with cmd params;
           index := find_index(cmd, COMMAND_TYPE|PROC_TYPE);
           if (index && index_callable(index)) {
              // get the active window
              int curWid = _mdi;
              get_window_id(curWid);
              // activate the MDI window
              activate_window(_mdi);
              if (params == "") {
                 call_index(index);
              } else {
                 call_index(params,index);
              }
              // restore the current window
              if (_iswindow_valid(curWid)) {
                 activate_window(curWid);
              }
           }
           return;
       }
   }
}

static _str aboutLicenseInfo()
{
   // locate the license file, on Windows it is installed under 'docs'
   license_name := "";
   if (isEclipsePlugin()) {
      license_name = "license_eclipse.htm";
   } else {
      license_name = "license.htm";
   }
   _str vsroot = _getSlickEditInstallPath();
   license_file :=  vsroot"docs"FILESEP :+ license_name;
   if (!file_exists(license_file)) {
      // Unix case, check in root installation directory
      license_file = vsroot""FILESEP:+ license_name;
   }
   if (!file_exists(license_file)) {
      // this is only needed for running out of the build directory
      license_file = vsroot"tools"FILESEP:+ license_name;
   }

   // get the contents of the license file
   license_text := "";
   _GetFileContents(license_file, license_text);

   return license_text;
}

static _str aboutReleaseNotesInfo()
{
   // Get the contents of the readme and load it into ctlminihtml_notes
   _str vsroot = _getSlickEditInstallPath();
   readme_text := "";
   readme_file := "";
   _maybe_append_filesep(vsroot);
   if (isEclipsePlugin()) {
      readme_file = vsroot"readme-eclipse.html";
   } else {
      readme_file = vsroot"readme.html";
   }
   _GetFileContents(readme_file, readme_text);
   return readme_text;
}

static _str aboutCopyrightInfo()
{
   // Get the contents of the readme and load it into ctlminihtml_copyrights
   _str vsroot = _getSlickEditInstallPath();
   readme_text := "";
   readme_file := "";
   _maybe_append_filesep(vsroot);
   if (isEclipsePlugin()) {
      readme_file = vsroot"copyrights.html";
   } else {
      readme_file = vsroot"copyrights.html";
   }
   _GetFileContents(readme_file, readme_text);
   return readme_text;
}

// @param text            HTML text to display.
// @param caption         (optional). Dialog title bar caption.
// @param bannerPicIndex  (optional). Alternate picture index to use for banner.
//                        @see load_picture
// @param bannerBackColor (optional). Alternate picture background color.
//                        Set this if you are providing your own banner picture,
//                        and you are not centering the picture. The color will
//                        be used to fill the empty space to the right of the
//                        banner created by sizing the dialog to fit the text.
//                        @see _rgb
// @param options         (optional). "C"=center banner picture instead of
//                        right-aligning and filling extra space with background
//                        color. "S"=size the dialog to fit the width of the
//                        banner picture.
void ctlok.on_create(_str text="", _str caption="", int bannerPicIndex=-1, int bannerBackColor=-1, _str options="")
{
/*
IMPORTANT!!!!! This dialog is too difficult to size correctly. The proper way to
write this dialog is similar to the find dialog. The minihtml controls should NOT
be inside the tab control tabs. The tab control should just be a small tab control
displayed below one of the current visible minihtml control. Then you place the
small tab control at y=ctlminihtml.p_y_extent; x=ctlminihtml.p_x,
width=ctlminihtml.p_width;

*/
   if( caption!="" ) {
      p_active_form.p_caption=caption;
   } else {
      p_active_form.p_caption=editor_name('A');
   }

   typeless font_name, font_size, flags, charset;
   parse _default_font(CFG_DIALOG) with font_name","font_size","flags","charset;
   if( !isinteger(charset) ) charset=-1;
   if( !isinteger(font_size) ) font_size=8;

   ctlminihtml_about.p_text=text;

   // RGH - 5/15/2006
   // New banner for Eclipse Plugin
   if (isEclipsePlugin()) {
      bitmapsPath := _getSlickEditInstallPath():+VSE_BITMAPS_DIR:+FILESEP;
      ctlbob_banner.p_picture = _find_or_add_picture(bitmapsPath:+"_eclipse_banner.png");
   } else if (_default_option(VSOPTIONZ_APP_THEME) == "Dark" && bannerPicIndex < 0) {
      ctlbob_banner.p_picture = ctlbob_banner_dark.p_picture;
   }
   // If specified, set the banner picture displayed, otherwise
   // leave as default.
   if( bannerPicIndex!=-1 ) {
      // Since the banner box (ctl_banner_box) is contained by the form,
      // we must make sure that the form is big enough to hold the banner
      // box BEFORE we set the width of the banner box, or else it will
      // get clipped.
      p_active_form.p_width *= 2;
      p_active_form.p_height *= 2;
      // Since the banner picture control (ctlbob_banner) is contained
      // by the banner box (ctl_banner_box), we must make sure that the
      // banner box is big enough to hold the picture BEFORE we set the
      // picture index, or else it will get clipped.
      ctl_banner_box.p_width *= 2;
      ctl_banner_box.p_height *= 2;
      // Set the picture
      ctlbob_banner.p_picture=bannerPicIndex;
      // Setting p_stretch has the side-effect of kicking the picture
      // control into resizing to fit the picture (if p_auto_size=true).
      ctlbob_banner.p_stretch=false;
   }
   if( ctlbob_banner.p_picture==0 ) {
      // No picture, so size down to 0x0 to force the html control to the
      // top of the dialog.
      ctlbob_banner.p_width=0;
      ctlbob_banner.p_height=0;
      ctl_banner_box.p_width=0;
      ctl_banner_box.p_height=0;
   }

   // Adjust banner image geometry to account for frame-width
   fw := _dx2lx(SM_TWIP,ctl_banner_box._frame_width());
   fh := _dy2ly(SM_TWIP,ctl_banner_box._frame_width());
   if( ctlbob_banner.p_x < fw ) {
      ctlbob_banner.p_x += fw - ctlbob_banner.p_x;
   }
   if( ctlbob_banner.p_y < fh ) {
      ctlbob_banner.p_y += fh - ctlbob_banner.p_y;
   }

   // Size the bounding background picture control for the banner to fit
   // the banner image.
   ctl_banner_box.p_width = ctlbob_banner.p_x_extent + fw;
   ctl_banner_box.p_height = ctlbob_banner.p_y_extent +fh;


   // Force form width to initially equal width of bounding banner box
//   p_active_form.p_width=ctl_banner_box.p_width;

   // Set the background color of bounding background picture control
   if( bannerBackColor!=-1 ) {
      ctl_banner_box.p_backcolor=bannerBackColor;
   } else if (_default_option(VSOPTIONZ_APP_THEME) != "Dark") {
      // Set product-specific background color
      if( isEclipsePlugin() ) {
         ctl_banner_box.p_backcolor=0x712d34;
      } else {
         //ctl_banner_box.p_backcolor=0x003BDDA0;
         ctl_banner_box.p_backcolor=0x00FFFFFF;
      }
   }

   // Leave a vertical gap between banner box and mini html box
   //ctlminihtml_about.p_y=ctl_banner_box.p_y_extent+90;

   ctlminihtml_about.p_x=MINIHTML_INDENT_X;
   options=upcase(options);
   if( pos('S',options)!=0 ) {
      // Do not allow the width of the form and html control to be
      // greater than the width of the banner image.
      //
      // Note: The width of the form already matches the width of the
      // banner image, so we only need to adjust the width of the html
      // control.
      int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
      // Note: ctlminihtml_about.p_x*2 = gap on left and right side of control
      ctlminihtml_about.p_width=client_width - ctlminihtml_about.p_x*2;
      ctlsstab1.p_width=ctlminihtml_notes.p_width=ctlminihtml_copyrights.p_width=ctlminihtml_license.p_width=ctlminihtml_contact.p_width;
   } else {
      // Resize dialog (if necessary) to fit the text
      if( ctlminihtml_about.p_width+2*ctlsstab1.p_x < ctl_banner_box.p_width+ctlok.p_width) {
         p_active_form.p_width=ctl_banner_box.p_width+ctlok.p_width;
      } else {
         // Note: ctlminihtml_about.p_x*2 = gap on left and right side of control
         //p_active_form.p_width=ctlminihtml_about.p_x*2 + ctlminihtml_about.p_width + p_active_form._left_width()*2;
         p_active_form.p_width=ctlsstab1.p_x_extent +  p_active_form._left_width()*2;
      }
      // Form width changed, have to recalculate the client width
      int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
      // Increase width of bounding background picture control so everything
      // continues to look nice.
      ctl_banner_box.p_width=client_width;
      if( pos('C',options)!=0 ) {
         // Center banner image
         ctlbob_banner.p_x = (ctl_banner_box.p_width - ctlbob_banner.p_width) intdiv 2;
      }
   }
   // RGH - 5/15/2006
   // Line up the tab control and html controls appropriately
   ctlminihtml_notes.p_x ctlminihtml_copyrights.p_x = ctlminihtml_license.p_x = ctlminihtml_contact.p_x = ctlminihtml_about.p_x;
   ctlsstab1.p_y = ctl_banner_box.p_y_extent;
   ctlminihtml_about.p_y = ctlminihtml_notes.p_y = ctlminihtml_copyrights.p_y = ctlminihtml_license.p_y = ctlminihtml_contact.p_y = 0;

   //ctlcopy.p_y=ctlok.p_y=ctlminihtml_about.p_y_extent+100;
   //ctlminihtml_about.p_backcolor=0x80000022;
   //ctlminihtml_notes.p_backcolor=0x80000022;
   //ctlminihtml_license.p_backcolor=0x80000022;
   ctlminihtml_notes.p_text = aboutReleaseNotesInfo();
   ctlminihtml_copyrights.p_text = aboutCopyrightInfo();
   ctlminihtml_license.p_text = aboutLicenseInfo();
   ctlminihtml_contact.p_text = aboutContactInfo();

   // default start tab is program information,
   // change tabs here to readme or license depending on options
   if( pos('R',options) != 0 ) {
      ctlsstab1.p_ActiveTab=1;
   } else if( pos('L',options) != 0 ) {
      ctlsstab1.p_ActiveTab=2;
   }
}

void ctlbob_banner.lbutton_up()
{
   int x,y;
   mou_get_xy(x,y);
   _map_xy(0,p_window_id,x,y);
   if (x>=133 && x<=140 &&
       y>=7 && y<=10) {
      goto_url(_get_eurl());
   }
}

_str MBRound(long ksize)
{
   typeless before, after;
   parse ksize/(1024) with before"." +0 after;

   if (after>=.5) {
      before+=1;
   }
   return(before"MB");
}
void appendDiskInfo(_str &diskinfo,_str path,_str DirCaption,_str UsageCaption="")
{
   if( diskinfo!="" ) {
      diskinfo :+= "\n";
   }
   if( diskinfo!="" ) {
      diskinfo :+= "\n";
   }
   diskinfo :+= "<b>"DirCaption"</b>:  "path;
   diskinfo :+= getDiskInfo(path);

}
_str getDiskInfo(_str path)
{
   diskinfo := "";
   status := 0;
   if (_isWindows()) {
      FSInfo := "";
      FSName := "";
      FSFlags := 0;
      UsageInfo := "";
      long TotalSpace, FreeSpace;
      status=_GetDiskSpace(path,TotalSpace,FreeSpace);
      if (!status) {
         UsageInfo = ","MBRound(FreeSpace)" free";
      }
      if (substr(path,1,2)=='\\') {
         typeless machinename, sharename;
         parse path with '\\'machinename'\'sharename'\';
         status=ntGetVolumeInformation('\\'machinename'\'sharename'\',FSName,FSFlags);
         if (!status) {
            FSInfo=","FSName;
         }
         diskinfo :+= " (remote"FSInfo:+UsageInfo")";
      } else {
         status=ntGetVolumeInformation(substr(path,1,3),FSName,FSFlags);
         if (!status) {
            FSInfo=","FSName;
         }
         _str dt=_drive_type(substr(path,1,2));
         if (dt==DRIVE_NOROOTDIR) {
            diskinfo :+= " (invalid drive)";
         } else if (dt==DRIVE_FIXED) {
            diskinfo :+= " (non-removable drive"FSInfo:+UsageInfo")";
         } else if (dt==DRIVE_CDROM){
            diskinfo :+= " (CD-ROM"FSInfo:+UsageInfo")";
         } else if (dt==DRIVE_REMOTE){
            diskinfo :+= " (remote"FSInfo:+UsageInfo")";
         } else {
            diskinfo :+= " (removable drive"FSInfo:+UsageInfo")";
         }
      }
   }
   return diskinfo;
}

_str _version()
{
   number := "";
   parse get_message(SLICK_EDITOR_VERSION_RC) with . "Version" number . ;
   return(number);
}

_str _product_year()
{
   year := "";
   parse get_message(SLICK_EDITOR_VERSION_RC) with . "Copyright" ."-"year .;

   return year;
}

_str _getProduct(bool includeVersion=true,bool includeArchInfo=false)
{
   product := _getApplicationName();
   if( isEclipsePlugin() ) {
      if (_isUnix()) {
         product :+= " Core v"eclipse_get_version()" for Eclipse";
      } else {
         product :+= " v"eclipse_get_version()" for Eclipse";
      }
   } else {
      product :+= " "_product_year();
   }


   verInfo := "";
   archInfo := "";

   if( includeVersion ) {
      _str version = _getVersion();
      if( isEclipsePlugin() ) {
         // Product name is so long that the version just
         // looks better on the next line.
         verInfo = "\n\n<b> Library Version:</b> "version;
      } else {
         verInfo = "v"version;
      }
   }

   if ( includeArchInfo ) {
      archInfo = machine_bits()"-bit";
   }

   if (verInfo != "" || archInfo != "") {
      if (!isEclipsePlugin()) {
         product :+= " (";
      }
      if (verInfo != "") {
         product :+= verInfo;
      }

      if (archInfo != "") {
         if (verInfo != "") {
            product :+= " ";
         }
         product :+= archInfo;
      }

      if (!isEclipsePlugin()) {
         product :+= ")";
      }
   }

   return product;
}

_str aboutProduct(bool includeVersion=false, _str altCaption=null)
{
   line := "";

   includeArchInfo := false;
   if (_isWindows()) {
      includeArchInfo = true;
   } else {
      includeArchInfo = _isLinux();
   }

   _str product = _getProduct(includeVersion, includeArchInfo);
   line=product;
   if( altCaption!=null ) {
      line=altCaption:+product;
   }

   return line;
}

_str _getVersion(bool includeSuffix=true)
{
   version := "";
   suffix := "";
   parse get_message(SLICK_EDITOR_VERSION_RC) with . "Version" version suffix .;
   if( includeSuffix && stricmp(suffix,"Beta") == 0 ) {
      version :+= " "suffix;
   }
   return version;
}
_str _getUserSysFileName() {
   return(USERSYSO_FILE_PREFIX:+_getVersion(false):+USERSYSO_FILE_SUFFIX);
}

_str aboutVersion(_str altCaption=null)
{
   _str line = _getVersion();
   if( altCaption!=null ) {
      line=altCaption:+line;
   }
   return line;
}

_str _getCopyright()
{
   copyright := "";
   parse get_message(SLICK_EDITOR_VERSION_RC) with . "Copyright" +0 copyright;
   return copyright;
}

_str aboutCopyright(_str altCaption=null)
{
   _str line = _getCopyright();
   if( altCaption!=null ) {
      line=altCaption:+line;
   }
   return line;
}

_str _getInstalledSerial()
{
   return _SerialNumber();
}

_str _getSerial()
{
   return _getInstalledSerial();
}

_str aboutSerial(_str altCaption=null)
{
   _str line = _getSerial();
   if (line == "") {
      line = "No license found";
   }
   if( altCaption != null ) {
      line = altCaption:+line;
   } else {
      line = "<b>"get_message(VSRC_CAPTION_SERIAL_NUMBER)"</b>: "line;
   }
   return line;
}

_str _getLicenseType()
{
   type := _LicenseType();
   switch(type) {
   case LICENSE_TYPE_TRIAL:
      return("Trial");
      break;
   case LICENSE_TYPE_NOT_FOR_RESALE:
      return("Not For Resale");
      break;
   case LICENSE_TYPE_BETA:
      return("Beta License");
      break;
   case LICENSE_TYPE_SUBSCRIPTION:
      return("Subscription");
      break;
   case LICENSE_TYPE_ACADEMIC:
      return("Academic");
      break;
   case LICENSE_TYPE_CONCURRENT:
      return("Concurrent");
      break;
   case LICENSE_TYPE_STANDARD:
      return("Standard");
      break;
   case LICENSE_TYPE_FILE:
      return("File");
      break;
   case LICENSE_TYPE_BORROW:
      return("Borrow");
      break;
   default:
      return("Unknown licensing ("type")");
   }
}

_str _getLicensedNofusers()
{
   type := _LicenseType();
   switch(type) {
   case LICENSE_TYPE_TRIAL:
      return("Trial");
   case LICENSE_TYPE_NOT_FOR_RESALE:
      return("Not For Resale");
   case LICENSE_TYPE_BETA:
      return("Beta License");
   case LICENSE_TYPE_SUBSCRIPTION:
      return("Subscription");
   case LICENSE_TYPE_ACADEMIC:
      return("Academic");
   case LICENSE_TYPE_CONCURRENT:
   case LICENSE_TYPE_STANDARD:
   case LICENSE_TYPE_FILE:
   case LICENSE_TYPE_BORROW:
      // 0 means that this is not a concurrent license
      return(_FlexlmNofusers());
   }
   return("Unknown licensing ("type")");
}

bool _singleUserTypeLicense()
{
   switch(_LicenseType()) {
   case LICENSE_TYPE_TRIAL:
   case LICENSE_TYPE_NOT_FOR_RESALE:
   case LICENSE_TYPE_BETA:
   case LICENSE_TYPE_ACADEMIC:
   case LICENSE_TYPE_BORROW:
      return true;
   }
   return false;
}

_str aboutLicensedNofusers(_str altCaption=null)
{
   _str line = _getLicensedNofusers();
   // 0 means that this is not a concurrent license
   // 1 means that this IS a concurrent license of 1.
   // We may one to change what gets displayed if "1" is returned.
   if ((_LicenseType() != LICENSE_TYPE_CONCURRENT) && (line == "" || line=="1" || line=="0")) {
      line = "Single user";
      if (_LicenseType() == LICENSE_TYPE_BORROW) {
         line :+= " (borrowed)";
      }
   }
   if( altCaption != null ) {
      line = altCaption:+line;
   } else {
      if (isEclipsePlugin() || _singleUserTypeLicense()) {
         line = "<b>License type</b>: "line;
      } else {
         line = "<b>"get_message(VSRC_CAPTION_NOFUSERS)"</b>: "line;
      }
   }
   return line;
}

_str aboutLicensedExpiration(_str altCaption=null)
{
   int caption = VSRC_CAPTION_LICENSE_EXPIRATION;
   _str line = _LicenseExpiration();
   if (line=="") return("");
   if( altCaption != null ) {
      line = altCaption:+line;
   } else {
      if (_LicenseType() == LICENSE_TYPE_BORROW) {
         caption = VSRC_CAPTION_LICENSE_BORROW_EXPIRATION;
      }
      line_b := "";
      line_e := "";
      /*
      if (_fnpLastLicenseExpiresInDays() < 5) {
         line_b = "<font color='red'>";
         line_e = "</font>";
      }*/
      line = "<b>"get_message(caption)"</b>: ":+line_b:+line:+line_e;
   }
   return line;
}
_str aboutLicensedFile(_str altCaption=null)
{
   line := "";
   caption := -1;
   if (_LicenseType() == LICENSE_TYPE_CONCURRENT) {
      line = _LicenseServerName();
      caption = VSRC_CAPTION_LICENSE_SERVER;
   }
   if (line == "") {
      line = _LicenseFile();
      caption = VSRC_CAPTION_LICENSE_FILE;
   }
   if (line=="") return("");
   if( altCaption != null ) {
      line = altCaption:+line;
   } else {
      line = "<b>"get_message(caption)"</b>: "line;
   }
   return line;
}
_str aboutLicensedTo(_str altCaption=null)
{
   _str line = _LicenseToInfo();
   if (line=="") return("");
   if( altCaption != null ) {
      line = altCaption:+line;
   } else {
      line = "<b>"get_message(VSRC_CAPTION_LICENSE_TO)"</b>: "line;
   }
   return line;
}

_str aboutUnlicensedFeatures() {
   unlicensedFeatures := "";
   if (!_haveBuild()) {
      unlicensedFeatures :+= ", Build";
   }
   if (!_haveDebugging()) {
      unlicensedFeatures :+= ", Debugging";
   }
   if (!_haveContextTagging()) {
      unlicensedFeatures :+= ", Context Tagging(TM)";
   }
   if (!_haveVersionControl()) {
      unlicensedFeatures :+= ", Version Control";
   }
   if (!_haveProMacros()) {
      unlicensedFeatures :+= ", Pro Macros";
   }
   if (!_haveBeautifiers()) {
      unlicensedFeatures :+= ", Beautifiers";
   }
   if (!_haveProDiff()) {
      unlicensedFeatures :+= ", Pro Diff";
   }
   if (!_haveMerge()) {
      unlicensedFeatures :+= ", Merge";
   }
   if (!_haveRefactoring()) {
      unlicensedFeatures :+= ", Refactoring";
   }
   if (!_haveRealTimeErrors()) {
      unlicensedFeatures :+= ", Java Real Time Errors";
   }

   if (_isCommunityEdition()) {
      unlicensedFeatures :+= ", Large File";
   }
   if (!_haveDiff()) {
      unlicensedFeatures :+= ", Diff";
   }
   if (!_haveBackupHistory()) {
      unlicensedFeatures :+= ", Backup History";
   }
   if (!_haveXMLValidation()) {
      unlicensedFeatures :+= ", XML Validation";
   }
   if (!_haveSmartOpen()) {
      unlicensedFeatures :+= ", Smart Open";
   }
   if (!_haveFTP()) {
      unlicensedFeatures :+= ", FTP";
   }
   /*
   if (!_haveMainframeLangs()) {
      unlicensedFeatures :+= ", Mainframe Languages Tagging";
   }
   if (!_haveHardwareLangs()) {
      unlicensedFeatures :+= ", Hardware Languages Tagging";
   }
   if (!_haveAdaLangs()) {
      unlicensedFeatures :+= ", Ada Language Tagging";
   }
   if (!_haveSQLLangs()) {
      unlicensedFeatures :+= ", SQL Languages Tagging";
   }
   */
   if (!_haveDefsToolWindow()) {
      unlicensedFeatures :+= ", Defs Tool Window";
   }
   if (!_haveCurrentContextToolBar()) {
      unlicensedFeatures :+= ", Current Context Toolbar";
   }
   if (!_haveCtags()) {
      unlicensedFeatures :+= ", Ctags";
   }
   if (!_haveCodeAnnotations()) {
      unlicensedFeatures :+= ", Code Annotations";
   }
   unlicensedFeatures=strip(unlicensedFeatures,'L',',');
   unlicensedFeatures=strip(unlicensedFeatures);
   if (unlicensedFeatures!="") {
      unlicensedFeatures="<b>Unlicensed Pro Features</b>:"unlicensedFeatures;
   }
   return unlicensedFeatures;
}

_str aboutUnlicensedLanguages() {
   unlicensedLanguages := "";
   if (!_haveMainframeLangs()) {
      unlicensedLanguages :+= "Cobol, HLASM, PL/I, ";
   }
   if (!_haveHardwareLangs()) {
      unlicensedLanguages :+= "VHDL, TTCN3, Vera, Verilog, SystemVerilog, ";
   }
   if (!_haveAdaLangs()) {
      unlicensedLanguages :+= "Ada, Modula-2, ";
   }
   if (!_haveSQLLangs()) {
      unlicensedLanguages :+= "ANSI SQL, PL/SQL, SQL Server, DB2, ";
   }
   unlicensedLanguages=strip(unlicensedLanguages);
   unlicensedLanguages=strip(unlicensedLanguages,'T',',');
   if (unlicensedLanguages != "") {
      unlicensedLanguages="<b>Unlicensed Standard/Pro Languages Tagging</b>: "unlicensedLanguages;
   }
   return unlicensedLanguages;
}

static _str _localizeBuildDate(_str MMM_DD_YYYY)
{
   // break it down into short month, day, and year
   parse MMM_DD_YYYY with auto month auto day auto year;

   // Switch out short month name for long month name
   split(def_short_month_mames, ' ', auto monthNames);
   for (m:=0; m<monthNames._length(); m++) {
      if (beginsWith(monthNames[m], month, false, 'i')) break;
   }
   split(def_long_month_names, ' ', monthNames);
   if (m < monthNames._length()) {
      month = monthNames[m];
   }

   // make sure that day of month does not have a leading zero
   if (length(day) >= 2 && _first_char(day) == '0') {
      day = _last_char(day);
   }

   // return date in standard format -- should localize this
   // using DateTime class, just trying to avoid a dependency
   return month:+" ":+day:+", ":+year;
}

_str _getStateFileBuildDate()
{
   build_date := __DATE__;
   return _localizeBuildDate(build_date);
}

_str _getProductBuildDate()
{
   build_date := _getSlickEditBuildDate();
   return _localizeBuildDate(build_date);
}

_str aboutProductBuildDate(_str altCaption=null)
{
   line := "";
   if (isEclipsePlugin()) {
      line = _getEclipseBuildDate();
   } else {
      line = _getProductBuildDate();
   }

   // include the state file build date if it differs
   state_line := _getStateFileBuildDate();
   if (state_line != line) {
      line :+= "&nbsp;&nbsp;&nbsp;("get_message(VSRC_CAPTION_STATE_BUILD_DATE)": "state_line")";
   }
   if( altCaption!=null ) {
      line=altCaption:+line;
   } else {
      line="<b>"get_message(VSRC_CAPTION_BUILD_DATE)"</b>: "line;
   }
   return line;
}

_str _getExpirationDate()
{
   expiration := "";
   return expiration;
}

_str aboutExpirationDate(_str altCaption=null)
{
   _str line= _getExpirationDate();
   if( line!="" ) {
      if( altCaption!=null ) {
         line=altCaption:+line;
      } else {
         line="<b>"get_message(VSRC_CAPTION_EXPIRATION_DATE)"</b>: ":+line;
      }
   }
   return line;
}

_str longEmulationName (_str name=def_keys)
{
   switch (name) {
   case "slick-keys":
      return "SlickEdit";
   case "":
      return "SlickEdit";
   case "bbedit-keys":
      return "BBEdit";
   case "brief-keys":
      return "Brief";
   case "codewarrior-keys":
      return "CodeWarrior";
   case "codewright-keys":
      return "CodeWright";
   case "emacs-keys":
      return "Epsilon";
   case "gnuemacs-keys":
      return "GNU Emacs";
   case "ispf-keys":
      return "ISPF";
   case "vcpp-keys":
      return "Visual C++ 6";
   case "vi-keys":
      return "Vim";
   case "vsnet-keys":
      return "Visual Studio";
   case "cua-keys":
       return "CUA";
   case "windows-keys":
      return "CUA";
   case "macosx-keys":
      return "macOS";
   case "xcode-keys":
      return "Xcode";
   case "eclipse-keys":
      return "Eclipse";
   }
   return "";
}

_str shortEmulationName (_str name)
{
   switch (name) {
   case "SlickEdit":
      return "slick";
   case "BBEdit":
      return "bbedit";
   case "Brief":
      return "brief";
   case "CodeWarrior":
      return "codewarrior";
   case "CodeWright":
      return "codewright";
   case "Epsilon":
      return "emacs";
   case "GNU Emacs":
      return "gnuemacs";
   case "ISPF":
      return "ispf";
   case "Visual C++ 6":
      return "vcpp";
   case "Vim":
      return "vi";
   case "Visual Studio":
      return "vsnet";
   case "Windows":
   case "CUA":
      return "windows";
   case "macOS":
       return "macosx";
   case "Xcode":
      return "xcode";
   case "Eclipse":
      return "eclipse";
   }
   return "";
}

_str _getEmulation()
{
   // special cases
   if (def_keys == "") {
      return "SlickEdit (text mode edition)";
   }

   return longEmulationName(def_keys);
}

_str aboutEmulation(_str altCaption=null)
{
   _str line = _getEmulation();
   if( altCaption!=null ) {
      line=altCaption:+line;
   } else {
      line="<b>"get_message(VSRC_CAPTION_EMULATION)"</b>: "line;
   }
   return line;
}

/**
 * Retrieve the current project type, suitable for display.
 *
 * @param altCaption
 *
 * @return _str
 */
_str aboutProject(_str altCaption=null, bool protectCustom = false)
{
   line := "No project open";
   // do we have a project name?
   if (_project_name._length() > 0 || _fileProjectHandle()>0) {
      handle := _ProjectHandle();
      // do we have an open project?
      if (handle > 0) {
         // it might be visual studio?
         line = _ProjectGet_AssociatedFileType(handle);
         if (line == "") {
            // some projects will just tell you the type
            line = _ProjectGet_ActiveType();
            if (line == "") {
               // check for a template name attribute - these were added in v16, so
               // all projects will not have them
               line = _ProjectGet_TemplateName(handle);
               if (line != "" && protectCustom && _ProjectGet_IsCustomizedProjectType(handle)) {
                  line = "Customized";
               }

               if (line == "") {
                  // try one last thing...it's hokey!
                  line = determineProjectTypeFromTargets(handle);
                  if (line == "") {
                     line = "Other";
                  }
               }
            }
         }
         // capitalize the first letter of each word if there's a project open
         line = _cap_string(line);
         if (_project_name=="") {
            line="Single file project - "line;
         }
      }
   }

   if (altCaption!=null ) {
      line=altCaption:+line;
   } else {
      line="<b>"get_message(VSRC_CAPTION_CURRENT_PROJECT_TYPE)"</b>: "line;
   }
   return line;
}

/**
 * Try to determine the project type by examining the target commandlines.  This
 * will not always work, in the case that the user has changed them.
 *
 * @param handle           handle of project file
 *
 * @return _str            project type, blank if one could not be determined
 */
static _str determineProjectTypeFromTargets(int handle)
{
   // NAnt
   // shackett 7-27-10 (removed Ch checking because the criteria is too broad, too much
   // stuff was being falsely reported as Ch)
   node := _xmlcfg_find_simple(handle, "/Project/Config/Menu/Target/Exec/@CmdLine[contains(., 'ch', 'I')]");
   if (node > 0) {
      node = _xmlcfg_find_simple(handle, "/Project/Files/Folder/@Filters[contains(., '*.build', 'I')]");
      if (node > 0) {
         return "NAnt";
      }
   }

   // SAS
   node = _xmlcfg_find_simple(handle, "/Project/Config/Menu/Target/Exec/@CmdLine[contains(., 'sassubmit', 'I')]");
   if (node > 0) {
      return "SAS";
   }

   // Vera
   node = _xmlcfg_find_simple(handle, "/Project/Config/Menu/Target/Exec/@CmdLine[contains(., 'vera', 'I')]");
   if (node > 0) {
      return "Vera";
   }

   // Verilog
   node = _xmlcfg_find_simple(handle, "/Project/Config/Menu/Target/Exec/@CmdLine[contains(., 'vlog', 'I')]");
   if (node > 0) {
      return "Verilog";
   }

   // VHDL
   node = _xmlcfg_find_simple(handle, "/Project/Config/Menu/Target/Exec/@CmdLine[contains(., 'vcom', 'I')]");
   if (node > 0) {
      return "VHDL";
   }

   return "";
}

_str aboutLanguage(_str altCaption=null)
{
   // is there a file open?
   line := "";
   bufId := _mdi.p_child;
   if (bufId && !_no_child_windows()) {
      lang := _LangGetModeName(bufId.p_LangId);
      line = "."_get_extension(bufId.p_buf_name);
      if (lang != "") {
         line :+= " ("lang")";
      }
   } else {
      line = "No file open";
   }

   if( altCaption!=null ) {
      line=altCaption:+line;
   } else {
      line="<b>"get_message(VSRC_CAPTION_CURRENT_LANGUAGE)"</b>: "line;
   }
   return line;
}

_str aboutEncoding(_str altCaption=null)
{
   // is there a file open?
   line := "";
   bufId := _mdi.p_child;
   if (bufId && !_no_child_windows()) {
      if (bufId.p_encoding==VSCP_ACTIVE_CODEPAGE) {
         line='ACP ('_GetACP()')';
      } else {
         line = encodingToTitle(bufId.p_encoding);
      }
   } else {
      line = "No file open";
   }

   if( altCaption!=null ) {
      line=altCaption:+line;
   } else {
      line="<b>"get_message(VSRC_CAPTION_CURRENT_ENCODING)"</b>: "line;
   }
   return line;
}

#if 1 /* __UNIX__*/
   _str macGetOSVersion();
   _str macGetOSName();
   _str macGetProcessorArch();
#endif

_str _getOsName()
{
   osname := "";

   if (_isWindows()) {
      typeless MajorVersion, MinorVersion, BuildNumber, PlatformId, ProductType;
      _str CSDVersion;
      ntGetVersionEx(MajorVersion, MinorVersion, BuildNumber, PlatformId, CSDVersion, ProductType);
      if (length(MinorVersion) < 1) {
         MinorVersion = "0";
      }
      if (MajorVersion>=10) {
         if(MajorVersion==10 && MinorVersion==0) {
            osname = "Windows 10";
         } else {
            osname = "Windows 10 or Later";
         }
      } else if (PlatformId == 1) {
         bool IsWindows98orLater = (PlatformId == 1) &&
            ((MajorVersion > 4) ||
             ((MajorVersion == 4) && (MinorVersion > 0))
             );
         osname = "Windows 95";
         if (MajorVersion == "4" && MinorVersion == "90") {
            osname = "Windows ME";
         } else if (IsWindows98orLater) {
            osname = "Windows 98 or Later";
         }
      } else if (PlatformId == 2) {
         if (MajorVersion <= 4) {
            osname = "Windows NT";
         } else if (MajorVersion <= 5) {
            if (MinorVersion >= 2) {
               if (ProductType == 1) {
                  osname = "Windows XP";
               } else {
                  osname = "Windows Server 2003";
               }
            } else if (MinorVersion == 1) {
               osname = "Windows XP";
            } else {
               osname = "Windows 2000";
            }
         } else if (MajorVersion <= 6) {
            if (MinorVersion == 0) {
               if (ProductType == 1) {
                  osname = "Windows Vista";
               } else {
                  osname = "Windows Server 2008";
               }
            } else if (MinorVersion == 1) {
               if (ProductType == 1) {
                  osname = "Windows 7";
               } else {
                  osname = "Windows Server 2008 R2";
               }
            } else if (MinorVersion == 2) {
               if (ProductType == 1) {
                  osname = "Windows 8";
               } else {
                  osname = "Windows Server 2012";
               }
            } else {
               osname="Windows 8 or Later";
            }
         } else {
            osname = "Windows 8 or Later";
         }
      } else {
         osname = "Windows ("PlatformId")";
      }
      // add an indicator if this is 64 bit
      if (ntIs64Bit() != 0) {
         osname :+= " x64";
      }
   } else {
      UNAME info;
      _uname(info);
      osname = info.sysname;

      // get a little more specific for Solaris platforms
      if (machine() == "SPARCSOLARIS") {
         osname :+= " Sparc";
      } else if (machine() == "INTELSOLARIS") {
         osname :+= " Intel";
      } else if (_isMac()) {
         osname =  macGetOSName();
      }
   }

   return osname;
}

/**
 * Get processor and/or operating system architecture
 */
static _str _getArchitecture()
{
   architecture := "";
   if (_isUnix()) {
      if(_isMac()) {
         architecture = macGetProcessorArch();
      } else {
         UNAME info;
         _uname(info);
         architecture :+= info.cpumachine;
      }
   }
   return architecture;
}

/**
 * Get extra OS version information, such as the distro name and
 * version on Linux.
 *
 * @return _str OS version information
 */
static _str _getOsVersion()
{
   if (length(_os_version_name) > 0) {
      // Cached version name
      return _os_version_name;
   }

   if (_isMac()) {
      _os_version_name = macGetOSVersion();
      return _os_version_name;
   }

   osver := "Unknown";

   // Try lsb_release command first (for LSB-compliant Linux distro)
   _str com_name = path_search("lsb_release");
   if (com_name != "" && _getOsVersionLSB(osver)) {
      // New version name.  Cache it.
      _os_version_name = osver;
      return osver;
   }

   // Try "/etc/issue" next.
   if (_getOsVersionUnix(osver)) {
      _os_version_name = osver;
      return osver;
   }

   return osver;
}

/**
 * Get just the first line from file specified.  In case the
 * first line is empty, keep going down until the last line is
 * reached.
 *
 * @param filename full path of file to open
 * @param line first line
 *
 * @return bool true on success, false otherwise.
 */
static bool _getFirstLineFromFile(_str filename, _str &line)
{
   // open the file in a temp view
   temp_view_id := 0;
   orig_view_id := 0;
   int status = _open_temp_view(filename, temp_view_id, orig_view_id);
   if (status) {
      return false;
   }

   top();
   do {
      get_line_raw(line);
      line = strip(line);
      if (line != "") {
         break;
      }
   } while (down() != BOTTOM_OF_FILE_RC);

   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   if (line == "") {
      return false;
   }
   return true;
}

/**
 * Get the OS version string from /etc/issue.  This may be used
 * on older Linux distros, or UNIX platforms where command
 * 'lsb_release' is not available.
 *
 * @param osver (reference) OS version name
 *
 * @return bool true on success, false otherwise
 */
static bool _getOsVersionUnix(_str& osver)
{
   issue_file := "";
   if (!_getFirstLineFromFile("/etc/issue", issue_file)) {
      return false;
   }
   osver = "";
   // First, read everything up to the first backslash (\).
   if (pos('{[~\\]#}', issue_file, 1, 'R') == 0) {
      return false;
   }
   osver = strip(substr(issue_file, pos('S0'), pos('0')));

   // In case the string starts with 'Welcome to', strip it.
   if (pos("Welcome to", osver, 1, 'I') == 1) {
      osver = strip(substr(osver, length("Welcome to")+1));
   }
   return true;
}

/**
 * Determine the distribution name and version for Linux. On
 * LSB-compliant Linux distro, it is determined from the system
 * command 'lsb_release -d'.  This command produces one-line
 * string of the format:
 * <pre>
 *   'Description: <disto name and version>'
 * </pre>
 *
 * @param osver (reference) OS version name
 *
 * @return bool true if successful, false otherwise.
 */
static bool _getOsVersionLSB(_str& osver)
{
   _str com_name = path_search("lsb_release");
   if (com_name == "") {
      // Command not available.
      return false;
   }
   com_name :+= " -d";

   int hstdout, hstderr, hstdin;
   int phandle = _PipeProcess(com_name, hstdin, hstdout, hstderr, '');
   if (phandle < 0) {
      // Pipe process failed.
      return false;
   }

   _str buf;
   int start_time = (int)_time('G');
   while (!_PipeIsReadable(hstdin)) {
      int cur_time = (int)_time('G');
      if (cur_time - start_time >= 5) {
         // Wait for stdout pipe up to 5 seconds to avoid infinite loop.
         return false;
      }
   }
   if (_PipeRead(hstdin, buf, 100, 0) < 0) {
      // Pipe read failed.
      return false;
   }
   _PipeCloseProcess(phandle);
   if (buf == "") {
      return false;
   }

   // Now I have the output string from 'lsb_release -d'.
   // Get the substring that is the name of distro.
   //   format: 'Description:   SUSE Linux 10.1...'
   buf = strip(buf, 'T', "\n");
   if (pos("Description\\:[ \t]#{?#}", buf, 1, "R") == 0) {
      return false;
   }
   buf = substr(buf, pos('S0'), pos('0'));
   osver = buf;
   return true;
}

_str aboutOsName(_str altCaption=null)
{
   line := _getOsName();
   if( altCaption!=null ) {
      line=altCaption:+line;
   } else {
      line="<b>"get_message(VSRC_CAPTION_OPERATING_SYSTEM)"</b>: "line;
   }
   return line;
}

_str aboutInstallationDirectory(_str altCaption=null)
{
   line := "";

   install_dir := "";
   caption := "";
   if( altCaption!=null ) {
      caption=altCaption;
   } else {
      caption=get_message(VSRC_CAPTION_INSTALLATION_DIRECTORY);
   }
   appendDiskInfo(install_dir,_getSlickEditInstallPath(),caption);

   line=install_dir;

   return line;
}

_str aboutConfigurationDirectory(_str altDirectoryCaption=null, _str altUsageCaption=null)
{
   line := "";

   config_info := "";
   dir_caption := "";
   if( altDirectoryCaption!=null ) {
      dir_caption=altDirectoryCaption;
   } else {
      dir_caption=get_message(VSRC_CAPTION_CONFIGURATION_DIRECTORY);
   }
   usage_caption := "";
   if( altUsageCaption!=null ) {
      usage_caption=altUsageCaption;
   } else {
      usage_caption=get_message(VSRC_CAPTION_CONFIGURATION_DRIVE_USAGE);
   }
   appendDiskInfo(config_info,_ConfigPath(),dir_caption,usage_caption);

   line=config_info;

   return line;
}

_str aboutMigratedConfigurationDirectory(_str altCaption=null)
{
   line := "";
   if (def_config_transfered_from_dir != "") {

      dirCaption := "";
      if (altCaption != null) {
         dirCaption=altCaption;
      } else {
         dirCaption=get_message(VSRC_CAPTION_MIGRATED_CONFIG);
      }

      line="<b>"dirCaption"</b>:  "def_config_transfered_from_dir;
   }

   return line;
}

_str aboutSpillFileDirectory(_str altDirectoryCaption=null, _str altUsageCaption=null)
{
   line := "";

   spill_info := "";
   if( _SpillFilename()!="" ) {
      // Spill File: C:\DOCUME~1\joesmith\LOCALS~1\Temp\$slk.1 (non-removable drive,FAT32)
      // Spill File Directory Drive Usage: 31446MB / 36860MB
      dir_caption := "";
      if( altDirectoryCaption!=null ) {
         dir_caption=altDirectoryCaption;
      } else {
         dir_caption=get_message(VSRC_CAPTION_SPILL_FILE);
      }
      usage_caption := "";
      if( altUsageCaption!=null ) {
         usage_caption=altUsageCaption;
      } else {
         usage_caption=get_message(VSRC_CAPTION_SPILL_FILE_DIRECTORY_DRIVE_USAGE);
      }
      appendDiskInfo(spill_info,_SpillFilename(),dir_caption,usage_caption);
   }

   line=spill_info;

   return line;
}

_str aboutDiskInfo()
{
   line := "";

   line=line                        :+
      aboutInstallationDirectory()  :+
      "\n"                          :+
      aboutConfigurationDirectory();

   _str mig_cfg_line = aboutMigratedConfigurationDirectory();
   if( mig_cfg_line!="" ) {
      line=line                     :+
         "\n"                       :+
         mig_cfg_line;
   }

   _str spill_line = aboutSpillFileDirectory();
   if( spill_line!="" ) {
      line=line                     :+
         "\n"                       :+
         spill_line;
   }

   return line;
}

const DISPLAYMANAGER_FILE='/etc/X11/default-display-manager';
const DISPLAYMANAGER_UNIT='/etc/systemd/system/display-manager.service';

static _str x11WindowManager()
{
   ds := '';
   show_output := false;
   // Look and see if window manager atom is set.
   rc := exec_command_to_temp_view('xprop -root -notype', auto tempView, auto origView, -1, 0, show_output);
   if (rc == 0) {
      top();
      rc = search('^_NET_SUPPORTING_WM_CHECK: window id # ([A-Fa-f0-9x]+)', '@L');
      wid := '';
      if (rc == 0) {
         wid = get_text(match_length('1'), match_length('S1'));
      }
      p_window_id = origView;
      _delete_temp_view(tempView);
      if (rc == 0) {
         rc = exec_command_to_temp_view('xprop -id 'wid' _NET_WM_NAME', tempView, origView, -1, 0, show_output);
         if (rc == 0) {
            top();
            rc = search('^[^=]+= "([^"]+)"', '@L');
            if (rc == 0) {
               ds = get_text(match_length('1'), match_length('S1'));
            }
            p_window_id = origView;
            _delete_temp_view(tempView);
         }
      }
   }

   if (ds == '') {
      // Maybe not always what we want, but good enough usually if it is available.
      ds = get_env('XDG_SESSION_DESKTOP');
   }

   if (ds == '') {
      ds = 'Unknown';
   }
   gX11WindowManager = ds;

   rv := '<b>Window Manager</b>: 'ds;

   dm := '';
   if (file_exists(DISPLAYMANAGER_FILE)) {
      rc = exec_command_to_temp_view('cat 'DISPLAYMANAGER_FILE, tempView, origView, -1, 0, show_output);
      if (rc == 0) {
         p_line = 1;
         get_line(dm);
         p_window_id = origView;
         _delete_temp_view(tempView);
      }
   }  else if (file_exists(DISPLAYMANAGER_UNIT)) {
      rc = exec_command_to_temp_view('grep ExecStart= 'DISPLAYMANAGER_UNIT, tempView, origView, -1, 0, show_output);
      if (rc == 0) {
         p_line = 1;
         get_line(dm);
         epos := pos('=', dm);
         if (epos > 0) {
            dm = substr(dm, epos+1);
         }
      }
   } else {
      rc = 0;
      dm = 'Unknown';
   }

   if (dm == '') {
      dm = 'Unknown';
   }
   rv :+= "\n<b>Display manager</b>: "dm;

   return rv"\n";
}

_str getX11WindowManager()
{
   if (gX11WindowManager == "") {
       x11WindowManager();
   }

   return gX11WindowManager;
}

bool wmNeedsModalWorkaround()
{
   wm := getX11WindowManager();
   rv := wm ==  "Openbox";
   //say('workaround='rv', wm='wm);
   return rv;
}

_str aboutOsInfo(_str altCaption=null)
{
   line := "";

   osinfo := "";
   if (_isWindows()) {
      // OS: Windows XP
      // Version: 5.01.2600  Service Pack 1
      typeless MajorVersion,MinorVersion,BuildNumber,PlatformId,ProductType;
      _str CSDVersion;
      ntGetVersionEx(MajorVersion,MinorVersion,BuildNumber,PlatformId,CSDVersion,ProductType);
      if( length(MinorVersion)<1 ) {
         MinorVersion="0";
      }
      // Pretty-up the minor version number for display
      if( length(MinorVersion)<2 ) {
         MinorVersion="0"MinorVersion;
      }
      osinfo :+= "<b>"get_message(VSRC_CAPTION_OPERATING_SYSTEM)"</b>:  "_getOsName();
      osinfo :+= "\n";
      osinfo :+= "<b>"get_message(VSRC_CAPTION_OPERATING_SYSTEM_VERSION)"</b>:  "MajorVersion"."MinorVersion"."BuildNumber"&nbsp;&nbsp;"CSDVersion;
   } else {
      // OS: SunOS
      // Kernel Level: 5.7
      // Build Version: Generic_106541-31
      // X Server Vendor: Hummingbird Communications Ltd.
      UNAME info;
      _uname(info);
      osinfo :+= "<b>"get_message(VSRC_CAPTION_OPERATING_SYSTEM)"</b>: "_getOsName();
      osinfo :+= "\n";
      if (_isLinux() || _isMac()) {
         osinfo :+= "<b>"get_message(VSRC_CAPTION_OPERATING_SYSTEM_VERSION)"</b>: "_getOsVersion();
         osinfo :+= "\n";
      }

      if (_isMac() == false) {
         osinfo :+= "<b>"get_message(VSRC_CAPTION_KERNEL_LEVEL)"</b>: "info.release;
         osinfo :+= "\n";
         osinfo :+= "<b>"get_message(VSRC_CAPTION_BUILD_VERSION)"</b>: "info.version;
         osinfo :+= "\n";
      }
      // Display processor architecture
      osinfo :+= "<b>"get_message(VSRC_CAPTION_PROCESSOR_ARCH)"</b>: "_getArchitecture();
      osinfo :+= "\n";

      // Display X server details
      if (_isMac() == false) {
         osinfo :+= "\n";
         osinfo :+= "<b>"get_message(VSRC_CAPTION_XSERVER_VENDOR)"</b>: "_XServerVendor();
         osinfo :+= "\n"x11WindowManager();
      }
   }

   line=osinfo;
   if( altCaption!=null ) {
      line=altCaption:+line;
   }

   return line;
}

/**
 * Get the total amount of virtual memory on the current machine
 * and the amount of available memory.
 *
 * @param TotalVirtual   (k) virtual address size
 * @param AvailVirtual   (k) free virtual address size
 *
 * @return 0 on success, <0 on error
 */
int _VirtualMemoryInfo(long &TotalVirtual, long &AvailVirtual)
{
   // initialize results
   TotalVirtual = AvailVirtual = 0;

   if (_isUnix()) {
      if (_isMac()) {
         //TotalVirtual=8388608;
         //AvailVirtual=8388608;
         _MacGetMemoryInfo(TotalVirtual, AvailVirtual);
         return 0;
      }
      // find the vmstat program
      vmstat_name := "vmstat";
      if (file_exists("/usr/bin/vmstat")) {
         vmstat_name = "/usr/bin/vmstat";
      } else if (file_exists("/usr/bin/vm_stat")) {
         vmstat_name = "/usr/bin/vm_stat"; // psycho mac
      } else {
         vmstat_name = path_search(vmstat_name);
         if (vmstat_name == "") {
            return FILE_NOT_FOUND_RC;
         }
      }

      // shell out the command and get the result
      vmstat_status := 0;
      vmstat_info := _PipeShellResult(vmstat_name, vmstat_status);
      if (vmstat_status) {
         return vmstat_status;
      }

      // split the result into lines
      split(vmstat_info, "\n", auto vmstat_lines);

      if (_isMac() && vmstat_lines._length() >= 5) {
         // get the number of bytes per page
         numBytesPerPage := 4096;
         parse vmstat_lines[0] with . "page size of" auto numBytesStr "bytes";
         numBytesStr = strip(numBytesStr);
         if (isuinteger(numBytesStr)) {
            numBytesPerPage = (int) numBytesStr;
         }

         parse vmstat_lines[1] with . " free:"       auto pagesFreeStr     ".";
         parse vmstat_lines[2] with . " active:"     auto pagesActiveStr   ".";
         parse vmstat_lines[3] with . " inactive:"   auto pagesInactiveStr ".";
         parse vmstat_lines[4] with . " wired down:" auto pagesWiredDownStr ".";
         if (pagesWiredDownStr=="") {
            // Speculate data is messing this up. Try next line
            parse vmstat_lines[5] with . " wired down:" pagesWiredDownStr ".";
         }

         pagesFreeStr = strip(pagesFreeStr);
         pagesActiveStr = strip(pagesActiveStr);
         pagesInactiveStr = strip(pagesInactiveStr);
         pagesWiredDownStr = strip(pagesWiredDownStr);

         // get the totals
         if (isuinteger(pagesFreeStr)) {
            TotalVirtual = AvailVirtual = (int) pagesFreeStr;
         }
         if (isuinteger(pagesActiveStr)) {
            TotalVirtual += (int) pagesActiveStr;
         }
         if (isuinteger(pagesInactiveStr)) {
            TotalVirtual += (int) pagesInactiveStr;
         }
         if (isuinteger(pagesWiredDownStr)) {
            TotalVirtual += (int) pagesWiredDownStr;
         }

         // adjust totals to block size
         AvailVirtual = AvailVirtual * (numBytesPerPage intdiv 1024);
         TotalVirtual = TotalVirtual * (numBytesPerPage intdiv 1024);

      } else {

         // scan for the line containing the field names, then get data
         _str vmstat_fields[];
         _str vmstat_data[];
         gotFree := false;
         foreach (auto line in vmstat_lines) {
            line = stranslate(line," ","\t");
            line = stranslate(line," "," #","r");
            line = strip(line);
            if (pos(" free ", line) > 0 || pos(" fre ", line) > 0) {
               gotFree = true;
               split(line, " ", vmstat_fields);
            }
            if (gotFree && isnumber(_first_char(line))) {
               split(line, " ", vmstat_data);
               break;
            }
         }

         // get the data from the columns for free and swap space
         for (i:=0; i<vmstat_fields._length(); i++) {
            if (i >= vmstat_data._length()) break;
            switch (vmstat_fields[i]) {
            case "free":
            case "fre":
               if (isuinteger(vmstat_data[i])) {
                  AvailVirtual = (long) vmstat_data[i];
                  TotalVirtual += AvailVirtual;
               }
               break;
            case "avm":
            case "buff": // Linux specific
               if (isuinteger(vmstat_data[i])) {
                  TotalVirtual += (long) vmstat_data[i];
               }
               break;
            case "swpd":
            case "swap":
               if (isuinteger(vmstat_data[i])) {
                  TotalVirtual += (long) vmstat_data[i];
               }
               break;
            case "cache": // Linux specific comes after 'buff'
               if (isuinteger(vmstat_data[i])) {
                  TotalVirtual += (long) vmstat_data[i];
               }
            }
         }

         // block size reported by AIX and HPUX is 4k, not 1k
         if (machine() == "RS6000" || machine() == "HP9000") {
            TotalVirtual *= 4;
            AvailVirtual *= 4;
         }
      }
   } else {

      index := find_index("ntGlobalMemoryStatus", PROC_TYPE|DLLCALL_TYPE);
      if (index_callable(index)) {
         long MemoryLoadPercent, TotalPhys, AvailPhys, TotalPageFile, AvailPageFile;
         ntGlobalMemoryStatus(MemoryLoadPercent,TotalPhys,AvailPhys,TotalPageFile,AvailPageFile,TotalVirtual,AvailVirtual);
         if (AvailPhys < AvailVirtual) AvailVirtual = AvailPhys;
         if (TotalPhys > TotalVirtual) TotalVirtual = TotalPhys;
      }

   }

   // success?
   if (TotalVirtual > 0) {
      return 0;
   }

   // did not find what we needed
   return -1;
}
#if 0
_str aboutPluginsInfo() {
   _str plugins[];
   _plgman_get_installed_plugins(plugins);
   result := "";
   for (i:=0;i<plugins._length();++i) {
      if (result=='') {
         result=maybe_quote_filename(plugins[i]);
      } else {
         strappend(result,',');
         strappend(result,maybe_quote_filename(plugins[i]));
      }
   }
   if (result!='') {
       result="<b>"get_message(VSRC_CAPTION_PLUGINS)":  </b>" :+ result;
   }
   return result;
}
#endif

_str aboutMemoryInfo(_str altCaption=null)
{
   line := "";
   memory := "";
   if (_isWindows()) {
      // Memory Load: %39
      // Physical Memory Usage: 413MB / 1048MB
      // Page File Usage: 339MB / 2521MB
      // Virtual Memory Usage: 107MB / 2097MB
      long MemoryLoadPercent, TotalPhys, AvailPhys, TotalPageFile, AvailPageFile, TotalVirtual, AvailVirtual;
      ntGlobalMemoryStatus(MemoryLoadPercent,TotalPhys,AvailPhys,TotalPageFile,AvailPageFile,TotalVirtual,AvailVirtual);
      memory :+= MemoryLoadPercent"%";
      memory :+= " "get_message(VSRC_CAPTION_MEMORY_LOAD);
      memory :+= ", ";
      memory :+= MBRound(TotalPhys-AvailPhys)"/"MBRound(TotalPhys);
      memory :+= " "get_message(VSRC_CAPTION_PHYSICAL_MEMORY_USAGE);
      memory :+= ", ";
      memory :+= MBRound(TotalPageFile-AvailPageFile)"/"MBRound(TotalPageFile);
      memory :+= " "get_message(VSRC_CAPTION_PAGE_FILE_USAGE);
      memory :+= ", ";
      memory :+= MBRound(TotalVirtual-AvailVirtual)"/"MBRound(TotalVirtual);
      memory :+= " "get_message(VSRC_CAPTION_VIRTUAL_MEMORY_USAGE);
   } else {
      long TotalVirtual=0, AvailVirtual=0;
      if (!_VirtualMemoryInfo(TotalVirtual, AvailVirtual)) {
         if(TotalVirtual > 0 && AvailVirtual > 0) {
             MemoryLoadPercent := 100 * (TotalVirtual - AvailVirtual) intdiv TotalVirtual;
             memory :+= MemoryLoadPercent"%";
             memory :+= " "get_message(VSRC_CAPTION_MEMORY_LOAD);
             memory :+= ", ";
             // report virtual memory statistics
             memory :+= MBRound(TotalVirtual-AvailVirtual)"/"MBRound(TotalVirtual);
             memory :+= " "get_message(VSRC_CAPTION_VIRTUAL_MEMORY_USAGE);
         }
      }
   }

   if (memory != "") {
      line=memory;
      if( altCaption!=null ) {
         line=altCaption:+memory;
      } else {
         line="<b>"get_message(VSRC_CAPTION_MEMORY)":  </b>" :+ memory;
      }
   }

   return line;
}

_str aboutShellInfo(_str altCaption=null)
{
   line := _get_process_shell(true);
   if (line != "") {
      if( altCaption!=null ) {
         line=altCaption:+line;
      } else {
         line="<b>"get_message(VSRC_CAPTION_SHELL_INFO)"</b>: "line;
      }
   }
   return line;
}

_str aboutScreenResolutionInfo(_str altCaption = null)
{
   _ScreenInfo list[];
   _GetAllScreens(list);

   line := "";
   for (i := 0; i < list._length(); i++) {
      if (line != "") {
         line :+= ", ";
      }
      if (_isWindows() && list[i].actual_width) {
         line :+= list[i].actual_width" x "list[i].actual_height' ('list[i].x' 'list[i].y' 'list[i].width' 'list[i].height')';
      } else {
         line :+= list[i].width" x "list[i].height;
      }
   }

   if( altCaption!=null ) {
      line=altCaption:+line;
   } else {
      line="<b>"get_message(VSRC_CAPTION_SCREEN_RESOLUTION)"</b>: "line;
   }
   return line;
}

_str aboutEclipseInfo(_str altCaption=null)
{
   line := "";

   eclipse_info := "";
   if( isEclipsePlugin() ) {
      eclipse_version := "";
      jdt_version := "";
      cdt_version := "";
      _eclipse_get_eclipse_version_string(eclipse_version);
      _eclipse_get_jdt_version_string(jdt_version);
      _eclipse_get_cdt_version_string(cdt_version);
      eclipse_info :+= "<b>Eclipse: </b> ":+eclipse_version;
      eclipse_info :+= "\n";
      eclipse_info :+= "<b>JDT: </b> ":+jdt_version;
      eclipse_info :+= "\n";
      eclipse_info :+= "<b>CDT: </b> ":+cdt_version;
   }

   line=eclipse_info;
   if( line!="" && altCaption!=null ) {
      line=altCaption:+line;
   }

   return line;
}

static _str aboutContactInfo()
{
   vsroot := _getSlickEditInstallPath();
   _maybe_append_filesep(vsroot);
   contact_file := vsroot:+"contact.html";
   contact_text := "";
   _GetFileContents(contact_file, contact_text);

   // remove notes about support and maintenance
   if (_isCommunityEdition()) {
      return stranslate(contact_text, "", "[<]li[>][^\n\r]*(Support|Maintenance)[^\n\r]*[<][/]li[>]", 'r');
   }
   return contact_text;
}

/**
 * Displays version of editor in message box.
 *
 * <p>
 * Note to OEMs: You can override the version()
 * command in order to display your own custom
 * About dialog box. Do NOT override the vsversion()
 * command, which is the default About dialog, because
 * you may need its information to debug problems.
 * </p>
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void version() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   vsversion();
}

//
// DO NOT ALLOW AN OEM TO OVERRIDE THIS FUNCTION!
//
// OEMs can override the version() command in order to replace
// our About dialog. Keep vsversion() safe because it may display
// more information than the OEM version displays, and will therefore
// be useful in a debugging situation.
_command void vsversion(_str options="", bool doModal = false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   //
   // Product name, version, copyright
   //

   // SlickEdit Version 10.0
   _str product = aboutProduct(true);
   product = "<b>"product"</b>";
   // Copyright 1988-2005 SlickEdit Inc.
   _str copyright = aboutCopyright();
   // Check for not-for-resale version
   not_for_resale := "";
   if( _NotForResale() ) {
      not_for_resale="<b>NOT FOR RESALE</b>";
   }

   //
   // License
   //

   // Serial number: WB0123456789
   _str serial = aboutSerial();

   // Licensed number of users: 5
   _str nofusers = aboutLicensedNofusers();

   // Licensed number of users: 5
   _str licenseExpiration = aboutLicensedExpiration();

   _str licenseFile = aboutLicensedFile();
   _str unlicensedFeatures = aboutUnlicensedFeatures();
   _str unlicensedLanguages = aboutUnlicensedLanguages();

   //_str licensedTo=aboutLicensedTo();

   // Licensed packages:
   //
   // PKGA
   //_str basePackNofusers = "";
   //_str licensedPacks = aboutInstalledPackages(basePackNofusers);
   //if( basePackNofusers!="" ) {
   //   // Append nofusers for the base package license to the serial number.
   //   // Although not part of the serial number, it makes it easier for a
   //   // user to report the number of users in a concurrent license if we
   //   // put it with the serial number.
   //   _str raw_serial = _getSerial();
   //   serial=stranslate(serial,raw_serial"-"basePackNofusers,raw_serial);
   //}

   //
   // Build date
   //

   _str build_date = aboutProductBuildDate();
   _str expiration = aboutExpirationDate();


   //
   // Emulation
   //

   // Emulation: CUA
   _str emulation = aboutEmulation();

   //
   // Project and language info
   //
   _str projInfo = aboutProject();
   _str langInfo = aboutLanguage();
   _str encInfo = aboutEncoding();

   //
   // Disk usage info
   //

   // Installation Directory: C:\slickedit\ (non-removable drive,FAT32)
   // Configuration Directory: c:\My Documents\joesmith\My SlickEdit Config\ (non-removable drive,FAT32)
   // Configuration Drive Usage: 28632MB / 32748MB
   _str diskinfo = aboutDiskInfo();


   //
   // Memory usage info
   //
   _str memoryinfo = aboutMemoryInfo();

   //
   // Shell used in build window
   //
   _str shellInfo = aboutShellInfo();

   //
   // Screen resolution info
   //
   _str screeninfo = aboutScreenResolutionInfo();

   // System info
   //

   // OS: Windows XP
   // Version: 5.01.2600  Service Pack 1
   //
   // --or--
   //
   // OS: SunOS
   // Kernel Level: 5.7
   // Build Version: Generic_106541-31
   // X Server Vendor: Hummingbird Communications Ltd.
   _str osinfo = aboutOsInfo();


   //
   // Eclipse plug-in only
   //

   // Eclipse: 3.0.0
   // JDT: 3.0.0
   // CDT: 2.0.0
   _str eclipse_info = aboutEclipseInfo();

   _str hotfix_info = aboutHotfixesList();

   // Put it all together
   text := "";
   text = text            :+
      product;
   if( not_for_resale != "" ) {
      text = text         :+
      "\n\n"              :+  // (blank line)
      not_for_resale;         // NOT FOR RESALE
   }
   if( serial != "" && (!isEclipsePlugin() || !_OEM())) {
      text = text         :+
         "\n";              // (blank line)
      text = text         :+
         "\n"             :+
         serial;         // Serial number: WB0123456789
   }
// if( licensedTo != "" ) {
//    text = text         :+
//       "\n"             :+
//       licensedTo;       // Licensed to: ...
// }
   if( nofusers != "" && (!isEclipsePlugin() || !_OEM())) {
      text = text         :+
         "\n"             :+
         nofusers;       // Number of licensed users: 5
   }
   if (licenseExpiration!="") {
      text = text         :+
         "\n"             :+
         licenseExpiration;     // License expiration: 15/1/2008
   }
   if (licenseFile!="") {
      text = text         :+
         "\n"             :+
         licenseFile;     // License file: c:\...\slickedit.lic
   }
   if (unlicensedFeatures!="") {
      text = text         :+
         "\n"             :+
         unlicensedFeatures;     // License file: c:\...\slickedit.lic
   }
   if (unlicensedLanguages!="") {
      text = text         :+
         "\n"             :+
         unlicensedLanguages;     // License file: c:\...\slickedit.lic
   }
   if( build_date != "" || expiration != "" || emulation != "" ) {
      text = text         :+
         "\n";              // (blank line)
      if( build_date != "" ) {
         text = text      :+
            "\n"          :+
            build_date;      // Build Date: June 30, 2004
      }
      if( expiration != "" ) {
         text = text      :+
            "\n"          :+
            expiration;      // Build Date: June 30, 2004
      }
      if( emulation != "" ) {
         text = text      :+
            "\n"          :+
            emulation;      // Emulation: CUA
      }
   }
   if( eclipse_info != "" ) {
      text = text         :+
      "\n\n"              :+
      eclipse_info;         // Eclipse: 3.0.0
                            // JDT: 3.0.0
                            // CDT: 2.0.0
   }
   if( osinfo != "" ) {
      text = text         :+
         "\n\n"           :+  // (blank line)
         osinfo;            // OS: Windows XP
                            // Version: 5.01.2600  Service Pack 1
   }
   if( memoryinfo != "" ) {
      text :+= "\n"  :+
               memoryinfo;  // Memory: 74% Load, 1554MB/2095MB Physical, 204MB/2097MB Virtual
   }

   if ( shellInfo != "" ) {
      text :+= "\n" :+
               shellInfo;
   }

   if ( screeninfo != "" ) {
      text :+= "\n" :+ screeninfo;
   }

   if (projInfo != "") {
      text :+= "\n\n"projInfo;
   }
   if (langInfo != "") {
      text :+= "\n"langInfo;
   }
   if (encInfo != "") {
      text :+= "\n"encInfo;
   }

   if( diskinfo != "" ) {
      text = text         :+
         "\n\n"           :+  // (blank line)
         diskinfo;          // Installation Directory: C:\vslick\ (non-removable drive,FAT32)
                            // Configuration Directory: c:\My Documents\joesmith\My SlickEdit Config\ (non-removable drive,FAT32)
                            // Configuration Drive Usage: 28632MB / 32748MB
                            // Spill File: C:\DOCUME~1\joesmith\LOCALS~1\Temp\$slk.1 (non-removable drive,FAT32)
                            // Spill File Directory Drive Usage: 31446MB / 36860MB
   }
   if( hotfix_info != "" ) {
      text = text         :+
         "\n\n"           :+  // (blank line)
         hotfix_info;
   }

   text :+= "\n\n";

   // Convert to HTML for the dialog
   text = stranslate(text,"<br>","\n");

   // Need to show Eclipse About dialog modal because it Slick-C stacks if you press the X
   // RGH - 5/15/2006
   // This dialog is now modal all the time (display the readme tab first if it's a first time startup)
   showCmdline := "";
   if( isEclipsePlugin() || doModal ) {
      showCmdline = "-modal _program_info_form";
   } else{
      showCmdline = "-xy _program_info_form";
   }
   show(showCmdline,text,"",-1,-1,options);
}

void _GetScreenInfo(int startX, int startY, _ScreenInfo &info)
{
   int screenX, screenY, screenW, screenH;
   _GetScreenFromPoint(startX, startY, screenX, screenY, screenW, screenH);

   info.x = screenX;
   info.y = screenY;
   info.width = screenW;
   info.height = screenH;
}

/**
 * Capitalizes the first character of the current word and places the cursor after
 * the current word.
 *
 * @return  0 if successful.  Returns 1 if no word exists at cursor.  On error, message is displayed.
 *
 * @see lowcase_word
 * @see upcase_word
 * @see camelcase_to_undescore
 * @see undescore_to_camelcase
 * @see toggle_camelcase
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command cap_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   start_col := 0;
   _str word=cur_word(start_col,def_from_cursor,false,def_word_continue);
   if (word=="") {
      retrieve_command_results();
      message(nls("No word at cursor"));
      return(1);
   }
   p_col=_text_colc(start_col,'I');
   _delete_text(_rawLength(word));
   _insert_text(_cap_word(word));
   retrieve_command_results();
   return(0);

}

/**
 * Move the cursor to the beginning of the identifier under the
 * cursor.  Does not move the cursor if there is no identifier under
 * the cursor, and returns "" in that case.
 *
 * @return  Returns the current identifier.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str _begin_identifier()
{
   id := cur_identifier(auto start_col);
   if (id != "") {
      p_col = start_col;
   }
   return id;
}
/**
 * Move the cursor to the last character of the identifier under the
 * cursor. Does not move the cursor if there is no identifier under
 * the cursor, and returns "" in that case.
 *
 * @return  Returns the current identifier.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str _end_identifier()
{
   id := cur_identifier(auto start_col);
   if (id != "") {
      p_col = start_col + length(id) - 1;
   }
   return id;
}

/**
 * If cursor is sitting on a valid identifier character
 * {@link p_identifier_chars}, the current word is
 * returned. Otherwise "" is returned.
 */
_str _SymbolWord()
{
   return cur_identifier(auto start_col=0);
}
/**
 * Returns the current identifier.
 * "" is returned if there is no identifier at the cursor.
 * <i>start_col</i> is set to the physical position within the current
 * line of the word returned.
 *
 * @param start_col        (output) start column for identifier.
 *                         The start column is returned as imaginary
 *                         columns, not physical columns.
 * @param option           one of the following: <ul>
 *    <li>VSCURWORD_WHOLE_WORD - get the entire identifier
 *    <li>VSCURWORD_FROM_CURSOR - get part of identifier before cursor
 *    <li>VSCURWORD_BEFORE_CURSOR - get part of identifier after cursor
 *    <li>VSCURWORD_AT_END_USE_PREV - not supported
 * </ul>
 *
 * @return  Returns the current word.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str cur_identifier(int &start_col, int option=VSCURWORD_WHOLE_WORD)
{
   // make sure we are on a character boundary
   if (!_StartOfDBCSCol(p_col)) {
      return("");
   }

   // check if the curent character is any identifier char
   id_chars := _clex_identifier_chars();
   this_ch := get_text();
   left_ch := get_text_left();
   if (!pos('['id_chars']',this_ch,1,'r') &&
       !pos('['id_chars']',left_ch,1,'r')) {
      return("");
   }

   // save original cursor position and column
   save_pos(auto p);
   orig_col  := p_col;
   orig_line := p_line;

   // search backwards to a non-identifier character
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   common_re := '([~\od'id_chars']|^)['id_chars']';
   status := search(common_re,'@rh-');
   if (status < 0) {
      restore_search(s1, s2, s3, s4, s5);
      restore_pos(p);
      return "";
   }

   // search for the real beginning of the identifier
   word_re   := _clex_identifier_re();
   status = search(word_re,'@rh');
   if ( status < 0 ) {
      restore_search(s1, s2, s3, s4, s5);
      restore_pos(p);
      return "";
   }

   // verify that we did not entirely miss the identifier
   if (p_col > orig_col || p_line != orig_line) {
      restore_search(s1, s2, s3, s4, s5);
      restore_pos(p);
      return "";
   }

   // save the start column, then search for end of identifier
   if (option==VSCURWORD_FROM_CURSOR) restore_pos(p);
   start_col = p_col;
   status = search('[~\od'id_chars']|$','@rh');
   if ( status < 0 ) {
      _end_line();
   }

   // verify that we did not entirely miss the identifier
   if (p_col < orig_col) {
      restore_search(s1, s2, s3, s4, s5);
      restore_pos(p);
      return "";
   }

   // get the word and restore position
   if (option==VSCURWORD_BEFORE_CURSOR) restore_pos(p);
   word := _expand_tabsc(start_col,p_col-start_col);
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
   return(word);
}

/**
 * Returns the current word.  If <i>from_cursor</i>=="1", word is
 * extracted starting at the cursor position instead of the beginning of
 * the word.  "" is returned if there is no word at the cursor.
 * <i>start_col</i> is set to the physical position within the current
 * line of the word returned.
 *
 * @param start_col    (Output only) Set to the physical column
 *                     start of the word.
 * @param from_cursor   When =="1", gets word starting from
 *                      cursor location instead of beginning of
 *                      word.
 * @param end_prev_word  When from_cursor!="1" and
 *                       end_prev_word==true, use previous word
 *                       when at end of line.
 * @param multi_line
 *
 * @return  Returns the current word.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str cur_word(int &start_col,_str from_cursor="",bool end_prev_word=false,bool multi_line=false)
{
   /*
      end_prev_word effects the following case.

          word1<cursor here>  word2

       By default, word2 is returned,  if end_prev_word==1 then word1 is returned.
   */
   int option=VSCURWORD_WHOLE_WORD;
   if( from_cursor!="1") {
      if (end_prev_word==1) {
         option=VSCURWORD_AT_END_USE_PREV;
      } else {
         if (from_cursor==VSCURWORD_BEFORE_CURSOR) {
            option=VSCURWORD_BEFORE_CURSOR;
         } else {
            option=VSCURWORD_FROM_CURSOR;
         }
      }
   }
   _str word=cur_word2(start_col,option,multi_line,true);
   if (word!="") {
      start_col=_text_colc(start_col,'P');
   }
   return(word);
}
static int find_cur_word(typeless p,_str common_re,_str word_chars) {
   int status;
   if (pos('[^\od'word_chars']',get_text(),1,'r') && p_col<=_text_colc(0,'L')) {
      // Search for word after cursor
      status=search('[\od'word_chars']|$','h@r');
      if (status || !match_length()) {
         status=STRING_NOT_FOUND_RC;restore_pos(p);
         // Look for word before cursor
         status=search(common_re,'h@r-');
      }
   } else {
      status=search(common_re,'h@r-');
   }
   return status;
}
_str cur_word2(int &start_col=0,int option=VSCURWORD_WHOLE_WORD,
               bool multi_line=false,
               bool doRestorePos=true
               )
{
   if (multi_line) doRestorePos=false;
   typeless sv_search_string, sv_flags, sv_word_re, sv_more;
   save_search(sv_search_string,sv_flags,sv_word_re,sv_more);
   /*
      end_prev_word effects the following case.

          word1<cursor here>  word2

       By default, word2 is returned,  if end_prev_word==1 then word1 is returned.
   */
   status := 0;
   word_chars := _extra_word_chars:+p_word_chars;
   save_pos(auto p);
   if ( option!=VSCURWORD_WHOLE_WORD ) {
      common_re := '([~\od'word_chars']|^)\c[\od'word_chars']';
      common_re='('common_re')|^';
      if (option==VSCURWORD_AT_END_USE_PREV && p_col!=1 &&
          !(pos('[\od'word_chars']',get_text(1),1,'r') || _dbcsIsLeadByteBuf(get_text_raw()))
         ) {
         left();
         b := pos('[\od'word_chars']',get_text(1),1,'r')  || _dbcsIsLeadByteBuf(get_text_raw());
         right();
         if (b) {
            //start_col=lastpos('\c['word_chars']#',line, col,'r')
            status=search('(\c[\od'word_chars']:1,1000)|^','h@r-');
         } else {
            status=find_cur_word(p,common_re,word_chars);
         }
      } else {
         if (multi_line) {
            if( pos('[\od'word_chars']',get_text(),1,'r') || _dbcsIsLeadByteBuf(get_text_raw())) {
               status=find_cur_word(p,common_re,word_chars);
            } else {
               status=search('[\od'word_chars']','h@r');
            }
         } else {
            status=find_cur_word(p,common_re,word_chars);
         }
      }
   } else {
      if (multi_line) {
         status=search('[\od'word_chars']','h@r');
      } else {
         status=search('[\od'word_chars']|$','h@r');
      }
   }
   if ( status || !match_length()) {
      restore_pos(p);
      restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
      return('');
   }
   start_col=p_col;
   status=search('[~\od'word_chars']|$','h@r');
   if ( status) {
      _end_line();
   }
   if (option==VSCURWORD_BEFORE_CURSOR) restore_pos(p);
   _str word=_expand_tabsc(start_col,p_col-start_col);
   if (doRestorePos) {
      restore_pos(p);
   }
   restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
   return(word);
}

/**
 * Moves the cursor to the beginning of the next word.  If you want the
 * cursor placed on the beginning of the next word, change the next word style
 *
 * @see prev_word
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command void next_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();

   // In ISPF emulation, if the cursor is in the prefix area,
   // next-word should jump out of the prefix area and to the
   // first non-blank character on the line.
   if (_isEditorCtl() && p_LCHasCursor && _LCIsReadWrite()) {
      _first_non_blank();
      p_LCHasCursor=false;
      return;
   }

   status := "";
   if (def_subword_nav) {
      status=skip_subword("");
   } else {
      status=skip_word("");
   }
   retrieve_command_results();
}
/**
 * Moves the cursor to the beginning of the next full word, regardless
 * of the "Subword Navigation" setting.
 *
 * @see next_word
 * @see next_subword
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void next_full_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();

   // In ISPF emulation, if the cursor is in the prefix area,
   // next-word should jump out of the prefix area and to the
   // first non-blank character on the line.
   if (_isEditorCtl() && p_LCHasCursor && _LCIsReadWrite()) {
      _first_non_blank();
      p_LCHasCursor=false;
      return;
   }

   _str status=skip_word("");
   retrieve_command_results();
}
/**
 * Moves the cursor to the beginning of the next subword, regardless of
 * the "Subword Navigation" setting.
 *
 * @see next_word
 * @see next_full_word
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void next_subword() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();

   // In ISPF emulation, if the cursor is in the prefix area,
   // next-word should jump out of the prefix area and to the
   // first non-blank character on the line.
   if (_isEditorCtl() && p_LCHasCursor && _LCIsReadWrite()) {
      _first_non_blank();
      p_LCHasCursor=false;
      return;
   }

   _str status=skip_subword("");
   retrieve_command_results();
}
/**
 * Moves the cursor to the beginning of the previous word.
 *
 * @see next_word
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void prev_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int was_command_state=command_state();
   if (was_command_state) init_command_op();
   if (def_subword_nav) {
      skip_subword("-");
   } else {
      skip_word("-");
   }
   if ( was_command_state ) {
      down();
      if ( ! rc ) {       /* on previous line? */
         begin_line();
      }
   }
   if (was_command_state) retrieve_command_results();

}
/**
 * Moves the cursor to the beginning of the previous full word,
 * regardless of the "Subword Navigation" setting.
 *
 * @see prev_word
 * @see prev_subword
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void prev_full_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int was_command_state=command_state();
   if (was_command_state) init_command_op();
   skip_word("-");
   if ( was_command_state ) {
      down();
      if ( ! rc ) {       /* on previous line? */
         begin_line();
      }
   }
   if (was_command_state) retrieve_command_results();

}
/**
 * Moves the cursor to the beginning of the previous subword, regardless
 * of the "Subword Navigation" setting.
 *
 * @see prev_word
 * @see prev_full_word
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void prev_subword() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int was_command_state=command_state();
   if (was_command_state) init_command_op();
   skip_subword("-");
   if ( was_command_state ) {
      down();
      if ( ! rc ) {       /* on previous line? */
         begin_line();
      }
   }
   if (was_command_state) retrieve_command_results();

}
static _str skip_word(_str direction_option)
{
   _str ch, re1, re2;
   int status;
   typeless orig_pos;
   word_chars := _extra_word_chars:+p_word_chars;
   if( def_vcpp_word ) {
      // Visual C++ style next/prev-word
      if( direction_option=="-" ) {
        if( p_col==1 ) {
           up();_end_line();
        } else {
           left();
        }
        // Guarantee that we start searching from a non-whitespace char
        save_pos(auto p);
        old_line := point();
        re1='([\od'word_chars'])';
        re2='([~\od \t'word_chars'])';
        status=search(re1'|'re2,'@rhe-<');
        if( status ) {
           top();
        } else if( old_line!=point() ) {
           // Forced onto line above, so park cursor at column 1 to let
           // user know that there is nothing else on this line. A subsequent
           // call to prev-word will move to previous word.
           restore_pos(p);
           _begin_line();
        } else {
           // -1 gets the current SBCS/DBCS or Unicode char
           ch=get_text(-1);
           if (pos(re1,ch,1,'r') || _dbcsIsLeadByteBuf(get_text_raw())) {
              re1='((^|[~\od'word_chars'])\c[\od'word_chars'])';
           } else {
              re1='((^|[\od \t'word_chars'])\c[~\od \t'word_chars'])';
           }
           search(re1,'@rhe-<');
        }
      } else {
        was_end_of_line := (p_col>_text_colc());
        if( was_end_of_line && !down() ) {
           if( _expand_tabsc()=="" ) {
              // Blank line, so place at cursor at end. Subsequent call to
              // next-word will move to next word.
              _end_line();
              return(0);
           }
           up();
        }
        // -1 gets the current SBCS/DBCS or Unicode char
        ch=get_text(-1);
        if( ch!='' ) {
           // Search for end of word.
           if( pos('[\od'word_chars']',ch,1,'r') || _dbcsIsLeadByteBuf(get_text_raw()) ) {
              search('[~\od'word_chars']|$','rhe@');
           } else {
              search('[\od \t'word_chars']|$','rhe@');
           }
        }
        ch=get_text(-1);
        if( ch=='' || was_end_of_line ) {
           // Guarantee that we end up on a non-whitespace char
           // def_next_word_style=='E' is not supported
           status=search('[~\od \t]#','@rhe');
        }
      }
      return(status);

   } else if (def_brief_word) {
      if ( direction_option=='-') {
         if ( p_col==1 ) {
            up();_end_line();
         } else {
            left();
         }
         re1='([\od'word_chars'])';
         re2='([~\od \t'word_chars'])';
         status=search(re1'|'re2,'@rhe-<');
         if ( status ) {
            top();
         } else {
            ch=get_text(-1);
            if (pos(re1,ch,1,'r') || _dbcsIsLeadByteBuf(get_text_raw())) {
               re1='((^|[~\od'word_chars'])\c[\od'word_chars'])';
            } else {
               re1='((^|[\od \t'word_chars'])\c[~\od \t'word_chars'])';
            }
            search(re1,'@rhe-<');
         }
      } else {
         ch=get_text(-1);
         if (ch!='' ) {
            // Search for end of word.
            if (pos('[\od'word_chars']',ch,1,'r') || _dbcsIsLeadByteBuf(get_text_raw())) {
               search('[~\od'word_chars']|$','rhe@');
            } else {
               search('[\od \t'word_chars']|$','rhe@');
            }
         }
         // Guarantee that we end up on a non-whitespace char
         // def_next_word_style=='E' is not supported
         status=search('[~\od \t]#','@rhe');
      }
      return(status);
   }
   if ( direction_option=='-' ) {
      if ( p_col==1 ) {
         up();_end_line();
      } else {
         left();
      }
      if (p_UTF8) {
         status=search('['word_chars']#','@rhe-<');
         if (status) {
            save_pos(orig_pos);
            //top();
         }
      } else {
         status=search('[\od]|['word_chars']','@rhe-<');
         if (status) {
            save_pos(orig_pos);
            //top();
         } else {
            if (_dbcs() && _dbcsIsLeadByteBuf(get_text_raw())) {
            } else {
               status=search('(^|[~\od'word_chars'])\c([\od]|['word_chars'])','@rhe-<');
            }
         }
      }
   } else {
      if ( def_next_word_style=='E' ) {   /* Move to end of next word */
         status=search('[\od]|['word_chars']#','@rhe>');
         //p_col+=1;status=search('[^'word_chars']','@rh');
         //p_col+=1;status=search(' ','@h');
         if (_begin_char()) {
            // This is a composite character
            // For now, we treat composite characters like a word.
            right();
         }
      } else {
         save_pos(orig_pos);
         if (p_UTF8) {
            // IF the current UTF-8 character sequence is a word character
            if ( pos('[\od'word_chars']',get_text(-1),1,'r')) {
               // Skip current character
               right();
            }
            /* Search for beginning of next word. */
            status=search('([~\od'word_chars']|^)\c[\od'word_chars']#','@rhe');
            if (status) {
               restore_pos(orig_pos);
            }
         } else {
            /* Move to beginning of next word. */
            if ( pos('[\od'word_chars']',get_text(1),1,'r')  || _dbcsIsLeadByteBuf(get_text_raw())) {
               right();
            }
            //status=search('(\c[\od]|[~'_extra_word_chars:+p_word_chars']\c|^\c)([\od]|['_extra_word_chars:+p_word_chars'])#','@re');
            save_pos(auto p);
            status=search('(\c[\od]|[~'word_chars']\c|^\c)','@rhe');
            if (!status && _dbcs() && _dbcsIsLeadByteBuf(get_text_raw())) {
            } else {
               restore_pos(p);
               status=search('([~'word_chars']|^)\c([\od]|['word_chars'])#','@rhe');
               if (status) {
                  restore_pos(orig_pos);
               }
               //status=search('([~'_extra_word_chars:+p_word_chars']|^)\c([\od]|['_extra_word_chars:+p_word_chars'])#','@re');
            }
         }
      }
   }
   return(status);
}

/**
 * Moves the cursor to the beginning of the current word.   To change
 * the word characters for a specific language, use the Options
 * dialog ("Document", "[Language] Options...]", "General".
 *
 * @see end_word
 * @see next_word
 * @see prev_word
 * @see cur_word
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void begin_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   start_col := 0;
   word := cur_word(start_col);
   if (word != "") {
      p_col=_text_colc(start_col,'I');
   }
}

/**
 * Moves the cursor to the end of the current word.   To change
 * the word characters for a specific language, use the Options
 * dialog ("Document", "[Language] Options...]", "General".
 *
 * @see begin_word
 * @see next_word
 * @see prev_word
 * @see cur_word
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void end_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   start_col := 0;
   word := cur_word(start_col);
   if (word != "") {
      p_col = _text_colc(start_col,'I')+length(word);
   }
}

/**
 * Selects the text from the cursor to the end of the word at the cursor or
 * the next word.
 *
 * @see select_whole_word
 * @see select_subword
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_command void select_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (def_subword_nav) {
      pselect_subword(_duplicate_selection(""),false);
   } else {
      pselect_word(_duplicate_selection(""));
   }

}
/**
 * Selects the text from the cursor to the end of the subword at the cursor
 * or the next subword.
 *
 * @see select_word
 * @see select_full_word
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_command void select_subword() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   pselect_subword(_duplicate_selection(""),false);
}
/**
 * Selects the text from the cursor to the end of the full word at
 * the cursor or the next compound.
 *
 * @see select_word
 * @see select_subword
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_command void select_full_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   pselect_word(_duplicate_selection(""));
}
_str def_word_delim="0";

_str pselect_subword(typeless mark, bool skipTrailing=true)
{
   _deselect(mark);
   _select_char(mark);
   int status;
   save_pos(auto p);
   status = skip_subword("",skipTrailing);
   if ( status ) {
      _deselect(mark);
      restore_pos(p);
      return(status);
   }
   _select_char(mark,translate(def_select_style,'N','I'));
   _cua_select=1;
   return(0);
}

_str pselect_word(typeless mark)
{
   _deselect(mark);_select_char(mark);
   if (!p_UTF8 && _dbcs()) {
      ch := get_text();
      int start=_StartOfDBCSCol(p_col)? 1:0;
      if (!start) {
         // This is unlikely to happen
         left();
         _deselect(mark);_select_char(mark);
         right();
         _select_char(mark,translate(def_select_style,'N','I'));
         _cua_select=1;
         return(0);
      } else if (start && _dbcsIsLeadByte(ch)) {
         right();
         _select_char(mark,translate(def_select_style,'N','I'));
         _cua_select=1;
         return(0);
      }
   }
   int status;
   word_chars := _extra_word_chars:+p_word_chars;
   if (def_brief_word) {
      // blanks | wordchars [blanks] |~ blnk,word_chars [blanks]
      status=search('[ \t]#|[\od'word_chars']#([ \t]@)|[~\od 'word_chars']#([ \t]@)','@rhe>');  /* rev2a */
   } else if( def_vcpp_word ) {
      // blanks | wordchars [blanks] |~ blnk,word_chars [blanks]
      status=search('[ \t]#|[\od'word_chars']#([ \t]@)|[~\od 'word_chars']#([ \t]@)','@rhe>');  /* rev2a */
   } else {
      if ( def_word_delim ) {
         status=search('[\od'word_chars']#|[~\od'word_chars']#','@rhe>');  /* rev2a */
      } else {
         status=search('[\od'word_chars']#','@rhe>'); /* rev2a */
      }
   }
   if ( status ) {
      _deselect(mark);
      return(status);
   }
   _select_char(mark,translate(def_select_style,'N','I'));
   _cua_select=1;
   return(0);

}
static int skip_subword(_str direction_option, bool skipTrailing=true)
{
   orig_col := p_col;
   ch := get_text();
   status := 0;
   _str word_chars = _clex_identifier_chars();
   if (direction_option == "-") {
      if (p_col == 1) {
         up();
         _end_line();
         return 0;
      }
      moved := maybeEatLeadingChars(ch);
      if (p_col == 1) {
         return 0;
      }
      ch = get_text();
      left();
      tempCh := get_text();
      // Word <- cursor on 'o' and you hit prev-word
      if (isLowercase(ch) && isalpha(tempCh) && upcase(tempCh) == tempCh) {
         maybeSkipBackOverChar("$");
         return 0;
      }
      prevCh := get_text();
      // say('prevCh =' prevCh', ch = ' ch', moved = ' moved);
      // prevCh: character to the left after eating leading separators and spaces
      if (isLowercase(prevCh)) {
         // lowercase: move past the string of lowercase chars
         status = search('[a-z]#','@reh-<');
         prevCh = get_prev_char();
         if (isalpha(prevCh) && upcase(prevCh) == prevCh) {
            // could have stopped after the uppercase, so back up
            left();
         } else if (_clex_is_identifier_char(prevCh)) {
            // skip non-alpha identifier chars or lowercase chars
            status = search('[A-Z]|[^'_clex_identifier_chars()']|[\n]|[\_-]','@reh->');
            prevCh = get_prev_char();
            ch = get_text();
            // if we stopped on an alpha char, it has to be lowercase, b/c we would've stopped b4 an uppercase
            if (isalpha(ch)) {
               if (isalpha(prevCh) && upcase(prevCh) == prevCh) {
                  left();
               }
            } else if (_clex_is_identifier_char(ch)) {
               // if we stopped on a string of uppercase before a non-alpha identifier char then
               // eat the string of uppercases
               if (isalpha(prevCh) && upcase(prevCh) == prevCh) {
                  status = search('[A-Z]#','@reh-<');
               }
            }
         }
         maybeSkipBackOverChar("$");
      } else if (isalpha(prevCh)) {
         // uppercase: need to check the char to the right
         if (isalpha(ch) && !isLowercase(ch)) {
            // uppercase: move past the string of uppercase chars
            status = search('[A-Z]#','@reh-<');
         } else {
            // non-alpha word char OR non-word char: need to check char to the left
            prevCh = get_prev_char();
            if (!isLowercase(prevCh) && isalpha(prevCh)) {
               // uppercase: search til the end of the string of uppercases
               status = search('[A-Z]#','@reh-<');
               prevCh = get_prev_char();
               if (_clex_is_identifier_char(prevCh) && !isalpha(prevCh) && prevCh != '-' && prevCh != '_') {
                  // skip non-alpha identifier chars
                  left();
                  status = search('[a-zA-Z]|[^'_clex_identifier_chars()']|[\n]|[\_-]','@reh->');
               }
            }
         }
         maybeSkipBackOverChar("$");
      } else if (!_clex_is_identifier_char(prevCh)) {
         // non-word char: check char to the right
         if (!_clex_is_identifier_char(ch) || !moved) {
            // non-word char OR didn't have any leading separators: jump back to end of string of non-word chars
            status = search('['word_chars']|['def_space_chars']|[\n]','@reh->');
         } else {
            right();
         }
      } else {
         // non-alpha word char: jump back to the next uppercase or non-word char or separator
         status = search('[A-Z]|[^'word_chars']|[\-_]|[\n]','@reh->');
         prevCh = get_prev_char();
         ch = get_text();
         // we stopped before an uppercase...move past a string of uppercase (unless we are on a lowercase)
         if (isalpha(prevCh) && !isLowercase(prevCh) && !isLowercase(ch)) {
            search('[A-Z]#','@reh-<');
         } else if (isalpha(prevCh)) {
            left();
         }
         maybeSkipBackOverChar("$");
      }
   } else {
      if (at_end_of_line()) {
         // eol: down to the next line
         down();
         begin_line();
      } else if (isspace(ch)) {
         // space char: end of the spaces
         status = search('['def_space_chars']#','@reh+>');
      } else if (isalpha(ch)) {
         if (isLowercase(ch)) {
            // lowercase: go to the last lowercase letter in the sequence
            status = search('[a-z]#','@reh>');
            maybeEatTrailingChars(skipTrailing,true,true);
         } else {
            right();
            nextChar := get_text();
            left();
            if (isLowercase(nextChar)) {
               // lowercase: go to the last lowercase letter in the sequence
               right();
               status = search('[a-z]#','@reh>');
               maybeEatTrailingChars(skipTrailing,true,true);
            } else if (isalpha(nextChar)) {
               // uppercase, go to last uppercase letter in the sequence
               status = search('[A-Z]#','@reh>');
               ch = get_text();
               if (!maybeEatTrailingChars(skipTrailing,isalpha(ch),isLowercase(ch)) && isalpha(get_text())) {
                  // if we didn't eat any separators or spaces, and this is an alpha char
                  // it must be lowercase, so step back
                  left();
               }
            } else if (_clex_is_identifier_char(nextChar)) {
               // non-alpha word char: jump to it
               right();
               maybeEatTrailingChars(skipTrailing);
            } else {
               // non-word char: jump to it
               right();
            }
         }
      } else if(_clex_is_identifier_char(ch) && (ch == '_' || ch == '-')){
         // separators: go to last separator in the sequence
         maybeEatTrailingChars();
      } else if (_clex_is_identifier_char(ch)) {
         // non-alpha word char: skip to the next upcase OR non-word char OR separator
         status = search('[A-Z]|[^'word_chars']|[\-_]|\n','@reh+<');
         ch = get_text();
         // if we are on a separator, space, or...
         if (ch == '-' || ch == '_' || isspace(ch)) {
            curIsAlpha := isalpha(get_text());
            curIsLCase := false;
            if (curIsAlpha) {
               curIsLCase = isLowercase(get_text());
            }
            maybeEatTrailingChars(skipTrailing,curIsAlpha,curIsLCase);
         }
      } else {
         // non-word char: jump to first word char, space, or EOL but eat trailing spaces
         status = search('['word_chars']|['def_space_chars']|\n','@reh+<');
         if (isspace(get_text())) {
            status = search('['def_space_chars']#','@reh+>');
         }
      }
   }
   return status;
}

/**
 * Possibly step backwards over a particular character.
 *
 * @param ch The character
 */
static void maybeSkipBackOverChar(_str ch="") {
   _str prevCh = get_prev_char();
   if (p_col > 1 && prevCh == ch && _clex_is_identifier_char(prevCh)) {
      left();
      prevCh = get_prev_char();
      if (!isspace(prevCh) && p_col > 1) {
         right();
      }
   }
}

/**
 * Skip backwards over possible word separators (dashes,underscores) and spaces
 * behind the cursor.
 *
 * @return Did we move?
 */
static bool maybeEatLeadingChars(_str ch="", bool cameFromAlpha=false, bool alphaWasLCase=false)
{
   _str prevCh = get_prev_char();
   orig_col := p_col;
   if (isspace(ch)) {
      search('['def_space_chars']#','@reh-<');
   } else if (isspace(prevCh)){
      left();
      search('['def_space_chars']#','@reh-<');
   }
   curChar := get_text();
   prevCh = get_prev_char();
   if (_clex_is_identifier_char(curChar) && curChar == '_') {
      search('[_]#','@reh-<');
   } else if (_clex_is_identifier_char(curChar) && curChar == '-') {
      search('[\-]#','@reh-<');
   } else if (_clex_is_identifier_char(prevCh) && prevCh == '_') {
      left();
      search('[_]#','@reh-<');
   } else if (_clex_is_identifier_char(prevCh) && prevCh == '-') {
      left();
      search('[\-]#','@reh-<');
   }
   return orig_col != p_col;
}
/**
 * Skip over possible word separators (dashes, underscores) and spaces
 * in front of the cursor.
 *
 * @return Did we move?
 */
static bool maybeEatTrailingChars(bool forceSkip=true, bool cameFromAlpha=false, bool alphaWasLCase=false)
{
   if (!forceSkip) {
      return false;
   }
   moved := false;
   _str word_chars = _clex_identifier_chars();
   // here we want to move to the next alpha char, non-identifier char, but skip a string of spaces
   // we are skipping non-alpha identifier chars, ie. numbers or $
   col := p_col;
   status := search('[a-zA-Z]|[^'word_chars']|[\n]|[\-_]','@reh+<');
   moved = p_col != col;

   ch := get_text();
   if (!_clex_is_identifier_char(ch)) {
      // if we are on a non-word char, we are done
   } else if (isLowercase(ch)) {
      if (moved) {
         // on a lowercase and we ate some chars...we should keep going
         status = search('[A-Z]|[^'word_chars']|[\n]','@reh+<');
         moved = p_col != col;
      }
   } else if (isalpha(ch) && cameFromAlpha && !alphaWasLCase) {
      // if we are on an uppercase and we came from an uppercase, keep going
      status = search('[a-z]|[^'word_chars']|[\n]','@reh+<');
      moved = p_col != col;
      // if we stopped on an lowercase, and the char before it is uppercase...move backward
      if (isLowercase(get_text()) && isalpha(get_prev_char()) && !isLowercase(get_prev_char())) {
         left();
      }
   }

   // skip separators and spaces
   if (_clex_is_identifier_char(ch) && ch == '_') {
      search('[_]#','@reh+>');
      moved = true;
   } else if (_clex_is_identifier_char(ch) && ch == '-') {
      search('[\-]#','@reh+>');
      moved = true;
   }
   if (isspace(ch)) {
      search('['def_space_chars']#','@reh+>');
      moved = true;
   }
   return moved;
}
static bool isLowercase(_str ch)
{
   return (isalpha(ch) && lowcase(ch) == ch);
}

/**
 * Toggle between successive, increasingly large selections with
 * each invocation.
 * <p>
 * Starting with no selection, creates an empty character selection,
 * then selects the current word, then the current line, then the current
 * code block, then a larger code block, then the current function, then
 * the entire file, then deselect and start all over again.
 * <p>
 * Except for empty character selections and line selections, the
 * selections are all locked so that the cursor remains stationary.
 *
 * @see select_char
 * @see select_whole_word
 * @see select_line
 * @see select_code_block
 * @see select_proc
 * @see select_all
 * @see deselect
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command void select_toggle() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   // keeps track of the last type of selection made
   static _str last_selection_type;
   if (_select_type()=="") {
      last_selection_type="";
   }
   status := 0;
   save_pos(auto p);
   switch (last_selection_type) {
   case "":
      _deselect();
      select_char();
      last_selection_type="CHAR";
      message("Starting character selection.");
      return;
   case "CHAR":
      _deselect();
      select_whole_word();
      last_selection_type="WORD";
      message("Selected word under cursor.");
      break;
   case "WORD":
      _deselect();
      select_line();
      last_selection_type="LINE";
      message("Selected current line.");
      return;
   case "LINE":
      _deselect();
      status = select_code_block();
      last_selection_type="CODE";
      message("Selected code block.");
      lock_selection();
      if (!status && count_lines_in_selection() > 1) {
         break;
      }
      // might just drop through
   case "CODE":
      _UpdateContext(true);
      tag_lock_context();
      context_id := tag_current_context();
      proc_start_line := 1;
      proc_end_line   := MAXINT;
      if (context_id > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, proc_start_line);
         tag_get_detail2(VS_TAGDETAIL_context_end_linenum, context_id, proc_end_line);
      }
      tag_unlock_context();
      orig_lines := count_lines_in_selection();
      status = select_code_block();
      lock_selection();
      new_lines := count_lines_in_selection();
      message("Extending selected code block.");
      if (!status && new_lines > orig_lines && new_lines <= proc_end_line-proc_start_line+1) {
         break;
      }
      _deselect();
      restore_pos(p);
      last_selection_type="PROC";
      if (!select_proc(0, -1, 1)) {
         message("Selected current function.");
         break;
      }
      // might just drop through
   case "PROC":
      _deselect();
      select_all_line();
      last_selection_type="ALL";
      message("Selected entire file.");
      break;
   case "ALL":
      _deselect();
      last_selection_type="";
      message("Deselected.");
      return;
   }
   lock_selection("q");
   restore_pos(p);
}

/**
 * @return Places current line at top of window.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void line_to_top() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_object==OI_LIST_BOX) {
      _lbline_to_top();
      return;
   }
   set_scroll_pos(p_left_edge,0);

}
/**
 * @return Places current line at bottom of window.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void line_to_bottom() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_object==OI_LIST_BOX) {
      _lbline_to_bottom();
      return;
   } else if ( p_object==OI_COMBO_BOX ) {
      // 12/13/2011 - This no longer makes sense but there may be dated code that
      // still calls it.  Just avoid this call so there is no Slick-C stack.
      return;
   }
   if (p_IsTempEditor) {
      return;
   }
   set_scroll_pos(p_left_edge,p_client_height);
}
/**
 * Translates the current word to upper case and places the cursor after
 * the current word.
 *
 * @return Returns 0 if successful.  Returns 1 if no word exists at cursor.  On
 * error, message is displayed.
 *
 * @see lowcase_word
 * @see cap_word
 * @see camelcase_to_undescore
 * @see undescore_to_camelcase
 * @see toggle_camelcase
 * @see upcase
 * @see upcase_selection
 * @see lowcase
 * @see lowcase_selection
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command upcase_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   start_col := 0;
   _str word=cur_word(start_col,def_from_cursor,false,def_word_continue);
   if ( word=="" ) {
      retrieve_command_results();
      message(nls("No word at cursor"));
      return(1);
   }
   p_col=_text_colc(start_col,'I');
   _delete_text(_rawLength(word));
   _insert_text(upcase(word));
   retrieve_command_results();
   return(0);

}
/**
 * Translates the current word to lower case and places the cursor after the
 * current word.
 *
 * @return Returns 0 if successful.  Returns 1 if no word exists at cursor.
 * On error, message is displayed.
 *
 * @see upcase_word
 * @see cap_word
 * @see camelcase_to_undescore
 * @see undescore_to_camelcase
 * @see toggle_camelcase
 * @see upcase
 * @see upcase_selection
 * @see lowcase
 * @see lowcase_selection
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command lowcase_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   start_col := 0;
   _str word=cur_word(start_col,def_from_cursor,false,def_word_continue);
   if ( word=="" ) {
      retrieve_command_results();
      message(nls("No word at cursor"));
      return(1);
   }
   p_col=_text_colc(start_col,'I');
   _delete_text(_rawLength(word));
   _insert_text(lowcase(word));
   retrieve_command_results();
   return(0);

}
_str _camelcase_to_underscore(_str word) {
   j:=1;
   for (;;) {
      i:=pos('[\p{Lu}]',word,j,'re');
      if (!i) {
         break;
      }
      matchlen:=pos('');
      //say('i='i' m='matchlen' w='word);
      if (i==1) {
         word=lowcase(substr(word,i,matchlen)):+substr(word,i+matchlen);
      } else if (substr(word,i-1,1)=='_') {
         word=substr(word,1,i-1):+lowcase(substr(word,i,matchlen)):+substr(word,i+matchlen);
      } else {
         word=substr(word,1,i-1):+'_':+lowcase(substr(word,i,matchlen)):+substr(word,i+matchlen);
      }
      j=i+matchlen+1;
      //say('w='word);
   }
   return word;
}
_str _underscore_to_camelcase(_str word) {
   j:=1;
   len:=_UTF8CharRead2OrMore(j,word,auto ch32);
   word=upcase(substr(word,j,len)):+substr(word,j+len);
   j=j+len;
   for (;;) {
      i:=pos('_[\p{L}]',word,j,'re');
      if (!i) {
         break;
      }
      matchlen:=pos('');
      match:=substr(word,i+1,matchlen-1);
      //say('i='i' m='matchlen' w='word);
      word=substr(word,1,i-1):+upcase(match):+substr(word,i+matchlen);
      j=i+matchlen+1;
      //say('w='word);
   }
   return word;
}
/**
 * Translates the current word from camelcase to underscores
 *
 * @return Returns 0 if successful.  Returns 1 if no word exists at cursor.
 * On error, message is displayed.
 *
 * @see upcase_word
 * @see lowcase_word
 * @see undescore_to_camelcase
 * @see toggle_camelcase
 * @see cap_word
 * @see upcase
 * @see upcase_selection
 * @see lowcase
 * @see lowcase_selection
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command int camelcase_to_underscore() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   start_col := 0;
   _str word=cur_word(start_col,def_from_cursor,false,def_word_continue);
   if ( word=="" ) {
      retrieve_command_results();
      message(nls("No word at cursor"));
      return(1);
   }
   p_col=_text_colc(start_col,'I');
   _delete_text(_rawLength(word));
   _insert_text(_camelcase_to_underscore(word));
   retrieve_command_results();
   return(0);
}
/**
 * Translates the current word from underscores to camelcase
 *
 * @return Returns 0 if successful.  Returns 1 if no word exists at cursor.
 * On error, message is displayed.
 *
 * @see upcase_word
 * @see lowcase_word
 * @see camelcase_to_undescore
 * @see toggle_camelcase
 * @see cap_word
 * @see upcase
 * @see upcase_selection
 * @see lowcase
 * @see lowcase_selection
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command int underscore_to_camelcase() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   start_col := 0;
   _str word=cur_word(start_col,def_from_cursor,false,def_word_continue);
   if ( word=="" ) {
      retrieve_command_results();
      message(nls("No word at cursor"));
      return(1);
   }
   p_col=_text_colc(start_col,'I');
   _delete_text(_rawLength(word));
   _insert_text(_underscore_to_camelcase(word));
   retrieve_command_results();
   return(0);
}
/**
 * Translates the current word from/to underscores to camelcase
 *
 * @return Returns 0 if successful.  Returns 1 if no word exists at cursor.
 * On error, message is displayed.
 *
 * @see upcase_word
 * @see lowcase_word
 * @see camelcase_to_undescore
 * @see undescore_to_camelcase
 * @see cap_word
 * @see upcase
 * @see upcase_selection
 * @see lowcase
 * @see lowcase_selection
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command int toggle_camelcase() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   start_col := 0;
   _str word=cur_word(start_col,def_from_cursor,false,def_word_continue);
   if ( word=="" ) {
      retrieve_command_results();
      message(nls("No word at cursor"));
      return(1);
   }
   p_col=_text_colc(start_col,'I');
   _delete_text(_rawLength(word));
   if (pos('_',word)) {
      _insert_text(_underscore_to_camelcase(word));
   } else {
      _insert_text(_camelcase_to_underscore(word));
   }
   retrieve_command_results();
   return(0);
}
/**
 * Ctrl+K or "Edit", "Copy Word"
 *
 * Copies word at cursor to the clipboard.  Invoking this command from the
 * keyboard multiple times in succession creates one clipboard.
 *
 * @return  Returns 0 if word exists at cursor.  Common return codes are
 * STRING_NOT_FOUND_RC and TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command copy_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   status := 0;
   init_command_op();
   push := name_name(prev_index('','C'))!="copy-word";
   if ( push && !def_subword_nav) {
      int i=_text_colc(p_col,'p');
      LineLen := _line_length();
      if ( i>LineLen && LineLen) {
         i=LineLen;
      }
      p_col=_text_colc(i,'I');
      status=search('[\od'_extra_word_chars:+p_word_chars']#|?|^','-rh@');
   }
   // there was a bug in copy_word when in brief emulation.  it was copying
   // the word as well as the whitespace that follows the word.  the reason
   // this was done is pselect_word() is indirectly used by select_word,
   // copy_word, and delete_word.  brief's delete_word deletes the word and
   // the trailing whitespace.  brief doesnt have an equivalent to copy_word.
   // to avoid this behavior in copy word, turn off def_brief_word before
   // calling cut_word2() and restore it after.  this will prevent the
   // specialized brief selection from happening for this case.
   //
   // 1/19/2004: Ditto for def_vcpp_word
   origDefBriefWord := def_brief_word;
   def_brief_word = false;
   origDefVcppWord := def_vcpp_word;
   def_vcpp_word = false;

   status=cut_word2(push,true,0,false);
   retrieve_command_results();

   // restore the def_brief_word value
   def_brief_word = origDefBriefWord;
   // restore the def_vcpp_word value
   def_vcpp_word = origDefVcppWord;

   return(status);

}
/**
 * Same as copy_word, except copies full word at cursor to the
 * clipboard, ignoring def_subword_nav setting.
 *
 * @return  Returns 0 if word exists at cursor.
 *
 * @see copy_word
 * @see copy_subword
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command copy_full_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   status := 0;
   init_command_op();
   push := name_name(prev_index('','C'))!="copy-full-word";
   if ( push ) {
      int i=_text_colc(p_col,'p');
      LineLen := _line_length();
      if ( i>LineLen && LineLen) {
         i=LineLen;
      }
      p_col=_text_colc(i,'I');
      status=search('[\od'_extra_word_chars:+p_word_chars']#|?|^','-rh@');
   }

   // there was a bug in copy_word when in brief emulation.  it was copying
   // the word as well as the whitespace that follows the word.  the reason
   // this was done is pselect_word() is indirectly used by select_word,
   // copy_word, and delete_word.  brief's delete_word deletes the word and
   // the trailing whitespace.  brief doesnt have an equivalent to copy_word.
   // to avoid this behavior in copy word, turn off def_brief_word before
   // calling cut_word2() and restore it after.  this will prevent the
   // specialized brief selection from happening for this case.
   //
   // 1/19/2004: Ditto for def_vcpp_word
   origDefBriefWord := def_brief_word;
   def_brief_word = false;
   origDefVcppWord := def_vcpp_word;
   def_vcpp_word = false;

   status=cut_word2(push,true,-1);
   retrieve_command_results();

   // restore the def_brief_word value
   def_brief_word = origDefBriefWord;
   // restore the def_vcpp_word value
   def_vcpp_word = origDefVcppWord;

   return(status);

}
/**
 * Same as copy_word, except copies subword at cursor to the
 * clipboard, ignoring def_subword_nav setting.
 *
 * @return  Returns 0 if word exists at cursor.
 *
 * @see copy_word
 * @see copy_full_word
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command copy_subword() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   status := 0;
   init_command_op();
   push := name_name(prev_index('','C'))!="copy-subword";
   if ( push ) {
      int i=_text_colc(p_col,'p');
      LineLen := _line_length();
      if ( i>LineLen && LineLen) {
         i=LineLen;
      }
      p_col=_text_colc(i,'I');
      status=search('[\od'_extra_word_chars:+p_word_chars']#|?|^','-rh@');
   }

   // there was a bug in copy_word when in brief emulation.  it was copying
   // the word as well as the whitespace that follows the word.  the reason
   // this was done is pselect_word() is indirectly used by select_word,
   // copy_word, and delete_word.  brief's delete_word deletes the word and
   // the trailing whitespace.  brief doesnt have an equivalent to copy_word.
   // to avoid this behavior in copy word, turn off def_brief_word before
   // calling cut_word2() and restore it after.  this will prevent the
   // specialized brief selection from happening for this case.
   //
   // 1/19/2004: Ditto for def_vcpp_word
   origDefBriefWord := def_brief_word;
   def_brief_word = false;
   origDefVcppWord := def_vcpp_word;
   def_vcpp_word = false;

   status=cut_word2(push,true,1,false);
   retrieve_command_results();

   // restore the def_brief_word value
   def_brief_word = origDefBriefWord;
   // restore the def_vcpp_word value
   def_vcpp_word = origDefVcppWord;

   return(status);

}
/**
 * Copies the buffer name (p_buf_name) to the clipboard
 *
 * @return  Returns 0 if word exists at cursor.
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void copy_buf_name() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _copy_text_to_clipboard(p_buf_name);
}
/**
 * Copies the buffer name (p_buf_name) to the clipboard
 *
 * @return  Returns 0 if word exists at cursor.
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void copy_buf_name_only() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _copy_text_to_clipboard(_strip_filename(p_buf_name,'P'));
}
_str retrieve_skip(...)
{
   status := 0;
   typeless old1,old2,old3,old4;
   int start_line;
   int view_id;
   get_window_id(view_id);
   activate_window(VSWID_RETRIEVE);
   Noflines := p_Noflines;
   result := "";
   line := "";
   int i;
   if (arg(2)=="") {
      activate_window(view_id);
      for (i=1; i<=Noflines+1 ; ++i) {
         if ( upcase(arg(1))=='N' ) {
            _retrieve_next();
         } else {
            _retrieve_prev();
         }
         _cmdline.get_command(line);
         if ( substr(line,1,1)!="@" ) {
            result=line;
            break;
         }
         _cmdline.set_command("",1,1);
      }
   } else {
      // Old code was way to slow.  Speeding it up by using search built-in
      _cmdline.get_command(old1,old2,old3,old4); /* ,old5,old6,old7,old8 */
      start_line=p_line;
      done := 0;
      if ( upcase(arg(1))=="N" ) {
         _cmdline._retrieve_next();
      } else {
         _cmdline._retrieve_prev();
      }
      _cmdline.get_command(line);
      if ( substr(line,1,length(arg(2)))==arg(2) && line:!=arg(3) ) {
         result=line;
         done=1;
      }
      _cmdline.set_command(old1,old2,old3,old4); /* ,old5,old6,old7,old8 */
      if (!done) {
         re := '^'_escape_re_chars(arg(2));
         if ( upcase(arg(1))=='N' ) {
            _end_line();
            status=search(re,'rh@');
            for (;;) {
               if (status) break;
               get_line(line);
               if (line:!=arg(3)) {
                  result=line;
                  done=1;
                  break;
               }
               status=repeat_search();
            }
            if (!done) {
               top();
               status=search(re,'rh@');
               for (;;) {
                  if (status||p_line>=start_line) break;
                  get_line(line);
                  if (line:!=arg(3)) {
                     result=line;
                     done=1;
                     break;
                  }
                  status=repeat_search();
               }
            }
         } else {
            up();_end_line();
            status=search(re,'-rh@');
            for (;;) {
               if (status) break;
               get_line(line);
               if (line:!=arg(3)) {
                  result=line;
                  done=1;
                  break;
               }
               status=repeat_search();
            }
            if (!done) {
               bottom();
               status=search(re,'-rh@');
               for (;;) {
                  if (status||p_line<start_line) break;
                  get_line(line);
                  if (line:!=arg(3)) {
                     result=line;
                     done=1;
                     break;
                  }
                  status=repeat_search();
               }
            }
         }
      }
      if (!done) {
         p_line=start_line;
      }
      activate_window(view_id);

   }
#if 0
   _cmdline.get_command(old1,old2,old3,old4); /* ,old5,old6,old7,old8 */
   activate_window(view_id);
   for (i=1; i<=Noflines+1 ; ++i) {
      if ( upcase(arg(1))=='N' ) {
         _retrieve_next();
      } else {
         _retrieve_prev();
      }
      _cmdline.get_command(line);
      if ( arg(2):!="" ) {
         if ( substr(line,1,length(arg(2)))==arg(2) && line:!=arg(3) ) {
            result=line;
            break;
         }
      } else {
         if ( substr(line,1,1)!="@" ) {
            result=line;
            break;
         }
         _cmdline.set_command("",1,1);
      }
      if ( arg(2):!="" ) {
         _cmdline.set_command(old1,old2,old3,old4); /* ,old5,old6,old7,old8 */
      }
   }
#endif
   return(result);
}
static const VSLANGUAGE_NOTSUPPORTEDPREFIX= "NotSupported_";
_str _getSupportedLangId(_str lang)
{
   if (substr(lang,1,length(VSLANGUAGE_NOTSUPPORTEDPREFIX))==VSLANGUAGE_NOTSUPPORTEDPREFIX) {
      return(substr(lang,length(VSLANGUAGE_NOTSUPPORTEDPREFIX)+1));
   }
   return(lang);
}
long _getTotalKMemory() {
   if (_isWindows()) {
      long MemoryLoadPercent, TotalPhys, AvailPhys, TotalPageFile, AvailPageFile, TotalVirtual, AvailVirtual;
      ntGlobalMemoryStatus(MemoryLoadPercent,TotalPhys,AvailPhys,TotalPageFile,AvailPageFile,TotalVirtual,AvailVirtual);
      return TotalPhys;
   }
   long TotalVirtual=0, AvailVirtual=0;
   if (!_VirtualMemoryInfo(TotalVirtual, AvailVirtual)) {
      return TotalVirtual;
   }
   return 0;
}
#if 0
static void auto_set_buffer_cache(_str &large_file_editing_msg) {
   // IF buffer size > 100 megabytes
   if (def_auto_set_buffer_cache && p_buf_size>(def_auto_set_buffer_cache_ksize*1024)) {
      // See if we should adjust the cache size. Default is too small for performing edits.
      parse _cache_size() with auto ksizeStr .;
      long ksize=(long)ksizeStr;
      //say("ksize="ksize);
      long recommended_ksize=(long)(p_buf_size/1024)*2;
      if (isinteger(ksize) && ksize>=0 && ksize<recommended_ksize) {
         physical_memory_ksize := _getTotalKMemory();
         //say("physical_memory_ksize="physical_memory_ksize);
         if (physical_memory_ksize) {
            /*
                Only allow SlickEdit 1/4 of the physical memory.
                old comment:Guess 400 megabytes for the rest of SlickEdit.
                            This is a bit low if the user has
                            many big tag files (maybe created by auto-tagging maybe).
            */
            //long available_for_buffer_cache=physical_memory_ksize/2-400000;
            long available_for_buffer_cache=physical_memory_ksize/4;
            have_enough_available := false;
            if (available_for_buffer_cache>(long)ksize) {
               have_enough_available=true;
               // Twice the buffer size
               new_kcache := recommended_ksize;
               if (available_for_buffer_cache<new_kcache) {
                  new_kcache=available_for_buffer_cache;
               }
               //say(recommended_ksize);
               _cache_size(new_kcache);
               large_file_editing_msg="Buffer cache size automatically increased";
            }
            if (!have_enough_available) {
               /*use_large_file_warning=true;
               if (large_file_editing_msg!="") {
                  large_file_editing_msg="\n":+large_file_editing_msg;
               } */
               msg := "Large edit operations will generate a large spill file. Add memory for better performance";
               //large_file_editing_msg=msg:+large_file_editing_msg;
               _ActivateAlert(3, 8,msg);
               sticky_message(msg);
#if 0
               more := "";
               if (p_buf_size>500000000) { // 500 megabytes
                  more="\nIt is also recommended that you have at least 8GB of physical memory.";
               }
               _ActivateAlert(3, 5, "Increase your virtual memory buffer cache size (KB) to "recommended_ksize".\nTools>Options>Virtual Memory>Buffer cache size (KB)."more, "Recommendation", 1);
               sticky_message("Increase your buffer cache size to "recommended_ksize" (Options>Virtual Memory>Buffer cache size)");
#endif
            }
         }
      }
   }
}
#endif

/**
 * @return Return "true" if the given language ID (see {@link p_LangId})
 *         is a standard language supported at installation or if it
 *         is a language added by the user.
 *
 * @param lang    language ID
 *
 */
bool _IsInstalledLanguage(_str lang)
{
   return _plugin_has_builtin_profile(VSCFGPACKAGE_LANGUAGE,lang);
   //return (pos(" "lang" "," "gInstalledLanguages" ") > 0);
}

void _cbsave_editorconfig() {
   if (_file_eq(_strip_filename(p_buf_name,'P'),".editorconfig") || _file_eq(_strip_filename(p_buf_name,'P'),".seeditorconfig.xml")) {
      _EditorConfigClearCache();
      _beautifier_cache_clear('');
   }
}
static void sync_wc_option(VS_LANGUAGE_OPTIONS &langOptions,_str epackage,_str profileName,_str name) {

    bool apply;
    _str  value = _plugin_get_property(epackage, profileName, name,'', apply);
    if (!apply) {
        _LangOptionsSetProperty(langOptions, name, "-1");
    } else {
        int status;
        if (isinteger(value) && value>= 0) {
           _LangOptionsSetProperty(langOptions, name, value);
        }
    }
}
static void sync_quote_option(VS_LANGUAGE_OPTIONS &langOptions,_str epackage,_str profileName,_str name) {
    bool apply;
    _str value = _plugin_get_property(epackage, profileName, name,'', apply);
    //if (!apply) {
    //    syncLangSetProperty(langOptions.m_properties, name, "1");
    //} else {
        int status;
        if (isinteger(value) && value>=0) _LangOptionsSetProperty(langOptions, name, value);
    //}
}
static _str  get_pointer_style(VS_LANGUAGE_OPTIONS &langOptions,_str epackage, _str profileName)
{
   _str ts = _plugin_get_property(epackage, profileName,"sp_ptr_between_type_and_star"/*VSCFGP_BEAUTIFIER_SP_PTR_BETWEEN_TYPE_AND_STAR*/);
   _str  sv = _plugin_get_property(epackage, profileName, "sp_ptr_between_star_and_id" /*VSCFGP_BEAUTIFIER_SP_PTR_BETWEEN_STAR_AND_ID*/);
   if (!length(ts) || !length(sv)) {
       return 0;
   }
   if (sv:!="0") {
       if (ts:!="0") {
         return BES_SPACE_SURROUNDS_POINTER;
      } else {
         return BES_SPACE_AFTER_POINTER;
      }
   } else {
       if (ts:!="0") {
           return 0;
       }
       return 0;
   }
}
void _LangOptionsApplyOverrides(VS_LANGUAGE_OPTIONS &langOptions,_str lang,_str buf_name) {
   if (_default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
      EDITOR_CONFIG_PROPERITIES ecprops;
      _EditorConfigGetProperties(buf_name,ecprops,lang,_default_option(VSOPTION_EDITORCONFIG_FLAGS));
      if (ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) {
         epackage := vsCfgPackage_for_LangBeautifierProfiles(lang);
         _str profileName=ecprops.m_beautifier_default_profile;
         if (_plugin_has_profile(epackage,profileName)) {
             _str value;
             value = _plugin_get_property(epackage, profileName, "tab_size");
             if (length(value)) _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_TABS, '+':+value);
             value = _plugin_get_property(epackage, profileName, VSLANGPROPNAME_INDENT_WITH_TABS);
             if (length(value)) _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_INDENT_WITH_TABS,value);
             value = _plugin_get_property(epackage, profileName, LOI_SYNTAX_INDENT);
             if (length(value)) _LangOptionsSetProperty(langOptions,LOI_SYNTAX_INDENT, value);

             // HTML/XML specific properties
             sync_wc_option(langOptions, epackage, profileName, LOI_TAG_CASE);
             sync_wc_option(langOptions, epackage, profileName, LOI_ATTRIBUTE_CASE);
             sync_wc_option(langOptions, epackage, profileName, LOI_WORD_VALUE_CASE);
             sync_wc_option(langOptions, epackage, profileName, LOI_HEX_VALUE_CASE);

             // quotestyle properties don't map that well. If they had apply, they would map better.
             sync_quote_option(langOptions, epackage, profileName, LOI_QUOTE_WORD_VALUES);
             sync_quote_option(langOptions, epackage, profileName, LOI_QUOTE_NUMBER_VALUES);

             // VBScript, Ada
             sync_wc_option(langOptions, epackage, profileName, LOI_KEYWORD_CASE);

             // Brace-style language properties C++

             value = _plugin_get_property(epackage, profileName, "braceloc_if");
             if (length(value)) _LangOptionsSetProperty(langOptions,LOI_BEGIN_END_STYLE, value);
             _str  be_style=value;

             value = _plugin_get_property(epackage, profileName, "sppad_if_parens");
             if (length(value)) _LangOptionsSetProperty(langOptions,LOI_PAD_PARENS, value);
             value = _plugin_get_property(epackage, profileName, "sp_if_before_lparen");
             if (length(value)) _LangOptionsSetProperty(langOptions,LOI_NO_SPACE_BEFORE_PAREN, value:=="0"?"1":"0");

             value = _plugin_get_property(epackage, profileName, LOI_INDENT_CASE_FROM_SWITCH);
             if (length(value)) _LangOptionsSetProperty(langOptions,LOI_INDENT_CASE_FROM_SWITCH, value);

             value = _plugin_get_property(epackage, profileName, LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS);
             if (length(value)) _LangOptionsSetProperty(langOptions,LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS, value);

             value = _plugin_get_property(epackage, profileName, "braceloc_fun");
             if (!length(value)) value = be_style;
             // Convert to boolean.
             if (value:!="0") value = "1";
             if (length(value)) _LangOptionsSetProperty(langOptions,LOI_FUNCTION_BEGIN_ON_NEW_LINE, value);

             value = _plugin_get_property(epackage, profileName, LOI_CUDDLE_ELSE);
             if (length(value)) _LangOptionsSetProperty(langOptions,LOI_CUDDLE_ELSE, value);

             value = get_pointer_style(langOptions, epackage, profileName);
             if (length(value)) _LangOptionsSetProperty(langOptions,LOI_POINTER_STYLE, value);
         }
      } else {
         if (ecprops.m_property_set_flags & ECPROPSETFLAG_INDENT_WITH_TABS) {
            _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_INDENT_WITH_TABS, ecprops.m_indent_with_tabs);
            //_LangOptionsSetPropertyp_indent_with_tabs=ecprops.m_indent_with_tabs;
         }
         if (ecprops.m_property_set_flags & ECPROPSETFLAG_SYNTAX_INDENT) {
            _LangOptionsSetProperty(langOptions,LOI_SYNTAX_INDENT, ecprops.m_syntax_indent);
            //p_SyntaxIndent=ecprops.m_syntax_indent;
         }
         if (ecprops.m_property_set_flags & ECPROPSETFLAG_TAB_SIZE) {
            _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_TABS, ecprops.m_tab_size);
            //p_tabs="+"ecprops.m_tab_size;
         }
      }
   }

}
/**
 * Sets the language specific information such as tabs, margins, color coding, etc. to the
 * specified language options.
 *
 * @param lang                Optional language ID (see {@link p_LangId})
 * @param bypass_buffer_setup If true, only set the language name and ID but do not copy
 *                            in language specific settings, such as tabs, or indent.
 * @param map_xml_files       Attempt to map XML files and HTML/JSP files to locate DTD,
 *                            Scheme, or JSP tag libraries in order to identify custom
 *                            tags.
 * @param called_from_mapxml_create_tagfile Specifies whether or not _SetEditorLanguage
 *                                          was called from mapxml_create_tagfile. This is
 *                                          for a specific "recursion too deep" error in
 *                                          Eclipse.
 * @param force_select_mode_cb If true, force call to _CallbackSelectMode to set lang mode.
 *
 * @see p_LangId
 * @see p_mode_name
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
void _SetEditorLanguage(_str lang="",
                        bool bypass_buffer_setup=false,
                        bool map_xml_files=false, bool called_from_mapxml_create_tagfile=false,
                        bool force_select_mode_cb=false,
                        bool preserve_hex_mode=false)
{
   large_file_editing_msg := "";
   /*
      Typically better NOT to set the cache size for the following reasons:
         * If the buffer cache size isn't large enough to fit the entire file in memory,
           there is no benefit for typical operations. Operations which cause a spill
           file to be generated (like a large edit) will see a performance increase
           when an optimal cache size is chosen.
         * Setting a large cache size often causes the OS to do swapping which makes
           operations MUCH slower. Best not to try to guess what the cache should be.
           Let users trial an error the buffer cache size.
         * If we guess wrong, SlickEdit may run out of memory and crash. This problem
           was reproduced on HPUX choosing a buffer cache size of 1/4 of availble memory.
   */
   //auto_set_buffer_cache(large_file_editing_msg);

   // Hook for site-specific file mode selection.
   // Here we call a user-defined userSelectEditMode() global function or
   // command. The function should return 0 for a successful override and
   // 1 to ignore and use the default _SetEditorLanguage().
   status := 0;
   index := 0;
   len := 0;
   selmodcb_index := find_index("userSelectEditorLanguage",PROC_TYPE|COMMAND_TYPE);
   if (!index_callable(selmodcb_index)) {
      selmodcb_index = find_index("userSelectEditMode",PROC_TYPE|COMMAND_TYPE);
   }
   if (index_callable(selmodcb_index)) {
      if (!gInSelEditModeCallback) {
         gInSelEditModeCallback = 1; // prevent from recursion
         status = call_index(lang,bypass_buffer_setup,selmodcb_index);
         gInSelEditModeCallback = 0; // clear recursion
         if (!status) return;
      }
   }
   if (isEclipsePlugin() && !called_from_mapxml_create_tagfile) {
      map_xml_files = true;
   }
   //bypass_buffer_setup=(arg(2)!="" && arg(2));
   _str keys=def_keys;
   buf_name := "";

   if ( lang!="" ) {
      if ( substr(lang,1,length(VSLANGUAGE_NOTSUPPORTEDPREFIX)):==VSLANGUAGE_NOTSUPPORTEDPREFIX ) {
         // This specifically fixes the problem of switching to/from
         // command/insert mode in vi emulation, where
         // _SetEditorLanguage() is called with p_LangId.
         // We put the fix here instead of in vi_switch_mode() in case a
         // situation arises in future where we want to pass in the
         // language explicitly.
         lang=substr(lang,length(VSLANGUAGE_NOTSUPPORTEDPREFIX)+1);
      }
      buf_name="";
   } else {
      buf_name=p_buf_name;

      // check for CVS backup file, get the real extension, not
      // the revision number
      just_file_name := _strip_filename(p_buf_name,'p');
      while (isnumber(lang) && substr(just_file_name,1,2)==".#") {
         just_file_name=_strip_filename(just_file_name,'e');
      }
   }

   // _Filename2LangId calls the suffix functions and
   // _ext_Filename2LangId callbacks, so we do not have to do it here.
   setup_index := 0;
   if (lang == "") {
      if (!bypass_buffer_setup) {
         p_AutoSelectLanguage = false;
      }
      lang = _Filename2LangId(buf_name,(p_encoding_set_by_user<0)?0:F2LI_NO_CHECK_BINARY_DATA);
   }
   if (!_LangIsDefined(lang)) {
      lang="fundamental";
   }
   if (p_buf_size>def_use_fundamental_mode_ksize*1024) {
      if (lang!="fundamental" && lang!='binary' && lang!="") {
         if (large_file_editing_msg) {
            large_file_editing_msg:+="\n";
         }
         large_file_editing_msg:+="Plain Text mode chosen for better performance";
         //large_file_editing_msg="Buffer cache size automatically increased";
         lang="fundamental";
      }
   }
   if (p_buf_size>def_use_undo_ksize*1024) {
      if (large_file_editing_msg) {
         large_file_editing_msg:+="\n";
      }
      large_file_editing_msg:+="Undo turned off for better performance";
      p_undo_steps=0;
   }

   VS_LANGUAGE_OPTIONS langOptions;
   _GetDefaultLanguageOptions(lang, langOptions);
   if ( !bypass_buffer_setup ) {
      if (_default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
         _LangOptionsApplyOverrides(langOptions,lang,p_buf_name);
      }
      p_mode_eventtab=_default_keys;
      p_SyntaxIndent = _LangOptionsGetPropertyInt32(langOptions,LOI_SYNTAX_INDENT); //LanguageSettings.getSyntaxIndent(lang);

      if (p_mdi_child) {
         p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(lang);
      }

      p_ModifyFlags &= ~MODIFYFLAG_CONTEXT_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_STATEMENTS_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_LOCALS_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_CONTEXTWIN_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_FCTHELP_UPDATED;
      ++p_LastModified;
   }

   {
      extensionSupported := true;
      // Note that we look up the index in the names table again.
      // This is a better API since we are independant of implementation.
      //say("selmode lexer_name="lexer_name" cf="color_flags);
      if ( !bypass_buffer_setup ) {
         //IF .editorconfig file support is enabled
         p_mode_name=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_MODE_NAME);
         p_LangId=lang;
         p_SoftWrap=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_SOFT_WRAP,def_SoftWrap?1:0) != 0;
         if (p_SoftWrap && p_buf_size>def_use_softwrap_ksize*1024) {
            if (large_file_editing_msg) {
               large_file_editing_msg:+="\n";
            }
            large_file_editing_msg:+="view line numbers turned off for better performance";
            p_SoftWrap=false;
         }
         // Don't automatically turn on spell checking for really large files.
         spell_check_while_typing := _LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING,0)!=0 && p_buf_size<=def_use_fundamental_mode_ksize*1024;
         _spell_check_while_typing_init(spell_check_while_typing,_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS));
         //p_spell_check_while_typing=spell_check_while_typing;
         //p_spell_check_while_typing_elements=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ADD_ELEMENTS);

         p_SoftWrapOnWord=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_SOFT_WRAP_ON_WORD,def_SoftWrapOnWord?1:0)!=0;

         p_begin_end_style = _LangOptionsGetPropertyInt32(langOptions,LOI_BEGIN_END_STYLE,0);
         p_indent_case_from_switch = (_LangOptionsGetPropertyInt32(langOptions,LOI_INDENT_CASE_FROM_SWITCH,0) != 0);
         p_no_space_before_paren = (_LangOptionsGetPropertyInt32(langOptions,LOI_NO_SPACE_BEFORE_PAREN,0) != 0);
         p_pad_parens = (_LangOptionsGetPropertyInt32(langOptions,LOI_PAD_PARENS,0) != 0);
         p_pointer_style = _LangOptionsGetPropertyInt32(langOptions,LOI_POINTER_STYLE,0);
         p_function_brace_on_new_line = (_LangOptionsGetPropertyInt32(langOptions,LOI_FUNCTION_BEGIN_ON_NEW_LINE,0)!= 0);
         p_keyword_casing = _LangOptionsGetPropertyInt32(langOptions,LOI_KEYWORD_CASE,0);

         p_tag_casing = _LangOptionsGetPropertyInt32(langOptions,LOI_TAG_CASE,0);
         p_attribute_casing = _LangOptionsGetPropertyInt32(langOptions,LOI_ATTRIBUTE_CASE,0);
         p_value_casing = _LangOptionsGetPropertyInt32(langOptions,LOI_WORD_VALUE_CASE,0);
         p_hex_value_casing = _LangOptionsGetPropertyInt32(langOptions,LOI_HEX_VALUE_CASE,0);

         p_hex_Nofcols= _LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_HEX_NOFCOLS,4);
         p_hex_bytes_per_col= _LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_HEX_BYTES_PER_COL,4);

         p_show_minimap = _LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_SHOW_MINIMAP,0)!=0;
         int LineNumbersLen=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_LINE_NUMBERS_LEN,1);
         int LineNumbersFlags=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_LINE_NUMBERS_FLAGS,0);
         checkLineNumbersLengthForISPF(LineNumbersFlags, LineNumbersLen);
         if (LineNumbersFlags & LNF_ON) {
            if (LineNumbersFlags & LNF_AUTOMATIC) {
               // we want automatic mode...
               p_LCBufFlags|=(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
            } else {
               p_LCBufFlags&=~VSLCBUFFLAG_LINENUMBERS_AUTO;
               p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS;
            }
         } else {
            p_LCBufFlags&=~(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
         }
         p_line_numbers_len=LineNumbersLen;
         if (!isinteger(def_use_view_line_numbers_ksize)) {
            def_use_view_line_numbers_ksize=100000;
         }
         if (p_buf_size>def_use_view_line_numbers_ksize*1024) {
            if (p_LCBufFlags&(VSLCBUFFLAG_LINENUMBERS | VSLCBUFFLAG_LINENUMBERS_AUTO)) {
               // if either one of these is on, turn them off!
               p_LCBufFlags&=~(VSLCBUFFLAG_LINENUMBERS | VSLCBUFFLAG_LINENUMBERS_AUTO);
            }
         }
         if (!isinteger(def_use_minimap_ksize)) {
            def_use_minimap_ksize=100000;
         }
         if (p_buf_size>def_use_minimap_ksize*1024) {
            p_show_minimap=false;
         }

         p_color_flags=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_COLOR_FLAGS,CLINE_COLOR_FLAG);
         p_lexer_name=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_LEXER_NAME);
         if (p_lexer_name!="") {
            p_color_flags|=LANGUAGE_COLOR_FLAG;
         }
         // Make sure color coding is off for huge files!
         if (p_buf_size>def_use_fundamental_mode_ksize*1024) {
            p_color_flags&= ~LANGUAGE_COLOR_FLAG;
         }
         hex_mode:=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_HEX_MODE,HM_HEX_OFF);
         if (!preserve_hex_mode) {
            p_hex_mode=HM_HEX_OFF;
            if (hex_mode==HM_HEX_ON) {
               hex();
            } else if (hex_mode==HM_HEX_ON) {
               linehex();
            }

         }
         if ( ! read_format_line() ) {
            svalue:=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_TABS);
            if ( svalue!="" ) p_tabs=svalue;
            _str margins=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_MARGINS);
            if ( margins!="" ) p_margins=margins;

            p_word_wrap_style=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_WORD_WRAP_FLAGS,STRIP_SPACES_WWS);
            p_indent_with_tabs=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_INDENT_WITH_TABS,0)!=0;

            int show_tabsnl_flags=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS,DEFAULT_SPECIAL_CHARS);
            if ( keys=="vi-keys" ) {
               //show_tabsnl_flags=0;
               _str _show_tabsnl=__ex_set_list();
               if ( _show_tabsnl!="" && _show_tabsnl>0 ) {
                  show_tabsnl_flags=SHOWSPECIALCHARS_TABS|SHOWSPECIALCHARS_NLCHARS;
               }
            }
            p_ShowSpecialChars |= show_tabsnl_flags;
            //p_show_tabs=langOptions.ShowSpecialChars;
            p_indent_style=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_INDENT_STYLE,INDENT_AUTO);
            p_word_chars=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_WORD_CHARS);
            p_AutoLeftMargin=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_AUTO_LEFT_MARGIN,0)!=0;
            p_FixedWidthRightMargin=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN,0);

            // update all the indent settings so that the user will immediately have tabs
            // turned on if necessary
            // check for temp editor - we don't want to be running this during tagging, multi-file
            // find, multi-file replace, etc.
            if (!p_IsTempEditor) {
               if (areAdaptiveFormattingTabSettingsRequiredImmediately(AFF_TABS | AFF_INDENT_WITH_TABS | AFF_SYNTAX_INDENT)) {
                  updateAdaptiveFormattingSettings(AFF_TABS | AFF_INDENT_WITH_TABS | AFF_SYNTAX_INDENT, false);
               }
            }
         } else {
            // we don't want to overwrite format line settings, because those are hard-core
            // check for temp editor - we don't want to be running this during tagging, multi-file
            // find, multi-file replace, etc.
            if (!p_IsTempEditor) {
               if (areAdaptiveFormattingTabSettingsRequiredImmediately(AFF_SYNTAX_INDENT)) {
                  updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT, false);
               }
            }

         }
         int TruncateLength=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_TRUNCATE_LENGTH,0);
         if (TruncateLength>=0) {
            p_TruncateLength=TruncateLength;
         } else {
            len=p_MaxLineLength-8;
            if (len>=2) {
               p_TruncateLength=len;
            }
         }
         typeless bs,be;
         parse _LangOptionsGetProperty(langOptions,VSLANGPROPNAME_BOUNDS) with bs be .;
         if (isinteger(bs)) {
            p_BoundsStart=bs;
         }
         if (isinteger(be)) {
            p_BoundsEnd=be;
         }
         int AutoCaps=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_AUTO_CAPS,1);
         if (AutoCaps==CM_CAPS_AUTO) {
            p_caps=_GetCaps()!=0;
         } else {
            p_caps=AutoCaps!=0;
         }
         if (index_callable(find_index("ispf_adjust_lc_bounds",PROC_TYPE))) {
            ispf_adjust_lc_bounds();
         }

         // keyboard callbacks are instantiated in specific order here
         _kbd_remove_callback(-1);  // clear all registered callbacks
         setOvertypeMarkerCallbacks();
         setEventUICallbacks();
         setAutoBracketCallback(lang);
      }
      _str szLexerName=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_LEXER_NAME);
      if (map_xml_files && _LanguageInheritsFrom("xml") && substr(szLexerName,1,3)=="XML") {
         _mapxml_init_file();
      }

      if (map_xml_files && _LanguageInheritsFrom("html") && substr(szLexerName,1,4)=="HTML") {
         _mapjsp_init_file(p_window_id);
      }
      // Call TextChange callbacks.  This updates the color coding and forces long lines
      // to wrap.  Need this here for auto restore and it is probably best to wrap long lines
      // right after opening a file.
      _updateTextChange();

      _str szEventTableName=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_EVENTTAB_NAME);
      in_process := (szEventTableName=="process-keys");
      in_fileman := (szEventTableName=="fileman-keys");
      in_grep := (szEventTableName=="grep-keys");
      vi_mode := "";
      vi_idx := find_index("vi-get-vi-mode",COMMAND_TYPE|PROC_TYPE);
      if ( vi_idx && index_callable(vi_idx) && keys=="vi-keys" && !in_process && !in_fileman && !in_grep ) {
         vi_mode=upcase(strip(vi_get_vi_mode()));
         if ( vi_mode=="C" ) {
            // Don't switch out of command mode!
            index=find_index("vi-command-keys",EVENTTAB_TYPE);
            if ( !index ) {
               message('Could not find event-table: "vi-command-keys".  Type any key');
               get_event();
            }
            // Toggle back to character-insert mode if necessary
            if ( !_insert_state() ) {
               _insert_toggle();
            }
            // Make sure the cursor is on a real character for each buffer
            if ( p_col>_text_colc() ) {
               p_col= _text_colc();
            }
         } else if (vi_mode == "V") {
            index=find_index("vi-visual-keys",EVENTTAB_TYPE);
            if ( !index ) {
               message('Could not find event-table: "vi-visual-keys".  Type any key');
               get_event();
            }
         } else {
            if (szEventTableName!="") index=_eventtab_get_mode_keys(szEventTableName);
         }
      } else {
         if (szEventTableName!="") index=_eventtab_get_mode_keys(szEventTableName);
      }
      if ( index ) {
         p_mode_eventtab=index;
      } else {
         p_mode_eventtab=_default_keys;
      }
   }
   if (large_file_editing_msg!="") {
      //say(large_file_editing_msg);
      _ActivateAlert(ALERT_GRP_EDITING_ALERTS,ALERT_LARGE_FILE_SUPPORT,large_file_editing_msg);
      //sticky_message(msg);
   }

   if ( !bypass_buffer_setup || force_select_mode_cb ) {
      //p_CallbackBufSetLineColor=0;
      _CallbackSelectMode(p_window_id,lang);
   }

   // Hack to use consitent line endings for binary mode.
   if (lang == "binary") {
      //p_hex_mode=HM_HEX_OFF;
      //hex();
      p_newline = "\n"; // force consistent line endings for binary mode
   }

   if (def_use_390_display_translations) {
      if (g390DisplayTranslationTable=="") {
         Set390DisplayTranslationTable(g390DisplayTranslationTable);
      }
      p_display_xlat=g390DisplayTranslationTable;
   }
}
/**
 * Sets the language specific information such as tabs, margins,
 * color coding, etc. to the specified language options.
 *
 * @param lang                Optional language ID (see {@link p_LangId})
 * @param bypass_buffer_setup If true, only set the language name
 *                            and ID but do not copy in language
 *                            specific settings, such as tabs, or indent.
 * @param map_xml_files       Attempt to map XML files and HTML/JSP files
 *                            to locate DTD, Scheme, or JSP tag libraries
 *                            in order to identify custom tags.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 * @deprecated Use {@link _SetEditorLanguage()}.
 */
void select_edit_mode(_str lang="",
                      bool bypass_buffer_setup=false,
                      bool map_xml_files=false)
{
   _SetEditorLanguage(lang,bypass_buffer_setup,map_xml_files);
}

/**
 * In ISPF emulation, the prefix area is used for line commands.  If the prefix
 * area is too narrow, then line numbers are not displayed properly.  This
 * method checks for the ISPF emulation and makes the necessary adjustment to
 * the line numbers length value sent in.
 *
 * @param lnl           line numbers length to possibly adjust
 */
void checkLineNumbersLengthForISPF(int &flags, int &lnl)
{
   if (def_keys == "ispf-keys") {
      // in ISPF mode, we don't want a prefix area narrower than the default...
      defLNL := _default_option(VSOPTION_LINE_NUMBERS_LEN);
      if (lnl < defLNL) lnl = defLNL;

      if (flags & LNF_AUTOMATIC) flags &= ~LNF_AUTOMATIC;
   }
}

static void Set390DisplayTranslationTable(_str &table)
{
   table="";
   int i;
   for (i=0;i<256;++i) {
      _str ch=_chr(i);
      if (i==94) {
         ch=_chr(172);
      }
      table :+= ch;
   }
}
/**
 * Switches to fundamental mode key bindings.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void fundamental_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _SetEditorLanguage("fundamental");
}
/**
 * Switches to binary mode key bindings, and switches to hex mode.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void binary_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _SetEditorLanguage("binary");
}
/**
 * Determines action taken when syntax indenting is on and the ENTER key is
 * pressed and the current line starts with a language key word such as IF,
 * WHILE, FOR etc.  If a new line is inserted, it is indented by the
 * <i>indent_amount</i> given.  The optional <i>column</i> parameter may be
 * given to specify an exact column for the cursor to be placed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void indent_on_enter(int syntax_indent, ...)
{
   _str name=name_on_key(ENTER);
   if ( _will_split_insert_line() ) {
      if ( _expand_tabsc(1,p_col-1)=="" && _expand_tabsc()!="") {
         _first_non_blank();
      }
      split_insert_line();
      typeless col1,col2;
      if ( arg(2)!="" ) {
         col1=arg(2);
         col2=p_col;
      } else {
         col2=p_col;
         col1=p_col+syntax_indent;
      }
      _str result=_expand_tabsc(col2,-1,'S');
      if ( result:=="" && !LanguageSettings.getInsertRealIndent(p_LangId)) {
         // if our line is empty, then we just insert a blank line
         result="";
      } else {
         result = indent_string(col1-1):+result;
      }
      replace_line(result);
      p_col=col1;
   } else if ( name=="maybe-split-insert-line" && ! _insert_state() ) {
      maybe_split_insert_line();
   } else {
      nosplit_insert_line();
      if ( arg(2)!="" ) {
         p_col=arg(2);
      } else {
         p_col += syntax_indent;
      }
      if ( LanguageSettings.getInsertRealIndent(p_LangId)) {
         get_line(auto line);
         if (line=="") {
            replace_line(indent_string(p_col-1));
         }
      }
   }

}
/**
 * Updates the Line status indicator and displays the number of lines
 * in the current buffer on the message line.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void count_lines() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   /* Force slick to caculate number of lines. */
   message(nls("File contains %s lines",p_Noflines));
}

/**
 * A command that operates on a single line in a buffer may be extended to
 * operate on all text boxes including the command line by calling
 * <b>init_command_op</b> before, and <b>retrieve_command_results</b> after the
 * command.  Calls to this function may not be nested.
 *
 * @example
 * <pre>
 * _command upcase_line()
 *       name_info(','VSARG2_REQUIRES_EDITORCTL |VSARG2_TEXT_BOX)
 * {
 *      init_command_op();
 *      get_line(line);replace_line(upcase(line));
 *      retrieve_command_results();
 * }
 * </pre>
 *
 * @categories Command_Line_Functions
 *
 */
void init_command_op()
{
   command_op_wid := "";
   if ( command_state() ) {
      _str line;
      int begin_col;
      int col;
      get_command(line,begin_col,col);
      if( p_object!=OI_COMBO_BOX && p_Password ) {
         line=substr("",1,length(line),"*");
      }
      command_op_wid=p_window_id;
      activate_window(VSWID_RETRIEVE);
      bottom();
      insert_line(line);p_col=col;
      _orig_mark=_duplicate_selection("");
      if ( _command_mark=="" ) {
         _command_mark=_alloc_selection();
         if ( _command_mark>=0 ) {
            _show_selection(_command_mark);
         }
      } else {
         int status=_show_selection(_command_mark);
         // Just incase some body screwed up the mark, lets allocate
         // another
         if (status==INVALID_SELECTION_HANDLE_RC) {
            _command_mark=_alloc_selection();
            _show_selection(_command_mark);
         }
         _deselect();
      }
      if ( begin_col!=col ) {
         if ( _command_mark!="" ) {
            p_col=begin_col;
            _select_char('','cn');
            p_col=col;
            _select_char('','cn');
         }
      }
   }
   _command_op_list="."command_op_wid" "_command_op_list;

}
void retrieve_command_results()
{
   typeless command_op_wid;
   parse _command_op_list with command_op_wid _command_op_list;
   command_op_wid=strip(command_op_wid,'B','.');
   if ( command_op_wid!="" ) {
      _command_mark=_duplicate_selection('');
      begin_col := p_col;
      col := p_col;
      int buf_id;
      get_line(auto line);
      if ( _select_type()!="" ) {
         if ( _select_type()=="LINE" ) {
            begin_col=1;col=length(line)+1;
         } else {
            _get_selinfo(begin_col,col,buf_id,_command_mark);
            if (substr(_select_type('','P'),2,1)=='E') {
               int temp=begin_col;
               begin_col=col;
               col=temp;
            }
         }
      }
      _delete_line();
      if ( _orig_mark!="" ) {
         _show_selection(_orig_mark);
      }
      p_window_id=command_op_wid;
      if (line!=p_text ) {
         if( p_object!=OI_COMBO_BOX && p_Password ) {
            if( verify(line,"*") ) {
               // There is something other than all '*', so allow it
               set_command(line,begin_col,col);
            }
         } else {
            set_command(line,begin_col,col);
         }
      } else {
         _set_sel(begin_col,col);
      }
   }
}

bool parseoption(var cmdline,_str optionletter)
{
   int i=pos("-":+upcase(optionletter),upcase(cmdline));
   if ( ! i ) {
      i=pos("+":+upcase(optionletter),upcase(cmdline));
   }
   if ( i && substr(cmdline,i+length(optionletter)+1,1)=="" && (i==1 || substr(cmdline,i-1,1)=="") ) {
      cmdline=substr(cmdline,1,i-1):+substr(cmdline,i+length(optionletter)+1);
      return(true);
   } else {
      return(false);
   }
}
void _cc_reload_color_coding_profile(_str epackage,_str profileName,bool doDelete,typeless user_info) {
   _clex_load(profileName);

}
void _convert_vlx_file_to_profile(_str vlx_filename,_str only_convert_profile_name="") {
   module := "convertvlx2cfgxml.ex";
   filename := _macro_path_search(_strip_filename(substr(module,1,length(module)-1), "P"));
   //_message_box("filename="filename);
   if (filename=="") {
      module="convertvlx2cfgxml.e";
      filename = _macro_path_search(_strip_filename(substr(module,1,length(module)), "P"));
      //_message_box("h2 filename="filename);
      if (filename=="") {
         filename="convertvlx2cfgxml";
      }
   }
   if (only_convert_profile_name!="") {
      only_convert_profile_name=" "_maybe_quote_filename(only_convert_profile_name);
   }
   shell(_maybe_quote_filename(filename)" "_maybe_quote_filename(vlx_filename):+only_convert_profile_name);
}
/**
 * Loads color coding lexer definition file specified.  If <i>filename</i> is
 * not specified and the current buffer has a ".cfg.xml" or
 * ".vlx" extension, it is loaded. Otherwise a Standard Open
 * File dialog box is displayed which allows you to
 * select a color coding definition file to load.  See
 * <b>Color Coding</b> for information on syntax of lexer
 * definitions.
 *
 * @return  Returns 0 if successful.
 *
 * @see color_toggle
 * @see color_modified_toggle
 *
 * @categories File_Functions
 */
_command int cload(_str filename="",_str only_convert_profile_name="") name_info(FILE_ARG','VSARG2_CMDLINE)
{
   int was_recording=_macro();
   wid := p_window_id;
   p_window_id=_mdi.p_child;
   _str default_buf_name=(_no_child_windows())?"":p_buf_name;
   if (filename=="") {
      filename=default_buf_name;
   }
   filename=strip(filename,'B','"');
   if ( filename=="<" || (filename=="" && _no_child_windows()) ||
        !(p_HasBuffer && (endsWith(filename,VSCFGFILEEXT_CFGXML,false,_fpos_case) || _file_eq(_get_extension(filename),"vlx")))
      ) {
      filename=_OpenDialog("-modal",
                           "Open Color Coding Config File", "*.cfg.xml",
                           "Color Coding Config Files (*.cfg.xml;*.vlx),All Files "ALLFILES_RE")",
                           //"Open Color Coding XML Config File", "*.cfg.xml",
                           //"XML Config Files (*.cfg.xml),All Files "ALLFILES_RE")",
                           OFN_FILEMUSTEXIST,
                           "",         // Default extensions
                           "",         // Initial filename
                           "",         // Initial directory
                           "colorcoding_profile_cfgxml"       // Retrieve name
                          );
      if (filename=="") {
         p_window_id=wid;
         return(COMMAND_CANCELLED_RC);
      }
   }
   int status;
   if (filename=="" || (p_HasBuffer && _file_eq(p_buf_name,absolute(filename)))) {
      if ( p_modify ) {
         status=save();
         if ( status ) {
            p_window_id=wid;
            return(status);
         }
      }
      filename=default_buf_name;
   }
   filename=strip(filename,'B','"');
   if (_file_eq(_get_extension(filename),'vlx')) {
      // Convert vlx to profile(s)
      _convert_vlx_file_to_profile(filename,only_convert_profile_name);
      return 0;
   }
   // Check if this profile has the right name.
   handle:=_xmlcfg_open(filename,status);
   if (handle<0) {
      _message_box(nls("Unable open XML file '%s'",filename));
      p_window_id=wid;
      return(status);
   }
   // Could be loading profile(s) from user.cfg.xml.
   // Look profile anme that starts with "colorcoding_profiles."
   first_profile_node:=_xmlcfg_find_simple(handle,'/options/profile[contains(@n,"^'_escape_re_chars(VSCFGPACKAGE_COLORCODING_PROFILES:+VSXMLCFG_FILESEP)'","r")]');
   if (first_profile_node<0) {
      int profile_node=_xmlcfg_set_path(handle,"/options/profile");
      _str name=_xmlcfg_get_attribute(handle,profile_node,VSXMLCFG_PROFILE_NAME);
      _xmlcfg_close(handle);
      if (name=="") {
         _message_box(nls("Missing /options/profile element or profile 'n' attribute"));
         p_window_id=wid;
         return(INVALID_ARGUMENT_RC);
      }
      _message_box(nls("No profile found in package '%s'",VSCFGPACKAGE_COLORCODING_PROFILES));
      p_window_id=wid;
      return(INVALID_ARGUMENT_RC);
   }
   /*if (!beginsWith(name,VSCFGPACKAGE_COLORCODING_PROFILES,false,'i')) {
      _message_box(nls("Profile path needs to be '%s'",VSCFGPACKAGE_COLORCODING_PROFILES));
      p_window_id=wid;
      return(INVALID_ARGUMENT_RC);
   } */
   _plugin_import_profiles(filename,VSCFGPACKAGE_COLORCODING_PROFILES,0,_cc_reload_color_coding_profile);

   _macro('m',was_recording);
   _macro_delete_line();
   _macro_call("cload",filename);
   if (status) {
      _message_box(nls("Unable to load color lexer file '%s'",filename)"\n\n"get_message(status));
      p_window_id=wid;
      return(status);
   }

   p_window_id=wid;
   return(0);
}
/**
 * Toggles display of modified line coloring on/off.
 *
 * @see color_toggle
 * @see cload
 *
 * @categories Buffer_Functions
 */
_command color_modified_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_color_flags&MODIFY_COLOR_FLAG) {
      p_color_flags&=~MODIFY_COLOR_FLAG;
   } else {
      p_color_flags|=MODIFY_COLOR_FLAG;
   }
}
_command color_language_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_color_flags&LANGUAGE_COLOR_FLAG) {
      p_color_flags&=~LANGUAGE_COLOR_FLAG;
   } else {
      p_color_flags|=LANGUAGE_COLOR_FLAG;
   }
}
int _OnUpdate_view_line_numbers_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (p_LCBufFlags&(VSLCBUFFLAG_LINENUMBERS | VSLCBUFFLAG_LINENUMBERS_AUTO)) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
/**
 * Toggles line number display on/off.  This command does more than just set the
 * {@link p_line_numbers_len} property.
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @return
 * @see view_spaces_toggle
 * @see view_tabs_toggle
 * @see view_nlchars_toggle
 * @see p_ShowSpecialChars
 * @see line_numbers_set_width
 * @see line_numbers_show_colon
 */
_command view_line_numbers_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   if (p_LCBufFlags&(VSLCBUFFLAG_LINENUMBERS | VSLCBUFFLAG_LINENUMBERS_AUTO)) {
      // if either one of these is on, turn them off!
      p_LCBufFlags&=~(VSLCBUFFLAG_LINENUMBERS | VSLCBUFFLAG_LINENUMBERS_AUTO);
   } else {
      // use the language settings to determine whether we want fixed width
      //  or automatic line numbers
      width := LanguageSettings.getLineNumbersLength(p_LangId);
      flags := LanguageSettings.getLineNumbersFlags(p_LangId);

      // line numbers might be turned off for the language, so let's turn them on
      flags |= LNF_AUTOMATIC;

      // check for ISPF
      checkLineNumbersLengthForISPF(flags, width);

      if (flags & LNF_AUTOMATIC) {      // automatic!
         p_LCBufFlags|=(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
      } else {
         p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS;
      }

      p_line_numbers_len=width;
   }

   if (isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_LINE_NUMS_TOGGLE);
   }
}

/**
 * Determines whether line numbers display a trailing colon or not.
 * @categories Miscellaneous_Functions
 * @see view_line_numbers_toggle
 * @see line_numbers_set_width
 */
_command void line_numbers_show_colon(_str showColon="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   typeless number=0;
   showColon=prompt(showColon,"",number2yesno(_default_option(VSOPTION_LCNOCOLON)));
   if ( setyesno(number,showColon) ) {
      message("Invalid option");
      return;
   }
   _default_option(VSOPTION_LCNOCOLON, !number);
   p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS;
}

/**
 * Determines the number of characters to display for line numbers,
 * including the trailing colon.
 * @categories Miscellaneous_Functions
 * @see view_line_numbers_toggle
 * @see line_numbers_show_colon
 */
_command void line_numbers_set_width(_str numChars="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   numChars=prompt(numChars,"",_default_option(VSOPTION_LINE_NUMBERS_LEN));
   if (!isuinteger(numChars)) {
      message("Invalid argument");
      return;
   }
   _default_option(VSOPTION_LINE_NUMBERS_LEN, numChars);
   p_line_numbers_len = (int) numChars;
   p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS;
}

int _OnUpdate_view_specialchars_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()/* || target_wid.p_UTF8*/) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if ((target_wid.p_ShowSpecialChars & (SHOWSPECIALCHARS_NLCHARS|SHOWSPECIALCHARS_TABS|SHOWSPECIALCHARS_SPACES|SHOWSPECIALCHARS_CTRL_CHARS))==
       (SHOWSPECIALCHARS_NLCHARS|SHOWSPECIALCHARS_TABS|SHOWSPECIALCHARS_SPACES|SHOWSPECIALCHARS_CTRL_CHARS)) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
/**
 * Toggles display of all special characters such as tabs, spaces, newline and more on/off.
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @return
 * @see view_spaces_toggle
 * @see view_tabs_toggle
 * @see view_nlchars_toggle
 * @see view_line_numbers_toggle
 * @see p_ShowSpecialChars
 */
_command view_specialchars_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   if ((p_ShowSpecialChars & (SHOWSPECIALCHARS_NLCHARS|SHOWSPECIALCHARS_TABS|SHOWSPECIALCHARS_SPACES|SHOWSPECIALCHARS_CTRL_CHARS))==
       (SHOWSPECIALCHARS_NLCHARS|SHOWSPECIALCHARS_TABS|SHOWSPECIALCHARS_SPACES|SHOWSPECIALCHARS_CTRL_CHARS)) {
      p_ShowSpecialChars=0;
   } else {
      p_ShowSpecialChars=SHOWSPECIALCHARS_ALL;
   }
   if (isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_SPECIAL_CHARS_TOGGLE);
   }
   if (!_QReadOnly()) {
      update_format_line();
   }
}
int _OnUpdate_view_nlchars_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()/* || target_wid.p_UTF8*/) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (target_wid.p_ShowSpecialChars & SHOWSPECIALCHARS_NLCHARS) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
/**
 * Toggles newline character display on/off.
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @return
 * @see view_spaces_toggle
 * @see view_tabs_toggle
 * @see view_nlchars_toggle
 * @see view_line_numbers_toggle
 * @see p_ShowSpecialChars
 */
_command view_nlchars_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   p_ShowSpecialChars^=SHOWSPECIALCHARS_NLCHARS;
   if (!_QReadOnly()) {
      update_format_line();
   }
   if (isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_NLCHARS_TOGGLE);
   }
}

int _OnUpdate_view_tabs_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()/* || target_wid.p_UTF8*/) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (target_wid.p_ShowSpecialChars & SHOWSPECIALCHARS_TABS) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
// Shortcut to toggle tabs and spaces
_command view_whitespace_toggle()
{
   view_tabs_toggle();
   view_spaces_toggle();
}
/**
 * Toggles tab display on/off.
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @return
 * @see view_spaces_toggle
 * @see view_tabs_toggle
 * @see view_nlchars_toggle
 * @see view_line_numbers_toggle
 * @see p_ShowSpecialChars
 */
_command view_tabs_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   p_ShowSpecialChars^=SHOWSPECIALCHARS_TABS;
   if (!_QReadOnly()) {
      update_format_line();
   }
   if (isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_TABCHARS_TOGGLE);
   }
}
int _OnUpdate_view_spaces_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() /*|| target_wid.p_UTF8*/) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (target_wid.p_ShowSpecialChars & SHOWSPECIALCHARS_SPACES) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
/**
 * Toggles space display on/off.
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @return
 * @see view_spaces_toggle
 * @see view_tabs_toggle
 * @see view_nlchars_toggle
 * @see view_line_numbers_toggle
 * @see p_ShowSpecialChars
 */
_command view_spaces_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   p_ShowSpecialChars^=SHOWSPECIALCHARS_SPACES;
   if (!_QReadOnly()) {
      update_format_line();
   }
   if (isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_SPACECHARS_TOGGLE);
   }
}
/**
 * Toggles other control characters display on/off.
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @return
 * @see view_spaces_toggle
 * @see view_tabs_toggle
 * @see view_nlchars_toggle
 * @see view_line_numbers_toggle
 * @see p_ShowSpecialChars
 */
_command view_other_ctrl_chars_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   p_ShowSpecialChars^=SHOWSPECIALCHARS_CTRL_CHARS;
   if (!_QReadOnly()) {
      update_format_line();
   }
}

int _OnUpdate_view_other_ctrl_chars_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (target_wid.p_ShowSpecialChars & SHOWSPECIALCHARS_CTRL_CHARS) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}

int _OnUpdate_view_formfeed_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() /*|| target_wid.p_UTF8*/) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (target_wid.p_ShowSpecialChars & SHOWSPECIALCHARS_FORMFEED) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
/**
 * Toggles formfeed display on/off.
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @return
 * @see view_spaces_toggle
 * @see view_tabs_toggle
 * @see view_nlchars_toggle
 * @see view_line_numbers_toggle
 * @see p_ShowSpecialChars
 */
_command view_formfeed_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   p_ShowSpecialChars^=SHOWSPECIALCHARS_FORMFEED;
   if (!_QReadOnly()) {
      update_format_line();
   }
}
/**
 * Toggles coloring between current line, modified lines, and language specific.
 * Only one coloring style is displayed at a time.
 *
 * @see color_modified_toggle
 * @see cload
 *
 * @categories Buffer_Functions
 */
_command color_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_color_flags&(LANGUAGE_COLOR_FLAG)) {
      p_color_flags|=MODIFY_COLOR_FLAG;
      p_color_flags&=~(LANGUAGE_COLOR_FLAG|CLINE_COLOR_FLAG);
   } else if (p_color_flags&MODIFY_COLOR_FLAG) {
      p_color_flags|=CLINE_COLOR_FLAG;
      p_color_flags&=~(MODIFY_COLOR_FLAG|LANGUAGE_COLOR_FLAG);
   } else {
      p_color_flags|=LANGUAGE_COLOR_FLAG;
      p_color_flags&=~(MODIFY_COLOR_FLAG|CLINE_COLOR_FLAG);
   }
}
void _clex_error(_str msg)
{
   _message_box(msg);
}
/**
 * Command to key in the underscore character.  This can be bound to a
 * key that is easier to type that underscore, for example Ctrl+U.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command keyin_underscore() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   keyin('_');
   last_event('_');
}
/**
 * Command to key in a space character without doing syntax expansion
 * or any other intelligent expansions that are normally done on space.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command keyin_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   keyin(' ');
   last_event(' ');
}
/**
 * Command to key in an enter key without doing syntax indent or any
 * other language specific expansions normally done on enter.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command keyin_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   call_root_key(ENTER);
   last_event(ENTER);
}
//
// This function is global.  However, this function may be
// modified in the future making it incompatible with the
// the current implementation.
//

static const UNIX_ASM_LEXER_LIST= "SP=SPARC RS=PPC PP=PPC LI=Intel IN=INTEL SC=INTEL FR=INTEL UN=INTEL SG=MIPS DE=MIPS MI=MIPS AL=ALPHA NT=Intel WI=Intel HP=HP";

int _OnUpdate_read_only_mode_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (p_readonly_mode) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
void _set_read_only(bool ReadOnly,bool TurnOn_set_by_user=true, bool ChangeDiskAttrs=false, bool ChangeDiskAttrsPrompt=true, bool quiet=false)
{
   oldReadOnly := p_readonly_mode;

   if (ChangeDiskAttrsPrompt) {
      quiet = false;
   }

   if ( ReadOnly ) {
      p_readonly_mode=true;
   } else {
      if (_isdiffed(p_buf_id) && !quiet) {
         _message_box(nls("Cannot change out of read only mode because file is being diffed."));
         return;
      }
      if (debug_is_readonly(p_buf_id) && !quiet) {
         _message_box(nls("Cannot change out of read only mode because file is being debugged."));
         return;
      }
      p_readonly_mode=false;
      if (_DataSetIsFile(p_buf_name) && p_readonly_mode == oldReadOnly && oldReadOnly == true && !quiet) {
         dstext := "Data set";
         if (_DataSetIsMember(p_buf_name)) dstext = "Member";
         _message_box(nls("Can't change %s into read-write mode.\n\n%s is in use.",p_buf_name,dstext));
         return;
      }
   }
   if (TurnOn_set_by_user) {
      p_readonly_set_by_user=true;
   }
   /*
      A windows customer requested updating the read-only attribute on disk.  They were
      using CVS and checking out the files read only.  This seems like a reasonable
      feature to add.  For now, let's wait to add this for Unix until a customer requests
      it.  Our Save As for Unix has a special feature to save a file read only.
      Windows does not have this feature.
   */
   if (ChangeDiskAttrs && oldReadOnly!=p_readonly_mode && !_DataSetIsFile(p_buf_name)) {
      _str attrs=file_list_field(p_buf_name,DIR_ATTR_COL,DIR_ATTR_WIDTH);
      if (attrs!="") {
         bool FileIsReadOnly;
         if (_isUnix()) {
            FileIsReadOnly = pos('w',attrs,1,'i')<=0;
         } else {
            FileIsReadOnly = pos('r',attrs,1,'i')>0;
            // This file has NTFS security options set which make the file read only.
            // Won't be able to change read only attribute.
            if (!FileIsReadOnly && !_WinFileIsWritable(p_window_id)) {
               return;
            }
         }
         _str result=IDYES;
         if (ChangeDiskAttrsPrompt) {
            msg := "";
            if (_isUnix()) {
               msg="Do you want to update the user write permissions on disk for this file?";
            } else {
               if (FileIsReadOnly) {
                  msg = "Do you want to remove the read only attribute on disk for this file?";
               } else {
                  msg = "Do you want to set the read only attribute on disk for this file?";
               }
            }
            if ((p_readonly_mode && !FileIsReadOnly) || (!p_readonly_mode && FileIsReadOnly)) {
               result=_message_box(msg:+"  "_strip_filename(p_buf_name, 'P'),"",MB_YESNOCANCEL);
            }
         }
         if (result==IDYES) {
            if (!p_readonly_mode && FileIsReadOnly && ChangeDiskAttrsPrompt) {
               int ro_status = _readonly_error(0,true,false);
               if (ro_status == COMMAND_CANCELLED_RC) {
                  result = IDCANCEL;
               }
            } else {
               if (_isUnix()) {
                  int status=_chmod(((p_readonly_mode)?"u-w ":"u+w ")_maybe_quote_filename(p_buf_name));
                  if (status && !quiet) {
                     _message_box('Unable to update user write permissions for: '_strip_filename(p_buf_name, 'P'));
                  }
               } else {
                  int status=_chmod(((p_readonly_mode)?"+r ":"-r ")_maybe_quote_filename(p_buf_name));
                  if (status && !quiet) {
                     _message_box('Unable to update read only attribute for: '_strip_filename(p_buf_name, 'P'));
                  }
               }
            }
         }
         if (result==IDCANCEL) {
            p_readonly_mode = oldReadOnly;
         }
      }
   }
}

bool def_rwprompt=true;
bool def_rwchange=true;

/**
 * Toggles read only mode on/off.  While in read only mode, you will not
 * be able to modify the current buffer with a command which modifies
 * text.
 * Available options:
 * <DL compact style="margin-left:20pt;">
 *   <DT>+<i>quiet</i>  <DD>Does not prompt or bring up message
 *   boxes on permissions problems.
 * </DL>
 * @see fundamental_mode
 * @see c_mode
 * @see pascal_mode
 * @see slickc_mode
 * @see fileman_mode
 * @see read_only_mode
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void read_only_mode_toggle(_str opts="") name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   old_readOnly := p_readonly_mode;
   quiet := pos("+quiet", opts) >= 1;

   _set_read_only(!p_readonly_mode,true,def_rwchange,!quiet && def_rwprompt, quiet);
   if (isEclipsePlugin() && old_readOnly != p_readonly_mode) {
      _eclipse_dispatchCommand(ECLIPSE_EV_READ_ONLY_TOGGLE);
   }
}
/**
 * Switches to read only mode.  While in read only mode, you will not be
 * able to modify the current buffer by a command which modifies text.
 * If the <i>off </i> parameter is specified and not "", read only mode is
 * turned off.
 *
 * Available options:
 * <DL compact style="margin-left:20pt;">
 *   <DT>+<i>quiet</i>  <DD>Does not prompt or bring up message
 *   boxes on permissions problems.
 * </DL>
 *
 * @see fundamental_mode
 * @see c_mode
 * @see pascal_mode
 * @see slickc_mode
 * @see fileman_mode
 * @see read_only_mode_toggle
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void read_only_mode(_str opts = "") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   old_readOnly := p_readonly_mode;
   if (arg(1)=="") {
      p_readonly_mode=true;
   } else {
      quiet := pos("+quiet", opts) >= 1;

      _set_read_only(arg(1)!="0", true, false, !quiet, quiet);
   }
   if (isEclipsePlugin() && old_readOnly != p_readonly_mode) {
      _eclipse_dispatchCommand(ECLIPSE_EV_READ_ONLY_TOGGLE);
   }
}

/**
 * Displays a message box indicating that the key pressed is not allowed in
 * "Read only" mode.
 *
 * @see read_only_mode
 *
 * @categories Miscellaneous_Functions
 *
 */
void msg_ro()
{
   popup_message("The key you pressed is not allowed in Read Only mode.");
   //popup_message(nls("The key you pressed is not allowed in %s mode.",p_mode_name))
}

bool _isdiff_form(_str form_name)
{
   switch (form_name) {
   case "_diff_form":
   case "_history_diff_form":
   case "_refactor_results_form":
      return true;
   default:
      break;
   }
   return false;
}
bool _isdiff_editor_window(int buf_id=0)
{
   if ((p_name=="_ctlfile1" || p_name=="_ctlfile2") &&
       (p_parent) && (_isdiff_form(p_parent.p_name))) {
      if (!buf_id || buf_id==p_buf_id) {
         if (!p_edit && p_visible) {//Form not edited, and is visible 10:31am 4/8/1996
            //I hope this does away with the intermittent "You cannot close because
            //file is diffed" messages that we have gotten
            return(true);
         }
      }else{
         _nocheck _control _ctlfile1;
         DIFF_MISC_INFO misc=p_parent._GetDialogInfo(DIFFEDIT_CONST_MISC_INFO,p_parent._ctlfile1);
         if (misc != null) {
            if (!buf_id) buf_id=p_buf_id;
            if (misc.WholeFileBufId1==buf_id ||
                misc.WholeFileBufId2==buf_id) {
               return(true);
            }
         }
      }
   }
   return(false);
}
bool _isdiffed(int buf_id)
{
   // If they did not give us a buffer ID, just check the current editor window.
   if (buf_id == 0) {
      if (!_isEditorCtl(true)) return false;
      return _isdiff_editor_window(p_buf_id);
   }

   // otherwise, look up the buffer user information
   if (buf_id > 0) {
      origWID := p_window_id;
      p_window_id = HIDDEN_WINDOW_ID;
      _safe_hidden_window();
      status := load_files('+bi 'buf_id);
      if (!status) {
         isdiffed := _GetBufferInfoHt(DIFFEDIT_CONST_BUFFER_IS_DIFFED);
         p_window_id = origWID;
         return (isdiffed != null && isdiffed > 0);
      }
      p_window_id = origWID;
      return false;
   }

   // should never get here
   last := _last_window_id();
   for (i:=1; i<=last; ++i) {
      if (!_iswindow_valid(i) || i.p_IsMinimap) continue;
      if (i._isdiff_editor_window(buf_id)) {
         return true;
      }
   }

   // definately not a diff buffer
   return false;
}

// possible filenames for extensionless files in the C standard library
static const LANGEXT_DAT= \
   " __bit_reference" \
   " __config" \
   " __debug" \
   " __functional_03" \
   " __functional_base" \
   " __functional_base_03" \
   " __hash" \
   " __hash_table" \
   " __libcpp_version" \
   " __locale" \
   " __memory" \
   " __mutex_base" \
   " __nullptr" \
   " __split_buffer" \
   " __sso_allocator" \
   " __std_stream" \
   " __string" \
   " __threading_support" \
   " __tree" \
   " __tuple" \
   " __undef_macros" \
   " algorithm" \
   " allocators" \
   " any" \
   " array" \
   " atomic" \
   " bitset" \
   " cassert" \
   " ccomplex" \
   " cctype" \
   " cerrno" \
   " cfenv" \
   " cfloat" \
   " chrono" \
   " cinttypes" \
   " ciso646" \
   " climits" \
   " clocale" \
   " cmath" \
   " codecvt" \
   " complex" \
   " condition_variable" \
   " coroutine" \
   " csetjmp" \
   " csignal" \
   " cstdarg" \
   " cstdbool" \
   " cstddef" \
   " cstdint" \
   " cstdio" \
   " cstdlib" \
   " cstring" \
   " ctgmath" \
   " ctime" \
   " cwchar" \
   " cwctype" \
   " deque" \
   " dynarray" \
   " exception" \
   " filesystem" \
   " forward_list" \
   " fstream" \
   " functional" \
   " future" \
   " hash_map" \
   " hash_set" \
   " initializer_list" \
   " iomanip" \
   " ios" \
   " iosfwd" \
   " iostream" \
   " istream" \
   " iterator" \
   " limits" \
   " list" \
   " locale" \
   " map" \
   " memory" \
   " memory_resource" \
   " modulemap" \
   " mutex" \
   " new" \
   " numeric" \
   " optional" \
   " ostream" \
   " propagate_const" \
   " queue" \
   " random" \
   " ratio" \
   " regex" \
   " scoped_allocator" \
   " set" \
   " shared_mutex" \
   " sstream" \
   " stack" \
   " stdexcept" \
   " streambuf" \
   " string" \
   " string_view" \
   " strstream" \
   " system_error" \
   " thread" \
   " tuple" \
   " type_traits" \
   " typeindex" \
   " typeinfo" \
   " unordered_map" \
   " unordered_set" \
   " utility" \
   " valarray" \
   " variant" \
   " vector" \
   " xcomplex" \
   " xdebug" \
   " xfacet" \
   " xfunctional" \
   " xhash" \
   " xios" \
   " xiosbase" \
   " xlocale" \
   " xlocbuf" \
   " xlocinfo" \
   " xlocmes" \
   " xlocmon" \
   " xlocnum" \
   " xloctime" \
   " xmemory" \
   " xmemory0" \
   " xrefwrap" \
   " xstddef" \
   " xstring" \
   " xtr1common" \
   " xtree" \
   " xutility" \
   " xxatomic" \
   "";

_str def_user_langext_files="";

_str _get_langext_files()
{
   // LANGEXT_DAT ends with a space so there is no need to add
   // an extra one before def_user_langext_files
   return(LANGEXT_DAT:+def_user_langext_files:+" ");
}

static _str make_space_delimit_string(_str (&str_array)[])
{
   result := "";

   int index;
   for (index=0;index<str_array._length();++index) {
      if (result:!="") {
         strappend(result," ");
      }
      strappend(result,str_array[index]);
   }

   return result;
}

static void make_array_from_space_delimit_string(_str space_string, _str (&str_array)[])
{
   _str item;
   space_string=strip(space_string);

   while (space_string:!="") {
      parse space_string with item space_string;
      space_string=strip(space_string);

      str_array[str_array._length()]=item;
   }
}

static _str edit_user_langext_callback()
{
   // prompt for name, check for duplicate, and add to list
   newName := "";
   _str promptResult = show("-modal _textbox_form",
                            "Enter the name for the new file",
                            0,
                            "",
                            "",
                            "",
                            "",
                            "Extensionless file:" "" );
   if (promptResult == "") {
      // user cancelled operation
      return "";
   }

   return _param1;
}

_command void edit_user_langext_files()
{
   _str str_array[];
   make_array_from_space_delimit_string(def_user_langext_files,str_array);

   _str result=show("-modal _list_editor_form",
                    "Extensionless C++ Files",
                    "Extensionless C++ Files:",
                    str_array,
                    edit_user_langext_callback);

   if (result:!="") {
      def_user_langext_files=make_space_delimit_string(_param1);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

_str concat_path_and_file(_str path, _str filename)
{
   _maybe_append_filesep(path);
   return path:+filename;
}

static void _activate_selmode_view()
{
   int *pview_id = _GetDialogInfoHtPtr(SELECT_MODE_VIEW_ID, _mdi);
   if (pview_id != null && _iswindow_valid(*pview_id)) {
      activate_window(*pview_id);
      return;
   }

   filename := _ConfigPath():+"selmode.ini";
   status := _open_temp_view(filename, auto selmode_view_id, auto orig_view_id);
   if (status) {
      _create_temp_view(selmode_view_id);
      p_buf_name=filename;
   }

   p_buf_flags= VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN;
   _SetDialogInfoHt(SELECT_MODE_VIEW_ID, selmode_view_id, _mdi);
}
static void _just_pds(_str &buf_name)
{
   if (_DataSetIsFile(buf_name)) {
      buf_name=_strip_filename(buf_name,"N");
   }
}
static int _find_selected_mode(_str buf_name,bool onlyLookForMember=false)
{
   _activate_selmode_view();
   top();
   int status;
   save_search(auto a,auto b,auto c,auto d);
   if (_DataSetIsFile(buf_name)) {
      status=search("\t"_escape_re_chars(buf_name)"$",
                    "@rhi");
   } else {
      status=search("\t"_escape_re_chars(buf_name)"$",
                    "@rh"_fpos_case);
   }
   if (status && _DataSetIsMember(buf_name) && !onlyLookForMember) {
      _just_pds(buf_name);
      status=search("\t"_escape_re_chars(buf_name)"$",
                    "@rhi");
   }
   restore_search(a,b,c,d);
   return(status);
}

int _DataSetQAutoFileType()
{
   option := get_env("VSLICK390AUTOFILETYPE");
   if (length(option)!=1 || !isdigit(option)) {
      return(1);
   }
   return(_asc(option)-_asc("0"));
}
/*
   AutoFileTypeOption
          0                    OFF:  No automatic file type determination
          1                    Default: Determine file type based on PDS name
                               and first non-blank line.  See
                               Default file type determination below.
          2                    Determine file type based on PDS lowercase extension.
                               Note that the "asm" extension is converted to
                               "s" for convenients.

                               For example,
                                   //a.b.c/member    File Type is "c"
                                   //a.b.y           File Type is "y"
                                   //a.b.asm         File type is "s"

Assembler -  Asterisk in column 1 or a recognized opcode of
             CSECT, DSECT, MACRO, TITLE, START or COPY
             Note: *PROCESS in column 1 is recognized as PL/I.

PL/I      -  First string is % or / *  or the first string
             is *PROCESS in column 1.
             See REXX, C, and Panel below for more information.

Pascal    -  First string is (* or the first string is / *  and
             the data set name ends in .PASCAL.

COBOL     -  First non-blank is a * or / in column 7

C         -  First string is # or
             first string is // and data set type is not .PROCLIB,
                 .CNTL, .JCL, or .ISPCTLx or
             first string is / * and data set type is .C

IDL       -  Same as C when data set type is .IDL

REXX      -  First string is a / * comment containing REXX
          -  or
             first string is a / * comment and the data set type
             is .EXEC or .REXX

Panel     -  First string is ) in column 1 followed by a panel section
             name or
             first string is % in column 1

Skeleton  -  ) in column 1 in a file that does not seem to be a panel.
JCL       -  //anything in column 1 followed by a JOB, DD, PROC,
                        EXEC, or MSG or
             // * in column 1 or
             // in column 1 and and data set type is .PROCLIB, .CNTL,
                .JCL, or .ISPCTLx

BookMaster - First character is  . or : in column 1

DTL       - First non-blank character is <

*/
_str _getFileTypeFromQualifier(_str buf_name,_str dsname="")
{
   if (dsname=="") {
      if (buf_name=="" || !_DataSetIsFile(buf_name)) return("");
      dsname=_DataSetNameOnly(buf_name);
   }
   dataset_type := lowcase(_get_extension(dsname, true));
   if (dataset_type==".asm") {
      return("asm390");
   }
   if (substr(dataset_type,1,1)==".") {
      return(substr(dataset_type,2));
   }
   return("");
}

// From the source of the data set or PDS member, determine
// the type.
_str _getFileTypeFromSource(
   _str buf_name,
   _str sourceData, /* About 1k of source data should be plenty */
   _str dataset_type=null
   )
{
   if (buf_name=="" /*|| !_DataSetIsFile(buf_name) could be ftp p_DocumentName*/
       ) return("");
   if (dataset_type==null) {
      dataset_type=_getFileTypeFromQualifier(buf_name);
   }

   // Strip leading blank lines
   _str line,rest;
   for (;;) {
      if (sourceData=="") {
         return("");
      }
      parse sourceData with line '[\r\n]','r' rest;
      if (line!="") {
         break;
      }
      sourceData=rest;
   }
   if (isinteger(substr(line,73,8)) && length(line)==80) {
      line=substr(line,1,72);
   }
   _str firstword,secondword;
   parse line with firstword rest '[\r\n]','r';
   if (substr(line,1,1)=="*" && lowcase(firstword)==lowcase("*process")) {
      return("pl1");
   }
   if (substr(line,1,1)=="*") {
      return("asm390");
   }
   _str cobolword1, cobolword2;
   parse lowcase(substr(line,7)) with cobolword1 cobolword2 .;
   if ((isinteger(substr(line,1,6)) &&  cobolword1=="cbl") ||
       lowcase(firstword)=="cbl") {
      return("cob");
   }
   // following added by Allen Richardson 4/14/2008 for Enterprise COBOL
   if ((isinteger(substr(line,1,6)) &&  cobolword1=="process") ||
       lowcase(firstword)=="process") {
      return("cob");
   }
   if (cobolword2=="division" || cobolword2=="division.") {
      if ((isinteger(substr(line,1,6)) &&  cobolword1=="identification") ||
          lowcase(cobolword1)=="identification") {
         return("cob");
      }
      if ((isinteger(substr(line,1,6)) &&  cobolword1=="id") ||
          lowcase(cobolword1)=="id") {
         return("cob");
      }
   }
   if ((substr(line,1,6)=="" || isinteger(substr(line,1,6))) &&
       (substr(line,7,1)=="*" || substr(line,7,1)=="/") ) {
      return("cob");
   }
   if (substr(firstword,1,2)=="/*") {
      if (pos("rexx",line,1,"i")) {
         return("rexx");
      }
      switch (dataset_type) {
      case ".pascal":
         return("pas");
      case ".c":
         return("c");
      case ".rexx":
      case ".exec":
         return("rexx");
      }
      return("pl1");
   }
   if (substr(firstword,1,2)=="(*") {
      return("pas");
   }
   if (substr(firstword,1,1)=="%") {
      return("pl1");
   }
   if (substr(firstword,1,1)=="#") {
      return("c");
   }
   if(substr(line,1,2)=="//" ){
      // JCL or C
      if (substr(line,3,1)=="*") {
         return("jcl");
      }
      if (rest!="" && (dataset_type==".proclib" || dataset_type==".cntl" || dataset_type==".jcl" || substr(dataset_type,1,7)==".ispctl")) {
         return("jcl");
      }
      parse rest with secondword .;
      secondword=upcase(secondword);
      if (pos(" "secondword" "," JOB DD PROC EXEC MSG COMMAND IF ELSE INCLUDE OUTPUT SET XMIT ")) {
         return("jcl");
      }
      return("c");
   }
   if (substr(line,1,1)!="") {
      parse line with . secondword .;
   } else {
      secondword=firstword;
   }
   secondword=upcase(secondword);
   if (pos(" "secondword" "," CSECT DSECT MACRO TITLE START COPY EQU ")) {
      return("asm390");
   }
   return("");
}
static void _selmode_delete_member_settings(_str buf_name)
{
   _activate_selmode_view();
   top();
   save_search(auto a,auto b,auto c,auto d);
   _just_pds(buf_name);
   for (;;) {
      int status=search("\t"_escape_re_chars(buf_name):+FILESEP,'@rh'_fpos_case);
      if (status) {
         break;
      }
      if(_delete_line()) break;
      _begin_line();
   }
   restore_search(a,b,c,d);
}
void _record_selected_mode(_str ext, _str option='M' /* or 'A' */)
{
   if (!def_record_dataset_mode) return;
   _str buf_name=p_buf_name;
   if (buf_name=="" || !_DataSetIsFile(buf_name)) return;
   int orig_view_id;
   get_window_id(orig_view_id);
   status := 0;
   if (option=='M') {
      status=_find_selected_mode(buf_name);
      // IF use automatic language determination AND
      //    don't have to worry about PDS member file type
      //    being different from the PDS file type
      if (ext=="") {
         if (!status) {
            _delete_line();
            _save_file("+o");
         }
         activate_window(orig_view_id);
         return;
      }
   } else {
      // Remove all member specific settings for this PDS
      _selmode_delete_member_settings(buf_name);
      // Add setting for PDS
      _just_pds(buf_name);
   }
   data := ext"\t"buf_name;
   if (!status) {
      replace_line(data);
      _save_file("+o");
      activate_window(orig_view_id);
      return;
   }
   top();up();
   insert_line(data);
   _save_file("+o");
   activate_window(orig_view_id);
}
_str _get_selected_mode(_str buf_name,bool onlyLookForMember=false)
{
   if (!def_record_dataset_mode) return("");
   if (buf_name=="" || !_DataSetIsFile(buf_name)) return("");
   _str line,ext;
   int orig_view_id;
   get_window_id(orig_view_id);
   int status=_find_selected_mode(buf_name,onlyLookForMember);
   if (!status) {
      get_line(line);
      parse line with ext"\t";
      activate_window(orig_view_id);
      return(ext);
   }
   activate_window(orig_view_id);
   return("");
}
/**
 * Update the language mode associated with the current file.
 * This is used for FTP files where the file mode might not be
 * selected immediately.
 *
 * @param wid  Window ID to udpate.
 *
 * @deprecated Use {@link _UpdateEditorLanguage()}.
 */
void _UpdateExtension(int wid=0)
{
   _UpdateEditorLanguage(wid);
}

/**
 * Update the language mode associated with the current file.
 * This is used for FTP files where the file mode might not be
 * selected immediately.
 *
 * @param wid  Window ID to udpate.
 */
void _UpdateEditorLanguage(int wid=0)
{
   if (!wid) {
      wid=_get_focus();
   }
   if (!wid || !wid._isEditorCtl()) {
      return;
   }
   file_name := _strip_filename(wid.p_buf_name, 'P');
   if ((!wid.p_AutoSelectLanguage || !wid._ftpDataSetIsFile()) &&
       (!isEclipsePlugin() || (_get_extension(wid.p_buf_name) != '' &&
         _Ext2LangId(_get_extension(wid.p_buf_name)) != "") ||
        !def_eclipse_check_ext_mode || wid.p_LangId != "fundamental")
       ) {
      return;
   }
   //say("idle="_idle_time_elapsed());
   if (_idle_time_elapsed()<75 || (wid.p_ModifyFlags&MODIFYFLAG_AUTOEXT_UPDATED)) {
      return;
   }

   // we may not even want to set the type
   setType := _DataSetQAutoFileType();
   if (!setType) {
      return;
   }

   _str lang = wid._DataSetEditorLanguage(wid.p_buf_name,setType,"",true);
   if ( lang == "" ) {
      lang="fundamental";
   }
   //say("ext="ext);
   if ( wid.p_LangId != lang ) {
      //say("got here ext="ext);
      int old_def_record_mode=def_record_dataset_mode;
      def_record_dataset_mode=0;
      wid._SetEditorLanguage(lang);
      def_record_dataset_mode=old_def_record_mode;
      wid.p_AutoSelectLanguage=true;
      refresh();
   }
   wid.p_ModifyFlags|=MODIFYFLAG_AUTOEXT_UPDATED;

}

// Determine the extension type of the data set.
// Retn: language type, "" unknown type
static _str _DataSetEditorLanguage(_str buf_name // fully qualified data set name: //DS.NAME or //PDS.NAME/MEM
                                   ,int AutoFileTypeOption // 1=use qualifier and first line, 2=use qualifier only, 0=do nothing
                                   ,_str sourceData=""
                                   ,bool currentObjectIsBuffer=false)
{
   // Check PDS extension first.
   temp_ext := "";
   _str dataset_type=null;
   if (AutoFileTypeOption > 0) {
      if (currentObjectIsBuffer) {
         temp_ext=_ftpGetFileTypeFromQualifier();
      } else {
         temp_ext=_getFileTypeFromQualifier(buf_name);
      }
      dataset_type=temp_ext;
      if (temp_ext!="") {
         // map the file extension to a language mode
         lang := _Ext2LangId(temp_ext);
         if ( lang != "" ) return lang;
      }
   }

   // Check first line of source.
   if (AutoFileTypeOption==1) {
      if (sourceData == "") {
         // Get the source.
         if (currentObjectIsBuffer) {
            save_pos(auto p);
            top();
            sourceData=get_text(1000);
            restore_pos(p);
         } else {
            int temp_view_id, orig_view_id;
            int status=_open_temp_view(buf_name,temp_view_id,orig_view_id);
            if (!status) {
               top();
               sourceData=get_text(1000);
               _delete_temp_view(temp_view_id);
               activate_window(orig_view_id);
            }
         }
      }

      // Check the source.
      temp_ext=_getFileTypeFromSource(buf_name,sourceData,dataset_type);
      if (temp_ext!="") {
         // map the extension to a language mode
         lang := _Ext2LangId(temp_ext);
         if ( lang != "" ) return lang;
         // Return identity extension if there is no language mode.
         return temp_ext;
      }
   }
   return("");
}
void _ModifyTabSetup(_str lang,_str iwt,_str tabs)
{
   if (_LangIsDefined(lang)) {
      if (iwt != "") {
         _LangSetProperty(lang,VSLANGPROPNAME_INDENT_WITH_TABS,(iwt != 0));
      }
      if (tabs != "") {
         _LangSetProperty(lang,VSLANGPROPNAME_TABS,tabs);
      }
   }
}
bool gExcludeLangIdsIndentWithTabs:[]= _reinit {
   "asm390"=>true,
   "cmake"=>true,  // Not sure about this one
   "cob"=>true,
   //"bourneshell"=>true,
   "cob74"=>true,
   "cob2000"=>true,
   //"csh"=>true,
   //"e"=>true,
   "fileman"=>true,
   "for"=>true,  // Not sure about this one but our default tabs are "1 7 250 +3"
   "imakefile"=>true,
   //"java"=>true,
   //"masm"=>true,
   "mak"=>true,
   "npasm"=>true,  // Want tabs +8
   //"pl"=>true,  // Want tabs +8
   "process"=>true,  // Want tabs +8
   //"properties"=>true,  // Want tabs +8
    "py"=>true,
   "tagdoc"=>true,
   "yaml"=>true,
    //"tcl"=>true,  // Want tabs +8
   //"unixasm"=>true,

};
bool gExcludeLangIdsTabs:[]= _reinit {
   "asm390"=>true,
   "cmake"=>true,  // Not sure about this one
   "cob"=>true,
   "bourneshell"=>true,
   "cob74"=>true,
   "cob2000"=>true,
   "csh"=>true,
   //"e"=>true,
   "fileman"=>true,
   "for"=>true,  // Not sure about this one but our default tabs are "1 7 250 +3"
   "imakefile"=>true,
   //"java"=>true,
   "masm"=>true,
   "mak"=>true,
   "npasm"=>true,  // Want tabs +8
   "pl"=>true,  // Want tabs +8
   "process"=>true,
   "properties"=>true,  // Want tabs +8
    "py"=>true,
   "tagdoc"=>true,
   "tcl"=>true,  // Want tabs +8
   "unixasm"=>true,
   "yaml"=>true,
};

void _ModifyTabSetupAll(_str fundamental_iwt,
                     _str other_iwt,_str other_tabs)
{
   // figure out which languages we don't want to set tabs for
   bool excludedLangIds:[];

   excludedLangIds=gExcludeLangIdsIndentWithTabs;
   excludedLangIds:["fundamental"]=true;
   excludedLangIds:["e"]=true;
   iwt_exclusions:=joinDict(excludedLangIds, ",");
   setOptionForAllLanguages("IndentWithTabs", other_iwt, iwt_exclusions);

   excludedLangIds=gExcludeLangIdsTabs;
   excludedLangIds:["fundamental"]=true;
   excludedLangIds:["e"]=true;
   excludedLangIds:["java"]=true;
   tabs_exclusions:=joinDict(excludedLangIds, ",");
   setOptionForAllLanguages("Tabs", other_tabs, tabs_exclusions);

   // fundamental is special
   _ModifyTabSetup("fundamental",fundamental_iwt,"");

   /*****START PROPRIOTARY FILE SETUP**********************************/
   //_ModifyTabSetup("process",fundamental_iwt,"+8");
   /*****END PROPRIOTARY FILE SETUP**********************************/

  // Some languages have beautifiers - we need to let them know we've made some changes.
  // IF we are doing this during the state file build, don't bother
  _str updateTab:[];
  updateTab:[VSLANGPROPNAME_INDENT_WITH_TABS]="";
  updateTab:[VSLANGPROPNAME_TABS]="";

}
void replace_def_data(_str name,_str info)
{
   index := find_index(name,MISC_TYPE);
   if (index) {
      set_name_info(index,info);
   } else {
      /*if (substr(name,1,13)=="def-language-" || substr(name,1,10)=="def-setup-") {
         parse name with "def-" . "-" auto ext;
         //if (index_callable(find_index("check_and_load_support",PROC_TYPE))) {
            //check_and_load_support(ext,index);
         //}
      } */
      index=find_index(name,MISC_TYPE);
      if (!index) {
         insert_name(name,MISC_TYPE,info);
      }
   }
}

/**
 * @return
 *    Returns the language mode associated with the given file name
 *    extension.  The <b>Language Options dialog box</b> allows you
 *    to map an extension that to a language mode.  This function
 *    performs that translation, and will also use the [optional]
 *    buffer name to determine the language mode.
 *
 * @param ext        source file name extension
 * @param file_name  source file name with path
 * @param currentObjectIsBuffer
 *                   pass "true" if if the current object is an
 *                   editor control containing the file in question
 * @param setAutoSelectLanguage
 *                   if "true" set {@link p_AutoSelectLanguage}
 *
 * @categories Miscellaneous_Functions
 * @deprecated Use {@link _Filename2LangId()}
 */
_str refer_ext(_str ext, _str file_name="",
               bool currentObjectIsBuffer=false,
               bool setAutoSelectLanguage=false)
{
   if (ext != "" && file_name=="") return _Ext2LangId(ext);
   return _Filename2LangId(/*ext,*/file_name/*,currentObjectIsBuffer,setAutoSelectLanguage*/);
}


static bool in_expand_extension_alias;
_command void expand_extension_alias() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (in_expand_extension_alias) return;
   if (command_state()) {
      return;
   }

   typeless orig_values;
   int status=_EmbeddedStart(orig_values);
   if(p_mode_eventtab==_default_keys) {
      if (status==1) {
         _EmbeddedEnd(orig_values);
      }
      return;
   }
   int i=eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(" "));
   if (!i) {
      if (status==1) {
         _EmbeddedEnd(orig_values);
      }
      return;
   }
   in_expand_extension_alias=true;

   if (!LanguageSettings.getExpandAliasOnSpace(p_LangId)) {
      LanguageSettings.setExpandAliasOnSpace(p_LangId, true);
      call_index(i);
      LanguageSettings.setExpandAliasOnSpace(p_LangId, false);
   } else {
      call_index(i);
   }
   in_expand_extension_alias=false;
   if (status==1) {
      _EmbeddedEnd(orig_values);
   }
}

/**
 * Callback used with _for_each_control, for finding a control
 * with a specific name.  Returns 0 on failure, or the window id
 * of the control with the matching name if found.
 */
int _compare_control_name(int wid, _str name)
{
   if (wid.p_object != OI_SSTAB_CONTAINER && wid.p_object!=OI_FORM) {
      //say("_compare_control_name: name="name" p_name="wid.p_name);
      widname := stranslate(wid.p_name, "-", "_");
      if (widname == name) {
         return wid;
      }
   }
   return 0;
}
/**
 * Get or set the line numbering flags for the current extension.
 * If num_style==0, then this just returns the current flag
 * settings, ignoring the mask.  Otherwise, the flags specified
 * in the style mask are set as they are in num_style.
 * If style_mask is ommited, use num_style for the mask.
 *
 * @param num_style      (optional) bitset of VSRENUMBER_* flags
 * @param style_mask     (optional) flag mask to set/get
 *
 * @return new flags on success, 0 if no extension options found.
 */
int numbering_options(int num_style=0, int style_mask=0)
{
   // first get our numbering style
   langID := p_LangId;
   flags := LanguageSettings.getNumberingStyle(langID);

   if (!num_style && !style_mask) {
      return flags;
   }

   return 0;
}
/**
 * make a line number, right justified with leading zeroes
 *
 * @param n              line number to create
 * @param num_digits     number of digits in line number area
 * @param pad_char       pad character (for leading zeroes)
 * @param use_blanks     use spaces (to remove line numbers)
 *
 * @return line number as string, length(result)==num_digits
 */
_str make_line_number(int n,int num_digits,_str pad_char="0",bool use_blanks=false)
{
   if (use_blanks) {
      return substr("",1,num_digits," ");
   }
   _str n_str = n;
   return substr("",1,num_digits-length(n_str),pad_char):+n_str;
}
/**
 * renumber lines in buffer according to the current numbering style
 *
 * @param start_col      start column line number is expected to be in
 * @param end_col        ending column for line number field
 * @param pad_char       padding character
 * @param remove_numbers remove line numbers from source (put in blanks)
 * @param quiet          do not display any messages
 */
void renumber_lines(int start_col,int end_col,_str pad_char="0",
                    bool use_blanks=false, bool quiet=false, bool check_seq_num=false)
{
   typeless p;
   _save_pos2(p);
   int orig_trunc=p_TruncateLength;
   p_TruncateLength=0;
   may_have_lost_data := false;
   int i,n=p_RNoflines;
   last_number := 0;
   int num_digits=end_col-start_col+1;
   for (i=1; i<=n; i++) {
      p_RLine=i;
      _str line;get_line_raw(line);
      int rstart_col=orig_trunc?start_col:text_col(line,start_col,'P');
      int rend_col=orig_trunc?end_col:text_col(line,end_col,'P');
      replace_increment := 0;
      number_contents := substr(line,rstart_col,rend_col-rstart_col+1);
      if (number_contents=="") {
         replace_increment=100;
         if (check_seq_num) {
            int seq_num = (last_number%100);
            if (seq_num > 0) {
               replace_increment=10000;
            }
         }

      } else if (pos('^0@{[0-9 ]*}$',number_contents,1,'r')) {
         text := substr(number_contents,pos('S0'),pos('0'));
         line_number := 0;
         if (isinteger(text)) {
            line_number=(int) text;
         }
         if (line_number <= last_number) {
            replace_increment = 100;
            if (check_seq_num) {
               seq_num := (last_number%100);
               if (seq_num > 0) {
                  replace_increment=10000;
               }
               last_number=last_number;
            } else {
               last_number=last_number-(last_number%100);
            }
         } else {
            last_number=line_number;
         }
      } else {
         may_have_lost_data=true;
         replace_increment=100;
         if (check_seq_num) {
            seq_num := (last_number%100);
            if (seq_num > 0) {
               replace_increment=10000;
            }
            last_number=last_number;
         } else {
            last_number=last_number-(last_number%100);
         }
      }
      if (replace_increment > 0 || use_blanks) {
         last_number+=replace_increment;
         line_prefix := substr(line,1,rstart_col-1);
         line_suffix := substr(line,rend_col+1);
         _str number_str=make_line_number(last_number,num_digits,pad_char,use_blanks);
         replace_line_raw(line_prefix:+number_str:+line_suffix);
      }
   }
   _restore_pos2(p);
   p_TruncateLength=orig_trunc;
   if (may_have_lost_data && !quiet) {
      _message_box(nls("Data in columns %s..%s has been overwritten with line numbers",start_col,end_col));
   }
}

/**
 * Repeats a command the specified number of times.  This
 * commmand basically implements a scenario in which the {@link
 * repeat_key} command needs to parse arguments when invoked
 * from the command line.
 *
 * @param command_string argument string passed to {@link
 *                       repeat_key}.
 */
static void _repeat_key_args(_str command_string)
{
   argname := command_name := args := "";
   num := 0;
   while (command_string != "") {
      parse command_string with argname command_string;
      if (substr(argname, 1, 1) :== "-") {
         // This is a flag.
         argname = substr(argname, 2);
         if (!isinteger(argname)) {
            // The flag is not numerical.  Skip it.
            continue;
         }
         num = (int)argname;
      } else if (command_name == "") {
         // Get the command name.
         command_name = argname;
      } else {
         args :+= " "argname;
      }
   }

   while (!num) {
      numstr := "";
      numstr = prompt(numstr, "Repeats:", num);
      if (isinteger(numstr)) {
         num = (int)numstr;
      } else {
         message("Not a number");
         return;
      }
   }

   // Make sure the command exists.
   command_name = strip(command_name);
   index := find_index(command_name, COMMAND_TYPE);
   if (!index || !index_callable(index)) {
      message("Command '"command_name"' not found");
      return;
   }
   i := 0;
   for (i = 0; i < num; ++i) {
      execute(command_name" "args);
   }
   message("'"command_name"' repeated ":+num:+" times");
}

/**
 * Repeat a key event the number of times specified.
 * <p>
 * To use, after calling this command, type the number of times
 * you want to repeat a key, followed by the key itself. For
 * instance, the following key sequence (without the dashes):
 * <pre>
 * <b>repeat_key</b> - <b>68</b> - <b>*</b>
 * </pre>
 * inserts 68 instances of '*' to the current cursor location as
 * if the character was manually typed 68 times.
 * <p>
 * The key to be repeated is not limited to a single character,
 * but can be a command bound to a key stroke (such as Ctrl+V).
 * <p>
 * This command can also be called from the command line, in
 * which case it can take arguments in the following format:
 * <pre>
 * <b>repeat_key</b> -[repeat num] [command name] [command arguments]
 * </pre>
 *
 * @categories Keyboard_Functions
 */
_command void repeat_key(_str command_string="") name_info(COMMAND_ARG','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_string != "") {
      // Command name exists.  Probably invoked from the command line.
      _repeat_key_args(command_string);
      return;
   }

   event := "";

   // Get the number first.
   num := 0;
   while (true) {
      num *= 10;
      event = get_event();
      if (event >= 0 && event <= 9) {
         num += (int)event;
         event = "";
         message("Repeats: ":+num);
      } else {
         num = num intdiv 10;
         break;
      }
   }

   if (!num) {
      return;
   }

   if (event == "") {
      event = get_event();
   }

   if (iscancel(event)) {
      message("Cancelled");
      return;
   }

   int i;
   for (i = 0; i < num; ++i) {
      call_key(event);
   }
   message("'"event2name(event)"' repeated ":+num:+" times");
}

/**
 * control line number mode, and immediately renumber lines
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions, Search_Functions
 */
_command void renumber,renum() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int renumber_flags = numbering_options();
   if (renumber_flags & VSRENUMBER_STD) {
      renumber_lines(73,80,"0");
   }
   if (renumber_flags & VSRENUMBER_COBOL) {
      renumber_lines(1,6,"0");
   }
}
/**
 * remove line numbers from source
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions, Search_Functions
 */
_command void unnum,unnumber() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int renumber_flags = numbering_options();
   if (renumber_flags & VSRENUMBER_STD) {
      renumber_lines(73,80,"0",true);
   }
   if (renumber_flags & VSRENUMBER_COBOL) {
      renumber_lines(1,6,"0",true);
   }
}


/**
 * Turn on or off uppercase mode.  The <b>caps</b> command controls whether
 * alphabetic data that you type is automatically converted to uppercase as you edit.
 * <p>
 * Note that if Auto Caps is turned on for the current file, the editor will set
 * caps mode according to the data in the file when it is opened.  If the data contains
 * uppercase letters and no lowercase letters, caps mode is turned on.  Otherwise, caps mode is off.
 *
 * @see help:ISPF Line Command Uppercase
 * @see p_caps
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions, Search_Functions
 */
_command void caps() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   _str cmdline=arg(1);
   if (cmdline=="") {
      p_caps=(!p_caps);
      return;
   }
   bool number;
   if(setonoff(number,cmdline)) return;
   p_caps=number;
}
void _LCUpdateOptions()
{
   if (!index_callable(find_index("_create_temp_view",PROC_TYPE))) {
      return;
   }
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   int first_buf_id=p_buf_id;

   inISPF := def_keys=="ispf-keys";
   int langSettings:[] = null;

   for (;;) {
      if (!(p_buf_flags&VSBUFFLAG_HIDDEN)) {
         if (_QReadOnly()) {
            if (_default_option(VSOPTION_LCREADONLY) && !beginsWith(p_buf_name,".process") && p_LangId!="fileman" && p_LangId!="grep") {
               p_LCBufFlags|=VSLCBUFFLAG_READWRITE;
            } else {
               p_LCBufFlags&= ~VSLCBUFFLAG_READWRITE;
            }
         } else {
            if (_default_option(VSOPTION_LCREADWRITE) && !beginsWith(p_buf_name,".process") && p_LangId!="fileman" && p_LangId!="grep") {
               p_LCBufFlags|=VSLCBUFFLAG_READWRITE;
            } else {
               p_LCBufFlags&= ~VSLCBUFFLAG_READWRITE;
            }
         }

         // we have to do some specialness for line numbers
         if (inISPF) {
            // if automatic line numbers are on, change them to manual
            if (p_LCBufFlags & VSLCBUFFLAG_LINENUMBERS_AUTO) {
               // change them to regular line numbers
               p_LCBufFlags&=~VSLCBUFFLAG_LINENUMBERS_AUTO;
               p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS;
            }
            p_line_numbers_len = _default_option(VSOPTION_LINE_NUMBERS_LEN);
         } else {
            // get the language info and use that
            lang := p_LangId;
            if (!langSettings._indexin(lang"length")) {
               langSettings:[lang"flags"] = LanguageSettings.getLineNumbersFlags(p_LangId);
               langSettings:[lang"length"] = LanguageSettings.getLineNumbersLength(p_LangId);
            }
            if (langSettings._indexin(lang"length")) {
               flags := langSettings:[lang"flags"];
               lnl := langSettings:[lang"length"];
               if (flags & LNF_ON) {
                  p_LCBufFlags |= (VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
               } else {
                  p_LCBufFlags &= ~(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
               }
               p_line_numbers_len = lnl;
            }
         }
      }
      _next_buffer('rh');
      if (p_buf_id==first_buf_id) {
         break;
      }
   }
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
}
_command void cob_tab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state()) {
      call_root_key(TAB);
      return;
   }
   if(_EmbeddedLanguageKey(last_event())) return;
   // For COBOL we want  05<TAB> to act just like 05<space>
   if (_LanguageInheritsFrom("cob")) {
      get_line(auto tline);
      if (p_TruncateLength) {
         tline=substr(tline,1,_TruncateLengthC());
         tline=strip(tline,'T');
      }
      line := strip(tline,'T');
      if ( p_col==text_col(line)+1 ) {
         word := strip(tline,'L');
         if ( pos(" "word"="," "def_cobol_levels" ") ) {
            typeless column=eq_name2value(word,def_cobol_levels);
            if ( isinteger(column) ) {
               replace_line(indent_string(column-1):+strip(tline)" ");
               _end_line();
            }
         }
      }
   }

   orig_col := p_col;
   tab();

   int root_binding_index=eventtab_index(_default_keys,_default_keys,event2index(TAB));
   if (name_name(root_binding_index)=="move-text-tab") {
      new_col := p_col;p_col=orig_col;
      if (p_indent_with_tabs) {
         _insert_text("\t");
      } else {
         _insert_text(substr("",1,new_col-orig_col));
      }
      p_col=new_col;
   }
}
_command void cob_backtab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state()) {
      call_root_key(S_TAB);
      return;
   }
   if(_EmbeddedLanguageKey(last_event())) return;
   backtab();
}
/**
 * Copy all files from the specified source directory to the specified
 * destination directory.
 *
 * @param srcDir  source directory
 * @param dstDir  destination directory
 * @param options Options: 'r' to make files read only, 'w' to make files read/write, '' to leave files untouched
 * @param ignoreErrors If true, keep trying to copy files even
 *                     if an error is encountered along the way.
 * @return 0 OK, !0 error code
 *
 * @categories File_Functions
 */
int copyFileTree(_str srcDir, _str dstDir, _str options="",
                 bool ignoreErrors=false,
                 _str (&FilesCopied)[]=null,
                 bool skipFilesOrDirs:[]=null)
{
   // Make sure source directory exists.
   _maybe_append_filesep(srcDir);
   if (!isdirectory(srcDir)) {
      return(FILE_NOT_FOUND_RC);
   }

   // Build a list of files in the source tree. The list includes both
   // the directories and files.
   _str fileList[];
   fileCount := 0;
   filePath := file_match("+t "_maybe_quote_filename(srcDir), 1);
   while (filePath != "") {
      // Skip the "." and ".." directory entries.
      if (_last_char(filePath) == FILESEP) {
         tempPath := substr(filePath,1,length(filePath)-1);
         tempPath = _strip_filename(tempPath, 'P');
         if (tempPath == "." || tempPath == "..") {
            filePath = file_match("+t "_maybe_quote_filename(srcDir), 0);
            continue;
         }
      }
      // Strip the source directory part.
      filePath = substr(filePath, length(srcDir) + 1);

      // Skip any file they wanted to exclude from the copy
      parse filePath with auto firstDir (FILESEP) .;
      if (skipFilesOrDirs._indexin(_file_case(filePath)) ||
          (firstDir != "" && skipFilesOrDirs._indexin(_file_case(firstDir:+FILESEP)))) {
         //say("copyFileTree: skipping "filePath);
         filePath = file_match("+t "_maybe_quote_filename(srcDir), 0);
         continue;
      }

      // Add the file to the list of files to copy
      //say("copyFileTree: "filePath);
      fileList[fileCount] = filePath;
      fileCount++;
      filePath = file_match("+t "_maybe_quote_filename(srcDir), 0);
   }

   // If the destination directory does not exist, create it.
   status := 0;
   _maybe_append_filesep(dstDir);
   if (!isdirectory(dstDir)) {
      status = make_path(dstDir);
      if (status) return(status);
   }

   // Create the directories and copy the files.
   int i;
   _str destPath;
   fileMode := "";
   if (options == "r") {
      fileMode = (_isUnix()) ? "u-w,g-w,o-w":"+R";
   } else if (options == "w") {
      fileMode = (_isUnix()) ? "u+w,g-w,o-w":"-R";
   }
   for (i=0; i<fileCount; i++) {
      // Build the destination path.
      destPath = dstDir :+ fileList[i];
      if (_last_char(destPath) == FILESEP) {
         // Create directory.
         if (!isdirectory(destPath)) {
            status = make_path(destPath);
         }
         if (_isUnix()) {
            if (!status && options != "") {
               _chmod("u+r,u+w,u+x,g+r,g+x,o+r,o+x ":+_maybe_quote_filename(destPath));
            }
         }
      } else {
         // Copy the file.
         status = copy_file(srcDir:+fileList[i], destPath);
         FilesCopied[FilesCopied._length()]=destPath;
         if (!status && fileMode != "") {
            _chmod(fileMode:+" ":+_maybe_quote_filename(destPath));
         }
      }
      // Keep going through failures if the continue
      // option is set
      if (status && (ignoreErrors == false)){
         return(status);
      }
   }
   return(0);
}
void _DebugUpdateMenu(_str ProjectFilename=_project_name)
{
   //
   // DJB (05/24/2005) -- In 10.0.1, the Debug menu always
   //                     exists as part of the MDI menu
   //
   _project_DebugConfig=false;
   /*
   int menu_handle=_mdi.p_menu_handle;
   if (!menu_handle) return;

   BuildMenuCaption := "&Build";
   DebugMenuCaption := "&Debug";
   pos1 := -1;
   pos2 := -1;
   int i;
   int count=_menu_info(menu_handle);
   for (i=0;i<count;++i) {
      int mf_flags;
      _str caption;
      _menu_get_state(menu_handle,i,mf_flags,"P",caption);
      if (strieq(stranslate(BuildMenuCaption,"","&"),stranslate(caption,"","&"))) {
         pos1=i;
         ++i;
         if (i<count) {
            _menu_get_state(menu_handle,i,mf_flags,'P',caption);
            if (strieq(stranslate(DebugMenuCaption,'','&'),stranslate(caption,'','&'))) {
               pos2=i;
            }
         }
         break;
      }
   }
   // IF we could not find the Build menu
   if (pos1<0) {
      return;
   }
   if (pos2>=0) {
      _menu_delete(menu_handle,pos2);
   }
   */

   index := 0;
   _str debug_command;
   if (_project_DebugCallbackName != "") {
      index=find_index("_"_project_DebugCallbackName"_ConfigNeedsDebugMenu",PROC_TYPE);
      if (index) {
         int Node=_ProjectGet_TargetNode(_ProjectHandle(ProjectFilename),"Debug");
         debug_command=_ProjectGet_TargetCmdLine(_ProjectHandle(ProjectFilename),Node);
         _project_DebugConfig=(!index || call_index(debug_command,index));
      } else {
         _project_DebugConfig=true;
      }
      /*
      if (!_project_DebugConfig) {
         _menu_info(menu_handle,'R');// Redraw menu bar
         return;
      }
      */
   }

   /*
   index=find_index("_default_debug_menu",oi2type(OI_MENU));
   if (!index) {
      _menu_info(menu_handle,'R');   // Redraw menu bar
      return;
   }
   int submenu_handle=_menu_insert_submenu(menu_handle,pos1+1,index,DebugMenuCaption,'ncw','help debug menu','Displays debug menu');
   //_menu_load(index);
   //_menu_insert(debug_menu_handle,-1,MF_SUBMENU,"Test");
   _menu_set_bindings(submenu_handle);
   _menu_info(menu_handle,'R');   // Redraw menu bar
   */

}
static _str _get_eurl()
{
   temp := "h";temp=temp"t";temp=temp"t";temp=temp"p";temp=temp":";
   temp :+= "/";temp=temp"/";temp=temp"w";temp=temp"w";temp=temp"w";
   temp :+= ".";temp=temp"s";temp=temp"l";temp=temp"i";temp=temp"c";
   temp :+= "k";temp=temp"e";temp=temp"d";temp=temp"i";temp=temp"t";
   temp :+= ".";temp=temp"c";temp=temp"o";temp=temp"m";temp=temp"/";
   temp :+= "e";temp=temp"a";temp=temp"s";temp=temp"t";temp=temp"e";
   temp :+= "r";temp=temp"e";temp=temp"g";temp=temp"g";temp=temp".";
   temp :+= "h";temp=temp"t";temp=temp"m";temp=temp"l";
   return(temp);
}
#if 0
/**
 * Show the amount of memory allocated and the number of allocations made
 * within the VSAPI DLL.
 */
_command show_memory_statistics()
{
   if (_MallocTotal()==0) {
      _message_box("Memory tracking is not enabled");
   } else {
      _message_box("Total number of bytes allocated = "_MallocTotal()"\nTotal number of allocations = "_MallocCount());
   }
}
#endif
/**
 * Duplicate the current line.
 *
 * @return 0 on success, <0 on error
 */
_command int duplicate_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   int mark_id;

   mark_id=_alloc_selection();
   if (mark_id<0) {
      message(get_message(mark_id));
      return(mark_id);
   }
   _select_line(mark_id);
   _copy_to_cursor(mark_id);
   down();
   // This selection can be freed because it is not the active selection
   _free_selection(mark_id);

   return(0);
}

/**
 * Convert language specific options information to the string
 * format which is stored in def-language-[lang].
 *
 * @deprecated Use {@link _LanguageSetupToInfo()}.
 *
 * @categories Miscellaneous_Functions
 */
_str _ExtSetupToInfo(VS_LANGUAGE_SETUP_OPTIONS &setup)
{
   return _LanguageSetupToInfo(setup);
}
/**
 * Places some language settings in
 * VS_LANGUAGE_SETUP_OPTIONS
 *
 * <p>Better to use {@link _LangGetProperty()} or {@link
 * _GetDefaultLanguageOptions()}.
 *
 * @categories Miscellaneous_Functions
 */
_str _LanguageSetupToInfo(VS_LANGUAGE_SETUP_OPTIONS &setup)
{
   return LanguageSettings.getLanguageSetupStringFromSetupOptions(setup);
}

/**
 * Store the basic options for the given language.
 * This applies only to the options stored in the
 * def-language-[lang] variable.
 *
 * @param lang    Language ID, see {@link p_LangId}
 * @param setup   Struct containing all language setup options
 *
 * @see _GetLanguageSetupOptions()
 * @see _GetDefaultLanguageOptions()
 * @see _SetDefaultLanguageOptions()
 *
 * @categories Miscellaneous_Functions
 * @deprecated Use {@link _SetLanguageSetupOptions()}.
 */
void _ExtSetSetup(_str lang, VS_LANGUAGE_SETUP_OPTIONS &setup)
{
   _SetLanguageSetupOptions(lang,setup);
}
/**
 * Store the basic options for the given language.
 * This applies only to the options stored in the
 * def-language-[lang] variable.
 *
 * @param lang    Language ID, see {@link p_LangId}
 * @param setup   Struct containing all language setup options
 *
 * @see _GetLanguageSetupOptions()
 * @see _GetDefaultLanguageOptions()
 * @see _SetDefaultLanguageOptions()
 *
 * @categories Miscellaneous_Functions
 */
void _SetLanguageSetupOptions(_str extension, VS_LANGUAGE_SETUP_OPTIONS &setup)
{
   LanguageSettings.setLanguageDefinitionOptions(extension, setup);
}

/**
 * @return Return the language mode name associated
 *         with the given extension.
 *
 * @see _Ext2LangId
 * @see _LangGetModeName
 *
 * @deprecated Use {@link _Ext2LangId()} or {@link
 *             _LangGetModeName()}
 */
_str _ExtGetModeName(_str extension)
{
   lang := _Ext2LangId(extension);
   if (lang=="") return "";
   return _LangGetModeName(lang);
}

/**
 * Retrieve the basic options for the given
 * language. This applies only to the options
 * stored in the def-language-[lang] variable.
 *
 * @param lang    Language ID, see {@link p_LangId}
 * @param setup   Struct containing all language setup options
 *
 * @see _SetLanguageSetupOptions()
 * @see _GetDefaultLanguageOptions()
 * @see _SetDefaultLanguageOptions()
 *
 * @categories Miscellaneous_Functions
 * @deprecated Use {@link _GetLanguageSetupOptions()}.
 */
int _ExtGetSetup(_str lang, VS_LANGUAGE_SETUP_OPTIONS &setup)
{
   return _GetLanguageSetupOptions(lang, setup);
}
/**
 * Retrieve the basic options for the given
 * language. This applies only to the options
 * stored in the def-language-[lang] variable.
 *
 * @param lang    Language ID, see {@link p_LangId}
 * @param setup   Struct containing all language setup options
 *
 * @see _SetLanguageSetupOptions()
 * @see _GetDefaultLanguageOptions()
 * @see _SetDefaultLanguageOptions()
 *
 * @categories Miscellaneous_Functions
 */
int _GetLanguageSetupOptions(_str lang, VS_LANGUAGE_SETUP_OPTIONS &setup)
{
   return LanguageSettings.getLanguageDefinitionOptions(lang, setup);
}

void _SoftWrapUpdateAll(bool SoftWrap,bool SoftWrapOnWord)
{
   def_SoftWrap=SoftWrap;
   def_SoftWrapOnWord=SoftWrapOnWord;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   _SoftWrapSetAll(SoftWrap,SoftWrapOnWord);
   int i,last=_last_window_id();
   for (i=1;i<=last;++i) {
      if (_iswindow_valid(i) && i._isEditorCtl(false) && !i.p_IsMinimap){
         if (i.p_SoftWrap!=SoftWrap || i.p_SoftWrapOnWord!=SoftWrapOnWord
             ) {
            i.p_SoftWrap=SoftWrap;
            i.p_SoftWrapOnWord=SoftWrapOnWord;
         }
      }
   }
}
void _SoftWrapSetAll(bool SoftWrap,bool SoftWrapOnWord)
{
   _LangSetProperty(VSCFGPROFILE_ALL_LANGUAGES,VSLANGPROPNAME_SOFT_WRAP,SoftWrap);
   _LangSetProperty(VSCFGPROFILE_ALL_LANGUAGES,VSLANGPROPNAME_SOFT_WRAP_ON_WORD,SoftWrapOnWord);
   _GetAllLangIds(auto langs);
   for (i := 0; i < langs._length();i ++) {
      lang := langs[i];
      _LangSetProperty(lang,VSLANGPROPNAME_SOFT_WRAP,SoftWrap);
      _LangSetProperty(lang,VSLANGPROPNAME_SOFT_WRAP_ON_WORD,SoftWrapOnWord);
   }
}
void _SmartTabSetAll(int smartTab)
{
   _LangSetProperty(VSCFGPROFILE_ALL_LANGUAGES,VSLANGPROPNAME_SMART_TAB,smartTab);
   _GetAllLangIds(auto langs);
   for (i := 0; i < langs._length();i ++) {
      langId := langs[i];
      smarttab_index := _FindLanguageCallbackIndex("%s_smartpaste",langId);
      if (smarttab_index && index_callable(smarttab_index)) {
         _LangSetProperty(langId,VSLANGPROPNAME_SMART_TAB,smartTab);
      }
   }
}

/**
 * Test if the current language supports the given type of doc comment.
 *
 * @param option DocCommentTrigger
 */
static bool have_doc_comment_style(_str option)
{
   return _plugin_has_property(vsCfgPackage_for_Lang(p_LangId),VSCFGPROFILE_DOC_ALIASES,option);
   //lang_doc_comments := LanguageSettings.getDocCommentFlags(p_LangId);
   //return (pos(DocCommentFlagDelimiter:+option:+DocCommentFlagDelimiter, lang_doc_comments) > 0);
}

/**
 * Prompt for user's preferred comment style.
 *
 * @param orig_comment           original comment text
 * @param comment_flags          bitset of VSCODEHELP_COMMETNFLAG_
 * @param slcomment_start        single line comment start delimiter
 * @param mlcomment_start        multiple line comment start delimiter
 * @param doxygen_comment_start  Doxygen style comment start delimiter
 *
 * @return Return 'false' if user cancelled.
 */
static bool prompt_for_doc_comment_style(_str orig_comment, VSCodeHelpCommentFlags &comment_flags, _str &slcomment_start, _str &mlcomment_start, _str &doxygen_comment_start)
{
   if (comment_flags==0) {

      keepStylePrompt := get_message(VSRC_DOC_COMMENT_STYLE_KEEP);
      javadocPrompt   := get_message(VSRC_DOC_COMMENT_STYLE_JAVADOC);
      doxygenPrompt   := get_message(VSRC_DOC_COMMENT_STYLE_DOXYGEN);
      doxygen1Prompt  := get_message(VSRC_DOC_COMMENT_STYLE_DOXYGEN1);
      doxygen2Prompt  := get_message(VSRC_DOC_COMMENT_STYLE_DOXYGEN2);
      xmldocPrompt    := get_message(VSRC_DOC_COMMENT_STYLE_XMLDOC);

      _str commentStyles[];
      int commentOptions[];
      if (orig_comment != "" || slcomment_start != "") {
         commentStyles[commentStyles._length()] = keepStylePrompt;
         commentOptions[commentOptions._length()] = VS_COMMENT_EDITING_FLAG_CREATE_DEFAULT;
      }

      if (is_javadoc_supported()) {
         if (have_doc_comment_style(DocCommentTrigger1)) {
            commentStyles[commentStyles._length()] = javadocPrompt;
            commentOptions[commentOptions._length()] = VS_COMMENT_EDITING_FLAG_CREATE_JAVADOC;
         }
         if (have_doc_comment_style(DocCommentTrigger2)) {
            commentStyles[commentStyles._length()] = doxygenPrompt;
            commentOptions[commentOptions._length()] = VS_COMMENT_EDITING_FLAG_CREATE_JAVADOC|VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN;
         }
         if (have_doc_comment_style(DocCommentTrigger4)) {
            commentStyles[commentStyles._length()] = doxygen1Prompt;
            commentOptions[commentOptions._length()] = VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN;
         }
      }
      if (have_doc_comment_style(DocCommentTrigger3)) {
         if (_is_xmldoc_supported()) {
            commentStyles[commentStyles._length()] = xmldocPrompt;
            commentOptions[commentOptions._length()] = VS_COMMENT_EDITING_FLAG_CREATE_XMLDOC;
         } else if (is_javadoc_supported()) {
            commentStyles[commentStyles._length()] = doxygen2Prompt;
            commentOptions[commentOptions._length()] = VS_COMMENT_EDITING_FLAG_CREATE_XMLDOC|VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN;
         }
      }

      msg := _language_comments_form_get_value("ctl_doc_comment_style", p_LangId);
      choice := 0;
      for (i:=0; i<commentStyles._length(); i++) {
         if (commentStyles[i] == msg) {
            choice = i+1;
            break;
         }
      }

      // if the user does not have a preferred documentation comment format, prompt
      if (choice == 0 && commentStyles._length() > 1) {
         choice = RadioButtons("Select doc comment style",
                                commentStyles, 1, "update_doc_comment.styleconversion",
                               "Do not show these options again.");
         if (choice <= 0) {
            return false;
         }
         // save comment format if they said not to prompt any more
         doNotPrompt := _param1;
         if (doNotPrompt) {
            commentFlags := _GetCommentEditingFlags(0, p_LangId);
            commentFlags &= ~VS_COMMENT_EDITING_FLAG_CREATE_JAVADOC;
            commentFlags &= ~VS_COMMENT_EDITING_FLAG_CREATE_XMLDOC;
            commentFlags &= ~VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN;
            commentFlags &= ~VS_COMMENT_EDITING_FLAG_CREATE_DEFAULT;
            commentFlags |= commentOptions[choice-1];
            _LangSetProperty(p_LangId, VSLANGPROPNAME_COMMENT_EDITING_FLAGS, commentFlags);
         }
      }

      // keep current formatting?
      if (choice <= 0) {
         return true;
      }
      msg = commentStyles[choice-1];
      if (msg == javadocPrompt) {
         mlcomment_start = CODEHELP_JAVADOC_PREFIX;
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK)) {
            slcomment_start = "*";
         } else {
            slcomment_start = " ";
         }
         comment_flags   = VSCODEHELP_COMMENTFLAG_JAVADOC;
         doxygen_comment_start = mlcomment_start;
      } else if (msg == doxygenPrompt) {
         mlcomment_start = CODEHELP_DOXYGEN_PREFIX;
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK)) {
            slcomment_start = "*";
         } else {
            slcomment_start = " ";
         }
         comment_flags = VSCODEHELP_COMMENTFLAG_DOXYGEN;
         doxygen_comment_start = mlcomment_start;
      } else if (msg == doxygen1Prompt) {
         doxygen_comment_start = CODEHELP_DOXYGEN_PREFIX1;
         comment_flags = VSCODEHELP_COMMENTFLAG_DOXYGEN;
         slcomment_start = "";
      } else if (msg == doxygen2Prompt) {
         doxygen_comment_start = CODEHELP_DOXYGEN_PREFIX2;
         comment_flags = VSCODEHELP_COMMENTFLAG_DOXYGEN;
         slcomment_start = "";
      } else if (msg == xmldocPrompt) {
         doxygen_comment_start = CODEHELP_DOXYGEN_PREFIX2;
         comment_flags = VSCODEHELP_COMMENTFLAG_XMLDOC;
         slcomment_start = CODEHELP_DOXYGEN_PREFIX2;
      } else if (msg == keepStylePrompt) {
         // do nothing
      } else {
         return false;
      }
   }
   return true;
}

/*
int _OnUpdate_update_doc_comment(CMDUI& cmdui, int target_wid, _str command)
{
   if (!target_wid || !target_wid._isEditorCtl() || target_wid.p_readonly_mode) {
      return(MF_GRAYED);
   }

   status := get_comment_delims(auto mlstart, auto mlend, auto supportJD);
   if (status == 0 && supportJD) {
      return MF_ENABLED;
   } else {
      return MF_GRAYED;
   }
}
*/

static _str _orig_item_text:[];
static _str _orig_help_text:[];

int _OnUpdate_update_doc_comment(CMDUI &cmdui,int target_wid,_str command)
{
   word := "";
   enabled := MF_ENABLED;

   if (!target_wid || !target_wid._isEditorCtl() ||!target_wid._istagging_supported() || target_wid.p_readonly_mode) {
      enabled=MF_GRAYED;
   }

   if (target_wid) {
      ldce := find_index('_lang_doc_comments_enabled', PROC_TYPE);
      if (ldce > 0) {
         if (!call_index(target_wid.p_LangId, ldce)) {
            enabled = MF_GRAYED;
         }
      }
   }
   // If there are no doc comment expansions, then this should not be enabled for that language.

   if (p_mdi_child && p_window_state:=='I') {
      enabled=MF_GRAYED;
   }

   command=translate(command,"-","_");
   menu_handle := cmdui.menu_handle;
   button_wid := cmdui.button_wid;
   if (button_wid) {
      return enabled;
   }
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      return enabled;
   }
   if (!target_wid && enabled==MF_GRAYED) {
      return enabled;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);
   save_pos(auto p);
   if (_in_comment()) {
      _clex_skip_blanks();
   }

   context_id := tag_current_context();
   restore_pos(p);
   func_name := "";
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, auto type_name);
      // are we on a function?
      if (tag_tree_type_is_func(type_name) || tag_tree_type_is_class(type_name) || tag_tree_type_is_data(type_name)) {
         tag_get_detail2(VS_TAGDETAIL_context_name, context_id, func_name);
      }
   }
   if (func_name == "") {
      return MF_GRAYED;
   }
   msg := "";
   if (command=="update-doc-comment") {
      msg=nls("Update Doc Comment for %s ", func_name);
   }
   if (cmdui.menu_handle) {
      if (!_orig_item_text._indexin(command)) {
         _orig_item_text:[command]="";
      }
      keys := text := "";
      parse _orig_item_text:[command] with keys "," text;
      if ( keys!=def_keys || text=="") {
         flags := 0;
         _str new_text;
         typeless junk;
         _menu_get_state(menu_handle,command,flags,'m',new_text,junk,junk,junk,_orig_help_text:[command]);
         if (keys!=def_keys || text=="") {
            text=new_text;
         }
         _orig_item_text:[command]=def_keys","text;
         //message '_orig_item_text='_orig_item_text;delay(300);
      }
      key_name := "";
      parse _orig_item_text:[command] with \t key_name;
      int status=_menu_set_state(menu_handle,
                                 cmdui.menu_pos,enabled,'p',
                                 msg"\t":+key_name,
                                 command,"","",
                                 _orig_help_text:[command]);
   }
   return(enabled);
}

static _str tag_style_for_doxygen(_str commentstart)
{
   // Indirection, since we can't import alias.e
   rv := '\';
   gaf := find_index('get_unexpanded_alias_body', PROC_TYPE);
   gdapn := find_index('getDocAliasProfileName', PROC_TYPE);
   if (gaf > 0 && gdapn > 0) {
      mli := '';
      int origview, tmpview;
      rc := call_index(commentstart, origview, tmpview, mli, call_index(p_LangId, gdapn), gaf);
      if (rc == 0) {
         top();
         save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
         if (search('@param', 'L@') == 0) {
            rv = '@';
         }
         restore_search(s1, s2, s3, s4, s5);
         p_window_id = origview;
         _delete_temp_view(tmpview);
      }
   }

   return rv;
}

/**
 * Update the javadoc or doxygen comment for the current
 * function or method, based on the signature.  If no comment
 * exists for the function, then one is generated.
 *
 * @categories Miscellaneous_Functions
 */
_command void update_doc_comment() name_info(','VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // get the function signature information
   // this call does not work for when you are on the javadoc of a function...would be nice
   // should validate first and last line
   status := _parseCurrentFuncSignature(auto javaDocElements, auto xmlDocElements, auto first_line, auto last_line, auto func_line);
   if (status) {
      return;
   }

   // find the start column of the comment
   start_col := find_comment_start_col(first_line);
   _save_pos2(auto p);
   mlcomment_start := "";
   slcomment_start := "";
   doxygen_comment_start := "";
   int blanks:[][];
   // extract the comment information from the existing comment for this function
   status =_GetCurrentCommentInfo(auto comment_flags,
                                  auto orig_comment,
                                  auto return_type,
                                  slcomment_start, blanks,
                                  doxygen_comment_start);
// say("update_doc_comment: comment_flags="comment_flags);
// say("update_doc_comment: slcommetn_start="slcomment_start);
// say("update_doc_comment: doxygen_comment="doxygen_comment_start);
   if (status) {
      _restore_pos2(p);
      return;
   }

   // should we convert original comment to documentation comment?
   orig_comment_flags   := comment_flags;
   orig_slcomment_start := slcomment_start;
   orig_mlcomment_start := mlcomment_start;
   orig_doxygen_start   := doxygen_comment_start;
   if (!prompt_for_doc_comment_style(orig_comment, comment_flags, slcomment_start, mlcomment_start, doxygen_comment_start)) {
      return;
   }

   // no comment at all, then create one
   if (is_javadoc_supported() && orig_comment == "" && orig_slcomment_start == "" && orig_comment_flags == 0 && orig_doxygen_start=="") {
      goto_line(func_line);
      if (doxygen_comment_start == "") {
         if (_is_xmldoc_preferred()) {
            doxygen_comment_start = DocCommentTrigger3;  // XML Doc
         } else {
            doxygen_comment_start = DocCommentTrigger1;  // Javadoc
         }
      }
      _EmbeddedCall(_document_comment,doxygen_comment_start,comment_flags);
      return;
   }

   // check the flags for the start of the comment
   isDoxygen := false;
   if ((comment_flags & VSCODEHELP_COMMENTFLAG_DOXYGEN) != 0) {
      mlcomment_start = doxygen_comment_start;
      isDoxygen = true;
   } else if (comment_flags & VSCODEHELP_COMMENTFLAG_JAVADOC) {
      mlcomment_start = CODEHELP_JAVADOC_PREFIX;
   } else if (comment_flags & VSCODEHELP_COMMENTFLAG_XMLDOC) {
      //mlcomment_start = CODEHELP_DOXYGEN_PREFIX2;
      mlcomment_start = "";
   }

   // the following code doesn't support XMLDOC comments, so bring up the
   // XMLDOC editor instead.
   if (slcomment_start == "///" && (comment_flags & VSCODEHELP_COMMENTFLAG_XMLDOC)) {
      _xmldoc_update_doc_comment(orig_comment, xmlDocElements, start_col, first_line, last_line);
      _restore_pos2(p);
      return;
   }

   // loop through blanks until we find a blank line, so we know if blanks are used in the comment
   typeless element;
   haveBlanks := false;
   for (element._makeempty();!haveBlanks;) {
      blanks._nextel(element);
      if(element._isempty()) break;
      i := 0;
      for (i = 0; i < blanks:[element]._length(); i++) {
         if (blanks:[element][i] > 0 && element != "") {
            haveBlanks = true;
            break;
         }
      }
   }
   _str commentElements:[][];
   _str tagList[];
   description := "";
   // parse information from the existing javadoc comment into hashtables
   //_parseJavadocComment(orig_comment, description, commentElements, tagList, false, isDoxygen, auto tagStyle, false);
   tagStyle := '';
   if (isDoxygen) {
      // Doxygen has the choice of two tag styles.  tag_tree_parse_javadoc_comment() will return whatever
      // style it encounters in the comment.  The special case is when there are no tags in the comment.  When
      // this happens, tag_tree_parse_javadoc_comment() will return whatever was passed in as the 'tagStyle'
      // (or a default of \\ if tagStyle is an empty string).  For this special case, we want to use the tag style
      // used in the doc comment expansion as the default tag style.
      tagStyle = tag_style_for_doxygen((mlcomment_start == '') ? slcomment_start : mlcomment_start);
   }
   tag_tree_parse_javadoc_comment(orig_comment, description, tagStyle, commentElements, tagList, false, isDoxygen, false);
   // nuke the original comment lines (if there were any)
   num_lines := last_line-first_line+1;
   if (num_lines > 0 && !(orig_comment == "" && orig_slcomment_start == "" && orig_comment_flags == 0 && orig_doxygen_start=="")) {
      p_line=first_line;
      int i;
      for (i=0; i<num_lines; i++) {
         // check if javadoc comment has leading asterisks
         if (slcomment_start=="" && (mlcomment_start == "/**" || mlcomment_start == "/*!")) {
            _first_non_blank();
            if (get_text(2) == "* ") slcomment_start = "*"
         }
         _delete_line();
      }
   }
   // put us where we need to be
   p_line=first_line-1;
   mlcomment_end := "";
   // get the ending of the comment (this should probably be parsed instead of using get_comment_delims)
   get_comment_delims(auto sl_delim,auto ml_delim, mlcomment_end);
   if (mlcomment_start == "") mlcomment_start = ml_delim;
   if (slcomment_start == ml_delim && slcomment_start != sl_delim) slcomment_start = "";
   if (mlcomment_start == "" && slcomment_start == "") slcomment_start = sl_delim;
   if (isDoxygen) {
      if (mlcomment_start == "//!") {
         mlcomment_end = "//!";
      } else if (mlcomment_start == "///") {
         mlcomment_end = "///";
      }
   }
   // add the start of the comment
   if (mlcomment_start!="") {
      if (!isDoxygen || (mlcomment_start != "///" && mlcomment_start != "//!")) {
         insert_line(indent_string(start_col-1):+mlcomment_start);
      }
      if (slcomment_start != "") {
         slcomment_start=" "slcomment_start;
      }
   }
   i := 0;

   // To be consistent with how multiline comments without borders are beautified,
   // the body of the comment is indented as if there was a single space as the left
   // border.  That way, the tags in a borderless doc comment don't look sunken into
   // the edge of the comment start and end.
   lborder := (slcomment_start == '' && mlcomment_start != '') ? '  ' : slcomment_start;
   prefix := indent_string(start_col-1):+lborder:+" ";
   // possibly adjust prefix
   leadingBlank := 1;
   if (isDoxygen && (mlcomment_start == "//!" || mlcomment_start == "///")) {
      // safety check for start_col - 2 to not be neg?
      prefix=indent_string(start_col-1):+mlcomment_start:+" ";
      leadingBlank = 0;
   }
   // maybe add leading blank lines before description
   if (isinteger(blanks:["leading"][0])) {
      for (i = 0; i < blanks:["leading"][0] - leadingBlank; i++) {
         insert_line(prefix);
      }
   }
   haveBrief := false;
   for (i = 0; i < tagList._length() && !haveBrief; i++) {
      if (tagList[i] == "brief") {
         haveBrief = true;
      }
   }
// say("prefix="prefix);
   // maybe add the description
   if (!haveBrief) {
      if (description != "") {
         description = stranslate(description, "\n", "\r\n", 'r');
         split(description, "\n", auto descArray);
         for (i = 0;i < descArray._length();i++) {
            if (strip(descArray[i]) != "") {
               insert_line(prefix:+descArray[i]);
            }
         }
         // add any blanks after the description
         if (isinteger(blanks:[""]._length()) && isinteger(blanks:[""][0])) {
            for (i = 0; i < blanks:[""][0]; i++) {
               insert_line(prefix);
            }
         }
      } else if (blanks._isempty()) {
         // leave room for the yet-to-be-written description
         insert_line(prefix);
      }
   }
   // insert javadoc tags in the order they were originally
   insert_javadoc_elements(prefix, commentElements, blanks, isDoxygen, tagList, javaDocElements, haveBlanks, tagStyle);
   // add the end of the comment
   if (mlcomment_start!="") {
      if (!isDoxygen || (mlcomment_start != "//!" && mlcomment_start != "///")) {
         if (slcomment_start == '') {
            // Another special case for borderless comments. We don't want to indent
            // the closing as if we were lining up the * with a border that isn't there.
            insert_line(mlcomment_end);
         } else {
            insert_line(indent_string(start_col):+mlcomment_end);
         }
      }
   }
   _restore_pos2(p);
}

/**
 * Find the first column of the beginning of a commment.
 *
 * @param first_line
 *
 * @return Starting column of current comment, or -1 if unsuccessful.
 */
int find_comment_start_col(int first_line){
   if (!_isEditorCtl()){
      return -1;
   }
   save_pos(auto p);
   goto_line(first_line);
   _first_non_blank();
   status := _clex_find_start();
   if (!status) {
      start_col := p_col;
      restore_pos(p);
      return start_col;
   }
   restore_pos(p);
   return -1;
}

/**
 * Insert all javadoc elements of a certain tag into a comment.
 *
 * @param prefix
 * @param sigElements
 * @param tag
 * @param comElements
 * @param blanks
 * @param haveBlanks
 */
static void insert_javadoc_element_from_signature(_str prefix, _str sigElements:[][], _str tag,
   _str comElements:[][], int blanks:[][], bool haveBlanks, bool isDoxygen, _str tagStyle)
{
   i := k := j := 0;
   _str params:[];
   params._makeempty();
   _str unmatchingDescs[];
   if (tag == "param") {
      // for each param element extracted from the existing comment...
      for (k = 0; k < comElements:[tag]._length(); k++) {
         split(strip(comElements:[tag][k])," ", auto commmentTokens);
         // stripping possible EOL char off of what we grabbed from the comment...could do this beforehand?
         if (commmentTokens._length() > 1) {
            commmentTokens[0] = stranslate(commmentTokens[0],'','\n','R');
            usingComment := false;
            for (i = 0; i < sigElements:[tag]._length(); i++) {
               newComment := strip(sigElements:[tag][i]);
               if (commmentTokens[0] == newComment) {
                  usingComment = true;
                  break;
               }
            }
            // unneeded nullcheck here?
            if (!usingComment && commmentTokens != null) {
               description := "";
               for (j = 1; j < commmentTokens._length(); j++) {
                  description :+= " "commmentTokens[j];
               }
               // couldn't find a match for this description? save it
               unmatchingDescs[k] = description;
            } else {
               unmatchingDescs[k] = "";
            }
         }
      }
   }
   blanksAfterLast := -1;
   // for each comment element of type 'tag' extracted from the function signature..
   for (i = 0; i < sigElements:[tag]._length(); i++) {
      newComment := strip(sigElements:[tag][i]);
      if (tag == "return") {
         if(newComment == "void") {
            // no return value...don't insert anything
            return;
         }
         newComment = "";
      }
      foundExisting := false;
      constructedDescription := false;
      // for each element of type "tag" extracted from the existing comment...
      for (k = 0; k < comElements:[tag]._length(); k++) {
         split(comElements:[tag][k]," ", auto commentTokens);
         if (commentTokens != null && commentTokens._length() > 0){
            // stripping possible EOL char off of what we grabbed from the comment...could do this beforehand?
            // we've already done this for params...
            commentTokens[0] = stranslate(commentTokens[0],'','\n','R');
            // is the first token the same as the new comment that would be generated
            // from the function signature?
            if (tag == "param" && params:[newComment] != null && params:[newComment] != "") {
               newComment :+= params:[newComment];
               foundExisting = true;
               constructedDescription = true;
               break;
            } else if (commentTokens[0] == newComment) {
               // if so, keep the already existing comment element, instead of replacing it
               newComment = comElements:[tag][k];
               foundExisting = true;
               constructedDescription = true;
               break;
            } else if (tag == "return" && commentTokens[0] != "") {
               // this is good unless the return type has changed...
               newComment = comElements:[tag][k];
               break;
            }
         }
      }
      // if we checked this signature element against each element in the comments, and didn't find
      // an appropriate description, see if we saved one from before that is in the same position
      if (!constructedDescription && tag == "param" && i < unmatchingDescs._length() && unmatchingDescs[i] != "") {
         newComment :+= unmatchingDescs[i];
         foundExisting = true;
      }
      numBlanks := 0;
      if (!foundExisting) {
         numBlanks = blanksForNewElement(blanks,tag,haveBlanks);
         // are we on the last element? check our value for "blanks after last occurrence"
         if (i == sigElements:[tag]._length() - 1) {
            if (blanksAfterLast >= 0) {
               numBlanks = blanksAfterLast;
            } else if (isinteger(blanks:[tag][i])) {
               // if blanksAfterLast isn't set here, that means the last item has been changed so we haven't
               // gotten to what was the previous last item...so check that one
               numBlanks = (int)blanks:[tag][i];
            }
         }
      } else if (isinteger(blanks:[tag][i])) {
         numBlanks = (int)blanks:[tag][i];
         // if there is a blank after this line BUT it is the last occurrence of this tag
         // that we found in the existing comment AND there are more occurences of this tag
         // to add from the function signature
         if (numBlanks > 0 && i == blanks:[tag]._length()-1 && i < sigElements:[tag]._length()-1) {
            // save this number of blanks for later
            blanksAfterLast = numBlanks;
            foundBlank := false;
            // check to see if there are blanks after at least one of the other occurrences of this tag
            m := 0;
            for (m = 0; m < i; m++) {
               if (isinteger(blanks:[tag][m]) && (int)blanks:[tag][m] > 0) {
                  foundBlank = true;
                  break;
               }
            }
            // no other blanks used between occurrences of this tag...don't insert a blank
            if (!foundBlank) {
               numBlanks = 0;
            }
         } else if (numBlanks == 0 && i == sigElements:[tag]._length()-1) {
            if (isinteger(blanks:[tag][blanks:[tag]._length()-1])) {
               numBlanks = (int)blanks:[tag][blanks:[tag]._length()-1];
            }
         }
      }
      // insert each line of the comment element...followed by the appropriate number of blank lines
      write_javadoc_element(newComment, prefix, tag, isDoxygen, tagStyle);
      for (j = 0; j < numBlanks; j++) {
         insert_line(prefix);
      }
   }
}

/**
 * Find the number of blanks that should be added after we add the javadoc tag
 * to a function comment.
 *
 * @param blanks
 * @param tag
 * @param haveBlanks
 *
 * @return number of blanks to be inserted after the javadoc element
 */
static int blanksForNewElement(int blanks:[][], _str tag, bool haveBlanks)
{
   i := 0;
   totalBlanks := 0;
   if (blanks:[tag]._length() == 0) {
      // no tags of this type in the comment...if they are using blanks just add one in
      // this could be improved
      return haveBlanks ? 1 : 0;
   } else {
      // see how many blanks are added after each tag of this type...if it's not consistent
      // then just take an average
      for (i = 0; i < blanks:[tag]._length(); i++) {
         totalBlanks += blanks:[tag][i];
      }
      return totalBlanks == 0 ? 0 : floor(totalBlanks/blanks:[tag]._length());
   }
}

/**
 * Insert all non-standard javadoc tags into the function comment.
 *
 * @param prefix
 * @param commentElements
 * @param blanks
 * @param isDoxygen
 * @param tagList
 * @param sigElements
 * @param haveBlanks
 */
static void insert_javadoc_elements(_str prefix, _str commentElements:[][], int blanks:[][],
   bool isDoxygen, _str tagList[], _str sigElements:[][], bool haveBlanks, _str tagStyle)
{
   k := 0;
   bool doneElementFromSig:[];
   doneElementFromSig._makeempty();
   curTag := "";
   for (k = 0; k < tagList._length(); k++) {
      curTag = tagList[k];
      // if this tag is not one that we extract from the function signature
      if (!pos(curTag,JAVADOC_TAGS_FROM_SIG) && commentElements:[curTag] != null) {
         i := j := 0;
         // for each comment element of type 'element' extracted from the function signature..
         for (i = 0; i < commentElements:[curTag]._length(); i++) {
            // insert each line of the comment element, along with any blank lines
            write_javadoc_element(strip(commentElements:[curTag][i]), prefix, curTag, isDoxygen, tagStyle);
            if (isinteger(blanks:[curTag][i])) {
               for (j = 0; j < blanks:[curTag][i]; j++) {
                  insert_line(prefix);
               }
            }
         }
      } else if (pos(curTag,JAVADOC_TAGS_FROM_SIG) && !doneElementFromSig:[curTag]) {
         insert_javadoc_element_from_signature(prefix, sigElements, curTag, commentElements, blanks, haveBlanks,
            isDoxygen, tagStyle);
         doneElementFromSig:[curTag] = true;
      }
   }
   parse JAVADOC_TAGS_FROM_SIG with curTag "," auto rest;
   // the loop on tagList will only cover the elements which existed in the original doc comment,
   // so we want to now loop over any elements which we extracted from the function signature and
   // didn't exist in the original comment
   while (curTag != "") {
      if (!doneElementFromSig:[curTag]) {
         insert_javadoc_element_from_signature(prefix, sigElements, curTag, commentElements, blanks, haveBlanks,
            isDoxygen, tagStyle);
      }
      parse rest with curTag "," rest;
   }
}

/**
 * Print a javadoc element into the current editor control.
 *
 * @param element
 * @param pre
 * @param tag
 */
static void write_javadoc_element(_str element, _str pre, _str tag, bool isDoxygen, _str tagStyle)
{
   tagprefix := tagStyle;
   if (tag == "return" && element == "") {
      insert_line(pre:+tagprefix:+tag);
      return;
   }
   j := 0;
   if (element == '' && tag != '') {
      // An empty tag element shouldn't be removed as if it were a blank line.
      insert_line(pre:+tagprefix:+tag);
   } else {
      element = stranslate(element, "\n", "\r\n", 'r');
      split(element, "\n", auto elementLines);
      for (j = 0;j < elementLines._length();j++) {
         // we should not be inserting blank lines here
         // that is the job of the blanks hashtable.
         if (elementLines[j] != "" || j == 0 || (elementLines[j] == "" && tag != "")) {
            if (j == 0) {
               insert_line(pre:+tagprefix:+tag" ":+elementLines[j]);
            } else {
               insert_line(pre:+elementLines[j]);
            }
         }
      }
   }
}

/**
 * Check if an associated file exists in the current directory.
 *
 * @param filename      current buffer name
 * @param ext_list      list of alternate file extensions to try
 *
 * @return bool
 */
static bool associated_file_exists(_str &filename, _str ext_list, bool returnAll, _str langId)
{
   mou_hour_glass(true);
   filename_no_ext  := _strip_filename(filename, 'E');
   filename_no_path := _strip_filename(filename, 'EP');

   _str foundFileList[];
   foreach (auto ext in ext_list) {
      // try same directory
      filename_with_ext := filename_no_ext"."ext;
      if (file_exists(filename_with_ext)) {
         foundFileList[foundFileList._length()] = filename_with_ext;
         if (!returnAll) break;
      } else if (buf_match(filename_with_ext,1,'hx') != "") {
         foundFileList[foundFileList._length()] = filename_with_ext;
         if (!returnAll) break;
      }

      // try current project
      if (_project_name != "") {
         filename_in_project := _projectFindFile(_workspace_filename, _project_name, filename_no_path"."ext, 0);
         if (filename_in_project != "") {
            foundFileList[foundFileList._length()] = filename_in_project;
            if (!returnAll) break;
         }
      }

      // try entire workspace, unless we already found a match in the
      // current directory or the current project
      if (_workspace_filename != "") {
         message("Searching: "_workspace_filename);
         _str projectList[] = null;
         _GetWorkspaceFiles(_workspace_filename, projectList);
         // try all projects in the workspace
         foreach (auto project in projectList) {
            project = _AbsoluteToWorkspace(project, _workspace_filename);
            if (project != _project_name) {
               // search this project for the file
               filename_in_project := _projectFindFile(_workspace_filename, project, filename_no_path"."ext, 0);
               if (filename_in_project != "") {
                  foundFileList[foundFileList._length()] = filename_in_project;
                  if (!returnAll) break;
               }
            }
         }
      }

      // try any open buffer
      if (foundFileList._length()) {
         filename_in_buffer := buf_match(filename_with_ext,1,'hxn');
         if (filename_in_buffer != "") {
            foundFileList[foundFileList._length()] = filename_in_buffer;
            if (!returnAll) break;
         }
      }
   }

   // try language-specific tag files
   if (_haveContextTagging() && langId != "" && foundFileList._length() == 0) {
      i := 0;
      orig_tag_file := tag_current_db();
      tag_files := tags_filenamea(langId);
      loop {
         tag_filename := next_tag_filea(tag_files, i, true, true);
         if (tag_filename == "") break;
         message("Searching: "tag_filename);
         foreach (ext in ext_list) {
            // look up the files in the tag file
            filename_in_tag_file := "";
            status := tag_find_file(filename_in_tag_file, filename_no_path"."ext);
            while (status == 0) {
               if (_file_eq(_strip_filename(filename_in_tag_file,'P'), filename_no_path"."ext) && file_exists(filename_in_tag_file)) {
                  foundFileList[foundFileList._length()] = filename_in_tag_file;
               }
               status = tag_next_file(filename_in_tag_file);
            }
         }
         tag_reset_find_file();
         if (foundFileList._length() > 0) {
            break;
         }
      }
      if (orig_tag_file != "") {
         tag_read_db(orig_tag_file);
      }
   }

   // remove duplicates
   foundFileList._sort();
   _aremove_duplicates(foundFileList, _file_eq("A","a"));

   // exactly one match, super!
   if (foundFileList._length() == 1) {
      filename = _maybe_quote_filename(foundFileList[0]);
      mou_hour_glass(false);
      return true;
   }

   // multiple matches, prompt
   if (foundFileList._length() > 1) {
      if (returnAll) {
         filename = "";
         foreach (auto fname in foundFileList) {
            _maybe_append(filename," ");
            filename :+= _maybe_quote_filename(fname);
         }
         mou_hour_glass(false);
         return true;
      } else {
         answer := select_tree(foundFileList);
         if (answer != "" && answer != COMMAND_CANCELLED_RC) {
            filename = _maybe_quote_filename(answer);
            mou_hour_glass(false);
            return true;
         }
      }
   }

   // that's all folks
   mou_hour_glass(false);
   return false;
}

static _str gassociated_extensions_for_language:[] = {
   "cs"           => "designer.cs xaml.cs xaml resx cs",
   "vb"           => "designer.vb xaml.vb xaml resx vb bas",
   "fs"           => "designer.fs xaml.fs xaml resx fs",
   "jsl"          => "designer.jsl xaml.jsl xaml resx jsl",
   "resx"         => "cs vb cpp h jsl fs resx xaml",
   "xaml"         => "cs vb cpp h jsl fs resx xaml",
   "c"            => "m mm cpp cppm cp cc cxx c++ inl ixx h hpp hp hh hxx h++ resx xaml qth",
   "m"            => "m mm cpp cppm cp cc cxx c++ inl ixx h hpp hp hh hxx h++ resx xaml qth",
   "ansic"        => "h c i",
   "ada"          => "ada adb ads",
   "d"            => "d di",
   "e"            => "e sh",
   "sv"           => "sv svh svi",
   "vr"           => "vr vfh vri",
};

/**
 * Returns the associated file for a given
 * filename (based on the file extension).
 *
 * @param filename
 * @param returnAll if 'true', does not prompt and instead returns
 *                  all the associated files for this file.
 *
 * @return _str Filename, or "" if no associated file was found
 */
_str associated_file_for(_str filename, bool returnAll=false)
{
   // NOTE: when adding support for other extensions
   // make sure to also add them to the list in the
   // _OnUpdate() function!

   // extract the extension
   langId    := _Filename2LangId(filename);
   extension := _get_extension(filename);
   filename   = _strip_filename(filename, 'E');

   // take care of nested extensions
   complete_extension := extension;
   switch (lowcase(extension)) {
   case "cs":
   case "vb":
   case "fs":
   case "jsl":
      inner_ext := _get_extension(filename);
      if (lowcase(inner_ext) == "xaml" || lowcase(inner_ext) == "designer") {
         complete_extension = inner_ext"."extension;
      }
      break;
   }


   // get the list of extensions to grok through and
   // check if our current extension is in the list of extensions
   associated_extensions := "";
   if (gassociated_extensions_for_language._indexin(langId)) {
      associated_extensions = gassociated_extensions_for_language:[langId];
   }
   if (gassociated_extensions_for_language._indexin(lowcase(extension))) {
      associated_extensions = gassociated_extensions_for_language:[lowcase(extension)];
   }

   // append other file extensions associated with this language
   other_extensions := _LangGetExtensions(langId);
   ex := "";
   foreach (ex in other_extensions) {
      if (!pos(" "_file_case(ex)" ", " "_file_case(associated_extensions)" ")) {
         associated_extensions :+= " "ex;
      }
   }

   // sort the list of extensions
   list := split2array(associated_extensions, " ");
   list._sort('F');
   associated_extensions = join(list, " ");

   // now try finding the current extension in the list of extensions
   if (associated_extensions != "") {
      // find the position of the current extension, and clip it out,
      // and rejigger the list so that we contiue searching in order
      i := pos(" "_file_case(complete_extension)" ", " "_file_case(associated_extensions)" ");
      if (i > 0) {
         head := substr(associated_extensions, 1, i-1);
         tail := substr(associated_extensions, i+length(complete_extension));
         associated_extensions = strip(tail" "head);
      }

      // now search for the file match
      if (!associated_file_exists(filename, associated_extensions, returnAll, langId)) {
         filename = "";
      }

   } else {
      // check for extension-specific callback
      index := find_index("_":+extension:+"_get_associated_file",PROC_TYPE);
      if (index_callable(index)) {
         filename = call_index(filename, returnAll, index);
      } else {
         // no match found
         filename = "";
      }
   }

   // strip quotes if not returning list of files
   if (!returnAll && filename != "" && file_exists(_maybe_unquote_filename(filename))) {
      return _maybe_unquote_filename(filename);
   }

   // return the list of files
   return filename;
}

/**
 * Find the header or source file associated with the current file in the editor
 * and open it.
 *
 * This function will search first in the same directory as the current file,
 * then in the current project, then the current workspace, then if no matches
 * are found, it will search all language-specific tag files.
 *
 * @see gui_open
 * @see edit
 * @categories File_Functions
 */
_command void edit_associated_file() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   // find the associated file
   filename := associated_file_for(p_buf_name);

   // edit the file
   if (filename != "") {
      edit(_maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
      message("Found: " filename);
   } else {
      message("No match found");
   }
}

int _OnUpdate_edit_associated_file(CMDUI &cmdui,int target_wid,_str command)
{
   // must have an editor control
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if(target_wid._ConcurProcessName()!=null) {
      return(MF_GRAYED);
   }

   // is this a supported langauge?
   ext := _get_extension(target_wid.p_buf_name);
   if (gassociated_extensions_for_language._indexin(target_wid.p_LangId)) {
      return MF_ENABLED;
   }
   if (gassociated_extensions_for_language._indexin(lowcase(ext))) {
      return MF_ENABLED;
   }

   // check if there are other file extensions associated with this language
   other_extensions := _LangGetExtensions(target_wid.p_LangId);
   if (other_extensions != "" && other_extensions != ext) {
      return MF_ENABLED;
   }

   // check for an extension specific callback
   index := find_index("_":+ext:+"_get_associated_file",PROC_TYPE);
   if (index_callable(index)) {
      return MF_ENABLED;
   }

   // not support for this extension
   return MF_GRAYED;
}

#if 0
/**
 * Called when the editor exits.  Removes all static globals
 * that don't need to go into the state file.
 */

void _before_write_state_stdcmds()
{
   _os_version_name = null; This causes a Slick-C stack and saves NO SIGNIFICANT SPACE
}
#endif
_str _xlatTMChars(_str caption) {
   // Replace (c) with copyright character
   // Replace (r) with registered trademark character
   // Replace (tm) with trademark character
   if( _UTF8() ) {
       caption=stranslate(caption,"\xC2\xA9","(C)",'I');
       caption=stranslate(caption,"\xC2\xAE","(R)",'I');
       caption=stranslate(caption,\xE2\x84\xA2,"(TM)",'I');
   } else {
      caption=stranslate(caption,"\xC2\xA9","(C)",'I');
      caption=stranslate(caption,"\xC2\xAE","(R)",'I');
       // There is generally no trademark symbol in the default font
       // used for the title bar (on Windows at least), so we will
       // not replace it.
   }
   return(caption);
}
_str _getApplicationName() {
   return(_default_option(VSOPTIONZ_APPLICATION_NAME));
}
_str _getDialogApplicationName() {
   return(_xlatTMChars(_default_option(VSOPTIONZ_APPLICATION_NAME)));
}

/**
 * Gets the value of a def-var.
 *
 * @param defVar              def-var we want value for
 * @param defaultValue        the default value we want to use if the def-var is
 *                            not in the names table, can be null
 *
 * @return                    current value of def-var
 */
typeless getDefVar(_str defVar, typeless defaultValue = null)
{
   // find our guy in the names table
   index := find_index(defVar, MISC_TYPE);

   if (index) {
      // it's there, so just return it
      return name_info(index);
   } else {
      // it is not there, so return a default value
      return defaultValue;
   }
}

#if 0
/**
 * Sets the value of a def-var.
 *
 * @param defVar           def-var we are setting
 * @param value            new value
 * @param defaultValue     default value of def-var - if the value matches the
 *                         default value, we will just delete the def-var from
 *                         the names table.  To avoid this deletion, do not
 *                         send a default value.
 */
int setDefVar(_str defVar, typeless value, typeless defaultValue = null)
{
   // find our guy in the names table
   index := find_index(defVar, MISC_TYPE);

   // find out if the value to set is just the default value of this def-var
   isValueDefault := (value != null && defaultValue != null && value :== defaultValue);

   if (index) {
      if (!isValueDefault) {
         // we don't want to set the same value all over again
         if (value != name_info(index)) {

            set_name_info(index, value);
            _config_modify_flags(CFGMODIFY_DEFDATA);
         }
      } else {
         // if this value is just the default value all over again,
         // we might as well delete the value out of the names table
         delete_name(index);
         index = 0;

         _config_modify_flags(CFGMODIFY_DEFDATA);
      }
   } else {
      // don't save the default, there's no point
      if (!isValueDefault) {
         index = insert_name(defVar, MISC_TYPE, value);
         if (!index) return(NOT_ENOUGH_MEMORY_RC);

         _config_modify_flags(CFGMODIFY_DEFDATA);
      }
   }

   return index;
}
#endif

/**
 * Copies current line or current selection up one line.  If no
 * selection is active, a LINE selection is created for the
 * current line.  If a selection is active, it is changed to
 * LINE selection and locked.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command void copy_lines_up() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (!select_active2()) {
      _deselect();
      select_line();
      _begin_select();
      up();
      _copy_to_cursor();
      down();
      deselect();
      return;
   }
   _select_type('','L',"LINE");
   _begin_select();
   up();
   _copy_to_cursor();
   down();
}

/**
 * Copies current line or current selection down line.  If no
 * selection is active, a LINE selection is created for the
 * current line. If a selection is active, it is changed to LINE
 * selection and locked.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command void copy_lines_down(bool do_smart_paste=true) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (!select_active2()) {
      _deselect();
      select_line();
      _copy_to_cursor();
      down();
      _deselect();
      return;
   }
   _select_type("","L","LINE");
   _end_select();
   _copy_to_cursor();
   down();
}

_command activate_editor() name_info(',')
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _mdi.p_child._set_focus();
   } else {
      _cmdline._set_focus();
   }
}


/**
 * Used as a callback by next_modified_line (you cannot have a
 * pointer to a built in)
 *
 * @return int return value from <B>up</B>
 */
static int myup()
{
   return up();
}

/**
 * Used as a callback by next_modified_line (you cannot have a
 * pointer to a built in)
 *
 * @return int return value from <B>down</B>
 */
static int mydown()
{
   return down();
}

/**
 * Find next line with modified or inserted flags.  Behaves like
 * Next button in diff.
 */
_command void next_modified_line(_str direction="+") name_info(',')
{
   ptrUpDown := mydown;
   if ( direction=="-" ) {
      ptrUpDown = myup;
   }
   int flags=_lineflags();
   if ( flags&(MODIFY_LF|INSERTED_LINE_LF) ) {
      next := flags;
      if ( flags&INSERTED_LINE_LF ) {
         next = MODIFY_LF;
      } else if ( flags&MODIFY_LF ) {
         next = INSERTED_LINE_LF;
      }

      found := false;
      save_pos(auto p);
      while ( !(*ptrUpDown)() ) {
         // First find a line with different flags
         curFlags := _lineflags();
         if ( curFlags&next ) {
            // INSERTED_LINE_LF gets visual precedence.  So we only stop at
            // lines that visuallly make sense, check for INSERTED_LINE_LF.
            if (next==INSERTED_LINE_LF || !(curFlags&INSERTED_LINE_LF)) {
               found = true;
               break;
            }
         }
         if ( !(curFlags&(MODIFY_LF|INSERTED_LINE_LF)) ) break;
      }
      if ( !found ) {
         // We're on a line with no inserted/modified flags, we have
         // some more work to do
         while ( !(*ptrUpDown)() ) {
            curFlags := _lineflags();
            if ( curFlags&(MODIFY_LF|INSERTED_LINE_LF) ) {
               found = true;
               break;
            }
         }
      }
      if ( !found ) restore_pos(p);
   } else {
      found := false;
      save_pos(auto p);
      while ( !(*ptrUpDown)() ) {
         curFlags := _lineflags();
         if ( curFlags&(MODIFY_LF|INSERTED_LINE_LF) ) {
            found = true;
            break;
         }
      }
      if ( !found ) restore_pos(p);
   }
}

/**
 * Find previous line with modified or inserted flags.  Behaves like
 * Prev button in diff.
 */
_command void prev_modified_line() name_info(',')
{
   next_modified_line("-");
}

bool _getAutoMargins(int &leftMargin,int &rightMargin) {
   typeless sleftMargin,srightMargin;
   parse p_margins with sleftMargin srightMargin .;
   leftMargin = sleftMargin;
   rightMargin = srightMargin;
   if (p_AutoLeftMargin) {
      save_pos(auto p);
      _first_non_blank();
      leftMargin = p_col;
      restore_pos(p);
      if (p_FixedWidthRightMargin) {
          rightMargin = leftMargin + p_FixedWidthRightMargin-1;
      }
   }
   // Return true if bad margins
   return (leftMargin + 3 >= rightMargin);
}

static bool _prevLineInDifferentParagraph(int non_blank_col) {
   result := true;
   save_pos(auto p);
   if(!up() && !_on_line0()) {
      _first_non_blank();
      if (_expand_tabsc(p_col,1)=="") {
         // Previous line is blank
         result=true;
      } else {
         result=p_col!=non_blank_col;
      }
   }
   restore_pos(p);
   return result;
}

/**
 * Initializes language options struct with typically required
 * properties.
 *
 * @param langOptions         Ouput. Propertiies set in this
 *                            structure.
 * @param initForNewLanguage  Determines whether some additional
 *                            properties are set.
 * @param newLanguageModeName Only used if initForNewLanguage is
 *                            true. Specifies mode name for new
 *                            language.
 */
void _LangInitOptions(VS_LANGUAGE_OPTIONS &langOptions, bool initForNewLanguage=false,_str newLanguageModeName="") {
   //langOptions.szRefersToLanguage="";
   langOptions._makeempty();

   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_AUTO_CAPS,"0");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_AUTO_LEFT_MARGIN,"0");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_BEGIN_END_PAIRS,"");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_BOUNDS,"0 0");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_COLOR_FLAGS,CLINE_COLOR_FLAG);
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_EVENTTAB_NAME,"");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN,"0");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_HEX_MODE,"0");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_INDENT_STYLE,INDENT_AUTO);
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_INDENT_WITH_TABS,"0");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_LEXER_NAME,"");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_MARGINS,"1 74 1");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_MODE_NAME,"");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS,DEFAULT_SPECIAL_CHARS);  // other control characters
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_SOFT_WRAP,"0");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_SOFT_WRAP_ON_WORD,"1");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_TABS,"+8");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_TRUNCATE_LENGTH,"0");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_WORD_CHARS,"A-Za-z0-9_$");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_WORD_WRAP_FLAGS,STRIP_SPACES_WWS|ONE_SPACE_WWS);

   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_CONTEXT_MENU,"_ext_menu_default");
   _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_CONTEXT_MENU_IF_SELECTION,"_ext_menu_default_sel");


#if 0
   langOptions.szBeginEndPairs="";
   langOptions.szAliasFilename="";
   langOptions.szInheritsFrom="";
   langOptions.LineNumbersLen=0;
   langOptions.LineNumbersFlags=0;

   langOptions.szFileExtensions="";

   langOptions.SyntaxIndent=0;
   langOptions.SyntaxExpansion=0;
   langOptions.minAbbrev=1;

   langOptions.IndentCaseFromSwitch=0;
   langOptions.PadParens=0;
   langOptions.NoSpaceBeforeParen=0;
   langOptions.BeginEndStyle=0;
   langOptions.PointerStyle=0;
   langOptions.FunctionBraceOnNewLine=0;
   langOptions.KeywordCasing= WORDCASE_PRESERVE;
   langOptions.TagCasing=0;
   langOptions.AttributeCasing=0;
   langOptions.ValueCasing=0;
   langOptions.HexValueCasing=0;
#endif
   if (initForNewLanguage) {
      _LangOptionsSetProperty(langOptions,LOI_SYNTAX_INDENT,4);
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_TABS,"+4");
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_EVENTTAB_NAME,"ext-keys");
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_MODE_NAME,newLanguageModeName);
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_INDENT_STYLE,INDENT_SMART);
   }
}
int _LangOptionsGetPropertyInt32(VS_LANGUAGE_OPTIONS &langOptions,_str propertyName, int defaultValue=0, bool &apply=null) {
   typeless value=_LangOptionsGetProperty(langOptions,propertyName,defaultValue,apply);
   if (isinteger(value)) {
      return value;
   }
   return defaultValue;
}
long _LangOptionsGetPropertyInt64(VS_LANGUAGE_OPTIONS &langOptions,_str propertyName, long defaultValue=0, bool &apply=null) {
   typeless value=_LangOptionsGetProperty(langOptions,propertyName,defaultValue,apply);
   if (isinteger(value)) {
      return value;
   }
   return defaultValue;
}

/**
 * Returns handle of text control of the output window.
 *
 * @return int Handle for the control, or 0 if it was not
 *         located.
 */
int output_window_text_control()
{
   oform := tw_find_form('_tboutputwin_form', _MDICurrent());
   if (oform <= 0) {
      oform = activate_tool_window('_tboutputwin_form');
   }
   return oform._find_control('ctloutput');
}

/**
 * Clears the output tool window.
 */
_command void clear_output_window() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   orig_win := p_window_id;
   p_window_id = output_window_text_control();

   lbc := find_index('_lbclear', PROC_TYPE);
   if (lbc >= 0) {
      call_index(lbc);
   }
   p_window_id = orig_win;
}

/**
 * Prompts the user for a file, and saves the contents of the
 * Output tool window to that file.
 */
_command void save_output_window() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   status := _open_temp_view('.output', auto temp, auto orig, '+b');
   if (status == 0) {
      save('');
      activate_window(orig);
      _delete_temp_view(temp);
   }
}

/**
 * Execs an external command, creating a temp view and
 * populating it with the output from the command. Optionally
 * also copies the output to the Output toolbar window.
 *
 * @param cmdline Command + parameters to send to exec.
 * @param tempView Output for the tempView id.
 * @param origView Output for the original view id.
 * @param progress Optional handle for a progress window, ala
 *                 'progress_show'.
 * @param progressCount If a progress window is supplied, how
 *                      many steps we're allowed to increment
 *                      the progress by.
 * @param copyToOutputWin If true, command output is also sent
 *                        to the Output tool window.
 *
 * @return int 0 On success, <0 on error, >0 if the command's
 *         exit code was not 0. If the return code is
 *         COMMAND_CANCELLED_RC, then the tempView wasn't
 *         created, and doesn't need to be cleaned up.
 */
int exec_command_to_temp_view(_str cmdline, int& tempView, int& origView, CTL_FORM progress = -1, int progressCount = 0, bool copyToOutputWin=true)
{
   origView = _create_temp_view(tempView, '');
   if (origView == 0) {
      return COMMAND_CANCELLED_RC;
   }

   oldmp := p_mouse_pointer;
   p_mouse_pointer = MP_HOUR_GLASS;
   tchand := copyToOutputWin ? output_window_text_control() : -1;
   rc := exec_command_to_window(cmdline, tempView, tchand, progress, progressCount);
   if (rc != 0) {
      parse cmdline with auto first ' ' auto rest;
      msg := 'Bad return code from 'first': 'rc;
      if (copyToOutputWin) {
         msg :+= ' See Output window for details.';
      }
      sticky_message(msg);
      p_window_id = origView;
      _delete_temp_view(tempView);
   }

   p_mouse_pointer = oldmp;
   return rc;
}

bool _last_line_not_terminated_with_eol() {
   if (_line_length()!=_line_length(true)) {
      return false;
   }
   save_pos(auto p);
   status:=down();
   restore_pos(p);
   return status?true:false;
}
