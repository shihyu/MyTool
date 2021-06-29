////////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "slickedit/SEString.h"
#include <stddef.h>

#define HVAR   int
#define VSHVAR  int
#define VSHREFVAR VSHVAR
#define VSHREFINT VSHREFVAR
#define VSHREFSTR VSHREFVAR
//typedef void *VSPVOID;
//typedef char *VSPSZ;

#define VSPVOID void *
#define VSPSZ const char *
#define SEStringConst const slickedit::SEString &
#define SEStringByRef slickedit::SEString &
#define SEStringRet   slickedit::SEString

EXTERN_C_BEGIN
#define VSHVAR_RC    1
#define VSHVAR_DOT   2

/**
 * Types of arguments passed to {@link vsCallIndex}.
 * <ul> 
 * <li>VSARGTYPE_INT          -- (pass by value) 'int', 32-bit integer</li>
 * <li>VSARGTYPE_LONG         -- (pass by value) 'long', C/C++ long integer</li>
 * <li>VSARGTYPE_HREFVAR      -- (pass by value) 'VSHREFVAR', Slick-C reference variable</li>
 * <li>VSARGTYPE_PSZ          -- (pass by value) 'const char*', null-teriminated character string</li>
 * <li>VSARGTYPE_PLSTR        -- (pass by value) 'VSPLSTR', character string with length prefix</li>
 * <li>VSARGTYPE_HVAR         -- (pass by value) 'VSHVAR', Slick-C variable</li>
 * <li>VSARGTYPE_BUF          -- (pass by value) 'VSBUFARG', binary data buffer</li>
 * <li>VSARGTYPE_EMPTY        -- (pass by value) unitialized Slick-C container</li>
 * <li>VSARGTYPE_INT64        -- (pass by value) 'VSINT64', 64-bit integer</li>
 * <li>VSARGTYPE_CMSTRING     -- (pass by value) 'cmStringUtf8', internal string class type</li>
 * <li>VSARGTYPE_SESTRING     -- (pass by value) 'SEString', public string class type</li>
 * <li>VSARGTYPE_SIZE_T       -- (pass by value) 'size_t', unsigned C++ size type</li>
 * <li>VSARGTYPE_BOOL         -- (pass by value) 'bool', boolean true or false type</li>
 * <li>VSARGTYPE_REF_BOOL     -- (pass by reference) 'bool *', boolean true or false type</li>
 * <li>VSARGTYPE_REF_INT      -- (pass by reference) 'int *', 32-bit integer</li>
 * <li>VSARGTYPE_REF_LONG     -- (pass by reference) 'long *', C/C++ long integer</li>
 * <li>VSARGTYPE_REF_INT64    -- (pass by reference) 'VSINT64 *', 64-bit integer</li>
 * <li>VSARGTYPE_REF_SIZE_T   -- (pass by reference) 'size_t *', unsigned C++ size type</li>
 * <li>VSARGTYPE_REF_CMSTRING -- (pass by reference) 'cmStringUtf8 *', internal string class type</li>
 * <li>VSARGTYPE_REF_SESTRING -- (pass by reference) 'SEString*', public string class type</li>
 * <li>VSARGTYPE_REF_EMPTY    -- (pass by reference) unitialized Slick-C container</li>
 * </ul>
 *  
 * @see VSARGTYPE 
 * @see VSBUFARG
 * @see vsCallIndex 
 * @see vsHvarCallMethod
 * @see vsHvarCallMethodByName
 * @see vsHvarConstruct 
 * @see vsCallPtr 
 * @see vsLoadTemplate
 *  
 * @categories Miscellaneous_Functions
 */
enum VSArgTypeKind : unsigned int {
   // pass by value arguments
   VSARGTYPE_INT      = 0,
   VSARGTYPE_LONG     = 1,
   VSARGTYPE_HREFVAR  = 2,
   VSARGTYPE_PSZ      = 3,
   VSARGTYPE_PLSTR    = 4,
   VSARGTYPE_HVAR     = 5,
   VSARGTYPE_BUF      = 6,
   VSARGTYPE_EMPTY    = 7,
   VSARGTYPE_INT64    = 8,
   VSARGTYPE_CMSTRING = 9,
   VSARGTYPE_SESTRING = 10,
   VSARGTYPE_SIZE_T   = 11,
   VSARGTYPE_DOUBLE   = 12,
   VSARGTYPE_BOOL     = 13,

   // pass by reference types
   VSARGTYPE_REF_BOOL     = 16,
   VSARGTYPE_REF_INT      = 17,
   VSARGTYPE_REF_LONG     = 18,
   VSARGTYPE_REF_INT64    = 19,
   VSARGTYPE_REF_SIZE_T   = 20,
   VSARGTYPE_REF_DOUBLE   = 21,
   VSARGTYPE_REF_CMSTRING = 22,
   VSARGTYPE_REF_SESTRING = 23,
   VSARGTYPE_REF_EMPTY    = 24,
};

/**
 * Argument type for binary data.
 *  
 * @see vsCallIndex 
 * @see vsHvarCallMethod
 * @see vsHvarCallMethodByName
 * @see vsHvarConstruct 
 * @see vsCallPtr 
 * @see vsLoadTemplate
 * @see vsFindIndex 
 * @see VSArgTypeKind 
 *  
 * @categories Miscellaneous_Functions
 */
struct VSBUFARG {
   int BufLen;
   const char *pBuf;
};

/**
 * Argument type for array of arguments passed to {@link vsCallIndex}.
 *  
 * @see VSArgTypeKind 
 * @see VSBUFARG
 * @see vsCallIndex 
 * @see vsHvarCallMethod
 * @see vsHvarCallMethodByName
 * @see vsHvarConstruct 
 * @see vsCallPtr 
 * @see vsLoadTemplate
 * @see vsFindIndex 
 *  
 * @categories Miscellaneous_Functions
 */
struct VSARGTYPE {
   VSArgTypeKind kind;
   union {
      int i;                                   // VSARGTYPE_INT
      long l;                                  // VSARGTYPE_LONG
      size_t size;                             // VSARGTYPE_SIZE_T
      bool b;                                  // VSARGTYPE_BOOL
      VSHVAR hvar;                             // VSARGTYPE_HVAR or VSARGTYPE_HREFVAR
                                               //   (this case is easier to remember than hVar)
      VSHVAR hVar;                             // VSARGTYPE_HVAR or VSARGTYPE_HREFVAR
      const char *psz;                         // VSARGTYPE_PSZ
      const VSLSTR *plstr;                     // VSARGTYPE_PLSTR
      VSBUFARG *pBufArg;                       // VSARGTYPE_BUF
      VSINT64 i64;                             // VSARGTYPE_INT64
      double d;                                // VSARGTYPE_DOUBLE
      bool *pbool;                             // VSARGTYPE_REF_BOOL
      int *pint32;                             // VSARGTYPE_REF_INT
      long *plong;                             // VSARGTYPE_REF_LONG
      VSINT64 *pint64;                         // VSARGTYPE_REF_INT64
      size_t *psize;                           // VSARGTYPE_REF_SIZE_T
      double *pd;                              // VSARGTYPE_REF_DOUBLE
      const cmROStringUtf8 *pCMString;         // VSARGTYPE_CMSTRING
      const slickedit::SEString *pSEString;    // VSARGTYPE_SESTRING
      cmStringUtf8 *prefCMString;              // VSARGTYPE_REF_CMSTRING
      slickedit::SEString *prefSEString;       // VSARGTYPE_REF_SESTRING
      void *nuthing;                           // VSARGTYPE_EMPTY (just a placeholder)
   } u;
};

typedef int VSFUNPTR;

struct VSCALLPTR {
   int isindex;
   union {
      int index;
      VSFUNPTR funptr;
   };
};

/**
 * Note: This function is a DLL API function.  It does not have a vs prefix or 
 * have the VSAPI attribute because it is not a portable function.  It is 
 * compiler dependant.  We expect this function to work with most 
 * (maybe all) UNIX C compilers.  However, under Windows, this 
 * function will likely only work for you if you are using Microsoft 
 * Visual C++.  This function is NOT callable from Slick-C&reg; (if you need 
 * similar functionality in Slick-C&reg; use the "say" macro function).
 * <p>
 * This functions parameters are identical to the C run-time printf 
 * function.  Displays a debug message in a scrolling window.  Under 
 * UNIX, this message is sent to standard out.  This function is used to 
 * assist in debugging.
 * 
 * @see xprintf
 * @see mprintf
 * @see dfprintf
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void xprintf(const char *s, ...);
/**
 * Note	This function is a DLL API function.  It does not have a vs prefix or 
 * have the VSAPI attribute because it is not a portable function.  It is 
 * compiler dependant.  We expect this function to work with most 
 * (maybe all) UNIX C compilers.  However, under Windows, this 
 * function will likely only work for you if you are using Microsoft 
 * Visual C++.  This function is NOT callable from Slick-C&reg; (if you need 
 * similar functionality in Slick-C&reg; use the "fsay" macro function).
 * <p>
 * This functions parameters are identical to the C run-time printf 
 * function.  Displays a debug message in a message box. This function is used to 
 * assist in debugging.
 * 
 * @see xprintf
 * @see mprintf
 * @see dfprintf
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void mprintf(const char *s, ...);


/** 
 * 
 * Appends a debug message to the file "c:\junk" (UNIX: /tmp/junk.slk).  
 * This function is used for debugging a DLL that is crashing.  For this 
 * reason, the output file is opened and closed on each call to ensure 
 * that the debug information will be preserved even if the application crashes.
 * <p>
 * <b>Note:</b>	This function is a DLL API function.  It does not have a vs 
 * prefix or have the VSAPI attribute because it is not a portable function.  
 * It is compiler dependant.  We expect this function to work with most 
 * (maybe all) UNIX C compilers.  However, under Windows, this function will 
 * likely only work for you if you are using Microsoft Visual C++.  This 
 * function is NOT callable from Slick-C&reg;.
 * <p>
 * This function's parameters are identical to the C run-time printf function.  
 * 
 * @see xprintf
 * @see mprintf
 * @see dfprintf
 * 
 * @categories Miscellaneous_Functions
 * 
 */
void dfprintf(const char *s, ...);


/**
 * Outputs debug data to a scrolling window.  The next debug output 
 * message will be printed on the next line.  This function is not yet 
 * supported under UNIX.  This function is used to assist 
 * debugging.
 * <p>
 * Use vsprintln to implement your own xprintf
 * <p>
 * @param pBuf	Data to be printed.
 * 
 * @param BufLen	Number of characters in <i>pBuf</i>.  -1 
 * specifies that <i>pBuf</i> is null terminated 
 * and its length can be determined using this.
 * 
 * @see vsprint
 * @see vsprintln
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void VSAPI vsprintln(const char *pBuf,int BufLen VSDEFAULT(-1));
/**
 * Outputs debug data to a scrolling window.  This function is not 
 * yet supported under UNIX.  This function is used to assist 
 * debugging.
 * 
 * @param pBuf	Data to be printed.
 * 
 * @param BufLen	Number of characters in <i>pBuf</i>.  -1 
 * specifies that <i>pBuf</i> is null terminated 
 * and its length can be determined using this.
 * 
 * @see vsprint
 * @see vsprintln
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void VSAPI vsprint(const char *pBuf,int BufLen VSDEFAULT(-1));

#include "vsevents.h"

/**
 * <p>Reads and dispatches all system messages until there are no more
 * messages or the variable <i>*pcancel</i> becomes non-
 * zero.</p>
 * 
 * @param pcancel       Optionally points to a user variable.  When the user variable is non-zero, this function returns.
 * @param ProcessTimerEvents  Determines whether timer events should be processed.  
 * 
 * @see vsEvent2Index
 * @see vsIndex2Event
 * @see vsSetEventTabIndex
 * @see vsEventTabIndex
 * @see vsQDefaultEventTab
 * 
 * @categories Keyboard_Functions
 */
void VSAPI vsProcessEvents(int *pcancel=0,int ProcessTimerEvents=0,int AllowUserInput=0);
/**
 * Converts a SlickEdit event constant into its corresponding 
 * name.
 * 
 * @return Returns pszName.
 * 
 * @param event	SlickEdit event constant.
 * 
 * @param pszName	Output buffer for name of event.  This can 
 * be 0.
 * 
 * @param MaxNameLen	Number of characters allocated to 
 * <i>pszName</i>.  We recommend 
 * VSMAXEVENTNAME.
 * 
 * @param option	One of the following option letters:
 * 
 * <dl>
 * <dt>'S'</dt><dd>Return Slick-C&reg; source code event name.  
 * These will never change so that our Slick-C&reg; 
 * source code will be backward compatible.</dd>
 * <dt>'L'</dt><dd>Return long event names intended for 
 * display on a menu. like "Alt+F4" instead for 
 * "A+F4".</dd>
 * <dt>'C'</dt><dd>Return short event names intended for 
 * display on a menu.</dd>
 * </dl>
 * 
 * @param pMaxNameLen	If this is not 0, this is set to the number of 
 * characters you need to allocate.
 * 
 * @see vsEvent2Index
 * @see vsIndex2Event
 * @see vsSetEventTabIndex
 * @see vsEventTabIndex
 * @see vsQDefaultEventTab
 * 
 * @categories Keyboard_Functions
 * 
 */ 
char *VSAPI vsEvent2Name(int event,char *pszName,int MaxNameLen,char option VSDEFAULT('L' /*SLC*/),int *pMaxNameLen VSDEFAULT(0), int version VSDEFAULT(0));
/**
 * This functions no longer has a purpose and is present for backward
 * compatibiliy only.
 * 
 * @categories Keyboard_Functions
 * @param event   Event constant
 * @param version
 * 
 * @return Returns input <i>index</i> unmodified.
 * 
 * @see vsIndex2Event
 * @deprecated It is no longer necessary to call this function.
 */
/*VSDEPRECATED*/ int VSAPI vsEvent2Index(int event,int version VSDEFAULT(0));
/**
 * @return Returns input <i>index</i> unmodified.
 * 
 * @param index	 Event
 * 
 * @see vsEvent2Index
 * @deprecated It is no longer necessary to call this function.
 * 
 * @categories Keyboard_Functions
 * 
 */ 
/*VSDEPRECATED*/ int VSAPI vsIndex2Event(int index,int version VSDEFAULT(0));
/**
 * Set event binding.
 * 
 * @examples 
 * <pre>
 *      static int VSAPI MyCommand()
 *      {
 *            vsMessageBox("Got here");
 *      }
 * 
 *      extern "C" int VSAPI vsDllInit()
 *      {
 *          vsLibExport("_command int MyCommand()",
 *                  0,0,
 *                                      MyCommand);
 *           // Bind this command to Shift+F12
 *           vsSetEventTabIndex(
 *                  vsQDefaultEventTab(),
 *                  VSEV_F12|VSEVFLAG_SHIFT,    // Shift+F12
 *                  vsFindIndex("MyCommand", VSTYPE_COMMAND));
 * 
 *      }
 * </pre>
 * @categories Keyboard_Functions
 * @param keytab_index
 *                  Index into names table of event table.  When
 *                  setting key bindings this is usually the event
 *                  table returned by
 *                  <b>vsQDefaultEventTab</b>() or
 *                  VSP_MODEEVENTTAB.
 * @param key_index  An event constant VSEV_??? from vsevents.h
 * @param index      Names table index.  May be 0 to unbind key.
 * @param version    Must be 0.
 * 
 * @return 
 * @see vsEvent2Name
 * @see vsEventTabIndex
 * @see vsQDefaultEventTab
 */
int VSAPI vsSetEventTabIndex(int keytab_index,int key_index,int index,int version VSDEFAULT(0));

/**
 * Sets range of event bindings
 * 
 * @categories Keyboard_Functions
 * @param keytab_index
 *                   Index into names table of event table.  When
 *                   setting key bindings this is usually the event
 *                   table returned by
 *                   <b>vsQDefaultEventTab</b>() or
 *                   VSP_MODEEVENTTAB.
 * @param event1  An event constant VSEV_??? from vsevents.h
 * @param event2  An event constant VSEV_??? from vsevents.h
 * <dl>
 * <dt>VSEV_RANGE_FIRST_CHAR_KEY<dd>First character key.  This is character code 0. No shift flags may be combined with this.
 * <dt>VSEV_RANGE_LAST_CHAR_KEY<dd>Last character key.  This is character code 0x1ffffff.  No shift flags may be combined with this.
 * <dt>VSEV_RANGE_FIRST_NONCHAR_KEY<dd>First non unicode character key. No shift flags may be combined with this.
 * <dt>VSEV_ALL_RANGE_LAST_NONCHAR_KEY<dd>Last non unicode character key with all shift flags.
 * <dt>VSEV_RANGE_FIRST_MOUSE<dd>First mouse event.  Shift flags may be combined with this.
 * <dt>VSEV_RANGE_LAST_MOUSE<dd>Last mouse event. Shift flags may be combined with this.
 * <dt>VSEV_ALL_RANGE_LAST_MOUSE<dd>Last mouse event with all shift flags.
 * <dt>VSEV_RANGE_FIRST_ON<dd>First ON event. No shift flags may be combined with this.
 * <dt>"VSEV_RANGE_LAST_ON<dd>Last ON event. No shift flags may be combined with this.
 * </dl>
 * 
 * @param index      Names table index.  May be 0 to unbind key.
 * @param version    Must be 0.
 * 
 * @return 
 * @example 
 * <pre>
 * static int VSAPI MyCommand()
 * {
 *    vsMessageBox("Got here");
 * }
 * 
 * extern "C" int VSAPI vsDllInit()
 * {
 *    vsLibExport("_command int MyCommand()",
 *            0,0,
 *            MyCommand);
 *    // Bind this command to a range of characters
 *    // ' ' - Last supported Unicode character
 *    vsSetEventTabRangeIndex(
 *           vsQDefaultEventTab(),
 *           VSEV_SPACE,
 *           VSEV_RANGE_LAST_CHAR_KEY,
 *           vsFindIndex("MyCommand", VSTYPE_COMMAND));
 *    
 *    // Unbind all character keys. This effects keys
 *    // like a-z, punctuation, and foreign language characters.  
 *    // Keys like Alt+A which are not unicode characters are not effected.
 *    vsSetEventTabRangeIndex(
 *           vsQDefaultEventTab(),
 *           VSEV_RANGE_FIRST_CHAR_KEY,
 *           VSEV_RANGE_LAST_CHAR_KEY,
 *           0);
 * 
 *    // Unbind all non-character keys including keys like Enter, 
 *    // Backspace, Ctrl+Shift+Alt+Enter, Alt+A
 *    vsSetEventTabRangeIndex(
 *           vsQDefaultEventTab(),
 *           VSEV_RANGE_NONFIRST_CHAR_KEY,
 *           VSEV_ALL_RANGE_NONLAST_CHAR_KEY,
 *           0);
 * 
 *    // Unbind all mouse events in any shift key combination.
 *    vsSetEventTabRangeIndex(
 *           vsQDefaultEventTab(),
 *           VSEV_RANGE_FIRST_MOUSE,
 *           VSEV_ALL_RANGE_LAST_MOUSE,
 *           0);
 * 
 *    // Unbind all Ctrl+mouse events.
 *    vsSetEventTabRangeIndex(
 *           vsQDefaultEventTab(),
 *           VSEV_RANGE_FIRST_MOUSE|VSEVFLAG_CTRL,
 *           VSEV_ALL_RANGE_LAST_MOUSE|VSEVFLAG_CTRL,
 *           0);
 * </pre>
 * 
 * @see vsEvent2Name
 * @see vsEventTabIndex
 * @see vsQDefaultEventTab
 */
int VSAPI vsSetEventTabRangeIndex(int keytab_index,int event1,
                                  int event2,int index,int version VSDEFAULT(0));
/**
 * @return Returns key binding information.
 * 
 * @param root_keytab_index	Index into names table of root event 
 * table.  When checking for key bindings this 
 * is usually the event table returned by 
 * <b>vsQDefaultEventTab</b>().
 * 
 * @param mode_keytab_index	Index into names table of mode 
 * event table.  This is either the same as 
 * <i>root_keytab_index</i> or the value of 
 * the VSP_MODEEVENTTAB property.  
 * Note that the mode event table is defined so 
 * that each language can override keys like 
 * <ENTER>,  <Space Bar>, etc. for smarter 
 * support.
 * 
 * @param key_index	The event index in range 
 * 1..VS_NUMKEYS-1.  Use 
 * <b>vsEvent2Index</b> to convert an event 
 * constant to an index.
 * 
 * @param return_used_keytab	When non-zero, the index of the 
 * event table which has this key binding is 
 * returned (i.e. either root_keytab_index, 
 * mode_keytab_index, or 0 if there is not 
 * binding).
 * 
 * @example
 * <pre>
 * int root_etab;
 * root_etab=vsQDefaultEventTab();
 * int index;
 * // Check key binding for Alt+F4
 * index= vsEventTabIndex(
 *        root_etab, 
 *        root_etab, 
 *        vsEvent2Index(VS_A_FKEYS_OFFSET+ 4));
 * if( vsNameType(index) & VSTYPE_COMMAND) {
 *      // Display the command bound to this key.
 *      vsMessage(vsNameName(index));
 * } else if (vsNameType(index) & VSTYPE_EVENTTAB) {
 *      // This key is a prefix key.  Display name of event table.
 *      vsMessage(vsNameName(index));
 * } else {
 *      // This could be a global function (not a command)
 *      // This could be an event function   "text1.A_F4() {   }" but this 
 * is unlikely for
 *      // the default event table.
 * }
 * </pre>
 * 
 * @see vsEvent2Name
 * @see vsIndex2Event
 * @see vsSetEventTabIndex
 * @see vsEvent2Index
 * @see vsQDefaultEventTab
 * 
 * @categories Keyboard_Functions
 * 
 */ 
int VSAPI vsEventTabIndex(int root_keytab_index,int mode_keytab_index,
                          int key_index,int return_used_keytab VSDEFAULT(0),int version VSDEFAULT(0));

/**
 * Retrieve the list of current event bindings.
 * 
 * @param keytab_index Index into names table of event table to query for bindings.
 * @param Nofbindings  (output). Number of bindings returned.
 * @param reserved     Reserved for future use. Should always be 0.
 * 
 * @return VSEVENT_BINDING array of event bindings. Nofbindings contains the count on return.
 * <p>
 * <b>IMPORTANT</b>: <br>
 * The array returned is managed data and must NOT be freed or altered. 
 * The array returned will be null if there are no bindings to list. 
 */
const VSEVENT_BINDING* VSAPI vsListBindings(int keytab_index, int* Nofbindings, int reserved VSDEFAULT(0));

/**
 * This function is used to redirect a key.  For example, in our OEM MDI 
 * sample program, we redirect client window key presses to send the key 
 * press to VSMDI_WID.
 * 
 * @param wid	Window id of editor control.  0 specifies the 
 * current object.
 * 
 * @param event	An event returned by vsLastEvent or a event 
 * constant from "vsevents.h".
 * 
 * @param pszShowKeys	Previous prefix key message.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Keyboard_Functions
 * 
 */ 
void VSAPI vsCallKey(int wid,int event,const char *pszShowKeys VSDEFAULT(0),int Reserved VSDEFAULT(1),int version VSDEFAULT(0));
/**
 * @return Returns reference to next element in array or hash table.  If 
 * <i>index</i> is empty (see <b>vsHvarMakeEmpty</b>()), the first 
 * element is returned.  If there are no more elements, <i>index</i> is set 
 * to empty and 0 is returned.
 * 
 * @param hvar	Handle to hash table or array variable.
 * 
 * @param hvarIndex	Handle to index variable.
 * 
 * @example
 * <pre>
 * VSHVAR  hvar;
 * VSHVAR hvarel;
 * 
 * // Create hash table with ["a"]=1, ["b"]=2, and ["c"]=3
 * hvar=vsHvarAlloc();
 * hvarel=vsHvarHashTabEl(hvar,"a");vsHvarSetI(hvarel,1);
 * hvarel=vsHvarHashTabEl(hvar,"b");vsHvarSetI(hvarel,2);
 * hvarel=vsHvarHashTabEl(hvar,"c");vsHvarSetI(hvarel,3);
 * // Traverse the elements in hash table
 * VSHVAR hvarIndex;
 * for (vsHvarMakeEmpty(hvarIndex);;) {
 *    VSHVAR    hvarel;
 *     hvarel=vsHvarNextEl(hvar,hvarIndex);
 *     if (!hvarel) break;
 *     vsMessageBox ((char *)vsHvarGetLstr (hvarel)->str);
 * }
 * </pre>
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
VSHVAR VSAPI vsHvarNextEl(VSHVAR hvarArrayOrHashTab,VSHVAR hvarstart);
/**
 * @return Returns true if the format of the variable specified is VSVF_EMPTY.  
 * This is equivelant to the expression 
 * <b>vsHvarFormat</b>(hvar)==VSVF_EMPTY.
 * 
 * @param hvar	Handle to variable.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
bool VSAPI vsHvarIsEmpty(VSHVAR hvar);
/**
 * Clears contents of variable and sets its variable format to 
 * VSVF_EMPTY.
 * 
 * @param hvar	Handle to variable.
 * 
 * @example
 * <pre>
 * VSHVAR  hvar;
 * VSHVAR hvarel;
 * 
 * // Create hash table with ["a"]=1, ["b"]=2, and ["c"]=3
 * hvar=vsHvarAlloc();
 * hvarel=vsHvarHashTabEl(hvar,"a");vsHvarSetI(hvarel,1);
 * hvarel=vsHvarHashTabEl(hvar,"b");vsHvarSetI(hvarel,2);
 * hvarel=vsHvarHashTabEl(hvar,"c");vsHvarSetI(hvarel,3);
 * // Traverse the elements in hash table
 * VSHVAR hvarIndex;
 * for (vsHvarMakeEmpty(hvarIndex);;) {
 *    VSHVAR    hvarel;
 *     hvarel=vsHvarNextEl(hvar,hvarIndex);
 *     if (!hvarel) break;
 *     vsMessageBox ((char *)vsHvarGetLstr (hvarel)->str);
 * }
 * </pre>
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void VSAPI vsHvarMakeEmpty(VSHVAR hvar);
/**
 * @return Returns a Slick-C&reg; variable handle which refers to an element in a 
 * Slick-C&reg; array.   If the index specified by <i>i</i> is greater than the 
 * number of items in the array specifed, the array is made larger and a 
 * variable handle to an uninitialized element is returned.  If 
 * <i>hVarHashtab</i> is not currently an array, the current variable 
 * contents are destroyed and an empty array is created.
 * 
 * @example
 * <pre>
 *    // Call a Slick-C&reg; function which returns a Slick-C&reg; array or struct
 *    int index;
 *    index=vsFindIndex("ProcReturnsArray ",VSTYPE_PROC);
 *    if (!index) {
 *        vsMessage("not found");
 *        return;
 *    }
 *    VSARGTYPE ArgList[1];
 *    ArgList[0].kind=VSARGTYPE_PSZ;ArgList[0].u.psz="some 
 * message";
 *    vsCallIndex(0,index,1,ArgList);
 *    // Get first element of array or struct
 *    VSHVAR hvar;
 *    hvar=vsHvarArrayEl(VSHVAR_RC,0);
 *   VSPLSTR  plstr;
 *    // Interpreter L strings are NULL terminated.
 *    plstr=vsHvarGetLstr(hvar);
 *    vsMessage((char *)plstr->str);
 * </pre>
 * 	
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
VSHVAR VSAPI vsHvarArrayEl(VSHVAR hVarArrayEl, int i);
/**
 * @return Returns number or entries in the array variable specified.
 * 
 * @param hvar     Handle to Slick-C variable.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsHvarArrayLength(VSHVAR hvar);
/**
 * @return Returns a Slick-C&reg; variable handle which refers to an element in a 
 * Slick-C&reg; hash table.  If the string index specified by pBuf does not 
 * exists in the hash table specified, a new uninitialized elemented is 
 * inserted.  If <i>hVarHashtab</i> is not currently a hash table, the 
 * current variable contents are destroyed and an empty hash table is 
 * created.
 * 
 * @example
 * <pre>
 *    // Call a Slick-C&reg; function which returns a Slick-C&reg; hash table
 *    int index;
 *    index=vsFindIndex("ProcReturnsHashtab ",VSTYPE_PROC);
 *    if (!index) {
 *        vsMessage("not found");
 *        return;
 *    }
 *    VSARGTYPE ArgList[1];
 *    ArgList[0].kind=VSARGTYPE_PSZ;ArgList[0].u.psz="some 
 * message";
 *    vsCallIndex(0,index,1,ArgList);
 *    // Get known index element of a hash table
 *    VSHVAR hvar;
 *    hvar=vsHvarHashtabEl(VSHVAR_RC,"styles");
 *   VSPLSTR  plstr;
 *    // Interpreter L strings are NULL terminated.
 *    plstr=vsHvarGetLstr(hvar);
 *    vsMessage((char *)plstr->str);
 * </pre>
 * 	
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
VSHVAR VSAPI vsHvarHashtabEl(VSHVAR hVarHashtab,const char *pBuf,int BufLen VSDEFAULT(-1));

/**
 * @return 
 * Returns pointer to Lstring value of interpreter variable corresponding 
 * to <i>hvar</i>. 
 *  
 * @note 
 * This is an antiquated way of getting a string value.  It is not re-entrant.
 * It is better to use {@link vsHvarGetS} to copy out the string value as a 
 * reference-counted object. 
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      VSPLSTR plstr;
 * 	      char buffer[100];
 * 
 * 	      // The rc variable is a global variable which always exists.
 * 	      index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 * 	      // Convert contents of typeless variable into ASCIIZ buffer.
 * 	      vsZLstrcpy(buffer,vsHvarGetLstr(hvar),100);
 * </pre>
 * 	
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetI
 * @see vsHvarGetS
 * @see vsHvarGetI64
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
VSPLSTR VSAPI vsHvarGetLstr(VSHVAR hVar);

/**
 * @return 
 * Returns pointer to string value of interpreter variable corresponding 
 * to <i>hvar</i>. 
 *  
 * @note 
 * This is an antiquated way of getting a string value.  It is not re-entrant.
 * It is better to use {@link vsHvarGetS} to copy out the string value as a 
 * reference-counted object. 
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      VSPLSTR plstr;
 * 	      char buffer[100];
 * 
 * 	      // The rc variable is a global variable which always exists.
 * 	      index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 * 	      xprintf("result=&lt;%s>",vsHvarGetZ(hvar));
 * </pre>
 * 	
 * @see vsHvarGetS
 * @see vsHvarSetS
 * @see vsHvarGetI
 * @see vsHvarSetI
 * @see vsHvarSetZ
 * @see vsHvarSetB
 * @see vsHvarSetI64
 * @see vsHvarGetI64
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 */ 
VSPSZ VSAPI vsHvarGetZ(VSHVAR hvar);

/**
 * @return Returns the length of the string value of interpreter variable 
 * corresponding to <i>hvar</i>.
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      char buffer[100];
 * 
 * 	      // The rc variable is a global variable which always exists.
 * 	      int index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      VSHVAR hvar=vsGetVar(index);
 * 	      xprintf("length=&lt;%d&gt;",vsHvarGetStringLength(hvar));
 * </pre>
 * 	
 * @see vsHvarGetS
 * @see vsHvarSetS
 * @see vsHvarGetZ
 * @see vsHvarSetZ
 * @see vsHvarGetI
 * @see vsHvarSetI
 * @see vsHvarSetB
 * @see vsHvarGetI64
 * @see vsHvarSetI64
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 */ 
EXTERN_C
int VSAPI vsHvarGetStringLength(VSHVAR hvar);

/**
 * Inserts an element into an array.
 * Nofitems defaults to 1.
 *  
 * @param hvarArray     array to insert item(s) into
 * @param hvarValue     value to insert into array 
 * @param start         start index corresponding to item(s) to insert
 * @param Nofitems      (default 1) number of items to insert
 *
 * @example
 * <pre>
 *    vsHvarMakeEmpty(VSHVAR_RC);
 *    hvar = vsHvarArrayEl(VSHVAR_RC, 0);
 *    vsHvarSetI(hvar, 1);
 *    hvar = vsHvarArrayEl(VSHVAR_RC, 1);
 *    vsHvarSetI(hvar, 2);
 *    hvar = vsHvarArrayEl(VSHVAR_RC, 2);
 *    vsHvarSetI(hvar, 3);
 *    vsHvarArrayDeleteEl(VSHVAR_RC, 1);
 *    hvar = vsHvarAlloc();
 *    vsHvarSetI(hvar, 4);
 *    vsHvarInsertArray(VSHVAR_RC, hvar, 1, 2);  // { 1,4,4,2,3 }
 *    vsHvarFree(hvar); 
 * </pre>
 *
 * @see vsHvarArrayDeleteEl 
 * @see vsHvarNextEl
 * @see vsHvarMakeEmpty
 * @see vsHvarIsEmpty
 * @see vsHvarFormat
 * @see vsHvarIndexIn
 *
 * @categories Miscellaneous_Functions
 */
void VSAPI vsHvarArrayInsertEl(VSHVAR hvarArray,VSHVAR hvarValue,int start,int Nofitems VSDEFAULT(1));
/**
 * Deletes elements from an array variable.
 *
 * @param hvarArray     array to delete item(s) from 
 * @param start         start index corresponding to item(s) to delete
 * @param Nofitems      (default 1) number of items to delete
 *
 * @example
 * <pre>
 *    vsHvarMakeEmpty(VSHVAR_RC);
 *    hvar = vsHvarArrayEl(VSHVAR_RC, 0);
 *    vsHvarSetI(hvar, 1);
 *    hvar = vsHvarArrayEl(VSHVAR_RC, 1);
 *    vsHvarSetI(hvar, 2);
 *    hvar = vsHvarArrayEl(VSHVAR_RC, 2);
 *    vsHvarSetI(hvar, 3);
 *    vsHvarArrayDeleteEl(VSHVAR_RC, 1); // t[1] will now contain 3
 * </pre>
 *
 * @see vsHvarNextEl
 * @see vsHvarMakeEmpty
 * @see vsHvarIsEmpty
 * @see vsHvarFormat
 *
 * @categories Miscellaneous_Functions
 */
void VSAPI vsHvarArrayDeleteEl(VSHVAR hvarArray,int start,int Nofitems VSDEFAULT(1));
/**
 * Inserts an element into a hash table.
 * Nofitems defaults to 1.
 *  
 * @param hvarHashtab   hash table to insert item into
 * @param hvarValue     value to insert into hash table 
 * @param pBuf          index or key corresponding to item to look for
 * @param BufLen        length of hash key
 *
 * @example
 * <pre>
 *    vsHvarMakeEmpty(VSHVAR_RC);
 *    hvar = vsHvarAlloc();
 *    vsHvarSetZ(hvar, "world");
 *    vsHvarHashtabInsertEl(VSHVAR_RC, hvar, "hello");
 *    vsHvarFree(hvar); 
 * </pre>
 *
 * @see vsHvarHashtabDeleteEl 
 * @see vsHvarNextEl
 * @see vsHvarMakeEmpty
 * @see vsHvarIsEmpty
 * @see vsHvarFormat
 * @see vsHvarIndexIn
 *
 * @categories Miscellaneous_Functions
 */
void VSAPI vsHvarHashtabInsertEl(VSHVAR hvarArray,VSHVAR hvarValue,VSPSZ pBuf,int BufLen VSDEFAULT(-1));
/**
 * Deletes an element from hash table.
 *
 * @param hvarHashtab   hash table to delete item from
 * @param pBuf          index or key corresponding to item to look for
 * @param BufLen        length of hash key
 *
 * @example
 * <pre>
 *    vsHvarMakeEmpty(VSHVAR_RC);
 *    hvar=vsHvarHashtabEl(VSHVAR_RC,"styles");
 *    vsHvarSetI(hvar,1);
 *    vsHvarHashtabDeleteEl(VSHVAR_RC,"styles");
 * </pre>
 *
 * @see vsHvarNextEl
 * @see vsHvarMakeEmpty
 * @see vsHvarIsEmpty
 * @see vsHvarFormat
 * @see vsHvarIndexIn
 *
 * @categories Miscellaneous_Functions
 */
void VSAPI vsHvarHashtabDeleteEl(VSHVAR hvarHashtab,VSPSZ pBuf,int BufLen VSDEFAULT(-1));
/**
 * @return
 * Returns a reference to element if element exists at index given.
 * 
 * @param hvarHashtab   hash table to test 
 * @param pBuf          index or key corresponding to item to look for
 * @param BufLen        length of hash key
 * 
 * @example
 * <pre>
 *    vsHvarMakeEmpty(VSHVAR_RC);
 *    hvar=vsHvarHashtabEl(VSHVAR_RC,"styles");
 *    vsHvarSetI(hvar,1);
 *    hvar=vsHvarIndexIn(VSHVAR_RC,"styles");  // will be non-zero
 *    hvar=vsHvarIndexIn(VSHVAR_RC,"color");   // will be zero
 * </pre>
 *
 * @see vsHvarNextEl
 * @see vsHvarMakeEmpty
 * @see vsHvarIsEmpty
 * @see vsHvarFormat
 * @see vsHvarHashtabInsertEl
 *
 * @categories Miscellaneous_Functions
 */
VSHVAR VSAPI vsHvarIndexIn(VSHVAR hvarHashtab,VSPSZ pBuf,int BufLen VSDEFAULT(-1));
/**
 * @return Returns integer value of interpreter variable corresponding to 
 * <i>hvar</i>.  If the value of the variable is not a valid integer, an 
 * unknown value is returned.
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      int i;
 * 	      int index;
 *  
 * 	      // The rc variable is a global variable which always exists.
 * 	      index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 * 	      i=vsHvarGetI(hvar);
 * </pre>
 * 	
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarGetI64 
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetZ
 * @see vsHvarGetLstr 
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsHvarGetI(VSHVAR hVar);
/**
 * @return Returns integer value of interpreter variable corresponding to 
 * <i>hvar</i>.  If the value of the variable is not a valid 64-bit integer, 
 * an unknown value is returned.
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      VSINT64 i;
 * 	      int index;
 *  
 * 	      // The rc variable is a global variable which always exists.
 * 	      index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 * 	      i=vsHvarGetI64(hvar);
 * </pre>
 *  
 * @see vsHvarGetI 
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
VSINT64 VSAPI vsHvarGetI64(VSHVAR hVar);
/**
 * @return Returns integer value representing a window ID of 
 *         interpreter variable corresponding to <i>hvar</i>. If
 *         the value of the variable is not a valid integer, an
 *         unknown value is returned.
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      int i;
 * 	      int index;
 *  
 * 	      // The rc variable is a global variable which always exists.
 * 	      index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 *          i=vsHvarGetWID(hvar);
 * </pre>
 * 	
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsHvarGetWID(VSHVAR hVar);
/**
 * @return Returns the id of the interpreter variable pointed to
 *         by the interpreter variable corresponding to
 *         <i>hvar</i>.
 * 
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
VSHVAR VSAPI vsHvarGetHRef(VSHVAR hVar);
/**
 * Sets value of interpreter variable to integer value specified.
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      VSPLSTR plstr;
 * 	      char buffer[100];
 * 
 * 	      // The rc variable is a global variable which always exists.
 * 	      index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 * 	     // Specify integer for variable value
 * 	      vsHvarSetI(hvar,100);
 * </pre>
 * 	
 * @see vsHvarSetB
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsHvarSetZ
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsHvarSetI64
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsHvarSetI(VSHVAR hVar,int value);
/**
 * Sets value of interpreter variable to the 64-bit integer value specified.
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      VSPLSTR plstr;
 * 	      char buffer[100];
 * 
 * 	      // The rc variable is a global variable which always exists.
 * 	      index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 * 	     // Specify integer for variable value
 * 	      vsHvarSetI64(hvar,100);
 * </pre>
 * 	
 * @see vsHvarSetB
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsHvarSetZ
 * @see vsHvarSetI
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsHvarSetI64(VSHVAR hVar,VSINT64 value);
/** 
 * Sets value of interpreter variable to window id specified. 
 * The window id is represented as an integer. 
 * 
 * @example
 * <pre>
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 * 	     // Specify integer for variable value
 *          vsHvarSetWID(hvar,wid);
 * </pre>
 * 	
 * @see vsHvarSetB
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsHvarSetZ
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarSetWID(VSHVAR hVar,int wid);
/**
 * Sets value of interpreter variable specified to data pointed to by pBuf. 
 * <i>BufLen</i> specifies the length of the data.
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      VSPLSTR plstr;
 * 	      char buffer[100];
 * 
 * 	      // The rc variable is a global variable which always exists.
 * 	      index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 * 	      vsHvarSetB(hvar,"this is a test",14);
 * </pre>
 * 	
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsHvarSetZ
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsHvarSetB(VSHVAR hVar,const void *pBuf,int BufLen);
/**
 * Sets value of interpreter variable specified to ASCIIZ string 
 * <i>pszValue.</i>
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      VSPLSTR plstr;
 * 	      char buffer[100];
 * 
 * 	      // The rc variable is a global variable which always exists.
 * 	      index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 * 	      vsHvarSetZ(hvar,"this is a test");
 * </pre>
 * 	
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsHvarSetB
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsHvarSetZ(VSHVAR hVar,const char *pszValue);
/** 
 * Sets value of interpreter variable specified to be a copy of 
 * the given interpreter variable. 
 *  
 * @param hvar    interpreter variable (destination) 
 * @param src     interpreter variable (source)
 * 
 * @see vsHvarFree 
 * @see vsHvarAlloc 
 * @see vsHvarMakeEmpty 
 * @see vsHvarArrayEl 
 * @see vsHvarSetI 
 * @see vsHvarSetI64
 * @see vsHvarSetZ 
 *  
 * @return Returns <0 on error.
 *  
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarCopy(VSHVAR hvar,VSHVAR src);
/** 
 * Compare two Hvar's for exact equality. 
 *  
 * @param lhs     left hand side of comparison
 * @param rhs     right hand side of comparison 
 * 
 * @see vsHvarFree 
 * @see vsHvarAlloc 
 * @see vsHvarMakeEmpty 
 * @see vsHvarArrayEl 
 * @see vsHvarSetI 
 * @see vsHvarSetI64
 * @see vsHvarSetZ 
 * @see vsHvarCopy 
 *  
 * @return Returns <0 on error.
 *  
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarEqual(VSHVAR rhs,VSHVAR lhs);
/** 
 * Sets value of interpreter variable specified to be a pointer 
 * to the given interpreter variable. 
 *  
 * NOTE:  As always with pointer types, use with care, because 
 * interpreter variables are not reference counted.  If the 
 * <code>src</code> variable goes out of scope, it will be 
 * destructed, leaving this pointer dangling. 
 *  
 * @param hvar    interpreter variable (destination) 
 * @param src     interpreter variable (source)
 * 
 * @see vsHvarFree 
 * @see vsHvarAlloc 
 * @see vsHvarMakeEmpty 
 * @see vsHvarArrayEl 
 * @see vsHvarSetI 
 * @see vsHvarSetI64
 * @see vsHvarSetZ 
 *  
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarSetPointer(VSHVAR hvar,VSHVAR src);

/**
 * @return Return a string describing the type of the given variable.
 * This is only for class and struct instances.
 * 
 * @param hvar    handle for interpreter variable
 * 
 * @categories Miscellaneous_Functions
 */
VSPSZ VSAPI vsHvarTypename(VSHVAR hvar);
/**
 * @return Return the number of non-static data members in a
 *         class or struct.
 *         Returns CLASS_NAME_NOT_FOUND_RC if the class is not found.
 * 
 * @param class_name Slick-C&reg; class name
 * 
 * @see vsHvarFieldName
 * @see vsHvarFieldIndex
 * @see vsHvarClassFieldName
 * @see vsHvarClassFieldIndex
 * @see vsHvarNumFields
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarClassNumFields(VSPSZ class_name);
/**
 * @return Return the number of non-static data members in a
 *         class or struct type instance.
 *         Returns CLASS_NAME_NOT_FOUND_RC if the class is not found.
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a struct or class instance.
 * 
 * @param hvar       handle for interpreter variable 
 * 
 * @see vsHvarFieldName
 * @see vsHvarFieldIndex
 * @see vsHvarClassFieldName
 * @see vsHvarClassFieldIndex
 * @see vsHvarClassNumFields
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarNumFields(VSHVAR hvar);
/**
 * @return Return the index >= 0 for the given non-static member
 *         of a class or struct.  
 *         Returns CLASS_NAME_NOT_FOUND_RC if the class is not found.
 *         Returns CLASS_MEMBER_NOT_FOUND_RC if the field is not found.
 * 
 * @param class_name Slick-C&reg; class name
 * @param field_name name of struct or class data field (non-static)
 * 
 * @see vsHvarFieldName
 * @see vsHvarFieldIndex
 * @see vsHvarClassFieldName
 * @see vsHvarGetField
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarClassFieldIndex(VSPSZ class_name,VSPSZ field_name);

void VSAPI vsHvarClearClassFieldCache(const slickedit::SEString &class_name);

/**
 * @return Return the index >= 0 for the given non-static member
 *         of a class or struct.  
 *         Returns CLASS_MEMBER_NOT_FOUND_RC if the field is not found.  
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a struct or class instance.
 * 
 * @param hvar       handle for interpreter variable 
 * @param field_name name of struct or class data field (non-static)
 * 
 * @see vsHvarFieldName
 * @see vsHvarClassFieldName
 * @see vsHvarClassFieldIndex
 * @see vsHvarGetField
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarFieldIndex(VSHVAR hvar,VSPSZ field_name);
/**
 * @return Return the name of the given non-static member of
 *         a class or struct.  
 *         Returns CLASS_NAME_NOT_FOUND_RC if the class is not found.
 *         Returns INVALID_ARGUMENT_RC if the field index is out of range.
 * 
 * @param class_name Slick-C&reg; class name
 * @param index      index >=0 of non-static data member
 * 
 * @see vsHvarFieldIndex
 * @see vsHvarFieldName
 * @see vsHvarClassFieldIndex
 * @see vsHvarGetField
 * 
 * @categories Miscellaneous_Functions
 */
VSPSZ VSAPI vsHvarClassFieldName(VSPSZ class_name,int index);
/**
 * @return Return the name of the given non-static member of
 *         a class or struct instance.  
 *         Returns INVALID_ARGUMENT_RC if the field index is out of range.
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a struct or class instance.
 * 
 * @param hvar    handle for interpreter variable
 * @param index   index >=0 of non-static data member
 * 
 * @see vsHvarFieldIndex
 * @see vsHvarGetField
 * 
 * @categories Miscellaneous_Functions
 */
VSPSZ VSAPI vsHvarFieldName(VSHVAR hvar,int index);
/**
 * @return Return a handle to the given non-static data member
 *         of a class or struct.  
 *         Returns INVALID_ARGUMENT_RC if the field index is out of range.
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a struct or class instance.
 * 
 * @param hvar    handle for interpreter variable
 * @param index   index >=0 of non-static data member
 * 
 * @see vsHvarFieldIndex
 * @see vsHvarGetFieldByName
 * 
 * @categories Miscellaneous_Functions
 */
VSHVAR VSAPI vsHvarGetField(VSHVAR hvar,int index);
/**
 * @return Return a handle to the given non-static data member
 *         of a class or struct.  
 *         Returns CLASS_MEMBER_NOT_FOUND_RC if the field is not found.  
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a struct or class instance.
 * 
 * @param hvar       handle for interpreter variable
 * @param field_name name of non-static data member
 * 
 * @see vsHvarFieldName
 * @see vsHvarGetField
 * 
 * @categories Miscellaneous_Functions
 */
VSHVAR VSAPI vsHvarGetFieldByName(VSHVAR hvar,VSPSZ field_name);
/**
 * Modify the contents of the given non-static 
 * data member of a class or struct.
 * 
 * @param hvar    handle for interpreter variable
 * @param index   index >=0 of non-static data member
 * @param value   value to set field to
 * 
 * @return 0 on success.
 *         Returns INVALID_ARGUMENT_RC if the field index is out of range.
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a struct or class instance.
 * 
 * @see vsHvarFieldIndex
 * @see vsHvarSetFieldByName
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarSetField(VSHVAR hvar,int index,VSHVAR value);
/**
 * Modify the contents of the given non-static 
 * data member of a class or struct.
 * 
 * @param hvar    handle for interpreter variable
 * @param name    name of non-static data member
 * @param value   value to set field to
 * 
 * @return 0 on success.
 *         Returns CLASS_MEMBER_NOT_FOUND_RC if the field is not found.  
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a struct or class instance.
 * 
 * @see vsHvarFieldName
 * @see vsHvarSetField
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarSetFieldByName(VSHVAR hvar,VSPSZ name,VSHVAR value);
/**
 * @return Return the name index of the given (virtual) method 
 *         for the a class instance.  For virtual methods, this will
 *         find the nearest virtual method, starting with the actual
 *         type of the 'hvar' class instance.
 *         Returns CLASS_MEMBER_NOT_FOUND_RC if the method is not found.  
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a class instance.
 * 
 * @param hvar       handle for interpreter variable
 * @param func_name  name of class function
 * 
 * @see vsHvarCallMethod
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarFindMethod(VSHVAR hvar,VSPSZ func_name);
/**
 * @return Return the name index of the given (virtual) method 
 *         for the a Slick-C&reg; class.  For virtual methods, this will
 *         find the nearest virtual method, starting with the actual
 *         type of the given class.
 *         Returns CLASS_NAME_NOT_FOUND_RC if the class is not found.
 *         Returns CLASS_MEMBER_NOT_FOUND_RC if the method is not found.  
 * 
 * @param class_name Slick-C&reg; class name
 * @param func_name  name of class function
 * 
 * @see vsHvarCallMethod
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarClassFindMethod(VSPSZ class_name,VSPSZ func_name);

void VSAPI vsHvarClearClassMethodCache();

/**
 * Check if the given variable is an instance of the given class
 * and if it implements the method named.
 * 
 * @param hvar          handle for interpreter variable
 * @param class_name    name of class or interface to test 
 * @param method_name   name of method to find
 * 
 * @return Return the name index of the given (virtual) method 
 *         for the a Slick-C&reg; class.  For virtual methods, this will
 *         find the nearest virtual method, starting with the actual
 *         type of the given class.
 *         Returns CLASS_NAME_NOT_FOUND_RC if the class is not found.
 *         Returns CLASS_MEMBER_NOT_FOUND_RC if the method is not found.  
 *
 * @see vsHvarTypename
 * @see vsHvarInstanceOf
 * @see vsHvarFindMethod 
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarFindInterfaceMethod(VSHVAR hvar,VSPSZ class_name,VSPSZ method_name);
/**
 * Call a class method with the given argument list. 
 * 
 * @param wid        window ID
 * @param hvar       handle for interpreter variable
 * @param index      names table index of class function
 * @param Nofargs    number of arguments
 * @param pArgList   array of arguments
 * 
 * @return 0 on success.
 *         Returns INVALID_ARGUMENT_RC if the method index is invalid.
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a struct or class instance.
 * 
 * @see vsHvarFindMethod
 * @see vsHvarCallMethodByName
 * @see VSARGTYPE 
 * @see VSArgTypeKind 
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarCallMethod(int wid,VSHVAR hvar,int index,int Nofargs,const VSARGTYPE *pArgList);
/**
 * Call a class method with the given argument list. 
 * 
 * @param wid        window ID
 * @param hvar       handle for interpreter variable
 * @param func_name  name of class function to call
 * @param Nofargs    number of arguments
 * @param pArgList   array of arguments
 * 
 * @return 0 on success.
 *         Returns INVALID_ARGUMENT_RC if the method index is invalid.
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a class instance.
 * 
 * @see vsHvarFindMethod
 * @see vsHvarCallMethod
 * @see VSARGTYPE 
 * @see VSArgTypeKind 
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarCallMethodByName(int wid,VSHVAR hvar,VSPSZ func_name,
                                 int Nofargs,const VSARGTYPE *pArgList);
/**
 * @return Return the name of the given parent or interface 
 *         which this class derives from or implements,
 *         respectively.  Returns INVALID_ARGUMENT_RC if the
 *         field index is out of range. Returns
 *         INVALID_HVAR_ARGUMENT_RC if 'hvar' is not a struct or
 *         class instance.
 * 
 * @param class_name    class to look up parent class for
 * @param index         0 for super class, 1 ... n for interfaces
 * 
 * @see vsHvarFieldName
 * @categories Miscellaneous_Functions
 */
VSPSZ VSAPI vsHvarClassParent(VSPSZ class_name,int index=0 /*superclass*/);
/**
 * @return Return the name of the given parent or interface 
 *         which this class derives from or implements,
 *         respectively.  Returns INVALID_ARGUMENT_RC if the
 *         field index is out of range. Returns
 *         INVALID_HVAR_ARGUMENT_RC if 'hvar' is not a struct or
 *         class instance.
 * 
 * @param hvar    handle for interpreter variable
 * @param index   0 for super class, 1 ... n for interfaces
 * 
 * @see vsHvarFieldName 
 * @see vsHvarClassParent 
 * @categories Miscellaneous_Functions
 */
VSPSZ VSAPI vsHvarParent(VSHVAR hvar,int index=0 /*superclass*/);
/**
 * Check if the given variable is an instance of the named class or interface.
 * 
 * @param hvar       handle for interpreter variable
 * @param class_name name of class, struct, or interface to test
 * 
 * @return 'true' if 'hvar' is an instance of 'name'
 *         'false' otherwise.
 *         Returns CLASS_NAME_NOT_FOUND_RC if the class is not found.
 *         Returns INVALID_HVAR_ARGUMENT_RC if 'hvar' is 
 *         not a struct or class instance.
 *
 * @see vsHvarTypename
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarInstanceOf(VSHVAR hvar,VSPSZ class_name);
/**
 * Construct a class instance and assign it to the given
 * interpreter variable.
 * <p> There is no vsHvarDestruct(), since class instances are
 * automaticaly destructed when they are freed.
 * 
 * @param hvar       interpreter variable
 * @param class_name name of class to construct an instance of
 * @param Nofargs    number of arguments
 * @param pArgList   array of arguments
 * @param numFields  Rarely needed. Needed to construct a class 
 *                   that has been defined yet so can't lookup
 *                   number of fields in the class.
 * 
 * @return Returns CLASS_NAME_NOT_FOUND_RC if the class is not
 *         found. Returns <0 on error.
 *  
 * @see vsHvarAlloc
 * @see VSARGTYPE 
 * @see VSArgTypeKind 
 * 
 * @categories Miscellaneous_Functions
 */
int VSAPI vsHvarConstruct(VSHVAR hvar, VSPSZ class_name,int Nofargs,const VSARGTYPE *pArgList,int numFields=-1);


void VSAPI vsDllInit(void);
void VSAPI vsDllExit(void);

int VSAPI vsQNofInternalClipboards(void);
/**
 * <p>Registers a native command or function that can be called from Slick-
 * C.  Commands may be invoked from the command line or bound to a 
 * key.</p>
 * 
 * <p>The syntax for <i>pszFuncProto</i> is:<br>
 * 
 * [_command] [<i>return-type</i>] <i>func-
 * name</i>([<i>type</i> [<i>var-name</i>] [, <i>type</i> [<i>var-
 * name</i>]]...])</p>
 * 
 * <p>If the _command keyword is specified, the DLL function may be 
 * bound to a key or executed from the command line.  Otherwise, the 
 * only way to call the function is to call it from a Slick-C&reg; macro.</p>
 * 
 * <p>Performance considerations:  For best performance, use the VSHVAR 
 * or VSREFVAR parameter type when operating on long strings instead 
 * of VSPSZ or VSPLSTR.  Then use the <b>vsHvarGetLstr</b> 
 * function to return a pointer to the interpreter variable. WARNING:  
 * Pointers to interpreter variables returned by the 
 * <b>vsHvarGetLstr</b> function are NOT VALID after any interpreter 
 * variable is set.  Be sure to reset any pointer after setting other 
 * interpreter variables or calling other macros. You may modify the 
 * contents of the VSPLSTR pointer returned by <b>vsHvarGetLstr</b> 
 * so long as you do not make the string any longer.  We suspect that 
 * using the int and long parameter types are no slower than using the 
 * VSHVAR type and converting the parameter yourself.</p>
 * 
 * @return Returns 0 if successful.  Otherwise a non-zero error code is returned.
 * 
 * @param func-name is the name of the DLL function to be registered.  
 * Currently the function names are case insensitive.
 * 
 * @param type may be one of the following:
 * 
 * <dl>
 * <dt>VSPSZ</dt><dd>NULL terminated string</dd>
 * <dt>VSPLSTR</dt><dd>See typedef in "vsapi.h".</dd>
 * <dt>int</dt>
 * <dt>long</dt>
 * <dt>VSHVAR</dt><dd>Handle to interpreter variable</dd>
 * <dt>VSHREFVAR</dt><dd>Call by reference handle to interpreter 
 * variable.  This type can be used as input to 
 * functions which accept VSHVAR parameters.</dd>
 * </dl>
 * 
 * @param pszNameInfo specifies completion for arguments to a 
 * command.  A '*' character may be appended to the end of a completion 
 * constant to indicate that one or more of the arguments may be entered.  
 * One or more of the follow string completion constants separated with 
 * spaces may be specified:
 * 
 * <dl>
 * <dt>VSARG_FILE</dt><dd>One filename</dd>
 * <dt>VSARG_MULTI_FILE</dt><dd>Multiple filenames</dd>
 * <dt>VSARG_BUFFER</dt><dd>Buffer name</dd>
 * <dt>VSARG_COMMAND</dt><dd>Slick-C&reg; command 
 * function</dd>
 * <dt>VSARG_PICTURE</dt><dd>Already loaded picture</dd>
 * <dt>VSARG_FORM</dt><dd>Dialog box template</dd>
 * <dt>VSARG_MODULE</dt><dd>Loaded Slick-C&reg; module</dd>
 * <dt>VSARG_MACRO</dt><dd>User recorded Slick-C&reg; 
 * command function</dd>
 * <dt>VSARG_MACROTAG</dt><dd>Slick-C&reg; tag name</dd>
 * <dt>VSARG_VAR</dt><dd>Slick-C&reg; global variable</dd>
 * <dt>VSARG_ENV</dt><dd>Environment variable</dd>
 * <dt>VSARG_MENU</dt><dd>Menu name</dd>
 * <dt>VSARG_TAG</dt><dd>Tag name</dd>
 * </dl>
 * 
 * @param arg2 is zero or more of the following flags which specify when the 
 * command should be enabled/disabled and a few other things:
 * 
 * <dl>
 * <dt>VSARG2_CMDLINE</dt><dd>Command supports the command 
 * line.</dd>
 * 
 * <dt>VSARG2_CMDLINE</dt><dd>allows a 
 * fundamental mode key binding to 
 * be inherited by the command line</dd>
 * 
 * <dt>VSARG2_MARK ON_SELECT</dt><dd>event should pass 
 * control on to this command and 
 * not deselect text first.
 * Ignored if command does not require an editor control</dd>
 * 
 * <dt>VSARG2_QUOTE</dt><dd>Indicates that this command must 
 * be quoted when called during 
 * macro recording.  Needed only if 
 * command name is an invalid 
 * identifier or keyword.</dd>
 * 
 * <dt>VSARG2_LASTKEY</dt><dd>Command requires last_event 
 * value to be set when called during 
 * macro recording.</dd>
 * 
 * <dt>VSARG2_MACRO</dt><dd>This is a recorded macro 
 * command. Used for completion.</dd>
 * 
 * <dt>VSARG2_TEXT_BOX</dt><dd>Command supports any text box 
 * control. VSARG2_TEXT_BOX 
 * allows a fundamental mode  key 
 * binding to be inherited by a text 
 * box</dd>
 * 
 * <dt>VSARG2_NOEXIT_SCROLL</dt><dd>Do not exit scroll caused by using 
 * scroll bars. Ignored if command 
 * does not require an editor control.</dd>
 * 
 * <dt>VSARG2_EDITORCTL</dt><dd>Command allowed in editor 
 * control. VSARG2_EDITORCTL 
 * allows a fundamental mode key 
 * binding to be inherited by a non-
 * MDI editor control</dd>
 * 
 * <dt>VSARG2_NOUNDOS</dt><dd>Do not automatically call 
 * _undo('s').  Require macro to call 
 * _undo('s') to start a new level of 
 * undo.</dd>
 * 
 * <dt>VSARG2_READ_ONLY</dt><dd>Command allowed when editor 
 * control is in strict read only mode. 
 * Ignored if command does not 
 * require an editor control</dd>
 * 
 * <dt>VSARG2_ICON</dt><dd>Command allowed when editor 
 * control window is iconized.  
 * Ignored if command does not 
 * require an editor control</dd>
 * 
 * <dt>VSARG2_REQUIRES_EDITORCTL</dt><dd>Command requires an editor 
 * control.</dd>
 * 
 * <dt>VSARG2_REQUIRES_MDI_EDITORCTL</dt><dd>
 * 	Command requires MDI editor 
 * control</dd>
 * 
 * <dt>VSARG2_REQUIRES_AB_SELECTION</dt><dd>
 * 	Command requires selection in 
 * active buffer.</dd>
 * 
 * <dt>VSARG2_REQUIRES_BLOCK_SELECTION</dt><dd>
 * 	Command requires block/column 
 * selection in any buffer</dd>
 * 
 * <dt>VSARG2_REQUIRES_CLIPBOARD</dt><dd>Command requires editor control 
 * clipboard</dd>
 * 
 * <dt>VSARG2_REQUIRES_FILEMAN_MODE</dt><dd>
 * 	Command requires active buffer 
 * to be in fileman mode.</dd>
 * 
 * <dt>VSARG2_REQUIRES_TAGGING</dt><dd>Command requires 
 * <ext>_proc_search/find-tag 
 * support.</dd>
 *  
 * <dt>VSARG2_REQUIRES_SELECTION</dt><dd>Command requires a selection in 
 * any buffer.</dd>
 * 
 * <dt>VSARG2_REQUIRES_MDI</dt><dd>Command requires MDI interface 
 * may be because it opens a new 
 * file or uses _mdi object. 
 * Commands with this attribute are 
 * removed from pop-up menus 
 * which the MDI interface is not 
 * available (editor control OEMs).</dd>
 * </dl>
 *
 * @param pfn (optional) Pointer to function.
 * For DLL functions, this is optional if the real function 
 * name is the same as the exported function name.
 * This is required for functions that are not exported
 * by your DLL or for functions in vsapi.dll.
 * 
 * @example
 * <pre>
 * 	    static int VSAPI MyCommand()
 * 	    {
 * 	          vsMessageBox("Got here");
 * 	    }
 * 	
 * 	    extern "C" int VSAPI vsDllInit()
 * 	    {
 * 	        vsLibExport("_command int MyCommand()", 
 * 	                VSARG_MULTI_FILE,0,
 *                                      MyCommand);
 * 	         // Bind this command to F12
 * 	         vsSetEventTabIndex(
 * 	                vsQDefaultEventTab(),
 * 	                vsEvent2Index(VS_OFFSET_FKEYS +11)  // F12,
 * 	                vsFindIndex("MyCommand", VSTYPE_COMMAND));
 * 	
 * 	    }
 * </pre>
 * 
 * @see vsDllExport
 * 
 * @categories Macro_Programming_Functions
 * 
 */ 
int VSAPI vsLibExport(const char *func_proto_p,const char *name_info_p,int arg2,void *pfn);

/**
 * Macro for calling {@link vsLibExport} and type-checking the function 
 * pointer that is passed in. 
 */
#define VS_LIB_EXPORT(return_type,func_name,arg_list,name_info_p,arg2,pfn) \
        vsLibExport(#return_type " " func_name#arg_list, \
                    name_info_p, arg2, \
                    (void*)static_cast<return_type (VSAPI *) arg_list>(pfn))
   
/**
 * <p>Registers a DLL command or function that can be called from the 
 * Slick-C&reg; macro.  See simple.c for a complete example.  DLL 
 * commands may be invoked from the command line or bound to a key.</p>
 * 
 * <p>The syntax for <i>pszFuncProto</i> is:<br>
 * 
 * [_command] [<i>return-type</i>] [<i>dllname</i>:]<i>func-
 * name</i>([<i>type</i> [<i>var-name</i>] [, <i>type</i> [<i>var-
 * name</i>]]...])
 * </p>
 *
 * <p>The address of the function is looked up using a shared 
 * library find function, using the <i>func_name</i> declared in
 * the prototype.  If the function is exported using a different
 * name, then you should use {@link vsLibExport}, which allows
 * you to pass in a pointer to the actual function.
 * 
 * @return Returns 0 if successful.  Otherwise a non-zero error code is returned.
 * 
 * @param func-name is the name of the DLL function to be registered.  
 * <i>dllname</i> is optional and indicates the name of the DLL which 
 * contains the function.  Currently the function names are case 
 * insensitive.
 * 
 * @param type may be one of the following:
 * 
 * <dl>
 * <dt>VSPSZ</dt><dd>NULL terminated string</dd>
 * <dt>VSPLSTR</dt><dd>See typedef in "vsapi.h".</dd>
 * <dt>int</dt>
 * <dt>long</dt>
 * <dt>VSHVAR</dt><dd>Handle to interpreter variable</dd>
 * <dt>VSHREFVAR</dt><dd>Call by reference handle to interpreter 
 * variable.  This type can be used as input to 
 * functions which accept VSHVAR parameters.</dd>
 * </dl>
 * 
 * @param pszNameInfo specifies completion for arguments to a 
 * command.  A '*' character may be appended to the end of a completion 
 * constant to indicate that one or more of the arguments may be entered.  
 * One or more of the follow string completion constants separated with 
 * spaces may be specified:
 * 
 * <dl> 
 * <dt>VSARG_FILE</dt><dd>One filename</dd>
 * <dt>VSARG_MULTI_FILE</dt><dd>Multiple filenames</dd>
 * <dt>VSARG_BUFFER</dt><dd>Buffer name</dd>
 * <dt>VSARG_COMMAND</dt><dd>Slick-C&reg; command 
 * function</dd>
 * <dt>VSARG_PICTURE</dt><dd>Already loaded picture</dd>
 * <dt>VSARG_FORM</dt><dd>Dialog box template</dd>
 * <dt>VSARG_MODULE</dt><dd>Loaded Slick-C&reg; module</dd>
 * <dt>VSARG_MACRO</dt><dd>User recorded Slick-C&reg; 
 * command function</dd>
 * <dt>VSARG_MACROTAG</dt><dd>Slick-C&reg; tag name</dd>
 * <dt>VSARG_VAR</dt><dd>Slick-C&reg; global variable</dd>
 * <dt>VSARG_ENV</dt><dd>Environment variable</dd>
 * <dt>VSARG_MENU</dt><dd>Menu name</dd>
 * <dt>VSARG_TAG</dt><dd>Tag name</dd>
 * </dl>
 * 
 * @param arg2 is zero or more of the following flags which specify when 
 * the command should be enabled/disabled and a few other things:
 * 
 * <dl>
 * <dt>VSARG2_CMDLINE</dt><dd>Command supports the command 
 * line.</dd>
 * 
 * <dt>VSARG2_CMDLINE</dt><dd>allows a 
 * fundamental mode key binding to 
 * be inherited by the command line</dd>
 * 
 * <dt>VSARG2_MARK</dt><dd>ON_SELECT event should pass 
 * control on to this command and 
 * not deselect text first.
 * Ignored if command does not require an editor control</dd>
 * 
 * <dt>VSARG2_QUOTE</dt><dd>Indicates that this command must 
 * be quoted when called during 
 * macro recording.  Needed only if 
 * command name is an invalid 
 * identifier or keyword.</dd>
 * 
 * <dt>VSARG2_LASTKEY</dt><dd>Command requires last_event 
 * value to be set when called during 
 * macro recording.</dd>
 * 
 * <dt>VSARG2_MACRO</dt><dd>This is a recorded macro 
 * command. Used for completion.</dd>
 * 
 * <dt>VSARG2_TEXT_BOX</dt><dd>Command supports any text box 
 * control. VSARG2_TEXT_BOX 
 * allows a fundamental mode  key 
 * binding to be inherited by a text 
 * box</dd>
 * 
 * <dt>VSARG2_NOEXIT_SCROLL</dt><dd>Do not exit scroll caused by using 
 * scroll bars. Ignored if command 
 * does not require an editor control.</dd>
 * 
 * <dt>VSARG2_EDITORCTL</dt><dd>Command allowed in editor 
 * control. VSARG2_EDITORCTL 
 * allows a fundamental mode key 
 * binding to be inherited by a non-
 * MDI editor control</dd>
 * 
 * <dt>VSARG2_NOUNDOS</dt><dd>Do not automatically call 
 * _undo('s').  Require macro to call 
 * _undo('s') to start a new level of 
 * undo.</dd>
 * 
 * <dt>VSARG2_READ_ONLY</dt><dd>Command allowed when editor 
 * control is in strict read only mode. 
 * Ignored if command does not 
 * require an editor control
 * <dt>VSARG2_ICON	Command allowed when editor 
 * control window is iconized.  
 * Ignored if command does not 
 * require an editor control</dd>
 * 
 * <dt>VSARG2_REQUIRES_EDITORCTL</dt><dd>Command requires an editor 
 * control.</dd>
 * 
 * <dt>VSARG2_REQUIRES_MDI_EDITORCTL</dt><dd>
 * 	Command requires MDI editor 
 * control</dd>
 * 
 * <dt>VSARG2_REQUIRES_AB_SELECTION</dt><dd>
 * 	Command requires selection in 
 * active buffer.</dd>
 * 
 * <dt>VSARG2_REQUIRES_BLOCK_SELECTION</dt><dd>
 * 	Command requires block/column 
 * selection in any buffer</dd>
 * 
 * <dt>VSARG2_REQUIRES_CLIPBOARD</dt><dd>Command requires editor control 
 * clipboard</dd>
 * 
 * <dt>VSARG2_REQUIRES_FILEMAN_MODE</dt><dd>
 * 	Command requires active buffer 
 * to be in fileman mode.</dd>
 * 
 * <dt>VSARG2_REQUIRES_TAGGING</dt><dd>Command requires 
 * <ext>_proc_search/find-tag 
 * support.</dd>
 * 
 * <dt>VSARG2_REQUIRES_SELECTION</dt><dd>Command requires a selection in 
 * any buffer.</dd>
 * 
 * <dt>VSARG2_REQUIRES_MDI</dt><dd>Command requires MDI interface 
 * may be because it opens a new 
 * file or uses _mdi object. 
 * Commands with this attribute are 
 * removed from pop-up menus 
 * which the MDI interface is not 
 * available (editor control OEMs).</dd>
 * </dl>
 * 
 * @param return-type may be one of the following
 * 
 * <ul>
 * <li>VSPSZ</li>
 * <li>VSPLSTR</li>
 * <li>int</li>
 * <li>long</li>
 * <li>void</li>
 * </ul>
 * 
 * <p>If the _command keyword is specified, the DLL function may be 
 * bound to a key or executed from the command line.  Otherwise, the 
 * only way to call the function is to call it from a Slick-C&reg; macro.</p>
 * 
 * <p>Performance considerations:  For best performance, use the VSHVAR 
 * or VSREFVAR parameter type when operating on long strings instead 
 * of VSPSZ or VSPLSTR.  Then use the <b>vsHvarGetLstr</b> 
 * function to return a pointer to the interpreter variable. WARNING:  
 * Pointers to interpreter variables returned by the 
 * <b>vsHvarGetLstr</b> function are NOT VALID after any interpreter 
 * variable is set.  Be sure to reset any pointer after setting other 
 * interpreter variables or calling other macros. You may modify the 
 * contents of the VSPLSTR pointer returned by <b>vsHvarGetLstr</b> 
 * so long as you do not make the string any longer.  We suspect that 
 * using the int and long parameter types are no slower than using the 
 * VSHVAR type and converting the parameter yourself.</p>
 * 
 * @examples
 * <pre>
 * 	    vsDllExport("_command int JustLikeEdit(VSPSZ pszFilenames)", 
 * VSARG_MULTI_FILE,
 * 	VSARG2_CMDLINE|VSARG2_REQUIRES_MDI);
 * 	    vsDllExport("_command void MultiComplete(VSPSZ pszFilename, 
 * VSPSZ pszEnvVar)",
 * 	          VSARG_FILE" "VSARG_ENV, 0);
 * </pre>
 * 
 * @see vsLibExport
 * 
 * @categories Macro_Programming_Functions
 * 
 */ 
int VSAPI vsDllExport(const char *pszFuncProto,const char *pszNameInfo,int arg2);

/**
 * <p>Returns the Windows DLL module handle or Unix dlopen 
 * module handle. 
 *  
 * <p>This function should only be called in vsDLLInit.
 * 
 * 
 * @see vsLibExport 
 * @see vsDLLExport
 * 
 * @categories Macro_Programming_Functions
 * 
 */ 
void *VSAPI vsDllGetModuleHandleFromInit();
/**
 * @return Test if the given property is safe to get for the 
 *         given window ID without causing the interpreter to
 *         throw an error.  Returns 0 if ok, <0 if not safe.
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id	One of the VSP_??? constants in "vs.h". 
 *  
 * @param object_id   One of the VSOI_??? constants in "vs.h" 
 *                    Ignored unless window_id==0 
 *  
 * @example
 * <pre>
 * 	    int col;
 *        col=vsPropTest(0,VSP_COL);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsPropTest(int wid,int prop_id,int object_id=0);
/**
 * @return Returns value of integer property.
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id	One of the VSP_??? constants in "vs.h".
 * 
 * @example
 * <pre>
 * 	    int col;
 * 	    col=vsPropGetI(0,VSP_COL);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsPropGetI(int wid,int prop_id);
/**
 * @return Returns value of integer property as a 64-bit integer
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id	One of the VSP_??? constants in "vs.h".
 * 
 * @example
 * <pre>
 * 	    VSINT64 col;
 * 	    col=vsPropGetI64(0,VSP_FILE_DATE);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
VSINT64 VSAPI vsPropGetI64(int wid,int prop_id);
/** 
 * @return Returns value of an VSHVAR property. 
 *         This can only be used with VSP_USER, VSP_USER2,
 *         and VSP_EMBEDDED_ORIG_VALUES.
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id	VSP_USER, VSP_USER2, or 
 *                VSP_EMBEDDED_ORIG_VALUES
 * 
 * @example
 * <pre>
 * 	    int col;
 *        col=vsPropGetHvar(0,VSP_USER);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 * @return Returns the value of an VSHVAR property.
 * 
 * @param wid
 * @param prop_id
 * 
 * @return int VSAPI
 */
VSHVAR VSAPI vsPropGetHvar(int wid,int prop_id);
/**
 * Copies string value of property into <i>pszValue</i>.  The returned 
 * string is always null terminated.  No more than <i>BufLen</i> 
 * characters are copied.
 * 
 * @return Returns number of characters copied
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id	One of the VSP_??? constants in "vs.h".
 * 
 * @param pszValue	Ouput buffer for null terminate string.  This 
 * can be 0.
 * 
 * @param BufLen	Number of characters allocated to 
 * <i>pszValue</i>.
 * 
 * @param pBufLen	If this is not 0, this is set to the number of 
 * characters you need to allocate to 
 * <i>pBufLen</i>.
 * 
 * @example
 * <pre>
 * 	    int len;
 * 	    char bufname[100];
 * 
 * 	    len=vsPropGetZ(0,VSP_BUFNAME,bufname,100);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsPropGetZ(int wid,int prop_id,char *pszValue,int ValueLen,int *pValueLen VSDEFAULT(0));
/**
 * Copies string value of property into <i>pBuf</i>.  No more than 
 * <i>BufLen</i> bytes are copied.
 * 
 * @return Returns number of bytes copied
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id	One of the VSP_??? constants in "vs.h".
 * <i>pBuf</i>	Output buffer for string value.  Buffer is not 
 * null terminated.  This can be 0.
 * 
 * @param BufLen	Number of bytes allocated to <i>pBuf</i>.
 * 
 * @param pBufLen	If  this is not 0, this is set to the number of 
 * characters you need to allocate to 
 * <i>pBuf</i>.
 * 
 * @example
 * <pre>
 * 	    int len;
 * 	    char bufname[100];
 * 
 * 	    len=vsPropGetB(0,VSP_BUFNAME,bufname,100);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
int VSAPI vsPropGetB(int wid,int prop_id,void *pBuf,int BufLen,int *pBufLen VSDEFAULT(0));

/**
 * Sets value of integer property to <i>value</i>.  For documentation on 
 * the properties, you must translate the VSP_??? constants into the 
 * Slick-C&reg; property name.  For example, VSP_BUFNAME corresponds 
 * to <b>p_buf_name</b> and VSP_LINE corresponds to 
 * <b>p_line</b>.
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id  One of the VSP_??? constants in "vs.h".
 * 
 * @param value	New value for property.
 * 
 * @example
 * <pre>
 * 	    // Go to line 5 in current buffer
 * 	    vsPropSetI64(0,VSP_LINE,5);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void VSAPI vsPropSetI(int wid,int prop_id,int value);
/**
 * Sets value of a 64-bit integer property to <i>value</i>.  For documentation 
 * on the properties, you must translate the VSP_??? constants into the 
 * Slick-C&reg; property name.  For example, VSP_BUFNAME corresponds 
 * to <b>p_buf_name</b> and VSP_LINE corresponds to 
 * <b>p_line</b>.
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id  One of the VSP_??? constants in "vs.h".
 * 
 * @param value	New value for property.
 * 
 * @example
 * <pre>
 * 	    // Go to line 5 in current buffer
 * 	    vsPropSetI64(0,VSP_LINE,5);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void VSAPI vsPropSetI64(int wid,int prop_id,VSINT64 value);
/**
 * Sets value of VSHVAR property to <i>hvar</i>. 
 * This can only be used with VSP_USER, VSP_USER2, and 
 * VSP_EMBEDDED_ORIG_VALUES. 
 *  
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id	VSP_USER, VSP_USER2, or 
 *                VSP_EMBEDDED_ORIG_VALUES
 *  
 * @param hvar    New value for property. 
 * 
 * @example
 * <pre>
 * 	    // Go to line 5 in current buffer
 *        vsPropSetHvar(0,VSP_LINE,hvar);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 */ 
void VSAPI vsPropSetHvar(int wid,int prop_id,VSHVAR hvar);
/**
 * Sets value of string property to <i>pszValue</i>.
 * 
 * @param wid	Window id of object.  0 specifies the current 
 * object.
 * 
 * @param prop_id	One of the VSP_??? constants in "vs.h".
 * 
 * @param pszValue	New value for property.
 * 
 * @example
 * <pre>
 * 	    vsPropSetZ(0,VSP_BUFNAME,"c:\\autoexec.bat");
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void VSAPI vsPropSetZ(int wid,int prop_id,const char *pszValue);

/**
 * Sets value of string property to <i>pBuf</i>.  For documentation on 
 * the properties, you must translate the VSP_??? constants into the 
 * Slick-C&reg; property name.  For example, VSP_BUFNAME corresponds 
 * to <b>p_buf_name</b> and VSP_LINE corresponds to 
 * <b>p_line</b>.
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id	One of the VSP_??? constants in "vs.h".
 * 
 * @param pBuf	Buffer containing new value.
 * 
 * @param BufLen	Number of charactes to copy from 
 * <i>pBuf</i>.
 * 
 * @example
 * <pre>
 * 	    vsPropSetB(0,VSP_BUFNAME,"c:\\autoexec.bat",15);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void VSAPI vsPropSetB(int wid,int prop_id,const void *pBuf,int BufLen);

/**
 * Opens the file specified with access specified by <i>option</i>.
 * 
 * @return If successful, a handle to file which may be used by other vsFilexxx 
 * functions.  Otherwise a negative error code is returned.
 * 
 * @param option may be one of the following.
 * 
 * <dl>
 * <dt>0</dt><dd>Open file for shared reading.</dd>
 * 
 * <dt>1</dt><dd>Open file for writing.  File is created if it does not 
 * exist.  File is truncated.</dd>
 * 
 * <dt>2</dt><dd>Open file for reading (read shared) and writing.  
 * File is created if it does not exist.  File is truncated.</dd>
 * 
 * <dt>3</dt><dd>Open file for reading (read shared) and writing.  
 * FILE_NOT_FOUND_RC is returned if the file does 
 * not exist.  File is NOT truncated.</dd>
 * 
 * <p>UNIX, unfortunately does not support sharing.  On UNIX it is possible 
 * for the compiler to be reading a file that you are writing to.</p>
 * 
 * @see vsFileOpen
 * @see vsFileClose
 * @see vsFileRead
 * @see vsFileWrite
 * @see vsFileSeek
 * @see vsFileMove
 * 
 * @categories File_Functions
 * 
 */ 
int VSAPI vsFileOpen(const char *pszFilename,int option);
/**
 * Closes the file handle <i>fh</i>.  <i>fh</i> must have been returned 
 * by <b>vsFileOpen</b>.
 * 
 * @return Returns 0 if successful.
 * 
 * @see vsFileOpen
 * @see vsFileClose
 * @see vsFileRead
 * @see vsFileWrite
 * @see vsFileSeek
 * @see vsFileMove
 * 
 * @categories File_Functions
 * 
 */ 
int VSAPI vsFileClose(int fh);
/**
 * Reads number of bytes specified by <i>BufLen</i> into <i>pBuf</i>.
 * 
 * @return If successful, the number of bytes read is returned.  Otherwise a 
 * negative error code is returned.
 * 
 * @see vsFileOpen
 * @see vsFileClose
 * @see vsFileRead
 * @see vsFileWrite
 * @see vsFileSeek
 * @see vsFileMove
 * 
 * @categories File_Functions
 * 
 */ 
int VSAPI vsFileRead(int fh,void *pBuf,int BufLen);
/**
 * Write number of bytes specified by <i>BufLen</i> to the file 
 * specified by <i>fh</i>.  <i>pBuf</i> points to the data to be written.
 * 
 * @return If successful, the number of bytes written is returned.  Otherwise a 
 * negative error code is returned.
 * 
 * @see vsFileOpen
 * @see vsFileClose
 * @see vsFileRead
 * @see vsFileWrite
 * @see vsFileSeek
 * @see vsFileMove
 * 
 * @categories File_Functions
 * 
 */ 
int VSAPI vsFileWrite(int fh,const void *pBuf,int BufLen);
/**
 * Changes the file position for the file specified by <i>fh</i>.
 * 
 * @return If successful, the new seek position is returned.  Otherwise a negative 
 * error code is returned.
 * 
 * @param option changes the meaning of <i>SeekPos</i> as follows:
 * 
 * <dl>
 * <dt>0</dt><dd>SeekPos is absolute position.</dd>
 * <dt>1</dt><dd>SeekPos is relative to current position.</dd>
 * <dt>2</dt><dd>SeekPos is relative to end of file.</dd>
 * </dl>
 * 
 * @see vsFileOpen
 * @see vsFileClose
 * @see vsFileRead
 * @see vsFileWrite
 * @see vsFileSeek
 * @see vsFileMove
 * 
 * @categories File_Functions
 * 
 */ 
VSINT64 VSAPI vsFileSeek(int fh,VSINT64 seekpos,int option);
/**
 * Forces the operating system to flush cached file data to disk.
 * 
 * @return Returns 0 if successful.
 * 
 * @see vsFileOpen
 * @see vsFileClose
 * @see vsFileRead
 * @see vsFileWrite
 * @see vsFileSeek
 * @see vsFileMove
 * 
 * @categories File_Functions
 * 
 */ 
int VSAPI vsFileFlush(int fh);

/**
 * Load the contents of a file into a slickedit::SEString 
 *  
 * @param fileName      Name/path for file to load 
 * @param fileContents  (output) set to contents of file 
 * @param preserveEOF   Preserve the trailing EOF character (if any) 
 * @param sizeLimit     if > 0 this is a limit on the size of the file to load 
 * @param autoEncoding  (default 0) by default the file encoding is ignored and 
 *                      the raw contents of the file is loaded.  Otherwise, this
 *                      is one of the VSENCODING_AUTO* flags used to determine
 *                      the given files encoding.  The contents of the file are
 *                      then converted to UTF8 on file load. 
 *  
 * @return 0 on success, <0 on error. 
 */
int VSAPI vsFileLoad(const slickedit::SEString &fileName,
                     slickedit::SEString &fileContents, 
                     bool preserveEOF=false, 
                     size_t sizeLimit=0,
                     int autoEncoding=0);

/**
 * Renames the file specified.  This function will fail if the destination 
 * file exists or the destionation path is on a different drive or file system.
 * 
 * @return Returns 0 if successful.
 * 
 * @param pszDestFilename	New name for file.
 * 
 * @param pszSrcFilename	Existing name of file.
 * 
 * @see vsFileOpen
 * @see vsFileClose
 * @see vsFileRead
 * @see vsFileWrite
 * @see vsFileSeek
 * @see vsFileMove
 * 
 * @categories File_Functions
 * 
 */ 
int VSAPI vsFileMove(const char *pszDestFilename,const char *pszSrcFilename);


#define VSTYPE_PROC      0x1
#define VSTYPE_VAR       0x4
#define VSTYPE_EVENTTAB  0x8
#define VSTYPE_COMMAND   0x10
#define VSTYPE_GVAR      0x20
#define VSTYPE_GPROC     0x40
#define VSTYPE_MODULE    0x80
#define VSTYPE_PICTURE   0x100
#define VSTYPE_BUFFER    0x200
#define VSTYPE_OBJECT    0x400
#define VSTYPEC_OBJECTMASK    0xf800
#define VSTYPEC_OBJECTSHIFT   11
#define VSTYPE_INFO      0x10000
#define VSTYPE_STRUCT    0x20000
#define VSTYPE_DLLCALL   0x40000   /* Entries with this flag MUST also have the
                                      VSTYPE_COMMAND or VSTYPE_PROC flag. */
#define VSTYPE_DLLMODULE 0x80000
#define VSTYPE_ENUM      0x400000
#define VSTYPE_CLASS     0x800000
#define VSTYPE_INTERFACE 0x1000000
#define VSTYPE_NAMESPACE 0x2000000
#define VSTYPE_CONST     0x4000000
#define VSTYPE_MISC      0x20000000
#define VSTYPE_BUILT_IN  0x40000000

#define vsoi2type(oi) (VSTYPE_OBJECT|(oi<<VSTYPEC_OBJECTSHIFT))


/**
 * This function is used to set command function attributes or user 
 * defined additional name information.
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @return Returns 0 if successful.
 * 
 * @param index	Index into names table of item.
 * 
 * @param pInfo	New name information string.
 * 
 * @param InfoLen Number of characters in <i>pInfo</i>.  -1 
 * means <i>pInfo</i> is null terminated.
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
int VSAPI vsNameSetInfo(int index,const char *pInfo,int InfoLen VSDEFAULT( -1));
/**
 * This function is used to get command function attributes or user 
 * defined additional name information.
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @return Returns name table index to <i>pszName</i> of one of the types 
 * specified by <i>flags</i>. 0 is returned if a match is not found.  A 
 * name type match is considered if  (<i>flags</i> & 
 * <b>vsNameType</b>(<i>index</i>)) is true.  Search is not case 
 * sensitive except for names of type VSTYPE_PICTURE and 
 * VSTYPE_MODULE under UNIX.  All underscore characters in 
 * <i>name</i> are converted to dash characters before searching takes 
 * place except for names of type VSTYPE_PICTURE or 
 * VSTYPE_MODULE.  The name type flags are listed in the file "vs.h".
 * 
 * @param pszName	Name to find.
 * 
 * @param flags	One or more of the VSTYPE_??? flags Ored 
 * together.
 * 
 * <dl> 
 * <dt>VSTYPE_PROC</dt><dd>Matches function</dd>
 * <dt>VSTYPE_VAR</dt><dd>Matches variable</dd>
 * <dt>VSTYPE_EVENTTAB</dt><dd>Matches event table</dd>
 * <dt>VSTYPE_COMMAND</dt><dd>Matches command</dd>
 * <dt>VSTYPE_CLASS</dt><dd>Matches class name
 * <dt>VSTYPE_INTERFACE</dt><dd>Matches interface name
 * <dt>VSTYPE_STRUCT</dt><dd>Matches struct name
 * <dt>VSTYPE_CONST</dt><dd>Matches const name
 * <dt>VSTYPE_ENUM</dt><dd>Matches enumerated type
 * <dt>VSTYPE_MODULE</dt><dd>Matches module</dd>
 * <dt>VSTYPE_PICTURE</dt><dd>Matches picture.</dd>
 * <dt>VSTYPE_CLASS</dt><dd>Matches any Slick-C&reg; class type name
 * <dt>VSTYPE_OBJECT</dt><dd>Matches any type of dialog box template.
 * Use 
 * vsoi2type(VSOI_???) to 
 * find a specific type of 
 * object.</dd>
 * <dt>VSTYPE_MISC</dt><dd>Matches miscellaneous.</dd>
 * </dl>
 * 
 * @param pszInfo	Output buffer for name information string.  
 * This can be 0.
 * 
 * @param MaxInfoLen	Number of characters allocated to 
 * <i>pszInfo</i>.  We recommend 
 * VSMAXNAMEINFO.
 * 
 * @param pMaxInfoLen	If this is not 0, this is set to the number of 
 * characters you need to allocate to 
 * <i>pszInfo</i>.
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
 * @see vsNameSetInfo 
 * 
 * @categories Names_Table_Functions
 */ 
int VSAPI vsFindNameInfo(const char *pszName, int flags, int *pKind,
                         char *pszInfo,int MaxInfoLen,int *pMaxInfoLen VSDEFAULT(0));

/**
 * This function is used to set command function attributes or 
 * user defined additional name information. 
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @return Returns name table index to <i>pszName</i> of one of the types 
 * specified by <i>flags</i>. A name type match is considered if 
 * (<i>flags</i> & <b>vsNameType</b>(<i>index</i>)) is true. 
 * Search is not case sensitive except for names of type 
 * VSTYPE_PICTURE and VSTYPE_MODULE under UNIX.  All underscore 
 * characters in <i>name</i> are converted to dash characters 
 * before searching takes place except for names of type 
 * VSTYPE_PICTURE or VSTYPE_MODULE.  The name type flags are 
 * listed in the file "vs.h". 
 *  
 * If no match is found, a new entry is added. 
 * 
 * @param pszName	Name to set
 * 
 * @param flags	One or more of the VSTYPE_??? flags Ored 
 * together.
 * 
 * @param pszInfo       Value of name info
 * 
 * @return int 
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
 * @see vsFindNameInfo 
 * 
 * @categories Names_Table_Functions
 */
int VSAPI vsSetNameInfo(const char *pszName, int flags, const char *pszInfo);

/**
 * This function is used to get command function attributes or user 
 * defined additional name information.
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @return Returns <i>pszInfo</i>.
 * 
 * @param index	Index into names table of item.
 * 
 * @param pszInfo	Output buffer for name information string.  
 * This can be 0.
 * 
 * @param MaxInfoLen	Number of characters allocated to 
 * <i>pszInfo</i>.  We recommend 
 * VSMAXNAMEINFO.
 * 
 * @param pMaxInfoLen	If this is not 0, this is set to the number of 
 * characters you need to allocate to 
 * <i>pszInfo</i>.
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
char *VSAPI vsNameInfo(int index,char *pszInfo,int MaxInfoLen,int *pMaxInfoLen VSDEFAULT(0));

/**
 * @return Returns name table type flags for index.
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @param index	Index into names table of item.
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
int VSAPI vsNameType(int index);
/**
 * @return Returns index into the name table of the module to which the 
 * procedure or command, corresponding to <i>index,</i> is linked.  If 
 * <i>index</i> is invalid or does not correspond to a procedure or 
 * command, 0 is returned.
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @example
 * <pre>
 * 	      index=vsFindIndex("upcase_filter");
 * 	      if (!vsNameCallable(index) ) {
 * 	           vsMessage("upcase_filter name in not in names table or not 
 * linked");
 * 	      } else {
 * 	           vsMessage("upcase_filter is defined and callable");
 * 	      }
 * </pre>
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
int VSAPI vsNameCallable(int index);
/**
 * @return Returns address of function.  0 is returned if index is not valid or can 
 * not be resolved.
 *  
 * @attention 
 * This function is thread-safe. 
 *  
 * @param index	Index into names table of global function.
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
void *VSAPI vsNameDllAddr(int index);
/**
 * @return Returns pszName.
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @param index	Index into names table of item.
 * 
 * @param pszName	Output buffer to receive name of names 
 * table item. This can be 0.
 * 
 * @param MaxNameLen	Number of characters allocated to 
 * <i>psName</i>.  We recommend 
 * VSMAXNAME.
 * 
 * @param pMaxNameLen	If this is not 0, this is set to the number of 
 * characters you need to allocate.
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
char *VSAPI vsNameName(int index,char *pszName,int MaxNameLen,int *pMaxNameLen VSDEFAULT(0));
/**
 * This function creates a new names table item. 
 *
 * @return If successful, the index of new names table item is 
 * returned. Otherwise, a negative error code is returned.  0 is 
 * never returned. 
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @param pszName	Name for new names table item.  For 
 *                kind==VSTYPE_PICTURE, <code>pszName</code> is
 *                the filename of a ".bmp", ".ico", ".png", or
 *                ".xpm" file whose path will be stripped off.
 *                Your picture should start with an "_" (ex.
 *                "c:\slickedit\_ed_stack.svg") to indicate
 *                that your bitmap is global. Otherwise when the
 *                configuration is written your bitmap will get
 *                deleted if it is not attatched to a
 *                Slick-C&reg; dialog box.
 * 
 * @param kind	Type of new names table item.  May be 
 * VSTYPE_MISC, VSTYPE_PICTURE, 
 * VSTYPE_EVENTTAB, or 
 * VSTYPE_MENU.
 * 
 * @param pszInfo	Optional name information for new names 
 * table item.  Use <b>vsNameInfo</b> 
 * function to retrieve this information later.
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
int VSAPI vsNameInsert(const char *pszName,int kind,const char *pszInfo VSDEFAULT(0),int reserved VSDEFAULT(0));
/** 
 * Delete the names table entry with the given index. 
 *  
 * @param index	Index into names table of item to delete.  For 
 * safety, Slick-C&reg; functions or DLL functions 
 * which have explicit calls from Slick-C&reg; are 
 * not removed.  In addition, variables 
 * (VSTYPE_VAR) and modules 
 * (VSTYPE_MODULE) may not be deleted.
 * Removes name entry corresponding to name table <i>index</i>.
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
void VSAPI vsNameDelete(int index,int reserved VSDEFAULT(0));
/**
 * @return If successful, returns index.  Otherwise a negative error code is 
 * returned.
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @param index	Index into names table of item.
 * 
 * @param pszName	New name.
 * 
 * @param pszInfo	Optional new name information.  If null, 
 * current name information is preserved.
 * This function is used to rename a names table item.
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
int VSAPI vsNameReplace(int index,const char *pszName,const char *pszInfo VSDEFAULT(0),int reserved VSDEFAULT(0));
/**
 * @return Returns name table <i>index</i> of the name with prefix matching 
 * <i>pszNamePrefix</i> and where (<i>flags</i> & 
 * name_type(<i>index</i>)) is true.  A non-zero value for 
 * <i>find_first</i>, begins a new search.  If <i>find_first</i> is zero, 
 * the next matching index is returned. 0 is returned  if no match is 
 * found.  Search is case sensitive unless one of the flags 
 * VSTYPE_MODULE, VSTYPE_PICTURE, or 
 * VSTYPE_IGNORECASE is given.  When one of the flags 
 * VSTYPE_MODULE or VSTYPE_PICTURE is given, search is case 
 * sensitive for file systems like UNIX which is case sensitive.  The 
 * search is always case insensitive when the VSTYPE_IGNORECASE 
 * flag is given.  Underscores in <i>pszName</i> are translated to dashes 
 * before search takes place unless VSTYPE_PICTURE or 
 * VSTYPE_MODULE is specified.
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @param pszNamePrefix 	Find names matching this prefix.
 * 
 * @param start	Specify 0 to search for the first match.   
 * Then use the return value of this function to 
 * search for the next match.
 * 
 * @param flags	One or more of the VSTYPE_??? flags Ored 
 * together.
 * 
 * @example
 * <pre>
 * 	      flags= VSTYPE_COMMAND;
 * 	      char *pszNamePrefix="p"; // Find names that start with p
 * 	      int index;
 * 	      index= vsNameMatch(pszNamePrefix,0,flags);   // Find first
 * 	      // Press Ctrl-Break to break a macro during a messageNwait
 * 	      for (int i=0;i<10;++i) {  // Only display first 10.
 * 	          if (!index ) break;
 * 	          char temps[1024];
 * 	          vsMessageBox(vsNameName(index,temps,1024));
 * 	          index= vsNameMatch(pszNamePrefix,index,flags) // Find next
 * 	      }
 * </pre>
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
int VSAPI vsNameMatch(const char *pszNamePrefix,int start,int flags);
/**
 * @return Returns name table index to <i>pszName</i> of one of the types 
 * specified by <i>flags</i>. 0 is returned if a match is not found.  A 
 * name type match is considered if  (<i>flags</i> & 
 * <b>vsNameType</b>(<i>index</i>)) is true.  Search is not case 
 * sensitive except for names of type VSTYPE_PICTURE and 
 * VSTYPE_MODULE under UNIX.  All underscore characters in 
 * <i>name</i> are converted to dash characters before searching takes 
 * place except for names of type VSTYPE_PICTURE or 
 * VSTYPE_MODULE.  The name type flags are listed in the file "vs.h".
 * 
 * @attention 
 * This function is thread-safe. 
 *  
 * @param pszName	Name to find.
 * 
 * @param flags	One or more of the VSTYPE_??? flags Ored 
 * together.
 * 
 * <dl> 
 * <dt>VSTYPE_PROC</dt><dd>Matches function</dd>
 * <dt>VSTYPE_VAR</dt><dd>Matches variable</dd>
 * <dt>VSTYPE_EVENTTAB</dt><dd>Matches event table</dd>
 * <dt>VSTYPE_COMMAND</dt><dd>Matches command</dd>
 * <dt>VSTYPE_CLASS</dt><dd>Matches class name
 * <dt>VSTYPE_INTERFACE</dt><dd>Matches interface name
 * <dt>VSTYPE_STRUCT</dt><dd>Matches struct name
 * <dt>VSTYPE_CONST</dt><dd>Matches const name
 * <dt>VSTYPE_ENUM</dt><dd>Matches enumerated type
 * <dt>VSTYPE_MODULE</dt><dd>Matches module</dd>
 * <dt>VSTYPE_PICTURE</dt><dd>Matches picture.</dd>
 * <dt>VSTYPE_CLASS</dt><dd>Matches any Slick-C&reg; class type name
 * <dt>VSTYPE_OBJECT</dt><dd>Matches any type of dialog box template.
 * Use 
 * vsoi2type(VSOI_???) to 
 * find a specific type of 
 * object.</dd>
 * <dt>VSTYPE_MISC</dt><dd>Matches miscellaneous.</dd>
 * </dl>
 * 
 * @example
 * <pre>
 * 	    int index=vsFindIndex("form1",vsoi2type(VSOI_FORM));
 * </pre>
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
 * 
 * @categories Names_Table_Functions
 * 
 */ 
int VSAPI vsFindIndex(const char *pszName,int flags);

/**
 * <p>Calls a Slick-C&reg; function or method corresponding to the names table 
 * <i>index</i> specified with the arguments specified.  Any return 
 * value can be retrieved by accessing the VSHVAR_RC variable handle.   
 * If you want to call a command (Slick-C&reg; <b>_command</b> or DLL 
 * <b>_command</b>) and speed is not an issue, use the more 
 * convenient <b>vsExecute</b> function.  <b>vsCallIndex</b> may be 
 * used to call any registered DLL function.</p>
 * 
 * <p>This function can not be used to call "built-in" Slick-C&reg; function or 
 * method such as <b>_default_option</b> function.  However, you can 
 * write your own Slick-C&reg; function to call a built-in and then use this 
 * function to call it.  To determine if a Slick-C&reg; function is a built-in, try 
 * the using the vsFindIndex function with 
 * VSTYPE_PROC|VSTYPE_COMMAND.  If 0 is returned, the 
 * function is a built-in.</p>
 * 
 * @example
 * <pre>
 *    // Call a Slick-C&reg; function which returns a Slick-C&reg; array or struct
 *    int index;
 *    index=vsFindIndex("ProcReturnsArray ",VSTYPE_PROC);
 *    if (!index) {
 *        vsMessage("not found");
 *        return;
 *    }
 *    VSARGTYPE ArgList[1];
 *    ArgList[0].kind=VSARGTYPE_PSZ;
 *    ArgList[0].u.psz="some * message";
 *    vsCallIndex(0,index,1,ArgList);
 *    // Get first element of array or struct
 *    VSHVAR hvar;
 *    hvar=vsHvarArrayEl(VSHVAR_RC,0);
 *    VSPLSTR  plstr;
 *    // Interpreter L strings are NULL terminated.
 *    plstr=vsHvarGetLstr(hvar);
 *    vsMessage((char *)plstr->str);
 * </pre>
 * 
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsArg
 * @see vsHvarAlloc
 * @see vsHvarFree
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsFindIndex 
 * @see VSARGTYPE 
 * @see VSArgTypeKind 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Miscellaneous_Functions
 */ 
void VSAPI vsCallIndex(int wid,int index,int Nofargs,const VSARGTYPE *pArgList);


/** Load template hidden. */
#define VSLOAD_HIDDEN     0x1     /* H */
/** Used internally by dialog editor. Load template in edit mode. */
#define VSLOAD_EDIT       0x2     /* E */
/**
 * Used internally by _load_template. Ignored by vsLoadTemplate.
 * <p>
 * Load template with ON_CREATE arguments passed
 * on the interpreter stack.
 * <p>
 * Arguments are passed on the intepreter stack
 * (e.g. a call to a Slick-C function with a
 * variable number of arguments). The next argument
 * is the 1-based offset of the first ON_CREATE
 * argument on the stack.
 *
 * @example
 * <pre>
 * _command int show_my_form(_str my_form_name, ...)
 * {
 *    int index = find_index("my_form_name",oi2type(OI_FORM));
 *    int parent_wid = _mdi;  // MDI frame
 *    // arg(1) == cmdline
 *    // ON_CREATE arguments passed to form start at arg(2)
 *    int wid = _load_template(index,parent_wid,'A',2);
 *    return wid;
 * }
 * ...
 * // "my arg1", "my arg2", and "my arg3" are passed as
 * // arguments to the ON_CREATE events for form1.
 * show_my_form("form1","my arg1","my arg2","my arg3");
 * </pre>
 */
#define VSLOAD_ARGPARAMS  0x4     /* A */
/**
 * Reload template with provided wid.
 * <p>
 * Note: The index_or_wid argument passed in to _load_template and vsLoadTemplate
 * is the wid of the object that has already been created, NOT the template index.
 * <p>
 * ON_CREATE, ON_LOAD, ON_RESIZE events are called <b>unless</b>
 * VSLOAD_NOCREATE is also given.
 * <p>
 * Use VSLOAD_REINIT to reset p_user, p_user2, window geometry, default properties.
 */
#define VSLOAD_WINDOW     0x8     /* W */
/**
 * Reinitialize template with provided wid. p_user, p_user2,
 * window geometry, default property values are reset.
 * <p>
 * Note: The index_or_wid argument passed in to _load_template and vsLoadTemplate
 * is the wid of the object that has already been created, NOT the template index.
 */
#define VSLOAD_REINIT     0x10    /* R */
/** Do not call ON_CREATE events for loaded template. This includes ON_LOAD and ON_RESIZE. */
#define VSLOAD_NOCREATE   0x20    /* C */
/** Load template as a child of parent wid. */
#define VSLOAD_CHILDFORM   0x40   /* P */
/** Load template as a child of parent wid and do not draw a border. MUST be used with VSLOAD_CHILDFORM. */
#define VSLOAD_CHILDFORM_NOBORDER   0x80   /* N */
/** Create children of parent. Parent wid must be a handle to the already created parent. */
#define VSLOAD_SKIPPARENT 0x100   /* S */
/**
 * Used internally by _load_template. Ignored by vsLoadTemplate.
 * <p>
 * Load template with ON_CREATE arguments passed as an array.
 * Next argument is the array of ON_CREATE arguments.
 */
#define VSLOAD_ARRAYPARAMS 0x200  /* Y */
/** Use MDI callbacks. Useful for setting status line text when window is not an MDI child. */
#define VSLOAD_USE_MDI_CALLBACKS 0x400  /* M */

#define VSLOAD_TOOLBAR   0x800

/**
 * Used internally by SlickEdit.
 * <p>
 * Load template as a child of MDI client. Parent must be _mdi. Template must be OI_FORM.
 */
#define VSLOAD_MDI_CHILDFORM   0x1000

typedef struct {
   int Nofargs;
#define MAX_VSLOAD_ARGS 24
   VSARGTYPE args[MAX_VSLOAD_ARGS];
} VSLOADDATA;

/**
 * Load a Slick-C resource template by index.
 *  
 * @param index_or_wid Resource template index or window id of 
 *                     already-created object. If VSLOAD_WINDOW
 *                     or VSLOAD_REINIT flags are used, then it
 *                     is the window id of the already-created
 *                     object. Otherwise it is the resource
 *                     template.
 * @param parent       Parent window id.
 * @param flags        Load flags. See VSLOAD_*. 
 * @param pLoadData    Load data. This includes ON_CREATE 
 *                     arguments passed to the ON_CREATE events
 *                     of the resource being loaded. Set to 0 if
 *                     no load data. See VSLOADDATA type.
 * @param x            Initial window geometry that overrides 
 *                     what is stored in the template. Only
 *                     useful when using VSLOAD_MDI_CHILDFORM
 *                     because you cannot create an MDI child
 *                     window hidden, move it, then make it
 *                     visible.
 * @param y 
 * @param width 
 * @param height 
 * @param state        Initial window state. 'N'=Normalized, 
 *                     'M'=Maximized, 'I'=Iconized/minimized.
 *                     Ignored if not using
 *                     VSLOAD_MDI_CHILDFORM.
 * 
 * @return Window id of loaded resource. Returns <0 on error. 
 *  
 * @see vsFindIndex
 * @see VSARGTYPE 
 * @see VSArgTypeKind 
 *  
 * @categories Window_Functions
 */
int VSAPI vsLoadTemplate(int index_or_wid, int parent, int flags, VSLOADDATA* pLoadData,
                         int x VSDEFAULT(-1), int y VSDEFAULT(-1),
                         int width VSDEFAULT(-1), int height VSDEFAULT(-1),
                         int state VSDEFAULT('N'));

/**
 * Calls a Slick-C&reg; function given the function pointer. 
 * 
 * @see VSARGTYPE 
 * @see VSArgTypeKind 
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Miscellaneous_Functions
 */ 
void VSAPI vsCallPtr(int wid,VSCALLPTR *pCallPtr,int Nofargs,const VSARGTYPE *pArgList);

/**
 * @categories Miscellaneous_Functions
 * @param pszName  Name of environment variable to set.
 * @param pszValue Value of variable to set
 * 
 * @return 0 if successful
 * @see vsSetEnv
 * 
 * @categories Miscellaneous_Functions
 * 
 */
int VSAPI vsSetEnv(const char *pszName,const char *pszValue);

/**
 * @return Returns value of environment variable given.  0 is returned if the 
 * environment variable does not exist.
 * 
 * @param pszName	Name of environment variable to retrieve value of.
 * 
 * @see vsSetEnv
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
char * VSAPI vsGetEnv(const char *pszName);

/**
 * Frees memory allocated by the <b>vsAlloc</b> function.  If a NULL 
 * pointer is given, this function does nothing.
 * 
 * @categories Miscellaneous_Functions
 * @param pBuf      Pointer to memory allocated by vsAlloc or vsRealloc.
 * 
 * @see vsAlloc
 * @see vsRealloc
 * 
 */
void VSAPI vsFree(void *pBuf);

/**
 * Allocates memory.  The memory is not initialized with 
 * zeros.  Use the {@link vsFree} function to free memory 
 * allocated by this function.
 * 
 * @param len    Number of bytes to allocated.
 * 
 * @return If successful, returns a pointer to len allocated 
 *         bytes of memory.  Otherwise 0 is returned.
 * @see vsFree
 * @see vsRealloc
 * 
 * @categories Miscellaneous_Functions
 * 
 */
void *VSAPI vsAlloc(size_t len);
/**
 * Reallocates memory.
 * 
 * @param pBuf   Null pointer or pointer allocated by {@link vsAlloc}.
 * @param len    New allocation size for <i>pBuf</i>.
 * 
 * @return If successful, resizes the memory allocated by {@link vsAlloc}
 *         to allow up to <i>len</i> bytes and returns a pointer to the
 *         newly allocated memory.  <i>pBuf</i> may be 0 to allocate new
 *         memory.  Otherwise 0 is returned.  The new memory is
 *         initialized to the previous value if any pointed to by
 *         <i>pBuf</i>.  Use the {@link vsFree} function to free memory allocated
 *         by this function.
 * @see vsFree
 * @see vsAlloc
 * 
 * @see vsFree
 * @see vsAlloc
 * 
 * @categories Miscellaneous_Functions
 * 
 */
void *VSAPI vsRealloc(void *pBuf,size_t len);

/**
 * @return Returns handle to global variable corresponding to the name table 
 * <i>index</i> given.
 * 
 * @param index	Names table index returned by 
 * <b>vsFindIndex</b> or 
 * <b>vsNameMatch</b>.
 * 
 * @example
 * <pre>
 * 	      VSHVAR hvar;
 * 	      VSPLSTR plstr;
 * 	      char buffer[100];
 * 
 * 	      // The rc variable is a global variable which always exists.
 * 	      index=vsFindIndex("rc",VSTYPE_VAR);
 * 	      // Get handle to interpreter variable
 * 	      hvar=vsGetVar(index);
 * 	      // Convert contents of typeless variable into <B>ASCIIZ</B> 
 * buffer.
 * 	      vsZLstrcpy(buffer,vsHvarGetLstr(hvar),100);
 * </pre>
 * 	
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsArg
 * @see vsHvarAlloc
 * @see vsHvarFree
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
VSHVAR VSAPI vsGetVar(int index);

/**
 * @return If <i>ParamNum</i> is zero, the number of parameters passed to the 
 * function are returned.  If <i>ParamNum</i> is greater than the number 
 * of parameters passed to the function, 0 (null VSHVAR) is returned.  
 * Otherwise, a valid VSHVAR is returned corresponding to the 
 * parameter number specified.  A VSHVAR is a handle to an interpreter 
 * typeless variable.  The vsHvar<i>xxx</i> functions can be used to get 
 * VSHVARs.
 * 
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsHvarSetB
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetZ
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
VSHVAR VSAPI vsArg(int ParamNum);

/**
 * Converts VSPLSTR to ASCIIZ string.  No more than <i>DestLen</i> 
 * are written.
 * 
 * @return Returns <i>pszDest</i>.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
char * VSAPI vsZLstrcpy(char *pszDest,VSPLSTR plstrSource,size_t DestLen);


/**
 * @return Returns 0 if the variable specified is valid.  This function frees a 
 * variable allocated by the <b>vsHvarAlloc</b> function.
 * 
 * @example
 * <pre>
 *    int index;
 *    index=vsFindIndex("popup_message",VSTYPE_COMMAND);
 *    if (!index) {
 *        vsMessage("popup_message not found");
 *        return;
 *    }
 *    // Note that we could call the popup_message method by using
 *    // VSARG_PSZ instead of allocating a Slick-C&reg; variable.
 *    VSHVAR hVar;
 *    hVar=vsHvarAlloc(0);
 *    vsHvarSetZ(hVar,"this is a message");
 *    VSARGTYPE ArgList[1];
 *    ArgList[0].kind=VSARGTYPE_HVAR;ArgList[0].u.hVar=hVar;
 *    vsCallIndex(0,index,1,ArgList);
 *    vsHvarFree(hVar);
 * </pre>
 * 	
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarAlloc
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int VSAPI vsHvarFree(VSHVAR hVar);
/**
 * @return Returns a handle to a newly created Slick-C&reg; variable.  You need to 
 * used this function if you want to call a Slick-C&reg; function or method 
 * which takes a call by reference input parameter.  You may also need to 
 * used this function when calling a Slick-C&reg; function or method which 
 * takes a more complex argument type like a Slick-C&reg; array.  If 
 * <i>InitTohVar</i> is non-zero, the returned variable is a copy of the 
 * input variable.  Use <b>vsHvarFree</b> to free a variable allocated by 
 * this function.
 * 
 * @example
 * <pre>
 *    int index;
 *    index=vsFindIndex("popup_message",VSTYPE_COMMAND);
 *    if (!index) {
 *        vsMessage("popup_message not found");
 *        return;
 *    }
 *    // Note that we could call the popup_message method by using
 *    // VSARG_PSZ instead of allocating a Slick-C&reg; variable.
 *    VSHVAR hVar;
 *    hVar=vsHvarAlloc(0);
 *    vsHvarSetZ(hVar,"this is a message");
 *    VSARGTYPE ArgList[1];
 *    ArgList[0].kind=VSARGTYPE_HVAR;ArgList[0].u.hVar=hVar;
 *    vsCallIndex(0,index,1,ArgList);
 *    vsHvarFree(hVar);
 * </pre>
 * 	
 * @see vsHvarGetI
 * @see vsHvarGetI64
 * @see vsHvarSetI
 * @see vsHvarSetI64
 * @see vsHvarSetB
 * @see vsHvarSetZ
 * @see vsHvarGetZ
 * @see vsHvarGetLstr
 * @see vsGetVar
 * @see vsArg
 * @see vsHvarHashtabEl
 * @see vsHvarArrayEl
 * @see vsHvarFree
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
VSHVAR VSAPI vsHvarAlloc(VSHVAR InitTohVar VSDEFAULT(0));

int VSAPI vsHvarGetBool(VSHVAR hVar,bool *pbool);
int VSAPI vsHvarGetI2(VSHVAR hVar,int *pi);
int VSAPI vsHvarIsInt(VSHVAR hVar);
int VSAPI vsHvarSetL(VSHVAR hVar,long i);
long VSAPI vsHvarGetL(VSHVAR hvar);
int VSAPI vsHvarSetLstr(VSHVAR hVar,VSPLSTR plstr);
int VSAPI vsHvarGetCallptr(VSHVAR hvar, VSCALLPTR *pcallptr);



#define VSVF_FREE     0 // Variable is on free list
                        // If you get this, you screwed up with pointers.
#define VSVF_LSTR     2
#define VSVF_INT      3
#define VSVF_ARRAY    4
#define VSVF_HASHTAB  5
#define VSVF_HREFVAR  6 // not normally possible
#define VSVF_PTR      7
#define VSVF_EMPTY    8
#define VSVF_FUNPTR   9
#define VSVF_OBJECT  10 // class instance
#define VSVF_WID     11 // window id
#define VSVF_INT64   12 // 64-bit integer
#define VSVF_DOUBLE  14 // floating point or high-precision number

/**
 * @return Returns variable format of <i>hvar</i>.  One of the VSVF_??? 
 * constants.
 * 
 * @param hvar	Handle to Slick-C&reg; variable.
 * 
 * @categories Macro_Programming_Functions
 */ 
int VSAPI vsHvarFormat(VSHVAR hVar);

int vsShell(const char *pszCommand,const char *pszOptions,const char *pszAltShell);

/**
 * Sets value of long integer property to <i>value</i>.
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id	One of the VSP_??? constants in "vs.h".
 * 
 * @param value	New value for property.
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * @see vsPropGetHWND
 * @see vsPropGetHWNDFrame
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void VSAPI vsPropSetL(int wid,int prop_id,long value);
/**
 * @return Returns value of long integer property.
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * 
 * @param prop_id	One of the VSP_??? constants in "vs.h".
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * @see vsPropGetHWND
 * @see vsPropGetHWNDFrame
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
long VSAPI vsPropGetL(int wid,int prop_id);

/**
 * @return Returns the window handle of the client frame for the given window ID.
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * @param alwaysReturnChildHWND  When false, shell HWND is 
 *                               returned. With Qt, this is
 *                               typically what you want because
 *                               it is unsafe to retrieve a
 *                               child widget HWND because of
 *                               drawing issues that will occur
 *                               afterwards.
 * 
 * @example
 * <pre>
 * 	    HWND hwnd = (HWND)vsPropGetHWNDFrame(0);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * @see vsPropGetHWND
 * @see vsPropGetHWNDFrame
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 */ 
void * VSAPI vsPropGetHWND(int wid,bool alwaysReturnChildHWND=false);
void *VSAPI vsPropGetQWidget(int window_id);
/**
 * @return Returns the window handle for the given window ID.
 * 
 * @param wid	Window id of object or index to resource 
 * returned by <b>vsFindIndex</b>, 
 * <b>vsNameMatch</b>, 
 * <B>VSP_CHILD</B>, or 
 * <B>VSP_NEXT</B>.  0 specifies the 
 * current object.
 * @param alwaysReturnChildHWND  When false, shell HWND is 
 *                               returned. With Qt, this is
 *                               typically what you want because
 *                               it is unsafe to retrieve a
 *                               child widget HWND because of
 *                               drawing issues that will occur
 *                               afterwards.
 * 
 * @example
 * <pre>
 * 	    HWND hwnd = (HWND)vsPropGetHWND(0);
 * </pre>
 * 
 * @see vsPropGetB
 * @see vsPropGetZ
 * @see vsPropSetZ
 * @see vsPropSetB
 * @see vsPropGetI
 * @see vsPropGetI64
 * @see vsPropSetI
 * @see vsPropSetI64
 * @see vsPropGetL
 * @see vsPropSetL
 * @see vsPropGetHWND
 * @see vsPropGetHWNDFrame
 * 
 * @appliesTo All_Window_Objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void * VSAPI vsPropGetHWNDFrame(int wid,bool alwaysReturnChildHWND=false);

/**
 * @deprecated 
 * Just do not use this function. 
 * 
 * @param pplstr   pointer to VSPLSTR
 * 
 * @return 0 on success, &lt;0 on error.
 */
VSDEPRECATED 
int VSAPI vsTopLstr(VSLSTR **pplstr);

#define VSSTRPOSFLAG_IGNORE_CASE    0x0001
#define VSSTRPOSFLAG_RE             0x0002
#define VSSTRPOSFLAG_WORD           0x0004
//#define VSSTRPOSFLAG_EXACT        0x0008
//#define VSSTRPOSFLAG_VERSION      0x0010
#define VSSTRPOSFLAG_UNIXRE         0x0020
#define VSSTRPOSFLAG_BINARY         0x0040
#define VSSTRPOSFLAG_BRIEFRE        0x0080
#define VSSTRPOSFLAG_ACP            0x0100
#define VSSTRPOSFLAG_WILDCARDS      0x0200
#define VSSTRPOSFLAG_PERLRE         0x0400
#define VSSTRPOSFLAG_VIMRE          0x0800
#define VSSTRPOSFLAG_IGNORE_CASE9   0x1000

#define VSSTRPOSFLAG_ISRE (VSSTRPOSFLAG_BRIEFRE|VSSTRPOSFLAG_UNIXRE|VSSTRPOSFLAG_RE|VSSTRPOSFLAG_PERLRE|VSSTRPOSFLAG_VIMRE|VSSTRPOSFLAG_WILDCARDS)


/**
 * @return Searches forward from start position specified for string given.  If 
 * string is found, the position of the string found is returned.  First 
 * character of string is 1 and NOT 0.  Returns 0 if the string is not 
 * found.
 * 
 * @param pSearchFor	String to search for.
 * 
 * @param SearchForLen	Number of bytes in <i>pSearchFor</i>.
 * You can specify -1 if pSearchFor is NULL 
 * terminated.
 * 
 * @param pBuf	Buffer to search in.
 * 
 * @param BufLen	Number of bytes in <i>pBuf</i>.
 * 
 * @param start	Character position to start searching from 
 * 1..<i>BufLen</i>.  Specify 1 to start search 
 * from firstcharacter.
 * 
 * @param SearchFlags	One or more of the following flags:
 * 
 * <dl>
 * <dt>VSSTRPOSFLAG_IGNORE_CASE</dt><dd>
 * 	Case insensitive search.</dd>
 * <dt>VSSTRPOSFLAG_RE</dt><dd>
 * 	SlickEdit regular expression search.  See
 * <b>SlickEdit Regular Expressions</b>.</dd>
 * <dt>VSSTRPOSFLAG_WORD</dt><dd>
 * 	Reserved for future used.</dd>
 * <dt>VSSTRPOSFLAG_UNIXRE</dt><dd>
 * 	UNIX regular expression search.  See
 * <b>UNIX Regular Expressions</b>.</dd>
 * <dt>VSSTRPOSFLAG_BINARY</dt><dd>
 * 	Binary search.  This allows start positions in
 * the middle of a DBCS or UTF-8 character.
 * This option is useful when editing binary
 * files (in SBCS/DBCS mode) which may 
 * contain characters which look like DBCS 
 * but are not.  For example, if you search for
 * the character 'a', it will not be found as the
 * second character of a DBCS sequence unless
 * this option is specified.</dd>
 * <dt>VSSTRPOSFLAG_ACP </dt><dd>
 * 	Specifies that pSearchFor and pBuf contain
 * active code page data and that an
 * SBCS/DBCS mode search should be
 * performed.  This flag is ignored if Unicode 
 * support is not active. </dd>
 * <dt>VSSTRPOSFLAG_BRIEFRE</dt><dd>
 * 	Brief regular expression search.  See
 * <b>Brief Regular Expressions</b>.</dd>
 * <dt>VSSTRPOSFLAG_WILDCARDS</dt><dd>
 *  Wildcards expression search.
 *  See <b>Wildcard Expressions</b>.</dd>
 * </dl>
 * 
 * @example
 * <pre>
 *    int i;
 *    char *ptext;
 *    ptext="t(h.s)";
 *    i=vsStrPos("t{h?s}",-1,
 *      "WHERE IS THIS",-1,
 *      1,
 *      VSSTRPOSFLAG_IGNORE_CASE|VSSTRPOSFLAG_RE);
 *    if (i) {
 *       // The first tagged expression for SlickEdit RE's is 0
 *       char word[100];
 *       int wordlen;
 *       wordlen=vsStrPosMatchLength(0);
 *       memcpy(word,ptext+vsStrPosMatchStart(0)-1,wordlen);
 *       word[wordlen]=0;
 *       vsMessageBox(word,"Tagged Expression");
 * 
 *       wordlen=vsStrPosMatchLength(-1);
 *       memcpy(word,ptext+vsStrPosMatchStart(-1)-1,wordlen);
 *       word[wordlen]=0;
 *       vsMessageBox(word,"Whole word found");
 *    }
 * 
 *    ptext="t(h.s)";
 *    StrPos(ptext,-1,
 *        "WHERE IS THIS",-1,
 *        1,
 *        
 * VSSTRPOSFLAG_IGNORE_CASE|VSSTRPOSFLAG_UNIXR
 * E);
 *    if (i) {
 *       // The first tagged expression for UNIX is 1 and not 0.
 *       char word[100];
 *       int wordlen;
 *       wordlen=vsStrPosMatchLength(1);
 *       memcpy(word,ptext+vsStrPosMatchStart(1)-1,wordlen);
 *       word[wordlen]=0;
 *       vsMessageBox(word,"Tagged Expression");
 * 
 *       wordlen=vsStrPosMatchLength(-1);
 *       memcpy(word,ptext+vsStrPosMatchStart(-1)-1,wordlen);
 *       word[wordlen]=0;
 *       vsMessageBox(word,"Whole word found");
 *    }
 * </pre>
 * 
 * @see vsStrLastPos
 * @see vsStrPosMatchLength
 * @see vsStrPosMatchStart
 * 
 * @categories String_Functions
 * 
 */ 
int VSAPI vsStrPos(const char *pSearchFor,int SearchForLen,
                   const char *pBuf,int BufLen, int start,int SearchFlags);

/**
 * @return Returns length of tagged expression found for last search
 * performed by vsStrPos, or vsStrLastPos.  Result is not defined if the
 * tagged expression was not found.
 * <p>
 * For SlickEdit and Brief regular expressions the first tagged expression
 * is 0 and the last is 9.  For UNIX and Perl, the first tagged
 * expression is 1 and the last is 0.
 *
 * @param TaggedExpression    Tagged expression number.
 *
 * @example See {@link vsStrPos} for an example.
 *
 * @see vsStrPos
 * @see vsStrLastPos
 * @see vsStrPosMatchStart
 * 
 * @categories String_Functions
 * 
 */
int VSAPI vsStrPosMatchLength(int MatchGroup);

/**
 * @return Returns start of tagged expression found for last search
 * performed by vsStrPos, or vsStrLastPos.  Result is not defined if the
 * tagged expression was not found.
 * <p>
 * For SlickEdit and Brief regular expressions the first tagged expression
 * is 0 and the last is 9.  For UNIX and Perl, the first tagged
 * expression is 1 and the last is 0.
 *
 * @param TaggedExpression	Tagged expression number.  For 
 * SlickEdit and Brief regular expressions the 
 * first tagged expression is 0 and the last is 9.  
 * For UNIX, the first tagged expression is 1 
 * and the last is 0.
 * @example See {@link vsStrPos} for an example.
 *
 * @see vsStrPos
 * @see vsStrLastPos
 * @see vsStrPosMatchLength
 * 
 * @categories String_Functions
 * 
 */
int VSAPI vsStrPosMatchStart(int MatchGroup);
/**
 * Searches backward from start position specified for string given.  If
 * string is found, the position of the string found is returned.  First
 * character of string is 1 and NOT 0.  Returns 0 if the string is not
 * found.
 *
 * @param pSearchFor	String to search for.
 * @param SearchForLen	Number of bytes in pSearchFor.
 *                      You can specify -1 if pSearchFor is NULL terminated.
 * @param pBuf	        Buffer to search in.
 * @param BufLen	    Number of bytes in pBuf.
 * @param start	        Character position to start searching from 1..BufLen.
 *                      Specify 1 to start search from first character.
 * @param SearchFlags	One or more of the following flags:
 *    <ul>
 *    <li>VSSTRPOSFLAG_IGNORE_CASE -- Case insensitive search.
 *    <li>VSSTRPOSFLAG_RE          -- SlickEdit regular expression search.
 *                                    See help on SlickEdit Regular Expressions.
 *    <li>VSSTRPOSFLAG_WORD        -- Reserved for future used.
 *    <li>VSSTRPOSFLAG_UNIXRE      -- UNIX regular expression search.
 *                                    See UNIX Regular Expressions.
 *    <li>VSSTRPOSFLAG_BINARY      -- Binary search.  This allows start positions
 *                                    in the middle of a DBCS or UTF-8 character.
 *                                    This option is useful when editing binary files
 *                                    (in SBCS/DBCS mode) which may contain characters
 *                                    which look like DBCS but are not.  For example,
 *                                    if you search for the character 'a', it will not
 *                                    be found as the second character of a DBCS
 *                                    sequence unless this option is specified.
 *    <li>VSSTRPOSFLAG_ACP         -- Specifies that pSearchFor and pBuf contain
 *                                    active code page data and that an SBCS/DBCS
 *                                    mode search should be performed.
 *                                    This flag is ignored if Unicode support is not active.
 *    <li>VSSTRPOSFLAG_BRIEFRE     -- Brief regular expression search.
 *                                    See help on Brief Regular Expressions.
 *    <li>VSSTRPOSFLAG_WILDCARDS   -- Wildcards expression search.
 *                                    See help on Wildcard Expressions</b>
 *    </ul>
 *
 * @example See {@link vsStrPos} for an example.
 *
 * @see vsStrPos
 * @see vsStrPosMatchLength
 * @see vsStrPosMatchStart
 * @see vsStrPosGetFlags
 * 
 * @categories String_Functions
 * 
 */
int VSAPI vsStrLastPos(const char *pSearchFor,int SearchForLen,
                       const char *pBuf,int BufLen, int start,int SearchFlags);

/**
 * Translate the string-style search arguments to vsStrPos() style arguments.
 * 
 * @return Bitset of VSSTRPOSFLAG_* flags required by by <b>vsStrPos</b> 
 * and <b>vsStrLastPos</b>.
 * 
 * @param pSearchFlags	One or more of the flags supported by 
 * <b>pos</b>.
 * 	
 * @see vsStrPos
 * @see vsStrLastPos
 * 
 * @categories String_Functions
 */ 
int VSAPI vsStrPosGetFlags(const char * char_flags);

/**
 * @return Returns <i>pInputStr</i> with all occurrences of <i>pSearchStr</i> 
 * replaced with <i>pReplaceStr</i>.  See <b>vsStrPos</b> function for 
 * information on valid search <i>options</i>.
 * 
 * @param pOutput	(output) Character array to copy output to.
 * 
 * @param OutputLen	Number of bytes allocated to output array.
 * 
 * @param pBytesRequired	Number of bytes required for pOutput (can 
 * be NULL).
 * 
 * @param pInputStr	Input string to translate.
 * 
 * @param InputLen	Length of input string, -1 if null-terminated.
 * 
 * @param pReplaceStr	String to replace search matches with.
 * 
 * @param ReplaceLen	Length of replace string, -1 if null-
 * terminated.
 * 
 * @param pSearchStr	String to search for.
 * 
 * @param SearchLen	Length of search string, -1 if null-
 * terminated.
 * 
 * @param SearchFlags	One or more of the following flags:
 * 
 * <dl>
 * <dt>VSSTRPOSFLAG_IGNORE_CASE</dt><dd>
 * 	Case insensitive search.</dd>
 * <dt>VSSTRPOSFLAG_RE</dt><dd>
 * 	SlickEdit regular expression search.  See 
 * SlickEdit Regular Expressions.</dd>
 * <dt>VSSTRPOSFLAG_WORD</dt><dd>
 * 	Reserved for future used.</dd>
 * <dt>VSSTRPOSFLAG_UNIXRE</dt><dd>
 * 	UNIX regular expression search.  See UNIX 
 * Regular Expressions.</dd>
 * <dt>VSSTRPOSFLAG_BINARY</dt><dd>
 * 	Binary search.  This allows start positions in 
 * the middle of a DBCS or UTF-8 character.  
 * This option is useful when editing binary 
 * files (in SBCS/DBCS mode) which may 
 * contain characters which look like DBCS 
 * but are not.  For example, if you search for 
 * the character 'a', it will not be found as the 
 * second character of a DBCS sequence unless 
 * this option is specified.</dd>
 * <dt>VSSTRPOSFLAG_ACP </dt><dd>
 * 	Specifies that pSearchFor and pBuf contain 
 * active code page data and that an 
 * SBCS/DBCS mode search should be 
 * performed.  This flag is ignored if Unicode 
 * support is not active. </dd>
 * <dt>VSSTRPOSFLAG_BRIEFRE</dt><dd>
 * 	Brief regular expression search.  See Brief 
 * Regular Expressions.</dd>
 * <dt>VSSTRPOSFLAG_WILDCARDS</dt><dd>
 *  Wildcards expression search.
 *  See <b>Wildcard Expressions</b>.</dd>
 * </dl>
 * 
 * @see <b>vsStrPos</b>
 * @see <b>vsStrPosGetFlags</b>
 * 
 * @categories String_Functions
 * 
 */
int VSAPI vsStrTranslate(char *pOutput, int OutputLen, size_t *pBytesRequired,
                         const char *pInputStr, int InputLen,
                         const char *pReplaceStr, int ReplaceLen,
                         const char *pSearchStr, int SearchLen,
                         int SearchFlags=0);

/**
 * Set the timeout amount for performance critical functions. 
 * The timeout is not a strict timeout, it's a software timeout. 
 * Use {@link _CheckTimeout()} to test if the timeout is expired. 
 * <p> 
 * It is good practice to clear the timeout after you are done 
 * with it by calling _SetTimeout(0). 
 * <p> 
 * Timeouts are set per-thread, making this function thread-safe, however, 
 * you need to set the timeout in the same thread that you use it in. 
 * 
 * @param ms   number of milliseconds to time out after. 
 *             use 0 to clear an existing timeout.
 * 
 * @return Normally will return 'ms', but if there is an existing 
 *         earlier timeout, the earlier timeout will be returned.
 *  
 * @categories Miscellaneous_Functions
 */
int VSAPI vsSetTimeout(int ms);
/** 
 * Check if a timeout set using {@link _SetTimeout()} has expired. 
 * This is a software timeout.  Nothing will happen when the timeout 
 * passes, it's up to you to call _CheckTimeout() yourself and 
 * handle the situtation. 
 * <p> 
 * Timeouts are set per-thread, making this function thread-safe, however, 
 * you need to set the timeout in the same thread that you use it in. 
 * 
 * @return 'true' if the timeout is expired.
 *  
 * @categories Miscellaneous_Functions
 */
int VSAPI vsCheckTimeout();
/** 
 * Check how many milliseconds are remaining before the timeout 
 * set using {@link _SetTimeout()} will expire.
 * This is a software timeout.  Nothing will happen when the timeout 
 * passes, it's up to you to call _CheckTimeout() yourself and 
 * handle the situtation. 
 * <p> 
 * Timeouts are set per-thread, making this function thread-safe, however, 
 * you need to set the timeout in the same thread that you use it in. 
 * 
 * @return 0 if the timeout is expired, 
 *         >0 is the number of milliseconds remaining, 
 *         >= MAXINT if there is no timeout set.
 *  
 * @categories Miscellaneous_Functions
 */
int VSAPI vsGetTimeoutRemaining();
/** 
 * Saves the current timeout value for restoring later. 
 *  
 * @param timeoutValue    (output only) current timeout value
 *  
 * @see _SetTimeout() 
 * @see _CheckTimeout() 
 * @see _RestoreTimeout() 
 *  
 * @categories Miscellaneous_Functions
 */
void VSAPI vsSaveTimeout(VSUINT64& timeoutValue);
/** 
 * Restore the previously set timeout value.  Note that the timeout value 
 * maybe reflect a timeout which is already past. 
 *  
 * @param timeoutValue    timeout value from {@link vsSaveTimeout()} 
 *  
 * @see _SetTimeout() 
 * @see _CheckTimeout() 
 * @see _SaveTimeout() 
 *  
 * @categories Miscellaneous_Functions
 */
void VSAPI vsRestoreTimeout(VSUINT64Param timeoutValue);


void VSAPI vsError(int errcode);

EXTERN_C void VSAPI vsStackDump(int dumpToFile,
                                int dumpToScreen,
                                int errorCode=0,
                                int ignoreNStackItems=0,
                                slickedit::SEString *pDumpFileName=nullptr);
EXTERN_C_END

