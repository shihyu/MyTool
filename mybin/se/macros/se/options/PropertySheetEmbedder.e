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
#import "propertysheetform.e"
#import "math.e"
#import "stdprocs.e"
#import "treeview.e"
#require "OptionsPanelInfo.e"
#require "PropertySheet.e"
#endregion Imports

namespace se.options;

class PropertySheetEmbedder : OptionsPanelInfo {

   // window id of our property sheet dialog
   int m_wid = 0;
   // the color that we use to highlight properties that were found in a search
   private const SEARCH_COLOR = '0xFFC4A4';
   // the color used to highlight protected properties
   private const PROTECTED_COLOR = '0xD8D8D8';
   // used to mark a protected property
   private int m_protectedIcon = 0;

   /**
    * Constructor.
    * 
    */
   PropertySheetEmbedder(_str caption = '', _str systemHelp = '')
   {
      OptionsPanelInfo(caption, '', systemHelp);

      m_protectedIcon = _find_or_add_picture('_lock.ico');
   }

   public void initialize(int wid, PropertySheet &ps, int helpHandle)
   {
      m_wid = wid;
      if (m_wid != 0) {
         m_wid._property_sheet_form_init_for_options(ps, helpHandle);
      }
   }

   public boolean isModified()
   {
      return m_wid._property_sheet_form_is_modified();
   }                                  

   public boolean apply(int &changeEventsTriggered, _str (&appliedProperties)[])
   {
      return m_wid._property_sheet_form_apply(changeEventsTriggered, appliedProperties);
   }

   public PropertySheet * getPropertySheetData()
   {
      return m_wid._property_sheet_form_get_property_sheet_data();
   }

   /**
    * Saves the relative sizes of the columns in the property
    * sheets so that all property sheet columns will be sized the
    * same.
    */
   public void saveColumnSizes()
   {
      m_wid.save_property_sheet_column_sizes();
   }

   /**
    * Sizes the property sheets columns to match the others in the
    * options.
    */
   public void sizeColumns()
   {
      m_wid.size_property_sheet_columns();
   }

   public void markSpecialProperties(int (&foundProperties)[], int (&protectedProperties)[], int (&propertyIcons):[])
   {
      // string = bgColor fgColor icon flags

      // we need to construct a hash table that will list all the 
      // physical attributes for each node, so the property sheet 
      // will know what to do

      _str attributes:[];
      foreach (auto property in foundProperties) {
         attributes:[property] = hex2dec(SEARCH_COLOR)',,,';
      }

      foreach (property in protectedProperties) {
         attributes:[property] = hex2dec(PROTECTED_COLOR)',,'m_protectedIcon','(TREENODE_DISABLED | TREENODE_BOLD);
      }

      foreach (property => auto icon in propertyIcons) {
         attributes:[property] = ',,'icon',';
      }

      m_wid._property_sheet_form_mark_special_properties(attributes);
   }

   /**
    * Returns the type of panel for this object.
    * 
    * @return        the OPTIONS_PANEL_TYPE of this object
    */
   public int getPanelType()
   {
      return OPT_PROPERTY_SHEET;
   }
}
