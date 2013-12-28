////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46434 $
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
#require "SelectChoice.e"
#endregion Imports

namespace se.options;

/** 
 * Represents an option that provides you with two or more
 * selections to choose from.
 * 
 * Inherits from Property.
 * 
 */
class Select : Property {
   // keeps track of the possible choices for this property.  
   // Keyed off of actual values as they are set in the application.  
   // Values are the strings representation of choices for GUI.
   private SelectChoice m_choices:[];

   // whether the values are flags that need to be ORed into the real value
   private boolean m_flag;

   // sometimes the actual value is not included in our list of choices.  
   // Usually we just put up an error message, but sometimes we want to show 
   // the real value.
   private boolean m_insertActualValue;

   /**
    * Constructor.
    */
   Select(_str caption = '', int index = 0, boolean flag = false)
   {
      m_choices._makeempty();
      m_flag = flag;
      m_insertActualValue = false;
      Property(caption, index);
   }

   /** 
    * Adds a choice to the Select.  The hashtable is keyed off the 
    * actual values.  Thus m_choices:[value] = choice. 
    * 
    * @param caption       caption of new choice
    * @param value         value of new choice
    */
   public void addChoice(SelectChoice &c)
   {
      value := c.getValue();
      if (!m_choices._indexin(value)) {
         m_choices:[value] = c;
      }
   }

   /**
    * Checks for a default choice in our list of choices.   
    * 
    * @return              actual value of the default choice, null if no default 
    *                      choice is found
    */
   private _str getValueOfDefaultChoice()
   {
      foreach (auto value => auto choice in m_choices) {
         if (choice.isDefault()) {
            return value;
         }
      }

      return null;
   }

   /**
    * Sets a new value for the property.  If the m_flag is not
    * true, then the base class is called.
    * 
    * @param newValue new value to set
    */
   public void setValue(_str newValue)
   {
      if (newValue == null) return;

      // make sure our new Value really is a flag to do all this specialness
      if (!m_flag || !isnumber(newValue)) {
         if (!m_choices._indexin(newValue)) {
            // go through and see if we have a default
            defaultValue := getValueOfDefaultChoice();
            if (defaultValue != null) {
               newValue = defaultValue;
            } else if (m_insertActualValue) {
               // there's no default, so maybe we should just add the actual value...
               SelectChoice sc(newValue, newValue);
               sc.setChoosable(false);

               addChoice(sc);
            }
         } 

         Property.setValue(newValue);
         return;
      } else {
   
         // get the actual value, not just the string
         typeless choiceValue;
         _str ourValue = "", ourDefault = "";
         boolean found = false, foundDefault = false;

         SelectChoice sc;
         foreach (choiceValue => sc in m_choices) {
            // this is a flag - we gotta check for a flag instead of an exact value
            // we have to do this silliness, because we can't control the value being sent in
            if (sc.isAvailable()) {
               if (((int)choiceValue & (int)newValue) == (int)choiceValue || (int)choiceValue == 0) {
                  if (ourValue == "") {
                     ourValue = choiceValue;
                     found = true;
                  } else if ((int)choiceValue > (int)ourValue) {
                     ourValue = choiceValue;
                  }
               }
   
               if (!found && sc.isDefault()) {
                  ourDefault = choiceValue;
                  foundDefault = true;
               }
            }
         }
   
         // if we found it, set it
         if (found) {
            Property.setValue(ourValue);
         } else if (foundDefault) {
            Property.setValue(ourDefault);
         }
      }
   }

   /**
    * Updates the current value.
    * 
    * @param newValue new value to set
    * 
    * @return current value (newly set?)
    */
   public _str updateValue(_str newValue)
   {
      // get the actual value, not just the string
      typeless i;
      _str ourValue = "";
      _str ourDefault = "";
      boolean found = false, foundDefault = false;
      for (i._makeempty();;) {
         m_choices._nextel(i);
         if (i._isempty()) break;
         if (m_choices:[i].isAvailable()) {
            if (strieq(m_choices:[i].getCaption(), newValue)) {
               ourValue = i;
               found = true;
               break;
            } else if (m_choices:[i].isDefault()) {
               ourDefault = i;
               foundDefault = true;
            }
         }
      }

      // update value
      if (found && m_value != ourValue) {
         m_value = ourValue;
      } else if (!found && foundDefault && m_value != ourDefault) {
         m_value = ourDefault;
      }

      return m_value;
   }

   /** 
    * Returns the string representation of the selected choice by 
    * looking it up in the hashtable. 
    * 
    * @return _str   Current value as a string
    */
   public _str getDisplayValue()
   {
      if (m_value != null && m_choices._indexin(m_value) && m_choices:[m_value].isAvailable()) {
         return m_choices:[m_value].getCaption();
      } else {
         return "Error retrieving value";
      }
   }

   /**
    * Sets the SettingInfo struct for this property.
    * 
    * @param info          SettingInfo for this property
    */
   public void setSettingInfo(SettingInfo &info)
   {
      // if we are set using a flag, make sure and add all our choices to the list
      if (info.ValueType == SELECT_AS_FLAG) {
         info.Flags._makeempty();
         SelectChoice sc;
         foreach (sc in m_choices) {
            FlagInformation f;
            f.Name = sc.getFlagName();
            f.Value = (int)sc.getValue();
            info.Flags[info.Flags._length()] = f;
         }
      }

      Property.setSettingInfo(info);
   }

   /**
    * Returns the array of choice captions.
    * 
    * @param choices array of choices
    */
   public void getChoices(_str (&choices)[])
   {
      typeless i;
      for (i._makeempty();;) {
         m_choices._nextel(i);
         if (i._isempty()) break;
         if (m_choices:[i].isAvailable() && m_choices:[i].isChoosable()) {
            choices[choices._length()] = m_choices:[i].getCaption();
         }
      }

      choices._sort();
   }

   /**
    * Sets the value that determines whether we add the actual value as a 
    * non-choosable choice if it's not one of the select choices. 
    * 
    * @param insert              value to set
    */
   public void setInsertChoiceIfNotAvailable(boolean insert)
   {
      m_insertActualValue = insert;
   }

   /**
    * Returns the current property type (one of the PropertyType enum).  Should 
    * be overwritten by child classes. 
    * 
    * @return           property type of this object
    */
   public int getPropertyType()
   {
      return SELECT_PROPERTY;
   }

};
