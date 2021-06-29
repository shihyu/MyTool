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
#import "clipbd.e"
#import "compile.e"
#import "error.e"
#import "fileman.e"
#import "files.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "slickc.e"
#import "stdprocs.e"
#import "tags.e"
#import "se/ui/toolwindow.e"
#import "toolbar.e"
#import "help.e"
#endregion

/* This module should be link after parseoption, .... ... */
/* function have been loaded. Also the keyboard should be functional */
/* before this module can be useful. */

_str st_batch_mode=0;    /* True if compiling batch program with -p option. */
static const ST_COMMAND= '0 vstw';

/**
 * Compiles the module specified.  If no name is specified and the 
 * current buffer has the extension e or cmd, the current module is saved 
 * (if necessary) and compiled.
 * 
 * @return Returns 0 if successful.  A positive return code indicates a return code 
 * from the Slick-C&reg; translator meaning there is an error in the source 
 * module.  A negative return code indicates an error trying to find or 
 * execute the Slick-C&reg; translator.
 * 
 * @categories Macro_Programming_Functions, Miscellaneous_Functions
 * 
 */ 
_command st(_str module_name="") name_info(','VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   return(vstw(module_name,arg(2),arg(3)));

}
bool _macroCompilePermitted(_str filename) 
{
   if (_haveProMacros()) {
      return true;
   }
   filename=absolute(strip(filename,'B','"'),null,true);
   path:=_strip_filename(filename,'n');
   macros_path:=absolute(_getSlickEditInstallPath()'macros':+FILESEP,null,true);
   if (length(path)>=length(macros_path) && _file_eq(macros_path,substr(path,1,length(macros_path)))) {
      name:=_strip_filename(filename,'pe');
      // Matches vusrmacs
      if (_file_eq(name,USERMACS_FILE)) {
         return true;
      }
      return false;
   }
   return true;
}
/**
 * This function is identical to the st command.
 * 
 * @categories Macro_Programming_Functions
 * 
 */ 
_command vstw(_str name="",...) name_info(','VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   //say('name='name);
  tconvert := "";
  _str st_command=ST_COMMAND;
  quiet := false;

  qparams := "";
  errfile := "";
  if ( st_batch_mode ) {
     qparams='';
  } else {
     //_error_file=absolute(COMPILE_ERROR_FILE);
     _error_file=GetErrorFilename();//GetErrorFilename sets COMPILE_ERROR_FILE
     qparams="-q -e "_maybe_quote_filename(COMPILE_ERROR_FILE)" ";
     quit_error_file();
     errfile=_error_file;
  }

  ch := "";
  option := "";
  uoption := "";
  async := "";

  // have to parse this option out manually for state file build
  if (pos(" -a ", name) > 0) {
     name = stranslate(name, " ", " -a ");
     async='A';
  }

  for (;;) {
     option=parse_file(name,false);
     if (option=='') break;
     uoption=upcase(option);
     ch=substr(uoption,1,1);
     if (ch!='-' && ch!='+') {
        // Need to convert plugin://name/macro.e to resolved native os path.
        option=strip(strip(option),'B','"');
        if (pos('plugin:',option)==1) {
           option=absolute(option,null,true);
        } else {
           option=absolute(option);
        }
        name :+= ' '_maybe_quote_filename(option);
        break;
     }
     switch (substr(uoption,2)) {
     case 'Q':
        qparams :+= option' ';
        break;
     case 'A':
        async='A';
        break;
     case 'W':
        quiet=true;
        break;
     case 'F':
        option=parse_file(name);
        qparams :+= ' -F 'option' ';
        break;
     case 'T':
        tconvert='-t ';
        st_command :+= '17';
        break;
     case 'TD':
        tconvert='-tu ';
        break;
     case 'TU':
        tconvert='-tu ';
        break;
     default:
        if (substr(uoption,2,1)=='I') {
           qparams :+= _maybe_quote_filename(option)' ';
           break;
        }
        _message_box('Invalid option uoption='uoption);
        return(1);
     }
  }


  typeless status=0;
  extension := "";
  if ( name=='' ) {
    extension=_get_extension(p_buf_name);
    if ( _file_eq('.'extension,_macro_ext) || _file_eq(extension,'cmd') ||
       (_file_eq(extension,'sh') && tconvert!='') ) {
      if ( p_modify ) {
         status=save();
         if ( status ) {
            return(status);
         }
      }
      name=_maybe_quote_filename(p_buf_name);
    } else {
       prompt('',nls('Compile macro'));
    }
  }
  if (!_macroCompilePermitted(name)) {
     clear_message();
     popup_message(nls("Compiling macro '%s1' requires Pro version",name));
     return VSRC_FEATURE_REQUIRES_PRO_EDITION;
  }

  line := "";
  if ( ! quiet ) { message(nls('Compiling')); }
  rc=0;
  //say('h4 qparams='qparams);
  //say('h4 name='name);
  //say('h4 st_command='st_command);
  //say('h4 tconvert='tconvert);
  if (file_eq(absolute(substr(name,1,length(VSCFGPLUGIN_DIR))),absolute(VSCFGPLUGIN_DIR))) {
     name=absolute(name,null,true);
  }
  line=st_command" "tconvert:+qparams:+' ':+name;
  pid := 0;
  status=shell(line,async:+'N', "", pid);

  if ( status==FILE_NOT_FOUND_RC ) {
     message(nls('ST program not found'));
     return(status);
  }
  if ( status<0 ) {  /* error from shelling st? */
     message(get_message(status));
     return(status);
  }
  if ( status!=0 && async=="" ) {
     p_window_id=_mdi.p_child;
     status=st_position_on_error();
     /* Must return 1 since the built in make facility needs to know */
     /* that the message has already been displayed by st_position_on_error. */
     return(1);
  } else {
    if ( ! quiet ) { message(nls('Compilation completed successfully.')); }
  }
  if (async != "") return pid;
  return(0);

}
/**
 * Parses Slick-C&reg; Translator error message.  Cursor is placed on the error 
 * if one exists.
 * 
 * @return Returns 0 if successful. Otherwise 1 is returned.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_str st_position_on_error(_str errfile="")
{
  p_window_id=_mdi.p_child;
  if (errfile != '') {
     _error_file=errfile;
  }
  if (_in_firstinit) {
     index := find_index('st_position_on_error',PROC_TYPE);
     _post_call(index,_error_file);
     return(1);
  }
  // For now, Slick-C only needs to support SBCS/DBCS filenames and content
  typeless status=load_files('+d +l '_maybe_quote_filename(_error_file));
  if ( status ) {
     if (status==NEW_FILE_RC) {
        _delete_buffer();
     }
     return(1);
  }
  //status=delete_file(_error_file);
  msg := "";
  get_line(msg);
  if ( substr(msg,1,16)=="Slick Translator" ) {
     _delete_line();
     _delete_line();
  }
  last_line := "";
  if ( p_Noflines>0 ) {
    get_line(last_line);
    _delete_buffer();
    //parse last_line with filename ' ' line col ':' msg ;
    temp := last_line;
    filename := parse_file(temp);
    typeless line="";
    typeless col="";
    parse temp with line col':'msg;
    if ( filename=='' || ! isinteger(line) || ! isinteger(col) || msg=='' ) {
       msg=last_line;
    } else {
       // if we are building the state file and files.e or vc.e haven't 
       // yet been loaded, then just display a message box.
       if (index_callable(find_index("window_edit", PROC_TYPE)) && index_callable(find_index("edit"))) {
          status=edit(_maybe_quote_filename(filename));
          if (isEclipsePlugin()) {
             _message_box("Error compiling: "filename);
          }
       } else {
          _message_box("Error compiling: "filename);
          status=STRING_NOT_FOUND_RC;
       }
       if ( ! status && line!='' && col!='' ) {
          name := _strip_filename(filename,'P');
          _str oldscroll_style=_scroll_style();
          _scroll_style('C');
          if ( col<=0 ) {
            p_RLine=line-1;    /* compiler is off by 1 */
            _end_line();left();
          } else {
            p_col=col;
            p_RLine=line;
          }
          _scroll_style(oldscroll_style);
       }
    }
  } else {
    if ( msg=='' ) msg=nls('No errors');
    _delete_buffer();
  }
  refresh();  /* Don't want message to go to shell window. */
              /* Refresh will close shell window and redraw editor screen. */
  message(msg);
  //st_compile_error=1;
  return(0);

}
static const TBSLICKCSTACK_FORM= '_tbslickc_stack_form';

int _tbGetActiveSlickCStackForm() {
   if (index_callable(find_index('_tbGetActiveForm',PROC_TYPE))) {
      return tw_find_form(TBSLICKCSTACK_FORM);
   }
   return _find_formobj(TBSLICKCSTACK_FORM,'N');
}
_command void dump_slickc_stack()
{
   _StackDump();
}
void _UpdateSlickCStack(int ignoreNStackItems=0,int errorCode=0,_str DumpFileName="")
{
   if (!index_callable(find_index('show_tool_window',PROC_TYPE|COMMAND_TYPE)) ||
       !_hit_defmain
        ) {
      if (errorCode<0) {
         say(get_message(errorCode));
      }
      _StackDump(0,1,ignoreNStackItems+1);
      return;
   }
   wid := _tbGetActiveSlickCStackForm();
   if (!wid) {
      show_tool_window(TBSLICKCSTACK_FORM);
      wid=_tbGetActiveSlickCStackForm();
      if (!wid) {
         return;
      }
   }
   _nocheck _control edit1;
   wid.edit1._lbclear();
   if (DumpFileName!='') {
      wid.edit1.insert_line(' Stack trace written to file: 'DumpFileName);
   }
   if (errorCode<0) {
      wid.edit1.insert_line(' 'get_message(errorCode));
   }
   wid.edit1._StackInsertList(ignoreNStackItems+1);

   int last = _last_window_id();
   int i;
   for (i=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_FORM && !i.p_edit) {
         if (i.p_name:==TBSLICKCSTACK_FORM) {
            i.edit1.top();i.edit1.down();
         }
      }
   }
   refresh();
}

defeventtab slickc_stack_keys;
def 'ENTER'=slickc_stack_goto;
def 'LBUTTON-DOUBLE-CLICK'=slickc_stack_goto;

_command void slickc_stack_goto() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI|VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Slick-C Debugging");
      return;
   }
   if ( command_state() || p_window_state:=='I' ) {
      try_calling(eventtab_index(_default_keys,
                          _default_keys,event2index(ENTER)));
      return;
   }
   edit1_view_id := 0;
   get_window_id(edit1_view_id);
   int edit1_buf_id=p_buf_id;
   line := "";
   get_line(line);
   if (line=="" || substr(line,1,1)=="") {
      _beep();
      return;
   }
   found := "";
   typeless status=0;
   filename := "";
   typeless offset="";
   typeless proc_name="";
   parse line with filename offset proc_name'(';
   ext := _get_extension(filename,true);
   if (_file_eq(ext,DLLEXT)) {
      // This is a dll entry
      status=find_tag('-e c 'proc_name);
      if (status) {
         return;
      }
   } else {
      filename=_strip_filename(filename,'E');
      filename :+= _macro_ext;
      if (_isRelative(filename) && file_exists(VSCFGPLUGIN_DIR:+filename)) {
         found=VSCFGPLUGIN_DIR:+filename;
      } else {
         found=slick_path_search(filename);
      }
      if (found=="") {
         // TBF:  we need a better technique for mapping module names to load paths
         found=file_match("+T "_maybe_quote_filename(_getSlickEditInstallPath():+FILESEP:+"macros":+FILESEP:+filename),1);
         if (found=="") {
            _message_box(nls("File %s not found",filename));
            return;
         }
      }
      // sometimes file_match will come up with a .ex even though a .e is there
      ext = _get_extension(found,true);
      if (_file_eq(ext, ".ex")) {
         filename = _strip_filename(found, 'e') :+ ".e";
         if (file_exists(filename)) found = filename;
      }
      filename=found;
      status=edit(_maybe_quote_filename(filename));
      if (status) {
         return;
      }
      status=st('-f 'offset);
      /*if (status) {
         return;
      } */
   }
   view_id := 0;
   get_window_id(view_id);
   int buf_id=p_buf_id;
   activate_window(edit1_view_id);
   p_buf_id=edit1_buf_id;
   save_pos(auto p);
   top();up();
   for (;;) {
      if (down()) {
         break;
      }
      _lineflags(0,CURLINEBITMAP_LF);
   }
   restore_pos(p);
   _lineflags(CURLINEBITMAP_LF,CURLINEBITMAP_LF);
   activate_window(view_id);p_buf_id=buf_id;
}
_command void slickc_stack_mode() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI)
{
  p_mode_name='Slick-C Stack';
  p_LangId="";
  p_mode_eventtab=find_index('slickc_stack_keys',EVENTTAB_TYPE);
  //_message_box('p_mode_eventtab='p_mode_eventtab);
}
static const SLICKC_STACK_BUFNAME= ".slickc_stack";

defeventtab _tbslickc_stack_form;
static int EditWindowBufferID(...) {
   if (arg()) edit1.p_user=arg(1);
   return edit1.p_user;
}

void edit1.on_create()
{
   EditWindowBufferID(p_buf_id);
   // (+m) Since we don't know what buffer is active here,
   // don't save previous buffer currsor location.
   int status=load_files("+m +q +b "SLICKC_STACK_BUFNAME);
   if (status) {
      // Since most strings are UTF-8, use UTF-8 encoding for buffer
      load_files("+m +futf8 +q +t");
      p_buf_name=SLICKC_STACK_BUFNAME;
      p_buf_flags|=VSBUFFLAG_HIDDEN|VSBUFFLAG_THROW_AWAY_CHANGES;
   }
   // Since most strings are UTF-8, use a Unicode font.
   _use_source_window_font(CFG_UNICODE_SOURCE_WINDOW);
   slickc_stack_mode();
   //p_readonly_mode=1;
   p_window_flags|=(OVERRIDE_CURLINE_RECT_WFLAG|CURLINE_RECT_WFLAG);
   p_MouseActivate=MA_NOACTIVATE;
}
void edit1.on_destroy()
{
   if (EditWindowBufferID()!=p_buf_id) {
      /*if (p_buf_flags&VSBUFFLAG_HIDDEN) {
         if (!_DialogViewingBuffer(p_buf_id,p_window_id)) {
            call_list('_cbquit_');
            _delete_buffer();
         }
      } */
      load_files('+q +m +bi 'EditWindowBufferID());
   }
}
void _tbslickc_stack_form.on_resize()
{
   formWid := p_active_form;
   int edit1_wid=edit1;
   edit1_wid.p_x = 0;
   edit1_wid.p_y = 0;
   ctlframe.p_width = ctlsupport_button.p_x*2+ctlsupport_button.p_width;
   edit1.p_width = _dx2lx(SM_TWIP,p_active_form.p_client_width) - edit1.p_x - ctlframe.p_width;
   edit1.p_height = _dy2ly(SM_TWIP,p_active_form.p_client_height) - edit1.p_y*2;
   ctlframe.p_x = edit1_wid.p_x_extent;
   ctlframe.p_y = 0;
}
bool _on_slickc_error(int errorCode,_str filename)
{
   _UpdateSlickCStack(1,errorCode,filename);
   //_StackDump(0,1,1);

   /*
   if (!_SlickCDebuggingEnabled()) {
      msg := "Slick-C"VSREGISTEREDTM" error:  ";
      msg :+= get_message(errorCode);
      msg :+= "\n\n";
      if (filename != '') {
         msg :+= _maybe_quote_filename(filename);
         msg :+= "\n\n";
      }
      msg :+= get_message(SLICKC_ATTACH_DEBUGGER_RC);
      msg = stranslate(msg,VSREGISTEREDTM,"(R)");
      response := _message_box(msg, "Slick-C"VSREGISTEREDTM" Error", MB_YESNO);
      msg = get_message(errorCode);
      if (response == IDYES) {
         slickc_debug_start();
         _SlickCDebugging(SLICKC_DEBUG_SUSPEND,def_debug_slickc_port);
         return true;
      }
   }
   */
   return false;
}

void ctlsupport_button.lbutton_down()
{
   orig_wid := p_window_id;
   int stack_wid = edit1.p_window_id;
   int mark_id = _alloc_selection();
   p_window_id = stack_wid;
   typeless p; save_pos(p);
   top(); _select_line(mark_id);
   bottom(); _select_line(mark_id);
   select_all_line();
   copy_to_clipboard();
   restore_pos(p);
   support_index := find_index('do_webmail_support', PROC_TYPE|COMMAND_TYPE);
   if (index_callable(support_index)) {
      call_index(support_index);
   }
   p_window_id = orig_wid;
   message("Slick-C"VSREGISTEREDTM" Stack information has been copied to clipboard.");
   _free_selection(mark_id);
}

void ctlimage1.lbutton_down()
{
   wid := 0;
   name := wid.p_name;
}
