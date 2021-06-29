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
#import "ini.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "recmacro.e"
#import "stdprocs.e"
#import "cfg.e"
#import "autocomplete.e"
#endregion

static typeless gcount;
static typeless gincrement;
static typeless gformat;
static typeless gdigitwidth;
static typeless gleading;
static typeless gtrailing;
static typeless gprefix;
static typeless gsuffix;
static bool gpadleft;
static _str gpadchar;

static _str enumerate_filter(_str s)
{
   // IF HEX FORMAT
   value := "";
   if (gformat==1) {
      value=dec2hex(gcount);
      value=substr(value,3);// Remove leading 0x
   } else if (gformat==2) {  // IF HEX and increment by bits
      if (gcount<0) gcount=0;
      value=dec2hex(1<<gcount);
      value=substr(value,3);// Remove leading 0x
   } else {
      value=gcount;
   }
   if (gdigitwidth) {
      if (gformat) {
         if (length(value)<gdigitwidth) {
            if (gpadleft) {
               value=substr("",1,gdigitwidth-length(value),gpadchar):+value;
            } else {
               value=value:+substr("",1,gdigitwidth-length(value),gpadchar);
            }
         }
      } else {
         if (length(value)<gdigitwidth) {
            if (gpadleft) {
               value=substr("",1,gdigitwidth-length(value),gpadchar):+value;
            } else {
               value=value:+substr("",1,gdigitwidth-length(value),gpadchar);
            }
         }
      }
   }
   value=gprefix:+gleading:+value:+gtrailing:+gsuffix;
   if (_select_type()=="LINE") {
      if (s!="") {
         gcount+=gincrement;
         //return(s" "value);
         return(value" "s);
      }
      gcount+=gincrement;
      return(value);
   }
   gcount+=gincrement;
   if (_select_type()=="BLOCK") {
      start_col := 0;
      end_col := 0;
      typeless junk;
      _get_selinfo(start_col,end_col,junk);
      int width=end_col-start_col+_select_type('','I');
      if (length(value)<width) {
         value=substr("",1,width-length(value)):+value;
      }
   }
   /*if (gprefix:!="") {
      value = strip(gprefix,'B','"'):+value;
   }
   if (gsuffix:!="") {
      value = value:+strip(gsuffix,'B','"');
   } */
   return value;
}
/**
 *    This commands adds incrementing numbers to a selection.  
 * 
 * 
 * @param cmdline is a  string in the format: 
 * <pre>
 *    [-x | -xf] [-l <i>leading</i>] [-t <i>trailing</i>] [-pc <i>padchar</i>] [-pr] 
 *    [<i>start</i> [ <i>increment </i>[ <i>DigitWidth</i> ]]]
 * </pre>
 * <DL compact style="margin-left:20pt;">
 *    <DT>-x </DT><DD>Specifies hexadecimal output.  If -l and -t options are not specified,
 * the buffers extension specific syntax for hex numbers is used.  If not hex 
 * syntax has been defined in the buffers color coding, "0x" is used for leading 
 * text.</DD>
 *    <DT>-xf</DT><DD>Specifies hexadecimal output.  If -l and -t options are not 
 * specified, the buffers extension specific syntax for hex numbers is used.  If 
 * not hex syntax has been defined in the buffers color coding, "0x" is used for 
 * leading text.  NOTE: the meaning of <i>start</i> and <i>increment</i> change 
 * when this option is specified (see below).</DD>
 *    <DT>-l <i>leading</i></DT><DD>Specifies text to prefix each number with.</DD>
 *    <DT>-t <i>trailing</i></DT><DD>Specifies text to append to each number.</DD>
 *    <DT>-pr</DT><DD> Specifies padding on the right. Defaults to pad left.</DD>
 *    <DT>-pc <i>padchar</i></DT><DD>Specifies pad character.</DD>
 *    </DL>
 * @see gui_enumerate
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void enumerate(_str cmdline='',_str prefix=null, _str suffix=null, _str padchar='0') name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if ( ! select_active2() ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return;
   }
   if (_select_type()=="CHAR" && !_MultiCursorAlreadyLooping() ) {
#if __VERSION__>=2.0
      _select_type("","L","LINE");
#else
      _select_type("","T","LINE");
#endif
   }
   option := "";
   rest := "";
   gformat=0;
   gleading=gtrailing="";
   gprefix=prefix;
   gsuffix=suffix;
   gpadleft=true;
   gpadchar=padchar;
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
outerloop:
      for (;;) {
         parse cmdline with option rest;
         if (substr(option,1,1)!="-") break;
         switch(upcase(option)){
         case "-X":
            gformat=1;   // Hex output
            cmdline=rest;
            break;
         case "-XF":
            gformat=2;   // Hex and increment by bits.
            cmdline=rest;
            break;
         case "-PR":
            gpadleft=false; // Pad right
            cmdline=rest;
            break;
         case "-L":
            cmdline=rest;
            parse cmdline with gleading rest;
            break;
         case "-T":
            cmdline=rest;
            parse cmdline with gleading rest;
            break;
         case "-PC":
            cmdline=rest;
            gpadchar= parse_file(cmdline,false);
            break;
         case "-P":
            cmdline=rest;
            gprefix = parse_file(cmdline,false);
            break;
         case "-S":
            cmdline=rest;
            gsuffix = parse_file(cmdline,false);
            break;
         default:
            // Could have -number
            if (isnumber(option)) {
               cmdline=option" "rest;
               break outerloop;
            }
            message(get_message(INVALID_ARGUMENT_RC));
            return;
         }
      }
      if (gformat) {
         if (gleading=="" && gtrailing=="") {
            first_col := 0;
            last_col := 0;
            buf_id := 0;
            _get_selinfo(first_col,last_col,buf_id);
            int old=p_buf_id;
            p_buf_id=buf_id;
            _str lexer_name=p_lexer_name;
            p_buf_id=old;
            if (lexer_name!="") {
               styles:=_plugin_get_property(VSCFGPACKAGE_COLORCODING_PROFILES,lexer_name,'styles');
               if (pos("xhex",styles,1,"i")) {
                  if (gprefix!=null && gsuffix!=null) {
                     gleading="0x";
                  }
               } else if (pos("amphhex",styles,1,"i")) {
                  if (gprefix!=null && gsuffix!=null) {
                     gleading="&H";
                  }
               } else if (pos("hexh",styles,1,"i")) {
                  if (gprefix!=null && gsuffix!=null) {
                     gtrailing="H";
                  }
               } else if (pos("dollarhex",styles,1,"i")) {
                  if (gprefix!=null && gsuffix!=null) {
                     gleading="$";
                  }
               }
            }
            // IF caller didn't specify a specific prefix or suffix and we couldn't 
            //    figure out the hexadecimal format for this language.
            if (gprefix==null && gsuffix==null && gleading=='' && gtrailing=='') {
               gleading="0x";
            }
         }
      }

      typeless start, increment;
      parse cmdline with start increment gdigitwidth;
      if (gdigitwidth=="") gdigitwidth=0;
      gincrement=1;
      if (increment!="") {
         gincrement=increment;
      }
      gcount=0;

      if (start!="") {
         //IF output is hex.
         if (gformat==2) {
            if (isinteger(start)) {
               gcount=start;
               if (gcount>0) --gcount;
            }else {
               start=hex2dec(start);
               if (start=="") {
                  message(get_message(INVALID_ARGUMENT_RC));
                  return;
               }
               if (start>0) {
                  gcount=0;
                  while (start) {
                     start=start>>1;
                     ++gcount;
                  }
                  if (gcount>0) --gcount;
               }
            }
         } else {
            gcount=start;
         }
      }
      // IF output is hex and start or increment is floaging point
      if (gformat && (!isinteger(gincrement) || !isinteger(gcount)) ) {
         message(get_message(INVALID_ARGUMENT_RC));
         return;
      }
      if (!isnumber(gcount) || !isnumber(gincrement) ||
          !isinteger(gdigitwidth)) {
         message(get_message(INVALID_ARGUMENT_RC));
         return;
      }
   }
   if (gdigitwidth>0) {
      if (_UTF8CountChars(gpadchar)>1) {
         message("Pad character must be one character");
         return;
      }
      if (length(gpadchar)>1) {
         message("Pad character is limited to ascii characters below code point 128");
         return;
      }
   }
   if (gprefix==null) gprefix='';
   if (gsuffix==null) gsuffix='';
   upcase_selection('',enumerate_filter);

}
/**
 * Adds incrementing numbers to a selection.  Displays <b>Enumerate dialog 
 * box</b>.
 * 
 * @see enumerate
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories File_Functions
 * 
 */
_command void gui_enumerate() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   _macro_delete_line();
   if (_select_type()=="") {
      _message_box(get_message(TEXT_NOT_SELECTED_RC));
      return;
   }
   show("-modal _enum_form");
}

defeventtab _enum_form;
static void _enable_padding() {
   typeless digwidth='';
   status:=eval_exp(digwidth,ctldigitwidth.p_text,10);
   bool enabled=(!status && digwidth>0);
   ctlpadchar.p_enabled=ctlpadleft.p_enabled=ctlpadright.p_enabled=enabled;
}
void ctlok.on_create()
{
   _retrieve_prev_form();
   _enable_padding();
}
void ctldigitwidth.on_change() {
   _enable_padding();
}
void ctlok.lbutton_up()
{
   typeless start='';
   typeless status=0;
   if (ctlflags.p_value) {
      start=ctlstart.p_text;
      if (!isinteger(ctlstart.p_text)) {
         typeless result=hex2dec(ctlstart.p_text);
         if (result=="" || result<0) {
            _message_box(get_message(INVALID_ARGUMENT_RC));
            ctlstart.set_command(ctlstart.p_text,1,length(ctlstart.p_text)+1);
            ctlstart._set_focus();
            return;
         }
      }
   } else {
      status=eval_exp(start,ctlstart.p_text,10);
      if (status) {
         _message_box("Invalid expression");
         ctlstart.set_command(ctlstart.p_text,1,length(ctlstart.p_text)+1);
         ctlstart._set_focus();
         return;
      }
   }

   typeless increment='';
   status=eval_exp(increment,ctlincrement.p_text,10);
   if (status) {
      _message_box("Invalid expression");
      ctlincrement.set_command(ctlincrement.p_text,1,length(ctlincrement.p_text)+1);
      ctlincrement._set_focus();
      return;
   }

   typeless digwidth='';
   status=eval_exp(digwidth,ctldigitwidth.p_text,10);
   if (status || digwidth<0) {
      _message_box("Must be positive integer expression");
      ctldigitwidth.set_command(ctldigitwidth.p_text,1,length(ctldigitwidth.p_text)+1);
      ctldigitwidth._set_focus();
      return;
   }

   options := "";
   if (ctldec.p_value) {
      options="";
   } else if (ctlhex.p_value) {
      options="-x ";
   }  else if (ctlflags.p_value) {
      options="-xf ";
   }
   padchar:=ctlpadchar.p_text;
   if (length(padchar)==0) {
      padchar=' ';
   }
   if (digwidth>0) {
      if (ctlpadright.p_value) {
         options=options:+"-pr ";
      }
      if (_UTF8CountChars(padchar)>1) {
         _message_box("Pad character must be one character");
         ctlpadchar.set_command(ctlpadchar.p_text,1,length(ctlpadchar.p_text)+1);
         ctlpadchar._set_focus();
         return;
      }
      if (length(padchar)>1) {
         _message_box("Pad character is limited to ascii characters below code point 128");
         ctlpadchar.set_command(ctlpadchar.p_text,1,length(ctlpadchar.p_text)+1);
         ctlpadchar._set_focus();
         return;
      }
   }
   if (length(padchar)>1) {
      padchar=' ';
   }
   _str prefix= null;
   if (ctlprefix.p_text :!= "") {
      prefix = ctlprefix.p_text;
   }
   _str suffix = null;
   if (ctlsuffix.p_text :!= "") {
      suffix = ctlsuffix.p_text;
   }

   //messageNwait("ctlok.lbutton_up: options="options);
   _macro("m",_macro("s"));
   cmdline := options" "start" "increment" "digwidth;
   _save_form_response();   
   _macro_call("enumerate",cmdline,prefix,suffix,padchar);

   int child_wid=_form_parent();
   if (!_MultiCursorAlreadyLooping()) {
      child_wid._MultiCursorCallFuncName(cmdline,prefix,suffix,padchar,'enumerate');
      p_active_form._delete_window(0);
      return;
   }

   child_wid.enumerate(cmdline,prefix,suffix,padchar);
   //_param1=ctlstart.p_text;
   //_param2=ctlincrement.p_text;
   //_param3=ctldigitwidth.p_text;
   p_active_form._delete_window(0);
}

