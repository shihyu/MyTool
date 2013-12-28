////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef VSHEAP_H
#define VSHEAP_H

#include "vsdecl.h"

EXTERN_C_BEGIN

/**
 * <p>The vsPosXXX functions provide the fastest way to scan buffers.  
 * However, once you use a non vsPosXXX function to access buffer 
 * data (may be to modify something), you MUST call <b>vsPosInit</b> 
 * again to avoid crashing the editor.  For this reason, we recommend you 
 * only use this function if you want your searching to be as fast as 
 * possible.</p>
 * 
 * <p><b>Speed tips</b>: Use the <b>vsSearch</b> function if you are 
 * searching for something which occurs far less times than the number 
 * of bytes in the file.  Using <b>vsGetText</b> to retrieve 4k of data or 
 * more is almost as fast as using vsPosInit except that a copy of the 
 * buffer data must be made.</p>
 * 
 * <p>The Pos cursor is NOT the same as the cursor position.</p>
 * 
 * <p>Use the <b>vsPropSetI</b> function with the VSP_WINDOW_ID 
 * property index to set the current object.</p>
 * 
 * @param LineOffset	Offset tp set the Pos cursor with in the 
 * current line.
 * 
 * @example
 * <pre>
 * // Process all the bytes in the current buffer as fast as possible.
 * // Move the cursor to the top of the current buffer.
 * vsTop(0);
 * // Initialize the Pos cursor to the first byte of the current line.
 * vsPosInit(0);
 * unsigned char *p,*pEndLine,*pEndBuf);
 * vsPosGetPointers(&p,&pEndLine,&pEndBuf);
 * // Count the number of star characters in the current buffer
 * int count=0;
 * for(;;++p) {
 *      if(p>=pEndBuf) {
 *            int status;
 *            status=vsPosRelPGoTo(pEndBuf);
 *            if(status) break;
 *            vsPosGetPointers(&p,&pEndLine,&pEndBuf);
 *            continue;
 *      }
 *      if(*p=='*' ) ++count;
 * }
 * </pre>
 * 
 * @see vsPosGetLinePointers
 * @see vsPosIsEOL
 * @see vsPosSetPointer
 * @see vsPosRelPGoTo
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosRestore
 * @see vsPosIsEOR
 * @see vsPosGetPointers
 * @see vsPosSetCurLine
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
int VSAPI vsPosInit(seLineOffset LineOffset);
/**
 * <p>You must call <b>vsPosInit</b> before calling this function.  Once 
 * you use a non vsPosXXX function which accesses buffer data you 
 * MUST call <b>vsPosInit</b> again to avoid crashing the editor.  Only 
 * use this function if you want your searching to be as fast as possible.</p>
 * 
 * <p>This function is used to quickly scan part of the current Pos line (Not 
 * the same as the cursor position).</p>
 * 
 * @param pp	Set to point to current byte.  You must check 
 * that pp is within the range *ppBeginLine 
 * and *ppEndLine.
 * 
 * @param ppBeginLine	Set to first valid byte at the beginning of the 
 * current Pos line segment.
 * 
 * @param ppEndLine	Set to point past the last valid byte of the 
 * current Pos line segment.
 * 
 * @param pRelLine	Use this to track the relative number of lines 
 * the Pos cursor as moved up or down.  
 * Subtract the initial RelLine from the RelLine 
 * when you are done to get the number of 
 * complete lines the Pos cursor has gone up or 
 * down.	
 * 
 * @see vsPosIsEOL
 * @see vsPosSetPointer
 * @see vsPosInit
 * @see vsPosRelPGoTo
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosRestore
 * @see vsPosIsEOR
 * @see vsPosGetPointers
 * @see vsPosSetCurLine
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
void VSAPI vsPosGetLinePointers(unsigned char **pp,unsigned char **ppBeginLine,
                            unsigned char **ppEndLine,seSeekPos *pRelLine);
/**
 * You must call <b>vsPosInit</b> before calling this function.  Once 
 * you use a non vsPosXXX function which accesses buffer data you 
 * MUST call <b>vsPosInit</b> again to avoid crashing the editor.  Only 
 * use this function if you want your searching to be as fast as possible.
 * 
 * @return Returns information about where Pos cursor + <i>Offset</i> is in 
 * relation to the end of line characters as follows:
 * 
 * <dl>
 * <dt>1</dt><dd>End of record which is past the last end of line 
 * character.</dd>
 * <dt>EOL2_RC</dt><dd>DOS end of line sequence was found (cr,lf).</dd>
 * <dt>EOL1_RC</dt><dd>Single character end of line sequence.</dd>
 * <dt>0</dt><dd>Position is not at the start of the end of line 
 * sequence.</dd>
 * <dt>RE_EOF_RC</dt><dd>Position is past the end of the file+1.</dd>
 * <dt><i>ReturnWhenBetweenNLChars</i></dt><dd>This value is 
 * returned when the position is under the 
 * linefeed of a carriage return, linefeed end of 
 * line sequence.</dd>
 * <dt>Other</dt><dd>File I/O error</dd>
 * </dl> 	
 * 
 * @param Offset	Specifies offset from Pos cursor.  Must be 
 * >=0.
 * 
 * @param ReturnWhenBetweenNLChars
 * 	This value is returned when the position is 
 * under the linefeed of a carriage return, 
 * linefeed end of line sequence.
 * 
 * @see vsPosInit
 * @see vsPosGetLinePointers
 * @see vsPosSetPointer
 * @see vsPosRelPGoTo
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosRestore
 * @see vsPosIsEOR
 * @see vsPosGetPointers
 * @see vsPosSetCurLine
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
int VSAPI vsPosIsEOL(int offset,int ReturnWhenBetweenNLChars VSDEFAULT(0));
/**
 * <p>You must call <b>vsPosInit</b> before calling this function.  Once 
 * you use a non vsPosXXX function which accesses buffer data you 
 * MUST call <b>vsPosInit</b> again to avoid crashing the editor.  Only 
 * use this function if you want your searching to be as fast as possible.</p>
 * 
 * <p>Sets the Pos cursor to a position inside the contiguous buffer segment 
 * returned by <b>vsPosGetPointers</b> or 
 * <b>vsPosGetLinePointers</b>.</p>
 * 
 * @param p	New position for Pos cursor.  Where 
 * <i>pBeginBuf</i>>=<i>p</i><<i>pEndBuf
 * </i>.
 * 
 * @example
 * <pre>
 * vsPosInit(0);
 * unsigned char *p,*pEndLine,*pEndBuf);
 * vsPosGetPointers(&p,&pEndLine,&pEndBuf);
 * if (p+1<pEndBuf) {
 *     vsPosSetPointer(p+1);
 *     if (vsPosIsEOL(0)) {
 *         ...
 *     }
 * }
 * </pre>
 * 
 * @see vsPosInit
 * @see vsPosGetLinePointers
 * @see vsPosIsEOL
 * @see vsPosRelPGoTo
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosRestore
 * @see vsPosIsEOR
 * @see vsPosGetPointers
 * @see vsPosSetCurLine
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
void VSAPI vsPosSetPointer(unsigned char *p);
/**
 * <p>You must call <b>vsPosInit</b> before calling this function.  Once 
 * you use a non vsPosXXX function which accesses buffer data you 
 * MUST call <b>vsPosInit</b> again to avoid crashing the editor.  Only 
 * use this function if you want your searching to be as fast as possible.</p>
 * 
 * <p>Moves the Pos cursor to the byte that would be there if the Pos buffer 
 * was contiguous.  <i>p</i> must be >=<i>pBeginBuf</i>.</p>
 * 
 * @param p	New position for Pos cursor.  <i>p</i> must 
 * be >=<i>pBeginBuf</i>.
 * 
 * @example
 * <pre>
 * // Process all the bytes in the current buffer as fast as possible.
 * // Move the cursor to the top of the current buffer.
 * vsTop(0);
 * // Initialize the Pos cursor to the first byte of the current line.
 * vsPosInit(0);
 * unsigned char *p,*pEndLine,*pEndBuf);
 * vsPosGetPointers(&p,&pEndLine,&pEndBuf);
 * // Count the number of star characters in the current buffer
 * int count=0;
 * for(;;++p) {
 *      if(p>=pEndBuf) {
 *            int status;
 *            status=vsPosRelPGoTo(pEndBuf);
 *            if(status) break;
 *            vsPosGetPointers(&p,&pEndLine,&pEndBuf);
 *            continue;
 *      }
 *      if(*p=='*' ) ++count;
 * }
 * </pre>
 * 
 * @see vsPosInit
 * @see vsPosGetLinePointers
 * @see vsPosIsEOL
 * @see vsPosSetPointer
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosRestore
 * @see vsPosIsEOR
 * @see vsPosGetPointers
 * @see vsPosSetCurLine
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
int VSAPI vsPosRelPGoTo(unsigned char *p);
/**
 * <p>You must call <b>vsPosInit</b> before calling this function.  Once 
 * you use a non vsPosXXX function which accesses buffer data you 
 * MUST call <b>vsPosInit</b> again to avoid crashing the editor.  Only 
 * use this function if you want your searching to be as fast as possible.</p>
 * 
 * <p>Moves the Pos cursor up or down the number of lines specified.  The 
 * Pos cursor is always place at the beginning of the line even when 0 is 
 * given.</p>
 * 
 * @return Returns the actually number of lines the Pos cursor went up or down.
 * 
 * @param Noflines	Number of lines to move Pos cursor up or 
 * down.  The Pos cursor is always place at the 
 * beginning of the line even when 0 is given.
 * 
 * @see vsPosInit
 * @see vsPosGetLinePointers
 * @see vsPosIsEOL
 * @see vsPosSetPointer
 * @see vsPosRelPGoTo
 * @see vsPosSave
 * @see vsPosRestore
 * @see vsPosIsEOR
 * @see vsPosGetPointers
 * @see vsPosSetCurLine
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
seSeekPosRet VSAPI vsPosNextBOL(seSeekPos Noflines);
/**
 * @return Saves the Pos cursor information in the memory pointed to by 
 * pSavePos. Specify 0 for pSavePos to determine how much memory 
 * you need to allocate.  This function allows you to access any editor 
 * buffer function that does not modify the buffer and then restore the 
 * Pos cursor with <b>vsPosRestore</b>.
 * 
 * @see vsPosInit
 * @see vsPosGetLinePointers
 * @see vsPosIsEOL
 * @see vsPosSetPointer
 * @see vsPosRelPGoTo
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosRestore
 * @see vsPosIsEOR
 * @see vsPosGetPointers
 * @see vsPosSetCurLine
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
int VSAPI vsPosSave(void *pSavePos);
/**
 * @return Restore Pos cursor to position saved by <b>vsPosSave</b>.
 * 
 * @see vsPosInit
 * @see vsPosGetLinePointers
 * @see vsPosIsEOL
 * @see vsPosSetPointer
 * @see vsPosRelPGoTo
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosIsEOR
 * @see vsPosGetPointers
 * @see vsPosSetCurLine
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
int VSAPI vsPosRestore(const void *pSavePos);
/**
 * You must call <b>vsPosInit</b> before calling this function.  Once 
 * you use a non vsPosXXX function which accesses buffer data you 
 * MUST call <b>vsPosInit</b> again to avoid crashing the editor.  Only 
 * use this function if you want your searching to be as fast as possible.
 * 
 * @return Returns information about where Pos cursor + <i>Offset</i> is in 
 * relation to the end of the record as follows:
 * 
 * <dl> 
 * <dt>1</dt><dd>End of record which is past the last end of line 
 * character.</dd>
 * <dt>0</dt><dd>Position is not at the start of the end of line 
 * sequence.</dd>
 * <dt>RE_EOF_RC</dt><dd>Position is past the end of the file+1.</dd>
 * <dt>Other</dt><dd>File I/O error</dd>
 * </dl>
 * 
 * @param Offset	Specifies offset from Pos cursor.  Must be 
 * >=0.
 * 
 * @see vsPosInit
 * @see vsPosGetLinePointers
 * @see vsPosIsEOL
 * @see vsPosSetPointer
 * @see vsPosRelPGoTo
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosGetPointers
 * @see vsPosSetCurLine
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
int VSAPI vsPosIsEOR(int offset);
/**
 * <p>You must call <b>vsPosInit</b> before calling this function.  Once 
 * you use a non vsPosXXX function which accesses buffer data you 
 * MUST call <b>vsPosInit</b> again to avoid crashing the editor.  Only 
 * use this function if you want your searching to be as fast as possible.</p>
 * 
 * <p>This function is used to quickly scan part of the current Pos line (Not 
 * the same as the cursor position).</p>
 * 
 * @param pp	Set to point to current byte.  You must check 
 * that pp is less than *ppEndBuf.
 * 
 * @param ppEndLine	Set to point past the last valid byte of the 
 * current Pos line segment.
 * 
 * @param ppEndBuf	Set to point past the last valid byte of the 
 * current Pos buffer segment.
 * 
 * @see vsPosIsEOL
 * @see vsPosSetPointer
 * @see vsPosInit
 * @see vsPosRelPGoTo
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosRestore
 * @see vsPosIsEOR
 * @see vsPosGetLinePointers
 * @see vsPosSetCurLine
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
void VSAPI vsPosGetPointers(unsigned char **pp,unsigned char **ppEndLine,
                            unsigned char **ppEndBuf VSDEFAULT(0));
/**
 * <p>You must call <b>vsPosInit</b> before calling this function.  Once 
 * you use a non vsPosXXX function which accesses buffer data you 
 * MUST call <b>vsPosInit</b> again to avoid crashing the editor.  Only 
 * use this function if you want your searching to be as fast as possible.</p>
 * 
 * <p>Sets the edit current line to the same line as the Pos cursor is on.</p>
 * 
 * @see vsPosInit
 * @see vsPosGetLinePointers
 * @see vsPosIsEOL
 * @see vsPosSetPointer
 * @see vsPosRelPGoTo
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosRestore
 * @see vsPosIsEOR
 * @see vsPosGetPointers
 * @see vsPosQCol
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
int VSAPI vsPosSetCurLine();
/**
 * You must call <b>vsPosInit</b> before calling this function.  Once 
 * you use a non vsPosXXX function which accesses buffer data you 
 * MUST call <b>vsPosInit</b> again to avoid crashing the editor.  Only 
 * use this function if you want your searching to be as fast as possible.
 * 
 * @return Returns the Pos cursor column position.  This is the same as the 
 * <b>p_col</b> property except for the Pos cursor instead of the edit 
 * cursor.
 * 
 * @see vsPosInit
 * @see vsPosGetLinePointers
 * @see vsPosIsEOL
 * @see vsPosSetPointer
 * @see vsPosRelPGoTo
 * @see vsPosNextBOL
 * @see vsPosSave
 * @see vsPosRestore
 * @see vsPosIsEOR
 * @see vsPosGetPointers
 * @see vsPosSetCurLine
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Search_Functions
 * 
 */ 
int VSAPI vsPosQCol();
int VSAPI vsPosQCol2(int addOffset);
/*******************BELOW NOT EXPOSED TO DLL INTERFACE YET***********************/
void VSAPI vsPosGetColorPointers(unsigned char **pp,unsigned char **ppEndLine,
                            unsigned char **ppEndBuf);
void VSAPI vsPosGetColorPointersRev(unsigned char **pp,unsigned char **ppBegin,
                           unsigned char **ppBeginBuf);
void VSAPI vsPosGetPointersRev(unsigned char **pp,unsigned char **ppBegin,
                           unsigned char **ppBeginBuf VSDEFAULT(0));

//int VSAPI vsPosRelPGoTo(unsigned char *p);
//int VSAPI vsPosRelPGoToRev(unsigned char *p);

int VSAPI vsPosRelGetChar(int offset);
int VSAPI vsPosGetChar();
int VSAPI vsPosRelGetCharRev(int offset);
int VSAPI vsPosGetCharRev();
int VSAPI vsPosQLineOffset();
int VSAPI vsPosOnLine0();
void VSAPI vsPosQPoint(seSeekPos *pLinePoint,seSeekPos *pDownCount,seLineOffset *pLineOffset);
int VSAPI vsPosGoToOffset(seSeekPos offset);
int VSAPI vsPosQLineLength(int IncludeNLChars);
seSeekPosRet VSAPI vsPosQOffset();
seSeekPosRet VSAPI vsPosQLine();
void VSAPI vsPosQRelLine(seSeekPos *pNoflines,seSeekPos *pStartRelLine);
int VSAPI vsPosRelGoTo(int offset);
int VSAPI vsPosRelPGoToRev(unsigned char *p);
int VSAPI vsPosRelGoToRev(int offset);
int VSAPI vsPosIsBOL(int offset);
int VSAPI vsPosIsAnyChar(int offset,int MultiLine);
int VSAPI vsPosFindBOL(int FindFirst);
int VSAPI vsPosFindEOL(int FindFirst);
seSeekPosRet VSAPI vsPosPrevBOL(seSeekPos Noflines);
int VSAPI vsPosFindBOLRev(int FindFirst);
int VSAPI vsPosFindEOLRev(int FindFirst);
EXTERN_C_END


#endif
