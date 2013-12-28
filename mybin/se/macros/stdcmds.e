////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50556 $
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
#include "slick_version.sh"
#include "license.sh"
#require "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "autobracket.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "box.e"
#import "c.e"
#import "clipbd.e"
#import "cobol.e"
#import "codehelp.e"
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
#import "mouse.e"
#import "markfilt.e"
#import "os2cmds.e"
#import "pip.e"
#import "pipe.e"
#import "projconv.e"
#import "project.e"
#import "pushtag.e"
#import "quickstart.e"
#import "recmacro.e"
#import "rul.e"
#import "selcode.e"
#import "seldisp.e"
#import "seltree.e"
#import "setupext.e"
#import "slickc.e"
#import "smartp.e"
#import "stdprocs.e"
#import "surround.e"
#import "tagform.e"
#import "tags.e"
#import "tbsearch.e"
#import "toolbar.e"
#import "util.e"
#import "vc.e"
#import "vi.e"
#import "vicmode.e"
#import "wkspace.e"
#import "xml.e"
#import "xmlwrap.e"
#import "se/ui/EventUI.e"
#import "se/ui/OvertypeMarker.e"
#endregion

using namespace se.lang.api;

const DIALOG_HISTORY_VIEW_ID = "DIALOG_HISTORY_VIEW_ID";
const OPTIONS_XML_HANDLE     = "OPTIONS_XML_HANDLE";
const C_STL_LANG_DAT_VIEW_ID = "C_STL_LANG_DAT_VIEW_ID";
const SELECT_MODE_VIEW_ID    = "SELECT_/dMODE_VIEW_ID";

#define MIN_PROG_INFO_WIDTH 8000
#define MIN_PROG_INFO_HEIGHT 7000

#define JAVADOC_TAGS_FROM_SIG "param,return,exception,throws"

struct ScreenInfo {
   int x;
   int y;
   int width;
   int height;
};

_str process_mark;
_str _error_mark;
_str _top_process_mark;//All you need from here are this and the initialization in
//definit.  Any other differences are unintentional.
_str compile_rc;
//static int gsmartnextwindow_state;

/**
 * If enabled, cancel current selection after copy to cursor
 * or move to cursor operation.
 *
 * @default 0
 * @categories Configuration_Variables
 */
boolean def_deselect_copyto=0;

/**
 * If enabled, attempt to automatically quit the build
 * window when the command shell exits.
 *
 * @default false
 * @categories Configuration_Variables
 */
boolean def_close_build_window_on_exit=false;

/**
 * If enabled, push a bookmark before jumping to the top or
 * bottom of the current buffer.  This allows you to use
 * pop-bookmark to jump back to the previous location.
 *
 * @default false
 * @categories Configuration_Variables
 */
boolean def_top_bottom_push_bookmark=false;

/**
 * If enabled, {@link end_line_text_toggle}() will stop at
 * the vertical line column before stopping at the
 * end of the line.
 *
 * @default false
 * @categories Configuration_Variables
 */
boolean def_end_line_stop_at_vertical_line=false;

/**
 * If enabled, use S/390 display translations.
 *
 * @see p_display_xlat
 * @default false
 * @categories Configuration_Variables
 */
int def_use_390_display_translations=0;

static _str g390DisplayTranslationTable='';

/**
 * If one of these directory names are found along a path
 * to an extensionless file, consider the file as C++
 *
 * @default "inc|include|c++|g++-2|g++-3|g++-4";
 * @categories Configuration_Variables
 */
_str def_cpp_include_path_re = "inc|include|c\\+\\+|g\\+\\+-[234]";

boolean def_word_continue=false;

/**
 * When enabled, if you undo all the changes up to the last save, 
 * you will be prompted whether you want to continue undoing changes.
 *
 * @default true
 * @categories Configuration_Variables
 */
boolean def_undo_past_save_prompt=true;

no_code_swapping;   /* Just in case there is an I/O error reading */
/* the slick.sta file, this will ensure user */
/* safe exit and save of files.  Common cursor */
/* movement commands will not cause module swapping. */
static boolean undo_past_save;
static _str _command_mark,_orig_mark;
static _str _command_op_list;

static int _picwin_cbarrow;
static int _picwin_cbdots;
static int _picwin_cbdis;
static int gInSelEditModeCallback=0;

static _str _os_version_name = '';

int _DebugPictureTab[];   // Global debug picture indexes for faster initialization

definit()
{
   _str initArg=arg(1);
   if (_UTF8()) {
      _extra_word_chars='\p{L}';
   } else if (_dbcs()) {
      _extra_word_chars='';
   } else {
      _extra_word_chars='\128-\255';
   }
   //gorig_wid=0;gsmartnextwindow_state=0;
   _UpgradeLanguageSetup();
   gNoTagCallList=0;

   rc=0;
   _str _last_have_dll='';
   _get_string='';
   _get_string2='';

   gvsPrintOptions.print_header="%f";
#if __UNIX__
   gvsPrintOptions.print_footer="%p";
#else
   gvsPrintOptions.print_footer="%p of %n";
#endif
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
      _xmlTempTagFileList._makeempty();
      _trialMessageDisplayedFlags1=0;

      _html_tempfile='';
      //This is used for VC++ options when someone compiles a single file.
      // I suppose we could just user _html_tempfile, but there is a possiblitly
      // that someone could launch an applet, then run a compile before it closed.
      _vcpp_compiler_option_tempfile='';
      _clear_dir_stack();
      old_search_bounds=null;
      _error_file=GetErrorFilename();//GetErrorFilename sets COMPILE_ERROR_FILE
      _last_open_path='';_last_open_cwd='';
      // Position where last compile was started
      // Don't go past here when searching for the previous error.
      _top_process_mark='';
      process_mark=''; /* Position of last error found by NEXT-ERROR in .process. */
      _error_mark='';  /* Position of last error found by NEXT-ERROR in $errors.tmp*/
      process_retrieve_id='';
      process_first_retrieve=1;
      gerror_info._makeempty();
      _error_file='';
      _grep_buffer='';
      compile_rc=0;
      _cua_select=0;
      _command_op_list='';
      _command_mark='';
      _orig_mark='';
      _os_version_name='';
      if (index_callable(find_index('_prjupdate_cobol',PROC_TYPE))) {
         // Make sure current object is not an editor control
         // so that there is no file I/O
         _cmdline._prjupdate_cobol();
      }


      //_cua_textbox(def_cua_textbox)
   } else {
      _pic_xclose_mono=load_picture(-1,"_xclose_mono.bmp");
      _pic_pinin_mono=load_picture(-1,"_pinin_mono.bmp");
      _pic_pinout_mono=load_picture(-1,"_pinout_mono.bmp");

      load_picture(-1,'_arrowlt.ico');
      load_picture(-1,'_arrowgt.ico');
      load_picture(-1,'_arrowc.ico');
      load_picture(-1,'_buttonarrow.ico');
      load_picture(-1,'_push_tag.ico');

      _pic_file=load_picture(-1,'_file.ico');
      _pic_file_red_edge=load_picture(-1,'_file_mod.ico');
      _pic_file_d=load_picture(-1,'_filed.ico');
      _pic_file12=load_picture(-1,'_file12.ico');
      _pic_file_d12=load_picture(-1,'_filed12.ico');

      _pic_drcdrom=load_picture(-1,'_drcdrom.ico');
      _pic_drremov=load_picture(-1,'_drremov.ico');
      _pic_drfixed=load_picture(-1,'_drfixed.ico');
      _pic_drremote=load_picture(-1,'_drremote.ico');

      _picwin_cbarrow=load_picture(-1,'_cbarrow.ico');
      _picwin_cbdots=load_picture(-1,'_cbdots.ico');
      _picwin_cbdis=load_picture(-1,'_cbdis.ico');

      #if __MACOSX__
      _pic_fldaop=load_picture(-1,'_fldopen_mac.png');
      _pic_fldclos=load_picture(-1,'_fldclos_mac.png');
      _pic_fldopen=load_picture(-1,'_fldopen_mac.png');
      _pic_fldclos12=load_picture(-1,'_fldclos12_mac.png');
      _pic_fldopen12=load_picture(-1,'_fldopen12_mac.png');
      #else
      _pic_fldaop=load_picture(-1,'_fldaop.ico');
      _pic_fldclos=load_picture(-1,'_fldclos.ico');
      _pic_fldopen=load_picture(-1,'_fldopen.ico');
      _pic_fldclos12=load_picture(-1,'_fldclos12.ico');
      _pic_fldopen12=load_picture(-1,'_fldopen12.ico');
      #endif
      
      _pic_fldtags=load_picture(-1,'_fldtags.ico');
      _pic_fldctags=load_picture(-1,'_fldctags.ico');
      _pic_tt=load_picture(-1,'_tt.ico');
      _pic_printer=load_picture(-1,'_printer.ico');
      _pic_search12=load_picture(-1, '_search12.ico');
      _pic_build12=load_picture(-1, '_build12.ico');

      _pic_xml_tag = _update_picture(-1, "_clstag0.ico");
      _pic_xml_attr = _update_picture(-1, "_clsdat0.ico");
      _pic_xml_target = _update_picture(-1, "_clslab0.ico");

      load_picture(-1,'_edsoftwrapm6x9.bmp');
      load_picture(-1,'_edsoftwrapm4x6.bmp');

      load_picture(-1,'_edplus.ico');
      load_picture(-1,'_edminus.ico');
      load_picture(-1,'_edbookmark.ico');
      load_picture(-1,'_edpushbookmark.ico');
      load_picture(-1,'_edannotation.ico');
      load_picture(-1,'_edannotationgray.ico');

      _pic_lbplus=load_picture(-1,'_lbplus.ico');
      _pic_lbminus=load_picture(-1,'_lbminus.ico');
      _pic_lbvs=load_picture(-1,'_lbvs.ico');
      _pic_func=load_picture(-1,'_func.ico');
      _pic_sm_file=load_picture(-1,'_smfile.ico');
      _pic_sm_file_d=load_picture(-1,'_smfiled.ico');
      _pic_sm_func=load_picture(-1,'_smfunc.ico');

      //1:13pm 6/22/1998
      //Dan added these bitmaps for the new project toolbar stuff....
      _pic_vc_co_user_w=load_picture(-1,'_docvcc.ico');
      set_name_info(_pic_vc_co_user_w,"You have this file checked out");
      _pic_vc_co_user_r=load_picture(-1,'_docvccg.ico');
      set_name_info(_pic_vc_co_user_r,"You have this read only file checked out");
      _pic_vc_co_other_m_w=load_picture(-1,'_docvccm.ico');
      set_name_info(_pic_vc_co_other_m_w,"Another user has this file checked out");
      _pic_vc_co_other_m_r=load_picture(-1,'_docvcrm.ico');
      set_name_info(_pic_vc_co_other_m_r,"Another user has this read only file checked out");
      _pic_vc_co_other_x_w=load_picture(-1,'_docvcwx.ico');
      set_name_info(_pic_vc_co_other_x_w,"Another user has this file checked out exclusively");
      _pic_vc_co_other_x_r=load_picture(-1,'_docvccx.ico');
      set_name_info(_pic_vc_co_other_x_r,"Another user has this read only file checked out exclusively");
      _pic_vc_available_w=load_picture(-1,'_docvc.ico');
      set_name_info(_pic_vc_available_w,"This file is available for check out");
      _pic_vc_available_r=load_picture(-1,'_docvcg.ico');
      set_name_info(_pic_vc_available_r,"This read only file is available for check out");
      _pic_doc_d=load_picture(-1,'_docd.ico');
      _pic_doc_w=load_picture(-1,'_doc.ico');
      _pic_doc_r=load_picture(-1,'_docg.ico');
      _pic_doc_ant=load_picture(-1,'_doctarget.ico');
      set_name_info(_pic_doc_ant,"This is a build file");

      _pic_tfldopen=_pic_tfldclos=load_picture(-1,'_tfldcls.ico');
      _pic_tfldopendisabled=_pic_tfldclosdisabled=load_picture(-1,'_tfldclsd.ico');
      //_pic_tfldopen=load_picture(-1,'_tfldopn.ico');
      //_pic_tfldopendisabled=load_picture(-1,'_tfldopnd.ico');
      _pic_tproject=load_picture(-1,'ptproject.ico');

      _pic_tpkgclos=load_picture(-1,'_tpkgcls.ico');

      // Bitmaps for dynamic surround and auto complete
      _pic_surround = load_picture(-1,'_surround.ico');
      _pic_light_bulb = load_picture(-1, '_edhint.ico');
      _pic_keyword = load_picture(-1,'_keyword.ico');
      if (_pic_keyword >= 0) {
         set_name_info(_pic_keyword, 'Keyword');
      }
      _pic_syntax = load_picture(-1,'_syntax.ico');
      if (_pic_syntax >= 0) {
         set_name_info(_pic_syntax, 'Syntax expansion');
      }
      _pic_complete_prev = load_picture(-1,'_complete_prev.ico');
      if (_pic_complete_prev >= 0) {
         set_name_info(_pic_complete_prev, 'Word completion on earlier line in file');
      }
      _pic_complete_next = load_picture(-1,'_complete_next.ico');
      if (_pic_complete_next >= 0) {
         set_name_info(_pic_complete_next, 'Word completion on subsequent line in file');
      }
      _pic_alias = load_picture(-1,'_alias.ico');
      if (_pic_alias >= 0) {
         set_name_info(_pic_alias, 'Alias or code template');
      }

      // Bitmaps for the debugger
      int breakpt_index=load_picture(-1,'_breakpt.ico');
      int execbrk_index=load_picture(-1,'_execbrk.ico');
      int execpt_index=load_picture(-1,'_execpt.ico');
      int stackbrk_index=load_picture(-1,'_stackbr.ico');
      int stackexc_index=load_picture(-1,'_stackex.ico');
      int watchpt_index=load_picture(-1,'_watchpt.ico');
      int watchpn_index=load_picture(-1,'_watchpn.ico');

      int breakpn_index=load_picture(-1,'_breakpn.ico');
      int execbn_index=load_picture(-1,'_execbn.ico');
      int stackbn_index=load_picture(-1,'_stackbn.ico');

      _pic_project2=_pic_project=load_picture(-1,'_project.ico');
      _pic_workspace=load_picture(-1,'_wkspace.ico');
      _pic_treecb_blank=load_picture(-1,'_cbblank.ico');

      _pic_job=load_picture(-1,'_job.ico');
      _pic_jobdd=load_picture(-1,'_jobdd.ico');
      // Load all of the picures that we need, and set up their help bubbles
      _pic_branch=load_picture(-1,'_cvsbranch2.ico');
      if ( _pic_branch>=0 ) {
         set_name_info(_pic_branch,"This is a branch tag");
      }
      _pic_cvs_file=load_picture(-1,'_cvs_file.ico');
      _pic_cvs_file_qm=load_picture(-1,'_cvs_file_qm.ico');
      if ( _pic_cvs_file_qm>=0 ) {
         set_name_info(_pic_cvs_file_qm,"This file does not exist in the repository");
      }
      _pic_file_old=load_picture(-1,'_cvs_file_date.ico');
      if ( _pic_file_old>=0 ) {
         set_name_info(_pic_file_old,"This file is older than the version in the repository");
      }
      _pic_file_mod=load_picture(-1,'_cvs_file_mod.ico');
      if ( _pic_file_mod>=0 ) {
         set_name_info(_pic_file_mod,"This file is modified locally");
      }
      _pic_file_mod_prop=load_picture(-1,'_cvs_file_mod.ico');
      if ( _pic_file_mod_prop>=0 ) {
         set_name_info(_pic_file_mod_prop,"This file's properties are modified locally");
      }
      _pic_file_mod2 = load_picture(-1, '_cvs_file.ico');
      if (_pic_file_mod2 >= 0) {
         set_name_info(_pic_file_mod2, "Another application has modified the file");
      }
      _pic_file_del = load_picture(-1, '_cvs_file_m.ico');
      if (_pic_file_del >= 0) {
         set_name_info(_pic_file_del, "Another application has deleted the file");
      }
      _pic_file_buf_mod = load_picture(-1, '_file_buf_mod.ico');
      if (_pic_file_buf_mod >= 0) {
         set_name_info(_pic_file_buf_mod, "Another application has modified the ":+
                       "file and the buffer is unsaved");
      }
      _pic_file_old_mod=load_picture(-1,'_cvs_file_mod_date.ico');
      if ( _pic_file_old_mod>=0 ) {
         set_name_info(_pic_file_old_mod,"This file is older than the version in the repository,and modified locally");
      }
      _pic_cvs_file_obsolete=load_picture(-1,'_cvs_file_obsolete.ico');
      if ( _pic_cvs_file_obsolete>=0 ) {
         set_name_info(_pic_cvs_file_obsolete,"This file exists locally, but no longer exists in the repository");
      }
      _pic_cvs_file_new=load_picture(-1,'_cvs_file_new.ico');
      if ( _pic_cvs_file_new>=0 ) {
         set_name_info(_pic_cvs_file_new,"This file is in the repository, but does not exist locally");
      }
      // Use 0 here, we have 2 copies of the same bitmap so that we can have
      // separate messages
      _pic_cvs_filem=load_picture(0,'_cvs_file_m.ico');
      if ( _pic_cvs_filem>=0 ) {
         set_name_info(_pic_cvs_filem,"This file has been removed");
      }
      _pic_cvs_filem_mod=load_picture(-1,'_cvs_file_m_mod.ico');
      if ( _pic_cvs_filem_mod>=0 ) {
         set_name_info(_pic_cvs_filem_mod,"This file has been removed but not commited");
      }
      _pic_cvs_filep=load_picture(-1,'_cvs_file_p.ico');
      if ( _pic_cvs_filep>=0 ) {
         set_name_info(_pic_cvs_filep,"This file has been added but not commited");
      }
      _pic_cvs_fld_m=load_picture(-1,'_cvs_fld_m.ico');
      if ( _pic_cvs_fld_m>=0 ) {
         set_name_info(_pic_cvs_fld_m,"This directory exists locally, but no longer exists in the repository");
      }
      _pic_cvs_fld_date=load_picture(-1,'_cvs_fld_date.ico');
      if ( _pic_cvs_fld_date>=0 ) {
         set_name_info(_pic_cvs_fld_date,"This directory is older than the version in the repository");
      }
      _pic_cvs_fld_mod=load_picture(-1,'_cvs_fld_mod.ico');
      if ( _pic_cvs_fld_mod>=0 ) {
         set_name_info(_pic_cvs_fld_mod,"This directory is modified but not commited (it has probably been merged from another branch)");
      }
      _pic_cvs_fld_p=load_picture(-1,'_cvs_fld_p.ico');
      if ( _pic_cvs_fld_p>=0 ) {
         set_name_info(_pic_cvs_fld_p,"This directory is in the repository does not exist locally");
      }
      _pic_cvs_fld_qm=load_picture(-1,'_cvs_fld_qm.ico');
      if ( _pic_cvs_fld_qm>=0 ) {
         set_name_info(_pic_cvs_fld_qm,"This directory does not exist in the repository");
      }
      _pic_cvs_file_error=load_picture(-1,'_cvs_file_error.ico');
      if ( _pic_cvs_file_error>=0 ) {
         set_name_info(_pic_cvs_file_error,"There is a problem with this file.  It probably exists locally, but is not in the CVS Entries file");
      }
      _pic_cvs_fld_error=load_picture(-1,'_cvs_fld_error.ico');
      if ( _pic_cvs_fld_error>=0 ) {
         set_name_info(_pic_cvs_fld_error,"There is a problem with this directory.  It probably exists locally, but is not in the CVS Entries file");
      }
      _pic_cvs_file_conflict=load_picture(-1,'_cvs_file_conflict.ico');
      if ( _pic_cvs_file_conflict>=0 ) {
         set_name_info(_pic_cvs_file_conflict,"There is a conflict in this file");
      }
      _pic_cvs_file_conflict_updated=load_picture(-1,'_cvs_file_conflict_updated.ico');
      if ( _pic_cvs_file_conflict_updated>=0 ) {
         set_name_info(_pic_cvs_file_conflict_updated,"There was a conflict in this file and it cannot be commited until it is modified");
      }
      _pic_cvs_file_conflict_local_added=load_picture(-1,'_cvs_file_conflict_local_add.ico');
      if ( _pic_cvs_file_conflict_local_added>=0 ) {
         set_name_info(_pic_cvs_file_conflict_local_added,"There was a conflict: local add, incoming add upon merge.");
      }
      _pic_cvs_file_conflict_local_deleted=load_picture(-1,'_cvs_file_conflict_local_add.ico');
      if ( _pic_cvs_file_conflict_local_deleted>=0 ) {
         set_name_info(_pic_cvs_file_conflict_local_deleted,"There was a conflict: local delete, incoming delete upon merge.");
      }
      _pic_cvs_file_copied=load_picture(-1,'_cvs_file_copied.ico');
      if ( _pic_cvs_file_copied>=0 ) {
         set_name_info(_pic_cvs_file_copied,"This file is copied in the index.");
      }
      _pic_cvs_file_not_merged=load_picture(-1,'_cvs_file_not_merged.ico');
      if ( _pic_cvs_file_not_merged>=0 ) {
         set_name_info(_pic_cvs_file_not_merged,"This file has been updated but not merged.");
      }
      _pic_cvs_module=load_picture(-1,'_module.ico');

      _pic_vc_user_bitmap  = load_picture(-1, "_vc_user.ico");
      _pic_vc_label_bitmap  = load_picture(-1, "_vc_label.ico");
      _pic_vc_floatingdate_bitmap  = load_picture(-1, "_vc_floatingdate.ico");
      _pic_linked_bitmap  = load_picture(-1, "_diff_path_link.ico");
      _pic_del_linked_bitmap  = load_picture(-1, "_diff_path_del_link.ico");
      _pic_diff_code_bitmap  = load_picture(-1, "_diff_code.ico");
      _pic_del_diff_code_bitmap  = load_picture(-1, "_diff_code_del.ico");
      _pic_diff_path_up  = load_picture(-1, "_arrow_up_blue.ico");
      _pic_diff_path_down  = load_picture(-1, "_arrow_down_blue.ico");

      _pic_file_reload_overlay  = load_picture(-1, "_file_reload_overlay.ico");
      if ( _pic_file_reload_overlay>=0 ) {
         set_name_info(_pic_file_reload_overlay,"There is a newer version of this file on disk");
      }
      _pic_file_date_overlay  = load_picture(-1, "_file_date_overlay.ico");
      if ( _pic_file_date_overlay>=0 ) {
         set_name_info(_pic_file_date_overlay,"This file is older than the version in the repository");
      }
      _pic_file_mod_overlay  = load_picture(-1, "_file_mod_overlay.ico");
      if ( _pic_file_mod_overlay>=0 ) {
         set_name_info(_pic_file_mod_overlay,"This file is modified locally");
      }
      _pic_file_checkout_overlay  = load_picture(-1, "_file_checkout_overlay.ico");
      if ( _pic_file_checkout_overlay>=0 ) {
         set_name_info(_pic_file_checkout_overlay,"This file is checked out");
      }

      _pic_diff_all_symbols = load_picture(-1,"_diff_all_symbols.ico");
      _pic_diff_one_symbol = load_picture(-1,"_diff_one_symbol.ico");

      // Sandra added these for the enhanced open toolbar

      _pic_otb_file_disk_open = load_picture(-1, '_filedisko.ico');
      _pic_otb_file_proj = load_picture(-1, '_fileprj.ico');
      _pic_otb_file_proj_open = load_picture(-1, '_fileprjo.ico');
      _pic_otb_file_wksp = load_picture(-1, '_filewksp.ico');
      _pic_otb_file_wksp_open = load_picture(-1, '_filewkspo.ico');
      _pic_otb_file_open = load_picture(-1, '_fileo.ico');
      _pic_otb_file_hist = load_picture(-1, '_filehist.ico');
      _pic_otb_file_hist_open = load_picture(-1, '_filehisto.ico');
      _pic_otb_network = load_picture(-1, '_network.ico');
      _pic_otb_favorites = load_picture(-1, '_favorites.ico');
      _pic_otb_server = load_picture(-1, '_server.ico');
      _pic_otb_share = load_picture(-1, '_share.ico');
      _pic_otb_cdrom = load_picture(-1, '_drcd2.ico');
      _pic_otb_remote = load_picture(-1, '_drnetwk.ico');
      _pic_otb_floppy = load_picture(-1, '_drflop.ico');

      #if __MACOSX__
      _pic_otb_cd_up = load_picture(-1, '_fldcdup_mac.png');
      _pic_otb_computer = load_picture(-1, '_computer_mac.png');
      _pic_otb_fixed = load_picture(-1, '_drfix2_mac.png');
      #else
      _pic_otb_cd_up = load_picture(-1, '_fldcdup.ico');
      _pic_otb_computer = load_picture(-1, '_computer.ico');
      _pic_otb_fixed = load_picture(-1, '_drfix2.ico');
      #endif
      int i;

#if USE_CVS_ANIMATION_PICS
      for (i=0;i<=20;++i) {
         int index=isinteger(_cvs_animation_pics[i])?_cvs_animation_pics[i]:-1;
         _str suffix='';
         if (length(i)<2) {
            suffix='0';
         }
         suffix=suffix:+i;
         if (index<=0) {
            _cvs_animation_pics[i]=load_picture(-1,CVS_STALL_PICTURE_PREFIX:+suffix'.ico');
         }
      }
#endif

#define VSBPFLAG_BREAKPOINT        0x00000001    /* Break point on this line*/
#define VSBPFLAG_EXEC              0x00000002    /* Line about to be executed. */
#define VSBPFLAG_STACKEXEC         0x00000004    /* Call Stack execution line */
#define VSBPFLAG_BREAKPOINTDISABLED   0x00000008 /* Break point disabled*/

#define VSBPFLAGC_NOFBITMAPS (0x0f+1)
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
   _pic_cbarrow=_picwin_cbarrow;
   _pic_cbdots=_picwin_cbdots;
   _pic_cbdis=_picwin_cbdis;
   // Editor initialization case or building state file.
   if ( arg(1):!='L' || editor_name('s')=='') {
      _str clex_file_list=LEXER_FILE_LIST;
      for (;;) {
         _str clex_file='';
         parse clex_file_list with clex_file (PATHSEP) clex_file_list;
         if (clex_file=='') {
            break;
         }
         if (clex_file!='') {
            //clex_file=path_search(filename);
            _clex_load(clex_file);
         }
      }
   }
   _in_quit=0;
   _in_exit_list=0;
   _in_help=0;
   undo_past_save=0;
   if (name_on_key(name2event('a-f4'))!= 'safe-exit') {
      _mdi._sysmenu_bind(SC_CLOSE,"&Close");
   }
   {
      int breakpt_index=find_index('_breakpt.ico');
      int execbrk_index=find_index('_execbrk.ico',PICTURE_TYPE);
      int execpt_index=find_index('_execpt.ico',PICTURE_TYPE);
      int stackbrk_index=find_index('_stackbr.ico',PICTURE_TYPE);
      int stackexc_index=find_index('_stackex.ico',PICTURE_TYPE);
      int watchpt_index=find_index('_watchpt.ico');
      int watchpn_index=find_index('_watchpn.ico');

      int breakpn_index=find_index('_breakpn.ico',PICTURE_TYPE);
      int execbn_index=find_index('_execbn.ico',PICTURE_TYPE);
      int stackbn_index=find_index('_stackbn.ico',PICTURE_TYPE);
      int execgo_index=find_index('_execgo.ico',PICTURE_TYPE);
      int stackgo_index=find_index('_stackgo.ico',PICTURE_TYPE);

      int annotation_index=find_index('_edannotation.ico',PICTURE_TYPE);
      int annotationgray_index=find_index('_edannotationgray.ico',PICTURE_TYPE);
      int bookmark_index=find_index('_edbookmark.ico',PICTURE_TYPE);
      int pushbm_index=find_index('_edpushbookmark.ico',PICTURE_TYPE);

      int edplus_index=find_index('_edplus.ico',PICTURE_TYPE);
      int edminus_index=find_index('_edminus.ico',PICTURE_TYPE);

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

   int dialogs_view_id=0;
   int orig_view_id=_find_or_create_temp_view(dialogs_view_id,'+futf8 +70 +t','.dialogs',false,VSBUFFLAG_THROW_AWAY_CHANGES,true);
   activate_window(orig_view_id);
   _SetDialogInfoHt(DIALOG_HISTORY_VIEW_ID, dialogs_view_id, _mdi);
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
   if (path=='') {
#if !__UNIX__
      path=get_env('TEMP');
#endif
      if (path=='') {
         path=get_env('TMP');
      }
   }
   if (path=='') {
#if __UNIX__
      path='/tmp/';
#else
      path='c:\temp\';
#endif
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
 * <p>If a unique name can not be created after 99 tries, '' is returned.</p>
 *
 * @categories Miscellaneous_Functions
 *
 */
_str mktemp(int start=1,_str Extension='')
{
   _str path=_temp_path();
   int i,pid=getpid();
   int buf_id;
   for (i=start; i<=99 ; ++i) {
      buf_id=0;
      if (p_HasBuffer) {
         buf_id=p_buf_id;
      }
      _str name=path:+substr(pid,1,6,'0'):+i'b'buf_id:+Extension;
      if ( file_match('-p 'name,1)=='' ) {
         return(name);
      }
   }
   return('');
}

void _on_keystatechange(int shiftnum = -1,boolean IsKeydownEvent = false)
{
   if (shiftnum < 0) {
      return; //inadvertant call
   }
   //say('_on_keystatechange k='event2name(last_event())' shiftnum='shiftnum);
   // IF this was a keydown event and the Right Control key was down
   if (IsKeydownEvent && shiftnum==1 && def_keys=='ispf-keys') {
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
      //say('IsKeydownEvent='IsKeydownEvent);
      //say('shiftnum='shiftnum);
   }
   if (_IsKeyDown(CTRL)) {
      _UpdateURLsMousePointer(true);
   } else {
      _UpdateURLsMousePointer(false);
   }
#if 0
   if (_IsKeyDown(CTRL)) {
      //say('_on_keystatechange: CTRL DOWN');
      if (!gsmartnextwindow_state) {
         gsmartnextwindow_state=1;
         gorig_wid=_mdi.p_child;
         if (gorig_wid.p_window_flags & HIDE_WINDOW_OVERLAP) {
            gorig_wid=0;
         }
      }
      //say('down N='gorig_wid.p_buf_name);
   } else {
      //say('_on_keystatechange: CTRL UP');
      gsmartnextwindow_state=0;
      //say('up N='gorig_wid);
      int final_wid=_mdi.p_child;
      if (!(final_wid.p_window_flags & HIDE_WINDOW_OVERLAP) &&
           (_iswindow_valid(gorig_wid) && gorig_wid.p_mdi_child) &&
          final_wid!=gorig_wid) {
         if (_default_option(VSOPTION_NEXTWINDOWSTYLE)==1) {
            // Put final before original
            //say('_on_keystatechange: reorder N='gorig_wid.p_buf_name' f='final_wid.p_buf_name);
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
boolean _DialogViewingBuffer(int buf_id,int skip_wid=0)
{
   int i;
   for (i=1;i<=_last_window_id();++i) {
      if (i!=skip_wid && _iswindow_valid(i) && !i.p_mdi_child &&
          i.p_HasBuffer && i.p_buf_id==buf_id && i!=VSWID_HIDDEN
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
boolean _SafeToDeleteBuffer(int buf_id,int skip_dialog_wid=0,int buf_flags=0)
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
         _message_box(nls('Unable to load picture "%s"',filename)'. 'get_message(result));
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
_command void key_not_defined() name_info(','VSARG2_LASTKEY|VSARG2_EDITORCTL)
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
   _str msg='';
   if ( status&LINE_INSERTS_UNDONE ) {
      msg=nls('Line insert(s),');
   }
   if ( status&LINE_DELETES_UNDONE ) {
      msg=msg:+nls('Line delete(s),');
   }
   if ( status&MARK_CHANGE_UNDONE ) {
      msg=msg:+nls('Mark change,');
   }
   if ( status&TEXT_CHANGE_UNDONE ) {
      msg=msg:+nls('Text change,');
   }
   if ( status&CURSOR_MOVEMENT_UNDONE ) {
      msg=msg:+nls('Cursor movement,');
   }
   if (status & LINE_FLAGS_UNDONE) {
      msg=msg:+nls('Line flags,');
   }
   if (status & FILE_FORMAT_CHANGE_UNDONE) {
      msg=msg:+nls('File Format Change,');
   }
   if (status & COLOR_CHANGE_UNDONE) {
      msg=msg:+nls('Color Change,');
   }
   if (status & MARKUP_CHANGE_UNDONE) {
      msg=msg:+nls('Markup Change,');
   }
   msg=strip(msg,'T',','):+' 'nls('undone');
   if ( p_undo_steps==0 ) {
      msg=nls('Undo not on');
   }
   return(msg);

}

static _str past_save(...)
{
   boolean bool;
   if ( undo_past_save && def_undo_past_save_prompt) {
      _str name= name_name(prev_index('','C'));
      if ( arg(1)!='' ) {
         bool=(name=='redo');
      } else {
         bool=(name=='undo' || name=='undo-line' || name=='undo-cursor');
      }
      if ( bool ) {
         flush_keyboard();
         int result=_message_box(nls("You are about to undo past previous save.\nContinue?"),'',MB_ICONQUESTION|MB_YESNOCANCEL);
         if ( result!=IDYES) {
            return(1);
         }
      }
      undo_past_save=0;
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

// If this is set to true, undo will undo each individual cursor movement
boolean def_undo_with_cursor=false;

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
 * <p>If def_undo_with_cursor is false, this behaves the
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
   _str undo_opt=def_undo_with_cursor?'':'C';
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
_str ispf_convert_re(_str searchString,boolean reverse=false)
{
   _str result="";
   int i,n=length(searchString);
   for (i=1;i<=n;++i) {
      _str ch=substr(searchString,i,1);
      _str add='';
      //say("ispf_convert_re: ch='"ch"'");
      if (reverse==true) {
         if (ch=='[') {
            int p=pos(']',searchString,i);
            if (p) {
               ch=substr(searchString,i,p-i+1);
               i=p;
            }
         }
         switch (ch) {
         case '?':
            add='=';
            break;
         case '[~ \t]':
         case '[^ \t]':
            add='^';
            break;
         case '[~\x20-\x7e]':
         case '[^\x20-\x7e]':
            add='.';
            break;
         case '[0-9]':
            add='#';
            break;
         case '[~0-9]':
         case '[^0-9]':
            add='-';
            break;
         case '[a-zA-Z]':
            add='@';
            break;
         case '[a-z]':
            add='<';
            break;
         case '[A-Z]':
            add='>';
            break;
         case '[~ \ta-zA-Z0-9]':
         case '[^ \ta-zA-Z0-9]':
            add='$';
            break;
         default:
            if (substr(ch,1,1)=='[' &&
                isalpha(substr(ch,2,1)) &&
                substr(ch,3,1)==upcase(substr(ch,2,1)) &&
                substr(ch,4,1)==']') {
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
         case '=':
            add='?';
            break;
         case '^':
            add='[~ \t]';
            break;
         case '.':
            add='[~\x20-\x7e]';
            break;
         case '#':
            add='[0-9]';
            break;
         case '-':
            add='[~0-9]';
            break;
         case '@':
            add='[a-zA-Z]';
            break;
         case '<':
            add='[a-z]';
            break;
         case '>':
            add='[A-Z]';
            break;
         case '$':
            add='[~ \ta-zA-Z0-9]';
            break;
         default:
            if (isalpha(ch)) {
               add='['lowcase(ch):+upcase(ch)']';
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
_command boolean ispf_enter() name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (def_keys=='ispf-keys') {
      if (command_state()) {
         command_execute();
         return(true);
      }
      if (_isEditorCtl()) {
         if (!_isdiffed(p_buf_id)) {

            // guard against infinite recursion
            static boolean inHandler;
            if (inHandler) return false;
            inHandler = true;

            // Trying to detect a null line has been entered.
            // This will end certain commands like I with no number
            // which will continually insert lines until a null line is
            // entered.

            boolean processed=false;
            get_line(auto line);
            if(p_LCHasCursor == false && line == '') {
               processed = ispf_process_return(true);
            } else if(p_col >= 2) {
               processed = ispf_process_return(false);
            }

            if(processed) {
               inHandler = false;
               return true;
            }

            int orig_col=p_col;
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
      //say('IsKeydownEvent='IsKeydownEvent);
      //say('shiftnum='shiftnum);
   }
   return(false);
}

// split/insert line set cursor position, to smart indent
// on exit, the cursor is in the smart indent column on the new line
void ispf_split_line(_str split_line_func='split-insert-line')
{
   // find what command ENTER is bound
   int default_index=eventtab_index(_default_keys,_default_keys,event2index(ENTER));
   int mode_index=default_index;
   if (p_mode_eventtab) {
      mode_index=eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(ENTER));
   }
   int split_index = find_index(split_line_func,PROC_TYPE|COMMAND_TYPE);
   if (!split_index || !index_callable(split_index)) {
      return;
   }
   if (mode_index && default_index!=mode_index) {
      // if ENTER has been rebound, then execute that enter,
      // it will do the smart indenting
      old_keys := def_keys;
      def_keys='windows-keys';
      int root_binding_index=eventtab_index(_default_keys,_default_keys,event2index(ENTER));
      set_eventtab_index(_default_keys,event2index(ENTER),split_index);
      last_event(ENTER);
      _argument=1;
      call_index(mode_index);
      _argument='';
      set_eventtab_index(_default_keys,event2index(ENTER),root_binding_index);
      def_keys=old_keys;
   } else {
      // ENTER is not rebound, so just split/insert line
      old_keys := def_keys;
      def_keys='windows-keys';
      call_index(split_index);
      def_keys=old_keys;
   }
}

// insert a blank line below the cursor
_command insert_blankline_below() name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   return nosplit_insert_line();
}
// insert a blank line above the cursor
_command insert_blankline_above()  name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   return nosplit_insert_line_above();
}

// insert line (maybe split it) set cursor position, to smart indent
// on exit, the cursor is in the smart indent column on the new line
_command void ispf_split_insert_line() name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   ispf_split_line('split-insert-line');
}

// insert line (maybe split it) set cursor position, to smart indent
// on exit, the cursor is in the smart indent column on the new line
_command void ispf_nosplit_insert_line() name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   ispf_split_line('nosplit-insert-line');
}

// insert line (maybe split it) set cursor position, to smart indent
// on exit, the cursor is in the smart indent column on the new line
_command void ispf_maybe_split_insert_line() name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   ispf_split_line('maybe-split-insert-line');
}

_str def_auto_reset;        /* If non-zero, reset-next-error is called. */
                       /* before a compile or make commands is executed. */

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
_command void nosplit_insert_line() name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( command_state() ) {
      command_execute();
      return;
   }

   // process ISPF line commands
   if (name_name(last_index()) != "ispf-nosplit-insert-line") {
      if (ispf_enter_key_handler("nosplit-insert-line")) return;
   }

   // For better BRIEF emulation, ctrl+enter is set to nosplit_insert_line
   // nosplit_insert_line command should still perform smart indenting.
   // If last event
   if (last_event():!=ENTER && last_event():!=' ') {
      last_event(ENTER);
      int enter_index=eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(ENTER));
      if (enter_index && p_mode_eventtab!=_default_keys) {
         int index=eventtab_index(_default_keys,_default_keys,event2index(ENTER));
         set_eventtab_index(_default_keys,event2index(ENTER),
                            find_index('nosplit_insert_line',COMMAND_TYPE));
         call_index(enter_index);
         set_eventtab_index(_default_keys,event2index(ENTER),index);
         return;
      }

   }
   if ( p_window_state:=='I' ) {
      p_window_state='N';
      return;
   }
   if (_QReadOnly()) {
      _readonly_error(0);
      return;
   }
   if (p_hex_mode==HM_HEX_LINE) {
      p_hex_nibble=0;
      p_hex_field=0;
   }
   typeless p;
   int col=0;
   if (_on_line0()) {
      col=1;
   } else {
      save_pos(p);
      _begin_line();
      search('[~ \t]|$','@rh');
      restore_pos(p);
      // If not on blank line
      if ( match_length() ) {
         _begin_line();
         _refresh_scroll();
         first_non_blank();
         col=p_col;
      } else {
         col=enter_on_bl();
      }
   }
   if ( p_indent_style!=INDENT_NONE) {
      if ( LanguageSettings.getInsertRealIndent(p_LangId) ) {
         insert_line(indent_string(col-1));
      } else {
         insert_line('');
      }
      p_col=col;
   } else {
      insert_line('');
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
_command void nosplit_insert_line_above() name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if(_isEditorCtl())
      up();
   nosplit_insert_line();
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
enter_on_bl()
{
   int col;
   if ( p_index ) { /* Does this buffer has syntax expansion options? */
      /* For source code buffers, leave the cursor position alone. */
      col=p_col;
   } else {
      typeless left_margin, right_margin, new_para_margin;
      parse p_margins with left_margin right_margin new_para_margin;
      col=new_para_margin;
   }
   return(col);

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
   int orig_wid=p_window_id;
   
   boolean ncw=_no_child_windows()!=0;
   if ( _default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      // Get the current editor control of the current MDI window
      int wid=_MDICurrentChild(0);
      ncw= (wid==0);
   }
   if (ncw) {
      if (!def_stay_on_cmdline) {
         VSWID_STATUS._set_focus();
      }
   } else {
      cursor_data();
      int old_wid=p_window_id;
      refresh();
      p_window_id=old_wid;
   }
   if (substr(_cmdline.p_text,1,1)=='@') {
      _cmdline.set_command('',1);
      message(get_message(COMMAND_NOT_FOUND_RC));
      return;
   }
   //say('_mac='_macro());
   _str command;
   if ( _macro() ) {
      _cmdline.get_command(command);
      _macro_call('execute',command,'a');
   }
   _macro('m',_macro());
   //say('h2 _mac='_macro());
   last_index(prev_index());

   boolean override_stay_on_cmdline=false;
   _str orig_cmdline=_cmdline.p_text;
   _str cmdline=_cmdline.p_text;
   _str cmdname;
   if (def_keys=='ispf-keys') {
      ispf_do_lc();
      cmdline=strip(cmdline,'L');
      parse cmdline with cmdname .;
      cmdname=lowcase(cmdname);
      switch (cmdname) {
      case 'c':
      case 'chg':
      case 'change':
      case 'find':
      case 'f':
      case 'rfind':
      case 'rchange':
         override_stay_on_cmdline=true;
         break;
      }
      //say('**cmdname='cmdname);
      if (find_index('ispf-'cmdname,COMMAND_TYPE|IGNORECASE_TYPE)) {
         cmdline='ispf-'substr(lowcase(cmdname),1,length(cmdname)):+substr(cmdline,length(cmdname)+1);
      }
   }
   //say('override'override_stay_on_cmdline);
   //say('cmdline='cmdline);
   append_retrieve_command(orig_cmdline);
   _str text;
   int status;
   if (def_unix_expansion) {
      /* Execute result of function call. */
      text=cmdline;
      _cmdline.set_command('',1);
      status=execute(_maybe_unix_expansion(text),'a');
   } else {
      _cmdline.set_command('',1);
      status=execute(cmdline,'a');
   }

   // log this guy in the pip 
   if (def_pip_on) {
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
      if (ssmessage!='') {
         clear_message();
         refresh();
         _message_box(ssmessage,'',MB_OK|MB_ICONINFORMATION);
      }
      _cmdline._set_focus();
   }
   // IF we have a 2.0 constant value for UNIXRE_SEARCH
   if (def_re_search==0x80) {
      // convert it to the new 3.0 value
      def_re_search=UNIXRE_SEARCH;
   }
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_ONE_FILE_PER_WINDOW)) {
      def_one_file='+w';
   }
}
boolean _insertion_valid(boolean quiet=false)
{
   if (p_TruncateLength && p_col>p_TruncateLength+1) {
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
static boolean ispf_enter_key_handler(_str commandName)
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
_command void split_insert_line() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
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

   // this file's readonly, you can't do that!
   if (_QReadOnly()) {
      _readonly_error(0);
      return;
   }

   // some checks for hex mode
   if (p_hex_mode==HM_HEX_LINE) {
      p_hex_nibble=0;
      p_hex_field=0;
   }

   // if we're on the top line of the file, just insert a blank line and be done with it
   if (_on_line0()) {
      insert_line('');
      //p_col=orig_col;
      return;
   }

   int orig_col=p_col;        // save our original column
   int indent_col=0;
   if ( p_indent_style!=INDENT_NONE ) {
      // we're using something complicated to indent, either auto or smart
      _begin_line();
      _refresh_scroll();

      if (_expand_tabsc()!='') first_non_blank();
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
   boolean RestoreLineModifyFlags=false;        // we might set this to true
   // are we past/at the end of the line?
   if (p_col>_text_colc()) {
      if (p_buf_width) {
         // Record files have no NLChars.  _split_line
         // won't insert any either.
         RestoreLineModifyFlags=true;
      } else {
         // we're going to add some newline characters
         p_col=_text_colc()+1;
         _str NLChars=get_text(_line_length(1)-_line_length());
         if (NLChars:==p_newline) {
            RestoreLineModifyFlags=true;
         }
      }
   }
   if( _on_line0() || indent_col!=p_col || _expand_tabsc(1,p_col-1)!="" ) {
      // determine if the line after the cursor is blank
      boolean restOfLineBlank=_expand_tabsc(p_col):=='';
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
      line := '';
      // unless there are spaces/tabs on this line, then we insert that
      int curline_flags=_lineflags();
      get_line(auto curline);
      if (_expand_tabsc(p_col)=='') {
         get_line_raw(line);
      }
      up();
      
      insert_line(line);
      // (clark) I think this is always true
      if (line=='') {
         /*
            Make this look like _split_line was called. 
            This is a little smarter than _split_line. _split_line always sets the current
            line of the split as modified. Here we make this emulate press enter in the middle
            versus the end of line.
         */
         if (curline=='') {
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
_command void maybe_split_insert_line() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
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
         p_hex_nibble=0;
         p_hex_field=0;
      }
      insert_line('');
   }
   _begin_line();

}
/**
 * @return Returns true if ENTER is bound to {@link split_insert_line}
 * or if we are in insert mode and ENTER is bound to {@link maybe_split_insert_line}
 */
boolean _will_split_insert_line()
{
   _str enter_cmd = name_on_key(ENTER);
   _str ctrl_enter_key = name2event("C_ENTER");
   if (last_event()==ctrl_enter_key) enter_cmd=name_on_key(ctrl_enter_key);
   if (enter_cmd:=='split-insert-line') return true;
   if (enter_cmd:=='maybe-split-insert-line' && _insert_state()) return true;
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
_command void ctab() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_LINEHEX)
{
   if ( command_state() ) {
      maybe_list_matches('','',true);
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
      if ( command_state() || _expand_tabsc(1,p_col-1)!='') {
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
      int old_col=p_col;
      ptab();
      int syntax_indent=p_col-old_col;
      replace_line(reindent_line(line,syntax_indent));
      return;
   }
   init_command_op();
   ptab();
   retrieve_command_results();
}
void ptab(...)
{
   if ( p_indent_style!=INDENT_NONE && p_SyntaxIndent>0 ) {
      if ( arg(1)=='' ) {
         p_col=((p_col-1) intdiv p_SyntaxIndent)*p_SyntaxIndent+1;
      } else {
         p_col=((p_col-2) intdiv p_SyntaxIndent)*p_SyntaxIndent+1+p_SyntaxIndent;
      }
      p_col=p_col+(int)(arg(1)p_SyntaxIndent);
   } else {
      if ( arg(1)=='-' ) {
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
_command void cbacktab() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
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
      p_LCHasCursor=1;
      p_hex_nibble=0;p_hex_field=0;
      return;
   }
   init_command_op();
   ptab('-');
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
_command void move_text_tab() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if ( command_state() ) {
      maybe_list_matches('','',true);
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
   int old_col=p_col;
   ptab();
   replace_line(_expand_tabsc(1,old_col-1,'S'):+
                substr('',1,p_col-old_col):+
                _expand_tabsc(old_col,-2,'S'));
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
_command void move_text_backtab() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
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
   int old_col=p_col;
   ptab('-');
   if ( _expand_tabsc(1,old_col)=='' ) {
      int syntax_indent=old_col-p_col;
      _reindent_linec(-syntax_indent);
      return;
   }
   _str subtext=strip(_expand_tabsc(p_col,old_col-p_col),'T');
   replace_line(_expand_tabsc(1,p_col-1,'S'):+subtext:+_expand_tabsc(old_col,-2,'S'));
   p_col=p_col+_rawLength(subtext);
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
_command void begin_line() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
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

   if (def_cursorwrap && p_SoftWrap && !p_IsTempEditor) {
      softwrap_begin_line(1, p);
   }

   if ( p_left_edge && p_col<p_char_width-2 ) {
      set_scroll_pos(0,p_cursor_y);
   }

}

static boolean softwrap_begin_line(int fnb_col, typeless orig_p)
{
   // if not doing cursor wrap or no softwrap, do nothing
   if (!def_cursorwrap || !p_SoftWrap || p_IsTempEditor) {
      return false;
   }

   // save the position that was calculated before
   save_pos(auto new_p);
   do {
      // remember the new column
      // and calculate p_cursor_x for column 1
      new_col := p_col;
      p_col=1;
      col1_x := p_cursor_x;

      // go to the original cursor position
      restore_pos(orig_p);

      // was it before the first non-blank position, then do nothing
      if (p_col <= fnb_col) break;

      // if they are at the beginning of the softwrap line, take
      // them to the real beginning of the line
      if (p_cursor_x <= col1_x) break;

      // move to the beginning of the softwrap line
      p_cursor_x=col1_x;
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
_command void begin_line_text_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
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
      int orig_col=p_col;
      first_non_blank();
      int fnb_col = p_col;
      /* not already on first non blank? */
      if ( p_col!=orig_col) {
         //first_non_blank();
      } else {
         _begin_line();
      }

      if (def_cursorwrap && p_SoftWrap && !p_IsTempEditor) {
         softwrap_begin_line(fnb_col, p);
      }
   }
   if ( p_left_edge && p_col<p_char_width-2 ) {
      set_scroll_pos(0,p_cursor_y);
   }

}

_first_non_blank_col(...)
{
   typeless sv_search_string,sv_flags,sv_word_re,sv_more;
   save_search(sv_search_string,sv_flags,sv_word_re,sv_more);
   _str return_if_all_blanks=arg(1);
   save_pos(auto p);
   _begin_line();
   search('[~ \t]|$','@rh');
   int col=p_col;
   restore_pos(p);
   if (!match_length() && return_if_all_blanks!='') {
      restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
      return(return_if_all_blanks);
   }
   restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
   return(col);
}
/**
 * Moves the cursor to the first non space or tab character of the current
 * line.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void first_non_blank(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (_on_line0()) {
      p_col=1;
      return;
   }
   typeless sv_search_string,sv_flags,sv_word_re,sv_more;
   save_search(sv_search_string,sv_flags,sv_word_re,sv_more);
   _begin_line();
   typeless p1=point();
   typeless ln=point('L'); // Search for $ does not work if p_TruncateLength!=0
   search('[~ \t]|$','@rh'arg(1));
   if (p_TruncateLength && (match_length()==0 || p1!=point())) {
      if (p1!=point()) {
         goto_point(p1,ln);
      }
      _begin_line();
      _refresh_scroll();
   }
   restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
}
int _TruncSearchLine(_str searchString,_str posOptions="")
{
   _str line;
   get_line_raw(line);
   if (p_TruncateLength > 0) {
      line=substr(line,1,p_TruncateLength);
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
   save_pos(auto orig_p);
   if (p_hex_mode==HM_HEX_ON) {
      _hex_end_line();
      return;
   }
   _TruncEndLine();

   if (def_cursorwrap && p_SoftWrap && !p_IsTempEditor) {
      softwrap_end_line(p_width/p_font_width, orig_p);
   }
}

static boolean softwrap_end_line(int lnb_col, typeless orig_p)
{
   // if not doing cursor wrap or no softwrap, do nothing
   if (!def_cursorwrap || !p_SoftWrap || p_IsTempEditor) {
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
   // hex mode
   if (p_hex_mode==HM_HEX_ON) {
      _hex_end_line();
      return;
   }

   // save the original column and jump to the end of the line
   save_pos(auto orig_p);
   orig_col := p_col;

   // find the last nonblank column
   _begin_line();
   search(':b$|$','@rh');
   nonblank_col := p_col;

   // find the actual end of the line
   _TruncEndLine();

   // check if we can use the last non-blank column
   if (nonblank_col > orig_col && nonblank_col < p_col) {
      p_col = nonblank_col;
   }

   // if this line extends beyond the vertical line column,
   // then toggle first to the vertical line column, then to
   // the end of the line.
   vline_col := _default_option('R');
   if (def_end_line_stop_at_vertical_line &&
       isnumber(vline_col) && vline_col > 0) {
      // line goes past vertical line column?
      if ((orig_col <= vline_col && p_col > vline_col)) {
         p_col = vline_col+1;
      }
   }

   // already was at end column then toggle back to nearest column
   if (p_col == orig_col) {
      if (nonblank_col < p_col) {
         p_col = nonblank_col;
      }
      if (def_end_line_stop_at_vertical_line &&
          isnumber(vline_col) && vline_col > 0 && vline_col < p_col) {
         p_col = vline_col+1;
      }
   }

   if (def_cursorwrap && p_SoftWrap && !p_IsTempEditor) {
      softwrap_end_line(nonblank_col, orig_p);
   }
}

static int gupdown_col=1;
static int gupdown_cursor_x=0;
static int gupdown_left_edge=0;

/**
 * For an edit window or editor control, the cursor moves one line up.
 * For the command line, the previous command
 * in the retrieve buffer ".command" is placed on the command line.
 *
 * @appliesTo  Edit_Window, Editor_Control, Command_Line
 * @categories Command_Line_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command int cursor_up(_str count='',_str doScreenLines='') name_info(','VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   return(_cursor_updown(count,"",1,(doScreenLines=='')?(_str)def_updown_screen_lines:doScreenLines));
}
int _cursor_updown(_str count='',_str dodown='',_str generate_macro_source='',
                   _str doScreenLinesStr='')
{
   if (count=='') count=1;
   dodown=dodown!="";
   generate_macro_source=generate_macro_source!="";
   boolean doScreenLines=doScreenLinesStr:!="" && doScreenLinesStr:!='0';
   int i;
   _str line;
   if (command_state()) {
      int orig_value=def_argument_completion_options;
      def_argument_completion_options = 0;
      for (i=1;i<=count;++i) {
         retrieve_skip((dodown)?'N':'');
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
   //say('gupdown_cursor_x='gupdown_cursor_x);
   if (prev_cmd!='cursor-up' && prev_cmd!='cursor-down') {
      gupdown_col=p_col;
      gupdown_cursor_x=p_cursor_x;
      gupdown_left_edge=p_left_edge;
      //say('change x='gupdown_cursor_x);
   }
   if (generate_macro_source) {
      _macro_repeat();
   }
   typeless downp;
   save_pos(downp);
   _str orig_point=point();
   int status;
   for (i=1;i<=count;++i) {
      if (p_hex_mode) {
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
   if (!p_hex_mode && (orig_point!=point() || p_SoftWrap)) {
      if (def_updown_col || !p_fixed_font) {
         stay_on_text(gupdown_col,gupdown_cursor_x,gupdown_left_edge);
      }
      if ((p_col>1)&&def_emulate_leading_tabs) {
         get_line(line);
         int pcol=text_col(line,p_col,'P');
         if ((pcol<length(line))&&('':==strip(substr(line,1,pcol)))) {
            ptab('-');
            ptab();
         }
      }
   }
   if (!dodown && _on_line0() && !_default_option('T')) {
      p_line=1;
      boolean blockSelectionActive=(select_active() && _select_type():=='BLOCK');
      if (!blockSelectionActive) {
         p_col=1;
      }
   }

   //read_behind_flush_repeats(key,def_flush_repeats);
   return(status);
}
static void stay_on_text(int updown_col,int updown_cursor_x,int left_edge)
{
   boolean blockSelectionActive=(select_active() && _select_type():=='BLOCK');
   if ( updown_col) {
      if (!p_fixed_font || p_SoftWrap) {
         //say('h2 x='updown_cursor_x);
         set_scroll_pos(left_edge,p_cursor_y);
         p_cursor_x=updown_cursor_x;
         //say('col='p_col);
         if (def_updown_col && !blockSelectionActive/* && !p_SoftWrap*/) {
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
_command int cursor_down(_str count='',_str doScreenLines='') name_info(','VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   return(_cursor_updown(count,"n",1,(doScreenLines=='')?(_str)def_updown_screen_lines:doScreenLines));
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
   int old_col;
   int old_left_edge;
   _str old_point;
   if ( def_top_bottom_style ) {
      old_col=p_col;
      old_left_edge=p_left_edge;
      old_point=point();
      set_scroll_pos(old_left_edge,p_cursor_y);
   }
   if (def_top_bottom_push_bookmark && p_LangId!='process') {
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
   int old_col;
   int old_left_edge;
   _str old_point;
   if ( def_top_bottom_style ) {
      old_col=p_col;
      old_left_edge=p_left_edge;
      old_point=point();
   }
   if (def_top_bottom_push_bookmark && p_LangId!='process') {
      push_bookmark();
   }
   bottom();_TruncEndLine();
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
_command void page_up() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
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
_command void page_down() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   page_up_down('d');

}
static void page_up_down(...)
{
   if (p_hex_mode==HM_HEX_ON) {
      if ( arg(1)!='' ) {
         _hex_pagedown();
      } else {
         _hex_pageup();
      }
      return;
   }
   _str key=last_event();
   read_behind(/*key*/);
   _str prev_cmd=name_name(prev_index());
   if (prev_cmd == 'cua-select') {
      prev_cmd = get_last_cua_key();
   }
   if (prev_cmd!='page-up' && prev_cmd!='page-down' ) {
      gupdown_col=p_col;
      gupdown_cursor_x=p_cursor_x;
      gupdown_left_edge=p_left_edge;
   }
   if (def_keys=='ispf-keys' && _cmdline.p_text!='' && lowcase(_cmdline.p_text)==substr('maximum',1,length(_cmdline.p_text))) {
      if ( arg(1)!='' ) {
         bottom_of_buffer();
      } else {
         top_of_buffer();
      }
      _cmdline.set_command('',1);
   } else if (lowcase(def_page)=='c') {
      if ( arg(1)!='' ) {
         if (p_cursor_y==0) {
            _page_down();
         } else {
            line_to_top();
         }
      } else {
         //say('p_char_height='p_char_height);
         //say('y='p_cursor_y);
         //say('div='p_cursor_y intdiv p_font_height);
         if (p_char_height<=(p_cursor_y intdiv p_font_height)+1) {
            _page_up();
         } else {
            line_to_bottom();
         }
      }
   } else {
      if ( arg(1)!='' ) {
         _page_down();
      } else {
         _page_up();
      }
   }
   if (def_updown_col || !p_fixed_font || p_SoftWrap) {
      stay_on_text(gupdown_col,gupdown_cursor_x,gupdown_left_edge);
      if ((p_col>1)&&def_emulate_leading_tabs) {
         get_line(auto line);
         int pcol=text_col(line,p_col,'P');
         if ((pcol<length(line))&&('':==strip(substr(line,1,pcol)))) {
            ptab('-');
            ptab();
         }
      }
   } else {
      p_col=gupdown_col;
   }
   read_behind();
}

void _goto_right_edge_col()
{
   int orig_left_edge=p_left_edge;
   p_cursor_x=p_client_width-1;
   //say(p_left_edge' 'orig_left_edge);
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
boolean _doCmdLineCursorBeginEndSelect(_str key)
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
_command void cursor_left(...) name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   int i,count=1;
   if (arg(1)!='') {
      count=arg(1);
   }
   int col;
   _str line;
   if (command_state()) {
      if (_doCmdLineCursorBeginEndSelect(last_event())) {
         return;
      }
      for (i=1;i<=count;++i) {
         if ( def_jmp_on_tab ) {
            left();
         } else {
            get_command(line,col);
            set_command(line,col-1);
         }
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
            p_LCHasCursor=1;
            p_hex_nibble=0;p_hex_field=0;
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
   int col=p_col;
   if (def_emulate_leading_tabs) {
      get_line(auto line);
      int pcol=text_col(line,p_col-1,'P');
      if ('':==strip(substr(line,1,pcol))) {
         ptab('-');
      } else if ( def_jmp_on_tab) {
         left();
      } else {
         p_col=p_col-1;
         _begin_char(); // Make sure we are on at the begining of the DBCS or UTF-8 chacter
      }
   } else if ( def_jmp_on_tab) {
         left();
   } else {
      p_col=p_col-1;
      _begin_char(); // Make sure we are on at the begining of the DBCS or UTF-8 chacter
   }

   if ( (p_word_wrap_style&WORD_WRAP_WWS) ||
        arg(1):=='1' ) {
      if ( def_linewrap || !(p_word_wrap_style&WORD_WRAP_WWS)) {
         leftmargin=1;
      }
      if ( col<=leftmargin) {
         get_line(auto line);
         if (strip(substr(line,1,_text_colc(col-1,'P')),'B'):=='' ) {
            up(1,1);
            if ( ! rc ) {
               _end_line();
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
_command void cursor_right(...) name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   int i,count=1;
   if (arg(1)!='') {
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
        arg(1):=='1' ) {
      if ( (p_col>rightmargin || arg(1):=='1') &&
           p_col>_text_colc() &&
           (def_keys!='ispf-keys' || p_col>p_TruncateLength) &&
           (! select_active() || _select_type():!='BLOCK') ) {
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
      get_line(auto line);
      int pcol=text_col(line,p_col,'P');
      if ('':==strip(substr(line,1,pcol))) {
         ptab();
         int try_col=p_col;
         first_non_blank();
         if (p_col>try_col) {
            p_col=try_col;
         }
      } else if ( def_jmp_on_tab ) {
         right();
      } else if(get_text()=="\t") {
         p_col=p_col+1;
      } else {
         right();
      }
   } else if ( def_jmp_on_tab ) {
      right();
   } else if(get_text()=="\t") {
      p_col=p_col+1;
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
_command int next_char() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
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
_command int prev_char() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
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
   if ( direction=='-' ) {
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
boolean ext_delete_char(_str force_wrap='')
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
_command void delete_char(_str force_wrap='') name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
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
_command void linewrap_delete_char() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   _macro('m',_macro());
   delete_char(1);
}
/**
 * Either calls _delete_char or deletes one tab character worth of space depending
 * on the cursor location and the value of def_emulate_leading_tabs
 */
void maybe_delete_tab()
{
   if (def_emulate_leading_tabs) {
      get_line(auto line);
      int pcol=text_col(line,p_col,'P');
      if ((pcol<length(line))&&('':==strip(substr(line,1,pcol)))) {
         // may have spaces, may have tabs, let cursor_right figure that out
         int sel_id=_alloc_selection();
         int start_col=p_col;
         _select_char(sel_id);
         cursor_right();
         _select_char(sel_id);
         _delete_selection(sel_id);
         _free_selection(sel_id);
         p_col=start_col;
         return;
      }
   }
   _delete_char();
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

   if ( (p_word_wrap_style&WORD_WRAP_WWS)  ||
        arg(1)!='' ) {
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
         maybe_delete_tab();
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
boolean ext_rubout_char(_str force_wrap='')
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
_command void rubout(_str force_wrap='') name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
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
_command void linewrap_rubout() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   _macro('m',_macro());
   rubout(1);
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

   int col=p_col;
   int line_len=0;
   int count=0;
   _str temp;
   int temp_len;
   if ( def_pull || _insert_state() ) {
      if ( def_hack_tabs && p_col!=1 ) {
         // Changed this to support DBCS
         left();
         if (get_text()=="\t") {
            p_col=col;p_col=p_col-1;_delete_char();
         } else {
            _delete_char();
         }
         //_delete_text();
      } else {
         if (/*def_keys=='brief-keys' && */p_index && p_indent_style==INDENT_SMART && p_indent_with_tabs && p_show_tabs!=1 && p_buf_width==0) {
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
               _rubout();
            }
         } else {
            boolean backspace_unindent = false;
            boolean handled_rubout=false;
            if (p_col>1) {
               get_line(auto line);
               int pcol=text_col(line,p_col-1,'P');
               if ((pcol<length(line))&&('':==strip(substr(line,1,pcol)))) {

                  if (def_emulate_leading_tabs) {

                     // may have spaces, may have tabs, let cursor_left figure that out
                     int sel_id=_alloc_selection();
                     _select_char(sel_id);
                     cursor_left();
                     _select_char(sel_id);
                     _delete_selection(sel_id);
                     _free_selection(sel_id);
                     handled_rubout=true;

                  } else if (!commentwrap_Backspace() && LanguageSettings.getBackspaceUnindents(p_LangId)) {

                     backspace_unindent = true;
                  }
               } else if (line == '' && !commentwrap_Backspace() && LanguageSettings.getBackspaceUnindents(p_LangId)) {

                  backspace_unindent = true;
               }
            }

            // Check for p_SyntaxIndent == 0...if we can't use that, check for tab settings
            if (backspace_unindent && (p_SyntaxIndent || (p_indent_with_tabs && p_tabs != ""))) {

               // determine the number of whitespace chars to delete
               int indent = p_SyntaxIndent;
               if (indent <= 0) {
                  typeless t1, t2;
                  parse p_tabs with t1 t2 .;
                  if (isinteger(t2) && isinteger(t1)) {
                     indent = t2 - t1;
                  }
               }

               // Don't un-indent if we don't have valid p_SyntaxIndent or valid p_tabs
               if (indent > 0) {
                  int ws_to_delete = (p_col-1) % indent;
                  if (ws_to_delete == 0) {
                     ws_to_delete = indent;
                  }
                  int new_pcol = (p_col-1) - ws_to_delete + 1;

                  while (p_col > new_pcol) {
                     _rubout();
                  }
                  while (p_col < new_pcol) {
                     // insert whitespace(s) in case we've deleted more than desired due to
                     // mix up of whitespace and tab characters.
                     _insert_text(' ');
                  }
                  handled_rubout = true;
               }
            }

            if (!handled_rubout) {
               _rubout();
            }
         }
      }
   } else {
      if ( col!=1 ) {
         // Changed this to support DBCS
         left();
         if (get_text()=="") {
            p_col=col;
            p_col=p_col-1;
         } else if (p_col<=col-2) {
            // This actually isn't possible to implement for Unicode so
            // here we just try 2 spaces for Unicode or DBCS
            _insert_text(' ');keyin(' ');
            left();left();
         } else {
            keyin(' ');
            left();
         }
      }
   }
   int status;
   typeless leftmargin;

   if ( (p_word_wrap_style&WORD_WRAP_WWS) || arg(1)!='' ) {
      parse p_margins with leftmargin .;
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
 * Places cursor at bottom right of window.
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
_command void split_line() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   int first_non_blank;

   int orig_col=p_col;
   int ifirst_non_blank=_first_non_blank_col(0);


   int flags=_lineflags();
   boolean RestoreLineModifyFlags=false;
   if (p_col>_text_colc()) {

      if (p_buf_width) {
         // Record files have no NLChars.  _split_line
         // won't insert any either.
         RestoreLineModifyFlags=true;
      } else {
         p_col=_text_colc()+1;
         _str NLChars=get_text(_line_length(1)-_line_length());
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
_command void split_line_at_column(typeless column='') name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   // prompt for a column number
   static int last_split_column;
   if (!last_split_column) last_split_column=80;
   column=prompt(column,"Split at column:",last_split_column);
   if (column=='') return;
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
_command void split_line_at_delimeter(_str delim='') name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   // prompt for a column number
   static _str last_delimeter;
   delim=prompt(delim,"Split at delimeter:",last_delimeter);
   if (delim=='') return;
   last_delimeter=delim;

   // now split up the line
   for (;;) {
      save_pos(auto p);
      int orig_line=p_line;
      _begin_line();
      cursor_right(length(delim));
      int status = search(delim,'@he');
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
   int status=search('[ \t]@$','rh@');
   if (!status && match_length()) {
      //search_replace('');
      _delete_text(match_length());
   }
   restore_pos(p);
}
void strip_leading_spaces(_str &deletedText="")
{
   save_pos(auto p);
   _begin_line();
   int status=search('^[ \t]@','rh@');
   deletedText="";
   if (!status && match_length()) {
      deletedText=get_match_text();
      int strip_count=match_length();
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
_command void join_lines() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (select_active()) {
      int i;
      _str num_lines = count_lines_in_selection();
      if (!isinteger(num_lines)) {
         // ?
         message('Bad selection.');
         return;
      }
      int nl = (int)num_lines;
      begin_select();
      typeless p;
      _save_pos2(p);
      for (i = 0; i < nl - 1; i++) {
         end_line();
         _insert_text(' ');
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
_command int join_line(_str stripLeadingSpaces='') name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   /* join next line to current line at cursor position. */
   /* if cursor position is less than length of line then */
   /* join next line to end of current line. */
   /* leading spaces and tabs of next line are stripped before join. */

   // are we about to try joining line comments or javadoc comments?
   boolean joinComments = _GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_JOIN_COMMENTS) != 0;
   boolean joiningLineComment = joinComments;
   boolean joiningJavaComment = joinComments;

   // is the current a line comment or Java doc comment?
   _str delims='';
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
      first_non_blank();
      joiningLineComment = joiningLineComment && (_inExtendableLineComment(delims) > 0);
      joiningJavaComment = joiningJavaComment && (_inJavadoc() > 0);
      restore_pos(p);
   }

   // if we are joining two comment lines, turn on strip leading spaces
   if (joiningLineComment || joiningJavaComment) {
      stripLeadingSpaces = true;
   }

   up();
   if ( stripLeadingSpaces!='' && !stripLeadingSpaces) { /* Do not strip spaces? */
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
         if (length(deletedText)>p_TruncateLength) {
            deletedText=substr(deletedText,1,p_TruncateLength);
         }
         _begin_line();_insert_text(deletedText);
         restore_pos(p);
      }
      //current_line= current_line:+strip(line,'L')

      // strip the leading comment
      // designator
      if (joiningLineComment) {
         if (get_text(3)=='///') {
            // XML Doc
            _delete_char();
            _delete_char();
            _delete_char();
         } else if (get_text(2)=='//') {
            // C++ comment
            _delete_char();
            _delete_char();
         } else if (get_text(length(delims))==lowcase(delims)) {
            int i;
            for (i=0; i<length(delims); ++i) {
               _delete_char();
            }
         } else if (get_text(1)=='#') {
            // Shell comment
            _delete_char();
         } else if (get_text(1)=='*') {
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
         } else if (get_text(2)=='--') {
            // Ada, Pascal, VHDL comment
            _delete_char();
            _delete_char();
         } else if (lowcase(get_text(4)):=='rem ') {
            // Basic comment
            _delete_char();
            _delete_char();
            _delete_char();
         }
      } else if (joiningJavaComment) {
         // Java doc leading star
         if (get_text(1)=='*' && get_text(2)!='*/') {
            _delete_char();
         }
      }
   }
   return(status);

}
/**
 * Places cursor on first character of selection specified.  <i>mark_id</i> is a handle to a
 * selection or bookmark returned by one of the built-ins <b>_alloc_selection</b> or <b>_duplicate_selection</b>.
 * A <i>mark_id</i> of '' or no <i>mark_id</i> parameter identifies the active selection.  If the selection type is LINE,
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
_command int begin_select(_str markid='',boolean LockSelection=true,boolean RestoreScrollPos=false) name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int temp_view_id=0;
   int orig_view_id=0;
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
   if (def_one_file!='' || !p_mdi_child || _no_child_windows() ||
       !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)
      ) {
      if (!_correct_window(orig_buf_id)) {
         _begin_select(arg(1),true,false);
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
   // Find a window to display this window
   int i,wid=0;
   for (i=1;i<=_last_window_id();++i) {
      if (_iswindow_valid(i) && i._isEditorCtl(0) && i.p_buf_id==buf_id &&
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
      edit('+bi 'buf_id);
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
_command end_select(_str markid='') name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int orig_buf_id=p_buf_id;
   int status=_end_select(arg(1),true,false);
   if (status) {
      return(status);
   }
   if (def_one_file!='' || !p_mdi_child || _no_child_windows() ||
       !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)
      ) {
      if (!_correct_window(orig_buf_id)) {
         _end_select(arg(1),true,false);
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
_command void select_line() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _cua_select=0;
   if ( lock_selection() ) return;
   boolean flag=_select_type('')!='' && _select_type('','S')!='C';
   int status=_select_line('',def_select_style:+def_advanced_select);
   if ( status==TEXT_ALREADY_SELECTED_RC ||
        (pos('C',def_select_style,1,'i') && flag) ) {
      _deselect();clear_message();select_line();
   }

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
   // If they hit Ctrl+I and we are in HTML, check if it
   // is safe to surround the selection with <i> and </i>
   if (last_event()==C_B &&
       select_active() && _select_type()!='BLOCK' &&
       checkHTMLContext() && !_QReadOnly() ) {
      insert_html_bold();
      return;
   }

   _cua_select=0;
   if ( lock_selection() ) return;
   boolean flag=_select_type('')!='' && _select_type('','S')!='C';
   int status=_select_block('',def_select_style:+def_advanced_select);
   if ( status==TEXT_ALREADY_SELECTED_RC ||
        (pos('C',def_select_style,1,'i') && flag)
      ) {
      _deselect();clear_message();select_block();
   }

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
_command void select_char() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _cua_select=0;
   if ( lock_selection() ) {
      return;
   }
   boolean flag=_select_type('')!='' && _select_type('','S')!='C';
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
_command void deselect() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   _deselect();
}
int _OnUpdate_deselect(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid.select_active()) {
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
int _copy_or_move(...)
{
   int status=0;
   typeless markid=arg(1);
   typeless copymove_option=arg(2);
   typeless do_smartpaste=arg(3);
   typeless support_deselect=arg(4);
      
   boolean srcbuf_eq_destbuf = false;
   long paste_src = 0;

   if (_select_type(markid)=='') {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   // Lock the selection
   if (markid=='') markid=_duplicate_selection('');
   _select_type(markid,'S','E');
   _get_selinfo(auto start_col, auto end_col, auto srcbuf_id, markid, auto j4, auto j5, auto j6, auto num_sellines);
   srcbuf_eq_destbuf = srcbuf_id == p_buf_id;

   if (srcbuf_eq_destbuf) {
      // Lookup location of selection in the document, in case we need
      // to feed it to the beautifier.
      save_pos(auto p1);
      _begin_select(markid);
      paste_src = _QROffset();
      restore_pos(p1);
   }

   if (do_smartpaste) {
      // Here we are assuming we were called from clipbd.e on a
      // paste operation.
      _extend_outline_selection(markid);
   }
   /* lock_selection(1)  /* No message */ */
   boolean special_case=_select_type(arg(1))=='LINE' && def_line_insert=='B';
   int cursor_y;
   if ( special_case ) {
      cursor_y=p_cursor_y;
      up();
   }

   _str select_style=_select_type('','S');
   _str persistent_mark=_select_type('','U');
   boolean userLockedSelection=select_style=='E' && persistent_mark=='P';

   adjust_outline_destination(markid);
   sel_type := _select_type(arg(1));
   if (sel_type=='CHAR' && _on_line0()) {
      insert_line('');
   }

   boolean beautify_destination = beautify_paste_expansion(p_LangId) && sel_type != 'BLOCK'; 

   if (do_smartpaste && !beautify_destination) {
      status=smart_paste(markid,copymove_option);
   } else {
      if ( upcase(copymove_option)=='M' ) {
         status=_move_to_cursor(markid);
      } else {
         status=_copy_to_cursor(markid);
      }
   }
   if ( special_case && (!status || status==SOURCE_DEST_CONFLICT_RC) ) {
      down();
      set_scroll_pos(p_left_edge,cursor_y);
   }

   if (!userLockedSelection || upcase(def_persistent_select)!='Y') {
      // Turn off persistance so that selection goes away when the
      // cursor moves
      _select_type(markid,'U','');
   }
   //_free_selection(markid);
   if (support_deselect && def_deselect_copyto) {
      _deselect(arg(1));
   }

   long start_offset = _QROffset();
   if (status == 0 && beautify_destination) {
      if (sel_type == 'LINE') {
         if (def_line_insert == 'A') {
            // Arrange to have cursor on last line of the selection.
            p_line += num_sellines;
         } else {
            // We're at the end of the selection, so adjust start_offset accordingly.
            // We have to delay this till after the text has been copied in, 
            // otherwise the offsets would be wrong for the case where a selection
            // is being dragged around in a single buffer.
            save_pos(auto p1);
            p_line -= num_sellines;
            _begin_line();
            start_offset = _QROffset();
            restore_pos(p1);
         }
      } else if (sel_type == 'CHAR') {
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
         if (!userLockedSelection || upcase(def_persistent_select)!='Y') {
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
   if (_select_type(markid)=='LINE') {
      //count=count_lines_in_selection(markid);
      //messageNwait('adjust_outline_destination: count='count);
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
_str lock_selection(_str quiet='')
{
   if ( _select_type('','S')=='C' && def_advanced_select!='' ) {
      int first_col,last_col,buf_id;
      _get_selinfo(first_col,last_col,buf_id);
      if ( p_buf_id==buf_id ) {
         select_it(_select_type(),'',_select_type('','I'):+def_advanced_select);
         if ( quiet=='' ) {
            message('Selection locked.');
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
      if (_select_type()=='') {
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
      if ((selType :=='CHAR') || (selType :=='LINE')) {
         //say('CF delete selection here we go.');
      }
   }
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
_command void gui_fill_selection() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   _macro('m',_macro());
   fill_selection('gui');
}
/**
 *    Fills selection with key you type.  If the <i>gui</i> option is given
 * and not '', a message box is displayed to prompt the user to press a key to
 * fill the selection.  Otherwise, message is displayed on the message line to
 * prompt the user to press a key.
 *
 * @return  Returns 0 if successful.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_command fill_selection(...) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   typeless gui=arg(1);
   if (!p_mdi_child && _executed_from_key_or_cmdline('fill_selection')) {
      gui=1;
   }
   if ( _select_type()=='' ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   _macro_delete_line();
   _str key='';
   if (gui!='') {
      int orig_wid=p_window_id;
      int wid=show('_fill_form');
      key=get_event();
      wid._delete_window();
      if ( iscancel(key) ) {
         return(1);
      }
      p_window_id=orig_wid;
      _macro('m',_macro('s'));
   } else {
      message(nls('Type a key to fill mark with'));key=get_event();
      if ( iscancel(key) ) {
         cancel();
         return(1);
      }
   }
   _str param=key2ascii(key);
   if (!p_UTF8 && _UTF8() && _UTF8Asc(param)>=128) {
      param=_UTF8ToMultiByte(param);
   }
   _macro_call('_fill_selection',param);
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
_command void shift_selection_left(...) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   typeless numshifts=arg(1);
   if (numshifts=='') {
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
_command void shift_selection_right(...) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   typeless numshifts=arg(1);
   if (numshifts=='') {
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
   int result=0;
   LeftOrRight=upcase(arg(1));
   boolean doLeft=(LeftOrRight=="L");
   count=arg(2);
   if (count=="") {
      result=show("-modal _textbox_form",
                  (doLeft)?"Shift Selection Left":"Shift Selection Right", // Form caption
                  0, //flags
                  '',   //use default textbox width
                  '',   //Help item.
                  '',   //Buttons and captions
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
   message(nls('Type a key'));
   _str key=get_event();
   clear_message();
   key=key2ascii(key);
   _str param;
   if ( length(key)>1 ) {
      param=last_event();
   } else {
      param=key;
   }
   _macro_call('keyin',param);
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
      _macro_call('_insert_state',1);
   } else {
      _macro_call('_insert_state',0);
   }
}
boolean def_esc_deselects;
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
   if (!p_mdi_child && !p_DockingArea && p_object==OI_EDITOR && p_active_form.p_object==OI_FORM) {
      if (last_event():==ESC || last_event():==A_F4) {
         call_event(defeventtab _ainh_dlg_manager,last_event(),'e');
      }
      return;
   }
   if (p_active_form==_tbIsActive("_tbshell_form")) {
      if (_no_child_windows()) {
         p_window_id= _cmdline;
      } else {
         p_window_id= _mdi.p_child;
      }
      _set_focus();
      return;
   }
   if (def_esc_deselects && _isEditorCtl(false) && select_active2()) {
      deselect();
      return;
   }
   int result=0;
   if ((p_window_id!=_cmdline &&
        !_default_option(VSOPTION_HAVECMDLINE))) {
      if (isEclipsePlugin()) {
         result = show('-modal -xy _textbox_form',
                       'SlickEdit Command', // Form caption
                       TB_RETRIEVE, //flags
                       '', //use default textbox width
                       '', //Help item.
                       '', //Buttons and captions
                       'command',   //Retrieve Name
                       '-c 'COMMAND_ARG:+_chr(0)'Command:');
      } else {
         result = show('-modal _textbox_form',
                       '', // Form caption
                       TB_RETRIEVE, //flags
                       '', //use default textbox width
                       '', //Help item.
                       '', //Buttons and captions
                       'command',   //Retrieve Name
                       '-c 'COMMAND_ARG:+_chr(0)'Command:');
      }
      if (result=='') {
         return;
      }
      _str text=_param1;
      if (def_keys=='ispf-keys') {
         ispf_do_lc();
         _str cmdname;
         _str cmdline=strip(text,'L');
         parse cmdline with cmdname .;
         cmdname=lowcase(cmdname);
         if (find_index('ispf-'cmdname,COMMAND_TYPE|IGNORECASE_TYPE)) {
            text='ispf-'substr(lowcase(cmdname),1,length(cmdname)):+substr(cmdline,length(cmdname)+1);
         }
      }
      if ( _macro() ) {
         _cmdline.get_command(text);
         _macro_call('execute',text,'a');
      }
      _macro('m',_macro());
      last_index(prev_index());

      if (def_unix_expansion) {
         /* Execute result of function call. */
         //_cmdline.set_command('',1);
         execute(_maybe_unix_expansion(text),'a');
         //append_retrieve_command(text);
      } else {
         execute(text,'ar');
      }
      if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_ONE_FILE_PER_WINDOW)) {
         def_one_file='+w';
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
   if (_no_child_windows()) {
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
_command void normal_character() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
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
_command void keyin_buf_name() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX)
{
   maybe_delete_selection();
   _str buf_name= _mdi._edit_window().p_buf_name;
   keyin(maybe_quote_filename(buf_name));
}
/**
 * Affects nothing.
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void nothing() name_info(','VSARG2_EDITORCTL)
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
   parse _default_font(CFG_DIALOG) with font_name','font_size','flags','charset;
   if( !isinteger(charset) ) charset=-1;
   if( !isinteger(font_size) ) font_size=8;

   if( font_name!="" ) {
      _minihtml_SetProportionalFont(font_name,charset);
   }
   if( isinteger(font_size) ) {
      _minihtml_SetProportionalFontSize(3,font_size*10);
   }
}

#define MINIHTML_INDENT_X 100

defeventtab _program_info_form;

void _program_info_form.on_resize() {
   // make sure the dialog doesn't get too scrunched
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(MIN_PROG_INFO_WIDTH, MIN_PROG_INFO_HEIGHT);
   }
   // resize the width of the tabs and html controls
   ctlsstab1.p_width=p_width-ctlsstab1.p_x;
   ctlminihtml2.p_width=ctlminihtml3.p_width=ctlminihtml4.p_width=
      ctlminihtml1.p_width=ctlsstab1.p_width- _dx2lx(SM_TWIP,4)-2*MINIHTML_INDENT_X;
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
   ctlminihtml2.p_height=ctlminihtml3.p_height=ctlminihtml4.p_height=ctlminihtml1.p_height=ctlsstab1.p_height-400;
}

void ctlcopy.lbutton_up()
{
   switch (ctlsstab1.p_ActiveTab) {
   case 0:
      ctlminihtml1._minihtml_command("copy");
      break;
   case 1:
      ctlminihtml2._minihtml_command("copy");
      break;
   case 2:
      ctlminihtml3._minihtml_command("copy");
      break;
   case 3:
      ctlminihtml4._minihtml_command("copy");
      break;
   }
}

static _str aboutLicenseInfo()
{
   // locate the license file, on Windows it is installed under 'docs'
   _str license_name = '';
   if (isEclipsePlugin()) {
      license_name = "license_eclipse.htm";
   } else {
      license_name = "license.htm";
   }
   _str vsroot = get_env("VSROOT");
   _str license_file = vsroot"docs"FILESEP :+ license_name;
   if (!file_exists(license_file)) {
      // Unix case, check in root installation directory
      license_file = vsroot""FILESEP:+ license_name;
   }
   if (!file_exists(license_file)) {
      // this is only needed for running out of the build directory
      license_file = vsroot"tools"FILESEP:+ license_name;
   }

   // get the contents of the license file 
   _str license_text = '';
   _GetFileContents(license_file, license_text);

   return license_text;
}

static _str aboutReleaseNotesInfo()
{
   // Get the contents of the readme and load it into ctlminihtml2
   _str vsroot = get_env("VSROOT");
   _str readme_text = '';
   _str readme_file = '';
   _maybe_append_filesep(vsroot);
   if (isEclipsePlugin()) {
      readme_file = vsroot"readme-eclipse.html";
   } else {
      readme_file = vsroot"readme.html";
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
// @param options         (optional). 'C'=center banner picture instead of
//                        right-aligning and filling extra space with background
//                        color. 'S'=size the dialog to fit the width of the
//                        banner picture.
void ctlok.on_create(_str text="", _str caption="", int bannerPicIndex=-1, int bannerBackColor=-1, _str options="")
{
/*
IMPORTANT!!!!! This dialog is too difficult to size correctly. The proper way to
write this dialog is similar to the find dialog. The minihtml controls should NOT 
be inside the tab control tabs. The tab control should just be a small tab control
displayed below one of the current visible minihtml control. Then you place the
small tab control at y=ctlminihtml.p_y+ctlminihtml.p_height; x=ctlminihtml.p_x,
width=ctlminihtml.p_width;

*/
   if( caption!="" ) {
      p_active_form.p_caption=caption;
   } else {
      p_active_form.p_caption=editor_name('A');
   }

   typeless font_name, font_size, flags, charset;
   parse _default_font(CFG_DIALOG) with font_name','font_size','flags','charset;
   if( !isinteger(charset) ) charset=-1;
   if( !isinteger(font_size) ) font_size=8;

   ctlminihtml1.p_text=text;

   // RGH - 5/15/2006
   // New banner for Eclipse Plugin
   if (isEclipsePlugin()) {
      ctlbob_banner.p_picture = _update_picture(-1, "eclipse_banner.bmp");
   }
   // If specified, set the banner picture displayed, otherwise
   // leave as default.
   if( bannerPicIndex!=-1 ) {
      // Since the banner box (ctl_banner_box) is contained by the form,
      // we must make sure that the form is big enough to hold the banner
      // box BEFORE we set the width of the banner box, or else it will
      // get clipped.
      p_active_form.p_width=p_active_form.p_width*2;
      p_active_form.p_height=p_active_form.p_height*2;
      // Since the banner picture control (ctlbob_banner) is contained
      // by the banner box (ctl_banner_box), we must make sure that the
      // banner box is big enough to hold the picture BEFORE we set the
      // picture index, or else it will get clipped.
      ctl_banner_box.p_width=ctl_banner_box.p_width*2;
      ctl_banner_box.p_height=ctl_banner_box.p_height*2;
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
   int fw = _dx2lx(SM_TWIP,ctl_banner_box._frame_width());
   int fh = _dy2ly(SM_TWIP,ctl_banner_box._frame_width());
   if( ctlbob_banner.p_x < fw ) {
      ctlbob_banner.p_x += fw - ctlbob_banner.p_x;
   }
   if( ctlbob_banner.p_y < fh ) {
      ctlbob_banner.p_y += fh - ctlbob_banner.p_y;
   }

   // Size the bounding background picture control for the banner to fit
   // the banner image.
   ctl_banner_box.p_width = ctlbob_banner.p_x + ctlbob_banner.p_width + fw;
   ctl_banner_box.p_height = ctlbob_banner.p_y + ctlbob_banner.p_height +fh;


   // Force form width to initially equal width of bounding banner box
//   p_active_form.p_width=ctl_banner_box.p_width;

   // Set the background color of bounding background picture control
   if( bannerBackColor!=-1 ) {
      ctl_banner_box.p_backcolor=bannerBackColor;
   } else {
      // Set product-specific background color
      if( isEclipsePlugin() ) {
         ctl_banner_box.p_backcolor=0x712d34;
      } else {
         //ctl_banner_box.p_backcolor=0x003BDDA0;
         ctl_banner_box.p_backcolor=0x00FFFFFF;
      }
   }

   // Leave a vertical gap between banner box and mini html box
   //ctlminihtml1.p_y=ctl_banner_box.p_y+ctl_banner_box.p_height+90;

   ctlminihtml1.p_x=MINIHTML_INDENT_X;
   options=upcase(options);
   if( pos('S',options)!=0 ) {
      // Do not allow the width of the form and html control to be
      // greater than the width of the banner image.
      //
      // Note: The width of the form already matches the width of the
      // banner image, so we only need to adjust the width of the html
      // control.
      int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
      // Note: ctlminihtml1.p_x*2 = gap on left and right side of control
      ctlminihtml1.p_width=client_width - ctlminihtml1.p_x*2;
      ctlsstab1.p_width=ctlminihtml2.p_width=ctlminihtml3.p_width=ctlminihtml1.p_width;
   } else {
      // Resize dialog (if necessary) to fit the text
      if( ctlminihtml1.p_width+2*ctlsstab1.p_x < ctl_banner_box.p_width+ctlok.p_width) {
         p_active_form.p_width=ctl_banner_box.p_width+ctlok.p_width;
      } else {
         // Note: ctlminihtml1.p_x*2 = gap on left and right side of control
         //p_active_form.p_width=ctlminihtml1.p_x*2 + ctlminihtml1.p_width + p_active_form._left_width()*2;
         p_active_form.p_width=ctlsstab1.p_x + ctlsstab1.p_width +  p_active_form._left_width()*2;
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
   ctlminihtml2.p_x = ctlminihtml3.p_x = ctlminihtml4.p_x=ctlminihtml1.p_x;
   ctlsstab1.p_y = ctl_banner_box.p_y + ctl_banner_box.p_height;
   ctlminihtml1.p_y = ctlminihtml2.p_y = ctlminihtml3.p_y = 0;

   //ctlcopy.p_y=ctlok.p_y=ctlminihtml1.p_y+ctlminihtml1.p_height+100;
   //ctlminihtml1.p_backcolor=0x80000022;
   //ctlminihtml2.p_backcolor=0x80000022;
   //ctlminihtml3.p_backcolor=0x80000022;
   ctlminihtml2.p_text = aboutReleaseNotesInfo();
   ctlminihtml3.p_text = aboutLicenseInfo();
   ctlminihtml4.p_text = aboutContactInfo();

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
   parse ksize/(1024) with before'.' +0 after;

   if (after>=.5) {
      before+=1;
   }
   return(before'MB');
}
void appendDiskInfo(_str &diskinfo,_str path,_str DirCaption,_str UsageCaption='')
{
   if( diskinfo!="" ) {
      diskinfo=diskinfo:+"\n";
   }
   if( diskinfo!="" ) {
      diskinfo=diskinfo:+"\n";
   }
   diskinfo=diskinfo:+"<b>"DirCaption"</b>:  "path;
   diskinfo=diskinfo:+getDiskInfo(path);

}
_str getDiskInfo(_str path)
{
   _str diskinfo="";
   int status=0;
#if __NT__
   _str FSInfo='';
   _str FSName='';
   int FSFlags=0;
   _str UsageInfo="";
   long TotalSpace, FreeSpace;
   status=_GetDiskSpace(path,TotalSpace,FreeSpace);
   if (!status) {
      UsageInfo = ','MBRound(FreeSpace)' free';
   }
   if (substr(path,1,2)=='\\') {
      typeless machinename, sharename;
      parse path with '\\'machinename'\'sharename'\';
      status=ntGetVolumeInformation('\\'machinename'\'sharename'\',FSName,FSFlags);
      if (!status) {
         FSInfo=','FSName;
      }
      diskinfo=diskinfo:+' (remote'FSInfo:+UsageInfo')';
   } else {
      status=ntGetVolumeInformation(substr(path,1,3),FSName,FSFlags);
      if (!status) {
         FSInfo=','FSName;
      }
      _str dt=_drive_type(substr(path,1,2));
      if (dt==DRIVE_NOROOTDIR) {
         diskinfo=diskinfo:+' (invalid drive)';
      } else if (dt==DRIVE_FIXED) {
         diskinfo=diskinfo:+' (non-removable drive'FSInfo:+UsageInfo')';
      } else if (dt==DRIVE_CDROM){
         diskinfo=diskinfo:+' (CD-ROM'FSInfo:+UsageInfo')';
      } else if (dt==DRIVE_REMOTE){
         diskinfo=diskinfo:+' (remote'FSInfo:+UsageInfo')';
      } else {
         diskinfo=diskinfo:+' (removable drive'FSInfo:+UsageInfo')';
      }
   }
#endif
   return diskinfo;
}

_str _version()
{
   _str number="";
   parse get_message(SLICK_EDITOR_VERSION_RC) with . . number . ;
   return(number);
}

_str _product_year()
{
   year := '';
   parse get_message(SLICK_EDITOR_VERSION_RC) with . 'Copyright' .'-'year .;

   return year;
}

_str _getProduct(boolean includeVersion=true,boolean includeArchInfo=false)
{
   product := _getApplicationName();
   if( isEclipsePlugin() ) {
#if __UNIX__
      product=product" Core v"eclipse_get_version()" for Eclipse";
#else
      product=product" v"eclipse_get_version()" for Eclipse";
#endif
   } else {
      product :+= ' '_product_year();
   }


   verInfo := '';
   archInfo := '';

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
         product :+= ')';
      }
   }

   return product;
}

_str aboutProduct(boolean includeVersion=false, _str altCaption=null)
{
   _str line = "";

   includeArchInfo := false;
#if __NT__
   includeArchInfo = true;
#else
   includeArchInfo = machine() :== 'LINUX';
#endif

   _str product = _getProduct(includeVersion, includeArchInfo);
   line=product;
   if( altCaption!=null ) {
      line=altCaption:+product;
   }

   return line;
}

_str _getVersion(boolean includeSuffix=true)
{
   _str version = "";
   _str suffix = "";
   parse get_message(SLICK_EDITOR_VERSION_RC) with . 'Version' version suffix .;
   if( includeSuffix && stricmp(suffix,"Beta") == 0 ) {
      version=version" "suffix;
   }
   return version;
}
_str _getUserSysFileName() {
#if __PCDOS__
   return("vusrs"_getVersion(false):+USERSYSO_FILE_SUFFIX);
#else
   return("vunxs"_getVersion(false):+USERSYSO_FILE_SUFFIX);
#endif
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
   _str copyright = "";
   parse get_message(SLICK_EDITOR_VERSION_RC) with . 'Copyright' +0 copyright;
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
   if (line == '') {
      line = 'No license found';
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
      return('Trial');
      break;
   case LICENSE_TYPE_NOT_FOR_RESALE:
      return('Not For Resale');
      break;
   case LICENSE_TYPE_BETA:
      return('Beta License');
      break;
   case LICENSE_TYPE_SUBSCRIPTION:
      return('Subscription');
      break;
   case LICENSE_TYPE_ACADEMIC:
      return('Academic');
      break;
   case LICENSE_TYPE_CONCURRENT:
      return('Concurrent');
      break;
   case LICENSE_TYPE_STANDARD:
      return('Standard');
      break;
   case LICENSE_TYPE_FILE:
      return('File');
      break;
   case LICENSE_TYPE_BORROW:
      return('Borrow');
      break;
   default:
      return('Unknown licensing ('type')');
   }
}

_str _getLicensedNofusers()
{
   type := _LicenseType();
   switch(type) {
   case LICENSE_TYPE_TRIAL:
      return('Trial');
   case LICENSE_TYPE_NOT_FOR_RESALE:
      return('Not For Resale');
   case LICENSE_TYPE_BETA:
      return('Beta License');
   case LICENSE_TYPE_SUBSCRIPTION:
      return('Subscription');
   case LICENSE_TYPE_ACADEMIC:
      return('Academic');
   case LICENSE_TYPE_CONCURRENT:
   case LICENSE_TYPE_STANDARD:
   case LICENSE_TYPE_FILE:
   case LICENSE_TYPE_BORROW:
      // 0 means that this is not a concurrent license
      return(_FlexlmNofusers());
   }
   return('Unknown licensing ('type')');
}

boolean _singleUserTypeLicense()
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
         line = line :+ " (borrowed)";
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
   if (line=='') return('');
   if( altCaption != null ) {
      line = altCaption:+line;
   } else {
      if (_LicenseType() == LICENSE_TYPE_BORROW) {
         caption = VSRC_CAPTION_LICENSE_BORROW_EXPIRATION;
      }
      _str line_b = "";
      _str line_e = "";
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
   _str line = '';
   int caption = -1;
   if (_LicenseType() == LICENSE_TYPE_CONCURRENT) {
      line = _LicenseServerName();
      caption = VSRC_CAPTION_LICENSE_SERVER;
   } 
   if (line == '') {
      line = _LicenseFile();
      caption = VSRC_CAPTION_LICENSE_FILE;
   }
   if (line=='') return('');
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
   if (line=='') return('');
   if( altCaption != null ) {
      line = altCaption:+line;
   } else {
      line = "<b>"get_message(VSRC_CAPTION_LICENSE_TO)"</b>: "line;
   }
   return line;
}

_str _getProductBuildDate()
{
   _str marker = _SLICK_BUILDDATE_MARKER;
   _str build_date='';
   parse marker with .'#'build_date'#';
   return build_date;
}

_str aboutProductBuildDate(_str altCaption=null)
{
   _str line = '';
   if (isEclipsePlugin()) {
      line = _getEclipseBuildDate();
   } else {
      line = _getProductBuildDate();
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
   _str expiration = "";
#if __OS390__ || __TESTS390__
   // Only demo version for OS/390 has expiration date.
   expiration=strip(get_message(DEMO_EXPIRATION_DATE_RC));
#endif
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
   case 'slick-keys':
      return 'SlickEdit';
   case '':
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
      return 'Mac OS X';
   case 'xcode-keys':
      return 'Xcode';
   case 'eclipse-keys':
      return 'Eclipse';
   }
   return '';
}

_str shortEmulationName (_str name)
{
   switch (name) {
   case 'SlickEdit':
      return 'slick';
   case 'BBEdit':
      return 'bbedit';
   case 'Brief':
      return 'brief';
   case 'CodeWarrior':
      return 'codewarrior';
   case 'CodeWright':
      return 'codewright';
   case 'Epsilon':
      return 'emacs';
   case 'GNU Emacs':
      return 'gnuemacs';
   case 'ISPF':
      return 'ispf';
   case 'Visual C++ 6':
      return 'vcpp';
   case 'Vim':
      return 'vi';
   case 'Visual Studio':
      return 'vsnet';
   case 'Windows':
   case 'CUA':
      return 'windows';
   case 'Mac OS X':
       return 'macosx';
   case 'Xcode':
      return 'xcode';
   case 'Eclipse':
      return 'eclipse';
   }
   return '';
}

_str _getEmulation()
{
   // special cases
   if (def_keys == '') {
      return 'SlickEdit (text mode edition)';
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
_str aboutProject(_str altCaption=null, boolean protectCustom = false)
{
   line := 'No project open';
   // do we have a project name?
   if (_project_name._length() > 0) {
      handle := _ProjectHandle();
      // do we have an open project?
      if (handle > 0) {
         // it might be visual studio?
         line = _ProjectGet_AssociatedFileType(handle);
         if (line == '') {
            // some projects will just tell you the type
            line = _ProjectGet_ActiveType();
            if (line == '') {
               // check for a template name attribute - these were added in v16, so 
               // all projects will not have them
               line = _ProjectGet_TemplateName(handle);
               if (line != "" && protectCustom && _ProjectGet_IsCustomizedProjectType(handle)) {
                  line = "Customized";
               }

               if (line == '') {
                  // try one last thing...it's hokey!
                  line = determineProjectTypeFromTargets(handle);
                  if (line == '') {
                     line = 'Other';
                  }
               }
            }
         }
         // capitalize the first letter of each word if there's a project open
         line = _cap_string(line);
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
         return 'NAnt';
      }
   }

   // SAS
   node = _xmlcfg_find_simple(handle, "/Project/Config/Menu/Target/Exec/@CmdLine[contains(., 'sassubmit', 'I')]");
   if (node > 0) {
      return 'SAS';
   }

   // Vera
   node = _xmlcfg_find_simple(handle, "/Project/Config/Menu/Target/Exec/@CmdLine[contains(., 'vera', 'I')]");
   if (node > 0) {
      return 'Vera';
   }

   // Verilog
   node = _xmlcfg_find_simple(handle, "/Project/Config/Menu/Target/Exec/@CmdLine[contains(., 'vlog', 'I')]");
   if (node > 0) {
      return 'Verilog';
   }

   // VHDL
   node = _xmlcfg_find_simple(handle, "/Project/Config/Menu/Target/Exec/@CmdLine[contains(., 'vcom', 'I')]");
   if (node > 0) {
      return 'VHDL';
   }

   return '';
}

_str aboutLanguage(_str altCaption=null)
{
   // is there a file open?
   line := '';
   bufId := _mdi.p_child;
   if (bufId && !_no_child_windows()) {
      lang := _LangId2Modename(bufId.p_LangId);
      line = '.'_get_extension(bufId.p_buf_name);
      if (lang != '') {
         line = line' ('lang')';
      }
   } else {
      line = 'No file open';
   }

   if( altCaption!=null ) {
      line=altCaption:+line;
   } else {
      line="<b>"get_message(VSRC_CAPTION_CURRENT_LANGUAGE)"</b>: "line;
   }
   return line;
}

#if __UNIX__
   _str macGetOSVersion();
   _str macGetOSName();
   _str macGetProcessorArch();
#endif

_str _getOsName()
{
   _str osname = "";

#if __NT__
   typeless MajorVersion, MinorVersion, BuildNumber, PlatformId, ProductType;
   _str CSDVersion;
   ntGetVersionEx(MajorVersion, MinorVersion, BuildNumber, PlatformId, CSDVersion, ProductType);
   if (length(MinorVersion) < 1) {
      MinorVersion = '0';
   }
   if (PlatformId == 1) {
      boolean IsWindows98orLater = (PlatformId == 1) &&
         ((MajorVersion > 4) ||
          ((MajorVersion == 4) && (MinorVersion > 0))
          );
      osname = "Windows 95";
      if (MajorVersion == '4' && MinorVersion == '90') {
         osname = 'Windows ME';
      } else if (IsWindows98orLater) {
         osname = 'Windows 98 or Later';
      }
   } else if (PlatformId == 2) {
      if (MajorVersion <= 4) {
         osname = 'Windows NT';
      } else if (MajorVersion <= 5) {
         if (MinorVersion >= 2) {
            if (ProductType == 1) {
               osname = 'Windows XP';
            } else {
               osname = 'Windows Server 2003';
            }
         } else if (MinorVersion == 1) {
            osname = 'Windows XP';
         } else {
            osname = 'Windows 2000';
         }
      } else if (MajorVersion <= 6) {
         if (MinorVersion == 0) {
            if (ProductType == 1) {
               osname = 'Windows Vista';
            } else {
               osname = 'Windows Server 2008';
            }
         } else if (MinorVersion == 1) {
            if (ProductType == 1) {
               osname = 'Windows 7';
            } else {
               osname = 'Windows Server 2008 R2';
            }
         } else if (MinorVersion == 2) {
            if (ProductType == 1) {
               osname = 'Windows 8';
            } else {
               osname = 'Windows Server 2012';
            }
         } else {
            osname='Windows 8 or Later';
         }
      } else {
         osname = 'Windows 8 or Later';
      }
   } else {
      osname = 'Windows ('PlatformId')';
   }
   // add an indicator if this is 64 bit
   if (ntIs64Bit() != 0) {
      osname :+= ' x64';
   }
#elif __UNIX__
   UNAME info;
   _uname(info);
   osname = info.sysname;

   // get a little more specific for Solaris platforms
   if (machine() == 'SPARCSOLARIS') {
      osname :+= ' Sparc';
   } else if (machine() == 'INTELSOLARIS') {
      osname :+= ' Intel';
   } else if (_isMac()) {
      osname =  macGetOSName();
   }
#endif

   return osname;
}

/**
 * Get processor and/or operating system architecture
 */
static _str _getArchitecture()
{
   _str architecture = "";
#if __UNIX__
   if(_isMac()) {
      architecture = macGetProcessorArch();
   } else {
      UNAME info;
      _uname(info);
      architecture :+= info.cpumachine;
   }
#endif
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

   #if __MACOSX__
   _os_version_name = macGetOSVersion();
   return _os_version_name;
   #endif

   _str osver = 'Unknown';

   // Try lsb_release command first (for LSB-compliant Linux distro)
   _str com_name = path_search("lsb_release");
   if (com_name != '' && _getOsVersionLSB(osver)) {
      // New version name.  Cache it.
      _os_version_name = osver;
      return osver;
   }

   // Try '/etc/issue' next.
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
 * @return boolean true on success, false otherwise.
 */
static boolean _getFirstLineFromFile(_str filename, _str &line)
{
   // open the file in a temp view
   int temp_view_id = 0;
   int orig_view_id = 0;
   int status = _open_temp_view(filename, temp_view_id, orig_view_id);
   if (status) {
      return false;
   }

   top();
   do {
      get_line_raw(line);
      line = strip(line);
      if (line != '') {
         break;
      }
   } while (down() != BOTTOM_OF_FILE_RC);

   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   if (line == '') {
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
 * @return boolean true on success, false otherwise
 */
static boolean _getOsVersionUnix(_str& osver)
{
   _str issue_file = '';
   if (!_getFirstLineFromFile('/etc/issue', issue_file)) {
      return false;
   }
   osver = '';
   // First, read everything up to the first backslash (\).
   if (pos('{[~\\]#}', issue_file, 1, 'R') == 0) {
      return false;
   }
   osver = strip(substr(issue_file, pos('S0'), pos('0')));

   // In case the string starts with 'Welcome to', strip it.
   if (pos('Welcome to', osver, 1, 'I') == 1) {
      osver = strip(substr(osver, length('Welcome to')+1));
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
 * @return boolean true if successful, false otherwise.
 */
static boolean _getOsVersionLSB(_str& osver)
{
   _str com_name = path_search("lsb_release");
   if (com_name == '') {
      // Command not available.
      return false;
   }
   com_name = com_name :+ " -d";

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
   if (buf == '') {
      return false;
   }

   // Now I have the output string from 'lsb_release -d'.
   // Get the substring that is the name of distro.
   //   format: 'Description:   SUSE Linux 10.1...'
   buf = strip(buf, 'T', "\n");
   if (pos("Description\\:[ \t]#{?#}", buf, 1, 'R') == 0) {
      return false;
   }
   buf = substr(buf, pos('S0'), pos('0'));
   osver = buf;
   return true;
}

_str aboutOsName(_str altCaption=null)
{
   _str line = _getOsName();
   if( altCaption!=null ) {
      line=altCaption:+line;
   } else {
      line="<b>"get_message(VSRC_CAPTION_OPERATING_SYSTEM)"</b>: "line;
   }
   return line;
}

_str aboutInstallationDirectory(_str altCaption=null)
{
   _str line = "";

   _str install_dir = "";
   _str caption = "";
   if( altCaption!=null ) {
      caption=altCaption;
   } else {
      caption=get_message(VSRC_CAPTION_INSTALLATION_DIRECTORY);
   }
   appendDiskInfo(install_dir,get_env("VSROOT"),caption);

   line=install_dir;

   return line;
}

_str aboutConfigurationDirectory(_str altDirectoryCaption=null, _str altUsageCaption=null)
{
   _str line = "";

   _str config_info = "";
   _str dir_caption = "";
   if( altDirectoryCaption!=null ) {
      dir_caption=altDirectoryCaption;
   } else {
      dir_caption=get_message(VSRC_CAPTION_CONFIGURATION_DIRECTORY);
   }
   _str usage_caption = "";
   if( altUsageCaption!=null ) {
      usage_caption=altUsageCaption;
   } else {
      usage_caption=get_message(VSRC_CAPTION_CONFIGURATION_DRIVE_USAGE);
   }
   appendDiskInfo(config_info,_ConfigPath(),dir_caption,usage_caption);

   line=config_info;

   return line;
}

_str aboutSpillFileDirectory(_str altDirectoryCaption=null, _str altUsageCaption=null)
{
   _str line = "";

   _str spill_info = "";
   if( _SpillFilename()!="" ) {
      // Spill File: C:\DOCUME~1\joesmith\LOCALS~1\Temp\$slk.1 (non-removable drive,FAT32)
      // Spill File Directory Drive Usage: 31446MB / 36860MB
      _str dir_caption = "";
      if( altDirectoryCaption!=null ) {
         dir_caption=altDirectoryCaption;
      } else {
         dir_caption=get_message(VSRC_CAPTION_SPILL_FILE);
      }
      _str usage_caption = "";
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
   _str line = "";

   line=line                        :+
      aboutInstallationDirectory()  :+
      "\n"                          :+
      aboutConfigurationDirectory();
   _str spill_line = aboutSpillFileDirectory();
   if( spill_line!="" ) {
      line=line                     :+
         "\n"                       :+
         spill_line;
   }

   return line;
}

_str aboutOsInfo(_str altCaption=null)
{
   _str line = "";

   _str osinfo = "";
#if __NT__
   // OS: Windows XP
   // Version: 5.01.2600  Service Pack 1
   typeless MajorVersion,MinorVersion,BuildNumber,PlatformId,ProductType;
   _str CSDVersion;
   ntGetVersionEx(MajorVersion,MinorVersion,BuildNumber,PlatformId,CSDVersion,ProductType);
   if( length(MinorVersion)<1 ) {
      MinorVersion='0';
   }
   // Pretty-up the minor version number for display
   if( length(MinorVersion)<2 ) {
      MinorVersion='0'MinorVersion;
   }
   osinfo=osinfo:+"<b>"get_message(VSRC_CAPTION_OPERATING_SYSTEM)"</b>:  "_getOsName();
   osinfo=osinfo:+"\n";
   osinfo=osinfo:+"<b>"get_message(VSRC_CAPTION_OPERATING_SYSTEM_VERSION)"</b>:  "MajorVersion'.'MinorVersion'.'BuildNumber'&nbsp;&nbsp;'CSDVersion;
#elif __UNIX__
   // OS: SunOS
   // Kernel Level: 5.7
   // Build Version: Generic_106541-31
   // X Server Vendor: Hummingbird Communications Ltd.
   UNAME info;
   _uname(info);
   osinfo=osinfo:+"<b>"get_message(VSRC_CAPTION_OPERATING_SYSTEM)"</b>: "_getOsName();
   osinfo=osinfo:+"\n";
   if (machine() :== 'LINUX' || _isMac()) {
      osinfo=osinfo:+"<b>"get_message(VSRC_CAPTION_OPERATING_SYSTEM_VERSION)"</b>: "_getOsVersion();
      osinfo=osinfo:+"\n";
   }

   if (_isMac() == false) {
      osinfo=osinfo:+"<b>"get_message(VSRC_CAPTION_KERNEL_LEVEL)"</b>: "info.release;
      osinfo=osinfo:+"\n";
      osinfo=osinfo:+"<b>"get_message(VSRC_CAPTION_BUILD_VERSION)"</b>: "info.version;
      osinfo=osinfo:+"\n";
   }
   // Display processor architecture
   osinfo=osinfo:+"<b>"get_message(VSRC_CAPTION_PROCESSOR_ARCH)"</b>: "_getArchitecture();
   osinfo=osinfo:+"\n";

   // Display X server details
   if (_isMac() == false) {
      osinfo=osinfo:+"\n";
      osinfo=osinfo:+"<b>"get_message(VSRC_CAPTION_XSERVER_VENDOR)"</b>: "_XServerVendor();
   }
#endif

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

#if __UNIX__
   if (_isMac()) {
      //TotalVirtual=8388608;
      //AvailVirtual=8388608;
#if __MACOSX__
      _MacGetMemoryInfo(TotalVirtual, AvailVirtual);
#endif
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
      if (pagesWiredDownStr=='') {
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
         if (gotFree && isnumber(first_char(line))) {
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

#else

   index := find_index("ntGlobalMemoryStatus", PROC_TYPE|DLLCALL_TYPE);
   if (index_callable(index)) {
      long MemoryLoadPercent, TotalPhys, AvailPhys, TotalPageFile, AvailPageFile;
      ntGlobalMemoryStatus(MemoryLoadPercent,TotalPhys,AvailPhys,TotalPageFile,AvailPageFile,TotalVirtual,AvailVirtual);
      if (AvailPhys < AvailVirtual) AvailVirtual = AvailPhys;
      if (TotalPhys > TotalVirtual) TotalVirtual = TotalPhys;
   }

#endif

   // success?
   if (TotalVirtual > 0) {
      return 0;
   }

   // did not find what we needed
   return -1;
}

_str aboutMemoryInfo(_str altCaption=null)
{
   _str line = "";
   _str memory = "";
#if __NT__
   // Memory Load: %39
   // Physical Memory Usage: 413MB / 1048MB
   // Page File Usage: 339MB / 2521MB
   // Virtual Memory Usage: 107MB / 2097MB
   long MemoryLoadPercent, TotalPhys, AvailPhys, TotalPageFile, AvailPageFile, TotalVirtual, AvailVirtual;
   ntGlobalMemoryStatus(MemoryLoadPercent,TotalPhys,AvailPhys,TotalPageFile,AvailPageFile,TotalVirtual,AvailVirtual);
   memory :+= MemoryLoadPercent"%";
   memory :+= " "get_message(VSRC_CAPTION_MEMORY_LOAD);
   memory :+= ", ";
   memory :+= MBRound(TotalPhys-AvailPhys)'/'MBRound(TotalPhys);
   memory :+= " "get_message(VSRC_CAPTION_PHYSICAL_MEMORY_USAGE);
   memory :+= ", ";
   memory :+= MBRound(TotalPageFile-AvailPageFile)'/'MBRound(TotalPageFile);
   memory :+= " "get_message(VSRC_CAPTION_PAGE_FILE_USAGE);
   memory :+= ", ";
   memory :+= MBRound(TotalVirtual-AvailVirtual)'/'MBRound(TotalVirtual);
   memory :+= " "get_message(VSRC_CAPTION_VIRTUAL_MEMORY_USAGE);
#else

   long TotalVirtual=0, AvailVirtual=0;
   if (!_VirtualMemoryInfo(TotalVirtual, AvailVirtual)) {
      if(TotalVirtual > 0 && AvailVirtual > 0) {
          MemoryLoadPercent := 100 * (TotalVirtual - AvailVirtual) intdiv TotalVirtual;
          memory :+= MemoryLoadPercent"%";
          memory :+= " "get_message(VSRC_CAPTION_MEMORY_LOAD);
          memory :+= ", ";
          // report virtual memory statistics
          memory :+= MBRound(TotalVirtual-AvailVirtual)'/'MBRound(TotalVirtual);
          memory :+= " "get_message(VSRC_CAPTION_VIRTUAL_MEMORY_USAGE);
      }
   }

#endif

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
   if (line != '') {
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
   ScreenInfo list[];
   getAllScreens(list);

   line := '';
   for (i := 0; i < list._length(); i++) {
      if (line != '') {
         line :+= ', ';
      }
      line :+= list[i].width' x 'list[i].height;
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
   _str line = "";

   _str eclipse_info = "";
   if( isEclipsePlugin() ) {
      _str eclipse_version="";
      _str jdt_version="";
      _str cdt_version="";
      _eclipse_get_eclipse_version_string(eclipse_version);
      _eclipse_get_jdt_version_string(jdt_version);
      _eclipse_get_cdt_version_string(cdt_version);
      eclipse_info=eclipse_info:+"<b>Eclipse: </b> ":+eclipse_version;
      eclipse_info=eclipse_info:+"\n";
      eclipse_info=eclipse_info:+"<b>JDT: </b> ":+jdt_version;
      eclipse_info=eclipse_info:+"\n";
      eclipse_info=eclipse_info:+"<b>CDT: </b> ":+cdt_version;
   }

   line=eclipse_info;
   if( line!="" && altCaption!=null ) {
      line=altCaption:+line;
   }

   return line;
}

static _str aboutContactInfo()
{
   vsroot := get_env("VSROOT");
   _maybe_append_filesep(vsroot);
   contact_file := vsroot:+"contact.html";
   contact_text := "";
   _GetFileContents(contact_file, contact_text);
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
_command void version() name_info(','VSARG2_EDITORCTL)
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
_command void vsversion(_str options='', boolean doModal = false) name_info(','VSARG2_EDITORCTL)
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
   _str not_for_resale = "";
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
   //   serial=stranslate(serial,raw_serial'-'basePackNofusers,raw_serial);
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
   _str text = "";
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

   text = text :+ "\n\n";

   // Convert to HTML for the dialog
   text = stranslate(text,'<br>',"\n");

   // Need to show Eclipse About dialog modal because it Slick-C stacks if you press the X
   // RGH - 5/15/2006
   // This dialog is now modal all the time (display the readme tab first if it's a first time startup)
   _str showCmdline = "";
   if( isEclipsePlugin() || doModal ) {
      showCmdline = '-modal _program_info_form';
   } else{
      showCmdline = '-xy _program_info_form';
   }
   show(showCmdline,text,"",-1,-1,options);
}

void getAllScreens(ScreenInfo (&list)[])
{
   int screenX, screenY, screenW, screenH;
   
   // get the first main monitor
   _GetScreen(screenX, screenY, screenW, screenH);
   ScreenInfo info;
   info.x = screenX;
   info.y = screenY;
   info.width = screenW;
   info.height = screenH;

   // add it to our verified list
   list[0] = info;

   // now go through our verified list and get some more
   for (i := 0; i < list._length(); i++) {

      ScreenInfo adjoining[];
      getAdjoiningScreens(list[i], adjoining);

      // go through all the adjoining ones
      for (j := 0; j < adjoining._length(); j++) {
         ScreenInfo adjoin = adjoining[j];
         // see if they match any of the unique ones
         int k;
         for (k = 0; k < list._length(); k++) {
            if (adjoin.x == list[k].x && adjoin.y == list[k].y) {
               // this is match, break
               break;
            } 
         }

         // did we get all the way to the end?
         if (k == list._length()) {
            // this is unique, add it to our list
            list[list._length()] = adjoin;
         }

      }
   }
}

void getAdjoiningScreens(ScreenInfo info, ScreenInfo (&list)[])
{
   int startX, startY;
   ScreenInfo newInfo;

   // north
   startX = info.x;
   startY = info.y - 1;
   getScreenInfo(startX, startY, newInfo);
   list[list._length()] = newInfo;

   // northeast
   startX = info.x + info.width;
   startY = info.y - 1;
   getScreenInfo(startX, startY, newInfo);
   list[list._length()] = newInfo;

   // east
   startX = info.x + info.width;
   startY = info.y;
   getScreenInfo(startX, startY, newInfo);
   list[list._length()] = newInfo;

   // southeast
   startX = info.x + info.width;
   startY = info.y + info.height;
   getScreenInfo(startX, startY, newInfo);
   list[list._length()] = newInfo;

   // south
   startX = info.x;
   startY = info.y + info.height;
   getScreenInfo(startX, startY, newInfo);
   list[list._length()] = newInfo;

   // southwest
   startX = info.x - 1;
   startY = info.y + info.height;
   getScreenInfo(startX, startY, newInfo);
   list[list._length()] = newInfo;

   // west
   startX = info.x - 1;
   startY = info.y;
   getScreenInfo(startX, startY, newInfo);
   list[list._length()] = newInfo;

   // northwest
   startX = info.x - 100;
   startY = info.y - 100;
   getScreenInfo(startX, startY, newInfo);
   list[list._length()] = newInfo;
}

void getScreenInfo(int startX, int startY, ScreenInfo &info)
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
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command cap_word() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   int start_col=0;
   _str word=cur_word(start_col,def_from_cursor,false,def_word_continue);
   if (word=='') {
      retrieve_command_results();
      message(nls('No word at cursor'));
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
 * the cursor, and returns '' in that case.
 *
 * @return  Returns the current identifier.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str _begin_identifier()
{
   id := cur_identifier(auto start_col);
   if (id != '') {
      p_col = start_col;
   }
   return id;
}
/**
 * Move the cursor to the last character of the identifier under the
 * cursor. Does not move the cursor if there is no identifier under
 * the cursor, and returns '' in that case.
 *
 * @return  Returns the current identifier.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str _end_identifier()
{
   id := cur_identifier(auto start_col);
   if (id != '') {
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
 * @param start_col
 * @param from_cursor
 * @param end_prev_word
 * @param multi_line
 *
 * @return  Returns the current word.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str cur_word(int &start_col,_str from_cursor="",boolean end_prev_word=false,boolean multi_line=false)
{
   /*
      end_prev_word effects the following case.

          word1<cursor here>  word2

       By default, word2 is returned,  if end_prev_word==1 then word1 is returned.
   */
   int option=VSCURWORD_WHOLE_WORD;
   if( from_cursor!='1') {
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
   if (word!='') {
      start_col=_text_colc(start_col,'P');
   }
   return(word);
}

_str cur_word2(int &start_col=0,int option=VSCURWORD_WHOLE_WORD,
               boolean multi_line=false,
               boolean doRestorePos=true
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
   int status=0;
   word_chars := _extra_word_chars:+p_word_chars;
   save_pos(auto p);
   if ( option!=VSCURWORD_WHOLE_WORD ) {
      _str common_re='([~\od'word_chars']:1,1000|^)\c[\od'word_chars']';
      common_re='('common_re')|^';
      if (option==VSCURWORD_AT_END_USE_PREV && p_col!=1 &&
          !(pos('[\od'word_chars']',get_text(1),1,'r') || _dbcsIsLeadByteBuf(get_text_raw()))
         ) {
         left();
         boolean bool=pos('[\od'word_chars']',get_text(1),1,'r')  || _dbcsIsLeadByteBuf(get_text_raw());
         right();
         if (bool) {
            //start_col=lastpos('\c['word_chars']#',line, col,'r')
            status=search('(\c[\od'word_chars']#:1,1000)|^','h@r-');
         } else {
            status=search(common_re,'h@r-');
         }
      } else {
         if (multi_line) {
            if( pos('[\od'word_chars']',get_text(),1,'r') || _dbcsIsLeadByteBuf(get_text_raw())) {
               status=search(common_re,'h@r-');
            } else {
               status=search('[\od'word_chars']','h@r');
            }
         } else {
            status=search(common_re,'h@r-');
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
/*
_command begin_word() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
   word=cur_word(start_col);
   if (word='') return(1);
   p_col=_text_colc(line,start_col,'I');
   return(0)
*/

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
_command void next_word() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();

   // In ISPF emulation, if the cursor is in the prefix area,
   // next-word should jump out of the prefix area and to the
   // first non-blank character on the line.
   if (_isEditorCtl() && p_LCHasCursor && _LCIsReadWrite()) {
      first_non_blank();
      p_LCHasCursor=false;
      return;
   }

   _str status='';
   if (def_subword_nav) {
      status=skip_subword('');
   } else {
      status=skip_word('');
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
_command void next_full_word() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();

   // In ISPF emulation, if the cursor is in the prefix area,
   // next-word should jump out of the prefix area and to the
   // first non-blank character on the line.
   if (_isEditorCtl() && p_LCHasCursor && _LCIsReadWrite()) {
      first_non_blank();
      p_LCHasCursor=false;
      return;
   }

   _str status=skip_word('');
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
_command void next_subword() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();

   // In ISPF emulation, if the cursor is in the prefix area,
   // next-word should jump out of the prefix area and to the
   // first non-blank character on the line.
   if (_isEditorCtl() && p_LCHasCursor && _LCIsReadWrite()) {
      first_non_blank();
      p_LCHasCursor=false;
      return;
   }

   _str status=skip_subword('');
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
_command void prev_word() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int was_command_state=command_state();
   if (was_command_state) init_command_op();
   if (def_subword_nav) {
      skip_subword('-');
   } else {
      skip_word('-');
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
_command void prev_full_word() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int was_command_state=command_state();
   if (was_command_state) init_command_op();
   skip_word('-');
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
_command void prev_subword() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int was_command_state=command_state();
   if (was_command_state) init_command_op();
   skip_subword('-');
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
      if( direction_option=='-' ) {
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
        boolean was_end_of_line = (p_col>_text_colc());
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

   } else if (def_brief_word && (!p_UTF8 && !_dbcs())) {
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
            ch=get_text();
            if (pos(re1,ch,1,'r') || _dbcsIsLeadByteBuf(get_text_raw())) {
               re1='((^|[~\od'word_chars'])\c[\od'word_chars'])';
            } else {
               re1='((^|[\od \t'word_chars'])\c[~\od \t'word_chars'])';
            }
            search(re1,'@rhe-<');
         }
      } else {
         ch=get_text();
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
 * the word characters for a specific extension, use the Extension Options
 * dialog box ("Tools", "Configuration", "File Extension Setup...", select
 * the Advanced tab).
 *
 * @see next_word
 * @see prev_word
 * @see cur_word
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void begin_word() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int start_col=0;
   _str word = cur_word(start_col);
   if (word != '') {
      p_col=_text_colc(start_col,'I');
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
_command void select_word() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (def_subword_nav) {
      pselect_subword(_duplicate_selection(''),false);
   } else {
      pselect_word(_duplicate_selection(''));
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
_command void select_subword() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   pselect_subword(_duplicate_selection(''),false);
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
_command void select_full_word() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   pselect_word(_duplicate_selection(''));
}
_str def_word_delim='0';

_str pselect_subword(typeless mark, boolean skipTrailing=true)
{
   _deselect(mark);
   _select_char(mark);
   int status;
   save_pos(auto p);
   status = skip_subword('',skipTrailing);
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
      _str ch=get_text();
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
static int skip_subword(_str direction_option, boolean skipTrailing=true)
{
   int orig_col = p_col;
   _str ch = get_text();
   int status = 0;
   _str word_chars = _clex_identifier_chars();
   if (direction_option == '-') {
      if (p_col == 1) {
         up();
         _end_line();
         return 0;
      }
      boolean moved = maybeEatLeadingChars(ch);
      if (p_col == 1) {
         return 0;
      }
      ch = get_text();
      left();
      _str tempCh = get_text();
      // Word <- cursor on 'o' and you hit prev-word
      if (isLowercase(ch) && isalpha(tempCh) && upcase(tempCh) == tempCh) {
         maybeSkipBackOverChar("$");
         return 0;
      }
      _str prevCh = get_text();
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
            _str nextChar = get_text();
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
            boolean curIsAlpha = isalpha(get_text());
            boolean curIsLCase = false;
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
static void maybeSkipBackOverChar(_str ch='') {
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
static boolean maybeEatLeadingChars(_str ch='', boolean cameFromAlpha=false, boolean alphaWasLCase=false)
{
   _str prevCh = get_prev_char();
   int orig_col = p_col;
   if (isspace(ch)) {
      search('['def_space_chars']#','@reh-<');
   } else if (isspace(prevCh)){
      left();
      search('['def_space_chars']#','@reh-<');
   }
   _str curChar = get_text();
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
static boolean maybeEatTrailingChars(boolean forceSkip=true, boolean cameFromAlpha=false, boolean alphaWasLCase=false)
{
   if (!forceSkip) {
      return false;
   }
   boolean moved = false;
   _str word_chars = _clex_identifier_chars();
   // here we want to move to the next alpha char, non-identifier char, but skip a string of spaces
   // we are skipping non-alpha identifier chars, ie. numbers or $
   int col = p_col;
   int status = search('[a-zA-Z]|[^'word_chars']|[\n]|[\-_]','@reh+<');
   moved = p_col != col;

   _str ch = get_text();
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
static boolean isLowercase(_str ch)
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
_command void select_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   // keeps track of the last type of selection made
   static _str last_selection_type;
   if (_select_type()=='') {
      last_selection_type='';
   }
   int status=0;
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
      select_all();
      last_selection_type="ALL";
      message("Selected entire file.");
      break;
   case "ALL":
      _deselect();
      last_selection_type='';
      message("Deselected.");
      return;
   }
   lock_selection('q');
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
 * @see upcase
 * @see upcase_selection
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command upcase_word() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   int start_col=0;
   _str word=cur_word(start_col,def_from_cursor,false,def_word_continue);
   if ( word=='' ) {
      retrieve_command_results();
      message(nls('No word at cursor'));
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
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command lowcase_word() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   /* Set variable def_from_cursor to 1 if you want to start from cursor */
   int start_col=0;
   _str word=cur_word(start_col,def_from_cursor,false,def_word_continue);
   if ( word=='' ) {
      retrieve_command_results();
      message(nls('No word at cursor'));
      return(1);
   }
   p_col=_text_colc(start_col,'I');
   _delete_text(_rawLength(word));
   _insert_text(lowcase(word));
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
_command copy_word() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int status = 0;
   init_command_op();
   boolean push=name_name(prev_index('','C'))!='copy-word';
   if ( push && !def_subword_nav) {
      int i=_text_colc(p_col,'p');
      int LineLen=_line_length();
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
   boolean origDefBriefWord = def_brief_word;
   def_brief_word = 0;
   boolean origDefVcppWord = def_vcpp_word;
   def_vcpp_word = 0;

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
_command copy_full_word() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int status = 0;
   init_command_op();
   boolean push=name_name(prev_index('','C'))!='copy-full-word';
   if ( push ) {
      int i=_text_colc(p_col,'p');
      int LineLen=_line_length();
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
   boolean origDefBriefWord = def_brief_word;
   def_brief_word = 0;
   boolean origDefVcppWord = def_vcpp_word;
   def_vcpp_word = 0;

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
_command copy_subword() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int status = 0;
   init_command_op();
   boolean push=name_name(prev_index('','C'))!='copy-subword';
   if ( push ) {
      int i=_text_colc(p_col,'p');
      int LineLen=_line_length();
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
   boolean origDefBriefWord = def_brief_word;
   def_brief_word = 0;
   boolean origDefVcppWord = def_vcpp_word;
   def_vcpp_word = 0;

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
   int status=0;
   typeless old1,old2,old3,old4;
   int start_line;
   int view_id;
   get_window_id(view_id);
   activate_window(VSWID_RETRIEVE);
   int Noflines=p_Noflines;
   _str result='';
   _str line='';
   int i;
   if (arg(2)=='') {
      activate_window(view_id);
      for (i=1; i<=Noflines+1 ; ++i) {
         if ( upcase(arg(1))=='N' ) {
            _retrieve_next();
         } else {
            _retrieve_prev();
         }
         _cmdline.get_command(line);
         if ( substr(line,1,1)!='@' ) {
            result=line;
            break;
         }
         _cmdline.set_command('',1,1);
      }
   } else {
      // Old code was way to slow.  Speeding it up by using search built-in
      _cmdline.get_command(old1,old2,old3,old4); /* ,old5,old6,old7,old8 */
      start_line=p_line;
      int done=0;
      if ( upcase(arg(1))=='N' ) {
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
         _str re='^'_escape_re_chars(arg(2));
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
      if ( arg(2):!='' ) {
         if ( substr(line,1,length(arg(2)))==arg(2) && line:!=arg(3) ) {
            result=line;
            break;
         }
      } else {
         if ( substr(line,1,1)!='@' ) {
            result=line;
            break;
         }
         _cmdline.set_command('',1,1);
      }
      if ( arg(2):!='' ) {
         _cmdline.set_command(old1,old2,old3,old4); /* ,old5,old6,old7,old8 */
      }
   }
#endif
   return(result);
}
#define VSLANGUAGE_NOTSUPPORTEDPREFIX 'NotSupported_'
_str _getSupportedLangId(_str lang)
{
   if (substr(lang,1,length(VSLANGUAGE_NOTSUPPORTEDPREFIX))==VSLANGUAGE_NOTSUPPORTEDPREFIX) {
      return(substr(lang,length(VSLANGUAGE_NOTSUPPORTEDPREFIX)+1));
   }
   return(lang);
}
long _getTotalKMemory() {
#if __NT__
   long MemoryLoadPercent, TotalPhys, AvailPhys, TotalPageFile, AvailPageFile, TotalVirtual, AvailVirtual;
   ntGlobalMemoryStatus(MemoryLoadPercent,TotalPhys,AvailPhys,TotalPageFile,AvailPageFile,TotalVirtual,AvailVirtual);
   return TotalPhys;
#else
   long TotalVirtual=0, AvailVirtual=0;
   if (!_VirtualMemoryInfo(TotalVirtual, AvailVirtual)) {
      return TotalVirtual;
   }
   return 0;
#endif
}
#if 0
static void auto_set_buffer_cache(_str &large_file_editing_msg) {
   // IF buffer size > 100 megabytes
   if (def_auto_set_buffer_cache && p_buf_size>(def_auto_set_buffer_cache_ksize*1024)) { 
      // See if we should adjust the cache size. Default is too small for performing edits.
      parse _cache_size() with auto ksizeStr .;
      long ksize=(long)ksizeStr;
      //say('ksize='ksize);
      long recommended_ksize=(long)(p_buf_size/1024)*2;
      if (isinteger(ksize) && ksize>=0 && ksize<recommended_ksize) {
         long physical_memory_ksize=_getTotalKMemory();
         //say('physical_memory_ksize='physical_memory_ksize);
         if (physical_memory_ksize) {
            /* 
                Only allow SlickEdit 1/4 of the physical memory. 
                old comment:Guess 400 megabytes for the rest of SlickEdit. 
                            This is a bit low if the user has
                            many big tag files (maybe created by auto-tagging maybe).
            */ 
            //long available_for_buffer_cache=physical_memory_ksize/2-400000;
            long available_for_buffer_cache=physical_memory_ksize/4;
            boolean have_enough_available=false;
            if (available_for_buffer_cache>(long)ksize) {
               have_enough_available=true;
               // Twice the buffer size
               long new_kcache=recommended_ksize;
               if (available_for_buffer_cache<new_kcache) {
                  new_kcache=available_for_buffer_cache;
               }
               //say(recommended_ksize);
               _cache_size(new_kcache);
               large_file_editing_msg="Buffer cache size automatically increased";
            }
            if (!have_enough_available) {
               /*use_large_file_warning=true;
               if (large_file_editing_msg!='') {
                  large_file_editing_msg="\n":+large_file_editing_msg;
               } */
               _str msg="Large edit operations will generate a large spill file. Add memory for better performance";
               //large_file_editing_msg=msg:+large_file_editing_msg;
               _ActivateAlert(3, 8,msg);
               sticky_message(msg);
#if 0
               _str more="";
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
 * @return Return 'true' if the given language ID (see {@link p_LangId})
 *         is a standard language supported at installation or if it
 *         is a language added by the user.
 * 
 * @param lang    language ID 
 *  
 * @see _EnumerateInstalledLanguages 
 */
boolean _IsInstalledLanguage(_str lang)
{
   return (pos(' 'lang' ',' 'gInstalledLanguages' ') > 0);
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
void _SetEditorLanguage(_str lang='',
                        boolean bypass_buffer_setup=false,
                        boolean map_xml_files=false, boolean called_from_mapxml_create_tagfile=false,
                        boolean force_select_mode_cb=false)
{
   _str large_file_editing_msg="";
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
   int status=0;
   int index=0;
   int len=0;
   int selmodcb_index = find_index('userSelectEditorLanguage',PROC_TYPE|COMMAND_TYPE);
   if (!index_callable(selmodcb_index)) {
      selmodcb_index = find_index('userSelectEditMode',PROC_TYPE|COMMAND_TYPE);
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
   if (_GetXMLWrapFlags(XW_ENABLE_CONTENTWRAP, lang)) {
      //Clear xmlwrap state if xmlwrap content wrapping is enabled
      XWclearState();
   }
   //bypass_buffer_setup=(arg(2)!='' && arg(2));
   _str keys=def_keys;
   _str buf_name='';
   _str orig_buf_ext='';

   if ( lang!='' ) {
      if ( substr(lang,1,length(VSLANGUAGE_NOTSUPPORTEDPREFIX)):==VSLANGUAGE_NOTSUPPORTEDPREFIX ) {
         // This specifically fixes the problem of switching to/from
         // command/insert mode in vi emulation, where
         // _SetEditorLanguage() is called with p_LangId.
         // We put the fix here instead of in vi_switch_mode() in case a
         // situation arises in future where we want to pass in the
         // extension explicitly.
         lang=substr(lang,length(VSLANGUAGE_NOTSUPPORTEDPREFIX)+1);
      }
      orig_buf_ext='';
      buf_name='';
   } else {
      orig_buf_ext = _get_extension(p_buf_name);
      buf_name=p_buf_name;

      // check for CVS backup file, get the real extension, not
      // the revision number
      _str just_file_name = _strip_filename(p_buf_name,'p');
      while (isnumber(lang) && substr(just_file_name,1,2)==".#") {
         orig_buf_ext = _get_extension(just_file_name);
         just_file_name=_strip_filename(just_file_name,'e');
      }
   }

   // _Filename2LangId calls the suffix functions and
   // _ext_Filename2LangId callbacks, so we do not have to do it here.
   int setup_index = 0;
   if (lang == '') {
      if (!bypass_buffer_setup) {
         p_AutoSelectLanguage = false;
      }
      lang = _Filename2LangId(buf_name);
      setup_index = find_index('def-language-'lang, MISC_TYPE);
      if (!setup_index) {
         check_and_load_support(orig_buf_ext,setup_index,buf_name);
         lang=_Filename2LangId(buf_name);
      }
   }
   if (p_buf_size>def_use_fundamental_mode_ksize*1024) {
      if (lang!='fundamental' && lang!='') {
         if (large_file_editing_msg) {
            large_file_editing_msg:+="\n";
         } 
         large_file_editing_msg:+="Plain Text mode chosen for better performance";
         //large_file_editing_msg="Buffer cache size automatically increased";
         lang='fundamental';
      }
   }
   if (p_buf_size>def_use_undo_ksize*1024) {
      if (large_file_editing_msg) {
         large_file_editing_msg:+="\n";
      } 
      large_file_editing_msg:+="Undo turned off for better performance";
      p_undo_steps=0;
   }
   if (large_file_editing_msg!='') {
      //say(large_file_editing_msg);
      _ActivateAlert(0, 24,large_file_editing_msg);
      //sticky_message(msg);
   }

   setup_index = find_index('def-language-'lang, MISC_TYPE);
   if (!setup_index) {
      check_and_load_support(lang,setup_index,buf_name);
      setup_index = find_index('def-language-'lang, MISC_TYPE);
   }

   if ( !bypass_buffer_setup ) {
      p_mode_eventtab=_default_keys;
      p_index=find_index('def-options-'lang,MISC_TYPE);
      p_SyntaxIndent = LanguageSettings.getSyntaxIndent(lang);

      if (p_mdi_child) {
         p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(lang);
      }

      p_ModifyFlags &= ~MODIFYFLAG_CONTEXT_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_STATEMENTS_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_LOCALS_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_CONTEXTWIN_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_PROCTREE_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_PROCTREE_SELECTED;
      p_ModifyFlags &= ~MODIFYFLAG_FCTHELP_UPDATED;
   }

   if ( setup_index ) {
      boolean extensionSupported = true;
      VS_LANGUAGE_OPTIONS langOptions;
      _GetDefaultLanguageOptions(lang, orig_buf_ext, langOptions);
      // Note that we look up the index in the names table again.
      // This is a better API since we are independant of implementation.
      //say('selmode lexer_name='lexer_name' cf='color_flags);
      if ( !bypass_buffer_setup ) {
         p_mode_name=langOptions.szModeName;
         if (extensionSupported) {
            p_LangId=lang;
         } else {
            // We need this so that InitProjectTools does not get
            // a null extension.
            p_LangId=VSLANGUAGE_NOTSUPPORTEDPREFIX:+lang;
         }
         p_SoftWrap=langOptions.SoftWrap;
         p_SoftWrapOnWord=langOptions.SoftWrapOnWord;

         p_begin_end_style = langOptions.BeginEndStyle;
         p_indent_case_from_switch = (langOptions.IndentCaseFromSwitch != 0);
         p_no_space_before_paren = (langOptions.NoSpaceBeforeParen != 0);
         p_pad_parens = (langOptions.PadParens != 0);
         p_pointer_style = langOptions.PointerStyle;
         p_function_brace_on_new_line = (langOptions.FunctionBraceOnNewLine != 0);
         p_keyword_casing = langOptions.KeywordCasing;

         p_tag_casing = langOptions.TagCasing;
         p_attribute_casing = langOptions.AttributeCasing;
         p_value_casing = langOptions.ValueCasing;
         p_hex_value_casing = langOptions.HexValueCasing;

         checkLineNumbersLengthForISPF(langOptions.LineNumbersFlags, langOptions.LineNumbersLen);
         if (langOptions.LineNumbersFlags & LNF_ON) {
            if (langOptions.LineNumbersFlags & LNF_AUTOMATIC) {
               // we want automatic mode...
               p_LCBufFlags|=(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
            } else {
               p_LCBufFlags&=~VSLCBUFFLAG_LINENUMBERS_AUTO;
               p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS;
            }
         } else {
            p_LCBufFlags&=~(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
         }
         p_line_numbers_len=langOptions.LineNumbersLen;

         p_color_flags=langOptions.ColorFlags;
         p_lexer_name=langOptions.szLexerName;
         p_hex_mode=langOptions.HexMode;

         if ( ! read_format_line() ) {
            if ( langOptions.szTabs!='' ) p_tabs=langOptions.szTabs;
            _str margins=langOptions.LeftMargin' 'langOptions.RightMargin' 'langOptions.NewParagraphMargin;
            if ( margins!='' ) p_margins=margins;

            p_word_wrap_style=langOptions.WordWrapStyle;
            p_indent_with_tabs=langOptions.IndentWithTabs;

            int show_tabsnl_flags=langOptions.ShowTabs;
            if ( keys=="vi-keys" ) {
               //show_tabsnl_flags=0;
               _str _show_tabsnl=__ex_set_list();
               if ( _show_tabsnl!="" && _show_tabsnl>0 ) {
                  show_tabsnl_flags=SHOWSPECIALCHARS_TABS|SHOWSPECIALCHARS_NLCHARS;
               }
            }
            p_ShowSpecialChars |= show_tabsnl_flags;
            p_show_tabs=langOptions.ShowTabs;
            p_indent_style=langOptions.IndentStyle;
            p_word_chars=langOptions.szWordChars;

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
         if (langOptions.TruncateLength>=0) {
            p_TruncateLength=langOptions.TruncateLength;
         } else {
            len=p_MaxLineLength-8;
            if (len>=2) {
               p_TruncateLength=len;
            }
         }

         p_BoundsStart=langOptions.BoundsStart;
         p_BoundsEnd=langOptions.BoundsEnd;
         if (langOptions.AutoCaps==CM_CAPS_AUTO) {
            p_caps=_GetCaps()!=0;
         } else {
            p_caps=langOptions.AutoCaps!=0;
         }
         if (index_callable(find_index('ispf_adjust_lc_bounds',PROC_TYPE))) {
            ispf_adjust_lc_bounds();
         }

         // keyboard callbacks are instantiated in specific order here
         _kbd_remove_callback(-1);  // clear all registered callbacks
         setOvertypeMarkerCallbacks();
         setEventUICallbacks();
         setAutoBracketCallback(lang);
      }
      if (map_xml_files && _LanguageInheritsFrom('xml') && substr(langOptions.szLexerName,1,3)=='XML') {
         _mapxml_init_file();
      }

      if (map_xml_files && _LanguageInheritsFrom('html') && substr(langOptions.szLexerName,1,4)=='HTML') {
         _mapjsp_init_file(p_window_id);
      }
      // Call TextChange callbacks.  This updates the color coding and forces long lines
      // to wrap.  Need this here for auto restore and it is probably best to wrap long lines
      // right after opening a file.
      _updateTextChange();

      boolean in_process=(langOptions.szEventTableName=="process-keys");
      boolean in_fileman=(langOptions.szEventTableName=="fileman-keys");
      boolean in_grep=(langOptions.szEventTableName=="grep-keys");
      _str vi_mode='';
      int vi_idx=find_index('vi-get-vi-mode',COMMAND_TYPE|PROC_TYPE);
      if ( vi_idx && index_callable(vi_idx) && keys=="vi-keys" && !in_process && !in_fileman && !in_grep ) {
         vi_mode=upcase(strip(vi_get_vi_mode()));
         if ( vi_mode=="C" ) {
            // Don't switch out of command mode!
            index=find_index('vi-command-keys',EVENTTAB_TYPE);
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
            index=find_index('vi-visual-keys',EVENTTAB_TYPE);
            if ( !index ) {
               message('Could not find event-table: "vi-visual-keys".  Type any key');
               get_event();
            }
         } else {
            if (!extensionSupported) {
               index=0;
            } else {
               index=find_index(langOptions.szEventTableName,EVENTTAB_TYPE);
            }
         }
      } else {
         if (!extensionSupported) {
            index=0;
         } else {
            index=find_index(langOptions.szEventTableName,EVENTTAB_TYPE);
         }
      }
      if ( index ) {
         p_mode_eventtab=index;
      } else {
         p_mode_eventtab=_default_keys;
      }
   }

   if ( !bypass_buffer_setup || force_select_mode_cb ) {
      //p_CallbackBufSetLineColor=0;
      _CallbackSelectMode(p_window_id,lang);
   }

   // hack to force "binary" mode into hex mode
   if (lang == "binary") {
      p_hex_mode=HM_HEX_OFF;
      hex();

      p_newline = "\n"; // force consistent line endings for binary mode
   }

   if ( !setup_index ) {  // No setup for the file extension?
      boolean autoSelectLanguage=p_AutoSelectLanguage;
      fundamental_mode();
      p_AutoSelectLanguage=autoSelectLanguage;
   }
   if (def_use_390_display_translations) {
      if (g390DisplayTranslationTable=='') {
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
void select_edit_mode(_str lang='',
                      boolean bypass_buffer_setup=false,
                      boolean map_xml_files=false)
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
   if (def_keys == 'ispf-keys') {
      // in ISPF mode, we don't want a prefix area narrower than the default...
      defLNL := _default_option(VSOPTION_LINE_NUMBERS_LEN);
      if (lnl < defLNL) lnl = defLNL;

      if (flags & LNF_AUTOMATIC) flags &= ~LNF_AUTOMATIC;
   }
}

static void Set390DisplayTranslationTable(_str &table)
{
   table='';
   int i;
   for (i=0;i<256;++i) {
      _str ch=_chr(i);
      if (i==94) {
         ch=_chr(172);
      }
      table=table:+ch;
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
   _SetEditorLanguage('fundamental');
}
/**
 * Switches to binary mode key bindings, and switches to hex mode.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void binary_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _SetEditorLanguage('binary');
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
      if ( _expand_tabsc(1,p_col-1)=='' && _expand_tabsc()!='') {
         first_non_blank();
      }
      split_insert_line();
      typeless col1,col2;
      if ( arg(2)!='' ) {
         col1=arg(2);
         col2=p_col;
      } else {
         col2=p_col;
         col1=p_col+syntax_indent;
      }
      _str result=_expand_tabsc(col2,-1,'S');
      if ( result:=='' && !LanguageSettings.getInsertRealIndent(p_LangId)) {
         // if our line is empty, then we just insert a blank line
         result='';
      } else {
         result = indent_string(col1-1):+result;
      }
      replace_line(result);
      p_col=col1;
   } else if ( name=='maybe-split-insert-line' && ! _insert_state() ) {
      maybe_split_insert_line();
   } else {
      nosplit_insert_line();
      if ( arg(2)!='' ) {
         p_col=arg(2);
      } else {
         p_col=p_col+syntax_indent;
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
   message(nls('File contains %s lines',p_Noflines));
}
/**
 * Extension speicific callback for process buffer to
 * insert argument completions for files / directories
 * visible in the current directory of the process buffer.
 */
void _process_autocomplete_get_arguments(typeless &words)
{
   if (!_isEditorCtl() || p_window_state=='I') {
      return;
   }
   process_tab(true,words);
}

int _process_autocomplete_get_prefix(_str &word,int &word_start_col=0,_str &complete_arg=null,int &start_word_col=0)
{
   boolean args_to_command=true;
   boolean return_val=false;
   _str line='';
   int col=1;
   line=_expand_tabsc();
   col=p_col;

   _str temp_line=line;

   _str name_prefix='';
   int match_flags=FILE_CASE_MATCH;
   _str completion_info="f:"(FILE_CASE_MATCH)"*";

   // IF we are selecting files
   // For compatibility with bash throw in '='.  This is so that
   //     ./configure --prefix=/gtk<Tab>
   // works just like the bash shell.  Not sure we = was added.  We
   // may have to add back slash support so a\=b works for a file
   // or directory named "a=b".
   _str alternate_temp_line=translate(temp_line,"   ","=>|<");
   // Translate redirection characters to space
   temp_line=alternate_temp_line;

   // IF the current and previous characters are space
   if (col>1 && substr(temp_line,col-1,2,'*'):=='  ') {
      // Split the line so we insert a word here instead of replacing
      // the next word.
      temp_line=substr(temp_line,1,col);
   }

   /* if the current character is a space and the previous character is not. */
   /* Try to expand the current argument on the command line. */
   int arg_number= _get_arg_number(temp_line,col,word,start_word_col,args_to_command,completion_info);
   complete_arg=word;
   word_start_col=start_word_col;
   if (substr(word,1,1)=='"') {
      word=substr(word,2);
      ++word_start_col;
   }
   _str name=_strip_filename(word,'p');
   word_start_col+=length(word)-length(name);
   word=name;
   //say('get_prefix: word='word' autocomp_col='col' start_col='start_word_col);
   return(0);
}

void _autocomplete_process(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,boolean onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol)
{
   int autocomplete_start_col=0;
   _str word='';
   _str complete_arg='';
   int start_word_col;
   _process_autocomplete_get_prefix(word,autocomplete_start_col,complete_arg,start_word_col);

   removeStartCol=start_word_col;
   _str path=_strip_filename(strip(complete_arg,'L','"'),'n');
   p_col-=length(complete_arg);
   boolean hadQuote=get_text()=='';
   _delete_text(length(complete_arg));
   if (pos(' ',path:+insertWord)) {
      _insert_text('"'path:+insertWord);
      if (!hadQuote) {
         removeLen=1;
      }
   } else {
      removeLen=0;
      _insert_text(path:+insertWord);
   }
}

/**
 * Handle the TAB key in the process buffer.  Tab will invoke the
 * auto complete system if it is not already active in order to list
 * file completions.
 *
 * @param autoCompleteAlreadyRunning    Is auto-complete already active?
 * @param autoCompleteWords             List of completions to add to
 */
_command void process_tab(_str autoCompleteAlreadyRunning='', typeless &autoCompleteWords=null) name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   //bsay('process_tab: running'autoCompleteAlreadyRunning);
   if ( !command_state() && p_window_state:!='I') {
      int col;
      if ( _process_info('c') ) {
         col=_process_info('c');
      } else {
         col=1;
      }
      if (p_line!=p_Noflines ||
          p_col<col
         ) {
         if (autoCompleteAlreadyRunning!=true) {
            call_root_key(last_event());
            return;
         }
      } else {
         if (autoCompleteAlreadyRunning!=true) {
            autocomplete();
            return;
         }
      }
      _str cmd=_expand_tabsc(col,-1,'S');
      _str cur;
      parse cmd with cur .;
      boolean do_files=true;
      if (file_eq('cd',cur) || file_eq('rmdir',cur)) {
         do_files=false;
      }
      // at this point, doAutoComplete will always be true
      boolean doAutoComplete= (autoCompleteAlreadyRunning==true);
      if (do_files) {
         maybe_list_matches("f:"(FILE_CASE_MATCH)"*" /*MULTI_FILE_ARG*/,'',true,true,true,'path_search:'(FILE_CASE_MATCH|REMOVE_DUPS_MATCH)"*",doAutoComplete,autoCompleteWords);
      } else {
         maybe_list_matches("dir:"(FILE_CASE_MATCH)"*" /*MULTI_FILE_ARG*/,'',true,true,true,'path_search:'(FILE_CASE_MATCH|REMOVE_DUPS_MATCH)"*",doAutoComplete,autoCompleteWords);
      }
      return;
   }
   call_root_key(last_event());

}
/**
 * New binding of ENTER key when in process mode.  When invoked
 * while the cursor is on the last line of the build window, a
 * blank line is inserted after the current line and the contents of the
 * current line after the "read point" is inserted in the ".process-
 * command" retrieve buffer for latter use by the <b>process_up</b> or
 * <b>process_down</b> command.  Otherwise the fundamental mode
 * ENTER key binding is executed.  Process output is inserted at the
 * character before the "read point".
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void process_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if ( !command_state() && p_window_state:!='I') {
      if (!(_process_info('b') && p_line==p_Noflines) ) {
         if (select_active2() && !_end_select_compare() && !_begin_select_compare()) {
            _str command='';
            int first_col,last_col,buf_id;
            _get_selinfo(first_col,last_col,buf_id);
            if (_select_type('','I')) ++last_col;
            if (_select_type()=='LINE') {
               command=_expand_tabsc();
            } else {
               command=_expand_tabsc(first_col,last_col-first_col);
            }
            _deselect();
            concur_command(command);
            return;
         }
         call_root_key(last_event());
         return;
      }
      int orig_view_id=p_window_id;
      if ( def_auto_reset ) {
         reset_next_error('','',0);
         /* clear_message */
      }
      p_window_id=orig_view_id;
      int col;
      if ( _process_info('c') ) {
         col=_process_info('c');
      } else {
         col=1;
      }
      _str cmd=_expand_tabsc(col,-1,'S');
      p_col=col;
      _delete_text(-1);

      if (_NeedVslickErrorInfo2(cmd)) {
         _insert_text(_VslickErrorInfo():+"\n"cmd"\n");
      }else{
         _insert_text(cmd"\n");
      }
      _str cur,temp;
      parse cmd with cur temp;
      if (file_eq('cd',cur)) {
         /*
           Minor bug:  The dos "cd" command does not change the active drive
              when a different drive is specified than the current drive.  The "vs" cd
              command changes the active drive.
           Minor bug:  The dos "cd" command supports multiple commands on one line.  The "vs"
              cd commands does not.
         */
#if __UNIX__
         temp=_unix_expansion(temp);
#endif
         cd('-p -a 'temp);
      }

      insert_retrieve((int)process_retrieve_id,process_first_retrieve,cmd);

      // If the command shell has exited, the close the build window
      if (def_close_build_window_on_exit) {
         if (_process_info('x') || !_process_info('r')) {
            quit();
         }
      }

      return;
   }
   call_root_key(last_event());

}
/**
 * New binding of HOME key when in process mode.  When invoked
 * while the cursor is on the last line of the build window, the
 * cursor is moved to column one or the "read point" column if the cursor
 * is on the line containing the "read point".  Otherwise the fundamental
 * mode HOME key binding is executed.  Process output is inserted at
 * the character before the "read point".
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void process_begin_line() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      _begin_line();
      return;
   }
   if ( _process_info('c') && _process_info('c')<=p_col ) {
      p_col=_process_info('c');
      if ( p_left_edge && p_col<p_char_width-2 ) {
         set_scroll_pos(0,p_cursor_y);
      }
      return;
   }
   call_root_key(last_event());

}
/**
 * New binding of UP key when in process mode.  When invoked while
 * the cursor is on the last line of the build window, the
 * previous command is retrieved from the ".process" buffer.
 * Otherwise the fundamental mode UP key binding is executed.
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void process_up() name_info(','VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if ( ! command_state() && _process_info('b') && p_line:==p_Noflines && name_name(prev_index()):!='root-keydef' ) {
      int col;
      if ( _process_info('c') ) {
         col=_process_info('c');
      } else {
         col=1;
      }
      _str line=_expand_tabsc(1,col-1,'S'):+
                  pretrieve_prev((int)process_retrieve_id,process_first_retrieve);
      replace_line(line);
      set_scroll_pos(0,p_cursor_y);
      _end_line();
      return;
   }
   call_root_key(last_event());

}
/**
 * New binding of DOWN key when in process mode.  When invoked
 * while the cursor is on the last line of the build window, the
 * next command is retrieved from the "process-buffer".  Otherwise the
 * fundamental mode key DOWN key binding is executed.
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void process_down() name_info(','VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if ( ! command_state() && _process_info('b') && p_line:==p_Noflines && name_name(prev_index()):!='root-keydef' ) {
      int col;
      if ( _process_info('c') ) {
         col=_process_info('c');
      } else {
         col=1;
      }
      _str line=_expand_tabsc(1,col-1,'S'):+
                  pretrieve_next((int)process_retrieve_id,process_first_retrieve);
      replace_line(line);
      set_scroll_pos(0,p_cursor_y);
      _end_line();
      return;
   }
   call_root_key(last_event());

}
/**
 * New binding of BACKSPACE key when in process mode.  When
 * invoked while the cursor is on the last line of the build window,
 * deletes character to the left of the cursor unless cursor is in
 * column 1 or at "read point".  Otherwise the fundamental mode
 * BACKSPACE key binding is executed.  Process output is inserted at
 * the character before the "read point".
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void process_rubout() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   // IF running UNIX pseudo TTY and entering password (text hidden) at current cursor position
   if (! command_state() && _process_info('h')) {
      // send backspace character
      _process_info('k');
      return;
   }
   if ( ! command_state() && _process_info('b') &&
        (_process_info('c')==p_col ||
         (! _process_info('c') && p_line:==p_Noflines && p_col==1)
        )
      ) {
      return;
   }
   call_root_key(last_event());

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
   _str command_op_wid='';
   if ( command_state() ) {
      _str line;
      int begin_col;
      int col;
      get_command(line,begin_col,col);
      if( p_object!=OI_COMBO_BOX && p_Password ) {
         line=substr('',1,length(line),'*');
      }
      command_op_wid=p_window_id;
      activate_window(VSWID_RETRIEVE);
      bottom();
      insert_line(line);p_col=col;
      _orig_mark=_duplicate_selection('');
      if ( _command_mark=='' ) {
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
         if ( _command_mark!='' ) {
            p_col=begin_col;
            _select_char('','cn');
            p_col=col;
            _select_char('','cn');
         }
      }
   }
   _command_op_list='.'command_op_wid' '_command_op_list;

}
void retrieve_command_results()
{
   typeless command_op_wid;
   parse _command_op_list with command_op_wid _command_op_list;
   command_op_wid=strip(command_op_wid,'B','.');
   if ( command_op_wid!='' ) {
      _command_mark=_duplicate_selection('');
      int begin_col=p_col;
      int col=p_col;
      int buf_id;
      get_line(auto line);
      if ( _select_type()!='' ) {
         if ( _select_type()=='LINE' ) {
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
      if ( _orig_mark!='' ) {
         _show_selection(_orig_mark);
      }
      p_window_id=command_op_wid;
      if (line!=p_text ) {
         if( p_object!=OI_COMBO_BOX && p_Password ) {
            if( verify(line,'*') ) {
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

boolean parseoption(var cmdline,_str optionletter)
{
   int i=pos('-':+upcase(optionletter),upcase(cmdline));
   if ( ! i ) {
      i=pos('+':+upcase(optionletter),upcase(cmdline));
   }
   if ( i && substr(cmdline,i+length(optionletter)+1,1)=='' && (i==1 || substr(cmdline,i-1,1)=='') ) {
      cmdline=substr(cmdline,1,i-1):+substr(cmdline,i+length(optionletter)+1);
      return(1);
   } else {
      return(0);
   }
}
/**
 * Loads color coding lexer definition file specified.  If <i>filename</i> is
 * not specified and the current buffer has a ".vlx" extension, it is loaded.
 * Otherwise a Standard Open File dialog box is displayed which allows you to
 * select a lexer definition file to load.  See <b>Color Coding</b> for information
 * on syntax of lexer definitions.
 *
 * @return  Returns 0 if successful.
 *
 * @see color_toggle
 * @see color_modified_toggle
 *
 * @categories File_Functions
 */
_command _str cload(...) name_info(FILE_ARG','VSARG2_CMDLINE)
{
   int was_recording=_macro();
   _str filename=arg(1);
   int wid=p_window_id;
   p_window_id=_mdi.p_child;
   _str default_buf_name=(_no_child_windows())?'':p_buf_name;
   if (filename=='') {
      filename=default_buf_name;
   }
   if ( filename=='<' || (filename=='' && _no_child_windows()) ||
        !(p_HasBuffer && file_eq('.'_get_extension(filename),'.vlx'))
      ) {
      filename=_OpenDialog('-modal',
                           'Open Color Lexer File', '*.vlx',
                           "Color Lexer (*.vlx),All Files "ALLFILES_RE")",
                           OFN_FILEMUSTEXIST,
                           'vlx',      // Default extensions
                           '',         // Initial filename
                           '',         // Initial directory
                           'vlx'       // Retrieve name
                          );
      if (filename=='') {
         p_window_id=wid;
         return(COMMAND_CANCELLED_RC);
      }
   }
   int status;
   if (filename=='' || (p_HasBuffer && file_eq(p_buf_name,absolute(filename)))) {
      if ( p_modify ) {
         status=save();
         if ( status ) {
            p_window_id=wid;
            return(status);
         }
      }
      filename=default_buf_name;
   }
   _macro('m',was_recording);
   _macro_delete_line();
   filename=strip(filename,'b','"');
   _macro_call('_clex_load',filename);
   status=_clex_load(filename);
   if (status) {
      _message_box(nls("Unable to load color lexer file '%s'",filename)"\n\n"get_message(status));
      p_window_id=wid;
      return(status);
   }

   filename=_strip_filename(filename,'p');
   _str string='(^|\'PATHSEP')':+_escape_re_chars(filename)'($|\'PATHSEP')';
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
_command void line_numbers_show_colon(_str showColon='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   typeless number=0;
   showColon=prompt(showColon,'',number2yesno(_default_option(VSOPTION_LCNOCOLON)));
   if ( setyesno(number,showColon) ) {
      message('Invalid option');
      return;
   }
   _default_option(VSOPTION_LCNOCOLON, !number);
   p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS;
   _config_modify_flags(CFGMODIFY_OPTION);
}

/**
 * Determines the number of characters to display for line numbers,
 * including the trailing colon.
 * @categories Miscellaneous_Functions
 * @see view_line_numbers_toggle
 * @see line_numbers_show_colon
 */
_command void line_numbers_set_width(_str numChars='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   numChars=prompt(numChars,'',_default_option(VSOPTION_LINE_NUMBERS_LEN));
   if (!isuinteger(numChars)) {
      message('Invalid argument');
      return;
   }
   _default_option(VSOPTION_LINE_NUMBERS_LEN, numChars);
   p_line_numbers_len = (int) numChars;
   p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS;
   _config_modify_flags(CFGMODIFY_OPTION);
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
void _clex_error(_str params)
{
   _str filename;
   typeless clex_status;
   _str section;
   _str name;
   _str value;
   parse params with filename "\0" clex_status section ']' name'='value ;
   //message 'fn='filename' clex_status='clex_status' section='section' name='name' value='value

   switch (clex_status) {
   case CLEX_NOT_ENOUGH_MEMORY_RC:
      _message_box(nls('Unable to initialize color lexer.')'  'get_message(clex_status));
      return;
   }
   int find_section_only=0;
   switch (clex_status) {
   case CLEX_IDCHARS_MUST_BE_DEFINED_FIRST_RC:
      find_section_only=1;
   }
   int status=edit(maybe_quote_filename(filename));
   if (status) {
      if (status==NEW_FILE_RC) {
         quit(false);
      }
      _message_box(nls("Unable to initialize color lexer.")"  "get_message(clex_status)nls("\n\nUnable to open file '%s'.",filename)"  "get_message(status));
      return;
   }
   // Find this section
   /* Search for the Environment section */
   top();
   status=search('^[ \t]*\[[ \t]*'section'[ \t]*\]','rhi@');
   if (status) {
      _message_box(nls("Unable to initialize color lexer.\nUnable to find section '%s'.\n",section)get_message(clex_status));
      return;
   }
   if (find_section_only) {
      _message_box(nls("Error in lexer definition\n\n")get_message(clex_status));
      return;
   }

   // Find this name and value
   down();
   save_pos(auto p);
   _str name_re;
   _str line;
   if (value=='') {
      name_re=_escape_re_chars(name)'(=|$)';
   } else {
      name_re=_escape_re_chars(name)'=( *)'_escape_re_chars(value);
   }
   _str section_re='\[';
   status=search('^[ \t]*('name_re'|'section_re')','rhi@');
   value='';
   if (!status) {
      get_line(line);
      if (substr(strip(line),1,1)=='[') {
         status=1;
      }
   }
   if (status) {
      // name and value not found
      restore_pos(p);
      _message_box(nls("Unable to initialize color lexer.\nUnable to find line of error '%s'.\n",section)get_message(clex_status));
      return;
   }
   _message_box(nls("Error in lexer definition found\n\n")get_message(clex_status));
}
/**
 * Command to key in the underscore character.  This can be bound to a
 * key that is easier to type that underscore, for example Ctrl+U.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command keyin_underscore() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
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
_command keyin_space() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
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
_command keyin_enter() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   call_root_key(ENTER);
   last_event(ENTER);
}
//
// This function is global.  However, this function may be
// modified in the future making it incompatible with the
// the current implementation.
//

#define UNIX_ASM_LEXER_LIST 'SP=SPARC RS=PPC PP=PPC LI=Intel IN=INTEL SC=INTEL FR=INTEL UN=INTEL SG=MIPS DE=MIPS MI=MIPS AL=ALPHA NT=Intel WI=Intel HP=HP'

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
void _set_read_only(boolean ReadOnly,boolean TurnOn_set_by_user=true, boolean ChangeDiskAttrs=false, boolean ChangeDiskAttrsPrompt=true)
{
   boolean oldReadOnly = p_readonly_mode;
   if ( ReadOnly ) {
      p_readonly_mode=true;
   } else {
      if (_isdiffed(p_buf_id)) {
         _message_box(nls("Cannot change out of read only mode because file is being diffed."));
         return;
      }
      if (debug_is_readonly(p_buf_id)) {
         _message_box(nls("Cannot change out of read only mode because file is being debugged."));
         return;
      }
      p_readonly_mode=false;
      if (_DataSetIsFile(p_buf_name) && p_readonly_mode == oldReadOnly && oldReadOnly == true) {
         _str dstext = "Data set";
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
      if (attrs!='') {

#if __UNIX__
         boolean FileIsReadOnly = pos('w',attrs,1,'i')<=0;
#else
         boolean FileIsReadOnly = pos('r',attrs,1,'i')>0;
         // This file has NTFS security options set which make the file read only.
         // Won't be able to change read only attribute.
         if (!FileIsReadOnly && !_WinFileIsWritable(p_window_id)) {
            return;
         }
#endif
         _str result=IDYES;
         if (ChangeDiskAttrsPrompt) {
            msg := '';
#if __UNIX__
            msg='Do you want to update the user write permissions on disk for this file?';
#else
            if (FileIsReadOnly) {
               msg = 'Do you want to remove the read only attribute on disk for this file?';
            } else {
               msg = 'Do you want to set the read only attribute on disk for this file?';
            }
#endif
            if ((p_readonly_mode && !FileIsReadOnly) || (!p_readonly_mode && FileIsReadOnly)) {
               result=_message_box(msg,'',MB_YESNOCANCEL);
            }
         }
         if (result==IDYES) {
            if (!p_readonly_mode && FileIsReadOnly && ChangeDiskAttrsPrompt) {
               int ro_status = _readonly_error(0,true,false);
               if (ro_status == COMMAND_CANCELLED_RC) {
                  result = IDCANCEL;
               }
            } else {
#if __UNIX__
               int status=_chmod(((p_readonly_mode)?'u-w ':'u+w ')maybe_quote_filename(p_buf_name));
               if (status) {
                  _message_box('Unable to update user write permissions for this file');
               }
#else
               int status=_chmod(((p_readonly_mode)?'+r ':'-r ')maybe_quote_filename(p_buf_name));
               if (status) {
                  _message_box('Unable to update read only attribute for this file');
               }
#endif
            }
         }
         if (result==IDCANCEL) {
            p_readonly_mode = oldReadOnly;
         }
      }
   }
}

boolean def_rwprompt=true;
boolean def_rwchange=true;

/**
 * Toggles read only mode on/off.  While in read only mode, you will not
 * be able to modify the current buffer with a command which modifies
 * text.
 *
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
_command void read_only_mode_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   boolean old_readOnly = p_readonly_mode;
   _set_read_only(!p_readonly_mode,true,def_rwchange,def_rwprompt);
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
_command void read_only_mode() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   boolean old_readOnly = p_readonly_mode;
   if (arg(1)=='') {
      p_readonly_mode=true;
   } else {
      _set_read_only(arg(1)!='0');
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
   popup_message('The key you pressed is not allowed in Read Only mode.');
   //popup_message(nls('The key you pressed is not allowed in %s mode.',p_mode_name))
}
int _isdiffed(int buf_id)
{
   int i,last=_last_window_id();
   for (i=1;i<=last;++i) {
      if (!_iswindow_valid(i) ) continue;
      if ((i.p_name=='_ctlfile1' || i.p_name=='_ctlfile2') &&
          (i.p_parent) && (i.p_parent.p_name=='_diff_form')) {
         if (buf_id==i.p_buf_id) {
            if (!i.p_edit && i.p_visible) {//Form not edited, and is visible 10:31am 4/8/1996
               //I hope this does away with the intermittent "You cannot close because
               //file is diffed" messages that we have gotten
               return(1);
            }
         }else{
            _nocheck _control _ctlfile1;
            DIFF_MISC_INFO misc=i.p_parent._GetDialogInfo(DIFFEDIT_CONST_MISC_INFO,i.p_parent._ctlfile1);
            if (misc.WholeFileBufId1==buf_id ||
                misc.WholeFileBufId2==buf_id) {
               return(1);
            }
         }
      }
   }
   return(0);
}

#define LANGEXT_DAT \
   " algorithm array bitset cassert cctype cerrno cfloat" \
   " ciso646 climits clocale cmath complex" \
   " csetjmp csignal cstdarg cstddef cstdio " \
   " cstdlib cstring ctime cwchar cwctype" \
   " deque exception fstream functional hash_map hash_set " \
   " iomanip ios iosfwd iostream istream iterator" \
   " limits list locale map memory new numeric ostream pthread_alloc" \
   " queue random regex rope set slist sstream stack stdexcept" \
   " streambuf string strstream typeinfo type_traits tuple" \
   " unordered_map unordered_set utility valarray vector" \
   " xcomplex xfunctional xhash xios xiosbase xlocale xlocinfo xlocmon" \
   " xlocnum xloctime xmemory xrefwrap xstddef xstring"\
   " xtree xtr1common xutility "

_str def_user_langext_files='';

_str _get_langext_files()
{
   // LANGEXT_DAT ends with a space so there is no need to add
   // an extra one before def_user_langext_files
   return(LANGEXT_DAT:+def_user_langext_files:+' ');
}

static _str make_space_delimit_string(_str (&str_array)[])
{
   _str result='';

   int index;
   for (index=0;index<str_array._length();++index) {
      if (result:!='') {
         strappend(result,' ');
      }
      strappend(result,str_array[index]);
   }

   return result;
}

static void make_array_from_space_delimit_string(_str space_string, _str (&str_array)[])
{
   _str item;
   space_string=strip(space_string);

   while (space_string:!='') {
      parse space_string with item space_string;
      space_string=strip(space_string);

      str_array[str_array._length()]=item;
   }
}

static _str edit_user_langext_callback()
{
   // prompt for name, check for duplicate, and add to list
   _str newName="";
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
      return '';
   }

   return _param1;
}

_command void edit_user_langext_files()
{
   _str str_array[];
   make_array_from_space_delimit_string(def_user_langext_files,str_array);

   _str result=show('-modal _list_editor_form',
                    'Extensionless C++ Files',
                    'Extensionless C++ Files:',
                    str_array,
                    edit_user_langext_callback);

   if (result:!='') {
      def_user_langext_files=make_space_delimit_string(_param1);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
}

_str concat_path_and_file(_str path, _str filename)
{
   _maybe_append_filesep(path);
   return path:+filename;
}
void _maybe_append(_str& line, _str ch)
{
   if (line != "" && last_char(line) != ch) {
      line = line :+ ch;
   }
}
void _maybe_prepend(_str& line, _str text)
{
   if (line != "" && substr(line, 1, length(text)) != text) {
      line = text :+ line;
   }
}
void _maybe_strip_filesep(_str &path)
{
   if (path!="" && last_char(path) == FILESEP) {
      path=substr(path,1,length(path)-1);
   }
}

void _maybe_strip(_str &path,_str ch)
{
   if (path!="" && last_char(path) == ch) {
      path=substr(path,1,length(path)-1);
   }
}

static void _activate_selmode_view()
{
   int *pview_id = _GetDialogInfoHtPtr(SELECT_MODE_VIEW_ID, _mdi);
   if (pview_id != null && _iswindow_valid(*pview_id)) {
      activate_window(*pview_id);
      return;
   }

   _str filename=_ConfigPath():+'selmode.ini';
   int orig_view_id;
   int selmode_view_id;
   int status=_open_temp_view(filename, selmode_view_id, orig_view_id);
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
      buf_name=_strip_filename(buf_name,'N');
   }
}
static int _find_selected_mode(_str buf_name,boolean onlyLookForMember=false)
{
   _activate_selmode_view();
   top();
   int status;
   save_search(auto a,auto b,auto c,auto d);
   if (_DataSetIsFile(buf_name)) {
      status=search("\t"_escape_re_chars(buf_name)'$',
                    '@rhi');
   } else {
      status=search("\t"_escape_re_chars(buf_name)'$',
                    '@rh'_fpos_case);
   }
   if (status && _DataSetIsMember(buf_name) && !onlyLookForMember) {
      _just_pds(buf_name);
      status=search("\t"_escape_re_chars(buf_name)'$',
                    '@rhi');
   }
   restore_search(a,b,c,d);
   return(status);
}

int _DataSetQAutoFileType()
{
   _str option=get_env("VSLICK390AUTOFILETYPE");
   if (length(option)!=1 || !isdigit(option)) {
      return(1);
   }
   return(_asc(option)-_asc('0'));
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
_str _getFileTypeFromQualifier(_str buf_name,_str dsname='')
{
   if (dsname=='') {
      if (buf_name=='' || !_DataSetIsFile(buf_name)) return('');
      dsname=_DataSetNameOnly(buf_name);
   }
   _str dataset_type = lowcase(_get_extension(dsname, true));
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
   if (buf_name=='' /*|| !_DataSetIsFile(buf_name) could be ftp p_DocumentName*/
       ) return('');
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
      if (line!='') {
         break;
      }
      sourceData=rest;
   }
   if (isinteger(substr(line,73,8)) && length(line)==80) {
      line=substr(line,1,72);
   }
   _str firstword,secondword;
   parse line with firstword rest '[\r\n]','r';
   if (substr(line,1,1)=='*' && lowcase(firstword)==lowcase('*process')) {
      return('pl1');
   }
   if (substr(line,1,1)=='*') {
      return('asm390');
   }
   _str cobolword1, cobolword2;
   parse lowcase(substr(line,7)) with cobolword1 cobolword2 .;
   if ((isinteger(substr(line,1,6)) &&  cobolword1=='cbl') ||
       lowcase(firstword)=='cbl') {
      return('cob');
   }
   // following added by Allen Richardson 4/14/2008 for Enterprise COBOL
   if ((isinteger(substr(line,1,6)) &&  cobolword1=='process') ||
       lowcase(firstword)=='process') {
      return('cob');
   }
   if (cobolword2=='division' || cobolword2=='division.') {
      if ((isinteger(substr(line,1,6)) &&  cobolword1=='identification') ||
          lowcase(cobolword1)=='identification') {
         return('cob');
      }
      if ((isinteger(substr(line,1,6)) &&  cobolword1=='id') ||
          lowcase(cobolword1)=='id') {
         return('cob');
      }
   }
   if ((substr(line,1,6)=='' || isinteger(substr(line,1,6))) &&
       (substr(line,7,1)=='*' || substr(line,7,1)=='/') ) {
      return('cob');
   }
   if (substr(firstword,1,2)=='/*') {
      if (pos('rexx',line,1,'i')) {
         return('rexx');
      }
      switch (dataset_type) {
      case '.pascal':
         return('pas');
      case '.c':
         return('c');
      case '.rexx':
      case '.exec':
         return('rexx');
      }
      return('pl1');
   }
   if (substr(firstword,1,2)=='(*') {
      return('pas');
   }
   if (substr(firstword,1,1)=='%') {
      return('pl1');
   }
   if (substr(firstword,1,1)=='#') {
      return('c');
   }
   if(substr(line,1,2)=='//' ){
      // JCL or C
      if (substr(line,3,1)=='*') {
         return('jcl');
      }
      if (rest!='' && (dataset_type=='.proclib' || dataset_type=='.cntl' || dataset_type=='.jcl' || substr(dataset_type,1,7)=='.ispctl')) {
         return('jcl');
      }
      parse rest with secondword .;
      secondword=upcase(secondword);
      if (pos(' 'secondword' ',' JOB DD PROC EXEC MSG COMMAND IF ELSE INCLUDE OUTPUT SET XMIT ')) {
         return('jcl');
      }
      return('c');
   }
   if (substr(line,1,1)!='') {
      parse line with . secondword .;
   } else {
      secondword=firstword;
   }
   secondword=upcase(secondword);
   if (pos(' 'secondword' ',' CSECT DSECT MACRO TITLE START COPY EQU ')) {
      return('asm390');
   }
   return('');
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
   int status=0;
   if (option=='M') {
      status=_find_selected_mode(buf_name);
      // IF use automatic language determination AND
      //    don't have to worry about PDS member file type
      //    being different from the PDS file type
      if (ext=='') {
         if (!status) {
            _delete_line();
            _save_file('+o');
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
   _str data=ext"\t"buf_name;
   if (!status) {
      replace_line(data);
      _save_file('+o');
      activate_window(orig_view_id);
      return;
   }
   top();up();
   insert_line(data);
   _save_file('+o');
   activate_window(orig_view_id);
}
_str _get_selected_mode(_str buf_name,boolean onlyLookForMember=false)
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
   _str file_name = _strip_filename(wid.p_buf_name, 'P');
   if ((!wid.p_AutoSelectLanguage || !wid._ftpDataSetIsFile()) && 
       (!isEclipsePlugin() || (_get_extension(wid.p_buf_name) != '' &&
         _Ext2LangId(_get_extension(wid.p_buf_name)) != '') || 
        !def_eclipse_check_ext_mode || wid.p_LangId != 'fundamental')
       ) {
      return;
   }
   //say('idle='_idle_time_elapsed());
   if (_idle_time_elapsed()<75 || (wid.p_ModifyFlags&MODIFYFLAG_AUTOEXT_UPDATED)) {
      return;
   }

   // we may not even want to set the type
   setType := _DataSetQAutoFileType();
   if (!setType) {
      return;
   }

   _str lang = wid._DataSetEditorLanguage(wid.p_buf_name,setType,'',true);
   if ( lang == '' ) {
      lang='fundamental';
   }
   //say('ext='ext);
   if ( wid.p_LangId != lang ) {
      //say('got here ext='ext);
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
                                   ,boolean currentObjectIsBuffer=false)
{
   // Check PDS extension first.
   _str temp_ext = "";
   _str dataset_type=null;
   if (AutoFileTypeOption > 0) {
      if (currentObjectIsBuffer) {
         temp_ext=_ftpGetFileTypeFromQualifier();
      } else {
         temp_ext=_getFileTypeFromQualifier(buf_name);
      }
      dataset_type=temp_ext;
      if (temp_ext!='') {
         // map the file extension to a language mode
         lang := _Ext2LangId(temp_ext);
         if ( lang != '' ) return lang;
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
      if (temp_ext!='') {
         // map the extension to a language mode
         lang := _Ext2LangId(temp_ext);
         if ( lang != '' ) return lang;
         // Return identity extension if there is no language mode.
         return temp_ext;
      }
   }
   return('');
}
void _ModifyTabSetup(_str lang,_str iwt,_str tabs)
{
   int setup_index=find_index('def-language-'lang,MISC_TYPE);
   if (!setup_index) {
      return;
   }
   _str before, orig_tabs, between, orig_indent_with_tabs, rest;
   parse name_info(setup_index) with before \
      'TABS=' orig_tabs ',' between 'IWT='orig_indent_with_tabs ',' rest;
   if (iwt=='') {
      iwt=orig_indent_with_tabs;
   }
   if (tabs=='') {
      tabs=orig_tabs;
   }
   set_name_info(setup_index,before'TABS='tabs','between'IWT='iwt','rest);
   _config_modify_flags(CFGMODIFY_DEFDATA);

   // changed a language option, so clear cache
   index := find_index("_ClearDefaultLanguageOptionsCache");
   if (index > 0) {
      call_index(index);
   }
}

void _ModifyTabSetupAll(_str fundamental_iwt,
                     _str other_iwt,_str other_tabs)
{

   // figure out which languages we don't want to set tabs for
   _str excludedLangIDs[];
   excludedLangIDs[0] = 'fundamental';
   excludedLangIDs[1] = 'process';
   excludedLangIDs[2] = 'tagdoc';
   excludedLangIDs[3] = 'fileman';
   excludedLangIDs[4] = 'e';
   excludedLangIDs[5] = 'masm';
   excludedLangIDs[6] = 'unixasm';
   excludedLangIDs[7] = 'java';
   excludedLangIDs[8] = 'bourneshell';
   excludedLangIDs[9] = 'csh';
   excludedLangIDs[10] = 'cob';
   excludedLangIDs[11] = 'mak';
   excludedLangIDs[12] = 'imakefile';
   excludedLangIDs[13] = 'py';
   excludedLangIDs[14] = 'asm390';

   exclusions := join(excludedLangIDs, ',');

   setOptionForAllLanguages('Tabs', other_tabs, exclusions);
   setOptionForAllLanguages('IndentWithTabs', other_iwt, exclusions);

   // fundamental is special
   _ModifyTabSetup("fundamental",fundamental_iwt,'');

   /*****START PROPRIOTARY FILE SETUP**********************************/
   _ModifyTabSetup("process",fundamental_iwt,'+8');
   /*****END PROPRIOTARY FILE SETUP**********************************/

  /*****START CUSTOM MODIFICATIONS**********************************/
  _ModifyTabSetup("masm",other_iwt,'' /* +8 */);
  _ModifyTabSetup("unixasm",other_iwt,'' /* +8 */);
  _ModifyTabSetup("java",other_iwt,'' /* +8 */); // SUN source looks better with +8
  _ModifyTabSetup("bourneshell",other_iwt,'' /* +8 */);  // UNIX origin
  _ModifyTabSetup("csh",other_iwt,'' /* +8 */);          // UNIX origin
  /*****END CUSTOM MODIFICATIONS**********************************/

  // some languages have beautifiers - we need to let them know we've made some changes
  // if we are doing this during the state file build, we don't want to bother trying
  index := find_index("update_all_current_profiles", PROC_TYPE);
  if (index_callable(index)) {
     call_index(true, false, false, index);
  }

}

void replace_def_data(_str name,_str info)
{
   // changed a language option, so clear cache
   index := find_index("_ClearDefaultLanguageOptionsCache");
   if (index > 0) {
      call_index(index);
   }

   index = find_index(name,MISC_TYPE);
   if (index) {
      set_name_info(index,info);
   } else {
      if (substr(name,1,13)=='def-language-' || substr(name,1,10)=='def-setup-') {
         parse name with 'def-' . '-' auto ext;
         if (index_callable(find_index("check_and_load_support",PROC_TYPE))) {
            check_and_load_support(ext,index);
         }
      }
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
 *                   pass 'true' if if the current object is an
 *                   editor control containing the file in question
 * @param setAutoSelectLanguage
 *                   if 'true' set {@link p_AutoSelectLanguage}
 *
 * @categories Miscellaneous_Functions
 * @deprecated Use {@link _Filename2LangId()}
 */
_str refer_ext(_str ext, _str file_name='',
               boolean currentObjectIsBuffer=false,
               boolean setAutoSelectLanguage=false)
{
   if (ext != '' && file_name=='') return _Ext2LangId(ext);
   return _Filename2LangId(/*ext,*/file_name/*,currentObjectIsBuffer,setAutoSelectLanguage*/);
}


static boolean in_expand_extension_alias;
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
   int i=eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(' '));
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
      _str widname = stranslate(wid.p_name, '-', '_');
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
_str make_line_number(int n,int num_digits,_str pad_char='0',boolean use_blanks=false)
{
   if (use_blanks) {
      return substr('',1,num_digits,' ');
   }
   _str n_str = n;
   return substr('',1,num_digits-length(n_str),pad_char):+n_str;
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
void renumber_lines(int start_col,int end_col,_str pad_char='0',
                    boolean use_blanks=false, boolean quiet=false)
{
   typeless p;
   _save_pos2(p);
   int orig_trunc=p_TruncateLength;
   p_TruncateLength=0;
   boolean may_have_lost_data=false;
   int i,n=p_RNoflines;
   int last_number=0;
   int num_digits=end_col-start_col+1;
   for (i=1; i<=n; i++) {
      p_RLine=i;
      _str line;get_line_raw(line);
      int rstart_col=text_col(line,start_col,'P');
      int rend_col=text_col(line,end_col,'P');
      int replace_increment=0;
      _str number_contents=substr(line,rstart_col,rend_col-rstart_col+1);
      if (number_contents=='') {
         replace_increment=100;
      } else if (pos('^0@{[0-9 ]*}$',number_contents,1,'r')) {
         _str text=substr(number_contents,pos('S0'),pos('0'));
         int line_number=0;
         if (isinteger(text)) {
            line_number=(int) text;
         }
         if (line_number <= last_number) {
            last_number=last_number-(last_number%100);
            replace_increment=100;
         } else {
            last_number=line_number;
         }
      } else {
         may_have_lost_data=true;
         replace_increment=100;
         last_number=last_number-(last_number%100);
      }
      if (replace_increment > 0 || use_blanks) {
         last_number+=replace_increment;
         _str line_prefix=substr(line,1,rstart_col-1);
         _str line_suffix=substr(line,rend_col+1);
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
   _str argname = '', command_name = '', args = '';
   int num = 0;
   while (command_string != '') {
      parse command_string with argname command_string;
      if (substr(argname, 1, 1) :== '-') {
         // This is a flag.
         argname = substr(argname, 2);
         if (!isinteger(argname)) {
            // The flag is not numerical.  Skip it.
            continue;
         }
         num = (int)argname;
      } else if (command_name == '') {
         // Get the command name.
         command_name = argname;
      } else {
         args = args' 'argname;
      }
   }

   while (!num) {
      _str numstr = '';
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
   int index = find_index(command_name, COMMAND_TYPE);
   if (!index || !index_callable(index)) {
      message("Command '"command_name"' not found");
      return;
   }
   int i = 0;
   for (i = 0; i < num; ++i) {
      execute(command_name' 'args);
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
_command void repeat_key(_str command_string='') name_info(COMMAND_ARG','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_string != '') {
      // Command name exists.  Probably invoked from the command line.
      _repeat_key_args(command_string);
      return;
   }

   _str event = '';

   // Get the number first.
   int num = 0;
   while (true) {
      num *= 10;
      event = get_event();
      if (event >= 0 && event <= 9) {
         num += (int)event;
         event = '';
         message("Repeats: ":+num);
      } else {
         num = num intdiv 10;
         break;
      }
   }

   if (!num) {
      return;
   }

   if (event == '') {
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
      renumber_lines(73,80,'0');
   }
   if (renumber_flags & VSRENUMBER_COBOL) {
      renumber_lines(1,6,'0');
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
      renumber_lines(73,80,'0',true);
   }
   if (renumber_flags & VSRENUMBER_COBOL) {
      renumber_lines(1,6,'0',true);
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
   if (cmdline=='') {
      p_caps=(p_caps)? 0:1;
      return;
   }
   boolean number;
   if(setonoff(number,cmdline)) return;
   p_caps=number;
}
void _LCUpdateOptions()
{
   if (!index_callable(find_index('_create_temp_view',PROC_TYPE))) {
      return;
   }
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   int first_buf_id=p_buf_id;

   inISPF := def_keys=='ispf-keys';
   int langSettings:[] = null;

   for (;;) {
      if (!(p_buf_flags&VSBUFFLAG_HIDDEN)) {
         if (_QReadOnly()) {
            if (_default_option(VSOPTION_LCREADONLY) && p_buf_name!='.process' && p_LangId!='fileman' && p_LangId!='grep') {
               p_LCBufFlags|=VSLCBUFFLAG_READWRITE;
            } else {
               p_LCBufFlags&= ~VSLCBUFFLAG_READWRITE;
            }
         } else {
            if (_default_option(VSOPTION_LCREADWRITE) && p_buf_name!='.process' && p_LangId!='fileman' && p_LangId!='grep') {
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
            if (!langSettings._indexin(lang'length')) {
               langSettings:[lang'flags'] = LanguageSettings.getLineNumbersFlags(p_LangId);
               langSettings:[lang'length'] = LanguageSettings.getLineNumbersLength(p_LangId);
            }
            if (langSettings._indexin(lang'length')) {
               flags := langSettings:[lang'flags'];
               lnl := langSettings:[lang'length'];
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
_command void cob_tab() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state()) {
      call_root_key(TAB);
      return;
   }
   if(_EmbeddedLanguageKey(last_event())) return;
   // For COBOL we want  05<TAB> to act just like 05<space>
   if (_LanguageInheritsFrom('cob')) {
      get_line(auto tline);
      if (p_TruncateLength) {
         tline=substr(tline,1,p_TruncateLength);
         tline=strip(tline,'T');
      }
      _str line=strip(tline,'T');
      if ( p_col==text_col(line)+1 ) {
         _str word=strip(tline,'L');
         if ( pos(' 'word'=',' 'def_cobol_levels' ') ) {
            typeless column=eq_name2value(word,def_cobol_levels);
            if ( isinteger(column) ) {
               replace_line(indent_string(column-1):+strip(tline)' ');
               _end_line();
            }
         }
      }
   }

   int orig_col=p_col;
   tab();

   int root_binding_index=eventtab_index(_default_keys,_default_keys,event2index(TAB));
   if (name_name(root_binding_index)=='move-text-tab') {
      int new_col=p_col;p_col=orig_col;
      if (p_indent_with_tabs) {
         _insert_text("\t");
      } else {
         _insert_text(substr('',1,new_col-orig_col));
      }
      p_col=new_col;
   }
}
_command void cob_backtab() name_info(','VSARG2_REQUIRES_EDITORCTL)
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
int copyFileTree(_str srcDir, _str dstDir, _str options='', boolean ignoreErrors=false, _str (&FilesCopied)[]=null)
{
   // Make sure source directory exists.
   _maybe_append_filesep(srcDir);
   if (!isdirectory(srcDir)) {
      return(FILE_NOT_FOUND_RC);
   }

   // Build a list of files in the source tree. The list includes both
   // the directories and files.
   _str fileList[];
   int fileCount = 0;
   _str filePath = file_match("+t "maybe_quote_filename(srcDir), 1);
   while (filePath != "") {
      // Skip the "." and ".." directory entries.
      if (last_char(filePath) == FILESEP) {
         _str tempPath = substr(filePath,1,length(filePath)-1);
         tempPath = _strip_filename(tempPath, 'P');
         if (tempPath == "." || tempPath == "..") {
            filePath = file_match("+t "maybe_quote_filename(srcDir), 0);
            continue;
         }
      }
      // Strip the source directory part.
      filePath = substr(filePath, length(srcDir) + 1);
      //say("   "filePath);
      fileList[fileCount] = filePath;
      fileCount++;
      filePath = file_match("+t "maybe_quote_filename(srcDir), 0);
   }

   // If the destination directory does not exist, create it.
   int status = 0;
   if (last_char(dstDir) != FILESEP) dstDir = dstDir :+ FILESEP;
   if (!isdirectory(dstDir)) {
      status = make_path(dstDir);
      if (status) return(status);
   }

   // Create the directories and copy the files.
   int i;
   _str destPath;
   _str fileMode = "";
   if (options == 'r') {
      fileMode = (__UNIX__) ? "u-w,g-w,o-w":"+R";
   } else if (options == 'w') {
      fileMode = (__UNIX__) ? "u+w,g-w,o-w":"-R";
   }
   for (i=0; i<fileCount; i++) {
      // Build the destination path.
      destPath = dstDir :+ fileList[i];
      if (last_char(destPath) == FILESEP) {
         // Create directory.
         if (!isdirectory(destPath)) {
            status = make_path(destPath);
         }
#if __UNIX__
         if (!status && options != '') {
            _chmod("u+r,u+w,u+x,g+r,g+x,o+r,o+x ":+maybe_quote_filename(destPath));
         }
#endif
      } else {
         // Copy the file.
         status = copy_file(srcDir:+fileList[i], destPath);
         FilesCopied[FilesCopied._length()]=destPath;
         if (!status && fileMode != "") {
            _chmod(fileMode:+" ":+maybe_quote_filename(destPath));
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

   _str BuildMenuCaption='&Build';
   _str DebugMenuCaption='&Debug';
   int pos1=-1;
   int pos2=-1;
   int i;
   int count=_menu_info(menu_handle);
   for (i=0;i<count;++i) {
      int mf_flags;
      _str caption;
      _menu_get_state(menu_handle,i,mf_flags,'P',caption);
      if (strieq(stranslate(BuildMenuCaption,'','&'),stranslate(caption,'','&'))) {
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

   int index=0;
   _str debug_command;
   if (_project_DebugCallbackName != '') {
      index=find_index('_'_project_DebugCallbackName'_ConfigNeedsDebugMenu',PROC_TYPE);
      if (index) {
         int Node=_ProjectGet_TargetNode(_ProjectHandle(ProjectFilename),'Debug');
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
   index=find_index('_default_debug_menu',oi2type(OI_MENU));
   if (!index) {
      _menu_info(menu_handle,'R');   // Redraw menu bar
      return;
   }
   int submenu_handle=_menu_insert_submenu(menu_handle,pos1+1,index,DebugMenuCaption,'ncw','help debug menu','Displays debug menu');
   //_menu_load(index);
   //_menu_insert(debug_menu_handle,-1,MF_SUBMENU,'Test');
   _menu_set_bindings(submenu_handle);
   _menu_info(menu_handle,'R');   // Redraw menu bar
   */

}

/**
 * This function returns a XMLCFG tree handle to the "options.xml" file.
 *
 * @return If successful, an XMLCFG tree handle to "options.xml" is returned.
 *         Otherwise a negative return code.  If the "options.xml" file does not exist, it is created.
 */
int _cfg_get_useroptions()
{
   int *phandle = _GetDialogInfoHtPtr(OPTIONS_XML_HANDLE, _mdi);
   if (phandle != null && *phandle>=0) {
      return *phandle;
   }

   int options_handle = 0;
   _str filename=_ConfigPath():+'options.xml';
   if (file_exists(filename)) {
      int status=0;
      options_handle = _xmlcfg_open(filename,status);
      if (options_handle < 0) {
         _message_box("Unable to open 'options.xml'\n\n"get_message(options_handle));
      }
   } else {
      options_handle = _xmlcfg_create(filename,VSENCODING_UTF8,0);
   }
   _SetDialogInfoHt(OPTIONS_XML_HANDLE, options_handle, _mdi);
   return(options_handle);
}

int _cfg_save_useroptions(boolean quiet = false)
{
   int options_handle = _cfg_get_useroptions();
   if (options_handle < 0) {
      return ERROR_WRITING_FILE_RC;;
   }
   int status=_xmlcfg_save(options_handle,-1,0);
   if (status && !quiet) {
      _message_box("Unable to write 'options.xml'\n\n"get_message(status));
   }
   return(status);
}

static _str _get_eurl()
{
   _str temp='h';temp=temp't';temp=temp't';temp=temp'p';temp=temp':';
   temp=temp'/';temp=temp'/';temp=temp'w';temp=temp'w';temp=temp'w';
   temp=temp'.';temp=temp's';temp=temp'l';temp=temp'i';temp=temp'c';
   temp=temp'k';temp=temp'e';temp=temp'd';temp=temp'i';temp=temp't';
   temp=temp'.';temp=temp'c';temp=temp'o';temp=temp'm';temp=temp'/';
   temp=temp'e';temp=temp'a';temp=temp's';temp=temp't';temp=temp'e';
   temp=temp'r';temp=temp'e';temp=temp'g';temp=temp'g';temp=temp'.';
   temp=temp'h';temp=temp't';temp=temp'm';temp=temp'l';
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
_command int duplicate_line() name_info(','VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
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
 * Convert language specific options information to the string
 * format which is stored in def-language-[lang].
 *
 * @example
 * <pre>
 * "MN=ModeName,TABS=[Tabs],...,SOW=SoftWrapOnWord"
 * </pre>
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
   _config_modify_flags(CFGMODIFY_DEFDATA);
}

/**
 * Create a default set of language specific options information
 * to the string format which is stored in def-language-[lang].
 *
 * @param ModeName   Language mode name 
 *  
 * @categories Miscellaneous_Functions
 */
_str _GetDefaultLanguageSetupInfo(_str ModeName)
{
   return('MN='ModeName',TABS=+4,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=N/A,LN=,CF=0,LNL=0,TL=0,BNDS=,');
}

/**
 * Configure the given language to use the default options.
 *
 * @param ModeName   Language mode name
 * @param lang       Optional language ID
 *                   (otherwise uses mode name)
 */
void _SetLanguageSetupDefaults(_str ModeName, _str lang='')
{
   info := _GetDefaultLanguageSetupInfo(ModeName);
   if (lang == '') {
      lang = _file_case(ModeName);
   }
   index := find_index('def-language-'lang, MISC_TYPE);
   _config_modify_flags(CFGMODIFY_DEFDATA);
   if (!index) {
      insert_name('def-language-'lang, MISC_TYPE, info);
      return;
   }
   set_name_info(index, info);

   // changed a language option, so clear cache
   index = find_index("_ClearDefaultLanguageOptionsCache");
   if (index > 0) {
      call_index(index);
   }
}

/**
 * @return Return the language mode name associated
 *         with the given extension.
 *
 * @see _Ext2LangId
 * @see _LangId2Modename
 *
 * @deprecated Use {@link _Ext2LangId()} or {@link _LangId2Modename()}
 */
_str _ExtGetModeName(_str extension)
{
   lang := _Ext2LangId(extension);
   if (lang=='') return '';
   return _LangId2Modename(lang);
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
   setup_index := LanguageSettings.getLanguageDefinitionOptions(lang, setup);

   return (setup_index ? 0 : 1);
}

void _SoftWrapUpdateAll(boolean SoftWrap,boolean SoftWrapOnWord)
{
   def_SoftWrap=SoftWrap;
   def_SoftWrapOnWord=SoftWrapOnWord;
   _SoftWrapSetAll(SoftWrap,SoftWrapOnWord);
   int i,last=_last_window_id();
   for (i=1;i<=last;++i) {
      if (_iswindow_valid(i) && i._isEditorCtl(false)){
         if (i.p_SoftWrap!=SoftWrap || i.p_SoftWrapOnWord!=SoftWrapOnWord
             ) {
            i.p_SoftWrap=SoftWrap;
            i.p_SoftWrapOnWord=SoftWrapOnWord;
         }
      }
   }
   _config_modify_flags(CFGMODIFY_OPTION);
}
void _SoftWrapSetAll(boolean SoftWrap,boolean SoftWrapOnWord)
{
   if (!index_callable(find_index('_SetLanguageOption',PROC_TYPE))) return;
   int index=name_match('def-language-',1,MISC_TYPE);
   for (;index;) {
      parse name_name(index) with 'def-language-'auto lang;
      _SetLanguageOption(lang, 'SW', SoftWrap);
      _SetLanguageOption(lang, 'SOW', SoftWrapOnWord);
      index=name_match('def-language-',0,MISC_TYPE);
   }
}

/**
 * Update the javadoc or doxygen comment for the current 
 * function or method, based on the signature.  If no comment 
 * exists for the function, then one is generated. 
 *  
 *  @categories Miscellaneous_Functions
 */
_command void update_doc_comment() name_info(','VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // get the function signature information
   // this call does not work for when you are on the javadoc of a function...would be nice
   // should validate first and last line
   int status = _parseCurrentFuncSignature(auto sigElements, auto first_line, auto last_line, auto func_line);
   if (status) {
      return;
   }
   // find the start column of the comment
   int start_col = find_comment_start_col(first_line);
   _save_pos2(auto p);
   _str mlcomment_start = '';
   _str slcomment_start = '';
   int blanks:[][];
   // extract the comment information from the existing comment for this function
   status =_GetCurrentCommentInfo(auto comment_flags,auto orig_comment, auto return_type, slcomment_start, blanks, 
      auto doxygen_comment_start);
   if (status) {
      _restore_pos2(p);
      return;
   } else if (slcomment_start == '') {
      goto_line(func_line);
      insert_blankline_above();
      javadoc_comment();
      return;
   }
   // check the flags for the start of the comment
   boolean isDoxygen = false;
   if ((comment_flags & VSCODEHELP_COMMENTFLAG_DOXYGEN) != 0) {
      mlcomment_start = doxygen_comment_start;
      isDoxygen = true;
   } else if (comment_flags & VSCODEHELP_COMMENTFLAG_JAVADOC) {
      mlcomment_start = CODEHELP_JAVADOC_PREFIX;
   }
   // loop through blanks until we find a blank line, so we know if blanks are used in the comment
   typeless element;
   boolean haveBlanks = false;
   for (element._makeempty();!haveBlanks;) {
      blanks._nextel(element);
      if(element._isempty()) break;
      int i = 0;
      for (i = 0; i < blanks:[element]._length(); i++) {
         if (blanks:[element][i] > 0 && element != '') {
            haveBlanks = true;
            break;
         }
      }
   }
   _str commentElements:[][];
   _str tagList[];
   _str description="";
   // parse information from the existing javadoc comment into hashtables
   _parseJavadocComment(orig_comment, description, commentElements, tagList, false, isDoxygen, auto tagStyle, false);
   // nuke the original comment lines
   int num_lines = last_line-first_line+1;
   if (num_lines > 0) {
      p_line=first_line;
      int i;
      for (i=0; i<num_lines; i++) {
         _delete_line();
      }
   }
   // put us where we need to be
   p_line=first_line-1;
   _str mlcomment_end = '';
   // get the ending of the comment (this should probably be parsed instead of using get_comment_delims)
   get_comment_delims(auto unused,auto unused2, mlcomment_end);
   if (isDoxygen) {
      if (mlcomment_start == '//!') {
         mlcomment_end = '//!';
      } else if (mlcomment_start == '///') {
         mlcomment_end = '///';
      }
   }
   // add the start of the comment
   if (mlcomment_start!='') {
      if (!isDoxygen || (mlcomment_start != '///' && mlcomment_start != '//!')) {
         insert_line(indent_string(start_col-1):+mlcomment_start);
      }
      if (slcomment_start != '') {
         slcomment_start=' 'slcomment_start;
      }
   }
   int i = 0;
   _str prefix=indent_string(start_col-1):+slcomment_start:+' ';
   // possibly adjust prefix
   int leadingBlank = 1;
   if (isDoxygen && (mlcomment_start == '//!' || mlcomment_start == '///')) {
      // safety check for start_col - 2 to not be neg?
      prefix=indent_string(start_col-2):+slcomment_start:+' ';
      leadingBlank = 0;
   }
   // maybe add leading blank lines before description
   if (isinteger(blanks:["leading"][0])) {
      for (i = 0; i < blanks:["leading"][0] - leadingBlank; i++) {
         insert_line(prefix);
      }
   }
   boolean haveBrief = false;
   for (i = 0; i < tagList._length() && !haveBrief; i++) {
      if (tagList[i] == 'brief') {
         haveBrief = true;
      }
   }
// say('prefix='prefix);
   // maybe add the description
   if (!haveBrief) {
      split(description, "\n", auto descArray);
      for (i = 0;i < descArray._length();i++) {
         if (strip(descArray[i]) != '') {
            insert_line(prefix:+descArray[i]);
         }
      }
      // add any blanks after the description
      if (isinteger(blanks:['']._length()) && isinteger(blanks:[''][0])) {
         for (i = 0; i < blanks:[''][0]; i++) {
            insert_line(prefix);
         }
      }
   } 
   // insert javadoc tags in the order they were originally
   insert_javadoc_elements(prefix, commentElements, blanks, isDoxygen, tagList, sigElements, haveBlanks, tagStyle);
   // add the end of the comment
   if (mlcomment_start!='') {
      if (!isDoxygen || (mlcomment_start != '//!' && mlcomment_start != '///')) {
         insert_line(indent_string(start_col):+mlcomment_end);
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
   first_non_blank();
   int status = _clex_find_start();
   if (!status) {
      int start_col = p_col;
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
   _str comElements:[][], int blanks:[][], boolean haveBlanks, boolean isDoxygen, _str tagStyle)
{
   int i, k, j = 0;
   _str params:[];
   params._makeempty();
   _str unmatchingDescs[];
   if (tag == 'param') {
      // for each param element extracted from the existing comment...
      for (k = 0; k < comElements:[tag]._length(); k++) {
         split(strip(comElements:[tag][k])," ", auto commmentTokens);
         // stripping possible EOL char off of what we grabbed from the comment...could do this beforehand?
         if (commmentTokens._length() > 1) {
            commmentTokens[0] = stranslate(commmentTokens[0],'','\n','R');
            boolean usingComment = false;
            for (i = 0; i < sigElements:[tag]._length(); i++) {
               _str newComment = strip(sigElements:[tag][i]);
               if (commmentTokens[0] == newComment) {
                  usingComment = true;
                  break;
               }
            }
            // unneeded nullcheck here?
            if (!usingComment && commmentTokens != null) {
               _str description = '';
               for (j = 1; j < commmentTokens._length(); j++) {
                  description :+= ' 'commmentTokens[j];
               }
               // couldn't find a match for this description? save it 
               unmatchingDescs[k] = description;
            } else {
               unmatchingDescs[k] = '';
            }
         }
      }
   }
   int blanksAfterLast = -1;
   // for each comment element of type 'tag' extracted from the function signature..
   for (i = 0; i < sigElements:[tag]._length(); i++) {
      _str newComment = strip(sigElements:[tag][i]);
      if (tag == 'return') {
         if(newComment == 'void') {
            // no return value...don't insert anything
            return;
         }
         newComment = '';
      }
      boolean foundExisting = false;
      boolean constructedDescription = false;
      // for each element of type 'tag' extracted from the existing comment...
      for (k = 0; k < comElements:[tag]._length(); k++) {
         split(comElements:[tag][k]," ", auto commentTokens);
         if (commentTokens != null && commentTokens._length() > 0){
            // stripping possible EOL char off of what we grabbed from the comment...could do this beforehand?
            // we've already done this for params...
            commentTokens[0] = stranslate(commentTokens[0],'','\n','R');
            // is the first token the same as the new comment that would be generated
            // from the function signature?
            if (tag == 'param' && params:[newComment] != null && params:[newComment] != '') {
               newComment = newComment :+ params:[newComment];
               foundExisting = true;
               constructedDescription = true;
               break;
            } else if (commentTokens[0] == newComment) {
               // if so, keep the already existing comment element, instead of replacing it
               newComment = comElements:[tag][k];
               foundExisting = true;
               constructedDescription = true;
               break;
            } else if (tag == 'return' && commentTokens[0] != '') {
               // this is good unless the return type has changed...
               newComment = comElements:[tag][k];
               break;
            }
         }
      }
      // if we checked this signature element against each element in the comments, and didn't find
      // an appropriate description, see if we saved one from before that is in the same position
      if (!constructedDescription && tag == 'param' && i < unmatchingDescs._length() && unmatchingDescs[i] != '') {
         newComment = newComment :+ unmatchingDescs[i]; 
         foundExisting = true;
      }
      int numBlanks = 0;
      if (!foundExisting) {
         numBlanks = blanksForNewElement(blanks,tag,haveBlanks);
         // are we on the last element? check our value for 'blanks after last occurrence'
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
            boolean foundBlank = false;
            // check to see if there are blanks after at least one of the other occurrences of this tag
            int m = 0;
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
static int blanksForNewElement(int blanks:[][], _str tag, boolean haveBlanks)
{
   int i = 0;
   int totalBlanks = 0;
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
   boolean isDoxygen, _str tagList[], _str sigElements:[][], boolean haveBlanks, _str tagStyle)
{
   int k = 0;
   boolean doneElementFromSig:[];
   doneElementFromSig._makeempty();
   _str curTag = '';
   for (k = 0; k < tagList._length(); k++) {
      curTag = tagList[k];
      // if this tag is not one that we extract from the function signature 
      if (!pos(curTag,JAVADOC_TAGS_FROM_SIG) && commentElements:[curTag] != null) {
         int i, j = 0;
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
   parse JAVADOC_TAGS_FROM_SIG with curTag ',' auto rest;
   // the loop on tagList will only cover the elements which existed in the original doc comment,
   // so we want to now loop over any elements which we extracted from the function signature and
   // didn't exist in the original comment 
   while (curTag != '') {
      if (!doneElementFromSig:[curTag]) {
         insert_javadoc_element_from_signature(prefix, sigElements, curTag, commentElements, blanks, haveBlanks,
            isDoxygen, tagStyle);
      }
      parse rest with curTag ',' rest;
   }
}

/**
 * Print a javadoc element into the current editor control.
 *
 * @param element
 * @param pre
 * @param tag
 */
static void write_javadoc_element(_str element, _str pre, _str tag, boolean isDoxygen, _str tagStyle)
{
   _str tagprefix = tagStyle;
   if (tag == 'return' && element == '') {
      insert_line(pre:+tagprefix:+tag);
      return;
   }
   int j = 0;
   split(element, "\n", auto elementLines);
   for (j = 0;j < elementLines._length();j++) {
      // we should not be inserting blank lines here
      // that is the job of the blanks hashtable
      if (elementLines[j] != '' || j == 0) {
         if (j == 0) {
            insert_line(pre:+tagprefix:+tag' ':+elementLines[j]);
         } else {
            insert_line(pre:+elementLines[j]);
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
 * @return boolean
 */
static boolean associated_file_exists(_str &filename, _str ext_list)
{
   mou_hour_glass(true);
   filename_no_ext  := _strip_filename(filename, 'E');
   filename_no_path := _strip_filename(filename, 'EP');

   // try same directory
   foreach (auto ext in ext_list) {
      if (file_exists(filename_no_ext"."ext)) {
         filename = filename_no_ext"."ext;
         mou_hour_glass(false);
         return true;
      }
   }

   // try current project
   if (_project_name != '') {
      foreach (ext in ext_list) {
         message("Searching: "_project_name);
         filename_in_project := _projectFindFile(_workspace_filename, _project_name, filename_no_path"."ext, 0);
         if (filename_in_project != '') {
            filename = filename_in_project;
            mou_hour_glass(false);
            return true;
         }
      }
   }

   // try entire workspace
   if (_workspace_filename != '') {
      _str foundFileList[];
      _str projectList[] = null;
      _GetWorkspaceFiles(_workspace_filename, projectList);
      foreach (ext in ext_list) {

         // try all projects in the workspace
         foreach (auto project in projectList) {
            project = _AbsoluteToWorkspace(project, _workspace_filename);
            if (project != _project_name) {
               // search this project for the file
               message("Searching: "project);
               filename_in_project := _projectFindFile(_workspace_filename, project, filename_no_path"."ext, 0);
               if (filename_in_project != "") {
                  foundFileList[foundFileList._length()] = filename_in_project;
               }
            }

         }
      }

      // remove duplicates
      foundFileList._sort();
      _aremove_duplicates(foundFileList, file_eq("A",'a'));

      // exactly one match, super!
      if (foundFileList._length() == 1) {
         filename = foundFileList[0];
         mou_hour_glass(false);
         return true;
      }

      // multiple matches, prompt
      if (foundFileList._length() > 1) {
         answer := select_tree(foundFileList);
         if (answer != '' && answer != COMMAND_CANCELLED_RC) {
            filename = answer;
            mou_hour_glass(false);
            return true;
         }
      }
   }

   // that's all folks
   mou_hour_glass(false);
   return false;
}


/**
 * Returns the associated file for a given 
 * filename (based on the file extension). 
 *  
 * @param filename 
 * 
 * @return _str Filename, or '' if no associated file was found
 */
_str associated_file_for(_str filename)
{
   // NOTE: when adding support for other extensions
   // make sure to also add them to the list in the
   // _OnUpdate() function!

   // extract the extension
   _str extension = _get_extension(filename);
   filename = _strip_filename(filename, 'E');

   // C#
   if( file_eq(extension, 'cs') ) {

      _str designerExt = _get_extension(filename);
      if (strieq(designerExt, "designer")) {
         if (!associated_file_exists(filename, "resx cs")) {
            filename = "";
         }
      } else if (strieq(designerExt, "xaml")) {
         if (!associated_file_exists(filename, "xaml cs")) {
            filename = "";
         }
      } else {
         if (!associated_file_exists(filename, "designer.cs xaml.cs xaml resx")) {
            filename = "";
         }
      }

   // Visual Studio resource file
   } else if( file_eq(extension, 'resx') ) {

      if (!associated_file_exists(filename, "cs designer.cs vb designer.vb cpp h jsl xaml")) {
         filename = "";
      }

   // Visual Studio xaml (windows presentation foundation) specification file
   } else if( file_eq(extension, 'xaml') ) {

      if (!associated_file_exists(filename, "cs xaml.cs vb cpp h jsl")) {
         filename = "";
      }

   // Visual Basic .NET
   } else if( file_eq(extension, 'vb') ) {

      _str designerExt = _get_extension(filename);
      if (strieq(designerExt, "designer")) {
         if (!associated_file_exists(filename, "resx vb")) {
            filename = "";
         }
      } else if (strieq(designerExt, "xaml")) {
         if (!associated_file_exists(filename, "xaml vb")) {
            filename = "";
         }
      } else {
         if (!associated_file_exists(filename, "designer.vb xaml.vb xaml resx")) {
            filename = "";
         }
      }

   // J#
   } else if( file_eq(extension, 'jsl') ) {

      if (!associated_file_exists(filename, "resx xaml")) {
         filename = "";
      }

   // build associated file path
   // h,    hpp, hp, hh, hxx -> c, m, cpp, cp, cc, cxx, inl, c++
   // c, m, cpp, cp, cc, cxx, c++ -> h,    hpp, hp, hh, hxx
   // inl -> h, hpp, hp, hh, hxx
   } else if(strieq(substr(extension, 1, 1), 'c') || strieq(extension, "inl") || (strieq(extension, 'm')) || (strieq(extension, 'mm'))) {

      // check for header file
      if (!associated_file_exists(filename, "h hpp hp hh hxx resx xaml qth")) {
         filename = "";
      }

   } else if(strieq(substr(extension, 1, 1), 'h')) {

      // check for source file
      if (!associated_file_exists(filename, "c m mm resx xaml cpp cp cc cxx c++ inl")) {
         filename = "";
      }

   } else if( file_eq(extension, 'qth') ) {

      if (!associated_file_exists(filename, "c cpp cxx c++ h")) {
         filename = "";
      }

   // Ada
   } else if( file_eq(extension, 'ads') ) {

      if (!associated_file_exists(filename, "adb ada")) {
         filename = "";
      }

   } else if( file_eq(extension, 'adb') ) {

      if (!associated_file_exists(filename, "ads ada")) {
         filename = "";
      }

   // DigitalMars D
   } else if( file_eq(extension, 'd') ) {

      if (!associated_file_exists(filename, "di")) {
         filename = "";
      }

   } else if( file_eq(extension, 'di') ) {

      if (!associated_file_exists(filename, "d")) {
         filename = "";
      }

   // Slick-C header file
   } else if( file_eq(extension,'sh') ) {

      // check for source file
      if (!associated_file_exists(filename, "e")) {
         filename = "";
      }

   } else if(strieq(substr(extension, 1, 1), 'e')) {

      // check for Slick-C header file
      if (!associated_file_exists(filename, "sh")) {
         filename = "";
      }

      // SystemVerilog
   } else if(file_eq(extension,'sv') ) {

      if (!associated_file_exists(filename, "svh svi")) {
         filename = "";
      }

   } else if(file_eq(extension,'svi') ) {

      if (!associated_file_exists(filename, "sv svh")) {
         filename = "";
      }

   } else if(file_eq(extension,'svh') ) {

      if (!associated_file_exists(filename, "sv svi")) {
         filename = "";
      }

      // Vera
   } else if(file_eq(extension,'vr') ) {

      if (!associated_file_exists(filename, "vrh vri")) {
         filename = "";
      }

   } else if(file_eq(extension,'vri') ) {

      if (!associated_file_exists(filename, "vr vrh")) {
         filename = "";
      }

   } else if(file_eq(extension,'vrh') ) {

      if (!associated_file_exists(filename, "vr vri")) {
         filename = "";
      }

   } else {

      // no match found
      filename = "";

   }
   return filename;
}


/**
 * Find the header or source file associated with the current file in the editor
 * and open it.
 *
 * @see gui_open
 * @see edit
 * @categories File_Functions
 */
_command void edit_associated_file() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   _str filename = associated_file_for(p_buf_name);

   // edit the file
   if (filename != "") {
      edit(maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
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

   // check if file extension matches a supported extension
   _str ext = _get_extension(target_wid.p_buf_name);
   if (pos(' 'ext' ',' c cc cp cpp cxx c++ inl m mm h hh hp hpp hxx cs resx xaml qth vb ads adb ada sh e jsl d di sv svh svi vr vri vrh ',1,'i')) {
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

/**
 * Copies current line or current selection up one line.  If no
 * selection is active, a LINE selection is created for the
 * current line.  If a selection is active, it is changed to
 * LINE selection and locked.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command void copy_lines_up() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if (select_active()) {
      markid := _duplicate_selection('');
      if (_select_type(markid) != "LINE") {
         _select_type(markid, 'T', 'LINE');
      }
      if (_select_type(markid, 'S') == 'C') {
         _select_type(markid, 'S', 'E');
      }
      begin_select(markid);
   }
   copy_to_clipboard();
   up();
   paste();
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
_command void copy_lines_down(boolean do_smart_paste=true) name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if (select_active()) {
      markid := _duplicate_selection('');
      if (_select_type(markid) != "LINE") {
         _select_type(markid, 'T', 'LINE');
      }
      if (_select_type(markid, 'S') == 'C') {
         _select_type(markid, 'S', 'E');
      }
      end_select(markid);
   }
   copy_to_clipboard();
   paste();
}

/**
 * Display menu of open tool windows for navigation.
 *
 */
_command void quick_navigate_toolwindows() name_info(','VSARG2_READ_ONLY)
{
   int objhandle = find_index("_active_toolwindow_menu",oi2type(OI_MENU));
   if (!objhandle) {
      return;
   }
   int menu_handle = p_active_form._menu_load(objhandle,'P');
   int cur = 0;
   int i = 0;
   // put an item in for the editor window
   if (!_no_child_windows()) {
      _menu_insert(menu_handle,cur++,MF_ENABLED,'Editor','activate_editor');
   }
   for(i = 0; i < def_toolbartab._length(); ++i) {
      _TOOLBAR* ptb = &def_toolbartab[i];
      // don't show toolbars
      if (ptb && !isToolbar(ptb->tbflags)) {
         int index = find_index(ptb->FormName,oi2type(OI_FORM));
         int wid = _tbIsVisible(ptb->FormName);
         // menu insert if the tool window is open, and it's not file tabs
         if(wid != 0 && wid.p_caption != 'File Tabs') {
            _menu_insert(menu_handle,cur++,MF_ENABLED,wid.p_caption,'activate_and_focus_toolbar 'ptb->FormName);
         }
      }
   }
   int x = 100;
   int y = 100;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   int flags2 = VPM_LEFTALIGN|VPM_LEFTBUTTON;
   int status = _menu_show(menu_handle, flags2, x, y);
   _menu_destroy(menu_handle);
}

_command void activate_and_focus_toolbar(_str form='') name_info(',')
{
   int wid = activate_toolbar(form,"");
   if (wid) {
      wid._set_focus();
   }
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
