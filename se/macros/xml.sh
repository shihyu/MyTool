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
#pragma option(metadata,"xml.e")


struct  XmlCfgPropertyInfo {
   _str name;
   _str value;
   bool apply;
};
/**
 * Opens an XML file and parses the file.
 * Returns a handle to the XML document.
 * This handle is used to get any parsing errors.
 * See {@link _xml_get_num_errors} and {@link _xml_get_error_info}. 
 *
 * Be sure to close the XML document by calling {@link _xml_close}.
 *
 * <P>
 *
 * @param Filename  Name of the XML file to open
 * @param status    Set to 0 if succesful. Otherwise this is set to
 *                  negative error code.
 * @param iEncoding For standard XML files, this parameter should be VSENCODING_AUTOXML.  For Microsort .NET project files, this parameter should be VSCP_ACTIVE_CODEPAGE.
 *
 * <P>encoding may be one of the following:
 *
 * <PRE>VSCP_ACTIVE_CODEPAGE
 * VSCP_EBCDIC
 * VSCP_CYRILLIC_KOI8_R
 * VSCP_ISO_8859_1
 * VSCP_ISO_8859_2
 * VSCP_ISO_8859_3
 * VSCP_ISO_8859_4
 * VSCP_ISO_8859_5
 * VSCP_ISO_8859_6
 * VSCP_ISO_8859_7
 * VSCP_ISO_8859_8
 * VSCP_ISO_8859_9
 * VSCP_ISO_8859_10
 * Any valid Windows code page
 * VSENCODING_AUTOUNICODE
 * VSENCODING_AUTOXML
 * VSENCODING_UTF8
 * VSENCODING_UTF8_WITH_SIGNATURE
 * VSENCODING_UTF16LE
 * VSENCODING_UTF16LE_WITH_SIGNATURE
 * VSENCODING_UTF16BE
 * VSENCODING_UTF16BE_WITH_SIGNATURE
 * VSENCODING_UTF32LE
 *
 * VSENCODING_UTF32LE_WITH_SIGNATURE
 * VSENCODING_UTF32BE
 * VSENCODING_UTF32BE_WITH_SIGNATURE
 * </PRE>
 * @param OpenFlags one of the following flags:
 *
 *                  <DL>
 *                  <DT>VSXML_VALIDATION_SCHEME_WELLFORMEDNESS</dt><DD>
 *                  When specified, performs a well-formedness check on the
 *                  document.  No validation is done</DD>
 *                  <DT>VSXML_VALIDATION_SCHEME_VALIDATE</dt><DD>
 *                  When specified, the document is validated against the
 *                  documents DTD or schema.</DD>
 *                  <DT>VSXML_VALIDATION_SCHEME_AUTO</DT><DD>
 *                  When specified, validates the document if a DTD or schema
 *                  is specified in the XML document.  If neither a DTD or
 *                  schema definition is specified, then a well-formedness
 *                  check is performed.</DD>
 *
 * @return handle to the document if succesful ( >=0 ).  Otherwise a
 *         negative error code is returned.
 */
extern int _xml_open(_str Filename,int &status,int OpenFlags, int iEncoding=VSENCODING_AUTOXML);


/**
 * Opens an XML document from a buffer and parses the buffer.
 * Returns a handle to the XML document.
 * This handle is used to get any parsing errors.
 * See {@link _xml_get_num_errors} and {@link _xml_get_error_info}.
 *
 * Be sure to close the XML document by calling {@link _xml_close}.
 *
 * <P>
 *
 * @param wid       Window id of control containing the buffer for the XML Document
 * @param status    Set to 0 if succesful. Otherwise this is set to
 *                  negative error code.
 * @param OpenFlags one of the following flags:
 *
 *                  <DL>
 *                  <DT>VSXML_VALIDATION_SCHEME_WELLFORMEDNESS</dt><DD>
 *                  When specified, performs a well-formedness check on the
 *                  document.  No validation is done</DD>
 *                  <DT>VSXML_VALIDATION_SCHEME_VALIDATE</dt><DD>
 *                  When specified, the document is validated against the
 *                  documents DTD or schema.</DD>
 *                  <DT>VSXML_VALIDATION_SCHEME_AUTO</DT><DD>
 *                  When specified, validates the document if a DTD or schema
 *                  is specified in the XML document.  If neither a DTD or
 *                  schema definition is specified, then a well-formedness
 *                  check is performed.</DD>
 *
 * @param StartRealSeakPos Start position within the control's buffer to use for
 *                         XML document
 * @param EndREalSeekPos  End position within the control's buffer to use for the
 *                        XML document
 *
 * @return handle to the document if succesful ( >=0 ).  Otherwise a
 *         negative error code is returned.
 */
extern int _xml_open_from_control(int wid,int &status,int OpenFlags=VSXML_VALIDATION_SCHEME_AUTO,int StartRealSeekPos=0,int EndRealSeekPos= -1);


/**
 * Closes an XML document that was previously opened via 
 * {@link _xml_open} or {@link _xml_open_from_buffer}.
 *
 *
 * <P>
 *
 * @param iHandle    XML Document handle returned from 
 *                   {@link _xml_open} or {@link _xml_open_from_buffer}
 *
 * @return 0 if successful, nonzero if an error occured
 *
 */
extern int _xml_close(int iHandle);

/**
 * Returns the number of parsing errors that occured when opening the
 * specified XML document.
 *
 * @param iHandle Handle to an XML document (returned from 
 *                {@link _xml_open} or {@link _xml_open_from_buffer)
 *
 * @return Number of parsing errors
 *
 */
extern int _xml_get_num_errors(int iHandle);

/**
 * Gets the parsing error information for a specified parsing error.
 *
 * @param iHandle    XML Document handle returned from 
 *                   {@link _xml_open} or {@link _xml_open_from_buffer}
 * @param errIndex   Specifies which error to get information on
 * @param line       Set to the 1 based line number where the error occurred
 * @param col        Set to the 1 based column number where the error occurred
 * @param fn         Set to the file name or buffer name where the error occured
 * @param msg        Set to the description of the error
 *
 * @return 0 if success, non zero if error (e.g. index out of range, invalid document handle)
 */
extern int _xml_get_error_info(int iHandle, int errIndex, int &line, int &col, _str &fn, _str &msg);



/**
 * Duplicates a tree
 *
 * @param DestHandle Handle of destination tree
 * @param DestNodeIndex
 *                   Index of destination node
 * @param SrcHandle  Handle to source tree
 * @param iSrcNodeIndex
 *                   Index of source node
 * @param flags      Specifies one of the following flags:
 *
 *                   <dl>
 *                   <dt>VSXMLCFG_COPY_CHILDREN<dd>copy children of source as the last children of the dest
 *                   <dt>VSXMLCFG_COPY_AS_CHILD<dd>copy the source as the last child of the dest
 *                   <dt>VSXMLCFG_COPY_BEFORE<dd>copy the source as a sibling before the dest
 *                   </dl>
 *                   Specify no flags to copy as a sibling after dest.   Note that this
 *                   function can not copy children as siblings.  Use the
 *                   _xmlcfg_copy_children_as_siblings() function to perform this operation.
 *
 * @return Returns first node created or VSRC_XMLCFG_NO_CHILDREN_COPIED if successful. Otherwise,
 *         an negative error code other than VSRC_XMLCFG_NO_CHILDREN_COPIED is returned.
 *
 * @example <pre>
 * // Add tree as last child
 * _xmlcfg_copy(DestHandle,DestNodeIndex,
 *    SrcHandle,SrcNodeIndex,VSXMLCFG_COPY_A_CHILD);
 *
 * // Add tree before dest node
 * _xmlcfg_copy(DestHandle,DestNodeIndex,
 *    SrcHandle,SrcNodeIndex,VSXMLCFG_COPY_BEFORE);
 *
 * // Add tree after dest node
 * _xmlcfg_copy(DestHandle,DestNodeIndex,
 *    SrcHandle,SrcNodeIndex);
 *
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_copy(int DestHandle,int DestNodeIndex,int SrcHandle,int iSrcNodeIndex,int flags);

/**
 * Opens an XML file and loads it into a tree.
 * returns a handle to the tree
 *
 * @param Filename  Name of the XML file to open
 * @param status    Set to 0 if succesful. Otherwise this is set to
 *                  negative error code.
 * @param OpenFlags zero or more of the following flags:
 *
 *                  <DL>
 *                  <DT>VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA</dt><DD>
 *                  When specified, non-whitespace PCDATA (text
 *                  between tags including white space) nodes
 *                  are added to tree. If all the PCDATA is
 *                  whitespace (' ','\t','\r','\n'), no PCDATA
 *                  is inserted. CDATA (&lt;![CDATA[ ... ]]>)
 *                  nodes are always added to the tree.
 *                  </DD>
 *                  <DT>VSXMLCFG_OPEN_ADD_ALL_PCDATA</dt><DD>
 *                  When specified, PCDATA (text between tags including white space) nodes
 *                  are added to tree.  CDATA (&lt;![CDATA[ ... ]]>) nodes are always added to
 *                  the tree.
 *                  </DD>
 *                  <DT>VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR</dt><DD>
 *                  When specified, a valid tree handle is returned even if the
 *                  XML document is not well formed.
 *                  <p>One useful
 *                  purpose for this option is to determine the namespaces
 *                  for the current element. Unless
 *                  the VSRC_XMLCFG_INPUT_ENDED_BEFORE_ALL_TAGS_WERE_TERMINATED is
 *                  returned, you can't be sure if the XML tree was parsed up to the
 *                  the current element.  Therefore, when determining the current
 *                  namespaces, truncate the buffer before the '&lt;' for the current element
 *
 *                  <P>If a unrecoverable error occurs like "out of memory", a
 *                  negative error code is returned.
 *
 *                  <P>By default, negative error code is returned.
 *
 *                  <P><B>Note</B>: this function DOES NOT perform a
 *                  thorough well formness check.
 *                  <DT>VSXMLCFG_OPEN_REFCOUNT</dt><DD>
 *                  When specified, a search is preformed in the XMLCFG open file cache
 *                  for a filename which already has the name given to open.  If it is
 *                  found, the reference count is incremented and the same XMLCFG
 *                  handle is returned.  _xmlcfg_close always decrements the reference
 *                  count and closes the file when the reference count is 0.
 *
 *                  </DD>
 *                  </dl>
 * @param iEncoding For standard XML files, this parameter should be VSENCODING_AUTOXML.  For Microsort .NET project files, this parameter should be VSCP_ACTIVE_CODEPAGE.
 *
 * <P>encoding may be one of the following:
 *
 * <BLOCKQUOTE><PRE>VSCP_ACTIVE_CODEPAGE
 * VSCP_EBCDIC
 * VSCP_CYRILLIC_KOI8_R
 * VSCP_ISO_8859_1
 * VSCP_ISO_8859_2
 * VSCP_ISO_8859_3
 * VSCP_ISO_8859_4
 * VSCP_ISO_8859_5
 * VSCP_ISO_8859_6
 * VSCP_ISO_8859_7
 * VSCP_ISO_8859_8
 * VSCP_ISO_8859_9
 * VSCP_ISO_8859_10
 * Any valid Windows code page
 * VSENCODING_AUTOUNICODE
 * VSENCODING_AUTOXML
 * VSENCODING_UTF8
 * VSENCODING_UTF8_WITH_SIGNATURE
 * VSENCODING_UTF16LE
 * VSENCODING_UTF16LE_WITH_SIGNATURE
 * VSENCODING_UTF16BE
 * VSENCODING_UTF16BE_WITH_SIGNATURE
 * VSENCODING_UTF32LE
 *
 * VSENCODING_UTF32LE_WITH_SIGNATURE
 * VSENCODING_UTF32BE
 * VSENCODING_UTF32BE_WITH_SIGNATURE
 * </PRE></BLOCKQUOTE>
 *
 * @return handle to the tree if succesful ( >=0 ).  Otherwise a
 *         negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_open(_str Filename,int &status,int OpenFlags=0,int iEncoding=VSENCODING_AUTOXML);


/**
 * Opens and parses an XML file into a tree.  The XMLCFG function
 * are intended to be used on valid XML files for reading and
 * writing various configuration information.  The XMLCFG
 * functions are not for validating or checking for well
 * formedness.
 *
 * @param wid       Window id of editor control.
 * @param status    (Output only) Set to 0 if successful.  Otherwise a negative error code.
 * @param OpenFlags zero or more of the following flags:
 *
 *                  <DL>
 *                  <DT>VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA</dt><DD>
 *                  When specified, non-whitespace PCDATA (text
 *                  between tags including white space) nodes
 *                  are added to tree. If all the PCDATA is
 *                  whitespace (' ','\t','\r','\n'), no PCDATA
 *                  is inserted. CDATA (&lt;![CDATA[ ... ]]>)
 *                  nodes are always added to the tree.
 *                  </DD>
 *                  <DT>VSXMLCFG_OPEN_ADD_ALL_PCDATA</dt><DD>
 *                  When specified, PCDATA (text between tags including white space) nodes
 *                  are added to tree.  CDATA (&lt;![CDATA[ ... ]]>) nodes are always added to
 *                  the tree.
 *                  </DD>
 *                  <DT>VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR</dt><DD>
 *                  When specified, a valid tree handle is returned even if the
 *                  XML document is not well formed.
 *                  <p>One useful
 *                  purpose for this option is to determine the namespaces
 *                  for the current element. Unless
 *                  the VSRC_XMLCFG_INPUT_ENDED_BEFORE_ALL_TAGS_WERE_TERMINATED is
 *                  returned, you can't be sure if the XML tree was parsed up to the
 *                  the current element.  Therefore, when determining the current
 *                  namespaces, truncate the buffer before the '&lt;' for the current element
 *
 *                  <P>If a unrecoverable error occurs like "out of memory", a
 *                  negative error code is returned.
 *
 *                  <P>By default, negative error code is returned.
 *
 *                  <P><B>Note</B>: this function DOES NOT perform a
 *                  thorough well formness check.
 *                  </Dl>
 * @param StartRealSeekPos
 *                  Start real seek position to start reading XML text.
 * @param EndRealSeekPos
 *                  End real seek position of XML text.
 *
 * @return Returns XMLCFG tree handle if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_open_from_buffer(int wid,int &status,int OpenFlags=0,
                             int StartRealSeekPos=0,long EndRealSeekPos= -1);


/**
 * Opens and parses an XML file into a tree.  The XMLCFG function are intended to be 
 * used on valid XML files for reading and writing various 
 * configuration information.  The XMLCFG functions are not for 
 * validating or checking for well formedness. 
 *
 * @param string    (Input only) String containing XML
 * @param status    (Output only) Set to 0 if successful.  Otherwise a negative error code.
 * @param OpenFlags zero or more of the following flags:
 *
 *                  <DL>
 *                  <DT>VSXMLCFG_OPEN_ADD_PCDATA</dt><DD>
 *                  When specified, PCDATA (text between tags including white space) nodes
 *                  are added to tree.  CDATA (&lt;![CDATA[ ... ]]>) nodes are always added to
 *                  the tree.
 *                  </DD>
 *                  <DT>VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR</dt><DD>
 *                  When specified, a valid tree handle is returned even if the
 *                  XML document is not well formed.
 *                  <p>One useful
 *                  purpose for this option is to determine the namespaces
 *                  for the current element. Unless
 *                  the VSRC_XMLCFG_INPUT_ENDED_BEFORE_ALL_TAGS_WERE_TERMINATED is
 *                  returned, you can't be sure if the XML tree was parsed up to the
 *                  the current element.  Therefore, when determining the current
 *                  namespaces, truncate the buffer before the '&lt;' for the current element
 *
 *                  <P>If a unrecoverable error occurs like "out of memory", a
 *                  negative error code is returned.
 *
 *                  <P>By default, negative error code is returned.
 *
 *                  <P><B>Note</B>: this function DOES NOT perform a
 *                  thorough well formness check.
 *                  </Dl>
 *
 * @return Returns XMLCFG tree handle if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_open_from_string(_str &string,int &status,int OpenFlags=0);
                             

/**
 * Creates or opens an existing XMLCFG tree.
 *
 * @param Filename  Name of XML file to create.  No disk I/O occurs.
 * @param iEncoding For standard XML files, this parameter should be VSENCODING_UTF8.
 * For Visual Studio 2002/2003 project files, this parameter should be
 * VSCP_ACTIVE_CODEPAGE. For Visual Studio 2005, use VSENCODING_UTF8.
 * Do not use VSENCODING_AUTOXML for creating new documents. But
 * VSENCODING_AUTOXML is valid when using VSXMLCFG_CREATE_IF_EXISTS_OPEN.
 *
 * <P>encoding may be one of the following:
 *
 * <blockquote><pre>VSCP_ACTIVE_CODEPAGE
 * VSCP_EBCDIC
 * VSCP_CYRILLIC_KOI8_R
 * VSCP_ISO_8859_1
 * VSCP_ISO_8859_2
 * VSCP_ISO_8859_3
 * VSCP_ISO_8859_4
 * VSCP_ISO_8859_5
 * VSCP_ISO_8859_6
 * VSCP_ISO_8859_7
 * VSCP_ISO_8859_8
 * VSCP_ISO_8859_9
 * VSCP_ISO_8859_10
 * Any valid Windows code page
 * VSENCODING_AUTOUNICODE
 * VSENCODING_UTF8
 * VSENCODING_UTF8_WITH_SIGNATURE
 * VSENCODING_UTF16LE
 * VSENCODING_UTF16LE_WITH_SIGNATURE
 * VSENCODING_UTF16BE
 * VSENCODING_UTF16BE_WITH_SIGNATURE
 * VSENCODING_UTF32LE
 * VSENCODING_UTF32LE_WITH_SIGNATURE
 * VSENCODING_UTF32BE
 * VSENCODING_UTF32BE_WITH_SIGNATURE
 * </pre></blockquote>
 * @param CreateOption
 *                  One of the following options.
 *
 *                  <DL>
 *                  <DT>VSXMLCFG_CREATE_IF_EXISTS_CLEAR</DT>
 *                  <DD>If this XMLCFG tree already exists, clear the contents of the tree.</DD>
 *                  <DT>VSXMLCFG_CREATE_IF_EXISTS_OPEN</DT>
 *                  <DD>If this XMLCFG tree already exists, just return the existing handle.</DD>
 *                  <DT>VSXMLCFG_CREATE_IF_EXISTS_ERROR</DT>
 *                  <DD>If  this XMLCFG tree already exists, return an error.</DD>
 *                  <DT>VSXMLCFG_CREATE_IF_EXISTS_CREATE</DT>
 *                  <DD>If  this XMLCFG tree already exists, create a new tree with the same name.</DD>
 *                  </DL>
 *
 * @return Returns XMLCFG tree handle if successful.  Otherwise a negative return code defined in "rc.sh" is returned
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_create(_str Filename,int iEncoding,int CreateOption=VSXMLCFG_CREATE_IF_EXISTS_CREATE);
/**
 * Decrements the open count and closes XMLCFG tree when the count reaches zero.
 *
 * @param iHandle Handle to tree to free
 *
 * @return 0 if successful
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_close(int iHandle);
/**
 * Gets the filename for the XMLCFG tree specified.  This is the name specified in the
 * _xmlcfg_open and _xmlcfg_create calls.
 *
 * @param iHandle    XMLCFG tree handle returned from _xmlcfg_open, _xmlcfg_open_from_buffer, or _xmlcfg_create
 *
 * @categories XMLCFG_Functions
 */
extern _str _xmlcfg_get_filename(int handle);


/**
 * Sorts nodes that are children of a specified node.
 *
 * @param iHandle XMLCFG tree handle returned from _xmlcfg_open, _xmlcfg_open_from_buffer, or _xmlcfg_create
 * @param ParentNodeIndex
 *                Children of this node are sorted
 * @param PrimaryAttrName
 *                Primary attribute name to sort on.
 *                Instead of an attribute name, this can be an
 *                XPath expression. This is very handy when the
 *                attribute you need to sort on is an element
 *                beneath the node being sorted. For example, 
 *                "attrs/@position" specifies "attrs" element is
 *                beneath the node being sorted has a position
 *                attribute.
 * @param PrimaryOptions
 *                String of one or more of the following options:
 *
 *
 *                <dl compact>
 *                <dt><b>F</b><dd>Sort filenames
 *                <dt><b>N</b><dd>Sort numbers
 *                <dt><b>I</b><dd>Case insensitive sort.  Sort is case sensitive if this option is not specified.
 *                <dt><b>D</b><dd>Descending.  Sort is ascending if this option is not specified.
 *                <dt><b>P</b><dd>Place parent nodes at the top after sort.  Here we consider a parent nodes with name PrimaryFolderElementName.
 *                <dt><b>2</b><dd>Specialized filename sort.  Sort case insensitive on name without path, then case sensitive on name without path, then case insensitive on path.
 *                </dl>
 * @param PrimaryFolderElementName
 *                Only used if <b>P</b> option specified in <i>PrimaryOptions</i>. Indicates the
 *                element of a folder.
 * @param SecondaryAttrName
 *                Secondary attribute name to sort on. Instead
 *                of an attribute name, this can be an XPath
 *                expression. This is very handy when the
 *                attribute you need to sort on is an element
 *                beneath the node being sorted. For example, 
 *                "attrs/@position" specifies "attrs" element is
 *                beneath the node being sorted has a position
 *                attribute.
 * @param SecondaryOptions
 *                Specifies secondary sort options.  See primary options for more information.
 *
 * @example // Sort the project files in the workspace
 * <pre>
 * int ProjectsNode=_WorkspaceGet_ProjectsNode(handle);
 * if (ProjectsNode>=0) {
 *    _xmlcfg_sort_on_attribute(handle,ProjectsNode,'File','2');
 * }
 *
 * // Sort a folder node and place sub folders at the top.
 * // Note that it is OK that <Folder> nodes have no "N"
 * // attribute but do have a "Name" attribute.
 * _xmlcfg_sort_on_attribute(handle,FolderNode,"N","2P",
 *    "Folder",
 *    "Name",
 *    "2P");
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
extern void _xmlcfg_sort_on_attribute(int iHandle,int ParentNodeIndex,
                               _str PrimaryAttrName,_str PrimaryOptions,
                               _str PrimaryFolderElementName=null,
                               _str SecondaryAttrName=null,_str SecondaryOptions=null);

/**
 * Fetches the XML document modify state.
 *
 * @param handle Handle to an XMLCFG tree returned by _xmlcfg_open(), _xmlcfg_create(), or _xmlcfg_open_from_buffer().
 *
 * @return Returns a non-zero value if the XML document has been modified.
 *
 * @see _xmlcfg_set_modify
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_get_modify(int handle);
/**
 * Sets XML document modify state.
 *
 * @param handle Handle to an XMLCFG tree returned by _xmlcfg_open(), _xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param modify New value for modify state
 *
 * @see _xmlcfg_get_modify
 *
 * @categories XMLCFG_Functions
 */
extern void _xmlcfg_set_modify(int handle,int modify);

/**
 * Saves an XMLCFG tree to a XML file.
 *
 * @param iHandle  Handle for tree to save
 * @param iIndentAmount
 *                 Amount to indent for each level.  -1 to use
 *                 tabs.
 *                 <p>Note: When iIndentAmount is 0, new-line
 *                 characters text in PCDATA nodes will not be
 *                 translated no matter what options you use.
 * @param iFlags   Formatting flags.   flags may be zero or more of the following flags:
 *
 *                 <DL>
 *                 <DT>VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR</DT>
 *                 <DD>Specifies that attributes for a given element be written on the same line if there is only one attribute.</DD>
 *                 <DT>VSXMLCFG_SAVE_DOS_EOL</DT>
 *                 <DD>Specifies that carriage return and line feed characters separate each line.  This is the default under Windows.</DD>
 *                 <DT>VSXMLCFG_SAVE_UNIX_EOL</DT>
 *                 <DD>Specifies that a line feed character separate each line.  This is the default under UNIX.</DD>
 *                 <DT>VSXMLCFG_SAVE_SPACE_AROUND_EQUAL</DT>
 *                 <DD>Specifies that spaces be added before and after the '=' for attributes and their values.</DD>
 *                 <DT>VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE</DT>
 *                 <DD>Specifies that the close brace be placed on a separate line.</DD>
 *                 <DT>VSXMLCFG_SAVE_PCDATA_INLINE</DT>
 *                 <DD>PCDATA will not be automatically indented on a new line.
 *                 Ideal for cases like: <Tag>Value</Tag> </DD>
 *                 <DT>VSXMLCFG_SAVE_PRESERVE_PCDATA</DT>
 *                 <DD>Specifies that all PCDATA should be saved
 *                 as is without modification. New-line
 *                 characaters will not be translated.</DD>
 *                 <DT>VSXMLCFG_SAVE_REINDENT_PCDATA_RELATIVE</DT>
 *                 <DD>For PCDATA nodes created after the file
 *                 is opened, add the current indent level to
 *                 the indent of pcdata text. This is has no
 *                 effect if the pcdata is on one line.</DD>
 *                 </DL>
 *  
 * @param Filename When given, specifies filename to write to.  Otherwise, the filename
 *                 used in the open or create call is used.
 * @param encoding When -1 this parameter defaults to the value specified in the
 * _xmlcfg_open() or _xmlcfg_create() call.  For Microsort .NET project
 * files, this parameter should be VSCP_ACTIVE_CODEPAGE. encoding may be
 * one of the following:
 *
 * <blockquote><PRE>
 * VSCP_ACTIVE_CODEPAGE
 * VSCP_EBCDIC
 * VSCP_CYRILLIC_KOI8_R
 * VSCP_ISO_8859_1
 * VSCP_ISO_8859_2
 * VSCP_ISO_8859_3
 * VSCP_ISO_8859_4
 * VSCP_ISO_8859_5
 * VSCP_ISO_8859_6
 * VSCP_ISO_8859_7
 * VSCP_ISO_8859_8
 * VSCP_ISO_8859_9
 * VSCP_ISO_8859_10
 * Any valid Windows code page
 * VSENCODING_UTF8
 * VSENCODING_UTF8_WITH_SIGNATURE
 * VSENCODING_UTF16LE
 * VSENCODING_UTF16LE_WITH_SIGNATURE
 * VSENCODING_UTF16BE
 * VSENCODING_UTF16BE_WITH_SIGNATURE
 * VSENCODING_UTF32LE
 * VSENCODING_UTF32LE_WITH_SIGNATURE
 * VSENCODING_UTF32BE
 * VSENCODING_UTF32BE_WITH_SIGNATURE
 * </PRE></blockquote>
 * @param NodeIndex   The children of this node are written.
 *
 * @return Returns 0 if successful.  Otherwise a negative return code defined in "rc.sh" is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_save(int iHandle,int iIndentAmount,int iFlags,_str Filename=null,int encoding=-1,int NodeIndex=TREE_ROOT_INDEX);
/**
 * Saves an XMLCFG tree to the buffer specified by wid.
 *
 * @param wid      Window which is viewing the output buffer.
 * @param iHandle  Handle for tree to save
 * @param iIndentAmount
 *                 Amount to indent for each level.  -1 to use tabs
 * @param iFlags   Formatting flags.   flags may be zero or more of the following flags:
 *
 *                 <DL>
 *                 <DT>VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR</DT>
 *                 <DD>Specifies that attributes for a given element be written on the same line if there is only one attribute.</DD>
 *                 <DT>VSXMLCFG_SAVE_DOS_EOL</DT>
 *                 <DD>Specifies that carriage return and line feed characters separate each line.  This is the default under Windows.</DD>
 *                 <DT>VSXMLCFG_SAVE_UNIX_EOL</DT>
 *                 <DD>Specifies that a line feed character separate each line.  This is the default under UNIX.</DD>
 *                 <DT>VSXMLCFG_SAVE_SPACE_AROUND_EQUAL</DT>
 *                 <DD>Specifies that spaces be added before and after the '=' for attributes and their values.</DD>
 *                 <DT>VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE</DT>
 *                 <DD>Specifies that the close brace be placed on a separate line.</DD>
 *                 <DT>VSXMLCFG_SAVE_PCDATA_INLINE</DT>
 *                 <DD>PCDATA will not be automatically indented on a new line.
 *                 Ideal for cases like: <Tag>Value</Tag> </DD>
 *                 <DT>VSXMLCFG_SAVE_PRESERVE_PCDATA</DT>
 *                 <DD>Specifies that all PCDATA should be saved
 *                 as is without modification. New-line
 *                 characaters will not be translated.</DD>
 *                 <DT>VSXMLCFG_SAVE_REINDENT_PCDATA_RELATIVE</DT>
 *                 <DD>For PCDATA nodes created after the file
 *                 is opened, add the current indent level to
 *                 the indent of pcdata text. This is has no
 *                 effect if the pcdata is on one line.</DD>
 *                 </DL>
 * @param NodeIndex   The children of this node are written.
 *
 * @return Returns 0 if successful.  Otherwise a negative return code defined in "rc.sh" is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_save_to_buffer(int wid,int iHandle,int iIndentAmount,int iFlags,int NodeIndex=TREE_ROOT_INDEX);


/**
 * Saves an XMLCFG tree to a string.
 *
 * @param wid      Window which is viewing the output buffer.
 * @param iHandle  Handle for tree to save
 * @param iIndentAmount
 *                 Amount to indent for each level.  -1 to use tabs
 * @param iFlags   Formatting flags.   flags may be zero or more of the following flags:
 *
 *                 <DL>
 *                 <DT>VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR</DT>
 *                 <DD>Specifies that attributes for a given element be written on the same line if there is only one attribute.</DD>
 *                 <DT>VSXMLCFG_SAVE_DOS_EOL</DT>
 *                 <DD>Specifies that carriage return and line feed characters separate each line.  This is the default under Windows.</DD>
 *                 <DT>VSXMLCFG_SAVE_UNIX_EOL</DT>
 *                 <DD>Specifies that a line feed character separate each line.  This is the default under UNIX.</DD>
 *                 <DT>VSXMLCFG_SAVE_SPACE_AROUND_EQUAL</DT>
 *                 <DD>Specifies that spaces be added before and after the '=' for attributes and their values.</DD>
 *                 <DT>VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE</DT>
 *                 <DD>Specifies that the close brace be placed on a separate line.</DD>
 *                 <DT>VSXMLCFG_SAVE_PCDATA_INLINE</DT>
 *                 <DD>PCDATA will not be automatically indented on a new line.
 *                 Ideal for cases like: <Tag>Value</Tag> </DD>
 *                 <DT>VSXMLCFG_SAVE_PRESERVE_PCDATA</DT>
 *                 <DD>Specifies that all PCDATA should be saved
 *                 as is without modification. New-line
 *                 characaters will not be translated.</DD>
 *                 <DT>VSXMLCFG_SAVE_REINDENT_PCDATA_RELATIVE</DT>
 *                 <DD>For PCDATA nodes created after the file
 *                 is opened, add the current indent level to
 *                 the indent of pcdata text. This is has no
 *                 effect if the pcdata is on one line.</DD>
 *                 </DL>
 * @param NodeIndex   The children of this node are written.
 *
 * @return Returns 0 if successful.  Otherwise a negative return code defined in "rc.sh" is returned.
 *
 * @categories XMLCFG_Functions
 */
extern void _xmlcfg_save_to_string(_str &result,int iHandle,int iIndentAmount,int iFlags,int NodeIndex=TREE_ROOT_INDEX);
/**
 * Gets the first child index from the specified index.
 * The root index is always 0, or TREE_ROOT_INDEX,
 * so to traverse the tree start there.
 *
 * @param iHandle   Handle of tree to get index from
 * @param NodeIndex Index of node to get child node index for
 * @param NodeTypeFlags Indicates node type of child to find.
 *                      1 or more VSXMLCFG_NODE_* flags.  See
 *                      {@link _xmlcfg_add}() for more information
 *                      on this parameter.
 *
 * @return If successful, returns index of first child.  Otherwise
 *         a negative error is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_get_first_child(int iHandle,int NodeIndex,int NodeTypeFlags=~VSXMLCFG_NODE_ATTRIBUTE);
/**
 * Gets the last child index from the specified index.
 *
 * @param iHandle   Handle of tree to get index from
 * @param NodeIndex Index of node to get child node index for
 * @param NodeTypeFlags Indicates node type of child to find.
 *                      1 or more VSXMLCFG_NODE_* flags.  See
 *                      {@link _xmlcfg_add}() for more information
 *                      on this parameter.
 *
 * @return If successful, returns index of last child.  Otherwise
 *         a negative error is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_get_last_child(int iHandle,int NodeIndex,int NodeTypeFlags=~VSXMLCFG_NODE_ATTRIBUTE);
/**
 * Gets the parent index from the specified index.
 *
 * @param iHandle   Handle of tree to get index from
 * @param NodeIndex Index of node to get parent node index for
 *
 * @return If successful, returns index of parent.  Otherwise
 *         a negative error is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_get_parent(int iHandle,int NodeIndex);
/**
 * Gets the previous sibling child index from the specified index.
 * The root index is always TREE_ROOT_INDEX,
 * so to traverse the tree start there.
 *
 * @categories XMLCFG_Functions
 * @param iHandle   Handle of tree to get index from
 * @param NodeIndex Index of node to get sibling node index for
 * @param NodeTypeFlags Indicates node type of child to find.
 *                      1 or more VSXMLCFG_NODE_* flags.  See
 *                      {@link _xmlcfg_add}() for more information
 *                      on this parameter.
 *
 * @return Returns the node index of the previous sibling of the node specified by NodeIndex.  -1 is returned if the node specified has no previous sibling.
 */
extern int _xmlcfg_get_prev_sibling(int iHandle,int NodeIndex,int NodeTypeFlags=VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
/**
 * Gets the next sibling child index from the specified index.
 * The root index is always TREE_ROOT_INDEX,
 * so to traverse the tree start there.
 *
 * @categories XMLCFG_Functions
 * @param iHandle   Handle of tree to get index from
 * @param NodeIndex Index of node to get sibling node index for
 * @param NodeTypeFlags Indicates node type of child to find.
 *                      1 or more VSXMLCFG_NODE_* flags.  See
 *                      {@link _xmlcfg_add}() for more information
 *                      on this parameter.
 *
 * @return Returns the node index of the next sibling of the node specified by NodeIndex.  -1 is returned if the node specified has no next sibling.
 */
extern int _xmlcfg_get_next_sibling(int iHandle,int NodeIndex,int NodeTypeFlags=VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
/**
 * Gets the next attribute node index.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by _xmlcfg_open() ,_xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param NodeIndex Tree node index.  Specify an element node to find the first
 *                  attribute (child of the element node).  In subsequent calls, specified
 *                  the previous value returned by this function to get the next attribute index.
 *
 * @return Returns the next attribute node index if successful.  Otherwise
 *         a negative error code is returned.
 * @example
 * <pre>
 * ProjectIndex=_xmlcfg_find_simple(handle,"/project");
 * for (AttrIndex=ProjectIndex;AttrIndex>0;) {
 *     AttrIndex=_xmlcfg_get_next_attribute(handle,AttrIndex);
 *     if (AttrIndex<0) break;
 *     say('Attribute name is '_xmlcfg_get_name(handle,AttrIndex));
 * }
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_get_next_attribute(int iHandle,int NodeIndex);
/**
 * Gets the node name
 *
 * @param iHandle   Handle to an XML tree
 * @param NodeIndex Index to set the name for
 *
 * @return Returns the name for the node specified.  The name returned is null for comment, attribute, CDATA, and PCDATA nodes.
 *
 * @categories XMLCFG_Functions
 */
extern _str _xmlcfg_get_name(int iHandle,int NodeIndex);
/**
 * Gets the node value
 *
 * @param iHandle   Handle to an XML tree
 * @param NodeIndex Index to set the name for
 *
 * @return Returns the value for the node specified.  The value returned is <b>null</b> except for comment, attribute, CDATA, and PCDATA nodes.
 *
 * @categories XMLCFG_Functions
 */
extern typeless _xmlcfg_get_value(int iHandle,int NodeIndex);

/**
 * Gets the text value of node and all child nodes.
 *
 * @param iHandle   Handle to an XML tree
 * @param NodeIndex Index to set the name for
 *
 * @return Returns the value for the node specified.  The value returned is <b>null</b> except for comment, attribute, CDATA, and PCDATA nodes.
 *
 * @categories XMLCFG_Functions
 */
extern typeless _xmlcfg_get_text(int iHandle,int NodeIndex);

/**
 * Gets info about a node
 *
 * @param iHandle   Handle for an XML tree
 * @param NodeIndex Index of element
 *
 * @return Returns the node type if successful (one of VSXMLCFG_NODE_* constants).  Otherwise
 *         a negative return code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_get_type(int iHandle,int NodeIndex);
/**
 * Gets the value of an attribute
 *
 * @param iHandle   Handle to an XML tree
 * @param NodeIndex Index to get attribute from
 * @param AttrName  Name of attribute to retrieve the value for
 * @param DefaultValue  Value to return if attribute does not exist or an error occurs.
 *
 * @return Returns value of attribute if successful.  Otherwise DefaultValue is returned.
 *
 * @categories XMLCFG_Functions
 */
extern typeless _xmlcfg_get_attribute(int iHandle,int NodeIndex,_str AttrName,_str DefaultValue='');
/**
 * Gets the value of an attribute
 *
 * @param iHandle  Handle to an XML tree
 * @param QueryStr This is a small subset of an XPath expression.  See {@link _xmlcfg_find_simple}() for information on this parameter.
 * @param AttrName Name of attribute to get value of.
 * @param DefaultValue
 *                 Value to return if attribute does not exist or an error occurs.
 *
 * @return Returns value of attribute if successful.  Otherwise DefaultValue is returned.
 * @example <PRE>
 * // Find the first file element node under /project with name equal to
 * // "main.c" and get the "options" attribute value.
 * options=_xmlcfg_get_path(handle,
 *     "/project/file[file-eq(@name,'main.c')]",
 *     "options");
 *
 * @categories XMLCFG_Functions
 */
extern _str _xmlcfg_get_path(int iHandle,_str QueryStr,_str AttrName,_str DefaultValue='');
/**
 * Sets the name for the node specified. The name should be
 * null for comment, attribute, CDATA, and PCDATA nodes.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by _xmlcfg_open() ,_xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param NodeIndex Tree node index.
 * @param name      New name for node.
 *
 * @return Returns 0 if successful.  Otherwise a negative return code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_set_name(int iHandle,int NodeIndex,_str name);
/**
 * Sets the value for the node specified. The value returned is null
 * except for comment, attribute, CDATA, and PCDATA nodes.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by _xmlcfg_open() ,_xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param NodeIndex Tree node index.
 * @param Value     New value for node.
 *
 * @return Returns 0 if successful.  Otherwise a negative return code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_set_value(int iHandle,int NodeIndex,_str Value);

/**
 * Sets or adds an attribute value for the element node specified.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by _xmlcfg_open() ,_xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param QueryStr  This is a small subset of an XPath expression.  See {@link _xmlcfg_find_simple}() for information on this parameter.
 * @param AttrName  Name of attribute.
 * @param AttrValue New value for attribute.
 * @param iFlags    -1 indicates that an error should be returned if the attribute does
 *                  not already exists.  Otherwise, the _xmlcfg_add_attribute() function
 *                  is called to add the attribute.
 *
 *                  <P>A combination of the following flags:
 *                  <DL>
 *                  <DT>VSXMLCFG_ADD_ATTR_AT_BEGINNING</DT>
 *                  <DD>Insert attribute at the beginning of the list of attributes
 *                  at this node.  By default, the attribute is added at the end.
 *                  </DD>
 *
 *                  </DL>
 *
 * @return Returns NodeIndex (>=0) for QueryStr (not attribute) if successful.  Otherwise a negative return code defined in
 *         "rc.sh" is returned.
 * @example <PRE>
 * // Find the first file element node under /project with name equal to
 * // "main.c" and set the "options" attribute value.
 * _xmlcfg_set_path(handle,
 *     "/project/file[file-eq(@name,'main.c')]",
 *     "options","-Zi");
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_set_path(int iHandle,_str QueryStr,_str AttrName=null,_str AttrValue=null,int iFlags=0);

/**
 * Gets the depth of a node.  Root node depth is 0
 *
 * @param iHandle Handle to an XML tree
 *
 * @param NodeIndex  Index to a node
 *
 * @return Depth of the node.  Root node depth is 0.
 *         Negative return value is an error.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_get_depth(int iHandle,int NodeIndex);
/**
 * Delete a node and its children from an XML tree.
 *
 * @param iHandle   Handle to an XML tree
 * @param NodeIndex Index to delete
 * @param OnlyDeleteChildren
 *                  When true, only the children of the node specified are
 *                  deleted.
 *
 * @return 0 if successful
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_delete(int iHandle,int NodeIndex,bool OnlyDeleteChildren=false);
/**
 * Adds a element to an XML tree
 *
 * @param iHandle   Handle to an XML tree
 * @param NodeIndex Index to a node
 * @param NameOrValue
 *                  Name or value of the element to be added.  If the NodeType specified
 *                  requires a name, this specifies the name.  Otherwise, this specifies
 *                  the value.
 * @param NodeType
 *                  One of the following:
 *                  <DL>
 *                  <DT>VSXMLCFG_NODE_ELEMENT_START</DT>
 *                  <DD>Name contains name of element.  Value is null.</DD>
 *                  <DT>VSXMLCFG_NODE_ELEMENT_START_END</DT>
 *                  <DD>Name contains name of element.  Value is null.</DD>
 *                  <DT>VSXMLCFG_NODE_XML_DECLARATION</DT>
 *                  <DD>Name is set to "xml".   Attributes are set.  For compatibility with XPath, the _xmlcfg_find_XXX functions won't find these attributes.</DD>
 *                  <DT>VSXMLCFG_NODE_PROCESSING_INSTRUCTION</DT>
 *                  <DD>Name is set to the processor name (not including '?').  Value is set to all data after the processor name not including leading white space.</DD>
 *                  <DT>VSXMLCFG_NODE_COMMENT</DT>
 *                  <DD>Name is set to null.  Value contains all data not including leading '!--' and trailing '--'.</DD>
 *                  <DT>VSXMLCFG_NODE_DOCTYPE</DT>
 *                  <DD>Name is set to "DOCTYPE".  For convience, the DOCTYPE information is stored as attributes so it can be more easily identified an modified.   A "root" attribute is set to the document root element specified.  A "PUBLIC" attribute is set to the public literal specified.  A "SYSTEM" attribute is set to the system literal.  A "DTD" attribute is set to the internal DTD subset. For compatibility with XPath, the _xmlcfg_find_XXX functions won't find these attributes.</DD>
 *                  <DT>VSXMLCFG_NODE_ATTIRIBUTE</DT>
 *                  <DD>Name is set to attribute name.  Value is set to value of attribute not including quotes.</DD>
 *                  <DT>VSXMLCFG_NODE_PCDATA></DT>
 *                  <DD>Name is set to null.  Value is set to the PCDATA text.</DD>
 *                  <DT>VSXMLCFG_NODE_CDATA</DT>
 *                  <DD>Name is set to null.  Value is set to the CDATA text.</DD>
 *                  </DL>
 * @param iFlags    Add flags.  By default, a new sibling is created after NodeIndex.
 *                  Use these flags
 *                  to change the behavior.
 *                  <ul>
 *                  <li>VSXMLCFG_ADD_AS_CHILD
 *                  <li>VSXMLCFG_ADD_AS_FIRST_CHILD
 *                  <li>VSXMLCFG_ADD_BEFORE
 *                  <li>VSXMLCFG_ADD_AS_CHILD
 *                  </ul>
 *
 * @return
 *         Returns index to new node if successful.  Otherwise a negative return
 *         code defined in "rc.sh" is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_add(int iHandle,int NodeIndex,_str NameOrValue,int NodeType,int iFlags);

/**
 * Adds either PCDATA or CDATA child node to XMLCFG tree
 * depending on the contents of the pText. Use the
 * _xmlcfg_get_text() function to get the text contents of the
 * node.
 *
 * @param iHandle   Handle to an XML tree
 * @param NodeIndex Index to a node
 * @param Text
 *                  Text for PCDATA or CData node
 *
 * @return
 *         Returns index to new node if successful.  Otherwise a negative return
 *         code defined in "rc.sh" is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_add_child_text(int iHandle,int NodeIndex,_str Text);

/**
 * Sets or adds an attribute value for the element node specified.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by _xmlcfg_open() ,_xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param NodeIndex Index to a node
 * @param AttrName  Name of attribute.
 * @param AttrValue New value for attribute.
 * @param iFlags    -1 indicates that an error should be returned if the attribute does
 *                  not already exists.  Otherwise, the _xmlcfg_add_attribute() function
 *                  is called to add the attribute.
 *
 *                  <P>A combination of the following flags:
 *                  <DL>
 *                  <DT>VSXMLCFG_ADD_ATTR_AT_BEGINNING</DT>
 *                  <DD>Insert attribute at the beginning of the list of attributes
 *                  at this node.  By default, the attribute is added at the end.
 *                  </DD>
 *
 *                  </DL>
 *
 * @return Returns 0 if successful.  Otherwise a negative return code defined in "rc.sh" is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_set_attribute(int iHandle,int NodeIndex,_str AttrName,_str AttrValue,int iFlags= 0);
/**
 * Sets or adds an attribute value for the element node specified.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by _xmlcfg_open() ,_xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param NodeIndex Index to a node
 * @param AttrName  Name of attribute.
 * @param AttrValue New value for attribute.
 * @param iFlags    A combination of the following flags:
 *                  <DL>
 *                  <DT>VSXMLCFG_ADD_ATTR_AT_BEGINNING</DT>
 *                  <DD>Insert attribute at the beginning of the list of attributes
 *                  at this node.  By default, the attribute is added at the end.
 *                  </DD>
 *
 *                  </DL>
 *
 * @return Returns node index of the new attribute if successful.  Otherwise
 *         a negative return code defined in "rc.sh" is returned.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_add_attribute(int iHandle,int NodeIndex,_str AttrName,_str AttrValue,int iFlags=0);
/**
 * Deletes an attribute
 *
 * @param iHandle Handle to an XML tree
 *
 * @param NodeIndex  Index to node to delete attribute from
 *
 * @param AttrName
 *                Name of attribute to delete
 *
 * @return Returns 0 if successful
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_delete_attribute(int iHandle,int NodeIndex,_str AttrName);
/**
 * Finds a child index under NodeIndex with the name
 * name
 *
 * @param iHandle   Handle to an XML tree
 * @param NodeIndex Index to a node to search under
 * @param name      Name of node to find.  This may be null.
 * @param NodeTypeFlags Indicates node type of child to find.
 *                      1 or more VSXMLCFG_NODE_* flags.  See
 *                      {@link _xmlcfg_add}() for more information
 *                      on this parameter.
 *
 * @return index >=0 if successful.
 *         Otherwise, a negative error code.
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_find_child_with_name(int iHandle,int NodeIndex,_str name,int NodeTypeFlags=VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
/**
 * Searches for nodes based on an subset XPath expression.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by _xmlcfg_open() ,_xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param QueryStr  This is a small subset of an XPath expression.  See {@link _xmlcfg_find_simple}() for information on this parameter.
 * @param Array     Set to node indexes or values found
 * @param NodeIndex Tree node index to start search from.
 * @param FindFlags Zero or more of the following flags:
 *                  <DL>
 *                  <DT>VSXMLCFG_FIND_APPEND</DT>
 *                  <DD>When specified, items are append to the end of Array.</DD>
 *                  <DT>VSXMLCFG_FIND_VALUES</DT>
 *                  <DD>When specified, values are returned instead of node indexes.</DD>
 *                  </DL>
 * @param maxAddCount  
 *
 * @return Returns 0 if successful.  Check the length (Array._length()) of the the array
 *         to see if any nodes were found.  Otherwise a negative error code is returned.
 * @example <PRE>
 * // Find all file element nodes under /project
 * _xmlcfg_find_simple_array(handle,"/project/file");
 *
 * // Find the "file" element nodes that are anywhere
 * // beneath the node specified.
 * _xmlcfg_find_simple_array(handle,"//file");
 * </PRE>
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_find_simple_array(int iHandle,_str QueryStr,_str (&Array)[],int NodeIndex=TREE_ROOT_INDEX,int FindFlags=0,int maxAddCount=-1);
/**
 * Searches for nodes based on an subset XPath expression and inserts the results into the current buffer.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by _xmlcfg_open() ,_xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param QueryStr  This is a small subset of an XPath expression.  See {@link _xmlcfg_find_simple}() for information on this parameter.
 * @param NodeIndex Tree node index to start search from.
 *
 * @return Returns 0 if successful. Otherwise a negative error code is returned.
 * @example <PRE>
 * // Find the value of all "name" attributes under
 * // "/project/file" element nodes.
 * _xmlcfg_find_simple_array(handle,"/project/file/@name");
 * </PRE>
 *
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_find_simple_insert(int iHandle,_str QueryStr,int NodeIndex=TREE_ROOT_INDEX);
/**
 * Searches for the first occurrence of a node.
 * 
 * @categories XMLCFG_Functions
 * @param iHandle   Handle to an XMLCFG tree returned by _xmlcfg_open() ,_xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param QueryStr  XPath 1.0 with the following
 *                  limitations:
 *                  
 *                  <ul>
 *                  <li>A subset of operators are supported. See
 *                  below.
 *                  <li>A small subset of XPath functions have
 *                  been implemented. See below.
 *                  <li>Duplicates are not removed for node
 *                  lists. This is stricly for performance.
 *                  Caller can do this as a separate step but
 *                  typically it's not necessary.
 *                  <li>Entity references are not supported. Predefined entities like "&amp;amp;", "&amp;lt;",
 *                  "&amp;gt;", etc. are supported.
 *                  <li>Floating point and Decimal types are not
 *                  yet supported. For simplicity, only bool,
 *                  string, node lists, and 64 bit integers have
 *                  been implemented. Floating point may be added
 *                  in the future.
 *                  <li>(XPath 2.0) Comma delimited sequences
 *                  are not yet supported. This would likely
 *                  effect performance too much given our speed
 *                  needs.
 *                  <li>(XPath 2.0) Namespaces are not supported
 *                  (and not likely to be supported)
 *                  </ul>
 *  
 *                  <p><b>Supported XPath Functions</b>
 *                  <dl>
 *                  <DT><code>number last()</code></DT>
 *                  <DT><code>number position()</code></DT>
 *                  <DT><code>boolean contains(string haystack,string
 *                  needle[,string flags=''])</code></DT>
 *                  <DD> The "flags" argument is a
 *                  SlickEdit extension.
 *                  The third argument to contains() is optional and is a string of zero or more of the following option letters:
 *                  <dl compact style="margin-left:20pt">
 *                  <DT>I</dt><dd>Specifies case insensitive search.</dd>
 *                  <DT>E</DT><dd>(default) Specifies case sensitive search.</dd>
 *                  <DT>R</DT><DD>Interpret string as a SlickEdit regular expression. See section <a href="help:SlickEdit regular expressions">SlickEdit Regular Expressions</a>.</DD>
 *                  <DT>L</DT><DD>Interpret string as a Perl regular expression. See section <a href="help:Perl regular expressions">Perl Regular Expressions</a>.</DD>
 *                  <DT>U</DT><DD>Interpret string as a Perl regular expression. See section <a href="help:Perl regular expressions">Perl Regular Expressions</a>. Support for Unix syntax regular expressions has been dropped.</DD>
 *                  <DT>B</DT><DD>Interpret string as a Perl regular expression. See section <a href="help:Perl regular expressions">Perl Regular Expressions</a>. Support for Brief syntax regular expressions has been dropped.</DD>
 *                  </dl>
 *                  </dd>
 *                  <DT><code>boolean not(boolean b)</code></DT>
 *                  <DT><code>boolean file-eq(string fileA,string fileB)</code></DT>
 *                  <DD>This function is a SlickEdit
 *                  extension. Returns true if files match in the case sensitivity of the OS.
 *                  Otherwise, false is returned.</dd>
 *                  <DT><code>boolean strieq(string s1,string s2)</code></DT>
 *                  <DD>This function is a SlickEdit
 *                  extension. Returns true if strings are a case insensitive match. Otherwise,
 *                  false is returned.</dd>
 *                  <DT><code>string name()</code></DT>
 *                  <DD>This function is a SlickEdit
 *                  extension. Returns element
 *                  name.
 *                  <p>Handy for something like the following:
 *                  <pre><code>
 *                  /path/ *[name()='short_description' or name()='long_description']
 *                  </code></pre>
 *                  </dd>
 *                  </dl>
 *                  
 *                  <p><b>Supported Operators in order of highest to lowest precedence</b>
 *                  <DL compact  style="margin-left:60pt">
 *                  <dt><code>[]</code></dt><dd>predicate</dd>
 *                  <dt><code>+, -</code></dt><dd>plus, minus</dd>
 *                  <dt><code>=, !=, &lt;, &lt;=, &gt;,
 *                  &gt;=,</code></dt><dd>comparisons</dd>
 *                  <dt><code>eq, ne, lt, le, gt, ge</code></dt><dd>comparisons</dd>
 *                  <dt><code>and</code></dt><dd>Logical and</dd>
 *                  <dt><code>or</code></dt><dd>Logical or</dd>
 *                  </DL>
 *                  <p><B>Some sample XPath expressions</B>:
 *                  <DL>
 *                  <DT><code>file</code></DT>
 *                  <DD>Find "file" element nodes that are children of the node specified.</DD>
 *                  <DT><code>@name</code></DT>
 *                  <DD>Find attribute nodes with name "name" that are children of  the node specified.</DD>
 *                  <DT><code>//file</code></DT>
 *                  <DD>Find "file" element nodes that are anywhere beneath the node specified.  For example, if the node specified is TREE_ROOT_INDEX ("/"), this matches "/project/file" and "/file".</DD>
 *                  <DT><code>/project/file</code></DT>
 *                  <DD>Find "file" element nodes under the "project" element nodes which are under the root.  If NodeIndex is not the root or the tree, searching starts at the root.</DD>
 *                  <DT><code>/project//file</code></DT>
 *                  <DD>Find "file" element nodes anywhere (no just a child) under the "project" element nodes which are under the root.  If NodeIndex is not the root or the tree, searching starts at the root.</DD>
 *                  
 *                  <DT><code>/project/file[@name='main.c']</code></DT>
 *                  <DD>Find "file" element nodes with a "name" attribute value of "main.c" under "project" element nodes which are under the root.  The expression between the square braces is called the predicate expression.  It tests for a codition starting from the context node but does not change the context node.</DD>
 *                  
 *                  <DT><code>/project/file[@name='main.c'][@option="debug"]</code></DT>
 *                  <dd>Find "file" element nodes with a "name" attribute value of "main.c" and option attribute value of "debug" under "project" element nodes which are under the root.  This is a form of and expression.  There is currently no way to perform an "OR" operation.</dd>
 *                  <DT><code>/project/file/@name[file-eq(.,'main.c')]</code></DT>
 *                  <DD>Find "name" attribute nodes of "file" element nodes with a "name" attribute value of "main.c" under "project" element nodes which are under the root.  The file-eq() function (the only supported function) performs a case insensitive compare under file systems which are case insensitive.  The first argument to the file-eq() function is a period.  This specifies the value of the current node.  Note that specifying "@name" as the first argument to the file-eq() function would not work because the context node is already on the "name" attribute node and there are no attributes below attribute nodes.</DD>
 *                  <DT><code>//file[contains(@config,'"WinDebug"','I')]/@name</code></DT>
 *                  <DD>Find "name" attribute nodes of "file" element nodes with a "config" attribute which contains "WinDebug" in any case.  The third argument to contains() is optional and is a string of zero or more of the following option letters:
 *                  <dl compact style="margin-left:20pt">
 *                  <DT>I</dt>   <dd>Specifies case insensitive search.</dd>
 *                  <DT>E</DT>   <dd>(default) Specifies case sensitive search.</dd>
 *                  <DT>R</DT><DD>Interpret string as a SlickEdit regular expression. See section <a href="help:SlickEdit regular expressions">SlickEdit Regular Expressions</a>.</DD>
 *                  <DT>L</DT><DD>Interpret string as a Perl regular expression. See section <a href="help:Perl regular expressions">Perl Regular Expressions</a>.</DD>
 *                  <DT>U</DT><DD>Interpret string as a Perl regular expression. See section <a href="help:Perl regular expressions">Perl Regular Expressions</a>. Support for Unix syntax regular expressions has been dropped.</DD>
 *                  <DT>B</DT><DD>Interpret string as a Perl regular expression. See section <a href="help:Perl regular expressions">Perl Regular Expressions</a>. Support for Brief syntax regular expressions has been dropped.</DD>
 *                  </dl>
 *                  <DT><code>//@config[contains(.,"'WinDebug'",'I')]</code></DT>
 *                  <DD>Find "config" attribute nodes with values that contain "WinDebug" of any case.</DD>
 *                  <DT><code>//file[not(@config)]/@name</code></DT>
 *                  <DD>Find "name" attribute nodes of "file" element nodes which do not have a config attribute.</DD>
 *                  </DL>
 *                  
 * @param NodeIndex Tree node index to start search from.
 * 
 * @return Returns node index (&gt;=0) found if successful. 
 *         Otherwise a negative error code is returned.
 * @example <PRE>
 * // Find the first file element node under /project with name equal to
 * // "main.c"
 * FileIndex=_xmlcfg_find_simple(handle,
 *     "/project/file[file-eq(@name,'main.c')]");
 * 
 * // Find the attribute node under /project/file with name equal
 * // to "main.c"
 * AttrIndex=_xmlcfg_find_simple(handle,
 *     "/project/file/@name[file-eq(.,'main.c')]");
 * </PRE>
 */
extern int _xmlcfg_find_simple(int iHandle,_str QueryStr,int NodeIndex=TREE_ROOT_INDEX);

extern void _xmlcfg_get_seekpos_from_node(int iHandle,long iIndex,int &hrefStatus, long &hrefSeek);
extern int _xmlcfg_get_node_from_seekpos(int iHandle,long lSeekPos);

/**
 * Determines if the given index points to a valid node in the XML tree.
 * 
 * @param iHandle       handle of xml tree
 * @param iIndex        index to check
 * 
 * @return              true if the index points to a valid node, false 
 *                      otherwise.
 *  
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_is_node_valid(int iHandle, long iIndex);

/**
 * Determines if the given handle points to a valid xml tree.
 * 
 * @param iHandle       handle of xml tree
 * 
 * @return int          true if the handle is a valid tree, false otherwise
 *  
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_is_handle_valid(int iHandle);

/**
 * Gets the node value, removing any leading indent from 
 * beautification 
 *
 * @param handle   Handle to an XML tree
 * @param node     Index to profile element node.
 *
 * @return Returns the value for the node specified.  The value returned is <b>null</b> except for comment, attribute, CDATA, and PCDATA nodes.
 *
 * @categories XMLCFG_Functions
 */
extern _str _xmlcfg_get_value_unindent(int handle,int node);
/**
 * Finds property value
 * 
 * @param handle   Handle to an XML tree
 * @param node     Index to profile element node.
 * @param name     Name of property.
 * @param defaultValue  Return value if property isn't found.
 * @param apply    Set to value of apply attribute.
 * 
 * @return Returns the value for the node specified.  If
 *         property isn't found, defaultValue is returned.
 *  
 * @categories XMLCFG_Functions
 */
extern _str _xmlcfg_get_property(int handle,int node,_str name, _str defaultValue="", bool &apply=null);
/**
 * Sets or addes property
 * 
 * @param handle   Handle to an XML tree
 * @param node     Index to profile element node.
 * @param name     Name of property.
 * @param value    New value for proeprty.
 * @param apply    Optional value for apply attribute. If null, 
 *                 apply attribute is not set or removed.
 * 
 * @categories XMLCFG_Functions
 */
extern void _xmlcfg_set_property(int handle,int node,_str name,_str value,bool apply=null);
/**
 * Finds property value
 * 
 * @param handle   Handle to an XML tree
 * @param node     Index to profile element node.
 * @param name     Name of property.
 * 
 * @return Returns node index of property node. If the property 
 *         isn't found, a negative number is returned.
 *  
 * @categories XMLCFG_Functions
 */
extern int _xmlcfg_find_property(int handle,int node,_str name);
/**
 * List property nodes matching some string matching
 * criteria
 * 
 * @param array  Set to array of nodes that match.
 * @param handle Handle to an XML tree
 * @param node   Handle to XML node.
 * @param matchNamePrefix
 *               Property name prefix to
 *               match. Specify "" to match all
 *               property names.
 * @param matchNameSearchOptions
 *               When !=null, this specifies search() style
 *               search options and a contains match (not prefix
 *               match) is performed. Typically used to match a
 *               regular expressions. (Ex.
 *               matchNameSearchOptions="L" where
 *               matchNamePrefix="^[^;]+;something$")
 * @param matchValue
 *               Value to match. Specify null to
 *               match all values.
 * @param matchValueSearchOptions
 *               When !=null, this specifies search() style
 *               search options and a contains match (not match
 *               of entire value) is performed. Typically used
 *               to match a regular expressions. (Ex.
 *               matchValuwSearchOptions="L" where
 *               matchValue="^[^;]+;something$")
 *               
 * @categories XMLCFG_Functions
 */
extern void _xmlcfg_list_properties(int (&array)[],int handle,int node,  _str matchNamePrefix='',_str matchNameSearchOptions=null,_str matchValue=null,_str matchValueSearchOptions=null);

