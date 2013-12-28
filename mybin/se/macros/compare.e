////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49273 $
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
#import "bind.e"
#import "diff.e"
#import "files.e"
#import "guiopen.e"
#import "help.e"
#import "hex.e"
#import "main.e"
#import "moveedge.e"
#import "recmacro.e"
#import "stdprocs.e"
#import "window.e"
#endregion
/*

  Compares two buffers in two windows starting from the cursor position
  in each window.  Requires that there be exactly two windows on the screen.

 Possible enhancement in the future would be to handle command line options.

    OPTIONS
      + or -A     Perform line by line ASCII compare
      + or -B     Perform byte by byte binary compare
      + or -C     Start each compare in column 1.  ASCII only.
      + or -E     Expand tabs before comparing lines. ASCII only.
      + or -L     Ignore leading spaces.  ASCII only.
      + or -T     Ignore trailing spaces.  ASCII only.
      + or -S     Ignore all spaces.  ASCII only.
      + or -I     Ignore case.  ASCII only.
*/

_str def_compare="0 0 0 0 0 0";  /* default compare options. */
int def_aresync_len=40;
int def_bresync_len=30;

#define MAX_VAR_LEN  255
#define BINARY_RESYNC_LOOK_AHEAD 4000
#define ASCII_RESYNC_LOOK_AHEAD 4000

static _str
   current_options;        /* Compare options used with last buffers compared. */
   /* Nofmismatches        /* Number of mismatches. */ */

definit()
{
   current_options=def_compare;
}
defload()
{
   /* Bind COMPARE command to F6 key if it is not bound to command. */
   int key_index=event2index(name2event('f6'));
   if ( ! eventtab_index(_default_keys,_default_keys,key_index) ) {
      set_eventtab_index(_default_keys,key_index,
                         find_index('compare',COMMAND_TYPE));
   }
   /* Bind RESYNC command to Ctrl+F6 if it is not bound to command. */
   key_index=event2index(name2event('c-f6'));
   if ( ! eventtab_index(_default_keys,_default_keys,key_index) ) {
      set_eventtab_index(_default_keys,key_index,
                         find_index('resync',COMMAND_TYPE));
   }
}
static _str set_compare_options(var view_id2)
{
   if ( get_other_window_view_id(view_id2) ) {
      return(1);
   }
   if ( current_options!='' ) {
      return(0);
   }
   current_options=def_compare;
   /* Nofmismatches=0 */
   return(0);

}
/**
 * Attempts to adjust the cursor position in two windows starting from 
 * the current cursor position of each window to the next reasonable 
 * match of buffer text.  Requires that there be exactly two windows on 
 * the screen.  Used after the <b>compare</b> command detects a 
 * mismatch.
 * 
 * @see compare
 * @see compare_options
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Buffer_Functions
 * 
 */ 
_command resync() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   typeless view_id2=0;
   if ( set_compare_options(view_id2) ) { return(1); }
   typeless start_at_col1=0;
   typeless bin='';
   typeless expand_tabs_b4='';
   typeless ignore_trailing_spaces='';
   typeless ignore_leading_spaces='';
   typeless ignore_all_spaces='';
   typeless ignore_case='';
   typeless status=0;
   parse current_options with bin expand_tabs_b4 ignore_leading_spaces ignore_trailing_spaces ignore_all_spaces ignore_case ;
   if ( bin ) {
      status=binary_resync(view_id2);
   } else {
      if ( ignore_all_spaces ) {
         message('Resyncing...');
      }
      status=ascii_resync(view_id2,start_at_col1,expand_tabs_b4,
                ignore_leading_spaces,ignore_trailing_spaces,
                ignore_all_spaces, ignore_case);
   }
   if ( status ) {
      message(nls('Resync failed'));
      return(1);
   }
   message(nls('Resync successful'));
   return(0);

}
static _str ascii_resync(int view_id2,
                         int start_at_col1,
                         boolean expand_tabs_b4,
                         boolean ignore_leading_spaces,
                         boolean ignore_trailing_spaces,
                         boolean ignore_all_spaces, 
                         boolean ignore_case)
{
   int view_id1=0;
   get_window_id(view_id1);
   typeless status=0;
   status=ascii_resync2(view_id2,ignore_leading_spaces,
                             ignore_trailing_spaces,ignore_all_spaces,
                             expand_tabs_b4,ignore_case);
   if ( ! status ) {
      activate_window(view_id1);
      return(0);
   }
   activate_window(view_id2);
   /* messageNwait('resync2') */
   status=ascii_resync2(view_id1,ignore_leading_spaces,
                             ignore_trailing_spaces,ignore_all_spaces,
                             expand_tabs_b4,ignore_case);
   if ( ! status ) {
      activate_window(view_id1);
      return(0);
   }
   return(1);

}
static _str ascii_resync2(int view_id2,
                          boolean ignore_leading_spaces,
                          boolean ignore_trailing_spaces,
                          boolean ignore_all_spaces,
                          boolean expand_tabs_b4,
                          boolean ignore_case)
{
   _str strip_option='';
   if ( ignore_leading_spaces && ignore_trailing_spaces ) {
      strip_option='B';
   } else if ( ignore_leading_spaces ) {
      strip_option='L';
   } else if ( ignore_trailing_spaces ) {
      strip_option='T';
   } else {
      strip_option='';
   }
   int view_id1=0;
   get_window_id(view_id1);
   typeless p1=point();
   int col1=p_col;
   int left_edge1=p_left_edge;
   int cursor_y1=p_cursor_y;
   down();_begin_line();
   if ( rc ) return(1);
   _str line1='';
   get_line_raw(line1);
   if ( expand_tabs_b4 ) line1=expand_tabs(line1);
   if ( ignore_all_spaces ) {
      line1=stranslate(line1,'',' ');
   } else if ( strip_option:!='' ) {
      line1=strip(line1,strip_option,' ');
   }
   if ( ignore_case ) {
      line1=upcase(line1,p_UTF8);
   }
   int start_col=1;
   activate_window(view_id2);
   typeless p2=point();
   int col2=p_col;
   int left_edge2=p_left_edge;
   int cursor_y2=p_cursor_y;
   _str line2='';
   get_line_raw(line2);
   int Noflines=1;
   for (;;) {
      if ( expand_tabs_b4 ) line2=expand_tabs(line2);
      if ( ignore_all_spaces ) {
         line2=stranslate(line2,'',' ');
      } else if ( strip_option:!='' ) {
         line2=strip(line2,strip_option,' ');
      }
      if ( ignore_case ) {
         line2=upcase(line2,p_UTF8);
      }
      if ( line1:==line2 ) {
         _begin_line();
         return(0);
      }
      down();
      Noflines=Noflines+1;
      if ( rc || Noflines>def_aresync_len ) {
         activate_window(view_id1);
         goto_point(p1);p_col=col1;set_scroll_pos(left_edge1,cursor_y1);
         activate_window(view_id2);
         goto_point(p2);p_col=col2;set_scroll_pos(left_edge2,cursor_y2);
         return(1);
      }
      get_line_raw(line2);
   }

}
static _str binary_resync(int view_id2)
{
   int view_id1=0;
   get_window_id(view_id1);
   typeless p1=point();
   int col1=p_col;
   int left_edge1=p_left_edge;
   int cursor_y1=p_cursor_y;
   _str match_text=get_text_raw(def_bresync_len);
   activate_window(view_id2);
   typeless p2=point();
   int col2=p_col;
   int left_edge2=p_left_edge;
   int cursor_y2=p_cursor_y;
   typeless status=binary_resync2(view_id2,match_text,BINARY_RESYNC_LOOK_AHEAD,def_bresync_len);
   if ( ! status ) {
      activate_window(view_id1);
      return(0);
   }
   goto_point(p2);p_col=col2;set_scroll_pos(left_edge2,cursor_y2);
   match_text=get_text_raw(def_bresync_len);
   status=binary_resync2(view_id1,match_text,BINARY_RESYNC_LOOK_AHEAD,def_bresync_len);
   if ( ! status ) {
      activate_window(view_id1);
      return(0);
   }
   goto_point(p1);p_col=col1;set_scroll_pos(left_edge1,cursor_y1);
   return(1);

}
static _str binary_resync2(int view_id2,
                           _str match_text,
                           int resync_look_ahead,
                           int resync_match_len)
{
   activate_window(view_id2);
   _str text2='';
   _str line='';
   get_line_raw(line);
   typeless p2=(int)point()+text_col(line,p_col,'p')-1;
   typeless end_p2=p2+resync_look_ahead;
   for (;;) {
      text2=get_text_raw(MAX_VAR_LEN);
      int i=pos(match_text,text2,1);
      if ( i ) {
         p2=p2+i-1;
         goto_point(p2);
         return(0);
      }
      int len=length(text2)-resync_match_len;
      if ( len<=0 ) {
         return(1);
      }
      p2=p2+len;
      if ( p2>resync_look_ahead ) {
         return(1);
      }
      goto_point(p2);
      if ( rc ) {
         /* past last byte of buffer. */
         return(1);
      }
   }

}
static boolean get_other_window_view_id2(int &linenum2,int &Noflines2,int &bufid2)
{
   int w2_view_id;
   if (p_window_state=='M' || _no_child_windows()) {
      return(1);
   }
   int wid2=0;
   int tile_id=p_tile_id;
   int first_window_id=p_window_id;
   w2_view_id=0;
   for (;;) {
      _next_window('HF');
      if ( p_window_id==first_window_id ) {
         break;
      }
      if ( p_tile_id==tile_id && !(p_window_flags &HIDE_WINDOW_OVERLAP)) {
         if ( w2_view_id ) {
            w2_view_id=0;
            break;
         }
         get_window_id(w2_view_id);
         wid2=p_window_id;
         linenum2=p_RLine;
         Noflines2=p_RNoflines;
         bufid2=p_buf_id;
      }
   }
   if ( !w2_view_id) {
      return(1);
   }
   if (wid2.p_window_state=='I') {
      wid2.p_window_state='N';
   }
   if (p_window_state=='I') {
      p_window_state='N';
   }
   return(0);
}
_command void diff_from_cursor() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   int bufid1=p_buf_id;
   //bufid1=p_buf_name;
   int linenum1=p_RLine;
   int Noflines1=p_RNoflines;
   int linenum2=0;
   int Noflines2=0;
   int bufid2=0;
   if ( get_other_window_view_id2(linenum2,Noflines2,bufid2) ) {
      diff();
      return;
   }
   if (bufid1==bufid2) {
      if (linenum1<linenum2) {
         Noflines1=linenum2-1;
      } else {
         Noflines2=linenum1-1;
      }
   }
   _DiffModal('-range1:'linenum1','Noflines1' -range2:'linenum2','Noflines2' -bi1 -bi2 'bufid1' 'bufid2);
}

/**
 * Compares two buffers in two tiled windows starting from the current cursor 
 * position of each window.  If the current window is not one of two tiled windows, 
 * you will be prompted for the files/buffers you want to compare and two tiled 
 * windows will be set up for you.
 * <pre>
 * You can perform the following steps to manually set up two tiled windows before invoking the <b>compare</b> command:
 *    -- Open (Ctrl+O) both files you wish to compare
 *    -- Make current one of the files you wish to compare current.
 *    -- Zoom the current window by clicking on the Maximize button.
 *    -- Use the <b>hsplit_window</b> command (Ctrl+H or "Window", "Hsplit") to create two tiled windows.
 *    -- Use the <b>link_window</b> command ("Window", "Link Window") and to display the other buffer in the newly created window.
 * 
 * After a compare mismatch, you can use the <b>resync</b> command to adjust the 
 * cursor in both windows to the next reasonable match.  This command will be 
 * improved in the future to handle more sophisticated mismatches.
 * 
 * Use the <b>compare_options</b> command displays the <b>Compare Options 
 * dialog box</b> to set various compare options.
 * 
 * In ISPF emulation, this command is not called when invoked from the command 
 * line.  Instead <b>ispf_compare</b> is called.  At the moment, you can't 
 * access the <b>compare</b> command when in ISPF emulation unless you bind 
 * it to a key.
 * </pre>
 * 
 * @see  compare_options
 * @see resync
 * @see ispf_compare
 * @see diff
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Buffer_Functions, File_Functions
 */
_command int compare() name_info(','VSARG2_REQUIRES_MDI)
{
   _macro_delete_line();
   _macro_call('compare');
   int view_id2=0;
   if ( set_compare_options(view_id2) ) { return(1); }
   typeless start_at_col1=0;
   typeless bin='';
   typeless expand_tabs_b4='';
   typeless ignore_trailing_spaces='';
   typeless ignore_leading_spaces='';
   typeless ignore_all_spaces='';
   typeless ignore_case='';
   typeless status=0;
   parse current_options with bin expand_tabs_b4 ignore_leading_spaces ignore_trailing_spaces ignore_all_spaces ignore_case ;
   if ( bin || p_hex_mode) {
      status=binary_compare(view_id2);
   } else {
      status=ascii_compare(view_id2,start_at_col1,expand_tabs_b4,
                ignore_leading_spaces,ignore_trailing_spaces,
                ignore_all_spaces, ignore_case);

   }
   if ( status==1 ) {
      temporary_select_char();
   }
   return(status);

}

defeventtab _compare_form;

_ok.on_create(typeless bin='',
              typeless expand='',
              typeless leading='',
              typeless trailing='',
              typeless all='',
              typeless case_arg='')
{
   _bin.p_value      = bin;
   _expand.p_value   = expand;
   _leading.p_value  = leading;
   _trailing.p_value = trailing;
   _all.p_value      = all;
   _case.p_value     = case_arg;

   if (_bin.p_value) {
      _expand.p_enabled = _leading.p_enabled = _trailing.p_enabled = _all.p_enabled = _case.p_enabled = 0;
   }
}

_ok.lbutton_up()
{
   _str ret_val = _bin.p_value' '(_expand.p_value && _expand.p_enabled)' '(_leading.p_value && _leading.p_enabled)' '(_trailing.p_value && _trailing.p_enabled)' '(_all.p_value && _all.p_enabled)' '(_case.p_value && _case.p_enabled);
   _save_form_response();
   p_active_form._delete_window(ret_val);
}

_save_settings.lbutton_up()
{
   def_compare = _bin.p_value' '(_expand.p_value && _expand.p_enabled)' '(_leading.p_value && _leading.p_enabled)' '(_trailing.p_value && _trailing.p_enabled)' '(_all.p_value && _all.p_enabled)' '(_case.p_value && _case.p_enabled);
   _config_modify_flags(CFGMODIFY_DEFVAR);
   _macro('m',_macro('s'));
   _macro_append("def_compare="def_compare";");
   save_config();
}

_bin.lbutton_up()
{
   _expand.p_enabled = _leading.p_enabled = _trailing.p_enabled =
   _all.p_enabled = _case.p_enabled = !p_value;
}


/** 
 * Displays <b>Compare Options dialog box</b> which allows you to modify various 
 * options for the <b>compare</b> command.
 * <pre>
 *    <b>Binary Compare</b>
 *    When on, a stream oriented compare is performed instead of  an ASCII line by line compare.  In this mode, all other compare options are ignored.
 * 
 *    <b>Expand tabs Before Compare</b>
 *    When checked, tabs and spaces are considered equivalent.  This allows you to compare source files where one is indented with tabs and the other is indented with spaces.
 * 
 *    <b>Ignore Leading Spaces</b>
 *    When checked, leading spaces are ignored.
 * 
 *    <b>Ignore Trailing Spaces</b>
 *    When checked, trailing spaces are ignored.
 * 
 *    <b>Ignore All Spaces</b>
 *    When checked, all differences in spaces are ignored.
 * 
 *    <b>Ignore Case</b>
 *    When checked, a case insensitive compare is performed.
 * 
 *    <b>Save Settings</b>
 *    Saves your compare options for your next edit session.
 * </pre>
 * 
 * @return  Returns 0 if successful.  Otherwise, COMMAND_CANCELLED_RC is returned.
 * 
 * @see compare
 * @see resync
 * 
 * 
 * @categories Buffer_Functions
 */
_command compare_options(_str options='') name_info(','VSARG2_REQUIRES_MDI)
{
   if (options!='') {
      current_options=options;
      return(0);
   }
   _macro_delete_line();
/* if set_compare_options(view_id2) then return(1) endif */
   typeless start_at_col1=0;
   typeless bin='';
   typeless expand_tabs_b4='';
   typeless ignore_trailing_spaces='';
   typeless ignore_leading_spaces='';
   typeless ignore_all_spaces='';
   typeless ignore_case='';
   typeless status=0;
   parse current_options with bin expand_tabs_b4 ignore_leading_spaces ignore_trailing_spaces ignore_all_spaces ignore_case ;
   if (bin == '') {
      bin = 0;
   }
   if (expand_tabs_b4=='') {
      expand_tabs_b4 = 0;
   }
   if (ignore_case == '') {
      ignore_case = 0;
   }
   if (ignore_leading_spaces == '') {
      ignore_leading_spaces = 0;
   }
   if (ignore_trailing_spaces == '') {
      ignore_trailing_spaces = 0;
   }
   if (ignore_all_spaces == '') {
      ignore_all_spaces = 0;
   }
   if ( prompt_compare_options(bin,
                   expand_tabs_b4,
                   ignore_leading_spaces,
                   ignore_trailing_spaces,
                   ignore_all_spaces,
                   ignore_case) ) {
      return(COMMAND_CANCELLED_RC);
   }
   current_options= bin " "expand_tabs_b4 " "ignore_leading_spaces " "ignore_trailing_spaces " "ignore_all_spaces " "ignore_case;
   _macro('m',_macro('s'));
   _macro_append('// binary expand_tabs ignore_leading ignore_trailing ignore_all ignore_case');
   _macro_call('compare_options',current_options);
   return(0);
}

static _str prompt_compare_options(var bin,
                   var expand_tabs_b4,
                   var ignore_leading_spaces,
                   var ignore_trailing_spaces,
                   var ignore_all_spaces,
                   var ignore_case
                   )
{
   typeless result = show('-modal _compare_form',
                 bin,
                 expand_tabs_b4,
                 ignore_leading_spaces,
                 ignore_trailing_spaces,
                 ignore_all_spaces,
                 ignore_case);
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   //p_modify=0;
   parse result with bin expand_tabs_b4 ignore_leading_spaces ignore_trailing_spaces ignore_all_spaces ignore_case;
   return(0);
}

static _str binary_compare(int view_id2)
{
  int view_id1=0;
  get_window_id(view_id1);
  _str line='';
  get_line_raw(line);
  typeless p1=(int)point()+text_col(line,p_col,'p')-1;
  activate_window(view_id2);
  get_line_raw(line);
  typeless p2=(int)point()+text_col(line,p_col,'p')-1;
  activate_window(view_id1);
  _str text1='';
  _str text2='';
  int i=0;
  int j=0;
  int middle=0;
  int len=0;
  int status=0;
  for (;;) {
     text1=get_text_raw(MAX_VAR_LEN);
     activate_window(view_id2);
     text2=get_text_raw(MAX_VAR_LEN);
     if ( text1:!=text2 ) {
        message(nls("Characters at cursor don't match"));
        /* find mismatch */
        if ( length(text1)>length(text2) ) {
           bottom();
           activate_window(view_id1);
           goto_point(p1+length(text2));
           return(1);
        } else if ( length(text2)>length(text1) ) {
           goto_point(p2+length(text1));
           activate_window(view_id1);
           bottom();
           return(1);
        }
        /* bin search for mismatch because it is faster. */
        i=1;j=length(text1);
        for (;;) {
           middle=(i+j) intdiv 2;
           len=middle-i+1;
           if ( substr(text1,i,len):!=substr(text2,i,len) ) {
              j=middle;
           } else {
              i=middle+1;
           }
           if ( i==j ) {
              break;
           }
        }
        i=i-1;
        goto_point(p2+i);
        activate_window(view_id1);
        goto_point(p1+i);
        return(1);
     }
     len=length(text1);
     p2=p2+len;
     goto_point(p2);
     if ( rc ) {
        /* past last byte of buffer. */
        bottom();
        activate_window(view_id1);
        status=goto_point(p1+len);
        clear_message();
        if ( status ) {
           bottom();
           message(nls("Files match"));
           return(0);
        }
        message(nls("File sizes don't match"));
        return(2);
     }
     activate_window(view_id1);
     p1=p1+len;
     goto_point(p1);
     if ( rc ) {
        clear_message();
        bottom();
        message(nls("File sizes don't match"));
        return(2);
     }
  }

}
static _str ascii_compare(int view_id2,
                          int start_at_col1,
                          boolean expand_tabs_b4,
                          boolean ignore_leading_spaces,
                          boolean ignore_trailing_spaces,
                          boolean ignore_all_spaces, 
                          boolean ignore_case)
{
   int view_id1=0;
   get_window_id(view_id1);

   _str line='';
   get_line_raw(line);
   if ( expand_tabs_b4 ) { line=expand_tabs(line); }
   int start_col=p_col;
   if ( expand_tabs(line,1,start_col-1,'S')!='' || ! ignore_leading_spaces ) {
      line=expand_tabs(line,start_col,-1,'S');
   } else {
      line=strip(line,'L',' ');
   }
   activate_window(view_id2);
   _str line2='';
   get_line_raw(line2);
   if ( expand_tabs_b4 ) { line2=expand_tabs(line2); }
   int start_col2=p_col;
   if ( expand_tabs(line2,1,start_col2-1,'S')!='' || ! ignore_leading_spaces ) {
      line2=expand_tabs(line2,start_col2,-1,'S');
   } else {
      line2=strip(line2,'L',' ');
   }
   int i1=0;
   int i2=0;
   int line_len=0;
   int line_len2=0;
   for (;;) {
      if ( ignore_trailing_spaces ) {
         line=strip(line,'T',' ');
         line2=strip(line2,'T',' ');
      }
      if ( ignore_case ) {
         line=upcase(line,p_UTF8);
         line2=upcase(line2,p_UTF8);
      }
      for (;;) {
         if ( line:!=line2 ) {
            if ( ignore_all_spaces ) {
               line=stranslate(line,'',' ');
               line2=stranslate(line2,'',' ');
               if ( line:==line2 ) {
                  break;
               }
            }
            activate_window(view_id1);
            get_line_raw(line);
            if ( expand_tabs_b4 ) { line=expand_tabs(line); }
            if ( expand_tabs(line,1,start_col-1,'S')!='' || ! ignore_leading_spaces ) {
               i1=text_col(line,start_col,'P');
            } else {
               i1=verify(line,' ');
               if ( ! i1 ) {
                  i1=length(line)+1;
               }
            }
            activate_window(view_id2);
            get_line_raw(line2);
            if ( expand_tabs_b4 ) { line2=expand_tabs(line2); }
            if ( expand_tabs(line2,1,start_col2-1,'S')!='' || ! ignore_leading_spaces ) {
               i2=text_col(line2,start_col2,'P');
            } else {
               i2=verify(line2,' ');
               if ( ! i2 ) {
                  i2=length(line2)+1;
               }
            }
            if ( ignore_trailing_spaces ) {
               line=strip(line,'T',' ');
               line2=strip(line2,'T',' ');
            }
            if ( ignore_case ) {
               line=upcase(line,p_UTF8);
               line2=upcase(line2,p_UTF8);
            }
            line_len=length(line);
            line_len2=length(line2);
            for (;;) {
               if ( i1>line_len || i2>line_len2 ) {
                  break;
               }
               if ( substr(line,i1,1):!=substr(line2,i2,1) ) {
                  if ( substr(line,i1,1):==' ' && ignore_all_spaces && i1<line_len ) {
                     i1=i1+1;
                     continue;
                  } else if ( substr(line2,i2,1):==' ' && ignore_all_spaces && i2<line_len2 ) {
                     i2=i2+1;
                     continue;
                  } else {
                     break;
                  }
               }
               i1=i1+1;i2=i2+1;
            }
            activate_window(view_id1);
            get_line_raw(line);
            if ( expand_tabs_b4 ) { line=expand_tabs(line); }
            p_col=text_col(line,i1,'i');
            activate_window(view_id2);
            get_line_raw(line2);
            if ( expand_tabs_b4 ) { line2=expand_tabs(line2); }
            p_col=text_col(line2,i2,'i');
            activate_window(view_id1);
            message(nls("Characters at cursor don't match"));
            return(1);
         }
         break;
      }
      down();
      if ( rc ) {
         activate_window(view_id1);
         down();
         if ( ! rc ) {
            message(nls('Files have different number of lines'));
            activate_window(view_id1);
            return(2);
         }
         message(nls('Files match.'));
         activate_window(view_id1);
         return(0);
      }
      activate_window(view_id1);
      down();
      if ( rc ) {
         message(nls('Files have different number of lines'));
         activate_window(view_id1);
         return(1);
      }
      start_col=1;start_col2=1;
      get_line_raw( line);
      if ( expand_tabs_b4 ) { line=expand_tabs(line); }
      activate_window(view_id2);
      get_line_raw( line2);
      if ( expand_tabs_b4 ) { line2=expand_tabs(line2); }
      if ( ignore_leading_spaces ) {
         line=strip(line,'L',' ');
         line2=strip(line2,'L',' ');
      }
   }

}
static compare_help_error()
{
   _str key_names='';
   parse where_is('compare','1') with 'is bound to 'key_names ;
   _str msg=nls('Before starting compare, use the Hsplit and Link Window commands on the Window menu to create two tiled windows containing the two files you want to compare.');
   if ( key_names!='' ) {
      popup_message(msg'   'nls('Start compare by pressing key(s) %s',key_names));
   } else {
      popup_message(msg);
   }
}

defeventtab _comparesetup_form;
_browse1.lbutton_up()
{
   int wid=p_window_id;
   typeless result=_OpenDialog('-modal',
                      '',                   // Dialog Box Title
                      '',                   // Initial Wild Cards
                      def_file_types,       // File Type List
                      OFN_FILEMUSTEXIST     // Flags
                      );
   if (result=='') {
      return('');
   }
   p_window_id=wid.p_prev;
   if (p_active_form.p_name=='_diffsetup_form') {
      p_text=strip(result,'B','"');
   }else{
      p_text=result;
   }
   end_line();
   _set_focus();
   return('');

}
_ok.on_create(_str buffer1name='')
{
   /*arg(1) is the initial buffer1 name. */
   _fl1.p_text=buffer1name;
   _file_width.p_text=_mdi.p_child.p_buf_width;
}

_ok.lbutton_up()
{
   _param1=strip(_fl1.p_text,'B','"');
   _param2=strip(_fl2.p_text,'B','"');
   _param3=(!isinteger(_file_width.p_text))?0:_file_width.p_text;
   if (_param1==''||_param2=='') {
      _message_box(nls("You must select two files to compare."));//Add nls if necessary
      return(1);
   }
   if (!file_or_buffer_exists(_param1)){
      _message_box(nls("File/buffer '%s' not found",_param1));
      _fl1._set_focus();
      return(1);
   }
   if (!file_or_buffer_exists(_param2)){
      _message_box(nls("File/buffer '%s' not found",_param2));
      _fl2._set_focus();
      return(1);
   }
   _save_form_response();
   p_active_form._delete_window(0);
}

static _str get_other_window_view_id(var w2_view_id)
{
   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      if (p_window_state=='M') {
         p_window_state='N';
      }
      int next_wid=_MDINextDocumentWindow(p_window_id,'g',true);
      int prev_wid=_MDINextDocumentWindow(p_window_id,'h',true);
      if (!next_wid && !prev_wid) {
         return(set_up_windows(w2_view_id));
      }
      if (prev_wid && !next_wid) {
         next_wid=_MDINextDocumentWindow(prev_wid,'h',true);
      } else if (next_wid && !prev_wid) {
         prev_wid=_MDINextDocumentWindow(next_wid,'g',true);
      }
      if (next_wid && prev_wid) {
         _message_box(nls("Compare requires exactly two horizontal or vertical tiled windows."));
         return(1);
      }
      if (prev_wid) {
         w2_view_id=prev_wid;
         return 0;
      }
      w2_view_id=next_wid;
      return 0;
   }
   if (p_window_state=='M' || _no_child_windows()) {
      return(set_up_windows(w2_view_id));
   }
   _str buf_name2='';
   int wid2=0;
   int tile_id=p_tile_id;
   int first_window_id=p_window_id;
   w2_view_id='';
   for (;;) {
      _next_window('HF');
      if ( p_window_id==first_window_id ) {
         break;
      }
      if ( p_tile_id==tile_id && !(p_window_flags &HIDE_WINDOW_OVERLAP)) {
         if ( w2_view_id!='' ) {
            w2_view_id='error';
            break;
         }
         get_window_id(w2_view_id);
         wid2=p_window_id;
         buf_name2=p_buf_name;
      }
   }
   if ( w2_view_id=='' || w2_view_id=='error') {
      return(set_up_windows(w2_view_id));
   }
#if 0
   if ( w2_view_id=='error') {  /* More than one tile? */
      _message_box(nls("Compare requires exactly two tiled windows."))
      return(1)
   }
#endif
   if (wid2.p_window_state=='I') {
      wid2.p_window_state='N';
   }
   if (p_window_state=='I') {
      p_window_state='N';
   }
   return(0);
}

static set_up_windows(int & w2_view_id)
{
   /*This functions used to set up windows for compare when not in one file per
     window mode.*/

   _str buf_name1=(_no_child_windows())?'':p_buf_name;
   typeless result=show('-modal _comparesetup_form',
                  buf_name1
                 );
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _str fn1=_param1;
   _str fn2=_param2;

   /*if the files to be compared are binary, _param1 is set to the file width,
     else it is 0.  This is because I felt that parsing this option out of
     the return string was somewhat sticky.*/
   typeless file_is_binary=_param3;
   fn1=maybe_quote_filename(absolute(fn1));
   fn2=maybe_quote_filename(absolute(fn2));
   if (file_is_binary) {
      fn1='+'file_is_binary' 'fn1;
      fn2='+'file_is_binary' 'fn2;
   }
   p_window_id=_mdi.p_child;
   typeless status=edit(fn1);
   if (status) {
       _message_box(nls("An error occured opening the file %s.\n\nCheck to be sure %s exists.",fn1,fn1));//Add nls if necessary
       return(1);
   }
   typeless hex_mode=p_hex_mode;
   top();
   int wid1=p_window_id;
   typeless w1;
   save_window_info(w1);
   if (p_window_state!='M') {
      zoom_window();
   }
   status=hsplit_window();
   get_window_id(w2_view_id);//Moved To Here
   if (status) {
       p_window_id=wid1;
       restore_window_info(w1);
       return(1);
   }
   status=edit('-w 'fn2);
   if (status) {
       _message_box(nls("An error occured opening the file %s.\n\nCheck to be sure %s exists.",fn2,fn2));//Add nls if necessary
       _delete_window();
       p_window_id=wid1;
       restore_window_info(w1);
       return(status);
   }
   if(p_hex_mode!=hex_mode) hex();
   top();
   p_window_id=wid1;_set_focus();
   return(0);
}


static save_window_info(_str &window_var)
{
   window_var='x='p_x' y='p_y' height='p_height' width='p_width ' state='p_window_state;
}

static restore_window_info(_str window_var)
{
   typeless x,y,height,width,state;
   parse window_var with 'x=' x 'y=' y 'height=' height 'width=' width 'state='state;
   p_window_state=state;
   if (x!='') {
      p_x=x;
   }
   if (y!='') {
      p_y=y;
   }
   if (height!='') {
      p_height=height;
   }
   if (width!='') {
      p_width=width;
   }
}

#if 0
static _str mark_cursor(bin,start_at_col1)
{
   _deselect
   if ( p_line > 0 ) {
      if ( bin || ! start_at_col1 ) {
         _select_block
      } else {
         _select_line
      }
   }

}
#endif
static void temporary_select_char()
{
   _next_window('f');  // Don't want to set focus
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      return;
   }
#if 0
   _deselect;_cua_select=1;_select_char('','ei');_prev_window 'f';return('');
#endif
   typeless old_mark=_duplicate_selection('');
   _select_char(mark,'ei');
   _show_selection(mark);_prev_window('f');refresh();
   delay(300,'k'); // Highlight for 3 seconds. Pressing ALT for menu won't work.
   _show_selection(old_mark);
   _free_selection(mark);
   //_undo 's';call_key key

}
  /* May use the commands below at a later date. */
   /* message msg' Resync/Compare/Window/Find/Help/Options?' */


/**
 * Moves the cursor up in both buffers being compared.  This command 
 * is typically used when comparing files with the <b>compare</b> command.
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Buffer_Functions
 */
_command void compare_up() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int view_id=0;
   get_window_id(view_id);
   int view_id2=0;
   if ( set_compare_options(view_id2) ) return;
   activate_window(view_id2);
   cursor_up();
   _deselect();_select_block();
   activate_window(view_id);
   cursor_up();
}

/**
 * Moves the cursor down in both buffers being compared.  This command is 
 * typically used when comparing files with the <b>compare</b> command.
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Buffer_Functions
 */
_command void compare_down() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int view_id=0;
   get_window_id(view_id);
   int view_id2=0;
   if ( set_compare_options(view_id2) ) return;
   activate_window(view_id2);
   cursor_down();
   _deselect();_select_block();
   activate_window(view_id);
   cursor_down();

}

/**
 * Moves the cursor right in both buffers being compared.  This command 
 * is typically used when comparing files with the <b>compare</b> command.
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Buffer_Functions
 */
_command void compare_right() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int view_id=0;
   get_window_id(view_id);
   int view_id2=0;
   if ( set_compare_options(view_id2) ) return;
   activate_window(view_id2);
   cursor_right();
   _deselect();_select_block();
   activate_window(view_id);
   cursor_right();
}
/**
 * Moves the cursor left in both buffers being compared.  This command is 
 * typically used when comparing files with the <b>compare</b> command.
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Buffer_Functions
 */
_command void compare_left() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int view_id=0;
   get_window_id(view_id);
   int view_id2=0;
   if ( set_compare_options(view_id2) ) return;
   activate_window(view_id2);
   cursor_left();
   _deselect();_select_block();
   activate_window(view_id);
   cursor_left();
}


/**
 * Moves the cursor to top of buffer for both buffers being compared.  This 
 * command is typically used when comparing files with the <b>compare</b> command.
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Buffer_Functions
 */
_command void compare_top() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int view_id=0;
   get_window_id(view_id);
   int view_id2=0;
   if ( set_compare_options(view_id2) ) return;
   activate_window(view_id2);
   top_of_buffer();
   _deselect();_select_block();
   activate_window(view_id);
   top_of_buffer();

}

/**
 * Moves the cursor to bottom of buffer for both buffers being compared.  
 * This command is typically used when comparing files with the <b>compare</b> 
 * command.
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Buffer_Functions
 */
_command void compare_bottom() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int view_id=0;
   get_window_id(view_id);
   int view_id2=0;
   if ( set_compare_options(view_id2) ) return;
   activate_window(view_id2);
   bottom_of_buffer();
   _deselect();_select_block();
   activate_window(view_id);
   bottom_of_buffer();

}

/**
 * Moves the cursor to the next page of both buffers being compared.  This 
 * command is typically used when comparing files with the <b>compare</b> command.
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Buffer_Functions
 */
_command void compare_page_down() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int view_id=0;
   get_window_id(view_id);
   int view_id2=0;
   if ( set_compare_options(view_id2) ) return;
   activate_window(view_id2);
   page_down();
   _deselect();_select_block();
   activate_window(view_id);
   page_down();
}
/**
 * Moves the cursor to the previous page of both buffers being compared.  This 
 * command is typically used when comparing files with the <b>compare</b> command.
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Buffer_Functions
 */
_command void compare_page_up() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int view_id=0;
   get_window_id(view_id);
   int view_id2=0;
   if ( set_compare_options(view_id2) ) return;
   activate_window(view_id2);
   page_up();
   _deselect();_select_block();
   activate_window(view_id);
   page_up();
}
