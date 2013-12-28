////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49880 $
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
#include "eclipse.sh"
#import "complete.e"
#import "dirlist.e"
#import "dlgman.e"
#import "filelist.e"
#import "files.e"
#import "frmopen.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "recmacro.e"
#import "saveload.e"
#import "setupext.e"
#import "stdprocs.e"
#import "tbcmds.e"
#import "tbsearch.e"
#import "util.e"
#endregion

   _combo_box _openfile_types
   _check_box _openexpand
   _check_box _openreadonly
   _check_box _openlock
   _check_box _openpreload
   _check_box _openbinary
// _command_button _openadv
   _radio_button _opendos
   _radio_button _openmac
   _radio_button _openunix
   _radio_button _openauto
   _text_box _openlinesep
   _text_box _openwidth
   _text_box _openfn
   _list_box _opendir_list

   _str def_ext;   // Default open and save as extension.
   _str def_quickopen;

   #define QO_NO_FILELIST 0
   #define QO_USE_FILELIST 1

/**
 * Opens one or more files for editing.  The <b>Open dialog box</b> is 
 * used to prompt for files and open options.  If a file is already open, that 
 * file is activated.
 * 
 * @param ofn_flags defaults to (OFN_READONLY|OFN_ALLOWMULTISELECT) and
 * may be a combination of the following flag constants defined in "slick.sh":
 * 
 * <dl>
 * <dt>OFN_ALLOWMULTISELECT</dt>
 * <dd>Allow multiple file selection.  When set, caller must process a return 
 * value which may have space delimited filenames, some of which are double 
 * quoted.</dd>
 * <dt>OFN_FILEMUSTEXIST</dt>
 * <dd>File(s) selected must exist.</dd>  
 * <dt>OFN_CHANGEDIR</dt>
 * <dd>Don't restore original directory on exit</dd>
 * <dt>OFN_NOOVERWRITEPROMPT</dt>
 * <dd>Don't prompt user with overwrite existing dialog.</dd>
 * <dt>OFN_SAVEAS</dt>
 * <dd>File list box does not select files and user is 
 * prompted whether to overwrite an existing file.</dd>
 * <dt>OFN_READONLY</dt>
 * <dd>Show read only button.  See OFN_PREFIXFLAGS flag.</dd>
 * <dt>OFN_KEEPOLDFILE</dt>
 * <dd>Show keep old name button. See OFN_PREFIXFLAGS flag.</dd>
 * <dt>OFN_PREFIXFLAGS</dt>
 * <dd>Prefix return value with -r if OFN_READONLY flag given and -n if 
 * <dt>OFN_KEEPOLDFILE flag given.</dd>
 * </dl>
 * 
 * @return Returns 0 if successful.
 * 
 * @see e
 * @see edit
 * 
 * @appliesTo Edit_Window
 *
 * @categories File_Functions
 * 
 */
_command gui_open(typeless flags="") name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   if (isEclipsePlugin()) {
      _eclipse_file_open();
      return(0);
   }

   // see if we need to prompt about the open style
   if (def_prompt_open_style) {
      result := show('-modal _open_style_prompt_form');
      if (result == IDCANCEL) return COMMAND_CANCELLED_RC;
   }

   // Unfortunately, last_index() is not set when gui_open is invoked
   // from the menu bar.  This should be changed in the future.
   boolean key_or_cmdline=_executed_from_key_or_cmdline('gui-open');
   _macro_delete_line();
   int a2_flags=0;
   _str a2_text='0';
   if (1 /* key_or_cmdline */) {
      a2_flags=EDIT_DEFAULT_FLAGS;
      a2_text='"EDIT_DEFAULT_FLAGS"';
   } else {
      a2_flags=0;
      a2_text='0';
   }

   // which open style do we use?
   switch (def_open_style) {
   case OPEN_BROWSE_FOR_FILES:
      return browse_open(a2_flags);
      break;
   case OPEN_SMART_OPEN:
   default:
      return smart_open(a2_flags);
      break;
   }
}

_command void smart_open(int editFlags = EDIT_DEFAULT_FLAGS) name_info(',')
{
   activate_open();
}

_command browse_open(int editFlags = EDIT_DEFAULT_FLAGS, typeless flags = OFN_READONLY|OFN_ALLOWMULTISELECT) name_info(',')
{
   _str options='-new -mdi -modal';
   if( p_active_form.p_name=="_sellist_form" ) {
      // Probably being called from Link Window dialog, so parent the Open
      // dialog to it.
      options='-new -modal';
   }
   typeless result=_OpenDialog(options,
        'Open',
        _last_wildcards,      // Initial wildcards
        //'*.c;*.h',
        def_file_types,
        OFN_SET_LAST_WILDCARDS|OFN_EDIT|flags,
        def_ext,      // Default extension
        '',      // Initial filename
        ''       // Initial directory
        );
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   p_window_id=_mdi._edit_window();
   // When change is made to last_index, want if(key_or_cmdline) here.
   // leave out a2_text argument because its not documented
   _macro('m',_macro('s'));
   _macro_call('edit',result /* ,a2_text */);
   //say('gui_open: result='result', a2_flags='a2_flags);
   return(edit(result,editFlags));
}

// Initialize the non-standard open file dialog stuff
static init_response()
{
   _openexpand.p_value=2;
   _openreadonly.p_value=2;
   _openlock.p_value=2;
    _openpreload.p_value=2;

   _openauto.p_value=1;
   //_openwide.p_value=2;
   //_openlinesep.p_text=''
}

_str _edit_get_switches()
{
   _str switches='';
   if (_openexpand.p_value!=2) {
      switches=switches' '((_openexpand.p_value)?'+e':'-e');
   }
   if (_openreadonly.p_value!=2) {
      switches=switches' '((_openreadonly.p_value)?'"-*read_only_mode 1"':'"-*read_only_mode 0"');
   }
   if (_openlock.p_value!=2) {
      switches=switches' '((_openlock.p_value)?'+n':'-n');
   }
   if (_openpreload.p_value!=2) {
      switches=switches' '((_openpreload.p_value)?'+lz':'-lz');
   }
   if (_openbinary.p_value!=2) {
      switches=switches' '((_openbinary.p_value)?'+lb':'-lb');
   }
   if (_opennewwin.p_value!=2) {
      switches=switches' '(_opennewwin.p_value?'+w':'-w');
   }
   // Process file format options
   if (_opendos.p_value) {
      switches=switches' +fd';
   }
   if (_openmac.p_value) {
      switches=switches' +fm';
   }
   if (_openunix.p_value) {
      switches=switches' +fu';
   }
   if (_openlinesep.p_text!='') {
      switches=switches' +f'_openlinesep.p_text;
   }
   if (_openwidth.p_text!='') {
      switches=switches' +'_openwidth.p_text;
   }
   return(switches);
}
/**
 * Creates an empty dialog box form for editing with the dialog editor.
 * 
 * @return Returns 0 if new form successfully created.
 * 
 * @appliesTo Edit_Window
 * @categories Buffer_Functions
 * 
 */
_command void new() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
    // If were started as part of the eclipse plug-in then
   // we need to new the "Eclipse" way
   //
   if (isEclipsePlugin()) {
      _eclipse_new(0, "");
      return;
   }
   _macro_delete_line();
   show('-modal -mdi _workspace_new_form','F');
}

/**
 * Creates an unnamed empty file in the specified editing mode.
 * 
 * @param mode_name     Mode name, default is Plain Text
 * 
 * @return Returns 0 if successful.
 * 
 * @see edit
 * 
 * @appliesTo Edit_Window
 * @categories Buffer_Functions
 */
_command new_file(_str mode_name="") name_info(MODENAME_ARG','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   _macro_delete_line();
   _str result='+t';
   _macro('m',_macro('s'));
   _macro_call('edit',result);
   p_window_id=_mdi._edit_window();
   typeless status = edit(result);
   if (!status && mode_name!="") {
      select_mode(mode_name);
   }
   return status;
}

/**
 * Saves the current buffer under a name you specify.  The <b>Explorer 
 * Standard Open dialog box</b> or <b>Standard Open dialog box</b> is displayed 
 * to prompt you for the output file name.  The name of the current buffer is 
 * changed unless the Keep old name check box is checked.  You may use the "Save 
 * File As Type" combo box to change file format to DOS, UNIX, or Macintosh 
 * ASCII format.
 * 
 * @return Returns 0 if successful.
 * 
 * @see save
 * @see name
 * @see save_as
 * 
 * @appliesTo Edit_Window
 *
 * @categories File_Functions
 * 
 */
_command gui_save_as() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   if ( index_callable(find_index("delphiIsRunning",PROC_TYPE)) ) {
      if ( delphiIsRunning() && delphiIsBufInDelphi(p_buf_name) ) {
         //sticky_message( "gui_save_as file="p_buf_name );
         delphiSaveAsBuffer( p_buf_name );
         return( 0 );
      }
   }
   _macro_delete_line();
   // Not sure if should support def_preplace option
   // If want to just or in OFN_NOOVERWRITEPROMPT
   int orig_wid=p_window_id;
   int unixflags=0;
#if __UNIX__
   _str attrs=file_list_field(p_buf_name,DIR_ATTR_COL,DIR_ATTR_WIDTH);
   int w=pos('w',attrs,'','i');
   if (!w && attrs!='') {
      unixflags=OFN_READONLY;
   }
#endif
   _str format_list='Current Format,DOS Format,UNIX Format,Macintosh Format';
   _str filename=p_buf_name;
   if (!_HaveValidOuputFileName(filename) && iswildcard(filename)) {
      filename='';
   }
   if (_isGrepBuffer(filename)) {
      filename = get_grep_buffer_filename(filename);
   }
   boolean doParseLineFormats=true;
   if (!__UNIX__) {
      format_list=def_file_types;
      doParseLineFormats=false;
   }
   refresh();
   _str init_filename;
   if (_FileQType(filename)==VSFILETYPE_NORMAL_FILE) {
      init_filename=maybe_quote_filename(filename);
   } else {
      init_filename=maybe_quote_filename(_strip_filename(filename,'P'));
   }
   typeless result=_OpenDialog('-new -modal',
        'Save As',
        '',     // Initial wildcards
        format_list,  // file types
        OFN_SAVEAS|OFN_SAVEAS_FORMAT|OFN_KEEPOLDFILE|OFN_PREFIXFLAGS|OFN_ADD_TO_PROJECT|unixflags,
        def_ext,      // Default extensions
        init_filename, // Initial filename
        '',      // Initial directory
        '',      // Reserved
        "Save As dialog box"
        );
   //messageNwait('_param1='_param1);
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   p_window_id=orig_wid;
   if (doParseLineFormats) {
      int i;
      for (i=1;;++i) {
         typeless format="";
         parse format_list with format','format_list;
         if (format=='') break;
         if (_param1==format) {
            switch (i) {
            case 1:  // No format change
               break;
            case 2:  // Dos format
               result='+fd 'result;
               break;
            case 3:  //UNIX format
               result='+fu 'result;
               break;
            case 4:  //Macintosh format
               result='+fm 'result;
               break;
            }
            break;
         }
      }
   }
   _macro('m',_macro('s'));
   if (isEclipsePlugin()) {
      result="-CFE ":+result;
   }
   _macro_call('save_as',result,SV_RETRYSAVE|SV_OVERWRITE);
   return(save_as(result,SV_RETRYSAVE|SV_OVERWRITE));
}


static void retrieve_edited_filenames()
{
   int command_view_id=0;
   int orig_view_id=0;
   typeless status=_open_temp_view('.command',command_view_id,orig_view_id);
   if (status) {
      return;
   }
   _str filename="";
   bottom();
   int nlines=p_line;
   while (p_line>nlines-500) {
      status=search('(^e )|(^edit )|(^\@cb _edit_form\._openfn\:)','-r@i');
      if (status) {
         break;
      }
      _str line='';
      get_line(line);
      p_window_id=orig_view_id;
      if (pos('e',line)==1) {   //Command was a command line edit command
         parse line with . filename ;
      }else{
         parse line with '@cb _edit_form._openfn:'filename ;
      }
      filename=strip(filename);
      if (filename!='' && substr(filename,1,1)!='@') {
         _qo_retrieve_list._lbadd_item(filename);
      }
      p_window_id=command_view_id;
      up();
   }
   _delete_temp_view(command_view_id);
   p_window_id=orig_view_id;
   _qo_retrieve_list._lbremove_duplicates();
   _qo_retrieve_list._lbtop();
}


//#define OFN_READONLY                 0x00000001
//#define OFN_OVERWRITEPROMPT          0x00000002
//#define OFN_HIDEREADONLY             0x00000004
//#define OFN_NOCHANGEDIR              0x00000008
//#define OFN_SHOWHELP                 0x00000010
//#define OFN_NOVALIDATE               0x00000100
//#define OFN_ALLOWMULTISELECT         0x00000200
//#define OFN_EXTENSIONDIFFERENT       0x00000400
//#define OFN_PATHMUSTEXIST            0x00000800
//#define OFN_FILEMUSTEXIST            0x00001000
//#define OFN_CREATEPROMPT             0x00002000
//#define OFN_SHAREAWARE               0x00004000
//#define OFN_NOREADONLYRETURN         0x00008000
//#define OFN_NOTESTFILECREATE         0x00010000
//#define OFN_NONETWORKBUTTON          0x00020000
//#define OFN_NOLONGNAMES              0x00040000     // force no long names for 4.x modules
//#if(WINVER >= 0x0400)
//#define OFN_NODEREFERENCELINKS       0x00100000
//#define OFN_LONGNAMES                0x00200000     // force long names for 3.x modules
//#endif /* WINVER >= 0x0400 */

// NT open flags
// For NT specific functions:
//    ntOpenDialog,ntStdOpenDialog,ntSaveAsDialog

//#define OFN_NOCHANGEDIR              0x00000008
#define NTOFN_FILEMUSTEXIST  0x00001000
#define NTOFN_ALLOWMULTISELECT         0x00000200

// Arguments to DLL function
_str ntOpenDialog(int TemplateId,
                   int onwer_wid,
                   _str pszTitle,
                   _str pszInitialWildCards,
                   _str pszFileFilters,
                   int NTOFNFlags,
                   int VSOFNFlags,
                   _str pszDefaultExt,
                   _str pszInitialFilename,
                   _str pszInitialDirectory,
                  _str pszRetrieveName,
                  _str pszHelpName,
                  typeless* itemCallbackProc);


_str qtOpenDialog(int TemplateId,
                   int onwer_wid,
                   _str pszTitle,
                   _str pszInitialWildCards,
                   _str pszFileFilters,
                   int NTOFNFlags,
                   int VSOFNFlags,
                   _str pszDefaultExt,
                   _str pszInitialFilename,
                   _str pszInitialDirectory,
                  _str pszRetrieveName,
                  _str pszHelpName,
                  typeless* itemCallbackProc);


#if __MACOSX__
_str macSaveFileDialog(_str title, _str initialFilename, _str initialDirectory, int flags, int parentWID);
_str macOpenFileDialog(_str title, _str initialWildcards, _str fileExtensionFilters, _str initialDirectory, int flags, int parentWID);
#endif

#define VSNTOPEN        101
#define VSNTSTDOPEN     103
#define VSNTSTDSAVEAS   104
#define VSNTSAVEAS      105

/**
 * Runs either explorer open dialog or Slick-C&reg;
 * dialog for performing Open and Save As operations.
 * 
 * @param ShowArgs   This argument may be passed to the Slick-C&reg; show() function.
 *                   It must contain the -modal option.
 * @param pszTitle   Title of the dialog.  Defaults to "Open" if "" is given.
 * @param pszInitialWildCards
 *                   Optional wildcards to start with.  Must exists in
 *                   pszFileFilters.
 * @param pszFileFilters
 *                   Comma delimited list of captions and wildcards in the
 *                   Syntax shown below:
 *                   
 *                   <p>All Files (*.*),C/C++ Files (*.c;*.cpp;*.h),Java Files (*.java)
 * @param VSOFNFlags ofn_flags   May a combination of the following flag constants defined in "slick.sh":
 *                   <dl>
 *                   <dt>OFN_EDIT
 *                   <dd>Use the Edit form, rather than the
 *                   regular open dialog.  This adds several
 *                   options, such as the encoding, line format,
 *                   read-only, expand tabs, preload file, etc.
 *                   <dt>OFN_ALLOWMULTISELECT
 *                   <dd>Allow multiple file selection.  When set, caller must process a return value which may have spaces delimited filenames some of which are double quoted.
 *                   <dt>OFN_FILEMUSTEXIST
 *                   <dd>File(s) selected must exist.
 *                   <dt>OFN_CHANGEDIR
 *                   <dd>Don't restore original directory on exit
 *                   <dt>OFN_NOOVERWRITEPROMPT
 *                   <dd>Don't prompt user with overwrite existing dialog.
 *                   
 *                   <dt>OFN_SAVEAS<dd>File list box does not select files and user is prompted whether to overwrite an existing file.
 *                   <dt>OFN_SAVEAS_FORMAT<dd>Same as
 *                   OFN_SAVEAS, but with additional options
 *                   (line format, encoding, change dir option).
 *                   <dt>OFN_READONLY<dd>Show read only button.    See OFN_PREFIXFLAGS flag.
 *                   <dt>OFN_KEEPOLDFILE<dd>Show keep old name button.    See OFN_PREFIXFLAGS flag.
 *                   <dt>OFN_PREFIXFLAGS<dd>Prefix return value with -r if OFN_READONLY flag given and -n if OFN_KEEPOLDFILE flag given.
 *                   </dl>
 * @param pszDefaultExt
 *                   Usually '' is specified for this parameter.  This extension is
 *                   used if the file the user has selected does not have an extension.
 * @param pszInitialFilename
 *                   Filename that initially appears in the File Name combo box.
 * @param pszInitialDirectory
 *                   When not '', current directory is switched to this directory when
 *                   the dialog box is displayed and then restored on exit.
 * @param pszRetrieveName
 *                   Retrieve name used keep track of the previous typed file names
 *                   in the File Name combo box.  Typically this is the name of the
 *                   command or function that invoked the dialog box or the extension
 *                   on the files being opened.  Can also be
 *                   used to restore the last directory selected
 *                   by this function (if pszInitialDirectory is
 *                   blank).
 * @param pszHelpName
 *                   Specifies help displayed when F1 is pressed or the help button
 *                   is pressed.  If the help_item starts with a '?' character, the
 *                   characters that follow are displayed in a message box.  The
 *                   help string may also specify a unique keyword in the "vslick.hlp"
 *                   (UNIX: "uvslick.hlp") help file.  The unique keywords for the help
 *                   file are contained in the file "vslick.lst" (UNIX: "uvslick.lst").
 *                   In addition, you may specify a unique keyword for any windows help
 *                   file by specifying a string in the format:  keyword:
 *                   help_filename.
 * @param pfnItemCallback
 *                   Callback that will be called with the name (including
 *                   absolute path) of each item that will be displayed in
 *                   the open dialog.  This is used to prevent items from
 *                   being included in the list.  The callback function should
 *                   take one parameter that is a _str type.  This string
 *                   will be the absolute filename of the item in question.
 *                   The callback should return 1 if the item is to be included
 *                   in the open dialog and 0 if not.
 * 
 * @return Returns a string of one or more filenames.  Filenames with spaces will be
 *         in double quotes.  "" is returned if the user cancels the dialog.
 *  
 * @categories Forms
 */
_str _OpenDialog(_str ShowArgs,
                 _str pszTitle="",
                 _str pszInitialWildCards="",
                 _str pszFileFilters="",
                 int VSOFNFlags=0,
                 _str pszDefaultExt="",
                 _str pszInitialFilename="",
                 _str pszInitialDirectory="",
                 _str pszRetrieveName="",
                 _str pszHelpName="",
                 typeless* pfnItemCallback = null)
{
   // no filters?  use the ones the user set up
   if (pszFileFilters=='') {
      pszFileFilters=def_file_types;
   }

   typeless result = 0;

   // do we want to try and retrieve anything from the last time 
   // we called this function?
   if (pszRetrieveName != '') {
      // see if we can retrieve the last directory for this retrieve name
      if (pszInitialDirectory == '') {
         pszInitialDirectory = _retrieve_value(pszRetrieveName'.lastOpenDialogDir');
      }
   }

   if (((machine()=='WINDOWS' && ntSupportOpenDialog() && !_DataSetSupport()) ||
        (!_isMac()))) {

      typeless NTOFNFlags = 0;
      if (VSOFNFlags=='') VSOFNFlags=0;

      pszInitialFilename=stranslate(pszInitialFilename,'','"');
      options := strip(ShowArgs);

      orig_wid := p_window_id;
      parent := p_window_id;

      // go through the options one at a time
      option := '';
      uoption := '';
      for (;;) {
         parse options with option options;
         if (option=='') break;
         uoption = upcase(option);
         switch (uoption) {
         case '-MODAL':
            break;
         case '-MDI':
            parent=_mdi;
            break;
         case '-APP':
            parent=_app;
            break;
         case '-DESKTOP':
            parent=_desktop;
            break;
         case '-NEW':
         case '-NOCENTER':
         case '-XY':
         case '-REINIT':
         case '-HIDEONDEL':
         case '-HIDDEN':
         case '-NOHIDDEN':
            break;
         case '_EDIT_FORM':
         case '-EDIT-FORM':
         case '_UNIXEDIT_FORM':
         case '-UNIXEDIT-FORM':
            VSOFNFlags |= OFN_EDIT;
            break;
         }
      }

      // figure out which dialog we want
      typeless TemplateId = '';
      if (VSOFNFlags & OFN_EDIT) {
         TemplateId=VSNTOPEN;
      } else if (VSOFNFlags & OFN_SAVEAS) {
         if (VSOFNFlags & OFN_SAVEAS_FORMAT) {
            TemplateId=VSNTSAVEAS;
         } else {
            TemplateId=VSNTSTDSAVEAS;
         }
      } else {
         TemplateId=VSNTSTDOPEN;
      }


      _str old_mark;
      int mark_status=1;
      if (isEclipsePlugin() && _isEditorCtl() && select_active()) {
         mark_status=save_selection(old_mark);
      }

      if (machine()=='WINDOWS') {
         result=p_window_id.ntOpenDialog(TemplateId,
                       parent,
                       pszTitle,
                       pszInitialWildCards,
                       pszFileFilters,
                       NTOFNFlags,
                       VSOFNFlags,
                       pszDefaultExt,
                       pszInitialFilename,
                       pszInitialDirectory,
                       pszRetrieveName,
                       pszHelpName,
                       pfnItemCallback);
      } else {
         result=p_window_id.qtOpenDialog(TemplateId,
                       parent,
                       pszTitle,
                       pszInitialWildCards,
                       pszFileFilters,
                       NTOFNFlags,
                       VSOFNFlags,
                       pszDefaultExt,
                       pszInitialFilename,
                       pszInitialDirectory,
                       pszRetrieveName,
                       pszHelpName,
                       pfnItemCallback);
      }

      if (isEclipsePlugin() && mark_status == 0) {
         restore_selection(old_mark);
      }
      p_window_id=orig_wid;

   } else if(_isMac()){
#if __MACOSX__
      // Display Mac file dialog
      if(VSOFNFlags & OFN_SAVEAS) {
         result = p_window_id.macSaveFileDialog(pszTitle, pszInitialFilename, pszInitialDirectory, VSOFNFlags, p_window_id);
      } else {
         result = p_window_id.macOpenFileDialog(pszTitle, pszInitialWildCards, pszFileFilters, pszInitialDirectory, VSOFNFlags, p_window_id);
      }
#endif
   } else {
      result = show(ShowArgs,
                  arg(2),arg(3),arg(4),arg(5),arg(6),arg(7),arg(8),arg(9),arg(10),arg(11));
   }

   // save/retrieve the dir?
   if (pszRetrieveName != '') {
      // save the result to this retrieve name, so we can maybe use it again
      if (result != '') {
         temp := strip(result, 'B', '"');
         temp = _strip_filename(temp, 'N');

         _append_retrieve(0, temp, pszRetrieveName'.lastOpenDialogDir');
      }
   }

   return result;
}

/**
 * Determines if the given text matches an encoding option.
 * 
 * @param text             text to check
 * 
 * @return boolean         true if the text matches an encoding 
 *                         option, false otherwise
 */
boolean isEncoding(_str text)
{
   // Get the encoding list.
   OPENENCODINGTAB openEncodingTab[];
   _EncodingListInit(openEncodingTab);

   openEncodingTab[0].text = 'Default';
   for (i := 1; i < openEncodingTab._length(); ++i) {
      if (!(OEFLAG_REMOVE_FROM_OPEN & openEncodingTab[i].OEFlags)) {
         encText := '';
         if (openEncodingTab[i].option) {
            encText = strip(openEncodingTab[i].option);
         } else if (openEncodingTab[i].codePage >= 0) {
            encText = '+fcp'openEncodingTab[i].codePage;
         } 

         // do these match?
         if (encText == text) return true;
      }
   }

   return false;
}

defeventtab _open_style_prompt_form;

#define SMART_OPEN_PICTURE_INDEX             _ctl_smart_open.p_user
#define BROWSE_OPEN_PICTURE_INDEX            _ctl_browse.p_user

void _ctl_ok.on_create()
{
   SMART_OPEN_PICTURE_INDEX = 0;
   BROWSE_OPEN_PICTURE_INDEX = 0;

   switch (def_open_style) {
   case OPEN_BROWSE_FOR_FILES:
      _ctl_browse.p_value = 1;
      break;
   case OPEN_SMART_OPEN:
   default:
      _ctl_smart_open.p_value = 1;
      break;
   }
   adjustOpenPicture();
}

void _ctl_smart_open.lbutton_up()
{
   adjustOpenPicture();
}

void _ctl_browse.lbutton_up()
{
   adjustOpenPicture();
}

static void adjustOpenPicture() 
{
   // we vary the picture depending on what
   // the user has selected
   if (_ctl_browse.p_value) {

      if (!BROWSE_OPEN_PICTURE_INDEX) {
#if __UNIX__
         if(_isMac()) {
            BROWSE_OPEN_PICTURE_INDEX = _update_picture(-1, 'browseOpenMac.bmp');
         } else {
            BROWSE_OPEN_PICTURE_INDEX = _update_picture(-1, 'browseOpenUnix.bmp');
         }
#else
         BROWSE_OPEN_PICTURE_INDEX = _update_picture(-1, 'browseOpen.bmp');
#endif
      }
      _ctl_preview.p_picture = BROWSE_OPEN_PICTURE_INDEX;
   } else {
      if (!SMART_OPEN_PICTURE_INDEX) {
         SMART_OPEN_PICTURE_INDEX = _update_picture(-1, 'smartOpen.bmp');
      }
      _ctl_preview.p_picture = SMART_OPEN_PICTURE_INDEX;
   }
}

void _ctl_ok.lbutton_up()
{
   if (_ctl_browse.p_value) {
      def_open_style = OPEN_BROWSE_FOR_FILES;
   } else if (_ctl_smart_open.p_value) {
      def_open_style = OPEN_SMART_OPEN;
   }

   def_prompt_open_style = (_ctl_dont_prompt.p_value == 0);

   p_active_form._delete_window(IDOK);
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(IDCANCEL);
}
