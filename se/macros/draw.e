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
#import "stdprocs.e"
#endregion

static _str hside,vside,
            tleft,tright,
            arrowleft,
            arrowright,
            arrowup,
            intersect,
            fillblock,
            filldot,
            tup,tdown,
            tlc,trc,
            blc,brc;


defmain()
{
   option := arg(1);
   if ( option == '' ) {
      // Can't display help because the font is wrong.
      //_macro_delete_line()
      //command_put('draw ')
      //message(nls('Arguments: 1='\197'  2='\206'  3='\216'  4='\215'  B=Blank  or Any character'));
      return(1);
   }
   if ( command_state() ) {
      command_toggle();
   }

   if (!p_fixed_font) {
      message("Warning:  The draw command may not work well with proportional fonts.");
   }

   
   overwrite_ch := "";
   ch := "";
   utf8 := false;
   if (lowcase(_first_char(option)) == 'u') {
      utf8 = true;
      option = substr(option, 2);
   } else {
      utf8 = p_UTF8;
   }

   fillblock  = utf8? _UTF8Chr(0x2588) : 'O';
   filldot    = utf8? _UTF8Chr(0x25CF) : '*';
   arrowleft  = utf8? _UTF8Chr(0x25C0) : '<';
   arrowright = utf8? _UTF8Chr(0x25B6) : '>';
   arrowup    = utf8? _UTF8Chr(0x25B2) : '^';

   if ( option=='1' ) {
      // Single line top/bottom sides and left/right sides.
      tlc       = utf8? _UTF8Chr(0x250F) : \218;
      tdown     = utf8? _UTF8Chr(0x2533) : \194;
      tright    = utf8? _UTF8Chr(0x2523) : \195;
      intersect = utf8? _UTF8Chr(0x254B) : \197;
      hside     = utf8? _UTF8Chr(0x2501) : \196;
      trc       = utf8? _UTF8Chr(0x2513) : \191;
      tleft     = utf8? _UTF8Chr(0x252B) : \180;
      vside     = utf8? _UTF8Chr(0x2503) : \179;
      brc       = utf8? _UTF8Chr(0x251B) : \217;
      tup       = utf8? _UTF8Chr(0x253B) : \193;
      blc       = utf8? _UTF8Chr(0x2517) : \192;
   } else if ( option=='2' ) {
      // Double line top/bottom sides and left/right sides.
      tlc       = utf8? _UTF8Chr(0x2554) : \201;
      tdown     = utf8? _UTF8Chr(0x2566) : \203;
      tright    = utf8? _UTF8Chr(0x2560) : \204;
      intersect = utf8? _UTF8Chr(0x256C) : \206;
      hside     = utf8? _UTF8Chr(0x2550) : \205;
      trc       = utf8? _UTF8Chr(0x2557) : \187;
      tleft     = utf8? _UTF8Chr(0x2563) : \185;
      vside     = utf8? _UTF8Chr(0x2551) : \186;
      brc       = utf8? _UTF8Chr(0x255D) : \188;
      tup       = utf8? _UTF8Chr(0x2569) : \202;
      blc       = utf8? _UTF8Chr(0x255A) : \200;
   } else if ( option=='3' ) {
      // Single line sides and double line top/bottom sides.
      tlc       = utf8? _UTF8Chr(0x2552) : \213;
      tdown     = utf8? _UTF8Chr(0x2564) : \209;
      tright    = utf8? _UTF8Chr(0x255E) : \198;
      intersect = utf8? _UTF8Chr(0x256A) : \216;
      hside     = utf8? _UTF8Chr(0x2550) : \205;
      trc       = utf8? _UTF8Chr(0x2555) : \184;
      tleft     = utf8? _UTF8Chr(0x2561) : \181;
      vside     = utf8? _UTF8Chr(0x2502) : \179;
      brc       = utf8? _UTF8Chr(0x255B) : \190;
      tup       = utf8? _UTF8Chr(0x2567) : \207;
      blc       = utf8? _UTF8Chr(0x2558) : \212;
   } else if ( option=='4' ) {
      // Double line sides and single line top/bottom sides.
      tlc       = utf8? _UTF8Chr(0x2553) : \214;
      tdown     = utf8? _UTF8Chr(0x2565) : \210;
      tright    = utf8? _UTF8Chr(0x255F) : \199;
      intersect = utf8? _UTF8Chr(0x256B) : \215;
      hside     = utf8? _UTF8Chr(0x2500) : \196;
      trc       = utf8? _UTF8Chr(0x2556) : \183;
      tleft     = utf8? _UTF8Chr(0x2562) : \182;
      vside     = utf8? _UTF8Chr(0x2551) : \186;
      brc       = utf8? _UTF8Chr(0x255C) : \189;
      tup       = utf8? _UTF8Chr(0x2568) : \208;
      blc       = utf8? _UTF8Chr(0x2559) : \211;
   } else if ( option=='5' ) {
      // [Unicode only] Thin line top/bottom sides and left/right sides
      tlc       = utf8? _UTF8Chr(0x250C) : \218;
      tdown     = utf8? _UTF8Chr(0x252C) : \194;
      tright    = utf8? _UTF8Chr(0x251C) : \195;
      intersect = utf8? _UTF8Chr(0x253C) : \197;
      hside     = utf8? _UTF8Chr(0x2500) : \196;
      trc       = utf8? _UTF8Chr(0x2510) : \191;
      tleft     = utf8? _UTF8Chr(0x2524) : \180;
      vside     = utf8? _UTF8Chr(0x2502) : \179;
      brc       = utf8? _UTF8Chr(0x2518) : \217;
      tup       = utf8? _UTF8Chr(0x2534) : \193;
      blc       = utf8? _UTF8Chr(0x2514) : \192;
   } else if ( option=='6' ) {
      // [Unicode only] Thin line top/bottom sides and left/right sides and rounded corners
      tlc       = utf8? _UTF8Chr(0x256D) : \218;
      tdown     = utf8? _UTF8Chr(0x252C) : \194;
      tright    = utf8? _UTF8Chr(0x251C) : \195;
      intersect = utf8? _UTF8Chr(0x253C) : \197;
      hside     = utf8? _UTF8Chr(0x2500) : \196;
      trc       = utf8? _UTF8Chr(0x256E) : \191;
      tleft     = utf8? _UTF8Chr(0x2524) : \180;
      vside     = utf8? _UTF8Chr(0x2502) : \179;
      brc       = utf8? _UTF8Chr(0x256F) : \217;
      tup       = utf8? _UTF8Chr(0x2534) : \193;
      blc       = utf8? _UTF8Chr(0x2570) : \192;
   } else if ( option=='7' ) {
      // [Unicode only] Single dotted line top/bottom sides and left/right sides.
      tlc       = utf8? _UTF8Chr(0x250F) : \218;
      tdown     = utf8? _UTF8Chr(0x2533) : \194;
      tright    = utf8? _UTF8Chr(0x2523) : \195;
      intersect = utf8? _UTF8Chr(0x254B) : \197;
      hside     = utf8? _UTF8Chr(0x254D) : \196;
      trc       = utf8? _UTF8Chr(0x2513) : \191;
      tleft     = utf8? _UTF8Chr(0x252B) : \180;
      vside     = utf8? _UTF8Chr(0x254F) : \179;
      brc       = utf8? _UTF8Chr(0x251B) : \217;
      tup       = utf8? _UTF8Chr(0x253B) : \193;
      blc       = utf8? _UTF8Chr(0x2517) : \192;
   } else if ( option=='8' ) {
      // [Unicode only] Thin dotted line top/bottom sides and left/right sides
      tlc       = utf8? _UTF8Chr(0x250C) : \218;
      tdown     = utf8? _UTF8Chr(0x252C) : \194;
      tright    = utf8? _UTF8Chr(0x251C) : \195;
      intersect = utf8? _UTF8Chr(0x253C) : \197;
      hside     = utf8? _UTF8Chr(0x254C) : \196;
      trc       = utf8? _UTF8Chr(0x2510) : \191;
      tleft     = utf8? _UTF8Chr(0x2524) : \180;
      vside     = utf8? _UTF8Chr(0x254E) : \179;
      brc       = utf8? _UTF8Chr(0x2518) : \217;
      tup       = utf8? _UTF8Chr(0x2534) : \193;
      blc       = utf8? _UTF8Chr(0x2514) : \192;
   } else if ( upcase(option)=='A' ) {
      // Draw corners with '*' top/bottom with '-' and left/right with '|'
      tlc       = '*';
      tdown     = "|";
      tright    = '|';
      intersect = '+';
      hside     = '-';
      trc       = '*';
      tleft     = '|';
      vside     = '|';
      brc       = '*';
      tup       = '-';
      blc       = '*';
   } else if ( upcase(option)=='B' ) {
      // Draw with blank character.  Used to erase drawing.
      tlc       = ' ';
      tdown     = ' ';
      tright    = ' ';
      intersect = ' ';
      hside     = ' ';
      trc       = ' ';
      tleft     = ' ';
      vside     = ' ';
      brc       = ' ';
      tup       = ' ';
      blc       = ' ';
   } else {
      // Draw with any other character.
      ch=substr(option,1,1);
      tlc       = ch;
      tdown     = ch;
      tright    = ch;
      intersect = ch;
      hside     = ch;
      trc       = ch;
      tleft     = ch;
      vside     = ch;
      brc       = ch;
      tup       = ch;
      blc       = ch;
   }

   // cursor-up/cursor-down should go into imaginary space to preserve column
   orig_def_updown_col := def_updown_col;
   def_updown_col=0;

   p := null;
   old_col := 0;
   line := "";
   temp_line := "";
   message(nls('Draw running.  Press arrow keys to draw.'));
   for (;;) {
      _undo('S');
      typeless key=get_event();
      if ( key:==UP ) {
         line=_expand_tabsc_raw();
         ch=utf8_char_at(line,p_col,utf8);
         if ( ch:==vside ) {
            draw_up();
            if ( _on_line0() ) {  /* hit top of file? */
               old_col=p_col;
               insert_line(substr('',1,p_col-1):+vside);
               p_col=old_col;
               continue;
            } else {
               temp_line = _expand_tabsc_raw();
               overwrite_ch=utf8_char_at(temp_line,p_col,utf8);
               if ( (utf8_asc(overwrite_ch,utf8)<=127 || overwrite_ch:==vside) ) {
                  replace_col_utf8(temp_line, p_col, vside);
                  continue;
               }
               draw_down();
            }
         }
         save_pos(p);
         old_col=p_col;
         draw_up();
         temp_line = _expand_tabsc_raw();
         overwrite_ch=utf8_char_at(temp_line,p_col,utf8);
         restore_pos(p);
         if ( ch:==hside ) {
            /* Determine how to translate the character under the cursor by */
            /* checking characters left,right, and under the cursor. */
            if ( is_left() ) {
               if ( is_right() ) {
                  ch=tup; 
               } else { 
                  ch=brc; 
               }
            } else if ( is_right() ) {
               ch=blc;
            }
            replace_col_utf8(line, p_col, ch);
         } else if ( ch:==tdown ) {
            replace_col_utf8(line, p_col, intersect);
         } else if ( ch:==trc ) {
            replace_col_utf8(line, p_col, tleft);
         } else if ( ch:==tlc ) {
            replace_col_utf8(line, p_col, tright);
         }
         p_col=old_col;
         orig_x := p_cursor_x;
         draw_up();
         p_cursor_x = orig_x;

         if ( _on_line0() ) {
            old_col=p_col;
            insert_line('');
            p_col=old_col;
         }
         /* Determine what character to insert. */
         if ( overwrite_ch:==tup || overwrite_ch:==intersect ) {  /* use intersect character? */
            ch=intersect;
         } else if ( overwrite_ch==fillblock || overwrite_ch==filldot ) {
            ch= overwrite_ch;
         } else if ( overwrite_ch==brc ) {
            ch= tleft;
         } else if ( overwrite_ch==blc ) {
            ch= tright;
         } else if ( overwrite_ch:==hside ) {
            if ( is_left() ) {
               if ( is_right() ) { 
                  ch=tdown; 
               } else { 
                  ch=trc; 
               }
            } else if ( is_right() ) {
               ch=tlc;
            } else {
               ch=vside;
            }
         } else if ( overwrite_ch:==tdown || overwrite_ch:==tlc ||
                     overwrite_ch:==tleft || overwrite_ch:==tright ||
                     overwrite_ch:==trc ) {  /* leave character the same ? */
            ch=overwrite_ch;
         } else {
            ch=vside;
         }
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, ch);
      } else if ( key:==DOWN ) {
         line=_expand_tabsc_raw();
         ch=utf8_char_at(line,p_col,utf8);
         if ( ch:==vside ) {
            rc=draw_down();
            if ( rc ) {  /* hit bottom of file? */
               orig_x := p_cursor_x;
               insert_line(substr('',1,p_col-1));
               p_cursor_x = orig_x;
               temp_line=_expand_tabsc_raw();
               replace_col_utf8(temp_line, p_col, vside);
               continue;
            } else {
               temp_line = _expand_tabsc_raw();
               overwrite_ch=utf8_char_at(temp_line,p_col,utf8);
               if ( utf8_asc(overwrite_ch,utf8)<=127 || overwrite_ch:==vside ) {
                  replace_col_utf8(temp_line, p_col, vside);
                  continue;
               }
               draw_up();
            }
         }
         rc=draw_down();
         if ( rc ) {
            overwrite_ch=' ';
         } else {
            temp_line = _expand_tabsc_raw();
            overwrite_ch=utf8_char_at(temp_line,p_col,utf8);
            draw_up();
         }
         if ( ch:==hside ) {
            /* Determine how to translate the character under the cursor by */
            /* checking characters left,right, and under the cursor. */
            if ( is_left() ) {
               if ( is_right() ) {
                  ch=tdown;
               } else {
                  ch=trc;
               }
            } else if ( is_right() ) {
               ch=tlc;
            }
            replace_col_utf8(line, p_col, ch);
         } else if ( ch:==tup ) {
            replace_col_utf8(line, p_col, intersect);
         } else if ( ch:==brc ) {
            replace_col_utf8(line, p_col, tleft);
         } else if ( ch:==blc ) {
            replace_col_utf8(line, p_col, tright);
         }
         rc=draw_down();
         if ( rc ) {
            orig_x := p_cursor_x;
            insert_line('');
            p_cursor_x = orig_x;
         }
         /* Determine what character to insert. */
         if ( overwrite_ch:==tdown ||
            overwrite_ch:==intersect ) {  /* use intersect character? */
            ch=intersect;
         } else if ( overwrite_ch==fillblock || overwrite_ch==filldot ) {
            ch= overwrite_ch;
         } else if ( overwrite_ch==trc ) {
            ch= tleft;
         } else if ( overwrite_ch==tlc ) {
            ch= tright;
         } else if ( overwrite_ch:==hside ) {
            if ( is_left() ) {
               if ( is_right() ) { ch=tup; } else { ch=brc; }
            } else if ( is_right() ) {
               ch=blc;
            } else {
               ch=vside;
            }
         } else if ( overwrite_ch:==tup || overwrite_ch:==blc ||
                overwrite_ch:==tleft || overwrite_ch:==tright ||
                overwrite_ch:==brc ) {  /* leave character the same ? */
            ch=overwrite_ch;
         } else {
            ch=vside;
         }
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, ch);
      } else if ( key:==LEFT ) {
         if ( p_col>1 ) {
            line=_expand_tabsc_raw();
            ch=utf8_char_at(line,p_col,utf8);
            overwrite_ch=utf8_char_before(line,p_col,utf8);
            if ( ch:==hside && (utf8_asc(overwrite_ch,utf8)<=127 || overwrite_ch:==hside) ) {
               left();
               replace_col_utf8(line, p_col, hside);
            } else {
               if ( ch:==vside ) {
                  /* Determine how to translate the character under the cursor by */
                  /* checking characters above ,below, and under the cursor. */
                  if ( is_above() ) {
                     if ( is_below() ) { 
                        ch=tleft; 
                     } else { 
                        ch=brc; 
                     }
                  } else if ( is_below() ) {
                     ch=trc;
                  }
                  replace_col_utf8(line, p_col, ch);
               } else if ( ch:==tright ) {
                  replace_col_utf8(line, p_col, intersect);
               } else if ( ch:==blc ) {
                  replace_col_utf8(line, p_col, tup);
               } else if ( ch:==tlc ) {
                  replace_col_utf8(line, p_col, tdown);
               }
               left();
               /* Determine what character to insert. */
               if ( overwrite_ch:==tleft || overwrite_ch:==intersect ) {  /* use intersect character? */
                  ch=intersect;
               } else if ( overwrite_ch==fillblock || overwrite_ch==filldot ) {
                  ch= overwrite_ch;
               } else if ( overwrite_ch==brc ) {
                  ch= tup;
               } else if ( overwrite_ch==trc ) {
                  ch= tdown;
               } else if ( overwrite_ch:==vside ) {
                  if ( is_above() ) {
                     if ( is_below() ) { 
                        ch=tright; 
                     } else { 
                        ch=blc; 
                     }
                  } else if ( is_below() ) {
                     ch=tlc;
                  } else {
                     ch=hside;
                  }
               } else if ( overwrite_ch:==tright || overwrite_ch:==blc ||
                      overwrite_ch:==tup || overwrite_ch:==tdown ||
                      overwrite_ch:==tlc ) {  /* leave character the same ? */
                  ch=overwrite_ch;
               } else {
                  ch=hside;
               }
               replace_col_utf8(line, p_col, ch);
            }
         }
      } else if ( key:==RIGHT ) {
         line=_expand_tabsc_raw();
         ch=utf8_char_at(line,p_col,utf8);
         overwrite_ch=utf8_char_after(line,p_col,utf8);
         if ( ch:==hside && (utf8_asc(overwrite_ch,utf8)<=127 || overwrite_ch:==hside) ) {
            right();
            replace_col_utf8(line, p_col, hside);
         } else {
               if ( ch:==vside ) {
                  /* Determine how to translate the character under the cursor by */
                  /* checking characters above ,below, and under the cursor. */
                  if ( is_above() ) {
                     if ( is_below() ) { 
                        ch=tright; 
                     } else { 
                        ch=blc; 
                     }
                  } else if ( is_below() ) {
                     ch=tlc;
                  }
                  replace_col_utf8(line, p_col, ch);
               } else if ( ch:==tleft ) {
                  replace_col_utf8(line, p_col, intersect);
               } else if ( ch:==brc ) {
                  replace_col_utf8(line, p_col, tup);
               } else if ( ch:==trc ) {
                  replace_col_utf8(line, p_col, tdown);
               }
               right();
               /* Determine what character to insert. */
               if ( overwrite_ch:==tright || overwrite_ch:==intersect ) {  /* use intersect character? */
                  ch=intersect;
               } else if ( overwrite_ch==fillblock || overwrite_ch==filldot ) {
                  ch= overwrite_ch;
               } else if ( overwrite_ch==blc ) {
                  ch= tup;
               } else if ( overwrite_ch==tlc ) {
                  ch= tdown;
               } else if ( overwrite_ch:==vside ) {
                  if ( is_above() ) {
                     if ( is_below() ) {
                         ch=tleft; 
                     } else { 
                        ch=brc; 
                     }
                  } else if ( is_below() ) {
                     ch=trc;
                  } else {
                     ch=hside;
                  }
               } else if ( overwrite_ch:==tleft || overwrite_ch:==brc ||
                      overwrite_ch:==tup || overwrite_ch:==tdown ||
                      overwrite_ch:==trc ) {  /* leave character the same ? */
                  ch=overwrite_ch;
               } else {
                  ch=hside;
               }
               replace_col_utf8(line, p_col, ch);
         }
      } else if ( key:==C_UP ) {
         draw_up();
      } else if ( key:==C_DOWN ) {
         draw_down();
      } else if ( key:==C_LEFT ) {
         left();
      } else if ( key:==C_RIGHT ) {
         right();
      } else if ( key:==S_UP ) {
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, fillblock);
         draw_up();
      } else if ( key:==S_DOWN ) {
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, fillblock);
         draw_down();
      } else if ( key:==S_LEFT ) {
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, fillblock);
         left();
      } else if ( key:==S_RIGHT ) {
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, fillblock);
         right();
      } else if ( key:==BACKSPACE ) {
         rubout();
      } else if ( key:==DEL ) {
         delete_char(1);
      } else if ( key=='.') {
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, filldot);
         right();
      } else if ( key=='<') {
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, arrowleft);
         right();
      } else if ( key=='>') {
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, arrowright);
         right();
      } else if ( key=='^') {
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, arrowup);
         right();
      } else if ( key==' ') {
         line=_expand_tabsc_raw();
         replace_col_utf8(line, p_col, ' ');
         right();
      } else if ( key:==C_Z ) {
         undo();
      } else if ( iscancel(key) ) {
         break;
      }
   }
   clear_message();
   def_updown_col = orig_def_updown_col;

}

static int utf8_asc(_str ch, bool utf8)
{
   if (utf8) {
      return _UTF8Asc(ch);
   } else {
      return _asc(ch);
   }
}

static int draw_up()
{
   orig_x := p_cursor_x;
   status := cursor_up();
   p_cursor_x = orig_x;
   return status;
}

static int draw_down()
{
   orig_x := p_cursor_x;
   status := cursor_down();
   p_cursor_x = orig_x;
   return status;
}

static _str utf8_char_at(_str line, int col, bool utf8)
{
   if (utf8) {
      start_col := _strBeginChar(line, col, auto substr_len);
      ch := substr(line, start_col, substr_len);
      return ch;
   } else {
      return substr(line, col, 1);
   }
}

static _str utf8_char_before(_str line, int col, bool utf8)
{
   if (utf8) {
      start_col := _strBeginChar(line, col-1, auto substr_len);
      ch := substr(line, start_col, substr_len);
      return ch;
   } else {
      return substr(line, col-1, 1);
   }
}

static _str utf8_char_after(_str line, int col, bool utf8)
{
   if (utf8) {
      start_col := _strBeginChar(line, col, auto substr_len);
      start_col = _strBeginChar(line, start_col+substr_len, substr_len);
      ch := substr(line, start_col, substr_len);
      return ch;
   } else {
      return substr(line, col+1, 1);
   }
}

static void replace_col_utf8(_str &line, int col, _str ch)
{
   if (p_UTF8) {
      start_col := _strBeginChar(line, col, auto char_len);
      line = substr(line,1,col-1):+ch:+substr(line,col+char_len,-1);
   } else {
      line = substr(line,1,col-1):+ch:+substr(line,col+1,-1);
   }
   replace_line_raw(line);
}

static bool is_above()
{
   save_pos(auto p);
   draw_up();
   if ( _on_line0() ) { 
      restore_pos(p);
      return(false); 
   }
   line := _expand_tabsc_raw();
   ch := utf8_char_at(line,p_col,p_UTF8);
   restore_pos(p);
   return(ch:==vside || ch:==tleft || ch:==tright || 
          ch:==intersect || ch :== fillblock || ch :== filldot ||
          ch:==tlc || ch:==trc || ch:==tdown);
}
static bool is_below()
{
   save_pos(auto p);
   rc=draw_down();
   if ( rc ) { 
      return(false); 
   }
   line := _expand_tabsc_raw();
   ch := utf8_char_at(line,p_col,p_UTF8);
   restore_pos(p);
   return(ch:==vside || ch:==tleft || ch:==tright ||
          ch:==intersect || ch :== fillblock || ch :== filldot ||
          ch:==blc || ch:==brc || ch:==tup);
}
static bool is_left()
{
   line := _expand_tabsc_raw();
   if ( p_col==1 ) { return(false); }
   ch := utf8_char_before(line,p_col,p_UTF8);
   return(ch:==hside || ch:==tup || ch:==tdown ||
          ch:==intersect || ch :== fillblock || ch :== filldot ||
          ch==tlc || ch==blc || ch:==tright);
}
static bool is_right()
{
   line := _expand_tabsc_raw();
   ch := utf8_char_after(line,p_col,p_UTF8);
   return(ch:==hside || ch:==tup || ch:==tdown ||
          ch:==intersect || ch :== fillblock || ch :== filldot ||
          ch==trc || ch==brc || ch:==tleft);
}
  
