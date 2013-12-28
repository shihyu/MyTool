////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46084 $
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
#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strictparens,on)
#pragma option(autodeclvars,off)

#import "xmlwrap.e"
#import "xmlcfg.e"

/**
 * Command to automatically insert a docbook ID into the editor.
 * 
 * @author shackett (1/27/2009)
 */
_command void insert_docbook_id() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str toInsert = create_docbook_id();
   _insert_text(toInsert);
}

/**
 * Creates a new ID for a docbook entity such as a section or 
 * chapter.  The result of running this function will create the
 * following:
 *  
 *    id="x_y_z" 
 *  
 * where x is the file name with no path or extension, y is 
 * derived from the binary time and z is a random number.  For 
 * instance, if you are working in the file 
 * "C:\docs\src\slickedit\sect_myfeature.docbook", you might get 
 * an insert that looks like: 
 *  
 *    id="sect_myfeature_23423_31906"
 * 
 * @author shackett (1/27/2009)
 */
_str create_docbook_id()
{
   // take the last 5 characters from the binary time
   _str binaryTime = _time('B');
   _str firstFive = substr(binaryTime, length(binaryTime) - 4, 5);
   int seedTime = (int)firstFive;

   // create a psuedo-random seed
   int seed = random(0, 99999);
   if(seed < 0)
      seed *= -1;
   _str seedStr = '00000'(_str)seed;
   _str secondFive = substr(seedStr, length(seedStr) - 4, 5);

   // strip the document's path and extensdion, then append the previously generated numbers
   return 'id="'_strip_filename(p_buf_name, 'PE')'_'firstFive'_'secondFive'"';
}


/**
 * This is used by the Preview window to extract something meaningful to put 
 * from the tag to display in the html window that normally displays the 
 * doccomment contents.  For now, it will extract the value of the xreflabel 
 * attribute.  if not xreflabel attribute, then use the whole tag with line
 * breaks condensed. 
 * 
 * @author dobrien (10/28/2009)
 * 
 * @return _str 
 */
_str create_docbook_comment_str(_str tagname = '') {
   _str returnVal = "no comment";
   //Search for the tagname occurence.  This is because at this point the
   //cursor should be located at column 1 of the line that the tag starts on.
   //There could be another tag preceeding the one that we want.
   save_pos(auto start_pos);
   //Be sure we are at column 1.
   p_col = 1;
   long startColOneOffset = _QROffset();
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   if (!search(XW_namedAttributeRegex('id', tagname), '@RHXCS')) {
      //Now we know we are in the proper element tag.
      long startIdAttribOffset = _QROffset();
      //Go to start of element.
      if (!search(XW_TAG_OPEN_BRACKET,'@-HXCS') && _QROffset() >= startColOneOffset) {
         long start_seekpos = _QROffset();
         select_char();
         //Go to end of element.
         if (!search(XW_TAG_CLOSE_BRACKET,'@HXCS') && _QROffset() > startIdAttribOffset) {
            lock_selection('q');
            //Element is selected, now search in selection for xreflabel attribute.
            _GoToROffset(start_seekpos);
            if (!search(XW_namedAttributeRegex('xreflabel'), '@MRHXCS')) {
               returnVal = get_text(match_length('0'), match_length('S0'));
            } else {
               //Didn't find xreflable, so extract element instead.
               returnVal = "no xreflabel attribute";
            }
         }
         deselect();
      }
   }
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(start_pos);
   return returnVal;
}

/**
 * Extract comments for the given docbook id tag, located in the given file and 
 * line number. 
 *
 * @param member_msg     (output) comment for docbook tag
 * @param tag_name       name of tag to search for
 * @param file_name      name of file that the tag is located in
 * @param line_no        the 'start' line for the tag
 *
 * @return 0 on success, nonzero on error
 */
int _docbook_ExtractTagComments2(_str &member_msg, _str tag_name, _str file_name, int line_no) {
   // try to create a temp view for the file
   boolean already_loaded = false;
   int     temp_view_id, orig_view_id;
   int status = _open_temp_view(file_name, temp_view_id, orig_view_id, '', already_loaded, false, true);
   if (status) {
      return status;
   }

   p_line = line_no; p_col = 1;
   member_msg = create_docbook_comment_str(tag_name);

   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   return 0;
}

/**
 * Format the given dooc book tag for mouse over display.  For docbook this is 
 * simply returning the name of the tag. 
 * The current object must be an editor control.
 *
 * @param lang           Current language ID {@see p_LangId} 
 * @param info           tag information
 *                       <UL>
 *                       <LI>info.class_name
 *                       <LI>info.member_name
 *                       <LI>info.type_name;
 *                       <LI>info.flags;
 *                       <LI>info.return_type;
 *                       <LI>info.arguments
 *                       <LI>info.exceptions
 *                       </UL>
 * @param flags          bitset of VSCODEHELPDCLFLAG_*
 * @param decl_indent_string    string to indent declaration with.
 * @param access_indent_string  string to indent public: with. 
 * @param header_list           array of strings that is a comment to insert 
 *                              between the access modifier and the declaration.
 *
 * @return string holding formatted declaration.
 */
_str _docbook_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0, 
                 _str decl_indent_string="",
                 _str access_indent_string="", _str (&header_list)[] = null)
{
   return info.member_name;
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _docbook_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   int status= _xml_get_expression_info(PossibleOperator,idexp_info,visited,depth);
   if (_in_string() && idexp_info.lastid != null && last_char(idexp_info.lastid) == '"' && last_char(idexp_info.lastid) == "'") {
      idexp_info.lastid = substr(idexp_info.lastid, 1, idexp_info.lastid._length() - 1);
   }
   return(status);
}

_command int docbook_promote() {
   return docbook_sectAdjust(-1, _QROffset());
}
_command int docbook_demote() {
   return docbook_sectAdjust(1, _QROffset());
}
_command int docbook_sectAdjust(int delta = 1, long startOffset = 0) {
   return XW_sectadjust(delta, startOffset);
}

/**
 * Returns the topmost set1 node in the current file.
 */
_command _str GetTopmostSection1()
{
   int status = 0;
   int sectNode = 0;
   // open the current buffer and parse it
   int handle = _xmlcfg_open_from_buffer(p_window_id, status);
   if (status != 0) {
      return "";
   }
   // look for the first sect1 node
   sectNode = _xmlcfg_find_simple(handle, '//sect1');
   // get its ID
   _str idValue = _xmlcfg_get_attribute(handle, sectNode, "id");
   // close the xml parser
   _xmlcfg_close(handle);
   // return the ID value
   return idValue;
}
