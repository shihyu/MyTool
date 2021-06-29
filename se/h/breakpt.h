////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once

#include "vsdecl.h"

EXTERN_C_BEGIN
   /*
       IMPORTANT:
       
       These calls still function but we recommend you use the new
       
       vsLineMarkerXXX calls instead which provides more features but the
       vsLineMarkerXXX calls do not support hiding debug bitmaps.
   
   
   */



   #define VSBPFLAG_BREAKPOINT        0x00000001    /* Break point on this line*/
   #define VSBPFLAG_EXEC              0x00000002    /* Line about to be executed. */
   #define VSBPFLAG_STACKEXEC         0x00000004    /* Call Stack execution line */
   #define VSBPFLAG_BREAKPOINTDISABLED   0x00000008 /* Break point disabled*/
   
   #define MAXDEBUGBITMAPS  256


   /**
    * Adds a break point.
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * @return Returns an index to a break point which is valid input to 
    * <b>vsBPMGet</b>().
    * 
    * @param wid	Window id of editor control.  0 specifies the 
    * current object.
    * 
    * @param RealLineNum	Real line number (<B>VSP_RLINE</B>).
    * 
    * @param flags	One of the flags below:
    * 
    * <ul>
    * <li>VSBPFLAG_BREAKPOINT</li>
    * <li>VSBPFLAG_EXEC</li>
    * <li>VSBPFLAG_STACKEXEC</li>
    * <li>VSBPFLAG_BREAKPOINTDISABLED</li>
    * </ul>
    * 
    * @param puserdata	Optional pointer to user data.  Use this to 
    * store debugger specific information.
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */
   VSDEPRECATED int VSAPI vsBPMAdd(int wid,seSeekPos RealLineNum,int flags,void *puserdata VSDEFAULT(0));
   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * Adds a break point.  You can use this function to set a break point in a 
    * file that has not yet been loaded (deferred break point).  When the file 
    * is loaded, the break point will be displayed.
    * 
    * @return Returns an index to a break point which is valid input to 
    * <b>vsBPMGet</b>().
    * 
    * @param pszBufName	Name of file or buffer.
    * 
    * @param RealLineNum	Real line number (<B>VSP_RLINE</B>).
    * 
    * @param flags	One of the flags below:
    * 
    * <ul>
    * <li>VSBPFLAG_BREAKPOINT</li>
    * <li>VSBPFLAG_EXEC</li>
    * <li>VSBPFLAG_STACKEXEC</li>
    * <li>VSBPFLAG_BREAKPOINTDISABLED</li>
    * </ul>
    * 
    * @param puserdata	Optional pointer to user data.  Use this to 
    * store debugger specific information.
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   VSDEPRECATED int VSAPI vsBPMAddB(const char *pszBufName,seSeekPos LineNum,int flags,void *puserdata VSDEFAULT(0));
   /*VSDEPRECATED*/ int VSAPI vsBPMAddDeferedBreakPoint(seSeekPos LineNum,seSeekPos NofLines,const char *pszBufName,int flags,int mask,int autoadd,int alwaysAddNewBreakPoint,void *pUserData,int BMIndex,int type,const char *pszMessage,int oldAPI,int markid,seSeekPos BeginLineROffset,const char *pszLineData,int col);
   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * @return Deletes break point of any kind.
    * 
    * @param BreakPointIndex	Index to a break point from 
    * <b>vsBPMAdd</b>(), 
    * <b>vsBPMAddB</b>(), or 
    * <b>vsBPMNext</b>().
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   VSDEPRECATED void VSAPI vsBPMRemove(int BreakPointIndex);
   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * Retrieves various information for a break point.
    * 
    * @param BreakPointIndex  Index to a break point from 
    * <b>vsBPMAdd</b>(), 
    * <b>vsBPMAddB</b>(), or 
    * <b>vsBPMNext</b>().
    * 
    * @param pRealLineNum	Set to real line number 
    * (<B>VSP_RLINE</B>) of breakpoint.
    * 
    * @param pflags	Set to flags of break point.
    * 
    * @param ppuserdata	Set to pointer to user data.
    * 
    * @param PBufID	Set to buffer id or a negative number if this 
    * break point if for a file which has not been 
    * loaded. 
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   VSDEPRECATED int VSAPI vsBPMGet(int BreakPointIndex,seSeekPos *pRealLineNum= 0,int *pflags VSDEFAULT(0),void **ppuserdata VSDEFAULT(0),int *pBufID VSDEFAULT(0),void *preserved1 VSDEFAULT(0),void *preserved2 VSDEFAULT(0));
   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * @return Returns next break point of -1 to indicate that there are no more.
    * 
    * @param BreakPointIndex	Previous break point index or -1 to find first 
    * break point.
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   VSDEPRECATED int VSAPI vsBPMNext(int BreakPointIndex);

   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * @return Index into names table of picture or 0 to indictate no picture.  Calls the 
    * callback function defined by vsCallbackSet(VSCALLBACK_APP_BPMQ_DEFAULT_BITMAP,...)
    * 
    * @param wid	Window id of editor control.  0 specifies the 
    * current object.
    * 
    * @param LineNum	Line number (<B>VSP_LINE</B>).
    * 
    * @param RealLineNum	Real line number (<B>VSP_RLINE</B>).
    * 
    * @param OldLineNum	Old line number 
    * (<B>VSP_OLDLINENUMBER</B>).
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   /*VSDEPRECATED*/ int VSAPI vsBPMQDefaultPicture(int wid,seSeekPos LineNum,seSeekPos RealLineNum,seSeekPos OldLineNum,int reserved VSDEFAULT(0));
   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * Determines the debug bitmap which gets displayed for the specified 
    * debug flags.
    * 
    * @param flags	Specifies the one or more of the 
    * VSBPFLAG_??? flags.  You can add your 
    * own.
    * 
    * @param index An index into the names table of the bitmap 
    * to display.  Use <b>vsUpdatePicture</b> to 
    * register a bitmap.
    * 
    * @see vsBPMQPicture
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   VSDEPRECATED void VSAPI vsBPMSetPicture(int flags,int index);
   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * @return Returns the debug bitmap index which gets displayed for the specified 
    * debug flags.
    * 
    * @param flags	Specifies the one or more of the 
    * VSBPFLAG_??? flags.  You can add your 
    * own.
    * 
    * @see vsBPMSetPicture
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   VSDEPRECATED int VSAPI vsBPMQPicture(int flags);

   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * @return Returns non-zero value if break points are displayed for the editor 
    * control specified.  0 indicates that break points are hidden.
    * 
    * @param wid	Window id of editor control.  0 specifies the 
    * current object.
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   VSDEPRECATED int VSAPI vsBPMQShowBreakPointsFor(int wid);
   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * <p>This function is no longer supported.</p>
    * 
    * <p>This function determines whether break bitmaps are display to the left 
    * of each line for all buffers currently open.  This function provides a 
    * way to hide break points without exiting debug mode.   Users may like 
    * this so that the break points don't take up space to the left of each line.</p>
    * 
    * @param onoff	Specifies whether to show break points.
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   /*VSDEPRECATED*/ void VSAPI vsBPMShowBreakPoints(int onoff);
   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * <p>This function is no longer supported.</p>
    * 
    * <p>Determines whether break bitmaps are display to the left of each line.  
    * This function provides a way to hide break points without exiting 
    * debug mode.   Users may like this so that the break points don't take 
    * up space to the left of each line.</p>
    * 
    * @param wid	Window id of editor control.  0 specifies the 
    * current object.
    * 
    * @param onoff	Specifies whether to show break points.
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   /*VSDEPRECATED*/ void VSAPI vsBPMShowBreakPointsFor(int wid,int onoff);


   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * Adds or removes the debug flags specified for all lines which have 
    * debug flags.
    * 
    * @return Returns 0 if successful.  It is possible but very unlikely that you could 
    * run out of memory.
    * 
    * @param flags	Zero or more of the the VSBPFLAG_??? 
    * flags.  
    * 
    * @param mask	One or more of the the VSBPFLAG_??? 
    * flags.  Only these debug flags are effected.
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   /*VSDEPRECATED*/ void VSAPI vsBPMSetAll(int flags,int mask);
   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * Clears (deletes) all break points.  Also clears all disabled break points.  
    * Execution and stack break points remain unchanged.
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   VSDEPRECATED inline void VSAPI vsBPMClearAllBreakPoints() {vsBPMSetAll(0,VSBPFLAG_BREAKPOINT|VSBPFLAG_BREAKPOINTDISABLED);}
   /**
    * 
    * @deprecated Use vsLineMarker* functions
    * 
    * Clears (deletes) all break points of any kind.  Use this function when 
    * your debugger terminates to exit debug mode.
    * 
    * @categories Deprecated_Breakpoint_Functions
    * 
    */ 
   VSDEPRECATED inline void VSAPI vsBPMClearAll() {vsBPMSetAll(0,-1);}



/********************************************************************************************/

 // The function below are here only present for backward compatiblity. We recommend you
 // do not use these functions.

   int VSAPI vsBPMSet(int wid,int flags,int mask,int autoadd VSDEFAULT(1));
   int VSAPI vsBPMSet2(int wid,seSeekPos LineNum,int flags,int mask,int autoadd VSDEFAULT(1));
   int VSAPI vsBPMSetBL(const char *pszBufName,seSeekPos LineNum,int flags,int mask,int autoadd);
   int VSAPI vsBPMQFlags(int wid);
   int VSAPI vsBPMQFlags2(int wid,seSeekPos LineNum =seSeekPos( -1));
   int VSAPI vsBPMSetFlags(int BreakPointIndex,int flags);

   void VSAPI vsBPMSetAllFor(int wid,int flags,int mask);
   void VSAPI vsBPMSetAllForB(const char *pszBufName,int flags,int mask);
   void VSAPI vsBPMStartDebugMode();  // Start debug mode for all MDI edit buffers
   void VSAPI vsBPMStartDebugModeFor(int wid);   // Start debug mode for a specific editor control
   void VSAPI vsBPMEndDebugMode();  // Frees all editor debug data and removes bitmap display
   void VSAPI vsBPMEndDebugModeFor(int wid);  // Updates old line numbers
   void VSAPI vsBPMEndDebugModeForB(const char *pszBufName); // Updates old line numbers
   int VSAPI vsBPMEnumerate(int wid,int i,int *pFlags,seSeekPos *pLineNum,void *pReserved VSDEFAULT(0));
   int VSAPI vsBPMEnumerateB(const char *pszBufName,int i,int *pFlags,seSeekPos *pLineNum,void *pReserved VSDEFAULT(0));

   inline int VSAPI vsBPMSetBreakPoint(int wid,seSeekPos LineNum= seSeekPos(-1)) {return(vsBPMSet2(wid,LineNum,VSBPFLAG_BREAKPOINT,VSBPFLAG_BREAKPOINT));}
   inline int VSAPI vsBPMSetBreakPointBL(const char *pszBufName,seSeekPos LineNum) {return(vsBPMSetBL(pszBufName,LineNum,VSBPFLAG_BREAKPOINT,VSBPFLAG_BREAKPOINT|VSBPFLAG_BREAKPOINTDISABLED,1));}
   inline void VSAPI vsBPMRemoveBreakPoint(int wid,seSeekPos LineNum =seSeekPos(-1)) {vsBPMSet2(wid,LineNum,0,VSBPFLAG_BREAKPOINT|VSBPFLAG_BREAKPOINTDISABLED,0);}
   inline void VSAPI vsBPMRemoveBreakPointBL(const char *pszBufName,seSeekPos LineNum) {vsBPMSetBL(pszBufName,LineNum,0,VSBPFLAG_BREAKPOINT|VSBPFLAG_BREAKPOINTDISABLED,0);}
   inline int VSAPI vsBPMDisableBreakPoint(int wid,seSeekPos LineNum =seSeekPos(-1)) {return(vsBPMSet2(wid,LineNum,VSBPFLAG_BREAKPOINTDISABLED,VSBPFLAG_BREAKPOINT|VSBPFLAG_BREAKPOINTDISABLED,1));}
   inline int VSAPI vsBPMDisableBreakPointBL(const char *pszBufName,seSeekPos LineNum) {return(vsBPMSetBL(pszBufName,LineNum,VSBPFLAG_BREAKPOINTDISABLED,VSBPFLAG_BREAKPOINT|VSBPFLAG_BREAKPOINTDISABLED,1));}
   inline int VSAPI vsBPMRemoveDisableBreakPoint(int wid,seSeekPos LineNum =seSeekPos(-1)) {return(vsBPMSet2(wid,LineNum,0,VSBPFLAG_BREAKPOINTDISABLED,0));}
   inline int VSAPI vsBPMRemoveDisableBreakPointBL(const char *pszBufName,seSeekPos LineNum) {return(vsBPMSetBL(pszBufName,LineNum,0,VSBPFLAG_BREAKPOINTDISABLED,0));}

   inline int VSAPI vsBPMToggleBreakPoint(int wid,seSeekPos LineNum =seSeekPos(-1)) {
      int status;
      if (vsBPMQFlags2(wid,LineNum) & VSBPFLAG_BREAKPOINT) {
         status=vsBPMSet2(wid,LineNum,0,VSBPFLAG_BREAKPOINT,0);
         //status=vsBPMRemoveBreakPoint(wid);
      } else {
         status=vsBPMSetBreakPoint(wid,LineNum);
      }
      return(status);
   }

   inline int VSAPI vsBPMSetExecLineBL(const char *pszBufName,seSeekPos LineNum) {return(vsBPMSetBL(pszBufName,LineNum,VSBPFLAG_EXEC,VSBPFLAG_EXEC,1));}
   inline int VSAPI vsBPMSetExecLine(int wid,seSeekPos LineNum= seSeekPos( -1)) {return(vsBPMSet2(wid,LineNum,VSBPFLAG_EXEC,VSBPFLAG_EXEC,1));}
   inline void VSAPI vsBPMRemoveExecLineBL(const char *pszBufName,seSeekPos LineNum) {vsBPMSetBL(pszBufName,LineNum,0,VSBPFLAG_EXEC,0);}
   inline void VSAPI vsBPMRemoveExecLine(int wid,seSeekPos LineNum =seSeekPos(-1)) {vsBPMSet2(wid,LineNum,0,VSBPFLAG_EXEC,0);}

   inline int VSAPI vsBPMSetStackExecLineBL(const char *pszBufName,seSeekPos LineNum) {return(vsBPMSetBL(pszBufName,LineNum,VSBPFLAG_STACKEXEC,VSBPFLAG_STACKEXEC,1));}
   inline int VSAPI vsBPMSetStackExecLine(int wid,seSeekPos LineNum =seSeekPos(-1)) {return(vsBPMSet2(wid,LineNum,VSBPFLAG_STACKEXEC,VSBPFLAG_STACKEXEC,1));}
   inline void VSAPI vsBPMRemoveStackExecLineBL(const char *pszBufName,seSeekPos LineNum) {vsBPMSetBL(pszBufName,LineNum,0,VSBPFLAG_STACKEXEC,0);}
   inline void VSAPI vsBPMRemoveStackExecLine(int wid,seSeekPos LineNum =seSeekPos(-1)) {vsBPMSet2(wid,LineNum,0,VSBPFLAG_STACKEXEC,0);}
/********************************************************************************************/

EXTERN_C_END
