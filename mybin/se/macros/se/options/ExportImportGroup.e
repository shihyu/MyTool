////////////////////////////////////////////////////////////////////////////////////
// $Revision: 43889 $
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
 * Determines whether an item is to be exported.  If this node is not a leaf, 
 * then there is a third setting to determine that some of the children are to 
 * be exported and some not. 
 */
enum ExportImportItemStatus {
   EIIS_FALSE,             // this node will not be exported/imported
   EIIS_TRUE,              // this node will be exported/imported
   EIIS_SOME_CHILDREN      // some of this node's children will be exported/imported
};

/**
 * Determines whether an item is protected or not.  If a setting is protected, 
 * then the user cannot change its value without at least a little finagling. 
 */
enum ExportImportProtectionStatus {
   EIPS_FALSE,             // do not protect this item
   EIPS_TRUE,              // protect this item
   EIPS_UNPROTECT          // if this item is protected, then unprotect it
};

/** 
 * Keeps track of an item and its current export status and protection status 
 * within the ExportImportGroup. 
 */
struct ExportImportItem {
   int Status;             // one of the ExportImportItemStatus enum
   int ProtectStatus;      // one of the ExportImportProtectionStatus enum
};

/**
 * This class keeps track of an Export Group, which is a group of properties 
 * to be exported and imported together.  Users who frequently export the same 
 * group of options may wish to create a group so they can quickly re-export the 
 * same options whenever any of the options might have changed. 
 */
class ExportImportGroup {

   private _str m_name = '';                    // name of this group
   private ExportImportItem m_items:[];         // a list of the items, keyed off 
                                                // their indices in the regular options XML DOM
   private boolean m_modified = false;          // whether this group has been modified

   /**
    * Constructor.  Initializes the group name.
    * 
    * @param name          name of this group
    */
   ExportImportGroup(_str name = '')
   { 
      m_name = name;
   }

   /**
    * Sets the name of this ExportImportGroup.
    * 
    * @param name          name of this group
    */
   public void setName(_str name)
   {
      m_name = name;
   }

   /**
    * Retrieves the name of this ExportImportGroup.
    * 
    * @return              name of this group
    */
   public _str getName()
   {
      return m_name;
   }

   /**
    * Determines whether this group has been modified since it was last saved.
    * 
    * @return              true if the group was modified, false otherwise
    */
   public boolean isGroupModified()
   {
      return m_modified;
   }

   /**
    * Adds an item to the group.
    * 
    * @param eti           item to be added to the group
    * @param index         index of the item in the XML DOM
    * @param isNew         whether this item is new (thus changing modified 
    *                      status)
    */
   public void addGroupItem(ExportImportItem eti, int index, boolean isNew = true)
   {
      m_items:[index] = eti;
      if (!m_modified) {
         m_modified = isNew;
      }
   }

   /**
    * Returns the current status of the item associated with the given index.
    * 
    * @param index         index of item to check
    * 
    * @return              current ExportImport status (ExportImportItemStatus 
    *                      enum)
    */
   public int getItemStatus(int index)
   {
      // make sure we even have this item in stock
      if (m_items._indexin(index)) {
         return m_items:[index].Status;
      }

      return null;
   }

   /**
    * Returns the current protection status of the item associated with the 
    * given index. 
    * 
    * @param index         index of item to check
    * 
    * @return              current Protection Status (member of 
    *                      ExportImportProtectionStatus enum)
    */
   public boolean isItemProtected(int index)
   {
      if (m_items._indexin(index)) {
         return (m_items:[index].ProtectStatus == EIPS_TRUE);
      }

      return false;
   }

   /**
    * Sets the status of the item associated with the given index.
    * 
    * @param index         index of item to change
    * @param value         new status 
    */
   public void setItemStatus(int index, int value)
   {
      m_modified = true;

      if (m_items._indexin(index)) {
         m_items:[index].Status = value;
      } else {
         // we make a new item with a default protection status
         ExportImportItem eii;
         eii.Status = value;
         eii.ProtectStatus = EIPS_FALSE;
         m_items:[index] = eii;
      }

      // make sure the protection is off if the import/export is off
      if (value == EIIS_FALSE) setItemProtectionStatus(index, EIPS_FALSE);
   }

   /**
    * Sets the protection status of the item associated with the given index.
    * 
    * @param index            index of item to change
    * @param value            new protection status
    */
   public void setItemProtectionStatus(int index, int value)
   {
      m_modified = true;

      // make sure we are exporting this option
      if (value == EIPS_TRUE || value == EIPS_UNPROTECT) {
         if (getItemStatus(index) != EIIS_TRUE) {
            setItemStatus(index, EIIS_TRUE);
         }
      }

      if (m_items._indexin(index)/* && m_items:[index].Status == EIIS_TRUE*/) {
         m_items:[index].ProtectStatus = value;
      } 

   }

   /**
    * Retrieves the protection status of the item associated with the given 
    * index. 
    * 
    * @param index            index of item to check
    * 
    * @return                 protection status of item
    */
   public int getItemProtectionStatus(int index)
   {
      if (m_items._indexin(index)) {
         return m_items:[index].ProtectStatus;
      } 

      return EIPS_FALSE;
   }

   /**
    * Copies the items of this group into another group.  Can be used to create 
    * a new group based off an existing one. 
    * 
    * @param dest             ExportImportGroup to copy items to
    */
   public void copyItemsToGroup(ExportImportGroup &dest)
   {
      typeless i;
      for (i._makeempty();;) {
         m_items._nextel(i);
         if (i._isempty()) break;
         dest.addGroupItem(m_items:[i], i);
      }
   }

   /**
    * Retrieve all the indices that are set to be imported or exported. 
    * Includes parent nodes which have the "some children" status. 
    * 
    * @return                 array of XML indices (in the regular options XML 
    *                         DOM)
    */
   public INTARRAY getAllIndices(boolean allowSomeChildren = true)
   {
      int list[];

      ExportImportItem item;
      int index;
      foreach (index => item in m_items) {
         if (item.Status == EIIS_TRUE || 
             (allowSomeChildren && item.Status == EIIS_SOME_CHILDREN)) list[list._length()] = index;
      }

      return list;
   }

   /**
    * Retrieve all the indices that are set to be imported or exported. 
    * Includes parent nodes which have the "some children" status. 
    * 
    * @return                 array of XML indices (in the regular options XML 
    *                         DOM)
    */
   public void getAllIndicesWithStatus(int (&table):[])
   {
      ExportImportItem item;
      int index;
      foreach (index => item in m_items) {
         table:[index] = item.Status;
      }
   }

   /**
    * Retrieve all the indices that are set to be imported or exported. 
    * Includes parent nodes which have the "some children" status. 
    * 
    * @return                 array of XML indices (in the regular options XML 
    *                         DOM)
    */
   public void getAllIndicesWithProtections(int (&table):[])
   {
      ExportImportItem item;
      int index;
      foreach (index => item in m_items) {
         if (item.ProtectStatus != EIPS_FALSE) {
            table:[index] = item.ProtectStatus;
         }
      }
   }

   /**
    * Determines if any of the items in this group are being exported/imported 
    * and are protected. 
    * 
    * @return                 true if at least one item is being 
    *                         exported/imported as protected
    */
   public boolean areAnyItemsProtected(boolean includeUnprotects)
   {
      ExportImportItem item;
      foreach (item in m_items) {
         if (item.Status == EIIS_TRUE && 
             (item.ProtectStatus == EIPS_TRUE || 
              (includeUnprotects && item.ProtectStatus == EIPS_UNPROTECT))) {
            return true;
         }
      }

      return false;
   }
};
