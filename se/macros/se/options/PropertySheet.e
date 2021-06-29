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
#require "BooleanProperty.e"
#require "ColorProperty.e"
#require "IPropertyTreeMember.e"
#require "NumericProperty.e"
#require "Path.e"
#require "Property.e"
#require "PropertyGroup.e"
#require "Select.e"
#require "TextProperty.e"
#import "guicd.e"
#import "math.e"
#import "treeview.e"
#endregion Imports

namespace se.options;

/**
 * Different types that can be contained in a PropertySheet.
 */
enum TreeMemberType {
   TMT_UNKNOWN = -2,
   TMT_NULL = -1,
   TMT_GROUP = 0,
   TMT_PROPERTY = 1,
};

/** 
 * Keeps up with a list of properties.  
 * 
 */
class PropertySheet {

   private IPropertyTreeMember m_properties[];         // our list of properties
   private _str m_sheetHelp = '';          // help information that will appear directly in the dialog
   private _str m_systemHelp = '';         // p_help tag for this panel in the Help System 
   private _str m_caption = '';

   /**
    * Constructor.
    * 
    */
   PropertySheet(_str caption = '', _str systemHelp = '', _str sheetHelp = '')
   {
      m_properties._makeempty();
      m_caption = caption;
      m_systemHelp = systemHelp;
      m_sheetHelp = sheetHelp;
   }

   /**
    * Returns the number of items in this property sheet.
    * 
    * @return number of items
    */
   public int getNumItems()
   {
      return m_properties._length();
   }

   /**
    * Gets the caption for this PropertySheet.
    * 
    * @return _str   caption
    */
   public _str getCaption()
   {
      return m_caption;
   }

   /**
    * Returns the index of the property whose caption matches the
    * input parameter.
    * 
    * @param caption caption to seek
    * 
    * @return index of property in PropertySheet with given
    *         caption, -1 if none were found.  If multiple
    *         properties have the matching caption, the lowest
    *         index is returned.
    */
   public int getIndexByCaption(_str caption)
   {
      int i;
      for (i = 0; i < m_properties._length(); i++) {
         // we don't want a property group
         if (getTypeAtIndex(i) == TMT_PROPERTY) {
            if (((Property)m_properties[i]).getCaption() == caption) {
               return i;
            }
         }
      }

      return -1;
   }


   /**
    * Get the type of IPropertyTreeMember at the given index.
    * 
    * @param index  index to check
    * 
    * @return member of TreeMemberType enum
    */
   public int getTypeAtIndex(int index)
   {
      // invalid index
      if (index < 0 || index >= m_properties._length()) {
         return TMT_NULL;
      }

      // either a property group or a property
      if (m_properties[index]._typename() == 'se.options.PropertyGroup') return TMT_GROUP;
      else return TMT_PROPERTY;
   }


   /**
    * Returns a pointer to the property at the given index.
    * 
    * @param index         index to check
    * 
    * @return              pointer to property at index, null if 
    *                      index is out of range or if item at
    *                      index is not a property
    */
   public Property * getPropertyByIndex(int index)
   {
      // we need only properties here
      if (getTypeAtIndex(index) != TMT_PROPERTY) return null;

      Property *p = &((Property)m_properties[index]);

      return p;
   }
   
   /**
    * Retrieves a pointer to the property in this property sheet which has the 
    * given index in the options dialog XML DOM. 
    * 
    * @param xmlIndex         XML index to search for
    * 
    * @return                 pointer to property with index, null if one is not 
    *                         found.
    */
   public Property * getPropertyByXMLIndex(int xmlIndex)
   {
      int i;
      for (i = 0; i < m_properties._length(); i++) {
         // we don't want a property group
         if (getTypeAtIndex(i) == TMT_PROPERTY) {
            if (((Property)m_properties[i]).getIndex() == xmlIndex) {
               return &((Property)m_properties[i]);
            }
         }
      }

      return null;
   }

   /**
    * Returns a pointer to the PropertyGroup at the given index.
    * 
    * @param index         index to check
    * 
    * @return              pointer to PropertyGroup at index, null 
    *                      if index is out of range or if item at
    *                      index is not a PropertyGroup
    */
   public PropertyGroup * getPropertyGroupByIndex(int index)
   {
      // we need only properties here
      if (getTypeAtIndex(index) != TMT_GROUP) return null;

      PropertyGroup *pg = &((PropertyGroup)m_properties[index]);

      return pg;
   }


   /**
    * Adds a new member to the PropertySheet.  Could be any item 
    * that implements the IPropertyTreeMember interface. 
    * 
    * @param p      new item to add
    */
   public void addPropertyTreeMember(IPropertyTreeMember iptm)
   {
      m_properties[m_properties._length()] = iptm;
   }

   
   /**
    * Determines if any of the properties within this PropertySheet
    * have been modified. 
    * 
    * @return true if any properties have been modified, false 
    *         otherwise.
    */
   public bool isModified()
   {
      int i;
      for (i = 0; i < m_properties._length(); i++) {
         if (getTypeAtIndex(i) == TMT_PROPERTY) {
            if (((Property)m_properties[i]).isModified()) {
               return true;
            }
         }
      }

      return false;
   }

   /**
    * Returns a list of the XML DOM indices of all the properties in this 
    * PropertySheet.  Does not include PropertyGroups. 
    * 
    * @param indices     array of XML DOM indices
    */
   public void getAllPropertyIndices(int (&indices)[])
   {
      for (i := 0; i < m_properties._length(); i++) {
         if (getTypeAtIndex(i) == TMT_PROPERTY) {
            indices[indices._length()] = ((Property)m_properties[i]).getIndex();
         }
      }
   }
   
   /**
    * Removes any disabled properties from the property sheet.
    * 
    * @param removedXMLIndices            array of XML indices of the properties 
    *                                     which were removed
    */
   public void removeDisabledProperties(int (&removedXMLIndices)[])
   {
      _str values:[];

      for (i := 0; i < m_properties._length(); i++) {
         if (getTypeAtIndex(i) == TMT_PROPERTY) {
            Property *p = &((Property)m_properties[i]);

            // keep track of caption/value pairs for dependencies
            values:[p -> getCaption()] = p -> getDisplayValue();

            // check dependencies to see if this item should be disabled
            if (values != null && !p -> m_dependencies.evaluate(values)) {
               removedXMLIndices[removedXMLIndices._length()] = p -> getIndex();
               removeProperty(i);
               i--;
            }
         }
      }

      // now see if the deletion of properties has left any empty groups
      int emptyGroups[];
      getEmptyGroups(emptyGroups);
      for (i = 0; i < emptyGroups._length(); i++) {
         // subtract the index, because that many groups have already been deleted...
         index := emptyGroups[i] - i;

         removedXMLIndices[removedXMLIndices._length()] = getXMLIndexOfItem(index);
         removeProperty(index);
      }
   }

   public void removeProperty(int index)
   {
      // see if this property is inside a group
      group := getPropertyGroupContainingProperty(index);
      if (group > 0) {
         ((PropertyGroup)m_properties[group]).removeProperty();
      }

      // just remove the property
      m_properties._deleteel(index);
   }
   
   public void getEmptyGroups(int (&emptyGroups)[])
   {
      for (i := 0; i < m_properties._length(); i++) {
         if (getTypeAtIndex(i) == TMT_GROUP) {
            if (((PropertyGroup)m_properties[i]).getNumProperties() == 0) {
               emptyGroups[emptyGroups._length()] = i;
            }
         }
      }
   }
   
   private int getPropertyGroupContainingProperty(int propIndex)
   {
      // start at the property index
      for (i := propIndex - 1; i > 0; i--) {
         // see if this is a property group
         if (getTypeAtIndex(i) == TMT_GROUP) {
            // see if it includes the given property
            PropertyGroup pg = ((PropertyGroup)m_properties[i]);
            if (i + pg.getNumProperties() >= propIndex) {
               // it does!  return this index
               return i;
            } else return -1;          // if this one doesn't, we know none of them include it
         } 
      }
      
      // no such luck
      return -1;
   }
   
   public int getXMLIndexOfItem(int psIndex)
   {
      return m_properties[psIndex].getIndex();
   }

   public _str getDialogHelpOfItem(int psIndex)
   {
      if (getTypeAtIndex(psIndex) != TMT_PROPERTY) return '';
         
      Property * p = getPropertyByIndex(psIndex);
      help := p -> getHelp();
      if (help == '') {
         help = m_sheetHelp;
      }

      return help;
   }


   /**
    * Determines if the given index of the currently showing 
    * property sheet is a DirectoryPath property. 
    * 
    * @param index index to check
    * 
    * @return     true if property is DirectoryPath, false 
    *             otherwise
    */
   public bool isDirectoryPath(int psIndex)
   {
      if (getTypeAtIndex(psIndex) != TMT_PROPERTY) return false;

      Property * p = getPropertyByIndex(psIndex);

      // now figure out what to do about it
      return (p -> getPropertyType() == DIRECTORY_PATH_PROPERTY);
   }

   /**
    * Determines if the given index of the currently showing 
    * property sheet is a Color property. 
    * 
    * @param index index to check
    * 
    * @return     true if property is a Color, false 
    *             otherwise
    */
   public bool isColorProperty(int psIndex)
   {
      if (getTypeAtIndex(psIndex) != TMT_PROPERTY) return false;

      Property * p = getPropertyByIndex(psIndex);

      // now figure out what to do about it
      return (p -> getPropertyType() == COLOR_PROPERTY);
   }

   public _str getLanguage()
   {
      // find the first property
      for (i := 0; i < m_properties._length() && getTypeAtIndex(i) != TMT_PROPERTY; i++) ;

      if (i < m_properties._length()) {
         Property * p = getPropertyByIndex(i);
         return p -> getLanguage();
      }

      return '';
   }

   public _str getPropertyPath(int propIndex)
   {
      path := m_properties[propIndex].getCaption();

      pgIndex := getPropertyGroupContainingProperty(propIndex);
      if (pgIndex > 0) {
         path = m_properties[pgIndex].getCaption() ' > ' path;
      }

      return path;
   }

   /**
    * Sets the system help for this object.  System help is a 
    * p_help tag that is used to navigate to the corresponding 
    * section of the help documentation. 
    * 
    * @return   help information
    */
   public _str getSystemHelp()
   {
      return m_systemHelp;
   }
};
