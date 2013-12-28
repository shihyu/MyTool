////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44890 $
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
#import "main.e"
#endregion

defeventtab default_keys;

/*
def  'A-M- '= codehelp_complete;
def  'A-M-,'= pop_bookmark;
def  'A-M-.'= push_tag;
*/

def  ' '= maybe_complete;
def  ')'= keyin_match_paren;
def  '*'= rexx_star;
def  '?'= maybe_list_matches;
def  'ESC'= cmdline_toggle;
def  'HOME'= begin_line_text_toggle;
def  'END'= end_line;
def  'LEFT'= cursor_left;
def  'RIGHT'= cursor_right;
def  'UP'= cursor_up;
def  'DOWN'= cursor_down;
def  'PGUP'= page_up;
def  'PGDN'= page_down;

def  'M-LEFT'= begin_line;
def  'M-RIGHT'= end_line;
def  'M-UP'= top_of_buffer;
def  'M-DOWN'= bottom_of_buffer;

def  'S- '= keyin_space;
def  'S-HOME'= cua_select;
def  'S-END'= cua_select;
def  'S-LEFT'= cua_select;
def  'S-RIGHT'= cua_select;
def  'S-UP'= cua_select;
def  'S-DOWN'= cua_select;
def  'S-PGUP'= cua_select;
def  'S-PGDN'= cua_select;

def  'S-M-HOME'= cua_select;
def  'S-M-END'= cua_select;
def  'S-M-LEFT'= cua_select;
def  'S-M-RIGHT'= cua_select;
def  'S-M-UP'= cua_select;
def  'S-M-DOWN'= cua_select;

def  'C-HOME'= top_of_buffer;
def  'C-END'= bottom_of_buffer;
def  'C-PGUP'= top_of_window;
def  'C-PGDN'= bottom_of_window;

def  'C-S- '= complete_more;
def  'C-S-,'= complete_prev;
def  'C-S-.'= complete_next;
def  'C-S-HOME'= cua_select;
def  'C-S-END'= cua_select;
def  'C-S-LEFT'= cua_select;
def  'C-S-RIGHT'= cua_select;
def  'C-S-UP'= prev_error;
def  'C-S-DOWN'= next_error;

def  'A-LEFT'= prev_word;
def  'A-RIGHT'= next_word;
def  'A-UP'= prev_paragraph;
def  'A-DOWN'= next_paragraph;

def  'C-A-LEFT'= prev_sexp;
def  'C-A-RIGHT'= next_sexp;
def  'C-A-UP'= backward_up_sexp;
def  'C-A-DOWN'= forward_down_sexp;
def  'C-A-S-LEFT'= select_prev_sexp;
def  'C-A-S-RIGHT'= select_next_sexp;
def  'C-A-BACKSPACE'= cut_prev_sexp;

def  'C-M-LEFT'= prev_sexp;
def  'C-M-RIGHT'= next_sexp;
def  'C-M-UP'= backward_up_sexp;
def  'C-M-DOWN'= forward_down_sexp;
def  'C-M-S-LEFT'= select_prev_sexp;
def  'C-M-S-RIGHT'= select_next_sexp;
def  'C-M-BACKSPACE'= cut_prev_sexp;

def  'A-S-LEFT'= cua_select;
def  'A-S-RIGHT'= cua_select;
def  'A-S-UP'= cua_select;
def  'A-S-DOWN'= cua_select;

def  'C- '= codehelp_complete;
def  'C-,'= pop_bookmark;
def  'C-.'= push_tag;
def  'C-/'= push_ref;
def  'C-='= diff;

def  'A-,'= function_argument_help;
def  'A-.'= list_symbols;
def  'A-M-.'= list_symbols;
def  'A-M-,'= function_argument_help;
def  'M-.'= list_symbols;
def  'M-,'= function_argument_help;

def  'M-1'= cursor_error;
def  'M-3'= activate_watch;
def  'M-4'= activate_variables;
def  'M-5'= activate_registers;
def  'M-6'= activate_memory;
def  'M-7'= activate_call_stack;

def  'A-1'= cursor_error;
def  'A-3'= activate_watch;
def  'A-4'= activate_variables;
def  'A-5'= activate_registers;
def  'A-6'= activate_memory;
def  'A-7'= activate_call_stack;

def  'C-A-A'= activate_autos;
def  'C-A-B'= activate_breakpoints;
def  'C-A-C'= activate_call_stack;
def  'C-A-H'= activate_threads;
def  'C-A-L'= activate_locals;
def  'C-A-M'= activate_members;
def  'C-A-V'= activate_variables;
def  'C-A-W'= activate_watch;

def  'C-M-A'= activate_autos;
def  'C-M-B'= activate_breakpoints;
def  'C-M-C'= activate_call_stack;
def  'C-M-H'= activate_threads;
def  'C-M-L'= activate_locals;
def  'C-M-M'= activate_members;
def  'C-M-V'= activate_variables;
def  'C-M-W'= activate_watch;

def  'CONTEXT'= context_menu;
def  'LBUTTON-DOWN'= mou_click;
def  'RBUTTON-DOWN'= mou_click_menu_block;
def  'MBUTTON-DOWN'= mou_paste;
def  'BACK-BUTTON-DOWN'= back;
def  'FORWARD-BUTTON-DOWN'= forward;
def  'LBUTTON-DOUBLE-CLICK'= mou_select_word;
def  'LBUTTON-TRIPLE-CLICK'= mou_select_line;
def  'MOUSE-MOVE'= _mouse_move;
def  'WHEEL-UP'= fast_scroll;
def  'WHEEL-DOWN'= fast_scroll;
def  'WHEEL-LEFT'= fast_scroll;
def  'WHEEL-RIGHT'= fast_scroll;
def  'S-LBUTTON-DOWN'= mou_extend_selection;
def  'C-LBUTTON-DOWN'= mou_click_copy;
def  'C-RBUTTON-DOWN'= mou_move_to_cursor;
def  'C-WHEEL-UP'= scroll_page_up;
def  'C-WHEEL-DOWN'= scroll_page_down;
def  'C-WHEEL-LEFT'= fast_scroll;
def  'C-WHEEL-RIGHT'= fast_scroll;
def  'C-S-RBUTTON-DOWN'= mou_copy_to_cursor;
def  'A-LBUTTON-DOWN'= mou_click_copy_block;

def on_keystatechange=_on_keystatechange;

def on_vsb_page_down=_sb_page_down;
def on_vsb_page_up=_sb_page_up;
def on_vsb_top=top_of_buffer;
def on_vsb_bottom=bottom_of_buffer;
def on_vsb_line_down=fast_scroll;
def on_vsb_line_up=fast_scroll;
def on_vsb_thumb_pos=_vsb_thumb_pos;
def on_vsb_thumb_track=_vsb_thumb_pos;

def on_sb_end_scroll=fast_scroll;
def on_hsb_line_down=fast_scroll;
def on_hsb_line_up=fast_scroll;
def on_hsb_top=scroll_begin_line;
def on_hsb_bottom=scroll_end_line;
def on_hsb_page_down=_sb_page_right;
def on_hsb_page_up=_sb_page_left;
def on_hsb_thumb_pos=_hsb_thumb_pos;
def on_hsb_thumb_track=_hsb_thumb_pos;

def on_got_focus=_on_got_focus;
def on_lost_focus=_on_lost_focus;
def on_select=_on_select;
def on_resize=_on_resize;
def on_close=_on_close;
def on_drop_files=_on_drop_files;
def on_init_menu=_on_init_menu;

defeventtab process_keys;
def   'C-U'=;
def   'ENTER'=                process_enter;
def   'TAB'=                  process_tab;
def   'BACKSPACE'=            process_rubout;
def   'HOME'=                 process_begin_line;
def   'UP'=                   process_up;
def   'DOWN'=                 process_down;
def   'lbutton-double-click'= cursor_error;

defeventtab grep_keys;
def   'ESC'=;
def   'ENTER'=                grep_enter;
def   'LBUTTON-DOUBLE-CLICK'= grep_lbutton_double_click;
def   'DEL'=                  grep_delete;
def   'S-UP'=                 grep_prev_file;
def   'S-DOWN'=               grep_next_file;
def   'LBUTTON-DOWN'=         grep_cursor;
def   'UP'=                   grep_cursor;
def   'DOWN'=                 grep_cursor;
def   'PGUP'=                 grep_cursor;
def   'PGDN'=                 grep_cursor;
def   'C-UP'=                 preview_cursor_up;
def   'C-DOWN'=               preview_cursor_down;
def   'C_PGUP'=               preview_page_up;
def   'C_PGDN'=               preview_page_down;

defeventtab fileman_keys;
def  ' '=                     fileman_space;
def  '!'-\128=                maybe_normal_character;

def  'A-S-A'=                 select_all;
def  'A-S-B'=                 fileman_backup;
def  'A-S-C'=                 fileman_copy;
def  'A-S-D'=                 fileman_delete;
def  'A-S-E'=                 fileman_edit;
def  'A-S-G'=                 fileman_replace;
def  'A-S-F'=                 fileman_find;
def  'A-S-M'=                 fileman_move;
def  'A-S-N'=                 fileman_keyin_name;
def  'A-S-O'=                 fsort;
def  'A-S-R'=                 for_select;
def  'A-S-P'=                 fileman_attr;
def  'A-S-T'=                 fileman_attr;

def  'M-S-A'=                 select_all;
def  'M-S-B'=                 fileman_backup;
def  'M-S-C'=                 fileman_copy;
def  'M-S-D'=                 fileman_delete;
def  'M-S-E'=                 fileman_edit;
def  'M-S-G'=                 fileman_replace;
def  'M-S-F'=                 fileman_find;
def  'M-S-M'=                 fileman_move;
def  'M-S-N'=                 fileman_keyin_name;
def  'M-S-O'=                 fsort;
def  'M-S-R'=                 for_select;
def  'M-S-P'=                 fileman_attr;
def  'M-S-T'=                 fileman_attr;

def  'ENTER'=                 fileman_enter;
def  'lbutton-double-click'=  fileman_enter;
def  'S-UP'=                  fileman_select_up;
def  'S-DOWN'=                fileman_select_down;
def  'S-PGUP'=                fileman_deselect_up;
def  'S-PGDN'=                fileman_deselect_down;
def  'F1'=                    fileman_help;

defmain()
{
   _config_modify_flags(CFGMODIFY_KEYS);
}
