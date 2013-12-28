////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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

static _str
      hside,vside,tleft,tright,intersect,tup,tdown
      ,tlc,trc,blc,brc;


defmain()
{
   if ( arg(1)=='' ) {
      // Can't display help because the font is wrong.
      //_macro_delete_line()
      //command_put('draw ')
      //message(nls('Arguments: 1='\197'  2='\206'  3='\216'  4='\215'  B=Blank  or Any character'));
      return(1);
   }
   _str overwrite_ch='';
   _str ch='';
   if ( arg(1)=='1' ) {
      tlc=\218;tdown=\194;tright=\195;intersect=\197;hside=\196;
      trc=\191;tleft=\180;vside=\179;brc=\217;tup=\193;blc=\192;
   } else if ( arg(1)=='2' ) {
      tlc=\201;tdown=\203;tright=\204;intersect=\206;hside=\205;
      trc=\187;tleft=\185;vside=\186;brc=\188;tup=\202;blc=\200;
   } else if ( arg(1)=='3' ) {
      tlc=\213;tdown=\209;tright=\198;intersect=\216;hside=\205;
      trc=\184;tleft=\181;vside=\179;brc=\190;tup=\207;blc=\212;
   } else if ( arg(1)=='4' ) {
      tlc=\214;tdown=\210;tright=\199;intersect=\215;hside=\196;
      trc=\183;tleft=\182;vside=\186;brc=\189;tup=\208;blc=\211;
   } else if ( upcase(arg(1))=='A' ) {
      tlc='*';tdown="|";tright='|';intersect='+';hside='-';
      trc='*';tleft='|';vside='|';brc='*';tup='-';blc='*';
   } else if ( upcase(arg(1))=='B' ) {
      tlc=' ';tdown=' ';tright=' ';intersect=' ';hside=' ';
      trc=' ';tleft=' ';vside=' ';brc=' ';tup=' ';blc=' ';
   } else {
      ch=substr(arg(1),1,1);
      tlc=ch;tdown=ch;tright=ch;intersect=ch;hside=ch;
      trc=ch;tleft=ch;vside=ch;brc=ch;tup=ch;blc=ch;
   }
   if ( command_state() ) {
      command_toggle();
   }
   typeless temp=0;
   int old_col=0;
   _str line='';
   message(nls('Draw running.  Press arrow keys to draw.'));
   for (;;) {
      _undo('S');
      typeless key=get_event();
      if ( key:==UP ) {
         line=_expand_tabsc_raw();ch=substr(line,p_col,1);
         if ( ch:==vside ) {
            up();
            if ( _on_line0() ) {  /* hit top of file? */
               old_col=p_col;
               insert_line( substr('',1,p_col-1):+vside);
               p_col=old_col;
               continue;
            } else {
               temp=_expand_tabsc_raw();
               overwrite_ch=substr(temp,p_col,1);
               if ( (_asc(overwrite_ch)<=127 || overwrite_ch:==vside) ) {
                  replace_line_raw(substr(temp,1,p_col-1):+vside:+substr(temp,p_col+1));
                  continue;
               }
               down();
            }
         }
         up();
         temp=_expand_tabsc_raw();
         overwrite_ch=substr(temp,p_col,1);
         down();
         if ( ch:==hside ) {
            /* Determine how to translate the character under the cursor by */
            /* checking characters left,right, and under the cursor. */
            if ( is_left() ) {
               if ( is_right() ) { ch=tup; } else { ch=brc; }
            } else if ( is_right() ) {
               ch=blc;
            }
            line=substr(line,1,p_col-1):+ch:+substr(line,p_col+1);
            replace_line_raw(line);
         } else if ( ch:==tdown ) {
            line=substr(line,1,p_col-1):+intersect:+substr(line,p_col+1);
            replace_line_raw(line);
         } else if ( ch:==trc ) {
            line=substr(line,1,p_col-1):+tleft:+substr(line,p_col+1);
            replace_line_raw(line);
         } else if ( ch:==tlc ) {
            line=substr(line,1,p_col-1):+tright:+substr(line,p_col+1);
            replace_line_raw(line);
         }
         up();
         if ( _on_line0() ) {
            old_col=p_col;
            insert_line('');
            p_col=old_col;
         }
         /* Determine what character to insert. */
         if ( overwrite_ch:==tup ||
            overwrite_ch:==intersect ) {  /* use intersect character? */
            ch=intersect;
         } else if ( overwrite_ch==brc ) {
            ch= tleft;
         } else if ( overwrite_ch==blc ) {
            ch= tright;
         } else if ( overwrite_ch:==hside ) {
            if ( is_left() ) {
               if ( is_right() ) { ch=tdown; } else { ch=trc; }
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
         replace_line_raw(substr(line,1,p_col-1):+ch:+substr(line,p_col+1));
      } else if ( key:==DOWN ) {
         line=_expand_tabsc_raw();ch=substr(line,p_col,1);
         if ( ch:==vside ) {
            rc=down();
            if ( rc ) {  /* hit bottom of file? */
               old_col=p_col;
               insert_line(substr('',1,p_col-1):+vside);
               p_col=old_col;
               continue;
            } else {
               temp=_expand_tabsc_raw();
               overwrite_ch=substr(temp,p_col,1);
               if ( _asc(overwrite_ch)<=127 || overwrite_ch:==vside ) {
                  replace_line_raw(substr(temp,1,p_col-1):+vside:+substr(temp,p_col+1));
                  continue;
               }
               up();
            }
         }
         rc=down();
         if ( rc ) {
            overwrite_ch=' ';
         } else {
            temp=_expand_tabsc_raw();
            overwrite_ch=substr(temp,p_col,1);
            up();
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
            line=substr(line,1,p_col-1):+ch:+substr(line,p_col+1);
            replace_line_raw(line);
         } else if ( ch:==tup ) {
            line=substr(line,1,p_col-1):+intersect:+substr(line,p_col+1);
            replace_line_raw(line);
         } else if ( ch:==brc ) {
            line=substr(line,1,p_col-1):+tleft:+substr(line,p_col+1);
            replace_line_raw(line);
         } else if ( ch:==blc ) {
            line=substr(line,1,p_col-1):+tright:+substr(line,p_col+1);
            replace_line_raw(line);
         }
         down();
         if ( rc ) {
            old_col=p_col;
            insert_line('');
            p_col=old_col;
         }
         /* Determine what character to insert. */
         if ( overwrite_ch:==tdown ||
            overwrite_ch:==intersect ) {  /* use intersect character? */
            ch=intersect;
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
         replace_line_raw(substr(line,1,p_col-1):+ch:+substr(line,p_col+1));
      } else if ( key:==LEFT ) {
         if ( p_col>1 ) {
            line=_expand_tabsc_raw();ch=substr(line,p_col,1);
            overwrite_ch=substr(line,p_col-1,1);
            if ( ch:==hside && (_asc(overwrite_ch)<=127 || overwrite_ch:==hside) ) {
               left();
               replace_line_raw(substr(line,1,p_col-1):+hside:+substr(line,p_col+1));
            } else {
               if ( ch:==vside ) {
                  /* Determine how to translate the character under the cursor by */
                  /* checking characters above ,below, and under the cursor. */
                  if ( is_above() ) {
                     if ( is_below() ) { ch=tleft; } else { ch=brc; }
                  } else if ( is_below() ) {
                     ch=trc;
                  }
                  line=substr(line,1,p_col-1):+ch:+substr(line,p_col+1);
                  replace_line_raw(line);
               } else if ( ch:==tright ) {
                  line=substr(line,1,p_col-1):+intersect:+substr(line,p_col+1);
                  replace_line_raw(line);
               } else if ( ch:==blc ) {
                  line=substr(line,1,p_col-1):+tup:+substr(line,p_col+1);
                  replace_line_raw(line);
               } else if ( ch:==tlc ) {
                  line=substr(line,1,p_col-1):+tdown:+substr(line,p_col+1);
                  replace_line_raw(line);
               }
               left();
               /* Determine what character to insert. */
               if (  overwrite_ch:==tleft ||
                   overwrite_ch:==intersect ) {  /* use intersect character? */
                  ch=intersect;
               } else if ( overwrite_ch==brc ) {
                  ch= tup;
               } else if ( overwrite_ch==trc ) {
                  ch= tdown;
               } else if ( overwrite_ch:==vside ) {
                  if ( is_above() ) {
                     if ( is_below() ) { ch=tright; } else { ch=blc; }
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
               replace_line_raw(substr(line,1,p_col-1):+ch:+substr(line,p_col+1));
            }
         }
      } else if ( key:==RIGHT ) {
         line=_expand_tabsc_raw();ch=substr(line,p_col,1);
         overwrite_ch=substr(line,p_col+1,1);
         if ( ch:==hside && (_asc(overwrite_ch)<=127 || overwrite_ch:==hside) ) {
            right();
            replace_line_raw(substr(line,1,p_col-1):+hside:+substr(line,p_col+1));
         } else {
               if ( ch:==vside ) {
                  /* Determine how to translate the character under the cursor by */
                  /* checking characters above ,below, and under the cursor. */
                  if ( is_above() ) {
                     if ( is_below() ) { ch=tright; } else { ch=blc; }
                  } else if ( is_below() ) {
                     ch=tlc;
                  }
                  line=substr(line,1,p_col-1):+ch:+substr(line,p_col+1);
                  replace_line_raw(line);
               } else if ( ch:==tleft ) {
                  line=substr(line,1,p_col-1):+intersect:+substr(line,p_col+1);
                  replace_line_raw(line);
               } else if ( ch:==brc ) {
                  line=substr(line,1,p_col-1):+tup:+substr(line,p_col+1);
                  replace_line_raw(line);
               } else if ( ch:==trc ) {
                  line=substr(line,1,p_col-1):+tdown:+substr(line,p_col+1);
                  replace_line_raw(line);
               }
               right();
               /* Determine what character to insert. */
               if ( overwrite_ch:==tright ||
                  overwrite_ch:==intersect ) {  /* use intersect character? */
                  ch=intersect;
               } else if ( overwrite_ch==blc ) {
                  ch= tup;
               } else if ( overwrite_ch==tlc ) {
                  ch= tdown;
               } else if ( overwrite_ch:==vside ) {
                  if ( is_above() ) {
                     if ( is_below() ) { ch=tleft; } else { ch=brc; }
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
               replace_line_raw(substr(line,1,p_col-1):+ch:+substr(line,p_col+1));
         }
      } else if ( iscancel(key) ) {
         break;
      }
   }
   clear_message();

}
static boolean is_above()
{
   up();
   if ( _on_line0() ) { down();return(0); }
   _str line=_expand_tabsc_raw();
   down();
   _str ch=substr(line,p_col,1);
   return(ch:==vside || ch:==tleft || ch:==tright || ch:==intersect ||
          ch:==tlc || ch:==trc || ch:==tdown);

}
static boolean is_below()
{
   down();
   if ( rc ) { return(0); }
   _str line=_expand_tabsc_raw();
   up();
   _str ch=substr(line,p_col,1);
   return(ch:==vside || ch:==tleft || ch:==tright || ch:==intersect ||
          ch:==blc || ch:==brc || ch:==tup);

}
static boolean is_left()
{
   _str line=_expand_tabsc_raw();
   if ( p_col==1 ) { return(0); }
   _str ch=substr(line,p_col-1,1);
   return(ch:==hside || ch:==tup || ch:==tdown || ch:==intersect ||
          ch==tlc || ch==blc || ch:==tright);

}
static boolean is_right()
{
   _str line=_expand_tabsc_raw();
   _str ch=substr(line,p_col+1,1);
   return(ch:==hside || ch:==tup || ch:==tdown || ch:==intersect ||
          ch==trc || ch==brc || ch:==tleft);

}
