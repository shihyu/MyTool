////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50386 $
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
/**
 * @return Returns 0 if successful.
 *
 * Sets the callback for the specified mouse event.
 *
 * @param type	Index of marker type.
 *
 * @param event	Mouse event constant.  Only the constants
 * LBUTTON_DOWN,
 * LBUTTON_DOUBLE_CLICK,
 * RBUTTON_DOWN are supported.
 *
 * @param pfnCallback	Callback.  Either index into names table of
 * function or pointer to Slick-C&reg; function.
 *
 *     int (* pfnCallback)(int wid,int LineNum, int LineMarkerIndex,int BMIndex,int Type, const char *pszMessage, void *pUserData);
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern int _MarkerTypeSetCallbackMouseEvent(int type,_str event,typeless pfnCallback);
extern int _LineMarkerExecuteMouseEvent(int wid,int linenum,long lineoffset,_str event);
extern void _PicSetOrder(int LineMarkerIndex,int order,int reserved);

/**
 * @return Returns index of type.  Once a type is allocated, various attributes of
 * the type can be set.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern int _MarkerTypeAlloc();

/**
 * Frees marker type alloced by {@link _MarkerTypeAlloc}()
 *
 * @param type    Must be a valid marker type index
 *
 * @return Returns 0 on success, <0 on error.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 * @see _MarkerTypeAlloc
 *
 */
extern int _MarkerTypeFree(int type);

/**
 * Adds a new line marker.
 *
 * @return Returns index of new line marker.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param RealLineNum   Line number or real line number (not
 * counting no save lines).
 *
 * @param isRealLineNum	Indicates whether <i>RealLineNum</i> is a
 * real line number or not.
 *
 * @param NofLines	Number of lines in this item.  Specify zero if
 * the marker type you are using does not have the
 * VSMARKERTYPEFLAG_DRAW_BOX flag set.
 *
 * @param BMIndex	Bitmap to display at the line specified.
 * Specify 0 for no bitmap.  The following are
 * names of bitmaps used for debugging:
 *
 * <dl>
 * <dt>_breakpt.bmp</dt><dd>Indicates a line with an enabled breakpoint.</dd>
 * <dt>_breakpn.bmp</dt><dd>Indicates a line with a disabled breakpoint.</dd>
 * <dt>_execpt.bmp</dt><dd>Indicates current execution line.</dd>
 * <dt>_stackex.bmp</dt><dd>Indicates a line on the execution call stack.</dd>
 * <dt>_watchpt.bmp</dt><dd>Indicates a line with an enabled watchpoint.</dd>
 * </dl>
 *
 * @param type	Type allocated by
 * <b>_MarkerTypeAlloc</b>().
 *
 * @param Message	HTML message displayed when mouse is
 * over bitmap.  Only a subset of HTML
 * supported by our mini-HTML control is
 * supported.
 *
 * @example
 * <pre>
 * // Add debug bitmap to give the visual effect of a
 * // break point.
 * int type=_MarkerTypeAlloc();
 * int LineMarkerIndex=_LineMarkerAdd(p_window_id,p_line,
 *       0,4, find_index("_breakpt.bmp", PICTURE_TYPE),
 *       type,"");
 *
 * // Add a line marker which draws a box
 * int type=_MarkerTypeAlloc();
 * int LineMarkerIndex=_LineMarkerAdd(p_window_id,p_line,
 *       0,4,find_index('_edplus.bmp',PICTURE_TYPE),
 *       type,"line 1<br>line2");
 * _LineMarkerSetMousePointer(LineMarkerIndex,MP_CROSS);
 * _LineMarkerSetStyleColor(LineMarkerIndex,0xff0000);
 * _MarkerTypeSetFlags(type,VSMARKERTYPEFLAG_DRAW_BOX|VSMARKERTYPEFLAG_AUTO_
 * REMOVE);
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern int _LineMarkerAdd(int wid,int RealLineNum,boolean isRealLineNum,int NofLines,int BMIndex,int type,_str Message);

/**
 * Adds a new, potentially deferred, line marker.
 *
 * @return Returns index of new line marker.
 *
 * @param pszBufName    Name of file to add the line marker to.
 *
 * @param RealLineNum   Line number or real line number (not
 * counting no save lines).
 *
 * @param isRealLineNum	Indicates whether <i>RealLineNum</i> is a
 * real line number or not.
 *
 * @param NofLines	Number of lines in this item.  Specify zero if
 * the marker type you are using does not have the
 * VSMARKERTYPEFLAG_DRAW_BOX flag set.
 *
 * @param BMIndex	Bitmap to display at the line specified.
 * Specify 0 for no bitmap.  The following are
 * names of bitmaps used for debugging:
 *
 * <dl>
 * <dt>_breakpt.bmp</dt><dd>Indicates a line with an enabled breakpoint.</dd>
 * <dt>_breakpn.bmp</dt><dd>Indicates a line with a disabled breakpoint.</dd>
 * <dt>_execpt.bmp</dt><dd>Indicates current execution line.</dd>
 * <dt>_stackex.bmp</dt><dd>Indicates a line on the execution call stack.</dd>
 * <dt>_watchpt.bmp</dt><dd>Indicates a line with an enabled watchpoint.</dd>
 * </dl>
 *
 * @param type	Type allocated by
 * <b>_MarkerTypeAlloc</b>().
 *
 * @param Message	HTML message displayed when mouse is
 * over bitmap.  Only a subset of HTML
 * supported by our mini-HTML control is
 * supported.
 *
 * @example
 * <pre>
 * // Add debug bitmap to give the visual effect of a
 * // break point.
 * int type=_MarkerTypeAlloc();
 * int LineMarkerIndex=_LineMarkerAddB(p_buf_name,p_l
 *       0,4, find_index("_breakpt.bmp", PICTURE_TYPE),
 *       type,"");
 *
 * // Add a line marker which draws a box
 * int type=_MarkerTypeAlloc();
 * int LineMarkerIndex=_LineMarkerAddB(p_buf_name,p_li
 *       0,4,find_index('_edplus.bmp',PICTURE_TYPE),
 *       type,"line 1<br>line2");
 * _LineMarkerSetMousePointer(LineMarkerIndex,MP_CROSS);
 * _LineMarkerSetStyleColor(LineMarkerIndex,0xff0000);
 * _MarkerTypeSetFlags(type,VSMARKERTYPEFLAG_DRAW_BOX|VSMARKERTYPEFLAG_AUTO_
 * REMOVE);
 * </pre>
 *
 * @see _LineMarkerAdd
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern int _LineMarkerAddB(_str pszBufName,int RealLineNum,int isRealLineNum,int NofLines,int BMIndex,int type,_str pszMessage);

/**
 * Adds a new stream marker.
 *
 * @return Returns index of new stream marker.
 *
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 *
 * @param RealLineNum      Line number or real line number (not
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
 * <dt>_breakpt.bmp</dt><dd>Indicates a line with an enabled breakpoint.</dd>
 * <dt>_breakpn.bmp</dt><dd>Indicates a line with a disabled breakpoint.</dd>
 * <dt>_execpt.bmp</dt><dd>Indicates current execution line.</dd>
 * <dt>_stackex.bmp</dt><dd>Indicates a line on the execution call stack.</dd>
 * <dt>_watchpt.bmp</dt><dd>Indicates a line with an enabled watchpoint.</dd>
 * </dl>
 *
 * @param type	Type allocated by
 * <b>_MarkerTypeAlloc</b>().
 *
 * @param Message	HTML message displayed when mouse is
 * over bitmap.  Only a subset of HTML
 * supported by our mini-HTML control is
 * supported.
 *
 * @example
 * <pre>
 * // Add debug bitmap to give the visual effect of a
 * // break point.
 * int type=_MarkerTypeAlloc();
 * int StreamMarkerIndex=_StreamMarkerAdd(p_window_id,p_line,
 *       0,4, find_index("_breakpt.bmp", PICTURE_TYPE),
 *       type,"");
 *
 * // Add a line marker which draws a box
 * int type=_MarkerTypeAlloc();
 * int  StreamMarkerIndex=_StreamMarkerAdd(p_window_id,p_line,
 *       0,4,find_index('_edplus.bmp',PICTURE_TYPE),
 *       type,"line 1<br>line2");
 * _MarkerSetMousePointer(LineMarkerIndex,MP_CROSS);
 * _LineMarkerSetStyleColor(LineMarkerIndex,0xff0000);
 * _MarkerTypeSetFlags(type,VSMARKERTYPEFLAG_DRAW_BOX|VSMARKERTYPEFLAG_AUTO_REMOVE);
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern int _StreamMarkerAdd(int wid, long StartOffset, long Length, boolean isRealOffset, int BMIndex,int type,_str pszMessage);

/**
 * Retrieve the details about the given stream marker.
 *
 * @param StreamMarkerIndex   Index of stream marker returned
 *                            by a vsStreamMarkerAdd function.
 * @param info                (reference) initialized with
 *                            stream marker information.
 *
 * @return 0 if stream marker index is valid, <0 on error.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
extern int _StreamMarkerGet(int StreamMarkerIndex,VSSTREAMMARKERINFO &info);

/**
 * Retrieves most properties for line marker.
 *
 * @param LineMarkerIndex  Index of Line marker returned by a vsLineMarkerAdd function.
 * @param info      Returns most properties for line marker.
 * @param version
 *
 * @return 0 if Line marker index is valid.
 */
extern int _LineMarkerGet(int LineMarkerIndex,VSLINEMARKERINFO &info);

/**
 * Adds a new stream marker.
 *
 * @return Returns index of new stream marker.
 *
 * @param BufName          Name of buffer to add marker to.
 *
 * @param RealLineNum      Line number or real line number (not
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
 * <dt>_breakpt.bmp</dt><dd>Indicates a line with an enabled breakpoint.</dd>
 * <dt>_breakpn.bmp</dt><dd>Indicates a line with a disabled breakpoint.</dd>
 * <dt>_execpt.bmp</dt><dd>Indicates current execution line.</dd>
 * <dt>_stackex.bmp</dt><dd>Indicates a line on the execution call stack.</dd>
 * <dt>_watchpt.bmp</dt><dd>Indicates a line with an enabled watchpoint.</dd>
 * </dl>
 *
 * @param type	Type allocated by
 * <b>_MarkerTypeAlloc</b>().
 *
 * @param Message	HTML message displayed when mouse is
 * over bitmap.  Only a subset of HTML
 * supported by our mini-HTML control is
 * supported.
 *
 * @see _StreamMarkerAdd
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern int _StreamMarkerAddB(_str BufName, long StartOffset, long Length, boolean isRealOffset, int BMIndex,int type,_str pszMessage);

/**
 * Removes line marker.
 *
 * @param LineMarkerIndex	Index of line marker returned by a _LineMarkerAdd function.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern void _LineMarkerRemove(int LineMarkerIndex);

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
extern void _LineMarkerRemoveAllType(int type);

/**
 * Removes stream marker.
 *
 * @param StreamMarkerIndex	Index of stream marker returned by a _StreamMarkerAdd function.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern void _StreamMarkerRemove(int StreamMarkerIndex);

/**
 * Removes all line markers that have the specified type from
 * window.
 *
 * @param type	Type of stream marker.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern void _LineMarkerRemoveType(int wid,int type);

/**
 * Removes all stream markers that have the specified type.
 *
 * @param type	Type of stream marker.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern void _StreamMarkerRemoveAllType(int type);

/**
 * Removes all stream markers that have the specified type from
 * window.
 *
 * @param type	Type of stream marker.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern void _StreamMarkerRemoveType(int wid, int type);

/**
 * Finds list of line markers which match.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 * @param list       Output.  List of line marker indexes.
 * @param wid        Window id of editor control.  0 specifies the
 *                   current object.
 * @param LineNum    Line number returned by
 *                   vsPropGetI(wid,VSP_LINE)
 * @param LineOffset Optional specifies offset to search for line markers
 *                   which use MarkIds.
 * @param CheckNofLines
 *                   When on, only line markers which NofLines which
 *                   include this line are returned.
 *
 */
extern void _LineMarkerFindList(int (&list)[],int wid,int LineNum,long LineOffset,boolean CheckNofLines);

/**
 *
 * @param list          Output.  List of stream marker indexes
 * @param wid           Window id of editor control.  0 specifies the current object.
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
 * @param           Find by type, or if 0
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
extern void _StreamMarkerFindList(int (&list)[],int wid,long StartOffset,long LineLen,long SearchStartOffset,int type);

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
 * </dd>
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
extern void _MarkerTypeSetFlags(int type,int MarkerTypeFlags);
/**
 * Sets the color index for the marker type specified. 
 *  
 * Currently only used for scroll markup stream markers 
 *
 * @param type	Index of marker type.
 *
 * @param Color index to set for this type.
 *
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
extern void _MarkerTypeSetColorIndex(int type,int ColorIndex);

/**
 * @return Returns the marker type flags for the marker type specified.
 *
 * @param type	Index of marker type.
 *
 * @see _MarkerTypeSetFlags
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
extern int _MarkerTypeGetFlags(int type);

/**
 * Sets the drawing priority for the marker type specified.
 *
 * @param type	Index of marker type.
 *
 * @param DrawPriority 	Drawing priority for this marker type 0
 *                      is the default (and highest) priority.
 *                      255 is the lowest priority possible.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
extern int _MarkerTypeSetPriority(int type, int DrawPriority);

/**
 * @return Returns the draw priority for the marker type specified.
 *         0 is the default (and highest) priority.
 *         255 is the lowest priority possible.
 *
 * @param type	Index of marker type.
 *
 * @see _MarkerTypeSetFlags
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
extern int _MarkerTypeGetPriority(int type);

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
extern void _LineMarkerSetMousePointer(int LineMarkerIndex,int MousePointer);

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
extern void _LineMarkerSetStyleColor(int LineMarkerIndex,int RGBBoxColor);

/**
 * Sets the RBG box color or squiggly line color for the stream marker specified..
 *
 * @param StreamMarkerIndex	Index of stream marker returned by a
 *                          vsStreamMarkerAdd function.
 *
 * @param RGBColor	RGB color
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern void _StreamMarkerSetStyleColor(int StreamMarkerIndex,int RGBBoxColor);

/**
 * Sets the color index for the text in the stream marker specified.
 *
 * @param StreamMarkerIndex   Index of stream marker returned by a
 *                            _StreamMarkerAdd function.
 * @param ColorIndex   Index of color allocated by {@link vsAllocColor}().  Specify 0 for no color (null).
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern void _StreamMarkerSetTextColor(int StreamMarkerIndex,int ColorIndex);

/**
 * Set length of the stream marker specified.
 *
 * @param StreamMarkerIndex   Index of stream marker returned by a
 *                            _StreamMarkerAdd function.
 * @param Length              New length.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern void _StreamMarkerSetLength(int StreamMarkerIndex,long Length);

/**
 * Set start offset for the stream marker specified.
 *
 * @param StreamMarkerIndex   Index of stream marker returned by a
 *                            _StreamMarkerAdd function.
 * @param StartOffset   New starting offset for the stream marker.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern void _StreamMarkerSetStartOffset(int StreamMarkerIndex,long StartOffset);

/**
 * Sets the color index for the text in the stream marker specified.
 *
 * @param StreamMarkerIndex   Index of stream marker returned by a
 *                            _StreamMarkerAdd function.
 * @param type               Replace type of stream marker.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Marker_Functions
 *
 */
extern void _StreamMarkerSetType(int StreamMarkerIndex,int type);

/**
 *
 * @param StreamMarkerIndex      Index of stream marker returned
 *                               by a _StreamMarkerAdd function.
 * @param message                Replace message.
 *
 * @return 0 if stream marker index is valid.
 * @appliesTo Edit_Window, Editor_Control
 * @categories Marker_Functions
 */
extern void _StreamMarkerSetMessage(int StreamMarkerIndex, _str pszMessage);

struct SCROLLBAR_MARKUP_INFO {
  int lineNumber;
  int len;
  int type;
  int handle;
};

/**
 * Allocate a type for scroll bar markers
 * 
 * @return int New marker type
 */
extern int _ScrollMarkupAllocType();


/**
 * Set the color for a type of scroll bar markers
 * 
 * @param wid Window ID of editor control 
 * @param iType Type returned by <B>vsScrollMarkupAllocType</B> 
 * @param iColorIndex a SlickEdit color index 
 * 
 * @return int 0 if successful
 */
extern int _ScrollMarkupSetTypeColor(int type,int colorIndex);


/**
 * Add a scroll bar mark
 * 
 * @param wid Window ID of editor control 
 * @param lineNum Line number to put mark on 
 * @param type Type returned by <B>vsScrollMarkupAllocType</B> 
 * @param length Number of lines in this mark, defaults to 1
 * 
 * @return int 0 if successful
 */
extern int _ScrollMarkupAdd(int wid,int lineNum,int type,int len=1);

/**
 * Note - len is still in lines
 */
extern int _ScrollMarkupAddOffset(int wid,long offset,int type,int len=1);

/**
 * Remove a scroll bar mark
 * 
 * @param wid Window ID of editor control 
 * @param scrollMarkupIndex Index of marker to remove
 */
extern void _ScrollMarkupRemove(int wid,int scrollMarkupIndex);

/**
 * Remove all scroll bar marks of a specified type from the 
 * specified editor control 
 * 
 * @param wid Window ID of editor control 
 * @param type Type returned by <B>vsScrollMarkupAllocType</B> 
 */
extern void _ScrollMarkupRemoveType(int wid, int type);

/**
 * Remove all scroll bar marks of a specified type
 * 
 * @param type Type returned by <B>vsScrollMarkupAllocType</B> 
 */
extern void _ScrollMarkupRemoveAllType(int type);

/**
 * Update scroll markup information for all child windows
 *  
 */
extern void _ScrollMarkupUpdateAllModels();

/**
 * 
 * Associate a standalone scrollbar with an editor control - 
 * this is only for the purposes of markup, it will not handle 
 * the actual scrolling. 
 *  
 * Vertical scroll bar must be current object 
 *  
 * Currently only supports vertical scrollbars 
 *  
 * @param wid Window ID of editor control to associate
 * 
 * @appliesTo Vscroll_Bar
 *
 * @categories Marker_Functions, Mouse_Functions
 */
extern void _ScrollMarkupSetAssociatedEditor(int wid);
extern void _ScrollMarkupUnassociateEditor(int wid);
extern void _ScrollMarkupGetMarkup(int wid,SCROLLBAR_MARKUP_INFO (&scrollMarkupInfo)[],long startLine=-1,long endLine=-1) ;
