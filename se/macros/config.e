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
#include "search.sh"
#include "vsockapi.sh"
#import "clipbd.e"
#import "color.e"
#import "complete.e"
#import "eclipse.e"
#import "ex.e"
#import "fileman.e"
#import "guiopen.e"
#import "mouse.e"
#import "main.e"
#import "math.e"
#import "keybindings.e"
#import "options.e"
#import "optionsxml.e"
#import "pmatch.e"
#import "pushtag.e"
#import "recmacro.e"
#import "search.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "treeview.e"
#import "window.e"
#import "dlgman.e"
#import "varedit.e"
#import "listbox.e"
#endregion

/**
 * Draw box around current line options
 * @see _default_option
 */
_metadata enum VSCurrentLineBoxOptions {
   VSCURRENT_LINE_BOXFOCUS_NONE     = 0,    // no box
   VSCURRENT_LINE_BOXFOCUS_ONLY     = 1,    // only the box, no ruler
   VSCURRENT_LINE_BOXFOCUS_TABS     = 2,    // tabs ruler
   VSCURRENT_LINE_BOXFOCUS_INDENT   = 3,    // syntax indent ruler
   VSCURRENT_LINE_BOXFOCUS_DECIMAL  = 4,    // decimal ruler
   VSCURRENT_LINE_BOXFOCUS_COBOL    = 5,    // cobol ruler
};

static const FIRSTSPECIALCHAR=   6;
static const LASTSPECIALCHAR=    11;

struct CtrlChar {
   _str character;
   _str name;
};

static _str spec_char_names_table[]={
   "Not Used",
   "Not Used",
   "Not Used",
   "Not Used",
   "Not Used",
   "End-Of-File",
   "Formfeed",
   "Other Control Characters",
   "End-Of-Line",
   "Carriage Return",
   "Line Feed",
};

static CtrlChar other_ctrl_chars_table[]={
   {"^@", "NUL"},
   {"^A", "SOH"},
   {"^B", "STX"},
   {"^C", "ETX"},
   {"^D", "EOT"},
   {"^E", "ENQ"},
   {"^F", "ACK"},
   {"^G", "BEL"},
   {"^H", "BS"},
   {"^I", "HT"},
   {"^J", "LF"},
   {"^K", "VT"},
   {"^L", "FF"},
   {"^M", "CR"},
   {"^N", "SO"},
   {"^O", "SI"},
   {"^P", "SLE"},
   {"^Q", "DC1"},
   {"^R", "DC2"},
   {"^S", "DC3"},
   {"^T", "DC4"},
   {"^U", "NAK"},
   {"^V", "SYN"},
   {"^W", "ETB"},
   {"^X", "CAN"},
   {"^Y", "EM"},
   {"^Z", "SUB"},
   {"^[", "ESC"},
   {"^ ", "FS"},
   {"^]", "GS"},
   {"^^", "RS"},
   {"^_", "US"},
};


_str _cua_textbox(_str cua = '')
{
   // if default value is used, we return current value
   if (cua == '') {
      cua = (int)(def_cua_textbox != 0);
   } else {
      def_cua_textbox = cua;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _macro_append("def_cua_textbox="def_cua_textbox";");

      cb_index := find_index('_ul2_combobx',EVENTTAB_TYPE);
      tb_index := find_index('_ul2_textbox',EVENTTAB_TYPE);
      if (cua) {
         tb2 := find_index('_ul2_textbox2',EVENTTAB_TYPE);
         if (cb_index) eventtab_inherit(cb_index,tb2);
         if (tb_index) eventtab_inherit(tb_index,tb2);
      } else {
         if (cb_index) eventtab_inherit(cb_index,0);
         if (tb_index) eventtab_inherit(tb_index,0);
         _cmdline.p_eventtab=0;
      }
   }

   return cua;
}

#if 0
/*List Configuration and Forms Button Section*/
defeventtab _listforms_form;
_ok.lbutton_up()
{
   // Return booleans separated by space  "<usersys> <user>"
   result=_modifiedsys_forms.p_value' '_userforms.p_value;
   p_active_form._delete_window(result);//_listforms_form
}

#endif

#region Options Dialog Helper Functions

defeventtab _emulation_form;

void _emulation_form_init_for_options()
{
   _ctlemu_ok.p_user = p_active_form;

   _ctlemu_ok.p_visible = false;
   _ctlcancel.p_visible = false;
   _ctlhelp.p_visible = false;

   // get the options purpose to determine whether to show our button
   form := getOptionsFormFromEmbeddedDialog();
   purpose := _GetDialogInfoHt(se.options.OptionsTree.PURPOSE, form);
   if (purpose == OP_QUICK_START) {
      _btn_restore.p_visible = false;

      heightDiff := _btn_restore.p_y - ctldescription.p_y;
      ctldescription.p_y += heightDiff;
      _ctl_customize_emulation_link.p_y += heightDiff;
      _ctl_customize_emulation_link.p_visible = true;
   }
}

bool _emulation_form_validate(int action)
{
   _str new_keys, emu;
   getKeysAndEmulation(new_keys, emu);

   if (def_keys != new_keys) {

      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(se.options.OptionsConfigTree.OPTIONS, getOptionsForm());

      // we gotta do crazy stuff now
      typeless result=0;
      if (optionsConfigTree -> areOptionsModified(false)) {
         result = _message_box("All other changes must be applied before changing emulation.  Do you wish to ":+
                               "apply other changes before applying emulation change?\n        Select Yes to ":+
                               "apply other changes, then apply emulation change.\n        Select No to cancel ":+
                               "other changes and then apply emulation change.","", MB_YESNOCANCEL);
         if (result == IDCANCEL) {
            setupEmulation();
            return false;
         } else if (result == IDNO) {
            wid := p_window_id;
            _emulation_form_apply();
            p_window_id = wid;

            // cancel all the other options
            optionsConfigTree -> cancel();
            p_window_id = wid;

         } else if (result == IDYES) {
            wid := p_window_id;
            // apply the other changes
            // give focus to options form
            p_window_id = getOptionsFormFromEmbeddedDialog();
            optionsConfigTree -> apply(true, false);
            p_window_id = wid;
            _emulation_form_apply();
            p_window_id = wid;
         }
      } else {
         // just apply it without worrying about the other stuff
         _emulation_form_apply();
      }

      // reload options - we need to catch all the changes that
      // might have happened by changing the emulation
      optionsConfigTree -> reloadOptionsTree();
   }

   // return 0 - we can switch away from this panel
   return true;
}

void _emulation_form_restore_state()
{
   _btn_restore.p_enabled = false;

   // check to see if this emulation has any custom keybindings - if so, enable the RESTORE button
   firstInit := _GetDialogInfoHt("firstInit", p_active_form, true);
   if (!firstInit) {
      _str keys, emu;
      getKeysAndEmulation(keys, emu);
      if (hasSavedKeybindings(emu, keys)) {
         _btn_restore.p_enabled = true;
      }
   }

   // this is really only for quick start
   form := getOptionsFormFromEmbeddedDialog();
   purpose := _GetDialogInfoHt(se.options.OptionsTree.PURPOSE, form);
   if (purpose == OP_QUICK_START) {
      setupEmulation();
   }
}

void _emulation_form_apply()
{
   formWid := _ctlemu_ok.p_user;
   firstInit := _GetDialogInfoHt("firstInit", formWid, true);

   set_emulation := "";
   new_keys := "";
   export_keys := '1';
   import_keys := '1';
   getKeysAndEmulation(new_keys, set_emulation);

   if (def_keys == new_keys) {
      return;
   }

   // we always save the keybindings from the old emulation
   // AND restore the keybindings from the new one
   switchEmulation(set_emulation, 1, 1);
   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(se.options.OptionsConfigTree.OPTIONS, getOptionsForm());
   if (optionsConfigTree) {
      optionsConfigTree -> markEmulationNodeInOptionsHistory();
   }
}

bool _emulation_form_is_modified()
{
   return false;
}

#endregion Options Dialog Helper Functions

_ctlemu_ok.on_create(bool firstInit = false)
{  
   _update_profiles_for_modified_eventtabs();
   _ctl_customize_emulation_link.p_mouse_pointer = MP_HAND;
   _ctl_customize_emulation_link.p_visible = false;

   _ctlemu_ok.p_user = 0;
   _ctlemu_cua_windows.p_user=0;
   _ctlemu_cua_mac.p_user=0;
   _ctlemu_slickedit.p_user=0;
   _ctlemu_brief.p_user=0;
   _ctlemu_emacs.p_user=0;
   _ctlemu_vi.p_user=0;
   _ctlemu_gnu.p_user=0;
   _ctlemu_vcpp.p_user=0;
   _ctlemu_vsnet.p_user=0;
   _ctlemu_ispf.p_user=0;
   _ctlemu_codewarrior.p_user=0;
   _ctlemu_bbedit.p_user=0;
   _ctlemu_xcode.p_user=0;
   _ctlemu_eclipse.p_user=0;
   if (firstInit) _ctlcancel.p_enabled = false;
   _SetDialogInfoHt("firstInit", firstInit, p_active_form, true);

   setupEmulation();
   call_event(_ctlemu_cua_windows,LBUTTON_UP,'');
}

void _btn_restore.lbutton_up()
{
   keys := emulation := "";
   getKeysAndEmulation(keys, emulation);

   resetEmulationKeyBindings(keys);
   // if this is the current emulation, then we need to
   // reset the current keybindings
   if (keys == def_keys) {
      // reload the keybindings options
      se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(se.options.OptionsConfigTree.OPTIONS, getOptionsForm());
      if (optionsTree) optionsTree -> reloadOptionsNode('Key Bindings');
   }

   _btn_restore.p_enabled = false;
}

void _ctl_customize_emulation_link.lbutton_up()
{
   origWid := p_window_id;

   bool nextEnabled, prevEnabled;
   disableEnableNextPreviousOptionsButtons(true, nextEnabled, prevEnabled);

   optionsWid := config('Emulation', 'N');
   _modal_wait(optionsWid);

   p_window_id = origWid;

   disableEnableNextPreviousOptionsButtons(false, nextEnabled, prevEnabled);

   // we need to refresh this stuff in case they changed anything
   _emulation_form_restore_state();
}

static bool hasSavedKeybindings(_str emulation, _str keys)
{
   // if this is the current emulation, we can check for keybindings
   // that haven't been written yet
   return isEmulationCustomized(keys);
}

static void setupEmulation()
{
   switch (lowcase(def_keys)) {
   case '':
      _ctlemu_slickedit.p_value=1;
      break;
   case 'macosx-keys':
      _ctlemu_cua_mac.p_value=1;
      break;
   case 'windows-keys':
      _ctlemu_cua_windows.p_value=1;
      break;
   case 'brief-keys':
      _ctlemu_brief.p_value=1;
      break;
   case 'emacs-keys':
      _ctlemu_emacs.p_value=1;
      break;
   /* 4/18/94 HERE - add check for vi emulation */
   case 'vi-keys':
      _ctlemu_vi.p_value=1;
      break;
   /* add check for Gnu EMACS emulation */
   case 'gnuemacs-keys':
      _ctlemu_gnu.p_value=1;
      break;
   /* 2/9/1999 add check for Visual C++ emulation */
   case 'vcpp-keys':
      _ctlemu_vcpp.p_value=1;
      break;
   /* 10/26/2004 add check for Visual Studio .NET emulation */
   case 'vsnet-keys':
      _ctlemu_vsnet.p_value=1;
      break;
   /* 11-21-99 add check for ISPF emulation */
   case 'ispf-keys':
      _ctlemu_ispf.p_value=1;
      break;
   /* 08-10-2001 add check for CodeWarrior emulation */
   case 'codewarrior-keys':
      _ctlemu_codewarrior.p_value=1;
      break;
   case 'codewright-keys':
      _ctlemu_codewright.p_value=1;
      break;
   /* 08-12-2004 add check for BBEdit emulation */
   case 'bbedit-keys':
      _ctlemu_bbedit.p_value=1;
      break;
   /* 08-12-2004 add check for Xcode emulation */
   case 'xcode-keys':
      _ctlemu_xcode.p_value=1;
      break;
   case 'eclipse-keys':
      _ctlemu_eclipse.p_value=1;
   }
}

void switchEmulation(_str set_emulation, _str export_keys=1, _str import_keys=1)
{
   macro := "emulate";
   _str filename=_getSlickEditInstallPath()'macros':+FILESEP:+(macro:+_macro_ext'x');
   if (filename=='') {
      filename=_getSlickEditInstallPath()'macros':+FILESEP:+(macro:+_macro_ext);
   }
   if (filename=='') {
      _message_box("File '%s' not found",macro:+_macro_ext'x');
      return;
   }
   orig_wid := p_window_id;
   p_window_id=_mdi.p_child;
   _macro('m',0);
   macro=_maybe_quote_filename(macro);
   typeless status=shell(macro' 'set_emulation' 'export_keys' 'import_keys);
   _macro('m',_macro('s'));
   p_window_id=orig_wid;
   _macro_call('shell',macro' 'set_emulation);
   if (status) {
      _message_box(nls("Unable to set emulation.\n\nError probably caused by missing macro compiler or incorrect macro compiler version."));
      return;
   }
   /**
    * Unused as of 5/2/07 because we removed the native Eclipse
    * emulation form for the SlickEdit form.
    */
/*   if (isEclipsePlugin()) {
      eclipseChangeKeyConfiguration(set_emulation);
   }*/
}

/**
 * Returns the currently selected emulation and cooresponding
 * key name.
 *
 * @param new_keys      emulation name
 * @param new_emu       key set for emulation
 */
void getKeysAndEmulation(_str &new_keys, _str &new_emu)
{
   if (_ctlemu_cua_windows.p_value) {
      new_emu='windows';
      new_keys="windows-keys";
   } else if (_ctlemu_cua_mac.p_value) {
      new_emu='macosx';
      new_keys="macosx-keys";
   } else if (_ctlemu_slickedit.p_value) {
      new_emu='slick';
      new_keys="";
   } else if (_ctlemu_brief.p_value) {
      new_emu='brief';
      new_keys="brief-keys";
   } else if (_ctlemu_emacs.p_value) {
      new_emu='emacs';
      new_keys="emacs-keys";
   } else if (_ctlemu_vi.p_value) {
      new_emu='vi';
      new_keys="vi-keys";
   } else if (_ctlemu_gnu.p_value) {
      new_emu='gnu';
      new_keys="gnuemacs-keys";
   } else if (_ctlemu_vcpp.p_value) {
      new_emu='vcpp';
      new_keys="vcpp-keys";
   } else if (_ctlemu_vsnet.p_value) {
      new_emu='vsnet';
      new_keys="vsnet-keys";
   } else if (_ctlemu_ispf.p_value) {
      new_emu='ispf';
      new_keys="ispf-keys";
   } else if (_ctlemu_codewarrior.p_value) {
      new_emu='codewarrior';
      new_keys="codewarrior-keys";
   } else if (_ctlemu_codewright.p_value) {
      new_emu='codewright';
      new_keys="codewright-keys";
   } else if (_ctlemu_bbedit.p_value) {
      new_emu='bbedit';
      new_keys="bbedit-keys";
   } else if (_ctlemu_xcode.p_value) {
      new_emu='xcode';
      new_keys="xcode-keys";
   } else if (_ctlemu_eclipse.p_value) {
      new_emu='eclipse';
      new_keys="eclipse-keys";
   }
}

_str getEmulationFromKeys(_str keys)
{
   emulation := '';
   switch (keys) {
   case "windows-keys":
      emulation = 'windows';
      break;
   case "macosx-keys":
      emulation = 'macosx';
      break;
   case "":
      emulation = 'slick';
      break;
   case "brief-keys":
      emulation = 'brief';
      break;
   case "emacs-keys":
      emulation = 'emacs';
      break;
   case "vi-keys":
      emulation = 'vi';
      break;
   case "gnuemacs-keys":
      emulation = 'gnu';
      break;
   case "vcpp-keys":
      emulation = 'vcpp';
      break;
   case "vsnet-keys":
      emulation = 'vsnet';
      break;
   case "ispf-keys":
      emulation = 'ispf';
      break;
   case "codewarrior-keys":
      emulation = 'codewarrior';
      break;
   case "codewright-keys":
      emulation = 'codewright';
      break;
   case "bbedit-keys":
      emulation = 'bbedit';
      break;
   case "xcode-keys":
      emulation = 'xcode';
      break;
   }

   return emulation;
}

void _ctlemu_ok.lbutton_up()
{
   _emulation_form_apply();
   p_active_form._delete_window(0);
}

void _ctlemu_cua_windows.lbutton_up()
{
   // select the help item according to the selected emulation
   help_message := "";
   new_keys := "";
   new_emulation := "";

   getKeysAndEmulation(new_keys, new_emulation);
   switch(new_emulation) {
   case 'macosx':
      help_message = "The macOS keyboard emulation uses a command set similar to that used in TextEdit.";
      break;
   case 'windows':
      help_message = "The CUA (Common User Access) keyboard emulation uses a command set similar to that used in Microsoft Word and Notepad.";
      break;
   case 'slick':
      help_message = "The SlickEdit keyboard emulation uses a command set similar to that used by the text mode edition of SlickEdit (circa 1995).";
      break;
   case 'brief':
      help_message = "The Brief keyboard emulation uses a command set similar to the Brief editor which was famous on DOS.  This emulation relies heavily on Alt-key combinations.";
      break;
   case 'emacs':
      help_message = "The Epsilon keyboard emulation uses a command set similar to the Epsilon editor which was famous on DOS and very similar to Emacs.  This emulation relies heavily on Ctrl-X and Escape (meta) key combinations.";
      break;
   case 'vi':
      help_message = "The Vim keyboard emulation behaves like the Unix Vim editor, including support of the ex command line.  It supports some, but not all Vim extensions.";
      break;
   case 'gnu':
      help_message = "The GNU Emacs keyboard emulation uses a command set similar to the GNU Emacs editor.  This emulation relies heavily on Ctrl-X and escape (meta) key combinations.  It does not include an emacs lisp emulator.";
      break;
   case 'vcpp':
      help_message = "The Visual C++ keyboard emulation uses a command set similar to that used by Microsoft Visual C++ 6.0.";
      break;
   case 'vsnet':
      help_message = "The Visual Studio .NET keyboard emulation uses a command set similar to that used by Microsoft Visual Studio .NET.";
      break;
   case 'ispf':
      help_message = "The ISPF keyboard emulation behaves like the IBM System/390 ISPF editor.  It includes support for the ISPF prefix line commands, the ISPF command line, rulers, line numbering, and some XEDIT extensions.";
      break;
   case 'codewarrior':
      help_message = "The CodeWarrior keyboard emulation uses command set similar to the Metrowerks CodeWarrior IDE.";
      break;
   case 'codewright':
      help_message = "The CodeWright keyboard emulation uses a command set similar to the CodeWright editor for Windows formerly produced by Premia.";
      break;
   case 'bbedit':
      help_message = "The BBEdit keyboard emulation uses a command set similar to the BBEdit (Bare Bones editor) famous on MacOS.";
      break;
   case 'xcode':
      help_message = "The XCode keyboard emulation uses a command set similar to the XCode IDE found on macOS.";
      break;
   case 'eclipse':
      help_message = "The Eclipse emulation uses a command set similar to the Eclipse IDE.";
      break;
   }

   // fill in the hint
   ctldescription.p_caption = help_message;

   // check to see if this emulation has any custom keybindings - if so, enable the RESTORE button
   firstInit := _GetDialogInfoHt("firstInit", p_active_form, true);
   if (!firstInit && hasSavedKeybindings(new_emulation, new_keys)) {
      _btn_restore.p_enabled = true;
   } else _btn_restore.p_enabled = false;

}

//-----------------------------------------------------------

/**
 * The <b>setup_general</b> command displays the <b>General
 * Options dialog  box</b>.
 *
 * @param showTab    tab number to display initially
 *                   (general, search, select, chars, more, exit, memory)
 *
 * @categories Miscellaneous_Functions
 */
_command void setup_general(_str showTab='')
{
   switch (showTab) {
   case 'general':   showTab=0; break;
   case 'search':    showTab=1; break;
   case 'select':    showTab=2; break;
   case 'chars':     showTab=3; break;
   case 'more':      showTab=4; break;
   case 'exit':      showTab=5; break;
   case 'memory':    showTab=6; break;
   }

   show_general_options(showTab);
}

_command toggle_so_matchcase()
{
   // Get current search options
   int currentSO = (int) _default_option('S');
   // Check for the presence of regex in these options
   if ((currentSO & VSSEARCHFLAG_IGNORECASE) > 0) {
      currentSO = currentSO & ~VSSEARCHFLAG_IGNORECASE;
   }
   else {
      currentSO |= VSSEARCHFLAG_IGNORECASE;
   }
   _default_option('S', currentSO);
}
_command toggle_so_regex()
{
   // Get current search options
   int currentSO = (int) _default_option('S');
   // Check for the presence of regex in these options
   if (currentSO & def_re_search_flags) {
      currentSO = currentSO & ~def_re_search_flags;
   } else {
      currentSO |= def_re_search_flags;
   }
   _default_option('S', currentSO);
}

_command toggle_so_matchword()
{
   // Get current search options
   int currentSO = (int) _default_option('S');
   // Check for the presence of regex in these options
   if ((currentSO & VSSEARCHFLAG_WORD) > 0) {
      currentSO = currentSO & ~VSSEARCHFLAG_WORD;
   }
   else {
      currentSO |= VSSEARCHFLAG_WORD;
   }
   _default_option('S', currentSO);
}
_command toggle_so_backwards()
{
   // Get current search options
   int currentSO = (int) _default_option('S');
   // Check for the presence of regex in these options
   if ((currentSO & VSSEARCHFLAG_REVERSE) > 0) {
      currentSO = currentSO & ~VSSEARCHFLAG_REVERSE;
   }
   else {
      currentSO |= VSSEARCHFLAG_REVERSE;
   }
   _default_option('S', currentSO);
}
_command toggle_so_cursorend()
{
   // Get current search options
   int currentSO = (int) _default_option('S');
   // Check for the presence of regex in these options
   if ((currentSO & VSSEARCHFLAG_POSITIONONLASTCHAR) > 0) {
      currentSO = currentSO & ~VSSEARCHFLAG_POSITIONONLASTCHAR;
   }
   else {
      currentSO |= VSSEARCHFLAG_POSITIONONLASTCHAR;
   }
   _default_option('S', currentSO);
}
_command toggle_so_hiddentext()
{
   // Get current search options
   int currentSO = (int) _default_option('S');
   // Check for the presence of regex in these options
   if ((currentSO & VSSEARCHFLAG_HIDDEN_TEXT) > 0) {
      currentSO = currentSO & ~VSSEARCHFLAG_HIDDEN_TEXT;
   }
   else {
      currentSO |= VSSEARCHFLAG_HIDDEN_TEXT;
   }
   _default_option('S', currentSO);
}

static const SPEC_CHARS_EDITOR_CTRL_NAME=    "_ctlSpecialCharE";
static const SPEC_CHARS_TB_CTRL_NAME=        "_ctlSpecialCharC";
static const SPEC_CHARS_UNICODE_CTRL_NAME=   "_ctlSpecialCharUE";
static const DEC_HEX_RETRIEVE_NAME=          "_special_characters_form._ctlViewDec";

#region Options Dialog Helper Functions

defeventtab _special_characters_form;
static _str ORIG_SPEC_CHARS(...){
   if (arg()) _ctlSpecialCharReset.p_user=arg(1);
   return _ctlSpecialCharReset.p_user;
}
static _str ORIG_UNICODE_SPEC_CHARS(...) {
   if (arg()) _ctlViewDec.p_user=arg(1);
   return _ctlViewDec.p_user;
}
static _str DEC_HEX_MODE(...) {
   if (arg()) _ctlViewHex.p_user=arg(1);
   return _ctlViewHex.p_user;
}
static int ORIG_DISPLAY_TAB(...) {
   if (arg()) ctlDisplayTab.p_user=arg(1);
   return ctlDisplayTab.p_user;
}
static int ORIG_DISPLAY_SPACE(...) {
   if (arg()) ctlDisplaySpace.p_user=arg(1);
   return ctlDisplaySpace.p_user;
}

bool _special_characters_form_is_modified()
{
   buildNewSpecialCharStrings(auto specChars, auto uniSpecChars);
   return (specChars != ORIG_SPEC_CHARS() || uniSpecChars != ORIG_UNICODE_SPEC_CHARS() ||
           ORIG_DISPLAY_TAB()!=ctlDisplayTab.p_value ||
           ORIG_DISPLAY_SPACE()!=ctlDisplaySpace.p_value );
}

bool _special_characters_form_validate()
{
   int wid;
   _str ctlName;
   for (i := FIRSTSPECIALCHAR; i <= LASTSPECIALCHAR; i++) {

      // for the non-unicode, we can use the textbox code value
      ctlName = SPEC_CHARS_TB_CTRL_NAME :+ i;
      wid = _find_control(ctlName);
      if (wid > 0) {

         if (wid.data_not_valid()) {
            msg := '';
            if (DEC_HEX_MODE() == 'D') {
               msg = "Please input a character code between 1 and 255.";
            } else {
               msg = "Please input a character code between 0x1 and 0xFF.";
            }
            _message_box(msg);

            p_window_id = wid;
            wid._set_focus();
            wid._set_sel(1, 1 + length(wid.p_text));
            return false;
         }
      }
   }

   return true;
}

void _special_characters_form_apply()
{
   _macro('m',_macro('s'));

   // get the new values
   buildNewSpecialCharStrings(auto specChars, auto uniSpecChars);
   if (specChars != ORIG_SPEC_CHARS()) {
      ORIG_SPEC_CHARS(specChars);
      // notice that _default_option('Q') and _default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB)
      // do the same exact thing.  I don't know why, but that's the way it is.
      _default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB, specChars);

      // When the special chars are updated from Tools->General, update the Vim list also - RH
      if (def_keys == 'vi-keys') {
         __ex_set_listchars(buildNewVimSpecialCharString());
      }

      _macro_append("_default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB,"_quote(specChars)");");
   }

   // unicode
   if (uniSpecChars != ORIG_UNICODE_SPEC_CHARS()) {
      ORIG_UNICODE_SPEC_CHARS(uniSpecChars);
      _default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8, uniSpecChars);
      _macro_append("_default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8,"_quote(uniSpecChars)");");
   }
   if (ctlDisplayTab.p_value!=ORIG_DISPLAY_TAB()) {
      ORIG_DISPLAY_TAB(ctlDisplayTab.p_value);
      _default_option(VSOPTION_SPECIAL_CHAR_TAB_OPTION, ctlDisplayTab.p_value);
      _macro_append("_default_option(VSOPTION_SPECIAL_CHAR_TAB_OPTION,"ctlDisplayTab.p_value");");
   }
   if (ctlDisplaySpace.p_value!=ORIG_DISPLAY_SPACE()) {
      ORIG_DISPLAY_SPACE(ctlDisplaySpace.p_value);
      _default_option(VSOPTION_SPECIAL_CHAR_SPACE_OPTION, ctlDisplaySpace.p_value);
      _macro_append("_default_option(VSOPTION_SPECIAL_CHAR_SPACE_OPTION,"ctlDisplaySpace.p_value");");
   }
}


_str _special_characters_form_build_export_summary(PropertySheetItem (&summary)[])
{
   error := '';
   PropertySheetItem psi;

   // non-unicode
   specChars := _default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB);
   for (i := FIRSTSPECIALCHAR; i <= LASTSPECIALCHAR; i++) {

      psi.Caption = spec_char_names_table[i - 1];
      ch := substr(specChars, i, 1);
      ascii := _asc(ch);
      uch := _UTF8Chr(ascii);
      psi.Value = uch :+ ' ('ascii')';

      summary[summary._length()] = psi;
   }

   uniSpecChars := _default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8);
   _str array[];
   split(uniSpecChars, \t, array);

   for (i = 0; i < other_ctrl_chars_table._length(); i++) {
      psi.Caption = 'Unicode 'other_ctrl_chars_table[i].name;
      psi.Value = array[i];

      summary[summary._length()] = psi;
   }

   // the last one is End of line
   psi.Caption = 'Unicode End-Of-Line';
   psi.Value = array[i];
   summary[summary._length()] = psi;

   psi.Caption = 'Tab Option';
   psi.Value = _default_option(VSOPTION_SPECIAL_CHAR_TAB_OPTION);
   summary[summary._length()] = psi;

   psi.Caption = 'Space Option';
   psi.Value = _default_option(VSOPTION_SPECIAL_CHAR_SPACE_OPTION);
   summary[summary._length()] = psi;


   return error;
}

_str _special_characters_form_import_summary(PropertySheetItem (&summary)[])
{
   error := '';

   specChars := _default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB);
   uniSpecChars := _default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8);
   _str array[];
   split(uniSpecChars, \t, array);

   _str newTabOption,newSpaceOption;
   newSpecChars := specChars;
   for (i := 0; i < summary._length(); i++) {
      // check for unicode in the caption
      caption := summary[i].Caption;
      if (strieq(summary[i].Caption,'Tab Option')) {
         newTabOption=summary[i].Value;
      } else if (strieq(summary[i].Caption,'Space Option')) {
         newSpaceOption=summary[i].Value;
      } else if (substr(caption, 1, 7) == 'Unicode') {
         caption = strip(substr(caption, 8));

         // one special case - end of line
         if (caption == 'End-Of-Line') {
            // it goes in the last slot
            array[array._length() - 1] = summary[i].Value;
         } else {
            // otherwise, check it against all the other captions
            for (j := 0; j < other_ctrl_chars_table._length(); j++) {
               if (caption == other_ctrl_chars_table[j].name) {
                  array[j] = summary[i].Value;
               }
            }
         }
      } else {
         // compare it to the captions in our table
         for (j := 0; j < spec_char_names_table._length(); j++) {
            if (caption == spec_char_names_table[j]) {
               // split off the ascii from the value
               value := summary[i].Value;
               parse value with auto ch '(' auto ascii ')';
               newSpecChars = substr(newSpecChars, 1, j) :+ _chr((int)ascii) :+ substr(newSpecChars, j + 2);
            }
         }
      }
   }
   if (isinteger(newTabOption) && newTabOption!=_default_option(VSOPTION_SPECIAL_CHAR_TAB_OPTION)) {
      _default_option(VSOPTION_SPECIAL_CHAR_TAB_OPTION,newTabOption);
   }
   if (isinteger(newSpaceOption) && newSpaceOption!=_default_option(VSOPTION_SPECIAL_CHAR_SPACE_OPTION)) {
      _default_option(VSOPTION_SPECIAL_CHAR_SPACE_OPTION,newSpaceOption);
   }

   // set the regular ones
   if (specChars != newSpecChars) {
      _default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB, newSpecChars);
   }

   // set the unicode
   newUniSpecChars := '';
   for (i = 0; i < array._length(); i++) {
      newUniSpecChars :+= array[i];
      if (i != array._length() - 1) {
         newUniSpecChars :+= \t;
      }
   }

   if (newUniSpecChars != uniSpecChars) {
      _default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8, newUniSpecChars);
   }

   // all done
   return error;
}

#endregion Options Dialog Helper Functions

void _special_characters_form.on_resize()
{
   heightDiff := p_height - (_ctlSpecialCharReset.p_y_extent);
   widthDiff := p_width - (_ctlSpecialCharReset.p_x_extent);

   // resize frames
   ctl_unicode_frame.p_height += heightDiff;
   ctl_unicode_frame.p_width += widthDiff;

   ctl_nonunicode_frame.p_width += widthDiff;

   _ctlSpecialCharReset.p_x += widthDiff;
   _ctlSpecialCharReset.p_y += heightDiff;

   origTreeWidth := ctl_unicode_tree.p_width;

   // get the column widths
   int widths[];
   int bw, bf, bs;
   _str caption;
   for (i := 0; i < 3; ++i) {
      ctl_unicode_tree._TreeGetColButtonInfo(i,bw,bf,bs,caption);
      widths[i] = bw;
   }

   // resize tree
   ctl_unicode_tree.p_height += heightDiff;
   ctl_unicode_tree.p_width += widthDiff;

   // now scale columns
   double ratio = (double)ctl_unicode_tree.p_width / (double)origTreeWidth;

   for (i = 0; i < 3; ++i) {
      ctl_unicode_tree._TreeGetColButtonInfo(i,bw,bf,bs,caption);
      bw = (int)(widths[i] * ratio);
      ctl_unicode_tree._TreeSetColButtonInfo(i,bw,bf,bs,caption);
   }
   ctlDisplayTab.p_y+=heightDiff;
   ctlDisplaySpace.p_y+=heightDiff;
}

static void buildNewSpecialCharStrings(_str &specChars, _str& uniSpecChars)
{
   specChars = uniSpecChars = '';

   // some of the stuff at the beginning of the string is not used, so pad the new string with the old
   diff := length(ORIG_SPEC_CHARS()) - (LASTSPECIALCHAR - FIRSTSPECIALCHAR + 1);
   if (diff > 0) {
      specChars = substr(ORIG_SPEC_CHARS(), 1, diff);
   }

   int wid;
   _str ctlName;
   for (i := FIRSTSPECIALCHAR; i <= LASTSPECIALCHAR; i++) {

      // for the non-unicode, we can use the textbox code value
      ctlName = SPEC_CHARS_TB_CTRL_NAME :+ i;
      wid = _find_control(ctlName);
      if (wid > 0) {

         typeless dec=wid.p_text;
         if (wid.data_not_valid()) {
            dec = 0;
         } else {
            if (_ctlViewHex.p_value) {
               // if this is a hex value, convert it
               dec = _hex2dec(dec);
            }
         }
         specChars :+= _chr(dec);

      }
   }

   // okay, end of line is at the top, but it's at the end of the array!
   firstIndex := ctl_unicode_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   index := ctl_unicode_tree._TreeGetNextSiblingIndex(firstIndex);

   while (index > 0) {
      uniSpecChars :+= ctl_unicode_tree._TreeGetCaption(index, 3) :+ \t;
      index = ctl_unicode_tree._TreeGetNextSiblingIndex(index);
   }

   // finally, add the last bit
   uniSpecChars :+= ctl_unicode_tree._TreeGetCaption(firstIndex, 3);
}

static _str buildNewVimSpecialCharString()
{
   buildNewSpecialCharStrings(auto specChars, auto uniSpecChars);

   //// Clark: I have not studied the vi code path
   //// close enough to know what is supposed to be done here.
   //// I suspect this code is wrong. For simplicity the VI functions
   //// should take a character code and NOT the actual character.
   //// This would require a lot of changes in the vi code though.
   //// Maybe passing the values in an array (utf-8 array?) would
   //// be better.
   ////
   ////If the vi code path is broken. It's no worse that v17.0 or v17.0.1

   // grab eol
   vimSpecChars := 'eol:'substr(specChars, VSSPECIALCHAR_EOL + 1, 1)',';

   // and tab
   // this is no longer configurable
   //vimSpecChars :+= 'tab:'substr(specChars, VSSPECIALCHAR_TAB + 1, 1)',';

   // eof
   vimSpecChars :+= substr(specChars, VSSPECIALCHAR_EOF + 1, 1);

   // and we're done!
   return vimSpecChars;
}

_special_characters_form.on_destroy()
{
   decHex := _ctlViewDec.p_value ? 'D' : 'H';
   _append_retrieve(0, decHex, '_special_characters_form._ctlViewDec');
}

static int data_not_valid()
{
   old_format := DEC_HEX_MODE();
   text := p_text;
   //message 'old_format='old_format
   switch (old_format) {
   case 'H':
      _str dec=hex2dec(text);
      if (!(isinteger(dec) && dec<=255 && dec>0)) {
         return(1);
      }
      break;
   case 'A':
      if (length(text)!=1) {
         return(1);
      }
      break;
   default:
      if (!(isinteger(text) && text<=255 && text>0)) {
         return(1);
      }
   }
   return(0);
}
void _ctlViewDec.lbutton_up()
{
   configSpecialCharNumToggle('D');
}
void _ctlViewHex.lbutton_up()
{
   configSpecialCharNumToggle('H');
}

static void setSpecialCode(int val)
{
   // decimal is easy
   if (DEC_HEX_MODE() == 'D') {
      p_text = val;
   } else {
      text := dec2hex(val);
      text = substr(text,3);
      if (length(text) < 2) {
         text = "0x0" :+ text;
      } else {
         text = "0x" :+ text;
      }
      p_text = text;
   }
   p_user=val;
}

static void setSpecialChar(typeless val)
{
   // this is ain't pretty, but normal textbox will not display the special characters correctly
   if (val!=p_user) {
      p_user=val;
      p_enabled=true;
      p_ReadOnly=false;
      delete_all(); top();
      insert_line(val);
      top(); _SetTextColor( CFG_WINDOW_TEXT, 1 ); top();
      p_ReadOnly=true;
      p_enabled=false;
   }
}

void _ctlSpecialCharC1.on_change()
{
   // make sure we're properly hexafied
   text := lowcase(p_text);
   if ((text=='x' || text=='0x') && (DEC_HEX_MODE() != 'H')) {
      configSpecialCharNumToggle('H', p_window_id);
      _ctlViewHex.p_value = 1;
   }

   value := 0;
   if (DEC_HEX_MODE() == 'H') {
      typeless dec = hex2dec(p_text);
      if (dec != '') {
         value = dec;
      }
   } else {
      if (isinteger(p_text) && p_text <= 255 && p_text > 0) {
         value = (int)p_text;
      }
   }

   if (p_user != value) {
      p_user = value;
      p_prev.setSpecialChar(_MultiByteToUTF8(_chr(value)));
   }
}
void _ctlSpecialCharSpin.on_spin_up(_str direction='')
{
   textwid := p_prev;
   typeless dec = textwid.p_user;
   if (direction != '') {
      if (dec > 1) --dec;
   } else {
      if (dec < 255) ++dec;
   }

   textwid.setSpecialCode(dec);
   //textwid.p_prev.setSpecialChar(dec);
}

void _ctlSpecialCharSpin.on_spin_down()
{
   call_event('-',p_window_id,ON_SPIN_UP,'');
}

static void configSpecialCharNumToggle(_str mode, int ignore_wid=0)
{
   // we're already in this mode, no need to do anything
   if (DEC_HEX_MODE() == mode) return;

   DEC_HEX_MODE(mode);

   // go through the controls and set the new values
   int wid;
   _str ctlName;
   for (i := FIRSTSPECIALCHAR; i <= LASTSPECIALCHAR; i++) {
      ctlName = SPEC_CHARS_TB_CTRL_NAME :+ i;
      wid = _find_control(ctlName);
      if ( ignore_wid != wid ) {
         val := wid.p_user;
         wid.setSpecialCode(val);
      }
   }
}

void _ctlSpecialCharReset.on_create()
{
   // set the original values
   ORIG_UNICODE_SPEC_CHARS(_default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8));
   ORIG_SPEC_CHARS(_default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB));
   ORIG_DISPLAY_TAB(_default_option(VSOPTION_SPECIAL_CHAR_TAB_OPTION));
   ORIG_DISPLAY_SPACE(_default_option(VSOPTION_SPECIAL_CHAR_SPACE_OPTION));

   ctlDisplayTab.p_value=ORIG_DISPLAY_TAB();
   ctlDisplaySpace.p_value=ORIG_DISPLAY_SPACE();

   // dec or hex?
   //decHex := _ctlViewDec.p_value ? 'D' : 'H';
   decHex := _retrieve_value(DEC_HEX_RETRIEVE_NAME);
   if (decHex == '' || decHex == 'D') {
      _ctlViewDec.p_value = 1;
   } else {
      _ctlViewHex.p_value = 1;
   }

   // non-unicode
   int wid;
   _str ctlName;
   for (i := FIRSTSPECIALCHAR; i <= LASTSPECIALCHAR; i++) {

      ctlName = SPEC_CHARS_EDITOR_CTRL_NAME :+ i;
      wid = _find_control(ctlName);
      if (wid > 0) {
         setupEditorControl(wid);
      }
   }

   setNonUnicodeSpecialChars(ORIG_SPEC_CHARS());
   setupUnicodeTree();
   setUnicodeSpecialChars(ORIG_UNICODE_SPEC_CHARS());
}

static void setNonUnicodeSpecialChars(_str valueString)
{
   _str val;
   int wid;
   _str ctlName;
   for (i := FIRSTSPECIALCHAR; i <= LASTSPECIALCHAR; i++) {

      // regular
      ctlName = SPEC_CHARS_EDITOR_CTRL_NAME :+ i;
      wid = _find_control(ctlName);
      if (wid > 0) {
         val = substr(valueString, i, 1);
         wid.setSpecialChar(_MultiByteToUTF8(val));
         wid=wid.p_next;
         wid.setSpecialCode(_asc(val));
      }
   }
}

static void setupUnicodeTree()
{
   colWidth := ctl_unicode_tree.p_width intdiv 7;
   ctl_unicode_tree._TreeSetColButtonInfo(0, colWidth, -1, -1, 'ASCII');
   ctl_unicode_tree._TreeSetColButtonInfo(1, colWidth, -1, -1, 'Char');
   ctl_unicode_tree._TreeSetColButtonInfo(2, colWidth * 2, -1, -1, 'Name');
   ctl_unicode_tree._TreeSetColButtonInfo(3, colWidth * 3, 0, -1, 'Value');
   ctl_unicode_tree._TreeSetColEditStyle(3, TREE_EDIT_TEXTBOX | TREE_EDIT_BUTTON);

   // start with End of Line
   caption := \t\t'End-Of-Line'\t;

   rowID := ctl_unicode_tree._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0);
   ctl_unicode_tree._TreeSetNodeEditStyle(rowID, 1, TREE_EDIT_TEXTBOX | TREE_EDIT_BUTTON);

   for (i := 0; i < other_ctrl_chars_table._length(); i++) {
      caption = i\tother_ctrl_chars_table[i].character\tother_ctrl_chars_table[i].name\t;
      rowID = ctl_unicode_tree._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0);
      ctl_unicode_tree._TreeSetNodeEditStyle(rowID, 1, TREE_EDIT_TEXTBOX | TREE_EDIT_BUTTON);
   }
}

int ctl_unicode_tree.on_change(int reason, int index, int col = -1, _str value = "", int wid = 0)
{
   switch (reason) {
   case CHANGE_EDIT_OPEN:
      return 0;
   case CHANGE_NODE_BUTTON_PRESS:
      {
         // get our cursor position in the textbox
         wid._get_sel(auto sp, auto ep);

         ch := p_active_form.show("-modal -xy _inslit_form", true);
         if (ch :!= '') {

            // insert the code as best we can - it may not show up very well
            text := wid.p_text;
            if (ep > length(text)) {
               // just shove it at the end
               text :+= ch;
            } else {
               text = substr(text, 1, ep - 1) :+ ch :+ substr(text, ep);
            }
            wid.p_text = text;
         }
      }
      break;
   case CHANGE_EDIT_PROPERTY:
      return TREE_EDIT_COLUMN_BIT|3;
      break;
   }

   return 0;
}

static void setUnicodeSpecialChars(_str valueString)
{
   _str array[];
   split(valueString, \t, array);

   // okay, end of line is at the top, but it's at the end of the array!
   index := ctl_unicode_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (array._length() > other_ctrl_chars_table._length()) {
      ctl_unicode_tree._TreeSetCaption(index, array[array._length() - 1], 3);
   }

   i := 0;
   while (true) {
      index = ctl_unicode_tree._TreeGetNextSiblingIndex(index);
      if (i > array._length() - 1 || index < 0) break;

      ctl_unicode_tree._TreeSetCaption(index, array[i], 3);
      i++;
   }
}

static void setupEditorControl(int wid)
{
   if (wid > 0) {
      wid._use_edit_font();
      wid.p_line_numbers_len=0;
      wid.p_LCBufFlags&=~(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_READWRITE);
      wid.p_user=-1;
      wid.p_height=max(_dy2ly(SM_TWIP,wid.p_font_height)+wid._top_height()*2, wid.p_height);
      wid.p_ReadOnly = true;
      wid.p_encoding=VSCP_ACTIVE_CODEPAGE;
   }

}

void _ctlSpecialCharReset.lbutton_up()
{
   setNonUnicodeSpecialChars(ORIG_SPEC_CHARS());
   setUnicodeSpecialChars(ORIG_UNICODE_SPEC_CHARS());
}

// END -- defeventtab _special_characters_form;

#region Options Dialog Helper Functions

defeventtab _selections_options_form;

static const CUA_STYLE= 'CN D 1 .';
static const CUAADV_STYLE= 'CN D 1 P 1';
static const SLICKEDITEXT_STYLE= 'CI Y 0 P';

static typeless SELECTIONS_TABLE(...):[] {
   if (arg()) _userdefined.p_user=arg(1);
   return _userdefined.p_user;
}
void _selections_options_form_init_for_options()
{
   config_initSelStyle();
}

bool _selections_options_form_apply()
{
   typeless ht:[];
   ht = SELECTIONS_TABLE();

   _macro('m',_macro('s'));

   def_advanced_select='P';
   //_macro_append('def_advanced_select='_quote(def_advanced_select)';');

   if(ctldelsel.p_value) {
      def_persistent_select='D';
   } else {
      if (ctlautodeselect.p_value) {
         def_persistent_select='N';
      } else {
         def_persistent_select='Y';
      }
   }
   if (def_persistent_select != ht:["def_persistent_select"]) {
     _macro_append('def_persistent_select='_quote(def_persistent_select)';');
   }

   def_deselect_paste= _deselect_after_paste.p_value!=0;
   if (_deselect_after_paste.p_value != ht:["_deselect_after_paste.p_value"]) {
      _macro_append('def_deselect_paste='def_deselect_paste';');
   }

   def_deselect_copy= _deselect_after_copy.p_value!=0;
   if (_deselect_after_copy.p_value != ht:["_deselect_after_copy.p_value"]) {
      _macro_append('def_deselect_copy='def_deselect_copy';');
   }

   def_deselect_drop= _deselect_after_drop.p_value!=0;
   if (_deselect_after_drop.p_value != ht:["_deselect_after_drop.p_value"]) {
      _macro_append('def_deselect_drop='def_deselect_drop';');
   }

   def_select_style=upcase(def_select_style);

   style1 := _extend.p_value?'C':'E';
   style2 := _inclusive_char.p_value?'I':'N';
   def_select_style=style1:+style2;

   if (def_select_style != ht:["def_select_style"]) {
      _macro_append('def_select_style='_quote(def_select_style)';');
   }

   def_inclusive_block_sel = _inclusive_block.p_value;
   if (_inclusive_block.p_value != ht:["_inclusive_block.p_value"]) {
      _macro_append('def_inclusive_block_sel='def_inclusive_block_sel';');
   }

   def_scursor_style= _shiftcursor.p_line-1;
   if (def_scursor_style<0) {
      def_scursor_style=0;
   }
   if (_shiftcursor.p_line != ht:["_shiftcursor.p_value"]) {
      _macro_append('def_scursor_style='def_scursor_style';');
   }

   def_cua_select_alt_shift_block= ctlaltshiftblock.p_value!=0;
   if (ctlaltshiftblock.p_value != ht:["ctlaltshiftblock.p_value"]) {
      _macro_append('def_cua_select_alt_shift_block='def_cua_select_alt_shift_block';');
   }

   def_autoclipboard=ctlmouseclipboard.p_value!=0;
   if (ctlmouseclipboard.p_value != ht:["ctlmouseclipboard.p_value"]) {
      _macro_append('def_autoclipboard='def_autoclipboard';');
   }

   def_cursor_beginend_select=ctlbeginendselect.p_value!=0;
   if (ctlbeginendselect.p_value != ht:["ctlbeginendselect.p_value"]) {
      _macro_append('def_cursor_beginend_select='def_cursor_beginend_select';');
   }

   def_mouse_menu_style = (_enable_block_select.p_value != 0) ? MM_MARK_FIRST : MM_TRACK_MOUSE;
   if (_enable_block_select.p_value != ht:['_enable_block_select.p_value']) {
      _macro_append('def_mouse_menu_style='def_mouse_menu_style';');
   }

   def_modal_tab = ctlIndentSelection.p_value;
   if (ctlIndentSelection.p_value != ht:['ctlIndentSelection.p_value']) {
      _macro_append('def_modal_tab='def_modal_tab';');
   }

   clipFormats := "";
   if (_cfHTML.p_value) {
      clipFormats :+= 'H';
   }
   if (clipFormats != def_clipboard_formats) {
      def_clipboard_formats = clipFormats;
      _macro_append('def_clipboard_formats="'def_clipboard_formats'";');
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);

   return true;
}

#endregion Options Dialog Helper Functions

static void config_initSelStyle()
{
   typeless ht:[];

   _macro('m',_macro('s'));
   _cuaadv.p_user=CUAADV_STYLE;

   // we set and save all the current values

   // def-persistent-select value goes with ctldelsel and ctlautodeselect
   def_persistent_select = upcase(def_persistent_select);
   ht:["def_persistent_select"] = def_persistent_select;
   ctldelsel.p_value = (int)(def_persistent_select=='D');
   ctlautodeselect.p_value = (int)(def_persistent_select!='Y');

   // def-deselect-paste goes with _deselect_after_paste
   ht:["_deselect_after_paste.p_value"] = _deselect_after_paste.p_value;
   _deselect_after_paste.p_value = (int)def_deselect_paste;

   // def-deselect-copy goes with _deselect_after_copy
   if (def_deselect_copy == "") def_deselect_copy = true;
   if (def_deselect_copy == null) def_deselect_copy = false;
   ht:["_deselect_after_copy.p_value"] = _deselect_after_copy.p_value;
   _deselect_after_copy.p_value= (int)def_deselect_copy;

   // def-deselect-drop goes with _deselect_after_drop
   ht:["_deselect_after_drop.p_value"] = _deselect_after_drop.p_value;
   _deselect_after_drop.p_value= (int)def_deselect_drop;

   // def-select-style goes with _inclusive_char and _extend
   def_select_style = upcase(def_select_style);
   ht:["def_select_style"] = def_select_style;
   _inclusive_char.p_value=pos('I',def_select_style);
   _extend.p_value=pos('C',def_select_style);

   // def_inclusive_block_sel => _inclusive_block
   _inclusive_block.p_value= def_inclusive_block_sel;
   ht:["_inclusive_block.p_value"] = _inclusive_block.p_value;

   // def-scursor-style goes with _shiftcursor
   _shiftcursor._lbadd_item("Always char select");
   _shiftcursor._lbadd_item("Char, Line, or Block select");
   _shiftcursor._lbadd_item("Char or Line select");
   if (def_scursor_style==2) {
      _shiftcursor.p_text="Char or Line select";
   } else if (def_scursor_style==1) {
      _shiftcursor.p_text="Char, Line, or Block select";
   } else {
      _shiftcursor.p_text="Always char select";
   }
   ht:["_shiftcursor.p_value"] = def_scursor_style;

   ctlaltshiftblock.p_value= (int)(def_cua_select_alt_shift_block!=0);
   ht:["ctlaltshiftblock.p_value"] = ctlaltshiftblock.p_value;

   // def-autoclipboard goes with ctlmouseclipboard
   ctlmouseclipboard.p_value=(int)(def_autoclipboard!=0);
   ht:["ctlmouseclipboard.p_value"] = ctlmouseclipboard.p_value;

   // def-cursor-beginend-select goes with ctlbeginendselect
   ctlbeginendselect.p_value=(int)(def_cursor_beginend_select!=0);
   ht:["ctlbeginendselect.p_value"] = ctlbeginendselect.p_value;

   // def_mouse_menu_style goes with _enable_block_select
   _enable_block_select.p_value=(int)(def_mouse_menu_style==MM_MARK_FIRST);
   ht:["_enable_block_select.p_value"] = _enable_block_select.p_value;

   ctlIndentSelection.p_value = (int)def_modal_tab;
   ht:["ctlIndentSelection.p_value"] = ctlIndentSelection.p_value;

   // shift cursor is enabled in cua mode
   _shiftcursorlabel.p_enabled=_shiftcursor.p_enabled=(name_on_key(S_UP)=='cua-select');
   ctlaltshiftblock.p_enabled=(name_on_key(name2event('a-s-up'))=='cua-select');

   // here we enable stuff
   enabled := !(def_keys=='brief-keys' || def_keys=='emacs-keys');
   _deselect_after_copy.p_enabled=enabled;
   _deselect_after_paste.p_enabled=enabled;
   _extend.p_enabled=enabled;
   ctlautodeselect.p_enabled=enabled;
   _deselect_after_drop.p_enabled=true;

   _update_style();

   _cfHTML.p_value = pos('H',def_clipboard_formats);

   SELECTIONS_TABLE(ht);
}

void _extend.lbutton_up()
{
   _userdefined.p_value = 1;
   _userdefined.p_enabled = true;
   _update_style();
}

void ctldelsel.lbutton_up()
{
   if (ctldelsel.p_value) {
      ctlautodeselect.p_value=1;
   }
   _update_style();
}
void ctlautodeselect.lbutton_up()
{
   if (!ctlautodeselect.p_value) {
      ctldelsel.p_value=0;
   }
   _update_style();
}

void _cuaadv.lbutton_up()
{
   typeless select_style='';
   typeless persistent='';
   typeless deselect='';
   typeless advselect='';
   typeless block='';
   parse p_user with select_style persistent deselect advselect block . ;

   _extend.p_value= (int)(substr(select_style,1,1)=='C');
   _inclusive_char.p_value= (int)(substr(select_style,2,1)=='I');

   switch (persistent) {
   case 'D':
      ctldelsel.p_value=1;
      ctlautodeselect.p_value=1;
      break;
   case 'Y':
   case 'N':
      ctldelsel.p_value=0;
      ctlautodeselect.p_value=(int)(persistent=='N');
      break;
   }

   _deselect_after_paste.p_value=deselect;
   _inclusive_block.p_value = block;
}

static _str _get_style()
{
   result := "";
   result=((_extend.p_value)?'C':'E');
   result :+= ((_inclusive_char.p_value)?'I':'N');

   result :+= ' ';
   if (ctldelsel.p_value) {
      result :+= 'D';
   } else {
      if (ctlautodeselect.p_value) {
         result :+= 'N';
      } else {
         result :+= 'Y';
      }
   }

   result :+= ' ';
   result :+= _deselect_after_paste.p_value;

   result :+= ' ';
   result :+= 'P';
   result :+= ' '_inclusive_block.p_value;
   return(result);
}

static void _update_style()
{
   typeless style = _get_style();
   if (style == CUAADV_STYLE ){
      _cuaadv.p_value=1;
   } else {
      _userdefined.p_enabled = true;
      _userdefined.p_value = 1;
   }
}

