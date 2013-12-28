////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47272 $
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
#import "listbox.e"
#import "main.e"
#import "slickc.e"
#import "stdprocs.e"
#import "tags.e"
#import "toolbar.e"
#endregion

/* This module should be link after parseoption, .... ... */
/* function have been loaded. Also the keyboard should be functional */
/* before this module can be useful. */

_str st_batch_mode=0;    /* True if compiling batch program with -p option. */
#define ST_COMMAND '0 vstw'

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
_command st(_str module_name="") name_info(','VSARG2_REQUIRES_MDI_EDITORCTL)
{
   return(vstw(module_name,arg(2),arg(3)));

}
/**
 * This function is identical to the st command.
 * 
 * @categories Macro_Programming_Functions
 * 
 */ 
_command vstw(_str name="",...) name_info(','VSARG2_REQUIRES_MDI_EDITORCTL)
{
  _str tconvert='';
  _str st_command=ST_COMMAND;
  boolean quiet=0;

  _str qparams="";
  _str errfile='';
  if ( st_batch_mode ) {
     qparams='';
  } else {
     //_error_file=absolute(COMPILE_ERROR_FILE);
     _error_file=GetErrorFilename();//GetErrorFilename sets COMPILE_ERROR_FILE
     qparams="-q -e "maybe_quote_filename(COMPILE_ERROR_FILE)" ";
     quit_error_file();
     errfile=_error_file;
  }

  _str ch="";
  _str option="";
  _str uoption="";
  for (;;) {
     option=parse_file(name);
     if (option=='') break;
     uoption=upcase(option);
     ch=substr(uoption,1,1);
     if (ch!='-' && ch!='+') {
        name=name' 'maybe_quote_filename(option);
        break;
     }
     switch (substr(uoption,2)) {
     case 'Q':
        qparams=qparams:+option' ';
        break;
     case 'W':
        quiet=1;
        break;
     case 'F':
        option=parse_file(name);
        qparams=qparams:+' -F 'option' ';
        break;
     case 'T':
        tconvert='-t ';
        st_command=st_command:+'17';
        break;
     case 'TD':
        tconvert='-tu ';
        break;
     case 'TU':
        tconvert='-tu ';
        break;
     default:
        if (substr(uoption,2,1)=='I') {
           qparams=qparams:+maybe_quote_filename(option)' ';
           break;
        }
        _message_box('Invalid option uoption='uoption);
        return(1);
     }
  }

  typeless status=0;
  _str extension="";
  if ( name=='' ) {
    extension=_get_extension(p_buf_name);
    if ( file_eq('.'extension,_macro_ext) || file_eq(extension,'cmd') ||
       (file_eq(extension,'sh') && tconvert!='') ) {
      if ( p_modify ) {
         status=save();
         if ( status ) {
            return(status);
         }
      }
      name=maybe_quote_filename(p_buf_name);
    } else {
       prompt('',nls('Compile macro'));
    }
  }

  _str line="";
  if ( ! quiet ) { message(nls('Compiling')); }
  rc=0;
  if (_win32s()==1) {
     line=st_command " "tconvert:+qparams;
     /* Since can't pass environment to compiler, use -i switch. */
     /* -i switch might already have been specified. */
     if (!pos(' -i( |)',name,1,'r') ) {
        _str value=get_env('VSLICKINCLUDE');
        if (value!='') {
           name='-i 'value' 'name;
        }
     }
     line=line:+name;
     if (errfile!='') {
        status=delete_file(errfile);
        if (status && status!=FILE_NOT_FOUND_RC) {
           _message_box(nls("Unable to delete '%s'",errfile));
           return(status);
        }
     }
     //messageNwait('line='line);
     status=shell(line,'n');
     if (status==0 && errfile!='' && file_match('-p 'errfile,1)!='') {
        status=1;
     }
  } else {
     line=st_command" "tconvert:+qparams:+name;
     status=shell(line,'n');
  }

  if ( status==FILE_NOT_FOUND_RC ) {
     message(nls('ST program not found'));
     return(status);
  }
  if ( status<0 ) {  /* error from shelling st? */
     message(get_message(status));
     return(status);
  }
  if ( status!=0 ) {
     p_window_id=_mdi.p_child;
     status=st_position_on_error();
     /* Must return 1 since the built in make facililty needs to know */
     /* that the message has already been displayed by st_position_on_error. */
     return(1);
  } else {
    if ( ! quiet ) { message(nls('Compilation completed successfully.')); }
  }
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
  if (errfile != '') {
     _error_file=errfile;
  }
  if (_in_firstinit) {
     int index=find_index('st_position_on_error',PROC_TYPE);
     _post_call(index,_error_file);
     return(1);
  }
  // For now, Slick-C only needs to support SBCS/DBCS filenames and content
  typeless status=load_files('+d +l 'maybe_quote_filename(_error_file));
  if ( status ) {
     if (status==NEW_FILE_RC) {
        _delete_buffer();
     }
     return(1);
  }
  //status=delete_file(_error_file);
  _str msg="";
  get_line(msg);
  if ( substr(msg,1,16)=="Slick Translator" ) {
     _delete_line();
     _delete_line();
  }
  _str last_line="";
  if ( p_Noflines>0 ) {
    get_line(last_line);
    _delete_buffer();
    //parse last_line with filename ' ' line col ':' msg ;
    _str temp=last_line;
    _str filename=parse_file(temp);
    typeless line="";
    typeless col="";
    parse temp with line col':'msg;
    if ( filename=='' || ! isinteger(line) || ! isinteger(col) || msg=='' ) {
       msg=last_line;
    } else {
       // if we are building the state file and files.e or vc.e haven't 
       // yet been loaded, then just display a message box.
       if (index_callable(find_index("window_edit", PROC_TYPE)) && index_callable(find_index("edit"))) {
          status=edit(maybe_quote_filename(filename));
       } else {
          _message_box("Error compiling: "filename);
          status=STRING_NOT_FOUND_RC;
       }
       if ( ! status && line!='' && col!='' ) {
          _str name=_strip_filename(filename,'P');
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
_command void dump_slickc_stack()
{
   _StackDump();
}
void _UpdateSlickCStack(int ignoreNStackItems=0,int errorCode=0,_str DumpFileName="")
{
   if (!index_callable(find_index('tbShow',PROC_TYPE|COMMAND_TYPE)) ||
       !_hit_defmain
        ) {
      if (errorCode<0) {
         say(get_message(errorCode));
      }
      _StackDump(0,1,ignoreNStackItems+1);
      return;
   }
   int wid=_find_object('_tbslickc_stack_form');
   if (!wid) {
      tbShow('_tbslickc_stack_form');
      wid=_find_object('_tbslickc_stack_form');
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
   wid.edit1.top();wid.edit1.down();
}

defeventtab slickc_stack_keys;
def 'ENTER'=slickc_stack_goto;
def 'LBUTTON-DOUBLE-CLICK'=slickc_stack_goto;

_command void slickc_stack_goto() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI|VSARG2_EDITORCTL)
{
   if ( command_state() || p_window_state:=='I' ) {
      try_calling(eventtab_index(_default_keys,
                          _default_keys,event2index(ENTER)));
      return;
   }
   int edit1_view_id=0;
   get_window_id(edit1_view_id);
   int edit1_buf_id=p_buf_id;
   _str line="";
   get_line(line);
   if (line=="" || substr(line,1,1)=="") {
      _beep();
      return;
   }
   _str found="";
   typeless status=0;
   _str filename="";
   typeless offset="";
   typeless proc_name="";
   parse line with filename offset proc_name'(';
   _str ext=_get_extension(filename,1);
   if (file_eq(ext,DLLEXT)) {
      // This is a dll entry
      status=find_tag('-e c 'proc_name);
      if (status) {
         return;
      }
   } else {
      filename=_strip_filename(filename,'E');
      filename=filename:+_macro_ext;
      found=slick_path_search(filename);
      if (found=="") {
         // TBF:  we need a better technique for mapping module names to load paths
         found=file_match("+T "maybe_quote_filename(get_env("VSROOT"):+FILESEP:+"macros":+FILESEP:+filename),1);
         if (found=="") {
            _message_box(nls("File %s not found",filename));
            return;
         }
      }
      filename=found;
      status=edit(maybe_quote_filename(filename));
      if (status) {
         return;
      }
      status=st('-f 'offset);
      /*if (status) {
         return;
      } */
   }
   int view_id=0;
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
#define SLICKC_STACK_BUFNAME ".slickc_stack"
#define EditWindowBufferID edit1.p_user
defeventtab _tbslickc_stack_form;
void edit1.on_create()
{
   EditWindowBufferID=p_buf_id;
   int status=load_files("+q +b "SLICKC_STACK_BUFNAME);
   if (status) {
      // Since most strings are UTF-8, use UTF-8 encoding for buffer
      load_files("+futf8 +q +t");
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
   if (EditWindowBufferID!=p_buf_id) {
      /*if (p_buf_flags&VSBUFFLAG_HIDDEN) {
         if (!_DialogViewingBuffer(p_buf_id,p_window_id)) {
            call_list('_cbquit_');
            _delete_buffer();
         }
      } */
      load_files('+q +m +bi 'EditWindowBufferID);
   }
}
void _tbslickc_stack_form.on_resize()
{
   int formWid=p_active_form;
   int edit1_wid=edit1;
   edit1_wid.p_x = 0;
   edit1_wid.p_y = 0;
   edit1.p_width = _dx2lx(SM_TWIP,p_active_form.p_client_width) - edit1.p_x - ctlframe.p_width;
   edit1.p_height = _dy2ly(SM_TWIP,p_active_form.p_client_height) - edit1.p_y*2;
   ctlframe.p_x = edit1_wid.p_x + edit1_wid.p_width;
   ctlframe.p_y = 0;
}
boolean _on_slickc_error(int errorCode,_str filename)
{
   _UpdateSlickCStack(1,errorCode,filename);
   //_StackDump(0,1,1);

   /*
   if (!_SlickCDebuggingEnabled()) {
      msg := "Slick-C"VSREGISTEREDTM" error:  ";
      msg :+= get_message(errorCode);
      msg :+= "\n\n";
      if (filename != '') {
         msg :+= maybe_quote_filename(filename);
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
void ctlxbutton.lbutton_up()
{
   tbClose(p_parent);
}

void ctlsupport_button.lbutton_down()
{
   int orig_wid = p_window_id;
   int stack_wid = edit1.p_window_id;
   int mark_id = _alloc_selection();
   p_window_id = stack_wid;
   typeless p; save_pos(p);
   top(); _select_line(mark_id);
   bottom(); _select_line(mark_id);
   select_all();
   copy_to_clipboard();
   restore_pos(p);
   int support_index = find_index('do_webmail_support', PROC_TYPE|COMMAND_TYPE);
   if (index_callable(support_index)) {
      call_index(support_index);
   }
   p_window_id = orig_wid;
   message("Slick-C"VSREGISTEREDTM" Stack information has been copied to clipboard.");
   _free_selection(mark_id);
}

void ctlimage1.lbutton_down()
{
   int wid = 0;
   _str name = wid.p_name;
}
