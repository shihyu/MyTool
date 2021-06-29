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
#import "main.e"
#import "recmacro.e"
#import "search.e"
#import "stdprocs.e"
#import "toolbar.e"
#endregion

///////////////////////////////////////////////////////////////////////////////
// This macro is used to update the user's vusrobjs.e file to work
// properly with version 10.0 or higher of the editor.
// 
// The main objective is to map the toolbar bitmaps
// to the new toolbar icon files.
// 
// The second objective is to rename their customized toolbars
// to 'old' so that they will get the changes in their new toolbars.
// 

// Map standard toolbar names to 'old' toolbar names
static _str gFormMap:[] = {
   "_tbstandard_form"        => "old_tbstandard_form",
   "_tbtagging_form"         => "old_tbtagging_form",
   "_tbdebugbb_form"         => "old_tbdebugbb_form",
   "_tbedit_form"            => "old_tbedit_form",
   "_tbvc_form"              => "old_tbvc_form",
};

// Map old bitmap names to new bitmap names
static _str gBitmapMap:[] = {
   "bbapi"               => "bbapi_index",
   "bbbeauty"            => "bbbeautify",
   "bbbkshfl"            => "bbshift_left",
   "bbbkshfr"            => "bbshift_right",
   "bbblank"             => "bbblank",
   "bbbottom"            => "bbbottom",
   "bbbuflst"            => "bblist_buffers",
   "bbcalc"              => "bbcalculator",
   "bbcascd"             => "bbcascade",
   "bbcbfind"            => "bbclass_browser_find",
   "bbchkin"             => "bbcheckin",
   "bbchkout"            => "bbcheckout",
   "bbcomp"              => "bbcompile",
   "bbcopy"              => "bbcopy",
   "bbcprmt"             => "bbshell",
   "bbcut"               => "bbcut",
   "bbdbgaddwatch"       => "bbdebug_add_watch",
   "bbdbgbreakpoints"    => "bbdebug_breakpoints",
   "bbdbgclearbp"        => "bbdebug_clear_breakpoints",
   "bbdbgclearex"        => "bbdebug_clear_exceptions",
   "bbdbgcontinue"       => "bbdebug_continue",
   "bbdbgdisablebp"      => "bbdebug_disable_breakpoints",
   "bbdbgdisableex"      => "bbdebug_disable_exceptions",
   "bbdbgdown"           => "bbdebug_down",
   "bbdbgexceptions"     => "bbdebug_exceptions",
   "bbdbggotopc"         => "bbdebug_show_next_statement",
   "bbdbgrestart"        => "bbdebug_restart",
   "bbdbgruncursor"      => "bbdebug_run_to_cursor",
   "bbdbgstepdeep"       => "bbdebug_step_deep",
   "bbdbgstepinstr"      => "bbdebug_step_instruction",
   "bbdbgstepinto"       => "bbdebug_step_into",
   "bbdbgstepout"        => "bbdebug_step_out",
   "bbdbgstepover"       => "bbdebug_step_over",
   //"bbdbgsteppast"       => "bbdebug_step_past",
   "bbdbgstop"           => "bbdebug_stop",
   "bbdbgsuspend"        => "bbdebug_suspend",
   "bbdbgtoggle3"        => "bbdebug_toggle_breakpoint3",
   "bbdbgtogglebp"       => "bbdebug_toggle_breakpoint",
   "bbdbgtoggleen"       => "bbdebug_toggle_enabled",
   "bbdbgtoggleex"       => "bbdebug_add_exception",
   "bbdbgtop"            => "bbdebug_top",
   "bbdbgup"             => "bbdebug_up",
   "bbdbgvcrcontinue"    => "bbdebug_continue",
   "bbdbgvcrrestart"     => "bbdebug_restart",
   "bbdebug"             => "bbdebug",
   "bbdiff"              => "bbdiff",
   "bbexec"              => "bbexecute",
   "bbexit"              => "bbexit",
   "bbfcthlp"            => "bbfunction_help",
   "bbffile"             => "bbfind_file",
   //"bbfilcmp"            => "bbfile_compare",
   "bbfind"              => "bbfind",
   "bbfindn"             => "bbfind_next",
   "bbfindp"             => "bbfind_prev",
   "bbfnfile"            => "bbfind_file",
   "bbfnhdr"             => "bbshow_procs",
   "bbftp"               => "bbftp",
   "bbfword"             => "bbfind_word",
   "bbgobmk"             => "bbbookmarks",
   "bbhexed"             => "bbhex",
   "bbhidcbk"            => "bbhide_code_block",
   "bbhidsel"            => "bbhide_selection",
   "bbhtanchor"          => "bbhtml_anchor",
   "bbhtapplet"          => "bbhtml_applet",
   "bbhtbody"            => "bbhtml_body",
   "bbhtbold"            => "bbhtml_bold",
   "bbhtcaption"         => "bbhtml_table_caption",
   "bbhtcenter"          => "bbhtml_center",
   "bbhtcode"            => "bbhtml_code",
   //"bbhtem"              => "bbhtml_emphasis",
   "bbhtfont"            => "bbhtml_font",
   "bbhtfont2"           => "bbhtml_font",
   "bbhthead"            => "bbhtml_head",
   "bbhthead3"           => "bbhtml_head",
   "bbhtheader"          => "bbhtml_table_header",
   "bbhthline"           => "bbhtml_hline",
   "bbhtimage"           => "bbhtml_image",
   "bbhtitalic"          => "bbhtml_italic",
   "bbhtlink"            => "bbhtml_link",
   "bbhtlist"            => "bbhtml_list",
   //"bbhtoption"          => "bbhtml_option",
   "bbhtparagraph"       => "bbhtml_paragraph",
   "bbhtrgbcolor"        => "bbhtml_rgb_color",
   "bbhtright"           => "bbhtml_right",
   "bbhtscript"          => "bbhtml_script",
   "bbhtstyle"           => "bbhtml_style",
   "bbhttable"           => "bbhtml_table",
   "bbhttarget"          => "bbhtml_anchor",
   "bbhttcol"            => "bbhtml_table_cell",
   "bbhttrow"            => "bbhtml_table_row",
   "bbhtuline"           => "bbhtml_underline",
   "bbhtview"            => "bbhtml_preview",
   "bbisel"              => "bbindent_selection",
   "bblcase"             => "bblowcase",
   //"bblistds"            => "bblist_data_sets",
   //"bblistjb"            => "bblist_jobs",
   "bblstclp"            => "bbclipboards",
   "bblstmem"            => "bblist_symbols",
   "bbmake"              => "bbmake",
   "bbmax"               => "bbmaximize_window",
   "bbmenued"            => "bbmenu_editor",
   "bbmerge"             => "bbmerge",
   "bbminall"            => "bbiconize_all",
   "bbmktags"            => "bbmake_tags",
   "bbmplay"             => "bbmacro_execute",
   "bbmrec"              => "bbmacro_record",
   "bbnew"               => "bbnew",
   "bbnexter"            => "bbnext_error",
   "bbnfunc"             => "bbnext_tag",
   "bbnxtbuf"            => "bbnext_buffer",
   "bbnxtwin"            => "bbnext_window",
   "bbopen"              => "bbopen",
   "bbpaste"             => "bbpaste",
   "bbpfunc"             => "bbprev_tag",
   "bbpgdn"              => "bbpage_down",
   "bbpgup"              => "bbpage_up",
   "bbpmatch"            => "bbfind_matching_paren",
   "bbpoptag"            => "bbpop_tag",
   "bbprint"             => "bbprint",
   "bbprvbuf"            => "bbprev_buffer",
   "bbprvwin"            => "bbprev_window",
   "bbptag"              => "bbprev_tag",
   "bbqmark"             => "bbsdkhelp",
   "bbredo"              => "bbredo",
   "bbreflow"            => "bbreflow",
   "bbrefs"              => "bbfind_refs",
   "bbreplac"            => "bbreplace",
   "bbs2t"               => "bbspaces_to_tabs",
   "bbsave"              => "bbsave",
   "bbselcbk"            => "bbselect_code_block",
   "bbseldis"            => "bbselective_display",
   "bbsetbmk"            => "bbset_bookmark",
   "bbshall"             => "bbshow_all",
   "bbsmrec"             => "bbmacro_stop",
   "bbspell"             => "bbspell",
   "bbstepover"          => "bbdebug_step_over",
   "bbt2s"               => "bbtabs_to_spaces",
   "bbtbed"              => "bbtoolbars",
   "bbtileh"             => "bbtile_horizontal",
   "bbtilev"             => "bbtile_vertical",
   "bbtool1"             => "bbtool08",
   "bbtool2"             => "bbtool09",
   "bbtool3"             => "bbtool26",
   "bbtool4"             => "bbtool27",
   "bbtool5"             => "bbtool08",
   "bbtool6"             => "bbtool08",
   "bbtool7"             => "bbtool08",
   "bbtool8"             => "bbtool08",
   "bbtool9"             => "bbtool08",
   "bbtop"               => "bbtop",
   "bbuisel"             => "bbunindent_selection",
   "bbundo"              => "bbundo",
   "bbupcase"            => "bbupcase",
   "bbvcflk"             => "bbvc_lock",
   "bbvcfulk"            => "bbvc_unlock",
   "bbvclver"            => "bbvc_history",
   "bbvcvdif"            => "bbvc_diff",
   "bbvsehelp"           => "bbvsehelp",
   "bbxmlval"            => "bbxml_validate",
   "bbxmlwel"            => "bbxml_wellformedness",

   // other bitmaps
   "_add"                          => "bbadd",
   "_arrow_down_blue"              => "bbdown",
   "_arrow_up_blue"                => "bbup",
   "_arrowlt"                      => "_f_arrow_lt",
   "_arrowgt"                      => "_f_arrow_gt",
   "_arrowc"                       => "_f_arrow_right",
   "_bh_project"                   => "_f_project",
   "_bh_workspace"                 => "_f_workspace",
   "_bh_vccommit"                  => "_f_doc_checked",
   "_bh_vcupdate"                  => "_f_doc_copied",
   "_browse"                       => "bbbrowse",
   "_browse2"                      => "bbbrowse",
   "_filter"                       => "bbfilter",
   "_modify"                       => "bbedit",
   "_menuedit"                     => "bbmenu",
   "_drcd2"                        => "_f_drive_cd",
   "_drcdrom"                      => "_f_drive_cd",
   "_drfix2"                       => "_f_drive",
   "_drfix2_mac"                   => "_f_drive",
   "_drfixed"                      => "_f_drive",
   "_drflop"                       => "_f_drive_floppy",
   "_drremote"                     => "_f_drive_network",
   "_drremov"                      => "_f_drive_floppy",
   "_favorites"                    => "_f_favorite",
   "_network"                      => "_f_network",
   "_server"                       => "_f_server",
   "_lock"                         => "_f_lock",
   "_smfunc"                       => "_sym_func",
   "_smfiled"                      => "_f_doc_disabled",
   "_smfile"                       => "_f_doc",
   "_func"                         => "_sym_func",
   "_stop0"                        => "_f_stop",
   "_class_split"                  => "bbhsplit_window",
   "_cbodots"                      => "bbbrowse",
   "_cbldots"                      => "bbbrowse",
   "_cbdots"                       => "bbbrowse",
   "_cbdis"                        => "bbmenudown",
   "_cbarrow"                      => "bbmenudown",
   "_cboarro"                      => "bbmenudown",
   "_cboarrl"                      => "bbmenudown",
   "_cbmenu"                       => "bbmenudown",
   "_cbck"                         => "bbcheckbox",
   "_cbckdc"                       => "bbcheckbox",
   "_cbckonly"                     => "bbxml_wellformedness",
   "_cbblack"                      => "_f_blank",
   "_cbblank"                      => "_f_blank",
   "_treesave_blank"               => "_f_blank",
   "_treesave"                     => "_f_save",
   "_computer"                     => "_f_computer",
   "_computer_mac"                 => "_f_computer",
   "_printer"                      => "_f_printer",
   "_drnetwk"                      => "_f_drive_network",
   "_filter"                       => "bbfilter",
   "_refresh"                      => "bbrefresh",
   "_refreshn"                     => "bbrefresh",
   "_cb3state"                     => "bbbox",
   "_cbgray"                       => "bbbox",
   "_clsabs0"                      => "_sym_class",
   "_clsabs1"                      => "_sym_class",
   "_clsabs2"                      => "_sym_class",
   "_clsabs3"                      => "_sym_class",
   "_clsann0"                      => "_sym_annotation",
   "_clsant0"                      => "_sym_annotation",
   "_clsant1"                      => "_sym_annotype",
   "_clsant2"                      => "_sym_annotype",
   "_clsant3"                      => "_sym_annotype",
   "_clsasn0"                      => "_sym_assign",
   "_clsatg0"                      => "_sym_target",
   "_clsblk0"                      => "_sym_block",
   "_clscla0"                      => "_sym_clause",
   "_clscls0"                      => "_sym_class",
   "_clscls1"                      => "_sym_class",
   "_clscls2"                      => "_sym_class",
   "_clscls3"                      => "_sym_class",
   "_clscns0"                      => "_sym_constructor",
   "_clscns1"                      => "_sym_constructor",
   "_clscns2"                      => "_sym_constructor",
   "_clscns3"                      => "_sym_constructor",
   "_clscon0"                      => "_sym_constant",
   "_clscon1"                      => "_sym_constant",
   "_clscon2"                      => "_sym_constant",
   "_clscon3"                      => "_sym_constant",
   "_clscrs0"                      => "_sym_cursor",
   "_clsctl0"                      => "_sym_control",
   "_clsctp0"                      => "_sym_constrproto",
   "_clsctp1"                      => "_sym_constrproto",
   "_clsctp2"                      => "_sym_constrproto",
   "_clsctp3"                      => "_sym_constrproto",
   "_clsdat0"                      => "_sym_var",
   "_clsdat1"                      => "_sym_var",
   "_clsdat2"                      => "_sym_var",
   "_clsdat3"                      => "_sym_var",
   "_clsdbs0"                      => "_sym_database",
   "_clsdef0"                      => "_sym_define",
   "_clsdir0"                      => "_sym_dir",
   "_clsdst0"                      => "_sym_destructor",
   "_clsdst1"                      => "_sym_destructor",
   "_clsdst2"                      => "_sym_destructor",
   "_clsdst3"                      => "_sym_destructor",
   "_clsdtp0"                      => "_sym_destrproto",
   "_clsdtp1"                      => "_sym_destrproto",
   "_clsdtp2"                      => "_sym_destrproto",
   "_clsdtp3"                      => "_sym_destrproto",
   "_clsenm0"                      => "_sym_enumc",
   "_clsenm1"                      => "_sym_enumc",
   "_clsenm2"                      => "_sym_enumc",
   "_clsenm3"                      => "_sym_enumc",
   "_clsens0"                      => "_sym_enum",
   "_clsens1"                      => "_sym_enum",
   "_clsens2"                      => "_sym_enum",
   "_clsens3"                      => "_sym_enum",
   "_clsetb0"                      => "_sym_eventtab",
   "_clsevt0"                      => "_sym_event",
   "_clsfil0"                      => "_sym_file",
   "_clsfrm0"                      => "_sym_form",
   "_clsfrn0"                      => "_sym_friend",
   "_clsfun0"                      => "_sym_func",
   "_clsfun1"                      => "_sym_func",
   "_clsfun2"                      => "_sym_func",
   "_clsfun3"                      => "_sym_func",
   "_clsgrp0"                      => "_sym_group",
   "_clsgrp1"                      => "_sym_group",
   "_clsgrp2"                      => "_sym_group",
   "_clsgrp3"                      => "_sym_group",
   "_clsimp0"                      => "_sym_import",
   "_clsinc0"                      => "_sym_include",
   "_clsint0"                      => "_sym_interface",
   "_clsint1"                      => "_sym_interface",
   "_clsint2"                      => "_sym_interface",
   "_clsint3"                      => "_sym_interface",
   "_clslab0"                      => "_sym_label",
   "_clsmen0"                      => "_sym_menu",
   "_clsmss0"                      => "_sym_unknown",
   "_clsmss1"                      => "_sym_unknown",
   "_clsmss2"                      => "_sym_unknown",
   "_clsmss3"                      => "_sym_unknown",
   "_clsndx0"                      => "_sym_index",
   "_clsopp0"                      => "_sym_operproto",
   "_clsopp1"                      => "_sym_operproto",
   "_clsopp2"                      => "_sym_operproto",
   "_clsopp3"                      => "_sym_operproto",
   "_clsopr0"                      => "_sym_operator",
   "_clsopr1"                      => "_sym_operator",
   "_clsopr2"                      => "_sym_operator",
   "_clsopr3"                      => "_sym_operator",
   "_clsoth0"                      => "_sym_other",
   "_clsoth1"                      => "_sym_other",
   "_clsoth2"                      => "_sym_other",
   "_clsoth3"                      => "_sym_other",
   "_clspks0"                      => "_sym_package",
   "_clsppt0"                      => "_sym_procproto",
   "_clsppt1"                      => "_sym_procproto",
   "_clsppt2"                      => "_sym_procproto",
   "_clsppt3"                      => "_sym_procproto",
   "_clsprc0"                      => "_sym_proc",
   "_clsprc1"                      => "_sym_proc",
   "_clsprc2"                      => "_sym_proc",
   "_clsprc3"                      => "_sym_proc",
   "_clsprm0"                      => "_sym_parameter",
   "_clsprp0"                      => "_sym_property",
   "_clsprp1"                      => "_sym_property",
   "_clsprp2"                      => "_sym_property",
   "_clsprp3"                      => "_sym_property",
   "_clsprt0"                      => "_sym_proto",
   "_clsprt1"                      => "_sym_proto",
   "_clsprt2"                      => "_sym_proto",
   "_clsprt3"                      => "_sym_proto",
   "_clsqry0"                      => "_sym_query",
   "_clssbk0"                      => "_sym_break",
   "_clsscl0"                      => "_sym_call",
   "_clsscn0"                      => "_sym_continue",
   "_clssel0"                      => "_sym_selector",
   "_clssfn0"                      => "_sym_call",
   "_clssgt0"                      => "_sym_goto",
   "_clssif0"                      => "_sym_if",
   "_clsslp0"                      => "_sym_loop",
   "_clsspp0"                      => "_sym_preprocessing",
   "_clsspr0"                      => "_sym_preprocessing",
   "_clssrt0"                      => "_sym_return",
   "_clssse0"                      => "_sym_staticselector",
   "_clssta0"                      => "_sym_statement",
   "_clsstr0"                      => "_sym_try",
   "_clssts0"                      => "_sym_struct",
   "_clssts1"                      => "_sym_struct",
   "_clssts2"                      => "_sym_struct",
   "_clssts3"                      => "_sym_struct",
   "_clstag0"                      => "_sym_tag",
   "_clstbl0"                      => "_sym_table",
   "_clstps0"                      => "_sym_class",
   "_clstps1"                      => "_sym_class",
   "_clstps2"                      => "_sym_class",
   "_clstps3"                      => "_sym_class",
   "_clstrg0"                      => "_sym_trigger",
   "_clstsk0"                      => "_sym_task",
   "_clstyp0"                      => "_sym_typedef",
   "_clstyp1"                      => "_sym_typedef",
   "_clstyp2"                      => "_sym_typedef",
   "_clstyp3"                      => "_sym_typedef",
   "_clsund0"                      => "_sym_undefine",
   "_clsunk0"                      => "_sym_unknown",
   "_clsuns0"                      => "_sym_union",
   "_clsuns1"                      => "_sym_union",
   "_clsuns2"                      => "_sym_union",
   "_clsuns3"                      => "_sym_union",
   "_clsusr0"                      => "_sym_user_defined",
   "_cvs_file"                     => "_f_doc",
   "_cvs_file_conflict"            => "_f_doc_warning",
   "_cvs_file_conflict_local_add"  => "_f_doc_conflict_add",
   "_cvs_file_conflict_local_del"  => "_f_doc_conflict_delete",
   "_cvs_file_conflict_updated"    => "_f_doc_conflict_updated",
   "_cvs_file_copied"              => "_f_doc_copied",
   "_cvs_file_date"                => "_f_doc_updateable",
   "_cvs_file_error"               => "_f_doc_error",
   "_cvs_file_m"                   => "_f_doc_delete",
   "_cvs_file_m_mod"               => "_f_doc_modified_delete",
   "_cvs_file_mod"                 => "_f_doc_modified",
   "_cvs_file_mod_date"            => "_f_doc_modified_updateable",
   "_cvs_file_new"                 => "_f_doc_new",
   "_cvs_file_not_merged"          => "_f_doc_error",
   "_cvs_file_obsolete"            => "_f_doc_obsolete",
   "_cvs_file_p"                   => "_f_doc_add",
   "_cvs_file_qm"                  => "_f_doc_unknown",
   "_cvs_fld_date"                 => "_f_folder_updateable",
   "_cvs_fld_error"                => "_f_folder_error",
   "_cvs_fld_m"                    => "_f_folder_delete",
   "_cvs_fld_mod"                  => "_f_folder_modified",
   "_cvs_fld_new"                  => "_f_folder_active",
   "_cvs_fld_obsolete"             => "_f_folder_delete",
   "_cvs_fld_p"                    => "_f_folder_add",
   "_cvs_fld_qm"                   => "_f_folder_unknown",
   "_cvsbranch2"                   => "_f_branch",
   "_deleten"                      => "bbdelete",
   "_diff_all_symbols"             => "_f_diff_all_symbols",
   "_diff_code"                    => "bbhtml_code",
   "_diff_code_del"                => "bbtext",
   "_diff_doc"                     => "_f_doc",
   "_diff_doc_del"                 => "_f_doc_delete",
   "_diff_one_symbol"              => "_f_diff_one_symbol",
   "_diff_path_del_link"           => "bbhtml_unlink",
   "_diff_path_link"               => "bbhtml_link",
   "_diffd"                        => "_f_doc_modified",
   "_diffd2"                       => "_f_doc_modified_and_viewed",
   "_diffm"                        => "_f_doc_delete",
   "_diffmoved"                    => "_f_diff_moved",
   "_diffopm"                      => "_f_folder_delete",
   "_diffopp"                      => "_f_folder_add",
   "_diffp"                        => "_f_doc_add",
   "_doc"                          => "_f_doc",
   "_docd"                         => "_f_doc_disabled",
   "_docg"                         => "_f_doc_readonly",
   "_doctarget"                    => "_f_target",
   "_docvc"                        => "_f_doc_vc",
   "_docvcc"                       => "_f_doc_vc_user",
   "_docvccg"                      => "_f_doc_vc_readonly",
   "_docvccm"                      => "_f_doc_vc_user",
   "_docvccx"                      => "_f_doc_readonly_locked",
   "_docvcg"                       => "_f_doc_checked_readonly",
   "_docvcrm"                      => "_f_doc_vc_user_readonly",
   "_docvcwx"                      => "_f_doc_locked",
   "_fbarrowleft"                  => "bbleft",
   "_fbarrowright"                 => "bbright",
   "_fbarrowup"                    => "bbup",
   "_fbarrowdown"                  => "bbdown",
   "_file"                         => "_f_doc",
   "_file12"                       => "_f_doc",
   "_file_buf_mod"                 => "_f_doc_modified",
   "_file_checkout_overlay"        => "_f_overlay_checked",
   "_file_date_overlay"            => "_f_overlay_updateable",
   "_file_lock"                    => "_f_doc_locked",
   "_file_mod"                     => "_f_doc_modified",
   "_file_mod_overlay"             => "_f_overlay_modified",
   "_file_reload_overlay"          => "_f_overlay_new",
   "_filed"                        => "_f_doc_disabled",
   "_filed12"                      => "_f_doc_disabled",
   "_filedisk"                     => "_f_doc",
   "_filedisko"                    => "_f_doc_updateable",
   "_filefwk"                      => "_f_framework",
   "_filehist"                     => "_f_doc_history",
   "_filehisto"                    => "_f_doc_history",
   "_filemch"                      => "_f_doc_matches",
   "_filemod12"                    => "_f_doc_modified",
   "_filenew"                      => "_f_doc_new",
   "_fileo"                        => "_f_doc_updateable",
   "_fileprj"                      => "_f_doc_in_project",
   "_fileprjo"                     => "_f_doc_in_project",
   "_filewksp"                     => "_f_doc_in_workspace",
   "_filewkspo"                    => "_f_doc_in_workspace",
   "_filexib"                      => "_f_interface",
   "_filexr"                       => "_f_references",
   "_fldaop"                       => "_f_folder_active",
   "_fldcdup"                      => "_f_folder_up",
   "_fldcdup_mac"                  => "_f_folder_up",
   "_fldclos"                      => "_f_folder",
   "_fldclos12"                    => "_f_folder",
   "_fldclos12_mac"                => "_f_folder",
   "_fldclos_mac"                  => "_f_folder",
   "_fldctags"                     => "_f_folder_tags",
   "_fldnib"                       => "_f_form",
   "_fldopen"                      => "_f_folder",
   "_fldopen12"                    => "_f_folder",
   "_fldopen12_mac"                => "_f_folder",
   "_fldopen_mac"                  => "_f_folder",
   "_fldtags"                      => "_f_folder_tags",
   "_ftpcdup"                      => "_f_folder_up",
   "_ftpfild"                      => "_f_doc_disabled",
   "_ftpfile"                      => "_f_doc", 
   "_ftpfod"                       => "_f_folder_disabled",
   "_ftpfold"                      => "_f_folder", 
   "_ftplfil"                      => "_f_doc_link", 
   "_ftplfol"                      => "_f_folder_link", 
   "_mouse"                        => "bbmouse", 
   "_vc_floatingdate"              => "_f_calendar",
   "_vc_user"                      => "_f_user",
   "_vc_label"                     => "_f_label",
   "_website"                      => "_f_website", 
   "_preview_horizontal"           => "bbstack_horizontal",
   "_preview_hybrid"               => "bbpreview_three_pane_left",
   "_preview_standard"             => "bbpreview_three_pane_up",
   "_preview_vertical"             => "bbstack_vertical",
   "_project"                      => "_f_project",
   "_references_list"              => "bbone_window",
   "_references_split"             => "bbvsplit_window",
   "_reload_file_buf_mod"          => "_f_doc_modified_updateable",
   "_reload_file_del"              => "_f_doc_delete",
   "_reload_file_mod"              => "_f_doc_modified",
   "_symbold"                      => "_f_symbol_modified",
   "_symbold2"                     => "_f_symbol_modified_and_viewed",
   "_symbolm"                      => "_f_symbol_delete",
   "_symbolmch"                    => "_f_symbol_matches",
   "_symbolp"                      => "_f_symbol_add",
   "_tbdiff"                       => "bbdiff",
   "_tfldcls"                      => "_f_folder",
   "_tfldclsd"                     => "_f_folder_delete",
   "_tfldopn"                      => "_f_folder",
   "_tfldopnd"                     => "_f_folder_delete",
   "_tpkgcls"                      => "_f_package",
   "_ut_class"                     => "_sym_class",
   "_ut_class_error"               => "_sym_class",
   "_ut_class_failure"             => "_sym_class",
   "_ut_class_notrun"              => "_sym_class",
   "_ut_class_passed"              => "_sym_class",
   "_ut_defect_trace"              => "bbtext",
   "_ut_defects_tab"               => "tbdebug_sessions",
   "_ut_error"                     => "_f_error",
   "_ut_error_not_icon"            => "_f_error",
   "_ut_failure"                   => "_f_bug",
   "_ut_failure_not_icon"          => "_f_bug",
   "_ut_hierarchy_tab"             => "tbinfo",
   "_ut_information"               => "_f_info",
   "_ut_method"                    => "_sym_func",
   "_ut_method_error"              => "_sym_func",
   "_ut_method_failure"            => "_sym_func",
   "_ut_method_notrun"             => "_sym_func",
   "_ut_method_passed"             => "_sym_func",
   "_ut_notrun_not_icon"           => "_f_warning",
   "_ut_package"                   => "_sym_package",
   "_ut_package_error"             => "_sym_package",
   "_ut_package_failure"           => "_sym_package",
   "_ut_package_notrun"            => "_sym_package",
   "_ut_package_passed"            => "_sym_package",
   "_ut_passed_not_icon"           => "_f_ok",
   "_ut_run_not_icon"              => "_f_run",
   "_ut_unittest_form"             => "tbunittest",
   "_ut_ut_defects"                => "bbdebug",
   "_ut_ut_rerun"                  => "bbexecute",
   "_exclamation_green"            => "_f_checkbox",
   "_exclamation_red"              => "_f_error",
   "_wkspace"                      => "_f_workspace",
   "_workspace16"                  => "_f_workspace",
   "_textbox16"                    => "_f_textbox",
   "_editwin16"                    => "_f_text",
   "_combobx16"                    => "_f_combobox",
   "_listbox16"                    => "_f_listbox",
   "_checkbx16"                    => "_f_checkbox",
   "_calendar16"                   => "_f_calendar",
   "_module"                       => "_f_folder_checked",
   "_build12"                      => "_f_build",
   "_search12"                     => "_f_search",
   "_alias"                        => "_f_alias",
   "_complete_next"                => "_f_complete_next",
   "_complete_prev"                => "_f_complete_prev",
   "_keyword"                      => "_f_key",
   "_surroundwith"                 => "_f_surround",
   "_syntax"                       => "_f_code",
   "_tt"                           => "_f_font",
   "_lbvs"                         => "_f_vs_pro",
   "_lbvs_eclipse"                 => "_f_vs_plugin",
   "_lbplus"                       => "_f_plus",
   "_lbminus"                      => "_f_minus",
   "_sarrow"                       => "bbpointer",
   "_labelb"                       => "bblabel",
   "_spinb"                        => "bbspin",
   "_textbox"                      => "bbtextbox",
   "_editwin"                      => "bbtext",
   "_frameb"                       => "bbframe",
   "_cmdbtn"                       => "bbbutton",
   "_radbtn"                       => "bbradio_button",
   "_checkbx"                      => "bbcheckbox",
   "_combobx"                      => "bbcombobox",
   "_listbox"                      => "bblistbox",
   "_vscroll"                      => "bbvert_scrollbar",
   "_hscroll"                      => "bbhorz_scrollbar",
   "_drvlist"                      => "bbhard_drive",
   "_fillist"                      => "bblist_buffers",
   "_dirlist"                      => "bbopen",
   "_picture"                      => "bbbox",
   "_gaugeb"                       => "bbprogress_bar",
   "_imageb"                       => "bbhtml_image",
   "_tree"                         => "bbtree",
   "_sstabb"                       => "bbtabs",
   "_minihtm"                      => "bbhtml_text",
   "_switchb"                      => "bbswitch",
   "_keybd"                        => "bbkeys",
   "_replace"                      => "bbtextbox",
   "_push_clipboard"               => "bbpaste",
   "debug_tool_autos"              => "tbdebug_autos",
   "debug_tool_breakpoints"        => "tbbreakpoints",
   "debug_tool_classes"            => "tbdebug_classes",
   "debug_tool_exceptions"         => "tbdebug_exceptions",
   "debug_tool_locals"             => "tbdebug_locals",
   "debug_tool_members"            => "tbdebug_members",
   "debug_tool_memory"             => "tbdebug_memory",
   "debug_tool_registers"          => "tbdebug_registers",
   "debug_tool_sessions"           => "tbdebug_sessions",
   "debug_tool_stack"              => "tbdebug_stack",
   "debug_tool_threads"            => "tbdebug_threads",
   "debug_tool_watches"            => "tbdebug_watches",
   "menulist"                      => "bbmenu",
   "otbookmarks"                   => "tbbookmarks",
   "otbookmarkstack"               => "tbbookmarks_stack",
   "otoutput"                      => "tboutput",
   "otreferences"                  => "tbreferences",
   "otsearch"                      => "tbsearch",
   "otshell"                       => "tbbuild",
   "otsymbol"                      => "tbpreview",
   "ptclass"                       => "tbsymbols",
   "ptfiles"                       => "tbfiles",
   "ptftp"                         => "tbftpopen",
   "ptopen"                        => "tbopen",
   "ptoutline"                     => "tboutput",
   "ptproject"                     => "tbprojects",
   "tag_args"                      => "tbtagargs",
   "tag_props"                     => "tbtagprops",
   "tbannotations"                 => "tbannotations",
   "tbbackup_history"              => "tbbackup_history",
   "tbclass"                       => "tbclass",
   "tbclipboard"                   => "tbclipboard",
   "tbfindsymbol"                  => "tbfindsymbol",
   "tbmessagelist"                 => "tbmessagelist",
   "tbnotifications"               => "tbnotifications",
   "tbregex"                       => "tbregex",
   "tbslickc_stack"                => "tbstack",
   "_buttonarrow"                  => "bbmenudown",
   "_edannotation"                 => "_ed_annotation",
   "_edannotationgray"             => "_ed_annotation_disabled",
   "_job"                          => "_ed_annotation",
   "_jobdd"                        => "_ed_annotation_disabled",
   "_breakpt"                      => "_ed_breakpoint",
   "_breakpn"                      => "_ed_breakpoint_disabled",
   "_watchpt"                      => "_ed_watchpoint",
   "_watchpn"                      => "_ed_watchpoint_disabled",
   "_edplus"                       => "_ed_plus",
   "_edminus"                      => "_ed_minus",
   "_edbookmark"                   => "_ed_bookmark",
   "_edpushbookmark"               => "_ed_bookmark_pushed",
   "_stackex"                      => "_ed_stack",
   "_stackgo"                      => "_ed_stack_go",
   "_stackbr"                      => "_ed_stack_breakpoint",
   "_stackbn"                      => "_ed_stack_breakpoint_disabled",
   "_execpt"                       => "_ed_exec",
   "_execgo"                       => "_ed_exec_go",
   "_execbrk"                      => "_ed_exec_breakpoint",
   "_execbn"                       => "_ed_exec_breakpoint_disabled",
   "_edhint"                       => "_ed_lightbulb",
   "_edreference"                  => "_ed_reference",
   "_edsearch"                     => "_ed_search",
   "_edsoftwrapm6x9"               => "_ed_softwrap",
   "_edsoftwrapm4x6"               => "_ed_softwrap",
   "_errmark"                      => "_ed_error",
   "_surround"                     => "_ed_up_and_down",
   "_merged_rev1"                  => "_ed_merge_left",
   "_merged_rev2"                  => "_ed_merge_right",
   "_merge_line_deleted"           => "_ed_delete",
   "_merge_line_added"             => "_ed_add",
   "error_obj"                     => "_ed_error",
   "eclipsewarning"                => "_ed_warning",
   "eclipsebookmark"               => "_ed_bookmark_pushed",
   "eclipsesearchmark"             => "_ed_arrow",
   "eclipsetaskmark"               => "_ed_task",
   "eclipseinfo"                   => "_ed_info",
};

static _str _replace_file_extension(_str filename, _str ext)
{
   return _strip_filename(filename, 'e'):+".":+ext;
}

static _str toolbar_bitmap_path_search(_str name, _str options="")
{
   ext := lowcase(_get_extension(name));
   if (ext == "") name :+= ".ico";
   file_name_only := _strip_filename(name, 'p');
   file_name_svg  := _replace_file_extension(file_name_only, "svg");

   plugins_dir := VSCFGPLUGIN_DIR;
   bitmaps_dir := _getSlickEditInstallPath();
   _maybe_append_filesep(bitmaps_dir);
   bitmaps_dir :+= VSE_BITMAPS_DIR:+FILESEP;

   tbFilePath := "";
   foreach (auto spec in '"bb/tb tb3d tbblue" "tb/tw tw3d twblue" _sym_/symbols _ed_/editor _file/files') {
      spec_no_quotes := _maybe_unquote_filename(spec);
      parse spec_no_quotes with auto prefix '/' auto dirs;
      if (pos(prefix, file_name_only) == 1) {
         found_all_versions := true;
         foreach (auto tbdir in dirs) {
            tbFilePath = bitmaps_dir:+tbdir:+FILESEP:+file_name_svg;
            if ( !file_exists(tbFilePath)) {
               found_all_versions = false;
               break;
            }
         }
         if (found_all_versions) {
            return file_name_svg;
         }
      }
   }

   // look in installation / bitmaps
   foreach (auto subdir in ". tb tw") {
      tbFilePath = bitmaps_dir:+subdir:+FILESEP:+file_name_svg;
      if ( file_exists(tbFilePath) ) {
         return file_name_svg;
      }
      tbFilePath = bitmaps_dir:+subdir:+FILESEP:+file_name_only;
      if ( file_exists(tbFilePath) ) {
         return file_name_only;
      }
      foreach (ext in "svg ico png bmp") {
         tbFilePath = bitmaps_dir:+subdir:+FILESEP:+_replace_file_extension(file_name_only, ext);
         if ( file_exists(tbFilePath) ) {
            return _replace_file_extension(file_name_only, ext);
         }
      }
   }

   // look in plugins / bitmaps
   foreach (subdir in ". bitmaps bitmaps/tb bitmaps/tw") {
      tbFilePath = plugins_dir:+subdir:+FILESEP:+file_name_svg;
      if ( file_exists(tbFilePath) ) {
         return file_name_svg;
      }
      tbFilePath = plugins_dir:+subdir:+FILESEP:+file_name_only;
      if ( file_exists(tbFilePath) ) {
         return file_name_only;
      }
      foreach (ext in "svg ico png bmp") {
         tbFilePath = plugins_dir:+subdir:+FILESEP:+_replace_file_extension(file_name_only, ext);
         if ( file_exists(tbFilePath) ) {
            return _replace_file_extension(file_name_only, ext);
         }
      }
   }

   // look in bitmaps path
   bitmaps_path := get_env("VSLICKBITMAPS");
   if (bitmaps_path != null && bitmaps_path != "") {
      tbFilePath = path_search(file_name_svg, "VSLICKBITMAPS");
      if ( tbFilePath != "" && file_exists(tbFilePath) ) {
         return file_name_svg;
      }
      tbFilePath = path_search(file_name_only, "VSLICKBITMAPS");
      if ( tbFilePath != "" && file_exists(tbFilePath) ) {
         return file_name_only;
      }
      foreach (ext in "svg ico png bmp") {
         tbFilePath = path_search(_replace_file_extension(file_name_only, ext), "VSLICKBITMAPS");
         if ( tbFilePath != "" && file_exists(tbFilePath) ) {
            return _replace_file_extension(file_name_only, ext);
         }
      }
   }


   // check if the file exists on disk
   foreach (ext in "svg ico png bmp") {
      if (file_exists(_replace_file_extension(name, ext))) {
         return _replace_file_extension(name, ext);
      }
   }
   if ( file_exists(name) ) {
      return name;
   }

   // did not find the icon anywhere
   return "";
}

static int testPictureProperties(_str &picturesMissing)
{
   // start from the top
   top();
   _begin_line();
   bool bitmaps_seen:[];

   count := 0;
   status := 0;
   for (;;) {

      // look for p_picture
      status = search("p_picture", '@ehw');
      if (status) {
         break;
      }

      // get the match
      get_line(auto line);

      // parse out the bitmap value
      _str leading;
      _str bitmap;
      parse line with leading "p_picture" "=" bitmap ";";

      // strip quotes
      if (_first_char(bitmap) == "'") {
         bitmap = strip(bitmap, 'B', "'");
      } else if (_first_char(bitmap) == '"') {
         bitmap = strip(bitmap, 'B', '"');
      }

      // try to find the bitmap, if we haven't already tried it
      if (bitmaps_seen._indexin(bitmap)) {
         newBitmap := toolbar_bitmap_path_search(bitmap);
         if (newBitmap == "") {
            picturesMissing :+= ' ';
            picturesMissing :+= bitmap;
            count++;
         }
         bitmaps_seen:[bitmap] = true;
      }

      // next please
      down();_begin_line();
   }

   return count;
}

static int testObjects(_str path)
{
   // open a temporary view
   int orig_wid, temp_wid;
   int status = _open_temp_view(_maybe_unquote_filename(path), temp_wid, orig_wid);
   if (status) {
      return status;
   }

   // save the old search options
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

   numMissing := testPictureProperties(auto missingBitmaps="");

   // cleanup
   restore_search(s1,s2,s3,s4,s5);
   p_window_id=orig_wid;
   _delete_temp_view(temp_wid);

   if (missingBitmaps=='') {
      _message_box("No missing bitmaps in sysobjs.e");
   } else {
      _message_box(numMissing :+ " missing bitmaps in sysobjs.e:\n\n":+missingBitmaps);
   }

   // that's all folks
   return 0;
}

static int updatePictureProperties()
{
   sstring := old_search_string;
   rstring := old_replace_string;
   save_old_search_options(auto soptions, auto srange, auto sflags, auto smisc);

   // replace all picture styles to the highlight style
   top();
   replace("p_style=PSPIC_AUTO_BUTTON", "p_style=PSPIC_HIGHLIGHTED_BUTTON", "@e*");
   top();
   replace("p_style=PSPIC_FLAT_BUTTON", "p_style=PSPIC_HIGHLIGHTED_BUTTON", "@e*");

   // PS_PIC_DEFAULT_TRANSPARENT is obsolete. If you want transparency, then
   // create an image with transparency.
   top();
   replace("p_style=PSPIC_DEFAULT_TRANSPARENT", "p_style=PSPIC_DEFAULT", "@e*");

   // start from the top
   top();
   _begin_line();

   count := 0;
   status := 0;
   for (;;) {

      // look for p_picture
      status = search("p_picture", '@ehw');
      if (status) {
         break;
      }

      // get the match
      get_line(auto line);

      // parse out the bitmap value
      _str leading;
      _str bitmap;
      parse line with leading "p_picture" "=" bitmap ";";

      // strip quotes
      if (_first_char(bitmap) == "'") {
         bitmap = strip(bitmap, 'B', "'");
      } else if (_first_char(bitmap) == '"') {
         bitmap = strip(bitmap, 'B', '"');
      }

      // needs update?
      orig_bitmap     := bitmap;
      bitmap_filename := _strip_filename(bitmap, 'P');
      bitmap = _strip_filename(bitmap_filename, 'E');
      if (gBitmapMap._indexin(bitmap)) {
         // get the new bitmap name
         bitmap = gBitmapMap:[bitmap];
         // check if the bitmap exists
         newBitmap := toolbar_bitmap_path_search(bitmap);
         if (newBitmap != "") {
            // replace the line
            replace_line(leading :+ "p_picture=" :+ _quote(newBitmap) :+ ";");
            count++;
         }
      } else {
         // maybe the file extension changed
         newBitmap := toolbar_bitmap_path_search(bitmap);
         if (newBitmap == "" && !_file_eq(bitmap, orig_bitmap)) {
            newBitmap = toolbar_bitmap_path_search(orig_bitmap);
         }
         if (!_file_eq(_strip_filename(newBitmap, 'P'), bitmap_filename)) {
            // replace the line
            replace_line(leading :+ "p_picture=" :+ _quote(newBitmap) :+ ";");
            count++;
         }
      }

      // next please
      down();_begin_line();
   }
   old_search_string = sstring;
   old_replace_string = rstring;
   restore_old_search_options(soptions, srange, sflags, smisc);

   return count;
}

static void updateOldForms()
{
   // start from the top
   top();
   _begin_line();

   status := 0;
   for (;;) {

      // look for _form
      status = search("_form", '@ehw');
      if (status) {
         break;
      }

      // get the match
      get_line(auto line);

      // parse out the bitmap value
      _str leading;
      _str trailing;
      _str form_name;
      parse line with leading "_form " form_name trailing;

      form_name = strip(form_name);
      if (gFormMap._indexin(form_name)) {

         // get the new bitmap name
         form_name = gFormMap:[form_name];

         // replace the line
         replace_line(leading :+ "_form " :+ form_name :+ " " :+ trailing);
      }

      // next please
      down();_begin_line();
   }
}

static void updateToolbarForms()
{
   int toolbarUpdateMap:[];
   int i,n=def_toolbartab._length();
   for (i = 0; i < n; ++i) {
      if (def_toolbartab[i].FormName=="_tbcontext_form" ||
          def_toolbartab[i].FormName=="_tbdebug_sessions_form" ||
          ((def_toolbartab[i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) &&
           (def_toolbartab[i].tbflags & TBFLAG_SIZEBARS) == 0 &&
           (def_toolbartab[i].tbflags & TBFLAG_NO_CAPTION) == 0)) {
         toolbarUpdateMap:[def_toolbartab[i].FormName] = i;
      }
   }

   // start from the top
   top();
   _begin_line();

   status := 0;
   for (;;) {
      // look for _form
      status = search("_form", '@ehw');
      if (status) {
         break;
      }

      // get the match
      get_line(auto line);

      // parse out the bitmap value
      _str leading;
      _str trailing;
      _str form_name;
      parse line with leading '_form ' form_name trailing;

      form_name = strip(form_name);
      if (toolbarUpdateMap._indexin(form_name)) {
         down();
         for (;;) {
            get_line(line);
            if (verify(line,'{}','M')) break;

            _str name, value;
            parse line with name "=" value ";";
            name = strip(name); value = strip(value);
            if (name :== 'p_eventtab2') {
               if (value :== '_toolbar_etab2') {
                  parse line with leading 'p_eventtab2' '=' '_toolbar_etab2;' trailing;
                  replace_line(leading:+'p_eventtab2=_qtoolbar_etab2;':+trailing);
               }
               break;
            }
            if (down()) break;
         }
      }

      // next please
      down();_begin_line();
   }
}

static int updateUserObjects(_str path)
{
   // open a temporary view
   int orig_wid, temp_wid;
   int status = _open_temp_view(_maybe_unquote_filename(path), temp_wid, orig_wid);
   if (status) {
      return status;
   }

   // save the old search options
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

   int num_icons_changed = updatePictureProperties();
   // If change the name of the forms, can't update the form
   // at startup. Needed when delete vslick.sta or launch
   // multiple instances using same config dir.
   //if (num_icons_changed > 10) updateOldForms();
   updateToolbarForms();

   // save the file
   if (p_modify) {
      status=save('',SV_OVERWRITE);
   }

   // cleanup
   restore_search(s1,s2,s3,s4,s5);
   p_window_id=orig_wid;
   _delete_temp_view(temp_wid);

   // that's all folks
   return 0;
}

static void testIcons()
{
   numMissing := 0;
   missingBitmaps := "";
   errors := false;
   foreach (auto old_bitmap => auto new_bitmap in gBitmapMap) {
      if (toolbar_bitmap_path_search(new_bitmap) == "") {
         missingBitmaps :+= new_bitmap :+ ".svg\n";
         ++numMissing;
      }
   }
   if (missingBitmaps=='') {
      _message_box("No missing bitmaps in updateobjs.e");
   } else {
      _message_box(numMissing :+ " missing bitmaps in updateobjs.e:\n\n":+missingBitmaps);
   }
}

defmain()
{
   // test mode?
   parse arg(1) with auto command auto filename;
   if (command == "testIcons") {
      macros_dir := _getSlickEditInstallPath():+"macros":+FILESEP;
      testIcons();
      testObjects(macros_dir:+"sysobjs.e");
      return 0;
   }

   // updating a single icon?
   if (command == "updateIcon" && filename != "") {
      filename = _maybe_unquote_filename(filename);
      bitmap_filename := _strip_filename(filename, 'P');
      bitmap := _strip_filename(bitmap_filename, 'E');
      if (gBitmapMap._indexin(bitmap)) {
         // get the new bitmap name
         bitmap = gBitmapMap:[bitmap];
      }
      _param1 = toolbar_bitmap_path_search(bitmap);
      return 0;
   }

   // expecting a single file name as an argument
   if (arg(1) == '') {
      message("usage: updateobjs <filename.e>");
      return 1;
   }

   // update the icons
   updateUserObjects(arg(1));

   // that's all folks
   return 0;
}
