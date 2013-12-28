////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44204 $
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
#include "listbox.sh"
#import "debug.sh"
#import "listbox.e"
#import "qtoolbar.e"
#import "stdprocs.e"
#import "toolbar.e"
#import "options.e"
#import "sc/controls/customizations/ToolbarControl.e"
#endregion

_TOOLBAR def_toolbartab[];

// button bar picture size
_str def_toolbar_pic_size="24x24";
_str def_toolbar_pic_depth=32;

// button bar toolbar spacing
int def_toolbar_pic_hspace = 4;
int def_toolbar_pic_vspace = 0;

#define BB_XSPACE 90

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
};

#define CUSTOMIZE_HELP_STRING "On a toolbar, right-click and select \"Properties...\" to customize."

static SPECIALCONTROL gtwSpecialControlTab:[] = {
   '_tbsearch_hist_etab'=>{OI_COMBO_BOX,2500,0,"_tbsearch_hist_etab","_tbsearch_hist_etab","_ul2_combobx","Search History"},
   '_tbcontext_combo_etab'=>{OI_COMBO_BOX,4200,0,"_tbcontext_combo_etab","_tbcontext_combo_etab","_ul2_combobx","Current Context"},
   '_tbproject_list_etab'=>{OI_COMBO_BOX,2500,0,"_tbproject_list_etab","_tbproject_list_etab","_ul2_combobx","Current Project"},
   '_tbproject_config_etab'=>{OI_COMBO_BOX,1800,0,"_tbproject_config_etab","_tbproject_config_etab","_ul2_combobx","Current Configuration"},
   'button'=>{OI_IMAGE,0,0,"","","",CUSTOMIZE_HELP_STRING},
   //'button'=>{OI_BUTTON,380,1220,"","",""},
   'space1'=>{OI_IMAGE,BB_XSPACE,0,"","_ul2_picture","",""},
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

struct TBDEFAULTLIST {

   _str FormName;

   // Bitmap info
   TBCONTROL CtrlList[];
};

static TBDEFAULTLIST gToolbarDefaultTab[] = {

   { "_tbstandard_form",
     // IMPORTANT:
     // When modifying this structure, make sure _tbstandard_form
     // in sysobjs is also updated.
     {
        { 'bbnew.ico','new','Create an Empty File to Edit' },
        { 'bbopen.ico','gui-open','Open a File for Editing' },
        { 'bbsave.ico','save','Save Current File' },
        { 'bbsave_history.ico','activate-deltasave','List Backup History for Current File' },
        { 'bbprint.ico','gui-print','Print Current File' },
        { "\tspace1",'','' },
        { 'bbcut.ico','cut','Delete Selected Text and Copy to the Clipboard' },
        { 'bbcopy.ico','copy-to-clipboard','Copy Selected Text to the Clipboard' },
        { 'bbpaste.ico','paste','Paste Clipboard into Current File' },
        { 'bbselect_code_block.ico','select-code-block','Select Lines in the Current Code Block' },
        { "\tspace1",'','' },
        { 'bbundo.ico','undo','Undo the Last Edit Operation' },
        { 'bbredo.ico','redo','Undo the Last Undo Operation' },
        { 'bbback.ico','back','Navigate Backward' },
        { 'bbforward.ico','forward','Navigate Forward' },
        { "\tspace1",'','' },
        { 'bbfind.ico','gui-find','Search for a String You Specify' },
        { 'bbfind_next.ico','find-next','Search for the Next Occurrence of the String You Last Searched' },
        { 'bbreplace.ico','gui-replace','Search for a String and Replace it with Another String' },
        { "\tspace1",'','' },
        { 'bbfullscreen.ico','fullscreen','Toggle Full Screen Editing Mode' },
        { 'bbconfig.ico','config','Displays the configuration options dialog' },
        { 'bbvsehelp.ico','help -contents','SlickEdit Help' },
      },
   },
   { "_tbproject_tools_form",
     {
        { 'bbnext_error.ico','next-error','Process the Next Compiler Error Message' },
        { 'bbmake.ico','project-build','Run the Build Command for the Current Project' },
        { 'bbcompile.ico','project-compile','Run the Compile Command for the Current Project' },
        { "\tspace1",'','' },
        { 'bbcheckin.ico','vccheckin','Check in Current File into Version Control System' },
        { 'bbcheckout.ico','vccheckout','Check out or Update Current File from Version Control System' },
      },
   },
   { "_tbtools_form",
     {
        { 'bbbeautify.ico','beautify_selection','Beautify Selection or Entire Buffer' },
        { 'bbdiff.ico','diff','Bring Up DIFFzilla'VSREGISTEREDTM'' },
        { 'bbmerge.ico','merge','Merge Two Sets of Changes Made to a File' },
        { 'bbfind_file.ico','find-file','Search for File' },
        { 'bbcalculator.ico','calculator','Display Calculator Dialog Box' },
        { 'bbshell.ico','dos','Run the Operating System Command Shell' },
        { 'bbspell.ico','spell-check M','Spell Check from Cursor or Selected Text' },
        { 'bbhex.ico','hex','Toggle Hex Editing' },
     }
   },
   { "_tbedit_form",
     {
        { 'bblowcase.ico','maybe-lowcase-selection','Translate Characters in Current Word or Selection to Lower Case' },
        { 'bbupcase.ico','maybe-upcase-selection','Translate Characters in Current Word or Selection to Upper Case' },
        { 'bbshift_left.ico','shift-selection-left','Left Shift Selection' },
        { 'bbshift_right.ico','shift-selection-right','Right Shift Selection' },
        { 'bbreflow.ico','reflow-selection','Word Wrap Current Paragraph or Selection' },
        { 'bbunindent_selection.ico','unindent-selection','Unindent Selected Text' },
        { 'bbindent_selection.ico','indent-selection','Indent Selected Text' },
        { 'bbtabs_to_spaces.ico','convert_tabs2spaces','Convert Tabs to Spaces' },
        { 'bbspaces_to_tabs.ico','convert_spaces2tabs','Convert Indentation Spaces to Tabs' },
        { 'bbfind_matching_paren.ico','find-matching-paren','Find the Matching Parenthesis or Begin/End Structure Pairs' },
     }
   },
   { "_tbseldisp_form",
     {
        { 'bbshow_procs.ico','show-procs','Outline Current File with Function Headings' },
        { 'bbhide_code_block.ico','hide-code-block','Hide Lines inside Current Code Block' },
        { 'bbselective_display.ico','selective-display','Display Selective Display Dialog Box' },
        { 'bbhide_selection.ico','hide-selection','Hide Selected Lines' },
        { 'bbplusminus.ico','plusminus','Toggles between hiding and showing the code block under the cursor' },
        { 'bbshow_all.ico','show-all','End Selective Display. All Lines Are Displayed and Outline Bitmaps Are Removed.' },
     }
   },
   { "_tbxml_form",
     {
        { 'bbbeautify.ico','beautify_selection','Beautify Selection or Entire Buffer' },
        { 'bbxml_validate.ico','xml-validate','Validate XML Document' },
        { 'bbxml_wellformedness.ico','xml-wellformedness','Check for Well-Formedness' },
     }
   },
   { "_tbhtml_form",
     {
        { 'bbhtml_body.ico','insert_html_body','Insert or Adjust Body Tag in Current HTML File' },
        { 'bbhtml_style.ico','insert_html_styles','Insert Style Tag into Current HTML File' },
        { 'bbhtml_image.ico','insert_html_image','Insert Image into Current HTML File' },
        { 'bbhtml_link.ico','insert_html_link','Insert Link into Current HTML File' },
        { 'bbhtml_anchor.ico','insert_html_anchor','Insert Target into Current HTML File' },
        { 'bbhtml_applet.ico','insert_html_applet','Insert Java Applet into Current HTML File' },
        { 'bbhtml_script.ico','insert_html_script','Insert Script or Script Tag into Current HTML File' },
        { 'bbhtml_hline.ico','insert_html_hline','Insert Horizontal Line into Current HTML File' },
        { 'bbhtml_rgb_color.ico','insert_rgb_value','Insert RGB Value into Current HTML File' },
        { "\tspace1",'','' },
        { 'bbhtml_head.ico','insert_html_heading','Insert Heading Tag into Current HTML File' },
        { 'bbhtml_paragraph.ico','insert_html_paragraph','Insert Paragraph Tag into Current HTML File' },
        { 'bbhtml_bold.ico','insert_html_bold','Insert Bold Tag into Current HTML File' },
        { 'bbhtml_italic.ico','insert_html_italic','Insert Italic Tag into Current HTML File' },
        { 'bbhtml_underline.ico','insert_html_uline','Insert Underline Tag into Current HTML File' },
        { 'bbhtml_font.ico','insert_html_font','Insert Font Tag into Current HTML File' },
        { 'bbhtml_center.ico','insert_html_center','Insert Align Center Tag into Current HTML File' },
        { 'bbhtml_right.ico','insert_html_right','Insert Align Right Tag into Current HTML File' },
        { 'bbhtml_list.ico','insert_html_list','Insert Ordered/Unordered Tag into Current HTML File' },
        { "\tspace1",'','' },
        { 'bbhtml_table.ico','insert_html_table','Insert Table Tag into Current HTML File' },
        { 'bbhtml_table_row.ico','insert-html-table-row','Insert Table Row Tag into Current HTML File' },
        { 'bbhtml_table_cell.ico','insert_html_table_col','Insert Table Cell Tag into Current HTML File' },
        { 'bbhtml_table_header.ico','insert_html_table_header','Insert Table Header Tag into Current HTML File' },
        { 'bbhtml_table_caption.ico','insert_html_table_caption','Insert Table Caption Tag into Current HTML File' },
        { "\tspace1",'','' },
        { 'bbhtml_preview.ico','html-preview','Bring up Web Browser or Display HTML File in Web Browser' },
        { 'bbspell.ico','spell-check M','Spell Check from Cursor or Selected Text' },
        { 'bbbeautify.ico','h_beautify_selection','Beautify Selection or Entire Buffer' },
        { 'bbftp.ico','ftpOpen','Activate FTP Tab for Opening FTP Files' }
     }
   },
   { "_tbtagging_form",
     {
        { 'bbmake_tags.ico','gui-make-tags','Build Tag Files for Use by the Symbol Browser and Other Context Tagging'VSREGISTEREDTM' Features' },
        { 'bbfind_symbol.ico','gui-push-tag','Activate the Find Symbol Tool Window to Locate Tags' },
        { 'bbclass_browser_find.ico','cb-find','Find the Symbol under the Cursor and Display in Symbol Browser' },
        { 'bbfind_refs.ico','push-ref','Go to Reference' },
        { 'bbpush_tag.ico','push-tag','Go to Definition' },
        { 'bbpop_tag.ico','pop-bookmark','Pop the Last Bookmark' },
        { 'bbnext_tag.ico','next-tag','Place Cursor on Next Symbol Definition' },
        { 'bbprev_tag.ico','prev-tag','Place Cursor on Previous Symbol Definition' },
        { 'bbend_tag.ico','end-tag','Place Cursor at the End of the Current Symbol Definition' },
        { 'bbfunction_help.ico','function-argument-help','Display Prototype(s) and Highlight Current Argument' },
        { 'bblist_symbols.ico','list-symbols','List Valid Symbols for Current Context' },
        { 'bbrefactor_rename.ico','refactor_quick_rename precise','Rename Symbol under Cursor' },
     }
   },
   { "_tbdebugbb_form",
     {
        { 'bbdebug_restart.ico','debug_restart','Restart Execution' },
        { 'bbdebug_continue.ico','project_debug','Continue Execution' },
        { 'bbdebug_suspend.ico','debug_suspend','Suspend Execution' },
        { 'bbdebug_stop.ico','debug_stop','Stop Debugging' },
        { "\tspace1",'','' },
        { 'bbdebug_show_next_statement.ico','debug_show_next_statement','Displays the Source Line for the Instruction Pointer' },
        { 'bbdebug_step_into.ico','debug_step_into','Step into a Function' },
        { 'bbdebug_step_over.ico','debug_step_over','Step over the Next Statement' },
        { 'bbdebug_step_out.ico','debug_step_out','Step out of the Current Function' },
        { 'bbdebug_step_deep.ico','debug_step_deep','Step into Next Statement (Will Step into Runtimes)' },
        { 'bbdebug_step_instruction.ico','debug_step_instr','Step by One Instruction' },
        { 'bbdebug_run_to_cursor.ico','debug_run_to_cursor','Continue until Line Cursor is on' },
        { "\tspace1",'','' },
        { 'bbdebug_toggle_breakpoint.ico','debug_toggle_breakpoint','Toggle Breakpoint' },
        { 'bbdebug_toggle_enabled.ico','debug_toggle_breakpoint_enabled','Toggle Breakpoint between Enabled and Disabled' },
        { 'bbdebug_disable_breakpoints.ico','debug_disable_all_breakpoints','Disable All Breakpoints' },
        { 'bbdebug_breakpoints.ico','debug_breakpoints','View or Modify Breakpoints' },
        { "\tspace1",'','' },
        { 'bbdebug_add_watch.ico','debug_add_watch','Add a Watch on the Current Variable' },
        { 'bbdebug_toggle_disassembly.ico','debug_toggle_disassembly','Toggle Display of Disassembly' },
        { 'bbdebug_toggle_hex.ico','debug_toggle_hex','Toggle Between Default and Hexidecimal Variable Display' },
     }
   },
   { "_tbunified_form",
     {
        { 'bbnew.ico','new','Create an Empty File to Edit' },
        { 'bbopen.ico','gui-open','Open a File for Editing' },
        { 'bbsave.ico','save','Save Current File' },
        { 'bbsave_history.ico','activate-deltasave','List Backup History for Current File' },
        { "\tspace1",'','' },
        { 'bbcut.ico','cut','Delete Selected Text and Copy to the Clipboard' },
        { 'bbcopy.ico','copy-to-clipboard','Copy Selected Text to the Clipboard' },
        { 'bbpaste.ico','paste','Paste Clipboard into Current File' },
        { "\tspace1",'','' },
        { 'bbundo.ico','undo','Undo the Last Edit Operation' },
        { 'bbredo.ico','redo','Undo the Last Undo Operation' },
        { 'bbback.ico','back','Navigate Backward' },
        { 'bbforward.ico','forward','Navigate Forward' },
        { 'bbfind.ico','gui-find','Search for a String You Specify' },
        { "\tspace1",'','' },
        { 'bbmake.ico','project-build','Run the Build Command for the Current Project' },
        { 'bbdebug.ico','project-debug','Run the Debug Command for the Current Project' },
        { "\tspace1",'','' },
        { 'bbfullscreen.ico','fullscreen','Toggle Full Screen Editing Mode' },
        { "\tspace1",'','' },
        { "\t_tbcontext_combo_etab",'','' },
      },
   },
};

#define CUSTOMIZE_HELP_STRING "On a toolbar, right-click and select \"Properties...\" to customize."

static struct TBCATLIST {

   // Category name
   _str name;

   // Bitmap info
   TBCONTROL CtrlList[];
};

// Some of these entries are replicated throughout the array.
static TBCATLIST gToolbarCatTab[] = {

   { "Custom Button",
      {
         { "\tbutton",'','' },
      }
   },
   { "User Definable Tools",
      {
        { 'bbtool01.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool02.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool03.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool04.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool05.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool06.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool07.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool08.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool09.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool10.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool11.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool12.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool13.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool14.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool15.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool16.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool17.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool18.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool19.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool20.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool21.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool22.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool23.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool24.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool25.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool26.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool27.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool28.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool29.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool30.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool31.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool32.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool33.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool34.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool35.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool36.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool37.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool38.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool39.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool40.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool41.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool42.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool43.ico','',CUSTOMIZE_HELP_STRING},
        { 'bbtool44.ico','',CUSTOMIZE_HELP_STRING},
      }
   },
   { "Edits and Selections",
      {
         { 'bbcut.ico','cut','Delete Selected Text and Copy to the Clipboard' },
         { 'bbcopy.ico','copy-to-clipboard','Copy Selected Text to the Clipboard' },
         { 'bbpaste.ico','paste','Paste Clipboard into Current File' },
         { 'bbundo.ico','undo','Undo the Last Edit Operation' },
         { 'bbredo.ico','redo','Undo the Last Undo Operation' },
         { 'bbclipboards.ico','list-clipboards','Insert a Clipboard Selected from a List of your Recently Created Clipboards' },
         { 'bbselect_code_block.ico','select-code-block','Select Lines in the Current Code Block' },
         { 'bbfind_matching_paren.ico','find-matching-paren','Find the Matching Parenthesis or Begin/End Structure Pairs' },
         { 'bbunindent_selection.ico','unindent-selection','Unindent Selected Text' },
         { 'bbindent_selection.ico','indent-selection','Indent Selected Text' },
         { 'bbsurround_with.ico','surround_with','Surrounds the Selected Block of Text with a Control Structure or Tag' },
         { 'bbunsurround.ico','unsurround','Un-surrounds the block under the cursor' },
         { 'bblowcase.ico','maybe-lowcase-selection','Translate Characters in Current Word or Selection to Lower Case' },
         { 'bbupcase.ico','maybe-upcase-selection','Translate Characters in Current Word or Selection to Upper Case' },
         { 'bbreflow.ico','reflow-selection','Word Wrap Current Paragraph or Selection' },
         { 'bbspell.ico','spell-check M','Spell Check from Cursor or Selected Text' },
         { 'bbshift_left.ico','shift-selection-left','Left Shift Selection' },
         { 'bbshift_right.ico','shift-selection-right','Right Shift Selection' },
         { 'bbtabs_to_spaces.ico','convert_tabs2spaces','Convert Tabs to Spaces' },
         { 'bbspaces_to_tabs.ico','convert_spaces2tabs','Convert Indentation Spaces to Tabs' },
         { 'bbbeautify.ico','beautify_selection','Beautify Selection or Entire Buffer' },
      }
   },
   { "Files and Buffers",
      {
         { 'bbnew.ico','new','Create an Empty File to Edit' },
         { 'bbopen.ico','gui-open','Open a File for Editing' },
         { 'bbnew_file.ico','new_file','Create an Empty Unnamed File to Edit (No Prompting)' },
         { 'bbproject_add_item.ico','project-add-item','Create Files from Template and Add to Project' },
         { 'bbtemplate_manager.ico','template_manager','Create, Edit, and Delete your Templates' },
         { 'bbsave.ico','save','Save Current File' },
         { 'bbsave_as.ico','gui-save-as','Save the Current File Under a Different Name' },
         { 'bbsave_all.ico','save-all','Save All Modified Files' },
         { 'bbsave_history.ico','activate-deltasave','List Backup History for Current File'  },
         { 'bbrevert.ico','revert','Revert Current File to Version on Disk' },
         { 'bbclose.ico','quit','Close Current File' },
         { 'bbback.ico','back','Navigate Backward' },
         { 'bbforward.ico','forward','Navigate Forward' },
         { 'bbnext_buffer.ico','next-doc','Switch to Next File' },
         { 'bbprev_buffer.ico','prev-doc','Switch to Previous File' },
         { 'bblist_buffers.ico','list-buffers','List All Open Files' },
         { 'bbreload.ico','auto-reload','Reload Files That Have Changed on Disk' },
         { 'bbdiff.ico','diff','Bring Up DIFFzilla'VSREGISTEREDTM'' },
         { 'bbmerge.ico','merge','Merge Two Sets of Changes Made to a File' },
         { 'bbnext_window.ico','next-window','Switch to Next Edit Window' },
         { 'bbprev_window.ico','prev-window','Switch to Previous Edit Window' },
         { 'bbprint.ico','gui-print','Print Current File' },
         { 'bbprint_preview.ico','print-preview','Print Preview For Current File' },
         { 'bbhtml_preview.ico','html-preview','Bring up Web Browser or Display HTML File in Web Browser' },
         { 'bbfind_file.ico','find-file','Search for File' },
         { 'bbtabs_to_spaces.ico','convert_tabs2spaces','Convert Tabs to Spaces' },
         { 'bbspaces_to_tabs.ico','convert_spaces2tabs','Convert Indentation Spaces to Tabs' },
      }
   },
   { "Searching",
      {
         { 'bbfind.ico','gui-find','Search for a String You Specify' },
         { 'bbfind_next.ico','find-next','Search for the Next Occurrence of the String You Last Searched' },
         { 'bbfind_prev.ico','find-prev','Search for the Previous Occurence of the String You Last Searched' },
         { 'bbfind_word.ico','quick-search','Search for Word at Cursor' },
         { 'bbreplace.ico','gui-replace','Search for a String and Replace it with Another String' },
         { 'bbfind_in_files.ico','find-in-files','Search for String in Files' },
         { 'bbreplace_in_files.ico','replace-in-files','Search and Replace for String in Files' },
         { 'bbfind_file.ico','find-file','Search for File' },
         { 'bbnext_error.ico','next-error','Process the Next Compiler Error Message' },
         { 'bbprev_error.ico','prev-error','Process the Previous Compiler Error Message' },
         { 'bbstop_search.ico','stop-search','Stops the Current Background Search' },
         { 'bbfind_matching_paren.ico','find-matching-paren','Find the Matching Parenthesis or Begin/End Structure Pairs' },
         { "\t_tbsearch_hist_etab",'','' },
      }
   },
   { "Tagging",
      {
         { 'bbfind_refs.ico','push-ref','Go to Reference' },
         { 'bbnext_tag.ico','next-tag','Place Cursor on Next Symbol Definition' },
         { 'bbprev_tag.ico','prev-tag','Place Cursor on Previous Symbol Definition' },
         { 'bbfind_symbol.ico','gui-push-tag','Activate the Find Symbol Tool Window to Locate Tags' },
         { 'bbpush_tag.ico','push-tag','Go to Definition' },
         { 'bbpop_tag.ico','pop-bookmark','Pop the Last Bookmark' },
         { 'bbend_tag.ico','end-tag','Place Cursor at the End of the Current Symbol Definition' },
         { 'bbfunction_help.ico','function-argument-help','Display Prototype(s) and Highlight Current Argument' },
         { 'bblist_symbols.ico','list-symbols','List Valid Symbols for Current Context' },
         { 'bbrefactor_rename.ico','refactor_quick_rename precise','Rename Symbol under Cursor' },
         { 'bbclass_browser_find.ico','cb-find','Find the Symbol under the Cursor and Display in Symbol Browser' },
         { 'bbtag_props.ico','activate_tag_properties_toolbar','Display the Properties for the Current Symbol in the Symbol Browser' },
         { 'bbmake_tags.ico','gui-make-tags','Build Tag Files for Use by the Symbol Browser and Other Context Tagging'VSREGISTEREDTM' Features' },
         { 'bbnext_statement.ico','next-statement','Place Cursor on Next Statement Within a Function' },
         { 'bbprev_statement.ico','prev-statement','Place Cursor on Previous Statement Within a Function' },
         { "\t_tbcontext_combo_etab",'','' },
      }
   },
   {
     "Completion",
      {
         { 'bbcomplete_next.ico','complete-next','Retrieve Next Word or Variable Which is a Prefix Match of the Word at the Cursor' },
         { 'bbcomplete_prev.ico','complete-prev','Retrieve Previous Word or Variable Which is a Prefix Match of the Word at the Cursor' },
         { 'bbcomplete_list.ico','complete-list','Display a List of Words or Variables Which are a Prefix Match of the Word at the Cursor' },
         { 'bbcomplete_more.ico','complete-more','Inserts the Text Up to and Including the Next Word Which Follows the Last Match Found by the Last Completion Command' },
         { 'bbcomplete_auto.ico','autocomplete','Display Completion Options for the Word at the Cursor' },
         { 'bbexpand_alias.ico','expand-alias','Expands the Alias Name for the Word at the Cursor' },
         { 'bbcomplete_tag.ico','codehelp_complete','Use Tagging to Complete the Word at the Cursor' },
         { 'bblist_aliases.ico','alias','Displays, Creates, or Modifies Aliases' },
         { 'bbnew_alias.ico','new-alias','Create a New Alias from the Current Text Selection' },
      }
   },
   { "Windowing",
      {
         { 'bbfullscreen.ico','fullscreen','Toggle Full Screen Editing Mode' },
         { 'bbtile_horizontal.ico','tile-windows h','Horizontally Tile Edit Windows' },
         { 'bbtile_vertical.ico','tile-windows','Vertically Tile Edit Windows' },
         { 'bbmaximize_window.ico','maximize-window','Maximize Current Edit Window' },
         { 'bbiconize_all.ico','iconize-all','Minimize All Edit Windows' },
         { 'bbzoomin.ico','wfont_zoom_in','Increase the Font Size for the Current Editor Window' },
         { 'bbzoomout.ico','wfont_zoom_out','Decrease the Font Size for the Current Editor Window' },
         { 'bbhsplit_window.ico','hsplit_window','Splits the Current Window Horizontally in Half' },
         { 'bbvsplit_window.ico','vsplit_window','Splits the Current Window Vertically in Half' },
      }
   },
   { "Project",
      {
         { 'bbworkspace_new.ico','workspace-new','Create a Workspace and/or Project' },
         { 'bbworkspace_insert.ico','workspace-insert','Add an Existing Project to the Current Workspace' },
         { 'bbproject_properties.ico','project-edit','Edit Settings for the Current Project' },
         { 'bbmake.ico','project-build','Run the Build Command for the Current Project' },
         { 'bbexecute.ico','project-execute','Run the Execute Command in the Current Project' },
         { 'bbcompile.ico','project-compile','Run the Compile Command for the Current Project' },
         { 'bbnext_error.ico','next-error','Process the Next Compiler Error Message' },
         { 'bbprev_error.ico','prev-error','Process the Previous Compiler Error Message' },
         { 'bbdebug.ico','project-debug','Run the Debug Command for the Current Project' },
         { 'bbcheckin.ico','checkin','Check in Current File into Version Control System' },
         { 'bbcheckout.ico','checkout','Check out or Update Current File from Version Control System' },
         { 'bbproject_add_item.ico','project-add-item','Create Files from Template and Add to Project' },
         { "\t_tbproject_list_etab",'','' },
         { "\t_tbproject_config_etab",'','' },
      }
   },
   { "Debug",
      {
         { 'bbdebug.ico','project-debug','Run the Debug Command for the Current Project' },
         { 'bbdebug_remote.ico','debug_remote','Attach Debugger to a Remote Application' },
         { 'bbdebug_attach.ico','debug_attach','Attach Debugger to a Running Application' },
         { 'bbdebug_detach.ico','debug_detach','Detach Debugger from a Running Application' },
         { 'bbdebug_restart.ico','debug_restart','Restart Execution' },
         { 'bbdebug_continue.ico','project_debug','Continue Execution' },
         { 'bbdebug_suspend.ico','debug_suspend','Suspend Execution' },
         { 'bbdebug_stop.ico','debug_stop','Stop Debugging' },
         { 'bbdebug_show_next_statement.ico','debug_show_next_statement','Display the Source Line for the Instruction Pointer' },
         { 'bbdebug_up.ico','debug_up','Go One Level Up Stack' },
         { 'bbdebug_down.ico','debug_down','Go One Level Down Stack' },
         { 'bbdebug_top.ico','debug_top','Go to Top of Stack' },
         { 'bbdebug_step_into.ico','debug_step_into','Step Into a Function' },
         { 'bbdebug_step_instruction.ico','debug_step_instr','Step by One Instruction' },
         { 'bbdebug_step_deep.ico','debug_step_deep','Step Into Next Statement (Will Step into Runtimes)' },
         { 'bbdebug_step_over.ico','debug_step_over','Step Over the Next Statement' },
         { 'bbdebug_step_out.ico','debug_step_out','Step out of the Current Function' },
         { 'bbdebug_run_to_cursor.ico','debug_run_to_cursor','Continue until Line Cursor is on' },
         { 'bbdebug_add_breakpoint.ico','debug_add_breakpoint','Create a New Breakpoint or Watchpoint' },
         { 'bbdebug_toggle_breakpoint.ico','debug_toggle_breakpoint','Toggle Breakpoint' },
         { 'bbdebug_toggle_enabled.ico','debug_toggle_breakpoint_enabled','Toggle Breakpoint between Enabled and Disabled' },
         { 'bbdebug_toggle_breakpoint3.ico','debug_toggle_breakpoint3','Toggle Breakpoint between Enabled, Disabled, and Removed' },
         { 'bbdebug_disable_breakpoints.ico','debug_disable_all_breakpoints','Disable All Breakpoints' },
         { 'bbdebug_clear_breakpoints.ico','debug_clear_all_breakpoints','Delete All Breakpoints' },
         { 'bbdebug_breakpoints.ico','debug_breakpoints','View or Modify Breakpoints' },
         { 'bbdebug_add_exception.ico','debug_add_exception','Add a New Exception Breakpoint' },
         { 'bbdebug_disable_exceptions.ico','debug_disable_all_exceptions','Disable All Exceptions' },
         { 'bbdebug_clear_exceptions.ico','debug_clear_all_exceptions','Delete All Exception Breakpoints' },
         { 'bbdebug_exceptions.ico','debug_exceptions','View or Modify Exception Breakpoints' },
         { 'bbdebug_add_watch.ico','debug_add_watch','Add a Watch on the Current Variable' },
         { 'bbdebug_add_watchpoint.ico','debug_add_watchpoint','Add a Watchpoint on the Variable under the Cursor' },
         { 'bbdebug_toggle_hex.ico','debug_toggle_hex','Toggle Between Default and Hexidecimal Variable Display' },
         { 'bbdebug_toggle_disassembly.ico','debug_toggle_disassembly','Toggle Display of Disassembly' },
         { 'bbdebug_set_instruction_pointer.ico','debug_set_instruction_pointer','Set the Instruction Pointer to the Current Line' },
      }
   },
   { "Selective Display",
      {
         { 'bbselective_display.ico','selective-display','Display Selective Display Dialog Box' },
         { 'bbshow_procs.ico','show-procs','Outline Current File with Function Headings' },
         { 'bbhide_code_block.ico','hide-code-block','Hide Lines inside Current Code Block' },
         { 'bbhide_selection.ico','hide-selection','Hide Selected Lines' },
         { 'bbplusminus.ico','plusminus','Toggles between hiding and showing the code block under the cursor' },
         { 'bbshow_all.ico','show-all','End Selective Display. All Lines Are Displayed and Outline Bitmaps Are Removed.' },
      }
   },
   { "Bookmarks",
      {
         { 'bbset_bookmark.ico','set-bookmark','Set a Persistent Bookmark on the Current Line' },
         { 'bbnext_bookmark.ico','next-bookmark','Go to Next Bookmark' },
         { 'bbprev_bookmark.ico','prev-bookmark','Go to Previous Bookmark' },
         { 'bbbookmarks.ico','goto-bookmark','Displays Go to Bookmark Dialog Box' },
         { 'bbclear_bookmarks.ico','clear-bookmarks','Clear All Bookmarks' },
         { 'bbdelete_bookmark.ico','delete-bookmark','Delete the Bookmark on the Current Line' },
         { 'bbtoggle_bookmark.ico','toggle-bookmark','Toggle Setting a Bookmark on the Current Line' },
         { 'bbpush_bookmark.ico','push-bookmark','Push a Bookmark onto the Bookmark Stack' },
         { 'bbpop_bookmark.ico','pop-bookmark','Jump to the Last Bookmark Pushed on the Bookmark Stack' },
      }
   },
   { "Macros",
      {
         { 'bbmacro_record.ico','record-macro-toggle','Starts macro recording' },
         //{ 'bbmacro_stop.ico','end-recording','Stops Macro Recording' },
         { 'bbmacro_execute.ico','record-macro-end-execute','Runs the Last Recorded Macro' },
      }
   },
   { "Tools",
      {
         { 'bbconfig.ico','config','Display Configuration Options Dialog' },
         { 'bbcalculator.ico','calculator','Display Calculator Dialog Box' },
         { 'bbspell.ico','spell-check M','Spell Check from Cursor or Selected Text' },
         { 'bbhex.ico','hex','Toggle Hex Editing' },
         { 'bbruler.ico','ruler','Insert Ruler Line' },
         { 'bbmenu_editor.ico','open-menu','Edit Menus' },
         { 'bbtoolbars.ico','toolbars','Edits Toolbars' },
         { 'bbbeautify.ico','gui_beautify','Displays Language Specific Beautifier Dialog Box' },
         { 'bbftp.ico','toggle-ftp','Toggles FTP Client Toolbar On/Off' }
      }
   },
   { "Version Control",
      {
         { 'bbcheckin.ico','checkin','Check in Current File into Version Control System' },
         { 'bbcheckout.ico','checkout','Check out or Update Current File from Version Control System' },
         { 'bbvc_lock.ico','vclock','Lock File Using Version Control' },
         { 'bbvc_unlock.ico','vcunlock','Unlock File Using Version Control' },
         { 'bbvc_update.ico','cvs-gui-mfupdate','Update a directory using Version Control' },
         { 'bbvc_history.ico','vchistory','Displays Version Control History for Current File' },
         { 'bbvc_diff.ico','vcdiff','Displays Differences for Current File Using Version Control' },
      }
   },
   { "HTML",
      {
         { 'bbhtml_body.ico','insert_html_body','Insert or Adjust Body Tag in Current HTML File' },
         { 'bbhtml_style.ico','insert_html_styles','Insert Style Tag into Current HTML File' },
         { 'bbhtml_image.ico','insert_html_image','Insert Image into Current HTML File' },
         { 'bbhtml_link.ico','insert_html_link','Insert Link into Current HTML File' },
         { 'bbhtml_anchor.ico','insert_html_anchor','Insert Target into Current HTML File' },
         { 'bbhtml_applet.ico','insert_html_applet','Insert Java Applet into Current HTML File' },
         { 'bbhtml_script.ico','insert_html_script','Insert Script or Script Tag into Current HTML File' },
         { 'bbhtml_hline.ico','insert_html_hline','Insert Horizontal Line into Current HTML File' },
         { 'bbhtml_rgb_color.ico','insert_rgb_value','Insert RGB Value into Current HTML File' },
         { 'bbhtml_head.ico','insert_html_heading','Insert Heading Tag into Current HTML File' },
         { 'bbhtml_paragraph.ico','insert_html_paragraph','Insert Paragraph Tag into Current HTML File' },
         { 'bbhtml_bold.ico','insert_html_bold','Insert Bold Tag into Current HTML File' },
         { 'bbhtml_italic.ico','insert_html_italic','Insert Italic Tag into Current HTML File' },
         { 'bbhtml_underline.ico','insert_html_uline','Insert Underline Tag into Current HTML File' },
         { 'bbhtml_code.ico','insert_html_code','Insert Code Tag into Current HTML File' },
         { 'bbhtml_font.ico','insert_html_font','Insert Font Tag into Current HTML File' },
         { 'bbhtml_center.ico','insert_html_center','Insert Align Center Tag into Current HTML File' },
         { 'bbhtml_list.ico','insert_html_list','Insert Ordered/Unordered Tag into Current HTML File' },
         { 'bbhtml_right.ico','insert_html_right','Insert Align Right Tag into Current HTML File' },
         { 'bbhtml_table.ico','insert_html_table','Insert Table Tag into Current HTML File' },
         { 'bbhtml_table_row.ico','insert-html-table-row','Insert Table Row Tag into Current HTML File' },
         { 'bbhtml_table_cell.ico','insert_html_table_col','Insert Table Cell Tag into Current HTML File' },
         { 'bbhtml_table_header.ico','insert_html_table_header','Insert Table Header Tag into Current HTML File' },
         { 'bbhtml_table_caption.ico','insert_html_table_caption','Insert Table Caption Tag into Current HTML File' },
         { 'bbhtml_preview.ico','html-preview','Bring up Web Browser or Display HTML File in Web Browser' },
         { 'bbspell.ico','spell-check M','Spell Check from Cursor or Selected Text' },
         { 'bbftp.ico','toggle-ftp','Toggles FTP Client Toolbar On/Off' }
      }
   },
   { "XML",
      {
        { 'bbbeautify.ico','beautify_selection','Beautify Selection or Entire Buffer' },
        { 'bbxml_validate.ico','xml-validate','Validate XML Document' },
        { 'bbxml_wellformedness.ico','xml-wellformedness','Check for Well-Formedness' },
      }
   },
   { "Miscellaneous",
      {
         { 'bbvsehelp.ico','help -contents','SlickEdit Help' },
         { 'bbsdkhelp.ico','wh','Displays SDK Help for the Word at the Cursor' },
         { 'bbapi_index.ico','api-index','API Apprentice Help on Current Word' },
         { 'bbshell.ico','dos','Run the Operating System Command Shell' },
         { 'bbcolor.ico','color','Displays Color Settings Dialog Box' },
         { 'bbfont.ico','config Fonts','Displays Font Settings Dialog Box' },
         { 'bbkeys.ico','gui-bind-to-key','Allows you to Change Your Key Bindings' },
         { 'bbexit.ico','safe-exit','Prompts to Save Files if Necessary and Exits the Editor' },
      }
   },
   { "Space",
      {
         { "\tspace1",'','' },
      }
   },
};

int _TBDefaultsSupported(_str FormName )
{
   int i;
   for ( i = 0; i < gToolbarDefaultTab._length(); i++ ) {
      if ( FormName == gToolbarDefaultTab[i].FormName) {
         return( 1 );
      }
   }
   return( 0 );
}

void _tbGetDefaultToolbarControlList(_str formName, TBCONTROL (&defaultList)[])
{
   for (i := 0; i < gToolbarDefaultTab._length(); i++) {
      if (gToolbarDefaultTab[i].FormName == formName) {
         defaultList = gToolbarDefaultTab[i].CtrlList;
         break;
      }
   }
}

boolean _tbIsModifiedToolbar(_str FormName)
{
   // look up the form in the name table
   FormName = stranslate(FormName, '_', '-');
   int index = find_index(FormName,OBJECT_TYPE);
   if (index <= 0) {
      return true; // assume the worst
   }

   // look for the toolbar in the default toolbar table
   int i,n = gToolbarDefaultTab._length();
   for (i=0; i<n; ++i) {
      if (gToolbarDefaultTab[i].FormName == FormName) {
         int child=index.p_child;
         int j=0,m = gToolbarDefaultTab[i].CtrlList._length();
         for (;;) {
            // add this to the beginning in the case the user removed ALL 
            if (!child) break;

            TBCONTROL tbc = gToolbarDefaultTab[i].CtrlList[j];
            if (child.p_object == OI_IMAGE) {
               // check if bitmap names match
               if ( substr(tbc.name,1,1):!="\t") {
                  if (!child.p_picture || name_name(child.p_picture) != tbc.name) {
                     return true;
                  }
               }
               // check if command names match
               _str child_command = stranslate(child.p_command, '_', '-');
               _str tbc_command   = stranslate(tbc.command, '_', '-');
               if (child_command != tbc_command) {
                  return true;
               }
               // check if popup message matches
               if ( substr(tbc.name,1,1):!="\t" && child.p_message != tbc.msg) {
                  return true;
               }
            } else {
               if (substr(tbc.name,1,1):!="\t") {
                  return true;
               }
               if ( substr(tbc.name,2) != child.p_name ) {
                  return true;
               }
            }

            // next please
            ++j;
            child = child.p_next;
            if (child==index.p_child) child=0;
            if (!child || j>= m) {
               break;
            }
         }
         // make sure that we have check all controls in both sources
         if (j<m || child != 0) {
            return true;
         }
         // no modifications to this toolbar
         return false;
      }
   }

   // toolbar was not found at all, assume the worst
   return true;
}

void _tbPropsInitCategories()
{
   // Fill the category list and select the first category:
   int i;
   for ( i = 0; i < gToolbarCatTab._length(); i++ ) {
      ctlcatlist._lbadd_item( gToolbarCatTab[i].name );
   }
   //ctlcatlist.p_line = _bbe_cLastCategory + 1;
   ctlcatlist._lbtop();
   ctlcatlist._lbselect_line();
   _tbPropsShowControls( ctlcatlist.p_line - 1 );
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

static int s_lastUnifiedToolbarState = 1;

void _tbPropsSetupToolbars(int state)
{
   int i, n = def_toolbartab._length();
   for (i = 0; i < n; ++i) {
      if (def_toolbartab[i].tbflags & TBFLAG_SIZEBARS) {
         continue;
      }

      int wid = _tbIsVisible(def_toolbartab[i].FormName);
      if (wid != 0) {
         _tbPropsToolbarEdit(wid, state);
      }
   }

   if (!state) {
      _tbOnUpdate(true);
   }

   if (state) {
      s_lastUnifiedToolbarState = _QToolbarGetUnifiedToolbar();
      if (s_lastUnifiedToolbarState) {
         _tbSetUnifiedToolbar(0);
      }

   } else {
      _tbSetUnifiedToolbar(s_lastUnifiedToolbarState);
   }
}

int _tbLastUnifiedToolbarState(int value = null)
{
   if (value == null) {
      value = s_lastUnifiedToolbarState;
   } else {
      s_lastUnifiedToolbarState = value;
   }

   return value;
}

void _tbPropsShowControls( int cIndex )
{
   //ctldescription.p_caption="";
   int firstChild = ctlpicture.p_child;
   int prevchild = 0;
   int child = firstChild;
   if (child) {
      for ( ;; ) {
         //messageNwait( "child="child" name="child.p_name );
         prevchild=child;
         child = child.p_next;
         if ( child.p_next==child ) {
            prevchild._delete_window();
            break;
         }
         prevchild._delete_window();
      }
   }


   _str cName = gToolbarCatTab[cIndex].name;
   int NofControls = gToolbarCatTab[cIndex].CtrlList._length();
   ctlcontrols.p_caption = cName" Controls";
   int frame_wid=_control ctlpicture;

   int first_x=0;
   int x=0;
   int y=0;
   _lxy2lxy(SM_TWIP,SM_TWIP,x,y);

   int width,height;
   int wid = 0;
   int client_width=_dx2lx(SM_TWIP,frame_wid.p_client_width);
   int line_height=0;
   int i;
   for ( i = 0; i < NofControls; ++i) {
      _str picname = gToolbarCatTab[cIndex].CtrlList[i].name;
      if ( substr(picname,1,1):=="\t") {
         SPECIALCONTROL *psc;
         picname=substr(picname,2);
         psc=&gtwSpecialControlTab:[picname];
         wid=_create_window(psc->object,frame_wid,"",0,0,0,0,CW_CHILD);
         wid.p_tab_index=i+1;
         if (psc->eventtab_name!="") {
            wid.p_eventtab=frame_wid.p_eventtab;
         }
         switch (psc->object) {
         case OI_IMAGE:
            wid.p_picture=find_index('bbfind.ico',PICTURE_TYPE);
            wid.p_eventtab=defeventtab _toolbars_prop_form.ctlpicture;
            wid.p_eventtab2=defeventtab _ul2_picture;
            if (picname=='button') {
               // Note:
               // In 10.0 we support an Image control with both a caption AND a picture. This
               // means that the "Sample Button" on Toolbar Customization dialog must now have
               // its p_picture property =0. Now we must check in gtwSpecialControlTab for a
               // special control (e.g. space1..spaceX) and skip this loop when p_picture=0
               // and the image is not a special control.
               wid.p_picture=0;
               wid.p_message=psc->description;
               //wid.p_style=PSPIC_FLAT_BUTTON;
               wid.p_style=PSPIC_HIGHLIGHTED_BUTTON;
               wid.p_caption='Sample Button';
               width=wid.p_width;
               height=wid.p_height;
            } else if (picname=='space1') {
               height=wid.p_height;
               width=psc->width;
               wid.p_picture=0;
               wid.p_message=picname;
               wid.p_style = PSPIC_TOOLBAR_DIVIDER_VERT;

            } else {
               height=wid.p_height;
               width=psc->width;
               wid.p_picture=0;
               wid.p_message=picname;
               wid.p_border_style=BDS_FIXED_SINGLE;
            }
            break;
         case OI_COMBO_BOX:
            wid.p_name=picname;
            wid.p_width=psc->width;
            wid.p_eventtab=defeventtab _toolbars_prop_form.ctlpicture;
            wid.p_eventtab2=defeventtab _ul2_picture;
            wid.p_message=psc->description;
            //wid.p_eventtab=find_index(psc->eventtab,EVENTTAB_TYPE);
            //wid.p_eventtab2=defeventtab _ul2_combobx;
            width=wid.p_width;
            height=wid.p_height;
            _ComboBoxSetDragDrop(wid, 1);
            break;
         default:
            _message_box("Internal bug.  Control not supported");
            width=0;
            height=0;
         }
      } else {
         wid=_create_window(OI_IMAGE,frame_wid,"",0,0,0,0,CW_HIDDEN|CW_CHILD);
         wid.p_tab_index=i+1;
         int picindex = find_index( _strip_filename( picname,'p' ), PICTURE_TYPE );
         if ( !picindex ) continue;
         wid.p_picture=picindex;
         wid.p_command = gToolbarCatTab[cIndex].CtrlList[i].command;
         wid.p_message=gToolbarCatTab[cIndex].CtrlList[i].msg;
         //wid.p_style=PSPIC_FLAT_BUTTON;
         wid.p_style=PSPIC_HIGHLIGHTED_BUTTON;
         wid.p_eventtab=defeventtab _toolbars_prop_form.ctlpicture;
         wid.p_eventtab2=defeventtab _ul2_picture;
         width=wid.p_width;
         height=wid.p_height;
      }
      if (x+width>client_width) {
         x=first_x;
         y+=line_height;
      }
      wid._move_window(x,y,width,height);
      wid.p_visible=1;
      //messageNwait("w="client_width" width="width" height="height" line_height="line_height);
      if (height>line_height) {
         line_height=height;
      }
      x+=width;
   }
}

boolean _tbIsSpecialControl(_str name)
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

#define BBFIRST_XINDENT (_twips_per_pixel_x()*GetSystemMetrics(VSM_TOOLBAR_HANDLE_EXTENT))
#define BBFIRST_YINDENT 40

void _tbResizeButtonBar2(int& new_width, int& new_height)
{
   int child, first_child;
   first_child = child = p_child;
   if (child == 0) {
      return;
   }
   int h_space = def_toolbar_pic_hspace * _twips_per_pixel_x();
   int v_space = def_toolbar_pic_vspace * _twips_per_pixel_y();
   int h_space2 = h_space / 2;
   int x = BBFIRST_XINDENT + h_space;
   int y = BBFIRST_YINDENT + def_toolbar_pic_vspace * _twips_per_pixel_y();
   int line_height = 0;
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
         child.p_visible=1;
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
   int orig_form_wid=p_active_form;
   int orig_wid=p_window_id;
   int old_form_index=find_index(FormName,oi2type(OI_FORM));
   if (!old_form_index) return;
   int VisibleWid=_tbIsVisible(FormName);
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
            //wid.p_eventtab=defeventtab _toolbars_prop_form.ctlpicture;
            //wid.p_eventtab2=defeventtab _ul2_picture;
            if (picname=='button') {
               //wid.p_picture=find_index('bbfind.ico',PICTURE_TYPE);
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
         int picindex = find_index( _strip_filename( picname,'p' ), PICTURE_TYPE );
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

