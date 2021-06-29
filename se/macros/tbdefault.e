#include "slick.sh"
#include "toolbar.sh"
#import "tbcontrols.e"

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
        { 'bbnew','new','Create an Empty File to Edit' },
        { 'bbopen','gui-open','Open a File for Editing' },
        { 'bbsave','save','Save Current File' },
        { 'bbsave_history','history-diff-machine-file','List Backup History for Current File' },
        { 'bbprint','gui-print','Print Current File' },
        { "\tspace1",'','' },
        { 'bbcut','cut','Delete Selected Text and Copy to the Clipboard' },
        { 'bbcopy','copy-to-clipboard','Copy Selected Text to the Clipboard' },
        { 'bbpaste','paste','Paste Clipboard into Current File' },
        { 'bbselect_code_block','select-code-block','Select Lines in the Current Code Block' },
        { "\tspace1",'','' },
        { 'bbundo','undo','Undo the Last Edit Operation' },
        { 'bbredo','redo','Undo the Last Undo Operation' },
        { 'bbback','back','Navigate Backward' },
        { 'bbforward','forward','Navigate Forward' },
        { "\tspace1",'','' },
        { 'bbfind','gui-find','Search for a String You Specify' },
        { 'bbfind_next','find-next','Search for the Next Occurrence of the String You Last Searched' },
        { 'bbreplace','gui-replace','Search for a String and Replace it with Another String' },
        { "\tspace1",'','' },
        { 'bbfullscreen','fullscreen','Toggle Full Screen Editing Mode' },
        { 'bbconfig','config','Displays the configuration options dialog' },
        { 'bbvsehelp','help -contents','SlickEdit Help' },
      },
   },
   { "_tbproject_tools_form",
     {
        { 'bbnext_error','next-error','Process the Next Compiler Error Message' },
        { 'bbmake','project-build','Run the Build Command for the Current Project' },
        { 'bbcompile','project-compile','Run the Compile Command for the Current Project' },
        { "\tspace1",'','' },
        { 'bbcheckin','vccheckin','Check in Current File into Version Control System' },
        { 'bbcheckout','vccheckout','Check out or Update Current File from Version Control System' },
      },
   },
   { "_tbtools_form",
     {
        { 'bbbeautify','beautify_selection','Beautify Selection or Entire Buffer' },
        { 'bbdiff','diff','Bring Up DIFFzilla'VSREGISTEREDTM'' },
        { 'bbmerge','merge','Merge Two Sets of Changes Made to a File' },
        { 'bbfind_file','find-file','Search for File' },
        { 'bbcalculator','calculator','Display Calculator Dialog Box' },
        { 'bbshell','dos','Run the Operating System Command Shell' },
        { 'bbspell','spell-check M','Spell Check from Cursor or Selected Text' },
        { 'bbhex','hex','Toggle Hex Editing' },
     }
   },
   { "_tbedit_form",
     {
        { 'bblowcase','maybe-lowcase-selection','Translate Characters in Current Word or Selection to Lower Case' },
        { 'bbupcase','maybe-upcase-selection','Translate Characters in Current Word or Selection to Upper Case' },
        { 'bbshift_left','shift-selection-left','Left Shift Selection' },
        { 'bbshift_right','shift-selection-right','Right Shift Selection' },
        { 'bbreflow','reflow-selection','Word Wrap Current Paragraph or Selection' },
        { 'bbunindent_selection','unindent-selection','Unindent Selected Text' },
        { 'bbindent_selection','indent-selection','Indent Selected Text' },
        { 'bbtabs_to_spaces','convert_tabs2spaces','Convert Tabs to Spaces' },
        { 'bbspaces_to_tabs','convert_spaces2tabs','Convert Indentation Spaces to Tabs' },
        { 'bbfind_matching_paren','find-matching-paren','Find the Matching Parenthesis or Begin/End Structure Pairs' },
     }
   },
   { "_tbseldisp_form",
     {
        { 'bbshow_procs','show-procs','Outline Current File with Function Headings' },
        { 'bbhide_code_block','hide-code-block','Hide Lines inside Current Code Block' },
        { 'bbselective_display','selective-display','Display Selective Display Dialog Box' },
        { 'bbhide_selection','hide-selection','Hide Selected Lines' },
        { 'bbplusminus','plusminus','Toggles between hiding and showing the code block under the cursor' },
        { 'bbshow_all','show-all','End Selective Display. All Lines Are Displayed and Outline Bitmaps Are Removed.' },
     }
   },
   { "_tbxml_form",
     {
        { 'bbbeautify','beautify_selection','Beautify Selection or Entire Buffer' },
        { 'bbxml_validate','xml-validate','Validate XML Document' },
        { 'bbxml_wellformedness','xml-wellformedness','Check for Well-Formedness' },
     }
   },
   { "_tbhtml_form",
     {
        { 'bbhtml_body','insert_html_body','Insert or Adjust Body Tag in Current HTML File' },
        { 'bbhtml_style','insert_html_styles','Insert Style Tag into Current HTML File' },
        { 'bbhtml_image','insert_html_image','Insert Image into Current HTML File' },
        { 'bbhtml_link','insert_html_link','Insert Link into Current HTML File' },
        { 'bbhtml_anchor','insert_html_anchor','Insert Target into Current HTML File' },
        { 'bbhtml_applet','insert_html_applet','Insert Java Applet into Current HTML File' },
        { 'bbhtml_script','insert_html_script','Insert Script or Script Tag into Current HTML File' },
        { 'bbhtml_hline','insert_html_hline','Insert Horizontal Line into Current HTML File' },
        { 'bbhtml_rgb_color','insert_rgb_value','Insert RGB Value into Current HTML File' },
        { "\tspace1",'','' },
        { 'bbhtml_head','insert_html_heading','Insert Heading Tag into Current HTML File' },
        { 'bbhtml_paragraph','insert_html_paragraph','Insert Paragraph Tag into Current HTML File' },
        { 'bbhtml_bold','insert_html_bold','Insert Bold Tag into Current HTML File' },
        { 'bbhtml_italic','insert_html_italic','Insert Italic Tag into Current HTML File' },
        { 'bbhtml_underline','insert_html_uline','Insert Underline Tag into Current HTML File' },
        { 'bbhtml_font','insert_html_font','Insert Font Tag into Current HTML File' },
        { 'bbhtml_center','insert_html_center','Insert Align Center Tag into Current HTML File' },
        { 'bbhtml_right','insert_html_right','Insert Align Right Tag into Current HTML File' },
        { 'bbhtml_list','insert_html_list','Insert Ordered/Unordered Tag into Current HTML File' },
        { "\tspace1",'','' },
        { 'bbhtml_table','insert_html_table','Insert Table Tag into Current HTML File' },
        { 'bbhtml_table_row','insert-html-table-row','Insert Table Row Tag into Current HTML File' },
        { 'bbhtml_table_cell','insert_html_table_col','Insert Table Cell Tag into Current HTML File' },
        { 'bbhtml_table_header','insert_html_table_header','Insert Table Header Tag into Current HTML File' },
        { 'bbhtml_table_caption','insert_html_table_caption','Insert Table Caption Tag into Current HTML File' },
        { "\tspace1",'','' },
        { 'bbhtml_preview','html-preview','Bring up Web Browser or Display HTML File in Web Browser' },
        { 'bbspell','spell-check M','Spell Check from Cursor or Selected Text' },
        { 'bbbeautify','h_beautify_selection','Beautify Selection or Entire Buffer' },
        { 'bbftp','ftpOpen','Activate FTP Tab for Opening FTP Files' }
     }
   },
   { "_tbtagging_form",
     {
        { 'bbmake_tags','gui-make-tags','Build Tag Files for Use by the Symbol Browser and Other Context Tagging'VSREGISTEREDTM' Features' },
        { 'bbfind_symbol','gui-push-tag','Activate the Find Symbol Tool Window to Locate Tags' },
        { 'bbclass_browser_find','cb-find','Find the Symbol under the Cursor and Display in Symbol Browser' },
        { 'bbfind_refs','push-ref','Go to Reference' },
        { 'bbpush_tag','push-tag','Go to Definition' },
        { 'bbpush_decl','push-alttag','Go to Declaration' },
        { 'bbpop_tag','pop-bookmark','Pop the Last Bookmark' },
        { 'bbnext_tag','next-tag','Place Cursor on Next Symbol Definition' },
        { 'bbprev_tag','prev-tag','Place Cursor on Previous Symbol Definition' },
        { 'bbend_tag','end-tag','Place Cursor at the End of the Current Symbol Definition' },
        { 'bbfunction_help','function-argument-help','Display Prototype(s) and Highlight Current Argument' },
        { 'bblist_symbols','list-symbols','List Valid Symbols for Current Context' },
        { 'bbrefactor_rename','refactor_quick_rename precise','Rename Symbol under Cursor' },
     }
   },
   { "_tbdebugbb_form",
     {
        { 'bbdebug_restart','debug_restart','Restart Execution' },
        { 'bbdebug_continue','project_debug','Continue Execution' },
        { 'bbdebug_suspend','debug_suspend','Suspend Execution' },
        { 'bbdebug_stop','debug_stop','Stop Debugging' },
        { "\tspace1",'','' },
        { 'bbdebug_show_next_statement','debug_show_next_statement','Displays the Source Line for the Instruction Pointer' },
        { 'bbdebug_step_into','debug_step_into','Step into a Function' },
        { 'bbdebug_step_over','debug_step_over','Step over the Next Statement' },
        { 'bbdebug_step_out','debug_step_out','Step out of the Current Function' },
        { 'bbdebug_step_deep','debug_step_deep','Step into Next Statement (Will Step into Runtimes)' },
        { 'bbdebug_step_instruction','debug_step_instr','Step by One Instruction' },
        { 'bbdebug_run_to_cursor','debug_run_to_cursor','Continue until Line Cursor is on' },
        { "\tspace1",'','' },
        { 'bbdebug_toggle_breakpoint','debug_toggle_breakpoint','Toggle Breakpoint' },
        { 'bbdebug_toggle_enabled','debug_toggle_breakpoint_enabled','Toggle Breakpoint between Enabled and Disabled' },
        { 'bbdebug_disable_breakpoints','debug_disable_all_breakpoints','Disable All Breakpoints' },
        { 'bbdebug_breakpoints','debug_breakpoints','View or Modify Breakpoints' },
        { "\tspace1",'','' },
        { 'bbdebug_add_watch','debug_add_watch','Add a Watch on the Current Variable' },
        { 'bbdebug_toggle_disassembly','debug_toggle_disassembly','Toggle Display of Disassembly' },
        { 'bbdebug_toggle_hex','debug_toggle_hex','Toggle Between Default and Hexadecimal Variable Display' },
     }
   },
   { "_tbvc_form",
     {
        { 'bbvc_diff','svc-diff-with-tip','Diff current file with the most recent version' },
        { 'bbvc_diff_symbol','svc-diff-current-symbol-with-tip','Diff the current symbol with the most recent version' },
        { 'bbvc_diff_tags','svc-diff-symbols-with-tip','Diff all symbols in the current file with the most recent version' },
        { 'bbvc_history','svc-history','Show Version Control history for the current file' },
        { "\tspace1",'','' },
        { 'bbcheckin','svc-commit','Checks in current file' },
        { 'bbcheckout','svc-checkout','Checks out source code from Version Control' },
        { 'bbvc_lock','vclock','Locks the current file without checking out the file' },
        { 'bbvc_unlock','vcunlock','Unlocks the current file without checking in the file' },
        { "\tspace1",'','' },
        { 'bbvc_update','svc-update','Get most recent version of current file from version control' },
        { 'bbvc_dir_update','svc-gui-mfupdate','Compare Directory with Version Control' },
        { 'bbvc_project_update','svc-gui-mfupdate-project','Compare current Project with Version Control' },
        { 'bbvc_project_dependencies','svc-gui-mfupdate-project-dependencies','Compare current Project and Dependencies with Version Control' },
        { 'bbvc_workspace_update','svc-gui-mfupdate-workspace','Compare Workspace with Version Control' },
        { "\tspace1",'','' },
        { 'bbvc_add','svc-add','Add Current file to version control' },
        { 'bbvc_setup','vcsetup','Allows you to choose and configure a Version Control interface' },
     }
   },
   { "_tbunified_form",
     {
        { 'bbnew','new','Create an Empty File to Edit' },
        { 'bbopen','gui-open','Open a File for Editing' },
        { 'bbsave','save','Save Current File' },
        { 'bbsave_history','activate-deltasave','List Backup History for Current File' },
        { "\tspace1",'','' },
        { 'bbcut','cut','Delete Selected Text and Copy to the Clipboard' },
        { 'bbcopy','copy-to-clipboard','Copy Selected Text to the Clipboard' },
        { 'bbpaste','paste','Paste Clipboard into Current File' },
        { "\tspace1",'','' },
        { 'bbundo','undo','Undo the Last Edit Operation' },
        { 'bbredo','redo','Undo the Last Undo Operation' },
        { 'bbback','back','Navigate Backward' },
        { 'bbforward','forward','Navigate Forward' },
        { 'bbfind','gui-find','Search for a String You Specify' },
        { "\tspace1",'','' },
        { 'bbmake','project-build','Run the Build Command for the Current Project' },
        { 'bbdebug','project-debug','Run the Debug Command for the Current Project' },
        { "\tspace1",'','' },
        { 'bbfullscreen','fullscreen','Toggle Full Screen Editing Mode' },
        { "\tspace1",'','' },
        { "\t_tbcontext_combo_etab",'','Current Context' },
      },
   },
   { "_tbandroid_form",
     {
        { 'bbandroid_avd','android-avd-manager','Launch Android Virtual Device Manager' },
        { 'bbandroid_sdk','android-sdk-manager','Launch Android SDK Manager' },
        { 'bbandroid_ddms','android-ddms','Launch DDMS (Dalvik Debug Monitor)' },
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

bool _tbIsModifiedToolbar(_str FormName)
{
   // look up the form in the name table
   FormName = stranslate(FormName, '_', '-');
   index := find_index(FormName,OBJECT_TYPE);
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
                  if (!child.p_picture || (name_name(child.p_picture) != tbc.name && _strip_filename(name_name(child.p_picture),'pe') != tbc.name)) {
                     return true;
                  }
               }
               // check if command names match
               child_command := stranslate(child.p_command, '_', '-');
               tbc_command := stranslate(tbc.command, '_', '-');
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
