////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50635 $
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
#include "dockchannel.sh"
#require "se/lang/api/LanguageSettings.e"
#require "se/lang/api/ExtensionSettings.e"
#import "complete.e"
#import "main.e"
#import "search.e"
#import "stdcmds.e"
#import "se/color/ColorScheme.e"
#endregion

using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;

defmain()
{
  _config_modify_flags(CFGMODIFY_OPTION);
#if __UNIX__
  def_autoclipboard=1;
  def_actapp=0;
#endif
  def_gui=1;
  def_argument_completion_options=VSARGUMENT_COMPLETION_ALL_OPTIONS;
  def_one_file='';
  def_modal_tab=1;
  def_eclipse_switchbuf=1;
  def_file_types="All Files ("ALLFILES_RE"),":+
                 "C/C++ Files (*.c;*.cc;*.cpp;*.cp;*.cxx;*.c++;*.h;*.hh;*.hpp;*.hxx;*.inl;*.xpm),":+
                 "C# Files (*.cs),":+  // Microsoft C# language
                 "Ch Files (*.ch;*.chf;*.chs;*.cpp;*.h),":+
                 "D Files (*.d),":+
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
                 "JavaScript (*.js;*.ds),":+
                 "ActionScript (*.as),":+
#if __UNIX__
                 "Pascal Files (*.pas;*.dpr),":+
#else
                 "Delphi Files (*.pas;*.dpr),":+
#endif
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
                 //"INI files (*.ini;*.slk),":+
                 //"Config files (*.cf;*.cnf;*.conf),":+
                 "Makefiles ("ALLFILES_RE"),":+
#if __UNIX__
                 //"Imakefiles (Imakefile),":+
                 "Assembler (*.s)";
#else
                 "Assembler (*.asm)";
#endif
  def_import_file_types = "Text Files (*.txt)";
  def_alt_menu=1;
  def_preplace=1;
  def_scursor_style=0;
  def_buflist=3;
  def_deselect_copy=1;
  def_deselect_paste=1;
  def_persistent_select='D';
  def_advanced_select='P';
  def_updown_col=0;
  def_hack_tabs=0;
  def_cursorwrap=0;
  def_load_options = '+L -LF +LE -S -E +U:32000 -N +BP';
  def_save_options = '-O +DD -Z -ZR -E -S';
  def_add_to_project_save_as = false;
  def_read_ahead_lines = 0;
  def_clipboards = 50;
  def_preload_ext = '.cmd';
  def_auto_restore = 1;
  def_select_style = 'CI';
  def_line_insert = 'A';
  def_exit_process = '';
  def_user_args = '';
  def_keys = '';
  def_prompt = '1';
  def_start_on_cmdline = '0';
  def_stay_on_cmdline = '0';
  def_wide_ext = '';
  def_next_word_style = 'E';
  def_top_bottom_style = '0';
  def_linewrap = '0';
  def_join_strips_spaces = true;
  def_jmp_on_tab = '1';
  def_pull = '1';
  def_from_cursor = '0';
  def_auto_reset = '';
  def_word_delim = '0';
  // Add support file names with spaces when using OS/2 icc compiler
//#if __UNIX__
  //def_error_re='^\*@(cfe\: (Error|Warning)\:|error(~:f|\*)|warning(~:f|\*)|\(|<|)\*@ *{:q|(.\\|):p}( +| *\(|\:|, line ){:d#}(,|\:|)( *{:d#}|> :i|)(\)|) @(error|){(\:|Error[~s]|Fatal|Warning)?*$}'
//#else
//#endif
  //def_error_re = '^\*@(cfe\: (Error|Warning)\:|error(~:f|\*)|warning(~:f|\*)|\(|)\*@ *{:q|:p}( +| *\(|\:|, line ){:d#}(,|\:|)( *{:d#}|)(\)|) @(error|rc|){(\:|Error[~s]|Fatal|Warning)?*$}'
  def_reflow_next = '0';
  def_start_on_first = '0';
  def_leading_codes = '';
  def_trailing_codes = '';
  def_print_device = 'prn';
  def_tprint_device = '/dev/lp0';
  def_restore_cursor = 0;
  def_exit_file_list = '1';
  def_pmatch_style = '0';
  //def_ignore_tcase = '1'
  def_leave_selected=0;

  def_bbtb_colors[0]=0x80000005;
  def_bbtb_colors[1]=0x80000005;

  def_word_continue=false;

  // default to enabling the ant/makefile target menus
  def_show_makefile_target_menu=1;

  // default to not showing files in project in open dialog
  def_show_prjfiles_in_open_dlg=0;

#if __UNIX__
  // default to resolving dependent project symlinks during makefile generation
  def_resolve_dependency_symlinks=1;
#else
  def_resolve_dependency_symlinks=0;
#endif

#if __UNIX__
  def_url_proxy="";
  def_url_proxy_bypass="";
#else
  def_url_proxy="IE;";
  def_url_proxy_bypass="";
#endif

  def_workspace_options=WORKSPACE_OPT_COPYSAMPLES;

  // Turn ON filling column selection when hitting keys by default
  def_do_block_mode_key=true;
  def_do_block_mode_delete=true;
  def_do_block_mode_backspace=true;
  def_do_block_mode_del_key=true;

  typeless p1;
  p1=&def_toolboxtab[0];
  p1->[0]='_mdibutton_bar_form';
  p1->[1]=' 4 7 10 14 17';
  p1->[2]='3';
  p1->[3]='';
  p1->[4]=0;
  p1=&def_toolboxtab[1];
  p1->[0]='_toolbox_form';
  p1->[1]='';
  p1->[2]='3';
  p1->[3]='';
  p1->[4]=0;

  // The dialog that controls def_maxbackup is in K, so multiply by 1024
  def_maxbackup=5000*1024;
  def_deltasave_flags=0;
  def_deltasave_versions=DELTASAVE_DEFAULT_NUMVERSIONS;

  def_jrefactor_auto_import=1; // Determines whether auto add import functionality is used

  // Jave Live errors def vars that are needed across multiple files
  def_java_live_errors_jdk_6_dir = "";
  def_java_live_errors_jvm_lib= "";
  def_java_live_errors_enabled = 0;
  def_java_live_errors_first = 1;
  def_java_live_errors_errored= 0;
  def_java_live_errors_incremental_compile = 0;

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
  def_search_incremental_highlight = 0;

  // Do extra checking for auto reload prompting? 
  def_autoreload_compare_contents = true;
  def_autoreload_compare_contents_max_size = 2000000;

  // Show or hide dot files in file/directory list?
#if __UNIX__
  def_filelist_show_dotfiles = false;
#else
  def_filelist_show_dotfiles = true;
#endif
  
  // adaptive formatting related items
  def_adaptive_formatting_flags = 0;
  def_warn_adaptive_formatting = true;
  def_adaptive_formatting_on = false;

  //**************************************************************
  // if you add a setup here, you may need to modify the
  // _ModifyTabSetupAll() function so switching emulations
  // changes some tab configurations.
  //**************************************************************

  replace_def_data("def-language-cfscript",'MN=CFScript,TABS=+4,MA=1 74 1,KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=CFScript,CF=1,');
  replace_def_data("def-options-cfscript",'4 1 1 0 4 1 1');
  ExtensionSettings.setLangRefersTo('cfscript', 'cfscript');

  replace_def_data("def-language-phpscript",'MN=PHP,TABS=+4,MA=1 74 1,KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=PHP,CF=1,');
  replace_def_data("def-options-phpscript",'4 1 1 0 4 1 1');
  ExtensionSettings.setLangRefersTo('phpscript', 'phpscript');
  LanguageSettings.setReferencedInLanguageIDs('phpscript', "html xhtml");

  replace_def_data("def-language-idl",'MN=IDL,TABS=+4,MA=1 74 1,KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=IDL,CF=1,');
  replace_def_data("def-options-idl",'4 1 1 0 4 1 1');
  LanguageSettings.setBeginEndPairs('idl', "(#ifdef),(#ifndef),(#if)|(#endif)");
  ExtensionSettings.setLangRefersTo('idl', 'idl');
  LanguageSettings.setReferencedInLanguageIDs('idl', "ansic c cs d java m");

  replace_def_data("def-language-tagdoc",'MN=SlickEdit Tag Docs,TABS=+3,MA=1 74 1,KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=VSTagDoc,CF=1,');
  replace_def_data("def-options-tagdoc",'3 1 1 0 4 1 1');
  ExtensionSettings.setLangRefersTo('tagdoc', 'tagdoc');

  replace_def_data("def-language-bat",'MN=Batch,TABS=+4,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=Batch,CF=1,LNL=0,');
  replace_def_data("def-options-bat",'4 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('bat', 'bat');
  ExtensionSettings.setLangRefersTo('cmd', 'bat');

  replace_def_data("def-language-ini",'MN=INI,TABS=+4,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=INI File,CF=1,LNL=0,');
  replace_def_data("def-options-ini",'4 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('ini', 'ini');
  ExtensionSettings.setLangRefersTo('slk', 'ini');

  replace_def_data("def-language-conf",'MN=Config,TABS=+4,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=Config File,CF=1,LNL=0,');
  replace_def_data("def-options-conf",'4 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('conf', 'conf');
  ExtensionSettings.setLangRefersTo('cf', 'conf');

  replace_def_data("def-language-mak",'MN=Makefile,TABS=+8,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=1,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=Makefile,CF=1,LNL=0,');
  replace_def_data("def-options-mak",'8 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('mak', 'mak');
  ExtensionSettings.setLangRefersTo('mk', 'mak');
  LanguageSettings.setLoadExpandTabsToSpaces('mak', 0);
  LanguageSettings.setSaveExpandTabsToSpaces('mak', 0);

  replace_def_data("def-language-imakefile",'MN=Imakefile,TABS=+4,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=Imakefile,CF=1,LNL=0,');
  replace_def_data("def-options-imakefile",'4 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('imakefile', 'imakefile');

  replace_def_data("def-language-fundamental","MN=Plain Text,TABS=+8,MA=1 74 1,KEYTAB=default-keys,WW=1,IWT=0,ST="DEFAULT_SPECIAL_CHARS",IN=1,WC=A-Za-z0-9_'.$,LN=,CF=4,");
  ExtensionSettings.setLangRefersTo('txt', FUNDAMENTAL_LANG_ID);
  ExtensionSettings.setLangRefersTo('asc', FUNDAMENTAL_LANG_ID);
  ExtensionSettings.setLangRefersTo('log', FUNDAMENTAL_LANG_ID);
  ExtensionSettings.setLangRefersTo('err', FUNDAMENTAL_LANG_ID);
  ExtensionSettings.setLangRefersTo('tsv', FUNDAMENTAL_LANG_ID);
  ExtensionSettings.setLangRefersTo('csv', FUNDAMENTAL_LANG_ID);

  replace_def_data("def-language-binary",'MN=Binary,TABS=+4,MA=1 74 1,KEYTAB=default-keys,WW=0,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=0,WC=A-Za-z0-9_$,LN=,CF=4,');
  replace_def_data("def-options-binary",'1 0 1 0 0 3 0');
  LanguageSettings.setLoadAsBinary('binary', true);
  LanguageSettings.setSaveAsBinary('binary', true);
  LanguageSettings.setAutoCompleteOptions('binary', 33554432);
  LanguageSettings.setUseAdaptiveFormatting('binary', false);

  replace_def_data("def-language-process",'MN=Process,TABS=+8,MA=1 74 1,KEYTAB=process-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_$.!@#%^&()\-_=+[{\]},LN=,CF=4,');
  LanguageSettings.setMenuIfNoSelection('process', '_process_menu_default');

  replace_def_data("def-language-fileman",'MN=Fileman,TABS=+8,MA=1 74 1,KEYTAB=fileman-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_$,LN=,CF=4,LNL=0,');

  // C/C++
  replace_def_data("def-language-c",'MN=C/C++,TABS=+4,MA=1 74 1,KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=cpp,CF=1,LNL=0,TL=-1');
  replace_def_data("def-options-c","4 1 1 0 4 1 1");
  LanguageSettings.setBeautifierProfileName('c', 'Default');
  LanguageSettings.setBeautifierExpansions('c', BEAUT_EXPAND_DEFAULTS);
  LanguageSettings.setAutoBracePlacement('c', AUTOBRACE_PLACE_NEXTLINE);

  LanguageSettings.setBeginEndPairs('c', '(#ifdef),(#ifndef),(#if)|(#endif)');
  LanguageSettings.setReferencedInLanguageIDs('c', "ansic asm asm390 d m masm npasm s unixasm");
  ExtensionSettings.setLangRefersTo('c', 'c');
  ExtensionSettings.setLangRefersTo('h', 'c');
#if __UNIX__
  ExtensionSettings.setLangRefersTo('C', 'c');
  ExtensionSettings.setLangRefersTo('H', 'c');
  ExtensionSettings.setLangRefersTo('CC', 'c');
  ExtensionSettings.setLangRefersTo('C++', 'c');
#endif
  ExtensionSettings.setLangRefersTo('tcc', 'c');
  ExtensionSettings.setLangRefersTo('cc', 'c');
  ExtensionSettings.setLangRefersTo('hh', 'c');
  ExtensionSettings.setLangRefersTo('cp', 'c');
  ExtensionSettings.setLangRefersTo('hp', 'c');
  ExtensionSettings.setLangRefersTo('cpp', 'c');
  ExtensionSettings.setLangRefersTo('hpp', 'c');
  ExtensionSettings.setLangRefersTo('hxx', 'c');
  ExtensionSettings.setLangRefersTo('cxx', 'c');
  ExtensionSettings.setLangRefersTo('inl', 'c');
  ExtensionSettings.setLangRefersTo('xpm', 'c');
  ExtensionSettings.setLangRefersTo('qth', 'c');
  ExtensionSettings.setLangRefersTo('c++', 'c');
  ExtensionSettings.setLangRefersTo('i', 'c');

  // Objective-C
  replace_def_data("def-language-m",'MN=Objective-C,TABS=+4,MA=1 74 1,KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=Objective-C,CF=1,LNL=0,TL=-1');
  replace_def_data("def-options-m","4 1 1 0 4 1 1");
  ExtensionSettings.setLangRefersTo('m', 'm');
  ExtensionSettings.setLangRefersTo('mm', 'm');
  LanguageSettings.setLangInheritsFrom('m', 'c');
  LanguageSettings.setReferencedInLanguageIDs('m', "ansic asm c masm s unixasm");
  LanguageSettings.setBeautifierProfileName('m', 'Default');
  LanguageSettings.setBeautifierExpansions('m', BEAUT_EXPAND_DEFAULTS);
  LanguageSettings.setAutoBracePlacement('m', AUTOBRACE_PLACE_NEXTLINE);

  // Applescript
  replace_def_data("def-language-applescript",'MN=Applescript,TABS=+4,MA=1 74 1,KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=Applescript,CF=1,LNL=0,TL=0,BNDS=,CAPS=0,SW=0,SOW=0');
  replace_def_data("def-options-applescript",'4 1 1 0 0 3 0');
  ExtensionSettings.setEncoding('applescript', '+fcp30113');
  ExtensionSettings.setLangRefersTo('applescript', 'applescript');

  // Microsoft C# language
  replace_def_data("def-language-cs",'MN=C#,TABS=+4,MA=1 74 1,KEYTAB=c-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_@,LN=CSharp,CF=1,LNL=0,TL=-1');
  replace_def_data("def-options-cs","4 1 1 0 4 1 1");
  LanguageSettings.setBeautifierProfileName('cs', 'Default');
  LanguageSettings.setBeautifierExpansions('cs', BEAUT_EXPAND_DEFAULTS);
  LanguageSettings.setBeginEndPairs('cs', '(#ifdef),(#ifndef),(#if)|(#endif)');
  ExtensionSettings.setLangRefersTo('cs', 'cs');
  LanguageSettings.setReferencedInLanguageIDs('cs', "bas");

  // Pascal
  replace_def_data("def-language-pas",'MN=Pascal,TABS=+4,MA=1 74 1,KEYTAB=pascal-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=pascal,CF=1,');
  replace_def_data("def-options-pas","4 1 1 0 0 1 0");
  ExtensionSettings.setLangRefersTo('pas', 'pas');
  ExtensionSettings.setLangRefersTo('dpr', 'pas');
  LanguageSettings.setReferencedInLanguageIDs('pas', "ansic asm masm s unixasm");
/*
    (clark) added "try" block for Delphi to begin/end pairs below

    begin
        try
               {something}
        finally
            {something else}
        end;
    end;
*/
  LanguageSettings.setBeginEndPairs('pas','(class),(begin),(case),(try)|(end);I');

  LanguageSettings.setBeginEndPairs('for','(then)|(endif) (if)|(then) (function),(subroutine)|(end);I');
  LanguageSettings.setReferencedInLanguageIDs('for', "ansic asm asm390 masm npasm s unixasm");

  // Slick-C
  replace_def_data("def-language-e",'MN=Slick-C,TABS=+3,MA=1 74 1,KEYTAB=slick-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=Slick-C,CF=1,');
  replace_def_data("def-options-e","3 1 1 0 4 1 0");
  LanguageSettings.setBeginEndPairs('e', '(#if)|(#endif)');
  ExtensionSettings.setLangRefersTo('e', 'e');
  LanguageSettings.setReferencedInLanguageIDs('e', "c");

  // Java
  replace_def_data("def-language-java",'MN=Java,TABS=+8,MA=1 74 1,KEYTAB=java-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=Java,CF=1,');
  replace_def_data("def-options-java","4 1 1 0 4 1 1");
  ExtensionSettings.setLangRefersTo('java', 'java');
  LanguageSettings.setReferencedInLanguageIDs('java', "js android");
  LanguageSettings.setBeautifierProfileName('java', 'Default');
  LanguageSettings.setBeautifierExpansions('java', BEAUT_EXPAND_DEFAULTS);

  // J#
  replace_def_data("def-language-jsl",'MN=J#,TABS=+8,MA=1 74 1,KEYTAB=java-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=JSharp,CF=1,');
  replace_def_data("def-options-jsl","4 1 1 0 4 1 1");
  LanguageSettings.setLangInheritsFrom('jsl', 'java');
  LanguageSettings.setReferencedInLanguageIDs('jsl', "java");
  ExtensionSettings.setLangRefersTo('jsl', 'jsl');

  // HTML
  replace_def_data("def-language-html",'MN=HTML,TABS=+4,MA=1 74 1,KEYTAB=html-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_:$,LN=HTML,CF=1,');
  replace_def_data("def-options-html",'4 1 0 0 1 1 1 1 0 0 0 1 1 0');
  ExtensionSettings.setEncoding('html', '+fautohtml');
  ExtensionSettings.setLangRefersTo('html', 'html');
  ExtensionSettings.setLangRefersTo('htm', 'html');
  ExtensionSettings.setLangRefersTo('rhtml', 'html');
  ExtensionSettings.setLangRefersTo('shtml', 'html');
  ExtensionSettings.setLangRefersTo('asp', 'html');
  ExtensionSettings.setLangRefersTo('asax', 'html');
  ExtensionSettings.setLangRefersTo('ascx', 'html');
  ExtensionSettings.setLangRefersTo('aspx', 'html');
  ExtensionSettings.setLangRefersTo('jsp', 'html');
  ExtensionSettings.setLangRefersTo('php3', 'html');
  ExtensionSettings.setLangRefersTo('php', 'html');
  ExtensionSettings.setLangRefersTo('master', 'html');
  LanguageSettings.setReferencedInLanguageIDs('html', "cfml xhtml");

  // CFML
  replace_def_data("def-language-cfml",'MN=CFML,TABS=+4,MA=1 74 1,KEYTAB=html-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_:$,LN=CFML,CF=1,');
  replace_def_data("def-options-cfml",'4 1 1 1 1 1 1 1 0 0 0 1 0');
  LanguageSettings.setLangInheritsFrom('cfml', 'html');
  ExtensionSettings.setLangRefersTo('cfml', 'cfml');
  ExtensionSettings.setLangRefersTo('cfm', 'cfml');
  ExtensionSettings.setLangRefersTo('cfc', 'cfml');
  LanguageSettings.setReferencedInLanguageIDs('cfml', "html xhtml");

  // Bulletin Board Code
  replace_def_data("def-language-bbc",'MN=Bulletin Board Code,TABS=+4,MA=1 74 1,KEYTAB=html-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_:$,LN=BBC,CF=1,');
  ExtensionSettings.setLangRefersTo('bbc', 'bbc');

  // TeX
  replace_def_data("def-language-tex",'MN=TeX,TABS=+4,MA=1 74 1,KEYTAB=default-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_:$\\,LN=tex,CF=1,');
  ExtensionSettings.setLangRefersTo('tex', 'tex');

  // BibTeX
  replace_def_data("def-language-bibtex",'MN=BibTeX,TABS=+4,MA=1 74 1,KEYTAB=default-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_:$\\,LN=BibTeX,CF=1,');
  ExtensionSettings.setLangRefersTo('bib', 'bibtex');

  // PDF
  replace_def_data("def-language-pdf",'MN=PDF,TABS=+4,MA=1 74 1,KEYTAB=default-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_:$\\,LN=PDF,CF=1,');
  ExtensionSettings.setLangRefersTo('pdf', 'pdf');

  // Postscript
  replace_def_data("def-language-postscript",'MN=PostScript,TABS=+4,MA=1 74 1,KEYTAB=default-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_:$\\,LN=PostScript,CF=1,');
  ExtensionSettings.setLangRefersTo('ps', 'postscript');

  // DTD
  replace_def_data("def-language-dtd",'MN=DTD,TABS=+4,MA=1 74 1,KEYTAB=xml-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_:$?.!\-,LN=XMLDTD,CF=1,');
  replace_def_data("def-options-dtd",'4 1 -1 -1 -1 1 1 1 1 1 1 0');
  ExtensionSettings.setEncoding('dtd', '+fautoxml');
  ExtensionSettings.setLangRefersTo('dtd', 'dtd');

  // XML
  replace_def_data("def-language-xml",'MN=XML,TABS=+4,MA=1 74 1,KEYTAB=xml-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_:$?.!\-,LN=XML,CF=1,');
  replace_def_data("def-options-xml",'4 1 -1 -1 -1 1 1 1 1 1 1 -1');
  ExtensionSettings.setEncoding('xml', '+fautoxml');
  ExtensionSettings.setLangRefersTo('xml', 'xml');
  ExtensionSettings.setLangRefersTo('eventHandlers', 'xml');
  ExtensionSettings.setLangRefersTo('scriptTerminology', 'xml');
  ExtensionSettings.setLangRefersTo('scriptSuite', 'xml');
  ExtensionSettings.setLangRefersTo('sdef', 'xml');
  ExtensionSettings.setLangRefersTo('xaml', 'xml');
  ExtensionSettings.setLangRefersTo('build', 'xml');
  ExtensionSettings.setLangRefersTo('wxs', 'xml');
  ExtensionSettings.setLangRefersTo('wxi', 'xml');
  ExtensionSettings.setLangRefersTo('wxl', 'xml');
  LanguageSettings.setReferencedInLanguageIDs('xml', "dtd xhtml xsd xsl");

  // VPJ
  replace_def_data("def-language-vpj",VPJ_SETUP);
  replace_def_data("def-options-vpj",'4 1 -1 -1 -1 1 1 1 1 1 1 -1');
  LanguageSettings.setLangInheritsFrom('vpj', 'xml');
  ExtensionSettings.setEncoding('vpj', '+fautoxml');
  ExtensionSettings.setEncoding('vpe', '+fautoxml');
  ExtensionSettings.setEncoding('vpt', '+fautoxml');
  ExtensionSettings.setEncoding('vpw', '+fautoxml');
  ExtensionSettings.setLangRefersTo('vpj', 'vpj');
  ExtensionSettings.setLangRefersTo('vpe', 'vpj');
  ExtensionSettings.setLangRefersTo('vpt', 'vpj');
  ExtensionSettings.setLangRefersTo('vpw', 'vpj');

  ExtensionSettings.setLangRefersTo('xsl', 'xml');
  ExtensionSettings.setEncoding('xsl', '+fautoxml');

  ExtensionSettings.setLangRefersTo('xslt', 'xml');
  ExtensionSettings.setEncoding('xslt', '+fautoxml');

  ExtensionSettings.setLangRefersTo('plist', 'xml');
  ExtensionSettings.setEncoding('plist', '+fautoxml');

  // XSD
  replace_def_data("def-language-xsd",XSD_SETUP);
  replace_def_data("def-options-xsd",'4 1 -1 -1 -1 1 1 1 1 1 1 -1');
  LanguageSettings.setLangInheritsFrom('xsd', 'xml');
  ExtensionSettings.setEncoding('xsd', '+fautoxml');
  ExtensionSettings.setLangRefersTo('xsd', 'xsd');
  LanguageSettings.setReferencedInLanguageIDs('xsd', "xhtml xml");

  // Docbook
  replace_def_data("def-language-docbook",DOCBOOK_SETUP);
  replace_def_data("def-options-docbook",'4 1 -1 -1 -1 1 1 1 1 1 1 -1');
  LanguageSettings.setLangInheritsFrom('docbook', 'xml');
  ExtensionSettings.setEncoding('docbook', '+fautoxml');
  ExtensionSettings.setLangRefersTo('docbook', 'docbook');
  ExtensionSettings.setDefaultDTD('docbook', '%VSROOT%tagfiles':+FILESEP:+'docbook.vtg');
  LanguageSettings.setReferencedInLanguageIDs('docbook', "dtd xhtml xsd xml");

  // Ant
  replace_def_data("def-language-ant",ANT_SETUP);
  replace_def_data("def-options-ant",'4 1 -1 -1 -1 1 1 1 1 1 1 -1');
  LanguageSettings.setLangInheritsFrom('ant', 'xml');
  ExtensionSettings.setEncoding('ant', '+fautoxml');

  // Android Resource XML 
  replace_def_data("def-language-android",ANDROID_SETUP);
  replace_def_data("def-options-android",'4 1 -1 -1 -1 1 1 1 1 1 1 -1');
  LanguageSettings.setLangInheritsFrom('android', 'xml');
  ExtensionSettings.setEncoding('android', '+fautoxml');
  LanguageSettings.setReferencedInLanguageIDs('android', "java");

  // XHTML
  replace_def_data("def-language-xhtml",XHTML_SETUP);
  replace_def_data("def-options-xhtml",'4 1 -1 -1 -1 1 1 1 1 1 1 -1');
  LanguageSettings.setLangInheritsFrom('xhtml', 'xml');
  ExtensionSettings.setEncoding('xhtml', '+fautoxml');
  ExtensionSettings.setLangRefersTo('xhtml', 'xhtml');
  LanguageSettings.setReferencedInLanguageIDs('xhtml', "cfml dtd html xml");

  // XML Doc
  replace_def_data("def-language-xmldoc",XMLDOC_SETUP);
  replace_def_data("def-options-xmldoc",'4 1 -1 -1 -1 1 1 1 1 1 1 -1');
  LanguageSettings.setLangInheritsFrom('xmldoc', 'xml');
  ExtensionSettings.setLangRefersTo('xmldoc', 'xmldoc');
  ExtensionSettings.setEncoding('xmldoc', '+fautoxml');
  ExtensionSettings.setDefaultDTD('xmldoc', '%VSROOT%tagfiles':+FILESEP:+'xmldoc.vtg');

#if !__UNIX__
  // Microsoft Visual Studio .NET project file extensions
  ExtensionSettings.setLangRefersTo('vcproj', 'xml');
  ExtensionSettings.setEncoding('vcproj', '+fautoxml');
  ExtensionSettings.setDefaultDTD('vcproj', '%VSROOT%tagfiles':+FILESEP:+'vcproj.vtg');

  ExtensionSettings.setLangRefersTo('vbproj', 'xml');
  ExtensionSettings.setEncoding('vbproj', '+fautoxml');
  ExtensionSettings.setDefaultDTD('vbproj', '%VSROOT%tagfiles':+FILESEP:+'csproj.vtg');

  ExtensionSettings.setLangRefersTo('csproj', 'xml');
  ExtensionSettings.setEncoding('csproj', '+fautoxml');
  ExtensionSettings.setDefaultDTD('csproj', '%VSROOT%tagfiles':+FILESEP:+'csproj.vtg');
#endif

  // vsdelta backup files
  ExtensionSettings.setLangRefersTo('vsdelta', 'xml');
  ExtensionSettings.setEncoding('vsdelta', '+ftext');
  ExtensionSettings.setDefaultDTD('vsdelta', '%VSROOT%tagfiles':+FILESEP:+'vsdelta.vtg');

  // .setemplate code template metadata files
  ExtensionSettings.setLangRefersTo('setemplate', 'xml');
  ExtensionSettings.setEncoding('setemplate', '+fautoxml');

  // .sca code annotation files
  ExtensionSettings.setLangRefersTo('sca', 'xml');
  ExtensionSettings.setEncoding('sca', '+fautoxml');

  // JSP TagLib
  replace_def_data("def-language-tld",'MN=JSP TagLib,TABS=+4,MA=1 74 1,KEYTAB=html-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_:$,LN=XMLTAGLIB,CF=1,');
  replace_def_data("def-options-tld",'4 1 1 1 1 1 1 1 0 0 0 1 0');
  LanguageSettings.setLangInheritsFrom('tld', 'html');
  ExtensionSettings.setLangRefersTo('tld', 'tld');

  // 1-ACFC0 - update .sh to point to Bourne Shell instead of Slick-C
  replace_def_data("def-language-bourneshell",'MN=Bourne Shell,TABS=+8,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=Bourne Shell,CF=1,LNL=0,');
  replace_def_data("def-options-bourneshell",'4 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('bourneshell', 'bourneshell');
  ExtensionSettings.setLangRefersTo('sh', 'bourneshell');

  // C Shell
  replace_def_data("def-language-csh",'MN=C Shell,TABS=+8,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=C Shell,CF=1,LNL=0,');
  replace_def_data("def-options-csh",'4 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('csh', 'csh');

  // SlickEdit Color Coding files
  replace_def_data("def-language-vlx",'MN=SlickEdit Color Coding,TABS=+4,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_$,LN=vlx,CF=1,LNL=0,');
  replace_def_data("def-options-vlx",'4 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('vlx', 'vlx');

  // SlickEdit message file
  replace_def_data("def-language-vsm",'MN=SlickEdit Message File,TABS=+4,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_$,LN=vsm,CF=1,LNL=0,');
  replace_def_data("def-options-vsm",'4 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('vsm', 'vsm');
  LanguageSettings.setReferencedInLanguageIDs('vsm', "ansic c e m");

  // DB2
  replace_def_data("def-language-db2",'MN=DB2,TABS=+8,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_,LN=DB2,CF=1,LNL=0,');
  replace_def_data("def-options-db2",'4 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('db2', 'db2');
  LanguageSettings.setReferencedInLanguageIDs('db2', "ansic c cob cob2000 cob74 plsql sqlserver");

  // JCL
  replace_def_data("def-language-jcl",'MN=JCL,TABS=+8,MA=1 74 1,KEYTAB=jcl-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_$,LN=JCL,CF=1,LNL=0,TL=72');
  replace_def_data("def-options-jcl",'4 1 1 0 0 3 0');
  ExtensionSettings.setLangRefersTo('jcl', 'jcl');

  // Grep
  replace_def_data("def-language-grep",'MN=Grep,TABS=+4,MA=1 74 1,KEYTAB=grep-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_$,LN=,CF=4,');
  LanguageSettings.setMenuIfNoSelection('grep', '_grep_menu_default');
  LanguageSettings.setMenuIfSelection('grep', '_grep_menu_default');

  // Windows Resource File
  replace_def_data("def-language-rc",'MN=Windows Resource File,TABS=+4,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_,LN=Windows Resource File,CF=1,');
  ExtensionSettings.setLangRefersTo('rc', 'rc');

  // Module Definition File
  replace_def_data("def-language-def",'MN=Module-Definition File,TABS=+4,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=1,WC=A-Za-z0-9_,LN=Module-Definition File,CF=1,');
  ExtensionSettings.setLangRefersTo('def', 'def');

  replace_def_data("def-numbering-cob","2");
  replace_def_data("def-numbering-cob74","2");
  replace_def_data("def-numbering-cob2000","2");

  replace_def_data("def-numbering-cob","2");

  if(_isMac()) {
     // The mac has a very smart "open" command, which handles
     // file associations.
     _str macOpenCommand = 'open %f';
     setup_association('nib', 'NIB Bundle', '', 0, macOpenCommand);
     setup_association('xib', 'Interface Builder Cocoa Document', '', 0, macOpenCommand);
     setup_association('icns', 'Apple icon image', '', 0, macOpenCommand);
     setup_association('framework', 'Framework', '', 0, 'open %f');
     setup_association('app', 'Application', '', 0, 'open -a %f');
     setup_association('ico','Icon File','',0,macOpenCommand);
     setup_association('bmp','BMP','',0,macOpenCommand);
     setup_association('jpg','JPG','',0,macOpenCommand);
     setup_association('jpeg','JPG','',0,macOpenCommand);
     setup_association('xpm','XPM','',0,macOpenCommand);
     setup_association('xbm','XBM','',0,macOpenCommand);
     setup_association('gif','GIF','',0,macOpenCommand);
     setup_association('png','PNG','',0,macOpenCommand);
     setup_association('tif','TIF','',0,macOpenCommand);
     setup_association('tiff','TIF','',0,macOpenCommand);
     setup_association('ico','Icon File','',0,macOpenCommand);
     setup_association('bmp','BMP','',0,macOpenCommand);
     setup_association('jpg','JPG','',0,macOpenCommand);
     setup_association('jpeg','JPG','',0,macOpenCommand);
     setup_association('xpm','XPM','',0,macOpenCommand);
     setup_association('xbm','XBM','',0,macOpenCommand);
     setup_association('gif','GIF','',0,macOpenCommand);
     setup_association('png','PNG','',0,macOpenCommand);
     setup_association('tif','TIF','',0,macOpenCommand);
     setup_association('tiff','TIF','',0,macOpenCommand);
  } else {
      _str imageOpenCommand = 'gimp %f';
      setup_association('ico','Icon File','',1,imageOpenCommand);
      setup_association('bmp','BMP','',1,imageOpenCommand);
      setup_association('jpg','JPG','',1,imageOpenCommand);
      setup_association('jpeg','JPG','',1,imageOpenCommand);
      setup_association('xpm','XPM','',1,imageOpenCommand);
      setup_association('xbm','XBM','',1,imageOpenCommand);
      setup_association('gif','GIF','',1,imageOpenCommand);
      setup_association('png','PNG','',1,imageOpenCommand);
      setup_association('tif','TIF','',1,imageOpenCommand);
      setup_association('tiff','TIF','',1,imageOpenCommand);
      _str mediaPlayerCommand = 'mplayer %f';
      setup_association('wmv','Windows Movie','',1,mediaPlayerCommand);
      setup_association('mpeg','MPEG Movie','',1,mediaPlayerCommand);
      setup_association('avi','AVI Movie','',1,mediaPlayerCommand);
      setup_association('mp3','Sound File','',1,mediaPlayerCommand);
  }

  // Lots of file extensions that we point to binary
  ExtensionSettings.setLangRefersTo('ico', 'binary');
  ExtensionSettings.setLangRefersTo('bmp', 'binary');
  ExtensionSettings.setLangRefersTo('jpg', 'binary');
  ExtensionSettings.setLangRefersTo('jpeg', 'binary');
  ExtensionSettings.setLangRefersTo('gif', 'binary');
  ExtensionSettings.setLangRefersTo('png', 'binary');
  ExtensionSettings.setLangRefersTo('tif', 'binary');
  ExtensionSettings.setLangRefersTo('tiff', 'binary');

  ExtensionSettings.setLangRefersTo('wmv', 'binary');
  ExtensionSettings.setLangRefersTo('mpeg', 'binary');
  ExtensionSettings.setLangRefersTo('avi', 'binary');
  ExtensionSettings.setLangRefersTo('mp3', 'binary');

  ExtensionSettings.setLangRefersTo('bin', 'binary');
  ExtensionSettings.setLangRefersTo('ex', 'binary');
  ExtensionSettings.setLangRefersTo('dll', 'binary');
  ExtensionSettings.setLangRefersTo('exe', 'binary');
  ExtensionSettings.setLangRefersTo('lib', 'binary');
  ExtensionSettings.setLangRefersTo('obj', 'binary');
  ExtensionSettings.setLangRefersTo('so', 'binary');
  ExtensionSettings.setLangRefersTo('sl', 'binary');
  ExtensionSettings.setLangRefersTo('o', 'binary');
  ExtensionSettings.setLangRefersTo('a', 'binary');
  ExtensionSettings.setLangRefersTo('class', 'binary');
  ExtensionSettings.setLangRefersTo('winmd', 'binary');

  ExtensionSettings.setLangRefersTo('zip', 'binary');
  ExtensionSettings.setLangRefersTo('war', 'binary');
  ExtensionSettings.setLangRefersTo('jar', 'binary');
  ExtensionSettings.setLangRefersTo('rar', 'binary');
  ExtensionSettings.setLangRefersTo('tar', 'binary');
  ExtensionSettings.setLangRefersTo('gz', 'binary');
  ExtensionSettings.setLangRefersTo('z', 'binary');
  ExtensionSettings.setLangRefersTo('Z', 'binary');

  setup_association('zip','ZIP Archive','',1,'');
  setup_association('war','War file','',1,'');
  setup_association('jar','Java Jar file','',1,'');
  setup_association('rar','RAR Archive','',1,'');
  setup_association('tar','Unix tar archive','',1,'');
  setup_association('gz','GNU Compressed file','',1,'');
  setup_association('z','Compressed file','',1,'');
  setup_association('Z','Compressed file','',1,'');

  restore_search('',0,'[A-Za-z0-9_$]');
  _scroll_style('H 2');
  _cursor_shape('-v 450 1000 750 1000 450 1000 750 1000');
  _default_option('S',IGNORECASE_SEARCH|VSSEARCHFLAG_WRAP|PROMPT_WRAP_SEARCH);
  _cache_size('2000 -1');
  _insert_state(1,'d');
  _default_option('T','1');
  _default_option('H','2');
  _default_option('V','4');
  _insert_state('1','d');

  def_color_scheme_version = 0;
  _default_color(CFG_SELECTION,0x0,0xE0C0C0,0);
  _default_color(CFG_WINDOW_TEXT,0x0,0xFFFFFF,0);
  _default_color(CFG_CLINE,0xFF0000,0xC8FFFF,0);
  _default_color(CFG_SELECTED_CLINE,0xFF0000,0xC0D8D8,0);
  _default_color(CFG_MESSAGE,0x80000008,0x80000005,0);
  _default_color(CFG_STATUS,0x80000008,0x80000005,0);
  _default_color(CFG_CURSOR,0x0,0xC0C0C0,0);
  _default_color(CFG_ERROR,0xFFFFFF,0xFF,0);
  _default_color(CFG_MODIFIED_LINE,0xFFFFFF,0xFF,0);
  _default_color(CFG_INSERTED_LINE,0xFFFFFF,0x80,0);
  _default_color(CFG_KEYWORD,0x800080,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_LINENUM,0x808080,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_NUMBER,0x800000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_STRING,0x808000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_COMMENT,0x8000,0xFFFFFF,F_ITALIC|F_INHERIT_BG_COLOR);
  _default_color(CFG_PPKEYWORD,0x8080,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_PUNCTUATION,0x80,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_LIBRARY_SYMBOL,0x40C0,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_OPERATOR,0x0,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_USER_DEFINED,0x804000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_IMAGINARY_LINE,0x606060,0xFFFF80,0);
  _default_color(CFG_FUNCTION,0x0,0xFFFFFF,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(CFG_LINEPREFIXAREA,0x0,0xFFF0F0,0);
  _default_color(CFG_FILENAME,0x0,0xC0C0C0,0);
  _default_color(CFG_HILIGHT,0x0,0xC0C0C0,0);
  _default_color(CFG_ATTRIBUTE,0x0,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_UNKNOWNXMLELEMENT,0x80FF,0xFFFFFF,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(CFG_XHTMLELEMENTINXSL,0x8080,0xFFFFFF,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(CFG_SPECIALCHARS,0xC0C0C0,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_CURRENT_LINE_BOX,0xFF8080,0xFF8080,0);
  _default_color(CFG_VERTICAL_COL_LINE,0x8080FF,0x8080FF,0);
  _default_color(CFG_MARGINS_COL_LINE,0x808080,0x808080,0);
  _default_color(CFG_TRUNCATION_COL_LINE,0xFF,0xFF,0);
  _default_color(CFG_PREFIX_AREA_LINE,0xC0C0C0,0xC0C0C0,0);
  _default_color(CFG_BLOCK_MATCHING,0xFF0000,0xFFFFFF,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(CFG_INC_SEARCH_CURRENT,0x0,0xFFFF80,0);
  _default_color(CFG_INC_SEARCH_MATCH,0x0,0x80FFFF,0);
  _default_color(CFG_HEX_MODE_COLOR,0x80,0xF0F0F0,0);
  _default_color(CFG_SYMBOL_HIGHLIGHT,0xFF0000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_MODIFIED_ITEM,0xFF,0xFFFFFF,0);
  _default_color(CFG_LINE_COMMENT,0x8000,0xFFFFFF,F_ITALIC|F_INHERIT_BG_COLOR);
  _default_color(CFG_DOCUMENTATION,0x804000,0xFFFFFF,F_ITALIC|F_INHERIT_BG_COLOR);
  _default_color(CFG_DOC_KEYWORD,0x5C3000,0xFFFFFF,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(CFG_DOC_PUNCTUATION,0x404040,0xFFFFFF,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(CFG_DOC_ATTRIBUTE,0x0,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_DOC_ATTR_VALUE,0x406000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_IDENTIFIER,0x0,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_FLOATING_NUMBER,0x803030,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_HEX_NUMBER,0x800000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_SINGLEQUOTED_STRING,0x606000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_BACKQUOTED_STRING,0x808000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_UNTERMINATED_STRING,0x808000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_INACTIVE_CODE,0x808080,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_INACTIVE_KEYWORD,0x808080,0xFFFFFF,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(CFG_INACTIVE_COMMENT,0x808080,0xFFFFFF,F_ITALIC|F_INHERIT_BG_COLOR);
  _default_color(CFG_IMAGINARY_SPACE,0x8000,0xFF80,0);
  _default_color(CFG_NAVHINT,0x0080FF,0xFFFFFF,0);
  _default_color(CFG_SEARCH_RESULT_TRUNCATED,0xC0C0C0,0xFFFFFF,0);
  _default_color(CFG_MARKDOWN_HEADER,0x800080,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_MARKDOWN_CODE,0x808000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_MARKDOWN_BLOCKQUOTE,0x40C0,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_MARKDOWN_LINK,0x800000,0xFFFFFF,F_INHERIT_BG_COLOR);
  _default_color(CFG_DOCUMENT_TAB_ACTIVE, 0x80000008, 0x80000005, 0);
  _default_color(CFG_DOCUMENT_TAB_MODIFIED, 0x80000008, 0x80000005, 0);
  _default_color(CFG_DOCUMENT_TAB_SELECTED, 0x80000008, 0x80000005, 0);
  _default_color(CFG_DOCUMENT_TAB_UNSELECTED, 0x80000008, 0x80000005, 0);

  _default_color(-CFG_SELECTION,0x0,0xCCB0B0,0);
  _default_color(-CFG_WINDOW_TEXT,0x0,0xD8D8D8,0);
  _default_color(-CFG_CLINE,0xFF0000,0xC0E0E0,0);
  _default_color(-CFG_SELECTED_CLINE,0xFF0000,0xA0BCBC,0);
  _default_color(-CFG_CURSOR,0x0,0x909090,0);
  _default_color(-CFG_ERROR,0xFFFFFF,0xFF,0);
  _default_color(-CFG_MODIFIED_LINE,0xFFFFFF,0xCF,0);
  _default_color(-CFG_INSERTED_LINE,0xFFFFFF,0x3030B0,0);
  _default_color(-CFG_KEYWORD,0x800080,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_LINENUM,0x808080,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_NUMBER,0x800000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_STRING,0x808000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_COMMENT,0x8000,0xD8D8D8,F_ITALIC|F_INHERIT_BG_COLOR);
  _default_color(-CFG_PPKEYWORD,0x8080,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_PUNCTUATION,0x80,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_LIBRARY_SYMBOL,0x40C0,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_OPERATOR,0x0,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_USER_DEFINED,0x804000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_IMAGINARY_LINE,0x606060,0xFFFF00,0);
  _default_color(-CFG_FUNCTION,0x0,0xD8D8D8,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(-CFG_FILENAME,0x0,0xA0A0A0,0);
  _default_color(-CFG_HILIGHT,0x0,0xA0A0A0,0);
  _default_color(-CFG_ATTRIBUTE,0x0,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_UNKNOWNXMLELEMENT,0x80FF,0xD8D8D8,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(-CFG_XHTMLELEMENTINXSL,0x8080,0xD8D8D8,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(-CFG_SPECIALCHARS,0xC0C0C0,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_BLOCK_MATCHING,0xFF0000,0xD8D8D8,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(-CFG_INC_SEARCH_CURRENT,0x0,0xCFCF50,0);
  _default_color(-CFG_INC_SEARCH_MATCH,0x0,0x50CFCF,0);
  _default_color(-CFG_HEX_MODE_COLOR,0x80,0xC8C8C8,0);
  _default_color(-CFG_SYMBOL_HIGHLIGHT,0xFF0000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_LINE_COMMENT,0x8000,0xD8D8D8,F_ITALIC|F_INHERIT_BG_COLOR);
  _default_color(-CFG_DOCUMENTATION,0x804000,0xD8D8D8,F_ITALIC|F_INHERIT_BG_COLOR);
  _default_color(-CFG_DOC_KEYWORD,0x5C3000,0xD8D8D8,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(-CFG_DOC_PUNCTUATION,0x404040,0xD8D8D8,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(-CFG_DOC_ATTRIBUTE,0x0,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_DOC_ATTR_VALUE,0x406000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_IDENTIFIER,0x0,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_FLOATING_NUMBER,0x803030,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_HEX_NUMBER,0x800000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_SINGLEQUOTED_STRING,0x606000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_BACKQUOTED_STRING,0x808000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_UNTERMINATED_STRING,0x808000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_INACTIVE_CODE,0x808080,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_INACTIVE_KEYWORD,0x808080,0xD8D8D8,F_BOLD|F_INHERIT_BG_COLOR);
  _default_color(-CFG_INACTIVE_COMMENT,0x808080,0xD8D8D8,F_ITALIC|F_INHERIT_BG_COLOR);
  _default_color(-CFG_IMAGINARY_SPACE,0x8000,0xFF00,0);
  _default_color(-CFG_XML_CHARACTER_REF,0x800000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_SEARCH_RESULT_TRUNCATED,0xC0C0C0,0xD8D8D8,0);
  _default_color(-CFG_MARKDOWN_HEADER,0x800080,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_MARKDOWN_CODE,0x808000,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_MARKDOWN_BLOCKQUOTE,0x40C0,0xD8D8D8,F_INHERIT_BG_COLOR);
  _default_color(-CFG_MARKDOWN_LINK,0x800000,0xD8D8D8,F_INHERIT_BG_COLOR);
  def_color_scheme = "Default";

  /* call mou_config('1 0 1996554239 0') */
  _default_option('D',0);
  def_updown_screen_lines=true;
  _SoftWrapUpdateAll(0,1);

  def_toolbar_options=0;
  def_toolbar_autohide_delay=TBAUTOHIDE_DELAY_DEFAULT;
  def_dock_channel_options=0;
  def_dock_channel_delay=DOCKCHANNEL_AUTO_DELAY;

#if __UNIX__
  def_vim_change_cursor=false;
#else
  def_vim_change_cursor=true;
#endif
  def_vim_esc_codehelp=false;
  def_vim_stay_in_ex_prmpt=true;
  def_vim_start_in_cmd_mode=false;

  def_project_auto_build = false;
  // Completion e and edit lists binary files
  def_list_binary_files=true;
  // Select comments when using select_proc
  def_select_proc_flags=0;
  def_select_type_block=false;

  // number of MRU document modes and project types to display on New File/Project dialog.
  def_max_doc_mode_mru = 5;
  def_max_proj_type_mru = 5;
}
static void setup_association(_str extension,_str ModeName,_str WinAppCmdLine,boolean WinUseFileAssociation,_str UnixAppCmdLine)
{
#if __UNIX__
   ExtensionSettings.setUseFileAssociation(extension, false);
   ExtensionSettings.setOpenApplication(extension, UnixAppCmdLine);
#else
   ExtensionSettings.setUseFileAssociation(extension, WinUseFileAssociation);
   ExtensionSettings.setOpenApplication(extension, WinAppCmdLine);
#endif
}
