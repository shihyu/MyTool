////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50292 $
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
#include "eclipse.sh"
#include "treeview.sh"
#import "adaptiveformatting.e"
#import "annotations.e"
#import "bookmark.e"
#import "compile.e"
#import "complete.e"
#import "debug.e"
#import "diff.e"
#import "dlgman.e"
#import "eclipse.e"
#import "fileman.e"
#import "get.e"
#import "gnucopts.e"
#import "guiopen.e"
#import "forall.e"
#import "hex.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#require "menu.e"
#import "moveedge.e"
#import "os2cmds.e"
#import "put.e"
#import "recmacro.e"
#import "saveload.e"
#import "sellist.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbdeltasave.e"
#import "tbfind.e"
#import "tbsearch.e"
#import "toast.e"
#import "toolbar.e"
#import "util.e"
#require "vc.e"
#import "vchack.e"
#import "window.e"
#import "xml.e"
#import "xmlwrap.e"
#import "wkspace.e"
#require "se/lang/api/LanguageSettings.e"
#import "project.e"
#import "projutil.e"
#import "complete.e"
#import "doscmds.e"
#import "mprompt.e"
#require "seltree.e"
#import "se/search/SearchResults.e"
#endregion

using se.lang.api.LanguageSettings;

#if __OS390__ || __TESTS390__
   #define FILECOUNTWARNING 20
   #define FILESOPENEDWARNING 100
#else
   #define FILECOUNTWARNING 100
   #define FILESOPENEDWARNING 500
#endif

#define CALLED_FROM_ECLIPSE '-CFE'

no_code_swapping;  /* Just in case there is an I/O error reading */
                   /* the slick.sta file, this will ensure user */
                   /* safe exit and save of files.  */

int vsvOpenTempView(_str filename, int &tempWID);

enum ActAppFlags {
   ACTAPP_AUTORELOADON                 = 0x1,
   ACTAPP_SAVEALLONLOSTFOCUS           = 0x2,
   ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED = 0x4,
   ACTAPP_WARNONLYIFBUFFERMODIFIED     = 0x8,
   ACTAPP_AUTOREADONLY                 = 0x10,
   ACTAPP_DONT_RELOAD_ON_SWITCHBUF     = 0x20,
   ACTAPP_CURRENT_FILE_ONLY            = 0x40,
   ACTAPP_TEST_ALL_IF_CURRENT_MODIFIED = 0x80,
};

boolean def_autoreload_compare_contents = true;
int def_autoreload_compare_contents_max_size = 2000000;

int def_fast_auto_readonly     = 1;
boolean def_batch_reload_files = true;
int def_autoreload_timeout_threshold     = 5000;
boolean def_autoreload_timeout_notifications = true;


/////////////////////////////////////////////////////////////////////
// Used by batch_call_list() utility functions for grouping 
// together calls to handlers for call_list callbacks.
//
#define BATCH_CALL_LIST_THRESHOLD 8
static int gbatch_call_list_timer = -1;
static int gbatch_call_list_count:[];
static typeless gbatch_call_list_arg:[];
 

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
   _str buf_name='';
   if ( buf_name_arg=='' ) {
      buf_name=p_buf_name;
   }
   _str buffer_name=prompt(buf_name_arg,'',make_buf_match(buf_name));
   _str name='';
   _str path='';
   parse buffer_name with name'<'path'>';
   if ( path!='' ) {
      buffer_name=path:+name;
   }
   _str attempt=absolute(strip(buffer_name));
   if ( attempt=='' ) {
      return(1);
   }
   int status=edit('+b 'maybe_quote_filename(attempt));
   if ( status ) {
      clear_message();
      status=edit('+b 'maybe_quote_filename(buffer_name));
   }
   return(status);
}
static int edit_count;
static _str gfirst_info;


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
 *   <DT>+FU [<i>buf_name</i>]   <DD>Force SlickEdit to interpret a file in UNIX format.
 *   <DT>+FM [<i>buf_name</i>]   <DD>Force SlickEdit to interpret a file in MAC format.
 *   <DT>+FD [<i>buf_name</i>]   <DD>Force SlickEdit to interpret a file in DOS format.
 *   <DT>+F<i>nnn</i>   <DD>Force SlickEdit to use <i>nnn</i> as the decimal value of the line separator character.
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
   if (!isinteger(a2_flags)) a2_flags=0;

#if 1
   if (_executed_from_key_or_cmdline(name_name(last_index('','C')))) {
      // Want smart open if executed from command line, key press, menu, or toolbar button
      a2_flags=EDIT_DEFAULT_FLAGS|EDIT_SMARTOPEN;
      //say('default 'filenameArg);
   }
   //say('a2_flags='a2_flags);
   int restorepos_flag=(a2_flags&EDIT_RESTOREPOS);
#else
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
   _str old_buffer_name='';
   typeless swold_pos='';
   int swold_buf_id=0;
   set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
   _str n='e';
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

   mou_hour_glass(1);
   typeless status=edit2(filename,a2_flags|restorepos_flag,auto_create_firstw_arg);
   if (a2_flags & VCF_AUTO_CHECKOUT) {
      _mfXMLOutputIsActive=1;
   }
   mou_hour_glass(0);
   switch_buffer(old_buffer_name,'E',swold_pos,swold_buf_id);
   if (!_no_child_windows() && !(a2_flags&EDIT_NOSETFOCUS)) {
      int final_wid=p_window_id;
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
   filename=maybe_quote_filename(filename);
   _str first_window='';
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
   _str result='';
#if FILESEP=='\'
   name=stranslate(name,'\\','\');
#endif
   for (;;) {
      if (match=='') {
         return(result);
      }
      if (!endsWith(match,name,false,_fpos_case'&')) {
         match=buf_match(name, 0, 'N');
         continue;
      }
      if (result!='') result:+=' ';
      result:+=maybe_quote_filename(match);
      match=buf_match(name, 0, 'N');
   }

}
enum_flags EditFlags {
   EDITFLAG_WORKSPACEFILES,
   EDITFLAG_BUFFERS,
};
static _str _listDiskFiles(_str filename) {
   int orig_view_id=_create_temp_view(auto list_view_id);
   if (orig_view_id=='') return(NOT_ENOUGH_MEMORY_RC);
   insert_file_list('-v +p 'maybe_quote_filename(filename));
   top();up();
   _str result='';
   while(!down()) {
      auto line=_lbget_text();
      if (result:!='') {
         result:+=result;
      }
      result=result:+maybe_quote_filename(line);
   }
   activate_window(orig_view_id);
   return(result);
}
EditFlags def_edit_flags=EDITFLAG_WORKSPACEFILES|EDITFLAG_BUFFERS;
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
   _str options='';
   int new_file_status=0;
   _str first_info='';
   _str first_window='';
   boolean filesOpenedPrompt = true;
   int totalOpened = 0;
   boolean useCache=true;
   boolean includeHTTPHeader=false;
   boolean allow_smartopen=(a2_flags & EDIT_SMARTOPEN) && (def_edit_flags &(EDITFLAG_WORKSPACEFILES|EDITFLAG_BUFFERS));
   typeless old_buf_flags=0;
   typeless old_buf_id=0;
   typeless list_view_id=0;
   typeless orig_view_id=0;
   boolean expandWildcards=true;
   int answer=0;

   typeless status=0;
   typeless result=0;
   boolean ExplicitWindowSizeGiven=false;
   _str line=def_one_file' 'filename;
   _str command='';
   _str exFlags='';
   _str param='';
   _str name='';
   _str info='';
   boolean encoding_set_by_user=false;
   int one_file_per_window_explicitly_specified=0; 
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
      _str word_nq=strip(word,'B','"');

      if ( substr(word_nq,1,1)=='+' || substr(word_nq,1,1)=='-' ) {
         _str letter=upcase(substr(word_nq,2,1));
         if ( letter=='T' || letter=='V' || letter=='B' ) {
            if ( letter=='B' ) {
               param=line;
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
            status=window_edit(def_load_options " "options" "first_window" "word_nq " "param,a2_flags);
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
            options=options " "word_nq;
            if (substr(word_nq,3,1)==':') {
               /* Add the y,width,height,state options. */
               _str y='';
               _str width='';
               _str height='';
               _str state='';
               parse line with y width height state line;
               options=options' 'y' 'width' 'height' 'state;
               ExplicitWindowSizeGiven=true;
            }
            //  One of +FXXXX options and not +fd +fu +fm and not +fNNNNN
         } else if (letter=='F' && length(word_nq)>3 && !(isinteger(substr(word_nq,3)))) {
            // Must be +fcpNNNN  +ftext +futf8 +futf16le etc.
            encoding_set_by_user=true;
            options=options " "word_nq;
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
            _str oneFilePerWindowOption=substr(upcase(word_nq),1,2);
            if (oneFilePerWindowOption=='+W') {
               one_file_per_window_explicitly_specified=1;
            } else if (oneFilePerWindowOption=='-W') {
               one_file_per_window_explicitly_specified= -1;
            }
            options=options " "word_nq;
         }
         continue;
      }
      int fileCount = 0;
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
         boolean do_smartopen=allow_smartopen && !_isHTTPFile(word) && 
            !iswildcard(_strip_filename(word_nq,'p')) &&  // AND not a wild card in name part
            // Need this for performance. On Unix, /abc/file looks absolute and
            // I'm not sure if this will be a problem.
            absolute(word_nq)!=word_nq;   
         if ( !do_smartopen &&
              expandWildcards && iswildcard(word) && 
              !_isHTTPFile(word) && (!__UNIX__ || !file_exists(strip(word,'B','"')))) {
            orig_view_id=_create_temp_view(list_view_id);
            if (orig_view_id=='') return(NOT_ENOUGH_MEMORY_RC);
            status=insert_file_list('-v +p 'word);
            if (!status) {
               fileCount = p_Noflines;
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
               _str foundFileList='';
               if (file_exists(word_nq)) {
                  foundFileList= maybe_quote_filename(absolute(word_nq));
               }
               foundFileList=_listDiskFiles(word_nq);
               if (def_edit_flags &EDITFLAG_BUFFERS) {
                  foundFileList = foundFileList' 'appendEditBuffers(word_nq);
               }
               if ((def_edit_flags &EDITFLAG_WORKSPACEFILES) && _workspace_filename!='') {
                  foundFileList = foundFileList' '_WorkspaceFindFile(word_nq, _workspace_filename, false, false, true,true);
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
         _str fileTypeText = "files";
         if (fileCount > FILECOUNTWARNING) {
            // Use the first name to determine the file type.
            _str name2 = strip(name,'B','"');
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
            if (filesOpenedPrompt && totalOpened > FILESOPENEDWARNING) {
               int remaining = fileCount - totalOpened;
               if (remaining > FILESOPENEDWARNING/4) {
                  answer = _message_box(nls("Opened %s %s. %s remaining.\n\nContinue and open the remaining %s?\nYou will not be prompted again.",totalOpened,fileTypeText,remaining,fileTypeText),"",MB_YESNO);
                  if (answer != IDYES) return(0);
                  filesOpenedPrompt = false;
               }
            }
            //block_was_read(0);
#if 0
            info=_get_file_info(maybe_quote_filename(name));
            //messageNwait('info='info);
            if (def_one_file!='') {
               parse info with x y width height state .;
               if (info!=''&&p_window_state!='M' && state!='M') {
                  options=options' +i:'x' 'y' 'width' 'height' 'state;
               } else {
                  info='';
               }
            }
#else
            info='';
#endif
            block_was_read(0);
            // Code for preloading when filesize
            //parse def_max_loadall with on size;
            //if (pos('\+l(??|?|)', def_load_options, 1, 'RI') && !pos('(\+|-)l', options, 1, 'IR')) {

            /*TempNoLoad="";
            if (on && isinteger(size) && size > 0 &&
               _filesize(name) > size * 1024) {
               TempNoLoad='-L ';
            } */
            //messageNwait(build_load_options(name) " "first_window" "options);

            first_window="";
            if (!ExplicitWindowSizeGiven) {
               //the +t tells first window to go ahead and resize the new window
               first_window=set_first_window('+t',auto_create_firstw_arg,one_file_per_window_explicitly_specified);
            }

            _str enqOption = "";
            // If the file to be opened is a data set, put an ENQ on it.
            // Prevent the file from being opened if the ENQ failed.
            // Also don't ENQ if data set is opened read-only.
            _str nameonly = strip(name,'B','"');
            if (_DataSetIsFile(nameonly)) {
               if (!pos("read_only_mode 1", command)) {
                  //say("edit2 ENQ filename="nameonly);
                  enqOption = "+ENQ ";
               }

               // If data set is migrated, let user know. We only do this
               // if the edit command was executed from the command line,
               // activated from a menu item, or from Open File dialog.
               int idx = last_index('', 'W');
               int showMigrateMsg = pos("show_migrate_message", exFlags);
               if ((idx || showMigrateMsg) && _os390IsMigrated(name)) {
                  _message_box(name" is migrated.\n\nRecalling data set...");
               }
            }
            status = 0;
#if __OS390__ || __TESTS390__
            // Check spill space before opening any file.
            status = _checkSpillSpace();
#endif
            boolean isHTTPFile=false;
            if (!status) {
               //status=window_edit(build_load_options(name) " "first_window" "options" "maybe_quote_filename(name),a2_flags)

               isHTTPFile=_isHTTPFile(name);
               if (!isHTTPFile) {
#if __UNIX__
                  _str samba_prefix="";
                  if( substr(name,1,2)=='//' ) {
                     // Samba share
                     samba_prefix=substr(name,1,2);
                     name=substr(name,3);
                  }
                  name=samba_prefix:+stranslate(name,FILESEP,FILESEP:+FILESEP);
#else
                  _str unc_prefix="";
                  if( substr(name,1,2)=='\\' ) {
                     // UNC path
                     unc_prefix=substr(name,1,2);
                     name=substr(name,3);
                  }
                  name=stranslate(name,FILESEP,FILESEP:+FILESEP);
                  // Have to also handle paths with mixed up '\' and '/'
                  name=unc_prefix:+stranslate(name,FILESEP2,FILESEP2:+FILESEP2);
#endif
                  status=window_edit(enqOption:+build_load_options(name) " "/*TempNoLoad:+*/options" "first_window" "maybe_quote_filename(name),a2_flags);
               } else {
                  _str SEURLFilename='';
                  boolean was_mapped=false;
                  name=translate(name,'/','\');
                  status=_mapxml_find_system_file(name,'',SEURLFilename,-1,was_mapped);
                  if (!status) {
                     int oldCache=_UrlSetCaching(useCache?1:2);
                     oldIncludeHeader := _UrlSetIncludeHeader(includeHTTPHeader);
                     status=window_edit(enqOption:+build_load_options(SEURLFilename) " "/*TempNoLoad:+*/options" "first_window" "maybe_quote_filename(SEURLFilename),a2_flags);
                     _UrlSetCaching(oldCache);
                     _UrlSetIncludeHeader(oldIncludeHeader);

                  }
                  if (status) {
                     for (;;) {
                        result=_mapxml_http_load_error(name,was_mapped,status,SEURLFilename,'');
                        if (result=='') break;
                        if (status) {
                           status=FILE_NOT_FOUND_RC;
                        } else {
                           status=window_edit(enqOption:+build_load_options(SEURLFilename) " "/*TempNoLoad:+*/options" "first_window" "maybe_quote_filename(SEURLFilename),a2_flags);
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
            int showErrorInMsgBox = pos("show_error_in_msgbox", exFlags);
            if (!(a2_flags&EDIT_NOSETFOCUS) && showErrorInMsgBox && status) {
               _message_box(nls("Can't edit %s.\n\n%s.",nameonly,get_message(status)));
            }

            //Put switchbuf here
            first_window='';
            edit_status(status,new_file_status,first_info, a2_flags, info);
            if ( status ) {
               if ( status!=NEW_FILE_RC ) { 
                  _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_FILE_OPEN_ERROR, "Error opening file: "get_message(status));
               } else {
                  _InitNewFileContents();
               }
            }
            if (!status && isHTTPFile) {
               docname(name);
            }
            if (!status && edit_count<def_max_filehist && !(a2_flags &EDIT_NOADDHIST)) {
               ++edit_count;
               _menu_add_filehist((isHTTPFile)?name:absolute(name));
            }
            block_was_read(1);read_ahead();
            if ( status && status!=NEW_FILE_RC ) {
               if (list_view_id!='') _delete_temp_view(list_view_id);
               return(status);
            }
            if (command!='') {
               execute(command,'');
            }
            if ( !expandWildcards || !iswildcard(word) || isHTTPFile ||
                 (__UNIX__ && file_exists(strip(word,'B','"')))) {
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
   // See if auto validation is on.  If it is on, then the user wants to
   // validate on open.  The default if no value is present is to auto validate
   _str bufext = _get_extension(p_buf_name);
   if (bufext=='xsd' || bufext=='xmldoc' || bufext=='xsl' || bufext=='xslt' || pos(' .'p_LangId' ',' 'def_xml_no_schema_list' ')) {
      // Do not do validate on these because they do not have DTD
      // and are not valid.
      return;
   }
   if (_LanguageInheritsFrom('xml') && gXMLAutoValidateBehavior != VSXML_AUTOVALIDATE_BEHAVIOR_DISABLE) {
      if (LanguageSettings.getAutoValidateOnOpen(p_LangId) && p_buf_size<3000000 /* 3 megabytes */) {
         xmlparse(VSXML_VALIDATION_SCHEME_VALIDATE, false);
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
   if (!(a2_flags & EDIT_NOUNICONIZE) && p_window_state=='I') p_window_state='N';
   boolean displayTranslationError=false;
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
      _str command='read-only-mode';
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
            int old_wid = p_window_id;
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
      }
   }
   if (displayTranslationError) {
      _message_box("Warning:  Not all characters could be translated to Unicode.  Untranslatable characters have been replaced by '?' characters.  Make sure you specified the correct encoding.\n\nSaving this file will NOT restore the file's original content.");
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
   boolean bCalledFromEclipse = false;
   _str cfe_option='';

   _str cfe_cmd = cmdline;
   parse cfe_cmd with cfe_cmd .;
   if (pos(CALLED_FROM_ECLIPSE, cfe_cmd)) {
      int index = pos(CALLED_FROM_ECLIPSE, cmdline);
      cmdline = substr(cmdline, 1, index-1):+ substr(cmdline, index+length(CALLED_FROM_ECLIPSE)+1);
      bCalledFromEclipse = true;
      cfe_option='-CFE';
   }
   // If were started as part of the eclipse plug-in then
   // we need to save as the "Eclipse" way
   //
   if (!bCalledFromEclipse && isEclipsePlugin()) {
      if(_eclipse_save_as(p_window_id, cmdline, sv_flags) == 0){
         p_modify = 0;
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

   int preserve_old_name=0;
   _str read_only='';
   _str save_options='';
   _str option='';
   _str ch='';
   _str temp='';
   for (temp=line;;) {
      option=parse_next_option(temp,false);
      option=upcase(option);
      if (option=='-N') {
         parse_next_option(line);
         preserve_old_name=1;
         save_options=save_options:+'+N ';
      } else if (option=='-R') {
         parse_next_option(line);
         read_only='-R ';
      } else {
         ch=substr(option,1,1);
         if (ch=='-' || ch=='+') {
            parse_next_option(line);
            save_options=save_options:+option' ';
         } else {
            break;
         }
      }
   }

   _str orig_line = line;
   line=strip(line,'B','"');
   if (preserve_old_name || _process_info('b') || file_eq(p_buf_name,absolute(line))) {
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
         filename = filename :+ _strip_filename(p_buf_name,'p');
      }
      _str old_buf_name=p_buf_name;
      //old_modify=p_modify;
      //old_buf_flags=p_buf_flags;
      boolean old_readonly_mode=p_readonly_mode;
      status = name_file(filename);
      if (status) return(status);
      // Defer forcing buffer to RW mode after the buffer rename.
      p_readonly_mode=0;
      // Force recalculation of adaptive formatting settings.
      p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(p_LangId);
      // In v13, Setting the editor language gets ignored unless p_LangId=''.
      p_LangId='';
      _SetEditorLanguage();
      status=save(read_only:+save_options:+cfe_option,sv_flags);
      if ( status ) {
         p_readonly_mode=old_readonly_mode;
         //call_list('_buffer_renamed_',p_buf_id,p_buf_name,old_buf_name,old_buf_flags);
         int status2 = name_file(old_buf_name);
         if (status2) return(status2);
         // Force recalculation of adaptive formatting settings.
         p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(p_LangId);
         // In v13, setting the editor language gets ignored unless p_LangId=''.
         p_LangId='';
         _SetEditorLanguage();
         //p_buf_name=old_buf_name;
         //p_modify=old_modify;
         //p_buf_flags=old_buf_flags;
      } else {
         p_readonly_mode= (read_only!='');
         p_readonly_set_by_user=0;
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
   // IF the user save the file as Unicode while in hex mode
   if (p_UTF8 && p_hex_mode) {
      // Get out of hex mode.
      hex_off();
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
boolean _executed_from_key_or_cmdline(_str cmdname)
{
   typeless executed_from_key=name_name(last_index()):==translate(cmdname,'-','_');
   typeless executed_from_cmdline=last_index('','w');
   return(executed_from_key || executed_from_cmdline);
}


int _OnUpdate_revert(CMDUI &cmdui,int target_wid,_str command)
{
   if (_no_child_windows()) {
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
      int orig_col=p_col;
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
      if (!target_wid.p_modify) {
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

/**
 * Reverts or refreshes the current buffer to the contents of the latest version
 * on disk.  If the buffer has been modified, then we revert.  If the file has 
 * not been modified, but has an earlier time stamp than the file on disk, then 
 * the file is refresh. 
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
      bfiledate := _file_date(p_buf_name, 'B');
      if (p_file_date :!= bfiledate && !_FileIsRemote(p_buf_name));

      temp_wid := 0;
      orig_wid := 0;
      status := _open_temp_view('', temp_wid, orig_wid, "+bi "p_buf_id);
      if (status == 0) {
         _ReloadCurFile(temp_wid, bfiledate, false, true, null, false);
         if ( useWholeFileCompare() && DSBackupVersionExists(p_buf_name) ) {
            DS_CreateDelta(p_buf_name);
            DSSetVersionComment(p_buf_name, -1, "Created by File > Reload."); 
         }

         temp_wid.p_file_date = (long)bfiledate;
         temp_wid.p_file_size = _file_size(p_buf_name);
         _delete_temp_view(temp_wid);
         if (_iswindow_valid(orig_wid)) {
            activate_window(orig_wid);
         }
      }
   }
}

#if __UNIX__
// Mac implementation to move a file to the trash
// Exported from the macutils library
int macMoveFileToTrash(_str filePath);
#endif
#if __PCDOS__
// Windows implementation to place a file in the recycle bin
// Exported from winutils.dll
extern int ntRecycleFile(_str filePath);
#endif

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
#if __PCDOS__
        return ntRecycleFile(filePath);
#endif
#if __UNIX__
        if (_isMac()) {
            return macMoveFileToTrash(filePath);
        } else {
            _str commandLine = '';
            if(def_trash_command != '') {

               // Replace the %f placeholder with the file path, in quotes if needed
               commandLine = stranslate(def_trash_command, maybe_quote_filename(filePath), "%f");

            } else {

               _str session_name = get_xdesktop_session_name();
               if (session_name == 'gnome') {
   
                   // Gnome: Look for the gvfs-trash command
                   _str gvsPath = path_search('gvfs-trash');
                   if (gvsPath != '') {
                       // >gvfs-trash /path/to/file.ext
                       def_trash_command = gvsPath :+ " %f";
                       commandLine = gvsPath :+ ' ' :+ maybe_quote_filename(filePath);
                   }
   
               } else if (session_name == 'kde') {
   
                   // KDE: Look for the kfmclient utility
                   _str kfmcPath = path_search('kfmclient');
                   if (kfmcPath != '') {
                       // >kfmclient move /path/to/file.ext trash:/
                       def_trash_command = kfmcPath :+ " move %f trash:/";
                       commandLine = kfmcPath :+ " move " :+ maybe_quote_filename(filePath) :+ " trash:/";
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
                       commandLine = trashPutPath :+ ' ' :+ maybe_quote_filename(filePath);
                   }
               }
            }

            if (commandLine != '') {
                return shell(commandLine, 'NA');
            }
        }
#endif
    }
    return delete_file(filePath);
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
_command int save(_str cmdline='',int flags= -1) name_info(','VSARG2_ICON|VSARG2_NOEXIT_SCROLL|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   boolean bCalledFromEclipse = false;

   if (!p_HasBuffer) {
      p_window_id=_mdi.p_child;
   }
   if (!p_mdi_child && !p_IsTempEditor && !p_AllowSave) {
      _beep();
      return(1);
   }
   if (!isinteger(flags) || flags== -1) flags=SV_RETRYSAVE;
   boolean preplace=!(flags&SV_OVERWRITE) && def_preplace;
   _str options='';
   _str filename=strip_options(cmdline,options,false,true);
   if (pos(CALLED_FROM_ECLIPSE, options)) {
      int index = pos(CALLED_FROM_ECLIPSE, options);
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
         p_modify = 0;
         return (0);
      }
      cmdline = _origCmdLine;
   }

   if ( filename=='') {
      filename=p_buf_name;
      if ( filename=='' || !_HaveValidOuputFileName(filename) ||
           (p_readonly_mode && !_isdiffed(p_buf_id)
            && file_eq(absolute(filename),p_buf_name))
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
               int ro_status = _readonly_error(0,true,true);
               if (ro_status || !p_readonly_mode) {
                  return ro_status;
               }
            } else {
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
   _str afilename=absolute(filename);
   /* IF name of buffer has been changed or new file  OR  saving to  */
   /* different file AND destination file already exists AND prompt on replace */
   /* and called from a key/command line/or option given. */
   if ( preplace && (p_buf_flags&VSBUFFLAG_PROMPT_REPLACE || !file_eq(strip(afilename,'','"'),p_buf_name)) &&
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
       file_eq(strip(afilename,'','"'),p_buf_name) &&
       p_file_date!="" && p_file_date!=0 &&
       file_exists(filename) &&
       p_file_date<_file_date(filename,'B')) {
      status=overwrite_newer(filename,'Save',flags);
      if ( status ) {
         return(status);
      }
   }
   update_format_line('1');
   message(nls('Saving %s',filename));
   if (!_HaveValidOuputFileName(afilename)) {
      message(nls('Invalid filename'));
      return(1);
   }
   filename=maybe_quote_filename(filename);
   _str nobackup="";
   if ((flags & SV_POSTMSGBOX)) flags&=~SV_RETRYSAVE;
   for (;;) {
      _str tempoptions=options:+nobackup;
      int save_read_only=0;
#if __UNIX__

      /* On UNIX, allow user to specify -r or +r to save as read only. */
      _str options2='';
      parse tempoptions with tempoptions '(-|\+)r','ir' +0 options2;
      _str ch=lowcase(substr(options2,1,2));
      if ( ch=='-r' || ch=='+r' ) {
         tempoptions=tempoptions:+substr(options2,3);
         save_read_only=1;
         /* Owner does not have write access. */
         status=_chmod('u+w 'filename);
         //status=_chmod('u+w 'p_buf_name);
         if ( status && status!=FILE_NOT_FOUND_RC) {
            if (flags & SV_RETURNSTATUS) {
               return(status);
            }
            _sv_message_box(flags,nls("Failed to change file permissions.  Check that you have access to the owner or group of this file."));
            return(status);
         }
      }
#endif
      mou_hour_glass(1);
      status= save_file(filename,build_save_options(filename) " "tempoptions);
      if (!status  && !(flags & SV_NOADDFILEHIST)) {
         _menu_add_filehist(strip(filename,'B','"'));
      }
      mou_hour_glass(0);
#if __UNIX__
      if (save_read_only && !_DataSetIsFile(filename)) {
         int status2=_chmod('u-w 'filename);
         if ( !status && status2 ) {
            status=status2;
            message(get_message(status));
         }
      }
#endif
      clear_message();
      if ( status==0 ) {
         if ( file_eq(afilename,p_buf_name) ) {
            p_buf_flags=p_buf_flags&~VSBUFFLAG_PROMPT_REPLACE;
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
         nobackup=nobackup:+" +o";
      }
      // local backup directory might have been changed.
   }
   return(status);
}
int _save_status(var status,_str buf_name,_str filename='', int sv_flags=0)
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
   _str msg='';
   if (filename!="" && filename!=buf_name) {
      //filename=buf_name;
      msg=nls("Unable to save %s to %s\n",buf_name,filename);
   } else {
      msg=nls("Unable to save %s\n",buf_name);
   }
   if (status==ACCESS_DENIED_RC) {
      if (retrysave) {
         if (_DataSetIsFile(buf_name)) {
            _str msg2 = msg:+ get_message(status);
            msg2 = msg2 :+ ".\nData set may be currently in use by another process.\nPlease check and try again.";
            _message_box(msg2);
            return(0);
         }
      }
#if __UNIX__
      if (retrysave) {
         _str attrs=file_list_field(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
         if (attrs=='') return(0);
         // IF there are no write permissions on this file.
         if (!pos("w","")) {
            int flags=1;  // Save as read only
            status=show("-modal _retrysave_form",msg:+ get_message(status),flags);
            if (!isinteger(status)) return(0);
            return(status);
         }
      }
#endif
      _str backup_msg="Backup directory could not be created.\n";
      if (pos(' +d ',' 'def_save_options' ',1,'i')) {
         _str dir=_replace_envvars(get_env('VSLICKBACKUP'));
         if (dir=='') {
#if __UNIX__
            dir=get_env('HOME');
            if (last_char(dir)!=FILESEP) dir=dir:+FILESEP;
            dir=dir:+'.vslick/backup';
#else
            dir='\vslick\backup';
#endif
         }
         if (last_char(dir)==FILESEP) {
            dir=substr(dir,1,length(dir)-1);
         }
         backup_msg='';
         if (file_match('-p 'dir,1)=='') {
            backup_msg="Backup directory '"dir"' could not be created.\n";
         }
      }
      _str msg2="\n\n":+
      "Possible causes:\n\n":+
      backup_msg:+
#if __UNIX__
      "Permissions on this file are read only.\n":+
      "Another program has a lock on this file.\n":+
#else
      "Another program has this file open.\n":+
#endif
      "\nSee help on \"Backup options\".";
      _sv_message_box(sv_flags,msg:+ get_message(status):+msg2);
      return(0);
   }
   if (retrysave) {
      if (status==FAILED_TO_BACKUP_FILE_RC
#if !__UNIX__
          || status==FAILED_TO_BACKUP_FILE_ACCESS_DENIED_RC
#endif
         ) {
         int flags=2;
         // UNIX always uses a local backup directory "$HOME/.vslick"
#if !__UNIX__
         if (pos(' [\+|\-]d '," "def_save_options" ",1,'RI')) {
            flags=2|4;
         }
#endif
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
_str overwrite_existing(_str filename, _str title, int sv_flags=0)
{
   boolean post_msgbox=isinteger(sv_flags) && (sv_flags & SV_POSTMSGBOX);
   int orig_wid=p_window_id;_set_focus();
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
   boolean post_msgbox=isinteger(sv_flags) && (sv_flags & SV_POSTMSGBOX);
   int orig_wid=p_window_id;_set_focus();
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
   boolean post_msgbox=isinteger(sv_flags) && (sv_flags & SV_POSTMSGBOX);
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
      ctl_cancel.p_x = ctl_ok.p_x + ctl_ok.p_width + 60;
      ctl_invert.p_x = ctl_cancel.p_x + ctl_cancel.p_width + 60;
      ctl_selectall.p_eventtab = defeventtab _reload_modified_diff_button;
      ctl_selectall.p_x = ctl_invert.p_x + ctl_invert.p_width + 60;
      ctl_selectall.p_y = ctl_invert.p_y;
      ctl_selectall.p_caption = "&Diff Selected";
      ctl_selectall.p_auto_size = true;
      ctl_tree.p_NeverColorCurrent = true;
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
      ctl_cancel.p_x = ctl_ok.p_x + ctl_ok.p_width + 60;
      ctl_invert.p_x = ctl_cancel.p_x + ctl_cancel.p_width + 60;
      ctl_selectall.p_eventtab = defeventtab _save_deleted_close_button;
      ctl_selectall.p_x = ctl_invert.p_x + ctl_invert.p_width + 60;
      ctl_selectall.p_y = ctl_invert.p_y;
      ctl_selectall.p_caption = "&Close Selected";
      ctl_selectall.p_width = 120 + _text_width(ctl_selectall.p_caption);
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
#if __UNIX__
   flags&=~4;
#endif
   if (msg!="") {
      ctllabel1.p_caption=msg;
   }
   if (!(flags&1)) {
#if __UNIX__
      ctlreadonly.p_enabled=0;
#else
      ctlreadonly.p_visible=0;
#endif
   }
   if (!(flags&2)) {
      ctlnobackup.p_enabled=0;
   }
   if (!(flags&4)) {
#if __UNIX__
      ctlconfigbackupdir.p_visible=ctlbackupdir.p_visible=ctlbackupdirlab.p_visible=0;
#else
      ctlconfigbackupdir.p_enabled=ctlbackupdir.p_enabled=ctlbackupdirlab.p_enabled=0;
#endif
   } else {
      _str backupdir=get_env("VSLICKBACKUP");
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
      ctlok.p_enabled=1;
   } else {
      ctlok.p_enabled=0;
   }
   ctlbackupdir.p_enabled=ctlbackupdirlab.p_enabled=ctlconfigbackupdir.p_value!=0;
}
void ctlok.lbutton_up()
{
   int flags=0;
   if (ctlreadonly.p_value) {
      flags|=1;
   }
   if (ctlnobackup.p_value) {
      flags|=2;
   }
   if (ctlconfigbackupdir.p_value) {
      flags|=4;
      _str new_value=ctlbackupdir.p_text;
      int status=_ConfigEnvVar("VSLICKBACKUP",_encode_vsenvvars(new_value,false));
      if (status) {
         return;
      }
   }
   p_active_form._delete_window(flags);
}
_str _copy_vslick_ini(_str filenopath=_INI_FILE)
{
   _str filename=_ConfigPath():+filenopath;
   _str global_filename=get_env('VSLICKBIN1'):+(filenopath);
   if (global_filename!="" && file_match("-p "maybe_quote_filename(filename),1)=="" &&
       !file_eq(global_filename,filename)) {
      // Make copy of global configuration file.
      copy_file(global_filename,filename);
#if __UNIX__
      _chmod("u+w "maybe_quote_filename(filename));
#else
      _chmod("-R "maybe_quote_filename(filename));
#endif
   }
   return(filename);
}
int _ini_config_value(_str filenopath,_str section, _str name, _str value)
{
   _str filename=_copy_vslick_ini(filenopath);
   int status=_ini_set_value(filename,section,name,value);
   if (status) {
      _message_box(nls("Unable to update file %s.",filename)"  "get_message(status));
      return(status);
   }
   return(0);
}

/**
 * Sets environment variable specified to value specified.  In addition,
 * this environment setting is placed in the users local "vslick.ini" so
 * that the next time the editor is invoked, the environment variable is
 * set to this value.
 *
 * @return  Returns 0 if successful.
 *
 * @categories Miscellaneous_Functions
 *
 */
int _ConfigEnvVar(_str envvar_name, _str new_value)
{
   status := 0;
   // if we are changing the backup directory, then we want to 
   // set the value first, then save the ini file, since the 
   // save operation will be affected by the environment 
   // variable value
   if (envvar_name == 'VSLICKBACKUP') {
      // grab the old value in case we need to restore it
      old_value := get_env(envvar_name);

      // set the new value
      if (new_value._isempty()) {
         set_env(envvar_name);
      } else {
         set_env(envvar_name,new_value);
      }

      // save the value in vslick.ini
      status=_ini_config_value(_INI_FILE,"Environment",envvar_name,new_value);
      if (status) {
         // something went wrong, so restore our old value
         if (old_value._isempty()) {
            set_env(envvar_name);
         } else {
            set_env(envvar_name,old_value);
         }
      }
   } else {
      status=_ini_config_value(_INI_FILE,"Environment",envvar_name,new_value);
      if (status) return(status);
      if (new_value._isempty()) {
         set_env(envvar_name);
      } else {
         set_env(envvar_name,new_value);
      }
   }

   return(status);
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
_command int name(_str newName="",boolean doAbsolute=true) name_info(FILE_ARG','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   _str arg1=prompt(newName,'',p_buf_name);
   int status= name_file(strip(arg1,'B','"'),doAbsolute);
   if (status) return(status);
   p_modify=1;
   p_buf_flags=p_buf_flags|VSBUFFLAG_PROMPT_REPLACE;
   // Force recalculation of adaptive formatting settings.
   p_adaptive_formatting_flags = adaptive_format_get_buffer_flags(p_LangId);
   /*
      Starting with SlickEdit v13, setting the editor language gets
      ignored unless p_LandId=''.
   */
   p_LangId='';
   _SetEditorLanguage();
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
_command int close_buffer(boolean saveBufferPos=true,boolean allowQuitIfHiddenWindowActive=false) name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // IF current buffer has the build window running in it
   if (_process_info('b')) {
      if (_DebugMaybeTerminate()) {
         return(1);
      }
   }
   if (isEclipsePlugin() && p_window_id != VSWID_HIDDEN && !isInternalCallFromEclipse()) {
      return quit(saveBufferPos,allowQuitIfHiddenWindowActive);
   }

   _str old_buffer_name='';
   typeless swold_pos;
   int swold_buf_id=0;
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
_command int quit(boolean saveBufferPos=true,boolean allowQuitIfHiddenWindowActive=false) name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _in_quit=true;

   if (!allowQuitIfHiddenWindowActive && !p_mdi_child) {
      // IF current buffer has the build window running in it
      if (_process_info('b')) {
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
      p_modify = 0;
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
   int status = 0;
   while (args != '') {
      // next file argument
      f := parse_file(args);

      // assume it could be a wildcard and use insert_file_list()
      int list_view_id=0;
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
         status = edit("+b "maybe_quote_filename(f));
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

   int multi=0;
   int activate_mdi=0;
   int do_refresh=0;
   _str cur_dir='';
   int mdi_restore=1;
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
   _str orig_dir='';
   if (cur_dir!='') {
      orig_dir=getcwd();
      cur_dir=strip(cur_dir,'B','"');
      chdir(cur_dir,1);
   }
   //status=0;
   //messageNwait('params='params);
   _str cmd='';
   _str ext='';
   _str qfilename='';
   _str filename='';
   typeless status=0;
   if (!multi) {
      //parse params with cmd qfilename;
      cmd=params;
      qfilename=parse_file(cmd);
      boolean done=false;
      if ((qfilename=='e' || qfilename=='edit')) {
         qfilename=parse_file(cmd);
         if (qfilename=="-#") {
            qfilename=parse_file(cmd);
            if (lowcase(qfilename)=="+fn" || lowcase(qfilename)=="-fn") {
               params="e -# "cmd;
            } else {
               filename=strip(qfilename,'B','"');
               ext=_get_extension(filename,1);
               if (file_eq(ext,PRJ_FILE_EXT) ||
                   file_eq(ext,WORKSPACE_FILE_EXT) ||
                   file_eq(ext,VISUAL_STUDIO_SOLUTION_EXT) ||
                   file_eq(ext,VCPP_PROJECT_WORKSPACE_EXT) ||
                   file_eq(ext,TORNADO_WORKSPACE_EXT)
                  ) {
                  status=workspace_open(qfilename);
                  if (cmd=="") {
                     done=true;
                  } else {
                     params="edit -# "cmd;
                  }
               }
            }
         }
      }
      if (!done) {
         EditFlags old_def_edit_flags=def_edit_flags;
         def_edit_flags&=~(EDITFLAG_WORKSPACEFILES|EDITFLAG_BUFFERS);
         status=execute(params,"");
         def_edit_flags=old_def_edit_flags;
      }
   } else {
      status=0;
      for (;;) {
         _str command='';
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
      _mdi._set_foreground_window();
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
static boolean in_actapp_files=false;
definit()
{
   _filepos_view_id=0;
   in_actapp_files=false;
   gbatch_call_list_timer = -1;
   gbatch_call_list_count = null;
   gbatch_call_list_arg = null;
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
   int orig_view_id=0;
   get_window_id(orig_view_id);
   _str idx_list='';
   typeless index=name_match(prefix_name,1,PROC_TYPE);
   for (;;) {
      if ( ! index ) { break; }
      if ( index_callable(index) ) {
         if ( (length(idx_list)+length(index))>MAX_LINE ) {
            break;
         }
         idx_list=idx_list:+' ':+index;
         //call_index(arg(2),arg(3),arg(4),arg(5),index)
      }
      index=name_match(prefix_name,0,PROC_TYPE);
   }
   while ( idx_list!='' ) {
      parse idx_list with index idx_list;
      switch (arg()) {
      case 1:
         call_index(index);
         break;
      case 2:
         call_index(arg(2),index);
         break;
      case 3:
         call_index(arg(2),arg(3),index);
         break;
      case 4:
         call_index(arg(2),arg(3),arg(4),index);
         break;
      case 5:
         call_index(arg(2),arg(3),arg(4),arg(5),index);
         break;
      case 6:
         call_index(arg(2),arg(3),arg(4),arg(5),arg(6),index);
         break;
      case 7:
         call_index(arg(2),arg(3),arg(4),arg(5),arg(6),arg(7),index);
         break;
      case 8:
         call_index(arg(2),arg(3),arg(4),arg(5),arg(6),arg(7),arg(8),index);
         break;
      }
   }
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
      if (_iswindow_valid(i) && i.p_HasBuffer) {
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

/** 
 * Remove the name of the file being closed from the 
 * gWarnedSlowFiles table.  This is so they will be warned again 
 * if they reopen the file
 */
void _cbquit_auto_reload (int bufID, _str filename, _str docname= '', int flags = 0)
{
   casedFilename := _file_case(filename);
   // If we close a file in the slow file list, take it out
   if ( gWarnedSlowFiles._indexin(casedFilename) ) {
      gWarnedSlowFiles._deleteel(casedFilename);
   }
}

#if __MACOSX__
/**
 * Exported from the macutils library. Used to notify external 
 * editors that SlickEdit is done editing a file, for ODB Editor 
 * suite implementation. 
 */
void macFileQuit(_str filePath);

int _cbquit2_mac(int buf_id,_str buf_name,_str document_name,int buf_flags)
{
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
static boolean useWholeFileCompare()
{
   return (def_autoreload_compare_contents &&
           p_file_size<=def_autoreload_compare_contents_max_size);
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
boolean _ReloadCurFile(int actapp_view_id, _str bfiledate,
                       boolean allowPrompting=true,
                       boolean allowEditFromJGUI=true, _str SrcFilename=null,
                       boolean forcePromptingIfModified=true)
{
   int orig_view_id=_mdi;
   _str options='';
   if (p_buf_width==1) {
      options='+LW';
   } else if (p_buf_width) {
      options='+'p_buf_width;
   }
   int encoding_set_by_user=-1;
   _str encoding_str=_load_option_encoding(p_buf_name);
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
      } else if (last_char(_EncodingToOption(p_encoding))=='s') {
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
      encoding_str=_EncodingToOption(encoding);
   }
   //say('ar: e_set_by_user='encoding_set_by_user);
   //say('ar: encoding_str='encoding_str);
   options=options' 'encoding_str;
   _str doc_name=p_DocumentName;
   if (doc_name=="") {
      doc_name=p_buf_name;
   }
   if (SrcFilename==null) {
      SrcFilename=p_buf_name;
   }
   _str orig_buf_name=p_buf_name;
   _str buf_name=p_buf_name;
   int buf_id=p_buf_id;
   boolean modify=p_modify;
   typeless p;
   save_pos(p,'L');
   int oldp_line_numbers_len=p_line_numbers_len;

   // 6/1/2006 - RB
   // Auto reload should restore autocaps settings.
   // If p_caps=2 (AutoCaps) was set in extension setup, then it could be
   // argued that we should figure out the caps setting by calling _GetCaps
   // all over again. Not sure, so will just restore it as-is for now.
   boolean caps = p_caps;

   // 6/13/2007 - DB
   // Auto reload should restore hex mode
   hexmode := p_hex_mode;

   activate_window(orig_view_id);_set_focus();

   //disabled_wid_list=_enable_non_modal_forms(0,_mdi);
   int result=IDYES;
   boolean reset_modified = false;
   // IF no reload prompt
   if ((def_actapp&ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED) || !allowPrompting) {
      if (modify && forcePromptingIfModified) {
         result = show('-modal _auto_file_reload_form', doc_name);
      }
   } else {
#if !__UNIX__
      if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
         if (_mdi.p_window_state=='I') {
            _mdi.p_window_state='R';
         }
      }
#endif
      // IF user only wants to be warned if buffer is modified
      if (( def_actapp & ACTAPP_WARNONLYIFBUFFERMODIFIED)) {
         if (modify) {
            //result=_message_box(nls("Another application has modified the file\n\n '%s'\n\nwhich you have modified.  Do you want to reload it?\n\nThe command \"set-var def_sbwarn_reload_modify 0\" will avoid this message box.",doc_name),'',MB_YESNOCANCEL|MB_ICONQUESTION);
            result = show ('-modal _auto_file_reload_form', doc_name);
         }
      } else {
         boolean ignoreTouchedFile = false;
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
   int temp_view_id=0;
   activate_window(orig_view_id);

   if (result==IDYES || result==IDYESTOALL) {
      /* Make a view&buffer windows list which contains window and position info. */
      /* for all windows. */
      temp_view_id=_list_bwindow_pos(buf_id);
      activate_window(actapp_view_id);
      // Use def_load_options for network,spill, and undo options. */
      _str ExtraOption='';
      if (!allowEditFromJGUI) {
         ExtraOption='-bg';
      }

      // save bookmark, breakpoint, and annotation information
      _SaveBookmarksInFile(auto bmSaves);
      _SaveBreakpointsInFile(auto bpSaves);
      _SaveAnnotationsInFile(auto annoSaves);

      status=load_files(build_load_options(buf_name):+' +q +d 'ExtraOption' +r +l ':+options' ':+maybe_quote_filename(SrcFilename));
      if (status) {
         if (status==NEW_FILE_RC) {
            status=FILE_NOT_FOUND_RC;
            _delete_buffer();
         }
         activate_window(orig_view_id);_set_focus();
         _message_box(nls("Unable to reload %s",doc_name)"\n\n"get_message(status));
         if (status!=ACCESS_DENIED_RC) {
            if (bfiledate=='' || bfiledate==0) {
               bfiledate=_file_date(buf_name,'B');
            }
            if (bfiledate!='' && bfiledate!=0) {
               p_file_date=(long)bfiledate;
            }
         }
      } else {
         p_buf_name=orig_buf_name;
         p_line_numbers_len=oldp_line_numbers_len;
         p_encoding_set_by_user=encoding_set_by_user;
         p_caps=caps;
         p_hex_mode=hexmode;
         restore_pos(p);
         // Need to do an add buffer here so the debugging
         // information is updated.
         // load_files with +r options calls the delete buffer
         // callback.  Here we readd this buffer.
         call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
         call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);

         // restore bookmarks, breakpoints, and annotation locations
         _RestoreBookmarksInFile(bmSaves);
         _RestoreBreakpointsInFile(bpSaves);
         _RestoreAnnotationsInFile(annoSaves);

         // clear highlights
         clear_highlights();

         _set_bwindow_pos(temp_view_id);

         // reset adaptive formatting
         adaptive_format_reset_buffers();
      }
      if (temp_view_id) {
         _delete_temp_view(temp_view_id);
      }

   } else {
      activate_window(actapp_view_id);
      p_file_date=(long)bfiledate;
      if (result == IDDIFFFILE) {
         _DiffModal('-r2 -b1 -d2 'maybe_quote_filename(doc_name)' 'maybe_quote_filename(doc_name));
      }
      activate_window(actapp_view_id);
      if (reset_modified) {
         p_modify = modify;
      } else {
         p_modify=1;
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
void _ReloadFiles(boolean allowPrompting=true, int (*bufIdList)[]=null,
                  AUTORELOAD_FILE_INFO (*pFastReloadTable):[]=null,
                  int reloadThreshold=def_autoreload_timeout_threshold)
{
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
   boolean reloadSelectArray[];
   _str delBufNames[];
   int delBitmaps[];
   boolean delSelectArray[];

   for (i = 0; i < bufferIDs._length(); ++i) {
      if (modFileNames._indexin(i)) { // Modified on disk
         j = reloadBufIDs._length();
         reloadBufIDs[j] = bufferIDs[i];
         reloadBufNames[j] = modFileNames:[i];
         if (modBufNames._indexin(modFileNames:[i])) { // ... and in buffer.
            reloadBitmaps[j] = _pic_file_buf_mod;
            reloadSelectArray[j] = false;
         } else {
            reloadBitmaps[j] = _pic_file_mod2;
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
               SL_SELECTCLINE |
               SL_DESELECTALL |
               SL_COLWIDTH |
               SL_INVERT |
               SL_SELECTALL |
               SL_MUSTEXIST;
   if (reloadBufNames._length() > 0) {
#if !__UNIX__
      if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
         if (_mdi.p_window_state=='I') {
            _mdi.p_window_state='R';
         }
      }
#endif
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
                                      null, reloadSelectArray, reload_modified_cb,
                                      '', "Reload Modified Files", flags, 'File',
                                      TREE_BUTTON_PUSHBUTTON|\
                                      TREE_BUTTON_SORT_FILENAME,
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
            bfiledate = _file_date(reloadBufNames[i], 'B');
            temp_wid = 0;
            orig_wid = 0;
            status = _open_temp_view('', temp_wid, orig_wid, "+bi "(int)reloadBufIDs[i]);
            if (status == 0) {
               if (pos(' 'reloadBufIDs[i]' ', reloadResult)) { // User chose to reload this one
                  _ReloadCurFile(temp_wid, bfiledate, false, true, null, false);
                  if ( temp_wid.useWholeFileCompare() && DSBackupVersionExists(reloadBufNames[i]) ) {
                     status = temp_wid.DS_CreateDelta(reloadBufNames[i]);
                     DSSetVersionComment(reloadBufNames[i], -1, "Created by Auto Reload.");
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
#if !__UNIX__
      if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
         if (_mdi.p_window_state=='I') {
            _mdi.p_window_state='R';
         }
      }
#endif
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
         saveFile = maybe_quote_filename(saveFile);
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
void _OldReloadFiles(boolean allowPrompting=true, int (*bufIdList)[]=null)
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
   int orig_autoreload = def_actapp & ACTAPP_AUTORELOADON;
   def_actapp &= ~ACTAPP_AUTORELOADON;

   int temp_wid, orig_wid;
   _open_temp_view("",temp_wid,orig_wid,"+bi "RETRIEVE_BUF_ID);
   int bufIds[] = null;
   if( bufIdList ) {
      bufIds= *bufIdList;
   } else {
      int first_buf_id = p_buf_id;
      for( ;; ) {
         _str noption = 'N';
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
   int len=closeFileList._length();
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
   def_actapp |= orig_autoreload;
}

#define TESTING_RELOAD_CHANGES 0
#define TIMING_AUTO_RELOAD     0
#define TIMING_ACTAPP          0

void _actapp_files(_str gettingFocus="")
{
#if TIMING_AUTO_RELOAD || TIMING_ACTAPP
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

   in_actapp_files=true;
   _str VCPPSaveFilesArg='N';
   _str Hunt='';
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
         _mdi.p_child.save_all(SV_POSTMSGBOX);
      }
      if (def_hidetoolbars) {
         _tbVisible(0);
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
   if (def_hidetoolbars) {
      _tbVisible(1);
   }
   if (!(def_actapp&ACTAPP_AUTORELOADON)) {
      in_actapp_files=false;
      return;
   }

   // Check now to see if any files will time out. We check here because we will
   // want to avoid both _ReloadFiles and maybe_set_readonly
   currentFileOnly := (def_actapp & ACTAPP_CURRENT_FILE_ONLY) != 0;

#if TIMING_AUTO_RELOAD
   t1 := _time('b');
#endif

   // Get this information here because we will pass it to both 
   // setBufferReadonlyStatuses and _ReloadFiles
   AUTORELOAD_FILE_INFO fastReloadInfoTable:[];
   getFastReloadInfoTable(fastReloadInfoTable,def_actapp&ACTAPP_AUTOREADONLY,def_fast_auto_readonly,def_autoreload_timeout_threshold);

#if TIMING_AUTO_RELOAD
   t10 := _time('b');
   say('_actapp_files getFastReloadInfoTable time='(int)t10-(int)t1);
#endif

   if ( def_actapp&ACTAPP_AUTOREADONLY ) {
      doAutoReadOnly(fastReloadInfoTable);
   }
   int ori_def_actapp;
   ori_def_actapp = def_actapp;
   if ( dpRunning ) def_actapp = def_actapp | ACTAPP_WARNONLYIFBUFFERMODIFIED;

#if TIMING_AUTO_RELOAD
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

#if TIMING_AUTO_RELOAD
   t100 := _time('b');
   say('_actapp_files _ReloadFiles time='(int)t100-(int)t50);
#endif

   if ( def_autoreload_timeout_notifications ) {
      showSlowFileNotification();
   }

#if TIMING_AUTO_RELOAD
   t110 := _time('b');
   say('_actapp_files showSlowFileNotification time='(int)t110-(int)t100);
#endif

   if ( dpRunning ) def_actapp = ori_def_actapp;
   int orig_wid;
   get_window_id(orig_wid);
   in_actapp_files=false;
   if (machine()=='WINDOWS') {
      //This calls the code to force VC++ to save the files
      if (VCPPSaveFilesArg!='N') {
         if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_VCPP_SETUP)) {
            int callable=index_callable(find_index('VCPPIsUp',PROC_TYPE));
            int isup=0;
            if (!InRecursion && callable && !DllIsMissing('vchack.dll') ) {
               isup=VCPPIsUp(def_vcpp_version);
            }
            if (isup) {
               InRecursion=1;
               int index=find_index('VCPPSaveFiles',PROC_TYPE);
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

#if TIMING_AUTO_RELOAD || TIMING_ACTAPP
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
      _mdi.p_child.for_each_buffer("maybe_set_readonly",false,&fastReloadInfoTable);
   }else{
      // We already have the information we need in fastReloadInfoTable
      // Loop through the buffers and set read only mode appropriately
      int temp_view_id=0;
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
                       _set_read_only(!p_readonly_mode,false);
                       //should reload here
                    }
                 }
                 p_readonly_set_by_user=0;
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
// WARNING: _switchbuf_files is called from _on_document_tab_left_click with
// null for old_buffer_name. It similates the old file tabs tool window
// auto-reload which occurs because the edit command is called.
void _switchbuf_files(_str old_buffer_name, _str option='')
{
   if ( in_actapp_files ||
        !(def_actapp & ACTAPP_AUTORELOADON) ||
        (def_actapp & ACTAPP_DONT_RELOAD_ON_SWITCHBUF) ||
         option == 'W') {
      return;
   }
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
void _ReloadFileList(_str (&fileList)[], boolean allowPrompting=true)
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
   int view_id=0;
   get_window_id(view_id);
   activate_window(temp_view_id);
   top();up();
   for (;;) {
      down();
      if (rc) return;
      _str line='';
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
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if (orig_view_id=='') return(0);
   int i,last=_last_window_id();
   for (i=1;i<=last;++i) {
      if (_iswindow_valid(i) && i.p_mdi_child && i.p_HasBuffer  &&
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
   boolean RestoreSelDisp    = (def_restore_flags & RF_NOSELDISP ) == 0;
   boolean RestoreLineModify = (def_restore_flags & RF_LINEMODIFY) != 0;
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
   ctlfilename.p_caption=maybe_quote_filename(filename);
   int max=0;
   int width=ctlanotherlab._text_width(ctlanotherlab.p_caption);
   if (width>max) max=width;
   width=ctlfilename._text_width(ctlfilename.p_caption);
   if (width>max) max=width;
   width=ctlyesnolab._text_width(ctlyesnolab.p_caption);
   if (width>max) max=width;

   width=ctldiff.p_x+ctldiff.p_width-ctlanotherlab.p_x;
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
   int status = 0;
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
   int temp_view_id=0;
   int orig_view_id=0;
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
   int status=get(maybe_quote_filename(filename),'','A');
   if (!status) {
      status=search('%\c','@');
      if (!status) {
         _str line='';
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
   _str langId = p_LangId;
   if (langId=='') return;
   boolean modify=p_modify;
   // This code is hardwired for now.  This will be configurable later.
   if (file_eq(langId,'xsl')) {
      _delete_line();
      insert_line('<?xml version="1.0"?>');
      insert_line('<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">');
      insert_line(indent_string(p_SyntaxIndent));
      insert_line('</xsl:stylesheet>');
      up();_end_line();
   } else if (file_eq(langId,'xsd')) {
      _delete_line();
      insert_line('<?xml version="1.0"?>');
      insert_line('<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">');
      insert_line(indent_string(p_SyntaxIndent));
      insert_line('</xsd:schema>');
      up();_end_line();
   } else if (file_eq(langId,'xmldoc')) {
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
   status=get(maybe_quote_filename(filename),'','A');
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
   ctldeletedfilename.p_caption = maybe_quote_filename(filename);
   int max = 0;
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
      _str file_list = '*.htm;*.html';
      _str format_list = 'HTML Files(*.htm;*.html), All Files('ALLFILES_RE')';
      _str initial_filename = maybe_quote_filename(_strip_filename(bufname,'P')) :+ '.html';
      typeless result=_OpenDialog('-new -modal',
                       'Export to HTML',
                       file_list,               // Initial wildcards
                       format_list,
                       OFN_SAVEAS,
                       file_list,               // Default extensions
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

   mou_hour_glass(1);

   int status;
   int orig_view_id = p_window_id;
   int temp_view_id;
   _open_temp_view('', temp_view_id, orig_view_id,'+bi ':+buffer_id);
   status = _ExportColorCodingToHTML(strip(filename, 'B', '"'));
   p_window_id = orig_view_id;
   _delete_temp_view(temp_view_id, false);

   mou_hour_glass(0);
   if (status != 0) {
      message("Error occured exporting: "filename);
   }
   return (0);
}

static void GetFilePositionFromWindow()
{
   int buf_id=p_buf_id;
   int wid=window_match(p_buf_name,1,'x');
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
   if (find_index('def-language-'langId, MISC_TYPE) <= 0) langId = FUNDAMENTAL_LANG_ID;
   if (langId != p_LangId) {
      info.m_langId = p_LangId;
   } else {
      info.m_langId = '';
   }

   typeless SoftWrap=p_SoftWrap;
   boolean lang_SoftWrap, lang_SoftWrapOnWord;
   _SoftWrapGetSettings(p_LangId, lang_SoftWrap, lang_SoftWrapOnWord);
   if (SoftWrap==lang_SoftWrap) {
      SoftWrap=2;
   }
   info.m_softWrap = SoftWrap;

   info.m_xmlWrapScheme = XW_getCurrentScheme(filename);
   if (info.m_xmlWrapScheme == null || info.m_xmlWrapScheme == '') {
      info.m_xmlWrapScheme = XW_NODEFAULTSCHEME;
   }

   info.m_xmlWrapOptions = XW_getCurrentOptions(filename);
   if (info.m_xmlWrapOptions == null || info.m_xmlWrapOptions == '') {
      info.m_xmlWrapOptions = '0';
   }

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
      boolean RestoreSelDisp=!(def_restore_flags &RF_NOSELDISP);
      boolean RestoreLineModify=((def_restore_flags &RF_LINEMODIFY) != 0);
      boolean RestoreLineflags=RestoreSelDisp ||RestoreLineModify;
      if (RestoreLineflags) {
         _str path=_ConfigPath():+"SelDisp":+FILESEP;
         status=_RestoreSelDisp(path:+info.m_selDisp,p_file_date,RestoreSelDisp,RestoreLineModify);
      }
   }
   _str scroll_style=_scroll_style();
   _scroll_style('C 0');
   _GoToROffset(info.m_seekPos);
   _scroll_style(scroll_style);

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
      bottom();

      // add the beginning comment
      if (beginComment != '') {
         insert_line(beginComment);
         bottom();
      }

      // then do a get.  or a fetch.  or a grab.  whatever.
      status = get(sourceFile, 'B');
      if (status) break;
   
      // add the ending comment
      if (endComment != '') {
         bottom();
         insert_line(endComment);
      }

      // now close her up
      status = save();

   } while (false);

   p_window_id = origWid;
   return status;
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
      if ( !(p_buf_flags&HIDE_BUFFER) && isReloadableFile(p_buf_name) ) {
         bufNames[bufNames._length()] = p_buf_name;
      }
   }

   load_files('+bi 'origBufID);

   _delete_temp_view(temp_wid);

   p_window_id = orig_wid;
}


static boolean isReloadableFile(_str filename)
{
   return filename!="" && filename!=".process" && filename!=".command";
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

      #define MAX_REPORTED_FILES 5
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
            slowFileString = slowFileString"\n"curFilename;
            ++numFilesInString;
         }
      }

      if ( slowFileString!="" ) {
         if ( len>MAX_REPORTED_FILES ) {
            slowFileString = slowFileString:+nls("\nand %s others",len-numFilesInString);
            // Put the "others" into the files we warned about, or this will 
            // keep happening.
         }
         toastMessageText := nls("The following file%s will always be skipped by auto reload and auto readonly:\n%s",numFilesInString==1?"":'s',slowFileString);
         _ActivateAlert(ALERT_GRP_WARNING_ALERTS,0,toastMessageText);
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
   int temp_wid = 0;
   int orig_wid = _create_temp_view(temp_wid);
   int orig_def_buflist = def_buflist;
   if (def_buflist & SEPARATE_PATH_FLAG) {
      def_buflist = def_buflist - SEPARATE_PATH_FLAG;
   }
   _build_buf_list(0, p_buf_id, 1, p_buf_id, false, bufIdList);
   def_buflist = orig_def_buflist;
   top();
   up();
   _str line = '';
   while (!down()) {
      get_line(line);
      line = strip(stranslate(line, '', '*'));
      modBufNames:[line] = line;
   }
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);

   // Get the names of the modified and deleted files.
   int orig_autoreload = def_actapp & ACTAPP_AUTORELOADON;
   def_actapp &= ~ACTAPP_AUTORELOADON;

   temp_wid = 0;
   orig_wid = 0;
   _open_temp_view("",temp_wid,orig_wid,"+bi "RETRIEVE_BUF_ID);
   int bufIds[] = null;
   if( bufIdList ) {
      bufIds= *bufIdList;
   } else {
      int first_buf_id = p_buf_id;
      for( ;; ) {
         _str noption = 'N';
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
      
      _str bfiledate = "";
      casedFilename := _file_case(p_buf_name);
      if ( fastReloadInfoTable._indexin(casedFilename) ) {
         bfiledate = fastReloadInfoTable:[casedFilename].bfileDate;
      }
#endif
#if TESTING_RELOAD_CHANGES
      if ( fastReloadInfoTable._indexin(_file_case(p_buf_name)) ) {
         if ( fastReloadInfoTable:[_file_case(p_buf_name)]!=bfiledate ) {
            say('findModifiedAndDeleted PROBLEM p_buf_name='p_buf_name);
            say('                       bfiledate=<'bfiledate'>');
            say('                       hashtbval=<'fastReloadInfoTable:[_file_case(p_buf_name)]'>');
         }
      }
#endif
      bufferNumber = bufferIDs._length();
      if (bfiledate == "") { //If there is no file on disk ...
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
         boolean ignoreTouchedFile = false;
         // first, determine if the user is checking for 'touched' files where the date is updated
         // but the content is not.

         if ( useWholeFileCompare() && (((int)_time('b')-(int)origTime)<def_autoreload_timeout_threshold) ) {
            wholeFileCompare(ignoreTouchedFile);
         }
         // if this file is not being ignored because it was touched, then handle it
         if (ignoreTouchedFile == false) {
            boolean fileReloadedSilently = false;
            // check to see if the buffer should be automatically reloaded (if the user wants 
            // to suppress the prompt if modified)
            if (def_actapp&ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED) {
               if (!modBufNames._indexin(p_buf_name)) {
                  // Buffer is not modified, but file is. Reload it silently.
                  // Also, save and restore the current window ID, _ReloadCurFile changes it.
                  wid:= p_window_id;
                  _ReloadCurFile(p_window_id, bfiledate, false, true, null, false);
                  p_window_id= wid;
                  fileReloadedSilently = true;
                  //create a backup history entry for the reload
                  if ( useWholeFileCompare() && DSBackupVersionExists(p_buf_name) ) {
                     DS_CreateDelta(p_buf_name);
                     DSSetVersionComment(p_buf_name, -1, "Created by Auto Reload.");
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
   _delete_temp_view(temp_wid);
   if (_iswindow_valid(orig_wid)) {
      activate_window(orig_wid);
   }

   def_actapp |= orig_autoreload;
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
 * @return boolean true if the file should
 */
static void wholeFileCompare(boolean &ignoreTouchedFile)
{
   ignoreTouchedFile = false;
   int orig_pBufId = p_buf_id;
   int fileWID = 0;
   int backupWID = 0;
   int origWID = p_window_id;
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

   if ( p_modify && DSBackupVersionExists(p_buf_name) ) {
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
      int different = FastCompare(fileWID, 0, backupWID, 0);
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
boolean checkIfFileIsModified (_str bufName)
{
   _str buf_id = '';
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
   int select_tree_wid = _find_control('ctl_tree');
   if (select_tree_wid) {
      //Find the selected buffers.
      _str selBufs:[];
      selBufs._makeempty();
      int flags=0;
      int showChildren;
      typeless bm1, bm2;
      int index = select_tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         if ( select_tree_wid._TreeGetCheckState(index) ) {
            selBufs:[index] =
               maybe_quote_filename(select_tree_wid._TreeGetCaption(index));
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
      int index = select_tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         if ( select_tree_wid._TreeGetCheckState(index) ) {
            bufferName =
               maybe_quote_filename(select_tree_wid._TreeGetCaption(index));
            rawBufferName = strip(bufferName, 'B', '"');

            buf_info = buf_match(rawBufferName, 1, 'vx');
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
         index = select_tree_wid._TreeGetNextIndex(index);
      }

      p_active_form._delete_window();

      int tmpwid = p_window_id;
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
        lineEndingStyles[2]= "Unix/Mac OS X (LF)";
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
    _macro('R',1);
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

        typeless chosenEncoding=show('_sellist_form -xy -new -mdi -modal',
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

        if (chosenEncoding != '') {
            // Find the match in the encoding table and format it
            // as arguments appropriate for the edit command
            _str editCommandParams = '';
            int i;
            for (i = 1; i < openEncodingTab._length(); ++i) {
                if (openEncodingTab[i].text == chosenEncoding) {
                    if (openEncodingTab[i].option) {
                        editCommandParams = strip(openEncodingTab[i].option);
                    } else if (openEncodingTab[i].codePage >= 0) {
                        editCommandParams = '+fcp'openEncodingTab[i].codePage;
                    }
                    break;
                }
            }

            // Combine current file buffer name with encoding option and line ending option
            editCommandParams :+= _rwe_chosen_le;
            editCommandParams :+= ' ';
            editCommandParams :+= maybe_quote_filename(p_buf_name);;
            execute('quit');
            edit(editCommandParams);
        }
    }
}

int _OnUpdate_reload_with_encoding(CMDUI &cmdui,int target_wid,_str command)
{
    if(target_wid && target_wid._isEditorCtl()) {
        if(target_wid.p_buf_name && file_exists(target_wid.p_buf_name)) {
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
boolean batch_call_list(_str callback_name, typeless batch_arg=null, 
                        boolean forceCallbackOnTimer=false)
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

