////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#include 'slick.sh'
#require 'Property.e'
#endregion Imports

namespace se.options;

/** 
 * This class represents a Property that contains a color value.
 * 
 */
class ColorProperty : Property {

   /**
    * Constructor.  Initializes the caption and XML index.
    * 
    */
   ColorProperty(_str caption = '', int index = 0)
   {
      Property(caption, index);
   }

   /** 
    * Since the color doesn't display any text, but only the actual 
    * color, we return an empty string 
    * 
    * @return _str      empty string
    */
   _str getDisplayValue()
   {
      return '';
   }

   /**
    * Returns the current property type (one of the PropertyType enum).  Should 
    * be overwritten by child classes. 
    * 
    * @return           property type of this object
    */
   public int getPropertyType()
   {
      return COLOR_PROPERTY;
   }
};
