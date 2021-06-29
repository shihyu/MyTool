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
#endregion Imports

namespace se.options;

/** 
 * This class is basically a dressed-up bi-directional hash
 * table.  It was implemented specifically for the relation
 * between XML and Tree indexes for the options dialog.
 * Maintains the one-to-one correspondence between indices of a
 * Tree and XML DOM.
 * 
 */
class RelationTable
{
   private int m_table:[];

   RelationTable()
   { }

   /** 
    * Clears the table to start anew!
    * 
    */
   public void clearTable()
   {
      if (m_table != null) {
         m_table._makeempty();
      }
   }

   /** 
    * Returns the XML index that corresponds to the given tree 
    * index. 
    * 
    * @param treeNode   tree index
    * 
    * @return int       XML index mapping to given tree index
    */
   public int getXMLIndex(int treeNode)
   {
      tree :=  "tree" :+ treeNode;
      if (m_table._indexin(tree)) {
         return m_table:[tree];
      }

      return -1;
   }

   /** 
    * Returns the tree index that corresponds to the given XML 
    * index. 
    * 
    * @param xmlNode    XML index
    * 
    * @return int       tree index mapping to given XML index
    */
   public int getTreeIndex(int xmlNode)
   {
      xml :=  "xml" :+ xmlNode;
      if (m_table._indexin(xml)) {
         return m_table:[xml];
      }

      return -1;
   }

   /** 
    * Sets a mapping between the input parameters.
    * 
    * @param xmlNode    XML index to be mapped
    * @param treeNode   Tree index to be mapped
    */
   public void setNodeRelation(int xmlNode, int treeNode)
   {
      _str xml, tree;
      xml = "xml" :+ xmlNode;
      tree = "tree" :+ treeNode;

      m_table:[xml] = treeNode;
      m_table:[tree] = xmlNode;
   }
};
