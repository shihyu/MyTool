////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49292 $
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
#import "compile.e"
#import "complete.e"
#import "diff.e"
#import "fileman.e"
#import "guifind.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "mfsearch.e"
#import "picture.e"
#import "printcommon.e"
#import "recmacro.e"
#import "savecfg.e"
#import "seek.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#endregion

static _str gprinter_setup,oprinter_setup;
static SEQtPrintOptions gqtprint_options;
//static _str gqtpagesetup_options;

#define PRINTSCHEME_INI_FILENAME "print.ini"
#define DEFAULTPRINTSCHEME "(none)"
#define PREVIOUSVALUESPRINTSCHEME '<Previous values>'

// PrintScheme defines all the values for a print scheme.
struct PrintScheme {
   _str options:[];
   int user; // Flag: 1=user-defined scheme
};
static int gIgnoreSchemeModify = 0;
static int gIgnoreSchemeListOnChange = 0;

defeventtab _printSchemeSave_form;
void ctlOK.lbutton_up()
{
   // Make sure scheme name is different from any existing ones.
   _str name = ctlSchemeName.p_text;
   if (name == "") {
      _message_box(nls("Missing scheme name."));
      ctlSchemeName._set_focus();
      return;
   }
   PrintScheme p:[];
   p = ctlOK.p_user;
   typeless i;
   for (i._makeempty();;) {
      p._nextel(i);
      if (i._isempty()) break;
      if (lowcase(name) == lowcase(i)) {
         // For non user-defined scheme, must be a new scheme name.
         if (!p:[name].user) {
            _message_box(nls("Scheme name already exists.\n\nPlease use a new name."));
            ctlSchemeName._set_focus();
            return;
         }
      } else if (lowcase(name) == DEFAULTPRINTSCHEME) {
         _message_box(nls("Scheme name cannot be the default name.\n\nPlease use a new name."));
         ctlSchemeName._set_focus();
         return;
      }
   }

   // Return new name.
   p_active_form._delete_window(name);
}
void ctlOK.on_create(PrintScheme (&p):[], _str defaultSaveSchemeName, _str mode)
{
   // Save the hash for access by save.
   ctlOK.p_user = p;

   // Check the mode and change the dialog title.
   if (mode == "rename") {
      p_active_form.p_caption = "Rename Scheme";
   }

   // Add the scheme names to the combo list.
   // Ignore the default scheme.
   int listwid = ctlSchemeName.p_window_id;
   listwid._lbclear();
   listwid.top();
   typeless i;
   for (i._makeempty();;) {
      p._nextel(i);
      if (i._isempty()) break;
      if (lowcase(i) == DEFAULTPRINTSCHEME) continue;
      listwid._lbadd_item(i);
   }
   listwid._lbsort("AI");
   ctlSchemeName.p_text = defaultSaveSchemeName;
}

/* sys_message,reserved,callback_index,font,header,footer,options */
defeventtab _print_form;
void ctlPreview.lbutton_up()
{
   // Set print options for preview
   if (gqtprint_options._isempty()) {
      gqtprint_options.m_deviceName='';
      gqtprint_options.m_collate=false;
      gqtprint_options.m_haveSelection=_selection_only.p_enabled?true:false;
   }
   gqtprint_options.m_landscape=ctllandscape.p_value?true:false;
   gqtprint_options.m_selection=_selection_only.p_value?true:false;
   if (isinteger(ctlCopies.p_text) && ctlCopies.p_text>0) {
      gqtprint_options.m_copyCount=(int)ctlCopies.p_text;
   } else {
      gqtprint_options.m_copyCount=1;
   }
   _QtPrintDialog(gqtprint_options,false /* don't show dialog */);

   PrintScheme p:[];
   p= ctlSchemeSave.p_user;
   _str currentScheme = ctlSchemeList.p_text;

   int editorctl_wid = 0;
   boolean printSelections = _selection_only.p_value ? true:false;
   VSPRINTOPTIONS printOptions;
   printOptions.print_header = _lheader.p_text;
   printOptions.print_cheader = _cheader.p_text;
   printOptions.print_rheader = _rheader.p_text;
   printOptions.print_footer = _lfooter.p_text;
   printOptions.print_cfooter = _cfooter.p_text;
   printOptions.print_rfooter = _rfooter.p_text;
   printOptions.print_font = _fonttext.p_text;
   int print_flags= 0;
   if (_print_color.p_value && _print_color.p_enabled) print_flags|=PRINT_COLOR;
   if (ctlColorCoding.p_value && ctlColorCoding.p_enabled) print_flags|=PRINT_FONTATTRS;
   if (ctlBgColor.p_value && ctlBgColor.p_enabled) print_flags|=PRINT_BACKGROUND;
   if (_two_up.p_value) print_flags|=PRINT_TWO_UP;
   if (ctlvisibleonly.p_value && ctlvisibleonly.p_enabled) print_flags|=PRINT_VISIBLEONLY;
   if (ctlhex.p_value && ctlhex.p_enabled) {
      print_flags|=PRINT_HEX;
   }
   typeless AfterHeader_ma=0;
   typeless BeforeFooter_ma=0;
   typeless top_ma=0;
   typeless left_ma=0;
   typeless bottom_ma=0;
   typeless right_ma=0;
   typeless space_between_ma=0;
   if(_check_inch(_control ctlAfterHeader,AfterHeader_ma)) return;
   if(_check_inch(_control ctlBeforeFooter,BeforeFooter_ma)) return;
   if(_check_inch(_control _top_ma,top_ma)) return;
   if(_check_inch(_control _left_ma,left_ma)) return;
   if(_check_inch(_control _bottom_ma,bottom_ma)) return;
   if(_check_inch(_control _right_ma,right_ma)) return;
   if(_check_inch(_control _space_between_ma,space_between_ma)) return;
   printOptions.print_options= left_ma','AfterHeader_ma','right_ma','BeforeFooter_ma','space_between_ma','print_flags','_linenums_every.p_text','top_ma','bottom_ma;
   doQtPreviewDialog(editorctl_wid,printOptions,printSelections);
   /*show("-modal -xy _PrintPreview_form",editorctl_wid,printOptions,printSelections);
   if (_param1) {
       _ok.call_event(false,_ok,LBUTTON_UP,'W');
   } */
}
static void doQtPreviewDialog(int editorctl_wid=0,VSPRINTOPTIONS PrintOptions=null,boolean printSelection=false)  {

   int status=0;
   if (!editorctl_wid) {
      editorctl_wid=_form_parent();
      if (!editorctl_wid._isEditorCtl()) {
         editorctl_wid=_mdi.p_child;
      }
   }
   _str buf_name=editorctl_wid.p_buf_name;
   if (buf_name=='') buf_name=editorctl_wid.p_DocumentName;
   if (PrintOptions==null) {
      PrintOptions=gvsPrintOptions;
   }
   _str print_options=PrintOptions.print_options;
   typeless left_ma, AfterHeader_ma, right_ma, BeforeFooter_ma, space_between_ma;
   typeless print_flags, linenums_every, top_ma, bottom_ma, pageleft_ma, pageright_ma;

   int temp_view_id=0;
   //printSelection=true;
   if (printSelection) {
      int orig_view_id=0;
      get_window_id(orig_view_id);
      p_window_id=editorctl_wid;
      int mark= _duplicate_selection();    /* Save the users mark. */
      if ( mark<0  ) return;
      typeless junk;
      int buf_id=0;
      status=_get_selinfo(junk,junk,buf_id);
      if ( status ) {
         _free_selection(mark);
         return;
      }

      parse print_options with left_ma','AfterHeader_ma','right_ma','BeforeFooter_ma','space_between_ma','print_flags','linenums_every','top_ma','bottom_ma','pageleft_ma','pageright_ma',';
      // Save old buffer cursor position so mark does not move.
      _next_buffer('h');_prev_buffer('h');

      _create_temp_view(temp_view_id);
      p_UTF8=editorctl_wid.p_UTF8;
      int old_buf_id=p_buf_id;
      p_buf_id=buf_id;
      _str lang=p_LangId;
      save_pos(auto p);
      _str selection_text='';
      _begin_select();
      if ((print_flags & PRINT_HEX) && _select_type()!='BLOCK') {
         typeless start_seekpos=_nrseek();
         // This code for hex does not support imaginary lines.
         _end_select();
         if (_select_type(mark,'I')) {
            right();
         }
         typeless end_seekpos=_nrseek();
         _begin_select();
         int count=end_seekpos-start_seekpos;
         typeless orig=_default_option(VSOPTION_WARNING_STRING_LENGTH);
         if (count+100 > orig) {
            _default_option(VSOPTION_WARNING_STRING_LENGTH,count+100);
         }
         selection_text=get_text(count);
         _default_option(VSOPTION_WARNING_STRING_LENGTH,orig);
      }

      typeless RealLineNumber=0;
      if (print_flags & PRINT_HEX) {
         if (_select_type()=='LINE') {
            _begin_line();
         }
         RealLineNumber=_QROffset();
         //messageNwait('RealLineNumber='RealLineNumber);
      } else {
         RealLineNumber=p_RLine;
      }
      restore_pos(p);
      _str tabs=p_tabs;
      int buf_width=p_buf_width;
      buf_name=p_buf_name;
      if (buf_name=='') buf_name=p_DocumentName;

      p_buf_id=old_buf_id;
      _SetEditorLanguage(lang);
      p_buf_name=buf_name;
      p_tabs=tabs;
      if ((print_flags & PRINT_HEX) && _select_type()!='BLOCK') {
         insert_line('');
         replace_line(selection_text);_end_line();_delete_text(-2);
      } else {
         if (_select_type()!='LINE') {
            insert_line("");
         }
         _copy_to_cursor(mark,VSMARKFLAG_COPYNOSAVELF);
      }
      _free_selection(mark);
      print_options=left_ma','AfterHeader_ma','right_ma','BeforeFooter_ma','space_between_ma','print_flags','linenums_every','top_ma','bottom_ma','pageleft_ma','pageright_ma','RealLineNumber;
      p_show_tabs=0;
      editorctl_wid=p_window_id;
      activate_window(orig_view_id);
   }
   parse print_options with left_ma','AfterHeader_ma','right_ma','BeforeFooter_ma','space_between_ma','print_flags','linenums_every','top_ma','bottom_ma;

   _QtPrintPreviewDialog(
          (editorctl_wid.p_DocumentName!='')?editorctl_wid.p_DocumentName:editorctl_wid.p_buf_name,
          editorctl_wid,
          _print_callback,
          PrintOptions.print_font,
          _insert_print_options(PrintOptions.print_header,editorctl_wid.p_buf_name,editorctl_wid.p_DocumentName),
          _insert_print_options(PrintOptions.print_footer,editorctl_wid.p_buf_name,editorctl_wid.p_DocumentName),
          print_options,
          _insert_print_options(PrintOptions.print_cheader,editorctl_wid.p_buf_name,editorctl_wid.p_DocumentName),
          _insert_print_options(PrintOptions.print_cfooter,editorctl_wid.p_buf_name,editorctl_wid.p_DocumentName),
          _insert_print_options(PrintOptions.print_rheader,editorctl_wid.p_buf_name,editorctl_wid.p_DocumentName),
          _insert_print_options(PrintOptions.print_rfooter,editorctl_wid.p_buf_name,editorctl_wid.p_DocumentName)
          );
   if (temp_view_id) _delete_temp_view(temp_view_id);
}

void _space_between_ma.on_change()
{
   schemeModified();
}
void ctlClose.lbutton_up()
{
   // If the current scheme is modified, prompt the user.
   //int status = promptForSaveOnClose();
   //if (status == 1) return; // user cancelled
   //if (status) return; // some update error
   rememberLastScheme();
   p_active_form._delete_window();
}
void ctlColorCoding.lbutton_up()
{
   schemeModified();
}

// Marks the current scheme as modified.
void ctlBgColor.lbutton_up()
{
   schemeModified();
}


// Check to see if the current scheme is modified and prompt user
// to save the scheme.
// Retn: 0 OK and proceed like normal
//       1 user cancelled
//       3 can't update ini file
static int promptForSaveOnClose()
{
   // If the current scheme is modified, prompt the user.
   if (ctlSchemeDelete.p_user == 1) {
      int status;
      status = _message_box(nls("You have a modified scheme.\nDo you wish to save it?"),"",MB_YESNOCANCEL|MB_ICONQUESTION);
      if (status == IDCANCEL) {
         return(1);
      } else if (status == IDYES) {
         status = call_event(_control ctlSchemeSave, LBUTTON_UP);
         return(status);
      } else {
         ctlSchemeDelete.p_user = 0;
      }
   }
   return(0);
}

// Mark the current scheme modified.
static void schemeModified()
{
   if (gIgnoreSchemeModify) return;
   _str schemeName = ctlSchemeList.p_text;
   if (schemeName == DEFAULTPRINTSCHEME) return;
   if (!pos("(Modified)", schemeName, 1, 'I')) {
      // Update scheme list text box to indicate modified scheme.
      schemeName = strip(schemeName,'B'):+' (Modified)';
      ++gIgnoreSchemeListOnChange;
      setCurrentSchemeName(schemeName);
      --gIgnoreSchemeListOnChange;
   }

   // Flag current scheme modified.
   ctlSchemeDelete.p_user = 1;
}
void ctlSchemeList.on_change(int reason)
{
   if (gIgnoreSchemeListOnChange) return;
   if (reason == CHANGE_CLINE) {
      if (!p_Noflines) return;
      // Get current scheme name.
      //_str oldScheme = ctlSchemeList.p_cb_text_box.p_text;
      //parse oldScheme with oldScheme ' (Modified)';

      // Get the selected scheme name from the combo list box.
      int listwid = ctlSchemeList.p_window_id;
      //listwid._lbfind_selected(1);
      _str schemeName = listwid._lbget_text();

      // If same scheme, do nothing.
      //if (schemeName == oldScheme) return;

      // Prompt user to save modified scheme before switching
      // to another scheme.
      //if (ctlSchemeDelete.p_user == 1) {
      //   int status = promptForSaveOnClose();
      //   if (status) return;
      //}

      ctlSchemeDelete.p_enabled=true;
      // Update combo text box.
      //setCurrentSchemeName(schemeName);

      // Fill the dialog with selected scheme values.
      PrintScheme p:[];
      p = ctlSchemeSave.p_user;
      fillSchemeDialog(p, schemeName);
   }
}

// Save the current scheme.
// Retn: 0 OK and current scheme save
//       1 user cancelled
//       3 can't update ini file
int ctlSchemeSave.lbutton_up(_str saveName='')
{
   // Always write to the user ini file.
   _str inifile =_ConfigPath():+VSCFGFILE_USER_PRINTSCHEMES;

   // Determine whether we need to prompt for a scheme name for saving.
   PrintScheme p:[];
   p = ctlSchemeSave.p_user;
   _str currentScheme = ctlSchemeList.p_text;
   int prompt = 0;
   _str defaultSaveSchemeName = "";
   if (saveName!='') {
      currentScheme=saveName;
   } else if (currentScheme == "" || currentScheme == DEFAULTPRINTSCHEME) {
      prompt = 1;
   } else if (pos(PREVIOUSVALUESPRINTSCHEME,currentScheme,1,'i')==1) {
      prompt = 1;
      defaultSaveSchemeName=PREVIOUSVALUESPRINTSCHEME;
   } else if (pos("(Modified)", currentScheme, 1, 'I')) {
      // Prompt for new name. If the scheme is not user-defined,
      // append "User". Otherwise, default to the original name.
      prompt = 1;
      _str nameOnly;
      parse currentScheme with nameOnly ' (Modified)';
      if (!p:[nameOnly].user) {
         defaultSaveSchemeName = nameOnly:+" User";
      } else {
         defaultSaveSchemeName = nameOnly;
      }
   } else {
      // If scheme is not user-defined, prompt for new name.
      if (!p:[currentScheme].user) {
         prompt = 1;
         defaultSaveSchemeName = currentScheme:+" User";
      } else {
         // If user scheme is unmodified, do nothing.
         if (ctlSchemeDelete.p_user == 0) {
            int answer = _message_box(nls("Current scheme has not been modified.\n\nSave using a different name?"),"",MB_YESNOCANCEL|MB_ICONQUESTION);
            if (answer != IDYES) return(1); // user cancelled
            prompt = 1;
         }
      }
   }
   if (prompt) {
      currentScheme = show("-modal _printSchemeSave_form",p,defaultSaveSchemeName,"save");
      if (currentScheme == "") return(1); // user cancelled
   }

   if (strieq(currentScheme,PREVIOUSVALUESPRINTSCHEME)) {
      _find_save_form_response();
   }
   // Update the named schemed in the hash.
   updateCurrentPrintScheme(p, currentScheme);
   ctlSchemeSave.p_user = p;

   // Write all user-defined schemes to the user ini file.
   int status = writePrintScheme(p, inifile);
   if (status) return(3);

   // Reinit the scheme list and combo text showing current scheme.
   fillSchemeNameList(p);
   setCurrentScheme(p,currentScheme);
   return(0);
}

// Delete the current scheme.
// Retn: 0 OK and scheme deleted
//       1 user cancelled
//       2 non user-defined scheme can not deleted
//       3 can't update ini file
int ctlSchemeDelete.lbutton_up()
{
   // Always update the user ini file.
   _str inifile =usercfg_init_write(VSCFGFILE_USER_PRINTSCHEMES);

   // Can only delete user-defined schemes.
   PrintScheme p:[];
   p = ctlSchemeSave.p_user;
   _str currentScheme = ctlSchemeList.p_text;
   if (currentScheme == "" || lowcase(currentScheme) == DEFAULTPRINTSCHEME) {
      return(2);
   } else if (pos("(Modified)", currentScheme, 1, 'I')) {
      parse currentScheme with currentScheme ' (Modified)';
   }
   if (p:[currentScheme]._varformat()==VF_EMPTY) {
      return(2);
   }
   if (!p:[currentScheme].user) {
      _message_box(nls("Only user-defined schemes can be deleted."));
      return(2);
   }

   // Get the scheme immediately after/before the scheme to be deleted
   // in the scheme list.
   _str last = "";
   _str nextScheme = "";
   int listwid = ctlSchemeList.p_window_id;
   listwid.top();
   listwid.up();
   while (!listwid.down()) {
      _str line = listwid._lbget_text();
      if (lowcase(line) == lowcase(currentScheme)) {
         if (listwid.p_line == listwid.p_Noflines) {
            nextScheme = last;
         } else {
            listwid.down();
            nextScheme = listwid._lbget_text();
         }
         break;
      }
      last = line;
   }
   if (nextScheme == "") nextScheme = PREVIOUSVALUESPRINTSCHEME;

   // Remove scheme from hash.
   p._deleteel(currentScheme);
   ctlSchemeSave.p_user = p;

   // Write all user-defined schemes to the user ini file.
   int status = writePrintScheme(p, inifile);
   if (status) return(3);

   // Reinit the scheme list and select the default scheme.
   fillSchemeNameList(p);
   setCurrentScheme(p, nextScheme);
   fillSchemeDialog(p, nextScheme);
   return(0);
}

// Rename the current scheme
// Retn: 0 OK and scheme deleted
//       1 user cancelled
//       2 non user-defined scheme can not renamed
//       3 can't update ini file
int ctlSchemeRename.lbutton_up()
{
   // Always update the user ini file.
   _str inifile =_ConfigPath():+VSCFGFILE_USER_PRINTSCHEMES;

   // Can only rename user-defined schemes.
   PrintScheme p:[];
   p = ctlSchemeSave.p_user;
   _str currentScheme = ctlSchemeList.p_text;
   int prompt = 0;
   if (currentScheme == "" || lowcase(currentScheme) == DEFAULTPRINTSCHEME ||
       pos(PREVIOUSVALUESPRINTSCHEME,currentScheme,1,'i')==1) {
      prompt = 1;
   } else if (pos("(Modified)", currentScheme, 1, 'I')) {
      parse currentScheme with currentScheme ' (Modified)';
   }
   if (prompt || !p:[currentScheme].user) {
      int answer = _message_box(nls("Only user-defined schemes can be renamed.\n\nWould you like to save this scheme under a different name?"),"",MB_YESNO|MB_ICONQUESTION);
      if (answer != IDYES) return(1);
      int status = call_event(_control ctlSchemeSave, LBUTTON_UP, 'W');
      return(status);
   }

   // Get new name.
   _str defaultSaveSchemeName = "";
   _str newScheme = show("-modal _printSchemeSave_form",p,defaultSaveSchemeName,"rename");
   if (newScheme == "") return(1); // user cancelled

   // Copy old scheme in hash to new scheme in hash.
   p:[newScheme] = p:[currentScheme];

   // Delete old scheme in hash.
   p._deleteel(currentScheme);
   ctlSchemeSave.p_user = p;

   // Write all user-defined schemes to the user ini file.
   int status = writePrintScheme(p, inifile);
   if (status) return(3);

   // Reinit the scheme list and select the default scheme.
   fillSchemeNameList(p);
   setCurrentScheme(p, newScheme);
   fillSchemeDialog(p, newScheme);
   return(0);
}
void ctlhex.lbutton_up()
{
   int wid=0;
   boolean enabled=!(ctlhex.p_value && ctlhex.p_enabled);
   if (enabled) {
      wid=_form_parent();
      if (wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
         ctlvisibleonly.p_enabled=wid.p_Nofhidden!=0;
      } else {
         ctlvisibleonly.p_enabled=0;
      }
   } else {
      ctlvisibleonly.p_enabled=enabled;
   }
   wid=_form_parent();
   if (wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP) &&
       wid.p_lexer_name=='') {
      ctlColorCoding.p_enabled=_print_color.p_enabled=ctlBgColor.p_enabled=false;
      //ctlColorCoding.p_value=_print_color.p_value=0;
   }
   _linenums_every.p_enabled=enabled;
   ctllinenums_everylab.p_enabled=enabled;
}
_mfhook.lbutton_up(int reason,typeless info)
{
   int wid=0;
   if (reason==CHANGE_SELECTED) {
      if (info) {
         // Some files or buffers have been selected
         if (_selection_only.p_enabled) _selection_only.p_enabled=0;
         if (ctlvisibleonly.p_enabled) ctlvisibleonly.p_enabled=0;
         if (ctlhex.p_enabled) {
            ctlhex.p_enabled=0;
            ctlhex.call_event(ctlhex,LBUTTON_UP);
         }
         if (ctlPreview.p_enabled) {
            ctlPreview.p_enabled=false;
         }
         wid=_form_parent();
         if (wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
            ctlBufName.p_enabled=0;
         }
      } else {
         wid=_form_parent();
         if (wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
            ctlBufName.p_enabled=1;
         }
         // No files or buffers are selected
         if (!_selection_only.p_enabled) {
            wid=_form_parent();
            if (wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP)
                && wid.select_active()) {
               _selection_only.p_enabled=1;
            }
         }
         if (!ctlvisibleonly.p_enabled) {
            wid=_form_parent();
            if (wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
               ctlvisibleonly.p_enabled= wid.p_Nofhidden!=0;
            }
         }
         if (!ctlhex.p_enabled) {
            wid=_form_parent();
            if (wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP) && !wid.p_UTF8) {
               ctlhex.p_enabled= 1;
               ctlhex.call_event(ctlhex,LBUTTON_UP);
            }
         }
         if (wid.p_mdi_child && _no_child_windows()) {
            ctlPreview.p_enabled=false;
         } else if (!ctlPreview.p_enabled) {
            ctlPreview.p_enabled=true;
         }
         wid=_form_parent();
         if (wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP) &&
             wid.p_lexer_name=='') {
            ctlColorCoding.p_enabled=_print_color.p_enabled=ctlBgColor.p_enabled=false;
            //ctlColorCoding.p_value=_print_color.p_value=0;
         }
      }
   }
}
/** 
 * Displays Print dialog box.  This form is not supported by the UNIX 
 * version.
 * 
 * @return Returns '' if the dialog box is cancelled.  Returns 0 if the user has 
 * specified to print the selection and sets the global variables _param1, 
 * _param2, _param3, and _param4.   The _param1-_param4 variables 
 * may be passed as arguments 1-4 to the <b>print_selection</b> 
 * function to perform the printing.  1 is returned if the user has selected 
 * to print the current buffer and the global variables _param1-_param4 
 * are set.   The _param1-_param4 variables may be passes as arguments 
 * 1-4 to the <b>_print</b> function to perform the printing
 * 
 * @categories Buffer_Functions
 * 
 */ 
void _ok.on_create()
{
   _str printer="";
   _str port="";
   typeless status=0;
   _str rest="";

   // Get the printer device name
   SEQtPrintOptions qtprint_options;
   _QtPrintDialog(qtprint_options,false /* don't show dialog */);
   ctlprinter.p_caption=qtprint_options.m_deviceName;

   _print_form_initial_alignment();

#if 0
   if (machine()=='WINDOWS') {
      parse gprinter_setup with "," +0 rest ;
      status=_printer_setup(rest,'R',gprinter_setup);
      if (status) {
         _message_box(get_message(status));
         p_active_form._delete_window();
         return;
      }
      parse gprinter_setup with printer",";
      _printer_setup('','P',port);
      ctlprinter.p_caption=printer" on "port;
#if 0
      if (gprinter_setup!="") {
         parse gprinter_setup with printer "," ; //"," "," port
         ctlprinter.p_caption=printer;
      } else {
         parse _ntgetdefaultprintinfo() with printer"," "," port ;
         ctlprinter.p_caption=printer" on "port;
      }
#endif
   } else {
      ctlprinter.p_visible=ctlprinter.p_prev.p_visible=0;
      ctlorientation.p_visible=0;
   }
#endif


   int wid=_form_parent();
   boolean nowins=!wid.p_HasBuffer || (wid.p_window_flags & HIDE_WINDOW_OVERLAP);
   int Nofhidden=0;
   int hex_mode=0;
   boolean utf8=0;
   _str caption="";
   if (!nowins) {
      caption=ctlBufName._ShrinkFilename(wid.p_buf_name,ctlBufName.p_width);
      ctlBufName.p_caption=caption;
      Nofhidden= wid.p_Nofhidden;
      hex_mode=wid.p_hex_mode;
      utf8=wid.p_UTF8;
   }
   // If parent window is not an MDI child window
   if (!wid.p_mdi_child) {
      _mfmore.p_enabled=0;
   }
   if (nowins) {
      _mfmore.call_event(_mfmore,LBUTTON_UP);
   } else {
      _mfhook.call_event(CHANGE_SELECTED,0,_mfhook,LBUTTON_UP,'w');
   }
   _fonttext.p_text=gvsPrintOptions.print_font;

   typeless AfterHeader_ma=0;
   typeless BeforeFooter_ma=0;
   typeless top_ma=0;
   typeless left_ma=0;
   typeless bottom_ma=0;
   typeless right_ma=0;
   typeless space_between_ma=0;
   typeless print_flags=0;
   typeless linenums_every=0;
   parse gvsPrintOptions.print_options with left_ma','AfterHeader_ma','right_ma','BeforeFooter_ma','space_between_ma','print_flags','linenums_every','top_ma','bottom_ma;
   if (left_ma == "") left_ma = 0;
   if (AfterHeader_ma == "") AfterHeader_ma = 0;
   if (right_ma == "") right_ma = 0;
   if (BeforeFooter_ma == "") BeforeFooter_ma = 0;
   if (space_between_ma == "") space_between_ma = 0;
   if (print_flags == "") print_flags = 0;
   if (linenums_every == "") linenums_every = 0;
   if (top_ma == "") top_ma = 0;
   if (bottom_ma == "") bottom_ma = 0;
   if (!isinteger(print_flags)) print_flags=PRINT_CENTER_HEADER|PRINT_CENTER_FOOTER;
   switch (print_flags & 3) {
   case PRINT_CENTER_HEADER:
      _cheader.p_text=gvsPrintOptions.print_header;
      break;
   case PRINT_RIGHT_HEADER:
      _rheader.p_text=gvsPrintOptions.print_header;
      break;
   default:
      _lheader.p_text=gvsPrintOptions.print_header;
      _cheader.p_text=gvsPrintOptions.print_cheader;
      _rheader.p_text=gvsPrintOptions.print_rheader;
   }
   switch ((print_flags>>2) & 3) {
   case PRINT_CENTER_HEADER:
      _cfooter.p_text=gvsPrintOptions.print_footer;
      break;
   case PRINT_RIGHT_HEADER:
      _rfooter.p_text=gvsPrintOptions.print_footer;
      break;
   default:
      _lfooter.p_text=gvsPrintOptions.print_footer;
      _cfooter.p_text=gvsPrintOptions.print_cfooter;
      _rfooter.p_text=gvsPrintOptions.print_rfooter;
      break;
   }
   if (!isinteger(top_ma)) top_ma=0;
   if (!isinteger(bottom_ma)) bottom_ma=0;
   _two_up.p_value=print_flags&PRINT_TWO_UP;
   _linenums_every.p_text=linenums_every;
   ctlAfterHeader.p_text=AfterHeader_ma/1440;
   ctlBeforeFooter.p_text=BeforeFooter_ma/1440;
   _left_ma.p_text=left_ma/1440;_top_ma.p_text=top_ma/1440;
   _right_ma.p_text=right_ma/1440;_bottom_ma.p_text=bottom_ma/1440;
   _space_between_ma.p_text=space_between_ma/1440;
   _retrieve_prev_form();
   ctlmffiletypes._init_mffiletypes();
   if (nowins || !wid.select_active()) {
      _selection_only.p_enabled=0;
   } else {
      _selection_only.p_value=1;
   }
   if (!_selection_only.p_enabled) {
      _selection_only.p_value=0;
   }
   if (!Nofhidden) {
      ctlvisibleonly.p_enabled=0;
      ctlvisibleonly.p_value=0;
   } else {
      ctlvisibleonly.p_value=1;
   }
   if (!hex_mode) {
      //ctlhex.p_enabled=0;
      ctlhex.p_value=0;
   } else {
      ctlhex.p_value=1;
   }
   if (utf8) {
      ctlhex.p_enabled=0;
   }
   ctlhex.call_event(ctlhex,LBUTTON_UP);
   if (!_two_up.p_value) {
      _space_between_ma.p_enabled=0;
      _space_between_label.p_enabled=0;
   }
   if (isnumber(ctlAfterHeader.p_text)) ctlAfterHeader.p_text=ctlAfterHeader.p_text:+'"';
   if (isnumber(ctlBeforeFooter.p_text)) ctlBeforeFooter.p_text=ctlBeforeFooter.p_text:+'"';
   if (isnumber(_top_ma.p_text)) _top_ma.p_text=_top_ma.p_text:+'"';
   if (isnumber(_left_ma.p_text)) _left_ma.p_text=_left_ma.p_text:+'"';
   if (isnumber(_bottom_ma.p_text)) _bottom_ma.p_text=_bottom_ma.p_text:+'"';
   if (isnumber(_right_ma.p_text)) _right_ma.p_text=_right_ma.p_text:+'"';
   if (isnumber(_space_between_ma.p_text)) _space_between_ma.p_text=_space_between_ma.p_text:+'"';
   ctlCopies.p_text = 1; // default to 1 copy

   // Restore last active tab.
   _str lastActiveTab;
   lastActiveTab = _retrieve_value("_print_form.ActiveTab");
   if (lastActiveTab == "") {
      ctlTab.p_ActiveTab = 0;
   } else {
      ctlTab.p_ActiveTab = (int)lastActiveTab;
   }

   // Save the start up values to the default print scheme into the
   // hash. This guarantees that we always have the default scheme
   // that has the initial values.
   PrintScheme p:[];
   p._makeempty();
   //updateCurrentPrintScheme(p, DEFAULTPRINTSCHEME);
   //p:[DEFAULTPRINTSCHEME].user = 0;
   ctlSchemeSave.p_user = p;

   // Load the print schemes.
   gIgnoreSchemeModify = 0;
   gIgnoreSchemeListOnChange=0;
   initPrintSchemes();
   wid=_form_parent();
   if (wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP) &&
       wid.p_lexer_name=='') {
      ctlColorCoding.p_enabled=_print_color.p_enabled=ctlBgColor.p_enabled=false;
      //ctlColorCoding.p_value=_print_color.p_value=0;
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _print_form_initial_alignment()
{
   // main form
   sizeBrowseButtonToTextBox(ctlmffiles.p_window_id, ctlfilesmenu.p_window_id);

   // header/footer tab
   sizeBrowseButtonToTextBox(_lheader.p_window_id, _lheader_btn.p_window_id);
   sizeBrowseButtonToTextBox(_cheader.p_window_id, _cheader_btn.p_window_id);
   sizeBrowseButtonToTextBox(_rheader.p_window_id, _rheader_btn.p_window_id);
   sizeBrowseButtonToTextBox(_lfooter.p_window_id, _lfooter_btn.p_window_id);
   sizeBrowseButtonToTextBox(_cfooter.p_window_id, _cfooter_btn.p_window_id);
   sizeBrowseButtonToTextBox(_rfooter.p_window_id, _rfooter_btn.p_window_id);
}

// Load all the print schemes into the specified hash table.
// Retn: 0 OK, !0 error loading scheme
static int loadPrintSchemesFromINI(_str inifile, PrintScheme (&p):[], int user)
{
   // Open the ini file.
   int temp_view_id, orig_view_id;
   if (_open_temp_view(inifile,temp_view_id,orig_view_id)) {
      _message_box(nls("Unable to open print scheme file, ",inifile));
      return(1);
   }

   // Loop thru the entire ini file and get all sections.
   _str line, schemeName;
   top(); up();
   while (1) {
      // Find the start of a section. [schemeName]
      if (down()) break;
      get_line(line);
      if (pos(';', line) == 1) continue; // skip over comment line
      if (pos('[', line) != 1) continue;
      parse line with '[' schemeName ']';
      if (schemeName == "") break;

      // Get the values in the section.
      //say("loadPrintSchemes inifile="inifile" schemeName="schemeName);
      _str varname, val;
      while (1) {
         if (down()) break;
         get_line(line);
         if (pos('[', line) == 1) {
            up();
            break;
         }
         if (pos(';', line) == 1) continue; // skip over comment line
         parse line with varname '=' val;
         if (varname == "") continue;
         varname = lowcase(varname);
         p:[schemeName].options:[varname] = val;
      }
      p:[schemeName].user = user; // flag a user-defined scheme
   }

   // Clean up the temp view.
   p_window_id = orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

// Get the current scheme values and update the scheme in the hash.
static void updateCurrentPrintScheme(PrintScheme (&p):[], _str schemeName)
{
   // For a new scheme, set the user flag.
   //say("updateCurrentPrintScheme "schemeName);
   if (lowcase(schemeName) != DEFAULTPRINTSCHEME && !p._indexin(schemeName)) {
      p:[schemeName].user = 1;
   }

   // General tab.
   pValueToHash("ctlColorCoding", "printcolorcoding", p, schemeName);
   pValueToHash("_print_color", "printcolor", p, schemeName);
   pValueToHash("ctlBgColor", "printbgcolor", p, schemeName);
   pValueToHash("_two_up", "twoup", p, schemeName);
   pTextToHash("_space_between_ma", "spacebetween", p, schemeName);
   pTextToHash("_linenums_every", "numberlinesevery", p, schemeName);
   pValueToHash("ctlportrait", "portrait", p, schemeName);
   pValueToHash("ctllandscape", "landscape", p, schemeName);
   pTextToHash("_fonttext", "fonttext", p, schemeName);

   // Header/Footer tab.
   pTextToHash("_lheader", "leftheader", p, schemeName);
   pTextToHash("_cheader", "centerheader", p, schemeName);
   pTextToHash("_rheader", "rightheader", p, schemeName);
   pTextToHash("_lfooter", "leftfooter", p, schemeName);
   pTextToHash("_cfooter", "centerfooter", p, schemeName);
   pTextToHash("_rfooter", "rightfooter", p, schemeName);

   // Margins tab.
   pTextToHash("ctlAfterHeader", "afterheader", p, schemeName);
   pTextToHash("ctlBeforeFooter", "beforefooter", p, schemeName);
   pTextToHash("_top_ma", "topmargin", p, schemeName);
   pTextToHash("_left_ma", "leftmargin", p, schemeName);
   pTextToHash("_bottom_ma", "bottommargin", p, schemeName);
   pTextToHash("_right_ma", "rightmargin", p, schemeName);
}

// Write the print schemes to the user ini file.
// Retn: 0 OK, !0 file write error
static int writePrintScheme(PrintScheme (&p):[], _str inifile)
{
   // Open the ini file.
   //say("writePrintScheme inifile="inifile" schemeName="schemeName);
   int temp_view_id, orig_view_id;
   orig_view_id = _create_temp_view(temp_view_id);
   p_buf_name = inifile;

   // Clear the entire buffer.
   delete_all();

   // Write out all user-modified schemes.
   typeless i;
   for (i._makeempty();;) {
      p._nextel(i);
      if (i._isempty()) break;
      if (!p:[i].user) continue;

      // Write user scheme.
      //say("writePrintScheme Writing "i);
      insert_line("["i"]");
      typeless jj;
      for (jj._makeempty();;) {
         p:[i].options._nextel(jj);
         if (jj._isempty()) break;
         insert_line(jj"="p:[i].options:[jj]);
      }
   }

   // Save the file.
   int status = _save_config_file();
   if (status) {
      _message_box(nls("Can't write print scheme ini file, ",inifile):+"\n\n":+get_message(status));
   }

   // Clean up the temp view.
   p_window_id = orig_view_id;
   _delete_temp_view(temp_view_id);

   // Flag current scheme unmodified.
   ctlSchemeDelete.p_user = 0;
   return(status);
}

// Determine the print scheme ini file.
// If the user ini file exists, use it. Otherwise use the
// global ini file.
static _str printSchemeINIFile()
{
   // Find the .ini file.
   // Try the user's ini first. If it does not exist, try the global
   // default ini file.
   _str inifile =usercfg_path_search(VSCFGFILE_USER_PRINTSCHEMES);
   if (inifile=='') {
      inifile = get_env('VSROOT'):+PRINTSCHEME_INI_FILENAME;
   }

   /*
   // Must have a scheme ini file.
   if (inifile == "") {
      _message_box(nls("Can't find print scheme file."));
      return("");
   }
   */
   return(inifile);
}

static void hashToPValue(_str ctl, _str valKey, PrintScheme (&p):[], _str schemeName)
{
   int wid = _find_control(ctl);
   if (!wid) return;
   if (p:[schemeName].options._indexin(valKey)) {
      wid.p_value = (int)p:[schemeName].options:[valKey];
   }
}

static void pValueToHash(_str ctl, _str valKey, PrintScheme (&p):[], _str schemeName)
{
   int wid = _find_control(ctl);
   if (!wid) return;
   p:[schemeName].options:[valKey] = wid.p_value;
}

static void hashToPText(_str ctl, _str valKey, PrintScheme (&p):[], _str schemeName)
{
   int wid = _find_control(ctl);
   if (!wid) return;
   if (p:[schemeName].options._indexin(valKey)) {
      wid.p_text = p:[schemeName].options:[valKey];
   }
}

static void pTextToHash(_str ctl, _str valKey, PrintScheme (&p):[], _str schemeName)
{
   int wid = _find_control(ctl);
   if (!wid) return;
   p:[schemeName].options:[valKey] = wid.p_text;
}

// Given a scheme name, find it in the scheme list and restore the
// the dialog values.
static void fillSchemeDialog(PrintScheme (&p):[], _str schemeName)
{
   // If scheme does not exist, do nothing to the current values.
   if (!p._indexin(schemeName)) return;

   // General tab.
   gIgnoreSchemeModify = 1;
   hashToPValue("ctlColorCoding", "printcolorcoding", p, schemeName);
   hashToPValue("_print_color", "printcolor", p, schemeName);
   hashToPValue("ctlBgColor", "printbgcolor", p, schemeName);
   hashToPValue("_two_up", "twoup", p, schemeName);
   _two_up.call_event(_two_up,LBUTTON_UP);
   hashToPText("_space_between_ma", "spacebetween", p, schemeName);
   hashToPText("_linenums_every", "numberlinesevery", p, schemeName);
   hashToPValue("ctlportrait", "portrait", p, schemeName);
   hashToPValue("ctllandscape", "landscape", p, schemeName);
   hashToPText("_fonttext", "fonttext", p, schemeName);

   // Header/Footer tab.
   hashToPText("_lheader", "leftheader", p, schemeName);
   hashToPText("_cheader", "centerheader", p, schemeName);
   hashToPText("_rheader", "rightheader", p, schemeName);
   hashToPText("_lfooter", "leftfooter", p, schemeName);
   hashToPText("_cfooter", "centerfooter", p, schemeName);
   hashToPText("_rfooter", "rightfooter", p, schemeName);

   // Margins tab.
   hashToPText("ctlAfterHeader", "afterheader", p, schemeName);
   hashToPText("ctlBeforeFooter", "beforefooter", p, schemeName);
   hashToPText("_top_ma", "topmargin", p, schemeName);
   hashToPText("_left_ma", "leftmargin", p, schemeName);
   hashToPText("_bottom_ma", "bottommargin", p, schemeName);
   hashToPText("_right_ma", "rightmargin", p, schemeName);
   gIgnoreSchemeModify = 0;
}

// Load the print schemes from ini files. Print schemes support
// two ini files:  print.ini and uprint.ini
//
// print.ini contains the global print schemes, defined by SlickEdit
// and shipped with the product. uprint.ini contains the subsequent
// user-defined schemes. Neither files are needed to be present for
// this module to build and run correctly.
//
// The default scheme ("none") always holds the startup print
// parameters from gvsPrintOptions.print_options. Unless a known
// scheme was last selected, dialog retrieval kicks in and restore
// previous dialog values.
//
// Retn: 0 OK, !0 error initializing scheme
static int initPrintSchemes()
{
   // Init print schemes.
   PrintScheme p:[];
   p = ctlSchemeSave.p_user; // access hash
   ctlSchemeDelete.p_user = 0; // current scheme unmodified

   // Locate the print scheme ini file.
   _str ginifile= slick_path_search(PRINTSCHEME_INI_FILENAME);
   _str uinifile= usercfg_path_search(VSCFGFILE_USER_PRINTSCHEMES);

   // Load the schemes.
   // The scheme names are hashed into a table. The values of each
   // scheme are hashed by its keyname into another hash table
   // inside each scheme struct.
   //
   // Load the global ini file first and then load the user ini file.
   int status1 = 1;
   if (ginifile != "") {
      loadPrintSchemesFromINI(ginifile, p, 0);
   }
   int status2 = 1;
   if (uinifile != "") {
      loadPrintSchemesFromINI(uinifile, p, 1);
   }
   ctlSchemeSave.p_user = p;

   // Fill the scheme name list.
   fillSchemeNameList(p);

   // Select the last scheme.
   _str lastScheme;
   lastScheme = _retrieve_value("_print_form.lastScheme");
   parse lastScheme with lastScheme ' (Modified)';
   if (lastScheme == "" || strieq(lastScheme,DEFAULTPRINTSCHEME)) lastScheme = PREVIOUSVALUESPRINTSCHEME;
   setCurrentScheme(p, lastScheme);

   // Fill the dialog with specified scheme values.
   fillSchemeDialog(p, lastScheme);
   return(0);
}

// Add the schemes in the hash to the scheme combo list.
static void fillSchemeNameList(PrintScheme (&p):[])
{
   int listwid = ctlSchemeList.p_window_id;
   listwid._lbclear();
   typeless i;
   for (i._makeempty();;) {
      p._nextel(i);
      if (i._isempty()) break;
      if (lowcase(i) == DEFAULTPRINTSCHEME) continue;
      listwid._lbadd_item(i);
   }
   listwid._lbsort("AI");
}

static void setCurrentSchemeName(_str schemeName)
{
   ctlSchemeList.p_ReadOnly = false;
   ctlSchemeList.p_text = schemeName;
   ctlSchemeList._set_sel(1,length(schemeName)+1);
   ctlSchemeList.p_ReadOnly = true;
}

// Select the specified scheme name in the scheme list and
// also fill in the dialog values associated with the selected
// scheme.
static void setCurrentScheme(PrintScheme (&p):[], _str schemeName)
{
   // Search the scheme list for matching name.
   int listwid = ctlSchemeList.p_window_id;
   listwid.top();
   listwid.up();
   int found = 0;
   while (!listwid.down()) {
      _str line = listwid._lbget_text();
      if (schemeName == line) {
         listwid._lbselect_line();
         setCurrentSchemeName(schemeName);
         found = 1;
         break;
      }
   }
   if (!found) {
      ctlSchemeDelete.p_enabled=false;
      // If specified scheme name is not found in list, user
      // the default scheme name.
      schemeName=PREVIOUSVALUESPRINTSCHEME;
      setCurrentSchemeName(schemeName);
   } else {
      ctlSchemeDelete.p_enabled=true;
   }
}

static _str get_pfile_list(_str files, _str atbuflist)
/* returns view id of buffer/file list */
{
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_window_id=temp_view_id;
   _str ch="";
   _str word="";
   _str option="";
   _str tree_option='';
   for (;;) {
      word=parse_file(files);
      if (word=="") break;
      ch=substr(word,1,1);
      if (ch=='-' || ch=='+') {
         option=upcase(substr(word,2));
         switch (option) {
         case 'T':
            if (ch=='-') {
               tree_option='';
            } else {
               tree_option='+t';
            }
            break;
         default:
            p_window_id=orig_view_id;
            _delete_temp_view(temp_view_id);
            _message_box('Invalid switch');
            return('');
         }
      } else {
         insert_file_list(word' +p -v 'tree_option);
      }
   }

   for (;;) {
      _str cur_buf=parse_file(atbuflist);
      if (cur_buf=='') {
         break;
      }
      if (substr(cur_buf,1,1)=='@') {
         int temp_buflist_view_id=0;
         _open_temp_view(substr(cur_buf,2),temp_buflist_view_id, temp_view_id);
         p_window_id=temp_buflist_view_id;
         typeless mark_id=_alloc_selection();
         top();_select_line(mark_id);
         bottom();
         //messageNwait('p_Noflines='p_Noflines);
         _select_line(mark_id);
         p_window_id=temp_view_id;
         _copy_to_cursor(mark_id);
         _delete_temp_view(temp_buflist_view_id);
      }else{
         insert_line(strip(cur_buf,'B','"'));
         //insert_file_list(cur_buf' +p -v');
      }
   }
   if (p_Noflines) {
      sort_buffer('-f');
      _remove_duplicates();
   }else{
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      return('');
   }
   p_window_id=orig_view_id;
   return(temp_view_id);
}

void _ok.lbutton_up(boolean doClose=true)
{
   if (!isinteger(ctlCopies.p_text) || ctlCopies.p_text<=0) {
      ctlCopies._text_box_error('Invalid number of copies specified');
      return;
   }
   int temp_view_id=0;
   int orig_view_id=p_window_id;
   typeless print_flags=0;
   int wid=_form_parent();
   //include_pfiles=(_mfproject_files.p_value)&&(pos('<<',_mfmore.p_caption));
   //include_wkspace_files=(_mfworkspace_files.p_value)&&(pos('<<',_mfmore.p_caption));
   if(!isinteger(_linenums_every.p_text)){
      _message_box('Invalid integer');
      _linenums_every._set_sel(1,length(_linenums_every.p_text)+1);
      p_window_id=_linenums_every;_set_focus();
      return;
   }
   if (machine()!='WINDOWS') {
      ctlorientation.p_visible=0;
   }

   _str files="";
   _str wildcards="";
   typeless status=0;
   typeless list_view_id='';
   _param9='';
   int fid=p_active_form;
   if (pos('<<',_mfmore.p_caption)) {
      status=_mfget_result(files,wildcards);
      //Third parameter is to include project files
      if (status) {
         return;
      }
      if (!wid.p_HasBuffer || (wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
         if (files=='') {
            //If there really are no files selected, mffind can
            //return 0 and we wind up here.  I didn't want to mess with
            //mffind to much, so we just wind up here.
            _message_box(nls("No files selected"));
            p_window_id=_control ctlmffiles;_set_focus();
            _set_sel(1,length(p_text)+1);
            return;
         }
      }
      status=_mfinit(temp_view_id,files,wildcards);
      _param9= temp_view_id;  //get_pfile_list(files, atbuflist);
      if (status) {
         //_message_box(nls("There are no files in the current project."));
         return;
      }
   } else if (!wid.p_HasBuffer || (wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
      _message_box(nls("No files selected"));
      _mfmore.call_event(_mfmore,LBUTTON_UP);
      return;
   }
   p_window_id=fid;
   typeless AfterHeader_ma=0;
   typeless BeforeFooter_ma=0;
   typeless top_ma=0;
   typeless left_ma=0;
   typeless bottom_ma=0;
   typeless right_ma=0;
   typeless space_between_ma=0;
   if(_check_inch(_control ctlAfterHeader,AfterHeader_ma)) return;
   if(_check_inch(_control ctlBeforeFooter,BeforeFooter_ma)) return;
   if(_check_inch(_control _top_ma,top_ma)) return;
   if(_check_inch(_control _left_ma,left_ma)) return;
   if(_check_inch(_control _bottom_ma,bottom_ma)) return;
   if(_check_inch(_control _right_ma,right_ma)) return;
   if(_check_inch(_control _space_between_ma,space_between_ma)) return;

   if (_print_color.p_value && _print_color.p_enabled) print_flags|=PRINT_COLOR;
   if (ctlColorCoding.p_value && ctlColorCoding.p_enabled) print_flags|=PRINT_FONTATTRS;
   if (ctlBgColor.p_value && ctlBgColor.p_enabled) print_flags|=PRINT_BACKGROUND;
   if (_two_up.p_value) print_flags|=PRINT_TWO_UP;
   if (ctlvisibleonly.p_value && ctlvisibleonly.p_enabled) print_flags|=PRINT_VISIBLEONLY;
   if (ctlhex.p_value && ctlhex.p_enabled) {
      print_flags|=PRINT_HEX;
   }

   _str rest="";
   _param1= _fonttext.p_text;
   _param2= _lheader.p_text;
   _param3= _lfooter.p_text;
   parse gvsPrintOptions.print_options with ','.','.','.','.','.','.','.','.','rest ;
   _param4=left_ma','AfterHeader_ma','right_ma','BeforeFooter_ma','space_between_ma','print_flags','_linenums_every.p_text','top_ma','bottom_ma','rest;
   _param5= _cheader.p_text;
   _param6= _cfooter.p_text;
   _param7= _rheader.p_text;
   _param8= _rfooter.p_text;
   _param10 = ctlCopies.p_text;
   if (!isinteger(_param10)) _param10 = 1;
   if (_param10 < 1) _param10 = 1;

   gvsPrintOptions.print_font=_param1;
   gvsPrintOptions.print_header=_param2;
   gvsPrintOptions.print_footer=_param3;
   gvsPrintOptions.print_options=_param4;
   gvsPrintOptions.print_cheader=_param5;
   gvsPrintOptions.print_cfooter=_param6;
   gvsPrintOptions.print_rheader=_param7;
   gvsPrintOptions.print_rfooter=_param8;

   _str schemeName = ctlSchemeList.p_text;
   // Check if there is a current scheme that is modified
   if(pos('(Modified)',schemeName,1,'i')) {
      // Save the scheme
      parse schemeName with schemeName ' (Modified)';
      ctlSchemeSave.call_event(PREVIOUSVALUESPRINTSCHEME,ctlSchemeSave,lbutton_up,'W');
   }
   _ok.p_user='';
   _save_form_response();
   // Set print options
   if (gqtprint_options._isempty()) {
      gqtprint_options.m_deviceName='';
      gqtprint_options.m_collate=false;
      gqtprint_options.m_haveSelection=_selection_only.p_enabled?true:false;
   }
   gqtprint_options.m_landscape=ctllandscape.p_value?true:false;
   gqtprint_options.m_selection=_selection_only.p_value?true:false;
   if (isinteger(ctlCopies.p_text) && ctlCopies.p_text>0) {
      gqtprint_options.m_copyCount=(int)ctlCopies.p_text;
   } else {
      gqtprint_options.m_copyCount=1;
   }
   _QtPrintDialog(gqtprint_options,false /* don't show dialog */);

   //promptForSaveOnClose();
   rememberLastScheme();
   if (doClose) {
      p_active_form._delete_window((_selection_only.p_value && _selection_only.p_enabled)?2:1);
   }
}
static void rememberLastScheme()
{
   _str schemeName = ctlSchemeList.p_text;
   parse schemeName with schemeName ' (Modified)';
   _append_retrieve(0, schemeName, "_print_form.lastScheme");
   _append_retrieve(0, ctlTab.p_ActiveTab, "_print_form.ActiveTab");
}
_ok.on_destroy()
{
   // IF save settings button pressed and user did not press OK button
   if (_ok.p_user!='') {
      _save_form_response();
   }
}
_font.lbutton_up()
{
   typeless result=0;
   result=show('-modal _font_form','fp',_fonttext.p_text);
   if (result!='') {
      _fonttext.p_text=result;
   }
}


definit()
{
   gqtprint_options._makeempty();
}
#if 0
// Saving and restore printer settings too slow
_str _srg_printer2(_str option='',_str info='')
{
   typeless Noflines=0;

   if (option=='N' || option=='R') {
      // IF we are not restoring from an editor invocation.
      // Only restore project if user has selected to restore current directory
      parse info with Noflines;
      if (!arg(3)) {
         down(Noflines);
         return(0);
      }
      down();
      get_line(gqtprint_options.m_deviceName);
      down();
      _str qtprint_options_other;
      get_line(qtprint_options_other);
      _str a2,a3,a4,a5,a6;
      parse qtprint_options_other with a2 a3 a4 a5 a6;
      gqtprint_options.m_landscape=a2!=0;
      gqtprint_options.m_selection=a3!=0;
      gqtprint_options.m_haveSelection=a4!=0;
      gqtprint_options.m_copyCount=(int)a5;
      gqtprint_options.m_collate=a6!=0;


      if (Noflines>2) {
         down();get_line(gvsPrintOptions.print_font);
         down();get_line(gvsPrintOptions.print_header);
         down();get_line(gvsPrintOptions.print_footer);
         down();get_line(gvsPrintOptions.print_options);
         down();get_line(gvsPrintOptions.print_cheader);
         down();get_line(gvsPrintOptions.print_cfooter);
         down();get_line(gvsPrintOptions.print_rheader);
         down();get_line(gvsPrintOptions.print_rfooter);
      }
      _QtPrintDialogRestore(gqtprint_options);
      //gqtprint_options.m_deviceName="";
   } else {
      insert_line('PRINTER2: 10');
      insert_line(gqtprint_options.m_deviceName);
      insert_line(
         gqtprint_options.m_landscape' ':+
         gqtprint_options.m_selection' ':+
         gqtprint_options.m_haveSelection' ':+
         gqtprint_options.m_copyCount' ':+
         gqtprint_options.m_collate
                  );
      insert_line(gvsPrintOptions.print_font);
      insert_line(gvsPrintOptions.print_header);
      insert_line(gvsPrintOptions.print_footer);
      insert_line(gvsPrintOptions.print_options);
      insert_line(gvsPrintOptions.print_cheader);
      insert_line(gvsPrintOptions.print_cfooter);
      insert_line(gvsPrintOptions.print_rheader);
      insert_line(gvsPrintOptions.print_rfooter);
   }
   return(0);
}
#endif
#if 0
void _setup.lbutton_up()
{
   typeless status=0;
   _str landscape="";
   _str rest="";
   _str printer="";
   _str port="";

   if (machine()=='WINDOWS') { //we're on a windows machine
      //parse gprinter_setup with devname"," ;
      if (ctllandscape.p_value) {
         _printer_setup(',2,,','r'); //turn on landscape
      } else {
         _printer_setup(',1,,','r'); //turn off landscape
      }
      status=_printer_setup('','s',gprinter_setup);
      if (status) {
         _message_box(nls('Failed to setup printer.')'  'get_message(status));
         return;
      }
      //_printer_setup('','R',setup);
      //parse setup with ','landscape',';
      parse gprinter_setup with ','landscape',';
      if (landscape==2 && !ctllandscape.p_value) {
         ctllandscape.p_value=1;
      } else if(landscape!=2 && !ctlportrait.p_value) {
         ctlportrait.p_value=1;
      }
      parse gprinter_setup with "," +0 rest ;
      _printer_setup(rest,'R',gprinter_setup);
      parse gprinter_setup with printer",";
      _printer_setup('','P',port);
      ctlprinter.p_caption=printer" on "port;
      return;
   }
   status=_printer_setup('','s',gprinter_setup);
   if (status) {
      _message_box(nls('Failed to setup printer.')'  'get_message(status));
   }
}
#endif
_two_up.lbutton_up()
{
   _space_between_ma.p_enabled=
   _space_between_label.p_enabled=_two_up.p_value!=0;

   //turn on landscape mode
   //if (def_auto_landscape) {
   if (_two_up.p_value) {
      ctllandscape.p_value=1;
   } else {
      ctlportrait.p_value=1;
   }
   //}
   schemeModified();
}
static _check_inch(int wid,var twips)
{
   typeless number="";
   _str text=wid.p_text;
   _str rest="";
   parse text with number '"','i' rest;
   typeless x,y;
   parse number with x '.' y;
   if (isnumber(number)) {
      number=number*1440;
      // Strip off decimal pointer if there is no exponent
      parse number with x '.' y;
      if (isinteger(y)) number=x;
   }
   if (rest!='' || !isnumber(number) || pos('e',number,1,'i')) {
      _message_box('Invalid margin setting');
      p_window_id=wid;
      wid._set_sel(1,length(text)+1);_set_focus();
      return(1);
   }
   twips=number;
   return(0);
}
/**
 * Runs the operating system Print Setup dialog box.
 * 
 * @see _printer_setup
 * 
 * @categories Buffer_Functions
 * 
 */ 
_command void printer_setup() name_info(','VSARG2_EDITORCTL)
{
   // Could display qt page setup dialog here
   _message_box('not currently supported');
}
static _str cancel_wid;
static void _print_callback(int reason)
{
   typeless PageNumber=0;
   typeless NofPages=0;
   _nocheck _control filelabel;
   switch(reason) {
   case PRINT_ONINIT:
      cancel_wid=show('_cancelprint_form');
      cancel_wid.filelabel.p_caption=arg(2);
      break;
   case PRINT_ONEXIT:
      cancel_wid._delete_window();
      break;
   case PRINT_ONPAGE:
      PageNumber=arg(2);
      NofPages=arg(3);
      //say("PageNumber="PageNumber" NofPages="NofPages);
      _nocheck _control ctlinfo;
      if (NofPages) {
         cancel_wid.ctlinfo.p_caption="Page "PageNumber" of "NofPages;
      } else {
         cancel_wid.ctlinfo.p_caption="Page "PageNumber;
      }
      cancel_wid.refresh('w');
      break;
   }
}
defeventtab _cancelprint_form;

#if !__UNIX__
/**
 * Show the print preview dialog.  Do this by showing the print dialog, sending
 * an event to the "preview" button, and the close button after that.
 * 
 * @return 0 if successful
 */
_command int print_preview() name_info(','VSARG2_EDITORCTL)
{
   if (machine()=='WINDOWS') {
      int wid=show('-hidden _print_form');
      if (wid=='') {
         return(COMMAND_CANCELLED_RC);
      }
      _nocheck _control ctlPreview;
      _nocheck _control ctlClose;
      wid.ctlPreview.call_event(wid.ctlPreview,LBUTTON_UP);
      wid.ctlClose.call_event(wid.ctlClose,LBUTTON_UP);
      return(0);
   }else{
      return(1);
   }
}
#endif 

ctl_cancel.lbutton_up()
{
   _print_cancel();
}
/**
 * <p>Non-UNIX platforms: Prints the current buffer or the selection.  The 
 * Print dialog box is displayed, which allows you to specify various print 
 * options.</p>
 * 
 * <p>UNIX: Prints the current buffer or the selection.  The Text Mode Print 
 * dialog box is displayed, which allows you to specify various print options.</p>
 * 
 * @return Returns 0 if successful.
 * 
 * @see print
 * 
 * @appliesTo Edit_Window
 *
 * @categories Miscellaneous_Functions
 * 
 */
_command gui_print() name_info(','VSARG2_EDITORCTL)
{
   _macro_delete_line();
   typeless result=show('-modal _print_form');
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   typeless status=0;
   boolean fileinmem=false;
   _str filename="";
   _str setup="";
   int orig_view_id=0;
   int filelist_view_id=0;
   int new_view=0;
   int junk_view_id=0;
   int copies=0;
   int numberOfCopies = _param10;

   SEQtPrintOptions qtprint_options;
   qtprint_options=gqtprint_options;
   qtprint_options.m_haveSelection=result!=1;
   qtprint_options.m_selection=qtprint_options.m_haveSelection;
   int print_status=_QtPrintDialog(qtprint_options,true /* show dialog */);
   if (print_status!=IDOK) {
      return(COMMAND_CANCELLED_RC);
   }
   if (!qtprint_options.m_selection) {
      result=1;
   }


   if (result==1) {
      if (_param9!='') {
         orig_view_id=p_window_id;
         filelist_view_id=_param9;
         p_window_id=filelist_view_id;
         if (!p_Noflines) {
            _message_box(nls("No matching files."));
            p_window_id=orig_view_id;
            _delete_temp_view(filelist_view_id);
            return('');
         }
         p_line=0;
         while (!down()) {
            get_line(filename);
            filename=strip(filename);

            p_window_id=VSWID_HIDDEN;
            status=_open_temp_view(filename,new_view,junk_view_id,'',fileinmem,false,true);
            //I decided to use load_files instead of edit to get around cases
            //where there were no child windows and edit brought them up.
            //This just feels cleaner to me.
            p_window_id=new_view;
            status=_print(filename,
                   '',//We don't know why this is here
                   //find_index('_print_callback',PROC_TYPE),    //callback_index
                   _print_callback,  //callback
                   _param1,         // Font
                   _insert_print_options(_param2,filename,""),         // header
                   _insert_print_options(_param3,filename,""),         // footer
                   _param4,         // margins, print flags, linenums_every
                   _insert_print_options(_param5,filename,""),
                   _insert_print_options(_param6,filename,""),
                   _insert_print_options(_param7,filename,""),
                   _insert_print_options(_param8,filename,"")
                   );
            _delete_temp_view(new_view);
            p_window_id=filelist_view_id;
            _macro('m',_macro('s'));
            _macro_call('print',_param1,_param2,_param3,_param4,_param5,_param6,_param7,_param8);
         }
         _delete_temp_view(filelist_view_id);
         p_window_id=orig_view_id;
      }else{
         status=_print(p_buf_name,'',
                //find_index('_print_callback',PROC_TYPE),    //callback_index
                _print_callback,  //callback
                _param1,         // Font
                _insert_print_options(_param2,p_buf_name,p_DocumentName),         // header
                _insert_print_options(_param3,p_buf_name,p_DocumentName),         // footer
                _param4,         // margins, print flags, linenums_every
                _insert_print_options(_param5,p_buf_name,p_DocumentName),         // cheader
                _insert_print_options(_param6,p_buf_name,p_DocumentName),         // cfooter
                _insert_print_options(_param7,p_buf_name,p_DocumentName),         // rheader
                _insert_print_options(_param8,p_buf_name,p_DocumentName)          // rfooter
                );
         _macro('m',_macro('s'));
         _macro_call('print',_param1,_param2,_param3,_param4,_param5,_param6,_param7,_param8);
      }
   } else {
      _str orig_def_keys=def_keys;
      def_keys='';
      for (copies=0; copies<numberOfCopies; copies++) {
         get_window_id(orig_view_id);
         status=print_selection(
                _param1,         // Font
                _param2,         // header
                _param3,         // footer
                _param4,         // margins, print flags, linenums_every
                _param5,         // cheader
                _param6,         // cfooter
                _param7,         // rheader
                _param8          // rfooter
                );
         activate_window(orig_view_id);
      }
      def_keys=orig_def_keys;
      if (def_keys=='brief-keys') deselect();
      _macro('m',_macro('s'));
      _macro_call('print_selection',_param1,_param2,_param3,_param4,_param5,_param6,_param7,_param8);
   }
   if (status) {
      _message_box("Error printing.  "get_message(status));
   }
   return(status);
}

/**
 * <p>Non-UNIX platforms: The print command prints the contents of the 
 * current buffer according to the options given. If a parameter 
 * is not specified, the default printer options set by the 
 * print dialog dialog box 
 * are used.</p>
 * 
 * <p>It is much easier to create input parameters to this function by using 
 * macro recording.  Use the <b>Print Setup dialog box</b> to set your 
 * options.  Then print a document while macro recording is on.</p>
 * 
 * <p>See <b>_print</b> function for information on input parameters.</p>
 * 
 * <p>UNIX: Under UNIX, this function calls the <b>tprint</b> command 
 * with no arguments.  All arguments are ignored.  The default printer 
 * options set by the <b>Text Mode Print dialog box</b> are used.</p>
 * 
 * @return Returns 0 if successful.
 * 
 * @see gui_print
 * 
 * @categories Buffer_Functions, Selection_Functions
 * 
 */ 
_command print(_str font='',_str lheader='',_str lfooter='',_str options='',_str cheader='',_str cfooter='',_str rheader='',_str rfooter='') name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   typeless status=0;
   _str buf_name = p_buf_name;
   _str doc_name = p_DocumentName;
   if( buf_name == "" ) {
      buf_name = doc_name;
   }

   useDefaults := (font == '' && lheader == '' && lfooter == '' &&
                   options == '' && cheader == '' && cfooter == '' &&
                   rheader == '' && rfooter == '');

   if (!useDefaults) {
      status=_print(buf_name,'',
             //find_index('_print_callback',PROC_TYPE),    //callback_index
             _print_callback,  //callback
             font,           //font
             _insert_print_options(lheader,buf_name,doc_name),
             _insert_print_options(lfooter,buf_name,doc_name),
             arg(4),
             _insert_print_options(cheader,buf_name,doc_name),
             _insert_print_options(cfooter,buf_name,doc_name),
             _insert_print_options(rheader,buf_name,doc_name),
             _insert_print_options(rfooter,buf_name,doc_name)
             );
   } else {
      status=_print(buf_name,'',
             //find_index('_print_callback',PROC_TYPE),    //callback_index
             _print_callback,  //callback
             gvsPrintOptions.print_font,   // font
             _insert_print_options(gvsPrintOptions.print_header,buf_name,doc_name),         // header
             _insert_print_options(gvsPrintOptions.print_footer,buf_name,doc_name),         // footer
             gvsPrintOptions.print_options,
             _insert_print_options(gvsPrintOptions.print_cheader,buf_name,doc_name),
             _insert_print_options(gvsPrintOptions.print_cfooter,buf_name,doc_name),
             _insert_print_options(gvsPrintOptions.print_rheader,buf_name,doc_name),
             _insert_print_options(gvsPrintOptions.print_rfooter,buf_name,doc_name)
             );
   }
   if (status && status!=COMMAND_CANCELLED_RC) {
      _message_box(nls('Printing Failed')'.  'get_message(status));
   }
   return(status);
}

void _copy_to_cursor_binary(_str markid='')
{
   int start_col=0, end_col=0;
   int buf_id=0;
   typeless status=_get_selinfo(start_col,end_col,buf_id,markid);
   if (status) {
      return;
   }
   typeless markid2=0;
   if (markid=='') {
      markid2=_duplicate_selection();
   } else {
      markid2=_duplicate_selection(markid);
   }
   _select_type(markid2,'S','E');
   int temp_view_id=0;
   int orig_view_id=0;
   typeless end_offset=0;
   typeless begin_offset=0;
   _open_temp_view('',temp_view_id,orig_view_id,"+bi "buf_id);
   if (_select_type()=='LINE') {
      _end_select(markid2);p_col=_text_colc(_line_length(true)+1,'I');
      end_offset=_nrseek()+_select_type(markid2,'I');
      _begin_select(markid2);p_col=1;
      begin_offset=_nrseek();
   } else {
      _end_select(markid2);
      end_offset=_nrseek()+_select_type(markid2,'I');
      _begin_select(markid2);
      begin_offset=_nrseek();
   }
   _str text="";
   _free_selection(markid2);
   for (;begin_offset<end_offset;) {
      int len=5000;
      if (begin_offset+len>end_offset) {
         len=end_offset-begin_offset;
      }
      activate_window(temp_view_id);
      text=get_text(len,begin_offset);
      activate_window(orig_view_id);
      _insert_text(text,1,"\n");
      begin_offset+=len;
      //messageNwait('b='begin_offset' e='end_offset);
   }
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
}
_command print_selection(...) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_MARK)
{
   typeless print_font="";
   typeless print_header="";
   typeless print_footer="";
   typeless print_options="";
   typeless print_cheader="";
   typeless print_cfooter="";
   typeless print_rheader="";
   typeless print_rfooter="";

   if (arg()>1) {
      print_font=arg(1);
      print_header=arg(2);
      print_footer=arg(3);
      print_options=arg(4);
      print_cheader=arg(5);
      print_cfooter=arg(6);
      print_rheader=arg(7);
      print_rfooter=arg(8);
   } else {
      print_font=gvsPrintOptions.print_font;
      print_header=gvsPrintOptions.print_header;
      print_footer=gvsPrintOptions.print_footer;
      print_options=gvsPrintOptions.print_options;
      print_cheader=gvsPrintOptions.print_cheader;
      print_cfooter=gvsPrintOptions.print_cfooter;
      print_rheader=gvsPrintOptions.print_rheader;
      print_rfooter=gvsPrintOptions.print_rfooter;
   }

   typeless AfterHeader_ma=0;
   typeless BeforeFooter_ma=0;
   typeless top_ma=0;
   typeless left_ma=0;
   typeless bottom_ma=0;
   typeless right_ma=0;
   typeless space_between_ma=0;
   typeless print_flags=0;
   typeless linenums_every=0;
   parse print_options with left_ma','AfterHeader_ma','right_ma','BeforeFooter_ma','space_between_ma','print_flags','linenums_every','top_ma','bottom_ma;
   if ( !select_active2() ) {
      _message_box(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   typeless mark= _duplicate_selection();    /* Save the users mark. */
   if ( mark<0  ) return(mark);
   typeless junk;
   int buf_id=0;
   int encoding=0;
   typeless status=_get_selinfo(junk,junk,buf_id,'',junk,junk,encoding);
   if ( status ) {
      _free_selection(mark);
      return(status);
   }
   // Save old buffer cursor position so mark does not move.
   _next_buffer('h');_prev_buffer('h');

   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if (orig_view_id=="") {
      _free_selection(mark);
      return(status);
   }
   p_encoding=encoding;
   int old_buf_id=p_buf_id;
   p_buf_id=buf_id;
   int hex_mode=p_hex_mode;
   typeless RealLineNumber=0;
   _str lang=p_LangId;
   save_pos(auto p);_begin_select();
   if (print_flags & PRINT_HEX) {
      if (_select_type()=='LINE') {
         _begin_line();
      }
      RealLineNumber=_QROffset();
      //messageNwait('RealLineNumber='RealLineNumber);
   } else {
      RealLineNumber=p_RLine;
   }
   restore_pos(p);
   _str tabs=p_tabs;
   int buf_width=p_buf_width;
   _str buf_name=p_buf_name;
   _str doc_name = p_DocumentName;
   if( buf_name == "" ) {
      buf_name = doc_name;
   }

   p_buf_id=old_buf_id;
   _SetEditorLanguage(lang);
   p_buf_name=buf_name;
   p_tabs=tabs;
   if (_select_type()!='LINE') {
      insert_line("");
      _delete_text(-2);
   }
   if (_select_type()=='BLOCK' || !hex_mode) {
      _copy_to_cursor(mark,VSMARKFLAG_COPYNOSAVELF);
   } else {
      _copy_to_cursor_binary(mark);
   }
   _free_selection(mark);
   typeless pageleft_ma=0;
   typeless pageright_ma=0;
   parse print_options with left_ma','AfterHeader_ma','right_ma','BeforeFooter_ma','space_between_ma','print_flags','linenums_every','top_ma','bottom_ma','pageleft_ma','pageright_ma',';
   print_options=left_ma','AfterHeader_ma','right_ma','BeforeFooter_ma','space_between_ma','print_flags','linenums_every','top_ma','bottom_ma','pageleft_ma','pageright_ma','RealLineNumber;
   p_show_tabs=0;
   status=0;
   status=_print(buf_name,'',
          //find_index('_print_callback',PROC_TYPE),    //callback_index
          _print_callback,  //callback
          print_font,
          _insert_print_options(print_header,buf_name,doc_name),
          _insert_print_options(print_footer,buf_name,doc_name),
          print_options,
          _insert_print_options(print_cheader,buf_name,doc_name),
          _insert_print_options(print_cfooter,buf_name,doc_name),
          _insert_print_options(print_rheader,buf_name,doc_name),
          _insert_print_options(print_rfooter,buf_name,doc_name)
          );
   p_window_id = orig_view_id;
   _delete_temp_view(temp_view_id);
   if ( status<0 ) {
      _message_box(nls('Printing Failed')'.  'get_message(status));
   } else {
      if (def_keys=='brief-keys') deselect();
   }
   return(status);
}
struct VSPRINTCONFIG {  // Used by _PrintSetConfig and _PrintGetConfig and C API
   _str szFontName;
   int FontSizeX10;
   int FontFlags;
   int FontCharSet;
   _str szLeftHeader;
   _str szLeftFooter;
   _str szCenterHeader;
   _str szCenterFooter;
   _str szRightHeader;
   _str szRightFooter;
   int twLeftMargin;
   int twRightMargin;
   int twTopMargin;
   int twBottomMargin;
   int twAfterHeader;
   int twBeforeFooter;
   int twSpaceBetween;
   int PrintFlags;
   int LinenumsEvery;
};
void _PrintSetConfig(VSPRINTCONFIG &result)
{
   //say('result.szCenterHeader='result.szCenterHeader);
   gvsPrintOptions.print_font=result.szFontName','(result.FontSizeX10 intdiv 10)','result.FontFlags','result.FontCharSet;

   switch (result.PrintFlags & 3) {
   case PRINT_CENTER_HEADER:
      gvsPrintOptions.print_header=result.szCenterHeader;
      break;
   case PRINT_RIGHT_HEADER:
      gvsPrintOptions.print_header=result.szRightHeader;
      break;
   default:
      gvsPrintOptions.print_header=result.szLeftHeader;
      gvsPrintOptions.print_cheader=result.szCenterHeader;
      gvsPrintOptions.print_rheader=result.szRightHeader;
   }
   switch ((result.PrintFlags>>2) & 3) {
   case PRINT_CENTER_HEADER:
      gvsPrintOptions.print_footer=result.szCenterFooter;
      break;
   case PRINT_RIGHT_HEADER:
      gvsPrintOptions.print_footer=result.szRightFooter;
      break;
   default:
      gvsPrintOptions.print_footer=result.szLeftFooter;
      gvsPrintOptions.print_cfooter=result.szCenterFooter;
      gvsPrintOptions.print_rfooter=result.szRightFooter;
      break;
   }

   gvsPrintOptions.print_options=
      result.twLeftMargin',':+
      result.twAfterHeader',':+
      result.twRightMargin',':+
      result.twBeforeFooter',':+
      result.twSpaceBetween',':+
      result.PrintFlags',':+
      result.LinenumsEvery',':+
      result.twTopMargin',':+
      result.twBottomMargin;

   _DialogClearRetrieval('_print_form');
}
void _PrintGetConfig(VSPRINTCONFIG &result)
{
   _str FontName="";
   typeless FontSize=0;
   typeless FontFlags=0;
   typeless CharSet=0;
   parse gvsPrintOptions.print_font with FontName','FontSize','FontFlags','CharSet;
   result.szFontName=FontName;
   result.FontSizeX10=FontSize*10;
   result.FontFlags=FontFlags;
   if (!isinteger(CharSet)) {
      CharSet=1;  // default_charset
   }
   result.FontCharSet=CharSet;

   typeless AfterHeader_ma=0;
   typeless BeforeFooter_ma=0;
   typeless top_ma=0;
   typeless left_ma=0;
   typeless bottom_ma=0;
   typeless right_ma=0;
   typeless space_between_ma=0;
   typeless print_flags=0;
   typeless linenums_every=0;
   parse gvsPrintOptions.print_options with left_ma','AfterHeader_ma','right_ma','BeforeFooter_ma','space_between_ma','print_flags','linenums_every','top_ma','bottom_ma;

   result.szLeftHeader='';
   result.szLeftFooter='';
   result.szCenterHeader='';
   result.szCenterFooter='';
   result.szRightHeader='';
   result.szRightFooter='';

   switch (print_flags & 3) {
   case PRINT_CENTER_HEADER:
      result.szCenterHeader=gvsPrintOptions.print_header;
      break;
   case PRINT_RIGHT_HEADER:
      result.szRightHeader=gvsPrintOptions.print_header;
      break;
   default:
      result.szLeftHeader=gvsPrintOptions.print_header;
      result.szCenterHeader=gvsPrintOptions.print_cheader;
      result.szRightHeader=gvsPrintOptions.print_rheader;
   }
   switch ((print_flags>>2) & 3) {
   case PRINT_CENTER_HEADER:
      result.szCenterFooter=gvsPrintOptions.print_footer;
      break;
   case PRINT_RIGHT_HEADER:
      result.szRightFooter=gvsPrintOptions.print_footer;
      break;
   default:
      result.szLeftFooter=gvsPrintOptions.print_footer;
      result.szCenterFooter=gvsPrintOptions.print_cfooter;
      result.szRightFooter=gvsPrintOptions.print_rfooter;
      break;
   }
   if (!isinteger(top_ma)) top_ma=0;
   if (!isinteger(bottom_ma)) bottom_ma=0;
   result.twLeftMargin=left_ma;
   result.twRightMargin=right_ma;
   result.twTopMargin=top_ma;
   result.twBottomMargin=bottom_ma;
   result.twAfterHeader=AfterHeader_ma;
   result.twBeforeFooter=BeforeFooter_ma;
   result.twSpaceBetween=space_between_ma;
   result.PrintFlags=print_flags;
   result.LinenumsEvery=linenums_every;
   //say('result.szCenterHeader='result.szCenterHeader);
}


