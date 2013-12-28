////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45785 $
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
 * Represents a numeric property.
 * 
 */
class NumericProperty : Property {
   int m_max;        // maximum allowed value
   int m_min;        // minimum allowed value
   boolean m_isInt;  // whether the value is an integer (float otherwise)

   /**
    * Constructor.  Initializes the caption, allowable ranges of
    * the property, and what sort of number it is (integer versus
    * floating point).
    * 
    */
   NumericProperty(_str caption = '', int index = 0, int min = -1, int max = -1, boolean isInt = true)
   {
      Property(caption, index);
      m_min = min;
      m_max = max;
      m_isInt = isInt;
   }

   /** 
    * Checks that a value is within the bounds specified by the 
    * property. 
    * 
    * @param value      value to be checked
    * 
    * @return _str      Empty string if value falls within bounds. 
    *                   Error message otherwise.
    */
   _str validateNumeric(_str value)
   {
      _str error = '';

      do {

         // not a number
         if (m_isInt) {
            if (!isinteger(value)) {
               error = "Please enter an integer value.";
               break;
            }
         } else {
            if (!isnumber(value)) {
               error = "Please enter a numeric value.";
               break;
            }
         }

         long num = (long)value;

         // too small
         if (m_min != -1 && num < m_min) {
            error = "Please enter a value greater than or equal to "m_min".";
            break;
         }

         // too large
         if (m_max != -1 && num > m_max) {
            error = "Please enter a value less than or equal to "m_max".";
            break;
         }

         // otherwise just right
      } while (false);

      return error;
   }

   /** 
    * Updates the current value of the property.  First ensures 
    * that new value falls within min/max range. 
    * 
    * @param newValue      the new value to be set
    * 
    * @return _str         
    */
   _str updateValue(_str newValue)
   {
      _str error = validateNumeric(newValue);

      if (error == '') {
         return Property.updateValue(newValue);
      }

      return error;
   }

   /**
    * Returns the current property type (one of the PropertyType enum).  Should 
    * be overwritten by child classes. 
    * 
    * @return           property type of this object
    */
   public int getPropertyType()
   {
      return NUMERIC_PROPERTY;
   }
};
