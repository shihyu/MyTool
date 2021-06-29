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
#include "toolbar.sh"
#require "se/lang/api/LanguageSettings.e"
#require "se/lang/api/ExtensionSettings.e"
#import "complete.e"
#import "main.e"
#import "search.e"
#import "stdcmds.e"
#import "se/color/ColorScheme.e"
#import "setupext.e"
#endregion

using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;

defmain()
{
  _config_modify_flags(CFGMODIFY_DEFVAR);
  def_re_search_flags=VSSEARCHFLAG_PERLRE;
  def_inclusive_block_sel=1;
  def_display_buffer_id=false;
  if (_isUnix()) {
     def_autoclipboard=true;
     def_actapp=0;
  }
  def_gui=1;
  def_argument_completion_options=VSARGUMENT_COMPLETION_ALL_OPTIONS;
  def_one_file='';
  def_modal_tab=1;
  def_eclipse_switchbuf=1;
  def_file_types="All Files ("ALLFILES_RE"),":+
                 "C/C++ Files (*.c;*.cc;*.cpp;*.cppm;*.cp;*.cxx;*.c++;*.h;*.hh;*.hpp;*.hxx;*.h++;*.inl;*.ixx;*.xpm),":+
                 "C# Files (*.cs),":+  // Microsoft C# language
                 "Ch Files (*.ch;*.chf;*.chs;*.cpp;*.h),":+
                 "D Files (*.d),":+
                 "Groovy Files (*.groovy;*.gvy;*.gy;*.gsh),":+
                 "Java Files (*.java),":+
                 "HTML Files (*.htm;*.html;*.shtml;*.asp;*.jsp;*.php;*.php3;*.rhtml;*.css),":+
                 "CFML Files (*.cfm;*.cfml;*.cfc),":+
                 "XML Files (*.xml;*.dtd;*.xsd;*.xmldoc;*.xsl;*.xslt;*.ent;*.tld;*.xhtml;*.build;*.plist),":+
                 "XML/SGML DTD Files (*.xsd;*.dtd),":+
                 "XML/JSP TagLib Files (*.tld;*.xml),":+
                 "Objective-C (*.m;*.mm;*.h)," :+
                 "IDL Files (*.idl),":+
                 "Ada Files (*.ada;*.adb;*.ads),":+
                 "Applescript Files (*.applescript),":+
                 "Basic Files (*.vb;*.vbs;*.bas;*.frm),":+
                 "Cobol Files (*.cob;*.cbl;*.ocb),":+
                 "CoffeeScript Files (*.coffee),":+
                 "JCL Files (*.jcl),":+
                 "JavaScript (*.js;*.ds;*.json),":+
                 "ActionScript (*.as),":+
                 (_isUnix()?"Pascal Files (*.pas;*.dpr),":"Delphi Files (*.pas;*.dpr),"):+
                 "Fortran Files (*.for;*.f),":+
                 "Google Go Files (*.go),":+
                 "PL/I Files (*.pl1),":+
                 "InstallScript (*.rul),":+
                 "Perl Files (*.pl;*.pm;*.perl;*.plx),":+
                 "Python Files (*.py),":+
                 "Ruby Files (*.rb;*.rby),":+
                 "Java Properties (*.properties),":+
                 "Lua Files (*.lua),":+
                 "Tcl Files (*.tcl;*.tlib;*.itk;*.itcl;*.exp),":+
                 "PV-WAVE (*.pro),":+
                 "Scala Files (*.scala),":+
                 "Slick-C (*.e;*.sh),":+
                 "SQL Files (*.sql),":+
                 "SAS Files (*.sas),":+
                 "Text Files (*.txt),":+
                 "TTCN-3 Files (*.ttcn),":+
                 "Verilog Files (*.v),":+
                 "VHDL Files (*.vhd),":+
                 "SystemVerilog Files (*.sv;*.svh;*.svi),":+
                 "Vera Files (*.vr;*.vrh),":+
                 "Erlang Files (*.erl;*.hrl),":+
                 "QML Files (*.qml),":+
                 //"INI files (*.ini;*.slk),":+
                 //"Config files (*.cf;*.cnf;*.conf),":+
                 "Makefiles ("ALLFILES_RE"),":+
                 //"Imakefiles (Imakefile),":+
                 (_isUnix()?"Assembler (*.s)":"Assembler (*.asm)");
  def_import_file_types = "Text Files (*.txt)";
  def_find_file_types=def_file_types;
  def_alt_menu=1;
  def_cua_select_alt_shift_block=!_isMac();
  def_preplace=1;
  def_scursor_style=0;
  def_buflist=3;
  def_deselect_copy=true;
  def_deselect_paste=true;
  def_persistent_select='D';
  def_advanced_select='P';
  def_updown_col=0;
  def_hack_tabs=false;
  def_cursorwrap=false;
  def_load_options = '+L -LF +LE -S -E +U:32000 -N +BP';
  def_save_options = '-O +DD -Z -ZR -E -S';
  def_add_to_project_save_as = false;
  def_read_ahead_lines = 0;
  def_clipboards = 50;
  def_preload_ext = '.cmd';
  def_auto_restore = 1;
  def_select_style = 'CI';
  def_line_insert = 'A';
  def_exit_process = '1';
  def_keys = '';
  def_block_mode_fill_only_if_line_long_enough=false;
  def_prompt = '1';
  def_start_on_cmdline = false;
  def_stay_on_cmdline = false;
  def_wide_ext = '';
  def_next_word_style = 'E';
  def_top_bottom_style = '0';
  def_linewrap = false;
  def_join_strips_spaces = true;
  def_jmp_on_tab = true;
  def_pull = true;
  def_from_cursor = false;
  def_auto_reset = '';
  def_word_delim = '0';
  // Add support file names with spaces when using OS/2 icc compiler
//#if __UNIX__
  //def_error_re='^\*@(cfe\: (Error|Warning)\:|error(~:f|\*)|warning(~:f|\*)|\(|<|)\*@ *{:q|(.\\|):p}( +| *\(|\:|, line ){:d#}(,|\:|)( *{:d#}|> :i|)(\)|) @(error|){(\:|Error[~s]|Fatal|Warning)?*$}'
//#else
//#endif
  //def_error_re = '^\*@(cfe\: (Error|Warning)\:|error(~:f|\*)|warning(~:f|\*)|\(|)\*@ *{:q|:p}( +| *\(|\:|, line ){:d#}(,|\:|)( *{:d#}|)(\)|) @(error|rc|){(\:|Error[~s]|Fatal|Warning)?*$}'
  def_reflow_next = false;
  def_start_on_first = false;
  def_tprint_device = '/dev/lp0';
  def_restore_cursor = false;
  def_exit_file_list = true;
  def_pmatch_style = false;
  //def_ignore_tcase = '1'
  def_leave_selected=0;

  def_word_continue=false;

  // default to enabling the ant/makefile target menus
  def_show_makefile_target_menu=1;

  // default to not showing files in project in open dialog
  def_show_prjfiles_in_open_dlg=PROJECT_ADD_HIDES_FILES_IF_SUPPORTED_IN_NATIVE_DIALOG;

  if (_isUnix()) {
     // default to resolving dependent project symlinks during makefile generation
     def_resolve_dependency_symlinks=1;
  } else {
     def_resolve_dependency_symlinks=0;
  }

  if (_isUnix()) {
     def_url_proxy="";
     def_url_proxy_bypass="";
  } else {
     def_url_proxy="IE;";
     def_url_proxy_bypass="";
  }

  def_workspace_flags=WORKSPACE_OPT_COPYSAMPLES;

  // Turn ON filling column selection when hitting keys by default
  def_do_block_mode_key=true;
  def_do_block_mode_delete=true;
  def_do_block_mode_backspace=true;
  def_do_block_mode_del_key=true;

  def_maxbackup_ksize=5000;
  def_deltasave_flags=0;
  def_deltasave_versions=DELTASAVE_DEFAULT_NUMVERSIONS;

  def_jrefactor_auto_import=1; // Determines whether auto add import functionality is used

  def_antmake_use_classpath = 1; 
  def_antmake_display_imported_targets = true; 
  def_antmake_filter_matches = false; 
  def_antmake_identify = true; 
  def_max_ant_file_size = 1048576;
  def_eclipse_extensionless = true;
  def_eclipse_check_ext_mode = true;

  // search and find tool flags
  def_find_init_defaults = 0;
  def_find_close_on_default = 1;
  def_search_incremental_highlight = 1;
  def_replace_preview_all_reverse_sides = false;

  // Do extra checking for auto reload prompting? 
  def_autoreload_compare_contents = true;
  def_autoreload_compare_contents_max_ksize = 2000;

  // Show or hide dot files in file/directory list?
  if (_isUnix()) {
     def_filelist_show_dotfiles = false;
  } else {
     def_filelist_show_dotfiles = true;
  }
  
  // adaptive formatting related items
  def_adaptive_formatting_flags = 0;
  //def_warn_adaptive_formatting = true;
  def_adaptive_formatting_on = false;

  restore_search('',0,'[A-Za-z0-9_$]');
  _scroll_style('H 2');
  _cursor_shape('-v 450 1000 750 1000 450 1000 750 1000');
  _default_option('S',IGNORECASE_SEARCH|VSSEARCHFLAG_WRAP|PROMPT_WRAP_SEARCH);
  _insert_state(1,'d');
  _default_option('H','2');
  _default_option('V','4');
  _insert_state('1','d');

  /* call mou_config('1 0 1996554239 0') */
  _default_option('D',0);
  def_updown_screen_lines=true;
  _SoftWrapUpdateAll(false,true);
  _str updateTable:[];
  //updateTable:[VSLANGPROPNAME_TABS]='';
  //updateTable:[VSLANGPROPNAME_INDENT_WITH_TABS]='';
  updateTable:[VSLANGPROPNAME_SOFT_WRAP]='';
  updateTable:[VSLANGPROPNAME_SOFT_WRAP_ON_WORD]='';
  if(index_callable(find_index('_update_buffer_from_new_setting',PROC_TYPE))) _update_buffer_from_new_setting(updateTable);

  def_toolbar_options = 0;

  if (_isUnix()) {
     def_vim_change_cursor=false;
  } else {
     def_vim_change_cursor=true;
  }
  def_vim_esc_codehelp=false;
  def_vim_stay_in_ex_prmpt=true;
  def_vim_start_in_cmd_mode=false;

  def_project_auto_build = false;
  // Completion e and edit lists binary files
  def_list_binary_files=true;
  // Select comments when using select_proc
  def_select_proc_flags=SELECT_PROC_NONE;
  def_select_type_block=false;

  // number of MRU document modes and project types to display on New File/Project dialog.
  def_max_doc_mode_mru = 5;
  def_max_proj_type_mru = 5;
}
