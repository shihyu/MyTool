////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45994 $
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
#import "markfilt.e"
#require "Property.e"
#endregion Imports

namespace se.options;

/** 
 * This class represents a property that has a true/false value.
 * 
 */
class BooleanProperty : Property {

   private _str m_falseDisplayValue = 'Off';
   private _str m_trueDisplayValue = 'On';

   /**
    * BooleanProperty constructor.  Initializes the caption and
    * index of the property.
    * 
    */
   BooleanProperty(_str caption = '', int index = 0)
   {
      Property(caption, index);
   }

   /**
    * Sets the true/false choices that will be listed in a
    * BooleanProperty combo box.  The default is True and False,
    * but you can set them to anything, such as On/Off, Yes/No,
    * Plain/Peanut.  As long as those values translate to setting a
    * boolean value, it's all good.
    *
    * @param trueDisplay
    * @param falseDisplay
    */
   public void setDisplayValues(_str falseDisplay, _str trueDisplay)
   {
      if (falseDisplay != '') {
         m_falseDisplayValue = falseDisplay;
      }
      if (trueDisplay != '') {
         m_trueDisplayValue = trueDisplay;
      }
   }

   /** 
    * Updates the current value of the property.  Ensures that the 
    * value is either "True" or "False". 
    * 
    * @param newValue      new value to be set
    * 
    * @return _str         returns new value
    */
   _str updateValue(_str newValue)
   {
      // make sure this setting is in true/false format - convert from boolean
      if (strieq(newValue, 'True')) {
         newValue = 'True';
      } else if (strieq(newValue, 'False')) {
         newValue = 'False';
      } else if (strieq(newValue, m_trueDisplayValue)) {
         newValue = 'True';
      } else if (strieq(newValue, m_falseDisplayValue)) {
         newValue = 'False';
      } else {
         if ((int)newValue) {
            newValue = 'True';
         } else {
            newValue = 'False';
         }
      }

      // capitalize word to keep things pretty
      newValue = _cap_word(newValue);

      return Property.updateValue(newValue);
   }

   /**
    * Returns an array containing the possible choices for this
    * property.  Could be either True/False or Yes/No.
    *
    * @param choices
    */
   public void getChoices(_str (&choices)[])
   {
      choices._makeempty();
      choices[0] = m_falseDisplayValue;
      choices[1] = m_trueDisplayValue;
   }

   /**
    * Returns the string representation of the selected choice.
    *
    * @return _str   Current value as a string
    */
   public _str getDisplayValue()
   {
      if (m_value == 'True') {
         return m_trueDisplayValue;
      } else if (m_value == 'False') {
         return m_falseDisplayValue;
      }

      return "Error retrieving value";
   }

   /**
    * Returns the current property type (one of the PropertyType enum).  Should 
    * be overwritten by child classes. 
    * 
    * @return           property type of this object
    */
   public int getPropertyType()
   {
      return BOOLEAN_PROPERTY;
   }
};
