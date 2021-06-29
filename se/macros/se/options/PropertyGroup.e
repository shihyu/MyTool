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
#require "Property.e"
#require "IPropertyTreeMember.e"
#endregion Imports

namespace se.options;

/**
 * A property group is simply a heading for a set of properties.
 */
class PropertyGroup : IPropertyTreeMember {
   private _str m_caption;             // caption of this property group
   private int m_count = 0;            // number of properties in this group
   private int m_index = 0;

   /**
    * Constructor.
    */
   PropertyGroup(_str caption = '', int count = 0, int index = 0)
   {
      m_caption = caption;
      m_count = count;
      m_index = index;
   }

   /**
    * Returns the number of properties in this group.
    * 
    * @return     the number of properties in this group
    */
   public int getNumProperties()
   {
      return m_count;
   }

   /**
    * Returns the caption of this PropertyGroup.
    * 
    * @return caption
    */
   public _str getCaption()
   {
      return m_caption;
   }
   
   
   public void removeProperty()
   {
      m_count--;
   }
   
   public int getIndex()
   {
      return m_index;
   }
}

