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
#include "markers.sh"
#include "toolbar.sh"
#include "eclipse.sh"
#include "treeview.sh"
#require "se/lang/api/LanguageSettings.e"
#import "se/messages/MessageCollection.e"
#import "se/search/SearchResults.e"
#import "se/ui/toolwindow.e"
#import "adaptiveformatting.e"
#import "annotations.e"
#import "bookmark.e"
#import "cfg.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "cvsutil.e"
#import "debug.e"
#import "diff.e"
#import "dlgman.e"
#import "doscmds.e"
#import "eclipse.e"
#import "fileman.e"
#import "forall.e"
#import "get.e"
#import "gnucopts.e"
#import "guiopen.e"
#import "hex.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "menu.e"
#import "mouse.e"
#import "moveedge.e"
#import "mprompt.e"
#import "notifications.e"
#import "os2cmds.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "ptoolbar.e"
#import "put.e"
#import "recmacro.e"
#import "saveload.e"
#import "sellist.e"
#import "seltree.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tagrefs.e"
#import "tags.e"
#import "tbdeltasave.e"
#import "tbfind.e"
#import "tbsearch.e"
#import "toast.e"
#import "toolbar.e"
#import "util.e"
#import "vc.e"
#import "vchack.e"
#import "window.e"
#import "wkspace.e"
#import "xml.e"
#import "xmlwrap.e"
#endregion

using se.lang.api.LanguageSettings;
using namespace se.ui;

   static const FILECOUNTWARNING= 100;
   static const FILESOPENEDWARNING= 500;

static const CALLED_FROM_ECLIPSE= '-CFE';

no_code_swapping;  /* Just in case there is an I/O error reading */
                   /* the slick.sta file, this will ensure user */
                   /* safe exit and save of files.  */

int vsvOpenTempView(_str filename, int &tempWID);

_metadata enum ActAppFlags {
   ACTAPP_AUTORELOADON                 = 0x1,
   ACTAPP_SAVEALLONLOSTFOCUS           = 0x2,
   ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED = 0x4,
   ACTAPP_WARNONLYIFBUFFERMODIFIED     = 0x8,
   ACTAPP_AUTOREADONLY                 = 0x10,
   ACTAPP_DONT_RELOAD_ON_SWITCHBUF     = 0x20,
   ACTAPP_CURRENT_FILE_ONLY            = 0x40,
   ACTAPP_TEST_ALL_IF_CURRENT_MODIFIED = 0x80,
};

bool def_autoreload_compare_contents = true;
int def_autoreload_compare_contents_max_ksize = 2000;

int def_fast_auto_readonly     = 1;
bool def_batch_reload_files = true;
int def_autoreload_timeout_threshold     = 5000;
bool def_autoreload_timeout_notifications = true;


/////////////////////////////////////////////////////////////////////
// Used by batch_call_list() utility functions for grouping 
// together calls to handlers for call_list callbacks.
//
static const BATCH_CALL_LIST_THRESHOLD= 8;
static int gbatch_call_list_timer = -1;
static int gbatch_call_list_count:[];
static typeless gbatch_call_list_arg:[];
static int gcall_list_indexes:[][];
static int gReloadBufIdList[];
static int gReloadFileTimerID = -1;
 

/**
 *
 * Activates the buffer specified if it exists.  If <i>buf_name_arg</i> is not
 * given, user will be prompted for name of buffer to activate.
 *
 * @param buf_name_arg Name of buffer to activate.
 *
 * @return typeless Returns 0 if successful.  Common return codes include
 *         FILE_NOT_FOUND_RC (buffer <i>buf_name_arg</i> does not exist).
 *
 * @categories Buffer_Functions
 */
_command find_buffer(_str buf_name_arg='') name_info(BUFFER_ARG','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _str old_buffer_name=p_buf_name;
   buf_name := "";
   if ( buf_name_arg=='' ) {
      buf_name=p_buf_name;
   }
   _str buffer_name=prompt(buf_name_arg,'',make_buf_match(buf_name));
   name := "";
   path := "";
   parse buffer_name with name'<'path'>';
   if ( path!='' ) {
      buffer_name=path:+name;
   }
   attempt := absolute(strip(buffer_name));
   if ( attempt=='' ) {
      return(1);
   }
   int status=edit('+b '_maybe_quote_filename(attempt));
   if ( status ) {
      clear_message();
      status=edit('+b '_maybe_quote_filename(buffer_name));
   }
   return(status);
}
static int edit_count;
static _str gfirst_info;

_command void o,open(_str filename='') name_info(FILE_MAYBE_LIST_BINARIES_ARG','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI|VSARG2_NOEXIT_SCROLL) {
   filename=strip(filename,'B','"');
   if (_isUnix()) {
      if (_isMac()) {
         int status=_ShellExecute(absolute(filename));
         if ( status<0 ) {
            _message_box(get_message(status)' ':+ filename);
         }
      } else {
         _project_open_file(filename);
      }
   } else {
      int status=_ShellExecute(absolute(filename));
      if ( status<0 ) {
         _message_box(get_message(status)' ':+ filename);
      }
   }
}

/**
 * Command line version of the <b>gui_open</b> command.  Edits the file(s)
 * specified.  <i>filespec</i> may have wild card characters (*
 * or ?  for DOS).  edit Command options can be set globally or
 * per extension.  The edit mode of each file loaded is set
 * based on file extension.
 * <p>
 * The useful edit options are listed below.  For a complete list of options, see <b>load_files</b>.  A few options are only useful in SlickEdit macros.
 * <DL compact style="margin-left:20pt;">
 *   <DT>+#<i>command</i>  <DD>Execute <i>command</i> on active buffer.  For example, "s test.c +#100" places the cursor on line 100 of test.c.
 *   <DT>+ or -L[C|Z]   <DD>Turn on/off load entire file switch.  The optional C suffix count the number of lines in the file.  The Z suffix counts the number of lines in the file and truncates the file if an EOF character is found in the middle of the file.
 *   <DT>+ or -LF <DD>+LF turns off loading entire file and turns on fast line count.  This is the fastest way for SlickEdit to count the number of lines in a file.  -LF turns off fast line counting.
 *   <DT>+ or -LB <DD>Turns on/off binary loading.  All edit/save options which performed translations are ignored.   For example, tab expansion or tab compression options are ignored.  This allows "safe" editing of binary files even when edit/save file translation are on.
 *   <DT>+ or -LE <DD>Turns on/off show EOF option.  When on, EOF characters at the end of DOS files are not stripped.  This option is not supported when the +LZ option is given.
 *   <DT>+ or -LN <DD>Turns on/off show new line characters option.  When on, new line characters are initially visible.
 *   <DT>+ or -W     <DD>If the file or buffer is not already displayed in a window, insert a window for displaying the file or buffer.
 *   <DT>+ or -S     <DD>Turn on/off unmodified block swapping to spill file.
 *   <DT>+<i>nnn</i> <DD>Load binary file(s) that follow in record width <i>nnn</i>.
 *   <DT>+T [<i>buf_name</i>] <DD>Start a default operating system format temp buffer with name <i>buf_name</i>.
 *   <DT>+TU [<i>buf_name</i>]   <DD>Start a UNIX format temp buffer with name <i>buf_name</i>.
 *   <DT>+TM [<i>buf_name</i>]   <DD>Start a MACINTOSH format temp buffer with name <i>buf_name</i>.
 *   <DT>+TD [<i>buf_name</i>]   <DD>Start a DOS format temp buffer with name <i>buf_name</i>.
 *   <DT>+T<i>nnn </i>     <DD>Start a temp buffer where <i>nnn</i> is the decimal value of the character to be used as the line separator character.
 *   <dt>+FU [<i>buf_name</i>]</dt><dd>Use &lt;LF&gt; for the
 *   line separator character. Effects new files and existing 
 *   files.</dd> 
 *   <dt>+FM [<i>buf_name</i>]</dt><dd>Use &lt;CR&gt; for the line
 *   separator character. Effects new files and existing 
 *   files.</dd> 
 *   <dt>+FD [<i>buf_name</i>]</dt><dd>Use &lt;CR&gt;&lt;LF&gt; 
 *   for the line separator characters.  Effects new files and existing 
 *   files.</dd> 
 *   <dt>+F<i>nnn [<i>buf_name</i>]</i></dt><dd>SBCS/DBCS mode. 
 *   Use <i>nnn</i> as the decimal value for the line separator 
 *   character for new files. Effects new files and existing 
 *   files.</dd> 
 *   <dt>+FNU [<i>buf_name</i>]</dt><dd>Use &lt;LF&gt; for the 
 *   line separator character for new files. Does not affect line 
 *   ending interpretation for existing files.</dd> 
 *   <dt>+FNM [<i>buf_name</i>]</dt><dd>Use &lt;CR&gt; for the 
 *   line separator character. Does not affect line 
 *   ending interpretation for existing files.</dd> 
 *   <dt>+FND [<i>buf_name</i>]</dt><dd>Use &lt;CR&gt;&lt;LF&gt; 
 *   for the line separator characters for new files. Does not 
 *   affect line 
 *   ending interpretation for existing files.</dd> 
 *   <dt>+FN<i>nnn</i> [<i>buf_name</i>]</i></dt><dd>SBCS/DBCS
 *   mode.
 *   Use <i>nnn</i> as the decimal value for the line separator 
 *   character for new files. Does not affect line 
 *   ending interpretation for existing files.</dd> 
 *   <DT>+FTEXT   <DD>SBCS/DBCS mode.  Open SBCS/DBCS file.  This is the default mode when no mode (either SBCS/DBCS or Unicode) is specified.
 *   <DT>+FEBCDIC <DD>SBCS/DBCS mode.  Open EBCDIC file.
 *   <DT>+FUTF8   <DD>Unicode mode.  Open UTF-8 file with or without signature.
 *   <DT>+FUTF8S  <DD>Unicode mode.  Open UTF-8 file with or without signature.
 *   <DT>+FUTF16LE   <DD>Unicode mode.  Open UTF-16 little endian file with or without signature.
 *   <DT>+FUTF16LES  <DD>Unicode mode.  Open UTF-16 little endian file with or without signature.
 *   <DT>+FUTF16BE   <DD>Unicode mode.  Open UTF-16 little endian file with or without signature.
 *   <DT>+FUTF16BES  <DD>Unicode mode.  Open UTF-16 big endian file with or without signature.
 *   <DT>+FUTF32LE   <DD>Unicode mode.  Open UTF-32 little endian file with or without signature.
 *   <DT>+FUTF32LES  <DD>Unicode mode.  Open UTF-32 little endian file with or without signature.
 *   <DT>+FUTF32BE   <DD>Unicode mode.  Open UTF-32 little endian file with or without signature.
 *   <DT>+FUTF32BES  <DD>Unicode mode.  Open UTF-32 big endian file with or without signature.
 *   <DT>+FCP<i>ddd</i> <DD>Unicode mode.  Open code page file specified by <i>ddd</i>.  Under windows, this can be any valid code page or one of the VSCP_* constants defined in "slick.sh."
 *   <DT>+FACP <DD>Unicode mode.  Open active code page file.  Under windows, this can be any valid code page or one of the VSCP_* constants defined in "slick.sh."
 *   <DT>+FAUTOXML   <DD>Unicode mode.  Open XML file.  The encoding is determined based on the encoding specified by the "?xml" tag.  If the encoding is not specified by the "?xml", the file data is assumed to be UTF-8 data which is consistent with XML standards.  We applied some modifications to the standard XML encoding determination to allow for some user error.  If the file has a standard Unicode signature, the Unicode signature is assumed to be correct and the encoding defined by the "?xml" tag is ignored.
 *   <DT>+FAUTOUNICODE
 *       <DD>If the file has a standard Unicode signature, open the file as a Unicode file.  Otherwise, the file is loaded as SBCS/DBCS data.
 *   <DT>+FAUTOUNICODE2
 *       <DD>If the file has a standard Unicode signature or "looks" like a Unicode file, open the file as a Unicode file.  Otherwise, the file is loaded as SBCS/DBCS data.  This option is NOT full proof and may give incorrect results.
 *   <DT>+FAUTOEBCDIC
 *       <DD>If the file "looks" like an EBCDIC file, open the file as an EBCDIC file.  Otherwise, the file is loaded as SBCS/DBCS data.  This option is NOT full proof and may give incorrect results.  We have attempted to make this option support binary EBCDIC files.
 *   <DT>+FAUTOEBCDIC,UNICODE
 *       <DD>This option is a combination of "+FAUTOEBCDIC" and "+FAUTOUNICODE" options.
 *   <DT>+FAUTOEBCDIC,UNICODE2
 *       <DD>This option is a combination of "+FAUTOEBCDIC" and "+FAUTOUNICODE2" options.
 *   <DT>+ or -E  <DD>Turn on/off expand tabs to spaces switch.  Default is off.
 *   Tab increments of 8 are the default if not otherwise specified in the
 *   language setup for this file type.
 *   <DT>+ or -D  <DD>Turn on/off memory buffer name search.  Disk file search.
 *   <DT>+B <i>buf_name</i>   <DD>Look in memory only for buffer
 *   with name <i>buf_name</i>.  This MUST specify the
 *   exact contents of p_buf_name or p_DocumentName.  DO
 *   NOT put quotes around buffer names with spaces.  Use
 *   absolute() if necessary when searching for a fully
 *   qualified filename.
 *   <DT>+N or -N <DD>Network support switch.  When on, SlickEdit will detect when another application has the same file open and automatically select "Read only" mode.  This option requires an extra file handle open to the original file.
 * </DL>
 * The options above that only show a plus sign will also take a minus sign.
 * However their function will remain the same.
 * <p>
 * If you need to edit a file whose name contains space characters, place double
 * quotes around the name.
 *
 * @appliesTo Edit_Window
 * @return Returns 0 if successful.  Common return codes are FILE_NOT_FOUND_RC (occurs when wild card specification matches no files), NEW_FILE_RC (empty buffer created with filename specified because file did not exist), PATH_NOT_FOUND_RC, TOO_MANY_FILES_RC, and TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 * @example
 * <DL compact style="margin-left:20pt;">
 * <DT><b>e +l test</b><DD>  Loads all of the file test and frees the file handle.  If test is already loaded, its buffer is activated.
 *
 * <DT><b>e "this is.c"</b><DD> Edit a file whose name contains a space character.
 *
 * <DT><b>e +d test</b><DD>  Loads the file test from disk regardless if a copy already exists in memory.
 *
 * <DT><b>e +w test</b><DD>  (One file per window option) Display file test in its own window.  If file test is already displayed in a window, the window is activated.
 *
 * <DT><b>e +b test</b><DD>  Activates the buffer test if it exists.
 *
 * <DT><b>e +t test</b><DD>  Starts a new buffer called test.
 *
 * <DT><b>e +40 +d test</b><DD> Loads the binary file test from disk in 40 character line width.  File may be edited and saved.
 *
 * @see gui_open
 * @categories File_Functions
 */
_command e,edit(_str filenameArg='', typeless a2_flags='',  _str auto_create_firstw_arg='') name_info(FILE_MAYBE_LIST_BINARIES_ARG'*,'VSARG2_CMDLINE|VSARG2_REQUIRES_MDI|VSARG2_NOEXIT_SCROLL)
{
   /* if arg(4) is 1, We are doing a find-proc, or find-tag, so do not restore
      position*/
#if 1
   if (_executed_from_key_or_cmdline(name_name(last_index('','C'))) && !isinteger(a2_flags)) {
      // Want smart open if executed from command line, key press, menu, or toolbar button
      a2_flags=EDIT_DEFAULT_FLAGS|EDIT_SMARTOPEN;
      //say('default 'filenameArg);
   }
   if (!isinteger(a2_flags)) a2_flags=0;
   //say('a2_flags='a2_flags);
   int restorepos_flag=(a2_flags&EDIT_RESTOREPOS);
#else
   if (!isinteger(a2_flags)) a2_flags=0;

   key_or_cmdline=_executed_from_key_or_cmdline(name_name(last_index('','C')));
   key_or_cmdline=key_or_cmdline || (isnumber(a2_flags) && (a2_flags & VCF_AUTO_CHECKOUT));
   a2_flags|=key_or_cmdline;
   if (_executed_from_key_or_cmdline(name_name(last_index('','C')))) {
      restorepos_flag=EDIT_RESTOREPOS;
   } else if (isinteger(a2_flags)) {
      restorepos_flag=a2_flags & EDIT_RESTOREPOS;
   } else {
      restorepos_flag=0;
   }
#endif
   //if (a2_flags &(VCF_AUTO_CHECKOUT|EDIT_RESTOREPOS)) {
   //   say('yes 'filenameArg);
   //}

   edit_count=0;
   int NextWindow_wid=_mdi.p_child;
   p_window_id=_mdi._edit_window();
   old_buffer_name := "";
   typeless swold_pos='';
   swold_buf_id := 0;
   set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
   n := 'e';
   if ( def_prompt ) {
      n='edit';
   }
   last_index(find_index(n,COMMAND_TYPE),'C');

   _str filename=prompt(filenameArg);
   if (isVisualStudioPlugin()) {
      return vsvOpenTempView(filename, def_msvsp_temp_wid);
   }
   /*
       Don't do unix expansion here.  Otherwise, can't edit files like /tmp/a$b.

       Expansion has already been done by caller.

       gui_open command calls _unix_expansion() when necessary.

       command_execute calls _unix_expansion()
   */
   //if (def_unix_expansion && !file_exists(filename)) {
   //   filename = _unix_expansion(filename);
   //}

   mou_hour_glass(true);
   typeless status=edit2(filename,a2_flags|restorepos_flag,auto_create_firstw_arg);
   if (a2_flags & VCF_AUTO_CHECKOUT) {
      _mfXMLOutputIsActive=true;
   }
   mou_hour_glass(false);
   if (!gin_restore) {
      switch_buffer(old_buffer_name,'E',swold_pos,swold_buf_id);
   }
   if (!_no_child_windows() && !(a2_flags&EDIT_NOSETFOCUS)) {
      final_wid := p_window_id;
      _doNextWindowStyle(final_wid,NextWindow_wid,true);
      _set_focus();
   }
   /*
      By default, exit scroll mode so that common code which
      edits a file and goes to an location (goto tag,bookmark,error)
      will show the correct location.
   */
   if (_isEditorCtl() && !(a2_flags & EDIT_NOEXITSCROLL)) {
      _ExitScroll();
   }
   return(status);
}

/** 
 * @return  Return 'true' if we are in the process of opening or closing a batch of files?
 */
bool _in_batch_open_or_close_files()
{
   return (gin_restore || _in_project_close || _in_workspace_close || _in_close_all);
}

/*
  Function Name:set_first_window

  Parameters:
      filename- the name of the file about to be opened (needed so we know if
                    it has a window)
      auto_create_firstw_arg
                  - just arg(3) from edit2().  If this
                    value:!="0" and no mdi children exist,
                    a window is created.  Pass "" for
                    this argument.  Auto restore is the
                    only macro which passes 0 for this
                    argument.  It is likely that this option
                    will not be supported in future
                    versions of VSE.

  Description:
      checks if the filename has a window already and sets the first_window
      variable to whatever size the window should be.

  Returns:
      the proper value for the first_window variable in edit(2)

*/
static _str set_first_window(_str &filename,_str auto_create_firstw_arg,int one_file_per_window_explicitly_specified)
{
   /* only necessary for an older version, but if you get one of these,
      something is wrong anyway, so might as well return ''
   */
   if (filename=='' || (iswildcard(filename) && !file_exists(filename))) {
      return('');
   }

   if (filename=='+t') { //need to alter window for temp buffers
      filename='';
   }
   filename=_maybe_quote_filename(filename);
   first_window := "";
   //format 0|1 xpos ypos winwidth winheight
   if ( _default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      if (one_file_per_window_explicitly_specified==1 ||
          (one_file_per_window_explicitly_specified==0 && def_one_file!='')
         ) {
         return '';
      }
      // Get the current editor control of the current MDI window
      int wid=_MDICurrentChild(0);
      if ( !wid && auto_create_firstw_arg) {
         first_window='+i ';
      }
   } else {
      if ( _no_child_windows() && auto_create_firstw_arg) {
         first_window='+i ';
      }
   }
   return(first_window);

}
static _str appendEditBuffers(_str name) {
   _str match=buf_match(_strip_filename(name,'p'), 1, 'N');
   result := "";
   if( FILESEP=='\') {
      name=stranslate(name,'\\','\');
   }
   for (;;) {
      if (match=='') {
         return(result);
      }
      if (!endsWith(match,name,false,_fpos_case'&')) {
         match=buf_match(name, 0, 'N');
         continue;
      }
      if (result!='') result:+=' ';
      result:+=_maybe_quote_filename(match);
      match=buf_match(name, 0, 'N');
   }

}
_metadata enum_flags EditFlags {
   EDITFLAG_WORKSPACEFILES,
   EDITFLAG_BUFFERS,
   EDITFLAG_SAME_DIR_FILES,
   EDITFLAG_DECOMPRESS_GZ_FILES,
   EDITFLAG_DECOMPRESS_XZ_FILES,
   EDITFLAG_DECOMPRESS_BZ2_FILES,
};
static _str _listDiskFiles(_str filename) {
   int orig_view_id=_create_temp_view(auto list_view_id);
   if (orig_view_id=='') return(NOT_ENOUGH_MEMORY_RC);
   insert_file_list('-v +p '_maybe_quote_filename(filename));
   top();up();
   result := "";
   while(!down()) {
      auto line=_lbget_text();
      if (result:!='') {
         result:+=' ';
      }
      result :+= _maybe_quote_filename(line);
   }
   activate_window(orig_view_id);
   return(result);
}
EditFlags def_edit_flags=EDITFLAG_WORKSPACEFILES|EDITFLAG_BUFFERS|EDITFLAG_SAME_DIR_FILES|EDITFLAG_DECOMPRESS_GZ_FILES|EDITFLAG_DECOMPRESS_XZ_FILES;
bool def_check_line_endings=true;
_str def_check_line_endings_excludes='<Binary Files>';
int def_use_check_line_endings_ksize=8000;
/**
 * Function Name:edit2  -  open a file file for editing
 *
 * @param filename                the name of the file about to be opened
 *                                (needed so we know if it has a window)
 * @param a2_flags                bitset of EDIT_* flags
 * @param auto_create_firstw_arg  just arg(3) from edit().  If this
 *                                value:!="0" and no mdi children exist,
 *                                a window is created.  Pass "" for
 *                                this argument.  Auto restore is the
 *                                only macro which passes 0 for this
 *                                argument.  It is likely that this option
 *                                will not be supported in future
 *                                versions of VSE.
 *
 * @return 0 on success, error code otherwise
 */
static _str edit2(_str filename, int a2_flags, _str auto_create_firstw_arg='')
{
   options := "";
   if (_default_option(VSOPTION_SHOW_EXTRA_LINE_AFTER_LAST_NL)) {
      options='+Fshowextraline';
   }
   new_file_status := 0;
   first_info := "";
   first_window := "";
   filesOpenedPrompt := true;
   totalOpened := 0;
   useCache := true;
   includeHTTPHeader := false;
   allow_smartopen := (a2_flags & EDIT_SMARTOPEN) && (def_edit_flags &(EDITFLAG_WORKSPACEFILES|EDITFLAG_BUFFERS));
   typeless old_buf_flags=0;
   typeless old_buf_id=0;
   typeless list_view_id=0;
   typeless orig_view_id=0;
   expandWildcards := true;
   answer := 0;

   typeless status=0;
   typeless result=0;
   ExplicitWindowSizeGiven := false;
   line := def_one_file' 'filename;
   command := "";
   exFlags := "";
   param := "";
   name := "";
   info := "";
   encoding_set_by_user := false;
   one_file_per_window_explicitly_specified := 0; 
   for (;;) {
      if ( line=='' ) {
         break;
      }

//    line=strip(line,'L')
//    if substr(line,1,1)='-' then
//       line=substr(line,3)
//
//    endif
      _str word=parse_file(line);
//   if isinteger(word) then   /* Could have a number be a line number. */
//      word='-#'word
//   endif
      word_nq := strip(word,'B','"');

      if ( substr(word_nq,1,1)=='+' || substr(word_nq,1,1)=='-' ) {
         letter := upcase(substr(word_nq,2,1));
         if ( letter=='T' || letter=='V' || letter=='B' ) {
            if ( letter=='B' ) {
               param=_maybe_unquote_filename(line);
               line='';
               parse buf_match(param,1,'vhx') with . . old_buf_flags .;
            } else if (substr(line,1,1)=='+' || substr(line,1,2)=="\"+") {
               // if the next paramter is another option, then no filename
               param="";
            } else {
               param=parse_file(line);
            }
            old_buf_id=p_buf_id;
            block_was_read(0);

            first_window="";
            if (!ExplicitWindowSizeGiven) {
               //the +t tells first window to go ahead and resize the new window
               first_window=set_first_window('+t',auto_create_firstw_arg,one_file_per_window_explicitly_specified);
            }
            //status=window_edit(def_load_options " "first_window" "options" "word_nq " "param,a2_flags)
            status=window_edit(build_load_options('')" "options" "first_window" "word_nq " "param,a2_flags);
            first_window='';
            status=edit_status(status,new_file_status,first_info,a2_flags,'');
            if ( status ) {
               return(status);
            }
            if (letter=='T') {
               if (p_buf_id!=old_buf_id) {
                  p_buf_flags=VSBUFFLAG_PROMPT_REPLACE;
               }
               _SetEditorLanguage('',false,true);
               _InitNewFileContents();
               call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
               call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
            } else if (letter=='B') {
               if (isinteger(old_buf_flags) && (old_buf_flags& VSBUFFLAG_HIDDEN)) {
                  call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
                  call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
               }
            }
            if (command!='') {
               execute(command,'');
            }
         } else if ( letter=='*' ) {
            /* Execute the command on all files that file. */
            command=substr(word_nq,3);
         } else if ( letter=='^' ) {
            // Extract flag from guiopen. Flag has the following form:
            //    -^show_migrate_message
            exFlags=substr(word_nq,3);
         } else if ( letter=='#' ) {
            execute(substr(word_nq,3),'');   /* Execute the command now. */
         } else if (letter=='I') {
            options :+= " "word_nq;
            if (substr(word_nq,3,1)==':') {
               /* Add the y,width,height,state options. */
               y := "";
               width := "";
               height := "";
               state := "";
               parse line with y width height state line;
               options :+= ' 'y' 'width' 'height' 'state;
               ExplicitWindowSizeGiven=true;
            }
            //  One of +FXXXX options and not +fd +fu +fm and not +fNNNNN
         } else if (letter=='F' && length(word_nq)>3 && !(isinteger(substr(word_nq,3)))) {
            // Must be +fcpNNNN  +ftext +futf8 +futf16le etc.
            encoding_set_by_user=true;
            options :+= " "word_nq;
            //say('got here');
         } else if (strieq(substr(word_nq,2),'cache')) {
            useCache=substr(word_nq,1,1)=='+';
         } else if (strieq(substr(word_nq,2),'header')) {
            includeHTTPHeader=substr(word_nq,1,1)=='+';
         } else if (strieq(substr(word_nq,2),'wildcard')) {
            expandWildcards=substr(word_nq,1,1)=='+';
         } else if (strieq(substr(word_nq,2),'smartopen')) {
            // This is primarily for turning off smartopen and 
            // not turning it on.  Turning it on requires specify
            // what the def_edit_flags should be.
            allow_smartopen=substr(word_nq,1,1)=='+' && (def_edit_flags &(EDITFLAG_WORKSPACEFILES|EDITFLAG_BUFFERS));
         } else {
            oneFilePerWindowOption := substr(upcase(word_nq),1,2);
            if (oneFilePerWindowOption=='+W') {
               one_file_per_window_explicitly_specified=1;
            } else if (oneFilePerWindowOption=='-W') {
               one_file_per_window_explicitly_specified= -1;
            }
            options :+= " "word_nq;
         }
         continue;
      }
      fileCount := 0;
      if ( substr(word_nq,1,1)=='@' ) {   /* List of files? *///ch1
         _str old_gfirst_info=gfirst_info;
         gfirst_info='';
         status=for_list(word_nq,'e 'options' %l',0);//ch2
         if ( status ) {
            return(status);
         }
         if ( new_file_status && !(a2_flags & EDIT_NOWARNINGS)) {
            message(get_message(new_file_status));
         }
         first_info=gfirst_info;
         gfirst_info=old_gfirst_info;
      } else {
         list_view_id='';
         bool do_smartopen=allow_smartopen && !_isHTTPFile(word) && 
            !iswildcard(word_nq) &&  // AND not a wild card in name part
            // Need this for performance. On Unix, /abc/file looks absolute and
            // I'm not sure if this will be a problem.
            absolute(word_nq)!=word_nq;   
         if ( !do_smartopen &&
              expandWildcards && iswildcard(word) && 
              !_isHTTPFile(word) && (!_isUnix() || !file_exists(strip(word,'B','"')))) {
            orig_view_id=_create_temp_view(list_view_id);
            if (orig_view_id=='') return(NOT_ENOUGH_MEMORY_RC);
            status=insert_file_list('-v +p 'word);
            if (!status) {
               fileCount = p_Noflines;
               if (!fileCount) {
                  _delete_temp_view(list_view_id);
                  status=FILE_NOT_FOUND_RC;
                  message(get_message(status));
                  return status;
               }
               top();
               name=_lbget_text();
            }
            activate_window(orig_view_id);
            if ( status ) {
               _delete_temp_view(list_view_id);
               message(get_message(status));
               return(status);
            }
         } else {
            name=word_nq;
            if (do_smartopen) {
               foundFileList := "";
               if (file_exists(word_nq)) {
                  foundFileList= _maybe_quote_filename(absolute(word_nq));
               }
               foundFileList=_listDiskFiles(word_nq);
               if (def_edit_flags &EDITFLAG_BUFFERS) {
                  foundFileList :+= ' 'appendEditBuffers(word_nq);
               }
               if ((def_edit_flags &EDITFLAG_WORKSPACEFILES) && _workspace_filename!='') {
                  foundFileList :+= ' '_WorkspaceFindFile(word_nq, _workspace_filename, false, false, true, true);
               }
               foundFileList=strip(foundFileList);
               if (foundFileList!='') {
                  foundFileList = _prompt_for_duplicate_files(foundFileList);
                  if (foundFileList=='') {
                     return(COMMAND_CANCELLED_RC);
                  }
                  word=foundFileList;
                  name=word_nq=strip(word,'B','"');
               }
            }
         }
         // Warn the user about the number of files that are about to be opened.
         // This check is repeated for each path in the edit command.
         fileTypeText := "files";
         if (fileCount > FILECOUNTWARNING) {
            // Use the first name to determine the file type.
            name2 := strip(name,'B','"');
            if (_DataSetIsFile(name2)) {
               if (_DataSetIsMember(name2)) {
                  fileTypeText = "members";
               } else {
                  fileTypeText = "data sets";
               }
            }
            answer = _message_box(nls("About to open %s %s.\n\nContinue?",fileCount,fileTypeText),"",MB_YESNO);
            if (answer != IDYES) return(0);
         }
         for (;;) {
            if ( name=='' ) break;    /* This should not happen */
            if ((def_edit_flags & EDITFLAG_DECOMPRESS_GZ_FILES) && (_file_eq(get_extension(name),'gz') || _file_eq(get_extension(name),'Z'))) {
               name2:=_strip_filename(_strip_filename(name,'p'),'e');
               if (!_file_eq(get_extension(name2),'tar') && !_file_eq(get_extension(name2),'cpio')) {
                  name :+= FILESEP:+name2;
               }
            } else if ((def_edit_flags & EDITFLAG_DECOMPRESS_XZ_FILES) && _file_eq(get_extension(name),'xz')) {
               name2:=_strip_filename(_strip_filename(name,'p'),'e');
               if (!_file_eq(get_extension(name2),'tar') && !_file_eq(get_extension(name2),'cpio')) {
                  name :+= FILESEP:+name2;
               }
            } else if ((def_edit_flags & EDITFLAG_DECOMPRESS_BZ2_FILES) && _file_eq(get_extension(name),'bz2')) {
               name2:=_strip_filename(_strip_filename(name,'p'),'e');
               if (!_file_eq(get_extension(name2),'tar') && !_file_eq(get_extension(name2),'cpio')) {
                  name :+= FILESEP:+name2;
               }
            }
            if (filesOpenedPrompt && totalOpened > FILESOPENEDWARNING) {
               int remaining = fileCount - totalOpened;
               if (remaining > FILESOPENEDWARNING intdiv 4) {
                  answer = _message_box(nls("Opened %s %s. %s remaining.\n\nContinue and open the remaining %s?\nYou will not be prompted again.",totalOpened,fileTypeText,remaining,fileTypeText),"",MB_YESNO);
                  if (answer != IDYES) return(0);
                  filesOpenedPrompt = false;
               }
            }
            //block_was_read(0);
#if 0
            info=_get_file_info(_maybe_quote_filename(name));
            //messageNwait('info='info);
            if (def_one_file!='') {
               parse info with x y width height state .;
               if (info!=''&&p_window_state!='M' && state!='M') {
                  options :+= ' +i:'x' 'y' 'width' 'height' 'state;
               } else {
                  info='';
               }
            }
#else
            info='';
#endif
            block_was_read(0);

            first_window="";
            if (!ExplicitWindowSizeGiven) {
               //the +t tells first window to go ahead and resize the new window
               first_window=set_first_window('+t',auto_create_firstw_arg,one_file_per_window_explicitly_specified);
            }

            enqOption := "";
            // If the file to be opened is a data set, put an ENQ on it.
            // Prevent the file from being opened if the ENQ failed.
            // Also don't ENQ if data set is opened read-only.
            nameonly := strip(name,'B','"');
            if (_DataSetIsFile(nameonly)) {
               if (!pos("read_only_mode 1", command)) {
                  //say("edit2 ENQ filename="nameonly);
                  enqOption = "+ENQ ";
               }

               // If data set is migrated, let user know. We only do this
               // if the edit command was executed from the command line,
               // activated from a menu item, or from Open File dialog.
               idx := last_index('', 'W');
               showMigrateMsg := pos("show_migrate_message", exFlags);
               if ((idx || showMigrateMsg)) {
                  _message_box(name" is migrated.\n\nRecalling data set...");
               }
            }
            status = 0;
            isHTTPFile := false;
            if (!status) {
               //status=window_edit(build_load_options(name) " "first_window" "options" "_maybe_quote_filename(name),a2_flags)

               isHTTPFile=_isHTTPFile(name);
               if (!isHTTPFile) {
                  if (_isUnix()) {
                     samba_prefix := "";
                     if( substr(name,1,2)=='//' ) {
                        // Samba share
                        samba_prefix=substr(name,1,2);
                        name=substr(name,3);
                     } else {
                        // Probably have smb://server/share/<path> or plugin://pluginName/...
                        parse name with samba_prefix '://' name;
                        if (samba_prefix!='' && name!='' && _strip_filename(samba_prefix,'N')=='') {
                           samba_prefix :+= '://';
                        }
                     }
                     name=samba_prefix:+stranslate(name,FILESEP,FILESEP:+FILESEP);
                  } else {
                     unc_prefix := "";
                     if( substr(name,1,2)=='\\' ) {
                        // UNC path
                        unc_prefix=substr(name,1,2);
                        name=substr(name,3);
                        name=stranslate(name,FILESEP,FILESEP:+FILESEP);
                     } else {
                        // Probably have plugin:\\pluginName\...
                        name=translate(name,FILESEP,FILESEP2);
                        parse name with auto samba_prefix ':\\' name;
                        if (samba_prefix!='' && name!='' && _strip_filename(samba_prefix,'N')=='') {
                           prefix := upcase(samba_prefix);
                           if (_isWindows() && ((length(prefix)==1) && (prefix>='A' && prefix<='Z'))) {
                              // maybe drive letter prefix?
                              unc_prefix=samba_prefix':\';
                           } else {
                              unc_prefix=samba_prefix':\\';
                           }
                        } else {
                           name=samba_prefix;
                        }
                        name=stranslate(name,FILESEP,FILESEP:+FILESEP);
                     }
                     // Have to also handle paths with mixed up '\' and '/'
                     name=unc_prefix:+stranslate(name,FILESEP2,FILESEP2:+FILESEP2);
                  }
                  status=window_edit(enqOption:+build_load_options(name) " "/*TempNoLoad:+*/options" "first_window" "_maybe_quote_filename(name),a2_flags);
               } else {
                  SEURLFilename := "";
                  was_mapped := false;
                  name=translate(name,'/','\');
                  status=_mapxml_find_system_file(name,'',SEURLFilename,-1,was_mapped);
                  if (!status) {
                     int oldCache=_UrlSetCaching(useCache?1:2);
                     oldIncludeHeader := _UrlSetIncludeHeader(includeHTTPHeader);
                     status=window_edit(enqOption:+build_load_options(SEURLFilename) " "/*TempNoLoad:+*/options" "first_window" "_maybe_quote_filename(SEURLFilename),a2_flags);
                     _UrlSetCaching(oldCache);
                     _UrlSetIncludeHeader(oldIncludeHeader);

                  }
                  if (status) {
                     for (;;) {
                        get_window_id(auto orig_wid);
                        result=_mapxml_http_load_error(name,was_mapped,status,SEURLFilename,'');
                        if (result=='') {
                           activate_window(orig_wid);
                           break;
                        }
                        if (status) {
                           status=FILE_NOT_FOUND_RC;
                        } else {
                           status=window_edit(enqOption:+build_load_options(SEURLFilename) " "/*TempNoLoad:+*/options" "first_window" "_maybe_quote_filename(SEURLFilename),a2_flags);
                           if (!status) {
                              break;
                           }
                        }
                        //_message_box(nls("Error processing DTD '%s1' for file '%s2'.\n\n",_SlickEditToUrl(local_dtd_filename),buf_name):+get_message(status)"\n\n":+info);
                     }
                  }
               }
            }
            // If file opened failed, remove the previous ENQ if there is one.
            showErrorInMsgBox := pos("show_error_in_msgbox", exFlags);
            if (!(a2_flags&EDIT_NOSETFOCUS) && showErrorInMsgBox && status) {
               _message_box(nls("Can't edit %s.\n\n%s.",nameonly,get_message(status)));
            }

            //Put switchbuf here
            first_window='';
            edit_status(status,new_file_status,first_info, a2_flags, info);
            if ( status ) {
               if ( status!=NEW_FILE_RC ) { 
                  msg := "Error opening file: "get_message(status)": "name;
                  notifyUserOfWarning(ALERT_FILE_OPEN_ERROR, msg, absolute(name));
               } else {
                  /*
                  Support doesn't like this warning: Removed for now.
                  if (name != "") {
                     msg := "File not found, creating buffer: ":+absolute(name);
                     notifyUserOfWarning(ALERT_FILE_NEW_ERROR, msg, absolute(name));
                  } */
                  _InitNewFileContents();
               }
            }
            if (!status && isHTTPFile) {
               docname(name);
            }
            if (!status && !(a2_flags &EDIT_NOADDHIST)) {
               ++edit_count;
               if (edit_count <= def_max_filehist) {
                  _menu_add_filehist((isHTTPFile)?name:absolute(name));
               } else if (edit_count <= def_max_allfileshist) {
                  _menu_add_allfilehist((isHTTPFile)?name:absolute(name));
               }
            }
            block_was_read(1);read_ahead();
            if ( status && status!=NEW_FILE_RC ) {
               if (list_view_id!='') _delete_temp_view(list_view_id);
               return(status);
            }
            if (command!='') {
               execute(command,'');
            }
            if (list_view_id=='') {
               break;
            }
            get_window_id(orig_view_id);
            activate_window(list_view_id);
            if (down()) {
               activate_window(orig_view_id);
               break;
            }
            name=_lbget_text();
            activate_window(orig_view_id);
            totalOpened++;
         }
         if (list_view_id!='') _delete_temp_view(list_view_id);
      }
   }
   if ( first_info!='' && def_start_on_first ) {
      if (gfirst_info=='') {
         gfirst_info=first_info;
      }
      _suspend();
      if ( ! rc ) {
         typeless first_buf_id;
         typeless first_wid;
         parse first_info with first_buf_id first_wid;
         p_window_id=first_wid;
         load_files('+bi 'first_buf_id); /* Could cause run-time error. */
         /* If user quit file with -#quit */
         rc=1;_resume();
      }
      if ( rc!=1 ) {
         clear_message();
         if ( new_file_status && !(a2_flags & EDIT_NOWARNINGS)) {
            message(get_message(new_file_status));
         }
      }
   }
   return(new_file_status);
}

static void do_xml_auto_validate()
{
   if (!_haveXMLValidation()) {
      return;
   }
   // See if auto validation is on.  If it is on, then the user wants to
   // validate on open.  The default if no value is present is to auto validate
   if (!use_schema_for_color_coding(p_LangId)) {
      // Do not do validate on these because they do not have DTD
      // and are not valid.
      return;
   }
   if (_LanguageInheritsFrom('xml') && gXMLAutoValidateBehavior != VSXML_AUTOVALIDATE_BEHAVIOR_DISABLE) {
      if (LanguageSettings.getAutoValidateOnOpen(p_LangId) && p_buf_size<3000000 /* 3 megabytes */) {
         xmlparse(VSXML_VALIDATION_SCHEME_VALIDATE, 
                  gotoError:false, 
                  isAutoValidation:true);
      } else if (LanguageSettings.getAutoWellFormedNessOnOpen(p_LangId) && p_buf_size<3000000 /* 3 megabytes */) {
         xmlparse(VSXML_VALIDATION_SCHEME_WELLFORMEDNESS, 
                  gotoError:false, 
                  isAutoValidation:true);
      }
   }
}


static _str edit_status(int status,int &new_file_status,_str &first_info, int a2_flags, _str window_info)
{
   if ( first_info=='' ) {
      first_info=p_buf_id' 'p_window_id;
   }
   if ( status ) {
      if ( status!=NEW_FILE_RC ) { 
         return(status); 
      }
      new_file_status=NEW_FILE_RC;
   }
   if (!(a2_flags & EDIT_NOUNICONIZE)) {
      // Now make sure the 
      int mdi_wid=_MDIFromChild(p_window_id);
      if (!mdi_wid) {
         mdi_wid=_mdi;
      }
      if (mdi_wid.p_window_state=='I') {
         mdi_wid.p_window_state='N';
      }
      if (p_window_state=='I') {
         p_window_state='N';
      }
   }
   displayTranslationError := false;
   if (p_encoding_translation_error) {
      if ((p_readonly_mode && block_was_read()>1) ||
          (p_LangId == FUNDAMENTAL_LANG_ID && block_was_read())) {
         displayTranslationError=true;
      }
   }
   // IF in read only mode AND we just loaded this file
   typeless x, y, width, height, state, icon_x, icon_y;
   if ( p_readonly_mode && block_was_read()>1) {
      int read_only_status=block_was_read();
      command := "read-only-mode";
      if (!(a2_flags & EDIT_NOWARNINGS)) {
         if ( read_only_status==3 ) {
            message(nls('Warning:  You have read only access to this file'));
         } else {
            message(nls('Warning:  Another process has read access'));
         }
      }
      _SetEditorLanguage('',false,true);
      do_xml_auto_validate();
      call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
      call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
      if (a2_flags & EDIT_RESTOREPOS) {
         _restore_filepos(p_buf_name);
         parse window_info with  x y width height state icon_x icon_y;
         if (window_info!='' && def_one_file!='') {
            if (state=='I') {
               p_window_state='N';
            } else {
               p_window_state=state;
            }
            _move_window(x,y,width,height,'N'/*,icon_x,icon_y*/);
         }
      }
      if ( index_callable(find_index(command,COMMAND_TYPE)) ) {
         if ( read_only_status==3 ) {
            execute(command,"");
         } else {
            execute(command' 1',"");
         }
      }
   } else if ( p_LangId == '' ) {
      // IF we just loaded this file OR a new file was created
      if (block_was_read() || status==NEW_FILE_RC) {
         _SetEditorLanguage('',false,true);
         if (status != NEW_FILE_RC) {
            // 7/5/2006 - RB
            // Found this problem while opening an XML file over FTP with auto-validation turned on.
            // Calling do_xml_auto_validate will cause the Output tool window to
            // auto show if it was auto hidden, which would change the active window
            // away from the current MDI child, which would cause all the property
            // accesses (p_buf_name, p_buf_id, etc.) to throw a stack. For this
            // reason we save and restore the active window.
            old_wid := p_window_id;
            do_xml_auto_validate();
            p_window_id=old_wid;
         }
         call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
         call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
         if (!status && (a2_flags & EDIT_RESTOREPOS)) {
            _restore_filepos(p_buf_name);
            parse window_info with x y width height state icon_x icon_y;
            if (window_info!='' && def_one_file!='') {
               if (state=='I') {
                  p_window_state='N';
               } else {
                  p_window_state=state;
               }
               _move_window(x,y,width,height,'N'/*,icon_x,icon_y*/);
            }
         }
         _str ext=get_extension(p_buf_name,true);
         if((a2_flags & EDIT_CHECK_LINE_ENDINGS) && def_check_line_endings && p_buf_size<def_use_check_line_endings_ksize*1024 &&
            // Exclude mode names an extensions specified
            !pos(';<'p_mode_name' Files>;', ';'def_check_line_endings_excludes';') &&  
            !_FileRegexMatchExcludePath(def_check_line_endings_excludes,p_buf_name)
            //!pos(';*'ext';', ';'def_check_line_endings_excludes';')
            ) {
             check_line_endings('',true);
         }
      }
   }
   if (displayTranslationError) {
      _message_box("Warning: Not all characters could be translated to Unicode. Untranslatable characters have been replaced by '?' characters. Make sure you specified the correct encoding.\n\nSaving this file will NOT restore the file's original content.");
   }
   return(0);
}
/**
 * Saves current buffer under a name you specify.  If the -n option is not
 * given, the buffer name is changed to the new name.  The -r option
 * allows you to save to a file which is read only and is only supported by
 * the UNIX version.
 *
 * @return Returns 0 if successful.  Common return codes are
 * INVALID_OPTION_RC, ACCESS_DENIED_RC,
 * ERROR_OPENING_FILE_RC, ERROR_WRITING_FILE_RC,
 * INSUFFICIENT_DISK_SPACE_RC, DRIVE_NOT_READY_RC,
 * and PATH_NOT_FOUND_RC.  On error, message box is displayed.
 *
 * @param cmdline is a string in the format: [-n] [-r] <i>filename</i>
 *
 * @see gui_save_as
 * @see save
 * @see name
 *
 * @appliesTo Edit_Window
 *
 * @categories File_Functions
 *
 */
_command int save_as,sa(_str cmdline='',int sv_flags= -1) name_info(FILENEW_ARG','VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   bCalledFromEclipse := false;
   cfe_option := "";

   _str cfe_cmd = cmdline;
   parse cfe_cmd with cfe_cmd .;
   if (pos(CALLED_FROM_ECLIPSE, cfe_cmd)) {
      index := pos(CALLED_FROM_ECLIPSE, cmdline);
      cmdline = substr(cmdline, 1, index-1):+ substr(cmdline, index+length(CALLED_FROM_ECLIPSE)+1);
      bCalledFromEclipse = true;
      cfe_option='-CFE';
   }
   // If were started as part of the eclipse plug-in then
   // we need to save as the "Eclipse" way
   //
   if (!bCalledFromEclipse && isEclipsePlugin()) {
      if(_eclipse_save_as(p_window_id, cmdline, sv_flags) == 0){
         p_modify = false;
         return (0);
      }
   }

   _macro_delete_line();
   typeless status=0;
   _str line=cmdline;
   if (line=='') {
      status=get_string(line,nls('Save as:')' ','-.save-as',p_buf_name);
      if ( status || line=='' ) {
         return COMMAND_CANCELLED_RC;
      }
   }
   _macro_call('save_as',line);

   preserve_old_name := 0;
   read_only := "";
   save_options := "";
   option := "";
   ch := "";
   temp := "";
   for (temp=line;;) {
      option=parse_next_option(temp,false);
      option=upcase(option);
      if (option=='-N') {
         parse_next_option(line);
         preserve_old_name=1;
         save_options :+= '+N ';
      } else if (option=='-R') {
         parse_next_option(line);
         read_only='-R ';
      } else {
         ch=substr(option,1,1);
         if (ch=='-' || ch=='+') {
            parse_next_option(line);
            save_options :+= option' ';
         } else {
            break;
         }
      }
   }

   _str orig_line = line;
   line=strip(line,'B','"');
   if (preserve_old_name || _process_info('b') || _file_eq(absolute(p_buf_name,null,true),absolute(line,null,true))) {
      // Preserve old name
      status=save(read_only:+save_options:+cfe_option:+orig_line,sv_flags);
   } else {
      if (_isGrepBuffer(p_buf_name)) {
         if (_duplicate_grep_buffer()) {
            _message_box(nls("Unable to save search result buffer."));
            return(1);
         }
      }
      if (buf_match(absolute(line),1,'X')!='') {
         _message_box(nls("You already have a buffer with name '%s'.",line));
         return(1);
      }
#if 1
      /*
         This code path allows changing file formats to
         update the EOL characters.
      */
      _str filename=line;
      if (isdirectory(filename)) {
         _maybe_append_filesep(filename);
         filename :+= _strip_filename(p_buf_name,'p');
      }
      _str old_buf_name=p_buf_name;
      //old_modify=p_modify;
      //old_buf_flags=p_buf_flags;
      old_readonly_mode := p_readonly_mode;
      status = name_file(filename);
      if (status) return(status);
      // Defer forcing buffer to RW mode after the buffer rename.
      p_readonly_mode=false;
      // Force recalculation of adaptive formatting settings.
      p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(p_LangId);
      // In v13, Setting the editor language gets ignored unless p_LangId=''.
      p_LangId='';
      _SetEditorLanguage('',false,false,false,false,p_hex_mode!=0 && p_hex_mode_reload_encoding);
      status=save(read_only:+save_options:+cfe_option,sv_flags);
      if ( status ) {
         p_readonly_mode=old_readonly_mode;
         //call_list('_buffer_renamed_',p_buf_id,p_buf_name,old_buf_name,old_buf_flags);
         int status2 = name_file(old_buf_name,old_buf_name!='');
         if (status2) return(status2);
         // Force recalculation of adaptive formatting settings.
         p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(p_LangId);
         // In v13, setting the editor language gets ignored unless p_LangId=''.
         p_LangId='';
         _SetEditorLanguage('',false,false,false,false,p_hex_mode!=0 && p_hex_mode_reload_encoding);
         //p_buf_name=old_buf_name;
         //p_modify=old_modify;
         //p_buf_flags=old_buf_flags;
      } else {
         /* Since language determination reads data from disk to determine what to do, determine
            the language again.
         */
         p_LangId='';
         _SetEditorLanguage('',false,false,false,false,p_hex_mode!=0 && p_hex_mode_reload_encoding);
         p_readonly_mode= (read_only!='');
         p_readonly_set_by_user=false;
      }
#else
      filename=line;
      status=save(read_only:+save_options:+cfe_option' 'filename,sv_flags);
      if (!status && !file_eq(p_buf_name,absolute(strip(filename,'','"')))) {
         name(line);
         p_buf_flags&= ~VSBUFFLAG_PROMPT_REPLACE;
         p_modify=0;
         if (read_only=='') {
            p_readonly_mode=0;
            p_readonly_set_by_user=false;
         }
      }

#endif
   }
   //if (!status) {
   //   _menu_add_filehist(p_buf_name);
   //}
   //cursor_data();
   return(status);
}


/**
 * Returns non-zero value if the command was executed from a key or the
 * command line.  This function should only be called from a command
 * (<b>_command</b>) function.
 * @categories Command_Line_Functions, Keyboard_Functions
 */
bool _executed_from_key_or_cmdline(_str cmdname)
{
   typeless executed_from_key=name_name(last_index()):==translate(cmdname,'-','_');
   typeless executed_from_cmdline=last_index('','w');
   return(executed_from_key || executed_from_cmdline);
}


int _OnUpdate_revert(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || _no_child_windows() ) {
      return MF_GRAYED;
   }
   if (!target_wid.p_modify) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}

/**
 * Revert the current buffer to the contents of the latest
 * version on disk.
 *
 * @param quiet  just reload the file, do not prompt
 *
 * @see edit
 * @appliesTo Edit_Window
 * @categories File_Functions
 */
_command void revert(_str quiet="") name_info(','VSARG2_ICON|VSARG2_NOEXIT_SCROLL|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state() || !_isEditorCtl()) {
      return;
   }

   if (!file_exists(p_buf_name)) {
      message('Canceled revert, "'p_buf_name'" does not exist.');
      return;
   }

   if (quiet!=1 && _message_box("Discard all changes to \"":+p_buf_name"\" ?", "SlickEdit", MB_YESNOCANCEL) != IDYES) {
      return;
   }


   _str bfiledate = _file_date(p_buf_name,'B');
   wid := p_window_id;
   _ReloadCurFile(p_window_id,bfiledate,false,true,null,false);

   // 12156 - sg
   // make sure this is the same file - sometimes things can get 
   // tricky if the user has been deleting things
   if (wid == p_window_id) {
      orig_col := p_col;
      _end_line();
      if (p_col > orig_col) {
         p_col = orig_col;
      }
   }
}

int _OnUpdate_revert_or_refresh(CMDUI &cmdui,int target_wid,_str command)
{
   caption := '';
   enabled := MF_ENABLED;
   helpMsg := '';
   if (_no_child_windows()) {
      enabled = MF_GRAYED; 
   } else {
      if (target_wid && !target_wid.p_modify) {
         bfiledate := _file_date(p_buf_name, 'B');
         if (p_file_date :== bfiledate || _FileIsRemote(p_buf_name)){
            enabled = MF_GRAYED;
         }
   
         caption = "&Refresh";
         helpMsg = "Refreshes the file using the current disk version.";
      } else {
         caption = "&Revert";
         helpMsg = "Reverts the file back to the disk version.";
      }
   }

   // if we are disabled, make sure and put both actions here so the user will know where it was
   if (enabled == MF_GRAYED) {
      caption = "&Refresh/Revert";
      helpMsg = "Refreshes or reverts the current file based on its modified status.";
   }


   status := _menu_set_state(cmdui.menu_handle,
                              cmdui.menu_pos, MF_ENABLED, 'p',
                              caption,
                              command,'','',
                              helpMsg);

   return enabled;
}

static int def_actapp_stack[];
static int gorig_def_actapp;
/*
  If temporarily modify def_actapp and calling/in
  an _ReloacCurFile function, must push/pop 
  def_actapp. Otherwise, the wrong value will
  get saved in user.cfg.xml.
*/
void _push_def_actapp(int actapp) {
   len := def_actapp_stack._length();
   if (!len) {
      gorig_def_actapp=def_actapp;
   }
   def_actapp_stack[len]=def_actapp;
   def_actapp=actapp;
}
void _pop_def_actapp() {
   len := def_actapp_stack._length();
   if (len) {
      def_actapp=def_actapp_stack[len-1];
      def_actapp_stack._deleteel(len-1);
      return;
   }
}

bool _MaybeUpdateUserOptions(_str filename) {
   if (!pos(VSCFGFILE_USER,filename,1,_fpos_case)) {
      return false;
   }
   name:=_strip_filename(filename,'P');
   path:=_strip_filename(filename,'N');
   if (_file_eq(name,VSCFGFILE_USER) && _file_eq(path,_ConfigPath())) {
      if (editor_name('s')=='') {
         return false;
      }
      save_def_vars := (_config_modify & CFGMODIFY_DEFVAR)!=0;
      if (save_def_vars) {
         int old_def_actapp=def_actapp;
         if (def_actapp_stack._length()) {
            def_actapp=gorig_def_actapp;
         }
         //say('def_actapp='def_actapp);
         _def_vars_update_profile();
         def_actapp=old_def_actapp;
      }
      if (_plugin_get_user_options_modify()) {
         int handle=_plugin_get_user_options();
         if (handle>=0) {
            //user_cfg_xml_saved=0;
            _xmlcfg_apply_profile_style(handle,_xmlcfg_get_document_element(handle));
            /* Save xml in UNIX eol format for more consistent cross platform EOL processing. This only makes
               a difference if new-lines are in PCDATA or attribute values.
            */
            status_user_cfg_xml:=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
            _xmlcfg_close(handle);
            if (!status_user_cfg_xml) {
               _plugin_set_user_options_modify(false);
               _config_modify&=~CFGMODIFY_DEFVAR;
               return true;
            }
         }
      }
   }
   return false;
}
/**
 * Reverts or refreshes the current buffer to the contents of the latest version
 * on disk.  If the buffer has been modified, then it is 
 * reverted. If the file has not been modified, but has an 
 * earlier time stamp than the file on disk, then the file is 
 * refreshed. 
 *
 * @see edit
 * @appliesTo Edit_Window
 * @categories File_Functions
 */
_command void revert_or_refresh() name_info(',')
{
   if (command_state() || !_isEditorCtl()) {
      return;
   }

   // determine if the current file is modified - if so, we revert, otherwise we refresh
   if (p_modify) {
      revert();
   } else {
      _MaybeUpdateUserOptions(p_buf_name);
      bfiledate := _file_date(p_buf_name, 'B');
      if (p_file_date :!= bfiledate && !_FileIsRemote(p_buf_name));

      temp_wid := 0;
      orig_wid := 0;
      status := _open_temp_view('', temp_wid, orig_wid, "+bi "p_buf_id);
      if (status == 0) {
         _ReloadCurFile(temp_wid, bfiledate, false, true, null, false, auto reloadStatus=0);
         if ( !reloadStatus && useWholeFileCompare() && _haveBackupHistory() && DSBackupVersionExists(p_buf_name) ) {
            stauts := DS_CreateDelta(p_buf_name);
            if ( !status ) {
               DSSetVersionComment(p_buf_name, -1, "Created by File > Reload."); 
            }
            temp_wid.p_file_date = (long)bfiledate;
            temp_wid.p_file_size = _file_size(p_buf_name);
         }

         _delete_temp_view(temp_wid);
         if (_iswindow_valid(orig_wid)) {
            activate_window(orig_wid);
         }
      }
   }
}

extern int _RecycleFile(_str filePath);

/**
 * Uses a platform-specific method to send a file to the Trash 
 * or Recycle Bin. 
 *  
 * If <i>def_delete_uses_recycle_bin</i> is FALSE (0), or a 
 * trash command is not available on the current platform, then 
 * {@link delete_file} is used. 
 *  
 * @param filePath Full path to file to be deleted 
 * @return Returns 0 if successful. Error codes similar to those
 *         returned by <i>delete_file</i>.
 * @see delete_file 
 * @categories File_Functions 
 */ 
int recycle_file(_str filePath)
{
    if (def_delete_uses_recycle_bin > 0) {
       if (_isUnix()) {
          if (!_isMac()) {
             commandLine := "";
             if(def_trash_command != '') {

                // Replace the %f placeholder with the file path, in quotes if needed
                commandLine = stranslate(def_trash_command, _maybe_quote_filename(filePath), "%f");

             } else {
                // Code below is in _RecycleFile()
   #if 0
                session_name := get_xdesktop_session_name();
                if (session_name == 'gnome') {

                    // Gnome: Look for the gvfs-trash command
                    _str gvsPath = path_search('gvfs-trash');
                    if (gvsPath != '') {
                        // >gvfs-trash /path/to/file.ext
                        def_trash_command = gvsPath :+ " %f";
                        commandLine = gvsPath :+ ' ' :+ _maybe_quote_filename(filePath);
                    }

                } else if (session_name == 'kde') {

                    // KDE: Look for the kfmclient utility
                    _str kfmcPath = path_search('kfmclient');
                    if (kfmcPath != '') {
                        // >kfmclient move /path/to/file.ext trash:/
                        def_trash_command = kfmcPath :+ " move %f trash:/";
                        commandLine = kfmcPath :+ " move " :+ _maybe_quote_filename(filePath) :+ " trash:/";
                    }
                }

                if (commandLine == '') {

                    // Otherwise: Look for the trash-cli command (trash, or trash-put)
                    _str trashPutPath = path_search('trash-put');
                    if(trashPutPath == '') {
                       trashPutPath = path_search('trash');
                    }
                    if (trashPutPath != '') {
                        // >trash-put /path/to/file.ext
                        def_trash_command = trashPutPath :+ " %f";
                        commandLine = trashPutPath :+ ' ' :+ _maybe_quote_filename(filePath);
                    }
                }
   #endif
             }

             if (commandLine != '') {
                 return shell(commandLine, 'NA');
             }
          }
       }
       return _RecycleFile(filePath);
    }
    return delete_file(filePath);
}

bool _get_filetype_dir_parts(_str filename,_str &dir, _str &name="") {
   ft:=_FileQType(filename);
   switch (ft) {
   case VSFILETYPE_JAR_FILE:
   case VSFILETYPE_GZIP_FILE:
   case VSFILETYPE_TAR_FILE:
       break;
   default:
      return false;
   }
   _str path=filename;
   for (;;) {
      path=_strip_filename(path,'N');
      if (path=='') {
         return false;
      }
      if (_last_char(path):== _FILESEP || _last_char(path):==_FILESEP2 ) {
         path=substr(path,1,length(path)-1);
         path=_strip_filename(path,'N');
         if (_last_char(path):== _FILESEP || _last_char(path):==_FILESEP2 ) {
            path=substr(path,1,length(path)-1);
            ft=_FileQType(path);
            switch (ft) {
            case VSFILETYPE_JAR_FILE:
            case VSFILETYPE_GZIP_FILE:
            case VSFILETYPE_TAR_FILE:
                break;
            default:
               dir=path:+_FILESEP;
               name=_strip_filename(filename,'P');
               return true;
            }
         } else {
            // We are lost.
            return false;
         }
      } else {
         // We are lost.
         return false;
      }
   }
}

/**
 * Writes contents of the active buffer to the file name specified.  If no
 * file name is specified, the current buffer is used.  The File Options
 * set default options for the save command.
 *
 * @return Returns 0 if successful.  Common return codes are:
 * INVALID_OPTION_RC, ACCESS_DENIED_RC,
 * ERROR_OPENING_FILE_RC, ERROR_WRITING_FILE_RC,
 * PATH_NOT_FOUND_RC, INSUFFICIENT_DISK_SPACE_RC, and
 * DRIVE_NOT_READY_RC.  On error, message is displayed.
 *
 * @param command_line may contain an output filename and any of the
 * following switches:
 *
 * <dl>
 * <dt>+ or -O</dt><dd>Overwrite destination switch (no backup).  Useful
 * for writing a file to a device such as the printer.
 * Default is off.</dd>
 *
 * <dt>+ or -R</dt><dd>UNIX only.  Save to read only file and keep file
 * read only.</dd>
 *
 * <dt>+ or -Z</dt><dd>Add end of file marker Ctrl+Z.  Default is on.</dd>
 *
 * <dt>+ or -T</dt><dd>Compress saved file with tabs.  Quoted strings are
 * left unchanged.  Always uses tab increments of 8.
 * Default is off.</dd>
 *
 * <dt>+ or -E</dt><dd>Turn on/off expand tabs to spaces switch.  Default
 * is off.</dd>
 *
 * <dt>+ or -B</dt><dd>Binary.  Save file without carriage return, line
 * feeds, or end of file marker.  Defaults to off.</dd>
 *
 * <dt>+ or -A</dt><dd>Convert destination filename to absolute.  Default
 * is on.  This option is used to write files to device
 * names such as PRN.  For example, "save +o -a prn"
 * sends the current buffer non-laser printer.</dd>
 *
 * <dt>+DB, -DB, +D,-D,+DK,-DK</dt><dd>
 *    These options specify the backup style.  The default
 * backup style is +D.  The backup styles are:</dd>
 *
 * <dl>
 * <dt>+DB, -DB</dt><dd>Write backup files into the same directory as the
 * destination file but change extension to ".bak".</dd>
 *
 * <dt>+D</dt><dd>When on, backup files are placed in a single
 * directory.  The default backup directory is
 * "\vslick\backup\" (UNIX:
 * "$HOME/.vslick/backup") . You may define an
 * alternate backup directory by defining an
 * environment variable called VSLICKBACKUP.
 * The VSLICKBACKUP environment variable may
 * contain a drive specifier. The backup file gets the
 * same name part as the destination file.  For
 * example, given the destination file
 * "c:\project\test.c" (UNIX: "/project/test.c") , the
 * backup  file will be "c:\vslick\backup\test.c"
 * (UNIX: "$HOME/.vslick/backup/test.c").<br><br>
 *
 * Non-UNIX platforms: For a network, you may
 * need to create the backup directory with appropriate
 * access rights manually before saving a file.</dd>
 *
 * <dt>-D</dt><dd>When on, backup file directories are derived from
 * concatenating a backup directory with the path and
 * name of the destination file.  The default backup
 * directory is "\vslick\backup\" (UNIX:
 * "$HOME/.vslick").  You may define an alternate
 * backup directory by defining an environment
 * variable called VSLICKBACKUP.  The
 * VSLICKBACKUP environment variable may
 * contain a drive specifier.  For example, given the
 * destination file "c:\project\test.c", the backup file
 * will be "c:\vslick\backup\project\test.c" (UNIX:
 * "$HOME/.vslick/backup/project/test.c").<br><br>
 *
 * Non-UNIX platforms: For a network, you may
 * need to create the backup directory with appropriate
 * access rights manually before saving a file.</dd>
 *
 * <dt>+DK,-DK</dt><dd>When on, backup files are placed in a directory off
 * the same directory as the destination file.  For
 * example, given the destination file
 * "c:\project\test.c" (UNIX: "$HOME/.vslick"), the
 * backup file will be "c:\project\backup\test.c"
 * (UNIX: "/project/backup/test.c").  This option
 * works well on networks.</dd>
 *
 * <dt>+DD</dt><dd>When on, back up files using the backup history system.
 * Delta backup files are derived from concatenating a backup directory with
 * the path and same of the destination file and the .vsdelta extension.
 * The default backup directory is the "vsdelta" subdirectory of your
 * configuration directory.</dd>
 * </dl>
 * </dl>
 *
 * <p>The internal variable <b>p_modify</b> is turned off if the output
 * filename is the same as the current file name.  If no filename is
 * specified the current buffer name is used.</p>
 *
 * <p>Command line example:</p>
 *
 * <dl>
 * <dt>save +O</dt><dd>Save this file but don't create a backup this one
 * time</dd>
 *
 * <dt>save +O -A +E PRN</dt><dd>Save a tabbed file to the
 * printer</dd>
 * </dl>
 *
 * @see file
 * @see print
 * @see save_as
 *
 * @appliesTo Edit_Window
 *
 * @categories File_Functions
 *
 */
_command int save(_str cmdline="",int flags= -1) name_info(FILENEW_ARG','VSARG2_ICON|VSARG2_NOEXIT_SCROLL|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   bCalledFromEclipse := false;

   if (!p_HasBuffer) {
      p_window_id=_mdi.p_child;
   }
   if (!p_mdi_child && !p_IsTempEditor && !p_AllowSave) {
      _beep();
      return(1);
   }
   if (!isinteger(flags) || flags== -1) flags=SV_RETRYSAVE;
   preplace := !(flags&SV_OVERWRITE) && def_preplace;
   options := "";
   _str filename=strip_options(cmdline,options,false,true);
   if (pos(CALLED_FROM_ECLIPSE, options)) {
      index := pos(CALLED_FROM_ECLIPSE, options);
      options = substr(options, 1, index-1):+ substr(options, index+length(CALLED_FROM_ECLIPSE)+1);
      bCalledFromEclipse = true;
   }
   filename=strip(filename,'B','"');

   // If were started as part of the eclipse plug-in then
   // we need to save the "Eclipse" way
   if (isEclipsePlugin() && !bCalledFromEclipse) {
      _str _origCmdLine = cmdline;
      cmdline = filename;
      if(cmdline =='') {
         cmdline = p_buf_name;
      }

      if(_eclipse_save(p_window_id, cmdline, flags)){
         return (0);
      }
      cmdline = _origCmdLine;
   }

   if ( filename=='') {
      filename=p_buf_name;
      if ( filename=='' || !_HaveValidOuputFileName(filename) ||
           (p_readonly_mode && !_isdiffed(p_buf_id)
            && _file_eq(absolute(filename),p_buf_name))
         ) {
         // IF called when application loses focus (save files on lost focus)
         if (flags & SV_POSTMSGBOX) {
            // Don't need to save these files
            return(0);
         }
         // IF no dialogs allowed
         if ((flags & SV_RETURNSTATUS) ) {
            if (filename=='' || !_HaveValidOuputFileName(filename)) {
               return(ERROR_WRITING_FILE_RC);
            }
         } else {
            // When save_all is called in one file per window mode need to set
            // the focus
            _set_focus();
            if (p_readonly_mode && filename!="") {
               if (_get_filetype_dir_parts(filename,auto ft_dir,auto ft_file)) {
                  return gui_save_as('',ft_file,ft_dir);
               }
               int ro_status = _readonly_error(0,true,true);
               if (ro_status || !p_readonly_mode) {
                  return ro_status;
               }
            } else {
               if (isEclipsePlugin() && bCalledFromEclipse) {
                  int rc = _eclipse_save_as(p_window_id, cmdline, flags);
                  if(rc == 0) {
                     p_modify = false;
                  }
                  return(0);
               }
               return(gui_save_as());
            }
         }
      }
   }
   if ( index_callable(find_index("delphiIsRunning",PROC_TYPE)) ) {
      if ( delphiIsRunning() && delphiIsBufInDelphi(p_buf_name) ) {
         //sticky_message( "delphi file="p_buf_name );
         delphiSaveBuffer( p_buf_name );
         return( 0 );
      }
   }
   typeless status=0;
   afilename := absolute(filename);
   /* IF name of buffer has been changed or new file  OR  saving to  */
   /* different file AND destination file already exists AND prompt on replace */
   /* and called from a key/command line/or option given. */
   if ( preplace && 
        ((p_buf_flags&VSBUFFLAG_PROMPT_REPLACE) || 
          (!_file_eq(strip(afilename,'','"'),p_buf_name) && !_file_eq(strip(absolute(afilename,null,true),'','"'),p_buf_name_no_symlinks))) &&
        file_exists(filename)
      ) {
      status=overwrite_existing(filename,'Save',flags);
      if ( status ) {
         return(status);
      }
   }
   /*
      IF user wants prompting on save AND
         buffer was not renamed AND
         save name matches buffer name AND
         This is not a new file AND
         file exists on disk AND
         file is newer than buffer
   */
   if (preplace &&
       !(p_buf_flags&VSBUFFLAG_PROMPT_REPLACE) &&
       (_file_eq(strip(afilename,'','"'),p_buf_name) || _file_eq(strip(absolute(afilename,null,true),'','"'),p_buf_name_no_symlinks)) &&
       p_file_date!="" && p_file_date!=0 &&
       file_exists(filename) &&
       p_file_date<_file_date(filename,'B')) {
      status=overwrite_newer(filename,'Save',flags);
      if ( status ) {
         return(status);
      }
   }
   update_format_line('1');
   if (!(flags & SV_QUIET)) message(nls('Saving %s',filename));
   if (!_HaveValidOuputFileName(afilename)) {
      message(nls('Invalid filename'));
      return(1);
   }
   save_count:=0;
   nobackup := "";
   if ((flags & SV_POSTMSGBOX)) flags&=~SV_RETRYSAVE;
   for (;;) {
      tempoptions := options:+nobackup;
      save_read_only := 0;
      if (_isUnix()) {

         /* On UNIX, allow user to specify -r or +r to save as read only. */
         options2 := "";
         parse tempoptions with tempoptions '(-|\+)r','ir' +0 options2;
         ch := lowcase(substr(options2,1,2));
         if ( ch=='-r' || ch=='+r' ) {
            tempoptions :+= substr(options2,3);
            save_read_only=1;
            /* Owner does not have write access. */
            status=_chmod('u+w '_maybe_quote_filename(filename));
            //status=_chmod('u+w 'p_buf_name);
            if ( status && status!=FILE_NOT_FOUND_RC) {
               if (flags & SV_RETURNSTATUS) {
                  return(status);
               }
               _sv_message_box(flags,nls("Failed to change file permissions.  Check that you have access to the owner or group of this file."));
               return(status);
            }
         }
      }
      mou_hour_glass(true);
      status= save_file(filename,build_save_options(filename) " "tempoptions);
      if (!status  && !(flags & SV_NOADDFILEHIST)) {
         save_count++;
         if (save_count <= def_max_filehist) {
            _menu_add_filehist(strip(filename,'B','"'));
         } else if (save_count <= def_max_allfileshist) {
            _menu_add_allfilehist(strip(filename,'B','"'));
         }
      }
      mou_hour_glass(false);
      if (_isUnix()) {
         if (save_read_only && !_DataSetIsFile(filename)) {
            int status2=_chmod('u-w '_maybe_quote_filename(filename));
            if ( !status && status2 ) {
               status=status2;
               message(get_message(status));
            }
         }
      }
      if (!(flags & SV_QUIET)) clear_message();
      if ( status==0 ) {
         if ( _file_eq(afilename,p_buf_name) ) {
            p_buf_flags &= ~VSBUFFLAG_PROMPT_REPLACE;
         }
      }
      if (flags & SV_RETURNSTATUS) {
         return(status);
      }
      nobackup="";
      typeless retry=_save_status(status,p_buf_name,filename,flags);
      if (!retry) break;
      if (retry&1) { //Save file as read only. UNIX only
         nobackup=" +r";
      }
      if (retry & 2) {
         nobackup :+= " +o";
      }
      // local backup directory might have been changed.
   }
   return(status);
}
int _save_status(var status,_str buf_name,_str filename="", int sv_flags=0)
{
   if (!isinteger(sv_flags)) sv_flags=0;
   int post_msgbox=(sv_flags & SV_POSTMSGBOX);
   int retrysave=(sv_flags & SV_RETRYSAVE);
   if (!status || status==COMMAND_CANCELLED_RC) {
      return(0);
   }
   // save_all command is called when VS does not have focus.  Under windows 3.x
   // this command can not set the focus.  Here we set the focus if there
   // is an error during the save_all command
   if (!post_msgbox) {
      _set_focus();
   }
   msg := "";
   if (status == DS_CANNOT_CREATE_BACKUP_FOR_FILE_RC) {
      status = 0;  // want to be sure actual save status is not affected here
   } else {
      if (filename!="" && filename!=buf_name) {
         //filename=buf_name;
         msg=nls("Unable to save %s to %s\n",buf_name,filename);
      } else {
         msg=nls("Unable to save %s\n",buf_name);
      }
   }
   if (status==ACCESS_DENIED_RC) {
      if (retrysave) {
         if (_DataSetIsFile(buf_name)) {
            msg2 :=  msg:+ get_message(status);
            msg2 :+= ".\nData set may be currently in use by another process.\nPlease check and try again.";
            _message_box(msg2);
            return(0);
         }
      }
      if (_isUnix()) {
         if (retrysave) {
            _str attrs=file_list_field(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
            if (attrs=='') {
               _sv_message_box(sv_flags,msg:+ get_message(status));
               return(0);
            }
            // IF there are no write permissions on this file.
            if (!pos("w","")) {
               flags := 1;  // Save as read only
               status=show("-modal _retrysave_form",msg:+ get_message(status),flags);
               if (!isinteger(status)) return(0);
               return(status);
            }
         }
      }
      backup_msg := "Backup directory could not be created.\n";
      if (pos(' \+d[d] ',' 'def_save_options' ',1,'ir')) {
         _str dir=_replace_envvars(get_env('VSLICKBACKUP'));
         if (dir=='') {
            if (_isUnix()) {
               dir=get_env('HOME');
               if (_last_char(dir)!=FILESEP) dir=dir:+FILESEP;
               dir :+= '.vslick/backup';
            } else {
               dir='\vslick\backup';
            }
         }
         _maybe_strip_filesep(dir);
         backup_msg='';
         if (file_match('-p 'dir,1)=='') {
            backup_msg="Backup directory '"dir"' could not be created.\n";
         }
      }
      _str msg2="\n\n":+
      "Possible causes:\n\n":+
      backup_msg;
      if (_isUnix()) {
         msg2=msg2:+"Permissions on this file are read only.\n":+
         "Another program has a lock on this file.\n";
      } else {
         msg2 :+= "Another program has this file open.\n";
      }
      msg2 :+= "\nSee help on \"Backup options\".";
      _sv_message_box(sv_flags,msg:+ get_message(status):+msg2);
      return(0);
   }
   if (retrysave) {
      if (status==FAILED_TO_BACKUP_FILE_RC
          || (_isWindows() && status==FAILED_TO_BACKUP_FILE_ACCESS_DENIED_RC)
         ) {
         flags := 2;
         // UNIX always uses a local backup directory "$HOME/.vslick"
         if (_isWindows()) {
            if (pos(' [\+|\-]d '," "def_save_options" ",1,'RI')) {
               flags=2|4;
            }
         }
         status=show("-modal _retrysave_form",msg:+ get_message(status),flags);
         if (!isinteger(status)) return(0);
         return(status);
      }
      if (status==FAILED_TO_BACKUP_FILE_ACCESS_DENIED_RC) {
         status=show("-modal _retrysave_form",msg:+ get_message(status),2);
         if (!isinteger(status)) return(0);
         return(status);
      }
   }
   _sv_message_box(sv_flags,msg:+ get_message(status));
   return(0);
}

/**
 * Displays a dialog box which prompts the user whether to replace the
 * existing file, <i>filename</i>.  The title of the dialog box is set to
 * <i>title</i> given.
 *
 * @return Returns 0 if the user has selected to replace the existing file.
 *
 * @categories Miscellaneous_Functions
 *
 */
int overwrite_existing(_str filename, _str title, int sv_flags=0)
{
   post_msgbox := isinteger(sv_flags) && (sv_flags & SV_POSTMSGBOX);
   orig_wid := p_window_id;_set_focus();
   if (post_msgbox) {
      _beep();_beep();
      message(nls("File '%s' already exists.  Can't replace during application switch focus",filename));
      return(COMMAND_CANCELLED_RC);
   }
   int status=_message_box(nls("File '%s' already exists.",filename)"\n\n":+
                       nls("Replace existing file?"),
                       title,
                       MB_YESNOCANCEL|MB_ICONQUESTION,IDNO
                      );
          p_window_id=orig_wid;
   if (status!=IDYES) {
      return(COMMAND_CANCELLED_RC);
   }
   return(0);
}
static int overwrite_newer(_str filename, _str title, int sv_flags=0)
{
   post_msgbox := isinteger(sv_flags) && (sv_flags & SV_POSTMSGBOX);
   orig_wid := p_window_id;_set_focus();
   if (post_msgbox) {
      _beep();_beep();
      message(nls("File '%s' is a new version.  Can't replace during application switch focus",filename));
      return(COMMAND_CANCELLED_RC);
   }
   int status=_message_box(nls("File '%s' is a new version.",filename)"\n\n":+
                       nls("Replace existing newer file?"),
                       title,
                       MB_YESNOCANCEL|MB_ICONQUESTION,IDNO
                      );
   p_window_id=orig_wid;
   if (status!=IDYES) {
      return(COMMAND_CANCELLED_RC);
   }
   return(0);
}
/*
   Under windows it is not safe to display a sychronous dialog box of any kind
   during the WM_ACTIVATEAPP lost focus message.  Windows NT and Chicago have
   not problem with this.
*/
void _sv_message_box(int sv_flags, _str msg)
{
   _mdi._set_foreground_window();
   post_msgbox := isinteger(sv_flags) && (sv_flags & SV_POSTMSGBOX);
   if (post_msgbox) {
      _beep();_beep();
      _post_call(find_index('popup_message',COMMAND_TYPE),msg);
      return;
   }
   _message_box(msg);
}


/**
 * Callback for select_tree(), for files that have been modified on disk and may 
 * need to be reloaded. 
 * 
 * @param reason 
 * @param user_data 
 * @param info 
 * 
 * @return 
 */
static _str reload_modified_cb (int reason, typeless user_data, typeless info=null)
{
   switch (reason) {
   case ST_ONLOAD:
      ctl_ok._set_focus();
      break;
   case SL_ONINITFIRST:
      select_tree_message(user_data);
      ctl_ok.p_caption = "&Reload Selected";
      ctl_ok.p_width = _text_width(ctl_ok.p_caption) + 240;
      ctl_cancel.p_x = ctl_ok.p_x_extent + 60;
      ctl_invert.p_x = ctl_cancel.p_x_extent + 60;

      // close selected
      ctl_selectall.p_eventtab = defeventtab _save_deleted_close_button;
      ctl_selectall.p_x = ctl_invert.p_x_extent + 60;
      ctl_selectall.p_y = ctl_invert.p_y;
      ctl_selectall.p_caption = "&Close Selected";
      ctl_selectall.p_auto_size = true;
      
      // diff selected
      ctl_delete.p_eventtab = defeventtab _reload_modified_diff_button;
      ctl_delete.p_x = ctl_selectall.p_x_extent + 60;
      ctl_delete.p_y = ctl_selectall.p_y;
      ctl_delete.p_caption = "&Diff Selected";
      ctl_delete.p_auto_size = true;

      // never reload
      ctl_additem.p_eventtab = defeventtab _never_reload_button;
      ctl_additem.p_x = ctl_delete.p_x_extent + 60;
      ctl_additem.p_y = ctl_delete.p_y;
      ctl_additem.p_caption = "Never Reload Selected";
      ctl_additem.p_auto_size = true;
      ctl_additem.p_visible = true;
      ctl_additem.p_enabled = true;

      break;
   }
   return '';
}


/**
 * Callback for select_tree(), for files that have been deleted from disk, but 
 * are still open in SE and may need to be re-saved. 
 * 
 * @param reason 
 * @param user_data 
 * @param info 
 * 
 * @return 
 */
static _str save_deleted_cb (int reason, typeless user_data, typeless info=null)
{
   switch (reason) {
   case ST_ONLOAD:
      ctl_ok._set_focus();
      break;
   case SL_ONINITFIRST:
      select_tree_message(user_data);
      ctl_ok.p_caption = "&Save Selected";
      ctl_ok.p_width = _text_width(ctl_ok.p_caption) + 240;
      ctl_cancel.p_x = ctl_ok.p_x_extent + 60;
      ctl_invert.p_x = ctl_cancel.p_x_extent + 60;
      ctl_selectall.p_eventtab = defeventtab _save_deleted_close_button;
      ctl_selectall.p_x = ctl_invert.p_x_extent + 60;
      ctl_selectall.p_y = ctl_invert.p_y;
      ctl_selectall.p_caption = "&Close Selected";
      ctl_selectall.p_width = 120 + _text_width(ctl_selectall.p_caption);
      ctl_delete.p_x = ctl_selectall.p_x_extent + 60;
      ctl_delete.p_visible = false;
      ctl_tree.p_NeverColorCurrent = true;
      break;
   }
   return '';
}


/*
   ctlbackupdir.p_user    Original value of VSLICKBACKUP environment variable.

*/
defeventtab _retrysave_form;
void ctlok.on_create(_str msg='', typeless flags='')
{
   if (!isinteger(flags)) flags=1|2|4;
   if (_isUnix()) {
      flags&=~4;
   }
   if (msg!="") {
      ctllabel1.p_caption=msg;
   }
   if (!(flags&1)) {
      if (_isUnix()) {
         ctlreadonly.p_enabled=false;
      } else {
         ctlreadonly.p_visible=false;
      }
   }
   if (!(flags&2)) {
      ctlnobackup.p_enabled=false;
   }
   if (!(flags&4)) {
      if (_isUnix()) {
         ctlconfigbackupdir.p_visible=ctlbackupdir.p_visible=ctlbackupdirlab.p_visible=false;
      } else {
         ctlconfigbackupdir.p_enabled=ctlbackupdir.p_enabled=ctlbackupdirlab.p_enabled=false;
      }
   } else {
      backupdir := get_env("VSLICKBACKUP");
      ctlbackupdir.p_user=backupdir;
      if (backupdir=="") {
         backupdir="c:\\vslick\\backup";
      }
      ctlbackupdir.p_text=backupdir;
   }
   ctlreadonly.call_event(ctlreadonly,lbutton_up);
}
void ctlreadonly.lbutton_up()
{
   if (ctlreadonly.p_value ||
       ctlnobackup.p_value ||
       (ctlconfigbackupdir.p_value && ctlbackupdir.p_text!=ctlbackupdir.p_user)) {
      ctlok.p_enabled=true;
   } else {
      ctlok.p_enabled=false;
   }
   ctlbackupdir.p_enabled=ctlbackupdirlab.p_enabled=ctlconfigbackupdir.p_value!=0;
}
void ctlok.lbutton_up()
{
   flags := 0;
   if (ctlreadonly.p_value) {
      flags|=1;
   }
   if (ctlnobackup.p_value) {
      flags|=2;
   }
   if (ctlconfigbackupdir.p_value) {
      flags|=4;
      new_value := ctlbackupdir.p_text;
      int status=_ConfigEnvVar("VSLICKBACKUP",new_value,_encode_vsenvvars(new_value,false));
      if (status) {
         return;
      }
   }
   p_active_form._delete_window(flags);
}

/**
 * Sets environment variable specified to value specified.  In addition,
 * this environment setting is placed in the users local
 * "user.cfg.xml" so that the next time the editor is invoked,
 * the environment variable is set to this value.
 * 
 * @categories Miscellaneous_Functions
 * @param envvar_name
 * @param new_value    Value to set environment variable to. If 
 *                     null, environment variable is deleted.
 * @param new_encoded_value  Value to set in environment 
 *                           profile. This is often encoded with
 *                           other environment variables
 *                           (aa%MYVAR%bb) but the new_value
 *                           argument is typically not encoded
 *                           and probably shouldn't be encoded.
 * 
 * @return Returns 0 if successful.
 */
int _ConfigEnvVar(_str envvar_name, _str new_value,_str new_encoded_value=null)
{
   if (new_value._isempty()) {
      handle:=_plugin_get_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_ENVIRONMENT);
      if (handle>=0) {
         profile_node:=_xmlcfg_get_first_child_element(handle);
         if (profile_node>=0) {
            property_node:=_xmlcfg_find_property(handle,profile_node,env_case(envvar_name));
            if (property_node>=0) {
               _xmlcfg_delete(handle,property_node);
               _plugin_set_profile(handle);
            }
         }
         _xmlcfg_close(handle);
      }
   } else {
      _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_ENVIRONMENT,VSCFGPROFILE_ENVIRONMENT_VERSION,env_case(envvar_name),new_encoded_value==null?new_value:new_encoded_value);
   }
   if (new_value._isempty()) {
      set_env(envvar_name);
   } else {
      set_env(envvar_name,new_value);
   }

   return(0);
}

/**
 * Changes the name of the current buffer to <i>filename</i>.  If no
 * <i>filename</i> is specified the current value is displayed on the command
 * line for editing.
 *
 * @return Returns 0 if successful.
 *
 * @see gui_save_as
 * @see save
 * @categories Edit_Window_Methods, File_Functions
 */
_command int name(_str newName="",bool doAbsolute=true, bool prompt_for_newName=true) name_info(FILENEW_ARG','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   orig_ext:=get_extension(p_buf_name,true);
   orig_LangId:=p_LangId;
   _str arg1=newName;
   if (newName=='' && prompt_for_newName) {
      arg1=prompt(newName,'',p_buf_name);
   }
   int status= name_file(strip(arg1,'B','"'),doAbsolute);
   if (status) return(status);
   p_modify=true;
   p_buf_flags |= VSBUFFLAG_PROMPT_REPLACE;
   // Force recalculation of adaptive formatting settings.
   p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(p_LangId);
   /*
      Starting with SlickEdit v13, setting the editor language gets
      ignored unless p_LandId=''.
   */
   p_LangId='';
   _SetEditorLanguage();
   if (p_LangId=='fundamental' && orig_ext=='' && get_extension(p_buf_name,true)=='' && orig_LangId!='fundamental') {
      _SetEditorLanguage(orig_LangId);
   }
   return(0);

}
_command void docname(_str newDocumentName='') name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_DocumentName:==newDocumentName) {
      return;
   }
   call_list('_document_renamed_',p_buf_id,p_DocumentName,newDocumentName,p_buf_flags);
   _str oldDocumentName=p_DocumentName;
   p_DocumentName=newDocumentName;
   call_list('_document_renamedAfter_',p_buf_id,oldDocumentName,newDocumentName,p_buf_flags);
}

/**
 * Change the current filename and update many references to
 * filename.
 * 
 * <p>Changes name on disk, in project, tag files, backup
 * history, file history
 * 
 * <p>Always saves file contents under new filename specified.
 *
 * @return Returns 0 if successful.
 *
 * @categories Edit_Window_Methods, File_Functions
 */
_command int rename(_str newfilename="") name_info(FILENEW_ARG','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   newfilename=strip(newfilename,'B','"');
   if (newfilename=='') {
      newfilename=prompt(newfilename,'',p_buf_name);
   }
   _rename_file('',newfilename);
   return(0);
}
static void _copy_backup_history_dir(_str old_dir,_str new_dir) {
   if (!_haveBackupHistory()) {
      return;
   }
   _maybe_append_filesep(old_dir);
   _maybe_append_filesep(new_dir);
   src_path:=_strip_filename(DSGetArchiveFilename(old_dir),'n');
   dest_path:=_strip_filename(DSGetArchiveFilename(new_dir),'n');
   // Not critical if can't copy backup files.
   status:=copyFileTree(src_path, dest_path,"", true);
}
static void _copy_backup_history(_str origfilename,_str newfilename) {
   if (!_haveBackupHistory()) {
      return;
   }
   dest_archive:=DSGetArchiveFilename(newfilename);
   if (file_exists(dest_archive)) {
      // This is too weird a case.
      return;
   }
   src_archive:=DSGetArchiveFilename(origfilename);
   handle:=_xmlcfg_open(src_archive,auto status);
   if (handle<0) {
      // Most likely the backup history delta file doesn't exist.
      return;
   }
   _str new_files[];
   status=copy_file(src_archive,dest_archive);
   if (status) {
      status=make_path(_strip_filename(dest_archive,'N'));
      if (!status) {
         status=copy_file(src_archive,dest_archive);
      }
   }
   if (!status) {
      new_files[new_files._length()]=dest_archive;
      dest:=_strip_filename(dest_archive,'E');
      status=copy_file(_strip_filename(src_archive,'E'),dest);
      if (!status) {
         new_files[new_files._length()]=dest;
         typeless array[];
         _xmlcfg_find_simple_array(handle,"/DF/D",array);
         for (i:=0;i<array._length();++i) {
            int node=array[i];
            if (_xmlcfg_get_type(handle,node)==VSXMLCFG_NODE_ELEMENT_START_END) {
               v:=_xmlcfg_get_attribute(handle,node,'V');
               dest=_strip_filename(dest_archive,'E')'.'v;
               status=copy_file(_strip_filename(src_archive,'E')'.'v,dest);
               if (status) {
                  break;
               }
               new_files[new_files._length()]=dest;
            }
         }
      }
      
   }
   if (status) {
      // Not critical if can't copy backup history
      for (j:=0;j<new_files._length();++j) {
         delete_file(new_files[j]);
      }
   }
   _xmlcfg_close(handle);
}
int _rename_file(_str origfilename,_str newfilename) {
   if (newfilename=='') {
      return COMMAND_CANCELLED_RC;
   }
   bool current_buffer_case=false;
   if (origfilename=='' && (p_buf_name=='' || !file_exists(p_buf_name))) {
      origfilename=p_buf_name;
      current_buffer_case=true;
   } else {
      if (origfilename=='') {
         origfilename=p_buf_name;
      }
      origfilename=absolute(origfilename);

      typeless buf_id,modifyFlags,buf_flags,buf_name;
      parse buf_match(_maybe_quote_filename(origfilename),1,'vhx') with buf_id modifyFlags buf_flags buf_name;
      if (modifyFlags!='' && (modifyFlags&1)) {
         _message_box(nls("Save file '%s' first",origfilename));
         return COMMAND_CANCELLED_RC;
      }
   }
   newfilename=absolute(newfilename);
   if (isdirectory(newfilename)) {
      _maybe_append_filesep(newfilename);
      strappend(newfilename,_strip_filename(origfilename,'p'));
   }
   if (file_eq(origfilename,newfilename)) {
      _message_box(nls("Can't rename to same name"));
      return COMMAND_CANCELLED_RC;
   }
   if (file_exists(newfilename)) {
      _message_box(nls("Destination file '%s' already exists",newfilename));
      return COMMAND_CANCELLED_RC;
   }
   prefix_dir:=_strip_filename(newfilename,'n');
   _maybe_strip(prefix_dir,FILESEP);
   if (!file_exists(prefix_dir)) {
      status:=_message_box("Create destination directory?\n\n"prefix_dir,'',MB_YESNOCANCEL);
      if (status!=IDYES) {
         return COMMAND_CANCELLED_RC;
      }
      status=_make_path(prefix_dir);
      if (status) {
         _message_box(nls("Unable to create parent directory '%s'",prefix_dir));
         return COMMAND_CANCELLED_RC;
      }
   }
   old_wfilename:=_workspace_filename;
   bool renaming_project=false;
   bool renaming_workspace=false;
   _str orig_project_tag_file='';
   // Are we renaming the project file?
   if (_workspace_filename != '' && !_IsWorkspaceAssociated(_workspace_filename)) {
      if (file_eq(get_extension(origfilename,true),PRJ_FILE_EXT) && 
          file_eq(get_extension(newfilename,true),PRJ_FILE_EXT)) {
         _str array[]=null;
         _GetWorkspaceFiles(_workspace_filename, array);
         for (i:= 0; i < array._length(); ++i) {
            project_filename:=absolute(array[i],_strip_filename(_workspace_filename,'N'));
            if (file_eq(project_filename,origfilename)) {
               renaming_project=true;
               break;
            }
         }
      }
      if (file_eq(get_extension(origfilename,true),WORKSPACE_FILE_EXT) && 
          file_eq(get_extension(newfilename,true),WORKSPACE_FILE_EXT)) {
         renaming_workspace=true;
      }
   }
   if (renaming_project || renaming_workspace) {
      /* NOTE: If the workspace is renamed, that can change the name of
         a project specific tag file. It just means there may be an extra unused .vtg 
         file left hanging around.
      */ 
      if (renaming_project) {
         orig_project_tag_file=project_tags_filename_only(origfilename,false,true);
      }
      orig_flags:=def_restore_flags;
      def_restore_flags&=~RF_PROJECTFILES;
      workspace_close();
      def_restore_flags=orig_flags;
   }
   status:=0;
   if (current_buffer_case) {
      //File does not exists on disk case
      origmodify:=p_modify;
      name(newfilename);
      status=save('',SV_OVERWRITE);
      //status:=0;say('status='status);
      if (status) {
         if (origfilename=='') {
            name(origfilename,false,false);
         } else {
            name(origfilename);
         }
         p_buf_flags &= ~VSBUFFLAG_PROMPT_REPLACE;
         p_modify=origmodify;
      }
   } else {
      _LoadEntireBuffer(origfilename);
      status=_file_move(newfilename,origfilename);
      if (status) {
         _message_box("Move failed\n\nSource:"origfilename"\n\nDest:"newfilename);
      } else {
         _rename_buffer(origfilename,newfilename);
      }
   }
   if (status) {
      if (old_wfilename!='' && _workspace_filename=='') {
         orig_flags:=def_restore_flags;
         def_restore_flags&=~RF_PROJECTFILES;
         workspace_open(_maybe_quote_filename(old_wfilename));
         def_restore_flags=orig_flags;
      }
      return status;
   }
   if (origfilename!='') {
      if (current_buffer_case) {
         _menu_remove_filehist(origfilename);
         recycle_file(origfilename);
      } else {
         _menu_rename_filehist(origfilename,newfilename);
         if (renaming_workspace || renaming_project) {
            _menu_rename_workspace_hist(origfilename,newfilename);
         }
      }
      _copy_backup_history(origfilename,newfilename);
      if ((def_vcflags&VCF_PROMPT_TO_REMOVE_DELETED_FILES) || (def_vcflags&VCF_PROMPT_TO_ADD_NEW_FILES)) {
          // TODO: rename/move in version control system
          // If you want, you can restrict this to requiring a workspace to be open.
      }
      bool renaming_project_do_reload=false;
      bool reload_workspace=false;
      if (renaming_project) {
         int old_array_size=_default_option(VSOPTION_WARNING_ARRAY_SIZE);
         _default_option(VSOPTION_WARNING_ARRAY_SIZE,MAXINT);
         if (!file_eq(_strip_filename(origfilename,'N'),_strip_filename(newfilename,'N'))) {
            handle3:=_xmlcfg_open(newfilename,auto junk3);
            if (handle3>=0) {
               typeless node_array;
               status=_xmlcfg_find_simple_array(handle3,'//F',node_array);
               if (!status) {
                  oldpath:=_strip_filename(origfilename,'N');
                  newpath:=_strip_filename(newfilename,'N');
                  for (j:=0;j<node_array._length();++j) {
                     node:=node_array[j];
                     _xmlcfg_set_attribute(handle3,node,'N',
                                           relative(absolute(_xmlcfg_get_attribute(handle3,node,'N'),oldpath),newpath));
                  }
               }
               _ProjectSave(handle3);
               renaming_project_do_reload=true;
               _xmlcfg_close(handle3);
               /* If a user is editing this project, Would be nice to reload this buffer. */
            }
         }
         // Rename and dependencies to this project referenced 
         //<Dependency Project="dep2/dep2.vpj"/>
         _str array[]=null;
         _GetWorkspaceFiles(old_wfilename, array);
         for (i := 0; i < array._length(); ++i) {
            project_filename:=absolute(array[i],_strip_filename(_workspace_filename,'N'));
            if (!file_eq(project_filename,origfilename)) {
               handle2:=_xmlcfg_open(project_filename,auto junk2);
               if (handle2>=0) {
                  old_path:=_RelativeToProject(origfilename,project_filename);
                  if (FILESEP=='\') {
                     //normalize old path
                     old_path=translate(old_path,'/',FILESEP);
                  }
                  if (old_path!='') {
                     typeless node_array;
                     status=_xmlcfg_find_simple_array(handle2,'//Dependency[file-eq(@Project,"'old_path'")]',node_array);
                     if (status==0) {
                        new_path:=_RelativeToProject(newfilename,project_filename);
                        if (FILESEP=='\') {
                           //normalize old path
                           new_path=translate(new_path,'/','\');
                        }
                        for (j:=0;j<node_array._length();++j) {
                           node:=node_array[0];
                           _xmlcfg_set_attribute(handle2,node,'Project',new_path);
                        }
                        if (node_array._length()) {
                           // Not much we can do if this save fails.
                           // Files have already been moved.
                           _ProjectSave(handle2);
                           _reload_buffer(project_filename);
                        }
                     }
                  }
                  _xmlcfg_close(handle2);
               }
            }
         }

         // Check if a workspace project needs to be moved.
         handle:=_xmlcfg_open(old_wfilename,auto junk);
         if (handle>=0) {
            old_path:=_RelativeToProject(origfilename,old_wfilename);
            if (FILESEP=='\') {
               //normalize old path
               old_path=translate(old_path,'/','\');
            }
            if (old_path!='') {
               node:=_xmlcfg_find_simple(handle,'//Project[file-eq(@File,"'old_path'")]');
               if (node>=0) {
                  new_path:=_RelativeToProject(newfilename,old_wfilename);
                  if (FILESEP=='\') {
                     //normalize old path
                     new_path=translate(new_path,'/','\');
                  }
                  _xmlcfg_set_attribute(handle,node,'File',new_path);
                  // Not much we can do if this save fails.
                  // Files have already been moved.
                  _WorkspaceSave(handle);
                  reload_workspace=true;
               }
            }
         }
         _xmlcfg_close(handle);
         _default_option(VSOPTION_WARNING_ARRAY_SIZE,old_array_size);
      }
      if (renaming_workspace) {
         bool workspace_path_changed=false;
         if (!file_eq(_strip_filename(origfilename,'N'),_strip_filename(newfilename,'N'))) {
            workspace_path_changed=true;
            int old_array_size=_default_option(VSOPTION_WARNING_ARRAY_SIZE);
            _default_option(VSOPTION_WARNING_ARRAY_SIZE,MAXINT);
            handle4:=_xmlcfg_open(newfilename,auto junk3);
            if (handle4>=0) {
               typeless node_array;
               status=_xmlcfg_find_simple_array(handle4,'//Project',node_array);
               if (!status) {
                  oldpath:=_strip_filename(origfilename,'N');
                  newpath:=_strip_filename(newfilename,'N');
                  for (j:=0;j<node_array._length();++j) {
                     node:=node_array[j];
                     _xmlcfg_set_attribute(handle4,node,'File',
                                           relative(absolute(_xmlcfg_get_attribute(handle4,node,'File'),oldpath),newpath));
                  }
                  if (node_array._length()) {
                     _WorkspaceSave(handle4);
                  }
               }
               reload_workspace=true;
               _xmlcfg_close(handle4);
               /* If a user is editing this project, Would be nice to reload this buffer. */
            }
            _default_option(VSOPTION_WARNING_ARRAY_SIZE,old_array_size);
         }


         orig_vtg:=_strip_filename(origfilename,'E'):+TAG_FILE_EXT;
         orig_vpwhist:=_strip_filename(origfilename,'E'):+WORKSPACE_STATE_FILE_EXT;
         if (workspace_path_changed) {
            delete_file(orig_vtg);
            // Would be better if we changed the paths in the vpwhist file but the
            // file format isn't great.
            delete_file(orig_vpwhist);
         } else {
            // Rename .vtg
            new_vtg:=_strip_filename(newfilename,'E'):+TAG_FILE_EXT;
            // Not a huge deal if this fails.
            _file_move(new_vtg,orig_vtg);

            // Rename .vpwhist
            new_vpwhist:=_strip_filename(newfilename,'E'):+WORKSPACE_STATE_FILE_EXT;
            // Not a huge deal if this fails.
            _file_move(new_vpwhist,orig_vpwhist);
         }
         old_wfilename=newfilename;
      }
      if (old_wfilename!='' && _workspace_filename=='') {
         if (orig_project_tag_file!='') {
            new_project_tag_file:=_VSEProjectTagFileName(old_wfilename,newfilename);
            // Not a huge deal if this fails.
            _file_move(new_project_tag_file,orig_project_tag_file);
         }

         orig_flags:=def_restore_flags;
         def_restore_flags&=~RF_PROJECTFILES;
         workspace_open(_maybe_quote_filename(old_wfilename),'','',true,true,false);
         def_restore_flags=orig_flags;
      }

      //IF there is a workspace open
      if (_workspace_filename != '') {
         // Check if the original filename exists as a non-wildcard
         _str found_in_project_names[];
         _str wildcard_in_project[];
         int i;
         _str array[]=null;
         _GetWorkspaceFiles(_workspace_filename, array);
         for (i = 0; i < array._length(); ++i) {
            project_filename:=absolute(array[i],_strip_filename(_workspace_filename,'N'));
            // file_in_project includes wildcard files which can't be removed!
            if (_FileExistsInCurrentProject(origfilename,project_filename)) {
               wildcard_in_project[wildcard_in_project._length()]=project_filename;
               //say('wildcard in project 'project_filename);
            }
            removed_a_file:=false;
            project_remove_filelist(project_filename,_maybe_quote_filename(origfilename),false,removed_a_file);
            if (removed_a_file) {
               //say('removed');
               found_in_project_names[found_in_project_names._length()]=project_filename;
            }
         }
         //say('wildcard_in_project='wildcard_in_project._length());
         for (i=0;i<found_in_project_names._length();++i) {
            //say("adding newfilename="newfilename);
            /* Don't care if file already exists in project.
               Either a wildcard picked the new name up or
               caller overwrote an existing file.
            */
            project_add_file(newfilename,true,found_in_project_names[i]);
         }
         bool assume_wildcard=false;
         if (!found_in_project_names._length()) {
            assume_wildcard=true;
            // This file could be a wildcard
            if (wildcard_in_project._length()) {
               for (i=0;i<wildcard_in_project._length();++i) {
                  ProjectName:=wildcard_in_project[i];
                  //say('tagging ProjectName='ProjectName);
                  useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
                  _str tag_filename=project_tags_filename_only(ProjectName);
                  tag_add_filelist(tag_filename,_maybe_quote_filename(newfilename),ProjectName,useThread,false);
                  call_list("_workspace_file_add", ProjectName, newfilename);
               }
            }
         }
         if (assume_wildcard || _IsWorkspaceAssociated(_workspace_filename)) {
            // Unfortunately, can't be sure if this is a wildcard or not.
            projecttbRefresh();
         }
      }
      if (renaming_project_do_reload) {
         _reload_buffer(newfilename);
      }
      if (reload_workspace) {
         _reload_buffer(_workspace_filename);
      }
   }
   return(0);
}

/**
 * Change the current filename and update many references to
 * filename.
 * 
 * <p>Changes name on disk, in project, tag files, backup
 * history, file history 
 * 
 * <p>Always saves file contents under new filename specified.
 *
 * @return Returns 0 if successful.
 *
 * @categories Edit_Window_Methods, File_Functions
 */
_command int gui_rename() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int was_recording=_macro();
   _macro_delete_line();
   buttons := "Rename,Cancel:_cancel";
   status:=textBoxDialog('Rename File',
                        0,
                        0,
                        "",
                        buttons,
                        '',
                        '-c 'FILENEW_NOQUOTES_ARG:+_chr(0)'New filename:'p_buf_name);
   if (status<0) {
      return status;
   }
   _macro('m',was_recording);
   _macro_call('rename', _param1);
   status=rename(_maybe_quote_filename(_param1));
   return status;
}
void _rename_buffer(_str old_dir,_str new_dir, bool isDirectory=false) {
   if (isDirectory) {
      _maybe_append_filesep(old_dir);
      _maybe_append_filesep(new_dir);
   }
   // Rename buffers that reference the old path name
   int orig_view_id=_create_temp_view(auto temp_view_id);
   start_buf_id:=p_buf_id;
   for (;;) {
      _next_buffer('NRH');
      if ( p_buf_id==start_buf_id ) {
         break;
      }
      if (p_buf_name!='' && _need_to_save()) {
         if (isDirectory) {
            if (file_eq(old_dir,substr(p_buf_name,1,length(old_dir)))) {
               new_buf_name:=new_dir:+substr(p_buf_name,length(old_dir)+1);
               orig_modify:=p_modify;
               p_window_id.name(new_buf_name);
               p_modify=orig_modify;
               p_buf_flags &= ~VSBUFFLAG_PROMPT_REPLACE;
            }
         } else {
            if (file_eq(old_dir,p_buf_name)) {
               new_buf_name:=new_dir;
               orig_modify:=p_modify;
               p_window_id.name(new_buf_name);
               p_modify=orig_modify;
               p_buf_flags &= ~VSBUFFLAG_PROMPT_REPLACE;
            }
         }
      }
   }
   p_window_id=orig_view_id;
}
/**
 * Rename/move a directory.
 * 
 * <p>Updates project files, tag files, backup history, file
 * history
 * 
 * @return Returns 0 if successful.
 *
 * @categories Edit_Window_Methods, File_Functions
 */
_command int rename_directory(_str cmdline='',_str new_dir='') name_info(DIRNEW_ARG' 'DIRNEW_ARG','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   int was_recording=_macro();
   _macro_delete_line();
   old_dir:=parse_file(cmdline,false);
   if (new_dir=='') {
      new_dir=parse_file(cmdline,false);
   }
   if (old_dir=='' || new_dir=='') {
      buttons := "Rename,Cancel:_cancel";
      if (old_dir=='') {
         old_dir=getcwd();
         _maybe_append_filesep(old_dir);
         strappend(old_dir,'dir');
      }
      if (new_dir=='') {
         new_dir=old_dir;
      }
      status:=textBoxDialog('Rename/Move Directory',
                           0,
                           0,
                           "",
                           buttons,
                           '',
                           '-c 'DIRNOQUOTES_ARG:+_chr(0)'Original directory:'old_dir,
                            '-c 'DIRNEW_NOQUOTES_ARG:+_chr(0)'New filename:'new_dir
                            );
      if (status<0) {
         return status;
      }
      old_dir=_param1;
      new_dir=_param2;
   }
   translate(old_dir,FILESEP,FILESEP2);
   translate(new_dir,FILESEP,FILESEP2);
   _maybe_strip(old_dir,FILESEP);
   _maybe_strip(new_dir,FILESEP);
   if (old_dir=='') {
      _message_box('No original directory specified');
      return COMMAND_CANCELLED_RC;
   }
   if (new_dir=='') {
      _message_box('No destination directory specified');
      return COMMAND_CANCELLED_RC;
   }
   old_dir=absolute(old_dir);
   new_dir=absolute(new_dir);
   if (file_eq(old_dir,new_dir)) {
      _message_box('Source and directories match');
      return COMMAND_CANCELLED_RC;
   }
   if (beginsWith(new_dir:+FILESEP,old_dir:+FILESEP,false,_fpos_case)) {
      _message_box("Destiniation directory can't be underneath source directory");
      return COMMAND_CANCELLED_RC;
   }
   prefix_dir:=_strip_filename(new_dir,'n');
   _maybe_strip(prefix_dir,FILESEP);
   if (!file_exists(prefix_dir)) {
      status:=_message_box("Create parent directory?\n\n"prefix_dir,'',MB_YESNOCANCEL);
      if (status!=IDYES) {
         return COMMAND_CANCELLED_RC;
      }
      status=_make_path(prefix_dir);
      if (status) {
         _message_box(nls("Unable to create parent directory '%s'",prefix_dir));
         return COMMAND_CANCELLED_RC;
      }
   }
   old_wfilename:=_workspace_filename;
   bool workspace_or_project_file_effected_by_move=false;
   new_wfilename:=old_wfilename;
   if (_IsWorkspaceAssociated(_workspace_filename)) {
      // A bit too much to try to support renaming third part workspaces, projects, and files.
      old_wfilename='';
   }
   bool changing_workspace_directory=false;
   bool changing_project_directory=false;
   if (old_wfilename!='') {
      if (file_eq(old_dir:+FILESEP,substr(old_wfilename,1,length(old_dir)+1))) {
         workspace_or_project_file_effected_by_move=true;
         new_wfilename=new_dir:+FILESEP:+substr(new_wfilename,length(old_dir)+2);
         changing_workspace_directory=true;
      }
   }

   int status;

   bool renamed_project_file=false;
   if (old_wfilename!='' && !changing_workspace_directory) {
       // Check if a workspace project is being moved
      _str array[]=null;
      _GetWorkspaceFiles(_workspace_filename, array);
      for (i:=0;i<array._length();++i) {
         project_filename:=absolute(array[i],_strip_filename(_workspace_filename,'N'));
         if (file_eq(old_dir:+FILESEP,substr(project_filename,1,length(old_dir)+1))) {
            changing_project_directory=true;
            break;
         }
      }
   }

   /* 
      Close the workspace if it wil lbe effected.
      Not a good idea to move workspace or project files before
      closing the workspace first. _workspace_close will fail.

      Also, on Windows a tag file could still be open which
      will case the move to fail.
   */
   if (workspace_or_project_file_effected_by_move) {
      orig_flags:=def_restore_flags;
      def_restore_flags&=~RF_PROJECTFILES;
      workspace_close();
      def_restore_flags=orig_flags;
   }

   _macro('m',was_recording);
   _macro_call('rename_directory',new_dir, old_dir);
   status=_file_move(new_dir,old_dir);
   if (status && _isWindows() && old_wfilename!='') {
      // could be a problem with the current directory
      orig_cwd:=getcwd();
      // Try change current directory to the root of the current drive
      chdir('\',0);
      // Kill all the process buffers that are running.
      _str array_idnames[];
      _terminal_list_idnames(array_idnames,true);
      if (_process_info()) {
         array_idnames[array_idnames._length()]='';
      }
      for (i:=0;i<array_idnames._length();++i) {
         _process_info('Q',array_idnames[i]);
      }
      _interactive_list_idnames(array_idnames,true);
      for (i=0;i<array_idnames._length();++i) {
         _process_info('Q',array_idnames[i]);
      }

      status=_file_move(new_dir,old_dir);
      chdir(orig_cwd,1);
   }
   //status=0;
   if (status) {
      if (old_wfilename!='' && _workspace_filename=='') {
         orig_flags:=def_restore_flags;
         def_restore_flags&=~RF_PROJECTFILES;
         workspace_open(_maybe_quote_filename(old_wfilename));
         def_restore_flags=orig_flags;
      }
      _message_box("Move failed\n\nSource:"old_dir"\n\nDest:"new_dir);
      return status;
   }
   _rename_buffer(old_dir,new_dir,true);


   //_menu_rename_filehist_path(old_dir,new_dir);
   if (old_wfilename!='') {
      // IF workspace didn't move but a project file directory has changed, adjust the relative project names.
      // Dependencies are not corrected.
      bool workspace_modified=false;
      bool project_modified=false;
      if (!changing_workspace_directory && changing_project_directory) {
         // Check if a workspace project needs to be moved.
         int old_array_size=_default_option(VSOPTION_WARNING_ARRAY_SIZE);
         _default_option(VSOPTION_WARNING_ARRAY_SIZE,MAXINT);

         handle:=_xmlcfg_open(new_wfilename,auto junk);
         if (handle>=0) {
            typeless files[];
            _xmlcfg_find_simple_array(handle,'//Project',files);
            len:=files._length();
            //say('len='len);
            if (len) {
               for (i:=0;i<len;++i) {
                  int node=files[i];
                  filename:=_xmlcfg_get_attribute(handle,node,'File');
                  if (FILESEP=='\') {
                     //need native FILESEP
                     filename=translate(filename,FILESEP,'/');
                  }
                  filename=absolute(filename,_strip_filename(old_wfilename,'N'));
                  if (file_eq(old_dir:+FILESEP,substr(filename,1,length(old_dir)+1))) {
                     filename=new_dir:+FILESEP:+substr(filename,length(old_dir)+2);
                     filename=_RelativeToWorkspace(filename,old_wfilename);
                     if (FILESEP=='\') {
                        //normalize path
                        filename=translate(filename,'/',FILESEP);
                     }
                     workspace_modified=true;
                     _xmlcfg_set_attribute(handle,node,'File',filename);
                  }
               }
               if (workspace_modified) {
                  _WorkspaceSave(handle);
                  _reload_buffer(new_wfilename);
               }
            }
         }
         _default_option(VSOPTION_WARNING_ARRAY_SIZE,old_array_size);
      }
      if (old_wfilename!='' && _workspace_filename=='') {
         orig_flags:=def_restore_flags;
         def_restore_flags&=~RF_PROJECTFILES;
         workspace_open(_maybe_quote_filename(new_wfilename),'','',true,true,false);
         def_restore_flags=orig_flags;
      }
      /*
         If a project directory is being changed, it's too complicated to figure out what
         the new relative file paths should be. For now, just bail. Assume users files
         are relative to the project file being moved and don't need to be changed.
      */
      if (!changing_project_directory) {
         _str array[]=null;
         _GetWorkspaceFiles(new_wfilename, array);
         int old_array_size=_default_option(VSOPTION_WARNING_ARRAY_SIZE);
         _default_option(VSOPTION_WARNING_ARRAY_SIZE,MAXINT);
         for (i := 0; i < array._length(); ++i) {
            project_filename:=absolute(array[i],_strip_filename(new_wfilename,'N'));
            _str project_path=_strip_filename(project_filename,'N');
            handle:=_ProjectHandle(project_filename);
#if 1
            //say('old_dir='old_dir);
            //say('project_filename='project_filename);
            old_path:=_RelativeToProject(old_dir:+FILESEP,project_filename);
            if (FILESEP=='\') {
               //normalize old path
               old_path=translate(old_path,'/','\');
            }
            //strappend(old_path,'/');
            //say('old_path='old_path);
            if (old_path=='') {
               //say('nothing to do');
               // No need to replace anything here.
               // Paths will still be relative.
               continue;
            }
            typeless files[];
            _xmlcfg_find_simple_array(handle,'//F[contains(@N,"^'_escape_re_chars(old_path)'[^/]@$","r")]',files);
            len:=files._length();
            //say('len='len);
            if (len) {
               new_path:=_RelativeToProject(new_dir:+FILESEP,project_filename);
               if (FILESEP=='\') {
                  //normalize old path
                  new_path=translate(new_path,'/','\');
               }
               for (i=0;i<len;++i) {
                  int node=files[i];
                  filename:=_xmlcfg_get_attribute(handle,node,'N');
                  filename=new_path:+substr(filename,length(old_path)+1);
                  _xmlcfg_set_attribute(handle,node,'N',filename);
               }
               project_modified=true;
               _ProjectSave(handle);
               _reload_buffer(project_filename);
            }
#else
            // this is might be more accurate but will be WAAAAAY slower for a large static project.
            typeless files[];
            //_xmlcfg_find_simple_array(handle,'//F[contains(@N,"^'_escape_re_chars(old_path)'[^/]@$","r")]',files);
            _xmlcfg_find_simple_array(handle,'//F',files);
            //_xmlcfg_find_simple_array(handle,"//F[contains(@N,'h','r')]",files);
            //_xmlcfg_find_simple_array(handle,"//F",files);
            len:=files._length();
            //say('len='len);
            if (len) {
               modified:=false;
               for (i=0;i<len;++i) {
                  int node=files[i];
                  filename:=_xmlcfg_get_attribute(handle,node,'N');
                  if (FILESEP=='\') {
                     //Need native FILESEP
                     filename=translate(filename,FILESEP,'/');
                  }
                  filename=absolute(filename,project_path);
                  if (file_eq(old_dir:+FILESEP,substr(filename,1,length(old_dir)+1))) {
                     filename=new_dir:+FILESEP:+substr(filename,length(old_dir)+2);
                     filename=_RelativeToProject(filename,project_path);
                     if (FILESEP=='\') {
                        //normalize path
                        filename=translate(filename,'/',FILESEP);
                     }
                     _xmlcfg_set_attribute(handle,node,'N',filename);
                     project_modified=true;
                     modified=true;
                  }
               }

               if (modified) {
                  _ProjectSave(handle);
                  _reload_buffer(project_filename);
               }
            }
#endif
         }
         _default_option(VSOPTION_WARNING_ARRAY_SIZE,old_array_size);
      }
      if (project_modified || workspace_modified) {
         // Unfortunately, can't be sure if this is a wildcard or not.
         projecttbRefresh();
      }
   }
   _menu_rename_filehist(old_dir,new_dir,true);
   _menu_rename_workspace_hist(old_dir,new_dir,true);
   _copy_backup_history_dir(old_dir,new_dir);
   if ((def_vcflags&VCF_PROMPT_TO_REMOVE_DELETED_FILES) || (def_vcflags&VCF_PROMPT_TO_ADD_NEW_FILES)) {
       // TODO: rename/move in version control system
       // If you want, you can restrict this to requiring a workspace to be open.
   }
   return status;
}
/**
 * Saves current file under name specified and quits the current file.  If
 * <i>filename</i> is not specified, buffer name is used.  Default options for
 * the <b>file</b> command may be set with the File Options. See
 * <b>_save_file</b>() function for a list of valid <i>options</i>.
 *
 * @param cmdline is a string in the format:
 *    <i>options</i>[<i>filename</i>]
 *
 * @return  Returns 0 if successful.  Common return codes are
 * INSUFFICIENT_DISK_SPACE_RC, PATH_NOT_FOUND_RC, ACCESS_DENIED_RC,
 * ERROR_OPENING_FILE_RC, ERROR_WRITING_FILE_RC, DRIVE_NOT_READY_RC, and
 * INVALID_OPTION_RC.  On error, message is displayed.
 *
 * @appliesTo  Edit_Window
 * @categories Edit_Window_Methods, File_Functions
 */
_command int file(_str cmdline='',int flags= -1) name_info(','VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   int status=save(cmdline,flags);
   if ( status==0 ) {
      status=quit();
   }
   return(status);
}


_command int eclipse_quit()
{
   setInternalCallFromEclipse(true);
   int status = quit();
   setInternalCallFromEclipse(false);
   return status;

}

/**
 * Prompts the user to save changes and deletes the current buffer.  The
 * previous buffer is displayed in the current window.  This function is
 * not affected by the One File per Window configuration option.
 *
 * @return  Returns 0 if the buffer was deleted.  Otherwise, a non-zero
 * number is returned.
 *
 * @appliesTo  Edit_Window
 *
 * @categories Buffer_Functions
 */
_command int close_buffer(bool saveBufferPos=true,bool allowQuitIfHiddenWindowActive=false) name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // IF current buffer has the build window running in it
   if (_ConcurProcessName()=='') {
      if (_DebugMaybeTerminate()) {
         return(1);
      }
   }
   if (isEclipsePlugin() && p_window_id != VSWID_HIDDEN && !isInternalCallFromEclipse()) {
      return quit(saveBufferPos,allowQuitIfHiddenWindowActive);
   }

   old_buffer_name := "";
   typeless swold_pos;
   swold_buf_id := 0;
   set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
   int buf_id=p_buf_id;

   int status=_window_quit(true,saveBufferPos,allowQuitIfHiddenWindowActive);
   if (buf_id!=p_buf_id) {
      switch_buffer(old_buffer_name,'Q',swold_pos,swold_buf_id);
   }
   return(status);
}

/**
 * The <b>quit</b> or <b>q</b> command, closes the current file.
 * <p>
 * When one file per window is on (default),
 * the buffer is closed if the current window is last
 * window displaying the buffer.
 * <p>
 * When one file per window is off, the current buffer is always
 * closed and all windows are closed if there are no buffers
 * left to display. Before a buffer is deleted, you will be
 * prompted whether you wish to save changes to the buffer if necessary.
 * </p>
 *
 * @param saveBufferPos    save the current position in the file
 * @param allowQuitIfHiddenWindowActive
 *
 * @return Returns 0 if successful.
 *         Possible return codes are 1 (concurrent process buffer must be exited), and
 *         COMMAND_CANCELLED_RC.  On error, a message is displayed.
 *
 * @appliesTo  Edit_Window
 * @categories Buffer_Functions
 *
 * @see edit
 * @see q
 * @see quit_file
 * @see quit_view
 */
_command int quit(bool saveBufferPos=true,bool allowQuitIfHiddenWindowActive=false) name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _in_quit=true;

   if (!allowQuitIfHiddenWindowActive && !p_mdi_child) {
      // IF current buffer has the build window running in it
      if (_ConcurProcessName()=='') {
         if (_DebugMaybeTerminate()) {
            return(1);
         }
         exit_process();
      }
      _in_quit=false;
      return(0);
   }

   // If we're started as part of the eclipse plug-in then
   // we need to close the "Eclipse" way
   //
   typeless status=0;
   if (isEclipsePlugin() && !isInternalCallFromEclipse()) {
      status = _eclipse_close_editor(p_window_id, p_buf_name, (int)p_modify);
      if (status == 0) {
         // The user decided not to close the editor, so lets bail
         return (status);
      }
      // At this point the user is closing the editor and has already
      // decided to save or not and if they decided to save, the
      // save has happened...so let's change the modify flag
      p_modify = false;
   }

   //bufid=p_buf_id;
   //Dan added because extra support was needed for prroject toolbar stuff
   _str buf_name=p_buf_name;
   if (def_one_file!='') {
      status=close_window('',saveBufferPos,allowQuitIfHiddenWindowActive);
   } else {
      status=close_buffer(saveBufferPos,allowQuitIfHiddenWindowActive);
   }
#if 0
   if (bufid!=p_buf_id) {
      switch_buffer('', 'Q');
      //Dan added extra support for project toolbar
      //switch_buffer(buf_name, 'Q');
      //switch_buffer(p_buf_name, '');
   }
#endif

   _in_quit=false;
   return(status);
}

/**
 * <b>q</b> is a convenient shorthand for the {@link quit} command
 * for use from the command line.
 *
 * @param args    list of files to close, may contain wildcards
 *
 * @appliesTo  Edit_Window
 * @categories Buffer_Functions
 */
_command int q(_str args="") name_info(FILE_MAYBE_LIST_BINARIES_ARG'*,'VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // no arguments, just quit the current file
   if (args=="") {
      return quit();
   }

   // loop until we run out of arguments
   status := 0;
   while (args != '') {
      // next file argument
      f := parse_file(args);

      // assume it could be a wildcard and use insert_file_list()
      list_view_id := 0;
      int orig_view_id=_create_temp_view(list_view_id);
      if (orig_view_id=='') return(NOT_ENOUGH_MEMORY_RC);
      status=insert_file_list('-v +p 'f);
      if (status) {
         activate_window(orig_view_id);
         _delete_temp_view(list_view_id);
         continue;
      }

      // for each match
      top();
      for (;;) {
         // get the file name
         f = _lbget_text();
         if (f == '') break;

         // switch to that file if it's open already
         if (_iswindow_valid(orig_view_id)) {
            activate_window(orig_view_id);
         }
         status = edit("+b "_maybe_quote_filename(f));
         if (status == COMMAND_CANCELLED_RC) break;
         if (!status) {
            status = quit();
            if (status == COMMAND_CANCELLED_RC) break;
         }
         status=0;
         activate_window(list_view_id);

         // next please
         if (down()) break;
      }

      // restore the last window, if it is still valid
      // and wipe out the temp view
      if (_iswindow_valid(orig_view_id)) {
         activate_window(orig_view_id);
      }
      _delete_temp_view(list_view_id);

      // check if they cancelled at any point
      if (status == COMMAND_CANCELLED_RC) break;
   }

   // report error status
   if (status) {
      message(get_message(status));
      return status;
   }
   clear_message();
   return 0;
}


/**
 * Supported under Windows, Windows NT, and Windows 95/98.  When another
 * application wants to communicate with SlickEdit using DDE, the other
 * application should use the server name of SlickEdit, the system topic,
 * and call this command so that the command is invoked on the correct object.
 * The DDE command string:
 * <pre>
 *         '<b>dde -mdi -refresh edit c:\junk</b>'
 * </pre>
 * can be sent to SlickEdit to have SlickEdit open the file
 * "c:\junk".  The first instance of SlickEdit has the server AND
 * application window name "SlickEdit".  All instances of
 * SlickEdit that follow have the server and application window name
 * "SlickEdit Server <i>n</i>" where <i>n</i> starts at 1.  Invoke
 * SlickEdit with the +new option to create another instance.
 * The <b>editor_name</b> function may be used to get the server name.
 *
 * @param params
 * <i>   params</i> is a string in the format: [-mdi] [-refresh] [-multi] <i>command</i>
 * <p>
 * The switches have the following meaning:
 * <DL compact style="margin-left:20pt;">
 * <DT>-mdi</DT><DD>Invoke command on mdi edit window.</DD>
 * <DT>-refresh</DT><DD>Refresh the screen after the command is executed.  If
 * you do not specify this command, you will need to send the <b>dderefresh</b>
 * command after sending all dde commands to insure that the screen is correctly
 * updated.</DD>
 * <DT>-multi</DT><DD>Indicates that <i>command</i> contains multiple commands
 * separated with semicolons.</DD>
 * <DT>-cd <i>directory</i></DT><DD>Temporarily change the current directory to
 * <i>directory</i> when executing the command.</DD>
 *
 * @categories Miscellaneous_Functions
 */
_command dde(_str params='')
{
   // DWH 12:26:15 PM 8/9/2007
   // Any time we process a DDE message we need to reload the current buffers
   _ReloadFiles();

   multi := 0;
   activate_mdi := 0;
   do_refresh := 0;
   cur_dir := "";
   mdi_restore := 1;
   typeless option='';
   for (;;) {
      params=strip(params,'L');
      if (substr(params,1,1)!='-') break;
      parse params with option params;
      option=lowcase(option);
      switch (option) {
      case '-multi':
         multi=1;
         break;
      case '-mdi':
         activate_mdi=1;
         break;
      case '-r':
      case '-refresh':
         do_refresh=1;
         break;
      case '-cd':
         cur_dir=parse_file(params);
         break;
      case '-norestore':
         // Do not restore MDI frame
         mdi_restore = 0;
         break;
      }
   }
   if (activate_mdi) {
      // If there is a modal dialog box up
      if (!_mdi.p_enabled) return(1);
      p_window_id=_mdi.p_child;
      if (mdi_restore && _mdi.p_window_state=='I') {
         _mdi.p_window_state='R';
         //_mdi.p_window_state='N';
      }
   }
   orig_dir := "";
   if (cur_dir!='') {
      orig_dir=getcwd();
      cur_dir=strip(cur_dir,'B','"');
      chdir(cur_dir,1);
   }
   //status=0;
   //messageNwait('params='params);
   cmd := "";
   ext := "";
   qfilename := "";
   filename := "";
   typeless status=0;
   if (!multi) {
      _str directory_list[];
      //parse params with cmd qfilename;
      cmd=params;
      qfilename=parse_file(cmd);
      done := false;
      if ((qfilename=='e' || qfilename=='edit')) {
         _str temp=cmd;
         _getDirectoryListFromCmdline(temp,directory_list);
         qfilename=parse_file(cmd);
         if (qfilename=="-#") {
            qfilename=parse_file(cmd);
            if (lowcase(qfilename)=="+fn" || lowcase(qfilename)=="-fn") {
               params="e -# "cmd;
            } else {
               filename=strip(qfilename,'B','"');
               if (_is_workspace_filename(filename)) {
                  status=workspace_open(qfilename);
                  if (cmd=="") {
                     done=true;
                  } else {
                     params="edit -# "cmd;
                     // Don't try to support a workspace and directories
                     directory_list._makeempty();
                  }
               }
            }
         }
      }
      if (!done) {
         cwd:=getcwd();
         _str orig_workspace_filename=_workspace_filename;
         if (!directory_list._isempty()) {
            project_add_directory_folder(directory_list);
         }
         new_cwd:=getcwd();

         chdir(cwd,1);
         EditFlags old_def_edit_flags=def_edit_flags;
         def_edit_flags&=~(EDITFLAG_WORKSPACEFILES|EDITFLAG_BUFFERS);
         status=execute(params,"");
         def_edit_flags=old_def_edit_flags;

         // IF we opened a different workspace
         if (!file_eq(orig_workspace_filename,_workspace_filename)) {
            chdir(new_cwd,1);
            cur_dir=''; // don't restore original directory because we opened a project.
         }
      }
   } else {
      // When multiple commands are specified, opening directories isn't suipported yet.
      status=0;
      for (;;) {
         command := "";
         parse params with command ';' params;
         if (command=='') break;
         EditFlags old_def_edit_flags=def_edit_flags;
         def_edit_flags&=~(EDITFLAG_WORKSPACEFILES|EDITFLAG_BUFFERS);
         status=execute(command,"");
         def_edit_flags=old_def_edit_flags;
      }
   }
   if (cur_dir!='' && !def_switchbuf_cd) {
      int cd_status = chdir(orig_dir,1);
      if (!cd_status) {
         call_list('_cd_',getcwd());
      }
   }
   if (do_refresh) {
      refresh();
      int mdi_wid=_MDICurrent();
      // Need on Windows. Not sure about Unix
      // Windows seems to active the parent window after
      if (!mdi_wid) {
         mdi_wid=_mdi;
      }
      mdi_wid._set_foreground_window();
   }
   return(status);

}


/**
 * Executes the <b>refresh</b> function to update the editor screen
 * after multiple DDE commands have been sent to the editor from another
 * application.
 * @categories Miscellaneous_Functions
 */
_command void dderefresh()
{
   refresh();
}

static bool in_actapp_files = false;
bool _InActAppFiles(typeless new_value=null)
{
   if ( new_value != null ) {
      in_actapp_files = new_value != 0;
   }
   return in_actapp_files;
}

// Table of files to never reload
static _str gDoNotReloadFiles:[]=null;

definit()
{
   gorig_def_actapp= -1;
   def_actapp_stack._makeempty();
   _filepos_view_id=0;
   in_actapp_files=false;
   gbatch_call_list_timer = -1;
   gbatch_call_list_count = null;
   gbatch_call_list_arg = null;
   gcall_list_indexes._makeempty();
   gDoNotReloadFiles = null;
   gReloadBufIdList._makeempty();
   gReloadFileTimerID = -1;
}

void _on_load_module_call_list()
{
   gcall_list_indexes._makeempty();
}
void call_list_reset_cache() {
   gcall_list_indexes._makeempty();
}
static bool all_indexes_callable(int (&idx_list)[]) {
   foreach (auto index in idx_list) {
      if (!index_callable(index)) {
         return false;
      }
   }
   return true;
}

/**
 * Calls all non-built-in Slick-C&reg; functions whose name has prefix <i>prefix_name</i>.
 * The arguments <i>arg1</i>, <i>arg2</i>, <i>arg3</i>, and <i>arg4</i> are passed to the
 * procedure as arguments 1-4 respectively.
 *
 *
 * @categories Miscellaneous_Functions
 */
void call_list(_str prefix_name, ...)
{
   //say("call_list H"__LINE__": prefix="prefix_name);
   orig_view_id := 0;
   get_window_id(orig_view_id);

   // get the list of macro functions associated with this prefix
   index := 0;
   int idx_list[];
   int (*pidx_list)[];
   pidx_list=gcall_list_indexes._indexin(prefix_name);
   if (pidx_list && all_indexes_callable(*pidx_list)) {
      idx_list = *pidx_list;
   } else {
      max := _default_option(VSOPTION_WARNING_ARRAY_SIZE);
      index = name_match(prefix_name,1,PROC_TYPE);
      for (;;) {
         if ( !index ) { break; }
         if ( index_callable(index) ) {
            if (idx_list._length() >= max) {
               break;
            }
            idx_list :+= index;
         }
         index = name_match(prefix_name,0,PROC_TYPE);
      }
      gcall_list_indexes:[prefix_name] = idx_list;
   }

   // now call each of them
   switch (arg()) {
   case 1:
      foreach (index in idx_list) {
         call_index(index);
      }
      break;
   case 2:
      foreach (index in idx_list) {
         call_index(arg(2),index);
      }
      break;
   case 3:
      foreach (index in idx_list) {
         call_index(arg(2),arg(3),index);
      }
      break;
   case 4:
      foreach (index in idx_list) {
         call_index(arg(2),arg(3),arg(4),index);
      }
      break;
   case 5:
      foreach (index in idx_list) {
         call_index(arg(2),arg(3),arg(4),arg(5),index);
      }
      break;
   case 6:
      foreach (index in idx_list) {
         call_index(arg(2),arg(3),arg(4),arg(5),arg(6),index);
      }
      break;
   case 7:
      foreach (index in idx_list) {
         call_index(arg(2),arg(3),arg(4),arg(5),arg(6),arg(7),index);
      }
      break;
   case 8:
      foreach (index in idx_list) {
         call_index(arg(2),arg(3),arg(4),arg(5),arg(6),arg(7),arg(8),index);
      }
      break;
   }

   // restore to the original window, in case it changed
   if ( _iswindow_valid(orig_view_id) ) {
      activate_window(orig_view_id);
   }
}

_command void auto_reload() name_info(','VSARG2_EDITORCTL)
{
   _on_activate_app(1);
}
/**
 * This function gets called with a send message and is not allowed
 * to display a message box.  This is used to support updating the
 * java gui builder files only.
 */
void _on_activate_app2()
{
   return;
#if 0
   /*
     If the "if (!def_actapp)" below is removed, a fix will be need to
     handle a problem where "Add new gui item" to project does NOT tag the new
     java file.
   */
   if (!def_actapp) {
      //say('skipping '_on_activate_app2);
      return;
   }
   if (!jguiIsConnected(true)) {
      return;
   }

   _open_temp_view("",actapp_view_id,orig_view_id,"+bi "RETRIEVE_BUF_ID);
   first_buf_id=p_buf_id;
   for (;;) {
      noption='N';
      if ((!(p_buf_flags & VSBUFFLAG_HIDDEN) || p_AllowSave) && p_LangId=='java' &&
          _jguiIsBufferValid()) {
//         say('buf_name='p_buf_name);
         temp_view_id=_list_bwindow_pos(p_buf_id);
         status=jguiSendGetFileInfo("GetFileInfoIF");
         if (status) {
            //gjguiSkipBufIdList[gjguiSkipBufIdList._length()]=p_buf_id;
            if (status==1) {
               _set_bwindow_pos(temp_view_id);
            }
         }
         if (temp_view_id) {
            _delete_temp_view(temp_view_id);
         }
      }
      _next_buffer(noption'RH');
      if (p_buf_id==first_buf_id) {
         break;
      }
   }
   _delete_temp_view(actapp_view_id);
   activate_window(orig_view_id);
#endif
}
void _on_activate_app(typeless gettingFocus='')
{
   // IF application got focus
   if (gettingFocus) {
      _tbSetRefreshBy(VSTBREFRESHBY_APPLICATION_GOT_FOCUS);
   }
   call_list('_actapp_', gettingFocus);
}
static void _start_undo_step()
{
   int i;
   for (i=1;i<_last_window_id();++i) {
      if (_iswindow_valid(i) && i.p_HasBuffer && !i.p_IsMinimap) {
         i._undo('s');
      }
   }
}
_str def_vcpp_save;
static int InRecursion=0;

/** 
 * Files that we have already warned the user are slow and will 
 * not be reloaded 
 */
static _str gWarnedSlowFiles:[]=null;

int def_never_reload_flags=0;
/** 
 * Remove the name of the file being closed from the 
 * gWarnedSlowFiles table.  This is so they will be warned again 
 * if they reopen the file
 */
void _cbquit_auto_reload (int bufID, _str filename, _str docname= '', int flags = 0)
{
   // remove the buffer id from the list of files to reload
   for (i:=0; i<gReloadBufIdList._length(); i++) {
      if (gReloadBufIdList[i] == bufID) {
         gReloadBufIdList._deleteel(i);
      }
   }

   casedFilename := _file_case(filename);
   // If we close a file in the slow file list, take it out
   if ( gWarnedSlowFiles._indexin(casedFilename) ) {
      gWarnedSlowFiles._deleteel(casedFilename);
   }
   /* Seems like a better idea to keep the Never Reload table
      entries until you restart. That way, if you change workspaces
      and the same buffer is open, you don't get prompted.

      def_never_reload_flags defaults to 0
   */ 
   if (def_never_reload_flags&1) {
      if ( gDoNotReloadFiles._indexin(casedFilename) ) {
         gDoNotReloadFiles._deleteel(casedFilename);
      }
   }
}

#if 1 /* __MACOSX__ */
/**
 * Exported from the macutils library. Used to notify external 
 * editors that SlickEdit is done editing a file, for ODB Editor 
 * suite implementation. 
 */
void macFileQuit(_str filePath);

int _cbquit2_mac(int buf_id,_str buf_name,_str document_name,int buf_flags)
{
   if (!_isMac()) {
      return 0;
   }
   macFileQuit(buf_name);
   return 0;
}
#endif

/**
 * Find out if we should compare the current buffer's contents
 * to the last version in backup history to verify that the file
 * actually changed before prompting about auto reload.
 *
 * @return true if we should compare the whole file if the dates
 *         match
 */
static bool useWholeFileCompare()
{
   return (def_autoreload_compare_contents &&
           p_file_size<=def_autoreload_compare_contents_max_ksize*1024);
}

/**
 * Unlike _ReloadCurFile, this function does not prompting 
 * before reloading the file. 
 *  
 * @param loadOptions
 * @param SrcFilename
 * @param bfiledate
 * @param actapp_view_id
 * @param encoding_set_by_user
 * 
 * @return Returns 0 if successful.
 */
int _ReloadCurFile2(_str loadOptions="",_str SrcFilename=null,_str bfiledate='',int actapp_view_id=p_window_id,int encoding_set_by_user=p_encoding_set_by_user) {
   orig_view_id:=p_window_id;
   /* Make a view&buffer windows list which contains window and position info. */
   /* for all windows. */
   activate_window(actapp_view_id);
   orig_buf_name := actapp_view_id.p_buf_name;

   if (SrcFilename==null) {
      SrcFilename=p_buf_name;
   }
   _str doc_name=p_DocumentName;
   if (doc_name=="") {
      doc_name=p_buf_name;
   }
   typeless p;
   save_pos(p,'L');
   temp_view_id:=_list_bwindow_pos(p_buf_id);
   // Use def_load_options for network,spill, and undo options. */

   // save bookmark, breakpoint, and annotation information
   _SaveMarkersInFile(auto markerSaves);

   // These get reset by load_files.
   applied_af_flags := p_adaptive_formatting_flags;
   status:=load_files(build_load_options(p_buf_name):+' +q +d  +r ':+loadOptions' ':+_maybe_quote_filename(SrcFilename));
   if (status) {
      if (status==NEW_FILE_RC) {
         status=FILE_NOT_FOUND_RC;
         _delete_buffer();
      }
      activate_window(orig_view_id);_set_focus();
      _message_box(nls("Unable to reload %s",doc_name)"\n\n"get_message(status));
   } else {
      // Just in case this file has really long lines,
      // temporarily turn off softwrap to improve performance a ton.
      orig_SoftWrap:=p_SoftWrap;
      p_SoftWrap=false;
      // This will need to be restored to the original name for cases where p_buf_name != SrcFilename.
      // This happens when mfundo is restoring a file.
      p_buf_name=orig_buf_name;
      p_encoding_set_by_user=encoding_set_by_user;
      if (bfiledate=='' || bfiledate==0) {
         bfiledate=_file_date(p_buf_name,'B');
      }
      if (bfiledate!='' && bfiledate!=0) {
         p_file_date=(long)bfiledate;
      }
      restore_pos(p);
      lang:=p_LangId;
      large_file_editing_msg := "";
      if (p_buf_size>def_use_fundamental_mode_ksize*1024) {
         if (lang!="fundamental" && lang!="") {
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
      if (p_SoftWrap && p_buf_size>def_use_softwrap_ksize*1024) {
         if (large_file_editing_msg) {
            large_file_editing_msg:+="\n";
         } 
         large_file_editing_msg:+="view line numbers turned off for better performance";
         p_SoftWrap=false;
         orig_SoftWrap=false;
      }
      if (large_file_editing_msg!="") {
         //say(large_file_editing_msg);
         _ActivateAlert(ALERT_GRP_EDITING_ALERTS,ALERT_LARGE_FILE_SUPPORT,large_file_editing_msg);
         //sticky_message(msg);
      }
      // Need to do an add buffer here so the debugging
      // information is updated.
      // load_files with +r options calls the delete buffer
      // callback.  Here we readd this buffer.
      call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
      call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);

      // restore bookmarks, breakpoints, and annotation locations
      _RestoreMmrkersInFile(markerSaves);

      // clear highlights
      clear_highlights();

      _set_bwindow_pos(temp_view_id);

      // reset any settings set by adaptive formatting.
      adaptive_format_reset_buffers(applied_af_flags);

      p_SoftWrap=orig_SoftWrap;
   }
   if (temp_view_id) {
      _delete_temp_view(temp_view_id);
   }


   return status;
}

/**
 * Reload the current open file from disk, prompting if necessary.
 *
 * @param actapp_view_id            View id from calling actapp function.
 * @param bfiledate                 Datestamp of file on disk.
 * @param allowPrompting            Prompt to auto-reload?
 * @param allowEditFromJGUI         Allow editing from Java Gui Builder?
 * @param SrcBufName                Optionally specifies a different file to
 *                                  replace the current file with.
 * @param forcePromptingIfModified  Prompt to auto-reload if modified
 *                                  even if allowPrompting==false
 *
 * @return true if we should not allow further prompting, that is,
 *         if they hit "Yes to All".
 */
bool _ReloadCurFile(int actapp_view_id, _str bfiledate,
                       bool allowPrompting=true,
                       bool allowEditFromJGUI=true, _str SrcFilename=null,
                       bool forcePromptingIfModified=true,
                       int &reloadStatus=0)
{
   was_hex := p_hex_mode==HM_HEX_ON;
   int temp_view_id;
   if (was_hex) {
      temp_view_id=_list_bwindow_pos(p_buf_id);
      p_modify=false;
      hex();
   }
   result:=_ReloadCurFile3(actapp_view_id,bfiledate,allowPrompting,allowEditFromJGUI,SrcFilename,forcePromptingIfModified, reloadStatus);
   if (was_hex) {
      actapp_view_id.hex();
      _set_bwindow_pos(temp_view_id);
      if (temp_view_id) {
         _delete_temp_view(temp_view_id);
      }
   }
   return result;
}
static bool _ReloadCurFile3(int actapp_view_id, _str bfiledate,
                       bool allowPrompting=true,
                       bool allowEditFromJGUI=true, _str SrcFilename=null,
                       bool forcePromptingIfModified=true,
                       int &reloadStatus=0)
{
   reloadStatus = 0;
   int orig_view_id=_mdi;
   options := "";
   if (p_buf_width==1) {
      options='+LW';
   } else if (p_buf_width) {
      options='+'p_buf_width;
   }
   encoding_set_by_user := -1;
   encoding_str := "";
   // We could be fancier here with restoring the binary property but
   // the encoding dialogs don't support the binary option with encodings
   // like Utf-16 yet. If it ever does, this should be a check box
   if(p_binary==1 && p_encoding==0) {
      encoding_str:+='+lb ';
   } else if(p_binary==2 && (p_encoding==VSENCODING_UTF8 || p_encoding==VSENCODING_UTF8_WITH_SIGNATURE)) {
      encoding_str:+='+l8 ';
   }
   if (p_hex_mode &&  (p_hex_mode_reload_encoding || p_hex_mode_reload_buf_width))  { 
      // Line hex mode uses whatever settings we see.
      // hex mode nees to us <LF>
      if (p_hex_mode==HM_HEX_ON) {
         encoding_str:+='+fu ';
      }
   } else {
      _str orig_encoding_str=encoding_str;
      encoding_str:+=_load_option_encoding(p_buf_name);
      //say('lo encoding_str='encoding_str);
      // IF the user has overriden default encoding recognition  AND
      //
      if (p_encoding_set_by_user!= -1) {
         int encoding;
         if (p_encoding_set_by_user==VSENCODING_AUTOUNICODE || p_encoding_set_by_user==VSENCODING_AUTOXML ||
             p_encoding_set_by_user==VSENCODING_AUTOUNICODE2 ||
             p_encoding_set_by_user==VSENCODING_AUTOEBCDIC || p_encoding_set_by_user==VSENCODING_AUTOEBCDIC_AND_UNICODE ||
             p_encoding_set_by_user==VSENCODING_AUTOEBCDIC_AND_UNICODE2
                ) {
            // The user chose some specific automatic processing.
            // Just reuse it.
            encoding_set_by_user=encoding=p_encoding_set_by_user;
         } else if (_last_char(_EncodingToOption(p_encoding))=='s') {
            // The current file has a signature. Automatic processing will
            // redetect this file and we can enhance this by automatically detecting
            // signatures.
            // Smarten what the user has requisted
            // WARNING: This won't work if the user removes the signature in
            // another application and then switches back.
            encoding_set_by_user=encoding=VSENCODING_AUTOUNICODE;
         } else {
            // No signature, must assume the user knows best.
            encoding_set_by_user=encoding=p_encoding_set_by_user;
         }
         encoding_str=orig_encoding_str:+_EncodingToOption(encoding);
      }

   }
   //say('ar: e_set_by_user='encoding_set_by_user);
   //say('ar: encoding_str='encoding_str);
   options :+= ' 'encoding_str;
   _str doc_name=p_DocumentName;
   if (doc_name=="") {
      doc_name=p_buf_name;
   }
   modify := p_modify;


   activate_window(orig_view_id);_set_focus();

   //disabled_wid_list=_enable_non_modal_forms(0,_mdi);
   int result=IDYES;
   reset_modified := false;
   // IF no reload prompt
   if ((def_actapp&ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED) || !allowPrompting) {
      if (modify && forcePromptingIfModified) {
         result = show('-modal _auto_file_reload_form', doc_name);
      }
   } else {
      if (_isWindows()) {
         if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
            if (_mdi.p_window_state=='I') {
               _mdi.p_window_state='R';
            }
         }
      }
      // IF user only wants to be warned if buffer is modified
      if (( def_actapp & ACTAPP_WARNONLYIFBUFFERMODIFIED)) {
         if (modify) {
            //result=_message_box(nls("Another application has modified the file\n\n '%s'\n\nwhich you have modified.  Do you want to reload it?\n\nThe command \"set-var def_sbwarn_reload_modify 0\" will avoid this message box.",doc_name),'',MB_YESNOCANCEL|MB_ICONQUESTION);
            result = show ('-modal _auto_file_reload_form', doc_name);
         }
      } else {
         ignoreTouchedFile := false;
         if ( useWholeFileCompare() ) {
            wholeFileCompare(ignoreTouchedFile);
            if ( !ignoreTouchedFile ) {
               result = show ('-modal _auto_file_reload_form', doc_name);
            }
         }
      }
   }
   //_enable_non_modal_forms(1,0,disabled_wid_list);
   typeless status=0;
   activate_window(orig_view_id);

   if (result==IDYES || result==IDYESTOALL) {
      reloadStatus = _ReloadCurFile2(options,SrcFilename,bfiledate,actapp_view_id,encoding_set_by_user);
   } else {
      activate_window(actapp_view_id);
      p_file_date=(long)bfiledate;
      if (result == IDDIFFFILE) {
         _DiffModal('-r2 -b1 -d2 '_maybe_quote_filename(doc_name)' '_maybe_quote_filename(doc_name));
      }
      activate_window(actapp_view_id);
      if (reset_modified) {
         p_modify = modify;
      } else {
         p_modify=true;
      }
   }
   // return true if they hit yes-to-all
   return (result==IDYESTOALL);
}

/**
 * @param allowPrompting If true, allow the user to be promted 
 *                       to reload/close files
 * @param bufIdList If not null, limit the files that reloaded 
 *                  to the buffer IDs in this list
 * @param pFastReloadTable Table indexed by filename that is 
 *                         returned by _GetFastReloadInfoTable.
 *                         If this is null,
 *                         _GetFastReloadInfoTable will be
 *                         called to retrieve the information
 * @param reloadThreshold Amount of time in miliseconds to wait 
 *                        on a file before marking it as slow
 *                        and refusing to ever reload it.
 */
void _ReloadFiles(bool allowPrompting=true, int (*bufIdList)[]=null,
                  AUTORELOAD_FILE_INFO (*pFastReloadTable):[]=null,
                  int reloadThreshold=def_autoreload_timeout_threshold)
{
   //say("_ReloadFiles H"__LINE__": HERE");
   //if (bufIdList) {
   //   _dump_var(*bufIdList, "_ReloadFiles H"__LINE__": bufIdList");
   //}
   if (!def_batch_reload_files) {
      _OldReloadFiles(allowPrompting, bufIdList);
      return;
   }
   _str bufferIDs[];
   _str modFileNames:[];
   _str delFileNames:[];
   _str modBufNames:[];

   numFound := findModifiedAndDeleted(bufferIDs, modFileNames, delFileNames, modBufNames, bufIdList,-1,pFastReloadTable,reloadThreshold);

   // If they were only reloading a subset of files, but one one modified, then
   // we should check all the buffers for reload.
   if (numFound > 0 && bufIdList != null && bufIdList->_length()==1 &&
       (def_actapp & ACTAPP_TEST_ALL_IF_CURRENT_MODIFIED)) {
      numFound = findModifiedAndDeleted(bufferIDs, modFileNames, delFileNames, modBufNames, null, (*bufIdList)[0],pFastReloadTable,reloadThreshold);
   }

   int i;
   int j;
   int status;

   _str reloadBufIDs[];
   _str reloadBufNames[];
   int reloadBitmaps[];
   int reloadOverlays[];
   bool reloadSelectArray[];
   _str delBufNames[];
   int delBitmaps[];
   bool delSelectArray[];

   for (i = 0; i < bufferIDs._length(); ++i) {
      if (modFileNames._indexin(i)) { // Modified on disk
         j = reloadBufIDs._length();
         reloadBufIDs[j] = bufferIDs[i];
         reloadBufNames[j] = modFileNames:[i];
         if (modBufNames._indexin(modFileNames:[i])) { // ... and in buffer.
            reloadBitmaps[j] = _pic_file;
            reloadOverlays[j] = _pic_file_mod_overlay;
            reloadSelectArray[j] = false;
         } else {
            reloadBitmaps[j] = _pic_file;
            reloadOverlays[j] = _pic_file_reload_overlay;
            reloadSelectArray[j] = true;
         }
      } else if (delFileNames._indexin(i)) { // Deleted on disk.
         j = delBufNames._length();
         delBufNames[j] = delFileNames:[i];
         delBitmaps[j] = _pic_file_del;
         delSelectArray[j] = true;
      }
   }

   int flags = SL_CHECKLIST |
               SL_DESELECTALL |
               SL_COLWIDTH |
               SL_INVERT |
               SL_SELECTALL |
               SL_DELETEBUTTON |
               SL_USE_OVERLAYS |
               SL_MUSTEXIST |
               SL_DEFAULTCALLBACK;
   INTARRAY removeIndexList;
   for (i = 0; i < reloadBufNames._length(); ++i) {
      if ( gDoNotReloadFiles._indexin(_file_case(reloadBufNames[i])) ) {
         ARRAY_APPEND(removeIndexList,i);
      }
   }
   len := removeIndexList._length();
   // Remove never reload files
   for (i = len-1;i>=0;--i) {
      reloadBufNames._deleteel(removeIndexList[i]);
      reloadBufIDs._deleteel(removeIndexList[i]);
      reloadBitmaps._deleteel(removeIndexList[i]);
      reloadOverlays._deleteel(removeIndexList[i]);
      reloadSelectArray._deleteel(removeIndexList[i]);
   }
   if (reloadBufNames._length() > 0) {
      if (_isWindows()) {
         if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
            if (_mdi.p_window_state=='I') {
               _mdi.p_window_state='R';
            }
         }
      }
      /*
        Try to display this dialog centered to the active MDI window. That way,
        the edit window with focus, gets focus when we close this dialog.

        Unfortuantely, this does not work for floating tool windows which
        could have been active when focus was switched away from slickedit. 
        Need a more complete "_CurrentShellWindow" function.
      */
      int wid=_MDICurrent();
      if (!wid || wid==_mdi) {
         wid=p_window_id;
      }
      _str reloadResult=wid.select_tree(reloadBufNames, reloadBufIDs, reloadBitmaps,
                                        reloadOverlays, reloadSelectArray, reload_modified_cb,
                                        // Pass SL_ADDBUTTON flag so ctl_message doesn't end up overlapping ctladd_item
                                        '', "Reload Modified Files", flags|SL_ADDBUTTON, 'File',
                                        TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_FILENAME,
                                        true, 'auto reload');

      if (reloadResult != COMMAND_CANCELLED_RC) {

         _str reloadFileID;
         typeless bfiledate;
         int temp_wid;
         int orig_wid;
         reloadResult = ' 'stranslate(reloadResult,' ',"\n")' ';
   
         // Freshen the file date for all buffers that have been modified, so the
         // dialog doesn't keep popping up if the user cancelled it the first time.
         //
         // Reload the files that the user has indicated should be reloaded.
         for (i = 0; i < reloadBufNames._length(); ++i) {
            _MaybeUpdateUserOptions(reloadBufNames[i]);
            bfiledate = _file_date(reloadBufNames[i], 'B');
            temp_wid = 0;
            orig_wid = 0;
            status = _open_temp_view('', temp_wid, orig_wid, "+bi "(int)reloadBufIDs[i]);
            if (status == 0) {
               if (pos(' 'reloadBufIDs[i]' ', reloadResult)) { // User chose to reload this one
                  _ReloadCurFile(temp_wid, bfiledate, false, true, null, false);
                  if ( temp_wid.useWholeFileCompare() && _haveBackupHistory() && DSBackupVersionExists(reloadBufNames[i]) ) {
                     status = temp_wid.DS_CreateDelta(reloadBufNames[i]);
                     if ( !status ) {
                        DSSetVersionComment(reloadBufNames[i], -1, "Created by Auto Reload.");
                     }
                  }
               }
               if (bfiledate!='' && bfiledate!=0) {
                  temp_wid.p_file_date = (long)bfiledate;
               }
               temp_wid.p_file_size = _file_size(reloadBufNames[i]);
               _delete_temp_view(temp_wid);
               if (_iswindow_valid(orig_wid)) {
                  activate_window(orig_wid);
               }
            }
         }
      }
   }

   if (delBufNames._length() > 0) {
      if (_isWindows()) {
         if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
            if (_mdi.p_window_state=='I') {
               _mdi.p_window_state='R';
            }
         }
      }
      _str saveResult = select_tree(delBufNames, null, delBitmaps,
                                    null, delSelectArray, save_deleted_cb,
                                    '', "Save Deleted Files", flags, 'File',
                                    TREE_BUTTON_PUSHBUTTON|\
                                    TREE_BUTTON_SORT_FILENAME,
                                    true, 'auto reload');

      if (saveResult == COMMAND_CANCELLED_RC ) return;
         
      _str saveFile;
      while (saveResult != '') {
         parse saveResult with saveFile "\n" saveResult;
         saveFile = _maybe_quote_filename(saveFile);
         _save_non_active(saveFile, false, 0);
      }
   }
}


/**
 * Reload all open files if modified on disk, prompting if necessary,
 * according to def_actapp settings.
 * <p>
 * Note: <br>
 * If ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED is set in def_actapp, 
 * then the user is never prompted, regardless of how 
 * allowPrompting is set. 
 *
 * @param allowPrompting (optional). Set to false if you do not want
 *                       user prompted to reload file from disk.
 *                       Defaults to true.
 * @param bufIdList      (optional). Pointer to an array of buf ids to check.
 *                       If null, then all open files are checked.
 *                       Defaults to null.
 */
void _OldReloadFiles(bool allowPrompting=true, int (*bufIdList)[]=null)
{
   // RGH - 5/22/2006
   // We don't want to do the SE reload files for the plugin
   // because Eclipse does this for us: see _actapp_files
   if (isEclipsePlugin()) {
      return;
   }

   // DWH 12:11:52 PM 8/9/2007
   // Shut off auto reload.  We are reloading the files already and
   // if auto reload is triggered in the middle of _ReloadFiles it
   // can cause all of the buffers not to be reloaded.
   _push_def_actapp(def_actapp & ~ACTAPP_AUTORELOADON);

   int temp_wid, orig_wid;
   _open_temp_view("",temp_wid,orig_wid,"+bi "RETRIEVE_BUF_ID);
   int bufIds[] = null;
   if( bufIdList ) {
      bufIds= *bufIdList;
   } else {
      int first_buf_id = p_buf_id;
      for( ;; ) {
         noption := 'N';
         if( (!(p_buf_flags & VSBUFFLAG_HIDDEN) || p_AllowSave) && p_file_date!="" && p_file_date!=0 ) {
            bufIds[bufIds._length()]=p_buf_id;
         }
         _next_buffer(noption'RH');
         if( p_buf_id==first_buf_id ) {
            break;
         }
      }
   }
   _str closeFileList[]=null;
   int i;
   for( i=0; i<bufIds._length(); ++i ) {
      activate_window(temp_wid);
      int status = load_files('+q +bi 'bufIds[i]);
      if( status!=0 ) {
         // This should never happen, we just got the buffer id
         continue;
      }
      _MaybeUpdateUserOptions(p_buf_name);
      _str bfiledate = _file_date(p_buf_name,'B');
      if (bfiledate == "" || bfiledate==0) { //If there is no file on disk ...
         if ((p_file_date != "" && p_file_date != 0) &&
             !(p_buf_flags & VSBUFFLAG_PROMPT_REPLACE) &&
             _HaveValidOuputFileName(p_buf_name)) { //but we're editing one (so not creating a new file).
            p_modify = true;
            status = show("-modal _auto_file_deleted_form", p_buf_name);
            if (status == IDYES) {
               save();
            } else if (status == IDCLOSE) {
               p_modify = false;
               // DWH 10-26-2006
               // Cannot  call _save_non_active here because we have a temp
               // view of the file open right now
               closeFileList[closeFileList._length()]=p_buf_name;
            }
         }
      } else if( p_file_date:!=bfiledate && !_FileIsRemote(p_buf_name)) {
         if( _ReloadCurFile(temp_wid,bfiledate,allowPrompting) ) {
            allowPrompting=false;
         }
         activate_window(temp_wid);
      }
   }
   _delete_temp_view(temp_wid);
   len := closeFileList._length();
   for (i=0;i<len;++i) {
      // DWH 10-26-2006 moved this from inside the loop
      // DJB 08-24-2006
      // Use _save_non_active() to close the buffer,
      // which is more consistent with what other parts of
      // the editor does.
      _save_non_active(closeFileList[i], true, 0);
   }
   if (_iswindow_valid(orig_wid)) {
      activate_window(orig_wid);
   }

   // DWH 12:11:52 PM 8/9/2007
   // Restore settings saved near top of function
   _pop_def_actapp();
}

#define FILES_TESTING_RELOAD_CHANGES 0
#define FILES_TIMING_AUTO_RELOAD     0
#define FILES_TIMING_ACTAPP          0


void _autoReloadAndReadOnly(int dpRunning=0)
{
   if (dpRunning) {
      _push_def_actapp(def_actapp);
   }
   // Check now to see if any files will time out. We check here because we will
   // want to avoid both _ReloadFiles and maybe_set_readonly
   currentFileOnly := (def_actapp & ACTAPP_CURRENT_FILE_ONLY) != 0;

#if FILES_TIMING_AUTO_RELOAD
   t1 := _time('b');
#endif

   // Get this information here because we will pass it to both 
   // setBufferReadonlyStatuses and _ReloadFiles
   AUTORELOAD_FILE_INFO fastReloadInfoTable:[];
   getFastReloadInfoTable(fastReloadInfoTable,def_actapp&ACTAPP_AUTOREADONLY,def_fast_auto_readonly,def_autoreload_timeout_threshold);

#if FILES_TIMING_AUTO_RELOAD
   t10 := _time('b');
   say('_actapp_files getFastReloadInfoTable time='(int)t10-(int)t1);
#endif

   if ( (def_actapp&ACTAPP_AUTOREADONLY) && !_default_option(VSOPTION_FORCERO) ) {
      doAutoReadOnly(fastReloadInfoTable);
   }
   if ( dpRunning ) def_actapp = def_actapp | ACTAPP_WARNONLYIFBUFFERMODIFIED;

#if FILES_TIMING_AUTO_RELOAD
   t50 := _time('b');
   say('_actapp_files doAutoReadOnly time='(int)t50-(int)t10);
#endif

   if (!_no_child_windows() && currentFileOnly) {
      int bufIdList[]; bufIdList._makeempty();

      bufIdList[0] = _mdi.p_child.p_buf_id;
      _ReloadFiles(true,&bufIdList,&fastReloadInfoTable,def_autoreload_timeout_threshold);
   }else if ( fastReloadInfoTable._length()!=0 ) {
      _ReloadFiles(true,null,&fastReloadInfoTable,def_autoreload_timeout_threshold);
   }

#if FILES_TIMING_AUTO_RELOAD
   t100 := _time('b');
   say('_actapp_files _ReloadFiles time='(int)t100-(int)t50);
#endif

   if ( def_autoreload_timeout_notifications ) {
      showSlowFileNotification();
   }

#if FILES_TIMING_AUTO_RELOAD
   t110 := _time('b');
   say('_actapp_files showSlowFileNotification time='(int)t110-(int)t100);
#endif
   if ( dpRunning ) {
      _pop_def_actapp();
   }
}

void _actapp_files(_str gettingFocus="")
{
#if FILES_TIMING_AUTO_RELOAD || FILES_TIMING_ACTAPP
   t0 := _time('b');
#endif
   if (!gettingFocus && !def_actapp) {
      return;
   }

   if (in_actapp_files) {
      return;
   }
   // We do not want to refresh files if we are running as the
   // Eclipse plug-in because Eclipse already does this for us
   //
   if (isEclipsePlugin()) {
      return;
   }
   _terminate_hover_over_popup();

   if (def_exit_flags & SAVE_CONFIG_IMMEDIATELY_SHARE_CONFIG) {
      path:=_ConfigPath();
      filename_no_quotes:=path:+VSCFGFILE_USER;
      if (_config_file_changed(filename_no_quotes)) {
         //say('reload 'filename_no_quotes);
         plugin_reload_user_config();
      }
      filename_no_quotes = path:+_getUserSysFileName():+_macro_ext;
      if (_config_file_changed(filename_no_quotes)) {
         //say('apply 'filename_no_quotes);
         shell(_maybe_quote_filename(filename_no_quotes));
      }

      filename_no_quotes = path:+USERMACS_FILE:+_macro_ext;
      if (_config_file_changed(filename_no_quotes)) {
         //say('apply 'filename_no_quotes);
         _reload_usermacs(filename_no_quotes);
      }

      filename_no_quotes=path:+USEROBJS_FILE:+_macro_ext;
      filename:=_maybe_quote_filename(filename_no_quotes);
      if (_config_file_changed(filename_no_quotes)) {
         //say('apply 'filename_no_quotes);
         if(_default_option(VSOPTION_LOAD_PLUGINS)) {
            shell("updateobjs ":+filename);
            // now run vusrobjs
            shell(filename);
         }
      }
   }


   in_actapp_files=true;
   VCPPSaveFilesArg := 'N';
   Hunt := "";
   parse def_vcpp_save with VCPPSaveFilesArg Hunt .;
   if (!gettingFocus) {
      // Must close open BSC file in case users build in VC++
      tag_close_bsc();
      if ( index_callable(find_index("delphiIsRunning",PROC_TYPE)) ) {
         if ( delphiIsRunning() ) {
            //dprint( "VSE: Deactivated..." );
            //sticky_message( "VSE: Deactivated..." );
            delphi1AppDeactivate();
            delphiAppDeactivate();
         }
      }
      if (def_actapp&ACTAPP_SAVEALLONLOSTFOCUS) {
         _start_undo_step();
         _mdi.p_child.save_all(SV_QUIET|SV_RETURNSTATUS);
      }
      if (def_hidetoolbars) {
         _tbVisible(false);
         tw_all_floating_set_visible(false);
      }
      if (machine()=='WINDOWS') {
         //This code is out here in case the user save the file in SlickEdit
         //and it is not actually modified
         //VCPPSaveFiles(VCPPSaveFilesArg);
         if (Hunt=='Y') {
            HuntForVCPPMessageBox();
         }
      }
      in_actapp_files=false;
      return;
   }
   int dpRunning;
   dpRunning = 0;
   if ( index_callable(find_index("delphiIsRunning",PROC_TYPE)) ) {
      if ( delphiIsRunning() ) {
         //dprint( "VSE: Activated..." );
         //sticky_message( "VSE: Activated..." );
         delphi1AppActivate();
         delphiAppActivate();
         dpRunning = 1;
      }
   }
   if ( def_hidetoolbars ) {
      _tbVisible(true);
      tw_all_floating_set_visible(true);
   }
   if (!(def_actapp&ACTAPP_AUTORELOADON)) {
      in_actapp_files=false;
      return;
   }

   _autoReloadAndReadOnly(dpRunning);

   int orig_wid;
   get_window_id(orig_wid);
   in_actapp_files=false;
   if (machine()=='WINDOWS' && _haveBuild()) {
      //This calls the code to force VC++ to save the files
      if (VCPPSaveFilesArg!='N') {
         if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_VCPP_SETUP)) {
            int callable=index_callable(find_index('VCPPIsUp',PROC_TYPE));
            isup := 0;
            if (!InRecursion && callable && !DllIsMissing('vchack.dll') ) {
               isup=VCPPIsUp(def_vcpp_version);
            }
            if (isup) {
               InRecursion=1;
               index := find_index('VCPPSaveFiles',PROC_TYPE);
               if (index) {
                  _post_call(index,VCPPSaveFilesArg"\1"def_vcpp_version);
                  _post_call(_actapp_files);
               }
            } else {
               InRecursion=0;
            }
         }
      }
   }
   activate_window(orig_wid);

#if FILES_TIMING_AUTO_RELOAD || FILES_TIMING_ACTAPP
   t200 := _time('b');
   say('_actapp_files total time='(int)t200-(int)t0);
#endif
}

/** 
 * Set the read only status to match the file on disk (auto 
 * readonly).  Uses the <B>def_fast_auto_readonly</B> variable.
 * 
 * @param fastReloadInfoTable Table returned by 
 *                            _GetFastReloadInfoTable
 */
static void doAutoReadOnly(AUTORELOAD_FILE_INFO (&fastReloadInfoTable):[])
{
   if ( !def_fast_auto_readonly ) {
      // If def_fast_auto_readonly is off, call maybe_set_readonly for each 
      // buffer.  This will call _WinFileIsWritable, which is more reliable in
      // some cases but may be slower.
      _mdi.p_child.for_each_buffer("maybe_set_readonly +quiet",false,&fastReloadInfoTable);
   }else{
      // We already have the information we need in fastReloadInfoTable
      // Loop through the buffers and set read only mode appropriately
      temp_view_id := 0;
      int orig_view_id=_create_temp_view(temp_view_id);
      int first_buf_id=p_buf_id;
      for (;;) {
        _next_buffer('HNR');    /* Must include hidden buffers, because */
                               /* active buffer could be a hidden buffer */
        int buf_id=p_buf_id;
        if ( !(p_buf_flags & VSBUFFLAG_HIDDEN) &&
             !_isdiffed(p_buf_id) &&
             !debug_is_readonly(p_buf_id)
             ) {
           casedFilename := _file_case(p_buf_name);
           if ( fastReloadInfoTable._indexin(casedFilename) ) {
              ro := fastReloadInfoTable:[casedFilename].readOnly;
              if (!p_readonly_set_by_user) {
                 if (ro) {
                    read_only_mode();
                    //should reload here
                 }else if (!ro) {
                    if (p_readonly_mode) {
                       _set_read_only(!p_readonly_mode,false,false,true);
                       //should reload here
                    }
                 }
                 p_readonly_set_by_user=false;
              }
           }
        }
        if ( buf_id== first_buf_id ) {
          break;
        }
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
}

static void ReloadCurrentFileTimerCB()
{
   if (gReloadFileTimerID >= 0 && _timer_is_valid(gReloadFileTimerID)) {
      _kill_timer(gReloadFileTimerID);
      gReloadFileTimerID = -1;
   }

   if (gReloadBufIdList._length() <= 0) {
      return;
   }

   int bufIdList[];
   bufIdList = gReloadBufIdList;
   gReloadBufIdList._makeempty();

   // Have to set in_actapp_files here so that we do not get a second instance
   // of auto reload.  This could happen since _actapp_files could be called
   // while this dialog is up.
   orig_in_actapp_files := in_actapp_files;
   in_actapp_files=true;
   _ReloadFiles(true, &bufIdList);
   in_actapp_files=orig_in_actapp_files;
   gReloadFileTimerID = -1;
}


// WARNING: _switchbuf_files is called from _on_document_tab_left_click with
// null for old_buffer_name. It similates the old file tabs tool window
// auto-reload which occurs because the edit command is called.
void _switchbuf_files(_str old_buffer_name, _str option='')
{
   if ( in_actapp_files ||
        !(def_actapp & ACTAPP_AUTORELOADON) ||
        (def_actapp & ACTAPP_DONT_RELOAD_ON_SWITCHBUF) ||
         option == 'W'
        // Could have close last window&buffer and
        // now there are no edit windows to switch to.
        || !_isEditorCtl(false)) {
      return;
   }

#if 0
   // 2:36:19 PM 5/24/2010
   // Do not change file to read only here.  After some discussion, we decided
   // this is going to hurt more often than it will help.  Could add a def var
   // for this if ppl want it back.
   // 
   // The specific case here is when a compiler locks a file, it gets set
   // readonly here, and then  it is left readonly when the build finishes.
   // You will get readonly errors when you type in the file after that.
#if 0
   if (def_actapp & ACTAPP_AUTOREADONLY) {
      maybe_set_readonly();
   }
#endif
   int bufIdList[]; bufIdList._makeempty();
   bufIdList[0] = p_buf_id;

   // Have to set in_actapp_files here so that we do not get a second instance
   // of auto reload.  This could happen since _actapp_files could be called
   // while this dialog is up.
   in_actapp_files=true;

   _ReloadFiles(true, &bufIdList);
   in_actapp_files=false;

#else

   // is this buffer already on the list of files to reload?
   already_have_buf_id := false;
   for (i:=0; i<gReloadBufIdList._length(); i++) {
      if (gReloadBufIdList[i] == p_buf_id) {
         already_have_buf_id = true;
         break;
      }
   }

   // add this buffer ID to the list
   if (!already_have_buf_id) {
      if( (!(p_buf_flags & VSBUFFLAG_HIDDEN) || p_AllowSave) && p_file_date!="" && p_file_date!=0) {
         gReloadBufIdList :+= p_buf_id;
      }
   }

   // add the buffer to the reload list and start the timer function
   if (gReloadFileTimerID >= 0 && _timer_is_valid(gReloadFileTimerID)) {
      _kill_timer(gReloadFileTimerID);
      gReloadFileTimerID = -1;
   }
   if (gReloadFileTimerID < 0) {
      gReloadFileTimerID = _set_timer(1, ReloadCurrentFileTimerCB);
   }

#endif
}

/**
 * Reload all open files in list, prompting if necessary, according to
 * def_actapp settings.
 * <p>
 * Note: <br>
 * If ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED is set in def_actapp, 
 * then the user is never prompted, regardless of how 
 * allowPrompting is set. 
 *
 * @param fileList       Array of filenames to reload from disk.
 * @param allowPrompting (optional). Set to false if you do not want
 *                       user prompted to reload file from disk.
 *                       Defaults to true.
 */
void _ReloadFileList(_str (&fileList)[], bool allowPrompting=true)
{
   // Assemble a list of buf ids for _ReloadFiles()
   int temp_wid, orig_wid;
   _open_temp_view("",temp_wid,orig_wid,"+bi "RETRIEVE_BUF_ID);
   int bufIds[] = null;
   int i;
   for( i=0; i<fileList._length(); ++i ) {
      // Only interested in open files
      int status = load_files('+q +b 'fileList[i]);
      if( status==0 ) {
         bufIds[bufIds._length()]=p_buf_id;
      }
   }
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);
   if( bufIds._length() > 0 ) {
      _ReloadFiles(allowPrompting,&bufIds);
   }
}

void _set_bwindow_pos(int temp_view_id)
{
   if (temp_view_id=='') return;
   view_id := 0;
   get_window_id(view_id);
   activate_window(temp_view_id);
   top();up();
   for (;;) {
      if(down()) break;
      line := "";
      get_line(line);
      typeless wid,p;
      parse line with wid p;
      wid.restore_pos(p);
   }
   activate_window(view_id);
}
/*
   Caller should initialize p for predictable results.
*/
int _list_bwindow_pos(int buf_id)
{
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if (orig_view_id=='') return(0);
   int i,last=_last_window_id();
   for (i=1;i<=last;++i) {
      if (_iswindow_valid(i) && i.p_mdi_child && i.p_HasBuffer  && !i.p_IsMinimap &&
          i.p_buf_id==buf_id && !(i.p_window_flags & HIDE_WINDOW_OVERLAP)
         ) {
         /* messageNwait('found one i='i); */
         /* Found a window which is displaying this buffer. */
         typeless p;
         i.save_pos(p,'L');
         insert_line(i' 'p);
      }
   }
   activate_window(orig_view_id);
   return(temp_view_id);
}
void _save_all_filepos()
{
   RestoreSelDisp    := (def_restore_flags & RF_NOSELDISP ) == 0;
   RestoreLineModify := (def_restore_flags & RF_LINEMODIFY) != 0;
   if (!RestoreLineModify && !RestoreSelDisp) return;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   int first_buf_id=p_buf_id;
   for (;;) {
      // This has problems if Restore Files is off, and the editor is closed
      // with one file open.  Need two loops to fix it- one for hidden buffers
      // and one for windows.
      if (!p_modify && (RestoreSelDisp|| RestoreLineModify) && _need_to_save2()) {
         _add_filepos_info(p_buf_name);
      }
      _next_buffer('NHR');
      if (p_buf_id==first_buf_id) {
         break;
      }
   }
}

int _filesize(_str filename)
{
   _str s=file_list_field(filename, DIR_SIZE_COL, DIR_SIZE_WIDTH);
   if (s=='') {
      return(0);
   }
   return(int)(s);
}
#if 0
defeventtab _saveas_form;
void ctlexpandtabs.lbutton_up()
{
   if (p_value) {
      ctltabify.p_value=0;
   }
}
void ctltabify.lbutton_up()
{
   if (p_value) {
      ctlexpandtabs.p_value=0;
   }
}
#endif

defeventtab _auto_file_reload_form;
ctlyes.on_create(_str filename = '')
{
   p_active_form.p_caption=_getDialogApplicationName();
   ctlfilename.p_caption=_maybe_quote_filename(filename);
   max := 0;
   int width=ctlanotherlab._text_width(ctlanotherlab.p_caption);
   if (width>max) max=width;
   width=ctlfilename._text_width(ctlfilename.p_caption);
   if (width>max) max=width;
   width=ctlyesnolab._text_width(ctlyesnolab.p_caption);
   if (width>max) max=width;

   width=ctldiff.p_x_extent-ctlanotherlab.p_x;
   if (width>max) max=width;

   ctldontprompt.p_value=(def_actapp & ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED)? 1:0;

   p_active_form.p_width=_left_width()*2+ctlanotherlab.p_x*2+width;

}

ctlyes.lbutton_up(){
   if (ctldontprompt.p_value) {
      def_actapp |= ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   p_active_form._delete_window(IDYES);
}
ctlyestoall.lbutton_up(){
   if (ctldontprompt.p_value) {
      def_actapp |= ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   p_active_form._delete_window(IDYESTOALL);
}
ctldiff.lbutton_up(){
   p_active_form._delete_window(IDDIFFFILE);
}

/**
 * Get the contents of the current editor control buffer
 * place it in the given string.
 *
 * @param text       (reference) contents of file
 *
 * @return 0 on success, <0 on error, LINES_TRUNCATED_RC if the file
 *         is larger than the default Slick-C&reg; string length
 *
 * @categories String_Functions, Edit_Window_Methods, Editor_Control_Methods
 * @see _GetFileContents
 */
int _GetBufferContents(_str &text)
{
   // save cursor position
   save_pos(auto p);

   // go to the end of the end
   bottom();
   _end_line();

   // compute the number of bytes in the file, and avoid Slick-C error
   status := 0;
   int nOfBytes = (int) _QROffset();
   if (nOfBytes >= _default_option(VSOPTION_WARNING_STRING_LENGTH)) {
      nOfBytes = _default_option(VSOPTION_WARNING_STRING_LENGTH)-1;
      status = LINES_TRUNCATED_RC;
   }

   // go back to the top of the file
   _GoToROffset(0);

   // get the text, without any translations
   text = get_text_raw(nOfBytes, 0);

   // and now restore cursor position
   restore_pos(p);
   return status;
}

/**
 * Get the contents of the given file and place it in the given string.
 *
 * @param filename   file to open
 * @param text       (reference) contents of file
 *
 * @return 0 on success, <0 on error, LINES_TRUNCATED_RC if the file
 *         is larger than the default Slick-C&reg; string length
 *
 * @categories File_Functions, String_Functions
 */
int _GetFileContents(_str filename, _str &text)
{
   // open the file in a temp view
   temp_view_id := 0;
   orig_view_id := 0;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);
   if (status) {
      text="";
      return(status);
   }

   // get the text, without any translations
   status = _GetBufferContents(text);

   // clean up and return status (which should be zero)
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(status);
}

static void _GetNewFileContents(_str filename)
{
   _delete_line();
   int status=get(_maybe_quote_filename(filename),'','A');
   if (!status) {
      status=search('%\c','@');
      if (!status) {
         line := "";
         get_line(line);
         if (line=='%\i%\c') {
            replace_line(indent_string(p_SyntaxIndent));
            _end_line();
         }
      }
   }
}
static void _InitNewFileContents()
{
   langId := p_LangId;
   if (langId=='') return;
   modify := p_modify;
   // This code is hardwired for now.  This will be configurable later.
   if (_file_eq(langId,'xsl')) {
      _delete_line();
      insert_line('<?xml version="1.0"?>');
      insert_line('<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">');
      insert_line(indent_string(p_SyntaxIndent));
      insert_line('</xsl:stylesheet>');
      up();_end_line();
   } else if (_file_eq(langId,'xsd')) {
      _delete_line();
      insert_line('<?xml version="1.0"?>');
      insert_line('<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">');
      insert_line(indent_string(p_SyntaxIndent));
      insert_line('</xsd:schema>');
      up();_end_line();
   } else if (_file_eq(langId,'xmldoc')) {
      _delete_line();
      insert_line('<?xml version="1.0"?>');
      insert_line('<doc>');
      insert_line(indent_string(p_SyntaxIndent));
      insert_line('</doc>');
      up();_end_line();
   }
   p_modify=modify;
   if (_LanguageInheritsFrom('xml')) {
      apply_dtd_changes();
   }
}
#if 0
// This code will be redone.
static void _GetNewFileContents(_str filename)
{
   _delete_line();
   status=get(_maybe_quote_filename(filename),'','A');
   if (!status) {
      status=search('%\c','@');
      if (!status) {
         get_line(line);
         if (line=='%\i%\c') {
            replace_line(indent_string(p_SyntaxIndent));
            _end_line();
         }
      }
   }
}
static void _InitNewFileContents()
{
   ext=get_extension(p_buf_name);
   if (ext=='') return;
   filename=user_configdir:+'newfile.'ext;
   if (file_exists(filename)) {
      _GetNewFileContents(filename);
      return;
   }
   filename=get_env('VSROOT'):+'newfile.'ext;
   if (file_exists(filename)) {
      _GetNewFileContents(filename);
      return;
   }
}
#endif


defeventtab _auto_file_deleted_form;
ctldeletedyes.on_create(_str filename = '')
{
   p_active_form.p_caption = _getDialogApplicationName();
   ctldeletedfilename.p_caption = _maybe_quote_filename(filename);
   max := 0;
   int width = ctldeletedlab._text_width(ctldeletedlab.p_caption);
   if (width > max) max = width;
   width = ctldeletedfilename._text_width(ctldeletedfilename.p_caption);
   if (width > max) max = width;
   width = ctlsaveitlab._text_width(ctlsaveitlab.p_caption);
   if (width > max) max = width;

   //p_active_form.p_width=_left_width()*2+ctldeletedlab.p_x*2+width;
   p_active_form.p_width=_left_width()*2+ctldeletedlab.p_x*2+max;
   //p_active_form.p_width=_left_width()*2+max*2+width;
}

ctldeletedyes.lbutton_up()
{
   p_active_form._delete_window(IDYES);
}

ctldeletedclose.lbutton_up()
{
   p_active_form._delete_window(IDCLOSE);
}

/**
 * Saves html version of source file with color-coding and font
 * information based on current editor settings.
 *
 * @param filename Optionally pass filename to save, otherwise
 *                 file prompt will appear.
 *
 * @return int
 */
_command int export_html(_str filename = '') name_info(FILENEW_ARG','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int buffer_id = p_buf_id;
   if (filename == '') {
      _str bufname = p_buf_name;
      file_list := "*.htm;*.html";
      format_list :=  'HTML Files(*.htm;*.html), All Files('ALLFILES_RE')';
      initial_filename := _maybe_quote_filename(_strip_filename(bufname,'P')) :+ '.html';
      typeless result=_OpenDialog('-new -modal',
                       'Export to HTML',
                       file_list,               // Initial wildcards
                       format_list,
                       OFN_SAVEAS,
                       '',                      // Default extension
                       initial_filename,        // Initial filename
                       '',                      // Initial directory
                       '',                      // Retrieve name
                       ''                       // Help item
                       );
      if (result=='') {
         return (COMMAND_CANCELLED_RC);
      }
      _str save_options;
      filename = strip_options(result, save_options, true);
   }

   mou_hour_glass(true);

   int status;
   orig_view_id := p_window_id;
   int temp_view_id;
   _open_temp_view('', temp_view_id, orig_view_id,'+bi ':+buffer_id);
   status = _ExportColorCodingToHTML(strip(filename, 'B', '"'));
   p_window_id = orig_view_id;
   _delete_temp_view(temp_view_id, false);

   mou_hour_glass(false);
   if (status != 0) {
      message("Error occured exporting: "filename);
   }
   return (0);
}

static void GetFilePositionFromWindow()
{
   int buf_id=p_buf_id;
   wid := window_match(p_buf_name,1,'x');
   for (;;) {
      if (!wid) break;
      if (wid.p_mdi_child && wid.p_buf_id==buf_id) {
         // Get position info from window
         typeless p;
         wid.save_pos(p);
         // Save position info into this view
         restore_pos(p);
         break;
      }
      wid=window_match(p_buf_name,0,'x');
   }
}

/**
 * Saves the file position info for the current file.
 * 
 * @param filename               name of file
 * 
 * @return int                   0 for success, non-zero otherwise
 */
int _add_filepos_info(_str filename)
{
   if (_strip_filename(filename,'p')=='filepos.slk') {
      return(0);
   }
   if (def_max_filepos<1) {
      return(0);
   }
   if (def_max_filepos>5000) {
      def_max_filepos=5000;
   }
   // Don't want to do file_match because could be looking on floppy which is slow
   // This means we can get garbage filenames
   if (filename=='' /*|| file_match('-p 'filename,1)==''*/) {
      return(1);
   }

   PERFILEDATA_INFO info;

   // load the data for our file into this struct
   GetFilePositionFromWindow();
   info.m_filename = filename;
   info.m_seekPos = _QROffset();
   info.m_col = p_col;
   info.m_encodingSetByUser = p_encoding_set_by_user;
   info.m_hexMode = p_hex_mode;

   // only store the lang id if it does not match what _Filename2LangId
   // comes up with.  The user may wish to set up an extension later.
   // 12480 - sg
   langId := _Filename2LangId(filename, F2LI_NO_CHECK_OPEN_BUFFERS | F2LI_NO_CHECK_PERFILE_DATA);
   // if it doesn't match a language, we give it fundamental mode
   if (!LanguageSettings.isLanguageDefined(langId)) langId = FUNDAMENTAL_LANG_ID;
   if (langId != p_LangId) {
      info.m_langId = p_LangId;
   } else {
      info.m_langId = '';
   }

   typeless SoftWrap=p_SoftWrap;
   bool lang_SoftWrap, lang_SoftWrapOnWord;
   _SoftWrapGetSettings(p_LangId, lang_SoftWrap, lang_SoftWrapOnWord);
   if (SoftWrap==lang_SoftWrap) {
      SoftWrap=2;
   }
   info.m_softWrap = SoftWrap;

   info.m_xmlWrapScheme = '';

   info.m_xmlWrapOptions = '0';;

   restoreSelDisp := !(def_restore_flags &RF_NOSELDISP);
   restoreLineModify := ((def_restore_flags &RF_LINEMODIFY) != 0);
   saveLineflags := (p_NofSelDispBitmaps && restoreSelDisp) || restoreLineModify;

   // positive or negative depending on whether we are saving the flags - the actual 
   // value will be set in the C code.
   info.m_selDisp = saveLineflags ? 1 : -1;

   _per_file_data_set_info(info);

   if (saveLineflags) {
      _filepos_save_sel_disp(filename);
   }

   return(0);
}

static void _filepos_save_sel_disp(_str filename)
{
   PERFILEDATA_INFO info;
   _per_file_data_get_info(filename, info);

   newSD := info.m_selDisp;
   if (!isinteger(newSD)) newSD = 1;
   if (newSD < 0) newSD = -newSD;

   path := _ConfigPath() :+ "SelDisp" :+ FILESEP;
   file_date := p_file_date;
   int status = _SaveSelDisp(path :+ newSD, file_date);
   if (status && !isdirectory(path)) {
      status = make_path(path);
      if (!status) {
         status = _SaveSelDisp(path :+ newSD, file_date);
      }
   }

   // IF we did not write the selective display code
   if (status) {
      newSD =- newSD;
   }

   if (newSD != info.m_selDisp) {
      info.m_selDisp = newSD;
      _per_file_data_set_info(info);
   }
}

/**
 * Retrieves the saved file position info for the given file.
 * 
 * @param filename               name of file
 * @param info                   info
 * 
 * @return int                   0 for success, non-zero otherwise
 */
int _filepos_get_info(_str filename, PERFILEDATA_INFO &info)
{
   if (filename=='') {
      return(FILE_NOT_FOUND_RC);
   }
   if (def_max_filepos<1) {
      return(FILE_NOT_FOUND_RC);
   }

   return _per_file_data_get_info(filename, info);
}

/**
 * Restores the file position information for this file.
 * 
 * @param filename               name of file
 * 
 * @return int                   0 for success, non-zero otherwise
 */
int _restore_filepos(_str filename)
{
   PERFILEDATA_INFO info;
   int status=_filepos_get_info(filename, info);
   if (status) {
      return(status);
   }

   if (isinteger(info.m_selDisp) && info.m_selDisp>0) {
      RestoreSelDisp := !(def_restore_flags &RF_NOSELDISP);
      RestoreLineModify := ((def_restore_flags &RF_LINEMODIFY) != 0);
      RestoreLineflags := RestoreSelDisp ||RestoreLineModify;
      if (RestoreLineflags) {
         _str path=_ConfigPath():+"SelDisp":+FILESEP;
         status=_RestoreSelDisp(path:+info.m_selDisp,p_file_date,RestoreSelDisp,RestoreLineModify);
      }
   }
   _str scroll_style=_scroll_style();
   _scroll_style('C 0',false);
   _GoToROffset(info.m_seekPos);
   _scroll_style(scroll_style,false);

   p_col=info.m_col;
   if (isinteger(info.m_hexMode) && info.m_hexMode && !p_hex_mode && !p_UTF8) {
      if (info.m_hexMode==1) {
         hex();
      } else {
         linehex();
      }
   }
   if (info.m_softWrap!=2) {
      p_SoftWrap=(info.m_softWrap != 0);
   }
   if (info.m_langId != "" && info.m_langId != p_LangId) {
      _SetEditorLanguage(info.m_langId);
   }

   // no idea what this is for
   int undo_steps = p_undo_steps;
   p_undo_steps = 0;
   p_undo_steps = undo_steps;

   return(0);
}

void _exit_filepos()
{
   _per_file_data_exit();
   gWarnedSlowFiles = null;
   gDoNotReloadFiles = null;
}

/**
 * Reads in the old filepos.slk and stores the data according to the new (v16)
 * method.
 */
void _UpgradeFileposData()
{
   // see if the old file exists
   oldFile := _ConfigPath() :+ 'filepos.slk';
   backupFile := oldFile'.bak';

   // check for the backup file, too.  Sometimes we are unable to delete the old file, 
   // but we still don't want to do this over and over
   if (file_exists(oldFile) && !file_exists(backupFile)) {
      // open it up, we need to look at it
      int tempWid, origWid;
      _open_temp_view(oldFile, tempWid, origWid);

      // a very good place to start
      top();

      line := '';
      filename := '';

      // go down each line
      recordNum := 1;
      do {
         get_line(filename);
         down();
         get_line(line);

         if (filename != '') {
            // parse the line!
            typeless seekPos, col, hexMode, selDisp, encoding, softWrap, xwScheme, xwOptions, langId;
            parse line with seekPos col . . . . . . . hexMode selDisp encoding softWrap xwScheme xwOptions langId .;
   
            if (pos('.', seekPos) == 1) {
               seekPos = substr(seekPos, 2);
            }
   
            PERFILEDATA_INFO info;
            info.m_filename = filename;
            info.m_seekPos = seekPos;
            info.m_col = col;
            info.m_hexMode = isinteger(hexMode) ? (int)hexMode : 0;
            info.m_selDisp = isinteger(selDisp) ? (int)selDisp : recordNum;
            info.m_encodingSetByUser = isinteger(encoding) ? (int)encoding : -1;
            info.m_softWrap = isinteger(softWrap) ? (int)softWrap : 2;
            info.m_xmlWrapScheme = xwScheme;
            info.m_xmlWrapOptions = xwOptions;
            info.m_langId = langId;
   
            _per_file_data_set_info(info, 0);
         }

         recordNum++;
      } while (!down());

      // back up this silly file
      copy_file(oldFile, backupFile);
      status := delete_file(oldFile);

      // restore our old window
      activate_window(origWid);
   }
}

/** 
 * Clear modified and inserted line flags for a lines in current 
 * buffer. 
 * 
 */
_command void reset_modified_lines() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   save_pos(auto p);
   top(); up();
   while(!down()) {
      _lineflags(0, VSLF_MODIFY | VSLF_INSERTED_LINE);
   }
   restore_pos(p);
}

/**
 * Appends the contents of one file to the end of another file.  Files should 
 * not be opened already. 
 * 
 * @param sourceFile       contents to be copied
 * @param destFile         file where contents will be appended 
 * @param beginComment     comment to be appended before the file 
 * @param endComment       comment to be appended after the file 
 * 
 * @return                 0 for success, error code otherwise.
 */
int append_file_contents(_str sourceFile, _str destFile, _str beginComment = '', _str endComment = '')
{
   // make sure these exist, okay?
   if (!file_exists(sourceFile) || !file_exists(destFile)) return(FILE_NOT_FOUND_RC);
   
   status := 0;   
   origWid := p_window_id;
   do {
      // first open a tempview containing the destination file
      status = _open_temp_view(destFile, auto tempWid, origWid);
      if (status) break;

      if (searchForFileContents(sourceFile)) {
         _delete_temp_view(tempWid);
         break;
      }

      bottom();

      // add the beginning comment
      if (beginComment != '') {
         insert_line(beginComment);
         bottom();
      }

      // then do a get.  or a fetch.  or a grab.  whatever.
      status = get(sourceFile, 'B');
      if (status) {
         _delete_temp_view(tempWid);
         break;
      }
   
      // add the ending comment
      if (endComment != '') {
         bottom();
         insert_line(endComment);
      }

      // now close her up
      status = save();
      _delete_temp_view(tempWid);

   } while (false);

   p_window_id = origWid;
   return status;
}

/**
 * Searches the current file for the text from another file
 * 
 * @param file 
 * 
 * @return bool
 */
bool searchForFileContents(_str file)
{
   // if the file doesn't exist, i guess that means false
   if (!file_exists(file)) return false;

   // grab the contents of the file
   int temp_wid,orig_wid;
   status := _open_temp_view(file, temp_wid, orig_wid);
   if (status) return false;

   result := get_text(p_buf_size, 0);
   _delete_temp_view(temp_wid);
   p_window_id = orig_wid;

   // now look for them in the existing file
   top();
   return (search(result) == 0);
}

/** 
 * Gets a hash table indexed by the filenames that are OK to 
 * reload 
 * 
 * @param outputTable Hash table of files that are OK for 
 *                       reload. The table is indexed by the
 *                       names. Use
 *                       <B>outputTable</B>._indexin(_file_case(filename))
 *                       to check if a file is OK to reload
 * @param getReadOnlyInfo set to 1 to get readonly info for 
 *                        files
 * @param fast_auto_readonly set to 1 if we are using fast read 
 *                           only
 * @param reloadThreshold Max time in milliseconds to wait for 
 *                        auto reload information
 */
static void getFastReloadInfoTable(AUTORELOAD_FILE_INFO (&outputTable):[],int getReadOnlyInfo,int fast_auto_readonly,
                                   int autoreloadTimeoutThreshold)
{
   getOpenFilenameList(auto bufNames);
   _GetFastReloadInfoTable(bufNames,getReadOnlyInfo,fast_auto_readonly,outputTable,autoreloadTimeoutThreshold);
}

static void getOpenFilenameList(_str (&bufNames)[])
{
   // We will not be appending to the list, so be sure that this gets initialized
   bufNames = null;

   // Get a temp view to loop through the buffers
   orig_wid := _create_temp_view(auto temp_wid);

   // Save the original buffer ID
   origBufID := p_buf_id;

   // Loop through the buffer IDs and get the filenames. Also build a hashtable 
   // of the filenames indexed by the buffer ID.
   for ( ;; ) {
      _next_buffer('nrh');
      if ( p_buf_id==origBufID ) break;

      // 2017/01/22
      // This updates any symbolic links that might have been changed.
      // for instance if /src/cur was linked to /src/a and the link changed to
      // /src/b, this will cause the link to be updated and the file to be
      // reloaded.
      if (!_isPluginFileSpec(p_buf_name)) {
         p_buf_name=p_buf_name; 
      }
      if ( !(p_buf_flags&HIDE_BUFFER) && isReloadableFile(p_buf_name) ) {
         bufNames[bufNames._length()] = p_buf_name;
      }
   }

   load_files('+bi 'origBufID);

   _delete_temp_view(temp_wid);

   p_window_id = orig_wid;
}


static bool isReloadableFile(_str filename)
{
   return filename!="" && !beginsWith(filename,".process") && filename!=".command";
}

static void getFilenameListFromBufIDList(int (&bufIds)[],
                                         _str (&bufNames)[],
                                         _str (&bufIDsToNames):[])
{
   // Get a temp view to loop through the buffers
   orig_wid := _create_temp_view(auto temp_wid);

   // Save the original buffer ID
   origBufID := p_buf_id;

   // Loop through the buffer IDs and get the filenames. Also build a hashtable 
   // of the filenames indexed by the buffer ID.
   len := bufIds._length();
   for ( i:=0;i<len;++i ) {
      status := load_files('+bi 'bufIds[i]);
      if ( !status ) {
         if ( isReloadableFile(p_buf_name) ) {
            bufNames[bufNames._length()] = p_buf_name;
            bufIDsToNames:[bufIds[i]] = p_buf_name;
         }
      } 
   }

   load_files('+bi 'origBufID);

   _delete_temp_view(temp_wid);

   p_window_id = orig_wid;
}

static const MAX_REPORTED_FILES= 5;
/** 
 * Warn the user about files that we will not reload because 
 * they are too slow.  We will warn once per file. 
 */
static void showSlowFileNotification()
{
   _str slowFileTable:[];
   _GetSlowReloadFiles(slowFileTable);
   len := slowFileTable._length();
   if ( len>0 ) {

      // Build a string of the files that we want to warn the user will not be
      // reloaded. The maximum number we will warn about is MAX_REPORTED_FILES.
      slowFileString := "";
      numFilesInString := 0;
      foreach ( auto curFilename => auto val in slowFileTable ) {
         if ( gWarnedSlowFiles._indexin(_file_case(curFilename)) ) {
            continue;
         }
         // We put the file in the "warned list" regardless of if we add it to the
         // message.  The message will contain "and X others" if we run over, 
         // we will consider this a warning for those files.  Otherwise, the user
         // would be warned 5 files at a time and would still see every filename
         gWarnedSlowFiles:[_file_case(curFilename)] = "";
         if ( numFilesInString<MAX_REPORTED_FILES ) {
            slowFileString :+= "\n"curFilename;
            ++numFilesInString;
         }
      }

      if ( slowFileString!="" ) {
         if ( len>MAX_REPORTED_FILES ) {
            slowFileString :+= nls("\nand %s others",len-numFilesInString);
            // Put the "others" into the files we warned about, or this will 
            // keep happening.
         }
         toastMessageText := nls("The following file%s will always be skipped by auto reload and auto readonly:\n%s",numFilesInString==1?"":'s',slowFileString);
         _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_FILE_OPEN_ERROR, toastMessageText);
         foreach (curFilename => val in slowFileTable) {
            toastMessageText = nls("The following file will always be skipped by auto reload and auto readonly:\n%s",slowFileString);
            notifyUserOfWarning(ALERT_FILE_OPEN_ERROR, toastMessageText, curFilename, 0, true);
         }
      }
   }
}

/**
 * Determine which buffers have files that are modified and deleted, and which 
 * buffers are themselves modified. If the 
 * ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED flag is set in 
 * def_actapp, don't report unmodified buffers with modified 
 * files. 
 * 
 * @param bufferIDs    List of buffer IDs, which index the other lists.
 * @param modFileNames List of buffers with modified files.
 * @param delFileNames List of buffers with deleted files.
 * @param modBufNames  List of modified buffers.
 * @param bufIdList 
 *  
 * @return Return the number of files which were modified or deleted. 
 */
static int findModifiedAndDeleted(_str (&bufferIDs)[],
                                  _str (&modFileNames):[],
                                  _str (&delFileNames):[],
                                  _str (&modBufNames):[],
                                  int (*bufIdList)[]=null,
                                  int skipBufferId=-1,
                                  AUTORELOAD_FILE_INFO (*pFastReloadInfoTable):[]=null,
                                  int reloadThreshold=0)
{
   if (isEclipsePlugin()) {
      return 0;
   }

   // Get the names of the modified buffers.
   numModifiedOrDeleted := 0;
   temp_wid := 0;
   int orig_wid = _create_temp_view(temp_wid);
   int orig_def_buflist = def_buflist;
   if (def_buflist & BUFLIST_FLAG_SEPARATE_PATH) {
      def_buflist = def_buflist - BUFLIST_FLAG_SEPARATE_PATH;
   }
   _build_buf_list(0, p_buf_id, true, p_buf_id, false, bufIdList);
   def_buflist = orig_def_buflist;
   top();
   up();
   line := "";
   while (!down()) {
      get_line(line);
      line = strip(stranslate(line, '', '*'));
      modBufNames:[line] = line;
   }
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);

   // Get the names of the modified and deleted files.
   _push_def_actapp(def_actapp & ~ACTAPP_AUTORELOADON);

   temp_wid = 0;
   orig_wid = 0;
   _open_temp_view("",temp_wid,orig_wid,"+bi "RETRIEVE_BUF_ID);
   int bufIds[] = null;
   if( bufIdList ) {
      bufIds= *bufIdList;
   } else {
      int first_buf_id = p_buf_id;
      for( ;; ) {
         noption := 'N';
         if( (!(p_buf_flags & VSBUFFLAG_HIDDEN) || p_AllowSave) && p_file_date!="" && p_file_date!=0 && p_buf_id!=skipBufferId ) {
            bufIds[bufIds._length()]=p_buf_id;
         }
         _next_buffer(noption'RH');
         if( p_buf_id==first_buf_id ) {
            break;
         }
      }
   }

   AUTORELOAD_FILE_INFO fastReloadInfoTable:[];
   _str reloadCandidateFilenameList[];
   _str bufIDsToFilenames:[];
   // Have to call this to get the filenames etc. We cannot simply build above
   // because it could have been passed in bufIdList
   getFilenameListFromBufIDList(bufIds,reloadCandidateFilenameList,bufIDsToFilenames);

   if ( pFastReloadInfoTable ) {
      fastReloadInfoTable = *pFastReloadInfoTable;
   } else {
      _GetFastReloadInfoTable(reloadCandidateFilenameList,def_actapp&ACTAPP_AUTOREADONLY,def_fast_auto_readonly,fastReloadInfoTable,reloadThreshold);
   }

   // Create a delete list of items that did not make into the fast reload 
   // info table
   int delList[];
   len := bufIds._length();
   for ( i:=0;i<len;++i ) {
      curFilename := bufIDsToFilenames:[bufIds[i]];
      if ( curFilename!=null ) {
         if ( !fastReloadInfoTable._indexin(_file_case(curFilename)) ) {
            delList[delList._length()] = i;
         }
      }
   }

   // Delete the items that we put in the list
   len = delList._length();
   for ( i=len-1;i>=0;--i ) {
      bufIds._deleteel(delList[i]);
   }

   int bufferNumber;
   origTime := _time('b');
   for( i=0; i<bufIds._length(); ++i ) {
      activate_window(temp_wid);
      int status = load_files('+q +bi 'bufIds[i]);
      if( status!=0 ) {
         // This should never happen, we just got the buffer id
         continue;
      }
#if 0 //11:06am 10/18/2010
      _str bfiledate = _file_date(p_buf_name,'B');
#else
      
      bfiledate := "";
      casedFilename := _file_case(p_buf_name);
      if ( fastReloadInfoTable._indexin(casedFilename) ) {
         bfiledate = fastReloadInfoTable:[casedFilename].bfileDate;
      }
      if (_MaybeUpdateUserOptions(p_buf_name)) {
         bfiledate = _file_date(p_buf_name, 'B');
      }
#endif
#if FILES_TESTING_RELOAD_CHANGES
      if ( fastReloadInfoTable._indexin(_file_case(p_buf_name)) ) {
         if ( fastReloadInfoTable:[_file_case(p_buf_name)]!=bfiledate ) {
            say('findModifiedAndDeleted PROBLEM p_buf_name='p_buf_name);
            say('                       bfiledate=<'bfiledate'>');
            say('                       hashtbval=<'fastReloadInfoTable:[_file_case(p_buf_name)]'>');
         }
      }
#endif
      bufferNumber = bufferIDs._length();
      if (bfiledate == 0 || bfiledate == "") { //If there is no file on disk ...
         if ((p_file_date != "" && p_file_date != 0) && 
             !(p_buf_flags & VSBUFFLAG_PROMPT_REPLACE) && 
             _HaveValidOuputFileName(p_buf_name) && //but we're editing one (so not creating a new file).
             (p_modify == false)) { 
            p_modify = true;
            bufferIDs[bufferNumber] = p_buf_id;
            delFileNames:[bufferNumber] = p_buf_name_no_symlinks;
            numModifiedOrDeleted++;
         }
      } else if( p_file_date:!=bfiledate && !_FileIsRemote(p_buf_name)) {
         // the file's date has been updated, so the buffer may be out of sync with the disk file
         ignoreTouchedFile := false;
         // first, determine if the user is checking for 'touched' files where the date is updated
         // but the content is not.

         if ( useWholeFileCompare() && (((int)_time('b')-(int)origTime)<def_autoreload_timeout_threshold) ) {
            wholeFileCompare(ignoreTouchedFile);
         }
         // if this file is not being ignored because it was touched, then handle it
         if (ignoreTouchedFile == false) {
            fileReloadedSilently := false;
            // check to see if the buffer should be automatically reloaded (if the user wants 
            // to suppress the prompt if modified)
            if (def_actapp&ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED) {
               if (!modBufNames._indexin(p_buf_name)) {
                  // Buffer is not modified, but file is. Reload it silently.
                  // Also, save and restore the current window ID, _ReloadCurFile changes it.
                  wid:= p_window_id;
                  _ReloadCurFile(p_window_id, bfiledate, false, true, null, false, auto reloadStatus=0);
                  p_window_id= wid;
                  fileReloadedSilently = true;
                  //create a backup history entry for the reload
                  if ( !reloadStatus && useWholeFileCompare() && _haveBackupHistory() && DSBackupVersionExists(p_buf_name) ) {
                     status = DS_CreateDelta(p_buf_name);
                     if ( !status ) {
                        DSSetVersionComment(p_buf_name, -1, "Created by Auto Reload.");
                     }
                  }
                  //say('file reloaded silently');
               }
            }
            // if the buffer wasn't reloaded silently, then add it to the modified buffer list
            if (fileReloadedSilently == false) {
               bufferIDs[bufferNumber] = p_buf_id;
               modFileNames:[bufferNumber] = p_buf_name;
               numModifiedOrDeleted++;
               //say('file added to modified list:'p_buf_name);
            }
         }
      }
   }
   // Don't want _delete_temp_view to delete a buffer.
   temp_wid.load_files('+m +bi 'RETRIEVE_BUF_ID);
   _delete_temp_view(temp_wid);
   if (_iswindow_valid(orig_wid)) {
      activate_window(orig_wid);
   }

   _pop_def_actapp();
   return numModifiedOrDeleted;
}


/** 
 * Some file systems do not have reliable dates (we will write
 * the file, store the date on disk, and the date will change 
 * without the file having been modified.  Because of this, if 
 * the file is under a size threshold we have to compare the 
 * file on disk to either the file in backup history or the 
 * buffer in memory. 
 *  
 * @param ignoreTouchedFile will be set to true if we determined 
 *                          the file can be ignored.
 *  
 * @return bool true if the file should
 */
static void wholeFileCompare(bool &ignoreTouchedFile)
{
   ignoreTouchedFile = false;
   int orig_pBufId = p_buf_id;
   fileWID := 0;
   backupWID := 0;
   origWID := p_window_id;
   int backupFileStatus;

   // 10/25/2012
   // Case 1: If the buffer is modified, we have to compare against the last 
   // version in backup history.  This because we do not know what the original 
   // contents of the buffer before it was modified was.  THIS HAS A KNOWN 
   // FAILURE case:
   //     If you have two editors sharing the same backup history directory, 
   //     and you modify and save the file in Editor 1, when you change to 
   //     Editor 2 the backup history entry will match the file on disk, 
   //     but not the buffer in Editor 2.  Currently, there is no good way
   //     around this.  The dates don't match, and that could be legitimate
   //     or because of a file system bug.  The file systems that have date
   //     bugs tend to be off by >=2 seconds, so it is too much to ignore.
   //     The buffer is modified, so it is not expected to match the file on
   //     disk.

   // Case 2: If the file is not modified, we can use the buffer as the backup.

   // Case 3: Buffer is modified and there is no backup history - There is 
   // nothing we can do here.  We have to prompt the user to reload

   if ( p_modify && _haveBackupHistory() && DSBackupVersionExists(p_buf_name) ) {
      // Case 1
      backupWID = DSExtractMostRecentVersion(p_buf_name, backupFileStatus);
   } else if ( !p_modify ) {
      // Case 2
      backupFileStatus = _open_temp_view("", backupWID,auto origBackupWID, "+bi "p_buf_id);
   } else {
      // Case 3
      // 10/25/2012 - If the file is modified and there is no backup 
      // available, we cannot screen out false date changes
      return;
   }
   // Open the file on disk last, since we are specifying +d. This way we will 
   // not have an issue with getting this when we are trying to load the 
   // existing buffer (see !p_modify case above).
   int diskFileStatus = _open_temp_view(p_buf_name, fileWID, auto fileOrigWID, "+d");
   if (!diskFileStatus && !backupFileStatus) {
      int different = FastBinaryCompare(fileWID, 0, backupWID, 0);
      if (!different) {
         // if the current file contents with the last backup history entry are
         // the same, then the file has been 'touched' and we should ignore it
         //say('touched file');
         ignoreTouchedFile = true;

         // If the files matched, save the date on disk at this point.
         // If we do not do this, the user will be prompted when they
         // save the file because the file on disk will still be newer
         // 10/26/2012
         // Only do this when the file is not modifed.  When the file is
         // modified, there is a failure case, so we want to be sure that
         // the "overwrite newer file" safeguard is still in place
         if (!origWID.p_modify) origWID.p_file_date = (long)_file_date(origWID.p_buf_name,'B');
      }
      _delete_temp_view(fileWID);
      _delete_temp_view(backupWID);
      p_window_id = origWID;
   }
}

/**
 * Given a buffer name, determine if it is modified (unsaved).
 * 
 * @param bufName 
 * 
 * @return 
 */
bool checkIfFileIsModified (_str bufName)
{
   buf_id := "";
   _str buf_info = buf_match(bufName, 1, 'vx');
   parse buf_info with buf_id ' ' .;

   int temp_wid;
   int orig_wid;
   _open_temp_view('', temp_wid, orig_wid, '+bi 'RETRIEVE_BUF_ID);
   activate_window(temp_wid);
   int status = load_files('+q +bi 'buf_id);
   if (status != 0) {
      return false;
   }

   typeless bfiledate = _file_date(p_buf_name, 'B');
   if ((p_file_date :!= bfiledate) && !_FileIsRemote(p_buf_name)) {
      return true;
   }

   _delete_temp_view(temp_wid);
   if (_iswindow_valid(orig_wid)) {
      activate_window(orig_wid);
   }
   return false;
}


defeventtab _reload_modified_diff_button;
void _reload_modified_diff_button.lbutton_up()
{
   select_tree_wid := _find_control('ctl_tree');
   if (select_tree_wid) {
      //Find the selected buffers.
      _str selBufs:[];
      selBufs._makeempty();
      flags := 0;
      int showChildren;
      typeless bm1, bm2;
      index := select_tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         if ( select_tree_wid._TreeGetCheckState(index) ) {
            selBufs:[index] =
               _maybe_quote_filename(select_tree_wid._TreeGetCaption(index));
         }
         index = select_tree_wid._TreeGetNextIndex(index);
      }

      //Diff the selected buffers.
      _str buf_info;
      typeless buf;
      for (buf._makeempty(); ; ) {
         selBufs._nextel(buf);
         if (buf._isempty()) {
            break;
         }
         int result = _DiffModal('-r2 -b1 -d2 'selBufs:[buf]' 'selBufs:[buf]);
         //If the buffer no longer differs from the file, remove it from the
         //tree.
         if ((result == 0) && !checkIfFileIsModified(selBufs:[buf])) {
            select_tree_wid._TreeDelete(buf);
         }
      }

      if (select_tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX) == -1) {
         p_active_form._delete_window();
      }
   }
}


defeventtab _save_deleted_close_button;
void _save_deleted_close_button.lbutton_up()
{
   select_tree_wid := _find_control('ctl_tree');
   if (select_tree_wid) {
      //Find the selected buffers and close them
      _str selBufs:[];
      selBufs._makeempty();
      flags := 0;
      int showChildren;
      typeless bm1, bm2;
      _str closeFileList[]=null;
      _str bufferName, rawBufferName;
      _str buf_id, buf_info;
      int temp_wid;
      int orig_wid;
      index := select_tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         if ( select_tree_wid._TreeGetCheckState(index) ) {
            bufferName =
               _maybe_quote_filename(select_tree_wid._TreeGetCaption(index));
            rawBufferName = strip(bufferName, 'B', '"');

            buf_info = buf_match(rawBufferName, 1, 'vx');
            if ( buf_info!="" ) {
               parse buf_info with buf_id .;

               int status = _open_temp_view('', temp_wid, orig_wid, '+bi '(int)buf_id);
               if (!status) {
                  p_modify = false;
                  closeFileList[closeFileList._length()]=p_buf_name_no_symlinks;
                  _delete_temp_view(temp_wid);
                  if (_iswindow_valid(orig_wid)) {
                     activate_window(orig_wid);
                  }
               }
            }
         }
         index = select_tree_wid._TreeGetNextIndex(index);
      }

      p_active_form._delete_window();

      tmpwid := p_window_id;
      p_window_id = HIDDEN_WINDOW_ID;
      _safe_hidden_window();
      int i;
      int old_def_actapp = def_actapp;
      def_actapp &= ~ACTAPP_AUTORELOADON;
      for (i = 0; i < closeFileList._length(); ++i) {
         _save_non_active(closeFileList[i], true, 0);
      }
      def_actapp = old_def_actapp;
      if (_iswindow_valid(tmpwid)) {
         p_window_id = tmpwid;
      } else if (_no_child_windows()) {
         p_window_id = _mdi;
      } else {
         p_window_id = _mdi.p_child;
      }
   }
}

defeventtab _never_reload_button;
void _never_reload_button.lbutton_up()
{
   int select_tree_wid = _find_control('ctl_tree');
   if (select_tree_wid) {
      //Find the selected buffers and close them
      _str selBufs:[];
      selBufs._makeempty();
      int flags=0;
      int showChildren;
      typeless bm1, bm2;
      _str closeFileList[]=null;
      _str bufferName, rawBufferName;
      _str buf_id, buf_info;
      int temp_wid;
      int orig_wid;
      INTARRAY removeList;
      STRARRAY removeListPaths;
      int index = select_tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         if ( select_tree_wid._TreeGetCheckState(index) ) {
            bufferName = _maybe_quote_filename(select_tree_wid._TreeGetCaption(index));
            ARRAY_APPEND(removeList,index);
            ARRAY_APPEND(removeListPaths,bufferName);
         }
         index = select_tree_wid._TreeGetNextIndex(index);
      }
      len := removeList._length();
      for (i:=0;i<len;++i) {
         select_tree_wid._TreeDelete(removeList[i]);
         gDoNotReloadFiles:[_file_case(removeListPaths[i])] = "";
      }
      if (select_tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX) == -1) {
         p_active_form._delete_window();
      }
   }
}

// Holds the line ending format option for reload_with_encoding
static _str _rwe_chosen_le;

// Callback function used by the _sellist_form invoked by reload_with_encoding
static _str _rwe_callback(int reason,var result,_str key)
{
    // Custom button is for choosing a line ending format
    if (key==SL_ONUSERBUTTON) {
        // Pick line ending format via standard combo-box dialog
        _str lineEndingStyles[];
        lineEndingStyles[0]= "Automatic";
        lineEndingStyles[1]= "Windows/DOS (CRLF)";
        lineEndingStyles[2]= "Unix/macOS (LF)";
        lineEndingStyles[3]= "Classic Mac (CR)";
        if (comboBoxDialog("Line Ending Format", "Format", lineEndingStyles, 0, lineEndingStyles[0]) == IDOK) {
            // Convert chosen line ending format into the +F? argument for the edit command
            _str lineEndOption = _param1;
            if (pos('Automatic', lineEndOption)) {
                _rwe_chosen_le = '';
            } else if (pos('Unix', lineEndOption)) {
                _rwe_chosen_le = " +FU";
            } else if (pos('Windows', lineEndOption)) {
                _rwe_chosen_le = " +FD";
            } else if (pos('Classic', lineEndOption)) {
                _rwe_chosen_le = " +FM";
            }
        }
    }
    return '';
}

/**
 * Displays a dialog allowing the user to pick a different 
 * encoding and re-open the currently active file with that 
 * encoding. 
 *  
 * @appliesTo Edit_Window
 * @categories File_Functions 
 */
_command void reload_with_encoding,rwe() name_info(','VSARG2_READ_ONLY|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _str editOptions=arg(1);
    if(p_buf_name != '') {
        _rwe_chosen_le = '';
        // Fill a temp view with all encoding names appropriate for File->Open
        int temp_view_id;
        typeless orig_view_id=_create_temp_view(temp_view_id);
        OPENENCODINGTAB openEncodingTab[];
        _EncodingListInit(openEncodingTab);
        skipFlag := OEFLAG_REMOVE_FROM_OPEN;
        int idx;
        for (idx = 1; idx < openEncodingTab._length(); ++idx) {
            if (!(skipFlag & openEncodingTab[idx].OEFlags)) {
                _lbadd_item(openEncodingTab[idx].text);
            }
        }
        p_line = 2;
        activate_window(orig_view_id);


        if (editOptions=='') {
           typeless was_recording=_macro();
           _str chosenEncoding=show('_sellist_form -xy -new -mdi -modal',
                           "Reload With...",
                           SL_VIEWID|SL_SELECTCLINE|SL_COMBO|SL_SELECTPREFIXMATCH,
                           temp_view_id,
                           "OK,Line Endings",             // Specify custom "Line Endings" button
                           "Reload With Encoding dialog", // Help item
                           '',                            // Use default font
                           _rwe_callback,                // Call back function to handle "Line Endings" button
                           '',
                           '_rwe_encs'                    // history retrieve name
                           );

           if (chosenEncoding == '') {
              // we cancelled out, don't do anything
              return;
           }

           _macro('M',was_recording);
           // Find the match in the encoding table and format it
           // as arguments appropriate for the edit command
           int i;
           for (i = 1; i < openEncodingTab._length(); ++i) {
               if (openEncodingTab[i].text == chosenEncoding) {
                   if (openEncodingTab[i].option) {
                       editOptions = strip(openEncodingTab[i].option);
                   } else if (openEncodingTab[i].codePage >= 0) {
                       editOptions = '+fcp'openEncodingTab[i].codePage;
                   }
                   break;
               }
           }

           // Combine current file buffer name with encoding option and line ending option
           editOptions :+= _rwe_chosen_le;
        }
        _macro_delete_line();
        _macro_call('reload_with_encoding',editOptions);
        editCommandParams :=  editOptions:+' ';
        editCommandParams :+= _maybe_quote_filename(p_buf_name);
        quit();
        edit(editCommandParams);

        // make sure the file is retagged
        p_modify = true;
        p_ModifyFlags = 0;
        ++p_LastModified;
        _UpdateContext(AlwaysUpdate:true);
        p_modify = false;
    }
}

int _OnUpdate_reload_with_encoding(CMDUI &cmdui,int target_wid,_str command)
{
    if(target_wid && target_wid._isEditorCtl()) {
        if(target_wid.p_buf_name && file_exists(target_wid.p_buf_name)) {
           if (p_hex_mode!=0 && p_hex_mode_reload_encoding) {
              return MF_GRAYED;
           }
            return MF_ENABLED;
        }
    }
    return MF_GRAYED;
}

/**
 * Timer callback function for {@link batch_call_list} function. 
 */
void batch_call_list_timer_proc()
{
   // this is a one-shot timer, so kill it immediately
   if (_timer_is_valid(gbatch_call_list_timer)) {
      _kill_timer(gbatch_call_list_timer);
      gbatch_call_list_timer = -1;
   }

   // now go through all the callbacks queued up, and call
   // the big refresh callback for the ones that are above
   // the repeat threshold.
   foreach (auto cb_name => auto count in gbatch_call_list_count) {
      if (count >= BATCH_CALL_LIST_THRESHOLD) {
         // invoke the batch update function
         index := find_index(cb_name, PROC_TYPE|COMMAND_TYPE);
         if (index_callable(index)) {
            if (gbatch_call_list_arg._indexin(cb_name)) {
               call_index(gbatch_call_list_arg:[cb_name], index);
            } else {
               call_index(index);
            }
         }
      }
   }

   // clean house
   gbatch_call_list_arg   = null;
   gbatch_call_list_count = null;
   gbatch_call_list_timer = -1;
}

/**
 * In a frequently called event handler, sometimes you will want to 
 * group events together and handle them all in one shot using a more 
 * general refresh function instead of a piecemeal handler for the 
 * specific event. 
 * <p> 
 * Call this function to schedule a one-shot timer to invoke a general 
 * refresh function.  It only scedules the timer to call the refresh 
 * function after four singular events have passed.  This way the 
 * simple, faster, piecemeal handler can be used for isolated events 
 * and you only go to the general, more expensive refresh handler for 
 * larger updates. 
 *  
 * @return The function returns 'true' if the threshold has been reached 
 *         and the rest of the event handler callback should be ignored.
 *         Otherwise, it returns false, and the caller is responsible
 *         for handling the event handler callback itself. 
 * 
 * @param callback_name          name of general refresh callback to call_event
 * @param batch_arg              argument to pass to refresh callback 
 * @param forceCallbackOnTimer   force callback, don't wait for threshold 
 *  
 * @see call_list 
 * @see close_all 
 *  
 * @categories Miscellaneous_Functions
 */
bool batch_call_list(_str callback_name, typeless batch_arg=null, 
                        bool forceCallbackOnTimer=false)
{
   // count the number of times we have been called for this event 
   skipEvent := true;
   if (!gbatch_call_list_count._indexin(callback_name)) {
      gbatch_call_list_count:[callback_name] = 1;
      skipEvent = false;
   } else if ( ++gbatch_call_list_count:[callback_name] <= BATCH_CALL_LIST_THRESHOLD ) {
      skipEvent = false;
   }

   // force callback to be queued up immediately
   if (forceCallbackOnTimer) {
      gbatch_call_list_count:[callback_name] = BATCH_CALL_LIST_THRESHOLD+1;
      skipEvent = true;
   }

   // save argument to pass along to callback
   gbatch_call_list_arg:[callback_name] = batch_arg;

   // start the timer function
   if (gbatch_call_list_timer < 0) {
      gbatch_call_list_timer = _set_timer(1, batch_call_list_timer_proc);
   }

   // Return 'true' if we should skip the rest of the processing
   return skipEvent;
}

/**
 * Customize menu based on 1FPW (1-File-Per-Window) setting.
 * 
 * @param menu_handle
 * @param no_child_windows
 */
void _init_menu_1fpw(int menu_handle, int no_child_windows)
{
   if ( def_one_file == '' ) {
      // Not in 1FPW mode
      return;
   }

   //
   // Document menu
   //

   int submenu_handle;
   int index = _menu_find_loaded_menu_caption(menu_handle, 'Document', submenu_handle);
   if ( index < 0 ) {
      return;
   }

   // These menu items are very confusing to the user if not in 1FPW mode
   int unused;
   int status = _menu_find(submenu_handle, 'next-buffer', unused, index, 'M');
   if ( !status ) {
      _menu_delete(submenu_handle, index);
   }
   status = _menu_find(submenu_handle, 'prev-buffer', unused, index, 'M');
   if ( !status ) {
      _menu_delete(submenu_handle, index);
   }
   status = _menu_find(submenu_handle, 'close-buffer', unused, index, 'M');
   if ( !status ) {
      _menu_delete(submenu_handle, index);
   }
}


/**
 * Save the all markers in the given file, optionally restricting the 
 * markers to a range of lines, and optionally saving relocation 
 * information.  This includes: 
 * <ul> 
 *    <li>Bookmarks (regular and bookmark stack)</li>
 *    <li>Debugger breakpoints</li> 
 *    <li>Code Annotations</li> 
 *    <li>Symbol References</li>
 * </ul>
 * 
 * This function is used to save marker information before 
 * we do something that heavily modifies a buffer, such as 
 * refactoring, beautification, or auto-reload.  It uses the 
 * relocatable marker information to attempt to restore the 
 * markers back to their original line, even if the actual 
 * line number has changed because lines were inserted or deleted.
 * 
 * @param markerSaves      Saved markers 
 * @param adjustLinesBy    Number of lines to adjust start line by
 *  
 * @see MarkerSaveInfo 
 * @see _RestoreMarkersInFile 
 * @see _SaveBookmarksInFile
 * @see _SaveBreakpointsInFile
 * @see _SaveAnnotationsInFile
 * @see _SaveReferencesInFile
 */
void _SaveMarkersInFile(MarkerSaveInfo &markerSaves,
                        int startRLine=0, int endRLine=0,
                        bool relocatable=true)
{
   markerSaves.bookmarks._makeempty();
   markerSaves.breakpoints._makeempty();
   markerSaves.annotations._makeempty();
   markerSaves.references._makeempty();
   markerSaves.messages._makeempty();

   if (!_isEditorCtl()) return;

   _SaveBookmarksInFile(   markerSaves.bookmarks,   startRLine, endRLine, relocatable );
   _SaveBreakpointsInFile( markerSaves.breakpoints, startRLine, endRLine, relocatable );
   _SaveAnnotationsInFile( markerSaves.annotations, startRLine, endRLine, relocatable );
   _SaveReferencesInFile(  markerSaves.references,  startRLine, endRLine, relocatable );
   _SaveMessagesInFile(    markerSaves.messages,    startRLine, endRLine, relocatable );
}

/**
 * Restore saved markers from the current file and relocate them
 * if the marker information includes relocation information. 
 * This includes: 
 * <ul> 
 *    <li>Bookmarks (regular and bookmark stack)</li>
 *    <li>Debugger breakpoints</li> 
 *    <li>Code Annotations</li> 
 *    <li>Symbol References</li>
 * </ul>
 * 
 * @param markerSaves      Saved markers 
 * @param adjustLinesBy    Number of lines to adjust start line by
 *  
 * @see MarkerSaveInfo 
 * @see _SaveMarkersInFile 
 * @see _RestoreBookmarksInFile
 * @see _RestoreBreakpointsInFile
 * @see _RestoreAnnotationsInFile
 * @see _RestoreReferencesInFile
 */
void _RestoreMmrkersInFile(MarkerSaveInfo &markerSaves, int adjustLinesBy=0)
{
   if (!_isEditorCtl()) return;
   _RestoreBookmarksInFile(   markerSaves.bookmarks,   adjustLinesBy);
   _RestoreBreakpointsInFile( markerSaves.breakpoints, adjustLinesBy);
   _RestoreAnnotationsInFile( markerSaves.annotations, adjustLinesBy);
   _RestoreReferencesInFile(  markerSaves.references,  adjustLinesBy);
   _RestoreMessagesInFile(    markerSaves.messages,    adjustLinesBy);
}
