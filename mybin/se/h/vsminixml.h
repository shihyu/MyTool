#ifndef __VSMINIXML_H_INCL__
#define __VSMINIXML_H_INCL__

#include "vsutf8.h"
#include "slickedit/SEArray.h"
#include "slickedit/SEString.h"

#ifndef VSNULLSEEK
#define VSNULLSEEK      0x7fffffffl
#endif

#define VSXMLCFG_ROOT_INDEX 0

#define VSXMLCFG_NODE_ELEMENT_START          0x1
#define VSXMLCFG_NODE_ELEMENT_START_END      0x2
#define VSXMLCFG_NODE_XML_DECLARATION        0x4
#define VSXMLCFG_NODE_PROCESSING_INSTRUCTION 0x8
#define VSXMLCFG_NODE_COMMENT                0x10
#define VSXMLCFG_NODE_DOCTYPE                0x20
#define VSXMLCFG_NODE_ATTRIBUTE              0x40
#define VSXMLCFG_NODE_PCDATA                 0x80
#define VSXMLCFG_NODE_CDATA                  0x100
#define VSXMLCFG_COPY_CHILDREN               0x200
#define VSXMLCFG_COPY_BEFORE                 VSXMLCFG_ADD_BEFORE
#define VSXMLCFG_COPY_AS_CHILD               VSXMLCFG_ADD_AS_CHILD
//#define VSXMLCFG_NODE_TEXT                    (VSXMLCFG_NODE_PCDATA|VSXMLCFG_NODE_CDATA)


EXTERN_C_BEGIN
/**
 * Decrements the open count and frees XMLCFG tree when the count reaches zero.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 *
 * @return Returns 0 if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
int vsXMLCFGClose(int iHandle);

#define VSXMLCFG_OPEN_ADD_PCDATA  VSXMLCFG_OPEN_ADD_ALL_PCDATA

#define VSXMLCFG_OPEN_ADD_ALL_PCDATA            0x01
#define VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR      0x02
#define VSXMLCFG_OPEN_REFCOUNT                  0x04
#define VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA  0x08
#define VSXMLCFG_OPEN_NO_TRANSLATION            0x10
#define VSXMLCFG_OPEN_REFCOPY                   0x20

/**
 * Opens an XML file and loads it into a tree.
 * returns a handle to the tree
 *
 * @param pszFilename  Name of the XML file to open
 * @param status    Set to 0 if succesful. Otherwise this is set to
 *                  negative error code.
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
 *                  <DT>VSXMLCFG_OPEN_REFCOUNT</dt><DD>
 *                  When specified, a search is preformed in the XMLCFG open file cache
 *                  for a filename which already has the name given to open.  If it is
 *                  found, the reference count is incremented and the same XMLCFG
 *                  handle is returned.  vsXMLCFGClose always decrements the reference
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
int VSAPI vsXMLCFGOpen(const char *pszFilename,int &status,int OpenFlags VSDEFAULT(0),int iEncoding VSDEFAULT(VSENCODING_AUTOXML));
/**
 * Opens and parses an XML file into a tree.  The XMLCFG function are intended to be used on valid XML files for reading and writing various configuration information.  The XMLCFG functions are not for validating or checking for well formedness.
 *
 * @param wid       Window id of editor control.
 * @param status    (Output only) Set to 0 if successful.  Otherwise a negative error code.
 * @param flags     zero or more of the following flags:
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
 * @param StartRealSeekPos
 *                  Start real seek position to start reading XML text.
 * @param EndRealSeekPos
 *                  End real seek position of XML text.
 * @param preserved
 *
 * @return Returns XMLCFG tree handle if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGOpenFromBuffer(int wid,int &status,int flags VSDEFAULT(0),int StartRealSeekPos VSDEFAULT(0),int EndRealSeekPos VSDEFAULT(VSNULLSEEK),void *preserved VSDEFAULT(0));
/**
 * Opens and parses an XML file into a tree.  The XMLCFG function are intended to be used on valid XML files for reading and writing various configuration information.  The XMLCFG functions are not for validating or checking for well formedness.
 * 
 * @categories XMLCFG_Functions
 * @param pBuffer
 * @param BufLen
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
 *                  <DT>VSXMLCFG_OPEN_REFCOUNT</dt><DD>
 *                  When specified, a search is preformed in the XMLCFG open file cache
 *                  for a filename which already has the name given to open.  If it is
 *                  found, the reference count is incremented and the same XMLCFG
 *                  handle is returned.  vsXMLCFGClose always decrements the reference
 *                  count and closes the file when the reference count is 0.
 *                  
 *                  </DD>
 *                  </dl>
 * @param iEncoding For standard XML files, this parameter should be VSENCODING_AUTOXML.  For Microsort .NET project files, this parameter should be VSCP_ACTIVE_CODEPAGE.
 * @param preserved
 * 
 * @return Returns XMLCFG tree handle if successful.  Otherwise a negative error code is returned.
 */
int VSAPI vsXMLCFGOpenFromString(const char *pBuffer,int BufLen,int &status,int OpenFlags=0,int iEncoding=VSENCODING_AUTOXML,void *preserved=0);

#define VSXMLCFG_SAVE_ALL_ON_ONE_LINE              0x1
#define VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR         0x2
#define VSXMLCFG_SAVE_DOS_EOL                      0x4
#define VSXMLCFG_SAVE_UNIX_EOL                     0x8
#define VSXMLCFG_SAVE_SPACE_AROUND_EQUAL           0x10
#define VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE 0x20
// PCDATA will not be automatically indented on a new line.
// Ideal for cases like: <Tag>Value</Tag>
#define VSXMLCFG_SAVE_PCDATA_INLINE                0x40
// Add a trailing space after the last attribute quote, but only
// on nodes that are solely attributed. 
// Example: <MyTag Name="Tag2" Value="Whatever" />
// This is a special case for Visual Studio XML project formats
// It includes the VSXMLCFG_SAVE_ALL_ON_ONE_LINE flag
#define VSXMLCFG_SAVE_SPACE_AFTER_LAST_ATTRIBUTE   (0x80 | VSXMLCFG_SAVE_ALL_ON_ONE_LINE)

#define VSXMLCFG_SAVE_ESCAPE_NL_ON_ATTR_VALUE      0x100
#define VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE            0x200
#define VSXMLCFG_SAVE_PRESERVE_PCDATA_INDENT       0x400

typedef void (VSAPI * PFNXMLCFGCFG_SAVE_CALLBACK)(int iHandle,int iIndex,int NodeTypeFlags,int *piIndentAmount,int *piFlags);

/**
 * Saves an XMLCFG tree to a XML file.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndentAmount
 *                  Amount to indent for each level.  -1 to use tabs
 * @param iFlags    Formatting flags.   flags may be zero or more of the following flags:
 *
 *                  <DL>
 *                  <DT>VSXMLCFG_SAVE_ALL_ON_ONE_LINE</DT>
 *                  <DD>Specifies that all attributes for a given element be written on the same line.</DD>
 *                  <DT>VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR</DT>
 *                  <DD>Specifies that attributes for a given element be written on the same line if there is only one attribute.</DD>
 *                  <DT>VSXMLCFG_SAVE_DOS_EOL</DT>
 *                  <DD>Specifies that carriage return and line feed characters separate each line.  This is the default under Windows.</DD>
 *                  <DT>VSXMLCFG_SAVE_UNIX_EOL</DT>
 *                  <DD>Specifies that a line feed character separate each line.  This is the default under UNIX.</DD>
 *                  <DT>VSXMLCFG_SAVE_SPACE_AROUND_EQUAL</DT>
 *                  <DD>Specifies that spaces be added before and after the '=' for attributes and their values.</DD>
 *                  <DT>VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE</DT>
 *                  <DD>Specifies that the close brace be placed on a separate line.</DD>
 *                  </DL>
 * @param pszAlternateFilename
 *                  When given, specifies filename to write to.  Otherwise, the filename
 *                  used in the open or create call is used.
 * @param encoding  When -1 this parameter defaults to the value specified in the
 *                  vsXMLCFGOpen() or vsXMLCFGCreate() call.  For Microsort .NET project files,
 *                  this parameter should be VSCP_ACTIVE_CODEPAGE. encoding may be one of the
 *                  following:
 *
 *                  <blockquote></pre>
 *                  VSENCODING_UTF8
 *                  VSENCODING_UTF8_WITH_SIGNATURE
 *                  VSENCODING_UTF16LE
 *                  VSENCODING_UTF16LE_WITH_SIGNATURE
 *                  VSENCODING_UTF16BE
 *                  VSENCODING_UTF16BE_WITH_SIGNATURE
 *                  VSENCODING_UTF32LE
 *                  VSENCODING_UTF32LE_WITH_SIGNATURE
 *                  VSENCODING_UTF32BE
 *                  VSENCODING_UTF32BE_WITH_SIGNATURE
 *                  </PRE></blockquote>
 * @param NodeIndex The children of this node are written.
 * @param pfnCallback   Allows the indent to be customized for the contenst of a specific node.
 *
 * @return Returns 0 if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGSave(int iHandle,int iIndentAmount,int iFlags,const char *pszAlternateFilename VSDEFAULT(0),
                       int encoding VSDEFAULT(-1),int NodeIndex VSDEFAULT(0), PFNXMLCFGCFG_SAVE_CALLBACK pfnCallback VSDEFAULT(0));
/**
 * Saves an XMLCFG tree to a buffer.
 *
 * @param wid       Window id of editor control.  0 specifies the current object.
 * @param iHandle   Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndentAmount
 *                  Amount to indent for each level.  -1 to use tabs
 * @param iFlags    Formatting flags.   flags may be zero or more of the following flags:
 *
 *                  <DL>
 *                  <DT>VSXMLCFG_SAVE_ALL_ON_ONE_LINE</DT>
 *                  <DD>Specifies that all attributes for a given element be written on the same line.</DD>
 *                  <DT>VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR</DT>
 *                  <DD>Specifies that attributes for a given element be written on the same line if there is only one attribute.</DD>
 *                  <DT>VSXMLCFG_SAVE_DOS_EOL</DT>
 *                  <DD>Specifies that carriage return and line feed characters separate each line.  This is the default under Windows.</DD>
 *                  <DT>VSXMLCFG_SAVE_UNIX_EOL</DT>
 *                  <DD>Specifies that a line feed character separate each line.  This is the default under UNIX.</DD>
 *                  <DT>VSXMLCFG_SAVE_SPACE_AROUND_EQUAL</DT>
 *                  <DD>Specifies that spaces be added before and after the '=' for attributes and their values.</DD>
 *                  <DT>VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE</DT>
 *                  <DD>Specifies that the close brace be placed on a separate line.</DD>
 *                  </DL>
 * @param NodeIndex The children of this node are written.
 * @param pfnCallback
 *                  Allows the indent to be customized for the contenst of a specific node.
 *
 * @return Returns 0 if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGSaveToBuffer(int wid,int iHandle,int iIndentAmount,int iFlags,int NodeIndex VSDEFAULT(0), PFNXMLCFGCFG_SAVE_CALLBACK pfnCallback VSDEFAULT(0));

/**
 * Gets the first child index from the specified index.
 * The root index is always 0, or TREE_ROOT_INDEX,
 * so to traverse the tree start there.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndex  Tree node index.
 * @param NodeTypeFlags Indicates node type of child to find.
 *                      1 or more VSXMLCFG_NODE_* flags.  See
 *                      {@link _xmlcfg_add}() for more
 *                      information on this parameter.
 *
 * @return Returns the node index of the first child of the specified node type for the node given.  -1 is returned if the node specified has no children.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGGetFirstChild(int iHandle,int iIndex,int NodeTypeFlags VSDEFAULT(~VSXMLCFG_NODE_ATTRIBUTE));
/**
 * Gets the parent index from the specified index.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex  Tree node index.
 * @param NodeTypeFlags
 *                Indicates node type of child to find.
 *                1 or more VSXMLCFG_NODE_* flags.  See
 *                {@link _xmlcfg_add}() for more information on
 *                this parameter.
 *
 * @return Returns the node index of the last child of the specified node type for the node given.  -1 is returned if the node specified has no children.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGGetLastChild(int iHandle,int NodeIndex,int NodeTypeFlags VSDEFAULT(~VSXMLCFG_NODE_ATTRIBUTE));
/** 
 * @return 
 * Return the number of nodes under the specified index.
 * 
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex  Tree node index.
 * @param NodeTypeFlags
 *                Indicates node type of child to find.
 *                1 or more VSXMLCFG_NODE_* flags.  See
 *                {@link _xmlcfg_add}() for more information on
 *                this parameter.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGGetNumChildren(int iHandle, int NodeIndex,int NodeTypeFlags VSDEFAULT(~VSXMLCFG_NODE_ATTRIBUTE));
/**
 * Gets the parent index from the specified index.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex
 *
 * @return If successful, returns index of parent.  Otherwise
 *         a negative error is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGGetParent(int iHandle,int NodeIndex);
/**
 * Gets the next attribute node index.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex Tree node index.  Specify an element node to find the first
 *                  attribute (child of the element node).  In subsequent calls, specified
 *                  the previous value returned by this function to get the next attribute index.
 *
 * @return Returns the next attribute node index if successful.  Otherwise
 *         a negative error code is returned.
 * @example <pre>
 * ProjectIndex=vsXNKCFGFindSimple(handle,"/project");
 * for (AttrIndex=ProjectIndex;AttrIndex>0;) {
 *     AttrIndex=vsXMLCFGGetNextAttribute(handle,AttrIndex);
 *     if (AttrIndex<0) break;
 *     xprintf("Attribute name is %s",vsXMLCFGGetNextAttribute(handle,AttrIndex));
 * }
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGGetNextAttribute(int iHandle,int NodeIndex);
/**
 * Gets the node name 
 * <p> 
 * This function returns data from a static global, so it is not thread safe. 
 *
 * @param iHandle    Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                   vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex  Index of element
 * @param pNameLen   (optional) pointer to int to set name length to
 *
 * @return Returns the name for the node specified. 
 *         The name returned is null for comment, attribute, CDATA, and PCDATA nodes.
 *  
 * @deprecated Use vsXMLCFGGetNameString() instead whereever possible. 
 *  
 * @categories XMLCFG_Functions
 */
const char *VSAPI vsXMLCFGGetName(int iHandle,int NodeIndex,int *pNameLen VSDEFAULT(0));
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
int VSAPI vsXMLCFGGetType(int iHandle,int NodeIndex);
/**
 * Retrieves attribute value for the attribute name given.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndex    Tree node index.
 * @param pszRequestedAttr
 *                  Name of attribute to retrieve value for.
 * @param pValueLen Number of bytes in returned value.
 * @param pszDefaultValue
 *                  Value to return if attributre does not exist on an error occurs.
 *
 * @return Returns attribute value if successful.  Otherwise pszDevaultValue is returned.
 *  
 * @deprecated Use vsXMLCFGGetAttributeString instead whereever possible. 
 *  
 * @categories XMLCFG_Functions
 */
const char * VSAPI vsXMLCFGGetAttribute(int iHandle,int iIndex,
                                  VSPSZ pszRequestedAttr,
                                  int *pValueLen VSDEFAULT(0),
                                  VSPSZ pszDefaultValue VSDEFAULT(""));

/**
 * Gets the node value
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex Index of element
 * @param pValueLen If specified, set to length in bytes of the value
 *
 * @return Returns the node type if successful (one of VSXMLCFG_NODE_* constants).  Otherwise
 *         a negative return code is returned.
 *
 * @deprecated Use vsXMLCFGGetValueString instead whereever possible. 
 *  
 * @categories XMLCFG_Functions
 */
const char * VSAPI vsXMLCFGGetValue(int iHandle,int NodeIndex,int *pValueLen VSDEFAULT(0));
/**
 * Gets the value of an attribute
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param pszQueryStr
 *                  This is a small subset of an XPath
 *                  expression.  See
 *                  {@link_xmlcfg_find_simple}()
 *                  for information on this parameter.
 * @param pszAttrName
 *                Name of attribute to get value of.
 * @param pAttrValueLen
 *                Number of bytes in returned attribute value.
 * @param pszDefaultValue
 *                Value to return if attribute does not exist or an error occurs.
 *
 * @return attribute value if successful.  Otherwise pszDefaultValue is returned.
 * @example <pre>
 * // Find the first file element node under /project with name equal to
 * // "main.c" and get the "options" attribute value.
 * char *pszOptions=vsXMLCFGGetPath(handle,
 *     "/project/file[file-eq(@name,'main.c')]",
 *     "options"
 *     );
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
const char * VSAPI vsXMLCFGGetPath(int iHandle,VSPSZ pszQueryStr,VSPSZ pszAttrName,int *pAttrValueLen VSDEFAULT(0),VSPSZ pszDefaultValue VSDEFAULT(""));
/**
 * Sets the name for the node specified. The name should be
 * null for comment, attribute, CDATA, and PCDATA nodes.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex Tree node index.
 * @param pszName
 *
 * @return Returns 0 if successful.  Otherwise a negative return code is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGSetName(int iHandle,int NodeIndex,const char * pszName);
/**
 * Sets the value for the node specified. The value returned is null
 * except for comment, attribute, CDATA, and PCDATA nodes.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex Tree node index.
 * @param pValue    New value for node.
 * @param ValueLen  Number of bytes in pValue.  -1 may be specified if pValue is a null terminated string.
 *
 * @return Returns 0 if successful.  Otherwise a negative return code is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGSetValue(int iHandle,int NodeIndex,const char *pValue,int ValueLen VSDEFAULT(-1));
/**
 * Sets or adds an attribute value for the element node specified.
 *
 * @param iHandle    Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param pszQueryStr
 *                   This is a small subset of an XPath
 *                   expression.  See {@link _xmlcfg_find_simple}() for
 *                   information on this parameter.
 * @param pszAttrName
 *                   Name of attribute.
 * @param pAttrValue New value for attribute
 * @param AttrValueLen
 *                   Number of bytes in pAttrValue.  -1 may be specified in pAttrValue is a null terminated string.
 * @param iFlags     -1 indicates that an error should be returned if the attribute does
 *                   not already exists.  Otherwise, the vsXMLCFGAddAttribute() function
 *                   is called to add the attribute.
 *
 *                   <P>A combination of the following flags:
 *                   <DL>
 *                   <DT>VSXMLCFG_ADD_ATTR_AT_BEGINNING</DT>
 *                   <DD>Insert attribute at the beginning of the list of attributes
 *                   at this node.  By default, the attribute is added at the end.
 *                   </DD>
 *
 *                   </DL>
 * @param reserved
 *
 * @return Returns 0 if successful.  Otherwise a negative error code is returned.
 * @example <pre>
 * // Find the first file element node under /project with name equal to
 * // "main.c" and set the "options" attribute value.
 * vsXMLCFGSetPath(handle,
 *     "/project/file[file-eq(@name,'main.c')]",
 *     "options",
 *     "-Zi"
 *     );
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGSetPath(int iHandle,const char *pszQueryStr,const char *pszAttrName VSDEFAULT(0),const char *pAttrValue VSDEFAULT(0),int AttrValueLen VSDEFAULT(-1),int iFlags VSDEFAULT(0), int reserved VSDEFAULT(0));
/**
 * Gets the depth of a node.  Root node depth is 0.
 *
 * @param NodeIndex Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndex  Tree node index.
 *
 * @return Returns the depth of the specified tree item.  The depth of the root tree item (NodeIndex=0) is 0.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGGetDepth(int iHandle,int NodeIndex);
/**
 * Returns the number of nodes in an XML tree
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 *
 * @return Number of nodes in the tree.
 *         Negative return value is an error.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGGetNumNodes(int iHandle);
/**
 * Delete a node and its children from an XML tree.
 *
 * @param iHandle   Handle to an XML tree
 * @param NodeIndex Index to delete
 * @param OnlyDeleteChildren
 *                  When true, only the children of the node specified are
 *                  deleted.
 *
 * @return Returns 0 if successful
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGDelete(int iHandle,int NodeIndex,int OnlyDeleteChildren VSDEFAULT(0));
#define   VSXMLCFG_ADD_BEFORE          0x1 /* Add a node before sibling in order */
#define   VSXMLCFG_ADD_AS_CHILD        0x2

/**
 * Adds node to XMLCFG tree.  Use the vsXMLCFGSetNname() function to set the name of a node.  Use the {@link vsXMLCFGSetValue}() function to set the value of a node.
 *
 * @param iHandle  Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndex   Tree node index to add attribute to.
 * @param pNameOrValue
 *                 Name or value of the element to be added.  If the NodeType specified requires a name, this specifies the name.  Otherwise, this specifies the value.
 * @param NameOrValueLen
 *                 Number of bytes in pNameOrValue.  -1 may be specified if pNameOrValue is a null terminated string.
 * @param NodeType      Indicates node type of child to find.
 *                      1 or more VSXMLCFG_NODE_* flags.  See
 *                      {@link _xmlcfg_add}()
 *                      for more information on this parameter.
 * @param iFlags   Add flags.  By default, a new sibling is created after NodeIndex.  0 or one of the following flags may be specified:
 *                  <ul>
 *                  <li>VSXMLCFG_ADD_BEFORE
 *                  <li>VSXMLCFG_ADD_AS_CHILD
 *                  </ul>
 *
 * @return Returns index to new node if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGAdd(int iHandle,int iIndex,const char *pNameOrValue,int NameOrValueLen,int NodeType,int iFlags);
#define VSXMLCFG_ADD_ATTR_AT_BEGINNING             0x1
/**
 * Adds attribute as a child of the NodeIndex specified.
 *
 * @param iHandle    Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndex     node index to add attribute to.
 * @param pszAttrName
 *                   Name of the attribute to be added.
 * @param pAttrValue Value of the attribute.
 * @param AttrValueLen
 *                   Number of bytes in pAttrValue.  -1 may be specified if pAttrValue is a null terminated string.
 * @param iFlags     combination of the following flags:
 *                  <DL>
 *                  <DT>VSXMLCFG_ADD_ATTR_AT_BEGINNING</DT>
 *                  <DD>Insert attribute at the beginning of the list of attributes
 *                  at this node.  By default, the attribute is added at the end.
 *                  </DD>
 *                  </DL>
 *
 * @return Returns node index of the new attribute if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGAddAttribute(int iHandle,int iIndex,const char *pszAttrName,const char *pAttrValue,int AttrValueLen VSDEFAULT(-1),int iFlags VSDEFAULT(0));
/**
 * Sets or adds an attribute value for the element node specified.
 *
 * @param iHandle    Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex  Index to a node
 * @param pszAttrName
 *                   Name of attribute.
 * @param pAttrValue New value for attribute.
 * @param AttrValueLen
 * @param iFlags     -1 indicates that an error should be returned if the attribute does
 *                   not already exists.  Otherwise, the vsXMLCFGAddAttribute() function
 *                   is called to add the attribute.
 *
 *                   <P>A combination of the following flags:
 *                   <DL>
 *                   <DT>VSXMLCFG_ADD_ATTR_AT_BEGINNING</DT>
 *                   <DD>Insert attribute at the beginning of the list of attributes
 *                   at this node.  By default, the attribute is added at the end.
 *                   </DD>
 *
 *                   </DL>
 *
 * @return Returns 0 if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGSetAttribute(int iHandle,int NodeIndex,const char * pszAttrName,const char *pAttrValue,int AttrValueLen VSDEFAULT(-1),int iFlags VSDEFAULT(0));
/**
 * Deletes an attribute
 *
 * @param iHandle Handle to an XML tree
 *
 * @param NodeIndex  Index to node to delete attribute from
 *
 * @param pszAttrName
 *                Name of attribute to delete
 *
 * @return Returns 0 if successful
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGDeleteAttribute(int iHandle,int NodeIndex,const char *pszAttrName);
/**
 * Finds the tree node index
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndex  Tree node index.
 * @param pszName Name of node to find.  This may be null.
 * @param NodeTypeFlags Indicates node type of child to find.
 *                      1 or more VSXMLCFG_NODE_* flags.  See
 *                      {@link _xmlcfg_add}()
 *                      for more information on this parameter.
 *
 * @return Returns the tree node index with element matching pszName which is a child of node NodeIndex.    Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGFindChildWithName(int iHandle,int iIndex,VSPSZ pszName,int NodeTypeFlags VSDEFAULT(VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END));
#define VSXMLCFG_FIND_APPEND       0x1
#define VSXMLCFG_FIND_VALUES       0x2
#define VSXMLCFG_FIND_FIRST_NODE   0x4  /* This is for internal use only. */
#define VSXMLCFG_FIND_CREATE       0x8  /* This is for internal use only. */
/**
 * Searches for nodes based on an subset XPath expression and inserts the results into the current buffer.
 *
 * @param wid       Window id of editor control.  0 specifies the current object.
 * @param iHandle   Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param pszQueryStr
 *                  This is a small subset of an XPath expression.  See {@link _xmlcfg_find_simple}() for information on this parameter.
 * @param NodeIndex Tree node index to start search from.
 *
 * @return Returns 0 if successful.  Otherwise a negative error code is returned.
 * @example <pre>
 * // Find the value of all "name" attributes under
 * // "/project/file" element nodes.
 * vsXMLCFGFindSimpleInsert(0,handle,"/project/file/@name");
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGFindSimpleInsert(int wid,int iHandle,const char *pszQueryStr,int NodeIndex VSDEFAULT(VSXMLCFG_ROOT_INDEX));
/**
 *
 * @param iHandle   iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param pszQueryStr
 *                  This is a small subset of an XPath
 *                  expression.  See {@link _xmlcfg_find_simple}() for
 *                  information on this parameter.
 * @param NodeIndex Tree node index to start search from.
 * @param reserved
 *
 * @return Returns node index (>=0) found if successful.  Otherwise a negative error code is returned.
 * @example <pre>
 * // Find the first file element node under /project with name equal to
 * // "main.c"
 * FileIndex=vsXMLCFGFindSimple(handle,
 *     "/project/file[file-eq(@name,'main.c')]");
 *
 * // Find the attribute node under /project/file with name equal
 * // to "main.c"
 * AttrIndex=vsXMLCFGFindSimple(handle,
 *     "/project/file/@name[file-eq(.,'main.c')]");
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGFindSimple(int iHandle,VSPSZ pszQueryStr,int NodeIndex VSDEFAULT(VSXMLCFG_ROOT_INDEX),int reserved VSDEFAULT(0));
/**
 * Searches for nodes based on an subset XPath expression.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param pszQueryStr
 *                  This is a small subset of an XPath
 *                  expression.  See {@link _xmlcfg_find_simple}() for
 *                  information on this parameter.
 * @param NodeIndex Tree node index to start search from.
 * @param FindFlags Zero or more of the following flags:
 *
 * @return If successful, returns array of integer node indexes where -1 terminates the array.  Otherwise 0 is returned.
 * @example <pre>
 * // Find all file element nodes under /project
 * int *piArray=vsXMLCFGFindSimpleArray(handle,"/project/file");
 *
 * // Find the "file" element nodes that are anywhere
 * // beneath the node specified.
 * int *piArray=vsXMLCFGFindSimpleArray(handle,"//file");
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
void VSAPI vsXMLCFGFindSimpleArray(int iHandle,VSPSZ pszQueryStr,int NodeIndex,slickedit::SEArray<int> &nodeArray,int FindFlags VSDEFAULT(0));
#define VSXMLCFG_CREATE_IF_EXISTS_CLEAR   0
#define VSXMLCFG_CREATE_IF_EXISTS_OPEN    1
#define VSXMLCFG_CREATE_IF_EXISTS_ERROR   2
#define VSXMLCFG_CREATE_IF_EXISTS_CREATE  3

/**
 * Creates or opens an existing XMLCFG tree.
 *
 * @param pszFilename
 *                  Name of XML file to create.  No disk I/O occurs.
 * @param iEncoding For standard XML files, this parameter should be
 * VSENCODING_UTF8. For Visual Studio 2002/2003 project files, this parameter 
 * should be VSCP_ACTIVE_CODEPAGE. For Visual Studio 2005, use VSENCODING_UTF8.
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
 * </pre></blockquote>
 * @param iCreateOption
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
 * @return Returns XMLCFG tree handle if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGCreate(const char *pszFilename,int iEncoding,int iCreateOption= VSXMLCFG_CREATE_IF_EXISTS_CREATE);
/**
 * Gets the previous sibling child index from the specified index.
 * The root index is always TREE_ROOT_INDEX,
 * so to traverse the tree start there.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex Index of node to get sibling node index for
 * @param NodeTypeFlags Indicates node type of child to find.
 *                      1 or more VSXMLCFG_NODE_* flags.  See
 *                      {@link _xmlcfg_add}()
 *                      for more information on this parameter.
 *
 * @return Returns the node index of the next sibling of the node specified by NodeIndex.  -1 is returned if the node specified has no next sibling.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGGetPrevSibling(int iHandle,int NodeIndex,int NodeTypeFlags VSDEFAULT(VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END));
/**
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex Index of node to get sibling node index for
 * @param NodeTypeFlags Indicates node type of child to find.
 *                      1 or more VSXMLCFG_NODE_* flags.  See
 *                      {@link _xmlcfg_add}()
 *                      for more information on this parameter.
 *
 *
 * @return Returns the node index of the next sibling of the node specified by NodeIndex.  -1 is returned if the node specified has no next sibling.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGGetNextSibling(int iHandle,int NodeIndex,int NodeTypeFlags VSDEFAULT(VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END));
/**
 * Duplicate a tree
 *
 * @param DestHandle Handle of destination tree
 * @param DestNodeIndex
 *                   Index of destination node
 * @param SrcHandle  Handle to source tree
 * @param iSrcNodeIndex
 *                   Index of source node
 * @param flags      Specifies one of the following flags:
 *                   <dl>
 *                   <dt>VSXMLCFG_COPY_CHILDREN<dd>copy children of source as the last children of the dest
 *                   <dt>VSXMLCFG_COPY_AS_CHILD<dd>copy the source as the last child of the dest
 *                   <dt>VSXMLCFG_COPY_BEFORE<dd>copy the source as a sibling before the dest
 *                   </dl>
 *                   Specify no flags to copy as a sibling after dest.   Note that this
 *                   function can not copy children as siblings.
 *
 * @return Returns first node created or VSRC_XMLCFG_NO_CHILDREN_COPIED if successful. Otherwise,
 *         an negative error code other than VSRC_XMLCFG_NO_CHILDREN_COPIED is returned.
 * @example <pre>
 * // Add tree as last child
 * vsXMLCFGCopy(DestHandle,DestNodeIndex,
 *    SrcHandle,SrcNodeIndex,VSXMLCFG_COPY_A_CHILD);
 *
 * // Add tree before dest node
 * vsXMLCFGCopy(DestHandle,DestNodeIndex,
 *    SrcHandle,SrcNodeIndex,VSXMLCFG_COPY_BEFORE);
 *
 * // Add tree after dest node
 * vsXMLCFGCopy(DestHandle,DestNodeIndex,
 *    SrcHandle,SrcNodeIndex);
 *
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGCopy(int DestHandle,int DestNodeIndex,int SrcHandle,int iSrcNodeIndex,int flags);
/**
 * Gets the filename for the XMLCFG tree specified.  This is the name specified in the
 * vsXMLCFGOpen and vsXMLCFGCreate calls.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 *
 * @return Returns the filename used to open or create this XML tree.
 *
 * @categories XMLCFG_Functions
 */
VSPSZ VSAPI vsXMLCFGGetFilename(int iHandle);
/**
 * Fetches the XML document modify state.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 *
 * @return Returns a non-zero value if the XML document has been modified.
 *
 * @categories XMLCFG_Functions
 */
int VSAPI vsXMLCFGGetModify(int iHandle);
/**
 * Sets XML document modify state.
 *
 * @param iHandle Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param Modify  New value for modify state
 *
 * @see vsXMLCFGGetModify
 *
 * @categories XMLCFG_Functions
 */
void VSAPI vsXMLCFGSetModify(int iHandle,int Modify);
/**
 * Sorts nodes that are children of a specified node.
 *
 * @param iHandle  Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iParentNode
 *                 of this node are sorted.
 * @param pszPrimaryAttrName
 *                 Name of primary attribute to sort on.
 * @param pszPrimaryOptions
 *                 String of one or more of the following options:
 *
 *
 *                 <dl compact>
 *                 <dt><b>F</b><dd>Sort filenames
 *                 <dt><b>N</b><dd>Sort numbers
 *                 <dt><b>I</b><dd>Case insensitive sort.  Sort is case sensitive if this option is not specified.
 *                 <dt><b>D</b><dd>Descending.  Sort is ascending if this option is not specified.
 *                 <dt><b>P</b><dd>Place parent nodes at the top after sort.  Here we consider a parent nodes with name PrimaryFolderElementName.
 *                 <dt><b>2</b><dd>Specialized filename sort.  Sort case insensitive on name without path, then case sensitive on name without path, then case insensitive on path.
 *                 </dl>
 * @param pszPrimaryFolderElementName
 *                 Only used if <b>P</b> option specified in <i>pszPrimaryOptions</i>. Indicates the
 *                 element of a folder.
 * @param pszSecondaryAttrName
 *                 Secondary attribute name to sort on
 * @param pszSecondaryOptions
 *                 Specifies secondary sort options.  See primary options for more information.
 * @param reserved
 *
 * @example <pre>
 * // Sort a folder node and place sub folders at the top.
 * // Note that it is OK that <Folder> nodes have no "N"
 * // attribute but do have a "Name" attribute.
 * vsXMLCFGSortOnAttribute(handle,FolderNode,"N",
 *    "Folder",
 *    "Name",
 *    "2P");
 * </pre>
 *
 * @categories XMLCFG_Functions
 */
void VSAPI vsXMLCFGSortOnAttribute(int iHandle,int iParentNode,
                                   const char *pszPrimaryAttrName,
                                   const char *pszPrimaryOptions,
                                   const char *pszPrimaryFolderElementName=0,
                                   const char *pszSecondaryAttrName=0,
                                   const char *pszSecondaryOptions=0,
                                   void *reserved=0);
int VSAPI vsXMLCFGGetNodeFromSeekPos(int iHandle,long lSeekPos);
void VSAPI vsXMLCFGGetSeekPosFromNode(int iHandle,int iIndex,int *piStatus,long *plSeek);
bool VSAPI XMLCFGIsValidNode(int iHandle,int iIndex);
bool VSAPI XMLCFGIsValidHandle(int iHandle);
EXTERN_C_END

/**
 * Saves an XMLCFG tree to a XML file.
 *
 * @param iHandle   Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndentAmount
 *                  Amount to indent for each level.  -1 to use tabs
 * @param iFlags    Formatting flags.   flags may be zero or more of the following flags:
 *
 *                  <DL>
 *                  <DT>VSXMLCFG_SAVE_ALL_ON_ONE_LINE</DT>
 *                  <DD>Specifies that all attributes for a given element be written on the same line.</DD>
 *                  <DT>VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR</DT>
 *                  <DD>Specifies that attributes for a given element be written on the same line if there is only one attribute.</DD>
 *                  <DT>VSXMLCFG_SAVE_DOS_EOL</DT>
 *                  <DD>Specifies that carriage return and line feed characters separate each line.  This is the default under Windows.</DD>
 *                  <DT>VSXMLCFG_SAVE_UNIX_EOL</DT>
 *                  <DD>Specifies that a line feed character separate each line.  This is the default under UNIX.</DD>
 *                  <DT>VSXMLCFG_SAVE_SPACE_AROUND_EQUAL</DT>
 *                  <DD>Specifies that spaces be added before and after the '=' for attributes and their values.</DD>
 *                  <DT>VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE</DT>
 *                  <DD>Specifies that the close brace be placed on a separate line.</DD>
 *                  </DL>
 * @param encoding  When -1 this parameter defaults to the value specified in the
 *                  vsXMLCFGOpen() or vsXMLCFGCreate() call.  For Microsort .NET project files,
 *                  this parameter should be VSCP_ACTIVE_CODEPAGE. encoding may be one of the
 *                  following:
 *
 *                  <blockquote></pre>
 *                  VSENCODING_UTF8
 *                  VSENCODING_UTF8_WITH_SIGNATURE
 *                  VSENCODING_UTF16LE
 *                  VSENCODING_UTF16LE_WITH_SIGNATURE
 *                  VSENCODING_UTF16BE
 *                  VSENCODING_UTF16BE_WITH_SIGNATURE
 *                  VSENCODING_UTF32LE
 *                  VSENCODING_UTF32LE_WITH_SIGNATURE
 *                  VSENCODING_UTF32BE
 *                  VSENCODING_UTF32BE_WITH_SIGNATURE
 *                  </PRE></blockquote>
 * @param NodeIndex The children of this node are written.
 * @param pfnCallback   Allows the indent to be customized for the contenst of a specific node.
 *
 * @return Returns 0 if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
slickedit::SEString vsXMLCFGSaveToString(int iHandle,int iIndentAmount,int iFlags,int NodeIndex VSDEFAULT(0), PFNXMLCFGCFG_SAVE_CALLBACK pfnCallback VSDEFAULT(0));

/**
 * Adds node to XMLCFG tree. 
 * Use the vsXMLCFGSetNname() function to set the name of a node. 
 * Use the {@link vsXMLCFGSetValue}() function to set the value of a node.
 *
 * @param iHandle          Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                         vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndex           Tree node index to add attribute to.
 * @param pNameOrValue     Name or value of the element to be added.  If the NodeType specified requires a name, this specifies the name.  Otherwise, this specifies the value.
 * @param NameOrValueLen   Number of bytes in pNameOrValue. 
 *                         -1 may be specified if pNameOrValue is a null terminated string.
 * @param NodeType         Indicates node type of child to find.
 *                         1 or more VSXMLCFG_NODE_* flags.  See
 *                         {@link _xmlcfg_add}()
 *                         for more information on this
 *                         parameter.
 * @param iFlags           Add flags. 
 *                         By default, a new sibling is created after NodeIndex.
 *                         0 or one of the following flags may be specified:
 *                         <ul>
 *                         <li>VSXMLCFG_ADD_BEFORE
 *                         <li>VSXMLCFG_ADD_AS_CHILD
 *                         </ul>
 *
 * @return Returns index to new node if successful. 
 *         Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
int vsXMLCFGAddString(int iHandle, int iIndex,
                      const slickedit::SEString &NameOrValue,
                      int NodeType, int iFlags);

/**
 * Retrieves attribute value for the attribute name given.
 * This function is thread-safe. 
 * 
 * @param iHandle          Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                         vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex        Tree node index.
 * @param pszAttrName      Name of attribute to return value of
 * @param pszDefaultValue  default value to return if attribute not present 
 *  
 * @return Returns attribute value if successful. 
 *         Otherwise pszDevaultValue is returned.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
slickedit::SEString vsXMLCFGGetAttributeString(int iHandle,int NodeIndex,
                                               VSPSZ pszAttrName,
                                               const char *pszDefaultValue=0);

/**
 * Retrieves a numeric attribute value for the attribute name given.
 * This function is thread-safe. 
 * 
 * @param iHandle          Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                         vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex        Tree node index.
 * @param pszAttrName      Name of attribute to return value of
 * @param iDefaultValue    default value to return if attribute not present 
 *  
 * @return Returns attribute value if successful.  Otherwise pszDevaultValue is returned.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
VSINT64 vsXMLCFGGetAttributeInteger(int iHandle,int NodeIndex,
                                    VSPSZ pszAttrName, VSINT64 iDefaultValue=0);

/**
 * Sets or adds an attribute value for the element node specified.
 *
 * @param iHandle       Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                      vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex     Index to a node
 * @param AttrName      Name of attribute.
 * @param AttrValue     New value for attribute.
 * @param iFlags        -1 indicates that an error should be returned if the 
 *                      attribute does not already exists.  Otherwise, the
 *                      vsXMLCFGAddAttribute() function is called to add the
 *                      attribute.
 *                      <P>
 *                      A combination of the following flags:
 *                      <DL>
 *                      <DT>VSXMLCFG_ADD_ATTR_AT_BEGINNING</DT>
 *                      <DD>Insert attribute at the beginning of the list of attributes
 *                      at this node.  By default, the attribute is added at the end.
 *                      </DD>
 *                      </DL>
 *
 * @return Returns 0 if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
int vsXMLCFGSetAttributeString(int iHandle, int NodeIndex,
                               const char *pszAttrName,
                               const slickedit::SEString &AttrValue,
                               int iFlags=0 );

/**
 * Adds attribute as a child of the NodeIndex specified.
 *
 * @param iHandle    Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndex     node index to add attribute to.
 * @param pszAttrName
 *                   Name of the attribute to be added.
 * @param pAttrValue Value of the attribute.
 * @param AttrValueLen
 *                   Number of bytes in pAttrValue.  -1 may be specified if pAttrValue is a null terminated string.
 * @param iFlags     combination of the following flags:
 *                  <DL>
 *                  <DT>VSXMLCFG_ADD_ATTR_AT_BEGINNING</DT>
 *                  <DD>Insert attribute at the beginning of the list of attributes
 *                  at this node.  By default, the attribute is added at the end.
 *                  </DD>
 *                  </DL>
 *
 * @return Returns node index of the new attribute if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
int vsXMLCFGAddAttributeString(int iHandle,int iIndex,
                               const char *pszAttrName, 
                               const slickedit::SEString &attrValue,
                               int iFlags VSDEFAULT(0));

/**
 * Sets or adds an integer attribute value for the element node specified.
 *
 * @param iHandle       Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                      vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex     Index to a node
 * @param AttrName      Name of attribute.
 * @param iAttrValue    New value for attribute.
 * @param iFlags        -1 indicates that an error should be returned if the 
 *                      attribute does not already exists.  Otherwise, the
 *                      vsXMLCFGAddAttribute() function is called to add the
 *                      attribute.
 *                      <P>
 *                      A combination of the following flags:
 *                      <DL>
 *                      <DT>VSXMLCFG_ADD_ATTR_AT_BEGINNING</DT>
 *                      <DD>Insert attribute at the beginning of the list of attributes
 *                      at this node.  By default, the attribute is added at the end.
 *                      </DD>
 *                      </DL>
 *
 * @return Returns 0 if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
int vsXMLCFGSetAttributeInteger(int iHandle, int NodeIndex,
                                const char *pszAttrName,
                                const VSINT64 iAttrValue,
                                int iFlags=0 );

/**
 * Adds attribute as a child of the NodeIndex specified.
 *
 * @param iHandle    Handle to an XMLCFG tree returned by vsXMLCFGOpen(), vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param iIndex     node index to add attribute to.
 * @param pszAttrName
 *                   Name of the attribute to be added.
 * @param pAttrValue Value of the attribute.
 * @param AttrValueLen
 *                   Number of bytes in pAttrValue.  -1 may be specified if pAttrValue is a null terminated string.
 * @param iFlags     combination of the following flags:
 *                  <DL>
 *                  <DT>VSXMLCFG_ADD_ATTR_AT_BEGINNING</DT>
 *                  <DD>Insert attribute at the beginning of the list of attributes
 *                  at this node.  By default, the attribute is added at the end.
 *                  </DD>
 *                  </DL>
 *
 * @return Returns node index of the new attribute if successful.  Otherwise a negative error code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
int vsXMLCFGAddAttributeInteger(int iHandle,int iIndex,
                                const char *pszAttrName, 
                                const VSINT64 attrValue,
                                int iFlags VSDEFAULT(0));

/**
 * Checks if the node name matches the given string. 
 * 
 * @param iHandle          Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                         vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex        Tree node index.
 * @param name             Node name to check against 
 * 
 * @return Returns 'true' if the node exists and it's name matches 'name'
 *
 * @categories XMLCFG_Functions
 */
VSDLLEXPORT bool vsXMLCFGIsNameEqual(int iHandle,int NodeIndex,const char *name);

/**
 * Gets the node name. 
 * This function is thread-safe. 
 *
 * @param iHandle          Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                         vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex        Tree node index.
 *
 * @return Returns the name for the node specified. 
 *         The name returned is null for comment, attribute,
 *         CDATA, and PCDATA nodes.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
slickedit::SEString vsXMLCFGGetNameString(int iHandle,int NodeIndex);

/**
 * Sets the name for the node specified. The name should be
 * null for comment, attribute, CDATA, and PCDATA nodes.
 *
 * @param iHandle          Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                         vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex        Tree node index.
 * @param Name             new name for the given node
 *
 * @return Returns 0 if successful.  Otherwise a negative return code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
int VSAPI vsXMLCFGSetNameString(int iHandle, int NodeIndex,
                                const slickedit::SEString &Name);

/**
 * Gets the node value
 * This function is thread-safe. 
 *
 * @param iHandle          Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                         vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex        Tree node index.
 *
 * @return Returns the value for the node specified. 
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
slickedit::SEString vsXMLCFGGetValueString(int iHandle,int NodeIndex);

/**
 * Sets the value for the node specified. The value returned is null
 * except for comment, attribute, CDATA, and PCDATA nodes.
 *
 * @param iHandle          Handle to an XMLCFG tree returned by vsXMLCFGOpen(), 
 *                         vsXMLCFGCreate(), or vsXMLCFGOpenFromBuffer().
 * @param NodeIndex        Tree node index.
 * @param Value            New value for node.
 *
 * @return Returns 0 if successful.  Otherwise a negative return code is returned.
 *
 * @categories XMLCFG_Functions
 */
extern VSDLLEXPORT
int VSAPI vsXMLCFGSetValueString(int iHandle, int NodeIndex,
                                 const slickedit::SEString &Value );


extern VSDLLEXPORT
slickedit::SEString vsXMLCFGGetValueStringUnindent(int iHandle, int NodeIndex);

#endif // __VSMINIXML_H_INCL__
