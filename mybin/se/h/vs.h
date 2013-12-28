////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef VS_H
#define VS_H

#include "vsdecl.h"
#include "vsutf8.h"
#include "slickedit/SEArray.h"
#include "slickedit/SEString.h"

#if ! VSWINDOWS
   #include <unistd.h>
   typedef struct _XDisplay Display;
   typedef union _XEvent XEvent;
#endif

#define VSMAXFILENAME  1024
#define VSMAXSERVERNAME  256
#define VSMAXNAME        256
#define VSMAXEVENTNAME   64
#define VSMAXEMULATION   64
#define VSMAXCURWORD     1024
#define VSMAXMESSAGE     1024
#define VSMAXMESSAGELINE 1024
#define VSMAXMENUSTRING  VSMAXMESSAGELINE
#define VSMAXNAMEINFO    1024
#define VSMAXBOOKMARKLINEDATA  1024
#define VSMAXBOOKMARKNAME 256
#define VSMAXDOCUMENTNAME 1024
#define VSMAXEXTENSION    256
#define VSMAXLEXERNAME    256
#define VSMAXMODENAME     256
#define VSMAXBEGINENDPAIRS 1024
#define VSMAXWORDCHARS    300
#define VSMAXENCODING     100
// Maximum length of a composite character.
// Used by vsGetText where Len=-2
#define VSMAXUTF32ARRAYLEN      32

#define VSOI_MDI_FORM          1
#define VSOI_FORM              2
#define VSOI_TEXT_BOX          3
#define VSOI_CHECK_BOX         4
#define VSOI_COMMAND_BUTTON    5
#define VSOI_RADIO_BUTTON      6
#define VSOI_FRAME             7
#define VSOI_LABEL             8
#define VSOI_LIST_BOX          9
#define VSOI_HSCROLL_BAR       10
#define VSOI_VSCROLL_BAR       11
#define VSOI_COMBO_BOX         12
#define VSOI_HTHELP            13
#define VSOI_PICTURE_BOX       14
#define VSOI_IMAGE             15
#define VSOI_GAUGE             16
#define VSOI_SPIN              17
#define VSOI_MENU              18
#define VSOI_MENU_ITEM         19
#define VSOI_TREE_VIEW         20
#define VSOI_SSTAB             21
#define VSOI_DESKTOP           22
#define VSOI_SSTAB_CONTAINER   23
#define VSOI_EDITOR            24

#define VSSC_SIZE         0xF000
#define VSSC_MOVE         0xF010
#define VSSC_MINIMIZE     0xF020
#define VSSC_MAXIMIZE     0xF030
#define VSSC_NEXTWINDOW   0xF040
#define VSSC_PREVWINDOW   0xF050
#define VSSC_CLOSE        0xF060
#define VSSC_RESTORE      0xF120

// RefreshFlags
#define VSREFRESH_BUFTEXT    0x0001   /* Buffer refresh flag */
#define VSREFRESH_BUFNAME    0x0002   /* Buffer refresh flag */
#define VSREFRESH_MODENAME   0x0004   /* Buffer refresh flag */
#define VSREFRESH_READONLY   0x0008   /* Buffer refresh flag */
#define VSREFRESH_LINE       0x0010
#define VSREFRESH_COL        0x0020
#define VSREFRESH_INSERTMODE 0x10000
#define VSREFRESH_RECORDING  0x20000
#define VSREFRESH_ALERTS	 0x40000

// Picture with lowest order is displayed on top
#define VSPIC_ORDER_DEBUGGER            100
#define VSPIC_ORDER_BPM                 101
#define VSPIC_ORDER_ANNOTATION          200
#define VSPIC_ORDER_ANNOTATION_GRAY     201
#define VSPIC_ORDER_SET_BOOKMARK        202
#define VSPIC_ORDER_PUSHED_BOOKMARK     203
#define VSPIC_ORDER_PLUS                500
#define VSPIC_ORDER_MINUS               501

#define VSSTATUSFLAG_READONLY    0x0001
#define VSSTATUSFLAG_INSERTMODE  0x0002
#define VSSTATUSFLAG_RECORDING   0x0004

// Breakpoint line number changed because lines were inserted or deleted
#define VSBPMREFRESH_LINENUMBERS_CHANGED      0x1
// Breakpoint was deleted because lines were deleted
#define VSBPMREFRESH_BREAKPOINTS_AUTO_DELETED 0x2

// Line marker line number changed because lines were inserted or deleted
#define VSMARKERREFRESH_LINENUMBERS_CHANGED      0x1
// Marker was removed because all text within marker was deleted
#define VSMARKERREFRESH_REMOVE                   0x2
/*
    The new stream marker code is very scalable. Since there could be millions
    of markers, it is too slow to check every stream marker to update
    the VSPICREFRESH_OFFSET_CHANGED and VSPICREFRESH_LENGTH_CHANGED
    flags.  You can write your own code which checks for inserts and
    deletes and check your own markers.  This way, the performance implications
    are up to the coder.
*/
// Picture offset changed because text was inserted or deleted
//#define VSPICREFRESH_OFFSET_CHANGED           0x4
// Picture offset changed because text was inserted or deleted
//#define VSPICREFRESH_LENGTH_CHANGED           0x8

#define VSNULLSEEK      0x7fffffffl


typedef seSeekPos vsSeekPos;

   typedef struct {
      seSeekPos PointSeekPos;
      seSeekPos PointDownCount;
      seSeekPos ScrollTop;
      seSeekPos ScrollDown;
      int ScrollLeftEdge;
      seSeekPos RLine;
      seSeekPos Line;
      seLineOffset col;
      int HexNibble;
      int HexField;
      int CursorY;
      int LeftEdge;
      int junk1;
      char buffer[150-4*sizeof(long)-8*sizeof(int)];
   } VSSAVEPOS;

typedef void (VSAPI *VSPFNCALLBACK_AR_BUF_TEXT_CHANGED)(int buf_id,int wid,seSeekPos StartMod,seSeekPos EndMod);
typedef void (VSAPI *VSPFNCALLBACK_AR_APP_DELETE_BUFFER)(int buf_id);
typedef void (VSAPI *VSPFNCALLBACK_AR_APP_ADD_BUFFER)(int buf_id,VSPSZ pszBufName,int buf_flags);
typedef void (VSAPI *VSPFNCALLBACK_AR_APP_RENAME_BUFFER)(int buf_id,VSPSZ pszOldBufName,VSPSZ pszNewBufName,int buf_flags);
typedef void (VSAPI *VSPFNCALLBACK_AR_APP_RENAME_DOCUMENT)(int buf_id,VSPSZ pszOldBufName,VSPSZ pszNewBufName,int buf_flags);
typedef void (VSAPI *VSPFNCALLBACK_AR_BUF_LINES_INSERTED)(int buf_id,seSeekPos AfterLineNum,seSeekPos Noflines);
typedef void (VSAPI *VSPFNCALLBACK_AR_BUF_LINES_INSERTED2)(int buf_id,seSeekPos AfterLineNum,seSeekPos Noflines,int SplitLineCase);
typedef void (VSAPI *VSPFNCALLBACK_AR_BUF_LINES_DELETED)(int buf_id,seSeekPos FirstLineNum,seSeekPos Noflines);
typedef void (VSAPI *VSPFNCALLBACK_AR_BUF_LINES_DELETED2)(int buf_id,seSeekPos FirstLineNum,seSeekPos Noflines,int JoinLineCase);
typedef void (VSAPI *VSPFNCALLBACK_AR_BUF_DRAW_LINE)(int buf_id, int wid, int y, int height, seSeekPos LineNum,seSeekPos RealLineNum, int PastBottomOfFile, int SoftWrap);
typedef void (VSAPI *VSPFNCALLBACK_AR_BUF_DRAW_LINE_START_FINISH)(int buf_id, int wid, int start);
typedef void (VSAPI *VSPFNCALLBACK_AR_APP_SELECT_MODE)(int wid,const char *pszExtension);

//typedef void (VSAPI *VSPFNCALLBACK_AR_BUF_DELETE_TEXT)(int buf_id,seSeekPos StartOffset,seSeekPos EndOffset);
//typedef void (VSAPI *VSPFNCALLBACK_AR_BUF_INSERT_TEXT)(int buf_id,seSeekPos Offset,int NofBytes);
typedef void (VSAPI *VSPFNCALLBACK_AR_BUF_REPLACE_TEXT)(int buf_id,seSeekPos Offset,seSeekPos InsertNofBytes,seSeekPos DeleteNofBytes);

typedef void (VSAPI *VSPFNUPDATEEDITORSTATUS)(
                  int wid,int RefreshFlags,
                  seSeekPos linenum,int col,
                  const char *pModeName,int ModeNameLen,
                  int StatusFlags,
                  int reserved);


#define VSOFN_ALLOWMULTISELECT  0x1  // Allow multiple file selection
                                   // When set, user must process
#define VSOFN_FILEMUSTEXIST     0x2  // File(s) selected must exist
#define VSOFN_CHANGEDIR         0x4  // Ignored for backward compatibility

#define VSOFN_NOOVERWRITEPROMPT 0x8  // Don't prompt user with overwrite exisiting dialog. */
#define VSOFN_SAVEAS            0x10 // File list box does not select files and
                                   // user is prompted whether to overwrite an
                                   // existing file.
#define VSOFN_DELAYFILELIST     0x20 // Display dialog box before displaying
                                   // list.
#define VSOFN_NODELWINDOW       0x40 // Open file dialog is not deleted
                                   // when user selects cancel. Instead
                                   // window is made invisible.
#define VSOFN_READONLY          0x80 // Show read only button. Can't be used
                                   // with VSOFN_READONLY
                                   // See VSOFN_PREFIXFLAGS flag
#define VSOFN_KEEPOLDFILE       0x100 // Show keep old name button
                                    // See VSOFN_PREFIXFLAGS flag
#define VSOFN_PREFIXFLAGS       0x200 // Prefix result with -r if
                                    // VSOFN_READONLY flag given and -n if
                                    // VSOFN_KEEPOLDFILE flag given and -a if
                                    // VSOFN_APPEND given.
#define VSOFN_SAVEAS_FORMAT     0x400
#define VSOFN_SET_LAST_WILDCARDS 0x800
#if 0
      #define VSOFN_KEEPDIR           0x400 // Show keep dir check box
#endif
#define VSOFN_NOCHANGEDIR        0x1000  // Dont' show Change dir check box

#define VSOFN_APPEND            0x2000 // Show append button.
#define VSOFN_NODATASETS        0x4000 // OS390 ONLY. Don't allow datasets
#define VSOFN_ADD_TO_PROJECT    0x8000 // Add saved file to project

EXTERN_C_BEGIN
#define VSP_CANCEL              0   /* boolean*/
#define VSP_DEFAULT             1   /* boolean*/
#define VSP_ENABLED             2   /* boolean*/
#define VSP_FONTBOLD            3   /* boolean*/
#define VSP_FONTITALIC          4   /* boolean*/
#define VSP_FONTSIZE            5   /* string*/
#define VSP_FONTSTRIKETHRU      6   /* boolean*/
/* #define                       7 */
#define VSP_FONTUNDERLINE       8   /* boolean*/
#define VSP_MAXBUTTON           9   /* boolean*/
#define VSP_MINBUTTON           10  /* boolean*/
#define VSP_VISIBLE             11  /* boolean*/
#define VSP_TABSTOP             12  /* boolean*/
#define VSP_CONTROLBOX          13  /* boolean*/
/* #define                       14 */ /* boolean*/
#define VSP_STYLE               15   /* int */
#define VSP_BORDERSTYLE         16   /* int */
//#define VSP_DRAWSTYLE           17   /* int */
#define VSP_SCROLLBARS          18   /* int */
   #define VSSB_NONE         0
   #define VSSB_HORIZONTAL   1
   #define VSSB_VERTICAL     2
   #define VSSB_BOTH         3

#define VSP_MULTISELECT         19   /* int */
#define VSP_INITSTYLE           20   /* int */
#define VSP_FONT_CHARSET        21   /* byte */
#define VSP_ALIGNMENT           22   /* int */
#define VSP_WINDOWSTATE         23   /* string. */
#define VSP_MOUSEPOINTER        24   /* int */
#define VSP_INITINFO            25   /* int */
#define VSP_VALIDATEINFO        26   /* int */
#define VSP_EVENTTAB            27   /* int */
#define VSP_NAME                28   /* string */
#define VSP_CAPTION             29   /* string */
#define VSP_FONTNAME            30   /* string. */
#define VSP_BACKCOLOR           31   /* int */
/* #define                         32 *//* int */
//#define VSP_DRAWMODE            33   /* int */
//#define VSP_DRAWWIDTH           34   /* int */
#define VSP_FORECOLOR           35   /* int */
#define VSP_HEIGHT              36   /* int */
#define VSP_INTERVAL            37   /* int */
#define VSP_TABINDEX            38   /* int */
#define VSP_WIDTH               39   /* int */
#define VSP_X                   40   /* int */
#define VSP_Y                   41   /* int */
#define VSP_VALUE               42   /* int */
#define VSP_INFROMLEFT          43   /* int */
#define VSP_DOWNFROMTOP         44   /* int */
#define VSP_INFROMRIGHT         45   /* int */
#define VSP_UPFROMBOTTOM        46   /* int */
#define VSP_SCALEMODE           47   /* int */
   #define  VSSM_TWIP      1
   #define  VSSM_PIXEL     3

#define VSP_X1                  48   /* int */
#define VSP_Y1                  49   /* int */
#define VSP_X2                  50   /* int */
#define VSP_Y2                  51   /* int */
#define VSP_TEXT                52   /* string */
#define VSP_PICPOINTSCALE       53   /* int */
#define VSP_AFTERPICINDENTX     54   /* int */
#define VSP_PICSPACEY           55   /* int */
#define VSP_PICINDENTX          56   /* int */
#define VSP_PICTURE             57   /* int */
#define VSP_CBACTIVE            58   /* int */
#define VSP_STRETCH             59   /* boolean */
#define VSP_FONTPRINTER         60   /* boolean */
#define VSP_AUTOSIZE            61   /* boolean */
#define VSP_CBPICTURE           62   /* int */
#define VSP_CBLISTBOX           63   /* int */
#define VSP_CBTEXTBOX           64   /* int */
#define VSP_CB                  65   /* int */
#define VSP_OBJECT              66   /* int */
#define VSP_CHILD               67   /* int */
#define VSP_NEXT                68   /* int */
#define VSP_CLIPCONTROLS        69   /* boolean */
#define VSP_WORDWRAP            70   /* boolean */
#define VSP_ADEFAULT            71   /* boolean */
#define VSP_EDIT                72   /* boolean */
#define VSP_SELECTED            73   /* boolean */
#define VSP_OBJECTMODIFY        74   /* boolean */
//#define VSP_FILLSTYLE           75   /* int */
#define VSP_EVENTTAB2           76   /* int */
#define VSP_MIN                 77   /* int */
#define VSP_MAX                 78   /* int */
#define VSP_LARGECHANGE         79   /* int */
#define VSP_SMALLCHANGE         80   /* int */
#define VSP_DELAY               81   /* int */
#define VSP_CBEXTENDEDUI        82   /* boolean */
#define VSP_NOFSTATES           83   /* int */
#define VSP_ACTIVEFORM          84   /* int */
#define VSP_TEMPLATE            85   /* int */
#define VSP_COMPLETION          86   /* string */
#define VSP_MAXCLICK            87   /* int */
#define VSP_NOFSELECTED         88   /* int */
#define VSP_AUTOSELECT          89   /* boolean */
#define VSP_INCREMENT           90   /* int */
#define VSP_PREV                91   /* int */
#define VSP_COMMAND             92   /* string */
#define VSP_MESSAGE             93   /* string */
#define VSP_CATEGORIES          94   /* string */
#define VSP_CHECKED             95   /* boolean */
#define VSP_INTERPRETHTML       98   /* boolean */


#define VSP_TILEID               100  /* int */
#define VSP_WINDOWFLAGS          101  /* int */
   #define VSWINDOWFLAG_HIDDEN  0x1
   #define VSWINDOWFLAG_OVERRIDE_CURLINE_RECT 0x4
   #define VSWINDOWFLAG_CURLINE_RECT 0x8
   #define VSWINDOWFLAG_OVERRIDE_CURLINE_COLOR 0x10
   #define VSWINDOWFLAG_CURLINE_COLOR 0x20
//#define VSP_VSBBYTEDIVS          102  /* int */
#define VSP_WINDOWID             103  /* int */
#define VSP_LEFTEDGE             104  /* int */
#define VSP_CURSORX              105  /* int */
#define VSP_CURSORY              106  /* int */
#define VSP_LINE                 107  /* int64 */
#define VSP_NOFLINES             108  /* int64 */
#define VSP_COL                  109  /* int */
#define VSP_BUFNAME              110  /* string */
#define VSP_MODIFY               111  /* int */
#define VSP_BUFID                112  /* int */
#define VSP_MARGINS              113  /* string */
#define VSP_TABS                 114  /* string */
#define VSP_MODENAME             115  /* string */
#define VSP_BUFWIDTH             116  /* int */
#define VSP_WORDWRAPSTYLE        117  /* int */
   #define VSWWS_STRIP_SPACES  1
   #define VSWWS_WORD_WRAP     2
   #define VSWWS_JUSTIFY       4
   #define VSWWS_ONESPACE      8

#define VSP_SHOWTABS             118  /* int */
#define VSP_INDENTWITHTABS       119  /* boolean */
#define VSP_BUFFLAGS             120  /* int */
#define VSP_NEWLINE              121  /* string */
#define VSP_UNDOSTEPS            122  /* int */
#define VSP_INDEX                123  /* int */
#define VSP_BUFSIZE              124  /* int64 */
#define VSP_CHARHEIGHT           125  /* int */
#define VSP_CHARWIDTH            126  /* int */
#define VSP_VSBMAX               127  /* int */
#define VSP_HSBMAX               128  /* int */
#define VSP_FONTHEIGHT           129  /* int */
#define VSP_FONTWIDTH            130  /* int */
#define VSP_CLIENTHEIGHT         131  /* int */
#define VSP_CLIENTWIDTH          132  /* int */
#define VSP_OLDX                 133  /* int */
#define VSP_OLDY                 134  /* int */
#define VSP_OLDWIDTH             135  /* int */
#define VSP_OLDHEIGHT            136  /* int */
#define VSP_ONEVENT              137  /* int */
#define VSP_SELLENGTH            138  /* int */
#define VSP_SELSTART             139  /* int */
#define VSP_CURRENTX             140  /* int */
#define VSP_CURRENTY             141  /* int */
#define VSP_PARENT               142  /* int */
#define VSP_MDICHILD             143  /* int */
#define VSP_WINDENTX             144  /* int */
#define VSP_FIXEDFONT            145  /* int */
#define VSP_RELLINE              146  /* int */
#define VSP_SCROLLLEFTEDGE       147  /* int */
#define VSP_DISPLAYXLAT          148  /* string */
#define VSP_UNDOVISIBLE          149  /* int */
#define VSP_MODAL                150  /* int */
#define VSP_NOFWINDOWS           151  /* int */
#define VSP_USER                 152  /* string */
#define VSP_USER2                153  /* string */
#define VSP_NOSELECTCOLOR        154  /* boolean */
#define VSP_VIEWID               155  /* int */
#define VSP_INDENTSTYLE          156  /* int */
   #define VSINDENTSTYLE_NONE        0
   #define VSINDENTSTYLE_AUTO        1
   #define VSINDENTSTYLE_SMART       2

#define VSP_MODEEVENTTAB         157  /* int */
#define VSP_XYSCALEMODE          158  /* int */
#define VSP_XYPARENT             159  /* int */
//#define VSP_BUTTONBAR            160  /* int */
//#define VSP_ISBUTTONBAR          161  /* int */
#define VSP_MENUHANDLE           163  /* int */
#define VSP_FILEDATE             164  /* int64 */
#define VSP_REDRAW               165  /* boolean */
#define VSP_WORDCHARS            166  /* string */
#define VSP_LEXERNAME            167  /* string */
#define VSP_BUSER                168  /* string */
#define VSP_COLORFLAGS           169  /* int */
   #define VSCOLORFLAG_LANGUAGE    0x1
   #define VSCOLORFLAG_MODIFY      0x2
   #define VSCOLORFLAG_CLINE       0x4
#define VSP_HWND                 170  /* HWND */
#define VSP_HWNDFRAME            171  /* HWND */



#define VSP_BINARY              172   /* boolean */
#define VSP_SHOWEOF             173   /* boolean */
//#define I_SHOWNLCHARS         174
#define VSP_EMBEDDED_ORIG_VALUES  174 /* hvar */
#define VSP_READONLYMODE       175    /* boolean */
#define VSP_HEXNIBBLE          176    /* boolean */
#define VSP_HEXMODE            177    /* boolean */
#define VSP_HEXFIELD           178    /* int */
#define VSP_HEXNOFCOLS         179    // int
#define VSP_HEXTOPPAGE         180    // int64
#define VSP_NOFHIDDEN          181    // int64
#define VSP_LINENUMBERSLEN     182    // int
#define VSP_READONLYSETBYUSER  183    // boolean

#define VSP_WINDENT_Y          184    // int
#define VSP_NOFSELDISPBITMAPS  185    // int64
#define VSP_LINESTYLE          186    // int
#define VSP_LEVELINDENT        187    // int
#define VSP_SPACEY             188    // int
#define VSP_EXPANDPICTURE      189    // int
#define VSP_COLLAPSEPICTURE    190    // int
#define VSP_SHOWROOT           191    // int
//#define VSP_CHECKLISTBOX       192    not supported
#define VSP_LEAFPICTURE        197    // int


//#define VSP_PASSWORD            198   not supported
#define VSP_READONLY            199   // boolean
#define VSP_SHOWSPECIALCHARS    200   // int
#define VSP_MOUSEACTIVATE       201   // int
#define VSP_MODIFYFLAGS         202   // int
#define VSP_OLDLINENUMBER       203   // int64
#define VSP_NOFNOSAVE           204   // int64
#define VSP_CAPTIONCLICK        205   // boolean
#define VSP_RLINE               206   // int64
#define VSP_RNOFLINES           207   // int64


// SSTab properties
#define VSP_ACTIVETAB           208   // int
#define VSP_ORIENTATION         209   // int
#define VSP_TABSPERROW          210   // int
#define VSP_BESTFIT             211   // boolean
#define VSP_NOFTABS             212   // int
#define VSP_ACTIVEORDER         213   // int
#define VSP_ACTIVECAPTION       214   // int
#define VSP_ACTIVEPICTURE       215   // int
#define VSP_ACTIVEHELP          216   // string
#define VSP_RBUFSIZE            217   // int64
#define VSP_ACTIVEENABLED       218   // boolean
#define VSP_PICTUREONLY         219   // boolean
#define VSP_SOURCERECORDING     220   // boolean
#define VSP_DOCUMENTMODE        221   // boolean
#define VSP_PADDINGX            222   // int
#define VSP_PADDINGY            223   // int
#define VSP_FIRSTACTIVETAB      224   // int
#define VSP_ALLOWSAVE           225   // boolean
#define VSP_DEBUGMODE           226   // boolean
#define VSP_SPLITID             227   // int
#define VSP_SPLITORDER          228   // int
#define VSP_UTF8                229      // int
#define VSP_EMBEDDEDLEXERNAME   230      // string
#define VSP_SYNTAXINDENT        231      // int
#define VSP_DOCUMENTNAME        232      // string
#define VSP_EXTENSION           233      // string
#define VSP_LANG_ID             233      // string
#define VSP_LANGCASESENSITIVE   234      // boolean
#define VSP_SWAPCOLORS          235      // boolean
#define VSP_TOOLBARBORDER       236      // int

#define VSP_PROTECTREADONLYMODE 237      // int
   #define VSPROTECTREADONLYMODE_OPTIONAL 0
   #define VSPROTECTREADONLYMODE_ALWAYS   1
   #define VSPROTECTREADONLYMODE_NEVER    2

#define VSP_GRABBAR             238
#define VSP_EMBEDDED            239
   #define VSEMBEDDED_BOTH      0
   #define VSEMBEDDED_IGNORE    1
   #define VSEMBEDDED_ONLY      2

#define VSP_AUTOSELECTEXTENSION 240       // deprecated, use VSP_AUTOSELECTLANGUAGE
#define VSP_AUTOSELECTLANGUAGE  240       // boolean
#define VSP_MAXLINELENGTH       241
//#define VSP_CHECKMAXLINELENGTHONSAVE  242
#define VSP_TRUNCATELENGTH      243
#define VSP_GRABBARLOCATION     244
#define VSP_ACTIVETOOLTIP       245
#define VSP_LCBUFFLAGS          246
   #define VSLCBUFFLAG_READWRITE         0x1  /* prefix area on/off*/
   #define VSLCBUFFLAG_LINENUMBERS       0x2  /* Line numbers on/off */
   #define VSLCBUFFLAG_LINENUMBERS_AUTO  0x4  /* Line numbers automatic */
#define VSP_LCCOL               247
   //#define VSLCFLAG_LEADINGZEROS  0x4
#define VSP_LCHASCURSOR         248        // int
#define VSP_LCINDENTX           249        // int
#define VSP_ENQNAME             250        // string
#define VSP_BOUNDSSTART         251        // int
#define VSP_BOUNDSEND           252        // int
#define VSP_CAPS                253        // int
#define VSP_LINE_HEIGHT         254        // int
#define VSP_ENCODING            256        // int
#define VSP_ENCODING_SET_BY_USER 257         // int
#define VSP_XLAT                258          // boolean
#define VSP_RAWPOS              259          // string
#define VSP_ENCODING_TRANSLATION_ERROR 260   // int
#define VSP_ACTIVECAPTIONCOLOR  261          // int
#define VSP_NEVERCOLORCURRENT   262
#define VSP_SOFTWRAP            263
#define VSP_SOFTWRAPONWORD      264
#define VSP_COLOR_ENTIRE_LINE   272
#define VSP_LASTMODIFIED        273
#define VSP_HASBUFFER           274
#define VSP_DOCKINGAREA         275
#define VSP_KEEPPICTUREGUTTER   276
#define VSP_ISTEMPEDITOR        277
#define VSP_HIGHLIGHTTAB        278
#define VSP_LISTCOMPLETIONS     279
#define VSP_LINESFORCEWRAPPED   280
//#define VSP_HIDETABROW          281
#define VSP_ADAPTIVE_FORMATTING_FLAGS  282   // int
#define VSP_INDENT_CASE_FROM_SWITCH    283   // boolean
#define VSP_PAD_PARENS                 284   // boolean
#define VSP_NO_SPACE_BEFORE_PAREN      285   // boolean
#define VSP_BEGIN_END_STYLE            286   // int
#define VSP_POINTER_STYLE              287   // int
#define VSP_FUNCTION_BRACE_ON_NEWLINE  288   // boolean
#define VSP_KEYWORD_CASING             289   // int
#define VSP_TAG_CASING                 290   // int
#define VSP_ATTRIBUTE_CASING           291   // int
#define VSP_VALUE_CASING               292   // int
#define VSP_HEX_VALUE_CASING           293   // int
#define VSP_IDENTIFIER_CHARS           294   // string
#define VSP_WIDGET                     301   // long
#define VSP_SHOWMODAL                  302   // boolean
#define VSP_CHECKABLE                  304   // boolean 
#define VSP_DISPLAY_LIST_ON_DOWN_KEY   305   // int
#define VSP_MULTIROW                   306   // Deprecated
#define VSP_FILESIZE                   307   // int64
#define VSP_CLOSABLETABS               308   // boolean
#define VSP_MDI_CHILD_DUPLICATE_ID     311   // int
#define VSP_BUFNAME_NO_SYMLINKS        312   // string


/* Completion arguments */
    /* "!" indicates last argument. */
#define VSARG_MORE     "*"      /* Indicate more arguments. */
#define VSARG_WORD     "w"      /* Match what was typed. */
#define VSARG_FILE     "f:18"   /* Match one file. 18=FILE_CASE_MATCH|AUTO_DIR_MATCH*/
#define VSARG_MULTI_FILE  VSARG_FILE"*"
#define VSARG_BUFFER     "b:2"    /* Match buffer. */
#define VSARG_COMMAND    "c"
#define VSARG_PICTURE    "_pic"
#define VSARG_FORM       "_form"
#define VSARG_OBJECT     "_object"
#define VSARG_MODULE     "m"
#define VSARG_PC         "pc"     /* look for procedure or command . */
                      /* look Slick-C tag cmd,proc,form */
#define VSARG_MACROTAG   "mt:8"   /* Any find-proc item. 8=REMOVE_DUPS_MATCH */
#define VSARG_MACRO      "k"      /* Recorded macro command. */
#define VSTYPE_ARG_PCB   "pcbt"   /* list proc,command, and built-in types. */
#define VSARG_VAR        "v"      /* look for variable. Global vars not included.*/
#define VSARG_ENV        "e"      /* look for environment variables. */
#define VSARG_MENU       "_menu"
#define VSARG_HELP       "h:37" /* (TERMINATE_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH) */
   /* Match tag used by push-tag command. */
#define VSARG_TAG        "tag:37" /* (REMOVE_DUPS_MATCH|NO_SORT_MATCH|TERMINATE_MATCH) */



/*
   NOTE:

   VSARG2_MARK,VSARG2_NOEXIT_SCROLL,
   VSARG2_READ_ONLY, VSARG2_ICON are now
   ignored if the command does not require an
   editor control.

       VSARG2_REQUIRES_EDITORCTL
                or
       VSARG2_REQUIRES_MDI_EDITORCTL

   This is different than versions <= 3.0
*/
#define VSARG2_NCW      0      // Ignored. Here for backward compatibility.
                               // Previously: Command allowed when there are no MDI child windows.
#define VSARG2_CMDLINE  0x4    // Command supports the command line.
                               // VSARG2_CMDLINE allows a fundamental mode
                               // key binding to be inherited by the command line
#define VSARG2_MARK     0x8    // ON_SELECT event should pass control on
                               // to this command and not deselect text first.
                               // Ignored if command does not require an editor control
#define VSARG2_LINEHEX   0x20  // Do not reset p_hex_nibble and p_hex_field
#define VSARG2_QUOTE     0x40  // Indicates that this command must be quoted when
                               // called during macro recording.  Needed only if
                               // command name is an invalid identifier or
                               // keyword.
#define VSARG2_LASTKEY  0x80   // Command requires last_event value to be set
                               // when called during macro recording.
#define VSARG2_MACRO     0x100      // This is a recorded macro command. Used for completion.
#define VSARG2_HELP      0          // Ignored. Here for backward compatibility.
#define VSARG2_HELPSALL  0          // Ignored. Here for backward compatibility.
#define VSARG2_TEXT_BOX  0x800      // Command supports any text box control.
                                    // VSARG2_TEXT_BOX allows a fundamental mode
                                    // key binding to be inherited by a text box
#define VSARG2_NOEXIT_SCROLL 0x1000 // Do not exit scroll caused by using scroll bars.
                                    // Ignored if command does not require an editor control
#define VSARG2_EDITORCTL   0x2000   // Command allowed in editor control.
                                    // VSARG2_EDITORCTL allows a fundamental mode
                                    // key binding to be inherited by a non-MDI editor control
#define VSARG2_NOUNDOS     0x4000   // Do not automatically call _undo('s').
                                    // Require macro to call _undo('s') to
                                    // start a new level of undo.
// Command allowed when editor control is in strict read only mode
// Ignored if command does not require an editor control
#define VSARG2_READ_ONLY   0x10
// Command allowed when editor control window is iconized
// Ignored if command does not require an editor control
#define VSARG2_ICON        0x2


// Command requires any editor control
#define VSARG2_REQUIRES_EDITORCTL       (VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_EDITORCTL)
#define VSARG2_REQUIRES_MDI_EDITORCTL   0x00010000 // Command requires mdi editor control


#define VSARG2_REQUIRES_AB_SELECTION    0x00020000 // Command requires selection in active buffer
#define VSARG2_REQUIRES_BLOCK_SELECTION 0x00040000 // Command requires block/column selection in any buffer
#define VSARG2_REQUIRES_CLIPBOARD       0x00080000 // Command requires editorctl clipboard
#define VSARG2_REQUIRES_FILEMAN_MODE    0x00100000 // Command requires active buffer to be in fileman mode
#define VSARG2_REQUIRES_TAGGING         0x00200000 // Command requires <ext>_proc_search/find-tag support
//#define VSARG2_REQUIRES_                0x00400000

#define VSARG2_REQUIRES_SELECTION       0x00800000 // Command requires a selection in any buffer
#define VSARG2_REQUIRES_MDI             0x00008000 // Command requires mdi interface may be because
                                                   // it opens a new file or uses _mdi object.

#define VSARG2_REQUIRES_PROJECT_SUPPORT 0x02000000 // Command requires project support
#define VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW  0x04000000  // Command requires min/max/restore/iconize window support
#define VSARG2_REQUIRES_TILED_WINDOWING    0x08000000            // Command requires tiled windowing
#define VSARG2_REQUIRES_GUIBUILDER_SUPPORT 0x10000000            // Command requires gui builder support

#define VSARG2_EXECUTE_FROM_MENU_ONLY      0x80000000  // This command can only be executed from a menu.
                                                       // This flag is in a way redundant since you can get the same
                                                       // effect with more control by writing an _OnUpdate.  However, it
                                                       // takes much less time to just add this attribute to a command.

#define VSARG2_REQUIRES  (VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_BLOCK_SELECTION|VSARG2_REQUIRES_CLIPBOARD|VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_SELECTION|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_PROJECT_SUPPORT|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW|VSARG2_REQUIRES_TILED_WINDOWING|VSARG2_REQUIRES_GUIBUILDER_SUPPORT)

/* vsNameType flags. */

#define VSWWS_STRIP_SPACES     1
#define VSWWS_WORD_WRAP        2
#define VSWWS_JUSTIFY          4

#define VSSHOWSPECIALCHARS_NLCHARS  0x01
#define VSSHOWSPECIALCHARS_TABS     0x02
#define VSSHOWSPECIALCHARS_SPACES   0x04
#define VSSHOWSPECIALCHARS_OTHER_CTRL_CHAR 0x8
#define VSSHOWSPECIALCHARS_EOF      VSSHOWSPECIALCHARS_OTHER_CTRL_CHAR
#define VSSHOWSPECIALCHARS_FORMFEED VSSHOWSPECIALCHARS_OTHER_CTRL_CHAR
#define VSSHOWSPECIALCHARS_ALL      0xff

#define VSBUF_RETRIEVE     0

#define VSVIEW_RETRIEVE   VSWID_RETRIEVE
#define VSVIEW_HIDDEN     VSWID_HIDDEN

// p_buf_flags
#define VSBUFFLAG_HIDDEN        0x1  /* NEXT_BUFFER won't switch to this buffer */
#define VSBUFFLAG_THROW_AWAY_CHANGES 0x2  /* Allow quit without prompting on modified buffer */
#define VSBUFFLAG_KEEP_ON_QUIT 0x4  /* Don't delete buffer on QUIT.  */
#define VSBUFFLAG_REVERT_ON_THROW_AWAY 0x10
#define VSBUFFLAG_PROMPT_REPLACE 0x20
#define VSBUFFLAG_DELETE_BUFFER_ON_CLOSE 0x40   /* Indicates whether a list box/ */
// Reserved FTP flags for full product
#define VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS 0x80   /* Specifies that buffer is currently being uploaded via FTP*/
#define VSBUFFLAG_FTP_BINARY             0x100  /* Specifies that the FTP buffer should be transferred binary by default */

// Predefined object handles

#define VSWID_DESKTOP       1
#define VSWID_APP           2
#define VSWID_MDI           3
#define VSWID_CMDLINE       4
#define VSWID_HIDDEN        5
#define VSWID_STATUS        6
#define VSWID_RETRIEVE      7

#include "slickc.h"
#define VSSELECT_INCLUSIVE     0x1
#define VSSELECT_NONINCLUSIVE  0x2
#define VSSELECT_CURSOREXTENDS 0x4
#define VSSELECT_BEGINEND      0x8
#define VSSELECT_PERSISTENT    0x10


#define VSSELECT_LINE   1
#define VSSELECT_CHAR   2
#define VSSELECT_BLOCK  4
// Only supported by vsSetSelectType
#define VSSELECT_NONINCLUSIVEBLOCK 8

#define VSOPTION_WARNING_ARRAY_SIZE    1
#define VSOPTION_WARNING_STRING_LENGTH 2
#define VSOPTION_VERTICAL_LINE_COL     3
#define VSOPTION_WEAK_ERRORS           4
#define VSOPTION_AUTO_ZOOM_SETTING     5
#define VSOPTION_MAXIMIZE_FIRST_MDICHILD  AUTO_ZOOM_SETTING
#define VSOPTION_MAXTABCOL             6
#define VSOPTION_CURSOR_BLINK          7
#define VSOPTION_DISPLAY_TEMP_CURSOR   8
#define VSOPTION_LEFT_MARGIN           9
#define VSOPTION_DISPLAY_TOP_OF_FILE   10
#define VSOPTION_HORIZONTAL_SCROLL_BAR 11
#define VSOPTION_VERTICAL_SCROLL_BAR   12
#define VSOPTION_HIDE_MOUSE            13
#define VSOPTION_ALT_ACTIVATES_MENU    14
#define VSOPTION_DRAW_BOX_AROUND_CURRENT_LINE 15
#define VSOPTION_MAX_MENU_FILENAME_LEN 16
#define VSOPTION_PROTECT_READONLY_MODE 17
#define VSOPTION_PROCESS_BUFFER_CR_ERASE_LINE 18
#define VSOPTION_ENABLE_FONT_FLAGS     19
#define VSOPTION_APIFLAGS              20
#define VSOPTION_HAVECMDLINE           21
#define VSOPTION_QUIET                 22
#define VSOPTION_SHOWTOOLTIPS          23
#define VSOPTION_TOOLTIPDELAY          24
#define VSOPTION_HAVEMESSAGELINE       25
#define VSOPTION_HAVEGETMESSAGELINE    26
#define VSOPTION_MACRO_SOURCE_LEVEL    27
#define VSOPTION_VSAPI_SOURCE_LEVEL    28
#define VSOPTION_APPLY_LOCAL_STATE_FILE_CHANGES 29
#define VSOPTION_EMBEDDED              30   /* Option dropped. See VSP_EMBEDDED property */
#define VSOPTION_DISPLAYVERSIONMESSAGE 31
#define VSOPTION_CXDRAGMIN             32
#define VSOPTION_CYDRAGMIN             33
#define VSOPTION_DRAGDELAY             34
#define VSOPTION_MDI_SHOW_WINDOW_FLAGS 35//4:26pm 4/20/1998
                                         //Dan added for to support hiding mdi
                                         //on startup
#define VSOPTION_SEARCHDEFAULTFLAGS           36
   #define VSSEARCHDEFAULTFLAG_INIT_HISTORY      0x1
   #define VSSEARCHDEFAULTFLAG_INIT_CURWORD      0x2
   #define VSSEARCHDEFAULTFLAG_INIT_SELECTION    0x4
   // INIT_SELECTION can be on with HISTORY or CURWORD
   #define VSSEARCHDEFAULTFLAGC_INIT_MASK        (0x1|0x2)

   #define VSSEARCHDEFAULTFLAG_IGNORE_CASE       0x20
   #define VSSEARCHDEFAULTFLAG_WRAP_AT_BEGIN_END 0x40
   #define VSSEARCHDEFAULTFLAG_RESTORE_CURSOR_AFTER_REPLACE 0x80
   #define VSSEARCHDEFAULTFLAG_LEAVE_SELECTED    0x100
   #define VSSEARCHDEFAULTFLAG_RE                0x200

   #define VSSEARCHDEFAULTFLAG_RE_SYNTAX_UNIX           0x000
   #define VSSEARCHDEFAULTFLAG_RE_SYNTAX_SLICKEDIT      0x800
   #define VSSEARCHDEFAULTFLAG_RE_SYNTAX_BRIEF          0x1000
   #define VSSEARCHDEFAULTFLAG_RE_SYNTAX_WILDCARD       0x2000
   #define VSSEARCHDEFAULTFLAG_RE_SYNTAX_PERL           0x4000

   #define VSSEARCHDEFAULTFLAGC_RE_SYNTAX_MASK         (0x000|0x800|0x1000|0x2000|0x4000)
#define VSOPTION_MAX_STACK_DUMP_LINE_LENGTH 37
#define VSOPTION_MAX_STACK_DUMP_ARGUMENT_NOFLINES 38
#define VSOPTION_NEXTWINDOWSTYLE                  39
#define VSOPTION_CODEHELP_FLAGS        40
// Default line command flags
// Needed for implementing a prefix area for ISPF
// emulation.  See VSLCFLAG_???
#define VSOPTION_LINE_NUMBERS_LEN      41  /* Initial value for VSP_LINENUMBERSLEN when buffer is created. */
#define VSOPTION_LCREADWRITE           42  /* If non-zero and buffer is writeable, VSLCFLAG_READWRITE is added to VSP_LCFLAGS when buffer is created. */
#define VSOPTION_LCREADONLY            43  /* If non-zero and buffer is read only, VSLCFLAG_READWRITE is added to VSP_LCFLAGS when buffer is created. */
#define VSOPTION_LCMAXNOFLINECOMMANDS  44
#define VSOPTION_RIGHT_CONTROL_IS_ENTER 45 /* obsolete */
#define VSOPTION_DOUBLE_CLICK_TIME     46
#define VSOPTION_LCNOCOLON             47
#define VSOPTION_PACKFLAGS1            48  /* Reserved for SlickEdit Inc. - 32-bit int of license flags */
#define VSOPTION_PACKFLAGS2            49  /* Reserved for SlickEdit Inc. - 32-bit int of license flags */
#define VSOPTION_UTF8_SUPPORT          50
#define VSOPTION_UNICODE_CALLS_AVAILABLE  51
#define VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS 52
#define VSOPTION_JAWS_MODE             53
#define VSOPTION_JGUI_SOCKET 54
#define VSOPTION_SHOW_SPLASH 55  /* 1=Show the splash screen on startup */
#define VSOPTION_FORCE_WRAP_LINE_LEN 56
#define VSOPTION_APPLICATION_CAPTION_FLAGS 57
#define VSOPTION_IPVERSION_SUPPORTED 58
   #define VSIPVERSION_ALL 0
   #define VSIPVERSION_4   1
   #define VSIPVERSION_6   2
#define VSOPTION_NO_BEEP            59
#define VSOPTION_NEW_WINDOW_WIDTH   60
#define VSOPTION_NEW_WINDOW_HEIGHT  61
// VSOPTION_USE_CTRL_SPACE_FOR_IME is no longer supported
#define VSOPTION_USE_CTRL_SPACE_FOR_IME 62
// Do not write any files into the
// configuration files.
// This option is needed for creating a licensing file
// during the installation process which may have
// administrator or root access.  We do not want
// configuration files written during installation
// process.
#define VSOPTION_CANT_WRITE_CONFIG_FILES    63
// Option when clicking in a registered MDI editor control, that does not
// have focus, to place caret at mouse hit coordinates in addition to
// giving focus.
#define VSOPTION_PLACE_CARET_ON_FOCUS_CLICK 64
// When get value, non-zero value means keep command line visible.
// When setting value, specify 1 to increment, 0 to decrement. Returns current count
#define VSOPTION_STAY_IN_GET_STRING_COUNT   65

#define VSOPTION_USE_UNIFIED_TOOLBAR   66
#define VSOPTION_MAC_ALT_KEY_BEHAVIOR  67
   #define VSOPTION_MAC_ALT_KEY_DEFAULT_IME_BEHAVIOR 0
   #define VSOPTION_MAC_ALT_KEY_WINDOWS_STYLE_BEHAVIOR 1
#define VSOPTION_NO_ANTIALIAS          68
#define VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS  69
#define VSOPTION_USE_CLEAR_KEY_AS_NUMLOCK_KEY      70
#define VSOPTION_CLEAR_KEY_NUMLOCK_STATE           71
#define VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE   72
#define VSOPTION_MAC_RESIZE_BORDERS                73
#define VSOPTION_CURSOR_BLINK_RATE                 74
// Do not read vrestore.slk or other user configuration files.
// This option is used to simplify starting the editor
// when you have a corrupt vrestore.slk, and is also used
// by utility programs that launch the editor, like vsmktags
#define VSOPTION_DONT_READ_CONFIG_FILES            75
// Option to disable corner toolbar on some Unix Window Managers
#define VSOPTION_MDI_ALLOW_CORNER_TOOLBAR          76
// Option for Mac High DPI (Retina) displays. High DPI doesn't work with
// the "Fast Pixmap scrolling" optimization in crt2.cpp
#define VSOPTION_MAC_HIGH_DPI_SUPPORT              77
   #define VSOPTION_MAC_HIGH_DPI_AUTO 0
   #define VSOPTION_MAC_HIGH_DPI_ON   1
   #define VSOPTION_MAC_HIGH_DPI_OFF  2
// Mac option to show the Windows-style full file path in the 
// main window title (and not use Mac native Proxy icons)
#define VSOPTION_MAC_SHOW_FULL_MDI_CHILD_PATH      78
// Option for Tab title display
   #define VSOPTION_TAB_TITLE_SHORT_NAME 0
   #define VSOPTION_TAB_TITLE_NAME_FOLLOWED_BY_FULL_PATH 1
   #define VSOPTION_TAB_TITLE_NAME_FOLLOWED_BY_PATH 2
   #define VSOPTION_TAB_TITLE_FULL_PATH     3
#define VSOPTION_TAB_TITLE                         79
   #define VSOPTION_SPLIT_WINDOW_EVENLY           0
   #define VSOPTION_SPLIT_WINDOW_STRICT_HALVING   1
#define VSOPTION_SPLIT_WINDOW                      80
   #define VSOPTION_ZOOM_WHEN_ONE_WINDOW_NEVER   0
   #define VSOPTION_ZOOM_WHEN_ONE_WINDOW_ALWAYS  1
   #define VSOPTION_ZOOM_WHEN_ONE_WINDOW_AUTO    2
#define VSOPTION_ZOOM_WHEN_ONE_WINDOW              81
#define VSOPTION_TAB_MODIFIED_COLOR                82
#define VSOPTION_JOIN_WINDOW_WITH_NEXT             83
/*#define VSOPTION_DRAGGING_DOCUMENT_TAB             84*/
#define VSOPTION_AUTO_RESTORING_TO_NEW_SCREEN_SIZE 85


#define VSOPTIONZ_PAST_EOF               1000

#define VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB  1001
   #define VSSPECIALCHAR_NOT_USED_1    0
   #define VSSPECIALCHAR_NOT_USED_2    1
   #define VSSPECIALCHAR_NOT_USED_3    2
   #define VSSPECIALCHAR_NOT_USED_4    3
   #define VSSPECIALCHAR_NOT_USED_5    4
   #define VSSPECIALCHAR_EOF           5
   #define VSSPECIALCHAR_FORMFEED      6
   #define VSSPECIALCHAR_OTHER_CTRL_CHAR 7
   #define VSSPECIALCHAR_EOL           8
   #define VSSPECIALCHAR_CR            9
   #define VSSPECIALCHAR_LF            10

   #define VSSPECIALCHAR_MAX     20

#define VSOPTIONZ_APPLICATION_NAME       1002
#define VSOPTIONZ_SUPPORTED_TOOLBARS_LIST  1003
#define VSOPTIONZ_LANG                     1004
#define VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8 1005
#define VSOPTIONZ_DEFAULT_FIND_WINDOW_OPTIONS 1006
/* #define VSOPTION_LINE_NUMBERS_LEN      3 */



#define VPJ_SHOWONMENU_HIDEIFNOCMDLINE  'HideIfNoCmdLine'
#define VPJ_SHOWONMENU_NEVER  'Never'
#define VPJ_SHOWONMENU_ALWAYS  'Always'

#define VPJTAG_PROJECT "Project"
#define VPJTAG_MACRO   "Macro"
#define VPJTAG_CONFIG  "Config"
#define VPJTAG_FILES   "Files"
#define VPJTAG_DEPENDENCIES "Dependencies"
#define VPJTAG_DEPENDENCY "Dependency"
#define VPJTAG_EXECMACRO    "ExecMacro"
#define VPJTAG_APPTYPETARGETS    "AppTypeTargets"
#define VPJTAG_APPTYPETARGET    "AppTypeTarget"
#define VPJTAG_TARGET    "Target"
#define VPJTAG_FOLDER    "Folder"
#define VPJTAG_F "F"
#define VPJTAG_MENU    "Menu"

#define VPJX_PROJECT  "/"VPJTAG_PROJECT
#define VPJX_MACRO    VPJX_PROJECT"/"VPJTAG_MACRO
#define VPJX_CONFIG   VPJX_PROJECT"/"VPJTAG_CONFIG
#define VPJX_FILES    VPJX_PROJECT"/"VPJTAG_FILES
#define VPJX_DEPENDENCIES VPJX_PROJECT"/"VPJTAG_DEPENDENCIES
#define VPJX_DEPENDENCY VPJX_DEPENDENCIES"/"VPJTAG_DEPENDENCY
#define VPJX_EXECMACRO VPJX_MACRO"/"VPJTAG_EXECMACRO
#define VPJX_APPTYPETARGETS VPJX_CONFIG"/"VPJTAG_APPTYPETARGETS
#define VPJX_APPTYPETARGET VPJX_APPTYPETARGETS"/"VPJTAG_APPTYPETARGET


#define VPWTAG_WORKSPACE "Workspace"
#define VPWTAG_PROJECTS "Projects"
#define VPWTAG_PROJECT "Project"
#define VPWTAG_ENVIRONMENT "Environment"
#define VPWTAG_SET         "Set"

#define VPWX_WORKSPACE "/"VPWTAG_WORKSPACE
#define VPWX_PROJECTS  VPWX_WORKSPACE"/"VPWTAG_PROJECTS
#define VPWX_PROJECT   VPWX_PROJECTS"/"VPWTAG_PROJECT
#define VPWX_ENVIRONMENT  VPWX_WORKSPACE"/"VPWTAG_ENVIRONMENT
#define VPWX_SET          VPWX_ENVIRONMENT"/"VPWTAG_SET


#define VPTTAG_TEMPLATES  "Templates"
#define VPTTAG_TEMPLATE  "Template"

#define VPTX_TEMPLATES "/"VPTTAG_TEMPLATES
#define VPTX_TEMPLATE  VPTX_TEMPLATES"/"VPTTAG_TEMPLATE


/**
 * Draw box around current line options -- No box
 * @see vsSetDefaultOption
 * @see vsQDefaultOption(VSOPTION_DRAW_BOX_AROUND_CURRENT_LINE)
 */
#define VSCURRENT_LINE_BOXFOCUS_NONE    0
/**
 * Draw box around current line options -- only the box, no ruler
 * @see vsSetDefaultOption
 * @see vsQDefaultOption(VSOPTION_DRAW_BOX_AROUND_CURRENT_LINE)
 */
#define VSCURRENT_LINE_BOXFOCUS_ONLY    1
/**
 * Draw box around current line options -- tabs ruler
 * @see vsSetDefaultOption
 * @see vsQDefaultOption(VSOPTION_DRAW_BOX_AROUND_CURRENT_LINE)
 */
#define VSCURRENT_LINE_BOXFOCUS_TABS    2
/**
 * Draw box around current line options -- syntax indent ruler
 * @see vsSetDefaultOption
 * @see vsQDefaultOption(VSOPTION_DRAW_BOX_AROUND_CURRENT_LINE)
 */
#define VSCURRENT_LINE_BOXFOCUS_INDENT  3
/**
 * Draw box around current line options -- decimal ruler
 * @see vsSetDefaultOption
 * @see vsQDefaultOption(VSOPTION_DRAW_BOX_AROUND_CURRENT_LINE)
 */
#define VSCURRENT_LINE_BOXFOCUS_DECIMAL 4
/**
 * Draw box around current line options -- COBOL Area ruler
 * @see vsSetDefaultOption
 * @see vsQDefaultOption(VSOPTION_DRAW_BOX_AROUND_CURRENT_LINE)
 */
#define VSCURRENT_LINE_BOXFOCUS_COBOL 5


/**
 * See Slick-C&reg; {@link load_files} method for information on return
 * values and pszCmdLine string.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszCmdLine	See {@link load_files} method for more
 * information.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods, File_Functions, Window_Functions
 *
 */
int VSAPI vsLoadFiles(int wid,const char *pszCmdline);

#define VSBLRESULTFLAG_NEWFILECREATED      0x1
#define VSBLRESULTFLAG_NEWTEMPFILECREATED  0x2
#define VSBLRESULTFLAG_NEWFILELOADED       0x4
#define VSBLRESULTFLAG_READONLYACCESS      0x8
#define VSBLRESULTFLAG_ANOTHERPROCESS      0x10
#define VSBLRESULTFLAG_READONLY            (VSBLRESULTFLAG_READONLYACCESS|VSBLRESULTFLAG_ANOTHERPROCESS)
#define VSBLRESULTFLAG_NEW                 (VSBLRESULTFLAG_NEWFILECREATED|VSBLRESULTFLAG_NEWTEMPFILECREATED|VSBLRESULTFLAG_NEWFILELOADED)
/**
 *
 * @param filename   Name of buffer to find or file to load.  If options specifies a filename, +bi, or +v,
 *                   this parameter is ignored.  Null or '' may be specified when options are specified
 *                   which don't require a filename.
 * @param options    See {@link load_files} function for options.
 * @param CreateIfNotFound   Indicates that the a new file should be created if the file does not exist.
 *                           This option is ignored if the +t, +b, +bi, or +v options are specified.
 * @param pBLResultFlags
 *                 Set to 0 or more of the following flags:
 *                 <dl compact>
 *                 <dt>VSBLRESULTFLAG_NEWFILECREATED</dt>
 *                 <dd>Indicates that a new file was created because the file was not found</dd>
 *                 <dt>VSBLRESULTFLAG_NEWTEMPFILECREATED</dt>
 *                 <dd>Indicates that a new temp file (+t option) was created</dd>
 *                 <dt>VSBLRESULTFLAG_NEWFILELOADED</dt>
 *                 <dd>Indicates that a file was loaded</dd>
 *                 <dt>VSBLRESULTFLAG_READONLY</dt>
 *                 <dd>Indicates that a file was loaded read only</dd>
 *                 <dt>VSBLRESULTFLAG_READONLYACCESS</dt>
 *                 <dd>Indicates that a file was loaded read only because of permissions on the file</dd>
 *                 <dt>VSBLRESULTFLAG_ANOTHERPROCESS</dt>
 *                 <dd>Indicates that a file was loaded read only because another process has the file open</dd>
 *                 </dl>
 * @example
 * <pre>
 *
 * // If absolute("test.cpp") exists as a buffer, return
 * // the buffer id.  Otherwise if the file exists on disk,
 * // load the active code page file from disk and return the buffer id.
 * // Otherwise, create a new buffer with name absolute("test.cpp")
 * // and set NewFileCreated=true.
 * bool NewFileCreated;
 * int bufid=vsBufLoad("test.cpp",0,true,&NewFileCreated);
 *
 * // Load the active code page file test.cpp from disk. If
 * // the file is not found, don't create it and
 * // return FILE_NOT_FOUND_RC.  p_buf_name is set to
 * // absolute("test.cpp").
 * int bufid=vsBufLoad("test.cpp","+d",false);
 *
 * // Load the UTF-8 file test.cpp from disk. If
 * // the file is not found, don't create it and
 * // return FILE_NOT_FOUND_RC.  p_buf_name is set to
 * // absolute("test.cpp").
 * int bufid=vsBufLoad("test.cpp","+futf8 +d",false);
 *
 * // Load test.cpp from disk. If the file is not found,
 * // create it and return the newly created buffer id.
 * // p_buf_name is set to absolute("test.cpp")
 * int bufid=vsBufLoad("test.cpp","+d");
 *
 * // Create an active code page temp buffer
 * int bufid=vsBufLoad(null,"+t");
 *
 * // Create a Unicode temp buffer
 * int bufid=vsBufLoad(null,"+futf8 +t");
 *
 * // Create a temp buffer and set p_buf_name to ".internal"
 * int bufid=vsBufLoad(".internal","+ti");
 *
 * // Create a temp buffer and set p_buf_name to absolute("temp")
 * int bufid=vsBufLoad("temp","+t");
 *
 * //Find the buffer id for the ".command" retrieve buffer
 * int bufid=vsBufLoad(".command","+b");
 *
 * </pre>
 *
 * @return If successful a buffer id>=0 is returned.  Otherwise a negative error code
 * is returned.  Common return codes are
 * FILE_NOT_FOUND_RC (occurs when wild card specification matches no files),
 * PATH_NOT_FOUND_RC, TOO_MANY_WINDOWS_RC, TOO_MANY_FILES_RC,
 * TOO_MANY_SELECTIONS_RC, NOT_ENOUGH_MEMORY_RC.  On error, message is
 * displayed.
 *
 */
int VSAPI vsBufLoad(const char *pszFilename,const char *pszOptions=0,bool CreateIfNotFound=true,
                    int *pBLResultFlags=0,int reserved=0,void *preserved=0);
/**
 * Places <i>Len</i> bytes of data starting from the byte offset specified
 * by <i>SeekPos</i> into <i>pszBuf</i>.  The resulting string is always
 * null terminated.  The buffer <i>pszBuf</i> must be large enough to
 * contain <i>Len</i>+1 bytes of data.
 *
 * @return Returns number of bytes copied not including null character.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param Len	Number of characters to copy into
 * <i>pszBuf</i>.
 *
 * @param SeekPos	Specifies the seek position of from which to
 * start copying.  Specify VSNULLSEEK to
 * start copying for the cursor position.
 *
 * @param pszBuf	Output buffer for text. The buffer
 * <i>pszBuf</i> must be large enough to
 * contain <i>Len</i>+1 bytes of data.
 *
 * @see vsInsertLine
 * @see vsReplaceLine
 * @see vsDeleteLine
 * @see vsGetLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsGetText(int wid,int Nofbytes,seSeekPos seekpos,char *pszBuf);
/**
 * Places the current line into <i>pszBuf</i>.  The resulting string is
 * always null terminated.  No more than <i>BufLen</i> bytes are
 * written.  Use the <b>vsQLineLength</b> function to determine the
 * length of the current line.
 *
 * @return Returns number of bytes copied not including null character.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszBuf	Output buffer for current line.
 *
 * @param BufLen	Number of characters allocated to
 * <i>pszBuf</i>.
 *
 * @see vsInsertLine
 * @see vsReplaceLine
 * @see vsDeleteLine
 * @see vsGetText
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsGetLine(int wid,char *pszBuf,int BufLen);
/**
 * This function is identical to the <b>vsGetLine</b> function, except
 * that the output string is in the same format as the internal buffer data
 * which can be SBCS/DBCS or UTF-8.  See "<b>Unicode and
 * SBCS/DBCS C API Programming</b>".
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsGetLineRaw(int wid,char *pszBuf,int BufLen);
/**
 * Deletes the current line.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @return Returns 0 unless last line of buffer is deleted.
 *
 * @see vsInsertLine
 * @see vsReplaceLine
 * @see vsGetLine
 * @see vsGetText
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsDeleteLine(int wid);
/**
 * Inserts line into editor buffer after the current line.
 *
 * @param wid    Window id of editor control.  0 specifies the current object.
 * @param pBuf   Data for new line.  Should not include line separator characters except for binary record files.
 * @param BufLen Number of characters in pBuf.  -1 specifies that pBuf is null terminate and length can be determined from it.
 *
 * @example <pre>
 * vsInsertLine(0,"add line after current line",-1);
 * </pre>
 *
 * @see vsGetLine
 * @see vsReplaceLine
 * @see vsDeleteLine
 * @see vsGetText
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsInsertLine(int wid,const char *pBuf,int BufLen VSDEFAULT(-1));
/**
 * This function is identical to the <b>vsInsertLine</b> function, except
 * that the input string is in the same format as the internal buffer data
 * which can be SBCS/DBCS or UTF-8.  See "<b>Unicode and
 * SBCS/DBCS C API Programming</b>".
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsInsertLineRaw(int wid,const char *pBuf,int BufLen VSDEFAULT(-1));
/**
 * Sets the current line of the current buffer to <i>pBuf</i>.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pBuf	New text for current line.  This should not
 * contain line separator characters.
 *
 * @param BufLen	Number of characters in <i>pBuf</i>. If
 * <i>BufLen</i> is -1, <i>pBuf</i> must be
 * null terminated.
 *
 * @see vsGetLine
 * @see vsInsertLine
 * @see vsDeleteLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsReplaceLine(int wid,const char *pBuf,int BufLen VSDEFAULT(-1));
/**
 * This function is identical to the <b>vsReplaceLine</b> function,
 * except that the input string is in the same format as the internal buffer
 * data which can be SBCS/DBCS or UTF-8.  See "<b>Unicode and
 * SBCS/DBCS C API Programming</b>".
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsReplaceLineRaw(int wid,const char *pBuf,int BufLen VSDEFAULT(-1));
/**
 * @param psz is temporarily displayed on the message line.  Message will
 * disappear after a key is pressed.
 *
 * @see vsStickyMessage
 *
 * @categories Miscellaneous_Functions
 *
 */
void VSAPI vsMessage(const char *psz);
/** 
 * Clears message on the message line. 
 *  
 * @see vsStickyMessage
 * @see vsMessage
 *
 * @categories Miscellaneous_Functions
 *
 */
void VSAPI vsClearMessage();
/**
 * <i>psz</i> is displayed on the message line.
 *
 * @see vsMessage
 *
 * @categories Miscellaneous_Functions
 *
 */
void VSAPI vsStickyMessage(const char *psz);
/**
 * Places cursor at first line and first column of buffer.  <i>wid</i>
 * identifies the object to be operated on.  0 specifies the current object.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @see vsBottom
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsTop(int wid);
/**
 * Places text cursor at end of last line of buffer.  <i>wid</i> identifies
 * the object to be operated on.  0 specifies the current object.
 *
 * @see vsTop
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsBottom(int wid);
/**
 * Moves cursor down the number of lines specified by <i>Noflines</i>.
 * If the destination line is not in view, it is center scrolled or smooth
 * scrolled into view.
 *
 * @return Returns 0 if successful. Otherwise BOTTOM_OF_FILE_RC is
 * returned.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param Noflines	Number of lines to move the cursor down.
 *
 * @example
 * <pre>
 * 	       status=vsDown(0,1);
 * 	       if (status) {
 * 	           // Hit bottom of file
 * 	       }
 * </pre>
 *
 * @see vsUp
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsDown(int wid,seSeekPos Noflines);
/**
 * Moves cursor up the number of lines specified by <i>Noflines</i>.  If
 * the destination line is not in view, it is center scrolled or smooth
 * scrolled into view.  <i>wid</i> identifies the object to be operated on.
 * 0 specifies the current object.
 *
 * @return Returns 0 if successful. Otherwise TOP_OF_FILE_RC is returned.
 *
 * @see vsDown
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsUp(int wid,seSeekPos Noflines);
int VSAPI vsRight(int wid);
int VSAPI vsLeft(int wid);
/**
 * This function has been deprecated.  It has the same effect as calling
 * {@link vsActivateWindow}().
 *
 * @categories Window_Functions
 * @AppliesTo All_Window_Objects
 */
int VSAPI vsActivateView(int view_id);

/**
 * Determines the current window.
 *
 * @appliesTo All_Window_Objects
 * @categories Window_Functions
 * @param window_id   ID of window
 *
 * @return
 * @example
 * <pre>
 *       int window_id;
 *       // Remember the current window id
 *       window_id=vsPropGetI(0,VSP_WINDOWID);
 *       // Switch to hidden window id
 *       vsActivateWindow(VSWID_HIDDEN);
 *       //Switch back to original window
 *       vsActivateWindow(window_id);
 * </pre>
 *
 * @see vsPropGetI
 * @see vsPropSetI
 */
int VSAPI vsActivateWindow(int window_id);

/**
 * @return If VSP_TRUNCATELENGTH is 0, the number of characters in
 * current line not including end of line characters is returned.  Specify a
 * non-zero value for <i>IncludeNLChars</i> if you want to include the
 * end of line characters in the returned length.
 *
 * <p>If VSP_TRUNCATELENGTH is non-zero, the length of the current
 * line as if the text to the right of the truncation length does not exist is
 * returned.  In addition, trailing blanks (tab characters count) are not
 * included in the length.</p>
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param IncludeNLChars	Specify a non-zero value for
 * <i>IncludeNLChars</i> if you want to
 * include the end of line characters in the
 * returned length.  This argument is ignored if
 * the VSP_TRUNCATELENGTH property is
 * non-zero.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsTruncQLineLength(int wid,int *pEntireLineLen VSDEFAULT(0),int reserved VSDEFAULT(0 /*IncludeNLChars*/));
/**
 * @return Returns number of characters in current line not including end of line
 * characters.  Specify a non-zero value for <i>IncludeNLChars</i> if
 * you want to include the end of line characters in the returned length.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param IncludeNLChars	Specify a non-zero value for
 * <i>IncludeNLChars</i> if you want to
 * include the end of line characters in the
 * returned length.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsQLineLength(int wid,int IncludeNLChars);
/**
 * @return Returns a handle to a selection or bookmark.  A selection requires 2
 * marks and a bookmark requires one. If no more marks are available, a
 * negative number (TOO_MANY_SELECTIONS_RC) is returned.  This
 * handle may be passed as a parameter to other selection functions such
 * as <b>vsSelectLine</b> and <b>vsCopyToCursor</b>.  Specify a
 * non-zero value for <i>AllocBookmark</i> to allocate a book mark.
 * Bookmarks can not be deleted.
 *
 * <p>IMPORTANT: The active selection or selection showing may not be
 * freed by the <b>vsFreeSelection</b> function.  Use the
 * <b>vsShowSelection</b> function to make another mark active before
 * freeing the mark you have allocated.</p>
 *
 * @see vsFreeSelection
 *
 * @categories Selection_Functions
 *
 */
int VSAPI vsAllocSelection(int AllocBookmark VSDEFAULT(0));
/**
 * Frees the selection handle or bookmark handle corresponding to
 * <i>mark_id</i>.  <b>_free_selection</b> will not free the active
 * selection (the one that is seen on screen).  <i>mark_id</i> is a handle
 * to a selection returned by <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  A <i>mark_id</i> of -1 is not
 * allowed.  The default selection or selection show
 * (<b>vsShowSelection</b>) can be freed.
 *
 * @param mark_id	Selection id to free.
 *
 * @see vsAllocSelection
 *
 * @categories Selection_Functions
 *
 */
int VSAPI vsFreeSelection(int markid);

/**
 * Clears selection specified.  <i>mark_id</i> is a handle to a selection
 * returned by <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  A <i>mark_id</i> of -1 identifies the
 * active selection.
 *
 * @return Returns 0 if <i>mark_id</i> is a valid selection handle.  Otherwise
 * INVALID_SELECTION_HANDLE_RC is returned.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param mark_id	Selection id to duplicated.   If -1 is specified
 * the active selection.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsDeselect(int wid, int markid VSDEFAULT(-1));
/**
 * Starts or extends the character selection specified.  Used for
 * processing lines of text.  The first <b>vsSelectLine</b> becomes the
 * pivot point.  Subsequent <b>vsSelectLine</b> calls will extend the
 * selection between the pivot point and the cursor.
 *
 * @return Returns 0 if successful.  Possible returns are
 * TEXT_NOT_SELECT_RC.  and
 * TEXT_ALREADY_SELECTED_RC.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  A
 * <i>mark_id</i> of -1 specifies the active
 * selection or selection showing and is always
 * allocated.
 *
 * @param SelectFlags	Zero or more of the following flags Ored
 * together:
 *
 * <dl>
 * <dt>VSSELECT_BEGINEND</dt><dd>
 * 	Specifies that selecting an area of text requires
 * <b>_select_char</b> be executed to select the end
 * of the text area as well as the beginning.  If
 * VSSELECT_CURSOREXTENDS is not specified,
 * this select style is used.</dd>
 *
 * <dt>VSSELECT_CURSOREXTENDS</dt><dd>
 * 	Specifies that the selection extend as the cursor
 * moves.</dd>
 *
 * <dt>VSSELECT_INCLUSIVE</dt><dd>
 * 	Specifies an inclusive selection.  Currently only
 * character selections are affected by this option.</dd>
 *
 * <dt>VSSELECT_NONINCLUSIVE</dt><dd>
 * 	Specifies a non-inclusive selection.  Currently only
 * character selections are affected by this option.  If
 * the 'I' letter is not specified, the character selection
 * will be non-inclusive selection.</dd>
 *
 * <dt>VSSELECT_PERSISTENT</dt><dd>
 * 	A value of 'P' specifies a persistent select style and
 * may be specified in addition to the other options
 * above.  Macros use this to help determine if a
 * selection should be unhighlighted when the cursor
 * moves.</dd>
 *
 * @see vsSelectChar
 * @see vsSelectLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsSelectLine(int wid,int markid VSDEFAULT(-1),int SelectFlags VSDEFAULT(0));
/**
 * Starts or extends the character selection specified.  Used for
 * processing sentences of text which do not start and end on line
 * boundaries.  The first <b>vsSelectChar</b> becomes the pivot point.
 * Subsequent <b>vsSelectChar</b> calls will extend the selection
 * between the pivot point and the cursor.
 *
 * @return Returns 0 if successful.  Possible returns are
 * TEXT_NOT_SELECT_RC.  and
 * TEXT_ALREADY_SELECTED_RC.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  A
 * <i>mark_id</i> of -1 specifies the active
 * selection or selection showing and is always
 * allocated.
 *
 * @param SelectFlags	Zero or more of the following flags Ored
 * together:
 *
 * <dl>
 * <dt>VSSELECT_BEGINEND</dt><dd>
 * 	Specifies that selecting an area of text requires
 * <b>_select_char</b> be executed to select the end
 * of the text area as well as the beginning.  If
 * VSSELECT_CURSOREXTENDS is not specified,
 * this select style is used.</dd>
 *
 * <dt>VSSELECT_CURSOREXTENDS</dt><dd>
 * 	Specifies that the selection extend as the cursor
 * moves.</dd>
 *
 * <dt>VSSELECT_INCLUSIVE</dt><dd>
 * 	Specifies an inclusive selection.  Currently only
 * character selections are affected by this option.</dd>
 *
 * <dt>VSSELECT_NONINCLUSIVE</dt><dd>
 * 	Specifies a non-inclusive selection.  Currently only
 * character selections are affected by this option.  If
 * the 'I' letter is not specified, the character selection
 * will be non-inclusive selection.</dd>
 *
 * <dt>VSSELECT_PERSISTENT</dt><dd>
 * 	A value of 'P' specifies a persistent select style and
 * may be specified in addition to the other options
 * above.  Macros use this to help determine if a
 * selection should be unhighlighted when the cursor
 * moves.</dd>
 *
 * @see vsSelectBlock
 * @see vsSelectLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsSelectChar(int wid,int markid VSDEFAULT(-1),int SelectFlags VSDEFAULT(0));
/**
 * Starts or extends the block selection specified.  Used for processing
 * columns of text.  The first <b>vsSelectBlock</b> becomes the pivot
 * point.  Subsequent <b>vsSelectBlock</b> calls will extend the
 * selection between the pivot point and the cursor.
 *
 * @return Returns 0 if successful.  Possible returns are
 * TEXT_NOT_SELECT_RC.  and
 * TEXT_ALREADY_SELECTED_RC.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  A
 * <i>mark_id</i> of -1 specifies the active
 * selection or selection showing and is always
 * allocated.
 *
 * @param SelectFlags	Zero or more of the following flags Ored
 * together:
 *
 * <dl>
 * <dt>VSSELECT_BEGINEND</dt><dd>
 * 	Specifies that selecting an area of text requires
 * <b>_select_char</b> be executed to select the end
 * of the text area as well as the beginning.  If
 * VSSELECT_CURSOREXTENDS is not specified,
 * this select style is used.</dd>
 *
 * <dt>VSSELECT_CURSOREXTENDS</dt><dd>
 * 	Specifies that the selection extend as the cursor
 * moves.</dd>
 *
 * <dt>VSSELECT_INCLUSIVE</dt><dd>
 * 	Specifies an inclusive selection.  Currently only
 * character selections are affected by this option.</dd>
 *
 * <dt>VSSELECT_NONINCLUSIVE</dt><dd>
 * 	Specifies a non-inclusive selection.  Currently only
 * character selections are affected by this option.  If
 * the 'I' letter is not specified, the character selection
 * will be non-inclusive selection.</dd>
 *
 * <dt>VSSELECT_PERSISTENT</dt><dd>
 * 	A value of 'P' specifies a persistent select style and
 * may be specified in addition to the other options
 * above.  Macros use this to help determine if a
 * selection should be unhighlighted when the cursor
 * moves.</dd>
 * </dl>
 *
 * @see vsSelectChar
 * @see vsSelectLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsSelectBlock(int wid,int markid VSDEFAULT(-1),int SelectFlags VSDEFAULT(0));
/**
 * Copies the selection specified by <i>mark_id</i> to cursor.  Character
 * or block selections are inserted before the character at the cursor.  Line
 * selections are always inserted after the current line.  Resulting
 * selection is always on destination text.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by the <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b> function.  A
 * <i>mark_id</i> of -1 specifies the active
 * selection or selection showing and is always
 * allocated.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
void VSAPI vsCopyToCursor(int wid,int markid VSDEFAULT(-1),int MustBeMinusOne VSDEFAULT(-1));

/**
 * Temporarily suspends undo 
 *  
 * <p>This function is used in conjuction with vsResumeUndo in 
 * order to perform temporary buffer modifications so that undo 
 * steps are not recorded for the temporary buffer 
 * modifications. As long as the buffer is 
 * restored to it's original state before vsSuspendUndo is 
 * called, no issues with undo will occur. 
 *  
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 * 
 * @return 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
int VSAPI vsSuspendUndo(int wid);
/**
 * Resumes undo suspend by vsSuspendUndo. 
 *  
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 * @param maxundos
 * @see vsResumeUndo
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
void VSAPI vsResumeUndo(int wid,int maxundos);
/**
 * Runs the command specified.  <i>pszCommand</i> can be any
 * command that can be invoked from the SlickEdit command
 * line.  Command may be an internal command (<b>_command</b>),
 * an external operating system command, or an external Slick-C&reg; batch
 * macro (with <b>defmain</b> entry point).    If no arguments are
 * given, the command line is erased and the command is inserted into
 * the command retrieve buffer.  <i>wid</i> identifies the object to be
 * operated on.  0 specifies the current object.
 *
 * @return Return value of command executed is returned.
 *
 * @param pszOptions is a string of one or more of the following letters:
 *
 * <dl>
 * <dt>W</dt><dd>If command is an external program, run
 * <b>slkwait</b> program to wait for program to
 * complete.   This option allows you to view the
 * results after running a DOS text mode application
 * which displays results to the screen.  Defaults to
 * OFF.</dd>
 *
 * <dt>A</dt><dd>If command is an external program, run program
 * asynchronously (no wait).  Defaults to OFF.</dd>
 *
 * <dt>R</dt><dd>Insert command into command retrieve buffer
 * (.command) and clear command line.  Defaults to
 * OFF unless pszCommand is NULL.</dd>
 *
 * <dt>Z</dt><dd>Return pointer to ASCIIZ instead of long.
 * BEWARE:  This is a pointer to the "rc" global
 * variable which will change if vsExecute is called
 * again or if you or another macro sets the "rc"
 * variable.  Make a copy of the string if necessary.</dd>
 *
 * <dt>L</dt><dd>Return pointer to VSLSTR instead of long.
 * BEWARE:  This is a pointer to the "rc" global
 * variable which will change if vsExecute is called
 * again or if you or another macro sets the "rc"
 * variable.  Make a copy of the string if necessary.</dd>
 *
 * <dt>S</dt><dd>Start new undo step.</dd>
 *
 * <dt>M</dt><dd>Record source if macro recording.</dd>
 *
 * <dt>D</dt><dd>Do refresh.  Refresh the screen after executing the
 * command.</dd>
 * </dl>
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Miscellaneous_Functions
 *
 */
long VSAPI vsExecute(int wid,const char *pszCommand,const char *pszOptions VSDEFAULT("SMDA"));


#define VSFONTLISTFLAG_SCREEN_FONTS  0x1
#define VSFONTLISTFLAG_PRINTER_FONTS 0x2
#define VSFONTLISTFLAG_FIXED_ONLY    0x4
#define VSFONTLISTFLAG_OUPUT_WIDTHxHEIGHT   0x8
#define VSFONTLISTFLAG_OUTPUT_CHARSET  0x10

/**
 * @return Returns 0 if successful.
 *
 * @param pfnCallback	Function called for each font name or font
 * size found.
 *
 * @param flags	One or more of the VSFONTLISTFLAG
 * _??? flags ORed together.
 *
 * <dl>
 * <dt>VSFONTLISTFLAG_SCREEN_FONTS</dt><dd>List screen fonts.</dd>
 * <dt>VSFONTLISTFLAG_PRINTER_FONTS</dt><dd>
 * 	List printer fonts</dd>
 * <dt>VSFONTLISTFLAG_FIXED_ONLY</dt><dd>List fixed fonts only.</dd>
 * <dt>VSFONTLISTFLAG_OUPUT_WIDTHxHEIGHT</dt><dd>
 * 	Windows only:  When
 * listing font sizes,
 * 	list fonts in
 * format
 * <i>www</i>x<i>hhh</i
 * >. where <i>www</i> is
 * the pixel width and
 * <i>hhh</i> is the pixel
 * height.</dd>
 * </dl>
 *
 * @param pszFontName	Name of font to list sizes for.  Specify 0 to
 * list available font names.
 *
 * @see vsFontIsScalable
 * @see vsFontList
 * @see vsFontQType
 * @see vsFontQDefaultCharSet
 *
 * @categories Font_Functions
 *
 */
int VSAPI vsFontList(void (VSAPI *pfnCallback)(const char *psz),int flags VSDEFAULT(VSFONTLISTFLAG_SCREEN_FONTS),const char *pszFontName VSDEFAULT(0));
/**
 * @return Returns non-zero value if the font is scalable.  You should not list font
 * sizes for fonts which are scalable since all sizes are supported.
 *
 * @param flags	One or more of the
 * VSFONTLISTFLAG_??? flags ORed
 * together.
 *
 * <dl>
 * <dt>VSFONTLISTFLAG_SCREEN_FONTS</dt><dd>Test screen font.</dd>
 * <dt>VSFONTLISTFLAG_PRINTER_FONTS</dt><dd>
 * 	Test printer font.</dd>
 * </dl>
 *
 * @param pszFontName	Name of font to list sizes for.  Specify 0 to
 * list available font names.
 *
 * @see vsFontIsScalable
 * @see vsFontList
 * @see vsFontQType
 * @see vsFontQDefaultCharSet
 *
 * @categories Font_Functions
 *
 */
int VSAPI vsFontIsScalable(int flags,const char *pszFontName,void *reserved VSDEFAULT(0));
#define VSFONTTYPE_RASTER    0x001
#define VSFONTTYPE_DEVICE    0x002
#define VSFONTTYPE_TRUETYPE  0x004   // Windows only
#define VSFONTTYPE_FIXED     0x008   // Fixed pitch font
#define VSFONTTYPE_OUTLINE   0x100
#define VSFONTTYPE_KERNING   0x200   // OS/2 only
/**
 * @return Returns flags of information about this font.
 *
 * <dl>
 * <dt>VSFONTTYPE_RASTER</dt><dd>Windows only.  Raster font.</dd>
 * <dt>VSFONTTYPE_DEVICE</dt><dd>Windows only.  Device font.</dd>
 * <dt>VSFONTTYPE_TRUETYPE</dt><dd>Windows only. True Type font.</dd>
 * <dt>VSFONTTYPE_FIXED</dt><dd>Fixed pitch font.</dd>
 * <dt>VSFONTTYPE_OUTLINE</dt><dd>Outline font.</dd>
 * <dt>VSFONTTYPE_KERNING</dt><dd>No longer used.</dd>
 * </dl>
 *
 * @param flags	One or more of the
 * VSFONTLISTFLAG_??? flags ORed
 * together.
 *
 * <dl>
 * <dt>VSFONTLISTFLAG_SCREEN_FONTS</dt><dd>Test screen font.</dd>
 * <dt>VSFONTLISTFLAG_PRINTER_FONTS</dt><dd>
 * 	Test printer font.</dd>
 * </dl>
 *
 * @param pszFontName	Name of font to list sizes for.  Specify 0 to
 * list available font names.
 *
 * @see vsFontIsScalable
 * @see vsFontList
 * @see vsFontQType
 * @see vsFontQDefaultCharSet
 *
 * @categories Font_Functions
 *
 */
int VSAPI vsFontQType(int flags,const char *pszFontName,void *reserved VSDEFAULT(0));
/**
 * @return Windows only:  Returns Windows character set.
 *
 * @param flags	One or more of the
 * VSFONTLISTFLAG_??? flags ORed
 * together.
 *
 * <dl>
 * <dt>VSFONTLISTFLAG_SCREEN_FONTS</dt><dd>Test screen font.</dd>
 * <dt>VSFONTLISTFLAG_PRINTER_FONTS</dt><dd>
 * 	Test printer font.</dd>
 * </dl>
 *
 * @param pszFontName	Name of font to list sizes for.  Specify 0 to
 * list available font names.
 *
 * @param pszFontSize	Font size.
 *
 * @see vsFontIsScalable
 * @see vsFontList
 * @see vsFontQType
 * @see vsFontQDefaultCharSet
 *
 * @categories Font_Functions
 *
 */
int VSAPI vsFontQDefaultCharSet(int flags,const char *pszFontName,const char *pszFontSize);

/**
 * Retrieve actual font name and metrics being used by an editor control window.
 * This can be different from what the window properties report (e.g. VSP_FONTNAME,
 * VSP_FONTWIDTH, etc.) because the operating system will often map a font
 * differently when it is used.
 *
 * @param wid         Editor control window id.
 * @param pszFontName (output). Actual font name used to draw text.
 * @param nFontName   Size of font name buffer.
 * @param pFontWidth  (output). Font width in pixels.
 * @param pFontHeight (output). Font height in pixels. This is significant when
 *                    a WidthxHeight font is chosen (e.g. "Terminal 8x12" on Windows).
 * @param pCharSet    (output). Character set. Windows only.
 *
 * @return 0 on success.
 */
int vsGetWindowFontInfo(int wid, char* pszFontName, int nFontName,
                        int* pFontWidth, int* pFontHeight, int* pCharSet);

/**
 * @return This function returns non-zero pending key or mouse event.  If there is
 * no pending event, 0 is returned..  See our OEM MDI sample program
 * for sample code which translates windows messages into our event
 * constants.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszOptions	A string of zero or more of the following
 * options:
 *
 * <dl>
 * <dt>'R'</dt><dd>Specifies no screen refresh.</dd>
 * <dt>'K'</dt><dd>Return keys from physical keyboard and not
 * keyboard macro that is being played back.</dd>
 * <dt>'P'</dt><dd>UNIX only: Process non-key/mouse events first
 * before testing for a key or mouse event.  This
 * option is ignored for non-UNIX platforms.</dd>
 * <dt>'M'</dt><dd>When given, only key events are tested.</dd>
 * </dl>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Keyboard_Functions
 *
 * @deprecated Use {@link vsIsEventPending}
 */
int VSAPI vsTestEvent(int wid VSDEFAULT(0),char *pszOptions VSDEFAULT(0));

enum vsEventPendingFlags {
   // Check for key events
   VSEVENTPENDING_KEY         = 0x1,
   // Check for mouse events
   VSEVENTPENDING_MOUSE       = 0x2,
   // Check for mouse-move event
   VSEVENTPENDING_MOUSE_MOVE  = 0x4,
   // Check for key events from recorded macro playback
   VSEVENTPENDING_MACRO       = 0x8
};

/**
 * Test if a key, mouse, or mouse-move event is available.
 *
 * @param flags  Bit-wise flags of vsEventPendingFlags. Defaults
 *               to 0.
 *
 * @return 1 (true) if event is available, otherwise 0 (false).
 *
 * @categories Keyboard_Functions
 */
int VSAPI vsIsEventPending(int flags VSDEFAULT(0));

// Some new exported VSAPI calls in 4.0

char **VSAPI vsTagListTagFiles(int reserved VSDEFAULT(0),char *pszExt VSDEFAULT(0),int includeSlickC VSDEFAULT(1));
void VSAPI vsTagSetExtTagFiles(const char *pszExt,char **ppList,int append VSDEFAULT(0));

#define VSCFGMODIFY_ALLCFGFILES  0x001 // For backward compatibility.
                              // New macros should use the constants below.
#define VSCFGMODIFY_DEFVAR    0x002  // Set macro variable with prefix "def_"
#define VSCFGMODIFY_DEFDATA   0x004  // Set symbol with prefix "def_"
#define VSCFGMODIFY_OPTION    0x008  // color, scroll style, insert state or
                                     // any option which the list_config
                                     // command generates source for.
#define VSCFGMODIFY_RESOURCE     0x010  // FORM, BITMAP, MENU, BUTTON BAR, TOOL BAR
#define VSCFGMODIFY_SYSRESOURCE  0x020  // FORM, BITMAP, MENU, BUTTON BAR, TOOL BAR
#define VSCFGMODIFY_LOADMACRO  0x040  // vusermacs is screened out of this.
                                      // Must write state file if user load
#define VSCFGMODIFY_LOADDLL    0x080  // Must write state file if user loads
                                      // a DLL.
#define VSCFGMODIFY_KEYS       0x100  // Modify keys
#define VSCFGMODIFY_USERMACS   0x200  // vusrmacs was loaded.
#define VSCFGMODIFY_MUSTSAVESTATE  (VSCFGMODIFY_LOADMACRO|VSCFGMODIFY_LOADDLL)
#define VSCFGMODIFY_DELRESOURCE  0x400 // Sometimes must write state file
                                       // when resource is deleted.
                                       // This should be used with
                                       // VSCFGMODIFY_RESOURCE or
                                       // VSCFGMODIFY_SYSRESOURCE
void VSAPI vsSetConfigModify(int addFlags);
/**
 * When the <B>VSP_TRUNCATELENGTH</B> is non-zero, replace
 * operations are skipped if the resulting line becomes longer than the
 * truncation length.  This function is used in conjunction with
 * <b>vsSearchQNofSkipped</b> and <b>vsSearchQSkipped</b> to
 * return information about what was skipped.  Call this function before
 * performing a search and replace operation to reset NofSkipped and
 * Skipped lines data returned by the <b>vsSearchQNofSkipped</b> and
 * <b>vsSearchQSkipped</b> functions.
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
void VSAPI vsSearchInitSkipped(int reserved VSDEFAULT(0));
/**
 * When the <B>VSP_TRUNCATELENGTH</B> is non-zero, replace
 * operations are skipped if the resulting line becomes longer than the
 * truncation length.  The <b>vsSearchInitSkipped</b> function is used
 * in conjunction with <b>vsSearchQNofSkipped</b> and
 * <b>vsSearchQSkipped</b> to return information about what was
 * skipped.  Call this function before performing a search and replace
 * operation to reset NofSkipped and Skipped lines data returned by the
 * <b>vsSearchQNofSkipped</b> and <b>vsSearchQSkipped</b>
 * functions.
 *
 * @return Returns a space delimited list of line numbers where the replace
 * operation that was skipped.
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
const char * VSAPI vsSearchQSkipped();
/**
 * When the <B>VSP_TRUNCATELENGTH</B> is non-zero, replace
 * operations are skipped if the resulting line becomes longer than the
 * truncation length.  The <b>vsSearchInitSkipped</b> function is used
 * in conjunction with <b>vsSearchQNofSkipped</b> and
 * <b>vsSearchQSkipped</b> to return information about what was
 * skipped.  Call this function before performing a search and replace
 * operation to reset NofSkipped and Skipped lines data returned by the
 * <b>vsSearchQNofSkipped</b> and <b>vsSearchQSkipped</b>
 * functions.
 *
 * @return Returns the number of replace operations that were skipped.
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
int VSAPI vsSearchQNofSkipped();
/**
 * @return Returns 0 if there are no lines longer than the <i>AllowedLineLen</i>
 * specified. At the moment only the physical line length is checked as if
 * tab characters count as 1 character.  We may change this in the future.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param AllowedLineLen	Lines lengths greater than this length are
 * flagged.
 *
 * @param pszLineNumbers	(Ouput only) ASCIIZ string.   Set to a space
 * delimited list of line numbers of lines which
 * are too long.  Lines with the
 * VSLF_NOSAVE flag set are ignored.
 *
 * @param MaxLineNumebersLen	Number of characters allocated to
 * <i>pszLineNumebers</i>.
 *
 * @param FromCursor	Set this to zero to check lines at and after the
 * cursor.  Otherwise, the entire buffer is
 * checked.
 *
 * @param pMaxLineLen	(Output only) Set to the length of the longest
 * line.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsCheckLineLengths(int wid,int AllowedLineLen,char *pszLineNumbers VSDEFAULT(0),int MaxLineNumbersLen VSDEFAULT(0),int FromCursor VSDEFAULT(0),int *pMaxLineLen VSDEFAULT(0),int CountTrailingBlanks VSDEFAULT(0),int reserved2 VSDEFAULT(0));
/**
 * @return Returns the value of the global Slick-C&reg; variable name given.  If the
 * variable is not found, <i>DefaultValue</i> is returned.
 *
 * @param pszVarName	Global Slick-C&reg; variable name.
 *
 * @param DefaultValue	Value returned if variable is not found in
 * names table.
 *
 * @categories Names_Table_Functions
 *
 */
int VSAPI vsQIntVar(VSPSZ pszVarName,int DefaultValue);
int VSAPI vsMDIReorder(int wid,int NextWid,int after VSDEFAULT(0));

/**
 * @return Returns true if a menu item which executes the <b>vcadd</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvcadd_enabled(int editorctl_wid);
/**
 * @return Returns true if a menu item which executes the <b>vccheckin</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvccheckin_enabled(int editorctl_wid);
/**
 * @return Returns true if a menu item which executes the <b>vccheckout</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvccheckout_enabled(int editorctl_wid);
/**
 * @return Returns true if a menu item which executes the <b>vcdiff</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvcdiff_enabled(int editorctl_wid);
/**
 * @return Returns true if a menu item which executes the <b>vcget</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvcget_enabled(int editorctl_wid);
/**
 * @return Returns true if a menu item which executes the <b>vchistory</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvchistory_enabled(int editorctl_wid);
/**
 * @return Returns true if a menu item which executes the <b>vclock</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvclock_enabled(int editorctl_wid);
/**
 * @return Returns true if a menu item which executes the <b>vcmanager</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvcmanager_enabled(int editorctl_wid);
/**
 * @return Returns true if a menu item which executes the <b>vcproperties</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvcproperties_enabled(int editorctl_wid);
/**
 * @return Returns true if a menu item which executes the <b>vcremove</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvcremove_enabled(int editorctl_wid);
/**
 * @return Returns true if a menu item which executes the <b>vcunlock</b>
 * command should be enabled.
 *
 * @categories Version_Control_Functions
 *
 */
int VSAPI vsQvcunlock_enabled(int editorctl_wid);

#define VSTBREFRESHBY_READ_ONLY                  1
#define VSTBREFRESHBY_UNDO                       2
#define VSTBREFRESHBY_REDO                       3
#define VSTBREFRESHBY_SELECTION                  4
#define VSTBREFRESHBY_CREATEDESTROY_MDICHILD     5
#define VSTBREFRESHBY_MDICHILD_WINDOW_STATE      6
#define VSTBREFRESHBY_ADDREMOVE_BOOKMARK         7
#define VSTBREFRESHBY_STARTSTOP_MACRO_RECORDING  8

#define VSTBREFRESHBY_PROJECT                    9
#define VSTBREFRESHBY_INTERNAL_CLIPBOARDS        10
#define VSTBREFRESHBY_SWITCHBUF                  11
#define VSTBREFRESHBY_APPLICATION_GOT_FOCUS      12
#define VSTBREFRESHBY_DEBUGGING                  13

// Start your own values here or just use this one
#define VSTBREFRESHBY_USER                       1000

int VSAPI vstbQRefreshBy();
void VSAPI vstbSetRefreshBy(int tbRefreshBy);

/*
   Specify the VSBMFLAG_SHOWTOOLTIP flag if you want the bookmark
   name displayed at the left edge of the edit window.  Note
   that the user can select not to show any bookmark names
   on the left edge.
*/
#define VSBMFLAG_SHOWTOOLTIP  0x1

/*
   VSBMFLAG_STANDARD has the following effects:
     * bookmark is diplayed in bookmark list
     * next_bookmark and prev_bookmark will traverse this bookmark.
*/
#define VSBMFLAG_STANDARD     0x2

/*
   This flag is used by the push_bookmark command.  PUSHED bookmarks
   are mainly useful for tagging where the bookmarks are very temporary.
   By convention, PUSHED bookmarks do not appear on the left edge
   or in the bookmarks dialog and are ignored by all commands excepted
   the pop_bookmark command.  Do not specify the VSBMFLAG_SHOWNAME,
   VSBMFLAG_STANDARD, or VSBMFLAG_SHOWPIC flags when using this flag.

   In case you were wondering, tag boookmarks are named to simplify
   save and restoring bookmarks.
*/
#define VSBMFLAG_PUSHED       0x4

/*
   Specify the VSBMFLAG_SHOWPIC if you want the bookmark
   bitmap displayed at the left edge of the edit window.
*/
#define VSBMFLAG_SHOWPIC      0x8

/*
   Specify the VSBMFLAG_SHOWNAME if you want the bookmark
   name and bitmap displayed at the left edge of the edit window.
   Note that the user can select not to show any bookmark names
   on the left edge.

   Deprecated. VSBMFLAG_SHOWTOOLTIP and VSBMFLAG_SHOWPIC replace it.
*/
#define VSBMFLAG_SHOWNAME     (VSBMFLAG_SHOWTOOLTIP|VSBMFLAG_SHOWPIC)

/*
    This flag is used to indicate that a bookmark represents an
    annotation.  Annotations are treated like regular bookmarks,
    but they can also have a verbose description and a hash table
    of attributes.
*/
#define VSBMFLAG_ANNOTATION   0x10

/**
 * Restores inactive bookmarks for the file specified by <i>wid</i>.
 * This function is typically called when a new file is loaded, so that
 * inactive bookmarks may be restored.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param vsbmflags	One or more of these flags must be in the
 * bookmark for the bookmark to be restored.
 *
 * @see vsBookmarkAdd
 * @see vsBookmarkRemove
 * @see vsBookmarkRestore
 * @see vsBookmarkGetInfo
 * @see vsBookmarkFind
 * @see vsBookmarkQCount
 *
 * @categories Bookmark_Functions
 *
 */
void VSAPI vsBookmarkRestore(int wid,int vsbmflags VSDEFAULT(-1));
/**
 * Deletes a bookmark.
 *
 * @param i Index of bookmark where
 * 0&lt;=i&lt;vsBookmarkQCount().
 *
 * @param free_markid	When non-zero, <b>vsFreeSelection</b> is
 * called for the markid belonging to this
 * bookmark.
 *
 * @see vsBookmarkAdd
 * @see vsBookmarkRemove
 * @see vsBookmarkRestore
 * @see vsBookmarkGetInfo
 * @see vsBookmarkFind
 * @see vsBookmarkQCount
 *
 * @categories Bookmark_Functions
 *
 */
void VSAPI vsBookmarkRemove(int i,int free_markid VSDEFAULT(1));
/**
 * Adds a new bookmark.
 *
 * @param pszBookmarkName	Name of bookmark to add.
 *
 * @param markid   Selection id returned from
 * <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.
 *
 * @param vsbmflags	Combination of VSBMFLAGS_??? ORed
 * together.
 *
 * @param RealLineNumber	Real line number of bookmark.  Specify -1 if
 * <i>markid</i> is an active bookmark.
 *
 * @param col	Column of bookmark.  Specify 0 if
 * <i>markid</i> is an active bookmark.
 *
 * @param BeginLineROffset	Real offset to beginning of line.
 * Imaginary line data not counted.  Specify 0
 * if <i>markid</i> is an active bookmark.
 *
 * @param pszLineData	Text on the line of the bookmark.  Specify 0
 * if <i>markid</i> is an active bookmark.
 *
 * @param pszFilename	Filename the bookmark is in.  Specify 0 if
 * <i>markid</i> is an active bookmark.
 *
 * @param pszDocumentName	Document name the bookmark is in.
 * Specify 0 if <i>markid</i> is an active
 * bookmark.
 *
 * @see vsBookmarkAdd
 * @see vsBookmarkRemove
 * @see vsBookmarkRestore
 * @see vsBookmarkGetInfo
 * @see vsBookmarkFind
 * @see vsBookmarkQCount
 *
 * @categories Bookmark_Functions
 *
 */
int VSAPI vsBookmarkAdd(const char *pszBookmarkName,
                         int markid,
                         int vsbmflags VSDEFAULT(VSBMFLAG_SHOWTOOLTIP|VSBMFLAG_STANDARD|VSBMFLAG_SHOWPIC),
                         seSeekPos RealLineNumber =seSeekPos(-1),
                         int col VSDEFAULT(0),
                         seSeekPos BeginLineROffset =seSeekPos(0),
                         char *pszLineData VSDEFAULT(0),
                         char *pszFilename VSDEFAULT(0),
                         char *pszDocumentName VSDEFAULT(0)
                         );
/**
 * Retrieves information for a bookmark.
 *
 * @return Returns 0 or TEXT_NOT_SELECTED_RC if successful.
 * TEXT_NOT_SELECT_RC indicates that the bookmark is not active.
 * This occurs when a buffer with bookmarks is closed.
 *
 * @param i	Bookmark index where
 * 0&lt;=i<<b>vsBookmarkQCount</b>().
 *
 * @param pszBookmarkName	Set to name of bookmark.  Must
 * have VSMAXBOOKMARKNAME chacters
 * allocated. Specify NULL if you don't need
 * this value.
 *
 * @param pmarkid	Set to selection id previous given to
 * vsBookmarkAdd.  Specify NULL if you
 * don't need this value.
 *
 * @param pvsbmflags	Set to combination of VSBMFLAGS_???
 * ORed together. Specify NULL if you don't
 * need this value.
 *
 * @param pbuf_id	Set to buffer id of bookmark. Specify NULL
 * if you don't need this value.
 *
 * @param pRealLineNumber	Set to real line number of bookmark.
 * Specify NULL if you don't need this value.
 *
 * @param pcol	Set to column of bookmark. Specify NULL
 * if you don't need this value.
 *
 * @param pBeginLineROffset	Set to real offset to beginning of
 * line.  Imaginary line data not counted.
 * Specify NULL if you don't need this value.
 *
 * @param pszLineData	Set to text on the line of the bookmark.
 * Must have
 * VSMAXBOOKMARKLINEDATA
 * allocated. Specify NULL if you don't need
 * this value.
 *
 * @param pszFilename	Set to filename the bookmark is in.  Must
 * have VSMAXFILENAME allocated.
 * Specify NULL if you don't need this value.
 *
 * @param pszDocumentName	Set to document name the bookmark
 * is in.  Must have
 * VSMAXDOCUMENTNAME allocated.
 * Specify NULL if you don't need this value.
 *
 * @see vsBookmarkAdd
 * @see vsBookmarkRemove
 * @see vsBookmarkRestore
 * @see vsBookmarkGetInfo
 * @see vsBookmarkFind
 * @see vsBookmarkQCount
 *
 * @categories Bookmark_Functions
 *
 */
int VSAPI vsBookmarkGetInfo(int i,
                            char *pszBookmarkName VSDEFAULT(0),   // VSMAXBOOKMARKNAME
                            int *pmarkid VSDEFAULT(0),
                            int *pvsbmflags VSDEFAULT(0),
                            int *pbuf_id VSDEFAULT(0),
                            int determineLineNumber VSDEFAULT(1),
                            seSeekPos *pRealLineNumber VSDEFAULT(0),
                            int *pCol VSDEFAULT(0),
                            seSeekPos *pBeginLineROffset VSDEFAULT(0),
                            char *pszLineData VSDEFAULT(0),   //VSMAXBOOKMARKLINEDATA
                            char *pszFilename VSDEFAULT(0),     //VSMAXFILENAME
                            char *pszDocumentName VSDEFAULT(0) //VSMAXDOCUMENTNAME
                            );
/**
 * Finds bookmark index.
 *
 * @return Returns index of boomark 0..vsBookmarkQCount() or -1 to indicate
 * the bookmark was not found.
 *
 * @param pszBookmarkName	Name of bookmark to find.
 * <i>vsbmflags</i>	One or more of these flags must be in the
 * bookmark found.
 *
 * @see vsBookmarkAdd
 * @see vsBookmarkRemove
 * @see vsBookmarkRestore
 * @see vsBookmarkGetInfo
 * @see vsBookmarkFind
 * @see vsBookmarkQCount
 *
 * @categories Bookmark_Functions
 *
 */
int VSAPI vsBookmarkFind(const char *pszBookmarkName,int vsbmflags VSDEFAULT(VSBMFLAG_STANDARD));
/**
 * @return Returns the number of bookmarks.
 *
 * @see vsBookmarkAdd
 * @see vsBookmarkRemove
 * @see vsBookmarkRestore
 * @see vsBookmarkGetInfo
 * @see vsBookmarkFind
 * @see vsBookmarkQCount
 *
 * @categories Bookmark_Functions
 *
 */
int VSAPI vsBookmarkQCount();

/**
 * @return Returns 0 if editing is allowed for this buffer.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @see p_readonly_set_by_user
 * @see p_ReadOnly
 * @see p_readonly_mode
 * @see p_ProtectReadOnlyMode
 * @see vsQReadOnly
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int vsQReadOnly(int wid);
void VSAPI vsPostCall(int index,char *pBuf,int BufLen VSDEFAULT(-1));
int VSAPI vsUndo(int wid, char option /* URSC*/);
/**
 *
 * Warning: You will need to call vsRefresh() to get the cursor
 * to update if it is not already being automatically called.
 * @param wid
 * @param onoff
 *  <dl compact>
 *  <dt>0</dt><dd>Automatic. Restore cursor to either visible or
 *  not visible depending on whether the editor control has
 *  focus</dd>
 *  <dt>1</dt><dd>Show cursor with no blinking. Displays
 *  non-blinking cursor at current cursor possition even if
 *  editor control does not have focus</dd>
 *  <dt>2</dt><dd>Hides cursor even if editor control has
 *  focus</dd>
 *  </dl>
 */
void VSAPI vsShowCursor(int wid,int onoff);
// Some new exported VSAPI calls in 3.0

/**
 * Turns off the VSLF_INSERTED_LINE and VSLF_MODIFY flags for
 * all lines in the specified editor control.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @see vsQLineFlags
 * @see vsSetLineFlags
 * @see vsResetModifiedLineFlags
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsResetModifiedLineFlags(int wid,int Reserved VSDEFAULT(0));
/**
 * Terminates the current application and returns the exit code given.
 *
 * @param ExitCode</i>	Exit code to return to operating system.
 *
 * @categories Miscellaneous_Functions
 *
 */
void VSAPI vsExit(int status);
void VSAPI vsMiniHTMLSetDefaultFixedFont(const char *pszFontName,int charset);
void VSAPI vsMiniHTMLSetDefaultFixedFontSize(int size /* 0..7 */,int PointSizeX10);
void VSAPI vsMiniHTMLSetDefaultProportionalFont(const char *pszFontName,int charset);
void VSAPI vsMiniHTMLSetDefaultProportionalFontSize(int size /* 0..7 */,int PointSizeX10);
//char * VSAPI vsMiniHTMLQFixedFont();
//int VSAPI vsMiniHTMLQFixedFontSize(int size /* 0..7 */);
//char * VSAPI vsMiniHTMLQProportionalFont();
//int VSAPI vsMiniHTMLQProportionalFontSize(int size /* 0..7 */);

/**
 * Copies corrensponding message into <i>pszMessage</i>.  Set to
 * "Message not available" for a non-existant error code.
 *
 * @return Returns <i>pszMessage</i>.
 *
 * @param rc	Error code.  One of ???_RC constants
 * defined in "rc.h".
 *
 * @param pszMessage	Output buffer for message.  This can be 0.
 * We recommend VSMAXMESSAGE.
 *
 * @param MaxMessageLen	Number of characters allocated to
 * <i>pszMessage</i>.  We recommend
 * VSMAXMESSAGE.
 *
 * @param pMaxMessageLen	If this is not 0, this is set to the
 * number of characters you need to allocate to
 * <i>pszMessage</i>.
 *
 * @see vsMessage
 * @see vsGetMessageLine
 *
 * @categories Miscellaneous_Functions
 *
 */
char *VSAPI vsGetMessage(int rc,char *pszMessage,int MaxMsgLen,int *pMaxMsgLen VSDEFAULT(0));
char * VSAPI vsGetMessage2(int errorcode);
void VSAPI vsMessageSetParamB(int index,const char *pBuf,int BufLen);
void VSAPI vsMessageSetParamZ(int index,const char *psz);
void VSAPI vsMessageSetParamI(int index,int i);
void VSAPI vsMessageSetVersion(int rc,const char *pszMessage);
void VSAPI vsMessageInitAutoUpdate(const char *pszPath,const char *pszMsgFilename,
                   const char *pszBinaryMsgFilename,
                   const char *pszDefinesFilename,
                   const char *pszMessageCategories,
                   const char *pszDefinesMessageCategories);
void VSAPI vsMessageForceAutoUpdate(const char *pszFilename VSDEFAULT(0));
void VSAPI vsMessageFindExePath(char *pszExePath,  // MAXFILENAME
                                const char *arg0);
void VSAPI vsMessageFindExe(char *pszExe,  // MAXFILENAME
                            const char *arg0);
/**
 * Copies current contents of message line into <i>pszMessage</i>.
 *
 * @return Returns <i>pszMessage</i>.
 *
 * @param pszMessage	Output buffer for message.  This can be 0.
 *
 * @param MaxMessageLen	Number of characters allocated to
 * <i>pszMessage</i>.  We recommend
 * VSMAXMESSAGELINE.
 *
 * @param pMaxMessageLen	If this is not 0, this is set to the
 * number of characters you need to allocate to
 * <i>pszMessage</i>.
 *
 * @see vsMessage
 * @see vsGetMessage
 *
 * @categories Miscellaneous_Functions
 *
 */
char *VSAPI vsGetMessageLine(char *pszMessage,int MaxMessageLen,int *pMaxMessageLen VSDEFAULT(0));
/**
 * Loads a .bmp, .ico, .png, or .xpm file. We recommend that the
 * filename start with an "_" (ex. "c:\slickedit\_stackex.ico").
 * This tells SlickEdit that the bitmap is global (not attatched
 * to a Slick-C&reg; dialog box).
 *
 * @return If succcessful, returns names table index of picture.  Otherwise, a
 * negative error code is returned.
 *
 * @param pszFilename	Filename of picture to load.  The filename
 * stored in the names table has no path.  So if
 * you use <b>vsFindIndex</b> to lookup your
 * bitmap, make sure you strip the path.
 *
 * @categories File_Functions
 *
 */
int VSAPI vsUpdatePicture(const char *pszFilename,int reserved VSDEFAULT(0));
/**
 * @return If successful, returns 0 and the temp window/buffer is active.
 * Otherwise a negative error code is returned.
 *
 * @param buf_id	Buffer to attach to the new window.
 *
 * @param pTempWindowId	Set to id of newly created window.
 *
 * @param pOrigWindowId	Set to current window id.  There is always a
 * valid current window id.
 *
 * Since many functions in the VSE API require a window id, you need
 * to play some tricks when you have a buffer id.
 *
 * @example
 * <pre>
 * int ColorFlags;
 * int orig_window_id,orig_buf_id;
 * vsBufCreateTempView(buf_id,&temp_window_id,&orig_window_id);
 *
 * ColorFlags=vsPropGetI(VSWID_HIDDEN,VSP_COLORFLAGS)
 *
 * vsBufDeleteTempView(temp_window_id,orig_window_id);
 * </pre>
 *
 * @see vsBufDeleteTempView
 *
 * @categories Buffer_Functions
 *
 */
void VSAPI vsBufCreateTempView(int buf_id,int *pTempWindowId,int *pOrigWindowId);
/**
 * This function deletes the window but does not delete the buffer attached
 * to that window.
 *
 * @param TempWindowId	Window id to delete.  Buffer is not deleted.
 *
 * @param OrigWindowId	Window to activate after deleting TempWindowId.
 *
 * @see vsBufCreateTempView
 *
 * @categories Buffer_Functions
 *
 */
void VSAPI vsBufDeleteTempView(int TempWindowId,int OrigWindowId);
/**
 * Gets the document name to be displayed to the user.
 *
 * @attention
 * This function is thread-safe.
 *
 * @return Returns <i>pszDocumentName</i>.
 *
 * @param buf_id	Buffer id returned by
 * <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_
 * ID),  <b>vsBufEdit</b>, or vsBufMatch.
 *
 * @param pszDocumentName	Set to document name
 * (VSP_DOCUMENTNAME).  If
 * <i>defaultToBufferName</i> is non-zero
 * and the document name is "" then this
 * parameter is set to the buffer name
 * (VSP_BUFNAME).
 *
 * @param MaxDocumentName	Number of characters allocated to
 * <i>pszDocumentName</i>.
 *
 * @param defaultToBufferName	Indicates that the
 * <i>pszDocumentName</i> parameter
 * should be set to the buffer name if the
 * document is "".
 *
 * @categories Buffer_Functions
 *
 */
char * VSAPI vsBufGetDocumentName(int buf_id,char *pszDocumentName,int MaxDocumentName,int *pMaxDocumentNameLen VSDEFAULT(0),int defaultToBufferName VSDEFAULT(1));
/**
 * @return Returns buffer name corresponding to buffer id specified.  Returns
 * <i>pszBufName</i>.
 *
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	    Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                      <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 * @param pszBufName	Name of buffer corresponding to <i>buf_id</i> specified.
 *                      This can be NULL, in which case, only the file name
 *                      length will be set.
 * @param MaxBufName	Number of characters allocated to pszBufName.
 *                      We recommend VSMAXFILENAME.
 * @param pMaxBufName	If this is not 0, this is set to the number of
 *                      characters needed to be allocated.
 *
 * @categories Buffer_Functions
 */
char * VSAPI vsBufGetName(int buf_id,
                          char *pszBufName, int MaxBufName,
                          int *pMaxBufNameLen VSDEFAULT(0));

/**
 * @return Returns language ID for the language mode corresponding to
 *         buffer id specified.  Returns <i>pszLanguageId</i>.
 *
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	    Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                      <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 * @param pszLanguageId	Name of language setting corresponding to <i>buf_id</i> specified.
 *                      This can be NULL, in which case, only the length of
 *                      the language ID will be set.
 * @param MaxLangId     Number of characters allocated to pszLanguageId.
 *                      We recommend at least 32.
 * @param pMaxLangIdLen	If this is not 0, this is set to the number of
 *                      characters needed to be allocated.
 *
 * @categories Buffer_Functions
 */
VSPSZ VSAPI vsBufGetLanguageId(int buf_id,
                               char *pszLanguageId, int MaxLangId,
                               int *pMaxLangIdLen VSDEFAULT(0));

/**
 * @return Returns language mode name corresponding to
 *         buffer id specified.  Returns <i>pszModeName</i>.
 *
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	       Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                         <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 * @param pszModeName      Name of language mode corresponding to <i>buf_id</i> specified.
 *                         This can be NULL, in which case, only the length of
 *                         the language mode name string will be set.
 * @param MaxModeName      Number of characters allocated to pszModeName.
 *                         We recommend at least VSMAXMODENAME
 * @param pMaxModeNameLen  If this is not 0, this is set to the number of
 *                         characters needed to be allocated.
 *
 * @categories Buffer_Functions
 */
VSPSZ VSAPI vsBufGetModeName(int buf_id,
                             char *pszModeName, int MaxModeName,
                             int *pMaxModeNameLen VSDEFAULT(0));

/**
 * Return the buffer flags for the given buffer.
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	 Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                   <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 *
 * @return bitset of the following flags
 *         <ul>
 *         <li>VSBUFFLAG_HIDDEN -- hidden buffer, next buffer won't switch to this buffer.
 *         <li>VSBUFFLAG_THROW_AWAY_CHANGES -- Allow quit without prompting on modified buffer
 *         <li>VSBUFFLAG_KEEP_ON_QUIT -- Don't delete buffer on QUIT.
 *         <li>VSBUFFLAG_REVERT_ON_THROW_AWAY -- Revert buffer
 *         <li>VSBUFFLAG_PROMPT_REPLACE -- Prompt before replacing buffer contents
 *         <li>VSBUFFLAG_DELETE_BUFFER_ON_CLOSE -- Indicates whether a list box
 *         <li>VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS -- Specifies that buffer is currently being uploaded via FTP
 *         <li>VSBUFFLAG_FTP_BINARY -- Specifies that the FTP buffer should be transferred binary by default
 *         </ul>
 *
 * @categories Buffer_Functions
 */
int VSAPI vsBufGetBufferFlags(int buf_id);
/**
 * Set the buffer flags for the given buffer.
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	 Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                   <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 * @param BufFlags   Bitset of the following flags
 *         <ul>
 *         <li>VSBUFFLAG_HIDDEN -- hidden buffer, next buffer won't switch to this buffer.
 *         <li>VSBUFFLAG_THROW_AWAY_CHANGES -- Allow quit without prompting on modified buffer
 *         <li>VSBUFFLAG_KEEP_ON_QUIT -- Don't delete buffer on QUIT.
 *         <li>VSBUFFLAG_REVERT_ON_THROW_AWAY -- Revert buffer
 *         <li>VSBUFFLAG_PROMPT_REPLACE -- Prompt before replacing buffer contents
 *         <li>VSBUFFLAG_DELETE_BUFFER_ON_CLOSE -- Indicates whether a list box
 *         <li>VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS -- Specifies that buffer is currently being uploaded via FTP
 *         <li>VSBUFFLAG_FTP_BINARY -- Specifies that the FTP buffer should be transferred binary by default
 *         </ul>
 *
 * @categories Buffer_Functions
 */
void VSAPI vsBufSetBufferFlags(int buf_id, int BufFlags);
/**
 * Return the read only flags for the given buffer.
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	 Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                   <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 *
 * @return bitset of the following flags
 *         <ul>
 *         <li>VSREADONLY_ON -- The file is in read only mode.
 *         <li>VSREADONLY_MANUALLY_SET -- Read only mode was set by the user.
 *         </ul>
 *
 * @categories Buffer_Functions
 */
int VSAPI vsBufGetReadOnlyFlags(int buf_id);

/**
 * Return the buffer modify flags for the given buffer.
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	 Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                   <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 *
 * @return bitset of VSMODIFYFLAG_*
 *
 * @categories Buffer_Functions
 */
int VSAPI vsBufGetModifyFlags(int buf_id);

/**
 * Set the buffer modify flags for the given buffer.
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	 Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                   <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 * @param BufFlags   Bitset of VSMODIFYFLAG_*
 * @param resetFlags reset the flags rather than just or'ing in the new flags
 *
 * @categories Buffer_Functions
 */
void VSAPI vsBufSetModifyFlags(int buf_id, int ModifyFlags, int resetFlags=false);

/**
 * @return
 * Return the the modify counter for the given buffer.
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	 Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                   <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 *
 * @categories Buffer_Functions
 */
int VSAPI vsBufGetLastModify(int buf_id);

/**
 * Return the file modification date for the given buffer ID.
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	    Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                      <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 * @param pszFileDate   (output) Set to the file modification date, encoded as
 *                      a 17 character numeric string YYYYMMDDHHmmssuuu
 *                      (year, month, date, hour, minute, second, microseconds)
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Buffer_Functions
 */
int VSAPI vsBufGetFileDate(int buf_id, char *pszFileDate);
/**
 * Return the file modification date for the given buffer ID as a 64-bit integer.
 * @attention
 * This function is thread-safe.
 *
 * @param buf_id	    Buffer id returned by <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_ID),
 *                      <b>vsBufEdit</b>, or <b>vsBufMatch</b>.
 * @param piFileDate    (output) Set to the file modification date, encoded as
 *                      a 17 character numeric string YYYYMMDDHHmmssuuu
 *                      (year, month, date, hour, minute, second, microseconds)
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Buffer_Functions
 */
int VSAPI vsBufGetInt64FileDate(int buf_id, VSINT64 *piFileDate);

/**
 * Translates line number to real line number
 *
 * @param buf_id    Buffer id - vsPropGetI(wid,VSP_BUFID)
 * @param LineNum
 *
 * @return Real line number corresponding to line number specified.
 */
seSeekPosRet VSAPI vsBufLineNumToRealLineNum(int buf_id,seSeekPos LineNum);
/**
 * Returns the number of lines in a buffer including
 * no save lines (lines with the VSLF_NOSAVE flag set).
 *
 * @param buf_id   Buffer id returned by vsPropGetI(wid,VSP_BUF_ID),  vsBufEdit, or vsBufMatch.
 *
 * @return Returns number of lines in buffer including no save lines (lines with the VSLF_NOSAVE flag set).
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
seSeekPosRet VSAPI vsBufGetNofLines(int buf_id);
/**
 * Returns the number of no save lines in a buffer (lines with the VSLF_NOSAVE flag set).
 *
 * @param buf_id   Buffer id returned by vsPropGetI(wid,VSP_BUF_ID),  vsBufEdit, or vsBufMatch.
 *
 * @return Returns the number of no save lines in a buffer (lines with the VSLF_NOSAVE flag set).
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
seSeekPosRet VSAPI vsBufGetNofNoSaveLines(int buf_id);
/**
 * Converts the offset (not ROffset) into a line number and optionally
 * a real line number.
 *
 * @param buf_id    Buffer id returned by vsPropGetI(wid,VSP_BUF_ID),  vsBufEdit, or vsBufMatch.
 * @param Offset    Byte offset into buffer including no save buffer data (lines with the VSLF_NOSAVE flag set).
 * @param pRLineNum  If specified, set to real line number (excludes lines with the VSLF_NOSAVE flag set).
 *
 * @return Returns the line number which contains the offset specified
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
seSeekPosRet VSAPI vsBufGetLineNumFromOffset(int buf_id,seSeekPos Offset,seSeekPos *pRLineNum VSDEFAULT(0));
#define VSNBFLAG_FIND_HIDDEN  0x1
#define VSNBFLAG_NO_UPDATE_BUFFER_VIEW  0x2
#define VSNBFLAG_NO_REFRESH  0x4

/**
 * Switches to the next buffer.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param nbflags	zero or more of the following flags:
 *
 * <dl>
 * <dt>VSNBFLAG_FIND_HIDDEN</dt><dd>
 * 	When specified, buffers with
 * (VSP_BUFFLAGS &
 * VSBUFFLAG_HIDDEN) are found.</dd>
 *
 * <dt>VSNBFLAG_NO_UPDATE_BUFFER_VIEW</dt><dd>
 * 	When specified, the buffers old cursor position (line
 * number, col, etc.) information is not
 * updated.</dd>
 *
 * <dt>VSNBFLAG_NO_REFRESH</dt><dd>
 * 	When specified, window refresh flags are
 * not updated to avoid unnecessary screen
 * painting.</dd>
 * </dl>
 *
 * @see vsPrevBuffer
 * @see vsDeleteBuffer
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsNextBuffer(int wid,int nbflags);
/**
 * Switches to the previous buffer.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param nbflags	zero or more of the following flags:
 *
 * <dl>
 * <dt>VSNBFLAG_FIND_HIDDEN</dt><dd>
 * 	When specified, buffers with
 * (VSP_BUFFLAGS &
 * VSBUFFLAG_HIDDEN) are found.</dd>
 *
 * <dt>VSNBFLAG_NO_UPDATE_BUFFER_VIEW</dt><dd>
 * 	When specified, the buffers old cursor position (line
 * number, col, etc.) information is not
 * updated.</dd>
 *
 * <dt>VSNBFLAG_NO_REFRESH</dt><dd>
 * 	When specified, window refresh flags are
 * not updated to avoid unnecessary screen
 * painting.</dd>
 * </dl>
 *
 * @see vsNextBuffer
 * @see vsDeleteBuffer
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsPrevBuffer(int wid,int nbflags);

#define VSPRINTFLAG_LEFT_HEADER     0
#define VSPRINTFLAG_RIGHT_HEADER    1
#define VSPRINTFLAG_CENTER_HEADER   2
#define VSPRINTFLAG_LEFT_FOOTER     (0<<2)
#define VSPRINTFLAG_RIGHT_FOOTER    (1<<2)
#define VSPRINTFLAG_CENTER_FOOTER   (2<<2)
#define VSPRINTFLAG_TWO_UP          0x10  /* Two columns */
#define VSPRINTFLAG_COLOR           0x20  /* Print color i.e. red green */
#define VSPRINTFLAG_FONTATTRS       0x40  /* Print color coding i.e. bold, italics, etc.*/

typedef struct {
   char szFontName[256];
   int FontSizeX10;         // Pointer size x 10
   int FontFlags;           // VSFONTFLAG_???
   int FontCharSet;         // VSCHARSET_???
   /*
     WARNING: If you set header/footer strings below, make sure you set
     bits 0..3 of the PrintFlags to 0.

         PrintFlags=PrintFlags & ~0xF;

   */
   char szLeftHeader[256];
   char szLeftFooter[256];
   char szCenterHeader[256];
   char szCenterFooter[256];
   char szRightHeader[256];
   char szRightFooter[256];
   // tw stands for twips.  1024 twips is one inch on the printed paper
   int twLeftMargin;   // Left margin between outer edge of paper and printed text
   int twRightMargin;  // Right margin between outer edge of paper and printed text
   int twTopMargin;    // Top margin between outer edge of paper and printed text
   int twBottomMargin; // Bottom margin between outer edge of paper and printed text
   int twAfterHeader;  // This is the space in twips between the header and the first line on the page.
   int twBeforeFooter; // This is the space in twips between the last line on a page and the footer.
   int twSpaceBetween; // This text specifies the width in pixels between columns.
   int PrintFlags;     // VSPRINTFLAGS_???
   int LinenumsEvery;  // Print line numbers every NNN lines.  0 for no line numbers.
} VSPRINTCONFIG;
/**
 * <b>Windows: </b>Retrieves the current print configuration which
 * will be used by the <b>print</b> command.  Note that is does not
 * retrieve the dialog box retrieval information for <b>gui_print</b>
 * dialog box.  Call the <b>vsPrintSetConfig</b> function to set print
 * configuration for the next time the <b>gui_print</b> dialog box is
 * displayed.
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions
 *
 */
void VSAPI vsPrintGetConfig(VSPRINTCONFIG *pconfig,int version VSDEFAULT(0));
/**
 * Windows: Sets the current print configuration which will be used by
 * the <b>print</b> command and the <b>gui_print</b> commands
 * dialog box.
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions
 *
 */
void VSAPI vsPrintSetConfig(const VSPRINTCONFIG *pconfig,int version VSDEFAULT(0));

#define VS_LANGUAGE_OPTIONS_VERSION 9
struct VS_LANGUAGE_OPTIONS {
   union {
      char szRefersToLanguage[VSMAXEXTENSION];
      char szRefersToExtension[VSMAXEXTENSION]; // alias
   };
   char szLexerName[VSMAXLEXERNAME];
#define VSCOLORFLAG_LANGUAGE    0x1
#define VSCOLORFLAG_MODIFY      0x2
#define VSCOLORFLAG_CURRENT_LINE  0x4
   int ColorFlags;
   int LeftMargin;     // 1..
   int RightMargin;    // 1..
   int NewParagraphMargin; // 1..
   int WordWrapStyle;  // see VSWWS_??? flags
   int IndentWithTabs;  // Boolean
   int DisplayLineNumbers;  // Boolean
   int SyntaxExpansion;  // Boolean.  Ignored for fundamental extension
   // We allocated static data for this
   // which you may copy but you may not free
   const char *pszTabs;  // String of tab stops
   char szModeName[VSMAXMODENAME];
   char szBeginEndPairs[VSMAXBEGINENDPAIRS];
   char szAliasFilename[VSMAXFILENAME];
   char szEventTableName[VSMAXNAME];
   char szWordChars[VSMAXWORDCHARS];
   int IndentStyle; // see VSINDENTSTYLE_???
   int SyntaxIndent;  // Number of characters to indent.   Ignored for fundamental extension
   // version=1
   int TruncateLength;
   char szEncoding[VSMAXENCODING];
   char szDTD[VSMAXFILENAME];  // This can be a .vtg or .dtd filename
   // version=2
   int UseFileAssociation;
   char szOpenApplication[VSMAXFILENAME*2 /*Commmand Line */];
   // version=3
   union {
      char szInheritsFromLanguage[VSMAXEXTENSION];
      char szInheritsFromExtension[VSMAXEXTENSION]; // alias
   };
   // version=4
   int BoundsStart;
   int BoundsEnd;
   int AutoCaps;
   int SoftWrap;
   int SoftWrapOnWord;
   // version=5
   int minAbbrev;
   // version = 6
   int IndentCaseFromSwitch;        // boolean
   int PadParens;                   // boolean
   int NoSpaceBeforeParen;          // boolean
   int BeginEndStyle;
   int PointerStyle;
   int FunctionBraceOnNewLine;      // boolean
   int ShowTabs;                    // boolean
   int KeywordCasing;
   int TagCasing;
   int AttributeCasing;
   int ValueCasing;
   int HexValueCasing;
   // version = 7
   char szFileExtensions[VSMAXFILENAME];
   // version = 8
   int HexMode;
   int LineNumbersLen;
   // version = 9
   int LineNumbersFlags;
};
typedef VS_LANGUAGE_OPTIONS VSEXTENSIONOPTIONS;
#define VSEXTENSIONOPTIONS_VERSION VS_LANGUAGE_OPTIONS_VERSION

/**
 * Updates all editor control buffers which are using these language
 * options to the newly configured values.
 *
 * @param pszLangId     Language ID.  See {@link p_LangId}.
 *                      For list of language types,
 *                      use our Language Options dialog
 *                      ("Tools", "Options","Language Setup...").
 *
 * @see vsSetDefaultLanguageOptions
 * @see vsSetDefaultExtensionReferTo
 * @see vsDeleteExtensionOptions
 * @see vsDeleteLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 * @deprecated Use {@link vsUpdateExistingBufferLanguageOptions()}
 */
void VSAPI vsUpdateExistingBufferExtensionOptions(const char *pszLangId,const char *pszReserved VSDEFAULT(0),int reserved VSDEFAULT(0));
/**
 * Updates all editor control buffers which are using these language
 * options to the newly configured values.
 *
 * @param pszLangId     Language ID.  See {@link p_LangId}.
 *                      For list of language types,
 *                      use our Language Options dialog
 *                      ("Tools", "Options","Language Setup...").
 * @param pszReserved   unused
 * @param reserved      unused
 *
 * @see vsSetDefaultLanguageOptions
 * @see vsDeleteLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 * @since 13.0
 */
void VSAPI vsUpdateExistingBufferLanguageOptions(const char *pszLangId,
                                                 const char *pszReserved VSDEFAULT(0),
                                                 int reserved VSDEFAULT(0));


/**
 * Looks up the default file encoding to be used when attempting to load
 * files of the given langauge.  It looks first in the language specific
 * file encodings and then for an extension specific file encodings, and
 * finally it will default to the default file encoding.
 *
 * @attention
 * This function is thread-safe.
 *
 * @param pszLangId  Language ID (see {@link p_LangId}
 *                   For list of language types,
 *                   Language Options dialog
 *                   ("Tools", "Options", "Language Setup...").
 *
 * @param pszExtension	File extension.
 *                      For list of file extension types,
 *                      use our Extension Manager dialog
 *                      ("Tools", "Options...", "File Extension Manager").
 *
 * @see vsGetDefaultLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 */
int VSAPI vsGetDefaultFileEncoding(const char *pszLangId,
                                   const char *pszExtension VSDEFAULT(0));

/**
 * Allows you to specify that a file extension is associated
 * with the specified language.  This information is used to
 * determine what language mode to choose when a file with the
 * given extension is opened.
 *
 * @param pszExtension	File extension.
 *                      For list of file extension types,
 *                      use our Extension Manager dialog
 *                      ("Tools", "Options...", "File Extension Manager").
 *
 * @param pszLangId  Language ID (see {@link p_LangId}
 *                   For list of language types,
 *                   Language Options dialog
 *                   ("Tools", "Options", "Language Setup...").
 *
 * @see vsGetDefaultExtensionReferTo
 * @see vsSetDefaultLanguageOptions
 * @see vsDeleteLanguageOptions
 * @see vsUpdateExistingBufferLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 */
void VSAPI vsSetDefaultExtensionReferTo(const char *pszExtension, const char *pszLangId);

/**
 * Looks up the language mode with is associated with the
 * given physical file extension.  This information is used to
 * determine what language mode to choose when a file with the
 * given extension is opened.
 *
 * @attention
 * This function is thread-safe.
 *
 * @param pszExtension	File extension.
 *                      For list of file extension types,
 *                      use our Extension Manager dialog
 *                      ("Tools", "Options...", "File Extension Manager").
 *
 * @param pszLangId  Language ID (see {@link p_LangId}
 *                   For list of language types,
 *                   Language Options dialog
 *                   ("Tools", "Options", "Language Setup...").
 *
 * @param maxLangId  number of bytes allocated to pszLangId
 *
 * @see vsSetDefaultExtensionReferTo
 * @see vsSetDefaultLanguageOptions
 * @see vsSetDefaultExtensionReferTo
 * @see vsDeleteLanguageOptions
 * @see vsUpdateExistingBufferLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 */
void VSAPI vsGetDefaultExtensionReferTo(const char *pszExtension,
                                        char *pszLangId, int maxLangId);

/**
 * Allows you to create a language which has it's own set of
 * options, but can inherit support callbacks from another
 * language.
 *
 * @param pszExtension	File extension.
 *                      For list of file extension types,
 *                      use our File Extension Manager dialog
 *                      ("Tools", "Options...", "File Extension Manager")
 *
 * @param pszInheritsFrom  <i>pszExtension</i> is set
 *                         to inherit language specific callbacks
 *                         from the language specified by
 *                         <i>pszInheritFrom</i>.
 *
 * @see vsSetDefaultLanguageOptions
 * @see vsSetDefaultExtensionReferTo
 * @see vsDeleteExtensionOptions
 * @see vsDeleteLanguageOptions
 * @see vsUpdateExistingBufferExtensionOptions
 * @see vsUpdateExistingBufferLanguageOptions
 * @see vsLanguageInheritsFrom
 * @see vsFindLanguageCallbackIndex
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @deprecated Use {@link vsSetLanguageInheritsFrom}.
 */
void VSAPI vsSetDefaultExtensionInheritsFrom(const char *pszExtension,const char *pszInheritFrom);

/**
 * Allows you to create a language which has it's own set of
 * options, but can inherit support callbacks from another
 * language.
 *
 * @param pszLangId  Language ID (see {@link p_LangId}
 *                   For list of language types,
 *                   Language Options dialog
 *                   ("Tools", "Options", "Language Setup...").
 *
 * @param pszParentLangId  <i>pszLangId</i> is set to
 *                         inherit language specific callbacks
 *                         from the language specified by
 *                         <i>pszParentLangId</i>.
 *                         If NULL, remove language inheritance
 *                         for <i>pszLangId</i>.
 *
 * @see vsSetDefaultLanguageOptions
 * @see vsSetDefaultExtensionReferTo
 * @see vsDeleteLanguageOptions
 * @see vsUpdateExistingBufferLanguageOptions
 * @see vsLanguageInheritsFrom
 * @see vsFindLanguageCallbackIndex
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @since 13.0
 */
void VSAPI vsSetLanguageInheritsFrom(const char *pszLangId,const char *pszParentLangId);

/**
 * Sets language specific options for a specific file extension.
 *
 * @param pszExtension	File extension.
 *                      For list of file extension types,
 *                      use our File Extension Manager dialog
 *                      ("Tools", "Options...", "File Extension Manager")
 * @param pLangOptions  New language specific options for
 *                      <i>pszExtension</i>.  Since all options are
 *                      must be set, use the
 *                      <b>vsGetDefaultExtensionOptions</b>
 *                      first to query the existing value before
 *                      setting new values.
 * @param reserved      unused
 * @param version       normally VS_LANGUAGE_OPTIONS_VERSION
 *
 * @see vsGetDefaultExtensionOptions
 * @see vsSetDefaultLanguageOptions
 * @see vsSetDefaultExtensionReferTo
 * @see vsDeleteExtensionOptions
 * @see vsDeleteLanguageOptions
 * @see vsUpdateExistingBufferExtensionOptions
 * @see vsUpdateExistingBufferLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 *
 * @deprecated Use {@link vsSetDefaultLanguageOptions}
 */
void VSAPI vsSetDefaultExtensionOptions(const char *pszLangId,
                                        const VS_LANGUAGE_OPTIONS *pLangOptions,
                                        int reserved VSDEFAULT(0),
                                        int version VSDEFAULT(VS_LANGUAGE_OPTIONS_VERSION));

/**
 * Sets language specific options for a specific language.
 *
 * @param pszLangId     File language ID (see {@link p_LangId}).
 *                      For list of language types,
 *                      use our Language Options dialog
 *                      ("Tools", "Options", "Language Setup...")
 * @param pszExtension  File extension referred to pszLangId
 * @param pLangOptions  New language specific options.
 *                      Since all options are must be set, use the
 *                      <b>vsGetDefaultLanguageOptions</b>
 *                      first to query the existing value before
 *                      setting new values.
 * @param reserved      unused
 * @param version       normally VS_LANGUAGE_OPTIONS_VERSION
 *
 * @see vsSetDefaultExtensionReferTo
 * @see vsDeleteLanguageOptions
 * @see vsUpdateExistingBufferLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 * @since 13.0
 */
void VSAPI vsSetDefaultLanguageOptions(const char *pszLangId,
                                       const char *pszExtension,
                                       const VS_LANGUAGE_OPTIONS *pLangOptions,
                                       int version VSDEFAULT(VS_LANGUAGE_OPTIONS_VERSION));
/**
 * Gets language specific options for a specific file extension.
 *
 * @return Returns 0 if successful.
 *
 * @param pszExtension	File extension.
 *                      For list of file extension types,
 *                      use our File Extension Manager dialog
 *                      ("Tools", "Options...", "File Extension Manager")
 * @param pLangOptions  Initialized to language specific options
 *                      for <i>pszExtension</i>.
 * @param version       normally VS_LANGUAGE_OPTIONS_VERSION
 *
 * @see vsSetDefaultExtensionOptions
 * @see vsGetDefaultLanguageOptions
 * @see vsSetDefaultLanguageOptions
 * @see vsSetDefaultExtensionReferTo
 * @see vsDeleteLanguageOptions
 * @see vsUpdateExistingBufferLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 *
 * @deprecated Use {@link vsGetDefaultLanguageOptions}
 */
int VSAPI vsGetDefaultExtensionOptions(const char *pszExtension,
                                       VS_LANGUAGE_OPTIONS *pLangOptions,
                                       int version VSDEFAULT(VS_LANGUAGE_OPTIONS_VERSION));

/**
 * Gets language specific options for a specific language type.
 *
 * @return Returns 0 if successful.
 *
 * @param pszLangId     Language ID (see {@link p_LangId}).
 *                      For list of language types,
 *                      use our Language Manager dialog
 *                      ("Tools", "Options...", "Language Manager")
 * @param pszExtension  File extension referred to pszLangId
 * @param pLangOptions  Initialized to language specific options
 *                      for <i>pszLangId</i>.
 * @param version       normally VS_LANGUAGE_OPTIONS_VERSION
 *
 * @see vsSetDefaultLanguageOptions
 * @see vsSetDefaultExtensionReferTo
 * @see vsDeleteLanguageOptions
 * @see vsUpdateExistingBufferLanguageOptions
 * @see vsSetDefaultLanguageOptions
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 * @since 13.0
 */
int VSAPI vsGetDefaultLanguageOptions(const char *pszLangId,
                                      const char *pszExtension,
                                      VS_LANGUAGE_OPTIONS *pLangOptions,
                                      int version VSDEFAULT(VS_LANGUAGE_OPTIONS_VERSION));

/**
 * Removes the language setup options for the specific
 * file extension.  If the given extension is just
 * referred to another extension, then only remove the
 * referral, not the entire language setup.
 *
 * @param pszExtension  File extension.
 *                      For list of file extension types,
 *                      use our Language Options dialog
 *                      ("Tools", "Options","Language Setup...").
 *
 * @see vsSetDefaultLanguageOptions
 * @see vsGetDefaultLanguageOptions
 * @see vsSetDefaultExtensionReferTo
 * @see vsGetDefaultExtensionReferTo
 * @see vsDeleteLanguageOptions
 *
 * @categories Configuration_Functions
 */
void VSAPI vsDeleteExtensionOptions(const char *pszExtension);

/**
 * Removes the language setup options for the specific
 * language, as specified by the given language ID.
 * Note that 'lang' must be a real language ID, not a
 * referred file extension.
 *
 * @param pszLangId     Language ID (see {@link p_LangId}
 *                      For list of languages,
 *                      use our Language Options dialog
 *                      ("Tools", "Options","Language Setup...").
 *
 * @see vsSetDefaultLanguageOptions
 * @see vsGetDefaultLanguageOptions
 * @see vsSetDefaultExtensionReferTo
 * @see vsGetDefaultExtensionReferTo
 * @see vsDeleteExtensionOptions
 *
 * @categories Configuration_Functions
 * @since 13.0
 */
void VSAPI vsDeleteLanguageOptions(const char *pszLangId);

/**
 * Does the current source language match or inherit from the
 * given language?
 * <p>
 * If 'lang' is not specified, the current object
 * must be an editor control.
 *
 * @attention
 * This function is thread-safe provided
 * <em>pszLangId</em> is not NULL or the empty string.
 *
 * @param parent        language ID to compare to
 * @param pszLangId     current language ID
 *                      (default={@link p_LangId})
 *
 * @return 'true' if the language matches, 'false' otherwise.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @since 13.0
 */
EXTERN_C int VSAPI
vsLanguageInheritsFrom(const char *parent, const char *pszLangId VSDEFAULT(0));

/**
 * Does the current source language have the given language in 
 * it's list of languages which symbols can be referenced in? 
 * <p>
 * If 'lang' is not specified, the current object
 * must be an editor control.
 *
 * @attention
 * This function is thread-safe provided
 * <em>pszLangId</em> is not NULL or the empty string.
 *
 * @param refLangId     language ID to check reference in
 * @param pszLangId     current language ID
 *                      (default={@link p_LangId})
 *
 * @return 'true' if the language matches, 'false' otherwise.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @since 17.0
 */
EXTERN_C int VSAPI
vsLanguageReferencedIn(const char *refLangId, const char *pszLangId VSDEFAULT(0));

/**
 * This function is used to look up a language-specific
 * callback function.
 * <p>
 * Return the names table index for the callback function for the
 * current language, or a language we inherit behavior from.
 * The current object should be an editor control.
 *
 * @attention
 * This function is thread-safe provided
 * <em>pszLangId</em> is not NULL or the empty string.
 * However, it is NOT thread-safe to call a Slick-C function.
 *
 * @param callback_name  name of callback to look up, with a
 *                       '%s' marker in place where the language
 *                       ID would be normally located.
 * @param pszLangId      current language ID
 *                       (default={@link p_LangId})
 *
 * @return Names table index for the callback.
 *         0 if the callback is not found or not callable.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @since 13.0
 */
EXTERN_C
int VSAPI vsFindLanguageCallbackIndex(const char *callback_name,
                                      const char *pszLangId VSDEFAULT(0));

#define VSCHARSET_ANSI  0
#define VSCHARSET_DEFAULT 1

#define VSCHARSET_SYMBOL          2
#define VSCHARSET_SHIFTJIS        128
#define VSCHARSET_HANGEUL         129
#define VSCHARSET_GB2312          134
#define VSCHARSET_CHINESEBIG5     136
#define VSCHARSET_OEM             255
//WINVER >= 0x0400)
#define VSCHARSET_JOHAB           130
#define VSCHARSET_HEBREW          177
#define VSCHARSET_ARABIC          178
#define VSCHARSET_GREEK           161
#define VSCHARSET_TURKISH         162
#define VSCHARSET_THAI            222
#define VSCHARSET_EASTEUROPE      238
#define VSCHARSET_RUSSIAN         204

#define VSCHARSET_MAC             77
#define VSCHARSET_BALTIC          186



/**
 * Returns information about the font configuration.
 *
 * @return Returns 0 if parameters are valid.
 *
 * @param field</i>	Field to change font for.  One of the
 * following constants defined in "vs.h":
 *
 * <dl>
 * <dt>VSCFG_CMDLINE</dt><dd>
 * 	Font used by the command line.</dd>
 * <dt>VSCFG_WINDOW_TEXT</dt><dd>
 * 	Font used by the editor control window text.</dd>
 * <dt>VSCFG_MESSAGE</dt><dd>
 * 	Font used by the message line.</dd>
 * <dt>VSCFG_STATUS</dt><dd>
 * 	Font used by the status line.</dd>
 * </dl>
 *
 * @param pszFontName	Output buffer for font name.
 *
 * @param MaxFontName	Number of characters for font name.
 *
 * @param pFontSizex10	Point size of font x 10.
 *
 * @param pFontFlags	One or more of the following flags:
 *
 * <ul>
 * <li>VSFONTFLAG_BOLD</li>
 * <li>VSFONTFLAG_ITALIC</li>
 * <li>VSFONTFLAG_STRIKE_THRU</li>
 * <li>VSFONTFLAG_UNDERLINE</li>
 * </ul>
 *
 * @param pCharSet	Indicates the character set of the font.  These
 * character sets map directly onto the
 * Windows character sets. See
 * VSCHARSET_??? constants defined in
 * "vs.h".  We do not expect this parameter to
 * be used under UNIX.
 *
 * @see vsSetDefaultFont
 * @see vsGetDefaultColor
 * @see vsSetDefaultColor
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions, Miscellaneous_Functions
 *
 */
int VSAPI vsGetDefaultFont(int field,char *pszFontName,int MaxFontName,
                           int *pFontSizex10,
                           int *pFontFlags,int *pCharSet VSDEFAULT(0));
/**
 * Sets font configuration for various SlickEdit objects.
 *
 * @return Returns 0 if parameters are valid.
 *
 * @param field	Field to change font for.  One of the
 * following constants defined in "vs.h".
 *
 * <dl>
 * <dt>VSCFG_CMDLINE</dt><dd>
 * 	Font used by the command line.</dd>
 * <dt>VSCFG_WINDOW_TEXT</dt><dd>
 * 	Font used by the editor control window text.</dd>
 * <dt>VSCFG_MESSAGE</dt><dd>
 * 	Font used by the message line.</dd>
 * <dt>VSCFG_STATUS</dt><dd>
 * 	Font used by the status line.</dd>
 * <dt>VSCFG_DIALOG</dt><dd>
 * 	Font used by dialog boxes.</dd>
 * </dl>
 *
 * @param pszFontName	Output buffer for font name.
 *
 * @param pFontSizex10	Point size of font x 10.
 *
 * @param FontFlags	One or more of the following flags:
 *
 * <ul>
 * <li>VSFONTFLAG_BOLD</li>
 * <li>VSFONTFLAG_ITALIC</li>
 * <li>VSFONTFLAG_STRIKE_THRU</li>
 * <li>VSFONTFLAG_UNDERLINE</li>
 * </ul>
 *
 * @param CharSet	Indicates the character set of the font.  These
 * character sets map directly onto the
 * Windows character sets. See
 * VSCHARSET_??? constants defined in
 * "vs.h".  We do not expect this parameter to
 * be used under UNIX.
 *
 * @see vsGetDefaultFont
 * @see vsGetDefaultColor
 * @see vsSetDefaultColor
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions
 *
 */
int VSAPI vsSetDefaultFont(int field,const char *pszFontName,
                           int FontSizex10,int FontFlags,int CharSet VSDEFAULT(VSCHARSET_DEFAULT));
/**
 * @return Returns number of menu items in loaded menu <i>menu_handle</i>.
 *
 * @param menu_handle	Handle of loaded menu returned by
 * <B>VSP_MENUHANDLE</B>,
 * <b>vsMenuLoad</b>,
 * <b>vsMenuFind</b>, or
 * <b>vsMenuGetState</b>.
 *
 * @see vsMenuDelete
 * @see vsMenuDestroy
 * @see vsMenuFind
 * @see vsMenuGetState
 * @see vsMenuInsert
 * @see vsMenuLoad
 * @see vsMenuQInfo
 * @see vsMenuSet
 * @see vsMenuSetState
 * @see vsMenuShow
 *
 * @categories Menu_Functions
 *
 */
int VSAPI vsMenuQInfo(int menu_handle,char option VSDEFAULT('C'));
/**
 * Deletes a menu or menu item in a loaded menu or a menu resource.
 *
 * @return Returns 0 if successful.
 *
 * @param menu_handle	Handle of loaded menu returned by
 * <B>VSP_MENUHANDLE</B>,
 * <b>vsMenuLoad</b>,
 * <b>vsMenuFind</b>, or
 * <b>vsMenuGetState</b>.  This handle may
 * also be a handle to menu resource returned
 * by <b>vsFindIndex</b> or
 * <b>vsNameMatch</b>.
 *
 * @param menu_pos	Position within menu <i>menu_handle</i>.
 * The first menu item position is 0.
 *
 * @example
 * <pre>
 * void VSAPI dllproc ()
 * {
 *      int status;
 *      int mh,mpos;
 *
 *      status=vsMenuFind (
 *                vsPropGetI(VSWID_MDI,VSP_MENU_HANDLE),
 *                "help -using",&mh,&mpos,'M');
 *      if (!status) vsMenuDelete (mh,mpos);
 * }
 * </pre>
 *
 * @see vsMenuDelete
 * @see vsMenuDestroy
 * @see vsMenuFind
 * @see vsMenuGetState
 * @see vsMenuInsert
 * @see vsMenuLoad
 * @see vsMenuQInfo
 * @see vsMenuSet
 * @see vsMenuSetState
 * @see vsMenuShow
 *
 * @categories Menu_Functions
 *
 */
int VSAPI vsMenuDelete(int menu_handle,int position);
/**
 * Destroy menu loaded by the vsMenuLoad function.  This function is
 * typically used to destroy the old menu bar when replacing a menu bar
 * or to destroy a pop-up menu after it has been displayed.
 *
 * @return Returns 0 if successful.
 *
 * @param menu_handle	Handle of loaded menu returned by
 * <B>VSP_MENUHANDLE</B>,
 * <b>vsMenuLoad</b>,
 * <b>vsMenuFind</b>, or
 * <b>vsMenuGetState</b>.
 *
 * @see vsMenuDelete
 * @see vsMenuDestroy
 * @see vsMenuFind
 * @see vsMenuGetState
 * @see vsMenuInsert
 * @see vsMenuLoad
 * @see vsMenuQInfo
 * @see vsMenuSet
 * @see vsMenuSetState
 * @see vsMenuShow
 *
 * @categories Menu_Functions
 *
 */
int VSAPI vsMenuDestroy(int menu_handle);
/**
 * Finds menu or menu item with a specified command or category.
 *
 * @return Returns 0 if successful.
 *
 * @param menu_handle	Handle of loaded menu returned by
 * VSP_MENUHANDLE, vsMenuLoad,
 * vsMenuFind, or vsMenuGetState.
 *
 * @param pszCommand  Command or category of menu item to
 * find.  If a command is specified, the
 * command must match exactly.  See
 * <i>by_category</i> parameter.
 *
 * @param pmenu_handle	Handle to loaded menu which contains
 * menu item found.
 *
 * @param pposition	Position of menu item found within
 * <i>pmenu_handle</i>.  0 is the position of
 * the first menu item.  Use the vsMenuQInfo
 * function to determine the number of items in
 * a loaded menu.
 *
 * @param by_category	May be 'M' or  'C'.  If the 'M' option is given,
 * <i>pszCommand</i> is the command of the
 * menu item to be found.  If the 'C' option is
 * given,  <i>pszCommand</i> is the category
 * of the menu item to be found.  Defaults to
 * 'C' if not specified.
 *
 * @example
 * <pre>
 * void VSAPI dllproc ()
 * {
 *     int status;
 *     int mh,mp;
 *     // Find the menu item which executes the gui-find command
 *     status=vsMenuFind(
 *             vsPropGetI(VSWID_MDI,VSP_MENUHANDLE),
 *             "new", &mh, &mp,'M');
 *     if (status) {
 *         vsMessage("Command not found in menu bar");
 *         return;
 *     }
 *     int mf_flags;
 *     char caption[VSMAXMENUSTRING];
 *     char command[VSMAXMENUSTRING];
 *     char categories[VSMAXMENUSTRING];
 *     char  help_command[VSMAXMENUSTRING];
 *     char help_message[VSMAXMENUSTRING];
 *     vsMenuGetState(mh, mp, &mf_flags, 'P',
 *                                 caption,VSMAXMENUSTRING
 *                                 command, VSMAXMENUSTRING,
 *                                 categories, VSMAXMENUSTRING,
 *                                 help_command, VSMAXMENUSTRING,
 *                                 help_message, VSMAXMENUSTRING );
 *     vsMessage(help_message);
 * }
 * </pre>
 *
 * @see vsMenuDelete
 * @see vsMenuDestroy
 * @see vsMenuFind
 * @see vsMenuGetState
 * @see vsMenuInsert
 * @see vsMenuLoad
 * @see vsMenuQInfo
 * @see vsMenuSet
 * @see vsMenuSetState
 * @see vsMenuShow
 *
 * @categories Menu_Functions
 *
 */
int VSAPI vsMenuFind(int menu_handle,const char *pszCommand,int *pmenu_handle,int *pposition,char by_category);
/**
 * Gets menu item values for the menu items which contain the
 * command or category specified.
 *
 * @return Returns 0 if successful.
 *
 * @param menu_handle	Handle of loaded menu returned by
 * VSP_MENUHANDLE, vsMenuLoad,
 * vsMenuFind, or vsMenuGetState.
 *
 * @param pszFindCommand Command or category of menu item to
 * find.  If a command is specified, the
 * command must match exactly.  See
 * <i>by_category</i> parameter.
 *
 * @param by_category	May be 'M', 'C', 'P'.  If the 'M' option is
 * given, <i>pszFindCommand</i> is the
 * command of the menu item to be found. If
 * the 'C' option is given,
 * <i>pszFindCommand</i> is the category of
 * the menu item to be found.  If the 'P' option
 * is given, <i>pszFindCommand</i> is an
 * integer (you must cast
 * <i>pszFindCommand</i> to int) position
 * (0..vsMenuQInfo(<i>menu_handle</i>)-1)
 * of the menu item with in
 * <i>menu_handle</i> in ASCIIZ format.
 * Defaults to 'C'.
 *
 * @param mf_flags    may be zero or more of the
 * following flags defined in "vs.h":
 *
 * <ul>
 * <li>VSMF_CHECKED</li>
 * <li>VSMF_UNCHECKED</li>
 * <li>VSMF_GRAYED</li>
 * <li>VSMF_ENABLED</li>
 * <li>VSMF_SUBMENU</li>
 * </ul>
 *
 * @param pszItemText	Menu item title.  This may be 0.
 *
 * @param MaxItemTextLen	Number of characters allocated to
 * <i>pszItemText</i>.  We recommend
 * VSMAXMENUSTRING.
 *
 * @param pszCommand	For a sub-menu, <i>command</i> is set to a
 * menu handle which may be used in calls to
 * _menu_get_state or _menu_info (you must
 * convert it to an int).  Otherwise, this is set to
 * the command to be executed when the menu
 * item is selected..  This may be 0.
 *
 * @param MaxCommandLen	Number of characters allocated to
 * <i>pszCommandLen</i>.  We recommend
 * VSMAXMENUSTRING.
 *
 * @param pszCategory	Menu item categories. This may be 0. May
 * be one or more categories separated with a '|'
 * character.  See <b>vsMenuSetState</b> function for
 * more information about categories.
 *
 * @param MaxCategoryLen	Number of characters allocated to
 * <i>pszCategory</i>.  We recommend
 * VSMAXMENUSTRING.
 *
 * @param pszHelpCommand	Menu item help command.  This
 * may be 0. Executed when F1 is pressed
 * while on the menu item.
 *
 * @param MaxHelpCommandLen	Number of characters allocated to
 * <i>pszHelpCommand</i>.  We recommend
 * VSMAXMENUSTRING.
 *
 * @param pszHelpMessage       Menu item help message.  This may be 0.
 * Displayed when menu item is selected.
 *
 * @param MaxHelpMessageLen	Number of characters allocated to
 * <i>pszHelpMessage</i>. We recommend
 * VSMAXMENUSTRING.
 *
 * @param pMaxItemTextLen	If this is not 0, this is set to the
 * number of characters you need to allocate to
 * <i>pszItemText</i>.
 *
 * @param pMaxCommandLen	If this is not 0, this is set to the
 * number of characters you need to allocate to
 * <i>pszCommand</i>.
 *
 * @param pMaxCategoryLen	If this is not 0, this is set to the
 * number of characters you need to allocate to
 * <i>pszCategory</i>.
 *
 * @param pMaxHelpCommandLen	If this is not 0, this is set to the
 * number of characters you need to allocate to
 * <i>pszHelpCommand</i>.
 *
 * @param pMaxHelpStringLen	If this is not 0, this is set to the
 * number of characters you need to allocate to
 * <i>pszHelpString</i>.
 *
 * @example
 * <pre>
 * // This code traverses a menu that has been loaded with
 * vsMenuLoad
 * static void traverse_menu(int menu_handle)
 * {
 *     int Nofitems;
 *     Nofitems=vsMenuQInfo(menu_handle,'c');
 *     for (i=0;i<Nofitems;++i) {
 *            int mf_flags;
 *           char caption[VSMAXMENUSTRING];
 *           char command[VSMAXMENUSTRING];
 *           char categories[VSMAXMENUSTRING];
 *           char  help_command[VSMAXMENUSTRING];
 *           char help_message[VSMAXMENUSTRING];
 *           vsMenuGetState(mh, i, &mf_flags, 'P',
 *                                        caption,VSMAXMENUSTRING
 *                                        command, VSMAXMENUSTRING,
 *                                        categories, VSMAXMENUSTRING,
 *                                        help_command, VSMAXMENUSTRING,
 *                                        help_message, VSMAXMENUSTRING );
 *
 *          vsMessageBox (caption)
 *          if (mf_flags & VSMF_SUBMENU) {
 *              traverse_menu(command);
 *          }
 *     }
 * }
 * void VSAPI dllproc ()
 * {
 *      traverse_menu(vsPropGetI(VSWID_MDI,
 * VSP_MENUHANDLE));
 * }
 * </pre>
 *
 * @see vsMenuDelete
 * @see vsMenuDestroy
 * @see vsMenuFind
 * @see vsMenuGetState
 * @see vsMenuInsert
 * @see vsMenuLoad
 * @see vsMenuQInfo
 * @see vsMenuSet
 * @see vsMenuSetState
 * @see vsMenuShow
 *
 * @categories Menu_Functions
 *
 */
int VSAPI vsMenuGetState(int menu_handle,char *pszFindCommand,
                         int *pflags,char by_category,
                         char *pszItemText VSDEFAULT(0),
                         int MaxItemTextLen VSDEFAULT(0),
                         char *pszCommand VSDEFAULT(0),
                         int MaxCommandLen VSDEFAULT(0),
                         char *pszCategory VSDEFAULT(0),
                         int MaxCategoryLen VSDEFAULT(0),
                         char *pszHelpCommand VSDEFAULT(0),
                         int MaxHelpCommandLen VSDEFAULT(0),
                         char *pszHelpString VSDEFAULT(0),
                         int MaxHelpStringLen VSDEFAULT(0),
                         int *pMaxItemTextLen VSDEFAULT(0),
                         int *pMaxCommandLen VSDEFAULT(0),
                         int *pMaxCategoryLen VSDEFAULT(0),
                         int *pMaxHelpCommandLen VSDEFAULT(0),
                         int *pMaxHelpStringLen VSDEFAULT(0)
                         );
/**
 * Inserts a menu or menu item into a loaded menu or a menu resource.
 *
 * @return Returns 0 if successful.
 *
 * @param menu_handle	Handle of loaded menu returned by
 * VSP_MENUHANDLE, vsMenuLoad,
 * vsMenuFind, or vsMenuGetState.
 *
 * @param position	Position within menu <i>menu_handle</i>.
 * Menu item is inserted before position.  The
 * first menu item position is 0.  Specify -1 or a
 * position greater than the last menu item to
 * insert after the last menu item.
 *
 * @param mf_flags may be zero or more of the
 * following flags defined in "vs.h":
 *
 * <ul>
 * <li>VSMF_CHECKED</li>
 * <li>VSMF_UNCHECKED</li>
 * <li>VSMF_GRAYED</li>
 * <li>VSMF_ENABLED</li>
 * <li>VSMF_SUBMENU</li>
 * </ul>
 *
 * @param pszItemText	Menu item title.
 *
 * @param pszCategory	Menu item categories. May be one or more
 * categories separated with a '|' character.  See
 * <b>vsMenuSetState</b> function for more
 * information about categories.
 *
 * @param pszHelpCommand	Menu item help command.
 * Executed when F1 is pressed while on the
 * menu item.
 *
 * @param pszHelpMessage	Menu item help message.  Displayed when
 * menu item is selected.
 *
 * @param MaxHelpMessageLen	Number of characters allocated to
 * <i>pszHelpMessage</i>.
 *
 * @example
 * <pre>
 * void VSAPI dllproc ()
 * {
 *      // Insert 2 items into a menu resource called menu1
 *      int index;
 *      index=vsFindIndex ("menu1",vsoi2type(VSOI_MENU));
 *      if (!index) {  // IF menu1 does not already exist?
 *          // Create new menu resource in names table
 *          index=vsNameInsert ("menu1",vsoi2type(VSOI_MENU));
 *          if (index&lt;=0) {
 *              vsMessage("unable to create menu1");
 *              return;
 *          }
 *      }
 *      // Insert File menu
 *      vsMenuInsert(index,0,VSMF_ENABLED|VSMF_SUBMENU,"&File",
 *                                "","","help file menu","");
 *      // Insert New menu item within File menu
 *      vsMenuInsert(
 *                   vsPropGetI(index,VSP_CHILD),
 *                    0,VSMF_ENABLED,"&New","New","",
 *                    "help file menu", "");
 *      // Load and display the menu as a pop-up menu
 *     vsExecute(0, "show menu1");
 * }
 * </pre>
 *
 * @see vsMenuDelete
 * @see vsMenuDestroy
 * @see vsMenuFind
 * @see vsMenuGetState
 * @see vsMenuInsert
 * @see vsMenuLoad
 * @see vsMenuQInfo
 * @see vsMenuSet
 * @see vsMenuSetState
 * @see vsMenuShow
 *
 * @categories Menu_Functions
 *
 */
int VSAPI vsMenuInsert(int menu_handle,int position,int flags,
                       const char *pszItemText,const char *pszCommand,
                       const char *pszCategory,
                       const char *pszHelpCommand,
                       const char *pszHelpString);
/**
 * @return If successful, loads menu resource and returns handle of loaded menu.
 * Otherwise a negative error code is returned.   Displaying a menu
 * resource as a pop-up menu with the <b>vsMenuShow</b> function
 * requires that you specify 'P' as the second argument to this function.
 * <i>menu_index</i> is a handle to a menu resource returned by
 * <b>vsFindIndex</b> or <b>vsNameMatch</b>.
 *
 * @param wid	Window id of SlickEdit form or MDI
 * frame.
 *
 * @param menu_index	Names table index of menu returned by
 * <b>vsFindIndex</b> or
 * <b>vsNameMatch</b>.
 *
 * @param menu_option	Specify 'P' for a popup-menu or 'M' for
 * menu bar.
 *
 * @example
 * <pre>
 * void VSAPI dllproc ()
 * {
 *     int index;
 *     // Find index of SlickEdit MDI menu resource
 *     index=vsFindIndex("_mdi_menu",vsoi2type(VSOI_MENU));
 *     // Load this menu resource
 *     int menu_handle;
 *     menu_handle=vsMenuLoad(VSWID_MDI,index,'M');
 *
 *     int old_menu_handle;
 *
 *     old_menu_handle=vsPropGetI(VSWID_MDI,VSP_MENUHANDLE);
 *
 *     // _set_menu will fail if the form has a dialog box style border.
 *     // Put a menu bar on this form.
 *     vsMenuSet(VSWID_MDI,menu_handle);
 *     // You DO NOT need to call vsMenuDestroy.  This menu is
 *     // destroyed when the MDI window is deleted.
 *     vsMenuDestroy(old_menu_handle);
 * }
 * </pre>
 *
 * @see vsMenuDelete
 * @see vsMenuDestroy
 * @see vsMenuFind
 * @see vsMenuGetState
 * @see vsMenuInsert
 * @see vsMenuLoad
 * @see vsMenuQInfo
 * @see vsMenuSet
 * @see vsMenuSetState
 * @see vsMenuShow
 *
 * @categories Menu_Functions
 *
 */
int VSAPI vsMenuLoad(int wid,int index,char menu_option);
/**
 * Sets the menu bar to the loaded menu specified.   If the form already
 * has a menu bar you should destroy the old menu bar AFTER setting
 * the menu bar.  See example below.
 *
 * @return Returns 0 if successful.
 *
 * @param wid	Window id of SlickEdit form or MDI
 * frame.
 *
 * @param menu_handle	Handle of loaded menu returned by
 * vsMenuLoad.
 *
 * @example
 * <pre>
 * void VSAPI dllproc ()
 * {
 *     int index;
 *     // Find index of SlickEdit MDI menu resource
 *     index=vsFindIndex("_mdi_menu",vsoi2type(VSOI_MENU));
 *     // Load this menu resource
 *     int menu_handle;
 *     menu_handle=vsMenuLoad(VSWID_MDI,index,'M');
 *
 *     int old_menu_handle;
 *
 *     old_menu_handle=vsPropGetI(VSWID_MDI,VSP_MENUHANDLE);
 *
 *     // _set_menu will fail if the form has a dialog box style border.
 *     // Put a menu bar on this form.
 *     vsMenuSet(VSWID_MDI,menu_handle);
 *     // You DO NOT need to call vsMenuDestroy.  This menu is
 *     // destroyed when the MDI window is deleted.
 *     vsMenuDestroy(old_menu_handle);
 * }
 * </pre>
 *
 * @see vsMenuDelete
 * @see vsMenuDestroy
 * @see vsMenuFind
 * @see vsMenuGetState
 * @see vsMenuInsert
 * @see vsMenuLoad
 * @see vsMenuQInfo
 * @see vsMenuSet
 * @see vsMenuSetState
 * @see vsMenuShow
 *
 * @appliesTo MDI_Window, Form
 *
 * @categories Form_Methods, MDI_Window_Methods, Menu_Functions
 *
 */
int VSAPI vsMenuSet(int wid,int menu_handle);
/**
 * Sets menu item values for the menu items which contain the command
 * or category specified.
 *
 * @return Returns 0 if successful.
 *
 * @param menu_handle	Handle of loaded menu returned by
 * <b>vsMenuLoad</b>.
 *
 * @param pszFindCommand	Command or category of menu item
 * to find.  If a command is specified, the
 * command must match exactly.  See
 * <i>by_category</i> parameter.
 *
 * @param by_category	May be 'M', 'C', 'P'.  If the 'M' option is
 * given, <i>psaFindCommand</i> is the
 * command of the menu item to be found. If
 * the 'C' option is given,
 * <i>pszFindCommand</i> is the category of
 * the menu item to be found.  If the 'P' option
 * is given, <i>pszFindCommand</i> is an
 * integer (you must cast <i>pszFindCommand
 * </i>to int) position
 * (0..<b>vsMenuQInfo</b>(<i>menu_handle
 * </i>)-1) of the menu item with in
 * <i>menu_handle</i>.  Defaults to 'C'.
 *
 * @param mf_flags may be zero or more of the
 * following flags defined in "vs.h":
 *
 * <ul>
 * <li>VSMF_CHECKED</li>
 * <li>VSMF_UNCHECKED</li>
 * <li>VSMF_GRAYED</li>
 * <li>VSMF_ENABLED</li>
 * <li>VSMF_SUBMENU</li>
 * </ul>
 *
 * @param pszItemText	Menu item title.
 *
 * @param pszCategory	Menu item categories. May be one or more
 * categories separated with a '|' character.  See
 * <b>vsMenuSetState</b> function for more
 * information about categories.
 *
 * @param pszHelpCommand	Menu item help command.
 * Executed when F1 is pressed while on the
 * menu item.
 *
 * @param pszHelpMessage	Menu item help message.  Displayed when
 * menu item is selected.
 *
 * @example
 * <pre>
 * void VSAPI dllproc ()
 * {
 *     // Gray out all menu items which are not allowed when there
 *     // no child windows.
 *     vsMenuSetState(
 *            vsPropGetI(VSWID_MDI,VSP_MENUHANDLE),
 *            "new",VSMF_GRAYED,'M');
 * }
 * </pre>
 *
 * @see vsMenuDelete
 * @see vsMenuDestroy
 * @see vsMenuFind
 * @see vsMenuGetState
 * @see vsMenuInsert
 * @see vsMenuLoad
 * @see vsMenuQInfo
 * @see vsMenuSet
 * @see vsMenuSetState
 * @see vsMenuShow
 *
 * @categories Menu_Functions
 *
 */
int VSAPI vsMenuSetState(int menu_handle,const char *pszFindCommand,
                         int flags,char by_category,
                         const char *pszItemText VSDEFAULT(0),
                         const char *pszCommand VSDEFAULT(0),const char *pszCategory VSDEFAULT(0),
                         const char *pszHelpCommand VSDEFAULT(0),const char *pszHelpString VSDEFAULT(0));
#define VSMF_CHECKED         1
#define VSMF_UNCHECKED       2
#define VSMF_GRAYED          4
#define VSMF_ENABLED         8
#define VSMF_SUBMENU         16

#define VSVPM_LEFTBUTTON   0x0000
#define VSVPM_RIGHTBUTTON  0x0002
#define VSVPM_LEFTALIGN    0x0000
#define VSVPM_CENTERALIGN  0x0004
#define VSVPM_RIGHTALIGN   0x0008
/**
 * Displays/runs menu as pop-up.  All menu items should be
 * grayed/checked before calling this function.  This function does not
 * return until the menu is closed.
 *
 * @return Returns 0 if successful.
 *
 * @param menu_handle	Handle of loaded menu returned by
 * <b>vsMenuLoad</b>.
 *
 * @param vpm_flags Defaults to
 * VPM_LEFTBUTTON|VPM_LEFTALIGN.
 *
 * @param vpm_flags may be zero or more of
 * the following flags defined in "slick.sh":
 *
 * <dl>
 * <dt>VSVPM_LEFTBUTTON</dt><dd>
 * 	Track menu items with left mouse button.</dd>
 * <dt>VSVPM_RIGHTBUTTON</dt><dd>
 * 	Track menu items with right mouse button.</dd>
 * <dt>VSVPM_LEFTALIGN</dt><dd>
 * 	<i>x</i> coordinate represents left most
 * corner of menu.</dd>
 * <dt>VSVPM_CENTERALIGN</dt><dd>
 * 	<i>x</i> coordinate represents horizontal
 * center of menu</dd>
 * <dt>VSVPM_RIGHTALIGN</dt><dd>
 * 	<i>x</i> coordinate represents right side of
 * menu.</dd>
 * </dl>
 *
 * @param x x coordinate of left side of menu.
 *
 * @param y y coordinate of top of menu.
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *    // Low-level code to display SlickEdit menu bar as pop-
 * up.
 *    // Could just use show or mou_show_menu function.
 *    index=vsFindIndex("_mdi_menu",vsoi2type(OI_MENU))
 *    if (!index) {
 *        vsMessage("Can't find _mdi_menu");
 *    }
 *    int menu_handle;
 *    menu_handle=vsMenuLoad(VSWID_MDI,index,'P');
 *    // Display this menu at top left of screen.
 *    int flags;
 *    flags=VSVPM_CENTERALIGN|VSVPM_LEFTBUTTON;
 *    vsMenuShow(menu_handle,flags,0,0)
 *    vsMenuDestroy(menu_handle);
 * }
 * </pre>
 *
 * @see vsMenuDelete
 * @see vsMenuDestroy
 * @see vsMenuFind
 * @see vsMenuGetState
 * @see vsMenuInsert
 * @see vsMenuLoad
 * @see vsMenuQInfo
 * @see vsMenuSet
 * @see vsMenuSetState
 * @see vsMenuShow
 *
 * @categories Menu_Functions
 *
 */
int VSAPI vsMenuShow(int wid,int menu_handle,int vpm_flags,int x,int y);

/**
 * Deletes all lines in the buffer of the editor control specified.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsDeleteAll(int wid);
/**
 * <p>Saves the editor cursor position and scroll position information so that
 * it can be restored later by <b>vsRestorePos2</b>.  It is safe to make
 * edits in between calls to vsSavePos2 and vsRestorePos2.</p>
 *
 * <p>IMPORTANT:  If you do not call <b>vsRestorePos2</b>, you need to
 * call <b>vsFreeSelection</b> to free the selection allocated.</p>
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pmark_id  Ouput for mark id.
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsSavePos2(int wid,int *pmarkid);
/**
 * Restores the editor cursor position and scroll position information and
 * frees the selection.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param mark_id	mark id allocated by <b>vsSavePos2</b>.
 *
 * @categories CursorMovement_Functions
 *
 */
void VSAPI vsRestorePos2(int wid,int markid);
/**
 * Restores the editor cursor position and scroll position information.
 * <i>pbuf</i> must have been initialized by <b>vsSavePos</b>.   NO
 * EDITS should have been made to this buffer inbetween the vsSavePos
 * and vsRestorePos calls.  Use <b>vsSavePos2</b> and
 * <b>vsRestorePos2</b> to save and restore where edits are made.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pbuf	Structure initialized by <b>vsSavePos</b>.
 *
 * @categories CursorMovement_Functions
 *
 */
void VSAPI vsRestorePos(int wid,const VSSAVEPOS *pbuf);
/**
 * <p>Saves the editor cursor position and scroll position information so that
 * it can be restored later by <b>vsRestorePos</b>. NO EDITS should be
 * made to this buffer inbetween the vsSavePos and vsRestorePos calls.
 * Use <b>vsSavePos2</b> and <b>vsRestorePos2</b> to save and
 * restore where edits are made.</p>
 *
 * <p>IMPORTANT:  You do not have to call vsRestorePos after calling this
 * function or free and memory.</p>
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pbuf	Structure filled in with editor cursor position
 * and scroll position information.
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsSavePos(int wid,VSSAVEPOS *pbuf,int reserved VSDEFAULT(0));
/**
 * Returns number of replaces performed by the last search and replace
 * performed one of the following search functions:
 * <b>vsSearchPromptReplace</b>, <b>vsCommandReplace</b>, or
 * vsExecute(wid,"gui-replace").
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods, File_Functions
 *
 */
int VSAPI vsCommandReplaceQNofChanges();
/**
 * This function searches for the string specified and replaces it with the.
 * This function is almost identical to making the call
 * vsExecute(wid,"replace
 * /<i>FindString</i>/<i>ReplaceString</i>/<i>Options</i>") except
 * that <b>vsRefresh</b> is not called, a new undo step is never started,
 * and code is not generated by macro recording.
 *
 * @return Returns 0 if the search string specified is found.  Common return
 * codes are STRING_NOT_FOUND_RC, INVALID_OPTION_RC and
 * INVALID_REGULAR_EXPRESSION_RC.  On error, message is
 * displayed.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszFindString	String to find.
 *
 * @param pszReplaceString	String to replace string found with.
 *
 * @param pszOptions	String of search options.  See
 * <b>vsSearch</b> for list of most options.
 * The following addition options may be
 * specified:
 *
 * <dl>
 * <dt><i>*</i></dt><dd>Make changes without prompting.</dd>
 * <dt><I>P</I></dt><dd>Wrap to beginning/end when string not
 * found.</dd>
 * </dl>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
int VSAPI vsCommandReplace(int wid,const char *pszFindString,const char *pszReplaceString,const char *pszOptions VSDEFAULT(""));
/**
 * This function searches for the string specified.  This function is almost
 * identical to making the call vsExecute(wid,"find
 * /<i>FindString</i>/<i>Options</i>") except that <b>vsRefresh</b> is
 * not called, a new undo step is never started, and code is not generated
 * by macro recording.
 *
 * @return Returns 0 if the search string specified is found.  Common return
 * codes are STRING_NOT_FOUND_RC, INVALID_OPTION_RC and
 * INVALID_REGULAR_EXPRESSION_RC.  On error, message is
 * displayed.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszFindString	String to find.
 *
 * @param pszOptions	String of search options.  See
 * <b>vsSearch</b> for list of most options.
 * The following addition options may be
 * specified.
 *
 * @param P	Wrap to beginning/end when string not
 * found.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
int VSAPI vsCommandFind(int wid,const char *pszFindString,const char *pszOptions VSDEFAULT(""));
/**
 * <p>This function saves the buffer date from the editor control specified to
 * the output file specified.  This function is identical to making the call
 * vsExecute(wid,"save "\"pszOutputFilename\"") except that
 * <b>vsRefresh</b> is not called, a new undo step is never started, and
 * code is not generated by macro recording.</p>
 *
 * <p>The <B>VSP_MODIFY</B> property is turned off if the output
 * filename is the same as the buffer name.</p>
 *
 * @return Returns 0 if successful.  Common return codes are:
 * INVALID_OPTION_RC, ACCESS_DENIED_RC,
 * ERROR_OPENING_FILE_RC, INSUFFICIENT_DISK_SPACE_RC,
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC,
 * DRIVE_NOT_READY_RC, and PATH_NOT_FOUND_RC. On
 * error, message displayed.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszOutputFilename	Specifies name of output file.  If this
 * is 0, the buffer name (VSP_BUFNAME) is
 * used.
 *
 * @param pszOptions	A string of zero or more of the following
 * switches delimited with a space:
 *
 * <p>Note that since record files are saved in binary (always with the +B
 * switch), many options have no effect.</p>
 *
 * <dl>
 * <dt>+ or -E</dt><dd>Turn on/off expand tabs to spaces switch.  Default
 * is off.</dd>
 *
 * <dt>+ or -G</dt><dd>Turn on/off setting of all old numbers.  Default is
 * off.  SlickEdit uses old line numbers to
 * better handle going to an error line after lines have
 * been inserted or deleted.  We don't recommend
 * setting the old line numbers on every save because
 * this requires that you do not save the file until you
 * have performed edits for all compile or multi-file
 * search messages.  See
 * <b>_SetAllOldLineNumbers</b> method for more
 * information.</dd>
 *
 * <dt>+ or -S</dt><dd>Strip trailing spaces on each line.  The buffer is
 * modified if the output file name matches the buffer
 * name.  Default is off.</dd>
 *
 * <dt>+ or -CL</dt><dd>Check maximum line length.  Default is off.  If the
 * destination file is requires a record length (an
 * OS/390 dataset member), lines are checked against
 * this record length.  Otherwise, line lengths are
 * checked against the <b>p_MaxLineLength</b>
 * property.  If there are any lines that are too long, an
 * error code is returned and a message box is
 * displayed with a list of the offending line numbers.
 * At the moment only the physical line length is
 * checked as if tab characters count as 1 character.
 * We may change this in the future.</dd>
 *
 * <dt>+FU</dt><dd>Save file in UNIX ASCII format (Lines ending with
 * just 10 character).  The buffer is modified if the
 * output file name matches the buffer name.</dd>
 *
 * <dt>+FD</dt><dd>Save file in DOS  ASCII format (Lines ending with
 * 13,10).  The buffer is modified if the output file
 * name matches the buffer name.</dd>
 *
 * <dt>+FM</dt><dd>Save file in Macintosh ASCII format (Lines ending
 * with just 13 character).  The buffer is modified if
 * the output file name matches the buffer name.</dd>
 *
 * <dt>+<i>ddd</i></dt><dd>Save file without line end characters and pad or
 * truncate lines so that each line is <i>ddd</i>
 * characters in length.  Use this option to generate of
 * fixed length record file.</dd>
 *
 * <dt>+FR</dt><dd>Save file without line end characters.</dd>
 *
 * <dt>+F<i>ddd</i></dt><dd>Save file using ASCII character <i>ddd</i> as the
 * line end character.  The buffer is modified if the
 * output file name matches the buffer name.</dd>
 *
 * <dt>+ or -B</dt><dd>Binary switch.  Save file exactly byte per byte as it
 * appears in the buffer.  This option overrides all save
 * options which effect bytes in the input or output.
 * This option is always on for record buffers.
 * Defaults to value of <b>p_binary</b> property for
 * other buffers.</dd>
 *
 * <dt>+ or -O</dt><dd>Overwrite destination switch (no backup).  Default
 * is off.  Useful for writing a file to a device such as
 * the printer.</dd>
 *
 * <dt>+ or -T</dt><dd>Compress saved file with tab increments of 8.
 * Default is off.</dd>
 *
 * <dt>+ or -ZR</dt><dd>Remove end of file marker (Ctrl+Z).  This option is
 * ignored if the current buffer is not a DOS ASCII
 * file.  The buffer is modified if the
 * <b>p_showeof</b> is true and the output file name
 * matches the buffer name.  Default is off.</dd>
 *
 * <dt>+ or -Z</dt><dd>Add end of file marker (Ctrl+Z).  Note that if a
 * buffer has a visible EOF character, the output file
 * will still have an EOF character.  Use +ZR to
 * ensure that the output file does not have and EOF
 * character.  Default is off.</dd>
 *
 * <dt>+ or -L</dt><dd>Reset line modify flags.  Default is off.</dd>
 *
 * <dt>+ or -N</dt><dd>Don't save lines with the VSLF_NOSAVE bit set.
 * When the editor keeps track of whether a buffer has
 * lines with the VSLF_NOSAVE bit set, we will not
 * need this option.</dd>
 *
 * <dt>+ or -A</dt><dd>Convert destination filename to absolute.  Default
 * is on.  This option is currently used to write files to
 * device names such as PRN.  For example,
 * "_save_file +o -a +e prn" sends the current buffer
 * to the printer.</dd>
 *
 * <dt>+DB, -DB, +D,-D,+DK,-DK</dt><dd>
 * 	These options specify the backup style.  The default
 * backup style is +D.  The backup styles are:
 *
 * <dl>
 * <dt>+DB, -DB</dt><dd>Write backup files into the same directory as the
 * destination file but change extension to ".bak".
 *
 * <dt>+D</dt><dd>When on, backup files are placed in a single
 * directory.  The default backup directory is
 * "\vslick\backup\" (UNIX:
 * "$HOME/.vslick/backup") . You may define an
 * alternate backup directory by defining an
 * environment variable called VSLICKBACKUP.
 * The VSLICKBACKUP environment variable may
 * contain a drive specifier. The backup file gets the
 * same name part as the destination file.  For
 * example, given the destination file
 * "c:\project\test.c" (UNIX: "/project/test.c") , the
 * backup  file will be "c:\vslick\backup\test.c"
 * (UNIX: "$HOME/.vslick/backup/test.c").<br><br>
 *
 * <b>Non-UNIX platforms</b>: For a network, you
 * may need to create the backup directory with
 * appropriate access rights manually before saving a
 * file.</dd>
 *
 * <dt>-D</dt><dd>When on, backup file directories are derived from
 * concatenating a backup directory with the path and
 * name of the destination file.  The default backup
 * directory is "\vslick\backup\" (UNIX:
 * "$HOME/.vslick").  You may define an alternate
 * backup directory by defining an environment
 * variable called VSLICKBACKUP.  The
 * VSLICKBACKUP environment variable may
 * contain a drive specifier.  For example, given the
 * destination file "c:\project\test.c", the backup file
 * will be "c:\vslick\backup\project\test.c" (UNIX:
 * "$HOME/.vslick/backup/project/test.c").<br><br>
 *
 * <b>Non-UNIX platforms</b>: For a network, you may
 * need to create the backup directory with appropriate
 * access rights manually before saving a file.</dd>
 *
 * <dt>+DK,-DK</dt><dd>When on, backup files are placed in a directory off
 * the same directory as the destination file.  For
 * example, given the destination file
 * "c:\project\test.c" (UNIX: "$HOME/.vslick"), the
 * backup file will be "c:\project\backup\test.c"
 * (UNIX: "/project/backup/test.c").  This option
 * works well on networks.</dd>
 * </dl>
 * </dl>
 *
 * @example
 * <pre>
 * 	    // Expand tabs and write buffer to temporary file.
 * 	    vsCommandSave (0,"tempfile","+E");
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods, File_Functions
 *
 */
int VSAPI vsCommandSave(int wid,const char *pszOutputFilename VSDEFAULT(0), const char *pszOptions VSDEFAULT(0));
/**
 * <p>This function changes the buffer name.  Use this function instead of
 * the VSP_BUFNAME property if you want various edit hook callbacks
 * and/or your filename converted to absolute.</p>
 *
 * <p>This function is almost identical to making the call
 * vsExecute(wid,"name \"<i>Filename\"</i> ") except that
 * <b>vsRefresh</b> is not called, a new undo step is never started, and
 * code is not generated by macro recording.</p>
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszFilename	New buffer name.  Filename is converted to
 * absolute.
 *
 * <p>This function changes the buffer name.  Use this function instead of
 * the VSP_BUFNAME property if you want various edit hook callbacks
 * and/or your filename converted to absolute.</p>
 *
 * <p>This function is almost identical to making the call
 * vsExecute(wid,"name \"<i>Filename\"</i> ") except that
 * <b>vsRefresh</b> is not called, a new undo step is never started, and
 * code is not generated by macro recording.</p>
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods, File_Functions
 *
 */
void VSAPI vsCommandName(int wid,const char *pszFilename);
/**
 * Sets the language specific information such as tabs, margins,
 * color coding, etc. to the specified language's options.
 *
 * @param wid	         Window id of editor control.
 *                      0 specifies the current object.
 * @param pszLangId     Language ID.  See {@link p_LangId}.
 *                      For list of language types,
 *                      use our Language Options dialog
 *                      ("Tools", "Options","Language Setup...").
 *
 * @categories Edit_Window_Methods
 * @deprecated Use {@link vsSetEditorLanguage()}.
 */
void VSAPI vsSelectEditMode(int wid,const char *pszLangId VSDEFAULT(0),int reserved VSDEFAULT(0));
/**
 * Sets the language specific information such as tabs, margins,
 * color coding, etc. to the specified language's options.
 *
 * @param wid	         Window id of editor control.
 *                      0 specifies the current object.
 * @param pszLangId     Language ID.  See {@link p_LangId}.
 *                      For list of language types,
 *                      use our Language Options dialog
 *                      ("Tools", "Options","Language Setup...").
 *
 * @categories Edit_Window_Methods
 */
void VSAPI vsSetEditorLanguage(int wid,const char *pszLangId VSDEFAULT(0),int reserved VSDEFAULT(0));
/**
 * @return Returns a last index corresponding to option given.
 *
 * @param option	Indicates last index information to return.
 *
 * <dl>
 * <dt>'C'</dt><dd>Returns the index of the last command or
 * function executed by a key,
 * <b>vsCallKey</b>, or <b>vsExecute</b>.<br><br>
 *
 * Note that this is different than the Slick-C&reg;
 * <b>last_index</b> function which updates
 * this value when <b>call_index</b> is
 * called.  Call <b>vsSetLastIndex</b> to
 * explicitly update this value.</dd>
 *
 * <dt>'L'</dt><dd>Returns the index of the last command or
 * function executed by a key or the
 * <b>vsCallKey</b> function.</dd>
 *
 * <dt>'K'</dt><dd>Returns the index of the last event table used
 * to determine a key binding.</dd>
 *
 * <dt>'W'</dt><dd>Returns the command line/menu wait value.
 * This flag is used by a command to determine
 * whether it was invoke by <b>vsExecute</b>
 * (command line or menu) or a key press.
 * This flag is set to non-zero when
 * <b>vsExecute</b> is called and 0 when a
 * key is pressed or <b>vsCallKey</b> is
 * called.</dd>
 *
 * @see vsQLastIndex
 * @see vsQPrevIndex
 * @see vsSetLastIndex
 * @see vsSetPrevIndex
 *
 * @categories Keyboard_Functions
 *
 */
int VSAPI vsQLastIndex(char option  /* K W C P */);
/**
 * @return Sets a last index corresponding to <i>option</i> given.
 *
 * @param option	Indicates last index information to Set.
 *
 * <dl>
 * <dt>'C'</dt><dd>Set the index of the last command or
 * function executed by a key,
 * <b>vsCallKey</b>, or <b>vsExecute</b>.</dd>
 *
 * <dt>'L'</dt><dd>Set the index of the last command or
 * function executed by a key or the
 * <b>vsCallKey</b> function.</dd>
 *
 * <dt>'K'</dt><dd>Set the index of the last event table used to
 * determine a key binding.</dd>
 *
 * <dt>'W'</dt><dd>Set the command line/menu wait value.
 * This flag is used by a command to determine
 * whether it was invoke by <b>vsExecute</b>
 * (command line or menu) or a key press.
 * This flag is set to non-zero when
 * <b>vsExecute</b> is called and 0 when a
 * key is pressed or <b>vsCallKey</b> is
 * called.</dd>
 * </dl>
 *
 * @param index	New value for index.
 *
 * @see vsQLastIndex
 * @see vsQPrevIndex
 * @see vsSetLastIndex
 * @see vsSetPrevIndex
 *
 * @categories Keyboard_Functions
 *
 */
void VSAPI vsSetLastIndex(char option  /* K W C P */,int index);
/**
 * @return Returns a last index corresponding to <i>option</i> given.
 *
 * @param option	Indicates last index information to return.
 *
 * <dl>
 * <dt>'C'</dt><dd>Returns the index of the previous command
 * or function executed by a key,
 * <b>vsCallKey</b>, or <b>vsExecute</b>.
 * Use this value to determine if your
 * command was executed multiple times in a
 * row (see example below).  For example,
 * several clipboard commands perform
 * append to clipboard when they realize they
 * have been executed multiple times in a row.<br><br>
 *
 * Note that this is different than the Slick-C&reg;
 * <b>prev_index</b> function which updates
 * this value when <b>call_index</b> is
 * called.  Call <b>vsSetPrevIndex</b> to
 * explicitly update this value.</dd>
 *
 * <dt>'L'</dt><dd>Returns the index of the previous command
 * or function executed by a key or the
 * <b>vsCallKey</b> function.</dd>
 *
 * @example
 * <pre>
 * 	    void VSAPI mycommand()
 * 	    {
 * 	          char szTemp[VSMAXNAME];
 * 	          int InvokedTwiceInRow;
 * 	          InvokeTwiceInRow=strcmp(vsNameName(
 * 	                        vsQPrevIndex('C'),szTemp,VSMAXNAME),
 * 	                        "mycommand"
 * 	                       )==0;
 * 	    }
 * </pre>
 *
 * @see vsQLastIndex
 * @see vsQPrevIndex
 * @see vsSetLastIndex
 * @see vsSetPrevIndex
 *
 * @categories Keyboard_Functions
 *
 */
int VSAPI vsQPrevIndex(char option  /* C P */);
/**
 * @return Returns a last index corresponding to <i>option</i> given.
 *
 * @param option	Indicates last index information to return.
 *
 * <dl>
 * <dt>'C'</dt><dd>Set the index of the previous command or
 * function executed by a key,
 * <b>vsCallKey</b>, or <b>vsExecute</b>.</dd>
 *
 * <dt>'L'</dt><dd>Set the index of the previous command or
 * function executed by a key or the
 * <b>vsCallKey</b> function.</dd>
 * </dl>
 *
 * @param index	New value for index.
 *
 * @see vsQLastIndex
 * @see vsQPrevIndex
 * @see vsSetLastIndex
 * @see vsSetPrevIndex
 *
 * @categories Keyboard_Functions
 *
 */
void VSAPI vsSetPrevIndex(char option  /* C P */,int index);
/**
 * @return Returns a last event.  Last event is set when a key is pressed.  This
 * function is typically used by a command which wants to know what
 * key it was invoked by.
 *
 * @param NewLastEvent	If this is not VSEV_NULL, the last event
 * is set to this value.
 *
 * @see vsCallKey
 * @see vsEvent2Name
 * @see vsEvent2Index
 * @see vsIndex2Event
 * @see vsEventTabIndex
 * @see vsSetEventTabIndex
 *
 * @categories Keyboard_Functions
 *
 */
int VSAPI vsQLastEvent(int NewLastEvent VSDEFAULT(VSEV_NULL),int version VSDEFAULT(0));
/**
 * @return Returns x position of mouse for last mouse event.    This function is
 * typically used by a command or function which is bound to a mouse
 * event, to determine where the mouse was when the event occurred.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param option	'D' specifies to return the position of mouse
 * in pixels relative to the screen.  '\0' specifies
 * to return the position of the mouse in pixels
 * relative to the window specified.  'M'
 * specifies to return the position in the scale
 * mode (VSP_SCALEMODE) of <i>wid</i>
 * relative to the window specified.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Mouse_Functions
 *
 */
int VSAPI vsMouQLastX(int wid VSDEFAULT(0),char option VSDEFAULT('D'));
/**
 * @return Returns y position of mouse for last mouse event.    This function is
 * typically used by a command or function which is bound to a mouse
 * event, to determine where the mouse was when the event occurred.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param option	'D' specifies to return the position of mouse
 * in pixels relative to the screen.  '\0' specifies
 * to return the position of the mouse in pixels
 * relative to the window specified.  'M'
 * specifies to return the position in the scale
 * mode (VSP_SCALEMODE) of <i>wid</i>
 * relative to the window specified.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Mouse_Functions
 *
 */
int VSAPI vsMouQLastY(int wid VSDEFAULT(0),char option VSDEFAULT('D'));

/**
 * Sets last global mouse x,y position<p> returned by 
 * vsMouQLastX and vsMousQLastY functions 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Mouse_Functions
 * @param global_x   Global pixel x position
 * @param global_y   Global pixel y position
 */
void VSAPI vsMouSetLastXY(int global_x, int global_y);
/**
 * @return Returns 'true' if the position of the mouse for the last event
 *         falls within the given rect, with respect to the coordinates
 *         of the given window ID.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param option	'D' specifies to return the position of mouse
 * in pixels relative to the screen.  '\0' specifies
 * to return the position of the mouse in pixels
 * relative to the window specified.  'M'
 * specifies to return the position in the scale
 * mode (VSP_SCALEMODE) of <i>wid</i>
 * relative to the window specified.
 *
 * @param top     Top of rectangle
 * @param bottom  Bottom of retangle
 * @param left    Left hand side of rectangle
 * @param right   Right hand size of rectnagle
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Mouse_Functions
 */
int VSAPI vsMouQLastInRect(int wid,char option,int top,int bottom,int left,int right);
/**
 * @return If successful, returns 0 and places current word in <i>pszWord</i>.
 * Otherwise a non-zero value is returned.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszWord	Ouput buffer for current word.  This can be
 * 0.
 *
 * @param MaxWordLen	Number of characters allocated to
 * <i>pszWord</i>.  We recommend
 * VSMAXCURWORD.
 *
 * @param pPhysicalStartCol	Recieves physical start column
 * (1..vsQLineLength()) of word.
 *
 * @param option	May be one of the following:
 *
 * <dl>
 * <dt>0</dt><dd>If the cursor is on a word character, all of
 * that word is returned.  If the cursor is not on
 * a word character and a word exists after the
 * cursor, that word is returned.  If the cursor is
 * not on a word character and a word does not
 * exist after the cursor, the previous word is
 * returned.  If no words exist on the current
 * line, a non-zero status is returned.</dd>
 *
 * <dt>1</dt><dd>(EMACS style) Same as 0 except that if
 * cursor is on a word character, no word
 * characters before the current character are
 * returned.</dd>
 *
 * <dt>2</dt><dd>Same as 0 except when the cursor is setting
 * on the first non-word character after a word
 * character, the previous word is returned.
 * <i>pMaxWordLen</i>	If this is not 0, this is set to the number of
 * characters you need to allocate to
 * <i>pszWord</i>.</dd>
 * </dl>
 *
 * @see vsMouCurWord
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsCurWord(int wid,char *pszWord,int MaxWordLen,
              int *pPhyiscalStartCol VSDEFAULT(0),
              int option VSDEFAULT(0) /* 1 from cursor, 2- end prev word*/,
              int *pMaxWordLen VSDEFAULT(0));
/**
 * @return If successful, returns 0 and places word or selection at location (x,y) in
 * <i>pszWord</i>.  Otherwise a non-zero value is returned.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param <i>x</i>, <i>y</i>	Pixel coordinates under which to check for
 * word or selection.
 *
 * @param XYAreInScreenCoordinates
 * 	If this is not zero, (<i>x</i>,<i>y</i>) are in
 * screen coordinates, otherwise
 * (<i>x</i>,<i>y</i>) are relative to the editor
 * control specified by <i>wid</i>.
 *
 * @param MaybeReturnSelectedText
 * 	If non-zero and a single line of selected text
 * exists under (<i>x</i>,<i>y</i>), the
 * selected text is returned.  Otherwise, the
 * word under (<i>x</i>,<i>y</i>) is returned.
 *
 * @param pszWord	Ouput buffer for word.  This can be 0.
 *
 * @param MaxWordLen	Number of characters allocated to
 * <i>pszWord</i>.  We recommend
 * VSMAXCURWORD.
 *
 * @param pPhysicalStartCol	Recieves physical start column
 * (1..vsQLineLength()) of word.
 *
 * @param option	May be one of the following:
 *
 * <dl>
 * <dt>0</dt><dd>If the cursor is on a word character, all of
 * that word is returned.  If the cursor is not on
 * a word character and a word exists after the
 * cursor, that word is returned.  If the cursor is
 * not on a word character and a word does not
 * exist after the cursor, the previous word is
 * returned.  If no words exist on the current
 * line, a non-zero status is returned.</dd>
 *
 * <dt>1</dt><dd>(EMACS style) Same as 0 except that if
 * cursor is on a word character, no word
 * characters before the current character are
 * returned.</dd>
 *
 * <dt>2</dt><dd> Same as 0 except when the cursor is setting
 * on the first non-word character after a word
 * character, the previous word is returned.
 * <i>pMaxWordLen</i>	If this is not 0, this is set to the number of
 * characters you need to allocate to
 * <i>pszWord</i>.</dd>
 * </dl>
 *
 * @example
 * <pre>
 * extern "C" void VSAPI vsDllInit()
 * {
 *      vsDllExport("void mymouse_move()",0,0);
 *      int index;
 *
 *      index=vsFindIndex("mymouse_move",VSTYPE_PROC|VSTYPE_COMMAND);
 *      if (index) {
 *           // Bind this function to a mouse move event.
 *            vsSetEventTabIndex(vsQDefaultEventTab(),
 *                           vsEvent2Index(VSEV_MOUSE_MOVE),
 *                           index);
 *
 *      }
 * }
 * extern "C" void VSAPI mymouse_move()
 * {
 *      // IF the current object is not an editor control object.
 *      //  Could check for VSP_OBJECT==VSOI_EDITOR, but this won't work
 *      // for MDI Child use of the editor control which will return VSOI_FORM.
 *      if (!vsPropGetI(0,VSP_HASBUFFER)>=0) return;
 *      char word[VSMAXCURWORD];
 *
 *      vsMouCurWord(0,vsMouQLastX(),vsMouQLastY(),1,1,word,VSMAXCURWORD);
 *      vsMessage(word);
 * }
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Mouse_Functions
 *
 */
int VSAPI vsMouCurWord(int wid,int x,int y,
                 int XYAreInScreenCoordinates,
                 int MaybeReturnSelectedText,
                 char *pszWord,int MaxWordLen,
                 int *pPhyiscalStartCol VSDEFAULT(0),
                 int option VSDEFAULT(0) /* 1 from cursor, 2- end prev word*/,
                 int *pMaxWordLen VSDEFAULT(0));

/**
 * Gets the line (and optionally column) that the mouse pointer is sitting over.
 * This function is only valid when <i>wid</i> is an editor control.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param <i>x</i>, <i>y</i>	Pixel coordinates under which to check for
 * word or selection.
 *
 * @param XYAreInScreenCoordinates
 * 	If this is not zero, (<i>x</i>,<i>y</i>) are in screen coordinates,
 *    otherwise (<i>x</i>,<i>y</i>) are relative to the editor control
 *    specified by <i>wid</i>.
 *
 * @param piLine pointer to variable where the line number will be stored.
 *    If the line position is not valid, a negative number will be filled in
 * @param piCol (optional) pointer to int variable where the colum number will be stored
 *    If the column position is not valid, a negative number will be filled in
 * @param piReserved1
 *    Reserved for future use
 * @param piReserved2
 *    Reserved for future use
 * @param iReserved3
 *    Reserved for future use
 */
int VSAPI vsMouPos(int wid,int mou_x,int mou_y,
                   int XYAreInScreenCoordinates,
                   seSeekPos *piLine,int *piCol=0,
                   seSeekPos *piRealLine=0,
                   int *piReserved2=0,
                   int iReserved3=0
                   );

int vsMouQPointer(int wid,int mou_x,int mou_y,int XYAreInScreenCoordinates,int markid,int DefaultMousePointer);
/**
 * @return This function is used to return command function VSARG2_???
 * attributes.  See "vs.h" for list of VSARG2_??? constants.
 *
 * @attention
 * This function is thread-safe.
 *
 * @see vsFindIndex
 * @see vsNameMatch
 * @see vsNameName
 * @see vsNameType
 * @see vsNameInfo
 * @see vsFindNameInfo
 * @see vsNameSetInfo
 * @see vsNameInfoArg2
 * @see vsCallIndex
 * @see vsNameInsert
 * @see vsNameReplace
 * @see vsNameDelete
 * @see vsNameCallable
 * @see vsNameDllAddr
 *
 * @categories Names_Table_Functions
 *
 */
int VSAPI vsNameInfoArg2(int index);
/**
 * <p>This function creates an editor window and buffer.  Use this function
 * when you want to do editor processing on a file but you do not want a
 * visible window created.  Use the <b>vsActivateWindow</b> and/or the
 * VSP_WINDOWID property to switch windows.  The call
 * <b>vsPropGetI</b>(0,VSP_WINDOWID) returns the current window id.</p>
 *
 * @param pTempWindowId	Set to newly created window id.
 * <i>pOrigWindowId</i>	Set to current window id.  There is always a
 * valid current window id.
 *
 * @example
 * <pre>
 * int status, temp_window_id, orig_window_id;
 * status=vsCreateTempView(&temp_window_id,&orig_window_id);
 * if (status) {
 *     return(status);
 * }
 * vsInsertLine(0,"Insert text into temp window");
 * // Free window and buffer
 * vsDeleteTempView(temp_window_id);
 * vsActiveWindow(orig_window_id);
 * </pre>
 *
 * @return If successful, returns 0 and the temp window/buffer is active.
 * Otherwise a negative error code is returned.
 *
 * @see vsDeleteTempView
 * @see vsOpenTempView
 *
 * @categories Buffer_Functions, File_Functions
 *
 */
int VSAPI vsCreateTempView(int *pTempWindowId,int *pOrigWindowId VSDEFAULT(0),const char *pszReserved VSDEFAULT(0));
/**
 * This function deletes the window and optionally deletes the buffer
 * attatched to that window.
 *
 * @param TempWindowId	Window id to delete.
 *
 * @param doDeleteBuffer	When <i>doDeleteBuffer</i> is 0, the
 * buffer is never deleted.  When
 * doDeleteBuffer is 1, the buffer is deleted
 * ONLY if it is a hidden buffer
 * (VSBUFFLAG_HIDDEN) not currently
 * being displayed in an editor control.  A non-
 * hidden buffer indicates that it is an MDI
 * Child edit window buffers.
 *
 * @see vsCreateTempView
 * @see vsOpenTempView
 *
 * @categories Buffer_Functions, File_Functions
 *
 */
void VSAPI vsDeleteTempView(int TempWindowId,int doDeleteBuffer VSDEFAULT(1));
/**
 * <p>This function creates an editor window which is linked to an existing or
 * new buffer.  Use this function when you want to do editor processing
 * on a file but you do not want a visible window created.  Use the
 * <b>vsActiveWindow</b> and/or the VSP_WINDOWID property to switch
 * windows.  The call <b>vsPropGetI</b>(0,VSP_WINDOWID) returns the
 * current window id.</p>
 *
 * @return If successful, returns 0 and the temp window/buffer is active.
 * Otherwise a negative error code is returned.
 *
 * @param pszFilename	Name of file to process.
 *
 * @param pTempWindowId	Set to newly created window id.
 *
 * @param pOrigWindowId	Set to current window id.  There is always a
 * valid current window id.
 *
 * @param pszLoadOption File load options
 * <dl compact>
 * <dt>""</dt><dd>Display existing buffer or read
 * <i>pszFilename</i> from disk.</dd>
 *
 * <dt>"+bi <i>buf_id></i>"</dt><dd>Ignore <i>pszFilename</i> and
 * create new window of buffer corresponding to
 * <i>buf_id</i>.</dd>
 *
 * <dt>"+d"</dt><dd>Always read <i>pszFilename</i> from disk
 * even if this file is already loaded in the
 * editor.</dd>
 *
 * <dt>"+b"</dt><dd>Only succeed if a buffer already exists of the
 * name <i>pszFilename</i>.</dd>
 * </dl>
 *
 * @param pszOpenOption File open options
 * <dl compact>
 * <dt>C</dt><dd>Clear the buffer.</dd>
 * <dt>M</dt><dd>Select the editing mode for this file.</dd>
 * <dt>X</dt><dd>If the file is not found, a new file is created.
 * <dt>L</dt><dd>Specifies that select edit mode will be called later,
 *                      but the file should have the correct load options initialized.
 * <dt>T</dt><dd>Throw away changes when temp view is closed.
 * </dl>
 *
 * @see vsDeleteTempView
 * @see vsCreateTempView
 *
 * @categories Buffer_Functions, File_Functions
 *
 */
int VSAPI vsOpenTempView(const char *pszFilename,
                         int *pTempWindowId,int *pOrigWindowId VSDEFAULT(0),
                         const char *pszLoadOption VSDEFAULT(0),
                         const char *pszOpenOption VSDEFAULT(0));

/**
 * @return Returns names table index of default event table.  This is typically
 * used to get and set key bindings global to all modes for the current
 * emulation.
 *
 * @example
 * <pre>
 *    int index;
 *
 * index=vsFindIndex("gui_open",VSTYPE_PROC|VSTYPE_COM
 * MAND);
 *    if (index) {
 *       // Bind this function to a F12
 *        vsSetEventTabIndex(vsQDefaultEventTab(),
 *                           vsEvent2Index(VS_OFFSET_FKEYS+11),
 *                           index);
 *
 *    }
 * </pre>
 *
 * @categories Keyboard_Functions
 *
 */
int VSAPI vsQDefaultEventTab();

#define VSIDOK                0x00000400
#define VSIDSAVE              0x00000800
#define VSIDSAVEALL           0x00001000
#define VSIDOPEN              0x00002000
#define VSIDYES               0x00004000
#define VSIDYESTOALL          0x00008000
#define VSIDNO                0x00010000
#define VSIDNOTOALL           0x00020000
#define VSIDABORT             0x00040000
#define VSIDRETRY             0x00080000
#define VSIDIGNORE            0x00100000
#define VSIDCLOSE             0x00200000
#define VSIDCANCEL            0x00400000
#define VSIDDISCARD           0x00800000
#define VSIDHELP              0x01000000
#define VSIDAPPLY             0x02000000
#define VSIDRESET             0x04000000
#define VSIDRESTOREDEFAULTS   0x08000000

#define VSMB_ICONMASK         0xF0000000

#define VSMB_OK               VSIDOK
#define VSMB_OKCANCEL         (VSIDOK|VSIDCANCEL)
#define VSMB_ABORTRETRYIGNORE (VSIDABORT|VSIDRETRY|VSIDIGNORE)
#define VSMB_YESNOCANCEL      (VSIDYES|VSIDNO|VSIDCANCEL)
#define VSMB_YESNO            (VSIDYES|VSIDNO)
#define VSMB_RETRYCANCEL      (VSIDRETRY|VSIDCANCEL)
#define VSMB_ICONHAND         0x10000000
#define VSMB_ICONQUESTION     0x20000000
#define VSMB_ICONEXCLAMATION  0x30000000
#define VSMB_ICONINFORMATION  0x40000000
#define VSMB_ICONSTOP         VSMB_ICONHAND
#define VSMB_ICONNONE         VSMB_ICONEXCLAMATION

/**
 * Creates a modal dialog box and displays <i>pszMessage</i> and
 * various buttons.  <i>pszMessage</i> may contain carriage return
 * characters to break a string message into multiple lines.  By default,
 * <i>pszMessage</i> is broken into multiple lines on word boundaries
 * if necessary.
 *
 * @return Returns the button id of the button pressed which closed the dialog
 * box.  One of the following constants is returned:
 *
 * <ul>
 * <li>VSIDOK</li>
 * <li>VSIDSAVE</li>
 * <li>VSIDSAVEALL</li>
 * <li>VSIDOPEN</li>
 * <li>VSIDYES</li>
 * <li>VSIDYESTOALL</li>
 * <li>VSIDNO</li>
 * <li>VSIDNOTOALL</li>
 * <li>VSIDABORT</li>
 * <li>VSIDRETRY</li>
 * <li>VSIDIGNORE</li>
 * <li>VSIDCLOSE</li>
 * <li>VSIDCANCEL</li>
 * <li>VSIDDISCARD</li>
 * <li>VSIDHELP</li>
 * <li>VSIDAPPLY</li>
 * <li>VSIDRESET</li>
 * <li>VSIDRESTOREDEFAULTS</li>
 * </ul>
 *
 * @param pszMessage	Message to display.
 *
 * @param pszTitle	Title for message box.  If 0, the default
 * application title is used.
 *
 * @param vsVSMB_flags	is a coVSMBination of zero or more VSID
 *                 button flags and VSMB_* flags:
 *
 *                 <p>Note: The VSMB_OK, VSMB_OKCANCEL, VSMB_ABORTRETRYIGNORE,
 *                 VSMB_YESNOCANCEL, VSMB_RETRYCANCEL are coVSMBinations of the VSID
 *                 button flags (ex. VSMB_OKCANCEL is VSIDOK|VSIDCANCEL)
 *                 <dl>
 *                 <dt>VSIDOK</dt><dd>Display an OK button</dd>
 *                 <dt>VSIDSAVE</dt><dd>Display a Save button</dd>
 *                 <dt>VSIDSAVEALL</dt><dd>Display a Save All button</dd>
 *                 <dt>VSIDOPEN</dt><dd>Display an Open button</dd>
 *                 <dt>VSIDYES</dt><dd>Display a Yes button</dd>
 *                 <dt>VSIDYESTOALL</dt><dd>Display a Yes to All button</dd>
 *                 <dt>VSIDNO</dt><dd>Display a No button</dd>
 *                 <dt>VSIDNOTOALL</dt><dd>Display a No to All button</dd>
 *                 <dt>VSIDABORT</dt><dd>Display an Abort button</dd>
 *                 <dt>VSIDRETRY</dt><dd>Display a Retry button</dd>
 *                 <dt>VSIDIGNORE</dt><dd>Display an Ignore button</dd>
 *                 <dt>VSIDCLOSE</dt><dd>Display a Close button</dd>
 *                 <dt>VSIDCANCEL</dt><dd>Display a Cancel button</dd>
 *                 <dt>VSIDDISCARD</dt><dd>Display a Discard button</dd>
 *                 <dt>VSIDHELP</dt><dd>Display a Help button</dd>
 *                 <dt>VSIDAPPLY</dt><dd>Display an Apply button</dd>
 *                 <dt>VSIDRESET</dt><dd>Display a Reset button</dd>
 *                 <dt>VSIDRESTOREDEFAULTS</dt><dd>Display Restore
 *                 Defaults button</dd>
 *                 <dt>VSMB_OK</dt><dd>Display an OK button.</dd>
 *                 <dt>VSMB_OKCANCEL</dt><dd>Display an OK and Cancel button.</dd>
 *                 <dt>VSMB_ABORTRETRYIGNORE</dt><dd>Display  Abort, Retry, Ignore buttons.
 *                 Not supported on UNIX.</dd>
 *                 <dt>VSMB_YESNOCANCEL</dt><dd> Display Yes, No, and Cancel buttons.</dd>
 *                 <dt>VSMB_YESNO</dt><dd>Display Yes, and No buttons.</dd>
 *                 <dt>VSMB_RETRYCANCEL</dt><dd>Display a Retry and Cancel button.
 *                 Not supported on UNIX.</dd>
 *                 <dt>VSMB_ICONHAND</dt><dd>Display a stop sign picture to the left of the message.</dd>
 *                 <dt>VSMB_ICONQUESTION</dt><dd>Display a question picture to the left of the
 *                 message.</dd>
 *                 <dt>VSMB_ICONEXCLAMATION</dt><dd>Display an exclamation point picture to the
 *                 left of the message.</dd>
 *                 <dt>VSMB_ICONINFORMATION</dt><dd>Display an 'i' picture to the left of the message.</dd>
 *                 <dt>VSMB_ICONSTOP</dt><dd>Display a stop sign picture to the left of the message.</dd>
 *                 </dl>
 *
 * @param default_button  If specified, determines which of the
 *                        buttons is the default button. One of
 *                        the following button constants:
 *
 *         <ul>
 *         <li>VSIDOK</li>
 *         <li>VSIDSAVE</li>
 *         <li>VSIDSAVEALL</li>
 *         <li>VSIDOPEN</li>
 *         <li>VSIDYES</li>
 *         <li>VSIDYESTOALL</li>
 *         <li>VSIDNO</li>
 *         <li>VSIDNOTOALL</li>
 *         <li>VSIDABORT</li>
 *         <li>VSIDRETRY</li>
 *         <li>VSIDIGNORE</li>
 *         <li>VSIDCLOSE</li>
 *         <li>VSIDCANCEL</li>
 *         <li>VSIDDISCARD</li>
 *         <li>VSIDHELP</li>
 *         <li>VSIDAPPLY</li>
 *         <li>VSIDRESET</li>
 *         <li>VSIDRESTOREDEFAULTS</li>
 *         </ul>
 *
 * @example
 * <pre>
 * result=vsMessageBox(
 *               "Save changes?",
 *               "",
 *               VSMB_YESNO|VSMB_ICONQUESTION);
 * if (result==VSIDYES) {
 *     // save the file
 * } else {
 *     // Don't save it
 * }
 * // Same as above but using VSID button flags instead of MB_OK.
 * // Also change the default button
 * result=vsMessageBox(
 *               "Save changes?",
 *               "",
 *               VSIDYES|VSIDNO|VSMB_ICONQUESTION,
 *               VSIDNO);
 * if (result==VSIDYES) {
 *     // save the file
 * } else {
 *     // Don't save it
 * }
 * </pre>
 *
 * @see vsStickyMessage
 * @see vsMessage
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsMessageBox(const char *pszMessage,const char *pszTitle VSDEFAULT(0),int vsmb_flags VSDEFAULT(VSMB_OK),int default_button VSDEFAULT(0));
/**
 * @return Returns non-zero value if this editor controls buffer type supports the
 * <b>hide_all_comments</b> command.
 *
 * @param wid	Window id of MDI frame window.
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsQhide_all_comments_enabled(int wid);
/**
 * @return Returns non-zero value if this editor controls buffer type supports the
 * <b>hide_code_block</b> command.
 *
 * @param wid	Window id of MDI frame window.
 *
 * @categories Selective_Display_Functions
 *
 */
int VSAPI vsQhide_code_block_enabled(int wid);

/**
 * @return Returns non-zero value if this editor controls
 * language mode supports tag navigation commands include
 * <b>show_procs</b>, <b>list_tags</b>,
 * <b>next_proc</b>, <b>prev_proc</b>, <b>find_tag</b>, and
 * <b>push_tag</b>.
 *
 * @param wid     Window id of MDI frame window.
 * @param lang    (optional) language id
 *
 * @categories Tagging_Functions
 */
int VSAPI vsQTaggingSupported(int wid VSDEFAULT(0), VSPSZ lang VSDEFAULT(0));

/**
 * @return Returns 'true' if the given file has support
 * for a load-tags callback function, such as for loading
 * symbols from a ZIP file or a DLL with metadata or a
 * Java class file or JAR file.
 *
 * @param pszFilename   name of file to test
 *
 * @see vsQTaggingSupported
 * @categories Tagging_Functions
 */
int VSAPI vsQBinaryLoadTagsSupported(VSPSZ pszFilename VSDEFAULT(0));

/**
 * @return Returns 'true' if the given file has support for a tagging
 * callback function or a load-tags callback function.
 *
 * @param fileName         Name of file to test
 * @param defaultLangId    Language ID of file to test
 *
 * @see vsQTaggingSupported
 * @see vsQBinaryLoadTagsSupported
 * @categories Tagging_Functions
 */
VSDLLEXPORT int SEIsTaggingSupported(const slickedit::SEString &fileName,
                                     const slickedit::SEString &defaultLangId);

/**
 * @return Returns non-zero value if the specified window is an
 *         editor control, and optionally, not a hidden window.
 *
 * @param wid                 window ID, 0 for current window
 * @param allowHiddenWindow   if false, return 0 for hidden
 *                            windows.
 *
 * @categories Editor_Control_Functions,Window_Functions
 */
int VSAPI vsIsEditorCtl(int wid,int allowHiddenWindow VSDEFAULT(1));


#define VSCLEXFLAG_OTHER        0x1
/* #define    VSCLEXFLAG_ERROR     =  0x2 */
#define VSCLEXFLAG_KEYWORD      0x4
#define VSCLEXFLAG_NUMBER       0x8
#define VSCLEXFLAG_STRING       0x10
#define VSCLEXFLAG_COMMENT      0x20
#define VSCLEXFLAG_PPKEYWORD    0x40
#define VSCLEXFLAG_LINENUM      0x80
#define VSCLEXFLAG_SYMBOL1      0x100
#define VSCLEXFLAG_PUNCTUATION  0x100
#define VSCLEXFLAG_SYMBOL2      0x200
#define VSCLEXFLAG_LIB_SYMBOL   0x200
#define VSCLEXFLAG_SYMBOL3      0x400
#define VSCLEXFLAG_OPERATOR     0x400
#define VSCLEXFLAG_SYMBOL4      0x800
#define VSCLEXFLAG_USER_DEFINED 0x800
#define VSCLEXFLAG_FUNCTION     0x1000
#define VSCLEXFLAG_NOSAVE       0x2000
#define VSCLEXFLAG_ATTRIBUTE    0x4000
#define VSCLEXFLAG_UNKNOWNXMLELEMENT  0x8000
#define VSCLEXFLAG_XHTMLELEMENTINXSL 0x10000
// WARNING: Don't add more flags unless
// you fix search flags.
#define VSCLEXFLAG_ALLFLAGS     0x1ffff


/**
 * Searches for language specific symbols or returns information about the
 * symbol at the cursor.  This function returns 0 if the p_lexer_name
 * property has not be set.
 * </P>
 *
 * @param clexflags Determines the language elements to search or to test for.
 *                  May be one or more of the following flags, which are defined
 *                  in "slick.sh."  Use the OR operator to specify more than one flag.
 *                  <UL>
 *                  <LI>VSCLEXFLAG_OTHER
 *                  <LI>VSCLEXFLAG_KEYWORD
 *                  <LI>VSCLEXFLAG_NUMBER
 *                  <LI>VSCLEXFLAG_STRING
 *                  <LI>VSCLEXFLAG_COMMENT
 *                  <LI>VSCLEXFLAG_PPKEYWORD
 *                  <LI>VSCLEXFLAG_LINENUM
 *                  <LI>VSCLEXFLAG_SYMBOL1
 *                  <LI>VSCLEXFLAG_SYMBOL2
 *                  <LI>VSCLEXFLAG_SYMBOL3
 *                  <LI>VSCLEXFLAG_SYMBOL4
 *                  <LI>VSCLEXFLAG_FUNCTION
 *                  </UL>
 *
 * @param options   options may be one of the following:
 *                  <DL compact>
 *                  <DT>O<DD>(Default) Find any of the language
 *                  elements specified.  Returns 0 and places cursor on first character of
 *                  symbol if it is found.  Otherwise, STRING_NOT_FOUND_RC is returned.
 *
 *                  <DT>N<DD>Find language elements specified which
 *                  are NOT any of the language elements specified in clexflags.  Returns 0
 *                  and placed cursor on first character of symbol if it is found.  Otherwise,
 *                  STRING_NOT_FOUND_RC is returned.
 *
 *                  <DT>T<DD>Test if symbol under cursor is any of
 *                  the language elements specified in clexflags.  Returns non-zero value if
 *                  cursor is on one of the language elements specified.
 *
 *                  <DT>G<DD>Return the color constant (NOT CLEXFLAG)
 *                  which corresponds to the symbol under the cursor.  The clexflags argument
 *                  is ignored.  Color constants are defined in "slick.sh" and may be one of
 *                  the following:
 *                  <UL>
 *                  <LI>VSCFG_WINDOW_TEXT
 *                  <LI>VSCFG_MODIFIED_LINE
 *                  <LI>VSCFG_INSERTED_LINE
 *                  <LI>VSCFG_KEYWORD
 *                  <LI>VSCFG_LINENUM
 *                  <LI>VSCFG_NUMBER
 *                  <LI>VSCFG_STRING
 *                  <LI>VSCFG_COMMENT
 *                  <LI>VSCFG_PPKEYWORD
 *                  <LI>VSCFG_PUNCTUATION
 *                  <LI>VSCFG_LIBRARY_SYMBOL
 *                  <LI>VSCFG_OPERATOR
 *                  <LI>VSCFG_USER_DEFINED
 *                  </UL>
 *
 *                  <DT>D<DD>Return the detailed color constant (NOT CLEXFLAG)
 *                  which corresponds to the symbol under the cursor.  The clexflags argument
 *                  is ignored.  This option is very similar to the 'G' option above,
 *                  except that it also recognizes the following specialized colors:
 *                  <UL>
 *                  <LI>VSCFG_LINE_COMMENT
 *                  <LI>VSCFG_DOCUMENTATION
 *                  <LI>VSCFG_IDENTIFIER
 *                  </UL>
 *
 *                  <DT>E<DD>Searches for embedded source.  Returns 0
 *                  if succesful.  Otherwise, STRING_NOT_FOUND_RC is returned.  The clexflags
 *                  argument is ignored.
 *
 *                  <DT>S<DD>Searches for non-embedded source.
 *                  Returns 0 if succesful.  Otherwise, STRING_NOT_FOUND_RC is returned.  The
 *                  clexflags argument is ignored.
 *                  </DL>
 *                  <P>
 *                  The option parameter may include a '-' (dash) character to enable the 'O'
 *                  and 'N' options to search backwards.
 *                  </P>
 *
 * @return
 * @example
 * <PRE>
 * // Find start of comment or string
 * status = vsClexFind(0,VSCLEXFLAG_COMMENT|VSCLEXFLAG_STRING);
 * if (status) {
 *    return status;
 * }
 * color = vsClexFind(0,0,'G');
 * if (color==VSCFG_COMMENT) {
 *    ...
 * }
 * // Assuming already in comment, find non-comment character
 * status = vsClexFind(0,VSCLEXFLAG_COMMENT,'N');
 * // Assuming already in comment, find non-comment character backwards
 * status = vsClexFind(0,VSCLEXFLAG_COMMENT,'N',-1);
 * </PRE>
 *
 * @see vsClexSkipBlanks
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 */
int VSAPI vsClexFind(int wid,int clexflags,char option VSDEFAULT('O'),
                     int direction VSDEFAULT(1));

/**
 * Starts from cursor position and skips over spaces, tabs, and comments.
 *
 * @param options may contain one or more of the following option letters:
 * <dl compact>
 * <dt>-<dd>Search backwards
 * <dt>m<dd>Search within selection
 * <dt>h<dd>Search through hidden lines.
 * <dt>c<dd>Skip spaces within comments
 * <dt>q<dd>Quick mode, does not test for embedded code
 * </pre>
 * </ul>
 * @return  Returns 0 if non-blank character is found, nonzero
 * otherwise. If this functions fails the cursor is moved but its final
 * location may not be the top or bottom of the buffer (we need to change
 * this should be more concrete).
 *
 * @see _clex_find
 * @see p_color_flags
 * @see _clex_load
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 */
int vsClexSkipBlanks(int wid, VSPSZ options VSDEFAULT(NULL));

int VSAPI vsQMFNextOccurrenceEnabled(int reserved VSDEFAULT(1));
/**
 * @return Returns non-zero value if the <b>find_next</b> and
 * <b>find_prev</b> commands are searching through symbol
 * references.
 *
 * @categories Search_Functions
 *
 */
int VSAPI vsQRefNextOccurrenceEnabled(int reserved VSDEFAULT(1));
int VSAPI vsQNextOccurrenceEnabled();
/**
 * @return Returns true if a menu item which executes the mflast command
 * should be enabled.
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsQmflast_enabled();
/**
 * @return Returns non-zero value if the concurrent process is still running.
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsConcurProcessQRunning();
/**
 * @return Returns non-zero value if the concurrent process command shell
 *         has exited.
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsConcurProcessQExited();
/**
 * @return Processes data in concurrent process buffer and returns non-zero value
 * if the concurrent process is still running.
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsConcurProcessQReadRunning();
/**
 * @return Processes data in concurrent process buffer and returns non-zero value
 * if the concurrent process command shell has exited.
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsConcurProcessQReadExited();
/**
 * @return Returns concurrent process read column if the current line of the
 * buffer in the editor control specified has the concurrent process read
 * point.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsConcurProcessQCol(int wid);
/**
 * @return Returns non-zero value if the buffer in the editor control specified has
 * a concurrent process attatched to it.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsConcurProcessIsThisBuffer(int wid);
/**
 * Bypasses the editor's process buffer and inputs directly into
 * running process from pszBuf. This input occurs out-of-band, which
 * means that any input data waiting to be sent from the editor's process
 * buffer will not be sent before the data in pszBuf.
 *
 * <p>
 * Currently only supported on UNIX.
 * </p>
 *
 * @param pszBuf   Char buffer to input direct to process
 *
 * @categories Miscellaneous_Functions
 */
void VSAPI vsConcurProcessInputDirect(VSPSZ pszBuf);
/**
 * @return Returns number of internal clipboards.
 *
 * @categories Clipboard_Functions
 *
 */
int VSAPI vsClipboardQNofInternal(void);

/**
 * See vsProjectQName.
 *
 * @categories Project_Functions
 *
 */
char * VSAPI vsGetProjectName(char *pszFilename,int MaxFilenameLen,int *pMaxFilenameLen VSDEFAULT(0));

/**
 * @return Returns <i>pszFilename</i>.
 *
 * @param pszFilename	Ouput buffer for workspace filename.  This
 * can be 0.
 *
 * @param MaxFilenameLen	Number of characters allocated to
 * <i>pszFilename</i>.  We recommend
 * VSMAXFILENAME.
 *
 * @param pMaxServerNameLen	If this is not 0, this is set to the exact
 * number of characters you need to allocate.
 *
 * @categories Project_Functions
 *
 */
char * VSAPI vsWorkspaceQName(char *pszFilename,int MaxFilenameLen,int *pMaxFilenameLen VSDEFAULT(0));
/**
 * @return Returns an array of ASCIIZ strings which are the relative projects
 * filenames in the current workspace.  0 is returned if an error occurs or
 * there is no workspace currently open.
 *
 * @param pNofProjects	Set to the number of projects in the current
 * workspace.  Set to zero of there is not a
 * workspace currently open.
 *
 * @param pActiveProject	Set to the index (0..NofProjects-1) of the
 * active project.  Set to -1 if no project is
 * active.
 *
 * @categories Project_Functions
 *
 */
char **VSAPI vsWorkspaceListProjects(int *pNofProjects,int *pActiveProject VSDEFAULT(0));
/**
 * @return Returns pszFilename.
 *
 * @param pszFilename	Ouput buffer for project name.  This can be
 * 0.
 *
 * @param MaxFilenameLen	Number of characters allocated to
 * <i>pszFilename</i>.  We recommend
 * VSMAXFILENAME.
 *
 * @param pMaxServerNameLen	If this is not 0, this is set to the exact
 * number of characters you need to allocate.
 *
 * @categories Project_Functions
 *
 */
char *VSAPI vsProjectQName(char *pszFilename,int MaxFilenameLen,int *pMaxFilenameLen VSDEFAULT(0));
/**
 * @return Returns an array of ASCIIZ strings which are the configrations names
 * in the current project.  0 is returned if an error occurs or there is no
 * project currently open.
 *
 * @param pNofConfigs	Set to the number of configurations in the
 * current project.  Set to zero of there is not a
 * project currently open.
 *
 * @param pActiveConfig	Set to the index (0..NofConfigs-1) of the
 * active configuration.  Set to -1 if no
 * configuration is active.
 *
 * @categories Project_Functions
 *
 */
char **VSAPI vsProjectListConfigs(int *pNofConfigs,int *pActiveConfig VSDEFAULT(0),int reserved VSDEFAULT(0), int *preserved VSDEFAULT(0));
/**
 * Converts <i>pszSrcFilename</i> to a path specification which is
 * relative to the directory specified by <i>pszToDir</i>.
 *
 * @return Returns <i>pszDestFilename</i>.
 *
 * @param pszDestFilename	Result of convert <i>pszSrcFilename</i> to
 * a relative path specification.
 *
 * @param pszSrcFilename	Filename with fully qualified path
 * specification.  This may NOT be a relative
 * path specification.
 *
 * @param pszToDir	Directory with or without trailing backslash
 * (UNIX: forward slash).  If 0 or "" is given,
 * the current directory is used.
 *
 * @param addDotDots	Indicates with ".." are allowed in the result
 * filename.
 *
 * @see vsFileAbsolute
 * @see vsFileAbsoluteTo
 * @see vsFileRelative
 *
 * @categories File_Functions
 *
 */
const char *VSAPI vsFileRelative(char *pszDestFilename,const char *pszSourceFilename,const char *pszToDir VSDEFAULT(0),int AddDotDots VSDEFAULT(1));
/**
 * Converts <i>pszSrcFilename</i> to a fully qualified path.
 *
 * @return Returns <i>pszDestFilename</i>.
 *
 * @param pszDestFilename	Result of convert <i>pszSrcFilename</i> to
 * a fully qualified path.
 *
 * @param pszSrcFilename	Filename with path specification which is
 * relative to the directory specified by
 * <i>pszToDir</i>.  This may already be fully
 * qualified.
 *
 * @param pszToDir	Directory with or without trailing backslash
 * (UNIX: forward slash).  If 0 or "" is given,
 * the current directory is used.
 *
 * @see vsFileAbsolute
 * @see vsFileAbsoluteTo
 * @see vsFileRelative
 *
 * @categories File_Functions
 *
 */
const char *VSAPI vsFileAbsoluteTo(char *pszDestFilename,const char *pszSourceFilename,const char *pszToDir  VSDEFAULT(0));
/**
 * Converts pszSrcFilename to a fully qualified path.
 *
 * @param pszDestFilename	Result of convert <i>pszSrcFilename</i> to
 * a fully qualified path.
 *
 * @param pszSrcFilename	Filename with path specification which is
 * relative to the current directory.  This may
 * already be fully qualified.
 *
 * @return Returns pszDestFilename.
 *
 * @see vsFileAbsolute
 * @see vsFileAbsoluteTo
 * @see vsFileRelative
 *
 * @categories File_Functions
 *
 */
const char *VSAPI vsFileAbsolute(char *pszDestFilename,const char *pszSourceFilename, void *preserved VSDEFAULT(0));
/**
 * Resolve link for pszSourceFilename. UNIX only. If filename does not exist, then
 * "" is returned. If filename is not a link, then original filename is returned.
 * If filename is not an absolute path, then it is assumed relative to current
 * directory.
 *
 * @param pszSourceFilename Filename to resolve link for
 *
 * @return Resolved link filename.
 *
 * @categories File_Functions
 *
 */
const char *VSAPI vsFileReadLink(const char *pszSourceFilename);
/**
 * @return Returns <i>pszResult</i>.  To set the emulation, call
 * <b>vsExecute</b> with the command "emulate <i>emu_mode</i>",
 * where <i>emu_mode</i> is one of the following value, for example,
 * "emulate vi" switches the editor into vi emulation.
 *
 * <dl>
 * <dt>Value</dt><dd>Emulation Mode</dd>
 * <dt>windows</dt><dd>Windows CUA</dt><dd>
 * <dt>emacs</dt><dd>Emacs (Epsilon)</dt><dd>
 * <dt>gnu</dt><dd>GNU Emacs</dt><dd>
 * <dt>brief</dt><dd>Brief</dt><dd>
 * <dt>vi</dt><dd>Unix VI</dt><dd>
 * <dt>slick</dt><dd>SlickEdit</dt><dd>
 * <dt>ispf</dt><dd>OS/390 ISPF</dt><dd>
 * <dt>vcpp</dt><dd>Visual C++</dt><dd>
 * </dl>
 *
 * @param pszResult	Ouput buffer for current emulation string.
 * Currently supported emulations are ""
 * (SlickEdit), "brief-keys", "emacs-keys", "vi-
 * keys", "gnuemacs-keys", "vcpp-keys"
 * (Visual C++), "ispf-keys" and "windows-
 * keys" (CUA).  This can be 0.
 *
 * @param MaxResult	Number of characters allocated to
 * <i>pszResult</i>.  We recommend
 * VSMAXEMULATION.
 *
 * @param pMaxResult	If this is not 0, this is set to the number of
 * characters you need to allocated.
 *
 * @categories Keyboard_Functions
 *
 */
char * VSAPI vsGetEmulation(char *pszResult,int MaxResult,int *pMaxResultLen VSDEFAULT(0));
void VSAPI vsguiUpdateStatusFont();
void VSAPI vsguiUpdateDocumentTabFont();
int VSAPI vsFileExists(VSPSZ pszFilename);
int VSAPI vsFileIsRemote(VSPSZ pszFilename);
int VSAPI vsFileIsWritable(VSPSZ pszFilename);

/**
 * Starts recording a macro and makes the editor control corresponding to
 * <i>wid</i> the output editor control for recorded source.
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @see cancel_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see start_recording
 * @see end_recording
 * @see list_macros
 * @see last_macro
 * @see gui_save_macro
 * @see save_macro
 * @see pause_recording
 * @see vsMacroGetFilename
 * @see vsMacroEndRecording
 * @see vsMacroQDefined
 * @see vsMacroQDefining
 * @see vsMacroQRecording
 * @see vsMacroQRecordSource
 * @see vsMacroQRunning
 * @see vsMacroSetRecordSource
 * @see vsMacroSetRunning
 * @see vsMacroStartRecording
 *
 * @categories Macro_Programming_Functions
 *
 */
void VSAPI vsMacroStartRecording(int wid);
/**
 * Terminates macro recording.  This function is used to implement our
 * macro recording commands.
 *
 * @see cancel_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see start_recording
 * @see end_recording
 * @see list_macros
 * @see last_macro
 * @see gui_save_macro
 * @see save_macro
 * @see pause_recording
 * @see vsMacroGetFilename
 * @see vsMacroEndRecording
 * @see vsMacroQDefined
 * @see vsMacroQDefining
 * @see vsMacroQRecording
 * @see vsMacroQRecordSource
 * @see vsMacroQRunning
 * @see vsMacroSetRecordSource
 * @see vsMacroSetRunning
 * @see vsMacroStartRecording
 *
 * @categories Macro_Programming_Functions
 *
 */
void VSAPI vsMacroEndRecording();
/**
 * Use this function and the <b>vsMacroQRecordSource</b> function to
 * determine whether your macro command needs to generate source
 * code.  If you have written a command, you should use
 * <b>vsMacroQRecordSource</b> to check whether you need to
 * generate source.  If your command executes another command with
 * <b>vsExecute</b> or <b>vsCallIndex</b> you may want to use
 * <b>vsMacroSetRecordSource</b> to turn on or off macro recording
 * before making the call.
 *
 * @return Returns non-zero value if a macro is currently being recorded.  This
 * will return 0 if the <b>pause_recording</b> command is called to
 * temporarily turn off recording.
 *
 * @see cancel_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see start_recording
 * @see end_recording
 * @see list_macros
 * @see last_macro
 * @see gui_save_macro
 * @see save_macro
 * @see pause_recording
 * @see vsMacroGetFilename
 * @see vsMacroEndRecording
 * @see vsMacroQDefined
 * @see vsMacroQDefining
 * @see vsMacroQRecording
 * @see vsMacroQRecordSource
 * @see vsMacroQRunning
 * @see vsMacroSetRecordSource
 * @see vsMacroSetRunning
 * @see vsMacroStartRecording
 *
 * @categories Macro_Programming_Functions
 *
 */
int VSAPI  vsMacroQRecording();
/**
 * @return Returns non-zero value if a recording macro is currently being
 * executed.
 *
 * @see cancel_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see start_recording
 * @see end_recording
 * @see list_macros
 * @see last_macro
 * @see gui_save_macro
 * @see save_macro
 * @see pause_recording
 * @see vsMacroGetFilename
 * @see vsMacroEndRecording
 * @see vsMacroQDefined
 * @see vsMacroQDefining
 * @see vsMacroQRecording
 * @see vsMacroQRecordSource
 * @see vsMacroQRunning
 * @see vsMacroSetRecordSource
 * @see vsMacroSetRunning
 * @see vsMacroStartRecording
 *
 * @categories Macro_Programming_Functions
 *
 */
int VSAPI  vsMacroQRunning();
/**
 * Indicates whether a source macro is currently running.  Determines
 * value returned by <b>vsMacroQRunning</b>.
 *
 * @param value	Set to 0 or 1.
 *
 * @see cancel_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see start_recording
 * @see end_recording
 * @see list_macros
 * @see last_macro
 * @see gui_save_macro
 * @see save_macro
 * @see pause_recording
 * @see vsMacroGetFilename
 * @see vsMacroEndRecording
 * @see vsMacroQDefined
 * @see vsMacroQDefining
 * @see vsMacroQRecording
 * @see vsMacroQRecordSource
 * @see vsMacroQRunning
 * @see vsMacroSetRecordSource
 * @see vsMacroSetRunning
 * @see vsMacroStartRecording
 *
 * @categories Macro_Programming_Functions
 *
 */
void VSAPI vsMacroSetRunning(int value);
/**
 * Use <b>vsMacroQRecordSource</b> and the
 * <b>vsMacroQRecording</b> function to determine whether your
 * macro command needs to generate source code.  If you have written a
 * command, you should use <b>vsMacroQRecordSource</b> to check
 * whether you need to generate source.  If your command executes
 * another command with <b>vsExecute</b> or <b>vsCallIndex</b>
 * you may want to use <b>vsMacroSetRecordSource</b> to turn on or
 * off macro recording before making the call.
 *
 * @return Returns non-zero value if a macro is currently being recorded.  This
 * will return 0 if the <b>pause_recording</b> command is called to
 * temporarily turn off recording.
 *
 * @see cancel_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see start_recording
 * @see end_recording
 * @see list_macros
 * @see last_macro
 * @see gui_save_macro
 * @see save_macro
 * @see pause_recording
 * @see vsMacroGetFilename
 * @see vsMacroEndRecording
 * @see vsMacroQDefined
 * @see vsMacroQDefining
 * @see vsMacroQRecording
 * @see vsMacroQRecordSource
 * @see vsMacroQRunning
 * @see vsMacroSetRecordSource
 * @see vsMacroSetRunning
 * @see vsMacroStartRecording
 *
 * @categories Macro_Programming_Functions
 *
 */
int VSAPI  vsMacroQRecordSource();
/**
 * Determines what <b>vsMacroQRecordSource</b> will return to a
 * command called by <b>vsExecute</b> or <b>vsCallIndex</b>.  By
 * default,  will Use <b>vsMacroQRecordSource</b> and the
 * <b>vsMacroQRecording</b> function to determine whether your
 * macro command needs to generate source code.  If you have written a
 * command, you should use <b>vsMacroQRecordSource</b> to check
 * whether you need to generate source. If your command executes
 * another command with <b>vsExecute</b> or <b>vsCallIndex</b>
 * you may want to use <b>vsMacroSetRecordSource</b> to turn on or
 * off macro recording before making the call.
 *
 * @param value	Set to 1 if you want command called by
 * <b>vsExecute</b> or <b>vsCallIndex</b>
 * to do macro recording.
 *
 * @example
 * <pre>
 * void VSAPI mycommand()
 * {
 *      vsMacroSetRecordSource(0);
 *      vsExecute(0,"save_as c:\\temp\\junk.c",
 *                  "" // DONT specify M option here
 *                );
 * }
 * </pre>
 *
 * @see cancel_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see start_recording
 * @see end_recording
 * @see list_macros
 * @see last_macro
 * @see gui_save_macro
 * @see save_macro
 * @see pause_recording
 * @see vsMacroGetFilename
 * @see vsMacroEndRecording
 * @see vsMacroQDefined
 * @see vsMacroQDefining
 * @see vsMacroQRecording
 * @see vsMacroQRecordSource
 * @see vsMacroQRunning
 * @see vsMacroSetRecordSource
 * @see vsMacroSetRunning
 * @see vsMacroStartRecording
 *
 * @categories Macro_Programming_Functions
 *
 */
void VSAPI vsMacroSetRecordSource(int value);
/**
 * Use this function to determine which macro recording commands
 * should be enabled or disabled.
 *
 * @return Returns non-zero value if there is a macro is currently being recorded.
 * This will return a non-zero value even if the <b>pause_recording</b>
 * command is used to temporarily turn of recording.
 *
 * @see cancel_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see start_recording
 * @see end_recording
 * @see list_macros
 * @see last_macro
 * @see gui_save_macro
 * @see save_macro
 * @see pause_recording
 * @see vsMacroGetFilename
 * @see vsMacroEndRecording
 * @see vsMacroQDefined
 * @see vsMacroQDefining
 * @see vsMacroQRecording
 * @see vsMacroQRecordSource
 * @see vsMacroQRunning
 * @see vsMacroSetRecordSource
 * @see vsMacroSetRunning
 * @see vsMacroStartRecording
 *
 * @categories Macro_Programming_Functions
 *
 */
int VSAPI vsMacroQDefining();
/**
 * @return Returns non-zero value if there is a last recorded macro which can be
 * executed by the available to be executed by the last_macro command.
 *
 * @see cancel_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see start_recording
 * @see end_recording
 * @see list_macros
 * @see last_macro
 * @see gui_save_macro
 * @see save_macro
 * @see pause_recording
 * @see vsMacroGetFilename
 * @see vsMacroEndRecording
 * @see vsMacroQDefined
 * @see vsMacroQDefining
 * @see vsMacroQRecording
 * @see vsMacroQRecordSource
 * @see vsMacroQRunning
 * @see vsMacroSetRecordSource
 * @see vsMacroSetRunning
 * @see vsMacroStartRecording
 *
 * @categories Macro_Programming_Functions
 *
 */
int VSAPI vsMacroQDefined();
/**
 * @return Returns absolute output filename of the last recorded macro.  This is
 * "" if there is no last recorded macro.
 *
 * @param pszFilename	Ouput buffer for filename.  This can be 0.
 *
 * @param MaxFilenameLen	Number of characters allocated to
 * <i>pszFilename</i>.  We recommend
 * VSMAXFILENAME.
 *
 * @param pMaxFilenameLen	If this is not 0, this is set to the
 * number of characters you need to allocate.
 *
 * @see cancel_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see start_recording
 * @see end_recording
 * @see list_macros
 * @see last_macro
 * @see gui_save_macro
 * @see save_macro
 * @see pause_recording
 * @see vsMacroGetFilename
 * @see vsMacroEndRecording
 * @see vsMacroQDefined
 * @see vsMacroQDefining
 * @see vsMacroQRecording
 * @see vsMacroQRecordSource
 * @see vsMacroQRunning
 * @see vsMacroSetRecordSource
 * @see vsMacroSetRunning
 * @see vsMacroStartRecording
 *
 * @categories Macro_Programming_Functions
 *
 */
char *VSAPI vsMacroGetFilename(char *pszFilename,int MaxFilenameLen,int *pMaxFilenameLen VSDEFAULT(0));

/**
 * Resets SlickEdit's idle time count to 0.  If an OEM does not call
 * this function, SlickEdit will not be able to track idle time.  This
 * will effect autosave and background tagging as well as any macro
 * which calls the <b>vsQIdle</b>() function.
 *
 * @example (Windows)
 * <pre>
 * static HHOOK ghook;
 * static LRESULT CALLBACK GetMsgProc(
 *     int code,	// hook code
 *     WPARAM wparam,	// removal flag
 *     LPARAM lparam 	// address of structure with message
 *    )
 * {
 *    if (wparam==PM_REMOVE) {
 *       MSG *pmsg;
 *       pmsg=(MSG *)lparam;
 *       UINT message;
 *       message=pmsg->message;
 *       if ((message>=WM_KEYFIRST && message&lt;=WM_KEYLAST) ||
 *           (message>=WM_MOUSEFIRST && message&lt;=WM_MOUSELASTX)
 *           ) {
 *          if (message==WM_MOUSEMOVE) {
 *             static int old_mx= -1000,old_my=-1000;
 *
 *             int mx,my;
 *             mx=(short)LOWORD(lparam);my=(short)HIWORD(lparam);
 *             // IF the mouse did not move
 *             if (mx!=old_mx || my!=old_my) {
 *                old_mx=mx;old_my=my;
 *                vsResetIdle();
 *             }
 *          } else {
 *             vsResetIdle();
 *          }
 *       }
 *    }
 *    return(CallNextHookEx(ghook,code,wparam,lparam));
 * }
 * int PASCAL WinMain( ...)
 * {
 *
 *    // Here we hook GetMessage so that we can accurately update
 *    // SlickEdits Idle time for AutoSave save and background
 *    // tagging.
 *
 *    // You may not have to unhook this hook function because
 *    // it automatically gets unhooked when the process
 *    // terminates.
 *
 *    ghook=SetWindowsHookEx(
 *         WH_GETMESSAGE,	// type of hook to install
 *         (HOOKPROC)GetMsgProc,	// address of hook procedure
 *         hinstance,	// handle of application instance
 *         GetCurrentThreadId() 	// identity of thread to install hook for
 *    );
 * }
 * </pre>
 *
 * @see vsQIdle
 *
 * @categories Keyboard_Functions
 *
 */
void VSAPI vsResetIdle(int reserved VSDEFAULT(-1));

/**
 * Thread safe way to get the number of milliseconds 
 * since the last event. 
 * 
 * @return long VSAPI 
 */
long VSAPI vsTimeSinceLastEvent();

/**
 * @return Returns the time in milliseconds since the last key or mouse event.
 *
 * @see vsResetIdle
 *
 * @categories Keyboard_Functions
 *
 */
long VSAPI vsQIdle();

#define VSEDITORNAME_INVOCATION_NAME          1
#define VSEDITORNAME_EXE_PATH                 2
#define VSEDITORNAME_STATE_FILENAME           3
#define VSEDITORNAME_AUTORESTORE_FILENAME     4
#define VSEDITORNAME_DDE_SERVER_NAME          5
#define VSEDITORNAME_APPLICATION_NAME         6
/**
 * @return Returns string corresponding to <i>option</i> specified.
 *
 * @param option	One of the VSEDITORNAME_???
 * constants defined in "vs.h":
 *
 * <dl>
 * <dt>VSEDITORNAME_INVOCATION_NAME</dt><dd>
 * 	Invocation name of editor.  (argv[0]).  This
 * name will contain a path if the user invoked
 * the editor with a path specification.  Under
 * Windows, this name is used when
 * associating an extension to the editor.</dd>
 *
 * <dt>VSEDITORNAME_EXE_PATH</dt><dd>
 * 	Absolute editor executable path with trailing
 * backslash.  A few files in a single user
 * configuration are stored in this directory
 * (vrestore.slk, vslick.ini).</dd>
 *
 * <dt>VSEDITORNAME_STATE_FILENAME</dt><dd>
 * 	Absolute state file name.</dd>
 *
 * <dt>VSEDITORNAME_AUTORESTORE_FILENAME</dt><dd>
 * 	Absolute auto restore file name.</dd>
 *
 * <dt>VSEDITORNAME_DDE_SERVER_NAME</dt><dd>
 * 	DDE server name.</dd>
 *
 * <dt>VSEDITORNAME_APPLICATION_NAME</dt><dd>
 * 	Application name.  This is currently only
 * used by vsMessageBox as the default title.
 * However, it is likely other dialogs will use
 * this in the future.</dd>
 * </dl>
 *
 * @param pszName	Buffer to contain copy of value.  This
 * parameter is used as the return value.  This
 * can be 0.
 *
 * @param MaxNameLen	Number of bytes allocated to pszName.
 * Must be at least 1.  We recommend
 * VSMAXFILENAME.
 *
 * @param pMaxNameLen	If this is not 0, this is set to the number
 * characters  you need to be allocate.
 *
 * @categories Miscellaneous_Functions
 *
 */
char *VSAPI vsGetEditorName(int option,char *pszName,int MaxNameLen,int *pMaxNameLen VSDEFAULT(0));

/**
 * @return Returns the display width of text string specified based on the current
 * font.  Return value is in the parent scale mode
 * (<b>p_xyscale_mode</b>).
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @param pText	Text to return width of.
 *
 * @param TextLen	Number of characters in <i>pText</i>.  -1
 * means <i>pText</i> is null terminated and
 * length is determined.
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
int VSAPI vsQTextWidth(int wid,const char *pText,int TextLen);
#define VSBUFMATCH_HIDDEN            0x1
#define VSBUFMATCH_EXACT             0x2
#define VSBUFMATCH_VERBOSE           0x4  /* Used by Slick-C&reg; only */
#define VSBUFMATCH_EXACT2            0x8  /* Used by Slick-C&reg; only, same as VSBUFMATCH_EXACT */
#define VSBUFMATCH_BUFNAMEONLY      0x10
#define VSBUFMATCH_DOCUMENTNAMEONLY 0x20
#define VSBUFMATCH_BUFFERIDONLY     0x40
#define VSBUFMATCH_FILENAMEONLY     0x80
#define VSBUFMATCH_FILENAME_HAS_NO_SYMLINKS     0x100
typedef struct {
   int BufID;
   int ModifyFlags;
   int ReadOnly;
   int BufFlags;
   //char szBufName[1024];
   char szBufName[512];
   char szDocumentName[512];
   char szModeName[128];
} VSBUFMATCHINFO;

/**
 * Find file(s) currently open in the editor matching the given file name prefix.
 *
 * @attention
 * This function is thread-safe.  On Unix, this function is not yet thread-safe
 * because it uses a call to zabsolute(), which can do a chdir()
 *
 * @param pszBufName       File name prefix to match, use "" to match any file.
 * @param pIndex           (output), set to buffer index of buffer found.
 *                         If it points to -1, find the first matching buffer.
 * @param BufMatchFlags    Buffer matching options, a bitset of:
 *    <ul>
 *    <li>VSBUFMATCH_HIDDEN -- Return buffers with (buf_flags & VSBUFFLAG_HIDDEN) true.
 *    <li>VSBUFMATCH_EXACT -- Exact buffer name match instead of prefix matching.
 *    <li>VSBUFMATCH_BUFNAMEONLY -- Find buffer names only.
 *    <li>VSBUFMATCH_DOCUMENTNAMEONLY -- Find document names only.
 *    <li>VSBUFMATCH_BUFFERIDONLY -- Return buffer ID only
 *    </ul>
 * @param pBufMatchInfo    (optional, output) set to detailed buffer info
 * @param Reserved         (unused)
 *
 * @return 0 on success, <0 on error
 *
 * @see vsBufGetName
 * @categories Buffer_Functions
 */
int VSAPI vsBufMatch(const char *pszBufName,
                     int *pIndex VSDEFAULT(0),
                     int BufMatchFlags VSDEFAULT(0),
                     VSBUFMATCHINFO *pBufMatchInfo VSDEFAULT(0),
                     int Reserved VSDEFAULT(0));

/**
 * Gets column width setting for column <i>i</i>. Column text is
 * separated with a tab character.
 *
 * @return Returns 0 if successful.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param i	Number between 0 and 199.
 *
 * @param pwidth	Set to the the current column width in the
 * scale mode (<b>p_xyscale_mode</b>) of
 * the parent.
 *
 * @appliesTo List_Box, Tree_View
 *
 * @categories List_Box_Methods, Tree_View_Methods
 *
 */
int VSAPI vsColWidthGet(int wid,int i,int *pwidth);
/**
 * Sets column width of column <i>i</i>.   Column text is separated with
 * a tab character.
 *
 * @return Returns 0 if successful.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param i	Number between 0 and 199.
 *
 * @param width	New column width in the scale mode
 * (<b>p_xyscale_mode</b>) of the parent.
 *
 * @appliesTo List_Box, Tree_View
 *
 * @categories List_Box_Methods, Tree_View_Methods
 *
 */
int VSAPI vsColWidthSet(int wid,int i,int width);
/**
 * Clears all column settings.
 *
 * @return Returns 0 if successful.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @appliesTo List_Box, Tree_View
 *
 * @categories List_Box_Methods, Tree_View_Methods
 *
 */
int VSAPI vsColWidthClear(int wid);

#define VSTREE_ROOT_INDEX     0

#define VSTREE_ADD_BEFORE     0x1 /* Add a node before sibling in order */
#define VSTREE_ADD_AS_CHILD   0x2
//These sort flags cannot be used in combination with each other
#define VSTREE_ADD_SORTED_CS         0x4
#define VSTREE_ADD_SORTED_CI         0x8
#define VSTREE_ADD_SORTED_FILENAME   0x10
#define VSTREE_ADD_SORTED_DESCENDING 0x20

#define VSTREENODE_HIDDEN     0x01    // node and children nodes are not visible in tree
#define VSTREENODE_SELECTED   0x02    // node is selected
#define VSTREENODE_BOLD       0x04    // node caption is bold
#define VSTREENODE_ALTCOLOR   0x08    // node is colored same as modified line
                                      // color.  When this is shut off, it will
                                      // restore the regular tree foreground and
                                      // background color.  Do not use this in
                                      // conjunction with _TreeSetColor(),
                                      // _TreeSetColColor(), _TreeSetRowColor()
#define VSTREENODE_FORCECOLOR 0x10    // node is always colored red
#define VSTREENODE_GRAYTEXT   0x20    // node is colored gray
#define VSTREENODE_DISABLED   0x40    // node is colored gray, do not show combo/text boxes
#define VSTREENODE_ITALIC     0x80    // node caption is italic
#define VSTREENODE_UNDERLINE  0x100   // node caption is underlined
#define VSTREENODE_FIRSTCOLUMNSPANS  0x200

#define VSTREE_CHECKBOX_UNCHECKED         0
#define VSTREE_CHECKBOX_CHECKED           1
#define VSTREE_CHECKBOX_PARTIALLYCHECKED  2

#define TREE_SEARCH_CI        0x1
#define TREE_SEARCH_PREFIX    0x2
#define TREE_SEARCH_SIBLING   0x4
#define TREE_SEARCH_RECURSIVE 0x8
#define TREE_SEARCH_HIDDEN    0x10

#define VSLTF_OUTPUT_LINE_NUMBERS   0x0001   // [OBSOLETE] output only line numbers
#define VSLTF_PROCS                 0x0002   // [OBSOLETE] List proctree (def_proctree_flags) only
#define VSLTF_TREE_OUTPUT           0x0004   // [OBSOLETE] Output to a tree control
#define VSLTF_TREE_OUTPUT_HIDDEN    0x0008   // [OBSOLETE] Output to tree control hidden
#define VSLTF_LIST_OUTPUT           0x0010   // [OBSOLETE] Output to list control
#define VSLTF_SKIP_OUT_OF_SCOPE     0x0020   // Skip locals that are out of scope
#define VSLTF_SET_TAG_CONTEXT       0x0040   // Set tagging context at cursor position
#define VSLTF_SET_TAG_MATCHES       0x0080   // [OBSOLETE] Insert tags into match set
#define VSLTF_LIST_OCCURRENCES      0x0100   // Insert references into tags database
#define VSLTF_START_LOCALS_IN_CODE  0x0200   // Parse locals without first parsing header
#define VSLTF_READ_FROM_STRING      0x0400   // [6.0] arg(3)=buffer, arg(6)=buffer_len
#define VSLTF_LIST_STATEMENTS       0x0800   // [9.0] list statements as well as contexts
#define VSLTF_LIST_LOCALS           0x1000   // [15.0] list local variables in current function
#define VSLTF_ASYNCHRONOUS          0x2000   // [15.0] request to update tags in background thread
#define VSLTF_READ_FROM_EDITOR      0x4000   // [15.0] reading input from an editor control
#define VSLTF_ASYNCHRONOUS_DONE     0x8000   // [16.0] special flag for job to indicate tagging done
#define VSLTF_BEAUTIFIER            0x10000  // [17.0] Set when this is associated with a beautifier job.
#define VSLTF_SAVE_TOKENLIST        0x20000  // [18.0] Set when building current context and saving token list
#define VSLTF_INCREMENTAL_CONTEXT   0x40000  // [18.0] Used for incremental parsing

/**
 * Sets the user info value for the specified tree item.
 *
 * @param wid	Window id of tree control.  0 specifies the
 * current object.
 *
 * @param ItemIndex	Tree item index.
 *
 * @param hvarinfo	New value for user info of this tree item.
 *
 * @see _TreeSetCaption
 * @see _TreeGetCaption
 * @see _TreeSetInfo
 * @see _TreeGetInfo
 * @see _TreeGetUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int VSAPI vsTreeSetUserInfo(int wid,int iHandle,VSHVAR hvar);

/**
 * Gets the user info value for the specified tree item.
 *
 * @param wid	Window id of tree control.  0 specifies the
 * current object.
 *
 * @param iHandle	Tree item index.
 *
 * @param pszInfo Buffer to put user info in
 * @param iInfoSize Size of buffer pszInfo
 *
 * @return 0 if successful
 *
 * @see _TreeSetCaption
 * @see _TreeGetCaption
 * @see _TreeSetInfo
 * @see _TreeGetInfo
 * @see _TreeGetUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int VSAPI vsTreeGetUserInfo(int wid,int iHandle,VSHVAR * hvar);

/**
 * Searches the tree for the specified value.
 *
 * @param wid	Window id of tree control.  0 specifies the
 * current object.
 *
 * @param iIndex	Tree item index.  By default, the parent index
 *                of the children to be searched.  If the
 *                TREE_SEARCH_SIBLING option is specified, then
 *                this is the first sibling search.
 * @param pSearchCaption    Caption to search for in the tree
 *
 * @param iFlags Search flags.
 *
 * TREE_SEARCH_CI           case insensitive search
 *
 * TREE_SEARCH_PREFIX       prefix match
 *
 * TREE_SEARCH_SIBLING      search siblings.  when this is
 * specified, iIndex is the first sibling searched, rather than
 * the parent of items to be searched
 *
 * TREE_SEARCH_RECURSIVE    search recursively through the tree
 * (by default, only one level is searched)
 *
 * TREE_SEARCH_HIDDEN       search hidden nodes
 *
 * @param pSearchUserInfo Optional user info to search for
 *
 * @return 0 if successful
 *
 * @see _TreeSetCaption
 * @see _TreeGetCaption
 * @see _TreeSetInfo
 * @see _TreeGetInfo
 * @see _TreeGetUserInfo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int VSAPI vsTreeSearch(int wid, int iIndex, 
                       const char * pSearchCaption,
                       int iCaptionLength, int iFlags = 0, 
                       const char * pSearchUserInfo = 0, int iUserInfoLength = 0,
                       int iColIndex = -1);

void VSAPI vsRecycleObjects(int onoff);
/**
 * Adds a new sibling or child item.
 *
 * @return Returns the item index of the new item.
 *
 * @param iWID	Window id of tree control.  0 specifies the
 * current object.
 *
 * @param ItemIndex	Specifies a tree item.  The root of the tree
 * can't be deleted and always has an item
 * index of 0.
 *
 * @param Flags	One or more of the following flags ORed
 * together:
 *
 * <dl>
 * <dt>VSTREE_ADD_BEFORE</dt><dd>Add this item before the item
 * specified.</dd>
 * <dt>VSTREE_ADD_AS_CHILD</dt><dd>Add this item after last child of
 * the item specified by
 * <i><b>ItemIndex</b></i>.</dd>
 * <dt>VSTREE_ADD_SORTED_CS</dt><dd>
 * 	Add this item sorted case
 * sensitive.</dd>
 * <dt>VSTREE_ADD_SORTED_CI</dt><dd>
 * 	Add this item sorted case
 * insensitive.</dd>
 * <dt>VSTREE_ADD_SORTED_FILENAME</dt><dd>
 * 	Add this item sorted by
 * filename.</dd>
 * </dl>
 *
 * @param NonCurrentBMIndex	Names table index to a picture
 * which gets displayed to the left of the
 * caption text when this node is not the current
 * node.  We recommend you specify the same
 * values for <i>NonCurrentBMIndex </i>and
 * <i>CurrentBMIndex </i>for leaf items.
 *
 * @param CurrentBMIndex	Names table index to a picture which
 * gets displayed to the left of the caption text
 * when this node is the current node.
 *
 * @param ShowChildren	Indicates whether to show the children
 * of this node.  0 specifies not to show the
 * children.  Specify 1 to initially show
 * children of this node.  Set this to -1 for leaf
 * items.
 *
 * @param iNodeFlags	This is 0 or VSTREENODE_HIDDEN.  The
 * hidden flag indicates that the new item not
 * be visible.
 *
 * @param hvarUserInfo  Slick-C variable containing per-node
 *                      user data.
 *
 * @see vsTreeSetUserInfo
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
int VSAPI vsTreeAddItem(int iWID,int  iRelativeIndex,const char *pszCaption,int  iFlags,
                        int  iCollapsedBMIndex,int  iExpandedBMIndex,
                        int  iState,int iNodeFlags VSDEFAULT(0),
                        VSHVAR hvarUserInfo VSDEFAULT(0));
/**
 * Finds the first child index of <B>iRelativeIndex</B>
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *             current window
 * @param iRelativeIndex index to find child of
 *
 * @return int first child index of <B>iRelativeIndex</B>
 */
int VSAPI vsTreeGetFirstChildIndex(int iWID,int  iRelativeIndex);

/**
 * Finds the next sibling index of <B>iRelativeIndex</B> ("next"
 * is the sibling "down" in the list)
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *             current window
 * @param iRelativeIndex index to find sibling for
 *
 * @return int
 */
int VSAPI vsTreeGetNextSiblingIndex(int iWID,int  iRelativeIndex);

/**
 * Finds the prev sibling index of <B>iRelativeIndex</B> ("prev"
 * is the sibling "up" in the list)
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *             current window
 * @param iRelativeIndex Tree node index to find sibling for
 *
 * @return int
 */
int VSAPI vsTreeGetPrevSiblingIndex(int iWID,int  iRelativeIndex);

/**
 * Gets the caption from node <B>iIndex</B>
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *             current window
 * @param iIndex Tree node index to get caption for
 * @param pszCaption Buffer to put caption in
 * @param iCaptionSize Size of buffer pszCaption
 * @param piCaptionLength (optional) Length of text put in
 *                        pszCaption
 * @param iColIndex Index of specific column to get caption for.
 *                  Default is to get all columns, separated by
 *                  tab characters.
 *
 * @return 0 if successful
 */
int VSAPI vsTreeGetCaption(int iWID,int iIndex,char *pszCaption,int iCaptionSize,int *piCaptionLength=0,int iColIndex=-1);

/**
 * Gets the caption from node <B>iIndex</B>
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *             current window
 * @param iIndex Tree node index to get caption for
 * @param caption String to put caption in
 * @param iColIndex Index of specific column to get caption for.
 *                  Default is to get all columns, separated by
 *                  tab characters.
 *
 * @return 0 if successful
 */
extern VSDLLEXPORT
int vsTreeGetCaptionS(int iWID,int iIndex,slickedit::SEString &caption,int iColIndex=-1);

/**
 *
 *
 * @author dhenry (5/13/2011)
 *
 * @param iWID
 * @param iHandle
 *
 * @return int -1 if
 */
int VSAPI vsTreeGetLineNumber(int iWID,int iHandle);

/**
 * Set info for a tree node.
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *             current window
 * @param iIndex Tree node index to set info for
 * @param iState >-1, set the expansion state for this node
 * @param iCollapsedBMIndex Bitmap index for node when it is
 *                          collapsed
 * @param iExpandedBMIndex Bitmap index for node when it is
 *                         expanded
 * @param iFlags Flags for this node. Combination of:
 * <UL>
 *     <LI>VSTREENODE_HIDDEN - Hide this node</LI>
 *     <LI>VSTREENODE_SELECTED - In multiselect mode, this node
 *     is selected</LI>
 *     <LI>VSTREENODE_BOLD - Show this node as bold</LI>
 *     <LI>VSTREENODE_ALTCOLOR - Color this node red if it is
 *     modified</LI>
 *     <LI>VSTREENODE_FORCECOLOR - Color this node red, even if
 *     it is not modified</LI>
 *     <LI>VSTREENODE_GRAYTEXT - Show text as disabled</LI>
 * </UL>
 * @param iDontSetFirstVisible Set the first visible node. If
 *                             setting info for many node
 *                             indexes in a loop, it is better
 *                             for performance to save this
 *                             until it is necessary
 * @param iMask                bitset of VSTREENODE_* for which 
 *                             flags to set or reset. 
 *
 * @return 0 if successful
 */
int VSAPI vsTreeSetInfo(int iWID,int iIndex,int iState,
                        int iCollapsedBMIndex=-1,int iExpandedBMIndex=-1,int iFlags=-1,
                        int iSetNewCurrentNodeIfHidden=1, int iMask=-1);

/**
 * Get info for a tree node.
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *            current window
 * @param iIndex Tree node index to set info for
 * @param piState if not null, get the expansion state for this
 *                node
 * @param piCollapsedBMIndex if not null, get Bitmap index for
 *                          node when it is collapsed
 * @param piExpandedBMIndex if not null, get Bitmap index for
 *                         node when it is expanded
 * @param piFlags if not null, get Flags for this node.
 *                Combination of:
 * <UL>
 *     <LI>VSTREENODE_HIDDEN - Hide this node</LI>
 *     <LI>VSTREENODE_SELECTED - In multiselect mode, this node
 *     is selected</LI>
 *     <LI>VSTREENODE_BOLD - Show this node as bold</LI>
 *     <LI>VSTREENODE_ALTCOLOR - Color this node red if it is
 *     modified</LI>
 *     <LI>VSTREENODE_FORCECOLOR - Color this node red, even if
 *     it is not modified</LI>
 *     <LI>VSTREENODE_GRAYTEXT - Show text as disabled</LI>
 * </UL>
 *
 * @param piLineNumber if not null, get the "line number" in the
 *                     tree for this index
 * @param iMask        flag mask for piFlags, bitset of 
 *                     VSTREENODE_*
 *
 * @return 0 if successful
 */
int VSAPI vsTreeGetInfo(int iWID,int iIndex,int *piState=0,
                        int *piCollapsedBMIndex=0,int *piExpandedBMIndex=0,int *piFlags=0,
                        int *piLineNumber=0, int iMask=-1);

/**
 * Set flags for all nodes in the tree
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *            current window
 * @param iFlags Flags to set for all nodes
 * @param iMask (optional) Mask to use for all flags.  For
 *              instance, to deselect all items in the tree, set
 *              <B>iFlags</B> to 0, and <B>iMask</B> to
 *              VSTREENODE_SELECTED
 *
 * @return 0 if successful
 */
int VSAPI vsTreeSetAllFlags(int iWID,int iFlags,int iMask=-1);

/**
 * Deselect all nodes in the tree
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *            current window
 * @return 0 if successful
 */
int VSAPI vsTreeDeselectAll(int iWID);

/**
 * Get the integer scroll position for the tree.  When the first
 * item is at top of the tree this function will return 0. When
 * the second item is at the top it will return 1 etc.
 *
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *            current window
 * @param iNewScroll if >-1, set this as the scroll position (if
 *                   it is valid - note the tree will not scroll
 *                   if there are fewer nodes than there is
 *                   space available to display them)
 *
 * @return Scroll position of tree
 */
int VSAPI vsTreeScroll(int iWid,int iNewScroll=-1);

/**
 * Get the node index for the item at a particular "line", the
 * top node being 0.
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *            current window
 * @param iLineNumber Line number in tree to get node index for.
 *                    0 is the first line, 1 is the second etc.
 *
 * @return node index for <B>iLineNumber</B> if successful, else
 *         -1
 */
int VSAPI vsTreeGetIndexFromLineNumber(int iWid,int iLineNumber);

/**
 * Sets the current tree index
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *            current window
 * @param iIndex Tree node index to current
 *
 * @return 0 if successful
 */
int VSAPI vsTreeSetCurIndex(int iWID,int iIndex);

/**
 * Gets the current tree index
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *            current window
 *
 * @return Current index in the tree <B>iWID</B> if successful, 
 *         <0 error code otherwise.
 */
int VSAPI vsTreeCurIndex(int iWID);

/**
 * Forces the tree to refresh.  Use sparingly, but there are
 * some cases where the tree must be forced to refresh.
 *
 * @param iWID Window ID of tree.  Specify 0 if it is the
 *            current window
 *
 * @return 0 if successful
 */
int VSAPI vsTreeRefresh(int iWID);

/**
 * Deletes a tree node.  Can optionally delete only the children
 * of the specified node, or even only the leafy children.
 *
 * @param wid
 * @param iIndex
 * @param iDeleteOnlyChildren
 * @param iDeleteOnlyLeafChildren
 * @return
 */
int VSAPI vsTreeDelete(int iWid, int iIndex, int iDeleteOnlyChildren = 0, int iDeleteOnlyLeafChildren = 0);

/**
 * Returns the number of columns in the treeview.
 *
 * @param wid   tree window ID
 *
 * @return int
 */
int VSAPI vsTreeGetNumColButtons(int wid);

/**
 * Set the check state for an item in the treeview 
 *  
 * @param iWID Window ID of the treeview control
 * @param iHandle Handle to node
 * @param iCheckedState Checked state 0, 1, or 2 (2 is gray 
 *                      state)
 * @param iColIndex Index of column to set check for. Defaults 
 *                  to 0.
 * 
 * @return int VSAPI 0 if successful
 */
int VSAPI vsTreeSetCheckState(int iWID,int iHandle,int iCheckedState,int iColIndex VSDEFAULT(0));

/**
 * Size the columns in the treeview to the data that they contain
 *  
 * @param iWID Window ID of the treeview control
 * @param iColIndex Index of column to set check for. Defaults 
 */
void VSAPI vsTreeSizeColumnToContents(int iWID,int iColIndex);

/**
 * @return Returns non-zero value if the is a system or internal clipboard which
 * can be pasted by the "<b>paste</b>" command.
 *
 * @categories Clipboard_Functions
 *
 */
int VSAPI vsHaveClipboard();
/**
 * @return If <i>undo_option</i> is 'U', NOTHING_TO_UNDO_RC if there is
 * no undo information.  If <i>undo_option</i> is 'R',
 * NOTHING_TO_REDO_RC if there is no redo information.  Use this
 * function to determine whether menu items which execute the
 * <b>undo</b>, <b>undo_cursor</b>, or <b>redo</b> commands
 * should be enabled.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param undo_option	Specify 'U' to test for undo information.
 * Specify 'R' to test for redo information.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsQUndoStatus(int wid,char undo_option VSDEFAULT('U' /* U or R*/));
/**
 * @return Returns non-zero value if there is a current selection.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsHaveSelection(int wid,bool mark_to_cursor=true);
/**
 * @return
 * <dl>
 * <dt>0</dt><dd>Current line is on last line of selection.</dd>
 * <dt>>0</dt><dd>Current line is after last line of selection.</dd>
 * <dt><0</dt><dd>Current line is before last line of selection.</dd>
 * <dt>-1</dt><dd>Text is not selected or selection is not in
 * current buffer.</dd>
 * </dl>
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	Handle to a selection returned by
 * <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  A
 * <i>mark_id</i> of -1 identifies the active
 * selection.
 *
 * @see vsBeginSelectCompare
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsEndSelectCompare(int wid,int markid VSDEFAULT(-1));
/**
 * @return
 *
 * <dl>
 * <dt>0</dt><dd>Current line is on first line of selection.</dd>
 * <dt>>0</dt><dd>Current line is after first line of selection.</dd>
 * <dt><0</dt><dd>Current line is before first line of selection.</dd>
 * <dt>-1</dt><dd>Text is not selected or selection is not in
 * current buffer.</dd>
 * </dl>
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param mark_id	Handle to a selection returned by
 * <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  A
 * <i>mark_id</i> of -1 identifies the active
 * selection.
 *
 * @see vsEndSelectCompare
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsBeginSelectCompare(int wid,int markid VSDEFAULT(-1));
/**
 * This function retrieves the selected text.  <i>pszBuf</i> is set to ""
 * (strlen(pszBuf)==0) iif there is no selection.
 *
 * @return Returns the number of characters in the selected text.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszBuf	Buffer to receive selected text.  Set to "" if
 * there is no selected text.
 *
 * @param BufLen	Number of characters allocated to
 * <i>pszBuf</i>.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by the <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b> function.  A
 * <i>mark_id</i> of -1 specifies the active
 * selection or selection showing and is always
 * allocated.
 *
 * @param flags	Must be -1.
 *
 * @param pEOLChars	Line separator characters.  When this is set
 * to 0, "\r\n" (UNIX: "\n") is always used.  The buffer's line
 * format setting is not used to determine the value to assign
 * to <i>pEOLChars</i>.  To specify Unix style line separator
 * characters in a Windows environment, see the example below.
 *
 * @param EOLCharsLen	Number of characters in
 * <i>pEOLChars</i>.  -1 means
 * <i>pEOLChars</i> is null terminated.
 *
 * @example The only way to have <i>vsGetSelectedText()</i> use Unix
 *          style line separators in Windows is to specify
 *          <i>pEOLChars</i> and <i>EOLCharsLen</i>.
 * <pre>
 * vsGetSelectedText(0, szText, 256, nMarkId, -1, "\n", 1);
 * </pre>
 *
 * @see vsQSelectedTextLength
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsGetSelectedText(int wid,char *pszBuf,int BufLen,int markid VSDEFAULT(-1),int flags VSDEFAULT(-1),const char *pEOLChars VSDEFAULT(0),int EOLCharsLen VSDEFAULT(-1));
/**
 * @return Returns the number of characters in the selected text.  0 is returned if
 * there is no selection.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by the <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b> function.  A
 * <i>mark_id</i> of -1 specifies the active
 * selection or selection showing and is always
 * allocated.
 *
 * @param flags	Must be -1.
 *
 * @param pEOLChars	Line separator characters.  When this is 0,
 * "\r\n" (UNIX: "\n") is used.
 *
 * @param EOLCharsLen	Number of characters in
 * <i>pEOLChars</i>.  -1 means
 * <i>pEOLChars</i> is null terminated.
 *
 * @see vsGetSelectedText
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsQSelectedTextLength(int wid,int markid VSDEFAULT(-1),int flags VSDEFAULT(-1),const char *pEOLChars VSDEFAULT(0),int EOLCharsLen VSDEFAULT(-1));
/**
 * @return Returns 0 if successful.  Possible return codes are
 * PROPERTY_OR_METHOD_NOT_ALLOWED_RC,
 * INVALID_SELECTION_HANDLE_RC,
 * TEXT_NOT_SELECTED_RC, or
 * INVALID_OBJECT_HANDLE_RC.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param mark_id	<I>H</I>andle to a selection returned by
 * <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  A
 * <i>mark_id</i> of -1 identifies the active
 * selection.
 *
 * @param LockSelection	If this is 1, the selection is "locked" (moving
 * the cursor will no longer remove or extend
 * the selection).
 *
 * If all input is valid and there is a selection, the cursor is placed at the
 * beginning of the selection.  For line selection, the column position of
 * the cursor is not changed.
 *
 * @see vsEndSelect
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsBeginSelect(int wid,int markid VSDEFAULT(-1),int LockSelection VSDEFAULT(1));
/**
 * <p>If all input is valid and there is a selection, the cursor is placed at the
 * end of the selection.  For line selection, the column position of the
 * cursor is not changed.</p>
 *
 * @return Returns 0 if successful.  Possible return codes are
 * PROPERTY_OR_METHOD_NOT_ALLOWED_RC,
 * INVALID_SELECTION_HANDLE_RC,
 * TEXT_NOT_SELECTED_RC, or
 * INVALID_OBJECT_HANDLE_RC.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param mark_id	Handle to a selection returned by
 * <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  A
 * <i>mark_id</i> of -1 identifies the active
 * selection.
 *
 * @param LockSelection	If this is 1, the selection is "locked" (moving
 * the cursor will no longer remove or extend
 * the selection).
 *
 * @see vsBeginSelect
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsEndSelect(int wid,int markid VSDEFAULT(-1),int LockSelection VSDEFAULT(1));
/**
 * Returns information about the selection specified.
 *
 * @return Returns 0 if <i>wid</i> and <i>markid</i> are valid.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	Selection handle returned by
 * <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  -1 specifies
 * current selection.
 *
 * @param pfirstcol	Output for first column of the first line of
 * the selection.
 *
 * @param plastcol	Output for last column of the last line of the
 * selection.  For a character selection, you
 * need to check whether the selection includes
 * this column (
 * <b>vsQSelectType</b>(<i>markid</i>,'I') ).
 *
 * @param pbuf_id	Indicates the buffer id of the buffer which
 * has this selection.
 *
 * @param pszBufName	Indicates the name of the buffer which has
 * this selection.  This can be 0.
 *
 * @param MaxBufName	Number of bytes allocated to
 * <i>pszBufName</i>.  We recommend
 * VSMAXFILENAME.
 *
 * @param pMaxBufNameLen	If this is not 0, this is set to the
 * number of characters you need to allocate.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsGetSelInfo(int wid,int markid,int *pfirstcol,int *plastcol=0,int *pbuf_id=0,char *pszBufName=0,int MaxBufName=0,int *pMaxBufNameLen=0,bool mark_to_cursor=true);
/**
 * Returns line number information about the selection specified.
 *
 * @return Returns 0 if <i>wid</i> and <i>markid</i> are valid.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	Selection handle returned by
 * <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  -1 specifies
 * current selection.
 *
 * @param pfirstline	Output for the first line of the selection.
 *
 * @param plastcol	Output for the last line of the selection.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsGetSelLines(int wid,int markid,seSeekPos *pfirstline,seSeekPos *plastline= 0,bool mark_to_cursor=true);
/**
 * @return Returns buffer id if successful (0 is a valid buffer id).  Otherwise a
 * negative error code is returned.
 *
 * @param pszFilename	File to open.
 *
 * @param pszLoadOptions	One of the following values:
 *
 * <dl>
 * <dt>""</dt><dd>Display existing buffer or read
 * <i>pszFilename</i> from disk.</dd>
 *
 * <dt>"+d"</dt><dd>Always read <i>pszFilename</i> from disk
 * even if this file is already loaded in the
 * editor.</dd>
 *
 * <dt>"+b"</dt><dd>Only succeed if a buffer already exists of the
 * name <i>pszFilename</i>.</dd>
 * </dl>
 *
 * @param IgnoreNotFound	If non-zero, create a new buffer with name
 * pszFilename if this file is not found.  This
 * option has no effect if
 * <i>pszLoadOptions</i> is "+bi" or "+b".
 *
 * @param pszLoadOptions2	This option may be one of the following:
 *
 * <dl>
 * <dt>""</dt><dd>No effect.</dd>
 *
 * <dt>"+L"</dt><dd>Always load entire file and close file handle.</dd>
 *
 * <dt>"-L"</dt><dd>Never load entire file and leave file handle
 * open to file.</dd>
 *
 * <dt>"+E:<i>ddd</i>"</dt><dd>Expand tabs to spaces.  This expands tabs in
 * increments of <i>ddd</i>.</dd>
 *
 * <dt>"+E"</dt><dd>Expand tabs to spaces. If your tabs settings
 * for the file being loaded are of the form
 * "+<<i>increment</i>>" (like +4), then  tabs
 * are expanded in increments of
 * <i>increment</i>.  Otherwise tabs are
 * expanded in increments of 8.  To set your
 * tabs in a form "+<<i>increment</i>>", bring
 * up the Extension Options dialog box
 * ("Tools", "Options", "File Extension Setup...",
 * select the Indent tab, select the
 * extension, and set the "Tabs:" text box).  For
 * languages such as REXX and UNIX shell
 * scripts which require the contents of the file
 * to be analyzed before the file type is known,
 * the fundamental mode tab settings are used.</dd>
 * </dl>
 *
 * @see vsBufCreate
 *
 * @categories Buffer_Functions, Edit_Window_Functions, Editor_Control_Functions, File_Functions
 *
 */
int VSAPI vsBufEdit(const char *pszFilename,const char * pszLoadOptions VSDEFAULT(""),int IgnoreNotFound VSDEFAULT(1),const char * pszLoadOptions2 VSDEFAULT(""),int quiet VSDEFAULT(0));

/**
 * @return Creates an empty buffer and returns the buffer id if successful (0 is a
 * valid buffer id).  Otherwise a negative error code is returned.
 *
 * @param pszTempOption	May be "+t", "+tu", "+td", or "+tm" which
 * corresponds to current OS, UNIX, DOS, or
 * Macintosh file format.
 *
 * @param pszLoadOptions	Specifies options that occur before
 * <i>pszTempOption</i>.  See
 * <b>vsLoadFiles</b> function for a list of
 * options.  It is not likely you will need to use
 * any options except possibly in a strange
 * macro.
 *
 * @see vsBufEdit
 *
 * @categories Buffer_Functions, Edit_Window_Functions, Editor_Control_Functions, File_Functions
 *
 */
int VSAPI vsBufCreate(const char *pszTempOption VSDEFAULT("+t"),const char *pszLoadOptions VSDEFAULT(0),int reserved1 VSDEFAULT(0),long reserved2 VSDEFAULT(0));
void VSAPI vsBufDelete(int buf_id);
/**
 * @return Returns line number (<B>VSP_LINE</B>) corresponding to
 * <i>RealLineNumber</i>.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param RealLineNumber	Real line number (<B>VSP_RLINE</B>).
 *
 * @see vsQLineNumberFromReal
 * @see vsQLineNumberFromOld
 * @see vsQRealLineNumberFromLine
 * @see vsQOldLineNumberFromLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
seSeekPosRet VSAPI vsQLineNumberFromReal(int wid,seSeekPos RealLineNumber);
/**
 * @return Returns line number (<B>VSP_LINE</B>) corresponding 
 *         to offset
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param offset	byte offset including no save bytes
 *
 * @see vsQLineNumberFromReal
 * @see vsQLineNumberFromOld
 * @see vsQRealLineNumberFromLine
 * @see vsQOldLineNumberFromLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
seSeekPosRet VSAPI vsQLineNumberFromOffset(int wid,seSeekPos offset);
/**
 * @return Returns line number (<B>VSP_LINE</B>) corresponding to
 * <i>OldLineNumber</i>.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param OldLineNumber	Old line number
 * (<B>VSP_OLDLINENUMBER</B>).
 *
 * @see vsQLineNumberFromReal
 * @see vsQLineNumberFromOld
 * @see vsQRealLineNumberFromLine
 * @see vsQOldLineNumberFromLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
seSeekPosRet VSAPI vsQLineNumberFromOld(int wid,seSeekPos OldLineNumber);
/**
 * @return Returns real line number (<B>VSP_RLINE</B>) corresponding to
 * <i>LineNumber</i>.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param LineNumber	Old line number (<B>VSP_LINE</B>).
 *
 * @see vsQLineNumberFromReal
 * @see vsQLineNumberFromOld
 * @see vsQRealLineNumberFromLine
 * @see vsQOldLineNumberFromLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
seSeekPosRet VSAPI vsQRealLineNumberFromLine(int wid,seSeekPos LineNumber);
/**
 * @return Returns old line number (<B>VSP_OLDLINENUMBER</B>)
 * corresponding to <i>LineNumber</i>.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param LineNumber	Line number (<B>VSP_LINE</B>).
 *
 * @see vsQLineNumberFromReal
 * @see vsQLineNumberFromOld
 * @see vsQRealLineNumberFromLine
 * @see vsQOldLineNumberFromLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
seSeekPosRet VSAPI vsQOldLineNumberFromLine(int wid,seSeekPos LineNumber);
/**
 * Evaluates a C syntax mathematical expression.
 *
 * @return Returns 0 if successful.
 *
 * @param pszResult	(Ouput only).  Result from evaluating the
 * expression specified in <i>pszSource.</i>
 *
 * @param pszSource	(Input only).  C syntax mathematical
 * expression.  See help on <b>math</b> for
 * more information.
 *
 * @param base	Specifies the output base for the result.
 * Currently only 2, 8, 10, and 16 are
 * supported.
 *
 * @categories Keyboard_Functions
 *
 */
const char *VSAPI vsEvalExp(char *pszResult /* 80 bytes*/,const char *pszSource, int base VSDEFAULT(10),void *preserved VSDEFAULT(0));

enum VSCALLBACK {

/**
 * <PRE>
 * void (VSAPI *VSPFNUPDATEEDITORSTATUS)(int wid,int RefreshFlags,seSeekPos linenum,
 *                                       int col,const char *pModeName,
 *                                       int ModeNameLen,int StatusFlags,
 *                                       int reserved);</PRE>
 * The UPDATEEDITORSTATUS callback function is called when the
 * editor control status indicators have changed.  This allows the user to
 * display a line number, column, and other editor status information
 * anywhere they want.
 *
 * @param wid	Window id of editor control.
 *
 * @param RefreshFlags	Flags indicating what has changed.
 *
 * @param linenum	Line number (VSP_RLINE). Update only if
 * (RefreshFlags & VSREFRESH_LINE).  Not
 * valid if ~(RefreshFlags &
 * VSREFRESH_LINE).  If <i>linenum</i> is
 * less than 0, this means VSE does not know
 * the current line number.  This happens (by
 * default) when you load a file larger than
 * 500k than has no color coding defined.
 *
 * @param col	Column. Update only if (RefreshFlags &
 * VSREFRESH_COL).
 *
 * @param pModeName	Mode name. Update only if (RefreshFlags &
 * VSREFRESH_OTHER).
 *
 * @param ModeNameLen	Number of bytes in pModeName.
 *
 * @param StatusFlags	See VSSTATUSFLAG_???? defines.
 * Update only if (RefreshFlags &
 * CorrespondingRefreshFlag)
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_WIN_UPDATE_EDITOR_STATUS=0,

/**
 * <PRE>void (VSAPI *pfnGotFocus)(int wid);</PRE>
 * The GOTFOCUS callback function is called any time the editor
 * control receives keyboard focus.
 *
 * @param wid	Window id of editor control.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_WIN_GOTFOCUS=1,

/**
 * <PRE>void (VSAPI *pfnLostFocus)(int wid);<PRE>
 * The LOSTFOCUS callback function is called any time the editor
 * control loses keyboard focus.
 *
 * @param wid	Window id of editor control.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_WIN_LOSTFOCUS=2,
/**
 * pfn is &VSCMDLINE_FUNCTIONS
 * <P>
 * For this callback, pfn is a pointer to the VSCMDLINE_FUNCTIONS
 * structure.  The VSCMDLINE_FUNCTIONS structure defines all the
 * function required to implement a command line.  See
 * VSCMDLINE_FUNCTIONS structure in "vs.h" for more information.
 * This allows each editor control to have its own command line.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_WIN_CMDLINE_FUNCTIONS=3,


/**
 * <PRE>void (VSAPI *pfnMessage)(int wid,const char *pszMsg,int Immediate);</PRE>
 * The MESSAGE callback function is called to display unobtrusive
 * informational messages like popup menu messages, incremental
 * search messages, and for many of the editor commands.
 *
 * @param wid	Window id of editor control.
 *
 * @param pszMsg	String to display.
 *
 * @param Immediate	Indicates whether the screen should be
 * updated immediately or if it is OK if the
 * screen gets update later in a paint message.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_WIN_MESSAGE=4,

/**
 * <PRE>void (VSAPI *pfnGetMessage)(int wid,char *pszMsg,int MaxStringLen);</PRE>
 * The GET_MESSAGE callback function allows the user to save the
 * message line so that it can be restored later.  Currently the editor
 * AutoSave features uses this to preserve the message.
 *
 * @param wid	Window id of editor control.
 *
 * @param pszMsg	String to receive message being displayed on
 * message line.  This may or may not be the
 * message displayed by the CallbackMessage
 * function.  This can be 0.
 *
 * @param MaxMsgLen	Number of characters allocated to
 * <i>pszMsg</i>.
 *
 * @param pMaxMsgLen	If this is not 0, this is set to the number of
 * characters you need to allocate to
 * <i>pszMsg</i>.
 *
 * @categories Miscellaneous_Defines
 *
 */
VSCALLBACK_WIN_GET_MESSAGE=5,

/**
 * <PRE>int (VSAPI *pfnQueryEndSession)();</PRE>
 * Returns 0 if it is safe to exit the application.  Otherwise 1 should be
 * returned.  This call allows support for the Slick-C&reg; exit function to be
 * called which is typically only needed by OEM which implement the
 * MDI callbacks.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_QUERY_END_SESSION=6,

/**
 * <PRE>void (VSAPI *pfnMenuAddFileHistory)(const char *pszFilename);</PRE>
 * The MENU_ADD_FILE_HISTORY callback gets called when the
 * "edit" command or "gui_open" command are called.  Note that MFC
 * MDI apps don't always uses these commands to open a file.
 * <b>vsBufEdit</b> does not call this callback.
 *
 * @param pszFilename	Absolute name of file
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_MENU_ADD_FILE_HISTORY=7,

/**
 * <PRE>void (VSAPI *pfnMenuAddWorkspaceHistory)(const char *pszFilename);</PRE>
 * The MENU_ADD_WORKSPACE_HISTORY callback is called when
 * a SlickEdit workspace is opened.
 *
 * @param pszFilename	Absolute name of workspace file
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_MENU_ADD_WORKSPACE_HISTORY=8,
VSCALLBACK_APP_MENU_ADD_PROJECT_HISTORY=VSCALLBACK_APP_MENU_ADD_WORKSPACE_HISTORY,

/**
 * <PRE>void (VSAPI *pfnPopupMenu)(const char *pszMenuName,int menu_handle);</PRE>
 * The POPUP_MENU callback is called when a right click menu is
 * displayed.  Later we may expand this hook to support when any pop-
 * up menu is displayed.
 *
 * @param pszMenuName	Name of Slick-C&reg; menu about to be
 * displayed.
 *
 * @param menu_handle	Handle to loaded menu.  Use vsMenu???
 * API's to make any kind of modification to
 * the menu before it gets display.  For
 * example, you might disable menu items,
 * remove menu items, or even add menu items
 * before the menu is displayed.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_POPUP_MENU=9,

// int (VSAPI *pfnQNofDebugBitmaps)(int buf_id);
//#define VSCALLBACK_BUF_QNOFDEBUGBITMAPS      12

/**
 * <PRE>int (VSAPI *pfnQDebugBitmap)(int buf_id,seSeekPos LineNum,seSeekPos RealLineNum,seSeekPos OldLineNum,int wid);</PRE>
 * <p>This callback returns the <i>index</i> to bitmap for the line number
 * specified.  <i>index</i> must be an index into the names table of a
 * registered bitmap.  Use <b>vsUpdatePicture</b> to register a bitmap.
 * 0 indicates that the line has no bitmap.</p>
 *
 * <p>WARNING: It is not safe to modify this buffer during this call.</p>
 *
 * @param buf_id	Buffer id.
 *
 * @param RealLineNum	Real line number (VSP_RLINE).
 *
 * @param OldLineNum	Old line number set by
 * <b>vsSetAllOldLineNumbers</b>.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_BUF_QDEBUGBITMAP=13,

/**
 * <PRE>int (VSAPI *pfnSetLineColor)(int buf_id,int wid, seSeekPos linenum,int LineFlags, 
 *                                   VSCOLORINDEX *pColor,int ColorLen,char *pTempLine,int reserved);</PRE>
 * @return Return VSLF_IN_SQUOTE if next line continues a multi-line single
 * quoted string.  Return VSLF_IN_DQUOTE if next line continues a
 * multi-line single quoted string.  Return VSLF_IN_LINE_COMMENT
 * if this line end with a line comment.  Return vsLFHCommentInfo(1,0)
 * if the next line continues a multi-line comment.  Otherwise return 0.
 *
 * <p>The SET_LINE_COLOR callback function is used to enhance and/or
 * replace our built-in syntax color coding.  This callback is called when
 * lines are displayed in a window, searching for syntax color coding, and
 * when printing.  Any color set by the vsSetTextColor function will
 * override syntax color coding.  In addition, difference color coding will
 * also override syntax color.</p>
 *
 * <p>This callback should ONLY be set during the
 * <B>VSCALLBACK_AR_APP_SELECT_MODE</B> callback
 * because this callback is an extension specific callback.</p>
 *
 * <p>Unless you have already written a programmers editor with color
 * coding, you probably don't have much of an idea about what is the best
 * way to implement color coding.  All high performance color coding
 * (including SlickEdit) is done by generating the syntax color as
 * the visible source lines are displayed.  As long as you don't write a
 * slow lexer, the user will not be able to type too fast for you color
 * coding to keep up.   </p>
 *
 * <p>Here are some important tips about implementing your own color
 * coding:</p>
 *
 * <ul>
 * <li> It is easiest to implement syntax color coding for languages
 * which have no multi-line constructs (like Basic or Assembler).
 * If possible, we recommend you use our built-in color coding to
 * process your multi-line constructs, and have your lexer do
 * some additional color processing.</li>
 *
 * <li> Multi-line constructs such as multi-line comments, multi-line
 * strings, and embedded languages (HTML can have embedded
 * JavaScript or VBScript) require you to store lexer state data for
 * each line in an editor buffer in your own array.  A byte or a 32
 * bit integer per line is typically all you need.  Our built-in color
 * coding only uses 8 bits per line for handling all the multi-line
 * constructs we support.  For example, your set line color
 * callback may need to check the lexer state data to see whether
 * the line being processed
 * (<b>gpArrayStateInfo[<i>linenum</i>]</b>) is inside a multi-
 * line comment started on a previous line.  This requires that you
 * implement some additional code for the following callbacks
 * (see <b>vsCallbackAdd</b>) in addition to the typical
 * callbacks:</li>
 *
 * <dl>
 * <dt><B>VSCALLBACK_AR_BUF_LINES_INSERTED</B></dt><dd>
 * During this callback you need to insert lines into your lexer
 * state array.  These new lines should be initialized with a NULL
 * (we use 0) lexer state value.</dd>
 * <dt><B>VSCALLBACK_AR_BUF_LINES_DELETED</B></dt><dd>
 * During this callback you need to delete the lines in your line
 * array.</dd>
 * <dt><B>VSCALLBACK_AR_BUF_TEXT_CHANGE</B></dt><dd>
 * Your lexer must be able to start in any of your defined multi-
 * line states.  During this callback you need to set the lexer state
 * data for lines whose state may have changed.</dd>
 * </dl>
 * </ul>
 *
 * <p><b>Syntax Color Coding Sample Code for Text Change
 * Callback</b></p>
 *
 * <p>Your DLL must define and export a function called
 * "<b>dllinit_<i>DLLName</i></b>" where <i>DLLName</i>
 * is the name of your DLL without the extension.  When the
 * editor initializes, all functions starting with "<b>dllinit_</b>"
 * are called.  During your "<b>dllinit_<i>DLLName</i></b>"
 * function you need to register a
 * <B>VSCALLBACK_AR_APP_SELECT_MODE</B>
 * callback (see <b>vsCallbackAdd</b>) which checks the
 * extension to see if the
 * VSCALLBACK_BUF_SET_LINE_COLOR callback as well
 * as the callbacks above need to be set.</p>
 *
 * <p><b>Syntax Color Coding Sample Code for Select Mode
 * Callback</b></p>
 *
 * <p>SlickEdit has four layers of color:  syntax color, undoable
 * buffer color,  undoable line insert/modify color, and intra-line
 * difference color (version >=4.0).</p>
 *
 * @param buf_id	Buffer id (VSP_BUFID).  Color coding is
 * per buffer and not per window.
 *
 * @param wid	Window id of editor control.
 *
 * @param linenum	Line number (VSP_LINE).  If you have a
 * lexer state array, it must be indexed with this
 * line number.
 *
 * @param RealLineNum	Real line number (VSP_RLINE).  This line
 * number does not include lines with the
 * VSLF_NOSAVE (non-savable line) flag set.
 * The difference editor adds non-savable lines.
 *
 * @param LineFlags	Current line flags.  See VSLF_??? constants
 * in "vs.h".
 *
 * @param pColor	Array of color indexes.  All data in this array
 * must be set.  Valid color indexes are any of
 * the VSCFG_??? constants or a color index
 * allocated by <b>vsAllocColor</b>.  0
 * indicates a NULL color.  Use the NULL
 * color to get our built-in color coding.  Some
 * color layers will automaticaly overlay any
 * color you define here.
 *
 * @param ColorLen	Number of color indexes that must be set.
 *
 * @param pTempLine	Optional temporary buffer which has
 * <i>ColorLen</i>+1 characters allocated.
 * Use the <b>vsGetLine</b> function to
 * retrieve the contents of the current line.
 *
 * <p><b>Syntax Color Coding Sample Code for Select Mode Callback</b></p>
 *
 * @example
 * <pre>
 * static void VSAPI CallbackSelectMode(int wid,char *pszExtension)
 * {
 *      int buf_id;
 *      buf_id=vsPropGetI(wid,VSP_BUFID);
 *      if (
 * #if VSUNIX
 *         strcmp(pszExtension,"MyLanguageExtension")==0
 * #else
 *         _stricmp(pszExtension,"MyLanguageExtension")==0
 * #endif
 *         ) {
 *           vsCallbackSet(buf_id,
 *                         VSCALLBACK_BUF_SET_LINE_COLOR,
 *                         CallbackSetLineColor);
 *           vsCallbackAdd(buf_id,
 *                         VSCALLBACK_AR_BUF_LINES_INSERTED,
 *                         CallbackLinesInserted);
 *           vsCallbackAdd(buf_id,
 *                         VSCALLBACK_AR_BUF_LINES_DELETED,
 *                         CallbackLinesDeleted);
 *           vsCallbackAdd(buf_id,
 *                         VSCALLBACK_AR_BUF_TEXT_CHANGE,
 *                         CallbackTextChange);
 *      } else {
 *           // DONT set the VSCALLBACK_BUF_SET_LINE_COLOR
 *           // here!
 *           // For completeness, we remove our callbacks here
 *           // in case the user renamed the buffer
 *           // or changed the mode.
 *           vsCallbackRemove(buf_id,
 *                            VSCALLBACK_AR_BUF_LINES_INSERTED,
 *                            CallbackLinesInserted);
 *           vsCallbackRemove(buf_id,
 *                            VSCALLBACK_AR_BUF_LINES_DELETED,
 *                            CallbackLinesDeleted);
 *           vsCallbackRemove(buf_id,
 *                            VSCALLBACK_AR_BUF_TEXT_CHANGE,
 *                            CallbackTextChange);
 *      }
 * }
 * </pre>
 *
 * <p><b>Syntax Color Coding Sample Code for Text Change Callback</b></p>
 *
 * @example
 * <pre>
 * #include <vsapi.h>
 * void VSAPI CallbackTextChange(int buf_id, int wid, seSeekPos StartMod, seSeekPos 
 * EndMod) {
 *      VSSAVEPOS  pos;
 *      vsSavePos(wid,&pos);   // Remember our cursor location.
 *      int cur_linenum=vsPropGetI(wid,VSP_LINE);
 *      vsGoToPoint(wid,StartMod);
 *      // Go up one line since the edit may have occurred
 *      // at the end of the previous line.
 *      vsUp(wid,1);
 *      seSeekPos linenum;
 *      linenum=vsPropGetI64(wid,VSP_LINE);
 *      if (linenum==0 ) {
 *           vsDown(wid,1);++linenum;
 *      }
 *      int LexerStateInfo;
 *      LexerStateInfo=gpArrayStateInfo[linenum];
 *
 *      // The following code is very similar to our built-in text
 *      // change event for handling syntax color coding.  Ignore
 *      // anything you don't think applies to your language.  Some
 *      // of this code may seem like hocus pocus (the pass stuff)
 *      // but our built-in color coding (unlike VC++ color coding
 *      // which messes up on nested comments) has no known bugs.
 *
 *      int pass=1;
 *      for (;;) {
 *           seSeekPos StartOffsetOfLine,down_count;
 *           vsQPoint(wid,&StartOffsetOfLine,&down_count);
 * #define MAXLINELEN   1024
 *           char szLine[MAXLINELEN];
 *           int LineLen;
 *           LineLen=vsGetLine(wid,szLine,MAXLINELEN);
 *           seSeekPos linenum;
 *           linenum=vsPropGetI64(wid,VSP_LINE);;
 *           // IF the current line is in this change
 *           if (cur_linenum==linenum) {
 *                // Make sure the all visible lines are refreshed
 *                // if the user is typing on this line.
 *                // The user may have opened a multi-line construct.
 *                // It actually is OK to always do this, and
 *                // place this call out side this loop.
 *                // We have not found this necessary.
 *                vsBufRefresh(buf_id);
 *           }
 *           if (vsQLineFlags(wid)& VSLF_NOSAVE) {
 *                // Use previous comment flags.
 *                gpArrayStateInfo[linenum]=LexerStateInfo;
 *                goto next_line;
 *           }
 *           int NextLineLexerStateInfo;
 *
 *           // Here's a function you need to implement.
 *           NextLineLexerStateInfo=
 *           DetermineNextLineLexerStateInfo(szLine,LineLen,
 *                                           LexerStateInfo);
 *
 *           // IF nesting level has changed.
 *           if (LexerStateInfo!=gpArrayStateInfo[linenum]) {
 *                gpArrayStateInfo[linenum]=LexerStateInfo;
 *           } else {
 *                // IF we are past last line of modification AND
 *                //    the lexer state info is the same
 *                if (pass>=2) {
 *                     break;
 *                }
 *           }
 *           LexerStateInfo=NextLineLexerStateInfo;
 * next_line:
 *           //IF we hit the bottom of the buffer
 *           if (vsDown(wid,1)) {
 *                break;
 *           }
 *           if (pass==1 && StartOffsetOfLine>EndMod) {
 *                ++pass;
 *           }
 *      }
 *      vsRestorePos(wid,&pos);   // Remember our cursor location.
 * }
 * </pre>
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_BUF_SET_LINE_COLOR= 14,
// void (VSAPI *pfnSetLineColorDiff)(int buf_id,seSeekPos linenum,VSCOLORINDEX *pColor,int ColorLen);
VSCALLBACK_BUF_SET_LINE_COLOR_DIFF=15,
// void (VSAPI *pfnSetLineColorAfterDiff)(int buf_id,int linenum,VSCOLORINDEX *pColor,int ColorLen);
//#define VSCALLBACK_BUF_SET_LINE_COLOR_DIFF_AFTER  16

/**
 * <PRE>int (VSAPI *pfnReadOnlyError)();</PRE>
 * This callback is called when the user attempts to modify a read-only
 * file.  By default, this callback displays a file is read-only message box
 * and/or optional checks out a file.
 *
 * @return Returns 0 to indicate that no default processing is necessary.  A non-
 * zero value indicates that the default processing should take place.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_READ_ONLY_ERROR=17,

/**
 * <PRE>void (VSAPI *pfnKeyOrMouseEventRead)(int event);</PRE>
 * @param event	SlickEdit event.  See vsevents.h.
 *
 * The callback is called when a key or mouse is read but has not yet
 * been processed.  This callback is typically used to track the state of the
 * mouse.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_KEY_OR_MOUSE_EVENT_READ=18,

/**
 * <PRE>int (VSAPI *pfnQDefaultBitmap)(int wid,seSeekPos LineNum,seSeekPos RealLineNum,seSeekPos OldLineNum,int reserved);</PRE>
 * The break point manager calls this function when there are no debug
 * flags (break point bitmaps) on the current line.  This callback is
 * typically used to display a bitmap indicating whether a break point can
 * be set on this line.
 *
 * @return Returns index into the names table of the picture or 0 to indicate no
 * picture.
 *
 * @param wid	Window id of editor control.
 *
 * @param RealLineNum	Real line number (VSP_RLINE).  This line
 * number does not include lines with the
 * VSLF_NOSAVE (non-savable line) flag set.
 * The difference editor adds non-savable lines.
 * <i>OldLineNum</i>	Old line number
 * (VSP_OLDLINENUMBER).
 *
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_BPMQ_DEFAULT_BITMAP=19,

#if 0
no longer supported
/**
 * <PRE>int (VSAPI *pfnMessageBox)(const char *pszMessage,const char *pszTitle,int vsmb_flags);</PRE>
 * Displays a simple message box and prompts the user.  This callback
 * must implement all features of the vsMessageBox function.  See
 * <b>vsMessageBox</b>.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_MESSAGEBOX=20,
#endif
// int (VSAPI *pfnDebugBitmapClick)(int wid,int flags,int NofClicks);
//#define VSCALLBACK_APP_DEBUG_BITMAP_CLICK    21


/**
 * <PRE>void (VSAPI *pfnModalWait)(int BeginEnd,int parent_wid,int reserved,void *preserved);</PRE>
 * This callback gets called before and after a dialog box goes into a
 * modal wait state.  This callback is necessary if you are using Visual
 * SlickEdit in a threaded environment.
 *
 * @param BeginEnd	When non-zero, indicates the call is before
 * the dialog has gone into a modal wait state.
 * When 0, the dialog is exiting its modal wait
 * state.
 *
 * @param parent_wid	Window id of the parent window of this
 * dialog box.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_MODAL_WAIT=22,
/**
 * <PRE>void (VSAPI *pfnDispatchMessage)(int BeginEnd,MSG *pmsg);</PRE>
 * Windows only:  This callback gets called before and after a dialog box
 * goes into a modal wait state. This callback is necessary if you are
 * using SlickEdit in a threaded environment.
 *
 * @param BeginEnd	When non-zero, indicates the call is before
 * the dialog has gone into a modal wait state.
 * When 0, the dialog is exiting its modal wait
 * state.
 *
 * @param pmsg	Pointer to windows MSG structure.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_DISPATCH_MESSAGE=23,
/**
 * Windows only:  This callback gets called before and after a dialog box
 * goes into a modal wait state. This callback is necessary if you are
 * using SlickEdit in a threaded environment.
 *
 * @param BeginEnd	When non-zero, indicates the call is before
 * the dialog has gone into a modal wait state.
 * When 0, the dialog is exiting its modal wait
 * state.
 *
 * @param pmsg	Pointer to windows MSG structure.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_TAG_FILE_REFRESH=24,
/**
 * This callback is called after tag files are removed or added.  This
 * happens when the Tag Files dialog box is used or when the current
 * project changes.  This callback does get called when the
 * <b>vsTagSetTagFiles</b> function is called.
 *
 * @param pszTagFilename	Name of tag file being added or removed.
 * Most of the time this if "" which indicates
 * that the tag file(s) being added or removed
 * are unknown so you must assume anything
 * could have happened to the list of tag files.
 *
 * @param pszOption	Specifies whether the tag file is being added
 * or removed.  "A" when adding a tag file and
 * "R" when removing a tag file.  When
 * <i>pszTagFileName</i> is "", the value of
 * pszOption is undefined.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_TAG_FILE_ADD_REMOVE=25,

/**
 * This callback is called after a tag file is modified.  This typically
 * occurs when the symbols for a particular file change.   Note that this
 * callback does not get called when the vsTagRetagFile function is
 * called.
 *
 * @param pszTagFilename	Name of tag file that was modified.  If this is
 * "", you should ignore this call back.
 * Currently, this happens when a reference file
 * was modified.  We expect this case to be
 * removed in the future since tags references
 * will be in the same tag file.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_TAG_FILE_MODIFIED=26,
/**
 * <PRE>void (VSAPI *pfnMFFindActivateToolbarAndSearchTab)();</PRE>
 * This displays/redocks the toolbar which contains the editor control
 * output window used for multi-file search output.  The tab containing
 * the search output should be activated.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_MFFIND_ACTIVATE_TOOLBAR_AND_SEARCH_TAB=27,
/**
 * <PRE>int (VSAPI *pfnMFFindIsToolbarVisible)();</PRE>
 * @returns	Returns non-zero value if the toolbar containg the editor control output
 * window used for multi-file search output is currently visible.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_MFFIND_IS_TOOLBAR_VISIBLE=28,

/**
 * <PRE>int (VSAPI *pfnMFFindQEditorCtlWID)();</PRE>
 * @returns	Returns non-zero value if the toolbar containg the editor control output
 * window used for multi-file search output is currently visible.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_MFFIND_QEDITOR_CTL_WID=29,

/**
 * <PRE>void (VSAPI *pfnMFFindCloseToolbar)();</PRE>
 * This callback is no longer supported
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
//VSCALLBACK_APP_MFFIND_CLOSE_TOOLBAR=30

/**
 * <PRE>void (VSAPI *pfnPopupMenu2)(const char *pszMenuName,int vtpm_flags,int x,int y);</PRE>
 * The POPUP_MENU2 callback is called when a right click menu
 * would be displayed.  When this callback is defined no, menu is
 * displayed. Later we may expand this hook to support when any pop-up
 * menu is displayed.
 *
 * @param pszMenuName	Name of Slick-C&reg; menu which would be
 * displayed.
 *
 * @param vtpm_flags	Windows VTPM_??? flags which would be
 * given to the WIN32 TrackPopupMenu
 * function.
 *
 * @param x	Recommended <i>x</i> screen coordinate
 * to display menu.
 *
 * @param y	Recommended <i>y</i> screen coordinate
 * to display menu.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_POPUP_MENU2=31,

/**
 * <PRE>void (VSAPI *pfnDeleteWindow)(int wid,int modal)</PRE>
 * This callback gets called before a dialog window gets deleted.  It may
 * also get called for a control window that gets deleted.
 *
 * @param wid	Window id of the window being deleted.
 *
 * @param modal	Non-zero the the window id is for a form
 * about to exit a modal wait state.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_DELETE_WINDOW=32,

/**
 * <PRE>void (VSAPI * vspfnRefreshBreakPoints)(int BPMRefreshFlags);</PRE>
 * This callback gets called when a break point is deleted because the line
 * it was on was deleted, and when the line number for a break point
 * changes.
 *
 * @param BPMRefreshFlags  Flags for this break point.  One or
 * more of the following flags:
 *
 * <dl>
 * <dt>VSBPMREFRESH_LINENUMBERS_CHANGED</dt><dd>
 * 	Breakpoint line number changed because lines
 * were inserted or deleted</dd>
 *
 * <dt>VSBPMREFRESH_BREAKPOINTS_AUTO_DELETED</dt><dd>
 * 	Breakpoint was deleted because lines were
 * deleted</dd>
 * </dl>
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_REFRESH_BREAKPOINTS=33,

/**
 * <PRE>int (VSAPI * vspfnBreakPointLinedDeleted)(int BreakPointIndex, int flags, void *puserdata);</PRE>
 * This callback gets called when the line that any kind a break point is
 * on is deleted.
 *
 * @return Return 0 to delete the break point.
 * @param BreakPointIndex   Index of break point being deleted.
 * @param flags Flags for this break point.
 * @param puserdata Pointer to user data for this break point.
 * @example
 * <pre>
 * static int VSAPI CallbackBreakPointLineDeleted(int BreakPointIndex, int
 * flags, void *puserdata)
 * {
 *      if (! (flags &
 *             (VSBPFLAG_BREAKPOINT|VSBPFLAG_BREAKPOINTDISABLED) ) ) {
 *             // Don't delete this because it is an execution or
 *             // stack executing break point.
 *             return(1);
 *      }
 *      ..
 *      return(0);
 * }
 * </pre>
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_APP_BREAKPOINT_LINE_DELETED=34,

// int (VSAPI * vspfnDiffMultiFile)(char *pszFilename1,char *pszFilename2,int state);
VSCALLBACK_APP_DIFF_MULTIFILE=36,
// int (VSAPI * vspfnDifftags)(char *pszTagname,int state);
VSCALLBACK_APP_DIFF_TAGS=37,
// int (VSAPI * vspfnDiffSave)(int iWindowId,int iFileId,char *pszTitle);
VSCALLBACK_APP_DIFF_SAVE=38,

/**
 * <pre>void (VSAPI * vspfnChangeFont)(int wid, VSPSZ pszFontName, int FontWidth, int FontHeight, int CharSet);</pre>
 * <p>
 * The FONT_CHANGE callback function is used to notify of a font change in an
 * editor control window.
 * <p>
 * Actual font name and metrics being used by an editor control window.
 * This can be different from what the window properties report (e.g. VSP_FONTNAME,
 * VSP_FONTWIDTH, etc.) because the operating system will often map a font
 * differently when it is used.
 * <p>
 * Note:<br>
 * This callback is not called the first time an editor control
 * is created. Use vsGetWindowFontInfo after calling
 * vsCreateEditorCtl to retrieve font name and metrics when an
 * editor control window is created.
 *
 * @param wid         Editor control window id.
 * @param pszFontName Actual font name used to draw text.
 * @param FontWidth   Font width in pixels.
 * @param FontHeight  Font height in pixels. This is significant when
 *                    a WidthxHeight font is selected (e.g. "Terminal 8x12" on Windows).
 * @param pCharSet    Character set. Windows only.
 *               	    Indicates the character set of the font. These
 *                    character sets map directly onto the Windows
 *                    character sets. See VSCHARSET_??? constants defined
 *                    in "vs.h".
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_WIN_FONT_CHANGE=39,
/**
 * <pre>bool (VSAPI * vspfnAllowDragDrop)(int wid);</pre>
 */
VSCALLBACK_APP_ALLOW_DRAG_DROP=40,
// void (VSAPI * vspfnDNDDragOver)(int iWID,BOOL fDragScroll,LPDATAOBJECT pDataObj,DWORD grfKeyState, POINTL pointl, LPDWORD pdwEffect,int *piHandled,HRESULT *phStatus);
VSCALLBACK_APP_DND_DRAGOVER=41,
// void (VSAPI * vspfnDNDDrop)(int iWID,POINTL pointl,LPDATAOBJECT pDataObj,FORMATETC *pFormatetc,STGMEDIUM *stgmedium,int *piHandled,HRESULT *phStatus);
VSCALLBACK_APP_DND_DROP=42,
VSCALLBACK_APP_DND_QUERYDROP=43,
VSCALLBACK_APP_DND_GETDATA=44,

/**
 * <PRE>void (VSAPI *pfnLoadTaggingSettings)();</PRE>
 *
 * <p>The LOAD_TAGGING_SETTINGS callback is called before a list of files are
 * scheduled to be tagged in the background.  This insures that the settings
 * that can not be loaded in a background thread are preloaded so the thread
 * has the correct tagging settings which it needs.  This will load the settings
 * for all languages supported by tagging.
 *
 * @categories Editor_Control_Callback_Functions
 */
VSCALLBACK_APP_LOAD_TAGGING_SETTINGS=45

};

/**
 * Sets a callback function.
 *
 * @param id	Buffer id for VSCALLBACK_BUF_???
 * callbacks.  Window id for
 * VSCALLBACK_WIN_??? callbacks.
 * 	Ignored for all other callbacks.
 *
 * @param vscallback	One of the following constants which
 * correspond to a callback function:
 *
 * <ul>
 * <li><B>VSCALLBACK_WIN_UPDATE_EDITOR_STATUS</B></li>
 * <li><B>VSCALLBACK_WIN_GOTFOCUS</B></li>
 * <li><B>VSCALLBACK_WIN_LOSTFOCUS</B></li>
 * <li><B>VSCALLBACK_WIN_CMDLINE_FUNCTIONS</B></li>
 * <li><B>VSCALLBACK_WIN_MESSAGE</B></li>
 * <li><B>VSCALLBACK_WIN_GET_MESSAGE</B></li>
 * <li><B>VSCALLBACK_WIN_FONT_CHANGE</B></li>
 * <li><B>VSCALLBACK_APP_QUERY_END_SESSION</B></li>
 * <li><B>VSCALLBACK_APP_MENU_ADD_FILE_HISTORY</B></li>
 * <li><B>VSCALLBACK_APP_MENU_ADD_WORKSPACE_HISTORY</B></li>
 * <li><B>VSCALLBACK_APP_POPUP_MENU</B></li>
 * <li><B>VSCALLBACK_APP_POPUP_MENU2</B></li>
 * <li><B>VSCALLBACK_APP_ADD_BUFFER</B></li>
 * <li><B>VSCALLBACK_APP_RENAME_BUFFER</B></li>
 * <li><B>VSCALLBACK_BUF_QDEBUGBITMAP</B></li>
 * <li><B>VSCALLBACK_BUF_SET_LINE_COLOR</B></li>
 * <li><B>VSCALLBACK_APP_READ_ONLY_ERROR</B></li>
 * <li><B>VSCALLBACK_APP_KEY_OR_MOUSE_EVENT_READ</B></li>
 * <li><B>VSCALLBACK_APP_BPMQ_DEFAULT_BITMAP</B></li>
 * <li><B>VSCALLBACK_APP_MESSAGEBOX</B></li>
 * <li><B>VSCALLBACK_APP_DISPATCH_MESSAGE</B></li>
 * <li><B>VSCALLBACK_APP_MODAL_WAIT</B></li>
 * <li><B>VSCALLBACK_APP_TAG_FILE_REFRESH</B></li>
 * <li><B>VSCALLBACK_APP_TAG_FILE_ADD_REMOVE</B></li>
 * <li><B>VSCALLBACK_APP_TAG_FILE_MODIFIED</B></li>
 * <li><B>VSCALLBACK_APP_MFFIND_ACTIVATE_TOOLBAR_
 * AND_SEARCH_TAB</B></li>
 * <li><B>VSCALLBACK_APP_MFFIND_IS_TOOLBAR_VISIBLE</B></li>
 * <li><B>VSCALLBACK_APP_MFFIND_QEDITOR_CTL_WID</B></li>
 * <li><B>VSCALLBACK_APP_MFFIND_CLOSE_TOOLBAR</B></li>
 * <li><B>VSCALLBACK_APP_DELETE_WINDOW</B></li>
 * <li><B>VSCALLBACK_APP_REFRESH_BREAKPOINTS</B></li>
 * <li><B>VSCALLBACK_APP_BREAKPOINT_LINE_DELETED</B></li>
 * </ul>
 *
 * @param pfn	Pointer to callback function or 0 to remove
 * callback function.  Make sure you remove
 * your callback function with
 * vsCallbackSet(id,vscallback,0) if you unload
 * a DLL which contains your callback
 * function.
 *
 * @see vsCallbackAdd
 * @see vsCallbackRemove
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods, Miscellaneous_Functions
 *
 */
void VSAPI vsCallbackSet(int id,VSCALLBACK vscallback,void *pfn);

/** 
 * Suspends all callbacks set by vsCallbackSet/vsCallbackAdd for 
 * the buffer <B>iBufID</B> 
 *  
 * @param iBufID Buffer ID to suspend callbacks for
 * @param iNewValue 1 to suspend callbacks, 0 to unsuspend 
 *                  callbacks.  Calls will be nested internally,
 *                  you do not have to get the original value
 *                  and restore it.
 * 
 * @return void
 */
void VSAPI vsCallbackBufSuspendAll(int iBufID,int iNewValue);

/**
 * @param iBufID Buffer ID to check suspend status of
 * 
 * @return int VSAPI >0 if callbacks for <B>iBufID</B> are 
 *         suspended, 0 if they are not.
 */
int VSAPI vsCallbackBufSuspended(int iBufID);

/** Used to register a different window control (win32).
 *  @param wnd The class to be registered
 */
void VSAPI vsWin32RegisterKbPlaybackWndProc(seintptr_t wnd);
/**
 *
 * @return Returns true when in a special event loop which limits
 *         user input.  This occurs when check for the
 *         Esc key and when a dialog is displayed with a cancel
 *         button.
 *
 */
bool VSAPI vsInProcessEventsCheckForCancel();
/**
 * This function is not support yet.
 *
 * @param id
 * @param vscallback
 *
 * @return
 */
void * VSAPI vsCallbackGet(int id,VSCALLBACK vscallback);
/*
   vsCallbackActivate forces immediate update of
   callbacks for the following:

     VSCALLBACK_WIN_CMDLINE_FUNCTIONS
     VSCALLBACK_WIN_MESSAGE
     VSCALLBACK_WIN_GET_MESSAGE

   VSE's implementation of the above editor control callbacks
   require global callback data.  vsExecute updates the
   global callback data.  However if you use vsCallIndex
   you might want to activate the callbacks.
*/
/**
 * Updates global function pointer callbacks for message line and
 * command line to those callbacks registered to the editor control
 * specified.
 * vsCallbackActivate forces immediate update of
 * callbacks for the following:
 * <DL>
 * <LI>  VSCALLBACK_WIN_CMDLINE_FUNCTIONS
 * <LI>  VSCALLBACK_WIN_MESSAGE
 * <LI>  VSCALLBACK_WIN_GET_MESSAGE
 * </DL>
 *
 * VSE's implementation of the above editor control callbacks
 * require global callback data.  vsExecute updates the
 * global callback data.  However if you use vsCallIndex
 * you might want to activate the callbacks.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @see vsCallbackSet
 * @see vsCallbackRemove
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Miscellaneous_Functions
 *
 */
void VSAPI vsCallbackActivate(int wid);

enum VSCALLBACK_AR {
/**
 * <PRE>void (VSAPI *pfnInsertLine)(int buf_id,seSeekPos AfterLineNum,seSeekPos Noflines)</PRE> 
 * <p>The LINES_INSERTED callback is called when lines are inserted into
 * a buffer.</p>
 *
 * <p>WARNING:  It is not safe to access editor buffer data during this
 * callback.</p>
 *
 * @param buf_id	Buffer id.
 *
 * @param AfterLineNum 	Line number (VSP_LINE and not
 * VSP_RLINE)  Lines we inserted after this
 * line.
 *
 * @param Noflines	Number of lines inserted.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_BUF_LINES_INSERTED= 0,
/**
 * <PRE>void (VSAPI *pfnDeleteLine)(int buf_id,seSeekPos FirstLinenum,seSeekPos Noflines)</PRE> 
 * <p>The LINES_DELETED callback is called when lines are deleted in a
 * buffer.</p>
 *
 * <p>WARNING:  It is not safe to access editor buffer data during this
 * callback.</p>
 *
 * @param buf_id	Buffer id.
 *
 * @param FirstLineNum 	Line number (VSP_LINE and not
 * VSP_RLINE. No save lines are counted).
 * First line deleted.
 *
 * @param Noflines	Number of lines deleted.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_BUF_LINES_DELETED=1,
/**
 * <PRE>void (VSAPI *pfnDeleteBuffer)(int buf_id);</PRE>
 * <p>The DELETE_BUFFER callback is called when a buffer is deleted.</p>
 *
 * <p>WARNING:  It is not safe to access editor buffer data during this
 * callback.</p>
 *
 * @param buf_id	Buffer id.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_APP_DELETE_BUFFER=2,
/**
 * void (VSAPI *pfnTextChange)(int buf_id,int wid, seSeekPos StartMod,seSeekPos EndMod);
 *
 * <p>The following buffer related API calls are allowed during
 * this callback: vsBufGetNofLines(), vsBufGetLineNumFromOffset(),
 * vsBufGetNofNoSaveLines().
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_BUF_TEXT_CHANGE=3,

/**
 * <PRE>void (VSAPI *pfnSelectMode)(int buf_id,int wid,const char *pszExtension);</PRE>
 * <p>The SELECT_MODE callback is called when Slick-C&reg; function
 * <b>_SetEditorLanguage</b> is called.  This occurs when
 * <b>vsBufEdit</b> or <b>vsCommandName</b> is called.</p>
 *
 * <p>This callback is typically used to set the extension specific
 * <B>VSCALLBACK_BUF_SET_LINE_COLOR</B> callback.</p>
 *
 * @param wid	Window id of editor control.
 *
 * @param pszExtension 	Extension corresponding to file extension
 * setup.  Note that this extension DOES NOT
 * have to match the actual extension on the
 * buffer.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_APP_SELECT_MODE=4,


/*
   The VSCALLBACK_AR_BUF_INSERT_TEXT callback was deprecated because the
   VSCALLBACK_AR_BUF_REPLACE_TEXT callback was required for any correct
   implementation and also makes this callback unnecessary (i.e. this callback
   was never needed).
*/
VSCALLBACK_AR_BUF_DELETE_TEXT_DEPRECATED=5,

/*
   The VSCALLBACK_AR_BUF_INSERT_TEXT callback was deprecated because the
   VSCALLBACK_AR_BUF_REPLACE_TEXT callback was required for any correct
   implementation and also makes this callback unnecessary (i.e. this callback
   was never needed).
*/
VSCALLBACK_AR_BUF_INSERT_TEXT_DEPRECATED=6,


/**
 * <PRE>void (VSAPI *pfnReplaceText)(int buf_id,seSeekPos StartOffset,seSeekPos InsertNofBytes,seSeekPos DeleteNofBytes)</PRE>
 * <p>The REPLACE_TEXT callback is called when any text is replaced
 * into a buffer.</p>
 *
 * <p>WARNING:  It is not safe to access editor buffer data during this
 * callback.</p>
 *
 * @param buf_id	Buffer id.
 *
 * @param StartOffset 	Byte offset (including lines with NOSAVE
 * data) of first byte being replaced.
 *
 * @param InsertNofBytes	Number of bytes being inserted.
 *
 * @param DeleteNofBytes	Number of bytes being deleted.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_BUF_REPLACE_TEXT=7,


/**
 * <PRE>void (VSAPI *pfnInsertLine)(int buf_id,seSeekPos AfterLineNum,seSeekPos Noflines,int SplitLineCase)</PRE>
 * <p>The REPLACE_TEXT callback is called when any text is replaced
 * into a buffer.</p>
 *
 * <p>WARNING:  It is not safe to access editor buffer data during this
 * callback.</p>
 *
 * @param buf_id	Buffer id.
 *
 * @param StartOffset 	Byte offset (including lines with NOSAVE
 * data) of first byte being replaced.
 *
 * @param InsertNofBytes	Number of bytes being inserted.
 *
 * @param DeleteNofBytes	Number of bytes being deleted.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_BUF_LINES_INSERTED2=8,

/**
 * void (VSAPI *pfnDeleteLine)(int buf_id,seSeekPos FirstLinenum,seSeekPos Noflines,int JoinLineCase)
 * <p>The LINES_INSERTED callback is called when lines are inserted into
 * a buffer.</p>
 *
 * <p>WARNING:  It is not safe to access editor buffer data during this
 * callback.</p>
 *
 * @param buf_id	Buffer id.
 *
 * @param AfterLineNum 	Line number (VSP_LINE and not
 * VSP_RLINE)  Lines we inserted after this
 * line.
 *
 * @param Noflines	Number of lines inserted.
 *
 * @param SplitLineCase	A non-zero value indicates that a line has
 * been inserted due to a split operation instead
 * of an insert line operation.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_BUF_LINES_DELETED2=9,

/**
 * <PRE>void (VSAPI *pfnAddBuffer)(int buf_id, const char *pszBufName, int buf_flags);</PRE>
 *
 * <p>The ADD_BUFFER callback is called when a buffer is added.</p>
 *
 * <p>WARNING:  It is not safe to access editor buffer data during this
 * callback.</p>
 *
 * @param buf_id	  Buffer id.
 *
 * @param pszBufName  Name of new editor buffer.
 *
 * @param buf_flags	  Current value of VSP_BUFFLAGS property. You might to use
 *                    this to check whether the buffer is hidden or not.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_APP_ADD_BUFFER=10,

/**
 * void (VSAPI *pfnDrawLine)(int buf_id, int wid, int y, int height, seSeekPos LineNum,seSeekPos RealLineNum, int PastBottomOfFile, int SoftWrap)
 * <p>
 * The DRAW_LINE callback is called when lines are drawn for a buffer.
 * </p>
 *
 * <p>
 * WARNING:  It is not safe to access editor buffer data during this
 * callback.
 * </p>
 *
 * @param buf_id Buffer id.
 *
 * @param wid	 Window id of editor control.  0 specifies the
 *               current object.
 *
 * @param y      y coordinate origin of drawn line.
 *
 * @param height Height of the drawn line (not the same as the font height).
 *
 * @param LineNum      Line number of drawn line.
 *
 * @param RealLineNum  Real line number of drawn line. This will differ from
 *                     LineNum when you have NOSAVE lines in your buffer.
 *                     See vsSetLineFlags.
 *
 * @param PastBottomOfFile (boolean). Set to true if drawn line is past the
 *                         bottom of the file (i.e. between the last line of
 *                         file and the bottom of the editor control window).
 *                                                1
 * @param SoftWrap         (boolean). Set to true if drawn line is soft-wrapped.
 *                         This will be false for the first "line", and true
 *                         for all other "lines" that are part of the soft-wrapped
 *                         line.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_BUF_DRAW_LINE=11,

/**
 * <PRE>void (VSAPI *pfnRenameBuffer)(int buf_id,
 *                                    const char *pszOldBufName,
 *                                    const char *pszNewBufName,
 *                                    int buf_flags);
 * </PRE>
 * The RENAME_BUFFER callback is called when the vsName function
 * is called.  Note that this function does not hook the VSP_BUFNAME
 * property.
 *
 * @param buf_id	Buffer id.
 *
 * @param pszOldBufName	Old name of buffer.
 *
 * @param pszNewBufName	New name of buffer.
 *
 * @param buf_flags	Current value of VSP_BUFFLAGS property.
 * You might to use this to check whether the
 * buffer is hidden or not.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_APP_RENAME_BUFFER=12,
/**
 * <PRE>void (VSAPI *pfnRenameDocument)(int buf_id,
 *                                    const char *pszOldDocName,
 *                                    const char *pszNewDocName,
 *                                    int buf_flags);
 * </PRE>
 * The RENAME_DOCUMENT callback is called when the docname() Slick-C&reg; macro function
 * is called.  Note that this function does not hook the VSP_DOCUMENTNAME
 * property.
 *
 * @param buf_id	Buffer id.
 *
 * @param pszOldDocName	Old document name of buffer.
 *
 * @param pszNewDocName	New document name of buffer.
 *
 * @param buf_flags	Current value of VSP_BUFFLAGS property.
 * You might to use this to check whether the
 * buffer is hidden or not.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_APP_RENAME_DOCUMENT=13,

/**
 * void (VSAPI *pfnDrawLineStartFinish)(int buf_id, int wid, int start)
 *
 * <p>
 * The DRAW_LINE_START_FINISH callback is called before starting to
 * draw lines for a buffer (start=1), and when finished drawing
 * lines for a buffer (start=0).
 * </p>
 *
 * <p>
 * This callback is useful when you have some GUI widget (e.g. gutter, trough, etc.)
 * that you must keep in sync line-by-line with the editor control window. See
 * also VSCALLBACK_AR_BUF_DRAW_LINE callback.
 * </p>
 *
 * <p>
 * WARNING:  It is not safe to access editor buffer data during this
 * callback.
 * </p>
 *
 * @param buf_id Buffer id.
 *
 * @param wid	 Window id of editor control.  0 specifies the
 *               current object.
 *
 * @param start (boolean). Set to true (1) when starting to draw lines. Set to
 *              false (0) when finished drawing lines.
 *
 * @categories Editor_Control_Callback_Functions
 *
 */
VSCALLBACK_AR_BUF_DRAW_LINE_START_FINISH=14

};


/**
 * Adds a callback function.
 *
 * @return Returns 0 if successful.  Otherwise NOT_ENOUGH_MEMORY_RC
 * is returned.  The break point manager defines
 * VSCALLBACK_AR_BUF_LINES_INSERTED,
 * VSCALLBACK_AR_BUF_LINES_DELETED, and
 * VSCALLBACK_AR_APP_DELETE_BUFFER.
 *
 * @param id	Buffer id for VSCALLBACK_BUF_???
 * callbacks.
 * 	Window id for VSCALLBACK_WIN_???
 * callbacks.
 * 	Ignored for all other callbacks.
 *
 * @param vscallback	One of the following constants which
 * correspond to a callback function:
 *
 * <ul>
 * <li><B>VSCALLBACK_AR_BUF_LINES_INSERTED</B></li>
 * <li><B>VSCALLBACK_AR_BUF_LINES_DELETED</B></li>
 * <li><B>VSCALLBACK_AR_BUF_DELETE_TEXT</B></li>
 * <li><B>VSCALLBACK_AR_BUF_INSERT_TEXT</B></li>
 * <li><B>VSCALLBACK_AR_BUF_REPLACE_TEXT</B></li>
 * <li><B>VSCALLBACK_AR_BUF_LINES_INSERTED2</B></li>
 * <li><B>VSCALLBACK_AR_BUF_LINES_DELETED2</B></li>
 * <li><B>VSCALLBACK_AR_BUF_TEXT_CHANGE</B></li>
 * <li><B>VSCALLBACK_AR_BUF_DRAW_LINE</B></li>
 * <li><B>VSCALLBACK_AR_APP_DELETE_BUFFER</B></li>
 * <li><B>VSCALLBACK_AR_APP_SELECT_MODE</B></li>
 * <li><B>VSCALLBACK_AR_APP_ADD_BUFFER</B></li>
 * <li><B>VSCALLBACK_AR_APP_RENAME_BUFFER</B></li>
 * <li><B>VSCALLBACK_AR_APP_RENAME_DOCUMENT</B></li>
 * </ul>
 *
 * @param pfn	Pointer to callback function.  Make sure you
 * remove your callback function with
 * <b>vsCallbackRemove</b> if you unload a
 * DLL which contains your callback function.
 *
 * @see vsCallbackSet
 * @see vsCallbackRemove
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods, Miscellaneous_Functions
 *
 */
int VSAPI vsCallbackAdd(int id,
                         VSCALLBACK_AR vscallback,
                         void *pfn,
                         int reserved1 VSDEFAULT(0),
                         int reserved2 VSDEFAULT(0));
/**
 * Removes a callback function.  Make sure you call this function if you
 * unload a DLL which has a callback function.
 *
 * @param id	Buffer id for
 * VSCALLBACK_AR_BUF_??? callbacks.
 * 	Window id for
 * VSCALLBACK_AR_WIN_??? callbacks.
 * 	Ignored for all other callbacks.
 *
 * @param vscallback	One of the following constants which
 * correspond to a callback function:
 *
 * <ul>
 * <li><B>VSCALLBACK_AR_BUF_LINES_INSERTED</B></li>
 * <li><B>VSCALLBACK_AR_BUF_LINES_DELETED</B></li>
 * <li><B>VSCALLBACK_AR_BUF_TEXT_CHANGE</B></li>
 * <li><B>VSCALLBACK_AR_APP_DELETE_BUFFER</B></li>
 * </ul>
 *
 * @param pfn	Pointer to callback function to remove
 *
 * @see vsCallbackSet
 * @see vsCallbackAdd
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods, Miscellaneous_Functions
 *
 */
int VSAPI vsCallbackRemove(int id,VSCALLBACK_AR vscallback,void *pfn);


/**
 * This function should only be used by OEM's to store some data per
 * editor control and not by users writing macros.
 *
 * @return Sets pointer to OEM window data.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pdata	Pointer to window specific data.
 *
 * @see vsWinSetData
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsWinSetData(int wid,void *pdata);
/**
 * This function should only be used by OEM's to store some data per
 * editor control and not by users writing macros.
 *
 * @return Returns pointer to OEM window data set by the
 * <b>vsWinSetData</b> function.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @see vsWinSetData
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void *VSAPI vsWinQData(int wid);

/**
 * This function should only be used by OEM's to store some data per
 * buffer and not by users writing macros.
 *
 * @return Sets pointer to OEM buffer data.
 *
 * @param buf_id	Buffer id returned by
 * <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_
 * ID),  <b>vsBufEdit</b>, or
 * <b>vsBufMatch</b>.
 *
 * @param pdata	Pointer to buffer specific data.
 *
 * @see vsBufQData
 *
 * @categories Buffer_Functions
 *
 */
void VSAPI vsBufSetData(int buf_id,void *pdata);
/**
 * This function should only be used by OEM's to store some data per
 * buffer and not by users writing macros.
 *
 * @return Returns pointer to OEM buffer data set by the <b>vsBufSetData</b>
 * function.
 *
 * @param buf_id	Buffer id returned by
 * <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_
 * ID),  <b>vsBufEdit</b>, or
 * <b>vsBufMatch</b>.
 *
 * @see vsBufSetData
 *
 * @categories Buffer_Functions
 *
 */
void *VSAPI vsBufQData(int buf_id);
#define VSCOLORINDEX unsigned short

/**
 * @return If successful, new color index is returned.  Otherwise 0 is returned.
 * Use the <b>vsSetDefaultColor</b> function to set the color attributes.
 * Color indexes are passed to the <b>vsSetTextColor</b> function to
 * set color.  There is a limit of 255 colors so make sure to free the color
 * when you are done.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 * @param fg         [optional] foreground color to set, default is black
 * @param bg         [optional] background color to set, default is white
 * @param fontFlags  [optional] bitset of VSFONTFLAG_*, default is plain
 * @param parentColor [optional] color to inherit fg, bg, or font attributes from
 *
 * @see vsFreeColor
 * @see vsSetTextColor
 * @see vsSetDefaultColor
 * @see vsGetDefaultColor
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
VSCOLORINDEX VSAPI vsAllocColor(int wid,
                                int fg=0x000000, int bg=0xffffff,
                                int fontFlags=0, VSCOLORINDEX parentColor=0);
/**
 * Frees a color index allocated by <b>vsAllocColor</b>.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @see vsAllocColor
 * @see vsSetTextColor
 * @see vsSetDefaultColor
 * @see vsGetDefaultColor
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsFreeColor(int wid,VSCOLORINDEX ColorIndex);
/**
 * Copies color indexes for ColorLen characters of text starting from the
 * cursor.  A 0 color index indicates a null color.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param ColorIndex	Valid color indexes are any of the
 * VSCFG_??? constants or a color index
 * allocated by <b>vsAllocColor</b>.  0
 * indicates a NULL color.  Use the NULL
 * color to get our built-in color coding.
 *
 * @param ColorLen	Repeat the specified color for this many bytes.
 * abs(<i>ColorLen</i>) times.
 *
 * @see vsAllocColor
 * @see vsFreeColor
 * @see vsSetDefaultColor
 * @see vsGetDefaultColor
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsSetTextColor(int wid,VSCOLORINDEX ColorIndex,seSeekPos ColorLen,bool replacePreviousColor=true);
//int VSAPI vsClexFind(int wid,int clex_flags, const char *options="O");


/**
 * @return Returns 0 if the window id is a valid instance of an SlickEdit
 * object.
 *
 * @param wid	Window id of object.  0 specifies the current object.
 *
 * @example
 * <pre>
 * int wid;
 * //Traverse all SlickEdit objects.
 * for (wid=1;wid&lt;=vsLastWindowID();++wid) {
 *      // IF this window is a valid object
 *      if (_iswindow_valid(wid) ){
 *             // IF this is an editor control object AND
 *             //      this an MDI child editor control AND
 *             //      it is not the HIDDEN WINDOW
 *             if(vsPropGetI(wid,VSP_HASBUFFER) &&
 *                 vsPropGetI(wid,VSP_MDICHILD) &&
 *                 wid!=VSWID_HIDDEN) {
 *                   vsDestroyEditorCtl (wid);
 *             }
 *      }
 * }
 * </pre>
 *
 * @categories Window_Functions
 */
int VSAPI vsIsWindowValid(int wid);
/**
 * @return Returns largest window id ever allocated.  This function is used in
 * conjuction with <b>vsIsWindowValid</b> to traverse all Visual
 * SlickEdit objects.
 *
 * @example
 * <pre>
 * int wid;
 * //Traverse all SlickEdit objects.
 * for (wid=1;wid&lt;=vsLastWindowID();++wid) {
 *      // IF this window is a valid object
 *      if (_iswindow_valid(wid) ){
 *             // IF this is an editor control object AND
 *             //      this an MDI child editor control AND
 *             //      it is not the HIDDEN WINDOW
 *             if(vsPropGetI(wid,VSP_HASBUFFER) &&
 *                 vsPropGetI(wid,VSP_MDICHILD) &&
 *                 wid!=VSWID_HIDDEN) {
 *                   vsDestroyEditorCtl (wid);
 *             }
 *      }
 * }
 * </pre>
 *
 * @categories Window_Functions
 */
int VSAPI vsLastWindowID();

/**
 * @return Returns instance handle (window id) of control, control_name,
 *         in the current form.  If the current form does not have a control
 *         with name (p_name), ctlName, 0 is returned.
 *
 * @param wid	     Window id of object.  0 specifies the current object.
 * @param pszName    Name of control to search for
 *
 * @see vsFindFormObject

 * @appliesTo	All_Window_Objects
 * @categories Form_Methods
 */
int VSAPI vsFindControl(int wid, VSPSZ pszName);

/**
 * @return	Returns an instance handle (window id) to the object,
 * <i>object_name</i>.  Returns 0 if an instance is not found.  Beware, by
 * default, this function will find edited or non-edited instances of an object.
 * Specify the 'N' option if you only want to find a non-edited instance of an
 * object.  Specify the 'E' option if you only want to find an edited instance
 * of an object.
 *
 * @param pszName       is a string in the format: form_name[.control_name]
 * @param pszOptions    "N" or "E", as described above
 *
 * @see vsFindControl
 *
 * @appliesTo	All_Window_Objects
 * @categories Form_Methods
 */
int VSAPI vsFindFormObject(VSPSZ pszName, VSPSZ pszOptions VSDEFAULT(NULL));

/**
 * Converts X and Y from scale mode specified to pixels.
 *
 * @categories Window_Functions
 * @param ScaleMode  Input scale mode.  VSSM_TWIP or VSSM_PIXEL.
 * @param px     Null or pointer to x coordinate.
 * @param py     Null or pointer to y coordinate.
 */
void VSAPI vsLXY2DXY(int ScaleMode,int *px,int *py);
/**
 * Converts X and Y from pixels to scale mode specified.
 *
 * @categories Window_Functions
 * @param ScaleMode  Output Scale mode. VSSM_TWIP or VSSM_PIXEL.
 * @param px     Null or pointer to x coordinate.
 * @param py     Null or pointer to y coordinate.
 */
void VSAPI vsDXY2LXY(int ScaleMode,int *px,int *py);
/**
 * <p>Moves and sizes the current window to the position and size specified.
 * The input position and size parameters are specified in the parent scale
 * mode (VSP_XYSCALEMODE).  For an editor control created with
 * vsCreateEditorCtl, the parent scale mode is always in pixels.</p>
 *
 * <p>After calling this function, you need to call <b>vsRefresh</b> with
 * the 'A' option so that the scroll bars are updated.</p>
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @param x	X position of window relative to parent.
 *
 * @param y	Y position of window relative to parent.
 *
 * @param width	Width of window.
 *
 * @param height	Height of window.
 *
 * @param state	One of the following:
 *
 * <dl>
 * <dt>0 or 'C'</dt><dd>Change position and size of window for its
 * current state.</dd>
 *
 * <dt>'N'</dt><dd>Change normalized position and size of
 * window.</dd>
 * </dl>
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods, Window_Functions
 *
 */
void VSAPI vsMoveWindow(int wid,int x,int y,int width,int height,char state VSDEFAULT(0),int reserved VSDEFAULT(1));

//#define VSCFG_MENU              (-1)
#define VSCFG_DIALOG                (-2)
#define VSCFG_HEX_SOURCE_WINDOW     (-5)
#define VSCFG_UNICODE_SOURCE_WINDOW (-6)
#define VSCFG_FILE_MANAGER_WINDOW   (-7)
#define VSCFG_DIFF_EDITOR_WINDOW    (-8)
#define VSCFG_MINIHTML_PROPORTIONAL (-9)
#define VSCFG_MINIHTML_FIXED        (-10)
#define VSCFG_DOCUMENT_TABS         (-11)

#define VSCFG_SELECTION                   1
#define VSCFG_WINDOW_TEXT                 2
#define VSCFG_CLINE                       3
#define VSCFG_SELECTED_CLINE              4
#define VSCFG_MESSAGE                     5
#define VSCFG_STATUS                      6
#define VSCFG_CMDLINE                     7
#define VSCFG_CURSOR                      8
#define VSCFG_CMDLINE_SELECTION           9
#define VSCFG_LIST_BOX_SELECTION         10
#define VSCFG_LIST_BOX                   11
#define VSCFG_ERROR                      12
#define VSCFG_MODIFIED_LINE              13
#define VSCFG_INSERTED_LINE              14
/* color not yet configurable for VSCFG_FUNCTION_HELP*/
#define VSCFG_FUNCTION_HELP              15
#define VSCFG_FUNCTION_HELP_FIXED        16
#define VSCFG_KEYWORD                    17
#define VSCFG_LINENUM                    18
#define VSCFG_NUMBER                     19
#define VSCFG_STRING                     20
#define VSCFG_COMMENT                    21
#define VSCFG_PPKEYWORD                  22
#define VSCFG_SYMBOL1                    23
#define VSCFG_PUNCTUATION                VSCFG_SYMBOL1
#define VSCFG_SYMBOL2                    24
#define VSCFG_LIBRARY_SYMBOL             VSCFG_SYMBOL2
#define VSCFG_SYMBOL3                    25
#define VSCFG_OPERATOR                   VSCFG_SYMBOL3
#define VSCFG_SYMBOL4                    26
#define VSCFG_USER_DEFINED               VSCFG_SYMBOL4
#define VSCFG_IMAGINARY_LINE             27
#define VSCFG_NOSAVE_LINE                27
#define VSCFG_FUNCTION                   28
#define VSCFG_LINE_PREFIX_AREA           29
#define VSCFG_FILENAME                   30
#define VSCFG_HILIGHT                    31
#define VSCFG_ATTRIBUTE                  32
#define VSCFG_UNKNOWNXMLELEMENT          33
#define VSCFG_XHTMLELEMENTINXSL          34

// Active/inactive titlebar caption color
#define VSCFG_ACTIVECAPTION              35
#define VSCFG_INACTIVECAPTION            36
                                   
#define VSCFG_SPECIALCHARS               37
#define VSCFG_CURRENT_LINE_BOX           38
#define VSCFG_VERTICAL_COL_LINE          39
#define VSCFG_MARGIN_COL_LINE            40
#define VSCFG_TRUNCATION_LINE            41
#define VSCFG_PREFIX_AREA_LINE           42
#define VSCFG_BLOCK_MATCHING             43
#define VSCFG_INC_SEARCH_CURRENT         44
#define VSCFG_INC_SEARCH_ALL             45
#define VSCFG_HEX_MODE                   46
#define VSCFG_SYMBOL_HIGHLIGHT           47
#define VSCFG_DOCUMENT_TAB_MODIFIED      48
#define VSCFG_LINE_COMMENT               49
#define VSCFG_DOCUMENTATION              50
#define VSCFG_DOC_KEYWORD                51
#define VSCFG_DOC_PUNCTUATION            52
#define VSCFG_DOC_ATTRIBUTE              53
#define VSCFG_DOC_ATTR_VALUE             54
#define VSCFG_IDENTIFIER                 55
#define VSCFG_FLOATING_NUMBER            56
#define VSCFG_HEX_NUMBER                 57
#define VSCFG_SINGLEQUOTED_STRING        58
#define VSCFG_BACKQUOTED_STRING          59
#define VSCFG_UNTERMINATED_STRING        60
#define VSCFG_INACTIVE_CODE              61
#define VSCFG_INACTIVE_KEYWORD           62
#define VSCFG_IMAGINARY_SPACE            63
#define VSCFG_INACTIVE_COMMENT           64
#define VSCFG_MODIFIED_ITEM              65
#define VSCFG_NAVHINT                    66
#define VSCFG_XML_CHARACTER_REF          67
#define VSCFG_SEARCH_RESULT_TRUNCATED    68
#define VSCFG_MARKDOWN_HEADER            69
#define VSCFG_MARKDOWN_CODE              70
#define VSCFG_MARKDOWN_BLOCKQUOTE        71
#define VSCFG_MARKDOWN_LINK              72
#define VSCFG_DOCUMENT_TAB_ACTIVE        73
#define VSCFG_DOCUMENT_TAB_SELECTED      74
#define VSCFG_DOCUMENT_TAB_UNSELECTED    75

#define VSCFG_FIRST_COLOR                 1
#define VSCFG_LAST_COLOR                 75

// Legacy
#define VSCFG_MODIFIED_FILE_TAB          VSCFG_DOCUMENT_TAB_MODIFIED

#define VSFONTFLAG_BOLD                       0x1
#define VSFONTFLAG_ITALIC                     0x2
#define VSFONTFLAG_STRIKE_THRU                0x4
#define VSFONTFLAG_UNDERLINE                  0x8
#define VSFONTFLAG_PRINTER                    0x200
#define VSFONTFLAG_INHERIT_STYLE              0x400
#define VSFONTFLAG_INHERIT_COLOR_ADD_STYLE    0x800
#define VSFONTFLAG_INHERIT_FG_COLOR           0x1000
#define VSFONTFLAG_INHERIT_BG_COLOR           0x2000

/**
 * Gets rgb color values (always in Windows format) and font style flag
 * for the <i><b>cfgfield</b></i> specified.
 *
 * @return Returns 0 if successful.
 *
 * @param cfgfield	One of the VSCFG_??? constants or a color
 * index allocated by <b>vsAllocColor</b>.
 *
 * @param FGColor	New rgb foreground color.
 * @param SetFGColor	Indicates whether to use <i>FGColor</i> as
 * new foreground color.
 *
 * @param BGColor	New rgb background color.
 * @param SetBGColor	Indicates whether to use <i>BGColor</i> as
 * new foreground color.
 *
 * @param FontFlag	Set to one of the VSFONTFLAG_?? constants or 0.
 * @param SetFontFlag	Indicates whether to use <i>FontFlag</i> as
 * new foreground color.
 *
 * @param cfgParentColor   One of the VSCFG_??? constants or a color
 *                         index allocated by <b>vsAllocColor</b>
 * @param SetParentColor   Indicates whether to use <i>cfgParentColor</i>
 *                         as new parent color id.
 *
 * @see vsAllocColor
 * @see vsFreeColor
 * @see vsSetTextColor
 * @see vsSetDefaultColor
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions
 *
 */
int VSAPI vsSetDefaultColor(int cfgfield,int FGColor,int SetFGColor,
                            int BGColor VSDEFAULT(0),int SetBGColor VSDEFAULT(0),
                            int FontFlag VSDEFAULT(0),int SetFontFlag VSDEFAULT(0),
                            int cfgParentColor VSDEFAULT(0), int SetParentColor VSDEFAULT(0));
/**
 * Gets rgb color values (always in Windows format) and font style flag
 * for the <i><b>cfgfield</b></i> specified.
 *
 * @return Returns 0 if successful.
 *
 * @param cfgfield	One of the VSCFG_??? constants or a color
 * index allocated by <b>vsAllocColor</b>.
 *
 * @param pFGColor	Ouput only.  Set to rgb foreground color.
 *
 * @param pBGColor	Ouput only.  Set to rgb background color.
 *
 * @param pFontFlag	Output only.  Set to one of the
 * VSFONTFLAG_?? constants or 0.
 *
 * @param pcfgParentColor  Output only.  Set to the color ID of the color
 *                         which 'cfgfield' inherits properties from.
 *                         One of the VSCFG_??? constants or a color
 *                         index allocated by <b>vsAllocColor</b>.
 *
 * @see vsAllocColor
 * @see vsFreeColor
 * @see vsSetTextColor
 * @see vsSetDefaultColor
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions
 *
 */
int VSAPI vsGetDefaultColor(int cfgfield,
                            int *pFGColor,int *pBGColor,
                            int *pFontFlag VSDEFAULT(NULL),
                            int *pcfgParentColor VSDEFAULT(NULL));

/**
 * @return
 * Return the font flags set for the given color index.
 *
 * @param wid     Window ID, currently unused.
 * @param cfg     Color index, either a default color VSCFG_* or one
 *                allocated using vsAllocColor()
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Functions, Editor_Control_Functions
 */
int VSAPI vsGetFontFlag(int wid, int cfg);

int VSAPI vsQueryEndSession(bool endSession=false);
/**
 * @return Returns <i>pszResult.</i>
 *
 * @param option	One of the following options:
 *
 * <dl>
 * <dt>VSOPTIONZ_PAST_EOF</dt><dd>
 * 	String displayed for lines in an editor control
 * past the end of the file.  Currently this string
 * can't be longer than 1 character.</dd>
 *
 * <dt>VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB</dt><dd>
 * 	Editor control display translation table.</dd>
 * </dl>
 *
 * @param MaxResult should be set to
 * VSSPECIALCHAR_MAX.   Each character
 * corresponds to one of the
 * VSSPECIALCHAR_??? constants.
 *
 * @param pszResult	Ouput buffer for option.  This can be 0.
 *
 * @param MaxResult	Number of characters allocated to
 * <i>pszResult</i>.
 *
 * @param pMaxResult	If this is not 0, this is set to the number of
 * characters you need to allocate to
 * <i>pszResult</i>.
 *
 * @see vsGetDefaultFont
 * @see vsSetDefaultFont
 * @see vsGetDefaultColor
 * @see vsSetDefaultColor
 * @see vsQDefaultOption
 * @see vsGetDefaultOptionZ
 * @see vsSetDefaultOption
 * @see vsSetDefaultOptionZ
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions
 *
 */
char *VSAPI vsGetDefaultOptionZ(int option,char *pszResult,int MaxResult,int *pMaxResultLen VSDEFAULT(0));
/**
 * @param option	One of the following options:
 *
 * <dl>
 * <dt>VSOPTIONZ_PAST_EOF</dt><dd>
 * 	String displayed for lines in an editor control
 * past the end of the file.  Currently this string
 * can't be longer than 1 character.</dd>
 * <dt>VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB</dt><dd>
 * 	Editor control display translation table.</dd>
 * </dl>
 *
 * @param MaxResult should be set to
 * VSSPECIALCHAR_MAX.   Each character
 * corresponds to one of the
 * VSSPECIALCHAR_??? constants.
 *
 * @param pszResult	New option value.
 *
 * @return Returns 0 if arguments are valid.
 *
 * @see vsGetDefaultFont
 * @see vsSetDefaultFont
 * @see vsGetDefaultColor
 * @see vsSetDefaultColor
 * @see vsQDefaultOption
 * @see vsGetDefaultOptionZ
 * @see vsSetDefaultOption
 * @see vsSetDefaultOptionZ
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions
 *
 */
int VSAPI vsSetDefaultOptionZ(int option,const char *pszResult);

#define VSCODEHELPFLAG_AUTO_FUNCTION_HELP   0x1
#define VSCODEHELPFLAG_AUTO_LIST_MEMBERS    0x2
// When on, pressing space bar during list members always
// inserts a space.
#define VSCODEHELPFLAG_SPACE_INSERTS_SPACE  0x4
// When on, selecting an item in during list members which
// requires an open paren,'<', or additional characters,
// automatically inserts the additinal characters.
#define VSCODEHELPFLAG_INSERT_OPEN_PAREN  0x8
// When on, pressing space during list members completes
// the word.
#define VSCODEHELPFLAG_SPACE_COMPLETION   0x10
// Get comments while doing list help and mouse-hover over
#define VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS 0x20
// Get comments while doing function help
#define VSCODEHELPFLAG_DISPLAY_FUNCTION_COMMENTS 0x40
// Disable auto syntax help on space key
#define VSCODEHELPFLAG_AUTO_SYNTAX_HELP 0x80
// Replace identifier after cursor, not just before
#define VSCODEHELPFLAG_REPLACE_IDENTIFIER  0x100

/**
 * @return Returns current setting of specified option.
 *
 * @param option	One of the following options:
 *
 * <dl compact style="margin-left:20pt">
 * <dt>VSOPTION_WARNING_ARRAY_SIZE</dt><dd>
 * 	A warning message is displayed if a Slick-C&reg;
 * array of this size or larger is created.</dd>
 *
 * <dt>VSOPTION_WARNING_STRING_LENGTH</dt><dd>
 * 	A warning message is displayed if a Slick-C&reg;
 * string of this size or larger is created.</dd>
 *
 * <dt>VSOPTION_VERTICAL_LINE_COL</dt><dd>
 * 	Column at which editor control displays a
 * vertical line.  0 indicates no vertical line
 * column.</dd>
 *
 * <dt>VSOPTION_WEAK_ERRORS</dt><dd>
 * 	Indicates whether a less server Slick-C&reg; error
 * should set the <b>find_error</b> commands
 * error location.</dd>
 *
 * <dt>VSOPTION_MAXIMIZE_FIRST_MDICHILD</dt><dd>
 * 	Indicates whether the first MDI Child should
 * be created maximized.</dd>
 *
 * <dt>VSOPTION_MAXTABCOL</dt><dd>
 * 	Specifies the maximum column to expand
 * tabs.  Tab characters after this column are
 * not expanded.</dd>
 *
 * <dt>VSOPTION_CURSOR_BLINK</dt><dd>
 * 	Indicates whether the cursor should blink.</dd>
 *
 * <dt>VSOPTION_DISPLAY_TEMP_CURSOR</dt><dd>
 * 	Indicates whether the editor control should
 * display a temporary cursor for an active MDI
 * child which does not have focus.</dd>
 *
 * <dt>VSOPTION_LEFT_MARGIN</dt><dd>
 * 	Left margin in twips between the editor
 * control text and the left edge of the window.
 * This is ignored, when bitmaps are displayed.</dd>
 *
 * <dt>VSOPTION_DISPLAY_TOP_OF_FILE</dt><dd>
 * 	Indicates whether the editor control should
 * display a "Top of File" line.</dd>
 *
 * <dt>VSOPTION_HORIZONTAL_SCROLL_BAR</dt><dd>
 * 	Indicates whether MDI Children should
 * have scroll bars.</dd>
 *
 * <dt>VSOPTION_VERTICAL_SCROLL_BAR</dt><dd>
 * 	Indicates whether MDI Children should
 * have scroll bars.</dd>
 *
 * <dt>VSOPTION_HIDE_MOUSE</dt><dd>
 * 	Indicates whether the mouse should be
 * hidden when you start typing in an editor
 * control.</dd>
 *
 * <dt>VSOPTION_ALT_ACTIVATES_MENU</dt><dd>
 * 	Indicates whether a lone alt key should
 * activate the menu bar.</dd>
 *
 * <dt>VSOPTION_DRAW_BOX_AROUND_CURRENT_LINE</dt><dd>
 * 	Indicates whether the editor control draws a
 *    dotted box or ruler around the current line.
 *    <ul>
 *    <li>VSCURRENT_LINE_BOXFOCUS_NONE    -- Do not draw box
 *    <li>VSCURRENT_LINE_BOXFOCUS_ONLY    -- Just draw box, no ruler
 *    <li>VSCURRENT_LINE_BOXFOCUS_TABS    -- Draw tabs ruler
 *    <li>VSCURRENT_LINE_BOXFOCUS_INDENT  -- Draw syntax indent ruler
 *    <li>VSCURRENT_LINE_BOXFOCUS_DECIMAL -- Darw decimal ruler
 *    </ul>
 * </dd>
 *
 * <dt>VSOPTION_MAX_MENU_FILENAME_LEN</dt><dd>
 * 	Indicates the maximum length of a filename
 * displayed in a menu.</dd>
 *
 * <dt>VSOPTION_PROTECT_READONLY_MODE</dt><dd>
 * 	Indicates whether a read only mode editor
 * control allows editing.  This option has no
 * effect for a an editor control if
 * VSP_PROTECTREADONLYMODE!=0.</dd>
 *
 * <dt>VSOPTION_PROCESS_BUFFER_CR_ERASE_LINE</dt><dd>
 * 	Indicates whether a carriage return not
 * followed by a line feed erase the line in the
 * current process buffer.</dd>
 *
 * <dt>VSOPTION_ENABLE_FONT_FLAGS</dt><dd>
 * 	No longer supported.</dd>
 *
 * <dt>VSOPTION_APIFLAGS</dt><dd>
 * 	VSINIT.APIFlags
 * 	You can not set this option.</dd>
 *
 * <dt>VSOPTION_HAVECMDLINE</dt><dd>
 * 	Indicates whether a command line is
 * currently available.  This gets set when an
 * event is dispatched or <b>vsExecute</b> is
 * called.  You can not set this option.</dd>
 *
 * <dt>VSOPTION_QUIET</dt><dd>Indicates whether the -Q invocation
 * option was specified.</dd>
 *
 * <dt>VSOPTION_SHOWTOOLTIPS</dt><dd>
 * 	Indicates whether tool tip message should be
 * displayed.</dd>
 *
 * <dt>VSOPTION_TOOLTIPDELAY</dt><dd>
 * 	Determines the tool tip message delay in
 * 10ths of a second.</dd>
 *
 * <dt>VSOPTION_HAVEMESSAGELINE</dt><dd>
 * 	Indicates whether a message line is currently
 * available.  This gets set when an event is
 * dispatched or <b>vsExecute</b> is called.
 * You can not set this option.</dd>
 *
 * <dt>VSOPTION_HAVEGETMESSAGELINE</dt><dd>
 * 	Indicates whether get message line is
 * currently available.  This gets set when an
 * event is dispatched or <b>vsExecute</b> is
 * called.  You can not set this option.</dd>
 *
 * <dt>VSOPTION_MACRO_SOURCE_LEVEL</dt><dd>
 * 	Indicates the source code macro level stored
 * in "vsapi.dll".</dd>
 *
 * <dt>VSOPTION_APPLY_LOCAL_STATE_FILE_CHANGES</dt><dd>
 * 	Indicates if local state file changes need to
 * be applied to the global state file.</dd>
 *
 * <dt>VSOPTION_DISPLAYVERSIONMESSAGE</dt><dd>
 * 	Indicates whether the version of the editor
 * message should be displayed when the
 * editor starts.</dd>
 *
 * <dt>VSOPTION_CXDRAGMIN</dt><dd>
 * 	(Windows only) Indicates the minumum
 * number of pixels in the X directory which
 * indicate a drag instead of just a click
 * operation.</dd>
 *
 * <dt>VSOPTION_CYDRAGMIN</dt><dd>
 * 	(Windows only) Indicates the minumum
 * number of pixels in the Y directory which
 * indicate a drag instead of just a click
 * operation.</dd>
 *
 * <dt>VSOPTION_DRAGDELAY</dt><dd>
 * 	(Windows only) Indicates the minumum
 * amount of time in milliseconds which
 * indicate a drag instead of just a click
 * operation.</dd>
 *
 * <dt>VSOPTION_NEXTWINDOWSTYLE</dt><dd>
 * 	This can be 0 or 1.  1 specifies "Smart next
 * window" mode.</dd>
 *
 * <dt>VSOPTION_CODEHELP_FLAGS</dt><dd>
 * 	Zero or more of the following flags:</dd>
 *
 * <dt>VSCODEHELPFLAG_AUTO_FUNCTION_HELP</dt><dd>
 * 	Indicates whether auto Parameter
 * Info is on/off.</dd>
 *
 * <dt>VSCODEHELPFLAG_AUTO_LIST_MEMBERS    0x2</dt><dd>
 * 	Indicates whether auto list members
 * is on/off.</dd>
 *
 * <dt>VSCODEHELPFLAG_SPACE_INSERTS_SPACE</dt><dd>
 * 	When on, pressing space bar during
 * list members always inserts a space. </dd>
 *
 * <dt>VSCODEHELPFLAG_INSERT_OPEN_PAREN</dt><dd>
 * 	When on, selecting an item during
 * list members which requires an open
 * paren,'&lt;', or additional characters,
 * automatically inserts the additinal
 * characters.</dd>
 *
 * <dt>VSCODEHELPFLAG_SPACE_COMPLETION</dt><dd>
 * 	When on, pressing space during list
 * members completes the word.</dd>
 *
 * <dt>VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS</dt><dd>
 * 	When on, source comments are
 * displayed while in list help</dd>
 *
 * <dt>VSCODEHELPFLAG_DISPLAY_FUNCTION_COMMENTS</dt><dd>
 * 	When on, source comments are
 * displayed while in Parameter Info</dd>
 *
 * <dt>VSCODEHELPFLAG_AUTO_SYNTAX_HELP</dt><dd>
 * 	Determines whether auto syntax help
 * is on or off.  Only some languages
 * which have Context Tagging&reg; such as
 * COBOL have auto syntax help.</dd>
 *
 * <dt>VSCODEHELPFLAG_REPLACE_IDENTIFIER</dt><dd>
 * 	When on, the current identifier is
 * replaced when an item is selected
 * from list members.</dd>
 *
 * <dt>VSOPTION_LINE_NUMBERS_LEN</dt><dd>
 * 	Indicates the number of digits to use when
 * displaying line numbers.  In addition, in
 * ISPF emulation this indicates the number of
 * '=' signs to display.</dd>
 *
 * <dt>VSOPTION_LCREADWRITE</dt><dd>
 * 	A non-zero value indicates that a prefix area
 * should be displayed for read/write files.</dd>
 *
 * <dt>VSOPTION_LCREADONLY</dt><dd>
 * 	A non-zero value indicates that a prefix area
 * should be displayed for read/only files.</dd>
 *
 * <dt>VSOPTION_LCMAXNOFLINECOMMANDS</dt><dd>
 * 	Indicates the maximumum number of line
 * command data allowed durring a search and
 * replace.  This is so that the error information
 * does not get extremely large.</dd>
 *
 * <dt>VSOPTION_DOUBLE_CLICK_TIME</dt><dd>
 * 	The maximum amount of time between two
 * clicks to be considered a double click.</dd>
 *
 * <dt>VSOPTION_LCNOCOLON</dt><dd>
 * 	A non-zero value indicates that no colon
 * character should be displayed after line
 * numbers.  This option is ignored in hex
 * mode.</dd>
 * </dl>
 *
 * @see vsGetDefaultFont
 * @see vsSetDefaultFont
 * @see vsGetDefaultColor
 * @see vsSetDefaultColor
 * @see vsQDefaultOption
 * @see vsGetDefaultOptionZ
 * @see vsSetDefaultOption
 * @see vsSetDefaultOptionZ
 *
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsQDefaultOption(int option);
/**
 * Sets corresponding option.
 *
 * @param option	See {@link vsQDefaultOption}.
 *
 * @see vsGetDefaultFont
 * @see vsSetDefaultFont
 * @see vsGetDefaultColor
 * @see vsSetDefaultColor
 * @see vsQDefaultOption
 * @see vsGetDefaultOptionZ
 * @see vsSetDefaultOption
 * @see vsSetDefaultOptionZ
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions
 *
 */
int VSAPI vsSetDefaultOption(int option,int value);

/**
 * This function is used to convert the buffer name for an MDI child edit
 * window into a window title.  Currently buffers with no name have a
 * caption in the form "Untitled<nnn>" where nnn is the buffer id of the
 * buffer.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszCaption	Output string for window caption.
 *
 * @param MaxCaptionLen	Number of characters allocated in
 * pszCaption.  We recommend
 * VSMAXFILENAME.
 *
 * @param state	Indicates the state of the MDI child edit
 * window.  One of the following:
 *
 * <dl>
 * <dt>'I'</dt><dd>Caption is for an iconized window.  No path
 * is placed in the caption.</dd>
 * <dt>'N'</dt><dd>Caption is for a normalized window.</dd>
 * <dt>'M'</dt><dd>Caption is for a maximized window.</dd>
 * </dl>
 *
 * @param pMaxCaptionLen
 *
 * @param showModified If set to false, the modified indicator 
 *                     (*) will not be appended to caption when
 *                     buffer is modified. Defaults to true.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsBufName2Caption(int wid, char* pszCaption, int MaxCaptionLen, char state, int* pMaxCaptionLen VSDEFAULT(0), bool showModified VSDEFAULT(true));
void VSAPI vsFileName2Caption(const char *pszFilename, char* pszCaption, int MaxCaptionLen, char state, int* pMaxCaptionLen VSDEFAULT(0), bool appendModifiedIndicator VSDEFAULT(false),int MDIChildWithDuplicateNameIndex=0);

/**
 * Sets focus to the object.  This function calls the VSINIT.pfnSetFocus
 * call back if it is defined.  Don't call this function in the
 * VSINIT.pfnSetFocus callback.
 *
 * @param wid	Window id of object to set focus to
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
void VSAPI vsSetFocus(int wid);
/**
 * Sets focus to the object.  This function does not call the
 * VSINIT.pfnSetFocus call back.
 *
 * @param wid	Window id of object to set focus to
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
void VSAPI vsSetFocus2(int wid);

class QWidget;

// IF GUI header files have been included
#if defined(VSAPI_H) || defined(SYSAPI_H)
   #if VSUNIX || (defined(VSUNIX) && VSUNIX)
      #define VSSYSHWND void *
   #else
      #define VSSYSHWND HWND
   #endif
   // Create an mdi instance and set VSP_HWNDFRAME and VSP_HWND properties
   // Currently we only support one MDI frame.
   /**
    * Registers a system window as a SlickEdit object.  There are
    * different reasons for registering form (outer) windows.  One reason is
    * so that a window created outside of SlickEdits dialog boxes
    * will get disabled when SlickEdit displays a modal dialog box.
    * Another reason is so that you can make a particular window the parent
    * of one of our dialog boxes.  Make sure you call
    * <b>vsUnregisterWindow</b> before you destroy your window.
    *
    * @return Returns window id of newly registered window.
    *
    * @param pwidget	QWidget to register
    *
    * @param oi	Object type.   One of VSOI_??? constants.
    * For now this must be VSOI_FORM.
    *
    * @see vsUnregisterWindow
    *
    * @categories Window_Functions
    *
    */
   int VSAPI vsQTRegisterWindow(QWidget *pwidget,int oi VSDEFAULT(VSOI_FORM));
   /**
    * Registers a system window as a SlickEdit object.  There are
    * different reasons for registering form (outer) windows.  One reason is
    * so that a window created outside of SlickEdits dialog boxes
    * will get disabled when SlickEdit displays a modal dialog box.
    * Another reason is so that you can make a particular window the parent
    * of one of our dialog boxes.  Make sure you call
    * <b>vsUnregisterWindow</b> before you destroy your window.
    *
    * @return Returns window id of newly registered window.
    *
    * @param hwndframe	System window handle which contains the
    * client window.  For Windows, this is always
    * the same as <i>hwnd</i>.  For UNIX,
    * specify the same value as <i>hwnd</i> if
    * the client window is not contained by a
    * window with decorations.
    *
    * @param hwnd	System window handle client window.
    *
    * @param oi	Object type.   One of VSOI_??? constants.
    * For now this must be VSOI_FORM.
    *
    * @see vsUnregisterWindow
    *
    * @categories Window_Functions
    *
    */
   int VSAPI vsRegisterWindow(VSSYSHWND hwndframe,VSSYSHWND hwndclient,int oi VSDEFAULT(VSOI_FORM));

   /**
    * Register a non-SlickEdit window as the SlickEdit command line.  OEMs
    * implementing their own command line should call this as well as registering
    * the callbacks in VSCMDLINE_FUNCTIONS.
    *
    * Note: for Qt, pass in the Qt widget for both parameters
    *
    * @param hwndcmdline Handle to command line window
    * @param hwndcmdlineclient Handle to client area of the command line window.
    *                          This may be the same as hwndcmdline
    *
    * @return void
    */
   void VSAPI vsCmdLineInit(VSSYSHWND hwndcmdline,VSSYSHWND hwndcmdlineclient);

   /**
    * Unregisters a window registered by vsRegisterWindow.
    *
    * @param wid Window id of object
    *
    * @see vsRegisterWindow
    *
    * @categories Window_Functions
    *
    */
   void VSAPI vsUnregisterWindow(int wid);
/**
 * <p>This function registers some MDI status line window handles.
 * SlickEdit will set focus to the <i>hwnd</i> window when there are no
 * MDI child windows.  The callback VSINIT.pfnSetFocus is called with
 * VSWID_STATUS to set focus to this window.  If this callback is not
 * defined, the focus is not changed.</p>
 *
 * <p>See our MDI sample program for an example.</p>
 *
 * @param hwndframe	System window handle which contains the
 * client window.  For Windows, this is always
 * the same as <i>hwnd</i>.  For UNIX,
 * specify the same value as <i>hwnd</i> if
 * the client window is not contained by a
 * window with decorations.
 *
 * @param hwnd	System window handle client window.
 *
 * @categories Miscellaneous_Functions
 *
 */
void VSAPI vsMDIRegisterStatusWindow(int mdi_wid,VSSYSHWND hwndframe,VSSYSHWND hwnd);
/**
 * <p>This function registers the MDI status line window. 
 * SlickEdit will set focus to the <i>hwnd</i> window when there are no
 * MDI child windows.  The callback VSINIT.pfnSetFocus is called with
 * VSWID_STATUS to set focus to this window.  If this callback is not
 * defined, the focus is not changed.</p>
 *
 * <p>See our MDI sample program for an example.</p>
 *
 * @param pwidget	Qt widget
 *
 * @categories Miscellaneous_Functions
 *
 */
void VSAPI vsQTMDIRegisterStatusWindow(int mdi_wid,QWidget *pwidget);
void VSAPI vsQTMDISetActiveCmdLine(int cmdline_wid);
/**
 * This function registers some MDI window handles.  Currently, only
 * one MDI window is supported.  SlickEdit will automically
 * disable the <i>hwndframe</i> window when a modal dialog box is
 * displayed.
 *
 * @return Returns MDI window instance handle.
 *
 * <p>See our MDI sample program for an example.</p>
 *
 * @param hwndframe	System window handle to outer most MDI
 * frame window.  For Windows, this is always
 * the same as <i>hwnd</i>.
 *
 * @param hwnd	System window handle MDI frame client
 * window.  The <i>hwndmdiclient</i>
 * window is inside this window.
 *
 * @param hwndmdiclient	System window handle of MDI client
 * window.  In a Windows MDI, this is the
 * parent window for all MDI child windows.
 *
 * @categories Miscellaneous_Functions
 *
 */
   int VSAPI vsMDICreate(VSSYSHWND hwndframe,VSSYSHWND hwnd,VSSYSHWND hwndmdiclient);
   int VSAPI vsQTMDICreate(QWidget *pMdiAppFrame);
   int VSAPI vsMDICreate_internal(VSSYSHWND hwndframe,VSSYSHWND hwnd,VSSYSHWND hwndmdiclient);
#define  VSBDS_NONE   0
#define  VSBDS_FIXED_SINGLE  1
   /**
    * <p>This function creates a new editor control.  DO NOT use this function
    * to create an editor control on a Slick-C&reg; dialog box.  If you are NOT
    * calling this function during the VSINIT.pfnMDICreateEditWindow
    * callback, you need to call <b>vsRefresh</b> with the 'A' option so
    * that the scroll bars are updated.</p>
    *
    * <p>You do not have to call <b>vsDestroyEditorCtl</b> on Windows
    * because SlickEdit gets the Windows WM_DESTROY message
    * and can cleanup their.  However, under X windows you must call
    * <b>vsDestroyEditorCtl</b> just before destroying the parent window
    * which contains the editor control window.  Otherwise, Visual
    * SlickEdit will crash.</p>
    *
    * @return If successful, returns window id of new editor control.  Otherwise
    * negative error code is returned.  0 is not a valid window id and is never
    * returned by this function.
    *
    * @param wid	Window id of new editor control.  This
    * should be 0 except when this function is
    * called during the
    * VSINIT.pfnMDICreateEditWindow
    * callback.
    *
    * @param hwndparent	System window handle of parent.
    *
    * @param <i>x</i>, <i>y</i>, <i>width</i>, <i>height</i>	Size in pixels to
    * use when created new editor control.
    *
    * @param BorderStyle	Border style of editor control.
    *
    * @param visible	When non-zero, editor control is created
    * initially visible.  Set the VSP_VISIBILE
    * property to make an editor visible or
    * invisible.
    *
    * @param buf_id	Buffer id to initially attatch to the new editor
    * control.
    *
    * @param pdata	Initial window specific user data.  Use
    * <b>vsWinQData</b> function to get your
    * window specific user data.  Use the
    * <b>vsWinSetData</b> function to change
    * this value later.
    *
    * @param mdi_wid	Window id of MDI frame window. If you
    * have implemented our MDI callbacks,
    * specify this parameter to register a new
    * editor control MDI child.  Use this
    * parameter during the VSINIT.
    * pfnMDICreateEditWindow callback.
    * Currently only one MDI frame window
    * (VSWID_MDI) is supported.
    *
    * @see vsDestroyEditorCtl
    *
    * @categories Editor_Control_Functions, Window_Functions
    *
    */
   int VSAPI vsCreateEditorCtl(int wid,VSSYSHWND hwndparent,int x,int y,int width,int height,
                               int BorderStyle VSDEFAULT(VSBDS_FIXED_SINGLE),
                               int visible VSDEFAULT(1),
                               int buf_id VSDEFAULT(-1),void *pdata VSDEFAULT(0),int mdi_wid VSDEFAULT(0),int reserved1 VSDEFAULT(0),void *pvwidget VSDEFAULT(0));
   /**
    * <p>This function creates a new editor control.  DO NOT use this function
    * to create an editor control on a Slick-C&reg; dialog box.  If you are NOT
    * calling this function during the VSINIT.pfnMDICreateEditWindow
    * callback, you need to call <b>vsRefresh</b> with the 'A' option so
    * that the scroll bars are updated.</p>
    *
    * <p>You do not have to call <b>vsDestroyEditorCtl</b> on Windows
    * because SlickEdit gets the Windows WM_DESTROY message
    * and can cleanup their.  However, under X windows you must call
    * <b>vsDestroyEditorCtl</b> just before destroying the parent window
    * which contains the editor control window.  Otherwise, Visual
    * SlickEdit will crash.</p>
    *
    * @return If successful, returns window id of new editor control.  Otherwise
    * negative error code is returned.  0 is not a valid window id and is never
    * returned by this function.
    *
    * @param wid	Window id of new editor control.  This
    * should be 0 except when this function is
    * called during the
    * VSINIT.pfnMDICreateEditWindow
    * callback.
    *
    * @param pParentWidget	QWidget parent
    *
    * @param <i>x</i>, <i>y</i>, <i>width</i>, <i>height</i>	Size in pixels to
    * use when created new editor control.
    *
    * @param BorderStyle	Border style of editor control.
    *
    * @param visible	When non-zero, editor control is created
    * initially visible.  Set the VSP_VISIBILE
    * property to make an editor visible or
    * invisible.
    *
    * @param buf_id	Buffer id to initially attatch to the new editor
    * control.
    *
    * @param pdata	Initial window specific user data.  Use
    * <b>vsWinQData</b> function to get your
    * window specific user data.  Use the
    * <b>vsWinSetData</b> function to change
    * this value later.
    *
    * @param mdi_wid	Window id of MDI frame window. If you
    * have implemented our MDI callbacks,
    * specify this parameter to register a new
    * editor control MDI child.  Use this
    * parameter during the VSINIT.
    * pfnMDICreateEditWindow callback.
    * Currently only one MDI frame window
    * (VSWID_MDI) is supported.
    *
    * @see vsDestroyEditorCtl
    *
    * @categories Editor_Control_Functions, Window_Functions
    *
    */
   int VSAPI vsQTCreateEditorCtl(int wid, QWidget* pParentWidget,
                                 int x, int y, int width, int height,
                                 int BorderStyle VSDEFAULT(VSBDS_FIXED_SINGLE),
                                 int visible VSDEFAULT(1),
                                 int buf_id VSDEFAULT(-1), void* pdata VSDEFAULT(0), int mdi_wid VSDEFAULT(0), int reserved1 VSDEFAULT(0));
   /**
    * This function destroys an editor control window an all allocated data
    * of that editor control.  The buffer is not deleted if there is another non-
    * mdi (VSP_MDICHILD==0) editor control displaying that buffer.
    *
    * @param wid	Window id of the editor control.
    *
    * @see vsCreateEditorCtl
    *
    * @appliesTo Edit_Window, Editor_Control
    *
    * @categories Edit_Window_Methods, Editor_Control_Methods, Window_Functions
    *
    */
   void VSAPI vsDestroyEditorCtl(int wid,long reserved VSDEFAULT(0));
   /**
    * Create a SWT form. An SWT form is used as an intermediary between an OEM
    * window and the editor control. Even though the name is "SWT", derived
    * from SWT used by Eclipse, it can be used to interface between any
    * supported OS and the editor control.
    *
    * @param hwndparent native parent window. This is HWND for Windows, Widget for Motif, Window for X11.
    * @param x
    * @param y
    * @param width
    * @param height
    * @param visible
    * @param preserved
    * @param reserved1
    *
    * @return
    *
    * @categories Form_Functions
    */

   int VSAPI vsCreateSWTForm(VSSYSHWND hwndparent,int x,int y,
                               int width,int height,
                               int BorderStyle VSDEFAULT(VSBDS_NONE),
                               int visible VSDEFAULT(1),
                               void *pvwidget VSDEFAULT(0),
                               int reserved1 VSDEFAULT(0));
   /**
    * Destroy an SWT form.
    *
    * @param wid       form ID
    * @param reserved  reserved
    *
    * @categories Form_Functions
    */
   void VSAPI vsDestroySWTForm(int wid,long reserved VSDEFAULT(0));
/**
 * Execute the command bound to the specified event (key) if one exists.
 *
 * @param wid    Window id of window that should perform the command for the specified key
 * @param event  Key or key combination to use to find the command bound to that key.  The values
 *               come from vsevents.h
 * @param checkCtrlAlt
 *               Flag: 1 to also check for CONTROL and/or ALT modifier keys being pressed before the key is executed, 0 to ignore the modifier keys
 *
 * @return 0 if no command for the specified key or key sequence.  -1 if command found
 *
 * @categories Keyboard_Functions
 */
int VSAPI vsMaybeExecuteKey(int wid, int event, int checkCtrlAlt);

/**
 *
 * Returns command index of command bound to the specified event (key)
 *
 * @param wid   Window id of window that is the context for the key.  This is
 *              important because some key bindings are "document mode" dependent
 * @param event The key or key sequence we want to find the bound command for.  Values come from
 *              vsevents.h
 *
 * @return 0 if no command is bound to this key, otherwise it returns the command index
 *
 * @categories Names_Table_Functions
 *
 **/
int VSAPI vsCommandIndexForKey(int wid, int event);


int VSAPI vsX11ActivateFirstInstance(const char * commandLine);
   #if 0
      int VSAPI vsXDispatchXEvent(XEvent * pevent);
      void VSAPI vsXRegisterKeysToIgnore(unsigned int startKey,unsigned int endKey
                                         ,unsigned int shift
                                         ,unsigned int control
                                         ,unsigned int alt
                                         ,unsigned int anyKey VSDEFAULT(1));
      void VSAPI vsXRegisterX11Dispatcher(int (*xdispatcher)(XEvent * event));
      void VSAPI vsXIdleProcessing();
      void VSAPI vsKillFocus(int wid);
      // Register a function to allocate a pixel given an RGB tripple.
      // The function must have the following functionality:
      //
      //    colorAllocProc returns a pixel given the RGB values.
      //    colorAllocProc also returns the actual RGB values of the
      //    returning pixel. This is needed in case an approximation
      //    is used for "closest".
      //
      //    If closest is 1, colorAllocProc MUST allocate a pixel. If an
      //    exact match is not found, return an existing pixel with a closest
      //    matching RGB value. When closest is 1, colorAllocProc always
      //    return 0 to indicate a success completion.
      //
      //    When closest is 0, the proc should return 0 for success
      //    pixel allocation and !0 for error.
      void vsXRegisterColorAllocProc(int (*colorAllocProc)(int rgb,
                                                           int closest,
                                                           unsigned long * returnPixel,
                                                           int *returnActualRGB
                                                           )
                                     );
      // Register a function to free a pixel previously allocated by
      // calling colorAllocProc.
      // The function must have the following functionality:
      //
      //    colorDeallocProc should return 0 for success and !0 for error.
      void vsXRegisterColorDeallocProc(int (*colorDeallocProc)(unsigned long pixel));
      // Register a function to set the mouse pointer shape for the shell
      // container that holds the editor control. All other shells created
      // by the editor control will not be affected.
      // Function param:
      //    cursor must be either an X window cursor or
      //           0 to clear the cursor (ie. XUndefineCursor())
      void vsXRegisterResetCursorProc(void (*resetCursorProc)(int editorID, // editor control ID
                                                              Cursor cursor)
                                      );
      // Set the foreground and background color of the specified editor control.
      // These colors affect the colors of dialogs created by the editor control.
      // Color coding colors are not affected.
      //
      // NOTE: For now, the changes are global and not per editor control.
      //       Pass 0 for editorID. Call before calling vsCreateEditorCtl().
      void vsXSetEditorColors(int editorID,
                              int bgRGB,
                              int fgRGB
                              );
      // Set the foreground and background scrollbar colors for the specified
      // editor control.
      //
      // NOTE: For now, the changes are global and not per editor control.
      //       Pass 0 for editorID. Call before calling vsCreateEditorCtl().
      void vsXSetScrollBarColors(int editorID,
                                 int bgRGB,
                                 int fgRGB,
                                 int troughRGB,
                                 int seRGB,
                                 int tsRGB,
                                 int bsRGB
                                 );
      // Set the scrollbar size attributes the specified editor control.
      //
      // NOTE: For now, the changes are global and not per editor control.
      //       Pass 0 for editorID. Call before calling vsCreateEditorCtl().
      void vsXSetScrollBarSizes(int editorID,
                                unsigned int bodyWidth,
                                unsigned int shadowThickness, // 1 or 2
                                unsigned int highlightThickness, // unsused
                                unsigned int borderWidth // unused
                                );
      // Register a shadow color calculating procedure.
      //
      // The proc performs the following:
      //    Given the background RGB color value, calculates the matching
      //    foreground, top shadow, bottom shadow, and select/recessed RGB color
      //    values.
      void vsXRegisterQueryShadowColors(void (*proc)(int bgRGB,
                                                     int * fgRGB, // return best foreground color for max contrast
                                                     int * tsRGB, // return top shadow
                                                     int * bsRGB, // return bottom shadow
                                                     int * seRGB  // return select/recessed color
                                                     )
                                        );
      // Check to see if the specified X window is a descendant of some
      // editor control. If so, return the editor control's ID.
      // Retn: editor control ID,
      //       0 for X window not descendant of any editor control
      int vsXWindowToEditorID(Window xw);
      // Register a callback to receive all X events that gets pulled off
      // the X event queue by the editor control.
      //
      // The proc return value has the following meaning.
      // Retn: 1 to indicate that the event has been used by the callback
      //         and that the editor control should ignore it. Please note
      //         that certain event like BUTTONRELEASE should not be
      //         consumed because it may cause the editor control to lose
      //         its state.
      //       0 to indicate that the event should be processed normally
      //         by the editor control
      void vsXRegisterTightLoopPeekProc(int (* proc)(XEvent * event));
      // Register a function to get, peek, and check for pending X event.
      //
      // The proc parameters are:
      //    display  ==> X connection
      //    mode     ==> 0 -- Check to see if there is at least one pending X event.
      //                      Return 1 to indicate event pending, 0 for none pending.
      //                 1 -- Get the next X event. If none, block and wait until one is available.
      //                      Return 0.
      //                 2 -- Peek the next X event. If none, block and wait until one is available.
      //                      Return 0.
      //                 3 -- Put the specified X event back onto its queue.
      //    event    ==> Returning X event for "get" and "peek" modes
      void vsXRegisterXGetEvent(int (*proc)(Display * display, int mode, XEvent * event));
   #endif

#endif

/**
 * This function is called after an mdi window has files dropped 
 * on it. <code>dropFiles</code> contains the list of filenames. 
 * Specify editor window <code>atWid &gt; 0</code> to drop files
 * into the tab group that hosts that specific editor window.
 *
 * @param dropFiles 
 * @param atWid 
 *
 * @categories File_Functions
 */
void VSAPI vsDropFiles(slickedit::SEArray<slickedit::SEString> dropFiles, int atWid VSDEFAULT(0));

enum vsDockingArea {
   VSDOCKINGAREA_NONE   = 0,
   VSDOCKINGAREA_LEFT,
   VSDOCKINGAREA_TOP,
   VSDOCKINGAREA_RIGHT,
   VSDOCKINGAREA_BOTTOM,

   VSDOCKINGAREA_FIRST = VSDOCKINGAREA_LEFT,
   VSDOCKINGAREA_LAST = VSDOCKINGAREA_BOTTOM,

   // Unspecified (ALL in some contexts)
   VSDOCKINGAREA_UNSPEC = -1
};

enum vsCorner {
   VSCORNER_TOPLEFT = 0,
   VSCORNER_TOPRIGHT,
   VSCORNER_BOTTOMLEFT,
   VSCORNER_BOTTOMRIGHT,

   VSCORNER_FIRST = VSCORNER_TOPLEFT,
   VSCORNER_LAST = VSCORNER_BOTTOMRIGHT
};

/**
 * <p>This function sets the active MDI child edit window.  This function
 * must be called by OEM's who implement our MDI API so Visual
 * SlickEdit knows at all times which edit window is active.  This
 * function is called during the Windows WM_ACTIVATE message or
 * during the MFC  CView::OnActivateView handler.</p>
 *
 * <p>See our MDI sample program for an example.</p>
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @categories Miscellaneous_Functions
 *
 */
void VSAPI vsMDISetActiveChild(int wid);

/**
 * Retrieve the registered MDI child (p_mdi_child != 0) from an
 * MDI child form.
 *
 * @param wid MDI child form which contains the registered MDI
 *            child (p_mdi_child == _mdi).
 *
 * @return Window id of registered MDI child.
 */
int VSAPI vsMDIGetChildFromForm(int wid);

/**
 * Retrieve the MDI child form that contains the registered MDI
 * child (p_mdi_child != 0).
 *
 * @param wid Registered MDI child (p_mdi_child != 0) which is
 *            contained by MDI child form.
 *
 * @return Window id of MDI child form.
 */
int VSAPI vsMDIGetFormFromChild(int wid);

/**
 * Create a new horizontal tabgroup from editor control
 * specified by <code>wid</code>. If editor control is already
 * part of a tabgroup, then it is removed and inserted into new
 * tabgroup.
 *
 * @param wid  Editor control window handle returned from 
 *             vsCreateEditorCtl.
 * @param insertAfter  Set to tre to insert after wid;
 */
void VSAPI vsMDIChildNewHorizontalTabGroup(int wid,int insertAfter);

/**
 * Create a new vertical tabgroup from editor control
 * specified by <code>wid</code>. If editor control is already
 * part of a tabgroup, then it is removed and inserted into new
 * tabgroup.
 * 
 * @param wid    Editor control window handle returned from
 *               vsCreateEditorCtl.
 * @param insertAfter  Set to tre to insert after wid;
 */
void VSAPI vsMDIChildNewVerticalTabGroup(int wid,int insertAfter);


/**
 * Return window id most recently active MDI window
 *  
 *  
 * @return Return window id of most recently active MDI 
 *         window
 */
int VSAPI vsMDICurrent();
/**
 * Return current mdi child window id of the specified MDI  
 * window.
 *  
 * @param mdi_wid   Window of an MDI mnain window 
 *  
 * @return Return current mdi child window id of the 
 * specified MDI window. 
 */
int VSAPI vsMDICurrentChild(int mdi_wid);

/**
 * Returns non-zero value if MDI child edit window is 
 * visible 
 *  
 * @param wid   MDI child edit window
 *  
 * @return Returns non-zero value is MDI child window is visible
 */
int VSAPI vsMDIChildIsVisible(int wid);
/**
 * Get MDI window window id for a particular MDI child edit 
 * window 
 *  
 * @param wid   MDI child edit window
 *  
 * @return Return MDI window window id for a particular MDI 
 * child edit window 
 */
int VSAPI vsMDIFromChild(int wid);
/**
 * Get MDI tab group ID for a particular MDI 
 * child edit window 
 *  
 * @param wid   MDI child edit window
 *  
 * @return Return MDI tab group ID for a 
 * particular MDI child edit window 
 */
VSUINT64 VSAPI vsMDITabGroupIDFromChild(int wid);

/**
 * Float/dock MDI child window <code>wid</code>.
 * 
 * @param wid 
 */
void VSAPI vsMDIChildFloatWindow(int wid,int doFloat);

/**
 * Return 1 if MDI child window <code>wid</code> is a 
 * floating window, 0 if a docked window. 
 *  
 * @param wid
 *
 * @return int.
 */
int VSAPI vsMDIChildIsFloating(int wid);

/** 
 * Use this function if you want duplicate windows viewing 
 * the same buffer to display a unique duplicate window id. 
 *  
 * Call this in your pfnMDIUpdateEditorStatus callback.  If true 
 * is returned, call vsRefresh(). For better performance, 
 * post yourself an event in your  pfnMDIUpdateEditorStatus 
 * callback which calls vsMDIRefreshDuplicateWindows and 
 * does a vsRefresh if necessary. 
 *  
 * @return Returns true if vsRefresh() needs to be called.
 */
bool VSAPI vsMDIRefreshDuplicateWindows();
/**
 * SlickEdit seems to use the functions in its MDI frame window
 * procedure during a WM_SETFOCUS message to adjust the focus.  We
 * are not sure if this is necessary so we have left the function.
 *
 * @return Returns non-zero value if focus was set to a modal dialog box.
 *
 * @categories Editor_Control_Functions
 *
 */
int VSAPI vsSetFocusToModalDialog();
/**
 * Finds most recent modal dialog
 *
 * @return Retunws window id of most recent modal dialog.
 *         Returns 0 if non exist.
 */
int VSAPI vsModalDialog();
int VSAPI vsAppHasFocus();
/**
 * Perform some Qt options before creating QApplication 
 *  
 * <p>Optionally parses args and sets GUI Style 
 * (QApplication::setStyle()). 
 * <p>On Unix, Sets default Qt graphics system to "raster" or 
 * "native" (QApplication::setGraphicsSystem())
 * <p>On Mac, initializes Cocoa Application class 
 *  
 * @param argc Optional args to parse for GUI Style options
 * @param argv Optional args to parse for GUI Style options
 */
void VSAPI vsQTBeforeCreatingQApplication(int argc=0,char **argv=0);
void VSAPI vsQTAfterCreatingQApplication();

/**
 * Used to wrapper calling native dialogs and making them 
 * modal. 
 *  
 * <p>Currently, this is only supported on Windows. 
 *  
 * @param owner_wid  Window id of parent owner dialog
 * 
 * @return Pointer to handle used by vsQTLeaveNativeModal to 
 *         exit the modal dialog.
 */
void *vsQTEnterNativeModal(int owner_wid);
void vsQTLeaveNativeModal(void *phandle);
/**
 * SlickEdit uses the server name to communicate with other
 * instances of the editor and for DDE.
 *
 * @return Returns pszServerName.
 *
 * @param pszServerName	Ouput buffer for server name.  The server
 * name is set by the vsInit call by VSINIT.
 * pszServerNamePrefix.  This can be 0.
 *
 * @param MaxServerNameLen	Number of characters allocated to
 * <i>pszServerName</i>.  We recommend
 * you this be VSMAXSERVERNAME.
 *
 * @param pMaxServerNameLen	If this is not 0, this is set to the exact
 * number of characters you need to allocate.
 *
 * @categories Miscellaneous_Functions
 *
 */
void VSAPI vsGetServerName(char *pszServerName,int MaxServerNameLen,int *pMaxServerNameLen VSDEFAULT(0));
/**
 * Indicates whether this is an editor control hosted with a 
 * non-Qt parent window.
 * 
 * @author cmaurer (7/31/2012)
 * 
 * @param wid 
 * 
 * @return bool  Returns true if the parent window is not a 
 *         QWidget.
 */
bool VSAPI vsIsTopLevelEditorCtl(int wid);

EXTERN_C_END


typedef struct {
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.

       REMARKS
          Forces the command line paint messages to update
   */
   void (VSAPI *pfnCmdLineUpdateWindow)(int wid);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.

       REMARKS
          Sets focus to the command line.
   */
   void (VSAPI *pfnCmdLineSetFocus)(int wid,int Reserved);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.

       RETURN
          Returns editor control window handle.  This function
          is clearly needed when the "wid" parameter is 0.
          We also call this function when "wid" is not 0 in
          which case you should just return "wid".
   */
   int (VSAPI *pfnCmdLineQEditorCtl)(int wid);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.

       REMARKS
          Moves the cursor one character to the left.
   */
   void (VSAPI *pfnCmdLineLeft)(int wid);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.

       REMARKS
          Moves the cursor one character to the right.
   */
   void (VSAPI *pfnCmdLineRight)(int wid);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.

       REMARKS
          (Like Backspace) Deletes the previous character.
   */
   void (VSAPI *pfnCmdLineRubout)(int wid);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.

       REMARKS
          (Like the Del key) Deletes the character under the
          cursor.
   */
   void (VSAPI *pfnCmdLineDeleteChar)(int wid);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.
          StartCol  Start column of selection. 1 specifies
                    first character.  Do nothing if
                    less than 1.
          EndCol    End column of selection. 1 specifies
                    first character.  Do nothing if
                    less than 1.

       REMARKS
          Sets the cursor and the selection.
          If StartCol==EndCol, just place the cursor.
          If EndCol<StartCol then the cursor is placed
          at the left of the selection.
   */
   void (VSAPI *pfnCmdLineSetSel)(int wid,int StartCol,int EndCol);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.
          pStartCol  Set to start column of selection or
                     cursor position if their is no selection.
                     1 specifies first character.
          pEndCol    Set to End column of selection or
                     cursor position if their is no selection.
                     1 specifies first character.
   */
   void (VSAPI *pfnCmdLineGetSel)(int wid,int *pStartCol,int *pEndCol);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.
          pPrompt   Prompt to be displayed before command line.
          PromptLen  Number of characters in prompt.

       REMARKS
          Sets the prompt displayed before the command line.
   */
   void (VSAPI *pfnCmdLineSetPrompt)(int wid,const char *pPrompt,int PromptLen);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.
          pBuf      New text for command line.
          BufLen    Number of characters pBuf.

       REMARKS
          Sets the text displayed on the command line.
   */
   void (VSAPI *pfnCmdLineSetText)(int wid,const char *Buf,int BufLen);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.
          pBuf      New text for command line.
          BufLen    Number of characters pBuf.

       REMARKS
          Inserts or replaces characters as if the user typed them from
          the keyboard.  This should replace the characters if
          currently in replace mode.
   */
   void (VSAPI *pfnCmdLineKeyin)(int wid,const char *pBuf,int BufLen);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.
          pBuf        Set to command line text
          MaxBufLen   Number of characters allocated to pBuf.
          pMaxBufLen  If not 0, this is set to the number of
                      characters required by pBuf.

       REMARKS
          Retrieves the text on the command line.
   */
   void (VSAPI *pfnCmdLineGetText)(int wid,char *pBuf,int MaxBufLen,int *pMaxBufLen);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.
          pBuf        Set to command line prompt
          MaxBufLen   Number of characters allocated to pBuf.
          pMaxBufLen  If not 0, this is set to the number of
                      characters required by pBuf.

       REMARKS
          Retrieves the text on the command line prompt.
   */
   void (VSAPI *pfnCmdLineGetPrompt)(int wid,char *pBuf,int MaxBufLen,int *pMaxBufLen);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.

       RETURN
          Returns the current insert/replace mode state.
   */
   int (VSAPI *pfnCmdLineQInsertState)(int wid);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.
          OnOff     New instert/replace mode state.

       REMARKS
          Sets the insert/replace mode state.  When in
          replace mode characters of replaced as the
          user types.
   */
   void (VSAPI *pfnCmdLineSetInsertState)(int wid,int OnOff);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.
          visible   New visible state of command line.

       REMARKS
          Determines whether command line and prompt are visible.
   */
   void (VSAPI *pfnCmdLineSetVisible)(int wid,int visible);
   /*

       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.  This may be 0.
                    You can use this to determine the command
                    line instance, if you have different
                    command lines for each editor control.
          pBuf      New text for command line.
          BufLen    Number of characters pBuf.
          StartCol  Start column of selection. 1 specifies
                    first character.  Do nothing if
                    less than 1.
          EndCol    End column of selection. 1 specifies
                    first character.  Do nothing if
                    less than 1.

       REMARKS
          Sets the cursor and the selection.
          If StartCol==EndCol, just place the cursor.
          If EndCol<StartCol then the cursor is placed
          at the left of the selection.
   */
   void (VSAPI *pfnCmdLineSetTextAndSel)(int wid,const char *Buf,int BufLen,int StartCol,int EndCol);
   /*
	  Registers an alert in the alert field of the status area.
    */
   void (VSAPI *pfnCmdLineRegisterAlert)(int alertGroupID);
   /*
	  Unregisters an alert in the alert field of the status area.
    */
   void (VSAPI *pfnCmdLineUnregisterAlert)(int alertGroupID);
   /*
	  Activates an alert in the alert field of the status area.
	*/
   void (VSAPI *pfnCmdLineActivateAlert)(int alertGroupID, int alertID, const char* msg, const char* header, int showToast);
   /*
	  Deactivates an alert in the alert field of the status area.
	*/
   void (VSAPI *pfnCmdLineDeactivateAlert)(int alertGroupID, int alertID, const char* msg, const char* header, int showToast);
   /*
	  Clears the last active alert for an alert group.
	*/
   void (VSAPI *pfnCmdLineClearLastAlert)(int alertGroupID, int alertID);
   /*
	  Sets the status for an alert group
	*/
   void (VSAPI *pfnCmdLineSetAlertGroupStatus)(int alertGroupID, int enabled, int showPopups);
   /*
	   Sets the status for an alert
	*/
   void (VSAPI *pfnCmdLineSetAlertStatus)(int alertGroupID, int alertID, int enabled, int showPopups);
   /*
	  Returns info about an alert group
	*/
   void (VSAPI *pfnCmdLineGetAlertGroup)(int alertGroupID, VSHREFVAR alertGroup);
   /*
	  Returns info about an alert
	*/
   void (VSAPI *pfnCmdLineGetAlert)(int alertGroupID, int alertID, VSHREFVAR alert);
   void (VSAPI *pfnjunk3)();
   void (VSAPI *pfnjunk4)();
   void (VSAPI *pfnjunk5)();
   void (VSAPI *pfnjunk6)();
   void (VSAPI *pfnjunk7)();
   void (VSAPI *pfnjunk8)();
   void (VSAPI *pfnjunk9)();
   void (VSAPI *pfnjunk10)();
} VSCMDLINE_FUNCTIONS;

/*
    This API version has nothing to do with the editor version.
*/
#define VSAPIVERSION  4
typedef struct {
/*****************Some Required fields********************************/
   /*
       Set this field to VSAPIVERSION.
   */
   int ApiVersion;
   /*
       Windows Win32 Application: (HINSTANCE) Application hinstance.
       UNIX GTK app:  This is an X Display
   */
#if VSUNIX
   Display * hinstance;
#else
   void *hinstance; /*HINSTANCE*/
#endif

   /*
         If this ends with a trailing backslash, this is the
         path to the SlickEdit binaries directory.
         Otherwise this is the executable name and path.  Where
         path is to the executable SlickEdit binaries directory.
         Prior to version 12, this was always a path.
   */
   const char *pszExecutablePath;
   /*
       OEM's should place all invocation options in the
       "Environment" section of the vslick.ini file in a variable
       called VSLICK.  For now, we recommend you set argc and
       argv to 0.  You can use other API's to do things like
       open a file and go to a line.

       SlickEdit uses (argc,argv) for historical reasons.

       Invocation arguments are concatenated as follows before they are
       processed.

          %VSLICK%" "argv[0]" "argv[1]" "argv[2]"...

       Double quotes are placed around argv[i] arguments which have
       spaces.
   */
   int argc;     // Number of null terminated strings in argv
   char **argv;  // Array of null terminated strings
   /*
         REMARKS:
              Specifies a directory to store configuration files.
              OEM's must always specify a configuration directory that
              does not conflict with the configuration directory
              SlickEdit uses for SlickEdit customers.
              SlickEdit will attempt to create this
              directory if it does not exist.

         OEM directory layout
            <OEMproduct>\vslick\win\    SlickEdit binaries
            <OEMproduct>\vslick         Global configuration directory or
                                        single user configuration directory
            <OEMproduct>\vslick\bitmaps  Editor bitmaps
            <OEMproduct>\vslick\macros   Macro pcode and macro source

         Windows:
           Single user with one configuration.

               Set this to <OEMproduct>\vslick

           Multiple users where each has their own configurations.


               Set this to <OEMproduct>\vslick\<UserName>

               If your product can not determine a unique user
               name, then require each user to specify a user
               configuration directory. You could have the user
               set an environment variable to a directory.  If
               you do this, make sure your environment variable name
               is unique and not SLICKEDITCONFIG which is used by our
               stand alone product.


         UNIX:

           Multiple users with multiple configurations.

               Build a directory based on the users HOME directory
               as follows:

                "$HOME/.vslick<OEMProduct>"


    SlickEdit always sets this value to null (only SlickEdit should
    do this) and constructs this directory as follows:

         Both:     The value of the SLICKEDITCONFIG environment variable
                   is used, and a versioned configuration directory is
                   selected.

         Windows:  If neither environment variable is set, we will use
                   a versioned directory underneath "My SlickEdit Config"
                   in the user's "My Documents" directory.

         Unix:     If neither environment variable is set, we will use
                   a versioned directory underneath ".slickedit"
                   in the user's home directory ($HOME).

   */
   const char *pszConfigDir;
   /*
        Default message box title.
   */
   const char *pszApplicationName;
   /*
       Various API flags indicating additional support you want.
   */

//Indicates that you want us to auto restore MDI Edit windows.
#define VSAPIFLAG_SAVERESTORE_EDIT_WINDOWS  0x1
/*
   Indicates you want to use our toolbars.  OEMs must turn
   this off.
*/
#define VSAPIFLAG_TOOLBAR_DOCKING           0x2
/*
   Indicates you want to use the default SlickEdit menu bar.
*/
#define VSAPIFLAG_MDI_MENUS                 0x4
/*
   Indicates that you are using our MDI interface in addition
   to the editor control.
*/
#define VSAPIFLAG_MDI_WINDOW                0x8
/*
   Indicates that the command line color is configurable.

   For now flag is reserved for SlickEdit Inc.
*/
#define VSAPIFLAG_CONFIGURABLE_CMDLINE_COLOR     0x10
/*
   Indicates that the command line font is configurable.

   For now flag is reserved for SlickEdit Inc.
*/
#define VSAPIFLAG_CONFIGURABLE_CMDLINE_FONT      0x20
/*
   Indicates that the status line color is configurable.

   For now flag is reserved for SlickEdit Inc.
*/
#define VSAPIFLAG_CONFIGURABLE_STATUS_COLOR      0x40
/*
   Indicates that the status line font is configurable.

   For now flag is reserved for SlickEdit Inc.
*/
#define VSAPIFLAG_CONFIGURABLE_STATUS_FONT       0x80
/*
   Indicates that the "Alt Menu Hotkeys" menu item
   on the Gerneral Tab should be enabled.

   Don't use this flag unless your menu bar hot keys
   exactly match SlickEdit or you make a custom
   version of "guisetup.e".  Note that
   SlickEdit changes the hot keys when you change
   emulations.

   We do not feel that this option is important enough
   for you to support. A user can manually unbind keys
   for which he or she wants to activate the menu bar.
   This option has NO EFFECT on our default CUA emulation.
*/
#define VSAPIFLAG_CONFIGURABLE_ALT_MENU_HOTKEYS  0x100
/*
   Indicates that the "Alt Menu Hotkeys" menu item
   on the Gerneral Tab should be enabled.

   If your MDI application has not problems support
   next_buffer when our "One File per Window" option
   is off, then you should OR in this flag.
*/
#define VSAPIFLAG_CONFIGURABLE_ONE_FILE_PER_WINDOW  0x200
/*
   Indicates that the "Visual C++ Setup..." menu item
   should be displayed on the configuration menu.

   Also tells VSE to put itself on the msdev toolbar or
   menu bar and perform other tighter integration
   operations.
*/
#define VSAPIFLAG_CONFIGURABLE_VCPP_SETUP           0x400
/*
   When this is on, all open file dialogs show
   extensions.

*/
#define VSAPIFLAG_OVERRIDE_EXPLORER_HIDE_EXTENSIONS 0x800
/*
   When this is on and a VSE dialog box is running, the
   user can edit via keyboard or windows system menu "edit form".

*/
#define VSAPIFLAG_ALLOW_DIALOG_EDITING              0x1000

/*
   Indicates whether access to project commands should
   be allowed.

   Also indicates whether dialog boxes to show VSE projects.
     When off
       * The extension options dialog will disable the
         "Extension Specific Project..." button
       * The Check In and Check Out dialog boxes will disable
         the "Open Project..." and "Edit Project..." buttons.

*/
#define VSAPIFLAG_ALLOW_PROJECT_SUPPORT             0x2000
#define VSAPIFLAG_ALLOW_DIALOG_ACCESS_TO_PROJECTS   VSAPIFLAG_ALLOW_PROJECT_SUPPORT
/*
    Allow working directory to be restored.
*/
#define VSAPIFLAG_SAVERESTORE_CWD                   0x4000

/*
    goto_bookmark is implemented such that it can
    restore bookmarks to deleted editor controls which
    have a non-null VSP_BUFNAME
*/
#define VSAPIFLAG_GOTO_BOOKMARK_RESTORES_BY_FILENAME         0x8000
/*
    goto_bookmark is implemented such that it can
    restore bookmarks to deleted editor controls which
    have a non-null VSP_DOCUMENTNAME.
*/
#define VSAPIFLAG_GOTO_BOOKMARK_RESTORES_BY_DOCUMENTNAME     0x10000
/*
    Indicates whether VSINIT.pszExecutablePath is absolute.
*/
#define VSAPIFLAG_EXECUTABLE_PATH_IS_ABSOLUTE                0x20000
/*
    Indicates whether dialogs should show a system
    menu.  At the moment, this only supports windows.
*/
#define VSAPIFLAG_SHOW_DIALOG_SYSTEM_MENU                    0x40000
#define VSAPIFLAG_DATASET_SUPPORT                            0x80000
#define VSAPIFLAG_UTF8_SUPPORT                              0x100000
#define VSAPIFLAG_UNICODE_MESSAGE_LOOP                      0x200000

/*
    Indicates that we are running in Eclipse/Webphere
*/
#define VSAPIFLAG_ECLIPSE_PLUGIN                             0x400000

/*
   Allow commands related to minimizing, maximizing, restoring,
   and iconizing a window
*/
#define VSAPIFLAG_ALLOW_MINMAXRESTOREICONIZE_WINDOW          0x800000
/*
   Allow commands related to tiled windowing.
*/
#define VSAPIFLAG_ALLOW_TILED_WINDOWING                     0x1000000

/*
   Allow java gui builder commands.
   IMPORTANT:  This flag will be turned off if the
       VSAPIFLAG_UTF8_SUPPORT flag is off because transfering
       data between the gui builder and
*/
#define VSAPIFLAG_ALLOW_JGUI_SUPPORT                        0x2000000

/**
 * Indicates that we are running in the context of Visual Studio
 */
#define VSAPIFLAG_VISUALSTUDIO_PLUGIN                       0x4000000

/*
   When this is on and a VSE dialog box is running, the
   user can invoke Slick-C debugging via windows system
   menu "Debug Slick-C"
*/
#define VSAPIFLAG_ALLOW_DEBUG_SLICKC                        0x8000000
/*
   Indicates that the OEM is using QT.

   NOTE: There is no VSAPIFLAG_USING_GTK. For GTK, do not specify this
   flag and link with libvsapiGTK.so

*/
#define VSAPIFLAG_USING_QT                                 0x10000000

/** 
 * Allow commands related to MDI tabgroups. Note that when 
 * including this flag, you probably do NOT want to include: 
 * 
 * <li>VSAPIFLAG_ALLOW_MINMAXRESTOREICONIZE_WINDOW 
 * <li>VSAPIFLAG_ALLOW_TILED_WINDOWING 
 *
 * and you should implement 
 * <code>pfnMDIChildNewHorizontalTabGroup</code>. 
 */
#define VSAPIFLAG_MDI_TABGROUPS                            0x20000000

#define VSAPIFLAG_CONFIGURABLE_DOCUMENT_TABS_FONT          0x40000000


   int APIFlags;
   int APIFlags2;  // Reserved for future use.

   /*
       These fields are reserved for SlickEdit.
   */
   int packFlags1;
   int packFlags2;

   void *Reserved[8];

/*****************Some optional fields********************************/
   /*
        Array of pointers to environment strings where the last pointer
        in the array is null (ppEnv[lastvalid+1]==NULL).

        Windows C++ runtimes.  Set this to _environ variable.

        UNIX C++ runtimes.  Set this to environ variable.
   */

   char **ppEnv;
   /*
        Function to display one line message.  This function must NOT
        create a new window like a message box would.

        PARAMETERS
           wid           This parameter is always 0 which indicates
                         that this function pointer
                         came from vsinit and does not have an
                         associated editor control.  This extra
                         parameter is here so that you can use
                         the same message callback function
                         for specific editor controls.
           pszMsg        Null terminated string to display.
           Immediate     Display message now instead of invalidating
                         the message area so a paint message is
                         received later.
                         UNIX: Be sure to call XFlush to flush display
                         output or a similar function.


   */
   void (VSAPI *pfnMessage)(int wid,const char *pszMsg,int Immediate);
   /*
       Function to retrieve message currently displayed.  During
       auto restore messages get displayed.  However, we restore
       the original message when auto save is done.

       PARAMETERS
          wid            This parameter is always 0 which indicates
                         that this function pointer
                         came from vsinit and does not have an
                         associated editor control.  This extra
                         parameter is here so that you can use
                         the same message callback function
                         for specific editor controls.
          pszMsg         If this is not null this is
                         set to null terminated string
                         containing message.  This can be 0.
          MaxMsgLen      Number of bytes allocated to pszMsg.  No
                         more than this many bytes may be written.
                         pszMsg[MaxStringLen] IS NOT VALID MEMORY.
          pMaxMsgLen     If this not 0, this is set to the number of
                         characters you need to allocate to pszMsg.
   */
   void (VSAPI *pfnGetMessage)(int wid, char *pszMsg,int MaxMsgLen, int *pMaxMsgLen);
   /*
       The pfnExit callback is called to exit the editor.
       Currently only two commands call this function

           safe_exit  -- This is only called for an MDI
                         application which uses our MDI
                         API's.
           fexit      -- This command is NEVER bound to a key
                         or menu.  It is typically only used
                         by the developers of VSE to
                         force an editor exit without
                         saving anything.

       In addition to this call back you may want to
       write a replacement function for the _QueryEndSession
       function using the vsLIBExport or vsDLLExport API.
       The _QueryEndSession function gets called when the
       safe_exit command is executed.  The safe_exit command
       only gets executed for MDI applications which use our
       MDI API's.
   */
   void (VSAPI *pfnExit)(int retcode);
   /*
       This callback is called when you call vsInit.  It occurs
       after all options have been set including after macros
       have been loaded but before any macros have been executed.

       At the time of this API design we were not sure if there
       would be a need for this callback.  None of our sample
       applications use it yet.
   */
   void (VSAPI *pfnAfterOptionsSet)();
   /*
       This field indicates up to what version you will allow your
       customers to get a free upgrade.  Due to the flexability
       of the editor API, a user will likely be able to get
       a new vsapi.dll from our Web site or an OEM web site
       and get free enhancements to the editor control.

       Set this field to a version number without the decimal
       point.  For example, if you don't want your users to
       get anything free after version 3.1, set this version to
       31.  This will allow "3.1a", "3.1b" etc but not "3.2"
       editor DLL.

       UNIX: Since we don't expect to have an DLL version of
       the editor control on UNIX, you can leave this field
       0.

       Clearly this is not a full proof mechanism but it is
       better than nothing.
   */
   int FreeVSEUpgradeUpTo;
   /*
        (Defaults to off) When on, the SlickEdit version
        message is displayed when the editor starts.  In the future,
        this might be changed to display a splash screen but for
        now we like the speed of the current implementation.
   */
   int DisplayVersionMessage;
   /*
       This field is reserved for SlickEdit internal use.
   */
   char *pszSerialNumber;
   /*
       If this is not 0, the editor control will not
       allow files to be saved.
   */
   int Demo;
   /*
        Properly sets focus to an editor control window.

        SlickEdit macros can set focus to any editor
        control window.  This typically occurs after an editor
        command, which requires a command line, is executed.

        If you don't create dialog boxes with an editor
        control, you don't need to implement this function.

        This function is NOT called for MDI children with
        editor controls (see pfnMDIChildEditorCtlSetFocus).



       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.
   */
   void (VSAPI *pfnSetFocus)(int wid);
   /*
       This field is reserved for SlickEdit.  OEMs must specify
       0 for now.

       pszServerNamePrefix specifies server name prefix to create
       a unique server name that is used to communicate
       with other instances of SlickEdit and as the DDE
       server name if the  "SupportDDE" field is non-zero.


       SlickEdit reserves "SlickEdit" for this field.
   */
   const char *pszServerNamePrefix;

   /*

       This field is reserved for SlickEdit.  OEMs must specify
       0 for now.

       Windows only, ignored by other platforms.  When true,
       SlickEdit will register itself as a DDE server.
   */
   int SupportDDE;

   /*
      Windows only,  COM library has been initialized if specified.
      If 0, vsInit will initialize (CoInitialize) for main thread. 
   */
   int COMInit;

/*****************MDI fields******************************************/
/*
     OVERVIEW OF MDI INTERFACE
     While our editor control can be used to implement any
     MDI interface, we decided to include callbacks for supporting the
     very popular Windows MDI interface (We're not saying
     you must like it).  In Windows MDI, there is an MDI outerframe
     which contains child windows.


     If you have a Windows style MDI app, this MDI API will save
     you time implementing the following features:

          AutoRestore           Save and restore window/files when
                                application terminates or is invoked.
          Project AutoRestore   Save and restore window/files when
                                a project is closed or opened.
          Listing Buffers       Allows you to choose an editor window
                                or buffer and switch to that window/buffer.
          List modified         Allows you to select buffers to save.

          Multi-file search/replace
          File manager
          Slick-C&reg; dialog developement  Opens edit window and
                                       goes to source code for
                                       dialog boxes.
          Tiled windowing       Our tiled windowing works on multiple
                                mdi children.  Splitting a window creates
                                a new mdi child. While this is not
                                common in IDE's, SlickEdit
                                and EMACS users especially like this.

     All the above features require that we know how to switch to another
     window or create another window.  We recommend that you use our MDI
     callbacks if you are implementing an application with multiple
     identical-looking edit windows.

*/


   /*
       PARAMETERS
          mdi_wid           MDI frame window handle returned from
                            vsMDICreate.
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.
          pszCaption        Name for newly created window.
          x,y,width,height  Position and size of new window.  When
                            x==MAXINT then, a default size and
                            position must be used.

         WindowState        Initial window state.
                            One of the following values:

             0             Use your own default for the window state.  VS
                           will maximize a new MDI child if the current
                           mdi child is already maximized.

            'I'           Iconize the window
            'M'           Maximize the window
            'N'           Normalize the window
       create_window_invisible  When true, create window invisible

       REMARKS
            Create a new MDI Child window. Use vsCreateEditorCtl to
            create the editor control within your MDI Child.  You may
            only create one editor control on the mdi child during
            this callback.


       RETURN:
           Return 0 if successful.  If successful, the active window must
           be the editor control.  vsCreateEditorCtl sets the active
           window to the newly created control.  If you change the active
           window during the callback, use
           vsPropSetI(0,VSP_WINDOW_ID,editorctlwid) to set the active
           window.

   */
   int (VSAPI *pfnMDICreateEditWindow)(int mdi_wid,int wid,const char *pszCaption,
                              int x,int y,
                              int width,int height,
                              char WindowState,bool create_window_invisible);
   /*
       Destroy the MDI Child window and all controls on it.  You must
       use the vsDestroyEditorCtl function to destroy any editor controls.

       PARAMETERS
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.
   */
   void (VSAPI *pfnMDIDestroyEditWindow)(int wid);
   /*
       (Defaults to off)

       REMARKS
          Sets focus to a editor control window.

       PARAMETERS
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.
   */
   void (VSAPI *pfnMDIChildEditorCtlSetFocus)(int wid);
   /*

       REMARKS:
          This optional callback function is intended for creating
          an MDI frame window at the same location and size it was
          in the last edit session.

          Under UNIX we recommend you return 1 to indicate that
          that the x,y,width, and height were ignored.  It takes
          a lot of code to support all window managers and OS's.
          The same window manager on a different UNIX is NOT
          the same unfortunately.

          You must call the vsMDICreate function to create
          SlickEdit's instance data and set the owner system window
          used when creating some dialog boxes.


       RETURN
          0       If successful
          1       If successful but the mdi width or height was ignored.
          <0      Error

       PARAMETERS:
          x,y,width,height     Windows.  Outer window position and
                               size.
                               UNIX:  Depends on OS and Window
                               manager.  These coordinates are retrieved
                               by the pfnMDIGetWindow

         WindowState      one of the following values

             0             Use your own default for the window state.  VS
                           will maximize a new MDI child if the current
                           mdi child is already maximized.

            'I'           Iconize the window
            'M'           Maximize the window
            'N'           Normalize the window


   */
   int (VSAPI *pfnMDICreate)(int x,int y,int width,int height,
                        int icon_x,int icon_y,char WindowState);
   /*
       Set focus to the next MDI window which does not have to
       be an editor window.

       PARAMETERS
          mdi_wid           MDI frame window handle returned from
                            vsMDICreate.
   */
   void (VSAPI *pfnMDINextWindow)(int mdi_wid);
   /*
       Set focus to the previous MDI window which does not have to
       be an editor window.

       PARAMETERS
          mdi_wid           MDI frame window handle returned from
                            vsMDICreate.
   */
   void (VSAPI *pfnMDIPrevWindow)(int mdi_wid);
   /*
      PARAMETERS
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.

      RETURN
         Returns next editor control.  This function must not
         change focus.

   */
   int (VSAPI *pfnMDIQNextEditWindow)(int wid);
   /*
      PARAMETERS
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.

      RETURN
         Returns previous editor control.  This function must not
         change focus.

   */
   int (VSAPI *pfnMDIQPrevEditWindow)(int wid);
   /*
        PARAMETERS
          wid            Editor control window handle returned from
                         vsCreateEditorCtl.  This is set to
                         0 if there are no MDI children with
                         editor controls. You must check for this.
          RefreshFlags   Flags indicating what has changed.
          linenum        Line number. Update only if (RefreshFlags & VSREFRESH_LINE).
                         Not valid if ~(RefreshFlags & VSREFRESH_LINE).
                         If linenum is less than 0, this means VSE
                         does not know the current line
                         number.  This happens (by default) when
                         you load a file larger than 500k than
                         has no color coding defined.
          col            Column. Update only if (RefreshFlags & VSREFRESH_COL).
          pModeName      Mode name. Update only if (RefreshFlags & VSREFRESH_OTHER).
          ModeNameLen    Number of bytes in pModeName.
          StatusFlags    See VSSTATUSFLAG_???? defines.  Update only
                         if (RefreshFlags & CorrespondingRefreshFlag)

        REMARKS
           This callback is useful for an MDI frame window which contains
           clipped MDI children.  This allows you to update the status
           information displayed in the MDI frame window.  Although
           the buffer name is not passed to this function as an
           argument, this callback should check the VSREFRESH_BUFNAME
           flag and get the buffer name via the vsBufName2Caption function.

           If you do not have clipped MDI children, use the
           vsSetCallback function to define a callback for an editor
           control window.
   */
   void (VSAPI *pfnMDIUpdateEditorStatus)(int wid,int RefreshFlags,seSeekPos linenum,
                                          int col,const char *pModeName,int ModeNameLen,
                                          int StatusFlags,
                                          int reserved1);

   /*
       PARAMETERS
         mdi_wid     MDI frame window handle returned from
                     vsMDICreate.
         area        One of the VSDOCKINGAREA_??? constants indicate the
                     area a dock palette is located.

       Return
         Window id of dock-palette, 0 if does not exist, <0 on
         error.

       Remarks
         Returns window id of frame window (dock-palette) containing 
         docked windows for the specified docking <code>area</code>. 
         You should also implement the 
         <code>VSINIT.CallbackMDIDockingAreaChange</code> callback to 
         adjust your MDI client area. 

         This callback is only designed for MDI where the children are clipped
         inside.

         Currently this callback may only be used by SlickEdit.

   */
   int (VSAPI *pfnMDIQDockPalette)(int mdi_wid, vsDockingArea area);

   /*
       PARAMETERS
         mdi_wid     MDI frame window handle returned from
                     vsMDICreate.
         area        One of the VSDOCKINGAREA_??? constants indicate the
                     area a dock palette is located.
         form_wid    Dock-palette window id to set.

       Remarks
         Set dock-palette window for the specified <code>area</code> on 
         the MDI frame window. You should also implement the 
         <code>VSINIT.CallbackMDIDockingAreaChange</code> callback to 
         adjust your MDI client area. 

         This callback is only designed for MDI where the children are clipped
         inside.

         Currently this callback may only be used by SlickEdit.

   */
   void (VSAPI *pfnMDISetDockPalette)(int mdi_wid, vsDockingArea area, int form_wid);

   /*
       PARAMETERS
         mdi_wid     MDI frame window handle returned from
                     vsMDICreate.
         area        One of the VSDOCKINGAREA_??? constants indicate the
                     area a dock palette is located.

       Return
         Window id of dock-palette window, 0 if no dock-channel in area.

       Remarks
         Remove dock-palette window from specified <code>area</code> 
         on the MDI frame window. Dock-palette window is removed but 
         NOT deleted. You should also implement the 
         <code>VSINIT.CallbackMDIDockingAreaChange</code> callback to 
         adjust your MDI client area. 

         This callback is only designed for MDI where the children are clipped
         inside.

         Currently this callback may only be used by SlickEdit.

   */
   int (VSAPI *pfnMDIRemoveDockPalette)(int mdi_wid, vsDockingArea area);

   /*
       PARAMETERS
         mdi_wid     MDI frame window handle returned from
                     vsMDICreate.
         area        One of the VSDOCKINGAREA_??? constants indicate the
                     area a dock palette is located.

       Remarks
         Adjust dock-palette area. Typically this is called when a child of
         the dock-palette becomes visible so that the area can be resized. 

         This callback is only designed for MDI where the children are clipped
         inside.

         Currently this callback may only be used by SlickEdit.
   */
   void (VSAPI *pfnMDIDockPaletteSizeAdjust)(int mdi_wid, vsDockingArea area);

   /*
       PARAMETERS
         mdi_wid     MDI frame window handle returned from
                     vsMDICreate.
         area        One of the VSDOCKINGAREA_??? constants indicate the
                     area a dock-channel is located.

       Return
         Window id of dock-channel, 0 if does not exist, <0 on
         error.

       Remarks
         Returns window id of frame window (dock-channel) for the 
         specified docking <code>area</code>. You should also implement the 
         <code>VSINIT.CallbackMDIDockingAreaChange</code> callback to 
         adjust your MDI client area. 

         This callback is only designed for MDI where the children are clipped
         inside.

         Currently this callback may only be used by SlickEdit.

   */
   int (VSAPI *pfnMDIQDockChannel)(int mdi_wid, vsDockingArea area);

   /*
       PARAMETERS
         mdi_wid     MDI frame window handle returned from
                     vsMDICreate.
         area        One of the VSDOCKINGAREA_??? constants indicate the
                     area a dock palette is located.
         form_wid    Dock-palette window id to set.

       Remarks
         Set dock-channel window for the specified <code>area</code> on 
         the MDI frame window. You should also implement the 
         <code>VSINIT.CallbackMDIDockingAreaChange</code> callback to 
         adjust your MDI client area. 

         This callback is only designed for MDI where the children are clipped
         inside.

         Currently this callback may only be used by SlickEdit.

   */
   void (VSAPI *pfnMDISetDockChannel)(int mdi_wid, vsDockingArea area, int form_wid);

   /*
       PARAMETERS
         mdi_wid     MDI frame window handle returned from
                     vsMDICreate.
         area        One of the VSDOCKINGAREA_??? constants indicate the
                     area a dock palette is located.

       Return
         Window id of dock-channel window, 0 if no dock-channel in area.

       Remarks
         Remove dock-channel window from specified <code>area</code> 
         on the MDI frame window. Dock-channel window is removed but 
         NOT deleted. You should also implement the 
         <code>VSINIT.CallbackMDIDockingAreaChange</code> callback to 
         adjust your MDI client area. 

         This callback is only designed for MDI where the children are clipped
         inside.

         Currently this callback may only be used by SlickEdit.

   */
   int (VSAPI *pfnMDIRemoveDockChannel)(int mdi_wid, vsDockingArea area);

   /*
       PARAMETERS
         mdi_wid     MDI frame window handle returned from
                     vsMDICreate.
         area        One of the VSDOCKINGAREA_??? constants indicate the area
                     a dock channel is located.

       Remarks
         Adjust dock-channel area. Typically this is called when a child of
         the dock-channel becomes visible so that the area can be resized. 

         This callback is only designed for MDI where the children are clipped
         inside.

         Currently this callback may only be used by SlickEdit.
   */
   void (VSAPI *pfnMDIDockChannelSizeAdjust)(int mdi_wid, vsDockingArea area);
   /*
       REMARKS
          Tiles all mdi children.

       PARAMETERS
          mdi_wid           MDI frame window handle returned from
                            vsMDICreate.
   */
#define VSMDITILE_VERTICAL   0x1
#define VSMDITILE_HORIZONTAL 0x2
#define VSMDITILE_UNTILE     0x4
#define VSMDITILE_TILE       0x8
   void (VSAPI *pfnMDITileWindows)(int mdi_wid,int TileFlags);
   /*
       REMARKS
          Cascades all mdi children.

      PARAMETERS
         mdi_wid           MDI frame window handle returned from
                           vsMDICreate.
   */
   void (VSAPI *pfnMDICascadeWindows)(int mdi_wid);
   /*
       REMARKS
          Arranges iconized mdi children.

      PARAMETERS
         mdi_wid           MDI frame window handle returned from
                           vsMDICreate.
   */
   void (VSAPI *pfnMDIArrangeIcons)(int mdi_wid);

   /*
        PARAMETERS
          mdi_wid      MDI frame window handle returned from
                       vsMDICreate.
          sc           One of VSSC_??? constants which specify system
                       menu items.  For convenience these exactly match
                       the windows SC_??? constants.

        REMARKS
          Executes a system menu command which operates on the MDI frame
          window.

          This callback is required by the following commands:

             size_mdi
             move_mdi

   */
   void (VSAPI *pfnMDISysMenuCommand)(int mdi_wid,int sc);
   /*
        PARAMETERS
          wid   Editor control window handle returned from
                vsCreateEditorCtl.
          sc    One of VSSC_??? constants which specify system menu items.  For
                convenience these exactly match the windows SC_??? constants.

        REMARKS
          Executes a system menu command which operates on the MDI Child window
          corresponding to this editor control window handle.

          This callback is required by the following commands:

             size_window
             move_window

   */
   void (VSAPI *pfnMDIChildSysMenuCommand)(int wid,int sc);


   /*
        PARAMETERS
          mdi_wid      MDI frame window handle returned from
                       vsMDICreate.
          sc           One of VSSC_??? constants which specify system menu items.  For
                       convenience these exactly match the windows SC_??? constants.
          pszCaption   New menu item caption.

        REMARKS
          Changes the specified menu item in the MDI system menu to the
          caption given.

          This callback is here so that key binding changes in the editor
          match those displayed by the Operating System in the default
          system menu captions.

          UNIX: This callback is probably too difficult to implement for shell
          windows.
   */
   void (VSAPI *pfnMDISysMenuSetCaption)(int mdi_wid,int sc,const char *pszCaption);
   /*
        PARAMETERS
          wid          Editor control window handle returned from
                       vsCreateEditorCtl.
          sc           One of VSSC_??? constants which specify system menu items.  For
                       convenience these exactly match the windows SC_??? constants.
          pszCaption   New menu item caption.

        REMARKS
          Changes the specified menu item in the MDI Child system menu
          to the caption given.

          This callback is here so that key binding changes in the editor
          match those displayed by the Operating System in the default
          system menu captions.
   */
   void (VSAPI *pfnMDIChildSysMenuSetCaption)(int wid,int sc,const char *pszCaption);

   /*
       PARAMETERS
          wid       Editor control window handle returned from
                    vsCreateEditorCtl.

       Return
          'I'   MDI Child frame which belongs to this editor control is iconized.
          'M'   MDI Child frame which belongs to this editor control is maximized.
          'N'   MDI Child frame which belongs to this editor control is normal.

       Remarks
         The following editor commands require this callback

           zoom_window     -  Toggles the state of mdi child

   */
   char (VSAPI *pfnMDIChildQWindowState)(int wid);
   /*
       PARAMETERS
          wid      Editor control window handle returned from
                   vsCreateEditorCtl.
          state    One of the following character constants

             'I'   MDI Child frame which belongs to this editor control is iconized.
             'M'   MDI Child frame which belongs to this editor control is maximized.
             'N'   MDI Child frame which belongs to this editor control is normal.

       Remarks
         The following editor commands require this callback

           zoom_window     -  Toggles the state of mdi child

   */
   void (VSAPI *pfnMDIChildSetWindowState)(int wid,char state);

   /*
       PARAMETERS
          wid     Editor control window handle returned from
                  vsCreateEditorCtl.
          px,py,pwidth,pheight   (Ouput) Pixel coordinates of MDI child frame.

       Remarks
         The following editor commands require this callback

           vsplit_window   -  Reduces the size of the current MDI child
                              to half its horizontal size and creates a new MDI child
                              to the right to fill in the other half.
           hsplit_window   -  Reduces the size of the current MDI child
                              to half its vertical size and creates a new MDI child
                              below to fill in the other half.

   */
   void (VSAPI *pfnMDIChildGetWindow)(int wid,int *px,int *py,int *pwidth,int *pheight,char state);
   /*
       PARAMETERS
          wid      Editor control window handle returned from
                   vsCreateEditorCtl.
          x,y,width,height   Pixel coordinates to place the MDI child frame.

       Remarks
         The following editor commands require this callback

           vsplit_window   -  Reduces the size of the current MDI child
                              to half its horizontal size and creates a new MDI child
                              to the right to fill in the other half.
           hsplit_window   -  Reduces the size of the current MDI child
                              to half its vertical size and creates a new MDI child
                              below to fill in the other half.

   */
   void (VSAPI *pfnMDIChildSetWindow)(int wid,int x,int y,int width,int height,char state);

   /*
       PARAMETERS
          wid          Editor control window handle returned from
                       vsCreateEditorCtl.
          px,py       (Ouput) Pixel coordinates of iconized MDI child.

       REMARKS
         The following editor commands use this callback:

           save_window_config  - Saves MDI frame coordinates in auto-restore file.
           restore             - Attempts to restore MDI frame to original
                              size and position.
           project_close   -  Saves MDI frame coordinates in project file.
           project_open    -  Attempts to restore MDI frame to original
                              size and position.

   */
   void (VSAPI *pfnMDIChildGetIconXY)(int wid,int *px,int *py);
   /*
       PARAMETERS
          wid          Editor control window handle returned from
                       vsCreateEditorCtl.
          x,y          New pixel coordinates of iconized
                       MDI child

       REMARKS
         The following editor commands use this callback:

           save_window_config  - Saves MDI frame coordinates in auto-restore file.
           restore             - Attempts to restore MDI frame to original
                                 size and position.
           project_close   -  Saves MDI frame coordinates in project file.
           project_open    -  Attempts to restore MDI frame to original
                              size and position.

   */
   void (VSAPI *pfnMDIChildSetIconXY)(int wid,int x,int y);
   /*

       PARAMETERS
          mdi_wid           MDI frame window handle returned from
                            vsMDICreate.
       REMARKS
          Places MDI children with same tile id on top of the
          Z order
   */
   void (VSAPI *pfnMDIBringTilesToFront)(int mdi_wid,int TileID);
   /*
       PARAMETERS
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.
       RETURN
          Returns tile id of MDI child containing the editor control
          given.
   */
   int (VSAPI *pfnMDIChildQTileID)(int wid);
   /*
       PARAMETERS
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.
       REMARSK
          Sets tile id of MDI child containing the editor control
          given.
   */
   void (VSAPI *pfnMDIChildSetTileID)(int wid,int TileID);
   /*
       PARAMETERS
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.
          vsp_old           One of the constants VSP_X,VSP_Y, VSP_WIDTH,
                            VSP_HEIGHT
       RETURN
          Returns the corresponding MDI child window attribute
          specified by vsp_old in pixels.

   */
   int (VSAPI *pfnMDIChildQOldWindow)(int wid,int vsp_old);
   /*
       PARAMETERS
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.
       REMARKS
          Sets the corresponding MDI child window attribute specified by
          vsp_old in pixels.
   */
   void (VSAPI *pfnMDIChildSetOldWindow)(int wid,int vsp_old,int value);

   /*
       PARAMETERS
          mdi_wid           MDI frame window handle returned from
                            vsMDICreate.
          px,py,pwidth,pheight   (Ouput) Pixel coordinates of MDI frame.
         state       Reserved for later use.


       UNIX: Under UNIX it is very difficult to implement this function
       for shell windows (non-clipped windows) because Window managers
       handle decorations differently.  The same Window manager on a
       different OS can be different.
   */
   void (VSAPI *pfnMDIGetWindow)(int mdi_wid,int *px,int *py,int *pwidth,int *pheight,char state);
   /*
       PARAMETERS
         mdi_wid     MDI frame window handle
         x,y,width,height   Pixel coordinates to place the MDI frame.
         state       Reserved for later use.

       Remarks
         The following editor commands use this callback:

           save_window_config  - Saves MDI frame coordinates in auto-restore file.
           restore             - Attempts to restore MDI frame to original
                                 size and position.
           project_close   -  Saves MDI frame coordinates in project file.
           project_open    -  Attempts to restore MDI frame to original
                              size and position.

       UNIX: Under UNIX it is very difficult to implement this function
       for shell windows (non-clipped windows) because Window managers
       handle decorations differently.  The same Window manager on a
       different OS can be different.
   */
   void (VSAPI *pfnMDISetWindow)(int mdi_wid,int x,int y,int width,int height,char state);

   /*
       PARAMETERS
         mdi_wid     MDI frame window handle returned from
                     vsMDICreate.
         px,py       On input, x and y coordinates returned from last pfnMDIGetWindow call.
                     On return, adjusted x and y coordinates to be used by
                     auto-restore.

       Remarks
         This callback is only called under UNIX.

         This callback is a work-around we had to use for getting
         our MDI frame auto-restore to work under Silicon Graphics.
         If you were able to get pfnMDISetWindow and pfnMDIGetWindow
         to work perfectly, you don't need to implement this callback.
   */
   void (VSAPI *pfnMDIGetRestoreXY)(int mdi_wid,int *px,int *py);
   /*
       PARAMETERS
         mdi_wid        MDI frame window handle returned from
                        vsMDICreate.
         px,py,pwidth,pheight   (Ouput) For clipped MDI Children, pixel
                                coordinates of MDI client area which
                                should be the largest non-maxmized MDI
                                Child Frame.
                                If you implemented non-clipped MDI Children,
                                this callback must be NULL.

       REMARKS
         Called when splitting a maximized MDI Child by the following
         commands:

           vsplit_window   -  Reduces the size of the current MDI child
                              to half its horizontal size and creates a new MDI child
                              to the right to fill in the other half.
           hsplit_window   -  Reduces the size of the current MDI child
                              to half its vertical size and creates a new MDI child
                              below to fill in the other half.

         Dockable toolbars require this callback to dock and undock.

   */
   void (VSAPI *pfnMDIClientGetWindow)(int mdi_wid,int *px,int *py,int *pwidth,int *pheight);

   /*
       PARAMETERS
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.

       RETURN
          Returns true if this editor control is on the
          active mdi child.  In WIN32 terms this means
          the WM_MDIGETACTIVE returns a child window
          handle which contains this editor control.

   */
   int (VSAPI *pfnMDIEditorCtlIsOnActiveChild)(int wid);

   /**
    * Called on save. Returns non-zero value if license is still
    * valid.  Currently this calllback is reserved by SlickEdit and
    * should not be used by OEM editor control customers.
    */
   int (VSAPI *pfnIsLicenseValid)();
   /**
    * Called on save if license is no longer valid.  Currently this
    * calllback is reserved by SlickEdit and should not be used by
    * OEM editor control customers.   Returns non-zero if expiration
    * is handled and can continue.
    */
   int (VSAPI *pfnLicenseExpired)();
   /**
    * Called in Slick-C _firstinit() function. Currently this
    * calllback is reserved by SlickEdit and should not be used by
    * OEM editor control customers.
    */
   void (VSAPI *pfnLicenseInit)();
   /**
    * Called on save. Returns non-zero value if license is still
    * valid.  Currently this calllback is reserved by SlickEdit and
    * should not be used by OEM editor control customers.
    */
   void (VSAPI *pfnNagOnSave)();
   /*

       REMARKS:
          Show the mdi window in the specified state


       RETURN
          0       If successful
          1       If successful but the mdi width or height was ignored.
          <0      Error

       PARAMETERS:
          wid             VSWID_MDI

         WindowState      one of the following values

             0             Use your own default for the window state.  VS
                           will maximize a new MDI child if the current
                           mdi child is already maximized.

            'I'           Iconize the window
            'M'           Maximize the window
            'N'           Normalize the window
   */
   void (VSAPI *pfnMDIShow)(int wid,char WindowState);
   /*
       PARAMETERS
          wid               Editor control window handle returned from
                            vsCreateEditorCtl.
       Returns
          If the mdichild system is displayed, true should be returned.
          Otherwise, false is returned.
   */
   bool (VSAPI *pfnMDIChildShowSystemMenu)(int wid);

   /**
    * Create a new horizontal or vertical tabgroup from editor 
    * control specified by <code>wid</code>. If editor control is 
    * already part of a tabgroup, then it is removed and inserted 
    * into new tabgroup. 
    *
    * <p>
    *
    * If <code>vertical</code> is true, then a vertical tabgroup is
    * created, otherwise a horizontal tabgroup is created. A
    * vertical tabgroup spans from top-to-bottom and is
    * width-adjustable with a separator that runs vertically. A
    * horizontal tabgroup spans from left-to-right and is
    * height-adjustable with a separator that runs horizontally. 
    *
    * @param wid      Editor control window handle returned from 
    *                 vsCreateEditorCtl.
    * @param vertical Set to true for a vertical tabgroup, false
    *                 for a horizontal tabgroup. 
    * @param insertAfter  Set to true to insert new MDI Child 
    *                 tab group after wid.
    */
   void (VSAPI * pfnMDIChildNewTabGroup)(int wid, bool vertical,bool insertAfter);

   /** 
    * SlickEdit internal use only.
    *
    * <p>
    *
    * Save MDI <code>state</code> and encode to string. The format
    * of this string is user-implementation specific. 
    * 
    * @return slickedit::SEString 
    */
   slickedit::SEString (VSAPI * pfnMDISaveState)();
   /**
    * SlickEdit internal use only.
    *
    * <p>
    *
    * Restore MDI <code>state</code> returned from 
    * <code>CallbackMDIGetState</code>. The format of this string
    * is user-implementation specific. 
    *
    * @param state
    *
    * @return true on success.
    */
   bool (VSAPI * pfnMDIRestoreState)(const slickedit::SEString& state);

   /**
    * Finds tile adjacent to active window.
    *  
    * @param wid            MDI child window id (editor wid)
    * @param option_letter   One of the following:
    *    <dl compact>
    *    <dt><b>"L"</b> <dd>find document tab to left
    *    <dt><b>"R"</b> <dd>find document tab to right
    *    <dt><b>"A"</b> <dd>find document tab to above
    *    <dt><b>"B"</b> <dd>find document tab to below
    *    <dt><b>"N"</b> <dd>find next document tab (active or not)
    *    <dt><b>"P"</b> <dd>find previous document tab (active or not)
    *    <dt><b>"1"</b> <dd>find next document tab within tab group
    *    <dt><b>"2"</b> <dd>find previous document tab within tab group
    *    <dt><b>"G"</b> <dd>find next tab group
    *    <dt><b>"H"</b> <dd>find previous tab group
    *    <dt><b>"g"</b> <dd>find next tab group (not circular)
    *    <dt><b>"h"</b> <dd>find previous tab group (not circular)
    *    </dl>
    * @param move_or_close  True means window edge can be sized
    *                       with active window
    * @return Non-zero window id
    */
   int (VSAPI *pfnMDINextDocumentWindow)(int wid, char option_letter, bool move_or_close);

   /**
    * Change size of tile 
    *  
    * @param wid MDI child window id (editor wid) 
    * @param Positive or negative number. Specifies increase or 
    *                 decrease in tile size.
    * @param before  size edge before or after wid.
    *  
    * @return Returns amount size of tile was changed. 
    */
   int (VSAPI *pfnMDIChangeDocumentWindowSize)(int wid, int add,bool before);
   /**
    * Returns group tab info. SlickEdit internal use only.
    *  
    * @param wid  MDI child window id (editor wid) 
    * @param hinfo   Slick-C Info 
    *  
    *  struct MDIDocumentTabInfo {
    *     _str caption;
    *     int wid;
    *  };
    *  struct MDIDocumentGroupInfo {
    *     int nextGroup_wid;
    *     int prevGroup_wid;
    *     int NofTabs;
    *     int active_index;
    *     MDIDocumentTabInfo tabInfo[];
    *  };
    *  void MDIDocumentGroupInfo(int wid,MDIDocumentGroupInfo &info,_str option);
    *  
    * @param option   One of the following:
    *    <dl compact>
    *    <dt><b>'B'</b> <dd>Basic group info
    *    <dt><b>'A'</b> <dd>All info. Fill in tab array
    *    </dl>
    */
   void (VSAPI *pfnMDIGetDocumentTabGroupInfo)(int wid, VSHREFVAR hinfo, char option);

   /**
    * Move a document window to the same document group as another document window 
    *  
    * @param move_wid MDI child window id (editor wid) to move
    * @param to_wid   MDI child window id (editor wid) of destination document group
    */
   void (VSAPI *pfnMDIMoveToDocumentTabGroup)(int move_wid, int to_wid);

   /**
    * Float/dock MDI child window <code>wid</code>.
    *  
    * @param wid MDI child window id (editor wid) to float/dock
    */
   void (VSAPI *pfnMDIChildFloatWindow)(int wid,bool doFloat);

   /**
    * Return true if MDI child window <code>wid</code> is a 
    * floating window, false if a docked window. 
    *  
    * @param wid MDI child window id (editor wid)
    */
   bool (VSAPI *pfnMDIChildIsFloating)(int wid);

   /**
    * Return window id's of all MDI windows
    *  
    * @param window_list  Array of MDI window window id's
    */
   void (VSAPI *pfnMDIGetMDIWindowList)(slickedit::SEArray<int> &window_list);

   /**
    *  Return window id most recently active MDI window
    *  
    *  @return Return window id of most recently active MDI window
    */
   int (VSAPI *pfnMDICurrent)();
   /**
    * Returns non-zero value if MDI child edit window is 
    * visible 
    *  
    * @param wid   MDI child edit window
    *  
    * @return Returns non-zero value is MDI child window is visible
    */
   int (VSAPI *pfnMDIChildIsVisible)(int wid);
   /**
    * Return current mdi child window id of the specified MDI 
    * window. 
    *  
    * @param mdi_wid   Window of an MDI mnain window 
    *  
    * @return Return current mdi child window id of the 
    * specified MDI window. 
    */
   int (VSAPI *pfnMDICurrentChild)(int mdi_wid);
   /**
    * Get MDI window window id for a particular MDI child edit 
    * window 
    *  
    * @param wid   MDI child edit window
    *  
    * @return Return MDI window window id for a particular MDI 
    * child edit window 
    */
   int (VSAPI *pfnMDIFromChild)(int wid);
   /**
    * Get MDI tab group ID for a particular MDI 
    * child edit window 
    *  
    * @param wid   MDI child edit window
    *  
    * @return Return MDI tab group ID for a 
    * particular MDI child edit window 
    */
   VSUINT64 (VSAPI * pfnMDITabGroupIDFromChild)(int wid);

   void *Reserved2[3];

/**********************Command Line callbacks **********************/
   /*
       IMPORTANT: This pointer must point to data that will not disappear.
       Define your command line functions in the global scope.
   */
   VSCMDLINE_FUNCTIONS *pcmdlinefuns;
   /*
       Because the command line is not part of the editor, you will
       need to have your own configuration for command line font.
       We don't think its worth it for you to support changing
       the command line font because very few users use this feature.

       This callback is reserved for SlickEdit.
   */
   void (VSAPI *pfnCmdLineSetFont)(void *pfont);

   void *Reserved3[5];
/************************Miscellaneous option callbacks*******************************************/
   /*
       The vs executable has a +/-new option which determines what
       happens when a user invokes another copy of the editor.

       This callback is currenly reserved for SlickEdit's use only.

       Returns non-zero value if command line was passed to existing
       editor instance.
   */
   int (VSAPI *pfnUseCurrentInstance)(const char *pszCmdline);

   /*
       This function is specific to SlickEdit's gui.  We need it because
       the MDI child window procedure is in the DLL.
   */
   void (VSAPI *pfnSetWasOnCmdline)(int WasOnCmdline);
   /*
       Called when vsRefresh is explicitly called to refresh all edit
       windows or when a SlickEdit command terminates.

       Since this function gets called on every keypress, make sure
       your code is fast.

       SlickEdit uses this callback to make sure that the focus
       is on the command line when there are no MDI children left.
   */
   void (VSAPI *pfnRefresh)(void);
   /*
       Because font selection is not portable, this function is reserved
       for SlickEdit.
   */
   void (VSAPI *pfnSetStatusFont)(void *pfont);
   /*
       Because color selection is not portable, this function is reserved
       for SlickEdit. Even SlickEdit is unable to support this option.
   */
   void (VSAPI *pfnSetStatusColor)(int fg,int bg);
   /*
       Because color selection is not portable, this function is reserved
       for SlickEdit.
   */
   void (VSAPI *pfnSetMessageColor)(int fg,int bg);
   /*
   
   */
   void (VSAPI *pfnMDIAllowCornerToolbar)(int allow);
   /*
       Comma delimited list of supported toolbars.  Ex  "Project,Slick-C&reg; Stack"
       Specify NULL to support all toolbars.
       Specify "" to support no toolbars
   */
   const char *pszSupportedToolbarsList;
   /*
       Specifies what language files should be used.  Currently, the following
       files are effected:

           win\vslick.vsb       (UNIX: bin/vslick.vsb): When a non-null pszLang is
                                specified, the default h/vsmsgdefs.h is not used.
                                Instead "vslick_<Lang>.vsb" is used.

           h/vsmsgdefs.h        When a non-null pszLang is
                                specified, the default h/vsmsgdefs.h is not used.
                                Instead "vslick_<Lang>.vsm" is used.
                                When installing these files make sure the ".vsb" file
                                is newer than the "h/vsmsgdefs.h" file so a macro compile is
                                not necessary.  Installation directories can be
                                read-only causing problems.

           macros\sysobjs.ex    When a non-null pszLang is specified, the dialogs in
                                "macros\sysobjs_<Lang>.ex" override the dialogs in
                                "macros\sysobjs.ex".  You do not need to ship a
                                "sysobjs_<Lang>.e".  If a "sysobjs_<Lang>.e" exists,
                                a "sysobjs_<Lang>.ex" will be created if necessary.
                                When installing thes files make sure the ".ex" file
                                is newer than the ".e" file so a macro compile is
                                not necessary.  Installation directories can be
                                read-only causing problems.

       effects which
       Specify NULL

   */
   const char *pszLang;


   /**
    * This callback is used to appropriately execute the vsLibExports before the
    * corresponding SlickC commands are called.
    *
    * Used in vseInitialize.
    *
    * RH - 3/9/06
    */
   void (*pfnAdditionalLibExports)();
   /**
    * Eclipse Alert functions.
    */
   void (*pfnEclipseRegisterAlert)(int alertGroupID);
   void (*pfnEclipseUnregisterAlert)(int alertGroupID);
   void (*pfnEclipseActivateAlert)(int alertGroupID, int alertID, const char* msg, const char* header, int showToast);
   void (*pfnEclipseDeactivateAlert)(int alertGroupID, int alertID, const char* msg, const char* header, int showToast);
   void (*pfnEclipseClearLastAlert)(int alertGroupID, int alertID);
   void (*pfnEclipseSetAlertGroupStatus)(int alertGroupID, int enabled, int showPopups);
   void (*pfnEclipseSetAlertStatus)(int alertGroupID, int alertID, int enabled, int showPopups);
   void (*pfnEclipseGetAlertGroup)(int alertGroupID, VSHREFVAR alertGroup);
   void (*pfnEclipseGetAlert)(int alertGroupID, int alertID, VSHREFVAR alert);
   void *Reserved4[7];
} VSINIT;

EXTERN_C_BEGIN
/**
 * <p>This function is intended for use by OEMs only.  OEMs receive a
 * special CD which has serveral examples which use this function.  We
 * recommend you look at the sample applications to get quickly started
 * using this function.</p>
 *
 * <p>This function is called once before calling any other SlickEdit
 * editor API function to initialize the API.  After calling this function,
 * you can create as many editor controls as you want with
 * "<b>vsCreateEditorCtl</b>".  Make sure you call
 * <b>vsPrepareForTerminate</b> and <b>vsTerminate</b> to properly
 * terminate the editor and release all resources.</p>
 *
 * @return Returns 0 if successful.
 *
 * @param pvsinit	See comments for VSINIT structure in
 * "vs.h".  You must initialized the contents of
 * this structure to 0.  For C and C++, this can
 * be done using memset() or defining this
 * structure as a global or static variable.
 *
 * @categories Miscellaneous_Functions
 *
 */
int VSAPI vsInit(VSINIT *pvsinit);

/**
 * @return
 * Return absolute path of users local configuration directory with
 * trailing file separator.
 *
 * @param NoLocalConfigOption
 *           When NoLocalConfigOption==0, the user configuration directory is returned.
 *
 *           <P>When NoLocalConfigOption==1, the user configuration directory is
 *           returned if it exists. Otherwise "" is returned.
 *
 *           <P>When NoLocalConfigOption==2, the user configuration directory is
 *           returned if it exists. Otherwise the "bin" directory is returned.
 *
 * @see vsInit
 * @categories File_Functions
 */
VSPSZ VSAPI vsConfigPath(int NoLocalConfigOption VSDEFAULT(0));
/**
 * Currently this function just sets some internal global variables to avoid
 * dispatching events for windows which are disappearing.  Due to our
 * MDI API implementation you must call
 * <b>vsPrepareForTerminate</b> before calling before
 * <b>vsTerminate</b>.  SlickEdit destroys its MDI Frame
 * window in between these two calls.
 *
 * @categories Miscellaneous_Functions
 *
 */
void VSAPI vsPrepareForTerminate();
/**
 * Frees allocated resources.  <b>vsPrepareForTerminate</b> must be
 * callled before calling this function.  No other vs??? calls should be
 * made after calling this function.  You may not call <b>vsInit</b> after
 * calling vsTerminate.
 *
 * @categories Miscellaneous_Functions
 *
 */
void VSAPI vsTerminate();

/**
 * @return Returns the character offset from the beginning of the buffer to the last
 * match or tagged expression found by the last <b>vsSearch</b> or
 * <b>vsRepeatSearch</b>.
 *
 * @param TaggedExpression	Tagged expression number. Specify
 * a <i>MatchGroup</i> of -1 to get the length
 * of the entire string matched.   For SlickEdit
 * and Brief regular expressions the first tagged
 * expression is 0 and the last is 9.  For UNIX,
 * the first tagged expression is 1 and the last is
 * 0.
 *
 * @example
 * <pre>
 * int status;
 * status=vsSearch(0,"this|that",-1,"r");
 * if (!status ){
 *     char temps[100];
 *     // Get the word matched
 *     vsGetText(0,vsMatchLength(),vsMatchStart(),temps);
 *     vsMessage(temps);
 * }
 * </pre>
 *
 * @see vsMatchLength
 * @see vsMatchCursorLength
 * @see vsSelectMatch
 * @see vsSearch
 * @see vsRepeatSearch
 * @see vsSearchReplace
 * @see vsSaveSearch
 * @see vsRestoreSearch
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
seSeekPosRet VSAPI vsMatchStart(int TaggedExpression VSDEFAULT(-1));
/**
 * @return Returns the number of bytes between the first byte of the last string
 * found by <b>vsSearch</b> or <b>vsRepeatSearch</b> and the cursor
 * (regular expression cursor).
 *
 * @example
 * <pre>
 * int status;
 * status=vsSearch(0,"th\\cis",-1,"r");
 * if (!status ){
 *     char temps[100];
 *     // Get first 2 characters of match "th"
 *     vsGetText(0,vsMatchCursorLength(),vsMatchStart(),temps);
 *     vsMessage(temps);
 * }
 * </pre>
 *
 * @see vsMatchStart
 * @see vsMatchLength
 * @see vsSelectMatch
 * @see vsSearch
 * @see vsRepeatSearch
 * @see vsSearchReplace
 * @see vsSaveSearch
 * @see vsRestoreSearch
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
int VSAPI vsMatchCursorLength();
/**
 * @return Returns the length of the last match or tagged expression found by the
 * last <b>vsSearch</b> or <b>vsRepeatSearch</b>.
 *
 * @param TaggedExpression	Tagged expression number.  For
 * SlickEdit and Brief regular expressions the
 * first tagged expression is 0 and the last is 9.
 * For UNIX, the first tagged expression is 1
 * and the last is 0.
 *
 * @example
 * <pre>
 * int status;
 * status=vsSearch(0,"this|that",-1,"r");
 * if (!status ){
 *     char temps[100];
 *     // Get the word matched
 *     vsGetText(0,vsMatchLength(),vsMatchStart(),temps);
 *     vsMessage(temps);
 * }
 * </pre>
 *
 * @see vsMatchStart
 * @see vsMatchCursorLength
 * @see vsSelectMatch
 * @see vsSearch
 * @see vsRepeatSearch
 * @see vsSearchReplace
 * @see vsSaveSearch
 * @see vsRestoreSearch
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
int VSAPI vsMatchLength(int TaggedExpression VSDEFAULT(-1));
/**
 * Fills the selection specified with a character.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param mark_id	Selection id to duplicated.   If -1 is specified
 * the active selection.
 *
 * @param ch	Character to fill selection with.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
void VSAPI vsFillSelection(int wid,int markid VSDEFAULT(-1),unsigned ch VSDEFAULT(' '));
/**
 * Inserts space character at left edge of marked area specified.
 * <i>mark_id</i> is a handle to a selection returned by
 * <b>vsAllocSelection</b> or <b>vsDuplicateSelection</b>.  A
 * <i>mark_id</i> of -1 <i>mark_id</i> parameter identifies the active
 * selection.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
void VSAPI vsShiftSelectionRight(int wid,int markid VSDEFAULT(-1),int Reserved VSDEFAULT(1),unsigned char Reserved2 VSDEFAULT(' '));
/**
 * Deletes characters at left edge of marked area specified.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by the <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b> function.  A
 * <i>mark_id</i> of -1 specifies the active
 * selection or selection showing and is always
 * allocated.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
void VSAPI vsShiftSelectionLeft(int wid,int markid VSDEFAULT(-1),int Reserved VSDEFAULT(1));
/**
 * Splits the current line at the cursor position.  More specifically inserts
 * <b>p_newline</b> character string at cursor.  If the cursor is past the
 * end of the line, the <b>p_newline</b> character string is inserted after
 * the last character of the line but before the line termination characters.
 *
 * @param wid      Window id of editor control.  0 specifies the
 * current object.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsSplitLine(int wid,int col VSDEFAULT(0));
/**
 * Joins the next line to the end of the current line.
 *
 * @return Returns 0 if successful.  The join is aborted if the join will create a
 * line longer than the truncation length and the truncation length is non-
 * zero (see <b>p_TruncateLength</b> property).   A non-zero value is
 * returned if the join is aborted.
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @see vsJoinLineToCursor
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsJoinLine(int wid);
/**
 * Joins the next line to the cursor position.   If necessary the current line
 * is padded with blanks.  If the cursor is before the end of the current
 * line, the next line is joined at the end of the current line.
 *
 * @return Returns 0 if successful.  The join is aborted if the join will create a
 * line longer than the truncation length and the truncation length is non-
 * zero (see <b>p_TruncateLength</b> property).   A non-zero value is
 * returned if the join is aborted.
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @see vsJoinLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsJoinLineToCursor(int wid,int reserved VSDEFAULT(0));
/**
 * Inserts or overwrites string specified into the command line or text
 * area depending on the insert state and the cursor position.  If BufLen is
 * -1, then <i>pBuf</i> must point to a null terminated string.  This
 * function is slow because it performs word wrap.  Use
 * <b>vsInsertLine</b> or <b>vsInsertText</b> function for better
 * performance.
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @param pBuf	Text to insert.  May contain line separator
 * characters.
 *
 * @param BufLen	Number of characters in <i>pBuf</i>.  -1
 * specifies that <i>pBuf</i> is null terminate
 * and length can be determined from it.
 *
 * @see vsQInsertState
 * @see vsSetInsertState
 *
 * @appliesTo Text_Box, Combo_Box, Edit_Window, Editor_Control
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void VSAPI vsKeyin(int wid,const char *pBuf,int BufLen);
/**
 * Deletes character under text cursor.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void VSAPI vsDeleteChar(int wid, int Reserved VSDEFAULT(0));
/**
 * Deletes a character if any to left of cursor and moves the cursor to left.
 * When the left edge is hit, the text area is smooth scrolled or center
 * scrolled depending on the scroll style.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void VSAPI vsRubout(int wid, int Reserved VSDEFAULT(0));
/**
 * Uses the selection id specified to select the last string matched by one
 * of the functions <b>vsSearch</b> or <b>vsRepeatSearch</b>.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.  A
 * <i>mark_id</i> of -1 specifies the active
 * selection or selection showing and is always
 * allocated.
 *
 * @see vsMatchLength
 * @see vsMatchStart
 * @see vsMatchCursorLength
 * @see vsSearch
 * @see vsRepeatSearch
 * @see vsSearchReplace
 * @see vsSaveSearch
 * @see vsRestoreSearch
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
int VSAPI vsSelectMatch(int wid,int markid VSDEFAULT(-1));
/**
 * Replaces the match found by the last <b>vsSearch</b> or
 * <b>vsRepeatSearch</b> with the replace string specified and
 * optionally searches for the next occurrence.
 *
 * @return Returns 0 if successful.  Common return codes are
 * BREAK_KEY_PRESSED_RC and STRING_NOT_FOUND_RC.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pReplaceString	Last search string found is replaced with this
 * string.
 *
 * @param ReplaceStringLen	Number of characters in
 * <i>pReplaceString</i>.  -1 means
 * <i>pReplaceString</i> is null terminated.
 *
 * @param RepeatSearch	If this is non-zero, a search for the next
 * occurrence of the last search string is
 * performed with the same options and
 * direction specified by the last
 * <b>vsSearch</b> or
 * <b>vsRepeatSearch</b> call
 *
 * @see vsMatchLength
 * @see vsMatchStart
 * @see vsMatchCursorLength
 * @see vsSelectMatch
 * @see vsSearch
 * @see vsRepeatSearch
 * @see vsSaveSearch
 * @see vsRestoreSearch
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
int VSAPI vsSearchReplace(int wid,const char *pReplaceString,int ReplaceStringLen VSDEFAULT(-1),int RepeatSearch VSDEFAULT(0));
int VSAPI vsSearchReplaceRaw(int wid,const char *pReplaceString,int ReplaceStringLen VSDEFAULT(-1),int RepeatSearch VSDEFAULT(0));
/**
 * Saves search information set by one of the functions <b>vsSearch</b>
 * or <b>vsRepeatSearch</b>.  Use <b>vsRestoreSearch</b> to restore
 * the search information.
 *
 * @return Returns number of bytes needed to be allocated to pvoid.
 *
 * @see vsMatchLength
 * @see vsMatchStart
 * @see vsMatchCursorLength
 * @see vsSelectMatch
 * @see vsSearch
 * @see vsRepeatSearch
 * @see vsSearchReplace
 * @see vsRestoreSearch
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions, Search_Functions
 *
 */
int VSAPI vsSaveSearch(void *pvoid VSDEFAULT(0));
/**
 * Restores search information saved by the <b>vsSaveSearch</b>
 * function.
 *
 * @see vsMatchLength
 * @see vsMatchStart
 * @see vsMatchCursorLength
 * @see vsSelectMatch
 * @see vsSearch
 * @see vsRepeatSearch
 * @see vsSearchReplace
 * @see vsSaveSearch
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Functions, Editor_Control_Functions, Search_Functions
 *
 */
void VSAPI vsRestoreSearch(void *pvoid);
/**
 * Sets the insert state on (non-zero) or off (0).  Each text box has its own
 * insert state.  However, all edit windows and editor controls share the
 * same insert state.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param State	New value for insert state.
 *
 * @see vsQInsertState
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void VSAPI vsSetInsertState(int wid,int state,int Reserved VSDEFAULT(0));
/**
 * Each text box has its own insert state.  However, all edit windows and
 * editor controls share the same insert state.
 *
 * @return Returns non-zero value if insert is on.
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @see vsSetInsertState
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
int VSAPI vsQInsertState(int wid,int Reserved VSDEFAULT(0));
/**
 * Places cursor at column 1 of current line.
 *
 * @see vsEndLine
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void VSAPI vsBeginLine(int wid);
/**
 * Places cursor after end of current line.
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @see vsBeginLine
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
void VSAPI vsEndLine(int wid);

#define VSSORT_DESCENDING           0x01
#define VSSORT_IGNORECASE           0x02
#define VSSORT_IGNORECASE_NONLOCALE 0x08
#define VSSORT_NUMBER               0x10
#define VSSORT_FILENAME             0x20
#define VSSORT_FILENAME_NAME_PART   0x40
#define VSSORT_FILECASE             0x80

/**
 * Sorts the selection specified in ascending or descending order in case
 * sensitivity specified.  Sorting defaults to ascending and case sensitive.
 * If the buffer containing the specified selection is the active buffer of
 * <i>wid</i>, the resulting lines are inserted after the end of the
 * selection.  Otherwise the resulting lines are inserted after the cursor.  If
 * a character selection is used, it is converted to a line type selection.
 *
 * @return Returns 0 if successful.  Common return codes are
 * LINE_OR_BLOCK_SELECTION_REQUIRED_RC,
 * NOT_ENOUGH_MEMORY_RC, TOO_MANY_SELECTIONS_RC,
 * and INVALID_SELECTION_HANDLE_RC.
 *
 * @param wid	Ouput window id.  Window id of editor
 * control.  0 specifies the current object.
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by the <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b> function.

 * @param SortFlags	Zero or more of the following flags Ored
 * together:
 * <dl>
 * <dt>VSSORT_DESCENDING</dt><dd>Sort in descending order.</dd>
 * <dt>VSSORT_IGNORECASE</dt><dd>Case insensitive sort according to
 * locale.</dd>
 * <dt>VSSORT_IGNORECASE_NONLOCALE</dt><dd>
 * 	Case insensitive sort according to
 * U.S. locale.</dd>
 * <dt>VSSORT_NUMBER</dt><dd>Data being sorted contains floating
 * point numbers.</dd>
 * <dt>VSSORT_FILENAME</dt><dd>Data being sorted containts file
 * names.</dd>
 * </dl>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsSortSelection(int wid,int markid VSDEFAULT(-1),int SortFlags VSDEFAULT(0));
/**
 * Deletes the marked text specified.  No clipboard is created.  This
 * function performs a "binary" delete when in hex mode
 * (<b>p_hex_mode</b>==<b>true</b>).  A binary delete allows
 * bisecting of end of line pairs like CR, LF.
 *
 * @return Returns 0 if successful.  Otherwise TEXT_NOT_SELECTED_RC is
 * returned. On error, message is displayed.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param mark_id	Selection id to duplicated.   If -1 is specified
 * the active selection.
 *
 * @categories Selection_Functions
 *
 */
void VSAPI vsDeleteSelection(int wid,int markid VSDEFAULT(-1),int Reserved VSDEFAULT(-1));
/**
 * @return If successful, a handle to a newly created selection identical to the
 * selection specified.  Otherwise a negative error code is returned.
 * Possible error codes are INVALID_SELECTION_HANDLE_RC or
 * TOO_MANY_SELECTIONS_RC.  <i>mark_id</i> is a handle to a
 * selection returned by one of the built-ins <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b>.
 *
 * <p>IMPORTANT:  If -1 is specified for the <i>mark_id</i> parameter, a
 * handle to the active selection is returned (no duplication is performed).
 * This is different than other selection functions which automatically
 * assume the active selection and perform the same operation.</p>
 *
 * <p>On error, message is displayed.</p>
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param mark_id	Selection id to duplicated.   If -1 is specified
 * for the <i>mark_id</i> parameter, a handle
 * to the active selection is returned (no
 * duplication is performed).  This is different
 * than other selection functions which
 * automatically assume the active selection
 * and perform the same operation.
 *
 * @example
 * <pre>
 * vsDeselect(0);vsSelectLine (0);
 * mark_showing=vsDuplicateSelection(0,-1);	// Save handle of active
 * selection
 * mark_id=vsDuplicateSelection(0,mark_showing);	// Duplicate
 * active selection
 * vsCopyToCursor(0);
 * vsShowSelection(0,mark_id);	// Keep selection on source text.
 * vsFreeSelection (mark_showing);	// Free selection on destination text.
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsDuplicateSelection(int wid,int markid,bool mark_to_cursor=true);
/**
 * Makes the mark corresponding to mark_id visible.  Currently only one
 * mark may be showing at a time.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by the <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b> function.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
void VSAPI vsShowSelection(int wid,int markid);
/**
 * <p>Takes sub-string of source buffer and places the result in the dest
 * buffer.  Unlike the the <b>vsExpandTabs</b> function, this function
 * gets the source text from the current line.</p>
 *
 * <p>The <i>StartCol</i> and <i>ColWidth</i> specification correspond to
 * the input <i>string</i> as if tab characters were expanded according to
 * the buffers tab settings.  We call this type of text position or count
 * imaginary.  Strings containing tab characters are expanded before
 * displayed.  Hence, the need arises for a differentiation between
 * physical and imaginary positions.  A physical position corresponds to
 * a byte in a string where  the characters are numbered one to the length
 * of string.  An imaginary position corresponds to a position in a string
 * once tabs have been expanded.</p>
 *
 * @param wid	<i>wid</i> identifies the object to be operated on.  0
 * specifies the current object.
 *
 * @param pszDest	Output.  Resulting string terminated with
 * ASCII 0.
 *
 * @param pDestLen	Output.  Number of bytes written to
 * <i>pszDest</i> not including ASCII 0.
 *
 * @param StartCol	Input. Start (imaginary) column for sub-
 * string.
 *
 * @param ColWidth	Input.  Number of (imaginary) columns to get
 * from <i>pSource</i>.   -1 specifies the rest or the
 * string.  -2 specifies to use the
 * <b>vsTruncQLineLength</b> instead of the real line
 * length.  This has the same effect as specifying -1 if the
 * <B>VSP_TRUNCATELENGTH</B> property is 0.
 *
 * @param Option	Input.  Specify 'E' if you want all tabs
 * expanded.  Otherwise specify 'S' to return tabs
 * unexpanded.
 *
 * @see vsExpandTabs
 * @see vsTextColC
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 *
 */
void VSAPI vsExpandTabsC(int wid,
                   char *pszDest,
                   int *pDestLen,
                   int StartCol,
                   int ColWidth,
                   char Option);
/**
 * We use the term imaginary to describe column positions which
 * correspond to a string as displayed on your screen.  Strings containing
 * tab characters are expanded before displayed.  Hence, the need arises
 * for a differentiation between physical and imaginary positions.  A
 * physical position corresponds to a character in string.  The characters
 * are number one to the length of string.  An imaginary position
 * corresponds to a position in a string once tabs have been expanded.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param col	Input imaginary or physical column
 * depending on <i>option</i>.  See table
 * below.
 *
 * @param option	See below.
 *
 * <p>Converts an imaginary column position to a physical string column
 * position and visa versa.  The input and output values are described by
 * the table below:</p>
 *
 * @param option	Input column, returned column
 *
 * <dl>
 * <dt>'P'</dt><dd>Imaginary, Physical</dd>
 * <dt>'T'</dt><dd>Imaginary, Physical.  Position is negated if the
 * imaginary column input corresponds to the middle
 * of a tab character.</dd>
 * <dt>'L'</dt><dd>Doesn't matter, Imaginary length of string.</dd>
 * <dt>'E'</dt><dd>Doesn't matter, Imaginary length of line where the
 * <b>vsTruncQLineLength</b> is used.  This has the
 * same effect as the 'L' option if the
 * <B>VSP_TRUNCATELENGTH</B> property is
 * 0.</dd>
 * <dt>'I'</dt><dd>Physical, Imaginary</dd>
 * </dl>
 *
 * <p>The input column is returned if input column is less than or equal to
 * zero and the third parameter is not 'L'.</p>
 *
 * @see vsExpandTabsC
 * @see vsExpandTabs
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 *
 */
int VSAPI vsTextColC(int wid,int col,char option VSDEFAULT('L'));
/**
 * This function changes the selection type for a specified selection
 * handle.
 *
 * @return Returns 0 if the <i>markid</i> specified is valid.  Otherwise a
 * negative error code is returned.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by the <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b> function.  A
 * <i>mark_id</i> of -1 specifies the active
 * selection or selection showing and is always
 * allocated.
 *
 * @param type	One of the following:
 *
 * <p>If <i>option</i>=='L' or option=='T'</p>
 * <ul>
 * <li>VSSELECT_LINE</li>
 * <li>VSSELECT_CHAR</li>
 * <li>VSSELECT_BLOCK</li>
 * <li>VSSELECT_NONINCLUSIVEBLOCK</li>
 * </ul>
 *
 * <p>If <i>option</i>=='S'</p>
 * <ul>
 * <li>VSSELECT_CURSOREXTENDS</li>
 * </ul>
 *
 * <p>If <i>option</i>=='U'</p>
 * <ul>
 * <li>VSSELECT_PERSISTENT</li>
 * </ul>
 *
 * @param option	'L', 'T', 'S', or 'U'.
 * 	For 'L' or 'T' the select type is set to the
 * <i>type</i> given.  When the 'L' option,
 * <i>type==VSSELECT_LINE,</i>, and the
 * last line of a character selection has 0 bytes
 * selected, the last line is not included in the
 * new line selection.
 *
 * <p>For 'S', the selection style is set to extend as
 * the cursor moves or not to extend as the
 * cursor moves.</p>
 *
 * <p>For 'U', the selection style is set to be
 * persistent or not persistent.</p>
 *
 * @see vsQSelectType
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsSetSelectType(int wid,int markid,int type,char option VSDEFAULT('L' /* T L U S*/));
/**
 * @return If a value of 'T' is specified for the second parameter, one of the
 * selection types VSSELECT_BLOCK, VSSELECT_CHAR, or
 * VSSELECT_LINE is returned. 0 is returned if the selection specified
 * has not been set.
 *
 * <p>When a value of 'S' is specified for the second parameter, the select
 * style is returned.  Select styles are VSSELECT_CURSOREXTENDS
 * or 0 which correspond to cut/paste (selection extends as the cursor
 * moves) or begin/end respectively.  0 is returned if the selection
 * specified has not been set.</p>
 *
 * <p>If a value of 'I' is specified for the second parameter, 1 is returned if
 * the selection specified is an inclusive selection.  Otherwise 0 is
 * returned.</p>
 *
 * <p>When a value of 'U' is specified for the second parameter, a
 * VSSELECT_PERSISTENT is returned if the selection specified is a
 * persistent mark.  Otherwise, 0 is returned.</p>
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param markid	<i>mark_id</i> is a selection handle
 * allocated by the <b>vsAllocSelection</b> or
 * <b>vsDuplicateSelection</b> function.  A
 * <i>mark_id</i> of -1 specifies the active
 * selection or selection showing and is always
 * allocated.
 *
 * @param option	See below.
 *
 * @see vsSetSelectType
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 *
 */
int VSAPI vsQSelectType(int wid,int markid= -1,char option='T' /* T S P I U W*/);
/**
 * @return Returns the number of bytes before the cursor.  Non-savable lines
 * (lines with the VSLF_NOSAVE flag set) are not included. This
 * methed is intended for dealing with disk seek position. However, if
 * you have changed the load options to translate files when they are
 * openned, these offsets will not match what is on disk.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @see vsGoToPoint
 * @see vsQPoint
 * @see vsGoToROffset
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Editor_Control_Methods, Search_Functions
 *
 */
seSeekPosRet VSAPI vsQROffset(int wid);
/**
 * Places the cursor at the character offset specified. Non-savable lines
 * (lines with the VSLF_NOSAVE flag set) are not included.  This
 * methed is intended for dealing with disk seek position.  However, if
 * you have changed the load options to translate files when they are
 * openned, these offsets will not match what is on disk.
 *
 * @return Returns 0 if offset is a valid offset.   Otherwise an negative error code
 * is returned.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param offset	Real character offset to go to.
 *
 * @see vsGoToPoint
 * @see vsQPoint
 * @see vsQROffset
 * @see vsGoToROffset
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
int VSAPI vsGoToROffset(int wid,seSeekPos offset);
/**
 * Places <i>Len</i> bytes of data starting from the byte offset specified
 * by <i>RealSeekPos</i> into <i>pszBuf</i>.  The resulting string is
 * always null terminated.  The buffer <i>pszBuf</i> must be large
 * enough to contain <i>Len</i>+1 bytes of data.   Lines with the VSLF_
 * NOSAVE flag set are not copied into the output buffer.  Use this
 * function to read all data but no save lines.
 *
 * @return Returns number of bytes copied not including null character.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param Len	Number of characters to copy into
 * <i>pszBuf</i>.
 *
 * @param RealSeekPos	Specifies the real seek position from which
 * to start copying.  Specify VSNULLSEEK to
 * start copying for the cursor position.
 *
 * @param pszBuf	Output buffer for text. The buffer
 * <i>pszBuf</i> must be large enough to
 * contain <i>Len</i>+1 bytes of data.
 *
 * @see vsInsertLine
 * @see vsReplaceLine
 * @see vsDeleteLine
 * @see vsGetLine
 * @see vsGetText
 * @see vsGetRText
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsGetRText(int wid,int Nofbytes,seSeekPos point,char *pszBuf,int *pNofbytesRead VSDEFAULT(0));
/**
 * Searches for the <i>OldLineNumber</i> specified and places the
 * cursor on the line with that old line number or the closest old line
 * number.  If no lines have an old line number set, then the cursor is
 * placed on the real line (<b>p_RLine</b>) number given.  The "real
 * line number" does not count non-savable lines (that is lines with the
 * VSLF_ NOSAVE flag).  Use the <b>vsSetAllOldLineNumbers</b>
 * function to set the old line numbers.  Note that the Slick-C&reg;
 * <b>save</b> command takes an option to set the old line numbers on
 * save.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param OldLineNumber	Indicates the old line number to find.
 *
 * @see vsSetAllOldLineNumbers
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsGoToOldLineNumber(int wid,seSeekPos OldLineNum,int Reserved VSDEFAULT(1));
/**
 * Sets all old line numbers for the current buffer to the line number.
 * Use the <b>vsGoToOldLineNumber</b> method to go to an old line
 * number. SlickEdit uses old line numbers to better handle going
 * to an error line after lines have been inserted or deleted. Note that the
 * Slick-C&reg; <b>save</b> command takes an option to set the old line
 * numbers on save.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsSetAllOldLineNumbers(int wid,int Reserved VSDEFAULT(1));
/**
 * @return Returns 0 if successful.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param DelLen	Number of characters to delete.   Specify -1
 * to delete to end of line.  Specify -2 to delete
 * to end of file.  When <i>DelLen</i> is
 * greater than the number of characters left in
 * the file, the text up to the end of file is
 * deleted.
 *
 * @param option	Maybe 0 or 'C'.  Specify 'C' to indicate that
 * <i>DelLen</i> is a positive imaginary count
 * (as if tabs were expanded) of characters to
 * delete in the current line.
 *
 * <p>If <i>option</i> is zero, number of characters specified by
 * <i>DelLen</i> starting from the cursor location are deleted.  Each end
 * of line character is treated as 1 character (as is).</p>
 *
 * <p>If <i>option</i> is 'C', the number of columns (as if tabs were
 * expanded) specified by <i>DelLen</i> are deleted from the current
 * line.   The end of line characters are not deleted.</p>
 *
 * @see vsInsertText
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsDeleteText(int wid,int DelLen,char option VSDEFAULT(0));
/**
 * <p>Insert <i>string</i> at cursor position.  You may use this function to
 * insert multiple lines of text.  <i>NLCh1</i> and <i>NLCh2</i> define
 * a 1 or two character end of line sequence.  You must specify
 * <i>NLCh1</i>==<i>NLCh2</i> if you want a 1 character end of line
 * sequence.  The end of line sequence is used to parse the source string
 * <i>pBuf</i> into multiple lines.  The <i>NLCh1</i> and
 * <i>NLCh2</i> are ignored if the binary option is non-zero.</p>
 *
 * <p>When you use this function on a record file (<b>p_buf_width</b>!=0)
 * and the <i>binary</i> argument is non-zero, all data is inserted into
 * the current line and not broken up into multiple lines.</p>
 *
 * <p>NOTE: If you are inserting at the end of a file and the last character of
 * <i>pBuf</i> is a new line, you can end up with a blank line that has
 * no new line characters in it.  You can test for this condition by calling
 * <b>vsQLineLength</b>(0,1) which will return 0.  Use
 * <b>vsDeleteLine</b>(0) to delete the line. </p>
 *
 * @return Returns 0 if successful.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pBuf	Text to insert.  May contain line separator
 * characters.
 *
 * @param BufLen	Number of characters in <i>pBuf</i>.  -1
 * specifies that <i>pBuf</i> is null terminate
 * and length can be determined from it.
 *
 * @param binary	Specify a non-zero value for the
 * <i>binary</i> argument if you want to allow
 * bisection of newline characters (i.e.
 * CR<insert here>LF).
 *
 * @param NLCh1	First character of end of line sequence.
 *
 * @param NLCh2	Second character of end of line sequence.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsInsertText(int wid,const char *pBuf,int BufLen VSDEFAULT(-1),int Binary VSDEFAULT(0),unsigned char NLCh1 VSDEFAULT('\r'),unsigned char NLCh2 VSDEFAULT('\n'));
/**
 * This function is identical to the <b>vsInsertText</b> function, except
 * that the input string is in the same format as the internal buffer data
 * which can be SBCS/DBCS or UTF-8.  See "<b>Unicode and
 * SBCS/DBCS C API Programming</b>".
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsInsertTextRaw(int wid,const char *pBuf,int BufLen VSDEFAULT(-1),int Binary VSDEFAULT(0),unsigned char NLCh1 VSDEFAULT('\r'),unsigned char NLCh2 VSDEFAULT('\n'));
/**
 * Searches for line specified and places the cursor on the line.
 *
 * @return Returns 0 if successful.  If the line specified is past the end of the file,
 * BOTTOM_OF_FILE_RC is returned and the cursor is placed at the
 * end of the file.  Other possible error codes are
 * INVALID_OBJECT_HANDLE_RC and
 * PROPERTY_OR_METHOD_NOT_ALLOWED_RC.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param LineNumber	Indicates the old line number to find.
 *
 * @param OnlyCountRealLines When non-zero, only real lines are
 * counted.    The "real line number" does not
 * count non-savable lines (that is lines with
 * the VSLF_ NOSAVE flag).
 *
 * @param doCenter	When non-zero, if scrolling is necessary to
 * make the destination line visible, the line is
 * scrolled to the center of the screen.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsGoToLine(int wid,seSeekPos LineNumber,int OnlyCountRealLines VSDEFAULT(1),int doCenterScroll VSDEFAULT(1));
/**
 * Moves the current buffer location to text position specified..  The
 * <b>vsQPoint</b> function may be used to get the text line position
 * (not necessarily the seek position for a record file) of the beginning of
 * the current line.  The current line number may also be retrieved by the
 * built-in function <b>vsQPoint</b>.
 *
 * @return Returns 0 if successful.  Otherwise INVALID_POINT_RC is returned.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param Point	Seek position to an character in the buffer.
 *
 * @param DownCount	Number of lines to scroll down.
 *
 * @param LineNum	If not -1, this specifies the new value for the
 * VSP_LINENUM property.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsGoToPoint(int wid,seSeekPos Point,seSeekPos DownCount =seSeekPos(0),seSeekPos LineNum= seSeekPos((-1)));
/**
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pPoint	If <i>option</i>=='P',<i> </i>ouput for seek
 * position to beginning of line.  Otherwise,
 * output for current line number.  -1 indicates
 * current line number is unknown.
 *
 * @param pDownCount	Ouput for number of lines to cursor down to
 * get to the current line.  This is non-zero in
 * rare cases such as when editing record files
 * (p_buf_width!=0) which have no end of line
 * characters and blank lines are inserted.
 *
 * @param option 'P' or 'L'.
 *
 * <dl>
 * <dt>'P'</dt><dd>Sets <i>pPoint</i> to the seek position to the beginning
 * of the current line.  Sets <i>pDownCount</i> to the number of lines to
 * cursor down to get to the current line when starting from the seek
 * position to the beginning of line.  It is unusual for
 * <i>pDownCount</i> to be non-zero.  This can only occur for record
 * files (<b>p_buf_width</b>!=0) when a line has 0 bytes INCLUDING
 * the end of line characters.  Lines of record files have no end of line
 * characters.</dd>
 *
 * <dt>'L'</dt><dd>Sets <i>pPoint</i> to current line number.  If the current
 * line number is not known, <i>pPoint</i> is set to -1.</dd>
 * </dl>
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsQPoint(int wid,seSeekPos *pPoint,seSeekPos *pDownCount,char Option VSDEFAULT('P'));
/**
 * @return Returns character offset of cursor from beginning of buffer.
 *
 * <p>IMPORTANT:  This function includes lines with VSLF_NOSAVE set
 * which means that these file offsets will not match what is on disk if
 * the file has non-savable lines.  Use <b>vsGoToROffset</b>,
 * <b>vsQROffset</b>, <b>p_RLine</b>, and <b>p_RNoflines</b> for
 * dealing with disk seek positions and line numbers.</p>
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
seSeekPosRet VSAPI vsQOffset(int wid);

/**
 * Searches for <i>pSearchString</i> specified.  If pReplaceString is
 * non-zero, and search and replace without prompting is performed.
 * Press and hold Ctrl+Alt+Shift to terminate a long search.
 * <i>pszOptions</i> is one or more of the following option letters:
 *
 * @return Returns 0 if the search specified is found.  Common return codes are
 * STRING_NOT_FOUND_RC, INVALID_OPTION_RC, and
 * INVALID_REGULAR_EXPRESSION_RC.  On error, message is
 * displayed.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pSearchString	String to search for.
 *
 * @param SearchStringLen	Number of characters in
 * <i>pSearchString</i>.  You can specify -1 if
 * <i>pSearchString</i> is null terminated.
 *
 * @param pszOption	String of zero or more of the following
 * options:
 *
 * <dl>
 * <dt>+</dt><dd>(Default) Forward search.</dd>
 * <dt>-</dt><dd>Reverse search.</dd>
 * <dt><</dt><dd>(Default) Place cursor at beginning of string found.</dd>
 * <dt>></dt><dd>Place cursor after end of string found.</dd>
 * <dt>E</dt><dd>(Default) Case sensitive search.</dd>
 * <dt>I</dt><dd>Case insensitive search.</dd>
 * <dt>M</dt><dd>Search within visible mark.</dd>
 * <dt>H</dt><dd>Find text in hidden lines.   Only the line contain the
 * first character of the search string is checked.</dd>
 * <dt>R</dt><dd>Search for SlickEdit regular expression.  See
 * <b>SlickEdit Regular Expressions</b>.</dd>
 * <dt>U</dt><dd>Interpret string as a UNIX regular expression.   See
 * section <b>UNIX Regular Expressions</b>.</dd>
 * <dt>B</dt><dd>Interpret string as a Brief regular expression.   See
 * section <b>Brief Regular Expressions</b>.</dd>
 * <dt>N</dt><dd>(Default) Do not interpret search string as a regular
 * search string.</dd>
 * <dt>P</dt><dd>Wrap to beginning/end when string not found.  Flag
 * is set.  However, this option has no effect on this
 * function.</dd>
 * <dt>@</dt><dd>Don't display error message.</dd>
 * <dt>*</dt><dd>This option is ignored.</dd>
 * <dt>W</dt><dd>Limits search to words.  Used to search and replace
 * variable names.  The default word characters are
 * [A-Za-z0-9_$].  To change the word characters for
 * a specific extension, use the Extension Options
 * dialog box ("Tools", "Options", "File Extension Setup...",
 * select the Advanced tab).</dd>
 * <dt>W=<i>SlickEdit-regular-expression</i></dt><dd>
 * 	Specifies a word search and sets the default word
 * characters to those matched by the <i>SlickEdit-
 * regular-expression</i> given.</dd>
 * <dt>W:P</dt><dd>Limits search to word prefix.  For example,
 * searching for "pre" matches "pre" and "prefix" but
 * not "supreme" or "supre".</dd>
 * <dt>W:PS</dt><dd>Limits search to strict word prefix.  For example,
 * searching for "pre" matches "prefix" but not "pre",
 * "supreme" or "supre".</dd>
 * <dt>W:S</dt><dd>Limits search to word suffix.  For example,
 * searching for "fix" matches "fix" and "sufix" but
 * not "fixit".</dd>
 * <dt>W:SS</dt><dd>Limits search to strict word suffix.  For example,
 * searching for "fix" matches "sufix" but not "fix" or
 * "fixit".</dd>
 * <dt>Y</dt><dd>Binary search.  This allows start positions in the
 * middle of a DBCS or UTF-8 character.  This option
 * is useful when editing binary files (in SBCS/DBCS
 * mode) which may contain characters which look
 * like DBCS but are not.  For example, if you search
 * for the character 'a', it will not be found as the
 * second character of a DBCS sequence unless this
 * option is specified.</dd>
 * <dt>,</dt><dd>Delimiter to separate ambiguous options.</dd>
 * <dt>X<i>CCLetters</i></dt><dd>Requires the first character of search string
 * NOT be one of the color coding elements specified.
 * For example, "XCS" requires that the first character
 * not be in a comment or string. <i>CCLetters</i> is
 * a string of one or more of the following color
 * coding element letters:
 *
 * <dl>
 * <dt>O</dt><dd>Other</dd>
 * <dt>K</dt><dd>Keyword</dd>
 * <dt>N</dt><dd>Number</dd>
 * <dt>S</dt><dd>String</dd>
 * <dt>C</dt><dd>Comment</dd>
 * <dt>P</dt><dd>Preprocessing</dd>
 * <dt>L</dt><dd>Line number</dd>
 * <dt>1</dt><dd>Symbol 1</dd>
 * <dt>2</dt><dd>Symbol 2</dd>
 * <dt>3</dt><dd>Symbol 3</dd>
 * <dt>4</dt><dd>Symbol 4</dd>
 * <dt>F</dt><dd>Function color</dd>
 * <dt>V</dt><dd>No save line</dd>
 * </dl>
 * </dd>
 *
 * <dt>C<i>CCLetters</i></dt><dd>Requires the first character of search string to
 * be one of the color coding elements specified. See
 * <i>CCLetters</i> above.</dd>
 * </dl>
 *
 * @param pReplaceString	String to replace search string with.  Specify
 * 0 to just perform a search.  If
 * <i>pReplaceString</i> is not NULL, a
 * search and replace without prompting is
 * performed.
 *
 * @param ReplaceStringLen	Number of characters in
 * <i>pReplaceString</i>.  You can specify -1
 * if <i>pReplaceString</i> is null terminated.
 *
 * @param pNofChanges	If this is non-zero and a search and replace is
 * performed, this is set to the number of
 * changes made.
 *
 * @example
 * <pre>
 * 	     // Search for word delimited string "pathsearch" where the first
 * character is
 * 	     // not in a comment or a string.
 * 	     int Nofchanges;
 * 	     vsSearch( 0,"pathsearch",-1,"xcs,w", "path_search",-1,
 * &Nofchanges);
 * </pre>
 *
 * @see vsMatchLength
 * @see vsMatchStart
 * @see vsMatchCursorLength
 * @see vsSelectMatch
 * @see vsRepeatSearch
 * @see vsSearchReplace
 * @see vsSaveSearch
 * @see vsRestoreSearch
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsSearch(int wid,const char *pSearchString,int SearchStringLen, const char *pszOptions=0,const char *pReplaceString=0,int ReplaceStringLen=0,VSINT64 *pNofchanges=0,
                   int (VSAPI *pfnCompletionStatus)(VSINT64 offset,VSINT64 NofChanges,void *puserdata)=0,void *puserdata=0
                   );
int VSAPI vsSearchRaw(int wid,const char *pSearchString,int SearchStringLen, const char *pszOptions=0,const char *pReplaceString=0,int ReplaceStringLen=0,VSINT64 *pNofchanges=0,
                      int (VSAPI *pfnCompletionStatus)(VSINT64 offset,VSINT64 NofChanges,void *puserdata)=0,void *puserdata=0
                      );
/**
 * Repeats a search initiated by <b>vsSearch</b>.  This will not repeat a
 * search initiated with one of the Slick-C&reg; search commands
 * <b>find</b>, or <b>replace</b> (see <b>find_next</b> command).
 *
 * @return Returns 0 if successful.  Possible return codes are
 * INVALID_OPTION_RC and STRING_NOT_FOUND_RC.  On error,
 * message is displayed.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszOptions	String of zero or more of the following
 * option letters:
 *
 * <dl>
 * <dt>+</dt><dd>Forward search.</dd>
 * <dt>-</dt><dd>Reverse search.</dd>
 * <dt><</dt><dd>Place cursor at beginning of string found.</dd>
 * <dt>></dt><dd>Place cursor after end of string found.</dd>
 * <dt>E</dt><dd>Case sensitive search.</dd>
 * <dt>I</dt><dd>Case insensitive search.</dd>
 * <dt>M</dt><dd>Search within visible mark.</dd>
 * <dt>R</dt><dd>Search for regular expression.  Syntax of regular
 * expression is described in section "<b>SlickEdit
 * Regular Expressions</b>".</dd>
 * <dt>U</dt><dd>Interpret string as a UNIX regular expression.   See
 * section <b>UNIX Regular Expressions</b>.</dd>
 * <dt>B</dt><dd>Interpret string as a Brief regular expression.   See
 * section <b>Brief Regular Expressions</b>.</dd>
 * <dt>N</dt><dd>Do not interpret search string as a regular
 * expression search string.</dd>
 * <dt>@</dt><dd>No error message.</dd>
 * <dt>W</dt><dd>Limits search to words.  Used to search and replace
 * variable names.  The default word characters are
 * [A-Za-z0-9_$].  To change the word characters for
 * a specific extension, use the Extension Options
 * dialog box ("Tools", "Options", "File Extension Setup...",
 * select the Advanced tab).</dd>
 * <dt>W=<i>SlickEdit-regular-expression</i></dt><dd>
 * 	Specifies a word search and sets the default word
 * characters to those matched by the <i>SlickEdit-
 * regular-expression</i> given.</dd>
 * <dt>W:P</dt><dd>Limits search to word prefix.  For example,
 * searching for "pre" matches "pre" and "prefix" but
 * not "supreme" or "supre".</dd>
 * <dt>W:PS</dt><dd>Limits search to strict word prefix.  For example,
 * searching for "pre" matches "prefix" but not "pre",
 * "supreme" or "supre".</dd>
 * <dt>W:S</dt><dd>Limits search to word suffix.  For example,
 * searching for "fix" matches "fix" and "sufix" but
 * not "fixit".</dd>
 * <dt>W:SS</dt><dd>Limits search to strict word suffix.  For example,
 * searching for "fix" matches "sufix" but not "fix" or
 * "fixit".</dd>
 * <dt>Y</dt><dd>Binary search.  This allows start positions in the
 * middle of a DBCS or UTF-8 character.  This option
 * is useful when editing binary files (in SBCS/DBCS
 * mode) which may contain characters which look
 * like DBCS but are not.  For example, if you search
 * for the character 'a', it will not be found as the
 * second character of a DBCS sequence unless this
 * option is specified.</dd>
 * <dt>,</dt><dd>Delimiter to separate ambiguous options.</dd>
 * <dt>X<i>CCLetters</i></dt><dd>Requires the first character of search string
 * NOT be one of the color coding elements specified.
 * For example, "XCS" requires that the first character
 * not be in a comment or string. <i>CCLetters</i> is
 * a string of one or more of the following color
 * coding element letters:
 *
 * <dl>
 * <dt>O</dt><dd>Other</dd>
 * <dt>K</dt><dd>Keyword</dd>
 * <dt>N</dt><dd>Number</dd>
 * <dt>S</dt><dd>String</dd>
 * <dt>C</dt><dd>Comment</dd>
 * <dt>P</dt><dd>Preprocessing</dd>
 * <dt>L</dt><dd>Line number</dd>
 * <dt>1</dt><dd>Symbol 1</dd>
 * <dt>2</dt><dd>Symbol 2</dd>
 * <dt>3</dt><dd>Symbol 3</dd>
 * <dt>4</dt><dd>Symbol 4</dd>
 * <dt>F</dt><dd>Function color</dd>
 * <dt>V</dt><dd>No save line</dd>
 * </dl>
 * </dd>
 *
 * <dt>C<i>CCLetters</i></dt><dd>Requires the first character of search string to
 * be one of the color coding elements specified. See
 * <i>CCLetters</i> above.</dd>
 * </dl>
 *
 * Any search option not specified takes on the same value as the last
 * search executed.  The exact start column of the search may be
 * specified by <i>StartCol</i>.  If <i>StartCol</i> is not given,
 * searching continues so that the string found by the last search
 * command is not found again.
 *
 * @param StartCol	Optional column to start repeat search from.
 *
 * @example
 * <pre>
 * 	      // While we could use a regular expression to do what this loop
 * does, this example
 * 	      // is easy to understand.
 * 	       int status;
 * 	       status=vsSearch(0,"_command");
 * 	       for (;;) {
 * 	           if (status) break;
 * 	           if (vsPropGetI(0,VSP_COL) ==1) {
 * 	               status=0;break;   // Found _command in column 1
 * 	           }
 * 	           status=vsRepeatSearch (0);
 * 	       }
 * </pre>
 *
 * @see vsMatchLength
 * @see vsMatchStart
 * @see vsMatchCursorLength
 * @see vsSelectMatch
 * @see vsSearch
 * @see vsSearchReplace
 * @see vsSaveSearch
 * @see vsRestoreSearch
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
int VSAPI vsRepeatSearch(int wid,const char *pszOptions VSDEFAULT(0),int StartCol VSDEFAULT(0));

#ifndef VSLF_COMMENT_INFO_MASK
   #define VSLFC_VSSELDISPSHIFT      5

   #define VSLF_CURLINEBITMAP  0x00000200
   #define VSLF_MODIFY         0x00000400
   #define VSLF_INSERTED_LINE  0x00000800
   #define VSLF_HIDDEN         0x00001000
   #define VSLF_MINUSBITMAP    0x00002000
   #define VSLF_PLUSBITMAP     0x00004000
   #define VSLF_NEXTLEVEL      0x00008000
   #define VSLF_LEVEL          0x001F8000
   #define VSLF_NOSAVE         0x00200000
   #define VSLF_VIMARK         0x00400000
   #define VSLF_READONLY       0x00800000

   #define vsLevelIndex(bl_flags)  (((bl_flags) & VSLF_LEVEL)>>15)
   #define vsIndex2Level(level)   ((level)<<15)


   /*
       Syntax Color Coding encoding

       The syntax color coding is encoded in the low 8 bits of the 32
       bits of line flags.

          First mlcomment can be nested between 0x1 and 0x7.  7 levels
          Second mlcomment can be nested between 0x9 and 0xF.  7 levels
          Third mlcomment can be nested between 0x11 and 0x17.  7 levels
          fourth mlcomment can not be nested 0x19 and 0x1c.  4 levels
          0x8==VSLF_IN_LINE_COMMENT is a special return value from
            SETLINECOLOR callback which indicates that the last character
            of the line is in a line comment.
          0x1d is multi-line state 0
          0x1e,0x1f   is used for multiline squotes and dquotes
          0xE0  Bits of LexerStateInfo are for the embedded language index.
                This allows up to 7 different embedded languages per
                language.

       Bits for OS/390 Assembler
          Parenthesis nesting between 0x1 and 0x3.  3 levels
          0x8==VSLF_IN_LINE_COMMENT is a special return value from
            SETLINECOLOR callback which indicates that the last character
            of the line is in a line comment.
          bits 100xx In squote
          bits 110xx In line continuation of parameters
          bits 111xx In line continuation of comment


   */
   // Note that LF stands for Line flag.  The H is just to assist with
   // completion purposes.

   // Mask multi-line comments, strings, and embedded languages
   #define VSLF_LEXER_STATE_INFO 0xff

   // Encode embedded language lexer state
   #define vsLFHEmbeddedLanguageInfo(EmbeddedLanguageIndex)  (((EmbeddedLanguageIndex)+1)<<5)
   // Returns index of embedded language.  -1 indicates no embedded language.
   #define vsLFHEmbeddedLanguageIndex(comment_info)  ((((int)(comment_info) &VSLF_EMBEDDED_LANGUAGE_MASK)>>5)-1)

   // Mask multi-line comments, strings
   #define VSLF_COMMENT_INFO_MASK 0x1f

   #define VSLF_EMBEDDED_LANGUAGE_MASK 0xE0
   #define VSLF_IN_LINE_COMMENT  0x8
   #define VSLF_IN_LINE_DOCS     0xF
   #define VSLF_IN_STATE0       0x1D
   #define VSLF_IN_DQUOTE       0x1E
   #define VSLF_IN_SQUOTE       0x1F

   // only intended for Perl, Bourne Shell, and csh
   #define VSLF_IN_BQUOTE       0x1C

   // end of file indicator
   #define VSLF_PAST_EOF        0x18

   // Only valid when python style flag is on
   #define VSLF_PYTHON_QUOTE_MASK   0x1F
   #define VSLF_PYTHON_IN_DQTRIPLE  0x18
   #define VSLF_PYTHON_IN_SQTRIPLE  0x1C

   #define VSLF_LUA_LFQUOTE         0x1D

   #define VSLF_ASM390_PAREN_NESTING_MASK   0x3
   #define VSLF_ASM390_SQUOTECONT_MASK      0x1C
   #define VSLF_ASM390_IS_SQUOTE            0x10
   #define VSLF_ASM390_IS_LINECONT_PARAM    0x18
   #define VSLF_ASM390_IS_LINECONT_COMMENT  0x1C

   // This can only occur when CICS is embedded in OS/390 assembler
   //#define VSLF_CICS_IS_LINECONT_PARAM      0x18

   // Encode multi-line comment.
   #define vsLFHCommentInfo(nest_level,comment_index) (nest_level|(comment_index<<3))
   // Returns index of multi-line comment we are currently in.  Don't
   // use this macro unless vsLFHInComment returns non-zero value.
   #define vsLFHCommentIndex(LexerStateInfo) (((LexerStateInfo) &0x018)>>3)
   // Returns nesting level of multi-line comment we are currently in.
   // Don't use this macro unless vsLFHInComment returns non-zero value.
   #define vsLFHNestLevel(LexerStateInfo) ((LexerStateInfo) &0x7)
#endif

/**
 * @return Gets line status flags for the current line.  wid identifies the object to
 * be operated on.  0 specifies the current object.  See
 * <b>vsSetLineFlags</b> function for information on meaning of flags
 * returned.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @see vsQLineFlags
 * @see vsSetLineFlags
 * @see vsResetModifiedLineFlags
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsQLineFlags(int wid);
/**
 * Sets the line status flags for the current line.
 *
 * @param wid Window id of editor control.  0 specifies the current object.
 *
 * @param Flags <i>Flags</i> is one or more of the following constants ORed together:
 *
 * <dl>
 * <dt>
 * VSLF_MLCOMMENTINDEX</dt><dd>Indicates which multi-line comment.
 * Only two are allowed.  Must know which multi-line comment we
 * are in so we know what will terminate it.</dd>
 *
 * <dt>VSLF_MLCOMMENTLEVEL</dt><dd>Indicates multi-line
 * comment nest level.</dd>
 * <dt>VSLF_NOSAVE</dt><dd>Used by Difference
 * Editor and Merge Editor.  Lines with the VSLF_NOSAVE flag
 * set are not saved in the file.</dd>
 * <dt> VSLF_VIMARK</dt><dd>Used by VI emulation to mark lines.</dd>
 * <dt>VSLF_MODIFY</dt><dd>Line has been modified.</dd>
 * <dt>VSLF_INSERTED_LINE</dt><dd>Line was inserted.</dd>
 * <dt>VSLF_HIDDEN</dt><dd>Indicates that this line
 * should not be displayed.</dd>
 * <dt>VSLF_PLUSBITMAP</dt><dd>Display "+" bitmap to
 * left of this line.</dd>
 * <dt>VSLF_MINUSBITMAP</dt><dd>Display "-" bitmap to
 * left of this line.</dd>
 * <dt>VSLF_CURLINEBITMAP</dt><dd>Display current line bitmap.</dd>
 * <dt>VSLF_LEVEL</dt><dd>Bits used to store
 * selective display nest level.</dd>
 * </dl>
 *
 * <p>The MLCOMMENT flags can not be modified.</p>
 *
 * @param Mask The <i>Mask</i> indicates which bits will be set
 * according to <i>Flags</i>.  If <i>Mask</i> is 0, <i>Mask</i>
 * is set to the value of <i>Flags</i>.
 *
 * @see vsQLineFlags
 * @see vsSetLineFlags
 * @see vsResetModifiedLineFlags
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
void VSAPI vsSetLineFlags(int wid,int Flags,int Mask VSDEFAULT(0));
/**
 * <p>By default, when you call a function which makes a change to an
 * editor control window the editor just sets some internal flags
 * indicating what updates are needed.  Then when you call this function
 * with the 'A' option, all editor controls and other SlickEdit
 * objects are updated.  This makes macros written for SlickEdit
 * run much faster.  Call several editor control functions and when you
 * are done call this function with the 'A' option to update the window.</p>
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @param option	'A' or 'W'. The 'A' option refreshes all editor
 * controls, all editor control scroll bars, and
 * calls the VSINIT.pfnRefresh callback
 * function if one exists.  While it may sound
 * like the 'A' option is inefficient, it is actually
 * highly optimized.  SlickEdit only
 * updates editor controls which have data that
 * has been modified.  Use the 'W' option to
 * flush paint messages for the object specified.
 * The 'W' option will not update the scroll bars
 * or call the VSINIT.pfnRefresh callback.
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 *
 */
void VSAPI vsRefresh(int wid VSDEFAULT(0),char Option VSDEFAULT('A'));
/**
 * This function has been deprecated.  Use {@link vsDeleteWindow}() instead.
 *
 * @param wid	Window id of object.  0 specifies the current
 * object.
 *
 * @appliesTo All_Window_Objects
 * @categories Window_Functions
 *
 */
void VSAPI vsQuitView(int wid);
/**
 * Deletes the window specified.  If the window specified is an
 * editor control, the buffer is not deleted.
 *
 * @param wid       Window id of object.  0 specifies the current
 *                  object.
 * @param preserved
 * @param reserved
 *
 * @appliesTo All_Window_Objects
 * @categories Window_Functions
 *
 */
void VSAPI vsDeleteWindow(int wid,void *preserved=0,int reserved=0);
/**
 * Deletes buffer from the buffer ring even if the buffer is modified.  The
 * previous buffer's non-active cursor position information is used
 * for the cursor location.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @see _next_buffer
 * @see _prev_buffer
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void VSAPI vsDeleteBuffer(int wid);
/**
 * @return Returns highest tab expansion column.  This value is useful for
 * dynamically determine how large a buffer you need to expand tabs for
 * an entire line.  To determine the buffer size assume the worst case
 * where the first byte of the line is a tab character and the first tab stop is
 * the value returned by this function.
 *
 * @example
 * <pre>
 * 	// Lets say     vsQMaxTabCol()  == 1000
 * //	and            vsQLineLength(0)==10
 *
 * 	BufferSize= vsQMaxTabCol()+vsQLineLength(0)+2== 1012
 * char *pszBuffer=(char *)vsAlloc(BufferSize);
 * if (pszBuffer) {
 * 	    vsExpandTabsC(0,pszBuffer,BufferSize,1,-1,'E');
 * }
 * </pre>
 *
 * <p>We added 2 to adjust for adding a null terminating character and one
 * more to be extra careful.</p>
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsQMaxTabCol();
/**
 * Takes sub-string of source buffer and places the result in the dest
 * buffer.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszDest	Output.  Resulting string terminated with
 * ASCII 0.
 *
 * @param pDestLen	Output.  Number of bytes written to
 * <i>pszDest</i> not including ASCII 0.
 *
 * @param pSource	Input.  Source buffer.
 *
 * @param SrcLen	Input.  Number of bytes in source buffer
 * <i>pSource</i>.  You can specify -1 if
 * pSource is an ASCIIZ string.
 *
 * @param StartCol	Input. Start (imaginary) column for sub-
 * string.
 *
 * @param ColWidth	Input.  Number of (imaginary) columns to
 * get from <i>pSource</i>.   -1 specifies the
 * rest or the string.
 *
 * @param Option	Input.  Specify 'E' if you want all tabs
 * expanded.  Otherwise specify 'S' to return
 * tabs unexpanded.
 *
 * <p>The <i>StartCol</i> and <i>ColWidth</i> specification correspond to
 * the input <i>string</i> as if tab characters were expanded according to
 * the buffers tab settings.  We call this type of text position or count
 * imaginary.  Strings containing tab characters are expanded before
 * displayed.  Hence, the need arises for a differentiation between
 * physical and imaginary positions.  A physical position corresponds to
 * a byte in a string where  the characters are numbered one to the length
 * of string.  An imaginary position corresponds to a position in a string
 * once tabs have been expanded.</p>
 *
 * @see vsExpandTabsC
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 *
 */
void VSAPI vsExpandTabs(int wid,
                   char *pszDest,
                   int *pDestLen,
                   const char *pSource,
                   int SrcLen,
                   int StartCol,
                   int ColWidth,
                   char Option);
/**
 * Note: This function is a low level save function.  It does not support the
 * users "Save" options specified in the File Options dialog box.  It also
 * does not perform any prompting when a file is overwritten or if an
 * error occurs during the save.  We recommend you use the
 * <b>vsCommandSave</b> function instead of this function.
 *
 * <p>Writes buffer to file name specified.  If no filename is specified, the
 * buffer name is used.</p>
 *
 * <p>The <b>p_modify</b> property is turned off if the output filename is
 * the same as the buffer name.</p>
 *
 * @return Returns 0 if successful.  Common return codes are:
 * INVALID_OPTION_RC, ACCESS_DENIED_RC,
 * ERROR_OPENING_FILE_RC, INSUFFICIENT_DISK_SPACE_RC,
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC,
 * DRIVE_NOT_READY_RC, and PATH_NOT_FOUND_RC. On
 * error, message displayed.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszCmdLine	An option output filename in double quotes
 * and any of the following switches delimited
 * with a space:
 *
 * <p>Note that since record files are saved in binary (always with the +B
 * switch), many options have no effect.</p>
 *
 * <dl>
 * <dt>+ or -E</dt><dd>Turn on/off expand tabs to spaces switch.  Default
 * is off.</dd>
 *
 * <dt>+ or -G</dt><dd>Turn on/off setting of all old numbers.  Default is
 * off.  SlickEdit uses old line numbers to
 * better handle going to an error line after lines have
 * been inserted or deleted.  We don't recommend
 * setting the old line numbers on every save because
 * this requires that you do not save the file until you
 * have performed edits for all compile or multi-file
 * search messages.  See
 * <b>_SetAllOldLineNumbers</b> method for more
 * information.</dd>
 *
 * <dt>+ or -S</dt><dd>Strip trailing spaces on each line.  The buffer is
 * modified if the output file name matches the buffer
 * name.  Default is off.</dd>
 *
 * <dt>+FU</dt><dd>Save file in UNIX ASCII format (Lines ending with
 * just 10 character).  The buffer is modified if the
 * output file name matches the buffer name.</dd>
 *
 * <dt>+FD</dt><dd>Save file in DOS  ASCII format (Lines ending with
 * 13,10).  The buffer is modified if the output file
 * name matches the buffer name.</dd>
 *
 * <dt>+FM</dt><dd>Save file in Macintosh ASCII format (Lines ending
 * with just 13 character).  The buffer is modified if
 * the output file name matches the buffer name.</dd>
 *
 * <dt>+FR</dt><dd>Save file without line end characters.</dd>
 *
 * <dt>+F<i>ddd</i></dt><dd>Save file using ASCII character <i>ddd</i> as the
 * line end character.  The buffer is modified if the
 * output file name matches the buffer name.</dd>
 *
 * <dt>+ or -B</dt><dd>Binary switch.  Save file exactly byte per byte as it
 * appears in the buffer.  This option overrides all save
 * options which effect bytes in the input or output.
 * This option is always on for record buffers.
 * Defaults to value of <b>p_binary</b> property for
 * other buffers.</dd>
 *
 * <dt>+ or -O</dt><dd>Overwrite destination switch (no backup).  Default
 * is off.  Useful for writing a file to a device such as
 * the printer.</dd>
 *
 * <dt>+ or -T</dt><dd>Compress saved file with tab increments of 8.
 * Default is off.</dd>
 *
 * <dt>+ or -ZR</dt><dd>Remove end of file marker (Ctrl+Z).  This option is
 * ignored if the current buffer is not a DOS ASCII
 * file.  The buffer is modified if the
 * <b>p_showeof</b> is true and the output file name
 * matches the buffer name.  Default is off.</dd>
 *
 * <dt>+ or -Z</dt><dd>Add end of file marker (Ctrl+Z).  Note that if a
 * buffer has a visible EOF character, the output file
 * will still have an EOF character.  Use +ZR to
 * ensure that the output file does not have and EOF
 * character.  Default is off.</dd>
 *
 * <dt>+ or -L</dt><dd>Reset line modify flags.  Default is off.</dd>
 *
 * <dt>+ or -N</dt><dd>Don't save lines with the VSLF_NOSAVE bit set.
 * When the editor keeps track of whether a buffer has
 * lines with the VSLF_NOSAVE bit set, we will not
 * need this option.</dd>
 *
 * <dt>+ or -A</dt><dd>Convert destination filename to absolute.  Default
 * is on.  This option is currently used to write files to
 * device names such as PRN.  For example,
 * "_save_file +o -a +e prn" sends the current buffer
 * to the printer.</dd>
 *
 * <dt>+DB, -DB, +D,-D,+DK,-DK</dt><dd>
 * 	These options specify the backup style.  The default
 * backup style is +D.  The backup styles are:
 *
 * <dl>
 * <dt>+DB, -DB</dt><dd>Write backup files into the same directory as the
 * destination file but change extension to ".bak".</dd>
 *
 * <dt>+D</dt><dd>When on, backup files are placed in a single
 * directory.  The default backup directory is
 * "\vslick\backup\" (UNIX:
 * "$HOME/.vslick/backup") . You may define an
 * alternate backup directory by defining an
 * environment variable called VSLICKBACKUP.
 * The VSLICKBACKUP environment variable may
 * contain a drive specifier. The backup file gets the
 * same name part as the destination file.  For
 * example, given the destination file
 * "c:\project\test.c" (UNIX: "/project/test.c") , the
 * backup  file will be "c:\vslick\backup\test.c"
 * (UNIX: "$HOME/.vslick/backup/test.c").<br><br>
 *
 * <b>Non-UNIX platforms</b>: For a network, you
 * may need to create the backup directory with
 * appropriate access rights manually before saving a
 * file.</dd>
 *
 * <dt>-D</dt><dd>When on, backup file directories are derived from
 * concatenating a backup directory with the path and
 * name of the destination file.  The default backup
 * directory is "\vslick\backup\" (UNIX:
 * "$HOME/.vslick").  You may define an alternate
 * backup directory by defining an environment
 * variable called VSLICKBACKUP.  The
 * VSLICKBACKUP environment variable may
 * contain a drive specifier.  For example, given the
 * destination file "c:\project\test.c", the backup file
 * will be "c:\vslick\backup\project\test.c" (UNIX:
 * "$HOME/.vslick/backup/project/test.c").<br><br>
 *
 * <b>Non-UNIX platforms</b>: For a network, you may
 * need to create the backup directory with appropriate
 * access rights manually before saving a file.</dd>
 *
 * <dt>+DK,-DK</dt><dd>When on, backup files are placed in a directory off
 * the same directory as the destination file.  For
 * example, given the destination file
 * "c:\project\test.c" (UNIX: "$HOME/.vslick"), the
 * backup file will be "c:\project\backup\test.c"
 * (UNIX: "/project/backup/test.c").  This option
 * works well on networks.</dd>
 * </dl>
 * </dd>
 * </dl>
 *
 * @example
 * <pre>
 * 	    // Expand tabs and write buffer to temporary file.
 * 	    vsSaveFile(0,"+E tempfile");
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
int VSAPI vsSaveFile(int wid,const char *pszCmdLine);


typedef int (* DiffMFCallback) (const char *pszFilename1, const char *pszFilename2,
                                int iFileStatus);

#define VSDIFF_FILE_STATUS_MATCH     0
#define VSDIFF_FILE_STATUS_PATH1     1
#define VSDIFF_FILE_STATUS_PATH2     2
#define VSDIFF_FILE_STATUS_DIFFERENT 3

#define VSDIFF_TAG_STATUS_MATCH     0
#define VSDIFF_TAG_STATUS_PATH1     1
#define VSDIFF_TAG_STATUS_PATH2     2
#define VSDIFF_TAG_STATUS_DIFFERENT 3
#define VSDIFF_TAG_STATUS_MOVED     4

#define VSDIFF_OPT_BUF1          0x1
#define VSDIFF_OPT_BUF2          0x2
#define VSDIFF_OPT_PRESERVE_BUF1 0x4
#define VSDIFF_OPT_PRESERVE_BUF2 0x8
#define VSDIFF_OPT_QUIET         0x10
#define VSDIFF_OPT_READ_ONLY_1   0x20
#define VSDIFF_OPT_READ_ONLY_2   0x40
#define VSDIFF_OPT_INTERLEAVED   0x80
#define VSDIFF_OPT_MODAL         0x100
#define VSDIFF_OPT_VIEW_ONLY     0x200
#define VSDIFF_OPT_RECURSIVE     0x400
#define VSDIFF_OPT_NOMAP         0x800
#define VSDIFF_OPT_AUTOCLOSE     0x1000
#define VSDIFF_OPT_SHOWALWAYS    0x2000
#define VSDIFF_OPT_DIFFTAGS      0x4000
#define VSDIFF_OPT_COMPARE_ONLY  0x8000

/**
 * Diffs the files specified and displays the Diff dialog.
 *
 * @return Returns 0 if successful.  On error a message box is display.
 *
 * @param pszFileName1	Name of the first file to be diffed.  This will
 * be loaded from disk.  If there is a buffer by
 * the same name in memory, it will be used.
 * This may be a directory if you want a multi-
 * file diff.
 *
 * @param iBuf1Index	Buffer Index for the first buffer.  If you use
 * this, be sure to specify "" for pszFileName1,
 * and 0 for iWindow1Index.  Specify -1 to have
 * this parameter ignored.  Do not use this for a
 * multi-file diff.
 *
 * @param iWindow1Index	Window Index for the first buffer.  If you use
 * this, be sure to specify "" for pszFileName1,
 * and -1 for iBuf1Index.  Specify 0 to have
 * this parameter ignored.  Do not use this for a
 * multi-file diff.
 *
 * @param pszFileName2	Name of the second file to be diffed.  This
 * will be loaded from disk.  If there is a buffer
 * by the same name in memory, it will be
 * used.  This may only be a directory if you
 * want a multi-file diff, or if pszFileName2
 * differs from pszFileName1 by path only.
 *
 * @param iBuf2Index	Buffer Index for the second buffer.  If you
 * use this, be sure to specify "" for
 * pszFileName2, and 0 for iWindow2Index.
 * Specify -1 to have this parameter ignored.
 * Do not use this for a multi-file diff.
 *
 * @param iWindow2Index	Window Index for the second buffer.  If you
 * use this, be sure to specify "" for
 * pszFileName2, and -1 for iBuf2Index.
 * Specify 0 to have this parameter ignored. Do
 * not use this for a multi-file diff.
 *
 * @param iFlags	Combination of the following flags.  None
 * of these flags apply to multi-file diff:
 *
 * <dl>
 * <dt>VSDIFF_OPT_BUF1</dt><dd>
 * <i>pszFileName1</i> is a buffer name and not a relative
 * filename which needs the path to be fully resolved.</dd>
 *
 * <dt>VSDIFF_OPT_BUF2</dt><dd>
 * <i>pszFileName2</i> is a buffer name and not a relative
 * filename which needs the path to be fully resolved.</dd>
 *
 * <dt>VSDIFF_OPT_PRESERVE_BUF1</dt><dd>
 * Do not delete buffer 1 when the diff closes.  Should be used in
 * conjunction with a non-null <i>iBuf1Index</i>.  If the user
 * chooses to "save" changes to this buffer, the modify flag will
 * be left on to show the caller that the user wishes to save the
 * file.  If the user does not save changes to the buffer, all changes
 * will be undone, and the modify flag will be off.  When using
 * this option, be sure to turn VSP_MODIFY off, and set
 * VSP_UNDOSTEPS to a large number (32000 or more) before
 * calling this function.</dd>
 *
 * <dt>VSDIFF_OPT_PRESERVE_BUF2</dt><dd>
 * Save as VSDIFF_OPT_PRESERVE_BUF1, except for buffer
 * 2.</dd>
 *
 * <dt>VSDIFF_OPT_QUIET</dt><dd>
 * Quiet option.  Shuts off the "Files match" message</dd>
 *
 * <dt>VSDIFF_OPT_READ_ONLY_1</dt><dd>
 * Make File1 read only.</dd>
 *
 * <dt>VSDIFF_OPT_READ_ONLY_2</dt><dd>
 * Make File2 read only.</dd>
 *
 * <dt>VSDIFF_OPT_INTERLEAVED</dt><dd>
 * Interleaved output in a single buffer.  Cannot be specified for a
 * multi-file diff.</dd>
 *
 * <dt>VSDIFF_OPT_MODAL</dt><dd>
 * Show diff dialog modally.  Cannot be used with
 * VSDIFF_OPT_INTERLEAVED.</dd>
 *
 * <dt>VSDIFF_OPT_VIEW_ONLY</dt><dd>
 * Make both files read only.  Will not allow the user to type, and
 * will hide all the "copy" buttons.</dd>
 *
 * <dt>VSDIFF_OPT_RECURSIVE</dt><dd>
 * Recurse subdirectories.  Use this option only with multi-file
 * diffs.</dd>
 *
 * <dt>VSDIFF_OPT_NOMAP</dt><dd>
 * Do not add information about this diff to the mapping
 * file(diffmap.ini)</dd>
 * </dl>
 *
 * @param pszFileSpec	Filespecs to match for multi-file diff (ex "*.c
 * *.h").  This is a space delimited list.  Specify
 * only for a multi-file diff.  Specify "" to have
 * this parameter ignored.
 *
 * @param pszExcludeFileSpec       Filespecs to exclude for multi-file
 * diff (ex "junk* test*"). This is a space
 * delimited list.  Specify only for a multi-file
 * diff.  Specify "" to have this parameter
 * ignored.
 *
 * @param pszDialogTitle	Title of diff dialog box.  If "" is specified,
 * the title will be "Diff".  Title cannot be
 * blank. Do not use this for a multi-file diff.
 *
 * @param pszFile1Title	Title above file 1 editor control in diff
 * dialog.  If "" is specified, the Document
 * name, or buffer name will be used.  Title
 * cannot be blank. Do not use this for a multi-
 * file diff.
 *
 * @param pszFile2Title	Title above file 1 editor control in diff
 * dialog.  If "" is specified, the Document
 * name, or buffer name will be used.  Title
 * cannot be blank.  Do not use this for a multi-
 * file diff.
 *
 * @param pszComment	If this parameter is specified, a "Comment"
 * button will be visible on the diff dialog.
 * When the user presses the button, they will
 * see a dialog with the contents of this
 * parameter.  This string can contain new line
 * characters ("\n").  Do not use this for a
 * multi-file diff.
 *
 * @param pszCommentButtonCaption
 * 	This is the caption for the "Comment"
 * button.  Use this only in conjunction with
 * the pszComment parameter.  Do not use this
 * for a multi-file diff.
 *
 * @param pszImaginaryLineCaption
 * 	This is the text used for imaginary lines.
 * Note that this parameter is a global setting
 * and will effect other diffs currently in
 * progress.  For this reason, you must make
 * sure that this parameter is the same for all
 * calls to vsDiffFiles and vsMergeFiles.
 *
 * @categories File_Functions
 *
 */
int VSAPI vsDiffFiles(const char *pszFileName1 VSDEFAULT(""),
                      int iBuf1Index VSDEFAULT(-1),
                      int iWindow1Index VSDEFAULT(0),
                      const char *pszFileName2 VSDEFAULT(""),
                      int iBuf2Index VSDEFAULT(-1),
                      int iWindow2Index VSDEFAULT(0),
                      int iFlags VSDEFAULT(0),
                      const char *pszFileSpec VSDEFAULT(""),
                      const char *pszExcludeFileSpec VSDEFAULT(""),
                      const char *pszDialogTitle VSDEFAULT(""),
                      const char *pszFile1Title VSDEFAULT(""),
                      const char *pszFile2Title VSDEFAULT(""),
                      const char *pszComment VSDEFAULT(""),
                      const char *pszCommentButtonCaption VSDEFAULT(""),
                      const char *pszImaginaryLine VSDEFAULT(0),
                      const char *pszSaveButton1Caption VSDEFAULT(0),
                      const char *pszSaveButton2Caption VSDEFAULT(0),
                      const char *pszDiffStateFile VSDEFAULT(0));

/**
 *
 * @return
 *         Returns true if the last set of files compared with vsDiffFiles
 *         matched
 *
 * @categories File_Functions
 *
 */
int VSAPI vsDiffLastFilesMatched();


#define VSDIFF_COMP_OPT_EXPAND_TABS            0x01
#define VSDIFF_COMP_OPT_IGNORE_LSPACES         0x02
#define VSDIFF_COMP_OPT_IGNORE_TSPACES         0x04
#define VSDIFF_COMP_OPT_IGNORE_SPACES          0x08
#define VSDIFF_COMP_OPT_IGNORE_CASE            0x10
#define VSDIFF_COMP_OPT_OUTPUT_INTERLEAVED     0x20
#define VSDIFF_COMP_OPT_DONT_COMPARE_EOL_CHARS 0x40

/**
 * Use this function to set the compare options for DIFFzilla&reg;.
 * Most options apply to the interface itself, and can be
 * passed in at the time you are comparing the files.  This
 * function is used with the VSDIFF_COMP_OPT_* flags to actually
 * control things like wheter or not to compare spaces in when
 * comparing files.
 *
 * @param iFlags A combination of VSDIFF_COMP_OPT_* flags
 *
 * @return 0 if successful
 *
 * @categories File_Functions
 *
 */
int VSAPI vsDiffSetCompareOptions(int iFlags);

/**
 * Compares tokens for each file, excluding whitespace,
 * newlines, and comments.
 *
 * @param iFile1WID Window ID of first file to compare
 * @param iFile2WID Window ID of second file to compare
 * @param filesMatch set to true if the code for these files
 *                   matches
 *
 * @return int 0 if successful (not error, this does not imply
 *         if files match)
 */
int VSAPI vsDiffCode(int iFile1WID,int iFile2WID,bool &filesMatch);

/**
 * Create an editor buffer in a new window with the data specified in pBuffer
 *
 * @param pBuffer    Data to put in the new buffer.  This may be 0
 * @param iLen       Length of pBuffer.  If pBuffer is an ASCIIZ buffer, this
 *                   parameter maybe -1.
 * @param piNewWindowId
 *                   Address of int variable to store the new window id
 * @param pszLoadFileOptions
 *                   Options to be given to vsLoadFiles when creating the new buffer.
 *                   This is mainly here to be able to specify the "+fu" and
 *                   "+fd" options to specify line ending types.
 * @param pszLangId  Language ID.  See {@link p_LangId}.
 *                   For list of language types,
 *                   use our Language Options dialog
 *                   ("Tools", "Options","Language Setup...").
 * @param pszBufName Name of new editor buffer.
 * @param pszDocName Docname property for new buffer.
 *
 * @return 0 if succesful
 *
 * @categories File_Functions
 *
 */
int VSAPI vsCreateViewFromBuffer(const char *pBuffer, int iLen, int *piNewWindowId,
                                 const char *pszLoadFileOptions="", const char *pszLangId="",
                                 const char *pszBufName="", const char *pszDocName="");

/**
 * Get char buffer from window id. Use vsFree to free buffer
 * data.
 *
 * @param ppBuffer Address of char * variable to store data in
 * @param piLen    Address of int variable to store length of the data in
 * @param iWindowId  Window id to store in ppBuffer
 *
 * @return 0 if successful
 *
 * @categories File_Functions
 *
 */
int VSAPI vsGetBufferFromView(char **ppBuffer,int *piLen,int iWindowId);

#define VSMERGE_OPT_BASE_BUFFER            0x1
#define VSMERGE_OPT_REV1_BUFFER            0x2
#define VSMERGE_OPT_REV2_BUFFER            0x4
#define VSMERGE_OPT_OUTPUT_BUFFER          0x8
#define VSMERGE_OPT_SMART                  0x10
#define VSMERGE_OPT_INTERLEAVED            0x20
#define VSMERGE_OPT_QUIET                  0x40
#define VSMERGE_OPT_CALLERSAVES            0x80
// VSMERGE_OPT_FORCECONFLICT is not currently available
// #define VSMERGE_OPT_FORCECONFLICT          0x100
#define VSMERGE_OPT_SHOWCHANGES            0x200
#define VSMERGE_OPT_INDIVIDUALCONFLICTUNDO 0x400
#define VSMERGE_OPT_IGNORESPACES           0x800

/**
 * Performs a three way merge and displays the results interleave or in a
 * merge dialog.
 *
 * @return Returns 0 if successful and there are no conflicts.  1 if there are
 * conflicts and the user chooses to save the file.  2 if there are conflicts
 * and the user chooses not to save the file.  A negative return code is
 * returned and a error message box is diplayed if a file I/O error occurs
 * or a file does not exist.
 *
 * @param pszBaseFilename	Name of the base file.  This will be loaded
 * from disk.  If there is a buffer by this name
 * in memory, it will be used.
 *
 * @param iBaseBufferId	Buffer index for the base buffer.  If you use
 * this, be sure to specify "" for
 * pszBaseFilename, and 0 for iBaseWindowId.
 * Specify -1 to have this parameter ignored.
 *
 * @param iBaseWindowId	Window Index for the first buffer.  If you use
 * this, be sure to specify "" for
 * pszBaseFilename, and -1 for iBuf1Index.
 * Specify 0 to have this parameter ignored.
 *
 * @param pszRev1Filename	Name of the revision 1 file.  This will be
 * loaded from disk.  If there is a buffer by this
 * name in memory, it will be used.
 *
 * @param iRev1BufferId	Buffer index for the revision 1 buffer.  If
 * you use this, be sure to specify "" for
 * <i>pszRev1Filename</i>, and 0 for
 * <i>iRev1WindowId</i>.  Specify -1 to have
 * this parameter ignored.
 *
 * @param iRev1WindowId	Window Index for the revision 1 buffer.  If you
 * use this, be sure to specify "" for
 * <i>pszRev1Filename</i>, and -1 for
 * <i>iBuf1Index</i>.  Specify 0 to have this
 * parameter ignored.
 *
 * @param pszRev2Filename	Name of the revision 2 file.  This will be
 * loaded from disk.  If there is a buffer by this
 * name in memory, it will be used.
 *
 * @param iRev2BufferId	Buffer index for the revision 2 buffer.  If
 * you use this, be sure to specify "" for
 * <i>pszRev2Filename</i>, and 0 for
 * <i>iRev2WindowId</i>.  Specify -1 to have
 * this parameter ignored.
 *
 * @param iRev2WindowId	Window Index for the revision 2 buffer.  If you
 * use this, be sure to specify "" for
 * <i>pszRev2Filename</i>, and -1 for
 * <i>iBuf2Index</i>.  Specify 0 to have this
 * parameter ignored.
 *
 * @param pszOutputFilename	Name of the output 2 file.
 *
 * @param iOutputBufferId	Buffer index for the output buffer.  If you
 * use this, be sure to specify "" for
 * <i>pszOutputFilename</i>, and 0 for
 * <i>iOutputWindowId</i>.  If you specify
 * <i>iOutputBufferId</i> or
 * <i>iOutputWindowId</i>, the output will be
 * left open after merge terminates(if there are
 * conflicts) so that you can deal with the
 * output.  Specify -1 to have this parameter
 * ignored.
 *
 * @param iOutputWindowId	Window Id for the output buffer.  If you use
 * this, be sure to specify "" for
 * <i>pszOutputFilename</i>, and -1 for
 * <i>iOutputBufferId</i>.  If you specify
 * <i>iOutputBufferId</i> or
 * <i>iOutputWindowId</i>, the output will be
 * left open after merge terminates (if there are
 * conflicts) so that you can deal with the
 * output.  Specify 0 to have this parameter
 * ignored.
 *
 * @param iFlags Combination of the following flags:
 *
 * <dl>
 * <dt>VSMERGE_OPT_BASE_BUFFER</dt><dd>
 * <i>pszBaseFilename</i> is a buffer name and not a relative
 * filename which needs the path to be fully resolved.</dd>
 *
 * <dt>VSMERGE_OPT_REV1_BUFFER</dt><dd>
 * <i>pszRev1Filename</i> is a buffer name and not a relative
 * filename which needs the path to be fully resolved.</dd>
 *
 * <dt>VSMERGE_OPT_REV2_BUFFER</dt><dd>
 * <i>pszRev2Filename</i> is a buffer name and not a relative
 * filename which needs the path to be fully resolved.</dd>
 *
 * <dt>VSMERGE_OPT_OUTPUT_BUFFER</dt><dd>
 * <i>pszRev2Filename</i> is a buffer name and not a relative
 * filename which needs the path to be fully resolved.  Buffer is
 * left open after merge for user to deal with.</dd>
 *
 * <dt>VSMERGE_OPT_SMART</dt><dd>
 * Feeds some conflict pieces back to diff in order to try to
 * resolve conflicts.  In many cases, will not make a difference  IF
 * YOU WANT YOUR USERS TO MAKE MOST OF THE
 * DECISIONS WITH CONFLICTS, THIS OPTION IS NOT
 * FOR YOU.</dd>
 *
 * <dt>VSMERGE_OPT_INTERLEAVED</dt><dd>
 * Gives the output in a single buffer with collisions labeled
 * rather than in an interactive dialog.</dd>
 *
 * <dt>VSMERGE_OPT_QUIET</dt><dd>
 * Quiet option.  Shuts off "Merge complete x conflicts" message.</dd>
 *
 * <dt>VSMERGE_OPT_CALLERSAVES</dt><dd>
 * When the user is prompted to save the file on close, does not
 * actually save.</dd>
 *
 * <dt>VSMERGE_OPT_FORCECONFLICT</dt><dd>
 * Merge will never automatically copy a change/delete into the
 * output.  Instead, a conflict will be generated.</dd>
 *
 * <dt>VSMERGE_OPT_SHOWCHANGES</dt><dd>
 * In cases where merge automatically copies lines into the
 * output, the lines are still colored with the color of the file that
 * they came from so the user can see what happened.</dd>
 *
 * <dt>VSMERGE_OPT_INDIVIDUALCONFLICTUNDO</dt><dd>
 * Rather than use SlickEdit's buffer undo, when the undo
 * button is pressed, the current conflict region is returned to its
 * original state.</dd>
 *
 * <dt>VSMERGE_OPT_IGNORESPACES</dt><dd>
 * Does not force conflicts because of lines that differ in spacing.
 * In cases where  this happens, lines copied to output will always
 * come from the base file for consistency.</dd>
 * </dl>
 *
 * @param pszCopy1Caption	This is the caption of the "Copy 1>>"
 * button.
 *
 * @param pszCopy2Caption	This is the caption of the "Copy 2>>"
 * button.
 *
 * @param pszCopy1AllCaption	This is the caption of the "Copy 1
 * All>>" button.
 *
 * @param pszCopy2AllCaption	This is the caption of the "Copy 2
 * All>>" button/.
 *
 * @param pszImaginaryLineCaption	This is the text used for
 * imaginary lines. Note that this parameter is a
 * global setting and will effect other diffs
 * currently in progress.  For this reason, you
 * must make sure that this parameter is the
 * same for all calls to vsDiffFiles and
 * vsMergeFiles.
 *
 * @categories File_Functions
 *
 */
int VSAPI vsMergeFiles(const char *pszBaseFilename VSDEFAULT(""),
               int iBaseBufferId VSDEFAULT(-1),
               int iBaseWindowId VSDEFAULT(0),
               const char *pszRev1Filename VSDEFAULT(""),
               int iRev1BufferId VSDEFAULT(-1),
               int iRev1WindowId VSDEFAULT(0),
               const char *pszRev2Filename VSDEFAULT(""),
               int iRev2BufferId VSDEFAULT(-1),
               int iRev2WindowId VSDEFAULT(0),
               const char *pszOutputFilename VSDEFAULT(""),
               int iOutputBufferId VSDEFAULT(-1),
               int iOutputWindowId VSDEFAULT(0),
               int iFlags VSDEFAULT(0),
               const char *pszCopy1Caption VSDEFAULT(""),
               const char *pszCopy2Caption VSDEFAULT(""),
               const char *pszCopy1AllCaption VSDEFAULT(""),
               const char *pszCopy2AllCaption VSDEFAULT(""),
               const char *pszImaginaryLineCaption VSDEFAULT(0)
               );

/**
 * @param pszFilename	Name of help file to use.  At the moment,
 * help files have a .hlp extension.   We may
 * change our help system to use HTML files
 * in the future.
 *
 * @categories Miscellaneous_Functions
 *
 */
void vsSetHelpFilename(char *pszFilename);
/**
 * This function searches for the string specified and replaces it with the
 * string specified.  This function is different from vsCommandReplace
 * in that it uses a dialog box instead of the message line to prompt the
 * user.
 *
 * @return Returns 0 if successful.  Common return codes are
 * COMMAND_CANCELLED_RC, STRING_NOT_FOUND_RC,
 * INVALID_OPTION_RC and
 * INVALID_REGULAR_EXPRESSION_RC.  On error, message is
 * displayed.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param pszFindString	String to find.
 *
 * @param pszReplaceString	String to replace string found with.
 *
 * @param pszOptions	String of search options.  See vsSearch for
 * list of most options.  The following addition
 * options may be specified:
 *
 * <dl>
 * <dt>*</dt><dd>Make changes without prompting.</dd>
 * <dt>P</dt><dd>Wrap to beginning/end when string not
 * found.</dd>
 * </dl>
 *
 * @see vsCommandReplaceQNofChanges
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
int VSAPI vsSearchPromptReplace(int wid,const char *pszFindString,const char *pszReplaceString,const char *pszOptions);



VSPSZ VSAPI vsLCQDataAtLine(int wid,seSeekPos LineNum);

#define VSLCFLAG_ERROR   0x1
#define VSLCFLAG_CHANGE  0x2
#define VSLCFLAG_BOUNDS  0x4
#define VSLCFLAG_MASK    0x8
#define VSLCFLAG_COLS    0x10
#define VSLCFLAG_TABS    0x20

int VSAPI vsLCQFlagsAtLine(int wid,seSeekPos LineNum);

int VSAPI vsLCSetFlagsAtLine(int wid,seSeekPos LineNum,int flags,int mask VSDEFAULT(-1));

int VSAPI vsLCQNofLineCommands(int wid);

int VSAPI vsLCQFlagsAtIndex(int wid,int iLineCommand);

int VSAPI vsLCSetFlagsAtIndex(int wid,int iLineCommand,int flags,int mask);

/**
 * Retrieves the current character and/or places the cursor at the
 * beginning of the current character.
 *
 * @return Returns 0 if the cursor is already at the beginning of the current
 * character.  Otherwise, a non-zero value is returned.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param doBeginChar	When non-zero, cursor position is adjusted
 * if necessary.
 *
 * @param pCharLen	Set to number of bytes in current UTF-8
 * character.
 *
 * @param beginCompsite	When non-zero, operation supports
 * composite characters.
 *
 * @param pUTF32Array	(Output) If the buffer is UTF-8, this is set to
 * the UTF-32 characters in the current
 * character.  If the buffer is not UTF-8, the
 * current DBCS character is placed in the first
 * entry and the array length is set to 1.  The
 * DBCS lead byte is in the first 8 bits
 * (array[0]&0xff).
 *
 * @param pUTF32ArrayLen	Number of UTF-32 characters placed in
 * <i>pUTF32Array</i>.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsBeginChar(int wid,int doBeginChar VSDEFAULT(1), int *pCharLen VSDEFAULT(0),int beginComposite VSDEFAULT(1),unsigned *pUTF32Array VSDEFAULT(0),int *pUTF32ArrayLen VSDEFAULT(0));

/**
 * This function tells the editor to refresh parts of the buffer specified.
 * Currently only the break point manager uses this function because it
 * modifies bitmaps which are stored outside the editors control.
 *
 * @param buf_id	Buffer id returned by
 * <b>vsPropGetI</b>(<i>wid</i>,VSP_BUF_
 * ID),  <b>vsBufEdit</b>, or
 * <b>vsBufMatch</b>.
 *
 * @param flags	Specifies buffer properties that need to be
 * refreshed when <b>vsRefresh</b> is called
 * or the editor automatically calls vsRefresh
 * when a macro terminates.
 *
 * @categories Buffer_Functions
 *
 */
void VSAPI vsBufRefresh(int buf_id,int flags VSDEFAULT(VSREFRESH_BUFTEXT));
void VSAPI vsTrace();  // For internal use.
#define VSFILETYPE_NORMAL_FILE   1
#define VSFILETYPE_DATASET_FILE  2
#define VSFILETYPE_REMOTE_OS390_DATASET_FILE 3
#define VSFILETYPE_REMOTE_OS390_HFS_FILE     4
#define VSFILETYPE_JAR_FILE      5
#define VSFILETYPE_URL_FILE      6

/**
 * Determines the file type given the absolute (make sure the
 * <i>filename</i> is absolute) <i>filename</i> specified.  This function
 * is needed because SlickEdit has some NFS-like features for
 * handling some special files.  These special files may have performance
 * limitations or other limitations.  This function lets you check the type
 * and special case operations.  For example, the filename
 * "c:\java\src.zip\java\lang\Object.java" is a special file type because
 * SlickEdit will treat "src.zip" like a directory so that files can be
 * loaded out of a zip (or jar) file without requiring much special code.
 * Currently, SlickEdit's NFS-like layer does not support writing
 * to zip or jar files.
 *
 * @return Returns one of the VSFILETYPE_* constants.
 *
 * @categories File_Functions
 *
 */
int VSAPI vsFileQType(VSPSZ pszFilename);

// VSXML
#define VSXML_VALIDATION_SCHEME_WELLFORMEDNESS  0x1
#define VSXML_VALIDATION_SCHEME_VALIDATE        0x2
#define VSXML_VALIDATION_SCHEME_AUTO            VSXML_VALIDATION_SCHEME_WELLFORMEDNESS | VSXML_VALIDATION_SCHEME_VALIDATE


int VSAPI vsXMLOpen(const char *pszFilename,int &status,int OpenFlags, int iEncoding VSDEFAULT(2));
int VSAPI vsXMLGetNumErrors(int iHandle);
int VSAPI vsXMLGetErrorInfo(int iDocHandle, int errIndex, int &line, int& col, char**fn, char**msg);
int VSAPI vsXMLClose(int iHandle);
int VSAPI vsXMLOpenFromControl(int wid,int &status,int flags VSDEFAULT(0),int StartRealSeekPos VSDEFAULT(0),int EndRealSeekPos VSDEFAULT(VSNULLSEEK),void *preserved VSDEFAULT(0));

/*
   Support for old names
*/
#define vsPicAdd vsLineMarkerAdd
#define vsPicAddB vsLineMarkerAddB
#define vsPicAddMarkId vsLineMarkerAddMarkId
#define vsPicAddMarkIdB vsLineMarkerAddMarkIdB
struct VSPICLISTITEM {
   int PicIndex;
   seSeekPos LineNum;
   seSeekPos NofLines;
   int BMIndex;
   int type;
   int MousePointer;
   int RGBBoxColor;
   char *pszMessage;
   void *pUserData;
};
/**
 * @deprecated.  Use {@link vsLineMarkerAllocFindList}() instead.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @param wid        Window id of editor control.  0 specifies the
 *                   current object.
 * @param LineNum    Line number returned by
 *                   vsPropGetI(wid,VSP_LINE)
 * @param LineOffset Optional specifies offset to search for Pics
 *                   which use MarkIds.
 * @param CheckNofLines
 * @param reserved
 *
 * @return Returns list of pictures which match the line (or lines if
 *         <i>CheckRange</i> is non-zero) specified.
 */
VSPICLISTITEM *VSAPI vsPicFindList(int wid,seSeekPos LineNum,seSeekPos LineOffset=(seSeekPos)VSNULLSEEK,int CheckNofLines=0,int reserved=0);

#define VSPICFLAG_AUTO_REMOVE            VSMARKERTYPEFLAG_AUTO_REMOVE
#define VSPICFLAG_DRAW_BOX               VSMARKERTYPEFLAG_DRAW_BOX
#define VSPICFLAG_UNDO                   VSMARKERTYPEFLAG_UNDO
#define VSPICFLAG_COPYPASTE              VSMARKERTYPEFLAG_COPYPASTE
#define VSPICFLAG_COPY_CHAR_LINE_SELECT  VSMARKERTYPEFLAG_COPY_CHAR_LINE_SELECT


/**
 * @deprecated.  Use {@link vsLineMarkerGet}() instead.
 *
 * @return Returns 0 if successful.
 *
 * @param PicIndex	Index of pic returned by a vsPicAdd
 * function.
 *
 * @param pRealLineNum	Set to real line number.
 *
 * @param pLineNum	Set to line number.
 *
 * @param pNofLines	Set to number of lines.  Used to determine
 * how lines to draw a box around.
 *
 * @param ppuserdata	Set to userdata.
 *
 * @param pBufID	Set to buffer id or negative number  if file is
 * not currently loaded.
 *
 * @param pszBufName	Set to buffer name.
 *
 * @param pBMIndex	Set to index into names table of bitmap.
 *
 * @param ptype 	Set to type.
 *
 * @param pszMessage	Set to message.
 *
 * @param pszLineData	Set to line data.  This parameter is typically
 * only used by pics with a valid mark id.
 *
 * @param pmarkid	Set to mark id.
 *
 * @param pBeginLineROffset	Set to real seek position to the
 * beginning of the line.
 *
 * @param pcol	Set to column.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsPicGet(int PicIndex,
                   seSeekPos *pRealLineNum VSDEFAULT(0),
                   seSeekPos *pLineNum VSDEFAULT(0),
                   seSeekPos *pNofLines VSDEFAULT(0),
                   void **ppUserData VSDEFAULT(0),
                   int *pBufID VSDEFAULT(0),
                   char *pszBufName VSDEFAULT(0),
                   int *pBMIndex VSDEFAULT(0),
                   int *ptype VSDEFAULT(0),
                   char **pszMessage VSDEFAULT(0),
                   char *pszLineData VSDEFAULT(0),
                   int *pmarkid VSDEFAULT(0),
                   seSeekPos *pBeginLineROffset VSDEFAULT(0),
                   int *pcol VSDEFAULT(0),
                   void *preserved2 VSDEFAULT(0)
                   );
#define vsPicGetBoxColor vsLineMarkerGetBoxColor
#define vsPicNext vsLineMarkerNext
#define vsPicRemove vsLineMarkerRemove
#define vsPicRemoveAllBMIndex vsLineMarkerRemoveAllBMIndex
#define vsPicRemoveAllType vsLineMarkerRemoveAllType
#define vsPicRemoveBMIndex vsLineMarkerRemoveBMIndex
#define vsPicRemoveType vsLineMarkerRemoveType
#define vsPicSetBMIndex vsLineMarkerSetBMIndex
#define vsPicSetUserData vsLineMarkerSetUserData
#define vsPicTypeSetCallbackRefresh vsMarkerTypeSetCallbackRefresh
#define vsPicTypeSetCallbackLinesDeleted vsMarkerTypeSetCallbackLinesDeleted
#define vsPicTypeSetCallbackMouseEvent vsMarkerTypeSetCallbackMouseEvent
#define vsPicSetBoxColor vsLineMarkerSetStyleColor
#define vsPicTypeSetFlags vsMarkerTypeSetFlags
#define vsPicSetMousePointer vsLineMarkerSetMousePointer
#define vsPicTypeSetCallbackCopyUserData vsMarkerTypeSetCallbackCopyUserData
#define vsPicTypeSetCallbackPasteUserData vsMarkerTypeSetCallbackPasteUserData
#define vsPicTypeSetCallbackFreeUserData vsMarkerTypeSetCallbackFreeUserData
#define vsPicTypeSetCallbackPasteIntoLine vsMarkerTypeSetCallbackPasteIntoLine
#define vsPicTypeQFlags vsMarkerTypeQFlags
#define vsPicTypeAlloc vsMarkerTypeAlloc

/**
 * Adds a new line marker.
 *
 * @return Returns index of new line marker.
 *
 * @param wid  Window id of editor control. 0 specifies the
 *             current object.
 *
 * @param RealLineNum  Line number or real line number (not
 *                     counting no save lines).
 *
 * @param isRealLineNum  Indicates whether <i>RealLineNum</i> is
 *                       a real line number or not.
 *
 * @param NofLines  Number of lines in this item. Specify zero
 *                  if the marker type you are using does not
 *                  have the VSMARKERTYPEFLAG_DRAW_BOX flag set.
 *
 * @param BMIndex  Bitmap to display at the line specified.
 *                 Specify 0 for no bitmap.  The following are
 *                 names of bitmaps used for debugging:
 *
 * <dl>
 * <dt>_breakpt.ico</dt><dd>Indicates a line with an enabled
 * break point.</dd>
 * <dt>_breakpn.ico</dt><dd>Indicates a line with a disabled
 * break point.</dd>
 * <dt>_execpt.ico</dt><dd>Indicates current execution
 * line.</dd>
 * <dt>_stackex.ico</dt><dd>Indicates a line on the execution
 * call stack.</dd>
 * </dl>
 *
 * @param type  Type allocated by <b>vsMarkerTypeAlloc</b>().
 *
 * @param pszMessage  HTML message displayed when mouse is over
 *                    bitmap. Only a subset of HTML is supported
 *                    by our mini-HTML control.
 *
 * @param pUserData  Pointer to user data.
 *
 * @example
 * <pre>
 * // Add debug bitmap to give the visual effect of a
 * // break point.
 * int type=vsMarkerTypeAlloc();
 * int LineMarkerIndex=vsLineMarkerAdd(0, vsPropGetI64(0,VSP_LINE),
 *                       0,4, vsFindIndex("_breakpt.ico",VSTYPE_PICTURE),
 *                       type);
 *
 * // Add a line marker which draws a box
 * int type=vsMarkerTypeAlloc();
 * int LineMarkerIndex=vsLineMarkerAdd(0,vsPropGetI64(0,VSP_LINE),
 *                       0,4,vsFindIndex("_edplus.ico",VSTYPE_PICTURE),
 *                       type,"line 1&lt;br&gt;line2");
 * vsLineMarkerSetMousePointer(LineMarkerIndex,MP_CROSS);
 * vsLineMarkerSetStyleColor(LineMarkerIndex,0xff0000);
 * vsMarkerTypeSetFlags(type,VSMARKERTYPEFLAG_DRAW_BOX|VSMARKERTYPEFLAG_AUTO_REMOVE);
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsLineMarkerAdd(int wid,seSeekPos RealLineNum,int isRealLineNum,seSeekPos NofLines,int BMIndex,int type,const char *pszMessage VSDEFAULT(0), void *pUserData VSDEFAULT(0), void *reserved VSDEFAULT(0));
/**
 * Adds a new line marker.   Note that using a mark id instead of a line
 * number has the advantage that the number of lines in the file do not
 * need to be calculated.  This is only useful for data files and not source
 * files.  However, the draw box feature is not supported.
 *
 * @return Returns index of new line marker.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param MarkId	Mark id allocated by vsAllocSelection().
 *
 * @param BMIndex	Bitmap to display at the line specified.
 * Specify 0 for no bitmap.
 *
 * @param type	Type allocated by
 * <b>vsMarkerTypeAlloc</b>().
 *
 * @param Message	HTML message displayed when mouse is
 * over bitmap.  Only a subset of HTML
 * supported by our mini-HTML control is
 * supported.
 *
 * @param pUserData	Pointer to user data.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsLineMarkerAddMarkId(int wid,int markid,int BMIndex,int type,const char *pszMessage VSDEFAULT(0), void *pUserData VSDEFAULT(0), void *reserved VSDEFAULT(0));
/**
 * Adds a new stream marker with an optional associated line picture.   Stream markers are intended
 * to be used for squiggly underline error markup, color markup, box markup, and focus rectangle markup.  The number of lines
 * in the file do not need to be calculated for this type of marker.
 *
 * The draw box feature is not supported.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 * @param wid        Window id of editor control.  0 specifies the current object.
 * @param StartOffset
 *                   Byte start offset of text in file
 * @param Length     Byte length of text
 * @param isRealOffset
 *                   When non-zero, indicates that <i>StartOffset</i> does NOT include lines with the NOSAVE VSLF_NOSAVE flag set.
 *                   Note that lines with the VSLF_NOSAVE flag set are not saved with the file on disk.
 *
 * @param BMIndex    Bitmap to display at the line specified.
 *                   Specify 0 for no bitmap.
 *
 * @param type       Type allocated by <b>vsMarkerTypeAlloc</b>().
 * @param pszMessage Optional message to display as tooltip help when cursor is over the bitmap.
 * @param pUserData  Pointer to user data.
 * @param reserved
 *
 * @return Returns index of new stream marker.
 *
 * @example
 * <pre>
 *    int type=vsMarkerTypeAlloc();
 *    vsMarkerTypeSetFlags(type,VSMARKERTYPEFLAG_DRAW_BOX|VSMARKERTYPEFLAG_AUTO_REMOVE|VSMARKERTYPEFLAG_UNDO);
 *    int wid=0; // current window which hopefully is and editor control.
 *    int StreamMarkerIndex=vsStreamMarkerAdd(
 *                  wid,
 *                  vsQOffset(wid),4,false,
 *                  vsFindIndex("_edplus.bmp",VSTYPE_PICTURE),type,"this is a test");
 *    vsStreamMarkerSetStyleColor(StreamMarkerIndex,0xff);
 * </pre>
 */
int VSAPI vsStreamMarkerAdd(int wid, seSeekPos StartOffset, seSeekPos Length, int isRealOffset, int BMIndex,int type,const char *pszMessage=0,void *pUserData=0,void *reserved=0);

/**
 * Adds a new stream marker with an optional associated line picture.   Stream markers are intended
 * to be used for squiggly underline error markup.  The number of lines
 * in the file do not need to be calculated for this type of marker.
 *
 * The draw box feature is not supported.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 *
 * @param pszBufName Name of Buffer;
 * @param StartOffset
 *                   Byte start offset of text in file
 * @param Length     Byte length of text
 * @param isRealOffset
 *                   When non-zero, indicates that <i>StartOffset</i> does NOT include lines with the NOSAVE VSLF_NOSAVE flag set.
 *                   Note that lines with the VSLF_NOSAVE flag set are not saved with the file on disk.
 *
 * @param BMIndex    Bitmap to display at the line specified.
 *                   Specify 0 for no bitmap.
 *
 * @param type       Type allocated by <b>vsMarkerTypeAlloc</b>().
 * @param pszMessage Optional message to display as tooltip help when cursor is over the bitmap.
 * @param pUserData  Pointer to user data.
 * @param reserved
 *
 * @return Returns index of new stream marker.
 */
EXTERN_C
int VSAPI vsStreamMarkerAddB(const char *pszBufName,seSeekPos StartOffset,seSeekPos Length,int isRealOffset,int BMIndex,int type,const char *pszMessage, void *pUserData=0,void *reserved=0);

struct VSSTREAMMARKERINFO {
   bool isDeferred;
   union {
      int buf_id;
      char szDeferredBufName[VSMAXFILENAME];
   };
   seSeekPos StartOffset;
   seSeekPos Length;
   int BMIndex;
   int type;
   int MousePointer;
   int RGBBoxColor;
   VSCOLORINDEX ColorIndex;
   char szMessage[VSMAXMESSAGE];
   void *pUserData;
};

/**
 * Retrieves properties for stream marker.
 *
 * @param StreamMarkerIndex  Index of stream marker returned by a vsStreamMarkerAdd function.
 * @param info      Returns all properties for stream marker.
 * @param version
 *
 * @return 0 if stream marker index is valid.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsStreamMarkerGet(int StreamMarkerIndex,VSSTREAMMARKERINFO &info,int version=0);

/**
 * Get the type of the stream marker
 *
 * @param StreamMarkerIndex  Index of stream marker returned by a vsStreamMarkerAdd function.
 *
 * @return 0 type of the <B>StreamMarkerIndex</B>
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsStreamMarkerGetType(int StreamMarkerIndex);

/** 
 * Get the starting offset of a stream marker 
 * 
 * @param StreamMarkerIndex stream marker to get starting offset 
 *                          of
 * 
 * @return vsSeekPos VSAPI Offset if valid, -1 otherwise
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
seSeekPosRet VSAPI vsStreamMarkerGetStartOffset(int StreamMarkerIndex);

/** 
 * Get the length stream marker 
 * 
 * @param StreamMarkerIndex stream marker to get starting length
 *                          of
 * 
 * @return int VSAPI length if valid, -1 otherwise
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
seSeekPosRet VSAPI vsStreamMarkerGetLength(int StreamMarkerIndex);

struct VSLINEMARKERINFO {
   bool isDeferred;
   union {
      int buf_id;
      char szDeferredBufName[VSMAXFILENAME];
   };
   //int RealLineNum;
   seSeekPos LineNum;  // Set to -1 for markids
   seSeekPos NofLines;
   void *pUserData;
   int BMIndex;
   int type;
   char szMessage[VSMAXMESSAGE];
   int MousePointer;
   int RGBBoxColor;
   int markid;
   /*
   char szLineData[VSMAXBOOKMARKLINEDATA];
   long markid_BeginLineROffset;
   int markid_col;
   */
};
/**
 *
 * @param LineMarkerIndex  Index of line marker returned by a vsLineMarkerAdd function.
 * @param info      Returns all information for line marker.
 * @param version
 *
 * @return 0 if stream marker index is valid.
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsLineMarkerGet(int LineMarkerIndex,VSLINEMARKERINFO &info,int version=0);


/**
 * Retrieves marker type flags
 *
 * @param type   Type returned by {@link vsMarkerTypeAlloc}()
 *
 * @return Returns marker type flags set by {@link vsMarkerTypeSetFlags}().
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsMarkerTypeQFlags(int type);

/**
 * Retrieves marker type color index
 *
 * @param type   Type returned by {@link vsMarkerTypeAlloc}()
 *
 * @return     Returns color index flags set by
 *             {@link vsMarkerTypeSetColorIndex}().
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsMarkerTypeQColorIndex(int type);

/**
 * Retrieves marker type draw priority.
 * Lower numbers mean higher priority, 0 is the default priority.
 *
 * @param type   Type returned by {@link vsMarkerTypeAlloc}()
 *
 * @return Returns marker type flags set by {@link vsMarkerTypeSetFlags}().
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsMarkerTypeQPriority(int type);
/**
 *
 * @param LineMarkerIndex   Index of line marker returned by a vsLineMarkerAdd function.
 * @param pRGBBoxColor   Set to RGB color specified by {@link vsLineMarkerSetStyleColor}().
 *
 * @return 0 if line marker index index is valid.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsLineMarkerGetBoxColor(int LineMarkerIndex,int *pRGBBoxColor);

/**
 * Adds a new line marker.
 *
 * @return Returns index of new line marker.
 *
 * @param pszBufName	Name of buffer.
 *
 * @param RealLineNum	Line number or real line number (not
 * counting no save lines).
 *
 * @param isRealLineNum	Indicates whether <i>RealLineNum</i> is a
 * real line number or not.
 *
 * @param NofLines	Number of lines in this item.  Specify zero if
 * the type you are using does not have the
 * VSMARKERTYPEFLAG_DRAW_BOX flag set.
 *
 * @param BMIndex	Bitmap to display at the line specified.
 * Specify 0 for no bitmap.  The following are
 * names of bitmaps used for debugging:
 *
 * <dl>
 * <dt>_breakpt.ico</dt><dd>Indicates a line with an enabled
 * break point.</dd>
 * <dt>_breakpn.ico</dt><dd>Indicates a line with a disabled
 * break point.</dd>
 * <dt>_execpt.ico</dt><dd>Indicates current execution
 * line.</dd>
 * <dt>_stackex.ico</dt><dd>Indicates a line on the execution
 * call stack.</dd>
 * </dl>
 *
 * @param type	Type allocated by
 * <b>vsMarkerTypeAlloc</b>().
 *
 * @param pszMessage	HTML message displayed when mouse is
 * over bitmap.  Only a subset of HTML
 * supported by our mini-HTML control is
 * supported.
 *
 * @param pUserData	Pointer to user data.
 *
 * @param pszLineData	This is usually 0 but may contain some of
 * the contents of the line.
 *
 * @example
 * <pre>
 * // Add debug bitmap to give the visual effect of a
 * // break point.
 * int type=vsMarkerTypeAlloc();
 * int LineMarkerIndex=vsLineMarkerAddB("c:\\projects\\java\\main.java",
 *                        10,
 *                        1,4,
 *                        vsFindIndex("_breakpt.ico",VSTYPE_PICTURE),
 *                        type);
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsLineMarkerAddB(const char *pszBufName,seSeekPos RealLineNum,int isRealLineNum,seSeekPos NofLines,int BMIndex,int type,const char *pszMessage VSDEFAULT(0), void *pUserData VSDEFAULT(0),const char *pszLineData VSDEFAULT(0), void *reserved VSDEFAULT(0));
/**
 * Adds a new line marker.   Note that using a mark id instead of a line
 * number has the advantage that the number of lines in the file do not
 * need to be calculated.  This is only useful for data files and not source
 * files.  However, the draw box feature is not supported.
 *
 * @return Returns index of new line marker.
 *
 * @param pszBufName	Name of buffer.
 *
 * @param MarkId	Mark id allocated by vsAllocSelection().
 *
 * @param BMIndex	Bitmap to display at the line specified.
 * Specify 0 for no bitmap.
 *
 * @param type	Type allocated by
 * <b>vsMarkerTypeAlloc</b>().
 *
 * @param pszMessage	HTML message displayed when mouse is
 * over bitmap.  Only a subset of HTML
 * supported by our mini-HTML control is
 * supported.
 *
 * @param pUserData	Pointer to user data.
 *
 * @param pszLineData	This is usually 0 but may contain some of
 * the contents of the line.
 *
 * @param RealLineNum
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsLineMarkerAddMarkIdB(const char *pszBufName,int markid,int BMIndex,int type,const char *pszMessage VSDEFAULT(0), void *pUserData VSDEFAULT(0), const char *pszLineData VSDEFAULT(0), seSeekPos RealLineNum= seSeekPos(0), seSeekPos BeginLineROffset =seSeekPos(0),int col VSDEFAULT(0), void *reserved VSDEFAULT(0));
/**
 * @return Returns index of type.  Once a type is allocated, various attributes of
 * the type can be set.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 * @see vsMarkerTypeFree
 *
 */
int VSAPI vsMarkerTypeAlloc();

/**
 * Frees marker type alloced by {@link vsMarkerTypeAlloc}().
 *
 * @param type    Marker type index
 *
 * @return Returns 0 on success, <0 on error.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 * @see vsMarkerTypeAlloc
 *
 */
int VSAPI vsMarkerTypeFree(int type);

/**
 * @return Returns 0 if successful.
 *
 * Sets the refresh callback for the marker type specified.  This callback is
 * called when a line marker line numbers change or a marker is removed because
 * all text for the marker was removed.
 *
 * @param type	Index of marker type.
 *
 * @param pfnRefreshMarkers	Callback.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsMarkerTypeSetCallbackRefresh(
   int type,
   void (VSAPI * pfnRefreshMarkers)(int MarkerRefreshFlags)
   );
/**
 * @return Returns 0 if successful.
 *
 * Sets the callback for the specified mouse event.
 *
 * @param type	Index of marker type.
 *
 * @param event	Mouse event constant. Mouse event constant
 * (ex VS_OFFSET_MEVENTS+VS_MK_LBUTTON_DOWN).
 * Only the
 * LBUTTON_DOWN,
 * LBUTTON_DOUBLE_CLICK,
 * RBUTTON_DOWN events are supported.
 *
 * @param pfnCommand	Callback.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsMarkerTypeSetCallbackMouseEvent(
   int type,
   int event,
   int (VSAPI * pfnCommand)(int wid,seSeekPos LineNum, int LineMarkerIndex,int BMIndex,int Type, const char *pszMessage, void *pUserData) VSDEFAULT(0)
   );
#define vsMarkerTypeSetCallbackLinesDeleted vsMarkerTypeSetCallbackKeepEmptyMarker
/**
 * Sets the KeepEmptyMarker callback for the marker type specified.  The purpose of this
 * callback is to give you more control over whether this marker should be deleted.  DO
 * NOT free user data in this callback.  Instead, define the
 * vsMarkerTypeSetCallbackFreeUserData() callback.
 *
 * <p> For line markers, this callback is called when the line
 * containing this marker is deleted and NofLines&lt;=0.
 * <p> For stream markers, this callback is called when all the text in the range is deleted.
 *
 * @param type   Type returned from vsMarkerTypeAlloc()
 * @param pfnPicKeepEmptyMarker
 *               Callback function.  Returns 0 if the marker should be deleted.
 *
 * @return Returns 0 if the marker type is valid.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsMarkerTypeSetCallbackKeepEmptyMarker(
   int type,
   int (VSAPI * pfnKeepEmptyMarker)(int MarkerIndex, int BMIndex,int type,void *pUserData)
   );
/**
 * Sets the CopyUserData callback for the marker type specified.  You may need to
 * define this callback if you want support for Undo or Copy/Paste.  The purpose of this
 * callback is to allow you to create a copy of the user data so that it may
 * be stored in the undo stack.  No pointers should be stored in
 * in the pDestClipboardUserData buffer because in the future the copy/paste
 * functionality could support inter-process clipboards.
 *
 * <p>This callback is called just before a marker is about to
 * be deleted or copied.
 *
 * @param type   Type returned from vsMarkerTypeAlloc()
 * @param pfnMarkerCopyUserData
 *               Callback function.  Sets buffer length of pDestClipboardUserData and
 *               if pDestClipboardUserData is not NULL, fills this buffer in with the
 *               user data.  pDestClipboardUserData is NULL the first time this callback
 *               is called to determine the buffer size.
 *
 * @return Returns 0 if the marker type is valid.
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsMarkerTypeSetCallbackCopyUserData(
   int type,
   void (VSAPI * pfnMarkerCopyUserData)(int SrcMarkerIndex, int SrcBMIndex,int SrcType,const void *pSrcUserData, void *pDestClipboardUserData,int *pDestClipboardUserDataLen)
   );


/**
 * Sets the PasteUserData callback for the marker type specified.  You may need to
 * define this callback if you want support for Undo or Copy/Paste.  The purpose of this
 * callback is to allow you to create new user data for the marker which has just
 * been created and set in a buffer.
 *
 * <p>This callback is called when a new marker has been created due to
 * an Undo/Paste/Copy-to-Clipboard or Buffer-to-Buffer-Copy.  The new marker has
 * the same settings as the marker that was copied except for line number information.
 *
 * <p> Note: Currently our copy/paste facility is performed by
 *     Buffer-to-Buffer-Copy because the SlickEdit clipboard is a buffer
 *
 * @param type   Type returned from vsMarkerTypeAlloc()
 * @param pfnMarkerPasteUserData
 *               Callback function.  Returns a pointer to the new user data for the newly created marker.
 *               All properties for NewMarkerIndex have
 *               been set except for the user data.  You may call vsLineMarkerGet
 *               to query information about the new marker.
 *
 * @return Returns 0 if the marker type is valid.
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsMarkerTypeSetCallbackPasteUserData(
   int type,
   void * (VSAPI * pfnMarkerPasteUserData)(int NewMarkerIndex,int SrcBMIndex, int SrcType,const void *pSrcClipboardUserData)
   );
/**
 * Sets the FreeUserData callback for the marker type specified.  You may need to
 * define this callback if you want support for Undo or Copy/Paste.
 *
 * <p>This callback is called just before a marker is about to
 * be deleted including when you call vsLineMarkerRemove.  Free your user data here if necessary.
 * Do not free the user data in the
 * vsMarkerTypeSetCallbackLinesDeleted() callback if you
 * free the user data here.
 *
 * @param type                Type returned from vsMarkerTypeAlloc()
 * @param pfnMarkerFreeUserData  Callback function.
 *
 * @return Returns 0 if the marker type is valid.
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsMarkerTypeSetCallbackFreeUserData(
   int type,
   void (VSAPI * pfnMarkerFreeUserData)(int MarkerIndex, int BMIndex,int Type,void *pUserData,int BufId)
   );

/**
 * Sets the PasteIntoLine callback for the marker type specified. You will almost
 * always need to define this callback when setting the VSMARKERTYPEFLAG_COPY_CHAR_LINE_SELECT
 * flag on the marker type in order to allow you to decide whether the marker that
 * was copied with the contents of a line should be pasted into the line
 * specified in the edit window specified.
 *
 * <p>
 * This callback is called when a marker will be created due to
 * a Paste/Copy-to-Clipboard or Buffer-to-Buffer-Copy AND the marker type
 * contains VSMARKERTYPEFLAG_COPYPASTE | VSMARKERTYPEFLAG_COPY_CHAR_LINE_SELECT.
 * </p>
 *
 * <p>
 * Note:<br>
 * Currently our copy/paste facility is performed by Buffer-to-Buffer-Copy
 * because the SlickEdit clipboard is a buffer.
 * </p>
 *
 * @param type   Type returned from vsMarkerTypeAlloc()
 * @param pfnMarkerPasteIntoLine
 *               Callback function. DestWid is the window id that the marker would
 *               be pasted to. SrcMarkerIndex is the source marker that would be copied
 *               and used to create a new marker.
 *               SrcType is the type of the marker that would be copied. The line
 *               and column at which the marker would be pasted is set upon entry
 *               into this callback. Return 0 if you DO NOT want the marker
 *               pasted into the line, return 1 if you DO want the marker
 *               pasted into the line. All properties for NewMarkerIndex have
 *               been set (except for the user data).  You may call vsLineMarkerGet
 *               to query information about the new marker.
 *
 * @return Returns 0 if the marker type is valid.
 *
 * @example
 * <pre>
 * ...
 * int VSAPI myCallbackMarkerPasteIntoLine(int DestWid, int SrcMarkerIndex, int SrcType);
 * int type = vsMarkerTypeAlloc();
 * vsMarkerTypeSetFlags(type,VSMARKERTYPEFLAG_COPYPASTE|VSMARKERTYPEFLAG_UNDO|VSMARKERTYPEFLAG_AUTO_REMOVE|VSMARKERTYPEFLAG_COPY_CHAR_LINE_SELECT);
 * vsMarkerTypeSetCallbackPasteIntoLine(type,myCallbackMarkerPasteIntoLine);
 * ...
 * int VSAPI myCallbackMarkerPasteIntoLine(int DestWid, int SrcMarkerIndex, int SrcType)
 * {
 *     // Current column we are pasting into
 *     int p_col = vsPropGetI(DestWid,VSP_COL);
 *     // Current line number we are pasting into
 *     VSINT64 p_line = vsPropGetI64(DestWid,VSP_LINE);
 *     // Current line length (excluding newline chars) we are pasting into
 *     int line_len = vsQLineLength(DestWid,0);
 *
 *     // TODO:
 *     // Decide whether to allow this paste or not.
 *     // Return 0 if you DO NOT want to perform the paste.
 *     // Return 1 if you DO want to perform the paste.
 *
 *     // Allow the marker to be pasted
 *     return 1;
 * }
 * </pre>
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsMarkerTypeSetCallbackPasteIntoLine(
   int type,
   int (VSAPI * pfnMarkerPasteIntoLine)(int DestWid, int SrcMarkerIndex, int SrcType)
   );

struct VSLINEMARKERLISTITEM {
   int LineMarkerIndex;
   seSeekPos LineNum;
   seSeekPos NofLines;
   int BMIndex;
   int type;
   int MousePointer;
   int RGBBoxColor;
   VSCOLORINDEX ColorIndex;
   char *pszMessage;
   void *pUserData;
};

/*
   When on, indicates that this marker should be removed when the
   area size is zero.
*/
#define VSMARKERTYPEFLAG_AUTO_REMOVE       0x10

/*
   When on, a box is draw around the text contained in the
   marker.  For line markers, the number of lines contained
   in the box is determined by the
   <i>NofLines</i> property of the line marker.
*/
#define VSMARKERTYPEFLAG_DRAW_BOX          0x20

/*
   When on, markers will be undone.  If you have user data, you may need to
   implement the vsMarkerTypeSetCallbackCopyUserData(), vsMarkerTypeSetCallbackPasteUserData(),
   and vsMarkerTypeSetCallbackFreeUserData() callbacks.

   NOTE:  Undo does not support line markers that use a markid.
*/
#define VSMARKERTYPEFLAG_UNDO              0x40
/*
   When on, markers will be copied.  If you have user data, you may need to
   implement the vsMarkerTypeSetCallbackCopyUserData(), vsMarkerTypeSetCallbackPasteUserData(),
   and vsMarkerTypeSetCallbackFreeUserData() callbacks.  Our current implementation
   does not require that the vsMarkerTypeSetCallbackCopyUserData() be defined but we
   may changed our implementation.

   This flag is not supported by stream markers.

   IMPORTANT:  Copy/Paste does not support line markers that use a markid.
*/
#define VSMARKERTYPEFLAG_COPYPASTE         0x80

/**
 * Has no effect unless VSMARKERTYPEFLAG_COPYPASTE is also set for the marker type.
 *
 * <p>
 * When set, markers on lines where the entire line's contents is selected with a
 * CHAR/STREAM selection will be copied. If you have user data, you may need to
 * implement the vsMarkerTypeSetCallbackCopyUserData, vsMarkerTypeSetCallbackPasteUserData,
 * and vsMarkerTypeSetCallbackFreeUserData callbacks.  Our current implementation
 * does not require that the vsMarkerTypeSetCallbackCopyUserData be defined but we
 * may change our implementation.
 * </p>
 *
 * <p>
 * markers will always be pasted when pasting into a line, unless you delegate
 * the decision to a callback set with vsMarkerTypeSetCallbackPasteIntoLine.
 * It is almost always a mistake to set this flag on a marker type without also
 * setting a callback with vsMarkerTypeSetCallbackPasteIntoLine.
 * </p>
 *
 * <p>This flag is not supported by stream markers.</p>
 * <p>
 * IMPORTANT: Copy/Paste does not support line markers that use a markid.
 * </p>
 */
#define VSMARKERTYPEFLAG_COPY_CHAR_LINE_SELECT 0x100

/*
   When on, a focus rect should be draw around the lines contained in this
   area.  You can also have a bitmap displayed on the first line of the selection.
   This flag only supported by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_FOCUS_RECT        0x200

/*
   When on, indicates that no decoration should be drawn under the
   characters contained in this area.  You can still have a bitmap
   displayed on the first line of the selection.
   This flag only supported by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_SQUIGGLY             0x400

/*
   When on, a vertical line is drawn to the left of the text
   contained in the marker.  You can still have a bitmap
   displayed on the first line of the selection.
   The flag may be combined with VSMARKERTYPEFLAG_DRAW_LINE_RIGHT.
   This flag only supported by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_LINE_LEFT            0x800

/*
   When on, a vertical line is drawn to the right of the text
   contained in the marker.  You can still have a bitmap
   displayed on the first line of the selection.
   The flag may be combined with VSMARKERTYPEFLAG_DRAW_LINE_LEFT.
   This flag only supported by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_LINE_RIGHT           0x1000

/*
   When on, a vertical squiggly line is drawn to the left of the text
   contained in the marker.  You can still have a bitmap
   displayed on the first line of the selection.
   The flag may be combined with VSMARKERTYPEFLAG_DRAW_SQUIGGLY_RIGHT.
   This flag only supported by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_SQUIGGLY_LEFT        0x2000

/*
   When on, a vertical squiggly line is drawn to the right of the text
   contained in the marker.  You can still have a bitmap
   displayed on the first line of the selection.
   The flag may be combined with VSMARKERTYPEFLAG_DRAW_SQUIGGLY_LEFT.
   This flag only supported by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_SQUIGGLY_RIGHT       0x4000

/*
   When on, a filled triangle pointing down is drawn at the top and to the
   left of the text contained in the marker.  You can still have a bitmap
   displayed on the first line of the selection. The flag may be combined
   with VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT, or with
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT,
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT, and
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT. This flag is only
   supported by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT     0x10000

/*
   When on, a filled triangle pointing down is drawn at the top and to the
   left of the text contained in the marker.  You can still have a bitmap
   displayed on the first line of the selection. The flag may be combined
   with VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT, or with
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT,
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT, and
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT. This flag is only
   supported by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT  0x20000

/*
   When on, a filled triangle pointing down is drawn at the top and to the
   right of the text contained in the marker.  You can still have a bitmap
   displayed on the first line of the selection. The flag may be combined
   with VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT, or with
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT,
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT, and
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT. This flag is only supported
   by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT    0x40000

/*
   When on, a filled triangle pointing down is drawn at the top and to the
   left of the text contained in the marker.  You can still have a bitmap
   displayed on the first line of the selection. The flag may be combined
   with VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT, or with
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT,
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT, and
   VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT. This flag is only
   supported by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT 0x80000

/*
   When on, a mark appears next to the scrolll bar to show where in the file
   the mark occurs.
 
   This flag is only supported by stream markers.
*/
#define VSMARKERTYPEFLAG_DRAW_SCROLL_BAR_MARKER     0x100000
#define VSMARKERTYPEFLAG_COLOR_IS_RGB               0x200000

/**
 * Sets the marker type flags for the marker type specified.
 *
 * @param type	Index of marker type.
 *
 * @param MarkerTypeFlags	Marker flags may be one or more of the VSMARKERTYPEFLAG_* flags.
 * See flags for details.
 *
 * <dl>
 * <dt>VSMARKERTYPEFLAG_AUTO_REMOVE</dt><dd>
 * Specifies that the marker be removed when
 * all marker text is deleted.</dd>
 * <dt>VSMARKERTYPEFLAG_DRAW_BOX</dt><dd>
 * Specifies that a box be drawn around
 * the text.  For line markers, the number of lines contained
 * in the box is determined by the
 * <i>NofLines</i> property of the line marker.
 * </dd>
 * <dt>VSMARKERTYPEFLAG_DRAW_FOCUS_RECT</dt><dd>
 * Specifies that a focus rectangle be drawn around
 * the text.  For line markers, the number of lines contained
 * in the box is determined by the
 * <i>NofLines</i> property of the line marker.
 * </dd>
 * <dt>VSMARKERTYPEFLAG_DRAW_SQUIGGLY</dt><dd>
 * Specifies that a squiggly underline be drawn under
 * the text.  For line markers, the number of lines contained
 * in the box is determined by the
 * <i>NofLines</i> property of the line marker.
 * <dt>VSMARKERTYPEFLAG_DRAW_SCROLL_BAR_MARKER</dt><dd>
 * </dd>

 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 *
 */
void VSAPI vsMarkerTypeSetFlags(int type,int MarkerTypeFlags);

/**
 * Sets the marker type color index for the marker type 
 * specified. Currently only supported by stream markers with 
 * VSMARKERTYPEFLAG_DRAW_SCROLL_BAR_MARKER flag. 
 *
 * @param type	Index of marker type.
 *
 * @param ColorIndex	Color index to use for markers of type 
 *                   <B>type</B>.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsMarkerTypeSetColorIndex(int type,int ColorIndex);

/**
 * Sets the marker type color RGB for the marker type specified.
 * Currently only supported by stream markers with 
 * VSMARKERTYPEFLAG_DRAW_SCROLL_BAR_MARKER flag. 
 *
 * @param type	Index of marker type.
 *
 * @param ColorIndex SlickEdit RGB Color for <B>type</B>. 
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsMarkerTypeSetColorRGB(int type,int ColorRGB);

/**
 * Sets the drawing priority for the marker type specified.
 * 0 is the highest priority, 255 is the lowest priority.
 *
 * @param type	Index of marker type.
 * @param DrawPriority  unsigned integer between 0 and 255.
 *                      0 is the default draw priority.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 *
 */
void VSAPI vsMarkerTypeSetPriority(int type,int DrawPriority);

/**
 * Lists line markers
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 * @param wid        Window id of editor control.  0 specifies the
 *                   current object.
 * @param LineNum    Line number returned by
 *                   vsPropGetI64(wid,VSP_LINE)
 * @param LineOffset Optional specifies offset to search for markers
 *                   which use MarkIds.
 * @param CheckNofLines
 *                   When on, only line markers with NofLines which
 *                   include this line are returned.
 * @param pNofItems  May be null.  Set to number of items in array returned.
 *
 * @return Returns list of line markers indexes which match the line (or lines if
 *         <i>CheckRange</i> is non-zero) specified.  -1 is appended to the end of the list
 *         to indicate the end of the list.  0 is returned if no matches are found.
 *         Call vsFree to free the list.
 */
int *VSAPI vsLineMarkerAllocFindList(int wid,seSeekPos LineNum,seSeekPos LineOffset=(seSeekPos)VSNULLSEEK,int CheckNofLines=0,int *pNofItems=0);


/**
 * Lists stream markers
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 * @param wid       Window id of editor control.  0 specifies the
 *                  current object.
 * @param pNofItems (output only, optional) Set to number of items in list.
 * @param StartOffset
 *                  Stream markers that intersect with StartOffset,StartOffset+Length are listed.
 * @param Length    Stream markers that intersect with StartOffset,StartOffset+Length are listed.
 * @param SearchStartOffset
 *                  For performance reasons, only Stream markers that start after
 *                  SearchStartOffset are listed. By default, StartOffset-8000 is used.
 *                  If performance is not a problem, you can
 *                  specify 0. However, if there are 1 million stream markers, then each call
 *                  requires 1 million stream markers to be checked and this can be SLOW.  This optimization works
 *                  well since it is reasonable to assume that this is less than one stream marker
 *                  per byte in the file.
 * @param type
 * @param internalStartBlockP1  Editor block+1 or 0 to indicate
 *     null.  This is offset by one for backward compatibility.
 *
 * @return Returns list of stream markers indexes that intersect with StartOffset,StartOffset+Length.
 *         -1 is appended to the end of the list to indicate the end of the list.  0 is returned if no matches are found.
 *         Call vsFree to free the list.
 */
int *VSAPI vsStreamMarkerAllocFindList(int wid,int *pNofItems,seSeekPos StartOffset,seSeekPos Length,seSeekPos SearchStartOffset=(seSeekPos)VSNULLSEEK,int type=0,int internalStartBlock=-1,seSeekPos internalStartBlockPos_l=(seSeekPos)0);
/**
 * @return Order of bitmap.  Lowest order is displayed on top.
 *
 * @param BMIndex	Index of bitmap in names table.
 *
 * @see vsPicSetOrder
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsPicGetOrder(int BMIndex);
/**
 * Interates all line markers.  Using this function could
 * cause slow performance since this function list all line markers
 * and not just line markers for a specific buffer.
 *
 * @param LineMarkerIndex  Specify -1 or the last value returned by this function.
 *
 * @return Returns index of next line marker.  Returns -1 if there are no more line markers.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 */
int VSAPI vsLineMarkerNext(int LineMarkerIndex);
/**
 * Removes line marker.
 *
 * @param LineMarkerIndex	Index of line marker returned by a vsLineMarkerAdd
 * function.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsLineMarkerRemove(int LineMarkerIndex);
/**
 * Removes stream marker.
 *
 * @param StreamMarkerIndex	Index of stream marker returned by a vsStreamMarkerAdd
 * function.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsStreamMarkerRemove(int StreamMarkerIndex);
/**
 * Removes all line markers that have the specified BMIndex.
 *
 * @param BMIndex	Index of bitmap in names table.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsLineMarkerRemoveAllBMIndex(int BMIndex);

/**
 * Removes all stream markers that have the specified BMIndex.
 *
 * @param BMIndex	Index of bitmap in names table.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsStreamMarkerRemoveAllBMIndex(int BMIndex);

/**
 * Removes all line markers that have the specified type.
 *
 * @param type	Type of marker.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsLineMarkerRemoveAllType(int type);
/**
 * Removes all stream markers that have the specified type.
 *
 * @param type	Type of marker
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsStreamMarkerRemoveAllType(int type);
/**
 * Removes all line markers for the specified editor control that have the
 * specified BMIndex.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param BMIndex	Index of bitmap in names table.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsLineMarkerRemoveBMIndex(int wid,int BMIndex);
/**
 * Removes all line markers for the specified editor control that have the
 * specified type.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param type	Type of marker.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsLineMarkerRemoveType(int wid,int type);
/**
 * Removes all line markers for the specified editor control that have the
 * specified type and are not pushed bookmarks.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param type	Type of marker.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsLineMarkerRemoveNonPushedType(int wid,int type);

/**
 * Removes all stream markers for the specified editor control that have the
 * specified type.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param type	Type of marker.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 * @return int Number of markers removed 
 *
 */
int VSAPI vsStreamMarkerRemoveType(int wid,int type);
/**
 * Sets the bitmap for the line marker specified.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 * @param LineMarkerIndex
 *                Index of line marker returned by a vsLineMarkerAdd
 *                function.
 * @param BMIndex Index of bitmap in names table.
 */
void VSAPI vsLineMarkerSetBMIndex(int LineMarkerIndex,int BMIndex);
/**
 * Sets the order for the bitmap specified.
 *
 * @param BMIndex	Index of bitmap in names table.
 *
 * @param Order	Index of bitmap in names table.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsPicSetOrder(int BMIndex,int order,int OnlySetIfZero VSDEFAULT(0));
/**
 * Sets the userdata for the line marker specified.
 *
 * @param LineMarkerIndex	Index of line marker returned by a vsLineMarkerAdd
 * function.
 *
 * @param pUserData	Pointer to user data.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
int VSAPI vsLineMarkerSetUserData(int LineMarkerIndex,void *pUserData);

/**
 * Sets the RBG box color line marker specified.
 *
 * @param LineMarkerIndex	Index of line marker returned by a vsLineMarkerAdd function.
 *
 * @param RGBColor	RGB color.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsLineMarkerSetStyleColor(int LineMarkerIndex,int RGBColor);

/**
 * Sets the RBG box color or squiggly line color for the stream marker specified..
 *
 * @param StreamMarkerIndex	Index of stream marker returned by a vsStreamMarkerAdd function.
 *
 * @param RGBColor	RGB color
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsStreamMarkerSetStyleColor(int StreamMarkerIndex,int RGBColor);

/**
 *
 * @param StreamMarkerIndex      Index of stream marker returned by a vsStreamMarkerAdd function.
 * @param Length        Replace StartOffset of this stream marker with the
 *                      StartOffset
 *
 * @return 0 if stream marker index is valid.
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsStreamMarkerSetUserData(int StreamMarkerIndex, void* pUserData);

/**
 *
 * @param StreamMarkerIndex      Index of stream marker returned by a vsStreamMarkerAdd function.
 * @param Length        Replace Length of this stream marker with the new Length
 *
 * @return 0 if stream marker index is valid.
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsStreamMarkerSetLength(int StreamMarkerIndex,seSeekPosParam Length);

/**
 *
 * @param StreamMarkerIndex      Index of stream marker returned by a vsStreamMarkerAdd function.
 * @param Length        Replace StartOffset of this stream marker with the
 *                      StartOffset
 *
 * @return 0 if stream marker index is valid.
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsStreamMarkerSetStartOffset(int StreamMarkerIndex, seSeekPosParam StartOffset);

/**
 *
 * @param StreamMarkerIndex      Index of stream marker returned by a vsStreamMarkerAdd function.
 * @param pszMessage             Replace marker type.
 *
 * @return 0 if stream marker index is valid.
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsStreamMarkerSetType(int StreamMarkerIndex, int type);

/**
 *
 * @param StreamMarkerIndex      Index of stream marker returned by a vsStreamMarkerAdd function.
 * @param pszMessage             Replace message.
 *
 * @return 0 if stream marker index is valid.
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsStreamMarkerSetMessage(int StreamMarkerIndex, const char *pszMessage);

/**
 * Sets the color index for the text in the stream marker specified.
 *
 * @param StreamMarkerIndex   Index of stream marker returned by a vsStreamMarkerAdd function.
 * @param ColorIndex   Index of color allocated by {@link vsAllocColor}().  Specify 0 for no color (null).
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
void VSAPI vsStreamMarkerSetTextColor(int StreamMarkerIndex,VSCOLORINDEX ColorIndex,int reserved=0);

// Mouse pointers.
// Valid built-in and resource pointers: -128..0
// Valid run-time (user-set) pointers: 1-127 index from gMousePointer[] table
// Built-in
#define VSMP_DEFAULT    0
#define VSMP_ARROW      -1
#define VSMP_CROSS      -2
#define VSMP_IBEAM      -3
#define VSMP_ICON       -4
#define VSMP_SIZE       -5
#define VSMP_SIZENESW   -6
#define VSMP_SIZENS     -7
#define VSMP_SIZENWSE   -8
#define VSMP_SIZEWE     -9
#define VSMP_UP_ARROW   -10
#define VSMP_HOUR_GLASS -11
#define VSMP_BUSY       -12
#define VSMP_SIZEHORZ   -13
#define VSMP_SIZEVERT   -14
#define VSMP_HAND       -15
#define VSMP_NODROP     -16
#define VSMP_SPLITVERT  -17
#define VSMP_SPLITHORZ  -18
// Resource
#define VSMP_LISTBOXBUTTONSIZE     -118
#define VSMP_ALLOWCOPY             -119
#define VSMP_ALLOWDROP             -120
#define VSMP_LEFTARROW_DROP_TOP    -121
#define VSMP_LEFTARROW_DROP_BOTTOM -122
#define VSMP_LEFTARROW_DROP_RIGHT  -123
#define VSMP_LEFTARROW_DROP_LEFT   -124
#define VSMP_LEFTARROW             -125
#define VSMP_RIGHTARROW            -126
#define VSMP_MOVETEXT              -127
#define VSMP_MAX       (VSMP_MOVETEXT)
// Custom cursor (e.g. user set picture index).
// It is illegal for the user to set this value.
#define VSMP_CUSTOM    -128

/**
 * Sets the mouse pointer for the line marker specified.
 *
 * @param LineMarkerIndex	Index of line marker returned by a vsLineMarkerAdd
 * function.
 *
 * @param MousePointer	Index to mouse pointer.  One of VSMP_*
 * constants.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions, Mouse_Functions
 *
 */
void VSAPI vsLineMarkerSetMousePointer(int LineMarkerIndex,int MousePointer);

/**
 * Sets the mouse pointer for the stream marker specified.
 *
 * @param StreamMarkerIndex	Index of stream marker returned by a vsStreamMarkerAdd
 * function.
 *
 * @param MousePointer	Index to mouse pointer.  One of VSMP_*
 * constants.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions, Mouse_Functions
 *
 */
void VSAPI vsStreamMarkerSetMousePointer(int StreamMarkerIndex,int MousePointer);

/**
 * Allocate a type for scroll bar markers
 * 
 * @return int New marker type
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsScrollMarkupAllocType();

/**
 * Set the color for a type of scroll bar markers
 * 
 * @param wid Window ID of editor control 
 * @param iType Type returned by <B>vsScrollMarkupAllocType</B> 
 * @param iColorInfo a SlickEdit color index, or an RGB color. 
 *                   If this is an RGB color - be sure
 *                   <B>isRGB</B> is 1.
 * @param iIsRGB If true, iColorInfo is an RGB color.
 * 
 * @return int 0 if successful
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsScrollMarkupSetTypeColor(int iType,int iColorInfo,int iIsRGB VSDEFAULT(0));

/**
 * Add a scroll bar mark
 * 
 * @param wid Window ID of editor control 
 * @param iLineNum Line number to put mark on 
 * @param iType Type returned by <B>vsScrollMarkupAllocType</B> 
 * @param iLength Number of lines in this mark, defaults to 1
 * 
 * @return int 0 if successful
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
int VSAPI vsScrollMarkupAdd(int wid,seSeekPos iLineNum,int iType,seSeekPos iLength= seSeekPos(1));
int VSAPI vsScrollMarkupAddOffset(int wid,seSeekPos offset,int iType,seSeekPos iLength= seSeekPos(1));

/**
 * Remove a scroll bar mark
 * 
 * @param wid Window ID of editor control 
 * @param iScrollMarkupIndex Index of marker to remove
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsScrollMarkupRemove(int wid,int iScrollMarkupIndex);

/**
 * Remove all scroll bar marks of a specified type for the 
 * specified window 
 * 
 * @param wid Window ID of editor control 
 * @param iType Type returned by <B>vsScrollMarkupAllocType</B> 
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsScrollMarkupRemoveType(int wid,int iType);

/**
 * Remove all scroll bar marks of a specified type. 
 *  
 * @param iType to remove
 * 
 * @return void
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsScrollMarkupRemoveAllType(int iType);

/**
 * Update scroll markup information for all child windows
 *  
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsScrollMarkupUpdateAllModels();
/** 
 * Associate a standalone scrollbar with an editor control - 
 * this is only for the purposes of markup, it will not handle 
 * the actual scrolling. 
 *  
 * Currently only supports vertical scrollbars 
 * 
 * @param wid Window ID of scrollbar
 * @param iAssociatedWID Window ID of the editor control to 
 *                       associate.
 * 
 * @return void
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
void VSAPI vsScrollMarkupSetAssociatedEditor(int wid,int iAssociatedWID);
void VSAPI vsScrollMarkupUnassociateEditor(int iScrollBarWID,int iAssociatedEditorWID);


struct VSSCROLLBAR_MARKUP_INFO {
   seSeekPos iLineNumber;
   seSeekPos iLineLength;
   seSeekPos offset;
   seSeekPos iByteLength;
   int iType;
   int iHandle;
   VSSCROLLBAR_MARKUP_INFO *pNext;
};
void VSAPI vsScrollMarkupGetMarkup(int iWID,slickedit::SEArray<VSSCROLLBAR_MARKUP_INFO> &markupInfo,
                                   seSeekPos startOffset=seSeekPos(0),
                                   seSeekPos endOffset= seSeekPos(-1));

/**
 * Invalidates the entire client are of the window and queues a paint message
 *
 * @param wid    Window id of editor control.  0 specifies the current object.
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
void vsInvalidateWindow(int wid);
/**
 * Immediately redraws all non-client area decorations.  On Unix, Shell
 * window decorations are not redrawn.
 *
 * @param wid    Window id of editor control.  0 specifies the current object.
 *
 * @appliesTo All_Window_Objects
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
void vsRedrawFrame(int wid);


// p_modify and p_ModifyFlags
#define VSMODIFYFLAG_MODIFIED                0x000001 // Indicated buffer is modifyed (p_modify==1)
#define VSMODIFYFLAG_AUTOSAVE_DONE           0x000002 // auto save of buffer happened
#define VSMODIFYFLAG_DELPHI                  0x000004 // ?
#define VSMODIFYFLAG_TAGGED                  0x000008 // buffer has been re-tagged
#define VSMODIFYFLAG_PROCTREE_UPDATED        0x000010 // Defs tool window updated
#define VSMODIFYFLAG_CONTEXT_UPDATED         0x000020 // Symbols updated
#define VSMODIFYFLAG_LOCALS_UPDATED          0x000040 // Local variables updated
#define VSMODIFYFLAG_FCTHELP_UPDATED         0x000080 // Function help updated
#define VSMODIFYFLAG_TAGWIN_UPDATED          0x000100 // Preview window updated
#define VSMODIFYFLAG_CONTEXTWIN_UPDATED      0x000200 // Context window updated
#define VSMODIFYFLAG_FTP_NEED_TO_SAVE        0x000400 // Need to save FTP buffer
#define VSMODIFYFLAG_AUTOEXT_UPDATED         0x000800 // ?
#define VSMODIFYFLAG_PROCTREE_SELECTED       0x001000 // Defs tool window selected item
#define VSMODIFYFLAG_LC_UPDATED              0x002000 // Line commands updated
#define VSMODIFYFLAG_XMLTREE_UPDATED         0x004000 // XML tree updated
#define VSMODIFYFLAG_JGUI_UPDATED            0x008000 // Indicates that Java GUI Builder has buffer contents
#define VSMODIFYFLAG_STATEMENTS_UPDATED      0x010000 // Statement tagging updated
#define VSMODIFYFLAG_AUTO_COMPLETE_UPDATED   0x020000 // Auto-complete up-to-date
#define VSMODIFYFLAG_CLASS_UPDATED           0x040000 // Class tool window updated
#define VSMODIFYFLAG_CLASS_SELECTED          0x080000 // Class tool window selected item
#define VSMODIFYFLAG_BGRETAG_THREADED        0x100000 // Background tagging started on thread
#define VSMODIFYFLAG_CONTEXT_THREADED        0x200000 // Context update started on thread
#define VSMODIFYFLAG_LOCALS_THREADED         0x400000 // Local variable tagging started on thread
#define VSMODIFYFLAG_STATEMENTS_THREADED     0x800000 // Statement tagging started on thread
#define VSMODIFYFLAG_SYMBOL_COLORING_RESET   0x1000000
#define VSMODIFYFLAG_SCROLL_MARKER_UPDATED   0x2000000
#define VSMODIFYFLAG_TOKENLIST_UPDATED       0x4000000


#if defined(__GTK_H__)
Window VSAPI vsGTKGetWindow(GtkWidget * widget);
Display * VSAPI vsGTKGetDisplay();
#endif

/**
 * Prepairs a buffer for threading.  The currently implementation
 * forces the buffer data and undo data to be resident
 * in memory.  This implementation allows for multiple reads
 * to occur without any blocking.
 *
 * @param wid       Window id of the editor control.
 * @param reserved1
 * @param reserved2
 */
void VSAPI vsThreadEditorCtlOpen(int wid,int reserved1, void *reserved2);


void VSAPI vsDoscRegisterCommentFormattingCallbackbTest(void);

int VSAPI vsLicenseType();
void VSAPI vsLicenseTypeSet(int value);
int VSAPI vsLicenseUsers();
void VSAPI vsLicenseUsersSet(int value);
int VSAPI vsOEM();
//EXTERN_C int VSAPI vsFlexlm();
VSPSZ VSAPI vsLicenseExpiration();
int VSAPI vsLicenseExpirationInDays();
VSPSZ VSAPI vsSerialNumber();
VSPSZ VSAPI vsLicenseFile();
void VSAPI vsLicenseFileSet(VSPSZ value);
void VSAPI vsLicenseExpirationSet(VSPSZ value);
void VSAPI vsLicenseExpirationInDaysSet(int value);
int VSAPI vsTrial();
void VSAPI vsTrialSet(int value);
int VSAPI vsSubscription();
void VSAPI vsSubscriptionSet(int value);
void VSAPI vsSerialNumberSet(VSPSZ value);
VSPSZ VSAPI vsLicenseToInfo();

/**
 *
 * @param value  Must valid HTML which can be display in the
 *               SlickEdit minihtml control.
 */
void VSAPI vsLicenseToInfoSet(VSPSZ value);
/**
 * @param path Path to change to
 * @param iChangeDrive if 1 (default) , change current drive to
 *                     drive <B>path</B> specifies.
 *
 * @return int VSAPI 0 if successful
 */
int VSAPI vsChangeDir(VSPSZ pszPath,int iChangeDrive VSDEFAULT(1));

/**
 *
 * @param pszPath   Buffer to receive the current directory
 * @param iPathSize Size of pszPath buffer
 * @param iDrive Drive letter to get current directory for
 *               (Windows only)
 *
 * @return int VSAPI If iPathSize>0, returns 0 if successful.
 *         If iPathSize is 0, returns size required.
 */
int VSAPI vsGetCurDir(char *pszPath,int iPathSize VSDEFAULT(0),char drive VSDEFAULT(0),int iKeepSymLinks VSDEFAULT(1));

/**
 * Temporarily changes the current working directory and leaves
 * the value locked, such that nothing else can get or set the
 * current working directory.
 *
 * IMPORTANT - you must call vsPopDir to unlock the current
 * working directory so others can access it.
 *
 * @param newDir              new current working directory
 * @param origDir             (by-ref) old current working
 *                            directory, used to send to
 *                            SEPopDir so we can revert to our
 *                            previous state
 * @param changeDrive         if true (default), change current
 *                            drive to the drive specified by
 *                            <B>path</B>.
 *
 * @return int                0 if successful
 */
int VSAPI vsPushDir(VSPSZ pszNewPath, char *pszOrigPath, int iChangeDir VSDEFAULT(1));

/**
 * Reverts the current working directory back to its previous
 * state before a call to vsPushDir.  This releases the lock on
 * the current working directory.
 *
 * @param origDir             previous current working directory
 *                            that we wish to revert to
 *
 * @return int                0 if successful
 */
int VSAPI vsPopDir(const char *pszPath);

/**
 *
 * @param wid       Window id of the editor control.
 * @param iLineNumber Line in wid to tokenize
 * @param pLine Text for line <B>iLineNumber</B> is stored here
 * @param iLineLen Length of line <B>iLineNumber</B> is stored here
 * @param pTokens array of VSCFG_* constants, one for each
 *                character in line <B>iLineNumber</B>
 *
 * @return int 0 if successful
 */
EXTERN_C
int VSAPI vsClexGetLineColorIndexes(int wid/*,int iLineNumber*/,
                                    unsigned char* &pLine, int &iLineLen,
                                    VSCOLORINDEX *&pTokens);

enum vsClexSkipableTypes {
   VSCLEX_SKIP_NONE       = 0,
   VSCLEX_SKIP_EOL        = 0x1,
   VSCLEX_SKIP_WHITESPACE = 0x2,
   VSCLEX_SKIP_ALL_COMMENTS = 0x4
};
/**
 *
 * @param wid       Window id of the editor control.
 * @param pToken pointer to start of token in internal static
 *               buffer.  COPY THIS DATA IF YOU KEEP IT
 * @param iTokenLen Length of token
 * @param tokenSeekPos seek position of token in buffer
 * @param tokenColor VSCFG_* constant
 * @param bGetFirstToken Move to the start of the line before
 *                       grabbing token
 *
 * @return int 0 if successful
 */
EXTERN_C
int VSAPI vsClexGetNextToken(int wid,unsigned int &iTokenLen,
                             unsigned int &tokenSeekPos,VSCOLORINDEX &tokenColor,bool bGetFirstToken=false,
                             int skipFlags=0
                             );

EXTERN_C
int VSAPI vsCreateZipFile(VSPSZ pszFilename, VSHREFVAR files, VSHREFVAR zipStatus,VSHREFVAR archiveNames);


enum vsWatchedPathTypes {
   WATCHEDPATH_SVN        = 0x1,
   WATCHEDPATH_FILESYSTEM = 0x2,
   WATCHEDPATH_PERFORCE   = 0x4,
};

struct VSWATCHEDPATHINFO {
   slickedit::SEString path;
   slickedit::SEString watchedPath;
   slickedit::SEString VCServerStatus;
   slickedit::SEString VCLocalStatus;
   slickedit::SEString localDate;
   slickedit::SEString localAttrs;
   vsWatchedPathTypes changeType;
};

EXTERN_C
int VSAPI vsSetFileInfo(const slickedit::SEString &filename,
                        const VSWATCHEDPATHINFO &fileInfo);

/**
 * Call when done setting a batch of file info so signals are 
 * sent to treeviews 
 * 
 */
EXTERN_C
void VSAPI vsSetFileInfoDone();

EXTERN_C
int VSAPI vsGetFileInfo(const slickedit::SEString &filename,
                        VSWATCHEDPATHINFO &fileInfo);

EXTERN_C
void VSAPI vsGetUpdatedFileInfoList(slickedit::SEArray<VSWATCHEDPATHINFO> &fileList,bool clearFileList=true);

/**
 * Sets all files not in <B>fileList</B> back to default state
 * 
 * @param protectedFileList File list to keep in original state 
 */
EXTERN_C
void VSAPI vsResetFileStatuses(slickedit::SEArray<slickedit::SEString> &protectedFileList,const slickedit::SEString &type,const slickedit::SEString &value,bool bResetFilesNotInList VSDEFAULT(false));

/**
 * Get system time in the output buffer specified. If the output
 * buffer is null or maxlen=0, then the size required to store
 * the time string is returned.
 *
 * @param pszString  (out) Output buffer for system time string.
 * @param maxlen     Maximum number of characters in output
 *                   buffer.
 * @param option     May be one of the following:
 *
 * <dl>
 * <dt>'T'</dt><dd>Return time in the format <i>hh</i>:<i>mmcc</i>
 * where <i>hh</i> is an hour between 1 and 12, mm
 * is the minutes between 0 and 59, and <i>cc</i> is
 * the "am" or "pm".</dd>
 *
 * <dt>'B'</dt><dd>Return binary time in milliseconds.  This options is
 * used for comparing dates with the :< and :>
 * operators.</dd>
 *
 * <dt>'M'</dt><dd>24-hour (Military) time in the format
 * <i>hh</i>:<i>mm</i>:<i>ss</i> where <i>hh</i>
 * is an hour between 0 and 23, <i>mm</i> is the
 * minutes between 0 and 59, and <i>ss</i> is the
 * seconds between 0 and 59.</dd>
 *
 * <dt>'L'</dt><dd>Returns time in the current local format.  Under
 * Windows, this uses the regional settings "Time
 * style."  For other platforms, this has not yet been
 * defined.</dd>
 *
 * <dt>'F'</dt><dd>Return time in the format YYYYMMDDhhmmssfff
 * where <i>YYYY</i> is the year, <i>MM</i> is the month,
 * <i>DD</i> is the day, <i>hh</i> is an hour between 0 and 23,
 * <i>mm</i> is the minutes between 0 and 59, <i>ss</i> is the
 * seconds between 0 and 59, and <i>fff</i> is the fractional
 * second, in milliseconds.</dd>
 *
 * <dt>'G'</dt><dd>Returns seconds elapsed since UNIX Epoch
 * (Midnight of January 1, 1970). This value is always in
 * UTC/GMT.</dd>
 *
 * @return 0 on success, >0 size required to store time string
 *         if output buffer is null, otherwise <0 error code.
 *
 * @categories Miscellaneous_Functions
 */
EXTERN_C
int VSAPI vsGetTimeString(char* pszTime, int maxlen, char option VSDEFAULT('T'));

EXTERN_C_END

/**
 * Indicates whether if running in a timer callback.
 *
 * <p>This is useful to know since there are times where utility
 * functions used by timers need to be change there operation
 * for safety reasons when being called from a timer callback.
 *
 * @return Returns true if running in a timer callback.
 */
extern bool VSAPI vsInTimer();



   #define VSW_HIDE             0   //Make invisible
   #define VSW_NORMAL           1   // Don't know if this is like SW_RESTORE
   #define VSW_SHOWMINIMIZED    2
   #define VSW_SHOWMAXIMIZED    3
   #define VSW_SHOWNOACTIVATE   4
   #define VSW_SHOW             5   //Make visible
   #define VSW_RESTORE          9

// SEFilename2LangId flags
#define VSF2LI_NO_CHECK_OPEN_BUFFERS   0x1            // do not check for file in list of open buffers
#define VSF2LI_NO_CHECK_PERFILE_DATA   0x2            // do not check for data stored for previously-opened files

/**
 * Returns the language mode associated with the given file.
 *
 * @return Returns the language ID for the given file.
 *
 * @param file_name        source file name with path
 * @param options          one or more of the following flags ORed together:
 * <dl>
 * <dt>F2LI_NO_CHECK_OPEN_BUFFERS</dt><dd>Do not go through open buffers
 * to determine lang id.  Normally, we see if the file is already open
 * and then return its p_LangId property.  If this flag is included,
 * this step is skipped</dd>
 * </dl>
 */

/**
 * Array of options that's associated with a buffer.
 */
typedef slickedit::SEArray<slickedit::SEString> BeautifierOptionArray;

/**
 * @param editor_wid Editor control id.
 * 
 * @return BeautifierOptionArray* NULL if there's no beautifier 
 *         configuration associated with a buffer.
 */
EXTERN_C
BeautifierOptionArray* VSAPI vsGetBeautifierOptions(int editor_wid);

/**
 * Returns the language mode associated with the given file.
 *
 * The <b>Language Options dialog box</b> allows you to map an
 * extension that to a language mode.  This function performs
 * that translation, and will also use the buffer
 * name to determine the language mode.
 *
 * If the file's actual extension matches a
 * <code>_[ext]_Filename2LangId()</code> callback, it will first
 * try the callback to see if the file, based on it's path or name
 * should be referred to an alternate language.
 *
 * Otherwise, if the file's actual extension matches a
 * <code>suffix_[ext]</code> callback, it will open the file
 * in a temporary view and try the callback to determine the
 * file's actual language type.
 *
 * @return Returns the language ID for the given file.
 *
 * @param file_name        source file name with path
 * @param options          one or more of the following flags ORed together:
 * <dl>
 * <dt>F2LI_NO_CHECK_OPEN_BUFFERS</dt><dd>Do not go through open buffers
 * to determine lang id.  Normally, we see if the file is already open
 * and then return its p_LangId property.  If this flag is included,
 * this step is skipped</dd>
 * <dt>F2LI_NO_CHECK_PERFILE_DATA</dt><dd>Do not go through data saved
 * for previously opened files to determine lang id.  Normally, we check
 * the data stored in perfile.xml to see if this file has been opened
 * before and has a stored lang id.  If this flag is included, this step
 * is skipped</dd>
 * </dl>
 */
extern VSDLLEXPORT
slickedit::SEString SEFilename2LangId(const slickedit::SEString &filename, int flags = 0);


/** 
 * Converts the unique display name for a language to it's 
 * language ID (canonical file extension).  This 
 * function will only search your current language setup. 
 * It will not attempt to autoload additional language 
 * features. 
 * 
 * @param mode_name     Display name for language type 
 * 
 * @return The language ID for the language 
 *         corresponding to 'mode_name'. 
 *  
 * @see SELangId2Modename
 * @see SEFilename2LangId 
 */
extern VSDLLEXPORT
slickedit::SEString SEModenameToLangId(const slickedit::SEString &mode_name);

/** 
 * Converts a language ID (canonical file extension) to 
 * the unique display name for a language.
 * 
 * @param lang    Language ID (see {@link p_LangId} 
 * 
 * @return The mode name for the language.
 *  
 * @see SEModename2LangId 
 * @see SEFilename2LangId 
 */
extern VSDLLEXPORT
slickedit::SEString SELangIdToModename(const slickedit::SEString &lang);

/** 
 * Locates the first language specification that uses the 
 * given lexer name.  Note there is no guarantee that the 
 * mapping form lexer names to languages should be unique, 
 * so use this function sparingly, as it will *only* find 
 * the first match. 
 * 
 * @param lexer_name     Language lexer name 
 * 
 * @return The language ID for the language 
 *         corresponding to 'lexer_name'. 
 *  
 * @see SELangId2LexerName 
 * @see SEModename2LangId 
 * @see SEFilename2LangId 
 */
extern VSDLLEXPORT
slickedit::SEString SELexerNameToLangId(const slickedit::SEString &lexer_name);

/**
 * @return Return the name of the color coding lexer for the 
 *         given language ID. 
 * 
 * @param lang File language ID (see {@link p_LangId}).
 *  
 * @see SELexerNameToLangId 
 * @see SEModenameToLangId 
 * @see SEFilename2LangId 
 */
extern VSDLLEXPORT
slickedit::SEString SELangIdToLexerName(const slickedit::SEString &lang);


void registerInternalFilename2LangIdCallbacks();

#if VSWINDOWS
// registry functions (windows only)
slickedit::SEString regQueryValue(int root, const slickedit::SEString &subkey,
                                  const slickedit::SEString &valueName, const slickedit::SEString &defaultValue = "");
slickedit::SEString regGetLatestVersionValue(int root, const slickedit::SEString &subkey,
                                             const slickedit::SEString &suffixPath, const slickedit::SEString &valueName);
#endif

slickedit::SEString vsMacroPathSearch(const char * pName, int options = 0, int searchCurrentDir = 1, int findMacro = 0);

typedef slickedit::SEString (*ExtFilenameCallback)(const slickedit::SEString &filename);

typedef slickedit::SEString (*ExtFileContentsCallback)(const slickedit::SEString &buffer, int fileHandle, const slickedit::SEString &filename);

void VSAPI vsRegisterUserFilename2LangIdFilenameCallback(const slickedit::SEString &ext, ExtFilenameCallback pfn);

void VSAPI vsRegisterUserFilename2LangIdFileContentsCallback(const slickedit::SEString &ext, ExtFileContentsCallback pfn);

#endif
