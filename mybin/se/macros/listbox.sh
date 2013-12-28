////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47389 $
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

extern void _lbadd_bounded(_str text, int max_items=25);
/**
 * Selects the current item in the list box.  The p_Nofselected property is incremented
 * if the current item was not selected.
 *
 * @see _lbdeselect_all
 * @see _lbselect_all
 * @see _lbdeselect_line
 * @see _lbinvert
 * @see _lbisline_selected
 * @see _lbmulti_select_result
 * @see _lbfind_selected
 *
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
extern void _lbselect_line();
/**
 * Deselects the current item in the list box.  The p_Nofselected property
 * is decremented if the current item was selected.
 *
 * @see _lbdeselect_all
 * @see _lbselect_all
 * @see _lbselect_line
 * @see _lbinvert
 * @see _lbisline_selected
 * @see _lbmulti_select_result
 * @see _lbfind_selected
 *
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
extern void _lbdeselect_line();
/**
 * Selects all lines in a list box.  The p_Nofselected property is set to the
 * number of lines in the list box.  Do not call this function if the
 * p_multi_select property is MS_NONE.
 *
 * @see _lbdeselect_all
 * @see _lbselect_line
 * @see _lbdeselect_line
 * @see _lbinvert
 * @see _lbisline_selected
 * @see _lbmulti_select_result
 * @see _lbfind_selected
 *
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
extern void _lbselect_all();
/**
 * Select all lines in the list box which are currently not selected and deselects
 * all lines which are selected.
 *
 * @see _lbdeselect_all
 * @see _lbselect_all
 * @see _lbselect_line
 * @see _lbdeselect_line
 * @see _lbfind_selected
 * @see _lbmulti_select_result
 * @see _lbisline_selected
 *
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
extern void _lbinvert();
/**
 * Deselects all selected lines in a list box.  The p_Nofselected property is set to 0.
 *
 * @see _lbselect_all
 * @see _lbselect_line
 * @see _lbdeselect_line
 * @see _lbinvert
 * @see _lbisline_selected
 * @see _lbmulti_select_result
 * @see _lbfind_selected
 *
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
extern void _lbdeselect_all();
/**
 * Returns non-zero value if the current line in the list box is selected.
 *
 * @see _lbdeselect_all
 * @see _lbselect_all
 * @see _lbselect_line
 * @see _lbdeselect_line
 * @see _lbinvert
 * @see _lbfind_selected
 * @see _lbmulti_select_result
 *
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
extern _str _lbisline_selected();
/**
 * Search for a whole item in the list box or combo box which 
 * matches the given text.  If the combo box or list box is 
 * case-sensitive, it will search for an exact match, otherwise 
 * it will search case-insensitive. 
 * 
 * @param text    string to search for
 *
 * @return Returns 	index was found on, negative return
 *    					code if item was not found.  Index is
 *    					0-based, so if setting p_line to return
 *    					value, add one.
 * 
 * @see _lbsearch
 *
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
extern int _lbfind_item(_str text, int start=0);
extern _str _lbbeginline_re();
extern _str _lbsearch2(_str text, _str options="");
extern void _lbclear2();
extern int _lbsort2(_str options,int start,int count);
extern int _lbremove_duplicates(_str options="",int start=0,int count=MAXINT);
extern void _lbbegin_update();
extern void _lbend_update(int index);
extern void _lbadd_item2(_str &text,int pic_index);
extern void _lbset_item2(_str &text,int pic_index);
extern void _lbsave_pos(typeless &p);
extern void _lbrestore_pos(typeless p);

extern void _lbselect_line_index(int lineNum);
extern void _lbdeselect_line_index(int lineNum);
extern boolean _lbisline_selected_index(int lineNum);
extern void _lbexit_scroll();
extern void _lbget_item_index(int lineNum,_str &text,int &pic_index);
extern void _lbadd_item_index(int lineNum,_str text,int pic_index);
extern void _lbset_item_index(int lineNum,_str text,int pic_index);
extern int _lbdelete_item_index(int lineNum);
extern void _lbdeselect_all();
extern void _lbselect_all();
extern void _lbinvert();
extern int _lbsearch_index(int lineNum,_str pszText,_str pszOptions);
extern void _lbline_to_top();
extern void _lbline_to_bottom();
extern int _lbfind_next_selected_index(int lineNum);
extern void _lbcommand(_str command);
