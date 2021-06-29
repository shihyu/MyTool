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
#include "minihtml.sh"
#include "markers.sh"
#include "vsevents.sh"
#import "autocomplete.e"
#import "bind.e"
#import "clipbd.e"
#import "codehelp.e"
#import "compile.e"
#import "context.e"
#import "cua.e"
#import "cutil.e"
#import "debug.e"
#import "debugpkg.e"
#import "dlgman.e"
#import "files.e"
#import "help.e"
#import "hex.e"
#import "html.e"
#import "htmltool.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "picture.e"
#import "pmatch.e"
#import "pushtag.e"
#import "recmacro.e"
#import "seek.e"
#import "seldisp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbprops.e"
#import "util.e"
#import "vi.e"
#import "vicmode.e"
#import "xml.e"
#require "se/lang/api/ExtensionSettings.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/color/DefaultColorsConfig.e"
#endregion

using se.lang.api.ExtensionSettings;
using se.lang.api.LanguageSettings;

_str def_space_chars='\t ';
static int _max_skip=1;
static _str _last_fast_event;
_str def_click_past_end;
int def_minimap_tooltip_lines=8;
static _str movecopy_selection;

/** 
 * If set to 'true', always scroll horizontally, even if the right-most column
 * of text is already visible for the lines currently on the screen. 
 *  
 * @default true
 * @categories Configuration_Variables
 */
bool def_limit_hscroll=true;

/**
 * Indicates the amount of time, in milliseconds, to delay before showing 
 * information for the symbol under the mouse in an editor window. 
 * 
 * @default 250 ms
 * @categories Configuration_Variables
 */
int def_tag_hover_editor_delay = 250;

/**
 * When set to 'true', Ctrl+Click can be used to create multiple cursors.
 *  
 * @default true
 * @categories Configuration_Variables
 */
bool def_multi_cursor_click = true;

static int BBTimerHandle=-1;  // When >=0 this is the handle for the
                              // popup message timer
static int gBBWid=0; // Window id of button whose message we
                     //  are currently displaying
static bool gBBWid_minimap_had_focus;
static bool gBBWid_minimap_had_selection;
static int gbuf_id;  // Buffer id of original editor control
static _str gLineNum;  // point() of original editor control
static int gCol;  // Line number of original editor control
static int gmx,gmy;  // Remember
static _str gScrollInfo;  // Original scroll info
static const BBTIMER_INTERVAL= 100;  // 1/10 second
static bool gInMouseMoveHandler;

static _str gURL;
static int gpreURLMousePointer;
static int gURL_window_id;
static bool goverURL;
static bool gmodKeyDown;
static int gmulti_cursor_count;
static typeless gmuti_cursor_count_time;

/**
 * Are we in the mouse-over handler code?
 * Then don't do anything funky like building
 * a tag file spontaneously.
 */
bool mousemove_handler_running()
{
   return gInMouseMoveHandler;
}


/*
Tested on Windows. Adjust for the fact that when
there is an ibeam cursor it seems to click further left that it appears. People
align their eyes with the middle of the ibean but that's not where the hot 
spot is. Instead of adjusting the click to be further right, make the window 
left margin smaller so we don't end up selecting the line when we really want
to just place the cursor.
*/
int _adjusted_windent_x() {
   if (!p_HasBuffer) {
      return 0;
   }
   if (machine()=='WINDOWS') {
      if (p_windent_x<=0) {
         return p_windent_x;
      }
      return p_windent_x-1;
   }
   return p_windent_x;
}

/**
 * Determine the first and last visible lines in the current window (editor control). 
 * 
 * @param startOffset  set to the start seek position of the first line (inclusive)
 * @param endOffset    set to the start seek position of the last line (inclusive)
 */
static void determineFirstAndLastVisibleLines(long &startLineOffset, long &endLineOffset)
{
   // find the first and last visible lines on the screen
   save_pos(auto p);
   orig_cursor_y := p_cursor_y;
   // adjust screen position if we are scrolled
   if (p_scroll_left_edge >= 0) {
      _str line_pos,down_count,SoftWrapLineOffset;
      parse _scroll_page() with line_pos down_count SoftWrapLineOffset;
      goto_point(line_pos);
      down((int)down_count);
      set_scroll_pos(p_scroll_left_edge,0,(int)SoftWrapLineOffset);
   }
   p_cursor_y=0;
   _begin_line();
   startLineOffset = _nrseek();
   p_cursor_y=p_client_height-1;
   down();
   endLineOffset=_nrseek();
   restore_pos(p);
}

/**
 * Determine the longest pixel line length for seek range
 * 
 * @param startOffset  set to the start seek position of the first line (inclusive)
 * @param endOffset    set to the start seek position of the last line (inclusive)
 */
static int determineLongestPixelLineLength(long startLineOffset, long endLineOffset)
{
   // find the first and last visible lines on the screen
   save_pos(auto p);
   goto_point(startLineOffset);
   max_pixel_line_length := 0;
   while (_nrseek() <= endLineOffset) {
      _end_line();

      left_edge:=p_left_edge;
      if (p_fixed_font) {
         left_edge=left_edge*p_font_width;
      }
      pixel_line_length := left_edge+p_cursor_x;
      if (pixel_line_length > max_pixel_line_length) {
         max_pixel_line_length = pixel_line_length;
      }
      if (down()) break;
   }
   restore_pos(p);
   return max_pixel_line_length;
}

/**
 * Extend the given range of lines, indicated by seek positions, by the given 
 * number of additional lines above and below.
 * 
 * @param startOffset  set to the start seek position of the first line (inclusive)
 * @param endOffset    set to the start seek position of the last line (inclusive)
 */
static void determineExtendedVisibleLineRange(long &startLineOffset, long &endLineOffset, int numExtraLines)
{
   if (numExtraLines <= 0 || startLineOffset <= 0) {
      return;
   }
   // find the first and last visible lines on the screen
   save_pos(auto p);
   goto_point(startLineOffset);
   up(numExtraLines);
   _begin_line();
   startLineOffset = _nrseek();
   goto_point(endLineOffset);
   down(numExtraLines);
   endLineOffset=_nrseek();
   restore_pos(p);
}

/*struct VSMOUSEOVERINFO {
   int buf_id;
   int LineNum;
   int col;
   int x,y,width,height;
};
static VSMOUSEOVERINFO gMouseOverInfo;
*/

/**
 * <pre>
 * This command may only be bound to the following scroll bar events:
 * on_vsb_line_down
 * on_vsb_line_up
 * on_sb_end_scroll
 * on_hsb_line_down
 * on_hsb_line_up
 * 
 * The above events are only received by edit window, and editor controls.  
 * It performs some optimizations for speeding up scrolling.
 * </pre>
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Mouse_Functions
 */
_command void fast_scroll() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
#if 0
   // ON_SB_END_SCROLL no longer supported
   if (last_event()==ON_SB_END_SCROLL) {
      _last_fast_event='';
      return;
   }

   --_chg_count;
   if ( _chg_count<=0 ) {
      _chg_count=DEF_FS_CHG_COUNT;
      _max_skip += DEF_FS_INC_MAX_SKIP_BY;
      if ( _max_skip>DEF_FS_MAX_SKIP ) {
         _max_skip=DEF_FS_MAX_SKIP;
      }
   }
   if (_last_fast_event:!=last_event()) {
      _last_fast_event=last_event();
      _chg_count=DEF_FS_CHG_COUNT;
      _max_skip=1;
   }
   _max_skip=1;
   int i;
   for (i=1;i<=_max_skip;++i) {
      int key=event2index(_last_fast_event);
      key&=(~VSEVFLAG_ALL_SHIFT_FLAGS);
      _last_fast_event=index2event(key);

      switch (_last_fast_event) {
      case WHEEL_DOWN:
      case ON_VSB_LINE_DOWN:
         _scroll_page('d',1);
         break;
      case WHEEL_UP:
      case ON_VSB_LINE_UP:
         _scroll_page('u',1);
         break;
      case WHEEL_LEFT:
      case ON_HSB_LINE_UP:
         _sb_line_left();
         break;
      case WHEEL_RIGHT:
      case ON_HSB_LINE_DOWN:
         _sb_line_right();
         break;
      }
   }
#else
   int key=event2index(last_event());
   key&=(~VSEVFLAG_ALL_SHIFT_FLAGS);
   _str e=index2event(key);

   switch (e) {
   case WHEEL_DOWN:
   case ON_VSB_LINE_DOWN:
      _scroll_page('d',1);
      break;
   case WHEEL_UP:
   case ON_VSB_LINE_UP:
      _scroll_page('u',1);
      break;
   case WHEEL_LEFT:
   case ON_HSB_LINE_UP:
      _sb_line_left();
      break;
   case WHEEL_RIGHT:
      if (def_limit_hscroll) {
         determineFirstAndLastVisibleLines(auto startLineOffset, auto endLineOffset);
         parse def_scroll_speeds with . . auto skip_count .;
         if (isinteger(skip_count) && skip_count > 0) {
            determineExtendedVisibleLineRange(startLineOffset, endLineOffset, (int)skip_count);
         }
         rightEdge := determineLongestPixelLineLength(startLineOffset, endLineOffset);
         if (p_scroll_left_edge<=0 && rightEdge<p_client_width) {
            break;
         }
         scroll_left_edge := p_scroll_left_edge;
         if (p_fixed_font) {
            scroll_left_edge=p_scroll_left_edge*p_font_width;
         }
         left_edge:=p_left_edge;
         if (p_fixed_font) {
            left_edge=left_edge*p_font_width;
         }
         partial_client_width := (7*p_client_width intdiv 8);
         if (scroll_left_edge >= 0 && scroll_left_edge+partial_client_width >= rightEdge) {
            break;
         } else if (left_edge+partial_client_width >= rightEdge) {
            break;
         }
      }
   case ON_HSB_LINE_DOWN:
      _sb_line_right();
      break;
   }
#endif
}
void _set_scroll_speed(var init_delay,var skip_count,int &count,int mx,int my)
{

   int diff_y,speed;
   if (my<p_windent_y) {
      diff_y= -my-p_windent_y;
   } else if (my>=p_client_height){
      diff_y=my-p_client_height;
   } else {
      return;
   }
   typeless s1,s2,s3,s4;
   parse def_scroll_speeds with s1 s2 s3 s4 .;
   diff_y=_dy2ly(SM_TWIP,diff_y);
   if (diff_y<=200) {
      speed=s1;
   } else if (diff_y<=400) {
      speed=s2;
   } else if (diff_y<=600) {
      speed=s3;
   } else {
      speed=s4;
   }
   parse speed with init_delay '.' skip_count;
   count=99999;
}
static bool selectNscroll(_str &mark_name,_str mstyle,bool lastkey_not_rbutton,int mx,int my,int wx,int wy,bool select_words,
                             int first_word_start_offset,int first_word_end_offset)
{
   /* we are outside the window. */
   /* Determine which side of window we are outside. */
   past_bottom := past_top := past_right := past_left := new_x := new_y := 0;
   mou_set_scroll_directions(past_bottom,past_right,past_top,past_left,new_x,new_y,mx,my);
   _SelectToCursor(mark_name,mstyle,new_x,new_y,select_words,(typeless)movecopy_selection,first_word_start_offset,first_word_end_offset,past_bottom!=0,past_right!=0,past_top!=0,past_left!=0);
   int init_delay=def_init_delay;
   max_skip := 1;
   int count=DEF_CHG_COUNT;
   _set_scroll_speed(init_delay,max_skip,count,mx,my);

   skip_count := 0;
   if ( machine()=='WINDOWS' ) {
      max_skip=2;
   }
   int NofbytesPerLine=p_hex_Nofcols*p_hex_bytes_per_col;
   _set_timer(init_delay);
   for (;;) {
      typeless event=ON_TIMER;
      ++skip_count;
      no_skip := skip_count>=max_skip;   //  || test_event('r'):!='')
      if ( no_skip ) {
         event=get_event('k');
         skip_count=0;
      }
      if (event:==ON_TIMER) {
         --count;
         if ( count<=0 ) {
            count=DEF_CHG_COUNT;
#if 0
            if ( init_delay>DEF_MIN_DELAY ) {
               init_delay -= DEF_DEC_DELAY_BY;
            } else {
               init_delay=DEF_MIN_DELAY;
            }
#endif
            max_skip += DEF_INC_MAX_SKIP_BY;
            if ( max_skip>DEF_MAX_SKIP ) {
               max_skip=DEF_MAX_SKIP;
            }
         }
      } else if ( event:==MOUSE_MOVE ) {
         // Mapping coordinates under UNIX is VERY VERY slow.
         // Here were reduce the number of calls a lot.
         mx=mou_last_x('D');my=mou_last_y('D');
         mx-=wx;my-=wy;
         if ( mou_in_window3(mx,my) ) {
            _SelectToCursor(mark_name,mstyle,mx,my,select_words,(typeless)movecopy_selection,first_word_start_offset,first_word_end_offset);
            _kill_timer();
            return(false);
         }
         mou_set_scroll_directions(past_bottom,past_right,past_top,past_left,new_x,new_y,mx,my);
         _SelectToCursor(mark_name,mstyle,new_x,new_y,select_words,(typeless)movecopy_selection,first_word_start_offset,first_word_end_offset);
         _set_scroll_speed(init_delay,max_skip,count,mx,my);
         _set_timer(init_delay);
      } else if ( !movecopy_selection && lastkey_not_rbutton && any_rbutton(event) ) {
         if ( mark_name=='CHAR' ) {
            mark_name='BLOCK';
            switch_select_type(mark_name/*,'',orig_col*/);
         } else if ( mark_name=='BLOCK' ) {
            mark_name='LINE';
            switch_select_type(mark_name/*,'',orig_col*/);
         } else if ( mark_name=='LINE' ) {
            mark_name='CHAR';
            switch_select_type(mark_name/*,'',orig_col*/);
         }
      } else if ( !movecopy_selection && lastkey_not_rbutton && event:==RBUTTON_UP ) {
      } else {
         _kill_timer();
         return(true);
      }
      down_rc := 0;
      if (p_hex_mode==HM_HEX_ON) {
         int offset=_nrseek();
         if ( past_bottom ) {
            int temp=offset+NofbytesPerLine;
            if (temp>p_buf_size) {
               temp-=NofbytesPerLine;
               down_rc=BOTTOM_OF_FILE_RC;
            } else {
               _nrseek(temp);
            }
         }
         if ( past_top ) {
            int temp=offset-NofbytesPerLine;
            if (temp<0) temp=0;
            _nrseek(temp);
         }
         if ( past_right ) {
            int LineOfs=offset%NofbytesPerLine;
            if (LineOfs<NofbytesPerLine-1) {
               _nrseek(offset+1);
            }
         }
         if ( past_left ) {
            p_cursor_x=0;
         }
         if ( down_rc && ! past_left ) {
            /* save_pos(p); */
            _nrseek(p_buf_size);
            if (!movecopy_selection) {
               select_it(mark_name,'',mstyle);
            }
            /* restore_pos(p) */
         } else {
            if (!movecopy_selection) select_it(mark_name,'',mstyle);
         }
      } else {
         if ( past_bottom ) {
            down_rc=cursor_down(1,1);
         }
         if ( past_top ) {
            cursor_up(1,1);
            if (!movecopy_selection && _on_line0() ) {
               cursor_down(1,1);
            }
         }
         if ( past_right ) {
            right();
         }
         if ( past_left ) {
            _refresh_scroll();
            p_cursor_x=0;
            left();
         }
         if ( down_rc && ! past_left ) {
            /* save_pos(p); */
            end_line();
            if ( ! p_buf_width ) {
               p_col++;
            }
            if (!movecopy_selection) {
               if (select_words) {
                  select_more_words(first_word_start_offset,first_word_end_offset,mstyle,-1,-1,past_bottom!=0,past_right!=0,past_top!=0,past_left!=0);
               } else {
                  select_it(mark_name,'',mstyle);
               }
            }
            /* restore_pos(p) */
         } else {
            if (!movecopy_selection) {
               if (select_words) {
                  select_more_words(first_word_start_offset,first_word_end_offset,mstyle,-1,-1,past_bottom!=0,past_right!=0,past_top!=0,past_left!=0);
               } else {
                  select_it(mark_name,'',mstyle);
               }
            }
         }
      }
   }

}
/**
 * Places the cursor where the mouse is and inserts the system clipboard  
 * (not the VS internal clipboard) at the cursor.  This command was designed to 
 * be natural for X Windows users but may make no sense to other users.  This 
 * command is more useful when the macro variable "def_autoclipboard" is set to 
 * 1 (use menu item "Macro", "Set Macro Variable...").  When this variable is 
 * on, selecting text with the mouse automatically creates a system clipboard 
 * but not a SlickEdit internal clipboard. 
 * 
 * @return Returns 0 if successful.  Other a non-zero number is returned.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Mouse_Functions
 * 
 */
_command int mou_paste() name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX|VSARG2_MARK)
{
   if (!def_autoclipboard) {
      // set def_autoclipboard=0 to support Microsoft IntelliMouse
      // (because middle button gets pressed accidently when scrolling)
      return(0);
   }
   if (_mdi.p_child.select_active()) {
      deselect();
   }
   if (command_state()) {
      //Caller must place the cursor first
      //This command only performs a paste when in a text box
#if 0
      int col;
      if (p_word_wrap) {
         col=mou_col2(mou_last_x(),mou_last_y());
      }else{
         col=mou_col(mou_last_x());
      }
      line := p_text;
      if (col-1>length(line)) {
         col=length(line)+1;
      }
      _set_sel(col);
#endif
   } else {
      if (p_scroll_left_edge>=0) {
         _scroll_page('r');
      }
      // X Windows is slow at mapping window coordinates
      int mx=mou_last_x('D');
      int my=mou_last_y('D');
      _map_xy(0,p_window_id,mx,my);
      p_cursor_y=my;
      p_cursor_x=mx;
      if (/*!def_click_past_end && */_select_type()!='BLOCK') {
         if (p_col>_text_colc()) _end_line();
      }
   }
   if (_isWindows()) {
      _cvtautoclipboard();
   }
   int status=paste('',!_isUnix());
   //if (pushedClipboard) pop_clipboard_itype(true);
   return(status);
}
/**
 * Copies current selection to cursor position.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Mouse_Functions
 * 
 */
_command void mou_copy_to_cursor(_str movecopy_option="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   if (movecopy_option=="") {
      movecopy_option="C";
   }
   if (_select_type()=='' /*!select_active2()*/) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return;
   }
   first_col := last_col := buf_id := 0;
   _get_selinfo(first_col,last_col,buf_id);
   doSmartPaste := false;
   if (p_buf_id==buf_id) {
      doSmartPaste=true;
      lock_selection('0');
   }

   if (p_scroll_left_edge>=0) {
      _scroll_page('r');
   }
   p_cursor_y=mou_last_y();
   p_cursor_x=mou_last_x();
   _copy_or_move('',
                 movecopy_option /* Copy selection, move selection, or paste clipboard. */,
                 doSmartPaste/* do SmartPaste(R). */);
   if (def_deselect_paste) {
      _deselect();
   }
}
/**
 * Copies current selection to cursor position.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Mouse_Functions
 * 
 */
_command void mou_move_to_cursor() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   mou_copy_to_cursor('M');
}

/**
 * Creates a selection without removing any existing selections.
 *  
 * @return int 
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Mouse_Functions
 */
_command int mou_click_copy() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_NOEXIT_SCROLL)
{
   // It is assumed that this command is bound to C-LBUTTON-DOWN.
   // On mac this is bound to A-LBUTTON-DOWN.
   return(mou_click('','C',false,1 /* add cursor */));
}
_command int mou_click_copy_block() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_NOEXIT_SCROLL)
{
   return(mou_click('BLOCK','C'));
}
_command int mou_click_block_add_cursors() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_NOEXIT_SCROLL)
{
   return(mou_click('BLOCK','C',false,2 /* add cursors from selection */));
}

//def "mouse_move"=
/*
def "mouse_move"=mymouse_move

void mymouse_move()
{
   word=_MouCurWord(mou_last_x(),mou_last_y(),
               false,
               1,
               PhysicalStartCol,
               0)  //  int option /* 1 from cursor, 2- end prev word*/)
   message('word='word);
}
*/

_str _MouCurWord(int x,int y,bool XYAreInScreenCoordinates,
                 int MaybeReturnSelectedText,
                 int &PhysicalStartCol,
                 int option /* 1 from cursor, 2- end prev word, 10 return '' */)
{
   //say('MaybeReturnSelectedText='MaybeReturnSelectedText);
   if(XYAreInScreenCoordinates) {
      _map_xy(0,p_window_id,x,y);
   }
   save_pos(auto p);
   p_cursor_y=y;
   p_cursor_x=x;
   PhysicalStartCol=0;
   mark_locked := 0;
   if (_select_type('','S')=='C') {
      mark_locked=1;
      _select_type('','S','E');
   }

   // IF we are past the end of line OR
   //    NOT
   //       the character under the cursor is not a word character OR
   //       the cursor is in a selection which is only one line
   in_selection := MaybeReturnSelectedText && mou_in_selection(x,y) && (count_lines_in_selection()==1 || _select_type()=='CHAR');
   result := "";
   //say('in_selection='mou_in_selection(x,y));
   if (p_col>_text_colc() ||
       !( pos('[\od'_extra_word_chars:+p_word_chars']',get_text(1),1,'r') ||
          in_selection
        )
      ) {
      result="";
   } else if (in_selection) {
      if (_select_type()=='CHAR') {
         _end_select();
         int end_pos=_nrseek();
         _begin_select();
         int start_pos=_nrseek();
         result=get_text(end_pos-start_pos+(int)(_select_type('','I')));
      } else {
         start_col := end_col := buf_id := 0;
         _get_selinfo(start_col,end_col,buf_id);
         //say('start_col='start_col' end_col='end_col);
         result=_expand_tabsc(start_col,end_col-start_col,'S');
      }
   } else {
      if (option==10) {
         result='';
      } else {
         from_cursor   := (option==1);
         end_prev_word := (option==2);
         result=cur_word(PhysicalStartCol,from_cursor,end_prev_word);
      }
   }
   restore_pos(p);
   if (mark_locked) {
      _select_type('','S','C');
   }
   return(result);
}
/*
   This function is called by windows drag drop dll
*/
void _scroll(bool past_left,bool past_top, bool past_right, bool past_bottom)
{
   //say('past_bottom='past_bottom);
   down_rc := 0;
   if (p_hex_mode==HM_HEX_ON) {
      int NofbytesPerLine=p_hex_Nofcols*p_hex_bytes_per_col;
      int offset=_nrseek();
      if ( past_bottom ) {
         int temp=offset+NofbytesPerLine;
         if (temp>p_buf_size) {
            temp-=NofbytesPerLine;
            down_rc=BOTTOM_OF_FILE_RC;
         } else {
            _nrseek(temp);
         }
      }
      if ( past_top ) {
         int temp=offset-NofbytesPerLine;
         if (temp<0) temp=0;
         _nrseek(temp);
      }
      if ( past_right ) {
         int LineOfs=offset%NofbytesPerLine;
         if (LineOfs<NofbytesPerLine-1) {
            _nrseek(offset+1);
         }
      }
      if ( past_left ) {
         p_cursor_x=0;
      }
      if ( down_rc && ! past_left ) {
         /* save_pos(p); */
         _nrseek(p_buf_size);
         //if (!movecopy_selection) select_it(mark_name,'',mstyle)

      } else {
         //if (!movecopy_selection) select_it(mark_name,'',mstyle)
      }
   } else {
      if ( past_bottom ) {
         down_rc=cursor_down(1,1);
      }
      if ( past_top ) {
         cursor_up(1,1);
         //if (!movecopy_selection && _on_line0() ) {
         //   cursor_down();
         //}
      }
      if ( past_right ) {
         right();
      }
      if ( past_left ) {
         _refresh_scroll();
         p_cursor_x=0;
         left();
      }
      if ( down_rc && ! past_left ) {
         end_line();
         if ( ! p_buf_width ) {
            p_col++;
         }
         /*if (!movecopy_selection) {
            if (select_words) {
               select_more_words(mstyle,-1,-1);
            } else {
               select_it(mark_name,'',mstyle);
            }
         }
         */
      } else {
         /*if (!movecopy_selection) {
            if (select_words) {
               select_more_words(mstyle,-1,-1);
            } else {
               select_it(mark_name,'',mstyle);
            }
         }
         */
      }
   }
}
bool _isDragDrop(int mx,int my)
{
   mou_mode(1);
   mou_capture();
   int cxdragmin= _default_option(VSOPTION_CXDRAGMIN);
   int cydragmin= _default_option(VSOPTION_CYDRAGMIN);
   //say(' dx='cxdragmin' 'cydragmin);
   //mx=mou_last_x('D');my=mou_last_y('D');
   //say('wx='wx' 'wy' mx='mx);
   _set_timer(_default_option(VSOPTION_DRAGDELAY));
   doDragDrop := false;
   start_time := (long)_time('B');
   for (;;) {
       typeless event=get_event('rk2');
       if ( event:==MOUSE_MOVE ) {
          //say('cc');
          // Mapping coordinates under UNIX is VERY VERY slow.
          // Here were reduce the number of calls a lot.
          int tx=mou_last_x();
          int ty=mou_last_y();
          tx-=mx;
          int y=ty-=my;
          end_time := (long)_time('B');
          if (end_time - start_time > 100) {
             if (abs(tx)>=cxdragmin || abs(ty)>=cydragmin) {
                //say('h1 tx='tx' ty='ty' dx='cxdragmin' wx='wx' 'wy);
                doDragDrop=true;
                break;
             }
          }
       } else if (event:==ON_TIMER) {
          //say('h2');
          doDragDrop=true;
          break;
       } else {
          break;
       }
   }
   _kill_timer();
   mou_mode(0);
   mou_release();
   return(doDragDrop);
}

/**
 * If the cursor is currently in virtual space between two tab
 * characters, align it to the nearest real character boundary.
 */
static void align_to_nearest_char()
{
   int col = _text_colc(p_col, 'p');
   int low_col  = _text_colc(col, 'i');
   int high_col = _text_colc(col+1, 'i');
   if (p_col-low_col <= high_col-p_col) {
      col = low_col;
   } else {
      col = high_col;
   }
   if (p_col != col) {
      p_col = col;
   }
}

static const  DROPEFFECT_NONE=   ( 0 );
static const  DROPEFFECT_COPY=   ( 1 );
static const  DROPEFFECT_MOVE=   ( 2 );
static const  DROPEFFECT_LINK=   ( 4 );
static const  DROPEFFECT_LOCAL=  0x8000;
static const  DROPEFFECT_SCROLL= ( 0x80000000 );
static int _mou_click_handle_drag_drop(int mx,int my,int wx,int wy,_str mark_name, _str mstyle, bool select_words, _str menu_option,int mark_locked,int first_word_start_offset,int first_word_end_offset, bool lastkey_not_rbutton, typeless orig_pos,_str old_scroll_style,_str copytext_option) {

   // For now, don't support drag/drop for multiple selections
   if (_MultiCursor()) {
      _MultiCursorClearAll();
   }

   if (_EditorCtlSupportsDragDrop()) {
      // are we dragging and dropping?
      if (!_isDragDrop(mx,my)) {
         // IF this is a mark start with shift-arrow keys or mouse and */
         // marks are not persistant  OR  menu_option given
         if ( (_cua_select && def_persistent_select!='Y') || menu_option
            // OR the mark is a locked persistant mark
            // || (! _cua_select && _select_type('','U')=='P' && _select_type('','s')=='E')
         ) {
            _deselect();
         } else if (mark_locked) {
            _select_type('','S','C');
         }
      } else {
         int old=def_autotag_flags2;
         int status=_DragDropStart(p_window_id);
         def_autotag_flags2=old;

         if (status==DROPEFFECT_NONE) {
            if (mark_locked) {
               _select_type('','S','C');
            }
            restore_pos(orig_pos);
         }
      }
      if (_isnull_selection()) {
         _cua_select=1;
      }
      if ( !def_click_past_end && _select_type()!='BLOCK' ) {
         if( p_col>_text_colc() ) _end_line();
      }
      if ( def_jmp_on_tab && _select_type()!='BLOCK' ) {
         align_to_nearest_char();
      }
      _scroll_style(old_scroll_style);
      return(1);
   }
   int old_mouse_pointer=p_mouse_pointer;
   movecopy_selection=1;
   save_pos(orig_pos);
   blank_inserted := false;
   if (_select_type()!='LINE' || def_line_insert=='B') {
      // Want to allow user to copy/move past end of buffer.
      old_modify := p_modify;
      bottom();
      if (!p_buf_width && _line_length()==_line_length(true)) {
         if (p_buf_width) {
            insert_line('');
            blank_inserted=true;
         } else {
            // For now don't allow insert after EOF character.
            blank_inserted=false;
         }
      } else {
         insert_line('');
         _delete_text(2); // Delete NLChars
         blank_inserted=true;
      }
      restore_pos(orig_pos);
      if (!old_modify) p_modify=false;
   }
#if 0
   mark_locked2=0;
   if (mark_locked) {
      mark_locked2=1;
      // Lock the selection so we can move the cursor without
      // changing the selection
      _begin_select();
      //if (_select_type('','S')=='E') {
      stop();

      restore_pos(orig_pos);
      _end_select();restore_pos(orig_pos);
   }
#endif
   p_cursor_y=my;
   p_cursor_x=mx;
   save_pos(orig_pos);
   mou_mode(1);
   mou_release();
   p_mouse_pointer=MP_MOVETEXT;
   mou_capture();
   p_mouse_pointer=MP_MOVETEXT;
   if (copytext_option) {
      message(nls('Copy selected text to new location'));
   } else {
      message(nls('Move selected text to new location'));
   }


   // Turn off cursor blink
   _default_option('k',0);
   for (;;) {
       typeless event=get_event('k');
       if ( event:==MOUSE_MOVE ) {
          // Mapping coordinates under UNIX is VERY VERY slow.
          // Here were reduce the number of calls a lot.
          mx=mou_last_x('D');my=mou_last_y('D');
          mx-=wx;my-=wy;
          // This code has gotten more complicated to handle BLOCK marks and menus better
          if ( mou_in_window3(mx,my) ) {
             _SelectToCursor(mark_name,mstyle,mx,my,select_words,(typeless)movecopy_selection,first_word_start_offset,first_word_end_offset);
          } else {
             done := selectNscroll(mark_name,mstyle,lastkey_not_rbutton,mx,my,wx,wy,select_words,first_word_start_offset,first_word_end_offset);
             if ( done ) {
                break;
             }
          }
#if 0 /*__MACOSX__ */
       } else if (event:==ON_KEYSTATECHANGE) {
          if (_IsKeyDown(ALT)) {
             copytext_option=true;
             message(nls('Copy selected text to new location'));
          } else {
             copytext_option=false;
             message(nls('Move selected text to new location'));
          }
#endif
       } else {
          break;
       }
   }
   // Turn on cursor blink
   _default_option('k',1);
   clear_message();
   mou_mode(0);
   mou_release();
   _scroll_style(old_scroll_style);
   p_mouse_pointer=old_mouse_pointer;
   switch (last_event()) {
   case LBUTTON_UP:
   case RBUTTON_UP:
   case MBUTTON_UP:
      int in_selection=mou_in_selection(mou_last_x(),mou_last_y());
      do_delete := false;
      if (blank_inserted) {
         if (in_selection) {
            old_modify := p_modify;
            bottom();_delete_line();
            restore_pos(orig_pos);
            p_modify=old_modify;
         } else {
            if (_select_type()=='LINE') {
               do_delete=true;
            } else {
               save_pos(auto p);
               int status=down();
               if (!status) {
                  up();
                  do_delete=true;
               }
               restore_pos(p);
            }
         }
      }
      if (in_selection) {
         /*if (mark_locked) {
            _select_type('','S','C');
         } */
         _deselect();
         _cua_select=1;
         return(0);
      }
      typeless status;
      if (copytext_option) {
         status=_copy_or_move('','C',true /* SmartPaste(R) */ ,false /* no deselect */);
      } else {
         status=_copy_or_move('','M',true /* SmartPaste(R) */ ,false /* no deselect */);
      }
      _end_select();
      if (do_delete) {
         save_pos(auto p);
         bottom();_delete_line();
         restore_pos(p);
      }
      if (def_deselect_paste) {
         _deselect();
         _cua_select=1;
      } else {
         if (mark_locked) {
            _select_type('','S','C');
         }
         /*if (mark_locked2) {
            select_it(_select_type(),'',_select_type('','I'):+_select_type('','U'):+'C')
         } */
      }
      return(0);
   }
   if (blank_inserted) {
      bottom();_delete_line();
   }
   // Operation cancelled
   restore_pos(orig_pos);
   if (mark_locked) {
      _select_type('','S','C');
   }
   /*if (mark_locked2) {
      select_it(_select_type(),'',_select_type('','I'):+_select_type('','U'):+'C')
   } */
   return(1);
}
/**
 * Converts selection into multiple cursors at the end of each line
 *
 * @see select_char
 * @see select_line
 * @see select_block
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
_command void convert_to_multiple_cursors_at_end_line()  name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // Ctrl+LButtonDown. Create multiple cursors at end of each line
   if (_MultiCursor()) {
      _MultiCursorClearAll();
   }
   // Save the original cursor position only to try to preserve some scroll information
   // when done.
   save_pos(auto p);
   _begin_select();
   _str b,e;
   _begin_line();b=_nrseek();
   _end_select();
   _begin_line();e=_nrseek();
   _deselect();

   _nrseek(b);
   last := "";
   for (;;) {
      if (!(_lineflags()&NOSAVE_LF)) {
         _TruncEndLine();_MultiCursorAdd();
         last=_nrseek();
      }
      int status=down();
      _begin_line();
      if ( status || _nrseek()>e) {
         break;
      }
   }
   restore_pos(p);
   if (last!='') {
      _nrseek(last);
   }
}
/**
 * Sets the cursor position to the mouse location.  Click and drag to 
 * character-select the text with this command. While dragging the mouse, you 
 * may use the right button to change the selection type to BLOCK, LINE, or CHAR  
 * The <i>select_type</i> parameter specifies the selection type and may be 
 * "CHAR", "LINE", or "BLOCK" and defaults to "CHAR".  The 'E' specifies that 
 * the current selection (if one exists) be extended to the mouse pointer 
 * instead of a new selection being created  This command is intended to be 
 * bound to a mouse button event.
 * 
 * @see mou_click_block
 * @see mou_click_line
 * @see mou_select_line
 * @see mou_extend_selection
 * @see mou_select_word
 * @see mou_click_menu
 * @see mou_click_menu_block
 * @see mou_click_menu_line
 * 
 * @appliesTo Text_Box, Edit_Window, Editor_Control
 * 
 * @categories Mouse_Functions
 * 
 */
_command int mou_click(_str mark_name="",
                       _str option="",  /* C, M, or E  == Copy, Move, Extend */
                       bool select_words=false,
                       int arg_add_cursor=0) name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_NOEXIT_SCROLL)
{
   ename := event2name(last_event());

   // Hex mode does not support multiple cursors
   if (p_hex_mode || _isdiffed(p_buf_id) || !def_multi_cursor_click) {
      arg_add_cursor=0;
   }
   allow_url_click := ename:=='C-LBUTTON-DOWN' || ename:=='M-LBUTTON-DOWN';
   orig_goverURL:=goverURL;
   if (allow_url_click && goverURL) {
      arg_add_cursor=0;
   }
   add_cursor := (arg_add_cursor==1)? 1:0;
   mark_name=upcase(mark_name);
   if (pos('-DOWN',ename) || pos('-UP',ename)) {
      gmulti_cursor_count=_MultiCursorCount();
      gmuti_cursor_count_time=_time('b');
   } else {
      // IF we added a cursor AND it was added in the last 1/2 second
      if (gmulti_cursor_count<_MultiCursorCount() &&
          gmuti_cursor_count_time!='' && ((typeless)_time('b')-gmuti_cursor_count_time)<500) {
         add_cursor=(arg_add_cursor==1)?2:0;
      }
   }
#if !MULTI_CURSOR_SUPPORTS_BLOCK_MARK
   if (mark_name=='BLOCK' && _MultiCursor()) {
      _MultiCursorClearAll();
      _deselect();
   }
#endif
   mark_locked := 0;
#if 0
   if (_select_type('','S')=='C') {
      say('mou_click');
      mark_locked=1;
      _select_type('','S','E');
      stop();
   }
#endif
   copytext_option := upcase(option)=='C';
   menu_option := upcase(option)=='M';
   extend_mark_option := upcase(option)=='E';

   // If we are extending the selection and last cua selection was a word selection.
   if (extend_mark_option && _cua_select==2) {
      select_words=true;
   }
   _str start_event=last_event();
   lastkey_not_rbutton := ! any_rbutton(last_event());
   if ( command_state() ) {
      // Assume that retrieve_prev_form/next_form called
      int view_id;
      get_window_id(view_id);
      activate_window(VSWID_RETRIEVE);
      bottom();
      activate_window(view_id);
      if (_default_option(VSOPTION_APIFLAGS)&0x80000000 || p_window_id != _cmdline) {
         mou_command_click(extend_mark_option);
      }
      return(1);
   }
   if (!add_cursor) {
      _MultiCursorClearAll();
   }
   // Mapping coordinates under UNIX is VERY VERY slow.
   // Here were reduce the number of calls a lot by getting the mouse
   // coordinates relative the screen and mapping top left corner of
   // client window.
   int mx=mou_last_x('D');
   int my=mou_last_y('D');
   wx := wy := 0;
   _map_xy(p_window_id,0,wx,wy);
   mx-=wx;my-=wy;

   if (p_mdi_child && p_window_state=='I') {
      if (extend_mark_option) return(2);
      //mou_create_window();
      return(3);
   }

   // When they click the mouse in an editor control
   // shut down all codehelp and other tooltips so they
   // do not get in the way of menus or selections. 
   _KillMouseOverBBWin();
   XW_TerminateCodeHelp();
   AutoCompleteTerminate();

   typeless orig_pos;
   save_pos(orig_pos);
   mark_locked=0;
   if (!extend_mark_option) {
      if (_select_type('','S')=='C') {
         mark_locked=1;
         _select_type('','S','E');
      }
   }

   if (!extend_mark_option && !mou_in_window()) {
      if (_isEditorCtl()) {
         //say('mx='mx);
         //say('l='p_LCIndentX+p_line_numbers_len*p_font_width);
         //say('p_font_width='p_font_width);
         if (_LCIsReadWrite() &&
             mx<p_LCIndentX+p_line_numbers_len*p_font_width ) {
            if ( _select_type('','u')=='' ) _deselect();
            if (p_scroll_left_edge>=0) {
               _scroll_page('r');
            }
            p_cursor_y=my;
            int col=(mx-p_LCIndentX+p_font_width intdiv 2) intdiv p_font_width;
            p_LCCol=col+1;
            p_LCHasCursor=true;
            return(4);
         }
         if (p_LCHasCursor) {
            p_LCHasCursor=false;
         }
         save_pos(auto p);
         if(!mou_debugbitmap(1+((select_words)?1:0),start_event)) {
            if (mark_locked) {
               _select_type('','S','C');
            }
            return(4);
         }
         restore_pos(p);
      }
   }

   if (p_LCHasCursor) {
      p_LCHasCursor=false;
   }

   if (!extend_mark_option && def_seldisp_single && (!mou_in_window())) {
      if (_isEditorCtl()) {
         if (p_scroll_left_edge>=0) {
            _scroll_page('r');
         }
         if (_select_type('','u')=='') {
            _deselect(); mark_locked = 0;
         }
         if(!mou_plusminus()) {
            if (mark_locked) {
               _select_type('','S','C');
            }
            return(4);
         }
      }
   }


   if (_macro()) {
      _message_box('You cannot select text with the mouse while macro recording');
      return 1;
   }
   init_mark := ! extend_mark_option || ! select_active();

   /*int orig_col=0;
   if (extend_mark_option && !init_mark) {
      save_pos(auto p);
      say('got here');
      if (substr(_select_type('','p'),1,1)=='B') {
         _begin_select();
      } else {
         _end_select();
      }
      orig_col=p_col;
      restore_pos(p);
   } */
   _str old_scroll_style=_scroll_style();
   _scroll_style('s 0');
   if ( command_state() ) {
      cursor_data();
   }
   _str persistant=(def_persistent_select=='Y')?'P':'';
   //mstyle='CN'persistant;
   _str mstyle;
   if ( pos('C',def_select_style) && def_persistent_select!='Y' ) {
      mstyle='CN';
   } else {
      mstyle='EN';
   }
   in_left_margin := 0;
   use_char_for_line_select := false;
   if ( mark_name=='' ) {
      if (!extend_mark_option && mx<_adjusted_windent_x()) {
         in_left_margin=1;
         mark_name='LINE';
         if (def_wpselect_flags&VS_WPSELECT_MOU_CHAR_LINE && p_hex_mode!=HM_HEX_ON) {
            use_char_for_line_select=true;
         }
      } else if (!def_select_type_block) {
         mark_name='CHAR';
      } else {
         mark_name='BLOCK'; 
      }
   }
   first_word_start_offset := 0;
   first_word_end_offset := 0;
   //bool was_in_selection;
   pending_deselect := false;
   if ( extend_mark_option ) {
      if (p_scroll_left_edge>=0) {
         if (extend_mark_option && !select_active()) {
            _deselect();
            if (select_words) {
               select_whole_word();
            } else {
               select_it(mark_name,'','CN');
            }
         }
         _scroll_page('r');
      }
      if (_MultiCursor()) {
         _MultiCursorClearAll();
      }
      if ( select_active() ) {
         mark_name=_select_type();
      } else {
         _deselect();
         if (select_words) {
            select_whole_word();
         } else {
            select_it(mark_name,'','CN');
         }
      }
      if (select_words) {
         set_first_word_offsets(first_word_start_offset,first_word_end_offset);
         select_more_words(first_word_start_offset,first_word_end_offset,mstyle,mx,my);
      } else {
         p_cursor_y=my;
         p_cursor_x=mx;
         select_it(mark_name,'','CN');
      }
      //was_in_selection=mou_in_selection(mou_last_x(),mou_last_y());
   } else {
      //was_in_selection=mou_in_selection(mou_last_x(),mou_last_y());
      if (add_cursor==1) {
         if (mark_locked) {
            _select_type('','S','C');
            _MultiCursorAdd();
            _select_type('','S','E');
         } else {
            _MultiCursorAdd();
         }
         // Would like to call _deselect() here but this will mess up the mou_in_selection() 
         // call below. Just leave the selection alone for a little while longer.
         pending_deselect=true;
         mark_locked=0;
      }
      if (p_scroll_left_edge>=0) {
         _scroll_page('r');
      }
      p_cursor_y=my;
      p_cursor_x=mx;
   }
   if (!add_cursor && _MultiCursor()) {
      _MultiCursorClearAll();
   }
   // Don't allow selecting a block when in hex mode.
   // Block selections are not visible in hex mode and
   // typing a key will insert characters for the block
   if (mark_name=='BLOCK' && p_hex_mode) {
      return(0);
   }
   movecopy_selection=0;

   // maybe we want to drag and drop some text
   if (!select_words && def_dragdrop && !in_left_margin && p_hex_mode!=HM_HEX_ON && !extend_mark_option && !menu_option &&
      mou_in_selection(mou_last_x(),mou_last_y())) {
      // Need to disable vi_correct_visual_mode_timer() so it doesn't move/modify the
      // selection during drag/drop.
      _vi_enable_correct_visual_mode=false;
      status:=_mou_click_handle_drag_drop(mx,my,wx,wy,mark_name,mstyle,select_words,menu_option,mark_locked,first_word_start_offset,first_word_end_offset,lastkey_not_rbutton,orig_pos,old_scroll_style,copytext_option);
      _vi_enable_correct_visual_mode=true;
      return status;
   //} else if (option=="C" && add_cursor && select_active2() && !select_words && p_hex_mode!=HM_HEX_ON && !extend_mark_option && !menu_option && !mou_in_selection(mou_last_x(),mou_last_y())) {
   //   create_multiple_cursors_at_end();
    //  return 0;
   }
   if (pending_deselect) {
      _deselect();
   }

   if (!select_words /*&& def_dragdrop */&&
       !extend_mark_option &&
       menu_option
       /*&& mou_in_selection(mou_last_x(),mou_last_y()) */
      ) {
      if (machine()=='WINDOWS' && _win32s()!=1) {
         if (!_isDragDrop(mx,my)) {
            if (mark_locked) {
               _select_type('','S','C');
            }
            _MultiCursorClearAllIfOtherBuffer();
            _deselect();
            if (!def_click_past_end) {
               if (p_col>_text_colc()) _end_line();
            }
            if (def_jmp_on_tab) {
               align_to_nearest_char();
            }
            _scroll_style(old_scroll_style);
            return(0);
         }
      }
   }
   if (mark_locked) {
      _select_type('','S','C');
   }


#if 0
   if (!(select_words && extend_mark_option)) {
      p_cursor_y=my;
      p_cursor_x=mx;
   }
#endif
   if (!def_click_past_end && _select_type()!='BLOCK' && mark_name!='BLOCK') {
      if (p_col>_text_colc()) _end_line();
   }
   if (def_jmp_on_tab && _select_type()!='BLOCK' && mark_name!='BLOCK') {
      align_to_nearest_char();
   }
   mou_mode(1);
   mou_release();mou_capture();
   _MultiCursorClearAllIfOtherBuffer();
   if ( ! extend_mark_option ) {
      // IF this is a mark start with shift-arrow keys or mouse and */
      // marks are not persistant  OR  menu_option given
      if ( (_cua_select && def_persistent_select!='Y') || menu_option
         // OR the mark is a locked persistant mark
         // || (! _cua_select && _select_type('','U')=='P' && _select_type('','s')=='E')
      ) {
         _deselect();
      }
   }
   if (init_mark && select_words) {
      select_whole_word(mstyle);
      init_mark=false;
      _cua_select=2;   // Indicate that we are in word select mode. Need to know this
                       // so Shift+LbuttonDown extends selection using words.
   }

   // If it's a new line selection, go ahead and make it
   // visible, without having to wait for next LBUTTONUP or MOUSE_MOVE
   if (init_mark && mark_name == "LINE") {
      select_it(mark_name,'',mstyle);
   }

   if (select_words) {
      // Turn off cursor blink
      _default_option('k',0);
   }
   if (select_words) {
      set_first_word_offsets(first_word_start_offset,first_word_end_offset);
   }

   // Select block if dbl-click without any other mouse events.
   do_sel_blk := false;
   _default_option(VSOPTION_MULTI_CURSOR_AUTO_MERGE,0);
   _vi_enable_correct_visual_mode=false;
   for (;;) {
       typeless event=get_event('k');
       if( event :== WHEEL_DOWN || event :== WHEEL_UP || 
           event :== WHEEL_LEFT || event :== WHEEL_RIGHT || 
           event :== ON_VSB_PAGE_DOWN || event :== ON_VSB_PAGE_UP ) {

          // We know left mouse button is down too!
          if( event :== WHEEL_DOWN || event :== WHEEL_UP ) {
             int count = mou_wheel_scroll_lines();
             int i;
             for( i=0; i < count; ++i ) {
                fast_scroll();
             }
          } else {
             fast_scroll();
          }
          //last_event(ON_SB_END_SCROLL);
          //fast_scroll();
          event=MOUSE_MOVE;
       }
       if ( event:==MOUSE_MOVE ) {
          // This code has gotten more complicated to handle BLOCK marks and menus better
          old_init_mark := init_mark;
          if ( init_mark ) {
             init_mark=false;
             if (!extend_mark_option) {
                _deselect();
             }
             select_it(mark_name,'',mstyle);
          }
          // Mapping coordinates under UNIX is VERY VERY slow.
          // Here were reduce the number of calls a lot.
          mx=mou_last_x('D');my=mou_last_y('D');
          mx-=wx;my-=wy;
          if ( mou_in_window3(mx,my) ) {
             _SelectToCursor(mark_name,mstyle,mx,my,select_words,(typeless)movecopy_selection,first_word_start_offset,first_word_end_offset);
             if (old_init_mark) {
                //orig_col=p_col;
                _cua_select=1;
                last_index(find_index('cua-select',COMMAND_TYPE));
             }
          } else {
             if (old_init_mark) {
                //orig_col=p_col;
                _cua_select=1;
                last_index(find_index('cua-select',COMMAND_TYPE));
             }
             done := selectNscroll(mark_name,mstyle,lastkey_not_rbutton,mx,my,wx,wy,select_words,first_word_start_offset,first_word_end_offset);
             if ( done ) {
                break;
             }
          }
       } else if ( lastkey_not_rbutton && any_rbutton(event) && ! init_mark ) {
          if ( mark_name=='CHAR' ) {
             mark_name='BLOCK';
             switch_select_type(mark_name/*,'',orig_col*/);
          } else if ( mark_name=='BLOCK' ) {
             mark_name='LINE';
             switch_select_type(mark_name/*,'',orig_col*/);
          } else if ( mark_name=='LINE' ) {
             mark_name='CHAR';
             switch_select_type(mark_name/*,'',orig_col*/);
          }
       } else if ( lastkey_not_rbutton && event:==RBUTTON_UP ) {
       } else if ( _isMac() && event:==ON_TIMER ) {
       }
       else {
          // Set mark to check this condition later.
          do_sel_blk = (mark_name == 'CHAR' && option == '' && select_words);
          break;
       }
   }
   _vi_enable_correct_visual_mode=true;
   _default_option(VSOPTION_MULTI_CURSOR_AUTO_MERGE,1);
   if (select_words) {
      // Turn on cursor blink
      _default_option('k',1);
      // Maybe unlock selection
      select_it(mark_name,'',mstyle);
   }
   if (_isnull_selection()) {
      _cua_select=1;
      _deselect();
      if (!def_click_past_end) {
         if (p_col>_text_colc()) _end_line();
      }
      if (def_jmp_on_tab) {
         align_to_nearest_char();
      }
   } else if (use_char_for_line_select) {
      int dupcur_markid=_duplicate_selection();
      _deselect();
      // Switch this selection to be a line selection.
      if (_begin_select_compare(dupcur_markid)>=0) {
         _begin_select(dupcur_markid);p_col=0;
         select_it('CHAR','',mstyle);
         _end_select(dupcur_markid);_TruncEndLine();++p_col;
         select_it('CHAR','',mstyle);
      } else {
         _end_select(dupcur_markid);_TruncEndLine();++p_col;
         select_it('CHAR','',mstyle);
         _begin_select(dupcur_markid);p_col=0;
         select_it('CHAR','',mstyle);
      }
      _free_selection(dupcur_markid);
   }
   _autoclipboard();
   mou_mode(0);
   mou_release();
   _scroll_style(old_scroll_style);
   if (allow_url_click && orig_goverURL) {
      vi_correct_visual_mode();
      _UpdateURLsMousePointer(false);
      return maybeOpenURL();
   }

   // Automatically select the matching paren
   if (!do_sel_blk || !select_active()) {
      vi_correct_visual_mode();
      if (arg_add_cursor==2) {
         _MultiCursorAddFromActiveSelection();
      } else if (!select_words && arg_add_cursor==0) {
         wid:=_find_formobj('_color_form','N');
         if (wid!=0) {
            cfg := _clex_find(0, 'D');
            wid.selectColor(cfg);
         }
      }
      return (0);  // nothing to do
   }

   typeless junk;
   start_col := end_col := lines := 0;
   _get_selinfo(start_col, end_col, junk, '', junk, junk, junk, lines);
   if (_select_type('') != 'CHAR' || lines != 1 || (end_col - start_col) != 1) {
      vi_correct_visual_mode();
      return (0);  // not the right selection length or type
   }

   left();
   text := get_text(1);
   right();

   sel_forward  := (pos(text,"([{") != 0);
   sel_backward := (pos(text,")]}") != 0);
   if (!sel_forward && !sel_backward) {
      vi_correct_visual_mode();
      return (0);  // not at the parenthesis
   }

   save_pos(auto p);
   if (find_matching_paren(true) != 0) {
      restore_pos(p);
      return (0);  // no matching parenthesis
   }
   _deselect();
   if (sel_forward) right();
   select_it('CHAR','',mstyle);

   restore_pos(p);
   if (sel_forward) {
      left();
   }
   select_it('CHAR', '', mstyle);
   vi_correct_visual_mode();

   return(0);
}

/** 
 * Create multiple cursors from the keyboard or from an existing selection. 
 * <p> 
 * To use this, bind it to a key, then when you want to create a set of 
 * cursors, start with the first cursor location, invoke this command, then 
 * move the cursor to the next location and invoke the command again, then move 
 * the cursor again and invoke this command, etc..  Multiple cursors will be 
 * created  as you move along creating additional cursors. 
 * <p> 
 * Note: in intermediate stages, you will have created multiple cursors and 
 * they will all track along with the cursor as you move around to create other 
 * cursors.  This can be confusing, but keep in mind that they all reset to 
 * the original locations where they were located when you add a cursor. 
 * <p>
 * By default, this command is bound to Ctrl+| (vertical bar). 
 *  
 * @see mou_click() 
 * @see add_multiple_cursor_down 
 * @see add_multiple_cursor_up 
 * @since 19.0.2 
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */ 
_command int add_multiple_cursors(_str mark_name="") name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_NOEXIT_SCROLL)
{
   // Keeps track of where cursors where set at
   static typeless gCursorPos[];
   static typeless gLastModified;

   // Maybe reset multi-cursors for block selection
   mark_name=upcase(mark_name);
#if !MULTI_CURSOR_SUPPORTS_BLOCK_MARK
   if (mark_name=='BLOCK' && _MultiCursor()) {
      _MultiCursorClearAll();
      _deselect();
      gCursorPos._makeempty();
   }
#endif

   // Do not add multiple cursors to the SlickEdit comand line
   if ( command_state() ) {
      return(1);
   }

   // Do not add multiple cursors to window in iconized state
   if (p_mdi_child && p_window_state=='I') {
      return(2);
   }

   // Do not add multiple cursors in the editor margin
   if (p_LCHasCursor) {
      message("You cannot set multiple cursors in the editor margin.");
      return(3);
   }

   // Do not add cursors while recording macros
   if (_macro()) {
      message("You cannot create cursors with while macro recording");
      return(4);
   }

   // If the buffer has been modified reset cursors
   firstCursor := (_MultiCursor()==0);
   if (!firstCursor && p_LastModified != gLastModified) {
      message("Resetting multi-cursors because buffer was modified.");
      _MultiCursorClearAll();
      gCursorPos._makeempty();
   }

   // Is this the first cursor marked?
   if (firstCursor && gCursorPos._length()!=1) {
      gCursorPos._makeempty();
      gLastModified = p_LastModified;
   }

   // Add the cursor to the end of the list
   save_pos(gCursorPos[gCursorPos._length()]);

   // Check if there is a selection to create multiple cursors from
   if (_select_type('','S')=='C' || _select_type('','S')=='E') {
      gCursorPos._makeempty();
      _MultiCursorClearAll();
      _MultiCursorAddFromActiveSelection();
      _select_type('','S','E');

   } else if (gCursorPos._length() > 1) {
      // Reset all the cursors
      _MultiCursorClearAll();
      for (i:=0; i<gCursorPos._length(); i++) {
         restore_pos(gCursorPos[i]);
         _MultiCursorAdd();
      }
   }

   // That's all folks
   return(0);
}
/**
 * Add another cursor below the current cursor location.
 * <p>
 * By default, this command is bound to Ctrl+Alt+Shift+Down
 *  
 * @see mou_click() 
 * @see add_multiple_cursors
 * @see add_multiple_cursor_up
 * @since 20.0.0
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void add_multiple_cursor_down() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_NOEXIT_SCROLL)
{
   // initiate multiple cursors if we are not already in multi-cursor mode
   if (_MultiCursor()==0) {
      add_multiple_cursors();
   }
   // move cursor down and add a cursor
   cursor_down();
   add_multiple_cursors();
}
/**
 * Add another cursor above the current cursor location.
 * <p>
 * By default, this command is bound to Ctrl+Alt+Shift+Up
 *  
 * @see mou_click() 
 * @see add_multiple_cursors
 * @see add_multiple_cursor_down
 * @since 20.0.0
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void add_multiple_cursor_up() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_NOEXIT_SCROLL)
{
   // initiate multiple cursors if we are not already in multi-cursor mode
   if (_MultiCursor()==0) {
      add_multiple_cursors();
   }
   // move cursor up and add a cursor
   cursor_up();
   add_multiple_cursors();
}

static void parseFileURL(_str inURL, _str& cmd, _str& ext, _str& args)
{
   fullPath := "";
   fullPath = substr(inURL, 8); //the 8th character is the one after 'file://'
   fullPath = stranslate(fullPath, ' ', '%20');

   fileName := _strip_filename(fullPath, 'P');

   parse fileName with '.' ext;

   parse ext with ext args;

   cmd = substr(fullPath, 1, length(fullPath)-length(args));
   cmd = strip(cmd);
}
static int maybeOpenURL ()
{
   status := 0;
   if (pos("file://", gURL) == 1) {
      cmd := "";
      ext := "";
      args := "";
      parseFileURL(gURL, cmd, ext, args);

      useFA := ExtensionSettings.getUseFileAssociation(ext);
      appCmd := ExtensionSettings.getOpenApplication(ext);

      if (!useFA && (appCmd != "")) {
         fileName := _maybe_quote_filename(cmd' 'args);
         appCmd =  _parse_project_command(appCmd, fileName, '', '');
         if (shell(appCmd, 'ap') >= 0) {
            return(0);
         }
      }

      if (_isWindows()) {
         // Note: ShellExecute returns a value greater than 32 on success.
         status = _ShellExecute(cmd, null, args);
         if (status >=0) {
            return(0);
         }
      }
   } else {
      if (_isWindows()) {
         status = _ShellExecute(gURL, null);
         if (status >=0) {
            return(0);
         }
      }
   }

   return goto_url(gURL);
}
static void set_first_word_offsets(int &first_word_start_offset,int &first_word_end_offset)
{
   save_pos(auto p);
   _begin_select('',false);
   first_word_start_offset=_nrseek();
   vcpp_goto_end_curword();
   first_word_end_offset=_nrseek();
   restore_pos(p);
}
static void vcpp_goto_end_curword()
{
   past_eol := (p_col>_text_colc());
   cursor_position_set := false;
   if( past_eol) {
      _end_line();++p_col;
      cursor_position_set=true;
   }
   if (!cursor_position_set) {
      // -1 gets the current SBCS/DBCS or Unicode char
      ch := get_text(-1);
      if( _isSpaceChar(ch)) {
         search('[~'def_space_chars']','r@');
      } else {
         // Search for end of word.
         word_chars := _extra_word_chars:+p_word_chars;
         if( pos('[\od'word_chars']',ch,1,'r') || _dbcsIsLeadByteBuf(get_text_raw()) ) {
            search('[~\od'word_chars']|$','re@');
         } else {
            search('[\od \t'word_chars']|$','re@');
         }
      }
   }
}
static void select_more_words(int first_word_start_offset,int first_word_end_offset,_str mstyle, int new_x,int new_y,
                              bool past_bottom=false,bool past_right=false,
                              bool past_top=false,bool past_left=false
                              )
{
   int start_col,end_col,buf_id;
   _get_selinfo(start_col,end_col,buf_id);
   int cur_offset=_nrseek();
   bool1 := (_begin_select_compare()==0 && p_col==start_col);
   typeless p,p2;
   status := 0;
   save_pos(p);
   // Try to extend word selection
   _select_char('','EN');  // lock the selection so we can compare selection
                           // to cursor position
   if (new_y>=0) {
      p_cursor_y=new_y;
      p_cursor_x=new_x;
   }
   search_direction := '+';
   search_direction2 := '-';
   if (past_top || (past_left && !past_bottom)) {
      search_direction='-';
      search_direction2='+';
   }
   // IF cursor is after start of first word
   if (cur_offset>first_word_start_offset) {
      save_pos(p2);
      _nrseek(first_word_start_offset);
      _deselect();_select_char('','EN');
      restore_pos(p2);
      if (new_y>=0 && new_x<_adjusted_windent_x()) {
         p_col=1;
      } else {
         vcpp_goto_end_curword();
      }
      _select_char('',mstyle);
   } else {
      // cursor is before start of first word
      save_pos(p2);
      _nrseek(first_word_end_offset);
      _deselect();_select_char('','EN');
      restore_pos(p2);

      if (p_col>_text_colc()) {
         _end_line();
      } else {
         ch := get_text(-1);
         if (_isSpaceChar(ch)) {
            search('['def_space_chars']#','@R-');
         } else {
            word_chars := _extra_word_chars:+p_word_chars;
            do_word := pos('[\od'word_chars']',ch,1,'r') || ((p_UTF8 == 0) && _IsLeadByteBuf(get_text_raw()));
            if (do_word) {
               if (p_UTF8) {
                  search('{(['word_chars']#)|^}','@r-'); /* rev2a */
               } else {
                  search('{([\od]|['word_chars']#)|^}','@r-'); /* rev2a */
               }
            } else {
               if (p_UTF8) {
                  search('{([~'def_space_chars:+word_chars']#)|^}','@r-'); /* rev2a */
               } else {
                  search('{([~\od]|[~'word_chars']#)|^}','@r-'); /* rev2a */
               }
            }
         }
      }
      _select_char('',mstyle);
   }
}
void _SelectToCursor(_str mark_name,_str mstyle,int new_x,int new_y,bool select_words,
                     bool movecopy_selection,int first_word_start_offset=0,int first_word_end_offset=0,
                     bool past_bottom=false,bool past_right=false,
                     bool past_top=false,bool past_left=false)
{
   if (p_scroll_left_edge>=0) {
      _scroll_page('r');
   }
   if (p_hex_mode==1) {
      old_field := p_hex_field;
      p_cursor_y=new_y;
      p_cursor_x=new_x;
      // This move cursor to end of buffer if y position is past last hex line.
      p_cursor_y=new_y;
      if (!_on_line0()) {
         if (!movecopy_selection) select_it(mark_name,'',mstyle);
      }
      if (!p_hex_field && old_field) {
         p_cursor_x=0x7fffffff;
      } else if (p_hex_field && !old_field) {
         p_cursor_x=0;
      }
      p_hex_field=old_field;
      p_hex_nibble=false;
      return;
   }
   if (select_words) {
      select_more_words(first_word_start_offset,first_word_end_offset,mstyle,new_x,new_y,past_bottom,past_right,past_top,past_left);
      return;
   }
   int y=new_y;
   old_cursor_y := p_cursor_y;
   old_cursor_x := p_cursor_x;
   p_cursor_y=y;
   p_cursor_x=new_x;
   if (movecopy_selection && p_cursor_x==old_cursor_x && p_cursor_y==old_cursor_y) {
      // Avoid some extra cursor refreshes so the mouse pointer
      // does not blink as much during a drag drop operation.
      // p_cursor_y and p_cursor_x are optimized so that the cursor
      // is redrawn only if it moved.
      return;
   }
   if (!def_click_past_end && _select_type()!='BLOCK') {
      if (p_col>_text_colc()) _end_line();
   }
   if (def_jmp_on_tab && _select_type()!='BLOCK') {
      align_to_nearest_char();
   }
   typeless p;save_pos(p);
   int down_rc=down();
   if ( ! down_rc ) {
      restore_pos(p);
   }
   // When multiple fonts are supported, want the font height
   // of the current line, and not the average font height.
   if ( y>=p_cursor_y+p_font_height && down_rc ) {
      cursor_x := p_cursor_x;
      end_line();
      if ( ! p_buf_width ) {
         p_col++;
      }
      if ( p_cursor_x<cursor_x ) {
         p_cursor_x=cursor_x;
      }
   }
   if( !_on_line0() && !movecopy_selection ) {
      select_it(mark_name,'',mstyle);
      if( _WPSelectIsNewlineSelectionCase('',true) ) {
         // Select newline chars at end of last line of selection.
         // See the comment on VS_WPSELECT_NEWLINE if you do not
         // understand what is going on here.
         // Change to inclusive CHAR selection so that we include the
         // newline chars.
         _select_type('','I',1);
      }
   }

}
/**
 * Set the scroll directions based on the position of the
 * mouse relative to the current window.
 * 
 * @param past_bottom      Set to 'true' if the mouse is below the window
 * @param past_right       Set to 'true' if the mouse is to the right of the window
 * @param past_top         Set to 'true' if the mouse is above the window
 * @param past_left        Set to 'true' if the mouse is to the left of the window
 * @param new_x            Set to horizontal position bounding the mouse within the window
 * @param new_y            Set to vertical position bounding the mouse within the window
 * @param mx               Horizontal position of mouse
 * @param my               Vertical position of mouse
 * 
 * @categories Mouse_Functions
 */
void mou_set_scroll_directions(int &past_bottom, int &past_right,
                               int &past_top,    int &past_left,
                               int &new_x, int &new_y, int mx, int my)
{
   new_x=mx;
   new_y=my;
   past_bottom=0;past_right=0;past_top=0;past_left=0;
   if ( my>=p_client_height ) {
      past_bottom=1;
      new_y=p_client_height; /* -1 */
   }
   if ( mx>=p_client_width ) {
      past_right=1;
      new_x=p_client_width-1;
   }
   if ( my<0 ) {
      past_top=1;
      new_y=0;
   }
   if ( mx<_adjusted_windent_x() ) {
      past_left=1;
      new_x=0;
   }
}

/**
 * Changes the left edge scroll position by half the window width to the 
 * right.  The cursor is moved half the window width to the right as well.
 * 
 * @see page_up
 * @see page_down
 * @see page_left
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void page_right() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   int width;
   if (p_fixed_font) {
      width=p_char_width intdiv 2;
   } else {
      width=p_client_width intdiv 2;
   }
   cursor_x := p_cursor_x;
   int left_edge=p_left_edge+width;
   set_scroll_pos(left_edge,p_cursor_y);
   if (p_object!=OI_LIST_BOX && p_fixed_font) {
      p_cursor_x=cursor_x*p_font_width;
   } else {
      p_cursor_x=cursor_x;
   }

}
/**
 * Changes the left edge scroll position by half the window width to the 
 * left.  The cursor is moved half the window width to the left as well.
 * 
 * @see page_up
 * @see page_down
 * @see page_right
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command void page_left() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   int width;
   if (p_fixed_font) {
      width=(p_char_width intdiv 2);
   } else {
      width=p_client_width intdiv 2;
   }
   cursor_x := p_cursor_x;
   int left_edge=p_left_edge-width;
   if ( left_edge<0 ) {
      cursor_x -= width;
   }
   if (left_edge<0) left_edge=0;
   p_cursor_x=0;
   set_scroll_pos(left_edge,p_cursor_y);
   p_cursor_x=cursor_x;
   /*
   if (p_object!=OI_LIST_BOX && p_fixed_font) {
      ix=(cursor_x-_adjusted_windent_x()) intdiv p_font_width;
      p_cursor_x=_adjusted_windent_x()+(ix)*p_font_width;
      //say('h2 cursor_x='cursor_x' c='p_cursor_x);
   } else {
      p_cursor_x=cursor_x;
   }
   */
}
/*
   Returns 'true' if any right button down events happens

*/
static _str any_rbutton(typeless event)
{
   return(
   event:==RBUTTON_DOWN || event:==RBUTTON_DOUBLE_CLICK ||
              event:==RBUTTON_TRIPLE_CLICK ||
   event:==name2event('a-rbutton_down') || event:==name2event('a-rbutton_double_click') ||
              event:==name2event('a-rbutton_triple_click') ||
   event:==name2event('c-rbutton_down') || event:==name2event('c-rbutton_double_click') ||
              event:==name2event('c-rbutton_triple_click') ||
   event:==name2event('s-rbutton_down') || event:==name2event('s-rbutton_double_click') ||
              event:==name2event('s-rbutton_triple_click')
              );
}
// checks whether mouse is in client area of window
static _str mou_in_window2(int mx,int my)
{
   return(mx>=0 && mx<p_client_width &&
          my>=0 && my<p_client_height);

}
/** 
 * @return Returns a non-zero value if the last mouse position read by 
 * <b>get_event</b>() or <b>test_event</b>() is within the current window.
 * 
 * Use only in edit window.  Checks whether mouse is in text area
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Mouse_Functions
 * 
 */
_str mou_in_window()
{
   int mx=mou_last_x('D');
   int my=mou_last_y('D');
   _map_xy(0,p_window_id,mx,my);
   return(mx>=_adjusted_windent_x() && mx<p_client_width &&
          my>=0 && my<p_client_height);
}
//
// This function is here only because mapping window coordinates
// under X windows is extremely slow.
//
static bool mou_in_window3(int mx,int my)
{
   return(((mx>=_adjusted_windent_x() || p_left_edge==0) && (mx<p_client_width || p_SoftWrap)) &&
          my>=0 && my<p_client_height);

}

/**
 * Selects the current line with a line type selection.
 * 
 * @see mou_click
 * @see mou_click_block
 * @see mou_select_line
 * @see mou_click_line
 * @see mou_select_word
 * 
 * @categories Mouse_Functions
 * 
 */
_command void mou_select_line() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   /*if (_isEditorCtl() && !mou_in_window()) {
      return;
   } */

   int cmd_state = command_state();

   if (!cmd_state && _macro()) {
      _message_box('You cannot select text with the mouse while macro recording');
   }
   if (p_object!=OI_TEXT_BOX) {
      // X Windows is slow at mapping window coordinates
      int mx=mou_last_x('D');
      int my=mou_last_y('D');
      _map_xy(0,p_window_id,mx,my);
      p_cursor_x=mx;
      p_cursor_y=my;
   }
   init_command_op();
#if 0
   if ( ! mou_in_window() ) {
      check_other_areas();
      return(1);
   }
#endif
   if (p_hex_mode==HM_HEX_ON && p_hex_field) {
     hex_select_line();
   } else {
      
      _deselect();
      if (cmd_state) {
         _select_line("");
      } else {
         _cua_select = 1;
         mou_click("LINE", "", false);
      }
      _autoclipboard();
     
   }
   retrieve_command_results();
   // Make sure selection will be extended when click mouse in another
   // window.
   if (!command_state()) {
      if (pos('C',def_select_style) && def_persistent_select!='Y') {
         mstyle := "CN";
         select_it('LINE','',mstyle);
      }
      if (!def_click_past_end) {
         if ( p_col > _text_colc() ) _end_line();
      }
   }
}
#if 0
/*
*/
int _on_DebugBitmapClick(int wid,int flags,int NofClicks)
{
   say('Nofclicks='NofClicks);
   return(flags?0:1);
}
#endif
static int mou_debugbitmap(int NofClicks,_str event)
{
   // X Windows is slow at mapping window coordinates
   int mx=mou_last_x('D');
   int my=mou_last_y('D');
   _map_xy(0,p_window_id,mx,my);
   p_cursor_x=mx;
   p_cursor_y=my;
   status := 1;
   // IF we are in the left margin
   int pm = _lineflags()&(PLUSBITMAP_LF|MINUSBITMAP_LF);
   if(mou_last_x()<_adjusted_windent_x()) {
      if (NofClicks == 1) {
         if (index_callable(find_index('_LineMarkerExecuteMouseEvent',PROC_TYPE))) {
            typeless LineOffset;
            parse point() with LineOffset .;
            status=_LineMarkerExecuteMouseEvent(p_window_id,(typeless)point('L'),LineOffset,event);
         } else {
            status=1;
         }
      } else if (NofClicks==2 && pm!=PLUSBITMAP_LF && pm!=MINUSBITMAP_LF && _haveDebugging()){
         return(debug_toggle_breakpoint());
      }
   }
   return(status);
}
static int mou_plusminus()
{
   // X Windows is slow at mapping window coordinates
   int mx=mou_last_x('D');
   int my=mou_last_y('D');
   _map_xy(0,p_window_id,mx,my);
   p_cursor_x=mx;
   p_cursor_y=my;
   status := 1;
   // IF we are in the left margin
   if(mou_last_x()<_adjusted_windent_x()) {
      status=plusminus('M');
   }
   return(status);
}
/**
 * Selects the current word with a character type selection.
 * 
 * @see mou_click
 * @see mou_click_block
 * @see mou_select_line
 * @see mou_click_line
 * @see mou_select_word
 * @see mou_select_line
 * @see mou_select_word
 * @see mou_click_copy
 * @see mou_move_to_cursor
 * 
 * @appliesTo Edit_Window, Editor_Control, Text_Box
 * 
 * @categories Mouse_Functions
 * 
 */
_command void mou_select_word_add_cursor() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL) {
   mou_select_word(1);
}
/**
 * Selects the current word with a character type selection.
 * 
 * @see mou_click
 * @see mou_click_block
 * @see mou_select_line
 * @see mou_click_line
 * @see mou_select_word
 * @see mou_select_line
 * 
 * @appliesTo Edit_Window, Editor_Control, Text_Box
 * 
 * @categories Mouse_Functions
 * 
 */
_command void mou_select_word(_str arg_add_cursor='',...) name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   int add_cursor=(arg_add_cursor=='1')?1:0;
   int was_command_state=command_state();
   if (!def_seldisp_single && (_isEditorCtl() &&  !mou_in_window())) {
      if(!mou_debugbitmap(2,last_event())) {
         return;
      }
      mou_plusminus();
      return;
   }
   if (!command_state() && _macro()) {
      _message_box('You cannot select text with the mouse while macro recording');
   }
   if (p_object==OI_TEXT_BOX) {
      mou_command_click(false,true);
      init_command_op();
   } else {
      if (p_hex_mode==HM_HEX_ON && p_hex_field) {
         // X Windows is slow at mapping window coordinates
         int mx=mou_last_x('D');
         int my=mou_last_y('D');
         _map_xy(0,p_window_id,mx,my);
         p_cursor_x=mx;
         p_cursor_y=my;
      }
   }
#if 0
   if ( ! mou_in_window() ) {
      check_other_areas();
      return(1);
   }
   p_cursor_x==mou_last_x();
   p_cursor_y==mou_last_y();
#endif
   if (p_hex_mode==HM_HEX_ON && p_hex_field) {
     hex_select_word();
     return;
   }
   if (was_command_state) {
      select_whole_word();
      _autoclipboard();
      retrieve_command_results();
   } else {
      mou_click('','',true,add_cursor);
   }
}
/**
 * Sets the cursor position to the mouse location and extends the 
 * selection to the cursor.  If no selection exists, the text between the old 
 * cursor position and the new cursor position is selected.  This command is 
 * intended to be bound to a mouse button event  
 * 
 * @see mou_click
 * @see mou_click_block
 * @see mou_select_line
 * @see mou_click_line
 * @see mou_select_word
 * 
 * @categories Mouse_Functions
 * 
 */
_command void mou_extend_selection() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   if (!command_state() && _macro()) {
      _message_box('You cannot select text with the mouse while macro recording');
   }
   mou_click('','E');

}
/**
 * Selects the text from the beginning to the end of the current word at 
 * the cursor.
 * 
 * @see select_word
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 * 
 */ 
_command void select_whole_word(...) name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _select_word_wp('0');

}
bool _isSpaceChar(_str ch)
{
   return(pos('['def_space_chars']',ch,1,'r')!=0);
}

static int _select_word_wp(...)
{
   typeless position;
   save_pos(position);
   bool do_word;

#if 0
   if (def_vcpp_word) {
#endif
      // VC++ style.  Selects words, spaces, DBCS character, 
      // or all non-word/none space  characters as word
      if (p_col>_text_colc()) {
         _end_line(); --p_col;
      }
      ch := get_text(-1);
      if (_isSpaceChar(ch)) {
         search('{['def_space_chars']#}','@R-');
      } else {
         word_chars := _extra_word_chars:+p_word_chars;
         do_word=pos('[\od'word_chars']',ch,1,'r') || ((p_UTF8 == 0) && _IsLeadByteBuf(get_text_raw()));
         if (do_word) {
            if (p_UTF8) {
               search('{(['word_chars']#)|^}','@r-'); /* rev2a */
            } else {
               search('{([\od]|['word_chars']#)|^}','@r-'); /* rev2a */
            }
         } else {
            // @Ding Zhaojie: Avoid selecting more than one parenthesis
            if (p_UTF8) {
               search('{([~\{\}\[\]\(\)'def_space_chars:+word_chars']#)|[\{\}\[\]\(\)]|^}','@r-'); /* rev2a */
            } else {
               search('{([~\od\{\}\[\]\(\)'def_space_chars:+word_chars']#)|[\{\}\[\]\(\)]|^}','@r-'); /* rev2a */
            }
         }
      }
#if 0
   } else {
      // Old code.  Selects words,DBCS character, or all non-word characters as word
      word_chars := _extra_word_chars:+p_word_chars;
      if ( p_col>_text_colc() ) {
         do_word=1;
      } else {
         ch := get_text(-1);
         if (def_vcpp_word) {
            do_word=_isSpaceChar(ch);
         } else {
            do_word=pos('[\od'word_chars']',ch,1,'r') || ((p_UTF8 == 0) && _IsLeadByteBuf(get_text_raw()));
         }
      }
      if ( do_word ) {
         blanks_re := "";
         if ( arg(1) ) {
            blanks_re='[ \t]@';
         }
         /* Search for beginning of word and match spaces at end of word*/
         if (p_UTF8) {
            search('{(['word_chars']#)'blanks_re'|^}','r-'); /* rev2a */
         } else {
            search('{([\od]|['word_chars']#)'blanks_re'|^}','r-'); /* rev2a */
         }
      } else {
         /* Search for beginning of word and match spaces at end of word*/
         if (p_UTF8) {
            search('{['word_chars']#|^}','r-'); /* rev2a */
         } else {
            search('{[~\od'word_chars']#|^}','r-'); /* rev2a */
         }
      }
   }
#endif
   if ( ! match_length() ) {
      restore_pos(position);
      message(nls('No word at cursor'));
      return(1);
   }
   _deselect();

   _select_char('','CN');
   goto_point(match_length('S0')+match_length());
   _select_char();
   restore_pos(position);
   _end_select();
   if ( pos('C',def_select_style) && def_persistent_select!='Y' ) {
      _select_char('','CN');
   } else {
      _select_char('','EN');
   }
   _cua_select=1;
   return(0);

}
/**
 * Sets the cursor position to the mouse location.  Click and drag to block 
 * (column) select text with this command. While dragging the mouse, you may use 
 * the right button to change the selection type to BLOCK, LINE, or CHAR  This 
 * command is intended to be bound to a mouse button event.
 * 
 * @see mou_click
 * @see mou_click_line
 * @see mou_select_line
 * @see mou_extend_selection
 * @see mou_select_word
 * @see mou_click_menu
 * @see mou_click_menu_block
 * @see mou_click_menu_line
 * 
 * @appliesTo Text_Box, Edit_Window, Editor_Control
 * 
 * @categories Mouse_Functions
 * 
 */
_command void mou_click_block() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_NOEXIT_SCROLL)
{
   if (!command_state() && _macro()) {
      _message_box('You cannot select text with the mouse while macro recording');
   }
   mou_click('block');

}
/** 
 * Sets the cursor position to the mouse location.  Click and drag to line-
 * select text with this command. While dragging the mouse, you may use the 
 * right button to change the selection type to BLOCK, LINE, or CHAR  This 
 * command is intended to be bound to a mouse button event.
 * 
 * @see mou_click
 * @see mou_click_block
 * @see mou_select_line
 * @see mou_extend_selection
 * @see mou_select_word
 * @see mou_click_menu
 * @see mou_click_menu_block
 * @see mou_click_menu_line
 * 
 * @appliesTo Text_Box, Edit_Window, Editor_Control
 * 
 * @categories Mouse_Functions
 * 
 */
_command void mou_click_line() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_NOEXIT_SCROLL)
{
   if (!command_state() && _macro()) {
      _message_box('You cannot select text with the mouse while macro recording');
   }
   mou_click('line');

}
static _str switch_select_type(_str type)
{
   if ( _select_type()=='' ) {
      return(1);
   }
   _select_type('','T',type);
   return(0);
}
void mou_command_click(bool extend_mark_option,bool just_set_cursor_pos=false)
{
   // X Windows is slow at mapping window coordinates
   wx := wy := 0;_map_xy(p_window_id,0,wx,wy);
   int mx=mou_last_x('D');mx-=wx;
   int my=mou_last_y('D');my-=wy;

   int pixel_x=mx;
   int pixel_y=my;
   int col;
   if (p_word_wrap) {
      col=mou_col2(pixel_x,pixel_y);
   }else{
      col=mou_col(pixel_x);
   }
   line := p_text;
   if (col-1>length(line)) {
      col=length(line)+1;
   }
   bool init_mark;
   int begin_col;
   if ( extend_mark_option ) {
      typeless junk;
      _get_sel(begin_col,junk);
      _set_sel(begin_col,col);
      init_mark=false;
   } else {
      init_mark=true;
      begin_col=col;
      _set_sel(begin_col);
   }
   if (just_set_cursor_pos) {
      return;
   }
   mou_mode(1);
   mou_release();mou_capture();
   for (;;) {
      typeless event;
      if (pixel_x<_adjusted_windent_x() && !p_word_wrap) {
         event=MOUSE_MOVE;
      } else {
         refresh('w');
         event=get_event('k');
      }
      if ( event:==MOUSE_MOVE ) {
         mx=mou_last_x('D');mx-=wx;
         my=mou_last_y('D');my-=wy;
         pixel_x=mx;
         pixel_y=my;
         int new_col;
         if (p_word_wrap) {
            new_col=mou_col2(pixel_x,pixel_y);
         }else{
            new_col=mou_col(pixel_x);
         }
         if (new_col-1>length(line)) {
            new_col=length(line)+1;
         }
         direction := 0;
         if (p_word_wrap) {
            if (pixel_y<0) {
               direction=-1;
            } else if (pixel_y>=p_client_height){
               direction=1;
            }else if (pixel_x<_adjusted_windent_x()) {
               //direction= -1;
            } else if (pixel_x>=p_client_width){
               //direction=1;

            }
         }else{
            if (pixel_x<_adjusted_windent_x()) {
               direction= -1;
            } else if (pixel_x>=p_client_width){
               direction=1;
            }
         }
         if (!direction) {
            _set_sel(begin_col,new_col);
            /* message 'begin_col='begin_col' new_col='new_col */
            col=new_col;
         } else {
            done := command_selectNscroll(begin_col,new_col,direction,mx,wx,wy) != 0;
            if ( done ) {
               break;
            }
            col=_get_sel();
         }
      } else {
         break;
      }
   }
   mou_mode(0);
   mou_release();
   init_command_op();
   _autoclipboard();
   retrieve_command_results();
}

static int GetTimerAdjustment(int YPos)
{
   YPos=abs(YPos);
   diff := 0;
   if (YPos>40) {
      diff=150;
   }else if (YPos>30) {
      diff=125;
   }else if (YPos>20) {
      diff=100;
   }else if (YPos>10) {
      diff=75;
   }
   return(diff);
}

static _str command_selectNscroll(int begin_col,int col,int direction,int mx,int wx,int wy)
{
   /* we are outside the window. */
   _set_sel(begin_col,col);
   //init_delay=def_init_delay;
   cur_delay := 200;
   init_delay := 200;
   int count=DEF_CHG_COUNT;
   skip_count := 0;
   max_skip := 1;
   my := 0;
   int pixel_x,pixel_y;
   _set_timer(cur_delay);
   for (;;) {
      if (!p_word_wrap) {
         col += direction;
      }else{
         int CurSP=_TextboxScroll();
         if (direction<0) {
            _TextboxScroll(CurSP-1);
         }else if (direction>0) {
            _TextboxScroll(CurSP+1);
         }
         mx=mou_last_x('D');mx-=wx;
         my=mou_last_y('D');my-=wy;
         pixel_x=mx;
         pixel_y=my;
         col=mou_col2(pixel_x,pixel_y);
      }
      if (p_word_wrap &&
          (col<0) || (col>length(p_text)) ) {
         _kill_timer();
         return(0);
      }
      _set_sel(begin_col,col);
      typeless event=ON_TIMER;
      ++skip_count;
      no_skip := skip_count>=max_skip;   //  || test_event('r'):!='')
      if ( no_skip ) {
         refresh('w');
         event=get_event('k');
         skip_count=0;
      }
      if(event:==ON_TIMER) {
         --count;
         if ( count<=0 ) {
            count=DEF_CHG_COUNT;
#if 0
            if ( init_delay>DEF_MIN_DELAY ) {
               init_delay -= DEF_DEC_DELAY_BY;
            } else {
               init_delay=DEF_MIN_DELAY;
            }
#endif
            max_skip += DEF_INC_MAX_SKIP_BY;
            if ( max_skip>DEF_MAX_SKIP ) {
               max_skip=DEF_MAX_SKIP;
            }
         }
      } else if ( event:==MOUSE_MOVE ) {
         mx=mou_last_x('D');mx-=wx;
         my=mou_last_y('D');my-=wy;
         pixel_x=mx;
         pixel_y=my;
         int new_col;
         if (p_word_wrap) {
            new_col=mou_col2(pixel_x,pixel_y);
         }else{
            new_col=mou_col(pixel_x);
         }
         if (!p_word_wrap) {
            if (pixel_x<0) new_col=1;
         }
         direction=0;

         if (p_word_wrap) {
            int CurSP=_TextboxScroll();
            diff := 0;
            if (pixel_y<0) {
               diff=GetTimerAdjustment(pixel_y);
               direction= -1;
            } else if (pixel_y>=p_client_height){
               diff=GetTimerAdjustment(pixel_y-p_client_height);
               direction=1;
            }
            cur_delay=init_delay-diff;
            if (init_delay!=cur_delay) {
               _kill_timer();
               _set_timer(cur_delay);
            }
         }else{
            diff := 0;
            if (pixel_x<_adjusted_windent_x()) {
               diff=GetTimerAdjustment(pixel_x);
               direction= -1;
            } else if (pixel_x>=p_client_width){
               diff=GetTimerAdjustment(pixel_x-p_client_width);
               direction=1;
            }
            cur_delay=init_delay-diff;
            if (init_delay!=cur_delay) {
               _kill_timer();
               _set_timer(cur_delay);
            }
         }
         if ( !direction) {
            _set_sel(begin_col,new_col);
            _kill_timer();
            return(0);
         }
         col=new_col;
         _set_sel(begin_col,col);
         continue;

      } else {
         _kill_timer();
         return(1);
      }
   }
}
void _sb_line_left()
{
   if (p_scroll_left_edge<0) {
      p_scroll_left_edge=p_left_edge;
   }
   int new_value;
   if (p_object!=OI_LIST_BOX && p_fixed_font) {
      new_value=p_scroll_left_edge-1;
   } else {
      new_value=p_scroll_left_edge-p_font_width;
   }
   if (new_value<0) {
      new_value=0;
   }
   p_scroll_left_edge=new_value;
}
void _sb_line_right()
{
   int old_val=p_scroll_left_edge;
   if (p_scroll_left_edge<0) {
      p_scroll_left_edge=p_left_edge;
   }
   if (p_object!=OI_LIST_BOX && p_fixed_font) {
      p_scroll_left_edge++;
   } else {
      p_scroll_left_edge += p_font_width;
   }
}
void _sb_page_left()
{
   if (p_scroll_left_edge<0) {
      p_scroll_left_edge=p_left_edge;
   }
   int new_value;
   if (p_object!=OI_LIST_BOX && p_fixed_font) {
      new_value=p_scroll_left_edge-(p_char_width intdiv 2);
   } else {
      new_value=p_scroll_left_edge-(p_client_width intdiv 2);
   }
   if (new_value<0) {
      new_value=0;
   }
   p_scroll_left_edge=new_value;
}
void _sb_page_right()
{
   if (p_scroll_left_edge<0) {
      p_scroll_left_edge=p_left_edge;
   }
   if (p_object!=OI_LIST_BOX && p_fixed_font) {
      p_scroll_left_edge=p_scroll_left_edge+(p_char_width intdiv 2);
   } else {
      p_scroll_left_edge=p_scroll_left_edge+(p_client_width intdiv 2);
   }
}
void _sb_page_down()
{
   _scroll_page('d');
}
void _sb_page_up()
{
   _scroll_page('u');
}

_command scroll_begin_line() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (p_scroll_left_edge<0) {
      p_scroll_left_edge=p_left_edge;
   }
   p_scroll_left_edge=0;
}
_command scroll_end_line() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   save_pos(auto p);
   _end_line();_refresh_scroll();
   left_edge := p_left_edge;
   restore_pos(p);
   p_scroll_left_edge=left_edge;
}
_command void scroll_page_up() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _scroll_page('u');
}

_command void scroll_page_down() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _scroll_page('d');
}

_command void scroll_top() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _scroll_page('t');
}

_command void scroll_bottom() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _scroll_page('b');
}

_command void scroll_line_up() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _scroll_page('u', 1);
}

_command void scroll_line_down() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _scroll_page('d', 1);
}

_command void scroll_line_left() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _sb_line_left();
}

_command void scroll_line_right() name_info(','VSARG2_NOEXIT_SCROLL| VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _sb_line_right();
}


/** 
 * If <b>last_event</b> was a mouse event, menu specified is display at the 
 * mouse cursor position.  Otherwise menu is displayed at center of screen.
 * 
 * @return Returns 0 if successful.
 * 
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see show
 * 
 * @categories Menu_Functions, Mouse_Functions
 * 
 */
_str mou_show_menu(_str menu_name, _str button="")
{
   _str event=last_event();
   if (arg()<2) {
      if (event:==RBUTTON_DOWN || event:==name2event('s-rbutton-down') ||
          event:==name2event('c-rbutton-down') || event:==name2event('a-rbutton-down')
          ) {
         button='R';
      } else if ((event:==LBUTTON_DOWN || event:==LBUTTON_UP) || event:==name2event('s-lbutton-down') ||
          event:==name2event('c-lbutton-down') || event:==name2event('a-lbutton-down')
          ) {
         button='L';
      } else {
         return(show(menu_name));
      }
   }
   if (button=='') {
      return(show(menu_name));
   }
   int index=find_index(menu_name,oi2type(OI_MENU));
   if (!index) {
      return(STRING_NOT_FOUND_RC);
   }
   int menu_handle=_menu_load(index,'P');
   int x=VSDEFAULT_INITIAL_MENU_OFFSET_X;
   int y=VSDEFAULT_INITIAL_MENU_OFFSET_Y;
   _lxy2lxy(SM_TWIP,p_scale_mode,x,y);
   x=mou_last_x('M')-x;y=mou_last_y('M')-y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y);
   call_list('_on_popup2_',translate(menu_name,'_','-'),menu_handle);
   if (_isEditorCtl()) {
      call_list('_on_popup_',translate(menu_name,'_','-'),menu_handle);
   }
   int flags;
   if (upcase(button)=='L') {
      flags=VPM_LEFTALIGN|VPM_LEFTBUTTON;
   } else {
      flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   }
   int status=_menu_show(menu_handle,flags,x,y);
   _menu_destroy(menu_handle);
   return(status);
}
void mou_hour_glass(bool onoff)
{
   //say('mou_hour_glass: onoff='onoff);
   if (onoff) {
      mou_set_pointer(MP_HOUR_GLASS);
      return;
   }
   mou_set_pointer(MP_DEFAULT);
}
/*

   If def_mouse_menu_style is MM_TRACK_MOUSE, we automatically track the popup
   the menu and track the mouse.

   Otherwise, we do the appropriate selection first, and then popup a menu if
   the mouse never moved.

   Looks for menus in the following manner:

      1. If there is a selection, it looks for _ext_menu(mode_name)_sel.

      2. Looks for _ext_menu(mode_name)

      3. If there is a selection, looks for _ext_menu_default_sel

      4. Looks for _ext_menu_default

*/

_metadata enum MouseMenuOptions {
   MM_TRACK_MOUSE = 1,
   MM_MARK_FIRST  = 2,
};

/**
 * Starts a block selection or displays an extension menu.  Use the 
 * <b>Extension Menu dialog box</b> to set the extension specific menus.  A 
 * selection can only be created if the "Select First" option is on (default is 
 * on).
 * 
 * @see mou_click
 * @see mou_click_block
 * @see mou_click_line
 * @see mou_select_line
 * @see mou_extend_selection
 * @see mou_select_word
 * @see mou_click_menu
 * @see mou_click_menu_line
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Mouse_Functions
 * 
 */
_command mou_click_menu_block() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   _mou_menu('BLOCK');
}
/**
 * Starts a line selection or displays an extension menu.  Use the 
 * <b>Extension Menu dialog box</b> to set the extension specific menus.  A 
 * selection can only be created if the "Select First" option is on (default is 
 * on).
 * 
 * @see mou_click
 * @see mou_click_block
 * @see mou_click_line
 * @see mou_select_line
 * @see mou_extend_selection
 * @see mou_select_word
 * @see mou_click_menu
 * @see mou_click_menu_block
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Mouse_Functions
 * 
 */
_command mou_click_menu_line() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   _mou_menu('LINE');
}
/**
 * Starts a character selection or displays an extension menu.  Use the 
 * <b>Extension Menu dialog box</b> to set the extension specific menus.  A 
 * selection can only be created if the "Select First" option is on (default is 
 * on).
 * 
 * @see mou_click
 * @see mou_click_block
 * @see mou_click_line
 * @see mou_select_line
 * @see mou_extend_selection
 * @see mou_select_word
 * @see mou_click_menu_block
 * @see mou_click_menu_line
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Mouse_Functions
 * 
 */
_command mou_click_menu() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   _mou_menu('CHAR');
}
static void _mou_menu(_str mark_type)
{
   gInMouseMoveHandler=true;
   if (command_state()) {
      call_event(defeventtab _ul2_textbox,RBUTTON_DOWN,'e');
      gInMouseMoveHandler=false;
      return;
   }
   int mx=mou_last_x();
   int my=mou_last_y();
   int status;
   if (select_active2() && def_mouse_menu_style==MM_MARK_FIRST) {
      int mark_id=_duplicate_selection();
      int orig_mark_id=_duplicate_selection('');
      typeless p;save_pos(p);
      status=mou_click(mark_type,'M');
      if (!status && !select_active2()) {
         restore_pos(p);
         _show_selection(mark_id);
         _free_selection(orig_mark_id);
         refresh();
         _mou_mode_menu();
         gInMouseMoveHandler=false;
         return;
      }
      _free_selection(mark_id);
      gInMouseMoveHandler=false;
      return;
   }
   if (mark_type!='' && def_mouse_menu_style==MM_MARK_FIRST) {
      status=mou_click(mark_type,'M');
      if (status) {
         gInMouseMoveHandler=false;
         return;
      }
   }else{
      _mou_mode_menu();
      gInMouseMoveHandler=false;
      return;
   }
   if (!select_active2() || (mx==mou_last_x() && my==mou_last_y())) {
      _mou_mode_menu();
   }
   gInMouseMoveHandler=false;
}


static get_menu_name()
{
   // no context menu for editor windows in tool windows
   switch (p_active_form.p_name) {
      case '_tbslickc_stack_form':
      case '_tbregex_form':
         return '';

      case '_tboutputwin_form':
         return '_output_menu_default';
   }
   _str mode_name='';
   idname:=_ConcurProcessName();
   lang := p_LangId;
   if (idname==null) {
      mode_name= p_mode_name;
   } else {
      mode_name='process';
      lang='process';
   }
   mode_name=stranslate(mode_name'_menu','__',' -');
   int index=find_index(mode_name,oi2type(OBJECT_TYPE)|IGNORECASE_TYPE);
   if (!index) {
      index=find_index('_'mode_name,oi2type(OI_MENU)|IGNORECASE_TYPE);
      if (!index) {
         index=find_index('_'lowcase(mode_name),oi2type(OI_MENU)|IGNORECASE_TYPE);
      }
   }
   if (index && select_active2()) {
      int sel_index=find_index(name_name(index)'_sel',oi2type(OI_MENU)|IGNORECASE_TYPE);
      if (!sel_index) {
         sel_index=find_index(lowcase(name_name(index))'_sel',oi2type(OI_MENU)|IGNORECASE_TYPE);
      }
      if (!sel_index) {
         index=sel_index;
      }
   }
   menu_name := name_name(index);
   if (menu_name!='') {
      return(menu_name);
   }

   if (select_active2()) {
      sel_menu_name := LanguageSettings.getMenuIfSelection(lang);
      if (sel_menu_name=='') {
         sel_menu_name='_ext_menu_default_sel';
      }
      return(sel_menu_name);
   } else {
      menu_name = LanguageSettings.getMenuIfNoSelection(lang);
      if (menu_name=='') {
         menu_name='_ext_menu_default';
      }
      return(menu_name);
   }
}

_command void context_menu() name_info(','CMDLINE_ARG2|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_NOEXIT_SCROLL)
{
   if (command_state()) {
      _mou_mode_menu(p_client_width intdiv 2,p_client_height intdiv 2);
      //call_event(defeventtab _ul2_textbox,CONTEXT,'E');
      return;
   }
   _mou_mode_menu(p_cursor_x,p_cursor_y+p_font_height);
   //_mou_mode_menu(p_client_width intdiv 2,p_client_height intdiv 2);
}

void _on_popup_misc(_str menu_name,int menu_handle)
{
   if (menu_name:!="_ext_menu_default") {
      return;
   }
}
static void _mou_mode_menu(int ix=MAXINT,int iy=MAXINT)
{
   typeless event=last_event();
   _str menu_name;
   if (p_object==OI_TEXT_BOX) {
      menu_name='_textbox_menu';
   } else {
      menu_name=get_menu_name();
   }
   if (menu_name=='') {
      return;
   }
   _str button;
   if (event:==RBUTTON_DOWN || event:==name2event('s-rbutton-down') ||
       event:==name2event('c-rbutton-down') || event:==name2event('a-rbutton-down')
       ) {
      button='R';
   } else if (event:==LBUTTON_DOWN || event:==name2event('s-lbutton-down') ||
       event:==name2event('c-lbutton-down') || event:==name2event('a-lbutton-down')
       ) {
      button='L';
   } else {
      //return(show(menu_name));
   }
   button='R';
   int index=find_index(menu_name,oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int x=VSDEFAULT_INITIAL_MENU_OFFSET_X;
   int y=VSDEFAULT_INITIAL_MENU_OFFSET_Y;
   _lxy2lxy(SM_TWIP,p_xyscale_mode,x,y);
   int mx=mou_last_x('M');
   int my=mou_last_y('M');
   if (p_object==OI_TEXT_BOX) {
      mx=my=0;
   }
   if (ix!=MAXINT && iy!=MAXINT) {
      ix=_dx2lx(p_xyscale_mode,ix);
      iy=_dy2ly(p_xyscale_mode,iy);
      mx=ix;
      my=iy;
   }
   x=mx-x;y=my-y;
   _lxy2dxy(p_xyscale_mode,x,y);
   _map_xy(p_window_id,0,x,y);
   int flags;
   if (upcase(button)=='L') {
      flags=VPM_LEFTALIGN|VPM_LEFTBUTTON;
   } else {
      flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   }
   if (p_object!=OI_TEXT_BOX) {
      index2 := find_index('_mou_mode_menu2',PROC_TYPE);
      if (index2) {
         call_index(menu_name,flags,x,y,index2);
         return;
      }
   }

   int menu_handle=p_active_form._menu_load(index,'P');

   // DJB 04-03-2007 -- this is no longer needed, but leave
   // it in for backwards compatibility
   if (!def_process_tab_output) {
      cmd := "set-var def-process-tab-output ";
      int mf_flags;
      _str caption;
      _menu_get_state(menu_handle,cmd:+"0",mf_flags,'M',caption);
      _menu_set_state(menu_handle,cmd:+"0",MF_CHECKED,'M',caption,cmd:+"1");
   }

   _menu_set_bindings(menu_handle);
   if (p_object!=OI_TEXT_BOX) {
      _menu_remove_unsupported_commands(menu_handle);
   }
   call_list('_on_popup2_',translate(menu_name,'_','-'),menu_handle,true);
   if (_isEditorCtl()) {
      call_list('_on_popup_',translate(menu_name,'_','-'),menu_handle,true);
   }
   _menu_show(menu_handle,flags,x,y);
   //_menu_show(menu_handle,flags,0,0);
   _menu_destroy(menu_handle);
}
static _str name_on_cxkey(_str key)
{
   cx_index := find_index('default-keys:c-x',EVENTTAB_TYPE);
   if (!cx_index) {
      return('');
   }
   if (name_on_key(C_X)!='default-keys:c-x') {
      return('');
   }
   return(name_name(eventtab_index(cx_index,cx_index,event2index(key))));

}

static bool get_emulation_menu_binding(_str cmd,_str &binding)
{
   _str event;
   switch (def_keys) {
   case 'windows-keys':
      return(false);
   case '':  // slick-keys
      switch (cmd) {
      case 'gui-open':
      case 'edit':
         event=name2event('f7');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'quit':
         event=name2event('f3');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'save':
         event=name2event('f2');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'undo':
         event=name2event('f9');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'redo':
         event=name2event('s-f9');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'cut':
         event=name2event('a-k');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'copy-to-clipboard':
         event=name2event('a-v');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'paste':
         event=name2event('c-y');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'list-clipboards':
         event=name2event('c-y');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'find-next':
         event=name2event('c-f');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'push-tag':
         event=name2event('c-.');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'push-tag-filter-overloads':
         event=name2event('c-h');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'push-alttag':
         event=name2event('c-h');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'pop-bookmark':
         event=name2event('c-,');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'project-compile':
         event=name2event('c-f6');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'project-build':
      case 'project-execute':
         event=name2event('c-f5');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'next-error':
         event=name2event('c-n');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'start-process':
         event=name2event('c-m');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'reflow-paragraph':
         event=name2event('a-p');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'load':
      case 'gui-load':
         event=name2event('c-l');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'record-macro-toggle':
         event=name2event('c-r');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'record-macro-end-execute':
         event=name2event('c-t');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'list-buffers':
         event=name2event('c-b');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'config':
         event=name2event('f5');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'next-window':
         event=name2event('c-w');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'help':
         event=name2event('f1');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      }
      return(false);
   case 'brief-keys':
      switch (cmd) {
      case 'gui-open':
      case 'edit':
         event=name2event('a-e');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'quit':
         event=name2event('c-_');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-insert-file':
      case 'get':
         event=name2event('a-r');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'dos':
         event=name2event('a-z');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'safe-exit':
         event=name2event('a-x');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'undo':
         event=name2event('a-u');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'cut':
         event=name2event('pad-minus');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'copy-to-clipboard':
         event=name2event('pad-plus');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'paste':
      case 'brief-paste':
         event=name2event('ins');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-fill-selection':
      case 'fill-selection':
         event=name2event('a-f');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-find':
      case 'search-forward':
         event=name2event('f5');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-replace':
      case 'translate-forward':
         event=name2event('s-f5');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-goto-line':
      case 'goto-line':
         event=name2event('a-g');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'next-error':
         event=name2event('c-n');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-load':
      case 'load':
      case 'prompt-load':
         event=name2event('f9');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-unload':
      case 'unload':
         event=name2event('s-f9');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'record-macro-toggle':
         event=name2event('f7');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'last-macro':
         event=name2event('f8');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'next-buffer':
         event=name2event('a-n');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'prev-buffer':
         event=name2event('a--');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'list-buffers':
         event=name2event('a-b');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      }
      return(false);
   case 'emacs-keys':
      switch (cmd) {
      case 'gui-open':
      case 'edit':
         event=name2event('c-f');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'quit':
      case 'emacs-quit':
         event=name2event('k');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'save':
         event=name2event('c-s');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-cd':
      case 'prompt-cd':
         event=name2event('f7');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-insert-file':
      case 'get':
         event=name2event('i');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-write-selection':
      case 'put':
         event=name2event('w');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'dos':
         event=name2event('c-e');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'safe-exit':
         event=name2event('c-c');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'undo':
         event=name2event('f9');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'redo':
         event=name2event('s-f9');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-replace':
      case 'query-replace':
         event=name2event('a-s-5');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'gui-goto-line':
      case 'goto-line':
         event=name2event('g');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'project-compile':
         event=name2event('c-f6');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'project-build':
         event=name2event('m');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'start-process':
         event=name2event('c-m');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'record-macro-toggle':
         event=name2event('(');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'last-macros':
         event=name2event('e');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'list-buffers':
         event=name2event('c-b');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'next-window':
         event=name2event('o');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'vsplit-window':
         event=name2event('o');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      case 'one-window':
         event=name2event('1');
         if (name_on_cxkey(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         return(false);
      }
      return(false);
   }
   return(false);
}
static bool get_cua_menu_binding(_str cmd,_str &binding)
{
   _str event;
   switch (cmd) {
   case 'safe-exit':
      if (_isMac()) {
         event=name2event('m-q');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
         event=name2event('m-f4');
      } else {
         event=name2event('a-f4');
      }
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'close-window':
      if (_isMac()) {
         event=name2event('m-w');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      event=name2event('c-f4');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'next-window':
      event=name2event('c-f6');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'prev-window':
      event=name2event('c-s-f6');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'copy-to-clipboard':
      if (_isMac()) {
         event=name2event('m-c');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      event=name2event('c-c');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'gui-open':
      if (_isMac()) {
         event=name2event('m-o');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      event=name2event('c-o');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'save':
      if (_isMac()) {
         event=name2event('m-s');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      event=name2event('c-s');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'paste':
      if (_isMac()) {
         event=name2event('m-v');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      event=name2event('c-v');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'cut':
      if (_isMac()) {
         event=name2event('m-x');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      event=name2event('c-x');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'redo':
      if (_isMac()) {
         event=name2event('m-s-z');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      event=name2event('c-y');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'undo':
      if (_isMac()) {
         event=name2event('m-z');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      event=name2event('c-z');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      event=name2event('a-backspace');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);
   case 'undo-cursor':
      if (_isMac()) {
         event=name2event('m-z');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      event=name2event('c-z');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      event=name2event('a-backspace');
      if (name_on_key(event)==cmd) {
         binding=_key_for_display(event);
         return(true);
      }
      return(false);

   case 'gui-print':
      if (_isMac()) {
         event=name2event('m-p');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      return(false);
   case 'gui-find':
      if (_isMac()) {
         event=name2event('m-f');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      return(false);
   case 'find-next':
      if (_isMac()) {
         event=name2event('m-g');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      return(false);
   case 'find-prev':
      if (_isMac()) {
         event=name2event('m-s-g');
         if (name_on_key(event)==cmd) {
            binding=_key_for_display(event);
            return(true);
         }
      }
      return(false);
   }
   return(false);
}
void _menu_set_binding(int menu_handle,int i)
{
   int flags;
   _str caption;
   _str cmdlist;
   _menu_get_state(menu_handle, i, flags, 'P', caption, cmdlist);
   if ((flags&MF_SUBMENU) && isinteger(cmdlist)) {
      _menu_set_bindings((int)cmdlist);
   } else {
      //messageNwait('cmd='cmd' caption='caption);
      for (;;) {
         _str cmd;
         parse cmdlist with cmd "\t" cmdlist;
         if (cmd=='') {
            // Remove binding. We might have changed emulations.
            _str rest;
            _menu_get_state(menu_handle, i, flags, 'P', caption);
            parse caption with caption "\t" rest;
            _menu_set_state(menu_handle, i, flags, 'P', caption);
            break;
         }
         if (cmd!='' && cmd!='-') {
            _str bindings;
            cmd=translate(cmd,'-','_');
            if (get_emulation_menu_binding(cmd,bindings) ||
                get_cua_menu_binding(cmd,bindings)) {
            } else {
               if (_isEditorCtl()) {
                  bindings=where_is(cmd,2,"\t");
               } else {
                  bindings=_mdi.p_child.where_is(cmd,2,"\t");
               }
               if (_isMac()) {
                  // on the Mac, prefer bindings that use the command key
                  cmd_pos := pos('Command',bindings);
                  comma_pos := pos("\t",bindings);
                  while ( (comma_pos>0) && (cmd_pos>comma_pos) ) {
                     parse bindings with . "\t" bindings;
                     cmd_pos=pos('Command',bindings);
                     comma_pos=pos("\t",bindings);
                  }
               }
               _str second;
               parse bindings with bindings "\t" second "\t";
               bindings=strip(bindings);second=strip(second);
               if (pos(' ',bindings) && (!pos(' ',second) && second!='')) {
                  bindings=second;
               }
            }
            if (bindings != '') {
               _str rest;
               _menu_get_state(menu_handle, i, flags, 'P', caption);
               parse caption with caption "\t" rest;
               _menu_set_state(menu_handle, i, flags, 'P', caption "\t" bindings);
               break;
            }
         }
      }
   }
}
void _menu_set_bindings(int menu_handle)
{
   //cmd='cursor-error';
   int i;
   for (i=0;i<_menu_info(menu_handle);++i) {
      _menu_set_binding(menu_handle,i);
   }
}
void _menu_remove_unsupported_commands(int menu_handle)
{
   //cmd='cursor-error';
   int i,index;
   for (i=0;i<_menu_info(menu_handle);++i) {
      int flags;
      _str caption;
      _str cmdlist;
      _menu_get_state(menu_handle, i, flags, 'P', caption,cmdlist);
      if ((flags&MF_SUBMENU)) {
         _menu_remove_unsupported_commands((int)cmdlist);
      } else {
         _str cmd;
          parse cmdlist with cmd "\t" cmdlist;
          if (cmd!='') {
             parse cmd with cmd .;
             index=find_index(cmd,COMMAND_TYPE);
             _str arg1,arg2;
             parse name_info(index) with arg1','arg2;
             doDelete := false;
             if (isinteger(arg2)) {
                flags=(int)arg2;
             } else {
                flags=0;
             }
#if 0
             doDelete= !p_mdi_child && (!isinteger(arg2) || !(((int)arg2)&VSARG2_EDITORCTL) ||
                 ((((int)arg2)&VSARG2_REQUIRES_MDI) && !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)));
#else
             if (isinteger(arg2)) {
                if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
                   // Remove commands which require MDI but MDI isn't supported
                   doDelete= !p_mdi_child && (flags&VSARG2_REQUIRES_MDI);
                }
                if (!doDelete) {
                   // Remove commands which require an editor control but we don't have an editor control target
                   // Not that the VSARG2_REQUIRES_MDI_EDITORCTL flag is used for MDI editor control as well.
                   // See VSARG2_REQUIRES_EDITORCTL.
                   doDelete= !p_HasBuffer && (flags & VSARG2_REQUIRES_MDI_EDITORCTL);
                }
                if (!doDelete) {
                   // Remove commands which require an MDI editor control but we don't have an MDI editor control
                   doDelete= !p_mdi_child && (flags & VSARG2_REQUIRES_MDI_EDITORCTL) && !(flags & EDITORCTL_ARG2);
                }
                if (!doDelete) {
                   if (_isCommunityEdition()) {
                      doDelete = (flags & (VSARG2_REQUIRES_PRO_EDITION|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)) != 0;
                   } else if (_isStandardEdition()) {
                      doDelete = (flags & VSARG2_REQUIRES_PRO_EDITION) != 0;
                   }
                }
             }
#endif
             int apiflags=_default_option(VSOPTION_APIFLAGS);
             RequireFlags := 0;
             if (apiflags & VSAPIFLAG_ALLOW_PROJECT_SUPPORT) {
                RequireFlags|=VSARG2_REQUIRES_PROJECT_SUPPORT;
             }
             if (apiflags & VSAPIFLAG_ALLOW_MINMAXRESTOREICONIZE_WINDOW) {
                RequireFlags|=VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW;
             }
             if (apiflags & VSAPIFLAG_ALLOW_TILED_WINDOWING) {
                RequireFlags|=VSARG2_REQUIRES_TILED_WINDOWING;
             }

             int req_flags=flags&(VSARG2_REQUIRES_PROJECT_SUPPORT|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW|VSARG2_REQUIRES_TILED_WINDOWING);

             if ((req_flags & RequireFlags)!=req_flags){
                doDelete=true;
             }

             if (doDelete) {
                _menu_delete(menu_handle,i);--i;

                // IF there are still some menu items AND we deleted the last menu item
                if (i>=0 && i+1==_menu_info(menu_handle)) {
                   // Check if the last menu item is a dash
                   _menu_get_state(menu_handle,i, flags, 'P', caption,cmdlist);
                   if (caption=='-') {
                      _menu_delete(menu_handle,i);--i;
                   }
                // IF we deleted the first menu item AND there are still some menu items
                } else if (i<0 && _menu_info(menu_handle)>0) {
                   _menu_get_state(menu_handle,i+1, flags, 'P', caption,cmdlist);
                   if (caption=='-') {
                      _menu_delete(menu_handle,i+1);
                   }
                // IF there is a previous menu item AND there is a next menu item
                } else if (i>=0 && i+1<_menu_info(menu_handle)) {
                   _menu_get_state(menu_handle,i, flags, 'P', caption,cmdlist);
                   if (caption=='-') {
                      _menu_get_state(menu_handle,i+1, flags, 'P', caption,cmdlist);
                      if (caption=='-') {
                        _menu_delete(menu_handle,i+1);
                      }
                   }
                }

             }
         }
      }
   }
}

/**
 * Shifts selected text left or right by an amount you specify.  A dialog 
 * box is displayed to prompt you for a shift count.  If the L or R option is 
 * not specified the text is shifted left.  Character selections are treated as 
 * line selections.
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 * 
 */
_command gui_shift_selection() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if ( _select_type()=='' ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   int was_recording=_macro();
   _macro_delete_line();
   int numshifts=get_num_shifts(arg(1));
   if (numshifts!='') {
      _macro('m',was_recording);
      if (lowcase(arg(1))=='r') {
         _macro_call('shift_selection_right', numshifts);
         shift_selection_right(numshifts);
      }else{
         _macro_call('shift_selection_left', numshifts);
         shift_selection_left(numshifts);
      }
   }
}

static get_num_shifts(_str direction)
{
   direction=(lowcase(direction)=='r')?('Right'):('Left');
   int result=show('-modal _textbox_form',
               'Shift Selection 'direction,
               TB_RETRIEVE_INIT,
               '',           //tb width
               '',           //Help item
               '',           //Buttons and captions
               'shift',      //retrieve
               '-e _valid_shift_amount Shift Amount');//prompts
   if (result=='') {
      return('');
   }
   return(_param1);
}

bool _valid_shift_amount(_str cl)
{
   if (!isnumber(cl)) {
      return(true);
   }
   integer := isinteger(cl);
   positive := (cl>=1);
   rv := positive&&integer;
   return(!rv);
}

/**
 * Determines whether the current cursor position is contained within a selection.
 *
 * @param markid a handle to a selection or bookmark returned by one of the built-ins <b>_alloc_selection</b> or
 * <b>_duplicate_selection</b>.  Default parameter specifies current selection.
 * 
 * @param strict   When true, returns true when cursor is inside
 *                 the selected area. When false, returns true
 *                 if cursor is either inside the selected area
 *                 or if the cursor could be at the end of a
 *                 selection that is being extended.
 *
 * @return 1 if cursor is in selection, 0 if not
 * @categories Edit_Window_Methods, Selection_Functions
 */
int _in_selection(_str mark_id = '',bool strict=true)
{
   int first_col,last_col,buf_id;
   status:=_get_selinfo(first_col,last_col,buf_id,mark_id);
   if (status) {
      // There's no selection.
      return 0;
   }
   status=0;
   switch (_select_type(mark_id)) {
   case 'LINE':
      if (_begin_select_compare(mark_id)>=0 && _end_select_compare(mark_id)<=0) {
         status=1;
      }
      break;
   case 'BLOCK':
      if (strict) {
         if (_select_type(mark_id,'I')) {
            ++last_col;
         }
         if (_begin_select_compare(mark_id)>=0 && _end_select_compare(mark_id)<=0 &&
              p_col>=first_col && p_col<last_col) {
            status=1;
         }
      } else {
         if (_begin_select_compare(mark_id)>=0 && _end_select_compare(mark_id)<=0 &&
              p_col>=first_col && p_col<=last_col) {
            status=1;
         }
      }
      break;
   default:
      if (_begin_select_compare(mark_id)>0 && _end_select_compare(mark_id)<0) {
         status=1;
      } else if (_begin_select_compare(mark_id)==0) {
         if (p_col>=first_col) {
            status=1;
            if (_end_select_compare(mark_id)==0){
               if (strict) {
                  if(p_col>=last_col+_select_type(mark_id,'I')) {
                     status=0;
                  }
               } else {
                  if(p_col>last_col) {
                     status=0;
                  }
               }
            }
         }
      } else if (_end_select_compare(mark_id)==0){
         if (strict) {
             if(p_col<last_col+_select_type(mark_id,'I')) {
                status=1;
             }
         } else {
            if(p_col<=last_col) {
               status=1;
            }
         }
      }
      break;
   }
   return(status);
}

/**
 * Determines whether the current mouse position is contained within a selection.
 *
 * @param markid a handle to a selection or bookmark returned by one of the built-ins <b>_alloc_selection</b> or
 * <b>_duplicate_selection</b>.  Default parameter specifies current selection.
 *
 * @return 1 if mouse is in selection, 0 if not
 * @categories Edit_Window_Methods, Selection_Functions
 */
int mou_in_selection(int mou_x,int mou_y)
{
   if (select_active2()) {
      x := p_cursor_x;
      y := p_cursor_y;
      p_cursor_x=mou_x;p_cursor_y=mou_y;
      int status=_in_selection();
      p_cursor_x=x;p_cursor_y=y;
      return(status);
   }
   return(0);
}

definit()
{
   if (arg(1)!='L') {
      BBTimerHandle=-1;
      //debug_count=0;
      gInMouseMoveHandler=false;
      gBBWid=0;
      goverURL=false;
      gmodKeyDown=false;
      gURL_window_id=0;
      gpreURLMousePointer=0;
   }
   gmulti_cursor_count=0;
   gmuti_cursor_count_time='';
}

defeventtab _minimap_tooltip_form;
static bool  _minimap_tooltip_get_mouse_line(typeless &mouse_linenum,int minimap_wid,int mx,int my) {
   //int mx; mou_get_xy(mx,my);
   bool orig_SoftWrap=minimap_wid.p_SoftWrap;
   minimap_wid.p_SoftWrap=false;
   minimap_wid.save_pos(auto p);
   //int mx=mou_last_x('D');
   //int my=mou_last_y('D');
   _map_xy(0,minimap_wid,mx,my);
   //p_cursor_x=mx;
   minimap_wid.p_cursor_y=my;
   mouse_linenum=minimap_wid.p_line;
   past_eow:=my>minimap_wid.p_cursor_y+ minimap_wid.p_font_height;
   minimap_wid.restore_pos(p);
   minimap_wid.p_SoftWrap=orig_SoftWrap;
   if (past_eow) {
      return true;
   }
   return false;
}
static void _minimap_tooltip_move_window(typeless mouse_linenum,int minimap_wid,int mx,int my,bool always_move) {
   _nocheck _control ctledit1;
   int wwidth=minimap_wid.p_minimap_to_editor_wid.p_client_width intdiv 2;
   if (def_minimap_tooltip_lines<=3) def_minimap_tooltip_lines=3;
   int wheight=gBBWid.ctledit1.p_font_height*def_minimap_tooltip_lines;
   wx:=0;wy:=0;
   _map_xy(minimap_wid.p_minimap_to_editor_wid,0,wx,wy);
   int min_y=wy;
   wx+=minimap_wid.p_minimap_to_editor_wid.p_client_width+_get_minimap_sizebar_width();
   wx-=wwidth;
   int cursor_y=minimap_wid.p_cursor_y;
   int junk_x=0;
   _map_xy(minimap_wid,0,junk_x,cursor_y);
   //wy=my-((minimap_wid.p_font_height*def_minimap_tooltip_lines-1) intdiv 2);
   wy=my-gBBWid.ctledit1.p_font_height;
   if (mouse_linenum!=gLineNum || always_move) {
      gLineNum=mouse_linenum;
      if (wy<min_y) wy=min_y;
      _dxy2lxy(SM_TWIP,wx,wy);
      _dxy2lxy(SM_TWIP,wwidth,wheight);
      gBBWid._move_window(wx,wy,wwidth,wheight);
      gBBWid._show_entire_form();
      gBBWid.ctledit1.p_cursor_x=0;
      gBBWid.ctledit1.p_line=mouse_linenum;
      gBBWid.ctledit1.center_line();
      gBBWid.ctledit1.refresh('w');
      refresh();
   }
}
void _minimap_tooltip_form.ESC() {
   _KillMouseOverBBWin(true);
}
void ctledit1.on_destroy() {
   if (gBBWid_minimap_had_focus && !gBBWid_minimap_had_selection) {
      if (select_active()) {
         _deselect();
      }
   }
}
void ctledit1.on_create(int minimap_wid,int buf_id) {
   p_active_form.p_MouseActivate=MA_NOACTIVATE;
   ctledit1._delete_buffer();
   ctledit1.load_files("+m +bi "buf_id);
   //ctledit1.p_visible=false;
   /*orig_wid:=p_window_id;
   _safe_hidden_window();
   p_buf_id=orig_buf_id;
   _delete_buffer();
   p_window_id=orig_wid;*/
}
void _minimap_tooltip_form.on_resize() {
   //height:=p_client_height;
   //width:=p_client_width;
   height:=p_height-_top_height()-_bottom_height();
   width:=p_width-_left_width()*2;
   ctledit1.p_height=height;
   ctledit1.p_width=width;
}

defeventtab _editorctl_tooltip_form;

void ctlpicture1.on_destroy() {
   gBBWid=0;
}

/**
 * Send a command to the HTML control on the Context Tagging(R) mouse-over 
 * comments form.  This is used to select, copy, or deselect text from those 
 * comments using the keyboard. 
 * 
 * @param minihtml_cmd   command to send to mouse-over control 
 *                       <ul>
 *                       <li><b>copy</b> - copy selected text to clipboard
 *                       <li><b>copyall</b> - copy all text to clipboard
 *                       <li><b>deselect</b> - deselect all selected text
 *                       <li><b>selectall</b> - select all text in control
 *                       <li><b>isselected</b> - return 'true' if text is selected in control
 *                       </ul>
 * 
 * @return 'true' if successful, 'false' otherwise.
 */
bool _ECCommandCallback(_str minihtml_cmd="copy")
{
   if (!_isEditorCtl()) {
      return false;
   }
   if (p_buf_id != gbuf_id) {
      return false;
   }

   if (!gBBWid || !_iswindow_valid(gBBWid)) {
      return false;
   }

   form_wid := _GetMouWindow();
   if (!form_wid || !_iswindow_valid(form_wid)) {
      return false;
   }

   form_wid = form_wid.p_active_form;
   if (form_wid != gBBWid || gBBWid.p_name=='_minimap_tooltip_form') {
      return false;
   }

   _nocheck _control ctlminihtml1;
   if (minihtml_cmd == "copy" && form_wid.ctlminihtml1._minihtml_isTextSelected()) {
      form_wid.ctlminihtml1._minihtml_command("copy");
      form_wid.ctlminihtml1._minihtml_command("deselect");
      return true;
   }
   if (minihtml_cmd == "copyall") {
      form_wid.ctlminihtml1._minihtml_command("copyall");
      return true;
   }
   if (minihtml_cmd == "deselect" && form_wid.ctlminihtml1._minihtml_isTextSelected()) {
      form_wid.ctlminihtml1._minihtml_command("deselect");
      return true;
   }
   if (minihtml_cmd == "selectall" && !form_wid.ctlminihtml1._minihtml_isTextSelected()) {
      form_wid.ctlminihtml1._minihtml_command("selectall");
      return true;
   }
   if (minihtml_cmd == "isselected" && form_wid.ctlminihtml1._minihtml_isTextSelected()) {
      return true;
   }

   return false;
}

static int _get_minimap_sizebar_width() {
   int minimap_sizebar_width = 60;
   minimap_sizebar_width=_lx2dx(SM_RTWIP,minimap_sizebar_width);
   if (minimap_sizebar_width<4) {
       minimap_sizebar_width = 4;
   }
   return minimap_sizebar_width;
}

struct ECTimerCallbackArgs {
   int editorctl_wid;
   bool isMinimap;
   int x;
   int y;
   int width;
   int height;
   int wx;
   int wy;
   _str header;
   _str msg;
   VS_TAG_BROWSE_INFO tagList[];
   int chdebug;
};

void _terminate_hover_over_popup() {
   if (BBTimerHandle>=0) {
      _kill_timer(BBTimerHandle);
   }
   if (_iswindow_valid(gBBWid)) {
      orig_wid := p_window_id;
      gBBWid._delete_window();
      if (_iswindow_valid(orig_wid)) {
         p_window_id = orig_wid;
      }
   }
   goverURL = false;
   if (_iswindow_valid(gURL_window_id)) {
      // Check for hand specifically because this is the only other mouse 
      // pointer we are using here.
      // http://www.slickedit.com
      if (!gURL_window_id.p_IsTempEditor && gURL_window_id.p_mouse_pointer==MP_HAND && gURL_window_id._isEditorCtl(false)) {
         gURL_window_id.p_mouse_pointer = gpreURLMousePointer;
      }
   }
   BBTimerHandle=-1;gBBWid=0;
}

void _ECTimerCallback(ECTimerCallbackArgs args)
{
   orig_chdebug := _chdebug;
   if (args.chdebug) {
      _chdebug = 1;
   }
   if (_chdebug) {
      say("_ECTimerCallback: IN");
      _dump_var(args, "_ECTimerCallback H"__LINE__": args");
   }
   _nocheck _control ctlminihtml1;
   _nocheck _control ctlminihtml2;
   _nocheck _control ctledit1;

   if (args == null) {
      _chdebug = orig_chdebug;
      return;
   }

   if (gBBWid=='') gBBWid=0;
   int mx,my; mou_get_xy(mx,my);
   bool in_rect=mx>=args.x && mx<args.x+args.width &&
          my>=args.y && my<args.y+args.height;

   in_form_rect := false;
   form_wid := _GetMouWindow();
   if (form_wid && _iswindow_valid(form_wid) && (form_wid.p_active_form.p_name == "_editorctl_tooltip_form" || form_wid.p_active_form.p_name=="_minimap_tooltip_form")) {
      form_wid=form_wid.p_active_form;
      if (form_wid==gBBWid) {
         in_form_rect=true;
         if (args.isMinimap) {
            if (!_IsKeyDown(CTRL)) {
               if (gBBWid.ctledit1.p_window_id!=_get_focus()) {
                  in_form_rect=false;
               } else {
                  if (_chdebug) {
                     say("_ECTimerCallback: OUT H"__LINE__);
                  }
                  _chdebug = orig_chdebug;
                  return;
               }
            } else {
               gBBWid.ctledit1._set_focus();
               gBBWid_minimap_had_focus=true;
               if (_chdebug) {
                  say("_ECTimerCallback: OUT H"__LINE__);
               }
               _chdebug = orig_chdebug;
               return;
            }
         }
      }
   }
   orig_in_rect := in_rect;
   in_rect=in_form_rect || in_rect;
   mouse_linenum := null;

   if (!args.isMinimap && gBBWid && _iswindow_valid(gBBWid)) {
      HYPERTEXTSTACK stack = gBBWid.ctlminihtml1.p_user;
      if (stack.HyperTextTop > 0) in_rect=true;
   }

   other := !_iswindow_valid(args.editorctl_wid) || 
            !args.editorctl_wid._isEditorCtl() ||
            !_AppActive() ||
            gbuf_id!=args.editorctl_wid.p_buf_id || 
            (args.isMinimap && !args.editorctl_wid.p_minimap_to_editor_wid.p_show_minimap) ||
            (!args.isMinimap && (gLineNum!=args.editorctl_wid.point() || gCol!=args.editorctl_wid.p_col || gScrollInfo!=args.editorctl_wid._scroll_page())) ||
            (args.isMinimap && (!args.editorctl_wid.p_IsMinimap || _minimap_tooltip_get_mouse_line(mouse_linenum,args.editorctl_wid,mx,my) || _MinimapInScroll(args.editorctl_wid))) ||
            (gBBWid && !_iswindow_valid(gBBWid));

   //++debug_count;message("debug_count="debug_count);
   // Click and drag in HTML window to select text
   if (_chdebug) {
      say("_ECTimerCallback H"__LINE__": in_rect="in_rect" other="other" capture="mou_is_captured());
   }
   if ((!in_rect || other) && !mou_is_captured()) {
      if (in_rect) {
         gmx=mx;gmy=my;
         //say('set***********');
      }
      //say('mx='mx' my='my);
      //say('x='x' y='y' xw='(x+width)' yw='(y+height));
      // The form was closed
      _terminate_hover_over_popup();
      if (_no_child_windows()) {
         if (_chdebug) {
            say("_ECTimerCallback: OUT H"__LINE__);
         }
         _chdebug = orig_chdebug;
         return;
      }
      if (!in_rect && !other && !args.isMinimap) {
         args.editorctl_wid._mouse_move();
      }
      if (_chdebug) {
         say("_ECTimerCallback: OUT H"__LINE__);
      }
      _chdebug = orig_chdebug;
      return;
   }
   //++debug_count;message("debug_count="debug_count" u2="form_wid.p_user2);
   // Enforce that all tooltip's windown ancestors must be visible in
   // order for tooltip to be visible:
   //IF (window is up OR timer has expired)

   // IF the message is already up for this window
   if (!gBBWid) {
      //GetMessagePosition(CurrentWid,x,y);
      //_map_xy(Wid.p_parent,0,x+width,y);

      //message((++debug_count)' form_wid.p_name='form_wid.p_name' x='x' y='y);
      if (args.isMinimap) {

         gBBWid=args.editorctl_wid.show('-hidden -nocenter _minimap_tooltip_form',args.editorctl_wid,gbuf_id);
         _minimap_tooltip_move_window(mouse_linenum,args.editorctl_wid,mx,my,true);

      } else {

         args.editorctl_wid.save_pos(auto orig_pos);
         args.editorctl_wid.p_cursor_x=mx;
         args.editorctl_wid.p_cursor_y=my;
         symbol_linenum := (int)args.editorctl_wid.point('L');
         args.editorctl_wid.restore_pos(orig_pos);

         gBBWid=args.editorctl_wid.show('-hidden -nocenter _editorctl_tooltip_form',args.editorctl_wid);
         _dxy2lxy(SM_TWIP,args.wx,args.wy);
         gBBWid._move_window(args.wx,args.wy,gBBWid.p_width,gBBWid.p_height);
         parse args.header with . "<hr>" auto extra_header;

         VSAUTOCODE_ARG_INFO arg_info;
         VSAUTOCODE_ARG_INFO list[];
         if (args.tagList._length() > 0) {
            bool been_there_done_that:[];
            langId := args.editorctl_wid.p_LangId;
            foreach (auto cm in args.tagList) {
               if (cm.language == "") cm.language = langId;
               prototype := args.editorctl_wid.extension_get_decl(langId,cm,VSCODEHELPDCLFLAG_SHOW_ACCESS|VSCODEHELPDCLFLAG_SHOW_CLASS|VSCODEHELPDCLFLAG_SHOW_STATIC|VSCODEHELPDCLFLAG_VERBOSE);
               tag_autocode_arg_info_from_browse_info(arg_info, cm, prototype);
               if (_chdebug) {
                  tag_browse_info_dump(cm, "_ECTimerCallback", 1);
               }
               key := cm.member_name";"cm.class_name";"cm.type_name";"_file_case(cm.file_name)";"cm.line_no";" prototype"<br>":+cm.doc_comments;
               if (been_there_done_that._indexin(key)) continue;
               been_there_done_that:[key] = true;
               arg_info.ParamNum=-1;
               all_comments := extra_header;
               if (length(args.msg) > 0) {
                  all_comments :+= args.msg;
               }
               if (all_comments != "") {
                  if (beginsWith(cm.doc_comments, "Evaluated type:")) all_comments :+= "<br>";
                  else if (cm.doc_comments != "") all_comments :+= "<hr>";
               }
               all_comments :+= cm.doc_comments;
               arg_info.tagList[0].comment_flags = VSCODEHELP_COMMENTFLAG_HTML;
               arg_info.tagList[0].comments = all_comments;
               list :+= arg_info;
            }
         } else {
            arg_info.ParamName="";
            arg_info.ParamNum=0;
            arg_info.ParamType="";
            arg_info.ParamKeyword="";
            arg_info.prototype = args.header;
            arg_info.arglength._makeempty();
            arg_info.argstart._makeempty();
            arg_info.tagList._makeempty();
            arg_info.tagList[0].filename = "";
            arg_info.tagList[0].linenum  = symbol_linenum;
            arg_info.tagList[0].comment_flags = VSCODEHELP_COMMENTFLAG_HTML;
            arg_info.tagList[0].comments = args.msg;
            arg_info.tagList[0].taginfo = null;
            arg_info.tagList[0].browse_info = null;
            arg_info.tagList[0].class_type = null;
            list[0] = arg_info;
         }

         HYPERTEXTSTACK stack;
         stack.HyperTextTop=0;
         stack.HyperTextMaxTop=stack.HyperTextTop;
         stack.s[stack.HyperTextTop].TagIndex=0;
         stack.s[stack.HyperTextTop].TagList = list;

         if (_chdebug) {
            say("_ECTimerCallback: SHOW COMMENTS H"__LINE__);
            _dump_var(arg_info, "_ECTimerCallback H"__LINE__": arg_info");
         }
         gBBWid.ctlminihtml1.p_user=stack;
         gBBWid.ctlminihtml2.p_user=0;
         gBBWid.ShowCommentHelp(false, false, gBBWid, args.editorctl_wid, true);

         // kill the timer
         if (BBTimerHandle > 0) {
            _kill_timer(BBTimerHandle);
            BBTimerHandle=-1;
         }
      }
      gBBWid._ShowWindow(SW_SHOWNOACTIVATE_FOCUS_LATER);
      //gBBWid.p_visible=true;
      if (_chdebug) {
         say("_ECTimerCallback: OUT H"__LINE__);
      }
      _chdebug = orig_chdebug;
      return;
   }

   if (gBBWid && args.isMinimap && orig_in_rect) {
      _minimap_tooltip_move_window(mouse_linenum,args.editorctl_wid,mx,my,false);
   }

   // kill the timer
   _chdebug = orig_chdebug;
   if (BBTimerHandle > 0) {
      _kill_timer(BBTimerHandle);
      BBTimerHandle=-1;
   }
}

/**
 * Prevents a tooltip window from popping up by killing any window that has 
 * already popped up and killing any timers that might be waiting to pop up. 
 *  
 * Used to prevent tooltips interfering with mouse operations. 
 */
void _KillMouseOverBBWin(bool always_kill=false)
{
   if (!always_kill && gBBWid && _iswindow_valid(gBBWid) && gBBWid.p_name=='_minimap_tooltip_form' && gBBWid.ctledit1.p_window_id==_get_focus()) {
      return;
   }
   _terminate_hover_over_popup();
}
static void _ConsiderBBWin(_str header,
                           _str msg,
                           _str OrigLineNum,
                           int OrigCol,
                           bool below=false,
                           int cursor_x=0,
                           int width=0,
                           VS_TAG_BROWSE_INFO (&tagList)[] = null)
{
   if (BBTimerHandle<0) {
      x := 0;
      y := 0;
      _map_xy(p_window_id,0,x,y);
      x+=cursor_x;

      orig_SoftWrap := p_SoftWrap;
      p_SoftWrap=false;
      y+=p_cursor_y;
      p_SoftWrap=orig_SoftWrap;

      if (!width) {
         width=_adjusted_windent_x();
      }
      height := p_font_height;
      wx := x;
      wy := y;
      if (below) {
         // If we display this dialog below the font height, a scroll bar can't
         // be used.
         wy+=p_font_height;
      } else {
         wx+=width;
      }

      gbuf_id=p_buf_id;
      gLineNum=OrigLineNum;
      gCol=OrigCol;
      gScrollInfo=_scroll_page();

      ECTimerCallbackArgs args;
      args.editorctl_wid = p_window_id;
      args.isMinimap = false;
      args.x = x;
      args.y = y;
      args.width = width;
      args.height = height;
      args.wx = wx;
      args.wy = wy;
      args.header = header;
      args.msg = msg;
      args.tagList = tagList;
      args.chdebug = _chdebug;

      BBTimerHandle=_set_timer(BBTIMER_INTERVAL,_ECTimerCallback,args);
   }
}

static void _ConsiderBBWin_minimap(int mx,int my)
{
   if (BBTimerHandle<0) {
      if (!_default_option(VSOPTION_MINIMAP_SHOW_TOOLTIP)) {
         return;
      }
      typeless mouse_linenum;
      if (_minimap_tooltip_get_mouse_line(mouse_linenum,p_window_id,mx,my)) {
         return;
      }

      x := 0;
      y := 0;
      _map_xy(p_window_id,0,x,y);

      width  := p_client_width;
      height := p_client_height;
      wx := 0;  // not used
      wy := 0;  // not used
      //int minimap_sizebar_width=_get_minimap_sizebar_width();
      //x-=minimap_sizebar_width;width+=minimap_sizebar_width;
      gbuf_id=p_buf_id;
      gLineNum=mouse_linenum;
      gBBWid_minimap_had_focus=false;
      gBBWid_minimap_had_selection=select_active()!=0;
      gCol=1;
      gScrollInfo=_scroll_page();

      ECTimerCallbackArgs args;
      args.editorctl_wid = p_window_id;
      args.isMinimap = p_IsMinimap;
      args.x = x;
      args.y = y;
      args.width = width;
      args.height = height;
      args.wx = wx;
      args.wy = wy;
      args.header = "";
      args.msg = "";
      args.tagList._makeempty();
      args.chdebug = _chdebug;

      BBTimerHandle=_set_timer(BBTIMER_INTERVAL,_ECTimerCallback,args);
   }
}

static void _MaybeCloseBBWid() 
{
   if (gBBWid && _iswindow_valid(gBBWid)) {
      in_form_rect := true;
      mx := gBBWid.mou_last_x('D');
      my := gBBWid.mou_last_y('D');
      _map_xy(0,gBBWid,mx,my);
      if (mx < 0 || mx > _lx2dx(SM_TWIP,gBBWid.p_width)) {
         in_form_rect=false;
      } else if (my > _ly2dy(SM_TWIP, gBBWid.p_height)) {
         in_form_rect=false;
      } else if (my < -p_font_height) {
         in_form_rect=false;
      }
      minihtml1 := gBBWid._find_control("ctlminihtml1");
      if (minihtml1 > 0 && minihtml1.p_object == OI_MINIHTML) {
         HYPERTEXTSTACK stack = minihtml1.p_user;
         if (stack.HyperTextTop > 0) in_form_rect=true;
      }
      if (!in_form_rect) {
         _KillMouseOverBBWin();
      } else {
         if (my > 0) {
            return;
         }
      }
   }
}

void _MouseMoveTimerCallback(_str args)
{
   typeless editorctl_wid;
   parse args with editorctl_wid;

   do {
      // invalid argument
      if (!isinteger(editorctl_wid)) {
         break;
      }
      // window does not exist any more
      if (!_iswindow_valid(editorctl_wid)) {
         break;
      }
      // window is not an editor control
      if (!editorctl_wid._isEditorCtl()) {
         break;
      }
      // SlickEdit lost focus
      if (!_AppActive()) {
         break;
      }
      
      // We need to be idle for a tenth of a second
      if (_idle_time_elapsed() < def_tag_hover_editor_delay) {
         _MaybeCloseBBWid();
         return;
      }

      // kill this timer
      if (BBTimerHandle > 0) {
         _kill_timer(BBTimerHandle);
         BBTimerHandle=-1;
      }

      // kill the old form if the mouse wanders outside of it.
      _MaybeCloseBBWid();

      // handle the mouse event, this might start a new timer to show the message
      // double check that the editor control hadn't magically vanished
      if (_iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
         editorctl_wid.handle_mouse_move();
      }
      return;

   } while (false);

   // kill this timer
   _KillMouseOverBBWin();
   if (BBTimerHandle > 0) {
      _kill_timer(BBTimerHandle);
      BBTimerHandle=-1;
   }
}

static _str getStreamMarkerMessage(int mx,int my, int &width, int &cursor_x) 
{
   goverURL = false;
   OrigLineNum := point();
   OrigCol := p_col;
   save_pos(auto p);
   _map_xy(0,p_window_id,mx,my);

   // adjust screen position if we are scrolled
   if (p_scroll_left_edge >= 0) {
      _str line_pos,down_count,SoftWrapLineOffset;
      parse _scroll_page() with line_pos down_count SoftWrapLineOffset;
      goto_point(line_pos);
      down((int)down_count);
      set_scroll_pos(p_scroll_left_edge,0,(int)SoftWrapLineOffset);
   }

   p_cursor_x=mx;
   p_cursor_y=my;
   cursorOffset := _nrseek();
   int list[];
   typeless linenum=point('L');
   _str sLineOffset;
   parse point() with sLineOffset .;
   LineOffset := (long)sLineOffset;
   stream_marker_msg := "";
   int list2[];
   LineLen := _line_length(true);
   //say('getStreamMarkerMessage() p_cursor_x='p_cursor_x' y='p_cursor_y' offset='LineOffset);

   _StreamMarkerFindList(list2,p_window_id,LineOffset,LineLen,LineOffset,0);
   VSSTREAMMARKERINFO trinfo;
   for (i:=0;i<list2._length();++i) {
      _StreamMarkerGet(list2[i],trinfo);
      //say('m('i')='trinfo.msg);
      if (trinfo.StartOffset>=LineOffset && trinfo.StartOffset<LineOffset+LineLen) {
         if (trinfo.msg != "" && trinfo.StartOffset<=cursorOffset && 
             trinfo.StartOffset+trinfo.Length>=cursorOffset) {
            _maybe_append(stream_marker_msg, "<br>");
            stream_marker_msg :+= trinfo.msg;
            break;
         }
      }
   }

   // nothing found
   if (stream_marker_msg == "") {
      restore_pos(p);
      return "";
   }

   _nrseek(trinfo.StartOffset);
   cursor_x=p_cursor_x;
   _nrseek(trinfo.StartOffset+trinfo.Length);
   width=p_cursor_x-cursor_x;

   //say('cursor_x='cursor_x);
   //say('width='width);
   //say('have OrigCol='OrigCol' width='width' cursor_x='cursor_x);
   index := find_index('urlMarkerType', MISC_TYPE);
   urlMarkerType := (int)name_info(index);
   gURL = "";
   if (urlMarkerType == trinfo.type) {
      gURL = get_text((int)trinfo.Length, (int)trinfo.StartOffset);
      goverURL = true;
      if (p_mouse_pointer != MP_HAND) {
         gpreURLMousePointer = p_mouse_pointer;
      }
      gURL_window_id = p_window_id;
      if (gmodKeyDown && !_isMac()) {
         gURL_window_id.p_mouse_pointer = MP_HAND;
      }
      width = _text_width(gURL);
   }
   screen_width := p_width;
   if (cursor_x+width > screen_width) {
      cursor_x -= (cursor_x+width)-screen_width; 
   }
   url_info := "";
   if (goverURL && pos('http://', gURL) == 1) {

      // test case http://www.slickedit.com/
      _xlat_default_font(CFG_FUNCTION_HELP, auto fontName, auto pointSizex10, auto fontFlags, auto fontHeight);
      imageSize := getImageSizeForFontHeight(fontHeight);
      url_info="<a href=\"<<open-url "gURL:+
         "\" lbuttondown><img src=vslick://_f_arrow_into.svg@"imageSize"></a>&nbsp;";
   }
   //_ConsiderBBWin(url_info:+result,OrigLineNum,OrigCol,true,cursor_x,width);
   //_ConsiderBBWin(result,OrigLineNum,OrigCol,true,16,200);
   //say('open');
   restore_pos(p);
   return url_info:+stream_marker_msg;
}
/**
 * The open_url_in_assoc_app command attempts to intelligently open the URL the 
 * cursor is in: 
 * <ul>
 *    <li>First, attempt to use the associated application found in the File
 *    Extension Manager.</li>
 *    <li>Second, attempt to use the associated application found in the
 *    registry (on Windows systems).</li>
 *    <li>Third, open with the default web browser</li>
 * </ul>
 *  
 * @see goto_url
 * @see open_url 
 *  
 * @categories Buffer_Functions
 */
_command void open_url_in_assoc_app () name_info(',')
{
   if (!def_url_support) {
      return;
   }
   int cursorOffset = _nrseek();
   typeless linenum = point('L');
   _str sLineOffset;
   parse point() with sLineOffset .;
   long LineOffset = (long)sLineOffset;
   result := "";
   int i;
   int list[];
   LineLen := _line_length(true);

   _StreamMarkerFindList(list, p_window_id, LineOffset, LineLen, VSNULLSEEK,0);
   VSSTREAMMARKERINFO trinfo;
   for (i=0;i<list._length();++i) {
      _StreamMarkerGet(list[i],trinfo);
      if (trinfo.StartOffset>=LineOffset && trinfo.StartOffset<LineOffset+LineLen) {
         if (trinfo.msg!='' && trinfo.StartOffset<=cursorOffset && 
             trinfo.StartOffset+trinfo.Length>cursorOffset) {
            gURL = get_text((int)trinfo.Length, (int)trinfo.StartOffset);
            break;
         }
      }
   }

   maybeOpenURL();
}

/**
 * This function is called by the editor key binding for
 * MOUSE_MOVE.  When the mouse is over a bitmap added by one of the
 * _LineMarkerAdd, _LineMarkerAdd(), or _LineMarkerAddB() functions, a message
 * is displayed.
 */
static void handle_mouse_move(bool forceUpdate=false)
{
   if (_chdebug) {
      say("handle_mouse_move H"__LINE__": IN");
   }
   mx := mou_last_x('D');
   my := mou_last_y('D');
   if (!forceUpdate && gmx==mx && gmy==my) {
      if (_chdebug) {
         say("handle_mouse_move H"__LINE__": MOUSE IN SAME POSITION");
      }
      return;
   }
   gmy=my;gmx=mx;
   gInMouseMoveHandler=true;
   if (_isEditorCtl(false) && 
       !_tbInDragDropCtlMode() && 
       _AppActive() && 
       p_hex_mode!=HM_HEX_ON) {

      if (p_IsMinimap) {

         if (_chdebug) {
            say("handle_mouse_move H"__LINE__": MINIMAP CASE");
         }
         _ConsiderBBWin_minimap(mx,my);

      } else if (mou_last_x()<_adjusted_windent_x() && _default_option(VSOPTION_SHOWTOOLTIPS)) {

         if (_chdebug) {
            say("handle_mouse_move H"__LINE__": GUTTER");
         }
         OrigLineNum := point();
         OrigCol := p_col;
         save_pos(auto p);
         _map_xy(0,p_window_id,mx,my);

         // adjust screen position if we are scrolled
         if (p_scroll_left_edge >= 0) {
            _str line_pos,down_count,SoftWrapLineOffset;
            parse _scroll_page() with line_pos down_count SoftWrapLineOffset;
            goto_point(line_pos);
            down((int)down_count);
            set_scroll_pos(p_scroll_left_edge,0,(int)SoftWrapLineOffset);
         }

         p_cursor_x=mx;
         p_cursor_y=my;
         int list[];
         typeless linenum=point('L');
         parse point() with auto sLineOffset .;
         LineOffset := (long)sLineOffset;
         _LineMarkerFindList(list,p_window_id,(typeless)point('L'),LineOffset,false);
         header := "";
         msg := "";
         foreach (auto markerId in list) {
            VSLINEMARKERINFO info;
            info.msg="";
            status := _LineMarkerGet(markerId, info);
            //say('m('markerId')='info.msg);
            // This is a workaround so that we can use the line marker message in Eclipse to 
            // determine if a marker is a pushed bookmark.  We check if the message is empty,
            // and if it isn't empty, we check that either it's not a 'Pushed Bookmark' message, 
            // or that def_show_bm_tags is set before actually showing the message.
            if (!status && info != null && info.msg!="" && (!pos(get_message(VSRC_PUSHED_BOOKMARK_NAME),info.msg) || def_show_bm_tags)) {
               // add a little more information for bookmarks
               _maybe_append(header, "<br><hr>");
               bookmarkId := _BookmarkFind(info.msg);
               if (bookmarkId >= 0) header :+= "Bookmark: ";
               header :+= info.msg;
            }
         }
         int list2[];
         LineLen := _line_length(true);
         _StreamMarkerFindList(list2,p_window_id,LineOffset,LineLen,VSNULLSEEK,0);
         foreach (markerId in list2) {
            VSSTREAMMARKERINFO trinfo;
            trinfo.msg="";
            status := _StreamMarkerGet(markerId,trinfo);
            //say('m('markerId')='trinfo.msg);
            if (!status && trinfo != null && trinfo.StartOffset>=LineOffset && trinfo.StartOffset<LineOffset+LineLen) {
               if (trinfo.msg!='' && trinfo.BMIndex) {
                  _maybe_append(header, "<br><hr>");
                  header :+= trinfo.msg;
               }
            }
         }

         // Does the current line have a selective-display [+] or [-] bitmap?
         lineflags := _lineflags();
         comment_msg := "";
         if (def_show_plusminus_tooltip) {
            if (lineflags & PLUSBITMAP_LF) {
               save_pos(auto before_comment_test);
               p_line = p_line;
               _first_non_blank();
               right();
               _maybe_append(header, "<br><hr>");
               header :+= "Expand code block";
               if (_in_comment()) {
                  _clex_skip_blanks();
                  _UpdateContext(true);
                  context_id := tag_get_current_context(auto cur_tag_name, auto cur_tag_flags, 
                                                        auto cur_type_name, auto cur_type_id, 
                                                        auto cur_context, auto cur_class, auto cur_package);
                  if (context_id > 0) {
                     tag_get_detail2(VS_TAGDETAIL_context_line, context_id, auto cur_line);
                     if (cur_line == p_RLine) {
                        _ExtractTagComments2(auto comment_flags, comment_msg, 500, cur_tag_name, p_buf_name, cur_line);
                        if (comment_msg != "") {
                           header = "Expand comment block";
                           _make_html_comments(comment_msg,comment_flags,"",cur_tag_name,p_LangId=="e"||p_LangId=="c",p_LangId);
                           msg = comment_msg;
                        }
                     }
                  } 
               }
               if (comment_msg == "") {
                  restore_pos(before_comment_test);
                  get_plusminus_range(auto first_line, auto last_line);
                  num_lines := ((last_line-first_line > 500)? 500 : (last_line-first_line+1));
                  _GetHTMLColorCoding(p_window_id, first_line, num_lines, msg);
                  if (last_line-first_line > 500) {
                     msg :+= "<font color=\"black\" style=\"background-color: white\"><b>Remaining "(last_line-first_line-499)" lines truncated.</b></font>";
                  }
               }
               restore_pos(before_comment_test);
            } else if (lineflags & MINUSBITMAP_LF) {
               _maybe_append(header, "<br><hr>");
               header :+= "Collapse code block";
            }
         }

         if (header!="" || msg!="") {
            _ConsiderBBWin(header,msg,OrigLineNum,OrigCol);
            //say('open');
         }
         restore_pos(p);
         //message('xxxgot here len'list._length());

      } else if (mou_last_x()>=_adjusted_windent_x()) {

         if (_chdebug) {
            say("handle_mouse_move H"__LINE__": IN EDITOR WINDOW");
         }
         VS_TAG_BROWSE_INFO tagList[];
         smWidth := smCursorX := 0;
         streamMessage := getStreamMarkerMessage(mx,my,smWidth,smCursorX);
         OrigLineNum := point();
         OrigCol := p_col;
         width := 0;
         cursor_x := p_cursor_x;
         msg := "";
         debug_expr := "";
         save_pos(auto p);
         header := debug_get_mouse_expr(cursor_x,width,&streamMessage,msg,debug_expr,tagList);
         if (_chdebug) {
            say("handle_mouse_move H"__LINE__": header="header);
            say("handle_mouse_move H"__LINE__": debug_expr="debug_expr);
            say("handle_mouse_move H"__LINE__": msg="msg);
            _dump_var(tagList, "handle_mosue_move");
         }
         if (msg == "" && smWidth>0) {
            width=smWidth;
            cursor_x = smCursorX;
         }
         if (debug_expr != "" && debug_expr != header) {
            _maybe_append(msg, "<hr>");
            msg :+= debug_expr;
         }
         if (streamMessage != "") {
            _maybe_append(msg, "<br>");
            msg :+= streamMessage;
         }
         if (header != "" || msg != "" || tagList._length() > 0) {
            // if we come up with a different message, 
            // we need to force the mouse-over help to restart
            static _str last_msg;
            curr_msg := header"<br>"msg"<br>"debug_expr;
            if (gBBWid && last_msg != null && last_msg!="" && curr_msg != last_msg) {
               minihtml1 := gBBWid._find_control("ctlminihtml1");
               if (minihtml1) {
                  HYPERTEXTSTACK stack = minihtml1.p_user;
                  if (stack.HyperTextTop <= 0) {
                     _KillMouseOverBBWin();
                  }
               }
            }
            last_msg = curr_msg;
            if (_chdebug) {
               say("handle_mouse_move H"__LINE__": msg="msg" width="width" cursor_x="cursor_x);
            }
            _ConsiderBBWin(header,msg,OrigLineNum,OrigCol,below:true,cursor_x,width,tagList);
         }
         restore_pos(p);
      }
   }
   if (_chdebug) {
      say("handle_mouse_move H"__LINE__": OUT");
   }
   gInMouseMoveHandler=false;
}

_command void codehelp_trace_mouse_over_help() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Parameter help");
      return;
   }
   if (_get_focus()!=p_window_id) {
      _beep();
      return;
   }
   _KillMouseOverBBWin();
   orig_chdebug := _chdebug;
   _chdebug = 1;
   handle_mouse_move(forceUpdate:true);
   _chdebug = orig_chdebug;
}



/**
 * This function is called by the editor key binding for
 * MOUSE_MOVE.  When the mouse is over a bitmap added by one of the
 * _LineMarkerAdd, _LineMarkerAdd(), or _LineMarkerAddB() functions, a message
 * is displayed.
 */
void _mouse_move()
{
   // check for situations where mouse-over should not happen
   if (!_isEditorCtl(false) || !_AppActive() || (p_hex_mode == HM_HEX_ON) || _tbInDragDropCtlMode()) {
      _KillMouseOverBBWin();
      return;
   }

   // start timer if we do not already have one pending
   if (BBTimerHandle < 0) {
      if (p_IsMinimap) {
         handle_mouse_move();
      } else {
         min_interval := min(def_tag_hover_editor_delay, BBTIMER_INTERVAL);
         BBTimerHandle=_set_timer(p_IsMinimap? 10 : min_interval, _MouseMoveTimerCallback, p_window_id);
      }
   }
}

/**
 * Display the specified picture, tracking the current line within
 * the current editor control.
 * 
 * @param pic_file_name    name of picture to display
 * @param erase            erase the picture from the gutter
 * 
 * @return 0 on success, <0 on error.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @see mouse_drag
 */
int mouse_show_drag_pic(_str pic_file_name, bool erase=false)
{
   // erase the existing picture
   static int pic_id;
   if (pic_id != 0) {
      _LineMarkerRemove(pic_id);
      pic_id = 0;
   }

   // do not draw new picture?
   if (erase) {
      return 0;
   }

   // create a pic type for these events
   static int pic_type;
   if (pic_type == 0) {
      pic_type = _MarkerTypeAlloc();
   }

   // update the picture index
   int pic_index = _find_or_add_picture(pic_file_name);
   if (pic_index < 0) {
      return pic_index;
   }

   // add the pic to be displayed
   pic_id = _LineMarkerAdd(p_window_id, p_line, false, 0, pic_index, pic_type, 'asdf');
   return pic_id;
}
/**
 * This is a generic function for dragging the mouse within an
 * editor control.  It can be used (for example) to move icons
 * in the gutter.
 * <p>
 * The starting point for this function is typically in response
 * to a lbutton_down event().  The mouse drag ends when we get
 * a lbutton_up() event or the user hits escape.
 * 
 * @param move_callback    callback for move animation events
 * @param move_picture     picture to show in gutter as mouse moves
 * 
 * @return 0 on success, COMMAND_CANCELLED_RC on cancel.
 *
 * @see debug_mouse_drag_instruction_pointer()
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Mouse_Functions
 */
int mouse_drag( int (*move_callback)(int wid), _str move_picture='' )
{
   mou_mode(1);
   mou_capture();
   mou_set_pointer(MP_ALLOWDROP);

   status := 0;
   int init_delay=def_init_delay;
   int count=DEF_CHG_COUNT;
   max_skip := 1;
   int mx,my;

   done := false;
   while (!done) {
      typeless event=get_event();
      switch (event) {
      case ON_TIMER:
      case MOUSE_MOVE:
         mx=mou_last_x('m');  // 'm' specifies mouse position in current scale mode
         my=mou_last_y('m');

         /* we are outside the window. */
         /* Determine which side of window we are outside. */
         past_bottom := past_top := past_right := past_left := new_x := new_y := 0;
         mou_set_scroll_directions(past_bottom,past_right,past_top,past_left,new_x,new_y,mx,my);
         _set_scroll_speed(init_delay,max_skip,count,mx,my);

         // mapp the mouse coordinates to the cursor
         p_cursor_y = my;
         if ( !mou_in_window3(mx,my) ) {
            if (past_bottom) {
               cursor_down(1);
               _set_timer(init_delay*2);
            } else if (past_top) {
               cursor_up(1);
               _set_timer(init_delay*2);
            }
         } else {
            _kill_timer();
         }
         if (move_callback != null) {
            (*move_callback)(p_window_id);
         }
         if (move_picture != '') {
            mouse_show_drag_pic(move_picture);
         }
         break;
      case LBUTTON_UP:
         mx=mou_last_x('m');  // 'm' specifies mouse position in current scale mode
         my=mou_last_y('m');
         p_cursor_x = mx;
         p_cursor_y = my;
         _kill_timer();
         done=true;
         break;
      case ESC:
         status=COMMAND_CANCELLED_RC;
         done=true;
         _kill_timer();
         break;
      }
   }

   mouse_show_drag_pic(move_picture,true);
   mou_set_pointer(MP_DEFAULT);
   mou_mode(0);
   mou_release();
   return status;
}


void _UpdateURLsMousePointer (bool mKD=false)
{
   gmodKeyDown = mKD;
   if (goverURL && !_isMac() && _iswindow_valid(gURL_window_id) && gURL_window_id._isEditorCtl(false)) {
      if (gmodKeyDown) {
         gURL_window_id.p_mouse_pointer = MP_HAND;
      } else {
         gURL_window_id.p_mouse_pointer = gpreURLMousePointer;
      }
   }
}


/*
a
adf
afd
afsd
xxxx
yyy
*/
#if 0
   static int gStreamMarkerIndex;
   static int gColorIndex;
_command void test3()
{
   int type=_MarkerTypeAlloc();
   _MarkerTypeSetFlags(type,VSMARKERTYPEFLAG_AUTO_REMOVE/*|VSMARKERTYPEFLAG_UNDO|VSMARKERTYPEFLAG_COPYPASTE|VSMARKERTYPEFLAG_DRAW_BOX*/);
   _str msg;
   gColorIndex=_AllocColor(0xffffff,0xffffff,F_NO_COLOR_BLENDING);
   //gColorIndex=_AllocColor(0xffffff,0xffffff);
   msg=substr('',1,10000,'x');
   //msg="line 1<br>line2";
   //int gStreamMarkerIndex=_LineMarkerAdd(p_window_id,p_line,0,4,find_index('_ed_plus.svg',PICTURE_TYPE),type,msg);
   int i;
   width := 3;
   for (i=0;i<1;++i) {
      gStreamMarkerIndex=_StreamMarkerAdd(p_window_id,_nrseek(),width,false,0 /*find_index('_ed_plus.svg',PICTURE_TYPE)*/,type,"this is a test");
      //_StreamMarkerSetStyleColor(gStreamMarkerIndex,0xff);
      _StreamMarkerSetTextColor(gStreamMarkerIndex,gColorIndex);
      p_col+=width+2;
   }
   //gStreamMarkerIndex=_LineMarkerAdd(p_window_id,p_line,false,0,find_index('_ed_plus.svg',PICTURE_TYPE),type,"this is a test");
   say(gStreamMarkerIndex);

   //_LineMarkerSetMousePointer(gStreamMarkerIndex,MP_HAND);

   //_LineMarkerAdd(p_window_id,p_line,0,0,type,"line 1<br>line2");
   //_MarkerTypeSetCallbackMouseEvent(type,LBUTTON_DOWN,test4);
   //_MarkerTypeSetFlags(type,VSMARKERTYPEFLAG_AUTO_REMOVE);
}
_command void test4()
{

   _default_color(gColorIndex,0xffffff,0xff00);
   //_StreamMarkerSetTextColor(gStreamMarkerIndex,CFG_MODIFIED_LINE);
   //VSSTREAMMARKERINFO info;
   //_StreamMarkerGet(gStreamMarkerIndex,info);
   //_StreamMarkerSetLength(gStreamMarkerIndex,6);
   //_StreamMarkerSetLength(gStreamMarkerIndex,info.Length+1);
   //_message_box(arg(1));
   //return(0);
}
#endif
