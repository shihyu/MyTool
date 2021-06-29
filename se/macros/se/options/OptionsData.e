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
#require "OptionsPanelInfo.e"
#require "DialogEmbedder.e"
#require "DialogExporter.e"
#require "PropertySheetEmbedder.e"
#endregion Imports

namespace se.options;

/**
 * This class acts as storage for all the data needed by the
 * OptionsTree.
 * 
 */
class OptionsData {

   // keyed by XML indexes
   // contains the window IDs of the gui elements that have been opened
   private int m_panelWIDs:[];          
   // contains the property sheet DATA of elements that have been opened
   private OptionsPanelInfo m_panelInfo:[];
   // contains the window ids of dialogs which are known to be shared across multiple nodes
   private int m_sharedWIDs:[];

   /**
    * Constructor.
    * 
    */
   OptionsData()
   { 
      m_sharedWIDs._makeempty();
      m_panelWIDs._makeempty();
      m_panelInfo._makeempty();
   }

   /**
    * Clears out the data and deletes all the windows that were
    * opened by the options dialog.
    * 
    */
   public void clear()
   {
      m_panelInfo._makeempty();

      // delete all the windows we've opened
      typeless i;
      foreach (i in m_panelWIDs) {
         if (i != null && _iswindow_valid(i)) {
            i._delete_window();
         }
      }

      // even the shared ones
      foreach (i in m_sharedWIDs) {
         if (i != null && _iswindow_valid(i)) {
            i._delete_window();
         }
      }

      m_panelWIDs._makeempty();
      m_sharedWIDs._makeempty();
   }

   /**
    * Clears the panel information for a set of indices.  Deletes
    * the related windows unless they are shared.
    * 
    * @param indices indices to delete info for
    */
   public void clearPanelInfoForIndices(int (&indices)[])
   {
      int i;
      for (i = 0; i < indices._length(); i++) {
         clearPanelInfoForIndex(indices[i]);
      }
   }

   /**
    * Clears the panel information for an index. 
    * Deletes the related windows unless they are shared. 
    * 
    * @param index to delete info for
    */
   public void clearPanelInfoForIndex(int index)
   {
      if (m_panelWIDs._indexin(index)) {
         wid := m_panelWIDs:[index];
         if (wid != null && _iswindow_valid(wid) && !isWIDShared(wid)) {
            wid._delete_window();
         } 
      }
      m_panelWIDs._deleteel(index);
      m_panelInfo._deleteel(index);
   }

   /**
    * Get the window id for the panel displayed when the given XML
    * index is displayed in the tree.
    * 
    * @param index      index associated with the window id that we want
    * 
    * @return           window id, -1 if index is not associated
    *                   with any window id
    */
   public int getWID(int index)
   {
      ret := -1;
      if (m_panelWIDs._indexin(index)) {
         ret = m_panelWIDs:[index];
      }

      return ret;
   }

   /**
    * Sets a window id and index relationship.
    * 
    * @param index  index to put in hashtable as key
    * @param wid    window id associated with given index
    */
   public void setWID(int index, int wid)
   {
      m_panelWIDs:[index] = wid;
   }


   /**
    * Determines if the given wid is shared.
    * 
    * @param wid    wid to check
    * 
    * @return true if wid is shared, false otherwise
    */
   private bool isWIDShared(int wid)
   {
      foreach (auto sharedWid in m_sharedWIDs) {
         if (sharedWid == wid) return true;
      }
//    typeless i;
//    for (i._makeempty();;) {
//       m_sharedWIDs._nextel(i);
//       if (i._isempty()) break;
//       if (m_sharedWIDs:[i] == wid) return true;
//    }

      return false;
   }

   /**
    * Returns whether a shared dialog by the given name has already
    * been loaded.
    * 
    * @param name    name of shared dialog
    * 
    * @return        whether the given dialog has already been loaded
    */
   public bool isAlreadyShared(_str name)
   {
      return m_sharedWIDs._indexin(name);
   }

   /**
    * Returns the window id of the shared dialog associated with
    * the given name.  If no shared dialog has that name, -1 is
    * returned.
    * 
    * @param name    name of shared dialog
    * 
    * @return        window id of loaded shared dialog
    */
   public int getSharedWID(_str name)
   {
      ret := -1;
      if (m_sharedWIDs._indexin(name)) {
         ret = m_sharedWIDs:[name];
      }
      return ret;
   }

   /**
    * Adds a shared dialog to our store.  Dialog is keyed off by
    * its name, and the value is the window id.
    * 
    * @param name   name of shared dialog
    * @param wid    window id of loaded shared dialog
    */
   public void addSharedWID(_str name, int wid)
   {
      m_sharedWIDs:[name] = wid;
   }

   /**
    * Determines whether the dialog associated with an index has
    * already been loaded.
    * 
    * @param index  index to check
    * 
    * @return true if dialog has been loaded, false otherwise
    */
   public bool hasBeenLoaded(int index)
   {
      return m_panelInfo._indexin(index);
   }

   /**
    * Returns the panel information associated with the given
    * index.
    * 
    * @param index      index of info that we want
    * 
    * @return           pointer to the info associated with the
    *                   index, null if none is found
    */
   public OptionsPanelInfo * getPanelInfo(int index)
   {
      if (m_panelInfo._indexin(index)) {
         return &(m_panelInfo:[index]);
      }

      return null;
   }

   /**
    * Returns a pointer to the DialogExporter associated with this index.  If no
    * info is associated with the index or the info is not of type 
    * DialogExporter, null is returned. 
    * 
    * @param index  indes of info wanted
    * 
    * @return pointer to DialogExporter, or null
    */
   public DialogExporter * getDialogExporter(int index)
   {
      panelType := getPanelType(index);
      if (panelType == OPT_DIALOG_FORM_EXPORTER || panelType == OPT_DIALOG_SUMMARY_EXPORTER) {
         return &((DialogExporter)m_panelInfo:[index]);
      }

      return null;
   }
   
   /**
    * Returns a pointer to the DialogEmbedder associated with this index.  If no
    * info is associated with the index or the info is not of type 
    * DialogEmbedder, null is returned. 
    * 
    * @param index  indes of info wanted
    * 
    * @return pointer to DialogEmbedder, or null
    */
   public DialogEmbedder * getDialogEmbedder(int index)
   {
      if (getPanelType(index) == OPT_DIALOG_EMBEDDER) {
         return &((DialogEmbedder)m_panelInfo:[index]);
      }

      return null;
   }

   /**
    * Returns a pointer to the PropertySheet associated with
    * this index.  If no info is associated with the index or the
    * info is not of type PropertySheet, null is returned.
    * 
    * @param index  indes of info wanted
    * 
    * @return pointer to PropertySheet, or null
    */
   public PropertySheetEmbedder * getPropertySheet(int index)
   {
      if (getPanelType(index) == OPT_PROPERTY_SHEET) {
         return &((PropertySheetEmbedder)m_panelInfo:[index]);
      }

      return null;
   }

   /**
    * Sets the panel info for an index.
    * 
    * @param index  index to associated with this info
    * @param opi    OptionsPanelInfo object
    */
   public void setPanelInfo(int index, OptionsPanelInfo &opi)
   {
      m_panelInfo:[index] = opi;
   }

   /**
    * Returns the type of panel at the specified index
    * 
    * @param index   index to be checked (-1 to use the input parameter)
    * 
    * @return        the OPTIONS_PANEL_TYPE of this object
    */
   public int getPanelType(int index)
   {
      // see if we have a panel already
      if (m_panelInfo._indexin(index)) {
         return m_panelInfo:[index].getPanelType();
      } 

      return OPT_UNKNOWN;
   }

   /**
    * Gets the text that should go into the help label for the
    * selected tree node and possibly property (when property sheet
    * is current).
    * 
    * @return              help information
    */
   public _str getHelp(int xmlIndex)
   {
      OptionsPanelInfo * opi = getPanelInfo(xmlIndex);
      if (opi != null) {
         return opi -> getPanelHelp();
      }

      return '';
   }
};
