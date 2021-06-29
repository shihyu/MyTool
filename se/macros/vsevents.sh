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
#pragma option(metadata,"event.e")


/*
    The file defines events for all keys, mouse events, and some
    other Slick-C  events (ON_??? events).

    To specify a key/mouse event and shift states, combine any of the
    VSEVFLAG_??? key shift flags with one of the VSEV_??? key/mouse constants.

    Ex.

       VSEVFLAG_CTRL|VSEV_ENTER                  -->  Ctrl+Enter
       VSEVFLAG_CTRL|VSEVFLAG_SHIFT|VSEV_ENTER   -->  Ctrl+Shift+Enter
       VSEVFLAG_CTRL|VSEVFLAG_SHIFT|VSEV_TAB     -->  Ctrl+Shift+Enter
       VSEVFLAG_CTRL|VSEVFLAG_SHIFT|VSEV_A       -->  Ctrl+Shift+A
       VSEVFLAG_CTRL|VSEVFLAG_SHIFT|VSEV_a       -->  Ctrl+Shift+a (not case sensitive)
       VSEVFLAG_CTRL|VSEV_A                      -->  Ctrl+A
       VSEVFLAG_CTRL|VSEV_a                      -->  Ctrl+a (not case sensitive)
       VSEVFLAG_CTRL|VSEV_LBUTTON_DOWN          -->  Ctrl+LButtonDown
       VSEVFLAG_CTRL|VSEV_LBUTTON_DOUBLE_CLICK  -->  Ctrl+LButtonDoubleClick
    
    The (ON_???) events, VSEV_?BUTTOM_UP, and VSEV_MOUSE_MOVE are not 
    combined (ORed) with key shift flags.

    There are some combinations of shift states and keys that are not supported.
    On Windows, Ctrl+Alt+Shift+<Key> does not work with some keyboard localizations.
*/



typedef int VSEVENT;

// This flag is used for storing the event table in the
// state file or pcode file in binary.
const VSEVFLAG_RANGE_CONTAINS_ONLY_ONE=  (1<<31);
// VSEVFLAG_ON is used for sorting purposes
const VSEVFLAG_ON=      (1<<30);

// VSEVFLAG_MOUSE is used for sorting purposes
const VSEVFLAG_MOUSE=   (1<<29);

const VSEVFLAG_ALT=     (1<<27);
const VSEVFLAG_CTRL=    (1<<26);
const VSEVFLAG_SHIFT=   (1<<25);
// The command shift flag is only useful for the MAC
const VSEVFLAG_COMMAND= (1<<24);
const VSEVFLAG_ALL_SHIFT_FLAGS=    (VSEVFLAG_ALT|VSEVFLAG_CTRL|VSEVFLAG_SHIFT|VSEVFLAG_COMMAND);


typedef int VSBINDING;

// Allow keyboard input to support 21-bit Unicode
const VSEV_RANGE_FIRST_CHAR_KEY=   0;
const VSEV_RANGE_LAST_CHAR_KEY=    0x1fffff;
const VSEV_LAST_CHAR_KEY=          (VSEV_RANGE_LAST_CHAR_KEY-1);


const VSEV_NULL=  0xffffffff;

const VSEV_RANGE_FIRST_MOUSE=     VSEVFLAG_MOUSE;
const VSEV_FIRST_MOUSE=                   (VSEV_RANGE_FIRST_MOUSE+1);
const VSEV_LBUTTON_DOWN=                  (VSEV_FIRST_MOUSE+0);
const VSEV_RBUTTON_DOWN=                  (VSEV_FIRST_MOUSE+1);
const VSEV_MBUTTON_DOWN=                  (VSEV_FIRST_MOUSE+2);
const VSEV_BACK_BUTTON_DOWN=              (VSEV_FIRST_MOUSE+3) ;
const VSEV_FORWARD_BUTTON_DOWN=           (VSEV_FIRST_MOUSE+4) ;
const VSEV_LBUTTON_DOUBLE_CLICK=          (VSEV_FIRST_MOUSE+5) ;
const VSEV_RBUTTON_DOUBLE_CLICK=          (VSEV_FIRST_MOUSE+6) ;
const VSEV_MBUTTON_DOUBLE_CLICK=          (VSEV_FIRST_MOUSE+7) ;
const VSEV_BACK_BUTTON_DOUBLE_CLICK=      (VSEV_FIRST_MOUSE+8) ;
const VSEV_FORWARD_BUTTON_DOUBLE_CLICK=   (VSEV_FIRST_MOUSE+9) ;
const VSEV_LBUTTON_TRIPLE_CLICK=          (VSEV_FIRST_MOUSE+10);
const VSEV_RBUTTON_TRIPLE_CLICK=          (VSEV_FIRST_MOUSE+11);
const VSEV_MBUTTON_TRIPLE_CLICK=          (VSEV_FIRST_MOUSE+12);
const VSEV_BACK_BUTTON_TRIPLE_CLICK=      (VSEV_FIRST_MOUSE+13);
const VSEV_FORWARD_BUTTON_TRIPLE_CLICK=   (VSEV_FIRST_MOUSE+14);
const VSEV_LBUTTON_UP=                    (VSEV_FIRST_MOUSE+15);
const VSEV_RBUTTON_UP=                    (VSEV_FIRST_MOUSE+16);
const VSEV_MBUTTON_UP=                    (VSEV_FIRST_MOUSE+17);
const VSEV_BACK_BUTTON_UP=                (VSEV_FIRST_MOUSE+18);
const VSEV_FORWARD_BUTTON_UP=             (VSEV_FIRST_MOUSE+19);
const VSEV_MOUSE_MOVE=                    (VSEV_FIRST_MOUSE+20);
const VSEV_WHEEL_UP=                      (VSEV_FIRST_MOUSE+21);
const VSEV_WHEEL_DOWN=                    (VSEV_FIRST_MOUSE+22)   ;
const VSEV_WHEEL_LEFT=                    (VSEV_FIRST_MOUSE+23);
const VSEV_WHEEL_RIGHT=                   (VSEV_FIRST_MOUSE+24);
const VSEV_LAST_MOUSE=             VSEV_WHEEL_RIGHT;
const VSEV_RANGE_LAST_MOUSE=     ((VSEV_LAST_MOUSE+1));
const VSEV_ALL_RANGE_LAST_MOUSE=   (VSEVFLAG_ALL_SHIFT_FLAGS|VSEV_RANGE_LAST_MOUSE);

// Start the non-character keys after the last key event or VS old keyboard events (same as ON_SELECT)
const VSEV_RANGE_FIRST_NONCHAR_KEY=     0x2001f6;   /* 20976554 */
const VSEV_FIRST_NONCHAR_KEY=     (VSEV_RANGE_FIRST_NONCHAR_KEY+1);
const VSEV_FIRST_FKEY=            VSEV_FIRST_NONCHAR_KEY;
const VSEV_F1=                    (VSEV_FIRST_FKEY+0);
const VSEV_F2=                    (VSEV_FIRST_FKEY+1);
const VSEV_F3=                    (VSEV_FIRST_FKEY+2);
const VSEV_F4=                    (VSEV_FIRST_FKEY+3);
const VSEV_F5=                    (VSEV_FIRST_FKEY+4);
const VSEV_F6=                    (VSEV_FIRST_FKEY+5);
const VSEV_F7=                    (VSEV_FIRST_FKEY+6);
const VSEV_F8=                    (VSEV_FIRST_FKEY+7);
const VSEV_F9=                    (VSEV_FIRST_FKEY+8);
const VSEV_F10=                   (VSEV_FIRST_FKEY+9);
const VSEV_F11=                   (VSEV_FIRST_FKEY+10);
const VSEV_F12=                   (VSEV_FIRST_FKEY+11);
const VSEV_F13=                   (VSEV_FIRST_FKEY+12);
const VSEV_F14=                   (VSEV_FIRST_FKEY+13);
const VSEV_F15=                   (VSEV_FIRST_FKEY+14);
const VSEV_F16=                   (VSEV_FIRST_FKEY+15);
const VSEV_F17=                   (VSEV_FIRST_FKEY+16);
const VSEV_F18=                   (VSEV_FIRST_FKEY+17);
const VSEV_F19=                   (VSEV_FIRST_FKEY+18);
const VSEV_F20=                   (VSEV_FIRST_FKEY+19);
const VSEV_F21=                   (VSEV_FIRST_FKEY+20);
const VSEV_F22=                   (VSEV_FIRST_FKEY+21);
const VSEV_F23=                   (VSEV_FIRST_FKEY+22);
const VSEV_F24=                   (VSEV_FIRST_FKEY+23);
const VSEV_LAST_FKEY=             VSEV_F24;

const VSEV_FIRST_KEY=             (VSEV_F24+20);
const VSEV_ENTER=                 VSEV_FIRST_KEY;
const VSEV_TAB=                   (VSEV_FIRST_KEY+1);
const VSEV_ESC=                   (VSEV_FIRST_KEY+2);
const VSEV_BACKSPACE=             (VSEV_FIRST_KEY+3);
const VSEV_PAD_STAR=              (VSEV_FIRST_KEY+4);
const VSEV_PAD_PLUS=              (VSEV_FIRST_KEY+5);
const VSEV_PAD_MINUS=             (VSEV_FIRST_KEY+6);
const VSEV_HOME=                  (VSEV_FIRST_KEY+7);
const VSEV_END=                   (VSEV_FIRST_KEY+8);
const VSEV_LEFT=                  (VSEV_FIRST_KEY+9);
const VSEV_RIGHT=                 (VSEV_FIRST_KEY+10);
const VSEV_UP=                    (VSEV_FIRST_KEY+11);
const VSEV_DOWN=                  (VSEV_FIRST_KEY+12);
const VSEV_CLEAR=                 (VSEV_FIRST_KEY+13);
const VSEV_PAD_0=                 (VSEV_FIRST_KEY+14);
const VSEV_PAD_1=                 (VSEV_FIRST_KEY+15);
const VSEV_PAD_2=                 (VSEV_FIRST_KEY+16);
const VSEV_PAD_3=                 (VSEV_FIRST_KEY+17);
const VSEV_PAD_4=                 (VSEV_FIRST_KEY+18);
const VSEV_PAD_5=                 (VSEV_FIRST_KEY+19);
const VSEV_PAD_6=                 (VSEV_FIRST_KEY+20);
const VSEV_PAD_7=                 (VSEV_FIRST_KEY+21);
const VSEV_PAD_8=                 (VSEV_FIRST_KEY+22);
const VSEV_PAD_9=                 (VSEV_FIRST_KEY+23);
const VSEV_PAD_DOT=               (VSEV_FIRST_KEY+24);
const VSEV_PAD_EQUAL=             (VSEV_FIRST_KEY+25);
const VSEV_PAD_ENTER=             (VSEV_FIRST_KEY+26);  /* not implemented */
const VSEV_PGUP=                  (VSEV_FIRST_KEY+27);
const VSEV_PGDN=                  (VSEV_FIRST_KEY+28);
const VSEV_DEL=                   (VSEV_FIRST_KEY+29);
const VSEV_INS=                   (VSEV_FIRST_KEY+30);
const VSEV_PAD_SLASH=             (VSEV_FIRST_KEY+31);
const VSEV_CTRL=                  (VSEV_FIRST_KEY+32);
const VSEV_SHIFT=                 (VSEV_FIRST_KEY+33);
const VSEV_ALT=                   (VSEV_FIRST_KEY+34);  /* not implemented */
const VSEV_COMMAND=               (VSEV_FIRST_KEY+35);  /* not implemented */
const VSEV_BREAK=                 (VSEV_FIRST_KEY+36);
const VSEV_CONTEXT=               (VSEV_FIRST_KEY+37);
const VSEV_LAST_KEY=              VSEV_CONTEXT;

const VSEV_ALL_RANGE_LAST_NONCHAR_KEY=  (VSEVFLAG_ALL_SHIFT_FLAGS|(VSEV_LAST_KEY+1));


#define vsIsMouseEvent(event) ((event&VSEVFLAG_MOUSE) && event!=VSEV_NULL)
#define vsIsKeyEvent(event)   (vsIsKeyEvent2(event) || event==VSEV_ON_NUM_LOCK || event==VSEV_ON_KEYSTATECHANGE)
#define vsIsKeyEvent2(event)  (event>=0 && event<VSEVFLAG_MOUSE)
#define vsIsOnEvent(event)    ((event&VSEVFLAG_ON) && event!=VSEV_NULL)

// Slick-C VSEV_ON_??? events
const VSEV_RANGE_FIRST_ON=      VSEVFLAG_ON;
const VSEV_FIRST_ON=          (VSEV_RANGE_FIRST_ON+1);
const VSEV_ON_SELECT=         (VSEV_FIRST_ON+0);
const VSEV_ON_NUM_LOCK=       (VSEV_FIRST_ON+1);
const VSEV_ON_CLOSE=          (VSEV_FIRST_ON+2);
const VSEV_ON_GOT_FOCUS=      (VSEV_FIRST_ON+3);
const VSEV_ON_LOST_FOCUS=     (VSEV_FIRST_ON+4);
const VSEV_ON_CHANGE=         (VSEV_FIRST_ON+5);
const VSEV_ON_RESIZE=         (VSEV_FIRST_ON+6);
const VSEV_ON_TIMER=          (VSEV_FIRST_ON+7);
const VSEV_ON_PAINT=          (VSEV_FIRST_ON+8);
const VSEV_ON_VSB_LINE_UP=     (VSEV_FIRST_ON+9);
const VSEV_ON_VSB_LINE_DOWN=   (VSEV_FIRST_ON+10);
const VSEV_ON_VSB_PAGE_UP=     (VSEV_FIRST_ON+11);
const VSEV_ON_VSB_PAGE_DOWN=   (VSEV_FIRST_ON+12);
const VSEV_ON_VSB_THUMB_TRACK= (VSEV_FIRST_ON+13);
const VSEV_ON_VSB_THUMB_POS=   (VSEV_FIRST_ON+14);
const VSEV_ON_VSB_TOP=         (VSEV_FIRST_ON+15);
const VSEV_ON_VSB_BOTTOM=      (VSEV_FIRST_ON+16);

const VSEV_ON_HSB_LINE_UP=     (VSEV_FIRST_ON+17);
const VSEV_ON_HSB_LINE_DOWN=   (VSEV_FIRST_ON+18);
const VSEV_ON_HSB_PAGE_UP=     (VSEV_FIRST_ON+19);
const VSEV_ON_HSB_PAGE_DOWN=   (VSEV_FIRST_ON+20);
const VSEV_ON_HSB_THUMB_TRACK= (VSEV_FIRST_ON+21);
const VSEV_ON_HSB_THUMB_POS=   (VSEV_FIRST_ON+22);
const VSEV_ON_HSB_TOP=         (VSEV_FIRST_ON+23);
const VSEV_ON_HSB_BOTTOM=      (VSEV_FIRST_ON+24);

const VSEV_ON_SB_END_SCROLL=  (VSEV_FIRST_ON+25);

const VSEV_ON_DROP_DOWN=      (VSEV_FIRST_ON+26);
const VSEV_ON_DRAG_DROP=      (VSEV_FIRST_ON+27);
const VSEV_ON_DRAG_OVER=      (VSEV_FIRST_ON+28);
const VSEV_ON_SCROLL_LOCK=    (VSEV_FIRST_ON+29);
const VSEV_ON_DROP_FILES=     (VSEV_FIRST_ON+30);
const VSEV_ON_CREATE=         (VSEV_FIRST_ON+31);
const VSEV_ON_DESTROY=        (VSEV_FIRST_ON+32);
const VSEV_ON_CREATE2=        (VSEV_FIRST_ON+33);
const VSEV_ON_DESTROY2=       (VSEV_FIRST_ON+34);
const VSEV_ON_SPIN_UP=        (VSEV_FIRST_ON+35);
const VSEV_ON_SPIN_DOWN=      (VSEV_FIRST_ON+36);
const VSEV_ON_SCROLL=         (VSEV_FIRST_ON+37);
const VSEV_ON_CHANGE2=        (VSEV_FIRST_ON+38);
const VSEV_ON_LOAD=           (VSEV_FIRST_ON+39);
const VSEV_ON_INIT_MENU=      (VSEV_FIRST_ON+40);
const VSEV_ON_KEYSTATECHANGE= (VSEV_FIRST_ON+41);
const VSEV_ON_GOT_FOCUS2=     (VSEV_FIRST_ON+42);
const VSEV_ON_LOST_FOCUS2=    (VSEV_FIRST_ON+43);
const VSEV_ON_HIGHLIGHT=      (VSEV_FIRST_ON+44);
const VSEV_LAST_ON=           VSEV_ON_HIGHLIGHT;
const VSEV_RANGE_LAST_ON=     (VSEV_LAST_ON+1);

