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
   private bool m_flag;

   // sometimes the actual value is not included in our list of choices.  
   // Usually we just put up an error message, but sometimes we want to show 
   // the real value.
   private bool m_insertActualValue;

   // whether to display the choices as a sorted list.  default is true,
   // but sometimes we like to turn it off
   private bool m_doSort = true;

   // keep a list of the choice captions in the order they should appear
   private _str m_choiceCaptions[];

   // a table of caption to actual value mappings
   private _str m_captionToValue:[];

   /**
    * Constructor.
    */
   Select(_str caption = '', int index = 0, bool flag = false, bool doSort = true)
   {
      m_choices._makeempty();
      m_flag = flag;
      m_insertActualValue = false;
      m_doSort = true;
      m_choiceCaptions._makeempty();
      m_captionToValue._makeempty();
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

         // add it to our array of captions - don't sort until the list is used
         m_choiceCaptions[m_choiceCaptions._length()] = c.getCaption();

         // add the caption to value mapping, so we can use the caption to get the choice
         m_captionToValue:[c.getCaption()] = value;
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
         ourValue := ourDefault := "";
         found := foundDefault := false;

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
      // we're being sent the caption, so we need to find the actual value
      _str ourValue = null;
      if (m_captionToValue._indexin(newValue)) {
         // make sure it's available
         thisValue := m_captionToValue:[newValue];
         if (m_choices._indexin(thisValue) && m_choices:[thisValue].isAvailable()) {
            ourValue = thisValue;
         }
      }

      // we didn't find it or it's not available
      // get the default
      if (ourValue == null) {
         ourValue = getValueOfDefaultChoice();
      }

      // if we got it, set it
      if (ourValue != null) {
         m_value = ourValue;
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
    * @param filterAvailable     true to only return the choices
    *                            which are currently available,
    *                            false to return all
    */
   public void getChoices(_str (&choices)[], bool filterAvailable = true)
   {
      // maybe sort first
      if (m_doSort) {
         m_choiceCaptions._sort();
         m_doSort = false;
      }

      // now we still have to go through and make sure everything is available
      for (i := 0; i < m_choiceCaptions._length(); i++) {
         cap := m_choiceCaptions[i];
         if (m_captionToValue._indexin(cap)) {
            val := m_captionToValue:[cap];
            if (!filterAvailable || (m_choices:[val].isAvailable() && m_choices:[val].isChoosable())) {
               choices[choices._length()] = cap;
            }
         }
      }

   }

   /**
    * Sets the value that determines whether we add the actual value as a 
    * non-choosable choice if it's not one of the select choices. 
    * 
    * @param insert              value to set
    */
   public void setInsertChoiceIfNotAvailable(bool insert)
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

   /**
    * Sets whether the choices in the Select Property are displayed
    * in sorted order.
    *
    * @param sorted
    */
   public void setSorted(bool sorted)
   {
      m_doSort = sorted;
   }

   /**
    * Returns true if any of the choices in the Select are
    * conditional, i.e. if they are only available some of the
    * time.
    *
    * @return bool
    */
   public bool hasConditionalChoices()
   {
      // go through the choices and see if any are conditional
      SelectChoice sc;
      foreach (auto choiceValue => sc in m_choices) {
         if (sc.isConditional()) return true;
      }

      return false;
   }
};
