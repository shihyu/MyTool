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
#pragma option(metadata,"color.e")

extern bool _clex_InString(int LineFlags);
extern bool _clex_InComment(int LineFlags);
extern bool _clex_InState(int LineFlags);

/**
 * Returns the color index for the character at the cursor.
 *
 * @see _FreeColor
 * @see _AllocColor
 * @see _SetTextColor
 * @see _default_color
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
extern int _GetTextColor();


/**
 * Get global text color marker type.  Marker type can used with
 * to _StreamMarker to find and delete markers.
 *
 * @return  Marker type used by _SetTextColor and search
 *          & replace for highlighting.
 * @see _SetTextColor
 * @see _MarkerTypeAlloc
 */
extern int _GetTextColorMarkerType();

/**
 * Get global scroll color marker type.  Marker type can used 
 * with to _ScrollMarkup* functions to find and delete 
 * markers. 
 *
 * @return  Marker type used by _ScrollMarkup* functions
 * @see _ScrollMarkupAddOffset
 * @see _ScrollMarkupRemoveType
 * @see _ScrollMarkupRemoveAllType
 */
extern int _GetScrollColorMarkerType();

/**
 * Sets the tag filename for the current buffer used for XML Context Tagging&reg; and
 * may create or update an XML color coding lexer associated with this tag file.
 *
 * @param ForceUpdate	Indicates whether to always update an existing XML color coding lexer for this <i>TagFilename</i>.  This option is most useful for allowing DTD changes to be reapplied.  It can also be useful if you have muliple buffers using the same tag file (same DTD).
 * @param TagFilename	Name of tag file.
 *
 * @appliesTo	Edit_Window, Editor_Control
 *
 * @categories Editor_Control_Methods, Miscellaneous_Functions
 */
extern void _clex_xmlSetConfig(bool forceUpdate,_str pszTagFilename);


/**
 * Returns the tag filename for the current buffer used for XML
 * Context Tagging&reg; and color coding.
 *
 * @appliesTo	Edit_Window, Editor_Control
 * @return the tag filename
 *
 * @categories Editor_Control_Methods, Miscellaneous_Functions
 */
extern _str _clex_xmlGetConfig();


/**
 * Adds the tag and attributes specified to the XML color coding for the current
 * buffer.
 *
 * @param tag_name	XML tag name.
 * @param attr_list	Space delimited list of attributes which belong to the
 * <i>tag_name</i> specified.
 *
 * @appliesTo	Edit_Window, Editor_Control
 *
 * @categories Editor_Control_Methods, Miscellaneous_Functions
 */
extern void _clex_xmlAddKeywordAttrs(_str tag_name,_str attr_list, ...);

/**
 * Sets the tag filename for the current buffer used for JSP Context Tagging&reg; and
 * may create or update an XML color coding lexer associated with this tag file.
 *
 * @param ForceUpdate	Indicates whether to always update an existing XML color coding lexer for this <i>TagFilename</i>.  This option is most useful for allowing DTD changes to be reapplied.  It can also be useful if you have muliple buffers using the same tag file (same DTD).
 * @param TagFilename	Name of tag file.
 *
 * @appliesTo	Edit_Window, Editor_Control
 *
 * @categories Editor_Control_Methods, Miscellaneous_Functions
 */
extern void _clex_jspSetConfig(bool forceUpdate,_str pszTagFilename);


/**
 * Returns the tag filename for the current buffer used for JSP
 * Context Tagging&reg; and color coding.
 *
 * @appliesTo	Edit_Window, Editor_Control
 * @return the tag filename
 *
 * @categories Editor_Control_Methods, Miscellaneous_Functions
 */
extern _str _clex_jspGetConfig();


/**
 * Adds the tag and attributes specified to the XML color coding for the current
 * buffer.
 *
 * @param tag_name	JSP tag name.
 * @param attr_list	Space delimited list of attributes which belong to the
 * <i>tag_name</i> specified.
 *
 * @appliesTo	Edit_Window, Editor_Control
 *
 * @categories Editor_Control_Methods, Miscellaneous_Functions
 */
extern void _clex_jspAddKeywordAttrs(_str tag_name,_str attr_list,...);



/**
 * Export current buffer to filename using HTML formatting for
 * color coding and font information.  Filename is absolute file
 * name with no options.
 *
 * @appliesTo Edit_Window
 *
 * @return Returns 0 if successful.
 */
extern int _ExportColorCodingToHTML(_str filename);

extern int _GetHTMLColorCoding(int wid, int linenum, int noflines, _str &text);

