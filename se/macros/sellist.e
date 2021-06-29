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
#include "eclipse.sh"
#include "slick.sh"
#import "backtag.e"
#import "compile.e"
#import "diff.e"
#import "eclipse.e"
#import "fileman.e"
#import "files.e"
#import "forall.e"
#import "frmopen.e"
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "menu.e"
#import "moveedge.e"
#import "recmacro.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbcmds.e"
#import "tbfilelist.e"
#import "util.e"
#import "window.e"
#import "wkspace.e"
#import "se/ui/mainwindow.e"
#endregion

   _control _sellist;

static const BUFFER_COL= 5;

enum_flags {
   BUFLIST_FLAG_SORT=0x1,
   BUFLIST_FLAG_SEPARATE_PATH=0x2,
   BUFLIST_FLAG_SHOW_SYSTEM_BUFFERS=0x4,
   BUFLIST_FLAG_SELECT_ACTIVE=0x8,
   BUFLIST_FLAG_FORCE_OLD_BUFLIST=0x10,
};

static _str lb_nls_chars;
static int gstart_buf_id;

int def_buflist=BUFLIST_FLAG_SORT+BUFLIST_FLAG_SEPARATE_PATH;
bool def_isearch_buflist=true;


_control btnsave_selected;   // Save Selected button
_control btndiff_selected;   // Diff Selected button
static _str _list_modified_ft(int reason,var result,_str key)
{
   line := "";
   doc_name := "";

   // Initialize or change selected
   if (reason==SL_ONINIT || reason==SL_ONSELECT) {
      int save_selected_wid=btnsave_selected;
      int diff_selected_wid=0;
      if ( _haveDiff() ) diff_selected_wid = btndiff_selected;
      if (_sellist.p_Nofselected > 0) {
         if (!save_selected_wid.p_enabled) {
             save_selected_wid.p_enabled = true;
         }
         if (_sellist.p_Nofselected==1 && !_sellist._lbfind_selected(true)) {
            _sellist. get_line(line);
            if (diff_selected_wid!=0) diff_selected_wid.p_enabled = file_exists(_buflist_name(line));

            doc_name=_buflist_name(line);
            // IF editor does not have this buffer (this could be a gui builder buffer)
            if (diff_selected_wid!=0 && buf_match(doc_name,1,'hx')=='') {
               diff_selected_wid.p_enabled=false;
            }
         } else {
            diff_selected_wid.p_enabled = false;
         }
      } else {
         save_selected_wid.p_enabled=false;
         if (diff_selected_wid!=0) diff_selected_wid.p_enabled=false;
      }
      return('');
   }
   if (reason==SL_ONDEFAULT) {  // Enter callback?
      /* Save all files. */
      result=1;
      return(1);
   }
   if (reason!=SL_ONUSERBUTTON && reason!=SL_ONLISTKEY){
      return('');
   }
   typeless status=0;
   name := "";
   temp_name := "";
   done := false;
   orig_wid := p_window_id;
   buf_id := 0;
   p_window_id=_sellist;
   if ( key==4) {  /* Save Selected */
      if (!btnsave_selected.p_enabled) {
         return('');
      }

      _param1._makeempty();
      top();up();
      while(!down()) {
         get_line(line);
         if (_lbisline_selected()) {
            get_line(line);
            _param1[_param1._length()]=_buflist_name(line);
         }
      }
      result='@';
      p_window_id=orig_wid;
      return(1);
   }
   if ( key==5) {  /* Diff Selected */
      if (!btndiff_selected.p_enabled || _lbfind_selected(true)!=0) {
         return('');
      }
      get_line(line);
      doc_name=_buflist_name(line);
      if (!file_exists(doc_name)) {
         return('');
      }
      orig_wid=p_window_id;
      result=_DiffModal('-r2 -b1 -d2 '_maybe_quote_filename(doc_name)' '_maybe_quote_filename(doc_name));
      p_window_id=orig_wid;
      return('');
   }
   if ( key==6) { /* Invert. */
      _lbinvert();
      typeless junk=0;
      _list_modified_ft(SL_ONSELECT,junk,'');
      p_window_id=orig_wid;
      return('');
   }
   if ( key==7) { /* Save None. */
      result=6;
      p_window_id=orig_wid;
      return(1);
   }
   return('');
}
static _str _list_buffers_callback(int reason, _str& result, _str key)
{
   line := "";
   name := "";
   bufname := "";
   typeless status = 0;

   if( reason == SL_ONDEFAULT ) {
      // Enter key
      _sellist.get_line(line);
      name = _buflist_name(line);
      result = name;
      return 1;
   } else if( reason == SL_ONINIT ) {
      if( def_buflist & BUFLIST_FLAG_SELECT_ACTIVE ) {
         bufname = _mdi.p_child.p_buf_name;
         _sellist._lbdeselect_line();
         if( def_buflist & BUFLIST_FLAG_SEPARATE_PATH ) {
            line = field(_strip_filename(bufname,'P'),13)'<'_strip_filename(bufname,'N')'>';
            _sellist.top();
            status = _sellist.search('^(\>|)[ \t]*(\*|)[ \t]*'_escape_re_chars(line),'er');
         } else {
            _sellist.top();
            _sellist._lbsearch(bufname);
         }
         _sellist._lbselect_line();
      }
      return "";
   }
   user_button := ( reason == SL_ONUSERBUTTON );
   if( reason != SL_ONLISTKEY && !user_button ) {
      return "";
   }
   orig_wid := p_window_id;
   p_window_id = _sellist;
   _str buffer_list = ( lowcase(p_active_form.p_caption) == "select a buffer" );
   if( buffer_list ) {
      if( !user_button && isalpha(key) ) {
         if( upcase(key) == 'Q' ) {
            key = 5;
         } else {
            i := pos(key,lb_nls_chars,1,'i');
            if( i != 0 ) {
               key = i + 2;
            }
         }
      }
      if( key == 6) {
         // Toggle order
         _lbclear();
         if ( def_buflist & BUFLIST_FLAG_SORT ) {
            def_buflist = def_buflist & ~BUFLIST_FLAG_SORT;
         } else {
            def_buflist = def_buflist | BUFLIST_FLAG_SORT;
         }
         _config_modify_flags(CFGMODIFY_DEFVAR);
         //_build_buf_list(width,p_buf_id,false,gstart_buf_id);
         width := 0;
         _build_buf_list(width,p_buf_id,false,_mdi.p_child.p_buf_id);
         if( def_buflist & BUFLIST_FLAG_SELECT_ACTIVE ) {
            bufname = _mdi.p_child.p_buf_name;
            _lbdeselect_line();
            if( def_buflist & BUFLIST_FLAG_SEPARATE_PATH ) {
               line = field(_strip_filename(bufname,'P'),13)'<'_strip_filename(bufname,'N')'>';
               top();
               status = search('^(\>|)[ \t]*(\*|)[ \t]*'_escape_re_chars(line),'er');
            } else {
               top();
               _lbsearch(bufname);
            }
            _lbselect_line();
         } else {
            top();
            p_modify = false;
            _lbselect_line();
         }
         p_window_id = orig_wid;
         return "";
      } else if( key == 4 ) {
         // Save
         get_line(line);
         name = _buflist_name(line);
         if( substr(name,1,1) == '.' ) {
            _message_box(nls("Can't save buffer starting with '.'"));
            p_window_id = orig_wid;_set_focus();
            return "";
         }
         if ( index_callable(find_index("delphiIsRunning",PROC_TYPE)) ) {

            if ( delphiIsRunning() && delphiIsBufInDelphi(name) ) {
               //sticky_message( "delphi file="p_buf_name );
               delphiSaveBuffer(name);
               return "";
            }
         }
         status = _save_non_active(name);
         if( status ) {
            p_window_id = orig_wid;
            return "";
         }
         //get_line line
         indicators := stranslate(substr('',1,BUFFER_COL-1),'','*');
         replace_line(indicators:+_build_buflist_name(name));
         _lbselect_line();
         p_modify = false;
         p_window_id = orig_wid;
         return "";
      } else if( key == 5 ) {
         // Close
         get_line(line);
         name = _buflist_name(line);
         if( substr(name,1,1) == '.' ) {
            p_window_id = orig_wid;
            _set_focus();
            _message_box(nls("Can't close buffer starting with '.'"));
            return "";
         }
         if( index_callable(find_index("delphiIsRunning",PROC_TYPE)) ) {
            if( delphiIsRunning() && delphiIsBufInDelphi(name) ) {
               //messageNwait( "closing file="name );
               delphiCloseBuffer(name);
               return "";
            }
         }
         status = _save_non_active(name,true);
         if( status ) {
            p_window_id = orig_wid;
            return "";
         }
         _delete_line();
         if( !_on_line0() ) {
            _lbselect_line();
         }
         // If the list is the last buffer?
#if 0 //12:03pm 7/30/2012
         say('::_list_buffers_callback p_name='p_name);
         if( last_buffer() ) {
            result = "";
            p_window_id = orig_wid;
            return 1;
         }
#endif
         p_window_id = orig_wid;
         return "";
      }
   } else {
      // Should be Link to window form
      if( key == 5 ) {
         // Start Process
         typeless old_one_file = def_one_file;
         def_one_file = '';
         old_process_tab_output := def_process_tab_output;
         def_process_tab_output = false;
         p_window_id=_mdi.p_child;
         result=start_process(true);
         if( result == PROCESS_ALREADY_RUNNING_RC ||
            ( result == 0 && buf_match(".process",1,'hx') != "" ) ) {

            int was_recording = _macro('m');
            _macro('m',_macro('s'));
            _macro_append("old_one_file = def_one_file;");
            _macro_append("def_one_file = '';");
            _macro_append("old_process_tab_output = def_process_tab_output;");
            _macro_append("def_process_tab_output = false;");
            _macro_call("start_process");
            _macro_append("def_one_file = old_one_file;");
            _macro_append("def_process_tab_output = old_process_tab_output;");
            _macro('m',was_recording);
            result = _chr(0);
            def_one_file = old_one_file;
            def_process_tab_output = old_process_tab_output;
            p_window_id = orig_wid;
            return 1;
         }
         p_window_id = orig_wid;
         def_one_file = old_one_file;
         def_process_tab_output = old_process_tab_output;
         return "";
      } else if( key == 4 ) {
         typeless old_one_file = def_one_file;
         def_one_file = '';
         typeless old_rec = _macro('m');
         _macro('m',0);
         result = gui_open(OFN_READONLY);
         _macro('m',old_rec);
         if( result ) {
            def_one_file = old_one_file;
            return "";
         }
         _macro_append("edit('-w ':+"_quote(_maybe_quote_filename(p_buf_name))");");
         result = _chr(0);
         def_one_file = old_one_file;
         p_window_id = orig_wid;
         return 1;
      }
   }
   return "";
}
int _OnUpdate_close_all(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_list_buffers(cmdui,target_wid,command));
}

/**
 * Closes all MDI edit windows and buffers except for the 
 * current one.  You are prompted to save changes to modified 
 * files. 
 * 
 * @return Returns 0 if successful.  Otherwise, non-zero is 
 *         returned.
 *  
 * @appliesTo  Edit_Window 
 *  
 * @categories Buffer_Functions 
 */
_command int close_others() name_info(',')
{
   if ( !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) || def_one_file=='') {
      // tab groups not supported
      return _close_all2(false);
   }
   if ( !_no_child_windows() ) {
      close_other_tabs();
   }
   return 0;
}

/**
 * Closes all MDI edit windows and buffers.  You are prompted to save changes
 * to modified files.
 *
 * @return  Returns 0 if successful.  Otherwise, a non-zero number is returned.
 *
 * @appliesTo  Edit_Window
 *
 * @categories Buffer_Functions
 */
_command int close_all() name_info(','VSARG2_REQUIRES_MDI)
{

   // RGH - 5/5/2006
   // For Eclipse, just use their closeAll because looping through the buffers doesn't
   //   work like it does in SlickEdit
   if (isEclipsePlugin()) {
      _eclipse_close_all(p_window_id);
      return(0);
   }

   // IF the process buffer is running AND we can find it not hidden
   if (_process_info() && buf_match(".process",1,"x")!='') {
      if(_DebugMaybeTerminate()) {
         return(1);
      }
   }

   // 1-9LRJ5
   // Show modified buffers window rather than prompting for each
   // individual buffer.
   // 5.23.07 - sg
   return(_close_all2());

   /* 
   while (!quit(true));

   if ( !_no_child_windows()) {
      return(1);
   }

   //Now see if there are any buffers that are not attached to windows.
   p_window_id=_mdi.p_child;
   _safe_hidden_window();
   int orig_buf_id=p_buf_id;

   found_one := false;
   for (;;) {
      if (_need_to_save()) {
         int is_hidden=(p_buf_flags&VSBUFFLAG_HIDDEN);
         if ( ! is_hidden) {
            found_one=true;
            break;
         }

      }
      _next_buffer('NRH');
      if ( p_buf_id==orig_buf_id ) {
         break;
      }
   }
   if (found_one) {
      int status=edit('+t');
      if (status) {
         _message_box('error: 'get_message(status));
         return(status);
      }
      wid := p_window_id;
      for (;;) {
         if (close_buffer()) break;
         if (wid!=p_window_id) break;
      }
      //while (!close_buffer()) ;
   }
   return(0);
   */
}

/** 
 * Close all open files and edit the files given.
 * 
 * @return 0 on success, <0 on error 
 *  
 * @see close_all 
 * @see edit 
 *  
 * @appliesTo  Edit_Window
 * @categories Buffer_Functions
 */
_command int close_all_and_edit,ce(_str filenameArg='', typeless a2_flags='',  _str auto_create_firstw_arg='') name_info(FILE_MAYBE_LIST_BINARIES_ARG'*,'VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   close_all();
   return edit(filenameArg,a2_flags,auto_create_firstw_arg);
}

/**
 *    Deletes contents of current buffer
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command delete_all() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _lbclear();
}
/**
 * Displays <b>Link Window dialog box</b>.  Allows you to select a
 * different file or buffer to display in the current window.  This command is
 * only useful when One File per Window is on.  Use
 * the <b>list_buffers</b> command,  if you are NOT in one file per window mode
 * because it is more powerful than this function.
 *
 * @return Returns 0 if switched buffers successfully.
 *
 * @appliesTo Edit_Window
 *
 * @categories Window_Functions
 *
 */
_command link_window() name_info(','VSARG2_MARK|VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // Let list_buffers/old_list_buffers do the heavy lifting of recording
   // correct statements.
   _macro_delete_line();

   return ( list_buffers('-l') );
}

int _OnUpdate_list_buffers(CMDUI &cmdui,int target_wid,_str command)
{
   // Users seems to want the buffer list tool window always to display.
   return(MF_ENABLED);
#if 0
   if ( _Nofbuffers(1)>0) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
#endif
}

_command eclipse_list_buffers2()
{
   setInternalCallFromEclipse(true);
   orig_buflist := def_buflist;
   def_buflist|=BUFLIST_FLAG_FORCE_OLD_BUFLIST;
   list_buffers();
   def_buflist = orig_buflist;
   setInternalCallFromEclipse(false);
}


/**
 * Displays and activates the Files toolbar
 * 
 * If options or hide_current are specified the old <b>Select a
 * Buffer dialog box</b>. Displays selection list of all buffers
 * being edited. The buttons on the right of this dialog box
 * operate on the selected line in the buffer list box.
 * 
 * @appliesTo Edit_Window
 * @categories Buffer_Functions
 * @param option if this string contains "-h", hidden buffers will be shown
 *               
 *               if this string contains "-w", the dialog will perform as the "Link Window" dialog
 * @param hide_current
 *               if true, hides the current buffer from the list
 * 
 * @return Returns 0 if switched buffers successfully.
 */
_command int list_buffers(_str option='', bool hide_current=false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI)
{
   if(isEclipsePlugin()){
      eclipse_list_buffers();
      return(0);
   }
   if ( (def_buflist&BUFLIST_FLAG_FORCE_OLD_BUFLIST) || option!="" || hide_current!=false ) {
      return old_list_buffers(option,hide_current);
   }
   wid := p_window_id;
   activate_files_files();
   if ((def_buflist&BUFLIST_FLAG_SELECT_ACTIVE) ) {
      wid=wid._MDIGetActiveMDIChild();
      if (wid) {
         wid._FilelistSelectCurrentBuffer();
      }
   }
   return 0;
}

/**
 * Displays the old <b>Select a Buffer dialog box</b>.  Displays
 * selection list of all buffers being edited.  The buttons on
 * the right of this dialog box operate on the selected line in
 * the buffer list box.
 * 
 * @appliesTo Edit_Window
 * @categories Buffer_Functions
 * @param option if this string contains "-h", hidden buffers will be shown
 *               
 *               if this string contains "-l", the dialog will
 *               perform as the "Link Window" dialog
 * @param hide_current
 *               if true, hides the current buffer from the list
 * 
 * @return Returns 0 if switched buffers successfully.
 */
static int old_list_buffers(_str option='', bool hide_current=false)
{
   link_window := false;
   show_system_buffers := false;

   for (;;) {
      cur_option := parse_file(option);
      if ( cur_option=="" ) break;
      if ( substr(cur_option,1,1)=='-' ) {
         switch ( lowcase(substr(cur_option,2)) ) {
         case 'l':
            link_window=true;
            break;
         case 'h':
            show_system_buffers=true;
            break;
         }
      
      }
   }
   status := 0;

   do {
      if (isEclipsePlugin() && !isInternalCallFromEclipse()) {
         status=eclipse_list_buffers();
         break;
      }
      if (p_window_id==_mdi) {
         p_window_id=_mdi.p_child;
      }
      if (!p_mdi_child && !p_DockingArea) {
         status=1;break;
      }
      //link_window='';
      buttons := "";
      help_item := "";
      _str title=nls('Select a Buffer');
      if ( link_window ) {
         title=nls('Link Window');
      }
      p_window_id=_mdi.p_child;
      _macro_delete_line();
      gstart_buf_id=p_buf_id;
      temp_view_id := 0;
      int orig_view_id=_create_temp_view(temp_view_id);
      if (orig_view_id=='') {
         status=1;break;
      }
      link_window_opts := "";
      if (link_window) {
         buttons=nls('&Link to Window,&Open File,&Start Process');
         help_item='Link Window dialog box';
         link_window_opts="-w ";
      } else {
         if ( lowcase(def_keys)=='brief-keys' ) {
            buttons=nls('&Edit,&Write,&Delete');
         } else {
            buttons=nls('&Edit,&Save,&Close,&Order');
         }
         help_item='Select a Buffer dialog box';
      }
      lb_nls_chars=nls_selection_chars(buttons);
      width := 0;

      orig_buflist := def_buflist;
      if ( show_system_buffers ) {
         def_buflist|=BUFLIST_FLAG_SHOW_SYSTEM_BUFFERS;
      }
      _build_buf_list(width,p_buf_id,false,gstart_buf_id,hide_current);
       def_buflist=orig_buflist;
      if ( p_Noflines==0 ) {
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
         _set_focus();_message_box(nls('Buffer list empty'));
         status=1;break;
      }
      typeless buflist=def_buflist;
      typeless result=0;
      if (def_isearch_buflist) {
         result=show('_sellist_form -mdi -modal -reinit',
                     title,
                     SL_VIEWID|SL_SELECTCLINE|SL_DEFAULTCALLBACK|SL_SIZABLE,
                     temp_view_id,
                     buttons,
                     help_item,        // help item name
                     '',                    // font
                     _list_buffers_callback,   // Call back function
                     '',                       // Item list separator
                     'list_buffers',           // retrieve form name
                     '',                       // combo box completion property value
                     '',                       // Minimum list width
                     '',                       // Combo box initial value
                     3                         // Number of leading characters to skip over when searching
                    );
      } else {
         result=show('_sellist_form -mdi -modal -reinit',
                     title,
                     SL_VIEWID|SL_SELECTCLINE|SL_NOISEARCH|SL_DEFAULTCALLBACK|SL_SIZABLE,
                     temp_view_id,
                     buttons,
                     help_item,        // help item name
                     '',                    // font
                     _list_buffers_callback   // Call back function
   
                    );
      }
      if (result=='') {
         status=COMMAND_CANCELLED_RC;break;
      }
      if (result==_chr(0)) {
         /* Start Process or Open File button pressed.  Work done.*/
         status=0;break;
      }
      _macro('m',_macro('s'));
      typeless delete_buffer_id='';
      //typeless status=0;
      p_window_id=_mdi.p_child;
      // IF we are doing a link window AND
      //    we are in one file per window AND
      //    this is the last window viewing this buffer AND
      //    and it is not a keep on quit buffer (stay residen buffer).
      if (link_window && def_one_file!='' && _islast_window() && !(p_buf_flags&VSBUFFLAG_KEEP_ON_QUIT)) {
         //delete_buffer_id=p_buf_id;
         status=_window_quit(false/* support VSBUFFLAG_KEEP_ON_QUIT*/,
                             true /*Save position.*/,
                             false/* Don't support hidden windows. */,
                             false /* Just save buffer. */
                             );
         if (status) {
            break;
         }
      }
      typeless buf_id=0;
      if (_isno_name(result)){
         parse result with '<' buf_id'>';
         _macro('m',_macro('s'));
         _macro_call('edit',link_window_opts'+bi 'buf_id);
         status=edit(link_window_opts'+bi 'buf_id);
         if ( ! status ) {
            p_buf_flags &= (~VSBUFFLAG_HIDDEN);
         }
      } else {
          _macro('m',_macro('s'));
          _macro_call('edit',link_window_opts'+b 'result);
          status=edit(link_window_opts'+b 'result);
          if ( ! status ) {
             p_buf_flags &= (~VSBUFFLAG_HIDDEN);
          }
      }
      if (!status) {
         if (p_window_state=='I') p_window_state='N';
         // IF we need to delete original buffer AND
         //    this
         if (delete_buffer_id!='' && p_buf_id!=delete_buffer_id) {
            buf_id=p_buf_id;
            p_buf_id=delete_buffer_id;
            _delete_buffer();
            p_buf_id=buf_id;
         }
      }
   } while ( false );
   return(status);
}

/* This procedure does not duplicate the buffer's margins, tabs, undo steps, */
/* etc. and thats why this procedure has not been made global yet. */
static _str duplicate_buffer(_str options="")
{
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      return(mark);
   }
   top();_select_line(mark);
   bottom();_select_line(mark);

   typeless encoding=p_encoding;
   typeless status=load_files( options' +t');
   if ( status ) {
      _free_selection(mark);
      return(status);
   }
   p_encoding=encoding;
   _delete_line();
   status=_copy_to_cursor(mark);
   _free_selection(mark);
   return(status);

}
/*static*/ _str _buflist_name(_str result)
{
   result=substr(result,BUFFER_COL);
   if ( def_buflist&BUFLIST_FLAG_SEPARATE_PATH ) {
      if (_isno_name(result)) {
         return(result);
      }
      name := "";
      path := "";
      parse result with name'<'path'>' ;
      if ( path!='' ) {
         result=path:+strip(name);
      }
   }
   return(result);


}
_str _build_buflist_name(_str match_name)
{
   line := "";
   if ( (def_buflist&BUFLIST_FLAG_SEPARATE_PATH) &&
      (_Substr(match_name,2,1)==':' || substr(match_name,1,1)==FILESEP) ) {
      line=field(_strip_filename(match_name,'P'),13)'<'_strip_filename(match_name,'N')'>';
   } else {
      line=match_name;
   }
   return(line);
}
void _build_buf_list(int &width, 
                     int temp_buf_id,
                     bool list_modified=false,
                     int start_buf_id=-1,
                     bool hide_current=false,
                     int (*bufIdList)[]=null)
{
   // build hash table of buffer's to check
   bool bufferIdsToCheck:[];
   if (bufIdList != null) {
      for (i:=0; i<bufIdList->_length(); i++) {
         bufferIdsToCheck:[(*bufIdList)[i]] = true;
      }
   }

   // should we check for delphi?
   bool checkForDelphi = (index_callable(find_index("delphiIsRunning",PROC_TYPE)) &&
                             list_modified && delphiIsRunning());

   _safe_hidden_window();
   int allow_system_buffers=(def_buflist&BUFLIST_FLAG_SHOW_SYSTEM_BUFFERS);
   width=0;
   if (start_buf_id<0) {
      start_buf_id=_mdi.p_child.p_buf_id;
   }
   line := "";
   match_name := "";
   skipBuf := false;
   typeless modify = false;
   load_files('+bi 'start_buf_id);
   for (;;) {
      // Skip over Delphi buffers:
      skipBuf = false;
      if ( checkForDelphi && delphiIsBufInDelphi(p_buf_name) ) {
         skipBuf = true;
      }
      // Maybe hide current buffer
      if (hide_current && p_buf_id==start_buf_id) {
         skipBuf = true;
      }
      // skip this buffer if it isn't in the list
      if (!skipBuf && bufIdList!=null && !bufferIdsToCheck._indexin(p_buf_id)) {
         skipBuf = true;
      }
      if ( !skipBuf && (p_buf_id!=temp_buf_id) ) {
         if (p_DocumentName!='') {
            match_name=p_DocumentName;
         } else {
            match_name=p_buf_name;
            if (_isPluginFileSpec(match_name)) {
               // So that external apps don't get confused.
               // Not sure if this is really needed.
               match_name=p_buf_name_no_symlinks;
            }
         }
         modify=p_modify;
         if (match_name=='') {
            match_name=NO_NAME:+p_buf_id'>';
         }
         if (!list_modified ||
              (modify &&  _need_to_save())
            ) {
            if ( modify ) {
               modify=' *';
            } else {
               modify='';
            }
            line=_build_buflist_name(match_name);
            int is_hidden=(p_buf_flags&VSBUFFLAG_HIDDEN);
            if ( ! is_hidden || allow_system_buffers) {
               if ( is_hidden ) {
                  modify :+= 'H';
               }
               int buf_id=p_buf_id;
               p_buf_id=temp_buf_id;
               insert_line(substr(modify,1,BUFFER_COL-1):+ strip(line,'L'));
               p_buf_id=buf_id;
               if ( length(line)>width ) { width=length(line); }
            }

         }
      }
      _next_buffer('NRH');
      if ( p_buf_id==start_buf_id ) {
         break;
      }
   }
   p_buf_id=temp_buf_id;
   if ( def_buflist&BUFLIST_FLAG_SORT && !_on_line0()) {
      typeless mark=_alloc_selection();
      if ( mark>=0 ) {
         top();p_col=BUFFER_COL;_select_block(mark);
         bottom();p_col=255;_select_block(mark);
         typeless old_mark=_duplicate_selection('');
         _show_selection(mark);
         sort_on_selection('-F I' /* _fpos_case */);
         _show_selection(old_mark);
         _free_selection(mark);
         top();
      }
   }
   int i,next=1;
   for (i=1; i<=p_Noflines ; ++i) {
      p_line=next;
      get_line(line);
      modify=substr(line,1,BUFFER_COL-1);
      new_modify := substr(stranslate(modify,'','H'),1,BUFFER_COL-1);
      if ( pos('H',modify) || (substr(line,BUFFER_COL,1)=='.' && (def_buflist&BUFLIST_FLAG_SORT)) ) {
         _delete_line();
         bottom();insert_line(new_modify:+ substr(line,BUFFER_COL));
      } else {
         replace_line(new_modify:+ substr(line,BUFFER_COL));
         next++;
      }
   }
}
/**
 * @return Returns '' if no items are selected in the list box.  Items which
 * contain space characters are placed in double quotes.  Items which contain
 * double quotes are not supported. <i>buffer_name</i> is a 
 * buffer where each line contains a filename.  If the 
 * <i>cwd</i> parameter is given and is not '', the list box text is assumed to
 * be file names and will be converted to absolute form relative to the
 * directory, <i>cwd.
 *
 * @see _lbdeselect_all
 * @see _lbselect_all
 * @see _lbselect_line
 * @see _lbdeselect_line
 * @see _lbinvert
 * @see _lbisline_selected
 * @see _lbfind_selected
 *
 * @appliesTo List_Box
 *
 * @categories List_Box_Methods
 *
 */
_str _lbmulti_select_result(_str not_supported="", _str cwd="", typeless isfileman_list="")
{
   line := "";
   text := "";
   typeless result='';
   typeless status=_lbfind_selected(true);
   for (;;) {
      if (status) break;
      if (isfileman_list != "") {
         get_line(line);
         text=pcfilename(line);
      } else {
         text=_maybe_quote_filename(_lbget_text());
      }
      if (cwd!='') {
         text=_absolute2(text,cwd);
      }
      result :+= " "text;
      status=_lbfind_selected(false);
   }
   return(result);
}
static void restore_view(int list_view_id,int temp_view_id)
{
   _delete_temp_view(temp_view_id,false);
   activate_window(list_view_id);
}
int _save_non_active(_str &buf_name,bool quit_option=false,int save_flags=SV_RETURNSTATUS,bool display_buffer_id=false)
{
   typeless status=0;
   typeless buf_id=0;
   temp_view_id := 0;
   list_view_id := 0;
   j := lastpos('<',buf_name);
   if ((j>=0 && display_buffer_id) || _isno_name(buf_name)) {
      parse substr(buf_name,j) with '<' buf_id'>';
      status=_open_temp_view('',temp_view_id,list_view_id,'+bi 'buf_id);
      //status=load_files('+bi 'buf_id);
   } else {
      status=_open_temp_view(buf_name,temp_view_id,list_view_id,"+b");
      //status=load_files('+b 'buf_name);
   }
   if ( status ) {
      return(status);
   }
   if (!quit_option && lowcase(def_keys)=='brief-keys' && ! p_modify ) {
      restore_view(list_view_id,temp_view_id);
      _message_box(nls('File not modified.  Nothing saved.'));
      return(1);
   }
   typeless result=0;
   if ( !quit_option ||
        (p_modify && ! (p_buf_flags&VSBUFFLAG_THROW_AWAY_CHANGES))) {  /* file modified? */
      result=IDYES;
      if (quit_option) {
         activate_window(list_view_id);
         result=prompt_for_save(nls("Save changes to '%s'?",buf_name));
         if (result==IDCANCEL) {
            restore_view(list_view_id,temp_view_id);
            return(COMMAND_CANCELLED_RC);
         }
      }
      if (result==IDYES) {
         option := ""; // option to pass to save()
         is_noname := _isno_name(buf_name);
         is_dir := (buf_name != '' && (isdirectory(buf_name) != '0'));
         if (is_noname || is_dir) {
            fname := '';
            if (is_noname) {
            parse buf_name with '<' buf_id'>';
            }
            if (is_dir) {
               fname = buf_name;
            }

            // Give this buffer a name
            activate_window(list_view_id);
            result=_OpenDialog('-mdi -new -modal',
                 'Save As',
                 '',   /* Initial wildcards */
                 //'*.c;*.h',
                 def_file_types,
                 OFN_SAVEAS,
                 '',      // Default extensions
                 fname,      // Initial filename
                 '',      // Initial directory
                 ''       // Reserved
                 );
            if (result=='') {
               restore_view(list_view_id,temp_view_id);
               return(COMMAND_CANCELLED_RC);
            }
            activate_window(temp_view_id);

            cur := "";
            for ( cur=parse_file(result); cur!=""; cur=parse_file(result) ) {
               if (result=="") {
                  result=cur;
                  break;
               }
               option :+= cur;
            }
            name(result);
            p_buf_flags &= ~VSBUFFLAG_PROMPT_REPLACE;
            buf_name=p_buf_name;
         }
         activate_window(temp_view_id);
         if ((p_buf_flags & VSBUFFLAG_PROMPT_REPLACE) &&
              file_match('-p 'buf_name,1)!='') {
            activate_window(list_view_id);
            status=overwrite_existing(buf_name,'Save');
            if ( status ) {
               restore_view(list_view_id,temp_view_id);
               return(status);
            }
         }
         activate_window(temp_view_id);
         status=save(option, +save_flags);
         if (status) {
            /////////////////////////////////////////////////////////////////
            // Don't call _save_status here, it was already called in save()

            //activate_window(list_view_id);
            //_save_status(status,buf_name);
            //restore_view(list_view_id,temp_view_id);
            return(status);
         }
      } else {
         activate_window(temp_view_id);
         //jguiSendFileInfo(true);
      }
      activate_window(temp_view_id);
      p_modify=false;
   }
   activate_window(temp_view_id);
   if (quit_option) {
      if (def_one_file!='') {
         // Delete all mdi windows which are displaying this buffer.
         count := 0;
         buf_id=p_buf_id;
         wid := window_match(p_buf_name,1,'xn');
         for (;;) {
            if (!wid) break;
            if (wid.p_mdi_child && wid.p_buf_id==buf_id) ++count;
            wid=window_match(p_buf_name,0,'xn');
         }
         if (count>=1) {
            buf_name=p_buf_name;
            restore_view(list_view_id,temp_view_id);

            wid=window_match(buf_name,1,'xn');
            for (;;) {
               if (!wid) break;
               if (count<=0) break;
               if (wid.p_buf_id==buf_id) {
                  --count;
                  // If deleting last window
                  if (wid.p_mdi_child) {
                     if (!count) {
                        // Delete the window and the buffer
                        wid.close_window('',true);
                     } else {
                        // Delete the window and not the buffer.
                        wid._delete_window();
                     }
                  }
               }
               wid=window_match(buf_name,0,'xn');
            }
         } else {
            close_buffer(true,true /* allow delete if hidden */);
            restore_view(list_view_id,temp_view_id);
         }
      } else {
         quit(true,true /* allow delete if hidden */);
         restore_view(list_view_id,temp_view_id);
      }
   } else {
      restore_view(list_view_id,temp_view_id);
   }
   return(0);
}
/**
 * @return Returns <b>true</b> if the string <i>name</i> starts with "no-
 * name<b".
 *
 * @categories Buffer_Functions
 *
 */
bool _isno_name(_str name)
{
   return(!name._isempty() && substr(name,1,length(NO_NAME))==NO_NAME);
}
_str _build_buf_name()
{
   if (p_buf_name:!='') {
      return(p_buf_name);
   }
   return(NO_NAME:+p_buf_id'>');
}
_str _build_buf_name2(_str buf_name,int buf_id)
{
   if (buf_name:!='') {
      return(buf_name);
   }
   return(NO_NAME:+buf_id'>');
}
static void _delete_unnamed_unsaved_temp_files(bool (&exclude_buf_ids):[]=null) {
   if (!p_mdi_child || (p_window_flags &HIDE_WINDOW_OVERLAP)) {
      p_window_id=_mdi.p_child;
   }
   int first_buf_id=p_buf_id;
   for (;;) {
      if (p_buf_name=='' && p_modified_temp_name!='') {
         if (!exclude_buf_ids._indexin(p_buf_id)) {
            delete_file(p_modified_temp_name);
         }
      }
      _next_buffer('RH');
      if (p_buf_id==first_buf_id) break;
   }
}
/**
 * Displays a list of buffers that are modified.  The <b>Modified Buffers
 * dialog box</b> is displayed which allows you to select the files you wish to
 * save, save all files, or save none.  The <i>title</i> argument specifies the
 * title of the dialog box and defaults to "Modified Buffers" if not specified
 * or ''.
 *
 * @return Returns 0 if successful.
 *
 * @appliesTo Edit_Window
 *
 * @categories Buffer_Functions, Window_Functions
 *
 */
_command int list_modified(_str title='',bool quiet=false, bool hideCurrent=false,int (*bufIdList)[]=null,bool show_using_current_wid=false,
                           bool allow_restore_unnamed_as_modified=false,bool &restore_unnamed_as_modified=false,bool prompt_unnamed_save_all=def_prompt_unnamed_save_all,bool delete_unsaved_unnamed_temp_files=false) name_info(','VSARG2_REQUIRES_MDI)
{
   // Don't auto restore unnamed files as modified
   restore_unnamed_as_modified=false;
   if (!p_mdi_child || (p_window_flags &HIDE_WINDOW_OVERLAP)) {
      p_window_id=_mdi.p_child;
   }
   _macro_delete_line();
   gstart_buf_id=p_buf_id;
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if (orig_view_id=='') return(1);
   if ( title=='' ) {
     title=nls('Modified Buffers');
   }
   width := 0;
   _build_buf_list(width,p_buf_id,true,gstart_buf_id,hideCurrent,bufIdList);
   //jguiAddModifiedBuffersToView();
   if ( p_Noflines==0 ) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      if (!quiet) {
         message(nls('No buffers are modified.'));
      }
      return(0);
   }
   buttons := nls('Save &All,&Save Selected:btnsave_selected,&Diff Selected:btndiff_selected,&Invert,Save &None');
   if (!_haveDiff()) {
      buttons = nls('Save &All,&Save Selected:btnsave_selected,&Invert,Save &None');
   }
   lb_nls_chars=nls_selection_chars(buttons);
   typeless buflist=def_buflist;

   activate_window(orig_view_id);
   typeless result=show('_sellist_form '(show_using_current_wid?'':'-mdi ')'-modal',
               title,
               SL_VIEWID|SL_ALLOWMULTISELECT|SL_NOISEARCH|
               SL_DEFAULTCALLBACK|SL_SIZABLE,
               temp_view_id,
               buttons,
               "Modified Buffers dialog box",        // help item name
               '',             // font
               _list_modified_ft   // Call back function
              );
   def_buflist=buflist;
   if ( result=='' ) {
      message('command cancelled');
      return(COMMAND_CANCELLED_RC);
   }
   typeless status=0;
   buf_name := "";
   typeless buf_id=0;
   orig_buf_id := 0;
   mdi_view_id := 0;
   was_hidden_window := false;
   switch (result) {
   case 1:
      // Auto restore unnamed files as modified
      if (allow_restore_unnamed_as_modified) {
         restore_unnamed_as_modified=!prompt_unnamed_save_all;
      }
      p_window_id=_mdi.p_child;
      orig_def_prompt_unnamed_save_all:=def_prompt_unnamed_save_all;
      // IF we are not exiting the editor, always prompt for name
      if (!allow_restore_unnamed_as_modified) {
         def_prompt_unnamed_save_all=true;
      }
      status=save_all(-1,false,false,!allow_restore_unnamed_as_modified || prompt_unnamed_save_all);
      def_prompt_unnamed_save_all=orig_def_prompt_unnamed_save_all;
      return(status);
   case 6: // Save None
      if (allow_restore_unnamed_as_modified) {
         // Don't auto restore unnamed files as modified
         restore_unnamed_as_modified=false;
      }
      if (delete_unsaved_unnamed_temp_files) {
         _delete_unnamed_unsaved_temp_files();
      }
      break;
   default:
      if (substr(result,1,1)=='@') {
         if (allow_restore_unnamed_as_modified) {
            // Don't auto restore unnamed files as modified
            restore_unnamed_as_modified=false;
         }
         _TagDelayCallList();
         mdi_view_id=_mdi.p_child;
         orig_buf_id=p_buf_id;
         p_window_id=mdi_view_id;
         was_hidden_window=false;
         if (p_window_flags &HIDE_WINDOW_OVERLAP) {
            was_hidden_window=true;
         }
         int i;
         for (i=0;i<_param1._length();++i) {
            buf_name=_param1[i];
            activate_window(mdi_view_id);
            if (_isno_name(buf_name)) {
               parse buf_name with '<' buf_id'>' ;
               status=edit('+q +bi 'buf_id);
            } else {
               status=edit('+q +b 'buf_name);
            }
            if ( status ) {
               p_window_id=_mdi.p_child;_set_focus();
               _message_box(nls("Unable to active file '%s'\n",buf_name)get_message(status));
               _TagProcessCallList();
               return(status);
            }
            status=save();
            if ( status ) {
               _TagProcessCallList();
               return(status);
            }
            if (!was_hidden_window) {
               activate_window(mdi_view_id);
            } else {
               was_hidden_window=false;
               get_window_id(mdi_view_id);
               orig_buf_id=p_buf_id;
            }
         }
         if (!was_hidden_window) {
            activate_window(mdi_view_id);
            mdi_view_id._set_focus();
            p_buf_id=orig_buf_id;
         }
         _TagProcessCallList();
         if (delete_unsaved_unnamed_temp_files) {
            _delete_unnamed_unsaved_temp_files();
         }
      }
   }
   /*
       Retag files that were not saved.
   */
   status=_open_temp_view('',temp_view_id,orig_view_id,'+bi '_mdi.p_child.p_buf_id);
   if (status) {
      return(0);
   }
   _TagDelayCallList();
   int first_buf_id=p_buf_id;
   for (;;) {
      _next_buffer('NHR');
      if (
          !(p_buf_flags&VSBUFFLAG_HIDDEN) &&
           (p_ModifyFlags&MODIFYFLAG_TAGGED) &&
            (p_modify)
          ) {
         _cbquit_maybe_retag();
      }
      if (p_buf_id==first_buf_id) break;
      // The +m option preserves the old buffer position information for the current buffer
   }
   _delete_temp_view(temp_view_id,false /* Don't delete buffer*/);
   activate_window(orig_view_id);
   _TagProcessCallList();

   return(0);
}

bool _AllowRestoreModified(bool restore_unnamed_as_modified) {
   if(p_buf_name=='' && p_modify && restore_unnamed_as_modified) {
      return true;
   }
   return false;
}

/*
    Use this function to check if you need to save an
    MDI buffer or an editor control buffer.
*/
bool _need_to_save2(_str buf_name="", _str doTestModify="")
{
   TestModify := doTestModify!='' && doTestModify;
   if (buf_name!="") {
      typeless buf_id="", ModifyFlags="", buf_flags="";
      parse buf_match(buf_name,1,'HEV') with buf_id ModifyFlags buf_flags buf_name;
      if (buf_id=='') {
         // Buffer was not found.
         return(false);
      }
      temp_view_id := 0;
      orig_view_id := 0;
      _open_temp_view("",temp_view_id, orig_view_id, "+bi "buf_id);
      typeless status=_need_to_save2('',TestModify);
      _delete_temp_view(temp_view_id, false);
      activate_window(orig_view_id);
      return(status);

   }
   return((!TestModify || p_modify) && (p_AllowSave || _need_to_save()));
}
/**
 * Use this function if you only want to check for MDI buffers.
 *
 * @return Returns non-zero if the current buffer needs to be saved.  The
 * <b>p_modify</b> property should be checked as well.  A non-zero
 * <b>p_modify</b> property indicates the buffer has been modified.  However,
 * certain special buffer names and buffers with the (p_buf_flags &
 * (VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN)) true, do not need to be saved.  An example,
 * will better describe the correct usage of this function.
 *
 * @example
 * <pre>
 * if (p_modify && _need_to_save()) {
 *     // Prompt the user here or automatically save this file.
 * }
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
bool _need_to_save()
{
   return(
          !(p_buf_flags&(VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN))&&
             p_LangId != 'fileman' &&
            substr(p_buf_name,1,1)!='.'
   );
}


/**
 * This function is used to assist in creating a font string argument used as
 * input to several Slick-C&reg; functions.  The <i>rgb_color</i> argument is ignored
 * by some Slick-C&reg; functions that don't support it.
 *
 * @return  Returns a string in the format: <i>font_name,  font_size,
 * font_flags,
 *
 * @categories Miscellaneous_Functions
 */
_str _font_param(_str font_name,_str font_size,_str font_flags, _str rgb_color="")
{
   return(font_name','font_size','font_flags','rgb_color);
}
