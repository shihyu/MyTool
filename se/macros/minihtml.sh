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
#pragma option(metadata,"controls.e")

/**
 * Shrink the control's width and height to exactly fit the text.
 *
 * @param minWidth   minimum width in TWIPS to shrink to
 * @param minHeight  minimum height in TWIPS to shrink to
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_ShrinkToFit(int minWidth=0, int minHeight=0);

/**
 * Specify the default fixed font for the HTML control.
 *
 * @param pszFontName font name
 * @param charset     character set
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_SetDefaultFixedFont(_str pszFontName,int charset);

/**
 * Set the size of the default HTML fixed font
 *
 * @param size         font size
 * @param PointSizeX10 point size
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_SetDefaultFixedFontSize(int size,int PointSizeX10);

/**
 * Specify the default proportional font for the HTML control.
 *
 * @param pszFontName font name
 * @param charset     character set
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_SetDefaultProportionalFont(_str pszFontName,int charset);

/**
 * Set the size of the default HTML proportional font
 *
 * @param size         font size
 * @param PointSizeX10 point size
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_SetDefaultProportionalFontSize(int size,int PointSizeX10);

/**
 * Specify the current fixed font for the HTML control.
 *
 * @param pszFontName font name
 * @param charset     character set
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_SetFixedFont(_str pszFontName,int charset);

/**
 * Set the size of the current HTML fixed font
 *
 * @param size         font size [0..7], -1 to scale all sizes
 * @param PointSizeX10 point size
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_SetFixedFontSize(int size,int PointSizeX10);

/**
 * Specify the current proportional font for the HTML control.
 *
 * @param pszFontName font name
 * @param charset     character set
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_SetProportionalFont(_str pszFontName,int charset);

/**
 * Set the size of the current HTML proportional font
 *
 * @param size         font size [0..7], -1 to scale all sizes
 * @param PointSizeX10 point size
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_SetProportionalFontSize(int size,int PointSizeX10);

/**
 * Retrieve the scroll information about the HTML control.
 * This is used to save and restore the scroll position.
 *
 * @param ScrollInfo   (reference) scroll info.
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_GetScrollInfo(typeless &ScrollInfo);

/**
 * Reset the scroll information about the HTML control.
 * This is used to save and restore the scroll position.
 *
 * @param ScrollInfo   (reference) scroll info.
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern void _minihtml_SetScrollInfo(typeless ScrollInfo);

/**
 * Find a named anchor (for example, &lt;A name="xxx"&gt;) within the text.
 * Control will be positioned at that item if found.
 *
 * @param name       Anchor name
 * @param flags      search flags
 *                   <UL>
 *                   <LI>VSMHFINDANAMEFLAG_INCREASE_HEIGHT
 *                   <LI>VSMHFINDANAMEFLAG_CENTER_SCROLL
 *                   </UL>
 *
 * @return 0 on success, <0 on error.
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern int _minihtml_FindAName(_str name,int flags);

/**
 * Handle mouse click within HTML control
 *
 * @param mx         mouse X position
 * @param my         mouse Y position
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern _str _minihtml_click(int mx,int my,...);

/**
 * @return Returns true if there is a selection in the control.
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern int _minihtml_isTextSelected();

/**
 * Send control command to the HTML control.
 *
 * @param command    may be one of the following:
 *    <DL compact>
 *    <DT>top        <DD style="marginleft:60pt"> Go to the top of the document
 *    <DT>bottom     <DD style="marginleft:60pt"> Go to the bottom of the document
 *    <DT>pagedown   <DD style="marginleft:60pt"> Scroll to next page
 *    <DT>pageup     <DD style="marginleft:60pt"> Scroll to previous page
 *    <DT>scrollup   <DD style="marginleft:60pt"> Scroll up as if pressing the scroll up button on
 *                                                the vertical scroll bar.
 *    <DT>scrolldown <DD style="marginleft:60pt"> Scroll down as if pressing the scroll down button on
 *                                                the vertical scroll bar.
 *    <DT>pageleft   <DD style="marginleft:60pt"> Scroll left one page.
 *    <DT>pageright  <DD style="marginleft:60pt"> Scroll right one page.
 *    <DT>scrollleft <DD style="marginleft:60pt"> Scroll left as if pressing the scroll left button on
 *                                                the horrizontal scroll bar.
 *    <DT>scrollright<DD style="marginleft:60pt"> Scroll right as if pressing the scroll right button on
 *                                                the horrizontal scroll bar.
 *    <DT>copy       <DD style="marginleft:60pt"> Copy selection or all text to clipboard if nothing selected
 *    <DT>copyall    <DD style="marginleft:60pt"> Copy all text to clipboard
 *    <DT>selectall  <DD style="marginleft:60pt"> Remove selection
 *    <DT>deselect   <DD style="marginleft:60pt"> Select all text in control
 *    <DT>zoomin     <DD style="marginleft:60pt"> Zoom in (increases font sizes)
 *    <DT>zoomout    <DD style="marginleft:60pt"> Zoom out (decreases font sizes)
 *    <DT>unzoom     <DD style="marginleft:60pt"> Unzoom (revert to default font sizes)
 *    <DT>zoom [n]   <DD style="marginleft:60pt"> Zoom to specified font size (or return current font size)
 *    </DL>
 * 
 * @appliesTo Mini_HTML
 * @categories Mini_HTML_Methods
 */
extern int _minihtml_command(_str command);

