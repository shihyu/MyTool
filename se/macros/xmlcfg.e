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
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "xml.sh"
#import "stdprocs.e"
#endregion

/* 
 * Additional XMLCFG functionality implemented in macros.
 */

/**
 * Retrieves the number of children of a node.  Function is not recursive, only 
 * determines the first level of elements underneath the current level. 
 * 
 * @param handle           handle to xml tree
 * @param parent           parent to count children of
 * 
 * @return                 number of children of node
 *  
 * @categories XMLCFG_Functions
 */
int _xmlcfg_get_num_children(int handle, int parent)
{
   children := 0;
   childIndex := _xmlcfg_get_first_child(handle, parent);

   while (childIndex >= 0) {
      ++children;
      childIndex = _xmlcfg_get_next_sibling(handle, childIndex);
   }

   return children;
}

/**
 * Determines if the xml file found in the current buffer is valid xml.
 * 
 * @return                 true if the xml is valid, false otherwise 
 *  
 * @categories XMLCFG_Functions
 */
bool _xmlcfg_buffer_is_valid()
{
   // Check if this XML file seems valid.
   int status;
   int handle=_xmlcfg_open_from_buffer(0,status);
   if (handle<0) {
      return(false);
   }
   _xmlcfg_close(handle);
   return(true);
}

/**
 * Copies the subtree underneath an XML node to another location, where they are 
 * siblings of a destination node. 
 * 
 * @param dest_handle         handle to destination tree
 * @param dest_index          index of destination node
 * @param src_handle          handle to source tree
 * @param src_index           index of source node (parent of subtree to copy)
 * @param copyBefore          true to copy the subtree before the dest_index, 
 *                            false to copy them after
 * @return 
 *  
 * @categories XMLCFG_Functions
 */
void _xmlcfg_copy_children_as_siblings(int dest_handle,int dest_index,int src_handle,int src_index, bool copyBefore = false)
{
   first := true;
   src_index=_xmlcfg_get_first_child(src_handle,src_index,~VSXMLCFG_NODE_ATTRIBUTE);
   while (src_index>=0) {
      copyFlags := 0;
      if (first && copyBefore) copyFlags = VSXMLCFG_COPY_BEFORE;
         
      //say('dest='_xmlcfg_get_name(handle,dest_index));
      //say('src type='_xmlcfg_get_type(src_handle,src_index));
      dest_index=_xmlcfg_copy(dest_handle,dest_index,src_handle,src_index,copyFlags);
      src_index=_xmlcfg_get_next_sibling(src_handle,src_index,~VSXMLCFG_NODE_ATTRIBUTE);

      first = false;
   }
}

void _xmlcfg_copy_children_with_name(int handle,int ParentNode,int NewParentNode,_str name,bool doMove=false)
{
   int child;
   child=_xmlcfg_get_first_child(handle,ParentNode);
   int flags=VSXMLCFG_COPY_AS_CHILD;
   while (child>=0) {
      if (_xmlcfg_get_name(handle,child)==name) {
         NewParentNode=_xmlcfg_copy(handle,NewParentNode,handle,child,flags);
         flags=0;
         int next_child=_xmlcfg_get_next_sibling(handle,child);
         if(doMove) _xmlcfg_delete(handle,child);
         child=next_child;
      } else {
         child=_xmlcfg_get_next_sibling(handle,child);
      }
   }
}

/**
 * Deletes all children of ParentNodeIndex with the specified Name.
 * 
 * @param handle     Handle to an XMLCFG tree returned by _xmlcfg_open(), _xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param ParentNode Tree node index.
 * @param name       Name of elements to delete. 
 * @categories XMLCFG_Functions
 */
void _xmlcfg_delete_children_with_name(int handle,int ParentNode,_str name)
{
   int Node=_xmlcfg_get_first_child(handle,ParentNode);
   while (Node>=0) {
      int Next=_xmlcfg_get_next_sibling(handle,Node);
      if (_xmlcfg_get_name(handle,Node):==name) {
         _xmlcfg_delete(handle,Node);
      } else {
         _xmlcfg_delete_children_with_name(handle,Node,name);
      }
      Node=Next;
   }
}

/**
 * another element with the attribute specified below QueryStr.
 * 
 * @param handle    Handle to an XMLCFG tree returned by _xmlcfg_open(), _xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param QueryStr  This is a small subset of an XPath expression.  See _xmlcfg_find_simple() for information on this parameter.
 * @param element   Name of tag to add.
 * @param AttrName Name of attribute to set value for ElementName
 * @param AttrValue Value for attribute.
 * 
 * @return Returns index of element node if successful.  Otherwise a negative error code is returned.
 * @example <pre>
 * // Add another [Set] element under /Workspace/Environment 
 * // and set the value.
 * Node=_xmlcfg_set_path2(handle,
 *     "/Workspace/Environment","Set",
 *     "Name",
 *     "VERSION"
 *     );
 * _xmlcfg_set_attribute(handle,Node,"Value","8.0");
 * </pre>
 *  
 * @categories XMLCFG_Functions
 */
int _xmlcfg_set_path2(int handle,_str QueryStr,_str element,_str AttrName,_str AttrValue)
{
   int NodeIndex=_xmlcfg_set_path(handle,QueryStr);
   typeless array[];
   _xmlcfg_find_simple_array(handle,QueryStr'/'element,array);
   if (!array._length()) {
      int FirstChild=_xmlcfg_get_first_child(handle,NodeIndex);
      if (FirstChild>=0) {
         NodeIndex=_xmlcfg_add(handle,FirstChild,element,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_BEFORE);
      } else {
         NodeIndex=_xmlcfg_add(handle,NodeIndex,element,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      }
      //NodeIndex=_xmlcfg_add(handle,NodeIndex,element,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   } else {
      NodeIndex=_xmlcfg_add(handle,array[array._length()-1],element,VSXMLCFG_NODE_ELEMENT_START_END,0);
   }
   _xmlcfg_set_attribute(handle,NodeIndex,AttrName,AttrValue);

   return(NodeIndex);
}

/**
 * Construct an XPath query string for the element specified.
 * 
 * @param handle      Handle to an XMLCFG tree returned by _xmlcfg_open(),
 *                    _xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param elementNode Node index of element to construct XPath query string for.
 * @param queryStr    (output). Query string for element node.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @example
 * <pre>
 * Element node:
 * 
 *   &lt;file name="main.c" option="debug"&gt;
 * 
 * Resulting XPath expression:
 * 
 *   /file[@name='main.c'][@option='debug']
 * </pre>
 *  
 * @categories XMLCFG_Functions
 */
int _xmlcfg_get_xpath_from_node(int handle, int elementNode, _str& queryStr)
{
   status := 0;

   queryStr="";

   OUTER:
   do {

      name := _xmlcfg_get_name(handle,elementNode);
      if( name==null ) {
         // Error
         status=VSRC_INVALID_ARGUMENT;
         break;
      }
      result :=  "/"name;
      int iattr = _xmlcfg_get_next_attribute(handle,elementNode);
      while( iattr>=0 ) {
         attr_name := _xmlcfg_get_name(handle,iattr);
         if( attr_name==null ) {
            // Error
            status=VSRC_XMLCFG_EXPECTING_ATTRIBUTE_NAME;
            break OUTER;
         }
         _str attr_val = _xmlcfg_get_value(handle,iattr);
         if( attr_val==null ) {
            // Error
            status=VSRC_XMLCFG_INVALID_NODE_INDEX;
            break OUTER;
         }
         result :+= "[@"attr_name"='"attr_val"']";
         iattr = _xmlcfg_get_next_attribute(handle,iattr);
      }
      if( iattr!=VSRC_XMLCFG_ATTRIBUTE_NOT_FOUND ) {
         // Error
         status=iattr;
         break;
      }

      // Success
      status=0;
      queryStr=result;

   } while( false );

   return status;
}

/**
 * Create a hash table of attributes for the given element node.
 * 
 * @param handle      Handle to an XMLCFG tree returned by _xmlcfg_open(),
 *                    _xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param elementNode Node index of element to create attribute hash table for.
 * @param ht          (output). Hash table of attribute string values. The hash table
 *                    indices are the attribute names.
 * @param append      (optional). If true, then attributes retrieved will be added
 *                    to, or replace existing, elements in the hash table.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @example
 * <pre>
 * // Hash table of attributes and values
 * _str ht:[];
 * int status;
 * int handle = _xmlcfg_open("project.xml",status);
 * // Find the first "file" element node under project element node which
 * // is under the root.
 * int elementNode = _xmlcfg_find_simple(handle,"/project/file");
 * status=_xmlcfg_get_attribute_ht(handle,elementNode,ht);
 * // Iterate through all attributes in the hash table
 * typeless i;
 * i._makeempty();
 * for( ;; ) {
 *    ht._nextel(i);
 *    if( i._isempty() ) break;
 *    say("Attribute: "i" = "ht:[i]);
 * }
 * </pre>
 *  
 * @categories XMLCFG_Functions
 */
int _xmlcfg_get_attribute_ht(int handle, int elementNode, _str (&ht):[], bool append=false)
{
   status := 0;

   if( !append ) {
      ht._makeempty();
   }

   // We do not want to foul up the caller's hash table if things go wrong,
   // so we wait and copy the results in after we have success.
   _str htresult:[]; htresult._makeempty();

   OUTER:
   do {

      int iattr = _xmlcfg_get_next_attribute(handle,elementNode);
      while( iattr>=0 ) {
         attr_name := _xmlcfg_get_name(handle,iattr);
         if( attr_name==null ) {
            // Error
            status=VSRC_XMLCFG_EXPECTING_ATTRIBUTE_NAME;
            break OUTER;
         }
         _str attr_val = _xmlcfg_get_value(handle,iattr);
         if( attr_val==null ) {
            // Error
            status=VSRC_XMLCFG_INVALID_NODE_INDEX;
            break OUTER;
         }
         htresult:[attr_name]=attr_val;
         iattr = _xmlcfg_get_next_attribute(handle,iattr);
      }
      if( iattr!=VSRC_XMLCFG_ATTRIBUTE_NOT_FOUND ) {
         // Error
         status=iattr;
         break;
      }

      // Success
      status=0;
      typeless i;
      i._makeempty();
      for( ;; ) {
         htresult._nextel(i);
         if( i._isempty() ) break;
         ht:[i]=htresult:[i];
      }

   } while( false );

   return status;
}


/**
 * Removes all the nodes in the XML DOM that are not direct parents or children 
 * of the given node. 
 *  
 * @param handle        Handle to an XMLCFG tree returned by _xmlcfg_open(),
 *                      _xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param indexToSave   Node index of element to save parents and children of 
 *  
 * @return 0 on success, <0 on error.
 *  
 * @categories XMLCFG_Functions
 */
int _xmlcfg_trim_to_only_this_node(int handle, int indexToSave)
{
   // get parent
   parent := _xmlcfg_get_parent(handle, indexToSave);
   // go through children and delete the ones that are not favored
   child := _xmlcfg_get_first_child(handle, parent);
   while (child > 0) {
      nextChild := _xmlcfg_get_next_sibling(handle, child);
      if (child != indexToSave) _xmlcfg_delete(handle, child);

      child = nextChild;
   }
   
   if (parent != TREE_ROOT_INDEX) {
      return _xmlcfg_trim_to_only_this_node(handle, parent);
   }

   return 0;
}

/**
 * Deletes all the attributes of a given node.
 * 
 * @param handle      Handle to an XMLCFG tree returned by _xmlcfg_open(),
 *                    _xmlcfg_create(), or _xmlcfg_open_from_buffer().
 * @param elementNode Node index of element to delete attributes of
 * 
 * @return 0 on success, <0 on error.
 * 
 * @categories XMLCFG_Functions
 */
int _xmlcfg_delete_all_attributes(int handle, int elementNode)
{
   _str attr:[];
   status := _xmlcfg_get_attribute_ht(handle, elementNode, attr);
   if (status) return status;

   foreach (auto attrName => . in attr) {
      status = _xmlcfg_delete_attribute(handle, elementNode, attrName);
      if (status) break;
   }

   return status;
}

/**
 * Deletes the first n children from a node.
 * 
 * @param handle              handle to xml tree
 * @param parent              parent node of children to delete
 * @param numToDelete         number of children to delete.  if this number is 
 *                            greater than the number of children that the node
 *                            has, then all children are deleted
 * 
 * @return int                0 on success, < 0 on error 
 *  
 * @categories XMLCFG_Functions
 */
int _xmlcfg_delete_first_n_children(int handle, int parent, int numToDelete)
{
   status := 0;

   numDeleted := 0;
   while (numDeleted < numToDelete) {
      child := _xmlcfg_get_first_child(handle, parent);
      if (child < 0) break;

      status = _xmlcfg_delete(handle, child);
      if (status) break;

      numDeleted++;
   }

   return status;
}

/**
 * Deletes the last n children from a node.
 * 
 * @param handle              handle to xml tree
 * @param parent              parent node of children to delete
 * @param numToDelete         number of children to delete.  if this number is 
 *                            greater than the number of children that the node
 *                            has, then all children are deleted
 * 
 * @return int                0 on success, < 0 on error 
 *  
 * @categories XMLCFG_Functions
 */
int _xmlcfg_delete_last_n_children(int handle, int parent, int numToDelete)
{
   status := 0;

   numDeleted := 0;
   while (numDeleted < numToDelete) {
      child := _xmlcfg_get_last_child(handle, parent);
      if (child < 0) break;

      status = _xmlcfg_delete(handle, child);
      if (status) break;

      numDeleted++;
   }

   return status;
}
