////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
/*
    The file defines events for all keys, mouse events, and some
    other Slick-C&reg;  events (ON_??? events).

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
       VSEVFLAG_CTRL|VS_MK_LBUTTON_DOWN          -->  Ctrl+LButtonDown
       VSEVFLAG_CTRL|VS_MK_LBUTTON_DOUBLE_CLICK  -->  Ctrl+LButtonDoubleClick
    
    The (ON_???) events, VSEV_?BUTTOM_UP, and VSEV_MOUSE_MOVE are not 
    combined (ORed) with key shift flags.

    There are some combinations of shift states and keys that are not supported.
    On Windows, Ctrl+Alt+Shift+<Key> does not work with some keyboard localizations.
*/
#pragma once


#define VSEVENT int

// This flag is used for storing the event table in the
// state file or pcode file in binary.
#define VSEVFLAG_RANGE_CONTAINS_ONLY_ONE  (1<<31)
// VSEVFLAG_ON is used for sorting purposes
#define VSEVFLAG_ON      (1<<30)

// VSEVFLAG_MOUSE is used for sorting purposes
#define VSEVFLAG_MOUSE   (1<<29)

#define VSEVFLAG_ALT     (1<<27)
#define VSEVFLAG_CTRL    (1<<26)
#define VSEVFLAG_SHIFT   (1<<25)
// The command shift flag is only useful for the MAC
#define VSEVFLAG_COMMAND (1<<24)
#define VSEVFLAG_ALL_SHIFT_FLAGS    (VSEVFLAG_ALT|VSEVFLAG_CTRL|VSEVFLAG_SHIFT|VSEVFLAG_COMMAND)


#define VSBINDING int

struct VSEVENT_BINDING {
   VSEVENT event;
   VSEVENT endEvent;
   VSBINDING binding; 
   bool operator <(const VSEVENT_BINDING &item2) const {
      return(event<item2.event);
   }
   bool operator ==(const VSEVENT_BINDING &item2) const {
      return(event>=item2.event && event<=item2.endEvent);
   }
};

// Allow keyboard input to support 21-bit Unicode
#define VSEV_LAST_CHAR_KEY          (VSEV_RANGE_LAST_CHAR_KEY-1)
#define VSEV_RANGE_FIRST_CHAR_KEY   0
#define VSEV_RANGE_LAST_CHAR_KEY    0x1fffff


#define VSEV_NULL  ((VSEVENT)0xffffffff)

#define VSEV_RANGE_FIRST_MOUSE     VSEVFLAG_MOUSE
#define VSEV_FIRST_MOUSE                   (VSEV_RANGE_FIRST_MOUSE+1)
#define VSEV_LBUTTON_DOWN                  (VSEV_FIRST_MOUSE+0)
#define VSEV_RBUTTON_DOWN                  (VSEV_FIRST_MOUSE+1)
#define VSEV_MBUTTON_DOWN                  (VSEV_FIRST_MOUSE+2)
#define VSEV_BACK_BUTTON_DOWN              (VSEV_FIRST_MOUSE+3) 
#define VSEV_FORWARD_BUTTON_DOWN           (VSEV_FIRST_MOUSE+4) 
#define VSEV_LBUTTON_DOUBLE_CLICK          (VSEV_FIRST_MOUSE+5) 
#define VSEV_RBUTTON_DOUBLE_CLICK          (VSEV_FIRST_MOUSE+6) 
#define VSEV_MBUTTON_DOUBLE_CLICK          (VSEV_FIRST_MOUSE+7) 
#define VSEV_BACK_BUTTON_DOUBLE_CLICK      (VSEV_FIRST_MOUSE+8) 
#define VSEV_FORWARD_BUTTON_DOUBLE_CLICK   (VSEV_FIRST_MOUSE+9) 
#define VSEV_LBUTTON_TRIPLE_CLICK          (VSEV_FIRST_MOUSE+10)
#define VSEV_RBUTTON_TRIPLE_CLICK          (VSEV_FIRST_MOUSE+11)
#define VSEV_MBUTTON_TRIPLE_CLICK          (VSEV_FIRST_MOUSE+12)
#define VSEV_BACK_BUTTON_TRIPLE_CLICK      (VSEV_FIRST_MOUSE+13)
#define VSEV_FORWARD_BUTTON_TRIPLE_CLICK   (VSEV_FIRST_MOUSE+14)
#define VSEV_LBUTTON_UP                    (VSEV_FIRST_MOUSE+15)
#define VSEV_RBUTTON_UP                    (VSEV_FIRST_MOUSE+16)
#define VSEV_MBUTTON_UP                    (VSEV_FIRST_MOUSE+17)
#define VSEV_BACK_BUTTON_UP                (VSEV_FIRST_MOUSE+18)
#define VSEV_FORWARD_BUTTON_UP             (VSEV_FIRST_MOUSE+19)
#define VSEV_MOUSE_MOVE                    (VSEV_FIRST_MOUSE+20)
#define VSEV_WHEEL_UP                      (VSEV_FIRST_MOUSE+21)
#define VSEV_WHEEL_DOWN                    (VSEV_FIRST_MOUSE+22)
#define VSEV_WHEEL_LEFT                    (VSEV_FIRST_MOUSE+23)
#define VSEV_WHEEL_RIGHT                   (VSEV_FIRST_MOUSE+24)
#define VSEV_LAST_MOUSE             VSEV_WHEEL_RIGHT
#define VSEV_RANGE_LAST_MOUSE     ((VSEV_LAST_MOUSE+1))
#define VSEV_ALL_RANGE_LAST_MOUSE   (VSEVFLAG_ALL_SHIFT_FLAGS|VSEV_RANGE_LAST_MOUSE)

// Start the non-character keys after the last key event or VS old keyboard events (same as ON_SELECT)
#define VSEV_RANGE_FIRST_NONCHAR_KEY     0x2001f6   /* 20976554 */
#define VSEV_FIRST_NONCHAR_KEY     (VSEV_RANGE_FIRST_NONCHAR_KEY+1)
#define VSEV_FIRST_FKEY            VSEV_FIRST_NONCHAR_KEY
#define VSEV_F1                    (VSEV_FIRST_FKEY+0)
#define VSEV_F2                    (VSEV_FIRST_FKEY+1)
#define VSEV_F3                    (VSEV_FIRST_FKEY+2)
#define VSEV_F4                    (VSEV_FIRST_FKEY+3)
#define VSEV_F5                    (VSEV_FIRST_FKEY+4)
#define VSEV_F6                    (VSEV_FIRST_FKEY+5)
#define VSEV_F7                    (VSEV_FIRST_FKEY+6)
#define VSEV_F8                    (VSEV_FIRST_FKEY+7)
#define VSEV_F9                    (VSEV_FIRST_FKEY+8)
#define VSEV_F10                   (VSEV_FIRST_FKEY+9)
#define VSEV_F11                   (VSEV_FIRST_FKEY+10)
#define VSEV_F12                   (VSEV_FIRST_FKEY+11)
#define VSEV_F13                   (VSEV_FIRST_FKEY+12)
#define VSEV_F14                   (VSEV_FIRST_FKEY+13)
#define VSEV_F15                   (VSEV_FIRST_FKEY+14)
#define VSEV_F16                   (VSEV_FIRST_FKEY+15)
#define VSEV_F17                   (VSEV_FIRST_FKEY+16)
#define VSEV_F18                   (VSEV_FIRST_FKEY+17)
#define VSEV_F19                   (VSEV_FIRST_FKEY+18)
#define VSEV_F20                   (VSEV_FIRST_FKEY+19)
#define VSEV_F21                   (VSEV_FIRST_FKEY+20)
#define VSEV_F22                   (VSEV_FIRST_FKEY+21)
#define VSEV_F23                   (VSEV_FIRST_FKEY+22)
#define VSEV_F24                   (VSEV_FIRST_FKEY+23)
#define VSEV_LAST_FKEY             VSEV_F24

#define VSEV_FIRST_KEY             (VSEV_F24+20)
#define VSEV_ENTER                 VSEV_FIRST_KEY
#define VSEV_TAB                   (VSEV_FIRST_KEY+1)
#define VSEV_ESC                   (VSEV_FIRST_KEY+2)
#define VSEV_BACKSPACE             (VSEV_FIRST_KEY+3)
#define VSEV_PAD_STAR              (VSEV_FIRST_KEY+4)
#define VSEV_PAD_PLUS              (VSEV_FIRST_KEY+5)
#define VSEV_PAD_MINUS             (VSEV_FIRST_KEY+6)
#define VSEV_HOME                  (VSEV_FIRST_KEY+7)
#define VSEV_END                   (VSEV_FIRST_KEY+8)
#define VSEV_LEFT                  (VSEV_FIRST_KEY+9)
#define VSEV_RIGHT                 (VSEV_FIRST_KEY+10)
#define VSEV_UP                    (VSEV_FIRST_KEY+11)
#define VSEV_DOWN                  (VSEV_FIRST_KEY+12)
#define VSEV_CLEAR                 (VSEV_FIRST_KEY+13)
#define VSEV_PAD_0                 (VSEV_FIRST_KEY+14)
#define VSEV_PAD_1                 (VSEV_FIRST_KEY+15)
#define VSEV_PAD_2                 (VSEV_FIRST_KEY+16)
#define VSEV_PAD_3                 (VSEV_FIRST_KEY+17)
#define VSEV_PAD_4                 (VSEV_FIRST_KEY+18)
#define VSEV_PAD_5                 (VSEV_FIRST_KEY+19)
#define VSEV_PAD_6                 (VSEV_FIRST_KEY+20)
#define VSEV_PAD_7                 (VSEV_FIRST_KEY+21)
#define VSEV_PAD_8                 (VSEV_FIRST_KEY+22)
#define VSEV_PAD_9                 (VSEV_FIRST_KEY+23)
#define VSEV_PAD_DOT               (VSEV_FIRST_KEY+24)
#define VSEV_PAD_EQUAL             (VSEV_FIRST_KEY+25)
#define VSEV_PAD_ENTER             (VSEV_FIRST_KEY+26)  /* not implemented*/
#define VSEV_PGUP                  (VSEV_FIRST_KEY+27)
#define VSEV_PGDN                  (VSEV_FIRST_KEY+28)
#define VSEV_DEL                   (VSEV_FIRST_KEY+29)
#define VSEV_INS                   (VSEV_FIRST_KEY+30)
#define VSEV_PAD_SLASH             (VSEV_FIRST_KEY+31)
#define VSEV_CTRL                  (VSEV_FIRST_KEY+32)
#define VSEV_SHIFT                 (VSEV_FIRST_KEY+33)
#define VSEV_ALT                   (VSEV_FIRST_KEY+34)  /* not implemented */
#define VSEV_COMMAND               (VSEV_FIRST_KEY+35)  /* not implemented */
#define VSEV_BREAK                 (VSEV_FIRST_KEY+36)
#define VSEV_CONTEXT               (VSEV_FIRST_KEY+37)
#define VSEV_LAST_KEY              VSEV_CONTEXT

#define VSEV_ALL_RANGE_LAST_NONCHAR_KEY  (VSEVFLAG_ALL_SHIFT_FLAGS|(VSEV_LAST_KEY+1))


#define vsIsMouseEvent(event) (((event)&VSEVFLAG_MOUSE) && (VSEVENT)(event)!=VSEV_NULL)
#define vsIsKeyEvent(event)   (vsIsKeyEvent2(event) || (VSEVENT)(event)==VSEV_ON_NUM_LOCK || (VSEVENT)(event)==VSEV_ON_KEYSTATECHANGE)
#define vsIsKeyEvent2(event)  ((event)>=0 && (VSEVENT)(event)<VSEVFLAG_MOUSE)
#define vsIsOnEvent(event)    (((event)&VSEVFLAG_ON) && (VSEVENT)(event)!=VSEV_NULL)

// Slick-C&reg; VSEV_ON_??? events
#define VSEV_RANGE_FIRST_ON      VSEVFLAG_ON
#define VSEV_FIRST_ON          (VSEV_RANGE_FIRST_ON+1)
#define VSEV_ON_SELECT         (VSEV_FIRST_ON+0)
#define VSEV_ON_NUM_LOCK       (VSEV_FIRST_ON+1)
#define VSEV_ON_CLOSE          (VSEV_FIRST_ON+2)
#define VSEV_ON_GOT_FOCUS      (VSEV_FIRST_ON+3)
#define VSEV_ON_LOST_FOCUS     (VSEV_FIRST_ON+4)
#define VSEV_ON_CHANGE         (VSEV_FIRST_ON+5)
#define VSEV_ON_RESIZE         (VSEV_FIRST_ON+6)
#define VSEV_ON_TIMER          (VSEV_FIRST_ON+7)
#define VSEV_ON_PAINT          (VSEV_FIRST_ON+8)
#define VSEV_ON_VSB_LINE_UP     (VSEV_FIRST_ON+9)
#define VSEV_ON_VSB_LINE_DOWN   (VSEV_FIRST_ON+10)
#define VSEV_ON_VSB_PAGE_UP     (VSEV_FIRST_ON+11)
#define VSEV_ON_VSB_PAGE_DOWN   (VSEV_FIRST_ON+12)
#define VSEV_ON_VSB_THUMB_TRACK (VSEV_FIRST_ON+13)
#define VSEV_ON_VSB_THUMB_POS   (VSEV_FIRST_ON+14)
#define VSEV_ON_VSB_TOP         (VSEV_FIRST_ON+15)
#define VSEV_ON_VSB_BOTTOM      (VSEV_FIRST_ON+16)

#define VSEV_ON_HSB_LINE_UP     (VSEV_FIRST_ON+17)
#define VSEV_ON_HSB_LINE_DOWN   (VSEV_FIRST_ON+18)
#define VSEV_ON_HSB_PAGE_UP     (VSEV_FIRST_ON+19)
#define VSEV_ON_HSB_PAGE_DOWN   (VSEV_FIRST_ON+20)
#define VSEV_ON_HSB_THUMB_TRACK (VSEV_FIRST_ON+21)
#define VSEV_ON_HSB_THUMB_POS   (VSEV_FIRST_ON+22)
#define VSEV_ON_HSB_TOP         (VSEV_FIRST_ON+23)
#define VSEV_ON_HSB_BOTTOM      (VSEV_FIRST_ON+24)

#define VSEV_ON_SB_END_SCROLL  (VSEV_FIRST_ON+25)

#define VSEV_ON_DROP_DOWN      (VSEV_FIRST_ON+26)
#define VSEV_ON_DRAG_DROP      (VSEV_FIRST_ON+27)
#define VSEV_ON_DRAG_OVER      (VSEV_FIRST_ON+28)
#define VSEV_ON_SCROLL_LOCK    (VSEV_FIRST_ON+29)
#define VSEV_ON_DROP_FILES     (VSEV_FIRST_ON+30)
#define VSEV_ON_CREATE         (VSEV_FIRST_ON+31)
#define VSEV_ON_DESTROY        (VSEV_FIRST_ON+32)
#define VSEV_ON_CREATE2        (VSEV_FIRST_ON+33)
#define VSEV_ON_DESTROY2       (VSEV_FIRST_ON+34)
#define VSEV_ON_SPIN_UP        (VSEV_FIRST_ON+35)
#define VSEV_ON_SPIN_DOWN      (VSEV_FIRST_ON+36)
#define VSEV_ON_SCROLL         (VSEV_FIRST_ON+37)
#define VSEV_ON_CHANGE2        (VSEV_FIRST_ON+38)
#define VSEV_ON_LOAD           (VSEV_FIRST_ON+39)
#define VSEV_ON_INIT_MENU      (VSEV_FIRST_ON+40)
#define VSEV_ON_KEYSTATECHANGE (VSEV_FIRST_ON+41)
#define VSEV_ON_GOT_FOCUS2     (VSEV_FIRST_ON+42)
#define VSEV_ON_LOST_FOCUS2    (VSEV_FIRST_ON+43)
#define VSEV_ON_HIGHLIGHT      (VSEV_FIRST_ON+44)
#define VSEV_LAST_ON           VSEV_ON_HIGHLIGHT
#define VSEV_RANGE_LAST_ON     (VSEV_LAST_ON+1)

/* You can use quoted characters instead of these predefined constants.
   The only possible problem is with a non-ASCII system (EBCDIC).
   We are currently not supporting any non-ASCII systems.
*/
#define VSEV_SPACE         ((VSEVENT)' ')
#define VSEV_EXCLAMATION   ((VSEVENT)'!')
#define VSEV_DOUBLEQUOTE   ((VSEVENT)'"')
#define VSEV_POUND         ((VSEVENT)'#')
#define VSEV_DOLLAR        ((VSEVENT)'$')
#define VSEV_PERCENT       ((VSEVENT)'%')
#define VSEV_AMPERSAND     ((VSEVENT)'&')
#define VSEV_SINGLEQUOTE   ((VSEVENT)'\'')
#define VSEV_LEFTPAREN     ((VSEVENT)'(')
#define VSEV_RIGHTPAREN    ((VSEVENT)')')
#define VSEV_STAR          ((VSEVENT)'*')
#define VSEV_PLUS          ((VSEVENT)'+')
#define VSEV_COMMA         ((VSEVENT)',')
#define VSEV_DASH          ((VSEVENT)'-')
#define VSEV_DOT           ((VSEVENT)'.')
#define VSEV_SLASH         ((VSEVENT)'/')
#define VSEV_0             ((VSEVENT)'0')
#define VSEV_1             ((VSEVENT)'1')
#define VSEV_2             ((VSEVENT)'2')
#define VSEV_3             ((VSEVENT)'3')
#define VSEV_4             ((VSEVENT)'4')
#define VSEV_5             ((VSEVENT)'5')
#define VSEV_6             ((VSEVENT)'6')
#define VSEV_7             ((VSEVENT)'7')
#define VSEV_8             ((VSEVENT)'8')
#define VSEV_9             ((VSEVENT)'9')
#define VSEV_COLON         ((VSEVENT)':')
#define VSEV_SEMICOLON     ((VSEVENT)';')
#define VSEV_LESSTHAN      ((VSEVENT)'<')
#define VSEV_EQUAL         ((VSEVENT)'=')
#define VSEV_GREATERTHAN   ((VSEVENT)'>')
#define VSEV_QUESTIONMARK  ((VSEVENT)'?')
#define VSEV_AT            ((VSEVENT)'@')
#define VSEV_A             ((VSEVENT)'A')
#define VSEV_B             ((VSEVENT)'B')
#define VSEV_C             ((VSEVENT)'C')
#define VSEV_D             ((VSEVENT)'D')
#define VSEV_E             ((VSEVENT)'E')
#define VSEV_F             ((VSEVENT)'F')
#define VSEV_G             ((VSEVENT)'G')
#define VSEV_H             ((VSEVENT)'H')
#define VSEV_I             ((VSEVENT)'I')
#define VSEV_J             ((VSEVENT)'J')
#define VSEV_K             ((VSEVENT)'K')
#define VSEV_L             ((VSEVENT)'L')
#define VSEV_M             ((VSEVENT)'M')
#define VSEV_N             ((VSEVENT)'N')
#define VSEV_O             ((VSEVENT)'O')
#define VSEV_P             ((VSEVENT)'P')
#define VSEV_Q             ((VSEVENT)'Q')
#define VSEV_R             ((VSEVENT)'R')
#define VSEV_S             ((VSEVENT)'S')
#define VSEV_T             ((VSEVENT)'T')
#define VSEV_U             ((VSEVENT)'U')
#define VSEV_V             ((VSEVENT)'V')
#define VSEV_W             ((VSEVENT)'W')
#define VSEV_X             ((VSEVENT)'X')
#define VSEV_Y             ((VSEVENT)'Y')
#define VSEV_Z             ((VSEVENT)'Z')

#define VSEV_LEFTBRACKET   ((VSEVENT)'[')
#define VSEV_BACKSLASH     ((VSEVENT)'\\')
#define VSEV_RIGHTBRACKET  ((VSEVENT)']')
#define VSEV_HAT           ((VSEVENT)'^')
#define VSEV_UNDERSCORE    ((VSEVENT)'_')
#define VSEV_BACKQUOTE     ((VSEVENT)'`')

#define VSEV_a             ((VSEVENT)'a')
#define VSEV_b             ((VSEVENT)'b')
#define VSEV_c             ((VSEVENT)'c')
#define VSEV_d             ((VSEVENT)'d')
#define VSEV_e             ((VSEVENT)'e')
#define VSEV_f             ((VSEVENT)'f')
#define VSEV_g             ((VSEVENT)'g')
#define VSEV_h             ((VSEVENT)'h')
#define VSEV_i             ((VSEVENT)'i')
#define VSEV_j             ((VSEVENT)'j')
#define VSEV_k             ((VSEVENT)'k')
#define VSEV_l             ((VSEVENT)'l')
#define VSEV_m             ((VSEVENT)'m')
#define VSEV_n             ((VSEVENT)'n')
#define VSEV_o             ((VSEVENT)'o')
#define VSEV_p             ((VSEVENT)'p')
#define VSEV_q             ((VSEVENT)'q')
#define VSEV_r             ((VSEVENT)'r')
#define VSEV_s             ((VSEVENT)'s')
#define VSEV_t             ((VSEVENT)'t')
#define VSEV_u             ((VSEVENT)'u')
#define VSEV_v             ((VSEVENT)'v')
#define VSEV_w             ((VSEVENT)'w')
#define VSEV_x             ((VSEVENT)'x')
#define VSEV_y             ((VSEVENT)'y')
#define VSEV_z             ((VSEVENT)'z')

#define VSEV_LEFTBRACE     ((VSEVENT)'{')
#define VSEV_PIPE          ((VSEVENT)'|')
#define VSEV_RIGHTBRACE    ((VSEVENT)'}')
#define VSEV_TILDE         ((VSEVENT)'~')

